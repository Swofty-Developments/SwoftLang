# Songs (NBS)

Note Block Studio songs, played per player through note-block sounds — no resource
pack, no client mod. Drop `.nbs` files (format v4/v5) into `scripts/songs/` and refer
to them by filename.

```swoftlang
command "radio" {
    execute {
        play song "cafe.nbs" to sender
        send "<gray>Now playing." to sender
    }
}
```

## Playback statements

| Form | Effect |
|---|---|
| `play song <file> to <player \| list \| all> [at tick <n>]` | start (optionally mid-song) |
| `play song <file> at <location> radius <r>` | start for everyone within `r` blocks |
| `broadcast song <file>` | start for everyone online |
| `pause song of <target>` | freeze at the current tick |
| `resume song of <target>` | continue from the pause point |
| `stop song of <target>` | stop and forget the position |
| `set song volume of <target> to <0..1>` | per-player volume |
| `fade song of <target> to <volume> over <duration>` | ramp volume across a duration |

Each player has one song session — starting a new song replaces the old one.
Playback is per player: two players can hear different songs, or the same song at
different volumes.

```swoftlang
command "ambience" {
    execute {
        // radius is evaluated once at start — it does not follow players
        play song "cave_theme.nbs" at location(100.5, 40.0, 20.5) radius 16.0
    }
}

command "nightclub" {
    execute {
        play song "drop.nbs" to all
        set song volume of all players to 1.0
    }
}

command "wind-down" {
    execute {
        fade song of sender to 0.0 over 5 seconds
    }
}
```

`at tick <n>` starts mid-song — useful for synchronized rejoin:

```swoftlang
command "sync-join" {
    execute {
        play song "anthem.nbs" to sender at tick 200
    }
}
```

## Song metadata

`song(<file>)` loads the file's header as a `Song` value:

| Property | Type | Meaning |
|---|---|---|
| `title` | `String` | song title from the NBS header |
| `author` | `String` | author field |
| `length` | `Integer` | length in song ticks |
| `speed` | `Double` | ticks per second |

```swoftlang
command "nowplaying" {
    execute {
        set s to song("cafe.nbs")
        set seconds to round(s.length / s.speed)
        send "<gold>${s.title}<gray> by ${s.author} — ${seconds}s" to sender
    }
}
```

## How playback works

The NBS parser is built into the runtime (v4 and v5 headers). A per-player session on
the tick scheduler converts each note into the matching
`BLOCK_NOTE_BLOCK_*` sound event with the right pitch. That means:

- songs sound identical for everyone, on vanilla clients,
- per-player volume is just sound volume — mid-song fades are smooth,
- densely-arranged songs cost a few packets per tick per listener; that's it.

::: tip The music addon
`import "music"` gets you [`play_song_near`, `play_song_for_all`, and
`stop_all_songs`](/1.2.0/libraries/music) — three thin wrappers over these statements,
and the smallest possible example of a SwoftLang-authored library.
:::
