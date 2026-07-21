// admin.sk port — /gamemode family, /give, a paginated admin panel,
// freeze and mute. Skript's options block becomes module-level vars.

var prefix = "<#FF93F8><bold>ᴀᴅᴍɪɴ+</bold> <gray>»</gray>"
var permission_message = "<red>ʏᴏᴜ ᴀʀᴇ ɴᴏᴛ ᴀʟʟᴏᴡᴇᴅ ᴛᴏ ᴜѕᴇ ᴛʜɪѕ ᴄᴏᴍᴍᴀɴᴅ!"

// gui and receiver-method bodies run against their own scope (this/player/
// state/slot), not module vars — prefixed output always goes through a helper
function tell(target: Player, msg: String) {
    send "${prefix} ${msg}" to target
}

function warn(target: Player, msg: String) {
    actionbar "${prefix} ${msg}" to target
}

// one function replaces five copy-pasted Skript triggers (and the gma
// copy-paste bug in the .sk, which set survival, has nowhere to live)
function apply_gamemode(actor: Player, target: Player, mode: String) {
    set target.gamemode to mode
    send "${prefix} <light_purple>Gamemode set to ${mode} for ${target.name}." to actor
}

command "gamemode" {
    permission: "minecraft.command.gamemode"
    description: "Set your or another player's gamemode"

    arguments {
        mode: String
        target: Player = sender
    }

    execute {
        if args.mode is "survival" or args.mode is "creative"
            or args.mode is "adventure" or args.mode is "spectator" {
            apply_gamemode(sender, args.target, args.mode)
        } else {
            send "${prefix} <light_purple>${args.mode} is not a gamemode!" to sender
        }
    }
}

command "gmc" {
    permission: "minecraft.command.gamemode"
    arguments {
        target: Player = sender
    }
    execute {
        apply_gamemode(sender, args.target, "creative")
    }
}

command "gms" {
    permission: "minecraft.command.gamemode"
    arguments {
        target: Player = sender
    }
    execute {
        apply_gamemode(sender, args.target, "survival")
    }
}

command "gmsp" {
    permission: "minecraft.command.gamemode"
    arguments {
        target: Player = sender
    }
    execute {
        apply_gamemode(sender, args.target, "spectator")
    }
}

command "gma" {
    permission: "minecraft.command.gamemode"
    arguments {
        target: Player = sender
    }
    execute {
        apply_gamemode(sender, args.target, "adventure")
    }
}

// worlds carry a writable weather enum (clear|rain|thunder); the command maps
// the .sk's vocabulary onto it and flips the sky for real
command "weather" {
    permission: "minecraft.command.weather"
    arguments {
        kind: String
    }
    execute {
        set w to sender.world
        if args.kind is "sun" or args.kind is "clear" {
            set w.weather to "clear"
            send "${prefix} <light_purple>Weather set to ${args.kind}." to sender
        } else if args.kind is "rain" {
            set w.weather to "rain"
            send "${prefix} <light_purple>Weather set to ${args.kind}." to sender
        } else if args.kind is "storm" {
            set w.weather to "thunder"
            send "${prefix} <light_purple>Weather set to ${args.kind}." to sender
        } else {
            send "${prefix} <light_purple>${args.kind} is not a type of weather!" to sender
        }
    }
}

command "give" {
    permission: "minecraft.command.give"
    description: "Give an item to a player, everyone, or yourself"

    arguments {
        target: String
        material: String
        amount: Integer = 1
    }

    execute {
        if args.target is "@a" {
            loop all players as p {
                set p.held_item to item(args.material, args.amount)
            }
            broadcast "${prefix} <light_purple>${sender.name} gave ${args.amount} ${args.material}(s) to everyone!"
        } else if args.target is "@s" or args.target is sender.name {
            set sender.held_item to item(args.material, args.amount)
            send "${prefix} <light_purple>You've been given ${args.amount} ${args.material}(s)!" to sender
        } else {
            set found to player(args.target)
            if found exists {
                set found.held_item to item(args.material, args.amount)
                send "${prefix} <light_purple>You've been given ${args.amount} ${args.material}(s) by ${sender.name}!" to found
                send "${prefix} <light_purple>Gave ${args.amount} ${args.material}(s) to ${found.name}." to sender
            } else {
                send "${prefix} <red>Player '${args.target}' not found." to sender
            }
        }
    }
}

// No 'on tab complete' sections: completion falls out of the typed
// arguments blocks above (Player args complete to online players, defaults
// make trailing args optional).

