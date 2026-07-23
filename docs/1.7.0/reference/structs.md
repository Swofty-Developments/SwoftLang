# Structs

A `struct` declares a named record type: a fixed set of typed fields, constructed all at
once, passed around by reference, and — when every field serializes — persisted whole. A
struct can also be **reactive**: mark a field as an event subject and the struct grows
handlers that fire on that subject's events for as long as the instance is stored
persistently. That last part turns a struct into a durable, stateful actor; the rest of
this page builds up to it with a guild and a duel.

## Declaration {#declaration}

```swoftlang
struct Guild {
    name: String
    level: Integer = 1                 // has a default → optional at construction
    members: List<Player>
    bank: Map<String, Integer>
    home: Optional<Location>
}
```

The name is a **Capitalized identifier** — the same rule every type name follows. A
struct is a nominal type usable anywhere a type is: a `var`/field type, a parameter, a
return, the right side of `is a`. Fields are `name: Type [= default]`, and a field's type
may be any value type — the scalars, the game values (`Player`, `Location`, `Vec`, `Item`,
`Entity`, `Mob` and its [custom subtypes](./mobs), `Block`), a `list`/`map`/`optional`/`either`
of those, or another struct nested inside.

A lowercase name is rejected the same way every type name is:

<!-- swoftc name=lowerstruct.sw expect=error -->

```swoftlang
struct guild {      // [!code error]
    name: String
    members: List<Player>
}
```

```txt
lowerstruct.sw:1:8: error: types must start with an uppercase letter — write `struct Guild`
struct guild {
       ^
```

## Construction is total {#construction}

You build a struct by naming it and supplying its fields in a `{ }` block. Every field
**without a default** must be given — there is no half-built struct, no null field to
check for later. Fields may appear in any order.

```swoftlang
struct Guild {
    name: String
    level: Integer = 1
    members: List<Player>
    bank: Map<String, Integer>
    home: Optional<Location>
}

command "found" {
    execute {
        if sender is a Player {
            set g to Guild {
                name: "Knights",
                members: [sender],
                bank: new_map(),
                home: none
            }
            send "<green>Founded ${g.name} (level ${g.level})." to sender
        }
    }
}
```

`level` is omitted and defaults to `1`; the other four have no default, so all four are
required. Leave one out and the checker names exactly which are missing:

<!-- swoftc name=missfield.sw expect=error -->

```swoftlang
struct Guild {
    name: String
    level: Integer = 1
    members: List<Player>
}

command "found" {
    execute {
        set g to Guild { level: 3 }      // [!code error]
    }
}
```

```txt
missfield.sw:9:18: error: construction of struct 'Guild' is missing required field(s): name, members
        set g to Guild { level: 3 }
                 ^
```

Totality is what makes the reactive machinery below implicit: the instant a struct
exists, every field holds a valid value, so a reactive instance is always ready to fire.

## Access and mutation {#access}

`g.field` reads a field; `set g.field to ...` writes one. Because fields carry their real
types, the natural collection and optional operations compose straight through them —
`at` on a map field, `exists` on an `optional` field, indexing on a list field:

```swoftlang
struct Guild {
    name: String
    level: Integer = 1
    bank: Map<String, Integer>
    home: Optional<Location>
}

command "guild-admin" {
    execute {
        if sender is a Player {
            set g to Guild { name: "Knights", bank: new_map(), home: none }
            send "<gray>${g.name} lvl ${g.level}" to sender
            set g.level to g.level + 1
            set g.bank at "gold" to 100         // map op through the field
            if g.home exists {
                teleport sender to g.home        // optional narrowed inside the guard
            }
        }
    }
}
```

Nested structs reach as far as their fields go — `g.leader.player.name` reads three deep,
and `set g.leader.contribution to ...` writes at the bottom of the chain.

## Reference semantics and `.copy()` {#reference}

A struct is a **reference type**, exactly like a `map` or a `list`. Passing one to a
function and mutating a field there is visible to the caller — the identity is stable, the
two names point at the same instance. This is the property the reactive layer depends on.

