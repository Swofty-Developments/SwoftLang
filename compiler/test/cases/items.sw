// Phase-9 generic item surface: identity + appearance + WYSIWYG lore + nested
// NBT tags + the on_click sugar. No stats{}/ability{} — gameplay systems are
// built in userland with event handlers (see the abilities.sw addon).

item "aspect_of_the_end" {
    material: "DIAMOND_SWORD"
    name: "<blue>Aspect of the End"
    rarity: rare
    glint: true
    amount: 1

    lore {
        line "<gray>Teleport 8 blocks ahead"
        blank
        if true {
            line "<gray>and gain a burst of speed."
        }
        loop 2 times {
            line "<dark_gray>* * *"
        }
    }

    attributes {
        speed: 0.05
        max_health: 10
    }

    tags {
        soulbound: true
        tier: 3
        meta: {
            origin: "the_end"
            keywords: ["teleport", "speed"]
        }
    }

    on_click(right) {
        send "<green>Whoosh!" to player
        if item.tags.tier exists {
            send "<gray>Tier ${item.tags.tier}" to player
        }
        cancel event
    }
}

item "grappling_hook" {
    skull: "abc123texturehash"
    rarity: epic
    tags {
        uses: 0
    }
}

command "kit" {
    execute {
        give item "aspect_of_the_end" to sender
        give item "grappling_hook" to sender amount 2
        set sender.held_item to custom_item("aspect_of_the_end")
    }
}

event PlayerUseItem {
    execute {
        if custom_id(event.item) otherwise "" is "aspect_of_the_end" {
            send "<gray>You used the Aspect!" to event.player
            cancel event
        }
    }
}
