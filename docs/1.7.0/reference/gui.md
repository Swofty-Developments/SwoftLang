# GUIs

GUIs are declared, not built imperatively. A `gui` block describes a chest inventory as
a pure function of per-player `state`; the runtime owns the session, renders it, routes
clicks, and re-renders (diffing only the changed slots) whenever a handler writes
`state`. You never touch cursor mechanics — every non-editable slot cancels vanilla
item movement automatically.

```swoftlang
gui "hello" {
    rows: 1
    title: "Hello"

    slot 4 {
        item { material: "DIAMOND", name: "<green>Click me" }
        on_click {
            send "clicked!" to player
        }
    }
}

command "hello-gui" {
    execute {
        open gui "hello" to sender
    }
}
```

## Declaration keys

Inside `gui "name" { ... }`, in any order:

| Key | Type | Required | Default | Meaning |
|---|---|---|---|---|
| `rows:` | integer 1–6 | **yes** | — | chest rows (9 slots each; slot indices `0 .. rows*9-1`) |
| `title:` | String expression | **yes** | — | re-evaluated on every render — interpolate `state` for dynamic titles |
| `state { k: expr ... }` | block | no | `{}` | initial per-open state map |
| `fill:` | [item value](#item-specs) | no | none | places the item in every slot not otherwise claimed |
| `border:` | [item value](#item-specs) | no | none | places the item around the outer ring |
| `slot N { ... }` | block | no | — | one slot; see [slot bodies](#slot-bodies) |
| `slots [list] { ... }` | block | no | — | same body on several slots; see [slot lists](#slot-lists) |
| `editable [list] { ... }` | block | no | — | players may take/place items; see [editable regions](#editable-regions) |
| `paginate { ... }` | block (max one) | no | — | list pagination template; see [pagination](#pagination) |
| `refresh:` | [duration](./syntax-cheatsheet#durations) | no | off | whole-view re-render timer |
| `on_open { ... }` | statements | no | — | runs after first render |
| `on_close { ... }` | statements | no | — | runs on teardown; binds `reason` |
| `on_click { ... }` | statements | no | — | global fallback for clicks on unregistered slots; binds `slot`, `click_type` |

The compiler validates everything it can see:

```
e_rows.sw:1:1: error: gui 'g' rows must be between 1 and 6 (got 7)
```
```
e_slotrange.sw:4:5: error: slot 30 is out of range for 2 row(s) (0..17)
```

## Slot lists {#slot-lists}

`slots` and `editable` take a bracketed list of indices and/or inclusive ranges:

```swoftlang
gui "ranges" {
    rows: 6
    title: "Ranges"

    slots [10..16, 19..25] {
        item { material: "PAPER", name: "<white>tile" }
    }

    editable [28..43] {
        on_change {
            send "slot ${slot} changed" to player
        }
    }
}
```

A range end below its start is a parse error. In `paginate`, `slots:` additionally
accepts `grid(a, b)` — the rectangle from `a` to `b` *excluding* the leftmost and
rightmost columns, which is how you say "the interior of the chest".

## Item specs {#item-specs}

Two spellings of the same thing:

**Block form** — inside `slot`, `slots`, and `paginate render`:

```swoftlang
gui "spec" {
    rows: 1
    title: "Spec"
    state { enabled: true }

    slot 0 {
        item {
            material: "DIAMOND"                      // XOR skull
            name: "<green>Toggle"
            lore: ["<gray>line 1", "<gray>${player.name}"]
            amount: 1
            glint: state.enabled
        }
    }
    slot 1 {
        item {
            skull: player.name                       // player head
            name: "<aqua>You"
        }
    }
}
```

**Call form** — in `fill:` / `border:` positions: `item(material [, amount]
[, name: e] [, lore: e] [, glint: e] [, skull: e])` with at most two positional
arguments (material, amount).

| Field | Type | Default | Meaning |
|---|---|---|---|
| `material` | String expression | — | material key, bare or `minecraft:`-prefixed |
| `skull` | String or Player expression | — | player head: a texture hash, or a `Player` value for their skin |
| `name` | String expression | item's own name | display name (MiniMessage tags work) |
| `lore` | list of String expressions | none | a single expression is treated as a one-line lore |
| `amount` | Number expression | 1 | stack size |
| `glint` | Boolean expression | false | enchantment glint override |

Exactly one of `material` / `skull` is required, and each field may appear once:

```
e_matskull.sw:5:14: error: item cannot have both 'material' and 'skull'
```

Item expressions re-evaluate on every render, so `state` and `player` references make
items live. `player` is bound in every expression and handler inside a `gui` block —
the viewer of this session.

## Slot bodies {#slot-bodies}

A `slot N { ... }` / `slots [..] { ... }` body contains:

| Entry | Required | Meaning |
|---|---|---|
| `item { ... }` | **yes** | what renders in the slot |
| `on_click(filter) { ... }` | no, repeatable | click handler; binds `slot` (Integer), `click_type` (String) |
| `refresh: <duration>` | no | per-slot re-render timer |

Click filters: `left`, `right`, `shift_left`, `shift_right`, `middle`, `double`, `any`.
Omitting the parenthesized filter means `any`. Multiple `on_click` blocks let you route
click types separately; the first matching handler wins:

```swoftlang
gui "clicky" {
    rows: 1
    title: "Clicky"
    state { page: 0, enabled: true }

    slot 4 {
        item { material: "DIAMOND", name: "<green>Button", glint: state.enabled }
        on_click(right) {
            set state.enabled to false        // state write -> re-render
        }
        on_click {
            set state.page to state.page + 1  // any other click
        }
        refresh: 1 seconds
    }
}
```

An unknown filter is caught at compile time:

```
e_filter.sw:6:24: error: Unknown click filter 'triple'; valid filters: left, right, shift_left, shift_right, middle, double, any
```

## State semantics {#state}

- `state` is a per-player, per-open map. `state { ... }` gives initial values;
  `open gui ... with { k: v }` overrides them for that open.
- Reads (`state.page`) are untyped (`Any`) — the escape hatch in an otherwise strict
  typechecker.
- Any `set state.x to ...` inside a handler marks the view dirty; after the handler
  returns, the layout re-runs and **only changed slots** are re-sent.
- Rendering is a pure function of `(state, player)`: item expressions and the title
  must not have side effects; put those in handlers.
- Timers (`refresh:` per-slot and whole-view) re-render on a schedule and auto-cancel
  when the session closes.

## Editable regions {#editable-regions}

Slots listed in `editable [...]` keep vanilla take/place/drag mechanics. The runtime
snapshots items before each click, batches diffs to the next tick (drag- and
shift-click-safe), then fires `on_change` once per changed slot with `slot` (Integer),
`old_item` (Item), and `new_item` (Item) bound:

```swoftlang
gui "chest" {
    rows: 3
    title: "Deposit"

    editable [9..17] {
        on_change {
            send "slot ${slot}: ${old_item.material} -> ${new_item.material}" to player
        }
    }
}
```

Initial contents render once and are never overwritten by re-renders — player edits
stick. Persist contents from `on_close`, which runs before teardown.

## Pagination {#pagination}

One `paginate { ... }` block per gui renders a list across a slot grid with automatic
page math (clamping, `ceil(total/slots)` page counts, prev/next arrows hidden at the
bounds):

| Key | Required | Default | Meaning |
|---|---|---|---|
| `source:` | **yes** | — | any list expression (usually `state.items`) |
| `slots:` | no | `grid(10, 43)` — the 7×4 interior | slot list or `grid(a, b)` |
| `render { ... }` | **yes** | — | item-spec block; binds `item` (element) and `index` |
| `on_click { ... }` | no | — | click on a rendered element; binds `item`, `index` |
| `prev_slot:` | no | auto arrows | slot for the previous-page arrow |
| `next_slot:` | no | auto arrows | slot for the next-page arrow |

The current page lives in `state.page`, so the title can show it. See the worked
example below for pagination in context.

## Navigation statements {#navigation}

Each player has a navigation *stack* of open GUIs with their saved state:

| Statement | Effect |
|---|---|
| `open gui "name" to <player> [with { k: v, ... }]` | push: saves the current gui (and its live state) on the stack, opens the new one |
| `replace gui "name" to <player> [with { ... }]` | switch without stacking |
| `close gui for <player>` | close whatever gui the player has open |
| `go back for <player>` | pop: reopen the previous gui with its saved state (closes if the stack is empty) |

Pressing ESC closes the gui and clears the whole stack. `on_close` runs in every case
with `reason` bound to one of `player_exited`, `server_exited`, or `replaced`.

```swoftlang
gui "confirm" {
    rows: 1
    title: "<red>Are you sure?"

    slot 3 {
        item { material: "LIME_WOOL", name: "<green>Yes" }
        on_click {
            close gui for player
        }
    }
    slot 5 {
        item { material: "RED_WOOL", name: "<red>No" }
        on_click {
            go back for player
        }
    }
}

command "confirm" {
    execute {
        open gui "confirm" to sender
    }
}
```

## Text input: prompt_input {#prompt-input}

`prompt_input(player, placeholder) : String` opens a sign editor and suspends the
current async task until the player submits. GUI handlers are *sync* (they run on the
tick thread), so wrap the call in `async { }`:

```swoftlang
gui "search" {
    rows: 1
    title: "Search"

    slot 4 {
        item { material: "OAK_SIGN", name: "<yellow>Search..." }
        on_click {
            async {
                set query to prompt_input(player, "search for?")
                send "you searched: ${query}" to player
            }
            close gui for player
        }
    }
}
```

Calling it directly from a handler is the async-only compile error shown in the
[builtins reference](./builtins#prompt-input).

## A complete worked example {#a-complete-worked-example}

A backpack-style storage screen: paginated contents, an editable deposit row, a live
player head, a toggle with per-slot refresh, and stacked navigation.

```swoftlang
gui "backpack" {
    rows: 6
    title: "Backpack (page ${state.page + 1})"

    state {
        page: 0
        locked: false
        items: []
    }

    fill: item("BLACK_STAINED_GLASS_PANE", name: " ")
    border: item("GRAY_STAINED_GLASS_PANE", name: " ")

    // live player head
    slot 4 {
        item {
            skull: player.name
            name: "<aqua>${player.name}'s backpack"
            lore: ["<gray>Health: ${player.health}"]
        }
        refresh: 2 seconds
    }

    // lock toggle: right-click locks, any other click unlocks
    slot 8 {
        item {
            material: "TRIPWIRE_HOOK"
            name: "<yellow>Lock"
            glint: state.locked
        }
        on_click(right) {
            set state.locked to true
        }
        on_click {
            set state.locked to false
        }
    }

    // paginated contents across the interior grid
    paginate {
        source: state.items
        slots: grid(10, 34)
        render {
            material: "CHEST"
            name: "<white>Item #${index}"
        }
        on_click {
            send "<gray>You picked entry ${index}" to player
        }
        prev_slot: 45
        next_slot: 53
    }

    // deposit row
    editable [37..43] {
        on_change {
            if state.locked {
                send "<red>Backpack is locked!" to player
            } else {
                send "<gray>Stored ${new_item.material}" to player
            }
        }
    }

    slot 49 {
        item { material: "BARRIER", name: "<red>Close" }
        on_click {
            close gui for player
        }
    }

    on_open {
        send "<gray>Opening backpack..." to player
    }
    on_close {
        send "<gray>Closed (${reason})" to player
    }
    on_click {
        send "<dark_gray>Nothing in slot ${slot} (${click_type})" to player
    }
}

command "backpack" {
    description: "Open your backpack"

    execute {
        open gui "backpack" to sender with { page: 0 }
    }
}
```

::: tip Where the semantics come from
The runtime is a declarative view layer in `net.swofty.gui`: per-player sessions,
dirty-state diff re-rendering, next-tick editable diffs, a per-player navigation stack,
and timer auto-cancelation. The `gui` block compiles to plain JSON
([schema](./json-ast#guis)) — the Java side walks it like everything else.
:::
