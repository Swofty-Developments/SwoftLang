command "maybe" {
    execute {
        set cond to true
        if cond {
            set x to 1
        }
        set y to x + 1
    }
}
