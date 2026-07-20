server {
    auth: mojang
    lighting: true
    host: "0.0.0.0"
    port: 25565
    brand: "SwoftLang"
    motd: "<green><bold>SwoftLang</bold> <gray>live demo"
}

storage {
    backend: files "data/swoftlang"
    flush: every 10 seconds
}

persistent visits for Player: Integer = 0

mob "zombie" {
    type: "ZOMBIE"
    health: 200
    ai: none
    viewable: false                   

    tags { hits: map<Player, Integer> }

    on_hit(attacker) {
        if attacker exists {
            set mob.tags.hits[attacker] to (mob.tags.hits[attacker] otherwise 0) + 1
            set count to mob.tags.hits[attacker] otherwise 0

            // this viewer sees their own nametag
            set name of mob to "<gold>Zombie <yellow>${count}<gray>/5" for attacker

            if count >= 5 {
                hide mob from attacker         
                send "<green>You slew your zombie!" to attacker
            } else {
                send "<red>Hit! <gray>(${count}/5)" to attacker
            }
        }
    }
}

event PlayerJoin {
    execute {
        send "<green>Hello, <yellow>${event.player.name}<green>! Welcome to the SwoftLang demo." to event.player
        send "<gray>Punch your zombie 5 times to slay it — each player gets their own." to event.player

        set visits for event.player to (visits for event.player) + 1

        show scoreboard "hud" to event.player
        show tablist "tab" to event.player

        spawn mob "zombie" at in_front_of(event.player, 5) as z
        set name of z to "<gold>Zombie <yellow>0<gray>/5" for event.player
        set z.glowing to true
        show z to event.player
    }
}

command "tp",
command "teleport" {
    description: "Teleport yourself to a player or to coordinates"

    arguments {
        player: Player = sender
        target: either<Player|Location>
    }

    execute {
        if args.player is not a Player {
            send "<red>You can only teleport players" to sender
            halt
        }

        teleport args.player to args.target
        send "<lime>Teleported ${sender} to ${args.target}"
    }
}

scoreboard "hud" {
    title: "<yellow><bold>SWOFTLANG DEMO"
    update: every 4 ticks
    numbers: hidden

    lines {
        line "<gray>Player: <white>${player.name}"
        blank
        line " <white>X: <aqua>${floor(player.location.x)}"
        line " <white>Y: <aqua>${floor(player.location.y)}"
        line " <white>Z: <aqua>${floor(player.location.z)}"
        blank
        line " <white>Health: <red>${floor(player.health)}"
        line " <white>Visits: <green>${visits for player}"
        blank
        line "<yellow>play.swofty.net"
    }
}

tablist "tab" {
    update: every 2 seconds
    header: "<aqua><bold>SWOFTLANG</bold> <gray>live demo"
    footer: "<green>Punch your zombie • try /tp"
}
