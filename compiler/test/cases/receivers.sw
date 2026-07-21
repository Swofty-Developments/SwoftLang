// OOP receiver blocks: Capitalized base-type receivers whose methods fire for
// every instance. Method names are validated against each receiver's fixed
// table; the user binders bind positionally to the fixed arg types, `this`
// binds to the receiver instance, and the body is sync-colored. Cancellable
// methods may `cancel event`. Emitted under the additive "receivers" key.

Player {
    on_join() {
        broadcast "<green>${this.name} joined"
    }

    on_chat(message) {
        if message is "secret" {
            cancel event
        }
        send "<gray>You said: ${message}" to this
    }

    on_death(death_text, chat_message) {
        broadcast "<red>${this.name} has fallen"
    }
}

// Base Mob: methods fire for every mob instance.
Mob {
    on_spawn() {
        broadcast "<gray>A mob has spawned"
    }

    on_hit(attacker) {
        set this.glowing to true
    }

    on_click(player) send "<gray>You poke a ${this.type}." to player
}

// Base Block: the positioned block value.
Block {
    on_place(player, location, block) {
        send "<gray>You placed a block" to player
    }

    on_break(player) {
        send "<gray>You broke a block" to player
    }
}

// A custom mob that OVERRIDES base Mob methods (most-specific wins). The bodies
// may call default() / super.<method>(...) to run the overridden base method.
mob "ghoul" {
    type: "ZOMBIE"
    name: "<dark_green>Ghoul"
    health: 40

    on_click(player) {
        send "<green>You poke the ghoul." to player
        default()
    }

    on_target(target) {
        super.on_target(target)
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