```swoftlang
struct Guild {
    name: String
    level: Integer = 1
}

function promote(gld: Guild) {
    set gld.level to gld.level + 1      // mutates the caller's instance
}

command "promote" {
    execute {
        set g to Guild { name: "Knights" }
        promote(g)
        set snapshot to g.copy()        // detached shallow copy
        promote(g)
        // g.level is 3; snapshot.level is frozen at 2
        send "<gray>now ${g.level}, snapshot ${snapshot.level}" to sender
    }
}
```

`g.copy()` returns a **shallow structural copy** — a new struct with the same field
values. Scalars are duplicated, but nested reference values (a `list`, a `map`, a nested
struct) are *shared* with the original, so mutating one through the copy shows up in both.
Reach for `.copy()` when you want a detached snapshot of the top-level fields — for
example a defensive copy before handing an instance to code that will mutate it.

Equality follows the reference model: `is` compares identity (same instance), and two
separately-constructed structs with identical fields are not `is`-equal.

## Structs as persistent state {#persistent}

A struct is an ordinary value, so it lives in a `var` for free. It can also be
[**persistent**](/1.7.0/guide/persistence) — provided every one of its fields is a persistable
type. The persistable types are the same ones a bare `persistent` variable accepts: the
scalars, `Location`, `Vec`, `Item`, `Player` (stored by uuid), any `list`/`map`/`optional`
of those, and nested structs that are themselves all-serializable.

```swoftlang
struct Guild {
    name: String
    level: Integer = 1
    members: List<Player>
    bank: Map<String, Integer>
    home: Optional<Location>
}

storage {
    backend: sqlite "data/guilds.db"
    flush: every 10 seconds
}

persistent guilds: Map<String, Guild> = new_map()

command "found" {
    execute {
        if sender is a Player {
            set guilds at "knights" to Guild {
                name: "Knights",
                members: [sender],
                bank: new_map(),
                home: sender.location
            }
            send "<green>Guild saved — survives a restart." to sender
        }
    }
}
```

The whole struct serializes to a JSON object of its fields — `Player` to uuid, `Location`
to its coordinates, `Item` to its NBT — and thaws back into the same live value on boot.
Reads stay total: the declared default is what an unwritten key returns.

A **live handle** is not a value and does not serialize. A struct with an `Entity`, `Mob`,
or [custom-mob](./mobs) field can't be made persistent — the checker rejects the
`persistent` declaration and names the offending field:

<!-- swoftc name=persbad.sw expect=error -->

```swoftlang
struct Party {
    boss: Mob                // [!code error]
    size: Integer = 1
}

persistent parties: Map<String, Party> = new_map()
```

```txt
persbad.sw:6:1: error: persistent 'parties' cannot store struct 'Party': field 'boss' has non-serializable type Mob
persistent parties: Map<String, Party> = new_map()
^
```

The fix is the familiar one from [persistence](/1.7.0/guide/persistence): store the uuid
`String` and re-resolve the entity when you need it, rather than persisting the live
handle.

### Schema & migration {#schema}

