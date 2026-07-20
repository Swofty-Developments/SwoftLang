// kitchen-sink.sw — exercises every SwoftLang construct for grammar tokenization.
/* block comment: declarations, handlers, builtins, types, enums, namespaces,
   entity properties, operators, interpolation and MiniMessage tags. */

import "../addons/abilities"

server {
    auth: offline
    port: 25565
    motd: "<green>A <bold>SwoftLang</bold> server ${server.tps}"
    http { port: 8090, bind: "127.0.0.1" }
    fishing { min_bite: 4 seconds, max_bite: 20 seconds }
}

storage {
    backend: sqlite "data/swoftlang.db"
}
persistent balance for Player: Integer = 100
persistent scores: map<Integer> = new_map()

item "aspect_of_the_end" {
    material: "DIAMOND_SWORD"
    name: "<blue>Aspect of the End"
    rarity: rare
    glint: true
    amount: 1
    attributes {
        speed: 0.02
        max_health: 4
    }
    tags {
        damage: 100,
        meta: { tier: 3, keywords: ["end", "sword"] }
    }
    lore {
        line "<gray>A legendary blade."
        blank
    }
    on_click(left) {
        set item.tags.uses to (item.tags.uses otherwise 0) - 1
        send "<light_purple>Whoosh" to player
    }
}

mob "crypt_ghoul" {
    type: "ZOMBIE"
    name: "<red>Crypt Ghoul <green>${mob.health}"
    health: 200
    ai: melee
    drops {
        item "aspect_of_the_end" chance 0.05 amount 1
        item "ROTTEN_FLESH" chance 0.5 amount 2
    }
    on_spawn { broadcast "<gray>A ${mob.custom_id} rises" }
    on_death { if killer exists { send "<green>Slain!" to killer } }
    on_attack { send "<red>rake" to victim }
}

npc "guide" {
    location: location(2.5, 64.0, 2.5)
    name: "<green>Village Guide"
    skin: "Notch"
    look_at_players: true
    on_click(player) { send "<gold>Hi ${player.name}" to player }
}

hologram "welcome" {
    location: location(0.5, 82.0, 0.5)
    billboard: center
    scale: 1.5
    update: every 2 seconds
    lines {
        line "<gold><bold>SwoftLang"
        blank
        line "<yellow>Hi ${player.name}"
    }
}

gui "storage_gui" {
    rows: 6
    title: "Storage (page ${state.page + 1})"
    state { page: 0, enabled: true, items: [] }
    fill: item("BLACK_STAINED_GLASS_PANE", name: " ")
    border: item("GRAY_STAINED_GLASS_PANE", name: " ")
    slot 4 {
        item { material: "DIAMOND", name: "<green>Toggle", glint: state.enabled }
        on_click(right) { set state.enabled to false }
        on_click { set state.page to state.page + 1 }
        refresh: 1 seconds
    }
    editable [28..43] { on_change { send "slot ${slot} changed" to player } }
    paginate {
        source: state.items
        slots: grid(10, 27)
        render { material: "PAPER", name: "<white>#${index}" }
        on_click { send "picked ${index}" to player }
        prev_slot: 45
        next_slot: 53
    }
    on_open { send "<gray>opened" to player }
    on_close { send "<gray>closed (${reason})" to player }
}

scoreboard "main" {
    title: "<yellow><bold>SWOFTLANG"
    update: every 4 ticks
    numbers: hidden
    lines {
        line "<gray>${player.name}"
        blank
        if player.level > 0 { line " Level: ${player.level}" } else { line " none" }
    }
}

tablist "lobby" {
    update: every 3 seconds
    header: "<aqua>SWOFTY.NET"
    footer: "<green>Have fun!"
    column {
        entry centered("Players") with skin green
        loop first 18 of all_players() as p {
            entry "${p.display_name}" with skin of p
        }
        fill with skin gray
    }
}

bossbar "objective" {
    text: "Objective: <yellow>collect wood"
    progress: player.exp
    color: yellow
    style: progress
    update: every 30 ticks
}

fishing_loot "overworld_water" {
    medium: water
    world: "world"
    catch item "COD" weight 40
    catch item "aspect_of_the_end" weight 5 message "<aqua>It glimmers."
    catch mob "crypt_ghoul" weight 3 message "<red>Something walked out."
}

api "/give/:player" {
    method: POST
    execute async {
        set target to player(request.params.player)
        if target exists {
            reply code 200 with "delivered to ${request.params.player}"
        } else {
            reply code 404 with "no such player"
        }
    }
}

placement_rule for "oak_stairs" {
    on_place(loc, face, cursor, against, player) -> Block {
        return block("oak_stairs")
            .with("facing", "north")
            .with("half", "top")
    }
    on_update(loc, cur, neighbours) -> Block {
        return cur.with("shape", "straight")
    }
    self_replaceable: false
}

