---
title: Items & Mobs
---

<StepHeader>
a custom sword that carries its identity, a <code>/kit</code> to hand it out, and a crypt ghoul that drops it — declared, not coded.
</StepHeader>

Custom content is declared at the top level, like everything else. An `item` block gives
you an identity-carrying item with the exact lore you write and a tree of NBT data; a
`mob` block gives you a spawnable creature with AI, drops, and handlers. Both are checked:
rarities, AI modes, and click filters are closed enums, and a drop referencing an unknown
item id is a compile error.

## Declaring an item

```swoftlang
item AspectOfTheEnd {
    material: "DIAMOND_SWORD"
    name: "<blue>Aspect of the End"
    rarity: rare
    glint: true

    tags: {
        damage: 100,
        meta: { tier: 3, keywords: ["end", "sword"] }
    }

    lore {
        line "<gray>A legendary blade from the End."
        blank
        line "<dark_gray>Soulbound"
    }
}

command "kit" {
    execute {
        give item "aspect_of_the_end" to sender
        send "<green>Kit delivered." to sender
    }
}
```

The declaration owns four things: **identity** (`material` or `skull`), **appearance**
(`name`, `rarity`, `glint`), the **lore** you write line for line, and a **tags** tree of
freeform NBT. The lore is what-you-see-is-what-you-get — no sections are assembled for you
— and one of the four vanilla rarities (`common`, `uncommon`, `rare`, `epic`) tints the
name. `lore { }` allows `line`, `blank`, and `if`/`loop`, the same restricted DSL as
scoreboard lines.

<MappedCompare>
<MappedPair label="a custom sword">
<template #skript>

```skript
# vanilla Skript: the "custom item" is rebuilt inline
# at every give site — name, lore, and enchant glint
# restated each time, drifting apart over time
command /kit:
    trigger:
        give player diamond sword named "&9Aspect of the End" with lore
            "&7A legendary blade from the End." and "&8Soulbound"
```

</template>
<template #swoftlang>

```swoftlang
item AspectOfTheEnd {
    material: "DIAMOND_SWORD"
    name: "<blue>Aspect of the End"
    rarity: rare

    lore {
        line "<gray>A legendary blade from the End."
    }
}

command "kit" {
    execute {
        give item "aspect_of_the_end" to sender
    }
}
```

</template>
<template #note>

The declaration is the single source of truth: every `give item` site stays in sync
because there's nothing to restate. The item also *carries its identity* — see
`custom_id` below — which inline-built items never do, so you can recognise it again after
it's been dropped, stored, or traded.

</template>
</MappedPair>
</MappedCompare>

## Identity: `custom_id`

Every declared item is tagged with its id, and the tag survives inventories, chests, and
restarts. `custom_id(<item>)` reads it back as an `Optional<String>` — `none` for vanilla
items, so [Step 07](/1.9.0/guide/options) discipline applies:

```swoftlang
Item {
    on_use {
        if custom_id(item) otherwise "" is "aspect_of_the_end" {
            send "<gray>You used the Aspect!" to player
        }
    }
}
```

`custom_item("id")` conjures a fresh instance as an expression, and any item value exposes
a `tags` namespace: `item.tags.<path>` reads and writes freeform NBT, nesting through
compounds (`item.tags.meta.tier`) and integrating with optionals — a missing tag reads as
`none`.

## Tags, attributes, and on_click

Three optional pieces turn a decorated item into interactive equipment:

- **`tags { }`** — arbitrary nested NBT (`damage: 100`, `meta: { tier: 3 }`), read and
  written at runtime through `item.tags.*`. This is where your own "stats" live — plain
  data you design.
- **`attributes { }`** — *real* vanilla attributes (`speed`, `max_health`,
  `attack_damage`, `attack_speed`, `armor`, `knockback_resistance`), applied while the
  item is held or worn and removed when it isn't.
- **`on_click(<filter>) { }`** — a filtered use handler (`left`, `right`, `any`) bound to
  this item, with `player` and `item` in scope. A tag write inside re-renders the lore and
  flushes back to the hand.

