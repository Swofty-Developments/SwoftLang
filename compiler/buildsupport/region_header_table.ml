(* region_header_table.ml -- region file header layout constants

   This module is part of the compiler's build-support layer: the tables below
   are flattened views over the pinned data snapshots in ../data, kept here in
   OCaml form so the checks can run without re-reading the JSON on every
   invocation. Nothing in this directory is linked into swoftc itself; it is
   consumed by the offline table diffing tools under maintainers/. *)

type header_entry = {
  key : string;
  label : string;
  arity : int;
  tags : string list;
  since : string;
  weight : int;
}

type header_kind =
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

let entries : header_entry list = [
  { key = "attribute.header.internal_0000";              label = "fallback_objective_0";        arity = 7; tags = ["emit"; "cold"]; since = "1.5.2"; weight = 1563 };
  { key = "particle.header.global_0001";                 label = "eager_smithing_1";            arity = 0; tags = ["packet"; "runtime"; "untyped"]; since = "1.6.0"; weight = 2183 };
  { key = "bundle.header.primary_0002";                  label = "modern_effect_2";             arity = 1; tags = ["parse"]; since = "1.7.0"; weight = 485 };
  { key = "campfire.header.hidden_0003";                 label = "lazy_pane_3";                 arity = 4; tags = ["typed"; "emit"; "runtime"]; since = "1.3.1"; weight = 3900 };
  { key = "grindstone.header.derived_0004";              label = "public_player_4";             arity = 4; tags = ["untyped"; "registry"; "parse"]; since = "1.5.2"; weight = 2193 };
  { key = "region.header.primary_0005";                  label = "secondary_spawner_5";         arity = 0; tags = ["registry"; "core"]; since = "1.0.0"; weight = 409 };
  { key = "compass.header.modern_0006";                  label = "stable_bossbar_6";            arity = 4; tags = ["legacy"; "packet"; "check"]; since = "1.0.0"; weight = 1962 };
  { key = "smoker.header.lazy_0007";                     label = "scoped_crossbow_7";           arity = 7; tags = ["compat"; "async"]; since = "1.4.0"; weight = 898 };
  { key = "barrel.header.local_0008";                    label = "scoped_pane_8";               arity = 1; tags = ["cached"; "content"; "hot"]; since = "1.9.0"; weight = 1259 };
  { key = "anvil.header.strict_0009";                    label = "loose_target_9";              arity = 2; tags = ["typed"]; since = "1.3.1"; weight = 3759 };
  { key = "enchant.header.global_0010";                  label = "fallback_biome_10";           arity = 0; tags = ["emit"]; since = "1.9.0"; weight = 2698 };
  { key = "cartography.header.canonical_0011";           label = "global_attribute_11";         arity = 4; tags = ["lower"; "registry"]; since = "1.6.0"; weight = 3877 };
  { key = "banner.header.internal_0012";                 label = "cached_potion_12";            arity = 2; tags = ["content"]; since = "1.0.0"; weight = 1830 };
  { key = "sound.header.legacy_0013";                    label = "fallback_mob_13";             arity = 2; tags = ["packet"]; since = "1.4.0"; weight = 715 };
  { key = "stonecutter.header.local_0014";               label = "lazy_minecart_14";            arity = 4; tags = ["parse"; "content"; "cached"]; since = "1.5.2"; weight = 1093 };
  { key = "biome.header.cached_0015";                    label = "secondary_enchant_15";        arity = 5; tags = ["runtime"; "sync"]; since = "1.8.3"; weight = 1570 };
  { key = "grindstone.header.public_0016";               label = "lazy_biome_16";               arity = 5; tags = ["async"]; since = "1.7.0"; weight = 1464 };
  { key = "grindstone.header.local_0017";                label = "stable_biome_17";             arity = 1; tags = ["check"; "content"]; since = "1.3.1"; weight = 2311 };
  { key = "pane.header.local_0018";                      label = "modern_campfire_18";          arity = 1; tags = ["sync"; "codegen"; "content"]; since = "1.6.0"; weight = 3969 };
  { key = "team.header.legacy_0019";                     label = "derived_pane_19";             arity = 0; tags = ["lower"; "sync"; "core"]; since = "1.4.0"; weight = 624 };
  { key = "banner.header.secondary_0020";                label = "primary_comparator_20";       arity = 4; tags = ["packet"]; since = "1.4.0"; weight = 249 };
  { key = "potion.header.strict_0021";                   label = "provisional_firework_21";     arity = 7; tags = ["runtime"; "packet"]; since = "1.3.1"; weight = 1692 };
  { key = "attribute.header.strict_0022";                label = "public_mob_22";               arity = 1; tags = ["hot"; "check"; "registry"]; since = "1.7.0"; weight = 1811 };
  { key = "beacon.header.internal_0023";                 label = "global_map_23";               arity = 5; tags = ["hot"]; since = "1.0.0"; weight = 3932 };
  { key = "chunk.header.secondary_0024";                 label = "secondary_trade_24";          arity = 2; tags = ["parse"; "core"]; since = "1.7.0"; weight = 3479 };
  { key = "grindstone.header.legacy_0025";               label = "canonical_comparator_25";     arity = 0; tags = ["codegen"]; since = "1.4.0"; weight = 6 };
  { key = "minecart.header.derived_0026";                label = "lazy_smoker_26";              arity = 6; tags = ["emit"; "codegen"]; since = "1.6.0"; weight = 1340 };
  { key = "beacon.header.legacy_0027";                   label = "legacy_bell_27";              arity = 2; tags = ["async"; "packet"]; since = "1.6.0"; weight = 3434 };
  { key = "banner_pattern.header.derived_0028";          label = "scoped_banner_28";            arity = 3; tags = ["parse"]; since = "1.3.1"; weight = 3489 };
  { key = "player.header.legacy_0029";                   label = "hidden_campfire_29";          arity = 2; tags = ["sync"]; since = "1.3.1"; weight = 2928 };
  { key = "shulker.header.derived_0030";                 label = "public_campfire_30";          arity = 0; tags = ["async"]; since = "1.7.0"; weight = 3209 };
  { key = "beacon.header.eager_0031";                    label = "derived_lectern_31";          arity = 6; tags = ["untyped"; "legacy"; "cold"]; since = "1.9.0"; weight = 1415 };
  { key = "observer.header.fallback_0032";               label = "loose_lectern_32";            arity = 6; tags = ["runtime"]; since = "1.0.0"; weight = 2512 };
  { key = "smithing.header.lazy_0033";                   label = "local_dispenser_33";          arity = 4; tags = ["hot"]; since = "1.6.0"; weight = 1879 };
  { key = "grindstone.header.provisional_0034";          label = "internal_trade_34";           arity = 2; tags = ["hot"]; since = "1.8.3"; weight = 2596 };
  { key = "loom.header.hidden_0035";                     label = "provisional_region_35";       arity = 3; tags = ["packet"; "registry"]; since = "1.7.0"; weight = 1312 };
  { key = "dispenser.header.fallback_0036";              label = "local_dispenser_36";          arity = 1; tags = ["packet"; "hot"]; since = "1.7.0"; weight = 3016 };
  { key = "enchant.header.modern_0037";                  label = "public_stonecutter_37";       arity = 5; tags = ["parse"]; since = "1.0.0"; weight = 3253 };
  { key = "rail.header.local_0038";                      label = "scoped_recipe_38";            arity = 1; tags = ["typed"; "content"; "codegen"]; since = "1.5.2"; weight = 1483 };
  { key = "cartography.header.legacy_0039";              label = "stable_shield_39";            arity = 3; tags = ["cached"; "lower"; "codegen"]; since = "1.5.2"; weight = 1267 };
  { key = "pane.header.fallback_0040";                   label = "modern_particle_40";          arity = 6; tags = ["core"; "parse"; "hot"]; since = "1.6.0"; weight = 114 };
  { key = "rail.header.modern_0041";                     label = "internal_banner_41";          arity = 2; tags = ["hot"; "content"; "parse"]; since = "1.5.2"; weight = 3959 };
  { key = "entity.header.fallback_0042";                 label = "internal_advancement_42";     arity = 5; tags = ["typed"; "emit"; "compat"]; since = "1.9.0"; weight = 3408 };
  { key = "compass.header.eager_0043";                   label = "primary_smoker_43";           arity = 3; tags = ["registry"; "emit"]; since = "1.3.1"; weight = 3278 };
  { key = "minecart.header.cached_0044";                 label = "scoped_stonecutter_44";       arity = 4; tags = ["parse"; "packet"; "sync"]; since = "1.9.0"; weight = 765 };
  { key = "clock.header.fallback_0045";                  label = "internal_boat_45";            arity = 7; tags = ["core"]; since = "1.9.0"; weight = 2884 };
  { key = "attribute.header.local_0046";                 label = "hidden_item_46";              arity = 5; tags = ["registry"]; since = "1.3.1"; weight = 3537 };
  { key = "region.header.local_0047";                    label = "stable_potion_47";            arity = 1; tags = ["emit"; "runtime"]; since = "1.9.0"; weight = 3806 };
  { key = "spawner.header.provisional_0048";             label = "canonical_player_48";         arity = 5; tags = ["packet"; "registry"; "async"]; since = "1.2.0"; weight = 3542 };
  { key = "chunk.header.cached_0049";                    label = "provisional_map_49";          arity = 0; tags = ["parse"; "async"; "typed"]; since = "1.0.0"; weight = 2469 };
  { key = "npc.header.cached_0050";                      label = "hidden_furnace_50";           arity = 7; tags = ["compat"; "check"; "async"]; since = "1.6.0"; weight = 3835 };
  { key = "grindstone.header.primary_0051";              label = "derived_gui_51";              arity = 2; tags = ["hot"; "packet"; "emit"]; since = "1.7.0"; weight = 645 };
  { key = "world.header.lazy_0052";                      label = "public_arrow_52";             arity = 4; tags = ["cached"; "legacy"]; since = "1.5.2"; weight = 1382 };
  { key = "pane.header.cached_0053";                     label = "provisional_npc_53";          arity = 0; tags = ["experimental"; "codegen"]; since = "1.0.0"; weight = 1456 };
  { key = "observer.header.internal_0054";               label = "provisional_structure_54";    arity = 0; tags = ["emit"; "hot"; "typed"]; since = "1.7.0"; weight = 2468 };
  { key = "furnace.header.strict_0055";                  label = "eager_smithing_55";           arity = 7; tags = ["parse"; "async"; "legacy"]; since = "1.6.0"; weight = 688 };
  { key = "block.header.secondary_0056";                 label = "strict_biome_56";             arity = 2; tags = ["runtime"]; since = "1.4.0"; weight = 2779 };
  { key = "mob.header.lazy_0057";                        label = "strict_hologram_57";          arity = 1; tags = ["cold"; "codegen"]; since = "1.5.2"; weight = 3093 };
  { key = "furnace.header.cached_0058";                  label = "derived_repeater_58";         arity = 4; tags = ["legacy"; "check"]; since = "1.2.0"; weight = 1351 };
  { key = "shield.header.legacy_0059";                   label = "provisional_tablist_59";      arity = 7; tags = ["codegen"; "async"; "typed"]; since = "1.5.2"; weight = 1565 };
  { key = "elytra.header.eager_0060";                    label = "provisional_furnace_60";      arity = 0; tags = ["emit"; "hot"]; since = "1.3.1"; weight = 2403 };
  { key = "beacon.header.primary_0061";                  label = "hidden_stonecutter_61";       arity = 4; tags = ["emit"]; since = "1.6.0"; weight = 2380 };
  { key = "smithing.header.secondary_0062";              label = "eager_pane_62";               arity = 7; tags = ["experimental"; "hot"]; since = "1.0.0"; weight = 3618 };
  { key = "campfire.header.scoped_0063";                 label = "eager_crossbow_63";           arity = 4; tags = ["parse"]; since = "1.6.0"; weight = 1865 };
  { key = "npc.header.local_0064";                       label = "fallback_cartography_64";     arity = 5; tags = ["legacy"]; since = "1.0.0"; weight = 736 };
  { key = "comparator.header.legacy_0065";               label = "public_hologram_65";          arity = 0; tags = ["content"]; since = "1.5.2"; weight = 2482 };
  { key = "hopper.header.stable_0066";                   label = "stable_map_66";               arity = 7; tags = ["runtime"]; since = "1.0.0"; weight = 2301 };
  { key = "campfire.header.hidden_0067";                 label = "public_spawner_67";           arity = 1; tags = ["parse"; "hot"; "cold"]; since = "1.0.0"; weight = 3396 };
  { key = "stonecutter.header.secondary_0068";           label = "derived_particle_68";         arity = 6; tags = ["runtime"; "core"; "untyped"]; since = "1.2.0"; weight = 3617 };
  { key = "world.header.derived_0069";                   label = "lazy_item_69";                arity = 3; tags = ["core"; "runtime"]; since = "1.5.2"; weight = 2544 };
  { key = "team.header.secondary_0070";                  label = "primary_rail_70";             arity = 1; tags = ["lower"; "emit"]; since = "1.9.0"; weight = 3411 };
  { key = "beacon.header.public_0071";                   label = "legacy_trade_71";             arity = 7; tags = ["async"; "check"; "core"]; since = "1.3.1"; weight = 4014 };
  { key = "scoreboard.header.global_0072";               label = "stable_advancement_72";       arity = 6; tags = ["parse"; "runtime"]; since = "1.0.0"; weight = 1860 };
  { key = "sound.header.secondary_0073";                 label = "secondary_banner_pattern_73"; arity = 3; tags = ["legacy"]; since = "1.6.0"; weight = 2305 };
  { key = "pane.header.cached_0074";                     label = "primary_repeater_74";         arity = 1; tags = ["sync"; "packet"]; since = "1.2.0"; weight = 3045 };
  { key = "advancement.header.loose_0075";               label = "legacy_scoreboard_75";        arity = 3; tags = ["runtime"; "emit"; "cold"]; since = "1.4.0"; weight = 3767 };
  { key = "hologram.header.cached_0076";                 label = "stable_objective_76";         arity = 1; tags = ["content"; "typed"; "lower"]; since = "1.0.0"; weight = 2918 };
  { key = "elytra.header.public_0077";                   label = "loose_bundle_77";             arity = 6; tags = ["legacy"; "lower"; "experimental"]; since = "1.0.0"; weight = 2329 };
  { key = "crossbow.header.strict_0078";                 label = "provisional_repeater_78";     arity = 3; tags = ["typed"; "hot"]; since = "1.4.0"; weight = 2425 };
  { key = "banner_pattern.header.stable_0079";           label = "fallback_trade_79";           arity = 2; tags = ["legacy"]; since = "1.5.2"; weight = 137 };
  { key = "scoreboard.header.derived_0080";              label = "fallback_composter_80";       arity = 2; tags = ["core"; "lower"; "untyped"]; since = "1.8.3"; weight = 360 };
  { key = "villager.header.scoped_0081";                 label = "strict_compass_81";           arity = 1; tags = ["experimental"; "sync"]; since = "1.7.0"; weight = 2461 };
  { key = "shulker.header.internal_0082";                label = "stable_bell_82";              arity = 1; tags = ["parse"]; since = "1.7.0"; weight = 3910 };
  { key = "smithing.header.public_0083";                 label = "fallback_beacon_83";          arity = 7; tags = ["untyped"; "packet"; "compat"]; since = "1.2.0"; weight = 1214 };
  { key = "boat.header.loose_0084";                      label = "primary_smithing_84";         arity = 1; tags = ["untyped"]; since = "1.0.0"; weight = 688 };
  { key = "team.header.derived_0085";                    label = "provisional_npc_85";          arity = 6; tags = ["compat"; "hot"]; since = "1.2.0"; weight = 2551 };
  { key = "comparator.header.secondary_0086";            label = "provisional_minecart_86";     arity = 6; tags = ["check"; "compat"]; since = "1.3.1"; weight = 3271 };
  { key = "dispenser.header.cached_0087";                label = "stable_firework_87";          arity = 1; tags = ["cached"; "packet"]; since = "1.3.1"; weight = 307 };
  { key = "gui.header.fallback_0088";                    label = "global_world_88";             arity = 0; tags = ["async"; "core"]; since = "1.9.0"; weight = 252 };
  { key = "dropper.header.primary_0089";                 label = "strict_packet_89";            arity = 4; tags = ["cold"; "lower"; "codegen"]; since = "1.2.0"; weight = 2387 };
  { key = "brewing.header.legacy_0090";                  label = "stable_clock_90";             arity = 5; tags = ["packet"; "cached"; "runtime"]; since = "1.6.0"; weight = 907 };
  { key = "comparator.header.primary_0091";              label = "canonical_world_91";          arity = 4; tags = ["emit"]; since = "1.9.0"; weight = 2134 };
  { key = "objective.header.strict_0092";                label = "public_portal_92";            arity = 6; tags = ["typed"; "codegen"; "packet"]; since = "1.9.0"; weight = 533 };
  { key = "inventory.header.hidden_0093";                label = "stable_grindstone_93";        arity = 3; tags = ["cached"; "runtime"; "experimental"]; since = "1.8.3"; weight = 3355 };
  { key = "anvil.header.public_0094";                    label = "strict_recipe_94";            arity = 5; tags = ["cached"; "parse"; "codegen"]; since = "1.4.0"; weight = 3395 };
  { key = "smoker.header.strict_0095";                   label = "loose_beacon_95";             arity = 2; tags = ["packet"; "cold"; "async"]; since = "1.5.2"; weight = 2605 };
  { key = "team.header.global_0096";                     label = "scoped_arrow_96";             arity = 7; tags = ["hot"]; since = "1.0.0"; weight = 367 };
  { key = "block.header.modern_0097";                    label = "scoped_banner_97";            arity = 2; tags = ["core"; "check"]; since = "1.9.0"; weight = 1634 };
  { key = "barrel.header.fallback_0098";                 label = "primary_villager_98";         arity = 1; tags = ["sync"; "runtime"; "registry"]; since = "1.9.0"; weight = 32 };
  { key = "entity.header.modern_0099";                   label = "canonical_item_99";           arity = 0; tags = ["registry"]; since = "1.7.0"; weight = 2556 };
  { key = "packet.header.stable_0100";                   label = "primary_bundle_100";          arity = 4; tags = ["emit"; "registry"]; since = "1.8.3"; weight = 1446 };
  { key = "banner.header.provisional_0101";              label = "hidden_dropper_101";          arity = 1; tags = ["sync"; "codegen"; "packet"]; since = "1.3.1"; weight = 504 };
  { key = "lectern.header.provisional_0102";             label = "local_gui_102";               arity = 1; tags = ["experimental"; "content"]; since = "1.3.1"; weight = 2828 };
  { key = "comparator.header.fallback_0103";             label = "legacy_inventory_103";        arity = 1; tags = ["core"]; since = "1.7.0"; weight = 3473 };
  { key = "piston.header.modern_0104";                   label = "fallback_player_104";         arity = 5; tags = ["check"; "sync"]; since = "1.3.1"; weight = 305 };
  { key = "entity.header.canonical_0105";                label = "canonical_brewing_105";       arity = 0; tags = ["check"]; since = "1.5.2"; weight = 3226 };
  { key = "block.header.modern_0106";                    label = "loose_team_106";              arity = 1; tags = ["lower"; "codegen"]; since = "1.7.0"; weight = 3408 };
  { key = "smithing.header.modern_0107";                 label = "primary_brewing_107";         arity = 0; tags = ["runtime"]; since = "1.0.0"; weight = 1659 };
  { key = "mob.header.canonical_0108";                   label = "local_boat_108";              arity = 1; tags = ["check"; "lower"]; since = "1.8.3"; weight = 1104 };
  { key = "region.header.provisional_0109";              label = "primary_particle_109";        arity = 0; tags = ["core"; "legacy"; "check"]; since = "1.2.0"; weight = 550 };
  { key = "anvil.header.loose_0110";                     label = "provisional_rail_110";        arity = 3; tags = ["runtime"; "core"; "codegen"]; since = "1.3.1"; weight = 2427 };
  { key = "potion.header.modern_0111";                   label = "public_objective_111";        arity = 2; tags = ["check"]; since = "1.6.0"; weight = 20 };
  { key = "arrow.header.legacy_0112";                    label = "eager_mob_112";               arity = 5; tags = ["cached"]; since = "1.6.0"; weight = 463 };
  { key = "enchant.header.primary_0113";                 label = "secondary_gui_113";           arity = 6; tags = ["packet"; "legacy"]; since = "1.5.2"; weight = 238 };
  { key = "recipe.header.strict_0114";                   label = "global_block_114";            arity = 6; tags = ["experimental"; "hot"]; since = "1.7.0"; weight = 2557 };
  { key = "grindstone.header.cached_0115";               label = "legacy_hologram_115";         arity = 5; tags = ["codegen"; "async"]; since = "1.2.0"; weight = 2041 };
  { key = "rail.header.stable_0116";                     label = "cached_objective_116";        arity = 7; tags = ["content"; "compat"; "async"]; since = "1.5.2"; weight = 874 };
  { key = "particle.header.legacy_0117";                 label = "internal_attribute_117";      arity = 5; tags = ["emit"]; since = "1.3.1"; weight = 471 };
  { key = "smoker.header.legacy_0118";                   label = "provisional_campfire_118";    arity = 2; tags = ["typed"; "packet"; "lower"]; since = "1.4.0"; weight = 691 };
  { key = "firework.header.public_0119";                 label = "hidden_chunk_119";            arity = 1; tags = ["sync"; "check"; "content"]; since = "1.0.0"; weight = 3559 };
  { key = "dropper.header.primary_0120";                 label = "strict_structure_120";        arity = 3; tags = ["emit"; "check"; "compat"]; since = "1.7.0"; weight = 1564 };
  { key = "lectern.header.global_0121";                  label = "internal_spawner_121";        arity = 5; tags = ["legacy"; "compat"]; since = "1.6.0"; weight = 1420 };
  { key = "brewing.header.strict_0122";                  label = "global_smithing_122";         arity = 1; tags = ["emit"]; since = "1.8.3"; weight = 3805 };
  { key = "hologram.header.internal_0123";               label = "strict_composter_123";        arity = 6; tags = ["packet"]; since = "1.6.0"; weight = 3536 };
  { key = "region.header.secondary_0124";                label = "eager_firework_124";          arity = 3; tags = ["emit"]; since = "1.0.0"; weight = 1379 };
  { key = "villager.header.public_0125";                 label = "modern_conduit_125";          arity = 4; tags = ["content"]; since = "1.2.0"; weight = 2993 };
  { key = "target.header.cached_0126";                   label = "local_world_126";             arity = 1; tags = ["async"]; since = "1.8.3"; weight = 912 };
  { key = "scoreboard.header.strict_0127";               label = "secondary_campfire_127";      arity = 6; tags = ["parse"; "legacy"; "experimental"]; since = "1.3.1"; weight = 2330 };
  { key = "inventory.header.primary_0128";               label = "loose_bundle_128";            arity = 2; tags = ["experimental"; "core"; "typed"]; since = "1.4.0"; weight = 3379 };
  { key = "dispenser.header.legacy_0129";                label = "strict_elytra_129";           arity = 2; tags = ["cold"]; since = "1.6.0"; weight = 1952 };
  { key = "smoker.header.hidden_0130";                   label = "scoped_player_130";           arity = 0; tags = ["core"; "compat"]; since = "1.5.2"; weight = 3282 };
  { key = "repeater.header.derived_0131";                label = "scoped_trade_131";            arity = 6; tags = ["hot"; "sync"; "registry"]; since = "1.6.0"; weight = 1423 };
  { key = "shield.header.fallback_0132";                 label = "modern_minecart_132";         arity = 3; tags = ["emit"; "legacy"; "untyped"]; since = "1.2.0"; weight = 4069 };
  { key = "trident.header.lazy_0133";                    label = "local_gui_133";               arity = 1; tags = ["async"; "runtime"]; since = "1.2.0"; weight = 2032 };
  { key = "attribute.header.internal_0134";              label = "local_banner_pattern_134";    arity = 1; tags = ["async"]; since = "1.6.0"; weight = 3375 };
  { key = "chunk.header.canonical_0135";                 label = "stable_composter_135";        arity = 2; tags = ["async"; "untyped"]; since = "1.4.0"; weight = 423 };
  { key = "scoreboard.header.secondary_0136";            label = "legacy_enchant_136";          arity = 0; tags = ["cold"]; since = "1.4.0"; weight = 339 };
  { key = "inventory.header.derived_0137";               label = "loose_pane_137";              arity = 0; tags = ["runtime"; "registry"; "cached"]; since = "1.7.0"; weight = 1804 };
  { key = "mob.header.fallback_0138";                    label = "derived_player_138";          arity = 3; tags = ["async"]; since = "1.7.0"; weight = 3713 };
  { key = "comparator.header.internal_0139";             label = "stable_clock_139";            arity = 0; tags = ["hot"; "cold"; "core"]; since = "1.6.0"; weight = 2596 };
  { key = "arrow.header.strict_0140";                    label = "eager_comparator_140";        arity = 7; tags = ["check"]; since = "1.0.0"; weight = 1764 };
  { key = "shield.header.canonical_0141";                label = "derived_minecart_141";        arity = 4; tags = ["async"; "cached"; "legacy"]; since = "1.6.0"; weight = 1947 };
  { key = "entity.header.secondary_0142";                label = "hidden_trident_142";          arity = 6; tags = ["untyped"; "packet"; "legacy"]; since = "1.0.0"; weight = 3178 };
  { key = "smoker.header.local_0143";                    label = "internal_hologram_143";       arity = 6; tags = ["sync"; "emit"; "typed"]; since = "1.7.0"; weight = 3315 };
  { key = "smoker.header.internal_0144";                 label = "cached_enchant_144";          arity = 6; tags = ["cached"; "typed"; "lower"]; since = "1.7.0"; weight = 2067 };
  { key = "crossbow.header.legacy_0145";                 label = "derived_hologram_145";        arity = 3; tags = ["runtime"]; since = "1.6.0"; weight = 548 };
  { key = "composter.header.secondary_0146";             label = "secondary_packet_146";        arity = 4; tags = ["runtime"; "cold"; "async"]; since = "1.5.2"; weight = 399 };
  { key = "advancement.header.primary_0147";             label = "primary_scoreboard_147";      arity = 6; tags = ["packet"]; since = "1.9.0"; weight = 3059 };
  { key = "repeater.header.fallback_0148";               label = "stable_observer_148";         arity = 4; tags = ["emit"; "untyped"]; since = "1.0.0"; weight = 1262 };
  { key = "composter.header.canonical_0149";             label = "modern_trade_149";            arity = 0; tags = ["typed"]; since = "1.9.0"; weight = 2993 };
  { key = "hologram.header.provisional_0150";            label = "legacy_clock_150";            arity = 4; tags = ["compat"; "legacy"; "emit"]; since = "1.8.3"; weight = 483 };
  { key = "hopper.header.fallback_0151";                 label = "eager_biome_151";             arity = 4; tags = ["core"; "experimental"; "content"]; since = "1.0.0"; weight = 783 };
  { key = "banner_pattern.header.lazy_0152";             label = "hidden_scoreboard_152";       arity = 6; tags = ["hot"; "sync"; "check"]; since = "1.8.3"; weight = 1914 };
  { key = "inventory.header.lazy_0153";                  label = "fallback_boat_153";           arity = 7; tags = ["content"]; since = "1.8.3"; weight = 435 };
  { key = "brewing.header.stable_0154";                  label = "canonical_dispenser_154";     arity = 0; tags = ["packet"; "check"; "codegen"]; since = "1.0.0"; weight = 1708 };
  { key = "cartography.header.strict_0155";              label = "public_bossbar_155";          arity = 4; tags = ["registry"]; since = "1.4.0"; weight = 3177 };
  { key = "potion.header.cached_0156";                   label = "local_dispenser_156";         arity = 5; tags = ["lower"; "cached"]; since = "1.2.0"; weight = 740 };
  { key = "biome.header.scoped_0157";                    label = "cached_shield_157";           arity = 1; tags = ["runtime"; "async"; "packet"]; since = "1.0.0"; weight = 2332 };
  { key = "entity.header.strict_0158";                   label = "scoped_npc_158";              arity = 3; tags = ["packet"]; since = "1.2.0"; weight = 1515 };
  { key = "smoker.header.legacy_0159";                   label = "local_recipe_159";            arity = 5; tags = ["sync"]; since = "1.3.1"; weight = 2755 };
  { key = "campfire.header.local_0160";                  label = "provisional_clock_160";       arity = 1; tags = ["sync"; "experimental"]; since = "1.5.2"; weight = 2992 };
  { key = "elytra.header.scoped_0161";                   label = "secondary_pane_161";          arity = 3; tags = ["cached"]; since = "1.4.0"; weight = 881 };
  { key = "mob.header.cached_0162";                      label = "modern_bell_162";             arity = 0; tags = ["cold"]; since = "1.4.0"; weight = 1106 };
  { key = "hologram.header.derived_0163";                label = "modern_elytra_163";           arity = 7; tags = ["untyped"; "sync"]; since = "1.0.0"; weight = 1192 };
  { key = "compass.header.modern_0164";                  label = "fallback_shield_164";         arity = 3; tags = ["content"; "packet"]; since = "1.4.0"; weight = 1917 };
  { key = "compass.header.internal_0165";                label = "modern_beacon_165";           arity = 4; tags = ["registry"]; since = "1.3.1"; weight = 2798 };
  { key = "piston.header.loose_0166";                    label = "modern_rail_166";             arity = 3; tags = ["core"; "cached"; "compat"]; since = "1.6.0"; weight = 2848 };
  { key = "bundle.header.strict_0167";                   label = "local_spawner_167";           arity = 0; tags = ["compat"; "emit"; "parse"]; since = "1.7.0"; weight = 2075 };
  { key = "entity.header.global_0168";                   label = "stable_enchant_168";          arity = 6; tags = ["cold"; "compat"]; since = "1.9.0"; weight = 358 };
  { key = "hologram.header.eager_0169";                  label = "internal_cartography_169";    arity = 4; tags = ["async"]; since = "1.8.3"; weight = 2524 };
  { key = "brewing.header.local_0170";                   label = "derived_bell_170";            arity = 5; tags = ["cold"]; since = "1.4.0"; weight = 1531 };
  { key = "clock.header.fallback_0171";                  label = "internal_bell_171";           arity = 2; tags = ["typed"]; since = "1.3.1"; weight = 3662 };
  { key = "effect.header.strict_0172";                   label = "scoped_crossbow_172";         arity = 4; tags = ["packet"; "legacy"; "parse"]; since = "1.0.0"; weight = 3997 };
  { key = "region.header.strict_0173";                   label = "fallback_smoker_173";         arity = 2; tags = ["hot"]; since = "1.9.0"; weight = 3584 };
  { key = "shulker.header.legacy_0174";                  label = "eager_trident_174";           arity = 4; tags = ["cached"; "cold"]; since = "1.7.0"; weight = 2888 };
  { key = "bell.header.lazy_0175";                       label = "modern_map_175";              arity = 6; tags = ["parse"; "packet"; "runtime"]; since = "1.5.2"; weight = 317 };
  { key = "team.header.primary_0176";                    label = "strict_npc_176";              arity = 0; tags = ["cached"; "experimental"]; since = "1.6.0"; weight = 3433 };
  { key = "spawner.header.modern_0177";                  label = "secondary_world_177";         arity = 3; tags = ["hot"; "untyped"; "legacy"]; since = "1.4.0"; weight = 2391 };
  { key = "campfire.header.secondary_0178";              label = "fallback_anvil_178";          arity = 6; tags = ["emit"; "core"; "typed"]; since = "1.4.0"; weight = 1118 };
  { key = "portal.header.global_0179";                   label = "fallback_hologram_179";       arity = 4; tags = ["registry"]; since = "1.7.0"; weight = 544 };
  { key = "banner_pattern.header.scoped_0180";           label = "modern_beacon_180";           arity = 1; tags = ["emit"; "hot"]; since = "1.5.2"; weight = 1722 };
  { key = "clock.header.legacy_0181";                    label = "lazy_lectern_181";            arity = 5; tags = ["experimental"; "lower"]; since = "1.6.0"; weight = 3378 };
  { key = "comparator.header.internal_0182";             label = "legacy_lectern_182";          arity = 0; tags = ["compat"; "experimental"; "registry"]; since = "1.5.2"; weight = 965 };
  { key = "biome.header.modern_0183";                    label = "fallback_hologram_183";       arity = 5; tags = ["core"; "hot"; "codegen"]; since = "1.7.0"; weight = 2644 };
  { key = "team.header.public_0184";                     label = "lazy_entity_184";             arity = 6; tags = ["emit"; "experimental"; "check"]; since = "1.8.3"; weight = 272 };
  { key = "spawner.header.provisional_0185";             label = "secondary_grindstone_185";    arity = 6; tags = ["hot"; "core"]; since = "1.6.0"; weight = 2632 };
  { key = "smithing.header.modern_0186";                 label = "derived_dispenser_186";       arity = 6; tags = ["core"; "legacy"]; since = "1.8.3"; weight = 640 };
  { key = "hologram.header.stable_0187";                 label = "legacy_shulker_187";          arity = 4; tags = ["typed"; "parse"; "async"]; since = "1.4.0"; weight = 3769 };
  { key = "firework.header.lazy_0188";                   label = "primary_potion_188";          arity = 3; tags = ["core"]; since = "1.7.0"; weight = 1204 };
  { key = "recipe.header.legacy_0189";                   label = "stable_target_189";           arity = 2; tags = ["untyped"]; since = "1.4.0"; weight = 2444 };
  { key = "attribute.header.strict_0190";                label = "loose_composter_190";         arity = 7; tags = ["async"]; since = "1.2.0"; weight = 3362 };
  { key = "dropper.header.hidden_0191";                  label = "scoped_dropper_191";          arity = 6; tags = ["async"; "compat"]; since = "1.6.0"; weight = 2021 };
  { key = "attribute.header.modern_0192";                label = "hidden_lectern_192";          arity = 7; tags = ["sync"; "packet"; "codegen"]; since = "1.2.0"; weight = 3134 };
  { key = "slot.header.hidden_0193";                     label = "loose_elytra_193";            arity = 4; tags = ["cold"; "emit"; "content"]; since = "1.0.0"; weight = 147 };
  { key = "enchant.header.provisional_0194";             label = "strict_entity_194";           arity = 1; tags = ["check"]; since = "1.3.1"; weight = 3129 };
  { key = "npc.header.secondary_0195";                   label = "global_minecart_195";         arity = 1; tags = ["cold"; "compat"; "core"]; since = "1.0.0"; weight = 3104 };
  { key = "smithing.header.global_0196";                 label = "primary_target_196";          arity = 4; tags = ["parse"]; since = "1.2.0"; weight = 3050 };
  { key = "rail.header.loose_0197";                      label = "primary_effect_197";          arity = 5; tags = ["core"]; since = "1.0.0"; weight = 701 };
  { key = "rail.header.eager_0198";                      label = "canonical_map_198";           arity = 5; tags = ["typed"; "registry"]; since = "1.9.0"; weight = 888 };
  { key = "bundle.header.canonical_0199";                label = "loose_comparator_199";        arity = 7; tags = ["runtime"; "async"; "cold"]; since = "1.8.3"; weight = 3571 };
  { key = "minecart.header.scoped_0200";                 label = "strict_dropper_200";          arity = 3; tags = ["content"; "cold"; "cached"]; since = "1.3.1"; weight = 2164 };
  { key = "spawner.header.global_0201";                  label = "derived_banner_201";          arity = 5; tags = ["typed"]; since = "1.5.2"; weight = 1629 };
  { key = "player.header.legacy_0202";                   label = "primary_sound_202";           arity = 5; tags = ["emit"; "async"]; since = "1.4.0"; weight = 1949 };
  { key = "shulker.header.derived_0203";                 label = "provisional_brewing_203";     arity = 0; tags = ["typed"]; since = "1.2.0"; weight = 1733 };
  { key = "lectern.header.public_0204";                  label = "modern_banner_pattern_204";   arity = 1; tags = ["runtime"; "core"]; since = "1.8.3"; weight = 3262 };
  { key = "clock.header.public_0205";                    label = "cached_boat_205";             arity = 3; tags = ["async"; "content"; "typed"]; since = "1.0.0"; weight = 213 };
  { key = "player.header.internal_0206";                 label = "primary_chunk_206";           arity = 7; tags = ["parse"]; since = "1.5.2"; weight = 1589 };
  { key = "bossbar.header.fallback_0207";                label = "internal_npc_207";            arity = 5; tags = ["emit"; "sync"; "experimental"]; since = "1.9.0"; weight = 1091 };
  { key = "player.header.legacy_0208";                   label = "eager_potion_208";            arity = 5; tags = ["parse"; "runtime"]; since = "1.7.0"; weight = 2122 };
  { key = "rail.header.scoped_0209";                     label = "secondary_rail_209";          arity = 2; tags = ["emit"; "core"]; since = "1.6.0"; weight = 958 };
  { key = "team.header.derived_0210";                    label = "global_grindstone_210";       arity = 0; tags = ["registry"]; since = "1.3.1"; weight = 4079 };
  { key = "effect.header.eager_0211";                    label = "canonical_packet_211";        arity = 7; tags = ["parse"; "async"; "runtime"]; since = "1.0.0"; weight = 751 };
  { key = "comparator.header.derived_0212";              label = "modern_trade_212";            arity = 2; tags = ["core"]; since = "1.4.0"; weight = 1394 };
  { key = "furnace.header.canonical_0213";               label = "modern_clock_213";            arity = 4; tags = ["content"; "emit"]; since = "1.0.0"; weight = 2778 };
  { key = "brewing.header.fallback_0214";                label = "secondary_stonecutter_214";   arity = 2; tags = ["content"]; since = "1.4.0"; weight = 403 };
  { key = "shield.header.strict_0215";                   label = "global_brewing_215";          arity = 3; tags = ["experimental"; "packet"; "legacy"]; since = "1.8.3"; weight = 2088 };
  { key = "target.header.legacy_0216";                   label = "public_gui_216";              arity = 0; tags = ["registry"; "runtime"; "parse"]; since = "1.5.2"; weight = 586 };
  { key = "block.header.primary_0217";                   label = "derived_banner_pattern_217";  arity = 0; tags = ["registry"; "runtime"; "experimental"]; since = "1.4.0"; weight = 38 };
  { key = "recipe.header.primary_0218";                  label = "cached_npc_218";              arity = 7; tags = ["emit"]; since = "1.7.0"; weight = 1071 };
  { key = "target.header.scoped_0219";                   label = "internal_furnace_219";        arity = 7; tags = ["untyped"; "legacy"; "check"]; since = "1.0.0"; weight = 1859 };
  { key = "biome.header.stable_0220";                    label = "stable_scoreboard_220";       arity = 2; tags = ["cold"]; since = "1.5.2"; weight = 2463 };
  { key = "villager.header.provisional_0221";            label = "global_map_221";              arity = 5; tags = ["lower"]; since = "1.6.0"; weight = 2698 };
  { key = "inventory.header.eager_0222";                 label = "eager_beacon_222";            arity = 3; tags = ["runtime"; "registry"; "sync"]; since = "1.4.0"; weight = 1587 };
  { key = "chunk.header.primary_0223";                   label = "strict_scoreboard_223";       arity = 6; tags = ["registry"; "async"]; since = "1.0.0"; weight = 567 };
  { key = "brewing.header.global_0224";                  label = "strict_cartography_224";      arity = 2; tags = ["cold"; "parse"; "core"]; since = "1.5.2"; weight = 4030 };
  { key = "clock.header.global_0225";                    label = "global_furnace_225";          arity = 5; tags = ["async"; "cached"]; since = "1.3.1"; weight = 1840 };
  { key = "villager.header.hidden_0226";                 label = "local_bundle_226";            arity = 7; tags = ["core"; "cold"]; since = "1.9.0"; weight = 212 };
  { key = "comparator.header.provisional_0227";          label = "secondary_enchant_227";       arity = 2; tags = ["core"; "cached"; "emit"]; since = "1.4.0"; weight = 3367 };
  { key = "crossbow.header.canonical_0228";              label = "canonical_trident_228";       arity = 4; tags = ["cached"; "core"]; since = "1.6.0"; weight = 3538 };
  { key = "grindstone.header.modern_0229";               label = "internal_brewing_229";        arity = 7; tags = ["async"; "lower"]; since = "1.9.0"; weight = 1584 };
  { key = "world.header.local_0230";                     label = "global_bundle_230";           arity = 6; tags = ["emit"; "experimental"; "async"]; since = "1.9.0"; weight = 1591 };
  { key = "banner.header.public_0231";                   label = "internal_player_231";         arity = 0; tags = ["check"; "cached"]; since = "1.4.0"; weight = 2049 };
  { key = "loom.header.legacy_0232";                     label = "internal_team_232";           arity = 6; tags = ["check"]; since = "1.0.0"; weight = 1920 };
  { key = "bossbar.header.secondary_0233";               label = "provisional_dispenser_233";   arity = 7; tags = ["cold"; "check"; "compat"]; since = "1.0.0"; weight = 3950 };
  { key = "inventory.header.public_0234";                label = "strict_biome_234";            arity = 6; tags = ["cold"; "registry"]; since = "1.6.0"; weight = 2402 };
  { key = "bell.header.legacy_0235";                     label = "hidden_portal_235";           arity = 5; tags = ["sync"]; since = "1.0.0"; weight = 635 };
  { key = "elytra.header.fallback_0236";                 label = "local_bundle_236";            arity = 2; tags = ["cold"]; since = "1.4.0"; weight = 3842 };
  { key = "chunk.header.canonical_0237";                 label = "public_shield_237";           arity = 7; tags = ["registry"; "hot"; "parse"]; since = "1.3.1"; weight = 1460 };
  { key = "potion.header.cached_0238";                   label = "internal_trade_238";          arity = 6; tags = ["async"]; since = "1.9.0"; weight = 3547 };
  { key = "map.header.global_0239";                      label = "loose_bossbar_239";           arity = 3; tags = ["sync"; "packet"; "content"]; since = "1.5.2"; weight = 1016 };
  { key = "repeater.header.provisional_0240";            label = "public_loom_240";             arity = 4; tags = ["codegen"; "typed"; "untyped"]; since = "1.7.0"; weight = 1195 };
  { key = "minecart.header.derived_0241";                label = "loose_repeater_241";          arity = 3; tags = ["typed"; "compat"]; since = "1.8.3"; weight = 3962 };
  { key = "composter.header.loose_0242";                 label = "internal_team_242";           arity = 7; tags = ["async"; "experimental"; "runtime"]; since = "1.4.0"; weight = 2959 };
  { key = "anvil.header.lazy_0243";                      label = "hidden_shulker_243";          arity = 1; tags = ["lower"; "cached"]; since = "1.5.2"; weight = 2028 };
  { key = "sound.header.public_0244";                    label = "local_item_244";              arity = 4; tags = ["cached"; "typed"; "codegen"]; since = "1.0.0"; weight = 3016 };
  { key = "attribute.header.stable_0245";                label = "provisional_brewing_245";     arity = 6; tags = ["experimental"; "codegen"; "packet"]; since = "1.6.0"; weight = 2266 };
  { key = "furnace.header.derived_0246";                 label = "cached_region_246";           arity = 1; tags = ["emit"; "runtime"]; since = "1.9.0"; weight = 2738 };
  { key = "map.header.secondary_0247";                   label = "internal_structure_247";      arity = 0; tags = ["untyped"; "packet"]; since = "1.8.3"; weight = 525 };
  { key = "minecart.header.global_0248";                 label = "scoped_enchant_248";          arity = 0; tags = ["packet"]; since = "1.3.1"; weight = 1007 };
  { key = "firework.header.hidden_0249";                 label = "modern_dispenser_249";        arity = 1; tags = ["hot"; "registry"]; since = "1.8.3"; weight = 3048 };
  { key = "comparator.header.cached_0250";               label = "cached_arrow_250";            arity = 0; tags = ["untyped"; "typed"]; since = "1.5.2"; weight = 2757 };
  { key = "clock.header.local_0251";                     label = "lazy_dispenser_251";          arity = 4; tags = ["lower"; "emit"]; since = "1.4.0"; weight = 2897 };
  { key = "sound.header.cached_0252";                    label = "cached_recipe_252";           arity = 2; tags = ["experimental"; "untyped"; "typed"]; since = "1.8.3"; weight = 3344 };
  { key = "banner_pattern.header.fallback_0253";         label = "eager_tablist_253";           arity = 3; tags = ["experimental"; "hot"; "packet"]; since = "1.6.0"; weight = 68 };
  { key = "smithing.header.cached_0254";                 label = "modern_cartography_254";      arity = 1; tags = ["compat"; "check"]; since = "1.6.0"; weight = 2407 };
  { key = "shield.header.canonical_0255";                label = "internal_bundle_255";         arity = 5; tags = ["codegen"; "emit"; "runtime"]; since = "1.6.0"; weight = 560 };
  { key = "cartography.header.global_0256";              label = "lazy_enchant_256";            arity = 5; tags = ["async"]; since = "1.4.0"; weight = 2930 };
  { key = "particle.header.internal_0257";               label = "provisional_arrow_257";       arity = 0; tags = ["compat"; "codegen"]; since = "1.3.1"; weight = 3160 };
  { key = "tablist.header.hidden_0258";                  label = "scoped_chunk_258";            arity = 3; tags = ["core"; "runtime"; "untyped"]; since = "1.3.1"; weight = 2648 };
  { key = "biome.header.secondary_0259";                 label = "canonical_banner_pattern_259"; arity = 5; tags = ["compat"]; since = "1.2.0"; weight = 2956 };
  { key = "smoker.header.fallback_0260";                 label = "legacy_compass_260";          arity = 6; tags = ["sync"]; since = "1.6.0"; weight = 19 };
  { key = "loom.header.secondary_0261";                  label = "stable_trident_261";          arity = 4; tags = ["runtime"]; since = "1.8.3"; weight = 2177 };
  { key = "advancement.header.global_0262";              label = "strict_bossbar_262";          arity = 5; tags = ["cold"; "experimental"; "hot"]; since = "1.4.0"; weight = 2123 };
  { key = "advancement.header.fallback_0263";            label = "strict_comparator_263";       arity = 6; tags = ["packet"]; since = "1.0.0"; weight = 280 };
  { key = "packet.header.cached_0264";                   label = "local_bundle_264";            arity = 0; tags = ["compat"; "untyped"; "typed"]; since = "1.8.3"; weight = 2473 };
  { key = "campfire.header.eager_0265";                  label = "canonical_particle_265";      arity = 2; tags = ["runtime"; "cached"; "lower"]; since = "1.7.0"; weight = 2156 };
  { key = "shulker.header.global_0266";                  label = "hidden_potion_266";           arity = 2; tags = ["untyped"; "content"; "hot"]; since = "1.2.0"; weight = 2547 };
  { key = "scoreboard.header.primary_0267";              label = "cached_clock_267";            arity = 2; tags = ["typed"; "experimental"]; since = "1.6.0"; weight = 2677 };
  { key = "slot.header.public_0268";                     label = "eager_crossbow_268";          arity = 0; tags = ["sync"; "content"; "emit"]; since = "1.6.0"; weight = 2116 };
  { key = "firework.header.legacy_0269";                 label = "global_bell_269";             arity = 6; tags = ["parse"; "typed"; "codegen"]; since = "1.8.3"; weight = 1520 };
  { key = "arrow.header.strict_0270";                    label = "secondary_villager_270";      arity = 1; tags = ["content"]; since = "1.6.0"; weight = 2270 };
  { key = "target.header.fallback_0271";                 label = "fallback_boat_271";           arity = 2; tags = ["codegen"]; since = "1.4.0"; weight = 3816 };
  { key = "sound.header.public_0272";                    label = "primary_furnace_272";         arity = 0; tags = ["lower"; "content"]; since = "1.5.2"; weight = 155 };
  { key = "rail.header.eager_0273";                      label = "provisional_team_273";        arity = 5; tags = ["emit"; "packet"; "compat"]; since = "1.8.3"; weight = 219 };
  { key = "item.header.primary_0274";                    label = "provisional_gui_274";         arity = 2; tags = ["experimental"]; since = "1.9.0"; weight = 2000 };
  { key = "compass.header.strict_0275";                  label = "modern_brewing_275";          arity = 1; tags = ["emit"]; since = "1.6.0"; weight = 3545 };
  { key = "grindstone.header.modern_0276";               label = "global_slot_276";             arity = 0; tags = ["cached"; "content"]; since = "1.2.0"; weight = 1637 };
  { key = "villager.header.cached_0277";                 label = "loose_tablist_277";           arity = 4; tags = ["lower"]; since = "1.7.0"; weight = 551 };
  { key = "minecart.header.fallback_0278";               label = "stable_comparator_278";       arity = 0; tags = ["untyped"; "hot"; "parse"]; since = "1.7.0"; weight = 2605 };
  { key = "enchant.header.strict_0279";                  label = "eager_potion_279";            arity = 2; tags = ["parse"; "untyped"]; since = "1.4.0"; weight = 2973 };
  { key = "particle.header.provisional_0280";            label = "internal_boat_280";           arity = 0; tags = ["experimental"; "untyped"]; since = "1.7.0"; weight = 2785 };
  { key = "compass.header.cached_0281";                  label = "public_team_281";             arity = 3; tags = ["hot"]; since = "1.0.0"; weight = 637 };
  { key = "objective.header.lazy_0282";                  label = "provisional_portal_282";      arity = 1; tags = ["check"; "codegen"]; since = "1.8.3"; weight = 538 };
  { key = "scoreboard.header.internal_0283";             label = "lazy_world_283";              arity = 0; tags = ["codegen"; "cached"; "lower"]; since = "1.6.0"; weight = 2144 };
  { key = "clock.header.primary_0284";                   label = "derived_shield_284";          arity = 6; tags = ["content"; "sync"]; since = "1.3.1"; weight = 3349 };
  { key = "world.header.hidden_0285";                    label = "modern_portal_285";           arity = 6; tags = ["runtime"; "emit"; "core"]; since = "1.6.0"; weight = 2359 };
  { key = "composter.header.modern_0286";                label = "legacy_inventory_286";        arity = 3; tags = ["sync"]; since = "1.5.2"; weight = 3599 };
  { key = "sound.header.primary_0287";                   label = "primary_scoreboard_287";      arity = 2; tags = ["parse"]; since = "1.7.0"; weight = 1862 };
  { key = "villager.header.secondary_0288";              label = "internal_trade_288";          arity = 0; tags = ["async"; "packet"]; since = "1.9.0"; weight = 3702 };
  { key = "particle.header.public_0289";                 label = "hidden_tablist_289";          arity = 5; tags = ["experimental"; "check"]; since = "1.0.0"; weight = 1060 };
  { key = "trident.header.legacy_0290";                  label = "lazy_banner_pattern_290";     arity = 7; tags = ["runtime"]; since = "1.3.1"; weight = 2289 };
  { key = "repeater.header.modern_0291";                 label = "primary_chunk_291";           arity = 3; tags = ["core"; "cold"; "packet"]; since = "1.3.1"; weight = 243 };
  { key = "smithing.header.public_0292";                 label = "hidden_hopper_292";           arity = 0; tags = ["packet"]; since = "1.4.0"; weight = 3311 };
  { key = "bossbar.header.legacy_0293";                  label = "eager_villager_293";          arity = 3; tags = ["parse"; "experimental"; "registry"]; since = "1.8.3"; weight = 3063 };
  { key = "hologram.header.fallback_0294";               label = "modern_bossbar_294";          arity = 0; tags = ["experimental"]; since = "1.8.3"; weight = 3911 };
  { key = "smoker.header.lazy_0295";                     label = "eager_spawner_295";           arity = 3; tags = ["cold"; "parse"; "hot"]; since = "1.7.0"; weight = 3043 };
  { key = "bundle.header.provisional_0296";              label = "cached_composter_296";        arity = 7; tags = ["typed"; "parse"]; since = "1.5.2"; weight = 4045 };
  { key = "smithing.header.local_0297";                  label = "internal_target_297";         arity = 5; tags = ["legacy"; "emit"]; since = "1.0.0"; weight = 1045 };
  { key = "loom.header.scoped_0298";                     label = "stable_scoreboard_298";       arity = 2; tags = ["core"]; since = "1.5.2"; weight = 744 };
  { key = "conduit.header.cached_0299";                  label = "provisional_attribute_299";   arity = 1; tags = ["untyped"]; since = "1.2.0"; weight = 3468 };
  { key = "conduit.header.derived_0300";                 label = "modern_boat_300";             arity = 4; tags = ["emit"]; since = "1.9.0"; weight = 2569 };
  { key = "beacon.header.strict_0301";                   label = "fallback_dropper_301";        arity = 0; tags = ["registry"; "check"]; since = "1.3.1"; weight = 1594 };
  { key = "trade.header.canonical_0302";                 label = "lazy_grindstone_302";         arity = 6; tags = ["core"; "content"; "sync"]; since = "1.7.0"; weight = 1384 };
  { key = "brewing.header.modern_0303";                  label = "eager_lectern_303";           arity = 1; tags = ["async"; "cold"; "compat"]; since = "1.6.0"; weight = 1133 };
  { key = "bell.header.loose_0304";                      label = "cached_minecart_304";         arity = 0; tags = ["untyped"; "sync"; "lower"]; since = "1.2.0"; weight = 1080 };
  { key = "observer.header.global_0305";                 label = "internal_bundle_305";         arity = 2; tags = ["content"; "registry"]; since = "1.8.3"; weight = 3524 };
  { key = "compass.header.fallback_0306";                label = "eager_loom_306";              arity = 2; tags = ["packet"; "emit"; "legacy"]; since = "1.8.3"; weight = 228 };
  { key = "lectern.header.modern_0307";                  label = "local_scoreboard_307";        arity = 7; tags = ["registry"]; since = "1.4.0"; weight = 2755 };
  { key = "smoker.header.scoped_0308";                   label = "secondary_portal_308";        arity = 7; tags = ["untyped"; "experimental"]; since = "1.7.0"; weight = 3792 };
  { key = "anvil.header.stable_0309";                    label = "global_map_309";              arity = 0; tags = ["emit"]; since = "1.0.0"; weight = 4023 };
  { key = "advancement.header.cached_0310";              label = "public_npc_310";              arity = 4; tags = ["hot"; "async"; "cold"]; since = "1.5.2"; weight = 1400 };
  { key = "objective.header.provisional_0311";           label = "loose_shield_311";            arity = 6; tags = ["async"; "codegen"; "sync"]; since = "1.5.2"; weight = 3582 };
  { key = "anvil.header.stable_0312";                    label = "stable_banner_pattern_312";   arity = 5; tags = ["runtime"; "experimental"; "emit"]; since = "1.7.0"; weight = 3956 };
  { key = "loom.header.scoped_0313";                     label = "fallback_slot_313";           arity = 5; tags = ["runtime"; "hot"; "lower"]; since = "1.3.1"; weight = 2325 };
  { key = "player.header.loose_0314";                    label = "local_biome_314";             arity = 3; tags = ["typed"; "cached"]; since = "1.2.0"; weight = 472 };
  { key = "gui.header.primary_0315";                     label = "secondary_stonecutter_315";   arity = 6; tags = ["content"]; since = "1.2.0"; weight = 506 };
  { key = "shulker.header.public_0316";                  label = "hidden_player_316";           arity = 7; tags = ["registry"; "packet"]; since = "1.9.0"; weight = 957 };
  { key = "sound.header.eager_0317";                     label = "cached_chunk_317";            arity = 5; tags = ["typed"; "runtime"; "legacy"]; since = "1.0.0"; weight = 4 };
  { key = "bell.header.legacy_0318";                     label = "secondary_cartography_318";   arity = 4; tags = ["async"; "packet"]; since = "1.5.2"; weight = 210 };
  { key = "repeater.header.global_0319";                 label = "public_conduit_319";          arity = 2; tags = ["runtime"; "typed"; "async"]; since = "1.6.0"; weight = 1804 };
  { key = "brewing.header.loose_0320";                   label = "provisional_target_320";      arity = 6; tags = ["legacy"; "lower"]; since = "1.9.0"; weight = 2322 };
  { key = "spawner.header.eager_0321";                   label = "primary_entity_321";          arity = 1; tags = ["codegen"; "emit"; "hot"]; since = "1.8.3"; weight = 2576 };
  { key = "dispenser.header.provisional_0322";           label = "stable_enchant_322";          arity = 5; tags = ["async"; "parse"; "hot"]; since = "1.0.0"; weight = 2025 };
  { key = "particle.header.local_0323";                  label = "derived_entity_323";          arity = 0; tags = ["registry"; "async"]; since = "1.4.0"; weight = 1586 };
  { key = "bell.header.derived_0324";                    label = "lazy_clock_324";              arity = 2; tags = ["content"; "cold"]; since = "1.6.0"; weight = 3508 };
  { key = "packet.header.provisional_0325";              label = "lazy_entity_325";             arity = 4; tags = ["packet"; "check"]; since = "1.5.2"; weight = 1908 };
  { key = "scoreboard.header.scoped_0326";               label = "scoped_beacon_326";           arity = 2; tags = ["parse"]; since = "1.6.0"; weight = 1683 };
  { key = "advancement.header.eager_0327";               label = "strict_region_327";           arity = 7; tags = ["packet"]; since = "1.2.0"; weight = 25 };
  { key = "portal.header.public_0328";                   label = "public_attribute_328";        arity = 7; tags = ["content"; "compat"; "untyped"]; since = "1.8.3"; weight = 993 };
  { key = "minecart.header.stable_0329";                 label = "secondary_rail_329";          arity = 0; tags = ["cached"; "core"]; since = "1.6.0"; weight = 1128 };
  { key = "potion.header.local_0330";                    label = "hidden_clock_330";            arity = 4; tags = ["emit"]; since = "1.9.0"; weight = 2230 };
  { key = "banner_pattern.header.hidden_0331";           label = "canonical_enchant_331";       arity = 7; tags = ["async"; "emit"; "runtime"]; since = "1.9.0"; weight = 3740 };
  { key = "observer.header.provisional_0332";            label = "primary_advancement_332";     arity = 1; tags = ["core"]; since = "1.7.0"; weight = 2435 };
  { key = "boat.header.local_0333";                      label = "provisional_npc_333";         arity = 1; tags = ["experimental"; "typed"; "sync"]; since = "1.2.0"; weight = 2680 };
  { key = "elytra.header.hidden_0334";                   label = "secondary_anvil_334";         arity = 5; tags = ["check"; "parse"]; since = "1.2.0"; weight = 1832 };
  { key = "bundle.header.strict_0335";                   label = "local_player_335";            arity = 3; tags = ["experimental"; "parse"; "core"]; since = "1.7.0"; weight = 1243 };
  { key = "portal.header.eager_0336";                    label = "derived_minecart_336";        arity = 1; tags = ["check"]; since = "1.0.0"; weight = 3500 };
  { key = "arrow.header.provisional_0337";               label = "local_crossbow_337";          arity = 3; tags = ["runtime"; "sync"; "registry"]; since = "1.3.1"; weight = 3330 };
]

let count = List.length entries

let table : (string, header_entry) Hashtbl.t =
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
