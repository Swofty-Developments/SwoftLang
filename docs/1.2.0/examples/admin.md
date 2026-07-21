---
title: Admin tools
---

<!-- swoftc-page excerpt=sources/admin.sw -->

# Admin tools

A kitchen-sink admin plugin: the /gamemode family, /give, a three-level control panel, freeze and mute. 314 lines of Skript, 445 of SwoftLang; exercises commands, GUIs, pagination, persistence, world weather, the cancellable `PlayerCommand` event, schedules and the raw-packet escape hatch.

<MappedCompare title="admin.sk → admin.sw — the whole file, both sides">
<MappedPair label="options → module vars">
<template #skript>

```skript
options:
    Prefix: &x&F&F&9&3&F&8&lᴀᴅᴍɪɴ+ &7»&r
    CommandPrefix: admin+


    gamemodePermission: minecraft.command.gamemode

    weatherPermission: minecraft.command.weather

    givePermission: minecraft.command.give

    freezePermission: freeze.use

    mutePermission: mute.use

    menuPermission: op

    unfrozenMessage: &dYou have been unfrozen!
    freezeMessage: &dYou have been frozen!

    PermissionMessage: &cʏᴏᴜ ᴀʀᴇ ɴᴏᴛ ᴀʟʟᴏᴡᴇᴅ ᴛᴏ ᴜѕᴇ ᴛʜɪѕ ᴄᴏᴍᴍᴀɴᴅ!
```

</template>
<template #swoftlang>

```swoftlang
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
```

</template>
<template #note>

`{@X}` is textual substitution at parse time; `var` is a real binding. gui and receiver-method bodies run against their own scope (`this`, `player`, `state`, `slot`) and don't see module vars, so prefixed output routes through the `tell()` / `warn()` helpers. Two differences from the .sk: `permission:` takes a literal string, and a denied command shows the runtime's message instead of a per-command `permission message:`.

</template>
</MappedPair>
<MappedPair label="/gamemode">
<template #skript>

```skript
command /gamemode <gamemode> [<player>]:
    permission: {@gamemodePermission}
    permission message: {@PermissionMessage}
    prefix: {@CommandPrefix}
    trigger:
        set {_p} to name of player
        if arg-2 is set:
            set {_p} to name of arg-2
        if arg-1 is a gamemode:
            send "{@Prefix} &dGamemode set to %arg-1% for %{_p} in proper case%."
            set the gamemode of {_p} parsed as player to arg-1
        else:
            send "{@Prefix} &d%arg-1% is not a gamemode!"
```

</template>
<template #swoftlang>

```swoftlang
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
```

</template>
<template #note>

`arg-2 is set` + `parsed as player` becomes a typed argument with a default: `target: Player = sender`. A name that isn't online never reaches the handler. Literal gamemode strings are enum-checked at compile time; this dynamic one is validated in the handler, like the .sk.

</template>
</MappedPair>
<MappedPair label="gmc / gms / gmsp / gma">
<template #skript>

```skript
command gmc [<player>]:
    permission: {@gamemodePermission}
    permission message: {@PermissionMessage}
    prefix: {@CommandPrefix}
    trigger:
        set {_p} to name of player
        if arg-1 is set:
            set {_p} to name of arg-1
        execute player command "gamemode creative %{_p}%"

command gms [<player>]:
    permission: {@gamemodePermission}
    permission message: {@PermissionMessage}
    prefix: {@CommandPrefix}
    trigger:
        set {_p} to name of player
        if arg-1 is set:
            set {_p} to name of arg-1
        execute player command "gamemode survival %{_p}%"

command gmsp [<player>]:
    permission: {@gamemodePermission}
    permission message: {@PermissionMessage}
    prefix: {@CommandPrefix}
    trigger:
        set {_p} to name of player
        if arg-1 is set:
            set {_p} to name of arg-1
        execute player command "gamemode spectator %{_p}%"

command gma [<player>]:
    permission: {@gamemodePermission}
    permission message: {@PermissionMessage}
    prefix: {@CommandPrefix}
    trigger:
        set {_p} to name of player
        if arg-1 is set:
            set {_p} to name of arg-1
        execute player command "gamemode survival %{_p}%"
```

