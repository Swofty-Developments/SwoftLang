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

command "tab" {
    execute {
        show tablist "lobby" to sender
        hide tablist from sender                              // wipe fakes, reset header/footer
        set tablist header to "<red>Maintenance" for sender   // one-off, until next cycle
        set tablist footer to "<gray>back soon" for all
    }
}
