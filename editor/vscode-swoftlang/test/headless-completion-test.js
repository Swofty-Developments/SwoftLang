/* Headless test: drives the compiled context-aware completion engine with a
 * range of line-prefix contexts and asserts the RIGHT bucket comes back (and
 * that the wrong buckets do not). Run: node test/headless-completion-test.js
 * (requires `npm run compile` first). */
'use strict';
const fs = require('fs');
const path = require('path');

const {
  createCompletionEngine,
  braceDepth,
  collectLocals,
} = require('../out/src/completion.js');
const { InsertTextFormat } = require('vscode-languageserver/node');
const data = JSON.parse(
  fs.readFileSync(path.join(__dirname, '..', 'data', 'swoftlang-symbols.json'), 'utf8'),
);
const engine = createCompletionEngine(data);

let fails = 0;
const ok = (c, m) => {
  if (c) console.log('ok:', m);
  else {
    console.error('FAIL:', m);
    fails++;
  }
};
const labels = (items) => new Set(items.map((i) => i.label));
// prefix + optional brace depth
const complete = (prefix, depth = 1, locals = [], ctx = {}) =>
  engine.getCompletions(prefix, depth, locals, ctx);

// --- 1. property access: `player.` -> properties, nothing else ---
{
  const s = labels(complete('player.'));
  ok(s.has('name'), 'after `player.` offers property `name`');
  ok(!s.has('gui'), 'after `player.` does NOT offer declaration `gui`');
  ok(!s.has('send'), 'after `player.` does NOT offer statement keyword `send`');
  ok(!s.has('survival'), 'after `player.` does NOT offer enum member `survival`');
  ok(!s.has('String'), 'after `player.` does NOT offer type `String`');
  const items = complete('event.player.', 3, [], { event: 'PlayerJoin' });
  ok(labels(items).has('location'), 'after `event.player.` offers property `location`');
  ok(
    items.every((i) => i.kind === 10 /* Property */),
    'every item after `.` has CompletionItemKind.Property',
  );
  // deduped: `name` appears exactly once even though many owners expose it
  ok(items.filter((i) => i.label === 'name').length === 1, 'property `name` is deduped to one item');
}

// --- 1b. receiver-type inference: `.` is filtered to the receiver's type ---
{
  // the reported bug: `event.` in an event PlayerJoin handler dumped every type's props
  const evCtx = { event: 'PlayerJoin' };
  const ev = labels(complete('        event.', 3, [], evCtx));
  ok(ev.has('player') && ev.has('first_spawn'), '`event.` in PlayerJoin offers player/first_spawn');
  ok(!ev.has('alignment'), '`event.` does NOT offer Display prop `alignment` (the bug)');
  ok(!ev.has('health'), '`event.` does NOT offer unrelated `health`');
  ok(ev.size === 3, '`event.` offers ONLY PlayerJoin\'s 3 props');

  // chain resolves event -> player (Player) -> Player props, not Display props
  const evp = labels(complete('        event.player.', 3, [], evCtx));
  ok(evp.has('name') && evp.has('health') && evp.has('uuid'), '`event.player.` offers Player props');
  ok(!evp.has('alignment'), '`event.player.` does NOT offer Display prop `alignment`');
  // subtype: Player also exposes OfflinePlayer props
  ok(evp.has('first_seen'), '`event.player.` includes inherited OfflinePlayer prop `first_seen`');

  // deeper chain: event.player.location -> Location props
  const evl = labels(complete('        event.player.location.', 3, [], evCtx));
  ok(evl.has('x') && evl.has('y') && evl.has('z'), '`event.player.location.` offers Location props');
  ok(!evl.has('name'), '`event.player.location.` does NOT offer Player prop `name`');

  // sender -> Player (command execute)
  ok(labels(complete('        sender.')).has('name'), '`sender.` offers Player props');

  // args.<name> -> declared argument type
  const argCtx = { argTypes: { target: 'Player' } };
  ok(labels(complete('        args.target.', 3, [], argCtx)).has('health'), '`args.target.` uses arg type Player');

  // local bound by `spawn mob … as m` -> Mob (+ Entity subtype)
  const mobCtx = { varTypes: { m: 'Mob' } };
  const mob = labels(complete('        m.', 3, [], mobCtx));
  ok(mob.has('custom_id'), '`m.` (spawned mob) offers Mob props');
  ok(mob.has('glowing'), '`m.` includes inherited Entity prop `glowing`');

  // unknown receiver -> offer nothing, never the all-owners wall
  ok(complete('        mystery.').length === 0, 'unknown receiver `mystery.` offers nothing');

  // analyze() wires event + args + var types from real source text
  const src =
    'command "tp" {\n  arguments {\n    target: Player = sender\n  }\n  execute {\n    spawn mob "x" at s as beast\n    ';
  const actx = engine.analyze(src);
  ok(actx.argTypes.target === 'Player', 'analyze() reads argument type target: Player');
  ok(actx.varTypes.beast === 'Mob', 'analyze() reads `spawn mob … as beast` -> Mob');
  const evSrc = 'event PlayerJoin {\n  execute {\n    ';
  ok(engine.analyze(evSrc).event === 'PlayerJoin', 'analyze() finds enclosing event PlayerJoin');
}