block_handler "oak_sign" {
    on_place(player, location, block) { send "placed ${block.id}" to player }
    on_destroy(location, block) { broadcast "mined ${block.id}" }
    on_interact(player, location, block) -> Boolean {
        send "you clicked ${block.id}" to player
        return true
    }
    on_touch(entity, location) { broadcast "something touched the sign" }
    tick(location, block) { broadcast "sign tick ${block.id}" }
}

event PlayerJoin {
    execute {
        set nametag of event.player to "<red>[ADMIN] ${event.player.name}"
        set nametag color of event.player to red
        reset nametag of event.player for all
        send packet "ParticlePacket" {
            particle: "minecraft:flame", particleCount: 40, x: 100.5
        } to event.player
    }
}

on packet "ClientPlayerDiggingPacket" {
    execute {
        if packet.status is "STARTED_DIGGING" {
            cancel packet
        }
    }
}

on EntityDamage {
    set victim to event.entity
    set raw to event.damage
    set dmg to clamp(raw, 0.0, 20.0)
    set aloc to victim.location
    knock victim away from aloc with strength 0.4
    damage victim by dmg as "generic"
    spawn particle "crit" at victim.location count 8 offset 0.4, 0.6, 0.4 speed 0.1 to all
    set event.damage to dmg
}

every 1 tick {
    loop all_players() as p {
        set exhaustion to p.tags.exhaustion otherwise 0.0
        if p.food >= 18 and p.health < p.max_health {
            set p.health to min(p.max_health, p.health + 1.0)
        }
        if p.food <= 0 and p.health > 1.0 {
            damage p by 1.0 as "starve"
        }
    }
}

var ability_now = 0

function armor_mitigated(raw: Double, armor: Double, toughness: Double) {
    set effective to armor - raw / (2.0 + toughness / 4.0)
    return raw * (1.0 - clamp(effective, 0.0, 20.0) / 25.0)
}

export function make_item_use(item_id: String, filter: String, handler) {
    return function(user: Player, held: Item) return none
}

command "demo",
command "showcase" {
    permission: "swoftlang.demo"
    description: "Everything at once"
    arguments {
        target: Player = sender
        where: either<Player|Location>
        amount: optional<Integer>
    }
    execute {
        set x to 1 + 2 * 3
        set y to (1 + 2) * 3
        set r to 17 % 5
        set half to 7 / 2.0
        send "x=${x} y=${y} r=${r} half=${half}"
        if x > 6 and x != 8 { send "big" }
        if not (x < 5) { send "not small" }
        if x = 5 { send "five" } else if x = 7 { send "seven" } else { send "other" }
        loop 3 times as i { send "iter ${i}" }
        set countdown to 3
        while countdown > 0 { set countdown to countdown - 1 }
        set name to "swoftlang"
        if name contains "swoft" { send "has swoft" }
        if x is a Number { send "number" }
        set v to velocity(0.5, 1.5, -0.5)
        set v.y to 3.0
        set m to { "b": 2, "a": 1 }
        set got to m.get("a") otherwise 0
        set names to all_mobs("crypt_ghoul")
        set blk to block_at(location(0, 64, 0))
        set gr to gradient("<red>", "<blue>", "text")
        send "picked ${got} at ${blk.id}"

        spawn mob "crypt_ghoul" at location(10, 64, 20) as g
        set g.health to g.max_health / 2
        spawn entity "ARMOR_STAND" at location(0.5, 64.0, 0.5) as stand
        set stand.custom_name to "<gold>Landmark"
        set stand.glowing to true
        mount stand on g
        dismount stand
        launch projectile "SNOWBALL" from sender with speed 2.5 as ball
        remove entity stand
        despawn g

        give item "aspect_of_the_end" to sender amount 2
        teleport target to where
        show scoreboard "main" to sender
        update scoreboard for sender
        show tablist "lobby" to sender
        show bossbar "objective" to sender
        title "<gold>WELCOME" subtitle "<gray>hi" to sender fade in 1 seconds stay 3 seconds fade out 10 ticks
        actionbar "<aqua>boost" to sender for 5 seconds
        belowname "<red>hearts" for sender
        open gui "storage_gui" to sender with { page: 0 }
        replace gui "storage_gui" to sender
        close gui for sender
        show hologram "welcome" to sender
        move hologram "welcome" to location(4.5, 83.0, 0.5)
        hide hologram "welcome" from sender
        set npc "guide" name "<aqua>Renamed"

        place block("minecraft:sea_lantern") at sender.location
        place "minecraft:oak_log" at location(1, 64, 1)
        set warning to schedule after 3 seconds { broadcast "<red>Incoming!" }
        set ticker to schedule every 10 ticks as "ticker" { broadcast "<gray>tick" }
        cancel schedule warning
        cancel schedule "ticker"
        set sender.tasks.welcome to schedule every 20 ticks { send "<gray>hi" to sender }
        if sender.tasks.welcome is running { send "running" to sender }
        cancel sender.tasks.welcome
        remove block at sender.location
        async { wait 2 seconds }

        broadcast "<gold>done"
        halt
    }
}
