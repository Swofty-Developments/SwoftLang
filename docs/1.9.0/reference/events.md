# Receivers & Events

SwoftLang handles server events through **receivers** — Capitalized top-level blocks,
one per engine subject, whose members are fixed-name methods that fire when something
happens to that subject. A `Player { }` block groups everything that can happen to a
player; a `Mob { }` block groups everything that can happen to a mob; and so on.

```swoftlang
Player {
    on_join {
        broadcast "<yellow>${player.name} joined the game"
    }

    on_chat {
        send "<gray>You said: ${message}" to player
    }
}
```

Inside every method the subject is a bare variable named after its type — `player`, `mob`,
`block`, and so on. Each section states its subject once ("The subject is bound as
`…`."), so the **Bound variables** column lists only the *additional* event data — the
subject itself is never repeated there. The rest of the event's data is bound alongside the
subject as bare variables, with types fixed by the catalog and the names listed in each
receiver's table below. A variable tagged `rw` may be reassigned to change what the engine
does (e.g. rewrite a chat `message`); untagged variables are read-only inputs.

## The receiver catalog

A **base receiver** is a Capitalized type whose methods fire for *every* instance of that
type. Eleven base receivers cover the engine, plus the special `Packet` block for raw
packets:

| Receiver | Subject variable | Fires for |
|---|---|---|
| `Player` | `player` | every online player |
| `Entity` | `entity` | every live entity (players, mobs, projectiles, items) |
| `Mob` | `mob` | every server-spawned mob |
| `Item` | `item` (the item stack) | the item involved in an interaction |
| `Block` | `block` | the positioned block value |
| `Projectile` | `projectile` | arrows, snowballs, thrown items in flight |
| `Inventory` | `inventory` | open-inventory / GUI interactions |
| `World` | `world` | world lifecycle, ticks, chunks |
| `Server` | `server` | the global singleton + pre-login / connection events |
| `Npc` | `npc` | [NPC](./npcs) clicks and ticks |
| `Hologram` | `hologram` | [hologram](./holograms) clicks and ticks |
| `Packet` | `packet` + `player` | [raw inbound packets](#the-packet-receiver), keyed by class name |

A method name is checked against its receiver's table at compile time, and so is every
variable it reaches for — a handler that would never fire, or one that reaches for data the
event never binds, is a compile error (a misspelled method name gets the nearest match
suggested):

<!-- swoftc name=ev.sw expect=error -->

```swoftlang
Player {
    on_join {
        send "<red>Under attack!" to attacker    // [!code error]
    }
}
```

```txt
ev.sw:3:38: error: variable 'attacker' is never assigned
        send "<red>Under attack!" to attacker
                                     ^
```

::: tip Base receivers vs. custom declarations
The base receiver (`Mob { }`) is the **base type** — its methods run for every mob.
A custom nominal declaration (`mob Ghoul { }`, `item Rod { }`) is a
**custom subtype** that carries the same method set but scoped to that one type, and
[overrides](#overriding-a-base-receiver) the base for its instances.
:::

## Player

Every online player. The subject is bound as `player`.

| Method | Cancellable | Bound variables |
|---|---|---|
| `on_join` | — | — |
| `on_quit` | — | — |
| `on_loaded` | — | — |
| `on_chat` | yes | `message` (String, rw) |
| `on_move` | yes | `new_position` (Location, rw) |
| `on_death` | — | `death_text` (String, rw), `chat_message` (String, rw) |
| `on_respawn` | — | `respawn_position` (Location, rw) |
| `on_command` | yes | `command` (String, rw) |
| `on_break_block` | yes | `block` (String), `location` (Location), `face` (String) |
| `on_place_block` | yes | `block` (String), `location` (Location), `face` (String), `hand` (String) |
| `on_interact_block` | yes | `block` (String), `location` (Location), `face` (String), `hand` (String) |
| `on_use_item` | yes | `item` (Item), `hand` (String) |
| `on_use_item_on_block` | — | `item_stack` (Item), `location` (Location), `face` (String), `hand` (String) |
| `on_start_digging` | yes | `block` (String), `location` (Location), `face` (String) |
| `on_finish_digging` | — | `block` (String), `location` (Location) |
| `on_cancel_digging` | — | `block` (String), `location` (Location) |
| `on_change_held_slot` | yes | `new_slot` (Integer, rw), `old_slot` (Integer) |
| `on_swap_item` | yes | `main_hand_item` (Item, rw), `off_hand_item` (Item, rw) |
| `on_gamemode_change` | yes | `new_game_mode` (String, rw) |
| `on_start_sprinting` · `on_stop_sprinting` | — | — |
| `on_start_flying` · `on_stop_flying` | — | — |
| `on_start_elytra` · `on_stop_elytra` | — | — |
| `on_interact_entity` | — | `target` (Entity), `hand` (String) |
| `on_spectate_entity` | — | `target` (Entity) |
| `on_teleport_to_entity` | — | `target` (Entity) |
| `on_pick_entity` | — | `target` (Entity) |
| `on_pick_block` | — | `block` (String), `location` (Location) |
| `on_edit_sign` | — | `block` (String), `block_position` (Location) |
| `on_edit_book` | — | — |
| `on_anvil_input` | — | `input` (String) |
| `on_leave_bed` | yes | — |
| `on_hand_animation` | yes | — |
| `on_input` | — | — |
| `on_tick` · `on_tick_end` | — | — |
| `on_chunk_load` · `on_chunk_unload` | — | `chunk_x` (Integer), `chunk_z` (Integer) |
| `on_skin_init` | — | `skin` (Skin, rw) |
| `on_settings_change` | — | — |
| `on_resource_pack_status` | — | — |
| `on_plugin_message` | — | — |
| `on_advancement_tab` | — | — |
| `on_stab` | — | `item_stack` (Item) |
| `on_pickup_experience` | yes | `experience_count` (Integer, rw) |
| `on_drop_item` | yes | `item` (Item) |
| `on_pickup_item` | — | — |
| `on_packet_in` · `on_packet_out` | yes | — |
| `on_begin_item_use` | yes | — |
| `on_cancel_item_use` · `on_finish_item_use` | — | — |
| `on_outgoing_transfer` | yes | `host` (String, rw), `port` (Integer, rw) |
| `on_cast_rod` · `on_fish_bite` · `on_catch_fish` · `on_reel_in` | — | [fishing](./fishing) |

## Entity

Base for every live entity — players, mobs, projectiles, dropped items. The subject is
bound as `entity`.

| Method | Cancellable | Bound variables |
|---|---|---|
| `on_hit` | yes | `attacker` (optional&lt;Entity&gt;) |
| `on_death` | — | — |
| `on_spawn` · `on_despawn` | — | — |
| `on_attack` | — | `target` (Entity) — `entity` is the attacker |
| `on_tick` | — | — |
| `on_teleport` | — | `new_position` (Location) |
| `on_velocity` | yes | `velocity` (Vec, rw) |
| `on_shoot` | yes | `projectile` (Entity), `to` (Location), `power` (Double, rw), `spread` (Double, rw) |
| `on_set_fire` | yes | `fire_ticks` (Integer, rw) |
| `on_fire_extinguish` | yes | — |
| `on_item_merge` | yes | — |
| `on_potion_add` · `on_potion_remove` | `on_potion_add` only | — |
| `on_equip` | — | `equipped_item` (Item, rw), `slot` (String) |
| `on_pickup_item` | yes | `item_stack` (Item), `item_entity` (Entity) |

## Mob

`Mob <: Entity` — narrows Entity to server-spawned mobs. The subject is bound as `mob`. A
`mob <MobType> { }` declaration ([Mobs](./mobs)) carries the same method set for one
mob type and overrides the base.

| Method | Cancellable | Bound variables |
|---|---|---|
| `on_hit` | — | `attacker` (Entity) |
| `on_death` | — | `killer` (optional&lt;Entity&gt;) |
| `on_spawn` | — | — |
| `on_tick` | — | — |
| `on_attack` | — | `target` (Entity) |
| `on_target` | — | `target` (optional&lt;Entity&gt;) |
| `on_click` | — | `player` (Player) |
| `on_despawn` | — | — |
| `on_teleport` | — | `new_position` (Location) |
| `on_shoot` | yes | `projectile` (Entity), `to` (Location), `power` (Double, rw), `spread` (Double, rw) |

## Item

The item stack involved in an interaction. The subject is bound as `item`. An
`item <ItemType> { }` declaration ([Items](./items)) carries the same method set for one item and
overrides the base.

`item` is the base `ItemStack`, so it carries the base-Item properties (`material`, `amount`,
`name`, `lore`, read-only `tags`). A custom id is not a base-Item property — it is reached as
`custom_id(item)`, whose type is `Optional<String>`: empty for a vanilla stack, set only when
the stack is a custom item type.

| Method | Cancellable | Bound variables |
|---|---|---|
| `on_use` | yes | `player` (Player) |
| `on_right_click` | yes | `player` (Player) |
| `on_right_click_block` | — | `player` (Player), `location` (Location), `face` (String) |
| `on_left_click` | — | `player` (Player) |
| `on_attack_entity` | — | `player` (Player), `target` (Entity) |
| `on_consume` | — | `player` (Player) |
| `on_drop` | yes | `player` (Player) |
| `on_pickup` | — | `player` (Player) |
| `on_swap_to` | — | `player` (Player) |
| `on_break` | — | `player` (Player) |
| `on_begin_use` | yes | `player` (Player) |
| `on_cancel_use` · `on_finish_use` | — | `player` (Player) |
| `on_equip` | — | `entity` (Entity), `slot` (String) |

## Block

The positioned block value. The subject is bound as `block`. A lowercase
`block_handler "id" { }` declaration ([Blocks](./blocks)) carries the same method set for
one block id and overrides the base.

| Method | Cancellable | Bound variables |
|---|---|---|
| `on_place` | — | `player` (Player), `location` (Location), `block` (Block) |
| `on_break` | yes | `player` (Player) |
| `on_destroy` | — | `location` (Location), `block` (Block) |
| `on_interact` | yes | `player` (Player), `location` (Location), `block` (Block) |
| `on_touch` | — | `entity` (Entity), `location` (Location) |
| `on_tick` | — | `location` (Location), `block` (Block) |
| `on_dispense` | yes | `item` (Item), `direction` (String) — see [Dispensers](./dispensers) |
| `on_update` | — | `location` (Location), `block` (Block) |

## Projectile

`Projectile <: Entity` — projectile lifecycle. The subject is bound as `projectile`. (The
shooter side is reachable via [`Entity.on_shoot`](#entity).)

| Method | Cancellable | Bound variables |
|---|---|---|
| `on_hit_block` | yes | `block` (Block), `world` (World) |
| `on_hit_entity` | yes | `target` (Entity) |
| `on_uncollide` | — | — |

## Inventory

Open-inventory and GUI interactions. The subject is bound as `inventory`.

| Method | Cancellable | Bound variables |
|---|---|---|
| `on_pre_click` | yes | `player` (Player), `slot` (Integer), `clicked_item` (Item) |
| `on_click` | — | `player` (Player), `slot` (Integer), `click_type` (String), `clicked_item` (Item), `cursor_item` (Item) |
| `on_open` | yes | `player` (Player) |
| `on_close` | — | `player` (Player), `from_client` (Boolean) |
| `on_button_click` | — | `player` (Player) |
| `on_bundle_select` | — | `player` (Player), `selected_item_index` (Integer) |
| `on_item_change` | — | `new_item` (Item), `previous_item` (Item), `slot` (Integer) |
| `on_creative_action` | yes | `player` (Player), `slot` (Integer), `clicked_item` (Item, rw) |

## World

The world (Minestom instance). The subject is bound as `world`.

| Method | Cancellable | Bound variables |
|---|---|---|
| `on_tick` | — | `duration` (Integer) |
| `on_chunk_load` · `on_chunk_unload` | — | `chunk_x` (Integer), `chunk_z` (Integer) |
| `on_register` · `on_unregister` | — | — |
| `on_section_invalidate` | — | — |
| `on_block_update` | — | `block` (Block), `block_position` (Location) |
| `on_entity_add` | yes | `entity` (Entity) |
| `on_entity_remove` | — | `entity` (Entity) |

## Server

The global singleton, plus the pre-login and connection-only events that have no player
or entity subject yet. The subject is bound as `server` ([Server config](./server-config)).

| Method | Cancellable | Bound variables |
|---|---|---|
| `on_list_ping` | yes | `status` (String, rw) |
| `on_client_ping` | yes | `delay` (Integer, rw), `payload` (Integer, rw) |
| `on_tick_monitor` | — | — |
| `on_pre_login` | — | `connection` (Any), `username` (String, rw), `game_profile` (Any) |
| `on_player_configuration` | — | `player` (Player), `spawning_instance` (World, rw), `hardcore` (Boolean) |
| `on_tps_change` | — | `past` (Double), `current` (Double) — see [TPS](./maps-toasts-skins-tps) |

::: tip No `Player` before login
`on_pre_login`, `on_client_ping`, and `on_list_ping` fire before there is a `Player`
object — they carry only a raw connection, which is why they live on `Server` rather than
`Player`.
:::

## Npc & Hologram

The [NPC](./npcs) and [hologram](./holograms) receivers reuse the same method set as their
lowercase `npc "id" { }` / `hologram "id" { }` declarations. None of these methods are
cancellable.

For `Npc` the subject is bound as `npc` (the NPC's fake-player entity):

| Method | Cancellable | Bound variables |
|---|---|---|
| `on_click` | — | `player` (Player) |
| `on_left_click` | — | `player` (Player) |
| `on_tick` | — | — |

For `Hologram` the subject is bound as `hologram` (the hologram's text-display stack):

| Method | Cancellable | Bound variables |
|---|---|---|
| `on_click` | — | `player` (Player) |
| `on_line_click` | — | `player` (Player), `line` (Integer) |
| `on_tick` | — | — |

## Fan-out — one event, several receivers

A single engine event can surface on more than one receiver, so you handle it wherever it
reads most naturally. When a player breaks a block, both the block and the player see it;
when an entity takes damage, `Entity.on_hit` fires, and if the entity is a mob,
`Mob.on_hit` fires too.

| Engine event | Receivers it surfaces on |
|---|---|
| block break | `Block.on_break` · `Player.on_break_block` |
| block place | `Block.on_place` · `Player.on_place_block` |
| block interact | `Block.on_interact` · `Player.on_interact_block` |
| entity damaged | `Entity.on_hit` · `Mob.on_hit` |
| item used | `Item.on_use` · `Player.on_use_item` |
| item dropped | `Item.on_drop` · `Player.on_drop_item` |
| item picked up | `Item.on_pickup` · `Entity.on_pickup_item` · `Player.on_pickup_item` |

The most-specific subject fires first — a custom `mob <MobType>` before base `Mob` before base
`Entity`. A [`cancel`](#cancelling) in any handler vetoes the shared underlying event;
later handlers still run and can observe or undo the decision.

## Overriding a base receiver

A custom declaration (`mob <MobType> { }`, `item <ItemType> { }`, `block_handler "id"
{ }`) carries the same method set as its base receiver, and **most-specific wins**: when a
custom method and the base method both exist, the custom one replaces the base for that
id. To keep the base behavior, write `call original method` from inside the overriding
method. It re-runs the base method with the current bound-variable values, so mutate a
bound variable before the call to forward a changed value to it:

```swoftlang
Mob {
    on_click {
        send "<gray>You poke a ${mob.type}." to player
    }
}

mob Ghoul {
    type: "ZOMBIE"
    name: "<dark_green>Ghoul"
    health: 40

    on_click {
        send "<green>You poke the ghoul." to player
        call original method            // also run base Mob.on_click
    }

    on_target {
        call original method            // re-run base Mob.on_target with the current target
    }
}
```

`call original method` is only legal inside an overriding method — writing it in a base
receiver or a method that overrides nothing is a compile error.

## Struct-instance receivers {#struct-receivers}

A third kind of receiver lives on a [struct](/1.9.0/reference/structs). Mark a struct field
`@EventReceiver` and it becomes an event subject *for that one instance*; the struct then
carries handlers, named after the field, using the same method table as the field's type.
Where a base receiver fires for every instance and a custom declaration fires for one
declared type, a struct-instance handler fires for the **one live struct instance** that
holds the subject — a specific duel, a specific party.

```swoftlang
struct Duel {
    @EventReceiver a: Player
    arena: Location

    a {
        on_death { teleport a to arena }      // only for this duel's player `a`
    }
}

persistent duels: Map<String, Duel> = new_map()
```

An instance is live exactly while it is reachable from a `persistent` root, so its handlers
are durable and self-cleaning — see [Reactive fields](/1.9.0/reference/structs#reactive) for the
liveness model and the constraint that a custom type can't be a reactive subject.

This adds a third link to the dispatch chain. For one native event the order is
**global base receiver → custom override → live struct-instance handler(s)**, least
specific first. Cancellation stays [cumulative](#cancelling): every layer runs in order,
any layer may `cancel event`, and later layers still execute and can observe the cancel.

## Cancelling

`cancel event` vetoes the underlying server event — a cancelled chat message is never
broadcast. It is legal only inside a method the engine marks **cancellable** (the
Cancellable column above), and only *before* the handler goes async. Anywhere else it is a
compile error:

<!-- swoftc name=nc.sw expect=error -->

```swoftlang
Player {
    on_join {
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
not block a tick, following the usual [async coloring](/1.9.0/guide/async) rules. Cancellation is
sync-only, so decide and `cancel` synchronously, then hand slow work to an async method or
a spawned task:

```swoftlang
Player {
    on_chat {
        if message contains "spoiler" {
            cancel event
            spawn warn_later(player)
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

The typed `Player.on_packet_in` / `on_packet_out` methods cover the common
"a packet arrived" case; reach for `Packet { }` only when you need a specific packet class
by name.

## Commands are separate

[`command "..." { }`](/1.9.0/guide/commands) declarations are not events — they define the
slash-commands players type, and are unchanged. Receivers handle what *happens* on the
server; commands handle what players *ask for*.
