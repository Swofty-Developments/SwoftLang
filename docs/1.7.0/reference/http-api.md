# HTTP API

Give your server a REST surface in two blocks: enable `http` in the
[server config](./server-config), then declare `api` routes at the top level. Web
dashboards, vote listeners, Discord-bot bridges — no plugin, no servlet container,
no dependency (the runtime uses the JDK's built-in HTTP server on virtual threads).

```swoftlang
server {
    http {
        port: 8080
        bind: "127.0.0.1"
    }
}

api "/status" {
    method: GET
    execute {
        reply with "online=${length(all_players())} tps=${server.tps}"
    }
}
```

```
$ curl http://127.0.0.1:8080/status
online=7 tps=20.0
```

## The `http` block

| Key | Default | Meaning |
|---|---|---|
| `port:` | `8080` | listen port |
| `bind:` | `"0.0.0.0"` | bind address |

No `http` block, no listener — declaring `api` routes without one is pointless but
harmless.

::: warning Bind to localhost unless you mean it
There is no authentication layer. Bind to `127.0.0.1` and put a reverse proxy in
front, or treat every route as public.
:::

## `api` routes

`api "/path" { ... }` declares one route. Path segments starting with `:` are
parameters, readable as `request.params.<name>`:

```swoftlang
item CarePackage {
    material: "CHEST"
    name: "Care Package"
    rarity: common
}

api "/give/:player" {
    method: POST
    execute {
        set target to player(request.params.player)
        if target exists {
            give item "care_package" to target
            reply with "delivered"
        } else {
            reply code 404 with "player offline"
        }
    }
}
```

| Key | Values | Meaning |
|---|---|---|
| `method:` | `GET`, `POST`, `PUT`, `DELETE`, `ANY` | matched method (`ANY` matches all) |
| `execute { ... }` | statements | the handler |

Both the path shape and the method are compile-checked:

```
e_apipath.sw:1:1: error: api path "stats" must start with '/'
```

```
e_apimethod.sw:2:13: error: unknown http method 'FETCH'; valid methods: GET, POST, PUT, DELETE, ANY
```

## The `request` value

Bound inside every handler, read-only:

| Property | Type | Meaning |
|---|---|---|
| `method` | `String` | `GET`, `POST`, … |
| `path` | `String` | the matched path as requested |
| `query` | `String` | raw query string (`a=1&b=2`), empty if none |
| `body` | `String` | request body (empty for bodyless methods) |
| `params` | namespace | `request.params.<name>` — one `String` per `:param` |

## `reply`

`reply [code <n>] with <string>` — status defaults to 200. `reply` records the
response; it is flushed to the client **when the handler finishes**. A handler that
never replies answers 204; a handler that throws answers 500. `reply` exists only
inside `api` handlers:

```
e_reply.sw:3:9: error: 'reply' is only allowed inside an 'api' handler
```

## Handlers are async

API handlers run **async-colored by default** — each request is its own virtual
thread, so `wait`, `prompt_input`-style blocking builtins, and direct async calls are
all legal without writing `execute async`. Game-state reads and writes are
tick-dispatched for you, exactly like any other async code:

```swoftlang
api "/countdown/:player" {
    method: POST
    execute {
        set target to player(request.params.player)
        if target exists {
            loop 3 times as i {
                send "<yellow>${4 - i}..." to target
                wait 1 seconds
            }
            send "<lime>Go!" to target
            reply with "done"
        } else {
            reply code 404 with "player offline"
        }
    }
}
```

Because the response flushes when the handler *finishes*, the HTTP client waits out
every `wait` in the body — the countdown above holds the connection for three
seconds. To answer fast and keep working, `reply` first and push the slow part into
a detached `async { }` block:

```swoftlang
api "/restart-countdown" {
    method: POST
    execute {
        reply with "countdown started"
        async {
            loop 3 times as i {
                broadcast "<red>Restarting in ${4 - i}..."
                wait 1 seconds
            }
        }
    }
}
```

::: tip JSON in, JSON out
`request.body` and `reply` speak strings — build JSON with interpolation for now.
If a route family outgrows that, wrap the string-building in a
[library of your own](/1.7.0/libraries/writing-an-addon).
:::
