(* Compile-time knowledge tables. These MUST match the Java runtime's
   PropertyRegistry (net.swofty.props) tables; the shared fixture
   test/property-table.json is generated from this module and cross-checked
   by both the OCaml test suite and the Java harness. *)

type ty =
  | TString
  | TInteger
  | TDouble
  | TBoolean
  | TPlayer
  | TLocation
  | TItem
  | TWorld
  | TMob
  | TItemTags (* the item.tags.* namespace: freeform nested NBT, optional reads *)
  | TEntityTags (* the entity/mob .tags.* namespace: freeform tags, optional reads *)
  | TTasks
    (* the per-object .tasks.* namespace (W-tasks): a first-class task registry
       that mirrors .tags but whose values are Schedule handles. Keys are
       user-chosen ids; a read yields optional<Schedule> (none if absent or
       finished). Lives on Player/Mob/Entity/Npc(this)/Hologram(this) and on the
       positioned Block value from block_at(loc). Item is intentionally excluded
       (items are value types with no stable runtime identity). *)
  | TDisplay (* text/item/block display entities (design 6B) *)
  | TRequest (* the 'request' binding inside api handlers *)
  | TReqParams (* the request.params.* namespace: path params, String reads *)
  | TSong (* NBS song metadata from song("file.nbs") *)
  | TServer (* the implicit 'server' value: tps/average_tps/mspt/motd *)
  | TWorldLoader (* anvil_loader/polar_loader/polar_storage_loader values *)
  | TSkin (* player skin: texture + signature *)
  | TCanvas (* 128x128 map canvas from map_canvas() *)
  | TSchedule (* cancelable handle from a 'schedule' expression *)
  | TEntity (* any live entity (phase 7); Mob narrows to it, keeping its rows *)
  | TBlock (* an immutable block value from block(...) / block_at(...) (W-blocks) *)
  | TVec (* an x/y/z velocity vector from velocity(x, y, z) (phase 7) *)
  | TOfflinePlayer (* a seen-store player record (phase 8); Player is a subtype *)
  | TList of ty
  | TMap of ty * ty (* map<K, V>: key type (String|Integer), value type (phase 11) *)
  | TOptional of ty
  | TEither of ty list
  | TFunction of { fn_async : bool; fn_params : ty list; fn_ret : ty }
  | TAny

let rec ty_to_string = function
  | TString -> "String"
  | TInteger -> "Integer"
  | TDouble -> "Double"
  | TBoolean -> "Boolean"
  | TPlayer -> "Player"
  | TLocation -> "Location"
  | TItem -> "Item"
  | TWorld -> "World"
  | TMob -> "Mob"
  | TItemTags -> "ItemTags"
  | TEntityTags -> "EntityTags"
  | TTasks -> "Tasks"
  | TDisplay -> "Display"
  | TRequest -> "Request"
  | TReqParams -> "RequestParams"
  | TSong -> "Song"
  | TServer -> "Server"
  | TWorldLoader -> "WorldLoader"
  | TSkin -> "Skin"
  | TCanvas -> "Canvas"
  | TSchedule -> "Schedule"
  | TEntity -> "Entity"
  | TBlock -> "Block"
  | TVec -> "Vec"
  | TOfflinePlayer -> "OfflinePlayer"
  | TList t -> "list<" ^ ty_to_string t ^ ">"
  (* String-keyed maps print as map<V> (the back-compat spelling); an
     Integer-keyed map prints its key type too (phase 11) *)
  | TMap (TString, v) -> "map<" ^ ty_to_string v ^ ">"
  | TMap (k, v) -> "map<" ^ ty_to_string k ^ ", " ^ ty_to_string v ^ ">"
  | TOptional t -> "optional<" ^ ty_to_string t ^ ">"
  | TEither ts -> "either<" ^ String.concat "|" (List.map ty_to_string ts) ^ ">"
  | TFunction { fn_async; fn_params; _ } ->
    let n = List.length fn_params in
    Printf.sprintf "%sfunction(%d param%s)"
      (if fn_async then "async " else "")
      n
      (if n = 1 then "" else "s")
  | TAny -> "Any"

type prop = {
  p_name : string;
  p_ty : ty;
  p_writable : bool;
}

let ro name ty = { p_name = name; p_ty = ty; p_writable = false }
let rw name ty = { p_name = name; p_ty = ty; p_writable = true }

(* W-pvp: entity ATTRIBUTE keys, now exposed as direct rw entity/player
   properties (like max_health): reading e.armor yields the current value,
   'set e.max_health to 40.0' sets the base value. Snake_case of the
   net.minestom.server.entity.attribute.Attributes constants (javap-verified
   against 2026.07.12-26.2); "absorption" aliases MAX_ABSORPTION (there is no
   plain ABSORPTION attribute in the jar). Single source of truth reused by the
   'add/remove modifier' statements and mirrored by Builtins.attributeFromName. *)
let combat_attribute_names =
  [
    "armor"; "armor_toughness"; "attack_damage"; "attack_knockback"; "attack_speed";
    "knockback_resistance"; "max_health"; "max_absorption"; "absorption"; "movement_speed";
    "fall_damage_multiplier"; "safe_fall_distance"; "sweeping_damage_ratio"; "flying_speed";
    "follow_range"; "jump_strength"; "scale"; "gravity"; "step_height"; "luck";
    "block_interaction_range"; "entity_interaction_range"; "explosion_knockback_resistance";
  ]

(* the attribute keys as rw Double properties, plus the native combat trackers
   as ro properties (Minestom exposes no first-class accessors for these):
   invulnerable_ticks (remaining i-frame ticks), fall_distance (blocks fallen),
   is_climbing (positional heuristic), and active_effects (the live potion-key
   list). Composed (deduped) onto Player/Mob/Entity property lookup so that
   e.armor / set e.max_health / e.fall_distance / e.active_effects resolve as
   direct properties, re-pointed at the same runtime Attribute/tracker code. *)
let combat_attribute_props = List.map (fun n -> rw n TDouble) combat_attribute_names

let combat_tracker_props =
  [
    ro "invulnerable_ticks" TInteger;
    ro "fall_distance" TDouble;
    ro "is_climbing" TBoolean;
    ro "active_effects" (TList TString);
  ]

let combat_entity_extra = combat_attribute_props @ combat_tracker_props

(* append 'extra' rows onto a base property list, dropping any whose name a base
   row already declares (the base row — e.g. the existing rw Double max_health
   or the boolean gravity — keeps priority) *)
let dedup_props base extra =
  base @ List.filter (fun p -> not (List.exists (fun q -> q.p_name = p.p_name) base)) extra

let player_props =
  [
    ro "name" TString;
    ro "uuid" TString;
    rw "health" TDouble;
    rw "max_health" TDouble;
    rw "food" TInteger;
    rw "food_saturation" TDouble;
    rw "level" TInteger;
    rw "exp" TDouble;
    rw "gamemode" TString;
    rw "location" TLocation;
    rw "world" TWorld;
    rw "held_item" TItem;
    rw "held_slot" TInteger;
    ro "latency" TInteger;
    rw "display_name" TString;
    rw "flying" TBoolean;
    rw "allow_flying" TBoolean;
    rw "flying_speed" TDouble;
    ro "online" TBoolean;
    rw "skin" TSkin;
    (* W-pvp status getters: Player is an Entity, but the checker's Player table
       does not compose entity_props, so the combat-relevant read-only status
       rows are listed here explicitly (the runtime resolves them through the
       Entity superclass walk). food/food_saturation already sit above. *)
    ro "on_ground" TBoolean;
    ro "is_sprinting" TBoolean;
    ro "alive_ticks" TInteger;
    (* freeform player tags: player.tags.<path>, same shape as entity/mob tags —
       optional<Any> reads, writable, 'set ... to none' deletes. Player is an
       Entity, so at runtime these go through the same per-entity store. *)
    ro "tags" TEntityTags;
    (* W-tasks: the per-player task registry, player.tasks.<id> — a Schedule
       handle keyed by id, auto-cancelled on disconnect *)
    ro "tasks" TTasks;
  ]

(* OfflinePlayer rows (phase 8): identity + seen-store timestamps, plus the
   'player' bridge — the live Player when online, none otherwise. Player is a
   subtype: every row here also resolves on Player values (the rows that are
   not already live Player rows compose onto the Player table). *)
let offline_player_props =
  [
    ro "name" TString;
    ro "uuid" TString;
    ro "online" TBoolean;
    ro "player" (TOptional TPlayer);
    ro "first_seen" TString;
    ro "last_seen" TString;
    ro "has_played_before" TBoolean;
  ]

(* the OfflinePlayer rows Player does not declare itself, composed onto
   Player property lookup (Player <: OfflinePlayer) *)
let offline_extra_props =
  List.filter
    (fun p -> not (List.exists (fun q -> q.p_name = p.p_name) player_props))
    offline_player_props

let location_props =
  [
    rw "x" TDouble;
    rw "y" TDouble;
    rw "z" TDouble;
    rw "yaw" TDouble;
    rw "pitch" TDouble;
    ro "block_x" TInteger;
    ro "block_y" TInteger;
    ro "block_z" TInteger;
  ]

let item_props =
  [
    rw "material" TString;
    rw "amount" TInteger;
    rw "name" TString;
    rw "lore" (TList TString);
    ro "tags" TItemTags;
  ]

let mob_props =
  [
    rw "health" TDouble;
    ro "max_health" TDouble;
    rw "name" TString;
    rw "location" TLocation;
    ro "type" TString;
    ro "custom_id" TString;
  ]

(* the general entity rows (phase 7): any live entity, spawned via 'spawn
   entity' / 'launch projectile' or listed by all_entities(). Mob is a
   subtype at runtime — mob values keep their own (typed) rows above. *)
let entity_props =
  [
    ro "type" TString;
    ro "uuid" TString;
    rw "location" TLocation;
    rw "velocity" TVec;
    rw "custom_name" TString;
    rw "name_visible" TBoolean;
    rw "glowing" TBoolean;
    rw "invisible" TBoolean;
    rw "gravity" TBoolean;
    rw "on_fire" TBoolean;
    rw "silent" TBoolean;
    (* phase 10: entity pose (EntityPose enum, snake_case names validated) and
       the sneaking convenience boolean *)
    rw "pose" TString;
    rw "sneaking" TBoolean;
    ro "passengers" (TList TEntity);
    ro "vehicle" (TOptional TEntity);
    (* projectile ownership: the launching entity for projectiles, none for
       everything else *)
    ro "shooter" (TOptional TEntity);
    ro "alive" TBoolean;
    ro "removed" TBoolean;
    (* W-pvp status getters (Entity: isOnGround/getAliveTicks/isSprinting).
       velocity above already covers entity.velocity. These feed crit checks,
       attack cooldown, and knockback math in userland .sw combat. *)
    ro "on_ground" TBoolean;
    ro "alive_ticks" TInteger;
    ro "is_sprinting" TBoolean;
    (* freeform entity tags: mob.tags.<path> / entity.tags.<path>, same shape as
       item tags — optional<Any> reads, writable, 'set ... to none' deletes *)
    ro "tags" TEntityTags;
    (* W-tasks: the per-entity task registry, entity.tags.<id> / mob.tasks.<id>
       (Mob <: Entity composes it on). An npc's on_* handlers bind `this` to the
       npc's fake-player Entity, so this.tasks.<id> is the npc scope too. Each
       task auto-cancels when the entity despawns/is removed. *)
    ro "tasks" TTasks;
  ]

