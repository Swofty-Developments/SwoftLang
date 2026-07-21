# Custom Items

An `item` block declares a custom item at the top level: its identity, its look, its
lore, and a tree of freeform NBT tags. The id and every tag ride the ItemStack, so the
item keeps its identity through any inventory move. The block covers appearance and data
only — cooldowns, abilities, and stat systems are built on top with [events](./events),
tags, and [addons](/libraries/abilities).

```swoftlang
item "aspect_of_the_end" {
    material: "DIAMOND_SWORD"
    name: "<blue>Aspect of the End"
    rarity: rare
    glint: true
    amount: 1

    lore {
        line "<gray>A legendary blade from the End."
        blank
        line "<dark_gray>Soulbound"
    }

    tags: {
        damage: 100,
        meta: { tier: 3, keywords: ["end", "sword"] }
    }
}

command "sword" {
    execute {
        give item "aspect_of_the_end" to sender
    }
}
```

## Declaration keys

| Key | Type | Required | Meaning |
|---|---|---|---|
| `material:` | string literal | one of material/skull | Minecraft material, bare or `minecraft:`-prefixed |
| `skull:` | string literal | one of material/skull | player-head texture (hash or full base64) — renders a custom skull |
| `name:` | String expression | no | display name; MiniMessage, italics off. Colour it yourself — nothing is auto-applied |
| `rarity:` | enum | no | one of the four vanilla rarities; see [below](#rarity) |
| `glint:` | Boolean expression | no | enchantment shimmer without an enchantment |
| `amount:` | Integer expression | no | default stack size handed out by `give item` (default 1) |
| `lore { ... }` | restricted DSL | no | the exact lore lines — WYSIWYG; see [lore](#lore) |
| `tags { ... }` | nested data | no | arbitrary NBT: scalars, lists, compounds; see [tags](#tags-the-nbt-api) |
| `attributes { ... }` | key: number pairs | no | **real** vanilla attribute modifiers, applied while held or worn |
| `on_click(<filter>) { ... }` | block | no | filtered use handler for this item; see [on_click](#on-click) |

`material` and `skull` are mutually exclusive — one identity, one look:

<!-- swoftc name=matskull.sw expect=error -->

```swoftlang
item "confused" {
    material: "STICK"
    skull: "abc"      // [!code error]
}
```

```txt
matskull.sw:1:1: error: item "confused" cannot have both 'material' and 'skull'
item "confused" {
^
```

## Rarity {#rarity}

`rarity:` sets the vanilla rarity component — the value the client uses to tint the
item's name colour. Four values are valid:

`common` · `uncommon` · `rare` · `epic`

Rarity sets that component and nothing else: no lore, banner, or stat block is assembled.
Custom tiers (legendary, mythic, a scheme of your own) are *data* — model them with a
[tag](#tags-the-nbt-api) and a [lore](#lore) line, as the [RPG item
tutorial](/guide/rpg-items) does. Any other name is rejected, with the fix in the
message:

<!-- swoftc name=rar.sw expect=error -->

```swoftlang
item "relic" {
    material: "NETHER_STAR"
    rarity: legendary      // [!code error]
}
```

```txt
rar.sw:3:13: error: rarity 'legendary' is not a SwoftLang rarity; only the four vanilla rarities are supported: common, uncommon, rare, epic (custom tiers are userland data — model them with tags{} + lore)
    rarity: legendary
            ^
```

## Lore {#lore}

The `lore { }` body is **what you see is what you get** — every line you write is a line
in the tooltip, in order, with no sections assembled for you. It is the same restricted
DSL as [scoreboard `lines { }`](./scoreboards-tablists#scoreboard):
`line <string-expr>`, `blank`, `if`/`else`, and `loop`, evaluated once when the item is
built.
MiniMessage in the strings is converted at build time.

```swoftlang
item "farmer_boots" {
    material: "GOLDEN_BOOTS"
    name: "<green>Farmer Boots"
    rarity: uncommon

    attributes: {
        speed: 0.02
        max_health: 4
    }

    lore {
        loop 2 times {
            line "<green>Tilled and true."
        }
    }
}
```

Because lore is literal, templating a stat line is just interpolation — read a tag,
print it. See [lore templating](/guide/rpg-items#lore-templating) for the pattern.

## Attributes

`attributes { }` carries **real** Minestom attribute modifiers — genuine engine
mechanics, applied while the item is in the main hand or a worn armor slot (a periodic
equipment scan diffs and applies/removes them) and removed when it isn't. The key set is
closed:

`speed` · `max_health` · `attack_damage` · `attack_speed` · `armor` ·
`knockback_resistance`

These are the vanilla attributes the server actually acts on — distinct from any custom
"stats" you invent, which live in [tags](#tags-the-nbt-api) as plain data.

## Tags: the NBT API {#tags-the-nbt-api}

`tags { }` attaches arbitrary structured data to the item — scalars, lists, and nested
compounds. Scalars become typed Minestom tags; compounds and lists become NBT structure.
The shape round-trips: what you write is what you read back.

```swoftlang
item "crypt_key" {
    skull: "1ae3855f952cd4a03c148a946e3f812a5955ad35cbcb52627ea4acd47d3081"
    name: "<gold>Crypt Key"
    rarity: epic

    tags: {
        uses: 3,
        meta: { engraving: "unclaimed" }
    }

    lore {
        line "<gray>Opens the sealed crypt beneath the graveyard."
        line "<dark_gray>Consumed on use."
    }
}
```

### Reading and writing tags at runtime

On **any** `Item` value, `item.tags.<path>` reaches into that tree. Paths nest
(`item.tags.meta.tier`), reads return an `optional<Any>`, writes set the tag, and writing
`none` deletes it.

| Form | Meaning |
|---|---|
| `item.tags.uses` | read — `optional<Any>`, `none` when the tag is absent |
| `item.tags.meta.tier` | read a nested path |
| `set item.tags.uses to 5` | write a scalar |
| `set item.tags.uses to none` | delete the tag |

Because a read is `optional`, the no-null discipline extends to NBT: a bare tag read can't
be used where a concrete value is required until you handle the missing case. Using one in
arithmetic without a fallback is a compile error:

<!-- swoftc name=tagopt.sw expect=error -->

```swoftlang
command "c" {
    execute {
        set it to custom_item("k")
        set n to it.tags.uses + 1      // [!code error]
        send "${n}" to sender
    }
}

item "k" { material: "STICK" tags: { uses: 3 } }
```

```txt
tagopt.sw:4:26: error: the left operand of '+' is optional<Any> and may be missing; check it with 'if ... exists' or provide a fallback with 'otherwise'
        set n to it.tags.uses + 1
                         ^
```

The two fixes are the familiar ones — `otherwise` for a fallback, `exists` to narrow:

```swoftlang
item "crypt_key" { material: "TRIPWIRE_HOOK" tags: { uses: 3 } }

command "use-key" {
    execute {
        set it to custom_item("crypt_key")

        // fallback: absent 'uses' reads as 0
        set left to (it.tags.uses otherwise 0) - 1

        // narrow: only inside the guard is the value known present
        if it.tags.uses exists {
            send "uses left: ${it.tags.uses}" to sender
        }
    }
}
```

## `on_click` {#on-click}

`on_click(<filter>) { }` is sugar for a filtered use handler bound to this item's id.
The filter is `left`, `right`, or `any`; inside, `player` and `item` are bound, and the
handler is cancellable. A tag write inside re-renders the item's lore and flushes it back
to the hand.

```swoftlang
item "crypt_key" {
    skull: "1ae3855f952cd4a03c148a946e3f812a5955ad35cbcb52627ea4acd47d3081"
    name: "<gold>Crypt Key"
    rarity: epic

    tags: {
        uses: 3
    }

    on_click {
        set item.tags.uses to (item.tags.uses otherwise 0) - 1
        send "<light_purple>The key turns..." to player
    }
}
```

The filter set is closed:

<!-- swoftc name=ocf.sw expect=error -->

```swoftlang
item "k" {
    material: "STICK"
    on_click(middle) {      // [!code error]
        send "x" to player
    }
}
```

```txt
ocf.sw:3:20: error: Unknown on_click filter 'middle'; valid filters: left, right, any
    on_click(middle) {
                   ^
```

## Working with items at runtime

| Form | Type / effect |
|---|---|
| `give item "id" to <player> [amount N]` | statement — puts N copies (default the item's `amount:`) in the inventory |
| `custom_item("id")` | `Item` — a fresh stack of the declared item |
| `item("MATERIAL")` / `item("MATERIAL", n)` | `Item` — a plain vanilla stack |
| `custom_id(<item>)` | `optional<String>` — the declared id, or `none` for vanilla stacks |
| `<item>.material` | `String` read/write — the material id |
| `<item>.name` | `String` read/write |
| `<item>.amount` | `Integer` read/write |
| `<item>.lore` | `list<String>` read/write |
| `<item>.tags.<path>` | the NBT namespace above |

`give item` with a literal id is resolved at compile time — a typo can't reach the
server:

<!-- swoftc name=giveid.sw expect=error -->

```swoftlang
command "kit" {
    execute {
        give item "aspect_of_the_emd" to sender      // [!code error]
    }
}
```

```txt
giveid.sw:3:19: error: unknown item 'aspect_of_the_emd' in 'give item'; declare it with 'item "aspect_of_the_emd" { }'
        give item "aspect_of_the_emd" to sender
                  ^
```

### Identity survives everything {#identity-custom-id}

Identity survives anything the ItemStack survives: the id and every tag ride the stack
itself, so a custom item dropped, stored in a chest GUI, or moved across inventories
still answers to `custom_id`.

## The `Item.on_use` method

Using any custom item fires the base [`Item.on_use`](./events#item) method — for every
custom item, whether or not it declares an `on_click`. Reach for it when a single handler
should span many item ids; reach for `on_click` when the behavior belongs to one item and
you want left/right separation.

```swoftlang
Item {
    on_use {
        if custom_id(item) otherwise "" is "aspect_of_the_end" {
            send "<gray>You used the Aspect!" to player
        }
    }
}
```

`item` is the used `Item`, `player` is the `Player` who used it, and `custom_id(item)`
reads the declaration id as an `optional<String>`; the method is cancellable.

::: tip Build a gameplay system
Stats, cooldowns, and named abilities are things you *build* on top of this — tags for
the numbers, lore templating for the display, events for the behavior. The
[Build an RPG Item System](/guide/rpg-items) tutorial walks the whole pattern, and the
[abilities](/libraries/abilities) addon packages the cooldown machinery in ~50 lines of
SwoftLang.
:::
