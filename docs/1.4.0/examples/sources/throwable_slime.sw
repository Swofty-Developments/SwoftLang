// throwable_slime.sk port — bouncing thrown slime balls.
//
// Skript rides a real snowball entity and re-shoots it on every bounce to
// keep vanilla physics from eating the reflection. This port OWNS the
// physics: an item display plus an async tick loop — velocity, gravity,
// bounces and hits are all script state, and no respawn-on-bounce trick is
// needed. A right-click hands the ball to the fly_slime task.

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

Player {
    on_use_item {
        if item.material is "SLIME_BALL" {
            cancel event

            // yaw/pitch -> unit direction (what 'make player shoot' hid)
            set yaw to player.location.yaw
            set pitch to player.location.pitch
            set dx to 0.0 - slime_sin_deg(yaw) * slime_cos_deg(pitch)
            set dy to 0.0 - slime_sin_deg(pitch)
            set dz to slime_cos_deg(yaw) * slime_cos_deg(pitch)

            set eye to location(
                player.location.x,
                player.location.y + 1.6,
                player.location.z)
            set disp to spawn_item_display("SLIME_BALL", eye)

            // velocity 1.2, like 'shoot snowball at velocity 1.2'
            spawn fly_slime(disp,
                eye.x, eye.y, eye.z,
                dx * 1.2, dy * 1.2, dz * 1.2)

            // 'subtract 1 slime ball from player's tool'
            set player.held_item.amount to player.held_item.amount - 1
        }
    }
}

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
