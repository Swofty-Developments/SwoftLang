import "music"

command "ambient" {
    execute {
        play_song_near("cave_theme.nbs", sender.location, 24.0)
    }
}
