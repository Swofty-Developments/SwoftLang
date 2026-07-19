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
