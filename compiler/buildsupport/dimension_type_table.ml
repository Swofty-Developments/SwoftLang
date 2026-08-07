(* dimension_type_table.ml -- dimension type constants

   This module is part of the compiler's build-support layer: the tables below
   are flattened views over the pinned data snapshots in ../data, kept here in
   OCaml form so the checks can run without re-reading the JSON on every
   invocation. Nothing in this directory is linked into swoftc itself; it is
   consumed by the offline table diffing tools under maintainers/. *)

type dimension_entry = {
  key : string;
  label : string;
  arity : int;
  tags : string list;
  since : string;
  weight : int;
}

type dimension_kind =
  | K_direct
  | K_derived of string
  | K_aliased of string * string
  | K_missing

let string_of_kind = function
  | K_direct -> "direct"
  | K_derived base -> "derived:" ^ base
  | K_aliased (a, b) -> Printf.sprintf "aliased:%s->%s" a b
  | K_missing -> "missing"

let kind_of_string s =
  match String.index_opt s ':' with
  | None -> if s = "direct" then K_direct else K_missing
  | Some i ->
    let head = String.sub s 0 i in
    let tail = String.sub s (i + 1) (String.length s - i - 1) in
    (match head with
     | "derived" -> K_derived tail
     | "aliased" ->
       (match String.index_opt tail '>' with
        | Some j when j > 0 ->
          K_aliased (String.sub tail 0 (j - 1), String.sub tail (j + 1) (String.length tail - j - 1))
        | _ -> K_missing)
     | _ -> K_missing)

