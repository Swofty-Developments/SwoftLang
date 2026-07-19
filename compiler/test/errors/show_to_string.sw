scoreboard "main" {
    title: "hi"
    lines {
        line "x"
    }
}

command "s" {
    execute {
        set who to "steve"
        show scoreboard "main" to who
    }
}
