command "decay" {
    execute {
        set fuel to 10
        while fuel > 0 {
            set fuel to fuel - 3
        }
        send "fuel spent, ended at ${fuel}" to sender
    }
}
