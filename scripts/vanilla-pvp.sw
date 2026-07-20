// Vanilla melee combat, implemented entirely in SwoftLang on top of the W-pvp
// primitives. Minestom ships NO combat mechanics — no armor reduction, no
// knockback, no crits, no attack cooldown, no i-frame timer, no natural regen.
// MinestomPvP reimplements all of it in Java by (a) listening to a couple of
// native events, (b) reading/writing attributes + velocity, and (c) tracking a
// handful of per-entity values in tags. This script does the exact same thing —
// but in-language — using only:
//
//   * the enriched EntityDamage event    (event.damage / attacker / entity)
//   * attribute(e, key)                  (armor, toughness, attack_speed, kb-res)
//   * the unified tags namespace          (entity.tags / player.tags — i-frames,
//                                          cd, exhaustion, cached enchant EPF, timers)
//   * the native trackers Minestom hides  (invulnerable_ticks / fall_distance)
//   * the combat effects                  (apply_knockback / apply_damage)
//   * spawn particle                      (the crit sparkle)
//   * food / food_saturation / health     (regen + starvation on a tick loop)
//
// All the reduction / knockback / crit / regen MATH is plain SwoftLang. That is
// the whole point: the primitives are enough to write vanilla PvP in .sw, where
// Skript would need a compiled Java addon (MinestomPvP / an Sk-addon) to do it.

// ---------------------------------------------------------------------------
// Damage-reduction math (exact vanilla / MinestomPvP constants)
// ---------------------------------------------------------------------------

// Armor + toughness curve: reduction = clamp(armor - dmg/(2 + tough/4),
// armor*0.2, 20); the hit is then scaled by (1 - reduction/25).
function armor_mitigated(raw: Double, armor: Double, toughness: Double) {
    set effective to armor - raw / (2.0 + toughness / 4.0)
    set reduction to clamp(effective, armor * 0.2, 20.0)
    return raw * (1.0 - reduction / 25.0)
}

// Enchantment protection: the summed EPF (capped at 20) scales the hit by
// (1 - EPF/25). The EPF is cached per-entity in victim.tags.protection_epf by
// whatever equips the armour; here we just read it.
function protection_mitigated(dmg: Double, epf: Double) {
    return dmg * (1.0 - clamp(epf, 0.0, 20.0) / 25.0)
}

// Resistance potion: -20% per level. `amp` is the raw amplifier (level - 1);
// a stored value of -1 means the effect is absent.
function resistance_mitigated(dmg: Double, amp: Double) {
    if amp < 0.0 {
        return dmg
    }
    return dmg * (25.0 - (amp + 1.0) * 5.0) / 25.0
}

// ---------------------------------------------------------------------------
// The one damage listener: i-frames -> armor -> protection -> resistance ->
// attack-cooldown scale -> crit -> knockback -> write back the final amount.
// ---------------------------------------------------------------------------

