#!/usr/bin/env node
// Generates data/swoftlang-symbols.json for the SwoftLang VS Code extension.
//
// Breadth (the full surface — every keyword, builtin, type, enum group, handler,
// namespace and per-type property) is DRIVEN BY editor/swoftlang-symbols.json,
// the canonical symbol dump. On top of that we enrich with:
//   * Live property rows      -> `swoftc --property-table` (event:<Name> owners with
//                                real field names, plus the base types). Falls back
//                                to the bundled property-table.raw.json dump.
//   * Builtin signatures/docs -> transcribed from compiler/lib/registry.ml below.
//   * Event field docs        -> curated below.
//
// The editor dump is the source of truth for WHICH symbols exist; this script
// only layers signatures/docs/owner-precise property types onto it and writes a
// single flat { symbols, enums } table the LSP consumes.
//
// Re-run with: node scripts/gen-symbols.js  (optionally SWOFTC=/path/to/main.exe)
'use strict';
const fs = require('fs');
const path = require('path');
const cp = require('child_process');

const DATA = path.join(__dirname, '..', 'data');
// editor/swoftlang-symbols.json — two dirs up from editor/vscode-swoftlang/scripts.
const EDITOR_DUMP = path.join(__dirname, '..', '..', 'swoftlang-symbols.json');

// --- the canonical symbol dump (breadth) ---
function loadEditorDump() {
  return JSON.parse(fs.readFileSync(EDITOR_DUMP, 'utf8'));
}

// --- property rows: prefer a live `--property-table`, else the bundled dump ---
function loadProperties() {
  const bin = process.env.SWOFTC ||
    '/mnt/work/VSC/SwoftLang/compiler/_build/default/bin/main.exe';
  try {
    if (fs.existsSync(bin)) {
      const out = cp.execFileSync(bin, ['--property-table'], { encoding: 'utf8' });
      return JSON.parse(out);
    }
  } catch (e) { /* fall through to bundled dump */ }
  const raw = path.join(DATA, 'property-table.raw.json');
  return JSON.parse(fs.readFileSync(raw, 'utf8'));
}

// keywords/operators/constants that are grammar surface but not in the editor
// dump's keyword list (block keys, connectors, time units). Unioned in below.
const EXTRA_KEYWORDS = [
  'go back', 'subtitle', 'with', 'for', 'manual',
  'execute', 'arguments', 'slot', 'slots', 'editable', 'paginate', 'state',
  'render', 'lines', 'column', 'source', 'refresh', 'border', 'prev_slot',
  'next_slot', 'ticks', 'seconds', 'millis', 'lore', 'drops', 'catch', 'reply',
  'code', 'weight', 'chance', 'message', 'permission', 'description',
];

const operators = [
  'is', 'is not', 'is a', 'is an', 'is not a', 'is not an', 'is missing',
  'contains', 'and', 'or', 'not', 'exists', 'otherwise', 'missing', 'either',
];

const constants = ['true', 'false', 'none', 'all', 'sender'];

// Extra type spellings the grammar accepts (Number/int/bool/Schedule).
const EXTRA_TYPES = ['Number', 'int', 'bool', 'Schedule'];