gui "admin_panel" {
    rows: 3
    title: "<aqua>ᴀᴅᴍɪɴ ᴘᴀɴᴇʟ"

    fill: item("GRAY_STAINED_GLASS_PANE", name: " ")

    slot 12 {
        item {
            skull: player
            name: "<yellow>ᴘʟᴀʏᴇʀ ᴍᴀɴᴀɢᴇᴍᴇɴᴛ"
        }
        on_click {
            open gui "player_management" to player
        }
    }
    slot 13 {
        item {
            material: "CLOCK"
            name: "<yellow>ᴛɪᴍᴇ ᴍᴀɴᴀɢᴇᴍᴇɴᴛ"
        }
        on_click {
            open gui "time_management" to player
        }
    }
    slot 14 {
        item {
            material: "SUNFLOWER"
            name: "<yellow>ᴡᴇᴀᴛʜᴇʀ ᴍᴀɴᴀɢᴇᴍᴇɴᴛ"
        }
        on_click {
            open gui "weather_management" to player
        }
    }
}

gui "player_management" {
    rows: 3
    title: "<aqua>ᴘʟᴀʏᴇʀ ᴍᴀɴᴀɢᴇᴍᴇɴᴛ"

    fill: item("GRAY_STAINED_GLASS_PANE", name: " ")

    // the .sk packs heads by hand into a 27-slot grid with no page math;
    // paginate owns the layout, arrows and clamping
    paginate {
        source: all_players()
        slots: [9..17]
        render {
            skull: item
            name: "<yellow>${item.name}"
        }
        on_click {
            open gui "player_actions" to player with { target: item }
        }
        prev_slot: 18
        next_slot: 26
    }

    slot 22 {
        item { material: "ARROW", name: "<red>ʙᴀᴄᴋ" }
        on_click {
            go back for player
        }
    }
}

gui "time_management" {
    rows: 3
    title: "<aqua>ᴛɪᴍᴇ ᴍᴀɴᴀɢᴇᴍᴇɴᴛ"

    fill: item("GRAY_STAINED_GLASS_PANE", name: " ")

    // the .sk routes every clock through console 'time set N' commands
    // matched by DISPLAY NAME; each slot here just writes world.time
    slot 10 {
        item { material: "CLOCK", name: "<yellow>ѕᴜɴʀɪѕᴇ" }
        on_click { set player.world.time to 0 }
    }
    slot 11 {
        item { material: "CLOCK", name: "<yellow>ᴅᴀʏ" }
        on_click { set player.world.time to 1000 }
    }
    slot 12 {
        item { material: "CLOCK", name: "<yellow>ɴᴏᴏɴ" }
        on_click { set player.world.time to 6000 }
    }
    slot 13 {
        item { material: "CLOCK", name: "<yellow>ᴀꜰᴛᴇʀɴᴏᴏɴ" }
        on_click { set player.world.time to 9000 }
    }
    slot 14 {
        item { material: "CLOCK", name: "<yellow>ꜱᴜɴꜱᴇᴛ" }
        on_click { set player.world.time to 12000 }
    }
    slot 15 {
        item { material: "CLOCK", name: "<yellow>ɴɪɢʜᴛ" }
        on_click { set player.world.time to 13000 }
    }
    slot 16 {
        item { material: "CLOCK", name: "<yellow>ᴍɪᴅɴɪɢʜᴛ" }
        on_click { set player.world.time to 18000 }
    }
    slot 22 {
        item { material: "ARROW", name: "<red>ʙᴀᴄᴋ" }
        on_click {
            go back for player
        }
    }
}

gui "weather_management" {
    rows: 3
    title: "<aqua>ᴡᴇᴀᴛʜᴇʀ ᴍᴀɴᴀɢᴇᴍᴇɴᴛ"

    fill: item("GRAY_STAINED_GLASS_PANE", name: " ")

    slot 12 {
        item { material: "SUNFLOWER", name: "<yellow>ꜱᴜɴɴʏ" }
        on_click {
            set player.world.weather to "clear"
            tell(player, "<light_purple>Weather set to clear.")
        }
    }
    slot 13 {
        item { material: "WATER_BUCKET", name: "<yellow>ʀᴀɪɴʏ" }
        on_click {
            set player.world.weather to "rain"
            tell(player, "<light_purple>Weather set to rain.")
        }
    }
    slot 14 {
        item { material: "BREEZE_ROD", name: "<yellow>ꜱᴛᴏʀᴍʏ" }
        on_click {
            set player.world.weather to "thunder"
            tell(player, "<light_purple>Weather set to thunder.")
        }
    }
    slot 22 {
        item { material: "ARROW", name: "<red>ʙᴀᴄᴋ" }
        on_click {
            go back for player
        }
    }
}

command "adminmenu",
command "amenu",
command "adminpanel",
command "apanel",
command "panel",
command "ap",
command "am" {
    permission: "admin.menu"
    description: "Open the admin panel"

    execute {
        open gui "admin_panel" to sender
    }
}

