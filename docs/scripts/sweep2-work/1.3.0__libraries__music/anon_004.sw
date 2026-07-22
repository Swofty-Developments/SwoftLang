import "music"

command "silence" {
    execute {
        stop_all_songs()
    }
}
