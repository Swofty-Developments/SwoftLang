---
title: Modules & Addons
---

<StepHeader>
a private economy module with an exported API, plus a hologram from the stdlib — all resolved and typechecked at compile time.
</StepHeader>

Up to now, every function you declared was global. Modules give you boundaries:
`import` pulls another `.sw` file in at **compile time**, and only its `export`-marked
declarations become visible. Imports resolve when `swoftc` runs — a missing module or a
call to something private is a compile error, not a boot-time surprise.

## `import` and `export`

Two files. The module keeps its internals to itself and exports a two-function API:

<!-- swoftc name=coins.sw -->

```swoftlang
// coins.sw — a tiny economy module
var total_minted = 0

function mint(amount: Integer) {
    set total_minted to total_minted + amount
    return total_minted
}

export function give_coins(p: Player, amount: Integer) {
    mint(amount)
    send "<gold>+${amount} coins" to p
}

export function coins_minted() {
    return total_minted
}
```

<!-- swoftc name=bank.sw -->

```swoftlang
// bank.sw — an entry script using the module
import "./coins.sw"

command "payday" {
    execute {
        if sender is a Player {
            give_coins(sender, 250)
            send "<gray>minted so far: ${coins_minted()}" to sender
        }
    }
}
```

Everything crosses the boundary typed: `give_coins(sender, "lots")` is the same compile
error it would be in one file, [optional](/1.7.0/guide/options) types flow through, and
[async coloring](/1.7.0/guide/async) is enforced across module calls.

Un-exported declarations are private, and the compiler says so by name:

<!-- swoftc name=bank2.sw expect=error -->

```swoftlang
import "./coins.sw"

command "mint" {
    execute {
        mint(500)   // [!code error]
    }
}
```

```txt
bank2.sw:5:9: error: function 'mint' is private to module 'coins' (coins.sw); add 'export' to its declaration to call it from here
        mint(500)
        ^
```

`export` works on functions and on content declarations — items, mobs, GUIs,
scoreboards. Commands and events in an imported module always register: they're
effects, not symbols, which is how an addon can ship its own `/commands`.

## How imports resolve

```swoftlang
import "./coins.sw"
import "music"

command "resolve-demo" {
    execute {
        send "both forms resolved at compile time" to sender
    }
}
```

- `"./relative.sw"` — a path relative to the importing file.
- `"name"` — a library module: `name.sw` looked up next to your script, then in the
  addon search path (`addons/` by default; override with
  `swoftc check entry.sw --addon-path <dir>`).

Import cycles are compile errors. Importing the same module twice is a no-op — a module
imported by several entry scripts loads once, shared.

A name that resolves nowhere fails with the search trail:

<!-- swoftc name=bank3.sw expect=error noaddons -->

```swoftlang
import "economy"

command "x" {
    execute {
        send "hi" to sender
    }
}
```

```txt
bank3.sw:1:1: error: cannot resolve import "economy" (looked for economy.sw and addons/economy.sw)
import "economy"
^
```

## Module state: `var`

That `var total_minted = 0` line in `coins.sw` is a **module-level variable** — private,
typed by its initializer, alive for the server session. It's how a module keeps a
registry without exposing it.

Module state is shared, live state. Every command, event, api handler, and schedule that
calls into the module touches the same variable, so a compound update like
`set hits to hits + 1` from many concurrent async tasks can race. Keep module state
coarse, or funnel updates through sync code.

## The standard library

SwoftLang ships stdlib addons in the repository's `addons/` directory — written in
SwoftLang itself, so they double as example code (the
[Libraries](/1.7.0/libraries/) section documents each API):

| Module | Import | What you get |
|---|---|---|
| Music | `import "music"` | note-block song helpers |
| Abilities | `import "abilities"` | named item abilities on per-player cooldowns |

Holograms and NPCs used to live here too; they have since graduated to first-class
[`hologram`](/1.7.0/reference/holograms) and [`npc`](/1.7.0/reference/npcs) constructs. Using an
addon is one import plus function calls:

```swoftlang
import "music"

command "anthem" {
    execute {
        play_song_for_all("anthem.nbs")
    }
}
```

## Lambdas across modules

Module APIs get interesting because functions are
[first-class values](/1.7.0/guide/functions#inline-functions-lambdas): you can hand a module a
lambda and let it call you back. The [abilities addon](/1.7.0/libraries/abilities)'s handler
API is exactly that —

```swoftlang
import "abilities"

item AspectOfTheEnd {
    material: "DIAMOND_SWORD"
    rarity: rare
}

command "kit-setup" {
    execute {
        on_item_use("aspect_of_the_end", "right",
            function(user: Player, held: Item) {
                send "<aqua>Instant Transmission! Whoosh." to user
            })
    }
}
```

— and `on_item_use` is an ordinary exported function: it stores your lambda in module
state and calls it when the item's use event fires. The checker verifies your lambda's
signature against the call, across the module boundary. That pattern —
primitives in the runtime, ergonomics in an importable `.sw` module — is how the whole
stdlib is built, and nothing stops your modules doing the same.

One step left: putting a real server around all of this.
