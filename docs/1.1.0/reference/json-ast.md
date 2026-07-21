# JSON AST

::: warning Internals — you don't need this page to write scripts
This page documents the compiler↔runtime wire format. It exists for people
debugging the toolchain, building editor tooling, or embedding the runtime.
Nothing here is part of the script-facing language; the schema can grow additive
keys at any time. If you're writing `.sw` files, the
[cheatsheet](./syntax-cheatsheet) is the page you want.
:::

`swoftc` compiles a `.sw` file into one JSON document — schema `swoftlang-ast`,
version 2. The Java runtime deserializes it and *walks the tree*. There is no bytecode,
no codegen, no reflection over scripts: every construct on this page maps to one Java
class in the executor, and evaluation is plain recursive interpretation.

That split is the whole architecture: OCaml owns parsing and every compile-time
guarantee (types, options, async coloring, caps); Java trusts the JSON it is handed.
Anything the schema cannot express, the runtime cannot do.

All examples on this page are real `swoftc` output from the scripts in `scripts/`.

## Top level

```json
{
  "format": "swoftlang-ast",
  "version": 2,
  "commands":    [],
  "events":      [],
  "functions":   [],
  "guis":        [],
  "scoreboards": [],
  "tablists":    [],
  "bossbars":    [],
  "server":      null
}
```

One document per `.sw` file. Every array is always present (possibly empty);
`server` is an object or `null`.

::: tip Positions everywhere
Every node — statements, expressions, declarations, arguments — carries `"line"` and
`"col"` pointing at its source position. Runtime errors cite them, so a coercion
failure at 3 a.m. still says `myscript.sw:14:9`.
:::

