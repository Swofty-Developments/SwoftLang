// phase-6 kitchen sink: displays, songs, tps, blocks, sounds, particles,
// motd/favicon/ServerPing, skins, toasts, map canvases, permissions, LAN

server {
    motd: "<gradient:gold:aqua>Swoft Platform"
    favicon: "icon.png"
    open_to_lan: true
    permissions {
        "swofty": ["admin.*"]
        "steve": ["mod.kick", "mod.mute"]
    }
}

Server {
    on_list_ping {
        broadcast "pinged"
    }

    on_tps_change {
        broadcast "TPS moved ${past} -> ${current}"
        if tps_at(60) < 15.0 broadcast "<red>we were lagging a minute ago"
    }
}

Block {
    on_break {
        send "you broke a block" to player
        cancel event
    }

    on_place {
        set block at location to "AIR"
    }
}

command "hologram" {
    execute {
        set d to spawn_text_display("<gold>Welcome!", location(0, 80, 0))
        set d.text to "<gold>Welcome, ${sender.name}!"
        set d.scale to 2.0
        set d.translation to location(0, 1, 0)
        set d.rotation to location(0, 45, 0)
        set d.billboard to "center"
        set d.alignment to "center"
        set d.line_width to 200
        set d.see_through to true
        set d.background to "#40000000"
        set d.glow_color to "gold"
        set d.view_range to 64.0
        show display d to all players
        set b to spawn_block_display("STONE", location(2, 80, 0))
        set i to spawn_item_display("DIAMOND_SWORD", location(4, 80, 0))
        mount display i on sender
        teleport display d to location(0, 90, 0)
        hide display d from sender
        destroy display b
    }
}

command "music" {
    execute {
        play song "megalovania.nbs" to sender
        play song "megalovania.nbs" to all players at tick 200
        play song "chill.nbs" at location(0, 64, 0) radius 20.0
        set song volume of sender to 0.5
        fade song of sender to 0.0 over 3 seconds
        pause song of sender
        resume song of sender
        stop song of sender
        broadcast song "anthem.nbs"
        set meta to song("megalovania.nbs")
        send "Now playing ${meta.title} by ${meta.author}" to sender
    }
}

command "tps" {
    execute {
        send "TPS ${server.tps} avg ${server.average_tps} mspt ${server.mspt}" to sender
        send tps_string() to sender
        send average_tps_string() to sender
    }
}

command "boom" {
    execute {
        set block at location(0, 64, 0) to "TNT"
        fill blocks from location(0, 63, 0) to location(4, 63, 4) with "STONE"
        send "under you: ${block_at(sender.location)}" to sender
        play sound "minecraft:entity.generic.explode" to all players at location(0, 64, 0) volume 2.0 pitch 0.8
        stop sound "minecraft:music_disc.cat" for sender
        stop sound for sender
        spawn particle "FLAME" at location(0, 65, 0) count 40 offset 0.5, 0.5, 0.5 speed 0.01 to all players
        spawn particle "HEART" at location(0, 66, 0)
    }
}

command "day" {
    execute {
        set w to sender.world
        set w.time to 1000
        set w.time_rate to 0
        set server motd to "<blue>daytime!"
        set server.motd to "<blue>daytime (property form)"
    }
}

command "disguise" {
    arguments {
        name: String
    }
    execute async {
        set fetched to fetch_skin(args.name)
        if fetched exists {
            set sender.skin to fetched
            send "skin texture: ${sender.skin.texture}" to sender
        } else {
            set sender.skin to skin("texture-base64", "signature-base64")
        }
    }
}

command "quest" {
    execute {
        show toast "<gold>Quest Complete!" description "You finished the tutorial" icon "DIAMOND" frame challenge to sender
        show toast "Hi there" to sender
        set canvas to map_canvas()
        draw rect on canvas from 0, 0 to 127, 127 color "white"
        draw pixel on canvas at 64, 64 color 34
        draw text on canvas at 10, 10 text "Hello" color "black"
        give map of canvas to sender
        send "canvas is ${canvas.width}x${canvas.height}" to sender
    }
}

command "admincheck" {
    permission: "admin.panel"
    execute {
        if has_permission(sender, "admin.ban") send "you may ban" to sender
    }
}
