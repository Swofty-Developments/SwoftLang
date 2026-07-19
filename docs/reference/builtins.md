# Builtins

Every builtin function — all 57, regenerated from the compiler's registry — with its
exact signature as the typechecker knows it. Calls are checked at compile time: wrong
arity, wrong argument types, and sync-context calls to async-only builtins are all
errors before anything reaches the server.

```
e_unkfn.sw:3:14: error: unknown function 'formatnumber'; did you mean 'format_number'?
```

*Number* below means `Integer` or `Double`. Functions marked **↑num** return `Integer`
when every argument is an `Integer`, otherwise `Double` — the result type follows the
arguments.

| Builtin | Returns | Notes |
|---|---|---|
| [`random(min, max)`](#random) | `Integer` | inclusive both ends |
| [`round(x)`](#round-floor-ceil) | `Integer` | |
| [`floor(x)`](#round-floor-ceil) | `Integer` | |
| [`ceil(x)`](#round-floor-ceil) | `Integer` | |
| [`abs(x)`](#abs-min-max-clamp) | **↑num** | |
| [`min(a, b)`](#abs-min-max-clamp) | **↑num** | |
| [`max(a, b)`](#abs-min-max-clamp) | **↑num** | |
| [`clamp(x, lo, hi)`](#abs-min-max-clamp) | **↑num** | |
| [`uppercase(s)`](#uppercase-lowercase) | `String` | |
| [`lowercase(s)`](#uppercase-lowercase) | `String` | |
| [`length(x)`](#length) | `Integer` | String or list |
| [`centered(s)`](#centered) | `String` | 30-char pad for tablist columns |
| [`format_number(n)`](#format-number) | `String` | `1,234,567` |
| [`location(x, y, z)`](#location) | `Location` | |
| [`location(x, y, z, yaw, pitch)`](#location) | `Location` | pitch clamped −90..90 |
| [`in_front_of(player, distance)`](#in-front-of) | `Location` | `distance` blocks ahead of the eye line |
| [`item(material)`](#item) | `Item` | |
| [`item(material, amount)`](#item) | `Item` | amount clamped 1..99 |
| [`player(name)`](#player) | `optional<Player>` | **optional** — narrow before use |
| [`all_players()`](#all-players) | `list<Player>` | |
| [`world(name)`](#world) | `optional<World>` | **optional** — narrow before use |
| [`custom_item(id)`](#custom-item) | `Item` | declared [custom item](./items) |
| [`custom_id(item)`](#custom-id) | `optional<String>` | `none` for vanilla stacks |
| [`all_mobs()`](#all-mobs) | `list<Mob>` | every live [custom mob](./mobs) |
| [`all_mobs(id)`](#all-mobs) | `list<Mob>` | one declaration's instances |
| [`spawn_text_display(text, at)`](#spawn-displays) | `Display` | [displays](./displays) |
| [`spawn_item_display(material, at)`](#spawn-displays) | `Display` | |
| [`spawn_block_display(block, at)`](#spawn-displays) | `Display` | |
| [`anvil_loader(dir)`](#world-loaders) | `WorldLoader` | [worlds](./worlds) |
| [`polar_loader(dir)`](#world-loaders) | `WorldLoader` | |
| [`polar_storage_loader(backend)`](#world-loaders) | `WorldLoader` | special form — backend config syntax |
| [`world_exists(name, loader)`](#world-exists-all-worlds) | `Boolean` | |
| [`all_worlds(loader)`](#world-exists-all-worlds) | `list<String>` | |
| [`block_at(at)`](#block-at) | `String` | block key at a location |
| [`song(file)`](#song) | `Song` | [NBS metadata](./songs) |
| [`tps_string()`](#tps) | `String` | pre-colored TPS |
| [`average_tps_string()`](#tps) | `String` | 5-minute figure |
| [`tps_at(seconds_ago)`](#tps) | `Double` | ring-buffer history |
| [`skin(texture, signature)`](#skin) | `Skin` | |
| [`fetch_skin(username)`](#fetch-skin) | `optional<Skin>` | **async-only** — Mojang API |
| [`map_canvas()`](#map-canvas) | `Canvas` | 128×128 [drawing surface](./maps-toasts-skins-tps#maps) |
| [`has_permission(player, perm)`](#has-permission) | `Boolean` | |
| [`random_float(min, max)`](#random-draws) | `Double` | |
| [`random_chance(p)`](#random-draws) | `Boolean` | `true` with probability `p` (0..1) |
| [`random_bool()`](#random-draws) | `Boolean` | fair coin |
| [`random_in(list)`](#random-draws) | `optional<T>` | random element; `none` when empty |
| [`shuffle(list)`](#random-draws) | `list<T>` | a new shuffled list |
| [`sort(list)`](#sorting) | `list<T>` | natural ascending (numbers or strings) |
| [`reverse(list)`](#sorting) | `list<T>` | reversed copy |
| [`sort_by(list, key)`](#sorting) | `list<T>` | by a key lambda, ascending |
| [`sort_by_desc(list, key)`](#sorting) | `list<T>` | by a key lambda, descending |
| [`min_by(list, key)`](#sorting) | `optional<T>` | element with the smallest key |
| [`max_by(list, key)`](#sorting) | `optional<T>` | element with the largest key |
| [`sort_by_key(map)`](#sorting-maps) | `map<K, V>` | new map, ordered by key ascending |
| [`sort_by_key_desc(map)`](#sorting-maps) | `map<K, V>` | ordered by key descending |
| [`sort_by_value(map)`](#sorting-maps) | `map<K, V>` | ordered by value ascending |
| [`sort_by_value_desc(map)`](#sorting-maps) | `map<K, V>` | ordered by value descending |
| [`sort_map_by(map, key)`](#sorting-maps) | `map<K, V>` | ordered by a `key(k, v)` lambda, ascending |
| [`sort_map_by_desc(map, key)`](#sorting-maps) | `map<K, V>` | same, descending |
| [`is_running(schedule)`](#is-running) | `Boolean` | live check by handle or name |
| [`prompt_input(player, placeholder)`](#prompt-input) | `String` | **async-only** |

## Numbers

### random {#random}

`random(min: Number, max: Number) : Integer`

A uniformly random integer between `min` and `max`, **inclusive of both bounds**.
Swapped bounds are tolerated (`random(10, 1)` behaves like `random(1, 10)`).

```swoftlang
command "roll" {
    execute {
        send "You rolled ${random(1, 6)}" to sender
    }
}
```

### round, floor, ceil {#round-floor-ceil}

`round(x: Number) : Integer` · `floor(x: Number) : Integer` · `ceil(x: Number) : Integer`

Half-up rounding, round toward −∞, round toward +∞. Always `Integer`.

```swoftlang
command "rounding" {
    execute {
        send "round(2.5) = ${round(2.5)}"      // 3
        send "floor(2.9) = ${floor(2.9)}"      // 2
        send "ceil(2.1)  = ${ceil(2.1)}"       // 3
    }
}
```

### abs, min, max, clamp {#abs-min-max-clamp}

`abs(x: Number)` · `min(a: Number, b: Number)` · `max(a: Number, b: Number)` ·
`clamp(x: Number, lo: Number, hi: Number)`

All four are **↑num**: all-`Integer` arguments give an `Integer`, any `Double` argument
gives a `Double`. `clamp(x, lo, hi)` limits `x` to the closed range `[lo, hi]`.

```swoftlang
command "mathy" {
    execute {
        set i to abs(-5)                       // Integer 5
        set d to abs(-5.5)                     // Double 5.5
        set capped to clamp(sender.health + 4.0, 0, sender.max_health)
        send "i=${i} d=${d} capped=${capped}" to sender
    }
}
```

## Strings

### uppercase, lowercase {#uppercase-lowercase}

`uppercase(s: String) : String` · `lowercase(s: String) : String`

```swoftlang
command "shout" {
    execute {
        send uppercase("swoft") + "!" to sender        // SWOFT!
        send lowercase(sender.name) to sender
    }
}
```

### length {#length}

`length(x: String | list<T>) : Integer`

Character count for strings, element count for lists.

```swoftlang
command "count" {
    execute {
        send "letters: ${length(sender.name)}" to sender
        send "online: ${length(all_players())}" to sender
    }
}
```

### centered {#centered}

`centered(s: String) : String`

Left-pads to visually center `s` in a 30-character field; strings of 30+ characters are
truncated to 30. Built for [tablist column headers](./scoreboards-tablists#tablist),
which render 30 characters wide.

```swoftlang
tablist "demo" {
    update: every 3 seconds
    column {
        entry centered("Players") with skin green
        fill with skin gray
    }
}
```

### format_number {#format-number}

`format_number(n: Number) : String`

Thousands separators, US grouping: `format_number(1234567)` → `"1,234,567"`. Doubles
keep their fractional part.

```swoftlang
command "bank" {
    execute {
        send "Balance: ${format_number(1234567)} coins" to sender
    }
}
```

## Value constructors

### location {#location}

`location(x: Number, y: Number, z: Number) : Location`
`location(x: Number, y: Number, z: Number, yaw: Number, pitch: Number) : Location`

The three-argument form has yaw and pitch 0. Pitch is clamped to −90..90.

```swoftlang
command "spawnpoint" {
    execute {
        teleport sender to location(0.5, 64.0, 0.5)
        teleport sender to location(100, 70, -20, 90, 0)
    }
}
```

### in_front_of {#in-front-of}

`in_front_of(player: Player, distance: Number) : Location`

The point `distance` blocks ahead of the player's eye direction — the spot they're
looking toward. Handy for spawning something in front of someone or projecting a marker:

```swoftlang
command "ahead" {
    execute {
        teleport sender to in_front_of(sender, 3)
    }
}
```

### item {#item}

`item(material: String) : Item` · `item(material: String, amount: Number) : Item`

Materials accept bare (`"stone"`) or namespaced (`"minecraft:stone"`) keys, any case.
An unknown material is a runtime `ScriptError` with the script's line and column.
Amount is clamped to 1..99 — an item never silently becomes air. Inside `gui` blocks
the same builtin takes named fields (`name:`, `lore:`, `glint:`, `skull:`) — see the
[GUI reference](./gui#item-specs).

```swoftlang
command "give-ish" {
    execute {
        set stack to item("DIAMOND", 3)
        set sender.held_item to stack
        send "material: ${stack.material}, amount: ${stack.amount}" to sender
    }
}
```

### skin {#skin}

`skin(texture: String, signature: String) : Skin`

A `Skin` value from a base64 texture/signature property pair — the exact shape the
Mojang session API serves. Assign it to [`player.skin`](./maps-toasts-skins-tps#skins),
pass it to tablist entries, or use it as an [`npc`](/reference/npcs) skin.

```swoftlang
command "mask" {
    execute {
        set sender.skin to skin("dGV4dHVyZWRhdGE...", "c2lnbmF0dXJl...")
    }
}
```

### map_canvas {#map-canvas}

`map_canvas() : Canvas`

A fresh 128×128 map drawing surface (`width` and `height` are readable properties).
Paint it with the [`draw` statements](./maps-toasts-skins-tps#maps) and hand it out
with `give map`.

```swoftlang
command "blank-map" {
    execute {
        set c to map_canvas()
        draw rect on c from 0, 0 to 127, 127 color "white"
        give map of c to sender
    }
}
```

## Lookups (these return optionals)

### player {#player}

`player(name: String) : optional<Player>`

The online player with that exact username, or `none`. The typechecker will not let the
result flow anywhere a `Player` is required until you narrow it:

```swoftlang
command "poke" {
    execute {
        set target to player("Notch")
        if target exists {
            send "<lime>Poke!" to target
        } else {
            send "<gray>Notch is not online" to sender
        }

        // or supply a fallback:
        set victim to player("Notch") otherwise sender
        send "gotcha" to victim
    }
}
```

Skipping the check is a compile error:

```
e_optional.sw:4:22: error: the send target is optional<Player> and may be missing; check it with 'if ... exists' or provide a fallback with 'otherwise'
```

### all_players {#all-players}

`all_players() : list<Player>`

Every online player. `loop all players as p` is sugar for
`loop all_players() as p`, and `send ... to all_players()` behaves like
`send ... to all`.

```swoftlang
command "who" {
    execute {
        send "There are ${length(all_players())} players online" to sender
        loop all_players() as p {
            send "<gray>- ${p.name}" to sender
        }
    }
}
```

### world {#world}

`world(name: String) : optional<World>`

Looks the name up in the engine's instance registry — populated by the host server
and by [`load world` / `create world`](./worlds). `none` if unknown.

```swoftlang
command "warp" {
    execute {
        set hub to world("hub")
        if hub exists {
            set sender.world to hub
        } else {
            send "<red>hub world is not registered" to sender
        }
    }
}
```

## Custom content

### custom_item {#custom-item}

`custom_item(id: String) : Item`

A fresh stack of a [declared custom item](./items) — stats, tags, lore, and identity
included. A literal id must name a declaration.

```swoftlang
item "cookie_of_truth" {
    material: "COOKIE"
    name: "Cookie of Truth"
    rarity: rare
}

command "cookie" {
    execute {
        set sender.held_item to custom_item("cookie_of_truth")
    }
}
```

### custom_id {#custom-id}

`custom_id(item: Item) : optional<String>`

The declaration id riding the stack, or `none` for vanilla items — the standard way
to recognize your items in events:

```swoftlang
event PlayerUseItem {
    execute {
        if custom_id(event.item) otherwise "" is "cookie_of_truth" {
            send "<gold>It tastes... honest." to event.player
        }
    }
}

item "cookie_of_truth" {
    material: "COOKIE"
    name: "Cookie of Truth"
    rarity: rare
}
```

### all_mobs {#all-mobs}

`all_mobs() : list<Mob>` · `all_mobs(id: String) : list<Mob>`

Every live [custom mob](./mobs), or just one declaration's instances. Literal ids
must name a declaration.

```swoftlang
mob "crypt_ghoul" {
    type: "ZOMBIE"
    health: 200
}

command "purge" {
    execute {
        loop all_mobs("crypt_ghoul") as g {
            despawn g
        }
        send "custom mobs still alive: ${length(all_mobs())}" to sender
    }
}
```

## Displays

### spawn_text_display, spawn_item_display, spawn_block_display {#spawn-displays}

`spawn_text_display(text: String, at: Location) : Display`
`spawn_item_display(material: String, at: Location) : Display`
`spawn_block_display(block: String, at: Location) : Display`

Spawn a display entity and get its handle. Style and manage it through
[Display properties and statements](./displays).

```swoftlang
command "marker" {
    execute {
        set d to spawn_text_display("<gold>here", sender.location)
        set d.billboard to "center"
    }
}
```

## Worlds

### anvil_loader, polar_loader, polar_storage_loader {#world-loaders}

`anvil_loader(dir: String) : WorldLoader`
`polar_loader(dir: String) : WorldLoader`
`polar_storage_loader(<backend config>) : WorldLoader`

Loader values for the [world statements](./worlds#loaders). `polar_storage_loader`
is a **special form**: its argument is `storage { }` backend syntax (`files`,
`sqlite`, `mysql { }`, `mongodb`), not an expression.

```swoftlang
command "loaders" {
    execute {
        load world "a" with anvil_loader("worlds")
        load world "b" with polar_loader("worlds")
        load world "c" with polar_storage_loader(files "data/worlds")
    }
}
```

### world_exists, all_worlds {#world-exists-all-worlds}

`world_exists(name: String, loader: WorldLoader) : Boolean`
`all_worlds(loader: WorldLoader) : list<String>`

Storage-level queries — they see saved worlds whether or not they're loaded.

```swoftlang
command "census" {
    execute {
        if world_exists("arena", polar_loader("worlds")) {
            send "arena is on disk" to sender
        }
        loop all_worlds(polar_loader("worlds")) as w {
            send "<gray>- ${w}" to sender
        }
    }
}
```

### block_at {#block-at}

`block_at(at: Location) : String`

The block key at a location (`minecraft:stone`-style). Pairs with
[`set block` / `fill blocks`](./worlds#blocks).

```swoftlang
command "under" {
    execute {
        send "you stand on ${block_at(location(sender.location.x, sender.location.y - 1, sender.location.z))}" to sender
    }
}
```

## Server introspection

### song {#song}

`song(file: String) : Song`

NBS header metadata: `title`, `author`, `length` (song ticks), `speed` (ticks/sec) —
see [Songs](./songs#song-metadata).

```swoftlang
command "meta" {
    execute {
        set s to song("cafe.nbs")
        send "${s.title} by ${s.author}" to sender
    }
}
```

### tps_string, average_tps_string, tps_at {#tps}

`tps_string() : String` · `average_tps_string() : String` ·
`tps_at(seconds_ago: Number) : Double`

The colored TPS strings (green/yellow/red, classic thresholds) and the raw historical
read. Raw current values are properties: `server.tps`, `server.average_tps`,
`server.mspt` — details on the [TPS reference](./maps-toasts-skins-tps#tps).

```swoftlang
command "tps" {
    execute {
        send "TPS: ${tps_string()} <gray>(5m: ${average_tps_string()}<gray>)" to sender
        send "<gray>60s ago: ${tps_at(60)}" to sender
    }
}
```

### has_permission {#has-permission}

`has_permission(player: Player, permission: String) : Boolean`

Asks the runtime's permission provider — the same one that enforces command
`permission:` keys. Defaults are configured in
[`server { permissions { } }`](./server-config#permissions).

```swoftlang
command "modcheck" {
    execute {
        if has_permission(sender, "swoftlang.moderate") {
            send "<green>You may moderate." to sender
        } else {
            send "<red>You may not." to sender
        }
    }
}
```

## Random draws {#random-draws}

`random(min, max)` (above) draws inclusive integers. These add the other draws — all
backed by `ThreadLocalRandom` at runtime. `random_in` and `shuffle` take a list and
follow its element type; `random_in` is `optional<T>` because the list may be empty.

`random_float(min, max) : Double` · `random_chance(p) : Boolean` ·
`random_bool() : Boolean` · `random_in(list) : optional<T>` · `shuffle(list) : list<T>`

```swoftlang
command "loot" {
    execute {
        set f to random_float(0.0, 1.0)
        send "roll ${f}" to sender

        if random_chance(0.1) {           // true 10% of the time — the "drop chance" primitive
            send "<gold>rare drop!" to sender
        }

        if random_bool() {
            send "heads" to sender
        }

        set drops to ["sword", "shield", "potion"]
        set pick to random_in(drops) otherwise "nothing"
        send "you get ${pick}" to sender

        loop shuffle(drops) as d {        // shuffle returns a new list; 'drops' is untouched
            send "${d}" to sender
        }
    }
}
```

## Sorting {#sorting}

Non-mutating sorts over lists: each returns a **new** list, leaving the argument
untouched. `sort` and `reverse` take just the list; the `_by` forms take a key lambda
that must return a `Number` or `String`. `min_by` / `max_by` return the *element* with
the extreme key, as an `optional<T>` (`none` for an empty list).

`sort(list) : list<T>` · `reverse(list) : list<T>` ·
`sort_by(list, key) : list<T>` · `sort_by_desc(list, key) : list<T>` ·
`min_by(list, key) : optional<T>` · `max_by(list, key) : optional<T>`

```swoftlang
command "leaderboard" {
    execute {
        set nums to [3, 1, 2]
        set up to sort(nums)              // [1, 2, 3]
        set down to reverse(nums)         // [2, 1, 3]
        send "sizes ${length(up)} ${length(down)}" to sender

        set scores to [10, 5, 20]
        set ranked to sort_by_desc(scores, function(n) return n)
        loop ranked as s {
            send "score ${s}" to sender
        }
        set top to max_by(scores, function(n) return n) otherwise 0
        send "top ${top}" to sender
    }
}
```

A key lambda that returns something unorderable is a compile error:

```
sort_key_noncomparable.sw:4:39: error: the key function of 'sort_by' must return a Number or String (got Location)
```

### Sorting maps {#sorting-maps}

The map forms return a **new map with a sorted iteration order** — the same entries, a
different `loop` order. Sort by key, by value, or by a `key(k, v)` lambda:

`sort_by_key(map)` · `sort_by_key_desc(map)` · `sort_by_value(map)` ·
`sort_by_value_desc(map)` · `sort_map_by(map, key)` · `sort_map_by_desc(map, key)` —
each returns `map<K, V>`

```swoftlang
command "kills" {
    execute {
        set kills to { "alice": 10, "bob": 25, "carol": 7 }

        set ranked to sort_by_value_desc(kills)   // highest kills first
        loop ranked as name -> n {
            send "${name}: ${n}" to sender
        }
    }
}
```

## Schedules {#schedules}

### is_running {#is-running}

`is_running(schedule) : Boolean`

Whether a [schedule](./schedulers#counters-self-cancel-and-named-schedules) is still
live — by its handle, or by the name it was given with `as "name"`.

```swoftlang
command "status" {
    execute {
        set h to schedule every 1 seconds as "ticker" {
            if run >= 10 stop
        }
        if is_running(h) send "ticker up" to sender
        cancel schedule "ticker"
    }
}
```

## Async-only builtins

Two builtins block their (virtual) thread, so the compiler restricts them to async
contexts — `async function`, `execute async`, or `async { }`:

### prompt_input {#prompt-input}

`prompt_input(player: Player, placeholder: String) : String` — **async-only**

Opens a sign editor for the player (a fake sign is placed six blocks above them, then
restored) and blocks the current *task* — never the server — until they submit. Returns
the first line they typed.

```
e_prompt.sw:3:23: error: 'prompt_input' can only be called in async contexts ('async function', 'execute async', or 'async { }')
```

```swoftlang
command "rename" {
    execute async {
        set answer to prompt_input(sender, "new name?")
        set sender.display_name to answer
        send "<lime>Renamed to ${answer}" to sender
    }
}
```

::: tip GUI click handlers are sync
Click handlers run on the tick thread. To prompt from a GUI, wrap the call in an
`async { ... }` block inside the handler — see the
[worked example](./gui#a-complete-worked-example) in the GUI reference.
:::

### fetch_skin {#fetch-skin}

`fetch_skin(username: String) : optional<Skin>` — **async-only**

A live Mojang API lookup on the calling virtual thread. `none` when the account
doesn't exist (or the API is unreachable) — narrow before use, like any optional.

```
e_fetchsync.sw:3:18: error: 'fetch_skin' can only be called in async contexts ('async function', 'execute async', or 'async { }')
```

```swoftlang
command "wear" {
    execute async {
        set s to fetch_skin("Notch")
        if s exists {
            set sender.skin to s
        }
    }
}
```
