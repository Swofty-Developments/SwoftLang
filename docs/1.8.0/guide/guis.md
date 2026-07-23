---
title: GUIs
---

<StepHeader>
a clickable <code>/shop</code> — declared slots with their own handlers, live state, and zero inventory-click plumbing.
</StepHeader>

Inventory GUIs are declared, not assembled. A `gui` block describes rows, a title, and
slots; each slot carries its own item and its own click handlers. The runtime opens a
per-player session, cancels vanilla item-stealing automatically, and re-renders when
state changes. Slot indices are range-checked against `rows` at compile time.

<MappedCompare>
<MappedPair label="a two-item shop">
<template #skript>

```skript
# vanilla Skript 2.7+; addons (SkBee, skript-gui) improve on this
command /shop:
    trigger:
        set {_gui} to chest inventory with 3 rows named "Shop"
        set slot 11 of {_gui} to diamond sword named "&bSword &7(100 coins)"
        set slot 15 of {_gui} to golden apple named "&6Apple &7(20 coins)"
        open {_gui} to player

on inventory click:
    if name of event-inventory is "Shop":
        cancel event
        if index of event-slot is 11:
            send "&aPurchased!" to player
            close player's inventory
```

</template>
<template #swoftlang>

```swoftlang
gui "shop" {
    rows: 3
    title: "<dark_green>Shop"

    slot 11 {
        item { material: "DIAMOND_SWORD", name: "<aqua>Sword <gray>(100 coins)" }
        on_click {
            send "<green>Purchased!" to player
            close gui for player
        }
    }
    slot 15 {
        item { material: "GOLDEN_APPLE", name: "<gold>Apple <gray>(20 coins)" }
        on_click {
            send "<green>Crunchy." to player
        }
    }
}

command "shop" {
    execute {
        open gui "shop" to sender
    }
}
```

</template>
<template #note>

Vanilla Skript builds inventories imperatively and routes every click through a global
`on inventory click:` you filter yourself. Here the click handler lives *on the slot it
belongs to*, vanilla stealing is cancelled for you, and `slot 27` in a 3-row GUI would
be a compile error.

</template>
</MappedPair>
</MappedCompare>

The rest of this step is what else a `gui` block can carry.

## Click filters

`on_click` alone catches every click on the slot. Add a filter for specific buttons —
`left`, `right`, `shift_left`, `shift_right`, `middle`, `double`, `any` — and stack
multiple handlers; the most specific match wins:

```swoftlang
gui "buttons" {
    rows: 1
    title: "Buttons"

    slot 4 {
        item { material: "DIAMOND", name: "<aqua>Click me" }
        on_click(right) {
            send "right click" to player
        }
        on_click(shift_left) {
            send "shift left click on slot ${slot}" to player
        }
        on_click {
            send "some other click: ${click_type}" to player
        }
    }
}
```

Handlers bind `player`, `slot`, and `click_type`. GUI handlers are sync — they run on
the tick thread; for anything that waits, drop into `async { }` exactly as in
[Step 09](/1.8.0/guide/async).

## State: the GUI that re-renders itself

Each open GUI carries a per-player `state` map, seeded by the `state { }` block (or by
`open ... with { }`). Writing to `state.*` in a handler marks the view dirty — after the
handler finishes, anything that referenced that state re-renders, and only the changed
slots are resent:

```swoftlang
gui "counter" {
    rows: 1
    title: "Clicked ${state.clicks} times"

    state {
        clicks: 0
    }

    slot 4 {
        item {
            material: "EMERALD"
            name: "<green>${state.clicks} clicks"
            glint: state.clicks > 0
        }
        on_click {
            set state.clicks to state.clicks + 1
        }
    }
}

command "counter" {
    execute {
        open gui "counter" to sender with { clicks: 0 }
    }
}
```

`title`, `item` fields, and `glint` are all expressions, re-evaluated on render. An
`item { }` body takes `material` (or `skull:` — a texture hash, or a `Player` value for
their skin), `name`, `lore`, `amount`, and `glint`.

## Fill, border, and ranges

```swoftlang
gui "vault" {
    rows: 6
    title: "Vault"

    fill: item("BLACK_STAINED_GLASS_PANE", name: " ")
    border: item("GRAY_STAINED_GLASS_PANE", name: " ")

    slots [10..16, 19..25] {
        item { material: "CHEST", name: "<gray>a storage slot" }
        on_click {
            send "slot ${slot}" to player
        }
    }

    editable [28..43] {
        on_change {
            send "slot ${slot} changed" to player
        }
    }
}
```

`fill` paints every undeclared slot; `border` paints the outer ring. `slots [ranges]`
declares many identical slots at once. `editable [ranges]` marks regions where players
*can* place and take items — `on_change` fires with `slot`, `old_item`, and `new_item`
bound.

## Navigation

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

command "reset" {
    execute {
        replace gui "confirm" to sender
    }
}
```

`open gui` pushes onto a per-player navigation stack, `replace gui` swaps the top,
`go back for player` pops to the previous view with its state intact, and `close gui`
clears out. Escape closes the whole stack.

## Timers, lifecycle, pagination

Three more tools; the [GUI reference](/1.8.0/reference/gui) has full detail:

- `refresh: 1 seconds` on a slot (or the whole GUI) re-renders on a cadence — live
  countdowns without handlers.
- `on_open { }` and `on_close { }` bracket the session; `on_close` binds `reason`
  (`player_exited`, `server_exited`, or `replaced`). A gui-level `on_click { }` is the
  fallback for clicks nothing else handled.
- `paginate { }` turns a list into pages: give it a `source` list, a `slots: grid(10, 43)`
  region, a `render { }` item template (with `item` and `index` bound), and
  `prev_slot`/`next_slot` for auto-managed arrows.

## Asking the player for text

`prompt_input(player, placeholder)` opens a sign editor and returns what they type. It
blocks, so it's **async-only** — the checker enforces it:

```swoftlang
gui "rename" {
    rows: 1
    title: "Rename"

    slot 4 {
        item { material: "NAME_TAG", name: "<yellow>Rename" }
        on_click {
            async {
                set answer to prompt_input(player, "new name?")
                send "renamed to: ${answer}" to player
            }
            close gui for player
        }
    }
}
```

Next: things worth selling in that shop.
