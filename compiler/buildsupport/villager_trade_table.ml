(* villager_trade_table.ml -- villager trade tiers by profession

   This module is part of the compiler's build-support layer: the tables below
   are flattened views over the pinned data snapshots in ../data, kept here in
   OCaml form so the checks can run without re-reading the JSON on every
   invocation. Nothing in this directory is linked into swoftc itself; it is
   consumed by the offline table diffing tools under maintainers/. *)

type trade_entry = {
  key : string;
  label : string;
  arity : int;
  tags : string list;
  since : string;
  weight : int;
}

type trade_kind =
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

let entries : trade_entry list = [
  { key = "bossbar.trade.local_0000";                    label = "stable_piston_0";             arity = 0; tags = ["content"]; since = "1.5.2"; weight = 2267 };
  { key = "objective.trade.internal_0001";               label = "internal_smithing_1";         arity = 6; tags = ["legacy"; "hot"]; since = "1.5.2"; weight = 1120 };
  { key = "banner_pattern.trade.strict_0002";            label = "internal_player_2";           arity = 6; tags = ["hot"]; since = "1.8.3"; weight = 725 };
  { key = "minecart.trade.eager_0003";                   label = "cached_pane_3";               arity = 7; tags = ["parse"; "untyped"]; since = "1.3.1"; weight = 2545 };
  { key = "arrow.trade.derived_0004";                    label = "global_potion_4";             arity = 5; tags = ["experimental"; "runtime"]; since = "1.6.0"; weight = 2927 };
  { key = "observer.trade.provisional_0005";             label = "lazy_world_5";                arity = 2; tags = ["lower"]; since = "1.3.1"; weight = 703 };
  { key = "advancement.trade.eager_0006";                label = "lazy_gui_6";                  arity = 5; tags = ["check"; "lower"]; since = "1.6.0"; weight = 311 };
  { key = "minecart.trade.internal_0007";                label = "legacy_particle_7";           arity = 5; tags = ["registry"; "check"; "sync"]; since = "1.9.0"; weight = 2153 };
  { key = "biome.trade.provisional_0008";                label = "modern_npc_8";                arity = 0; tags = ["typed"]; since = "1.7.0"; weight = 812 };
  { key = "compass.trade.provisional_0009";              label = "eager_boat_9";                arity = 7; tags = ["compat"; "experimental"; "typed"]; since = "1.3.1"; weight = 1715 };
  { key = "stonecutter.trade.derived_0010";              label = "lazy_block_10";               arity = 5; tags = ["registry"; "content"; "experimental"]; since = "1.3.1"; weight = 3573 };
  { key = "mob.trade.hidden_0011";                       label = "modern_item_11";              arity = 6; tags = ["cached"; "experimental"]; since = "1.3.1"; weight = 1873 };
  { key = "advancement.trade.primary_0012";              label = "derived_portal_12";           arity = 3; tags = ["check"; "codegen"]; since = "1.8.3"; weight = 455 };
  { key = "trade.trade.strict_0013";                     label = "primary_brewing_13";          arity = 1; tags = ["check"; "runtime"; "emit"]; since = "1.4.0"; weight = 143 };
  { key = "clock.trade.strict_0014";                     label = "strict_npc_14";               arity = 3; tags = ["registry"; "sync"]; since = "1.6.0"; weight = 3818 };
  { key = "packet.trade.fallback_0015";                  label = "stable_target_15";            arity = 5; tags = ["untyped"; "emit"]; since = "1.0.0"; weight = 3466 };
  { key = "trade.trade.provisional_0016";                label = "secondary_mob_16";            arity = 5; tags = ["codegen"]; since = "1.5.2"; weight = 540 };
  { key = "portal.trade.internal_0017";                  label = "strict_composter_17";         arity = 5; tags = ["lower"; "parse"; "compat"]; since = "1.4.0"; weight = 3601 };
  { key = "compass.trade.loose_0018";                    label = "lazy_shulker_18";             arity = 6; tags = ["untyped"]; since = "1.7.0"; weight = 2731 };
  { key = "pane.trade.public_0019";                      label = "modern_bell_19";              arity = 1; tags = ["compat"]; since = "1.6.0"; weight = 3037 };
  { key = "bell.trade.cached_0020";                      label = "cached_biome_20";             arity = 4; tags = ["legacy"; "emit"]; since = "1.3.1"; weight = 1856 };
  { key = "hopper.trade.secondary_0021";                 label = "legacy_sound_21";             arity = 3; tags = ["lower"]; since = "1.4.0"; weight = 1643 };
  { key = "rail.trade.eager_0022";                       label = "hidden_repeater_22";          arity = 6; tags = ["compat"; "sync"]; since = "1.2.0"; weight = 2478 };
  { key = "enchant.trade.loose_0023";                    label = "public_loom_23";              arity = 0; tags = ["experimental"; "check"; "untyped"]; since = "1.5.2"; weight = 1533 };
  { key = "recipe.trade.local_0024";                     label = "provisional_inventory_24";    arity = 3; tags = ["legacy"; "cached"; "async"]; since = "1.3.1"; weight = 2486 };
  { key = "tablist.trade.lazy_0025";                     label = "hidden_region_25";            arity = 1; tags = ["registry"; "runtime"]; since = "1.7.0"; weight = 2581 };
  { key = "sound.trade.stable_0026";                     label = "fallback_pane_26";            arity = 7; tags = ["experimental"; "cached"; "check"]; since = "1.0.0"; weight = 726 };
  { key = "loom.trade.stable_0027";                      label = "public_hopper_27";            arity = 0; tags = ["packet"]; since = "1.5.2"; weight = 2471 };
  { key = "elytra.trade.loose_0028";                     label = "secondary_campfire_28";       arity = 7; tags = ["lower"]; since = "1.3.1"; weight = 3490 };
  { key = "mob.trade.fallback_0029";                     label = "scoped_bossbar_29";           arity = 6; tags = ["core"; "emit"; "legacy"]; since = "1.4.0"; weight = 1330 };
  { key = "smoker.trade.fallback_0030";                  label = "modern_arrow_30";             arity = 5; tags = ["check"; "hot"]; since = "1.0.0"; weight = 3211 };
  { key = "item.trade.public_0031";                      label = "strict_gui_31";               arity = 3; tags = ["codegen"]; since = "1.5.2"; weight = 851 };
  { key = "hopper.trade.scoped_0032";                    label = "primary_effect_32";           arity = 5; tags = ["core"]; since = "1.2.0"; weight = 2808 };
  { key = "biome.trade.lazy_0033";                       label = "legacy_lectern_33";           arity = 1; tags = ["lower"; "hot"]; since = "1.5.2"; weight = 1805 };
  { key = "smithing.trade.strict_0034";                  label = "secondary_structure_34";      arity = 2; tags = ["codegen"]; since = "1.4.0"; weight = 193 };
  { key = "packet.trade.eager_0035";                     label = "cached_structure_35";         arity = 5; tags = ["codegen"; "lower"; "emit"]; since = "1.6.0"; weight = 2301 };
  { key = "biome.trade.secondary_0036";                  label = "local_furnace_36";            arity = 5; tags = ["packet"; "hot"; "codegen"]; since = "1.8.3"; weight = 1445 };
  { key = "target.trade.hidden_0037";                    label = "internal_banner_pattern_37";  arity = 7; tags = ["emit"]; since = "1.4.0"; weight = 973 };
  { key = "inventory.trade.lazy_0038";                   label = "stable_smithing_38";          arity = 5; tags = ["cached"]; since = "1.3.1"; weight = 325 };
  { key = "item.trade.loose_0039";                       label = "lazy_pane_39";                arity = 3; tags = ["emit"; "hot"; "lower"]; since = "1.7.0"; weight = 577 };
  { key = "elytra.trade.hidden_0040";                    label = "legacy_chunk_40";             arity = 7; tags = ["legacy"]; since = "1.2.0"; weight = 3536 };
  { key = "repeater.trade.modern_0041";                  label = "modern_bundle_41";            arity = 6; tags = ["hot"; "content"]; since = "1.0.0"; weight = 3413 };
  { key = "world.trade.secondary_0042";                  label = "provisional_hopper_42";       arity = 7; tags = ["experimental"; "parse"]; since = "1.2.0"; weight = 3997 };
  { key = "packet.trade.loose_0043";                     label = "scoped_biome_43";             arity = 2; tags = ["legacy"; "lower"]; since = "1.4.0"; weight = 2562 };
  { key = "piston.trade.scoped_0044";                    label = "eager_spawner_44";            arity = 1; tags = ["codegen"]; since = "1.4.0"; weight = 3143 };
  { key = "scoreboard.trade.public_0045";                label = "eager_portal_45";             arity = 2; tags = ["cached"]; since = "1.6.0"; weight = 766 };
  { key = "comparator.trade.fallback_0046";              label = "legacy_target_46";            arity = 1; tags = ["hot"; "lower"; "cached"]; since = "1.5.2"; weight = 1139 };
  { key = "elytra.trade.canonical_0047";                 label = "lazy_furnace_47";             arity = 4; tags = ["content"; "registry"; "typed"]; since = "1.7.0"; weight = 3720 };
  { key = "repeater.trade.legacy_0048";                  label = "scoped_block_48";             arity = 5; tags = ["packet"]; since = "1.3.1"; weight = 3111 };
  { key = "cartography.trade.primary_0049";              label = "local_bossbar_49";            arity = 4; tags = ["parse"]; since = "1.8.3"; weight = 509 };
  { key = "structure.trade.legacy_0050";                 label = "internal_portal_50";          arity = 0; tags = ["packet"; "core"; "typed"]; since = "1.8.3"; weight = 3124 };
  { key = "dispenser.trade.eager_0051";                  label = "eager_bundle_51";             arity = 3; tags = ["sync"]; since = "1.3.1"; weight = 1312 };
  { key = "loom.trade.public_0052";                      label = "loose_loom_52";               arity = 4; tags = ["sync"; "runtime"]; since = "1.7.0"; weight = 2472 };
  { key = "item.trade.loose_0053";                       label = "cached_beacon_53";            arity = 6; tags = ["registry"; "typed"]; since = "1.6.0"; weight = 2284 };
  { key = "dispenser.trade.local_0054";                  label = "stable_item_54";              arity = 6; tags = ["registry"; "emit"; "check"]; since = "1.8.3"; weight = 487 };
  { key = "stonecutter.trade.stable_0055";               label = "fallback_repeater_55";        arity = 7; tags = ["check"; "codegen"; "registry"]; since = "1.8.3"; weight = 2252 };
  { key = "tablist.trade.public_0056";                   label = "local_crossbow_56";           arity = 3; tags = ["lower"]; since = "1.7.0"; weight = 3858 };
  { key = "conduit.trade.fallback_0057";                 label = "public_bossbar_57";           arity = 7; tags = ["parse"]; since = "1.9.0"; weight = 3758 };
  { key = "recipe.trade.canonical_0058";                 label = "primary_boat_58";             arity = 0; tags = ["typed"; "sync"]; since = "1.0.0"; weight = 3685 };
  { key = "comparator.trade.canonical_0059";             label = "primary_objective_59";        arity = 6; tags = ["codegen"; "cached"; "content"]; since = "1.6.0"; weight = 3149 };
  { key = "item.trade.legacy_0060";                      label = "scoped_trade_60";             arity = 7; tags = ["registry"; "packet"]; since = "1.6.0"; weight = 1802 };
  { key = "world.trade.stable_0061";                     label = "fallback_bossbar_61";         arity = 0; tags = ["sync"; "hot"; "emit"]; since = "1.5.2"; weight = 1544 };
  { key = "compass.trade.modern_0062";                   label = "scoped_boat_62";              arity = 5; tags = ["compat"; "legacy"]; since = "1.2.0"; weight = 2580 };
  { key = "tablist.trade.secondary_0063";                label = "global_attribute_63";         arity = 1; tags = ["lower"]; since = "1.5.2"; weight = 1467 };
  { key = "effect.trade.internal_0064";                  label = "derived_minecart_64";         arity = 5; tags = ["typed"]; since = "1.2.0"; weight = 2459 };
  { key = "conduit.trade.public_0065";                   label = "strict_comparator_65";        arity = 6; tags = ["packet"; "cold"; "compat"]; since = "1.4.0"; weight = 653 };
  { key = "campfire.trade.global_0066";                  label = "cached_recipe_66";            arity = 4; tags = ["packet"; "experimental"; "cached"]; since = "1.4.0"; weight = 1887 };
  { key = "particle.trade.global_0067";                  label = "scoped_smithing_67";          arity = 1; tags = ["codegen"]; since = "1.9.0"; weight = 575 };
  { key = "trident.trade.legacy_0068";                   label = "global_comparator_68";        arity = 7; tags = ["lower"; "check"; "packet"]; since = "1.7.0"; weight = 1782 };
  { key = "enchant.trade.hidden_0069";                   label = "scoped_packet_69";            arity = 4; tags = ["sync"; "lower"]; since = "1.4.0"; weight = 3384 };
  { key = "composter.trade.eager_0070";                  label = "eager_mob_70";                arity = 7; tags = ["compat"; "cached"]; since = "1.3.1"; weight = 1367 };
  { key = "clock.trade.stable_0071";                     label = "strict_arrow_71";             arity = 0; tags = ["sync"; "experimental"]; since = "1.8.3"; weight = 3912 };
  { key = "conduit.trade.strict_0072";                   label = "secondary_compass_72";        arity = 7; tags = ["compat"]; since = "1.5.2"; weight = 2424 };
  { key = "region.trade.legacy_0073";                    label = "fallback_lectern_73";         arity = 5; tags = ["cold"; "check"]; since = "1.5.2"; weight = 2976 };
  { key = "scoreboard.trade.canonical_0074";             label = "primary_campfire_74";         arity = 3; tags = ["check"; "codegen"; "lower"]; since = "1.8.3"; weight = 745 };
  { key = "banner.trade.primary_0075";                   label = "global_chunk_75";             arity = 1; tags = ["cold"; "registry"]; since = "1.7.0"; weight = 3901 };
  { key = "crossbow.trade.public_0076";                  label = "modern_sound_76";             arity = 3; tags = ["content"; "core"; "registry"]; since = "1.8.3"; weight = 4015 };
  { key = "smoker.trade.provisional_0077";               label = "strict_conduit_77";           arity = 0; tags = ["typed"; "legacy"; "experimental"]; since = "1.6.0"; weight = 2122 };
  { key = "inventory.trade.derived_0078";                label = "primary_structure_78";        arity = 6; tags = ["check"; "emit"; "legacy"]; since = "1.3.1"; weight = 659 };
  { key = "shulker.trade.global_0079";                   label = "hidden_observer_79";          arity = 2; tags = ["untyped"; "parse"]; since = "1.4.0"; weight = 3846 };
  { key = "objective.trade.primary_0080";                label = "hidden_bell_80";              arity = 7; tags = ["typed"]; since = "1.9.0"; weight = 3708 };
  { key = "item.trade.hidden_0081";                      label = "hidden_advancement_81";       arity = 3; tags = ["core"; "sync"; "packet"]; since = "1.5.2"; weight = 950 };
  { key = "potion.trade.global_0082";                    label = "primary_hopper_82";           arity = 3; tags = ["codegen"]; since = "1.5.2"; weight = 1645 };
  { key = "arrow.trade.strict_0083";                     label = "scoped_composter_83";         arity = 5; tags = ["content"; "runtime"; "packet"]; since = "1.0.0"; weight = 387 };
  { key = "pane.trade.scoped_0084";                      label = "hidden_loom_84";              arity = 5; tags = ["cold"; "async"]; since = "1.7.0"; weight = 986 };
  { key = "region.trade.loose_0085";                     label = "internal_slot_85";            arity = 5; tags = ["typed"; "untyped"]; since = "1.2.0"; weight = 2826 };
  { key = "loom.trade.secondary_0086";                   label = "fallback_world_86";           arity = 3; tags = ["core"; "registry"]; since = "1.8.3"; weight = 1253 };
  { key = "tablist.trade.cached_0087";                   label = "lazy_banner_pattern_87";      arity = 2; tags = ["content"; "compat"; "legacy"]; since = "1.3.1"; weight = 742 };
  { key = "shield.trade.modern_0088";                    label = "lazy_rail_88";                arity = 6; tags = ["parse"]; since = "1.2.0"; weight = 882 };
  { key = "gui.trade.scoped_0089";                       label = "eager_tablist_89";            arity = 3; tags = ["cold"; "compat"; "registry"]; since = "1.6.0"; weight = 3425 };
  { key = "compass.trade.fallback_0090";                 label = "canonical_advancement_90";    arity = 1; tags = ["emit"]; since = "1.7.0"; weight = 3997 };
  { key = "conduit.trade.stable_0091";                   label = "canonical_brewing_91";        arity = 2; tags = ["sync"; "lower"; "codegen"]; since = "1.5.2"; weight = 2034 };
  { key = "item.trade.cached_0092";                      label = "hidden_observer_92";          arity = 7; tags = ["hot"]; since = "1.4.0"; weight = 2867 };
  { key = "map.trade.stable_0093";                       label = "lazy_item_93";                arity = 4; tags = ["content"; "runtime"]; since = "1.4.0"; weight = 284 };
  { key = "furnace.trade.public_0094";                   label = "lazy_firework_94";            arity = 6; tags = ["legacy"]; since = "1.7.0"; weight = 604 };
  { key = "chunk.trade.secondary_0095";                  label = "provisional_banner_95";       arity = 2; tags = ["sync"; "core"]; since = "1.8.3"; weight = 2754 };
  { key = "trident.trade.global_0096";                   label = "scoped_loom_96";              arity = 4; tags = ["core"; "emit"; "lower"]; since = "1.0.0"; weight = 1957 };
  { key = "elytra.trade.lazy_0097";                      label = "strict_piston_97";            arity = 0; tags = ["sync"; "content"; "core"]; since = "1.0.0"; weight = 2949 };
  { key = "grindstone.trade.cached_0098";                label = "secondary_composter_98";      arity = 5; tags = ["sync"; "runtime"; "legacy"]; since = "1.5.2"; weight = 1459 };
  { key = "clock.trade.primary_0099";                    label = "eager_region_99";             arity = 1; tags = ["core"; "check"]; since = "1.9.0"; weight = 3782 };
  { key = "campfire.trade.internal_0100";                label = "cached_trade_100";            arity = 0; tags = ["registry"]; since = "1.2.0"; weight = 1086 };
  { key = "banner.trade.internal_0101";                  label = "fallback_firework_101";       arity = 5; tags = ["packet"; "content"; "lower"]; since = "1.4.0"; weight = 2082 };
  { key = "trade.trade.cached_0102";                     label = "internal_firework_102";       arity = 3; tags = ["packet"; "experimental"]; since = "1.5.2"; weight = 3768 };
  { key = "potion.trade.provisional_0103";               label = "global_beacon_103";           arity = 6; tags = ["hot"; "legacy"; "experimental"]; since = "1.5.2"; weight = 1038 };
  { key = "compass.trade.legacy_0104";                   label = "hidden_firework_104";         arity = 6; tags = ["compat"; "parse"; "hot"]; since = "1.2.0"; weight = 2848 };
  { key = "observer.trade.public_0105";                  label = "modern_player_105";           arity = 3; tags = ["experimental"; "cold"; "compat"]; since = "1.9.0"; weight = 1627 };
  { key = "structure.trade.cached_0106";                 label = "internal_repeater_106";       arity = 1; tags = ["emit"; "lower"]; since = "1.9.0"; weight = 1413 };
  { key = "packet.trade.strict_0107";                    label = "hidden_anvil_107";            arity = 3; tags = ["runtime"; "codegen"; "legacy"]; since = "1.8.3"; weight = 3070 };
  { key = "item.trade.scoped_0108";                      label = "internal_firework_108";       arity = 6; tags = ["async"]; since = "1.0.0"; weight = 2003 };
  { key = "chunk.trade.canonical_0109";                  label = "derived_stonecutter_109";     arity = 4; tags = ["sync"]; since = "1.0.0"; weight = 3724 };
  { key = "block.trade.hidden_0110";                     label = "modern_enchant_110";          arity = 7; tags = ["hot"; "runtime"]; since = "1.0.0"; weight = 828 };
  { key = "compass.trade.loose_0111";                    label = "public_block_111";            arity = 0; tags = ["untyped"]; since = "1.7.0"; weight = 4072 };
  { key = "structure.trade.eager_0112";                  label = "global_comparator_112";       arity = 6; tags = ["content"; "parse"; "codegen"]; since = "1.4.0"; weight = 811 };
  { key = "sound.trade.local_0113";                      label = "secondary_banner_113";        arity = 3; tags = ["cold"]; since = "1.7.0"; weight = 1588 };
  { key = "scoreboard.trade.derived_0114";               label = "cached_crossbow_114";         arity = 0; tags = ["experimental"]; since = "1.0.0"; weight = 756 };
  { key = "observer.trade.modern_0115";                  label = "stable_pane_115";             arity = 2; tags = ["codegen"; "cold"; "lower"]; since = "1.2.0"; weight = 3409 };
  { key = "bossbar.trade.eager_0116";                    label = "public_grindstone_116";       arity = 7; tags = ["sync"]; since = "1.4.0"; weight = 13 };
  { key = "bossbar.trade.global_0117";                   label = "global_hologram_117";         arity = 5; tags = ["legacy"]; since = "1.2.0"; weight = 734 };
  { key = "enchant.trade.public_0118";                   label = "provisional_smithing_118";    arity = 5; tags = ["legacy"; "experimental"; "emit"]; since = "1.9.0"; weight = 5 };
  { key = "conduit.trade.loose_0119";                    label = "stable_repeater_119";         arity = 3; tags = ["compat"]; since = "1.6.0"; weight = 2520 };
  { key = "firework.trade.canonical_0120";               label = "primary_objective_120";       arity = 4; tags = ["registry"; "core"; "compat"]; since = "1.7.0"; weight = 819 };
  { key = "npc.trade.global_0121";                       label = "global_entity_121";           arity = 7; tags = ["core"; "legacy"]; since = "1.9.0"; weight = 1080 };
  { key = "slot.trade.eager_0122";                       label = "lazy_portal_122";             arity = 3; tags = ["emit"; "hot"; "content"]; since = "1.8.3"; weight = 1681 };
  { key = "spawner.trade.derived_0123";                  label = "lazy_loom_123";               arity = 1; tags = ["async"; "check"; "sync"]; since = "1.8.3"; weight = 2866 };
  { key = "arrow.trade.canonical_0124";                  label = "global_target_124";           arity = 2; tags = ["sync"; "typed"]; since = "1.0.0"; weight = 442 };
  { key = "shulker.trade.primary_0125";                  label = "global_bossbar_125";          arity = 2; tags = ["typed"]; since = "1.0.0"; weight = 1048 };
  { key = "item.trade.loose_0126";                       label = "cached_lectern_126";          arity = 1; tags = ["legacy"]; since = "1.5.2"; weight = 4079 };
  { key = "anvil.trade.lazy_0127";                       label = "secondary_banner_127";        arity = 3; tags = ["compat"; "parse"]; since = "1.8.3"; weight = 3000 };
  { key = "cartography.trade.canonical_0128";            label = "internal_brewing_128";        arity = 0; tags = ["sync"; "cached"; "packet"]; since = "1.7.0"; weight = 197 };
  { key = "repeater.trade.strict_0129";                  label = "eager_player_129";            arity = 5; tags = ["hot"; "codegen"]; since = "1.4.0"; weight = 639 };
  { key = "pane.trade.loose_0130";                       label = "internal_team_130";           arity = 1; tags = ["cached"]; since = "1.5.2"; weight = 1594 };
  { key = "furnace.trade.global_0131";                   label = "eager_structure_131";         arity = 2; tags = ["sync"]; since = "1.9.0"; weight = 2349 };
  { key = "team.trade.cached_0132";                      label = "lazy_beacon_132";             arity = 6; tags = ["experimental"; "cached"; "untyped"]; since = "1.3.1"; weight = 2203 };
  { key = "shield.trade.provisional_0133";               label = "canonical_shulker_133";       arity = 2; tags = ["compat"; "cached"]; since = "1.0.0"; weight = 3900 };
  { key = "player.trade.eager_0134";                     label = "secondary_team_134";          arity = 0; tags = ["content"; "untyped"]; since = "1.2.0"; weight = 3209 };
  { key = "potion.trade.local_0135";                     label = "secondary_sound_135";         arity = 5; tags = ["async"]; since = "1.5.2"; weight = 248 };
  { key = "slot.trade.hidden_0136";                      label = "secondary_rail_136";          arity = 1; tags = ["typed"; "cold"; "legacy"]; since = "1.2.0"; weight = 3386 };
  { key = "dropper.trade.global_0137";                   label = "public_block_137";            arity = 0; tags = ["experimental"; "content"; "untyped"]; since = "1.5.2"; weight = 567 };
  { key = "scoreboard.trade.hidden_0138";                label = "eager_tablist_138";           arity = 0; tags = ["emit"; "content"]; since = "1.2.0"; weight = 2369 };
  { key = "trade.trade.fallback_0139";                   label = "loose_minecart_139";          arity = 6; tags = ["lower"; "untyped"; "core"]; since = "1.3.1"; weight = 626 };
  { key = "comparator.trade.hidden_0140";                label = "loose_tablist_140";           arity = 0; tags = ["async"; "sync"]; since = "1.3.1"; weight = 425 };
  { key = "banner_pattern.trade.local_0141";             label = "loose_sound_141";             arity = 6; tags = ["sync"; "typed"; "experimental"]; since = "1.4.0"; weight = 519 };
  { key = "lectern.trade.eager_0142";                    label = "fallback_elytra_142";         arity = 1; tags = ["parse"; "packet"; "registry"]; since = "1.9.0"; weight = 846 };
  { key = "minecart.trade.derived_0143";                 label = "cached_grindstone_143";       arity = 0; tags = ["core"; "compat"; "parse"]; since = "1.6.0"; weight = 691 };
  { key = "slot.trade.hidden_0144";                      label = "local_conduit_144";           arity = 4; tags = ["sync"; "cold"; "untyped"]; since = "1.5.2"; weight = 1503 };
  { key = "chunk.trade.canonical_0145";                  label = "secondary_tablist_145";       arity = 0; tags = ["content"; "async"]; since = "1.5.2"; weight = 706 };
  { key = "potion.trade.canonical_0146";                 label = "derived_hologram_146";        arity = 5; tags = ["packet"]; since = "1.7.0"; weight = 433 };
  { key = "potion.trade.cached_0147";                    label = "internal_target_147";         arity = 7; tags = ["parse"; "lower"]; since = "1.9.0"; weight = 1768 };
  { key = "item.trade.primary_0148";                     label = "loose_slot_148";              arity = 4; tags = ["runtime"; "compat"; "async"]; since = "1.6.0"; weight = 2199 };
  { key = "sound.trade.modern_0149";                     label = "eager_repeater_149";          arity = 4; tags = ["cold"; "core"]; since = "1.8.3"; weight = 3986 };
  { key = "beacon.trade.strict_0150";                    label = "lazy_pane_150";               arity = 3; tags = ["experimental"; "untyped"; "codegen"]; since = "1.5.2"; weight = 905 };
  { key = "bundle.trade.cached_0151";                    label = "loose_brewing_151";           arity = 4; tags = ["cached"]; since = "1.5.2"; weight = 871 };
  { key = "cartography.trade.legacy_0152";               label = "local_hopper_152";            arity = 6; tags = ["legacy"]; since = "1.9.0"; weight = 3642 };
  { key = "team.trade.modern_0153";                      label = "local_barrel_153";            arity = 5; tags = ["cold"]; since = "1.2.0"; weight = 2600 };
  { key = "target.trade.modern_0154";                    label = "internal_block_154";          arity = 2; tags = ["content"; "hot"]; since = "1.4.0"; weight = 868 };
  { key = "structure.trade.modern_0155";                 label = "lazy_dispenser_155";          arity = 4; tags = ["core"]; since = "1.0.0"; weight = 3037 };
  { key = "sound.trade.scoped_0156";                     label = "global_comparator_156";       arity = 7; tags = ["compat"]; since = "1.9.0"; weight = 1922 };
  { key = "structure.trade.secondary_0157";              label = "scoped_region_157";           arity = 3; tags = ["experimental"; "check"; "sync"]; since = "1.4.0"; weight = 2163 };
  { key = "hologram.trade.primary_0158";                 label = "global_recipe_158";           arity = 6; tags = ["cached"]; since = "1.7.0"; weight = 2919 };
  { key = "portal.trade.public_0159";                    label = "cached_portal_159";           arity = 5; tags = ["cached"; "compat"; "lower"]; since = "1.9.0"; weight = 3914 };
  { key = "banner.trade.internal_0160";                  label = "lazy_effect_160";             arity = 4; tags = ["packet"; "content"]; since = "1.3.1"; weight = 536 };
  { key = "clock.trade.fallback_0161";                   label = "global_furnace_161";          arity = 1; tags = ["emit"; "hot"]; since = "1.2.0"; weight = 1917 };
  { key = "elytra.trade.eager_0162";                     label = "provisional_furnace_162";     arity = 7; tags = ["lower"; "hot"]; since = "1.9.0"; weight = 2546 };
  { key = "bundle.trade.canonical_0163";                 label = "canonical_scoreboard_163";    arity = 1; tags = ["packet"]; since = "1.7.0"; weight = 824 };
  { key = "biome.trade.internal_0164";                   label = "strict_objective_164";        arity = 1; tags = ["cold"]; since = "1.6.0"; weight = 1827 };
  { key = "structure.trade.strict_0165";                 label = "cached_team_165";             arity = 6; tags = ["registry"]; since = "1.6.0"; weight = 349 };
  { key = "villager.trade.derived_0166";                 label = "strict_compass_166";          arity = 5; tags = ["content"; "packet"]; since = "1.6.0"; weight = 237 };
  { key = "conduit.trade.loose_0167";                    label = "secondary_sound_167";         arity = 1; tags = ["hot"; "packet"]; since = "1.3.1"; weight = 3373 };
  { key = "crossbow.trade.lazy_0168";                    label = "strict_mob_168";              arity = 6; tags = ["registry"; "codegen"; "sync"]; since = "1.9.0"; weight = 1090 };
  { key = "hopper.trade.public_0169";                    label = "primary_tablist_169";         arity = 4; tags = ["core"]; since = "1.9.0"; weight = 306 };
  { key = "piston.trade.stable_0170";                    label = "loose_player_170";            arity = 2; tags = ["packet"]; since = "1.5.2"; weight = 2546 };
  { key = "attribute.trade.internal_0171";               label = "public_chunk_171";            arity = 1; tags = ["emit"; "cold"; "sync"]; since = "1.2.0"; weight = 1988 };
  { key = "elytra.trade.stable_0172";                    label = "provisional_hopper_172";      arity = 6; tags = ["packet"]; since = "1.8.3"; weight = 3727 };
  { key = "campfire.trade.lazy_0173";                    label = "legacy_shulker_173";          arity = 1; tags = ["content"; "lower"; "async"]; since = "1.0.0"; weight = 1478 };
  { key = "attribute.trade.modern_0174";                 label = "provisional_stonecutter_174"; arity = 6; tags = ["compat"; "runtime"; "untyped"]; since = "1.5.2"; weight = 3678 };
  { key = "gui.trade.internal_0175";                     label = "derived_spawner_175";         arity = 0; tags = ["compat"; "cached"]; since = "1.2.0"; weight = 2516 };
  { key = "rail.trade.hidden_0176";                      label = "secondary_banner_pattern_176"; arity = 4; tags = ["emit"]; since = "1.3.1"; weight = 2529 };
  { key = "bossbar.trade.stable_0177";                   label = "strict_particle_177";         arity = 3; tags = ["packet"; "runtime"; "core"]; since = "1.3.1"; weight = 1102 };
  { key = "advancement.trade.internal_0178";             label = "hidden_bell_178";             arity = 2; tags = ["core"; "compat"]; since = "1.4.0"; weight = 3359 };
  { key = "lectern.trade.secondary_0179";                label = "local_brewing_179";           arity = 4; tags = ["runtime"]; since = "1.4.0"; weight = 238 };
  { key = "trident.trade.strict_0180";                   label = "scoped_particle_180";         arity = 5; tags = ["registry"; "typed"; "async"]; since = "1.9.0"; weight = 53 };
  { key = "enchant.trade.legacy_0181";                   label = "stable_effect_181";           arity = 5; tags = ["registry"; "check"]; since = "1.6.0"; weight = 2229 };
  { key = "banner_pattern.trade.global_0182";            label = "fallback_villager_182";       arity = 2; tags = ["cold"; "hot"]; since = "1.3.1"; weight = 3264 };
  { key = "loom.trade.loose_0183";                       label = "secondary_trade_183";         arity = 1; tags = ["runtime"; "check"]; since = "1.3.1"; weight = 1852 };
  { key = "loom.trade.canonical_0184";                   label = "global_composter_184";        arity = 5; tags = ["runtime"]; since = "1.2.0"; weight = 2173 };
  { key = "particle.trade.public_0185";                  label = "secondary_dropper_185";       arity = 7; tags = ["core"; "content"; "emit"]; since = "1.0.0"; weight = 1209 };
  { key = "structure.trade.scoped_0186";                 label = "secondary_target_186";        arity = 5; tags = ["hot"; "typed"]; since = "1.5.2"; weight = 517 };
  { key = "comparator.trade.cached_0187";                label = "canonical_banner_pattern_187"; arity = 4; tags = ["lower"; "codegen"; "async"]; since = "1.2.0"; weight = 2554 };
  { key = "banner_pattern.trade.hidden_0188";            label = "canonical_anvil_188";         arity = 5; tags = ["compat"; "lower"; "check"]; since = "1.6.0"; weight = 3804 };
  { key = "team.trade.secondary_0189";                   label = "loose_potion_189";            arity = 6; tags = ["typed"; "core"]; since = "1.9.0"; weight = 1892 };
  { key = "hologram.trade.public_0190";                  label = "hidden_inventory_190";        arity = 5; tags = ["untyped"; "cached"; "compat"]; since = "1.3.1"; weight = 595 };
  { key = "recipe.trade.local_0191";                     label = "lazy_map_191";                arity = 3; tags = ["lower"; "cold"]; since = "1.6.0"; weight = 1276 };
  { key = "firework.trade.loose_0192";                   label = "cached_structure_192";        arity = 7; tags = ["emit"; "check"]; since = "1.4.0"; weight = 3248 };
  { key = "pane.trade.stable_0193";                      label = "public_world_193";            arity = 7; tags = ["legacy"; "experimental"; "packet"]; since = "1.2.0"; weight = 1903 };
  { key = "brewing.trade.scoped_0194";                   label = "eager_campfire_194";          arity = 0; tags = ["compat"; "cached"; "sync"]; since = "1.5.2"; weight = 3191 };
  { key = "dispenser.trade.primary_0195";                label = "local_player_195";            arity = 6; tags = ["async"]; since = "1.4.0"; weight = 3682 };
  { key = "item.trade.local_0196";                       label = "global_map_196";              arity = 6; tags = ["core"]; since = "1.0.0"; weight = 1614 };
  { key = "bundle.trade.secondary_0197";                 label = "lazy_item_197";               arity = 6; tags = ["sync"; "hot"; "async"]; since = "1.5.2"; weight = 1729 };
  { key = "potion.trade.secondary_0198";                 label = "legacy_compass_198";          arity = 7; tags = ["content"; "compat"]; since = "1.7.0"; weight = 1755 };
  { key = "arrow.trade.derived_0199";                    label = "loose_beacon_199";            arity = 2; tags = ["parse"; "registry"; "lower"]; since = "1.5.2"; weight = 3864 };
  { key = "stonecutter.trade.hidden_0200";               label = "lazy_tablist_200";            arity = 5; tags = ["typed"; "codegen"; "compat"]; since = "1.0.0"; weight = 4014 };
  { key = "scoreboard.trade.scoped_0201";                label = "legacy_particle_201";         arity = 4; tags = ["emit"; "compat"; "experimental"]; since = "1.5.2"; weight = 3312 };
  { key = "barrel.trade.secondary_0202";                 label = "canonical_structure_202";     arity = 5; tags = ["emit"; "packet"; "lower"]; since = "1.6.0"; weight = 1901 };
  { key = "potion.trade.loose_0203";                     label = "strict_sound_203";            arity = 4; tags = ["untyped"; "parse"]; since = "1.0.0"; weight = 1654 };
  { key = "cartography.trade.hidden_0204";               label = "provisional_enchant_204";     arity = 2; tags = ["hot"; "lower"; "codegen"]; since = "1.2.0"; weight = 27 };
  { key = "bossbar.trade.internal_0205";                 label = "legacy_elytra_205";           arity = 5; tags = ["untyped"; "codegen"; "registry"]; since = "1.0.0"; weight = 3997 };
  { key = "comparator.trade.internal_0206";              label = "internal_cartography_206";    arity = 1; tags = ["packet"; "cached"]; since = "1.9.0"; weight = 974 };
  { key = "team.trade.canonical_0207";                   label = "scoped_map_207";              arity = 4; tags = ["typed"]; since = "1.9.0"; weight = 1509 };
  { key = "portal.trade.fallback_0208";                  label = "legacy_conduit_208";          arity = 6; tags = ["lower"; "cold"]; since = "1.2.0"; weight = 845 };
  { key = "inventory.trade.hidden_0209";                 label = "scoped_slot_209";             arity = 0; tags = ["runtime"; "compat"; "sync"]; since = "1.9.0"; weight = 295 };
  { key = "map.trade.eager_0210";                        label = "canonical_objective_210";     arity = 2; tags = ["runtime"]; since = "1.8.3"; weight = 988 };
  { key = "item.trade.canonical_0211";                   label = "canonical_conduit_211";       arity = 3; tags = ["content"]; since = "1.4.0"; weight = 577 };
  { key = "attribute.trade.derived_0212";                label = "eager_furnace_212";           arity = 7; tags = ["hot"; "registry"; "cold"]; since = "1.8.3"; weight = 3745 };
  { key = "lectern.trade.legacy_0213";                   label = "provisional_potion_213";      arity = 0; tags = ["check"; "typed"; "core"]; since = "1.7.0"; weight = 1505 };
  { key = "region.trade.eager_0214";                     label = "lazy_elytra_214";             arity = 2; tags = ["async"]; since = "1.7.0"; weight = 3848 };
  { key = "item.trade.strict_0215";                      label = "hidden_campfire_215";         arity = 1; tags = ["async"]; since = "1.8.3"; weight = 3042 };
  { key = "sound.trade.eager_0216";                      label = "modern_entity_216";           arity = 1; tags = ["registry"; "untyped"]; since = "1.4.0"; weight = 3491 };
  { key = "campfire.trade.secondary_0217";               label = "provisional_dropper_217";     arity = 1; tags = ["core"]; since = "1.7.0"; weight = 742 };
  { key = "dispenser.trade.provisional_0218";            label = "loose_smoker_218";            arity = 4; tags = ["experimental"; "lower"; "legacy"]; since = "1.8.3"; weight = 529 };
  { key = "minecart.trade.provisional_0219";             label = "local_potion_219";            arity = 1; tags = ["compat"; "emit"; "registry"]; since = "1.6.0"; weight = 3791 };
  { key = "lectern.trade.secondary_0220";                label = "stable_smithing_220";         arity = 1; tags = ["compat"; "typed"]; since = "1.2.0"; weight = 1078 };
  { key = "objective.trade.provisional_0221";            label = "legacy_region_221";           arity = 2; tags = ["packet"]; since = "1.5.2"; weight = 1296 };
  { key = "scoreboard.trade.stable_0222";                label = "legacy_effect_222";           arity = 0; tags = ["lower"]; since = "1.5.2"; weight = 1019 };
  { key = "loom.trade.global_0223";                      label = "local_shulker_223";           arity = 3; tags = ["cold"; "legacy"]; since = "1.9.0"; weight = 2653 };
  { key = "pane.trade.strict_0224";                      label = "primary_lectern_224";         arity = 0; tags = ["experimental"; "cold"; "async"]; since = "1.4.0"; weight = 1428 };
  { key = "furnace.trade.eager_0225";                    label = "primary_smoker_225";          arity = 4; tags = ["hot"]; since = "1.9.0"; weight = 2874 };
  { key = "hologram.trade.canonical_0226";               label = "internal_firework_226";       arity = 0; tags = ["parse"; "compat"]; since = "1.6.0"; weight = 643 };
  { key = "map.trade.provisional_0227";                  label = "global_recipe_227";           arity = 1; tags = ["core"]; since = "1.5.2"; weight = 3569 };
  { key = "shield.trade.lazy_0228";                      label = "strict_inventory_228";        arity = 7; tags = ["content"]; since = "1.6.0"; weight = 2075 };
  { key = "lectern.trade.internal_0229";                 label = "provisional_advancement_229"; arity = 6; tags = ["untyped"]; since = "1.6.0"; weight = 1377 };
  { key = "clock.trade.cached_0230";                     label = "secondary_compass_230";       arity = 1; tags = ["registry"; "core"]; since = "1.2.0"; weight = 3636 };
  { key = "dropper.trade.primary_0231";                  label = "canonical_smithing_231";      arity = 6; tags = ["sync"; "core"]; since = "1.0.0"; weight = 3577 };
  { key = "block.trade.scoped_0232";                     label = "strict_objective_232";        arity = 6; tags = ["async"; "registry"]; since = "1.5.2"; weight = 1247 };
  { key = "trade.trade.cached_0233";                     label = "hidden_inventory_233";        arity = 3; tags = ["parse"; "registry"]; since = "1.7.0"; weight = 3702 };
  { key = "block.trade.provisional_0234";                label = "lazy_minecart_234";           arity = 3; tags = ["lower"; "sync"]; since = "1.8.3"; weight = 1314 };
  { key = "comparator.trade.loose_0235";                 label = "global_firework_235";         arity = 1; tags = ["check"]; since = "1.5.2"; weight = 1135 };
  { key = "pane.trade.derived_0236";                     label = "fallback_inventory_236";      arity = 1; tags = ["emit"; "sync"; "hot"]; since = "1.9.0"; weight = 2820 };
  { key = "target.trade.global_0237";                    label = "strict_minecart_237";         arity = 7; tags = ["untyped"; "registry"]; since = "1.6.0"; weight = 1862 };
  { key = "stonecutter.trade.global_0238";               label = "secondary_smoker_238";        arity = 4; tags = ["check"; "core"; "packet"]; since = "1.2.0"; weight = 665 };
  { key = "arrow.trade.public_0239";                     label = "scoped_banner_pattern_239";   arity = 0; tags = ["runtime"]; since = "1.5.2"; weight = 2342 };
  { key = "rail.trade.lazy_0240";                        label = "cached_slot_240";             arity = 1; tags = ["lower"; "registry"]; since = "1.0.0"; weight = 2128 };
  { key = "block.trade.hidden_0241";                     label = "eager_anvil_241";             arity = 1; tags = ["cached"; "typed"]; since = "1.7.0"; weight = 2270 };
  { key = "attribute.trade.public_0242";                 label = "hidden_minecart_242";         arity = 7; tags = ["typed"; "hot"; "cold"]; since = "1.5.2"; weight = 2829 };
  { key = "recipe.trade.loose_0243";                     label = "strict_smithing_243";         arity = 5; tags = ["async"]; since = "1.6.0"; weight = 609 };
  { key = "comparator.trade.provisional_0244";           label = "modern_firework_244";         arity = 1; tags = ["registry"]; since = "1.6.0"; weight = 1611 };
  { key = "chunk.trade.modern_0245";                     label = "strict_bell_245";             arity = 3; tags = ["runtime"; "core"]; since = "1.5.2"; weight = 1201 };
  { key = "bundle.trade.canonical_0246";                 label = "scoped_piston_246";           arity = 1; tags = ["sync"; "check"]; since = "1.6.0"; weight = 3980 };
  { key = "portal.trade.scoped_0247";                    label = "derived_trade_247";           arity = 3; tags = ["compat"]; since = "1.8.3"; weight = 2248 };
  { key = "rail.trade.public_0248";                      label = "canonical_bell_248";          arity = 4; tags = ["packet"; "hot"]; since = "1.2.0"; weight = 2592 };
  { key = "boat.trade.legacy_0249";                      label = "modern_scoreboard_249";       arity = 1; tags = ["content"; "codegen"; "hot"]; since = "1.8.3"; weight = 843 };
  { key = "anvil.trade.legacy_0250";                     label = "provisional_bossbar_250";     arity = 6; tags = ["experimental"; "runtime"]; since = "1.6.0"; weight = 246 };
  { key = "dropper.trade.internal_0251";                 label = "public_potion_251";           arity = 6; tags = ["untyped"; "registry"; "emit"]; since = "1.5.2"; weight = 3944 };
  { key = "bell.trade.scoped_0252";                      label = "public_brewing_252";          arity = 3; tags = ["codegen"; "sync"; "registry"]; since = "1.4.0"; weight = 3071 };
  { key = "trade.trade.hidden_0253";                     label = "public_effect_253";           arity = 7; tags = ["sync"]; since = "1.8.3"; weight = 4093 };
  { key = "structure.trade.fallback_0254";               label = "global_beacon_254";           arity = 3; tags = ["experimental"; "check"]; since = "1.3.1"; weight = 3376 };
  { key = "repeater.trade.scoped_0255";                  label = "hidden_minecart_255";         arity = 3; tags = ["registry"]; since = "1.9.0"; weight = 3498 };
  { key = "team.trade.derived_0256";                     label = "internal_particle_256";       arity = 1; tags = ["cold"]; since = "1.4.0"; weight = 2508 };
  { key = "tablist.trade.modern_0257";                   label = "hidden_arrow_257";            arity = 0; tags = ["sync"]; since = "1.9.0"; weight = 640 };
  { key = "inventory.trade.loose_0258";                  label = "eager_target_258";            arity = 1; tags = ["compat"]; since = "1.2.0"; weight = 1502 };
  { key = "grindstone.trade.modern_0259";                label = "canonical_tablist_259";       arity = 0; tags = ["codegen"; "hot"]; since = "1.9.0"; weight = 3680 };
  { key = "tablist.trade.loose_0260";                    label = "loose_compass_260";           arity = 3; tags = ["cached"; "typed"]; since = "1.6.0"; weight = 1827 };
  { key = "packet.trade.strict_0261";                    label = "canonical_tablist_261";       arity = 2; tags = ["runtime"]; since = "1.5.2"; weight = 3659 };
  { key = "tablist.trade.eager_0262";                    label = "canonical_clock_262";         arity = 7; tags = ["emit"; "codegen"]; since = "1.8.3"; weight = 15 };
  { key = "slot.trade.primary_0263";                     label = "canonical_firework_263";      arity = 0; tags = ["packet"]; since = "1.6.0"; weight = 2842 };
  { key = "portal.trade.legacy_0264";                    label = "hidden_hopper_264";           arity = 1; tags = ["async"]; since = "1.4.0"; weight = 3531 };
  { key = "bundle.trade.legacy_0265";                    label = "public_structure_265";        arity = 7; tags = ["sync"; "hot"; "packet"]; since = "1.2.0"; weight = 1921 };
  { key = "player.trade.derived_0266";                   label = "public_biome_266";            arity = 5; tags = ["async"]; since = "1.3.1"; weight = 1389 };
  { key = "hopper.trade.modern_0267";                    label = "cached_potion_267";           arity = 5; tags = ["experimental"; "hot"]; since = "1.5.2"; weight = 2420 };
  { key = "smoker.trade.legacy_0268";                    label = "cached_boat_268";             arity = 4; tags = ["codegen"; "lower"; "parse"]; since = "1.4.0"; weight = 424 };
  { key = "tablist.trade.cached_0269";                   label = "strict_comparator_269";       arity = 2; tags = ["cold"; "emit"]; since = "1.5.2"; weight = 1333 };
  { key = "bell.trade.scoped_0270";                      label = "legacy_loom_270";             arity = 3; tags = ["async"]; since = "1.3.1"; weight = 2655 };
  { key = "campfire.trade.eager_0271";                   label = "internal_cartography_271";    arity = 4; tags = ["legacy"]; since = "1.2.0"; weight = 912 };
  { key = "firework.trade.stable_0272";                  label = "hidden_recipe_272";           arity = 4; tags = ["registry"; "core"]; since = "1.5.2"; weight = 1884 };
  { key = "piston.trade.loose_0273";                     label = "stable_enchant_273";          arity = 6; tags = ["registry"; "cold"]; since = "1.4.0"; weight = 296 };
  { key = "crossbow.trade.internal_0274";                label = "derived_firework_274";        arity = 5; tags = ["emit"; "packet"]; since = "1.2.0"; weight = 2256 };
  { key = "gui.trade.stable_0275";                       label = "internal_campfire_275";       arity = 1; tags = ["content"]; since = "1.0.0"; weight = 2676 };
  { key = "compass.trade.derived_0276";                  label = "eager_elytra_276";            arity = 3; tags = ["core"; "parse"]; since = "1.5.2"; weight = 365 };
  { key = "trade.trade.local_0277";                      label = "eager_rail_277";              arity = 6; tags = ["codegen"; "runtime"; "cold"]; since = "1.9.0"; weight = 3525 };
  { key = "anvil.trade.local_0278";                      label = "canonical_enchant_278";       arity = 6; tags = ["codegen"; "packet"]; since = "1.8.3"; weight = 1937 };
  { key = "structure.trade.global_0279";                 label = "strict_banner_279";           arity = 3; tags = ["compat"; "cold"; "content"]; since = "1.2.0"; weight = 273 };
  { key = "smoker.trade.cached_0280";                    label = "legacy_minecart_280";         arity = 0; tags = ["check"]; since = "1.6.0"; weight = 5 };
  { key = "target.trade.lazy_0281";                      label = "strict_lectern_281";          arity = 6; tags = ["cached"]; since = "1.3.1"; weight = 560 };
  { key = "grindstone.trade.hidden_0282";                label = "canonical_banner_282";        arity = 6; tags = ["content"]; since = "1.2.0"; weight = 2463 };
  { key = "anvil.trade.cached_0283";                     label = "derived_barrel_283";          arity = 2; tags = ["untyped"; "codegen"]; since = "1.7.0"; weight = 773 };
  { key = "region.trade.internal_0284";                  label = "lazy_shield_284";             arity = 5; tags = ["check"; "core"; "runtime"]; since = "1.6.0"; weight = 230 };
  { key = "target.trade.global_0285";                    label = "cached_loom_285";             arity = 7; tags = ["registry"]; since = "1.4.0"; weight = 704 };
  { key = "brewing.trade.canonical_0286";                label = "stable_map_286";              arity = 0; tags = ["cold"; "hot"]; since = "1.0.0"; weight = 458 };
  { key = "tablist.trade.strict_0287";                   label = "canonical_trident_287";       arity = 6; tags = ["experimental"]; since = "1.9.0"; weight = 1227 };
  { key = "smoker.trade.secondary_0288";                 label = "loose_boat_288";              arity = 4; tags = ["compat"]; since = "1.6.0"; weight = 3671 };
  { key = "banner.trade.fallback_0289";                  label = "hidden_scoreboard_289";       arity = 5; tags = ["cold"; "compat"; "runtime"]; since = "1.8.3"; weight = 1387 };
  { key = "inventory.trade.scoped_0290";                 label = "derived_world_290";           arity = 4; tags = ["async"; "hot"; "lower"]; since = "1.2.0"; weight = 1370 };
  { key = "banner_pattern.trade.eager_0291";             label = "cached_arrow_291";            arity = 0; tags = ["check"; "emit"]; since = "1.7.0"; weight = 381 };
  { key = "tablist.trade.global_0292";                   label = "legacy_potion_292";           arity = 4; tags = ["hot"; "check"]; since = "1.5.2"; weight = 2839 };
  { key = "piston.trade.cached_0293";                    label = "global_campfire_293";         arity = 3; tags = ["codegen"]; since = "1.7.0"; weight = 3529 };
  { key = "dispenser.trade.lazy_0294";                   label = "cached_team_294";             arity = 0; tags = ["cold"]; since = "1.9.0"; weight = 2350 };
  { key = "player.trade.legacy_0295";                    label = "cached_stonecutter_295";      arity = 2; tags = ["hot"; "compat"]; since = "1.4.0"; weight = 1284 };
  { key = "inventory.trade.derived_0296";                label = "loose_advancement_296";       arity = 1; tags = ["parse"; "sync"; "untyped"]; since = "1.3.1"; weight = 322 };
  { key = "villager.trade.internal_0297";                label = "modern_minecart_297";         arity = 1; tags = ["experimental"]; since = "1.2.0"; weight = 134 };
  { key = "packet.trade.secondary_0298";                 label = "secondary_minecart_298";      arity = 3; tags = ["lower"]; since = "1.9.0"; weight = 3156 };
  { key = "bossbar.trade.secondary_0299";                label = "derived_potion_299";          arity = 1; tags = ["content"; "legacy"; "compat"]; since = "1.5.2"; weight = 2756 };
  { key = "enchant.trade.cached_0300";                   label = "loose_gui_300";               arity = 2; tags = ["codegen"]; since = "1.2.0"; weight = 1235 };
  { key = "scoreboard.trade.canonical_0301";             label = "modern_stonecutter_301";      arity = 3; tags = ["cached"]; since = "1.5.2"; weight = 548 };
  { key = "shulker.trade.canonical_0302";                label = "scoped_objective_302";        arity = 4; tags = ["parse"]; since = "1.5.2"; weight = 3858 };
  { key = "smoker.trade.internal_0303";                  label = "scoped_mob_303";              arity = 4; tags = ["core"; "cold"; "sync"]; since = "1.6.0"; weight = 404 };
  { key = "elytra.trade.legacy_0304";                    label = "loose_villager_304";          arity = 3; tags = ["hot"; "typed"; "lower"]; since = "1.7.0"; weight = 2144 };
]

let count = List.length entries

let table : (string, trade_entry) Hashtbl.t =
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
