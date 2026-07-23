# Scoreboards & Tablists

Declarative sidebars, player-list columns, bossbars — plus the title, actionbar, and
belowname statements. Declarations describe *what a player sees*; per-player content
comes from evaluating the body with `player` bound to each viewer, on the cadence you
declare.

## Scoreboards (sidebars) {#scoreboard}

<!-- swoftc name=sb_main.sw -->

```swoftlang
scoreboard "main" {
    title: "<yellow><bold>SWOFTLANG"
    update: every 4 ticks
    numbers: hidden

    lines {
        line "<gray>${player.name}"
        blank
        line " <white>Health: <red>${player.health}"
        if player.level > 0 {
            line " <white>Level: <aqua>${player.level}"
        } else {
            line " <white>Level: <gray>none yet"
        }
        blank
        line "<yellow>www.swofty.net"
    }
}
```

| Key | Required | Default | Meaning |
|---|---|---|---|
| `title:` | **yes** | — | expression, re-evaluated every cycle (animatable) |
| `update:` | no | `manual` | `every N ticks\|seconds` or `manual` |
| `numbers:` | no | `hidden` | `hidden` (blank number format) or `shown` (red score numbers) |
| `lines { ... }` | **yes** | — | restricted DSL, evaluated per player per cycle |

The `lines { }` block allows exactly `line <string-expr>`, `blank`, `if`/`else`, and
`loop` — nothing else:

```
e_dsl.sw:4:9: error: Unexpected 'send': only 'line', 'blank', 'if', and 'loop' are allowed inside 'lines { }'
```

### The 15-line cap

The Minecraft client renders at most 15 sidebar lines. The compiler counts the maximum
number of lines any static path through your `lines` block can emit and rejects
overflows at compile time:

```
e_sidebar.sw:1:1: error: scoreboard 'big' can emit 16 lines on a static path; the sidebar limit is 15
```

### Statements

<!-- swoftc prelude=sb_main.sw -->

```swoftlang
command "sb" {
    execute {
        show scoreboard "main" to sender      // create lazily + add viewer
        update scoreboard for sender          // force one refresh now
        hide scoreboard from sender           // remove whatever board they see
    }
}
```

A player sees at most one sidebar — `show`ing a second implicitly hides the first.
`update scoreboard` is how `update: manual` boards ever change.

### Runtime notes

One Minestom `Sidebar` per (declaration, player). Each cycle re-evaluates the body into
a line list, then *diffs* against what the client has: content updates only for changed
lines, score updates only when positions shift, create/remove only at the tail. Scores
are `count - 1 - i` so lines render top-down in declaration order; `numbers: hidden`
uses the blank number format. Updates run as one scheduler task per declaration at tick
end.

## Tablists {#tablist}

<!-- swoftc name=tl_lobby.sw -->

```swoftlang
tablist "lobby" {
    update: every 3 seconds
    header: "<aqua>You are playing on <yellow><bold>SWOFTY.NET"
    footer: "<green>Have fun!"

    column {
        entry centered("Players") with skin green
        loop first 18 of all_players() as p {
            entry "${p.display_name}" with skin of p
        }
        fill with skin gray
    }
    column {
        entry centered("Server Info") with skin cyan
        entry "Latency: ${player.latency}ms" with skin gray
        fill with skin gray
    }
}
```

| Key | Required | Default | Meaning |
|---|---|---|---|
| `update:` | no | `manual` | `every N ticks\|seconds` or `manual` |
| `header:` | no | none | expression, per player per cycle |
| `footer:` | no | none | expression, per player per cycle |
| `column { ... }` | repeatable | — | one visual column (≤ 20 entries) |

Column bodies are a restricted DSL: `entry <string-expr> [with skin <skin>]`,
`fill [with skin <skin>]`, `if`/`else`, `loop`. `fill` pads the column to 20 rows with
blank entries so the next column starts cleanly.

### Skins

Every entry renders with a player-head icon:

| Skin syntax | Meaning |
|---|---|
| `with skin green` | builtin palette: `green`, `gray`, `cyan`, `blue`, `purple`, `orange` (flat colored heads) |
| `with skin of <player-expr>` | that player's actual skin |
| `with skin custom(texture, signature)` | raw base64 texture + Mojang signature pair |
| *(omitted)* | `gray` |

Unknown palette names are compile errors (with a suggestion).

### The 20-entry cap

The vanilla client wraps the player list every 20 entries — that is what makes columns
work at all. Exceeding it would bleed into the next column, so the compiler rejects it:

```
e_column.sw:4:5: error: tablist column can emit 21 entries on a static path; the client limit is 20 per column
```

### Statements

<!-- swoftc prelude=tl_lobby.sw -->

```swoftlang
command "tab" {
    execute {
        show tablist "lobby" to sender
        hide tablist from sender                              // wipe fakes, reset header/footer
        set tablist header to "<red>Maintenance" for sender   // one-off, until next cycle
        set tablist footer to "<gray>back soon" for all
    }
}
```

