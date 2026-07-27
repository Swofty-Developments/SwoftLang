---
title: Options — No More Null
---

<StepHeader>
a <code>/find</code> command that looks players up by name and can't crash on a miss — because the compiler won't let it.
</StepHeader>

SwoftLang has no null. No `NullPointerException`, no "value was silently empty and your
message rendered as blank". A value that might be absent has type `Optional<T>`, the
absent value is written `none`, and the compiler **proves you handled the missing case
before it lets you touch the value**.

## Where optionals come from

Four places produce an `Optional<T>`:

1. **Builtins that can miss.** `player("Notch")` returns `Optional<Player>` — Notch is
   probably not on your server. Likewise `world(name)` returns `Optional<World>`.
2. **Optional command arguments.** `who: Optional<Player>` is `none` when the caller
   omits it ([Step 02](/1.9.0/guide/commands#arguments)).
3. **Functions with mixed return paths** — some paths `return` a value, some fall off the
   end ([below](#functions-that-might-not-return-a-value)).
4. **Variables assigned on only some branches** ([below](#maybe-assigned-variables)).

And the literal `none` itself, which you can assign directly: `set label to none`.

## What the compiler stops

Try to use a maybe-missing value as if it were there:

<!-- swoftc name=find.sw expect=error -->

<ErrorToggle file="find.sw">
<template #broken>

```swoftlang
command "find" {
    execute {
        set target to player("Notch")
        send "hi ${target.name}" to sender
    }
}
```

</template>
<template #fixed>

```swoftlang
command "find" {
    execute {
        set target to player("Notch")
        if target exists {
            send "hi ${target.name}" to sender
        } else {
            send "<red>Notch is not online" to sender
        }
    }
}
```

</template>
<template #error>

```txt
find.sw:4:14: error: this value is Optional<Player> and may be missing; check it with 'if ... exists' or provide a fallback with 'otherwise'
        send "hi ${target.name}" to sender
             ^
```

</template>
</ErrorToggle>

That's the flagship diagnostic. Note it fired *inside a string interpolation* — `${...}`
fragments are typechecked like any other expression. The error names your two exits:
prove it exists, or provide a fallback.

## Exit 1: `exists` narrowing

`if <expr> exists { ... }` proves presence. Inside the branch, the type is `Player` — not
`Optional<Player>` — and property access is legal. In the `else` branch the compiler
knows it's **missing**, and using it is still an error there:

```swoftlang
command "find" {
    arguments {
        name: String
    }
    execute {
        set target to player(args.name)
        if target exists {
            send "found ${target.name}, ping ${target.latency}ms" to sender
        } else {
            send "<red>nobody called ${args.name} is online" to sender
        }
    }
}
```

The negative test reads the way you'd say it — `is missing` is sugar for `not (... exists)`:

```swoftlang
command "greet" {
    arguments {
        who: Optional<Player>
    }
    execute {
        if args.who is missing {
            send "you didn't name anyone" to sender
            halt
        }
        send "hello ${args.who.name}" to sender
    }
}
```

Narrowing survives the `halt`: after that guard clause, `args.who` is a plain `Player`
for the rest of the body.

## Exit 2: `otherwise` fallbacks

`<optional> otherwise <fallback>` yields the value if present, else the fallback — and
the result type is plain `T`:

```swoftlang
command "title" {
    execute {
        set label to none
        set title to label otherwise "guest"
        send "title = ${title}" to sender
    }
}
```

Chains read left to right; the first present value wins:

```swoftlang
command "pick" {
    execute {
        set victim to player("Alex") otherwise player("Steve") otherwise sender
        send "picked ${victim}" to sender
    }
}
```

`victim` is a plain value (`Player` — `sender` anchors the chain with something that's
always there), immediately usable, no `if` in sight. `otherwise` binds just tighter than
`or`, so conditions like `a otherwise b or c` parse the way they read.

## The same moves, mapped from Skript

In Skript, "might be missing" is a runtime question — you ask `is set` when you remember
to, and get a silent `<none>` in your string when you don't. In SwoftLang it's a type,
and forgetting is a compile error. The two idioms map directly:

<MappedCompare>
<MappedPair label="look up a player by name">
<template #skript>

```skript
command /find <text>:
    trigger:
        set {_target} to player named arg-1
        if {_target} is set:
            send "&a%{_target}% is online"
        else:
            send "&cnobody called %arg-1% is online"
```

</template>
<template #swoftlang>

```swoftlang
command "find" {
    arguments {
        name: String
    }
    execute {
        set target to player(args.name)
        if target exists {
            send "<green>${target.name} is online (${target.latency}ms)" to sender
        } else {
            send "<red>nobody called ${args.name} is online" to sender
        }
    }
}
```

</template>
<template #note>

Skript's `is set` is a runtime check you *may* write; nothing complains if you skip it.
SwoftLang's `exists` is the same check, but skipping it doesn't compile — and inside the
branch the type has genuinely narrowed from `Optional<Player>` to `Player`, so
`target.latency` is legal there and only there.

</template>
</MappedPair>
<MappedPair label="default when the argument is omitted">
<template #skript>

```skript
command /greet [<player>]:
    trigger:
        set {_who} to arg-1
        if {_who} is not set:
            set {_who} to player
        send "&aHello, %{_who}%!" to {_who}
```

</template>
<template #swoftlang>

```swoftlang
command "greet" {
    arguments {
        who: Optional<Player>
    }
    execute {
        set target to args.who otherwise sender
        send "<green>Hello, ${target.name}!" to target
    }
}
```

</template>
<template #note>

The four-line Skript dance is one `otherwise`. And because `sender` is always present,
the result type is plain `Player` — no check needed downstream, and the compiler knows it.

</template>
</MappedPair>
</MappedCompare>

## Functions that might not return a value

```swoftlang
function find_target(name: String) {
    set found to player(name)
    if found exists {
        return found
    }
}

command "hunt" {
    execute {
        set t to find_target("Herobrine")
        if t exists {
            send "target: ${t.name}" to sender
        } else {
            send "no target" to sender
        }
        set safe to find_target("Herobrine") otherwise sender
        send "safe = ${safe}" to sender
    }
}
```

`find_target` returns on one path and falls off the end on the other, so its inferred
return type is `Optional<Player>`. Callers handle it with the exact same two tools. No
annotation needed — the compiler reads the flow.

## Maybe-assigned variables

Assign a variable in only some branches and it's `optional` at the join point:

<!-- swoftc name=label.sw expect=error -->

```swoftlang
command "label" {
    execute {
        if sender is a Player {
            set label to "player"
        }
        send uppercase(label) to sender   // [!code error]
    }
}
```

```txt
label.sw:6:24: error: variable 'label' may not be assigned on all paths; assign it in every branch or check it with 'if label exists'
        send uppercase(label) to sender
                       ^
label.sw:6:24: error: 'uppercase' expects a String here, got Optional<String>
        send uppercase(label) to sender
                       ^
```

Two errors, one story: the flow analysis saw a path where `label` was never assigned,
typed it `Optional<String>`, and then the builtin signature check refused it. Fix it by
assigning in every branch (`else { set label to "console" }`), or treat it as the
optional it is.

## `Either<A|B>` uses the same narrowing

Union types are the sibling feature: a value that is definitely present but could be one
of several types. `is a` / `is not a` narrow them per-branch, exactly like `exists` — and
the `else` branch narrows to *the other* member:

```swoftlang
function describe(dest: Either<Player|Location>) {
    if dest is a Player {
        return "the player ${dest.name}"
    } else {
        return "a location at x=${dest.x}"
    }
}

command "describe" {
    execute {
        send describe(sender) to sender
    }
}
```

Skip the narrowing and:

<!-- swoftc name=visit.sw expect=error -->

```swoftlang
command "visit" {
    arguments {
        dest: Either<Player|Location>
    }
    execute {
        send "heading to x=${args.dest.x}" to sender   // [!code error]
    }
}
```

```txt
visit.sw:6:14: error: cannot access property 'x' on Either<Player|Location>; narrow it first with 'is a'
        send "heading to x=${args.dest.x}" to sender
             ^
```

The two compose: an `Optional<Either<Player|Location>>` narrows first by `exists`, then
by `is a`.

## The rules on one card

| You have | To get the value | Result |
|---|---|---|
| `Optional<T>` | `if x exists { ... }` | `T` inside the branch; known-missing in `else` |
| `Optional<T>` | `if x is missing { halt }` | `T` afterwards |
| `Optional<T>` | `x otherwise fallback` | `T` (first present value) |
| `Either<A\|B>` | `if x is a A { ... }` | `A` inside; `B` in `else` |
| unassigned-on-some-paths | assign on all paths, or treat as optional | plain type |

::: tip Why this matters on a game server
The classic Minecraft-plugin crash is a player object that went stale — someone logged
off between your lookup and your use. SwoftLang can't stop time, but it forces every
lookup that *can* miss to have a written-down answer for the miss, at compile time, with
the error pointing at your line. The runtime never manufactures a null to surprise you
later.
:::
