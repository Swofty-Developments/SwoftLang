---
title: Writing an Addon
---

# Writing your own addon

An addon is one `.sw` file in the addon search path. No manifest, no build step, no
API jar — `export` what you mean to share, keep the rest private, and importers get
full typechecking against your signatures.

This page builds `titles.sw`, a small big-screen-text library, in four steps. Every
listing compiles (`swoftc check` runs on all of them), and the finished file uses
the same techniques as the [stdlib addons](./index#the-shipped-addons) — just
fewer of them at once.

What we're building:

<!-- swoftc name=hype.sw defer -->

```swoftlang
import "titles"

command "hype" {
    execute {
        announce(sender, "Boss incoming")
        announce_all("Sudden death!")
        set_title_style(function(text: String) return "<red><bold>${text}")
        spawn countdown(sender, 3, function(p: Player) send "<green>fight!" to p)
    }
}
```

## Step 1 — one file, one export

Create `addons/titles.sw` next to your `scripts/` directory:

<!-- swoftc name=titles.sw -->

```swoftlang
// titles.sw — step 1: one file, one export
export function announce(target: Player, text: String) {
    title text to target
}
```

That's a complete, working addon. Any script can now use it:

```swoftlang
import "titles"

command "shout" {
    execute {
        announce(sender, "<gold>Hello!")
    }
}
```

Two things happened silently. The import compiled both files **as one unit** — if
you pass `announce` an `Integer`, the error appears in *your* script, citing the
addon's real signature. And nothing but `announce` leaked: an addon exports
exactly what it says.

## Step 2 — private helpers and module state

Route every announcement through one styling function so titles stay consistent, and
give them nicer fade timing:

<!-- swoftc name=titles.sw -->

```swoftlang
// titles.sw — step 2: private helper + module state
var title_prefix = "<gold><bold>"

function styled(text: String) {
    return "${title_prefix}${text}"
}

export function announce(target: Player, text: String) {
    title styled(text) to target fade in 5 ticks stay 40 ticks fade out 10 ticks
}

export function announce_all(text: String) {
    loop all players as p {
        announce(p, text)
    }
}
```

- `var title_prefix = ...` is a **module-level variable**: initialized at load,
  shared by every call into the module, invisible outside it
  ([details and a concurrency caveat](./index#module-vars)).
- `styled` has no `export`, so it's private. A script that calls it anyway gets a
  compile error naming your module — this is real output from the same rule firing
  on the abilities addon:

```
e_private.sw:5:9: error: function 'ability_put' is private to module 'abilities' (addons/abilities.sw); add 'export' to its declaration to call it from here
```

## Step 3 — first-class functions as configuration

A prefix string is weak configuration — a *function* is strong configuration. Swap
the `var` to hold a lambda, and export a setter:

<!-- swoftc name=titles.sw -->

```swoftlang
// titles.sw — step 3: the style is a swappable lambda
var title_style = function(text: String) return "<gold><bold>${text}"

function styled(text: String) {
    return title_style(text)
}

export function announce(target: Player, text: String) {
    title styled(text) to target fade in 5 ticks stay 40 ticks fade out 10 ticks
}

export function announce_all(text: String) {
    loop all players as p {
        announce(p, text)
    }
}

export function set_title_style(style) {
    set title_style to style
}
```

An importer restyles every future announcement in one line — a function value
crossing a module boundary:

```swoftlang
import "titles"

command "halloween" {
    execute {
        set_title_style(function(text: String) return "<dark_purple>☠ ${text} ☠")
        announce_all("The event begins")
    }
}
```

This is the same pattern the [abilities addon](./abilities) uses for its
`on_item_use` handlers — its registry just stores many lambdas instead of one.

## Step 4 — async APIs and callbacks

Libraries can export `async function`s too; coloring rules flow across the module
boundary like everything else. A countdown that hands control back through a
callback:

<!-- swoftc name=titles.sw -->

```swoftlang
// titles.sw — step 4: async + callback
export async function countdown(target: Player, from: Integer, done) {
    loop from times as i {
        title "<yellow>${from - i + 1}" to target stay 15 ticks
        wait 1 seconds
    }
    title "<green>GO!" to target stay 20 ticks
    done(target)
}
```

Sync code can't call it directly (it `wait`s), but `spawn` works from anywhere:

```swoftlang
import "titles"

command "duel" {
    execute {
        spawn countdown(sender, 3, function(p: Player) {
            send "<green>The duel is on." to p
            teleport p to location(0.5, 80.0, 0.5)
        })
        send "<gray>Get ready..." to sender
    }
}
```

## The finished file

<!-- swoftc name=titles.sw -->

```swoftlang
// =========================================================================
// titles.sw — big-screen text helpers
//
//   import "titles"
//
//   announce(player, "<bold>Boss incoming")
//   announce_all("Sudden death!")
//   set_title_style(function(text: String) return "<red>${text}")
//   spawn countdown(player, 3, function(p: Player) send "go!" to p)
// =========================================================================

// module-private state: the formatting lambda every announcement goes through
var title_style = function(text: String) return "<gold><bold>${text}"

// private: one place that applies the current style
function styled(text: String) {
    return title_style(text)
}

// Show a styled title to one player.
export function announce(target: Player, text: String) {
    title styled(text) to target fade in 5 ticks stay 40 ticks fade out 10 ticks
}

// Show a styled title to everyone online.
export function announce_all(text: String) {
    loop all players as p {
        announce(p, text)
    }
}

// Swap the style used by every future announcement.
export function set_title_style(style) {
    set title_style to style
}

// 3.. 2.. 1.. GO — then hand control back through the callback.
export async function countdown(target: Player, from: Integer, done) {
    loop from times as i {
        title "<yellow>${from - i + 1}" to target stay 15 ticks
        wait 1 seconds
    }
    title "<green>GO!" to target stay 20 ticks
    done(target)
}
```

A header comment showing the import line and a call per export is the stdlib
convention — it's the first thing someone sees opening the file.

## Shipping it

- **Where it lives:** `addons/titles.sw` next to `scripts/` is found automatically;
  anywhere else needs [`--addon-path`](/1.5.0/reference/cli) at check/compile time and the
  matching engine configuration.
- **CI is one line:** `swoftc check scripts/*.sw --addon-path addons` typechecks
  every script *and* every addon they import.
- **Addons can ship effects.** A `command`, `event`, `api` route, scheduler, or
  packet listener declared in your addon registers when it's imported — that's how
  [abilities.sw installs its use-event listener](./abilities#how-its-built). Use it
  deliberately:
  effects are the part of your addon users can't opt out of. And don't try to
  `export` them:

```
e_expcmd.sw:1:8: error: commands and events always register when their module is imported (they are effects, not symbols); remove 'export'
```

- **No cycles.** If two addons need each other, extract the shared part into a
  third module both import:

```
b.sw:1:1: error: import cycle: a -> b -> a
```

## Where to go deeper

The stdlib addons are the reference implementations, in increasing order of technique:

| Addon | Teaches |
|---|---|
| [`music.sw`](./music#how-its-built) | wrapping statements in functions (30 lines) |
| [`abilities.sw`](./abilities#how-its-built) | closure-chain registries, lambdas across modules, per-player cooldowns |

Read them in that order and you'll have seen every trick the standard library knows.
The old `holograms` and `npcs` addons taught closure-chain registries and raw-packet
NPCs; both have since [graduated](/1.5.0/reference/holograms) to first-class constructs, but
the [raw packets reference](/1.5.0/reference/packets) still covers the packet techniques the
NPC addon used.
