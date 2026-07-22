command "mathy" {
    execute {
        set i to abs(-5)                       // Integer 5
        set d to abs(-5.5)                     // Double 5.5
        set capped to clamp(sender.health + 4.0, 0, sender.max_health)
        send "i=${i} d=${d} capped=${capped}" to sender
    }
}
