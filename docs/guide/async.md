---
title: Async
---

<StepHeader>
a <code>/race</code> countdown that waits without freezing a tick — and three thread bugs the compiler refuses to compile.
</StepHeader>

Minecraft servers live and die by the tick: 20 per second, ~50 ms each, and everything
gameplay-visible happens on tick threads. A script that sleeps on a tick thread freezes
the world. SwoftLang's answer is compiler-checked async: code that waits runs on
background **virtual threads**, code that touches the world hops back to the tick
thread, and the compiler makes it impossible to get the two confused.

## The surface

Four constructs:

```swoftlang
async function countdown(target: Player, from: Integer) {   // 1. async function
    loop from times as i {
        send "<yellow>${from - i + 1}..." to target
        wait 1 seconds                                      // 2. wait
    }
    send "<lime>Go!" to target
}

command "race" {
    execute {
        spawn countdown(sender, 3)                          // 3. spawn
        send "countdown started" to sender
    }
}

Player {
    on_join {
        async {                                             // 4. async block
            wait 60 ticks
            send "<gold>Tip: type /help to get started" to player
        }
    }
}
```

`wait` takes `ticks`, `seconds`, or `millis`, with any integer expression for the amount.

## The coloring rules

Every region of code has a color — **sync** or **async** — decided entirely at compile
time:

| Region | Color |
|---|---|
| `execute { }` (command) | sync |
| `execute async { }` (command) | async |
| receiver method body (`on_join { }`) | sync |
| receiver method marked async (`on_join async { }`) | async |
| `async function` body | async |
| `async { }` block body | async |
| plain `function` body | sync — even when called from async code |

And the rules the checker enforces:

**1. `wait` needs async.** In sync code:

<!-- swoftc name=slow.sw expect=error -->

```swoftlang
command "slow" {
    execute {
        send "counting down..." to sender
        wait 3 seconds   // [!code error]
        send "done" to sender
    }
}
```

```txt
slow.sw:4:9: error: 'wait' is only allowed in async functions, 'execute async', or 'async { }' blocks
        wait 3 seconds
        ^
```

**2. Direct calls to async functions need async.** A direct call runs the async function
to completion on *your* thread — from sync code that would mean waiting on a tick
thread, so the compiler refuses:

<!-- swoftc name=heal.sw expect=error -->

```swoftlang
async function heal_later(p: Player) {
    wait 5 seconds
    set p.health to p.max_health
}

command "heal" {
    execute {
        if sender is a Player {
            heal_later(sender)   // [!code error]
        }
    }
}
```

```txt
heal.sw:9:13: error: 'heal_later' is an async function; call it with 'spawn heal_later(...)' or move this call into an async context
            heal_later(sender)
            ^
```

**3. `spawn` and `async { }` are legal in both colors.** They're fire-and-forget — a new
task starts, your code continues immediately, no value comes back.

