---
title: Combat & PvP
---

# Combat & PvP

Minestom ships **no** combat mechanics — no armour reduction, no knockback, no crits, no
attack cooldown, no invulnerability window, no natural regen. SwoftLang gives you the
first-class surface to build all of it in-language: the cancellable
[`Entity.on_hit`](./events#entity) method, attributes as **direct entity properties**
(`victim.armor`, `set player.max_health to 40`), the combat verbs
(`damage … by`, `knock … away from`, `apply … to … for`, `shoot … from`), the native
trackers as **read-only properties** (`entity.invulnerable_ticks`, `entity.fall_distance`,
`entity.is_climbing`), and per-entity scratch state on the
[`.tags`](#per-entity-scratch-state-tags) namespace. The reduction, crit, and regen **math**
is then plain SwoftLang — the whole [`vanilla-pvp.sw`](#walkthrough-vanilla-pvp-sw) script is
written this way.

```swoftlang
Entity {
    on_hit {
        // veto a hit entirely — entity is the victim, attacker is the source
        if entity.tags.invulnerable exists {
            cancel event
        }
    }
}
```

## The `Entity.on_hit` method

Every hit flows through the cancellable [`Entity.on_hit`](./events#entity) method. `entity`
is the victim and `attacker` is the source — the entry points for a combat system:

| Binding | Type | Access | Meaning |
|---|---|---|---|
| `entity` | `Entity` | — | the victim taking the hit |
| `attacker` | `optional<Entity>` | ro | the direct attacker, when there is one |
| `cancel event` | — | — | negate the hit outright |

The hit surface reports *that* a hit happened and to whom, and lets you veto it or add
feedback (knockback, crits, effects); it does not bind the numeric damage amount. Combat
**math** — armour curves, crit multipliers — is plain SwoftLang you apply when *you* deal
damage with the [`damage … by`](#combat-verbs) verb, or use to decide whether to
`cancel event`.

## Attributes are entity properties

Every combat attribute is a **direct property** on any live entity (Player, Mob, Entity,
Display) — read it for the current value, `set` it for the base value, exactly like
`max_health`. Named **modifiers** stack on top of the base without clobbering it.

| Form | Type | Meaning |
|---|---|---|
| `e.armor` | `Double` | read the attribute's current value |
| `set e.max_health to 40.0` | — | set the base value |
| `add modifier "<id>" to e.<attr> of <amount> <operation>` | — | add a named modifier |
| `remove modifier "<id>" from e.<attr>` | — | remove it by id |

```swoftlang
command "buff" {
    execute {
        set spd to sender.movement_speed
        set sender.max_health to 40.0
        add modifier "sprint_boost" to sender.movement_speed of 0.2 add_multiplied_base
        remove modifier "sprint_boost" from sender.movement_speed
        send "base speed ${spd}" to sender
    }
}
```

The attribute properties are `armor`, `armor_toughness`, `attack_damage`,
`attack_knockback`, `attack_speed`, `knockback_resistance`, `max_health`, `max_absorption`,
`absorption`, `movement_speed`, `fall_damage_multiplier`, `safe_fall_distance`,
`sweeping_damage_ratio`, `flying_speed`, `follow_range`, `jump_strength`, `scale`,
`gravity`, `step_height`, `luck`, `block_interaction_range`, `entity_interaction_range`,
and `explosion_knockback_resistance`. A modifier written to an unknown attribute is a
compile error that echoes the full list:

```
w_attr.sw:2:32: error: unknown attribute 'not_an_attribute'; valid attributes: armor, armor_toughness, attack_damage, attack_knockback, attack_speed, knockback_resistance, max_health, max_absorption, absorption, movement_speed, fall_damage_multiplier, safe_fall_distance, sweeping_damage_ratio, flying_speed, follow_range, jump_strength, scale, gravity, step_height, luck, block_interaction_range, entity_interaction_range, explosion_knockback_resistance
```

The modifier operation must be one of `add`, `add_multiplied_base`, or
`add_multiplied_total`:

```
w_op.sw:2:54: error: unknown modifier operation 'scale_it'; valid operations: add, add_multiplied_base, add_multiplied_total
```

## Combat verbs

Four English statement verbs do the imperative combat work — deal damage, launch a body,
apply a potion, shoot a projectile. Damage-type, potion-effect, and projectile-type
literals are validated against the registry; entity arguments accept any live entity.

| Statement | Effect |
|---|---|
| `damage <target> by <amount> [as "<type>"] [from <source>]` | deal typed damage, optionally attributed to a source |
| `knock <target> away from <location> [with strength <s>]` | vanilla knockback along the `target − location` direction (default strength `0.4`) |
| `apply "<effect>" <amplifier> to <e> for <duration>` | apply a potion effect |
| `remove "<effect>" from <e>` | clear one effect |
| `shoot "<projectile>" from <location> [with velocity <vec>] [by <shooter>]` | spawn a projectile |

```swoftlang
command "smite" {
    execute {
        damage sender by 6.0 as "magic"
        apply "regeneration" 1 to sender for 100
        shoot "arrow" from sender.location with velocity velocity(0, 1, 2) by sender
    }
}
```

`knock … away from` reads best in a hit listener — the direction is the victim pushed away
from the attacker's position:

```swoftlang
Entity {
    on_hit {
        if attacker exists {
            knock entity away from attacker.location with strength 0.5
        }
    }
}
```

The live effect ids are the read-only `e.active_effects` list, and `remove … from` clears
one by id:

```swoftlang
command "effects" {
    execute {
        apply "strength" 0 to sender for 200
        loop sender.active_effects as e {
            send "active: ${e}" to sender
        }
        remove "strength" from sender
    }
}
```

Bad literals are rejected at compile time — `damage e by 6.0 as "not_a_damage_type"` raises
`unknown damage type 'not_a_damage_type'`, and the effect / projectile verbs raise
`unknown potion effect` / `unknown projectile type` the same way.

## Native trackers

Three per-entity counters Minestom tracks but does not otherwise surface are read-only
properties — they are what an i-frame check and a crit check need:

| Property | Type | Meaning |
|---|---|---|
| `e.invulnerable_ticks` | `Integer` | remaining vanilla i-frame ticks (window 10) |
| `e.fall_distance` | `Double` | blocks fallen while airborne (the crit condition) |
| `e.is_climbing` | `Boolean` | positional climbing heuristic |

```swoftlang
Entity {
    on_hit {
        if attacker exists {
            // crit: falling, airborne, not sprinting -> the sparkle
            if attacker.fall_distance > 0.0 and not attacker.on_ground and not attacker.is_sprinting {
                spawn particle "crit" at entity.location count 8 offset 0.4, 0.6, 0.4 speed 0.1 to all
            }
        }
    }
}
```

## Per-entity scratch state: `.tags`

A combat system needs to remember things **between** hits and ticks — the last swing tick
for the attack-cooldown curve, a knockback level, a cached enchant EPF, an exhaustion
accumulator. All of it lives on the unified [`.tags`](./mobs#tags) namespace, the same one
items and mobs use: `player.tags.<key>` and `mob.tags.<key>` read, write, and delete
freeform per-entity values without declaring a field. A tag read is `optional<Any>`, so
narrow it with `if … exists` or give a fallback with `otherwise`:

```swoftlang
Entity {
    on_hit {
        // honour a short custom i-frame window: ignore hits while it is live
        set iframe to entity.invulnerable_ticks
        if iframe > 0 {
            cancel event
            return
        }
        // count hits taken on the victim's own scratch state
        set hits to entity.tags.hits_taken otherwise 0
        set entity.tags.hits_taken to hits + 1
    }
}
```

Reading a tag directly without a fallback is a compile error, exactly as elsewhere:

```
w_tags.sw:3:30: error: the left operand of '+' is optional<Any> and may be missing; check it with 'if ... exists' or provide a fallback with 'otherwise'
```

## Walkthrough: `vanilla-pvp.sw`

The shipped `scripts/vanilla-pvp.sw` reimplements vanilla melee combat end-to-end using
only the surface above — the same job MinestomPvP does in Java, but in-language. It has
two parts.

**One hit listener.** `Entity { on_hit }` applies the vanilla combat feedback on
every hit — attack-cooldown swing tracking, the crit sparkle, and knockback — reading its
inputs from attribute properties and `.tags` and writing its scratch state back to `.tags`.
`entity` is the victim; the attacker-dependent steps run only `if attacker exists`:

```swoftlang
Entity {
    on_hit {
        if attacker exists {
            // attack cooldown: record the swing tick for the next hit's charge
            set attacker.tags.last_swing to attacker.alive_ticks

            // crit: falling, airborne, not sprinting -> the sparkle
            if attacker.fall_distance > 0.0 and not attacker.on_ground and not attacker.is_sprinting {
                spawn particle "crit" at entity.location count 8 offset 0.4, 0.6, 0.4 speed 0.1 to all
            }

            // knockback: base + sprint bonus, scaled by the target's resistance
            set sprint_bonus to 0.0
            if attacker.is_sprinting {
                set sprint_bonus to 1.0
            }
            set kb_resist to entity.knockback_resistance
            set strength to (0.4 + sprint_bonus * 0.5) * (1.0 - kb_resist)
            knock entity away from attacker.location with strength strength
        }
    }
}
```

The hit surface reports the victim and attacker but not the numeric amount, so the
armour + toughness + protection + resistance **reduction math** stays as reusable userland
functions, applied where the script itself deals damage with `damage … by`. The
attack-cooldown curve reads `attacker.attack_speed` and the last-swing tick from
`attacker.tags.last_swing` (compared against `attacker.alive_ticks`), the crit check reads
`attacker.fall_distance`, and knockback folds in the target's `entity.knockback_resistance`
before the `knock entity away from attacker.location` push.

**A tick loop for regen, starvation, and exhaustion** — the loop Minestom does not run.
A top-level `every 1 tick` schedule runs each game tick over every online player. Food,
saturation, and health are real player properties; the exhaustion float and the
heal/starve timers live under `player.tags`:

```swoftlang
every 1 tick {
    loop all_players() as p {
        // starvation: food 0 -> 1 damage every 80 ticks, never below 1 HP
        if p.food <= 0 and p.health > 1.0 {
            set starve_timer to p.tags.starve_timer otherwise 0
            if starve_timer >= 80 {
                damage p by 1.0 as "starve"
                set p.tags.starve_timer to 0
            } else {
                set p.tags.starve_timer to starve_timer + 1
            }
        }
    }
}
```

That is the whole point of the combat surface: the reduction, crit, and regen math is
ordinary SwoftLang, attributes and trackers are ordinary properties, and the per-entity
bookkeeping is just `.tags`. In Skript the same behaviour needs a compiled Java addon.

<MappedCompare title="Custom knockback on a hit" leftLabel="Skript + MinestomPvP" rightLabel="SwoftLang">
<MappedPair label="scale knockback by the target's resistance">
<template #skript>

```skript
# Skript has no attribute-aware knockback hook of its own —
# vanilla-style PvP knockback comes from a compiled Java addon
# (MinestomPvP / an Sk-addon), configured, not scripted.
on damage:
    # victim's knockback resistance and a directional push are not exposed here
    # ...addon does the knockback...
```

</template>
<template #swoftlang>

```swoftlang
Entity {
    on_hit {
        if attacker exists {
            set kb_resist to entity.knockback_resistance
            knock entity away from attacker.location with strength (0.5 * (1.0 - kb_resist))
        }
    }
}
```

</template>
<template #note>

The victim is `entity`, the source is `attacker`, and `knockback_resistance` is a plain
property, so a resistance-aware push is a few lines of arithmetic plus the `knock … away
from` verb. Skript reaches for a compiled combat addon because the language exposes neither
the attribute nor a directional knockback hook.

</template>
</MappedPair>
</MappedCompare>
