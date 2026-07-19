// SwoftLang live demo — a single, self-contained showcase script.
//
// Highlights: an online-mode (Mojang auth) server with world lighting, a files
// storage backend, two flavours of persistent state (a per-player counter and a
// Player-keyed map), a custom mob whose damage is handled INLINE by its own
// on_hit block, a join greeting with a live scoreboard + tablist, and a /tp
// command over an either<Player|Location> argument.

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

// per-player visit counter, kept across restarts
persistent visits for Player: Integer = 0

// how many hits each player has left on the counter mob, keyed by the player
persistent hits: map<Player, Integer> = new_map()

mob "hit_counter" {
    type: "ZOMBIE"
    name: "<gold>Hit me! <yellow><bold>5</bold> <gold>left"
    health: 200
    ai: none

    // fired whenever a player punches this mob; the whole hit-counter game
    // lives right here, next to the mob it belongs to.
    on_hit(attacker) {
        if attacker exists {
            set left to (hits[attacker] otherwise 5) - 1

            if left <= 0 {
                despawn mob
                broadcast "<green>The hit-counter mob was destroyed!"
            } else {
                set hits at attacker to left
                set mob.name to "<gold>Hit me! <yellow><bold>${left}</bold> <gold>left"
            }
        }
    }
}

event PlayerJoin {
    execute {
        if not event.first_spawn {
            halt
        }

        send "<green>Hello, <yellow>${event.player.name}<green>! Welcome to the SwoftLang demo." to event.player
        send "<gray>Try <white>/tp</white>, watch the scoreboard, and punch the mob in front of you." to event.player

        set visits for event.player to (visits for event.player) + 1

        show scoreboard "hud" to event.player
        show tablist "tab" to event.player

        // spawn the counter mob three blocks ahead of the player and light it up
        spawn mob "hit_counter" at in_front_of(event.player, 3) as m
        set m.glowing to true
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
    footer: "<green>Punch the mob • try /tp"
}
