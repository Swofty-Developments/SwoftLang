// W-tasks: first-class per-object task registry (<obj>.tasks.<id>), a separate
// namespace from .tags whose values are Schedule handles. A named task is bound
// to any object, referenced by id, cancelled by id, and (at runtime)
// auto-cancelled when the owner goes away. Also: imperative block placement
// (place ... at ...) and removal (remove block at ...).

Player {
  on_join {
    // associate named tasks with a Player; re-assigning the same id cancels the
    // old task first (runtime), so the value must be a Schedule expression
    set player.tasks.welcome to schedule every 20 ticks {
        send "<gray>tick" to player
    }
    set player.tasks.reminder to schedule after 1 seconds every 2 seconds {
        send "<yellow>reminder" to player
    }

    // reference by id: a Boolean 'is running', and the Optional<Schedule> read
    if player.tasks.welcome is running send "<green>welcome running" to player
    if player.tasks.reminder is not running send "<red>reminder stopped" to player
    set handle to player.tasks.welcome

    // cancel by id (also 'stop <obj>.tasks.<id>')
    cancel player.tasks.welcome
    stop player.tasks.reminder

    // a task on a block-at-a-position: block_at(loc) keys by position
    place block("minecraft:sea_lantern") at player.location
    set block_at(player.location).tasks.pulse to schedule every 5 ticks {
        broadcast "<aqua>pulse"
    }
    if block_at(player.location).tasks.pulse is running broadcast "pulsing"
    cancel block_at(player.location).tasks.pulse

    // imperative placement (Block value or "id" string) and removal — removal
    // cancels every task bound to that position
    place "minecraft:oak_log" at player.location
    remove block at player.location
  }
}

// a task on a Mob (this = the Mob), bound once on spawn
mob Sentinel {
    type: "IRON_GOLEM"
    name: "<gray>Sentinel"
    on_spawn {
        // on_spawn binds 'mob' (the spawned Mob); the task auto-cancels on despawn
        set mob.tasks.patrol to schedule every 40 ticks {
            broadcast "<white>patrolling"
        }
    }
}

// a task on a Hologram (this = the text-display) and an Npc (this = the fake
// player Entity), keyed off their click handlers
hologram "board" {
    location: location(0, 65, 0)
    lines {
        line "<gold>Tasks Board"
    }
    on_click {
        set hologram.tasks.shimmer to schedule every 10 ticks {
            send "<light_purple>shimmer" to player
        }
        if hologram.tasks.shimmer is running send "<green>shimmering" to player
        cancel hologram.tasks.shimmer
    }
}

npc "guide" {
    location: location(5, 64, 5)
    skin: "Notch"
    // on_tick is the generic handler that binds 'npc' to the npc's fake-player
    // Entity, so npc.tasks.<id> is the npc task scope
    on_tick {
        set npc.tasks.follow to schedule after 2 seconds every 1 seconds {
            broadcast "<yellow>following"
        }
        if npc.tasks.follow is running broadcast "following on"
        stop npc.tasks.follow
    }
}
