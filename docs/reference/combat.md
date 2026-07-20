---
title: Combat & PvP
---

# Combat & PvP

Minestom ships **no** combat mechanics — no armour reduction, no knockback, no crits, no
attack cooldown, no invulnerability window, no natural regen. SwoftLang gives you the
primitives to build all of it in-language: the enriched
[`EntityDamage`](./events) event, attribute accessors, the combat effects
(`apply_damage` / `apply_knockback` / `apply_effect` / `spawn_projectile`), the native
trackers Minestom hides (`invulnerable_ticks` / `fall_distance`), and per-entity scratch
state on the [`.tags`](#per-entity-scratch-state-tags) namespace. The reduction, crit, and
regen **math** is then plain SwoftLang — the whole [`vanilla-pvp.sw`](#walkthrough-vanilla-pvp-sw)
script is written this way.

```swoftlang
on EntityDamage {
    set victim to event.entity
    set armor to attribute(victim, "armor")
    // simple flat mitigation, then commit it back to the event
    set event.damage to max(0.0, event.damage * (1.0 - armor / 25.0))
}
```

## The `EntityDamage` event

Every hit flows through the cancellable `EntityDamage` event (see the
[event catalog](./events#richest-event)). Its enriched fields are the entry point for a
combat system:

| Field | Type | Access | Meaning |
|---|---|---|---|
| `entity` | `Entity` | ro | the victim taking the hit |
| `damage` | `Double` | rw | the incoming amount — rewrite it to apply reduction |
| `attacker` | `optional<Entity>` | ro | the direct attacker, when there is one |
| `source_entity` | `optional<Entity>` | ro | the ultimate source (e.g. the shooter behind an arrow) |
| `damage_type` | `String` | ro | the typed cause |
| `cancelled` | `Boolean` | rw | `cancel event` to negate the hit |

## Attribute accessors and modifiers

`attribute(e, "key")` reads an entity's attribute base value; `set_attribute` writes it;
and named **modifiers** stack multiplicatively or additively on top without clobbering the
base. The entity argument accepts any live entity (Player, Mob, Entity, Display).

| Call | Returns | Effect |
|---|---|---|
| `attribute(e, "armor")` | `Double` | the attribute's current value |
| `set_attribute(e, "max_health", 40.0)` | — | set the base value |
| `add_attribute_modifier(e, "movement_speed", "id", 0.2, "add_multiplied_base")` | — | add a named modifier |
| `remove_attribute_modifier(e, "movement_speed", "id")` | — | remove it by id |

```swoftlang
command "buff" {
    execute {
        set spd to attribute(sender, "movement_speed")
        set_attribute(sender, "max_health", 40.0)
        add_attribute_modifier(sender, "movement_speed", "sprint_boost", 0.2, "add_multiplied_base")
        remove_attribute_modifier(sender, "movement_speed", "sprint_boost")
        send "base speed ${spd}" to sender
    }
}
```

Attribute keys and modifier operations are validated against the registry when written as
literals. The valid keys include `armor`, `armor_toughness`, `attack_damage`,
`attack_speed`, `knockback_resistance`, `max_health`, `movement_speed`, and
`scale` — the full list is echoed in the error:

```
w_attr.sw:3:36: error: unknown attribute 'not_an_attribute'; valid attributes: armor, armor_toughness, attack_damage, attack_knockback, attack_speed, knockback_resistance, max_health, max_absorption, absorption, movement_speed, ...
```

The modifier operation must be one of `add_value`, `add`, `add_multiplied_base`,
`multiply_base`, `add_multiplied_total`, or `multiply_total`:

```
w_op.sw:3:9: error: unknown attribute operation 'scale_it'; valid operations: add_value, add, add_multiplied_base, multiply_base, add_multiplied_total, multiply_total
```

## Combat effects

The effect builtins do the imperative combat work — deal damage, launch a body, apply a
potion, spawn a projectile. Damage-type, potion-effect, and projectile-type literals are
validated against the registry; entity arguments accept any live entity.

| Call | Returns | Effect |
|---|---|---|
| `apply_damage(e, amount, "type")` | `Boolean` | deal typed damage; `true` when the hit lands |
| `apply_damage(e, amount, "type", source)` | `Boolean` | …with an attributing source entity |
| `apply_knockback(e, strength, dx, dz)` | — | vanilla knockback along the `(dx, dz)` direction |
| `apply_effect(e, "effect", ticks, amp)` | — | apply a potion effect |
| `apply_effect(e, "effect", ticks, amp, ambient)` | — | …with the ambient flag |
| `apply_effect(e, "effect", ticks, amp, ambient, particles)` | — | …and the particles flag |
| `remove_effect(e, "effect")` | — | clear one effect |
| `active_effects(e)` | `list<String>` | the entity's active effect ids |
| `spawn_projectile("type", loc, velocity)` | `Entity` | spawn a projectile |
| `spawn_projectile("type", loc, velocity, owner)` | `Entity` | …owned by a shooter |

```swoftlang
command "smite" {
    execute {
        set landed to apply_damage(sender, 6.0, "magic")
        if landed {
            apply_knockback(sender, 0.5, 1.0, 0.0)
            apply_effect(sender, "regeneration", 100, 1)
        }
        set arrow to spawn_projectile("arrow", sender.location, velocity(0, 1, 2), sender)
        send "spawned ${arrow}" to sender
    }
}
```

`active_effects` flows to a `list<String>` you can loop, and `remove_effect` clears one by
id:

```swoftlang
command "effects" {
    execute {
        apply_effect(sender, "strength", 200, 0, true, false)
        loop active_effects(sender) as e {
            send "active: ${e}" to sender
        }
        remove_effect(sender, "strength")
    }
}
```

Bad literals are rejected at compile time — `apply_damage(e, 6.0, "not_a_damage_type")`
raises `unknown damage type 'not_a_damage_type'`, and the effect / projectile builtins
raise `unknown potion effect` / `unknown projectile type` the same way.

## Native trackers

Two per-entity counters Minestom tracks but does not surface are exposed as builtins —
they are what an i-frame check and a crit check need:

| Call | Returns | Meaning |
|---|---|---|
| `invulnerable_ticks(e)` | `Integer` | remaining vanilla i-frame ticks (window 10) |
| `fall_distance(e)` | `Double` | blocks fallen while airborne (the crit condition) |
| `is_climbing(e)` | `Boolean` | positional climbing heuristic |

```swoftlang
on EntityDamage {
    set attacker to event.attacker
    if attacker exists {
        // crit: falling, airborne, not sprinting -> 1.5x + the sparkle
        if fall_distance(attacker) > 0.0 and not attacker.on_ground and not attacker.is_sprinting {
            set event.damage to event.damage * 1.5
            spawn particle "crit" at event.entity.location count 8 offset 0.4, 0.6, 0.4 speed 0.1 to all
        }
    }
}
```

## Per-entity scratch state: `.tags`

A combat system needs to remember things **between** hits and ticks — the last damage for
the i-frame comparison, the last swing tick for the attack-cooldown curve, a cached
enchant EPF, an exhaustion accumulator. All of it lives on the unified
[`.tags`](./mobs#tags) namespace, the same one items and mobs use:
`player.tags.<key>` and `mob.tags.<key>` read, write, and delete freeform per-entity
values without declaring a field.

::: warning There is no `set_state` / `get_state`
The old state-store builtins were **removed**. Store combat scratch state on `.tags`
instead — `set p.tags.starve_timer to n`, `set victim.tags.last_damage to dmg`. A tag read
is `optional<Any>`, so narrow it or give a fallback with `otherwise`:
:::

```swoftlang
on EntityDamage {
    set victim to event.entity
    set iframe to invulnerable_ticks(victim)
    set last to victim.tags.last_damage otherwise 0.0
    // honour the 10-tick window: a weaker-or-equal hit inside it is ignored
    if iframe > 0 and event.damage <= last {
        cancel event
        return
    }
    set victim.tags.last_damage to event.damage
}
```

Reading a tag directly without a fallback is a compile error, exactly as elsewhere:

```
w_tags.sw:3:30: error: the left operand of '+' is optional<Any> and may be missing; check it with 'if ... exists' or provide a fallback with 'otherwise'
```

## Walkthrough: `vanilla-pvp.sw`

The shipped `scripts/vanilla-pvp.sw` reimplements vanilla melee combat end-to-end using
only the primitives above — the same job MinestomPvP does in Java, but in-language. It has
two parts.

**One damage listener.** `on EntityDamage` runs the hit through the vanilla pipeline in
order: i-frames → armour + toughness → enchant protection → resistance → attack-cooldown
scale → crit → knockback → write the final amount back to `event.damage`. Every step reads
its inputs from attributes and `.tags` and writes its scratch state back to `.tags`:

```swoftlang
on EntityDamage {
    set victim to event.entity
    set raw to event.damage

    // i-frames: strongest-hit-wins inside the 10-tick window
    set iframe to invulnerable_ticks(victim)
    set last_amt to victim.tags.last_damage otherwise 0.0
    if iframe > 0 and raw <= last_amt {
        cancel event
        return
    }
    set incoming to raw
    if iframe > 0 {
        set incoming to raw - last_amt
    }

    // armour + toughness, read straight off the victim's attributes
    set armor to attribute(victim, "armor")
    set toughness to attribute(victim, "armor_toughness")
    set effective to armor - incoming / (2.0 + toughness / 4.0)
    set reduction to clamp(effective, armor * 0.2, 20.0)
    set dmg to incoming * (1.0 - reduction / 25.0)

    set victim.tags.last_damage to dmg
    set event.damage to dmg
}
```

The attacker-dependent steps — attack cooldown, crit, knockback — run only `if attacker
exists`. The attack-cooldown curve reads `attribute(attacker, "attack_speed")` and the
last-swing tick from `attacker.tags.last_swing` (compared against `attacker.alive_ticks`),
the crit check reads `fall_distance(attacker)`, and knockback folds in the target's
`knockback_resistance` before calling `apply_knockback`.

**A tick loop for regen, starvation, and exhaustion** — the loop Minestom does not run.
A `command "pvp-engine"` starts a `repeat … every 1 tick` over every online player.
Food, saturation, and health are real player properties; the exhaustion float and the
heal/starve timers live under `player.tags`:

```swoftlang
command "hunger-tick" {
    execute {
        repeat 100 times every 1 tick {
            loop all_players() as p {
                // starvation: food 0 -> 1 damage every 80 ticks, never below 1 HP
                if p.food <= 0 and p.health > 1.0 {
                    set starve_timer to p.tags.starve_timer otherwise 0
                    if starve_timer >= 80 {
                        apply_damage(p, 1.0, "starve")
                        set p.tags.starve_timer to 0
                    } else {
                        set p.tags.starve_timer to starve_timer + 1
                    }
                }
            }
        }
    }
}
```

That is the whole point of the W-pvp primitives: the reduction, crit, and regen math is
ordinary SwoftLang, and the per-entity bookkeeping is just `.tags`. In Skript the same
behaviour needs a compiled Java addon.

<MappedCompare title="Armour damage reduction on a hit" leftLabel="Skript + MinestomPvP" rightLabel="SwoftLang">
<MappedPair label="mitigate incoming damage by armour">
<template #skript>

```skript
# Skript has no armour/toughness math and no writable damage-reduction
# hook of its own — vanilla-style PvP reduction comes from a compiled
# Java addon (MinestomPvP / an Sk-addon), configured, not scripted.
on damage:
    # victim's armour value and the reduction curve are not exposed here
    set {_dmg} to damage
    # ...addon does the mitigation...
```

</template>
<template #swoftlang>

```swoftlang
on EntityDamage {
    set victim to event.entity
    set armor to attribute(victim, "armor")
    set dmg to event.damage * (1.0 - armor / 25.0)
    set event.damage to max(0.0, dmg)
}
```

</template>
<template #note>

The victim's `armor` attribute and a writable `event.damage` are all the mitigation needs,
so the curve is a few lines of plain arithmetic. Skript reaches for a compiled combat addon
because the language exposes neither the attribute nor a rewritable damage amount.

</template>
</MappedPair>
</MappedCompare>
