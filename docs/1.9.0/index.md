---
layout: home
title: SwoftLang
---

<div class="sw-hero">
<p class="sw-hero-kicker">swoftc · OCaml compiler · JVM runtime</p>
<h1 class="sw-hero-title">The Minecraft scripting language that <em>catches your bugs</em> before the server boots.</h1>
<p class="sw-hero-pitch">Write commands, events, GUIs and scoreboards in readable English-flavored syntax. A flow-sensitive typechecker proves every maybe-missing value is handled — at compile time, with the error pointing at your line.</p>
<div class="sw-hero-links">
<a class="sw-btn primary" href="/1.9.0/guide/">Start the guide</a>
<a class="sw-btn" href="/1.9.0/guide/commands">Coming from Skript?</a>
<a class="sw-btn" href="/1.9.0/reference/syntax-cheatsheet">Cheatsheet</a>
</div>
</div>

<ErrorToggle file="warp.sw" error-note="+ 7 more errors downstream of the same missing value">
<template #broken>

<!-- swoftc match=prefix -->

```swoftlang
command "warp" {
    description: "Send someone to spawn"

    arguments {
        who: Optional<Player>
    }

    execute async {
        set target to args.who
        send "<gray>Warping ${target.name} in 3 seconds..." to target
        wait 3 seconds
        teleport target to location(0.5, 64.0, 0.5)
        send "<green>Welcome to spawn, ${target.name}!" to target
    }
}
```

</template>
<template #fixed>

```swoftlang
command "warp" {
    description: "Send someone to spawn"

    arguments {
        who: Optional<Player>
    }

    execute async {
        set target to args.who otherwise sender
        send "<gray>Warping ${target.name} in 3 seconds..." to target
        wait 3 seconds
        teleport target to location(0.5, 64.0, 0.5)
        send "<green>Welcome to spawn, ${target.name}!" to target
    }
}
```

</template>
<template #error>

```txt
warp.sw:10:14: error: this value is Optional<Player> and may be missing; check it with 'if ... exists' or provide a fallback with 'otherwise'
        send "<gray>Warping ${target.name} in 3 seconds..." to target
             ^
```

</template>
</ErrorToggle>

`who` is an optional argument — the caller may omit it. The broken variant uses it as if it were
always there, so `swoftc check` refuses to compile until the miss has a written-down answer.
One `otherwise sender` later, the type is plain `Player` and the script ships. That's the whole
philosophy — [the Options guide](/1.9.0/guide/options) is Step 07.

<div class="pillar">
<div class="pillar-copy">
<p class="pillar-n">01</p>

## Skript, translated function by function

<p>Everything you already know maps over — events, persistent variables, waits. Read your Skript on the left, its SwoftLang on the right, aligned pair by pair.</p>
<p class="more"><a href="/1.9.0/guide/commands">Skript-to-SwoftLang mappings run through the whole guide →</a></p>
</div>
<div class="pillar-code">

<MappedCompare>
<MappedPair label="join event">
<template #skript>

```skript
on join:
    send "&aWelcome, %player%!" to player
    broadcast "&7%player% joined"
```

</template>
<template #swoftlang>

```swoftlang
Player {
    on_join {
        send "<green>Welcome, ${player.name}!" to player
        send "<gray>${player.name} joined" to all
    }
}
```

</template>
</MappedPair>
<MappedPair label="kill counter">
<template #skript>

```skript
on death of monster:
    attacker is a player
    add 1 to {kills::%uuid of attacker%}
    send "&e%{kills::%uuid of attacker%}% kills" to attacker
```

</template>
<template #swoftlang>

```swoftlang
persistent kills for Player: Integer = 0

Mob {
    on_death {
        if killer exists {
            set k to player(killer.uuid)
            if k exists {
                set kills for k to kills for k + 1
                send "<yellow>${kills for k} kills" to k
            }
        }
    }
}
```

</template>
<template #note>

`Mob.on_death` binds `killer` as `Optional<Entity>` — mobs die to lava too, and to
non-players. Skript hands you an `attacker` that might silently be nothing; SwoftLang
won't compile until the `exists` checks are there, and `player(killer.uuid)` resolves the
online player who scores the kill. The `persistent … for Player` declaration replaces the
`{kills::%uuid%}` list-variable idiom: typed, defaulted, and saved across restarts.

