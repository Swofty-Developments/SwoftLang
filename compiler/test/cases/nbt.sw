// Phase-9 NBT tag API: item.tags.<path...> get (optional<Any>, integrates with
// exists/otherwise), set (scalars, nested compounds, and 'to none' = delete).
// Works on ANY Item value — registry items, custom_item(), held_item,
// event.item — not just declared items.

item MysticBlade {
    material: "DIAMOND_SWORD"
    tags: {
        tier: 1
        meta: {
            origin: "vault"
            flags: ["glow", "bound"]
        }
    }
}

command "enchant" {
    execute {
        set blade to custom_item("mystic_blade")

        // set a scalar tag
        set blade.tags.tier to 5

        // read with a fallback, and read after narrowing with 'exists'
        set blade.tags.charges to (blade.tags.charges otherwise 0) + 1
        if blade.tags.tier exists {
            send "<green>Tier ${blade.tags.tier}" to sender
        }

        // nested path through a compound
        set blade.tags.meta.level to 10

        // delete a tag
        set blade.tags.tier to none

        set sender.held_item to blade
    }
}

Item {
    on_use {
        // tags read off the item value (`item`)
        if item.tags.soulbound exists {
            send "<gray>Soulbound." to player
        }
        set item.tags.uses to (item.tags.uses otherwise 0) + 1
    }
}
