#!/usr/bin/env node
// Generates data/swoftlang-symbols.json for the SwoftLang VS Code extension.
//
// Sources:
//   * Property rows        -> `swoftc --property-table` (bundled dump property-table.raw.json,
//                             regenerated here if the binary is available).
//   * Keywords / operators / declarations / types / constants
//                          -> the TextMate grammar surface (kept in sync by hand below).
//   * Builtin signatures / event set / enums
//                          -> compiler/lib/registry.ml (transcribed below).
//
// Re-run with: node scripts/gen-symbols.js  (optionally SWOFTC=/path/to/main.exe)
'use strict';
const fs = require('fs');
const path = require('path');
const cp = require('child_process');

const DATA = path.join(__dirname, '..', 'data');

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

// --- keywords from the grammar surface ---
const keywords = [
  // statements / control flow
  'if', 'else', 'halt', 'loop', 'while', 'times', 'as', 'return', 'wait',
  'spawn', 'call', 'go back', 'go', 'back',
  // action verbs
  'send', 'teleport', 'set', 'cancel', 'broadcast', 'open', 'close', 'replace',
  'show', 'hide', 'update', 'title', 'subtitle', 'actionbar', 'clear', 'line',
  'blank', 'entry', 'fill', 'give',
  // connectors
  'to', 'with', 'for', 'every', 'manual',
  // block keys
  'execute', 'arguments', 'slot', 'slots', 'editable', 'paginate', 'state',
  'render', 'lines', 'column', 'on_click', 'on_open', 'on_close', 'on_change',
  'on_click_fallback', 'source', 'refresh', 'border', 'prev_slot', 'next_slot',
  // time units
  'ticks', 'seconds', 'millis',
];

// declaration keywords (top-level block openers)
const declarations = [
  'command', 'event', 'function', 'async function', 'async', 'gui',
  'scoreboard', 'tablist', 'bossbar', 'server', 'mob', 'item',
];

const operators = [
  'is', 'is not', 'is a', 'is an', 'is not a', 'is not an', 'is missing',
  'contains', 'and', 'or', 'not', 'exists', 'otherwise', 'missing',
];

const types = [
  'String', 'Integer', 'Double', 'Boolean', 'Number', 'int', 'bool',
  'Player', 'OfflinePlayer', 'Location', 'Item', 'World', 'Mob', 'Entity',
  'Vec', 'Skin', 'Canvas', 'Song', 'Display', 'Server', 'Schedule',
  'either', 'optional', 'list', 'map',
];

const constants = ['true', 'false', 'none', 'all', 'sender'];