</template>
<template #swoftlang>

```swoftlang
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
```

</template>
<template #note>

The .sk re-enters itself with `execute player command "gamemode ..."` — four times, copy-pasted. There is no execute-a-command-string statement; the port calls a shared function. Which is also where the .sk's bug shows: its `gma` sets *survival* (paste slip). A shared function has no copy to paste wrong.

</template>
</MappedPair>
<MappedPair label="/weather">
<template #skript>

```skript
command /weather <text>:
    permission: {@weatherPermission}
    permission message: {@PermissionMessage}
    prefix: {@CommandPrefix}
    trigger:
        if arg-1 is "sun" or "clear" or "rain" or "storm":
            set weather to arg-1 parsed as weather
            send "{@Prefix} &dWeather set to %arg-1%." to player
        else:
            send "{@Prefix} &d%arg-1 in proper case% is not a type of weather!" to player
```

</template>
<template #swoftlang>

```swoftlang
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
```

</template>
<template #note>

Worlds expose a writable `weather` row — a `clear`/`rain`/`thunder` enum validated at compile time (alongside read-only `raining`/`thundering` booleans). The port maps the .sk's `sun`/`clear`/`rain`/`storm` vocabulary onto it and actually changes the sky; only an unrecognized word falls through to the "not a type of weather" reply.

</template>
</MappedPair>
<MappedPair label="/give">
<template #skript>

```skript
command /give <text> <item> <integer=1>:
    permission: {@givePermission}
    permission message: {@PermissionMessage}
    trigger:
        set {_item} to arg-2
        set {_amount} to arg-3
        
        if arg-1 is "@a":
            give {_amount} of {_item} to all players
            broadcast "{@Prefix} &d%player% gave %{_amount}% %{_item}%(s) to everyone!"
            
        else if arg-1 is "@s" or player's name:
            give {_amount} of {_item} to player
            send "{@Prefix} &dYou've been given %{_amount}% %{_item}%(s)!" to player
            
        else:
            set {_target} to arg-1 parsed as player
            if {_target} is online:
                give {_amount} of {_item} to {_target}
                send "{@Prefix} &dYou've been given %{_amount}% %{_item}%(s) by %player%!" to {_target}
                send "{@Prefix} &dGave %{_amount}% %{_item}%(s) to %{_target}%." to player
            else:
                send "{@Prefix} &cPlayer '%arg-1%' not found." to player
```

</template>
<template #swoftlang>

```swoftlang
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
```

</template>
<template #note>

`@a`/`@s` are matched as plain strings, exactly like the .sk. Skript's `give` adds to the inventory; here the port writes `held_item`, which *replaces* the held stack, because `give item` is reserved for declared custom items. Same items delivered, different slot.

</template>
</MappedPair>
<MappedPair label="tab completion">
<template #skript>

```skript
on tab complete of "/give":
	set tab completions for position 1 to all players, "@a", and "@s"
	set tab completions for position 2 to all items
	set tab completions for position 3 to 1, 2, 3, 4, 5, 6, 7, 8, and 9

on tab complete of "/weather":
    set tab completions for position 1 to "sun", "rain", and "storm"

on tab complete of "/gamemode":
    set tab completions for position 1 to all gamemodes
    set tab completions for position 2 to all players
```

</template>
<template #swoftlang>

```swoftlang
// No 'on tab complete' sections: completion falls out of the typed
// arguments blocks above (Player args complete to online players, defaults
// make trailing args optional).
```

</template>
<template #note>

Three handler blocks become zero lines: completion derives from the typed `arguments` blocks — `Player` args complete to online players, defaults make trailing args optional.

</template>
</MappedPair>
<MappedPair label="the admin panel">
<template #skript>

```skript
function Main(p: player):
    set {_gui} to chest inventory with 3 rows named "&bᴀᴅᴍɪɴ ᴘᴀɴᴇʟ"

    loop 27 times:
        set slot (loop-number - 1) of {_gui} to gray stained glass pane named " "
    set slot 12 of {_gui} to skull of {_p} named "&eᴘʟᴀʏᴇʀ ᴍᴀɴᴀɢᴇᴍᴇɴᴛ"
    set slot 13 of {_gui} to clock named "&eᴛɪᴍᴇ ᴍᴀɴᴀɢᴇᴍᴇɴᴛ"
    set slot 14 of {_gui} to sunflower named "&eᴡᴇᴀᴛʜᴇʀ ᴍᴀɴᴀɢᴇᴍᴇɴᴛ"

    open {_gui} to {_p}
```

