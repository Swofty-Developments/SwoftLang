import "music"

command "cafe" {
    execute {
        play_song_near("cafe.nbs", location(100.5, 64.0, 20.5), 16.0)
    }
}