// --- builtin signatures transcribed from registry.ml (name -> {sigs, doc}) ---
// The LIST of builtins comes from the editor dump; this table only supplies the
// signature/doc for the ones we have transcribed. Builtins absent here are
// emitted bare (name only), so completion still offers them.
const BUILTIN_SIGS = {
  random: [['random(min: Number, max: Number): Integer'], 'Random integer in [min, max].'],
  round: [['round(n: Number): Integer'], 'Round to the nearest integer.'],
  floor: [['floor(n: Number): Integer'], 'Round down to an integer.'],
  ceil: [['ceil(n: Number): Integer'], 'Round up to an integer.'],
  abs: [['abs(n: Number): Number'], 'Absolute value (keeps Integer/Double).'],
  uppercase: [['uppercase(s: String): String'], 'Uppercase a string.'],
  lowercase: [['lowercase(s: String): String'], 'Lowercase a string.'],
  length: [['length(x: String|list): Integer'], 'Length of a string or list.'],
  location: [['location(x, y, z): Location', 'location(x, y, z, yaw, pitch): Location'], 'Build a Location.'],
  in_front_of: [['in_front_of(e: Entity, dist: Number): Location'], 'Location dist blocks ahead of an entity.'],
  item: [['item(material: String): Item', 'item(material: String, amount: Number): Item'], 'Build an Item stack.'],
  player: [['player(name: String): optional<Player>'], 'Look up an online player by name.'],
  all_players: [['all_players(): list<Player>'], 'Every online player.'],
  world: [['world(name: String): optional<World>'], 'Look up a loaded world by name.'],
  centered: [['centered(s: String): String'], 'Center a chat string.'],
  prompt_input: [['prompt_input(p: Player, msg: String): String'], 'async only: prompt a player for chat input.'],
  min: [['min(a: Number, b: Number): Number'], 'Smaller of two numbers.'],
  max: [['max(a: Number, b: Number): Number'], 'Larger of two numbers.'],
  clamp: [['clamp(n, lo, hi): Number'], 'Clamp n into [lo, hi].'],
  format_number: [['format_number(n: Number): String'], 'Group-separated number string.'],
  custom_item: [['custom_item(id: String): Item'], 'Instantiate a registered custom item.'],
  custom_id: [['custom_id(i: Item): optional<String>'], 'Custom-item id of a stack, if any.'],
  all_mobs: [['all_mobs(): list<Mob>', 'all_mobs(type: String): list<Mob>'], 'Every mob (optionally by type).'],
  velocity: [['velocity(x, y, z): Vec'], 'Build a velocity vector (blocks/tick).'],
  vec: [['vec(x, y, z): Vec'], 'Build a vector.'],
  all_entities: [['all_entities(): list<Entity>', 'all_entities(type: String): list<Entity>'], 'Every live entity (optionally by type).'],
  spawn_text_display: [['spawn_text_display(text: String, at: Location): Display'], 'Spawn a text display entity.'],
  spawn_item_display: [['spawn_item_display(item: String, at: Location): Display'], 'Spawn an item display entity.'],
  spawn_block_display: [['spawn_block_display(block: String, at: Location): Display'], 'Spawn a block display entity.'],
  song: [['song(file: String): Song'], 'Load NBS song metadata.'],
  tps_string: [['tps_string(): String'], 'Colored current TPS string.'],
  average_tps_string: [['average_tps_string(): String'], 'Colored average TPS string.'],
  tps_at: [['tps_at(secondsAgo: Number): Double'], 'TPS sample from N seconds ago.'],
  anvil_loader: [['anvil_loader(path: String): WorldLoader'], 'An Anvil-format world loader.'],
  polar_loader: [['polar_loader(path: String): WorldLoader'], 'A Polar-format world loader.'],
  world_exists: [['world_exists(name: String, loader): Boolean'], 'Whether a world exists for a loader.'],
  all_worlds: [['all_worlds(loader): list<String>'], 'World names known to a loader.'],
  block_at: [['block_at(loc: Location): String'], 'Block id at a location.'],
  block: [['block(id: String): Block'], 'Build a Block from an id.'],
  skin: [['skin(texture: String, signature: String): Skin'], 'Build a Skin from texture+signature.'],
  fetch_skin: [['fetch_skin(name: String): optional<Skin>'], 'async only: fetch a skin from Mojang.'],
  map_canvas: [['map_canvas(): Canvas'], 'Allocate a 128x128 map canvas.'],
  new_map: [['new_map(): map'], 'Create an empty map (typed by context).'],
  has_permission: [['has_permission(p: Player, node: String): Boolean'], 'Permission check.'],
  offline_player: [['offline_player(name: String): optional<OfflinePlayer>'], 'Seen-store lookup by name.'],
  offline_player_uuid: [['offline_player_uuid(uuid: String): OfflinePlayer'], 'Construct an OfflinePlayer identity.'],
  fetch_offline_player: [['fetch_offline_player(name: String): optional<OfflinePlayer>'], 'async only: resolve name->uuid via Mojang.'],
  all_seen_players: [['all_seen_players(): list<OfflinePlayer>'], 'Every seen-store player.'],
  map_get: [['map_get(m, key): optional', 'shorthand: m[key]'], 'Read a map value.'],
  map_set: [['map_set(m, key, value)'], 'Write a map value.'],
  map_has: [['map_has(m, key): Boolean'], 'Whether a key exists.'],
  map_delete: [['map_delete(m, key)'], 'Remove a key.'],
  map_keys: [['map_keys(m): list'], 'Keys of a map.'],
  map_size: [['map_size(m): Integer'], 'Entry count of a map.'],
  random_float: [['random_float(min, max): Double'], 'Random double in [min, max].'],
  random_double: [['random_double(min, max): Double'], 'Random double in [min, max].'],
  random_int: [['random_int(min, max): Integer'], 'Random integer in [min, max].'],
  random_chance: [['random_chance(p: Number): Boolean'], 'True with probability p (0..1).'],
  chance: [['chance(p: Number): Boolean'], 'True with probability p (0..1).'],
  random_bool: [['random_bool(): Boolean'], 'Random coin flip.'],
  random_in: [['random_in(coll): optional'], 'Random element of a list/string.'],
  random_element: [['random_element(coll): optional'], 'Random element of a collection.'],
  random_uuid: [['random_uuid(): String'], 'A fresh random UUID string.'],
  random_seed: [['random_seed(n: Integer)'], 'Seed the RNG for reproducible runs.'],
  shuffle: [['shuffle(coll): list'], 'Shuffled copy of a collection.'],
  sort: [['sort(coll): list'], 'Sorted copy (natural order).'],
  sort_by: [['sort_by(coll, keyLambda): list'], 'Sort ascending by a key.'],
  sort_by_desc: [['sort_by_desc(coll, keyLambda): list'], 'Sort descending by a key.'],
  reverse: [['reverse(coll): list'], 'Reversed copy.'],
  min_by: [['min_by(coll, keyLambda): optional'], 'Element with the smallest key.'],
  max_by: [['max_by(coll, keyLambda): optional'], 'Element with the largest key.'],
  sort_by_key: [['sort_by_key(m): map'], 'Sort a map ascending by key.'],
  sort_by_key_desc: [['sort_by_key_desc(m): map'], 'Sort a map descending by key.'],
  sort_by_value: [['sort_by_value(m): map'], 'Sort a map ascending by value.'],
  sort_by_value_desc: [['sort_by_value_desc(m): map'], 'Sort a map descending by value.'],
  sort_map_by: [['sort_map_by(m, keyLambda): map'], 'Sort a map by a derived key.'],
  sort_map_by_desc: [['sort_map_by_desc(m, keyLambda): map'], 'Sort a map descending by a derived key.'],
  sum: [['sum(coll): Number'], 'Sum of a numeric collection.'],
  product: [['product(coll): Number'], 'Product of a numeric collection.'],
  mod: [['mod(a: Number, b: Number): Number'], 'Modulo (remainder).'],
  sqrt: [['sqrt(n: Number): Double'], 'Square root.'],
  pow: [['pow(base: Number, exp: Number): Double'], 'Raise base to a power.'],
  round_to: [['round_to(n: Number, places: Integer): Double'], 'Round to N decimal places.'],
  format_decimals: [['format_decimals(n: Number, places: Integer): String'], 'Fixed-decimal string.'],
  sin: [['sin(x: Number): Double'], 'Sine (radians).'],
  cos: [['cos(x: Number): Double'], 'Cosine (radians).'],
  tan: [['tan(x: Number): Double'], 'Tangent (radians).'],
  asin: [['asin(x: Number): Double'], 'Arc sine.'],
  acos: [['acos(x: Number): Double'], 'Arc cosine.'],
  atan: [['atan(x: Number): Double'], 'Arc tangent.'],
  atan2: [['atan2(y: Number, x: Number): Double'], 'Two-argument arc tangent.'],
  ln: [['ln(x: Number): Double'], 'Natural logarithm.'],
  log: [['log(x: Number): Double'], 'Natural logarithm.'],
  log10: [['log10(x: Number): Double'], 'Base-10 logarithm.'],
  pi: [['pi(): Double'], 'The constant pi.'],
  e: [['e(): Double'], "Euler's number."],
  sign: [['sign(n: Number): Integer'], 'Sign of a number (-1, 0, 1).'],
  parse: [['parse(s: String): optional<Number>'], 'Parse a number from a string.'],
  matches: [['matches(s: String, regex: String): Boolean'], 'Regex match test.'],
  stripped: [['stripped(s: String): String'], 'String with color/format stripped.'],
  formatted: [['formatted(s: String): String'], 'MiniMessage-formatted string.'],
  type_of: [['type_of(x): String'], 'Runtime type name of a value.'],
  strip_color: [['strip_color(s: String): String'], 'Remove color codes.'],
  legacy_to_mini: [['legacy_to_mini(s: String): String'], 'Convert legacy §-codes to MiniMessage.'],
  gradient: [['gradient(from: String, to: String, text: String): String'], 'Color a string with a gradient.'],
  rainbow: [['rainbow(text: String): String'], 'Rainbow-color a string.'],
  distance: [['distance(a: Location, b: Location): Double'], 'Distance between two locations.'],
  direction_from: [['direction_from(a: Location, b: Location): Vec'], 'Unit vector from a toward b.'],
  above: [['above(loc: Location, n: Number): Location'], 'Location n blocks above.'],
  below: [['below(loc: Location, n: Number): Location'], 'Location n blocks below.'],
  is_within: [['is_within(loc: Location, center: Location, radius: Number): Boolean'], 'Whether loc is within radius of center.'],
  blocks_in_radius: [['blocks_in_radius(center: Location, radius: Number): list<Location>'], 'Block locations within a radius.'],
  players_in_radius: [['players_in_radius(center: Location, radius: Number): list<Player>'], 'Players within a radius.'],
  location_of: [['location_of(e: Entity): Location'], 'An entity current location.'],
  is_running: [['is_running(name: String): Boolean'], 'Whether a named schedule is running.'],
  to_nbt: [['to_nbt(i: Item): String'], 'Serialize an item stack to NBT.'],
  from_nbt: [['from_nbt(s: String): optional<Item>'], 'Parse an item stack from NBT.'],
};

