/*
 * SwoftLang live debug tracer client.
 *
 * Connects to the server's WebSocket (ws://<host>:<debugPort>, hosted only when
 * the server runs with --debug) and turns the newline-delimited JSON protocol
 * into editor decorations:
 *
 *   Server -> client:
 *     {"type":"hello","protocol":1,"scriptsDir":"/abs/path/scripts"}
 *     {"type":"trace","file":"scripts/chat.sw","line":12,"col":9,"kind":"send",
 *        "handler":"event PlayerChat","seq":42,"ts":<ms>}
 *     {"type":"handler","phase":"enter"|"exit","file":..,"line":..,"name":".."}
 *     {"type":"reload","file":"scripts/chat.sw","ok":true}
 *     {"type":"reload","file":"scripts/chat.sw","ok":false,"error":".."}
 *   Client -> server:
 *     {"type":"subscribe"}   // optional; server streams by default on connect
 *
 * line/col in the protocol are 1-based (compiler convention); VS Code ranges are
 * 0-based so we subtract one.
 *
 * A trace makes the executed line FLASH bright emerald, then fade over ~700ms,
 * leaving a fainter "recently executed" trail for ~2.5s so a handler can be
 * watched running statement-by-statement.
 */
import * as vscode from 'vscode';
import * as path from 'path';
import * as fs from 'fs';
import WebSocket from 'ws';

// ---- protocol message shapes ----
export interface HelloMsg {
  type: 'hello';
  protocol: number;
  scriptsDir?: string;
}
export interface TraceMsg {
  type: 'trace';
  file: string;
  line: number;
  col?: number;
  kind?: string;
  handler?: string;
  seq?: number;
  ts?: number;
}
export interface HandlerMsg {
  type: 'handler';
  phase: 'enter' | 'exit';
  file: string;
  line: number;
  name: string;
}
export interface ReloadMsg {
  type: 'reload';
  file: string;
  ok: boolean;
  error?: string;
}
export type ServerMsg = HelloMsg | TraceMsg | HandlerMsg | ReloadMsg;

// ---- decoration animation ----
// A line eases in, then BREATHES on a slow shared sine while it keeps firing —
// so a scoreboard/tablist update loop settles into one long phase-in/out rather
// than re-flashing on every hit — and fades once it stops. Rows are phase-offset
// by line number so lines lit in the same burst cascade top→bottom.
const ATTACK_MS = 130; // ease-in when a line first lights up
const SUSTAIN_MS = 1500; // after its last hit, how long a line stays lit before fading out
const BREATHE_MS = 1700; // period of the slow in/out breathing cycle
const STAGGER_MS = 55; // per-row phase offset so simultaneous lines cascade downward
const BREATHE_FLOOR = 0.5; // breathing dips only to this fraction (never fully dark while active)
const PEAK_ALPHA = 0.5; // brightest background alpha
const STEPS = 16; // ladder resolution — higher = smoother fade

function easeOutQuad(t: number): number {
  return 1 - (1 - t) * (1 - t);
}

/**
 * A tint layer used for the fade. We pre-build a ladder of decoration types
 * from strongest (emerald) to faintest, and move a line down the ladder over
 * time; a setDecorations call per bucket keeps the flash cheap.
 */
interface Layer {
  type: vscode.TextEditorDecorationType;
}

function makeLayer(alpha: number, strong: boolean): Layer {
  // emerald: rgb(16, 185, 129)
  const bg = `rgba(16, 185, 129, ${alpha.toFixed(3)})`;
  return {
    type: vscode.window.createTextEditorDecorationType({
      isWholeLine: true,
      backgroundColor: bg,
      borderWidth: strong ? '0 0 0 3px' : '0',
      borderStyle: 'solid',
      borderColor: strong ? 'rgba(16, 185, 129, 0.95)' : 'transparent',
      overviewRulerColor: 'rgba(16, 185, 129, 0.8)',
      overviewRulerLane: vscode.OverviewRulerLane.Center,
    }),
  };
}