(* the Entity rows a Mob does not declare itself, composed onto Mob property
   lookup (Mob <: Entity): so event.mob.uuid / set mob.gravity typecheck while
   the mob's own typed rows (health/name/...) keep priority *)
let mob_extra_props =
  List.filter
    (fun p -> not (List.exists (fun q -> q.p_name = p.p_name) mob_props))
    entity_props

(* velocity vectors (phase 7): blocks-per-tick components *)
(* W-stdlib B7: .length is the vector magnitude, .normalized the unit vector in
   the same direction (both computed, read-only) *)
let vec_props =
  [ rw "x" TDouble; rw "y" TDouble; rw "z" TDouble; ro "length" TDouble; ro "normalized" TVec ]

(* display entity rows (design 6B): text displays use text/background/
   alignment/line_width/see_through, item displays use item, block displays
   use block; the shared transform rows apply to all three. rotation and
   translation are euler-degree / block-offset triples carried as Locations
   (x/y/z used, yaw/pitch ignored). *)
let display_props =
  [
    rw "text" TString;
    rw "item" TString;
    rw "block" TString;
    rw "scale" TDouble;
    rw "translation" TLocation;
    rw "rotation" TLocation;
    rw "billboard" TString;
    rw "glow_color" TString;
    rw "background" TString;
    rw "alignment" TString;
    rw "line_width" TInteger;
    rw "see_through" TBoolean;
    rw "view_range" TDouble;
    (* W-tasks: a hologram's on_* handlers bind `this` to its text-display stack
       (a Display), so this.tasks.<id> is the hologram task scope; the task
       auto-cancels when the display/hologram is removed *)
    ro "tasks" TTasks;
  ]

(* the 'request' binding inside api handlers (design 6B) *)
let request_props =
  [
    ro "method" TString;
    ro "path" TString;
    ro "query" TString;
    ro "body" TString;
    ro "params" TReqParams;
  ]

let song_props =
  [ ro "title" TString; ro "author" TString; ro "length" TInteger; ro "speed" TDouble ]

(* the implicit 'server' value (design 6B TPS + 6D MOTD) *)
let server_props =
  [ ro "tps" TDouble; ro "average_tps" TDouble; ro "mspt" TDouble; rw "motd" TString ]

let skin_props = [ ro "texture" TString; ro "signature" TString ]
let canvas_props = [ ro "width" TInteger; ro "height" TInteger ]

(* world rows (design 6D time; phase 10 weather). weather is a writable enum
   (clear|rain|thunder, validated on literal writes); raining/thundering are
   read-only booleans derived from it. *)
let world_props =
  [
    rw "time" TInteger;
    rw "time_rate" TInteger;
    rw "weather" TString;
    ro "raining" TBoolean;
    ro "thundering" TBoolean;
  ]

(* event name -> (cancellable, wrapper properties, shortcut variable aliases) *)
type event_def = {
  e_name : string;
  e_cancellable : bool;
  e_props : prop list;
  e_aliases : (string * ty) list;
}

let events =
  [
    {
      e_name = "PlayerChat";
      e_cancellable = true;
      e_props =
        [
          ro "player" TPlayer;
          rw "message" TString;
          ro "raw_message" TString;
          ro "recipients" (TList TPlayer);
          rw "cancelled" TBoolean;
        ];
      e_aliases = [ ("player", TPlayer); ("message", TString) ];
    };
    {
      e_name = "PlayerJoin";
      e_cancellable = false;
      e_props = [ ro "player" TPlayer; ro "first_spawn" TBoolean; ro "world" TWorld ];
      e_aliases = [ ("player", TPlayer); ("name", TString) ];
    };
    {
      e_name = "PlayerUseItem";
      e_cancellable = true;
      e_props =
        [
          ro "player" TPlayer;
          ro "item" TItem;
          ro "custom_id" (TOptional TString);
          rw "cancelled" TBoolean;
        ];
      e_aliases = [ ("player", TPlayer); ("item", TItem) ];
    };
    {
      e_name = "MobSpawn";
      e_cancellable = false;
      e_props = [ ro "mob" TMob ];
      e_aliases = [ ("mob", TMob) ];
    };
    {
      e_name = "MobDeath";
      e_cancellable = false;
      e_props = [ ro "mob" TMob; ro "killer" (TOptional TPlayer) ];
      e_aliases = [ ("mob", TMob); ("killer", TOptional TPlayer) ];
    };
    {
      e_name = "MobDamage";
      e_cancellable = true;
      e_props =
        [
          ro "mob" TMob;
          rw "damage" TDouble;
          ro "attacker" (TOptional TPlayer);
          rw "cancelled" TBoolean;
        ];
      e_aliases = [ ("mob", TMob); ("damage", TDouble); ("attacker", TOptional TPlayer) ];
    };
    {
      (* fired when the integer TPS bucket changes (design 6B) *)
      e_name = "TpsChange";
      e_cancellable = false;
      e_props = [ ro "past" TDouble; ro "current" TDouble ];
      e_aliases = [ ("past", TDouble); ("current", TDouble) ];
    };
    {
      e_name = "BlockBreak";
      e_cancellable = true;
      e_props =
        [
          ro "player" TPlayer;
          ro "block" TString;
          ro "location" TLocation;
          ro "block_face" TString;
          rw "result_block" TString;
          rw "cancelled" TBoolean;
        ];
      e_aliases = [ ("player", TPlayer); ("block", TString); ("location", TLocation) ];
    };
    {
      e_name = "BlockPlace";
      e_cancellable = true;
      e_props =
        [
          ro "player" TPlayer;
          ro "block" TString;
          ro "location" TLocation;
          ro "block_face" TString;
          ro "hand" TString;
          ro "cursor_position" TLocation;
          rw "cancelled" TBoolean;
        ];
      e_aliases = [ ("player", TPlayer); ("block", TString); ("location", TLocation) ];
    };
    {
      (* dynamic MOTDs and fake player counts (design 6D) *)
      e_name = "ServerPing";
      e_cancellable = false;
      e_props = [ rw "motd" TString; rw "online" TInteger; rw "max" TInteger ];
      e_aliases = [ ("motd", TString) ];
    };
    {
      (* phase 10: command-preprocess veto. Fires on Minestom's
         PlayerCommandEvent before the command is dispatched; cancelling vetoes
         it, and 'command' is rw so handlers can rewrite what runs. *)
      e_name = "PlayerCommand";
      e_cancellable = true;
      e_props = [ ro "player" TPlayer; rw "command" TString; rw "cancelled" TBoolean ];
      e_aliases = [ ("player", TPlayer); ("command", TString) ];
    };
    (* --- phase-8: native fishing engine events (net.swofty.fishing) --- *)
    {
      e_name = "PlayerCastRod";
      e_cancellable = true;
      e_props = [ ro "player" TPlayer; rw "cancelled" TBoolean ];
      e_aliases = [ ("player", TPlayer) ];
    };
    {
      e_name = "FishBite";
      e_cancellable = false;
      e_props = [ ro "player" TPlayer; ro "hook_location" TLocation ];
      e_aliases = [ ("player", TPlayer); ("hook_location", TLocation) ];
    };
    {
      e_name = "PlayerCatchFish";
      e_cancellable = true;
      e_props =
        [
          ro "player" TPlayer;
          rw "caught_item" (TOptional TItem);
          ro "caught_mob" (TOptional TMob);
          rw "cancelled" TBoolean;
        ];
      e_aliases =
        [ ("player", TPlayer); ("caught_item", TOptional TItem); ("caught_mob", TOptional TMob) ];
    };
    {
      e_name = "PlayerReelIn";
      e_cancellable = false;
      e_props = [ ro "player" TPlayer ];
      e_aliases = [ ("player", TPlayer) ];
    };
    (* --- phase-9: dispenser runtime (net.swofty.blocks) — fires before a
       dispenser/dropper pops an item; 'item' is rw so handlers can swap what
       comes out (none while the block is empty), cancel = nothing moves *)
    {
      e_name = "BlockDispense";
      e_cancellable = true;
      e_props =
        [
          ro "location" TLocation;
          ro "block" TString;
          rw "item" (TOptional TItem);
          ro "direction" TVec;
          rw "cancelled" TBoolean;
        ];
      e_aliases =
        [
          ("location", TLocation);
          ("block", TString);
          ("item", TOptional TItem);
          ("direction", TVec);
        ];
    };
    (* --- W-events: typed engine event catalog (design A1/A2). These wrap
       concrete Minestom events on the GENERIC runtime path (GenericSwoftEvent +
       EventPropertyResolver, NOT an EventType wrapper): each property is a
       catalog getter whose Java type is promoted by ty_of_java_type, a synthetic
       accessor (EntityDamage's Damage unwrap: damage/attacker/source_entity/
       damage_type), or a friendly runtime alias (world<-instance, location<-
       block_position/position). e_aliases stays empty — the generic wrapper
       binds only `event`, so every value is reached through event.<prop>.
       'cancelled' is rw exactly on cancellable events. --- *)
    (* A1 — tier-1 typed events (90% of scripts) *)
    {
      e_name = "EntityDamage";
      e_cancellable = true;
      e_props =
        [
          ro "entity" TEntity;
          rw "damage" TDouble;
          ro "attacker" (TOptional TEntity);
          ro "source_entity" (TOptional TEntity);
          ro "damage_type" TString;
          rw "cancelled" TBoolean;
        ];
      e_aliases = [];
    };
    {
      e_name = "PlayerDeath";
      e_cancellable = false;
      e_props =
        [
          ro "player" TPlayer;
          ro "world" TWorld;
          rw "death_text" TString;
          rw "chat_message" TString;
        ];
      e_aliases = [];
    };
    {
      e_name = "PlayerRespawn";
      e_cancellable = false;
      e_props = [ ro "player" TPlayer; ro "world" TWorld; rw "respawn_position" TLocation ];
      e_aliases = [];
    };
    {
      e_name = "PlayerMove";
      e_cancellable = true;
      e_props =
        [
          ro "player" TPlayer;
          rw "new_position" TLocation;
          ro "on_ground" TBoolean;
          rw "cancelled" TBoolean;
        ];
      e_aliases = [];
    };
    {
      e_name = "PlayerBlockInteract";
      e_cancellable = true;
      e_props =
        [
          ro "player" TPlayer;
          ro "block" TString;
          ro "location" TLocation;
          ro "block_face" TString;
          ro "hand" TString;
          ro "cursor_position" TLocation;
          rw "cancelled" TBoolean;
        ];
      e_aliases = [];
    };
    {
      e_name = "InventoryPreClick";
      e_cancellable = true;
      e_props =
        [ ro "player" TPlayer; ro "slot" TInteger; ro "clicked_item" TItem; rw "cancelled" TBoolean ];
      e_aliases = [];
    };
    {
      e_name = "InventoryClose";
      e_cancellable = false;
      e_props = [ ro "player" TPlayer; ro "from_client" TBoolean ];
      e_aliases = [];
    };
    {
      e_name = "ItemDrop";
      e_cancellable = true;
      e_props = [ ro "player" TPlayer; ro "item_stack" TItem; rw "cancelled" TBoolean ];
      e_aliases = [];
    };
    {
      e_name = "PickupItem";
      e_cancellable = true;
      e_props =
        [
          ro "entity" TEntity;
          ro "item_stack" TItem;
          ro "item_entity" TEntity;
          rw "cancelled" TBoolean;
        ];
      e_aliases = [];
    };
    {
      e_name = "PlayerGameModeChange";
      e_cancellable = true;
      e_props = [ ro "player" TPlayer; rw "new_game_mode" TString; rw "cancelled" TBoolean ];
      e_aliases = [];
    };
    {
      e_name = "PlayerDisconnect";
      e_cancellable = false;
      e_props = [ ro "player" TPlayer; ro "world" TWorld ];
      e_aliases = [];
    };
    {
      e_name = "PlayerUseItemOnBlock";
      e_cancellable = false;
      e_props =
        [
          ro "player" TPlayer;
          ro "item_stack" TItem;
          ro "location" TLocation;
          ro "block_face" TString;
          ro "hand" TString;
          ro "cursor_position" TLocation;
        ];
      e_aliases = [];
    };
    (* A2 — tier-2 typed events (common) *)
    {
      e_name = "EntityDeath";
      e_cancellable = false;
      e_props = [ ro "entity" TEntity; ro "world" TWorld ];
      e_aliases = [];
    };
    {
      e_name = "EntitySpawn";
      e_cancellable = false;
      e_props = [ ro "entity" TEntity; ro "world" TWorld ];
      e_aliases = [];
    };
    {
      e_name = "EntityAttack";
      e_cancellable = false;
      e_props = [ ro "entity" TEntity; ro "target" TEntity; ro "world" TWorld ];
      e_aliases = [];
    };
    {
      e_name = "EntityTeleport";
      e_cancellable = false;
      e_props = [ ro "entity" TEntity; ro "new_position" TLocation ];
      e_aliases = [];
    };
    {
      e_name = "EntityShoot";
      e_cancellable = true;
      e_props =
        [
          ro "entity" TEntity;
          ro "projectile" TEntity;
          ro "to" TLocation;
          rw "power" TDouble;
          rw "spread" TDouble;
          rw "cancelled" TBoolean;
        ];
      e_aliases = [];
    };
    {
      e_name = "EntityVelocity";
      e_cancellable = true;
      e_props = [ ro "entity" TEntity; rw "velocity" TVec; rw "cancelled" TBoolean ];
      e_aliases = [];
    };
    {
      e_name = "ProjectileCollideWithEntity";
      e_cancellable = true;
      e_props = [ ro "target" TEntity; ro "world" TWorld; rw "cancelled" TBoolean ];
      e_aliases = [];
    };
    {
      e_name = "PlayerEntityInteract";
      e_cancellable = false;
      e_props =
        [
          ro "player" TPlayer;
          ro "target" TEntity;
          ro "hand" TString;
          ro "interact_position" TLocation;
        ];
      e_aliases = [];
    };
    {
      e_name = "PlayerChangeHeldSlot";
      e_cancellable = true;
      e_props =
        [
          ro "player" TPlayer;
          rw "new_slot" TInteger;
          ro "old_slot" TInteger;
          ro "item_in_new_slot" TItem;
          ro "item_in_old_slot" TItem;
          rw "cancelled" TBoolean;
        ];
      e_aliases = [];
    };
    {
      e_name = "PickupExperience";
      e_cancellable = true;
      e_props = [ ro "player" TPlayer; rw "experience_count" TInteger; rw "cancelled" TBoolean ];
      e_aliases = [];
    };
    {
      e_name = "PlayerBeginItemUse";
      e_cancellable = true;
      e_props =
        [
          ro "player" TPlayer;
          ro "item_stack" TItem;
          ro "hand" TString;
          rw "item_use_duration" TInteger;
          ro "animation" TString;
          rw "cancelled" TBoolean;
        ];
      e_aliases = [];
    };
    {
      e_name = "PlayerSwapItem";
      e_cancellable = true;
      e_props =
        [
          ro "player" TPlayer;
          rw "main_hand_item" TItem;
          rw "off_hand_item" TItem;
          rw "cancelled" TBoolean;
        ];
      e_aliases = [];
    };
    {
      e_name = "PlayerStartDigging";
      e_cancellable = true;
      e_props =
        [
          ro "player" TPlayer;
          ro "block" TString;
          ro "location" TLocation;
          ro "block_face" TString;
          rw "cancelled" TBoolean;
        ];
      e_aliases = [];
    };
    {
      e_name = "InventoryClick";
      e_cancellable = false;
      e_props =
        [
          ro "player" TPlayer;
          ro "slot" TInteger;
          ro "click_type" TString;
          ro "clicked_item" TItem;
          ro "cursor_item" TItem;
        ];
      e_aliases = [];
    };
    {
      e_name = "InventoryOpen";
      e_cancellable = true;
      e_props = [ ro "player" TPlayer; rw "cancelled" TBoolean ];
      e_aliases = [];
    };
    {
      e_name = "PlayerLoaded";
      e_cancellable = false;
      e_props = [ ro "player" TPlayer; ro "world" TWorld ];
      e_aliases = [];
    };
    {
      e_name = "PlayerStartSprinting";
      e_cancellable = false;
      e_props = [ ro "player" TPlayer; ro "world" TWorld ];
      e_aliases = [];
    };
    {
      e_name = "PlayerStopSprinting";
      e_cancellable = false;
      e_props = [ ro "player" TPlayer; ro "world" TWorld ];
      e_aliases = [];
    };
    {
      e_name = "PlayerStartFlying";
      e_cancellable = false;
      e_props = [ ro "player" TPlayer; ro "world" TWorld ];
      e_aliases = [];
    };
    {
      e_name = "PlayerStopFlying";
      e_cancellable = false;
      e_props = [ ro "player" TPlayer; ro "world" TWorld ];
      e_aliases = [];
    };
    (* A3 — the engine PlayerUseItemEvent typed under a distinct identifier (the
       catalog short 'PlayerUseItem' names the custom-items curated event). It is
       NOT an EventType wrapper, so it canonicalizes to the simple class name and
       the runtime resolves it generically via EventCatalog.resolve. *)
    {
      e_name = "VanillaUseItem";
      e_cancellable = true;
      e_props =
        [
          ro "player" TPlayer;
          ro "item_stack" TItem;
          ro "hand" TString;
          rw "item_use_time" TInteger;
          rw "cancelled" TBoolean;
        ];
      e_aliases = [];
    };
  ]

let find_curated name = List.find_opt (fun e -> e.e_name = name) events

(* curated identifier -> the concrete class its runtime wrapper listens to
   (mirrors EventType.MINESTOM_CLASS_MAP in EventType.java). A generated
   catalog hit may only collapse to the curated typed rows when the curated
   wrapper covers the SAME class; 'PlayerUseItem' wraps the custom-items
   event PlayerUseCustomItemEvent, NOT the engine PlayerUseItemEvent, so the
   engine event stays reachable through its class spelling. *)
let curated_event_class =
  [
    ("PlayerChat", "net.minestom.server.event.player.PlayerChatEvent");
    ("PlayerJoin", "net.minestom.server.event.player.PlayerSpawnEvent");
    ("PlayerUseItem", "net.swofty.items.event.PlayerUseCustomItemEvent");
    ("MobSpawn", "net.swofty.mobs.event.MobSpawnEvent");
    ("MobDeath", "net.swofty.mobs.event.MobDeathEvent");
    ("MobDamage", "net.swofty.mobs.event.MobDamageEvent");
    ("TpsChange", "net.swofty.tps.TpsChangeEvent");
    ("BlockBreak", "net.minestom.server.event.player.PlayerBlockBreakEvent");
    ("BlockPlace", "net.minestom.server.event.player.PlayerBlockPlaceEvent");
    ("ServerPing", "net.minestom.server.event.server.ServerListPingEvent");
    ("PlayerCommand", "net.minestom.server.event.player.PlayerCommandEvent");
    ("PlayerCastRod", "net.swofty.fishing.event.PlayerCastRodEvent");
    ("FishBite", "net.swofty.fishing.event.FishBiteEvent");
    ("PlayerCatchFish", "net.swofty.fishing.event.PlayerCatchFishEvent");
    ("PlayerReelIn", "net.swofty.fishing.event.PlayerReelInEvent");
    ("BlockDispense", "net.swofty.blocks.event.BlockDispenseEvent");
    (* --- W-events: typed engine catalog (design A1/A2). All engine classes; no
       EventType wrapper, so they resolve on the generic runtime path. --- *)
    ("EntityDamage", "net.minestom.server.event.entity.EntityDamageEvent");
    ("PlayerDeath", "net.minestom.server.event.player.PlayerDeathEvent");
    ("PlayerRespawn", "net.minestom.server.event.player.PlayerRespawnEvent");
    ("PlayerMove", "net.minestom.server.event.player.PlayerMoveEvent");
    ("PlayerBlockInteract", "net.minestom.server.event.player.PlayerBlockInteractEvent");
    ("InventoryPreClick", "net.minestom.server.event.inventory.InventoryPreClickEvent");
    ("InventoryClose", "net.minestom.server.event.inventory.InventoryCloseEvent");
    ("ItemDrop", "net.minestom.server.event.item.ItemDropEvent");
    ("PickupItem", "net.minestom.server.event.item.PickupItemEvent");
    ("PlayerGameModeChange", "net.minestom.server.event.player.PlayerGameModeChangeEvent");
    ("PlayerDisconnect", "net.minestom.server.event.player.PlayerDisconnectEvent");
    ("PlayerUseItemOnBlock", "net.minestom.server.event.player.PlayerUseItemOnBlockEvent");
    ("EntityDeath", "net.minestom.server.event.entity.EntityDeathEvent");
    ("EntitySpawn", "net.minestom.server.event.entity.EntitySpawnEvent");
    ("EntityAttack", "net.minestom.server.event.entity.EntityAttackEvent");
    ("EntityTeleport", "net.minestom.server.event.entity.EntityTeleportEvent");
    ("EntityShoot", "net.minestom.server.event.entity.EntityShootEvent");
    ("EntityVelocity", "net.minestom.server.event.entity.EntityVelocityEvent");
    ( "ProjectileCollideWithEntity",
      "net.minestom.server.event.entity.projectile.ProjectileCollideWithEntityEvent" );
    ("PlayerEntityInteract", "net.minestom.server.event.player.PlayerEntityInteractEvent");
    ("PlayerChangeHeldSlot", "net.minestom.server.event.player.PlayerChangeHeldSlotEvent");
    ("PickupExperience", "net.minestom.server.event.item.PickupExperienceEvent");
    ("PlayerBeginItemUse", "net.minestom.server.event.item.PlayerBeginItemUseEvent");
    ("PlayerSwapItem", "net.minestom.server.event.player.PlayerSwapItemEvent");
    ("PlayerStartDigging", "net.minestom.server.event.player.PlayerStartDiggingEvent");
    ("InventoryClick", "net.minestom.server.event.inventory.InventoryClickEvent");
    ("InventoryOpen", "net.minestom.server.event.inventory.InventoryOpenEvent");
    ("PlayerLoaded", "net.minestom.server.event.player.PlayerLoadedEvent");
    ("PlayerStartSprinting", "net.minestom.server.event.player.PlayerStartSprintingEvent");
    ("PlayerStopSprinting", "net.minestom.server.event.player.PlayerStopSprintingEvent");
    ("PlayerStartFlying", "net.minestom.server.event.player.PlayerStartFlyingEvent");
    ("PlayerStopFlying", "net.minestom.server.event.player.PlayerStopFlyingEvent");
    (* A3: engine PlayerUseItemEvent under a distinct identifier (custom-items
       'PlayerUseItem' shadows the catalog short name) *)
    ("VanillaUseItem", "net.minestom.server.event.player.PlayerUseItemEvent");
  ]

let curated_covers_class name cls =
  match List.assoc_opt name curated_event_class with
  | Some curated_cls -> curated_cls = cls
  | None -> false

(* A0.1: reverse index concrete-class -> the curated e_name whose runtime
   wrapper listens to it. Built from curated_event_class, keeping only entries
   that name a real curated event. This lets EVERY spelling of one class — the
   catalog short name, the simple class name, AND the (possibly renamed)
   curated alias — collapse to the same typed rows. Without it, a curated event
   that renamed its identifier (PlayerSpawnEvent -> "PlayerJoin",
   PlayerBlockBreakEvent -> "BlockBreak", PlayerBlockPlaceEvent -> "BlockPlace",
   ServerListPingEvent -> "ServerPing") was only typed under the alias, and the
   catalog/class spellings fell through to generic Any rows.

   Only classes a curated wrapper actually covers are mapped: 'PlayerUseItem'
   wraps the CUSTOM PlayerUseCustomItemEvent, so the engine PlayerUseItemEvent
   class is absent here and keeps its generic rows (name-collision safe). *)
let curated_class_index =
  List.filter_map
    (fun (name, cls) -> match find_curated name with Some _ -> Some (cls, name) | None -> None)
    curated_event_class

let curated_for_class cls = List.assoc_opt cls curated_class_index

(* --- phase-7: the full generated Minestom event catalog --- *)

(* Events_data (generated from data/events.json, pinned Minestom ebaa2bbf64)
   lists every concrete public event class. Handlers may name any of them by
   catalog short name ("EntityShoot") or simple class name
   ("EntityShootEvent"). The curated typed rows above KEEP priority; every
   other catalog event gets Any-typed rows whose writability comes from the
   catalog's setter scan, and cancellability comes from the catalog. *)

let simple_class_name cls =
  let cut c s =
    match String.rindex_opt s c with
    | Some i -> String.sub s (i + 1) (String.length s - i - 1)
    | None -> s
  in
  cut '$' (cut '.' cls)

let find_generated name =
  List.find_opt
    (fun (g : Events_data.gen_event) ->
      g.Events_data.ev_short = name || simple_class_name g.Events_data.ev_class = name)
    Events_data.generated_events

let generic_event_def (g : Events_data.gen_event) =
  {
    e_name = g.Events_data.ev_short;
    e_cancellable = g.Events_data.ev_cancellable;
    e_props =
      List.map
        (fun (gp : Events_data.gen_event_prop) ->
          { p_name = gp.Events_data.p_name; p_ty = TAny; p_writable = gp.Events_data.p_settable })
        g.Events_data.ev_props;
    e_aliases = [];
  }

(* A0.2: Java-type -> SwoftLang ty promotion table.

   Maps a catalog property's javaType (the generic Java return type recorded in
   events_data.ml) to the ty it should surface as. This is the single table
   event typing is built on: an event-typing overlay names which catalog
   properties an event exposes (and their role names), and this function
   supplies each one's ty. [None] means "no first-class SwoftLang type" — leave
   the row TAny (AbstractInventory/Inventory/Click, raw collections, ...).

   Notes matching the runtime (A0.3/A0.4):
   - Block ids and enum-like Minestom types (GameMode/PlayerHand/BlockFace/
     ClickType/ItemAnimation/SoundEvent) surface as TString; the runtime
     normalizes an enum to its lowercase name on read and matches
     case-insensitively on write.
   - Component surfaces as TString (MiniMessage), reusing the PlayerChat
     Component<->String bridge.
   - Pos/Point/BlockVec all surface as TLocation (Point has yaw/pitch 0).
   - Damage surfaces as TDouble via the runtime Damage-unwrap accessor
     (getAmount/setAmount); the raw getDamage() object is never exposed. *)
let ty_of_java_type (java_type : string) : ty option =
  (* strip any generic parameters: "java.util.Collection<...>" -> the raw class *)
  let base =
    match String.index_opt java_type '<' with
    | Some i -> String.sub java_type 0 i
    | None -> java_type
  in
  match base with
  | "net.minestom.server.entity.Player" -> Some TPlayer
  | "net.minestom.server.entity.Entity" | "net.minestom.server.entity.LivingEntity"
  | "net.minestom.server.entity.ItemEntity" | "net.minestom.server.entity.ExperienceOrb" ->
    Some TEntity
  | "net.minestom.server.item.ItemStack" -> Some TItem
  | "net.minestom.server.instance.block.Block" -> Some TString
  | "net.minestom.server.coordinate.Pos" | "net.minestom.server.coordinate.Point"
  | "net.minestom.server.coordinate.BlockVec" ->
    Some TLocation
  | "net.minestom.server.coordinate.Vec" -> Some TVec
  | "net.minestom.server.instance.Instance" -> Some TWorld
  | "net.kyori.adventure.text.Component" -> Some TString
  | "java.lang.String" -> Some TString
  | "boolean" | "java.lang.Boolean" -> Some TBoolean
  | "int" | "byte" | "short" | "long" | "java.lang.Integer" | "java.lang.Byte"
  | "java.lang.Short" | "java.lang.Long" ->
    Some TInteger
  | "double" | "float" | "java.lang.Double" | "java.lang.Float" -> Some TDouble
  | "net.minestom.server.entity.GameMode" | "net.minestom.server.entity.PlayerHand"
  | "net.minestom.server.instance.block.BlockFace"
  | "net.minestom.server.inventory.click.ClickType" | "net.minestom.server.item.ItemAnimation"
  | "net.minestom.server.sound.SoundEvent" ->
    Some TString
  | "net.minestom.server.entity.damage.Damage" -> Some TDouble
  | _ -> None

let find_event name =
  match find_curated name with
  | Some e -> Some e
  | None -> (
    match find_generated name with
    | None -> None
    | Some g -> (
      (* every spelling of a catalog class collapses to the curated typed rows
         whenever a curated wrapper covers that exact class — even when the
         curated identifier was renamed (PlayerSpawnEvent -> "PlayerJoin"). A
         curated identifier that only SHADOWS an unrelated catalog event
         ('PlayerUseItem' wraps the custom PlayerUseCustomItemEvent, not the
         engine PlayerUseItemEvent) does not map the engine class, so that
         event keeps its generic Any rows. *)
      match curated_for_class g.Events_data.ev_class with
      | Some cname -> find_curated cname
      | None -> Some (generic_event_def g)))

(* the emitted AST (and so the runtime registry) uses the canonical short
   catalog name whichever spelling the script used. When the short catalog
   name is shadowed by a curated identifier wrapping a DIFFERENT class, emit
   the simple class name instead: EventType.fromIdentifier misses it, so the
   runtime resolves it generically to the genuine engine event. *)
(* Curated identifiers that are NOT EventType wrappers and whose e_name is not a
   catalog spelling the runtime can resolve: emit a name EventCatalog.resolve can
   map to the engine class instead. VanillaUseItem -> the simple class name
   PlayerUseItemEvent (the catalog short 'PlayerUseItem' is taken by the custom
   curated event, so it cannot be emitted for the engine event). *)
let curated_emit_override = [ ("VanillaUseItem", "PlayerUseItemEvent") ]

let emit_name_for cname =
  match List.assoc_opt cname curated_emit_override with Some emit -> emit | None -> cname

let canonical_event_name name =
  if find_curated name <> None then emit_name_for name
  else
    match find_generated name with
    | None -> name
    | Some g -> (
      match curated_for_class g.Events_data.ev_class with
      | Some cname ->
        (* the runtime binds the curated wrapper by this identifier
           (EventType.fromIdentifier / EventCatalog.resolve); emit it whatever
           spelling was written *)
        emit_name_for cname
      | None ->
        (* class covered by no curated wrapper. When the catalog short name is
           shadowed by a curated identifier that wraps a DIFFERENT class, emit
           the simple class name so EventType.fromIdentifier misses it and the
           runtime resolves the genuine engine event generically. *)
        if find_curated g.Events_data.ev_short <> None then
          simple_class_name g.Events_data.ev_class
        else g.Events_data.ev_short)

(* every name an 'event' declaration accepts, for unknown-event suggestions *)
let all_event_names =
  List.map (fun e -> e.e_name) events
  @ List.concat_map
      (fun (g : Events_data.gen_event) ->
        let short = g.Events_data.ev_short in
        let simple = simple_class_name g.Events_data.ev_class in
        if List.exists (fun e -> e.e_name = short) events then [ simple ]
        else [ short; simple ])
      Events_data.generated_events

(* W-collections: zero-arg accessors on lists/maps/strings use property form
   (no parens), reusing the ordinary prop-access machinery. list<T>: size /
   is_empty + first/last (optional<T>). map<K,V>: size / is_empty + keys
   (list<K>) / values (list<V>). String: length. Everything that TAKES an
   argument is a method (see the method tables below). *)
let list_props elem =
  [
    ro "size" TInteger;
    ro "is_empty" TBoolean;
    ro "first" (TOptional elem);
    ro "last" (TOptional elem);
  ]

let map_props k v =
  [ ro "size" TInteger; ro "is_empty" TBoolean; ro "keys" (TList k); ro "values" (TList v) ]

let string_props = [ ro "length" TInteger ]

(* --- W-blocks: block-state schema, loaded from the embedded
   data/block_states.json (generated offline from the pinned Minestom jar).
   Shape: { "blocks": { "<namespaced id>": { "<prop>": ["<value>", ...] } },
   "block_entity_ids": { ... }, "block_entity_types": [ ... ] }. --- *)

let block_states : (string, (string * string list) list) Hashtbl.t = Hashtbl.create 2048
let block_entity_ids : (string, string) Hashtbl.t = Hashtbl.create 256

let () =
  match Yojson.Safe.from_string Block_states_data.json with
  | exception _ -> ()
  | `Assoc top ->
    (match List.assoc_opt "blocks" top with
    | Some (`Assoc blocks) ->
      List.iter
        (fun (bid, props) ->
          match props with
          | `Assoc plist ->
            let ps =
              List.map
                (fun (pname, vals) ->
                  let vlist =
                    match vals with
                    | `List vs ->
                      List.filter_map (function `String s -> Some s | _ -> None) vs
                    | _ -> []
                  in
                  (pname, vlist))
                plist
            in
            Hashtbl.replace block_states bid ps
          | _ -> ())
        blocks
    | _ -> ());
    (match List.assoc_opt "block_entity_ids" top with
    | Some (`Assoc bes) ->
      List.iter
        (fun (bid, v) -> match v with `String s -> Hashtbl.replace block_entity_ids bid s | _ -> ())
        bes
    | _ -> ())
  | _ -> ()

(* "oak_stairs", "OAK_STAIRS", and "minecraft:oak_stairs" all name the same
   block; the schema keys are lowercase namespaced ids, default namespace
   minecraft. *)
let normalize_block_id s =
  let s = String.lowercase_ascii s in
  if String.contains s ':' then s else "minecraft:" ^ s

let block_known id = Hashtbl.mem block_states (normalize_block_id id)

let block_prop_names id =
  match Hashtbl.find_opt block_states (normalize_block_id id) with
  | Some ps -> List.map fst ps
  | None -> []

let block_prop_values id prop =
  match Hashtbl.find_opt block_states (normalize_block_id id) with
  | Some ps -> ( match List.assoc_opt prop ps with Some vs -> vs | None -> [])
  | None -> []

(* short (namespace-stripped) ids for unknown-block suggestions *)
let block_id_suggestions () =
  Hashtbl.fold
    (fun k _ acc ->
      let short =
        match String.index_opt k ':' with
        | Some i -> String.sub k (i + 1) (String.length k - i - 1)
        | None -> k
      in
      short :: acc)
    block_states []

(* --- Packet catalog: the `Packet { on "Class" { } }` receiver.
   Loaded from the embedded data/packets.json (generated by
   data/GenMinestomCatalogs.java from the pinned Minestom jar). Shape:
   { "<fully.qualified.PacketClass>": { "simple_name": "...", "direction": "...",
     "fields": [ { "name": "...", "accessor": "...", "javaType": "...",
                   "ty": "TString" }, ... ] }, ... }.
   Each field's "ty" is one of the Registry ty-constructor spellings; we map it
   back to the ty algebra so `packet.<field>` typechecks to the real field type.
   The catalog also carries a non-packet "_meta" entry (no "fields"); it is
   skipped. --- *)

(* map a catalog "ty" string (a ty_to_string-ish spelling emitted by the Java
   generator) back to the ty algebra; anything unrecognized degrades to TAny so
   an opaque field still reads without crashing the loader *)
let ty_of_catalog_string = function
  | "TString" -> TString
  | "TInteger" -> TInteger
  | "TDouble" -> TDouble
  | "TBoolean" -> TBoolean
  | "TItem" -> TItem
  | "TLocation" -> TLocation
  | "TVec" -> TVec
  | "TPlayer" -> TPlayer
  | "TEntity" -> TEntity
  | "TMob" -> TMob
  | "TBlock" -> TBlock
  | "TWorld" -> TWorld
  | _ -> TAny

(* FQ class name -> its fields, exposed as read-only props (packet fields are
   inbound values, never assignable) *)
let packet_fields_tbl : (string, prop list) Hashtbl.t = Hashtbl.create 256

(* simple class name -> FQ class name, so `on "ClientChatMessagePacket"` resolves
   the bare spelling; fully-qualified names hit packet_fields_tbl directly *)
let packet_simple_to_fq : (string, string) Hashtbl.t = Hashtbl.create 256

(* FQ class name -> "client" (inbound, listenable) | "server" (outbound). A
   `Packet { on "..." }` block can only listen to CLIENT packets, mirroring the
   runtime PacketSender.resolveClient, so this lets the typechecker reject an
   outbound server packet the same way the runtime would. *)
let packet_direction_tbl : (string, string) Hashtbl.t = Hashtbl.create 256

let () =
  match Yojson.Safe.from_string Packets_data.json with
  | exception _ -> ()
  | `Assoc entries ->
    List.iter
      (fun (fq, v) ->
        match v with
        | `Assoc kv -> (
          match List.assoc_opt "fields" kv with
          | Some (`List fields) ->
            let props =
              List.filter_map
                (fun f ->
                  match f with
                  | `Assoc ff -> (
                    match List.assoc_opt "name" ff with
                    | Some (`String nm) ->
                      let ty =
                        match List.assoc_opt "ty" ff with
                        | Some (`String ts) -> ty_of_catalog_string ts
                        | _ -> TAny
                      in
                      Some (ro nm ty)
                    | _ -> None)
                  | _ -> None)
                fields
            in
            Hashtbl.replace packet_fields_tbl fq props;
            (match List.assoc_opt "simple_name" kv with
            | Some (`String sn) -> Hashtbl.replace packet_simple_to_fq sn fq
            | _ -> ());
            (match List.assoc_opt "direction" kv with
            | Some (`String dir) -> Hashtbl.replace packet_direction_tbl fq dir
            | _ -> ())
          (* entries without a "fields" array (e.g. the "_meta" header) are not
             packet classes; skip them *)
          | _ -> ())
        | _ -> ())
      entries
  | _ -> ()

(* resolve a `on "..."` class name to its FQ catalog key. Accepts either the
   bare simple name (ClientChatMessagePacket) or the fully-qualified name
   (net.minestom.server...ClientChatMessagePacket). None if unknown. *)
let resolve_packet_class name =
  if Hashtbl.mem packet_fields_tbl name then Some name
  else Hashtbl.find_opt packet_simple_to_fq name

(* the typed field props of a resolved (FQ) packet class *)
let packet_fields fq =
  match Hashtbl.find_opt packet_fields_tbl fq with Some ps -> ps | None -> []

(* "client" (inbound) | "server" (outbound) for a resolved FQ packet class *)
let packet_direction fq = Hashtbl.find_opt packet_direction_tbl fq

(* every known packet's simple name, for unknown-class suggestions *)
let packet_class_names () = Hashtbl.fold (fun sn _ acc -> sn :: acc) packet_simple_to_fq []

(* only the inbound (client) packet simple names — the ones an `on "..."` block
   can actually listen to, so unknown-class suggestions never point at an
   unusable outbound server packet *)
let client_packet_class_names () =
  Hashtbl.fold
    (fun sn fq acc ->
      match Hashtbl.find_opt packet_direction_tbl fq with
      | Some "client" -> sn :: acc
      | _ -> acc)
    packet_simple_to_fq []

(* zero-arg accessors on a Block value (method form is the with/property/nbt/tag
   family in Tc_expr) *)
let block_props =
  [
    ro "id" TString;
    ro "properties" (TMap (TString, TString));
    ro "nbt" (TOptional TString);
    (* W-tasks: block_at(loc) returns a Block that remembers its position, so
       block_at(loc).tasks.<id> keys the task registry by that position; the
       task auto-cancels when the block is removed/replaced *)
    ro "tasks" TTasks;
  ]

let props_of_ty = function
  | TString -> Some string_props
  | TBlock -> Some block_props
  | TList elem -> Some (list_props elem)
  | TMap (k, v) -> Some (map_props k v)
  (* Player <: OfflinePlayer (phase 8): the OfflinePlayer-only rows compose
     onto Player values *)
  | TPlayer -> Some (dedup_props (player_props @ offline_extra_props) combat_entity_extra)
  | TOfflinePlayer -> Some offline_player_props
  | TLocation -> Some location_props
  | TItem -> Some item_props
  (* Mob <: Entity (phase 7): the Entity-only rows compose onto Mob values *)
  | TMob -> Some (dedup_props (mob_props @ mob_extra_props) combat_entity_extra)
  | TItemTags -> Some []
  | TEntityTags -> Some []
  | TTasks -> Some []
  | TWorld -> Some world_props
  | TDisplay -> Some display_props
  | TRequest -> Some request_props
  | TReqParams -> Some []
  | TSong -> Some song_props
  | TServer -> Some server_props
  | TSkin -> Some skin_props
  | TCanvas -> Some canvas_props
  | TWorldLoader -> Some []
  | TSchedule -> Some []
  | TEntity -> Some (dedup_props entity_props combat_entity_extra)
  | TVec -> Some vec_props
  | _ -> None

let find_prop owner name =
  (* item.tags.<key> is a freeform NBT namespace: any key resolves, writable;
     reads are optional<Any> — an absent tag is none (phase 9), so the no-null
     discipline (exists/otherwise) extends to NBT *)
  if owner = TItemTags || owner = TEntityTags then
    Some { p_name = name; p_ty = TOptional TAny; p_writable = true }
  else if owner = TTasks then
    (* W-tasks: <obj>.tasks.<id> — any id resolves; a read yields
       optional<Schedule> (none if absent or finished). Writes go through the
       dedicated task_set node, not the generic prop path. *)
    Some { p_name = name; p_ty = TOptional TSchedule; p_writable = true }
  else if owner = TReqParams then
    (* request.params.<key>: path params resolve by name, String reads *)
    Some { p_name = name; p_ty = TString; p_writable = false }
  else
    match props_of_ty owner with
    | None -> None
    | Some props -> List.find_opt (fun p -> p.p_name = name) props

(* a freeform tag namespace (item tags or entity/mob tags): any key resolves,
   reads are optional<Any>, and 'set ... to none' deletes *)
let is_tags_ty = function TItemTags | TEntityTags -> true | _ -> false

(* W-tasks: the per-object task namespace (obj.tasks.<id>): any id resolves,
   reads are optional<Schedule> *)
let is_tasks_ty = function TTasks -> true | _ -> false

(* W-tasks: the object types that carry a .tasks registry. Player/Mob/Entity all
   have a stable runtime identity; Display backs holograms; Block (from
   block_at) keys by position. Npc's this binds to Entity, Hologram's this to
   Display — both already covered. Item is excluded: it is a value type with no
   stable identity, so .tasks is rejected on it. *)
let is_task_owner = function
  | TPlayer | TMob | TEntity | TDisplay | TBlock | TOfflinePlayer | TAny -> true
  | _ -> false

(* --- inline event handlers on item/mob/hologram/npc declarations
   (W-inline-handlers). Generalizes the mob on_hit dispatch into a full
   first-class handler set on every entity-like declaration.

   Each declaration kind has a FIXED table of allowed handler names and their
   parameter TYPES; the binder NAMES are user-chosen, only the types are fixed
   here. Inside every handler body `this` binds to the kind's instance type and
   the named parameters bind to their fixed types; the body is sync-colored.
   The runtime registers one filtered dispatcher per (kind,event) that routes
   to the matching declaration by item-id / mob-type / hologram / npc name
   (reusing the mob on_hit machinery).

   The handlers already shipped with dedicated declaration fields — mob
   on_spawn/on_death/on_attack/on_hit, the item on_click(left|right|any) filter
   sugar, and npc on_click/on_left_click — are consumed by their own parser
   branches BEFORE the generic path, so only the ADDITIVE handlers reach it.
   The already-shipped mob/npc names are still listed below so unknown-handler
   suggestions and per-kind validation share one source of truth. *)

type decl_kind =
  | KMob
  | KItem
  | KHologram
  | KNpc

let decl_kind_name = function
  | KMob -> "mob"
  | KItem -> "item"
  | KHologram -> "hologram"
  | KNpc -> "npc"

(* the type bound to `this` inside a handler body on this kind *)
let decl_this_ty = function
  | KMob -> TMob
  | KItem -> TItem
  | KHologram -> TDisplay (* the hologram's text-display stack *)
  | KNpc -> TEntity (* the npc's fake-player entity *)

(* the bare variable name the receiver instance ("self") is bound under inside a
   handler body — its natural noun. `this` was removed; the receiver is now a
   plain in-scope variable of this name. *)
let decl_noun = function
  | KMob -> "mob"
  | KItem -> "item"
  | KHologram -> "hologram"
  | KNpc -> "npc"

type handler_sig = {
  h_event : string;
  (* fixed parameter list: (canonical name for errors, fixed ty). The user
     supplies its own binder names positionally; only the types are fixed. *)
  h_params : (string * ty) list;
  (* whether the body may `cancel event` to veto: true only for handlers whose
     runtime dispatch binds a cancellable Minestom event wrapper (item
     on_right_click = PlayerUseItem, on_drop = ItemDrop). on_attack_entity is
     NOT cancellable — Minestom's EntityAttackEvent is a pure notification with
     no setCancelled — so it is left false to avoid a silent runtime no-op. *)
  h_cancellable : bool;
}

let hs h_event h_params = { h_event; h_params; h_cancellable = false }
let hsc h_event h_params = { h_event; h_params; h_cancellable = true }

(* MOB: on_hit(attacker) already shipped (dedicated field). *)
let mob_handlers =
  [
    hs "on_hit" [ ("attacker", TEntity) ];
    hs "on_death" [ ("killer", TOptional TEntity) ];
    hs "on_click" [ ("player", TPlayer) ];
    hs "on_attack" [ ("target", TEntity) ];
    hs "on_target" [ ("target", TOptional TEntity) ];
    hs "on_spawn" [];
    hs "on_tick" [];
  ]

let item_handlers =
  [
    hsc "on_right_click" [ ("player", TPlayer) ];
    hs "on_right_click_block" [ ("player", TPlayer); ("location", TLocation); ("face", TString) ];
    hs "on_left_click" [ ("player", TPlayer) ];
    hs "on_attack_entity" [ ("player", TPlayer); ("target", TEntity) ];
    hs "on_consume" [ ("player", TPlayer) ];
    hsc "on_drop" [ ("player", TPlayer) ];
    hs "on_pickup" [ ("player", TPlayer) ];
    hs "on_swap_to" [ ("player", TPlayer) ];
    hs "on_break" [ ("player", TPlayer) ];
  ]

let hologram_handlers =
  [
    hs "on_click" [ ("player", TPlayer) ];
    hs "on_line_click" [ ("player", TPlayer); ("line", TInteger) ];
    (* on_tick(): fired every tick while the hologram is active; `this` binds to
       the hologram's text-display stack. Guarded — only ticked if declared. *)
    hs "on_tick" [];
  ]

(* NPC: both click handlers already shipped (dedicated fields); reconciled here.
   on_tick() fires every tick while the npc is active; `this` binds to the npc's
   fake-player entity. Guarded — only ticked if declared. *)
let npc_handlers =
  [
    hs "on_click" [ ("player", TPlayer) ];
    hs "on_left_click" [ ("player", TPlayer) ];
    hs "on_tick" [];
  ]

let handlers_for = function
  | KMob -> mob_handlers
  | KItem -> item_handlers
  | KHologram -> hologram_handlers
  | KNpc -> npc_handlers

let find_handler kind name = List.find_opt (fun h -> h.h_event = name) (handlers_for kind)
let handler_names kind = List.map (fun h -> h.h_event) (handlers_for kind)

(* --- W-blocks: block_handler / placement_rule callback signatures ---

   Each callback has a fixed parameter list (the user chooses binder names, the
   types are fixed here) and an optional required return type. A callback whose
   bcb_ret is Some t MUST return a t on every path; one whose bcb_ret is None
   must not return a value. *)
type block_cb_sig = {
  bcb_name : string;
  bcb_params : (string * ty) list;
  bcb_ret : ty option;
}

let block_handler_cbs =
  [
    { bcb_name = "on_place";
      bcb_params = [ ("player", TPlayer); ("location", TLocation); ("block", TBlock) ];
      bcb_ret = None };
    { bcb_name = "on_destroy";
      bcb_params = [ ("location", TLocation); ("block", TBlock) ];
      bcb_ret = None };
    { bcb_name = "on_interact";
      bcb_params = [ ("player", TPlayer); ("location", TLocation); ("block", TBlock) ];
      bcb_ret = Some TBoolean };
    { bcb_name = "on_touch"; bcb_params = [ ("entity", TEntity); ("location", TLocation) ];
      bcb_ret = None };
    { bcb_name = "tick"; bcb_params = [ ("location", TLocation); ("block", TBlock) ];
      bcb_ret = None };
  ]

let placement_rule_cbs =
  [
    { bcb_name = "on_place";
      bcb_params =
        (* 'player' is the placing player's POSITION (a yaw/pitch-bearing Location),
           not a Player value: Minestom's PlacementState only exposes
           playerPosition() (a Pos) — there is no Player in a placement rule. This
           is the source of orientation-from-look for stairs/doors (player.yaw). *)
        [ ("location", TLocation); ("face", TString); ("cursor", TVec); ("against", TBlock);
          ("player", TLocation) ];
      bcb_ret = Some TBlock };
    { bcb_name = "on_update";
      bcb_params = [ ("location", TLocation); ("block", TBlock); ("neighbors", TMap (TString, TBlock)) ];
      bcb_ret = Some TBlock };
  ]

let find_block_cb cbs name = List.find_opt (fun c -> c.bcb_name = name) cbs
let block_cb_names cbs = List.map (fun c -> c.bcb_name) cbs

(* --- OOP receiver types (top-level `Player { on_join() {} } `, etc.) ---

   A receiver is a Capitalized top-level type block whose members are fixed-name
   methods. Each method has a fixed parameter list (the user chooses binder
   names, the types are fixed here) and a cancellable flag (the body may
   `cancel event` iff the underlying Minestom event is cancellable). `this`
   binds to the receiver's instance type inside every method body, which is
   sync-colored.

   The method tables below are derived from the OOP event-model design's §1
   receiver catalog / §2 event->receiver.method mapping. The lowercase custom
   declarations (`mob "id"`, `item "id"`, `block_handler "id"`) keep their own
   handler tables above and now OVERRIDE the matching base-receiver method
   (most-specific-wins); a custom body may call `default()` / `super.<m>(...)`
   to invoke the base. Npc / Hologram reuse their existing handler tables. *)
type receiver_kind =
  | RPlayer
  | REntity
  | RMob
  | RItem
  | RBlock
  | RProjectile
  | RInventory
  | RWorld
  | RServer
  | RNpc
  | RHologram

let receiver_name = function
  | RPlayer -> "Player"
  | REntity -> "Entity"
  | RMob -> "Mob"
  | RItem -> "Item"
  | RBlock -> "Block"
  | RProjectile -> "Projectile"
  | RInventory -> "Inventory"
  | RWorld -> "World"
  | RServer -> "Server"
  | RNpc -> "Npc"
  | RHologram -> "Hologram"

let receiver_kind_of_name = function
  | "Player" -> Some RPlayer
  | "Entity" -> Some REntity
  | "Mob" -> Some RMob
  | "Item" -> Some RItem
  | "Block" -> Some RBlock
  | "Projectile" -> Some RProjectile
  | "Inventory" -> Some RInventory
  | "World" -> Some RWorld
  | "Server" -> Some RServer
  | "Npc" -> Some RNpc
  | "Hologram" -> Some RHologram
  | _ -> None

(* the capitalized receiver keywords (base types) + the special `Packet` block *)
let receiver_type_names =
  [ "Player"; "Entity"; "Mob"; "Item"; "Block"; "Projectile"; "Inventory"; "World"; "Server";
    "Npc"; "Hologram" ]

(* the bare variable name the receiver instance ("self") is bound under inside a
   method body — its natural noun. `this` was removed; the receiver is now a
   plain in-scope variable of this name. *)
let receiver_noun = function
  | RPlayer -> "player"
  | REntity -> "entity"
  | RMob -> "mob"
  | RItem -> "item"
  | RBlock -> "block"
  | RProjectile -> "projectile"
  | RInventory -> "inventory"
  | RWorld -> "world"
  | RServer -> "server"
  | RNpc -> "npc"
  | RHologram -> "hologram"

(* the type bound to the receiver-instance variable inside a method body *)
let receiver_this_ty = function
  | RPlayer -> TPlayer
  | REntity -> TEntity
  | RMob -> TMob
  | RItem -> TItem
  | RBlock -> TBlock
  | RProjectile -> TEntity (* projectiles are entities; no distinct TProjectile *)
  | RInventory -> TAny (* no distinct TInventory value type *)
  | RWorld -> TWorld
  | RServer -> TServer
  | RNpc -> TEntity (* the npc's fake-player entity *)
  | RHologram -> TDisplay (* the hologram's text-display stack *)

(* Player: every online player. Method args are the event's non-`player` props. *)
let player_receiver_handlers =
  [
    hs "on_join" [];
    hs "on_quit" [];
    hs "on_loaded" [];
    hsc "on_chat" [ ("message", TString) ];
    hsc "on_move" [ ("new_position", TLocation) ];
    hs "on_death" [ ("death_text", TString); ("chat_message", TString) ];
    hs "on_respawn" [ ("respawn_position", TLocation) ];
    hsc "on_command" [ ("command", TString) ];
    hsc "on_break_block" [ ("block", TString); ("location", TLocation); ("face", TString) ];
    hsc "on_place_block" [ ("block", TString); ("location", TLocation); ("face", TString); ("hand", TString) ];
    hsc "on_interact_block" [ ("block", TString); ("location", TLocation); ("face", TString); ("hand", TString) ];
    hsc "on_use_item" [ ("item", TItem); ("hand", TString) ];
    hs "on_use_item_on_block" [ ("item_stack", TItem); ("location", TLocation); ("face", TString); ("hand", TString) ];
    hsc "on_start_digging" [ ("block", TString); ("location", TLocation); ("face", TString) ];
    hs "on_finish_digging" [ ("block", TString); ("location", TLocation) ];
    hs "on_cancel_digging" [ ("block", TString); ("location", TLocation) ];
    hsc "on_change_held_slot" [ ("new_slot", TInteger); ("old_slot", TInteger) ];
    hsc "on_swap_item" [ ("main_hand_item", TItem); ("off_hand_item", TItem) ];
    hsc "on_gamemode_change" [ ("new_game_mode", TString) ];
    hs "on_start_sprinting" [];
    hs "on_stop_sprinting" [];
    hs "on_start_flying" [];
    hs "on_stop_flying" [];
    hs "on_start_elytra" [];
    hs "on_stop_elytra" [];
    hs "on_interact_entity" [ ("target", TEntity); ("hand", TString) ];
    hs "on_spectate_entity" [ ("target", TEntity) ];
    hs "on_teleport_to_entity" [ ("target", TEntity) ];
    hs "on_pick_entity" [ ("target", TEntity) ];
    hs "on_pick_block" [ ("block", TString); ("location", TLocation) ];
    hs "on_edit_sign" [ ("block", TString); ("block_position", TLocation) ];
    hs "on_edit_book" [];
    hs "on_anvil_input" [ ("input", TString) ];
    hsc "on_leave_bed" [];
    hsc "on_hand_animation" [];
    hs "on_input" [];
    hs "on_tick" [];
    hs "on_tick_end" [];
    hs "on_chunk_load" [ ("chunk_x", TInteger); ("chunk_z", TInteger) ];
    hs "on_chunk_unload" [ ("chunk_x", TInteger); ("chunk_z", TInteger) ];
    hs "on_skin_init" [ ("skin", TSkin) ];
    hs "on_settings_change" [];
    hs "on_resource_pack_status" [];
    hs "on_plugin_message" [];
    hs "on_advancement_tab" [];
    hs "on_stab" [ ("item_stack", TItem) ];
    hsc "on_pickup_experience" [ ("experience_count", TInteger) ];
    hsc "on_drop_item" [ ("item", TItem) ];
    hs "on_pickup_item" [];
    hsc "on_packet_in" [];
    hsc "on_packet_out" [];
    hsc "on_begin_item_use" [];
    hs "on_cancel_item_use" [];
    hs "on_finish_item_use" [];
    hsc "on_outgoing_transfer" [ ("host", TString); ("port", TInteger) ];
    (* custom net.swofty fishing events (typed views for the rod holder) *)
    hs "on_cast_rod" [];
    hs "on_fish_bite" [];
    hs "on_catch_fish" [];
    hs "on_reel_in" [];
  ]

(* Entity: base for every live entity. `this` = the subject entity. *)
let entity_receiver_handlers =
  [
    hsc "on_hit" [ ("attacker", TOptional TEntity) ];
    hs "on_death" [];
    hs "on_spawn" [];
    hs "on_despawn" [];
    hs "on_attack" [ ("target", TEntity) ];
    hs "on_tick" [];
    hs "on_teleport" [ ("new_position", TLocation) ];
    hsc "on_velocity" [ ("velocity", TVec) ];
    hsc "on_shoot" [ ("projectile", TEntity); ("to", TLocation); ("power", TDouble); ("spread", TDouble) ];
    hsc "on_set_fire" [ ("fire_ticks", TInteger) ];
    hsc "on_fire_extinguish" [];
    hsc "on_item_merge" [];
    hsc "on_potion_add" [];
    hs "on_potion_remove" [];
    hs "on_equip" [ ("equipped_item", TItem); ("slot", TString) ];
    hsc "on_pickup_item" [ ("item_stack", TItem); ("item_entity", TEntity) ];
  ]

(* Mob <: Entity: narrows Entity to server-spawned mobs. *)
let mob_receiver_handlers =
  [
    hs "on_hit" [ ("attacker", TEntity) ];
    hs "on_death" [ ("killer", TOptional TEntity) ];
    hs "on_spawn" [];
    hs "on_tick" [];
    hs "on_attack" [ ("target", TEntity) ];
    hs "on_target" [ ("target", TOptional TEntity) ];
    hs "on_click" [ ("player", TPlayer) ];
    hs "on_despawn" [];
    hs "on_teleport" [ ("new_position", TLocation) ];
    hsc "on_shoot" [ ("projectile", TEntity); ("to", TLocation); ("power", TDouble); ("spread", TDouble) ];
  ]

(* Item: the ItemStack involved in an interaction. *)
let item_receiver_handlers =
  [
    hsc "on_use" [ ("player", TPlayer) ];
    hsc "on_right_click" [ ("player", TPlayer) ];
    hs "on_right_click_block" [ ("player", TPlayer); ("location", TLocation); ("face", TString) ];
    hs "on_left_click" [ ("player", TPlayer) ];
    hs "on_attack_entity" [ ("player", TPlayer); ("target", TEntity) ];
    hs "on_consume" [ ("player", TPlayer) ];
    hsc "on_drop" [ ("player", TPlayer) ];
    hs "on_pickup" [ ("player", TPlayer) ];
    hs "on_swap_to" [ ("player", TPlayer) ];
    hs "on_break" [ ("player", TPlayer) ];
    hsc "on_begin_use" [ ("player", TPlayer) ];
    hs "on_cancel_use" [ ("player", TPlayer) ];
    hs "on_finish_use" [ ("player", TPlayer) ];
    hs "on_equip" [ ("entity", TEntity); ("slot", TString) ];
  ]

(* Block: the positioned block value. Generalizes block_handler_cbs. *)
let block_receiver_handlers =
  [
    hs "on_place" [ ("player", TPlayer); ("location", TLocation); ("block", TBlock) ];
    hsc "on_break" [ ("player", TPlayer) ];
    hs "on_destroy" [ ("location", TLocation); ("block", TBlock) ];
    hsc "on_interact" [ ("player", TPlayer); ("location", TLocation); ("block", TBlock) ];
    hs "on_touch" [ ("entity", TEntity); ("location", TLocation) ];
    hs "on_tick" [ ("location", TLocation); ("block", TBlock) ];
    hsc "on_dispense" [ ("item", TItem); ("direction", TString) ];
    hs "on_update" [ ("location", TLocation); ("block", TBlock) ];
  ]

(* Projectile <: Entity: projectile lifecycle. *)
let projectile_receiver_handlers =
  [
    hsc "on_hit_block" [ ("block", TBlock); ("world", TWorld) ];
    hsc "on_hit_entity" [ ("target", TEntity) ];
    hs "on_uncollide" [];
  ]

(* Inventory / GUI: open-inventory interactions. *)
let inventory_receiver_handlers =
  [
    hsc "on_pre_click" [ ("player", TPlayer); ("slot", TInteger); ("clicked_item", TItem) ];
    hs "on_click" [ ("player", TPlayer); ("slot", TInteger); ("click_type", TString); ("clicked_item", TItem); ("cursor_item", TItem) ];
    hsc "on_open" [ ("player", TPlayer) ];
    hs "on_close" [ ("player", TPlayer); ("from_client", TBoolean) ];
    hs "on_button_click" [ ("player", TPlayer) ];
    hs "on_bundle_select" [ ("player", TPlayer); ("selected_item_index", TInteger) ];
    hs "on_item_change" [ ("new_item", TItem); ("previous_item", TItem); ("slot", TInteger) ];
    hsc "on_creative_action" [ ("player", TPlayer); ("slot", TInteger); ("clicked_item", TItem) ];
  ]

(* World / Instance: the Minestom Instance. *)
let world_receiver_handlers =
  [
    hs "on_tick" [ ("duration", TInteger) ];
    hs "on_chunk_load" [ ("chunk_x", TInteger); ("chunk_z", TInteger) ];
    hs "on_chunk_unload" [ ("chunk_x", TInteger); ("chunk_z", TInteger) ];
    hs "on_register" [];
    hs "on_unregister" [];
    hs "on_section_invalidate" [];
    hs "on_block_update" [ ("block", TBlock); ("block_position", TLocation) ];
    hsc "on_entity_add" [ ("entity", TEntity) ];
    hs "on_entity_remove" [ ("entity", TEntity) ];
  ]

(* Server: the global singleton + pre-login / connection-only events. *)
let server_receiver_handlers =
  [
    hsc "on_list_ping" [ ("status", TString) ];
    hsc "on_client_ping" [ ("delay", TInteger); ("payload", TInteger) ];
    hs "on_tick_monitor" [];
    hs "on_pre_login" [ ("connection", TAny); ("username", TString); ("game_profile", TAny) ];
    hs "on_player_configuration" [ ("player", TPlayer); ("spawning_instance", TWorld); ("hardcore", TBoolean) ];
    hs "on_tps_change" [ ("past", TDouble); ("current", TDouble) ];
  ]

let receiver_handlers = function
  | RPlayer -> player_receiver_handlers
  | REntity -> entity_receiver_handlers
  | RMob -> mob_receiver_handlers
  | RItem -> item_receiver_handlers
  | RBlock -> block_receiver_handlers
  | RProjectile -> projectile_receiver_handlers
  | RInventory -> inventory_receiver_handlers
  | RWorld -> world_receiver_handlers
  | RServer -> server_receiver_handlers
  | RNpc -> npc_handlers
  | RHologram -> hologram_handlers

let find_receiver_method rk name =
  List.find_opt (fun h -> h.h_event = name) (receiver_handlers rk)

let receiver_method_names rk = List.map (fun h -> h.h_event) (receiver_handlers rk)

(* every base-receiver kind, in the design's fan-out precedence order — the
   source for the editor symbol dump (receiver keywords + their method names). *)
let all_receiver_kinds =
  [ RPlayer; REntity; RMob; RItem; RBlock; RProjectile; RInventory; RWorld; RServer; RNpc;
    RHologram ]

(* the base receiver a lowercase custom declaration extends, for override /
   `default()` / `super` resolution *)
let base_receiver_of_kind = function
  | KMob -> RMob
  | KItem -> RItem
  | KHologram -> RHologram
  | KNpc -> RNpc

(* The canonical engine/curated event a receiver method dispatches on (design §2
   event->receiver.method mapping). This is what lets a receiver method compile
   down to the SAME event-dispatch JSON the removed flat `event { }` form emitted
   (name goes through `canonical_event_name` at emit time, exactly as the flat
   form did), so the runtime EventRegistrar target is unchanged. Methods whose
   dispatch has no distinct catalog event (they ride the inline-handler / NPC /
   hologram / mob-forwarding runtimes: on_click, on_target, on_touch, ...) return
   None; emit falls back to a `<Receiver>.<method>` identifier for them. *)
let receiver_method_event rk name : string option =
  match (rk, name) with
  (* --- Player --- *)
  | RPlayer, "on_join" -> Some "PlayerSpawn"
  | RPlayer, "on_quit" -> Some "PlayerDisconnect"
  | RPlayer, "on_loaded" -> Some "PlayerLoaded"
  | RPlayer, "on_chat" -> Some "PlayerChat"
  | RPlayer, "on_move" -> Some "PlayerMove"
  | RPlayer, "on_death" -> Some "PlayerDeath"
  | RPlayer, "on_respawn" -> Some "PlayerRespawn"
  | RPlayer, "on_command" -> Some "PlayerCommand"
  | RPlayer, "on_break_block" -> Some "PlayerBlockBreak"
  | RPlayer, "on_place_block" -> Some "PlayerBlockPlace"
  | RPlayer, "on_interact_block" -> Some "PlayerBlockInteract"
  | RPlayer, "on_use_item" -> Some "VanillaUseItem"
  | RPlayer, "on_use_item_on_block" -> Some "PlayerUseItemOnBlock"
  | RPlayer, "on_start_digging" -> Some "PlayerStartDigging"
  | RPlayer, "on_finish_digging" -> Some "PlayerFinishDigging"
  | RPlayer, "on_cancel_digging" -> Some "PlayerCancelDigging"
  | RPlayer, "on_change_held_slot" -> Some "PlayerChangeHeldSlot"
  | RPlayer, "on_swap_item" -> Some "PlayerSwapItem"
  | RPlayer, "on_gamemode_change" -> Some "PlayerGameModeChange"
  | RPlayer, "on_start_sprinting" -> Some "PlayerStartSprinting"
  | RPlayer, "on_stop_sprinting" -> Some "PlayerStopSprinting"
  | RPlayer, "on_start_flying" -> Some "PlayerStartFlying"
  | RPlayer, "on_stop_flying" -> Some "PlayerStopFlying"
  | RPlayer, "on_start_elytra" -> Some "PlayerStartFlyingWithElytra"
  | RPlayer, "on_stop_elytra" -> Some "PlayerStopFlyingWithElytra"
  | RPlayer, "on_interact_entity" -> Some "PlayerEntityInteract"
  | RPlayer, "on_spectate_entity" -> Some "PlayerSpectateEntity"
  | RPlayer, "on_teleport_to_entity" -> Some "PlayerTeleportToEntity"
  | RPlayer, "on_pick_entity" -> Some "PlayerPickEntity"
  | RPlayer, "on_pick_block" -> Some "PlayerPickBlock"
  | RPlayer, "on_edit_sign" -> Some "PlayerEditSign"
  | RPlayer, "on_edit_book" -> Some "EditBook"
  | RPlayer, "on_anvil_input" -> Some "PlayerAnvilInput"
  | RPlayer, "on_leave_bed" -> Some "PlayerLeaveBed"
  | RPlayer, "on_hand_animation" -> Some "PlayerHandAnimation"
  | RPlayer, "on_input" -> Some "PlayerInput"
  | RPlayer, "on_tick" -> Some "PlayerTick"
  | RPlayer, "on_tick_end" -> Some "PlayerTickEnd"
  | RPlayer, "on_chunk_load" -> Some "PlayerChunkLoad"
  | RPlayer, "on_chunk_unload" -> Some "PlayerChunkUnload"
  | RPlayer, "on_skin_init" -> Some "PlayerSkinInit"
  | RPlayer, "on_settings_change" -> Some "PlayerSettingsChange"
  | RPlayer, "on_resource_pack_status" -> Some "PlayerResourcePackStatus"
  | RPlayer, "on_plugin_message" -> Some "PlayerPluginMessage"
  | RPlayer, "on_advancement_tab" -> Some "AdvancementTab"
  | RPlayer, "on_stab" -> Some "PlayerStab"
  | RPlayer, "on_pickup_experience" -> Some "PickupExperience"
  | RPlayer, "on_drop_item" -> Some "ItemDrop"
  | RPlayer, "on_pickup_item" -> Some "PickupItem"
  | RPlayer, "on_packet_in" -> Some "PlayerPacket"
  | RPlayer, "on_packet_out" -> Some "PlayerPacketOut"
  | RPlayer, "on_begin_item_use" -> Some "PlayerBeginItemUse"
  | RPlayer, "on_cancel_item_use" -> Some "PlayerCancelItemUse"
  | RPlayer, "on_finish_item_use" -> Some "PlayerFinishItemUse"
  | RPlayer, "on_outgoing_transfer" -> Some "OutgoingTransfer"
  | RPlayer, "on_cast_rod" -> Some "PlayerCastRod"
  | RPlayer, "on_fish_bite" -> Some "FishBite"
  | RPlayer, "on_catch_fish" -> Some "PlayerCatchFish"
  | RPlayer, "on_reel_in" -> Some "PlayerReelIn"
  (* --- Entity --- *)
  | REntity, "on_hit" -> Some "EntityDamage"
  | REntity, "on_death" -> Some "EntityDeath"
  | REntity, "on_spawn" -> Some "EntitySpawn"
  | REntity, "on_despawn" -> Some "EntityDespawn"
  | REntity, "on_attack" -> Some "EntityAttack"
  | REntity, "on_tick" -> Some "EntityTick"
  | REntity, "on_teleport" -> Some "EntityTeleport"
  | REntity, "on_velocity" -> Some "EntityVelocity"
  | REntity, "on_shoot" -> Some "EntityShoot"
  | REntity, "on_set_fire" -> Some "EntitySetFire"
  | REntity, "on_fire_extinguish" -> Some "EntityFireExtinguish"
  | REntity, "on_item_merge" -> Some "EntityItemMerge"
  | REntity, "on_potion_add" -> Some "EntityPotionAdd"
  | REntity, "on_potion_remove" -> Some "EntityPotionRemove"
  | REntity, "on_equip" -> Some "EntityEquip"
  | REntity, "on_pickup_item" -> Some "PickupItem"
  (* --- Mob (mob-filtered typed views of the entity events) --- *)
  | RMob, "on_hit" -> Some "MobDamage"
  | RMob, "on_death" -> Some "MobDeath"
  | RMob, "on_spawn" -> Some "MobSpawn"
  | RMob, "on_attack" -> Some "EntityAttack"
  | RMob, "on_despawn" -> Some "EntityDespawn"
  | RMob, "on_teleport" -> Some "EntityTeleport"
  | RMob, "on_shoot" -> Some "EntityShoot"
  | RMob, "on_click" -> Some "PlayerEntityInteract"
  (* on_target / on_tick ride the SwoftMob AI-forwarding runtime: no catalog event *)
  | RMob, ("on_target" | "on_tick") -> None
  (* --- Item (rides the inline-handler runtime; events per InlineHandlerRuntime) --- *)
  | RItem, "on_use" -> Some "PlayerUseItem"
  | RItem, "on_right_click" -> Some "VanillaUseItem"
  | RItem, "on_right_click_block" -> Some "PlayerUseItemOnBlock"
  | RItem, "on_left_click" -> Some "PlayerHandAnimation"
  | RItem, "on_attack_entity" -> Some "EntityAttack"
  | RItem, "on_consume" -> Some "PlayerFinishItemUse"
  | RItem, "on_drop" -> Some "ItemDrop"
  | RItem, "on_pickup" -> Some "PickupItem"
  | RItem, "on_swap_to" -> Some "PlayerChangeHeldSlot"
  | RItem, "on_begin_use" -> Some "PlayerBeginItemUse"
  | RItem, "on_cancel_use" -> Some "PlayerCancelItemUse"
  | RItem, "on_finish_use" -> Some "PlayerFinishItemUse"
  | RItem, "on_equip" -> Some "EntityEquip"
  (* on_break rides the native durability tracker: no catalog event *)
  | RItem, "on_break" -> None
  (* --- Block --- *)
  | RBlock, "on_place" -> Some "PlayerBlockPlace"
  | RBlock, "on_break" -> Some "PlayerBlockBreak"
  | RBlock, "on_interact" -> Some "PlayerBlockInteract"
  | RBlock, "on_dispense" -> Some "BlockDispense"
  (* on_destroy / on_touch / on_tick / on_update ride the block-handler runtime *)
  | RBlock, ("on_destroy" | "on_touch" | "on_tick" | "on_update") -> None
  (* --- Projectile --- *)
  | RProjectile, "on_hit_block" -> Some "ProjectileCollideWithBlock"
  | RProjectile, "on_hit_entity" -> Some "ProjectileCollideWithEntity"
  | RProjectile, "on_uncollide" -> Some "ProjectileUncollide"
  (* --- Inventory / GUI --- *)
  | RInventory, "on_pre_click" -> Some "InventoryPreClick"
  | RInventory, "on_click" -> Some "InventoryClick"
  | RInventory, "on_open" -> Some "InventoryOpen"
  | RInventory, "on_close" -> Some "InventoryClose"
  | RInventory, "on_button_click" -> Some "InventoryButtonClick"
  | RInventory, "on_bundle_select" -> Some "InventoryBundleItemSelect"
  | RInventory, "on_item_change" -> Some "InventoryItemChange"
  | RInventory, "on_creative_action" -> Some "CreativeInventoryAction"
  (* --- World / Instance --- *)
  | RWorld, "on_tick" -> Some "InstanceTick"
  | RWorld, "on_chunk_load" -> Some "InstanceChunkLoad"
  | RWorld, "on_chunk_unload" -> Some "InstanceChunkUnload"
  | RWorld, "on_register" -> Some "InstanceRegister"
  | RWorld, "on_unregister" -> Some "InstanceUnregister"
  | RWorld, "on_section_invalidate" -> Some "InstanceSectionInvalidate"
  | RWorld, "on_block_update" -> Some "InstanceBlockUpdate"
  | RWorld, "on_entity_add" -> Some "AddEntityToInstance"
  | RWorld, "on_entity_remove" -> Some "RemoveEntityFromInstance"
  (* --- Server --- *)
  | RServer, "on_list_ping" -> Some "ServerListPing"
  | RServer, "on_client_ping" -> Some "ClientPingServer"
  | RServer, "on_tick_monitor" -> Some "ServerTickMonitor"
  | RServer, "on_pre_login" -> Some "AsyncPlayerPreLogin"
  | RServer, "on_player_configuration" -> Some "AsyncPlayerConfiguration"
  | RServer, "on_tps_change" -> Some "TpsChange"
  (* --- Npc / Hologram ride their dedicated packet runtimes: no catalog event --- *)
  | (RNpc | RHologram), _ -> None
  | _ -> None

(* --- builtin functions --- *)

type param_kind =
  | PNum
  | PStr
  | PStrOrList
  | PPlayer
  | PItem
  | PLoc
  | PLoader
  | PSchedOrName (* a Schedule handle or a String name (scheduler v2) *)

type ret_kind =
  | RTy of ty
  | RNumJoin

type builtin = {
  b_name : string;
  b_sigs : (param_kind list * ret_kind) list;
  b_async_only : bool;
}

let b name sigs = { b_name = name; b_sigs = sigs; b_async_only = false }

let builtins =
  [
    b "random" [ ([ PNum; PNum ], RTy TInteger) ];
    b "round" [ ([ PNum ], RTy TInteger) ];
    b "floor" [ ([ PNum ], RTy TInteger) ];
    b "ceil" [ ([ PNum ], RTy TInteger) ];
    b "abs" [ ([ PNum ], RNumJoin) ];
    b "uppercase" [ ([ PStr ], RTy TString) ];
    b "lowercase" [ ([ PStr ], RTy TString) ];
    b "length" [ ([ PStrOrList ], RTy TInteger) ];
    b "location"
      [ ([ PNum; PNum; PNum ], RTy TLocation); ([ PNum; PNum; PNum; PNum; PNum ], RTy TLocation) ];
    (* the Location `distance` blocks ahead of the player's eye direction *)
    b "in_front_of" [ ([ PPlayer; PNum ], RTy TLocation) ];
    b "item" [ ([ PStr ], RTy TItem); ([ PStr; PNum ], RTy TItem) ];
    b "player" [ ([ PStr ], RTy (TOptional TPlayer)) ];
    b "all_players" [ ([], RTy (TList TPlayer)) ];
    b "world" [ ([ PStr ], RTy (TOptional TWorld)) ];
    b "centered" [ ([ PStr ], RTy TString) ];
    {
      b_name = "prompt_input";
      b_sigs = [ ([ PPlayer; PStr ], RTy TString) ];
      b_async_only = true;
    };
    b "min" [ ([ PNum; PNum ], RNumJoin) ];
    b "max" [ ([ PNum; PNum ], RNumJoin) ];
    b "clamp" [ ([ PNum; PNum; PNum ], RNumJoin) ];
    b "format_number" [ ([ PNum ], RTy TString) ];
    b "custom_item" [ ([ PStr ], RTy TItem) ];
    b "custom_id" [ ([ PItem ], RTy (TOptional TString)) ];
    b "all_mobs" [ ([], RTy (TList TMob)); ([ PStr ], RTy (TList TMob)) ];
    (* --- phase-7 entities --- *)
    b "velocity" [ ([ PNum; PNum; PNum ], RTy TVec) ];
    b "all_entities" [ ([], RTy (TList TEntity)); ([ PStr ], RTy (TList TEntity)) ];
    (* --- phase-6 display entities (design 6B) --- *)
    b "spawn_text_display" [ ([ PStr; PLoc ], RTy TDisplay) ];
    b "spawn_item_display" [ ([ PStr; PLoc ], RTy TDisplay) ];
    b "spawn_block_display" [ ([ PStr; PLoc ], RTy TDisplay) ];
    (* --- phase-6 NBS songs --- *)
    b "song" [ ([ PStr ], RTy TSong) ];
    (* --- phase-6 TPS introspection --- *)
    b "tps_string" [ ([], RTy TString) ];
    b "average_tps_string" [ ([], RTy TString) ];
    b "tps_at" [ ([ PNum ], RTy TDouble) ];
    (* --- phase-6 worlds --- *)
    b "anvil_loader" [ ([ PStr ], RTy TWorldLoader) ];
    b "polar_loader" [ ([ PStr ], RTy TWorldLoader) ];
    b "world_exists" [ ([ PStr; PLoader ], RTy TBoolean) ];
    b "all_worlds" [ ([ PLoader ], RTy (TList TString)) ];
    (* --- phase-6 blocks --- *)
    b "block_at" [ ([ PLoc ], RTy TBlock) ];
    (* W-blocks: block("id") / block("id", { prop: val }) -> Block. The property
       map form and literal id/prop/value validation are handled specially in
       Tc_expr; this stub reserves the name for collision checks. *)
    b "block" [ ([ PStr ], RTy TBlock) ];
    (* --- phase-6 player skins --- *)
    b "skin" [ ([ PStr; PStr ], RTy TSkin) ];
    {
      (* Mojang API lookup over java.net.http on the calling virtual thread *)
      b_name = "fetch_skin";
      b_sigs = [ ([ PStr ], RTy (TOptional TSkin)) ];
      b_async_only = true;
    };
    (* --- phase-6 map canvases --- *)
    b "map_canvas" [ ([], RTy TCanvas) ];
    (* --- phase-6 permissions --- *)
    b "has_permission" [ ([ PPlayer; PStr ], RTy TBoolean) ];
    (* --- phase-8 offline players --- *)
    (* seen-store lookup (case-insensitive); none if never seen. Sync-safe. *)
    b "offline_player" [ ([ PStr ], RTy (TOptional TOfflinePlayer)) ];
    (* total: constructs the identity; name from the store else "unknown" *)
    b "offline_player_uuid" [ ([ PStr ], RTy TOfflinePlayer) ];
    {
      (* Mojang API username->uuid over java.net.http (5s timeout -> none);
         a hit also seeds the seen-store *)
      b_name = "fetch_offline_player";
      b_sigs = [ ([ PStr ], RTy (TOptional TOfflinePlayer)) ];
      b_async_only = true;
    };
    b "all_seen_players" [ ([], RTy (TList TOfflinePlayer)) ];
    (* --- phase-10 maps --- *)
    (* new_map() builds an empty map with untyped keys/values; the key and value
       types are fixed by the context it flows into (a typed persistent, a
       map<K,V> variable, or the first insertion). The empty '{}' literal is
       rejected as ambiguous with a block, so this is the way to create one. *)
    b "new_map" [ ([], RTy (TMap (TAny, TAny))) ];
    (* The six map_get/map_set/map_has/map_delete/map_keys/map_size DICTIONARY
       free builtins were REMOVED: the natural-language dialect ('set m at k to
       v', 'm has k', 'keys of m', 'delete m at k', 'size of m', 'm[k]') and the
       method dialect (m.set/get/has/delete/keys/size) are the only surface
       forms now. A literal call to any of them is a parse error (see
       Parse_expr.removed_map_builtins) that points at both forms. Those same
       map_* nodes remain the internal emit target (Tc_expr routes them by the
       map's key/value type), so removing them here only drops the free-function
       spelling and its name-collision registration. map_canvas is unrelated. *)
    (* --- W-pvp: the entity ATTRIBUTE accessors/modifiers, combat EFFECTS, and
       native trackers were free functions (attribute/set_attribute/
       add_attribute_modifier/remove_attribute_modifier, apply_damage/
       apply_knockback/apply_effect/remove_effect/active_effects/spawn_projectile,
       invulnerable_ticks/fall_distance/is_climbing). They are REMOVED: attribute
       keys are now direct rw entity/player properties (combat_attribute_props),
       the trackers are ro properties (combat_tracker_props), and the effects are
       English statement verbs (damage/knock/apply/remove/shoot + add/remove
       modifier). Calling the old names now errors as an unknown function. --- *)
    (* --- phase-11 random (java.util.concurrent.ThreadLocalRandom at runtime).
       random(min,max) above stays; these are the additive draws. random_in and
       shuffle depend on the list element type, so they are handled specially in
       Tc_expr and only listed here to reserve their names. --- *)
    b "random_float" [ ([ PNum; PNum ], RTy TDouble) ];
    b "random_chance" [ ([ PNum ], RTy TBoolean) ];
    b "random_bool" [ ([], RTy TBoolean) ];
    b "random_in" [ ([ PStrOrList ], RTy (TOptional TAny)) ];
    b "shuffle" [ ([ PStrOrList ], RTy (TList TAny)) ];
    (* --- phase-11 sorting builtins. All non-mutating; their result type
       depends on the collection/lambda, so they are handled specially in
       Tc_expr and listed here only to reserve their names. --- *)
    b "sort" [ ([ PStrOrList ], RTy (TList TAny)) ];
    b "sort_by" [ ([ PStrOrList; PStr ], RTy (TList TAny)) ];
    b "sort_by_desc" [ ([ PStrOrList; PStr ], RTy (TList TAny)) ];
    b "reverse" [ ([ PStrOrList ], RTy (TList TAny)) ];
    b "min_by" [ ([ PStrOrList; PStr ], RTy (TOptional TAny)) ];
    b "max_by" [ ([ PStrOrList; PStr ], RTy (TOptional TAny)) ];
    b "sort_by_key" [ ([ PStr ], RTy (TMap (TAny, TAny))) ];
    b "sort_by_key_desc" [ ([ PStr ], RTy (TMap (TAny, TAny))) ];
    b "sort_by_value" [ ([ PStr ], RTy (TMap (TAny, TAny))) ];
    b "sort_by_value_desc" [ ([ PStr ], RTy (TMap (TAny, TAny))) ];
    b "sort_map_by" [ ([ PStr; PStr ], RTy (TMap (TAny, TAny))) ];
    b "sort_map_by_desc" [ ([ PStr; PStr ], RTy (TMap (TAny, TAny))) ];
    (* --- W-stdlib B3: math beyond arithmetic (java.lang.Math at runtime).
       min/max/clamp/abs/round/floor/ceil already exist above. mod/sum/product
       fold to the operands' numeric join, so they are handled specially in
       Tc_expr and only listed here to reserve their names. pi()/e() are the
       constants; sign returns -1/0/1. --- *)
    b "mod" [ ([ PNum; PNum ], RNumJoin) ];
    b "sqrt" [ ([ PNum ], RTy TDouble) ];
    b "pow" [ ([ PNum; PNum ], RTy TDouble) ];
    b "round_to" [ ([ PNum; PNum ], RTy TDouble) ];
    b "sin" [ ([ PNum ], RTy TDouble) ];
    b "cos" [ ([ PNum ], RTy TDouble) ];
    b "tan" [ ([ PNum ], RTy TDouble) ];
    b "asin" [ ([ PNum ], RTy TDouble) ];
    b "acos" [ ([ PNum ], RTy TDouble) ];
    b "atan" [ ([ PNum ], RTy TDouble) ];
    b "atan2" [ ([ PNum; PNum ], RTy TDouble) ];
    b "ln" [ ([ PNum ], RTy TDouble) ];
    (* natural log by default; the two-arg form is log base b *)
    b "log" [ ([ PNum ], RTy TDouble); ([ PNum; PNum ], RTy TDouble) ];
    b "log10" [ ([ PNum ], RTy TDouble) ];
    b "pi" [ ([], RTy TDouble) ];
    b "e" [ ([], RTy TDouble) ];
    b "sign" [ ([ PNum ], RTy TInteger) ];
    (* sum/product over a list<Number>; result numeric type flows from the
       element type, so handled specially in Tc_expr (reserved here) *)
    b "sum" [ ([ PStrOrList ], RTy TDouble) ];
    b "product" [ ([ PStrOrList ], RTy TDouble) ];
    (* --- W-stdlib B8: decimal-place number formatting (thousands-sep
       format_number exists above) --- *)
    b "format_decimals" [ ([ PNum; PNum ], RTy TString) ];
    (* --- W-stdlib B4: random design-named forms. random_int/random_double/
       chance are aliases of random/random_float/random_chance; random_element
       depends on the list element type (special-cased in Tc_expr). --- *)
    b "random_int" [ ([ PNum; PNum ], RTy TInteger) ];
    b "random_double" [ ([ PNum; PNum ], RTy TDouble) ];
    b "chance" [ ([ PNum ], RTy TBoolean) ];
    b "random_element" [ ([ PStrOrList ], RTy (TOptional TAny)) ];
    b "random_uuid" [ ([], RTy TString) ];
    b "random_seed" [ ([ PNum ], RTy TAny) ];
    (* --- W-stdlib B1: string free helpers. parse(s, Type) and type_of(obj)
       take a type/any argument, so they are special-cased in Tc_expr and only
       reserved here. matches/stripped/formatted are plain String -> value. --- *)
    b "parse" [ ([ PStr; PStr ], RTy (TOptional TAny)) ];
    b "matches" [ ([ PStr; PStr ], RTy TBoolean) ];
    b "stripped" [ ([ PStr ], RTy TString) ];
    b "formatted" [ ([ PStr ], RTy TString) ];
    b "type_of" [ ([ PStr ], RTy TString) ];
    (* --- W-stdlib B2: color & format codes (MiniMessage/legacy at runtime) --- *)
    b "strip_color" [ ([ PStr ], RTy TString) ];
    b "legacy_to_mini" [ ([ PStr ], RTy TString) ];
    b "gradient" [ ([ PStr; PStr; PStr ], RTy TString) ];
    b "rainbow" [ ([ PStr ], RTy TString) ];
    (* --- W-stdlib B7: location / region / vector math. distance/direction_from
       take two Locations; above/below shift on the Y axis; is_within is an AABB
       test; blocks_in_radius/players_in_radius sample a sphere; vec(x,y,z) makes
       a Vec; location_of(entity) is special-cased (accepts any live entity). --- *)
    b "distance" [ ([ PLoc; PLoc ], RTy TDouble) ];
    b "direction_from" [ ([ PLoc; PLoc ], RTy TVec) ];
    b "above" [ ([ PLoc; PNum ], RTy TLocation) ];
    b "below" [ ([ PLoc; PNum ], RTy TLocation) ];
    b "is_within" [ ([ PLoc; PLoc; PLoc ], RTy TBoolean) ];
    b "blocks_in_radius" [ ([ PLoc; PNum ], RTy (TList TLocation)) ];
    b "players_in_radius" [ ([ PLoc; PNum ], RTy (TList TPlayer)) ];
    b "vec" [ ([ PNum; PNum; PNum ], RTy TVec) ];
    b "location_of" [ ([ PPlayer ], RTy TLocation) ];
    (* --- phase-11 scheduler v2: liveness check by handle or name --- *)
    b "is_running" [ ([ PSchedOrName ], RTy TBoolean) ];
    (* --- phase-10 item <-> NBT string (persist item stacks) --- *)
    b "to_nbt" [ ([ PItem ], RTy TString) ];
    b "from_nbt" [ ([ PStr ], RTy (TOptional TItem)) ];
  ]

let find_builtin name = List.find_opt (fun bl -> bl.b_name = name) builtins

(* --- W-collections: method tables keyed by base type (List / Map / String).

   Method parameter and return types are written against the receiver's type
   variables so one entry covers every instantiation:
     SElem = list element T, SKey = map key K, SVal = map value V,
     SSelf = the receiver's own type (list<T> / map<K,V> / String).
   Concrete leaves (SInt/SStr/SBool/SAny) and the SList/SOpt constructors let a
   method mention Integer / String / Boolean / list<..> / optional<..>.
   SFn is a lambda parameter: its argument schemes plus the return ROLE it must
   satisfy — FBool (filtered), FComparable (sorted_by/min_by/max_by keys), or
   FFree (mapped, whose element type flows out as U).
   me_mut splits pure EXPRESSION methods (false) from in-place MUTATING
   statement methods (true); the typechecker rejects the wrong context.

   These are a second entry point to the SAME runtime as the free builtins
   (map_get/sort/uppercase/...), which stay as deprecated aliases. *)
type fn_role =
  | FBool (* the lambda must return a Boolean (filtered) *)
  | FComparable (* the lambda must return a Number or String key *)
  | FFree (* the lambda return is a free element U (mapped) *)

type mscheme =
  | SElem
  | SKey
  | SVal
  | SSelf
  | SInt
  | SStr
  | SBool
  | SAny
  | SList of mscheme
  | SOpt of mscheme
  | SFn of mscheme list * fn_role

type mret =
  | RScheme of mscheme
  | RMappedList (* list<U> where U is the (single) fn argument's return type *)

type meth = {
  me_name : string;
  me_params : mscheme list;
  me_ret : mret;
  me_mut : bool; (* true = in-place mutation, statement-only; false = pure expr *)
}

let me name params ret mut = { me_name = name; me_params = params; me_ret = ret; me_mut = mut }
let pe name params ret = me name params (RScheme ret) false (* pure expression method *)
let mu name params = me name params (RScheme SSelf) true (* mutating statement method *)

let map_methods =
  [
    (* expression (pure) *)
    pe "get" [ SKey ] (SOpt SVal);
    pe "has" [ SKey ] SBool;
    pe "get_or" [ SKey; SVal ] SVal;
    pe "sorted_by_key" [] SSelf;
    pe "sorted_by_key_desc" [] SSelf;
    pe "sorted_by_value" [] SSelf;
    pe "sorted_by_value_desc" [] SSelf;
    pe "sorted_by" [ SFn ([ SKey; SVal ], FComparable) ] SSelf;
    (* statement (mutating in place) *)
    mu "set" [ SKey; SVal ];
    mu "delete" [ SKey ];
    mu "clear" [];
    mu "put_all" [ SSelf ];
  ]

let list_methods =
  [
    (* expression (pure) *)
    pe "contains" [ SElem ] SBool;
    pe "index_of" [ SElem ] (SOpt SInt);
    pe "get" [ SInt ] (SOpt SElem);
    pe "joined" [ SStr ] SStr;
    pe "count" [ SElem ] SInt;
    pe "sorted" [] SSelf;
    pe "sorted_by" [ SFn ([ SElem ], FComparable) ] SSelf;
    pe "sorted_by_desc" [ SFn ([ SElem ], FComparable) ] SSelf;
    pe "reversed" [] SSelf;
    pe "shuffled" [] SSelf;
    pe "filtered" [ SFn ([ SElem ], FBool) ] SSelf;
    me "mapped" [ SFn ([ SElem ], FFree) ] RMappedList false;
    pe "taken" [ SInt ] SSelf;
    pe "dropped" [ SInt ] SSelf;
    pe "min_by" [ SFn ([ SElem ], FComparable) ] (SOpt SElem);
    pe "max_by" [ SFn ([ SElem ], FComparable) ] (SOpt SElem);
    (* statement (mutating in place) *)
    mu "add" [ SElem ];
    mu "add_all" [ SSelf ];
    mu "remove" [ SElem ];
    mu "remove_at" [ SInt ];
    mu "clear" [];
    mu "insert" [ SInt; SElem ];
  ]

let string_methods =
  [
    pe "length" [] SInt;
    pe "upper" [] SStr;
    pe "lower" [] SStr;
    pe "trimmed" [] SStr;
    pe "contains" [ SStr ] SBool;
    pe "starts_with" [ SStr ] SBool;
    pe "ends_with" [ SStr ] SBool;
    pe "replace" [ SStr; SStr ] SStr;
    pe "split" [ SStr ] (SList SStr);
    pe "substring" [ SInt; SInt ] SStr;
    pe "index_of" [ SStr ] (SOpt SInt);
    pe "repeated" [ SInt ] SStr;
    pe "reversed" [] SStr;
    pe "padded_left" [ SInt; SStr ] SStr;
    pe "padded_right" [ SInt; SStr ] SStr;
    (* W-stdlib B1: prefix/suffix of length n (clamped to the string length) *)
    pe "first_chars" [ SInt ] SStr;
    pe "last_chars" [ SInt ] SStr;
  ]

let find_method methods name = List.find_opt (fun m -> m.me_name = name) methods
let method_names methods = List.map (fun m -> m.me_name) methods

(* --- enums --- *)

let gamemodes = [ "survival"; "creative"; "adventure"; "spectator" ]

(* A0.4 enum->string normalization lists (lowercased Minestom enum names) for
   event rows that expose these as TString. Reads normalize to the lowercase
   name on the runtime side; these back literal-write validation the same way
   'gamemodes' does. PlayerHand -> main/off; BlockFace -> the six faces. *)
let hands = [ "main"; "off" ]
let block_faces = [ "bottom"; "top"; "north"; "south"; "west"; "east" ]

(* EntityPose enum names (pinned Minestom ebaa2bbf64: net.minestom.server.entity
   .EntityPose), lowercased snake_case for the 'pose' entity row (phase 10) *)
let entity_poses =
  [
    "standing"; "fall_flying"; "sleeping"; "swimming"; "spin_attack"; "sneaking"; "long_jumping";
    "dying"; "croaking"; "using_tongue"; "sitting"; "roaring"; "sniffing"; "emerging"; "digging";
    "sliding"; "shooting"; "inhaling";
  ]

(* the World 'weather' row values (phase 10): clear|rain|thunder map onto the
   Minestom Weather rain/thunder levels at runtime *)
let weather_states = [ "clear"; "rain"; "thunder" ]
let bossbar_colors = [ "pink"; "blue"; "red"; "green"; "yellow"; "purple"; "white" ]
let bossbar_styles = [ "progress"; "notched_6"; "notched_10"; "notched_12"; "notched_20" ]
let tablist_skins = [ "green"; "gray"; "cyan"; "blue"; "purple"; "orange" ]

(* the vanilla rarity component values (phase 9: the extended Hypixel-style
   ladder is gone — custom tiers are userland data, e.g. tags{} + lore) *)
let rarities = [ "common"; "uncommon"; "rare"; "epic" ]

(* pre-phase-9 ladder values, recognized for a pointed migration error *)
let removed_rarities = [ "legendary"; "mythic"; "divine"; "special" ]

(* on_click sugar filters (phase 9): use-item interactions only *)
let item_click_filters = [ "left"; "right"; "any" ]

(* real Minestom attributes applicable from an item's attributes{} block (design 5A) *)
let item_attribute_names =
  [ "speed"; "max_health"; "attack_damage"; "attack_speed"; "armor"; "knockback_resistance" ]

(* combat_attribute_names is defined near the top of this file (it composes into
   the entity/player property tables). *)

(* W-pvp: AttributeOperation names (javap-verified enum ADD_VALUE /
   ADD_MULTIPLIED_BASE / ADD_MULTIPLIED_TOTAL) plus friendly aliases; mirrored by
   Builtins.attributeOperationFromName. *)
let attribute_operations =
  [
    "add_value"; "add"; "add_multiplied_base"; "multiply_base"; "add_multiplied_total";
    "multiply_total";
  ]

(* W-pvp: PotionEffect keys accepted by apply_effect/remove_effect (snake_case
   of net.minestom.server.potion.PotionEffects, javap-verified against
   2026.07.12-26.2). Validated as literals; dynamic strings are checked at
   runtime by PotionEffect.fromKey. *)
let potion_effect_names =
  [
    "speed"; "slowness"; "haste"; "mining_fatigue"; "strength"; "instant_health";
    "instant_damage"; "jump_boost"; "nausea"; "regeneration"; "resistance"; "fire_resistance";
    "water_breathing"; "invisibility"; "blindness"; "night_vision"; "hunger"; "weakness";
    "poison"; "wither"; "health_boost"; "absorption"; "saturation"; "glowing"; "levitation";
    "luck"; "unluck"; "slow_falling"; "conduit_power"; "dolphins_grace"; "bad_omen";
    "hero_of_the_village"; "darkness"; "trial_omen"; "raid_omen"; "wind_charged"; "weaving";
    "oozing"; "infested"; "breath_of_the_nautilus";
  ]

(* W-pvp: DamageType registry keys accepted by apply_damage (snake_case of
   net.minestom.server.entity.damage.DamageTypes, javap-verified). Validated as
   literals; dynamic strings resolve at runtime. *)
let damage_type_names =
  [
    "wither"; "wither_skull"; "mace_smash"; "trident"; "on_fire"; "campfire";
    "falling_stalactite"; "fireball"; "spit"; "sting"; "spear"; "in_fire"; "arrow"; "hot_floor";
    "drown"; "generic_kill"; "dragon_breath"; "lava"; "fly_into_wall"; "player_attack"; "freeze";
    "falling_anvil"; "sweet_berry_bush"; "fireworks"; "stalagmite"; "generic"; "sonic_boom";
    "dry_out"; "ender_pearl"; "fall"; "mob_projectile"; "mob_attack"; "thrown"; "falling_block";
    "wind_charge"; "player_explosion"; "unattributed_fireball"; "sulfur_cube_hot"; "in_wall";
    "starve"; "mob_attack_no_aggro"; "outside_border"; "lightning_bolt"; "out_of_world"; "magic";
    "explosion"; "bad_respawn_point"; "thorns"; "indirect_magic"; "cramming"; "cactus";
  ]

(* W-pvp: projectile EntityType keys accepted by spawn_projectile. These are the
   thrown/shot combat projectiles; each is a real EntityType in the pinned jar. *)
let projectile_types = [ "arrow"; "spectral_arrow"; "trident"; "snowball"; "egg" ]

let mob_ais = [ "melee"; "passive"; "none" ]

(* phase-8: the fishing media a fishing_loot table can match *)
let fishing_mediums = [ "water"; "lava" ]

(* phase-6 enums *)
let api_methods = [ "GET"; "POST"; "PUT"; "DELETE"; "ANY" ]
let toast_frames = [ "task"; "goal"; "challenge" ]
let display_billboards = [ "fixed"; "vertical"; "horizontal"; "center" ]
let display_alignments = [ "left"; "center"; "right" ]

(* the 16 NamedTextColor names — team color is a protocol enum (design 5C) *)
let nametag_colors =
  [
    "black"; "dark_blue"; "dark_green"; "dark_aqua"; "dark_red"; "dark_purple"; "gold"; "gray";
    "dark_gray"; "blue"; "green"; "aqua"; "red"; "light_purple"; "yellow"; "white";
  ]

(* EntityType constant names dumped from Minestom 2026.07.12-26.2
   (javap on net.minestom.server.entity.EntityTypes) *)
let entity_types =
  [
    "ACACIA_BOAT"; "ACACIA_CHEST_BOAT"; "ALLAY"; "AREA_EFFECT_CLOUD"; "ARMADILLO";
    "ARMOR_STAND"; "ARROW"; "AXOLOTL"; "BAMBOO_CHEST_RAFT"; "BAMBOO_RAFT"; "BAT"; "BEE";
    "BIRCH_BOAT"; "BIRCH_CHEST_BOAT"; "BLAZE"; "BLOCK_DISPLAY"; "BOGGED"; "BREEZE";
    "BREEZE_WIND_CHARGE"; "CAMEL"; "CAMEL_HUSK"; "CAT"; "CAVE_SPIDER"; "CHERRY_BOAT";
    "CHERRY_CHEST_BOAT"; "CHEST_MINECART"; "CHICKEN"; "COD"; "COMMAND_BLOCK_MINECART";
    "COPPER_GOLEM"; "COW"; "CREAKING"; "CREEPER"; "DARK_OAK_BOAT"; "DARK_OAK_CHEST_BOAT";
    "DOLPHIN"; "DONKEY"; "DRAGON_FIREBALL"; "DROWNED"; "EGG"; "ELDER_GUARDIAN"; "ENDERMAN";
    "ENDERMITE"; "ENDER_DRAGON"; "ENDER_PEARL"; "END_CRYSTAL"; "EVOKER"; "EVOKER_FANGS";
    "EXPERIENCE_BOTTLE"; "EXPERIENCE_ORB"; "EYE_OF_ENDER"; "FALLING_BLOCK"; "FIREBALL";
    "FIREWORK_ROCKET"; "FISHING_BOBBER"; "FOX"; "FROG"; "FURNACE_MINECART"; "GHAST";
    "GIANT"; "GLOW_ITEM_FRAME"; "GLOW_SQUID"; "GOAT"; "GUARDIAN"; "HAPPY_GHAST"; "HOGLIN";
    "HOPPER_MINECART"; "HORSE"; "HUSK"; "ILLUSIONER"; "INTERACTION"; "IRON_GOLEM"; "ITEM";
    "ITEM_DISPLAY"; "ITEM_FRAME"; "JUNGLE_BOAT"; "JUNGLE_CHEST_BOAT"; "LEASH_KNOT";
    "LIGHTNING_BOLT"; "LINGERING_POTION"; "LLAMA"; "LLAMA_SPIT"; "MAGMA_CUBE";
    "MANGROVE_BOAT"; "MANGROVE_CHEST_BOAT"; "MANNEQUIN"; "MARKER"; "MINECART"; "MOOSHROOM";
    "MULE"; "NAUTILUS"; "OAK_BOAT"; "OAK_CHEST_BOAT"; "OCELOT"; "OMINOUS_ITEM_SPAWNER";
    "PAINTING"; "PALE_OAK_BOAT"; "PALE_OAK_CHEST_BOAT"; "PANDA"; "PARCHED"; "PARROT";
    "PHANTOM"; "PIG"; "PIGLIN"; "PIGLIN_BRUTE"; "PILLAGER"; "PLAYER"; "POLAR_BEAR";
    "PUFFERFISH"; "RABBIT"; "RAVAGER"; "SALMON"; "SHEEP"; "SHULKER"; "SHULKER_BULLET";
    "SILVERFISH"; "SKELETON"; "SKELETON_HORSE"; "SLIME"; "SMALL_FIREBALL"; "SNIFFER";
    "SNOWBALL"; "SNOW_GOLEM"; "SPAWNER_MINECART"; "SPECTRAL_ARROW"; "SPIDER";
    "SPLASH_POTION"; "SPRUCE_BOAT"; "SPRUCE_CHEST_BOAT"; "SQUID"; "STRAY"; "STRIDER";
    "SULFUR_CUBE"; "TADPOLE"; "TEXT_DISPLAY"; "TNT"; "TNT_MINECART"; "TRADER_LLAMA";
    "TRIDENT"; "TROPICAL_FISH"; "TURTLE"; "VEX"; "VILLAGER"; "VINDICATOR";
    "WANDERING_TRADER"; "WARDEN"; "WIND_CHARGE"; "WITCH"; "WITHER"; "WITHER_SKELETON";
    "WITHER_SKULL"; "WOLF"; "ZOGLIN"; "ZOMBIE"; "ZOMBIE_HORSE"; "ZOMBIE_NAUTILUS";
    "ZOMBIE_VILLAGER"; "ZOMBIFIED_PIGLIN";
  ]

(* "ZOMBIE", "zombie", and "minecraft:zombie" all name the same EntityType *)
let normalize_entity_type s =
  let s =
    match String.index_opt s ':' with
    | Some i -> String.sub s (i + 1) (String.length s - i - 1)
    | None -> s
  in
  String.uppercase_ascii s

let entity_type_exists s = List.mem (normalize_entity_type s) entity_types

(* --- caps --- *)

let sidebar_max_lines = 15
let tablist_column_max_entries = 20

(* 'fill blocks' warns when a literal volume exceeds this many blocks
   (design 6D: bounded volume cap, checker warns big literals) *)
let fill_blocks_warn_volume = 100_000

(* --- editor-facing language surface (swoftc --dump-symbols) ---

   The single source of truth for grammar + LSP: every list below is pulled from
   the real registry/parser structures in this file (builtins, the ty algebra,
   the handler/callback tables, the property tables via props_of_ty, and the enum
   value lists) so the emitted JSON can never drift from what the compiler
   actually accepts. The three lexically-fixed surfaces that live in the
   lexer/parser rather than as data (control/statement keywords, top-level
   declaration keywords, and the freeform namespaces) are canonicalized here so
   this module owns them too. *)

(* control-flow + statement-verb keyword surface. Hard keywords come from the
   lexer keyword_table (lexer.mll); the statement verbs are the soft keywords the
   statement parser (parse_stmt.ml) matches; command/event/on/every/schedule are
   the control-side declaration/handler heads. Kept here as the LSP source of
   truth. *)
let control_keywords =
  [
    (* declaration/handler heads that read as control keywords *)
    "command"; "event"; "on"; "every"; "schedule";
    (* control flow *)
    "if"; "else"; "loop"; "while"; "times"; "function"; "return"; "call";
    (* module machinery *)
    "import"; "export"; "var";
    (* core statement verbs *)
    "set"; "send"; "broadcast"; "reply"; "teleport"; "spawn"; "launch"; "give";
    "show"; "hide"; "wait"; "cancel"; "stop"; "halt"; "place"; "remove"; "add";
    "clear"; "delete"; "create"; "open"; "close"; "play"; "move"; "go"; "save";
    "load"; "unload"; "update"; "reset"; "title"; "actionbar"; "fill"; "clone";
    "replace"; "despawn"; "destroy"; "mount"; "dismount"; "dispense"; "draw";
    "repeat"; "skin"; "name"; "line"; "entry"; "blank"; "belowname"; "fade";
    (* W-pvp combat verbs *)
    "damage"; "knock"; "apply"; "shoot";
    (* boolean / logical / relational operators (word form) *)
    "is"; "not"; "and"; "or"; "either"; "contains"; "as"; "to"; "in"; "of";
    "all"; "players"; "true"; "false";
  ]

(* W-collections: the natural-language collection-operation words. These are
   context-sensitive SOFT keywords (legal variable names elsewhere), so they are
   deliberately NOT in control_keywords; the symbol dump advertises them under a
   separate 'collection_ops' key so the editor grammar/LSP can color and complete
   them as collection operators without the parser reserving them globally. 'of'
   also appears in control_keywords as a general connective; listing it here too
   is harmless (both surfaces color it a keyword). *)
let collection_ops = [ "of"; "has"; "sorted"; "reversed"; "first"; "last" ]

(* the top-level declaration keywords, mirroring the dispatch in parser.ml. Every
   one opens a first-class declaration block. *)
let declaration_keywords =
  [
    "item"; "mob"; "npc"; "hologram"; "gui"; "scoreboard"; "tablist"; "bossbar";
    "server"; "storage"; "persistent"; "api"; "fishing_loot"; "block_handler";
    "placement_rule";
  ]

(* the freeform per-object namespaces reachable as <obj>.<ns>.<key>: .tags
   (TItemTags/TEntityTags), .tasks (TTasks, the Schedule registry), and the
   combat 'attributes' surfaced as direct rw properties (combat_attribute_names). *)
let namespaces = [ "tags"; "tasks"; "attributes" ]

(* the named + generic type surface. Named types are their ty_to_string spelling;
   the generic constructors (list/map/optional/either) are the type keywords the
   type parser accepts. *)
let type_names =
  List.map ty_to_string
    [
      TString; TInteger; TDouble; TBoolean; TPlayer; TOfflinePlayer; TLocation;
      TItem; TWorld; TMob; TEntity; TDisplay; TVec; TBlock; TSchedule; TSong;
      TServer; TSkin; TCanvas;
    ]
  @ [ "list"; "map"; "optional"; "either" ]

(* every inline handler name across the four declaration kinds plus the
   block_handler / placement_rule callbacks, deduped — the on_* surface. *)
let all_handler_names =
  let from_kinds =
    List.concat_map handler_names [ KMob; KItem; KHologram; KNpc ]
  in
  let from_block_cbs =
    block_cb_names block_handler_cbs @ block_cb_names placement_rule_cbs
  in
  (* the OOP base-receiver method surface (on_join, on_dispense, on_tps_change,
     ...) — every capitalized receiver's methods, so the editor colors/completes
     them exactly like the inline-handler names *)
  let from_receivers = List.concat_map receiver_method_names all_receiver_kinds in
  List.sort_uniq compare (from_kinds @ from_block_cbs @ from_receivers)

(* the capitalized receiver block heads exposed to the editor: the 11 base-type
   receivers plus the special `Packet` raw-packet receiver. *)
let receiver_keyword_names = receiver_type_names @ [ "Packet" ]

(* the property-bearing owner types exposed to the editor: (display name, ty).
   Rows come straight from props_of_ty so they can never drift. *)
let property_owner_types =
  [
    ("Player", TPlayer);
    ("OfflinePlayer", TOfflinePlayer);
    ("Mob", TMob);
    ("Entity", TEntity);
    ("Item", TItem);
    ("Block", TBlock);
    ("Location", TLocation);
    ("World", TWorld);
    ("Vec", TVec);
    ("Display", TDisplay);
    ("Skin", TSkin);
    ("Song", TSong);
    ("Server", TServer);
    ("Canvas", TCanvas);
    ("Request", TRequest);
  ]

let dump_symbols_json () : Yojson.Safe.t =
  let jstrings xs = `List (List.map (fun s -> `String s) xs) in
  let props_json ty =
    match props_of_ty ty with
    | None -> `List []
    | Some props ->
      `List
        (List.map
           (fun p ->
             `Assoc
               [
                 ("name", `String p.p_name);
                 ("type", `String (ty_to_string p.p_ty));
                 ("writable", `Bool p.p_writable);
               ])
           props)
  in
  `Assoc
    [
      ("keywords", jstrings control_keywords);
      ("collection_ops", jstrings collection_ops);
      ("declarations", jstrings declaration_keywords);
      ("receivers", jstrings receiver_keyword_names);
      ("handlers", jstrings all_handler_names);
      ("builtins", jstrings (List.map (fun bl -> bl.b_name) builtins));
      ("types", jstrings type_names);
      ("namespaces", jstrings namespaces);
      ( "properties",
        `Assoc (List.map (fun (name, ty) -> (name, props_json ty)) property_owner_types) );
      (* the Packet catalog for the LSP: keyed by simple class name (the `on
         "..."` spelling), each value the typed field list so the editor can
         complete class names in `on "..."`, complete `packet.<field>`, and
         scaffold a packet's fields. Rows come straight from packet_fields_tbl so
         they can never drift from what the compiler accepts. *)
      ( "packets",
        `Assoc
          (List.sort
             (fun (a, _) (b, _) -> compare a b)
             (Hashtbl.fold
                (fun simple fq acc ->
                  let fields =
                    List.map
                      (fun p ->
                        `Assoc
                          [
                            ("name", `String p.p_name);
                            ("type", `String (ty_to_string p.p_ty));
                          ])
                      (packet_fields fq)
                  in
                  (simple, `List fields) :: acc)
                packet_simple_to_fq [])) );
      ( "enums",
        `Assoc
          [
            ("gamemode", jstrings gamemodes);
            ("rarity", jstrings rarities);
            ("ai", jstrings mob_ais);
            ("billboard", jstrings display_billboards);
            ("alignment", jstrings display_alignments);
            ("weather", jstrings weather_states);
            ("pose", jstrings entity_poses);
            ("hand", jstrings hands);
            ("block_face", jstrings block_faces);
            ("bossbar_color", jstrings bossbar_colors);
            ("bossbar_style", jstrings bossbar_styles);
            ("nametag_color", jstrings nametag_colors);
            ("api_method", jstrings api_methods);
            ("toast_frame", jstrings toast_frames);
            ("fishing_medium", jstrings fishing_mediums);
            ("projectile_type", jstrings projectile_types);
            ("damage_types", jstrings damage_type_names);
            ("effect_types", jstrings potion_effect_names);
            ("attribute_keys", jstrings combat_attribute_names);
            ("modifier_operations", jstrings attribute_operations);
            ("item_attribute_keys", jstrings item_attribute_names);
            ("entity_types", jstrings entity_types);
          ] );
    ]

(* --- shared JSON fixture (test/property-table.json) --- *)

let property_table_json () : Yojson.Safe.t =
  let owner_rows owner props =
    List.map
      (fun p ->
        `Assoc
          [
            ("owner", `String owner);
            ("name", `String p.p_name);
            ("type", `String (ty_to_string p.p_ty));
            ("writable", `Bool p.p_writable);
          ])
      props
  in
  `List
    (owner_rows "Player" (dedup_props player_props combat_entity_extra)
    @ owner_rows "Location" location_props
    @ owner_rows "Item" item_props
    @ owner_rows "Mob" (dedup_props (mob_props @ mob_extra_props) combat_entity_extra)
    @ owner_rows "World" world_props
    @ owner_rows "Display" display_props
    @ owner_rows "Request" request_props
    @ owner_rows "Song" song_props
    @ owner_rows "Server" server_props
    @ owner_rows "Skin" skin_props
    @ owner_rows "Canvas" canvas_props
    @ owner_rows "Entity" (dedup_props entity_props combat_entity_extra)
    @ owner_rows "Vec" vec_props
    @ owner_rows "OfflinePlayer" offline_player_props
    @ List.concat_map (fun e -> owner_rows ("event:" ^ e.e_name) e.e_props) events)
