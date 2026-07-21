---
title: Abilities
---

# Abilities — `import "abilities"`

Named item abilities on per-player cooldowns. `on_item_use` binds a handler to a
custom item id and click side; `with_cooldown` wraps a handler so it fires at most
once per player per cooldown window, showing an actionbar countdown while it waits.

```swoftlang
import "abilities"

item "aspect_of_the_end" {
    material: "DIAMOND_SWORD"
    name: "<blue>Aspect of the End"
    rarity: rare
    glint: true
}

command "kit-setup" {
    execute {
        on_item_use("aspect_of_the_end", "right", with_cooldown(3.0,
            function(user: Player, held: Item) {
                send "<aqua>Instant Transmission! Whoosh." to user
            }))
        send "<gray>Aspect ability registered." to sender
    }
}
```

## Exports

| Function | Signature | Returns |
|---|---|---|
| `on_item_use` | `(item_id: String, filter: String, handler)` | registers `handler` for that item id + click side |
| `with_cooldown` | `(seconds: Double, handler)` | a new handler of the same shape, gated by a per-player cooldown |

Both take a **handler** — a `function(user: Player, held: Item)` lambda. Because lambdas
are first-class values, `with_cooldown` returns a wrapped handler you hand straight to
`on_item_use`.

### `on_item_use(item_id, filter, handler)` {#on_item_use}

Registers `handler` to run when a player uses the [custom item](/1.1.0/reference/items) with id
`item_id`. `filter` is `"left"`, `"right"`, or `"any"`, kept for parity with the item
[`on_click`](/1.1.0/reference/items#on-click) sugar. Registering again for the same id + filter
replaces the previous handler. The handler receives the acting `Player` and the `Item`
in hand — read its [tags](/1.1.0/reference/items#tags-the-nbt-api) to drive stat formulas:

```swoftlang
import "abilities"

command "wire" {
    execute {
        on_item_use("aspect_of_the_end", "right",
            function(user: Player, held: Item) {
                set dmg to held.tags.damage otherwise 0
                send "<aqua>Transmission for ${dmg} damage!" to user
            })
    }
}

item "aspect_of_the_end" { material: "DIAMOND_SWORD" tags: { damage: 100 } }
```

### `with_cooldown(seconds, handler)` {#with_cooldown}

Wraps a `(Player, Item)` handler with a per-player cooldown of `seconds` seconds and
returns a handler of the same shape. When a player is still cooling down, the wrapped
handler sends an actionbar countdown and does nothing else; otherwise it runs the inner
handler and arms the cooldown. Each `with_cooldown` call owns an independent window, so
two wrapped abilities never share a timer:

```swoftlang
import "abilities"

command "wire" {
    execute {
        // a 5-second ability and a 1-second ability, independent cooldowns
        on_item_use("blink_staff", "right", with_cooldown(5.0,
            function(user: Player, held: Item) {
                send "<light_purple>Blink!" to user
            }))
        on_item_use("spark_wand", "right", with_cooldown(1.0,
            function(user: Player, held: Item) {
                send "<yellow>Spark!" to user
            }))
    }
}

item "blink_staff" { material: "BLAZE_ROD" }
item "spark_wand" { material: "STICK" }
```

## How it's built

`addons/abilities.sw` is about fifty lines of SwoftLang and uses three patterns from
the guide:

- **A module-level association chain** ([module vars](/1.1.0/guide/modules#module-vars)) stores
  handlers and cooldown deadlines by string key — the same closure-chain registry trick
  the retired NPC addon used before it became a runtime. `on_item_use` prepends a
  `"use:<id>:<filter>" -> handler` entry; `with_cooldown` reads and writes
  `"cd:<slot>:<uuid>"` deadlines.
- **A self-counted tick clock.** An `every 1 ticks` block increments a module counter, so
  the addon measures cooldown windows in ticks (20 per second) without needing a
  wall-clock builtin.
- **A single generic listener.** One [`PlayerUseItem`](/1.1.0/reference/events) handler reads
  `event.custom_id` and dispatches to every registered filter for that item — the one
  place all custom-item uses flow through.

```swoftlang
// the single generic surface: every custom-item use flows through here
event PlayerUseItem {
    execute {
        set id to event.custom_id otherwise ""
        // dispatch 'id' to the handlers registered for it (addon internals)
    }
}
```

::: tip One click side per press
The engine `PlayerUseItem` event reports the item, not which mouse button was pressed, so
every registered filter for an item fires here. When you need genuine left/right
separation, use the item declaration's [`on_click(<side>)`](/1.1.0/reference/items#on-click)
sugar, which compiles to a side-filtered handler. `with_cooldown` composes with either.
:::

The same shape — a registry of handlers, a tick clock, one dispatch listener — fits
any "named action with bookkeeping".