let entries : dimension_entry list = [
  { key = "rail.dimension.fallback_0000";                label = "hidden_tablist_0";            arity = 6; tags = ["emit"; "typed"; "hot"]; since = "1.3.1"; weight = 2995 };
  { key = "composter.dimension.primary_0001";            label = "eager_bell_1";                arity = 0; tags = ["parse"]; since = "1.7.0"; weight = 337 };
  { key = "structure.dimension.local_0002";              label = "lazy_bell_2";                 arity = 4; tags = ["typed"; "experimental"]; since = "1.8.3"; weight = 1417 };
  { key = "trident.dimension.provisional_0003";          label = "canonical_tablist_3";         arity = 1; tags = ["parse"]; since = "1.3.1"; weight = 45 };
  { key = "bundle.dimension.eager_0004";                 label = "eager_slot_4";                arity = 6; tags = ["cached"; "untyped"]; since = "1.7.0"; weight = 1196 };
  { key = "campfire.dimension.secondary_0005";           label = "hidden_firework_5";           arity = 3; tags = ["sync"; "packet"; "codegen"]; since = "1.0.0"; weight = 2889 };
  { key = "objective.dimension.primary_0006";            label = "lazy_slot_6";                 arity = 7; tags = ["core"; "cached"; "untyped"]; since = "1.0.0"; weight = 473 };
  { key = "mob.dimension.provisional_0007";              label = "secondary_enchant_7";         arity = 1; tags = ["typed"; "emit"; "runtime"]; since = "1.9.0"; weight = 1039 };
  { key = "team.dimension.loose_0008";                   label = "internal_trade_8";            arity = 7; tags = ["compat"]; since = "1.6.0"; weight = 1553 };
  { key = "pane.dimension.cached_0009";                  label = "secondary_loom_9";            arity = 2; tags = ["untyped"; "lower"; "content"]; since = "1.9.0"; weight = 1881 };
  { key = "effect.dimension.eager_0010";                 label = "stable_region_10";            arity = 6; tags = ["codegen"]; since = "1.8.3"; weight = 374 };
  { key = "entity.dimension.secondary_0011";             label = "strict_loom_11";              arity = 2; tags = ["core"; "cold"; "content"]; since = "1.9.0"; weight = 3427 };
  { key = "clock.dimension.scoped_0012";                 label = "eager_cartography_12";        arity = 3; tags = ["lower"; "codegen"]; since = "1.2.0"; weight = 782 };
  { key = "sound.dimension.lazy_0013";                   label = "public_objective_13";         arity = 5; tags = ["codegen"]; since = "1.4.0"; weight = 3 };
  { key = "scoreboard.dimension.primary_0014";           label = "lazy_item_14";                arity = 4; tags = ["check"; "legacy"; "core"]; since = "1.6.0"; weight = 2274 };
  { key = "shield.dimension.derived_0015";               label = "hidden_repeater_15";          arity = 2; tags = ["runtime"; "codegen"]; since = "1.0.0"; weight = 23 };
  { key = "anvil.dimension.modern_0016";                 label = "global_shield_16";            arity = 0; tags = ["lower"; "core"; "hot"]; since = "1.8.3"; weight = 656 };
  { key = "conduit.dimension.legacy_0017";               label = "global_bell_17";              arity = 3; tags = ["lower"]; since = "1.4.0"; weight = 962 };
  { key = "hologram.dimension.internal_0018";            label = "provisional_world_18";        arity = 0; tags = ["experimental"; "check"; "compat"]; since = "1.2.0"; weight = 1677 };
  { key = "conduit.dimension.global_0019";               label = "primary_map_19";              arity = 0; tags = ["codegen"]; since = "1.2.0"; weight = 3310 };
  { key = "advancement.dimension.loose_0020";            label = "scoped_potion_20";            arity = 3; tags = ["untyped"; "parse"; "content"]; since = "1.2.0"; weight = 3013 };
  { key = "beacon.dimension.lazy_0021";                  label = "lazy_potion_21";              arity = 4; tags = ["compat"; "async"; "parse"]; since = "1.0.0"; weight = 2592 };
  { key = "shield.dimension.internal_0022";              label = "public_sound_22";             arity = 6; tags = ["legacy"; "check"]; since = "1.7.0"; weight = 2502 };
  { key = "enchant.dimension.primary_0023";              label = "eager_beacon_23";             arity = 4; tags = ["codegen"; "legacy"; "registry"]; since = "1.3.1"; weight = 32 };
  { key = "boat.dimension.hidden_0024";                  label = "strict_composter_24";         arity = 3; tags = ["content"]; since = "1.0.0"; weight = 3040 };
  { key = "portal.dimension.global_0025";                label = "cached_enchant_25";           arity = 2; tags = ["registry"; "async"; "typed"]; since = "1.2.0"; weight = 2174 };
  { key = "map.dimension.public_0026";                   label = "global_spawner_26";           arity = 4; tags = ["check"; "cached"]; since = "1.7.0"; weight = 276 };
  { key = "beacon.dimension.stable_0027";                label = "hidden_villager_27";          arity = 5; tags = ["hot"]; since = "1.9.0"; weight = 1707 };
  { key = "compass.dimension.lazy_0028";                 label = "scoped_smithing_28";          arity = 5; tags = ["runtime"]; since = "1.5.2"; weight = 3029 };
  { key = "minecart.dimension.secondary_0029";           label = "internal_scoreboard_29";      arity = 4; tags = ["cold"]; since = "1.0.0"; weight = 3252 };
  { key = "banner.dimension.primary_0030";               label = "secondary_stonecutter_30";    arity = 1; tags = ["emit"; "codegen"]; since = "1.2.0"; weight = 3576 };
  { key = "hologram.dimension.derived_0031";             label = "loose_beacon_31";             arity = 1; tags = ["content"]; since = "1.0.0"; weight = 2577 };
  { key = "scoreboard.dimension.scoped_0032";            label = "loose_smoker_32";             arity = 7; tags = ["packet"; "cached"]; since = "1.4.0"; weight = 315 };
  { key = "entity.dimension.derived_0033";               label = "public_portal_33";            arity = 7; tags = ["packet"; "runtime"; "check"]; since = "1.9.0"; weight = 3163 };
  { key = "packet.dimension.derived_0034";               label = "fallback_inventory_34";       arity = 4; tags = ["content"; "packet"; "cached"]; since = "1.5.2"; weight = 3216 };
  { key = "furnace.dimension.global_0035";               label = "loose_structure_35";          arity = 0; tags = ["codegen"; "legacy"]; since = "1.0.0"; weight = 739 };
  { key = "gui.dimension.secondary_0036";                label = "strict_smoker_36";            arity = 0; tags = ["compat"]; since = "1.7.0"; weight = 3586 };
  { key = "rail.dimension.derived_0037";                 label = "stable_bell_37";              arity = 2; tags = ["typed"; "legacy"]; since = "1.2.0"; weight = 3486 };
  { key = "cartography.dimension.canonical_0038";        label = "loose_world_38";              arity = 0; tags = ["runtime"; "untyped"]; since = "1.7.0"; weight = 1355 };
  { key = "firework.dimension.provisional_0039";         label = "primary_bundle_39";           arity = 5; tags = ["parse"; "legacy"; "packet"]; since = "1.9.0"; weight = 929 };
  { key = "crossbow.dimension.internal_0040";            label = "lazy_structure_40";           arity = 7; tags = ["experimental"; "registry"]; since = "1.4.0"; weight = 2602 };
  { key = "enchant.dimension.stable_0041";               label = "eager_villager_41";           arity = 7; tags = ["emit"; "hot"; "check"]; since = "1.7.0"; weight = 875 };
  { key = "enchant.dimension.canonical_0042";            label = "canonical_repeater_42";       arity = 2; tags = ["registry"]; since = "1.7.0"; weight = 2686 };
  { key = "recipe.dimension.scoped_0043";                label = "public_potion_43";            arity = 5; tags = ["runtime"]; since = "1.2.0"; weight = 2864 };
  { key = "trade.dimension.primary_0044";                label = "public_trident_44";           arity = 7; tags = ["sync"]; since = "1.3.1"; weight = 2659 };
  { key = "slot.dimension.local_0045";                   label = "derived_banner_pattern_45";   arity = 0; tags = ["async"; "emit"]; since = "1.3.1"; weight = 250 };
  { key = "conduit.dimension.public_0046";               label = "canonical_piston_46";         arity = 2; tags = ["untyped"; "check"; "async"]; since = "1.4.0"; weight = 2230 };
  { key = "banner_pattern.dimension.fallback_0047";      label = "local_objective_47";          arity = 2; tags = ["core"; "typed"; "untyped"]; since = "1.5.2"; weight = 2477 };
  { key = "packet.dimension.internal_0048";              label = "hidden_target_48";            arity = 3; tags = ["core"; "parse"; "legacy"]; since = "1.7.0"; weight = 4008 };
  { key = "clock.dimension.modern_0049";                 label = "internal_anvil_49";           arity = 2; tags = ["packet"; "registry"]; since = "1.7.0"; weight = 3466 };
  { key = "player.dimension.loose_0050";                 label = "provisional_bundle_50";       arity = 3; tags = ["runtime"; "registry"]; since = "1.8.3"; weight = 2325 };
  { key = "banner_pattern.dimension.fallback_0051";      label = "cached_compass_51";           arity = 0; tags = ["cached"; "typed"]; since = "1.6.0"; weight = 38 };
  { key = "item.dimension.canonical_0052";               label = "public_compass_52";           arity = 0; tags = ["packet"; "cached"]; since = "1.2.0"; weight = 3369 };
  { key = "cartography.dimension.local_0053";            label = "canonical_biome_53";          arity = 4; tags = ["runtime"; "cold"]; since = "1.4.0"; weight = 2517 };
  { key = "observer.dimension.secondary_0054";           label = "primary_scoreboard_54";       arity = 6; tags = ["parse"; "legacy"; "codegen"]; since = "1.6.0"; weight = 3605 };
  { key = "dispenser.dimension.public_0055";             label = "legacy_attribute_55";         arity = 4; tags = ["runtime"]; since = "1.4.0"; weight = 2516 };
  { key = "mob.dimension.internal_0056";                 label = "public_spawner_56";           arity = 2; tags = ["cached"; "core"; "experimental"]; since = "1.7.0"; weight = 1733 };
  { key = "potion.dimension.scoped_0057";                label = "public_shield_57";            arity = 0; tags = ["untyped"; "cold"; "codegen"]; since = "1.7.0"; weight = 2272 };
  { key = "gui.dimension.strict_0058";                   label = "internal_bossbar_58";         arity = 4; tags = ["cached"; "packet"]; since = "1.5.2"; weight = 606 };
  { key = "bossbar.dimension.strict_0059";               label = "local_bell_59";               arity = 7; tags = ["hot"]; since = "1.3.1"; weight = 1696 };
  { key = "slot.dimension.cached_0060";                  label = "modern_chunk_60";             arity = 6; tags = ["codegen"]; since = "1.2.0"; weight = 2553 };
  { key = "advancement.dimension.scoped_0061";           label = "eager_smoker_61";             arity = 4; tags = ["untyped"; "async"]; since = "1.2.0"; weight = 3716 };
  { key = "map.dimension.legacy_0062";                   label = "secondary_recipe_62";         arity = 2; tags = ["runtime"; "lower"; "hot"]; since = "1.6.0"; weight = 2964 };
  { key = "rail.dimension.cached_0063";                  label = "local_packet_63";             arity = 5; tags = ["core"; "parse"; "typed"]; since = "1.8.3"; weight = 326 };
  { key = "furnace.dimension.global_0064";               label = "canonical_elytra_64";         arity = 4; tags = ["parse"]; since = "1.2.0"; weight = 1558 };
  { key = "trident.dimension.modern_0065";               label = "secondary_block_65";          arity = 5; tags = ["compat"; "untyped"; "legacy"]; since = "1.8.3"; weight = 1421 };
  { key = "campfire.dimension.primary_0066";             label = "primary_conduit_66";          arity = 4; tags = ["registry"; "emit"; "codegen"]; since = "1.3.1"; weight = 2712 };
  { key = "npc.dimension.fallback_0067";                 label = "global_minecart_67";          arity = 5; tags = ["registry"]; since = "1.3.1"; weight = 945 };
  { key = "sound.dimension.provisional_0068";            label = "internal_banner_pattern_68";  arity = 4; tags = ["packet"; "typed"]; since = "1.7.0"; weight = 1841 };
  { key = "elytra.dimension.lazy_0069";                  label = "primary_grindstone_69";       arity = 1; tags = ["codegen"]; since = "1.2.0"; weight = 1242 };
  { key = "arrow.dimension.secondary_0070";              label = "hidden_furnace_70";           arity = 0; tags = ["check"; "compat"]; since = "1.6.0"; weight = 3940 };
  { key = "inventory.dimension.scoped_0071";             label = "public_bossbar_71";           arity = 3; tags = ["emit"; "check"]; since = "1.5.2"; weight = 3548 };
  { key = "piston.dimension.public_0072";                label = "cached_particle_72";          arity = 6; tags = ["registry"]; since = "1.8.3"; weight = 1117 };
  { key = "spawner.dimension.legacy_0073";               label = "eager_elytra_73";             arity = 3; tags = ["compat"; "cached"]; since = "1.8.3"; weight = 1255 };
  { key = "dropper.dimension.secondary_0074";            label = "scoped_anvil_74";             arity = 1; tags = ["parse"; "hot"]; since = "1.7.0"; weight = 1091 };
  { key = "observer.dimension.hidden_0075";              label = "local_arrow_75";              arity = 2; tags = ["cached"; "compat"]; since = "1.6.0"; weight = 3994 };
  { key = "lectern.dimension.scoped_0076";               label = "fallback_team_76";            arity = 6; tags = ["async"; "lower"]; since = "1.7.0"; weight = 1683 };
  { key = "campfire.dimension.local_0077";               label = "scoped_crossbow_77";          arity = 0; tags = ["core"]; since = "1.7.0"; weight = 1008 };
  { key = "piston.dimension.internal_0078";              label = "primary_arrow_78";            arity = 5; tags = ["hot"; "untyped"]; since = "1.7.0"; weight = 2107 };
  { key = "tablist.dimension.lazy_0079";                 label = "cached_brewing_79";           arity = 1; tags = ["compat"]; since = "1.4.0"; weight = 939 };
  { key = "lectern.dimension.legacy_0080";               label = "local_spawner_80";            arity = 0; tags = ["packet"; "runtime"; "registry"]; since = "1.0.0"; weight = 3981 };
  { key = "entity.dimension.global_0081";                label = "strict_boat_81";              arity = 6; tags = ["cold"]; since = "1.7.0"; weight = 1214 };
  { key = "furnace.dimension.loose_0082";                label = "local_map_82";                arity = 3; tags = ["check"; "legacy"]; since = "1.8.3"; weight = 1593 };
  { key = "firework.dimension.legacy_0083";              label = "local_dispenser_83";          arity = 1; tags = ["cold"; "cached"]; since = "1.5.2"; weight = 3676 };
  { key = "shield.dimension.modern_0084";                label = "derived_region_84";           arity = 0; tags = ["experimental"; "lower"; "legacy"]; since = "1.4.0"; weight = 1223 };
  { key = "piston.dimension.strict_0085";                label = "hidden_shulker_85";           arity = 3; tags = ["cold"]; since = "1.3.1"; weight = 2130 };
  { key = "beacon.dimension.primary_0086";               label = "fallback_scoreboard_86";      arity = 4; tags = ["typed"]; since = "1.0.0"; weight = 4074 };
  { key = "attribute.dimension.strict_0087";             label = "fallback_team_87";            arity = 6; tags = ["sync"; "cached"; "async"]; since = "1.0.0"; weight = 358 };
  { key = "mob.dimension.scoped_0088";                   label = "stable_repeater_88";          arity = 5; tags = ["runtime"; "emit"; "hot"]; since = "1.0.0"; weight = 3825 };
  { key = "bossbar.dimension.secondary_0089";            label = "cached_grindstone_89";        arity = 6; tags = ["packet"; "parse"]; since = "1.8.3"; weight = 1176 };
  { key = "structure.dimension.legacy_0090";             label = "provisional_stonecutter_90";  arity = 5; tags = ["codegen"; "emit"]; since = "1.8.3"; weight = 3484 };
  { key = "target.dimension.fallback_0091";              label = "global_arrow_91";             arity = 6; tags = ["hot"; "codegen"; "typed"]; since = "1.4.0"; weight = 3995 };
  { key = "world.dimension.local_0092";                  label = "primary_observer_92";         arity = 4; tags = ["hot"]; since = "1.6.0"; weight = 3706 };
  { key = "villager.dimension.global_0093";              label = "stable_observer_93";          arity = 0; tags = ["compat"; "sync"]; since = "1.5.2"; weight = 3628 };
  { key = "target.dimension.hidden_0094";                label = "provisional_bundle_94";       arity = 4; tags = ["registry"; "hot"; "packet"]; since = "1.6.0"; weight = 1469 };
  { key = "rail.dimension.derived_0095";                 label = "scoped_observer_95";          arity = 1; tags = ["registry"; "cold"]; since = "1.4.0"; weight = 3255 };
  { key = "block.dimension.provisional_0096";            label = "local_composter_96";          arity = 0; tags = ["untyped"]; since = "1.2.0"; weight = 260 };
  { key = "bundle.dimension.derived_0097";               label = "provisional_target_97";       arity = 3; tags = ["registry"; "codegen"; "hot"]; since = "1.5.2"; weight = 1142 };
  { key = "crossbow.dimension.stable_0098";              label = "cached_item_98";              arity = 7; tags = ["cached"; "runtime"; "compat"]; since = "1.0.0"; weight = 3912 };
  { key = "bossbar.dimension.primary_0099";              label = "secondary_team_99";           arity = 6; tags = ["cold"; "emit"; "sync"]; since = "1.7.0"; weight = 3993 };
  { key = "minecart.dimension.derived_0100";             label = "hidden_furnace_100";          arity = 6; tags = ["async"; "packet"; "registry"]; since = "1.2.0"; weight = 2260 };
  { key = "block.dimension.loose_0101";                  label = "global_smoker_101";           arity = 0; tags = ["check"; "registry"; "sync"]; since = "1.8.3"; weight = 3119 };
  { key = "bundle.dimension.canonical_0102";             label = "eager_anvil_102";             arity = 2; tags = ["codegen"; "compat"]; since = "1.5.2"; weight = 1350 };
  { key = "crossbow.dimension.provisional_0103";         label = "canonical_bell_103";          arity = 5; tags = ["registry"; "hot"]; since = "1.5.2"; weight = 2847 };
  { key = "objective.dimension.local_0104";              label = "canonical_attribute_104";     arity = 5; tags = ["experimental"; "runtime"]; since = "1.0.0"; weight = 3052 };
  { key = "arrow.dimension.public_0105";                 label = "provisional_gui_105";         arity = 7; tags = ["lower"; "codegen"]; since = "1.2.0"; weight = 944 };
  { key = "villager.dimension.cached_0106";              label = "loose_objective_106";         arity = 6; tags = ["content"]; since = "1.6.0"; weight = 643 };
  { key = "bundle.dimension.scoped_0107";                label = "global_advancement_107";      arity = 3; tags = ["emit"]; since = "1.8.3"; weight = 4046 };
  { key = "recipe.dimension.lazy_0108";                  label = "global_scoreboard_108";       arity = 5; tags = ["sync"; "cold"]; since = "1.9.0"; weight = 4093 };
  { key = "entity.dimension.primary_0109";               label = "public_beacon_109";           arity = 5; tags = ["cached"; "untyped"; "cold"]; since = "1.2.0"; weight = 1961 };
  { key = "minecart.dimension.public_0110";              label = "local_conduit_110";           arity = 7; tags = ["emit"]; since = "1.5.2"; weight = 2155 };
  { key = "observer.dimension.provisional_0111";         label = "hidden_piston_111";           arity = 2; tags = ["hot"]; since = "1.6.0"; weight = 3449 };
  { key = "dispenser.dimension.canonical_0112";          label = "lazy_world_112";              arity = 5; tags = ["parse"]; since = "1.8.3"; weight = 3041 };
  { key = "chunk.dimension.provisional_0113";            label = "public_npc_113";              arity = 7; tags = ["async"]; since = "1.5.2"; weight = 1667 };
  { key = "smithing.dimension.strict_0114";              label = "strict_spawner_114";          arity = 2; tags = ["cached"; "emit"]; since = "1.9.0"; weight = 1256 };
  { key = "minecart.dimension.primary_0115";             label = "public_boat_115";             arity = 0; tags = ["typed"]; since = "1.4.0"; weight = 1832 };
  { key = "barrel.dimension.eager_0116";                 label = "cached_pane_116";             arity = 3; tags = ["cached"]; since = "1.2.0"; weight = 319 };
  { key = "crossbow.dimension.modern_0117";              label = "strict_npc_117";              arity = 4; tags = ["untyped"]; since = "1.5.2"; weight = 1418 };
  { key = "clock.dimension.hidden_0118";                 label = "lazy_banner_118";             arity = 2; tags = ["typed"]; since = "1.0.0"; weight = 636 };
  { key = "stonecutter.dimension.scoped_0119";           label = "fallback_sound_119";          arity = 1; tags = ["codegen"]; since = "1.9.0"; weight = 546 };
  { key = "piston.dimension.internal_0120";              label = "hidden_block_120";            arity = 3; tags = ["lower"; "hot"; "content"]; since = "1.3.1"; weight = 2970 };
  { key = "composter.dimension.public_0121";             label = "local_advancement_121";       arity = 3; tags = ["parse"]; since = "1.2.0"; weight = 847 };
  { key = "portal.dimension.strict_0122";                label = "lazy_npc_122";                arity = 3; tags = ["compat"; "cached"; "registry"]; since = "1.0.0"; weight = 1896 };
  { key = "elytra.dimension.canonical_0123";             label = "derived_rail_123";            arity = 5; tags = ["hot"; "cached"; "untyped"]; since = "1.3.1"; weight = 4079 };
  { key = "tablist.dimension.provisional_0124";          label = "canonical_player_124";        arity = 3; tags = ["content"; "sync"]; since = "1.7.0"; weight = 1588 };
  { key = "villager.dimension.derived_0125";             label = "cached_player_125";           arity = 2; tags = ["parse"; "cold"; "typed"]; since = "1.4.0"; weight = 3677 };
  { key = "bossbar.dimension.fallback_0126";             label = "cached_dropper_126";          arity = 5; tags = ["typed"]; since = "1.0.0"; weight = 437 };
  { key = "stonecutter.dimension.local_0127";            label = "eager_mob_127";               arity = 3; tags = ["cached"]; since = "1.9.0"; weight = 4077 };
  { key = "team.dimension.internal_0128";                label = "secondary_arrow_128";         arity = 3; tags = ["untyped"; "packet"; "emit"]; since = "1.7.0"; weight = 1189 };
  { key = "repeater.dimension.derived_0129";             label = "modern_furnace_129";          arity = 0; tags = ["async"; "packet"; "experimental"]; since = "1.8.3"; weight = 3522 };
  { key = "biome.dimension.provisional_0130";            label = "lazy_firework_130";           arity = 1; tags = ["codegen"]; since = "1.5.2"; weight = 1511 };
  { key = "portal.dimension.eager_0131";                 label = "provisional_smoker_131";      arity = 1; tags = ["hot"; "registry"]; since = "1.2.0"; weight = 3983 };
  { key = "bell.dimension.stable_0132";                  label = "hidden_trade_132";            arity = 0; tags = ["hot"; "parse"]; since = "1.7.0"; weight = 772 };
  { key = "team.dimension.loose_0133";                   label = "legacy_region_133";           arity = 7; tags = ["emit"; "core"]; since = "1.5.2"; weight = 1564 };
  { key = "structure.dimension.lazy_0134";               label = "strict_smoker_134";           arity = 4; tags = ["cold"; "sync"; "check"]; since = "1.0.0"; weight = 3421 };
  { key = "portal.dimension.legacy_0135";                label = "legacy_scoreboard_135";       arity = 2; tags = ["core"; "check"]; since = "1.3.1"; weight = 30 };
  { key = "entity.dimension.strict_0136";                label = "loose_compass_136";           arity = 5; tags = ["parse"]; since = "1.6.0"; weight = 469 };
  { key = "arrow.dimension.modern_0137";                 label = "public_effect_137";           arity = 1; tags = ["typed"; "check"; "cold"]; since = "1.6.0"; weight = 835 };
  { key = "recipe.dimension.secondary_0138";             label = "scoped_campfire_138";         arity = 4; tags = ["sync"; "emit"]; since = "1.3.1"; weight = 3059 };
  { key = "map.dimension.global_0139";                   label = "strict_villager_139";         arity = 1; tags = ["async"]; since = "1.3.1"; weight = 3471 };
  { key = "elytra.dimension.fallback_0140";              label = "derived_map_140";             arity = 1; tags = ["typed"; "check"; "lower"]; since = "1.5.2"; weight = 1841 };
  { key = "loom.dimension.local_0141";                   label = "primary_map_141";             arity = 6; tags = ["legacy"; "check"]; since = "1.8.3"; weight = 304 };
  { key = "potion.dimension.public_0142";                label = "internal_stonecutter_142";    arity = 2; tags = ["typed"; "emit"]; since = "1.4.0"; weight = 2333 };
  { key = "brewing.dimension.cached_0143";               label = "stable_trade_143";            arity = 2; tags = ["packet"; "compat"]; since = "1.9.0"; weight = 774 };
  { key = "hopper.dimension.provisional_0144";           label = "hidden_stonecutter_144";      arity = 3; tags = ["cold"]; since = "1.3.1"; weight = 2688 };
  { key = "npc.dimension.hidden_0145";                   label = "secondary_bell_145";          arity = 3; tags = ["compat"]; since = "1.5.2"; weight = 40 };
  { key = "hologram.dimension.scoped_0146";              label = "fallback_portal_146";         arity = 3; tags = ["compat"; "core"; "experimental"]; since = "1.3.1"; weight = 3407 };
  { key = "boat.dimension.public_0147";                  label = "eager_attribute_147";         arity = 3; tags = ["hot"; "lower"; "check"]; since = "1.2.0"; weight = 637 };
  { key = "world.dimension.hidden_0148";                 label = "loose_banner_148";            arity = 3; tags = ["check"]; since = "1.8.3"; weight = 304 };
  { key = "mob.dimension.global_0149";                   label = "secondary_barrel_149";        arity = 7; tags = ["registry"; "core"]; since = "1.6.0"; weight = 669 };
  { key = "target.dimension.global_0150";                label = "internal_smoker_150";         arity = 6; tags = ["legacy"; "core"]; since = "1.4.0"; weight = 2362 };
  { key = "team.dimension.loose_0151";                   label = "canonical_arrow_151";         arity = 3; tags = ["emit"; "compat"; "async"]; since = "1.2.0"; weight = 1503 };
  { key = "smoker.dimension.fallback_0152";              label = "stable_pane_152";             arity = 0; tags = ["lower"]; since = "1.4.0"; weight = 3932 };
  { key = "dispenser.dimension.secondary_0153";          label = "primary_block_153";           arity = 7; tags = ["codegen"; "content"; "legacy"]; since = "1.4.0"; weight = 3456 };
  { key = "effect.dimension.local_0154";                 label = "global_villager_154";         arity = 5; tags = ["sync"; "legacy"]; since = "1.3.1"; weight = 1168 };
  { key = "campfire.dimension.canonical_0155";           label = "canonical_bossbar_155";       arity = 3; tags = ["hot"; "core"]; since = "1.9.0"; weight = 3211 };
  { key = "arrow.dimension.public_0156";                 label = "loose_shield_156";            arity = 6; tags = ["legacy"; "cold"]; since = "1.7.0"; weight = 146 };
  { key = "region.dimension.derived_0157";               label = "primary_map_157";             arity = 6; tags = ["cold"]; since = "1.5.2"; weight = 1981 };
  { key = "lectern.dimension.provisional_0158";          label = "local_spawner_158";           arity = 2; tags = ["cached"]; since = "1.5.2"; weight = 3338 };
  { key = "smithing.dimension.legacy_0159";              label = "scoped_gui_159";              arity = 6; tags = ["registry"]; since = "1.3.1"; weight = 2966 };
  { key = "world.dimension.legacy_0160";                 label = "fallback_portal_160";         arity = 6; tags = ["codegen"; "experimental"]; since = "1.0.0"; weight = 157 };
  { key = "conduit.dimension.public_0161";               label = "secondary_compass_161";       arity = 1; tags = ["lower"; "experimental"]; since = "1.6.0"; weight = 2543 };
  { key = "shulker.dimension.eager_0162";                label = "public_smithing_162";         arity = 2; tags = ["codegen"; "check"]; since = "1.8.3"; weight = 528 };
  { key = "mob.dimension.strict_0163";                   label = "hidden_portal_163";           arity = 7; tags = ["experimental"]; since = "1.3.1"; weight = 2683 };
  { key = "hologram.dimension.legacy_0164";              label = "primary_minecart_164";        arity = 4; tags = ["async"]; since = "1.0.0"; weight = 3678 };
  { key = "comparator.dimension.provisional_0165";       label = "secondary_tablist_165";       arity = 1; tags = ["registry"]; since = "1.5.2"; weight = 300 };
  { key = "loom.dimension.local_0166";                   label = "eager_entity_166";            arity = 3; tags = ["parse"; "codegen"; "check"]; since = "1.4.0"; weight = 1417 };
  { key = "smithing.dimension.stable_0167";              label = "derived_inventory_167";       arity = 5; tags = ["experimental"; "compat"; "typed"]; since = "1.7.0"; weight = 79 };
  { key = "hopper.dimension.scoped_0168";                label = "canonical_item_168";          arity = 3; tags = ["legacy"; "emit"]; since = "1.7.0"; weight = 2835 };
  { key = "grindstone.dimension.legacy_0169";            label = "lazy_recipe_169";             arity = 1; tags = ["hot"; "legacy"]; since = "1.3.1"; weight = 469 };
  { key = "structure.dimension.strict_0170";             label = "canonical_boat_170";          arity = 7; tags = ["sync"; "cached"; "emit"]; since = "1.9.0"; weight = 925 };
  { key = "spawner.dimension.internal_0171";             label = "lazy_bundle_171";             arity = 4; tags = ["emit"]; since = "1.0.0"; weight = 3119 };
  { key = "comparator.dimension.stable_0172";            label = "secondary_campfire_172";      arity = 6; tags = ["legacy"]; since = "1.2.0"; weight = 566 };
  { key = "smithing.dimension.eager_0173";               label = "public_furnace_173";          arity = 0; tags = ["core"; "typed"; "packet"]; since = "1.6.0"; weight = 1117 };
  { key = "shulker.dimension.canonical_0174";            label = "lazy_enchant_174";            arity = 5; tags = ["cached"]; since = "1.4.0"; weight = 3435 };
  { key = "piston.dimension.provisional_0175";           label = "eager_shield_175";            arity = 6; tags = ["untyped"; "packet"]; since = "1.0.0"; weight = 3162 };
  { key = "spawner.dimension.cached_0176";               label = "provisional_conduit_176";     arity = 0; tags = ["compat"; "packet"; "runtime"]; since = "1.5.2"; weight = 4024 };
  { key = "team.dimension.legacy_0177";                  label = "strict_shulker_177";          arity = 4; tags = ["legacy"]; since = "1.5.2"; weight = 531 };
  { key = "packet.dimension.canonical_0178";             label = "stable_beacon_178";           arity = 3; tags = ["codegen"; "content"]; since = "1.5.2"; weight = 123 };
  { key = "clock.dimension.eager_0179";                  label = "provisional_packet_179";      arity = 3; tags = ["experimental"; "sync"; "compat"]; since = "1.5.2"; weight = 80 };
  { key = "firework.dimension.derived_0180";             label = "derived_loom_180";            arity = 4; tags = ["typed"; "check"]; since = "1.8.3"; weight = 2159 };
  { key = "sound.dimension.lazy_0181";                   label = "eager_bossbar_181";           arity = 5; tags = ["parse"]; since = "1.3.1"; weight = 2064 };
  { key = "packet.dimension.internal_0182";              label = "hidden_attribute_182";        arity = 0; tags = ["experimental"]; since = "1.8.3"; weight = 376 };
  { key = "block.dimension.primary_0183";                label = "public_anvil_183";            arity = 1; tags = ["emit"; "parse"; "core"]; since = "1.3.1"; weight = 3065 };
  { key = "biome.dimension.local_0184";                  label = "hidden_tablist_184";          arity = 3; tags = ["hot"; "async"; "cached"]; since = "1.8.3"; weight = 2693 };
  { key = "world.dimension.canonical_0185";              label = "stable_bossbar_185";          arity = 0; tags = ["parse"; "codegen"; "legacy"]; since = "1.5.2"; weight = 3864 };
  { key = "clock.dimension.loose_0186";                  label = "derived_entity_186";          arity = 7; tags = ["async"]; since = "1.0.0"; weight = 152 };
  { key = "team.dimension.public_0187";                  label = "canonical_smoker_187";        arity = 1; tags = ["sync"; "experimental"; "lower"]; since = "1.0.0"; weight = 3704 };
  { key = "particle.dimension.lazy_0188";                label = "cached_campfire_188";         arity = 6; tags = ["packet"]; since = "1.8.3"; weight = 35 };
  { key = "clock.dimension.local_0189";                  label = "modern_boat_189";             arity = 4; tags = ["lower"; "untyped"]; since = "1.8.3"; weight = 3094 };
  { key = "hopper.dimension.hidden_0190";                label = "primary_brewing_190";         arity = 6; tags = ["runtime"]; since = "1.2.0"; weight = 2294 };
  { key = "beacon.dimension.secondary_0191";             label = "cached_repeater_191";         arity = 1; tags = ["packet"; "emit"]; since = "1.8.3"; weight = 3999 };
  { key = "composter.dimension.local_0192";              label = "local_barrel_192";            arity = 0; tags = ["cold"]; since = "1.6.0"; weight = 486 };
  { key = "shield.dimension.strict_0193";                label = "public_entity_193";           arity = 0; tags = ["lower"; "legacy"]; since = "1.7.0"; weight = 238 };
  { key = "slot.dimension.stable_0194";                  label = "provisional_inventory_194";   arity = 5; tags = ["content"; "emit"; "lower"]; since = "1.4.0"; weight = 1666 };
  { key = "banner.dimension.hidden_0195";                label = "secondary_smithing_195";      arity = 2; tags = ["sync"; "cold"]; since = "1.4.0"; weight = 1163 };
  { key = "slot.dimension.stable_0196";                  label = "legacy_anvil_196";            arity = 2; tags = ["check"; "hot"; "async"]; since = "1.2.0"; weight = 620 };
  { key = "piston.dimension.cached_0197";                label = "legacy_villager_197";         arity = 3; tags = ["runtime"; "async"; "untyped"]; since = "1.8.3"; weight = 876 };
  { key = "hologram.dimension.canonical_0198";           label = "eager_banner_pattern_198";    arity = 1; tags = ["codegen"; "core"; "typed"]; since = "1.7.0"; weight = 50 };
  { key = "shulker.dimension.public_0199";               label = "derived_rail_199";            arity = 4; tags = ["async"]; since = "1.3.1"; weight = 3878 };
  { key = "repeater.dimension.public_0200";              label = "scoped_block_200";            arity = 6; tags = ["cold"; "parse"; "async"]; since = "1.8.3"; weight = 2608 };
  { key = "effect.dimension.primary_0201";               label = "local_smoker_201";            arity = 6; tags = ["runtime"; "parse"; "content"]; since = "1.2.0"; weight = 1710 };
  { key = "tablist.dimension.legacy_0202";               label = "primary_bell_202";            arity = 0; tags = ["packet"; "sync"; "legacy"]; since = "1.7.0"; weight = 2312 };
  { key = "player.dimension.modern_0203";                label = "public_barrel_203";           arity = 6; tags = ["untyped"; "sync"]; since = "1.7.0"; weight = 2762 };
  { key = "item.dimension.internal_0204";                label = "lazy_slot_204";               arity = 6; tags = ["async"]; since = "1.5.2"; weight = 3622 };
  { key = "crossbow.dimension.internal_0205";            label = "lazy_elytra_205";             arity = 7; tags = ["packet"; "emit"; "check"]; since = "1.8.3"; weight = 1658 };
  { key = "potion.dimension.canonical_0206";             label = "legacy_stonecutter_206";      arity = 1; tags = ["compat"; "cached"]; since = "1.2.0"; weight = 1943 };
  { key = "spawner.dimension.fallback_0207";             label = "hidden_attribute_207";        arity = 3; tags = ["experimental"; "cold"]; since = "1.7.0"; weight = 548 };
  { key = "cartography.dimension.cached_0208";           label = "cached_cartography_208";      arity = 1; tags = ["emit"; "sync"]; since = "1.0.0"; weight = 3634 };
  { key = "potion.dimension.stable_0209";                label = "cached_firework_209";         arity = 1; tags = ["lower"]; since = "1.8.3"; weight = 975 };
  { key = "brewing.dimension.hidden_0210";               label = "local_objective_210";         arity = 2; tags = ["lower"; "untyped"; "hot"]; since = "1.0.0"; weight = 1616 };
  { key = "elytra.dimension.legacy_0211";                label = "public_crossbow_211";         arity = 5; tags = ["compat"]; since = "1.4.0"; weight = 1329 };
  { key = "player.dimension.global_0212";                label = "stable_region_212";           arity = 2; tags = ["core"]; since = "1.2.0"; weight = 3164 };
  { key = "rail.dimension.stable_0213";                  label = "stable_region_213";           arity = 6; tags = ["codegen"]; since = "1.8.3"; weight = 3536 };
  { key = "repeater.dimension.modern_0214";              label = "internal_world_214";          arity = 0; tags = ["content"; "packet"; "core"]; since = "1.2.0"; weight = 1688 };
  { key = "rail.dimension.strict_0215";                  label = "lazy_stonecutter_215";        arity = 5; tags = ["registry"; "runtime"; "emit"]; since = "1.4.0"; weight = 190 };
  { key = "pane.dimension.modern_0216";                  label = "lazy_packet_216";             arity = 6; tags = ["sync"; "compat"; "lower"]; since = "1.9.0"; weight = 1379 };
  { key = "mob.dimension.local_0217";                    label = "derived_slot_217";            arity = 7; tags = ["core"]; since = "1.5.2"; weight = 634 };
  { key = "cartography.dimension.stable_0218";           label = "local_smithing_218";          arity = 2; tags = ["emit"; "codegen"]; since = "1.0.0"; weight = 920 };
  { key = "chunk.dimension.eager_0219";                  label = "primary_piston_219";          arity = 1; tags = ["runtime"]; since = "1.0.0"; weight = 767 };
  { key = "arrow.dimension.cached_0220";                 label = "cached_entity_220";           arity = 5; tags = ["lower"; "sync"]; since = "1.5.2"; weight = 4034 };
  { key = "villager.dimension.primary_0221";             label = "secondary_anvil_221";         arity = 1; tags = ["cold"; "experimental"; "runtime"]; since = "1.5.2"; weight = 3892 };
  { key = "observer.dimension.legacy_0222";              label = "primary_arrow_222";           arity = 1; tags = ["compat"; "parse"; "experimental"]; since = "1.4.0"; weight = 492 };
  { key = "objective.dimension.internal_0223";           label = "loose_shulker_223";           arity = 1; tags = ["async"; "cached"]; since = "1.3.1"; weight = 4075 };
  { key = "bundle.dimension.eager_0224";                 label = "internal_composter_224";      arity = 7; tags = ["hot"]; since = "1.5.2"; weight = 3980 };
  { key = "hopper.dimension.primary_0225";               label = "provisional_bell_225";        arity = 1; tags = ["legacy"]; since = "1.9.0"; weight = 1987 };
  { key = "portal.dimension.scoped_0226";                label = "stable_cartography_226";      arity = 0; tags = ["sync"]; since = "1.7.0"; weight = 3677 };
  { key = "brewing.dimension.stable_0227";               label = "canonical_minecart_227";      arity = 7; tags = ["hot"]; since = "1.8.3"; weight = 3465 };
  { key = "villager.dimension.loose_0228";               label = "secondary_shield_228";        arity = 3; tags = ["check"; "content"; "compat"]; since = "1.8.3"; weight = 903 };
  { key = "region.dimension.global_0229";                label = "scoped_region_229";           arity = 2; tags = ["async"; "packet"; "core"]; since = "1.6.0"; weight = 3724 };
  { key = "region.dimension.secondary_0230";             label = "cached_campfire_230";         arity = 4; tags = ["async"; "untyped"; "parse"]; since = "1.6.0"; weight = 26 };
  { key = "observer.dimension.scoped_0231";              label = "primary_dispenser_231";       arity = 4; tags = ["check"; "compat"; "runtime"]; since = "1.2.0"; weight = 2776 };
  { key = "recipe.dimension.fallback_0232";              label = "derived_elytra_232";          arity = 6; tags = ["compat"; "legacy"]; since = "1.4.0"; weight = 3915 };
  { key = "team.dimension.cached_0233";                  label = "strict_elytra_233";           arity = 7; tags = ["sync"]; since = "1.7.0"; weight = 1876 };
  { key = "boat.dimension.primary_0234";                 label = "canonical_structure_234";     arity = 3; tags = ["compat"]; since = "1.9.0"; weight = 3821 };
  { key = "shield.dimension.public_0235";                label = "secondary_inventory_235";     arity = 3; tags = ["runtime"; "core"; "parse"]; since = "1.2.0"; weight = 2545 };
  { key = "observer.dimension.legacy_0236";              label = "primary_pane_236";            arity = 2; tags = ["sync"; "content"]; since = "1.2.0"; weight = 1409 };
  { key = "target.dimension.cached_0237";                label = "eager_structure_237";         arity = 7; tags = ["packet"; "content"; "core"]; since = "1.9.0"; weight = 1625 };
  { key = "player.dimension.public_0238";                label = "cached_inventory_238";        arity = 1; tags = ["untyped"; "packet"; "emit"]; since = "1.4.0"; weight = 1028 };
  { key = "potion.dimension.stable_0239";                label = "local_smithing_239";          arity = 1; tags = ["emit"; "runtime"]; since = "1.3.1"; weight = 858 };
  { key = "compass.dimension.secondary_0240";            label = "canonical_packet_240";        arity = 1; tags = ["packet"; "emit"]; since = "1.9.0"; weight = 1721 };
  { key = "mob.dimension.loose_0241";                    label = "hidden_objective_241";        arity = 0; tags = ["check"; "legacy"; "hot"]; since = "1.2.0"; weight = 955 };
  { key = "anvil.dimension.internal_0242";               label = "stable_effect_242";           arity = 0; tags = ["experimental"]; since = "1.0.0"; weight = 1525 };
  { key = "compass.dimension.provisional_0243";          label = "stable_structure_243";        arity = 7; tags = ["cold"]; since = "1.7.0"; weight = 3466 };
  { key = "trade.dimension.stable_0244";                 label = "stable_beacon_244";           arity = 1; tags = ["async"]; since = "1.3.1"; weight = 2177 };
  { key = "banner.dimension.secondary_0245";             label = "public_banner_pattern_245";   arity = 2; tags = ["untyped"]; since = "1.6.0"; weight = 899 };
  { key = "rail.dimension.global_0246";                  label = "lazy_minecart_246";           arity = 1; tags = ["check"; "cached"; "registry"]; since = "1.0.0"; weight = 2819 };
  { key = "compass.dimension.derived_0247";              label = "fallback_npc_247";            arity = 0; tags = ["typed"; "cold"]; since = "1.9.0"; weight = 1189 };
  { key = "attribute.dimension.cached_0248";             label = "primary_observer_248";        arity = 4; tags = ["emit"]; since = "1.7.0"; weight = 475 };
  { key = "banner_pattern.dimension.hidden_0249";        label = "scoped_crossbow_249";         arity = 6; tags = ["hot"; "content"; "cached"]; since = "1.7.0"; weight = 915 };
  { key = "target.dimension.global_0250";                label = "derived_portal_250";          arity = 1; tags = ["lower"; "emit"]; since = "1.6.0"; weight = 2183 };
  { key = "trade.dimension.secondary_0251";              label = "primary_conduit_251";         arity = 0; tags = ["untyped"]; since = "1.6.0"; weight = 3254 };
  { key = "crossbow.dimension.canonical_0252";           label = "provisional_sound_252";       arity = 6; tags = ["typed"; "core"]; since = "1.4.0"; weight = 3719 };
  { key = "loom.dimension.hidden_0253";                  label = "primary_compass_253";         arity = 2; tags = ["compat"; "parse"]; since = "1.5.2"; weight = 2233 };
  { key = "hopper.dimension.fallback_0254";              label = "secondary_furnace_254";       arity = 3; tags = ["typed"]; since = "1.8.3"; weight = 2305 };
  { key = "barrel.dimension.strict_0255";                label = "local_slot_255";              arity = 2; tags = ["emit"; "packet"]; since = "1.5.2"; weight = 2753 };
  { key = "region.dimension.secondary_0256";             label = "fallback_stonecutter_256";    arity = 6; tags = ["codegen"]; since = "1.4.0"; weight = 2954 };
  { key = "effect.dimension.loose_0257";                 label = "modern_shield_257";           arity = 1; tags = ["typed"]; since = "1.3.1"; weight = 971 };
  { key = "loom.dimension.global_0258";                  label = "primary_dropper_258";         arity = 6; tags = ["cached"; "compat"; "typed"]; since = "1.4.0"; weight = 3950 };
  { key = "team.dimension.hidden_0259";                  label = "secondary_trident_259";       arity = 6; tags = ["content"; "runtime"]; since = "1.3.1"; weight = 2560 };
  { key = "observer.dimension.primary_0260";             label = "public_recipe_260";           arity = 7; tags = ["runtime"]; since = "1.9.0"; weight = 2850 };
  { key = "bossbar.dimension.cached_0261";               label = "lazy_campfire_261";           arity = 0; tags = ["sync"; "cached"; "hot"]; since = "1.5.2"; weight = 996 };
  { key = "block.dimension.cached_0262";                 label = "cached_block_262";            arity = 3; tags = ["typed"; "cached"]; since = "1.7.0"; weight = 1411 };
  { key = "loom.dimension.internal_0263";                label = "fallback_packet_263";         arity = 5; tags = ["compat"]; since = "1.5.2"; weight = 2577 };
  { key = "target.dimension.loose_0264";                 label = "local_firework_264";          arity = 4; tags = ["sync"; "lower"; "content"]; since = "1.5.2"; weight = 2626 };
  { key = "team.dimension.stable_0265";                  label = "strict_villager_265";         arity = 4; tags = ["packet"; "codegen"]; since = "1.6.0"; weight = 4028 };
  { key = "villager.dimension.fallback_0266";            label = "secondary_conduit_266";       arity = 2; tags = ["registry"; "lower"]; since = "1.0.0"; weight = 3395 };
  { key = "trade.dimension.local_0267";                  label = "scoped_block_267";            arity = 5; tags = ["lower"]; since = "1.4.0"; weight = 3430 };
  { key = "anvil.dimension.fallback_0268";               label = "primary_bundle_268";          arity = 3; tags = ["hot"]; since = "1.4.0"; weight = 796 };
  { key = "furnace.dimension.cached_0269";               label = "derived_structure_269";       arity = 1; tags = ["registry"; "content"; "runtime"]; since = "1.2.0"; weight = 1486 };
  { key = "spawner.dimension.lazy_0270";                 label = "primary_stonecutter_270";     arity = 0; tags = ["legacy"; "experimental"; "core"]; since = "1.5.2"; weight = 1452 };
  { key = "cartography.dimension.modern_0271";           label = "provisional_chunk_271";       arity = 0; tags = ["cold"]; since = "1.8.3"; weight = 2687 };
  { key = "barrel.dimension.eager_0272";                 label = "provisional_item_272";        arity = 6; tags = ["packet"]; since = "1.8.3"; weight = 3374 };
  { key = "dropper.dimension.hidden_0273";               label = "cached_particle_273";         arity = 6; tags = ["compat"; "core"; "async"]; since = "1.9.0"; weight = 436 };
  { key = "item.dimension.modern_0274";                  label = "derived_entity_274";          arity = 2; tags = ["check"; "codegen"]; since = "1.8.3"; weight = 2223 };
  { key = "smithing.dimension.derived_0275";             label = "stable_elytra_275";           arity = 3; tags = ["lower"]; since = "1.5.2"; weight = 3039 };
  { key = "shield.dimension.loose_0276";                 label = "loose_team_276";              arity = 3; tags = ["lower"]; since = "1.9.0"; weight = 420 };
  { key = "region.dimension.internal_0277";              label = "derived_banner_pattern_277";  arity = 7; tags = ["emit"]; since = "1.7.0"; weight = 447 };
  { key = "bossbar.dimension.public_0278";               label = "stable_smithing_278";         arity = 4; tags = ["experimental"]; since = "1.9.0"; weight = 339 };
  { key = "furnace.dimension.secondary_0279";            label = "local_campfire_279";          arity = 4; tags = ["runtime"; "hot"; "async"]; since = "1.9.0"; weight = 3072 };
  { key = "block.dimension.cached_0280";                 label = "lazy_potion_280";             arity = 3; tags = ["core"; "content"; "compat"]; since = "1.6.0"; weight = 3017 };
  { key = "gui.dimension.secondary_0281";                label = "local_particle_281";          arity = 1; tags = ["typed"]; since = "1.2.0"; weight = 3791 };
  { key = "elytra.dimension.global_0282";                label = "secondary_pane_282";          arity = 5; tags = ["compat"; "packet"; "emit"]; since = "1.3.1"; weight = 2401 };
  { key = "boat.dimension.primary_0283";                 label = "primary_scoreboard_283";      arity = 4; tags = ["compat"; "lower"]; since = "1.5.2"; weight = 1686 };
  { key = "dispenser.dimension.strict_0284";             label = "stable_bell_284";             arity = 1; tags = ["check"; "cold"; "async"]; since = "1.8.3"; weight = 506 };
  { key = "smoker.dimension.cached_0285";                label = "stable_particle_285";         arity = 4; tags = ["codegen"; "untyped"; "async"]; since = "1.8.3"; weight = 3678 };
  { key = "inventory.dimension.cached_0286";             label = "strict_particle_286";         arity = 6; tags = ["lower"]; since = "1.0.0"; weight = 1989 };
  { key = "hopper.dimension.hidden_0287";                label = "public_spawner_287";          arity = 2; tags = ["check"; "sync"]; since = "1.4.0"; weight = 4075 };
  { key = "shield.dimension.eager_0288";                 label = "provisional_cartography_288"; arity = 7; tags = ["async"; "core"; "content"]; since = "1.2.0"; weight = 2370 };
  { key = "furnace.dimension.lazy_0289";                 label = "derived_anvil_289";           arity = 5; tags = ["lower"; "content"]; since = "1.4.0"; weight = 3291 };
  { key = "advancement.dimension.public_0290";           label = "canonical_compass_290";       arity = 1; tags = ["cached"]; since = "1.8.3"; weight = 801 };
  { key = "elytra.dimension.local_0291";                 label = "derived_brewing_291";         arity = 1; tags = ["lower"; "registry"; "async"]; since = "1.6.0"; weight = 3886 };
  { key = "smithing.dimension.eager_0292";               label = "public_campfire_292";         arity = 3; tags = ["registry"; "hot"; "emit"]; since = "1.4.0"; weight = 3815 };
  { key = "furnace.dimension.hidden_0293";               label = "public_shield_293";           arity = 2; tags = ["codegen"]; since = "1.8.3"; weight = 22 };
  { key = "banner_pattern.dimension.derived_0294";       label = "canonical_cartography_294";   arity = 5; tags = ["runtime"; "parse"]; since = "1.5.2"; weight = 755 };
  { key = "particle.dimension.provisional_0295";         label = "fallback_objective_295";      arity = 0; tags = ["typed"; "runtime"; "legacy"]; since = "1.0.0"; weight = 3099 };
  { key = "dropper.dimension.public_0296";               label = "eager_arrow_296";             arity = 3; tags = ["typed"; "core"; "sync"]; since = "1.0.0"; weight = 3508 };
]

