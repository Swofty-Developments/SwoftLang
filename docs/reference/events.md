# Event Catalog

An `event <Name> { }` handler can name **any concrete Minestom event**. The catalog on
this page is generated at build time from the pinned engine snapshot (Minestom
`ebaa2bbf64`) — every public class under `net.minestom.server.event.**` that implements
`Event`, plus SwoftLang's own first-class events (fishing, dispensers, mobs, TPS). Name
one by its short catalog name or by its simple class name, and the compiler wires a
listener for you.

```swoftlang
event PlayerStartSprinting {
    execute {
        send "${event.player.name} sprints" to event.player
    }
}
```

## Naming an event

Every catalog entry answers to two spellings — the **short name** (the class name with
the trailing `Event` dropped) and the **simple class name** itself:

```swoftlang
// these two declarations listen to exactly the same class
event PlayerFinishItemUse {
    execute {
        send "reeled in after ${event.use_duration} ticks" to event.player
    }
}
```

```swoftlang
event PlayerFinishItemUseEvent {
    execute {
        send "reeled in after ${event.use_duration} ticks" to event.player
    }
}
```

A misspelled name is caught at compile time, with the nearest catalog match suggested:

<!-- swoftc name=ev.sw expect=error -->

```swoftlang
event EntityDamg {
    execute {
        send "hurt" to all      // [!code error]
    }
}
```

```txt
ev.sw:1:1: error: unknown event 'EntityDamg'; did you mean 'EntityDamage'?
event EntityDamg {
^
```

## Curated typed events vs. the generated catalog

Two kinds of events live in the catalog, and they differ only in how richly their
`event.*` properties are typed.

**Curated typed events** are the core surface — the ones you reach for constantly. Their
properties carry precise SwoftLang types (a `Player`, a `Location`, an
`optional<Item>`), and most expose short **alias** bindings so you can write `player`
and `message` instead of `event.player` and `event.message`.

**Generated catalog events** — every other class in the tables below — expose their
properties as `Any`. A property is discovered from the class's record components and
`getX()`/`isX()` getters; it is writable when the class ships a matching `setX(..)`
setter (marked with `*` in the tables). `Any` values flow into `send`, interpolation,
and further property reads directly; coerce with the usual forms when you need a
concrete type.

```swoftlang
event EntityShoot {
    execute {
        // 'power' and 'spread' have setters in the catalog, so they are writable
        set event.power to 1.5
        set event.spread to 0.0
        send "line out: ${event.projectile} towards ${event.to}" to all
    }
}
```

### The curated typed events

| Event | Cancellable | Aliases | `event.*` properties |
|---|---|---|---|
| `PlayerChat` | yes | `player`, `message` | `player` (Player), `message` (String, rw), `cancelled` (rw) |
| `PlayerJoin` | — | `player`, `name` | `player` (Player), `first_spawn` (Boolean), `world` (World) |
| `PlayerUseItem` | yes | `player`, `item` | `player` (Player), `item` (Item), `custom_id` (optional&lt;String&gt;), `cancelled` (rw) |
| `MobSpawn` | — | `mob` | `mob` (Mob) |
| `MobDeath` | — | `mob`, `killer` | `mob` (Mob), `killer` (optional&lt;Player&gt;) |
| `MobDamage` | yes | `mob`, `damage` | `mob` (Mob), `damage` (Double, rw), `cancelled` (rw) |
| `BlockBreak` | yes | `player`, `block`, `location` | `player` (Player), `block` (String), `location` (Location), `cancelled` (rw) |
| `BlockPlace` | yes | `player`, `block`, `location` | `player` (Player), `block` (String), `location` (Location), `cancelled` (rw) |
| `ServerPing` | — | `motd` | `motd` (String, rw), `online` (Integer, rw), `max` (Integer, rw) |
| `TpsChange` | — | `past`, `current` | `past` (Double), `current` (Double) |
| [`PlayerCastRod`](./fishing) | yes | `player` | `player` (Player), `cancelled` (rw) |
| [`FishBite`](./fishing) | — | `player`, `hook_location` | `player` (Player), `hook_location` (Location) |
| [`PlayerCatchFish`](./fishing) | yes | `player`, `caught_item`, `caught_mob` | `player` (Player), `caught_item` (optional&lt;Item&gt;, rw), `caught_mob` (optional&lt;Mob&gt;), `cancelled` (rw) |
| [`PlayerReelIn`](./fishing) | — | `player` | `player` (Player) |
| [`BlockDispense`](./dispensers) | yes | `location`, `block`, `item`, `direction` | `location` (Location), `block` (String), `item` (optional&lt;Item&gt;, rw), `direction` (Vec), `cancelled` (rw) |

