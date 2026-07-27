# Server Config

SwoftLang scripts don't just run *on* a server — they can *be* the server. A `server`
block configures how the embedded Minestom server boots: authentication, bind address,
branding, the HTTP listener, permissions, and LAN discovery. No YAML, no properties
files.

```swoftlang
server {
    auth: offline
    host: "0.0.0.0"
    port: 25565
    brand: "SwoftLang"
    motd: "<green>A SwoftLang server"
    favicon: "server-icon.png"
    open_to_lan: false

    http {
        port: 8080
        bind: "127.0.0.1"
    }

    permissions {
        "Swofty": ["swoftlang.admin", "swoftlang.teleport"]
        "Notch": ["swoftlang.teleport"]
    }
}
```

## Keys

| Key | Type | Default | Meaning |
|---|---|---|---|
| `auth:` | mode | `offline` | authentication mode — see below |
| `host:` | String | `"0.0.0.0"` | bind address |
| `port:` | integer | `25565` | bind port, 1–65535 (checked at compile time) |
| `brand:` | String | none | the brand string clients see (F3 screen) |
| `motd:` | String | none | server-list MOTD (MiniMessage ok) |
| `favicon:` | String | none | path to a 64×64 PNG, base64'd at boot for the server list |
| `open_to_lan:` | boolean | `false` | announce the server on the local network |
| `lighting:` | boolean | `true` | compute and send block/sky light — see [lighting](#lighting) |
| `http { ... }` | block | off | REST listener — see the [HTTP API reference](./http-api) |
| `permissions { ... }` | block | `{}` | default permission grants — see [permissions](#permissions) |

All keys are optional — `server {}` is a valid offline server on the default port.

## Auth modes

| Mode | Written | Boot behavior |
|---|---|---|
| Offline | `auth: offline` | no authentication (default) |
| Mojang | `auth: mojang` | online-mode encryption + session validation (`MojangAuth.init()`) |
| Velocity | `auth: velocity "forwarding-secret"` | modern forwarding from a Velocity proxy (`VelocityProxy.enable(secret)`) |
| BungeeCord | `auth: bungeecord` | legacy ip-forwarding from BungeeCord (`BungeeCordProxy.enable()`) |

```swoftlang
server {
    auth: velocity "hunter2-forwarding-secret"
    port: 25566
}
```

::: warning Proxy modes trust the proxy
`velocity` and `bungeecord` disable direct authentication — the proxy vouches for
players. Never expose a proxy-mode server's port to the public internet; keep it
reachable only from the proxy.
:::

## Permissions {#permissions}

Command `permission:` keys and [`has_permission(...)`](./builtins#has-permission)
both ask the runtime's permission provider. The default provider reads the
`permissions { }` map — usernames to permission lists:

```swoftlang
server {
    permissions {
        "Swofty": ["swoftlang.admin", "swoftlang.teleport"]
    }
}

command "sudo" {
    permission: "swoftlang.admin"
    execute {
        send "<red>with great power..." to sender
    }
}
```

The provider is a pluggable interface on the Java side — a host server embedding
SwoftLang can replace it with its own rank system, and the `permissions { }` block
stops mattering. With neither a block nor a custom provider, everything is
allowed (and logged).

## Dynamic MOTD {#motd}

The `motd:` key is the static server-list text. Two runtime surfaces make it dynamic:

| Form | Effect |
|---|---|
| `set server motd to <string>` | statement — change the MOTD from any handler |
| `server.motd` | read/write property, same thing as an lvalue |
| `Server { on_list_ping }` | per-ping rewrite of the status line |

`Server.on_list_ping` fires for each server-list ping, with a writable `status` line —
a dynamic MOTD, computed per ping:

```swoftlang
Server {
    on_list_ping {
        set status to "<green>${length(all_players())} heroes online right now"
    }
}
```

## Lighting {#lighting}

`lighting:` toggles the engine's light engine — the per-chunk sky- and block-light
computation the server runs and ships to clients. It defaults to `true`. Setting it
`false` skips that work entirely, which trims CPU on servers that don't need accurate
shadows (minigame lobbies, fully-lit builds):

```swoftlang
server {
    auth: offline
    motd: "<green>No lighting"
    lighting: false
}
```

It must be a `true`/`false` literal — anything else is a parse error:

```
bad_lighting.sw:3:5: error: Expected 'true' or 'false' after 'lighting:', found identifier 'maybe'
```

The key is additive in the JSON AST: it is emitted only when set to `false`, so a
script that never touches lighting produces byte-identical output.

## One block per server

At most one `server` block is allowed. Two in the same file is a compile error:

```
e_dupserver.sw:4:1: error: duplicate 'server' block; only one server block is allowed per script
```

Across multiple script files the check moves to load time: the first `server` block
wins and extras are reported and ignored.

## Boot order

At startup the engine:

1. Compiles/loads every script (via `swoftc` or [sidecars](./cli#sidecars)),
   resolving [imports](/1.9.0/libraries/) as it goes.
2. Reads the single `server` block (or defaults).
3. `MinecraftServer.init()`, applies the auth mode, sets the brand, reads the
   favicon, then `start(host, port)` — and starts the HTTP listener if configured.

Commands, events, GUIs, scoreboards, tablists, items, mobs, api routes, and
schedulers from all loaded scripts (and their imported addons) are registered before
the first player can connect.

## JSON shape

The block compiles to the top-level `"server"` key of the
[JSON AST](./json-ast#server) — `null` when no script declares one:

```json
{
  "auth": { "kind": "offline", "secret": null },
  "host": "0.0.0.0",
  "port": 25565,
  "brand": "SwoftLang",
  "motd": "<green>A SwoftLang server",
  "http": { "port": 8080, "bind": "127.0.0.1" },
  "favicon": "server-icon.png",
  "permissions": { "Swofty": ["swoftlang.admin"] }
}
```

`auth.kind` is one of `offline`, `mojang`, `velocity` (with `secret`), `bungeecord`.
The phase-6 keys (`http`, `favicon`, `permissions`, `open_to_lan`) are additive and
only present when used — older scripts emit byte-identical JSON.

## Storage {#storage-phase-3}

`storage` is the `server`-block sibling for [persistent variables](/1.9.0/guide/persistence):
at most one per server, configuring where `persistent` declarations live and how often
dirty values flush.

```swoftlang
storage {
  backend: files "data/swoftlang"
  flush: every 30 seconds
}
```

Backends:

| Backend | Written | Storage |
|---|---|---|
| Files (default) | `backend: files "data/swoftlang"` | one JSON file per variable, atomic tmp+move writes |
| SQLite | `backend: sqlite "data/swoftlang.db"` | table `swoft_persist(var, key, value)` |
| MySQL | `backend: mysql { host: "localhost", port: 3306, database: "mc", user: "root", password: "..." }` | same schema |
| MongoDB | `backend: mongodb "mongodb://localhost:27017/swoftlang"` | collection `swoft_persist` |

With no `storage` block, persistence defaults to `files "swoftlang-data"`. Reads and
writes always hit an in-memory cache; a background task flushes dirty entries on the
`flush:` cadence (default 30 seconds) and on shutdown — script execution never blocks
on IO.

The same backend syntax also feeds
[`polar_storage_loader(...)`](./worlds#loaders), so whole worlds can live in the
database next to your variables.
