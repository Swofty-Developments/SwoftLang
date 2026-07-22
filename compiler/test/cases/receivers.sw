// OOP receiver blocks: Capitalized base-type receivers whose methods fire for
// every instance. Method names are validated against each receiver's fixed
// table; the receiver instance binds under its natural noun (player/mob/block)
// and the event's args bind as bare variables, and the body is sync-colored.
// Cancellable methods may `cancel event`. Emitted under the additive
// "receivers" key.

Player {
    on_join {
        broadcast "<green>${player.name} joined"
    }

    on_chat {
        if message is "secret" {
            cancel event
        }
        send "<gray>You said: ${message}" to player
    }

    on_death {
        broadcast "<red>${player.name} has fallen"
    }
}

// Base Mob: methods fire for every mob instance.
Mob {
    on_spawn {
        broadcast "<gray>A mob has spawned"
    }

    on_hit {
        set mob.glowing to true
    }

    on_click send "<gray>You poke a ${mob.type}." to player
}

// Base Block: the positioned block value.
Block {
    on_place {
        send "<gray>You placed a block" to player
    }

    on_break {
        send "<gray>You broke a block" to player
    }
}

// A custom mob that OVERRIDES base Mob methods (most-specific wins). The bodies
// may 'call original method' to run the overridden base method.
mob Ghoul {
    type: "ZOMBIE"
    name: "<dark_green>Ghoul"
    health: 40

    on_click {
        send "<green>You poke the ghoul." to player
        call original method
    }

    on_target {
        call original method
    }
}

// The Packet receiver: class-name-keyed raw-packet handlers. Each `on "Class"`
// desugars into the existing packet-listener runtime; `player` and `packet` are
// bound in scope.
Packet {
    on "ClientPlayerActionPacket" {
        broadcast "<gray>A dig packet arrived"
    }

    on "ClientAnimationPacket" {
        send "<gray>You swung your arm" to player
    }
}
