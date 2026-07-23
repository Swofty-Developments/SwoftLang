# Mob AI

A [`mob`](./mobs) declaration can carry an `ai { }` block that gives the creature
**custom behavior** — you write the *goals* it pursues, the *targets* it picks, and the
*navigator* statements that move it. This is the tier above the one-word
[`ai:` presets](./mobs#declaration-keys); the presets stay for the common cases, and the
`ai { }` block is there when you want to script the brain yourself.

```swoftlang
mob Guardian {
    type: "IRON_GOLEM"
    name: "<gold>Guardian"
    health: 100

    ai {
        target closest Player within 16
        goal "chase" {
            should_start { target exists }
            on_start { look at target }
            on_tick {
                path mob to target
                if distance(mob, target) < 2 {
                    stop pathing mob
                }
            }
            should_end { target is none }
        }
        goal "wander" priority 5 {
            on_tick { path mob to random_point_near(mob.location, 8) }
        }
    }
}
```

An `ai { }` block holds any number of **targets** (selectors that choose the entity the
mob is after) and **goals** (prioritized behaviors). Each tick the highest-priority goal
whose `should_start` is met runs its `on_tick` until it ends — the classic
select-and-run loop, written in SwoftLang.

::: tip One block, one group
One `ai { }` block is one behavior group for the mob. Presets and a custom `ai { }` are
alternatives — pick the preset for the common shape, the block when you need to script it.
:::

## Bare context: `mob` and `target` {#context}

Everywhere inside an `ai { }` block — goal lifecycle blocks and `target { }` blocks alike —
two names are bound **bare**, with no `this` (the same convention as
[receivers](./events) and reactive blocks):

| Name | Type | Meaning |
|---|---|---|
| `mob` | the enclosing mob type (e.g. `Guardian`) | the creature this AI drives |
| `target` | `Optional<Entity>` | the group's currently selected target |

`target` is an [`Optional`](/guide/options) because there may be nothing selected this
tick — narrow it with `exists` / `is none` (or `otherwise`) before you treat it as a
concrete entity:

```swoftlang
goal FaceThreat {
    should_start { target exists }
    on_tick { look at target }
    should_end { target is none }
}
```

Inside a reusable goal type like `FaceThreat`, `mob` is bound to *whatever* creature the
goal is attached to; the navigator and `distance` builtins accept the `Optional<Entity>`
`target` directly, so a `should_start { target exists }` guard is all you need before
pathing to it.

## Goals {#goals}

A **goal** is one prioritized behavior with a lifecycle. Declared inline in the `ai { }`
block as `goal "<name>" [priority N] { ... }`, its blocks map one-to-one onto Minestom's
goal selector:

| Block | Returns | When it runs |
|---|---|---|
| `should_start { }` | `Boolean` (default `true`) | each tick the goal is idle — may this goal take over? |
| `on_start { }` | — | once, when the goal begins |
| `on_tick { }` | — | every tick while the goal is active |
| `should_end { }` | `Boolean` (default `false`) | each tick the goal is active — is it done? |
| `on_end { }` | — | once, when the goal stops |

All five are optional. A goal with no `should_end` runs until a **higher-priority** goal
preempts it.

```swoftlang
mob Warden {
    type: "WARDEN"
    health: 500
    ai {
        target closest Player within 24
        goal "hunt" {
            should_start { target exists }
            on_tick { path mob to target at speed 0.4 }
            should_end { target is none }
        }
        goal "patrol" priority 10 {
            on_tick { path mob to random_point_near(mob.location, 12) }
        }
    }
}
```

### Priority {#priority}

**Declaration order is priority** — the first goal listed is the highest. An explicit
`priority N` overrides that (lower `N` = higher priority). The highest-priority goal whose
`should_start` is `true` runs until its `should_end` fires or a higher-priority goal starts.
Above, `hunt` (declaration order → priority 0) outranks `patrol` (`priority 10`): the Warden
chases while a player is in range and only patrols when there is none.

### Reusable goal types {#goal-types}

A goal you want on more than one mob becomes a **top-level goal type** — PascalCase, like a
[struct](./structs) or a mob type — declared with the same lifecycle blocks and attached by
name through the `goals:` list. `priority` still applies at the attachment site, and
declaration order in the list is the default priority:

```swoftlang
goal Chase {
    should_start { target exists }
    on_tick { path mob to target }
    should_end { target is none }
}

goal Wander {
    on_tick { path mob to random_point_near(mob.location, 8) }
}

mob Hound {
    type: "WOLF"
    ai {
        target closest Player within 20
        goals: [ Chase, Wander priority 5 ]
    }
}
```

`Chase` and `Wander` bind `mob` to the `Hound` here; attach the same pair to another mob and
`mob` binds to that one. A name in `goals:` must be a declared **goal** type — pointing it at
a mob, item, or struct type is a compile error:

```
ai_goal_non_mob.sw:10:18: error: 'Blob' is a mob/item/struct type, not a reusable goal type; a goal must be declared with 'goal Blob { <lifecycle> }'
```

## Targets {#targets}

Targets choose the entity a goal's `target` refers to. You may list **zero or more**; they
are tried in order and the first that yields an entity wins for that tick.

### Natural selectors {#natural-targets}

The common cases read like English — `target <selector> within <n>`, the range in blocks:

| Form | Picks |
|---|---|
| `target closest Player within <n>` | the nearest player in range |
| `target closest hostile within <n>` | the nearest hostile mob in range |
| `target closest <MobType> within <n>` | the nearest instance of a declared [mob type](./mobs) |
| `target last attacker within <n>` | whoever last damaged this mob, if still in range |

```swoftlang
mob Ghoul {
    type: "ZOMBIE"
    health: 30
}

mob Sentinel {
    type: "IRON_GOLEM"
    health: 120
    ai {
        target last attacker within 24
        target closest hostile within 16
        target closest Ghoul within 20
        target closest Player within 12
        goal "engage" {
            should_start { target exists }
            on_tick { path mob to target }
            should_end { target is none }
        }
    }
}
```

An unknown selector word is caught at compile time — only the forms above and the block form
below are accepted:

```
ai_bad_target.sw:4:16: error: Unknown target selector form: identifier 'nearest'; expected 'closest Player|hostile|<MobType> within <n>', 'last attacker within <n>', or a 'target { ... }' block
```

### The `target { }` block {#target-block}

When selection needs real logic, write a `target { ... }` block that **returns** the chosen
entity — an `Entity`, an `Optional<Entity>`, or `none` for "nothing this tick". `mob` is
bound, so you can measure against the creature's own position:

```swoftlang
mob Medic {
    type: "VILLAGER"
    health: 40
    ai {
        target {
            set hurt to all_mobs().filtered(function(m: Mob) { return m.health < m.max_health })
            return hurt.min_by(function(m: Mob) { return distance(mob, m) })
        }
        goal "tend" {
            should_start { target exists }
            on_tick { path mob to target }
            should_end { target is none }
        }
    }
}
```

Returning `none` (or an empty `Optional`) means no target this tick, so a
`should_start { target exists }` goal simply won't start.

## Navigator vocabulary {#navigator}

Goals move the mob through a small statement-and-query vocabulary over the built-in
navigator (A\* pathfinding). Both a live [`Entity`](./entities) and a `Location` — and the
`Optional<Entity>` `target` — are accepted as destinations:

| Statement | Effect |
|---|---|
| `path <mob> to <entity \| location>` | start or continue an A\* path to the point |
| `path <mob> to <point> at speed <n>` | the same, with a movement-speed modifier on the path |
| `stop pathing <mob>` | clear the current path |
| `look at <entity \| location>` | face the point without moving |

| Query | Type | Meaning |
|---|---|---|
| `<mob> reached <entity \| location>` | `Boolean` | at or adjacent to that point |
| `<mob>.navigating` | `Boolean` | has an active path right now |

`distance(a, b)` (blocks between two points, entities, or the `target`) and
`random_point_near(p, r)` (a `Location` within `r` blocks of `p`) round out the AI builtins.

```swoftlang
mob Ranger {
    type: "SKELETON"
    health: 30
    ai {
        target closest Player within 18
        goal "kite" {
            should_start { target exists }
            on_tick {
                path mob to target at speed 0.35
                look at target
                if mob reached target { stop pathing mob }
                if mob.navigating { look at mob.location }
            }
            should_end { target is none }
        }
    }
}
```

## Presets still work {#presets}

The one-word [`ai:` preset](./mobs#declaration-keys) is unchanged — it is sugar over the
same goal machinery, and remains the right choice for the common shapes. A mob uses a preset
*or* a custom `ai { }` block, not both:

```swoftlang
mob Brute {
    type: "ZOMBIE"
    health: 40
    ai: melee            // chase + attack + stroll
}

mob Cow {
    type: "COW"
    health: 10
    ai: passive          // stroll only
}

mob Statue {
    type: "ARMOR_STAND"
    ai: none             // no AI at all
}
```

## Goals run on the tick thread {#tick-thread}

**Every goal block runs on the tick thread, every tick.** That is what makes `path`,
`look at`, and `distance` cheap and immediate — but it also means a goal body must **never
block**. `wait` and `await` are compile errors inside `should_start` / `on_tick` / the rest,
exactly as they are in any other [tick-colored](/guide/async#the-coloring-rules) code:

<!-- swoftc name=ai_await_tick.sw expect=error -->

```swoftlang
async function slow_pick() {
    wait 1 ticks
    return 5
}

mob Ghoul {
    type: "ZOMBIE"
    ai {
        target closest Player within 10
        goal "chase" {
            on_tick {
                set n to await spawn slow_pick()   // [!code error]
                path mob to target at speed n
            }
        }
    }
}
```

```txt
ai_await_tick.sw:12:26: error: 'await' is only allowed in async functions, 'execute async', or 'async { }' blocks; on the tick thread wrap the awaiting work in an 'async { }' block instead
                set n to await spawn slow_pick()
                         ^
```

When a goal needs data that is slow to compute, **detach** it: `spawn`/`async { }` produce a
[future](./futures), you `await` it *inside* the `async { }` task, and the world access after
the `await` [auto-hops back](/guide/async#what-runs-where) onto the tick thread. The `on_tick`
itself returns immediately; the follow-up lands on a later tick.

```swoftlang
async function preferred_target_name(m: Mob) {
    wait 2 ticks
    return "Herobrine"
}

mob Assassin {
    type: "ZOMBIE"
    health: 40
    ai {
        target closest Player within 24
        goal "stalk" {
            should_start { target exists }
            on_tick {
                path mob to target                 // immediate, every tick
                async {
                    set who to await spawn preferred_target_name(mob)
                    look at mob.location            // back on the tick thread
                }
            }
            should_end { target is none }
        }
    }
}
```

This is the single-consumer [futures](./futures#consuming) model applied to AI: produce a
future with `spawn`/`async`, consume it once with `await` inside the detached task.

## A note on deep pathfinding {#future-pathfinding}

The navigator here is the built-in ground A\* — it walks the mob to a point. Full control
over **how** a path is found — flight, swimming, custom walkability and cost per block via a
dedicated `pathfinding { }` block — is a planned future tier, not part of this release. Until
it lands, the `path … to` / `at speed` / `stop pathing` vocabulary above is the whole
navigator surface, and it drives the standard entity pathfinder.

## See also

- [Custom Mobs](./mobs) — the `mob` declaration, presets, drops, tags, and events
- [Futures](./futures) and the [Async guide](/guide/async) — `spawn`/`async` + `await`, the
  tick-thread detach pattern goals use for slow data
- [Entities](./entities) — the property surface every `mob` composes
- [Options](/guide/options) — how `target` models "nothing selected"