**4. `cancel event` is banned in async regions** — the event has already dispatched by
the time async code runs ([why](/guide/events#cancelling-events)):

```txt
filter.sw:4:9: error: 'cancel event' must run before the handler goes async
        cancel event
        ^
```

That's the entire model. Sync functions stay callable from anywhere; only
genuinely-waiting code needs the `async` keyword.

The same `wait`, mapped from Skript:

<MappedCompare>
<MappedPair label="a delayed heal">
<template #skript>

```skript
command /heal:
    trigger:
        send "&7Healing in 5 seconds..." to player
        wait 5 seconds
        # everything below now runs 5s later — the trigger
        # silently became delayed; cancelling the event or
        # relying on "still on the event thread" breaks
        heal player
        send "&aHealed!" to player
```

</template>
<template #swoftlang>

```swoftlang
command "heal" {
    execute async {
        send "<gray>Healing in 5 seconds..." to sender
        wait 5 seconds
        if sender is a Player {
            set sender.health to sender.max_health
        }
        send "<green>Healed!" to sender
    }
}
```

</template>
<template #note>

The spelling is identical — `wait 5 seconds` — but in Skript, `wait` silently turns the
rest of the trigger into delayed code and nothing warns you. In SwoftLang, `wait` is
only legal in code that is *declared* async, it parks a virtual thread instead of
anything tick-related, and using it in sync code is a compile error. The declaration is
the documentation.

</template>
</MappedPair>
</MappedCompare>

## Getting values back

Inside async code, calling an async function directly is sequential and returns its
value — it reads exactly like sync code:

```swoftlang
async function fetch_bonus(base: Integer) {
    wait 100 millis
    return base * 2
}

command "bonus" {
    execute async {
        send "crunching..." to sender
        set b to fetch_bonus(50)
        send "your bonus is ${b}" to sender
    }
}
```

No callbacks, no `.then`. The task parks at each `wait` and the story reads top to
bottom.

`spawn`, by contrast, detaches the work onto its own task and hands you back a
[**`Future<T>`**](#futures) — a handle to the result that isn't ready yet. Ignore the
handle and it's fire-and-forget (`spawn farewell(sender.name)` as a bare statement just
kicks off independent work); *hold* it and you can await the value or fan several out in
parallel. Argument expressions are evaluated in the *parent* before the task detaches, so
`spawn farewell(sender.name)` captures the name at spawn time.

## Futures {#futures}

Sequential `set b to fetch_bonus(50)` is perfect when you need the answer *right here*
before the next line. But two things it can't do: hand a running task's result to code
somewhere else, and start several waits at once so they overlap instead of stacking. Both
need a **value that stands for a result you don't have yet**. That value is `Future<T>`.

`spawn` produces one. Used as an expression, `spawn build_profile(player)` starts the task
and evaluates to a `Future<Profile>` — a first-class value you can bind, pass to a
function, or drop into a `List<Future<Profile>>`:

<!-- swoftc name=welcome.sw -->

```swoftlang
struct Profile { rank: String }

async function build_profile(p: Player) {
    wait 100 millis
    return Profile { rank: "gold" }
}

async function welcome(player: Player) {
    set pending to spawn build_profile(player)   // Future<Profile> — task is running
    send "<gray>Loading your profile..." to player
    set profile to await pending                 // block *this* task until it lands
    send "<lime>Welcome, ${profile.rank}" to player
}
```

`await <future>` is an expression yielding the `T`. It parks the current virtual thread
until the future resolves — cheap, the same parking `wait` does — and returns instantly if
the result is already there. The `Profile` here is a [struct](/reference/structs); futures
pair naturally with struct loads and [persistence](/guide/persistence) reads, which is
where the "not ready yet" value actually comes from.

An `async { }` block is also an expression: its value is the block's trailing expression,
wrapped as a `Future<T>`.

<!-- swoftc name=asyncblock.sw -->

```swoftlang
async function prepare(p: Player) {
    set greeting to async {
        wait 200 millis
        "Welcome back"        // trailing expression → Future<String>
    }
    send "<gray>..." to p
    send await greeting to p
}
```

### `await` is async-only — same rule as `wait`

`await` blocks a task, so it lives under the exact same color rule as `wait`: legal in an
async context, a compile error on the tick thread (where blocking would freeze the world).
No new machinery — if `wait` is allowed there, so is `await`. Reaching for it inside a
sync `on_join`:

<!-- swoftc name=welcome_tick.sw expect=error -->

```swoftlang
struct Profile { rank: String }

async function build_profile(p: Player) {
    wait 100 millis
    return Profile { rank: "gold" }
}

Player {
    on_join {
        set profile to await spawn build_profile(player)   // [!code error]
        send "welcome ${profile.rank}" to player
    }
}
```

```txt
welcome_tick.sw:10:24: error: 'await' is only allowed in async functions, 'execute async', or 'async { }' blocks; on the tick thread use 'when <future> is ready as <name> { ... }' instead
        set profile to await spawn build_profile(player)
                       ^
```

### `when … is ready` — collecting a result on the tick thread

The error message names the fix. On the tick thread you don't block for a future — you
register a **continuation**. `when <future> is ready as <name> { … }` is a statement: it
returns immediately, and when the future resolves the body runs *back on the tick thread*
with `<name>` bound to the result. That makes it safe to touch the world right there — no
thread hop to reason about:

<!-- swoftc name=welcome_ready.sw -->

```swoftlang
struct Profile { rank: String }

async function build_profile(p: Player) {
    wait 100 millis
    return Profile { rank: "gold" }
}

Player {
    on_join {
        when spawn build_profile(player) is ready as profile {
            send "<lime>Welcome, ${profile.rank}" to player
        }
    }
}
```

So the two consumers split by color: **`await`** in async code (you're already off the
tick, blocking is free), **`when … is ready`** in tick code (never block; hand the runtime
a callback).

### Fanning out — `all of` and `any of`

Holding futures as values is what makes *parallel* waiting possible. Spawn several, then
combine them:

- **`all of <list-of-futures>`** resolves when every one resolves, to the list of results
  in input order. `await all of [...]` gives you the results once the slowest finishes —
  not the sum of every wait.
- **`any of <list-of-futures>`** resolves to the **first** result — a race between
  equivalent sources.

For a fixed set of *different* types, destructure positionally: `set (a, b) to await all
of [fa, fb]` binds `a` and `b` to each future's own type.

<!-- swoftc name=fanout.sw -->

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
    // both loads run at once; total wait ≈ 500ms, not 800ms
    set (stats, friends) to await all of [spawn load_stats(p), spawn load_friends(p)]
    send "<yellow>${stats.kills} kills · ${friends.count} friends" to p
}
```

When the futures are all the *same* type, skip the destructure and take the list:

<!-- swoftc name=race.sw -->

```swoftlang
async function ping(mirror: String) {
    wait 100 millis
    return mirror
}

async function fastest(p: Player) {
    set winner to await any of [spawn ping("eu"), spawn ping("us"), spawn ping("asia")]
    send "<lime>fastest mirror: ${winner}" to p
}
```

### Hold now, await later

A future doesn't have to be awaited where it's made. Kick the slow work off *first*, do
whatever doesn't depend on it, and await only at the moment you actually need the value —
the wait overlaps with everything in between:

<!-- swoftc name=holdhandle.sw -->

```swoftlang
async function slow_lookup(id: Integer) {
    wait 500 millis
    return id * 10
}

async function process(p: Player, id: Integer) {
    set pending to spawn slow_lookup(id)   // starts the clock now
    send "<gray>crunching..." to p         // this runs while the lookup is in flight
    wait 100 millis                         // ...and so does this
    set value to await pending             // by now it's very likely already done
    send "<lime>result ${value}" to p
}
```

### Putting it together

A realistic pattern: load a player's arena data in the background while a countdown plays,
then reveal it the instant both the data and the timer are done.

<!-- swoftc name=arena.sw -->

```swoftlang
struct Loadout { name: String }
struct MatchStats { wins: Integer }

async function load_loadout(p: Player) {
    wait 400 millis
    return Loadout { name: "Vanguard" }
}

async function load_stats(p: Player) {
    wait 700 millis
    return MatchStats { wins: 12 }
}

async function enter_arena(p: Player) {
    // fire both loads off in parallel — the vthreads work while we count down
    set loadout_job to spawn load_loadout(p)
    set stats_job to spawn load_stats(p)

    loop 3 times as i {
        send "<yellow>Entering the arena in ${3 - i}..." to p
        wait 1 seconds
    }

    // the countdown outlasted both loads; await just collects what's ready
    set (loadout, stats) to await all of [loadout_job, stats_job]
    send "<lime>Welcome, ${loadout.name} — ${stats.wins} career wins" to p
}

command "arena" {
    execute {
        if sender is a Player {
            spawn enter_arena(sender)
        }
    }
}
```

### No error branch — yet

You'll notice there's no `otherwise`, no timeout, no `if it failed` on a future. That's
deliberate, and it follows from what can actually go wrong today. Nothing a future wraps
right now does *outbound* IO — there's no HTTP call or database write whose failure is a
normal, expected outcome you'd want to branch on. So the only real failure modes are:

- **A bug in the async body** (a runtime error). The future completes exceptionally and
  `await` re-raises it in the awaiting task — it propagates and gets logged like any script
  error, exactly as it would if you'd called the function sequentially. A
  `when … is ready` whose future errored simply doesn't run its body.
- **Cancellation** on reload or shutdown. Every in-flight task is torn down; `await`
  unwinds cleanly and pending continuations don't fire. The program is going away — not a
  case you handle.
- **Missing data is not a failure.** "No profile found" is an [`Optional`](/guide/options),
  and the future succeeds *with* the `Optional` — don't route absence through the future.
- **A player who logged off mid-load is not a failure** either. The value arrived; re-check
  `p.online` in the continuation, the same [stale-player](#stale-players) guard you already
  write.

The `otherwise` / `with timeout` / `Result` branch is deferred until there's an operation
whose failure is a genuine routine outcome — that arrives together with outbound IO, and
its error model gets designed alongside it. See the [Futures
reference](/reference/futures#error-model) for the full rationale.

## What runs where

You don't manage any of this, but knowing it explains the rules:

- **Sync bodies** run inline on the tick thread, exactly like a hand-written listener —
  zero overhead, and why `wait` is banned there.
- **Async bodies** each get a virtual thread; thousands of concurrently-waiting tasks
  cost kilobytes each.
- **`wait n ticks`** resumes your task aligned to the tick boundary; `seconds`/`millis`
  are plain sleeps.
- **Touching the world** — teleporting, setting health, changing held items — must
  happen on the tick thread. Every [property](/guide/properties#threading) knows its
  thread policy; tick-only writes from async code are automatically funneled to the next
  tick while your task parks. So `set p.health to 0` in an async task is correct as
  written — the runtime does the thread hop, not you.

## Scope snapshots

A spawned task gets a **shallow snapshot** of the parent's variables. Bindings are
copied; objects are shared:

- `set x to 5` in the task — invisible to the parent.
- `set p.health to 5` in the task — very visible. There's only one player.

Function values are the one exception to "objects are shared": a lambda crossing a task
boundary is rebound over a snapshot of its captured environment, so calling it inside
the task never writes back into the parent's variables.

## `halt` in a task

`halt` kills the **current task only** — a spawned task halting never affects the parent
script or sibling tasks. An uncaught script error likewise kills just its own task, with
a log line citing script and line number.

## Stale players

A task that waits can outlive its player:

```swoftlang
async function delayed_reward(p: Player) {
    wait 30 seconds
    if p.online {
        set p.health to p.max_health
        send "<lime>Reward!" to p
    }
}

command "reward" {
    execute {
        spawn delayed_reward(sender)
    }
}
```

`p.online` is the idiomatic guard. As defense in depth, tick-dispatched writes to an
offline player are silently dropped rather than corrupting anything — but write the
guard; your intent should live in the script.

::: tip Lifecycle
All tasks are tracked. On script reload or server shutdown, every running task is
cancelled cleanly — a `wait 10 minutes` won't hold your server open.
:::
