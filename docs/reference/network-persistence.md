# Network Persistence

[Persistence](/guide/persistence) as taught in the guide assumes one server: one process owns
the cache, one flusher writes it out, and nobody else touches the backend. Put that same script
behind a proxy — a lobby, two survival shards, a minigame node, all sharing one database — and
the write-behind cache becomes a liability. Two servers hold the same player's coins, both think
they're authoritative, and the last flush wins.

`mode: network` fixes that. The headline property is what it *doesn't* change:

::: tip The one-line summary
**Topology is configuration, not a keyword.** No `persistent` declaration and no line of game
code changes between a single server and a fifteen-server network. You flip one field in the
`storage` block.
:::

## Topology is config, not a keyword {#topology}

Here is a complete script, twice. The declarations are identical. The `Player { }` block is
identical. Only the `storage` block differs — and under `mode: network` the runtime silently
grows session leases, replicated globals, and cross-server broadcast underneath it.

::: code-group

```swoftlang [standalone]
storage {
    backend: files "data/game"
    flush: every 10 seconds
}

persistent pot: Integer = 0
persistent coins for Player: Integer = 0
persistent leaderboard: Map<String, Integer> = new_map()

Player {
    on_join {
        set coins for player to (coins for player) + 10
        add 50 to pot
        set leaderboard at player.name to coins for player
        send "<gold>${coins for player} coins — the pot is at ${pot}" to player
    }
}
```

```swoftlang [network]
storage {
    backend: mysql { host: "10.0.0.5", database: "net", user: "mc", password: "hunter2" }
    mode: network
    flush: every 30 seconds
    on_handoff_failure: kick "Loading your data — reconnect in a moment"
    coordinator: redis "redis://10.0.0.6"
}

persistent pot: Integer = 0
persistent coins for Player: Integer = 0
persistent leaderboard: Map<String, Integer> = new_map()

Player {
    on_join {
        set coins for player to (coins for player) + 10
        add 50 to pot
        set leaderboard at player.name to coins for player
        send "<gold>${coins for player} coins — the pot is at ${pot}" to player
    }
}
```

:::

Everything below the `storage` block is byte-for-byte the same text. That is deliberate and it
is the whole point of the design: **develop standalone, flip to network, deploy.** There is no
`@replicated` annotation to sprinkle, no per-variable `network` keyword, no second dialect of
the language for clustered servers.

### The `storage` block, in full

