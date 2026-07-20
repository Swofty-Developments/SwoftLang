---
title: Blocks
---

# Blocks

A `block(...)` value is a full block state — an id plus every property that block
carries (a stair's `facing` and `half`, a slab's `type`, a log's `axis`) and an optional
NBT tag payload. You build one immutably, place it into the world, read one back, and
register handlers that fire when a block is placed, broken, clicked, or ticked. Minestom
ships **zero** default placement behaviour, so orientation and connection rules are yours
to author with `placement_rule` — or you import the ready-made
[vanilla-placement addon](#the-vanilla-placement-addon).

```swoftlang
command "blocks" {
    execute {
        set b to block("oak_stairs", {facing: "north", half: "top"})
        set dir to b.property("facing")
        set block at sender.location to b
        send "placed ${b.id} facing ${dir}" to sender
    }
}
```

## Constructing a block value

`block("id")` gives the block's default state; the two-argument form seeds properties
from a map literal. The id may be given bare (`"oak_stairs"`) or namespaced
(`"minecraft:oak_stairs"`).

```swoftlang
command "make" {
    execute {
        set plain to block("oak_stairs")
        set posed to block("oak_stairs", {facing: "north", half: "top", waterlogged: "false"})
        set dir to posed.property("facing")
        send "${plain.id} / ${dir}" to sender
    }
}
```

Property values are always strings — `"true"` / `"false"` for booleans, `"north"` for
enums, `"8"` for numbers — matching the vanilla blockstate vocabulary.

## Block methods

Every method returns a **new** block; the receiver is never mutated. Chain `with` to pose
a block up in one expression.

| Method | Returns | Meaning |
|---|---|---|
| `b.with("prop", "val")` | `Block` | a copy with one property set |
| `b.property("prop")` | `String` | the current value of a property |
| `b.properties` | `map<String, String>` | every property as a map |
| `b.id` | `String` | the namespaced block key (`minecraft:oak_stairs`) |
| `b.nbt` | `String` | the block-entity NBT as SNBT (`{}` when none) |
| `b.with_nbt("{…}")` | `Block` | a copy carrying the given SNBT payload |
| `b.get_tag("key")` | `String` | one custom tag value |
| `b.with_tag("key", "val")` | `Block` | a copy with one custom tag set |

```swoftlang
command "inspect" {
    execute {
        set b to block("oak_stairs")
            .with("facing", "east")
            .with("half", "top")
        set facing to b.property("facing")
        set props to b.properties
        set kind to b.id
        set b to b.with_nbt("{}")
        set b to b.with_tag("owner", "swofty")
        set tag to b.get_tag("owner")
        send "${kind} facing ${facing}, owner ${tag}" to sender
    }
}
```

## Compile-time state validation

Block ids, property names, and property values are checked against the real block
registry at compile time, so a typo never survives to runtime. An unknown block:

```
w_block.sw:3:24: error: unknown block "not_a_real_block" in block(...)
```

An unknown property — the diagnostic lists what the block actually accepts:

```
w_block.sw:3:49: error: block "minecraft:oak_stairs" has no property 'nonsense'; valid properties: facing, half, shape, waterlogged
```

An out-of-range value — again with the valid set spelled out:

```
w_block.sw:3:47: error: 'sideways' is not a valid value for property 'facing' of block "minecraft:oak_stairs"; valid values: east, north, south, west
```

The same check runs on the `.with(...)` key, so `block("oak_stairs").with("nonsense", "x")`
is rejected exactly like the map form.

## Placing and reading blocks

These statements edit the blocks inside a loaded [world](./worlds). `set block at`,
`fill blocks`, and `place ... at` accept either a plain id string or a posed `block(...)`;
`block_at` reads one back as a `Block` you can call methods on.

| Form | Effect |
|---|---|
| `set block at <location> to "STONE"` | place one block |
| `place <Block\|"id"> at <location>` | place one block (same effect as `set block at ... to`) |
| `remove block at <location>` | clear the block, and cancel any tasks bound to that position |
| `fill blocks from <loc> to <loc> with "GLASS"` | fill the box between two corners |
| `block_at(<location>)` | `Block` — the block at that spot (`.id` is its key) |

```swoftlang
command "place" {
    execute {
        set here to block_at(sender.location)
        set block at sender.location to block("oak_stairs", {facing: "north"})
        fill blocks from location(0, 63, 0) to location(2, 63, 2) with block("oak_slab", {type: "double"})
        send "was standing on ${here.id}" to sender
    }
}
```

`place ... at` and `set block at ... to` are two spellings of the same one-cell placement —
pick whichever reads better at the call site. Either accepts a plain id string (which skips
the state machinery) or a posed `block(...)` value that carries a full state:

```swoftlang
command "platform" {
    execute {
        fill blocks from location(-5.0, 63.0, -5.0) to location(5.0, 63.0, 5.0) with "SMOOTH_STONE"
        set block at location(0.0, 64.0, 0.0) to "BEACON"
        send "standing on ${block_at(sender.location)}" to sender
    }
}
```

`remove block at` clears the cell to air and cancels every
[`.tasks`](/reference/schedulers#obj-tasks) task bound to that
position. Together, `place` and `remove block at` are the imperative pair for scripting the
world from an event handler:

```swoftlang
on PlayerJoin {
    place block("minecraft:sea_lantern") at event.player.location
    place "minecraft:oak_log" at event.player.location
    remove block at event.player.location
}
```

Fills run on the tick thread. The compiler measures literal volumes and warns before you
freeze the server — real `swoftc` output:

```
w_fill.sw:3:9: warning: 'fill blocks' spans 1000000 blocks here; fills over 100000 blocks can stall the tick thread
```

```swoftlang
command "bigfill" {
    execute {
        // compiles, but earns the warning above
        fill blocks from location(0.0, 0.0, 0.0) to location(99.0, 99.0, 99.0) with "STONE"
    }
}
```

## `block_handler` — react to a block

A `block_handler "id" { }` declaration registers lifecycle callbacks for one block type.
Each callback is optional; declare only the ones you need. `on_interact` returns a
`Boolean` — `true` to consume the click.

```swoftlang
block_handler "oak_sign" {
    on_place(player, location, block) {
        send "placed a sign" to player
    }
    on_destroy(location, block) {
        broadcast "a sign broke"
    }
    on_interact(player, location, block) -> Boolean {
        send "you clicked the sign" to player
        return true
    }
    on_touch(entity, location) {
        broadcast "something touched a sign"
    }
    tick(location, block) {
        broadcast "sign tick"
    }
}
```

| Callback | Parameters | Fires when |
|---|---|---|
| `on_place` | `(player, location, block)` | a player places the block |
| `on_destroy` | `(location, block)` | the block is broken |
| `on_interact` | `(player, location, block) -> Boolean` | a player right-clicks it |
| `on_touch` | `(entity, location)` | an entity walks into it |
| `tick` | `(location, block)` | the block ticks |

## `placement_rule` — decide the placed state

Where a `block_handler` reacts to a placed block, a `placement_rule for "id" { }` decides
**what state to place** — the orientation and connection logic Minestom leaves to the
server. `on_place` returns the `Block` to set; `on_update` recomputes it when a neighbour
changes; `self_replaceable` controls whether clicking the block again replaces it (slabs
stacking into a double, for instance).

```swoftlang
placement_rule for "oak_stairs" {
    on_place(location, face, cursor, against, player) -> Block {
        return block("oak_stairs").with("facing", "north").with("half", "top")
    }
    on_update(location, block, neighbors) -> Block {
        return block
    }
    self_replaceable: false
}
```

The `on_place` callback is handed the placement context:

| Parameter | Type | Meaning |
|---|---|---|
| `location` | `Location` | the cell being placed into |
| `face` | `String` | the clicked face — `"top"`, `"north"`, … |
| `cursor` | `Vec` | the hit point on that face, each component in `0..1` |
| `against` | `Block` | the block that was clicked |
| `player` | `Location` | the placing player's position, carrying `.yaw` / `.pitch` |

Minestom's placement state exposes a position, not a `Player`, so `player` is a
`Location` — read `player.yaw` to orient stairs and doors from the look direction.
`on_update(location, block, neighbors)` receives `neighbors` as a `map<String, Block>`
keyed by the six face names, and returns the block's recomputed state (fence connections,
stair shapes) whenever an adjacent block changes.

## The vanilla-placement addon

Rebuilding every stair, slab, log, fence, wall, and door rule by hand is a lot of
boilerplate, so the shipped `blocks` addon does it for you — written entirely in
SwoftLang on top of `placement_rule`. Import it and freshly placed blocks orient and
connect like vanilla:

```swoftlang
import "blocks"
```

Reading `addons/blocks.sw` is also the reference example for the construct: it shows
`facing_from_yaw`, neighbour scanning, waterlogging, and the two-block door write, all in
plain `.sw`. Extend it by copying one `placement_rule` block per new block id.

<MappedCompare title="Orienting a placed log" leftLabel="Skript + a Java addon" rightLabel="SwoftLang">
<MappedPair label="axis from the clicked face">
<template #skript>

```skript
# Skript has no block-placement-state hook: the log's axis is baked by the
# client/server at place time and Skript cannot rewrite the placed state.
# Doing this needs a compiled Java addon (a BlockPlacementRule) — there is
# no pure-Skript form.
on place of oak log:
    # ...no access to face/cursor/placed state here...
```

</template>
<template #swoftlang>

```swoftlang
placement_rule for "oak_log" {
    on_place(location, face, cursor, against, player) -> Block {
        set axis to "y"
        if (face is "north") or (face is "south") set axis to "z"
        if (face is "east") or (face is "west") set axis to "x"
        return block("oak_log").with("axis", axis)
    }
    self_replaceable: false
}
```

</template>
<template #note>

The placement state — clicked `face`, `cursor`, the `against` block, the player's look —
is exactly what an oriented placement needs, and it is right there in the callback. In
Skript this is a compiled Java addon; here it is a typechecked `.sw` declaration.

</template>
</MappedPair>
</MappedCompare>