// --- 2. type positions -> types only ---
{
  const s = labels(complete('    if args.player is not a '));
  ok(s.has('Player') && s.has('Mob'), 'after `is not a ` offers types Player/Mob');
  ok(!s.has('name'), 'after `is not a ` does NOT offer property `name`');
  ok(!s.has('send'), 'after `is not a ` does NOT offer statement keyword `send`');

  ok(labels(complete('        target: ')).has('String'), 'after `target: ` offers type `String`');
  ok(labels(complete('    x: either<')).has('Player'), 'inside `either<` offers type `Player`');
  ok(labels(complete('    if x is ')).has('Integer'), 'after `is ` offers types');
  const t = complete('    y: ');
  ok(
    t.every((i) => i.kind === 25 /* TypeParameter */),
    'every item in a type position has CompletionItemKind.TypeParameter',
  );
}

// --- 3. statement start inside a block -> statement kw + builtins, not junk ---
{
  const s = labels(complete('        se', 2));
  ok(s.has('send') && s.has('set'), 'statement start offers `send`/`set`');
  ok(s.has('random') || s.has('floor'), 'statement start offers builtins');
  ok(!s.has('survival'), 'statement start does NOT offer enum member `survival`');
  ok(!s.has('command'), 'statement start does NOT offer declaration `command`');
  ok(!s.has('name'), 'statement start does NOT offer property `name`');
}

// --- 4. top level (depth 0) -> declaration keywords only ---
{
  const s = labels(complete('', 0));
  ok(s.has('command') && s.has('event') && s.has('mob'), 'top level offers declaration keywords');
  ok(s.has('persistent') && s.has('storage'), 'top level offers persistent/storage');
  ok(!s.has('send'), 'top level does NOT offer statement keyword `send`');
  ok(!s.has('name'), 'top level does NOT offer property `name`');
}

// --- 5. inside a string -> nothing, or MiniMessage tags after `<` ---
{
  ok(complete('        send "<gray>hello ').length === 0, 'inside a string offers nothing');
  const mm = labels(complete('        send "<'));
  ok(mm.has('red') && mm.has('bold'), 'inside a string after `<` offers MiniMessage tags');
  ok(!mm.has('send'), 'MiniMessage context does NOT offer code symbols');
}

// --- 5b. config property value: `<key>:` -> only that key's enum values ---
{
  const numbers = complete('    numbers: ');
  const nSet = labels(numbers);
  ok(nSet.has('hidden') && nSet.has('shown'), 'after `numbers: ` offers hidden/shown');
  ok(nSet.size === 2, 'after `numbers: ` offers ONLY [hidden, shown]');
  ok(numbers.every((i) => i.kind === 20 /* EnumMember */), '`numbers:` values are EnumMember kind');

  const auth = labels(complete('    auth: '));
  ok(
    auth.has('mojang') && auth.has('velocity') && auth.has('bungeecord') && auth.has('offline'),
    'after `auth: ` offers mojang/velocity/bungeecord/offline',
  );
  ok(!auth.has('String'), 'after `auth: ` does NOT offer types');
  ok(!auth.has('send'), 'after `auth: ` does NOT offer statement keywords');

  const ai = labels(complete('        ai: '));
  ok(ai.has('melee') && ai.has('passive') && ai.has('none') && ai.size === 3, '`ai: ` -> melee/passive/none only');

  const style = labels(complete('    style: '));
  ok(style.has('progress') && style.has('notched_20'), '`style: ` -> bossbar styles');

  // an unknown key (argument type annotation) still falls back to types
  ok(labels(complete('        player: ')).has('Player'), 'unknown key `player: ` falls back to types');
}

