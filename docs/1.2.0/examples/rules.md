---
title: Rules
---

<!-- swoftc-page excerpt=sources/rules.sw -->

# Rules

A /rules menu — eleven books, a warning sign, one close button. 31 lines of Skript, 131 of SwoftLang (the books earn their keep); exercises declarative GUIs and commands.

<MappedCompare title="rules.sk → rules.sw — the whole file, both sides">
<MappedPair label="the /rules command">
<template #skript>

```skript
command /rules:
	trigger:
		rules(player, "rules")
```

</template>
<template #swoftlang>

```swoftlang
// rules.sk port — a /rules menu, declared instead of assembled.

command "rules" {
    description: "Open the server rules"

    execute {
        open gui "rules" to sender
    }
}
```

</template>
<template #note>

The .sk routes through `rules(player, "rules")` and string-compares the discriminator inside. Screens are declarations here, so the command just opens one.

</template>
</MappedPair>
<MappedPair label="building the screen">
<template #skript>

```skript
function rules(p: player, type: text):
	if {_type} is "rules":
		
		set metadata tag "rules" of {_p} to chest inventory with 5 rows named "&c&lRules"
		set slot (numbers between 0 and 44) of metadata tag "rules" of {_p} to gray stained glass pane named " "
		open (metadata tag "rules" of {_p}) to {_p}
```

</template>
<template #swoftlang>

```swoftlang
// Skript builds the inventory by hand (metadata tag, 45 glass panes, one
// set-slot per book) and routes clicks by comparing inventories. The gui
// block declares the same screen; the runtime owns the session, cancels
// item movement, and routes clicks per slot.
gui "rules" {
    rows: 5
    title: "<red><bold>Rules"

    fill: item("GRAY_STAINED_GLASS_PANE", name: " ")
```

</template>
<template #note>

A metadata-tag inventory, 45 glass set-slot calls and an open-before-populate dance become `rows` / `title` / `fill`. There is no window object to stash on the player — the runtime owns the session and renders the declaration.

</template>
</MappedPair>
<MappedPair label="the warning sign">
<template #skript>

```skript
		set slot 4 of metadata tag "rules" of {_p} to shiny redstone block named "&c&l! ! !" with lore "&7If you see someone breaking any" and "&7of these rules, report them in the discord!" and "&9/discord"
```

</template>
<template #swoftlang>

```swoftlang
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
```

</template>
<template #note>

`shiny` → `glint: true`; `&c&l` → `<red><bold>`; the `with lore ... and ...` chain becomes a list.

</template>
</MappedPair>
<MappedPair label="eleven rule books">
<template #skript>

```skript
		set slot 10 of metadata tag "rules" of {_p} to book named "&e&l[1] &fBe respectful to everyone!" with lore "&7- If someone is being toxic, " with lore "&7you can report them in /discord"
		set slot 11 of metadata tag "rules" of {_p} to book named "&e&l[2] &fNo Naked Killing!" with lore "&7- A player without armor on," and "&7who is not in OP gens area" and "&7is considered naked!"
		set slot 12 of metadata tag "rules" of {_p} to book named "&e&l[3] &fNo Combat Logging!" with lore "&7- This is not bannable, but" and "&7if you are in combat while logging" and "&7out you will be killed."
		set slot 13 of metadata tag "rules" of {_p} to book named "&e&l[4] &fNo Excessive Swearing!" with lore "&7- Any more than 2 or 3 times" and "&7in a short period of time is " and "&7considered excessive swearing!"
		set slot 14 of metadata tag "rules" of {_p} to book named "&e&l[5] &fNo Scamming!" with lore "&7- This is telling a player" and "&7they will receive something for" and "&7something in return, but lying!"
		set slot 15 of metadata tag "rules" of {_p} to book named "&e&l[6] &fNo Advertising!" with lore "&7- Advertising a server not" and "&7partnered with mostlygens," and "&7or any website!"
		set slot 16 of metadata tag "rules" of {_p} to book named "&e&l[7] &fNo Abusing Bugs!" with lore "&7- This is abusing a feature" and "&7in the game, that is not meant" and "&7to be in the game!" and "&f- Instead, report it in the" and "&fdiscord! &9/discord"
		set slot 19 of metadata tag "rules" of {_p} to book named "&e&l[8] &fNo Slurs, or Discrimination!" with lore "&7- This is any slur or" and "&7way of discrimination!"
		set slot 20 of metadata tag "rules" of {_p} to book named "&e&l[9] &fDo not disrespect a staff member!" with lore "&7- Be respectful to every" and "&7staff member, and be patient!"
		set slot 21 of metadata tag "rules" of {_p} to book named "&e&l[10] &fNo Hacking!" with lore "&7- No form of hacking is allowed," and "&7and there is no excuse." and "&7Having a unfair advantage, by using" and "&7mods or hacks, is bannable." and "&f- If you see someone hacking, report them" and "&fin the discord! &9/discord"
		set slot 22 of metadata tag "rules" of {_p} to book named "&e&l[11] &fNo Spamming Chat!" with lore "&7- This is saying the same message" and "&7in a short amount of time, or spamming" and "&7messages in chat."
```

</template>
<template #swoftlang>

```swoftlang
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
```

</template>
<template #note>

Deliberately 1:1 — menu content is the bulk of any menu script, and it ports mechanically. The compiler validates every material name and slot index against the declared rows.

</template>
</MappedPair>
<MappedPair label="close button and click routing">
<template #skript>

```skript
		set slot 40 of metadata tag "rules" of {_p} to barrier named "&c&lClose Menu"
			
on inventory click:
	if event-inventory = (metadata tag "rules" of player):
		cancel event
		if index of event-slot is 40:
			close inventory of player
```

</template>
<template #swoftlang>

```swoftlang
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
```

</template>
<template #note>

The .sk cancels every click on a matching inventory and compares `index of event-slot is 40`. Here only slot 40 declares an `on_click`; every non-editable slot cancels item movement automatically, so the router disappears.

</template>
</MappedPair>
</MappedCompare>
