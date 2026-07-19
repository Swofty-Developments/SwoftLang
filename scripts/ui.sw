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
        line "<yellow>www.swofty.net"
    }
}

tablist "lobby" {
    update: every 3 seconds
    header: "<aqua>You are playing on <yellow><bold>SWOFTY.NET"
    footer: "<green>Have fun!"

    column {
        entry centered("Players") with skin green
        loop first 18 of all_players() as p {
            entry "${p.display_name}" with skin of p
        }
        fill with skin gray
    }
    column {
        entry centered("Server Info") with skin cyan
        entry "Latency: ${player.latency}ms" with skin gray
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
    description: "UI statement showcase"

    execute {
        show scoreboard "main" to sender
        update scoreboard for sender

        show tablist "lobby" to sender
        set tablist header to "<red>Maintenance" for sender

        show bossbar "objective" to sender
        set bossbar "objective" progress to 0.5 for sender

        title "<gold>WELCOME" subtitle "<gray>to SwoftLang" to sender fade in 1 seconds stay 3 seconds fade out 10 ticks
        actionbar "<aqua>boost!" to sender for 5 seconds
        belowname "<red>hearts" for sender
        set belowname score to sender.health for sender
    }
}

command "uihide" {
    description: "Hide every UI element again"

    execute {
        hide scoreboard from sender
        hide tablist from sender
        hide bossbar "objective" from sender
        clear title for sender
        clear belowname for sender
    }
}
