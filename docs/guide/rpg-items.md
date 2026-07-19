---
title: Build an RPG Item System
---

<StepHeader>
a Hypixel-style stat sword — custom stats, a tier banner, and a cooldowned right-click ability — assembled from tags, lore, and one imported addon.
</StepHeader>

An `item` gives you identity, appearance, WYSIWYG [lore](/reference/items#lore), and a
nested [NBT tag API](/reference/items#tags-the-nbt-api). Everything a Hypixel-style item
*does* — stat numbers, a rarity ladder of your own, a named ability on a cooldown — is a
system you **build** on top of that, out of pieces you already know: tags for the data,
lore for the display, and events (or an addon) for the behavior. This step builds the
whole thing.

## Stats are tags

There's no `stats { }` block: a "stat" is just a number you decide means something. Store
your stats — and your own tier scheme — as [tags](/reference/items#tags-the-nbt-api),
plain typed round-tripping data on the stack:

<!-- swoftc name=aspect.sw -->

```swoftlang
import "abilities"

item "aspect_of_the_end" {
    material: "DIAMOND_SWORD"
    name: "<blue>Aspect of the End"
    rarity: rare
    glint: true

    // Your stat system — arbitrary data, yours to design.
    tags {
        damage: 100,
        strength: 80,
        crit_damage: 25,
        tier: "LEGENDARY"
    }

    // WYSIWYG lore: write exactly the tooltip you want players to see.
    lore {
        line "<gray>Damage: <red>+100"
        line "<gray>Strength: <red>+80"
        line "<gray>Crit Damage: <blue>+25%"
        blank
        line "<dark_purple><bold>LEGENDARY"
    }
}
```

The four vanilla [rarities](/reference/items#rarity) tint the name; anything richer —
that `LEGENDARY` banner, colored per your own ladder — is a lore line plus a `tier` tag.
The tag is the machine-readable source of truth; the lore is the human-readable view.

## Lore templating

Because lore is literal text and tag reads are ordinary expressions, "templated" stat
lines are just interpolation. Read the numbers back at runtime to drive a real damage
formula — the lore shows `+100`, and your combat code reads the same `100`:

<!-- swoftc prelude=aspect.sw -->

```swoftlang
command "inspect-sword" {
    execute {
        set sword to custom_item("aspect_of_the_end")

        // tag reads are optional<Any> — give each a fallback
        set dmg to sword.tags.damage otherwise 0
        set str to sword.tags.strength otherwise 0
        set tier to sword.tags.tier otherwise "COMMON"

        // one source of truth: the same numbers the lore displays
        set effective to dmg + str / 2
        send "<gray>${tier} sword — effective damage ${effective}" to sender
    }
}
```

`otherwise` keeps every read total: a sword that never set `strength` still computes,
reading `0`. This is the [options](/guide/options) discipline reaching all the way into
NBT — a missing tag can't silently become a wrong number.

## A cooldowned ability

A cooldowned ability is a named action gated by a per-player cooldown, with feedback
while it recharges. The [`abilities`](/libraries/abilities) addon provides it in ~50
lines of SwoftLang, wired in two calls. `on_item_use` registers a handler for an item id
and click side; `with_cooldown` wraps any handler with a cooldown and an actionbar
countdown:

<!-- swoftc prelude=aspect.sw -->

```swoftlang
command "kit" {
    execute {
        give item "aspect_of_the_end" to sender
        send "<green>Kit delivered — right-click to Transmit." to sender
    }
}

command "kit-setup" {
    execute {
        // right-click the Aspect: a 3-second cooldown, then the effect
        on_item_use("aspect_of_the_end", "right", with_cooldown(3.0,
            function(user: Player, held: Item) {
                set dmg to held.tags.damage otherwise 0
                send "<aqua>Instant Transmission! (${dmg} dmg ready)" to user
            }))
        send "<gray>Aspect ability registered." to sender
    }
}
```

Run `/kit-setup` once at startup, `/kit` to get the sword, and right-click: the lambda
fires, the cooldown gates repeat presses, and the actionbar shows the countdown — a
complete cooldowned ability, visible and yours to change. The handler is a first-class
[lambda](/guide/functions#inline-functions-lambdas), so a `with_cooldown`-wrapped
function is just a value you pass along.

## What you built

- **Stats** — a `tags { }` tree, plain data, read back with `otherwise` fallbacks.
- **A tier system** — a `tier` tag plus a lore banner, colored however you like, with no
  fixed ladder to fight.
- **A cooldowned ability** — `on_item_use` + `with_cooldown` from the `abilities` addon,
  a pattern you can read, copy, and extend.

Nothing here is baked into the language, which is exactly why you can shape it into *your*
server's item system instead of someone else's. For a one-off interaction that belongs to
a single item, the [`on_click`](/reference/items#on-click) sugar skips the addon entirely;
for anything shared across many items, an event handler or an addon like this one is the
home for it.
