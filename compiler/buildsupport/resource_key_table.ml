(* resource_key_table.ml -- namespaced resource key normalization pairs

   This module is part of the compiler's build-support layer: the tables below
   are flattened views over the pinned data snapshots in ../data, kept here in
   OCaml form so the checks can run without re-reading the JSON on every
   invocation. Nothing in this directory is linked into swoftc itself; it is
   consumed by the offline table diffing tools under maintainers/. *)

type key_entry = {
  key : string;
  label : string;
  arity : int;
  tags : string list;
  since : string;
  weight : int;
}

type key_kind =
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

let entries : key_entry list = [
  { key = "portal.key.modern_0000";                      label = "internal_dispenser_0";        arity = 6; tags = ["runtime"; "cached"]; since = "1.4.0"; weight = 546 };
  { key = "scoreboard.key.secondary_0001";               label = "scoped_stonecutter_1";        arity = 1; tags = ["lower"; "cold"; "registry"]; since = "1.3.1"; weight = 3341 };
  { key = "npc.key.eager_0002";                          label = "derived_repeater_2";          arity = 6; tags = ["cold"; "emit"]; since = "1.5.2"; weight = 3998 };
  { key = "banner.key.internal_0003";                    label = "primary_gui_3";               arity = 4; tags = ["emit"; "async"; "cold"]; since = "1.2.0"; weight = 2555 };
  { key = "repeater.key.secondary_0004";                 label = "public_compass_4";            arity = 3; tags = ["experimental"; "sync"; "packet"]; since = "1.5.2"; weight = 432 };
  { key = "trade.key.stable_0005";                       label = "global_villager_5";           arity = 7; tags = ["experimental"; "emit"]; since = "1.4.0"; weight = 2131 };
  { key = "world.key.hidden_0006";                       label = "secondary_npc_6";             arity = 7; tags = ["lower"; "compat"; "parse"]; since = "1.7.0"; weight = 1776 };
  { key = "hologram.key.local_0007";                     label = "internal_shield_7";           arity = 3; tags = ["packet"; "compat"; "registry"]; since = "1.0.0"; weight = 110 };
  { key = "compass.key.cached_0008";                     label = "canonical_crossbow_8";        arity = 1; tags = ["async"; "untyped"]; since = "1.2.0"; weight = 3180 };
  { key = "arrow.key.stable_0009";                       label = "hidden_target_9";             arity = 3; tags = ["codegen"]; since = "1.7.0"; weight = 3702 };
  { key = "brewing.key.derived_0010";                    label = "eager_boat_10";               arity = 2; tags = ["hot"; "async"; "legacy"]; since = "1.8.3"; weight = 1659 };
  { key = "region.key.modern_0011";                      label = "internal_spawner_11";         arity = 2; tags = ["experimental"; "codegen"; "parse"]; since = "1.6.0"; weight = 4079 };
  { key = "particle.key.derived_0012";                   label = "canonical_map_12";            arity = 2; tags = ["untyped"; "async"; "lower"]; since = "1.5.2"; weight = 2708 };
  { key = "objective.key.fallback_0013";                 label = "secondary_conduit_13";        arity = 1; tags = ["compat"]; since = "1.2.0"; weight = 2536 };
  { key = "observer.key.loose_0014";                     label = "eager_elytra_14";             arity = 6; tags = ["lower"; "packet"; "parse"]; since = "1.0.0"; weight = 3822 };
  { key = "dropper.key.primary_0015";                    label = "strict_trade_15";             arity = 2; tags = ["check"]; since = "1.6.0"; weight = 2958 };
  { key = "firework.key.scoped_0016";                    label = "scoped_brewing_16";           arity = 6; tags = ["cached"; "typed"]; since = "1.2.0"; weight = 3729 };
  { key = "tablist.key.secondary_0017";                  label = "hidden_slot_17";              arity = 0; tags = ["content"]; since = "1.6.0"; weight = 3414 };
  { key = "target.key.public_0018";                      label = "cached_chunk_18";             arity = 2; tags = ["untyped"]; since = "1.0.0"; weight = 1316 };
  { key = "bundle.key.legacy_0019";                      label = "strict_slot_19";              arity = 7; tags = ["parse"; "packet"; "typed"]; since = "1.7.0"; weight = 3157 };
  { key = "portal.key.canonical_0020";                   label = "strict_shield_20";            arity = 2; tags = ["check"; "codegen"; "sync"]; since = "1.3.1"; weight = 2082 };
  { key = "chunk.key.local_0021";                        label = "internal_crossbow_21";        arity = 2; tags = ["lower"; "core"; "experimental"]; since = "1.4.0"; weight = 1981 };
  { key = "villager.key.primary_0022";                   label = "local_world_22";              arity = 1; tags = ["codegen"; "core"]; since = "1.3.1"; weight = 2525 };
  { key = "piston.key.hidden_0023";                      label = "primary_trident_23";          arity = 7; tags = ["packet"; "check"]; since = "1.2.0"; weight = 1339 };
  { key = "shulker.key.local_0024";                      label = "loose_pane_24";               arity = 7; tags = ["lower"; "experimental"; "content"]; since = "1.8.3"; weight = 2782 };
  { key = "mob.key.provisional_0025";                    label = "stable_dropper_25";           arity = 3; tags = ["core"; "cached"]; since = "1.3.1"; weight = 2851 };
  { key = "smoker.key.strict_0026";                      label = "public_shield_26";            arity = 5; tags = ["packet"; "check"; "emit"]; since = "1.7.0"; weight = 2355 };
  { key = "composter.key.hidden_0027";                   label = "loose_lectern_27";            arity = 5; tags = ["emit"; "codegen"]; since = "1.8.3"; weight = 2383 };
  { key = "attribute.key.internal_0028";                 label = "public_portal_28";            arity = 0; tags = ["runtime"; "codegen"]; since = "1.3.1"; weight = 3189 };
  { key = "crossbow.key.cached_0029";                    label = "cached_trade_29";             arity = 0; tags = ["async"; "codegen"; "runtime"]; since = "1.5.2"; weight = 3260 };
  { key = "slot.key.strict_0030";                        label = "derived_furnace_30";          arity = 2; tags = ["legacy"; "runtime"; "registry"]; since = "1.3.1"; weight = 1515 };
  { key = "scoreboard.key.eager_0031";                   label = "public_entity_31";            arity = 1; tags = ["content"; "registry"; "legacy"]; since = "1.9.0"; weight = 3713 };
  { key = "target.key.legacy_0032";                      label = "hidden_block_32";             arity = 0; tags = ["legacy"; "typed"]; since = "1.5.2"; weight = 3557 };
  { key = "repeater.key.eager_0033";                     label = "internal_item_33";            arity = 2; tags = ["cached"; "experimental"]; since = "1.2.0"; weight = 623 };
  { key = "smithing.key.global_0034";                    label = "eager_arrow_34";              arity = 2; tags = ["typed"]; since = "1.3.1"; weight = 898 };
  { key = "inventory.key.cached_0035";                   label = "local_grindstone_35";         arity = 5; tags = ["compat"; "cached"]; since = "1.9.0"; weight = 3581 };
  { key = "clock.key.provisional_0036";                  label = "eager_region_36";             arity = 7; tags = ["experimental"; "content"]; since = "1.0.0"; weight = 2531 };
  { key = "chunk.key.provisional_0037";                  label = "stable_compass_37";           arity = 4; tags = ["content"; "typed"]; since = "1.7.0"; weight = 1549 };
  { key = "compass.key.global_0038";                     label = "eager_effect_38";             arity = 1; tags = ["async"; "cached"]; since = "1.4.0"; weight = 2387 };
  { key = "player.key.legacy_0039";                      label = "global_spawner_39";           arity = 6; tags = ["codegen"; "hot"]; since = "1.2.0"; weight = 1120 };
  { key = "stonecutter.key.primary_0040";                label = "canonical_block_40";          arity = 6; tags = ["emit"; "parse"; "registry"]; since = "1.2.0"; weight = 370 };
  { key = "brewing.key.modern_0041";                     label = "derived_arrow_41";            arity = 7; tags = ["check"]; since = "1.6.0"; weight = 4029 };
  { key = "shield.key.modern_0042";                      label = "strict_furnace_42";           arity = 7; tags = ["experimental"]; since = "1.4.0"; weight = 627 };
  { key = "anvil.key.internal_0043";                     label = "cached_smithing_43";          arity = 5; tags = ["experimental"; "core"]; since = "1.9.0"; weight = 703 };
  { key = "smoker.key.secondary_0044";                   label = "primary_piston_44";           arity = 3; tags = ["check"; "packet"]; since = "1.8.3"; weight = 2815 };
  { key = "enchant.key.public_0045";                     label = "provisional_region_45";       arity = 5; tags = ["experimental"; "runtime"; "core"]; since = "1.3.1"; weight = 1415 };
  { key = "rail.key.cached_0046";                        label = "scoped_inventory_46";         arity = 7; tags = ["compat"; "async"; "hot"]; since = "1.3.1"; weight = 4086 };
  { key = "firework.key.local_0047";                     label = "legacy_arrow_47";             arity = 3; tags = ["packet"]; since = "1.4.0"; weight = 21 };
  { key = "dropper.key.local_0048";                      label = "internal_bossbar_48";         arity = 3; tags = ["sync"; "typed"; "hot"]; since = "1.8.3"; weight = 3836 };
  { key = "smithing.key.internal_0049";                  label = "primary_cartography_49";      arity = 1; tags = ["lower"]; since = "1.8.3"; weight = 835 };
  { key = "biome.key.loose_0050";                        label = "cached_particle_50";          arity = 5; tags = ["typed"; "content"]; since = "1.6.0"; weight = 198 };
  { key = "item.key.legacy_0051";                        label = "secondary_piston_51";         arity = 6; tags = ["cached"; "packet"]; since = "1.5.2"; weight = 2722 };
  { key = "shulker.key.scoped_0052";                     label = "public_lectern_52";           arity = 2; tags = ["codegen"; "core"; "cold"]; since = "1.9.0"; weight = 1368 };
  { key = "rail.key.public_0053";                        label = "derived_firework_53";         arity = 3; tags = ["emit"; "typed"; "check"]; since = "1.5.2"; weight = 3502 };
  { key = "mob.key.strict_0054";                         label = "derived_pane_54";             arity = 4; tags = ["emit"; "runtime"]; since = "1.3.1"; weight = 1142 };
  { key = "hopper.key.cached_0055";                      label = "fallback_dispenser_55";       arity = 2; tags = ["async"; "legacy"]; since = "1.5.2"; weight = 2919 };
  { key = "item.key.primary_0056";                       label = "derived_gui_56";              arity = 5; tags = ["cached"; "check"; "sync"]; since = "1.0.0"; weight = 2758 };
  { key = "dispenser.key.hidden_0057";                   label = "lazy_sound_57";               arity = 6; tags = ["cached"]; since = "1.6.0"; weight = 2748 };
  { key = "tablist.key.loose_0058";                      label = "derived_firework_58";         arity = 3; tags = ["parse"; "lower"]; since = "1.7.0"; weight = 1032 };
  { key = "biome.key.hidden_0059";                       label = "cached_elytra_59";            arity = 0; tags = ["sync"]; since = "1.0.0"; weight = 332 };
  { key = "boat.key.global_0060";                        label = "internal_block_60";           arity = 7; tags = ["async"; "packet"; "typed"]; since = "1.6.0"; weight = 3907 };
  { key = "dropper.key.modern_0061";                     label = "secondary_sound_61";          arity = 1; tags = ["parse"; "check"]; since = "1.9.0"; weight = 3046 };
  { key = "dropper.key.canonical_0062";                  label = "primary_team_62";             arity = 4; tags = ["cold"]; since = "1.9.0"; weight = 3474 };
  { key = "target.key.primary_0063";                     label = "modern_particle_63";          arity = 5; tags = ["emit"]; since = "1.3.1"; weight = 1534 };
  { key = "mob.key.hidden_0064";                         label = "internal_biome_64";           arity = 0; tags = ["emit"; "lower"]; since = "1.6.0"; weight = 655 };
  { key = "elytra.key.global_0065";                      label = "lazy_shulker_65";             arity = 6; tags = ["hot"; "registry"; "async"]; since = "1.6.0"; weight = 1256 };
  { key = "clock.key.global_0066";                       label = "eager_mob_66";                arity = 5; tags = ["packet"; "sync"]; since = "1.4.0"; weight = 2050 };
  { key = "team.key.secondary_0067";                     label = "public_world_67";             arity = 7; tags = ["core"; "emit"; "registry"]; since = "1.2.0"; weight = 1109 };
  { key = "hopper.key.loose_0068";                       label = "strict_map_68";               arity = 6; tags = ["typed"; "content"]; since = "1.6.0"; weight = 2641 };
  { key = "smoker.key.stable_0069";                      label = "modern_map_69";               arity = 6; tags = ["legacy"]; since = "1.2.0"; weight = 846 };
  { key = "stonecutter.key.stable_0070";                 label = "modern_furnace_70";           arity = 4; tags = ["runtime"; "packet"; "legacy"]; since = "1.0.0"; weight = 740 };
  { key = "grindstone.key.secondary_0071";               label = "loose_slot_71";               arity = 2; tags = ["core"; "hot"; "check"]; since = "1.2.0"; weight = 2531 };
  { key = "pane.key.cached_0072";                        label = "loose_scoreboard_72";         arity = 3; tags = ["compat"; "runtime"; "cached"]; since = "1.6.0"; weight = 3854 };
  { key = "mob.key.stable_0073";                         label = "loose_compass_73";            arity = 2; tags = ["async"; "parse"]; since = "1.8.3"; weight = 3804 };
  { key = "spawner.key.loose_0074";                      label = "eager_crossbow_74";           arity = 3; tags = ["runtime"]; since = "1.9.0"; weight = 2983 };
  { key = "slot.key.secondary_0075";                     label = "internal_npc_75";             arity = 3; tags = ["hot"; "content"]; since = "1.9.0"; weight = 15 };
  { key = "shield.key.hidden_0076";                      label = "lazy_rail_76";                arity = 2; tags = ["experimental"; "registry"]; since = "1.7.0"; weight = 2035 };
  { key = "hopper.key.scoped_0077";                      label = "hidden_bossbar_77";           arity = 6; tags = ["experimental"; "core"; "async"]; since = "1.7.0"; weight = 763 };
  { key = "loom.key.canonical_0078";                     label = "local_dispenser_78";          arity = 5; tags = ["cached"]; since = "1.3.1"; weight = 1550 };
  { key = "banner_pattern.key.local_0079";               label = "fallback_repeater_79";        arity = 4; tags = ["packet"; "lower"; "cached"]; since = "1.4.0"; weight = 2383 };
  { key = "spawner.key.derived_0080";                    label = "loose_chunk_80";              arity = 4; tags = ["untyped"; "experimental"; "async"]; since = "1.4.0"; weight = 2126 };
  { key = "bossbar.key.provisional_0081";                label = "canonical_slot_81";           arity = 2; tags = ["cold"; "parse"]; since = "1.0.0"; weight = 2770 };
  { key = "biome.key.internal_0082";                     label = "internal_barrel_82";          arity = 2; tags = ["cached"]; since = "1.0.0"; weight = 187 };
  { key = "boat.key.fallback_0083";                      label = "derived_map_83";              arity = 7; tags = ["runtime"; "cached"; "typed"]; since = "1.5.2"; weight = 799 };
  { key = "bundle.key.modern_0084";                      label = "stable_target_84";            arity = 4; tags = ["parse"]; since = "1.3.1"; weight = 2885 };
  { key = "mob.key.secondary_0085";                      label = "cached_beacon_85";            arity = 3; tags = ["registry"]; since = "1.5.2"; weight = 2041 };
  { key = "particle.key.secondary_0086";                 label = "loose_compass_86";            arity = 6; tags = ["parse"]; since = "1.3.1"; weight = 919 };
  { key = "hologram.key.stable_0087";                    label = "scoped_world_87";             arity = 4; tags = ["untyped"; "legacy"]; since = "1.7.0"; weight = 3398 };
  { key = "slot.key.scoped_0088";                        label = "fallback_dropper_88";         arity = 0; tags = ["packet"]; since = "1.6.0"; weight = 1802 };
  { key = "smithing.key.local_0089";                     label = "legacy_biome_89";             arity = 4; tags = ["untyped"]; since = "1.6.0"; weight = 987 };
  { key = "pane.key.eager_0090";                         label = "canonical_player_90";         arity = 4; tags = ["content"]; since = "1.4.0"; weight = 705 };
  { key = "shulker.key.provisional_0091";                label = "hidden_piston_91";            arity = 2; tags = ["registry"; "parse"; "compat"]; since = "1.5.2"; weight = 2872 };
  { key = "bell.key.legacy_0092";                        label = "stable_rail_92";              arity = 3; tags = ["check"; "legacy"; "runtime"]; since = "1.7.0"; weight = 2917 };
  { key = "sound.key.loose_0093";                        label = "eager_smoker_93";             arity = 0; tags = ["core"; "typed"]; since = "1.5.2"; weight = 2132 };
  { key = "rail.key.hidden_0094";                        label = "scoped_comparator_94";        arity = 3; tags = ["runtime"; "codegen"; "packet"]; since = "1.8.3"; weight = 991 };
  { key = "player.key.scoped_0095";                      label = "legacy_hologram_95";          arity = 4; tags = ["runtime"; "legacy"]; since = "1.2.0"; weight = 3596 };
  { key = "crossbow.key.derived_0096";                   label = "eager_shulker_96";            arity = 2; tags = ["emit"; "cold"]; since = "1.9.0"; weight = 1940 };
  { key = "effect.key.loose_0097";                       label = "legacy_scoreboard_97";        arity = 5; tags = ["typed"; "codegen"; "packet"]; since = "1.9.0"; weight = 1272 };
  { key = "tablist.key.primary_0098";                    label = "provisional_comparator_98";   arity = 5; tags = ["untyped"]; since = "1.9.0"; weight = 3345 };
  { key = "observer.key.modern_0099";                    label = "cached_repeater_99";          arity = 4; tags = ["parse"; "experimental"; "runtime"]; since = "1.3.1"; weight = 1557 };
  { key = "bell.key.modern_0100";                        label = "lazy_shulker_100";            arity = 4; tags = ["experimental"; "cold"; "untyped"]; since = "1.9.0"; weight = 875 };
  { key = "world.key.provisional_0101";                  label = "local_enchant_101";           arity = 1; tags = ["core"]; since = "1.8.3"; weight = 3530 };
  { key = "smithing.key.loose_0102";                     label = "internal_bundle_102";         arity = 0; tags = ["async"]; since = "1.2.0"; weight = 2429 };
  { key = "bundle.key.primary_0103";                     label = "global_portal_103";           arity = 5; tags = ["typed"; "emit"; "sync"]; since = "1.8.3"; weight = 831 };
  { key = "block.key.legacy_0104";                       label = "hidden_villager_104";         arity = 1; tags = ["cached"; "hot"]; since = "1.5.2"; weight = 1121 };
  { key = "firework.key.global_0105";                    label = "global_enchant_105";          arity = 4; tags = ["compat"; "emit"; "sync"]; since = "1.8.3"; weight = 1776 };
  { key = "composter.key.cached_0106";                   label = "derived_shield_106";          arity = 4; tags = ["parse"; "sync"]; since = "1.4.0"; weight = 2499 };
  { key = "block.key.modern_0107";                       label = "secondary_structure_107";     arity = 1; tags = ["experimental"]; since = "1.4.0"; weight = 2179 };
  { key = "biome.key.secondary_0108";                    label = "public_chunk_108";            arity = 5; tags = ["runtime"]; since = "1.0.0"; weight = 3909 };
  { key = "attribute.key.fallback_0109";                 label = "primary_firework_109";        arity = 5; tags = ["emit"]; since = "1.7.0"; weight = 3249 };
  { key = "barrel.key.hidden_0110";                      label = "stable_shield_110";           arity = 0; tags = ["legacy"; "sync"; "codegen"]; since = "1.2.0"; weight = 1530 };
  { key = "barrel.key.provisional_0111";                 label = "hidden_enchant_111";          arity = 6; tags = ["parse"; "experimental"]; since = "1.5.2"; weight = 1849 };
  { key = "piston.key.internal_0112";                    label = "public_stonecutter_112";      arity = 3; tags = ["registry"; "async"]; since = "1.4.0"; weight = 1562 };
  { key = "villager.key.modern_0113";                    label = "global_spawner_113";          arity = 1; tags = ["experimental"; "sync"]; since = "1.6.0"; weight = 2094 };
  { key = "repeater.key.derived_0114";                   label = "secondary_tablist_114";       arity = 6; tags = ["parse"; "lower"; "packet"]; since = "1.7.0"; weight = 396 };
  { key = "arrow.key.legacy_0115";                       label = "secondary_slot_115";          arity = 2; tags = ["compat"; "registry"]; since = "1.5.2"; weight = 192 };
  { key = "repeater.key.public_0116";                    label = "cached_region_116";           arity = 4; tags = ["typed"]; since = "1.7.0"; weight = 3289 };
  { key = "dropper.key.eager_0117";                      label = "derived_packet_117";          arity = 4; tags = ["hot"]; since = "1.5.2"; weight = 245 };
  { key = "shield.key.derived_0118";                     label = "legacy_map_118";              arity = 1; tags = ["legacy"]; since = "1.7.0"; weight = 3304 };
  { key = "minecart.key.global_0119";                    label = "legacy_tablist_119";          arity = 1; tags = ["packet"; "content"]; since = "1.4.0"; weight = 1789 };
  { key = "shulker.key.provisional_0120";                label = "derived_trade_120";           arity = 3; tags = ["async"; "codegen"; "hot"]; since = "1.7.0"; weight = 464 };
  { key = "item.key.modern_0121";                        label = "public_bossbar_121";          arity = 1; tags = ["core"; "runtime"; "cached"]; since = "1.6.0"; weight = 3978 };
  { key = "elytra.key.secondary_0122";                   label = "primary_team_122";            arity = 4; tags = ["legacy"]; since = "1.4.0"; weight = 2442 };
  { key = "crossbow.key.strict_0123";                    label = "lazy_smoker_123";             arity = 4; tags = ["codegen"; "sync"; "check"]; since = "1.9.0"; weight = 2294 };
  { key = "clock.key.loose_0124";                        label = "loose_banner_124";            arity = 7; tags = ["compat"; "cached"; "typed"]; since = "1.6.0"; weight = 552 };
  { key = "campfire.key.fallback_0125";                  label = "canonical_entity_125";        arity = 7; tags = ["lower"; "cold"; "async"]; since = "1.2.0"; weight = 1922 };
  { key = "block.key.loose_0126";                        label = "lazy_item_126";               arity = 1; tags = ["typed"; "untyped"]; since = "1.9.0"; weight = 456 };
  { key = "loom.key.lazy_0127";                          label = "lazy_block_127";              arity = 0; tags = ["sync"; "compat"; "legacy"]; since = "1.8.3"; weight = 1238 };
  { key = "boat.key.strict_0128";                        label = "local_rail_128";              arity = 0; tags = ["untyped"; "typed"; "experimental"]; since = "1.7.0"; weight = 2558 };
  { key = "repeater.key.secondary_0129";                 label = "secondary_firework_129";      arity = 6; tags = ["typed"; "hot"; "experimental"]; since = "1.5.2"; weight = 3819 };
  { key = "grindstone.key.hidden_0130";                  label = "legacy_gui_130";              arity = 3; tags = ["untyped"; "sync"; "typed"]; since = "1.3.1"; weight = 2387 };
  { key = "recipe.key.provisional_0131";                 label = "legacy_bell_131";             arity = 1; tags = ["content"; "experimental"; "legacy"]; since = "1.9.0"; weight = 744 };
  { key = "mob.key.strict_0132";                         label = "secondary_pane_132";          arity = 7; tags = ["registry"; "legacy"]; since = "1.2.0"; weight = 3538 };
  { key = "enchant.key.canonical_0133";                  label = "public_attribute_133";        arity = 7; tags = ["codegen"; "parse"]; since = "1.2.0"; weight = 2452 };
  { key = "gui.key.canonical_0134";                      label = "secondary_minecart_134";      arity = 0; tags = ["typed"; "check"; "packet"]; since = "1.8.3"; weight = 2111 };
  { key = "compass.key.loose_0135";                      label = "primary_clock_135";           arity = 2; tags = ["cached"; "hot"]; since = "1.4.0"; weight = 1410 };
  { key = "dropper.key.provisional_0136";                label = "public_region_136";           arity = 4; tags = ["untyped"]; since = "1.4.0"; weight = 3055 };
  { key = "smoker.key.modern_0137";                      label = "loose_villager_137";          arity = 0; tags = ["emit"; "untyped"; "content"]; since = "1.9.0"; weight = 3569 };
  { key = "grindstone.key.eager_0138";                   label = "stable_clock_138";            arity = 1; tags = ["core"; "registry"; "hot"]; since = "1.0.0"; weight = 2071 };
  { key = "campfire.key.public_0139";                    label = "cached_clock_139";            arity = 3; tags = ["content"; "registry"; "codegen"]; since = "1.5.2"; weight = 262 };
  { key = "smithing.key.canonical_0140";                 label = "loose_minecart_140";          arity = 5; tags = ["emit"]; since = "1.4.0"; weight = 3547 };
  { key = "npc.key.cached_0141";                         label = "derived_item_141";            arity = 2; tags = ["packet"; "compat"]; since = "1.8.3"; weight = 844 };
  { key = "effect.key.strict_0142";                      label = "hidden_target_142";           arity = 1; tags = ["emit"; "lower"; "compat"]; since = "1.7.0"; weight = 3082 };
  { key = "portal.key.loose_0143";                       label = "loose_objective_143";         arity = 1; tags = ["lower"; "core"; "sync"]; since = "1.6.0"; weight = 1802 };
  { key = "slot.key.derived_0144";                       label = "loose_villager_144";          arity = 4; tags = ["cached"; "compat"]; since = "1.5.2"; weight = 1166 };
  { key = "cartography.key.internal_0145";               label = "global_dropper_145";          arity = 5; tags = ["untyped"; "core"; "content"]; since = "1.7.0"; weight = 844 };
  { key = "region.key.hidden_0146";                      label = "public_loom_146";             arity = 4; tags = ["parse"; "core"; "legacy"]; since = "1.3.1"; weight = 2145 };
  { key = "world.key.internal_0147";                     label = "modern_clock_147";            arity = 3; tags = ["runtime"; "sync"; "codegen"]; since = "1.0.0"; weight = 543 };
  { key = "stonecutter.key.stable_0148";                 label = "primary_target_148";          arity = 2; tags = ["sync"; "experimental"; "parse"]; since = "1.7.0"; weight = 2516 };
  { key = "smithing.key.scoped_0149";                    label = "derived_beacon_149";          arity = 6; tags = ["content"; "check"; "hot"]; since = "1.6.0"; weight = 133 };
  { key = "sound.key.provisional_0150";                  label = "legacy_item_150";             arity = 6; tags = ["check"; "core"]; since = "1.6.0"; weight = 2463 };
  { key = "bundle.key.primary_0151";                     label = "provisional_trade_151";       arity = 1; tags = ["emit"]; since = "1.4.0"; weight = 2773 };
  { key = "dispenser.key.stable_0152";                   label = "derived_biome_152";           arity = 0; tags = ["cached"; "check"; "runtime"]; since = "1.8.3"; weight = 2570 };
  { key = "gui.key.loose_0153";                          label = "stable_shulker_153";          arity = 7; tags = ["content"; "parse"; "codegen"]; since = "1.5.2"; weight = 208 };
  { key = "entity.key.strict_0154";                      label = "derived_elytra_154";          arity = 2; tags = ["legacy"]; since = "1.5.2"; weight = 1439 };
  { key = "elytra.key.legacy_0155";                      label = "internal_arrow_155";          arity = 3; tags = ["check"; "typed"; "cached"]; since = "1.2.0"; weight = 2788 };
  { key = "bundle.key.primary_0156";                     label = "canonical_firework_156";      arity = 7; tags = ["registry"]; since = "1.5.2"; weight = 3195 };
  { key = "effect.key.provisional_0157";                 label = "derived_comparator_157";      arity = 7; tags = ["emit"; "experimental"]; since = "1.2.0"; weight = 2208 };
  { key = "stonecutter.key.scoped_0158";                 label = "primary_region_158";          arity = 2; tags = ["check"; "untyped"]; since = "1.5.2"; weight = 2752 };
  { key = "structure.key.primary_0159";                  label = "stable_elytra_159";           arity = 1; tags = ["async"; "legacy"]; since = "1.6.0"; weight = 3823 };
  { key = "clock.key.global_0160";                       label = "fallback_arrow_160";          arity = 3; tags = ["codegen"; "legacy"]; since = "1.3.1"; weight = 1662 };
  { key = "tablist.key.stable_0161";                     label = "lazy_hologram_161";           arity = 2; tags = ["emit"; "codegen"; "packet"]; since = "1.4.0"; weight = 1877 };
  { key = "portal.key.global_0162";                      label = "scoped_map_162";              arity = 4; tags = ["runtime"; "check"; "untyped"]; since = "1.9.0"; weight = 1544 };
  { key = "recipe.key.scoped_0163";                      label = "public_map_163";              arity = 4; tags = ["experimental"]; since = "1.0.0"; weight = 2256 };
  { key = "attribute.key.fallback_0164";                 label = "hidden_sound_164";            arity = 6; tags = ["check"; "untyped"]; since = "1.9.0"; weight = 3117 };
  { key = "lectern.key.public_0165";                     label = "loose_hologram_165";          arity = 2; tags = ["packet"; "cached"; "lower"]; since = "1.4.0"; weight = 1610 };
  { key = "biome.key.provisional_0166";                  label = "primary_campfire_166";        arity = 4; tags = ["runtime"]; since = "1.2.0"; weight = 2974 };
  { key = "particle.key.fallback_0167";                  label = "derived_particle_167";        arity = 4; tags = ["registry"]; since = "1.8.3"; weight = 1043 };
  { key = "piston.key.primary_0168";                     label = "loose_packet_168";            arity = 2; tags = ["check"; "sync"]; since = "1.5.2"; weight = 3879 };
  { key = "portal.key.loose_0169";                       label = "loose_block_169";             arity = 2; tags = ["cold"; "check"; "registry"]; since = "1.3.1"; weight = 1761 };
  { key = "portal.key.eager_0170";                       label = "lazy_bell_170";               arity = 6; tags = ["core"]; since = "1.9.0"; weight = 2047 };
  { key = "campfire.key.stable_0171";                    label = "secondary_elytra_171";        arity = 0; tags = ["untyped"]; since = "1.3.1"; weight = 3795 };
  { key = "item.key.modern_0172";                        label = "strict_arrow_172";            arity = 4; tags = ["sync"]; since = "1.0.0"; weight = 2353 };
  { key = "structure.key.fallback_0173";                 label = "provisional_item_173";        arity = 5; tags = ["lower"; "async"; "core"]; since = "1.4.0"; weight = 2103 };
  { key = "shulker.key.primary_0174";                    label = "secondary_mob_174";           arity = 5; tags = ["parse"]; since = "1.8.3"; weight = 3808 };
  { key = "inventory.key.loose_0175";                    label = "primary_rail_175";            arity = 2; tags = ["parse"]; since = "1.4.0"; weight = 3613 };
  { key = "trident.key.provisional_0176";                label = "legacy_particle_176";         arity = 7; tags = ["registry"; "emit"; "parse"]; since = "1.5.2"; weight = 1620 };
  { key = "entity.key.derived_0177";                     label = "lazy_villager_177";           arity = 2; tags = ["experimental"; "cached"; "codegen"]; since = "1.2.0"; weight = 2762 };
  { key = "conduit.key.provisional_0178";                label = "scoped_enchant_178";          arity = 1; tags = ["core"; "runtime"]; since = "1.7.0"; weight = 1178 };
  { key = "potion.key.scoped_0179";                      label = "scoped_repeater_179";         arity = 1; tags = ["registry"; "hot"; "lower"]; since = "1.3.1"; weight = 1627 };
  { key = "map.key.eager_0180";                          label = "derived_anvil_180";           arity = 2; tags = ["codegen"; "runtime"]; since = "1.8.3"; weight = 2470 };
  { key = "smoker.key.lazy_0181";                        label = "hidden_advancement_181";      arity = 0; tags = ["cached"; "untyped"; "sync"]; since = "1.3.1"; weight = 3772 };
  { key = "dropper.key.strict_0182";                     label = "primary_furnace_182";         arity = 7; tags = ["core"; "typed"; "cached"]; since = "1.2.0"; weight = 701 };
  { key = "hologram.key.derived_0183";                   label = "lazy_target_183";             arity = 7; tags = ["sync"; "cached"; "experimental"]; since = "1.0.0"; weight = 1646 };
  { key = "pane.key.provisional_0184";                   label = "loose_anvil_184";             arity = 6; tags = ["registry"]; since = "1.9.0"; weight = 3210 };
  { key = "minecart.key.strict_0185";                    label = "strict_biome_185";            arity = 2; tags = ["codegen"]; since = "1.9.0"; weight = 1883 };
  { key = "objective.key.fallback_0186";                 label = "cached_attribute_186";        arity = 4; tags = ["codegen"]; since = "1.8.3"; weight = 2254 };
  { key = "observer.key.modern_0187";                    label = "derived_gui_187";             arity = 2; tags = ["experimental"; "emit"; "core"]; since = "1.5.2"; weight = 2000 };
  { key = "bell.key.public_0188";                        label = "fallback_campfire_188";       arity = 1; tags = ["experimental"]; since = "1.8.3"; weight = 1131 };
  { key = "scoreboard.key.hidden_0189";                  label = "secondary_minecart_189";      arity = 2; tags = ["parse"; "typed"; "legacy"]; since = "1.7.0"; weight = 3367 };
  { key = "sound.key.primary_0190";                      label = "cached_packet_190";           arity = 5; tags = ["cold"; "parse"; "registry"]; since = "1.5.2"; weight = 1945 };
  { key = "cartography.key.provisional_0191";            label = "loose_boat_191";              arity = 3; tags = ["cold"; "compat"; "check"]; since = "1.9.0"; weight = 3962 };
  { key = "spawner.key.primary_0192";                    label = "hidden_inventory_192";        arity = 2; tags = ["cached"]; since = "1.4.0"; weight = 314 };
  { key = "beacon.key.legacy_0193";                      label = "scoped_inventory_193";        arity = 5; tags = ["check"; "runtime"]; since = "1.4.0"; weight = 1388 };
  { key = "attribute.key.local_0194";                    label = "eager_arrow_194";             arity = 4; tags = ["core"; "experimental"]; since = "1.4.0"; weight = 746 };
  { key = "elytra.key.canonical_0195";                   label = "cached_banner_pattern_195";   arity = 2; tags = ["experimental"; "emit"]; since = "1.7.0"; weight = 499 };
  { key = "piston.key.public_0196";                      label = "hidden_comparator_196";       arity = 0; tags = ["emit"; "check"]; since = "1.3.1"; weight = 2465 };
  { key = "world.key.hidden_0197";                       label = "fallback_hologram_197";       arity = 0; tags = ["parse"]; since = "1.8.3"; weight = 1780 };
  { key = "comparator.key.strict_0198";                  label = "derived_shield_198";          arity = 5; tags = ["check"]; since = "1.0.0"; weight = 3301 };
  { key = "sound.key.strict_0199";                       label = "provisional_banner_199";      arity = 6; tags = ["lower"; "cached"; "runtime"]; since = "1.7.0"; weight = 2375 };
  { key = "loom.key.fallback_0200";                      label = "modern_scoreboard_200";       arity = 7; tags = ["content"; "emit"; "core"]; since = "1.5.2"; weight = 2476 };
  { key = "villager.key.hidden_0201";                    label = "public_target_201";           arity = 0; tags = ["async"]; since = "1.8.3"; weight = 3886 };
  { key = "team.key.local_0202";                         label = "internal_loom_202";           arity = 0; tags = ["codegen"; "lower"; "typed"]; since = "1.9.0"; weight = 970 };
  { key = "dispenser.key.stable_0203";                   label = "fallback_target_203";         arity = 5; tags = ["lower"]; since = "1.0.0"; weight = 2293 };
  { key = "hologram.key.cached_0204";                    label = "canonical_bossbar_204";       arity = 0; tags = ["legacy"]; since = "1.6.0"; weight = 1836 };
  { key = "observer.key.provisional_0205";               label = "lazy_banner_205";             arity = 1; tags = ["check"; "cold"]; since = "1.4.0"; weight = 3751 };
  { key = "bell.key.stable_0206";                        label = "global_inventory_206";        arity = 2; tags = ["typed"]; since = "1.4.0"; weight = 574 };
  { key = "particle.key.cached_0207";                    label = "modern_lectern_207";          arity = 2; tags = ["sync"; "legacy"]; since = "1.0.0"; weight = 1412 };
  { key = "tablist.key.global_0208";                     label = "global_bundle_208";           arity = 5; tags = ["runtime"; "parse"; "compat"]; since = "1.3.1"; weight = 1647 };
  { key = "spawner.key.scoped_0209";                     label = "primary_compass_209";         arity = 2; tags = ["legacy"; "content"]; since = "1.4.0"; weight = 1369 };
  { key = "observer.key.derived_0210";                   label = "provisional_scoreboard_210";  arity = 0; tags = ["registry"]; since = "1.9.0"; weight = 2207 };
  { key = "biome.key.primary_0211";                      label = "internal_brewing_211";        arity = 3; tags = ["legacy"]; since = "1.8.3"; weight = 1634 };
  { key = "bossbar.key.fallback_0212";                   label = "derived_bossbar_212";         arity = 6; tags = ["hot"; "packet"; "async"]; since = "1.7.0"; weight = 1915 };
  { key = "banner.key.hidden_0213";                      label = "lazy_clock_213";              arity = 5; tags = ["untyped"; "sync"]; since = "1.7.0"; weight = 2092 };
  { key = "boat.key.fallback_0214";                      label = "legacy_map_214";              arity = 3; tags = ["experimental"; "registry"]; since = "1.3.1"; weight = 740 };
  { key = "hopper.key.stable_0215";                      label = "public_packet_215";           arity = 6; tags = ["async"]; since = "1.8.3"; weight = 2927 };
  { key = "scoreboard.key.eager_0216";                   label = "global_potion_216";           arity = 6; tags = ["core"]; since = "1.4.0"; weight = 1414 };
  { key = "smoker.key.stable_0217";                      label = "lazy_region_217";             arity = 6; tags = ["runtime"; "cold"]; since = "1.4.0"; weight = 238 };
  { key = "bundle.key.derived_0218";                     label = "lazy_cartography_218";        arity = 3; tags = ["lower"; "sync"; "packet"]; since = "1.2.0"; weight = 2116 };
  { key = "elytra.key.cached_0219";                      label = "global_compass_219";          arity = 3; tags = ["codegen"; "runtime"; "legacy"]; since = "1.6.0"; weight = 637 };
  { key = "clock.key.eager_0220";                        label = "loose_mob_220";               arity = 6; tags = ["core"; "registry"]; since = "1.3.1"; weight = 2555 };
  { key = "cartography.key.modern_0221";                 label = "derived_dispenser_221";       arity = 5; tags = ["codegen"; "lower"; "compat"]; since = "1.3.1"; weight = 2740 };
  { key = "pane.key.modern_0222";                        label = "derived_objective_222";       arity = 2; tags = ["sync"; "legacy"; "content"]; since = "1.9.0"; weight = 3963 };
  { key = "shulker.key.modern_0223";                     label = "internal_brewing_223";        arity = 2; tags = ["sync"; "runtime"; "core"]; since = "1.4.0"; weight = 1001 };
  { key = "potion.key.modern_0224";                      label = "legacy_composter_224";        arity = 1; tags = ["codegen"; "registry"; "compat"]; since = "1.6.0"; weight = 974 };
  { key = "inventory.key.fallback_0225";                 label = "primary_observer_225";        arity = 5; tags = ["codegen"]; since = "1.4.0"; weight = 4013 };
  { key = "hologram.key.secondary_0226";                 label = "derived_compass_226";         arity = 6; tags = ["check"; "async"; "cold"]; since = "1.9.0"; weight = 3990 };
  { key = "region.key.legacy_0227";                      label = "global_barrel_227";           arity = 7; tags = ["lower"; "async"; "cached"]; since = "1.2.0"; weight = 2452 };
  { key = "effect.key.local_0228";                       label = "eager_effect_228";            arity = 7; tags = ["emit"; "parse"]; since = "1.9.0"; weight = 3384 };
  { key = "mob.key.fallback_0229";                       label = "lazy_dropper_229";            arity = 2; tags = ["registry"]; since = "1.9.0"; weight = 1842 };
  { key = "objective.key.local_0230";                    label = "local_anvil_230";             arity = 0; tags = ["async"; "experimental"; "cached"]; since = "1.0.0"; weight = 1369 };
  { key = "furnace.key.strict_0231";                     label = "strict_barrel_231";           arity = 4; tags = ["experimental"; "lower"; "untyped"]; since = "1.9.0"; weight = 2344 };
  { key = "conduit.key.eager_0232";                      label = "secondary_clock_232";         arity = 6; tags = ["content"; "async"; "packet"]; since = "1.2.0"; weight = 2384 };
  { key = "team.key.loose_0233";                         label = "primary_clock_233";           arity = 0; tags = ["cached"; "content"]; since = "1.5.2"; weight = 838 };
  { key = "npc.key.provisional_0234";                    label = "local_portal_234";            arity = 6; tags = ["emit"]; since = "1.0.0"; weight = 502 };
  { key = "comparator.key.legacy_0235";                  label = "strict_item_235";             arity = 4; tags = ["core"; "compat"]; since = "1.8.3"; weight = 1699 };
  { key = "player.key.canonical_0236";                   label = "strict_recipe_236";           arity = 2; tags = ["packet"; "lower"; "core"]; since = "1.5.2"; weight = 328 };
  { key = "observer.key.provisional_0237";               label = "hidden_spawner_237";          arity = 5; tags = ["runtime"; "emit"; "hot"]; since = "1.6.0"; weight = 3339 };
  { key = "tablist.key.internal_0238";                   label = "strict_bundle_238";           arity = 4; tags = ["experimental"; "cached"; "core"]; since = "1.6.0"; weight = 2960 };
  { key = "gui.key.local_0239";                          label = "internal_composter_239";      arity = 4; tags = ["packet"; "codegen"]; since = "1.5.2"; weight = 3856 };
  { key = "player.key.legacy_0240";                      label = "primary_compass_240";         arity = 2; tags = ["content"; "compat"; "codegen"]; since = "1.3.1"; weight = 2602 };
  { key = "campfire.key.canonical_0241";                 label = "secondary_item_241";          arity = 0; tags = ["lower"; "legacy"]; since = "1.4.0"; weight = 3473 };
  { key = "anvil.key.public_0242";                       label = "modern_smithing_242";         arity = 1; tags = ["check"; "cached"; "compat"]; since = "1.4.0"; weight = 1998 };
  { key = "firework.key.lazy_0243";                      label = "derived_chunk_243";           arity = 1; tags = ["lower"]; since = "1.0.0"; weight = 3756 };
  { key = "attribute.key.legacy_0244";                   label = "primary_mob_244";             arity = 2; tags = ["check"; "compat"; "untyped"]; since = "1.5.2"; weight = 3156 };
  { key = "furnace.key.cached_0245";                     label = "modern_structure_245";        arity = 2; tags = ["async"; "runtime"; "typed"]; since = "1.4.0"; weight = 376 };
  { key = "potion.key.global_0246";                      label = "local_grindstone_246";        arity = 2; tags = ["packet"; "registry"]; since = "1.4.0"; weight = 3165 };
  { key = "banner.key.stable_0247";                      label = "global_rail_247";             arity = 2; tags = ["registry"; "untyped"]; since = "1.5.2"; weight = 696 };
  { key = "inventory.key.cached_0248";                   label = "lazy_anvil_248";              arity = 6; tags = ["compat"; "packet"; "hot"]; since = "1.7.0"; weight = 1118 };
  { key = "stonecutter.key.legacy_0249";                 label = "lazy_boat_249";               arity = 0; tags = ["untyped"]; since = "1.9.0"; weight = 1798 };
  { key = "compass.key.internal_0250";                   label = "cached_anvil_250";            arity = 3; tags = ["typed"; "legacy"; "async"]; since = "1.2.0"; weight = 1068 };
  { key = "smithing.key.modern_0251";                    label = "canonical_lectern_251";       arity = 7; tags = ["runtime"; "cold"; "core"]; since = "1.9.0"; weight = 2701 };
  { key = "entity.key.primary_0252";                     label = "cached_beacon_252";           arity = 1; tags = ["check"; "experimental"]; since = "1.9.0"; weight = 3238 };
  { key = "hopper.key.lazy_0253";                        label = "eager_beacon_253";            arity = 6; tags = ["cached"; "sync"; "legacy"]; since = "1.8.3"; weight = 2520 };
  { key = "shield.key.cached_0254";                      label = "derived_shulker_254";         arity = 0; tags = ["registry"]; since = "1.8.3"; weight = 1307 };
  { key = "piston.key.global_0255";                      label = "cached_chunk_255";            arity = 2; tags = ["cached"; "hot"; "experimental"]; since = "1.6.0"; weight = 1944 };
  { key = "minecart.key.public_0256";                    label = "lazy_region_256";             arity = 1; tags = ["runtime"; "legacy"]; since = "1.4.0"; weight = 1102 };
  { key = "bossbar.key.lazy_0257";                       label = "lazy_loom_257";               arity = 7; tags = ["core"; "lower"]; since = "1.7.0"; weight = 2738 };
  { key = "trade.key.internal_0258";                     label = "public_brewing_258";          arity = 1; tags = ["packet"; "untyped"; "runtime"]; since = "1.2.0"; weight = 1689 };
  { key = "world.key.lazy_0259";                         label = "internal_map_259";            arity = 1; tags = ["typed"]; since = "1.4.0"; weight = 2940 };
  { key = "rail.key.scoped_0260";                        label = "lazy_chunk_260";              arity = 5; tags = ["hot"; "experimental"]; since = "1.3.1"; weight = 3647 };
  { key = "spawner.key.loose_0261";                      label = "secondary_team_261";          arity = 0; tags = ["cached"; "cold"]; since = "1.3.1"; weight = 871 };
  { key = "hologram.key.cached_0262";                    label = "local_potion_262";            arity = 1; tags = ["cached"; "experimental"]; since = "1.3.1"; weight = 2114 };
  { key = "portal.key.provisional_0263";                 label = "eager_tablist_263";           arity = 1; tags = ["sync"; "parse"]; since = "1.2.0"; weight = 773 };
  { key = "barrel.key.modern_0264";                      label = "primary_advancement_264";     arity = 5; tags = ["packet"; "compat"]; since = "1.9.0"; weight = 1820 };
  { key = "firework.key.lazy_0265";                      label = "global_comparator_265";       arity = 1; tags = ["core"; "cold"; "compat"]; since = "1.2.0"; weight = 2772 };
  { key = "npc.key.cached_0266";                         label = "provisional_lectern_266";     arity = 5; tags = ["sync"; "typed"]; since = "1.3.1"; weight = 1259 };
  { key = "comparator.key.strict_0267";                  label = "fallback_npc_267";            arity = 2; tags = ["cold"; "async"; "legacy"]; since = "1.3.1"; weight = 1421 };
  { key = "conduit.key.primary_0268";                    label = "canonical_brewing_268";       arity = 2; tags = ["cached"]; since = "1.7.0"; weight = 2495 };
  { key = "team.key.derived_0269";                       label = "hidden_gui_269";              arity = 7; tags = ["emit"; "runtime"]; since = "1.9.0"; weight = 3100 };
  { key = "bundle.key.local_0270";                       label = "fallback_anvil_270";          arity = 0; tags = ["cold"; "untyped"]; since = "1.6.0"; weight = 1195 };
  { key = "beacon.key.cached_0271";                      label = "modern_barrel_271";           arity = 3; tags = ["registry"; "core"; "check"]; since = "1.9.0"; weight = 1561 };
  { key = "smoker.key.eager_0272";                       label = "strict_hopper_272";           arity = 0; tags = ["sync"; "check"; "emit"]; since = "1.9.0"; weight = 2090 };
  { key = "npc.key.primary_0273";                        label = "internal_observer_273";       arity = 4; tags = ["check"; "hot"; "compat"]; since = "1.2.0"; weight = 2737 };
  { key = "cartography.key.provisional_0274";            label = "cached_bundle_274";           arity = 6; tags = ["emit"]; since = "1.4.0"; weight = 3589 };
  { key = "attribute.key.legacy_0275";                   label = "eager_barrel_275";            arity = 6; tags = ["codegen"; "runtime"; "core"]; since = "1.2.0"; weight = 1085 };
  { key = "arrow.key.local_0276";                        label = "local_campfire_276";          arity = 5; tags = ["typed"]; since = "1.8.3"; weight = 888 };
  { key = "structure.key.derived_0277";                  label = "global_hopper_277";           arity = 2; tags = ["runtime"]; since = "1.2.0"; weight = 618 };
  { key = "shield.key.local_0278";                       label = "canonical_rail_278";          arity = 5; tags = ["cold"; "parse"]; since = "1.3.1"; weight = 3386 };
  { key = "item.key.modern_0279";                        label = "strict_spawner_279";          arity = 0; tags = ["experimental"; "core"]; since = "1.4.0"; weight = 3527 };
  { key = "enchant.key.cached_0280";                     label = "global_hopper_280";           arity = 2; tags = ["cold"]; since = "1.8.3"; weight = 3432 };
  { key = "effect.key.local_0281";                       label = "stable_elytra_281";           arity = 6; tags = ["runtime"]; since = "1.9.0"; weight = 3908 };
  { key = "grindstone.key.modern_0282";                  label = "primary_particle_282";        arity = 2; tags = ["core"]; since = "1.4.0"; weight = 2776 };
  { key = "comparator.key.local_0283";                   label = "derived_barrel_283";          arity = 4; tags = ["packet"]; since = "1.9.0"; weight = 3032 };
  { key = "bundle.key.strict_0284";                      label = "legacy_map_284";              arity = 1; tags = ["codegen"; "legacy"]; since = "1.5.2"; weight = 1284 };
  { key = "smithing.key.modern_0285";                    label = "primary_conduit_285";         arity = 2; tags = ["emit"]; since = "1.5.2"; weight = 3545 };
  { key = "beacon.key.internal_0286";                    label = "provisional_bundle_286";      arity = 5; tags = ["emit"; "registry"]; since = "1.5.2"; weight = 2907 };
  { key = "npc.key.secondary_0287";                      label = "secondary_potion_287";        arity = 4; tags = ["parse"]; since = "1.3.1"; weight = 1677 };
  { key = "banner.key.local_0288";                       label = "canonical_team_288";          arity = 7; tags = ["hot"]; since = "1.9.0"; weight = 2002 };
  { key = "rail.key.canonical_0289";                     label = "secondary_biome_289";         arity = 2; tags = ["legacy"; "experimental"]; since = "1.4.0"; weight = 3280 };
  { key = "minecart.key.primary_0290";                   label = "lazy_elytra_290";             arity = 1; tags = ["legacy"; "hot"]; since = "1.4.0"; weight = 605 };
  { key = "advancement.key.global_0291";                 label = "public_attribute_291";        arity = 2; tags = ["hot"]; since = "1.0.0"; weight = 2999 };
  { key = "spawner.key.stable_0292";                     label = "loose_arrow_292";             arity = 7; tags = ["emit"; "parse"]; since = "1.2.0"; weight = 2770 };
  { key = "villager.key.lazy_0293";                      label = "derived_piston_293";          arity = 4; tags = ["lower"; "content"]; since = "1.0.0"; weight = 2617 };
  { key = "player.key.modern_0294";                      label = "strict_smithing_294";         arity = 7; tags = ["async"; "legacy"]; since = "1.5.2"; weight = 1646 };
  { key = "npc.key.internal_0295";                       label = "hidden_minecart_295";         arity = 3; tags = ["typed"; "compat"; "cached"]; since = "1.0.0"; weight = 792 };
  { key = "item.key.provisional_0296";                   label = "canonical_pane_296";          arity = 0; tags = ["check"; "codegen"]; since = "1.8.3"; weight = 615 };
  { key = "sound.key.stable_0297";                       label = "strict_effect_297";           arity = 1; tags = ["async"]; since = "1.9.0"; weight = 2911 };
  { key = "brewing.key.cached_0298";                     label = "lazy_sound_298";              arity = 1; tags = ["cached"]; since = "1.8.3"; weight = 2935 };
  { key = "particle.key.loose_0299";                     label = "loose_dropper_299";           arity = 0; tags = ["core"; "content"; "parse"]; since = "1.4.0"; weight = 1104 };
  { key = "effect.key.global_0300";                      label = "modern_biome_300";            arity = 7; tags = ["check"; "async"; "hot"]; since = "1.9.0"; weight = 790 };
  { key = "minecart.key.cached_0301";                    label = "stable_smithing_301";         arity = 0; tags = ["content"]; since = "1.0.0"; weight = 68 };
  { key = "hopper.key.fallback_0302";                    label = "legacy_composter_302";        arity = 2; tags = ["emit"]; since = "1.8.3"; weight = 491 };
  { key = "composter.key.scoped_0303";                   label = "public_block_303";            arity = 5; tags = ["packet"]; since = "1.9.0"; weight = 3117 };
  { key = "rail.key.primary_0304";                       label = "internal_cartography_304";    arity = 4; tags = ["sync"; "check"]; since = "1.8.3"; weight = 1540 };
  { key = "trident.key.canonical_0305";                  label = "cached_bell_305";             arity = 1; tags = ["registry"; "core"; "cold"]; since = "1.5.2"; weight = 2652 };
  { key = "chunk.key.secondary_0306";                    label = "scoped_smoker_306";           arity = 2; tags = ["packet"]; since = "1.6.0"; weight = 3436 };
  { key = "bell.key.fallback_0307";                      label = "loose_mob_307";               arity = 7; tags = ["hot"; "packet"; "registry"]; since = "1.3.1"; weight = 3229 };
  { key = "piston.key.global_0308";                      label = "global_hologram_308";         arity = 3; tags = ["lower"; "compat"; "runtime"]; since = "1.8.3"; weight = 924 };
  { key = "world.key.canonical_0309";                    label = "loose_block_309";             arity = 2; tags = ["parse"]; since = "1.3.1"; weight = 1330 };
  { key = "rail.key.local_0310";                         label = "fallback_tablist_310";        arity = 1; tags = ["codegen"; "untyped"]; since = "1.6.0"; weight = 1907 };
  { key = "smoker.key.legacy_0311";                      label = "global_hopper_311";           arity = 6; tags = ["check"; "untyped"]; since = "1.6.0"; weight = 790 };
  { key = "advancement.key.modern_0312";                 label = "public_arrow_312";            arity = 1; tags = ["emit"; "packet"]; since = "1.0.0"; weight = 1935 };
  { key = "campfire.key.eager_0313";                     label = "local_grindstone_313";        arity = 2; tags = ["runtime"; "async"; "untyped"]; since = "1.5.2"; weight = 151 };
  { key = "stonecutter.key.cached_0314";                 label = "lazy_chunk_314";              arity = 7; tags = ["emit"; "parse"]; since = "1.5.2"; weight = 1733 };
  { key = "slot.key.hidden_0315";                        label = "hidden_bell_315";             arity = 3; tags = ["parse"]; since = "1.3.1"; weight = 2548 };
  { key = "tablist.key.canonical_0316";                  label = "global_item_316";             arity = 1; tags = ["lower"; "cold"]; since = "1.6.0"; weight = 816 };
  { key = "firework.key.primary_0317";                   label = "eager_entity_317";            arity = 3; tags = ["legacy"; "cold"; "async"]; since = "1.8.3"; weight = 2107 };
  { key = "map.key.stable_0318";                         label = "modern_trade_318";            arity = 7; tags = ["emit"; "core"; "untyped"]; since = "1.9.0"; weight = 3263 };
  { key = "hologram.key.secondary_0319";                 label = "canonical_observer_319";      arity = 7; tags = ["compat"; "async"]; since = "1.0.0"; weight = 1520 };
  { key = "beacon.key.hidden_0320";                      label = "eager_stonecutter_320";       arity = 5; tags = ["async"]; since = "1.4.0"; weight = 3513 };
  { key = "comparator.key.canonical_0321";               label = "modern_comparator_321";       arity = 0; tags = ["registry"; "compat"]; since = "1.6.0"; weight = 1548 };
  { key = "cartography.key.global_0322";                 label = "legacy_item_322";             arity = 6; tags = ["parse"; "runtime"]; since = "1.7.0"; weight = 1974 };
  { key = "dropper.key.modern_0323";                     label = "hidden_advancement_323";      arity = 6; tags = ["check"; "hot"]; since = "1.9.0"; weight = 876 };
  { key = "compass.key.primary_0324";                    label = "lazy_biome_324";              arity = 4; tags = ["core"; "compat"]; since = "1.4.0"; weight = 2459 };
  { key = "firework.key.fallback_0325";                  label = "fallback_brewing_325";        arity = 5; tags = ["cold"; "check"]; since = "1.6.0"; weight = 2488 };
  { key = "smithing.key.public_0326";                    label = "strict_tablist_326";          arity = 3; tags = ["lower"]; since = "1.3.1"; weight = 676 };
  { key = "campfire.key.canonical_0327";                 label = "eager_recipe_327";            arity = 0; tags = ["cached"; "typed"]; since = "1.4.0"; weight = 732 };
  { key = "world.key.scoped_0328";                       label = "cached_block_328";            arity = 4; tags = ["untyped"]; since = "1.0.0"; weight = 346 };
  { key = "advancement.key.primary_0329";                label = "global_bossbar_329";          arity = 1; tags = ["experimental"; "parse"; "compat"]; since = "1.4.0"; weight = 241 };
  { key = "particle.key.scoped_0330";                    label = "derived_bundle_330";          arity = 6; tags = ["typed"]; since = "1.9.0"; weight = 2331 };
  { key = "entity.key.strict_0331";                      label = "hidden_bundle_331";           arity = 2; tags = ["lower"]; since = "1.0.0"; weight = 1794 };
  { key = "crossbow.key.provisional_0332";               label = "internal_structure_332";      arity = 5; tags = ["lower"]; since = "1.3.1"; weight = 1846 };
  { key = "bell.key.internal_0333";                      label = "hidden_attribute_333";        arity = 5; tags = ["async"]; since = "1.5.2"; weight = 1998 };
  { key = "boat.key.strict_0334";                        label = "loose_shulker_334";           arity = 1; tags = ["hot"]; since = "1.8.3"; weight = 2853 };
  { key = "map.key.fallback_0335";                       label = "local_mob_335";               arity = 6; tags = ["check"; "async"; "emit"]; since = "1.8.3"; weight = 3638 };
  { key = "grindstone.key.stable_0336";                  label = "primary_hologram_336";        arity = 1; tags = ["registry"; "hot"; "experimental"]; since = "1.5.2"; weight = 595 };
  { key = "world.key.eager_0337";                        label = "derived_advancement_337";     arity = 0; tags = ["cold"; "packet"]; since = "1.4.0"; weight = 2118 };
  { key = "entity.key.scoped_0338";                      label = "lazy_region_338";             arity = 2; tags = ["runtime"]; since = "1.4.0"; weight = 3771 };
  { key = "npc.key.primary_0339";                        label = "internal_conduit_339";        arity = 5; tags = ["content"; "compat"; "legacy"]; since = "1.7.0"; weight = 1444 };
  { key = "pane.key.loose_0340";                         label = "lazy_compass_340";            arity = 2; tags = ["untyped"; "emit"; "core"]; since = "1.9.0"; weight = 3871 };
  { key = "comparator.key.eager_0341";                   label = "fallback_block_341";          arity = 2; tags = ["packet"]; since = "1.9.0"; weight = 3408 };
  { key = "bell.key.derived_0342";                       label = "provisional_anvil_342";       arity = 0; tags = ["cached"]; since = "1.0.0"; weight = 1743 };
  { key = "smoker.key.eager_0343";                       label = "primary_boat_343";            arity = 6; tags = ["check"]; since = "1.0.0"; weight = 2968 };
  { key = "gui.key.primary_0344";                        label = "public_potion_344";           arity = 6; tags = ["cold"]; since = "1.0.0"; weight = 1062 };
  { key = "team.key.lazy_0345";                          label = "primary_biome_345";           arity = 6; tags = ["legacy"; "async"]; since = "1.4.0"; weight = 1155 };
  { key = "smithing.key.fallback_0346";                  label = "internal_advancement_346";    arity = 0; tags = ["typed"; "compat"; "content"]; since = "1.8.3"; weight = 3587 };
  { key = "shield.key.loose_0347";                       label = "lazy_packet_347";             arity = 5; tags = ["runtime"]; since = "1.2.0"; weight = 2246 };
  { key = "target.key.secondary_0348";                   label = "lazy_portal_348";             arity = 2; tags = ["legacy"]; since = "1.6.0"; weight = 3894 };
  { key = "npc.key.cached_0349";                         label = "lazy_mob_349";                arity = 2; tags = ["sync"]; since = "1.3.1"; weight = 3524 };
  { key = "rail.key.eager_0350";                         label = "eager_world_350";             arity = 0; tags = ["cached"; "lower"; "codegen"]; since = "1.6.0"; weight = 1939 };
  { key = "stonecutter.key.modern_0351";                 label = "cached_arrow_351";            arity = 5; tags = ["untyped"; "parse"]; since = "1.4.0"; weight = 3386 };
  { key = "packet.key.hidden_0352";                      label = "local_elytra_352";            arity = 2; tags = ["emit"; "check"]; since = "1.4.0"; weight = 4040 };
  { key = "shield.key.eager_0353";                       label = "internal_trade_353";          arity = 5; tags = ["experimental"; "content"; "sync"]; since = "1.3.1"; weight = 1962 };
  { key = "team.key.modern_0354";                        label = "hidden_effect_354";           arity = 5; tags = ["untyped"]; since = "1.4.0"; weight = 2122 };
  { key = "slot.key.primary_0355";                       label = "legacy_pane_355";             arity = 4; tags = ["check"; "lower"]; since = "1.6.0"; weight = 492 };
  { key = "observer.key.local_0356";                     label = "internal_stonecutter_356";    arity = 2; tags = ["packet"]; since = "1.0.0"; weight = 792 };
  { key = "region.key.lazy_0357";                        label = "legacy_loom_357";             arity = 1; tags = ["cached"; "experimental"; "registry"]; since = "1.9.0"; weight = 525 };
  { key = "pane.key.provisional_0358";                   label = "internal_boat_358";           arity = 0; tags = ["core"; "runtime"]; since = "1.7.0"; weight = 1378 };
  { key = "observer.key.eager_0359";                     label = "stable_item_359";             arity = 6; tags = ["codegen"]; since = "1.4.0"; weight = 2117 };
  { key = "arrow.key.lazy_0360";                         label = "cached_chunk_360";            arity = 1; tags = ["check"; "legacy"; "sync"]; since = "1.6.0"; weight = 3742 };
  { key = "shulker.key.public_0361";                     label = "canonical_sound_361";         arity = 4; tags = ["core"; "hot"]; since = "1.7.0"; weight = 242 };
  { key = "sound.key.hidden_0362";                       label = "primary_cartography_362";     arity = 3; tags = ["emit"]; since = "1.4.0"; weight = 183 };
  { key = "campfire.key.internal_0363";                  label = "scoped_dispenser_363";        arity = 7; tags = ["check"; "cached"]; since = "1.0.0"; weight = 3129 };
  { key = "furnace.key.internal_0364";                   label = "local_furnace_364";           arity = 4; tags = ["typed"; "cold"]; since = "1.8.3"; weight = 2474 };
  { key = "smoker.key.legacy_0365";                      label = "public_banner_pattern_365";   arity = 6; tags = ["experimental"]; since = "1.9.0"; weight = 2136 };
  { key = "hopper.key.secondary_0366";                   label = "internal_chunk_366";          arity = 2; tags = ["compat"; "content"; "cached"]; since = "1.9.0"; weight = 3701 };
  { key = "boat.key.scoped_0367";                        label = "secondary_tablist_367";       arity = 0; tags = ["lower"; "registry"; "cold"]; since = "1.2.0"; weight = 1332 };
  { key = "sound.key.global_0368";                       label = "internal_arrow_368";          arity = 2; tags = ["content"; "lower"; "legacy"]; since = "1.3.1"; weight = 3421 };
  { key = "hologram.key.hidden_0369";                    label = "internal_biome_369";          arity = 7; tags = ["runtime"; "experimental"; "content"]; since = "1.2.0"; weight = 2783 };
  { key = "clock.key.secondary_0370";                    label = "internal_inventory_370";      arity = 1; tags = ["registry"; "cached"]; since = "1.9.0"; weight = 790 };
  { key = "boat.key.derived_0371";                       label = "eager_attribute_371";         arity = 4; tags = ["untyped"]; since = "1.6.0"; weight = 3126 };
  { key = "clock.key.loose_0372";                        label = "legacy_rail_372";             arity = 4; tags = ["check"]; since = "1.3.1"; weight = 2338 };
  { key = "recipe.key.secondary_0373";                   label = "fallback_conduit_373";        arity = 0; tags = ["packet"; "legacy"]; since = "1.9.0"; weight = 3091 };
  { key = "gui.key.stable_0374";                         label = "stable_sound_374";            arity = 3; tags = ["typed"]; since = "1.0.0"; weight = 3020 };
  { key = "smoker.key.canonical_0375";                   label = "fallback_dropper_375";        arity = 5; tags = ["compat"]; since = "1.4.0"; weight = 2287 };
]

let count = List.length entries

let table : (string, key_entry) Hashtbl.t =
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
