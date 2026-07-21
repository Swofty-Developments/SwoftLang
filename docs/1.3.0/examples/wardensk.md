---
title: WardenSK
---

<!-- swoftc-page excerpt=sources/WardenSK.sw -->

# WardenSK

A warden-anger Skript ADDON — custom expressions, conditions, effects and events built on reflection — ported to one importable module of exported functions. 273 lines of Skript, 217 of SwoftLang; exercises modules, custom mobs, lambdas, entity poses, sounds and particles.

<MappedCompare title="WardenSK_1.0.sk → WardenSK.sw — the whole file, both sides">
<MappedPair label="the addon header">
<template #skript>

```skript
# WardenSK
# Adds support for all Warden (entity) related things
# Recommended:
    # Skript 2.14+
    # Skript-Reflect 2.6.3+
    # SkBee 3.20+
    # Paper 1.21.10+
# Apologies for any inconsistencies, WardenSK is a solo project, which means it is bound to have errors.

# Lusk Warden Syntax .sk Port
# Although, few syntaxes may not function identical to Lusk.
```

</template>
<template #swoftlang>

```swoftlang
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
```

</template>
<template #note>

Four version pins (Skript, skript-reflect, SkBee, Paper) and an apology for solo-project errors become one `import` line for consumers — and the apology retires: the typechecker reads every line before the server boots.

</template>
</MappedPair>
<MappedPair label="reflection import → a declared mob">
<template #skript>

```skript
import:
    org.bukkit.entity.Entity

# _       __               __               
#| |     / /___ __________/ /__  ____  _____
#| | /| / / __ `/ ___/ __  / _ \/ __ \/ ___/
#| |/ |/ / /_/ / /  / /_/ /  __/ / / (__  ) 
#|__/|__/\__,_/_/   \__,_/\___/_/ /_/____/  

#    ______                               _                 
#   / ____/  ______  ________  __________(_)___  ____  _____
#  / __/ | |/_/ __ \/ ___/ _ \/ ___/ ___/ / __ \/ __ \/ ___/
# / /____>  </ /_/ / /  /  __(__  |__  ) / /_/ / / / (__  ) 
#/_____/_/|_/ .___/_/   \___/____/____/_/\____/_/ /_/____/  
#          /_/                                              
```

</template>
<template #swoftlang>

```swoftlang
// The .sk imports org.bukkit.entity.Entity and calls Paper methods through
// skript-reflect. No reflection here: the warden is a declared custom mob
// and every "syntax" below is an exported, typechecked function.
mob "warden" {
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
    spawn mob "warden" at at as w
    set w.name to "<dark_aqua>Warden #${warden_count}"
    return w
}
```

</template>
<template #note>

The .sk imports `org.bukkit.entity.Entity` and drives it through skript-reflect; here WARDEN is a real entity type, so the mob is declared like any other. Mobs expose no uuid property, so a warden's *name* is its identity, and `summon_warden` hands out unique ones.

</template>
</MappedPair>
<MappedPair label="anger: get / set / add / reset">
<template #skript>

```skript
# Warden - Anger (Don't get this confused with Skript's Warden Anger Level, that expression is towards a entity, this one is general anger.)
# Gets the anger level of this warden. Anger is an integer from 0 to 150. Once a Warden reaches 80 anger at a target it will actively pursue it.

expression:
    patterns:
        [the] anger of %entity% [(specific: (for %entity%))]
        %entity%'[s] anger [(specific: (for %entity%))]
    return type: integer
    get:
        if expr-2 is set:
            return expr-1.getAnger(expr-2)
        else if expr-2 is not set:
            return expr-1.getAngerLevel()
    set:
        expr-2 is set:
            expr-1.setAnger(expr-2, change value)
    add:
        expr-2 is set:
            expr-1.increaseAnger(expr-2, change value)
    reset:
        expr-2 is set:
            expr-1.clearAnger(expr-2)
```

</template>
<template #swoftlang>

```swoftlang
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
```

</template>
<template #note>

A pattern grammar with five changer blocks becomes four functions. `clamp(value, 0, 150)` matches the Paper range. Skript read highest and prey back from Paper on demand; here both are tracked as the anger is written, so clearing the current prey's anger leaves `highest` at its old value until the next write updates it.

</template>
</MappedPair>
<MappedPair label="prey">
<template #skript>

```skript
# Warden - (Prey)
# Returns the entity at which this warden is most angry.

expression:
    patterns:
        [the] prey of %entity%
        %entity%'[s] prey
    return type: livingEntity
    get:
        expr-1 = warden
        return expr-1.getEntityAngryAt()
    set:
        expr-1.setAnger(change value)
    remove: 
        entity.clearAnger(change value)
```

</template>
<template #swoftlang>

```swoftlang
// ── Warden - Prey ────────────────────────────────────────────────────────
// 'the entity at which this warden is most angry', as optional<Player>.

