---
title: Throwable slime
---

<!-- swoftc-page excerpt=sources/throwable_slime.sw -->

# Throwable slime

Slime balls that fly, bounce off walls and sting on contact — projectile physics owned by an async tick loop. Thrown by hand or fired from a dispenser, both feeding the same flight task. 101 lines of Skript, 155 of SwoftLang; exercises async tasks, item displays, the dispenser event and script-side math.

<MappedCompare title="throwable_slime.sk → throwable_slime.sw — the whole file, both sides">
<MappedPair label="the aim math">
<template #skript>

*`make player shoot snowball at velocity 1.2` — the engine computes the launch direction for you*

</template>
<template #swoftlang>

```swoftlang
// throwable_slime.sk port — bouncing thrown slime balls.
//
// Skript rides a real snowball entity and re-shoots it on every bounce to
// keep vanilla physics from eating the reflection. This port OWNS the
// physics: an item display plus an async tick loop — velocity, gravity,
// bounces and hits are all script state, and no respawn-on-bounce trick is
// needed. The same fly_slime task launches a ball whether a player throws
// one or a dispenser fires one.

// sin/cos via Bhaskara I's approximation — the language ships no trig
// builtins (same dodge as the npcs addon's atan2). Degrees in, [-1,1] out.
function slime_wrap_deg(a: Double) {
    set r to a
    while r > 180.0 {
        set r to r - 360.0
    }
    while r < -180.0 {
        set r to r + 360.0
    }
    return r
}

function slime_sin_deg(a: Double) {
    set x to slime_wrap_deg(a)
    if x < 0.0 {
        set x to 0.0 - x
        set n to x * (180.0 - x)
        return 0.0 - 4.0 * n / (40500.0 - n)
    }
    set n to x * (180.0 - x)
    return 4.0 * n / (40500.0 - n)
}

function slime_cos_deg(a: Double) {
    return slime_sin_deg(90.0 - a)
}
```

</template>
<template #note>

The port owns the whole flight, so it recovers the direction vector `make player shoot` hid — yaw/pitch through Bhaskara I's sine approximation (the npcs stdlib addon does the same for atan2). Twenty-five lines, written once, reused by both entry points.

</template>
</MappedPair>
<MappedPair label="throwing on right-click">
<template #skript>

```skript
on right click with slime ball:
	make player shoot snowball at velocity 1.2
	set {_proj} to the shot projectile
	set {_item} to a slime ball
	{_proj}.setItem({_item})
	set {_proj}'s metadata tag "TimeCreated" to now
	set {_proj}'s metadata tag "CollisionCount" to 0
	subtract 1 slime ball from player's tool
```

</template>
<template #swoftlang>

```swoftlang
event PlayerUseItem {
    execute {
        if event.item.material is "SLIME_BALL" {
            cancel event

            // yaw/pitch -> unit direction (what 'make player shoot' hid)
            set yaw to event.player.location.yaw
            set pitch to event.player.location.pitch
            set dx to 0.0 - slime_sin_deg(yaw) * slime_cos_deg(pitch)
            set dy to 0.0 - slime_sin_deg(pitch)
            set dz to slime_cos_deg(yaw) * slime_cos_deg(pitch)

            set eye to location(
                event.player.location.x,
                event.player.location.y + 1.6,
                event.player.location.z)
            set disp to spawn_item_display("SLIME_BALL", eye)

            // velocity 1.2, like 'shoot snowball at velocity 1.2'
            spawn fly_slime(disp,
                eye.x, eye.y, eye.z,
                dx * 1.2, dy * 1.2, dz * 1.2)

            // 'subtract 1 slime ball from player's tool'
            set event.player.held_item.amount to event.player.held_item.amount - 1
        }
    }
}
```

</template>
<template #note>

`on right click with slime ball` → `PlayerUseItem` plus a material guard. The .sk's `TimeCreated` / `CollisionCount` metadata tags become plain locals of the flight task. `subtract 1 from tool` is a `held_item.amount` write.

</template>
</MappedPair>
<MappedPair label="dispenser launch">
<template #skript>

```skript
on dispense of slime ball:
	cancel event
	set {_pos} to (event-block's location) ~ (vector from (facing of block))
	shoot snowball from {_pos} at velocity 1.2 (event-block's facing)
	set {_proj} to the shot projectile
	set {_item} to a slime ball
	{_proj}.setItem({_item})
	set {_proj}'s metadata tag "TimeCreated" to now
	set {_proj}'s metadata tag "CollisionCount" to 0
	remove 1 slime ball from inventory of event-block
```

</template>
<template #swoftlang>

```swoftlang
// 'on dispense of slime ball' — the dispenser fires the same bouncing ball.
// BlockDispense hands us the block's position and facing; cancel the vanilla
// item eject and launch fly_slime from the block toward its facing at the
// same velocity 1.2 the thrower uses.
event BlockDispense {
    execute {
        if event.item exists {
            if event.item.material is "SLIME_BALL" {
                cancel event
                set dir to event.direction
                set disp to spawn_item_display("SLIME_BALL", event.location)
                spawn fly_slime(disp,
                    event.location.x, event.location.y, event.location.z,
                    dir.x * 1.2, dir.y * 1.2, dir.z * 1.2)
            }
        }
    }
}
```

</template>
<template #note>