</template>
</MappedPair>
<MappedPair label="wait without blocking">
<template #skript>

```skript
command /crate:
    trigger:
        send "&7Opening your crate..." to player
        wait 3 seconds
        send "&aYou won a diamond!" to player
```

</template>
<template #swoftlang>

```swoftlang
command "crate" {
    execute async {
        send "<gray>Opening your crate..." to sender
        wait 3 seconds
        send "<green>You won a diamond!" to sender
    }
}
```

</template>
<template #note>

Same shape, different guarantee: `execute async` parks a virtual thread, never the
tick thread — and moving that `wait` into a sync handler is a compile error, not a
laggy server.

</template>
</MappedPair>
</MappedCompare>

</div>
</div>

<div class="pillar flip">
<div class="pillar-copy">
<p class="pillar-n">02</p>

## The compiler knows your property table

<p>Every <code>this.…</code> property access is checked against the real Minestom-backed property table — with typo suggestions and read-only enforcement, before the server ever boots.</p>
<p class="more"><a href="/1.9.0/guide/properties">Properties guide →</a></p>
</div>
<div class="pillar-code">

<!-- swoftc name=welcome.sw expect=error -->

```swoftlang
Player {
    on_join {
        send "hi ${player.nmae}" to player // [!code error]
    }
}
```

<div class="sw-diag">
<p class="sw-diag-title">swoftc check welcome.sw</p>

```txt
welcome.sw:3:14: error: unknown property 'nmae' on Player; did you mean 'name'?
        send "hi ${player.nmae}" to player
             ^
```

</div>

</div>
</div>

<div class="pillar">
<div class="pillar-copy">
<p class="pillar-n">03</p>

## Async that reads top to bottom

<p>No callbacks, no schedulers, no <code>runTaskLater</code>. <code>wait</code> parks a virtual thread; <code>spawn</code> fires and forgets; async functions return values you can just add.</p>
<p class="more"><a href="/1.9.0/guide/async">Async guide →</a></p>
</div>
<div class="pillar-code">

```swoftlang
command "crate" {
    description: "Open a timed reward crate"

    execute async {
        send "<gray>Opening your crate..." to sender
        wait 3 seconds
        send "<green>You won a diamond!" to sender
        spawn announce(sender.name)
    }
}

async function announce(name: String) {
    wait 1 seconds
    send "<gold>${name} just opened a crate" to all
}
```

</div>
</div>

<div class="pillar flip">
<div class="pillar-copy">
<p class="pillar-n">04</p>

## GUIs are declarations, not inventory-click plumbing

<p>Describe the inventory — rows, slots, items, click handlers — and the runtime renders it, diffs it, and re-renders on state change.</p>
<p class="more"><a href="/1.9.0/reference/gui">GUI reference →</a></p>
</div>
<div class="pillar-code">

```swoftlang
gui "menu" {
    rows: 3
    title: "Server Menu"

    slot 13 {
        item { material: "COMPASS", name: "<aqua>Warp home" }
        on_click {
            send "<gray>Warping..." to player
            close gui for player
        }
    }
}

command "menu" {
    execute {
        open gui "menu" to sender
    }
}
```

</div>
</div>

<div class="pillar">
<div class="pillar-copy">
<p class="pillar-n">05</p>

## State that survives restarts

<p>One keyword. Typed, defaulted, keyed by UUID when you say <code>for Player</code>, flushed write-behind to files, SQLite, MySQL or MongoDB. Reads are never missing.</p>
<p class="more"><a href="/1.9.0/guide/persistence">Persistence guide →</a></p>
</div>
<div class="pillar-code">

```swoftlang
persistent visits for Player: Integer = 0

Player {
    on_join {
        set visits for player to visits for player + 1
        send "<gray>Visit #${visits for player}" to player
    }
}
```

</div>
</div>

<div class="sw-cta">
<p>The guide is a numbered course — 16 steps, one concept each, ending in something runnable.</p>
<a class="sw-btn primary" href="/1.9.0/guide/">Step 01 · Setup</a>
</div>

<p style="margin-top: var(--sp-6)">Or go deeper: <a href="/1.9.0/examples/">full Skript plugins ported line by line</a> and the <a href="/1.9.0/libraries/">standard library addons</a>.</p>
