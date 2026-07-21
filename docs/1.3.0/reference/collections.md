# Collections & Strings

Lists, maps, and Strings all carry **methods** you call with `receiver.method(args)`. A
method resolves by the receiver's static type — the compiler knows a `list<Integer>` from
a `map<String, V>` from a `String` and offers only that type's methods, checking argument
types and arity at compile time.

Methods come in two kinds:

- **Pure expression methods** return a value and never touch the receiver — `nums.sorted()`,
  `scores.get("k")`, `name.upper()`. Use them anywhere an expression is allowed.
- **Mutating statement methods** change the receiver in place and are written as bare
  statements — `nums.add(4)`, `scores.delete("bob")`. They have no result, so they cannot
  appear inside an expression.

The method forms are a second entry point to the same runtime as the free builtins
([`sort`](./builtins#sorting), [`map_get`](./maps#operations), [`uppercase`](./builtins#uppercase-lowercase),
…), which keep working. Reach for whichever reads better at the call site.

## Accessors {#accessors}

The zero-argument accessors stay in **property form** — no parentheses:

| Property | On | Returns | Notes |
|---|---|---|---|
| `.size` | list, map, String | `Integer` | element / entry / character count |
| `.is_empty` | list, map | `Boolean` | |
| `.first` | list | `optional<T>` | `none` when empty |
| `.last` | list | `optional<T>` | `none` when empty |
| `.keys` | map | `list<K>` | insertion order |
| `.values` | map | `list<V>` | insertion order |
| `.length` | String | `Integer` | same as `.size`; also spelled `.length()` |

```swoftlang
command "accessors" {
    execute {
        set nums to [10, 20, 30]
        send "size ${nums.size}, empty ${nums.is_empty}" to sender
        send "first ${nums.first otherwise 0}, last ${nums.last otherwise 0}" to sender
    }
}
```

## Lists {#lists}

### Expression methods {#list-expr}

| Method | Returns | Notes |
|---|---|---|
| `.contains(x)` | `Boolean` | membership test |
| `.index_of(x)` | `optional<Integer>` | position of `x`, or `none` |
| `.get(i)` | `optional<T>` | element at index `i`, or `none` |
| `.count(x)` | `Integer` | how many times `x` occurs |
| `.joined(sep)` | `String` | join elements with `sep` |
| `.sorted()` | `list<T>` | natural ascending copy |
| `.sorted_by(key)` | `list<T>` | by a `key(elem)` lambda, ascending |
| `.sorted_by_desc(key)` | `list<T>` | same, descending |
| `.reversed()` | `list<T>` | reversed copy |
| `.shuffled()` | `list<T>` | randomly shuffled copy |
| `.filtered(pred)` | `list<T>` | elements where `pred(elem)` is true |
| `.mapped(fn)` | `list<U>` | `fn(elem)` over every element |
| `.taken(n)` | `list<T>` | first `n` elements |
| `.dropped(n)` | `list<T>` | all but the first `n` |
| `.min_by(key)` | `optional<T>` | element with the smallest key |
| `.max_by(key)` | `optional<T>` | element with the largest key |

All of these are non-mutating — they return a new value and leave the receiver alone. The
lambda methods take the element type; `.filtered` needs a `Boolean` lambda, `.sorted_by` /
`.min_by` / `.max_by` a comparable (number or String) key, and `.mapped` may return any
type, which becomes the new list's element type.

```swoftlang
command "list-expr" {
    execute {
        set nums to [3, 1, 2]

        if nums.contains(3) {
            send "has 3" to sender
        }
        set idx to nums.index_of(2) otherwise 0 - 1
        set third to nums.get(2) otherwise 0
        set joined to nums.joined(", ")
        send "third ${third}, idx ${idx}, joined ${joined}" to sender

        set sorted to nums.sorted()
        set ranked to nums.sorted_by(function(n: Integer) { return n })
        set evens to nums.filtered(function(n: Integer) { return n % 2 == 0 })
        set doubled to nums.mapped(function(n: Integer) { return n * 2 })
        set top to nums.max_by(function(n: Integer) { return n }) otherwise 0
        set some to nums.taken(2)
        send "sorted ${sorted.size}, evens ${evens.size}, doubled ${doubled.size}" to sender
        send "top ${top}, some ${some.size}" to sender
    }
}
```

### Mutating methods {#list-mut}

These change the list in place and are written as statements:

| Statement | Effect |
|---|---|
| `list.add(x)` | append `x` |
| `list.add_all(other)` | append every element of another list |
| `list.remove(x)` | remove the first occurrence of `x` |
| `list.remove_at(i)` | remove the element at index `i` |
| `list.insert(i, x)` | insert `x` at index `i` |
| `list.clear()` | remove everything |

```swoftlang
command "list-mut" {
    execute {
        set nums to [3, 1, 2]
        nums.add(4)
        nums.add_all([5, 6])
        nums.remove(1)
        nums.insert(0, 9)
        send "size ${nums.size}" to sender
    }
}
```

## Maps {#maps}

Method forms complement the [`map_*` builtins and index sugar](./maps). Reads return an
`optional<V>` because the key may be absent — narrow with `exists` or supply an `otherwise`;
`.get_or(k, default)` bakes the fallback in and returns a plain `V`.

### Expression methods {#map-expr}

| Method | Returns | Notes |
|---|---|---|
| `.get(k)` | `optional<V>` | value for `k`, or `none` |
| `.get_or(k, default)` | `V` | value for `k`, else `default` |
| `.has(k)` | `Boolean` | key present |
| `.sorted_by_key()` | `map<K, V>` | new map, ordered by key ascending |
| `.sorted_by_key_desc()` | `map<K, V>` | ordered by key descending |
| `.sorted_by_value()` | `map<K, V>` | ordered by value ascending |
| `.sorted_by_value_desc()` | `map<K, V>` | ordered by value descending |
| `.sorted_by(key)` | `map<K, V>` | ordered by a `key(k, v)` lambda, ascending |

### Mutating methods {#map-mut}

| Statement | Effect |
|---|---|
| `map.set(k, v)` | insert or overwrite the entry for `k` |
| `map.delete(k)` | remove the entry for `k` |
| `map.put_all(other)` | copy every entry of another map |
| `map.clear()` | remove every entry |

```swoftlang
command "map-methods" {
    execute {
        set scores to { "alice": 10, "bob": 7 }
        scores.set("carol", 3)
        scores.delete("bob")
        scores.put_all({ "dan": 1 })

        set alice to scores.get("alice") otherwise 0
        set safe to scores.get_or("zoe", 0)
        if scores.has("alice") {
            send "has alice" to sender
        }
        set byval to scores.sorted_by_value_desc()
        set bykey to scores.sorted_by(function(k: String, v: Integer) { return v })
        send "map ${scores.size}, keys ${scores.keys.size}, values ${scores.values.size}" to sender
        send "alice ${alice}, safe ${safe}, byval ${byval.size}, bykey ${bykey.size}" to sender
    }
}
```

## Strings {#strings}

Every String method is a pure expression — Strings are immutable, so each method returns a
new String, list, or scalar.

| Method | Returns | Notes |
|---|---|---|
| `.length()` | `Integer` | character count (or the `.length` / `.size` property) |
| `.upper()` | `String` | uppercase |
| `.lower()` | `String` | lowercase |
| `.trimmed()` | `String` | strip leading/trailing whitespace |
| `.contains(s)` | `Boolean` | substring test |
| `.starts_with(s)` | `Boolean` | prefix test |
| `.ends_with(s)` | `Boolean` | suffix test |
| `.replace(from, to)` | `String` | replace every `from` with `to` |
| `.split(sep)` | `list<String>` | split on `sep` |
| `.substring(start, end)` | `String` | characters `[start, end)` |
| `.index_of(s)` | `optional<Integer>` | position of `s`, or `none` |
| `.repeated(n)` | `String` | the String repeated `n` times |
| `.reversed()` | `String` | characters reversed |
| `.padded_left(n, pad)` | `String` | left-pad to width `n` with `pad` |
| `.padded_right(n, pad)` | `String` | right-pad to width `n` with `pad` |
| `.first_chars(n)` | `String` | first `n` characters (clamped) |
| `.last_chars(n)` | `String` | last `n` characters (clamped) |

```swoftlang
command "strings" {
    execute {
        set greeting to "  Hello, World  "
        set clean to greeting.trimmed()
        set parts to clean.split(", ")
        set up to clean.upper()
        set rep to "ab".repeated(3)
        set starts to clean.starts_with("Hello")
        send "clean '${up}' len ${clean.length()}" to sender
        send "parts ${parts.size}, rep ${rep}, starts ${starts}" to sender
    }
}
```