// --- 6. expression position -> builtins + consts + operators, not decls/props ---
{
  const s = labels(complete('        set x to floor('));
  ok(s.has('random'), 'expression offers builtins');
  ok(s.has('true') && s.has('none'), 'expression offers constants');
  ok(!s.has('command'), 'expression does NOT offer declaration `command`');
  ok(!s.has('name'), 'expression does NOT offer property `name`');
}

// --- 7. brace depth helper ---
{
  ok(braceDepth('command "x" {\n  execute {\n    ') === 2, 'braceDepth counts nested blocks');
  ok(braceDepth('command "x" {\n}\n') === 0, 'braceDepth returns to 0 after close');
  ok(braceDepth('send "a { b" to sender') === 0, 'braceDepth ignores braces inside strings');
}

// --- 8. resolve attaches documentation for real symbols ---
{
  const rnd = complete('        set x to floor(').find((i) => i.label === 'random');
  const resolved = engine.resolve({ ...rnd });
  ok(!!resolved.documentation, 'resolve attaches documentation to a builtin');
}

// --- 9. snippet completions ---
{
  const send = complete('        se', 2).find((i) => i.label === 'send');
  ok(!!send, 'statement start offers `send`');
  ok(send.insertTextFormat === InsertTextFormat.Snippet, '`send` is a Snippet completion');
  ok(
    typeof send.insertText === 'string' && send.insertText.includes('"$1"'),
    '`send` snippet inserts `"$1"` with a tab stop inside the quotes',
  );
  const cmd = complete('', 0).find((i) => i.label === 'command');
  ok(cmd && cmd.insertTextFormat === InsertTextFormat.Snippet, '`command` declaration is a Snippet');
  ok(cmd && cmd.insertText.includes('execute'), '`command` snippet scaffolds an execute block');
  // trivial keywords stay plain
  const halt = complete('        ha', 2).find((i) => i.label === 'halt');
  ok(!halt || halt.insertTextFormat === undefined, '`halt` stays a plain-text completion');
  // a property named `command` must NOT get the declaration snippet
  const propCmd = complete('event.').find((i) => i.label === 'command');
  ok(!propCmd || propCmd.insertTextFormat === undefined, 'property `command` is not a snippet');
}

// --- 10. local variable completion ---
{
  const src =
    'command "s" {\n  execute {\n    set score to 5\n    spawn mob "m" at loc as beast\n    ';
  const depth = braceDepth(src);
  const locals = collectLocals(src);
  ok(locals.includes('score'), 'collectLocals finds `set score to`');
  ok(locals.includes('beast'), 'collectLocals finds `spawn … as beast`');

  // at a fresh statement line inside the execute block, `score` shows as a Variable
  const items = complete('    ', depth, locals);
  const score = items.find((i) => i.label === 'score');
  ok(!!score && score.kind === 6 /* Variable */, '`score` appears as a Variable at statement start');
  // variables are sorted before keywords/builtins
  const scoreSort = score.sortText;
  const sendItem = items.find((i) => i.label === 'send');
  ok(sendItem && scoreSort < sendItem.sortText, 'local variables sort before statement keywords');

  // in an expression position the local is also offered, still no property `name`
  const expr = complete('    set x to ', depth, locals);
  const exprLabels = labels(expr);
  ok(exprLabels.has('beast'), 'local `beast` offered in expression position');
  ok(!exprLabels.has('name'), 'expression still does NOT offer property `name`');

  // function params and persistent names are collected
  const src2 = 'persistent visits: Integer = 0\nfunction key(loc: Location, n) {\n  ';
  const l2 = collectLocals(src2);
  ok(l2.includes('visits'), 'collectLocals finds persistent `visits`');
  ok(l2.includes('loc') && l2.includes('n'), 'collectLocals finds function params');
}