::: tip `PlayerUseItem` and the engine's `PlayerUseItemEvent`
The curated `PlayerUseItem` identifier wraps SwoftLang's **custom-items** use event — it
is what carries `event.custom_id` and drives the [`on_click`](./items#on-click) item
sugar. The raw engine event still has a spelling of its own: name
`VanillaUseItem` (the typed identifier below) to listen to Minestom's
`PlayerUseItemEvent` directly, with typed `item_stack` / `hand` / `item_use_time` rows.
:::

## Typed engine events

Between the two extremes sits a third tier: **typed engine events**. These name plain
Minestom events — `EntityDamage`, `PlayerMove`, `PickupItem` — but their `event.*`
properties carry precise SwoftLang types and real setters, hand-authored rather than
discovered from getters. So `event.damage` is a writable `Double`, `event.attacker` is
an `optional<Entity>`, `event.damage_type` is a `String` — properties the raw catalog
never exposes. They have no short aliases; reach everything through `event.<prop>`.

Naming one of these gets you the typed rows below, *not* the generated `Any` rows the
tables further down would suggest for the same class. `EntityDamage` is the one to
reach for: attack damage flows through it (the engine's `EntityAttack` is not
cancellable), so it is where you read the victim, scale the hit, inspect the source, and
veto lethal damage.

```swoftlang
event EntityDamage {
    execute {
        set event.damage to event.damage * 2.0
        send "${event.entity} took ${event.damage} (${event.damage_type})" to all
        if event.attacker exists {
            send "attacker: ${event.attacker}" to all
        }
        if event.damage > 100.0 {
            cancel event
        }
    }
}
```

### Tier 1 — the events most scripts reach for

| Event | Cancellable | `event.*` properties |
|---|---|---|
| `EntityDamage` | yes | `entity` (Entity), `damage` (Double, rw), `attacker` (optional&lt;Entity&gt;), `source_entity` (optional&lt;Entity&gt;), `damage_type` (String), `cancelled` (rw) |
| `PlayerDeath` | — | `player` (Player), `world` (World), `death_text` (String, rw), `chat_message` (String, rw) |
| `PlayerRespawn` | — | `player` (Player), `world` (World), `respawn_position` (Location, rw) |
| `PlayerMove` | yes | `player` (Player), `new_position` (Location, rw), `on_ground` (Boolean), `cancelled` (rw) |
| `PlayerBlockInteract` | yes | `player` (Player), `block` (String), `location` (Location), `block_face` (String), `hand` (String), `cursor_position` (Location), `cancelled` (rw) |
| `InventoryPreClick` | yes | `player` (Player), `slot` (Integer), `clicked_item` (Item), `cancelled` (rw) |
| `InventoryClose` | — | `player` (Player), `from_client` (Boolean) |
| `ItemDrop` | yes | `player` (Player), `item_stack` (Item), `cancelled` (rw) |
| `PickupItem` | yes | `entity` (Entity), `item_stack` (Item), `item_entity` (Entity), `cancelled` (rw) |
| `PlayerGameModeChange` | yes | `player` (Player), `new_game_mode` (String, rw), `cancelled` (rw) |
| `PlayerDisconnect` | — | `player` (Player), `world` (World) |
| `PlayerUseItemOnBlock` | — | `player` (Player), `item_stack` (Item), `location` (Location), `block_face` (String), `hand` (String), `cursor_position` (Location) |

### Tier 2 — common, fully typed

| Event | Cancellable | `event.*` properties |
|---|---|---|
| `EntityDeath` | — | `entity` (Entity), `world` (World) |
| `EntitySpawn` | — | `entity` (Entity), `world` (World) |
| `EntityAttack` | — | `entity` (Entity), `target` (Entity), `world` (World) |
| `EntityTeleport` | — | `entity` (Entity), `new_position` (Location) |
| `EntityShoot` | yes | `entity` (Entity), `projectile` (Entity), `to` (Location), `power` (Double, rw), `spread` (Double, rw), `cancelled` (rw) |
| `EntityVelocity` | yes | `entity` (Entity), `velocity` (Vec, rw), `cancelled` (rw) |
| `ProjectileCollideWithEntity` | yes | `target` (Entity), `world` (World), `cancelled` (rw) |
| `PlayerEntityInteract` | — | `player` (Player), `target` (Entity), `hand` (String), `interact_position` (Location) |
| `PlayerChangeHeldSlot` | yes | `player` (Player), `new_slot` (Integer, rw), `old_slot` (Integer), `item_in_new_slot` (Item), `item_in_old_slot` (Item), `cancelled` (rw) |
| `PickupExperience` | yes | `player` (Player), `experience_count` (Integer, rw), `cancelled` (rw) |
| `PlayerBeginItemUse` | yes | `player` (Player), `item_stack` (Item), `hand` (String), `item_use_duration` (Integer, rw), `animation` (String), `cancelled` (rw) |
| `PlayerSwapItem` | yes | `player` (Player), `main_hand_item` (Item, rw), `off_hand_item` (Item, rw), `cancelled` (rw) |
| `PlayerStartDigging` | yes | `player` (Player), `block` (String), `location` (Location), `block_face` (String), `cancelled` (rw) |
| `InventoryClick` | — | `player` (Player), `slot` (Integer), `click_type` (String), `clicked_item` (Item), `cursor_item` (Item) |
| `InventoryOpen` | yes | `player` (Player), `cancelled` (rw) |
| `PlayerLoaded` | — | `player` (Player), `world` (World) |
| `PlayerStartSprinting` · `PlayerStopSprinting` | — | `player` (Player), `world` (World) |
| `PlayerStartFlying` · `PlayerStopFlying` | — | `player` (Player), `world` (World) |
| `VanillaUseItem` | yes | `player` (Player), `item_stack` (Item), `hand` (String), `item_use_time` (Integer, rw), `cancelled` (rw) |

`VanillaUseItem` is the vanilla `PlayerUseItemEvent` under a typed identifier of its
own — the short name `PlayerUseItem` is taken by the [custom-items](./items) use event.

Writing a settable property does what you'd expect — clamp a fall, redirect a
teleport, rewrite a death message:

```swoftlang
event PlayerMove {
    execute {
        if event.on_ground {
            set event.new_position to event.player.location
        }
    }
}
```

```swoftlang
event PlayerGameModeChange {
    execute {
        send "${event.player.name} -> ${event.new_game_mode}" to event.player
    }
}
```

## Cancelling

`cancel event` is legal on exactly the events the engine marks cancellable (the
`Cancellable` column below, and `cancelled` in a curated event's rows). It is a compile
error anywhere else:

<!-- swoftc name=nc.sw expect=error -->

```swoftlang
event FishBite {
    execute {
        cancel event      // [!code error]
    }
}
```

```txt
nc.sw:3:9: error: event 'FishBite' is not cancellable
        cancel event
        ^
```

Cancellable catalog events also carry a settable `cancelled` property, so
`set event.cancelled to true` and `cancel event` are two spellings of the same effect.

## Priority and async

Every handler takes an optional `priority:` (lower runs first) and an `execute` body.
Handlers run on the tick thread by default; a whole handler can be marked
`execute async` where the work must not block a tick, following the usual
[async coloring](/guide/async) rules.

```swoftlang
event PickupItem {
    priority: 1

    execute {
        if event.cancelled {
            send "too slow, the catch is gone" to all
        }
        send "caught ${event.item_stack}" to all
    }
}
```

## The generated catalog

`*` marks a property with a setter (writable). Names are the short catalog names; the
simple class name (append `Event`) always works too. Rows here are what the compiler
*discovers* from a class's getters — an event that also appears in the
[typed engine events](#typed-engine-events) tables above resolves to those richer typed
rows instead, so consult those first. Projectile-flight events —
`EntityShoot`, `ProjectileCollideWithBlock`, `ProjectileCollideWithEntity`,
`ProjectileUncollide` — live in the `entity` group.

### Player · `player` (47)

| Event | Class spelling | Cancellable | Discovered properties |
|---|---|---|---|
| `AdvancementTab` | `AdvancementTabEvent` | — | action, entity, instance, player, tab_id |
| `AsyncPlayerConfiguration` | `AsyncPlayerConfigurationEvent` | — | entity, feature_flags, first_config, hardcore*, player, spawning_instance* |
| `AsyncPlayerPreLogin` | `AsyncPlayerPreLoginEvent` | — | connection, game_profile*, player_uuid, username* |
| `PlayerAnvilInput` | `PlayerAnvilInputEvent` | — | entity, input, instance, inventory, player |
| `PlayerBlockBreak` | `PlayerBlockBreakEvent` | yes | block, block_face, block_position, cancelled*, entity, instance, player, result_block* |
| `PlayerBlockInteract` | `PlayerBlockInteractEvent` | yes | block, block_face, block_position, blocking_item_use*, cancelled*, cursor_position, entity, hand, instance, player |
| `PlayerBlockPlace` | `PlayerBlockPlaceEvent` | yes | block*, block_face, block_position, cancelled*, cursor_position, entity, hand, instance, player |
| `PlayerCancelDigging` | `PlayerCancelDiggingEvent` | — | block, block_position, entity, instance, player |
| `PlayerChangeHeldSlot` | `PlayerChangeHeldSlotEvent` | yes | cancelled*, entity, instance, item_in_new_slot, item_in_old_slot, new_slot*, old_slot, player, slot* |
| `PlayerChat` | `PlayerChatEvent` | yes | cancelled*, entity, formatted_message*, instance, player, raw_message, recipients |
| `PlayerChunkLoad` | `PlayerChunkLoadEvent` | — | chunk_x, chunk_z, entity, instance, player |
| `PlayerChunkUnload` | `PlayerChunkUnloadEvent` | — | chunk_x, chunk_z, entity, instance, player |
| `PlayerCommand` | `PlayerCommandEvent` | yes | cancelled*, command*, entity, instance, player |
| `PlayerDeath` | `PlayerDeathEvent` | — | chat_message*, death_text*, entity, instance, player |
| `PlayerDisconnect` | `PlayerDisconnectEvent` | — | entity, instance, player |
| `PlayerEntityInteract` | `PlayerEntityInteractEvent` | — | entity, hand, instance, interact_position, player, target |
| `PlayerFinishDigging` | `PlayerFinishDiggingEvent` | — | block*, block_position, entity, instance, player |
| `PlayerGameModeChange` | `PlayerGameModeChangeEvent` | yes | cancelled*, entity, instance, new_game_mode*, player |
| `PlayerHandAnimation` | `PlayerHandAnimationEvent` | yes | cancelled*, entity, hand, instance, player |
| `PlayerLoaded` | `PlayerLoadedEvent` | — | entity, instance, player |
| `PlayerMove` | `PlayerMoveEvent` | yes | cancelled*, entity, instance, new_position*, on_ground, player |
| `PlayerPacket` | `PlayerPacketEvent` | yes | cancelled*, entity, instance, packet, player |
| `PlayerPacketOut` | `PlayerPacketOutEvent` | yes | cancelled*, entity, packet, player |
| `PlayerPickBlock` | `PlayerPickBlockEvent` | — | block, block_position, entity, include_data, instance, player |
| `PlayerPickEntity` | `PlayerPickEntityEvent` | — | entity, include_data, instance, player, target |
| `PlayerPluginMessage` | `PlayerPluginMessageEvent` | — | entity, identifier, instance, message, message_string, player |
| `PlayerPreEat` | `PlayerPreEatEvent` | yes | cancelled*, eating_time*, entity, food_item, hand, instance, item_stack, player |
| `PlayerResourcePackStatus` | `PlayerResourcePackStatusEvent` | — | entity, player, status |
| `PlayerRespawn` | `PlayerRespawnEvent` | — | entity, player, respawn_position* |
| `PlayerSettingsChange` | `PlayerSettingsChangeEvent` | — | entity, player |
| `PlayerSkinInit` | `PlayerSkinInitEvent` | — | entity, player, skin* |
| `PlayerSpawn` | `PlayerSpawnEvent` | — | entity, first_spawn, instance, player, spawn_instance |
| `PlayerSpectate` | `PlayerSpectateEvent` | — | entity, player, target |
| `PlayerStartDigging` | `PlayerStartDiggingEvent` | yes | block, block_face, block_position, cancelled*, entity, instance, player |
| `PlayerStartFlying` | `PlayerStartFlyingEvent` | — | entity, instance, player |
| `PlayerStartFlyingWithElytra` | `PlayerStartFlyingWithElytraEvent` | — | entity, instance, player |
| `PlayerStartSneaking` | `PlayerStartSneakingEvent` | — | entity, instance, player |
| `PlayerStartSprinting` | `PlayerStartSprintingEvent` | — | entity, instance, player |
| `PlayerStopFlying` | `PlayerStopFlyingEvent` | — | entity, instance, player |
| `PlayerStopFlyingWithElytra` | `PlayerStopFlyingWithElytraEvent` | — | entity, instance, player |
| `PlayerStopSneaking` | `PlayerStopSneakingEvent` | — | entity, instance, player |
| `PlayerStopSprinting` | `PlayerStopSprintingEvent` | — | entity, instance, player |
| `PlayerSwapItem` | `PlayerSwapItemEvent` | yes | cancelled*, entity, instance, main_hand_item*, off_hand_item*, player |
| `PlayerTick` | `PlayerTickEvent` | — | entity, instance, player |
| `PlayerTickEnd` | `PlayerTickEndEvent` | — | entity, instance, player |
| `PlayerUseItem` | `PlayerUseItemEvent` | yes | cancelled*, entity, hand, instance, item_stack, item_use_time*, player |
| `PlayerUseItemOnBlock` | `PlayerUseItemOnBlockEvent` | — | block_face, entity, hand, instance, item_stack, player, position |

### Entity & projectile · `entity` (17)

| Event | Class spelling | Cancellable | Discovered properties |
|---|---|---|---|
| `EntityAttack` | `EntityAttackEvent` | — | entity, instance, target |
| `EntityDamage` | `EntityDamageEvent` | yes | cancelled*, damage, entity, instance, sound* |
| `EntityDeath` | `EntityDeathEvent` | — | entity, instance |
| `EntityDespawn` | `EntityDespawnEvent` | — | entity, instance |
| `EntityFireExtinguish` | `EntityFireExtinguishEvent` | yes | cancelled*, entity, instance, natural |
| `EntityItemMerge` | `EntityItemMergeEvent` | yes | cancelled*, entity, instance, merged, result* |
| `EntityPotionAdd` | `EntityPotionAddEvent` | — | entity, instance, potion |
| `EntityPotionRemove` | `EntityPotionRemoveEvent` | — | entity, instance, potion |
| `EntitySetFire` | `EntitySetFireEvent` | yes | cancelled*, entity, fire_ticks*, instance |
| `EntityShoot` | `EntityShootEvent` | yes | cancelled*, entity, instance, power*, projectile, spread*, to |
| `EntitySpawn` | `EntitySpawnEvent` | — | entity, instance, spawn_instance |
| `EntityTeleport` | `EntityTeleportEvent` | — | entity, new_position, relative_flags, teleport_position |
| `EntityTick` | `EntityTickEvent` | — | entity, instance |
| `EntityVelocity` | `EntityVelocityEvent` | yes | cancelled*, entity, instance, velocity* |
| `ProjectileCollideWithBlock` | `ProjectileCollideWithBlockEvent` | yes | block, instance |
| `ProjectileCollideWithEntity` | `ProjectileCollideWithEntityEvent` | yes | instance, target |
| `ProjectileUncollide` | `ProjectileUncollideEvent` | — | entity, instance |

### Item · `item` (7)

| Event | Class spelling | Cancellable | Discovered properties |
|---|---|---|---|
| `EntityEquip` | `EntityEquipEvent` | — | entity, equipped_item*, instance, item_stack, slot |
| `ItemDrop` | `ItemDropEvent` | yes | cancelled*, entity, instance, item_stack, player |
| `PickupExperience` | `PickupExperienceEvent` | yes | cancelled*, entity, experience_count*, experience_orb, instance, player |
| `PickupItem` | `PickupItemEvent` | yes | cancelled*, entity, instance, item_entity, item_stack, living_entity |
| `PlayerBeginItemUse` | `PlayerBeginItemUseEvent` | yes | animation, cancelled*, entity, hand, instance, item_stack, item_use_duration*, player |
| `PlayerCancelItemUse` | `PlayerCancelItemUseEvent` | — | entity, hand, instance, item_stack, player, riptide_spin_attack*, use_duration |
| `PlayerFinishItemUse` | `PlayerFinishItemUseEvent` | — | entity, hand, instance, item_stack, player, riptide_spin_attack*, use_duration |

### Inventory · `inventory` (5)

| Event | Class spelling | Cancellable | Discovered properties |
|---|---|---|---|
| `InventoryClick` | `InventoryClickEvent` | — | click_type, clicked_item, cursor_item, entity, instance, inventory, player, slot |
| `InventoryClose` | `InventoryCloseEvent` | — | entity, from_client, instance, inventory, new_inventory*, player |
| `InventoryItemChange` | `InventoryItemChangeEvent` | — | inventory, new_item, previous_item, slot |
| `InventoryOpen` | `InventoryOpenEvent` | yes | cancelled*, entity, instance, inventory*, player |
| `InventoryPreClick` | `InventoryPreClickEvent` | yes | cancelled*, click_type, clicked_item*, cursor_item*, entity, instance, inventory, player, slot |

### Instance · `instance` (7)

| Event | Class spelling | Cancellable | Discovered properties |
|---|---|---|---|
| `AddEntityToInstance` | `AddEntityToInstanceEvent` | yes | cancelled*, entity, instance |
| `InstanceChunkLoad` | `InstanceChunkLoadEvent` | — | chunk, chunk_x, chunk_z, instance |
| `InstanceChunkUnload` | `InstanceChunkUnloadEvent` | — | chunk, chunk_x, chunk_z, instance |
| `InstanceRegister` | `InstanceRegisterEvent` | — | instance |
| `InstanceTick` | `InstanceTickEvent` | — | duration, instance |
| `InstanceUnregister` | `InstanceUnregisterEvent` | — | instance |
| `RemoveEntityFromInstance` | `RemoveEntityFromInstanceEvent` | — | entity, instance |

### Server · `server` (3)

| Event | Class spelling | Cancellable | Discovered properties |
|---|---|---|---|
| `ClientPingServer` | `ClientPingServerEvent` | yes | cancelled*, connection, delay*, payload* |
| `ServerListPing` | `ServerListPingEvent` | yes | cancelled*, connection, ping_type, response_data* |
| `ServerTickMonitor` | `ServerTickMonitorEvent` | — | tick_monitor |

### Book · `book` (1)

| Event | Class spelling | Cancellable | Discovered properties |
|---|---|---|---|
| `EditBook` | `EditBookEvent` | — | entity, instance, item_stack, pages, player, signed, title |

::: tip Every listed event is live
Name any row above in an `event { }` declaration today — the runtime registers a generic listener for its class and hands your handler the discovered properties. The four fishing events, the mob and TPS events, and `BlockDispense` sit alongside the engine catalog as first-class curated events.
:::
