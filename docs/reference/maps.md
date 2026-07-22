# Maps

A `Map<K, V>` is a dictionary from keys of type `K` to values of type `V`. The key type
is `String`, `Integer`, or `Player`; `Map<V>` with one type argument is shorthand for
`Map<String, V>`. The value type is inferred from a literal or written explicitly. Maps
are mutable reference values — passing one to a function and mutating it there is visible
to the caller — and a `map` of a scalar value type can be `persistent`, so a whole
dictionary survives a restart.

Every map operation comes in **two coexisting dialects** that compile to exactly the same
thing: a *natural-language* phrasing (`set m at k to v`, `size of m`, `delete m at k`) and
a *method* phrasing (`m.set(k, v)`, `m.size`, `m.delete(k)`). Pick whichever reads better —
the switch below flips every example on this page between the two.

<DialectSwitch />

<DialectCode title="A counter map">
<template #natural>

```swoftlang
command "counts" {
    execute {
        // literal — V is inferred as Integer from the values
        set counts to { "a": 1, "b": 2, "c": 3 }

        set counts at "d" to 4               // write
        set a to counts["a"] otherwise 0     // index-read yields Optional<V>
        send "a is ${a}, size is ${size of counts}" to sender

        delete counts at "b"                 // remove one entry
        if counts has "c" {                  // membership test
            send "still counting c" to sender
        }
    }
}
```

</template>
<template #code>

```swoftlang
command "counts" {
    execute {
        // literal — V is inferred as Integer from the values
        set counts to { "a": 1, "b": 2, "c": 3 }

        counts.set("d", 4)                   // write
        set a to counts.get("a") otherwise 0 // .get yields Optional<V>
        send "a is ${a}, size is ${counts.size}" to sender

        counts.delete("b")                   // remove one entry
        if counts.has("c") {                 // membership test
            send "still counting c" to sender
        }
    }
}
```

</template>
</DialectCode>

## Building a map {#building}

| Form | Result | Notes |
|---|---|---|
| `{ "k": v, ... }` | `Map<String, V>` | String keys; `V` is the join of the value types |
| `{ 1: v, ... }` | `Map<Integer, V>` | Integer-literal keys |
| `new_map()` | `Map<Any, Any>` | an empty map; key and value narrow from context |

The empty `{}` literal is rejected — it collides with a block — so an empty map is
always `new_map()`:

<!-- swoftc name=emptymap.sw expect=error -->

```swoftlang
command "bad" {
    execute {
        set m to {}      // [!code error]
    }
}
```

```txt
emptymap.sw:3:19: error: empty map literal '{}' is ambiguous with a block; use new_map() to build an empty map
        set m to {}
                  ^
```

Every value in a map must be *present* — a map cannot store a possibly-missing value
directly, so narrow or `otherwise` an optional before you put it in.

## Key types {#key-types}

Keys are `String`, `Integer`, or `Player`. Every map operation is key-type aware: the
index sugar, the natural-language forms, the methods, and both loop forms take a key of
the map's `K`, and `keys of m` (or `m.keys`) returns a `List<K>`.

An **Integer-keyed** map — `Map<Integer, V>`, inferred from an integer-literal
dictionary or written out:

<DialectCode title="Integer keys" file="intkeys.sw">
<template #natural>

```swoftlang
command "intkeys" {
    execute {
        set names to { 1: "one", 2: "two", 3: "three" }

        set names at 4 to "four"             // Integer key
        set first to names[1] otherwise "none"
        send "first ${first}" to sender

        loop names as num -> word {          // key is an Integer, value a String
            send "${num} = ${word}" to sender
        }
    }
}
```

</template>
<template #code>

```swoftlang
command "intkeys" {
    execute {
        set names to { 1: "one", 2: "two", 3: "three" }

        names.set(4, "four")                 // Integer key
        set first to names.get(1) otherwise "none"
        send "first ${first}" to sender

        loop names as num -> word {          // key is an Integer, value a String
            send "${num} = ${word}" to sender
        }
    }
}
```

</template>
</DialectCode>

A **Player-keyed** map — `Map<Player, V>`. Players serialize by UUID on the Java side, so
a Player-keyed map is `persistent`-safe; the compiler just types the key as `Player`:

