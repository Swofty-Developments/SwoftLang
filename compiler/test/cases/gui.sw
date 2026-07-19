gui "storage" {
    rows: 6
    title: "Storage (page ${state.page + 1})"

    state {
        page: 0
        enabled: true
        items: []
    }

    fill: item("BLACK_STAINED_GLASS_PANE", name: " ")
    border: item("GRAY_STAINED_GLASS_PANE", name: " ", glint: false)

    slot 4 {
        item {
            material: "DIAMOND"
            name: "<green>Toggle"
            lore: ["<gray>hi ${player.name}", "<gray>page ${state.page}"]
            amount: 1
            glint: state.enabled
        }
        on_click(right) {
            set state.enabled to false
        }
        on_click {
            set state.page to state.page + 1
        }
        refresh: 1 seconds
    }

    slot 8 {
        item {
            skull: player.name
            name: "<aqua>You"
        }
        on_click(shift_left) {
            send "clicked slot ${slot} with ${click_type}" to player
        }
    }

    slots [0..3, 5..7] {
        item {
            material: "GRAY_STAINED_GLASS_PANE"
            name: " "
        }
    }

    editable [28..43] {
        on_change {
            send "slot ${slot} changed" to player
        }
    }

    paginate {
        source: state.items
        slots: grid(10, 27)
        render {
            material: "PAPER"
            name: "<white>#${index}"
        }
        on_click {
            send "you picked item ${index}" to player
        }
        prev_slot: 45
        next_slot: 53
    }

    refresh: 5 seconds

    on_open {
        send "<gray>opened storage" to player
    }
    on_close {
        send "<gray>closed (${reason})" to player
    }
    on_click {
        send "unhandled click on ${slot}" to player
    }
}

gui "confirm" {
    rows: 1
    title: "<red>Are you sure?"

    slot 3 {
        item {
            material: "LIME_WOOL"
            name: "<green>Yes"
        }
        on_click {
            async {
                set answer to prompt_input(player, "why?")
                send "because: ${answer}" to player
            }
            close gui for player
        }
    }
    slot 5 {
        item {
            material: "RED_WOOL"
            name: "<red>No"
        }
        on_click {
            go back for player
        }
    }
}

command "storage" {
    execute {
        open gui "storage" to sender with { page: 0 }
        replace gui "confirm" to sender
        go back for sender
        close gui for sender
    }
}