// --- 11. comprehensive enum-value contexts driven by the symbol dump ---
{
  const rarity = labels(complete('    rarity: '));
  ok(rarity.has('common') && rarity.has('epic') && rarity.size === 4, '`rarity: ` -> rarity enum values');
  const weather = labels(complete('    weather: '));
  ok(weather.has('clear') && weather.has('thunder'), '`weather: ` -> weather enum values');
  const color = labels(complete('    color: '));
  ok(color.has('pink') && color.has('purple'), '`color: ` -> bossbar_color values');
  const method = labels(complete('    method: '));
  ok(method.has('GET') && method.has('DELETE'), '`method: ` -> api_method values');
  const medium = labels(complete('    medium: '));
  ok(medium.has('water') && medium.has('lava') && medium.size === 2, '`medium: ` -> fishing_medium values');
  const pose = labels(complete('    pose: '));
  ok(pose.has('standing') && pose.has('sneaking'), '`pose: ` -> pose enum values');
}

// --- 12. attribute keys inside an `attributes { }` block ---
{
  const a = complete('        ', 2, [], { block: 'attributes' });
  const s = labels(a);
  ok(s.has('max_health') && s.has('attack_damage'), '`attributes {` offers attribute keys');
  ok(!s.has('send'), '`attributes {` does NOT offer statement keyword `send`');
  ok(a.every((i) => i.kind === 20 /* EnumMember */), 'attribute keys are EnumMember kind');
}

// --- 13. decl body: config keys + inline handlers + namespaces + statements ---
{
  const it = labels(complete('        ', 2, [], { block: 'item' }));
  ok(it.has('material'), 'item body offers config key `material`');
  ok(it.has('on_click') && it.has('on_break'), 'item body offers inline handler snippets');
  ok(it.has('tags') && it.has('attributes'), 'item body offers tags/attributes namespaces');
  ok(it.has('send'), 'item body still offers statement keywords');
  const oc = complete('        ', 2, [], { block: 'mob' }).find((i) => i.label === 'on_click');
  ok(oc && oc.insertTextFormat === InsertTextFormat.Snippet, 'inline handler `on_click` is a Snippet');
  ok(oc && oc.insertText.includes('left,right'), 'on_click snippet offers left/right filter choice');
}

// --- 14. comprehensive builtin breadth (all 117, incl. bare ones) ---
{
  const expr = labels(complete('        set x to ', 2));
  for (const b of ['gradient', 'sqrt', 'players_in_radius', 'rainbow', 'distance', 'vec']) {
    ok(expr.has(b), `expression offers builtin \`${b}\``);
  }
}

// --- 15. analyze() reports the enclosing block ---
{
  ok(engine.analyze('item "x" {\n  attributes {\n    ').block === 'attributes', 'analyze() reports enclosing `attributes` block');
  ok(engine.analyze('command "c" {\n  execute {\n    ').block === 'execute', 'analyze() reports enclosing `execute` block');
}

