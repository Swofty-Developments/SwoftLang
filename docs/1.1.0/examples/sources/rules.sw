// rules.sk port — a /rules menu, declared instead of assembled.

command "rules" {
    description: "Open the server rules"

    execute {
        open gui "rules" to sender
    }
}

// Skript builds the inventory by hand (metadata tag, 45 glass panes, one
// set-slot per book) and routes clicks by comparing inventories. The gui
// block declares the same screen; the runtime owns the session, cancels
// item movement, and routes clicks per slot.
gui "rules" {
    rows: 5
    title: "<red><bold>Rules"

    fill: item("GRAY_STAINED_GLASS_PANE", name: " ")

    slot 4 {
        item {
            material: "REDSTONE_BLOCK"
            name: "<red><bold>! ! !"
            glint: true
            lore: [
                "<gray>If you see someone breaking any",
                "<gray>of these rules, report them in the discord!",
                "<blue>/discord"
            ]
        }
    }

    slot 10 {
        item {
            material: "BOOK"
            name: "<yellow><bold>[1] <white>Be respectful to everyone!"
            lore: ["<gray>- If someone is being toxic,", "<gray>you can report them in /discord"]
        }
    }

    slot 11 {
        item {
            material: "BOOK"
            name: "<yellow><bold>[2] <white>No Naked Killing!"
            lore: ["<gray>- A player without armor on,", "<gray>who is not in OP gens area", "<gray>is considered naked!"]
        }
    }

    slot 12 {
        item {
            material: "BOOK"
            name: "<yellow><bold>[3] <white>No Combat Logging!"
            lore: ["<gray>- This is not bannable, but", "<gray>if you are in combat while logging", "<gray>out you will be killed."]
        }
    }

    slot 13 {
        item {
            material: "BOOK"
            name: "<yellow><bold>[4] <white>No Excessive Swearing!"
            lore: ["<gray>- Any more than 2 or 3 times", "<gray>in a short period of time is", "<gray>considered excessive swearing!"]
        }
    }

    slot 14 {
        item {
            material: "BOOK"
            name: "<yellow><bold>[5] <white>No Scamming!"
            lore: ["<gray>- This is telling a player", "<gray>they will receive something for", "<gray>something in return, but lying!"]
        }
    }

    slot 15 {
        item {
            material: "BOOK"
            name: "<yellow><bold>[6] <white>No Advertising!"
            lore: ["<gray>- Advertising a server not", "<gray>partnered with mostlygens,", "<gray>or any website!"]
        }
    }

    slot 16 {
        item {
            material: "BOOK"
            name: "<yellow><bold>[7] <white>No Abusing Bugs!"
            lore: ["<gray>- This is abusing a feature", "<gray>in the game, that is not meant", "<gray>to be in the game!", "<white>- Instead, report it in the", "<white>discord! <blue>/discord"]
        }
    }

    slot 19 {
        item {
            material: "BOOK"
            name: "<yellow><bold>[8] <white>No Slurs, or Discrimination!"
            lore: ["<gray>- This is any slur or", "<gray>way of discrimination!"]
        }
    }

    slot 20 {
        item {
            material: "BOOK"
            name: "<yellow><bold>[9] <white>Do not disrespect a staff member!"
            lore: ["<gray>- Be respectful to every", "<gray>staff member, and be patient!"]
        }
    }

    slot 21 {
        item {
            material: "BOOK"
            name: "<yellow><bold>[10] <white>No Hacking!"
            lore: ["<gray>- No form of hacking is allowed,", "<gray>and there is no excuse.", "<gray>Having a unfair advantage, by using", "<gray>mods or hacks, is bannable.", "<white>- If you see someone hacking, report them", "<white>in the discord! <blue>/discord"]
        }
    }

    slot 22 {
        item {
            material: "BOOK"
            name: "<yellow><bold>[11] <white>No Spamming Chat!"
            lore: ["<gray>- This is saying the same message", "<gray>in a short amount of time, or spamming", "<gray>messages in chat."]
        }
    }

    slot 40 {
        item {
            material: "BARRIER"
            name: "<red><bold>Close Menu"
        }
        on_click {
            close gui for player
        }
    }
}