<DialectCode title="Player keys" file="pmap.sw">
<template #natural>

```swoftlang
command "pmap" {
    execute {
        set wins to new_map()

        set wins at sender to 10             // first insertion fixes K = Player, V = Integer
        set mine to wins[sender] otherwise 0
        send "you have ${mine}" to sender

        loop wins as who -> pts {            // key is a Player
            send "${who.name}: ${pts}" to sender
        }
    }
}
```

</template>
<template #code>

```swoftlang
command "pmap" {
    execute {
        set wins to new_map()

        wins.set(sender, 10)                 // first insertion fixes K = Player, V = Integer
        set mine to wins.get(sender) otherwise 0
        send "you have ${mine}" to sender

        loop wins as who -> pts {            // key is a Player
            send "${who.name}: ${pts}" to sender
        }
    }
}
```

</template>
</DialectCode>

Passing a key of the wrong type is a compile error naming the key type the map expects.
The message names the exact form you wrote — the natural `m has k`:

```
has_wrong_key_type.sw:4:18: error: 'm has k' expects a String key here (got Integer)
        if m has 5 {
                 ^
```

## Operations {#operations}

Every operation has the two coexisting surface forms, and both compile to exactly the same
runtime call:

| Operation | Natural language | Method / property | Result |
|---|---|---|---|
| read | `m[k]` | `m.get(k)` | `Optional<V>` |
| write | `set m at k to v` | `m.set(k, v)` | — |
| test | `m has k` | `m.has(k)` | `Boolean` |
| remove | `delete m at k` | `m.delete(k)` | — |
| keys | `keys of m` | `m.keys` | `List<K>` |
| values | `values of m` | `m.values` | `List<V>` |
| size | `size of m` | `m.size` | `Integer` |
| clear | `clear m` | `m.clear()` | — |

Reads return an `Optional<V>` because the key may be absent — the compiler makes you
account for that with `exists` or `otherwise`:

<DialectCode title="Look up a price" file="lookup.sw">
<template #natural>

```swoftlang
command "lookup" {
    execute {
        set prices to { "diamond": 800, "iron": 40 }

        // fall back to a default
        set p to prices["gold"] otherwise 0
        send "gold costs ${p}" to sender

        // ...or narrow with 'exists'
        if prices["diamond"] exists {
            send "diamond is priced" to sender
        }
    }
}
```

</template>
<template #code>

```swoftlang
command "lookup" {
    execute {
        set prices to { "diamond": 800, "iron": 40 }

        // fall back to a default
        set p to prices.get("gold") otherwise 0
        send "gold costs ${p}" to sender

        // ...or narrow with 'exists'
        if prices.get("diamond") exists {
            send "diamond is priced" to sender
        }
    }
}
```

</template>
</DialectCode>

`values of m` walks the stored values, and `clear m` empties the map:

<DialectCode title="Sum the values, then clear" file="values.sw">
<template #natural>

```swoftlang
command "reset-prices" {
    execute {
        set prices to { "diamond": 800, "iron": 40 }

        set total to 0
        loop values of prices as v {
            set total to total + v
        }
        send "total value ${total}" to sender

        clear prices
        send "cleared, size ${size of prices}" to sender
    }
}
```

</template>
<template #code>

```swoftlang
command "reset-prices" {
    execute {
        set prices to { "diamond": 800, "iron": 40 }

        set total to 0
        loop prices.values as v {
            set total to total + v
        }
        send "total value ${total}" to sender

        prices.clear()
        send "cleared, size ${prices.size}" to sender
    }
}
```

</template>
</DialectCode>

A write type-checks the value against `V`; a mismatched value is a compile error that
names the form you used:

<!-- swoftc name=badval.sw expect=error -->

```swoftlang
command "bad" {
    execute {
        set counts to { "a": 1 }
        set counts at "b" to "two"       // [!code error]
    }
}
```

```txt
badval.sw:4:30: error: 'set m at k to v' expects a Integer value (got String)
        set counts at "b" to "two"
                             ^
```

## Iterating {#iterating}