// --- 16. Packet blocks: class-name completion is client-only; field completion
//     scopes to the enclosing on-block's class; scaffold binds every field ---
{
  const packetData = JSON.parse(
    fs.readFileSync(path.join(__dirname, '..', 'data', 'packets.json'), 'utf8'),
  );
  const pEngine = createCompletionEngine(data, packetData);
  const pComplete = (prefix, depth = 1, locals = [], ctx = {}) =>
    pEngine.getCompletions(prefix, depth, locals, ctx);

  // `Packet { on "<CURSOR>" }` — inbound client packets only, never outbound.
  const cls = pComplete('    on "', 2, [], { block: 'Packet' });
  const clsL = labels(cls);
  ok(clsL.has('ClientChatMessagePacket'), '`on "` offers inbound client packet ClientChatMessagePacket');
  ok(clsL.has('ClientPlayerActionPacket'), '`on "` offers inbound client packet ClientPlayerActionPacket');
  ok(!clsL.has('ActionBarPacket'), '`on "` does NOT offer outbound server packet ActionBarPacket');
  ok(cls.length > 0 && cls.every((i) => i.detail === 'inbound · client packet'),
    'every `on "` class item is an inbound client packet');

  // `packet.<CURSOR>` scopes to the enclosing on-block's class.
  const chat = labels(pComplete('        set v to packet.', 3, [], { packetClass: 'ClientChatMessagePacket' }));
  ok(chat.has('message') && chat.has('timestamp') && chat.has('checksum'),
    '`packet.` in a ClientChatMessagePacket block offers its fields');
  ok(!chat.has('block_face') && !chat.has('sequence'),
    '`packet.` does NOT leak another packet\'s fields (block_face/sequence)');
  const act = labels(pComplete('        set v to packet.', 3, [], { packetClass: 'ClientPlayerActionPacket' }));
  ok(act.has('block_face') && act.has('sequence') && !act.has('message'),
    '`packet.` in a ClientPlayerActionPacket block scopes to ITS fields');

  // scaffold snippet binds every field of the enclosing packet.
  const scaffold = pComplete('        ', 3, [], { packetClass: 'ClientChatMessagePacket' })
    .find((i) => i.label === 'scaffold packet fields');
  ok(!!scaffold && scaffold.insertTextFormat === InsertTextFormat.Snippet, 'scaffold item is a Snippet');
  const chatFields = packetData.packets.ClientChatMessagePacket.fields;
  ok(scaffold && chatFields.every((f) => scaffold.insertText.includes(`to packet.${f.name}`)),
    `scaffold binds all ${chatFields.length} ClientChatMessagePacket fields`);
}

