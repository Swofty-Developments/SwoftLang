// Phase-9 generic custom items showcase.
// The language provides identity, appearance, WYSIWYG lore, and a nested
// NBT tag API — no stats{}/ability{}. Gameplay systems are built in
// userland: on_click sugar for one-off interactions, and the abilities.sw
// stdlib addon (on_item_use + with_cooldown) for named, cooldowned actions.
// aspect_of_the_end: material + rarity + glint + nested tags + a cooldowned
// ability wired through abilities.sw. crypt_key: skull + nested tags + an
// on_click that mutates a tag. farmer_boots: real vanilla attributes + a
// loop lore. Plus a dispenser demo (phase 9 §5).

import "abilities"

item "aspect_of_the_end" {
    material: "DIAMOND_SWORD"
    name: "<blue>Aspect of the End"
    rarity: rare
    glint: true
    amount: 1

    lore {
        line "<gray>A legendary blade from the End."
        blank
        line "<dark_gray>Soulbound"
    }

    tags: {
        damage: 100,
        meta: { tier: 3, keywords: ["end", "sword"] }
    }
}

item "crypt_key" {
    skull: "1ae3855f952cd4a03c148a946e3f812a5955ad35cbcb52627ea4acd47d3081"
    name: "<gold>Crypt Key"
    rarity: epic

    tags: {
        uses: 3,
        meta: { engraving: "unclaimed" }
    }

    lore {
        line "<gray>Opens the sealed crypt beneath the graveyard."
        line "<dark_gray>Consumed on use."
    }

    // on_click sugar: a filtered PlayerUseItem for this id, binds player +
    // item; the tag write re-renders the lore and flushes back to the hand
    on_click(left) {
        set item.tags.uses to (item.tags.uses otherwise 0) - 1
        send "<light_purple>The key turns..." to player
    }
}

item "farmer_boots" {
    material: "GOLDEN_BOOTS"
    name: "<green>Farmer Boots"
    rarity: uncommon

    attributes: {
        speed: 0.02
        max_health: 4
    }

    lore {
        loop 2 times {
            line "<green>Tilled and true."
        }
    }
}

command "kit" {
    execute {
        give item "aspect_of_the_end" to sender
        give item "crypt_key" to sender
        give item "farmer_boots" to sender amount 2
        send "<green>Kit delivered." to sender
    }
}

// Wire the Aspect's ability with the abilities.sw addon: a named,
// cooldowned right-click that mirrors the removed ability{} block in
// userland. Register once at startup.
command "kit-setup" {
    execute {
        on_item_use("aspect_of_the_end", "right", with_cooldown(3.0,
            function(user: Player, held: Item) {
                send "<aqua>Instant Transmission! Whoosh." to user
            }))
        send "<gray>Aspect ability registered." to sender
    }
}

// Dispenser runtime (phase 9 §5): fire the dispenser/dropper at a location.
command "dispense-demo" {
    execute {
        dispense from location(0.0, 64.0, 0.0)
        send "<gray>Fired the dispenser at 0, 64, 0." to sender
    }
}

// The cancellable BlockDispense event: swap or block what comes out. `block`
// binds to the dispensing block; `item` is the ejected stack, `direction` the
// facing.
Block {
    on_dispense {
        send "<gray>A dispenser fired ${item.name} facing ${direction}." to all players
    }
}
