# Fishing

SwoftLang ships a complete fishing engine. A player right-clicks a fishing rod, a bobber
flies out and settles on the water (or lava), a bite lands inside a configurable window,
and reeling at the right moment pulls in a catch — an item that flies to the player, or
a mob that spawns at the hook. What each rod pulls up is driven by declarative **loot
tables**, and the whole lifecycle is exposed through four typed events.

```swoftlang
fishing_loot "overworld_water" {
    medium: water
    catch item "COD" weight 40
    catch item "SALMON" weight 25
    catch item "PUFFERFISH" weight 10 message "<yellow>Careful, it puffs!"
}
```

## Loot tables

A `fishing_loot "<name>" { }` block declares a weighted catch table. Each `catch` line
adds one possible result; when a bite is landed against this table the engine picks one
line at random, weighted by `weight`.

| Field | Meaning |
|---|---|
| `medium:` | which fluid this table fishes — `water` or `lava` |
| `world:` | *(optional)* restrict the table to one world by name |
| `catch item "<id>" weight <n>` | an item result — a vanilla material or a declared [custom item](./items) |
| `catch mob "<id>" weight <n>` | a mob result — spawns a declared [custom mob](./mobs) at the hook |
| `... message "<text>"` | *(optional)* a MiniMessage line sent to the fisher on that catch |

Item ids resolve against your declared items first, then vanilla materials; mob ids must
name a declared mob. An unknown id is a compile error, and the `medium:` enum is closed:

<!-- swoftc name=med.sw expect=error -->

```swoftlang
fishing_loot "ow" {
    medium: acid      // [!code error]
    catch item "COD" weight 40
}
```

```txt
med.sw:2:13: error: unknown fishing medium 'acid'; valid mediums: water, lava
    medium: acid
            ^
```

### Table matching

Tables are matched by `medium` plus optional `world`. The most specific table wins — a
table with a matching `world:` beats a medium-only table — and a built-in vanilla water
table serves any bite that no declared table claims. Declaring a table for `water` in
`"world"` and a broad `lava` table anywhere is enough to cover both fluids:

```swoftlang
fishing_loot "overworld_water" {
    medium: water
    world: "world"
    catch item "COD" weight 40
    catch item "SALMON" weight 25
    catch item "PUFFERFISH" weight 10 message "<yellow>Careful, it puffs!"
}

fishing_loot "any_lava" {
    medium: lava
    catch item "MAGMA_CREAM" weight 8
    catch item "BLAZE_ROD" weight 2 message "<gold>Still warm."
}
```

## The bite window

The delay between casting and a bite is configured in the [`server`](./server-config)
block, under a `fishing { }` section. `min_bite` and `max_bite` are duration literals;
each cast rolls a bite time uniformly in that range.

```swoftlang
server {
    motd: "Gone fishin'"
    fishing {
        min_bite: 4 seconds
        max_bite: 20 seconds
    }
}
```

With no `fishing { }` section, the engine uses its default window. Reel in before the
bite and nothing happens; reel during the bite window and the catch is resolved.

## The fishing events

Four typed events cover the lifecycle. Each binds `player`, and — like every curated
event — exposes its properties both bare and under `event.*`.

| Event | Cancellable | Bindings | Fires |
|---|---|---|---|
| `PlayerCastRod` | yes | `player` | before the bobber spawns — cancel to refuse the cast |
| `FishBite` | — | `player`, `hook_location` (Location) | when the bobber dips |
| `PlayerCatchFish` | yes | `player`, `caught_item` (optional&lt;Item&gt;, rw), `caught_mob` (optional&lt;Mob&gt;) | just before the catch is delivered |
| `PlayerReelIn` | — | `player` | when the line comes back in |

`PlayerCastRod` gates casting — a good place to enforce a permission, a region, or a
cooldown:

```swoftlang
event PlayerCastRod {
    execute {
        if player.world.time > 100000 {
            send "<gray>The fish are asleep." to player
            cancel event
        }
    }
}
```

`PlayerCatchFish` fires *before* delivery. `caught_item` is read-write, so you can swap
the delivered stack; `caught_mob` is read-only; and `cancel event` (or `halt`) discards
the catch entirely:

```swoftlang
event PlayerCatchFish {
    execute {
        if event.caught_mob exists {
            send "<red>brace yourself..." to player
            halt
        }
        if event.caught_item exists {
            send "you landed ${event.caught_item.name}!" to player
            if event.caught_item.material is "minecraft:pufferfish" {
                set event.caught_item to item("COD")
                send "<gray>...swapped the puffer for a safer cod." to player
            }
        }
    }
}
```

## A complete custom fishing setup

Declared custom item and mob, two loot tables, a bite window, and handlers for the whole
lifecycle — the entire feature in one file:

<!-- swoftc name=fishing_full.sw -->

```swoftlang
item "glimmering_cod" {
    material: "COD"
    name: "<aqua>Glimmering Cod"
    rarity: rare
    lore {
        line "<gray>It hums faintly."
    }
}

mob "sea_walker" {
    type: "ZOMBIE"
    name: "<dark_aqua>Sea Walker"
    health: 40
    ai: melee
}

fishing_loot "overworld_water" {
    medium: water
    world: "world"
    catch item "COD" weight 40
    catch item "SALMON" weight 25
    catch item "glimmering_cod" weight 5 message "<aqua>It glimmers in your hands."
    catch mob "sea_walker" weight 3 message "<red>Something walked out of the water..."
    catch item "PUFFERFISH" weight 10 message "<yellow>Careful, it puffs!"
}

fishing_loot "any_lava" {
    medium: lava
    catch item "MAGMA_CREAM" weight 8
    catch item "BLAZE_ROD" weight 2 message "<gold>Still warm."
}

server {
    fishing {
        min_bite: 4 seconds
        max_bite: 20 seconds
    }
}

event PlayerCastRod {
    execute {
        if player.world.time > 100000 {
            send "<gray>The fish are asleep." to player
            cancel event
        }
    }
}

event FishBite {
    execute {
        send "bite at x=${hook_location.x} z=${hook_location.z}" to player
    }
}

event PlayerCatchFish {
    execute {
        if event.caught_mob exists {
            send "<red>brace yourself..." to player
            halt
        }
        if event.caught_item exists {
            send "you landed ${event.caught_item.name}!" to player
        }
    }
}

event PlayerReelIn {
    execute {
        send "<gray>line reeled in" to player
    }
}
```

Custom-item catches carry their [identity](./items#identity-custom-id) all the way into
the player's inventory, and mob catches spawn as full [custom mobs](./mobs) — aggro,
drops, and all.
