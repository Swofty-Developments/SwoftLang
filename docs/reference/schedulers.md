# Schedulers

Two ways to run code on a clock: a declarative top-level `every` block that starts at
boot, and a `schedule` expression that returns a cancelable handle. Both run
async-colored on virtual threads, tick-aligned — no busy loops, no timer plugin.

## `every` blocks

```swoftlang
mob "boss_wither" {
    type: "WITHER"
    health: 600
}

every 30 seconds {
    broadcast "<gray>Autosave in 10 seconds..."
}

every 5 ticks {
    loop all_mobs("boss_wither") as boss {
        set boss.name to "<dark_red>Wither <red>${boss.health}❤"
    }
}
```

`every <duration> { ... }` is a top-level declaration, like an event. The body starts
running when the server boots and repeats forever on the given cadence. It is
**async-colored**: `wait`, direct async calls, and blocking builtins are all legal
inside.

The cadence is a duration literal (`ticks` / `seconds` / `millis`) and must be
positive:

```
e_sched0.sw:1:1: error: scheduler cadence must be positive
```

## The `schedule` expression

For anything dynamic — delays started from a command, repeaters you'll cancel later —
`schedule` is an *expression* returning a `Schedule` handle:

```swoftlang
command "meteor" {
    execute {
        set warning to schedule after 3 seconds {
            broadcast "<red>Incoming!"
        }

        set shake to schedule every 10 ticks {
            play sound "minecraft:entity.generic.explode" to all volume 0.2 pitch 0.5
        }

        set finale to schedule after 5 seconds every 1 seconds {
            spawn particle "EXPLOSION_EMITTER" at location(0.5, 80.0, 0.5) count 1
        }

        cancel schedule warning
        cancel schedule shake
        cancel schedule finale
    }
}
```

| Form | Behavior |
|---|---|
| `schedule after <dur> { ... }` | run once, after the delay |
| `schedule every <dur> { ... }` | repeat on the cadence, starting one cadence from now |
| `schedule after <dur> every <dur> { ... }` | initial delay, then repeat |
| `cancel schedule <handle>` | stop it (safe on already-finished one-shots) |

The body is a closure — it captures the variables around it, like a
[lambda](/guide/functions#inline-functions-lambdas):

```swoftlang
command "remind" {
    arguments {
        text: String
    }
    execute {
        set who to sender
        set what to args.text
        set ignored to schedule after 60 seconds {
            send "<yellow>Reminder: ${what}" to who
        }
        send "<gray>Reminder set." to sender
    }
}
```

`cancel schedule` on anything that isn't a `Schedule` is a compile error — the
handle is a real type, not a magic id string.

## Counters, self-cancel, and named schedules

Repeating schedules carry a **run counter** and can **stop themselves**, run a **fixed
number of times**, and be **named** so you cancel or query them without holding a
handle. This one example uses all of it:

```swoftlang
every 1 seconds as "heartbeat" {
    if run >= 5 stop
    broadcast "heartbeat"
}

command "flash" {
    execute {
        // fixed-count repeat, spaced by 'every', with the run counter in scope
        repeat 3 times every 10 ticks {
            if run > 1 send "again" to sender
            send "flash" to sender
        }

        // a named handle that self-cancels at run 10
        set h to schedule every 1 seconds as "counter" {
            if run >= 10 stop
        }

        // liveness by handle or by name
        if is_running(h) send "counter is running" to sender
        if is_running("heartbeat") send "heartbeat is running" to sender

        // cancel by name and by handle
        cancel schedule "counter"
        cancel schedule h
    }
}
```

**`run`** is an `Integer` bound inside every `every`, `schedule`, and `repeat` body —
`1` on the first run, incrementing each time. **`stop`** cancels the enclosing schedule
from within (distinct from [`halt`](/guide/control-flow), which ends the current task);
together they express "repeat until a condition" without an external handle.

| Form | Behavior |
|---|---|
| `run` | the current run number (`Integer`, `1`-based), in any repeating body |
| `stop` | cancel the schedule this body belongs to |
| `repeat <n> times { ... }` | run the body `n` times back to back |
| `repeat <n> times every <dur> { ... }` | run the body `n` times, one per cadence |
| `every <dur> as "name" { ... }` | a named top-level scheduler |
| `schedule ... as "name" { ... }` | a named `schedule` expression (still returns a handle) |
| `cancel schedule "name"` | cancel by name |
| `is_running(<handle or "name">)` | `Boolean` — is that schedule still live |

Both `run` outside a schedule and `stop` outside a schedule are compile errors:

```
run_outside_schedule.sw:4:14: error: variable 'run' is never assigned
```

```
stop_outside_schedule.sw:4:9: error: 'stop' is only allowed inside an 'every', 'schedule', or 'repeat' body (it cancels the enclosing schedule); use 'halt' to end the current task
```

A `repeat` count must be a positive `Integer`, and cancelling or querying an
undeclared name is caught with the naming form spelled out:

```
repeat_non_int.sw:4:16: error: repeat count must be a positive Integer (got String)
```

```
cancel_unknown_named_schedule.sw:3:25: error: unknown schedule 'ghost' in 'cancel schedule'; name one with 'every ... as "ghost"' or 'schedule ... as "ghost"'
```

## Which tool when

| Situation | Use |
|---|---|
| "every N, forever, from boot" (boards, autosaves, ambient effects) | `every` block |
| delay or repeater created in response to something | `schedule` expression |
| one task that must also *react* (waits interleaved with logic) | `spawn` an [async function](/guide/async) |
| sequential waits inside an existing async body | plain `wait` |

All of them ride the same machinery: virtual threads plus a tick-end
clock, so a `schedule every 1 ticks` body runs aligned to real server ticks, and
game-state writes are tick-dispatched exactly as in any async code. Schedules are
cancelled wholesale on engine reload and shutdown.

::: tip Real-world example
The first-class [`npc`](/reference/npcs) construct's `look_at_players` head tracking is
one repeating schedule per NPC under the hood — it finds the nearest player each tick and
rotates the head, cancelling the schedule when the NPC is removed.
:::
