/* Headless test: run the real swoftc on a broken/warning/clean .sw and apply the
 * SAME parsing the LSP uses (DIAG_RE + stdout JSON), asserting 0-based positions.
 * Run: node test/headless-diag-test.js */
'use strict';
const cp = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');

const SWOFTC = process.env.SWOFTC ||
  '/mnt/work/VSC/SwoftLang/compiler/_build/default/bin/main.exe';

// Must match src/server.ts
const DIAG_RE = /^(.*?):(\d+):(\d+):\s*(error|warning):\s*(.*)$/;
function clamp(line, col) { return { line: Math.max(0, line - 1), character: Math.max(0, col - 1) }; }

function check(content) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'swtest-'));
  const f = path.join(dir, 'buf.sw');
  fs.writeFileSync(f, content);
  const r = cp.spawnSync(SWOFTC, ['check', f], { encoding: 'utf8' });
  const diags = [];
  for (const raw of (r.stderr || '').split(/\r?\n/)) {
    const m = DIAG_RE.exec(raw.trim());
    if (!m) continue;
    diags.push({ severity: m[4], pos: clamp(+m[2], +m[3]), message: m[5] });
  }
  const t = (r.stdout || '').trim();
  let stdoutErr = null;
  if (t.startsWith('{')) { try { const o = JSON.parse(t); if (o.error) stdoutErr = o.error; } catch {} }
  fs.rmSync(dir, { recursive: true, force: true });
  return { diags, stdoutErr, code: r.status };
}

let fails = 0;
const ok = (c, m) => { if (c) console.log('ok:', m); else { console.error('FAIL:', m); fails++; } };

// 1) syntax error: `command test {` -> error at 1:9 (1-based) => 0:8
const bad = check('command test {\n  execute {\n  }\n}\n');
ok(bad.code === 1, 'broken file exits non-zero');
ok(bad.diags.length >= 1 && bad.diags[0].severity === 'error', 'error diagnostic parsed');
ok(bad.diags[0].pos.line === 0 && bad.diags[0].pos.character === 8,
  `error mapped to 0-based line 0 col 8 (got ${bad.diags[0].pos.line}:${bad.diags[0].pos.character})`);
ok(bad.stdoutErr && bad.stdoutErr.line === 1 && bad.stdoutErr.col === 9,
  'stdout JSON reports 1-based line 1 col 9');

// 2) warning: big fill volume -> warning severity, exit 0
const warn = check('command "x" {\n  execute {\n    fill blocks from location(0,0,0) to location(1000,1000,1000) with "stone"\n  }\n}\n');
ok(warn.code === 0, 'warning-only file exits 0');
ok(warn.diags.some((d) => d.severity === 'warning'), 'warning diagnostic parsed as Warning severity');
const w = warn.diags.find((d) => d.severity === 'warning');
ok(w && w.pos.line === 2, `warning mapped to 0-based line 2 (got ${w && w.pos.line})`);

// 3) clean file: no diagnostics
const clean = check('command "hi" {\n  execute {\n    send "hello" to sender\n  }\n}\n');
ok(clean.code === 0 && clean.diags.length === 0, 'clean file yields no diagnostics');

console.log(fails === 0 ? '\nALL DIAGNOSTIC TESTS PASSED' : `\n${fails} FAILURE(S)`);
process.exit(fails === 0 ? 0 : 1);
