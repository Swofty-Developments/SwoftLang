---
title: Variables & Types
---

<StepHeader>
a <code>/profile</code> command built from inferred locals, typed interpolation, and a list loop.
</StepHeader>

## `set`

Variables are created by assignment — `set <name> to <expression>`:

```swoftlang
command "vars" {
    execute {
        set count to 3
        set pi to 3.14
        set active to true
        set name to "Swofty"
        set spawn to location(0.5, 42.0, 0.5)
        set sword to item("diamond_sword")
        send "${name} has ${count} lives" to sender
    }
}
```

There are no type annotations on variables. The compiler *infers* the type from the
assignment and tracks it through every branch of your code — that flow tracking is what
powers the narrowing you'll lean on in [Step 07](/1.9.0/guide/options). Reassigning with a
different type is fine; the variable just has the new type from that point on. Using a
variable that was never assigned is a compile error, not a runtime `null`.

<MappedCompare>
<MappedPair label="locals and interpolation">
<template #skript>

```skript
command /profile:
    trigger:
        set {_coins} to 500
        set {_rank} to "Knight"
        send "&6%{_rank}% &f— %{_coins}% coins" to player
```

</template>
<template #swoftlang>

```swoftlang
command "profile" {
    execute {
        set coins to 500
        set rank to "Knight"
        send "<gold>${rank} <white>— ${coins} coins" to sender
    }
}
```

</template>
<template #note>

Skript's `{_underscore}` locals become plain names. Interpolation is `${...}` instead of
`%...%`, takes full expressions, and is typechecked — a typo inside a string is a compile
error, not silent `<none>` output in chat at runtime.

</template>
</MappedPair>
</MappedCompare>

## The types

| Type | Example values | Notes |
|---|---|---|
| `String` | `"hello"`, `"<red>colored"` | supports `${...}` interpolation |
| `Integer` | `42`, `-7` | 64-bit |
| `Double` | `3.14`, `7 / 2.0` | `Integer / Integer` stays integer division |
| `Boolean` | `true`, `false` | |
| `Player` | `sender`, `player` in a `Player` method | a live player on the server |
| `Location` | `location(0.5, 42.0, 0.5)` | immutable position snapshot (x, y, z, yaw, pitch) |
| `Item` | `item("diamond_sword")` | immutable item stack |
| `World` | `world("lobby")`, `world` in a `World` method | a server world instance |
| `List<T>` | `["a", "b", "c"]`, `all_players()` | |
| `Optional<T>` | `player("Notch")`, `none` | present-or-missing — [Step 07](/1.9.0/guide/options) |
| `Either<A\|B>` | argument unions | narrowed with `is a` |

In type *checks*, `Number` matches both `Integer` and `Double`. Later steps add a few
domain types on top — `Mob`, `Display`, `Skin` — each introduced where it's used.

## String interpolation

`${...}` inside a string embeds a value. It takes full expressions, not just variable
names:

```swoftlang
command "interp" {
    execute {
        set n to 41
        set word to "swoft"
        send "next is ${n + 1}"
        send "shouting: ${uppercase(word)}"
        if sender is a Player {
            send "you are at y=${sender.location.y}"
        }
    }
}
```

Interpolated fragments are typechecked like any other expression — misspell a property
inside `${...}` and you get the same compile error you'd get outside a string.

`send` without a target messages the sender; `send ... to all` (or `broadcast`) reaches
everyone. `+` on strings concatenates: `send "total = " + (1 + 2)` — on numbers it adds,
so parenthesize when you mean arithmetic inside a concatenation.

## Lists

```swoftlang
command "lists" {
    execute {
        set words to ["alpha", "beta", "gamma"]
        send "we have ${length(words)} words"
        loop words as w {
            send "word: ${w}"
        }
        loop all_players() as p {
            send "online: ${p.name}"
        }
    }
}
```

`length(...)` works on strings and lists. `loop <list> as x` iterates — `loop all
players as p` is the idiomatic spelling for the online-player list
([Step 05](/1.9.0/guide/control-flow#loop-over-players)).

## Type checks: `is a` / `is not a`

`<expr> is a <Type>` tests a value's runtime type — and the compiler *uses the result*
to narrow types in each branch:

```swoftlang
command "checks" {
    execute {
        set x to 7
        set name to "Swofty"
        if x is a Number {
            send "x is a number"
        }
        if name is not a Number {
            send "name is not a number"
        }
        if sender is a Player {
            send "ping: ${sender.latency}ms"
        }
    }
}
```

`sender.latency` only compiles *inside* the `sender is a Player` branch — at top level
`sender` might be the console. `is an` is accepted wherever `is a` is, so you can write
`is an Integer` and keep your grammar teacher happy.

This narrowing is the same machinery that handles `Either<A|B>` and `Optional<T>` — it
starts doing serious work in [Step 07](/1.9.0/guide/options). First, the control flow those
branches hang off.