| Field | Values | Meaning |
|---|---|---|
| `backend:` | `files` / `sqlite` / `mysql` / `mongodb` | where bytes land (see [Backends](/guide/persistence#backends)) |
| `mode:` | `standalone` (default) \| `network` | the topology |
| `flush:` | `every <duration>` | write-behind cadence — under `network`, a **crash checkpoint only** |
| `on_handoff_failure:` | `kick "<message>"` | what to do when a lease can't be acquired (default: kick) |
| `coordinator:` | `redis "<uri>"` | optional pub-sub + lease store; defaults to the backend itself |

`mode: standalone` behaves exactly as it always has — same cache, same flusher, same emitted
sidecars. Adding the field changes nothing for a single server.

## The desync it fixes {#desync}

The bug is not hypothetical, and it is not a race you can code around in script. It is what
write-behind plus a proxy *is*:

```txt
A: coins for Steve = 100 in cache
   Steve earns 50            -> A's cache = 150   (dirty, not yet flushed)
   proxy moves Steve A -> B
B: on_join loads coins       -> reads 100 from the backend   <- STALE
   Steve earns 50            -> B's cache = 150
A: flush timer fires         -> writes 100 over the backend  <- CLOBBER
```

Two independent faults, and each one alone is enough to lose data:

1. **Unflushed value.** B read the backend before A's dirty entry reached it. Tightening
   `flush:` narrows this window but never closes it — there is always a `flush interval`-sized
   hole between the last write and the transfer.
2. **Handoff clobber.** A kept the player's entry in memory *after they left*, and the flusher
   dutifully wrote it back on top of B's newer value. This one is not even a race: it is
   guaranteed, and a shorter flush interval makes it fire *sooner*.

### Session ownership

Under `mode: network`, a `for Player` value is **session-owned**: at any instant exactly one
server owns a given player's entry, so two concurrent writers never exist and the interleaving
above is unrepresentable.

1. **Acquire + load on join.** Before any `on_join` handler runs, the joining server acquires
   the player's lease and loads their current values. By the time your code runs the data is
   present — `on_join` may read it as a plain synchronous value.
2. **Flush + evict + release on quit or transfer.** On the way out the server flushes that
   player's dirty entries *synchronously*, then **drops them from memory**, then releases the
   lease. Eviction is the half that kills fault 2: A has nothing left to clobber with, because A
   no longer holds a copy.
3. **Handoff barrier.** B cannot acquire until A has released (default acquire wait: 5s). So
   "B loads" is ordered strictly after "A flushed", which kills fault 1.
4. **Lease TTL.** A lease lives 30s and is renewed by its holder. If A crashes it stops
   renewing, the lease lapses, and the player is never stranded on a dead server.
5. **Monotonic generation.** Every successful acquire returns a strictly greater generation
   stamp. A write arriving with an older generation is a late writer that already lost the
   handoff, and it is **rejected**, not applied.
6. **Handoff failure.** If the backend is down or a lease is stuck past the timeout, the
   `on_handoff_failure:` policy applies — by default the player is kicked with your message. The
   runtime will never invent defaults or serve a second copy of live data.

::: warning `flush:` is demoted
Under `mode: standalone`, `flush:` is your durability knob. Under `mode: network` it is **not
part of the handoff path at all** — the handoff flushes synchronously regardless of the timer.
`flush:` survives only as a *crash checkpoint*: a hard `kill -9` loses at most one interval of
writes for players still online. `every 30 seconds` is a sensible network value; tuning it down
no longer buys you correctness across servers, because ownership already did.
:::

## What each declaration becomes {#decl-shape}

There is no keyword to choose a strategy — the **shape of the declaration** picks it, and it
picks the only strategy that could be correct for that shape.

| Declaration | Owner | Under `mode: network` |
|---|---|---|
| `X for Player`, `X for OfflinePlayer` | the server the player is on | **session-owned** — sync read/write, load-on-join, flush-evict-release-on-leave |
| `X` (no `for`) | nobody | **replicated** — local replica, sync reads, atomic broadcast writes |
| `X for String`, `X for Integer` | nobody | **replicated**, keyed — same as above, one row per key |

```swoftlang
storage {
    backend: mysql { host: "10.0.0.5", database: "net", user: "mc", password: "hunter2" }
    mode: network
}

// session-owned: one server owns each player's row at a time
persistent coins for Player: Integer = 0
persistent history for OfflinePlayer: List<String> = []

// replicated: every server holds a live copy
persistent pot: Integer = 0
persistent boss_active: Boolean = false
persistent leaderboard: Map<String, Integer> = new_map()
persistent scores for String: Integer = 0
persistent visits for Integer: Integer = 0
```

The intuition behind the split: a **player** is somewhere specific — the proxy knows exactly
which server they are on, so ownership is a fact you can look up and lease. A **global** is
nowhere in particular; every server needs it in front of them at all times, so it is replicated
and writes are made commutative instead of exclusive.

### The lifecycle difference

This is the part that surprises people, so it is worth stating flatly:

- **Globals load eagerly, once, at boot.** A server reads every global's current value during
  startup and then keeps it fresh by subscribing to change broadcasts. There is no lazy first
  read — `pot` is correct from the first tick.
- **Per-player values load lazily, per join, and are evicted per leave.** Nothing about a
  player is in memory before they connect to *this* server, and nothing remains after they
  leave it. A server with 40 players holds 40 rows, not the whole table.

So a global's cost scales with the number of *declarations*, and a session value's cost scales
with the number of *players on this node* — which is exactly the scaling you want when you add
a sixteenth server.

## Reads {#reads}

**A value you own reads synchronously.** A live `Player` is by definition connected to this
server, so `coins for player` is a cache hit and behaves identically in both modes. A global
reads from the local replica, also synchronously, also in both modes.

**A value you may not own is a `Future<T>`.** An `OfflinePlayer` might be on another node
entirely, so under `mode: network` reading through one is an IO snapshot: it types as
[`Future<T>`](/reference/futures) and must be `await`ed inside an [`async` block](/guide/async).

```swoftlang
storage {
    backend: mysql { host: "10.0.0.5", database: "net", user: "mc", password: "hunter2" }
    mode: network
}

persistent coins for Player: Integer = 0

command "balance" {
    description: "Your own balance — you're on this server, so this is sync"
    execute {
        if sender is a Player {
            send "<gold>${coins for sender} coins" to sender
        }
    }
}

function peek(who: OfflinePlayer, viewer: Player) {
    async {
        // 'who' may be on another node: the read is a Future<Integer>
        set bal to await coins for who
        send "<gray>they have ${bal} coins" to viewer
    }
}
```

Forget the `await` and the checker says so, naming the type it handed you:

<!-- swoftc name=remote.sw expect=error -->

```swoftlang
storage {
    backend: mysql { host: "db", database: "net", user: "mc", password: "p" }
    mode: network
}

persistent coins for Player: Integer = 0

function report(who: OfflinePlayer) {
    async {
        set bal to coins for who   // [!code error]
        broadcast "balance ${bal}"
    }
}
```

```txt
remote.sw:10:20: error: 'coins for <OfflinePlayer>' may read a player this server does not own — under 'mode: network' that read is a Future<Integer>; write 'await coins for <player>' inside an 'async { }' block
        set bal to coins for who
                   ^
```

Under `mode: standalone` that exact same expression is a plain synchronous read — one process
owns everything, so there is nothing to wait for. This is the compatibility hinge: existing
scripts keep compiling unchanged, and the moment you flip to `network` the compiler tells you
precisely which reads have become remote.

## Writes {#writes}

**A value you own is written normally.** Single writer, no contention, read-modify-write is
perfectly safe:

```swoftlang
storage {
    backend: mysql { host: "10.0.0.5", database: "net", user: "mc", password: "hunter2" }
    mode: network
}

persistent coins for Player: Integer = 0

Player {
    on_join {
        // 'player' is on THIS server, so this server owns the lease: fine
        set coins for player to (coins for player) + 10
    }
}
```

**Anything else is an atomic op.** For a player you may not own, or for a replicated global that
fifteen servers can write at once, the language only lets you express operations that *commute* —
so concurrent applications converge instead of losing updates.

```swoftlang
storage {
    backend: mongodb "mongodb://10.0.0.5:27017/net"
    mode: network
}

persistent pot: Integer = 0
persistent boss_active: Boolean = false
persistent announcements: List<String> = []
persistent leaderboard: Map<String, Integer> = new_map()
persistent coins for Player: Integer = 0
persistent history for OfflinePlayer: List<String> = []

function payout(who: OfflinePlayer) {
    // --- replicated globals ---
    add 50 to pot                                  // atomic increment
    subtract 5 from pot                            // atomic decrement
    append "a duel ended" to announcements         // atomic list append
    set leaderboard at "top" to 1                  // atomic per-key map write
    set boss_active to true                        // unconditional set: last-writer-wins

    // --- a player this server may not own ---
    grant 100 coins to who                         // routed atomic increment
    append "won-duel" to history for who           // routed atomic append
}
```

The 1.10.0 atomic set:

| Op | Applies to | Meaning |
|---|---|---|
| `add <n> to X` | `Integer` / `Double` | atomic increment |
| `subtract <n> from X` | `Integer` / `Double` | atomic decrement |
| `append <v> to X` | `List<T>` | atomic append |
| `set X at <k> to <v>` | `Map<K, V>` | atomic per-key put |
| `set X to <v>` | any scalar | unconditional set, last-writer-wins |
| `grant <n> X to <player>` | player-keyed `Integer` / `Double` | routed atomic increment |

Compare-and-set, multi-value transactions, and strongly-consistent single-owner globals are
deliberately **not** in 1.10.0.

In `mode: standalone` every one of those spellings desugars to the plain local mutation it
looks like — `add 50 to pot` is `set pot to pot + 50`. They are not a "network dialect"; they
are the normal way to write these mutations, and network mode is simply the mode that *requires*
them.

### Error demo: assigning to a player you don't own

<!-- swoftc name=pay.sw expect=error -->

```swoftlang
storage {
    backend: mysql { host: "db", database: "net", user: "mc", password: "p" }
    mode: network
}

persistent coins for Player: Integer = 0

function pay(who: OfflinePlayer) {
    set coins for who to 100   // [!code error]
}
```

```txt
pay.sw:9:5: error: can't 'set coins for <OfflinePlayer>' — under 'mode: network' this server may not own that player, so the write would clobber the owner; use an atomic op instead ('grant <n> coins to <player>' or 'append <value> to coins for <player>')
    set coins for who to 100
    ^
```

An assignment says "the new value is 100 *regardless of what it is now*". If the owning server
has them at 340, that write destroys 240 coins. `grant 100 coins to who` says "add 100 to
whatever it is", which is true no matter who else is writing.

### Error demo: read-modify-write on a global

<!-- swoftc name=bet.sw expect=error -->

```swoftlang
storage {
    backend: mongodb "mongodb://db/net"
    mode: network
}

persistent pot: Integer = 0

command "bet" {
    execute {
        set pot to pot + 50   // [!code error]
    }
}
```

```txt
bet.sw:10:9: error: 'set pot to ...' reads 'pot' to compute its new value — that read-modify-write is racy across servers under 'mode: network' (two servers can both read the old value); use 'add <n> to pot' (or 'subtract <n> from pot') instead
        set pot to pot + 50
        ^
```

Classic lost update: two servers read `100`, both compute `150`, both store `150`, and one
player's 50 evaporates. The hint always names the atomic op for the *declared value type* — a
`List` gets pointed at `append`, a `Map` at `set X at <key> to <value>`.

Note the exemption baked into the rule: `set leaderboard at key to v` *does* read the map to
produce the updated one, but it is a per-key atomic op and is allowed. Only a genuine whole-value
read-modify-write is rejected.

## `mode: network` needs a shared backend {#shared-backend}

A network of servers has to coordinate somewhere: the lease table, the replica broadcast, and
the atomic ops all live in the backend (or in a `coordinator:`). A `files` or `sqlite` backend is
local to one process and cannot hold a lease anyone else can see, so pairing it with
`mode: network` is a compile error, not a runtime surprise on launch night.

<!-- swoftc name=game.sw expect=error -->

```swoftlang
storage {
    backend: files "data/game"   // [!code error]
    mode: network
    flush: every 30 seconds
}

persistent pot: Integer = 0
```

```txt
game.sw:1:1: error: 'mode: network' needs a shared backend: a files backend can't coordinate servers — use 'backend: mysql { ... }' or 'backend: mongodb "..."'
storage {
^
```

`backend: sqlite` fails the same way with `a sqlite backend can't coordinate servers`. The two
usable network backends are **`mysql`** and **`mongodb`**.

## Change events {#change-events}

A persistent declaration may carry a trailing block with exactly one change handler.
`on_change { }` reacts to a scalar; `on_entry_change { }` reacts to one entry of a `Map` or
`List`. The body is *bare context*, the same binding style [receivers](/reference/events) and
[reactive struct fields](/reference/structs#reactive) use.

```swoftlang
storage {
    backend: mysql { host: "10.0.0.5", database: "net", user: "mc", password: "hunter2" }
    mode: network
}

// a scalar global: binds old, new, caused_here
persistent boss_active: Boolean = false {
    on_change {
        if new {
            broadcast "<red>The world boss has awoken!"
        } else {
            broadcast "<gray>The boss is gone (was ${old})"
        }
    }
}

// per-player: the declaration's key binds as 'player'
persistent coins for Player: Integer = 0 {
    on_change {
        send "<gold>${old} -> ${new} coins" to player
    }
}

// keyed global: the declaration's key binds as 'key'
persistent scores for String: Integer = 0 {
    on_change {
        broadcast "<aqua>${key}: ${old} -> ${new}"
    }
}

// a collection reacts per ENTRY, with Optional old/new
persistent leaderboard: Map<String, Integer> = new_map() {
    on_entry_change {
        if old is missing {
            broadcast "<green>${key} joined the board at ${new otherwise 0}"
        } else if new is missing {
            broadcast "<gray>${key} fell off the board"
        } else {
            broadcast "<gold>${key} -> ${new otherwise 0}"
        }
    }
}
```

### Bound names

| Declaration | `on_change` binds | `on_entry_change` binds |
|---|---|---|
| `X` (global scalar) | `old`, `new`, `caused_here` | — |
| `X for Player` | `player`, `old`, `new`, `caused_here` | `player`, `key`, `old`, `new`, `caused_here` |
| `X for String` / `for Integer` | `key`, `old`, `new`, `caused_here` | `key`, `old`, `new`, `caused_here` |
| `X: Map<K, V>` / `List<T>` | *(error — use `on_entry_change`)* | `key`, `old: Optional<V>`, `new: Optional<V>`, `caused_here` |

Mixing them up is a compile error that names the right one: a `Map` with `on_change` is told to
use `on_entry_change`, and a scalar with `on_entry_change` is told the opposite.

### It fires on every server — *including* the writer

This is the semantic worth reading twice. When a change happens, the handler runs on **every
server in the network, the one that made the write included.**

That is not an accident of implementation; it is forced by what people put in these handlers.
Look at `boss_active` above: the body is a `broadcast`. If the handler fired only on servers
that *received* the change over the network, then the players standing on the server whose code
flipped the boss on would be the only players in the entire network who never got told. The
originating server has players too, and they need the message as much as anyone.

So the rule is: **one event, fired everywhere, with a flag telling you where you are.**

`caused_here: Boolean` is bound in every handler and is `true` exactly on the server that made
the write:

```swoftlang
storage {
    backend: mysql { host: "10.0.0.5", database: "net", user: "mc", password: "hunter2" }
    mode: network
}

persistent audit: List<String> = []

persistent pot: Integer = 0 {
    on_change {
        // everywhere: keep every server's players informed
        broadcast "<gold>Pot: ${new}"

        if caused_here {
            // exactly once, network-wide: the side effect that must not be duplicated
            append "pot ${old} -> ${new}" to audit
        }
    }
}

command "bet" {
    execute {
        add 50 to pot
    }
}
```

Use `if caused_here` for anything that must happen once network-wide (an audit log row, a
webhook, a Discord message). Use `if not caused_here` for "someone else did this" reactions. Use
neither — the common case — when the handler is idempotent per-server, like updating a
scoreboard or broadcasting to local players.

There is deliberately no separate `on_network_change`. One event plus a flag means you cannot
write a handler that silently behaves differently depending on which server it lands on.

### When it does *not* fire

- **No-ops don't fire.** The comparison is by value: `set boss_active to true` when it is
  already `true` fires nothing, and neither does `set x to x`. This is the first line of defence
  against cascades (below) and it costs nothing.
- **Loads and restores don't fire.** A player joining and their values loading is a *restore*,
  not a change. The boot-time replica load of every global is not a change either. If it were,
  every join would storm every handler with fabricated "changes" that no one made — a hundred
  logins would look like a hundred economy events.
- **Collections fire per entry, batched on bulk operations.** Clearing a 10,000-entry map fires
  per-entry removals up to a cap, then emits one summary log line instead of ten thousand
  handler invocations.

Handlers run on the tick thread, so the body is sync-coloured: an `await` or `wait` inside is
the usual colour error. Reach for `async { }` if you need to do IO in reaction to a change.

`on_change` works in `mode: standalone` too — it fires locally, and `caused_here` is always
`true`. Like everything else on this page, the declaration does not change between modes.

## Cascade guards {#cascade}

Change handlers can write persistent values, and written values fire change handlers. That is a
loop waiting to happen, and across a network it is a loop that can span machines. Four layers
keep it bounded.

### Layer 1 — no-op suppression

A change that isn't a change fires nothing. Converging cascades (a handler that writes a value
which settles) and trivial echoes die for free, before any of the machinery below gets involved.

### Layer 2 — static cycle detection (compile error)

At compile time the checker builds a directed graph: for every change handler, which persistent
values does its body write — following function calls *interprocedurally*, so a cycle hidden
behind a helper is still found. A handler that writes its own value at its own key is rejected:

<!-- swoftc name=econ.sw expect=error -->

```swoftlang
storage {
    backend: files "data/game"
}

persistent pot: Integer = 0 {
    on_change {
        set pot to new + 1   // [!code error]
    }
}
```

```txt
econ.sw:7:9: error: the 'on_change' for 'pot' writes 'pot', which would re-fire itself forever
        set pot to new + 1
        ^
```

...and so is a cycle across different values, with the path printed so you know which edge to
cut:

<!-- swoftc name=board.sw expect=error -->

```swoftlang
storage {
    backend: files "data/game"
}

persistent coins for Player: Integer = 0 {
    on_change {                                  // [!code error]
        set leaderboard at player.name to new
    }
}

persistent leaderboard: Map<String, Integer> = new_map() {
    on_entry_change {
        bump(key)
    }
}

function bump(name: String) {
    set found to player(name)
    if found exists {
        grant 1 coins to found
    }
}
```

```txt
board.sw:6:5: error: change handlers form a cycle: coins -> leaderboard -> coins
    on_change {
    ^
```

**The deliberate exception:** a handler writing the **same value at a different key** is
*allowed*. `coins`'s handler doing `grant 1 coins to party_leader` is a legitimate referral
bonus, not a self re-fire, and no static analysis can decide whether that key chain terminates.
Only same-value-same-key and cross-value cycles are compile errors; the different-key case is
handed to layer 3.

### Layer 3 — a propagating causality token

Here is the layer that exists specifically because of the network, and the reasoning is worth
spelling out.

**A per-server depth counter does not work.** Suppose each server counts how deep it is in a
handler chain and refuses to go past 8. Server A writes at depth 1, and broadcasts. Server B
receives that broadcast — but B was not in a handler when it arrived, so as far as B's counter
is concerned this is a brand-new change at **depth 0**. B's handler writes, and broadcasts. A
receives it at depth 0. The two servers ping-pong forever, and *neither one's counter ever
exceeds 1*. Local depth is not a property of the cascade; it is a property of one hop of it.

So **causality has to travel with the broadcast.** Every change carries a token:

```txt
{ chain_id, origin_server, depth, path }
```

Writes made *inside* a handler inherit the current chain at `depth + 1`, and the token is
serialized into the broadcast message. A cross-server cascade therefore keeps counting — B
receives the change already at depth 1, its handler's write is depth 2, and the ping-pong runs
out of budget instead of running forever.

Past the cap (default **8**, overridable with the `swoft.persist.cascade_depth` system property)
the write is **rejected and logged loudly** — never silently dropped, because a silently dropped
write is a data-loss bug that looks like nothing:

```txt
[persist] change cascade exceeded depth 8, write to 'coins(Alex)' rejected  chain: coins(Steve) -> coins(Bob) -> coins(Alex) -> ...  (chain lobby-1#7 started on 'lobby-1')
```

The line names the rejected write, the path that got there, the chain id, and the server the
chain started on — enough to find the handler across a whole network from one log grep.

### Layer 4 — self-echo suppression

Broadcasts carry `origin_server`, and a server ignores its own echo coming back off the bus. It
already applied that change locally and already fired its handlers (that's layer-3 depth
accounting doing its job); re-applying the echo would double-count every write in the network.

## Deployment notes and honest limitations {#deployment}

### Use a Redis coordinator on a busy network

`coordinator:` is optional. With no coordinator the runtime falls back to a **polled bus** — a
reserved ring of rows in the shared backend, swept every 250ms, with 64 slots per publishing
server. That is genuinely enough for a small network and it means `mode: network` works with
nothing but a database.

It has a hard limit though, and it is worth stating plainly: **if a server publishes more than
64 messages between two 250ms polls, the ring wraps and receivers miss messages.** Sequence
numbers mean a wrapped slot can't *replay* a stale message, so you get a dropped update rather
than a corrupted one — but a dropped global update is still a replica that stays wrong until the
next write to that value.

So: any network doing more than ~250 global writes/second on one node should configure Redis
pub-sub, which has no polling window and no ring at all.

```swoftlang
storage {
    backend: mysql { host: "10.0.0.5", database: "net", user: "mc", password: "hunter2" }
    mode: network
    coordinator: redis "redis://10.0.0.6"
}

persistent pot: Integer = 0
```

Redis also becomes the lease store, which takes the lease traffic off your game database.

### A routed atomic op can be lost mid-flight

`grant 100 coins to who` for a player on another server is *routed* to that server's owner. If
that owner disconnects the player (or crashes) while the message is in flight, the op can land
on a server that no longer owns the lease and be dropped. Delivery is at-most-once and
best-effort by design — the backend, not the bus, is the source of truth.

Closing this needs a durable outbox with acknowledgements and redelivery, which is **noted as
future work and is not in 1.10.0**. If an increment absolutely must not be lost (a paid rank, a
purchase), write it through your own transactional path rather than relying on a routed atomic
op.

### `delete X at K` on a global is a whole-map re-store

`set X at K to V` is a true per-key atomic op. Its sibling `delete X at K` on a *replicated
global* is currently implemented as a whole-map re-store, so it is **last-writer-wins over the
entire map**: a concurrent per-key write on another server can be lost by a deletion that read
the map before it. Deletions from globals are usually rare and administrative, so this is an
accepted 1.10.0 trade-off rather than a defect — but don't build a high-frequency eviction loop
on it.

### Reload

The [reload path](/reference/cli) is integrated: reloading scripts does not drop leases for
still-connected players, and replica subscriptions are torn down and re-established cleanly.

## See also

- [Persistence guide](/guide/persistence) — the declaration, types, backends, schema migration
- [Futures](/reference/futures) — `Future<T>`, `await`, and what `async { }` buys you
- [Structs](/reference/structs#persistent) — persistent records and reactive fields
