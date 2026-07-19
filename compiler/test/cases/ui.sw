scoreboard "main" {
    title: "<yellow><bold>SWOFTLANG"
    update: every 4 ticks
    numbers: hidden

    lines {
        line "<gray>${player.name}"
        blank
        line " <white>Health: <red>${player.health}"
        if player.level > 0 {
            line " <white>Level: <aqua>${player.level}"
        } else {
            line " <white>Level: <gray>none yet"
        }
        blank
        loop 2 times as i {
            line "<dark_gray>row ${i}"
        }
        line "<yellow>www.swofty.net"
    }
}

tablist "lobby" {
    update: every 3 seconds
    header: "<aqua>You are playing on <yellow><bold>SWOFTY.NET"
    footer: "<green>Have fun!"

    column {
        entry centered("Players (${length(all_players())})") with skin green
        loop first 18 of all_players() as p {
            entry "${p.display_name}" with skin of p
        }
        fill with skin gray
    }
    column {
        entry centered("Server Info") with skin cyan
        entry "Latency: ${player.latency}ms" with skin gray
        entry "Custom" with skin custom("texturedata", "signaturedata")
        fill with skin gray
    }
}

bossbar "objective" {
    text: "Objective: <yellow>collect wood"
    progress: player.exp
    color: yellow
    style: progress
    update: every 30 ticks
}

command "ui" {
    description: "ui statement showcase"

    execute {
        show scoreboard "main" to sender
        update scoreboard for sender
        hide scoreboard from sender

        show tablist "lobby" to sender
        set tablist header to "<red>Maintenance" for sender
        set tablist footer to "<gray>back soon" for all
        hide tablist from sender

        show bossbar "objective" to sender
        set bossbar "objective" progress to 0.5 for sender
        set bossbar "objective" text to "<red>Danger!" for sender
        hide bossbar "objective" from sender

        title "<gold>WELCOME" to sender
        title "<gold>NEW AREA" subtitle "<gray>The Wilds" to sender fade in 1 seconds stay 3 seconds fade out 10 ticks
        clear title for sender

        actionbar "<red>${sender.health}❤" to sender
        actionbar "<aqua>boost!" to sender for 5 seconds

        belowname "<red>❤" for sender
        set belowname score to sender.health for sender
        clear belowname for sender
    }
}
