---
title: NPCs
---

# NPCs

An `npc` block declares a standing player NPC: a location, an overhead name, a skin, an
optional head-tracking toggle, and inline click handlers. The runtime builds it from a
fake player entry — spawn packets in, tab-list entry pulled back out after a couple of
ticks — and drives head rotation with real engine trigonometry. You declare it; the
engine spawns it at boot.

```swoftlang
npc "guide" {
    location: location(5, 64, 5)
    name: "<green>Village Guide"
    skin: "Notch"
    look_at_players: true
    on_click(player) {
        send "<yellow>Hello ${player.name}!" to player
    }
}
```

## Declaration keys

| Key | Type | Required | Meaning |
|---|---|---|---|
| `location:` | `Location` | **yes** | where it stands |
| `name:` | `String` | no | overhead name; per-viewer when it interpolates `player.*` |
| `skin:` | skin source | no | a username `String` or `skin(texture, signature)` |
| `look_at_players:` | `Boolean` | no | head tracks the nearest player (default `false`) |
| `on_click(p) { ... }` | handler | no | right-click interact; binds the clicking `Player` |
| `on_left_click(p) { ... }` | handler | no | left-click / attack; binds the clicking `Player` |

The click parameter is yours to name — `on_click(player)`, `on_left_click(clicker)` —
and is a `Player`, bound for the duration of the handler exactly like a command body.
Both handlers run on the tick thread.

## Skins

A skin is either a **username** the engine fetches once at boot (cached), or a raw
`skin(texture, signature)` pair — the same [`skin`](./builtins#skin) value the rest of
the language uses:

```swoftlang
npc "notch_clone" {
    location: location(5, 64, 5)
    skin: "Notch"
}

npc "custom" {
    location: location(8, 64, 8)
    skin: skin("ewogICJ0ZXh0dXJlcyI=", "sig-bytes-here")
}
```

## Per-viewer name

Like a hologram line, the overhead `name` becomes **per-viewer** when it interpolates a
player-scoped path — each player sees the name rendered for them, over a team packet:

```swoftlang
npc "greeter" {
    location: location(5, 64, 5)
    name: "<green>Guide (${player.name})"
    skin: "Notch"
    on_click(clicker) {
        send "<yellow>Welcome, ${clicker.name}!" to clicker
    }
}
```

## Statements

Every NPC statement addresses a declared NPC by name:

| Statement | Effect |
|---|---|
| `set npc "name" skin <source>` | reskin — a username `String` or `skin(...)` |
| `set npc "name" name <string>` | change the overhead name |
| `set npc "name" location <location>` | move it |
| `remove npc "name"` | despawn it everywhere and stop head tracking |

```swoftlang
npc "guide" {
    location: location(5, 64, 5)
    skin: "Notch"
}

command "reassign" {
    execute {
        set npc "guide" skin "Herobrine"
        set npc "guide" name "<red>Renamed Guide"
        set npc "guide" location location(6, 64, 6)
    }
}
```

NPCs are cleaned up on engine reload, shutdown, and per-viewer on disconnect.

## Coming from an NPC plugin

<MappedCompare title="A skinned, clickable NPC" leftLabel="Spigot + Citizens" rightLabel="SwoftLang">
<MappedPair label="spawn and wire a click">
<template #skript>

```yaml
# Citizens: /npc create Guide, /npc skin Notch, /npc lookclose,
# then a Denizen/Skript hook for the click:
on right click on npc:
    if {_npc}'s name is "Guide":
        send "<yellow>Hello %player%!" to player
```

</template>
<template #swoftlang>

```swoftlang
npc "guide" {
    location: location(5, 64, 5)
    name: "<green>Village Guide"
    skin: "Notch"
    look_at_players: true
    on_click(player) {
        send "<yellow>Hello ${player.name}!" to player
    }
}
```

</template>
<template #note>

Citizens spawns the NPC from chained commands and needs a second plugin to react to a
click. Here the NPC, its skin, its head tracking, and both click handlers are one
declaration the compiler checks — and `${player.name}` in the handler or the name is a
typed `Player`, not a placeholder string.

</template>
</MappedPair>
</MappedCompare>

## Diagnostics

Declaring two NPCs with the same name is a compile error:

```
duplicate_npc.sw:5:1: error: duplicate npc "dup"
```

::: tip Supersedes the `npcs` addon
This first-class construct replaces the retired
[`npcs` addon](/libraries/npcs) — the ~400-line one that hand-rolled the spawn packets,
an `atan2`/`sqrt` head-look, and a closure-chain registry. That `import "npcs"` API is
gone; declare `npc` blocks instead — the packet plumbing and the head trigonometry move
into the runtime, and click handlers are inline typed bodies rather than first-class
functions crossing a module boundary.
:::