Persistence adds two top-level keys (additive, no version bump): `"storage"`
(backend + flush cadence, or `null`) and `"persistents"` (declarations with `name`,
optional `subject` type, `type`, `default`). It also adds the `persist_get` expression
and `persist_set` statement kinds — see the
[cheatsheet](./syntax-cheatsheet#persistence).

Phase 5/6 keys are additive too, present only when used: `"items"`, `"mobs"`,
`"packet_listeners"`, `"apis"`, `"schedulers"`, and `"module_vars"`. Exported
declarations carry `"exported": true`.

### Module bundles {#bundles}

When a script `import`s modules (or several entry files are compiled together), the
top level becomes a **bundle** instead — the same per-file keys, one object per
module in dependency order:

```json
{
  "format": "swoftlang-ast",
  "version": 2,
  "modules": [
    { "name": "holograms", "path": "addons/holograms.sw", "entry": false,
      "module_vars": [], "functions": [], "commands": [], "events": [] },
    { "name": "lobby", "path": "scripts/lobby.sw", "entry": true,
      "functions": [], "commands": [], "events": [] }
  ]
}
```

The Java loader merges modules with collision checks — a duplicate exported symbol
across two modules is a load error naming both. A module imported by several entries
appears (and loads) once.

## DataType

Types appear in command arguments and function parameters:

```json
{ "base": "STRING" }
{ "base": "EITHER",   "subtypes": [ { "base": "PLAYER" }, { "base": "LOCATION" } ] }
{ "base": "OPTIONAL", "subtypes": [ { "base": "PLAYER" } ] }
{ "base": "LIST",     "subtypes": [ { "base": "STRING" } ] }
```

`base` is one of `STRING`, `INTEGER`, `DOUBLE`, `BOOLEAN`, `PLAYER`, `LOCATION`,
`WORLD`, `ITEM`, `EITHER`, `OPTIONAL`, `LIST`, or `UNKNOWN` (unrecognized type name —
emitted with a compile warning). Only the last three composite forms carry `subtypes`.

## Expressions

Every expression is `{ "line", "col", "kind", ... }`. The executor's
`evaluateExpression` switches on `kind`:

| kind | Fields | Meaning |
|---|---|---|
| `string` | `value` | string literal; simple `${a.b.c}` fragments stay raw and interpolate at runtime |
| `number` | `value`, `integer` | `integer: true` for `Integer`, else `Double` |
| `boolean` | `value` | |
| `none` | — | the missing optional value (`NoneValue.INSTANCE` in Java) |
| `var` | `name` | root identifier only — never dotted |
| `prop` | `target` (Expr), `name` | one property hop; chains nest left |
| `type` | `name` | type literal, right side of `is a` |
| `binary` | `op`, `left`, `right` | see operator list below |
| `unary` | `op` (`NOT` \| `NEGATE` \| `EXISTS`), `operand` | |
| `call` | `name`, `args` | user function or builtin |
| `all_players` | — | online-player collection (sugar for the builtin) |
| `list` | `items` | list literal |

Binary `op` values: `EQUALS`, `NOT_EQUALS`, `LESS_THAN`, `GREATER_THAN`,
`LESS_EQUALS`, `GREATER_EQUALS`, `AND`, `OR`, `OR_ELSE` (`otherwise`), `IS_TYPE`,
`IS_NOT_TYPE`, `CONTAINS`, `CONCATENATE`, `ADD`, `SUBTRACT`, `MULTIPLY`, `DIVIDE`,
`MODULO`.

`event.player.name` compiles to nested `prop` nodes over a root `var`:

```json
{
  "kind": "prop", "name": "name",
  "target": {
    "kind": "prop", "name": "player",
    "target": { "kind": "var", "name": "event", "line": 3, "col": 14 },
    "line": 3, "col": 20
  },
  "line": 3, "col": 27
}
```

Complex interpolation (`"${1 + 2}"`) is desugared by the compiler into `CONCATENATE`
chains of real expressions — the runtime only ever string-interpolates simple dotted
paths.

## Statements

Every statement is `{ "line", "col", "kind", ... }`; bodies are either a single
statement (`if` branches, loop bodies — usually a `block`) or arrays (handler bodies).

### Core

| kind | Fields |
|---|---|
| `send` | `message`, `target` (Expr or `null` = sender) |
| `broadcast` | `message` |
| `teleport` | `entity`, `target` |
| `halt` | — |
| `cancel_event` | — |
| `if` | `condition`, `then` (Stmt), `else` (Stmt or `null`; else-if chains nest here) |
| `block` | `statements` |
| `assign` | `target` (string, plain variable), `value` |
| `set_prop` | `target` (Expr), `name`, `value` — `set a.b.c to v` has `target` = `a.b`, `name` = `"c"` |
| `loop` | `count`, `var` (string or `null`), `body` |
| `while` | `condition`, `body` |
| `foreach` | `var`, `limit` (Expr or `null` — the `first N of` cap), `iterable`, `body` |
| `call` | `name`, `args` |
| `return` | `value` (Expr or `null`) |

Example — `set thing.point.x to 9.5`:

```json
{
  "kind": "set_prop",
  "name": "x",
  "target": {
    "kind": "prop", "name": "point",
    "target": { "kind": "var", "name": "thing", "line": 15, "col": 13 },
    "line": 15, "col": 19
  },
  "value": { "kind": "number", "value": 9.5, "integer": false, "line": 15, "col": 27 },
  "line": 15, "col": 19
}
```

### Async

| kind | Fields |
|---|---|
| `wait` | `amount` (Expr), `unit` (`"ticks"` \| `"seconds"` \| `"millis"`) |
| `spawn` | `call`: `{ "name", "args" }` |
| `async_block` | `body` (Stmt array) |

```json
{
  "line": 34, "col": 9,
  "kind": "spawn",
  "call": { "name": "farewell", "args": [ { "kind": "string", "value": "swofty", "line": 34, "col": 24 } ] }
}
```

### GUI navigation

| kind | Fields |
|---|---|
| `open_gui` / `replace_gui` | `name`, `target` (Expr), `init` (object of state-key → Expr) |
| `close_gui` / `gui_back` | `target` |

### Scoreboard / tablist / bossbar / titles

| kind | Fields |
|---|---|
| `show_scoreboard` | `name`, `target` |
| `hide_scoreboard`, `update_scoreboard` | `target` |
| `show_tablist` | `name`, `target` |
| `hide_tablist` | `target` |
| `set_tablist_part` | `part` (`"header"` \| `"footer"`), `value`, `target` |
| `show_bossbar`, `hide_bossbar` | `name`, `target` |
| `set_bossbar_part` | `name`, `part` (`"progress"` \| `"text"`), `value`, `target` |
| `title` | `title`, `subtitle` (or `null`), `target`, `fade_in`/`stay`/`fade_out` (ticks or `null`) |
| `clear_title` | `target` |
| `actionbar` | `text`, `target`, `duration` (ticks or `null`) |
| `belowname` | `text`, `target` |
| `set_belowname_score` | `value`, `target` |
| `clear_belowname` | `target` |

### Restricted-DSL statements

Only inside scoreboard `lines` and tablist `columns` bodies:

| kind | Fields |
|---|---|
| `line` | `text` |
| `blank` | — |
| `entry` | `text`, `skin` |
| `fill` | `skin` |

`skin` is `{ "kind": "builtin", "name": "green" }`,
`{ "kind": "player", "expr": Expr }`, or
`{ "kind": "custom", "texture": Expr, "signature": Expr }`.

## Commands

```json
{
  "line": 10, "col": 1,
  "names": [ "tp", "teleport" ],
  "permission": "swoftlang.teleport",
  "description": "Teleport a player to coordinates or another player",
  "arguments": [
    { "line": 16, "col": 9, "name": "player",
      "type": { "base": "PLAYER" }, "default": "sender" },
    { "line": 17, "col": 9, "name": "target",
      "type": { "base": "EITHER",
                "subtypes": [ { "base": "PLAYER" }, { "base": "LOCATION" } ] },
      "default": null }
  ],
  "execute": { "async": false, "statements": [ ... ] }
}
```

An alias group is **one** entry with several `names`; the loader registers one Minestom
command per name, all sharing the same execute block. `default` is the raw one-token
default as a string, or `null`. `execute` is `null` for a body-less command.

Execute blocks everywhere have the shape `{ "async": bool, "statements": [Stmt...] }` —
`async: true` means the runtime detaches the whole body onto a virtual thread.

## Events

```json
{
  "line": 1, "col": 1,
  "name": "PlayerChat",
  "priority": 0,
  "execute": { "async": false, "statements": [ ... ] }
}
```

## Functions

```json
{
  "line": 12, "col": 1,
  "name": "add",
  "async": false,
  "params": [
    { "line": 12, "col": 14, "name": "a", "type": { "base": "INTEGER" } },
    { "line": 12, "col": 22, "name": "b", "type": { "base": "INTEGER" } }
  ],
  "body": [ ... ]
}
```

`type` is `null` for untyped parameters. Return types are inferred at compile time and
not serialized — the runtime discovers the value when a `return` unwinds.

## GUIs {#guis}

```json
{
  "line": 1, "col": 1,
  "name": "storage",
  "rows": 6,
  "title": { "kind": "string", "value": "Storage (page ${state.page + 1})", ... },
  "state": { "page": Expr, "enabled": Expr, "items": Expr },
  "fill":   ItemSpec | Expr | null,
  "border": ItemSpec | Expr | null,
  "slots": [
    {
      "slots": [ 4 ],
      "item": ItemSpec,
      "click_handlers": [ { "filter": "right", "body": [Stmt...] },
                          { "filter": "any",   "body": [Stmt...] } ],
      "refresh": 20
    }
  ],
  "editable": [ { "slots": [ 28, 29, ... ], "on_change": [Stmt...] | null } ],
  "paginate": {
    "source": Expr,
    "slots": [ 10, 11, 12, 13, 14, 15, 16, 19, ... ],
    "render": ItemSpec,
    "on_click": [Stmt...] | null,
    "prev_slot": 45,
    "next_slot": 53
  } | null,
  "refresh": 100 | null,
  "on_open":  [Stmt...] | null,
  "on_close": [Stmt...] | null,
  "on_click_fallback": [Stmt...] | null
}
```

`ItemSpec` is six nullable expression fields:

```json
{
  "material": Expr | null,
  "skull":    Expr | null,
  "name":     Expr | null,
  "lore":     [Expr...] | null,
  "amount":   Expr | null,
  "glint":    Expr | null
}
```

Slot lists, ranges, and `grid(a, b)` are expanded to explicit integer arrays at compile
time (note the `slots` array above skipping 17 and 18 — the border columns of a
`grid(10, 27)`). All `refresh` values and durations are already converted to ticks.

## Scoreboards, tablists, bossbars

```json
{
  "name": "main",
  "title": Expr,
  "update": { "kind": "ticks", "value": 4 },
  "numbers": "hidden",
  "lines": [Stmt...]
}
```

```json
{
  "name": "lobby",
  "update": { "kind": "ticks", "value": 60 },
  "header": Expr | null,
  "footer": Expr | null,
  "columns": [ { "line": 6, "col": 5, "body": [Stmt...] } ]
}
```

```json
{
  "name": "objective",
  "text": Expr,
  "progress": Expr,
  "color": "yellow",
  "style": "progress",
  "update": { "kind": "ticks", "value": 30 }
}
```

`update` is `{ "kind": "ticks", "value": n }` or `{ "kind": "manual" }`. The `lines` /
`columns` bodies contain only the restricted-DSL statement kinds plus `if`, `loop`, and
`foreach` — the compiler guarantees it, the runtime just executes them with a
line/entry sink.

## Server {#server}

```json
{
  "line": 1, "col": 1,
  "auth": { "kind": "offline", "secret": null },
  "host": "0.0.0.0",
  "port": 25565,
  "brand": "SwoftLang",
  "motd": "<green>A SwoftLang server"
}
```

`auth.kind` ∈ `offline` | `mojang` | `velocity` | `bungeecord`; `secret` is non-null
only for `velocity`. Host and port defaults are baked in by the compiler.

## Compile errors

On failure, `swoftc` writes a machine-readable object to **stdout** (human diagnostics
go to stderr) and exits 1:

```json
{ "error": { "message": "event 'PlayerJoin' is not cancellable", "line": 3, "col": 9 } }
```

See the [CLI reference](./cli#diagnostics) for the full contract.

## Consuming the AST

The Java loader (`net.swofty.compiler.SwoftJsonLoader`) is a straight Gson walk: each
`kind` constructs the matching representation class, and `ASTExecutor` interprets the
tree. If you want to target SwoftLang from other tooling, emit this schema — the
runtime cannot tell the difference. The one thing you lose by skipping `swoftc` is the
entire compile-time story: nothing at the JSON layer checks types, arity, colors, or
caps.
