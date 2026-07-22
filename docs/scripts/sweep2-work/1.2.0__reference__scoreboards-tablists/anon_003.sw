command "bb" {
    execute {
        show bossbar "objective" to sender
        set bossbar "objective" progress to 0.5 for sender
        set bossbar "objective" text to "<red>Danger!" for sender
        hide bossbar "objective" from sender
    }
}
