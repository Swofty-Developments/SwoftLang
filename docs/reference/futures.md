# Futures

A `Future<T>` is a value that stands for a result that isn't ready yet — the work is
running on a background [virtual thread](/guide/async#what-runs-where) and the future is
your handle to its eventual `T`. It is a real, first-class value: bind it, pass it to a
function, return it, store it in a `List<Future<T>>`. This page is the reference for
producing, consuming, and combining futures; the [Async guide](/guide/async#futures) is
the narrative introduction.

`Future<T>` is generic and PascalCase like [`List<T>`](/reference/collections) or
[`Optional<T>`](/guide/options). You never construct one directly — `spawn` and `async { }`
produce them.

## Producing a future {#producing}

### `spawn <call>` as an expression

`spawn f(args)` starts `f` on its own async task and evaluates to a `Future<R>`, where `R`
is the inferred return type of the async callable `f`. Only [async
callables](/guide/async) are spawnable — spawning a plain sync function is an error, the
same as it has always been.

```swoftlang
async function build_profile(p: Player) {
    wait 100 millis
    return "gold"
}

async function demo(player: Player) {
    set handle to spawn build_profile(player)   // Future<String>
    set rank to await handle
    send "rank ${rank}" to player
}
```

As a bare statement, `spawn f(args)` is **fire-and-forget** — the future is simply
discarded. Every existing script that used `spawn` for a detached task is unchanged;
becoming an expression is purely additive.

```swoftlang
async function log_metrics(p: Player) {
    wait 10 millis
    return 1
}

command "ping" {
    execute {
        if sender is a Player {
            spawn log_metrics(sender)   // statement form → result discarded
            send "pong" to sender
        }
    }
}
```

### `async { … }` as an expression

An `async { }` block used as an expression evaluates to a `Future<T>` where `T` is the
type of the block's **trailing expression**. With no trailing expression the type is
`Future<Unit>`.

```swoftlang
async function demo(p: Player) {
    set answer to async {
        wait 200 millis
        6 * 7           // trailing expression → Future<Integer>
    }
    send "answer ${await answer}" to p
}
```

## Consuming a future {#consuming}

Which consumer you use is decided by [color](/guide/async#the-coloring-rules): `await` in
async code, `when … is ready` on the tick thread.

### `await <future>` — async context only {#await}

`await e` requires `e : Future<T>` and evaluates to `T`. It parks the current virtual
thread until the future resolves (cheap — the same parking [`wait`](/guide/async) does) and
returns immediately if the result is already present.

`await` blocks, so it obeys the **same color rule as `wait`**: legal only in an async
context (an `async function` body, `execute async`, or an `async { }` block), and a compile
error on the tick thread, where blocking would freeze the world.

<!-- swoftc name=await_tick.sw expect=error -->

```swoftlang
async function score(p: Player) {
    wait 50 millis
    return 10
}

Player {
    on_join {
        set s to await spawn score(player)   // [!code error]
        send "score ${s}" to player
    }
}
```

```txt
await_tick.sw:8:18: error: 'await' is only allowed in async functions, 'execute async', or 'async { }' blocks; on the tick thread use 'when <future> is ready as <name> { ... }' instead
        set s to await spawn score(player)
                 ^
```

### `when <future> is ready as <name> { … }` — tick callback {#when-ready}

A **statement** that registers a continuation and returns immediately. When the future
resolves, `<body>` runs **back on the tick thread** with `<name>` bound to the `T` — so it
is safe to touch the world inside it. This is the callback consumer for tick-colored code,
where `await` is forbidden.

```swoftlang
struct Profile { rank: String }

async function build_profile(p: Player) {
    wait 100 millis
    return Profile { rank: "gold" }
}

Player {
    on_join {
        when spawn build_profile(player) is ready as profile {
            send "welcome ${profile.rank}" to player
        }
    }
}
```

If the future completes exceptionally or is cancelled, the body does **not** run (see
[Error model](#error-model)).

## Combinators {#combinators}

`all of` and `any of` turn a list of futures into a single future, so several tasks wait in
parallel instead of one after another.

| Form | Argument | Result |
|---|---|---|
| `all of L` | `L : List<Future<T>>` | `Future<List<T>>` — all results, input order |
| `any of L` | `L : List<Future<T>>` | `Future<T>` — the first result to arrive |

`all of` resolves once the **slowest** input does; `any of` resolves as soon as the
**first** input does (a race). Both are ordinary future-valued expressions — `await` them
in async code or hand them to `when … is ready` on the tick thread.

```swoftlang
async function ping(mirror: String) {
    wait 100 millis
    return mirror
}

async function pick(p: Player) {
    set mirrors to [spawn ping("eu"), spawn ping("us"), spawn ping("asia")]
    set all_replies to await all of mirrors     // List<String>, all three
    set first_reply to await any of mirrors     // String, whichever won
    send "${all_replies.size} replied, ${first_reply} first" to p
}
```

### Positional destructure {#positional-destructure}

`all of` over a **list literal of futures of different types** can be destructured
positionally: the compiler tracks each element's type by position, so `set (a, b) to await
all of [fa, fb]` binds `a : Ta` and `b : Tb`. This is the way to fan out a fixed set of
*heterogeneous* work; the homogeneous `Future<List<T>>` form above is for same-typed sets.

```swoftlang
struct Stats { kills: Integer }
struct Friends { count: Integer }

async function load_stats(p: Player) {
    wait 300 millis
    return Stats { kills: 12 }
}

async function load_friends(p: Player) {
    wait 500 millis
    return Friends { count: 7 }
}

async function open_menu(p: Player) {
    set (stats, friends) to await all of [spawn load_stats(p), spawn load_friends(p)]
    send "${stats.kills} kills · ${friends.count} friends" to p
}
```

## Holding a future {#holding}

A future is a value, so it need not be consumed where it is produced. Start slow work
early, carry the handle through unrelated code, and await it only when the value is needed
— the wait overlaps with everything in between. A future can also be a parameter, letting
one function start the work and another finish it.

```swoftlang
async function slow_lookup(id: Integer) {
    wait 500 millis
    return id * 10
}

async function report(p: Player, pending: Future<Integer>) {
    send "working..." to p
    set value to await pending           // finish work started elsewhere
    send "result ${value}" to p
}

async function process(p: Player, id: Integer) {
    set handle to spawn slow_lookup(id)  // starts now
    report(p, handle)                    // hand the handle off
}
```

## Typing & color rules {#rules}

| Construct | Requires | Yields | Context |
|---|---|---|---|
| `spawn call` | `call` is an async callable returning `R` | `Future<R>` | any color |
| `async { … x }` | `x : T` (trailing expr) | `Future<T>` | any color |
| `await e` | `e : Future<T>` | `T` | **async only** (same gate as `wait`) |
| `when e is ready as n { }` | `e : Future<T>`, binds `n : T` | statement | tick or async |
| `all of L` | `L : List<Future<T>>` | `Future<List<T>>` | any color |
| `any of L` | `L : List<Future<T>>` | `Future<T>` | any color |

Spawning a non-async callable is an error. Everything else about async — [world access
hopping back to the tick thread](/guide/async#what-runs-where),
[scope snapshots](/guide/async#scope-snapshots), `halt` killing only its own task — is
unchanged; futures add a value handle, not a new execution model.

## Error model {#error-model}

There is deliberately **no error branch on a future** in this release — no `otherwise`, no
`with timeout`, no `Result<T>` / `if it failed`. The reason is that nothing a future wraps
today does *outbound* IO: SwoftLang has inbound [`api`](/reference/http-api) routes but no
outbound HTTP, webhook, or database call — so there is no operation whose failure is a
normal, expected outcome worth branching on. The failure modes that *do* exist are handled
without one:

- **A runtime error inside the async body** completes the future exceptionally. `await`
  **re-raises** it in the awaiting task, where it propagates and is logged like any script
  error — exactly as a sequential call would. A `when … is ready` whose future errored does
  not run its body; the error is logged.
- **Cancellation** on reload or shutdown (the runtime cancels every in-flight task): a
  pending `await` unwinds the task cleanly and `when … is ready` continuations do not fire.
  The program is being torn down — not a handled outcome.
- **Missing data is not a future failure** — model it as [`Optional<T>`](/guide/options).
  The future succeeds *with* the `Optional`; don't route absence through the future.
- **A player or entity gone mid-load is not a future failure** — the value succeeded.
  Re-check liveness (`p.online`) in the continuation, the usual
  [stale-player](/guide/async#stale-players) guard.

An `await f otherwise <default>`, `await f with timeout <dur>`, and a `Result<T>` /
`if it failed as err` branch are **deferred** until outbound IO lands — that is the first
operation whose failure is a routine, expected result, and its error model will be designed
alongside it.

## See also

- [Async guide](/guide/async#futures) — the narrative walkthrough with a combined example
- [Structs](/reference/structs) and [Persistence](/guide/persistence) — where the
  "not-ready-yet" values (loaded records) typically come from
- [Options](/guide/options) — how missing data is modeled, *not* as a future failure
