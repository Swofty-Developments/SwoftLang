command "vars" {
    execute {
        set x to 10                    // declare/assign a local
        set x to x + 1                 // reassign
        set sender.health to 20.0      // property write (see Properties)
        set held to sender.held_item   // property read into a local
    }
}
