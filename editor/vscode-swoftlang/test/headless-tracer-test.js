/* Headless test: drive the compiled DebugTracer with a fake `vscode` module and
 * assert that trace/handler/reload messages decorate the correct 0-based lines.
 * Run: node test/headless-tracer-test.js   (after `npm run compile`) */
'use strict';
const path = require('path');
const Module = require('module');

// ---- capture buffers ----
const decorationCalls = []; // {editor, typeId, ranges}
const statusMessages = [];
const infoMessages = [];
const errorMessages = [];
const docChangeListeners = []; // workspace.onDidChangeTextDocument subscribers

let typeCounter = 0;
function fakeEditor(uriStr) {
  return {
    document: { uri: { toString: () => uriStr, fsPath: uriStr } },
    revealRange() {},
    setDecorations(type, ranges) {
      decorationCalls.push({ editor: uriStr, typeId: type.__id, ranges });
    },
  };
}

const flashUri = 'file:///ws/scripts/events.sw';
const editors = [fakeEditor(flashUri)];

const vscodeStub = {
  StatusBarAlignment: { Left: 1, Right: 2 },
  OverviewRulerLane: { Center: 2 },
  TextEditorRevealType: { InCenterIfOutsideViewport: 2 },
  Range: class {
    constructor(sl, sc, el, ec) {
      this.start = { line: sl, character: sc };
      this.end = { line: el, character: ec };
    }
  },
  Uri: { file: (p) => ({ fsPath: p, toString: () => 'file://' + p }) },
  window: {
    visibleTextEditors: editors,
    createOutputChannel: () => ({ appendLine() {}, dispose() {} }),
    createStatusBarItem: () => ({
      text: '', tooltip: '', command: '', show() {}, hide() {}, dispose() {},
    }),
    createTextEditorDecorationType: () => ({ __id: ++typeCounter, dispose() {} }),
    setStatusBarMessage: (m) => statusMessages.push(m),
    showInformationMessage: (m) => infoMessages.push(m),
    showErrorMessage: (m) => errorMessages.push(m),
    showTextDocument: async () => editors[0],
  },
  workspace: {
    openTextDocument: async () => ({}),
    // the tracer subscribes to document edits so it can drop pulses whose line
    // numbers just shifted; the stub records the listener as a disposable.
    onDidChangeTextDocument: (fn) => {
      docChangeListeners.push(fn);
      return { dispose() {} };
    },
  },
};

// intercept require('vscode')
const origLoad = Module._load;
Module._load = function (request, parent, isMain) {
  if (request === 'vscode') return vscodeStub;
  return origLoad.call(this, request, parent, isMain);
};

const { DebugTracer } = require(path.join(__dirname, '..', 'out', 'src', 'tracer.js'));

// ---- host that maps "scripts/events.sw" -> our fake editor's uri ----
const host = {
  resolveFile(file) {
    if (file === 'scripts/events.sw') return vscodeStub.Uri.file('/ws/scripts/events.sw');
    return undefined;
  },
  scriptsDir: () => '/ws/scripts',
  setScriptsDirFromHello() {},
  autoReveal: () => true,
  // off by default in the extension, so the tracer never hijacks the scroll
  followExecution: () => false,
};
const context = { subscriptions: [] };

const tracer = new DebugTracer(host, context, () => 25580, () => 'localhost');

let failures = 0;
function assert(cond, msg) {
  if (!cond) { console.error('FAIL:', msg); failures++; }
  else console.log('ok:', msg);
}

// the fake editor uses the key 'file:///ws/scripts/events.sw'; make resolveFile
// produce that exact key so findEditor matches.
host.resolveFile = (file) =>
  file === 'scripts/events.sw' ? { fsPath: '/ws/scripts/events.sw', toString: () => flashUri } : undefined;

// --- drive: hello, handler enter, trace on line 18 (1-based) ---
tracer.dispatch({ type: 'hello', protocol: 1, scriptsDir: '/ws/scripts' });
tracer.dispatch({ type: 'handler', phase: 'enter', file: 'scripts/events.sw', line: 14, name: 'event PlayerBeginItemUse' });
tracer.dispatch({ type: 'trace', file: 'scripts/events.sw', line: 18, col: 9, kind: 'send', handler: 'event PlayerBeginItemUse', seq: 41 });

// onTrace is async (may await reveal); give the microtask queue a beat.
setTimeout(() => {
  // Find the strongest (flash) decoration call that has a non-empty range set.
  const flashCalls = decorationCalls.filter((c) => c.ranges && c.ranges.length > 0);
  assert(flashCalls.length > 0, 'a decoration with a range was applied for the trace');
  const decoratedLines = new Set();
  for (const c of flashCalls) for (const r of c.ranges) decoratedLines.add(r.start.line);
  // protocol line 18 (1-based) must decorate editor line 17 (0-based)
  assert(decoratedLines.has(17), 'trace line 18 (1-based) decorated 0-based line 17');
  assert(!decoratedLines.has(18), 'did NOT decorate line 18 (would be an off-by-one)');

  // handler-enter marker at line 14 -> 0-based line 13
  // (rendered via handlerMarker; captured in decorationCalls too)
  assert([...decoratedLines].includes(13) || decorationCalls.some(c => (c.ranges||[]).some(r => r.start.line === 13)),
    'handler enter line 14 (1-based) marked 0-based line 13');

  // reload messages surface as toasts
  tracer.dispatch({ type: 'reload', file: 'scripts/events.sw', ok: true });
  tracer.dispatch({ type: 'reload', file: 'scripts/events.sw', ok: false, error: 'events.sw:20:9: error: boom' });
  assert(infoMessages.some((m) => /reloaded events\.sw/.test(m)), 'reload ok produced an info toast');
  assert(errorMessages.some((m) => /reload FAILED events\.sw/.test(m)), 'reload error produced an error toast');

  tracer.dispose();
  console.log(failures === 0 ? '\nALL TRACER TESTS PASSED' : `\n${failures} FAILURE(S)`);
  process.exit(failures === 0 ? 0 : 1);
}, 100);