// gutter marker shown while a handler is executing (its enter line)
function makeHandlerMarker(context: vscode.ExtensionContext): vscode.TextEditorDecorationType {
  return vscode.window.createTextEditorDecorationType({
    isWholeLine: true,
    backgroundColor: 'rgba(52, 211, 153, 0.10)',
    borderWidth: '0 0 0 3px',
    borderStyle: 'solid',
    borderColor: 'rgba(52, 211, 153, 0.9)',
    after: {
      contentText: '  ◀ handler',
      color: 'rgba(52, 211, 153, 0.7)',
      fontStyle: 'italic',
    },
  });
}

interface ActiveLine {
  editorKey: string; // uri string
  line: number; // 0-based
  firstSeen: number; // Date.now() when the line first lit up (drives the ease-in)
  lastSeen: number; // Date.now() of the most recent hit (drives sustain/fade)
}

export interface TracerHost {
  /** map a server (scripts-relative) file path to a workspace document uri, or undefined */
  resolveFile(file: string): vscode.Uri | undefined;
  scriptsDir(): string | undefined;
  setScriptsDirFromHello(dir: string): void;
  autoReveal(): boolean;
  followExecution(): boolean;
}

export class DebugTracer implements vscode.Disposable {
  private ws: WebSocket | undefined;
  private status: vscode.StatusBarItem;
  private output: vscode.OutputChannel;
  private layers: Layer[] = [];
  private handlerMarker: vscode.TextEditorDecorationType;
  private active: ActiveLine[] = [];
  private tickTimer: NodeJS.Timeout | undefined;
  private handlerLines = new Map<string, number>(); // uri -> line currently marked
  private buffer = '';
  private connected = false;
  private disposed = false;
  private reconnectTimer: NodeJS.Timeout | undefined;
  private wantConnected = false;
  private lastReload = '';

  constructor(
    private readonly host: TracerHost,
    context: vscode.ExtensionContext,
    private readonly getPort: () => number,
    private readonly getHost: () => string,
  ) {
    this.output = vscode.window.createOutputChannel('SwoftLang Debug Tracer');
    this.status = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Left, 100);
    this.status.command = 'swoftlang.debug.connect';
    this.updateStatus();
    this.status.show();

    // ladder of glow layers from faintest (index 0) to brightest (STEPS-1);
    // the brightest ~30% carry the emerald left-border so the glow fades too.
    for (let i = 0; i < STEPS; i++) {
      const frac = (i + 1) / STEPS; // (0, 1]
      const alpha = Math.max(0.02, PEAK_ALPHA * frac);
      this.layers.push(makeLayer(alpha, frac >= 0.7));
    }
    this.handlerMarker = makeHandlerMarker(context);

