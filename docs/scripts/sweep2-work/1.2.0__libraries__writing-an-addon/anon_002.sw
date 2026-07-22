import "titles"

command "halloween" {
    execute {
        set_title_style(function(text: String) return "<dark_purple>☠ ${text} ☠")
        announce_all("The event begins")
    }
}
