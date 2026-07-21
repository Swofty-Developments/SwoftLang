# Display Entities

Text, item, and block displays — the 1.19.4+ display entities — as first-class
values. Spawn one with a builtin, style it through properties, and manage it with
display statements. Floating shop labels, 3D item showcases, ghost-block previews:
no armor stands, no packets.

```swoftlang
command "label" {
    execute {
        set d to spawn_text_display("<gold><bold>Item Shop", location(0.5, 82.0, 0.5))
        set d.billboard to "center"
        set d.scale to 1.5
        set d.background to "#80000000"
    }
}
```

## Spawning

| Builtin | Returns | Spawns |
|---|---|---|
| `spawn_text_display(text, location)` | `Display` | floating text (MiniMessage / `&` codes ok) |
| `spawn_item_display(material, location)` | `Display` | a rendered ItemStack |
| `spawn_block_display(block, location)` | `Display` | a block state |

All three return a `Display` value — a real Minestom entity, visible to everyone by
default, alive until you `destroy` it (or the server stops; displays are not
persistent).

## Properties

All read/write. The three content properties apply to their own display kind; the
transform and rendering rows apply to all three.

| Property | Type | Applies to | Meaning |
|---|---|---|---|
| `text` | `String` | text | the displayed text |
| `item` | `String` | item | material name |
| `block` | `String` | block | block name |
| `scale` | `Double` | all | uniform scale factor |
| `translation` | `Location` | all | render offset from the anchor, in blocks (x/y/z used) |
| `rotation` | `Location` | all | euler degrees carried as a Location (x=pitch, y=yaw, z=roll) |
| `billboard` | `String` | all | `fixed`, `vertical`, `horizontal`, `center` |
| `glow_color` | `String` | all | one of the 16 named colors — gives the entity a glow outline |
| `background` | `String` | text | `#AARRGGBB` hex background, e.g. `"#80000000"` |
| `alignment` | `String` | text | `left`, `center`, `right` |
| `line_width` | `Integer` | text | wrap width in pixels (default 200) |
| `see_through` | `Boolean` | text | text visible through walls |
| `view_range` | `Double` | all | render distance multiplier |

Enum-ish string properties are validated when literal:

```
e_glow.sw:4:29: error: unknown glow color '#00ff88'; valid values: black, dark_blue, dark_green, dark_aqua, dark_red, dark_purple, gold, gray, dark_gray, blue, green, aqua, red, light_purple, yellow, white
```

(`glow_color` is a protocol team color — 16 names, no hex. `background` *is* hex,
with alpha.)

## Statements

| Form | Effect |
|---|---|
| `show display <d> to <player \| list \| all>` | per-viewer visibility on |
| `hide display <d> from <player \| list \| all>` | per-viewer visibility off |
| `mount display <d> on <player \| mob>` | ride an entity — moves with it |
| `teleport display <d> to <location>` | move the anchor |
| `destroy display <d>` | remove the entity |

```swoftlang
command "crown" {
    execute {
        set crown to spawn_item_display("GOLDEN_HELMET", sender.location)
        set crown.translation to location(0.0, 2.3, 0.0)
        set crown.scale to 0.6
        mount display crown on sender
        send "<gold>Crowned." to sender

        // a private marker: spawn for everyone, then narrow visibility
        set mark to spawn_text_display("<red>quest here", location(10.5, 70.0, 4.5))
        hide display mark from all
        show display mark to sender
    }
}
```

## Rotation and translation

Both are euler-degree / block-offset triples carried as `Location` values — `x`, `y`,
`z` are used, yaw and pitch on the carrier are ignored:

```swoftlang
command "tilt" {
    execute {
        set d to spawn_block_display("GRASS_BLOCK", location(0.5, 65.0, 0.5))
        set d.rotation to location(0.0, 45.0, 0.0)      // 45° around Y
        set d.translation to location(0.0, 0.25, 0.0)   // raised a quarter block
    }
}
```

## Lifetime and patterns

Displays live for the server session. For a permanent fixture, spawn it at boot from
a [scheduler](./schedulers) or a join guard; keep the handle in a module or local
variable if you'll mutate it later.

Multi-line floating text has its own first-class construct — the
[`hologram`](./holograms) block stacks a text display per line for you, with per-viewer
text and `show` / `set line` / `move` statements. Reach for that instead of stacking
displays by hand:

```swoftlang
hologram "welcome" {
    location: location(0.5, 82.0, 0.5)
    lines {
        line "<gold><bold>SwoftLang"
        line "<gray>have a look around"
    }
}

Player {
    on_join() {
        show hologram "welcome" to this
    }
}
```
