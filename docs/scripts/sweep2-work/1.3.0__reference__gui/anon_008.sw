gui "backpack" {
    rows: 6
    title: "Backpack (page ${state.page + 1})"

    state {
        page: 0
        locked: false
        items: []
    }

    fill: item("BLACK_STAINED_GLASS_PANE", name: " ")
    border: item("GRAY_STAINED_GLASS_PANE", name: " ")

    // live player head
    slot 4 {
        item {
            skull: player.name
            name: "<aqua>${player.name}'s backpack"
            lore: ["<gray>Health: ${player.health}"]
        }
        refresh: 2 seconds
    }

    // lock toggle: right-click locks, any other click unlocks
    slot 8 {
        item {
            material: "TRIPWIRE_HOOK"
            name: "<yellow>Lock"
            glint: state.locked
        }
        on_click(right) {
            set state.locked to true
        }
        on_click {
            set state.locked to false
        }
    }

    // paginated contents across the interior grid
    paginate {
        source: state.items
        slots: grid(10, 34)
        render {
            material: "CHEST"
            name: "<white>Item #${index}"
        }
        on_click {
            send "<gray>You picked entry ${index}" to player
        }
        prev_slot: 45
        next_slot: 53
    }

    // deposit row
    editable [37..43] {
        on_change {
            if state.locked {
                send "<red>Backpack is locked!" to player
            } else {
                send "<gray>Stored ${new_item.material}" to player
            }
        }
    }

    slot 49 {
        item { material: "BARRIER", name: "<red>Close" }
        on_click {
            close gui for player
        }
    }

    on_open {
        send "<gray>Opening backpack..." to player
    }
    on_close {
        send "<gray>Closed (${reason})" to player
    }
    on_click {
        send "<dark_gray>Nothing in slot ${slot} (${click_type})" to player
    }
}

command "backpack" {
    description: "Open your backpack"

    execute {
        open gui "backpack" to sender with { page: 0 }
    }
}