on EntityDamage {
    set victim to event.entity
    set raw to event.damage

    // ---- i-frames: honour the vanilla 10-tick invulnerability window ----
    // A weaker-or-equal hit inside the window is ignored; a stronger hit only
    // deals the surplus over the last hit (Minecraft's "strongest hit wins").
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

    // ---- armor + toughness + enchant protection + resistance ----
    set armor to attribute(victim, "armor")
    set toughness to attribute(victim, "armor_toughness")
    set epf to victim.tags.protection_epf otherwise 0.0
    set res_amp to victim.tags.resistance_amp otherwise -1.0

    set dmg to armor_mitigated(incoming, armor, toughness)
    set dmg to protection_mitigated(dmg, epf)
    set dmg to resistance_mitigated(dmg, res_amp)

    // ---- everything that needs a living attacker: cooldown, crit, knockback ----
    set attacker to event.attacker
    if attacker exists {
        // Attack cooldown (1.9+): scale = clamp((ticksSinceSwing + 0.5) /
        // cooldownTicks, 0, 1); damage *= 0.2 + scale^2 * 0.8. cooldownTicks is
        // 20 / attackSpeed. The last-swing tick lives in attacker.tags.
        set speed to attribute(attacker, "attack_speed")
        set cd_ticks to 20.0 / speed
        set last_swing to attacker.tags.last_swing otherwise 0
        set since to attacker.alive_ticks - last_swing
        set charge to clamp((since + 0.5) / cd_ticks, 0.0, 1.0)
        set dmg to dmg * (0.2 + charge * charge * 0.8)
        set attacker.tags.last_swing to attacker.alive_ticks

        // Critical hit: attacker is falling (fall_distance > 0), airborne, and
        // (1.9+) not sprinting. 1.5x plus the crit sparkle at the victim.
        set is_crit to false
        if fall_distance(attacker) > 0.0 and not attacker.on_ground and not attacker.is_sprinting {
            set is_crit to true
        }
        if is_crit {
            set dmg to dmg * 1.5
            spawn particle "crit" at event.entity.location count 8 offset 0.4, 0.6, 0.4 speed 0.1 to all
        }

        // Knockback: base 0.4 horizontal, +0.5 for a sprint hit, +0.5 per
        // Knockback level, all scaled down by the target's knockback resistance.
        // apply_knockback builds the vanilla vector from the (dx, dz) direction.
        set sprint_bonus to 0.0
        if attacker.is_sprinting {
            set sprint_bonus to 1.0
        }
        set kb_level to attacker.tags.knockback_level otherwise 0.0
        set kb_resist to attribute(victim, "knockback_resistance")
        set strength to (0.4 + sprint_bonus * 0.5 + kb_level * 0.5) * (1.0 - kb_resist)

        set vloc to event.entity.location
        set aloc to attacker.location
        apply_knockback(victim, strength, vloc.x - aloc.x, vloc.z - aloc.z)
    }

    // Remember this hit for the i-frame comparison, then commit the reduced
    // amount back to the event so the engine subtracts the right number.
    set victim.tags.last_damage to dmg
    set event.damage to dmg
}

// ---------------------------------------------------------------------------
// Natural regeneration, starvation, and the exhaustion accumulator — the tick
// loop Minestom does not run. Started once; ticks every game tick over every
// online player. Food/saturation/health are real properties; the exhaustion
// float and the two heal/starve timers live under player.tags.
// ---------------------------------------------------------------------------

command "pvp-engine" {
    description: "Start the vanilla regen / hunger / exhaustion tick loop"

    execute {
        repeat 1728000 times every 1 tick {
            loop all_players() as p {
                set exhaustion to p.tags.exhaustion otherwise 0.0

                // Natural regen: food >= 18 and below max health -> 1 HP every
                // 80 ticks, at a cost of 6.0 exhaustion.
                if p.food >= 18 and p.health < p.max_health {
                    set heal_timer to p.tags.regen_timer otherwise 0
                    if heal_timer >= 80 {
                        set p.health to min(p.max_health, p.health + 1.0)
                        set exhaustion to exhaustion + 6.0
                        set p.tags.regen_timer to 0
                    } else {
                        set p.tags.regen_timer to heal_timer + 1
                    }
                }

                // Starvation: food <= 0 -> 1 magic-less damage every 80 ticks,
                // never below 1 HP (normal difficulty).
                if p.food <= 0 and p.health > 1.0 {
                    set starve_timer to p.tags.starve_timer otherwise 0
                    if starve_timer >= 80 {
                        apply_damage(p, 1.0, "starve")
                        set p.tags.starve_timer to 0
                    } else {
                        set p.tags.starve_timer to starve_timer + 1
                    }
                }

                // Drain the exhaustion accumulator: every whole 4.0 units burns
                // one saturation point, or one food point once saturation is gone.
                if exhaustion >= 4.0 {
                    set exhaustion to exhaustion - 4.0
                    if p.food_saturation > 0.0 {
                        set p.food_saturation to max(0.0, p.food_saturation - 1.0)
                    } else {
                        set p.food to max(0, p.food - 1)
                    }
                }

                set p.tags.exhaustion to exhaustion
            }
        }
    }
}
