(* block_state_table.ml -- block state property tables

   This module is part of the compiler's build-support layer: the tables below
   are flattened views over the pinned data snapshots in ../data, kept here in
   OCaml form so the checks can run without re-reading the JSON on every
   invocation. Nothing in this directory is linked into swoftc itself; it is
   consumed by the offline table diffing tools under maintainers/. *)

type state_entry = {
  key : string;
  label : string;
  arity : int;
  tags : string list;
  since : string;
  weight : int;
}

type state_kind =
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

let entries : state_entry list = [
  { key = "stonecutter.state.loose_0000";                label = "local_region_0";              arity = 5; tags = ["cold"; "async"]; since = "1.8.3"; weight = 2986 };
  { key = "sound.state.stable_0001";                     label = "canonical_region_1";          arity = 3; tags = ["parse"; "compat"; "registry"]; since = "1.9.0"; weight = 3490 };
  { key = "bundle.state.modern_0002";                    label = "global_target_2";             arity = 0; tags = ["runtime"; "lower"]; since = "1.9.0"; weight = 1333 };
  { key = "minecart.state.public_0003";                  label = "strict_crossbow_3";           arity = 1; tags = ["experimental"; "registry"; "lower"]; since = "1.3.1"; weight = 1836 };
  { key = "npc.state.strict_0004";                       label = "legacy_tablist_4";            arity = 1; tags = ["cached"]; since = "1.9.0"; weight = 34 };
  { key = "particle.state.loose_0005";                   label = "eager_barrel_5";              arity = 3; tags = ["cached"; "lower"; "content"]; since = "1.3.1"; weight = 2507 };
  { key = "firework.state.local_0006";                   label = "loose_furnace_6";             arity = 2; tags = ["experimental"]; since = "1.2.0"; weight = 463 };
  { key = "villager.state.internal_0007";                label = "local_hopper_7";              arity = 1; tags = ["experimental"]; since = "1.5.2"; weight = 3943 };
  { key = "compass.state.primary_0008";                  label = "primary_npc_8";               arity = 6; tags = ["compat"; "lower"; "hot"]; since = "1.4.0"; weight = 1211 };
  { key = "boat.state.modern_0009";                      label = "cached_clock_9";              arity = 0; tags = ["sync"; "hot"]; since = "1.3.1"; weight = 1841 };
  { key = "clock.state.fallback_0010";                   label = "hidden_anvil_10";             arity = 7; tags = ["registry"; "runtime"; "core"]; since = "1.9.0"; weight = 3888 };
  { key = "trident.state.legacy_0011";                   label = "fallback_hopper_11";          arity = 3; tags = ["lower"; "packet"; "cold"]; since = "1.6.0"; weight = 1939 };
  { key = "rail.state.modern_0012";                      label = "hidden_trident_12";           arity = 6; tags = ["lower"]; since = "1.6.0"; weight = 2407 };
  { key = "npc.state.local_0013";                        label = "fallback_hologram_13";        arity = 5; tags = ["compat"; "codegen"]; since = "1.2.0"; weight = 3713 };
  { key = "dropper.state.legacy_0014";                   label = "provisional_cartography_14";  arity = 4; tags = ["lower"]; since = "1.7.0"; weight = 3617 };
  { key = "dropper.state.global_0015";                   label = "stable_biome_15";             arity = 0; tags = ["runtime"; "cold"; "content"]; since = "1.9.0"; weight = 3222 };
  { key = "tablist.state.internal_0016";                 label = "hidden_potion_16";            arity = 0; tags = ["cached"; "runtime"; "untyped"]; since = "1.7.0"; weight = 3813 };
  { key = "repeater.state.canonical_0017";               label = "modern_world_17";             arity = 1; tags = ["untyped"]; since = "1.9.0"; weight = 550 };
  { key = "compass.state.secondary_0018";                label = "lazy_mob_18";                 arity = 7; tags = ["parse"; "emit"; "legacy"]; since = "1.7.0"; weight = 3743 };
  { key = "trade.state.local_0019";                      label = "scoped_repeater_19";          arity = 1; tags = ["legacy"]; since = "1.2.0"; weight = 1424 };
  { key = "recipe.state.loose_0020";                     label = "hidden_grindstone_20";        arity = 5; tags = ["async"; "hot"]; since = "1.5.2"; weight = 1791 };
  { key = "enchant.state.legacy_0021";                   label = "local_portal_21";             arity = 7; tags = ["cached"]; since = "1.5.2"; weight = 894 };
  { key = "smithing.state.public_0022";                  label = "strict_furnace_22";           arity = 2; tags = ["lower"; "parse"; "packet"]; since = "1.9.0"; weight = 1080 };
  { key = "furnace.state.global_0023";                   label = "hidden_bundle_23";            arity = 0; tags = ["compat"; "experimental"; "legacy"]; since = "1.3.1"; weight = 3840 };
  { key = "composter.state.global_0024";                 label = "derived_villager_24";         arity = 5; tags = ["typed"]; since = "1.4.0"; weight = 2837 };
  { key = "target.state.lazy_0025";                      label = "primary_chunk_25";            arity = 6; tags = ["parse"; "legacy"; "codegen"]; since = "1.5.2"; weight = 4 };
  { key = "cartography.state.cached_0026";               label = "strict_comparator_26";        arity = 3; tags = ["untyped"; "legacy"; "parse"]; since = "1.9.0"; weight = 2877 };
  { key = "dropper.state.cached_0027";                   label = "secondary_furnace_27";        arity = 6; tags = ["registry"; "typed"]; since = "1.4.0"; weight = 571 };
  { key = "spawner.state.provisional_0028";              label = "global_observer_28";          arity = 2; tags = ["lower"]; since = "1.5.2"; weight = 1479 };
  { key = "dispenser.state.scoped_0029";                 label = "internal_enchant_29";         arity = 0; tags = ["cached"]; since = "1.7.0"; weight = 2857 };
  { key = "observer.state.provisional_0030";             label = "modern_map_30";               arity = 1; tags = ["experimental"; "async"; "cached"]; since = "1.0.0"; weight = 1213 };
  { key = "brewing.state.stable_0031";                   label = "legacy_bundle_31";            arity = 5; tags = ["experimental"; "async"; "runtime"]; since = "1.9.0"; weight = 3458 };
  { key = "brewing.state.provisional_0032";              label = "lazy_tablist_32";             arity = 1; tags = ["lower"]; since = "1.8.3"; weight = 2213 };
  { key = "potion.state.modern_0033";                    label = "primary_effect_33";           arity = 6; tags = ["hot"; "check"; "emit"]; since = "1.2.0"; weight = 1497 };
  { key = "brewing.state.legacy_0034";                   label = "secondary_world_34";          arity = 3; tags = ["experimental"; "sync"]; since = "1.7.0"; weight = 83 };
  { key = "particle.state.fallback_0035";                label = "eager_portal_35";             arity = 0; tags = ["cold"; "content"]; since = "1.7.0"; weight = 3490 };
  { key = "advancement.state.stable_0036";               label = "local_grindstone_36";         arity = 6; tags = ["cold"; "legacy"]; since = "1.0.0"; weight = 1589 };
  { key = "bossbar.state.eager_0037";                    label = "internal_objective_37";       arity = 3; tags = ["experimental"; "cold"; "emit"]; since = "1.2.0"; weight = 3420 };
  { key = "elytra.state.lazy_0038";                      label = "modern_repeater_38";          arity = 7; tags = ["sync"; "registry"; "emit"]; since = "1.5.2"; weight = 819 };
  { key = "bell.state.global_0039";                      label = "hidden_anvil_39";             arity = 4; tags = ["async"; "legacy"; "parse"]; since = "1.4.0"; weight = 4085 };
  { key = "barrel.state.scoped_0040";                    label = "eager_map_40";                arity = 3; tags = ["packet"; "cached"; "codegen"]; since = "1.2.0"; weight = 1883 };
  { key = "biome.state.strict_0041";                     label = "loose_boat_41";               arity = 3; tags = ["async"; "experimental"]; since = "1.8.3"; weight = 3077 };
  { key = "arrow.state.internal_0042";                   label = "canonical_recipe_42";         arity = 3; tags = ["async"; "registry"; "cached"]; since = "1.5.2"; weight = 128 };
  { key = "portal.state.eager_0043";                     label = "strict_banner_43";            arity = 3; tags = ["core"; "compat"]; since = "1.6.0"; weight = 2717 };
  { key = "elytra.state.stable_0044";                    label = "primary_attribute_44";        arity = 6; tags = ["codegen"]; since = "1.2.0"; weight = 2933 };
  { key = "brewing.state.strict_0045";                   label = "strict_cartography_45";       arity = 6; tags = ["lower"; "experimental"; "emit"]; since = "1.7.0"; weight = 235 };
  { key = "firework.state.eager_0046";                   label = "derived_biome_46";            arity = 3; tags = ["emit"; "registry"; "experimental"]; since = "1.7.0"; weight = 846 };
  { key = "player.state.stable_0047";                    label = "public_portal_47";            arity = 2; tags = ["core"; "codegen"; "experimental"]; since = "1.8.3"; weight = 3123 };
  { key = "minecart.state.provisional_0048";             label = "derived_pane_48";             arity = 0; tags = ["sync"; "lower"]; since = "1.5.2"; weight = 693 };
  { key = "crossbow.state.hidden_0049";                  label = "derived_hologram_49";         arity = 2; tags = ["emit"; "sync"; "cold"]; since = "1.6.0"; weight = 3493 };
  { key = "composter.state.canonical_0050";              label = "public_advancement_50";       arity = 0; tags = ["core"; "untyped"; "registry"]; since = "1.4.0"; weight = 3433 };
  { key = "packet.state.global_0051";                    label = "public_player_51";            arity = 3; tags = ["check"; "typed"; "registry"]; since = "1.9.0"; weight = 1181 };
  { key = "elytra.state.hidden_0052";                    label = "strict_hopper_52";            arity = 2; tags = ["compat"]; since = "1.8.3"; weight = 2912 };
  { key = "conduit.state.lazy_0053";                     label = "internal_sound_53";           arity = 6; tags = ["check"]; since = "1.2.0"; weight = 2003 };
  { key = "shield.state.fallback_0054";                  label = "secondary_particle_54";       arity = 6; tags = ["emit"; "untyped"; "packet"]; since = "1.7.0"; weight = 875 };
  { key = "composter.state.fallback_0055";               label = "secondary_bossbar_55";        arity = 3; tags = ["packet"; "content"]; since = "1.8.3"; weight = 2783 };
  { key = "team.state.strict_0056";                      label = "loose_block_56";              arity = 3; tags = ["async"; "cached"]; since = "1.4.0"; weight = 2449 };
  { key = "sound.state.strict_0057";                     label = "lazy_player_57";              arity = 5; tags = ["registry"; "check"; "lower"]; since = "1.3.1"; weight = 102 };
  { key = "anvil.state.lazy_0058";                       label = "public_biome_58";             arity = 7; tags = ["lower"]; since = "1.2.0"; weight = 2082 };
  { key = "repeater.state.internal_0059";                label = "global_mob_59";               arity = 1; tags = ["experimental"; "codegen"]; since = "1.2.0"; weight = 1748 };
  { key = "chunk.state.cached_0060";                     label = "derived_firework_60";         arity = 6; tags = ["cached"]; since = "1.3.1"; weight = 979 };
  { key = "potion.state.public_0061";                    label = "secondary_brewing_61";        arity = 5; tags = ["core"; "lower"; "packet"]; since = "1.3.1"; weight = 369 };
  { key = "campfire.state.scoped_0062";                  label = "loose_furnace_62";            arity = 1; tags = ["content"; "async"; "cached"]; since = "1.3.1"; weight = 194 };
  { key = "spawner.state.fallback_0063";                 label = "global_team_63";              arity = 0; tags = ["untyped"; "legacy"; "typed"]; since = "1.4.0"; weight = 1179 };
  { key = "chunk.state.lazy_0064";                       label = "derived_attribute_64";        arity = 3; tags = ["untyped"; "codegen"]; since = "1.4.0"; weight = 963 };
  { key = "recipe.state.lazy_0065";                      label = "hidden_minecart_65";          arity = 2; tags = ["sync"; "lower"; "untyped"]; since = "1.5.2"; weight = 2877 };
  { key = "observer.state.public_0066";                  label = "internal_mob_66";             arity = 3; tags = ["emit"; "experimental"]; since = "1.7.0"; weight = 3817 };
  { key = "shield.state.global_0067";                    label = "modern_hologram_67";          arity = 7; tags = ["content"; "parse"; "emit"]; since = "1.9.0"; weight = 2773 };
  { key = "hopper.state.strict_0068";                    label = "fallback_npc_68";             arity = 2; tags = ["core"; "hot"; "parse"]; since = "1.8.3"; weight = 979 };
  { key = "smithing.state.stable_0069";                  label = "lazy_piston_69";              arity = 3; tags = ["parse"; "runtime"; "cold"]; since = "1.8.3"; weight = 3622 };
  { key = "scoreboard.state.hidden_0070";                label = "strict_campfire_70";          arity = 4; tags = ["check"; "async"; "cached"]; since = "1.4.0"; weight = 786 };
  { key = "advancement.state.modern_0071";               label = "modern_banner_pattern_71";    arity = 3; tags = ["typed"]; since = "1.3.1"; weight = 3277 };
  { key = "biome.state.lazy_0072";                       label = "scoped_tablist_72";           arity = 0; tags = ["sync"; "check"; "emit"]; since = "1.7.0"; weight = 2171 };
  { key = "crossbow.state.fallback_0073";                label = "stable_bell_73";              arity = 7; tags = ["sync"; "emit"; "untyped"]; since = "1.4.0"; weight = 2536 };
  { key = "rail.state.loose_0074";                       label = "scoped_slot_74";              arity = 0; tags = ["registry"; "cached"]; since = "1.6.0"; weight = 843 };
  { key = "elytra.state.legacy_0075";                    label = "legacy_elytra_75";            arity = 5; tags = ["registry"; "core"]; since = "1.0.0"; weight = 17 };
  { key = "clock.state.local_0076";                      label = "secondary_trade_76";          arity = 7; tags = ["cold"; "parse"; "emit"]; since = "1.0.0"; weight = 2440 };
  { key = "barrel.state.primary_0077";                   label = "legacy_smithing_77";          arity = 3; tags = ["compat"]; since = "1.3.1"; weight = 3045 };
  { key = "item.state.modern_0078";                      label = "legacy_shulker_78";           arity = 0; tags = ["typed"; "cold"; "core"]; since = "1.6.0"; weight = 3443 };
  { key = "villager.state.stable_0079";                  label = "primary_particle_79";         arity = 3; tags = ["async"; "registry"; "cold"]; since = "1.6.0"; weight = 30 };
  { key = "hologram.state.global_0080";                  label = "secondary_lectern_80";        arity = 4; tags = ["check"; "emit"; "typed"]; since = "1.5.2"; weight = 1304 };
  { key = "player.state.primary_0081";                   label = "hidden_world_81";             arity = 1; tags = ["parse"]; since = "1.9.0"; weight = 1326 };
  { key = "banner_pattern.state.public_0082";            label = "internal_team_82";            arity = 3; tags = ["hot"; "check"]; since = "1.5.2"; weight = 332 };
  { key = "hologram.state.secondary_0083";               label = "lazy_crossbow_83";            arity = 4; tags = ["hot"]; since = "1.8.3"; weight = 1546 };
  { key = "arrow.state.loose_0084";                      label = "provisional_target_84";       arity = 3; tags = ["hot"]; since = "1.8.3"; weight = 3133 };
  { key = "stonecutter.state.stable_0085";               label = "canonical_rail_85";           arity = 5; tags = ["cached"; "async"]; since = "1.4.0"; weight = 682 };
  { key = "tablist.state.cached_0086";                   label = "secondary_bell_86";           arity = 6; tags = ["cached"; "typed"; "packet"]; since = "1.4.0"; weight = 1721 };
  { key = "barrel.state.canonical_0087";                 label = "lazy_potion_87";              arity = 3; tags = ["sync"; "untyped"]; since = "1.5.2"; weight = 3269 };
  { key = "objective.state.cached_0088";                 label = "global_bell_88";              arity = 6; tags = ["typed"; "legacy"; "runtime"]; since = "1.4.0"; weight = 164 };
  { key = "elytra.state.strict_0089";                    label = "scoped_beacon_89";            arity = 0; tags = ["content"]; since = "1.7.0"; weight = 4050 };
  { key = "bundle.state.scoped_0090";                    label = "strict_entity_90";            arity = 0; tags = ["legacy"; "packet"]; since = "1.4.0"; weight = 522 };
  { key = "loom.state.eager_0091";                       label = "fallback_dropper_91";         arity = 0; tags = ["emit"; "typed"; "untyped"]; since = "1.9.0"; weight = 1531 };
  { key = "stonecutter.state.fallback_0092";             label = "provisional_trident_92";      arity = 0; tags = ["experimental"]; since = "1.0.0"; weight = 2438 };
  { key = "anvil.state.secondary_0093";                  label = "lazy_map_93";                 arity = 6; tags = ["cached"]; since = "1.0.0"; weight = 2233 };
  { key = "target.state.internal_0094";                  label = "derived_structure_94";        arity = 4; tags = ["runtime"]; since = "1.0.0"; weight = 284 };
  { key = "elytra.state.primary_0095";                   label = "legacy_npc_95";               arity = 6; tags = ["typed"; "sync"; "content"]; since = "1.6.0"; weight = 3796 };
  { key = "npc.state.derived_0096";                      label = "derived_potion_96";           arity = 0; tags = ["core"; "cached"]; since = "1.9.0"; weight = 2894 };
  { key = "pane.state.lazy_0097";                        label = "loose_effect_97";             arity = 0; tags = ["registry"]; since = "1.6.0"; weight = 711 };
  { key = "map.state.legacy_0098";                       label = "derived_bundle_98";           arity = 7; tags = ["check"]; since = "1.3.1"; weight = 1161 };
  { key = "crossbow.state.scoped_0099";                  label = "lazy_potion_99";              arity = 3; tags = ["hot"]; since = "1.4.0"; weight = 2896 };
  { key = "campfire.state.stable_0100";                  label = "hidden_repeater_100";         arity = 2; tags = ["typed"; "registry"; "legacy"]; since = "1.3.1"; weight = 3515 };
  { key = "item.state.secondary_0101";                   label = "hidden_pane_101";             arity = 4; tags = ["async"]; since = "1.8.3"; weight = 3139 };
  { key = "world.state.local_0102";                      label = "secondary_sound_102";         arity = 6; tags = ["typed"; "lower"]; since = "1.5.2"; weight = 2353 };
  { key = "campfire.state.stable_0103";                  label = "strict_gui_103";              arity = 4; tags = ["content"; "parse"; "async"]; since = "1.9.0"; weight = 1019 };
  { key = "potion.state.cached_0104";                    label = "derived_block_104";           arity = 2; tags = ["emit"]; since = "1.6.0"; weight = 563 };
  { key = "entity.state.eager_0105";                     label = "derived_trident_105";         arity = 7; tags = ["check"]; since = "1.9.0"; weight = 1544 };
  { key = "conduit.state.fallback_0106";                 label = "global_compass_106";          arity = 0; tags = ["check"; "emit"; "codegen"]; since = "1.4.0"; weight = 2456 };
  { key = "potion.state.fallback_0107";                  label = "scoped_recipe_107";           arity = 0; tags = ["core"]; since = "1.9.0"; weight = 526 };
  { key = "crossbow.state.public_0108";                  label = "legacy_potion_108";           arity = 4; tags = ["cold"; "hot"]; since = "1.9.0"; weight = 630 };
  { key = "portal.state.primary_0109";                   label = "hidden_advancement_109";      arity = 5; tags = ["check"]; since = "1.5.2"; weight = 2495 };
  { key = "shulker.state.canonical_0110";                label = "loose_campfire_110";          arity = 5; tags = ["runtime"; "registry"; "lower"]; since = "1.4.0"; weight = 2973 };
  { key = "map.state.loose_0111";                        label = "stable_potion_111";           arity = 1; tags = ["lower"]; since = "1.2.0"; weight = 1220 };
  { key = "block.state.modern_0112";                     label = "strict_enchant_112";          arity = 1; tags = ["typed"]; since = "1.7.0"; weight = 3244 };
  { key = "advancement.state.stable_0113";               label = "global_beacon_113";           arity = 5; tags = ["packet"; "emit"]; since = "1.7.0"; weight = 606 };
  { key = "shulker.state.eager_0114";                    label = "local_packet_114";            arity = 6; tags = ["legacy"; "untyped"]; since = "1.3.1"; weight = 364 };
  { key = "stonecutter.state.loose_0115";                label = "legacy_beacon_115";           arity = 6; tags = ["experimental"]; since = "1.5.2"; weight = 157 };
  { key = "trident.state.local_0116";                    label = "fallback_brewing_116";        arity = 7; tags = ["hot"]; since = "1.7.0"; weight = 622 };
  { key = "scoreboard.state.legacy_0117";                label = "fallback_smithing_117";       arity = 4; tags = ["content"; "sync"; "untyped"]; since = "1.4.0"; weight = 664 };
  { key = "cartography.state.eager_0118";                label = "primary_target_118";          arity = 0; tags = ["parse"]; since = "1.0.0"; weight = 2023 };
  { key = "mob.state.strict_0119";                       label = "global_bell_119";             arity = 7; tags = ["parse"; "cold"]; since = "1.7.0"; weight = 2069 };
  { key = "scoreboard.state.stable_0120";                label = "stable_attribute_120";        arity = 6; tags = ["cold"; "lower"]; since = "1.8.3"; weight = 1876 };
  { key = "grindstone.state.loose_0121";                 label = "cached_firework_121";         arity = 7; tags = ["legacy"; "compat"; "runtime"]; since = "1.9.0"; weight = 528 };
  { key = "enchant.state.eager_0122";                    label = "hidden_boat_122";             arity = 1; tags = ["cached"; "legacy"; "parse"]; since = "1.8.3"; weight = 3963 };
  { key = "crossbow.state.fallback_0123";                label = "global_shield_123";           arity = 5; tags = ["experimental"]; since = "1.5.2"; weight = 3466 };
  { key = "portal.state.secondary_0124";                 label = "internal_objective_124";      arity = 4; tags = ["core"; "lower"]; since = "1.0.0"; weight = 1201 };
  { key = "lectern.state.canonical_0125";                label = "modern_biome_125";            arity = 3; tags = ["hot"]; since = "1.6.0"; weight = 3441 };
  { key = "clock.state.scoped_0126";                     label = "derived_player_126";          arity = 6; tags = ["core"; "async"; "sync"]; since = "1.7.0"; weight = 2291 };
  { key = "packet.state.strict_0127";                    label = "derived_grindstone_127";      arity = 6; tags = ["codegen"; "hot"]; since = "1.9.0"; weight = 1568 };
  { key = "advancement.state.modern_0128";               label = "fallback_dispenser_128";      arity = 5; tags = ["parse"; "hot"; "codegen"]; since = "1.5.2"; weight = 562 };
  { key = "furnace.state.local_0129";                    label = "fallback_inventory_129";      arity = 1; tags = ["lower"]; since = "1.5.2"; weight = 3593 };
  { key = "shulker.state.cached_0130";                   label = "legacy_observer_130";         arity = 2; tags = ["check"]; since = "1.3.1"; weight = 1969 };
  { key = "banner_pattern.state.global_0131";            label = "loose_region_131";            arity = 6; tags = ["typed"; "registry"; "legacy"]; since = "1.0.0"; weight = 1317 };
  { key = "elytra.state.global_0132";                    label = "local_scoreboard_132";        arity = 0; tags = ["codegen"; "hot"]; since = "1.0.0"; weight = 3718 };
  { key = "banner.state.secondary_0133";                 label = "internal_trade_133";          arity = 3; tags = ["core"]; since = "1.4.0"; weight = 489 };
  { key = "stonecutter.state.provisional_0134";          label = "provisional_potion_134";      arity = 4; tags = ["experimental"; "lower"; "async"]; since = "1.8.3"; weight = 3160 };
  { key = "inventory.state.derived_0135";                label = "local_region_135";            arity = 5; tags = ["async"; "hot"; "cold"]; since = "1.3.1"; weight = 3961 };
  { key = "bundle.state.loose_0136";                     label = "secondary_potion_136";        arity = 1; tags = ["untyped"]; since = "1.5.2"; weight = 3135 };
  { key = "loom.state.strict_0137";                      label = "local_potion_137";            arity = 5; tags = ["runtime"]; since = "1.6.0"; weight = 732 };
  { key = "gui.state.secondary_0138";                    label = "eager_piston_138";            arity = 2; tags = ["parse"; "compat"; "cached"]; since = "1.4.0"; weight = 2156 };
  { key = "recipe.state.internal_0139";                  label = "lazy_packet_139";             arity = 4; tags = ["emit"]; since = "1.6.0"; weight = 3685 };
  { key = "advancement.state.primary_0140";              label = "lazy_portal_140";             arity = 2; tags = ["check"]; since = "1.4.0"; weight = 1056 };
  { key = "block.state.provisional_0141";                label = "cached_map_141";              arity = 4; tags = ["check"; "async"; "untyped"]; since = "1.8.3"; weight = 825 };
  { key = "team.state.eager_0142";                       label = "provisional_npc_142";         arity = 2; tags = ["legacy"; "hot"; "packet"]; since = "1.2.0"; weight = 2124 };
  { key = "npc.state.strict_0143";                       label = "legacy_hologram_143";         arity = 2; tags = ["content"; "hot"]; since = "1.0.0"; weight = 1832 };
  { key = "elytra.state.modern_0144";                    label = "canonical_pane_144";          arity = 2; tags = ["check"; "sync"; "runtime"]; since = "1.3.1"; weight = 1039 };
  { key = "dispenser.state.fallback_0145";               label = "cached_beacon_145";           arity = 1; tags = ["untyped"; "registry"]; since = "1.2.0"; weight = 2805 };
  { key = "crossbow.state.local_0146";                   label = "public_conduit_146";          arity = 6; tags = ["emit"; "codegen"]; since = "1.6.0"; weight = 3750 };
  { key = "pane.state.provisional_0147";                 label = "global_pane_147";             arity = 1; tags = ["emit"]; since = "1.7.0"; weight = 3891 };
  { key = "campfire.state.fallback_0148";                label = "strict_bell_148";             arity = 1; tags = ["cached"; "registry"]; since = "1.0.0"; weight = 1540 };
  { key = "packet.state.derived_0149";                   label = "secondary_clock_149";         arity = 1; tags = ["legacy"]; since = "1.6.0"; weight = 2347 };
  { key = "dropper.state.hidden_0150";                   label = "fallback_repeater_150";       arity = 4; tags = ["core"; "compat"; "legacy"]; since = "1.8.3"; weight = 1250 };
  { key = "attribute.state.loose_0151";                  label = "public_lectern_151";          arity = 5; tags = ["content"]; since = "1.5.2"; weight = 3659 };
  { key = "rail.state.derived_0152";                     label = "cached_npc_152";              arity = 5; tags = ["legacy"; "cached"; "content"]; since = "1.6.0"; weight = 1251 };
  { key = "firework.state.hidden_0153";                  label = "provisional_attribute_153";   arity = 7; tags = ["hot"; "emit"]; since = "1.2.0"; weight = 2357 };
  { key = "minecart.state.loose_0154";                   label = "modern_cartography_154";      arity = 3; tags = ["cached"; "compat"; "untyped"]; since = "1.0.0"; weight = 3747 };
  { key = "lectern.state.secondary_0155";                label = "lazy_boat_155";               arity = 3; tags = ["emit"]; since = "1.3.1"; weight = 818 };
  { key = "crossbow.state.lazy_0156";                    label = "scoped_firework_156";         arity = 0; tags = ["async"]; since = "1.4.0"; weight = 3816 };
  { key = "biome.state.legacy_0157";                     label = "eager_inventory_157";         arity = 1; tags = ["check"; "untyped"]; since = "1.6.0"; weight = 3642 };
  { key = "crossbow.state.primary_0158";                 label = "scoped_dispenser_158";        arity = 5; tags = ["check"; "parse"]; since = "1.2.0"; weight = 1381 };
  { key = "map.state.canonical_0159";                    label = "fallback_smoker_159";         arity = 7; tags = ["typed"; "core"; "cached"]; since = "1.4.0"; weight = 3226 };
  { key = "portal.state.strict_0160";                    label = "local_scoreboard_160";        arity = 2; tags = ["codegen"; "core"]; since = "1.2.0"; weight = 1564 };
  { key = "trade.state.primary_0161";                    label = "strict_clock_161";            arity = 6; tags = ["parse"]; since = "1.9.0"; weight = 1087 };
  { key = "elytra.state.provisional_0162";               label = "local_item_162";              arity = 7; tags = ["codegen"; "hot"]; since = "1.8.3"; weight = 2316 };
  { key = "chunk.state.local_0163";                      label = "lazy_grindstone_163";         arity = 1; tags = ["emit"; "hot"]; since = "1.8.3"; weight = 3320 };
  { key = "dispenser.state.canonical_0164";              label = "public_comparator_164";       arity = 7; tags = ["cached"; "check"]; since = "1.6.0"; weight = 328 };
  { key = "banner_pattern.state.hidden_0165";            label = "scoped_boat_165";             arity = 7; tags = ["compat"; "legacy"]; since = "1.0.0"; weight = 1683 };
  { key = "player.state.lazy_0166";                      label = "secondary_grindstone_166";    arity = 2; tags = ["cached"; "untyped"]; since = "1.8.3"; weight = 1379 };
  { key = "firework.state.eager_0167";                   label = "scoped_player_167";           arity = 3; tags = ["codegen"; "compat"; "async"]; since = "1.5.2"; weight = 3544 };
  { key = "player.state.public_0168";                    label = "internal_smoker_168";         arity = 7; tags = ["sync"]; since = "1.9.0"; weight = 2261 };
  { key = "recipe.state.internal_0169";                  label = "secondary_chunk_169";         arity = 0; tags = ["untyped"]; since = "1.8.3"; weight = 2177 };
  { key = "objective.state.local_0170";                  label = "fallback_campfire_170";       arity = 0; tags = ["compat"; "cold"]; since = "1.7.0"; weight = 1744 };
  { key = "spawner.state.global_0171";                   label = "fallback_particle_171";       arity = 3; tags = ["cached"; "runtime"; "experimental"]; since = "1.3.1"; weight = 122 };
  { key = "smoker.state.fallback_0172";                  label = "cached_chunk_172";            arity = 5; tags = ["typed"; "check"]; since = "1.9.0"; weight = 1255 };
  { key = "beacon.state.fallback_0173";                  label = "internal_trade_173";          arity = 5; tags = ["codegen"; "emit"]; since = "1.6.0"; weight = 4034 };
  { key = "effect.state.strict_0174";                    label = "local_gui_174";               arity = 4; tags = ["compat"; "cached"]; since = "1.5.2"; weight = 922 };
  { key = "objective.state.provisional_0175";            label = "local_effect_175";            arity = 5; tags = ["cold"; "hot"]; since = "1.5.2"; weight = 1119 };
  { key = "minecart.state.global_0176";                  label = "modern_effect_176";           arity = 1; tags = ["hot"; "core"; "experimental"]; since = "1.0.0"; weight = 1870 };
  { key = "hologram.state.eager_0177";                   label = "strict_shulker_177";          arity = 3; tags = ["legacy"; "parse"]; since = "1.0.0"; weight = 403 };
  { key = "arrow.state.legacy_0178";                     label = "stable_spawner_178";          arity = 7; tags = ["check"; "compat"; "core"]; since = "1.9.0"; weight = 723 };
  { key = "stonecutter.state.secondary_0179";            label = "internal_elytra_179";         arity = 6; tags = ["codegen"; "cold"]; since = "1.8.3"; weight = 2681 };
  { key = "crossbow.state.legacy_0180";                  label = "primary_dispenser_180";       arity = 0; tags = ["parse"; "check"]; since = "1.2.0"; weight = 1724 };
  { key = "sound.state.strict_0181";                     label = "primary_loom_181";            arity = 4; tags = ["lower"]; since = "1.4.0"; weight = 647 };
  { key = "team.state.canonical_0182";                   label = "secondary_target_182";        arity = 2; tags = ["typed"]; since = "1.3.1"; weight = 4058 };
  { key = "portal.state.cached_0183";                    label = "provisional_minecart_183";    arity = 5; tags = ["async"; "packet"]; since = "1.9.0"; weight = 2458 };
  { key = "piston.state.strict_0184";                    label = "legacy_tablist_184";          arity = 2; tags = ["emit"]; since = "1.2.0"; weight = 2926 };
  { key = "cartography.state.local_0185";                label = "secondary_bundle_185";        arity = 6; tags = ["compat"]; since = "1.6.0"; weight = 1485 };
  { key = "target.state.internal_0186";                  label = "derived_chunk_186";           arity = 2; tags = ["experimental"; "async"]; since = "1.6.0"; weight = 1335 };
  { key = "rail.state.secondary_0187";                   label = "stable_packet_187";           arity = 3; tags = ["async"]; since = "1.0.0"; weight = 3331 };
  { key = "firework.state.lazy_0188";                    label = "global_pane_188";             arity = 2; tags = ["check"; "legacy"; "experimental"]; since = "1.7.0"; weight = 1618 };
  { key = "boat.state.derived_0189";                     label = "local_trade_189";             arity = 2; tags = ["packet"; "content"; "core"]; since = "1.2.0"; weight = 3997 };
  { key = "barrel.state.canonical_0190";                 label = "legacy_mob_190";              arity = 3; tags = ["runtime"; "registry"; "async"]; since = "1.6.0"; weight = 1932 };
  { key = "entity.state.local_0191";                     label = "public_smoker_191";           arity = 2; tags = ["typed"; "core"]; since = "1.9.0"; weight = 738 };
  { key = "entity.state.primary_0192";                   label = "derived_recipe_192";          arity = 2; tags = ["cached"; "codegen"; "typed"]; since = "1.2.0"; weight = 3910 };
  { key = "clock.state.cached_0193";                     label = "stable_arrow_193";            arity = 7; tags = ["cached"; "async"]; since = "1.9.0"; weight = 1199 };
  { key = "attribute.state.local_0194";                  label = "legacy_cartography_194";      arity = 1; tags = ["registry"; "content"]; since = "1.6.0"; weight = 1071 };
  { key = "smithing.state.modern_0195";                  label = "legacy_campfire_195";         arity = 4; tags = ["emit"; "async"]; since = "1.9.0"; weight = 3497 };
  { key = "clock.state.fallback_0196";                   label = "global_team_196";             arity = 4; tags = ["check"; "runtime"; "experimental"]; since = "1.6.0"; weight = 2348 };
  { key = "cartography.state.loose_0197";                label = "fallback_gui_197";            arity = 1; tags = ["experimental"]; since = "1.9.0"; weight = 1662 };
  { key = "scoreboard.state.cached_0198";                label = "derived_player_198";          arity = 7; tags = ["legacy"; "packet"]; since = "1.0.0"; weight = 13 };
  { key = "grindstone.state.internal_0199";              label = "public_structure_199";        arity = 5; tags = ["lower"; "untyped"; "compat"]; since = "1.8.3"; weight = 318 };
  { key = "structure.state.primary_0200";                label = "legacy_entity_200";           arity = 6; tags = ["packet"; "hot"]; since = "1.7.0"; weight = 3928 };
  { key = "hopper.state.cached_0201";                    label = "public_bossbar_201";          arity = 0; tags = ["experimental"; "content"]; since = "1.7.0"; weight = 3271 };
  { key = "inventory.state.modern_0202";                 label = "hidden_team_202";             arity = 4; tags = ["async"; "registry"]; since = "1.7.0"; weight = 2401 };
  { key = "composter.state.fallback_0203";               label = "stable_minecart_203";         arity = 5; tags = ["content"]; since = "1.5.2"; weight = 2089 };
  { key = "scoreboard.state.modern_0204";                label = "provisional_banner_204";      arity = 1; tags = ["cached"; "cold"; "core"]; since = "1.7.0"; weight = 3892 };
  { key = "enchant.state.scoped_0205";                   label = "canonical_tablist_205";       arity = 3; tags = ["codegen"]; since = "1.4.0"; weight = 1874 };
  { key = "portal.state.stable_0206";                    label = "fallback_enchant_206";        arity = 3; tags = ["codegen"; "untyped"; "async"]; since = "1.5.2"; weight = 1518 };
  { key = "compass.state.fallback_0207";                 label = "loose_chunk_207";             arity = 4; tags = ["legacy"; "hot"; "runtime"]; since = "1.3.1"; weight = 1667 };
  { key = "conduit.state.local_0208";                    label = "primary_piston_208";          arity = 5; tags = ["hot"; "check"]; since = "1.7.0"; weight = 253 };
  { key = "objective.state.loose_0209";                  label = "scoped_portal_209";           arity = 2; tags = ["lower"; "content"]; since = "1.5.2"; weight = 560 };
  { key = "firework.state.cached_0210";                  label = "fallback_clock_210";          arity = 2; tags = ["registry"]; since = "1.4.0"; weight = 730 };
  { key = "bell.state.scoped_0211";                      label = "secondary_npc_211";           arity = 2; tags = ["typed"]; since = "1.8.3"; weight = 2776 };
  { key = "chunk.state.derived_0212";                    label = "eager_effect_212";            arity = 3; tags = ["codegen"; "legacy"]; since = "1.4.0"; weight = 773 };
  { key = "gui.state.derived_0213";                      label = "hidden_slot_213";             arity = 5; tags = ["sync"; "lower"]; since = "1.4.0"; weight = 2642 };
  { key = "elytra.state.stable_0214";                    label = "cached_effect_214";           arity = 4; tags = ["runtime"; "content"]; since = "1.2.0"; weight = 3790 };
  { key = "region.state.legacy_0215";                    label = "loose_world_215";             arity = 0; tags = ["typed"; "content"; "lower"]; since = "1.8.3"; weight = 841 };
  { key = "villager.state.strict_0216";                  label = "secondary_team_216";          arity = 5; tags = ["codegen"]; since = "1.7.0"; weight = 1881 };
  { key = "repeater.state.modern_0217";                  label = "canonical_gui_217";           arity = 1; tags = ["typed"; "untyped"]; since = "1.7.0"; weight = 500 };
  { key = "firework.state.local_0218";                   label = "cached_chunk_218";            arity = 2; tags = ["registry"; "experimental"; "legacy"]; since = "1.8.3"; weight = 597 };
  { key = "chunk.state.lazy_0219";                       label = "strict_conduit_219";          arity = 6; tags = ["async"]; since = "1.7.0"; weight = 1080 };
  { key = "crossbow.state.fallback_0220";                label = "cached_rail_220";             arity = 0; tags = ["packet"; "check"]; since = "1.4.0"; weight = 2705 };
  { key = "tablist.state.provisional_0221";              label = "secondary_piston_221";        arity = 4; tags = ["experimental"; "codegen"; "compat"]; since = "1.4.0"; weight = 859 };
  { key = "elytra.state.canonical_0222";                 label = "legacy_structure_222";        arity = 2; tags = ["experimental"; "sync"; "cold"]; since = "1.2.0"; weight = 745 };
  { key = "shield.state.strict_0223";                    label = "global_campfire_223";         arity = 2; tags = ["untyped"; "cached"]; since = "1.6.0"; weight = 2313 };
  { key = "biome.state.provisional_0224";                label = "global_inventory_224";        arity = 7; tags = ["packet"]; since = "1.8.3"; weight = 2573 };
  { key = "inventory.state.eager_0225";                  label = "fallback_team_225";           arity = 3; tags = ["registry"]; since = "1.3.1"; weight = 2986 };
  { key = "clock.state.public_0226";                     label = "secondary_shield_226";        arity = 1; tags = ["compat"; "codegen"; "legacy"]; since = "1.0.0"; weight = 1118 };
  { key = "attribute.state.global_0227";                 label = "hidden_loom_227";             arity = 6; tags = ["typed"; "async"]; since = "1.7.0"; weight = 1418 };
  { key = "potion.state.fallback_0228";                  label = "eager_target_228";            arity = 6; tags = ["lower"]; since = "1.3.1"; weight = 3757 };
  { key = "banner.state.loose_0229";                     label = "derived_packet_229";          arity = 1; tags = ["parse"; "compat"]; since = "1.0.0"; weight = 2187 };
  { key = "pane.state.internal_0230";                    label = "fallback_pane_230";           arity = 5; tags = ["async"; "untyped"; "sync"]; since = "1.7.0"; weight = 2673 };
  { key = "scoreboard.state.stable_0231";                label = "secondary_cartography_231";   arity = 0; tags = ["experimental"; "cached"; "cold"]; since = "1.5.2"; weight = 2484 };
  { key = "recipe.state.stable_0232";                    label = "secondary_barrel_232";        arity = 3; tags = ["parse"; "core"]; since = "1.0.0"; weight = 3360 };
  { key = "campfire.state.legacy_0233";                  label = "provisional_sound_233";       arity = 6; tags = ["content"; "packet"; "core"]; since = "1.5.2"; weight = 1213 };
  { key = "block.state.provisional_0234";                label = "lazy_rail_234";               arity = 5; tags = ["typed"; "cached"]; since = "1.3.1"; weight = 3097 };
  { key = "dropper.state.secondary_0235";                label = "modern_banner_235";           arity = 7; tags = ["async"]; since = "1.0.0"; weight = 3294 };
  { key = "recipe.state.local_0236";                     label = "local_banner_pattern_236";    arity = 3; tags = ["registry"; "hot"]; since = "1.2.0"; weight = 1564 };
  { key = "enchant.state.internal_0237";                 label = "derived_shield_237";          arity = 7; tags = ["sync"; "runtime"]; since = "1.2.0"; weight = 3164 };
  { key = "trade.state.eager_0238";                      label = "eager_furnace_238";           arity = 0; tags = ["experimental"]; since = "1.5.2"; weight = 892 };
  { key = "banner_pattern.state.legacy_0239";            label = "legacy_biome_239";            arity = 4; tags = ["emit"; "legacy"]; since = "1.7.0"; weight = 59 };
  { key = "boat.state.local_0240";                       label = "modern_structure_240";        arity = 1; tags = ["check"; "async"]; since = "1.0.0"; weight = 2769 };
  { key = "bundle.state.hidden_0241";                    label = "fallback_scoreboard_241";     arity = 0; tags = ["check"; "sync"]; since = "1.7.0"; weight = 3196 };
  { key = "packet.state.secondary_0242";                 label = "global_entity_242";           arity = 0; tags = ["parse"; "sync"; "hot"]; since = "1.4.0"; weight = 1699 };
  { key = "block.state.derived_0243";                    label = "fallback_world_243";          arity = 7; tags = ["cached"]; since = "1.0.0"; weight = 3204 };
  { key = "advancement.state.derived_0244";              label = "secondary_bundle_244";        arity = 3; tags = ["lower"; "cached"; "experimental"]; since = "1.7.0"; weight = 2343 };
  { key = "gui.state.modern_0245";                       label = "canonical_trident_245";       arity = 0; tags = ["cold"; "async"; "experimental"]; since = "1.8.3"; weight = 3069 };
  { key = "conduit.state.provisional_0246";              label = "fallback_trade_246";          arity = 0; tags = ["runtime"]; since = "1.3.1"; weight = 3376 };
  { key = "player.state.cached_0247";                    label = "loose_chunk_247";             arity = 7; tags = ["compat"]; since = "1.3.1"; weight = 3098 };
  { key = "player.state.loose_0248";                     label = "cached_region_248";           arity = 2; tags = ["legacy"; "experimental"; "codegen"]; since = "1.0.0"; weight = 580 };
  { key = "sound.state.provisional_0249";                label = "eager_sound_249";             arity = 4; tags = ["legacy"]; since = "1.5.2"; weight = 3335 };
  { key = "block.state.derived_0250";                    label = "stable_biome_250";            arity = 4; tags = ["codegen"]; since = "1.5.2"; weight = 1812 };
  { key = "compass.state.fallback_0251";                 label = "cached_clock_251";            arity = 7; tags = ["content"; "parse"]; since = "1.8.3"; weight = 3950 };
  { key = "team.state.secondary_0252";                   label = "canonical_repeater_252";      arity = 5; tags = ["core"; "cached"; "sync"]; since = "1.7.0"; weight = 2595 };
  { key = "structure.state.loose_0253";                  label = "global_smoker_253";           arity = 0; tags = ["content"; "runtime"]; since = "1.2.0"; weight = 471 };
  { key = "lectern.state.local_0254";                    label = "loose_campfire_254";          arity = 1; tags = ["codegen"; "lower"]; since = "1.8.3"; weight = 3265 };
  { key = "packet.state.internal_0255";                  label = "loose_boat_255";              arity = 0; tags = ["codegen"; "sync"; "core"]; since = "1.2.0"; weight = 1010 };
  { key = "minecart.state.modern_0256";                  label = "canonical_firework_256";      arity = 2; tags = ["experimental"; "check"; "core"]; since = "1.8.3"; weight = 1482 };
  { key = "potion.state.strict_0257";                    label = "secondary_bundle_257";        arity = 7; tags = ["untyped"; "content"]; since = "1.3.1"; weight = 4015 };
  { key = "effect.state.loose_0258";                     label = "legacy_slot_258";             arity = 7; tags = ["registry"]; since = "1.8.3"; weight = 2547 };
  { key = "repeater.state.provisional_0259";             label = "modern_cartography_259";      arity = 4; tags = ["cached"; "experimental"; "legacy"]; since = "1.3.1"; weight = 865 };
  { key = "dispenser.state.hidden_0260";                 label = "strict_firework_260";         arity = 7; tags = ["experimental"; "compat"]; since = "1.0.0"; weight = 780 };
  { key = "recipe.state.stable_0261";                    label = "cached_campfire_261";         arity = 0; tags = ["async"; "content"]; since = "1.9.0"; weight = 3479 };
  { key = "firework.state.legacy_0262";                  label = "stable_shield_262";           arity = 7; tags = ["cached"; "runtime"; "hot"]; since = "1.2.0"; weight = 3541 };
  { key = "shulker.state.internal_0263";                 label = "legacy_trade_263";            arity = 5; tags = ["cold"; "registry"]; since = "1.4.0"; weight = 2590 };
  { key = "elytra.state.hidden_0264";                    label = "public_beacon_264";           arity = 4; tags = ["emit"; "lower"]; since = "1.3.1"; weight = 3423 };
  { key = "stonecutter.state.derived_0265";              label = "loose_trade_265";             arity = 7; tags = ["async"; "emit"; "parse"]; since = "1.3.1"; weight = 1881 };
  { key = "gui.state.public_0266";                       label = "eager_arrow_266";             arity = 1; tags = ["registry"]; since = "1.8.3"; weight = 2758 };
  { key = "composter.state.strict_0267";                 label = "eager_region_267";            arity = 5; tags = ["typed"; "parse"]; since = "1.6.0"; weight = 3517 };
]

let count = List.length entries

let table : (string, state_entry) Hashtbl.t =
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
