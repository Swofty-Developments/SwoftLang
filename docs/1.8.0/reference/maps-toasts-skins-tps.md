# Maps, Toasts, Skins & TPS

The platform grab bag: map canvases you can draw on, advancement toasts, runtime
skin control, tick-rate introspection — plus the sound and particle statements.
Small surfaces, one page.

## Map canvases {#maps}

`map_canvas()` creates a 128×128 drawing surface; three `draw` statements paint it;
`give map` hands it to a player as a held filled map.

```swoftlang
command "wanted" {
    execute {
        set c to map_canvas()
        draw rect on c from 0, 0 to 127, 127 color "white"
        draw rect on c from 4, 4 to 123, 123 color "black"
        draw text on c at 30, 14 text "WANTED" color "red"
        draw text on c at 12, 60 text sender.name color "black"
        draw pixel on c at 64, 100 color 34
        give map of c to sender
    }
}
```

| Form | Effect |
|---|---|
| `map_canvas()` | new `Canvas` (128×128, `width`/`height` readable) |
| `draw pixel on <c> at <x>, <y> color <col>` | one pixel |
| `draw rect on <c> from <x1>, <y1> to <x2>, <y2> color <col>` | filled rectangle |
| `draw text on <c> at <x>, <y> text <s> color <col>` | text in a built-in 5×7 pixel font |
| `give map of <c> to <player>` | a filled-map item rendering the canvas |

Colors are either a **name** (`"red"`, `"white"`, `"black"`, …) or a raw
**MapPalette index** (a number) when you need the exact vanilla shade. Coordinates
run 0–127, origin top-left.

## Toasts {#toasts}

The advancement popup in the top-right corner, without declaring an advancement:

```swoftlang
Player {
    on_join {
        show toast "<gold>Welcome!" description "Have a look around" icon "COMPASS" frame task to player
    }
}
```

`show toast <title> [description <s>] [icon <material>] [frame task|goal|challenge] to <target>`

The frame changes the border art and sound; `challenge` gets the purple fanfare.
Frames are compile-checked:

```
e_toast.sw:3:31: error: unknown toast frame 'quest'; valid frames: task, goal, challenge
```

## Skins {#skins}

A player's skin is a property. Build a `Skin` value from a texture/signature pair,
or fetch a real player's by username:

| Form | Type | Notes |
|---|---|---|
| `skin(texture, signature)` | `Skin` | base64 property pair, as Mojang serves it |
| `fetch_skin(username)` | `Optional<Skin>` | **async-only** — live Mojang API lookup |
| `<player>.skin` | `Skin` | read/write — writing respawns the player's skin for all viewers |
| `<skin>.texture`, `<skin>.signature` | `String` | read-only |

```swoftlang
command "borrow-skin" {
    arguments {
        victim: String
    }
    execute async {
        set s to fetch_skin(args.victim)
        if s exists {
            set sender.skin to s
            send "<green>You are now wearing ${args.victim}'s skin." to sender
        } else {
            send "<red>No such Minecraft account." to sender
        }
    }
}
```

`fetch_skin` blocks its virtual thread on the Mojang API, so the compiler bans it
from sync code — same rule as `prompt_input`:

```
e_fetchsync.sw:3:18: error: 'fetch_skin' can only be called in async contexts ('async function', 'execute async', or 'async { }')
```

Skin values also feed [NPCs](/1.8.0/reference/npcs) and
[tablist entries](./scoreboards-tablists#tablist).

## TPS introspection {#tps}

Minestom has no vanilla TPS command — SwoftLang measures it from tick monitor events
into a ring buffer and exposes it three ways:

| Form | Type | Meaning |
|---|---|---|
| `server.tps` | `Double` | 1-minute average |
| `server.average_tps` | `Double` | 5-minute average |
| `server.mspt` | `Double` | milliseconds per tick |
| `tps_string()` | `String` | pre-colored `<green>20.0` / yellow / red |
| `average_tps_string()` | `String` | same, for the 5-minute figure |
| `tps_at(seconds_ago)` | `Double` | historical read from the ring buffer |

```swoftlang
command "lag" {
    execute {
        send "TPS ${tps_string()} <gray>(5m ${average_tps_string()}<gray>, ${server.mspt} mspt)" to sender
        send "<gray>one minute ago: ${tps_at(60)}" to sender
    }
}
```

And a [`Server`](/1.8.0/reference/events#server) method, fired when the integer TPS bucket
changes (crossing 19→18 fires; 19.4→19.1 doesn't):

```swoftlang
Server {
    on_tps_change {
        if current < 15.0 {
            broadcast "<red>Server struggling: ${past} -> ${current} TPS"
        }
    }
}
```

## Sounds {#sounds}

```swoftlang
command "dramatic" {
    execute {
        play sound "minecraft:entity.ender_dragon.growl" to all volume 0.8 pitch 0.7
        play sound "minecraft:block.bell.use" to sender at sender.location
        stop sound "minecraft:entity.ender_dragon.growl" for all
        stop sound for sender
    }
}
```

| Form | Effect |
|---|---|
| `play sound <key> to <target> [at <location>] [volume <v>] [pitch <p>]` | positional when `at` is given, else at the player |
| `stop sound [<key>] for <target>` | stop one sound, or all without a key |

Sound keys are the vanilla registry names (`minecraft:` prefix optional). Pitch runs
0.5–2.0, vanilla-style.

## Particles {#particles}

```swoftlang
command "sparkle" {
    execute {
        spawn particle "FLAME" at sender.location count 40 offset 0.5, 0.5, 0.5 speed 0.01
        spawn particle "HEART" at sender.location count 3 to sender
    }
}
```

`spawn particle <name> at <location> [count <n>] [offset <x>, <y>, <z>] [speed <s>] [to <viewer | all>]`

Without a `to` clause everyone near the location sees it; with one, only the named
viewers do. Offsets are the vanilla random-spread triple, not a direction vector.
For particle *packets* with every protocol field exposed, the
[raw packet escape hatch](./packets#sending-packets) still exists — this statement
covers the common 95%.
