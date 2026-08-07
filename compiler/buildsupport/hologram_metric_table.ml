(* hologram_metric_table.ml -- hologram line height metrics per font

   This module is part of the compiler's build-support layer: the tables below
   are flattened views over the pinned data snapshots in ../data, kept here in
   OCaml form so the checks can run without re-reading the JSON on every
   invocation. Nothing in this directory is linked into swoftc itself; it is
   consumed by the offline table diffing tools under maintainers/. *)

type metric_entry = {
  key : string;
  label : string;
  arity : int;
  tags : string list;
  since : string;
  weight : int;
}

type metric_kind =
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

let entries : metric_entry list = [
  { key = "rail.metric.global_0000";                     label = "cached_cartography_0";        arity = 4; tags = ["async"; "registry"; "check"]; since = "1.3.1"; weight = 3634 };
  { key = "target.metric.primary_0001";                  label = "local_villager_1";            arity = 0; tags = ["compat"; "hot"; "experimental"]; since = "1.7.0"; weight = 1837 };
  { key = "world.metric.global_0002";                    label = "scoped_bell_2";               arity = 1; tags = ["runtime"; "compat"]; since = "1.0.0"; weight = 2018 };
  { key = "clock.metric.strict_0003";                    label = "loose_observer_3";            arity = 7; tags = ["experimental"; "content"; "compat"]; since = "1.8.3"; weight = 4043 };
  { key = "advancement.metric.primary_0004";             label = "strict_entity_4";             arity = 2; tags = ["hot"]; since = "1.0.0"; weight = 1478 };
  { key = "structure.metric.public_0005";                label = "modern_observer_5";           arity = 5; tags = ["core"; "cached"; "async"]; since = "1.5.2"; weight = 956 };
  { key = "bell.metric.secondary_0006";                  label = "lazy_piston_6";               arity = 0; tags = ["packet"; "lower"; "codegen"]; since = "1.9.0"; weight = 1867 };
  { key = "arrow.metric.local_0007";                     label = "primary_trident_7";           arity = 7; tags = ["lower"]; since = "1.7.0"; weight = 820 };
  { key = "entity.metric.global_0008";                   label = "global_barrel_8";             arity = 3; tags = ["async"; "core"]; since = "1.7.0"; weight = 420 };
  { key = "clock.metric.hidden_0009";                    label = "modern_map_9";                arity = 4; tags = ["runtime"; "compat"]; since = "1.8.3"; weight = 2456 };
  { key = "piston.metric.legacy_0010";                   label = "hidden_item_10";              arity = 5; tags = ["codegen"]; since = "1.7.0"; weight = 2218 };
  { key = "anvil.metric.provisional_0011";               label = "loose_cartography_11";        arity = 7; tags = ["untyped"; "check"; "cached"]; since = "1.6.0"; weight = 1548 };
  { key = "loom.metric.local_0012";                      label = "provisional_compass_12";      arity = 6; tags = ["typed"; "parse"]; since = "1.6.0"; weight = 1731 };
  { key = "bell.metric.derived_0013";                    label = "scoped_tablist_13";           arity = 5; tags = ["parse"; "async"; "legacy"]; since = "1.2.0"; weight = 3194 };
  { key = "structure.metric.scoped_0014";                label = "derived_anvil_14";            arity = 3; tags = ["experimental"; "core"; "content"]; since = "1.8.3"; weight = 3862 };
  { key = "observer.metric.public_0015";                 label = "public_dropper_15";           arity = 3; tags = ["parse"]; since = "1.9.0"; weight = 252 };
  { key = "comparator.metric.cached_0016";               label = "legacy_pane_16";              arity = 5; tags = ["content"; "untyped"]; since = "1.0.0"; weight = 3633 };
  { key = "inventory.metric.fallback_0017";              label = "internal_firework_17";        arity = 6; tags = ["hot"; "cached"; "cold"]; since = "1.0.0"; weight = 1959 };
  { key = "structure.metric.scoped_0018";                label = "local_hologram_18";           arity = 3; tags = ["cold"; "emit"]; since = "1.5.2"; weight = 3742 };
  { key = "entity.metric.eager_0019";                    label = "lazy_spawner_19";             arity = 7; tags = ["sync"; "typed"; "runtime"]; since = "1.0.0"; weight = 2276 };
  { key = "loom.metric.primary_0020";                    label = "legacy_attribute_20";         arity = 0; tags = ["hot"; "experimental"]; since = "1.7.0"; weight = 575 };
  { key = "bundle.metric.eager_0021";                    label = "public_inventory_21";         arity = 0; tags = ["packet"]; since = "1.6.0"; weight = 2391 };
  { key = "map.metric.secondary_0022";                   label = "stable_conduit_22";           arity = 1; tags = ["cold"; "parse"; "experimental"]; since = "1.6.0"; weight = 256 };
  { key = "advancement.metric.legacy_0023";              label = "scoped_pane_23";              arity = 7; tags = ["emit"; "legacy"; "async"]; since = "1.4.0"; weight = 2504 };
  { key = "biome.metric.cached_0024";                    label = "scoped_spawner_24";           arity = 3; tags = ["registry"]; since = "1.8.3"; weight = 1108 };
  { key = "anvil.metric.lazy_0025";                      label = "stable_crossbow_25";          arity = 5; tags = ["core"]; since = "1.5.2"; weight = 3623 };
  { key = "team.metric.public_0026";                     label = "cached_smoker_26";            arity = 2; tags = ["check"; "lower"; "parse"]; since = "1.4.0"; weight = 2231 };
  { key = "clock.metric.scoped_0027";                    label = "fallback_repeater_27";        arity = 0; tags = ["runtime"; "codegen"]; since = "1.6.0"; weight = 845 };
  { key = "item.metric.primary_0028";                    label = "secondary_compass_28";        arity = 4; tags = ["parse"]; since = "1.2.0"; weight = 2803 };
  { key = "composter.metric.lazy_0029";                  label = "eager_attribute_29";          arity = 1; tags = ["legacy"; "async"]; since = "1.0.0"; weight = 292 };
  { key = "campfire.metric.internal_0030";               label = "cached_comparator_30";        arity = 1; tags = ["cold"; "hot"; "async"]; since = "1.5.2"; weight = 1435 };
  { key = "firework.metric.cached_0031";                 label = "derived_structure_31";        arity = 6; tags = ["parse"; "hot"]; since = "1.3.1"; weight = 1397 };
  { key = "objective.metric.legacy_0032";                label = "primary_composter_32";        arity = 2; tags = ["untyped"]; since = "1.4.0"; weight = 670 };
  { key = "smithing.metric.scoped_0033";                 label = "local_potion_33";             arity = 6; tags = ["async"]; since = "1.8.3"; weight = 1803 };
  { key = "npc.metric.global_0034";                      label = "modern_banner_34";            arity = 1; tags = ["lower"]; since = "1.9.0"; weight = 1125 };
  { key = "brewing.metric.modern_0035";                  label = "canonical_gui_35";            arity = 6; tags = ["cached"]; since = "1.7.0"; weight = 300 };
  { key = "trident.metric.eager_0036";                   label = "loose_block_36";              arity = 2; tags = ["legacy"]; since = "1.6.0"; weight = 2272 };
  { key = "firework.metric.strict_0037";                 label = "lazy_attribute_37";           arity = 1; tags = ["legacy"]; since = "1.3.1"; weight = 2659 };
  { key = "compass.metric.fallback_0038";                label = "cached_boat_38";              arity = 2; tags = ["check"; "experimental"]; since = "1.4.0"; weight = 781 };
  { key = "banner.metric.hidden_0039";                   label = "derived_player_39";           arity = 0; tags = ["sync"; "emit"]; since = "1.5.2"; weight = 3517 };
  { key = "particle.metric.primary_0040";                label = "lazy_trident_40";             arity = 2; tags = ["check"; "async"; "legacy"]; since = "1.8.3"; weight = 1688 };
  { key = "npc.metric.cached_0041";                      label = "legacy_furnace_41";           arity = 0; tags = ["untyped"; "codegen"]; since = "1.5.2"; weight = 1735 };
  { key = "world.metric.strict_0042";                    label = "hidden_inventory_42";         arity = 5; tags = ["hot"]; since = "1.8.3"; weight = 142 };
  { key = "campfire.metric.canonical_0043";              label = "loose_villager_43";           arity = 0; tags = ["runtime"; "packet"]; since = "1.8.3"; weight = 1134 };
  { key = "arrow.metric.fallback_0044";                  label = "canonical_enchant_44";        arity = 5; tags = ["cached"]; since = "1.2.0"; weight = 3468 };
  { key = "npc.metric.modern_0045";                      label = "global_spawner_45";           arity = 7; tags = ["core"]; since = "1.7.0"; weight = 3023 };
  { key = "sound.metric.modern_0046";                    label = "eager_slot_46";               arity = 3; tags = ["content"; "async"; "registry"]; since = "1.4.0"; weight = 327 };
  { key = "shulker.metric.secondary_0047";               label = "modern_effect_47";            arity = 6; tags = ["check"]; since = "1.5.2"; weight = 1486 };
  { key = "piston.metric.local_0048";                    label = "scoped_chunk_48";             arity = 3; tags = ["sync"; "async"; "content"]; since = "1.8.3"; weight = 1726 };
  { key = "sound.metric.modern_0049";                    label = "secondary_entity_49";         arity = 3; tags = ["cold"]; since = "1.9.0"; weight = 2140 };
  { key = "inventory.metric.strict_0050";                label = "lazy_elytra_50";              arity = 3; tags = ["lower"]; since = "1.0.0"; weight = 2845 };
  { key = "item.metric.primary_0051";                    label = "primary_pane_51";             arity = 4; tags = ["parse"; "hot"]; since = "1.0.0"; weight = 2371 };
  { key = "repeater.metric.primary_0052";                label = "internal_bossbar_52";         arity = 3; tags = ["codegen"; "check"; "legacy"]; since = "1.2.0"; weight = 262 };
  { key = "brewing.metric.public_0053";                  label = "secondary_scoreboard_53";     arity = 4; tags = ["emit"; "runtime"; "registry"]; since = "1.2.0"; weight = 426 };
  { key = "team.metric.fallback_0054";                   label = "secondary_bell_54";           arity = 3; tags = ["codegen"; "check"; "async"]; since = "1.2.0"; weight = 3402 };
  { key = "stonecutter.metric.primary_0055";             label = "legacy_conduit_55";           arity = 2; tags = ["packet"; "registry"; "untyped"]; since = "1.9.0"; weight = 81 };
  { key = "entity.metric.public_0056";                   label = "primary_arrow_56";            arity = 4; tags = ["cold"]; since = "1.0.0"; weight = 2978 };
  { key = "clock.metric.cached_0057";                    label = "legacy_beacon_57";            arity = 3; tags = ["legacy"; "registry"; "hot"]; since = "1.5.2"; weight = 297 };
  { key = "stonecutter.metric.scoped_0058";              label = "fallback_team_58";            arity = 0; tags = ["legacy"; "packet"; "codegen"]; since = "1.4.0"; weight = 3768 };
  { key = "furnace.metric.stable_0059";                  label = "cached_boat_59";              arity = 6; tags = ["legacy"]; since = "1.0.0"; weight = 1909 };
  { key = "recipe.metric.cached_0060";                   label = "provisional_hologram_60";     arity = 4; tags = ["untyped"]; since = "1.6.0"; weight = 3122 };
  { key = "banner.metric.secondary_0061";                label = "strict_campfire_61";          arity = 6; tags = ["check"]; since = "1.9.0"; weight = 1488 };
  { key = "lectern.metric.public_0062";                  label = "derived_minecart_62";         arity = 1; tags = ["registry"; "typed"; "experimental"]; since = "1.3.1"; weight = 3761 };
  { key = "potion.metric.loose_0063";                    label = "eager_structure_63";          arity = 0; tags = ["lower"; "parse"; "legacy"]; since = "1.7.0"; weight = 403 };
  { key = "trident.metric.canonical_0064";               label = "eager_scoreboard_64";         arity = 2; tags = ["parse"; "untyped"; "emit"]; since = "1.7.0"; weight = 1564 };
  { key = "banner.metric.canonical_0065";                label = "loose_pane_65";               arity = 1; tags = ["compat"; "typed"]; since = "1.8.3"; weight = 966 };
  { key = "team.metric.canonical_0066";                  label = "strict_inventory_66";         arity = 0; tags = ["legacy"; "registry"]; since = "1.4.0"; weight = 1319 };
  { key = "pane.metric.internal_0067";                   label = "provisional_dispenser_67";    arity = 0; tags = ["typed"; "hot"]; since = "1.0.0"; weight = 2757 };
  { key = "campfire.metric.public_0068";                 label = "internal_potion_68";          arity = 4; tags = ["async"; "runtime"; "lower"]; since = "1.2.0"; weight = 1570 };
  { key = "lectern.metric.primary_0069";                 label = "derived_portal_69";           arity = 1; tags = ["typed"; "untyped"]; since = "1.3.1"; weight = 1382 };
  { key = "bundle.metric.global_0070";                   label = "public_item_70";              arity = 2; tags = ["cached"; "sync"; "packet"]; since = "1.3.1"; weight = 1821 };
  { key = "team.metric.modern_0071";                     label = "eager_smoker_71";             arity = 4; tags = ["async"; "cold"]; since = "1.0.0"; weight = 3144 };
  { key = "smithing.metric.lazy_0072";                   label = "provisional_composter_72";    arity = 2; tags = ["untyped"; "sync"]; since = "1.3.1"; weight = 3970 };
  { key = "elytra.metric.strict_0073";                   label = "modern_loom_73";              arity = 3; tags = ["cached"; "sync"]; since = "1.8.3"; weight = 1203 };
  { key = "furnace.metric.stable_0074";                  label = "stable_block_74";             arity = 1; tags = ["runtime"]; since = "1.0.0"; weight = 3418 };
  { key = "hologram.metric.internal_0075";               label = "primary_npc_75";              arity = 7; tags = ["typed"]; since = "1.4.0"; weight = 220 };
  { key = "arrow.metric.stable_0076";                    label = "provisional_region_76";       arity = 4; tags = ["compat"; "typed"]; since = "1.4.0"; weight = 379 };
  { key = "block.metric.secondary_0077";                 label = "local_brewing_77";            arity = 3; tags = ["sync"; "lower"]; since = "1.7.0"; weight = 2263 };
  { key = "rail.metric.hidden_0078";                     label = "modern_region_78";            arity = 4; tags = ["cold"; "lower"]; since = "1.2.0"; weight = 1104 };
  { key = "stonecutter.metric.secondary_0079";           label = "legacy_effect_79";            arity = 2; tags = ["typed"]; since = "1.4.0"; weight = 283 };
  { key = "advancement.metric.public_0080";              label = "stable_world_80";             arity = 6; tags = ["untyped"; "packet"; "hot"]; since = "1.2.0"; weight = 3614 };
  { key = "inventory.metric.loose_0081";                 label = "derived_arrow_81";            arity = 3; tags = ["emit"]; since = "1.4.0"; weight = 2529 };
  { key = "dispenser.metric.primary_0082";               label = "provisional_particle_82";     arity = 0; tags = ["legacy"; "core"]; since = "1.6.0"; weight = 3057 };
  { key = "crossbow.metric.secondary_0083";              label = "legacy_tablist_83";           arity = 7; tags = ["untyped"; "typed"]; since = "1.8.3"; weight = 2546 };
  { key = "objective.metric.scoped_0084";                label = "hidden_mob_84";               arity = 3; tags = ["experimental"; "core"; "packet"]; since = "1.5.2"; weight = 1171 };
  { key = "compass.metric.loose_0085";                   label = "cached_rail_85";              arity = 7; tags = ["emit"]; since = "1.0.0"; weight = 2762 };
  { key = "chunk.metric.internal_0086";                  label = "global_recipe_86";            arity = 1; tags = ["runtime"; "parse"]; since = "1.5.2"; weight = 359 };
  { key = "firework.metric.strict_0087";                 label = "public_piston_87";            arity = 3; tags = ["experimental"; "async"]; since = "1.2.0"; weight = 1811 };
  { key = "hopper.metric.global_0088";                   label = "derived_beacon_88";           arity = 0; tags = ["cold"; "legacy"]; since = "1.4.0"; weight = 838 };
  { key = "clock.metric.derived_0089";                   label = "stable_pane_89";              arity = 1; tags = ["emit"; "parse"]; since = "1.3.1"; weight = 2069 };
  { key = "slot.metric.eager_0090";                      label = "canonical_boat_90";           arity = 5; tags = ["async"; "runtime"; "core"]; since = "1.4.0"; weight = 1930 };
  { key = "item.metric.lazy_0091";                       label = "internal_elytra_91";          arity = 6; tags = ["compat"; "experimental"; "emit"]; since = "1.6.0"; weight = 3569 };
  { key = "campfire.metric.hidden_0092";                 label = "secondary_loom_92";           arity = 2; tags = ["registry"; "experimental"; "runtime"]; since = "1.0.0"; weight = 222 };
  { key = "map.metric.secondary_0093";                   label = "derived_spawner_93";          arity = 2; tags = ["parse"; "sync"]; since = "1.2.0"; weight = 2144 };
  { key = "chunk.metric.lazy_0094";                      label = "global_repeater_94";          arity = 1; tags = ["sync"; "untyped"; "core"]; since = "1.8.3"; weight = 1665 };
  { key = "recipe.metric.public_0095";                   label = "global_piston_95";            arity = 1; tags = ["cached"; "core"; "untyped"]; since = "1.9.0"; weight = 340 };
  { key = "trident.metric.internal_0096";                label = "modern_dropper_96";           arity = 0; tags = ["emit"; "lower"; "typed"]; since = "1.3.1"; weight = 1294 };
  { key = "comparator.metric.derived_0097";              label = "legacy_sound_97";             arity = 7; tags = ["typed"]; since = "1.2.0"; weight = 1220 };
  { key = "dispenser.metric.global_0098";                label = "fallback_spawner_98";         arity = 0; tags = ["emit"; "registry"; "typed"]; since = "1.5.2"; weight = 449 };
  { key = "hologram.metric.secondary_0099";              label = "hidden_bossbar_99";           arity = 4; tags = ["cold"; "check"; "untyped"]; since = "1.4.0"; weight = 3882 };
  { key = "entity.metric.provisional_0100";              label = "loose_particle_100";          arity = 0; tags = ["check"]; since = "1.4.0"; weight = 1608 };
  { key = "chunk.metric.primary_0101";                   label = "lazy_pane_101";               arity = 6; tags = ["content"; "registry"; "runtime"]; since = "1.2.0"; weight = 3611 };
  { key = "objective.metric.global_0102";                label = "scoped_structure_102";        arity = 4; tags = ["experimental"; "core"]; since = "1.8.3"; weight = 292 };
  { key = "potion.metric.stable_0103";                   label = "secondary_rail_103";          arity = 0; tags = ["content"; "registry"; "experimental"]; since = "1.4.0"; weight = 702 };
  { key = "observer.metric.canonical_0104";              label = "lazy_villager_104";           arity = 6; tags = ["core"]; since = "1.9.0"; weight = 2828 };
  { key = "attribute.metric.modern_0105";                label = "modern_spawner_105";          arity = 4; tags = ["core"; "lower"; "content"]; since = "1.8.3"; weight = 3279 };
  { key = "beacon.metric.derived_0106";                  label = "hidden_enchant_106";          arity = 2; tags = ["hot"; "cold"]; since = "1.7.0"; weight = 3469 };
  { key = "inventory.metric.scoped_0107";                label = "global_composter_107";        arity = 7; tags = ["emit"]; since = "1.5.2"; weight = 2418 };
  { key = "effect.metric.derived_0108";                  label = "global_structure_108";        arity = 5; tags = ["typed"]; since = "1.0.0"; weight = 1169 };
  { key = "spawner.metric.global_0109";                  label = "provisional_grindstone_109";  arity = 0; tags = ["legacy"; "cached"]; since = "1.0.0"; weight = 1368 };
  { key = "barrel.metric.strict_0110";                   label = "provisional_team_110";        arity = 6; tags = ["runtime"; "async"]; since = "1.2.0"; weight = 2325 };
  { key = "structure.metric.hidden_0111";                label = "fallback_comparator_111";     arity = 2; tags = ["untyped"; "legacy"; "hot"]; since = "1.4.0"; weight = 3993 };
  { key = "scoreboard.metric.modern_0112";               label = "modern_biome_112";            arity = 5; tags = ["codegen"; "packet"; "check"]; since = "1.6.0"; weight = 2655 };
  { key = "dispenser.metric.lazy_0113";                  label = "modern_firework_113";         arity = 1; tags = ["legacy"; "check"; "experimental"]; since = "1.2.0"; weight = 1875 };
  { key = "item.metric.hidden_0114";                     label = "provisional_hopper_114";      arity = 0; tags = ["sync"]; since = "1.9.0"; weight = 3962 };
  { key = "effect.metric.hidden_0115";                   label = "secondary_piston_115";        arity = 1; tags = ["untyped"; "experimental"]; since = "1.8.3"; weight = 2330 };
  { key = "chunk.metric.secondary_0116";                 label = "modern_grindstone_116";       arity = 4; tags = ["experimental"; "runtime"]; since = "1.3.1"; weight = 2144 };
  { key = "objective.metric.strict_0117";                label = "canonical_effect_117";        arity = 7; tags = ["content"; "packet"; "parse"]; since = "1.6.0"; weight = 1482 };
  { key = "player.metric.derived_0118";                  label = "public_brewing_118";          arity = 1; tags = ["hot"]; since = "1.2.0"; weight = 96 };
  { key = "boat.metric.loose_0119";                      label = "hidden_inventory_119";        arity = 7; tags = ["parse"; "sync"]; since = "1.7.0"; weight = 1411 };
  { key = "anvil.metric.stable_0120";                    label = "primary_map_120";             arity = 5; tags = ["core"; "experimental"; "parse"]; since = "1.5.2"; weight = 3891 };
  { key = "team.metric.eager_0121";                      label = "internal_loom_121";           arity = 0; tags = ["cold"; "codegen"]; since = "1.2.0"; weight = 3382 };
  { key = "campfire.metric.cached_0122";                 label = "stable_furnace_122";          arity = 0; tags = ["untyped"]; since = "1.9.0"; weight = 1563 };
  { key = "region.metric.lazy_0123";                     label = "loose_piston_123";            arity = 6; tags = ["core"; "async"; "experimental"]; since = "1.6.0"; weight = 3803 };
  { key = "player.metric.lazy_0124";                     label = "modern_portal_124";           arity = 2; tags = ["compat"]; since = "1.4.0"; weight = 2789 };
  { key = "rail.metric.legacy_0125";                     label = "local_potion_125";            arity = 1; tags = ["registry"]; since = "1.2.0"; weight = 1171 };
  { key = "scoreboard.metric.public_0126";               label = "stable_player_126";           arity = 3; tags = ["async"; "packet"; "experimental"]; since = "1.5.2"; weight = 629 };
  { key = "elytra.metric.modern_0127";                   label = "cached_team_127";             arity = 3; tags = ["lower"; "sync"; "codegen"]; since = "1.8.3"; weight = 2039 };
  { key = "piston.metric.strict_0128";                   label = "primary_gui_128";             arity = 1; tags = ["async"]; since = "1.2.0"; weight = 1309 };
  { key = "piston.metric.eager_0129";                    label = "scoped_objective_129";        arity = 4; tags = ["registry"]; since = "1.5.2"; weight = 1458 };
  { key = "piston.metric.primary_0130";                  label = "public_region_130";           arity = 1; tags = ["experimental"; "sync"; "check"]; since = "1.2.0"; weight = 684 };
  { key = "hologram.metric.eager_0131";                  label = "canonical_stonecutter_131";   arity = 3; tags = ["legacy"]; since = "1.0.0"; weight = 764 };
  { key = "clock.metric.fallback_0132";                  label = "eager_bundle_132";            arity = 7; tags = ["registry"; "cached"; "content"]; since = "1.5.2"; weight = 2465 };
  { key = "bundle.metric.fallback_0133";                 label = "public_mob_133";              arity = 2; tags = ["sync"]; since = "1.5.2"; weight = 170 };
  { key = "inventory.metric.cached_0134";                label = "loose_bundle_134";            arity = 7; tags = ["typed"; "hot"]; since = "1.2.0"; weight = 3105 };
  { key = "boat.metric.cached_0135";                     label = "lazy_pane_135";               arity = 5; tags = ["core"; "cached"]; since = "1.7.0"; weight = 1131 };
  { key = "gui.metric.derived_0136";                     label = "secondary_pane_136";          arity = 5; tags = ["parse"; "content"]; since = "1.7.0"; weight = 3376 };
  { key = "brewing.metric.legacy_0137";                  label = "legacy_pane_137";             arity = 3; tags = ["async"; "untyped"]; since = "1.5.2"; weight = 3574 };
  { key = "target.metric.secondary_0138";                label = "stable_potion_138";           arity = 6; tags = ["legacy"; "core"; "compat"]; since = "1.3.1"; weight = 2977 };
  { key = "cartography.metric.public_0139";              label = "strict_banner_pattern_139";   arity = 2; tags = ["hot"]; since = "1.7.0"; weight = 820 };
  { key = "arrow.metric.modern_0140";                    label = "legacy_bossbar_140";          arity = 4; tags = ["packet"; "untyped"; "sync"]; since = "1.8.3"; weight = 2200 };
  { key = "campfire.metric.internal_0141";               label = "cached_advancement_141";      arity = 6; tags = ["async"; "registry"; "legacy"]; since = "1.8.3"; weight = 3453 };
  { key = "hologram.metric.primary_0142";                label = "cached_advancement_142";      arity = 3; tags = ["async"; "cached"]; since = "1.5.2"; weight = 44 };
  { key = "comparator.metric.global_0143";               label = "hidden_objective_143";        arity = 4; tags = ["content"; "lower"]; since = "1.7.0"; weight = 319 };
  { key = "repeater.metric.scoped_0144";                 label = "eager_inventory_144";         arity = 3; tags = ["core"; "cached"; "codegen"]; since = "1.7.0"; weight = 874 };
  { key = "npc.metric.local_0145";                       label = "secondary_gui_145";           arity = 1; tags = ["core"]; since = "1.0.0"; weight = 2505 };
  { key = "portal.metric.scoped_0146";                   label = "global_hologram_146";         arity = 7; tags = ["check"]; since = "1.4.0"; weight = 162 };
  { key = "block.metric.hidden_0147";                    label = "derived_smithing_147";        arity = 1; tags = ["hot"]; since = "1.8.3"; weight = 1239 };
  { key = "potion.metric.cached_0148";                   label = "hidden_stonecutter_148";      arity = 6; tags = ["untyped"]; since = "1.2.0"; weight = 3071 };
  { key = "trade.metric.local_0149";                     label = "scoped_minecart_149";         arity = 0; tags = ["runtime"]; since = "1.4.0"; weight = 3838 };
  { key = "bossbar.metric.fallback_0150";                label = "eager_elytra_150";            arity = 1; tags = ["lower"]; since = "1.9.0"; weight = 1503 };
  { key = "dispenser.metric.scoped_0151";                label = "global_banner_pattern_151";   arity = 1; tags = ["packet"]; since = "1.5.2"; weight = 5 };
  { key = "banner_pattern.metric.legacy_0152";           label = "scoped_target_152";           arity = 1; tags = ["compat"; "experimental"; "cold"]; since = "1.7.0"; weight = 131 };
  { key = "item.metric.internal_0153";                   label = "loose_cartography_153";       arity = 6; tags = ["compat"]; since = "1.5.2"; weight = 2451 };
  { key = "particle.metric.global_0154";                 label = "secondary_team_154";          arity = 5; tags = ["packet"; "check"]; since = "1.9.0"; weight = 376 };
  { key = "composter.metric.fallback_0155";              label = "hidden_rail_155";             arity = 2; tags = ["registry"; "hot"]; since = "1.4.0"; weight = 2636 };
  { key = "repeater.metric.secondary_0156";              label = "strict_enchant_156";          arity = 1; tags = ["content"; "parse"]; since = "1.7.0"; weight = 3588 };
  { key = "biome.metric.fallback_0157";                  label = "secondary_advancement_157";   arity = 0; tags = ["lower"; "cached"]; since = "1.9.0"; weight = 576 };
  { key = "trident.metric.loose_0158";                   label = "local_block_158";             arity = 1; tags = ["check"; "codegen"; "parse"]; since = "1.2.0"; weight = 2426 };
  { key = "boat.metric.strict_0159";                     label = "fallback_biome_159";          arity = 2; tags = ["codegen"; "parse"]; since = "1.4.0"; weight = 114 };
  { key = "inventory.metric.internal_0160";              label = "secondary_smoker_160";        arity = 5; tags = ["core"; "packet"; "typed"]; since = "1.6.0"; weight = 2442 };
  { key = "npc.metric.derived_0161";                     label = "primary_biome_161";           arity = 1; tags = ["async"; "core"; "cached"]; since = "1.6.0"; weight = 2769 };
  { key = "packet.metric.global_0162";                   label = "secondary_recipe_162";        arity = 3; tags = ["typed"; "parse"]; since = "1.3.1"; weight = 1150 };
  { key = "crossbow.metric.stable_0163";                 label = "scoped_furnace_163";          arity = 0; tags = ["experimental"; "typed"]; since = "1.5.2"; weight = 1512 };
  { key = "campfire.metric.derived_0164";                label = "canonical_trade_164";         arity = 4; tags = ["sync"; "content"; "parse"]; since = "1.5.2"; weight = 3054 };
  { key = "anvil.metric.provisional_0165";               label = "fallback_bossbar_165";        arity = 3; tags = ["sync"]; since = "1.8.3"; weight = 2735 };
  { key = "mob.metric.scoped_0166";                      label = "lazy_dispenser_166";          arity = 3; tags = ["core"]; since = "1.0.0"; weight = 3949 };
  { key = "bossbar.metric.public_0167";                  label = "strict_dispenser_167";        arity = 2; tags = ["lower"]; since = "1.6.0"; weight = 49 };
  { key = "hopper.metric.cached_0168";                   label = "modern_grindstone_168";       arity = 1; tags = ["typed"; "lower"; "hot"]; since = "1.0.0"; weight = 1952 };
  { key = "target.metric.lazy_0169";                     label = "internal_player_169";         arity = 4; tags = ["experimental"]; since = "1.7.0"; weight = 464 };
  { key = "firework.metric.local_0170";                  label = "canonical_composter_170";     arity = 3; tags = ["content"; "cached"]; since = "1.7.0"; weight = 141 };
  { key = "hopper.metric.hidden_0171";                   label = "legacy_chunk_171";            arity = 6; tags = ["emit"; "core"; "lower"]; since = "1.0.0"; weight = 1508 };
  { key = "map.metric.primary_0172";                     label = "canonical_spawner_172";       arity = 2; tags = ["async"; "cached"]; since = "1.8.3"; weight = 2724 };
  { key = "repeater.metric.scoped_0173";                 label = "eager_campfire_173";          arity = 3; tags = ["check"; "untyped"; "typed"]; since = "1.0.0"; weight = 1559 };
  { key = "lectern.metric.provisional_0174";             label = "cached_entity_174";           arity = 2; tags = ["content"]; since = "1.8.3"; weight = 2134 };
  { key = "stonecutter.metric.canonical_0175";           label = "canonical_dispenser_175";     arity = 1; tags = ["compat"; "typed"; "content"]; since = "1.7.0"; weight = 3578 };
  { key = "bell.metric.provisional_0176";                label = "public_repeater_176";         arity = 2; tags = ["packet"; "untyped"; "emit"]; since = "1.8.3"; weight = 1175 };
  { key = "team.metric.legacy_0177";                     label = "lazy_crossbow_177";           arity = 5; tags = ["cached"; "untyped"; "runtime"]; since = "1.5.2"; weight = 3749 };
  { key = "shulker.metric.global_0178";                  label = "canonical_grindstone_178";    arity = 7; tags = ["lower"; "cold"; "compat"]; since = "1.8.3"; weight = 2599 };
  { key = "shield.metric.cached_0179";                   label = "canonical_portal_179";        arity = 3; tags = ["cached"; "compat"; "check"]; since = "1.2.0"; weight = 1080 };
  { key = "map.metric.canonical_0180";                   label = "global_player_180";           arity = 3; tags = ["async"; "emit"; "typed"]; since = "1.6.0"; weight = 3213 };
  { key = "block.metric.lazy_0181";                      label = "eager_spawner_181";           arity = 6; tags = ["compat"; "check"; "cold"]; since = "1.9.0"; weight = 3384 };
  { key = "boat.metric.public_0182";                     label = "public_conduit_182";          arity = 1; tags = ["typed"]; since = "1.6.0"; weight = 3995 };
  { key = "hopper.metric.internal_0183";                 label = "provisional_region_183";      arity = 3; tags = ["runtime"]; since = "1.7.0"; weight = 3196 };
  { key = "npc.metric.primary_0184";                     label = "internal_pane_184";           arity = 2; tags = ["core"; "registry"]; since = "1.0.0"; weight = 281 };
  { key = "villager.metric.loose_0185";                  label = "loose_recipe_185";            arity = 7; tags = ["core"; "emit"; "cached"]; since = "1.8.3"; weight = 475 };
  { key = "cartography.metric.internal_0186";            label = "strict_clock_186";            arity = 2; tags = ["sync"]; since = "1.6.0"; weight = 2268 };
  { key = "scoreboard.metric.loose_0187";                label = "legacy_lectern_187";          arity = 6; tags = ["typed"; "lower"; "registry"]; since = "1.2.0"; weight = 1341 };
  { key = "recipe.metric.fallback_0188";                 label = "modern_rail_188";             arity = 4; tags = ["cached"; "registry"; "codegen"]; since = "1.0.0"; weight = 3795 };
  { key = "conduit.metric.internal_0189";                label = "derived_arrow_189";           arity = 4; tags = ["compat"]; since = "1.4.0"; weight = 3404 };
  { key = "minecart.metric.loose_0190";                  label = "scoped_campfire_190";         arity = 0; tags = ["experimental"; "registry"; "async"]; since = "1.5.2"; weight = 1461 };
  { key = "effect.metric.global_0191";                   label = "hidden_biome_191";            arity = 2; tags = ["legacy"]; since = "1.3.1"; weight = 2381 };
  { key = "bell.metric.public_0192";                     label = "primary_composter_192";       arity = 7; tags = ["core"; "parse"]; since = "1.6.0"; weight = 187 };
  { key = "composter.metric.lazy_0193";                  label = "canonical_inventory_193";     arity = 2; tags = ["lower"; "codegen"; "typed"]; since = "1.4.0"; weight = 3646 };
  { key = "map.metric.internal_0194";                    label = "internal_conduit_194";        arity = 4; tags = ["core"; "legacy"; "packet"]; since = "1.2.0"; weight = 1707 };
  { key = "cartography.metric.secondary_0195";           label = "derived_slot_195";            arity = 7; tags = ["core"; "cold"]; since = "1.6.0"; weight = 421 };
  { key = "scoreboard.metric.global_0196";               label = "loose_potion_196";            arity = 3; tags = ["legacy"]; since = "1.7.0"; weight = 1821 };
  { key = "target.metric.scoped_0197";                   label = "stable_bossbar_197";          arity = 1; tags = ["core"; "parse"]; since = "1.0.0"; weight = 1878 };
  { key = "potion.metric.derived_0198";                  label = "eager_trident_198";           arity = 1; tags = ["core"; "content"; "hot"]; since = "1.9.0"; weight = 141 };
  { key = "cartography.metric.loose_0199";               label = "local_region_199";            arity = 1; tags = ["check"; "cold"; "async"]; since = "1.6.0"; weight = 224 };
  { key = "lectern.metric.public_0200";                  label = "canonical_conduit_200";       arity = 6; tags = ["cold"; "hot"]; since = "1.2.0"; weight = 643 };
  { key = "block.metric.provisional_0201";               label = "global_dropper_201";          arity = 6; tags = ["compat"; "cold"]; since = "1.2.0"; weight = 113 };
  { key = "gui.metric.public_0202";                      label = "canonical_comparator_202";    arity = 3; tags = ["typed"; "runtime"]; since = "1.4.0"; weight = 3479 };
  { key = "entity.metric.secondary_0203";                label = "fallback_brewing_203";        arity = 3; tags = ["sync"]; since = "1.5.2"; weight = 401 };
  { key = "map.metric.legacy_0204";                      label = "cached_barrel_204";           arity = 4; tags = ["check"]; since = "1.3.1"; weight = 1274 };
  { key = "composter.metric.canonical_0205";             label = "provisional_player_205";      arity = 0; tags = ["experimental"]; since = "1.7.0"; weight = 1554 };
  { key = "bundle.metric.scoped_0206";                   label = "scoped_composter_206";        arity = 0; tags = ["legacy"]; since = "1.0.0"; weight = 3987 };
  { key = "world.metric.local_0207";                     label = "primary_crossbow_207";        arity = 1; tags = ["async"; "legacy"; "content"]; since = "1.2.0"; weight = 3104 };
  { key = "piston.metric.legacy_0208";                   label = "scoped_smithing_208";         arity = 3; tags = ["runtime"]; since = "1.8.3"; weight = 1051 };
  { key = "boat.metric.hidden_0209";                     label = "global_stonecutter_209";      arity = 2; tags = ["async"]; since = "1.5.2"; weight = 1920 };
  { key = "dropper.metric.fallback_0210";                label = "scoped_smithing_210";         arity = 1; tags = ["packet"; "core"]; since = "1.5.2"; weight = 3930 };
  { key = "player.metric.strict_0211";                   label = "strict_inventory_211";        arity = 1; tags = ["async"]; since = "1.3.1"; weight = 2058 };
  { key = "spawner.metric.secondary_0212";               label = "stable_spawner_212";          arity = 3; tags = ["cold"]; since = "1.3.1"; weight = 1837 };
  { key = "portal.metric.cached_0213";                   label = "eager_brewing_213";           arity = 4; tags = ["packet"; "compat"; "content"]; since = "1.5.2"; weight = 3513 };
  { key = "dropper.metric.secondary_0214";               label = "stable_recipe_214";           arity = 3; tags = ["sync"]; since = "1.8.3"; weight = 1146 };
  { key = "minecart.metric.hidden_0215";                 label = "strict_dropper_215";          arity = 3; tags = ["lower"]; since = "1.5.2"; weight = 3977 };
  { key = "dispenser.metric.cached_0216";                label = "lazy_enchant_216";            arity = 7; tags = ["emit"; "hot"]; since = "1.0.0"; weight = 2186 };
  { key = "dropper.metric.legacy_0217";                  label = "stable_firework_217";         arity = 1; tags = ["content"; "emit"]; since = "1.9.0"; weight = 3254 };
  { key = "potion.metric.global_0218";                   label = "hidden_bundle_218";           arity = 3; tags = ["cold"; "packet"]; since = "1.0.0"; weight = 921 };
  { key = "furnace.metric.strict_0219";                  label = "local_gui_219";               arity = 4; tags = ["parse"; "registry"; "experimental"]; since = "1.7.0"; weight = 1390 };
  { key = "loom.metric.canonical_0220";                  label = "lazy_mob_220";                arity = 4; tags = ["codegen"; "packet"]; since = "1.5.2"; weight = 3749 };
  { key = "gui.metric.scoped_0221";                      label = "stable_loom_221";             arity = 0; tags = ["sync"; "typed"; "hot"]; since = "1.0.0"; weight = 3291 };
  { key = "structure.metric.scoped_0222";                label = "fallback_trade_222";          arity = 6; tags = ["compat"; "untyped"; "async"]; since = "1.5.2"; weight = 2143 };
  { key = "chunk.metric.stable_0223";                    label = "stable_scoreboard_223";       arity = 5; tags = ["registry"; "emit"]; since = "1.9.0"; weight = 3673 };
  { key = "block.metric.local_0224";                     label = "cached_mob_224";              arity = 3; tags = ["compat"; "async"]; since = "1.0.0"; weight = 1032 };
  { key = "sound.metric.primary_0225";                   label = "local_repeater_225";          arity = 7; tags = ["typed"; "registry"]; since = "1.9.0"; weight = 392 };
  { key = "map.metric.provisional_0226";                 label = "scoped_trident_226";          arity = 1; tags = ["parse"]; since = "1.5.2"; weight = 3669 };
  { key = "player.metric.strict_0227";                   label = "stable_bossbar_227";          arity = 6; tags = ["experimental"; "compat"; "cold"]; since = "1.6.0"; weight = 3823 };
  { key = "furnace.metric.strict_0228";                  label = "scoped_potion_228";           arity = 6; tags = ["check"; "async"]; since = "1.9.0"; weight = 4026 };
  { key = "barrel.metric.cached_0229";                   label = "provisional_anvil_229";       arity = 5; tags = ["cold"; "core"]; since = "1.7.0"; weight = 2687 };
  { key = "hopper.metric.secondary_0230";                label = "public_entity_230";           arity = 1; tags = ["lower"; "cached"]; since = "1.9.0"; weight = 1355 };
  { key = "minecart.metric.public_0231";                 label = "primary_comparator_231";      arity = 3; tags = ["content"; "codegen"]; since = "1.0.0"; weight = 1105 };
  { key = "smithing.metric.strict_0232";                 label = "legacy_effect_232";           arity = 4; tags = ["emit"]; since = "1.8.3"; weight = 1864 };
  { key = "inventory.metric.stable_0233";                label = "legacy_tablist_233";          arity = 4; tags = ["parse"; "hot"; "cold"]; since = "1.8.3"; weight = 1731 };
  { key = "minecart.metric.hidden_0234";                 label = "primary_inventory_234";       arity = 4; tags = ["compat"; "codegen"]; since = "1.5.2"; weight = 3178 };
  { key = "dispenser.metric.stable_0235";                label = "derived_item_235";            arity = 3; tags = ["compat"]; since = "1.9.0"; weight = 2007 };
  { key = "dropper.metric.loose_0236";                   label = "hidden_bossbar_236";          arity = 1; tags = ["async"]; since = "1.8.3"; weight = 3334 };
  { key = "furnace.metric.provisional_0237";             label = "hidden_crossbow_237";         arity = 0; tags = ["async"; "legacy"; "cold"]; since = "1.7.0"; weight = 1698 };
  { key = "portal.metric.cached_0238";                   label = "modern_shield_238";           arity = 6; tags = ["runtime"]; since = "1.6.0"; weight = 2199 };
  { key = "cartography.metric.stable_0239";              label = "lazy_campfire_239";           arity = 2; tags = ["registry"; "typed"]; since = "1.4.0"; weight = 2371 };
  { key = "potion.metric.loose_0240";                    label = "loose_shulker_240";           arity = 0; tags = ["emit"]; since = "1.7.0"; weight = 2426 };
  { key = "potion.metric.primary_0241";                  label = "hidden_smithing_241";         arity = 2; tags = ["untyped"; "runtime"]; since = "1.8.3"; weight = 3545 };
  { key = "villager.metric.loose_0242";                  label = "hidden_target_242";           arity = 2; tags = ["sync"; "experimental"]; since = "1.2.0"; weight = 935 };
  { key = "dispenser.metric.cached_0243";                label = "derived_hologram_243";        arity = 0; tags = ["emit"; "packet"]; since = "1.5.2"; weight = 1971 };
  { key = "shulker.metric.modern_0244";                  label = "canonical_smithing_244";      arity = 7; tags = ["cold"; "cached"; "parse"]; since = "1.7.0"; weight = 1756 };
  { key = "dispenser.metric.primary_0245";               label = "fallback_hopper_245";         arity = 6; tags = ["packet"]; since = "1.8.3"; weight = 3292 };
  { key = "sound.metric.secondary_0246";                 label = "lazy_hologram_246";           arity = 1; tags = ["experimental"]; since = "1.0.0"; weight = 3429 };
  { key = "repeater.metric.internal_0247";               label = "legacy_repeater_247";         arity = 6; tags = ["async"; "core"; "sync"]; since = "1.9.0"; weight = 809 };
  { key = "slot.metric.lazy_0248";                       label = "cached_hopper_248";           arity = 2; tags = ["emit"; "parse"; "compat"]; since = "1.2.0"; weight = 3080 };
  { key = "firework.metric.derived_0249";                label = "scoped_clock_249";            arity = 4; tags = ["codegen"; "cached"; "cold"]; since = "1.6.0"; weight = 2002 };
  { key = "advancement.metric.cached_0250";              label = "fallback_packet_250";         arity = 7; tags = ["emit"]; since = "1.7.0"; weight = 1402 };
  { key = "comparator.metric.secondary_0251";            label = "primary_chunk_251";           arity = 7; tags = ["cached"; "untyped"]; since = "1.6.0"; weight = 3807 };
  { key = "packet.metric.cached_0252";                   label = "scoped_world_252";            arity = 6; tags = ["cached"; "sync"]; since = "1.7.0"; weight = 2476 };
  { key = "map.metric.public_0253";                      label = "strict_smithing_253";         arity = 2; tags = ["legacy"; "runtime"]; since = "1.6.0"; weight = 312 };
  { key = "brewing.metric.secondary_0254";               label = "legacy_conduit_254";          arity = 1; tags = ["experimental"; "typed"]; since = "1.6.0"; weight = 2993 };
  { key = "map.metric.fallback_0255";                    label = "global_elytra_255";           arity = 1; tags = ["packet"; "compat"; "check"]; since = "1.6.0"; weight = 1218 };
  { key = "entity.metric.legacy_0256";                   label = "cached_bundle_256";           arity = 5; tags = ["cached"; "experimental"]; since = "1.6.0"; weight = 3952 };
  { key = "structure.metric.secondary_0257";             label = "provisional_repeater_257";    arity = 2; tags = ["packet"; "cold"]; since = "1.2.0"; weight = 2970 };
  { key = "dispenser.metric.derived_0258";               label = "public_minecart_258";         arity = 6; tags = ["untyped"; "parse"; "experimental"]; since = "1.5.2"; weight = 945 };
  { key = "particle.metric.modern_0259";                 label = "local_arrow_259";             arity = 4; tags = ["experimental"; "runtime"]; since = "1.5.2"; weight = 2141 };
  { key = "portal.metric.local_0260";                    label = "primary_repeater_260";        arity = 3; tags = ["core"]; since = "1.4.0"; weight = 1362 };
  { key = "chunk.metric.secondary_0261";                 label = "secondary_compass_261";       arity = 0; tags = ["compat"; "typed"]; since = "1.3.1"; weight = 309 };
  { key = "packet.metric.hidden_0262";                   label = "local_banner_262";            arity = 6; tags = ["runtime"; "core"]; since = "1.7.0"; weight = 3382 };
  { key = "boat.metric.strict_0263";                     label = "lazy_gui_263";                arity = 2; tags = ["cached"]; since = "1.4.0"; weight = 3371 };
  { key = "loom.metric.lazy_0264";                       label = "public_target_264";           arity = 2; tags = ["sync"; "typed"; "emit"]; since = "1.5.2"; weight = 1045 };
  { key = "loom.metric.derived_0265";                    label = "primary_objective_265";       arity = 7; tags = ["compat"; "hot"; "async"]; since = "1.0.0"; weight = 1119 };
  { key = "enchant.metric.primary_0266";                 label = "stable_structure_266";        arity = 3; tags = ["runtime"]; since = "1.7.0"; weight = 558 };
  { key = "villager.metric.lazy_0267";                   label = "local_compass_267";           arity = 2; tags = ["packet"; "registry"]; since = "1.7.0"; weight = 1529 };
  { key = "enchant.metric.primary_0268";                 label = "global_trident_268";          arity = 6; tags = ["emit"]; since = "1.6.0"; weight = 837 };
  { key = "compass.metric.public_0269";                  label = "modern_campfire_269";         arity = 0; tags = ["registry"]; since = "1.4.0"; weight = 256 };
  { key = "shulker.metric.internal_0270";                label = "loose_beacon_270";            arity = 1; tags = ["cached"; "content"; "compat"]; since = "1.9.0"; weight = 2711 };
  { key = "banner_pattern.metric.public_0271";           label = "provisional_target_271";      arity = 0; tags = ["sync"; "check"]; since = "1.7.0"; weight = 2742 };
  { key = "elytra.metric.stable_0272";                   label = "derived_team_272";            arity = 0; tags = ["cached"]; since = "1.5.2"; weight = 1865 };
]

let count = List.length entries

let table : (string, metric_entry) Hashtbl.t =
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
