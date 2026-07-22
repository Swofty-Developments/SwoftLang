---
title: Your First Command
---

<StepHeader>
a complete <code>/give</code> command — named typed arguments, defaults, a permission gate, and a guard clause.
</StepHeader>

A `command` block registers a slash command on the server. The smallest one is a name and
an `execute` block:

```swoftlang
command "ping" {
    execute {
        send "pong" to sender
    }
}
```

`sender` is bound inside every command body — whoever ran the command, a player or the
console. `send <message> to <target>` writes a message; `${...}` interpolation and
`<lime>`-style color tags are covered in [Step 04](/1.4.0/guide/variables-and-types).

The same command, mapped from Skript:

<MappedCompare>
<MappedPair label="hello command">
<template #skript>

```skript
command /hello:
    description: Say hello
    trigger:
        send "&aHello, %player%!" to player
```

</template>
<template #swoftlang>

```swoftlang
command "hello" {
    description: "Say hello"

    execute {
        send "<green>Hello, ${sender}!" to sender
    }
}
```

</template>
<template #note>

`trigger:` becomes `execute { }`, `%player%` becomes `${sender}`, and `&a` color codes
become [MiniMessage](https://docs.advntr.dev/minimessage/format.html) tags like
`<green>`. Skript's `player` is always a player; `sender` may be the console, and the
compiler flags the difference where it matters
([Step 04](/1.4.0/guide/variables-and-types#type-checks-is-a-is-not-a)).

</template>
</MappedPair>
</MappedCompare>

## Permission and description

```swoftlang
command "heal" {
    permission: "myserver.heal"
    description: "Restore your health to full"

    execute {
        if sender is a Player {
            set sender.health to sender.max_health
            send "<lime>Healed!" to sender
        }
    }
}
```

- `permission` — the sender must hold this node or the command is refused (you'll grant
  nodes in [Step 16](/1.4.0/guide/ship-it#permissions)).
- `description` — shows up in command listings; also good documentation.

Both are optional.

## Aliases

Chaining `command` headers gives one body several names, and the short form drops the
repeated keyword:

```swoftlang
command "tp",
command "teleport" {
    execute {
        send "same body, two names" to sender
    }
}

command "gm", "gamemode" {
    execute {
        send "short alias form" to sender
    }
}
```

Either way the loader registers one command per name, sharing the body.

## Arguments

Declare typed arguments in an `arguments` block. Each line is `name: Type`, optionally
with `= default`:

```swoftlang
command "give" {
    permission: "myserver.give"
    description: "Give an item to a player"

    arguments {
        material: String
        amount: Integer = 1
        target: Player = sender
    }

    execute {
        set stack to item(args.material, args.amount)
        send "gave ${args.target.name} ${args.amount}x ${args.material}" to sender
    }
}
```

An argument with a default is optional on the command line; one without is required. So
`/give diamond` works (amount `1`, target you), and so does `/give diamond 64 Swofty`.

Arguments live under the `args` root: `args.material`, `args.target`. Deep paths like
`args.target.name` go through the [property system](/1.4.0/guide/properties) and are checked
against the declared argument type at compile time.

The base types are `String`, `Integer`, `Double`, `Boolean`, `Player`, and `Location` —
[Step 04](/1.4.0/guide/variables-and-types) has the full type system. Two more argument shapes
are worth knowing now and understanding later:

- `dest: either<Player|Location>` — accepts more than one type; you tell them apart with
  `is a` ([Step 07](/1.4.0/guide/options#either-a-b-uses-the-same-narrowing)).
- `who: optional<Player>` — the argument may be absent, and the type system makes you
  deal with that ([Step 07](/1.4.0/guide/options) is entirely about this).

<MappedCompare>
<MappedPair label="typed arguments with defaults">
<template #skript>

```skript
command /give <text> [<integer=1>] [<player=%player%>]:
    trigger:
        send "&aGave %arg-3% %arg-2%x %arg-1%" to player
```

</template>
<template #swoftlang>

```swoftlang
command "give" {
    arguments {
        material: String
        amount: Integer = 1
        target: Player = sender
    }
    execute {
        send "<green>Gave ${args.target.name} ${args.amount}x ${args.material}" to sender
    }
}
```

</template>
<template #note>

Skript's positional `<text> [<integer=1>]` with `arg-1`, `arg-2` becomes a named, typed
`arguments` block. A default makes an argument optional, and every use site says
`args.amount`, not "the second one" — get the order wrong and it's a compile error, not
a scrambled message.

</template>
</MappedPair>
</MappedCompare>

## Bailing out early

`halt` stops the script immediately — the idiomatic guard-clause exit:

```swoftlang
command "smite" {
    arguments {
        victim: either<Player|Location>
    }
    execute {
        if args.victim is not a Player {
            send "<red>You can only smite players" to sender
            halt
        }
        send "<gold>Smitten." to sender
    }
}
```

Guards, loops, and the rest of the control-flow toolkit are
[Step 05](/1.4.0/guide/control-flow); first, the other way scripts get triggered.