A persistent struct is a record on disk, and its shape changes over releases. Two constructs
keep old data loadable — the full worked treatment is in
[Persistence → Schema migration](/1.7.0/guide/persistence#schema-migration); the struct-body syntax
is:

- **`schema: N`** — a reserved struct-body statement declaring the struct's current version
  (default `1`). A stored row is tagged with the schema it was written under.
- **`migrate to N { <stmts> }`** — the upgrade run when a row older than `N` is loaded.
  Inside the block, `raw` is a `Map<String, Any>` of the row's previously stored fields
  (read a dropped/renamed column with `raw["oldName"] otherwise <fallback>`), and each
  statement `set`s a *current* field of the struct.

```swoftlang
struct Guild {
    schema: 2

    name: String
    tag: String = ""

    migrate to 2 {
        set name to raw["title"] otherwise "Unnamed"
        set tag to ""
    }
}

persistent guilds: Map<String, Guild> = new_map()
```

Adding or removing a field needs *neither* — auto-heal fills a missing field from its default
and drops fields the struct no longer declares, so `schema`/`migrate` are only for renames,
type changes, and cross-field backfills. The checker requires each `migrate to N` to have `N`
in `2..schema` with no duplicates, requires every `set` target to be a real field, and
rejects `schema`/`migrate` on a struct that isn't persistent-capable.

## Reactive fields — instance receivers {#reactive}

The headline feature. Annotate a struct field with **`@EventReceiver`** and it becomes an
event subject; then declare handlers on it *inside the struct body*, named after the
field. The handlers fire for that specific instance's subject.

```swoftlang
struct Duel {
    @EventReceiver a: Player
    @EventReceiver b: Player
    arena: Location
    score: Map<Player, Integer>

    a {                          // the field name opens its handler block
        on_death {               // Player's vocabulary, because a : Player
            // full struct context is in scope as bare names: a, b, arena, score
            set score at b to (score[b] otherwise 0) + 1
            teleport a to arena
            broadcast "<yellow>${b.name} takes the lead"
        }
    }

    b {
        on_death {
            set score at a to (score[a] otherwise 0) + 1
            teleport b to arena
            broadcast "<yellow>${a.name} takes the lead"
        }
    }
}
```

Three rules make this read the way it looks:

- **The field's type picks the vocabulary.** `a: Player` gets [Player](/1.7.0/reference/events#player)
  handlers (`on_death`, `on_chat`, …); a `boss: Mob` field would get [Mob](/1.7.0/reference/events#mob)
  handlers instead. The receiver method table is exactly the one from
  [Receivers & Events](/1.7.0/reference/events).
- **The context is bare — there is no `this`.** Inside a handler the struct's own fields
  (`a`, `b`, `arena`, `score`) *and* the event's bound variables (`killer` on a death, …)
  are all in scope as plain names. `a` **is** the field: the subject this handler reacts on.
- **`@EventReceiver` is a field modifier.** It only makes sense on a type that has an event
  vocabulary — a base subject. Put it on an `Integer` and there is nothing to react to:

<!-- swoftc name=badrecv.sw expect=error -->

```swoftlang
struct Score {
    @EventReceiver total: Integer      // [!code error]

    total {
        on_death { broadcast "x" }
    }
}
```

```txt
badrecv.sw:2:5: error: field 'total' is marked '@EventReceiver' but its type Integer has no event vocabulary; only a base subject (Player, Entity, Mob, Item, Block) can be a reactive receiver
    @EventReceiver total: Integer
    ^
```

### Liveness is persistence-gated — a durable stateful actor {#liveness}

There is no `activate`/`dispose` verb. A reactive instance's handlers fire **if and only
if the instance is reachable from a persistent root** — put it in a `persistent`
(directly, or inside a persistent `list`/`map`, or as a field of something already
reachable) and it is live; remove it and it is dead.

```swoftlang
struct Duel {
    @EventReceiver a: Player
    @EventReceiver b: Player
    arena: Location
    score: Map<Player, Integer>

    a { on_death { set score at b to (score[b] otherwise 0) + 1  teleport a to arena } }
    b { on_death { set score at a to (score[a] otherwise 0) + 1  teleport b to arena } }
}

persistent duels: Map<String, Duel> = new_map()

command "duel" {
    execute {
        if sender is a Player {
            // live the instant it lands in `duels`
            set duels at "arena-1" to Duel {
                a: sender, b: sender, arena: sender.location, score: new_map()
            }
        }
    }
}

command "endduel" {
    execute {
        delete duels at "arena-1"      // stops reacting, durably
    }
}
```

The runtime derives a `subject → instance` registry by walking persistent roots on load
and updating it on every persistent write, so it holds the instance by a strong reference
for exactly as long as it is stored — no weak references, no garbage-collection surprises.
Removal from persistence *is* the teardown signal.

The consequence is a feature, not a footnote: **a reactive struct is necessarily
serializable** (it must be persistent to be live), so a reactive instance is a *durable,
stateful actor*. Its `score` map, its `arena` — all of its state — rides across restarts
along with its handlers, and it resumes reacting on boot.

### Precedence and cancel {#precedence}

For one native event, handlers run in a fixed order of increasing specificity:

**global base receiver → custom override → live struct-instance handler(s).**

The base `Player { on_death }` runs first, then any custom override (a
[`mob Ghoul { }`](./mobs) or [`item Rod { }`](./items) block —
[most-specific wins](/1.7.0/reference/events#overriding-a-base-receiver), unchanged), then every
live struct-instance handler whose subject matches.

```swoftlang
struct Duel {
    @EventReceiver a: Player
    @EventReceiver b: Player
    arena: Location

    a { on_chat { cancel event  broadcast "<gray>[duel] ${a.name}: ${message}" } }
    b { on_chat { cancel event  broadcast "<gray>[duel] ${b.name}: ${message}" } }
}

persistent duels: Map<String, Duel> = new_map()

Player {
    on_chat {
        send "<dark_gray>(logged)" to player      // the global layer, runs first
    }
}
```

Cancellation is **cumulative, never short-circuiting**: on a cancellable event, *all*
layers run in order, and any layer may `cancel event` to veto the underlying game action.
Later layers still execute — they can observe that an earlier layer cancelled and react to
it. [`call original method`](/1.7.0/reference/events#overriding-a-base-receiver) keeps its
meaning inside the custom layer. When two live instances both match one subject (a player
in two duels at once), all of them fire.

### A custom type can't be a reactive subject {#custom-constraint}

A [custom mob or item](./mobs) already owns its behavior in its own block — one behavior
owner per type. So a **custom** type may not be the subject a struct *reacts on*. This is
the one place normal subtyping is narrowed, and it is scoped to reactive fields only.

- **Plain data field** — `leader: Mob` with no `@EventReceiver` — holding a `Ghoul` is
  completely fine. It's held as data; the mob's own `mob Ghoul { }` handlers still run. No
  struct handler is claiming its events.
- **Reactive field** — `@EventReceiver anchor: Mob` with an `anchor { }` handler block —
  a `Ghoul` flowing into it is an error, because that *would* make the struct drive the
  Ghoul's events.

Because mobs and items are nominal types, this is caught statically: a `Ghoul`-typed value
assigned into a reactive base field is a compile error (with a runtime backstop that
simply doesn't dispatch the struct handler if a custom-specialized subject reaches the
field dynamically).

<!-- swoftc name=raidbad.sw expect=error -->

```swoftlang
mob Ghoul {
    type: "ZOMBIE"
    health: 40
}

struct Anchorwatch {
    @EventReceiver anchor: Mob

    anchor {
        on_death { broadcast "the anchor fell" }
    }
}

command "raid" {
    execute {
        spawn mob Ghoul at location(0, 64, 0) as g
        set watch to Anchorwatch { anchor: g }      // [!code error]
    }
}
```

```txt
raidbad.sw:17:44: error: 'Ghoul' is a custom mob — it owns its behavior in its `mob Ghoul` block and can't also drive the reactive struct field 'anchor'. Put the logic in Ghoul's handlers, or use a plain Mob.
        set watch to Anchorwatch { anchor: g }
                                           ^
```

The two ways out are in the message: put the logic in `Ghoul`'s own handlers, or type the
field as a plain `Mob` and keep it a data field.

## New diagnostics at a glance {#diagnostics}

| Situation | Message |
|---|---|
| lowercase struct name | *types must start with an uppercase letter — write `struct Guild`* |
| construction missing a non-default field | *…is missing required field(s): …* |
| `@EventReceiver` on a type with no event vocabulary | *…has no event vocabulary; only a base subject…* |
| persistent struct with a non-serializable field | *…field 'boss' has non-serializable type Mob* |
| a custom type reaching a reactive field | *'Ghoul' is a custom mob — it owns its behavior…* |

::: tip Where reactive structs shine
Anything with a lifetime and a subject: a duel, a party, a bounty on a player's head, a
timed curse. Give it a `@EventReceiver` field for the subject, put its state in ordinary
fields, and store it in a `persistent` map keyed by an id. It reacts while it's stored and
stops the moment you delete it — no bookkeeping.
:::