export function warden_prey(w: Mob) {
    set prey_name to warden_data("prey:${w.name}")
    if prey_name exists return player(prey_name)
    return none
}
```

</template>
<template #note>

`getEntityAngryAt()` → the stored prey name resolved through `player(name)` — an `optional<Player>`, so a logged-off prey is provably `missing`, never null.

</template>
</MappedPair>
<MappedPair label="past/future anger → listener arguments">
<template #skript>

```skript
# Warden Anger (Event)
# Returns the past/future anger of the warden in the Warden Anger Change event.
# The future anger level can be set.

expression:
    patterns:
        [the] [future: future|past: past] anger [level] [of [the] warden]
    return type: integer
    usable in:
        WardenAngerChangeEvent
    get:
        if first element of parse tags is not set:
            return the anger of (event.getEntity())
        else if the first element of parse tags contains "future":
            return {-futureAnger::%(event.getEntity())%}
            delete {-futureAnger::%(event.getEntity())%}
        else if the first element of parse tags contains "future":
            return {-pastAnger::%(event.getEntity())%}
            delete {-pastAnger::%(event.getEntity())%}
    set:
        event.getEntity().setNewAnger(change value)
```

</template>
<template #swoftlang>

```swoftlang
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
```

</template>
<template #note>

The .sk parks old/new anger in `{-pastAnger::}` / `{-futureAnger::}` side-channel list vars so a parse-tagged expression can fish them back out. Listeners here are first-class lambdas and old/new anger arrive as *arguments* — nothing to stash, nothing to clean up.

</template>
</MappedPair>
<MappedPair label="highest anger">
<template #skript>

```skript
# Warden - Highest Anger Level || NOT IN LUSK
# Anger is an integer from 0 to 150. Once a Warden reaches 80 anger at a target it will actively pursue it.

expression:
    patterns:
        [the] highest anger [level] of %livingEntity%
        %livingEntity%'s highest anger [level]
    return type: integer
    get:
        return expr-1.getHighestAnger()
```

</template>
<template #swoftlang>

```swoftlang
// ── Warden - Highest Anger / general anger ───────────────────────────────
// the .sk's '%entity%'s anger' without a target, and its 'highest anger'.

export function warden_anger(w: Mob) {
    set stored to warden_data("highest:${w.name}")
    if stored exists return stored
    return 0
}
```

</template>
<template #note>

Same registry read as the general anger expression — the .sk needed a second expression block for the second pattern spelling.

</template>
</MappedPair>
<MappedPair label="five spellings of “is it angry”">
<template #skript>

```skript
# Warden - Angry State
# Returns the Angry State of an entity.
# (Warden, PigZombie, Wolf, Enderman)
# Can be set for all except wardens.

expression:
    patterns:
        [the] ang(ry|er) state of %entity%
        %entity%'[s] ang(ry|er) state
        whether %entity% is angry [or not]
        whether [or not] %entity% is angry
    return type: boolean
    get:
        if expr-1 is angry:
            return true
        else if expr-1 isn't angry:
            return false

# Warden - Is Angry (Property)

expression:
    patterns:
        [the] [is] angry of %livingentities%
        %livingentities%'[s] [is] angry
    return type: boolean
    get:
        return whether expr-1 is angry

#   ______                ___ __  _                 
#  / ____/___  ____  ____/ (_) /_(_)___  ____  _____
# / /   / __ \/ __ \/ __  / / __/ / __ \/ __ \/ ___/
#/ /___/ /_/ / / / / /_/ / / /_/ / /_/ / / / (__  ) 
#\____/\____/_/ /_/\__,_/_/\__/_/\____/_/ /_/____/  

# Warden - Is Agitated
# Checks if a Warden is agitated.

condition:
    patterns:
        %livingentities% (is|are|=) agitated
        %livingentities% (negative:(isn't|is not|aren't|are not|!=)) agitated
    check:
        if first element of parse tags contains "negative":
            loop exprs-1:
                if expr-1's anger is between 40 and 79:
                    stop
                continue
        else if first element of parse tags is not set:
            loop exprs-1:
                if expr-1's anger isn't between 40 and 79:
                    stop
                continue

# Warden - Is Angry
# Checks if a Warden is agitated.

condition:
    patterns:
        %livingentities% (is|are|=) angry
        %livingentities% (negative:(isn't|is not|aren't|are not|!=)) angry
    check:
        if first element of parse tags contains "negative":
            loop exprs-1:
                if expr-1's anger is between 80 and 150:
                    stop
                continue
        else if first element of parse tags is not set:
            loop exprs-1:
                if expr-1's anger isn't between 80 and 150:
                    stop
                continue

# Warden - Is Calm
# Checks if a Warden is calm.

condition:
    patterns:
        %livingentities% (is|are|=) calm
        %livingentities% (negative:(isn't|is not|aren't|are not|!=)) calm
    check:
        if first element of parse tags contains "negative":
            loop exprs-1:
                if expr-1's anger is between 0 and 39:
                    stop
                continue
        else if first element of parse tags is not set:
            loop exprs-1:
                if expr-1's anger isn't between 0 and 39:
                    stop
                continue
