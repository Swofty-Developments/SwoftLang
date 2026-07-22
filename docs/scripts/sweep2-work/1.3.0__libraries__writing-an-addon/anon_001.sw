import "titles"

command "shout" {
    execute {
        announce(sender, "<gold>Hello!")
    }
}