</template>
<template #swoftlang>

```swoftlang
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
```

</template>
<template #note>

`skull of {_p}` → `skull: player` — item expressions re-evaluate per viewer, so the head is always the opener's.

</template>
</MappedPair>
<MappedPair label="player list">
<template #skript>

```skript
function PManagement(p: player):
    set {_gui} to chest inventory with 3 rows named "&bᴘʟᴀʏᴇʀ ᴍᴀɴᴀɢᴇᴍᴇɴᴛ"

    loop 27 times:
        set slot (loop-number - 1) of {_gui} to gray stained glass pane named " "
    set {_slot} to 0
    loop all players:
        set slot {_slot} of {_gui} to skull of loop-value named "&e%loop-value%"
        add 1 to {_slot}

    set slot 26 of {_gui} to arrow named "&cʙᴀᴄᴋ"

    open {_gui} to {_p}
```

</template>
<template #swoftlang>

```swoftlang
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
```

</template>
<template #note>

The .sk packs heads into slots by hand with a manual counter and no page math. `paginate` owns layout, prev/next arrows and clamping; `source: all_players()` re-evaluates on render.

</template>
</MappedPair>
<MappedPair label="time menu">
<template #skript>

```skript
function DManagment(p: player):
    set {_gui} to chest inventory with 3 rows named "&bᴛɪᴍᴇ ᴍᴀɴᴀɢᴇᴍᴇɴᴛ"

    loop 27 times:
        set slot (loop-number - 1) of {_gui} to gray stained glass pane named " "

    set slot 10 of {_gui} to clock named "&eѕᴜɴʀɪѕᴇ"
    set slot 11 of {_gui} to clock named "&eᴅᴀʏ"
    set slot 12 of {_gui} to clock named "&eɴᴏᴏɴ"
    set slot 13 of {_gui} to clock named "&eᴀꜰᴛᴇʀɴᴏᴏɴ"
    set slot 14 of {_gui} to clock named "&eꜱᴜɴꜱᴇᴛ"
    set slot 15 of {_gui} to clock named "&eɴɪɢʜᴛ"
    set slot 16 of {_gui} to clock named "&eᴍɪᴅɴɪɢʜᴛ"
    set slot 22 of {_gui} to arrow named "&cʙᴀᴄᴋ"

    open {_gui} to {_p}
```

</template>
<template #swoftlang>

```swoftlang
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
```

</template>
<template #note>

The .sk builds clocks here and, 60 lines later, matches them back *by display name* to run console `time set N` commands. Each slot here owns its click and writes `world.time` — renaming a button can't silently break it.

</template>
</MappedPair>
<MappedPair label="weather menu">
<template #skript>

```skript
function WManagement(p: player):
    set {_gui} to chest inventory with 3 rows named "&bᴡᴇᴀᴛʜᴇʀ ᴍᴀɴᴀɢᴇᴍᴇɴᴛ"

    loop 27 times:
        set slot (loop-number - 1) of {_gui} to gray stained glass pane named " "

    set slot 12 of {_gui} to sunflower named "&eꜱᴜɴɴʏ"
    set slot 13 of {_gui} to water bucket named "&eʀᴀɪɴʏ"
    set slot 14 of {_gui} to breeze rod named "&eꜱᴛᴏʀᴍʏ"
    set slot 22 of {_gui} to arrow named "&cʙᴀᴄᴋ"

    open {_gui} to {_p}
```

</template>
<template #swoftlang>

```swoftlang
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
```

</template>
<template #note>

The .sk's three weather items map straight onto the `weather` enum: each button writes `player.world.weather` and the sky changes for the opener. `set player.world.weather to ...` is the same chained property write the time menu uses for `world.time`.

</template>
</MappedPair>
<MappedPair label="/adminmenu and its six aliases">
<template #skript>

