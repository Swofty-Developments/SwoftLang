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
  | TVec (* an x/y/z velocity vector from velocity(x, y, z) (phase 7) *)
  | TOfflinePlayer (* a seen-store player record (phase 8); Player is a subtype *)
  | TEvent of string
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
  | TVec -> "Vec"
  | TOfflinePlayer -> "OfflinePlayer"
  | TEvent name -> "event<" ^ name ^ ">"
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
    (* freeform entity tags: mob.tags.<path> / entity.tags.<path>, same shape as
       item tags — optional<Any> reads, writable, 'set ... to none' deletes *)
    ro "tags" TEntityTags;
  ]

(* the Entity rows a Mob does not declare itself, composed onto Mob property
   lookup (Mob <: Entity): so event.mob.uuid / set mob.gravity typecheck while
   the mob's own typed rows (health/name/...) keep priority *)
let mob_extra_props =
  List.filter
    (fun p -> not (List.exists (fun q -> q.p_name = p.p_name) mob_props))
    entity_props

(* velocity vectors (phase 7): blocks-per-tick components *)
let vec_props = [ rw "x" TDouble; rw "y" TDouble; rw "z" TDouble ]

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

let props_of_ty = function
  (* Player <: OfflinePlayer (phase 8): the OfflinePlayer-only rows compose
     onto Player values *)
  | TPlayer -> Some (player_props @ offline_extra_props)
  | TOfflinePlayer -> Some offline_player_props
  | TLocation -> Some location_props
  | TItem -> Some item_props
  (* Mob <: Entity (phase 7): the Entity-only rows compose onto Mob values *)
  | TMob -> Some (mob_props @ mob_extra_props)
  | TItemTags -> Some []
  | TEntityTags -> Some []
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
  | TEntity -> Some entity_props
  | TVec -> Some vec_props
  | TEvent name -> (
    match find_event name with
    | Some e -> Some e.e_props
    | None -> Some [])
  | _ -> None

let find_prop owner name =
  (* item.tags.<key> is a freeform NBT namespace: any key resolves, writable;
     reads are optional<Any> — an absent tag is none (phase 9), so the no-null
     discipline (exists/otherwise) extends to NBT *)
  if owner = TItemTags || owner = TEntityTags then
    Some { p_name = name; p_ty = TOptional TAny; p_writable = true }
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
  [ hs "on_click" [ ("player", TPlayer) ]; hs "on_line_click" [ ("player", TPlayer); ("line", TInteger) ] ]

(* NPC: both handlers already shipped (dedicated fields); reconciled here. *)
let npc_handlers =
  [ hs "on_click" [ ("player", TPlayer) ]; hs "on_left_click" [ ("player", TPlayer) ] ]

let handlers_for = function
  | KMob -> mob_handlers
  | KItem -> item_handlers
  | KHologram -> hologram_handlers
  | KNpc -> npc_handlers

let find_handler kind name = List.find_opt (fun h -> h.h_event = name) (handlers_for kind)
let handler_names kind = List.map (fun h -> h.h_event) (handlers_for kind)

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
    b "block_at" [ ([ PLoc ], RTy TString) ];
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
    (* map_get/map_set/map_has/map_delete/map_keys/map_size are handled
       specially in Tc_expr (their result type depends on the map's key/value
       type), but they still resolve here so name-collision checks see them *)
    b "map_get" [ ([ PStr; PStr ], RTy (TOptional TAny)) ];
    b "map_set" [ ([ PStr; PStr; PStr ], RTy TAny) ];
    b "map_has" [ ([ PStr; PStr ], RTy TBoolean) ];
    b "map_delete" [ ([ PStr; PStr ], RTy TAny) ];
    b "map_keys" [ ([ PStr ], RTy (TList TString)) ];
    b "map_size" [ ([ PStr ], RTy TInteger) ];
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
    (* --- phase-11 scheduler v2: liveness check by handle or name --- *)
    b "is_running" [ ([ PSchedOrName ], RTy TBoolean) ];
    (* --- phase-10 item <-> NBT string (persist item stacks) --- *)
    b "to_nbt" [ ([ PItem ], RTy TString) ];
    b "from_nbt" [ ([ PStr ], RTy (TOptional TItem)) ];
  ]

let find_builtin name = List.find_opt (fun bl -> bl.b_name = name) builtins

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
    (owner_rows "Player" player_props
    @ owner_rows "Location" location_props
    @ owner_rows "Item" item_props
    @ owner_rows "Mob" (mob_props @ mob_extra_props)
    @ owner_rows "World" world_props
    @ owner_rows "Display" display_props
    @ owner_rows "Request" request_props
    @ owner_rows "Song" song_props
    @ owner_rows "Server" server_props
    @ owner_rows "Skin" skin_props
    @ owner_rows "Canvas" canvas_props
    @ owner_rows "Entity" entity_props
    @ owner_rows "Vec" vec_props
    @ owner_rows "OfflinePlayer" offline_player_props
    @ List.concat_map (fun e -> owner_rows ("event:" ^ e.e_name) e.e_props) events)
