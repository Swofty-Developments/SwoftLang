command "give-ish" {
    execute {
        set stack to item("DIAMOND", 3)
        set sender.held_item to stack
        send "material: ${stack.material}, amount: ${stack.amount}" to sender
    }
}
