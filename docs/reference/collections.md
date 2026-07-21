# Collections & Strings

Lists, maps, and Strings each speak **two coexisting dialects** for the operations they
share. A *natural-language* phrasing reads like English — `add x to l`, `size of l`,
`sorted l`, `uppercase of s` — and a *method* phrasing calls `receiver.method(args)`. Both
compile to exactly the same runtime; reach for whichever reads better at the call site.
The switch below flips every example on this page between the two.

A method resolves by the receiver's static type — the compiler knows a `list<Integer>`
from a `map<String, V>` from a `String` and offers only that type's methods, checking
argument types and arity at compile time. Operations split into two shapes:

- **Pure / query forms** return a value and never touch the receiver — `sorted l` /
  `l.sorted()`, `size of m` / `m.size`, `uppercase of s` / `s.upper()`. Use them anywhere
  an expression is allowed.
- **Mutating forms** change the receiver in place and are written as bare statements —
  `add x to l` / `l.add(x)`, `clear l` / `l.clear()`. They have no result, so they cannot
  appear inside an expression.

The richer transforms (`.filtered`, `.mapped`, `.joined`, `.get_or`, …) have no
natural-language spelling and stay in method form — they are listed in the reference
tables below.

<DialectSwitch />

## Accessors {#accessors}

The size and endpoint accessors read a collection without changing it:

| Natural language | Method / property | On | Returns |
|---|---|---|---|
| `size of c` | `c.size` | list, map, String | `Integer` |
| `first of l` | `l.first` | list | `optional<T>` |
| `last of l` | `l.last` | list | `optional<T>` |
| `keys of m` | `m.keys` | map | `list<K>` |
| `values of m` | `m.values` | map | `list<V>` |
| `length of s` | `s.length` | String | `Integer` |
| — | `c.is_empty` | list, map | `Boolean` |

<DialectCode title="Peek at a list" file="accessors.sw">
<template #natural>

```swoftlang
command "accessors" {
    execute {
        set nums to [10, 20, 30]
        send "size ${size of nums}, empty ${nums.is_empty}" to sender
        send "first ${first of nums otherwise 0}, last ${last of nums otherwise 0}" to sender
    }
}
```

</template>
<template #code>

```swoftlang
command "accessors" {
    execute {
        set nums to [10, 20, 30]
        send "size ${nums.size}, empty ${nums.is_empty}" to sender
        send "first ${nums.first otherwise 0}, last ${nums.last otherwise 0}" to sender
    }
}
```

</template>
</DialectCode>

## Lists {#lists}

### Mutating a list {#list-mut}

The four in-place edits with a natural spelling:

| Natural language | Method | Effect |
|---|---|---|
| `add x to l` | `l.add(x)` | append `x` |
| `remove x from l` | `l.remove(x)` | remove the first occurrence of `x` |
| `clear l` | `l.clear()` | remove everything |

<DialectCode title="Build up a list" file="list-mut.sw">
<template #natural>

```swoftlang
command "list-mut" {
    execute {
        set nums to [3, 1, 2]
        add 4 to nums
        remove 1 from nums
        add 9 to nums
        send "size ${size of nums}" to sender
    }
}
```

</template>
<template #code>

```swoftlang
command "list-mut" {
    execute {
        set nums to [3, 1, 2]
        nums.add(4)
        nums.remove(1)
        nums.add(9)
        send "size ${nums.size}" to sender
    }
}
```

</template>
</DialectCode>

The remaining mutators are method-only: `l.add_all(other)` appends every element of
another list, `l.remove_at(i)` drops the element at an index, and `l.insert(i, x)` splices
`x` in at position `i`.

### Querying & transforming {#list-expr}

Membership, sorting, and reversal each have a natural form; the rest are method-only:

| Natural language | Method | Returns |
|---|---|---|
| `l contains x` | `l.contains(x)` | `Boolean` |
| `sorted l` | `l.sorted()` | `list<T>` |
| `sorted l by <fn>` | `l.sorted_by(fn)` | `list<T>` |
| `reversed l` | `l.reversed()` | `list<T>` |

<DialectCode title="Sort and search" file="list-query.sw">
<template #natural>

```swoftlang
command "list-query" {
    execute {
        set nums to [3, 1, 2]

        if nums contains 3 {
            send "has 3" to sender
        }
        set up to sorted nums
        set ranked to sorted nums by function(n: Integer) { return 0 - n }
        set down to reversed nums
        send "sorted ${up.size}, ranked ${ranked.size}, reversed ${down.size}" to sender
    }
}
```

</template>
<template #code>

```swoftlang
command "list-query" {
    execute {
        set nums to [3, 1, 2]

        if nums.contains(3) {
            send "has 3" to sender
        }
        set up to nums.sorted()
        set ranked to nums.sorted_by(function(n: Integer) { return 0 - n })
        set down to nums.reversed()
        send "sorted ${up.size}, ranked ${ranked.size}, reversed ${down.size}" to sender
    }
}
```

