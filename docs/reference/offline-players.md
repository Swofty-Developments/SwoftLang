# Offline Players

An `OfflinePlayer` is a player the server has seen before — online or not. It carries
identity (name, UUID), seen-store timestamps, and a bridge back to a live `Player` when
one is connected. Every online player *is* an offline player: `Player` is a subtype of
`OfflinePlayer`, so every row and function below accepts a live `Player` directly.

```swoftlang
set found to offline_player("Notch")
if found exists {
    send "<gold>${found.name}</gold> — last seen ${found.last_seen}" to sender
    if found.player exists {
        send "<green>Someone looked you up!" to found.player
    }
}
```

## The `OfflinePlayer` value

| Property | Type | Access | Meaning |
|---|---|---|---|
| `name` | `String` | ro | last known name |
| `uuid` | `String` | ro | the account UUID |
| `online` | `Boolean` | ro | live lookup — are they connected right now |
| `player` | `optional<Player>` | ro | the live `Player` when online, `none` otherwise — **the bridge** |
| `first_seen` | `String` | ro | ISO timestamp from the seen-store (`"unknown"` if pre-tracking) |
| `last_seen` | `String` | ro | updated on quit, and read as "now" while online |
| `has_played_before` | `Boolean` | ro | present in the seen-store |

The `player` bridge is the crossing point between the offline and online worlds. It is an
`optional<Player>`, so narrowing with `exists` is what turns an offline record into a
live player you can message, teleport, or give items to — no null, no guessing.

## Player is an OfflinePlayer

Because `Player <: OfflinePlayer`, a function that takes an `OfflinePlayer` accepts an
online player, and `is a Player` narrows an offline value to the live type where it
applies:

```swoftlang
function describe(subject: OfflinePlayer) {
    if subject is a Player {
        send "you are online right now" to subject
    }
}
```

## Builtins

| Builtin | Returns | Notes |
|---|---|---|
| `offline_player(name)` | `optional<OfflinePlayer>` | seen-store lookup, case-insensitive; `none` if never seen. Instant, sync-safe |
| `offline_player_uuid(uuid)` | `OfflinePlayer` | total — builds the identity; name from the store, else `"unknown"` |
| `fetch_offline_player(name)` | `optional<OfflinePlayer>` | **async only** — Mojang username→UUID lookup; a hit also seeds the seen-store |
| `all_seen_players()` | `list<OfflinePlayer>` | every player on record |

`offline_player` answers instantly from the local seen-store and is safe on the tick
thread. `fetch_offline_player` reaches out to Mojang over the network, so it is
**async-only** — call it inside an `async` command or block:

```swoftlang
command "lookup" {
    arguments {
        who: String
    }
    execute async {
        set fetched to fetch_offline_player(args.who)
        if fetched exists {
            send "${fetched.name} = ${fetched.uuid}" to sender
        } else {
            send "no Mojang account named ${args.who}" to sender
        }
    }
}
```

## Persistent data for anyone

[Persistent variables](/guide/persistence) can be keyed by `Player` or by
`OfflinePlayer` — and because both key by the same UUID string, the two spellings are
interchangeable at the storage level. A value written through a `Player` subject reads
back through an `OfflinePlayer` subject with the same UUID, and vice versa. In practice
there is one rule: **player-keyed persistents accept either subject.**

```swoftlang
persistent balance for Player: Integer = 100
persistent visits for OfflinePlayer: Integer = 0

command "reward" {
    arguments {
        who: String
        amount: Integer
    }
    execute {
        set target to offline_player(args.who)
        if target exists {
            // 'balance' is declared 'for Player' but takes the OfflinePlayer subject
            set balance for target to balance for target + args.amount
            send "paid ${args.amount} to ${target.name}" to sender
            if target.player exists {
                send "<green>+${args.amount} coins!" to target.player
            }
        }
    }
}
```

This is the whole point: you can pay, ban, or credit a player who is offline right now,
and the moment they log in the same store is live for them.

## Coming from Skript

Skript leans on `%offline player%` and `uuid of` scattered through your code, with a
live-player fetch that may quietly fail. SwoftLang makes the offline record a real typed
value and the live crossing a checked `exists`:

<MappedCompare>
<MappedPair label="pay a player, online or not">
<template #skript>

```skript
# {balance::%uuid%} works offline; getting a live
# player to message them might return <none>
command /reward <offline player> <integer>:
    trigger:
        add arg-2 to {balance::%uuid of arg-1%}
        send "&7Paid %arg-2% to %arg-1%" to player
        arg-1 is online
        send "&a+%arg-2% coins!" to arg-1
```

</template>
<template #swoftlang>

```swoftlang
persistent balance for Player: Integer = 100

command "reward" {
    arguments {
        who: String
        amount: Integer
    }
    execute {
        set target to offline_player(args.who)
        if target exists {
            set balance for target to balance for target + args.amount
            send "<gray>Paid ${args.amount} to ${target.name}" to sender
            if target.player exists {
                send "<green>+${args.amount} coins!" to target.player
            }
        }
    }
}
```

</template>
<template #note>

Skript's `%uuid of arg-1%` becomes automatic — the persistent is keyed by UUID, and the
same `balance` accepts the `OfflinePlayer` subject even though it's declared
`for Player`. The dodgy `arg-1 is online` / message-arg-1 dance becomes
`target.player exists`: a typed `optional<Player>` that the checker forces you to unwrap
before you can send to it.

</template>
</MappedPair>
<MappedPair label="who has ever joined?">
<template #skript>

```skript
# Skript has no first-class "everyone seen" list;
# you maintain {seen::*} yourself on join
on join:
    add player to {seen::*}
```

</template>
<template #swoftlang>

```swoftlang
command "census" {
    execute {
        loop all_seen_players() as p {
            send "${p.name} <gray>last seen ${p.last_seen}</gray>" to sender
        }
    }
}
```

</template>
<template #note>

The seen-store is maintained for you: `all_seen_players()` walks everyone the server has
ever recorded, each a full `OfflinePlayer` with name and timestamps — no bookkeeping list
to grow and prune by hand.

</template>
</MappedPair>
</MappedCompare>

## How the seen-store works

The seen-store rides whatever [storage backend](/guide/persistence#the-storage-block) you
configured — the same write-behind cache as your persistent variables. It records name,
`first_seen`, and `last_seen` per UUID, updated when a player joins and when they
disconnect, and it survives a backend switch like any other persistent data. Every
`offline_player(...)` and `all_seen_players()` call reads it in memory, so lookups never
touch disk on the tick thread.