```swoftlang
item CryptKey {
    skull: "1ae3855f952cd4a03c148a946e3f812a5955ad35cbcb52627ea4acd47d3081"
    name: "<gold>Crypt Key"
    rarity: epic

    tags: {
        uses: 3
    }

    on_click {
        set item.tags.uses to (item.tags.uses otherwise 0) - 1
        send "<light_purple>The key turns... (${item.tags.uses otherwise 0} uses left)" to player
    }
}
```

(`skull:` instead of `material:` renders a player-head with that texture — one or the
other, never both; the checker enforces it.)

::: tip Build a whole item system
Stats, tiers, and cooldowned abilities are things you *assemble* from these pieces — tags
for the numbers, lore for the display, events or an addon for the behavior. [Step
14](/1.9.0/guide/rpg-items) walks the full Hypixel-style pattern, and the
[reference](/1.9.0/reference/items) has every key.
:::

## Declaring a mob

<!-- swoftc name=mobs.sw -->

```swoftlang
item RottenScimitar {
    material: "GOLDEN_SWORD"
    name: "<gray>Rotten Scimitar"
    rarity: uncommon

    tags: {
        damage: 40
    }
}

mob CryptGhoul {
    type: "ZOMBIE"
    name: "<red>Crypt Ghoul <green>${mob.health}<red>❤"
    health: 200
    damage: 25
    speed: 0.3
    ai: melee

    drops {
        item "rotten_scimitar" chance 0.05 amount 1
        item "ROTTEN_FLESH" chance 0.5 amount 2
    }

    on_spawn {
        broadcast "<gray>A ${mob.custom_id} rises from the crypt..."
    }

    on_death {
        if killer exists {
            send "<green>You slew the Crypt Ghoul!" to killer
        }
    }

    on_attack {
        send "<red>The ghoul rakes at you!" to victim
    }
}
```

The pieces:

- `type` — the base entity, validated against the real entity-type registry.
- `name` — live-interpolated: `${mob.health}` re-renders on the nameplate as the mob
  takes damage.
- `ai` — `melee` (target, chase, attack), `passive` (wander), or `none` (statue).
- `drops { }` — each roll is `item <id> chance <p> amount <n>`; ids can be your custom
  items or vanilla materials, checked at compile time.
- Handlers bind `mob`, plus `killer` (an `Optional<Player>` — narrowing required) in
  `on_death` and `victim` in `on_attack`.

A custom mob is an [entity](/1.9.0/reference/entities), so the shared entity properties and
statements — `velocity`, `glowing`, `mount`, `remove entity` — work on it alongside its
typed mob rows.

## Spawning and querying

These commands live in the same file as the `mob CryptGhoul` declaration above —
spawning an undeclared mob id is a compile error.

<!-- swoftc prelude=mobs.sw -->

```swoftlang
command "ghoul" {
    execute {
        spawn mob CryptGhoul at location(10, 64, 20) as m
        set m.health to m.max_health / 2
        send "<gray>Spawned ${m.custom_id} at half health." to sender
    }
}

command "cleanse" {
    execute {
        loop all_mobs("crypt_ghoul") as g {
            despawn g
        }
        send "<green>The crypt is quiet." to sender
    }
}
```

`spawn mob ... as m` binds the new mob to a variable — a `Mob` value with properties
`health` (rw), `max_health` (ro), `name` (rw), `location` (rw), `type` (ro), and
`custom_id` (ro). `all_mobs("id")` lists the living instances; `despawn` removes one.

Server-wide, the base [`Mob`](/1.9.0/reference/events#mob) receiver's `on_spawn`, `on_death`, and
`on_hit` methods fire for *every* mob — a `mob <MobType> { }` declaration handles that mob's own
story, while `Mob { }` drives global systems:

```swoftlang
persistent mob_kills for Player: Integer = 0

Mob {
    on_death {
        if killer exists {
            set k to player(killer.uuid)
            if k exists {
                set mob_kills for k to (mob_kills for k) + 1
                send "<gold>Kill #${mob_kills for k}: ${mob.custom_id}" to k
            }
        }
    }
}
```

That's a kill tracker in ten lines — persistence from [Step 10](/1.9.0/guide/persistence),
optionals from [Step 07](/1.9.0/guide/options), and content from this one. Next: packaging
systems like it into reusable modules.
