---
title: Holograms
---

# Holograms

A `hologram` block declares a named stack of floating text: a base location, a
billboard mode, an optional scale and refresh cadence, and a restricted `lines { }`
DSL that reads like the [scoreboard](./scoreboards-tablists) sidebar. Each line is a
[text display](./displays) entity, auto-stacked 0.28 blocks apart; the runtime tracks
them by name, so you show, edit, move, and remove holograms by name — never by entity
handle.

```swoftlang
hologram "rules" {
    location: location(4, 70, 4)
    billboard: fixed
    lines {
        line "<aqua><bold>Server Rules"
        line "<gray>1. Be nice"
        line "<gray>2. No griefing"
    }
}

command "showrules" {
    execute {
        show hologram "rules" to all
    }
}
```

A hologram is declared once at the top level and shown from any handler. Declaring it
does not place it in the world — nothing renders until a `show` statement targets a
player or `all`.

## Declaration keys

| Key | Type | Required | Meaning |
|---|---|---|---|
| `location:` | `Location` | **yes** | anchor of line 0; lines stack downward |
| `billboard:` | mode | no | facing mode — `center` (default), `vertical`, `horizontal`, `fixed` |
| `scale:` | `Number` | no | display scale factor (`1.0` = default) |
| `update:` | `every <dur>` | no | re-render cadence for dynamic and per-viewer lines |
| `on_tick { ... }` | handler | no | runs every tick with `hologram` bound to the line stack |
| `lines { ... }` | block | **yes** | the line DSL — see below |

The billboard mode is an enum, checked at compile time — `center`, `vertical`,
`horizontal`, and `fixed` are the four Minecraft display billboard constraints. Anything
else is rejected:

```
bad_hologram_billboard.sw:3:5: error: unknown billboard mode 'diagonal'
```

## The `lines` block

`lines { }` is a restricted DSL — only four statement forms are allowed, the same
shape as a scoreboard's `lines`:

| Form | Renders |
|---|---|
| `line "<text>"` | one text line (MiniMessage; `${...}` interpolation) |
| `blank` | an empty spacer line |
| `if <cond> { ... } else { ... }` | lines from whichever branch matches |
| `loop <n> times { ... }` | the body's lines, `n` times |

```swoftlang
hologram "board" {
    location: location(0, 66, 0)
    lines {
        line "<gold><bold>Leaderboard"
        blank
        loop 3 times {
            line "<yellow>* * *"
        }
    }
}
```

Anything else inside `lines { }` is a compile error that names the four legal forms:

```
hologram_bad_line_dsl.sw:4:9: error: Unexpected identifier 'entry': only 'line', 'blank', 'if', and 'loop' are allowed inside 'lines { }'
```

## Per-viewer holograms

When a line interpolates a **player-scoped** path — `${player.name}`, `player.health`,
anything reached through the viewing `player` — the whole stack renders *per viewer*.
The compiler detects this automatically: the same `player`-binding machinery as
[per-viewer scoreboards](./scoreboards-tablists) runs the `lines` block once per player
who is shown the hologram, so each sees their own text.

```swoftlang
hologram "spawn_info" {
    location: location(0, 65, 0)
    billboard: center
    scale: 1.5
    update: every 1 seconds
    lines {
        line "<gold><bold>Welcome!"
        blank
        line "<gray>Hi ${player.name}"
        if player.health > 10 {
            line "<green>Healthy"
        } else {
            line "<red>Careful"
        }
    }
}

command "welcome" {
    execute {
        show hologram "spawn_info" to sender
    }
}
```

A hologram with no player-scoped line is **global**: one shared stack rendered for
everyone it is shown to. `update: every <dur>` re-runs the `lines` block on that
cadence, so interpolated counters and per-viewer conditions stay current without a
manual refresh loop.

## Per-tick handler

An `on_tick` handler runs every tick with `hologram` bound to the hologram's text-display
stack, a lower-level companion to `update: every <dur>` when you need per-frame control
over the line displays rather than a fixed re-render cadence:

```swoftlang
hologram "clock" {
    location: location(0, 66, 0)
    lines {
        line "<aqua>Clock"
    }
    on_tick {
        set hologram.text to "<aqua>Clock"
    }
}
```

::: tip Per-hologram timers
Inside a hologram handler `hologram` is the hologram, and it carries a
[task registry](./schedulers#obj-tasks):
`set hologram.tasks.<id> to schedule every N ticks { }` binds a named task that auto-cancels
when the hologram is removed.
:::

## Statements

Every hologram statement addresses a declared hologram by name:

| Statement | Effect |
|---|---|
| `show hologram "name" to <target>` | render it for a player, a list of players, or `all` |
| `hide hologram "name" from <target>` | stop rendering it for that target |
| `set hologram "name" line <n> to <expr>` | rewrite line `n` (0-based) in place, no flicker |
| `move hologram "name" to <location>` | move the whole stack; line offsets are kept |
| `remove hologram "name"` | destroy every line display for everyone |

```swoftlang
hologram "shop" {
    location: location(0, 82, 0)
    lines {
        line "<gold><bold>Item Shop"
        line "<gray>open"
    }
}

command "closeshop" {
    execute {
        set hologram "shop" line 1 to "<red>closed for maintenance"
        move hologram "shop" to location(2, 82, 0)
        show hologram "shop" to all
    }
}
```

Holograms are cleared on engine reload and shutdown, and re-torn-down when a viewer
disconnects — no dangling display entities to sweep up.

## Coming from a hologram plugin

<MappedCompare title="A named, multi-line hologram" leftLabel="Spigot + FancyHolograms" rightLabel="SwoftLang">
<MappedPair label="declare and show">
<template #skript>

```yaml
# FancyHolograms — holograms.yml, then an in-game /hologram create,
# then commands or a separate Skript to change lines at runtime
rules:
  location: world, 4, 70, 4
  billboard: FIXED
  lines:
    - "<aqua><bold>Server Rules"
    - "<gray>1. Be nice"
```

</template>
<template #swoftlang>

```swoftlang
hologram "rules" {
    location: location(4, 70, 4)
    billboard: fixed
    lines {
        line "<aqua><bold>Server Rules"
        line "<gray>1. Be nice"
    }
}

command "showrules" {
    execute {
        show hologram "rules" to all
    }
}
```

</template>
<template #note>

A plugin hologram is YAML plus a runtime plugin plus its command surface; per-viewer
text needs a placeholder engine on top. Here the hologram is one declaration the
compiler checks, `${player.name}` makes it per-viewer for free, and `show` / `set line`
/ `move` are statements — not plugin commands.

</template>
</MappedPair>
</MappedCompare>

## Diagnostics

A hologram statement that names a hologram no script declares is caught at compile
time, with the declaration you're missing spelled out:

```
unknown_hologram_ref.sw:3:9: error: unknown hologram 'ghost'; declare it with 'hologram "ghost" { }'
```

::: tip Supersedes the `holograms` addon
This first-class construct replaces the retired
[`holograms` addon](/1.4.0/libraries/holograms) — the one that stored line handles in a
closure chain and computed stack offsets by hand. That `import "holograms"` API is gone;
declare `hologram` blocks instead — fewer lines, typechecked, and per-viewer for free.
:::