// The .sk's 70-line 'on inventory click' router — matching inventories by
// display name, finding the target player back by parsing the TITLE — is
// the on_click handlers inside the gui blocks above. The one screen it
// builds inline (per-player actions) is a gui like any other; the target
// rides along as state instead of being encoded in the window title.
gui "player_actions" {
    rows: 3
    title: "<aqua>${state.target.name}"

    fill: item("GRAY_STAINED_GLASS_PANE", name: " ")

    slot 12 {
        item { material: "IRON_SWORD", name: "<red>ᴋɪᴄᴋ" }
        on_click {
            kick_player(player, state.target)
        }
    }
    slot 13 {
        item { material: "CLOCK", name: "<red>ᴛᴇᴍᴘ-ʙᴀɴ" }
        on_click {
            tell(player, "<red>There is no ban registry yet — see the pair note.")
        }
    }
    slot 14 {
        item { material: "BARRIER", name: "<red>ʙᴀɴ" }
        on_click {
            tell(player, "<red>There is no ban registry yet — see the pair note.")
        }
    }
    slot 11 {
        item { material: "GLASS_BOTTLE", name: "<red>ᴍᴜᴛᴇ" }
        on_click {
            toggle_mute(player, state.target)
        }
    }
    slot 15 {
        item { material: "PACKED_ICE", name: "<red>ꜰʀᴇᴇᴢᴇ" }
        on_click {
            toggle_freeze(player, state.target)
        }
    }
    slot 22 {
        item { material: "ARROW", name: "<red>ʙᴀᴄᴋ" }
        on_click {
            go back for player
        }
    }
}

// no kick statement yet — the raw packet escape hatch closes the connection
function kick_player(actor: Player, target: Player) {
    send packet "DisconnectPacket" { message: "${prefix} kicked" } to target
    send "${prefix} <light_purple>Kicked ${target.name}." to actor
}

persistent frozen for Player: Boolean = false
persistent freeze_x for Player: Double = 0.0
persistent freeze_y for Player: Double = 0.0
persistent freeze_z for Player: Double = 0.0

function toggle_freeze(actor: Player, target: Player) {
    if frozen for target {
        set frozen for target to false
        send "${prefix} <light_purple>You have been unfrozen!" to target
        send "${prefix} <light_purple>You have unfrozen ${target.name}!" to actor
    } else {
        set frozen for target to true
        set freeze_x for target to target.location.x
        set freeze_y for target to target.location.y
        set freeze_z for target to target.location.z
        send "${prefix} <light_purple>You have been frozen by ${actor.name}!" to target
        send "${prefix} <light_purple>You have frozen ${target.name}!" to actor
    }
}

command "freeze" {
    permission: "freeze.use"
    arguments {
        target: Player
        reason: optional<String>
    }
    execute {
        if args.reason exists {
            if not (frozen for args.target) {
                send "${prefix} <light_purple>Reason: ${args.reason}" to args.target
            }
        }
        toggle_freeze(sender, args.target)
    }
}

// 'on player move: cancel event' — the port corrects instead of cancels:
// a boot-time schedule snaps frozen players back to where they were frozen
// (their location survives restarts too)
every 2 ticks {
    loop all players as p {
        if frozen for p {
            teleport p to location(freeze_x for p, freeze_y for p, freeze_z for p)
            actionbar "${prefix} <light_purple>You're frozen, therefore you cannot move!" to p
        }
    }
}

// 'on command: cancel event' while frozen — on_command fires before a
// command dispatches and is cancellable, so the freeze veto is a direct port
Player {
    on_command(cmd) {
        if frozen for this {
            cancel event
            warn(this, "<light_purple>Commands can not be executed while you're frozen!")
        }
    }
}

persistent muted for Player: Boolean = false

function toggle_mute(actor: Player, target: Player) {
    if muted for target {
        set muted for target to false
        send "${prefix} <light_purple>You have been unmuted!" to target
        send "${prefix} <light_purple>You have unmuted ${target.name}!" to actor
    } else {
        set muted for target to true
        send "${prefix} <light_purple>You have been muted!" to target
        send "${prefix} <light_purple>You have muted ${target.name}!" to actor
    }
}

command "mute" {
    permission: "mute.use"
    arguments {
        target: Player
    }
    execute {
        // the .sk reads {Muted::%uuid of player%} — the SENDER's flag — in
        // its toggle check; keying off the target is what it meant
        toggle_mute(sender, args.target)
    }
}

Player {
    on_chat(message) {
        if muted for this {
            cancel event
            warn(this, "<light_purple>You cannot talk while being muted!")
        }
    }
}