// --- builtins transcribed from registry.ml (name -> signatures + one-line doc) ---
const builtins = [
  ['random', ['random(min: Number, max: Number): Integer'], 'Random integer in [min, max].'],
  ['round', ['round(n: Number): Integer'], 'Round to the nearest integer.'],
  ['floor', ['floor(n: Number): Integer'], 'Round down to an integer.'],
  ['ceil', ['ceil(n: Number): Integer'], 'Round up to an integer.'],
  ['abs', ['abs(n: Number): Number'], 'Absolute value (keeps Integer/Double).'],
  ['uppercase', ['uppercase(s: String): String'], 'Uppercase a string.'],
  ['lowercase', ['lowercase(s: String): String'], 'Lowercase a string.'],
  ['length', ['length(x: String|list): Integer'], 'Length of a string or list.'],
  ['location', ['location(x, y, z): Location', 'location(x, y, z, yaw, pitch): Location'], 'Build a Location.'],
  ['item', ['item(material: String): Item', 'item(material: String, amount: Number): Item'], 'Build an Item stack.'],
  ['player', ['player(name: String): optional<Player>'], 'Look up an online player by name.'],
  ['all_players', ['all_players(): list<Player>'], 'Every online player.'],
  ['world', ['world(name: String): optional<World>'], 'Look up a loaded world by name.'],
  ['centered', ['centered(s: String): String'], 'Center a chat string.'],
  ['prompt_input', ['prompt_input(p: Player, msg: String): String'], 'async only: prompt a player for chat input.'],
  ['min', ['min(a: Number, b: Number): Number'], 'Smaller of two numbers.'],
  ['max', ['max(a: Number, b: Number): Number'], 'Larger of two numbers.'],
  ['clamp', ['clamp(n, lo, hi): Number'], 'Clamp n into [lo, hi].'],
  ['format_number', ['format_number(n: Number): String'], 'Group-separated number string.'],
  ['custom_item', ['custom_item(id: String): Item'], 'Instantiate a registered custom item.'],
  ['custom_id', ['custom_id(i: Item): optional<String>'], 'Custom-item id of a stack, if any.'],
  ['all_mobs', ['all_mobs(): list<Mob>', 'all_mobs(type: String): list<Mob>'], 'Every mob (optionally by type).'],
  ['velocity', ['velocity(x, y, z): Vec'], 'Build a velocity vector (blocks/tick).'],
  ['all_entities', ['all_entities(): list<Entity>', 'all_entities(type: String): list<Entity>'], 'Every live entity (optionally by type).'],
  ['spawn_text_display', ['spawn_text_display(text: String, at: Location): Display'], 'Spawn a text display entity.'],
  ['spawn_item_display', ['spawn_item_display(item: String, at: Location): Display'], 'Spawn an item display entity.'],
  ['spawn_block_display', ['spawn_block_display(block: String, at: Location): Display'], 'Spawn a block display entity.'],
  ['song', ['song(file: String): Song'], 'Load NBS song metadata.'],
  ['tps_string', ['tps_string(): String'], 'Colored current TPS string.'],
  ['average_tps_string', ['average_tps_string(): String'], 'Colored average TPS string.'],
  ['tps_at', ['tps_at(secondsAgo: Number): Double'], 'TPS sample from N seconds ago.'],
  ['anvil_loader', ['anvil_loader(path: String): WorldLoader'], 'An Anvil-format world loader.'],
  ['polar_loader', ['polar_loader(path: String): WorldLoader'], 'A Polar-format world loader.'],
  ['world_exists', ['world_exists(name: String, loader): Boolean'], 'Whether a world exists for a loader.'],
  ['all_worlds', ['all_worlds(loader): list<String>'], 'World names known to a loader.'],
  ['block_at', ['block_at(loc: Location): String'], 'Block id at a location.'],
  ['skin', ['skin(texture: String, signature: String): Skin'], 'Build a Skin from texture+signature.'],
  ['fetch_skin', ['fetch_skin(name: String): optional<Skin>'], 'async only: fetch a skin from Mojang.'],
  ['map_canvas', ['map_canvas(): Canvas'], 'Allocate a 128x128 map canvas.'],
  ['has_permission', ['has_permission(p: Player, node: String): Boolean'], 'Permission check.'],
  ['offline_player', ['offline_player(name: String): optional<OfflinePlayer>'], 'Seen-store lookup by name.'],
  ['offline_player_uuid', ['offline_player_uuid(uuid: String): OfflinePlayer'], 'Construct an OfflinePlayer identity.'],
  ['fetch_offline_player', ['fetch_offline_player(name: String): optional<OfflinePlayer>'], 'async only: resolve name->uuid via Mojang.'],
  ['all_seen_players', ['all_seen_players(): list<OfflinePlayer>'], 'Every seen-store player.'],
  ['new_map', ['new_map(): map'], 'Create an empty map (typed by context).'],
  ['map_get', ['map_get(m, key): optional', 'map_get syntax: m[key]'], 'Read a map value.'],
  ['map_set', ['map_set(m, key, value)'], 'Write a map value.'],
  ['map_has', ['map_has(m, key): Boolean'], 'Whether a key exists.'],
  ['map_delete', ['map_delete(m, key)'], 'Remove a key.'],
  ['map_keys', ['map_keys(m): list'], 'Keys of a map.'],
  ['map_size', ['map_size(m): Integer'], 'Entry count of a map.'],
  ['random_float', ['random_float(min, max): Double'], 'Random double in [min, max].'],
  ['random_chance', ['random_chance(p: Number): Boolean'], 'True with probability p (0..1).'],
  ['random_bool', ['random_bool(): Boolean'], 'Random coin flip.'],
  ['random_in', ['random_in(coll): optional'], 'Random element of a list/string.'],
  ['shuffle', ['shuffle(coll): list'], 'Shuffled copy of a collection.'],
  ['sort', ['sort(coll): list'], 'Sorted copy (natural order).'],
  ['sort_by', ['sort_by(coll, keyLambda): list'], 'Sort ascending by a key.'],
  ['sort_by_desc', ['sort_by_desc(coll, keyLambda): list'], 'Sort descending by a key.'],
  ['reverse', ['reverse(coll): list'], 'Reversed copy.'],
  ['min_by', ['min_by(coll, keyLambda): optional'], 'Element with the smallest key.'],
  ['max_by', ['max_by(coll, keyLambda): optional'], 'Element with the largest key.'],
  ['sort_by_key', ['sort_by_key(m): map'], 'Sort a map ascending by key.'],
  ['sort_by_key_desc', ['sort_by_key_desc(m): map'], 'Sort a map descending by key.'],
  ['sort_by_value', ['sort_by_value(m): map'], 'Sort a map ascending by value.'],
  ['sort_by_value_desc', ['sort_by_value_desc(m): map'], 'Sort a map descending by value.'],
  ['sort_map_by', ['sort_map_by(m, keyLambda): map'], 'Sort a map by a derived key.'],
  ['sort_map_by_desc', ['sort_map_by_desc(m, keyLambda): map'], 'Sort a map descending by a derived key.'],
  ['to_nbt', ['to_nbt(i: Item): String'], 'Serialize an item stack to NBT.'],
  ['from_nbt', ['from_nbt(s: String): optional<Item>'], 'Parse an item stack from NBT.'],
];