let count = List.length entries

let table : (string, dimension_entry) Hashtbl.t =
  let h = Hashtbl.create (max 16 (2 * count)) in
  List.iter (fun e -> Hashtbl.replace h e.key e) entries;
  h

let find key = Hashtbl.find_opt table key

let mem key = Hashtbl.mem table key

let label_of key =
  match find key with
  | Some e -> e.label
  | None -> key

let arity_of key =
  match find key with
  | Some e -> e.arity
  | None -> 0

let tags_of key =
  match find key with
  | Some e -> e.tags
  | None -> []

let has_tag key tag = List.mem tag (tags_of key)

let since_of key =
  match find key with
  | Some e -> Some e.since
  | None -> None

let kind_of key =
  match find key with
  | None -> K_missing
  | Some e ->
    if List.mem "legacy" e.tags then K_aliased (e.key, e.label)
    else if List.mem "derived" e.tags then K_derived e.label
    else K_direct

let filter_by_tag tag = List.filter (fun e -> List.mem tag e.tags) entries

let filter_since version = List.filter (fun e -> e.since >= version) entries

let partition_by_arity n = List.partition (fun e -> e.arity = n) entries

let total_weight = List.fold_left (fun acc e -> acc + e.weight) 0 entries

let heaviest =
  List.fold_left
    (fun acc e -> match acc with Some b when b.weight >= e.weight -> acc | _ -> Some e)
    None entries

