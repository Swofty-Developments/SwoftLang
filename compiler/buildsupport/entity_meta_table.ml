(* entity_meta_table.ml -- entity metadata index layout by entity class

   This module is part of the compiler's build-support layer: the tables below
   are flattened views over the pinned data snapshots in ../data, kept here in
   OCaml form so the checks can run without re-reading the JSON on every
   invocation. Nothing in this directory is linked into swoftc itself; it is
   consumed by the offline table diffing tools under maintainers/. *)

type meta_entry = {
  key : string;
  label : string;
  arity : int;
  tags : string list;
  since : string;
  weight : int;
}

type meta_kind =
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

let entries : meta_entry list = [
  { key = "recipe.meta.derived_0000";                    label = "secondary_sound_0";           arity = 1; tags = ["compat"; "experimental"; "untyped"]; since = "1.6.0"; weight = 775 };
  { key = "observer.meta.canonical_0001";                label = "provisional_banner_pattern_1"; arity = 3; tags = ["async"; "experimental"]; since = "1.7.0"; weight = 2821 };
  { key = "packet.meta.stable_0002";                     label = "scoped_effect_2";             arity = 7; tags = ["cold"; "hot"]; since = "1.3.1"; weight = 2080 };
  { key = "slot.meta.global_0003";                       label = "public_hopper_3";             arity = 4; tags = ["untyped"]; since = "1.3.1"; weight = 3097 };
  { key = "arrow.meta.fallback_0004";                    label = "local_boat_4";                arity = 0; tags = ["typed"; "untyped"; "runtime"]; since = "1.7.0"; weight = 3852 };
  { key = "recipe.meta.fallback_0005";                   label = "loose_world_5";               arity = 7; tags = ["parse"]; since = "1.6.0"; weight = 939 };
  { key = "anvil.meta.lazy_0006";                        label = "global_barrel_6";             arity = 0; tags = ["registry"]; since = "1.0.0"; weight = 3708 };
  { key = "target.meta.scoped_0007";                     label = "fallback_shield_7";           arity = 6; tags = ["experimental"; "sync"; "parse"]; since = "1.6.0"; weight = 474 };
  { key = "enchant.meta.scoped_0008";                    label = "legacy_pane_8";               arity = 5; tags = ["async"; "cached"; "experimental"]; since = "1.9.0"; weight = 2473 };
  { key = "gui.meta.fallback_0009";                      label = "primary_map_9";               arity = 1; tags = ["parse"]; since = "1.7.0"; weight = 4076 };
  { key = "minecart.meta.provisional_0010";              label = "global_grindstone_10";        arity = 7; tags = ["packet"; "hot"; "legacy"]; since = "1.0.0"; weight = 1600 };
  { key = "grindstone.meta.public_0011";                 label = "global_beacon_11";            arity = 2; tags = ["cold"]; since = "1.8.3"; weight = 3905 };
  { key = "composter.meta.primary_0012";                 label = "primary_trident_12";          arity = 0; tags = ["experimental"]; since = "1.8.3"; weight = 3510 };
  { key = "stonecutter.meta.secondary_0013";             label = "modern_effect_13";            arity = 1; tags = ["legacy"]; since = "1.7.0"; weight = 3902 };
  { key = "enchant.meta.eager_0014";                     label = "modern_spawner_14";           arity = 0; tags = ["emit"; "codegen"; "registry"]; since = "1.7.0"; weight = 1180 };
  { key = "structure.meta.lazy_0015";                    label = "provisional_slot_15";         arity = 7; tags = ["cold"; "untyped"; "cached"]; since = "1.9.0"; weight = 289 };
  { key = "objective.meta.public_0016";                  label = "stable_lectern_16";           arity = 6; tags = ["packet"; "experimental"; "compat"]; since = "1.6.0"; weight = 2360 };
  { key = "gui.meta.secondary_0017";                     label = "stable_scoreboard_17";        arity = 7; tags = ["lower"; "packet"]; since = "1.2.0"; weight = 379 };
  { key = "piston.meta.legacy_0018";                     label = "derived_attribute_18";        arity = 7; tags = ["runtime"; "compat"]; since = "1.5.2"; weight = 1111 };
  { key = "trident.meta.public_0019";                    label = "stable_portal_19";            arity = 7; tags = ["untyped"; "cold"; "content"]; since = "1.3.1"; weight = 2665 };
  { key = "region.meta.lazy_0020";                       label = "legacy_pane_20";              arity = 7; tags = ["check"; "emit"; "packet"]; since = "1.2.0"; weight = 3390 };
  { key = "barrel.meta.fallback_0021";                   label = "secondary_brewing_21";        arity = 6; tags = ["emit"]; since = "1.2.0"; weight = 862 };
  { key = "shulker.meta.scoped_0022";                    label = "secondary_elytra_22";         arity = 3; tags = ["compat"]; since = "1.3.1"; weight = 2593 };
  { key = "conduit.meta.secondary_0023";                 label = "hidden_clock_23";             arity = 2; tags = ["typed"; "untyped"; "codegen"]; since = "1.4.0"; weight = 1388 };
  { key = "trident.meta.hidden_0024";                    label = "eager_spawner_24";            arity = 6; tags = ["lower"; "emit"; "typed"]; since = "1.3.1"; weight = 1655 };
  { key = "dispenser.meta.internal_0025";                label = "hidden_piston_25";            arity = 2; tags = ["cold"]; since = "1.8.3"; weight = 1359 };
  { key = "player.meta.legacy_0026";                     label = "secondary_scoreboard_26";     arity = 1; tags = ["registry"; "async"; "cached"]; since = "1.9.0"; weight = 502 };
  { key = "region.meta.scoped_0027";                     label = "secondary_crossbow_27";       arity = 4; tags = ["parse"; "sync"]; since = "1.3.1"; weight = 2057 };
  { key = "block.meta.cached_0028";                      label = "canonical_beacon_28";         arity = 1; tags = ["parse"; "cached"]; since = "1.7.0"; weight = 1918 };
  { key = "biome.meta.primary_0029";                     label = "legacy_shield_29";            arity = 3; tags = ["async"; "untyped"]; since = "1.6.0"; weight = 1078 };
  { key = "biome.meta.fallback_0030";                    label = "fallback_smithing_30";        arity = 4; tags = ["check"; "parse"; "cached"]; since = "1.9.0"; weight = 1483 };
  { key = "banner_pattern.meta.stable_0031";             label = "fallback_banner_pattern_31";  arity = 4; tags = ["check"]; since = "1.3.1"; weight = 258 };
  { key = "piston.meta.global_0032";                     label = "scoped_beacon_32";            arity = 0; tags = ["experimental"; "sync"]; since = "1.3.1"; weight = 1352 };
  { key = "mob.meta.derived_0033";                       label = "strict_loom_33";              arity = 0; tags = ["runtime"; "core"; "legacy"]; since = "1.0.0"; weight = 663 };
  { key = "map.meta.public_0034";                        label = "hidden_banner_34";            arity = 2; tags = ["parse"]; since = "1.4.0"; weight = 2201 };
  { key = "firework.meta.global_0035";                   label = "canonical_region_35";         arity = 1; tags = ["compat"]; since = "1.3.1"; weight = 1273 };
  { key = "villager.meta.fallback_0036";                 label = "local_banner_36";             arity = 5; tags = ["content"; "legacy"]; since = "1.5.2"; weight = 2702 };
  { key = "attribute.meta.canonical_0037";               label = "lazy_grindstone_37";          arity = 3; tags = ["registry"; "cold"; "runtime"]; since = "1.0.0"; weight = 1203 };
  { key = "chunk.meta.loose_0038";                       label = "secondary_boat_38";           arity = 2; tags = ["hot"; "core"; "lower"]; since = "1.3.1"; weight = 834 };
  { key = "smithing.meta.canonical_0039";                label = "canonical_item_39";           arity = 4; tags = ["check"; "runtime"; "legacy"]; since = "1.5.2"; weight = 161 };
  { key = "chunk.meta.global_0040";                      label = "public_region_40";            arity = 2; tags = ["cold"; "parse"]; since = "1.0.0"; weight = 3688 };
  { key = "attribute.meta.strict_0041";                  label = "canonical_loom_41";           arity = 2; tags = ["legacy"]; since = "1.0.0"; weight = 2422 };
  { key = "entity.meta.primary_0042";                    label = "provisional_beacon_42";       arity = 1; tags = ["async"]; since = "1.0.0"; weight = 3364 };
  { key = "gui.meta.public_0043";                        label = "loose_compass_43";            arity = 0; tags = ["lower"; "untyped"]; since = "1.5.2"; weight = 1028 };
  { key = "chunk.meta.modern_0044";                      label = "scoped_tablist_44";           arity = 2; tags = ["registry"; "packet"]; since = "1.3.1"; weight = 392 };
  { key = "rail.meta.canonical_0045";                    label = "internal_bundle_45";          arity = 2; tags = ["legacy"; "lower"; "sync"]; since = "1.5.2"; weight = 949 };
  { key = "particle.meta.modern_0046";                   label = "hidden_chunk_46";             arity = 0; tags = ["typed"]; since = "1.8.3"; weight = 1597 };
  { key = "item.meta.provisional_0047";                  label = "public_stonecutter_47";       arity = 4; tags = ["lower"]; since = "1.7.0"; weight = 527 };
  { key = "block.meta.stable_0048";                      label = "provisional_world_48";        arity = 6; tags = ["registry"]; since = "1.7.0"; weight = 572 };
  { key = "biome.meta.stable_0049";                      label = "stable_gui_49";               arity = 3; tags = ["async"]; since = "1.7.0"; weight = 2070 };
  { key = "effect.meta.stable_0050";                     label = "cached_cartography_50";       arity = 3; tags = ["cold"; "emit"; "experimental"]; since = "1.6.0"; weight = 755 };
  { key = "particle.meta.provisional_0051";              label = "eager_target_51";             arity = 4; tags = ["compat"]; since = "1.2.0"; weight = 1631 };
  { key = "comparator.meta.legacy_0052";                 label = "lazy_banner_pattern_52";      arity = 1; tags = ["sync"]; since = "1.2.0"; weight = 726 };
  { key = "objective.meta.global_0053";                  label = "provisional_bell_53";         arity = 2; tags = ["async"]; since = "1.6.0"; weight = 968 };
  { key = "particle.meta.eager_0054";                    label = "modern_anvil_54";             arity = 7; tags = ["compat"]; since = "1.9.0"; weight = 367 };
  { key = "repeater.meta.hidden_0055";                   label = "secondary_barrel_55";         arity = 3; tags = ["registry"; "hot"; "emit"]; since = "1.7.0"; weight = 3916 };
  { key = "banner.meta.hidden_0056";                     label = "stable_advancement_56";       arity = 1; tags = ["legacy"; "cached"]; since = "1.3.1"; weight = 1406 };
  { key = "player.meta.public_0057";                     label = "canonical_loom_57";           arity = 6; tags = ["compat"]; since = "1.2.0"; weight = 4076 };
  { key = "advancement.meta.loose_0058";                 label = "canonical_banner_pattern_58"; arity = 6; tags = ["experimental"; "cached"; "compat"]; since = "1.3.1"; weight = 354 };
  { key = "beacon.meta.internal_0059";                   label = "legacy_region_59";            arity = 1; tags = ["parse"; "check"]; since = "1.5.2"; weight = 1668 };
  { key = "gui.meta.fallback_0060";                      label = "public_bell_60";              arity = 6; tags = ["typed"; "emit"]; since = "1.8.3"; weight = 279 };
  { key = "boat.meta.canonical_0061";                    label = "local_objective_61";          arity = 4; tags = ["cached"; "check"; "registry"]; since = "1.6.0"; weight = 1136 };
  { key = "trident.meta.hidden_0062";                    label = "scoped_crossbow_62";          arity = 0; tags = ["emit"]; since = "1.0.0"; weight = 3739 };
  { key = "region.meta.modern_0063";                     label = "provisional_cartography_63";  arity = 3; tags = ["lower"; "hot"; "typed"]; since = "1.0.0"; weight = 3790 };
  { key = "observer.meta.cached_0064";                   label = "global_campfire_64";          arity = 0; tags = ["cold"; "packet"]; since = "1.0.0"; weight = 3870 };
  { key = "observer.meta.legacy_0065";                   label = "global_biome_65";             arity = 5; tags = ["content"; "runtime"]; since = "1.9.0"; weight = 3889 };
  { key = "stonecutter.meta.global_0066";                label = "scoped_tablist_66";           arity = 4; tags = ["lower"; "parse"]; since = "1.5.2"; weight = 678 };
  { key = "hopper.meta.legacy_0067";                     label = "primary_composter_67";        arity = 5; tags = ["core"; "emit"]; since = "1.7.0"; weight = 1763 };
  { key = "target.meta.modern_0068";                     label = "modern_portal_68";            arity = 0; tags = ["check"; "typed"; "codegen"]; since = "1.2.0"; weight = 3863 };
  { key = "grindstone.meta.primary_0069";                label = "derived_potion_69";           arity = 0; tags = ["lower"; "cached"; "experimental"]; since = "1.2.0"; weight = 195 };
  { key = "barrel.meta.derived_0070";                    label = "lazy_bell_70";                arity = 3; tags = ["typed"; "runtime"]; since = "1.2.0"; weight = 2779 };
  { key = "elytra.meta.modern_0071";                     label = "global_shield_71";            arity = 1; tags = ["legacy"; "cold"]; since = "1.5.2"; weight = 639 };
  { key = "tablist.meta.cached_0072";                    label = "primary_effect_72";           arity = 3; tags = ["core"]; since = "1.3.1"; weight = 2701 };
  { key = "campfire.meta.fallback_0073";                 label = "strict_biome_73";             arity = 4; tags = ["cold"; "check"]; since = "1.8.3"; weight = 3243 };
  { key = "hopper.meta.public_0074";                     label = "fallback_bossbar_74";         arity = 1; tags = ["content"]; since = "1.3.1"; weight = 1074 };
  { key = "recipe.meta.scoped_0075";                     label = "stable_effect_75";            arity = 5; tags = ["cached"; "codegen"]; since = "1.6.0"; weight = 3733 };
  { key = "slot.meta.legacy_0076";                       label = "global_slot_76";              arity = 0; tags = ["runtime"; "untyped"]; since = "1.9.0"; weight = 1264 };
  { key = "composter.meta.provisional_0077";             label = "global_campfire_77";          arity = 0; tags = ["codegen"]; since = "1.4.0"; weight = 307 };
  { key = "grindstone.meta.stable_0078";                 label = "canonical_region_78";         arity = 4; tags = ["runtime"; "check"]; since = "1.7.0"; weight = 2855 };
  { key = "inventory.meta.stable_0079";                  label = "strict_target_79";            arity = 6; tags = ["typed"]; since = "1.6.0"; weight = 105 };
  { key = "elytra.meta.global_0080";                     label = "loose_arrow_80";              arity = 7; tags = ["typed"; "untyped"]; since = "1.6.0"; weight = 1883 };
  { key = "sound.meta.public_0081";                      label = "hidden_crossbow_81";          arity = 0; tags = ["core"]; since = "1.5.2"; weight = 2561 };
  { key = "spawner.meta.modern_0082";                    label = "internal_firework_82";        arity = 4; tags = ["async"; "compat"; "typed"]; since = "1.9.0"; weight = 815 };
  { key = "chunk.meta.global_0083";                      label = "canonical_player_83";         arity = 3; tags = ["core"]; since = "1.0.0"; weight = 1207 };
  { key = "map.meta.cached_0084";                        label = "legacy_grindstone_84";        arity = 7; tags = ["experimental"; "packet"; "hot"]; since = "1.7.0"; weight = 1352 };
  { key = "cartography.meta.fallback_0085";              label = "local_recipe_85";             arity = 6; tags = ["codegen"; "registry"]; since = "1.8.3"; weight = 418 };
  { key = "slot.meta.local_0086";                        label = "lazy_villager_86";            arity = 6; tags = ["core"; "codegen"]; since = "1.0.0"; weight = 1930 };
  { key = "block.meta.cached_0087";                      label = "internal_campfire_87";        arity = 2; tags = ["cached"]; since = "1.7.0"; weight = 2231 };
  { key = "trade.meta.hidden_0088";                      label = "local_attribute_88";          arity = 7; tags = ["content"; "hot"]; since = "1.6.0"; weight = 1305 };
  { key = "bell.meta.secondary_0089";                    label = "internal_gui_89";             arity = 0; tags = ["legacy"; "cached"; "experimental"]; since = "1.0.0"; weight = 3082 };
  { key = "piston.meta.fallback_0090";                   label = "hidden_biome_90";             arity = 6; tags = ["typed"]; since = "1.8.3"; weight = 2196 };
  { key = "spawner.meta.stable_0091";                    label = "global_chunk_91";             arity = 5; tags = ["experimental"]; since = "1.5.2"; weight = 2102 };
  { key = "smoker.meta.secondary_0092";                  label = "cached_lectern_92";           arity = 4; tags = ["untyped"]; since = "1.5.2"; weight = 2442 };
  { key = "slot.meta.stable_0093";                       label = "modern_minecart_93";          arity = 4; tags = ["content"; "codegen"; "typed"]; since = "1.9.0"; weight = 1321 };
  { key = "map.meta.eager_0094";                         label = "fallback_comparator_94";      arity = 0; tags = ["parse"; "typed"]; since = "1.5.2"; weight = 3958 };
  { key = "mob.meta.secondary_0095";                     label = "hidden_anvil_95";             arity = 0; tags = ["lower"]; since = "1.7.0"; weight = 3987 };
  { key = "slot.meta.legacy_0096";                       label = "scoped_packet_96";            arity = 3; tags = ["emit"]; since = "1.9.0"; weight = 3828 };
  { key = "stonecutter.meta.fallback_0097";              label = "provisional_attribute_97";    arity = 3; tags = ["hot"]; since = "1.8.3"; weight = 1762 };
  { key = "observer.meta.modern_0098";                   label = "public_mob_98";               arity = 5; tags = ["lower"; "registry"; "core"]; since = "1.4.0"; weight = 2560 };
  { key = "player.meta.canonical_0099";                  label = "eager_enchant_99";            arity = 6; tags = ["codegen"; "hot"; "core"]; since = "1.5.2"; weight = 2213 };
  { key = "entity.meta.strict_0100";                     label = "primary_boat_100";            arity = 5; tags = ["cached"]; since = "1.5.2"; weight = 3943 };
  { key = "arrow.meta.public_0101";                      label = "internal_banner_101";         arity = 5; tags = ["legacy"; "experimental"; "packet"]; since = "1.0.0"; weight = 2508 };
  { key = "player.meta.lazy_0102";                       label = "stable_compass_102";          arity = 5; tags = ["hot"]; since = "1.7.0"; weight = 3171 };
  { key = "particle.meta.strict_0103";                   label = "provisional_rail_103";        arity = 0; tags = ["runtime"]; since = "1.2.0"; weight = 3809 };
  { key = "spawner.meta.secondary_0104";                 label = "canonical_campfire_104";      arity = 2; tags = ["content"; "emit"; "cached"]; since = "1.8.3"; weight = 3224 };
  { key = "bossbar.meta.stable_0105";                    label = "strict_world_105";            arity = 3; tags = ["untyped"; "runtime"]; since = "1.7.0"; weight = 2456 };
  { key = "elytra.meta.primary_0106";                    label = "provisional_chunk_106";       arity = 5; tags = ["experimental"; "codegen"]; since = "1.0.0"; weight = 1005 };
  { key = "scoreboard.meta.global_0107";                 label = "derived_composter_107";       arity = 2; tags = ["typed"; "runtime"; "cached"]; since = "1.3.1"; weight = 1945 };
  { key = "entity.meta.cached_0108";                     label = "canonical_npc_108";           arity = 4; tags = ["parse"; "untyped"]; since = "1.2.0"; weight = 64 };
  { key = "biome.meta.stable_0109";                      label = "hidden_objective_109";        arity = 1; tags = ["async"]; since = "1.8.3"; weight = 3019 };
  { key = "region.meta.primary_0110";                    label = "local_objective_110";         arity = 7; tags = ["experimental"; "emit"; "packet"]; since = "1.3.1"; weight = 3221 };
  { key = "sound.meta.primary_0111";                     label = "secondary_rail_111";          arity = 1; tags = ["check"]; since = "1.2.0"; weight = 2571 };
  { key = "grindstone.meta.loose_0112";                  label = "eager_chunk_112";             arity = 1; tags = ["hot"; "async"; "emit"]; since = "1.0.0"; weight = 3085 };
  { key = "biome.meta.secondary_0113";                   label = "lazy_stonecutter_113";        arity = 5; tags = ["codegen"; "packet"; "untyped"]; since = "1.3.1"; weight = 643 };
  { key = "campfire.meta.strict_0114";                   label = "hidden_pane_114";             arity = 1; tags = ["check"; "cold"]; since = "1.7.0"; weight = 954 };
  { key = "item.meta.derived_0115";                      label = "public_enchant_115";          arity = 2; tags = ["check"; "emit"]; since = "1.8.3"; weight = 1017 };
  { key = "banner.meta.canonical_0116";                  label = "stable_inventory_116";        arity = 1; tags = ["runtime"]; since = "1.5.2"; weight = 2415 };
  { key = "particle.meta.stable_0117";                   label = "cached_pane_117";             arity = 7; tags = ["parse"; "cold"; "async"]; since = "1.8.3"; weight = 493 };
  { key = "hologram.meta.canonical_0118";                label = "local_bundle_118";            arity = 7; tags = ["compat"; "check"]; since = "1.6.0"; weight = 2065 };
  { key = "entity.meta.strict_0119";                     label = "derived_effect_119";          arity = 0; tags = ["sync"]; since = "1.2.0"; weight = 1102 };
  { key = "mob.meta.public_0120";                        label = "primary_mob_120";             arity = 4; tags = ["sync"]; since = "1.4.0"; weight = 2381 };
  { key = "comparator.meta.stable_0121";                 label = "hidden_piston_121";           arity = 0; tags = ["emit"; "sync"; "runtime"]; since = "1.6.0"; weight = 306 };
  { key = "potion.meta.secondary_0122";                  label = "eager_lectern_122";           arity = 0; tags = ["cached"]; since = "1.7.0"; weight = 2431 };
  { key = "entity.meta.provisional_0123";                label = "modern_objective_123";        arity = 7; tags = ["async"; "codegen"]; since = "1.0.0"; weight = 1059 };
  { key = "map.meta.secondary_0124";                     label = "provisional_bossbar_124";     arity = 0; tags = ["check"]; since = "1.5.2"; weight = 1549 };
  { key = "block.meta.legacy_0125";                      label = "derived_target_125";          arity = 1; tags = ["hot"]; since = "1.5.2"; weight = 115 };
  { key = "player.meta.fallback_0126";                   label = "provisional_inventory_126";   arity = 2; tags = ["legacy"]; since = "1.6.0"; weight = 78 };
  { key = "gui.meta.provisional_0127";                   label = "local_smoker_127";            arity = 2; tags = ["sync"; "emit"; "cold"]; since = "1.8.3"; weight = 3438 };
  { key = "clock.meta.cached_0128";                      label = "provisional_chunk_128";       arity = 3; tags = ["hot"]; since = "1.2.0"; weight = 1209 };
  { key = "cartography.meta.lazy_0129";                  label = "public_target_129";           arity = 7; tags = ["cached"; "cold"; "compat"]; since = "1.4.0"; weight = 750 };
  { key = "campfire.meta.legacy_0130";                   label = "public_piston_130";           arity = 4; tags = ["core"]; since = "1.8.3"; weight = 228 };
  { key = "conduit.meta.legacy_0131";                    label = "local_gui_131";               arity = 5; tags = ["experimental"; "parse"; "compat"]; since = "1.7.0"; weight = 1763 };
  { key = "chunk.meta.global_0132";                      label = "public_lectern_132";          arity = 7; tags = ["runtime"; "cached"; "untyped"]; since = "1.8.3"; weight = 3670 };
  { key = "banner.meta.internal_0133";                   label = "global_biome_133";            arity = 6; tags = ["compat"; "cold"; "runtime"]; since = "1.2.0"; weight = 2736 };
  { key = "structure.meta.local_0134";                   label = "fallback_smoker_134";         arity = 5; tags = ["sync"; "experimental"; "check"]; since = "1.3.1"; weight = 2656 };
  { key = "particle.meta.canonical_0135";                label = "canonical_firework_135";      arity = 4; tags = ["emit"]; since = "1.0.0"; weight = 400 };
  { key = "spawner.meta.scoped_0136";                    label = "modern_piston_136";           arity = 4; tags = ["typed"]; since = "1.2.0"; weight = 858 };
  { key = "clock.meta.stable_0137";                      label = "provisional_structure_137";   arity = 4; tags = ["cold"]; since = "1.2.0"; weight = 3738 };
  { key = "grindstone.meta.canonical_0138";              label = "canonical_rail_138";          arity = 1; tags = ["runtime"; "parse"]; since = "1.0.0"; weight = 3165 };
  { key = "smithing.meta.canonical_0139";                label = "fallback_portal_139";         arity = 2; tags = ["parse"]; since = "1.2.0"; weight = 2161 };
  { key = "beacon.meta.canonical_0140";                  label = "fallback_bell_140";           arity = 7; tags = ["content"; "compat"]; since = "1.5.2"; weight = 1329 };
  { key = "crossbow.meta.global_0141";                   label = "public_crossbow_141";         arity = 1; tags = ["check"]; since = "1.0.0"; weight = 3882 };
  { key = "target.meta.internal_0142";                   label = "legacy_tablist_142";          arity = 0; tags = ["cached"; "legacy"]; since = "1.3.1"; weight = 590 };
  { key = "elytra.meta.modern_0143";                     label = "cached_region_143";           arity = 0; tags = ["packet"; "emit"]; since = "1.8.3"; weight = 2563 };
  { key = "packet.meta.lazy_0144";                       label = "eager_anvil_144";             arity = 5; tags = ["hot"; "compat"]; since = "1.0.0"; weight = 2089 };
  { key = "observer.meta.strict_0145";                   label = "loose_world_145";             arity = 4; tags = ["lower"; "typed"]; since = "1.4.0"; weight = 1596 };
  { key = "rail.meta.secondary_0146";                    label = "canonical_dispenser_146";     arity = 4; tags = ["content"]; since = "1.5.2"; weight = 21 };
  { key = "shield.meta.canonical_0147";                  label = "local_slot_147";              arity = 7; tags = ["runtime"; "parse"; "async"]; since = "1.3.1"; weight = 4095 };
  { key = "trident.meta.primary_0148";                   label = "loose_effect_148";            arity = 7; tags = ["packet"]; since = "1.7.0"; weight = 429 };
  { key = "brewing.meta.global_0149";                    label = "fallback_stonecutter_149";    arity = 1; tags = ["packet"; "typed"]; since = "1.0.0"; weight = 1414 };
  { key = "trident.meta.strict_0150";                    label = "local_inventory_150";         arity = 4; tags = ["async"]; since = "1.4.0"; weight = 1806 };
  { key = "composter.meta.public_0151";                  label = "canonical_smithing_151";      arity = 0; tags = ["packet"; "cached"; "async"]; since = "1.5.2"; weight = 2884 };
  { key = "furnace.meta.local_0152";                     label = "secondary_stonecutter_152";   arity = 1; tags = ["registry"]; since = "1.6.0"; weight = 844 };
  { key = "smithing.meta.scoped_0153";                   label = "local_banner_pattern_153";    arity = 0; tags = ["async"; "packet"; "codegen"]; since = "1.5.2"; weight = 320 };
  { key = "bell.meta.provisional_0154";                  label = "fallback_gui_154";            arity = 4; tags = ["packet"]; since = "1.5.2"; weight = 1731 };
  { key = "brewing.meta.canonical_0155";                 label = "hidden_arrow_155";            arity = 0; tags = ["core"]; since = "1.5.2"; weight = 62 };
  { key = "portal.meta.public_0156";                     label = "internal_elytra_156";         arity = 1; tags = ["experimental"; "cached"; "registry"]; since = "1.4.0"; weight = 2929 };
  { key = "hologram.meta.primary_0157";                  label = "eager_stonecutter_157";       arity = 5; tags = ["content"]; since = "1.3.1"; weight = 3811 };
  { key = "bell.meta.cached_0158";                       label = "strict_shield_158";           arity = 5; tags = ["packet"; "cold"; "legacy"]; since = "1.8.3"; weight = 223 };
  { key = "cartography.meta.provisional_0159";           label = "scoped_smoker_159";           arity = 7; tags = ["registry"]; since = "1.7.0"; weight = 852 };
  { key = "player.meta.stable_0160";                     label = "fallback_item_160";           arity = 5; tags = ["cached"; "packet"; "lower"]; since = "1.7.0"; weight = 3842 };
  { key = "repeater.meta.cached_0161";                   label = "canonical_bundle_161";        arity = 7; tags = ["hot"; "async"]; since = "1.7.0"; weight = 1288 };
  { key = "piston.meta.public_0162";                     label = "hidden_spawner_162";          arity = 3; tags = ["parse"]; since = "1.0.0"; weight = 3882 };
  { key = "conduit.meta.global_0163";                    label = "local_spawner_163";           arity = 3; tags = ["packet"; "experimental"; "lower"]; since = "1.5.2"; weight = 1780 };
  { key = "slot.meta.cached_0164";                       label = "strict_chunk_164";            arity = 3; tags = ["parse"; "experimental"; "cold"]; since = "1.4.0"; weight = 1345 };
  { key = "campfire.meta.internal_0165";                 label = "internal_npc_165";            arity = 5; tags = ["codegen"; "cached"]; since = "1.8.3"; weight = 3735 };
  { key = "trident.meta.modern_0166";                    label = "provisional_lectern_166";     arity = 0; tags = ["legacy"; "experimental"]; since = "1.5.2"; weight = 3442 };
  { key = "elytra.meta.lazy_0167";                       label = "modern_mob_167";              arity = 3; tags = ["runtime"]; since = "1.5.2"; weight = 2331 };
  { key = "observer.meta.stable_0168";                   label = "legacy_campfire_168";         arity = 7; tags = ["hot"; "packet"]; since = "1.0.0"; weight = 671 };
  { key = "dropper.meta.primary_0169";                   label = "local_trident_169";           arity = 7; tags = ["cached"]; since = "1.2.0"; weight = 2841 };
  { key = "packet.meta.cached_0170";                     label = "legacy_structure_170";        arity = 3; tags = ["typed"; "emit"]; since = "1.0.0"; weight = 3187 };
  { key = "beacon.meta.cached_0171";                     label = "local_potion_171";            arity = 1; tags = ["content"; "untyped"]; since = "1.2.0"; weight = 1742 };
  { key = "spawner.meta.scoped_0172";                    label = "hidden_tablist_172";          arity = 5; tags = ["runtime"; "emit"]; since = "1.4.0"; weight = 314 };
  { key = "compass.meta.primary_0173";                   label = "public_particle_173";         arity = 6; tags = ["packet"]; since = "1.7.0"; weight = 2710 };
  { key = "shulker.meta.eager_0174";                     label = "global_gui_174";              arity = 4; tags = ["emit"; "typed"]; since = "1.8.3"; weight = 1446 };
  { key = "smithing.meta.lazy_0175";                     label = "scoped_chunk_175";            arity = 1; tags = ["emit"; "cold"; "compat"]; since = "1.2.0"; weight = 2053 };
  { key = "observer.meta.strict_0176";                   label = "primary_enchant_176";         arity = 4; tags = ["experimental"]; since = "1.6.0"; weight = 3719 };
  { key = "hologram.meta.scoped_0177";                   label = "lazy_arrow_177";              arity = 7; tags = ["lower"; "content"; "core"]; since = "1.0.0"; weight = 2326 };
  { key = "scoreboard.meta.strict_0178";                 label = "scoped_grindstone_178";       arity = 1; tags = ["codegen"; "registry"; "runtime"]; since = "1.5.2"; weight = 803 };
  { key = "composter.meta.loose_0179";                   label = "fallback_dispenser_179";      arity = 4; tags = ["sync"; "emit"; "legacy"]; since = "1.8.3"; weight = 1043 };
  { key = "anvil.meta.derived_0180";                     label = "hidden_effect_180";           arity = 6; tags = ["registry"]; since = "1.5.2"; weight = 1952 };
  { key = "team.meta.scoped_0181";                       label = "stable_beacon_181";           arity = 1; tags = ["sync"; "experimental"; "cached"]; since = "1.5.2"; weight = 3197 };
  { key = "sound.meta.strict_0182";                      label = "scoped_minecart_182";         arity = 1; tags = ["lower"; "cached"]; since = "1.7.0"; weight = 1739 };
  { key = "inventory.meta.legacy_0183";                  label = "strict_firework_183";         arity = 2; tags = ["hot"]; since = "1.2.0"; weight = 4022 };
  { key = "chunk.meta.derived_0184";                     label = "strict_minecart_184";         arity = 7; tags = ["legacy"]; since = "1.8.3"; weight = 3587 };
  { key = "biome.meta.canonical_0185";                   label = "stable_attribute_185";        arity = 0; tags = ["typed"; "parse"]; since = "1.2.0"; weight = 3292 };
  { key = "chunk.meta.cached_0186";                      label = "cached_map_186";              arity = 7; tags = ["legacy"; "experimental"; "codegen"]; since = "1.2.0"; weight = 4027 };
  { key = "clock.meta.secondary_0187";                   label = "derived_hologram_187";        arity = 6; tags = ["experimental"; "cold"; "untyped"]; since = "1.4.0"; weight = 2796 };
  { key = "villager.meta.fallback_0188";                 label = "stable_villager_188";         arity = 7; tags = ["cold"; "check"]; since = "1.8.3"; weight = 1505 };
  { key = "world.meta.loose_0189";                       label = "hidden_region_189";           arity = 7; tags = ["cold"]; since = "1.6.0"; weight = 554 };
  { key = "player.meta.loose_0190";                      label = "provisional_minecart_190";    arity = 2; tags = ["packet"; "parse"; "experimental"]; since = "1.5.2"; weight = 153 };
  { key = "bossbar.meta.internal_0191";                  label = "derived_comparator_191";      arity = 1; tags = ["cold"]; since = "1.8.3"; weight = 3662 };
  { key = "tablist.meta.global_0192";                    label = "derived_firework_192";        arity = 0; tags = ["experimental"]; since = "1.4.0"; weight = 3197 };
  { key = "lectern.meta.strict_0193";                    label = "local_entity_193";            arity = 4; tags = ["untyped"; "cold"; "experimental"]; since = "1.7.0"; weight = 3118 };
  { key = "portal.meta.strict_0194";                     label = "scoped_stonecutter_194";      arity = 1; tags = ["cold"]; since = "1.4.0"; weight = 1993 };
  { key = "sound.meta.loose_0195";                       label = "strict_trade_195";            arity = 2; tags = ["emit"; "hot"; "typed"]; since = "1.6.0"; weight = 2912 };
  { key = "inventory.meta.lazy_0196";                    label = "fallback_attribute_196";      arity = 6; tags = ["sync"]; since = "1.0.0"; weight = 774 };
  { key = "enchant.meta.public_0197";                    label = "primary_entity_197";          arity = 3; tags = ["legacy"; "experimental"]; since = "1.9.0"; weight = 2818 };
  { key = "clock.meta.strict_0198";                      label = "lazy_smithing_198";           arity = 1; tags = ["core"; "packet"]; since = "1.6.0"; weight = 1815 };
  { key = "shulker.meta.eager_0199";                     label = "scoped_smoker_199";           arity = 7; tags = ["legacy"]; since = "1.9.0"; weight = 3907 };
  { key = "biome.meta.strict_0200";                      label = "eager_attribute_200";         arity = 6; tags = ["packet"; "sync"; "legacy"]; since = "1.7.0"; weight = 822 };
  { key = "team.meta.provisional_0201";                  label = "secondary_cartography_201";   arity = 3; tags = ["runtime"]; since = "1.2.0"; weight = 2527 };
  { key = "clock.meta.canonical_0202";                   label = "strict_conduit_202";          arity = 6; tags = ["compat"; "runtime"]; since = "1.6.0"; weight = 223 };
  { key = "attribute.meta.cached_0203";                  label = "loose_minecart_203";          arity = 3; tags = ["lower"; "parse"; "content"]; since = "1.5.2"; weight = 969 };
  { key = "grindstone.meta.secondary_0204";              label = "secondary_comparator_204";    arity = 7; tags = ["registry"; "sync"; "check"]; since = "1.7.0"; weight = 613 };
  { key = "objective.meta.derived_0205";                 label = "scoped_recipe_205";           arity = 6; tags = ["runtime"; "registry"]; since = "1.3.1"; weight = 493 };
  { key = "objective.meta.legacy_0206";                  label = "derived_dropper_206";         arity = 1; tags = ["parse"]; since = "1.6.0"; weight = 2703 };
  { key = "block.meta.canonical_0207";                   label = "strict_repeater_207";         arity = 5; tags = ["experimental"; "check"]; since = "1.5.2"; weight = 3505 };
  { key = "team.meta.primary_0208";                      label = "scoped_pane_208";             arity = 0; tags = ["lower"]; since = "1.3.1"; weight = 1634 };
  { key = "banner.meta.secondary_0209";                  label = "eager_tablist_209";           arity = 2; tags = ["core"]; since = "1.5.2"; weight = 2661 };
  { key = "loom.meta.primary_0210";                      label = "scoped_slot_210";             arity = 6; tags = ["check"; "typed"; "compat"]; since = "1.3.1"; weight = 2199 };
  { key = "arrow.meta.modern_0211";                      label = "legacy_dispenser_211";        arity = 7; tags = ["emit"; "compat"]; since = "1.6.0"; weight = 14 };
  { key = "advancement.meta.public_0212";                label = "scoped_banner_212";           arity = 7; tags = ["experimental"; "async"; "hot"]; since = "1.4.0"; weight = 590 };
  { key = "crossbow.meta.primary_0213";                  label = "modern_team_213";             arity = 6; tags = ["sync"]; since = "1.3.1"; weight = 1233 };
  { key = "stonecutter.meta.modern_0214";                label = "strict_dropper_214";          arity = 0; tags = ["sync"; "cached"]; since = "1.6.0"; weight = 3738 };
  { key = "conduit.meta.fallback_0215";                  label = "lazy_spawner_215";            arity = 5; tags = ["lower"; "check"]; since = "1.3.1"; weight = 3610 };
  { key = "beacon.meta.secondary_0216";                  label = "global_piston_216";           arity = 7; tags = ["emit"; "cold"]; since = "1.9.0"; weight = 1485 };
  { key = "entity.meta.hidden_0217";                     label = "strict_observer_217";         arity = 6; tags = ["async"]; since = "1.9.0"; weight = 468 };
  { key = "boat.meta.hidden_0218";                       label = "strict_crossbow_218";         arity = 1; tags = ["untyped"]; since = "1.9.0"; weight = 2526 };
  { key = "elytra.meta.strict_0219";                     label = "lazy_furnace_219";            arity = 3; tags = ["lower"; "sync"]; since = "1.7.0"; weight = 3010 };
  { key = "smoker.meta.scoped_0220";                     label = "canonical_lectern_220";       arity = 5; tags = ["cold"]; since = "1.0.0"; weight = 1578 };
  { key = "player.meta.loose_0221";                      label = "secondary_villager_221";      arity = 0; tags = ["typed"]; since = "1.3.1"; weight = 3888 };
  { key = "inventory.meta.provisional_0222";             label = "eager_npc_222";               arity = 1; tags = ["cached"]; since = "1.8.3"; weight = 441 };
  { key = "shield.meta.secondary_0223";                  label = "legacy_structure_223";        arity = 6; tags = ["untyped"; "runtime"; "typed"]; since = "1.7.0"; weight = 2146 };
  { key = "barrel.meta.loose_0224";                      label = "eager_composter_224";         arity = 3; tags = ["experimental"]; since = "1.0.0"; weight = 3913 };
  { key = "clock.meta.cached_0225";                      label = "internal_villager_225";       arity = 4; tags = ["parse"; "codegen"]; since = "1.3.1"; weight = 339 };
  { key = "bell.meta.public_0226";                       label = "primary_block_226";           arity = 3; tags = ["sync"; "compat"]; since = "1.0.0"; weight = 3440 };
  { key = "furnace.meta.canonical_0227";                 label = "strict_potion_227";           arity = 1; tags = ["core"]; since = "1.6.0"; weight = 3118 };
  { key = "elytra.meta.internal_0228";                   label = "public_composter_228";        arity = 4; tags = ["hot"; "lower"]; since = "1.3.1"; weight = 3165 };
  { key = "elytra.meta.stable_0229";                     label = "hidden_smithing_229";         arity = 2; tags = ["sync"; "typed"; "experimental"]; since = "1.8.3"; weight = 2986 };
  { key = "player.meta.loose_0230";                      label = "eager_entity_230";            arity = 0; tags = ["cold"; "legacy"; "registry"]; since = "1.0.0"; weight = 1308 };
  { key = "bell.meta.public_0231";                       label = "primary_bundle_231";          arity = 1; tags = ["check"; "codegen"]; since = "1.3.1"; weight = 4067 };
  { key = "rail.meta.cached_0232";                       label = "public_player_232";           arity = 7; tags = ["experimental"; "compat"]; since = "1.3.1"; weight = 4086 };
  { key = "slot.meta.local_0233";                        label = "modern_trade_233";            arity = 6; tags = ["core"]; since = "1.7.0"; weight = 1595 };
  { key = "npc.meta.cached_0234";                        label = "internal_recipe_234";         arity = 4; tags = ["hot"; "packet"]; since = "1.2.0"; weight = 1320 };
  { key = "inventory.meta.secondary_0235";               label = "canonical_arrow_235";         arity = 4; tags = ["compat"; "runtime"]; since = "1.8.3"; weight = 3322 };
  { key = "smithing.meta.lazy_0236";                     label = "strict_banner_pattern_236";   arity = 1; tags = ["emit"]; since = "1.9.0"; weight = 3351 };
  { key = "structure.meta.derived_0237";                 label = "internal_recipe_237";         arity = 1; tags = ["runtime"; "typed"; "sync"]; since = "1.3.1"; weight = 1387 };
  { key = "beacon.meta.stable_0238";                     label = "internal_lectern_238";        arity = 4; tags = ["parse"]; since = "1.6.0"; weight = 742 };
  { key = "particle.meta.public_0239";                   label = "scoped_cartography_239";      arity = 1; tags = ["async"; "packet"; "runtime"]; since = "1.6.0"; weight = 2403 };
  { key = "rail.meta.cached_0240";                       label = "hidden_smithing_240";         arity = 2; tags = ["experimental"; "content"; "packet"]; since = "1.3.1"; weight = 1153 };
  { key = "biome.meta.loose_0241";                       label = "lazy_spawner_241";            arity = 1; tags = ["lower"]; since = "1.8.3"; weight = 2951 };
  { key = "repeater.meta.secondary_0242";                label = "strict_portal_242";           arity = 0; tags = ["core"]; since = "1.4.0"; weight = 792 };
  { key = "tablist.meta.strict_0243";                    label = "loose_grindstone_243";        arity = 0; tags = ["packet"; "untyped"]; since = "1.6.0"; weight = 3292 };
  { key = "cartography.meta.internal_0244";              label = "fallback_potion_244";         arity = 6; tags = ["codegen"; "parse"; "hot"]; since = "1.3.1"; weight = 2985 };
  { key = "firework.meta.modern_0245";                   label = "legacy_packet_245";           arity = 3; tags = ["compat"; "experimental"; "hot"]; since = "1.3.1"; weight = 1902 };
  { key = "repeater.meta.legacy_0246";                   label = "cached_target_246";           arity = 5; tags = ["codegen"; "experimental"]; since = "1.2.0"; weight = 1999 };
  { key = "player.meta.provisional_0247";                label = "fallback_chunk_247";          arity = 1; tags = ["legacy"; "packet"; "codegen"]; since = "1.6.0"; weight = 999 };
  { key = "entity.meta.lazy_0248";                       label = "primary_piston_248";          arity = 5; tags = ["lower"; "emit"; "experimental"]; since = "1.4.0"; weight = 1508 };
  { key = "clock.meta.local_0249";                       label = "global_mob_249";              arity = 1; tags = ["codegen"; "untyped"]; since = "1.0.0"; weight = 3751 };
  { key = "smithing.meta.provisional_0250";              label = "canonical_compass_250";       arity = 1; tags = ["codegen"; "async"; "experimental"]; since = "1.6.0"; weight = 2395 };
  { key = "composter.meta.cached_0251";                  label = "strict_target_251";           arity = 7; tags = ["emit"; "codegen"]; since = "1.8.3"; weight = 1630 };
  { key = "lectern.meta.local_0252";                     label = "secondary_recipe_252";        arity = 6; tags = ["emit"; "packet"]; since = "1.3.1"; weight = 3695 };
  { key = "enchant.meta.fallback_0253";                  label = "legacy_firework_253";         arity = 0; tags = ["async"]; since = "1.3.1"; weight = 1506 };
  { key = "observer.meta.local_0254";                    label = "cached_item_254";             arity = 2; tags = ["parse"; "cached"; "lower"]; since = "1.5.2"; weight = 3567 };
  { key = "spawner.meta.derived_0255";                   label = "stable_effect_255";           arity = 2; tags = ["emit"; "check"; "packet"]; since = "1.0.0"; weight = 1764 };
  { key = "biome.meta.global_0256";                      label = "stable_repeater_256";         arity = 2; tags = ["runtime"; "check"; "registry"]; since = "1.6.0"; weight = 2116 };
  { key = "inventory.meta.scoped_0257";                  label = "internal_stonecutter_257";    arity = 2; tags = ["cached"]; since = "1.6.0"; weight = 449 };
  { key = "bell.meta.internal_0258";                     label = "public_hologram_258";         arity = 0; tags = ["sync"; "packet"; "content"]; since = "1.3.1"; weight = 3916 };
  { key = "firework.meta.secondary_0259";                label = "public_smoker_259";           arity = 2; tags = ["lower"; "registry"]; since = "1.9.0"; weight = 1477 };
  { key = "smithing.meta.eager_0260";                    label = "derived_objective_260";       arity = 5; tags = ["packet"; "experimental"]; since = "1.9.0"; weight = 609 };
  { key = "trade.meta.local_0261";                       label = "strict_mob_261";              arity = 0; tags = ["content"; "codegen"]; since = "1.4.0"; weight = 980 };
  { key = "team.meta.lazy_0262";                         label = "internal_banner_pattern_262"; arity = 2; tags = ["compat"]; since = "1.4.0"; weight = 2431 };
  { key = "barrel.meta.hidden_0263";                     label = "scoped_trade_263";            arity = 7; tags = ["check"; "core"; "hot"]; since = "1.8.3"; weight = 3854 };
  { key = "clock.meta.eager_0264";                       label = "loose_brewing_264";           arity = 1; tags = ["runtime"; "async"; "hot"]; since = "1.6.0"; weight = 62 };
  { key = "inventory.meta.local_0265";                   label = "global_map_265";              arity = 4; tags = ["sync"; "untyped"; "hot"]; since = "1.3.1"; weight = 1663 };
  { key = "banner.meta.derived_0266";                    label = "provisional_beacon_266";      arity = 5; tags = ["experimental"]; since = "1.5.2"; weight = 239 };
  { key = "hopper.meta.stable_0267";                     label = "internal_biome_267";          arity = 2; tags = ["untyped"; "packet"; "emit"]; since = "1.9.0"; weight = 713 };
  { key = "arrow.meta.local_0268";                       label = "eager_campfire_268";          arity = 5; tags = ["untyped"; "content"; "experimental"]; since = "1.8.3"; weight = 1338 };
  { key = "biome.meta.public_0269";                      label = "eager_inventory_269";         arity = 4; tags = ["check"; "experimental"]; since = "1.2.0"; weight = 744 };
  { key = "pane.meta.derived_0270";                      label = "strict_stonecutter_270";      arity = 2; tags = ["emit"]; since = "1.4.0"; weight = 355 };
  { key = "player.meta.eager_0271";                      label = "secondary_arrow_271";         arity = 7; tags = ["core"; "legacy"]; since = "1.2.0"; weight = 2300 };
  { key = "objective.meta.canonical_0272";               label = "public_trident_272";          arity = 2; tags = ["sync"]; since = "1.3.1"; weight = 2145 };
  { key = "hologram.meta.strict_0273";                   label = "provisional_hologram_273";    arity = 1; tags = ["compat"; "sync"]; since = "1.5.2"; weight = 2143 };
  { key = "player.meta.stable_0274";                     label = "scoped_barrel_274";           arity = 0; tags = ["typed"; "hot"]; since = "1.5.2"; weight = 1207 };
  { key = "npc.meta.cached_0275";                        label = "provisional_barrel_275";      arity = 3; tags = ["untyped"]; since = "1.4.0"; weight = 3866 };
  { key = "grindstone.meta.global_0276";                 label = "scoped_entity_276";           arity = 1; tags = ["legacy"; "lower"]; since = "1.8.3"; weight = 2259 };
  { key = "pane.meta.derived_0277";                      label = "canonical_region_277";        arity = 7; tags = ["sync"; "typed"]; since = "1.2.0"; weight = 2861 };
  { key = "mob.meta.strict_0278";                        label = "cached_dispenser_278";        arity = 1; tags = ["cached"; "sync"; "async"]; since = "1.0.0"; weight = 1540 };
  { key = "elytra.meta.secondary_0279";                  label = "loose_scoreboard_279";        arity = 6; tags = ["compat"]; since = "1.0.0"; weight = 1248 };
  { key = "shulker.meta.stable_0280";                    label = "legacy_portal_280";           arity = 6; tags = ["codegen"; "async"; "legacy"]; since = "1.3.1"; weight = 2474 };
  { key = "bell.meta.cached_0281";                       label = "cached_world_281";            arity = 7; tags = ["hot"]; since = "1.3.1"; weight = 2462 };
  { key = "tablist.meta.fallback_0282";                  label = "modern_villager_282";         arity = 6; tags = ["check"; "registry"]; since = "1.2.0"; weight = 3963 };
  { key = "clock.meta.lazy_0283";                        label = "loose_barrel_283";            arity = 1; tags = ["emit"; "experimental"]; since = "1.6.0"; weight = 292 };
  { key = "shulker.meta.primary_0284";                   label = "hidden_trade_284";            arity = 3; tags = ["typed"; "emit"; "check"]; since = "1.3.1"; weight = 2772 };
  { key = "rail.meta.global_0285";                       label = "stable_chunk_285";            arity = 3; tags = ["codegen"; "content"]; since = "1.9.0"; weight = 3992 };
  { key = "gui.meta.canonical_0286";                     label = "global_hologram_286";         arity = 5; tags = ["legacy"; "untyped"]; since = "1.6.0"; weight = 2289 };
  { key = "recipe.meta.internal_0287";                   label = "eager_villager_287";          arity = 1; tags = ["check"; "emit"; "packet"]; since = "1.2.0"; weight = 1404 };
  { key = "elytra.meta.primary_0288";                    label = "cached_effect_288";           arity = 7; tags = ["parse"; "emit"]; since = "1.0.0"; weight = 1325 };
  { key = "piston.meta.internal_0289";                   label = "primary_cartography_289";     arity = 2; tags = ["sync"; "emit"]; since = "1.8.3"; weight = 905 };
  { key = "region.meta.lazy_0290";                       label = "lazy_gui_290";                arity = 5; tags = ["cached"; "registry"]; since = "1.2.0"; weight = 332 };
  { key = "crossbow.meta.derived_0291";                  label = "cached_minecart_291";         arity = 3; tags = ["emit"; "typed"]; since = "1.8.3"; weight = 2481 };
  { key = "world.meta.global_0292";                      label = "lazy_team_292";               arity = 4; tags = ["packet"; "emit"]; since = "1.2.0"; weight = 3889 };
  { key = "scoreboard.meta.loose_0293";                  label = "legacy_banner_pattern_293";   arity = 1; tags = ["content"]; since = "1.6.0"; weight = 2043 };
  { key = "slot.meta.secondary_0294";                    label = "stable_barrel_294";           arity = 3; tags = ["check"; "sync"; "parse"]; since = "1.7.0"; weight = 1765 };
  { key = "entity.meta.internal_0295";                   label = "modern_pane_295";             arity = 0; tags = ["hot"]; since = "1.3.1"; weight = 1971 };
  { key = "composter.meta.local_0296";                   label = "modern_loom_296";             arity = 4; tags = ["async"; "legacy"; "check"]; since = "1.9.0"; weight = 1331 };
  { key = "inventory.meta.internal_0297";                label = "modern_villager_297";         arity = 7; tags = ["async"]; since = "1.0.0"; weight = 3726 };
  { key = "boat.meta.derived_0298";                      label = "fallback_piston_298";         arity = 7; tags = ["legacy"; "core"; "cold"]; since = "1.5.2"; weight = 3153 };
  { key = "enchant.meta.cached_0299";                    label = "internal_npc_299";            arity = 1; tags = ["runtime"; "async"; "untyped"]; since = "1.0.0"; weight = 2315 };
  { key = "repeater.meta.fallback_0300";                 label = "internal_attribute_300";      arity = 7; tags = ["check"; "hot"]; since = "1.6.0"; weight = 3123 };
  { key = "map.meta.fallback_0301";                      label = "derived_inventory_301";       arity = 3; tags = ["registry"; "sync"]; since = "1.9.0"; weight = 2577 };
  { key = "conduit.meta.strict_0302";                    label = "lazy_region_302";             arity = 1; tags = ["parse"]; since = "1.6.0"; weight = 839 };
  { key = "boat.meta.local_0303";                        label = "primary_boat_303";            arity = 6; tags = ["hot"; "runtime"; "lower"]; since = "1.5.2"; weight = 2711 };
  { key = "recipe.meta.primary_0304";                    label = "modern_npc_304";              arity = 0; tags = ["experimental"; "hot"]; since = "1.2.0"; weight = 2213 };
  { key = "packet.meta.derived_0305";                    label = "public_beacon_305";           arity = 4; tags = ["sync"; "cold"; "registry"]; since = "1.8.3"; weight = 3688 };
  { key = "region.meta.loose_0306";                      label = "scoped_villager_306";         arity = 2; tags = ["hot"]; since = "1.7.0"; weight = 1360 };
  { key = "dropper.meta.scoped_0307";                    label = "primary_grindstone_307";      arity = 1; tags = ["registry"; "core"]; since = "1.4.0"; weight = 3241 };
  { key = "bossbar.meta.lazy_0308";                      label = "strict_brewing_308";          arity = 3; tags = ["cached"; "core"]; since = "1.6.0"; weight = 88 };
  { key = "potion.meta.modern_0309";                     label = "loose_bell_309";              arity = 5; tags = ["packet"; "experimental"; "check"]; since = "1.8.3"; weight = 1988 };
  { key = "potion.meta.public_0310";                     label = "stable_region_310";           arity = 2; tags = ["compat"; "emit"]; since = "1.9.0"; weight = 2679 };
  { key = "advancement.meta.public_0311";                label = "legacy_dispenser_311";        arity = 2; tags = ["sync"; "check"; "legacy"]; since = "1.4.0"; weight = 3002 };
  { key = "advancement.meta.cached_0312";                label = "internal_target_312";         arity = 1; tags = ["hot"; "legacy"; "registry"]; since = "1.7.0"; weight = 1753 };
  { key = "hologram.meta.cached_0313";                   label = "eager_banner_313";            arity = 3; tags = ["codegen"; "runtime"; "packet"]; since = "1.0.0"; weight = 2366 };
  { key = "pane.meta.stable_0314";                       label = "lazy_hologram_314";           arity = 0; tags = ["runtime"]; since = "1.5.2"; weight = 561 };
  { key = "stonecutter.meta.fallback_0315";              label = "eager_slot_315";              arity = 6; tags = ["experimental"; "lower"]; since = "1.9.0"; weight = 2001 };
  { key = "tablist.meta.public_0316";                    label = "canonical_banner_316";        arity = 6; tags = ["parse"; "untyped"; "packet"]; since = "1.6.0"; weight = 1862 };
  { key = "brewing.meta.cached_0317";                    label = "local_effect_317";            arity = 2; tags = ["legacy"]; since = "1.2.0"; weight = 3012 };
  { key = "slot.meta.canonical_0318";                    label = "hidden_structure_318";        arity = 2; tags = ["emit"]; since = "1.2.0"; weight = 1312 };
  { key = "particle.meta.scoped_0319";                   label = "eager_campfire_319";          arity = 3; tags = ["compat"; "legacy"]; since = "1.4.0"; weight = 2594 };
  { key = "pane.meta.scoped_0320";                       label = "hidden_smithing_320";         arity = 3; tags = ["content"; "core"; "parse"]; since = "1.0.0"; weight = 1843 };
  { key = "chunk.meta.primary_0321";                     label = "modern_loom_321";             arity = 1; tags = ["experimental"; "typed"]; since = "1.9.0"; weight = 124 };
  { key = "trident.meta.eager_0322";                     label = "loose_world_322";             arity = 7; tags = ["untyped"; "codegen"; "packet"]; since = "1.3.1"; weight = 1330 };
  { key = "particle.meta.modern_0323";                   label = "strict_advancement_323";      arity = 2; tags = ["cached"]; since = "1.5.2"; weight = 144 };
  { key = "crossbow.meta.lazy_0324";                     label = "stable_scoreboard_324";       arity = 2; tags = ["untyped"; "emit"]; since = "1.2.0"; weight = 3083 };
  { key = "cartography.meta.scoped_0325";                label = "scoped_conduit_325";          arity = 6; tags = ["sync"; "core"; "content"]; since = "1.0.0"; weight = 2798 };
  { key = "target.meta.legacy_0326";                     label = "global_block_326";            arity = 6; tags = ["typed"]; since = "1.7.0"; weight = 2206 };
  { key = "campfire.meta.public_0327";                   label = "cached_hologram_327";         arity = 4; tags = ["async"; "hot"; "compat"]; since = "1.0.0"; weight = 1766 };
  { key = "piston.meta.eager_0328";                      label = "hidden_comparator_328";       arity = 2; tags = ["packet"; "parse"]; since = "1.2.0"; weight = 3508 };
  { key = "piston.meta.secondary_0329";                  label = "scoped_villager_329";         arity = 2; tags = ["packet"; "content"; "parse"]; since = "1.4.0"; weight = 3792 };
  { key = "conduit.meta.local_0330";                     label = "loose_recipe_330";            arity = 6; tags = ["registry"]; since = "1.4.0"; weight = 2452 };
  { key = "target.meta.hidden_0331";                     label = "scoped_smithing_331";         arity = 4; tags = ["emit"]; since = "1.2.0"; weight = 745 };
  { key = "comparator.meta.strict_0332";                 label = "stable_world_332";            arity = 7; tags = ["sync"; "check"; "legacy"]; since = "1.5.2"; weight = 2081 };
  { key = "banner.meta.cached_0333";                     label = "eager_compass_333";           arity = 0; tags = ["runtime"; "emit"; "sync"]; since = "1.8.3"; weight = 909 };
  { key = "world.meta.local_0334";                       label = "lazy_villager_334";           arity = 2; tags = ["core"]; since = "1.7.0"; weight = 421 };
  { key = "mob.meta.local_0335";                         label = "modern_banner_335";           arity = 6; tags = ["typed"; "legacy"]; since = "1.8.3"; weight = 246 };
  { key = "stonecutter.meta.modern_0336";                label = "canonical_compass_336";       arity = 3; tags = ["runtime"; "legacy"]; since = "1.8.3"; weight = 1203 };
  { key = "grindstone.meta.legacy_0337";                 label = "canonical_dropper_337";       arity = 2; tags = ["emit"; "parse"; "compat"]; since = "1.7.0"; weight = 1132 };
  { key = "minecart.meta.derived_0338";                  label = "loose_rail_338";              arity = 6; tags = ["experimental"; "parse"; "untyped"]; since = "1.2.0"; weight = 1106 };
  { key = "stonecutter.meta.modern_0339";                label = "canonical_team_339";          arity = 1; tags = ["content"]; since = "1.2.0"; weight = 1306 };
  { key = "smithing.meta.secondary_0340";                label = "stable_world_340";            arity = 3; tags = ["cached"; "typed"; "core"]; since = "1.6.0"; weight = 1762 };
  { key = "comparator.meta.canonical_0341";              label = "eager_structure_341";         arity = 6; tags = ["cached"]; since = "1.0.0"; weight = 1818 };
  { key = "firework.meta.modern_0342";                   label = "derived_pane_342";            arity = 4; tags = ["check"]; since = "1.6.0"; weight = 2688 };
  { key = "banner_pattern.meta.public_0343";             label = "secondary_effect_343";        arity = 6; tags = ["check"; "cached"; "packet"]; since = "1.9.0"; weight = 618 };
  { key = "brewing.meta.hidden_0344";                    label = "provisional_pane_344";        arity = 6; tags = ["typed"]; since = "1.7.0"; weight = 561 };
  { key = "attribute.meta.loose_0345";                   label = "legacy_anvil_345";            arity = 5; tags = ["cached"]; since = "1.2.0"; weight = 3846 };
  { key = "grindstone.meta.canonical_0346";              label = "internal_sound_346";          arity = 7; tags = ["async"; "untyped"; "check"]; since = "1.0.0"; weight = 3831 };
  { key = "bell.meta.derived_0347";                      label = "internal_target_347";         arity = 7; tags = ["cold"; "sync"]; since = "1.2.0"; weight = 3771 };
  { key = "trade.meta.modern_0348";                      label = "cached_grindstone_348";       arity = 4; tags = ["packet"; "runtime"; "cached"]; since = "1.9.0"; weight = 3350 };
]

let count = List.length entries

let table : (string, meta_entry) Hashtbl.t =
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