    context.subscriptions.push(
      this.status,
      this.output,
      this,
      // editing a traced file shifts its line numbers — clear stale pulses at once
      vscode.workspace.onDidChangeTextDocument((e) => {
        const key = e.document.uri.toString();
        if (this.active.some((a) => a.editorKey === key)) this.clearFile(e.document.uri);
      }),
    );
  }

  // ---- connection lifecycle ----
  connect(): void {
    this.wantConnected = true;
    if (this.ws) return;
    const url = `ws://${this.getHost()}:${this.getPort()}`;
    this.log(`connecting to ${url} ...`);
    let ws: WebSocket;
    try {
      ws = new WebSocket(url);
    } catch (e: any) {
      this.log(`connect failed: ${e?.message ?? e}`);
      this.scheduleReconnect();
      return;
    }
    this.ws = ws;

    ws.on('open', () => {
      this.connected = true;
      this.log('connected');
      this.updateStatus();
      try {
        ws.send(JSON.stringify({ type: 'subscribe' }));
      } catch {
        /* server streams by default anyway */
      }
      this.startTicker();
    });
    ws.on('message', (data: WebSocket.RawData) => this.onData(data.toString()));
    ws.on('close', () => {
      this.connected = false;
      this.ws = undefined;
      this.updateStatus();
      this.log('disconnected');
      if (this.wantConnected) this.scheduleReconnect();
    });
    ws.on('error', (err: Error) => {
      this.log(`ws error: ${err.message}`);
      // 'close' will follow and trigger reconnect
    });
  }

  disconnect(): void {
    this.wantConnected = false;
    if (this.reconnectTimer) {
      clearTimeout(this.reconnectTimer);
      this.reconnectTimer = undefined;
    }
    if (this.ws) {
      try {
        this.ws.close();
      } catch {
        /* ignore */
      }
      this.ws = undefined;
    }
    this.connected = false;
    this.clearAll();
    this.updateStatus();
  }

  private scheduleReconnect(): void {
    if (this.disposed || !this.wantConnected) return;
    if (this.reconnectTimer) return;
    this.reconnectTimer = setTimeout(() => {
      this.reconnectTimer = undefined;
      if (this.wantConnected && !this.ws) this.connect();
    }, 3000);
  }

  // ---- protocol parsing (newline-delimited JSON, tolerant of framing) ----
  private onData(chunk: string): void {
    this.buffer += chunk;
    let idx: number;
    while ((idx = this.buffer.indexOf('\n')) >= 0) {
      const line = this.buffer.slice(0, idx).trim();
      this.buffer = this.buffer.slice(idx + 1);
      if (line) this.handleLine(line);
    }
    // A single unframed JSON object (no trailing newline) is also accepted once
    // it parses cleanly — ws already delivers whole frames.
    const rest = this.buffer.trim();
    if (rest.startsWith('{') && rest.endsWith('}')) {
      try {
        JSON.parse(rest);
        this.handleLine(rest);
        this.buffer = '';
      } catch {
        /* wait for more data */
      }
    }
  }

  private handleLine(line: string): void {
    let msg: ServerMsg;
    try {
      msg = JSON.parse(line) as ServerMsg;
    } catch {
      this.log(`unparseable: ${line}`);
      return;
    }
    this.dispatch(msg);
  }

  /** Public so headless tests can drive the tracer without a socket. */
  dispatch(msg: ServerMsg): void {
    switch (msg.type) {
      case 'hello':
        this.log(`hello: protocol=${msg.protocol} scriptsDir=${msg.scriptsDir ?? '(none)'}`);
        if (msg.scriptsDir) this.host.setScriptsDirFromHello(msg.scriptsDir);
        break;
      case 'trace':
        this.onTrace(msg);
        break;
      case 'handler':
        this.onHandler(msg);
        break;
      case 'reload':
        this.onReload(msg);
        break;
      default:
        this.log(`unknown message type: ${JSON.stringify(msg)}`);
    }
  }

  private async onTrace(msg: TraceMsg): Promise<void> {
    const uri = this.host.resolveFile(msg.file);
    if (!uri) {
      this.log(`trace for unknown file: ${msg.file}`);
      return;
    }
    const line0 = Math.max(0, (msg.line || 1) - 1);
    let editor = this.findEditor(uri);
    if (!editor && this.host.autoReveal()) {
      try {
        const doc = await vscode.workspace.openTextDocument(uri);
        editor = await vscode.window.showTextDocument(doc, {
          preview: true,
          preserveFocus: true,
        });
      } catch (e: any) {
        this.log(`could not reveal ${uri.fsPath}: ${e?.message ?? e}`);
      }
    }
    if (!editor) return;

    // Follow-execution (scrolling to the line) is OFF by default so the tracer
    // never hijacks your scroll while a loop keeps firing. Opt in with
    // swoftlang.debug.followExecution.
    if (this.host.followExecution()) {
      editor.revealRange(
        new vscode.Range(line0, 0, line0, 0),
        vscode.TextEditorRevealType.InCenterIfOutsideViewport,
      );
    }
    const nowMs = Date.now();
    const existing = this.active.find(
      (a) => a.editorKey === uri.toString() && a.line === line0,
    );
    if (existing) {
      // already lit — just refresh its "last hit" so a constant loop keeps
      // breathing as one long steady pulse instead of re-flashing every tick.
      existing.lastSeen = nowMs;
    } else {
      this.active.unshift({
        editorKey: uri.toString(),
        line: line0,
        firstSeen: nowMs,
        lastSeen: nowMs,
      });
      // cap the trail so we never leak decorations
      if (this.active.length > 200) this.active.length = 200;
    }
    this.render();
    this.startTicker();
  }

  private onHandler(msg: HandlerMsg): void {
    const uri = this.host.resolveFile(msg.file);
    if (msg.phase === 'enter') {
      this.status.text = `$(debug-start) ${msg.name}`;
      this.status.tooltip = `SwoftLang: executing ${msg.name}`;
      vscode.window.setStatusBarMessage(`▶ ${msg.name}`, 2500);
      this.log(`handler enter: ${msg.name} @ ${msg.file}:${msg.line}`);
      if (uri) {
        const line0 = Math.max(0, (msg.line || 1) - 1);
        this.handlerLines.set(uri.toString(), line0);
        this.renderHandlerMarker(uri);
      }
    } else {
      this.log(`handler exit: ${msg.name}`);
      if (uri) {
        this.handlerLines.delete(uri.toString());
        const editor = this.findEditor(uri);
        if (editor) editor.setDecorations(this.handlerMarker, []);
      }
      this.updateStatus();
    }
  }

  private onReload(msg: ReloadMsg): void {
    const short = path.basename(msg.file);
    // the file's line numbers may have shifted on save — drop any stale pulses
    // so only fresh traces at the NEW line numbers light up.
    const reloadedUri = this.host.resolveFile(msg.file);
    if (reloadedUri) this.clearFile(reloadedUri);
    if (msg.ok) {
      this.lastReload = `reloaded ${short} ✓`;
      vscode.window.setStatusBarMessage(`$(check) reloaded ${short}`, 4000);
      vscode.window.showInformationMessage(`SwoftLang: reloaded ${short}`);
      this.log(`reload ok: ${msg.file}`);
    } else {
      this.lastReload = `reload failed: ${short} ✗`;
      const err = msg.error ? `: ${msg.error}` : '';
      vscode.window.showErrorMessage(`SwoftLang: reload FAILED ${short}${err}`);
      this.log(`reload error: ${msg.file}${err}`);
    }
    this.updateStatus();
  }

  // Drop all active pulses + handler marks for one file (its lines shifted).
  private clearFile(uri: vscode.Uri): void {
    const key = uri.toString();
    this.active = this.active.filter((a) => a.editorKey !== key);
    this.handlerLines.delete(key);
    const editor = this.findEditor(uri);
    if (editor) {
      for (const l of this.layers) editor.setDecorations(l.type, []);
      editor.setDecorations(this.handlerMarker, []);
    }
  }

  // ---- rendering ----
  private findEditor(uri: vscode.Uri): vscode.TextEditor | undefined {
    const key = uri.toString();
    return vscode.window.visibleTextEditors.find((e) => e.document.uri.toString() === key);
  }

  private renderHandlerMarker(uri: vscode.Uri): void {
    const editor = this.findEditor(uri);
    if (!editor) return;
    const line = this.handlerLines.get(uri.toString());
    if (line === undefined) {
      editor.setDecorations(this.handlerMarker, []);
      return;
    }
    editor.setDecorations(this.handlerMarker, [new vscode.Range(line, 0, line, 0)]);
  }

  private render(): void {
    const now = Date.now();
    // group active lines per editor into ladder buckets by pulse intensity
    const perEditor = new Map<string, vscode.Range[][]>();

    for (const a of this.active) {
      const sinceLast = now - a.lastSeen;
      if (sinceLast > SUSTAIN_MS) continue; // fully faded
      // ease-in when the line first appears
      const appear = easeOutQuad(Math.min(1, (now - a.firstSeen) / ATTACK_MS));
      // sustain = 1 while firing, eases to 0 over SUSTAIN_MS after the last hit
      const sustain = easeOutQuad(Math.max(0, 1 - sinceLast / SUSTAIN_MS));
      // slow shared breathing, phase-shifted per row so bursts cascade downward
      const phase = (now - a.line * STAGGER_MS) / BREATHE_MS;
      const breathe = 0.5 - 0.5 * Math.cos(phase * 2 * Math.PI); // 0..1
      const level = BREATHE_FLOOR + (1 - BREATHE_FLOOR) * breathe; // FLOOR..1
      const env = appear * sustain * level;
      if (env <= 0.001) continue;
      const bucket = Math.min(STEPS - 1, Math.max(0, Math.round(env * (STEPS - 1))));
      let buckets = perEditor.get(a.editorKey);
      if (!buckets) {
        buckets = this.layers.map(() => []);
        perEditor.set(a.editorKey, buckets);
      }
      buckets[bucket].push(new vscode.Range(a.line, 0, a.line, 0));
    }

    for (const editor of vscode.window.visibleTextEditors) {
      const key = editor.document.uri.toString();
      const buckets = perEditor.get(key);
      for (let i = 0; i < this.layers.length; i++) {
        editor.setDecorations(this.layers[i].type, buckets ? buckets[i] : []);
      }
    }
  }

  private startTicker(): void {
    if (this.tickTimer) return;
    this.tickTimer = setInterval(() => {
      const now = Date.now();
      this.active = this.active.filter((a) => now - a.lastSeen <= SUSTAIN_MS);
      this.render();
      if (this.active.length === 0) {
        if (this.tickTimer) {
          clearInterval(this.tickTimer);
          this.tickTimer = undefined;
        }
      }
    }, 40);
  }

  private clearAll(): void {
    this.active = [];
    this.handlerLines.clear();
    for (const editor of vscode.window.visibleTextEditors) {
      for (const l of this.layers) editor.setDecorations(l.type, []);
      editor.setDecorations(this.handlerMarker, []);
    }
    if (this.tickTimer) {
      clearInterval(this.tickTimer);
      this.tickTimer = undefined;
    }
  }

  private updateStatus(): void {
    const dot = this.connected ? '$(debug-disconnect)' : '$(plug)';
    const state = this.connected ? 'Debug: connected' : 'Debug: disconnected';
    const tail = this.lastReload ? ` — ${this.lastReload}` : '';
    this.status.text = `${dot} SwoftLang ${state}${tail}`;
    this.status.command = this.connected ? 'swoftlang.debug.disconnect' : 'swoftlang.debug.connect';
    this.status.tooltip = this.connected
      ? `Connected to ws://${this.getHost()}:${this.getPort()} — click to disconnect`
      : 'Click to connect to the SwoftLang debug server (server must run with --debug)';
  }

  private log(m: string): void {
    this.output.appendLine(`[${new Date().toISOString()}] ${m}`);
  }

  isConnected(): boolean {
    return this.connected;
  }

  dispose(): void {
    this.disposed = true;
    this.disconnect();
    for (const l of this.layers) l.type.dispose();
    this.handlerMarker.dispose();
  }
}

// small helper used by the host mapping and unit tests
export function scriptsRelativeToUri(
  scriptsDir: string | undefined,
  file: string,
  workspaceRoot: string | undefined,
): string | undefined {
  // The server sends paths like "scripts/chat.sw" (relative) or an absolute path.
  if (path.isAbsolute(file)) return file;
  // strip a leading "scripts/" if scriptsDir already ends in the same segment
  const parts = file.split(/[\\/]/);
  const base = scriptsDir || (workspaceRoot ? path.join(workspaceRoot, 'scripts') : undefined);
  if (!base) return undefined;
  const baseLeaf = path.basename(base);
  if (parts.length > 1 && parts[0] === baseLeaf) {
    return path.join(base, ...parts.slice(1));
  }
  // otherwise treat it as relative to scriptsDir directly
  const candidate = path.join(base, file);
  if (fs.existsSync(candidate)) return candidate;
  // last resort: relative to the workspace root
  if (workspaceRoot) {
    const wc = path.join(workspaceRoot, file);
    if (fs.existsSync(wc)) return wc;
  }
  return candidate;
}
