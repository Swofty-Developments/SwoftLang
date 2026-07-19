/*
 * Mock SwoftLang debug server.
 *
 * A tiny WebSocket server that speaks the Part-2 tracer protocol so the
 * extension's tracer UI can be built and demonstrated WITHOUT the Java
 * `--debug` runtime. On each client connect it sends `hello`, then loops a
 * scripted sequence: a handler enter, several trace lines stepping through a
 * block, a handler exit, a successful reload, and a failed reload.
 *
 * Run with:  npm run mock            (after `npm run compile`)
 *      or:   npx ts-node test/mock-debug-server.ts
 *
 * Options (env):
 *   PORT         port to listen on            (default 25580)
 *   SCRIPTS_DIR  absolute scripts dir sent in hello
 *                (default <repoRoot>/scripts, resolved from this file)
 *   TRACE_FILE   scripts-relative file to trace (default scripts/events.sw)
 *   LOOP         "1" to repeat the sequence forever (default one-shot per client)
 *   STEP_MS      ms between trace steps        (default 550)
 */
import { WebSocketServer, WebSocket } from 'ws';
import * as path from 'path';

const PORT = parseInt(process.env.PORT || '25580', 10);
const STEP_MS = parseInt(process.env.STEP_MS || '550', 10);
const LOOP = process.env.LOOP === '1';
// __dirname is <repo>/editor/vscode-swoftlang/out/test at runtime; four levels
// up is the SwoftLang repo root that owns scripts/.
const repoRoot = path.resolve(__dirname, '..', '..', '..', '..');
const SCRIPTS_DIR = process.env.SCRIPTS_DIR || path.join(repoRoot, 'scripts');
const TRACE_FILE = process.env.TRACE_FILE || 'scripts/events.sw';

interface Step {
  delay: number; // ms to wait before sending, relative to previous
  msg: Record<string, unknown>;
}

// A scripted run through the `event PlayerBeginItemUse` handler in
// scripts/events.sw (lines 14, 17, 18, 20 in the shipped file), then two
// reload outcomes. Adjust TRACE_FILE / lines to taste.
function buildSequence(): Step[] {
  const handlerName = 'event PlayerBeginItemUse';
  let seq = 40;
  const t = (line: number, kind: string): Step => ({
    delay: STEP_MS,
    msg: {
      type: 'trace',
      file: TRACE_FILE,
      line,
      col: 9,
      kind,
      handler: handlerName,
      seq: seq++,
      ts: Date.now(),
    },
  });
  return [
    {
      delay: 400,
      msg: { type: 'handler', phase: 'enter', file: TRACE_FILE, line: 14, name: handlerName },
    },
    t(17, 'block'),
    t(18, 'send'),
    t(20, 'set'),
    {
      delay: STEP_MS,
      msg: { type: 'handler', phase: 'exit', file: TRACE_FILE, line: 14, name: handlerName },
    },
    { delay: 900, msg: { type: 'reload', file: TRACE_FILE, ok: true } },
    {
      delay: 1600,
      msg: {
        type: 'reload',
        file: TRACE_FILE,
        ok: false,
        error: 'events.sw:20:9: error: unknown property \'nonexistent\' on Event',
      },
    },
  ];
}

function send(ws: WebSocket, obj: Record<string, unknown>): void {
  if (ws.readyState === WebSocket.OPEN) ws.send(JSON.stringify(obj) + '\n');
}

async function driveClient(ws: WebSocket): Promise<void> {
  send(ws, { type: 'hello', protocol: 1, scriptsDir: SCRIPTS_DIR });
  const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));
  do {
    for (const step of buildSequence()) {
      if (ws.readyState !== WebSocket.OPEN) return;
      await sleep(step.delay);
      send(ws, step.msg);
      console.log(`-> ${JSON.stringify(step.msg)}`);
    }
    if (LOOP) await sleep(2500);
  } while (LOOP && ws.readyState === WebSocket.OPEN);
}

const wss = new WebSocketServer({ port: PORT });
wss.on('listening', () => {
  console.log(`[mock-debug-server] listening on ws://localhost:${PORT}`);
  console.log(`[mock-debug-server] scriptsDir = ${SCRIPTS_DIR}`);
  console.log(`[mock-debug-server] tracing    = ${TRACE_FILE}${LOOP ? ' (looping)' : ''}`);
  console.log('[mock-debug-server] connect the extension: "SwoftLang: Connect to Debug Server"');
});
wss.on('connection', (ws) => {
  console.log('[mock-debug-server] client connected');
  ws.on('message', (d) => console.log(`<- ${d.toString().trim()}`));
  ws.on('close', () => console.log('[mock-debug-server] client disconnected'));
  void driveClient(ws);
});
wss.on('error', (e) => console.error('[mock-debug-server] error', e));
