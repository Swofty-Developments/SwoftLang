command "titles" {
    execute {
        title "<gold>WELCOME" to sender
        title "<gold>WELCOME" subtitle "<gray>to SwoftLang" to sender
        title "<gold>GO" subtitle "<gray>now" to sender fade in 1 seconds stay 3 seconds fade out 10 ticks
        clear title for sender
    }
}
