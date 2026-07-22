// =========================================================================
// music.sw — convenience wrappers over the NBS song primitives (stdlib
// addon, design 6C; written in SwoftLang)
//
//   import "music"
//
//   play_song_near("cafe.nbs", location(100.5, 64.0, 20.5), 16.0)
//   play_song_for_all("anthem.nbs")
//   stop_all_songs()
//
// Song files live in scripts/songs/*.nbs (NBS v4/v5). These helpers are
// thin sugar over the 'play song' / 'stop song' statements — use the
// primitives directly for pause/resume/fade/volume and 'at tick' starts.
// =========================================================================

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
