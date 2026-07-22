# Nametags

Per-viewer nametag control: set a player's whole tag, or just its prefix, suffix, or
color — for everyone, or for one specific viewer. Rank prefixes, disguises, "you are
being watched" markers: all one statement each.

```swoftlang
Player {
    on_join {
        set nametag of player to "<red>[ADMIN] ${player.name}"
        set nametag prefix of player to "&6[VIP] "
        set nametag suffix of player to " &7(AFK)"
        set nametag color of player to red
    }
}
```

## Statements

| Form | Effect |
|---|---|
| `set nametag of <player> to <string> [for <viewer \| all>]` | replace the whole visible name |
| `set nametag prefix of <player> to <string> [for ...]` | text before the name |
| `set nametag suffix of <player> to <string> [for ...]` | text after the name |
| `set nametag color of <player> to <color> [for ...]` | name color — bare name or String expression |
| `reset nametag of <player> [for ...]` | back to vanilla |

Without a `for` clause the change applies to **all** viewers, including players who
join later — the runtime re-sends nametag state on join. With `for <viewer>` only that
viewer sees it; the same player can look different to different people:

```swoftlang
command "spy" {
    arguments {
        target: Player
    }
    execute {
        // only the command sender sees the mark
        set nametag suffix of args.target to " <dark_red>☠" for sender
        send "<gray>Marked ${args.target.name} — only you see it." to sender
    }
}
```

## Colors

`set nametag color` takes one of the 16 protocol team colors, written bare
(`red`, `gold`) or as any String expression. The set is closed — team color is a
protocol enum, not RGB — and the compiler checks literals:

```
e_nt.sw:6:46: error: unknown nametag color 'badcolor'; valid colors: black, dark_blue, dark_green, dark_aqua, dark_red, dark_purple, gold, gray, dark_gray, blue, green, aqua, red, light_purple, yellow, white
```

Prefix and suffix strings accept the usual formatting — MiniMessage tags
(`<gold>`) and legacy `&` codes both work.

## How it works (and what that implies)

Nametags ride the same mechanism the vanilla scoreboard uses: single-member teams,
sent **per viewer** as `TeamsPacket`s (team names are prefixed `ZZZZZ` + username so
they sort last and never collide with real teams). Consequences worth knowing:

- Nothing is stored on the player entity — it's pure view state. Disconnect cleanup
  and join re-sends are handled by the runtime.
- Changes are cheap (one small packet per affected viewer) — animating a prefix from
  a [scheduler](./schedulers) is fine.
- A server-wide team plugin that also manages one-player teams could fight over the
  same protocol surface; SwoftLang assumes it owns nametags.

For floating text that *isn't* attached to a player's head, use
[text displays](./displays) or [holograms](/1.5.0/reference/holograms).
