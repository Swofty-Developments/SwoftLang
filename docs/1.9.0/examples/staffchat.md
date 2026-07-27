---
title: StaffChat
---

<!-- swoftc-page excerpt=sources/StaffChat.sw -->

# StaffChat

A toggleable staff-only chat channel — one keyed persistent, a chat router, a permission-gated broadcast. 25 lines of Skript, 50 of SwoftLang; exercises keyed persistence, chat events, permissions.

<MappedCompare title="StaffChat.sk → StaffChat.sw — the whole file, both sides">
<MappedPair label="the /staffchat command">
<template #skript>

```skript
#by ItzMCcat16
command /staffchat [<text>]:
    permission: staffchat.send
    trigger:
        if arg-1 is not set:
            if {staffchat::%player's uuid%} is not true:
                set {staffchat::%player's uuid%} to true
                send "&6&lStaff&e&lChat &8- &eEnabled &7staffchat"
            else:
                set {staffchat::%player's uuid%} to false
                send "&6&lStaff&e&lChat &8- &eDisabled &7staffchat"
        else:
            sendStaff(player, arg-1)
```

</template>
<template #swoftlang>

```swoftlang
// StaffChat.sk port — toggleable staff-only chat channel.

// Skript kept the toggle in {staffchat::%uuid%}, a runtime map that dies
// with the server. A keyed persistent survives restarts and needs no uuid
// bookkeeping — the Player IS the key.
persistent staffchat for Player: Boolean = false

command "staffchat" {
    permission: "staffchat.send"
    description: "Toggle staff chat, or send one message to it"

    arguments {
        message: Optional<String>
    }

    execute {
        if args.message is missing {
            if staffchat for sender {
                set staffchat for sender to false
                send "<gold><bold>Staff</bold></gold><yellow><bold>Chat</bold></yellow> <dark_gray>- <yellow>Disabled <gray>staffchat" to sender
            } else {
                set staffchat for sender to true
                send "<gold><bold>Staff</bold></gold><yellow><bold>Chat</bold></yellow> <dark_gray>- <yellow>Enabled <gray>staffchat" to sender
            }
        } else {
            send_staff(sender, args.message)
        }
    }
}
```

</template>
<template #note>

`{staffchat::%player's uuid%}` is a runtime map keyed by hand-stringified uuids, and it dies with the server. `persistent staffchat for Player` survives restarts and the player *is* the key. The `[<text>]` optional argument becomes `Optional<String>` — and the `is missing` check is not convention, it's required: using `args.message` unchecked is a compile error.

</template>
</MappedPair>
<MappedPair label="chat routing">
<template #skript>

```skript
on chat:
    if {staffchat::%player's uuid%} is true:
        cancel event
        sendStaff(player, message)
    else:
        broadcast "%player's displayname%&f: %message%"
```

</template>
<template #swoftlang>

```swoftlang
Player {
    on_chat {
        if staffchat for player {
            cancel event
            send_staff(player, message)
        } else {
            broadcast "${player.display_name}<white>: ${message}"
        }
    }
}
```

</template>
<template #note>

`on chat` → `Player { on_chat }`, with the sender bound as `player` and the text as `message`. `cancel event` compiles only because `on_chat` is cancellable — in `on_join` the same line is a compile error. `%player's displayname%` → `${player.display_name}`, and `&`-codes become MiniMessage tags throughout.

</template>
</MappedPair>
<MappedPair label="the staff broadcast">
<template #skript>

```skript
function sendStaff(player: player, msg: text):
    if {_player} has permission "staffchat.send":
        loop all players:
            if loop-player has permission "staffchat.receive":
                send "&6&lS&e&lC &8- &7%{_player}'s displayname%&f: %{_msg}%" to loop-player
```

</template>
<template #swoftlang>

```swoftlang
function send_staff(from: Player, msg: String) {
    if has_permission(from, "staffchat.send") {
        loop all players as p {
            if has_permission(p, "staffchat.receive") {
                send "<gold><bold>S</bold></gold><yellow><bold>C</bold></yellow> <dark_gray>- <gray>${from.display_name}<white>: ${msg}" to p
            }
        }
    }
}
```

</template>
<template #note>

Skript parameters arrive as `{_player}` locals re-read by string name; here they're typed parameters — passing a non-Player is a compile error, not a silent `<none>`. The permission-gated recipient loop maps line for line.

</template>
</MappedPair>
</MappedCompare>