Looping the keys walks them as a plain `List<K>`; the dedicated `loop m as key -> value`
form binds the key and the `V` value per entry:

<DialectCode title="Walk every entry" file="dump.sw">
<template #natural>

```swoftlang
command "dump" {
    execute {
        set counts to { "a": 1, "b": 2 }

        loop keys of counts as key {
            send "key ${key}" to sender
        }

        loop counts as name -> amount {
            send "${name} = ${amount}" to sender
        }
    }
}
```

</template>
<template #code>

```swoftlang
command "dump" {
    execute {
        set counts to { "a": 1, "b": 2 }

        loop counts.keys as key {
            send "key ${key}" to sender
        }

        loop counts as name -> amount {
            send "${name} = ${amount}" to sender
        }
    }
}
```

</template>
</DialectCode>

## Persistence {#persistence}

A map whose values are `String`, `Integer`, `Double`, or `Boolean` can be declared
`persistent`, for any key type — `String`, `Integer`, and `Player` (by UUID) all
serialize. It writes to the [storage backend](./server-config#storage-phase-3)
as JSON and is reloaded on boot, so the whole dictionary survives restarts. Writes
through the map mutate the stored value in place:

<DialectCode title="A restart-safe leaderboard" file="leaderboard.sw">
<template #natural>

```swoftlang
storage {
    backend: files "data/game"
    flush: every 10 seconds
}

persistent leaderboard: Map<Integer> = new_map()

command "score" {
    arguments { amount: Integer }
    execute {
        set leaderboard at sender.name to (leaderboard[sender.name] otherwise 0) + args.amount
        send "total ${leaderboard[sender.name] otherwise 0}" to sender
    }
}
```

</template>
<template #code>

```swoftlang
storage {
    backend: files "data/game"
    flush: every 10 seconds
}

persistent leaderboard: Map<Integer> = new_map()

command "score" {
    arguments { amount: Integer }
    execute {
        leaderboard.set(sender.name, (leaderboard.get(sender.name) otherwise 0) + args.amount)
        send "total ${leaderboard.get(sender.name) otherwise 0}" to sender
    }
}
```

</template>
</DialectCode>

### Storing items across restarts {#items}

A scalar map can hold item stacks by serializing them: `to_nbt(item)` turns an `Item`
into its NBT `String`, and `from_nbt(string)` parses one back — as an
`Optional<Item>`, because the text might be malformed. The round-trip lets a persistent
`Map<String>` act as a restart-safe item store:

<DialectCode title="Stow and recall a held item" file="stash.sw">
<template #natural>

```swoftlang
storage {
    backend: files "data/stash"
    flush: every 10 seconds
}

persistent stash: Map<String> = new_map()

command "stow" {
    execute {
        set stash at sender.name to to_nbt(sender.held_item)
        send "stowed your held item" to sender
    }
}

command "recall" {
    execute {
        set raw to stash[sender.name]
        if raw exists {
            set restored to from_nbt(raw)
            if restored exists {
                send "you stowed ${restored.material} x${restored.amount}" to sender
            }
        } else {
            send "nothing stowed" to sender
        }
    }
}
```

</template>
<template #code>

```swoftlang
storage {
    backend: files "data/stash"
    flush: every 10 seconds
}

persistent stash: Map<String> = new_map()

command "stow" {
    execute {
        stash.set(sender.name, to_nbt(sender.held_item))
        send "stowed your held item" to sender
    }
}

command "recall" {
    execute {
        set raw to stash.get(sender.name)
        if raw exists {
            set restored to from_nbt(raw)
            if restored exists {
                send "you stowed ${restored.material} x${restored.amount}" to sender
            }
        } else {
            send "nothing stowed" to sender
        }
    }
}
```

</template>
</DialectCode>

The [Player Vault example](/examples/player-vault) puts exactly this pattern to work:
every edited vault slot is serialized into one persistent `Map<String>`.

::: tip Where the semantics come from
Maps are backed by `LinkedHashMap<String, Object>` on the Java side, so `keys of m` and
`loop ... as k -> v` visit entries in insertion order. A persistent map is flushed and
reloaded through the same storage backend as any other `persistent` value.
:::