```skript
command /adminmenu:
    aliases: /amenu, /adminpanel, /apanel, /panel, /ap, am
    permission: {@menuPermission}
    permission message: {@PermissionMessage}
    prefix: {@CommandPrefix}
    trigger:
        Main(player)
```

</template>
<template #swoftlang>

```swoftlang
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
```

</template>
<template #note>

`aliases:` → alias-group declarations sharing one body.

</template>
</MappedPair>
<MappedPair label="the click router">
<template #skript>

```skript
on inventory click:

    if name of event-inventory is "&bᴀᴅᴍɪɴ ᴘᴀɴᴇʟ":
        cancel event
        if event-item is player head:
            PManagement(player)
        if event-item is clock:
            DManagment(player)
        if event-item is sunflower:
            WManagement(player)

    if name of event-inventory is "&bᴘʟᴀʏᴇʀ ᴍᴀɴᴀɢᴇᴍᴇɴᴛ":
        cancel event
        if event-item is player head:
            set {_target} to uncolored name of event-item

            set {_gui} to chest inventory with 3 rows named "&b%{_target}%"

            loop 27 times:
                set slot (loop-number - 1) of {_gui} to gray stained glass pane named " "
            set slot 12 of {_gui} to iron sword named "&cᴋɪᴄᴋ"
            set slot 13 of {_gui} to clock named "&cᴛᴇᴍᴘ-ʙᴀɴ"
            set slot 14 of {_gui} to barrier named "&cʙᴀɴ"
            set slot 11 of {_gui} to glass bottle named "&cᴍᴜᴛᴇ"
            set slot 15 of {_gui} to packed ice named "&cꜰʀᴇᴇᴢᴇ"
            set slot 22 of {_gui} to arrow named "&cʙᴀᴄᴋ"

            open {_gui} to player
        if event-item is arrow:
            Main(player)

    if name of event-inventory is "&bᴛɪᴍᴇ ᴍᴀɴᴀɢᴇᴍᴇɴᴛ":
        cancel event
        if event-item is clock:
            set {_time} to name of event-item
            if {_time} is "&eѕᴜɴʀɪѕᴇ":
                execute console command "time set 0"
            if {_time} is "&eᴅᴀʏ":
                execute console command "time set 1000"
            if {_time} is "&eɴᴏᴏɴ":
                execute console command "time set 6000"
            if {_time} is "&eᴀꜰᴛᴇʀɴᴏᴏɴ":
                execute console command "time set 9000"
            if {_time} is "&eꜱᴜɴꜱᴇᴛ":
                execute console command "time set 12000"
            if {_time} is "&eɴɪɢʜᴛ":
                execute console command "time set 13000"
            if {_time} is "&eᴍɪᴅɴɪɢʜᴛ":
                execute console command "time set 18000"
        if event-item is arrow:
            Main(player)

    if name of event-inventory is "&bᴡᴇᴀᴛʜᴇʀ ᴍᴀɴᴀɢᴇᴍᴇɴᴛ":
        cancel event
        if event-item is sunflower:
            set the weather to sun
        if event-item is water bucket:
            set the weather to rain
        if event-item is breeze rod:
            set the weather to thunder

        if event-item is arrow:
            Main(player)

    else:
        loop all players:
            if name of event-inventory is "&b%loop-value%":
                cancel event
                if event-item is iron sword:
                    kick loop-value
                if event-item is clock:
                    ban loop-value's ip for 12 hours
                if event-item is barrier:
                    ban loop-value's ip
                if event-item is glass bottle:
                    execute console command "mute %loop-value%"
                if event-item is packed ice:
                    execute player command "freeze %loop-value%"
                if event-item is arrow:
                    PManagement(player)
```

</template>
<template #swoftlang>

```swoftlang
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
```

</template>
<template #note>

Eighty lines of matching inventories by title — including finding the target player by looping everyone online and comparing the window name — collapse into the `on_click` handlers already declared per slot, plus one gui the .sk built inline: the per-player actions screen, whose target rides in `state` instead of the title bar. Kick closes the connection through the raw `DisconnectPacket`. Temp-ban and ban each want a persistent ban registry, so those two buttons carry a placeholder message.

