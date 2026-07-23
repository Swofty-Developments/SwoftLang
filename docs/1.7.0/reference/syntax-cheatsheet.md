# Syntax Cheatsheet

Every construct in the language, at a glance. All snippets on this page compile with
`swoftc check`.

## File structure

A `.sw` file is a sequence of top-level declarations, in any order:

| Declaration | Purpose |
|---|---|
| `import "name"` / `import "./file.sw"` | Pull in a module ([libraries](/1.7.0/libraries/)) |
| `var name = expr` | Module-level variable, private to the file |
| `export <declaration>` | Make a symbol importable ([libraries](/1.7.0/libraries/#exports)) |
| `command "name" { ... }` | Chat command (aliases share one body) |
| `Player { ... }`, `Mob { ... }`, … | Receiver block — event methods by subject ([reference](./events)) |
| `function name(...) { ... }` | Reusable function |
| `async function name(...) { ... }` | Function that may `wait` |
| `item <ItemType> { ... }` | Custom item ([reference](./items)) |
| `mob <MobType> { ... }` | Custom mob ([reference](./mobs)) |
| `gui "name" { ... }` | Declarative inventory GUI ([reference](./gui)) |
| `scoreboard "name" { ... }` | Sidebar ([reference](./scoreboards-tablists)) |
| `tablist "name" { ... }` | Player-list columns ([reference](./scoreboards-tablists)) |
| `bossbar "name" { ... }` | Boss bar ([reference](./scoreboards-tablists)) |
| `api "/path/:param" { ... }` | HTTP route ([reference](./http-api)) |
| `every <duration> { ... }` | Boot-started repeating task ([reference](./schedulers)) |
| `Packet { on "Name" { ... } }` | Inbound raw-packet listeners ([reference](./packets)) |
| `server { ... }` | Server bootstrap config ([reference](./server-config)) |
| `storage { ... }` | Persistence backend ([reference](./server-config#storage-phase-3)) |
| `persistent name: Type = default` | Persistent variable ([guide](/1.7.0/guide/persistence)) |

Comments: `// line` and `/* block */`. Statements are newline-insensitive — there are no
semicolons, and you can split expressions across lines freely.

## Commands

```swoftlang
command "tp",
command "teleport" {                          // aliases share one body
    permission: "swoftlang.teleport"
    description: "Teleport a player"

    arguments {
        player: Player = sender               // one-token default
        target: Either<Player|Location>       // union type, no default
    }

    execute {
        if args.player is not a Player {
            send "<red>You can only teleport players" to sender
            halt
        }
        teleport args.player to args.target
        send "<lime>Teleported ${sender} to ${args.target}"
    }
}
```

- Alias groups: `command "tp", command "teleport" { ... }` or the short form
  `command "tp", "teleport" { ... }`.
- Arguments are readable as `args.name` and also bound unprefixed (`player`, `target`).
- `execute async { ... }` makes the whole handler [async](#async).
- `sender` is always bound to the executing `Player`.

## Receivers & events

Events are handled by **receiver** blocks — a Capitalized subject with fixed-name methods.
The subject is a bare variable named after its type; the event's data is bound alongside it:

```swoftlang
Player {
    on_chat {
        set message to "[Filtered] ${message}"
        if message contains "badword" {
            cancel event
        }
    }
}
```

The base receivers (methods fire for every instance; the full catalog is on the
[Receivers & Events](./events) page):

| Receiver | Subject variable | Example methods |
|---|---|---|
| `Player` | `player` | `on_join`, `on_chat`, `on_command`, `on_death` |
| `Entity` | `entity` | `on_hit`, `on_death`, `on_attack` |
| `Mob` | `mob` | `on_spawn`, `on_death`, `on_click` |
| `Item` | `item` | `on_use`, `on_drop`, `on_consume` |
| `Block` | `block` | `on_place`, `on_break`, `on_dispense` |
| `Projectile` | `projectile` | `on_hit_block`, `on_hit_entity` |
| `Inventory` | `inventory` | `on_pre_click`, `on_open`, `on_close` |
| `World` | `world` | `on_tick`, `on_chunk_load`, `on_entity_add` |
| `Server` | `server` | `on_list_ping`, `on_tps_change` |
| `Packet` | — | `on "PacketClass" { }` raw-packet handlers |

A `mob <MobType> { }` / `item <ItemType> { }` / `block_handler "id" { }` declaration carries
the same method set for one id and overrides the base (`call original method` reaches it).
`cancel event` in a non-cancellable method is a compile error:

```
e_cancel.sw:3:9: error: event 'on_join' is not cancellable
        cancel event
        ^
```

## Types

| Type | Also written | Values |
|---|---|---|
| `String` | — | `"text"`, with `${...}` interpolation |
| `Integer` | `int` | `42`, `-3` |
| `Double` | `double` | `2.5` |
| `Boolean` | `bool` | `true`, `false` |
| `Player` | — | an online player |
| `Location` | — | from `location(x, y, z[, yaw, pitch])` |
| `World` | — | from `world(name)` |
| `Item` | — | from `item(material[, amount])`, `custom_item(id)` |
| `Mob` | — | from `spawn mob ... as m`, `all_mobs()` ([mobs](./mobs)) |
| `Display` | — | from `spawn_text_display(...)` etc. ([displays](./displays)) |
| `Song` | — | from `song(file)` ([songs](./songs)) |
| `Skin` | — | from `skin(t, s)`, `fetch_skin(name)` ([skins](./maps-toasts-skins-tps#skins)) |
| `Canvas` | — | from `map_canvas()` ([maps](./maps-toasts-skins-tps#maps)) |
| `Schedule` | — | from a `schedule` expression ([schedulers](./schedulers)) |
| `WorldLoader` | — | from `anvil_loader(...)` etc. ([worlds](./worlds#loaders)) |
| `Either<A\|B>` | — | union; narrow with `is a` |
| `Optional<T>` | — | maybe-missing; narrow with `exists` / `otherwise` |
| `List<T>` | — | `[1, 2, 3]`, `all_players()` |
| `Map<K, V>` | `Map<V>` (= `Map<String, V>`) | dictionary ([maps](./maps)) |

**Every type is PascalCase.** As of 1.6.0 this is uniform: scalars (`String`,
`Integer`), engine types (`Player`, `Mob`), your own structs and custom
item/mob types, **and** the four generic containers — `Map`, `List`,
`Optional`, `Either` — all start with a capital letter. The old lowercase
spellings (`map<…>`, `list<…>`, `optional<…>`, `either<…>`) are no longer
accepted. Function names stay lowercase (`new_map()`, `map_canvas()`) — only
the *type* spelling is capitalized.

There is no null. `none` is the missing value of an `Optional<T>`, and the typechecker
forces you to prove presence before use — see [Options](#options-no-more-null).
`Number` in `is a Number` checks accepts both `Integer` and `Double`. Unknown type names
in argument lists are accepted with a compile *warning* (`unknown type 'Thing', treating
as UNKNOWN`).

## Variables and assignment

```swoftlang
command "vars" {
    execute {
        set x to 10                    // declare/assign a local
        set x to x + 1                 // reassign
        set sender.health to 20.0      // property write (see Properties)
        set held to sender.held_item   // property read into a local
    }
}
```

`set <lvalue> to <expr>` is the only assignment form. An lvalue is a plain variable or a
dotted property path.

## Operators and precedence

Lowest to highest:

| Level | Operators |
|---|---|
| 1 | `or`, `\|\|` |
| 2 | `otherwise` (optional fallback) |
| 3 | `and`, `&&` |
| 4 | `not <expr>` |
| 5 | `=`, `==`, `!=`, `<`, `>`, `<=`, `>=`, `contains`, `is`, `is not`, `is a` / `is an`, `is not a`, `exists`, `is missing` |
| 6 | `+`, `-` |
| 7 | `*`, `/`, `%` |
| 8 | unary `-` |
| 9 | `.` property access, calls, literals, `( )` |

English-y aliases: `is` ≡ `=`; `is not` ≡ `!=`; `is a Player` / `is an Item` is a type
check; `x exists` / `x is missing` test optionals. `+` on strings concatenates.

```swoftlang
command "ops" {
    execute {
        set x to 1 + 2 * 3                       // 7 — precedence
        set y to (1 + 2) * 3                     // 9 — parens group
        set ok to x > 6 and not (y < 5)
        if "SwoftLang" contains "swoft" {        // case-insensitive substring
            send "yes" to sender
        }
        if x is a Number and ok is not a String {
            send "typed" to sender
        }
    }
}
```

## String interpolation

`${...}` inside any string literal:

```swoftlang
command "interp" {
    execute {
        set who to sender.name
        send "Hello ${who}, health ${sender.health}"          // simple paths
        send "Sum: ${1 + 2 * 3}, upper: ${uppercase(who)}"    // full expressions
    }
}
```

Simple dotted paths (`${a.b.c}`) stay in the string and are resolved at runtime through
the property registry. Anything more complex is desugared *at compile time* into a
concatenation chain of real expressions. Both forms are fully type-checked — a typo like
`${sender.latencey}` is a compile error with a suggestion.

## Control flow

```swoftlang
command "flow" {
    execute {
        // if / else if / else
        set x to 7
        if x = 5 {
            send "five" to sender
        } else if x = 7 {
            send "seven" to sender
        } else {
            send "other" to sender
        }

        // counted loop; optional counter runs 1..N
        loop 3 times as i {
            send "iteration ${i}" to sender
        }
        loop 3 times {
            send "again" to sender
        }

        // while (runtime guard stops runaway loops at 100,000 iterations)
        set n to 3
        while n > 0 {
            set n to n - 1
        }

        // iterate a list
        loop all_players() as p {
            send "hi ${p.name}" to p
        }
        loop all players as p {                   // sugar for all_players()
            send "hey ${p.name}" to p
        }
        loop first 5 of all_players() as p {      // cap the iteration count
            send "you're early" to p
        }

        halt                                       // stop this script run
        send "never reached" to sender
    }
}
```

### Brace-free bodies

Every body position — `if`/`else`, loops, function bodies, `execute`, `async` blocks,
GUI handlers — also accepts exactly one statement with no braces:

```swoftlang
command "terse" {
    execute {
        // any body can be exactly one brace-free statement
        set x to 7
        if x > 5 send "big" to sender
        else if x = 5 send "exact" to sender
        else halt

        loop 3 times as i send "i = ${i}" to sender
        async send "from a task" to sender

        // a dangling else binds to the nearest if
        if x > 0 if x > 100 send "huge" to sender
        else send "positive, not huge" to sender
    }
}
```

Scoreboard `lines { }` and tablist `column { }` bodies still require braces.

## Functions

```swoftlang
function factorial(n: int) {
    if n <= 1 {
        return 1
    }
    return n * factorial(n - 1)               // recursion (depth cap 256)
}

function greet(player: Player) {
    send "Welcome, ${player}!" to player
}

command "demo" {
    execute {
        set f to factorial(5)                 // call as expression
        greet(sender)                         // call as statement
        call greet(sender)                    // optional 'call' keyword
        return                                // bare return = stop, like halt
    }
}
```

Parameter types are optional (untyped params are `Any`). A function whose paths
*sometimes* return a value gets return type `Optional<T>` — callers must narrow it.

### Inline functions (lambdas)

`function(...)` without a name is an expression — a first-class function value:

```swoftlang
function double(x: Integer) return x * 2      // brace-free body

command "lambda" {
    execute {
        set triple to function(x: Integer) return x * 3
        send "${triple(4)}" to sender         // 12: call through the variable

        set count to 0
        set inc to function() set count to count + 1
        inc()                                 // closures capture by reference
        send "${count}" to sender             // 1

        set task to async function(p: Player) {
            wait 1 seconds
            send "later" to p
        }
        spawn task(sender)                    // spawn works on async lambdas
    }
}
```

Call names resolve in order: local variable holding a callable → declared function →
builtin. Calling a value the checker knows is not a function is a compile error
(`'x' is an Integer, not a function`). Details on the
[Functions page](/1.7.0/guide/functions#inline-functions-lambdas).

## Options (no more null) {#options-no-more-null}

```swoftlang
command "find" {
    arguments {
        who: Optional<Player>                 // optional command argument
    }
    execute {
        set found to player("Notch")          // player() : Optional<Player>

        if found exists {
            send "hi ${found.name}" to found  // narrowed to Player here
        } else {
            send "offline" to sender
        }
        if found is missing {
            send "still missing" to sender
        }

        set target to args.who otherwise sender   // Optional<T> otherwise T -> T
        set label to none                         // the missing value
        set title to label otherwise "guest"
        send "${title}" to target
    }
}
```

Using a possibly-missing value where a concrete one is needed is a compile error:

```
e_optional.sw:4:22: error: the send target is Optional<Player> and may be missing; check it with 'if ... exists' or provide a fallback with 'otherwise'
```

## Properties

Dotted paths read and write real game state through a compile-time-checked whitelist
(no reflection). Read-only writes and typos are compile errors.

| Owner | Read/write | Read-only |
|---|---|---|
| `Player` | `health`, `max_health`, `food`, `food_saturation`, `level`, `exp`, `gamemode`, `location`, `world`, `held_item`, `held_slot`, `display_name`, `flying`, `allow_flying`, `flying_speed`, `skin` | `name`, `uuid`, `latency`, `online` |
| `Location` | `x`, `y`, `z`, `yaw`, `pitch` | `block_x`, `block_y`, `block_z` |
| `Item` | `material`, `amount`, `name`, `lore` | `stats.*`, `tags.*` (tags writable — [items](./items)) |
| `Mob` | `health`, `name`, `location` | `max_health`, `type`, `custom_id` ([mobs](./mobs)) |
| `World` | `time`, `time_rate` | — ([worlds](./worlds)) |
| `Display` | `text`, `item`, `block`, `scale`, `translation`, `rotation`, `billboard`, `glow_color`, `background`, `alignment`, `line_width`, `see_through`, `view_range` | — ([displays](./displays)) |
| `Song` | — | `title`, `author`, `length`, `speed` ([songs](./songs)) |
| `Skin` | — | `texture`, `signature` |
| `Canvas` | — | `width`, `height` |
| `server` | `motd` | `tps`, `average_tps`, `mspt` ([TPS](./maps-toasts-skins-tps#tps)) |
| `request` | — | `method`, `path`, `query`, `body`, `params.*` — [api handlers](./http-api) only |

```swoftlang
command "props" {
    execute {
        set sender.health to sender.max_health
        set sender.location.y to sender.location.y + 10   // wither + one teleport
        set sender.held_item.amount to 32
        set sender.gamemode to "creative"                 // enum-validated string
    }
}
```

Values with immutable Java representations (`Location`, `Item`) are written
copy-on-write: the runtime reads the deepest settable *anchor* (`location`,
`held_item`, or a local variable), applies withers, and stores once. A stored
`Location` is a snapshot — mutating a local copy never moves the player.

## Statements reference

| Statement | Form |
|---|---|
| assign | `set x to <expr>` / `set a.b.c to <expr>` |
| send | `send <expr> [to <player \| list \| all>]` |
| broadcast | `broadcast <expr>` |
| teleport | `teleport <player> to <player \| location>` |
| halt | `halt` — end this script task |
| cancel | `cancel event` — sync event handlers only |
| if | `if <cond> { } [else if <cond> { }] [else { }]` |
| loop | `loop <n> times [as i] { }` |
| foreach | `loop [first <n> of] <list> as x { }` |
| while | `while <cond> { }` |
| call | `f(args)` / `call f(args)` |
| return | `return [<expr>]` |
| wait | `wait <expr> ticks\|seconds\|millis` — async only |
| spawn | `spawn f(args)` — fire-and-forget task |
| async block | `async { ... }` |
| GUI nav | `open gui "g" to <p> [with { k: v }]`, `replace gui "g" to <p>`, `close gui for <p>`, `go back for <p>` |
| scoreboard | `show scoreboard "s" to <p>`, `hide scoreboard from <p>`, `update scoreboard for <p>` |
| tablist | `show tablist "t" to <p>`, `hide tablist from <p>`, `set tablist header\|footer to <expr> for <p>` |
| bossbar | `show bossbar "b" to <p>`, `hide bossbar "b" from <p>`, `set bossbar "b" progress\|text to <expr> for <p>` |
| title | `title <expr> [subtitle <expr>] to <p> [fade in <dur>] [stay <dur>] [fade out <dur>]`, `clear title for <p>` |
| actionbar | `actionbar <expr> to <p> [for <dur>]` |
| belowname | `belowname <expr> for <p>`, `set belowname score to <expr> for <p>`, `clear belowname for <p>` |
| [items](./items) | `give item "id" to <p> [amount <n>]` |
| [mobs](./mobs) | `spawn mob <MobType> at <loc> [as <var>]`, `despawn <mob>` |
| [viewers](./entities#per-viewer) | `show <entity> to <p\|all>`, `hide <entity> from <p\|all>`, `set name of <entity> to <expr> for <p>`; `viewers of <entity>` (expr → `List<Player>`) |
| [nametags](./nametags) | `set nametag [prefix\|suffix\|color] of <p> to <expr> [for <viewer\|all>]`, `reset nametag of <p> [for ...]` |
| [packets](./packets) | `send packet "Name" { field: expr, ... } to <target>`, `cancel packet` |
| [displays](./displays) | `show\|hide display <d> to\|from <target>`, `mount display <d> on <entity>`, `teleport display <d> to <loc>`, `destroy display <d>` |
| [worlds](./worlds) | `create\|load\|unload\|save\|delete world ...`, `clone world "a" to "b" with <loader>`, `import anvil world ...` |
| [blocks](./blocks#placing-and-reading-blocks) | `set block at <loc> to "STONE"`, `place <block> at <loc>`, `remove block at <loc>`, `fill blocks from <loc> to <loc> with "X"` |
| [http](./http-api) | `reply [code <n>] with <expr>` — api handlers only |
| [songs](./songs) | `play\|pause\|resume\|stop song ...`, `broadcast song <file>`, `set song volume ...`, `fade song ...` |
| [sounds](./maps-toasts-skins-tps#sounds) | `play sound <key> to <target> [at <loc>] [volume <v>] [pitch <p>]`, `stop sound [<key>] for <target>` |
| [particles](./maps-toasts-skins-tps#particles) | `spawn particle <name> at <loc> [count <n>] [offset <x>,<y>,<z>] [speed <s>] [to <viewer\|all>]` |
| [toasts](./maps-toasts-skins-tps#toasts) | `show toast <title> [description <s>] [icon <mat>] [frame task\|goal\|challenge] to <target>` |
| [maps](./maps-toasts-skins-tps#maps) | `draw pixel\|rect\|text on <canvas> ...`, `give map of <canvas> to <p>` |
| motd | `set server motd to <expr>` |
| [schedulers](./schedulers) | `cancel schedule <handle>` (creation is the `schedule` *expression*) |

Targets accept a `Player`, a `List<Player>`, or the keyword `all` (broadcast).

## Durations

Declaration positions (`update:`, `refresh:`, `cooldown:`, title fades,
`actionbar ... for`, `every <dur>`, `schedule after/every <dur>`,
`fade song ... over <dur>`) take an *integer literal* plus a unit and are converted
to ticks at compile time:

| Written | Ticks |
|---|---|
| `10 ticks` / `1 tick` | as-is |
| `3 seconds` / `1 second` | × 20 |
| `250 millis` | ÷ 50 (minimum 1) |

The `wait` statement is more general — its amount is any numeric expression, and the
unit is kept for the runtime (`seconds`/`millis` sleep the task's virtual thread;
`ticks` aligns to tick end).

## Async

```swoftlang
async function countdown(target: Player, from: Integer) {
    loop from times as i {
        send "<yellow>${from - i + 1}..." to target
        wait 1 seconds
    }
    send "<lime>Go!" to target
}

async function double_it(x: Integer) {
    wait 1 ticks
    return x * 2
}

command "start" {
    execute {
        spawn countdown(sender, 3)      // fire-and-forget from sync code
        async {                          // anonymous fire-and-forget block
            wait 10 ticks
            send "ready" to sender
        }
        send "started" to sender         // runs immediately, no blocking
    }
}

command "race" {
    execute async {                      // whole handler is async
        wait 5 ticks
        set doubled to double_it(21)     // direct async call: sequential
        send "result ${doubled}" to sender
    }
}
```

Coloring rules the compiler enforces:

- `wait` only in async color (`async function`, `execute async`, `async { }`).
- Direct calls to async functions only from async color; from sync code use `spawn`.
- `spawn` and `async { }` are legal in both colors and never return a value.
- `cancel event` is banned in async regions — cancel in the sync prologue, then detach.
- Spawned tasks get a shallow snapshot of variables: reassignments don't leak back,
  object mutations are shared.

```
e_wait.sw:3:9: error: 'wait' is only allowed in async functions, 'execute async', or 'async { }' blocks
```

## Persistence {#persistence}

```swoftlang
storage {
  backend: files "data/swoftlang"     // or: sqlite "path.db" | mysql { ... } | mongodb "uri"
  flush: every 30 seconds             // write-behind cadence (default 30s)
}

persistent total_joins: Integer = 0            // global scalar, default required
persistent kills for Player: Integer = 0       // keyed by subject

Player {
    on_join {
        set total_joins to total_joins + 1
    }
}
```

Persistent types are limited to `String | Integer | Double | Boolean`. Defaults are
mandatory, so reads are total — never optional. Keyed access without `for` is a compile
error (`kills is keyed by Player — use kills for <player>`). See the
[server config](./server-config#storage-phase-3) page for backend configuration.

## Modules {#modules}

```swoftlang
import "music"                           // stdlib/addon by name (addon path)
                                         // import "./lib/util.sw" — relative form

var greeting_count = 0                   // module-level var: private, shared state

export function greet(target: Player) {  // 'export' makes it importable
    set greeting_count to greeting_count + 1
    send "hello (#${greeting_count})" to target
}

function helper() return 1               // un-exported = private to this file
```

`export` legally prefixes `function`, `item`, `mob`, `gui`, `scoreboard`, `tablist`,
and `bossbar`. Commands, events, `api` routes, schedulers, and packet listeners in an
imported module always register — they're effects, not symbols. Full rules, collision
errors, and the addon search path live in the [Libraries section](/1.7.0/libraries/).

## What the compiler catches

A non-exhaustive sampler of compile errors (each shown with real `swoftc` output on its
reference page): unknown/read-only properties, typos with did-you-mean suggestions,
optional misuse, wrong builtin arity or argument types, `wait` in sync code, `cancel
event` on non-cancellable events, sidebar line and tablist column caps, invalid
enum values (gamemode, bossbar color/style, click filters, tablist skins, rarities,
stats, attributes, entity types, nametag and glow colors, toast frames, HTTP
methods), GUI slot ranges, duplicate `server` blocks, unknown item/mob ids in
`give item` / `spawn mob` / drops, `reply` outside api handlers, `cancel packet`
outside packet listeners, blocking builtins in sync code, import cycles, calls to
un-exported module functions, and use of never-assigned variables.

Named runtime objects are checked against their declarations, too. Referring to a
`scoreboard`, `tablist`, `bossbar`, `gui`, `hologram`, `npc`, or named `schedule` that
no script declares is a compile error naming the declaration you're missing:

```
unknown_gui.sw:3:9: error: unknown gui 'nope'; declare it with 'gui "nope" { }'
```

And the *target* of a directed statement is type-checked: `show`, `send`, `title`,
`subtitle`, `actionbar`, and friends want a `Player`, a list of players, or `all` —
handing one a `String` (or any other type) is caught before it ships:

```
send_to_string.sw:4:22: error: cannot send a message to a String; expected a Player, a list of players, or 'all'
```
