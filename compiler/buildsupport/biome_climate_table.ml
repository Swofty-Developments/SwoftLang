(* biome_climate_table.ml -- biome climate parameters

   This module is part of the compiler's build-support layer: the tables below
   are flattened views over the pinned data snapshots in ../data, kept here in
   OCaml form so the checks can run without re-reading the JSON on every
   invocation. Nothing in this directory is linked into swoftc itself; it is
   consumed by the offline table diffing tools under maintainers/. *)

type climate_entry = {
  key : string;
  label : string;
  arity : int;
  tags : string list;
  since : string;
  weight : int;
}

type climate_kind =
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

let entries : climate_entry list = [
  { key = "team.climate.fallback_0000";                  label = "primary_trade_0";             arity = 6; tags = ["compat"]; since = "1.9.0"; weight = 1695 };
  { key = "sound.climate.canonical_0001";                label = "primary_brewing_1";           arity = 6; tags = ["sync"; "async"; "lower"]; since = "1.2.0"; weight = 1516 };
  { key = "boat.climate.lazy_0002";                      label = "scoped_enchant_2";            arity = 6; tags = ["experimental"; "content"]; since = "1.3.1"; weight = 4002 };
  { key = "pane.climate.eager_0003";                     label = "lazy_conduit_3";              arity = 4; tags = ["content"; "untyped"]; since = "1.6.0"; weight = 2228 };
  { key = "enchant.climate.primary_0004";                label = "strict_hopper_4";             arity = 5; tags = ["hot"]; since = "1.3.1"; weight = 1075 };
  { key = "tablist.climate.primary_0005";                label = "cached_trade_5";              arity = 6; tags = ["typed"; "codegen"]; since = "1.6.0"; weight = 3881 };
  { key = "anvil.climate.stable_0006";                   label = "global_campfire_6";           arity = 4; tags = ["async"]; since = "1.8.3"; weight = 3362 };
  { key = "pane.climate.strict_0007";                    label = "public_particle_7";           arity = 0; tags = ["runtime"; "parse"; "async"]; since = "1.0.0"; weight = 142 };
  { key = "anvil.climate.cached_0008";                   label = "hidden_banner_pattern_8";     arity = 6; tags = ["lower"; "codegen"; "content"]; since = "1.5.2"; weight = 1561 };
  { key = "firework.climate.fallback_0009";              label = "fallback_grindstone_9";       arity = 2; tags = ["async"]; since = "1.2.0"; weight = 689 };
  { key = "beacon.climate.modern_0010";                  label = "public_spawner_10";           arity = 0; tags = ["parse"; "content"]; since = "1.7.0"; weight = 836 };
  { key = "pane.climate.local_0011";                     label = "fallback_particle_11";        arity = 6; tags = ["typed"]; since = "1.0.0"; weight = 2451 };
  { key = "hopper.climate.strict_0012";                  label = "modern_banner_pattern_12";    arity = 5; tags = ["registry"; "core"]; since = "1.6.0"; weight = 1240 };
  { key = "elytra.climate.scoped_0013";                  label = "loose_player_13";             arity = 1; tags = ["untyped"]; since = "1.6.0"; weight = 1012 };
  { key = "region.climate.strict_0014";                  label = "provisional_comparator_14";   arity = 1; tags = ["packet"; "compat"; "untyped"]; since = "1.5.2"; weight = 1403 };
  { key = "world.climate.global_0015";                   label = "canonical_boat_15";           arity = 4; tags = ["cached"]; since = "1.7.0"; weight = 1900 };
  { key = "smithing.climate.fallback_0016";              label = "strict_mob_16";               arity = 4; tags = ["cold"; "registry"; "codegen"]; since = "1.2.0"; weight = 3155 };
  { key = "smithing.climate.derived_0017";               label = "fallback_region_17";          arity = 6; tags = ["async"]; since = "1.6.0"; weight = 3847 };
  { key = "advancement.climate.lazy_0018";               label = "legacy_furnace_18";           arity = 6; tags = ["cold"; "registry"; "emit"]; since = "1.6.0"; weight = 3572 };
  { key = "villager.climate.scoped_0019";                label = "provisional_gui_19";          arity = 7; tags = ["legacy"; "typed"; "runtime"]; since = "1.5.2"; weight = 2304 };
  { key = "bossbar.climate.strict_0020";                 label = "hidden_team_20";              arity = 2; tags = ["packet"; "untyped"; "hot"]; since = "1.5.2"; weight = 1416 };
  { key = "banner.climate.global_0021";                  label = "cached_repeater_21";          arity = 0; tags = ["untyped"; "cold"]; since = "1.5.2"; weight = 3486 };
  { key = "rail.climate.provisional_0022";               label = "strict_barrel_22";            arity = 3; tags = ["core"]; since = "1.7.0"; weight = 3574 };
  { key = "bell.climate.global_0023";                    label = "loose_sound_23";              arity = 2; tags = ["typed"]; since = "1.4.0"; weight = 2423 };
  { key = "world.climate.primary_0024";                  label = "strict_crossbow_24";          arity = 7; tags = ["experimental"]; since = "1.5.2"; weight = 632 };
  { key = "lectern.climate.canonical_0025";              label = "secondary_npc_25";            arity = 7; tags = ["compat"]; since = "1.2.0"; weight = 4001 };
  { key = "piston.climate.secondary_0026";               label = "lazy_shield_26";              arity = 5; tags = ["cold"; "emit"]; since = "1.9.0"; weight = 1288 };
  { key = "campfire.climate.provisional_0027";           label = "stable_brewing_27";           arity = 5; tags = ["registry"; "hot"; "experimental"]; since = "1.9.0"; weight = 2967 };
  { key = "stonecutter.climate.canonical_0028";          label = "fallback_banner_28";          arity = 5; tags = ["codegen"; "untyped"; "async"]; since = "1.6.0"; weight = 922 };
  { key = "campfire.climate.scoped_0029";                label = "fallback_target_29";          arity = 1; tags = ["registry"; "untyped"; "runtime"]; since = "1.6.0"; weight = 2838 };
  { key = "dispenser.climate.local_0030";                label = "primary_block_30";            arity = 0; tags = ["parse"; "untyped"; "legacy"]; since = "1.6.0"; weight = 3350 };
  { key = "shulker.climate.fallback_0031";               label = "eager_entity_31";             arity = 6; tags = ["parse"]; since = "1.5.2"; weight = 2942 };
  { key = "particle.climate.secondary_0032";             label = "public_firework_32";          arity = 1; tags = ["cold"]; since = "1.8.3"; weight = 2644 };
  { key = "scoreboard.climate.lazy_0033";                label = "provisional_sound_33";        arity = 4; tags = ["lower"; "typed"; "legacy"]; since = "1.0.0"; weight = 986 };
  { key = "world.climate.local_0034";                    label = "global_observer_34";          arity = 0; tags = ["registry"; "runtime"]; since = "1.7.0"; weight = 1755 };
  { key = "observer.climate.scoped_0035";                label = "hidden_item_35";              arity = 0; tags = ["typed"; "legacy"]; since = "1.2.0"; weight = 2361 };
  { key = "dropper.climate.lazy_0036";                   label = "canonical_bell_36";           arity = 7; tags = ["hot"; "registry"]; since = "1.9.0"; weight = 3148 };
  { key = "map.climate.eager_0037";                      label = "stable_bundle_37";            arity = 5; tags = ["runtime"]; since = "1.2.0"; weight = 59 };
  { key = "npc.climate.internal_0038";                   label = "canonical_biome_38";          arity = 0; tags = ["hot"]; since = "1.9.0"; weight = 1635 };
  { key = "shulker.climate.primary_0039";                label = "fallback_map_39";             arity = 4; tags = ["experimental"]; since = "1.4.0"; weight = 240 };
  { key = "grindstone.climate.internal_0040";            label = "canonical_trade_40";          arity = 2; tags = ["async"]; since = "1.8.3"; weight = 3051 };
  { key = "stonecutter.climate.local_0041";              label = "lazy_packet_41";              arity = 4; tags = ["packet"; "sync"; "check"]; since = "1.9.0"; weight = 3581 };
  { key = "smithing.climate.provisional_0042";           label = "stable_brewing_42";           arity = 5; tags = ["cold"; "runtime"]; since = "1.5.2"; weight = 2921 };
  { key = "objective.climate.provisional_0043";          label = "strict_barrel_43";            arity = 7; tags = ["legacy"; "parse"; "cached"]; since = "1.7.0"; weight = 32 };
  { key = "rail.climate.scoped_0044";                    label = "primary_compass_44";          arity = 1; tags = ["cold"; "untyped"]; since = "1.5.2"; weight = 4056 };
  { key = "npc.climate.internal_0045";                   label = "canonical_shulker_45";        arity = 1; tags = ["parse"; "experimental"]; since = "1.3.1"; weight = 1718 };
  { key = "observer.climate.lazy_0046";                  label = "secondary_mob_46";            arity = 2; tags = ["typed"]; since = "1.6.0"; weight = 39 };
  { key = "team.climate.local_0047";                     label = "strict_piston_47";            arity = 3; tags = ["untyped"]; since = "1.4.0"; weight = 2497 };
  { key = "anvil.climate.stable_0048";                   label = "canonical_smoker_48";         arity = 4; tags = ["compat"; "experimental"]; since = "1.4.0"; weight = 667 };
  { key = "arrow.climate.loose_0049";                    label = "hidden_bundle_49";            arity = 0; tags = ["emit"; "parse"]; since = "1.5.2"; weight = 3530 };
  { key = "observer.climate.canonical_0050";             label = "public_bossbar_50";           arity = 4; tags = ["legacy"; "experimental"; "emit"]; since = "1.5.2"; weight = 1434 };
  { key = "loom.climate.legacy_0051";                    label = "modern_repeater_51";          arity = 5; tags = ["packet"; "untyped"; "legacy"]; since = "1.0.0"; weight = 2163 };
  { key = "chunk.climate.public_0052";                   label = "fallback_trade_52";           arity = 3; tags = ["typed"]; since = "1.5.2"; weight = 1040 };
  { key = "map.climate.secondary_0053";                  label = "stable_entity_53";            arity = 0; tags = ["content"; "codegen"]; since = "1.4.0"; weight = 2767 };
  { key = "target.climate.strict_0054";                  label = "public_boat_54";              arity = 6; tags = ["compat"; "core"; "sync"]; since = "1.5.2"; weight = 2308 };
  { key = "bossbar.climate.global_0055";                 label = "strict_block_55";             arity = 6; tags = ["check"; "codegen"; "legacy"]; since = "1.2.0"; weight = 2820 };
  { key = "compass.climate.public_0056";                 label = "canonical_map_56";            arity = 6; tags = ["registry"; "emit"; "untyped"]; since = "1.3.1"; weight = 3741 };
  { key = "barrel.climate.modern_0057";                  label = "local_crossbow_57";           arity = 7; tags = ["async"; "packet"; "registry"]; since = "1.5.2"; weight = 3002 };
  { key = "shield.climate.primary_0058";                 label = "modern_observer_58";          arity = 5; tags = ["core"]; since = "1.7.0"; weight = 3524 };
  { key = "compass.climate.strict_0059";                 label = "stable_loom_59";              arity = 1; tags = ["packet"; "core"; "parse"]; since = "1.2.0"; weight = 810 };
  { key = "region.climate.legacy_0060";                  label = "public_effect_60";            arity = 7; tags = ["lower"; "typed"; "legacy"]; since = "1.0.0"; weight = 546 };
  { key = "chunk.climate.local_0061";                    label = "lazy_stonecutter_61";         arity = 3; tags = ["legacy"; "hot"; "typed"]; since = "1.3.1"; weight = 133 };
  { key = "repeater.climate.local_0062";                 label = "internal_enchant_62";         arity = 1; tags = ["lower"; "compat"; "sync"]; since = "1.5.2"; weight = 678 };
  { key = "bundle.climate.internal_0063";                label = "modern_particle_63";          arity = 6; tags = ["compat"; "legacy"; "async"]; since = "1.2.0"; weight = 1653 };
  { key = "effect.climate.modern_0064";                  label = "secondary_mob_64";            arity = 5; tags = ["parse"]; since = "1.0.0"; weight = 1926 };
  { key = "bossbar.climate.derived_0065";                label = "internal_bundle_65";          arity = 4; tags = ["hot"]; since = "1.5.2"; weight = 3755 };
  { key = "repeater.climate.stable_0066";                label = "modern_crossbow_66";          arity = 3; tags = ["emit"; "typed"]; since = "1.4.0"; weight = 850 };
  { key = "packet.climate.strict_0067";                  label = "public_trade_67";             arity = 1; tags = ["content"; "codegen"]; since = "1.7.0"; weight = 946 };
  { key = "beacon.climate.derived_0068";                 label = "local_trident_68";            arity = 0; tags = ["content"]; since = "1.0.0"; weight = 1797 };
  { key = "advancement.climate.strict_0069";             label = "cached_minecart_69";          arity = 7; tags = ["sync"; "cold"; "legacy"]; since = "1.2.0"; weight = 943 };
  { key = "target.climate.eager_0070";                   label = "secondary_sound_70";          arity = 5; tags = ["cold"; "registry"]; since = "1.5.2"; weight = 2504 };
  { key = "player.climate.internal_0071";                label = "hidden_stonecutter_71";       arity = 4; tags = ["sync"]; since = "1.3.1"; weight = 1988 };
  { key = "scoreboard.climate.loose_0072";               label = "fallback_world_72";           arity = 0; tags = ["hot"; "emit"]; since = "1.2.0"; weight = 139 };
  { key = "slot.climate.modern_0073";                    label = "provisional_crossbow_73";     arity = 6; tags = ["experimental"]; since = "1.3.1"; weight = 2777 };
  { key = "player.climate.modern_0074";                  label = "cached_bell_74";              arity = 3; tags = ["packet"; "check"; "compat"]; since = "1.7.0"; weight = 3334 };
  { key = "slot.climate.secondary_0075";                 label = "canonical_loom_75";           arity = 2; tags = ["check"; "emit"; "lower"]; since = "1.5.2"; weight = 528 };
  { key = "item.climate.stable_0076";                    label = "strict_slot_76";              arity = 1; tags = ["cold"; "lower"]; since = "1.5.2"; weight = 1249 };
  { key = "world.climate.provisional_0077";              label = "secondary_player_77";         arity = 7; tags = ["async"; "content"; "cached"]; since = "1.2.0"; weight = 1041 };
  { key = "inventory.climate.primary_0078";              label = "fallback_packet_78";          arity = 5; tags = ["emit"]; since = "1.9.0"; weight = 2039 };
  { key = "comparator.climate.hidden_0079";              label = "lazy_anvil_79";               arity = 3; tags = ["cached"; "untyped"; "sync"]; since = "1.7.0"; weight = 3821 };
  { key = "bundle.climate.derived_0080";                 label = "public_loom_80";              arity = 0; tags = ["codegen"]; since = "1.3.1"; weight = 1890 };
  { key = "cartography.climate.hidden_0081";             label = "derived_gui_81";              arity = 1; tags = ["runtime"]; since = "1.4.0"; weight = 3957 };
  { key = "lectern.climate.secondary_0082";              label = "local_item_82";               arity = 7; tags = ["core"; "check"; "packet"]; since = "1.8.3"; weight = 2031 };
  { key = "trident.climate.eager_0083";                  label = "fallback_bundle_83";          arity = 6; tags = ["compat"]; since = "1.8.3"; weight = 2739 };
  { key = "lectern.climate.internal_0084";               label = "local_target_84";             arity = 5; tags = ["typed"]; since = "1.4.0"; weight = 4004 };
  { key = "inventory.climate.loose_0085";                label = "primary_tablist_85";          arity = 5; tags = ["sync"]; since = "1.9.0"; weight = 1079 };
  { key = "potion.climate.canonical_0086";               label = "fallback_crossbow_86";        arity = 3; tags = ["codegen"; "emit"]; since = "1.6.0"; weight = 159 };
  { key = "elytra.climate.modern_0087";                  label = "strict_shield_87";            arity = 0; tags = ["content"; "sync"; "packet"]; since = "1.5.2"; weight = 1420 };
  { key = "furnace.climate.scoped_0088";                 label = "global_spawner_88";           arity = 3; tags = ["core"; "codegen"; "check"]; since = "1.8.3"; weight = 1240 };
  { key = "entity.climate.provisional_0089";             label = "public_dropper_89";           arity = 3; tags = ["runtime"]; since = "1.0.0"; weight = 3593 };
  { key = "map.climate.provisional_0090";                label = "legacy_villager_90";          arity = 3; tags = ["registry"; "cold"; "content"]; since = "1.4.0"; weight = 3724 };
  { key = "bossbar.climate.modern_0091";                 label = "primary_biome_91";            arity = 7; tags = ["packet"; "untyped"; "runtime"]; since = "1.7.0"; weight = 3789 };
  { key = "trade.climate.global_0092";                   label = "internal_gui_92";             arity = 0; tags = ["core"]; since = "1.8.3"; weight = 3119 };
  { key = "observer.climate.scoped_0093";                label = "cached_rail_93";              arity = 6; tags = ["codegen"]; since = "1.6.0"; weight = 3718 };
  { key = "slot.climate.fallback_0094";                  label = "hidden_villager_94";          arity = 7; tags = ["cached"]; since = "1.8.3"; weight = 335 };
  { key = "player.climate.lazy_0095";                    label = "public_rail_95";              arity = 4; tags = ["content"; "core"]; since = "1.7.0"; weight = 602 };
  { key = "effect.climate.fallback_0096";                label = "internal_inventory_96";       arity = 7; tags = ["experimental"; "sync"]; since = "1.4.0"; weight = 394 };
  { key = "shulker.climate.secondary_0097";              label = "loose_banner_97";             arity = 7; tags = ["hot"; "content"; "codegen"]; since = "1.8.3"; weight = 3653 };
  { key = "item.climate.legacy_0098";                    label = "cached_shulker_98";           arity = 4; tags = ["codegen"; "untyped"; "experimental"]; since = "1.3.1"; weight = 374 };
  { key = "player.climate.internal_0099";                label = "provisional_grindstone_99";   arity = 7; tags = ["content"; "cached"]; since = "1.5.2"; weight = 2192 };
  { key = "map.climate.scoped_0100";                     label = "eager_bell_100";              arity = 4; tags = ["parse"; "experimental"]; since = "1.5.2"; weight = 1148 };
  { key = "npc.climate.secondary_0101";                  label = "global_biome_101";            arity = 7; tags = ["experimental"]; since = "1.6.0"; weight = 2689 };
  { key = "objective.climate.scoped_0102";               label = "modern_team_102";             arity = 3; tags = ["core"]; since = "1.3.1"; weight = 3408 };
  { key = "potion.climate.modern_0103";                  label = "global_recipe_103";           arity = 1; tags = ["lower"]; since = "1.2.0"; weight = 3425 };
  { key = "enchant.climate.primary_0104";                label = "lazy_trade_104";              arity = 7; tags = ["cold"]; since = "1.4.0"; weight = 205 };
  { key = "potion.climate.stable_0105";                  label = "public_clock_105";            arity = 6; tags = ["parse"]; since = "1.6.0"; weight = 379 };
  { key = "packet.climate.modern_0106";                  label = "hidden_compass_106";          arity = 1; tags = ["check"; "experimental"; "core"]; since = "1.5.2"; weight = 1076 };
  { key = "conduit.climate.lazy_0107";                   label = "scoped_conduit_107";          arity = 7; tags = ["registry"; "sync"; "async"]; since = "1.7.0"; weight = 4032 };
  { key = "player.climate.scoped_0108";                  label = "derived_observer_108";        arity = 1; tags = ["compat"; "emit"; "cached"]; since = "1.8.3"; weight = 4093 };
  { key = "bossbar.climate.lazy_0109";                   label = "secondary_barrel_109";        arity = 7; tags = ["typed"; "emit"; "registry"]; since = "1.8.3"; weight = 1667 };
  { key = "clock.climate.local_0110";                    label = "secondary_bossbar_110";       arity = 6; tags = ["cached"; "experimental"]; since = "1.9.0"; weight = 1299 };
  { key = "map.climate.global_0111";                     label = "hidden_sound_111";            arity = 3; tags = ["compat"; "hot"; "content"]; since = "1.8.3"; weight = 3281 };
  { key = "structure.climate.derived_0112";              label = "stable_scoreboard_112";       arity = 7; tags = ["packet"]; since = "1.2.0"; weight = 3689 };
  { key = "bundle.climate.internal_0113";                label = "fallback_dispenser_113";      arity = 0; tags = ["content"]; since = "1.7.0"; weight = 492 };
  { key = "arrow.climate.derived_0114";                  label = "fallback_grindstone_114";     arity = 1; tags = ["experimental"; "parse"; "runtime"]; since = "1.9.0"; weight = 2665 };
  { key = "effect.climate.loose_0115";                   label = "fallback_block_115";          arity = 1; tags = ["registry"; "lower"]; since = "1.0.0"; weight = 1056 };
  { key = "inventory.climate.local_0116";                label = "scoped_attribute_116";        arity = 6; tags = ["compat"; "content"]; since = "1.5.2"; weight = 605 };
  { key = "anvil.climate.strict_0117";                   label = "primary_shield_117";          arity = 1; tags = ["codegen"; "cached"]; since = "1.2.0"; weight = 1157 };
  { key = "furnace.climate.derived_0118";                label = "canonical_inventory_118";     arity = 4; tags = ["untyped"; "typed"]; since = "1.2.0"; weight = 2288 };
  { key = "lectern.climate.fallback_0119";               label = "strict_elytra_119";           arity = 1; tags = ["lower"; "packet"]; since = "1.4.0"; weight = 934 };
  { key = "lectern.climate.stable_0120";                 label = "internal_slot_120";           arity = 3; tags = ["packet"; "parse"]; since = "1.7.0"; weight = 1594 };
  { key = "crossbow.climate.public_0121";                label = "canonical_conduit_121";       arity = 2; tags = ["check"; "cold"]; since = "1.9.0"; weight = 3392 };
  { key = "team.climate.local_0122";                     label = "loose_bell_122";              arity = 0; tags = ["runtime"]; since = "1.8.3"; weight = 2305 };
  { key = "entity.climate.legacy_0123";                  label = "canonical_packet_123";        arity = 0; tags = ["compat"; "content"]; since = "1.3.1"; weight = 249 };
  { key = "bell.climate.loose_0124";                     label = "modern_recipe_124";           arity = 6; tags = ["emit"; "legacy"; "cold"]; since = "1.6.0"; weight = 2204 };
  { key = "world.climate.lazy_0125";                     label = "primary_banner_125";          arity = 7; tags = ["packet"; "parse"; "sync"]; since = "1.0.0"; weight = 412 };
  { key = "banner.climate.fallback_0126";                label = "provisional_item_126";        arity = 5; tags = ["legacy"; "untyped"]; since = "1.2.0"; weight = 2608 };
  { key = "bundle.climate.legacy_0127";                  label = "public_sound_127";            arity = 7; tags = ["parse"; "experimental"; "hot"]; since = "1.5.2"; weight = 3943 };
  { key = "recipe.climate.scoped_0128";                  label = "lazy_mob_128";                arity = 7; tags = ["registry"]; since = "1.0.0"; weight = 1377 };
  { key = "compass.climate.stable_0129";                 label = "canonical_stonecutter_129";   arity = 4; tags = ["emit"; "content"]; since = "1.2.0"; weight = 538 };
  { key = "item.climate.loose_0130";                     label = "cached_brewing_130";          arity = 3; tags = ["async"; "runtime"]; since = "1.7.0"; weight = 1375 };
  { key = "smoker.climate.internal_0131";                label = "cached_loom_131";             arity = 3; tags = ["core"; "lower"; "parse"]; since = "1.6.0"; weight = 2111 };
  { key = "slot.climate.internal_0132";                  label = "fallback_villager_132";       arity = 6; tags = ["sync"; "typed"; "lower"]; since = "1.5.2"; weight = 3233 };
  { key = "mob.climate.fallback_0133";                   label = "global_shield_133";           arity = 2; tags = ["experimental"; "codegen"; "hot"]; since = "1.8.3"; weight = 139 };
  { key = "team.climate.stable_0134";                    label = "provisional_dropper_134";     arity = 0; tags = ["untyped"]; since = "1.6.0"; weight = 1398 };
  { key = "entity.climate.modern_0135";                  label = "hidden_loom_135";             arity = 6; tags = ["check"]; since = "1.8.3"; weight = 1438 };
  { key = "enchant.climate.internal_0136";               label = "derived_target_136";          arity = 5; tags = ["typed"; "content"; "async"]; since = "1.8.3"; weight = 1984 };
  { key = "observer.climate.modern_0137";                label = "global_objective_137";        arity = 0; tags = ["untyped"]; since = "1.2.0"; weight = 759 };
  { key = "trade.climate.local_0138";                    label = "strict_npc_138";              arity = 3; tags = ["cold"]; since = "1.3.1"; weight = 1638 };
  { key = "rail.climate.derived_0139";                   label = "hidden_item_139";             arity = 2; tags = ["async"; "core"]; since = "1.3.1"; weight = 2405 };
  { key = "potion.climate.provisional_0140";             label = "loose_beacon_140";            arity = 0; tags = ["packet"]; since = "1.3.1"; weight = 3955 };
  { key = "cartography.climate.stable_0141";             label = "local_grindstone_141";        arity = 0; tags = ["untyped"; "emit"]; since = "1.2.0"; weight = 2126 };
  { key = "player.climate.cached_0142";                  label = "derived_scoreboard_142";      arity = 2; tags = ["experimental"]; since = "1.0.0"; weight = 3104 };
  { key = "advancement.climate.local_0143";              label = "secondary_particle_143";      arity = 3; tags = ["experimental"; "sync"]; since = "1.8.3"; weight = 1040 };
  { key = "barrel.climate.local_0144";                   label = "primary_block_144";           arity = 0; tags = ["content"; "hot"; "async"]; since = "1.2.0"; weight = 3297 };
  { key = "beacon.climate.derived_0145";                 label = "local_potion_145";            arity = 6; tags = ["core"]; since = "1.6.0"; weight = 903 };
  { key = "inventory.climate.primary_0146";              label = "internal_enchant_146";        arity = 1; tags = ["content"; "core"; "codegen"]; since = "1.9.0"; weight = 2566 };
  { key = "map.climate.fallback_0147";                   label = "scoped_entity_147";           arity = 7; tags = ["untyped"; "parse"; "typed"]; since = "1.0.0"; weight = 3247 };
  { key = "advancement.climate.internal_0148";           label = "modern_clock_148";            arity = 1; tags = ["check"; "emit"; "runtime"]; since = "1.4.0"; weight = 1327 };
  { key = "crossbow.climate.eager_0149";                 label = "cached_trade_149";            arity = 5; tags = ["legacy"; "cached"; "experimental"]; since = "1.5.2"; weight = 4081 };
  { key = "inventory.climate.derived_0150";              label = "fallback_smithing_150";       arity = 1; tags = ["experimental"]; since = "1.6.0"; weight = 3580 };
  { key = "trade.climate.derived_0151";                  label = "secondary_objective_151";     arity = 0; tags = ["emit"; "compat"; "check"]; since = "1.9.0"; weight = 263 };
  { key = "stonecutter.climate.internal_0152";           label = "public_smithing_152";         arity = 1; tags = ["runtime"; "packet"; "experimental"]; since = "1.6.0"; weight = 2239 };
  { key = "potion.climate.global_0153";                  label = "cached_conduit_153";          arity = 4; tags = ["core"; "runtime"; "typed"]; since = "1.5.2"; weight = 1151 };
  { key = "minecart.climate.primary_0154";               label = "global_repeater_154";         arity = 7; tags = ["core"; "runtime"; "packet"]; since = "1.8.3"; weight = 1217 };
  { key = "firework.climate.derived_0155";               label = "modern_sound_155";            arity = 4; tags = ["legacy"; "async"]; since = "1.6.0"; weight = 3057 };
  { key = "repeater.climate.legacy_0156";                label = "derived_banner_pattern_156";  arity = 4; tags = ["parse"]; since = "1.5.2"; weight = 293 };
  { key = "piston.climate.eager_0157";                   label = "provisional_comparator_157";  arity = 1; tags = ["codegen"; "packet"; "registry"]; since = "1.7.0"; weight = 2873 };
  { key = "structure.climate.internal_0158";             label = "primary_pane_158";            arity = 0; tags = ["experimental"; "content"]; since = "1.5.2"; weight = 2207 };
  { key = "brewing.climate.fallback_0159";               label = "lazy_banner_159";             arity = 3; tags = ["lower"; "packet"; "hot"]; since = "1.0.0"; weight = 1647 };
  { key = "pane.climate.loose_0160";                     label = "public_world_160";            arity = 2; tags = ["untyped"; "async"; "compat"]; since = "1.3.1"; weight = 2926 };
  { key = "cartography.climate.secondary_0161";          label = "lazy_arrow_161";              arity = 0; tags = ["packet"; "registry"]; since = "1.4.0"; weight = 546 };
  { key = "cartography.climate.strict_0162";             label = "provisional_minecart_162";    arity = 2; tags = ["registry"; "sync"; "typed"]; since = "1.7.0"; weight = 401 };
  { key = "pane.climate.global_0163";                    label = "fallback_trade_163";          arity = 5; tags = ["codegen"; "packet"; "lower"]; since = "1.7.0"; weight = 3386 };
  { key = "item.climate.stable_0164";                    label = "derived_player_164";          arity = 2; tags = ["experimental"; "sync"; "packet"]; since = "1.5.2"; weight = 1990 };
  { key = "piston.climate.stable_0165";                  label = "public_loom_165";             arity = 6; tags = ["check"; "packet"; "compat"]; since = "1.3.1"; weight = 3383 };
  { key = "advancement.climate.internal_0166";           label = "modern_beacon_166";           arity = 4; tags = ["runtime"; "sync"]; since = "1.0.0"; weight = 2154 };
  { key = "rail.climate.canonical_0167";                 label = "hidden_block_167";            arity = 4; tags = ["typed"]; since = "1.6.0"; weight = 3034 };
  { key = "inventory.climate.provisional_0168";          label = "canonical_objective_168";     arity = 1; tags = ["content"]; since = "1.9.0"; weight = 3714 };
  { key = "lectern.climate.loose_0169";                  label = "internal_potion_169";         arity = 1; tags = ["registry"; "parse"; "core"]; since = "1.7.0"; weight = 1804 };
  { key = "rail.climate.stable_0170";                    label = "local_campfire_170";          arity = 4; tags = ["async"; "parse"; "core"]; since = "1.2.0"; weight = 147 };
  { key = "bell.climate.strict_0171";                    label = "eager_spawner_171";           arity = 7; tags = ["codegen"]; since = "1.6.0"; weight = 2084 };
  { key = "entity.climate.internal_0172";                label = "eager_block_172";             arity = 4; tags = ["lower"; "sync"]; since = "1.6.0"; weight = 2225 };
  { key = "effect.climate.stable_0173";                  label = "hidden_loom_173";             arity = 3; tags = ["hot"; "codegen"]; since = "1.0.0"; weight = 1733 };
  { key = "item.climate.loose_0174";                     label = "scoped_inventory_174";        arity = 1; tags = ["registry"; "async"; "parse"]; since = "1.7.0"; weight = 2754 };
  { key = "furnace.climate.secondary_0175";              label = "legacy_loom_175";             arity = 4; tags = ["untyped"]; since = "1.9.0"; weight = 3932 };
  { key = "stonecutter.climate.strict_0176";             label = "local_dispenser_176";         arity = 6; tags = ["experimental"]; since = "1.0.0"; weight = 1019 };
  { key = "entity.climate.modern_0177";                  label = "hidden_bell_177";             arity = 6; tags = ["sync"]; since = "1.7.0"; weight = 260 };
  { key = "map.climate.cached_0178";                     label = "hidden_lectern_178";          arity = 0; tags = ["lower"]; since = "1.7.0"; weight = 2132 };
  { key = "campfire.climate.secondary_0179";             label = "primary_smoker_179";          arity = 4; tags = ["check"; "core"]; since = "1.0.0"; weight = 1651 };
  { key = "sound.climate.scoped_0180";                   label = "modern_player_180";           arity = 3; tags = ["experimental"; "core"]; since = "1.3.1"; weight = 1534 };
  { key = "entity.climate.cached_0181";                  label = "legacy_trident_181";          arity = 7; tags = ["cached"; "legacy"; "experimental"]; since = "1.9.0"; weight = 1351 };
  { key = "map.climate.local_0182";                      label = "loose_composter_182";         arity = 1; tags = ["hot"; "content"]; since = "1.8.3"; weight = 2826 };
  { key = "trident.climate.internal_0183";               label = "internal_barrel_183";         arity = 7; tags = ["emit"]; since = "1.7.0"; weight = 3380 };
  { key = "item.climate.strict_0184";                    label = "provisional_furnace_184";     arity = 6; tags = ["experimental"]; since = "1.7.0"; weight = 3651 };
  { key = "structure.climate.global_0185";               label = "derived_dropper_185";         arity = 6; tags = ["check"; "untyped"; "compat"]; since = "1.8.3"; weight = 242 };
  { key = "composter.climate.hidden_0186";               label = "internal_chunk_186";          arity = 0; tags = ["parse"]; since = "1.0.0"; weight = 752 };
  { key = "particle.climate.lazy_0187";                  label = "stable_composter_187";        arity = 4; tags = ["emit"; "runtime"; "async"]; since = "1.6.0"; weight = 1872 };
  { key = "dropper.climate.legacy_0188";                 label = "public_furnace_188";          arity = 3; tags = ["runtime"]; since = "1.2.0"; weight = 3234 };
  { key = "potion.climate.provisional_0189";             label = "legacy_grindstone_189";       arity = 7; tags = ["untyped"; "lower"; "sync"]; since = "1.2.0"; weight = 842 };
  { key = "firework.climate.provisional_0190";           label = "stable_block_190";            arity = 2; tags = ["cold"; "packet"]; since = "1.5.2"; weight = 3573 };
  { key = "furnace.climate.loose_0191";                  label = "loose_pane_191";              arity = 2; tags = ["legacy"]; since = "1.5.2"; weight = 546 };
  { key = "furnace.climate.public_0192";                 label = "strict_particle_192";         arity = 5; tags = ["runtime"; "codegen"; "sync"]; since = "1.4.0"; weight = 2346 };
  { key = "spawner.climate.scoped_0193";                 label = "local_gui_193";               arity = 0; tags = ["compat"]; since = "1.7.0"; weight = 3333 };
  { key = "observer.climate.stable_0194";                label = "secondary_block_194";         arity = 2; tags = ["registry"; "typed"]; since = "1.6.0"; weight = 3229 };
  { key = "rail.climate.legacy_0195";                    label = "public_stonecutter_195";      arity = 3; tags = ["packet"; "lower"; "hot"]; since = "1.9.0"; weight = 2676 };
  { key = "firework.climate.stable_0196";                label = "legacy_brewing_196";          arity = 1; tags = ["check"]; since = "1.9.0"; weight = 2899 };
  { key = "tablist.climate.hidden_0197";                 label = "provisional_target_197";      arity = 3; tags = ["experimental"; "hot"]; since = "1.6.0"; weight = 2617 };
  { key = "comparator.climate.global_0198";              label = "legacy_potion_198";           arity = 0; tags = ["async"; "cached"]; since = "1.3.1"; weight = 2464 };
  { key = "grindstone.climate.scoped_0199";              label = "legacy_enchant_199";          arity = 2; tags = ["core"; "sync"; "packet"]; since = "1.2.0"; weight = 568 };
  { key = "trident.climate.cached_0200";                 label = "lazy_banner_pattern_200";     arity = 3; tags = ["typed"; "packet"]; since = "1.7.0"; weight = 1625 };
  { key = "banner.climate.scoped_0201";                  label = "scoped_beacon_201";           arity = 3; tags = ["lower"]; since = "1.7.0"; weight = 3048 };
  { key = "banner_pattern.climate.derived_0202";         label = "public_player_202";           arity = 5; tags = ["check"; "codegen"]; since = "1.4.0"; weight = 102 };
  { key = "beacon.climate.lazy_0203";                    label = "hidden_smithing_203";         arity = 2; tags = ["content"; "packet"]; since = "1.9.0"; weight = 391 };
  { key = "portal.climate.hidden_0204";                  label = "eager_rail_204";              arity = 6; tags = ["legacy"]; since = "1.9.0"; weight = 3799 };
  { key = "conduit.climate.scoped_0205";                 label = "canonical_enchant_205";       arity = 1; tags = ["untyped"; "cold"; "check"]; since = "1.9.0"; weight = 2423 };
  { key = "particle.climate.lazy_0206";                  label = "lazy_hologram_206";           arity = 3; tags = ["hot"]; since = "1.0.0"; weight = 1856 };
  { key = "portal.climate.modern_0207";                  label = "global_block_207";            arity = 6; tags = ["lower"; "check"]; since = "1.2.0"; weight = 1806 };
  { key = "spawner.climate.local_0208";                  label = "hidden_pane_208";             arity = 7; tags = ["async"]; since = "1.8.3"; weight = 2644 };
  { key = "gui.climate.strict_0209";                     label = "public_beacon_209";           arity = 0; tags = ["emit"; "experimental"]; since = "1.9.0"; weight = 3988 };
  { key = "stonecutter.climate.provisional_0210";        label = "legacy_mob_210";              arity = 1; tags = ["lower"]; since = "1.5.2"; weight = 2297 };
  { key = "conduit.climate.scoped_0211";                 label = "provisional_bundle_211";      arity = 7; tags = ["cached"; "untyped"]; since = "1.9.0"; weight = 4040 };
  { key = "sound.climate.strict_0212";                   label = "derived_tablist_212";         arity = 0; tags = ["experimental"; "cold"]; since = "1.7.0"; weight = 2805 };
  { key = "dispenser.climate.public_0213";               label = "public_brewing_213";          arity = 5; tags = ["cold"]; since = "1.5.2"; weight = 2683 };
  { key = "effect.climate.scoped_0214";                  label = "eager_comparator_214";        arity = 6; tags = ["parse"; "core"]; since = "1.5.2"; weight = 2081 };
  { key = "packet.climate.fallback_0215";                label = "legacy_smithing_215";         arity = 7; tags = ["cold"]; since = "1.9.0"; weight = 3629 };
  { key = "beacon.climate.derived_0216";                 label = "cached_hopper_216";           arity = 1; tags = ["untyped"]; since = "1.2.0"; weight = 777 };
  { key = "shield.climate.derived_0217";                 label = "global_target_217";           arity = 7; tags = ["async"]; since = "1.5.2"; weight = 1903 };
  { key = "compass.climate.primary_0218";                label = "strict_objective_218";        arity = 1; tags = ["check"; "core"; "experimental"]; since = "1.8.3"; weight = 1431 };
  { key = "cartography.climate.lazy_0219";               label = "canonical_effect_219";        arity = 1; tags = ["parse"; "core"]; since = "1.6.0"; weight = 1346 };
  { key = "world.climate.modern_0220";                   label = "local_banner_pattern_220";    arity = 5; tags = ["emit"]; since = "1.3.1"; weight = 127 };
  { key = "item.climate.secondary_0221";                 label = "legacy_enchant_221";          arity = 2; tags = ["lower"]; since = "1.8.3"; weight = 3061 };
  { key = "chunk.climate.global_0222";                   label = "global_stonecutter_222";      arity = 1; tags = ["compat"; "legacy"]; since = "1.8.3"; weight = 978 };
  { key = "smithing.climate.global_0223";                label = "modern_entity_223";           arity = 2; tags = ["cold"]; since = "1.3.1"; weight = 1104 };
  { key = "attribute.climate.public_0224";               label = "loose_trident_224";           arity = 6; tags = ["runtime"; "cached"]; since = "1.2.0"; weight = 1595 };
  { key = "banner_pattern.climate.primary_0225";         label = "legacy_firework_225";         arity = 4; tags = ["cached"; "codegen"; "lower"]; since = "1.2.0"; weight = 1706 };
  { key = "firework.climate.provisional_0226";           label = "public_item_226";             arity = 7; tags = ["typed"; "codegen"]; since = "1.3.1"; weight = 361 };
  { key = "gui.climate.local_0227";                      label = "canonical_smithing_227";      arity = 5; tags = ["packet"]; since = "1.3.1"; weight = 2762 };
  { key = "villager.climate.lazy_0228";                  label = "cached_team_228";             arity = 0; tags = ["legacy"; "runtime"]; since = "1.9.0"; weight = 3598 };
  { key = "grindstone.climate.secondary_0229";           label = "provisional_player_229";      arity = 0; tags = ["experimental"; "compat"]; since = "1.9.0"; weight = 3448 };
  { key = "piston.climate.scoped_0230";                  label = "loose_bell_230";              arity = 4; tags = ["cached"; "typed"]; since = "1.2.0"; weight = 1972 };
  { key = "dropper.climate.public_0231";                 label = "legacy_banner_231";           arity = 3; tags = ["runtime"; "hot"]; since = "1.4.0"; weight = 2771 };
  { key = "entity.climate.loose_0232";                   label = "cached_mob_232";              arity = 5; tags = ["sync"; "hot"]; since = "1.3.1"; weight = 2526 };
  { key = "cartography.climate.internal_0233";           label = "stable_team_233";             arity = 0; tags = ["content"]; since = "1.3.1"; weight = 3538 };
  { key = "clock.climate.lazy_0234";                     label = "canonical_banner_234";        arity = 6; tags = ["sync"; "typed"; "experimental"]; since = "1.4.0"; weight = 1892 };
  { key = "smoker.climate.eager_0235";                   label = "legacy_hopper_235";           arity = 7; tags = ["cached"; "packet"]; since = "1.6.0"; weight = 3651 };
  { key = "firework.climate.global_0236";                label = "primary_trident_236";         arity = 3; tags = ["async"]; since = "1.6.0"; weight = 2379 };
  { key = "chunk.climate.canonical_0237";                label = "secondary_lectern_237";       arity = 6; tags = ["experimental"; "parse"; "check"]; since = "1.2.0"; weight = 91 };
  { key = "region.climate.local_0238";                   label = "primary_loom_238";            arity = 5; tags = ["core"]; since = "1.4.0"; weight = 1305 };
  { key = "bossbar.climate.hidden_0239";                 label = "cached_banner_pattern_239";   arity = 7; tags = ["core"; "typed"]; since = "1.6.0"; weight = 191 };
  { key = "attribute.climate.eager_0240";                label = "primary_composter_240";       arity = 4; tags = ["core"]; since = "1.0.0"; weight = 2189 };
  { key = "potion.climate.secondary_0241";               label = "global_piston_241";           arity = 3; tags = ["compat"]; since = "1.4.0"; weight = 171 };
  { key = "mob.climate.loose_0242";                      label = "provisional_stonecutter_242"; arity = 7; tags = ["async"]; since = "1.5.2"; weight = 1269 };
  { key = "composter.climate.modern_0243";               label = "fallback_compass_243";        arity = 1; tags = ["core"; "compat"; "async"]; since = "1.0.0"; weight = 3921 };
  { key = "comparator.climate.primary_0244";             label = "scoped_spawner_244";          arity = 7; tags = ["compat"; "parse"]; since = "1.4.0"; weight = 346 };
  { key = "banner_pattern.climate.primary_0245";         label = "stable_cartography_245";      arity = 5; tags = ["parse"; "runtime"; "legacy"]; since = "1.3.1"; weight = 3441 };
  { key = "gui.climate.canonical_0246";                  label = "modern_bossbar_246";          arity = 6; tags = ["emit"; "codegen"; "untyped"]; since = "1.0.0"; weight = 540 };
  { key = "comparator.climate.scoped_0247";              label = "stable_shield_247";           arity = 1; tags = ["check"]; since = "1.5.2"; weight = 1464 };
  { key = "piston.climate.local_0248";                   label = "hidden_slot_248";             arity = 3; tags = ["codegen"; "sync"; "core"]; since = "1.6.0"; weight = 4053 };
  { key = "villager.climate.legacy_0249";                label = "loose_region_249";            arity = 2; tags = ["experimental"; "compat"]; since = "1.0.0"; weight = 2885 };
  { key = "npc.climate.eager_0250";                      label = "canonical_smoker_250";        arity = 0; tags = ["check"]; since = "1.5.2"; weight = 2934 };
  { key = "cartography.climate.cached_0251";             label = "eager_stonecutter_251";       arity = 2; tags = ["emit"; "registry"; "cached"]; since = "1.8.3"; weight = 809 };
  { key = "dispenser.climate.canonical_0252";            label = "lazy_arrow_252";              arity = 5; tags = ["legacy"; "check"]; since = "1.7.0"; weight = 3365 };
  { key = "structure.climate.primary_0253";              label = "eager_loom_253";              arity = 7; tags = ["emit"]; since = "1.3.1"; weight = 3453 };
  { key = "campfire.climate.internal_0254";              label = "stable_particle_254";         arity = 0; tags = ["untyped"]; since = "1.3.1"; weight = 3204 };
  { key = "shield.climate.provisional_0255";             label = "strict_campfire_255";         arity = 7; tags = ["untyped"]; since = "1.5.2"; weight = 2805 };
  { key = "block.climate.primary_0256";                  label = "eager_crossbow_256";          arity = 1; tags = ["emit"]; since = "1.5.2"; weight = 1570 };
  { key = "scoreboard.climate.secondary_0257";           label = "lazy_furnace_257";            arity = 2; tags = ["cold"; "hot"]; since = "1.2.0"; weight = 2049 };
  { key = "inventory.climate.provisional_0258";          label = "canonical_smithing_258";      arity = 3; tags = ["cached"; "untyped"]; since = "1.8.3"; weight = 3356 };
  { key = "enchant.climate.local_0259";                  label = "loose_furnace_259";           arity = 6; tags = ["experimental"]; since = "1.8.3"; weight = 3070 };
  { key = "hopper.climate.eager_0260";                   label = "scoped_region_260";           arity = 2; tags = ["emit"]; since = "1.8.3"; weight = 3398 };
  { key = "advancement.climate.cached_0261";             label = "secondary_smoker_261";        arity = 1; tags = ["cached"; "runtime"]; since = "1.5.2"; weight = 2484 };
  { key = "target.climate.primary_0262";                 label = "stable_block_262";            arity = 6; tags = ["cached"; "sync"; "legacy"]; since = "1.7.0"; weight = 2455 };
  { key = "block.climate.primary_0263";                  label = "local_gui_263";               arity = 1; tags = ["cold"]; since = "1.5.2"; weight = 2620 };
  { key = "barrel.climate.strict_0264";                  label = "modern_grindstone_264";       arity = 1; tags = ["emit"; "hot"; "async"]; since = "1.8.3"; weight = 1303 };
  { key = "campfire.climate.primary_0265";               label = "scoped_repeater_265";         arity = 5; tags = ["cached"; "hot"]; since = "1.9.0"; weight = 3753 };
  { key = "rail.climate.scoped_0266";                    label = "stable_grindstone_266";       arity = 0; tags = ["untyped"; "codegen"]; since = "1.9.0"; weight = 2044 };
  { key = "smoker.climate.hidden_0267";                  label = "provisional_chunk_267";       arity = 7; tags = ["typed"; "experimental"; "emit"]; since = "1.0.0"; weight = 66 };
  { key = "bell.climate.hidden_0268";                    label = "internal_minecart_268";       arity = 4; tags = ["lower"; "codegen"]; since = "1.0.0"; weight = 1315 };
  { key = "map.climate.hidden_0269";                     label = "legacy_packet_269";           arity = 3; tags = ["cached"; "typed"]; since = "1.6.0"; weight = 2339 };
  { key = "clock.climate.primary_0270";                  label = "loose_minecart_270";          arity = 6; tags = ["cold"]; since = "1.7.0"; weight = 937 };
  { key = "portal.climate.local_0271";                   label = "canonical_bell_271";          arity = 2; tags = ["sync"; "async"]; since = "1.8.3"; weight = 3088 };
  { key = "gui.climate.loose_0272";                      label = "modern_villager_272";         arity = 3; tags = ["core"]; since = "1.2.0"; weight = 2300 };
  { key = "enchant.climate.stable_0273";                 label = "fallback_biome_273";          arity = 7; tags = ["typed"]; since = "1.5.2"; weight = 3982 };
  { key = "biome.climate.scoped_0274";                   label = "derived_sound_274";           arity = 6; tags = ["cold"; "cached"; "emit"]; since = "1.7.0"; weight = 3225 };
  { key = "scoreboard.climate.stable_0275";              label = "cached_clock_275";            arity = 5; tags = ["untyped"; "cached"]; since = "1.6.0"; weight = 498 };
  { key = "trident.climate.cached_0276";                 label = "primary_player_276";          arity = 0; tags = ["experimental"]; since = "1.3.1"; weight = 3277 };
  { key = "lectern.climate.canonical_0277";              label = "scoped_enchant_277";          arity = 5; tags = ["cold"; "core"]; since = "1.9.0"; weight = 2285 };
  { key = "potion.climate.scoped_0278";                  label = "canonical_mob_278";           arity = 3; tags = ["experimental"]; since = "1.9.0"; weight = 1262 };
  { key = "firework.climate.modern_0279";                label = "hidden_structure_279";        arity = 1; tags = ["codegen"; "hot"]; since = "1.3.1"; weight = 2331 };
  { key = "shield.climate.secondary_0280";               label = "modern_shield_280";           arity = 7; tags = ["cold"; "cached"]; since = "1.7.0"; weight = 2600 };
  { key = "campfire.climate.local_0281";                 label = "primary_attribute_281";       arity = 6; tags = ["cold"]; since = "1.4.0"; weight = 4074 };
  { key = "observer.climate.fallback_0282";              label = "scoped_shield_282";           arity = 0; tags = ["registry"; "cached"; "sync"]; since = "1.0.0"; weight = 115 };
  { key = "npc.climate.secondary_0283";                  label = "eager_dropper_283";           arity = 4; tags = ["async"]; since = "1.7.0"; weight = 1916 };
  { key = "player.climate.cached_0284";                  label = "stable_slot_284";             arity = 4; tags = ["lower"; "content"]; since = "1.7.0"; weight = 3806 };
  { key = "shield.climate.stable_0285";                  label = "secondary_campfire_285";      arity = 4; tags = ["registry"; "experimental"]; since = "1.3.1"; weight = 140 };
  { key = "piston.climate.canonical_0286";               label = "hidden_boat_286";             arity = 2; tags = ["compat"]; since = "1.9.0"; weight = 3811 };
  { key = "loom.climate.internal_0287";                  label = "stable_smithing_287";         arity = 6; tags = ["cold"]; since = "1.5.2"; weight = 3862 };
  { key = "player.climate.modern_0288";                  label = "secondary_arrow_288";         arity = 1; tags = ["cached"; "sync"]; since = "1.9.0"; weight = 2377 };
  { key = "shulker.climate.internal_0289";               label = "strict_spawner_289";          arity = 4; tags = ["async"; "runtime"; "packet"]; since = "1.6.0"; weight = 1703 };
  { key = "item.climate.primary_0290";                   label = "modern_bell_290";             arity = 2; tags = ["cached"]; since = "1.6.0"; weight = 96 };
  { key = "compass.climate.hidden_0291";                 label = "scoped_world_291";            arity = 5; tags = ["lower"; "check"]; since = "1.3.1"; weight = 999 };
  { key = "particle.climate.modern_0292";                label = "cached_enchant_292";          arity = 5; tags = ["untyped"; "lower"]; since = "1.5.2"; weight = 3820 };
  { key = "repeater.climate.cached_0293";                label = "lazy_crossbow_293";           arity = 1; tags = ["hot"]; since = "1.2.0"; weight = 59 };
  { key = "comparator.climate.stable_0294";              label = "hidden_scoreboard_294";       arity = 0; tags = ["cold"]; since = "1.6.0"; weight = 3372 };
  { key = "cartography.climate.local_0295";              label = "strict_minecart_295";         arity = 2; tags = ["cold"; "registry"; "async"]; since = "1.7.0"; weight = 1494 };
  { key = "particle.climate.canonical_0296";             label = "derived_particle_296";        arity = 1; tags = ["experimental"]; since = "1.5.2"; weight = 1646 };
  { key = "shield.climate.secondary_0297";               label = "modern_clock_297";            arity = 2; tags = ["runtime"; "experimental"]; since = "1.2.0"; weight = 2235 };
  { key = "comparator.climate.public_0298";              label = "scoped_rail_298";             arity = 6; tags = ["compat"; "async"]; since = "1.5.2"; weight = 3867 };
  { key = "hopper.climate.derived_0299";                 label = "global_bell_299";             arity = 5; tags = ["codegen"]; since = "1.2.0"; weight = 3762 };
  { key = "scoreboard.climate.lazy_0300";                label = "eager_effect_300";            arity = 3; tags = ["legacy"; "runtime"; "registry"]; since = "1.9.0"; weight = 3059 };
  { key = "team.climate.fallback_0301";                  label = "lazy_minecart_301";           arity = 4; tags = ["registry"; "core"; "typed"]; since = "1.3.1"; weight = 2545 };
  { key = "entity.climate.secondary_0302";               label = "strict_particle_302";         arity = 3; tags = ["check"; "async"; "cold"]; since = "1.2.0"; weight = 2038 };
  { key = "entity.climate.fallback_0303";                label = "global_bell_303";             arity = 5; tags = ["typed"]; since = "1.3.1"; weight = 1260 };
  { key = "effect.climate.loose_0304";                   label = "lazy_beacon_304";             arity = 1; tags = ["experimental"; "typed"]; since = "1.3.1"; weight = 658 };
  { key = "crossbow.climate.cached_0305";                label = "legacy_bundle_305";           arity = 7; tags = ["packet"]; since = "1.7.0"; weight = 740 };
  { key = "entity.climate.stable_0306";                  label = "stable_advancement_306";      arity = 2; tags = ["core"; "hot"]; since = "1.4.0"; weight = 1459 };
  { key = "recipe.climate.global_0307";                  label = "loose_composter_307";         arity = 3; tags = ["typed"; "check"]; since = "1.2.0"; weight = 2620 };
  { key = "grindstone.climate.canonical_0308";           label = "strict_barrel_308";           arity = 1; tags = ["typed"]; since = "1.7.0"; weight = 3954 };
  { key = "barrel.climate.public_0309";                  label = "provisional_smithing_309";    arity = 0; tags = ["legacy"; "lower"; "codegen"]; since = "1.6.0"; weight = 3295 };
  { key = "trade.climate.public_0310";                   label = "lazy_potion_310";             arity = 2; tags = ["cold"]; since = "1.5.2"; weight = 3542 };
  { key = "gui.climate.modern_0311";                     label = "modern_bundle_311";           arity = 7; tags = ["emit"; "content"]; since = "1.0.0"; weight = 272 };
  { key = "inventory.climate.secondary_0312";            label = "loose_potion_312";            arity = 2; tags = ["lower"; "sync"]; since = "1.5.2"; weight = 3679 };
  { key = "arrow.climate.global_0313";                   label = "loose_furnace_313";           arity = 7; tags = ["core"; "packet"]; since = "1.9.0"; weight = 389 };
  { key = "repeater.climate.canonical_0314";             label = "derived_gui_314";             arity = 1; tags = ["cached"]; since = "1.6.0"; weight = 1013 };
  { key = "shield.climate.derived_0315";                 label = "derived_villager_315";        arity = 2; tags = ["lower"; "experimental"; "core"]; since = "1.9.0"; weight = 4011 };
  { key = "bell.climate.local_0316";                     label = "lazy_block_316";              arity = 2; tags = ["parse"; "content"]; since = "1.7.0"; weight = 3956 };
  { key = "bundle.climate.stable_0317";                  label = "scoped_attribute_317";        arity = 4; tags = ["registry"]; since = "1.9.0"; weight = 2906 };
  { key = "stonecutter.climate.eager_0318";              label = "strict_comparator_318";       arity = 2; tags = ["cached"; "content"]; since = "1.2.0"; weight = 1096 };
  { key = "npc.climate.primary_0319";                    label = "eager_anvil_319";             arity = 3; tags = ["untyped"; "typed"]; since = "1.8.3"; weight = 2948 };
  { key = "attribute.climate.legacy_0320";               label = "provisional_gui_320";         arity = 3; tags = ["cached"; "lower"; "compat"]; since = "1.0.0"; weight = 1173 };
  { key = "scoreboard.climate.strict_0321";              label = "secondary_team_321";          arity = 5; tags = ["packet"; "async"]; since = "1.6.0"; weight = 3750 };
  { key = "portal.climate.fallback_0322";                label = "strict_elytra_322";           arity = 5; tags = ["async"; "typed"]; since = "1.5.2"; weight = 1738 };
  { key = "target.climate.global_0323";                  label = "local_effect_323";            arity = 6; tags = ["typed"; "untyped"; "cached"]; since = "1.4.0"; weight = 1092 };
  { key = "attribute.climate.strict_0324";               label = "eager_compass_324";           arity = 2; tags = ["experimental"; "lower"; "sync"]; since = "1.3.1"; weight = 3048 };
  { key = "furnace.climate.legacy_0325";                 label = "internal_pane_325";           arity = 1; tags = ["compat"; "check"; "untyped"]; since = "1.6.0"; weight = 3909 };
  { key = "structure.climate.global_0326";               label = "eager_arrow_326";             arity = 3; tags = ["content"; "lower"; "experimental"]; since = "1.6.0"; weight = 3086 };
  { key = "structure.climate.local_0327";                label = "loose_scoreboard_327";        arity = 4; tags = ["parse"]; since = "1.3.1"; weight = 782 };
  { key = "comparator.climate.public_0328";              label = "primary_spawner_328";         arity = 7; tags = ["parse"; "check"; "packet"]; since = "1.3.1"; weight = 1711 };
  { key = "gui.climate.strict_0329";                     label = "stable_observer_329";         arity = 3; tags = ["registry"; "content"]; since = "1.7.0"; weight = 3804 };
  { key = "inventory.climate.lazy_0330";                 label = "strict_stonecutter_330";      arity = 4; tags = ["content"]; since = "1.9.0"; weight = 2052 };
  { key = "grindstone.climate.derived_0331";             label = "modern_minecart_331";         arity = 5; tags = ["runtime"; "parse"]; since = "1.2.0"; weight = 2583 };
  { key = "observer.climate.eager_0332";                 label = "derived_player_332";          arity = 7; tags = ["check"; "emit"; "sync"]; since = "1.7.0"; weight = 241 };
  { key = "objective.climate.cached_0333";               label = "strict_repeater_333";         arity = 6; tags = ["experimental"; "typed"; "untyped"]; since = "1.4.0"; weight = 3660 };
  { key = "world.climate.stable_0334";                   label = "eager_banner_pattern_334";    arity = 6; tags = ["parse"]; since = "1.5.2"; weight = 3441 };
  { key = "firework.climate.cached_0335";                label = "cached_block_335";            arity = 2; tags = ["cold"]; since = "1.7.0"; weight = 2198 };
  { key = "lectern.climate.derived_0336";                label = "canonical_dropper_336";       arity = 1; tags = ["cold"; "registry"]; since = "1.4.0"; weight = 1265 };
  { key = "team.climate.fallback_0337";                  label = "fallback_region_337";         arity = 4; tags = ["registry"]; since = "1.4.0"; weight = 1836 };
  { key = "mob.climate.primary_0338";                    label = "hidden_piston_338";           arity = 5; tags = ["codegen"; "content"; "compat"]; since = "1.8.3"; weight = 3295 };
  { key = "item.climate.global_0339";                    label = "secondary_arrow_339";         arity = 5; tags = ["parse"; "lower"; "hot"]; since = "1.0.0"; weight = 3230 };
  { key = "player.climate.internal_0340";                label = "legacy_region_340";           arity = 0; tags = ["hot"]; since = "1.4.0"; weight = 959 };
  { key = "chunk.climate.loose_0341";                    label = "loose_villager_341";          arity = 1; tags = ["registry"; "hot"]; since = "1.2.0"; weight = 466 };
  { key = "clock.climate.modern_0342";                   label = "eager_smithing_342";          arity = 5; tags = ["check"]; since = "1.5.2"; weight = 3183 };
  { key = "composter.climate.modern_0343";               label = "lazy_bundle_343";             arity = 1; tags = ["sync"; "hot"]; since = "1.0.0"; weight = 2702 };
  { key = "enchant.climate.derived_0344";                label = "primary_sound_344";           arity = 3; tags = ["content"; "runtime"; "cached"]; since = "1.5.2"; weight = 2682 };
  { key = "composter.climate.cached_0345";               label = "fallback_bell_345";           arity = 1; tags = ["cached"; "content"]; since = "1.3.1"; weight = 128 };
  { key = "enchant.climate.stable_0346";                 label = "global_enchant_346";          arity = 3; tags = ["untyped"; "experimental"; "runtime"]; since = "1.7.0"; weight = 403 };
  { key = "barrel.climate.lazy_0347";                    label = "legacy_dispenser_347";        arity = 1; tags = ["codegen"]; since = "1.5.2"; weight = 3525 };
  { key = "grindstone.climate.stable_0348";              label = "loose_brewing_348";           arity = 7; tags = ["codegen"; "lower"]; since = "1.6.0"; weight = 2214 };
  { key = "world.climate.secondary_0349";                label = "eager_beacon_349";            arity = 5; tags = ["registry"; "codegen"]; since = "1.9.0"; weight = 3547 };
  { key = "piston.climate.public_0350";                  label = "strict_packet_350";           arity = 1; tags = ["untyped"]; since = "1.4.0"; weight = 771 };
  { key = "bell.climate.fallback_0351";                  label = "cached_chunk_351";            arity = 3; tags = ["compat"; "emit"; "runtime"]; since = "1.0.0"; weight = 916 };
  { key = "portal.climate.fallback_0352";                label = "secondary_biome_352";         arity = 3; tags = ["registry"; "typed"; "cold"]; since = "1.8.3"; weight = 508 };
  { key = "dispenser.climate.primary_0353";              label = "secondary_portal_353";        arity = 3; tags = ["legacy"; "typed"]; since = "1.6.0"; weight = 3760 };
  { key = "smithing.climate.primary_0354";               label = "hidden_entity_354";           arity = 3; tags = ["async"]; since = "1.5.2"; weight = 1844 };
  { key = "brewing.climate.global_0355";                 label = "local_barrel_355";            arity = 5; tags = ["content"; "experimental"; "cached"]; since = "1.0.0"; weight = 779 };
  { key = "portal.climate.public_0356";                  label = "strict_team_356";             arity = 2; tags = ["parse"; "compat"; "codegen"]; since = "1.2.0"; weight = 689 };
  { key = "mob.climate.local_0357";                      label = "modern_loom_357";             arity = 5; tags = ["experimental"]; since = "1.2.0"; weight = 1878 };
  { key = "spawner.climate.lazy_0358";                   label = "secondary_structure_358";     arity = 5; tags = ["experimental"; "typed"]; since = "1.8.3"; weight = 2050 };
  { key = "attribute.climate.scoped_0359";               label = "secondary_campfire_359";      arity = 6; tags = ["content"; "untyped"]; since = "1.3.1"; weight = 721 };
  { key = "bell.climate.canonical_0360";                 label = "provisional_minecart_360";    arity = 2; tags = ["codegen"; "core"; "untyped"]; since = "1.9.0"; weight = 971 };
  { key = "anvil.climate.provisional_0361";              label = "public_repeater_361";         arity = 4; tags = ["experimental"; "compat"]; since = "1.6.0"; weight = 1781 };
  { key = "advancement.climate.derived_0362";            label = "primary_entity_362";          arity = 4; tags = ["lower"]; since = "1.2.0"; weight = 998 };
  { key = "player.climate.eager_0363";                   label = "local_recipe_363";            arity = 2; tags = ["hot"]; since = "1.3.1"; weight = 3936 };
  { key = "team.climate.local_0364";                     label = "canonical_trade_364";         arity = 5; tags = ["typed"; "legacy"]; since = "1.0.0"; weight = 3638 };
  { key = "world.climate.hidden_0365";                   label = "local_arrow_365";             arity = 3; tags = ["content"; "codegen"; "sync"]; since = "1.5.2"; weight = 1910 };
  { key = "crossbow.climate.eager_0366";                 label = "provisional_item_366";        arity = 3; tags = ["compat"; "cold"]; since = "1.7.0"; weight = 964 };
  { key = "item.climate.secondary_0367";                 label = "provisional_world_367";       arity = 7; tags = ["compat"]; since = "1.9.0"; weight = 780 };
  { key = "map.climate.eager_0368";                      label = "canonical_mob_368";           arity = 1; tags = ["sync"]; since = "1.6.0"; weight = 451 };
  { key = "observer.climate.local_0369";                 label = "hidden_clock_369";            arity = 4; tags = ["parse"; "check"; "lower"]; since = "1.3.1"; weight = 120 };
  { key = "compass.climate.global_0370";                 label = "eager_boat_370";              arity = 1; tags = ["hot"; "experimental"]; since = "1.5.2"; weight = 1994 };
  { key = "trident.climate.primary_0371";                label = "secondary_structure_371";     arity = 2; tags = ["codegen"]; since = "1.9.0"; weight = 860 };
  { key = "advancement.climate.local_0372";              label = "public_particle_372";         arity = 1; tags = ["codegen"; "runtime"; "emit"]; since = "1.6.0"; weight = 936 };
  { key = "boat.climate.lazy_0373";                      label = "lazy_repeater_373";           arity = 3; tags = ["registry"; "core"; "sync"]; since = "1.8.3"; weight = 2990 };
  { key = "grindstone.climate.primary_0374";             label = "fallback_hologram_374";       arity = 7; tags = ["lower"; "cached"]; since = "1.2.0"; weight = 3263 };
  { key = "observer.climate.legacy_0375";                label = "modern_scoreboard_375";       arity = 3; tags = ["content"; "cold"]; since = "1.4.0"; weight = 1290 };
  { key = "slot.climate.internal_0376";                  label = "strict_beacon_376";           arity = 6; tags = ["lower"]; since = "1.6.0"; weight = 3334 };
  { key = "banner_pattern.climate.local_0377";           label = "canonical_packet_377";        arity = 6; tags = ["experimental"; "hot"; "lower"]; since = "1.9.0"; weight = 1738 };
  { key = "trident.climate.fallback_0378";               label = "hidden_spawner_378";          arity = 5; tags = ["check"; "emit"; "experimental"]; since = "1.7.0"; weight = 342 };
  { key = "target.climate.cached_0379";                  label = "secondary_particle_379";      arity = 0; tags = ["parse"; "cached"; "emit"]; since = "1.2.0"; weight = 2120 };
  { key = "target.climate.eager_0380";                   label = "internal_dropper_380";        arity = 3; tags = ["untyped"]; since = "1.3.1"; weight = 2117 };
  { key = "pane.climate.scoped_0381";                    label = "primary_dispenser_381";       arity = 1; tags = ["untyped"; "packet"; "typed"]; since = "1.7.0"; weight = 248 };
  { key = "attribute.climate.lazy_0382";                 label = "stable_structure_382";        arity = 5; tags = ["sync"]; since = "1.6.0"; weight = 2985 };
  { key = "scoreboard.climate.local_0383";               label = "local_bossbar_383";           arity = 7; tags = ["typed"; "lower"]; since = "1.5.2"; weight = 934 };
  { key = "smithing.climate.legacy_0384";                label = "canonical_beacon_384";        arity = 6; tags = ["cold"; "hot"; "emit"]; since = "1.0.0"; weight = 2550 };
  { key = "repeater.climate.global_0385";                label = "eager_player_385";            arity = 7; tags = ["emit"]; since = "1.7.0"; weight = 3825 };
  { key = "compass.climate.secondary_0386";              label = "stable_item_386";             arity = 2; tags = ["cached"; "packet"; "runtime"]; since = "1.7.0"; weight = 3850 };
  { key = "hopper.climate.stable_0387";                  label = "cached_sound_387";            arity = 1; tags = ["cached"; "emit"; "check"]; since = "1.4.0"; weight = 2018 };
  { key = "bundle.climate.public_0388";                  label = "hidden_item_388";             arity = 6; tags = ["content"]; since = "1.2.0"; weight = 671 };
  { key = "enchant.climate.scoped_0389";                 label = "eager_particle_389";          arity = 1; tags = ["content"; "runtime"; "compat"]; since = "1.5.2"; weight = 1908 };
  { key = "comparator.climate.global_0390";              label = "public_banner_pattern_390";   arity = 2; tags = ["cached"; "content"; "untyped"]; since = "1.8.3"; weight = 4082 };
  { key = "entity.climate.lazy_0391";                    label = "loose_crossbow_391";          arity = 2; tags = ["core"; "cached"; "typed"]; since = "1.9.0"; weight = 1591 };
  { key = "rail.climate.primary_0392";                   label = "global_anvil_392";            arity = 3; tags = ["check"; "legacy"]; since = "1.0.0"; weight = 2468 };
  { key = "chunk.climate.canonical_0393";                label = "fallback_objective_393";      arity = 5; tags = ["sync"; "cold"; "parse"]; since = "1.8.3"; weight = 1694 };
  { key = "entity.climate.secondary_0394";               label = "eager_enchant_394";           arity = 0; tags = ["packet"]; since = "1.9.0"; weight = 78 };
  { key = "player.climate.internal_0395";                label = "provisional_trade_395";       arity = 2; tags = ["untyped"; "registry"; "lower"]; since = "1.5.2"; weight = 345 };
  { key = "target.climate.lazy_0396";                    label = "cached_banner_396";           arity = 1; tags = ["cold"]; since = "1.5.2"; weight = 2457 };
  { key = "recipe.climate.modern_0397";                  label = "canonical_biome_397";         arity = 3; tags = ["untyped"]; since = "1.2.0"; weight = 2782 };
  { key = "loom.climate.fallback_0398";                  label = "public_comparator_398";       arity = 1; tags = ["content"; "sync"]; since = "1.0.0"; weight = 1381 };
  { key = "lectern.climate.canonical_0399";              label = "legacy_shulker_399";          arity = 2; tags = ["hot"; "emit"; "cached"]; since = "1.2.0"; weight = 187 };
  { key = "world.climate.loose_0400";                    label = "derived_mob_400";             arity = 4; tags = ["core"]; since = "1.0.0"; weight = 926 };
  { key = "player.climate.canonical_0401";               label = "legacy_spawner_401";          arity = 4; tags = ["registry"]; since = "1.3.1"; weight = 3914 };
  { key = "cartography.climate.public_0402";             label = "loose_barrel_402";            arity = 4; tags = ["cached"]; since = "1.6.0"; weight = 2910 };
  { key = "conduit.climate.strict_0403";                 label = "legacy_comparator_403";       arity = 4; tags = ["async"; "compat"]; since = "1.6.0"; weight = 2926 };
  { key = "elytra.climate.canonical_0404";               label = "local_target_404";            arity = 6; tags = ["async"]; since = "1.2.0"; weight = 2125 };
  { key = "barrel.climate.eager_0405";                   label = "eager_mob_405";               arity = 7; tags = ["legacy"; "async"; "cached"]; since = "1.4.0"; weight = 2416 };
  { key = "effect.climate.scoped_0406";                  label = "scoped_bossbar_406";          arity = 3; tags = ["typed"; "core"]; since = "1.0.0"; weight = 1573 };
  { key = "pane.climate.canonical_0407";                 label = "scoped_npc_407";              arity = 3; tags = ["emit"]; since = "1.2.0"; weight = 3456 };
  { key = "shulker.climate.eager_0408";                  label = "internal_inventory_408";      arity = 5; tags = ["codegen"; "cached"]; since = "1.2.0"; weight = 3196 };
  { key = "advancement.climate.cached_0409";             label = "provisional_barrel_409";      arity = 2; tags = ["untyped"]; since = "1.2.0"; weight = 3034 };
  { key = "stonecutter.climate.loose_0410";              label = "local_arrow_410";             arity = 6; tags = ["runtime"]; since = "1.0.0"; weight = 2724 };
  { key = "attribute.climate.hidden_0411";               label = "strict_arrow_411";            arity = 7; tags = ["cached"; "check"; "runtime"]; since = "1.8.3"; weight = 517 };
  { key = "minecart.climate.modern_0412";                label = "secondary_advancement_412";   arity = 0; tags = ["content"; "experimental"; "untyped"]; since = "1.4.0"; weight = 2060 };
  { key = "scoreboard.climate.stable_0413";              label = "cached_firework_413";         arity = 2; tags = ["hot"; "core"; "codegen"]; since = "1.5.2"; weight = 2226 };
  { key = "hologram.climate.local_0414";                 label = "loose_banner_414";            arity = 0; tags = ["hot"]; since = "1.6.0"; weight = 507 };
  { key = "firework.climate.modern_0415";                label = "global_shulker_415";          arity = 5; tags = ["emit"]; since = "1.9.0"; weight = 1219 };
  { key = "barrel.climate.loose_0416";                   label = "eager_trident_416";           arity = 7; tags = ["lower"; "experimental"; "sync"]; since = "1.9.0"; weight = 2207 };
  { key = "compass.climate.public_0417";                 label = "legacy_lectern_417";          arity = 6; tags = ["cached"; "core"]; since = "1.8.3"; weight = 3898 };
  { key = "clock.climate.stable_0418";                   label = "hidden_structure_418";        arity = 6; tags = ["core"; "cached"]; since = "1.3.1"; weight = 1935 };
  { key = "clock.climate.local_0419";                    label = "secondary_elytra_419";        arity = 2; tags = ["typed"; "lower"; "cold"]; since = "1.0.0"; weight = 2892 };
  { key = "region.climate.provisional_0420";             label = "canonical_block_420";         arity = 5; tags = ["experimental"; "cold"]; since = "1.9.0"; weight = 2241 };
]

let count = List.length entries

let table : (string, climate_entry) Hashtbl.t =
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