// curated event names (registry.ml `events`) — the ones worth completing/hovering.
const events = [
  ['PlayerChat', true, 'player, message, cancelled'],
  ['PlayerJoin', false, 'player, first_spawn, world'],
  ['PlayerUseItem', true, 'player, item, custom_id, cancelled'],
  ['MobSpawn', false, 'mob'],
  ['MobDeath', false, 'mob, killer'],
  ['MobDamage', true, 'mob, damage, cancelled'],
  ['TpsChange', false, 'past, current'],
  ['BlockBreak', true, 'player, block, location, cancelled'],
  ['BlockPlace', true, 'player, block, location, cancelled'],
  ['ServerPing', false, 'motd, online, max'],
  ['PlayerCommand', true, 'player, command, cancelled'],
  ['PlayerCastRod', true, 'player, cancelled'],
  ['FishBite', false, 'player, hook_location'],
  ['PlayerCatchFish', true, 'player, caught_item, caught_mob, cancelled'],
  ['PlayerReelIn', false, 'player'],
  ['BlockDispense', true, 'location, block, item, direction, cancelled'],
];

// enums from registry.ml (useful literal completions)
const enums = {
  gamemode: ['survival', 'creative', 'adventure', 'spectator'],
  weather: ['clear', 'rain', 'thunder'],
  rarity: ['common', 'uncommon', 'rare', 'epic'],
  bossbar_color: ['pink', 'blue', 'red', 'green', 'yellow', 'purple', 'white'],
  bossbar_style: ['progress', 'notched_6', 'notched_10', 'notched_12', 'notched_20'],
  mob_ai: ['melee', 'passive', 'none'],
  nametag_color: ['black', 'dark_blue', 'dark_green', 'dark_aqua', 'dark_red',
    'dark_purple', 'gold', 'gray', 'dark_gray', 'blue', 'green', 'aqua', 'red',
    'light_purple', 'yellow', 'white'],
  entity_pose: ['standing', 'fall_flying', 'sleeping', 'swimming', 'spin_attack',
    'sneaking', 'long_jumping', 'dying', 'croaking', 'using_tongue', 'sitting',
    'roaring', 'sniffing', 'emerging', 'digging', 'sliding', 'shooting', 'inhaling'],
};

function build() {
  const props = loadProperties(); // [{owner,name,type,writable}]
  const symbols = [];

  for (const k of keywords) symbols.push({ name: k, kind: 'keyword' });
  for (const d of declarations) symbols.push({ name: d, kind: 'declaration' });
  for (const o of operators) symbols.push({ name: o, kind: 'operator' });
  for (const t of types) symbols.push({ name: t, kind: 'type' });
  for (const c of constants) symbols.push({ name: c, kind: 'constant' });

  for (const [name, sigs, doc] of builtins) {
    symbols.push({ name, kind: 'builtin', signature: sigs[0], signatures: sigs, doc });
  }

  for (const [name, cancellable, propList] of events) {
    symbols.push({
      name, kind: 'event',
      doc: `Event handler target.${cancellable ? ' Cancellable.' : ''} Fields: ${propList}.`,
    });
  }

  // property rows: dedupe by owner+name so hover can report owner + type.
  const seen = new Set();
  for (const p of props) {
    const key = p.owner + '.' + p.name;
    if (seen.has(key)) continue;
    seen.add(key);
    symbols.push({
      name: p.name, kind: 'property', owner: p.owner,
      type: p.type, writable: !!p.writable,
      doc: `${p.owner}.${p.name}: ${p.type}${p.writable ? '' : ' (read-only)'}`,
    });
  }

  for (const [group, vals] of Object.entries(enums)) {
    for (const v of vals) symbols.push({ name: v, kind: 'enum', owner: group });
  }

  const outObj = {
    generatedBy: 'scripts/gen-symbols.js',
    note: 'Derived from the SwoftLang TextMate grammar + compiler/lib/registry.ml + swoftc --property-table.',
    symbols,
    enums,
  };
  const outPath = path.join(DATA, 'swoftlang-symbols.json');
  fs.writeFileSync(outPath, JSON.stringify(outObj, null, 2) + '\n');
  console.error(`wrote ${outPath}: ${symbols.length} symbols (${props.length} property rows)`);
}

build();
