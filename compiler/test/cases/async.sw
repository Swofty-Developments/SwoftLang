async function greet_later(p: Player, delay: Integer) {
    wait delay seconds
    send "<gold>Hello ${p.name}!" to p
}

function plain(n: Integer) {
    return n + 1
}

command "countdown" {
    description: "async command handler"

    execute async {
        set i to 3
        while i > 0 {
            send "${i}..." to sender
            wait 1 seconds
            set i to i - 1
        }
        wait 500 millis
        wait 20 ticks
        send "Go!" to sender
        greet_later(sender, 1)
        spawn greet_later(sender, 5)
        set answer to prompt_input(sender, "type something")
        send "you typed ${answer}" to sender
        set m to plain(41)
        send "m = ${m}" to sender
    }
}

event PlayerJoin {
    execute {
        send "<green>Welcome ${event.player.name}!" to all
        spawn greet_later(event.player, 5)
        async {
            wait 40 ticks
            set event.player.health to event.player.max_health
            send "healed!" to event.player
        }
    }
}