// curated event field docs (registry.ml `events`)
const EVENT_DOCS = {
  PlayerChat: [true, 'player, message, cancelled'],
  PlayerJoin: [false, 'player, first_spawn, world'],
  PlayerUseItem: [true, 'player, item, custom_id, cancelled'],
  MobSpawn: [false, 'mob'],
  MobDeath: [false, 'mob, killer'],
  MobDamage: [true, 'mob, damage, cancelled'],
  TpsChange: [false, 'past, current'],
  BlockBreak: [true, 'player, block, location, cancelled'],
  BlockPlace: [true, 'player, block, location, cancelled'],
  ServerPing: [false, 'motd, online, max'],
  PlayerCommand: [true, 'player, command, cancelled'],
  PlayerCastRod: [true, 'player, cancelled'],
  FishBite: [false, 'player, hook_location'],
  PlayerCatchFish: [true, 'player, caught_item, caught_mob, cancelled'],
  PlayerReelIn: [false, 'player'],
  BlockDispense: [true, 'location, block, item, direction, cancelled'],
  EntityDamage: [true, 'entity, damage, cancelled'],
};

const uniq = (arr) => Array.from(new Set(arr));

function build() {
  const dump = loadEditorDump();
  const props = loadProperties(); // [{owner,name,type,writable}]
  const symbols = [];

  const keywords = uniq([...(dump.keywords || []), ...EXTRA_KEYWORDS]);
  const declarations = uniq([...(dump.declarations || []), 'command', 'event', 'function', 'async function']);
  const types = uniq([...(dump.types || []), ...EXTRA_TYPES]);
  const builtins = dump.builtins || [];
  const handlers = dump.handlers || [];
  const namespaces = dump.namespaces || [];
  const receivers = dump.receivers || [];
  const enums = dump.enums || {};

  for (const k of keywords) symbols.push({ name: k, kind: 'keyword' });
  for (const d of declarations) symbols.push({ name: d, kind: 'declaration' });
  for (const r of receivers) symbols.push({ name: r, kind: 'receiver', doc: `\`${r} { }\` OOP receiver block.` });
  for (const o of operators) symbols.push({ name: o, kind: 'operator' });
  for (const t of types) symbols.push({ name: t, kind: 'type' });
  for (const c of constants) symbols.push({ name: c, kind: 'constant' });

  for (const name of builtins) {
    const sig = BUILTIN_SIGS[name];
    if (sig) symbols.push({ name, kind: 'builtin', signature: sig[0][0], signatures: sig[0], doc: sig[1] });
    else symbols.push({ name, kind: 'builtin' });
  }

  for (const name of handlers) {
    symbols.push({ name, kind: 'handler', doc: `Inline \`${name}\` event handler block.` });
  }
  for (const name of namespaces) {
    symbols.push({ name, kind: 'namespace', doc: `\`${name}\` namespace block.` });
  }

  for (const [name, [cancellable, propList]] of Object.entries(EVENT_DOCS)) {
    symbols.push({
      name, kind: 'event',
      doc: `Event handler target.${cancellable ? ' Cancellable.' : ''} Fields: ${propList}.`,
    });
  }

  // property rows: live table (event:<Name> owners) unioned with the editor
  // dump's per-owner properties (e.g. Block). Dedupe by owner.name.
  const seen = new Set();
  const pushProp = (owner, name, type, writable) => {
    const key = owner + '.' + name;
    if (seen.has(key)) return;
    seen.add(key);
    symbols.push({
      name, kind: 'property', owner, type, writable: !!writable,
      doc: `${owner}.${name}: ${type}${writable ? '' : ' (read-only)'}`,
    });
  };
  for (const p of props) pushProp(p.owner, p.name, p.type, p.writable);
  for (const [owner, rows] of Object.entries(dump.properties || {})) {
    for (const r of rows) pushProp(owner, r.name, r.type, r.writable);
  }

  for (const [group, vals] of Object.entries(enums)) {
    for (const v of vals) symbols.push({ name: String(v), kind: 'enum', owner: group });
  }

  const outObj = {
    generatedBy: 'scripts/gen-symbols.js',
    note: 'Breadth from editor/swoftlang-symbols.json; property rows from swoftc --property-table; signatures/docs from registry.ml.',
    symbols,
    enums,
    namespaces,
    handlers,
  };
  const outPath = path.join(DATA, 'swoftlang-symbols.json');
  fs.writeFileSync(outPath, JSON.stringify(outObj, null, 2) + '\n');
  const counts = symbols.reduce((m, s) => ((m[s.kind] = (m[s.kind] || 0) + 1), m), {});
  console.error(`wrote ${outPath}: ${symbols.length} symbols`, counts);
}

build();