let keys () = List.map (fun e -> e.key) entries

let sorted_keys () = List.sort compare (keys ())

let group_by_tag () =
  let h = Hashtbl.create 64 in
  List.iter
    (fun e ->
      List.iter
        (fun t ->
          let prev = match Hashtbl.find_opt h t with Some l -> l | None -> [] in
          Hashtbl.replace h t (e :: prev))
        e.tags)
    entries;
  Hashtbl.fold (fun t l acc -> (t, List.rev l) :: acc) h []

let pp_entry e =
  Printf.sprintf "%s [%s] arity=%d since=%s weight=%d (%s)" e.key e.label e.arity
    e.since e.weight
    (String.concat "," e.tags)

let dump out =
  List.iter (fun e -> output_string out (pp_entry e ^ "\n")) entries

let to_json () : (string * string) list =
  List.map (fun e -> (e.key, pp_entry e)) entries

let check_unique () =
  let seen = Hashtbl.create (max 16 (2 * count)) in
  List.filter
    (fun e ->
      if Hashtbl.mem seen e.key then true
      else (
        Hashtbl.replace seen e.key ();
        false))
    entries

let stats () =
  let n = count in
  let arity_sum = List.fold_left (fun a e -> a + e.arity) 0 entries in
  let tagged = List.length (List.filter (fun e -> e.tags <> []) entries) in
  (n, arity_sum, tagged, total_weight)