</template>
</DialectCode>

These further transforms are method-only — each returns a new value and leaves the
receiver alone:

| Method | Returns | Notes |
|---|---|---|
| `.index_of(x)` | `optional<Integer>` | position of `x`, or `none` |
| `.get(i)` | `optional<T>` | element at index `i`, or `none` |
| `.count(x)` | `Integer` | how many times `x` occurs |
| `.joined(sep)` | `String` | join elements with `sep` |
| `.sorted_by_desc(key)` | `list<T>` | by a `key(elem)` lambda, descending |
| `.shuffled()` | `list<T>` | randomly shuffled copy |
| `.filtered(pred)` | `list<T>` | elements where `pred(elem)` is true |
| `.mapped(fn)` | `list<U>` | `fn(elem)` over every element |
| `.taken(n)` | `list<T>` | first `n` elements |
| `.dropped(n)` | `list<T>` | all but the first `n` |
| `.min_by(key)` | `optional<T>` | element with the smallest key |
| `.max_by(key)` | `optional<T>` | element with the largest key |

The lambda methods take the element type; `.filtered` needs a `Boolean` lambda, `.sorted_by`
/ `.min_by` / `.max_by` a comparable (number or String) key, and `.mapped` may return any
type, which becomes the new list's element type.

```swoftlang
command "list-methods" {
    execute {
        set nums to [3, 1, 2]

        set idx to nums.index_of(2) otherwise 0 - 1
        set joined to nums.joined(", ")
        set evens to nums.filtered(function(n: Integer) { return n % 2 == 0 })
        set doubled to nums.mapped(function(n: Integer) { return n * 2 })
        set top to nums.max_by(function(n: Integer) { return n }) otherwise 0
        set some to nums.taken(2)
        send "idx ${idx}, joined ${joined}, top ${top}" to sender
        send "evens ${evens.size}, doubled ${doubled.size}, some ${some.size}" to sender
    }
}
```

## Maps {#maps}

The full set of map operations — reads, writes, membership, `keys of` / `values of`,
deletion, and `clear` — is covered in both dialects on the [Maps page](./maps#operations).
Beyond those, maps carry method-only helpers. Reads return an `optional<V>` because the key
may be absent — narrow with `exists` or supply an `otherwise`; `.get_or(k, default)` bakes
the fallback in and returns a plain `V`.

| Method | Returns | Notes |
|---|---|---|
| `.get_or(k, default)` | `V` | value for `k`, else `default` |
| `.put_all(other)` | — | copy every entry of another map |
| `.sorted_by_key()` | `map<K, V>` | new map, ordered by key ascending |
| `.sorted_by_key_desc()` | `map<K, V>` | ordered by key descending |
| `.sorted_by_value()` | `map<K, V>` | ordered by value ascending |
| `.sorted_by_value_desc()` | `map<K, V>` | ordered by value descending |
| `.sorted_by(key)` | `map<K, V>` | ordered by a `key(k, v)` lambda, ascending |

```swoftlang
command "map-methods" {
    execute {
        set scores to { "alice": 10, "bob": 7 }
        scores.put_all({ "dan": 1 })

        set safe to scores.get_or("zoe", 0)
        set byval to scores.sorted_by_value_desc()
        set bykey to scores.sorted_by(function(k: String, v: Integer) { return v })
        send "safe ${safe}, keys ${keys of scores}, values ${values of scores}" to sender
        send "byval ${byval.size}, bykey ${bykey.size}" to sender
    }
}
```

## Strings {#strings}

Strings are immutable, so every String operation is a pure expression that returns a new
String, list, or scalar. Case conversion and length carry a natural spelling:

| Natural language | Method | Returns |
|---|---|---|
| `uppercase of s` | `s.upper()` | `String` |
| `lowercase of s` | `s.lower()` | `String` |
| `length of s` | `s.length()` | `Integer` |

<DialectCode title="Normalise a string" file="strings.sw">
<template #natural>

```swoftlang
command "strings" {
    execute {
        set greeting to "  Hello, World  "
        set clean to greeting.trimmed()
        set up to uppercase of clean
        send "clean '${up}' len ${length of clean}" to sender
    }
}
```

</template>
<template #code>

```swoftlang
command "strings" {
    execute {
        set greeting to "  Hello, World  "
        set clean to greeting.trimmed()
        set up to clean.upper()
        send "clean '${up}' len ${clean.length()}" to sender
    }
}
```

</template>
</DialectCode>

Everything else is method-only:

| Method | Returns | Notes |
|---|---|---|
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
command "string-methods" {
    execute {
        set clean to "Hello, World"
        set parts to clean.split(", ")
        set rep to "ab".repeated(3)
        set starts to clean.starts_with("Hello")
        send "parts ${parts.size}, rep ${rep}, starts ${starts}" to sender
    }
}
```