`on dispense of slime ball` maps straight onto the [`BlockDispense`](/reference/dispensers#the-blockdispense-event) event: it hands the handler the block's `location`, its facing `direction`, and the `item` about to leave. Cancel the vanilla eject and hand the position and direction to the *same* `fly_slime` task the thrower uses — one bouncing ball, two ways to launch it. The .sk's `~ vector from facing` offset and metadata tags fold into that shared task.

</template>
</MappedPair>
<MappedPair label="flight, bounces, lifetime">
<template #skript>

```skript
on projectile hit:
	projectile is snowball
	event-block's block data is not air # hopefully prevents collisions with entities. Have not tested
	if projectile.getItem() = slime ball:
		cancel event
		if all:
			((projectile's velocity)'s vector length) > 0.4
			projectile has metadata tag "TimeCreated"
			projectile has metadata tag "CollisionCount"
			time since (metadata tag "TimeCreated" of (projectile)) < 60 seconds
			(metadata tag "CollisionCount" of (projectile)) < 100
		then:
			set {_pos} to (the vector from (event-block's location) to ((projectile)'s location))
			set {_absx} to abs({_pos}'s x)
			set {_absy} to abs({_pos}'s y)
			set {_absz} to abs({_pos}'s z)

			if all:
				{_absx} > {_absy}
				{_absx} > {_absz}
			then:
				if {_pos}'s x < 0:
					teleport projectile to ((event-location) ~ vector((-0.1 - (((projectile)'s velocity)'s x * 0.1)), 0, 0))
				else:
					teleport projectile to ((event-location) ~ vector((0.1 - (((projectile)'s velocity)'s x * 0.1)), 0, 0))
				set ((projectile's velocity)'s x) to (-1 * (projectile's velocity)'s x)
			# ... y and z faces likewise ...
			shoot a snowball from (projectile's location) with speed 0 up:
				set (projectile)'s velocity to {_proj}'s velocity
				set {_item} to a slime ball
				(projectile).setItem({_item})
			kill event-projectile
		else:
			drop (a slime ball) at ((event-location) ~ (normalized (projectile's velocity))*-0.2) without velocity
			kill event-projectile
```

</template>
<template #swoftlang>

```swoftlang
// One task per thrown ball: 20 steps/second, at most 60 seconds or 100
// bounces (the .sk's TimeCreated / CollisionCount metadata, as plain locals).
async function fly_slime(disp: Display,
                         px: Double, py: Double, pz: Double,
                         vx: Double, vy: Double, vz: Double) {
    set bounces to 0
    loop 1200 times {
        wait 1 ticks

        // snowball-ish gravity and drag
        set vy to vy - 0.03
        set vx to vx * 0.99
        set vy to vy * 0.99
        set vz to vz * 0.99

        // velocity is blocks-per-tick, exactly Minecraft's convention
        set nx to px + vx
        set ny to py + vy
        set nz to pz + vz

        if block_at(location(nx, ny, nz)) != "minecraft:air" {
            set speed2 to vx * vx + vy * vy + vz * vz
            if speed2 < 0.16 or bounces >= 100 {
                // rest where it landed, then clean up
                wait 10 seconds
                destroy display disp
                return
            }
            set bounces to bounces + 1

            // reflect the dominant penetration axis, exactly like the .sk:
            // offset from the block centre decides which face we struck
            set cx to floor(nx) + 0.5
            set cy to floor(ny) + 0.5
            set cz to floor(nz) + 0.5
            set ax to abs(nx - cx)
            set ay to abs(ny - cy)
            set az to abs(nz - cz)
            if ax > ay and ax > az {
                set vx to 0.0 - vx
            } else if ay > ax and ay > az {
                set vy to 0.0 - vy
            } else {
                set vz to 0.0 - vz
            }
        } else {
            set px to nx
            set py to ny
            set pz to nz
            teleport display disp to location(px, py, pz)
        }
```

</template>
<template #note>

The .sk's wildest trick — reflect the velocity, then *kill the snowball and shoot a fresh one* so vanilla physics doesn't undo the bounce, copying both metadata tags across — collapses to one sign flip: the task owns velocity. The dominant-axis pick mirrors the .sk's abs() compares; lifetime is `loop 1200 times` (60 s) and a 100-bounce cap; the landed ball rests where it stopped.

</template>
</MappedPair>
<MappedPair label="hitting someone">
<template #skript>

```skript
on projectile collide:
	projectile is snowball
	projectile.getItem() = slime ball

	if all:
		event-entity is a player
		event-entity's gamemode is creative
	then:
		stop

	damage the entity by 1 hearts
	knock entity (projectile's velocity) with strength ((projectile's velocity)'s vector length*0.5)
```

</template>
<template #swoftlang>

```swoftlang
        // 'on projectile collide' — hit detection is our loop now
        loop all players as victim {
            set hx to victim.location.x - px
            set hy to victim.location.y + 0.9 - py
            set hz to victim.location.z - pz
            if hx * hx + hy * hy + hz * hz < 0.75 {
                if victim.gamemode != "creative" {
                    // 'damage the entity by 1 hearts'
                    set victim.health to max(victim.health - 2.0, 0.0)
                    play sound "entity.slime.squish" to victim
                }
                destroy display disp
                return
            }
        }
    }
    destroy display disp
}
```

</template>
<template #note>

`on projectile collide` becomes a distance check inside the flight loop. Creative players are waved through, and a hit is 1 heart (`health - 2.0`) plus the slime squish — the sting and the sound, landed straight from the task that already knows exactly where the ball is.

</template>
</MappedPair>
</MappedCompare>
