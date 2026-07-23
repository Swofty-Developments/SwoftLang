---
title: Offline Players
---

<StepHeader>
a <code>/whois</code> that looks up anyone the server has ever seen — online or not — and messages them if they happen to be on.
</StepHeader>

So far "a player" has meant someone connected right now. But servers remember people:
balances, bans, and stats belong to accounts that are usually offline. SwoftLang models
that directly. An `OfflinePlayer` is any account the server has seen — and because every
online `Player` *is* an `OfflinePlayer`, the two worlds share one type, with a checked
bridge between them.

## The seen-store

Every join and quit is recorded in a **seen-store** that rides your
[storage backend](/1.7.0/guide/persistence#the-storage-block). You query it with
`offline_player(name)` — an instant, tick-safe lookup that returns an
`Optional<OfflinePlayer>`, `none` if the server has never seen that name:

```swoftlang
set found to offline_player("Notch")
if found exists {
    send "<gold>${found.name}</gold> — last seen ${found.last_seen}" to sender
} else {
    send "never seen anyone by that name" to sender
}
```

An `OfflinePlayer` carries `name`, `uuid`, `first_seen`, `last_seen`,
`has_played_before`, `online`, and — the important one — `player`.

## The bridge back to a live player

`found.player` is an `Optional<Player>`: the live `Player` when they're connected, `none`
when they're not. That single property is the crossing between offline records and live
players, and because it's an `optional`, the checker makes you handle the "not online"
case before you can message them:

```swoftlang
set found to offline_player("Notch")
if found exists {
    if found.player exists {
        // inside this guard, found.player is a real Player
        send "<green>Someone just looked you up!" to found.player
    }
}
```

No null player, no "is online" flag you might forget to check — the type is the check.

## Player is an OfflinePlayer

Since `Player <: OfflinePlayer`, anything that accepts an `OfflinePlayer` accepts a live
player too, and `is a Player` narrows the other way:

```swoftlang
function describe(subject: OfflinePlayer) {
    if subject is a Player {
        send "you are online right now" to subject
    }
}
```

## Paying someone who's offline

The payoff: persistent data keyed by player works whether or not the target is connected,
because [persistents](/1.7.0/guide/persistence) are keyed by UUID and accept either an
`OfflinePlayer` or a `Player` subject. You can credit an offline account and, if they
happen to be online, ping them in the same breath:

<!-- swoftc name=whois.sw -->

```swoftlang
persistent balance for Player: Integer = 0

command "whois" {
    description: "Look up anyone this server has ever seen"
    arguments {
        who: String
    }
    execute {
        set found to offline_player(args.who)
        if found exists {
            send "<gold>${found.name}</gold> <gray>(${found.uuid})</gray>" to sender
            send "first seen ${found.first_seen}, last seen ${found.last_seen}" to sender
            send "balance: ${balance for found}" to sender
            if found.player exists {
                send "<green>${sender} looked you up!" to found.player
            }
        } else {
            send "never seen anyone called ${args.who}" to sender
        }
    }
}
```

`balance for found` reads the store with the `OfflinePlayer` subject; had a `Player`
written it earlier, the UUID key makes them the same entry.

## Reaching past the seen-store

For an account the server has never seen locally, `fetch_offline_player(name)` asks
Mojang directly. It hits the network, so it's **async-only** — the compiler enforces it,
and a successful lookup seeds the seen-store for next time:

```swoftlang
command "resolve" {
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

That's the full picture: [`offline_player`](/1.7.0/reference/offline-players#builtins) for the
local store, `fetch_offline_player` for the wider world, `all_seen_players()` to walk
everyone on record, and the `player` bridge to cross back to a live session — all typed,
all null-free. The [reference page](/1.7.0/reference/offline-players) has the complete property
and builtin tables.
