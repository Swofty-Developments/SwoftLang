// WardenSK_1.0.sk port — a Skript ADDON (custom expressions, conditions,
// effects and events built on reflection) becoming a SwoftLang MODULE:
// plain exported functions over module state. Drop this file in addons/
// and consume it with:  import "WardenSK"
//
//   set w to summon_warden(location(0.5, 64.0, 0.5))
//   increase_warden_anger(w, some_player, 100)
//   if warden_is_angry(w) { ... }
//   on_warden_anger_change(function(warden_name: String, target_name: String,
//                                   old_anger: Integer, new_anger: Integer) {
//       broadcast "<red>${warden_name} now ${new_anger} at ${target_name}"
//   })

// The .sk imports org.bukkit.entity.Entity and calls Paper methods through
// skript-reflect. No reflection here: the warden is a declared custom mob
// and every "syntax" below is an exported, typechecked function.
mob Warden {
    type: "WARDEN"
    name: "<dark_aqua>Warden"
    health: 500
    damage: 30
    ai: none

    on_spawn {
        broadcast "<dark_aqua>The ground trembles..."
    }
}

// anger registry: association chain keyed "anger:<warden>:<target>",
// "highest:<warden>", "prey:<warden>". Mobs carry no uuid property, so a
// warden's NAME is its identity — summon_warden hands out unique ones.
var warden_data = function(lookup: String) return none
var warden_count = 0

function warden_put(key: String, value) {
    set previous to warden_data
    set warden_data to function(lookup: String) {
        if lookup is key return value
        return previous(lookup)
    }
}

export function summon_warden(at: Location) {
    set warden_count to warden_count + 1
    spawn mob Warden at at as w
    set w.name to "<dark_aqua>Warden #${warden_count}"
    return w
}

// ── Warden - Anger ───────────────────────────────────────────────────────
// get / set / add / reset of the .sk's anger expression. Anger is clamped
// to 0..150 like the Paper API it wrapped; 80+ means active pursuit.

export function warden_anger_at(w: Mob, target: Player) {
    set stored to warden_data("anger:${w.name}:${target.name}")
    if stored exists return stored
    return 0
}

export function set_warden_anger(w: Mob, target: Player, value: Integer) {
    set old_anger to warden_anger_at(w, target)
    set new_anger to clamp(value, 0, 150)
    warden_put("anger:${w.name}:${target.name}", new_anger)

    // maintain highest + prey (the .sk gets both free from Paper); a drop
    // on the current prey keeps the prey and lowers the highest
    set highest to warden_anger(w)
    if new_anger >= highest {
        warden_put("highest:${w.name}", new_anger)
        warden_put("prey:${w.name}", target.name)
    } else {
        set prey_name to warden_data("prey:${w.name}")
        if prey_name exists {
            if prey_name is target.name {
                warden_put("highest:${w.name}", new_anger)
            }
        }
    }

    fire_anger_change(w.name, target.name, old_anger, new_anger)
}

export function increase_warden_anger(w: Mob, target: Player, amount: Integer) {
    set_warden_anger(w, target, warden_anger_at(w, target) + amount)
}

export function clear_warden_anger(w: Mob, target: Player) {
    set_warden_anger(w, target, 0)
}

// ── Warden - Prey ────────────────────────────────────────────────────────
// 'the entity at which this warden is most angry', as Optional<Player>.

export function warden_prey(w: Mob) {
    set prey_name to warden_data("prey:${w.name}")
    if prey_name exists return player(prey_name)
    return none
}

// ── Warden - anger change listeners ──────────────────────────────────────
// The .sk defines an 'anger [level]' event expression with past/future
// parse tags, fed by {-pastAnger::}/{-futureAnger::} side-channel list
// vars. Listeners here are first-class lambdas and old/new anger arrive
// as ARGUMENTS — no side channel to stash or clean up.

var anger_listeners = function(warden_name: String, target_name: String,
                               old_anger: Integer, new_anger: Integer) return 0

export function on_warden_anger_change(handler) {
    set previous to anger_listeners
    set anger_listeners to function(warden_name: String, target_name: String,
                                    old_anger: Integer, new_anger: Integer) {
        handler(warden_name, target_name, old_anger, new_anger)
        previous(warden_name, target_name, old_anger, new_anger)
        return 0
    }
}

function fire_anger_change(warden_name: String, target_name: String,
                           old_anger: Integer, new_anger: Integer) {
    anger_listeners(warden_name, target_name, old_anger, new_anger)
}

// ── Warden - Highest Anger / general anger ───────────────────────────────
// the .sk's '%entity%'s anger' without a target, and its 'highest anger'.

export function warden_anger(w: Mob) {
    set stored to warden_data("highest:${w.name}")
    if stored exists return stored
    return 0
}

// ── Angry State / Is Angry / conditions ──────────────────────────────────
// the .sk spells "is it angry" five ways: an angry-state expression, an
// is-angry property, and three double-pattern conditions with negation
// handled by parse tags. A Boolean-returning function is all of them;
// 'not' comes from the language.

export function warden_is_calm(w: Mob) {
    return warden_anger(w) <= 39
}

export function warden_is_agitated(w: Mob) {
    set a to warden_anger(w)
    return a >= 40 and a <= 79
}

export function warden_is_angry(w: Mob) {
    return warden_anger(w) >= 80
}

// ── Warden - Disturb (effect) ────────────────────────────────────────────
// no pathfinding hook to hand a disturbance to, so the closest observable
// behavior: the warden's listening cue plays and the sculk flares there.

export function disturb(w: Mob, from: Location) {
    play sound "entity.warden.listening" to all at from
    spawn particle "sculk_charge_pop" at from count 12 offset 0.3, 0.3, 0.3
}

// ── Events ───────────────────────────────────────────────────────────────
// The .sk bridges WardenAngerChangeEvent into a custom Skript event by
// copying event-values into a list var and re-calling it. Here gameplay
// drives the same registry the listeners already watch: hitting a warden
// enrages it (vanilla raises attacker anger to ~100). The hit's source may be
// a non-player, so the nearest player takes the blame.

Mob {
    on_hit {
        if mob.custom_id is "warden" {
            set best to 999999999.0
            set nearest to player("")
            loop all players as p {
                set dx to p.location.x - mob.location.x
                set dy to p.location.y - mob.location.y
                set dz to p.location.z - mob.location.z
                set d to dx * dx + dy * dy + dz * dz
                if d < best {
                    set best to d
                    set nearest to p
                }
            }
            if nearest exists {
                increase_warden_anger(mob, nearest, 100)
            }
        }
    }
}

// ── Warden - Sniff toggle ────────────────────────────────────────────────
// The .sk's 'On Warden - On Sniff Toggle' fired when the vanilla warden
// entered or left its sniffing pose (SkBee's pose-change event plus parse
// tags). Pose is a writable entity row now, so the module DRIVES the pose
// instead of waiting to observe it: sniff_all puts every warden into (or out
// of) its sniffing pose and notifies the listeners with the new state.

var sniff_listeners = function(sniffing: Boolean) return 0

export function on_warden_sniff_toggle(handler) {
    set previous to sniff_listeners
    set sniff_listeners to function(sniffing: Boolean) {
        handler(sniffing)
        previous(sniffing)
        return 0
    }
}

export function sniff_all(sniffing: Boolean) {
    loop all_entities("WARDEN") as w {
        if sniffing {
            set w.pose to "sniffing"
        } else {
            set w.pose to "standing"
        }
    }
    sniff_listeners(sniffing)
}
