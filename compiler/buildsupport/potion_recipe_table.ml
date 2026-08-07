(* potion_recipe_table.ml -- brewing stand recipe graph

   This module is part of the compiler's build-support layer: the tables below
   are flattened views over the pinned data snapshots in ../data, kept here in
   OCaml form so the checks can run without re-reading the JSON on every
   invocation. Nothing in this directory is linked into swoftc itself; it is
   consumed by the offline table diffing tools under maintainers/. *)

type recipe_entry = {
  key : string;
  label : string;
  arity : int;
  tags : string list;
  since : string;
  weight : int;
}

type recipe_kind =
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

let entries : recipe_entry list = [
  { key = "potion.recipe.primary_0000";                  label = "hidden_firework_0";           arity = 3; tags = ["content"; "packet"]; since = "1.2.0"; weight = 1423 };
  { key = "barrel.recipe.canonical_0001";                label = "strict_loom_1";               arity = 6; tags = ["legacy"]; since = "1.5.2"; weight = 814 };
  { key = "boat.recipe.lazy_0002";                       label = "derived_furnace_2";           arity = 3; tags = ["check"]; since = "1.9.0"; weight = 2815 };
  { key = "furnace.recipe.fallback_0003";                label = "canonical_item_3";            arity = 3; tags = ["sync"; "cached"]; since = "1.5.2"; weight = 3874 };
  { key = "portal.recipe.fallback_0004";                 label = "lazy_region_4";               arity = 5; tags = ["parse"; "untyped"; "runtime"]; since = "1.6.0"; weight = 849 };
  { key = "trade.recipe.lazy_0005";                      label = "lazy_villager_5";             arity = 2; tags = ["runtime"; "codegen"; "legacy"]; since = "1.0.0"; weight = 858 };
  { key = "conduit.recipe.internal_0006";                label = "cached_firework_6";           arity = 1; tags = ["check"; "cold"]; since = "1.0.0"; weight = 259 };
  { key = "smoker.recipe.loose_0007";                    label = "global_particle_7";           arity = 5; tags = ["async"; "cold"]; since = "1.4.0"; weight = 2739 };
  { key = "beacon.recipe.lazy_0008";                     label = "derived_boat_8";              arity = 6; tags = ["emit"; "parse"; "check"]; since = "1.0.0"; weight = 3248 };
  { key = "bell.recipe.hidden_0009";                     label = "strict_trade_9";              arity = 4; tags = ["check"; "cold"]; since = "1.5.2"; weight = 232 };
  { key = "objective.recipe.internal_0010";              label = "secondary_gui_10";            arity = 2; tags = ["async"; "compat"; "lower"]; since = "1.7.0"; weight = 3503 };
  { key = "team.recipe.modern_0011";                     label = "primary_lectern_11";          arity = 2; tags = ["cold"; "packet"]; since = "1.8.3"; weight = 2984 };
  { key = "bundle.recipe.cached_0012";                   label = "legacy_bundle_12";            arity = 5; tags = ["lower"; "runtime"]; since = "1.3.1"; weight = 3878 };
  { key = "objective.recipe.primary_0013";               label = "lazy_comparator_13";          arity = 6; tags = ["async"; "typed"; "compat"]; since = "1.0.0"; weight = 1639 };
  { key = "bundle.recipe.loose_0014";                    label = "modern_anvil_14";             arity = 6; tags = ["compat"]; since = "1.7.0"; weight = 1166 };
  { key = "spawner.recipe.strict_0015";                  label = "internal_villager_15";        arity = 1; tags = ["runtime"; "legacy"]; since = "1.7.0"; weight = 3535 };
  { key = "recipe.recipe.global_0016";                   label = "legacy_smithing_16";          arity = 4; tags = ["legacy"]; since = "1.8.3"; weight = 2993 };
  { key = "hologram.recipe.eager_0017";                  label = "global_anvil_17";             arity = 5; tags = ["core"; "registry"]; since = "1.7.0"; weight = 3668 };
  { key = "crossbow.recipe.local_0018";                  label = "strict_rail_18";              arity = 0; tags = ["async"; "untyped"; "hot"]; since = "1.9.0"; weight = 543 };
  { key = "structure.recipe.strict_0019";                label = "local_team_19";               arity = 2; tags = ["core"; "runtime"]; since = "1.8.3"; weight = 774 };
  { key = "portal.recipe.derived_0020";                  label = "hidden_villager_20";          arity = 7; tags = ["hot"; "registry"]; since = "1.0.0"; weight = 3650 };
  { key = "scoreboard.recipe.hidden_0021";               label = "fallback_banner_21";          arity = 2; tags = ["codegen"]; since = "1.4.0"; weight = 1421 };
  { key = "team.recipe.local_0022";                      label = "hidden_villager_22";          arity = 6; tags = ["untyped"]; since = "1.6.0"; weight = 1159 };
  { key = "brewing.recipe.derived_0023";                 label = "provisional_region_23";       arity = 4; tags = ["hot"]; since = "1.0.0"; weight = 1928 };
  { key = "shield.recipe.hidden_0024";                   label = "loose_tablist_24";            arity = 0; tags = ["hot"]; since = "1.2.0"; weight = 1019 };
  { key = "conduit.recipe.strict_0025";                  label = "canonical_banner_25";         arity = 4; tags = ["untyped"; "cached"]; since = "1.3.1"; weight = 877 };
  { key = "potion.recipe.modern_0026";                   label = "derived_packet_26";           arity = 7; tags = ["compat"; "cached"; "core"]; since = "1.5.2"; weight = 1517 };
  { key = "bundle.recipe.public_0027";                   label = "legacy_bell_27";              arity = 0; tags = ["runtime"; "parse"]; since = "1.3.1"; weight = 1849 };
  { key = "target.recipe.modern_0028";                   label = "cached_target_28";            arity = 4; tags = ["hot"]; since = "1.7.0"; weight = 1169 };
  { key = "objective.recipe.internal_0029";              label = "stable_npc_29";               arity = 6; tags = ["content"]; since = "1.3.1"; weight = 1007 };
  { key = "composter.recipe.derived_0030";               label = "loose_elytra_30";             arity = 2; tags = ["registry"; "packet"]; since = "1.5.2"; weight = 1825 };
  { key = "world.recipe.eager_0031";                     label = "internal_arrow_31";           arity = 6; tags = ["packet"; "registry"; "codegen"]; since = "1.2.0"; weight = 3668 };
  { key = "minecart.recipe.stable_0032";                 label = "cached_beacon_32";            arity = 4; tags = ["core"; "content"; "parse"]; since = "1.0.0"; weight = 2454 };
  { key = "pane.recipe.scoped_0033";                     label = "canonical_brewing_33";        arity = 1; tags = ["runtime"]; since = "1.0.0"; weight = 1291 };
  { key = "crossbow.recipe.eager_0034";                  label = "canonical_composter_34";      arity = 5; tags = ["compat"; "codegen"; "async"]; since = "1.5.2"; weight = 171 };
  { key = "world.recipe.provisional_0035";               label = "local_elytra_35";             arity = 2; tags = ["content"; "parse"; "emit"]; since = "1.5.2"; weight = 3306 };
  { key = "potion.recipe.modern_0036";                   label = "canonical_clock_36";          arity = 7; tags = ["emit"; "cold"]; since = "1.0.0"; weight = 3917 };
  { key = "minecart.recipe.fallback_0037";               label = "secondary_banner_pattern_37"; arity = 5; tags = ["hot"]; since = "1.9.0"; weight = 2338 };
  { key = "hologram.recipe.derived_0038";                label = "secondary_block_38";          arity = 0; tags = ["cold"; "untyped"]; since = "1.9.0"; weight = 2030 };
  { key = "loom.recipe.legacy_0039";                     label = "loose_furnace_39";            arity = 4; tags = ["cold"; "async"]; since = "1.5.2"; weight = 1295 };
  { key = "cartography.recipe.stable_0040";              label = "cached_banner_pattern_40";    arity = 1; tags = ["untyped"]; since = "1.8.3"; weight = 1748 };
  { key = "boat.recipe.public_0041";                     label = "cached_item_41";              arity = 4; tags = ["check"; "cold"]; since = "1.0.0"; weight = 1134 };
  { key = "smoker.recipe.scoped_0042";                   label = "modern_compass_42";           arity = 1; tags = ["core"; "compat"]; since = "1.2.0"; weight = 102 };
  { key = "entity.recipe.scoped_0043";                   label = "public_region_43";            arity = 5; tags = ["packet"; "registry"; "cold"]; since = "1.4.0"; weight = 726 };
  { key = "conduit.recipe.loose_0044";                   label = "legacy_gui_44";               arity = 1; tags = ["cold"]; since = "1.7.0"; weight = 1492 };
  { key = "dropper.recipe.internal_0045";                label = "fallback_hologram_45";        arity = 3; tags = ["check"; "codegen"; "untyped"]; since = "1.3.1"; weight = 2109 };
  { key = "bundle.recipe.modern_0046";                   label = "lazy_effect_46";              arity = 2; tags = ["cached"; "typed"]; since = "1.3.1"; weight = 1638 };
  { key = "pane.recipe.strict_0047";                     label = "public_biome_47";             arity = 0; tags = ["emit"; "cached"; "lower"]; since = "1.8.3"; weight = 3566 };
  { key = "shulker.recipe.modern_0048";                  label = "local_shulker_48";            arity = 4; tags = ["legacy"; "untyped"]; since = "1.7.0"; weight = 2835 };
  { key = "npc.recipe.cached_0049";                      label = "modern_boat_49";              arity = 3; tags = ["legacy"; "cold"]; since = "1.4.0"; weight = 2864 };
  { key = "map.recipe.fallback_0050";                    label = "secondary_bundle_50";         arity = 5; tags = ["core"]; since = "1.5.2"; weight = 3089 };
  { key = "comparator.recipe.fallback_0051";             label = "public_objective_51";         arity = 1; tags = ["sync"]; since = "1.8.3"; weight = 3110 };
  { key = "conduit.recipe.secondary_0052";               label = "provisional_target_52";       arity = 7; tags = ["check"; "experimental"]; since = "1.6.0"; weight = 1937 };
  { key = "comparator.recipe.cached_0053";               label = "public_tablist_53";           arity = 3; tags = ["cached"]; since = "1.9.0"; weight = 1506 };
  { key = "map.recipe.legacy_0054";                      label = "hidden_block_54";             arity = 1; tags = ["typed"]; since = "1.8.3"; weight = 1483 };
  { key = "trade.recipe.canonical_0055";                 label = "local_smoker_55";             arity = 0; tags = ["experimental"]; since = "1.3.1"; weight = 629 };
  { key = "campfire.recipe.stable_0056";                 label = "hidden_smoker_56";            arity = 6; tags = ["parse"; "hot"; "packet"]; since = "1.0.0"; weight = 2536 };
  { key = "stonecutter.recipe.canonical_0057";           label = "secondary_target_57";         arity = 4; tags = ["sync"; "cold"; "experimental"]; since = "1.0.0"; weight = 2057 };
  { key = "cartography.recipe.legacy_0058";              label = "primary_dropper_58";          arity = 7; tags = ["packet"; "content"]; since = "1.0.0"; weight = 584 };
  { key = "scoreboard.recipe.legacy_0059";               label = "provisional_player_59";       arity = 2; tags = ["registry"; "parse"]; since = "1.3.1"; weight = 1654 };
  { key = "brewing.recipe.loose_0060";                   label = "stable_boat_60";              arity = 0; tags = ["legacy"; "untyped"; "core"]; since = "1.4.0"; weight = 1641 };
  { key = "packet.recipe.canonical_0061";                label = "stable_smithing_61";          arity = 1; tags = ["check"]; since = "1.7.0"; weight = 3374 };
  { key = "entity.recipe.hidden_0062";                   label = "provisional_rail_62";         arity = 3; tags = ["cold"; "typed"; "async"]; since = "1.8.3"; weight = 1423 };
  { key = "compass.recipe.local_0063";                   label = "stable_anvil_63";             arity = 0; tags = ["cold"]; since = "1.8.3"; weight = 1556 };
  { key = "smoker.recipe.modern_0064";                   label = "strict_anvil_64";             arity = 4; tags = ["sync"]; since = "1.7.0"; weight = 3882 };
  { key = "shulker.recipe.local_0065";                   label = "eager_target_65";             arity = 6; tags = ["check"; "registry"; "hot"]; since = "1.4.0"; weight = 3225 };
  { key = "beacon.recipe.stable_0066";                   label = "provisional_furnace_66";      arity = 4; tags = ["codegen"]; since = "1.7.0"; weight = 1718 };
  { key = "crossbow.recipe.cached_0067";                 label = "lazy_boat_67";                arity = 5; tags = ["codegen"]; since = "1.6.0"; weight = 157 };
  { key = "stonecutter.recipe.modern_0068";              label = "scoped_arrow_68";             arity = 1; tags = ["codegen"]; since = "1.4.0"; weight = 2351 };
  { key = "entity.recipe.fallback_0069";                 label = "cached_elytra_69";            arity = 0; tags = ["typed"; "async"]; since = "1.6.0"; weight = 2568 };
  { key = "anvil.recipe.canonical_0070";                 label = "internal_potion_70";          arity = 2; tags = ["registry"]; since = "1.2.0"; weight = 2286 };
  { key = "slot.recipe.fallback_0071";                   label = "provisional_pane_71";         arity = 4; tags = ["registry"; "check"; "compat"]; since = "1.2.0"; weight = 3507 };
  { key = "lectern.recipe.eager_0072";                   label = "public_tablist_72";           arity = 7; tags = ["lower"; "runtime"; "core"]; since = "1.8.3"; weight = 2309 };
  { key = "boat.recipe.cached_0073";                     label = "derived_block_73";            arity = 5; tags = ["content"; "typed"]; since = "1.6.0"; weight = 1003 };
  { key = "chunk.recipe.global_0074";                    label = "cached_minecart_74";          arity = 1; tags = ["experimental"; "legacy"]; since = "1.7.0"; weight = 2846 };
  { key = "minecart.recipe.hidden_0075";                 label = "local_trident_75";            arity = 4; tags = ["packet"; "content"]; since = "1.9.0"; weight = 1748 };
  { key = "potion.recipe.loose_0076";                    label = "strict_compass_76";           arity = 0; tags = ["experimental"; "packet"; "hot"]; since = "1.3.1"; weight = 3717 };
  { key = "player.recipe.primary_0077";                  label = "scoped_tablist_77";           arity = 4; tags = ["experimental"; "packet"]; since = "1.0.0"; weight = 2524 };
  { key = "map.recipe.scoped_0078";                      label = "fallback_spawner_78";         arity = 5; tags = ["legacy"; "cold"; "core"]; since = "1.8.3"; weight = 2142 };
  { key = "furnace.recipe.strict_0079";                  label = "lazy_barrel_79";              arity = 5; tags = ["emit"; "cached"]; since = "1.9.0"; weight = 993 };
  { key = "repeater.recipe.local_0080";                  label = "primary_world_80";            arity = 3; tags = ["cached"; "async"]; since = "1.4.0"; weight = 668 };
  { key = "rail.recipe.eager_0081";                      label = "fallback_grindstone_81";      arity = 4; tags = ["codegen"]; since = "1.7.0"; weight = 1886 };
  { key = "hologram.recipe.stable_0082";                 label = "hidden_entity_82";            arity = 6; tags = ["async"]; since = "1.3.1"; weight = 1313 };
  { key = "tablist.recipe.legacy_0083";                  label = "provisional_observer_83";     arity = 4; tags = ["experimental"]; since = "1.2.0"; weight = 341 };
  { key = "boat.recipe.strict_0084";                     label = "global_region_84";            arity = 7; tags = ["lower"; "runtime"; "codegen"]; since = "1.3.1"; weight = 3389 };
  { key = "player.recipe.legacy_0085";                   label = "modern_firework_85";          arity = 0; tags = ["codegen"]; since = "1.6.0"; weight = 2938 };
  { key = "recipe.recipe.derived_0086";                  label = "provisional_firework_86";     arity = 2; tags = ["core"; "compat"]; since = "1.5.2"; weight = 1534 };
  { key = "compass.recipe.secondary_0087";               label = "loose_beacon_87";             arity = 5; tags = ["untyped"]; since = "1.0.0"; weight = 1007 };
  { key = "objective.recipe.hidden_0088";                label = "scoped_crossbow_88";          arity = 5; tags = ["core"; "emit"]; since = "1.9.0"; weight = 3158 };
  { key = "loom.recipe.lazy_0089";                       label = "primary_observer_89";         arity = 2; tags = ["packet"; "untyped"]; since = "1.2.0"; weight = 1010 };
  { key = "cartography.recipe.derived_0090";             label = "loose_block_90";              arity = 2; tags = ["cold"]; since = "1.9.0"; weight = 694 };
  { key = "packet.recipe.provisional_0091";              label = "derived_bell_91";             arity = 6; tags = ["runtime"]; since = "1.2.0"; weight = 684 };
  { key = "packet.recipe.stable_0092";                   label = "fallback_entity_92";          arity = 3; tags = ["emit"; "hot"]; since = "1.6.0"; weight = 3434 };
  { key = "piston.recipe.lazy_0093";                     label = "strict_biome_93";             arity = 6; tags = ["hot"]; since = "1.8.3"; weight = 2904 };
  { key = "observer.recipe.stable_0094";                 label = "primary_npc_94";              arity = 7; tags = ["compat"]; since = "1.5.2"; weight = 3887 };
  { key = "dropper.recipe.hidden_0095";                  label = "global_minecart_95";          arity = 6; tags = ["lower"; "typed"]; since = "1.9.0"; weight = 3516 };
  { key = "piston.recipe.cached_0096";                   label = "scoped_bossbar_96";           arity = 5; tags = ["sync"]; since = "1.0.0"; weight = 2339 };
  { key = "map.recipe.global_0097";                      label = "canonical_region_97";         arity = 5; tags = ["content"]; since = "1.5.2"; weight = 348 };
  { key = "compass.recipe.lazy_0098";                    label = "provisional_recipe_98";       arity = 5; tags = ["compat"; "runtime"; "lower"]; since = "1.9.0"; weight = 693 };
  { key = "cartography.recipe.public_0099";              label = "modern_target_99";            arity = 3; tags = ["core"; "parse"]; since = "1.3.1"; weight = 3979 };
  { key = "world.recipe.derived_0100";                   label = "provisional_banner_pattern_100"; arity = 3; tags = ["legacy"; "content"; "runtime"]; since = "1.7.0"; weight = 653 };
  { key = "smoker.recipe.stable_0101";                   label = "secondary_arrow_101";         arity = 7; tags = ["core"; "async"]; since = "1.4.0"; weight = 1984 };
  { key = "hologram.recipe.secondary_0102";              label = "stable_map_102";              arity = 2; tags = ["content"; "emit"]; since = "1.7.0"; weight = 2166 };
  { key = "shield.recipe.primary_0103";                  label = "loose_structure_103";         arity = 0; tags = ["sync"; "registry"; "untyped"]; since = "1.6.0"; weight = 2071 };
  { key = "item.recipe.hidden_0104";                     label = "cached_lectern_104";          arity = 5; tags = ["cached"; "sync"]; since = "1.9.0"; weight = 838 };
  { key = "inventory.recipe.derived_0105";               label = "hidden_recipe_105";           arity = 3; tags = ["legacy"]; since = "1.8.3"; weight = 3151 };
  { key = "item.recipe.secondary_0106";                  label = "hidden_tablist_106";          arity = 4; tags = ["typed"]; since = "1.2.0"; weight = 2270 };
  { key = "anvil.recipe.canonical_0107";                 label = "hidden_brewing_107";          arity = 6; tags = ["packet"; "async"]; since = "1.5.2"; weight = 3060 };
  { key = "chunk.recipe.public_0108";                    label = "lazy_gui_108";                arity = 5; tags = ["compat"; "registry"; "parse"]; since = "1.6.0"; weight = 863 };
  { key = "campfire.recipe.derived_0109";                label = "scoped_piston_109";           arity = 2; tags = ["parse"; "legacy"]; since = "1.6.0"; weight = 818 };
  { key = "bossbar.recipe.cached_0110";                  label = "public_composter_110";        arity = 6; tags = ["cold"; "content"; "compat"]; since = "1.3.1"; weight = 3376 };
  { key = "trident.recipe.modern_0111";                  label = "lazy_packet_111";             arity = 7; tags = ["core"; "async"; "lower"]; since = "1.7.0"; weight = 2943 };
  { key = "bossbar.recipe.modern_0112";                  label = "local_campfire_112";          arity = 0; tags = ["registry"; "cold"]; since = "1.5.2"; weight = 1203 };
  { key = "entity.recipe.fallback_0113";                 label = "internal_rail_113";           arity = 5; tags = ["lower"; "parse"]; since = "1.6.0"; weight = 1722 };
  { key = "repeater.recipe.scoped_0114";                 label = "canonical_potion_114";        arity = 6; tags = ["runtime"; "experimental"]; since = "1.6.0"; weight = 2447 };
  { key = "crossbow.recipe.canonical_0115";              label = "internal_bell_115";           arity = 2; tags = ["cold"; "content"]; since = "1.4.0"; weight = 1936 };
  { key = "anvil.recipe.internal_0116";                  label = "legacy_compass_116";          arity = 6; tags = ["core"; "legacy"; "lower"]; since = "1.4.0"; weight = 994 };
  { key = "attribute.recipe.local_0117";                 label = "provisional_dispenser_117";   arity = 3; tags = ["cold"]; since = "1.7.0"; weight = 2055 };
  { key = "recipe.recipe.derived_0118";                  label = "scoped_mob_118";              arity = 3; tags = ["emit"; "cold"; "typed"]; since = "1.8.3"; weight = 3288 };
  { key = "slot.recipe.legacy_0119";                     label = "strict_smoker_119";           arity = 6; tags = ["parse"]; since = "1.6.0"; weight = 746 };
  { key = "boat.recipe.scoped_0120";                     label = "canonical_trade_120";         arity = 2; tags = ["untyped"]; since = "1.5.2"; weight = 1371 };
  { key = "firework.recipe.global_0121";                 label = "legacy_observer_121";         arity = 0; tags = ["packet"; "check"; "cached"]; since = "1.9.0"; weight = 976 };
  { key = "elytra.recipe.loose_0122";                    label = "secondary_mob_122";           arity = 2; tags = ["lower"; "untyped"]; since = "1.0.0"; weight = 3180 };
  { key = "shield.recipe.fallback_0123";                 label = "fallback_bundle_123";         arity = 6; tags = ["async"]; since = "1.0.0"; weight = 70 };
  { key = "rail.recipe.canonical_0124";                  label = "cached_region_124";           arity = 3; tags = ["runtime"]; since = "1.3.1"; weight = 1257 };
  { key = "smithing.recipe.canonical_0125";              label = "hidden_rail_125";             arity = 5; tags = ["core"; "content"; "cached"]; since = "1.7.0"; weight = 3418 };
  { key = "enchant.recipe.legacy_0126";                  label = "stable_inventory_126";        arity = 6; tags = ["emit"]; since = "1.5.2"; weight = 679 };
  { key = "dropper.recipe.legacy_0127";                  label = "internal_map_127";            arity = 3; tags = ["cached"; "hot"; "content"]; since = "1.6.0"; weight = 683 };
  { key = "slot.recipe.public_0128";                     label = "strict_packet_128";           arity = 4; tags = ["compat"; "legacy"; "typed"]; since = "1.7.0"; weight = 2060 };
  { key = "barrel.recipe.primary_0129";                  label = "global_campfire_129";         arity = 5; tags = ["parse"; "content"; "check"]; since = "1.5.2"; weight = 3238 };
  { key = "target.recipe.public_0130";                   label = "modern_item_130";             arity = 7; tags = ["emit"; "core"; "cold"]; since = "1.7.0"; weight = 396 };
  { key = "team.recipe.hidden_0131";                     label = "loose_elytra_131";            arity = 1; tags = ["typed"]; since = "1.2.0"; weight = 3024 };
  { key = "anvil.recipe.local_0132";                     label = "loose_gui_132";               arity = 0; tags = ["sync"; "hot"]; since = "1.8.3"; weight = 3536 };
  { key = "attribute.recipe.internal_0133";              label = "modern_conduit_133";          arity = 7; tags = ["hot"]; since = "1.0.0"; weight = 1451 };
  { key = "particle.recipe.strict_0134";                 label = "public_gui_134";              arity = 0; tags = ["cached"; "cold"; "legacy"]; since = "1.5.2"; weight = 2960 };
  { key = "villager.recipe.canonical_0135";              label = "stable_map_135";              arity = 4; tags = ["experimental"; "typed"]; since = "1.7.0"; weight = 1671 };
  { key = "spawner.recipe.fallback_0136";                label = "derived_observer_136";        arity = 5; tags = ["hot"; "runtime"]; since = "1.4.0"; weight = 3285 };
  { key = "campfire.recipe.legacy_0137";                 label = "canonical_smithing_137";      arity = 4; tags = ["cold"; "packet"; "async"]; since = "1.7.0"; weight = 493 };
  { key = "clock.recipe.cached_0138";                    label = "internal_player_138";         arity = 6; tags = ["packet"; "runtime"]; since = "1.4.0"; weight = 3742 };
  { key = "banner_pattern.recipe.loose_0139";            label = "strict_slot_139";             arity = 6; tags = ["content"; "codegen"]; since = "1.8.3"; weight = 1555 };
  { key = "villager.recipe.scoped_0140";                 label = "hidden_trident_140";          arity = 6; tags = ["experimental"; "runtime"]; since = "1.7.0"; weight = 924 };
  { key = "beacon.recipe.modern_0141";                   label = "loose_boat_141";              arity = 3; tags = ["emit"; "compat"]; since = "1.9.0"; weight = 808 };
  { key = "shield.recipe.internal_0142";                 label = "internal_packet_142";         arity = 1; tags = ["codegen"; "sync"; "packet"]; since = "1.8.3"; weight = 1102 };
  { key = "loom.recipe.local_0143";                      label = "modern_shield_143";           arity = 6; tags = ["cold"; "registry"]; since = "1.0.0"; weight = 1340 };
  { key = "world.recipe.provisional_0144";               label = "loose_chunk_144";             arity = 6; tags = ["typed"]; since = "1.9.0"; weight = 169 };
  { key = "particle.recipe.stable_0145";                 label = "fallback_entity_145";         arity = 4; tags = ["codegen"]; since = "1.3.1"; weight = 945 };
  { key = "structure.recipe.global_0146";                label = "global_structure_146";        arity = 3; tags = ["legacy"; "hot"; "async"]; since = "1.2.0"; weight = 3129 };
  { key = "item.recipe.secondary_0147";                  label = "legacy_repeater_147";         arity = 6; tags = ["parse"]; since = "1.2.0"; weight = 276 };
  { key = "composter.recipe.global_0148";                label = "eager_block_148";             arity = 5; tags = ["legacy"]; since = "1.8.3"; weight = 1162 };
  { key = "rail.recipe.eager_0149";                      label = "global_shulker_149";          arity = 1; tags = ["async"; "compat"; "experimental"]; since = "1.6.0"; weight = 1780 };
  { key = "minecart.recipe.loose_0150";                  label = "global_bossbar_150";          arity = 2; tags = ["cached"]; since = "1.0.0"; weight = 3542 };
  { key = "enchant.recipe.scoped_0151";                  label = "hidden_slot_151";             arity = 2; tags = ["sync"; "legacy"]; since = "1.9.0"; weight = 1768 };
  { key = "boat.recipe.canonical_0152";                  label = "cached_cartography_152";      arity = 4; tags = ["runtime"]; since = "1.7.0"; weight = 2146 };
  { key = "cartography.recipe.primary_0153";             label = "local_banner_pattern_153";    arity = 1; tags = ["content"; "codegen"; "hot"]; since = "1.3.1"; weight = 2226 };
  { key = "firework.recipe.primary_0154";                label = "lazy_lectern_154";            arity = 0; tags = ["cached"]; since = "1.3.1"; weight = 253 };
  { key = "villager.recipe.cached_0155";                 label = "legacy_potion_155";           arity = 0; tags = ["legacy"]; since = "1.6.0"; weight = 3837 };
  { key = "hopper.recipe.modern_0156";                   label = "loose_hologram_156";          arity = 3; tags = ["async"; "parse"; "content"]; since = "1.2.0"; weight = 2167 };
  { key = "gui.recipe.lazy_0157";                        label = "stable_inventory_157";        arity = 0; tags = ["codegen"]; since = "1.6.0"; weight = 633 };
  { key = "recipe.recipe.canonical_0158";                label = "modern_smoker_158";           arity = 3; tags = ["hot"; "runtime"]; since = "1.7.0"; weight = 802 };
  { key = "effect.recipe.secondary_0159";                label = "scoped_sound_159";            arity = 0; tags = ["typed"]; since = "1.2.0"; weight = 1385 };
  { key = "firework.recipe.secondary_0160";              label = "eager_npc_160";               arity = 6; tags = ["content"; "compat"; "runtime"]; since = "1.0.0"; weight = 1369 };
  { key = "crossbow.recipe.cached_0161";                 label = "eager_banner_161";            arity = 6; tags = ["untyped"; "codegen"]; since = "1.3.1"; weight = 1810 };
  { key = "slot.recipe.modern_0162";                     label = "secondary_packet_162";        arity = 0; tags = ["emit"]; since = "1.9.0"; weight = 603 };
  { key = "anvil.recipe.scoped_0163";                    label = "global_block_163";            arity = 5; tags = ["registry"; "cold"; "codegen"]; since = "1.3.1"; weight = 3218 };
  { key = "minecart.recipe.hidden_0164";                 label = "modern_dispenser_164";        arity = 5; tags = ["async"; "registry"; "lower"]; since = "1.7.0"; weight = 2931 };
  { key = "banner.recipe.scoped_0165";                   label = "scoped_player_165";           arity = 1; tags = ["sync"]; since = "1.2.0"; weight = 2939 };
  { key = "repeater.recipe.internal_0166";               label = "hidden_trade_166";            arity = 6; tags = ["hot"]; since = "1.0.0"; weight = 1715 };
  { key = "target.recipe.secondary_0167";                label = "internal_banner_167";         arity = 6; tags = ["async"; "codegen"; "parse"]; since = "1.0.0"; weight = 6 };
  { key = "objective.recipe.primary_0168";               label = "hidden_clock_168";            arity = 1; tags = ["content"]; since = "1.3.1"; weight = 702 };
  { key = "tablist.recipe.public_0169";                  label = "public_pane_169";             arity = 3; tags = ["check"; "core"; "sync"]; since = "1.5.2"; weight = 2972 };
  { key = "rail.recipe.secondary_0170";                  label = "loose_bossbar_170";           arity = 1; tags = ["core"; "legacy"]; since = "1.9.0"; weight = 4037 };
  { key = "dropper.recipe.internal_0171";                label = "secondary_enchant_171";       arity = 4; tags = ["registry"; "parse"; "core"]; since = "1.0.0"; weight = 3259 };
  { key = "minecart.recipe.modern_0172";                 label = "local_beacon_172";            arity = 5; tags = ["experimental"; "untyped"; "packet"]; since = "1.5.2"; weight = 879 };
  { key = "scoreboard.recipe.secondary_0173";            label = "derived_clock_173";           arity = 6; tags = ["typed"; "legacy"; "experimental"]; since = "1.5.2"; weight = 919 };
  { key = "barrel.recipe.modern_0174";                   label = "scoped_pane_174";             arity = 4; tags = ["registry"; "check"; "compat"]; since = "1.4.0"; weight = 3413 };
  { key = "dispenser.recipe.hidden_0175";                label = "hidden_anvil_175";            arity = 5; tags = ["async"; "sync"]; since = "1.0.0"; weight = 1941 };
  { key = "structure.recipe.fallback_0176";              label = "derived_bell_176";            arity = 4; tags = ["hot"]; since = "1.8.3"; weight = 1857 };
  { key = "biome.recipe.global_0177";                    label = "stable_elytra_177";           arity = 1; tags = ["experimental"; "check"]; since = "1.6.0"; weight = 2537 };
  { key = "recipe.recipe.local_0178";                    label = "strict_mob_178";              arity = 3; tags = ["content"; "registry"]; since = "1.5.2"; weight = 2637 };
  { key = "portal.recipe.primary_0179";                  label = "global_hologram_179";         arity = 4; tags = ["legacy"]; since = "1.9.0"; weight = 1147 };
  { key = "clock.recipe.local_0180";                     label = "fallback_inventory_180";      arity = 3; tags = ["untyped"]; since = "1.5.2"; weight = 2087 };
  { key = "target.recipe.canonical_0181";                label = "secondary_cartography_181";   arity = 0; tags = ["cached"; "typed"; "core"]; since = "1.2.0"; weight = 3337 };
  { key = "attribute.recipe.primary_0182";               label = "provisional_team_182";        arity = 3; tags = ["lower"; "emit"]; since = "1.6.0"; weight = 2409 };
  { key = "stonecutter.recipe.cached_0183";              label = "eager_banner_pattern_183";    arity = 6; tags = ["typed"]; since = "1.8.3"; weight = 1348 };
  { key = "arrow.recipe.primary_0184";                   label = "cached_stonecutter_184";      arity = 1; tags = ["cold"; "runtime"; "cached"]; since = "1.4.0"; weight = 313 };
  { key = "compass.recipe.legacy_0185";                  label = "stable_anvil_185";            arity = 3; tags = ["core"; "packet"]; since = "1.0.0"; weight = 403 };
  { key = "beacon.recipe.strict_0186";                   label = "internal_lectern_186";        arity = 3; tags = ["emit"]; since = "1.8.3"; weight = 356 };
  { key = "minecart.recipe.global_0187";                 label = "strict_firework_187";         arity = 4; tags = ["lower"]; since = "1.7.0"; weight = 223 };
  { key = "pane.recipe.derived_0188";                    label = "public_rail_188";             arity = 7; tags = ["untyped"; "sync"]; since = "1.0.0"; weight = 405 };
  { key = "region.recipe.loose_0189";                    label = "fallback_dispenser_189";      arity = 4; tags = ["emit"; "sync"]; since = "1.8.3"; weight = 602 };
  { key = "npc.recipe.global_0190";                      label = "eager_loom_190";              arity = 4; tags = ["core"; "registry"; "runtime"]; since = "1.2.0"; weight = 2067 };
  { key = "brewing.recipe.cached_0191";                  label = "scoped_enchant_191";          arity = 6; tags = ["cold"; "cached"]; since = "1.4.0"; weight = 977 };
  { key = "minecart.recipe.modern_0192";                 label = "stable_block_192";            arity = 4; tags = ["runtime"]; since = "1.4.0"; weight = 3096 };
  { key = "target.recipe.strict_0193";                   label = "scoped_grindstone_193";       arity = 5; tags = ["typed"; "codegen"]; since = "1.5.2"; weight = 2163 };
  { key = "target.recipe.lazy_0194";                     label = "provisional_grindstone_194";  arity = 7; tags = ["check"; "cold"]; since = "1.8.3"; weight = 1901 };
  { key = "chunk.recipe.primary_0195";                   label = "primary_trade_195";           arity = 3; tags = ["async"; "content"; "legacy"]; since = "1.4.0"; weight = 3263 };
  { key = "rail.recipe.global_0196";                     label = "modern_tablist_196";          arity = 3; tags = ["sync"]; since = "1.4.0"; weight = 154 };
  { key = "minecart.recipe.stable_0197";                 label = "canonical_structure_197";     arity = 3; tags = ["codegen"; "experimental"; "emit"]; since = "1.4.0"; weight = 2706 };
  { key = "particle.recipe.public_0198";                 label = "local_clock_198";             arity = 3; tags = ["untyped"; "experimental"; "sync"]; since = "1.3.1"; weight = 1113 };
  { key = "shield.recipe.scoped_0199";                   label = "hidden_target_199";           arity = 5; tags = ["lower"; "registry"]; since = "1.0.0"; weight = 2777 };
  { key = "boat.recipe.provisional_0200";                label = "canonical_block_200";         arity = 6; tags = ["packet"; "experimental"; "emit"]; since = "1.3.1"; weight = 905 };
  { key = "comparator.recipe.provisional_0201";          label = "cached_furnace_201";          arity = 2; tags = ["parse"; "lower"]; since = "1.7.0"; weight = 3393 };
  { key = "boat.recipe.hidden_0202";                     label = "derived_entity_202";          arity = 3; tags = ["codegen"]; since = "1.7.0"; weight = 2158 };
  { key = "npc.recipe.fallback_0203";                    label = "global_structure_203";        arity = 3; tags = ["async"; "check"; "codegen"]; since = "1.6.0"; weight = 2168 };
  { key = "hologram.recipe.derived_0204";                label = "secondary_grindstone_204";    arity = 5; tags = ["legacy"]; since = "1.3.1"; weight = 161 };
  { key = "repeater.recipe.canonical_0205";              label = "fallback_smoker_205";         arity = 0; tags = ["sync"]; since = "1.0.0"; weight = 25 };
  { key = "enchant.recipe.loose_0206";                   label = "lazy_lectern_206";            arity = 1; tags = ["codegen"; "typed"]; since = "1.7.0"; weight = 2459 };
  { key = "world.recipe.hidden_0207";                    label = "public_bundle_207";           arity = 0; tags = ["content"; "cached"; "async"]; since = "1.6.0"; weight = 2422 };
  { key = "boat.recipe.public_0208";                     label = "hidden_trade_208";            arity = 3; tags = ["untyped"; "packet"; "codegen"]; since = "1.6.0"; weight = 2259 };
  { key = "biome.recipe.fallback_0209";                  label = "modern_lectern_209";          arity = 3; tags = ["legacy"; "hot"; "content"]; since = "1.9.0"; weight = 3602 };
  { key = "packet.recipe.canonical_0210";                label = "internal_biome_210";          arity = 2; tags = ["emit"; "parse"; "core"]; since = "1.6.0"; weight = 2216 };
  { key = "loom.recipe.secondary_0211";                  label = "hidden_grindstone_211";       arity = 0; tags = ["core"]; since = "1.5.2"; weight = 1729 };
  { key = "pane.recipe.derived_0212";                    label = "secondary_conduit_212";       arity = 2; tags = ["typed"; "legacy"]; since = "1.5.2"; weight = 2938 };
  { key = "piston.recipe.legacy_0213";                   label = "legacy_arrow_213";            arity = 7; tags = ["parse"; "runtime"]; since = "1.6.0"; weight = 2649 };
  { key = "villager.recipe.derived_0214";                label = "loose_world_214";             arity = 3; tags = ["async"; "compat"]; since = "1.7.0"; weight = 3069 };
  { key = "repeater.recipe.provisional_0215";            label = "scoped_banner_215";           arity = 7; tags = ["packet"]; since = "1.3.1"; weight = 3106 };
  { key = "lectern.recipe.secondary_0216";               label = "scoped_packet_216";           arity = 0; tags = ["typed"]; since = "1.3.1"; weight = 402 };
  { key = "rail.recipe.secondary_0217";                  label = "internal_entity_217";         arity = 1; tags = ["cold"; "sync"; "legacy"]; since = "1.7.0"; weight = 3434 };
  { key = "arrow.recipe.cached_0218";                    label = "eager_loom_218";              arity = 0; tags = ["sync"; "cold"]; since = "1.8.3"; weight = 2317 };
  { key = "objective.recipe.strict_0219";                label = "modern_shulker_219";          arity = 0; tags = ["emit"; "typed"; "core"]; since = "1.4.0"; weight = 2563 };
  { key = "player.recipe.public_0220";                   label = "strict_shulker_220";          arity = 7; tags = ["codegen"; "sync"]; since = "1.4.0"; weight = 2925 };
  { key = "clock.recipe.canonical_0221";                 label = "eager_potion_221";            arity = 2; tags = ["content"; "untyped"]; since = "1.6.0"; weight = 2509 };
  { key = "loom.recipe.eager_0222";                      label = "secondary_bundle_222";        arity = 5; tags = ["lower"]; since = "1.3.1"; weight = 2723 };
  { key = "anvil.recipe.lazy_0223";                      label = "fallback_enchant_223";        arity = 5; tags = ["parse"; "core"]; since = "1.3.1"; weight = 2103 };
  { key = "campfire.recipe.modern_0224";                 label = "global_packet_224";           arity = 4; tags = ["check"; "sync"; "packet"]; since = "1.3.1"; weight = 632 };
  { key = "rail.recipe.public_0225";                     label = "scoped_anvil_225";            arity = 5; tags = ["sync"; "experimental"]; since = "1.6.0"; weight = 434 };
  { key = "rail.recipe.hidden_0226";                     label = "internal_attribute_226";      arity = 4; tags = ["hot"]; since = "1.9.0"; weight = 3914 };
  { key = "conduit.recipe.cached_0227";                  label = "global_recipe_227";           arity = 1; tags = ["registry"; "cold"; "typed"]; since = "1.3.1"; weight = 3170 };
  { key = "player.recipe.modern_0228";                   label = "canonical_barrel_228";        arity = 7; tags = ["experimental"; "runtime"; "typed"]; since = "1.0.0"; weight = 753 };
  { key = "boat.recipe.cached_0229";                     label = "cached_hologram_229";         arity = 4; tags = ["parse"; "cold"]; since = "1.5.2"; weight = 2644 };
  { key = "chunk.recipe.eager_0230";                     label = "provisional_shield_230";      arity = 0; tags = ["sync"]; since = "1.3.1"; weight = 1686 };
  { key = "structure.recipe.provisional_0231";           label = "eager_team_231";              arity = 0; tags = ["emit"; "cached"; "packet"]; since = "1.0.0"; weight = 3202 };
  { key = "chunk.recipe.derived_0232";                   label = "modern_player_232";           arity = 5; tags = ["cached"]; since = "1.5.2"; weight = 3182 };
  { key = "enchant.recipe.public_0233";                  label = "loose_elytra_233";            arity = 2; tags = ["cold"; "registry"; "parse"]; since = "1.4.0"; weight = 1482 };
  { key = "mob.recipe.global_0234";                      label = "public_banner_pattern_234";   arity = 5; tags = ["emit"; "parse"; "untyped"]; since = "1.2.0"; weight = 3292 };
  { key = "effect.recipe.stable_0235";                   label = "public_clock_235";            arity = 7; tags = ["typed"]; since = "1.4.0"; weight = 2786 };
  { key = "arrow.recipe.internal_0236";                  label = "stable_sound_236";            arity = 6; tags = ["lower"; "untyped"; "codegen"]; since = "1.0.0"; weight = 2917 };
  { key = "dropper.recipe.primary_0237";                 label = "stable_banner_237";           arity = 7; tags = ["typed"; "compat"]; since = "1.0.0"; weight = 62 };
  { key = "packet.recipe.cached_0238";                   label = "eager_scoreboard_238";        arity = 4; tags = ["cached"; "parse"]; since = "1.9.0"; weight = 741 };
  { key = "effect.recipe.scoped_0239";                   label = "public_trident_239";          arity = 4; tags = ["check"; "compat"; "cached"]; since = "1.7.0"; weight = 1166 };
  { key = "mob.recipe.loose_0240";                       label = "modern_portal_240";           arity = 0; tags = ["parse"]; since = "1.6.0"; weight = 3231 };
  { key = "rail.recipe.local_0241";                      label = "lazy_stonecutter_241";        arity = 2; tags = ["check"; "sync"]; since = "1.3.1"; weight = 3139 };
  { key = "chunk.recipe.loose_0242";                     label = "cached_hologram_242";         arity = 1; tags = ["runtime"; "cached"]; since = "1.7.0"; weight = 1237 };
  { key = "smoker.recipe.legacy_0243";                   label = "public_brewing_243";          arity = 3; tags = ["lower"; "parse"]; since = "1.3.1"; weight = 3396 };
  { key = "hopper.recipe.global_0244";                   label = "eager_grindstone_244";        arity = 3; tags = ["lower"; "hot"; "legacy"]; since = "1.6.0"; weight = 2752 };
  { key = "spawner.recipe.canonical_0245";               label = "loose_tablist_245";           arity = 4; tags = ["codegen"; "packet"]; since = "1.9.0"; weight = 773 };
  { key = "villager.recipe.cached_0246";                 label = "legacy_slot_246";             arity = 5; tags = ["hot"; "runtime"]; since = "1.4.0"; weight = 2619 };
  { key = "world.recipe.loose_0247";                     label = "lazy_block_247";              arity = 1; tags = ["runtime"; "cached"; "experimental"]; since = "1.9.0"; weight = 2735 };
  { key = "repeater.recipe.local_0248";                  label = "hidden_structure_248";        arity = 3; tags = ["sync"]; since = "1.0.0"; weight = 3408 };
  { key = "banner.recipe.strict_0249";                   label = "public_region_249";           arity = 6; tags = ["cached"; "sync"; "legacy"]; since = "1.6.0"; weight = 3739 };
  { key = "hologram.recipe.secondary_0250";              label = "lazy_villager_250";           arity = 0; tags = ["typed"]; since = "1.6.0"; weight = 2335 };
  { key = "hopper.recipe.cached_0251";                   label = "public_slot_251";             arity = 6; tags = ["emit"; "content"]; since = "1.6.0"; weight = 2099 };
  { key = "enchant.recipe.stable_0252";                  label = "derived_slot_252";            arity = 6; tags = ["registry"]; since = "1.6.0"; weight = 3378 };
  { key = "hologram.recipe.eager_0253";                  label = "cached_lectern_253";          arity = 5; tags = ["codegen"; "typed"; "compat"]; since = "1.9.0"; weight = 3306 };
  { key = "trade.recipe.secondary_0254";                 label = "stable_loom_254";             arity = 5; tags = ["sync"]; since = "1.6.0"; weight = 1318 };
  { key = "comparator.recipe.global_0255";               label = "modern_trident_255";          arity = 7; tags = ["sync"]; since = "1.6.0"; weight = 2352 };
  { key = "attribute.recipe.public_0256";                label = "loose_bundle_256";            arity = 7; tags = ["emit"]; since = "1.8.3"; weight = 3705 };
  { key = "beacon.recipe.loose_0257";                    label = "global_team_257";             arity = 5; tags = ["packet"]; since = "1.4.0"; weight = 3537 };
  { key = "world.recipe.scoped_0258";                    label = "secondary_beacon_258";        arity = 4; tags = ["emit"; "async"; "sync"]; since = "1.9.0"; weight = 1735 };
  { key = "advancement.recipe.legacy_0259";              label = "stable_scoreboard_259";       arity = 7; tags = ["runtime"]; since = "1.5.2"; weight = 1295 };
  { key = "block.recipe.loose_0260";                     label = "cached_crossbow_260";         arity = 6; tags = ["experimental"; "content"; "async"]; since = "1.9.0"; weight = 1478 };
  { key = "hopper.recipe.stable_0261";                   label = "scoped_objective_261";        arity = 5; tags = ["hot"; "core"]; since = "1.3.1"; weight = 592 };
  { key = "team.recipe.lazy_0262";                       label = "scoped_world_262";            arity = 0; tags = ["sync"; "lower"; "parse"]; since = "1.8.3"; weight = 2520 };
  { key = "gui.recipe.provisional_0263";                 label = "canonical_grindstone_263";    arity = 7; tags = ["cold"; "untyped"; "packet"]; since = "1.8.3"; weight = 199 };
]

let count = List.length entries

let table : (string, recipe_entry) Hashtbl.t =
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