// --- 17. v1.10.0 network persistence: storage topology keys/values, change
//     handlers + their bound names, atomic write ops ---
{
  const { createCompletionEngine: mk } = require('../out/src/completion.js');
  const pe = mk(data);
  const an = (t) => pe.analyze(t);

  // 17a. `storage { }` body -> exactly the five topology keys, nothing else.
  const storage = pe.getCompletions('    ', 1, [], an('storage {\n    '));
  const sL = labels(storage);
  for (const k of ['mode', 'backend', 'flush', 'coordinator', 'on_handoff_failure']) {
    ok(sL.has(k), `storage block offers \`${k}\``);
  }
  ok(sL.size === 5, 'storage block offers ONLY the five topology keys');
  ok(!sL.has('send') && !sL.has('command'), 'storage block does NOT offer statements/declarations');

  // 17b. the value positions.
  const mode = labels(complete('    mode: '));
  ok(mode.has('standalone') && mode.has('network') && mode.size === 2,
    '`mode: ` -> standalone/network only');
  const coord = labels(complete('    coordinator: '));
  ok(coord.has('redis') && coord.size === 1, '`coordinator: ` -> redis only');
  const hf = labels(complete('    on_handoff_failure: '));
  ok(hf.has('kick') && hf.size === 1, '`on_handoff_failure: ` -> kick only');
  const be = labels(complete('    backend: '));
  ok(be.has('files') && be.has('sqlite') && be.has('mysql') && be.has('mongodb') && be.size === 4,
    '`backend: ` -> the four backends only');

  // 17c. `backend: mysql { }` -> the connection keys.
  const conn = labels(pe.getCompletions('        ', 2, [], an('storage {\n    backend: mysql {\n        ')));
  ok(['host', 'port', 'database', 'user', 'password'].every((k) => conn.has(k)),
    '`backend: mysql { }` offers host/port/database/user/password');
  ok(conn.size === 5, '`backend: mysql { }` offers ONLY the connection keys');

  // 17d. `persistent … { }` -> the two change handlers only.
  const pdecl = labels(pe.getCompletions('    ', 1, [],
    an('persistent boss_active: Boolean = false {\n    ')));
  ok(pdecl.has('on_change') && pdecl.has('on_entry_change') && pdecl.size === 2,
    '`persistent … { }` offers exactly on_change/on_entry_change');

  // 17e. `on_change` on a `for Player` decl -> player/old/new/caused_here.
  const pCtx = an('persistent coins for Player: Integer = 0 {\n    on_change {\n        ');
  ok(pCtx.changeHandler === 'on_change' && pCtx.changeSubject === 'player',
    'analyze() sees on_change on a `for Player` decl');
  const pBind = labels(pe.getCompletions('        ', 2, [], pCtx));
  for (const b of ['player', 'old', 'new', 'caused_here']) {
    ok(pBind.has(b), `on_change (for Player) offers bound var \`${b}\``);
  }
  ok(!pBind.has('key'), 'on_change on a `for Player` decl does NOT offer `key`');

  // 17f. `on_change` on a `for String` decl binds `key`, not `player`.
  const kCtx = an('persistent scores for String: Integer = 0 {\n    on_change {\n        ');
  ok(kCtx.changeSubject === 'key', 'analyze() binds `key` for a `for String` decl');
  const kItems = pe.getCompletions('        ', 2, [], kCtx);
  const boundVar = (items, name) =>
    items.some((i) => i.label === name && i.kind === 6 /* Variable */);
  ok(boundVar(kItems, 'key') && !boundVar(kItems, 'player'),
    'on_change (for String) binds `key`, not `player` (the `player(…)` builtin is unaffected)');

  // 17g. `on_entry_change` on a Map always binds the entry `key`.
  const eCtx = an('persistent leaderboard: Map<String, Integer> = new_map() {\n    on_entry_change {\n        ');
  ok(eCtx.changeHandler === 'on_entry_change', 'analyze() sees on_entry_change');
  const eBind = labels(pe.getCompletions('        ', 2, [], eCtx));
  for (const b of ['key', 'old', 'new', 'caused_here']) {
    ok(eBind.has(b), `on_entry_change offers bound var \`${b}\``);
  }
  const oldItem = pe.getCompletions('        ', 2, [], eCtx).find((i) => i.label === 'old');
  ok(oldItem && /Optional<V>/.test(oldItem.detail || ''), 'on_entry_change `old` is described as Optional<V>');

  // bound vars are also offered in expression position inside the handler.
  const eExpr = labels(pe.getCompletions('        if ', 2, [], eCtx));
  ok(eExpr.has('caused_here'), 'bound vars are offered in expression position too');
  // ... and NOT outside a change handler.
  const outside = labels(complete('        ', 2, [], {}));
  ok(!outside.has('caused_here'), '`caused_here` is NOT offered outside a change handler');

  // 17h. atomic write ops.
  const atomic = pe.getCompletions('        ', 2, [], eCtx);
  const aL = labels(atomic);
  for (const l of ['add … to', 'subtract … from', 'append … to', 'grant … to']) {
    ok(aL.has(l), `change handler offers atomic op \`${l}\``);
  }
  const grant = atomic.find((i) => i.label === 'grant … to');
  ok(grant && grant.insertTextFormat === InsertTextFormat.Snippet, 'atomic `grant` is a Snippet');
  // they are also plain statement keywords in the general palette.
  const stmts = labels(complete('        ', 2));
  ok(stmts.has('add') && stmts.has('subtract') && stmts.has('append') && stmts.has('grant'),
    'atomic ops are offered as statement keywords in a normal body');

  // 17i. every persistence keyword from the dump carries a doc in the LSP data.
  const bySym = new Map(data.symbols.filter((s) => s.kind === 'keyword').map((s) => [s.name, s]));
  for (const k of ['mode', 'standalone', 'network', 'on_handoff_failure', 'coordinator',
                   'kick', 'redis', 'on_change', 'on_entry_change', 'old', 'new',
                   'caused_here', 'key', 'player', 'subtract', 'append', 'grant']) {
    ok(bySym.has(k) && !!bySym.get(k).doc, `LSP data carries \`${k}\` with a doc`);
  }
}

console.log(fails === 0 ? '\nALL COMPLETION TESTS PASSED' : `\n${fails} FAILURE(S)`);
process.exit(fails === 0 ? 0 : 1);
