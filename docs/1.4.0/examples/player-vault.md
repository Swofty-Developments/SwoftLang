---
title: Player Vault
---

<!-- swoftc-page excerpt=sources/Player_Vault.sw -->

# Player Vault

Ten permission-gated item vaults per player, captured slot by slot as they change and kept safe across restarts. 33 lines of Skript, 91 of SwoftLang; exercises GUIs, editable regions, a persistent `map<String>`, `to_nbt`/`from_nbt` item serialization, and permissions.

<MappedCompare title="Player_Vault.sk → Player_Vault.sw — the whole file, both sides">
<MappedPair label="the item store">
<template #skript>

*nothing to show — `{vault::%player%::%n%::%slot%}` entries pop into existence on first write, invisibly global*

</template>
<template #swoftlang>

```swoftlang
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
```

</template>
<template #note>

The store is a `map<String>` — a String-keyed dictionary — and `persistent`, so it serializes to the flat-file backend and comes back after a restart, exactly like Skript's `{vault::*}`. The trick that makes item stacks fit a *scalar* map: each value is the stack run through `to_nbt`, which turns an `Item` into its NBT string. See the [map reference](/1.4.0/reference/maps) for the type in full.

</template>
</MappedPair>
<MappedPair label="the /pv command">
<template #skript>

```skript
command pv <number> [<offline player>]:
 trigger:
  player's inventory contains "Vault":
   send "&cYou already have a vault open!"
   stop
  set {_target} to player
  arg-2 is set:
   player is op:
    set {_target} to arg-2
   else:
    send "&cYou don't have permission to view other players' vaults."
    stop
  arg-1 is between 1 and 10:
   player has permission "pv.%arg-1%" or "pv.*":
    open chest inventory with 6 rows named "Vault %arg-1%" to player
    set {openvault::%player%} to arg-1
    loop 54 times:
     if {vault::%{_target}%::%arg-1%::%loop-number - 1%} is set:
      set slot (loop-number - 1) of player's current inventory to {vault::%{_target}%::%arg-1%::%loop-number - 1%}
   else:
    send "&cYou don't have permission to open this vault."
  else:
   send "&cPlease choose a number between 1 and 10."
```

</template>
<template #swoftlang>

```swoftlang
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
```

</template>
<template #note>

`player is op` becomes a permission (`pv.others`) — there is no op bit in the language on purpose. `arg-1 is between 1 and 10` is a plain range check. Two things vanish: the "already have a vault open" inventory-name sniff (the runtime owns gui sessions; opening another replaces it) and `{openvault::%player%}` bookkeeping (the vault number and owner ride along as gui state in `open ... with { }`, so the `on_change` handler already knows which vault it is writing).

</template>
</MappedPair>
<MappedPair label="saving: close-loop vs on_change">
<template #skript>

```skript
on inventory close:
 name of event-inventory contains "Vault":
  set {_vaultnum} to {openvault::%player%}
  delete {openvault::%player%}
  loop 54 times:
   slot (loop-number - 1) of event-inventory is not air:
    set {vault::%player%::%{_vaultnum}%::%loop-number - 1%} to slot (loop-number - 1) of event-inventory
   else:
    delete {vault::%player%::%{_vaultnum}%::%loop-number - 1%}
```

</template>
<template #swoftlang>

```swoftlang
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
```

</template>
<template #note>

The .sk loops all 54 slots on close, hand-diffing air. An `editable` region fires `on_change` per *changed* slot with `slot`, `old_item`, `new_item` bound — the runtime does the diffing. Each change writes straight through to the persistent map: `to_nbt(new_item)` serializes the stack, `delete vault at key` clears a slot emptied back to `AIR`. Because the map is persistent, the whole vault is on disk the moment it changes — no close-time sweep required.

</template>
</MappedPair>
<MappedPair label="reading it back">
<template #skript>

*Skript reads `{vault::...}` from anywhere, no proof required — a typo'd index is just `<none>`*

</template>
<template #swoftlang>

```swoftlang
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
```

</template>
<template #note>

Two optionals, two `exists` gates — both enforced by the compiler, not by discipline. `vault[key]` is the index-read form (equivalently `vault.get(key)`); it yields `optional<String>` (the slot may be empty). `from_nbt` turns the stored NBT string back into an `Item`, and it is *also* optional — malformed data is provably `missing`, never a crash. The full round-trip, `to_nbt` on write and `from_nbt` on read, is what lets a scalar map hold real item stacks.

</template>
</MappedPair>
</MappedCompare>
