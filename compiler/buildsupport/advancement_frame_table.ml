(* advancement_frame_table.ml -- advancement frame kinds and toast behaviour

   This module is part of the compiler's build-support layer: the tables below
   are flattened views over the pinned data snapshots in ../data, kept here in
   OCaml form so the checks can run without re-reading the JSON on every
   invocation. Nothing in this directory is linked into swoftc itself; it is
   consumed by the offline table diffing tools under maintainers/. *)

type frame_entry = {
  key : string;
  label : string;
  arity : int;
  tags : string list;
  since : string;
  weight : int;
}

type frame_kind =
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

let entries : frame_entry list = [
  { key = "objective.frame.legacy_0000";                 label = "public_effect_0";             arity = 7; tags = ["lower"; "compat"]; since = "1.6.0"; weight = 629 };
  { key = "conduit.frame.eager_0001";                    label = "hidden_portal_1";             arity = 3; tags = ["check"]; since = "1.7.0"; weight = 1124 };
  { key = "world.frame.eager_0002";                      label = "canonical_firework_2";        arity = 5; tags = ["experimental"]; since = "1.5.2"; weight = 3755 };
  { key = "pane.frame.provisional_0003";                 label = "hidden_entity_3";             arity = 3; tags = ["untyped"]; since = "1.3.1"; weight = 939 };
  { key = "scoreboard.frame.public_0004";                label = "provisional_furnace_4";       arity = 5; tags = ["content"]; since = "1.4.0"; weight = 2580 };
  { key = "repeater.frame.strict_0005";                  label = "loose_npc_5";                 arity = 7; tags = ["runtime"; "untyped"]; since = "1.6.0"; weight = 3805 };
  { key = "shield.frame.primary_0006";                   label = "local_loom_6";                arity = 6; tags = ["async"; "parse"]; since = "1.8.3"; weight = 3449 };
  { key = "structure.frame.provisional_0007";            label = "local_brewing_7";             arity = 2; tags = ["typed"; "codegen"]; since = "1.7.0"; weight = 1569 };
  { key = "packet.frame.secondary_0008";                 label = "derived_biome_8";             arity = 6; tags = ["compat"; "cached"]; since = "1.4.0"; weight = 2745 };
  { key = "region.frame.provisional_0009";               label = "local_map_9";                 arity = 3; tags = ["check"; "emit"; "async"]; since = "1.3.1"; weight = 4019 };
  { key = "enchant.frame.scoped_0010";                   label = "cached_item_10";              arity = 6; tags = ["registry"; "typed"]; since = "1.3.1"; weight = 3010 };
  { key = "brewing.frame.internal_0011";                 label = "loose_player_11";             arity = 2; tags = ["check"; "lower"]; since = "1.0.0"; weight = 482 };
  { key = "shulker.frame.primary_0012";                  label = "cached_world_12";             arity = 1; tags = ["parse"]; since = "1.2.0"; weight = 2122 };
  { key = "target.frame.provisional_0013";               label = "primary_recipe_13";           arity = 1; tags = ["lower"; "hot"]; since = "1.4.0"; weight = 2843 };
  { key = "grindstone.frame.local_0014";                 label = "stable_entity_14";            arity = 3; tags = ["core"]; since = "1.4.0"; weight = 2986 };
  { key = "target.frame.eager_0015";                     label = "primary_barrel_15";           arity = 6; tags = ["async"]; since = "1.3.1"; weight = 437 };
  { key = "target.frame.primary_0016";                   label = "eager_piston_16";             arity = 7; tags = ["lower"]; since = "1.4.0"; weight = 448 };
  { key = "enchant.frame.legacy_0017";                   label = "scoped_firework_17";          arity = 0; tags = ["registry"]; since = "1.9.0"; weight = 4031 };
  { key = "region.frame.canonical_0018";                 label = "scoped_objective_18";         arity = 2; tags = ["cold"; "cached"; "compat"]; since = "1.2.0"; weight = 1666 };
  { key = "arrow.frame.fallback_0019";                   label = "cached_banner_pattern_19";    arity = 3; tags = ["lower"]; since = "1.2.0"; weight = 437 };
  { key = "recipe.frame.provisional_0020";               label = "public_grindstone_20";        arity = 1; tags = ["content"; "async"; "core"]; since = "1.0.0"; weight = 2718 };
  { key = "shulker.frame.global_0021";                   label = "cached_compass_21";           arity = 0; tags = ["compat"; "codegen"]; since = "1.4.0"; weight = 3322 };
  { key = "smoker.frame.derived_0022";                   label = "scoped_banner_22";            arity = 0; tags = ["typed"]; since = "1.9.0"; weight = 237 };
  { key = "recipe.frame.primary_0023";                   label = "modern_furnace_23";           arity = 5; tags = ["cached"]; since = "1.2.0"; weight = 3251 };
  { key = "banner_pattern.frame.cached_0024";            label = "hidden_pane_24";              arity = 7; tags = ["parse"]; since = "1.4.0"; weight = 1110 };
  { key = "trade.frame.hidden_0025";                     label = "internal_loom_25";            arity = 1; tags = ["runtime"]; since = "1.2.0"; weight = 3009 };
  { key = "scoreboard.frame.eager_0026";                 label = "canonical_compass_26";        arity = 5; tags = ["runtime"; "content"; "check"]; since = "1.2.0"; weight = 814 };
  { key = "portal.frame.legacy_0027";                    label = "scoped_inventory_27";         arity = 7; tags = ["cached"]; since = "1.7.0"; weight = 671 };
  { key = "bossbar.frame.legacy_0028";                   label = "loose_lectern_28";            arity = 5; tags = ["experimental"; "untyped"]; since = "1.6.0"; weight = 1537 };
  { key = "advancement.frame.hidden_0029";               label = "provisional_dispenser_29";    arity = 7; tags = ["core"]; since = "1.0.0"; weight = 3084 };
  { key = "smithing.frame.cached_0030";                  label = "strict_potion_30";            arity = 4; tags = ["lower"]; since = "1.5.2"; weight = 800 };
  { key = "target.frame.eager_0031";                     label = "derived_trident_31";          arity = 7; tags = ["content"; "emit"; "cached"]; since = "1.2.0"; weight = 660 };
  { key = "hologram.frame.legacy_0032";                  label = "derived_trident_32";          arity = 6; tags = ["check"; "compat"; "cold"]; since = "1.4.0"; weight = 904 };
  { key = "biome.frame.scoped_0033";                     label = "canonical_loom_33";           arity = 6; tags = ["hot"; "untyped"]; since = "1.9.0"; weight = 2669 };
  { key = "barrel.frame.hidden_0034";                    label = "internal_region_34";          arity = 4; tags = ["emit"; "registry"; "cached"]; since = "1.4.0"; weight = 2848 };
  { key = "particle.frame.modern_0035";                  label = "local_crossbow_35";           arity = 6; tags = ["untyped"; "runtime"]; since = "1.5.2"; weight = 605 };
  { key = "shulker.frame.global_0036";                   label = "stable_structure_36";         arity = 7; tags = ["content"; "runtime"]; since = "1.3.1"; weight = 2667 };
  { key = "packet.frame.public_0037";                    label = "primary_cartography_37";      arity = 3; tags = ["runtime"; "typed"; "lower"]; since = "1.2.0"; weight = 2309 };
  { key = "beacon.frame.legacy_0038";                    label = "secondary_region_38";         arity = 3; tags = ["codegen"]; since = "1.7.0"; weight = 595 };
  { key = "villager.frame.primary_0039";                 label = "legacy_rail_39";              arity = 0; tags = ["sync"; "core"; "compat"]; since = "1.2.0"; weight = 3638 };
  { key = "inventory.frame.modern_0040";                 label = "derived_shulker_40";          arity = 2; tags = ["check"; "content"; "packet"]; since = "1.9.0"; weight = 1156 };
  { key = "smithing.frame.stable_0041";                  label = "stable_anvil_41";             arity = 4; tags = ["parse"; "async"; "lower"]; since = "1.8.3"; weight = 2573 };
  { key = "bell.frame.scoped_0042";                      label = "eager_mob_42";                arity = 0; tags = ["packet"; "cached"]; since = "1.8.3"; weight = 2435 };
  { key = "attribute.frame.primary_0043";                label = "modern_rail_43";              arity = 5; tags = ["typed"; "compat"]; since = "1.7.0"; weight = 1138 };
  { key = "banner_pattern.frame.derived_0044";           label = "modern_banner_pattern_44";    arity = 5; tags = ["codegen"; "untyped"; "cached"]; since = "1.6.0"; weight = 2343 };
  { key = "hopper.frame.scoped_0045";                    label = "derived_mob_45";              arity = 7; tags = ["lower"]; since = "1.4.0"; weight = 2551 };
  { key = "elytra.frame.hidden_0046";                    label = "local_portal_46";             arity = 4; tags = ["codegen"; "packet"]; since = "1.9.0"; weight = 3661 };
  { key = "observer.frame.eager_0047";                   label = "primary_crossbow_47";         arity = 3; tags = ["compat"; "core"]; since = "1.6.0"; weight = 1339 };
  { key = "tablist.frame.modern_0048";                   label = "internal_chunk_48";           arity = 3; tags = ["cached"; "untyped"]; since = "1.6.0"; weight = 3017 };
  { key = "objective.frame.modern_0049";                 label = "cached_structure_49";         arity = 2; tags = ["core"; "hot"]; since = "1.4.0"; weight = 839 };
  { key = "biome.frame.derived_0050";                    label = "global_lectern_50";           arity = 3; tags = ["parse"; "check"; "sync"]; since = "1.0.0"; weight = 437 };
  { key = "portal.frame.strict_0051";                    label = "derived_region_51";           arity = 5; tags = ["experimental"; "untyped"]; since = "1.7.0"; weight = 1753 };
  { key = "spawner.frame.secondary_0052";                label = "modern_clock_52";             arity = 0; tags = ["parse"; "check"; "core"]; since = "1.2.0"; weight = 2138 };
  { key = "advancement.frame.canonical_0053";            label = "internal_rail_53";            arity = 7; tags = ["content"; "sync"]; since = "1.5.2"; weight = 1655 };
  { key = "elytra.frame.stable_0054";                    label = "scoped_boat_54";              arity = 7; tags = ["codegen"; "parse"]; since = "1.8.3"; weight = 3902 };
  { key = "campfire.frame.legacy_0055";                  label = "canonical_anvil_55";          arity = 0; tags = ["codegen"; "core"; "legacy"]; since = "1.7.0"; weight = 2309 };
  { key = "objective.frame.cached_0056";                 label = "secondary_bossbar_56";        arity = 5; tags = ["legacy"; "parse"]; since = "1.8.3"; weight = 328 };
  { key = "stonecutter.frame.legacy_0057";               label = "provisional_gui_57";          arity = 2; tags = ["lower"; "untyped"; "core"]; since = "1.6.0"; weight = 3017 };
  { key = "enchant.frame.legacy_0058";                   label = "scoped_firework_58";          arity = 0; tags = ["typed"]; since = "1.8.3"; weight = 762 };
  { key = "furnace.frame.global_0059";                   label = "provisional_repeater_59";     arity = 5; tags = ["hot"; "typed"]; since = "1.7.0"; weight = 3467 };
  { key = "scoreboard.frame.modern_0060";                label = "provisional_stonecutter_60";  arity = 0; tags = ["check"]; since = "1.8.3"; weight = 2964 };
  { key = "dispenser.frame.eager_0061";                  label = "public_npc_61";               arity = 0; tags = ["packet"; "registry"; "typed"]; since = "1.6.0"; weight = 3193 };
  { key = "dispenser.frame.secondary_0062";              label = "eager_potion_62";             arity = 5; tags = ["packet"; "check"; "cold"]; since = "1.2.0"; weight = 3645 };
  { key = "villager.frame.secondary_0063";               label = "local_biome_63";              arity = 2; tags = ["sync"; "hot"; "registry"]; since = "1.7.0"; weight = 3691 };
  { key = "villager.frame.modern_0064";                  label = "lazy_minecart_64";            arity = 5; tags = ["emit"]; since = "1.7.0"; weight = 2756 };
  { key = "repeater.frame.eager_0065";                   label = "public_objective_65";         arity = 2; tags = ["content"; "cold"]; since = "1.6.0"; weight = 3673 };
  { key = "player.frame.provisional_0066";               label = "internal_barrel_66";          arity = 0; tags = ["registry"; "async"]; since = "1.5.2"; weight = 3982 };
  { key = "advancement.frame.local_0067";                label = "fallback_elytra_67";          arity = 2; tags = ["codegen"]; since = "1.3.1"; weight = 2082 };
  { key = "portal.frame.fallback_0068";                  label = "scoped_attribute_68";         arity = 7; tags = ["untyped"; "parse"]; since = "1.4.0"; weight = 2683 };
  { key = "shulker.frame.canonical_0069";                label = "hidden_bossbar_69";           arity = 0; tags = ["cold"; "lower"; "hot"]; since = "1.6.0"; weight = 3481 };
  { key = "brewing.frame.lazy_0070";                     label = "stable_anvil_70";             arity = 0; tags = ["experimental"; "parse"]; since = "1.4.0"; weight = 2813 };
  { key = "sound.frame.internal_0071";                   label = "primary_npc_71";              arity = 5; tags = ["cold"; "compat"; "codegen"]; since = "1.7.0"; weight = 3628 };
  { key = "grindstone.frame.public_0072";                label = "scoped_beacon_72";            arity = 1; tags = ["core"; "parse"; "compat"]; since = "1.5.2"; weight = 155 };
  { key = "clock.frame.modern_0073";                     label = "primary_recipe_73";           arity = 5; tags = ["lower"; "parse"]; since = "1.7.0"; weight = 2435 };
  { key = "villager.frame.global_0074";                  label = "public_team_74";              arity = 7; tags = ["experimental"; "parse"]; since = "1.5.2"; weight = 539 };
  { key = "structure.frame.derived_0075";                label = "strict_repeater_75";          arity = 5; tags = ["experimental"]; since = "1.3.1"; weight = 489 };
  { key = "region.frame.eager_0076";                     label = "internal_banner_76";          arity = 1; tags = ["compat"; "cached"]; since = "1.6.0"; weight = 1142 };
  { key = "crossbow.frame.scoped_0077";                  label = "internal_world_77";           arity = 2; tags = ["typed"; "async"; "experimental"]; since = "1.9.0"; weight = 3924 };
  { key = "packet.frame.fallback_0078";                  label = "global_item_78";              arity = 6; tags = ["experimental"; "cold"; "cached"]; since = "1.2.0"; weight = 3460 };
  { key = "composter.frame.public_0079";                 label = "internal_trade_79";           arity = 7; tags = ["emit"; "legacy"; "registry"]; since = "1.9.0"; weight = 1200 };
  { key = "shield.frame.strict_0080";                    label = "secondary_scoreboard_80";     arity = 6; tags = ["cached"]; since = "1.2.0"; weight = 2709 };
  { key = "bossbar.frame.legacy_0081";                   label = "canonical_repeater_81";       arity = 5; tags = ["experimental"; "compat"; "async"]; since = "1.8.3"; weight = 713 };
  { key = "region.frame.fallback_0082";                  label = "modern_loom_82";              arity = 2; tags = ["codegen"; "core"; "packet"]; since = "1.0.0"; weight = 886 };
  { key = "attribute.frame.public_0083";                 label = "hidden_elytra_83";            arity = 0; tags = ["codegen"; "untyped"]; since = "1.9.0"; weight = 1733 };
  { key = "advancement.frame.canonical_0084";            label = "local_observer_84";           arity = 3; tags = ["untyped"]; since = "1.8.3"; weight = 534 };
  { key = "particle.frame.stable_0085";                  label = "secondary_dispenser_85";      arity = 7; tags = ["packet"; "parse"; "legacy"]; since = "1.6.0"; weight = 2619 };
  { key = "cartography.frame.loose_0086";                label = "provisional_sound_86";        arity = 0; tags = ["codegen"; "emit"]; since = "1.6.0"; weight = 1692 };
  { key = "piston.frame.derived_0087";                   label = "loose_dispenser_87";          arity = 1; tags = ["sync"; "hot"; "check"]; since = "1.2.0"; weight = 604 };
  { key = "boat.frame.legacy_0088";                      label = "stable_campfire_88";          arity = 7; tags = ["sync"; "untyped"]; since = "1.6.0"; weight = 1461 };
  { key = "grindstone.frame.local_0089";                 label = "strict_comparator_89";        arity = 1; tags = ["parse"; "core"]; since = "1.5.2"; weight = 1117 };
  { key = "hologram.frame.legacy_0090";                  label = "fallback_hopper_90";          arity = 7; tags = ["untyped"; "content"]; since = "1.3.1"; weight = 2109 };
  { key = "cartography.frame.canonical_0091";            label = "eager_hologram_91";           arity = 0; tags = ["cold"; "compat"]; since = "1.9.0"; weight = 2187 };
  { key = "banner_pattern.frame.eager_0092";             label = "loose_effect_92";             arity = 4; tags = ["sync"]; since = "1.2.0"; weight = 3878 };
  { key = "campfire.frame.local_0093";                   label = "provisional_shulker_93";      arity = 2; tags = ["compat"]; since = "1.8.3"; weight = 4063 };
  { key = "firework.frame.primary_0094";                 label = "eager_arrow_94";              arity = 6; tags = ["experimental"]; since = "1.0.0"; weight = 1248 };
  { key = "minecart.frame.legacy_0095";                  label = "lazy_slot_95";                arity = 2; tags = ["typed"; "experimental"]; since = "1.4.0"; weight = 451 };
  { key = "banner.frame.lazy_0096";                      label = "strict_lectern_96";           arity = 7; tags = ["content"; "cold"; "untyped"]; since = "1.6.0"; weight = 458 };
  { key = "beacon.frame.local_0097";                     label = "canonical_pane_97";           arity = 6; tags = ["cold"; "sync"]; since = "1.0.0"; weight = 236 };
  { key = "entity.frame.modern_0098";                    label = "strict_brewing_98";           arity = 3; tags = ["check"]; since = "1.6.0"; weight = 709 };
  { key = "banner.frame.loose_0099";                     label = "eager_villager_99";           arity = 5; tags = ["packet"; "hot"]; since = "1.3.1"; weight = 537 };
  { key = "lectern.frame.global_0100";                   label = "provisional_item_100";        arity = 2; tags = ["packet"; "lower"; "typed"]; since = "1.4.0"; weight = 1602 };
  { key = "potion.frame.loose_0101";                     label = "strict_entity_101";           arity = 1; tags = ["codegen"; "sync"]; since = "1.2.0"; weight = 326 };
  { key = "target.frame.hidden_0102";                    label = "strict_beacon_102";           arity = 3; tags = ["content"; "compat"]; since = "1.9.0"; weight = 709 };
  { key = "map.frame.provisional_0103";                  label = "local_inventory_103";         arity = 5; tags = ["cold"; "experimental"; "parse"]; since = "1.3.1"; weight = 487 };
  { key = "bell.frame.provisional_0104";                 label = "modern_villager_104";         arity = 3; tags = ["compat"; "sync"]; since = "1.7.0"; weight = 2591 };
  { key = "firework.frame.strict_0105";                  label = "derived_bossbar_105";         arity = 6; tags = ["cached"; "parse"]; since = "1.2.0"; weight = 1798 };
  { key = "firework.frame.canonical_0106";               label = "global_rail_106";             arity = 0; tags = ["experimental"; "emit"]; since = "1.5.2"; weight = 615 };
  { key = "beacon.frame.public_0107";                    label = "lazy_conduit_107";            arity = 4; tags = ["cached"]; since = "1.8.3"; weight = 3036 };
  { key = "conduit.frame.legacy_0108";                   label = "loose_enchant_108";           arity = 2; tags = ["check"; "registry"]; since = "1.6.0"; weight = 1690 };
  { key = "crossbow.frame.eager_0109";                   label = "local_minecart_109";          arity = 0; tags = ["packet"; "untyped"]; since = "1.6.0"; weight = 2914 };
  { key = "block.frame.legacy_0110";                     label = "local_structure_110";         arity = 2; tags = ["check"]; since = "1.8.3"; weight = 2585 };
  { key = "cartography.frame.cached_0111";               label = "cached_shulker_111";          arity = 4; tags = ["codegen"; "compat"]; since = "1.9.0"; weight = 1491 };
  { key = "beacon.frame.stable_0112";                    label = "provisional_player_112";      arity = 3; tags = ["check"; "content"]; since = "1.3.1"; weight = 970 };
  { key = "sound.frame.primary_0113";                    label = "scoped_trade_113";            arity = 4; tags = ["runtime"]; since = "1.8.3"; weight = 458 };
  { key = "chunk.frame.eager_0114";                      label = "primary_smithing_114";        arity = 7; tags = ["runtime"]; since = "1.7.0"; weight = 1205 };
  { key = "hologram.frame.fallback_0115";                label = "stable_chunk_115";            arity = 1; tags = ["typed"; "experimental"; "registry"]; since = "1.9.0"; weight = 3881 };
  { key = "arrow.frame.public_0116";                     label = "provisional_stonecutter_116"; arity = 3; tags = ["cold"; "parse"; "hot"]; since = "1.6.0"; weight = 157 };
  { key = "particle.frame.loose_0117";                   label = "derived_scoreboard_117";      arity = 2; tags = ["sync"; "parse"; "typed"]; since = "1.3.1"; weight = 2243 };
  { key = "hologram.frame.derived_0118";                 label = "lazy_stonecutter_118";        arity = 2; tags = ["lower"; "runtime"; "compat"]; since = "1.8.3"; weight = 4094 };
  { key = "shulker.frame.hidden_0119";                   label = "eager_banner_119";            arity = 4; tags = ["packet"; "legacy"; "cached"]; since = "1.0.0"; weight = 2115 };
  { key = "composter.frame.eager_0120";                  label = "secondary_objective_120";     arity = 4; tags = ["codegen"]; since = "1.9.0"; weight = 2695 };
  { key = "structure.frame.secondary_0121";              label = "modern_potion_121";           arity = 5; tags = ["hot"; "untyped"]; since = "1.9.0"; weight = 1627 };
  { key = "shield.frame.global_0122";                    label = "public_bossbar_122";          arity = 6; tags = ["sync"; "packet"]; since = "1.8.3"; weight = 2063 };
  { key = "smoker.frame.primary_0123";                   label = "provisional_gui_123";         arity = 2; tags = ["codegen"]; since = "1.9.0"; weight = 567 };
  { key = "biome.frame.local_0124";                      label = "internal_bundle_124";         arity = 3; tags = ["content"; "untyped"; "core"]; since = "1.3.1"; weight = 1437 };
  { key = "barrel.frame.global_0125";                    label = "provisional_trade_125";       arity = 5; tags = ["compat"; "hot"]; since = "1.9.0"; weight = 925 };
  { key = "rail.frame.secondary_0126";                   label = "internal_crossbow_126";       arity = 0; tags = ["sync"]; since = "1.0.0"; weight = 489 };
  { key = "trade.frame.strict_0127";                     label = "modern_attribute_127";        arity = 5; tags = ["runtime"]; since = "1.9.0"; weight = 303 };
  { key = "slot.frame.secondary_0128";                   label = "scoped_advancement_128";      arity = 2; tags = ["experimental"]; since = "1.7.0"; weight = 3789 };
  { key = "slot.frame.scoped_0129";                      label = "internal_barrel_129";         arity = 1; tags = ["codegen"]; since = "1.0.0"; weight = 3488 };
  { key = "objective.frame.lazy_0130";                   label = "lazy_compass_130";            arity = 0; tags = ["lower"; "runtime"; "compat"]; since = "1.9.0"; weight = 3987 };
  { key = "piston.frame.strict_0131";                    label = "canonical_advancement_131";   arity = 5; tags = ["packet"; "legacy"]; since = "1.5.2"; weight = 2728 };
  { key = "conduit.frame.secondary_0132";                label = "canonical_dropper_132";       arity = 4; tags = ["runtime"; "content"; "registry"]; since = "1.4.0"; weight = 2070 };
  { key = "shield.frame.loose_0133";                     label = "public_conduit_133";          arity = 1; tags = ["legacy"; "cold"; "experimental"]; since = "1.4.0"; weight = 3538 };
  { key = "grindstone.frame.lazy_0134";                  label = "eager_advancement_134";       arity = 5; tags = ["core"]; since = "1.2.0"; weight = 2255 };
  { key = "recipe.frame.scoped_0135";                    label = "lazy_particle_135";           arity = 6; tags = ["core"; "parse"; "content"]; since = "1.6.0"; weight = 671 };
  { key = "repeater.frame.internal_0136";                label = "secondary_objective_136";     arity = 7; tags = ["check"; "parse"]; since = "1.3.1"; weight = 2087 };
  { key = "shield.frame.global_0137";                    label = "fallback_grindstone_137";     arity = 4; tags = ["sync"]; since = "1.0.0"; weight = 3611 };
  { key = "chunk.frame.derived_0138";                    label = "stable_objective_138";        arity = 1; tags = ["check"; "parse"]; since = "1.6.0"; weight = 2607 };
  { key = "player.frame.modern_0139";                    label = "eager_recipe_139";            arity = 6; tags = ["registry"; "cold"; "runtime"]; since = "1.4.0"; weight = 177 };
  { key = "bundle.frame.cached_0140";                    label = "loose_attribute_140";         arity = 7; tags = ["legacy"; "lower"]; since = "1.4.0"; weight = 3883 };
  { key = "gui.frame.public_0141";                       label = "secondary_sound_141";         arity = 5; tags = ["content"]; since = "1.5.2"; weight = 343 };
  { key = "map.frame.fallback_0142";                     label = "provisional_brewing_142";     arity = 0; tags = ["async"; "codegen"]; since = "1.3.1"; weight = 2269 };
  { key = "mob.frame.internal_0143";                     label = "scoped_dropper_143";          arity = 7; tags = ["runtime"; "cold"]; since = "1.3.1"; weight = 1707 };
  { key = "attribute.frame.scoped_0144";                 label = "hidden_grindstone_144";       arity = 0; tags = ["hot"; "parse"; "registry"]; since = "1.5.2"; weight = 3954 };
  { key = "world.frame.cached_0145";                     label = "modern_inventory_145";        arity = 1; tags = ["emit"; "packet"]; since = "1.7.0"; weight = 1353 };
  { key = "hopper.frame.lazy_0146";                      label = "global_structure_146";        arity = 1; tags = ["legacy"; "untyped"]; since = "1.8.3"; weight = 3566 };
  { key = "team.frame.primary_0147";                     label = "scoped_gui_147";              arity = 4; tags = ["core"; "lower"; "hot"]; since = "1.7.0"; weight = 3210 };
  { key = "shulker.frame.public_0148";                   label = "internal_map_148";            arity = 7; tags = ["packet"; "runtime"]; since = "1.7.0"; weight = 2564 };
  { key = "player.frame.public_0149";                    label = "derived_team_149";            arity = 6; tags = ["registry"; "codegen"; "check"]; since = "1.8.3"; weight = 3381 };
  { key = "advancement.frame.fallback_0150";             label = "secondary_pane_150";          arity = 6; tags = ["packet"]; since = "1.5.2"; weight = 2889 };
  { key = "compass.frame.lazy_0151";                     label = "strict_chunk_151";            arity = 2; tags = ["codegen"; "parse"]; since = "1.7.0"; weight = 3219 };
  { key = "rail.frame.provisional_0152";                 label = "local_minecart_152";          arity = 7; tags = ["untyped"; "experimental"]; since = "1.4.0"; weight = 4060 };
  { key = "bundle.frame.canonical_0153";                 label = "hidden_rail_153";             arity = 3; tags = ["sync"]; since = "1.8.3"; weight = 799 };
  { key = "npc.frame.stable_0154";                       label = "stable_team_154";             arity = 6; tags = ["emit"; "cached"]; since = "1.0.0"; weight = 2313 };
  { key = "effect.frame.loose_0155";                     label = "local_inventory_155";         arity = 3; tags = ["typed"; "check"; "hot"]; since = "1.7.0"; weight = 3806 };
  { key = "portal.frame.modern_0156";                    label = "fallback_player_156";         arity = 1; tags = ["experimental"; "async"; "typed"]; since = "1.0.0"; weight = 1437 };
  { key = "biome.frame.local_0157";                      label = "legacy_region_157";           arity = 6; tags = ["runtime"; "core"; "experimental"]; since = "1.9.0"; weight = 4027 };
  { key = "enchant.frame.public_0158";                   label = "fallback_potion_158";         arity = 5; tags = ["parse"]; since = "1.4.0"; weight = 2658 };
  { key = "campfire.frame.cached_0159";                  label = "primary_trident_159";         arity = 0; tags = ["emit"; "runtime"; "untyped"]; since = "1.7.0"; weight = 2679 };
  { key = "shulker.frame.scoped_0160";                   label = "loose_region_160";            arity = 0; tags = ["async"; "compat"; "typed"]; since = "1.4.0"; weight = 800 };
  { key = "dispenser.frame.legacy_0161";                 label = "provisional_lectern_161";     arity = 5; tags = ["core"]; since = "1.9.0"; weight = 779 };
  { key = "potion.frame.primary_0162";                   label = "cached_attribute_162";        arity = 7; tags = ["async"; "core"]; since = "1.2.0"; weight = 2377 };
  { key = "structure.frame.scoped_0163";                 label = "local_sound_163";             arity = 6; tags = ["runtime"]; since = "1.9.0"; weight = 3319 };
  { key = "block.frame.hidden_0164";                     label = "lazy_pane_164";               arity = 3; tags = ["legacy"]; since = "1.7.0"; weight = 382 };
  { key = "hologram.frame.eager_0165";                   label = "provisional_region_165";      arity = 4; tags = ["check"; "experimental"]; since = "1.7.0"; weight = 3232 };
  { key = "advancement.frame.legacy_0166";               label = "internal_pane_166";           arity = 6; tags = ["core"]; since = "1.0.0"; weight = 526 };
  { key = "particle.frame.strict_0167";                  label = "legacy_packet_167";           arity = 5; tags = ["lower"; "async"]; since = "1.3.1"; weight = 3819 };
  { key = "tablist.frame.hidden_0168";                   label = "legacy_rail_168";             arity = 4; tags = ["untyped"; "emit"]; since = "1.9.0"; weight = 1685 };
  { key = "firework.frame.legacy_0169";                  label = "loose_tablist_169";           arity = 7; tags = ["compat"; "codegen"; "typed"]; since = "1.3.1"; weight = 476 };
  { key = "arrow.frame.cached_0170";                     label = "lazy_conduit_170";            arity = 4; tags = ["typed"; "core"; "check"]; since = "1.2.0"; weight = 2410 };
  { key = "campfire.frame.hidden_0171";                  label = "local_furnace_171";           arity = 1; tags = ["emit"; "core"]; since = "1.7.0"; weight = 1142 };
  { key = "campfire.frame.derived_0172";                 label = "hidden_comparator_172";       arity = 4; tags = ["core"; "async"]; since = "1.3.1"; weight = 1695 };
  { key = "region.frame.global_0173";                    label = "canonical_scoreboard_173";    arity = 0; tags = ["content"]; since = "1.0.0"; weight = 2120 };
  { key = "bossbar.frame.secondary_0174";                label = "hidden_beacon_174";           arity = 5; tags = ["legacy"]; since = "1.7.0"; weight = 965 };
  { key = "structure.frame.canonical_0175";              label = "internal_comparator_175";     arity = 1; tags = ["cached"; "core"]; since = "1.6.0"; weight = 3360 };
  { key = "hopper.frame.eager_0176";                     label = "hidden_repeater_176";         arity = 3; tags = ["core"; "cached"]; since = "1.6.0"; weight = 1625 };
  { key = "observer.frame.legacy_0177";                  label = "legacy_attribute_177";        arity = 3; tags = ["compat"; "cold"; "experimental"]; since = "1.2.0"; weight = 3976 };
  { key = "packet.frame.internal_0178";                  label = "public_stonecutter_178";      arity = 1; tags = ["registry"]; since = "1.9.0"; weight = 1849 };
  { key = "elytra.frame.primary_0179";                   label = "scoped_map_179";              arity = 7; tags = ["content"; "untyped"; "async"]; since = "1.4.0"; weight = 1655 };
  { key = "firework.frame.secondary_0180";               label = "modern_effect_180";           arity = 0; tags = ["compat"; "lower"]; since = "1.7.0"; weight = 2458 };
  { key = "player.frame.fallback_0181";                  label = "canonical_npc_181";           arity = 3; tags = ["content"]; since = "1.9.0"; weight = 1348 };
  { key = "mob.frame.internal_0182";                     label = "fallback_hopper_182";         arity = 2; tags = ["runtime"]; since = "1.8.3"; weight = 2738 };
  { key = "campfire.frame.lazy_0183";                    label = "legacy_bossbar_183";          arity = 3; tags = ["typed"; "compat"]; since = "1.3.1"; weight = 3191 };
  { key = "mob.frame.scoped_0184";                       label = "loose_trade_184";             arity = 3; tags = ["packet"]; since = "1.2.0"; weight = 2317 };
  { key = "compass.frame.legacy_0185";                   label = "global_cartography_185";      arity = 4; tags = ["async"; "lower"]; since = "1.4.0"; weight = 1265 };
  { key = "sound.frame.canonical_0186";                  label = "lazy_npc_186";                arity = 6; tags = ["compat"]; since = "1.0.0"; weight = 2261 };
  { key = "team.frame.canonical_0187";                   label = "eager_crossbow_187";          arity = 5; tags = ["codegen"]; since = "1.8.3"; weight = 676 };
  { key = "recipe.frame.legacy_0188";                    label = "primary_villager_188";        arity = 7; tags = ["lower"; "untyped"]; since = "1.7.0"; weight = 3387 };
  { key = "hologram.frame.secondary_0189";               label = "derived_comparator_189";      arity = 3; tags = ["parse"]; since = "1.4.0"; weight = 3454 };
  { key = "rail.frame.legacy_0190";                      label = "lazy_loom_190";               arity = 7; tags = ["lower"; "parse"; "cold"]; since = "1.6.0"; weight = 2142 };
  { key = "smoker.frame.provisional_0191";               label = "hidden_potion_191";           arity = 6; tags = ["emit"; "core"; "codegen"]; since = "1.3.1"; weight = 2119 };
  { key = "bossbar.frame.canonical_0192";                label = "modern_item_192";             arity = 5; tags = ["registry"; "packet"; "content"]; since = "1.5.2"; weight = 3107 };
  { key = "enchant.frame.global_0193";                   label = "cached_conduit_193";          arity = 0; tags = ["experimental"; "content"; "cold"]; since = "1.3.1"; weight = 2940 };
  { key = "conduit.frame.provisional_0194";              label = "lazy_advancement_194";        arity = 6; tags = ["legacy"]; since = "1.0.0"; weight = 3777 };
  { key = "cartography.frame.stable_0195";               label = "derived_rail_195";            arity = 7; tags = ["check"; "core"]; since = "1.9.0"; weight = 3094 };
  { key = "banner_pattern.frame.canonical_0196";         label = "strict_crossbow_196";         arity = 7; tags = ["core"; "check"; "sync"]; since = "1.9.0"; weight = 3408 };
  { key = "repeater.frame.fallback_0197";                label = "fallback_spawner_197";        arity = 7; tags = ["registry"]; since = "1.3.1"; weight = 944 };
  { key = "cartography.frame.secondary_0198";            label = "stable_packet_198";           arity = 1; tags = ["cold"; "hot"; "compat"]; since = "1.6.0"; weight = 190 };
  { key = "bossbar.frame.loose_0199";                    label = "scoped_clock_199";            arity = 6; tags = ["core"; "experimental"; "sync"]; since = "1.3.1"; weight = 2472 };
  { key = "anvil.frame.global_0200";                     label = "global_biome_200";            arity = 7; tags = ["content"; "runtime"]; since = "1.6.0"; weight = 3748 };
  { key = "world.frame.hidden_0201";                     label = "internal_bundle_201";         arity = 6; tags = ["core"]; since = "1.9.0"; weight = 960 };
  { key = "compass.frame.legacy_0202";                   label = "hidden_hologram_202";         arity = 0; tags = ["codegen"; "cold"; "cached"]; since = "1.4.0"; weight = 615 };
  { key = "target.frame.strict_0203";                    label = "lazy_composter_203";          arity = 6; tags = ["experimental"; "cached"; "legacy"]; since = "1.8.3"; weight = 1239 };
  { key = "spawner.frame.local_0204";                    label = "lazy_bundle_204";             arity = 4; tags = ["cold"; "registry"]; since = "1.3.1"; weight = 1794 };
  { key = "mob.frame.eager_0205";                        label = "secondary_brewing_205";       arity = 2; tags = ["content"; "runtime"; "legacy"]; since = "1.4.0"; weight = 3449 };
  { key = "scoreboard.frame.derived_0206";               label = "fallback_particle_206";       arity = 5; tags = ["sync"; "hot"; "lower"]; since = "1.8.3"; weight = 1620 };
  { key = "trident.frame.legacy_0207";                   label = "public_bell_207";             arity = 1; tags = ["experimental"; "compat"]; since = "1.9.0"; weight = 2616 };
  { key = "loom.frame.loose_0208";                       label = "hidden_minecart_208";         arity = 1; tags = ["lower"]; since = "1.6.0"; weight = 44 };
  { key = "team.frame.fallback_0209";                    label = "lazy_grindstone_209";         arity = 5; tags = ["async"]; since = "1.5.2"; weight = 2818 };
  { key = "barrel.frame.secondary_0210";                 label = "provisional_enchant_210";     arity = 2; tags = ["packet"; "codegen"; "typed"]; since = "1.3.1"; weight = 2588 };
  { key = "bossbar.frame.internal_0211";                 label = "fallback_tablist_211";        arity = 0; tags = ["emit"; "legacy"; "async"]; since = "1.3.1"; weight = 942 };
  { key = "npc.frame.primary_0212";                      label = "provisional_target_212";      arity = 4; tags = ["hot"; "experimental"; "async"]; since = "1.5.2"; weight = 2473 };
  { key = "rail.frame.primary_0213";                     label = "local_block_213";             arity = 0; tags = ["codegen"; "typed"; "experimental"]; since = "1.9.0"; weight = 1509 };
  { key = "barrel.frame.secondary_0214";                 label = "scoped_map_214";              arity = 1; tags = ["cold"]; since = "1.8.3"; weight = 2333 };
  { key = "barrel.frame.fallback_0215";                  label = "local_villager_215";          arity = 0; tags = ["hot"; "emit"]; since = "1.3.1"; weight = 1684 };
  { key = "beacon.frame.hidden_0216";                    label = "public_grindstone_216";       arity = 1; tags = ["parse"; "sync"; "runtime"]; since = "1.8.3"; weight = 2196 };
  { key = "block.frame.modern_0217";                     label = "internal_observer_217";       arity = 5; tags = ["hot"; "packet"; "typed"]; since = "1.2.0"; weight = 1305 };
  { key = "lectern.frame.cached_0218";                   label = "hidden_mob_218";              arity = 3; tags = ["content"; "typed"; "sync"]; since = "1.5.2"; weight = 1932 };
  { key = "barrel.frame.cached_0219";                    label = "legacy_rail_219";             arity = 3; tags = ["codegen"; "registry"]; since = "1.2.0"; weight = 1172 };
  { key = "comparator.frame.scoped_0220";                label = "scoped_effect_220";           arity = 1; tags = ["compat"; "sync"; "async"]; since = "1.4.0"; weight = 2285 };
  { key = "biome.frame.primary_0221";                    label = "hidden_crossbow_221";         arity = 4; tags = ["typed"]; since = "1.7.0"; weight = 2770 };
  { key = "repeater.frame.stable_0222";                  label = "stable_dropper_222";          arity = 3; tags = ["lower"]; since = "1.5.2"; weight = 1134 };
  { key = "barrel.frame.canonical_0223";                 label = "loose_dropper_223";           arity = 0; tags = ["legacy"; "check"; "experimental"]; since = "1.7.0"; weight = 1808 };
  { key = "portal.frame.public_0224";                    label = "derived_target_224";          arity = 3; tags = ["cached"; "sync"]; since = "1.5.2"; weight = 1669 };
  { key = "piston.frame.modern_0225";                    label = "public_boat_225";             arity = 3; tags = ["codegen"; "runtime"; "legacy"]; since = "1.2.0"; weight = 788 };
  { key = "bundle.frame.provisional_0226";               label = "global_furnace_226";          arity = 5; tags = ["legacy"]; since = "1.9.0"; weight = 1308 };
  { key = "grindstone.frame.hidden_0227";                label = "fallback_item_227";           arity = 1; tags = ["core"]; since = "1.4.0"; weight = 3967 };
  { key = "advancement.frame.internal_0228";             label = "loose_advancement_228";       arity = 2; tags = ["emit"]; since = "1.7.0"; weight = 2550 };
  { key = "portal.frame.global_0229";                    label = "scoped_elytra_229";           arity = 2; tags = ["experimental"]; since = "1.9.0"; weight = 3990 };
  { key = "boat.frame.primary_0230";                     label = "public_stonecutter_230";      arity = 3; tags = ["cached"]; since = "1.2.0"; weight = 1771 };
  { key = "particle.frame.internal_0231";                label = "provisional_region_231";      arity = 2; tags = ["typed"; "registry"; "codegen"]; since = "1.5.2"; weight = 611 };
  { key = "chunk.frame.secondary_0232";                  label = "fallback_target_232";         arity = 5; tags = ["async"; "content"]; since = "1.2.0"; weight = 341 };
  { key = "tablist.frame.eager_0233";                    label = "scoped_observer_233";         arity = 2; tags = ["untyped"; "core"]; since = "1.8.3"; weight = 794 };
  { key = "dispenser.frame.secondary_0234";              label = "global_block_234";            arity = 3; tags = ["emit"; "sync"; "parse"]; since = "1.9.0"; weight = 952 };
  { key = "stonecutter.frame.stable_0235";               label = "cached_comparator_235";       arity = 6; tags = ["experimental"]; since = "1.0.0"; weight = 262 };
  { key = "particle.frame.scoped_0236";                  label = "strict_inventory_236";        arity = 5; tags = ["check"; "cached"]; since = "1.2.0"; weight = 1941 };
  { key = "lectern.frame.secondary_0237";                label = "derived_effect_237";          arity = 5; tags = ["typed"; "core"]; since = "1.0.0"; weight = 2330 };
  { key = "stonecutter.frame.local_0238";                label = "modern_world_238";            arity = 7; tags = ["core"]; since = "1.2.0"; weight = 1703 };
  { key = "trade.frame.global_0239";                     label = "secondary_sound_239";         arity = 3; tags = ["sync"]; since = "1.7.0"; weight = 3754 };
  { key = "conduit.frame.internal_0240";                 label = "secondary_smoker_240";        arity = 7; tags = ["typed"; "cached"; "sync"]; since = "1.9.0"; weight = 1241 };
  { key = "repeater.frame.local_0241";                   label = "scoped_hopper_241";           arity = 7; tags = ["codegen"; "typed"; "parse"]; since = "1.5.2"; weight = 628 };
  { key = "map.frame.secondary_0242";                    label = "cached_effect_242";           arity = 1; tags = ["async"; "content"; "core"]; since = "1.9.0"; weight = 793 };
  { key = "mob.frame.fallback_0243";                     label = "public_cartography_243";      arity = 0; tags = ["cold"]; since = "1.0.0"; weight = 1187 };
  { key = "world.frame.fallback_0244";                   label = "lazy_crossbow_244";           arity = 1; tags = ["content"; "lower"; "untyped"]; since = "1.6.0"; weight = 3536 };
  { key = "tablist.frame.cached_0245";                   label = "global_rail_245";             arity = 4; tags = ["packet"]; since = "1.6.0"; weight = 2284 };
  { key = "attribute.frame.internal_0246";               label = "modern_portal_246";           arity = 6; tags = ["parse"; "core"]; since = "1.7.0"; weight = 1966 };
  { key = "shulker.frame.cached_0247";                   label = "secondary_npc_247";           arity = 6; tags = ["runtime"]; since = "1.3.1"; weight = 2898 };
  { key = "advancement.frame.fallback_0248";             label = "cached_brewing_248";          arity = 3; tags = ["codegen"; "lower"; "core"]; since = "1.4.0"; weight = 1328 };
  { key = "bundle.frame.eager_0249";                     label = "secondary_dispenser_249";     arity = 0; tags = ["typed"]; since = "1.5.2"; weight = 2104 };
  { key = "mob.frame.derived_0250";                      label = "provisional_conduit_250";     arity = 7; tags = ["lower"; "cached"; "experimental"]; since = "1.6.0"; weight = 1863 };
  { key = "scoreboard.frame.eager_0251";                 label = "public_bossbar_251";          arity = 5; tags = ["packet"]; since = "1.7.0"; weight = 3504 };
  { key = "tablist.frame.lazy_0252";                     label = "cached_dispenser_252";        arity = 3; tags = ["registry"; "async"]; since = "1.7.0"; weight = 1258 };
  { key = "bundle.frame.loose_0253";                     label = "internal_portal_253";         arity = 4; tags = ["async"; "compat"; "packet"]; since = "1.2.0"; weight = 1062 };
  { key = "sound.frame.legacy_0254";                     label = "strict_pane_254";             arity = 4; tags = ["content"; "cold"; "legacy"]; since = "1.6.0"; weight = 3630 };
  { key = "piston.frame.loose_0255";                     label = "fallback_trade_255";          arity = 2; tags = ["sync"]; since = "1.5.2"; weight = 3558 };
  { key = "trident.frame.legacy_0256";                   label = "internal_barrel_256";         arity = 2; tags = ["cached"]; since = "1.6.0"; weight = 1965 };
  { key = "block.frame.cached_0257";                     label = "provisional_elytra_257";      arity = 7; tags = ["core"]; since = "1.4.0"; weight = 2379 };
  { key = "structure.frame.modern_0258";                 label = "stable_sound_258";            arity = 6; tags = ["parse"]; since = "1.4.0"; weight = 741 };
  { key = "recipe.frame.internal_0259";                  label = "hidden_furnace_259";          arity = 4; tags = ["legacy"]; since = "1.3.1"; weight = 2714 };
  { key = "inventory.frame.modern_0260";                 label = "hidden_map_260";              arity = 2; tags = ["sync"; "packet"]; since = "1.7.0"; weight = 1161 };
  { key = "region.frame.hidden_0261";                    label = "public_clock_261";            arity = 3; tags = ["parse"]; since = "1.3.1"; weight = 2366 };
  { key = "brewing.frame.lazy_0262";                     label = "internal_npc_262";            arity = 1; tags = ["compat"]; since = "1.0.0"; weight = 2802 };
  { key = "team.frame.strict_0263";                      label = "public_structure_263";        arity = 4; tags = ["content"]; since = "1.3.1"; weight = 876 };
  { key = "region.frame.hidden_0264";                    label = "strict_observer_264";         arity = 0; tags = ["legacy"; "hot"]; since = "1.4.0"; weight = 237 };
]

let count = List.length entries

let table : (string, frame_entry) Hashtbl.t =
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
