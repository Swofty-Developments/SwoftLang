---
title: Music
---

# Music — `import "music"`

Three helpers over the [NBS song statements](/1.6.0/reference/songs), thirty lines in all.
Song files live in `scripts/songs/*.nbs` (NBS v4/v5).

```swoftlang
import "music"

command "cafe" {
    execute {
        play_song_near("cafe.nbs", location(100.5, 64.0, 20.5), 16.0)
    }
}
```

The helpers cover the common cases; for pause/resume, fades, per-player volume, and
`at tick` starts, use the [song statements](/1.6.0/reference/songs#playback-statements)
directly.

## API

### play_song_near {#play_song_near}

`play_song_near(song_file: String, center: Location, radius: Double)`

| Param | Type | Meaning |
|---|---|---|
| `song_file` | `String` | file in `scripts/songs/` |
| `center` | `Location` | center of the audience |
| `radius` | `Double` | blocks from center |

Returns nothing. Starts the song for every player within `radius` blocks of
`center`. The audience is computed **once, at start** — players who wander in later
don't hear it, players who wander out keep hearing it.

```swoftlang
import "music"

command "ambient" {
    execute {
        play_song_near("cave_theme.nbs", sender.location, 24.0)
    }
}
```

### play_song_for_all {#play_song_for_all}

`play_song_for_all(song_file: String)`

| Param | Type | Meaning |
|---|---|---|
| `song_file` | `String` | file in `scripts/songs/` |

Returns nothing. Starts the song for everyone currently online (each player gets
their own session — late joiners are not included).

```swoftlang
import "music"

command "anthem" {
    execute {
        play_song_for_all("anthem.nbs")
    }
}
```

### stop_all_songs {#stop_all_songs}

`stop_all_songs()`

No parameters. Returns nothing. Stops whatever song every online player is hearing.

```swoftlang
import "music"

command "silence" {
    execute {
        stop_all_songs()
    }
}
```

## How it's built {#how-its-built}

The whole addon is
[`addons/music.sw`](https://github.com/Swofty-Developments/SwoftLang/blob/master/addons/music.sw):

```swoftlang
// Start a song for every player within 'radius' blocks of 'center'
// (radius is evaluated once, at start — it does not follow players).
export function play_song_near(song_file: String, center: Location, radius: Double) {
    play song song_file at center radius radius
}

// Start a song for everyone currently online.
export function play_song_for_all(song_file: String) {
    play song song_file to all players
}

// Stop whatever song every online player is hearing.
export function stop_all_songs() {
    stop song of all players
}
```

That's the entire source (minus the header comment): three `export function`
declarations wrapping three statements. Wrapping a wordy statement — or a repeated
argument shape — in a named function is what an addon this size is for. The
[writing-an-addon tutorial](./writing-an-addon) starts here.
