# Receivers & Events

SwoftLang handles server events through **receivers** — Capitalized top-level blocks,
one per engine subject, whose members are fixed-name methods that fire when something
happens to that subject. A `Player { }` block groups everything that can happen to a
player; a `Mob { }` block groups everything that can happen to a mob; and so on.

```swoftlang
Player {
    on_join() {
        broadcast "<yellow>${this.name} joined the game"
    }

    on_chat(message) {
        send "<gray>You said: ${message}" to this
    }
}
```

Inside every method, `this` is the subject the block is about — the joining player, the
mob that took a hit, the block that was placed. The method's parameters bind the rest of
the event's data, positionally, with types fixed by the catalog and names you choose.

## The receiver catalog

A **base receiver** is a Capitalized type whose methods fire for *every* instance of that
type. Eleven base receivers cover the engine, plus the special `Packet` block for raw
packets:

| Receiver | `this` | Fires for |
|---|---|---|
| `Player` | the player | every online player |
| `Entity` | the entity | every live entity (players, mobs, projectiles, items) |
| `Mob` | the mob | every server-spawned mob |
| `Item` | the item stack | the item involved in an interaction |
| `Block` | the block | the positioned block value |
| `Projectile` | the projectile entity | arrows, snowballs, thrown items in flight |
| `Inventory` | the open inventory | open-inventory / GUI interactions |
| `World` | the world (instance) | world lifecycle, ticks, chunks |
| `Server` | the server | the global singleton + pre-login / connection events |
| `Npc` | the npc's entity | [NPC](./npcs) clicks and ticks |
| `Hologram` | the hologram display | [hologram](./holograms) clicks and ticks |
| `Packet` | — | [raw inbound packets](#the-packet-receiver), keyed by class name |

A method name is checked against its receiver's table at compile time, and so is its
parameter count — a handler that would never fire, or one that binds the wrong data, is a
compile error (a misspelled method name gets the nearest match suggested):

<!-- swoftc name=ev.sw expect=error -->

```swoftlang
Player {
    on_chat() {            // [!code error]
        broadcast "hi"
    }
}
```

```txt
ev.sw:2:5: error: Player method 'on_chat' expects 1 parameter (message: String), got 0
    on_chat() {
    ^
```

::: tip Base receivers vs. custom declarations
A Capitalized receiver (`Mob { }`) is the **base type** — its methods run for every mob.
A lowercase declaration with a string id (`mob "ghoul" { }`, `item "rod" { }`) is a
**custom subtype** that carries the same method set but scoped to that one id, and
[overrides](#overriding-a-base-receiver) the base for its instances.
:::

## Player

Every online player. `this` is the player.

| Method | Cancellable | Parameters |
|---|---|---|
| `on_join()` | — | — |
| `on_quit()` | — | — |
| `on_loaded()` | — | — |
| `on_chat(message)` | yes | `message` (String, rw) |
| `on_move(new_position)` | yes | `new_position` (Location, rw) |
| `on_death(death_text, chat_message)` | — | `death_text` (String, rw), `chat_message` (String, rw) |
| `on_respawn(respawn_position)` | — | `respawn_position` (Location, rw) |
| `on_command(command)` | yes | `command` (String, rw) |
| `on_break_block(block, location, face)` | yes | `block` (String), `location` (Location), `face` (String) |
| `on_place_block(block, location, face, hand)` | yes | `block` (String), `location` (Location), `face` (String), `hand` (String) |
| `on_interact_block(block, location, face, hand)` | yes | `block` (String), `location` (Location), `face` (String), `hand` (String) |
| `on_use_item(item, hand)` | yes | `item` (Item), `hand` (String) |
| `on_use_item_on_block(item_stack, location, face, hand)` | — | `item_stack` (Item), `location` (Location), `face` (String), `hand` (String) |
| `on_start_digging(block, location, face)` | yes | `block` (String), `location` (Location), `face` (String) |
| `on_finish_digging(block, location)` | — | `block` (String), `location` (Location) |
| `on_cancel_digging(block, location)` | — | `block` (String), `location` (Location) |
| `on_change_held_slot(new_slot, old_slot)` | yes | `new_slot` (Integer, rw), `old_slot` (Integer) |
| `on_swap_item(main_hand_item, off_hand_item)` | yes | `main_hand_item` (Item, rw), `off_hand_item` (Item, rw) |
| `on_gamemode_change(new_game_mode)` | yes | `new_game_mode` (String, rw) |
| `on_start_sprinting()` · `on_stop_sprinting()` | — | — |
| `on_start_flying()` · `on_stop_flying()` | — | — |
| `on_start_elytra()` · `on_stop_elytra()` | — | — |
| `on_interact_entity(target, hand)` | — | `target` (Entity), `hand` (String) |
| `on_spectate_entity(target)` | — | `target` (Entity) |
| `on_teleport_to_entity(target)` | — | `target` (Entity) |
| `on_pick_entity(target)` | — | `target` (Entity) |
| `on_pick_block(block, location)` | — | `block` (String), `location` (Location) |
| `on_edit_sign(block, block_position)` | — | `block` (String), `block_position` (Location) |
| `on_edit_book()` | — | — |
| `on_anvil_input(input)` | — | `input` (String) |
| `on_leave_bed()` | yes | — |
| `on_hand_animation()` | yes | — |
| `on_input()` | — | — |
| `on_tick()` · `on_tick_end()` | — | — |
| `on_chunk_load(chunk_x, chunk_z)` · `on_chunk_unload(chunk_x, chunk_z)` | — | `chunk_x` (Integer), `chunk_z` (Integer) |
| `on_skin_init(skin)` | — | `skin` (Skin, rw) |
| `on_settings_change()` | — | — |
| `on_resource_pack_status()` | — | — |
| `on_plugin_message()` | — | — |
| `on_advancement_tab()` | — | — |
| `on_stab(item_stack)` | — | `item_stack` (Item) |
| `on_pickup_experience(experience_count)` | yes | `experience_count` (Integer, rw) |
| `on_drop_item(item)` | yes | `item` (Item) |
| `on_pickup_item()` | — | — |
| `on_packet_in()` · `on_packet_out()` | yes | — |
| `on_begin_item_use()` | yes | — |
| `on_cancel_item_use()` · `on_finish_item_use()` | — | — |
| `on_outgoing_transfer(host, port)` | yes | `host` (String, rw), `port` (Integer, rw) |
| `on_cast_rod()` · `on_fish_bite()` · `on_catch_fish()` · `on_reel_in()` | — | [fishing](./fishing) |

## Entity

Base for every live entity — players, mobs, projectiles, dropped items. `this` is the
subject entity.

| Method | Cancellable | Parameters |
|---|---|---|
| `on_hit(attacker)` | yes | `attacker` (optional&lt;Entity&gt;) |
| `on_death()` | — | — |
| `on_spawn()` · `on_despawn()` | — | — |
| `on_attack(target)` | — | `target` (Entity) — `this` is the attacker |
| `on_tick()` | — | — |
| `on_teleport(new_position)` | — | `new_position` (Location) |
| `on_velocity(velocity)` | yes | `velocity` (Vec, rw) |
| `on_shoot(projectile, to, power, spread)` | yes | `projectile` (Entity), `to` (Location), `power` (Double, rw), `spread` (Double, rw) |
| `on_set_fire(fire_ticks)` | yes | `fire_ticks` (Integer, rw) |
| `on_fire_extinguish()` | yes | — |
| `on_item_merge()` | yes | — |
| `on_potion_add()` · `on_potion_remove()` | `on_potion_add` only | — |
| `on_equip(equipped_item, slot)` | — | `equipped_item` (Item, rw), `slot` (String) |
| `on_pickup_item(item_stack, item_entity)` | yes | `item_stack` (Item), `item_entity` (Entity) |

## Mob

`Mob <: Entity` — narrows Entity to server-spawned mobs. A lowercase `mob "id" { }`
declaration ([Mobs](./mobs)) carries the same method set for one mob type and overrides
the base.

| Method | Cancellable | Parameters |
|---|---|---|
| `on_hit(attacker)` | — | `attacker` (Entity) |
| `on_death(killer)` | — | `killer` (optional&lt;Entity&gt;) |
| `on_spawn()` | — | — |
| `on_tick()` | — | — |
| `on_attack(target)` | — | `target` (Entity) |
| `on_target(target)` | — | `target` (optional&lt;Entity&gt;) |
| `on_click(player)` | — | `player` (Player) |
| `on_despawn()` | — | — |
| `on_teleport(new_position)` | — | `new_position` (Location) |
| `on_shoot(projectile, to, power, spread)` | yes | `projectile` (Entity), `to` (Location), `power` (Double, rw), `spread` (Double, rw) |

## Item

The item stack involved in an interaction. A lowercase `item "id" { }` declaration
([Items](./items)) carries the same method set for one item and overrides the base.

| Method | Cancellable | Parameters |
|---|---|---|
| `on_use(player)` | yes | `player` (Player) |
| `on_right_click(player)` | yes | `player` (Player) |
| `on_right_click_block(player, location, face)` | — | `player` (Player), `location` (Location), `face` (String) |
| `on_left_click(player)` | — | `player` (Player) |
| `on_attack_entity(player, target)` | — | `player` (Player), `target` (Entity) |
| `on_consume(player)` | — | `player` (Player) |
| `on_drop(player)` | yes | `player` (Player) |
| `on_pickup(player)` | — | `player` (Player) |
| `on_swap_to(player)` | — | `player` (Player) |
| `on_break(player)` | — | `player` (Player) |
| `on_begin_use(player)` | yes | `player` (Player) |
| `on_cancel_use(player)` · `on_finish_use(player)` | — | `player` (Player) |
| `on_equip(entity, slot)` | — | `entity` (Entity), `slot` (String) |

## Block

The positioned block value. A lowercase `block_handler "id" { }` declaration
([Blocks](./blocks)) carries the same method set for one block id and overrides the base.

| Method | Cancellable | Parameters |
|---|---|---|
| `on_place(player, location, block)` | — | `player` (Player), `location` (Location), `block` (Block) |
| `on_break(player)` | yes | `player` (Player) |
| `on_destroy(location, block)` | — | `location` (Location), `block` (Block) |
| `on_interact(player, location, block)` | yes | `player` (Player), `location` (Location), `block` (Block) |
| `on_touch(entity, location)` | — | `entity` (Entity), `location` (Location) |
| `on_tick(location, block)` | — | `location` (Location), `block` (Block) |
| `on_dispense(item, direction)` | yes | `item` (Item), `direction` (String) — see [Dispensers](./dispensers) |
| `on_update(location, block)` | — | `location` (Location), `block` (Block) |

## Projectile

`Projectile <: Entity` — projectile lifecycle. `this` is the projectile entity. (The
shooter side is reachable via [`Entity.on_shoot`](#entity).)

| Method | Cancellable | Parameters |
|---|---|---|
| `on_hit_block(block, world)` | yes | `block` (Block), `world` (World) |
| `on_hit_entity(target)` | yes | `target` (Entity) |
| `on_uncollide()` | — | — |

## Inventory

Open-inventory and GUI interactions.

| Method | Cancellable | Parameters |
|---|---|---|
| `on_pre_click(player, slot, clicked_item)` | yes | `player` (Player), `slot` (Integer), `clicked_item` (Item) |
| `on_click(player, slot, click_type, clicked_item, cursor_item)` | — | `player` (Player), `slot` (Integer), `click_type` (String), `clicked_item` (Item), `cursor_item` (Item) |
| `on_open(player)` | yes | `player` (Player) |
| `on_close(player, from_client)` | — | `player` (Player), `from_client` (Boolean) |
| `on_button_click(player)` | — | `player` (Player) |
| `on_bundle_select(player, selected_item_index)` | — | `player` (Player), `selected_item_index` (Integer) |
| `on_item_change(new_item, previous_item, slot)` | — | `new_item` (Item), `previous_item` (Item), `slot` (Integer) |
| `on_creative_action(player, slot, clicked_item)` | yes | `player` (Player), `slot` (Integer), `clicked_item` (Item, rw) |

## World

The world (Minestom instance). `this` is the world.

| Method | Cancellable | Parameters |
|---|---|---|
| `on_tick(duration)` | — | `duration` (Integer) |
| `on_chunk_load(chunk_x, chunk_z)` · `on_chunk_unload(chunk_x, chunk_z)` | — | `chunk_x` (Integer), `chunk_z` (Integer) |
| `on_register()` · `on_unregister()` | — | — |
| `on_section_invalidate()` | — | — |
| `on_block_update(block, block_position)` | — | `block` (Block), `block_position` (Location) |
| `on_entity_add(entity)` | yes | `entity` (Entity) |
| `on_entity_remove(entity)` | — | `entity` (Entity) |

## Server

The global singleton, plus the pre-login and connection-only events that have no player
or entity subject yet. `this` is the server ([Server config](./server-config)).

| Method | Cancellable | Parameters |
|---|---|---|
| `on_list_ping(status)` | yes | `status` (String, rw) |
| `on_client_ping(delay, payload)` | yes | `delay` (Integer, rw), `payload` (Integer, rw) |
| `on_tick_monitor()` | — | — |
| `on_pre_login(connection, username, game_profile)` | — | `connection` (Any), `username` (String, rw), `game_profile` (Any) |
| `on_player_configuration(player, spawning_instance, hardcore)` | — | `player` (Player), `spawning_instance` (World, rw), `hardcore` (Boolean) |
| `on_tps_change(past, current)` | — | `past` (Double), `current` (Double) — see [TPS](./maps-toasts-skins-tps) |

::: tip No `Player` before login
`on_pre_login`, `on_client_ping`, and `on_list_ping` fire before there is a `Player`
object — they carry only a raw connection, which is why they live on `Server` rather than
`Player`.
:::

## Npc & Hologram

The [NPC](./npcs) and [hologram](./holograms) receivers reuse the same method set as their
lowercase `npc "id" { }` / `hologram "id" { }` declarations:

| Receiver | Methods |
|---|---|
| `Npc` | `on_click(player)`, `on_left_click(player)`, `on_tick()` |
| `Hologram` | `on_click(player)`, `on_line_click(player, line)`, `on_tick()` |

## Fan-out — one event, several receivers

A single engine event can surface on more than one receiver, so you handle it wherever it
reads most naturally. When a player breaks a block, both the block and the player see it;
when an entity takes damage, `Entity.on_hit` fires, and if the entity is a mob,
`Mob.on_hit` fires too.

| Engine event | Receivers it surfaces on |
|---|---|
| block break | `Block.on_break(player)` · `Player.on_break_block(block, location, face)` |
| block place | `Block.on_place(player, location, block)` · `Player.on_place_block(...)` |
| block interact | `Block.on_interact(player, location, block)` · `Player.on_interact_block(...)` |
| entity damaged | `Entity.on_hit(attacker)` · `Mob.on_hit(attacker)` |
| item used | `Item.on_use(player)` · `Player.on_use_item(item, hand)` |
| item dropped | `Item.on_drop(player)` · `Player.on_drop_item(item)` |
| item picked up | `Item.on_pickup(player)` · `Entity.on_pickup_item(...)` · `Player.on_pickup_item()` |

The most-specific subject fires first — a custom `mob "id"` before base `Mob` before base
`Entity`. A [`cancel`](#cancelling) in any handler vetoes the shared underlying event;
later handlers still run and can observe or undo the decision.

## Overriding a base receiver

A lowercase custom declaration (`mob "id" { }`, `item "id" { }`, `block_handler "id"
{ }`) carries the same method set as its base receiver, and **most-specific wins**: when a
custom method and the base method both exist, the custom one replaces the base for that
id. To keep the base behavior, call `default()` (or the equivalent `super.<method>(...)`)
from inside the overriding method:

```swoftlang
Mob {
    on_click(player) {
        send "<gray>You poke a ${this.type}." to player
    }
}

mob "ghoul" {
    type: "ZOMBIE"
    name: "<dark_green>Ghoul"
    health: 40

    on_click(player) {
        send "<green>You poke the ghoul." to player
        default()                       // also run base Mob.on_click
    }

    on_target(target) {
        super.on_target(target)
    }
}
```

`default()` and `super.<method>(...)` are only legal inside an overriding method — calling
`default()` from a base receiver or a method that overrides nothing is a compile error.

## Cancelling

`cancel event` vetoes the underlying server event — a cancelled chat message is never
broadcast. It is legal only inside a method the engine marks **cancellable** (the
Cancellable column above), and only *before* the handler goes async. Anywhere else it is a
compile error:

<!-- swoftc name=nc.sw expect=error -->

```swoftlang
Player {
    on_join() {
        cancel event      // [!code error]
    }
}
```

```txt
nc.sw:3:9: error: event 'on_join' is not cancellable
        cancel event
        ^
```

## Async methods

A method runs on the tick thread by default. Mark its body `async` where slow work must
not block a tick, following the usual [async coloring](/1.2.0/guide/async) rules. Cancellation is
sync-only, so decide and `cancel` synchronously, then hand slow work to an async method or
a spawned task:

```swoftlang
Player {
    on_chat(message) {
        if message contains "spoiler" {
            cancel event
            spawn warn_later(this)
        }
    }
}

async function warn_later(p: Player) {
    wait 1 seconds
    send "<red>No spoilers in chat!" to p
}
```

## The Packet receiver

`Packet { }` is the raw-packet escape hatch: a listener on inbound Minestom packets keyed
by class name, for the rare cases the typed receivers above don't cover. Each `on
"ClassName" { }` handler binds `player` (the sender) and `packet` (the raw packet) in
scope. See [Packets](./packets) for the full treatment.

```swoftlang
Packet {
    on "ClientPlayerActionPacket" {
        broadcast "<gray>${player.name} sent a player-action packet"
    }
}
```

The typed `Player.on_packet_in()` / `on_packet_out()` methods cover the common
"a packet arrived" case; reach for `Packet { }` only when you need a specific packet class
by name.

## Commands are separate

[`command "..." { }`](/1.2.0/guide/commands) declarations are not events — they define the
slash-commands players type, and are unchanged. Receivers handle what *happens* on the
server; commands handle what players *ask for*.