</template>
</MappedPair>
<MappedPair label="freeze">
<template #skript>

```skript
command freeze <player> [<text>]:
    permission: {@freezePermission}
    permission message: {@PermissionMessage}
    prefix: {@CommandPrefix}
    trigger:
        if {Freezed::%uuid of arg-1%} is true:
            set {Freezed::%uuid of arg-1%} to false
            send "{@Prefix} {@unfrozenMessage}" to arg-1
            send "{@Prefix} &dYou have unfrozen %arg-1%!" to player
        else:
            set {Freezed::%uuid of arg-1%} to true
            if arg-2 is set:
                send "{@Prefix} &dYou have been frozen by %player% for %arg-2%!" to arg-1
                send "{@Prefix} &dYou have frozen %arg-1%!" to player
            else:
                send "{@Prefix} &dYou have been frozen by %player%!" to arg-1
                send "{@Prefix} &dYou have frozen %arg-1%!" to player
```

</template>
<template #swoftlang>

```swoftlang
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
```

</template>
<template #note>

`{Freezed::%uuid of arg-1%}` → `frozen for Player`, plus three Doubles for the freeze spot (Locations aren't persistable — scalars only). All of it survives restarts, which the .sk's did too — but its freeze *location* was never stored at all.

</template>
</MappedPair>
<MappedPair label="movement lock">
<template #skript>

```skript
on player move:
    if {Freezed::%uuid of player%} is true:
        cancel event
        send action bar "{@Prefix} &dYou're frozen, there for you cannot move!"
    else:
        stop
```

</template>
<template #swoftlang>

```swoftlang
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
```

</template>
<template #note>

The .sk cancels every move event; the port corrects instead of cancels — a boot-time `every 2 ticks` schedule snaps frozen players back to their stored spot. One loop covers everyone, and because the spot is persistent it survives restarts.

</template>
</MappedPair>
<MappedPair label="command lock">
<template #skript>

```skript
on command:
    if {Freezed::%uuid of player%} is true:
        cancel event
        send action bar "{@Prefix} &dCommands can not be executed while you're frozen!"
```

</template>
<template #swoftlang>

```swoftlang
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
```

</template>
<template #note>

`Player.on_command` fires before a typed command dispatches; it is cancellable and its `command` parameter is even writable (a handler can rewrite what runs). Here the freeze check just cancels — a one-to-one port of the .sk's `on command: cancel event`, keyed off the same persistent `frozen` flag. Receiver bodies see `this` and their parameters, not module vars, so the prefix goes through the `warn` helper.

</template>
</MappedPair>
<MappedPair label="mute">
<template #skript>

```skript
command mute <player>:
    permission: {@mutePermission}
    permission message: {@PermissionMessage}
    prefix: {@CommandPrefix}
    trigger:
        if {Muted::%uuid of player%} is true:
            set {Muted::%uuid of player%} to false
            send "{@Prefix} &dYou have been unmuted!" to arg-1
            send "{@Prefix} &dYou have unmuted %arg-1%!" to player
        else:
            set {Muted::%uuid of player%} to true
            send "{@Prefix} &dYou have been muted!" to arg-1
            send "{@Prefix} &dYou have muted %arg-1%!" to player
```

</template>
<template #swoftlang>

```swoftlang
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
```

</template>
<template #note>

The .sk toggles `{Muted::%uuid of player%}` — the *sender's* flag, so muting anyone mutes yourself. The port keys off the target, which is what it meant.

</template>
</MappedPair>
<MappedPair label="muted chat">
<template #skript>

```skript
on chat:
    if {Muted::%uuid of player%} is true:
        cancel event
        send action bar "{@Prefix} &dYou cannot talk while being muted!" to player
```

</template>
<template #swoftlang>

```swoftlang
Player {
    on_chat(message) {
        if muted for this {
            cancel event
            warn(this, "<light_purple>You cannot talk while being muted!")
        }
    }
}
```

</template>
<template #note>

`on chat` → `Player { on_chat(message) }`; the `warn` helper carries the module prefix into the action bar, and the cancel is legal because `on_chat` is cancellable.

</template>
</MappedPair>
</MappedCompare>
