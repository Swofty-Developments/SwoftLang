---
title: Ship It
---

<StepHeader>
a production <code>server.sw</code> — auth, MOTD, permissions, a loaded world, an HTTP endpoint, and a scheduled announcer.
</StepHeader>

Thirteen steps of scripts; one step of server. Everything that turns your scripts folder
into a shippable server lives in script files too — a `server { }` block for boot
configuration, world statements for the map, `api` declarations for HTTP, and `every`
blocks for schedules. Same compiler, same checks.

## The `server` block

At most one across all your scripts (a duplicate is a compile error):

```swoftlang
server {
    auth: offline
    host: "0.0.0.0"
    port: 25565
    brand: "SwoftLang"
    motd: "<green>A SwoftLang server"
    favicon: "server-icon.png"
}
```

Every field is optional — an empty block (or none at all) boots an offline-mode server
on `0.0.0.0:25565`. `motd` takes MiniMessage; `favicon` is a path to a 64×64 PNG,
embedded at boot.

### Auth

`auth` picks how players are verified:

| Mode | Written | Use it when |
|---|---|---|
| `offline` | `auth: offline` | local dev; no verification (the default) |
| `mojang` | `auth: mojang` | standalone public server — full account verification |
| `velocity` | `auth: velocity "secret"` | behind a Velocity proxy (modern forwarding) |
| `bungeecord` | `auth: bungeecord` | behind BungeeCord |

```swoftlang
server {
    auth: velocity "kQ8mZ2vX9pL4"
    host: "127.0.0.1"
    port: 25566
}
```

Behind a proxy you bind to localhost and let the proxy face the internet — the secret
must match your `velocity.toml`.

### Permissions

Back in [Step 02](/1.9.0/guide/commands#permission-and-description) you gated commands with
`permission:`. Grants live here — a name-to-nodes map consumed by the default
permission provider:

```swoftlang
server {
    auth: mojang

    permissions {
        "Swofty": ["myserver.admin", "myserver.heal", "myserver.give"]
        "Notch": ["myserver.heal"]
    }
}
```

Anyone not listed lacks the node and gets the refusal message. The permission provider is
replaceable for real deployments; the block above is the built-in default.

## Worlds

Worlds load through **loaders** — values describing where world data lives:

- `anvil_loader("worlds/")` — the vanilla region format; drop in any world folder.
- `polar_loader("worlds/")` — a compact single-file format, fast to load and clone.
- `polar_storage_loader(<backend>)` — polar bytes in a
  [Step 10 storage backend](/1.9.0/guide/persistence#the-storage-block), keyed by world name.

```swoftlang
command "arena-setup" {
    permission: "myserver.admin"

    execute {
        set loader to anvil_loader("worlds/")

        if world_exists("arena", loader) {
            load world "arena" with loader
        } else {
            create world "arena" with loader
        }

        set w to world("arena")
        if w exists {
            set w.time to 6000
            teleport sender to location(0.5, 65.0, 0.5)
        }
    }
}

command "arena-reset" {
    permission: "myserver.admin"

    execute {
        unload world "arena" teleporting players to location(0.5, 65.0, 0.5)
        send "<green>Arena unloaded; players rescued to spawn." to sender
    }
}
```

The full statement set: `create world`, `load world`, `save world`,
`unload world <name> [without saving] [teleporting players to <loc>]`,
`clone world "a" to "b" with <loader>`, `delete world`, plus the `world_exists(name,
loader)` and `all_worlds(loader)` builtins. A loaded world resolves via `world(name)`
— an `Optional<World>`, as always.

## Schedulers

Skript's `every 5 minutes:` exists here too — as a top-level declaration that starts at
boot, with a body that is async-colored (it may `wait`):

<MappedCompare>
<MappedPair label="a repeating announcer">
<template #skript>

```skript
every 5 minutes:
    broadcast "&7Remember to vote!"
```

</template>
<template #swoftlang>

```swoftlang
every 300 seconds {
    broadcast "<gray>Remember to vote!"
}
```

</template>
<template #note>

Durations are `ticks`, `seconds`, or `millis` — no minutes unit, so five minutes is
`300 seconds`. The body runs as a background task on the tick-aligned clock from
[Step 09](/1.9.0/guide/async): a slow body can't stall the game, and every scheduled task is
cancelled cleanly on reload.

</template>
</MappedPair>
</MappedCompare>

For dynamic schedules, `schedule` is an *expression* returning a handle you can cancel:

```swoftlang
command "event-start" {
    permission: "myserver.admin"

    execute {
        set job to schedule after 10 seconds every 60 seconds {
            broadcast "<gold>The event is live — /warp event"
        }
        cancel schedule job
    }
}
```

## The HTTP API

Declare endpoints and your server speaks HTTP — handy for dashboards, vote listeners,
and status pages. Enable the listener in `server { }`, then declare `api` blocks:

```swoftlang
server {
    http {
        port: 8080
        bind: "127.0.0.1"
    }
}

api "/stats/:name" {
    method: GET
    execute async {
        set p to player(request.params.name)
        if p exists {
            reply with "online, ping ${p.latency}ms"
        } else {
            reply code 404 with "offline"
        }
    }
}
```

`:segments` in the path become `request.params.*`; `request` also carries `method`,
`path`, `query`, and `body`. `reply [code N] with <string>` sends the response — the
checker only allows it inside `api` bodies. Handlers are async-colored (they run off
the game thread), so the [Step 09](/1.9.0/guide/async) rules apply unchanged: property writes
hop to the tick thread by themselves, and that `player(...)` lookup is the same
`Optional<Player>` it always was.

## A dynamic MOTD

The [`Server`](/1.9.0/reference/events#server) receiver's `on_list_ping` method fires on every
server-list ping, with a writable `status` line — the MOTD players see in their server
list:

```swoftlang
Server {
    on_list_ping {
        set status to "<green>${length(all_players())} adventurers online"
    }
}
```

## The payoff: `server.sw`

Everything above, as one shippable file:

```swoftlang
server {
    auth: mojang
    host: "0.0.0.0"
    port: 25565
    brand: "SwoftLang"
    motd: "<green>A SwoftLang server"
    favicon: "server-icon.png"

    http {
        port: 8080
        bind: "127.0.0.1"
    }

    permissions {
        "Swofty": ["myserver.admin"]
    }
}

Server {
    on_list_ping {
        set status to "<green>${length(all_players())} adventurers online"
    }
}

every 300 seconds {
    broadcast "<gray>Remember to vote! <yellow>/vote"
}

api "/health" {
    method: GET
    execute async {
        reply with "ok, ${length(all_players())} online"
    }
}
```

```bash
$ swoftc check scripts/*.sw --addon-path addons
$ ./gradlew :java:run
```

Fourteen steps ago that check command had nothing to say. Now it's proving optionals,
property chains, thread colors, GUI slot ranges, module boundaries, and this server
block — before a single player connects. Keep the
[syntax cheatsheet](/1.9.0/reference/syntax-cheatsheet) open, raid the
[examples](/1.9.0/examples/) for full ported plugins, and go ship something.