### Runtime notes (packets)

Minestom has no high-level API for fake list entries, so the tablist runtime speaks
packets directly (`net.swofty.ui.SwoftTablistRuntime`):

- Each cycle, per viewer: wipe the previous fakes with one `PlayerInfoRemovePacket`,
  then rebuild every column in order.
- Entries are fake profiles with deterministic UUIDs
  (`nameUUIDFromBytes(viewerUuid + "#tab#" + slot)`) and names `"tab" + base36(slot)` —
  stable across refreshes, so clients don't flicker.
- Ordering uses the modern `listOrder` field (1.21.2+) set to the slot index — no
  `TAB000`-style team-name hacks, no collisions with gameplay teams.
- Skins ride the profile's `textures` property; the six palette constants are the
  base64+signature pairs shipped in the runtime.
- Per-column exceptions are swallowed so one broken column can't kill the loop; all
  fakes are removed on disconnect.

## Bossbars {#bossbar}

<!-- swoftc name=bb_obj.sw -->

```swoftlang
bossbar "objective" {
    text: "Objective: <yellow>collect wood"
    progress: player.exp
    color: yellow
    style: progress
    update: every 30 ticks
}
```

| Key | Required | Default | Meaning |
|---|---|---|---|
| `text:` | **yes** | — | expression, per player per cycle |
| `progress:` | **yes** | — | number expression, clamped to 0..1 |
| `color:` | no | `white` | `pink`, `blue`, `red`, `green`, `yellow`, `purple`, `white` |
| `style:` | no | `progress` | `progress`, `notched_6`, `notched_10`, `notched_12`, `notched_20` |
| `update:` | no | `manual` | `every N ticks\|seconds` or `manual` |

Bad enum values die at compile time:

```
e_color.sw:1:1: error: unknown bossbar color 'teal'; valid colors: pink, blue, red, green, yellow, purple, white
```

### Statements

<!-- swoftc prelude=bb_obj.sw -->

```swoftlang
command "bb" {
    execute {
        show bossbar "objective" to sender
        set bossbar "objective" progress to 0.5 for sender
        set bossbar "objective" text to "<red>Danger!" for sender
        hide bossbar "objective" from sender
    }
}
```

One Adventure `BossBar` instance per (declaration, player); updates mutate `name`/
`progress` in place and Minestom pushes the packets automatically. All of a player's
bars are removed on disconnect.

## Titles {#titles}

```swoftlang
command "titles" {
    execute {
        title "<gold>WELCOME" to sender
        title "<gold>WELCOME" subtitle "<gray>to SwoftLang" to sender
        title "<gold>GO" subtitle "<gray>now" to sender fade in 1 seconds stay 3 seconds fade out 10 ticks
        clear title for sender
    }
}
```

`fade in` / `stay` / `fade out` take [duration literals](./syntax-cheatsheet#durations)
and may appear in any order after the target; omitted times use the vanilla defaults
(10 / 70 / 20 ticks). Omitted subtitle is empty. `clear title` resets immediately.

## Actionbar {#actionbar}

```swoftlang
command "ab" {
    execute {
        actionbar "<aqua>boost!" to sender                  // single send (fades ~2s)
        actionbar "<red>${sender.health}❤" to sender for 5 seconds
    }
}
```

The client has no persistent-actionbar API — bare sends fade after a couple of
seconds. The `for <duration>` form runs a 2-tick repeater that re-sends the text for
the duration, which is the standard workaround.

## Belowname {#belowname}

```swoftlang
command "bn" {
    execute {
        belowname "<red>hearts" for sender                  // label under the name tag
        set belowname score to sender.health for sender     // the number next to it
        clear belowname for sender
    }
}
```

The score must be a number (it renders as an integer). One belowname objective per
player; setting a new label replaces the old one for all viewers.

## Update cadences and targets

- `update: every N ticks|seconds` schedules one task per declaration (tick-end
  execution) that refreshes every current viewer. `update: manual` means nothing
  happens until an explicit `update ... for <player>` statement (scoreboards) or a
  `set ... for <player>` override (tablists/bossbars).
- Every `to`/`for`/`from` target accepts a `Player`, a `List<Player>`, or `all`:

```swoftlang
scoreboard "main" { title: "<gold>Stats" lines { line "<gray>hi" } }
bossbar "objective" { text: "<yellow>Go" progress: 0.5 color: yellow style: progress }

command "everyone" {
    execute {
        show scoreboard "main" to all
        show bossbar "objective" to all_players()
    }
}
```

- Statements do not require the declaration to live in the same file — names resolve
  across all loaded scripts at runtime.

For the text floating *over a player's head* — name, prefix, suffix, color, per
viewer — see the [nametags reference](./nametags); for free-floating text in the
world, [displays](./displays) and [holograms](./holograms).
