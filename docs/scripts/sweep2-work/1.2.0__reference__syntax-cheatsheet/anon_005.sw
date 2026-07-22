command "interp" {
    execute {
        set who to sender.name
        send "Hello ${who}, health ${sender.health}"          // simple paths
        send "Sum: ${1 + 2 * 3}, upper: ${uppercase(who)}"    // full expressions
    }
}
