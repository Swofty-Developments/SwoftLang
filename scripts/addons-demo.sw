// First-class npc {} + hologram {} demo (GROUP C/D).
//
// These used to be hand-rolled SwoftLang addons (addons/npcs.sw +
// addons/holograms.sw) that stored state in closure-association chains and
// implemented atan2/sqrt in the language itself. They are now FIRST-CLASS
// language constructs with dedicated Java runtimes (net.swofty.npcs /
// net.swofty.holograms), exactly like scoreboard/tablist/bossbar — fewer
// lines, typechecked, and with real per-viewer rendering, packet-built fake
// players, and Math.atan2 head tracking done natively. The old addons and
// their trig/closure code are gone.

import "music"

// The vanilla block placement rules addon: importing it registers stairs,
// slab, log, fence, pane, wall and door placement_rule{}s so blocks orient
// and connect like vanilla (Minestom ships none). It is a pure-SwoftLang
// feature and the reference example for the placement_rule construct.
import "blocks"

// A per-viewer hologram: the "${player.name}" line makes each viewer get a
// private display stack rendered with their own player bound (auto-detected,
// like scoreboards). Re-rendered on the update cadence.
hologram "welcome" {
    location: location(0.5, 82.0, 0.5)
    billboard: center
    scale: 1.5
    update: every 2 seconds
    lines {
        line "<gold><bold>SwoftLang"
        blank
        line "<gray>first-class holograms"
        line "<yellow>Hi ${player.name}"
    }
}

// A fake-player NPC. It spawns at engine init, is never a real connection
// (so it never leaks into /tp suggestions or the tab list), fetches Notch's
// skin from Mojang asynchronously, tracks the nearest player's head, and
// dispatches on_click with the clicker bound as `player`.
npc "guide" {
    location: location(2.5, 64.0, 2.5)
    name: "<green>Village Guide"
    skin: "Notch"
    look_at_players: true
    on_click {
        send "<gold>Guide<gray> says: welcome, ${player.name}!" to player
    }
}

command "holo-demo" {
    description: "Per-viewer hologram lifecycle (needs a live world)"

    execute {
        show hologram "welcome" to sender
        set hologram "welcome" line 2 to "<gray>rewritten in place"
        move hologram "welcome" to location(4.5, 83.0, 0.5)
        send "hologram 'welcome' shown - it greets you by name" to sender
    }
}

command "holo-off" {
    description: "Hide the demo hologram from you"

    execute {
        hide hologram "welcome" from sender
    }
}

command "npc-demo" {
    description: "Retarget the first-class NPC (needs a live world)"

    execute {
        set npc "guide" name "<aqua>Renamed Guide"
        set npc "guide" location location(4.5, 64.0, 4.5)
        send "NPC 'guide' updated - right-click it, it watches you" to sender
    }
}

command "music-demo" {
    description: "Song helpers (needs songs in scripts/songs/)"

    execute {
        play_song_near("demo.nbs", sender.location, 16.0)
        play_song_for_all("demo.nbs")
        stop_all_songs()
        send "music helpers exercised" to sender
    }
}
