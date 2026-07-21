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
[lambda](/1.1.0/guide/functions#inline-functions-lambdas):

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
from within (distinct from [`halt`](/1.1.0/guide/control-flow), which ends the current task);
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

## Per-object task registry — `<obj>.tasks.<id>` {#obj-tasks}

Every game object carries a **named task registry** under `.tasks` — a namespace
distinct from [tags](/1.1.0/reference/mobs#tags) whose values are `Schedule` handles. You bind a
repeating or delayed task to an object under an id you choose, then reference, query, and
cancel it **by that id** — no handle variable to carry around. The registry lives on the
object, so the same id means "that object's task" from anywhere.

```swoftlang
on PlayerJoin {
    // bind two named tasks to the joining player
    set event.player.tasks.welcome to schedule every 20 ticks {
        send "<gray>tick" to event.player
    }
    set event.player.tasks.reminder to schedule after 1 seconds every 2 seconds {
        send "<yellow>reminder" to event.player
    }

    // query by id: 'is running' / 'is not running' is a Boolean
    if event.player.tasks.welcome is running send "<green>welcome running" to event.player
    if event.player.tasks.reminder is not running send "<red>reminder stopped" to event.player

    // cancel by id — 'cancel' and 'stop' are interchangeable here
    cancel event.player.tasks.welcome
    stop event.player.tasks.reminder
}
```

The value assigned must be a `schedule` expression — the registry stores the live handle.
Any [`schedule` form](#the-schedule-expression) works (`after`, `every`, `after … every`),
and the body is the same closure, with `run` and `stop` in scope.

### The registry entry

| Form | Meaning |
|---|---|
| `set <obj>.tasks.<id> to schedule …` | bind (or rebind) the task under `id` |
| `<obj>.tasks.<id> is running` | `Boolean` — is that task still live |
| `<obj>.tasks.<id> is not running` | `Boolean` — the negation |
| `cancel <obj>.tasks.<id>` | stop it (safe if already finished) |
| `stop <obj>.tasks.<id>` | same as `cancel` on a registry entry |
| `<obj>.tasks.<id>` (as a value) | reads as `optional<Schedule>` |

Reading an entry gives an **`optional<Schedule>`** — missing until something is bound —
so it composes with the [option operators](/1.1.0/guide/options):

```swoftlang
on PlayerJoin {
    set handle to event.player.tasks.welcome        // optional<Schedule>
    if event.player.tasks.welcome exists broadcast "welcome is bound"
}
```

**Rebinding the same id cancels the old task first**, and a task **auto-cancels when its
owner goes away** — the player disconnects, the mob despawns, the entity is removed — so a
per-object task never outlives the thing it belongs to.

### Which objects have a registry

`.tasks` is available on the objects with a stable identity:

| Owner | How the object is in scope |
|---|---|
| `Player` | any `Player` value — `event.player`, `sender`, a loop variable |
| `Mob` | `mob` inside [`on_spawn`](/1.1.0/reference/mobs), a `Mob` value elsewhere |
| `Entity` | any [`Entity`](/1.1.0/reference/entities) value |
| `Npc` | `this` inside an [npc](/1.1.0/reference/npcs) handler (`on_click`, `on_tick`) |
| `Hologram` | `this` inside a [hologram](/1.1.0/reference/holograms) handler |
| `block_at(<location>)` | the block at a position — the registry is keyed by that position |

Binding a task from inside a construct's own handler uses `this` (or `mob` in
`on_spawn`), so the task's lifetime is naturally the construct's:

```swoftlang
mob "sentinel" {
    type: "IRON_GOLEM"
    name: "<gray>Sentinel"
    on_spawn {
        // auto-cancels when this mob despawns
        set mob.tasks.patrol to schedule every 40 ticks {
            broadcast "<white>patrolling"
        }
    }
}

npc "guide" {
    location: location(5, 64, 5)
    skin: "Notch"
    on_tick() {
        set this.tasks.follow to schedule after 2 seconds every 1 seconds {
            broadcast "<yellow>following"
        }
        if this.tasks.follow is running broadcast "following on"
        stop this.tasks.follow
    }
}
```

A task on a **block** is keyed by position through `block_at(<location>)`. Removing the
block (see [`remove block at`](/1.1.0/reference/blocks#placing-and-reading-blocks)) cancels every
task bound to that position:

```swoftlang
on PlayerJoin {
    place block("minecraft:sea_lantern") at event.player.location
    set block_at(event.player.location).tasks.pulse to schedule every 5 ticks {
        broadcast "<aqua>pulse"
    }
    if block_at(event.player.location).tasks.pulse is running broadcast "pulsing"
    remove block at event.player.location      // also cancels the 'pulse' task
}
```

`Item` has **no** task registry — items are value types with no stable identity, so
`item.tasks.x` is a compile error:

```
w_item_tasks.sw:4:13: error: Item has no task registry; .tasks is only available on Player, Mob, Entity, Npc, Hologram, and block_at(...) (items are value types with no stable identity)
```

## Which tool when

| Situation | Use |
|---|---|
| "every N, forever, from boot" (boards, autosaves, ambient effects) | `every` block |
| delay or repeater created in response to something | `schedule` expression |
| one task that must also *react* (waits interleaved with logic) | `spawn` an [async function](/1.1.0/guide/async) |
| sequential waits inside an existing async body | plain `wait` |

All of them ride the same machinery: virtual threads plus a tick-end
clock, so a `schedule every 1 ticks` body runs aligned to real server ticks, and
game-state writes are tick-dispatched exactly as in any async code. Schedules are
cancelled wholesale on engine reload and shutdown.

::: tip Real-world example
The first-class [`npc`](/1.1.0/reference/npcs) construct's `look_at_players` head tracking is
one repeating schedule per NPC under the hood — it finds the nearest player each tick and
rotates the head, cancelling the schedule when the NPC is removed.
:::
