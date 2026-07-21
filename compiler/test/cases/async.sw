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

Player {
    on_join {
        send "<green>Welcome ${player.name}!" to all
        spawn greet_later(player, 5)
        async {
            wait 40 ticks
            set player.health to player.max_health
            send "healed!" to player
        }
    }
}
