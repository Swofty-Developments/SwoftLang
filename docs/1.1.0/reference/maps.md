# Maps

A `map<K, V>` is a dictionary from keys of type `K` to values of type `V`. The key type
is `String`, `Integer`, or `Player`; `map<V>` with one type argument is shorthand for
`map<String, V>`. The value type is inferred from a literal or written explicitly. Maps
are mutable reference values — passing one to a function and mutating it there is visible
to the caller — and a `map` of a scalar value type can be `persistent`, so a whole
dictionary survives a restart.

```swoftlang
command "counts" {
    execute {
        // literal — V is inferred as Integer from the values
        set counts to { "a": 1, "b": 2, "c": 3 }

        map_set(counts, "d", 4)          // builtin write
        set counts at "e" to 5           // index-set sugar for the same thing

        set a to counts["a"] otherwise 0 // index-read yields optional<V>
        send "a is ${a}, size is ${map_size(counts)}" to sender

        map_delete(counts, "b")
    }
}
```

## Building a map {#building}

| Form | Result | Notes |
|---|---|---|
| `{ "k": v, ... }` | `map<String, V>` | String keys; `V` is the join of the value types |
| `{ 1: v, ... }` | `map<Integer, V>` | Integer-literal keys |
| `new_map()` | `map<Any, Any>` | an empty map; key and value narrow from context |

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
index sugar, the `map_*` builtins, and both loop forms take a key of the map's `K`, and
`map_keys` returns a `list<K>`.

An **Integer-keyed** map — `map<Integer, V>`, inferred from an integer-literal
dictionary or written out:

```swoftlang
command "intkeys" {
    execute {
        set names to { 1: "one", 2: "two", 3: "three" }

        map_set(names, 4, "four")        // Integer key
        set names at 5 to "five"         // index-set sugar, Integer key

        set first to names[1] otherwise "none"
        send "first ${first}" to sender

        loop names as num -> word {      // key is an Integer, value a String
            send "${num} = ${word}" to sender
        }
    }
}
```

A **Player-keyed** map — `map<Player, V>`. Players serialize by UUID on the Java side, so
a Player-keyed map is `persistent`-safe; the compiler just types the key as `Player`:

```swoftlang
command "pmap" {
    execute {
        set wins to new_map()

        set wins at sender to 10         // first insertion fixes K = Player, V = Integer
        set mine to wins[sender] otherwise 0
        send "you have ${mine}" to sender

        loop wins as who -> pts {         // key is a Player
            send "${who.name}: ${pts}" to sender
        }
    }
}
```

Passing a key of the wrong type is a compile error naming the key type the map expects:

```
map_int_key_on_string.sw:4:31: error: 'map_has' expects a String key here (got Integer)
```

## Operations {#operations}

| Operation | Builtin | Sugar | Result |
|---|---|---|---|
| read | `map_get(m, k)` | `m[k]` | `optional<V>` |
| write | `map_set(m, k, v)` | `set m at k to v` | — |
| test | `map_has(m, k)` | — | `Boolean` |
| remove | `map_delete(m, k)` | — | — |
| keys | `map_keys(m)` | — | `list<K>` |
| size | `map_size(m)` | — | `Integer` |

Reads return an `optional<V>` because the key may be absent — the compiler makes you
account for that with `exists` or `otherwise`:

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

`map_set` type-checks the value against `V`; a mismatched value is a compile error:

<!-- swoftc name=badval.sw expect=error -->

```swoftlang
command "bad" {
    execute {
        set counts to { "a": 1 }
        map_set(counts, "b", "two")      // [!code error]
    }
}
```

```txt
badval.sw:4:30: error: 'map_set' expects a Integer value (got String)
        map_set(counts, "b", "two")
                             ^
```

## Iterating {#iterating}

`loop map_keys(m) as k` walks the keys as a plain `list<String>`; the dedicated
`loop m as key -> value` form binds the String key and the `V` value per entry:

```swoftlang
command "dump" {
    execute {
        set counts to { "a": 1, "b": 2 }

        loop map_keys(counts) as key {
            send "key ${key}" to sender
        }

        loop counts as name -> amount {
            send "${name} = ${amount}" to sender
        }
    }
}
```

## Persistence {#persistence}

A map whose values are `String`, `Integer`, `Double`, or `Boolean` can be declared
`persistent`, for any key type — `String`, `Integer`, and `Player` (by UUID) all
serialize. It writes to the [storage backend](./server-config#storage-phase-3)
as JSON and is reloaded on boot, so the whole dictionary survives restarts. Writes
through the map (including `set m at k to v`) mutate the stored value in place:

```swoftlang
storage {
    backend: files "data/game"
    flush: every 10 seconds
}

persistent leaderboard: map<Integer> = new_map()

command "score" {
    arguments { amount: Integer }
    execute {
        set leaderboard at sender.name to (leaderboard[sender.name] otherwise 0) + args.amount
        send "total ${leaderboard[sender.name] otherwise 0}" to sender
    }
}
```

### Storing items across restarts {#items}

A scalar map can hold item stacks by serializing them: `to_nbt(item)` turns an `Item`
into its NBT `String`, and `from_nbt(string)` parses one back — as an
`optional<Item>`, because the text might be malformed. The round-trip lets a persistent
`map<String>` act as a restart-safe item store:

```swoftlang
storage {
    backend: files "data/stash"
    flush: every 10 seconds
}

persistent stash: map<String> = new_map()

command "stow" {
    execute {
        map_set(stash, sender.name, to_nbt(sender.held_item))
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

The [Player Vault example](/1.1.0/examples/player-vault) puts exactly this pattern to work:
every edited vault slot is serialized into one persistent `map<String>`.

::: tip Where the semantics come from
Maps are backed by `LinkedHashMap<String, Object>` on the Java side, so `map_keys` and
`loop ... as k -> v` visit entries in insertion order. A persistent map is flushed and
reloaded through the same storage backend as any other `persistent` value.
:::
