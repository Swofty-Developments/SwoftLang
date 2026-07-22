mob "sentinel" {
    type: "IRON_GOLEM"
    name: "<gray>Sentinel"
    on_spawn {
        // auto-cancels when this mob despawns
        set mob.tasks.patrol to schedule every 40 ticks {
            broadcast "<white>patrolling"
        }
    }
}

npc "guide" {
    location: location(5, 64, 5)
    skin: "Notch"
    on_tick {
        set npc.tasks.follow to schedule after 2 seconds every 1 seconds {
            broadcast "<yellow>following"
        }
        if npc.tasks.follow is running broadcast "following on"
        stop npc.tasks.follow
    }
}