```

</template>
<template #swoftlang>

```swoftlang
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
```

</template>
<template #note>

An angry-state expression, an is-angry property, and three double-pattern conditions (negation via parse tags, multi-entity via `exprs-1` loops) — five Skript registrations — are three Boolean functions. Negation is `not` at the call site; many-mobs is a loop. The language already had the grammar.

</template>
</MappedPair>
<MappedPair label="disturb">
<template #skript>

```skript
#    ______________          __      
#   / ____/ __/ __/__  _____/ /______
#  / __/ / /_/ /_/ _ \/ ___/ __/ ___/
# / /___/ __/ __/  __/ /__/ /_(__  ) 
#/_____/_/ /_/  \___/\___/\__/____/  

# Warden - Disturb
# Makes a warden sense a disturbance at the provided location.

effect:
    patterns:
        disturb %livingentities% from %location%
    trigger:
        expr-1 = warden
        expr-1.setDisturbanceLocation(expr-2)
```

</template>
<template #swoftlang>

```swoftlang
// ── Warden - Disturb (effect) ────────────────────────────────────────────
// no pathfinding hook to hand a disturbance to, so the closest observable
// behavior: the warden's listening cue plays and the sculk flares there.

export function disturb(w: Mob, from: Location) {
    play sound "entity.warden.listening" to all at from
    spawn particle "sculk_charge_pop" at from count 12 offset 0.3, 0.3, 0.3
}
```

</template>
<template #note>

Custom-mob AI is melee/passive/none, so the port expresses the disturbance as its observable signature rather than a pathfinding nudge: the warden's listening cue plays and the sculk flares at the spot — the part a player actually sees.

</template>
</MappedPair>
<MappedPair label="the anger-change event">
<template #skript>

```skript
#    ______                 __      
#   / ____/   _____  ____  / /______
#  / __/ | | / / _ \/ __ \/ __/ ___/
# / /___ | |/ /  __/ / / / /_(__  ) 
#/_____/ |___/\___/_/ /_/\__/____/  

# On Warden - On Anger Change

import:
    io.papermc.paper.event.entity.WardenAngerChangeEvent

event "On Warden - On Anger Change":
    patterns:
        [on] warden anger chang(e[d]|ing)
    event-values: command sender, entity, entity type, location, world

on WardenAngerChangeEvent:
    set {_eventValues::commandSender} to event.getTarget()
    set {_eventValues::entity} to event.getEntity()
    set {_eventValues::entityType} to event.getEntityType()
    set {_eventValues::location} to event.getEntity()'s location
    set {_eventValues::world} to world of (event.getEntity()'s location)
    set {_event} to (custom event "On Warden - On Anger Change" using event-values {_eventValues::*})
    call {_event}
    if {_event}.isCancelled():
        cancel event
        event.setCancelled(true)
    set {-pastAnger::%event.getEntity()%} to event.getOldAnger()
    set {-futureAnger::%event.getEntity()%} to event.getNewAnger()
```

</template>
<template #swoftlang>

```swoftlang
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
```

</template>
<template #note>

The .sk registers a custom event, listens to the Bukkit one, copies event-values into a list var and re-fires. Here `set_warden_anger` calls the listener chain directly, and gameplay feeds the same registry: `Mob { on_hit }` bumps anger by 100 like vanilla. The mob is bound as `mob` and the hit's source may be a non-player, so the port picks the nearest player as the aggressor — a small deliberate heuristic, and the registry it feeds is the one the listeners already watch.

</template>
</MappedPair>
<MappedPair label="sniff toggle">
<template #skript>

```skript
# On Warden - On Sniff Toggle

import:
    org.bukkit.event.entity.EntityPoseChangeEvent

event "On Warden - on Sniff Toggle": # When using IntelliSkript, highlights/colors may not show.
    patterns:
        [on] warden (start:(sniff[ing] [start|begin]|start sniffing))
        [on] warden (stop:(sniff[ing] stop|stop sniffing))
        [on] warden (sniff toggle|toggle sniff)
    event-values: command sender, entity, entity type, location, pose, world, pose
    check:
        first element of parse tags is set
        if first element of parse tags contains "start":
            if pose != sniffing_pose:
                stop
            continue
        else if first element of parse tags contains "stop":
            if pose = sniffing_pose:
                stop
            continue

on entity pose change: # You need SkBee 3.20+
    event-entity = warden
    if any:
        event-pose = sniffing_pose
        past event-pose = sniffing_pose
    then:
        set {_eventValues::commandSender} to event-commandSender
        set {_eventValues::entity} to event-entity
        set {_eventValues::entityType} to event-entityType
        set {_eventValues::location} to event-location
        set {_eventValues::pose::pose} to event-pose
        set {_eventValues::world} to event-world
        set {_eventValues::pose::pastPose} to past event-pose
        set {_event} to (custom event "On Warden - on Sniff Toggle" using event-values {_eventValues::*})
        call {_event}
```

</template>
<template #swoftlang>

```swoftlang
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
```

</template>
<template #note>

`pose` is a writable entity row (an `EntityPose` enum, snake-case names validated at compile time). The .sk waited for the vanilla warden to *enter* its sniffing pose; the module drives it directly — `sniff_all` sets every warden's pose to `sniffing` (or back to `standing`) and notifies the listeners, the same first-class-lambda chain the anger events use.

</template>
</MappedPair>
</MappedCompare>
