# Raw Packets

::: danger Sharp edge — you are talking to the protocol
`send packet` and the `Packet { }` receiver are SwoftLang's NMS escape hatch. Packet
**names and field shapes are resolved at runtime** against the pinned Minestom snapshot
(`minestom-snapshots:ebaa2bbf64`, 1.21.4) — the compiler checks only the statement
shape, so a typo in a packet name or field is a *runtime* error, and a Minestom
upgrade can rename fields under you. A malformed-but-constructible packet can
desync or disconnect clients. `Packet` handlers run on the connection's **read
thread**, not the tick thread. Prefer the first-class statements (displays, sounds,
particles, nametags…) whenever one exists — reach for packets when nothing else
does the job.
:::

The first-class [`npc`](/1.3.0/reference/npcs) construct's runtime is built entirely on this
surface — player-info packets, spawn packets, rotation packets, and one interact
listener — the same primitives this page documents, now assembled for you in Java.

## Sending packets

```swoftlang
Player {
    on_join {
        send packet "ParticlePacket" {
            particle: "minecraft:flame",
            overrideLimiter: false, longDistance: false,
            x: 100.5, y: 65.0, z: 20.5,
            offsetX: 0.5, offsetY: 0.5, offsetZ: 0.5,
            maxSpeed: 0.01, particleCount: 40
        } to player
    }
}
```

`send packet "<Name>" { field: expr, ... } to <player | list | all>`. The runtime
resolves `<Name>` as a short or fully-qualified class name under
`net.minestom.server.network.packet.server.**` and calls the record's **canonical
constructor**, coercing each field by the record component's type:

| Component type | What you write |
|---|---|
| numbers (`int`, `float`, `byte`…) | any Number expression |
| `String` / `Component` | String (Components parse MiniMessage) |
| `boolean` | Boolean |
| `UUID` | a UUID string |
| enums | the constant name as a string (`"ALWAYS"`, `"SURVIVAL"`) |
| `Point` / `Pos` | a `Location` value |
| nested records | a nested `{ field: expr, ... }` map |
| lists | `[ item, item, ... ]` — items may be nested maps |

Field names must match the record components exactly — Minestom's names, not the
wiki's (`ParticlePacket`'s count field is `particleCount`). On mismatch the runtime
error lists the components the record actually has.

Nested records and lists compose, which is enough to build a fake player from
scratch:

```swoftlang
command "ghost" {
    execute {
        send packet "PlayerInfoUpdatePacket" {
            actions: ["ADD_PLAYER", "UPDATE_LISTED"],
            entries: [{
                uuid: "a0000000-0000-4000-8000-000000770000",
                username: "Ghost",
                properties: [],
                listed: true,
                latency: 0,
                gameMode: "SURVIVAL",
                displayName: none,
                chatSession: none,
                listOrder: 0
            }]
        } to sender
        send packet "SpawnEntityPacket" {
            entityId: 770000,
            uuid: "a0000000-0000-4000-8000-000000770000",
            type: 147,
            position: sender.location,
            headRot: 0.0,
            data: 0,
            velocityX: 0, velocityY: 0, velocityZ: 0
        } to sender
    }
}
```

## Listening for packets

The `Packet { }` receiver hooks **inbound** client packet classes by name. Each member
is an `on "<ClientPacketName>" { ... }` handler; `player` (the sender) and `packet` are
bound, fields of the packet are readable as `packet.<component>` (read-only), and
`cancel packet` swallows it before default handling:

```swoftlang
Packet {
    on "ClientPlayerActionPacket" {
        if packet.status is "START_DIGGING" {
            send "<red>No mining in the lobby." to player
            cancel packet
        }
    }
}
```

One `Packet { }` block can hold as many `on "..."` handlers as you like. `cancel packet`
outside a `Packet` handler is a compile error:

```
e_cancelpkt.sw:3:9: error: 'cancel packet' is only allowed inside a Packet handler
```

### The packet color

`Packet` handler bodies are a restricted sync color of their own. They run on the
connection's read thread — before the packet reaches the tick loop — so blocking is
banned harder than in normal sync code:

- `wait` and `spawn` are rejected; `async { }` is the one way to detach work.
- `cancel packet` must run before the handler goes async — you can't decide to
  swallow a packet after it has already been processed.

```
e_pktwait.sw:3:9: error: 'wait' is not allowed inside Packet handlers; wrap the work in an 'async { }' block
```

Keep handler bodies short: read fields, decide, cancel or not, and push anything
slow into `async { }`:

```swoftlang
Packet {
    on "ClientInteractEntityPacket" {
        set target to packet.target_id
        async {
            // off the read thread: log, look things up, message people
            broadcast "<gray>someone poked entity ${target}"
        }
    }
}
```

## Packet-field stringification

`"${packet.type}"` interpolates the field's Java `toString()` — handy for
dispatching on union-shaped packets. The pinned snapshot's
`ClientInteractEntityPacket.type` stringifies as `Attack[]`,
`Interact[hand=MAIN]`, or `InteractAt[...]` — which is exactly how the
[`npc`](/1.3.0/reference/npcs) runtime tells left clicks from right clicks.

## When packets are the right tool

| Job | Reach for |
|---|---|
| floating text, 3D markers | [displays](./displays) — first-class |
| sounds, particles | [`play sound` / `spawn particle`](./maps-toasts-skins-tps#sounds) — first-class |
| per-viewer name changes | [nametags](./nametags) — first-class |
| fake players / NPCs | the [`npc`](/1.3.0/reference/npcs) construct — first-class — or packets directly |
| client-side-only entities, custom equipment illusions, protocol tricks Minestom has no API for | packets — this page |
