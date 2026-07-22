// StaffChat.sk port — toggleable staff-only chat channel.

// Skript kept the toggle in {staffchat::%uuid%}, a runtime map that dies
// with the server. A keyed persistent survives restarts and needs no uuid
// bookkeeping — the Player IS the key.
persistent staffchat for Player: Boolean = false

command "staffchat" {
    permission: "staffchat.send"
    description: "Toggle staff chat, or send one message to it"

    arguments {
        message: optional<String>
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

function send_staff(from: Player, msg: String) {
    if has_permission(from, "staffchat.send") {
        loop all players as p {
            if has_permission(p, "staffchat.receive") {
                send "<gold><bold>S</bold></gold><yellow><bold>C</bold></yellow> <dark_gray>- <gray>${from.display_name}<white>: ${msg}" to p
            }
        }
    }
}
