// Player_Vault.sk port — per-player numbered vaults behind permission checks.

// A flat-file backend, flushed on a timer: the vault survives restarts.
storage {
    backend: files "data/vaults"
    flush: every 30 seconds
}

// The authoritative copy of every occupied vault slot, keyed
// "<uuid>:<vault>:<slot>". Skript's {vault::%player%::%n%::%slot%} list is a
// runtime map; a persistent map<String> is the same idea — and because its
// values are the item stacks serialized with to_nbt, the whole store is
// scalar and persists to the backend, exactly like {vault::*} did.
persistent vault: map<String> = new_map()

function vault_key(owner: String, number: Integer, slot: Integer) {
    return "${owner}:${number}:${slot}"
}

command "pv" {
    description: "Open one of your ten vaults"

    arguments {
        number: Integer
        target: optional<Player>
    }

    execute {
        set owner to sender
        if args.target exists {
            if has_permission(sender, "pv.others") {
                set owner to args.target
            } else {
                send "<red>You don't have permission to view other players' vaults." to sender
                halt
            }
        }
        if args.number >= 1 and args.number <= 10 {
            if has_permission(sender, "pv.${args.number}") or has_permission(sender, "pv.*") {
                open gui "vault" to sender with { vaultnum: args.number, owner: owner.uuid }
            } else {
                send "<red>You don't have permission to open this vault." to sender
            }
        } else {
            send "<red>Please choose a number between 1 and 10." to sender
        }
    }
}

gui "vault" {
    rows: 6
    title: "Vault ${state.vaultnum}"

    editable [0..53] {
        on_change {
            set key to vault_key("${state.owner}", state.vaultnum, slot)
            if new_item.material is "AIR" {
                delete vault at key
            } else {
                set vault at key to to_nbt(new_item)
            }
        }
    }

    on_close {
        send "<gray>Vault ${state.vaultnum} saved." to player
    }
}

command "pvpeek" {
    description: "Inspect one stored vault slot"

    arguments {
        number: Integer
        slot: Integer
    }

    execute {
        set stored to vault[vault_key("${sender.uuid}", args.number, args.slot)]
        if stored exists {
            set restored to from_nbt(stored)
            if restored exists {
                send "Vault ${args.number} slot ${args.slot}: ${restored.material} x${restored.amount}" to sender
            } else {
                send "Vault ${args.number} slot ${args.slot} holds unreadable data." to sender
            }
        } else {
            send "Vault ${args.number} slot ${args.slot} is empty." to sender
        }
    }
}
