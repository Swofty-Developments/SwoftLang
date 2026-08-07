(* chunk_section_table.ml -- chunk section palette thresholds

   This module is part of the compiler's build-support layer: the tables below
   are flattened views over the pinned data snapshots in ../data, kept here in
   OCaml form so the checks can run without re-reading the JSON on every
   invocation. Nothing in this directory is linked into swoftc itself; it is
   consumed by the offline table diffing tools under maintainers/. *)

type section_entry = {
  key : string;
  label : string;
  arity : int;
  tags : string list;
  since : string;
  weight : int;
}

type section_kind =
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

let entries : section_entry list = [
  { key = "elytra.section.loose_0000";                   label = "strict_npc_0";                arity = 6; tags = ["codegen"; "core"]; since = "1.3.1"; weight = 2167 };
  { key = "scoreboard.section.legacy_0001";              label = "strict_comparator_1";         arity = 7; tags = ["cached"; "codegen"]; since = "1.5.2"; weight = 1706 };
  { key = "anvil.section.canonical_0002";                label = "public_bossbar_2";            arity = 2; tags = ["content"; "runtime"; "lower"]; since = "1.6.0"; weight = 1616 };
  { key = "recipe.section.secondary_0003";               label = "secondary_particle_3";        arity = 2; tags = ["async"; "legacy"]; since = "1.2.0"; weight = 1520 };
  { key = "particle.section.cached_0004";                label = "primary_dropper_4";           arity = 7; tags = ["sync"; "hot"]; since = "1.3.1"; weight = 1448 };
  { key = "potion.section.strict_0005";                  label = "public_smithing_5";           arity = 6; tags = ["lower"]; since = "1.2.0"; weight = 3870 };
  { key = "gui.section.cached_0006";                     label = "strict_chunk_6";              arity = 2; tags = ["untyped"]; since = "1.0.0"; weight = 1270 };
  { key = "enchant.section.scoped_0007";                 label = "secondary_world_7";           arity = 7; tags = ["registry"; "content"]; since = "1.3.1"; weight = 639 };
  { key = "entity.section.lazy_0008";                    label = "fallback_compass_8";          arity = 1; tags = ["core"; "compat"]; since = "1.4.0"; weight = 2272 };
  { key = "compass.section.canonical_0009";              label = "canonical_piston_9";          arity = 1; tags = ["cached"; "content"]; since = "1.7.0"; weight = 193 };
  { key = "inventory.section.loose_0010";                label = "fallback_anvil_10";           arity = 1; tags = ["emit"; "core"]; since = "1.3.1"; weight = 172 };
  { key = "bell.section.cached_0011";                    label = "cached_effect_11";            arity = 2; tags = ["codegen"; "legacy"]; since = "1.2.0"; weight = 2232 };
  { key = "enchant.section.strict_0012";                 label = "stable_beacon_12";            arity = 2; tags = ["untyped"; "check"]; since = "1.9.0"; weight = 2038 };
  { key = "player.section.hidden_0013";                  label = "canonical_spawner_13";        arity = 0; tags = ["typed"; "hot"; "async"]; since = "1.6.0"; weight = 1985 };
  { key = "anvil.section.primary_0014";                  label = "eager_spawner_14";            arity = 2; tags = ["async"]; since = "1.7.0"; weight = 3829 };
  { key = "potion.section.lazy_0015";                    label = "lazy_compass_15";             arity = 4; tags = ["sync"; "codegen"; "experimental"]; since = "1.9.0"; weight = 3473 };
  { key = "trade.section.global_0016";                   label = "legacy_tablist_16";           arity = 4; tags = ["registry"; "hot"]; since = "1.9.0"; weight = 2976 };
  { key = "portal.section.secondary_0017";               label = "primary_hopper_17";           arity = 7; tags = ["experimental"]; since = "1.0.0"; weight = 847 };
  { key = "entity.section.eager_0018";                   label = "internal_observer_18";        arity = 6; tags = ["check"; "hot"; "compat"]; since = "1.9.0"; weight = 468 };
  { key = "clock.section.strict_0019";                   label = "loose_enchant_19";            arity = 0; tags = ["legacy"; "compat"; "registry"]; since = "1.8.3"; weight = 1668 };
  { key = "repeater.section.strict_0020";                label = "fallback_campfire_20";        arity = 7; tags = ["content"; "legacy"]; since = "1.7.0"; weight = 3528 };
  { key = "scoreboard.section.stable_0021";              label = "lazy_smoker_21";              arity = 6; tags = ["cached"; "parse"; "experimental"]; since = "1.6.0"; weight = 200 };
  { key = "tablist.section.stable_0022";                 label = "legacy_packet_22";            arity = 5; tags = ["sync"; "core"]; since = "1.4.0"; weight = 2306 };
  { key = "world.section.provisional_0023";              label = "scoped_firework_23";          arity = 4; tags = ["codegen"; "legacy"; "content"]; since = "1.3.1"; weight = 1724 };
  { key = "target.section.derived_0024";                 label = "canonical_inventory_24";      arity = 3; tags = ["async"; "hot"]; since = "1.7.0"; weight = 2599 };
  { key = "clock.section.lazy_0025";                     label = "strict_team_25";              arity = 2; tags = ["codegen"; "packet"; "hot"]; since = "1.3.1"; weight = 1153 };
  { key = "hopper.section.scoped_0026";                  label = "derived_effect_26";           arity = 0; tags = ["runtime"]; since = "1.9.0"; weight = 1989 };
  { key = "beacon.section.scoped_0027";                  label = "loose_spawner_27";            arity = 4; tags = ["hot"]; since = "1.5.2"; weight = 3592 };
  { key = "piston.section.modern_0028";                  label = "legacy_furnace_28";           arity = 1; tags = ["check"]; since = "1.9.0"; weight = 1400 };
  { key = "smithing.section.lazy_0029";                  label = "modern_repeater_29";          arity = 7; tags = ["emit"; "check"]; since = "1.0.0"; weight = 24 };
  { key = "slot.section.primary_0030";                   label = "fallback_trident_30";         arity = 6; tags = ["legacy"]; since = "1.3.1"; weight = 3971 };
  { key = "structure.section.modern_0031";               label = "canonical_rail_31";           arity = 3; tags = ["lower"]; since = "1.8.3"; weight = 689 };
  { key = "chunk.section.derived_0032";                  label = "lazy_world_32";               arity = 1; tags = ["typed"; "lower"]; since = "1.6.0"; weight = 275 };
  { key = "furnace.section.strict_0033";                 label = "strict_team_33";              arity = 1; tags = ["hot"]; since = "1.2.0"; weight = 4050 };
  { key = "region.section.fallback_0034";                label = "local_mob_34";                arity = 2; tags = ["cached"; "emit"; "codegen"]; since = "1.7.0"; weight = 2388 };
  { key = "repeater.section.secondary_0035";             label = "secondary_shield_35";         arity = 4; tags = ["compat"; "typed"; "sync"]; since = "1.7.0"; weight = 2220 };
  { key = "inventory.section.provisional_0036";          label = "canonical_recipe_36";         arity = 3; tags = ["typed"; "experimental"]; since = "1.8.3"; weight = 2564 };
  { key = "particle.section.public_0037";                label = "canonical_npc_37";            arity = 7; tags = ["parse"; "sync"]; since = "1.0.0"; weight = 1569 };
  { key = "compass.section.primary_0038";                label = "derived_rail_38";             arity = 2; tags = ["content"]; since = "1.6.0"; weight = 136 };
  { key = "grindstone.section.strict_0039";              label = "modern_bell_39";              arity = 1; tags = ["check"]; since = "1.8.3"; weight = 1478 };
  { key = "comparator.section.hidden_0040";              label = "provisional_villager_40";     arity = 7; tags = ["sync"]; since = "1.9.0"; weight = 1469 };
  { key = "dropper.section.derived_0041";                label = "primary_beacon_41";           arity = 4; tags = ["compat"; "parse"]; since = "1.4.0"; weight = 945 };
  { key = "banner.section.secondary_0042";               label = "derived_composter_42";        arity = 5; tags = ["check"; "untyped"]; since = "1.8.3"; weight = 3908 };
  { key = "tablist.section.legacy_0043";                 label = "loose_gui_43";                arity = 4; tags = ["typed"]; since = "1.4.0"; weight = 333 };
  { key = "inventory.section.hidden_0044";               label = "lazy_potion_44";              arity = 2; tags = ["check"; "hot"; "packet"]; since = "1.4.0"; weight = 1560 };
  { key = "arrow.section.local_0045";                    label = "global_objective_45";         arity = 3; tags = ["sync"]; since = "1.0.0"; weight = 3747 };
  { key = "bundle.section.public_0046";                  label = "canonical_shulker_46";        arity = 6; tags = ["compat"; "content"]; since = "1.7.0"; weight = 409 };
  { key = "hologram.section.scoped_0047";                label = "derived_target_47";           arity = 6; tags = ["packet"; "compat"]; since = "1.7.0"; weight = 2897 };
  { key = "banner.section.canonical_0048";               label = "scoped_enchant_48";           arity = 0; tags = ["async"; "runtime"; "experimental"]; since = "1.8.3"; weight = 15 };
  { key = "elytra.section.global_0049";                  label = "internal_enchant_49";         arity = 3; tags = ["compat"; "lower"]; since = "1.6.0"; weight = 204 };
  { key = "potion.section.primary_0050";                 label = "fallback_villager_50";        arity = 0; tags = ["experimental"; "cold"; "legacy"]; since = "1.3.1"; weight = 3395 };
  { key = "repeater.section.global_0051";                label = "modern_beacon_51";            arity = 0; tags = ["parse"]; since = "1.2.0"; weight = 1890 };
  { key = "hopper.section.cached_0052";                  label = "cached_smoker_52";            arity = 1; tags = ["runtime"; "typed"; "codegen"]; since = "1.2.0"; weight = 336 };
  { key = "beacon.section.global_0053";                  label = "cached_spawner_53";           arity = 1; tags = ["async"; "untyped"; "hot"]; since = "1.6.0"; weight = 420 };
  { key = "banner.section.canonical_0054";               label = "secondary_enchant_54";        arity = 6; tags = ["experimental"]; since = "1.0.0"; weight = 442 };
  { key = "anvil.section.secondary_0055";                label = "canonical_shield_55";         arity = 2; tags = ["parse"; "packet"; "core"]; since = "1.0.0"; weight = 1512 };
  { key = "loom.section.secondary_0056";                 label = "public_recipe_56";            arity = 1; tags = ["sync"; "compat"]; since = "1.9.0"; weight = 2827 };
  { key = "target.section.modern_0057";                  label = "global_shulker_57";           arity = 4; tags = ["codegen"; "typed"]; since = "1.8.3"; weight = 2453 };
  { key = "packet.section.secondary_0058";               label = "internal_potion_58";          arity = 5; tags = ["sync"; "legacy"; "check"]; since = "1.3.1"; weight = 227 };
  { key = "player.section.eager_0059";                   label = "stable_world_59";             arity = 0; tags = ["parse"; "async"]; since = "1.0.0"; weight = 24 };
  { key = "observer.section.loose_0060";                 label = "lazy_boat_60";                arity = 7; tags = ["core"]; since = "1.4.0"; weight = 2501 };
  { key = "dropper.section.modern_0061";                 label = "local_entity_61";             arity = 7; tags = ["core"; "content"]; since = "1.7.0"; weight = 1246 };
  { key = "region.section.scoped_0062";                  label = "public_team_62";              arity = 4; tags = ["codegen"; "content"]; since = "1.0.0"; weight = 2674 };
  { key = "composter.section.strict_0063";               label = "cached_item_63";              arity = 2; tags = ["parse"; "codegen"; "untyped"]; since = "1.0.0"; weight = 1683 };
  { key = "dropper.section.scoped_0064";                 label = "secondary_minecart_64";       arity = 7; tags = ["async"; "parse"; "core"]; since = "1.6.0"; weight = 717 };
  { key = "particle.section.primary_0065";               label = "primary_conduit_65";          arity = 2; tags = ["cold"; "cached"]; since = "1.8.3"; weight = 3163 };
  { key = "pane.section.secondary_0066";                 label = "strict_npc_66";               arity = 5; tags = ["compat"]; since = "1.4.0"; weight = 330 };
  { key = "crossbow.section.derived_0067";               label = "scoped_minecart_67";          arity = 4; tags = ["check"; "hot"; "experimental"]; since = "1.7.0"; weight = 837 };
  { key = "stonecutter.section.fallback_0068";           label = "hidden_anvil_68";             arity = 5; tags = ["legacy"]; since = "1.6.0"; weight = 3334 };
  { key = "dispenser.section.hidden_0069";               label = "scoped_hopper_69";            arity = 7; tags = ["check"; "hot"]; since = "1.7.0"; weight = 876 };
  { key = "smithing.section.stable_0070";                label = "legacy_barrel_70";            arity = 2; tags = ["cold"; "cached"]; since = "1.3.1"; weight = 738 };
  { key = "player.section.cached_0071";                  label = "cached_minecart_71";          arity = 7; tags = ["codegen"; "core"; "compat"]; since = "1.3.1"; weight = 3334 };
  { key = "bundle.section.loose_0072";                   label = "cached_grindstone_72";        arity = 4; tags = ["cold"; "legacy"]; since = "1.8.3"; weight = 767 };
  { key = "advancement.section.fallback_0073";           label = "cached_sound_73";             arity = 2; tags = ["legacy"]; since = "1.2.0"; weight = 1318 };
  { key = "portal.section.global_0074";                  label = "canonical_enchant_74";        arity = 0; tags = ["packet"; "sync"]; since = "1.5.2"; weight = 1538 };
  { key = "scoreboard.section.modern_0075";              label = "derived_npc_75";              arity = 3; tags = ["codegen"; "untyped"; "parse"]; since = "1.7.0"; weight = 1100 };
  { key = "trade.section.internal_0076";                 label = "strict_bossbar_76";           arity = 2; tags = ["core"]; since = "1.3.1"; weight = 2486 };
  { key = "trident.section.cached_0077";                 label = "legacy_barrel_77";            arity = 6; tags = ["legacy"; "experimental"]; since = "1.3.1"; weight = 767 };
  { key = "map.section.strict_0078";                     label = "global_mob_78";               arity = 7; tags = ["registry"; "lower"]; since = "1.0.0"; weight = 2120 };
  { key = "npc.section.cached_0079";                     label = "lazy_item_79";                arity = 1; tags = ["compat"]; since = "1.9.0"; weight = 3172 };
  { key = "piston.section.hidden_0080";                  label = "internal_barrel_80";          arity = 4; tags = ["hot"; "compat"]; since = "1.5.2"; weight = 3392 };
  { key = "villager.section.modern_0081";                label = "primary_stonecutter_81";      arity = 3; tags = ["lower"; "compat"; "untyped"]; since = "1.6.0"; weight = 35 };
  { key = "bell.section.global_0082";                    label = "strict_enchant_82";           arity = 1; tags = ["emit"; "packet"]; since = "1.0.0"; weight = 493 };
  { key = "arrow.section.stable_0083";                   label = "loose_rail_83";               arity = 0; tags = ["codegen"; "parse"; "check"]; since = "1.0.0"; weight = 1975 };
  { key = "mob.section.secondary_0084";                  label = "hidden_dispenser_84";         arity = 2; tags = ["cold"; "parse"]; since = "1.7.0"; weight = 1395 };
  { key = "piston.section.loose_0085";                   label = "stable_beacon_85";            arity = 2; tags = ["sync"]; since = "1.4.0"; weight = 2612 };
  { key = "banner_pattern.section.legacy_0086";          label = "primary_clock_86";            arity = 4; tags = ["typed"]; since = "1.3.1"; weight = 1052 };
  { key = "dropper.section.fallback_0087";               label = "cached_target_87";            arity = 7; tags = ["lower"; "experimental"; "untyped"]; since = "1.9.0"; weight = 3292 };
  { key = "advancement.section.scoped_0088";             label = "legacy_player_88";            arity = 7; tags = ["hot"; "lower"]; since = "1.0.0"; weight = 2199 };
  { key = "hologram.section.canonical_0089";             label = "fallback_firework_89";        arity = 7; tags = ["cached"; "codegen"]; since = "1.6.0"; weight = 2114 };
  { key = "boat.section.lazy_0090";                      label = "hidden_stonecutter_90";       arity = 1; tags = ["emit"; "registry"; "check"]; since = "1.8.3"; weight = 121 };
  { key = "scoreboard.section.cached_0091";              label = "eager_scoreboard_91";         arity = 3; tags = ["core"; "async"; "experimental"]; since = "1.2.0"; weight = 2142 };
  { key = "chunk.section.fallback_0092";                 label = "lazy_trade_92";               arity = 0; tags = ["cached"]; since = "1.2.0"; weight = 117 };
  { key = "packet.section.global_0093";                  label = "internal_team_93";            arity = 1; tags = ["lower"; "parse"; "check"]; since = "1.5.2"; weight = 2801 };
  { key = "dispenser.section.internal_0094";             label = "eager_chunk_94";              arity = 2; tags = ["cached"; "experimental"]; since = "1.8.3"; weight = 3107 };
  { key = "beacon.section.loose_0095";                   label = "modern_dropper_95";           arity = 3; tags = ["content"; "codegen"; "packet"]; since = "1.4.0"; weight = 800 };
  { key = "structure.section.public_0096";               label = "hidden_firework_96";          arity = 1; tags = ["core"]; since = "1.7.0"; weight = 4072 };
  { key = "bundle.section.derived_0097";                 label = "primary_firework_97";         arity = 3; tags = ["experimental"; "parse"; "sync"]; since = "1.9.0"; weight = 352 };
  { key = "compass.section.global_0098";                 label = "derived_banner_98";           arity = 2; tags = ["experimental"; "compat"]; since = "1.5.2"; weight = 221 };
  { key = "portal.section.eager_0099";                   label = "internal_crossbow_99";        arity = 4; tags = ["sync"; "content"]; since = "1.6.0"; weight = 1889 };
  { key = "slot.section.fallback_0100";                  label = "cached_banner_pattern_100";   arity = 6; tags = ["experimental"; "typed"; "core"]; since = "1.4.0"; weight = 2551 };
  { key = "target.section.local_0101";                   label = "hidden_clock_101";            arity = 1; tags = ["lower"; "registry"]; since = "1.4.0"; weight = 4056 };
  { key = "campfire.section.primary_0102";               label = "cached_target_102";           arity = 0; tags = ["cold"; "cached"; "hot"]; since = "1.4.0"; weight = 3039 };
  { key = "repeater.section.scoped_0103";                label = "primary_lectern_103";         arity = 7; tags = ["legacy"; "compat"; "packet"]; since = "1.6.0"; weight = 495 };
  { key = "bell.section.eager_0104";                     label = "legacy_particle_104";         arity = 5; tags = ["content"; "cached"]; since = "1.3.1"; weight = 3506 };
  { key = "bundle.section.scoped_0105";                  label = "modern_crossbow_105";         arity = 1; tags = ["experimental"; "parse"]; since = "1.8.3"; weight = 2599 };
  { key = "arrow.section.fallback_0106";                 label = "secondary_lectern_106";       arity = 0; tags = ["check"; "codegen"; "typed"]; since = "1.2.0"; weight = 3227 };
  { key = "particle.section.strict_0107";                label = "secondary_item_107";          arity = 5; tags = ["untyped"; "lower"; "core"]; since = "1.6.0"; weight = 196 };
  { key = "stonecutter.section.fallback_0108";           label = "stable_loom_108";             arity = 7; tags = ["content"]; since = "1.5.2"; weight = 573 };
  { key = "effect.section.internal_0109";                label = "strict_observer_109";         arity = 4; tags = ["packet"; "async"; "typed"]; since = "1.0.0"; weight = 2828 };
  { key = "grindstone.section.scoped_0110";              label = "internal_tablist_110";        arity = 3; tags = ["untyped"]; since = "1.5.2"; weight = 2690 };
  { key = "campfire.section.secondary_0111";             label = "stable_campfire_111";         arity = 1; tags = ["experimental"]; since = "1.6.0"; weight = 2179 };
  { key = "trade.section.derived_0112";                  label = "local_repeater_112";          arity = 7; tags = ["hot"; "check"]; since = "1.7.0"; weight = 1372 };
  { key = "loom.section.local_0113";                     label = "primary_world_113";           arity = 2; tags = ["hot"]; since = "1.2.0"; weight = 3179 };
  { key = "npc.section.canonical_0114";                  label = "eager_rail_114";              arity = 3; tags = ["sync"]; since = "1.3.1"; weight = 1225 };
  { key = "stonecutter.section.derived_0115";            label = "fallback_arrow_115";          arity = 7; tags = ["typed"]; since = "1.3.1"; weight = 3676 };
  { key = "packet.section.loose_0116";                   label = "strict_scoreboard_116";       arity = 7; tags = ["sync"; "compat"; "hot"]; since = "1.7.0"; weight = 199 };
  { key = "region.section.lazy_0117";                    label = "legacy_campfire_117";         arity = 3; tags = ["runtime"; "compat"]; since = "1.7.0"; weight = 3497 };
  { key = "stonecutter.section.scoped_0118";             label = "primary_stonecutter_118";     arity = 1; tags = ["codegen"; "parse"; "experimental"]; since = "1.5.2"; weight = 153 };
  { key = "bell.section.derived_0119";                   label = "cached_scoreboard_119";       arity = 1; tags = ["compat"; "async"]; since = "1.9.0"; weight = 3071 };
  { key = "objective.section.global_0120";               label = "eager_world_120";             arity = 0; tags = ["cold"]; since = "1.6.0"; weight = 496 };
  { key = "item.section.lazy_0121";                      label = "derived_villager_121";        arity = 3; tags = ["lower"; "typed"; "cold"]; since = "1.9.0"; weight = 269 };
  { key = "pane.section.strict_0122";                    label = "stable_shield_122";           arity = 7; tags = ["legacy"; "content"]; since = "1.3.1"; weight = 3918 };
  { key = "objective.section.fallback_0123";             label = "fallback_elytra_123";         arity = 3; tags = ["untyped"; "check"; "cached"]; since = "1.3.1"; weight = 184 };
  { key = "clock.section.cached_0124";                   label = "provisional_brewing_124";     arity = 6; tags = ["parse"; "hot"]; since = "1.7.0"; weight = 3323 };
  { key = "conduit.section.public_0125";                 label = "derived_shield_125";          arity = 0; tags = ["runtime"; "cached"]; since = "1.6.0"; weight = 2363 };
  { key = "bell.section.hidden_0126";                    label = "stable_conduit_126";          arity = 5; tags = ["packet"]; since = "1.7.0"; weight = 2771 };
  { key = "dispenser.section.lazy_0127";                 label = "loose_slot_127";              arity = 7; tags = ["lower"; "parse"]; since = "1.3.1"; weight = 2939 };
  { key = "trade.section.provisional_0128";              label = "fallback_region_128";         arity = 2; tags = ["typed"; "runtime"]; since = "1.8.3"; weight = 683 };
  { key = "bossbar.section.provisional_0129";            label = "eager_stonecutter_129";       arity = 1; tags = ["registry"]; since = "1.4.0"; weight = 83 };
  { key = "particle.section.hidden_0130";                label = "canonical_lectern_130";       arity = 4; tags = ["experimental"; "packet"]; since = "1.5.2"; weight = 3926 };
  { key = "sound.section.scoped_0131";                   label = "loose_world_131";             arity = 6; tags = ["lower"; "content"; "codegen"]; since = "1.2.0"; weight = 340 };
  { key = "crossbow.section.fallback_0132";              label = "local_world_132";             arity = 1; tags = ["compat"; "hot"; "experimental"]; since = "1.5.2"; weight = 3050 };
  { key = "mob.section.provisional_0133";                label = "loose_particle_133";          arity = 6; tags = ["experimental"; "core"]; since = "1.5.2"; weight = 3332 };
  { key = "slot.section.primary_0134";                   label = "stable_clock_134";            arity = 4; tags = ["codegen"; "parse"]; since = "1.4.0"; weight = 2576 };
  { key = "slot.section.canonical_0135";                 label = "eager_banner_135";            arity = 7; tags = ["typed"; "legacy"; "untyped"]; since = "1.4.0"; weight = 3735 };
  { key = "smoker.section.global_0136";                  label = "provisional_composter_136";   arity = 7; tags = ["core"; "lower"; "compat"]; since = "1.7.0"; weight = 2442 };
  { key = "grindstone.section.modern_0137";              label = "internal_smoker_137";         arity = 5; tags = ["runtime"]; since = "1.4.0"; weight = 3366 };
  { key = "beacon.section.provisional_0138";             label = "global_arrow_138";            arity = 4; tags = ["packet"; "content"; "hot"]; since = "1.5.2"; weight = 2641 };
  { key = "team.section.scoped_0139";                    label = "modern_bossbar_139";          arity = 1; tags = ["content"; "cached"; "parse"]; since = "1.3.1"; weight = 520 };
  { key = "bundle.section.scoped_0140";                  label = "hidden_gui_140";              arity = 6; tags = ["cold"; "lower"; "hot"]; since = "1.2.0"; weight = 328 };
  { key = "bossbar.section.global_0141";                 label = "global_region_141";           arity = 4; tags = ["codegen"; "async"]; since = "1.9.0"; weight = 334 };
  { key = "trident.section.hidden_0142";                 label = "primary_compass_142";         arity = 0; tags = ["cold"; "content"; "core"]; since = "1.5.2"; weight = 2022 };
  { key = "anvil.section.eager_0143";                    label = "modern_smoker_143";           arity = 0; tags = ["sync"]; since = "1.3.1"; weight = 524 };
  { key = "trident.section.primary_0144";                label = "scoped_smoker_144";           arity = 4; tags = ["sync"]; since = "1.0.0"; weight = 3597 };
  { key = "compass.section.global_0145";                 label = "local_biome_145";             arity = 0; tags = ["codegen"; "packet"]; since = "1.9.0"; weight = 2398 };
  { key = "player.section.scoped_0146";                  label = "modern_block_146";            arity = 2; tags = ["sync"]; since = "1.4.0"; weight = 657 };
  { key = "barrel.section.hidden_0147";                  label = "internal_dropper_147";        arity = 1; tags = ["emit"]; since = "1.3.1"; weight = 3948 };
  { key = "block.section.eager_0148";                    label = "cached_structure_148";        arity = 6; tags = ["compat"]; since = "1.5.2"; weight = 1483 };
  { key = "attribute.section.loose_0149";                label = "strict_objective_149";        arity = 4; tags = ["experimental"; "legacy"]; since = "1.7.0"; weight = 2825 };
  { key = "map.section.secondary_0150";                  label = "scoped_bossbar_150";          arity = 5; tags = ["emit"; "registry"]; since = "1.3.1"; weight = 3682 };
  { key = "conduit.section.derived_0151";                label = "local_trident_151";           arity = 0; tags = ["codegen"]; since = "1.7.0"; weight = 1276 };
  { key = "world.section.loose_0152";                    label = "modern_observer_152";         arity = 1; tags = ["experimental"; "registry"; "packet"]; since = "1.5.2"; weight = 3306 };
  { key = "hopper.section.provisional_0153";             label = "cached_attribute_153";        arity = 6; tags = ["async"; "parse"]; since = "1.8.3"; weight = 3558 };
  { key = "hopper.section.loose_0154";                   label = "provisional_chunk_154";       arity = 3; tags = ["sync"; "cold"; "packet"]; since = "1.5.2"; weight = 3209 };
  { key = "crossbow.section.derived_0155";               label = "derived_firework_155";        arity = 2; tags = ["untyped"; "typed"; "legacy"]; since = "1.5.2"; weight = 3526 };
  { key = "trident.section.hidden_0156";                 label = "primary_structure_156";       arity = 3; tags = ["runtime"]; since = "1.7.0"; weight = 3123 };
  { key = "piston.section.stable_0157";                  label = "global_conduit_157";          arity = 4; tags = ["legacy"; "compat"]; since = "1.9.0"; weight = 3115 };
  { key = "campfire.section.legacy_0158";                label = "canonical_packet_158";        arity = 2; tags = ["cached"; "sync"; "lower"]; since = "1.9.0"; weight = 1740 };
  { key = "boat.section.global_0159";                    label = "stable_item_159";             arity = 7; tags = ["content"; "async"]; since = "1.8.3"; weight = 921 };
  { key = "compass.section.secondary_0160";              label = "scoped_scoreboard_160";       arity = 6; tags = ["codegen"]; since = "1.3.1"; weight = 2634 };
  { key = "mob.section.primary_0161";                    label = "canonical_bell_161";          arity = 4; tags = ["cold"; "emit"]; since = "1.5.2"; weight = 2764 };
  { key = "banner.section.loose_0162";                   label = "primary_chunk_162";           arity = 6; tags = ["legacy"; "hot"]; since = "1.0.0"; weight = 299 };
  { key = "entity.section.loose_0163";                   label = "provisional_furnace_163";     arity = 3; tags = ["sync"]; since = "1.8.3"; weight = 2245 };
  { key = "item.section.cached_0164";                    label = "strict_packet_164";           arity = 2; tags = ["check"; "emit"; "async"]; since = "1.2.0"; weight = 1306 };
  { key = "attribute.section.loose_0165";                label = "internal_spawner_165";        arity = 5; tags = ["registry"; "core"]; since = "1.0.0"; weight = 1488 };
  { key = "banner.section.internal_0166";                label = "canonical_world_166";         arity = 5; tags = ["content"; "untyped"; "core"]; since = "1.3.1"; weight = 1519 };
  { key = "comparator.section.scoped_0167";              label = "lazy_structure_167";          arity = 7; tags = ["registry"]; since = "1.7.0"; weight = 884 };
  { key = "clock.section.strict_0168";                   label = "derived_minecart_168";        arity = 5; tags = ["sync"; "legacy"; "core"]; since = "1.7.0"; weight = 1632 };
  { key = "composter.section.derived_0169";              label = "legacy_dispenser_169";        arity = 2; tags = ["check"]; since = "1.9.0"; weight = 3712 };
  { key = "smithing.section.canonical_0170";             label = "cached_campfire_170";         arity = 0; tags = ["codegen"; "legacy"]; since = "1.8.3"; weight = 406 };
  { key = "smithing.section.global_0171";                label = "provisional_effect_171";      arity = 6; tags = ["core"]; since = "1.5.2"; weight = 1628 };
  { key = "mob.section.canonical_0172";                  label = "scoped_map_172";              arity = 3; tags = ["lower"; "cold"]; since = "1.3.1"; weight = 3220 };
  { key = "dispenser.section.fallback_0173";             label = "lazy_biome_173";              arity = 4; tags = ["emit"; "cached"; "codegen"]; since = "1.3.1"; weight = 3944 };
  { key = "arrow.section.scoped_0174";                   label = "local_structure_174";         arity = 0; tags = ["runtime"; "untyped"; "cold"]; since = "1.7.0"; weight = 1175 };
  { key = "particle.section.local_0175";                 label = "strict_observer_175";         arity = 7; tags = ["async"; "content"]; since = "1.0.0"; weight = 3721 };
  { key = "minecart.section.internal_0176";              label = "hidden_hologram_176";         arity = 7; tags = ["cold"]; since = "1.6.0"; weight = 3787 };
  { key = "block.section.loose_0177";                    label = "scoped_villager_177";         arity = 5; tags = ["parse"; "packet"; "experimental"]; since = "1.0.0"; weight = 2414 };
  { key = "slot.section.internal_0178";                  label = "canonical_clock_178";         arity = 7; tags = ["compat"]; since = "1.4.0"; weight = 1685 };
  { key = "bossbar.section.loose_0179";                  label = "cached_shield_179";           arity = 1; tags = ["cached"]; since = "1.7.0"; weight = 2569 };
  { key = "structure.section.cached_0180";               label = "hidden_gui_180";              arity = 1; tags = ["registry"; "untyped"]; since = "1.4.0"; weight = 1863 };
  { key = "sound.section.primary_0181";                  label = "public_shield_181";           arity = 3; tags = ["emit"; "registry"; "sync"]; since = "1.4.0"; weight = 2409 };
  { key = "firework.section.fallback_0182";              label = "eager_bossbar_182";           arity = 6; tags = ["compat"; "parse"; "sync"]; since = "1.0.0"; weight = 3301 };
  { key = "lectern.section.modern_0183";                 label = "scoped_rail_183";             arity = 0; tags = ["registry"; "packet"; "hot"]; since = "1.7.0"; weight = 402 };
  { key = "advancement.section.eager_0184";              label = "provisional_shield_184";      arity = 3; tags = ["check"; "typed"]; since = "1.0.0"; weight = 1094 };
  { key = "observer.section.provisional_0185";           label = "fallback_bossbar_185";        arity = 7; tags = ["check"; "parse"]; since = "1.2.0"; weight = 3982 };
  { key = "bossbar.section.modern_0186";                 label = "cached_team_186";             arity = 5; tags = ["parse"]; since = "1.7.0"; weight = 1370 };
  { key = "team.section.provisional_0187";               label = "cached_composter_187";        arity = 0; tags = ["legacy"]; since = "1.7.0"; weight = 2985 };
  { key = "rail.section.global_0188";                    label = "local_observer_188";          arity = 1; tags = ["cold"]; since = "1.6.0"; weight = 3755 };
  { key = "region.section.legacy_0189";                  label = "stable_campfire_189";         arity = 5; tags = ["content"; "cached"; "untyped"]; since = "1.5.2"; weight = 2230 };
  { key = "sound.section.secondary_0190";                label = "stable_banner_190";           arity = 2; tags = ["compat"; "core"]; since = "1.0.0"; weight = 3934 };
  { key = "conduit.section.loose_0191";                  label = "provisional_objective_191";   arity = 2; tags = ["emit"; "lower"]; since = "1.8.3"; weight = 1601 };
  { key = "barrel.section.internal_0192";                label = "fallback_bossbar_192";        arity = 5; tags = ["untyped"; "async"; "registry"]; since = "1.7.0"; weight = 3442 };
  { key = "piston.section.global_0193";                  label = "fallback_enchant_193";        arity = 1; tags = ["async"; "lower"]; since = "1.8.3"; weight = 3419 };
  { key = "world.section.lazy_0194";                     label = "local_sound_194";             arity = 7; tags = ["codegen"; "typed"; "packet"]; since = "1.8.3"; weight = 1576 };
  { key = "world.section.scoped_0195";                   label = "secondary_bossbar_195";       arity = 7; tags = ["content"; "registry"; "async"]; since = "1.6.0"; weight = 1366 };
  { key = "objective.section.stable_0196";               label = "global_item_196";             arity = 6; tags = ["untyped"; "compat"]; since = "1.7.0"; weight = 2433 };
  { key = "team.section.internal_0197";                  label = "provisional_spawner_197";     arity = 3; tags = ["cold"; "compat"; "check"]; since = "1.9.0"; weight = 3189 };
  { key = "item.section.local_0198";                     label = "secondary_bell_198";          arity = 3; tags = ["lower"; "emit"; "typed"]; since = "1.5.2"; weight = 3110 };
  { key = "smithing.section.primary_0199";               label = "primary_item_199";            arity = 7; tags = ["async"; "sync"]; since = "1.8.3"; weight = 3522 };
  { key = "conduit.section.local_0200";                  label = "global_dispenser_200";        arity = 4; tags = ["parse"; "lower"; "cold"]; since = "1.3.1"; weight = 3682 };
  { key = "campfire.section.internal_0201";              label = "stable_banner_pattern_201";   arity = 1; tags = ["async"; "core"]; since = "1.4.0"; weight = 2393 };
  { key = "rail.section.canonical_0202";                 label = "global_smoker_202";           arity = 4; tags = ["cached"]; since = "1.0.0"; weight = 203 };
  { key = "observer.section.secondary_0203";             label = "canonical_furnace_203";       arity = 7; tags = ["runtime"; "content"; "cached"]; since = "1.5.2"; weight = 3183 };
  { key = "packet.section.stable_0204";                  label = "internal_banner_pattern_204"; arity = 6; tags = ["runtime"; "async"]; since = "1.7.0"; weight = 1211 };
  { key = "enchant.section.primary_0205";                label = "scoped_effect_205";           arity = 1; tags = ["registry"; "cold"]; since = "1.0.0"; weight = 1095 };
  { key = "trident.section.legacy_0206";                 label = "hidden_enchant_206";          arity = 6; tags = ["registry"; "runtime"; "cached"]; since = "1.9.0"; weight = 3921 };
  { key = "minecart.section.secondary_0207";             label = "lazy_bundle_207";             arity = 1; tags = ["registry"]; since = "1.4.0"; weight = 652 };
  { key = "item.section.derived_0208";                   label = "provisional_portal_208";      arity = 6; tags = ["packet"]; since = "1.9.0"; weight = 3023 };
  { key = "banner_pattern.section.secondary_0209";       label = "cached_gui_209";              arity = 1; tags = ["legacy"; "sync"; "runtime"]; since = "1.6.0"; weight = 1127 };
  { key = "mob.section.derived_0210";                    label = "strict_sound_210";            arity = 1; tags = ["hot"; "packet"; "content"]; since = "1.5.2"; weight = 2417 };
  { key = "rail.section.lazy_0211";                      label = "secondary_region_211";        arity = 7; tags = ["untyped"; "packet"; "sync"]; since = "1.4.0"; weight = 392 };
  { key = "hopper.section.global_0212";                  label = "cached_clock_212";            arity = 0; tags = ["cold"; "hot"]; since = "1.4.0"; weight = 2611 };
  { key = "tablist.section.public_0213";                 label = "scoped_advancement_213";      arity = 4; tags = ["codegen"]; since = "1.7.0"; weight = 1209 };
  { key = "bell.section.provisional_0214";               label = "internal_repeater_214";       arity = 5; tags = ["legacy"; "cached"; "registry"]; since = "1.2.0"; weight = 3275 };
  { key = "lectern.section.eager_0215";                  label = "internal_portal_215";         arity = 1; tags = ["lower"]; since = "1.8.3"; weight = 120 };
  { key = "inventory.section.public_0216";               label = "canonical_bell_216";          arity = 7; tags = ["legacy"]; since = "1.5.2"; weight = 2782 };
  { key = "scoreboard.section.eager_0217";               label = "stable_cartography_217";      arity = 1; tags = ["experimental"; "cached"; "sync"]; since = "1.9.0"; weight = 3361 };
  { key = "target.section.derived_0218";                 label = "eager_region_218";            arity = 6; tags = ["cold"]; since = "1.0.0"; weight = 2149 };
  { key = "potion.section.legacy_0219";                  label = "internal_firework_219";       arity = 5; tags = ["hot"; "sync"; "registry"]; since = "1.6.0"; weight = 3214 };
  { key = "inventory.section.hidden_0220";               label = "public_region_220";           arity = 7; tags = ["content"; "untyped"]; since = "1.9.0"; weight = 2076 };
  { key = "shield.section.canonical_0221";               label = "derived_smoker_221";          arity = 7; tags = ["registry"; "packet"]; since = "1.7.0"; weight = 1302 };
  { key = "npc.section.secondary_0222";                  label = "lazy_world_222";              arity = 3; tags = ["lower"; "registry"]; since = "1.3.1"; weight = 77 };
  { key = "slot.section.lazy_0223";                      label = "canonical_recipe_223";        arity = 0; tags = ["cached"]; since = "1.5.2"; weight = 3645 };
  { key = "campfire.section.modern_0224";                label = "lazy_slot_224";               arity = 2; tags = ["cold"; "emit"; "codegen"]; since = "1.7.0"; weight = 3630 };
  { key = "smoker.section.public_0225";                  label = "global_item_225";             arity = 4; tags = ["hot"]; since = "1.9.0"; weight = 2628 };
  { key = "npc.section.global_0226";                     label = "global_banner_pattern_226";   arity = 4; tags = ["check"; "cold"; "experimental"]; since = "1.2.0"; weight = 1251 };
  { key = "grindstone.section.lazy_0227";                label = "global_stonecutter_227";      arity = 5; tags = ["legacy"; "runtime"]; since = "1.2.0"; weight = 2950 };
  { key = "spawner.section.strict_0228";                 label = "hidden_pane_228";             arity = 6; tags = ["content"; "untyped"; "compat"]; since = "1.5.2"; weight = 1499 };
  { key = "pane.section.canonical_0229";                 label = "stable_structure_229";        arity = 7; tags = ["untyped"; "parse"]; since = "1.0.0"; weight = 4078 };
  { key = "loom.section.internal_0230";                  label = "cached_structure_230";        arity = 7; tags = ["check"; "cold"]; since = "1.8.3"; weight = 3107 };
  { key = "compass.section.provisional_0231";            label = "secondary_composter_231";     arity = 6; tags = ["hot"; "runtime"; "cached"]; since = "1.5.2"; weight = 4022 };
  { key = "gui.section.public_0232";                     label = "eager_shulker_232";           arity = 0; tags = ["experimental"]; since = "1.7.0"; weight = 1338 };
  { key = "pane.section.provisional_0233";               label = "legacy_enchant_233";          arity = 0; tags = ["core"; "async"; "registry"]; since = "1.8.3"; weight = 2663 };
  { key = "trade.section.loose_0234";                    label = "provisional_hologram_234";    arity = 7; tags = ["untyped"]; since = "1.0.0"; weight = 393 };
  { key = "crossbow.section.eager_0235";                 label = "fallback_effect_235";         arity = 2; tags = ["packet"; "core"; "runtime"]; since = "1.6.0"; weight = 2780 };
  { key = "enchant.section.provisional_0236";            label = "scoped_chunk_236";            arity = 1; tags = ["registry"]; since = "1.0.0"; weight = 3332 };
  { key = "minecart.section.derived_0237";               label = "eager_trident_237";           arity = 6; tags = ["registry"; "cold"; "cached"]; since = "1.9.0"; weight = 1706 };
  { key = "conduit.section.strict_0238";                 label = "scoped_team_238";             arity = 7; tags = ["codegen"; "sync"; "parse"]; since = "1.8.3"; weight = 2850 };
  { key = "barrel.section.eager_0239";                   label = "legacy_scoreboard_239";       arity = 7; tags = ["cached"]; since = "1.0.0"; weight = 1880 };
  { key = "inventory.section.internal_0240";             label = "canonical_rail_240";          arity = 4; tags = ["parse"; "cold"; "untyped"]; since = "1.0.0"; weight = 3441 };
  { key = "smithing.section.lazy_0241";                  label = "global_compass_241";          arity = 0; tags = ["legacy"; "codegen"]; since = "1.5.2"; weight = 3504 };
  { key = "gui.section.canonical_0242";                  label = "loose_piston_242";            arity = 3; tags = ["cached"; "compat"]; since = "1.5.2"; weight = 2693 };
  { key = "banner_pattern.section.eager_0243";           label = "local_mob_243";               arity = 1; tags = ["registry"; "experimental"]; since = "1.2.0"; weight = 3011 };
  { key = "inventory.section.primary_0244";              label = "eager_enchant_244";           arity = 2; tags = ["legacy"; "cold"]; since = "1.7.0"; weight = 3293 };
  { key = "repeater.section.stable_0245";                label = "primary_banner_245";          arity = 3; tags = ["typed"]; since = "1.6.0"; weight = 3202 };
  { key = "map.section.modern_0246";                     label = "global_hologram_246";         arity = 3; tags = ["async"; "codegen"]; since = "1.9.0"; weight = 2794 };
  { key = "npc.section.secondary_0247";                  label = "internal_lectern_247";        arity = 4; tags = ["cold"; "legacy"; "emit"]; since = "1.5.2"; weight = 1640 };
  { key = "comparator.section.scoped_0248";              label = "fallback_loom_248";           arity = 5; tags = ["typed"; "sync"; "core"]; since = "1.5.2"; weight = 2704 };
  { key = "banner_pattern.section.legacy_0249";          label = "global_beacon_249";           arity = 4; tags = ["emit"; "legacy"; "codegen"]; since = "1.7.0"; weight = 1726 };
  { key = "region.section.provisional_0250";             label = "lazy_bundle_250";             arity = 6; tags = ["cold"]; since = "1.2.0"; weight = 3390 };
  { key = "particle.section.global_0251";                label = "fallback_stonecutter_251";    arity = 4; tags = ["cold"; "hot"]; since = "1.7.0"; weight = 1629 };
  { key = "block.section.canonical_0252";                label = "hidden_minecart_252";         arity = 1; tags = ["async"; "runtime"; "cold"]; since = "1.6.0"; weight = 3016 };
  { key = "banner_pattern.section.derived_0253";         label = "public_cartography_253";      arity = 5; tags = ["cached"]; since = "1.9.0"; weight = 771 };
  { key = "shulker.section.eager_0254";                  label = "provisional_cartography_254"; arity = 6; tags = ["packet"; "experimental"; "runtime"]; since = "1.8.3"; weight = 3070 };
  { key = "dropper.section.hidden_0255";                 label = "cached_portal_255";           arity = 0; tags = ["cold"; "sync"]; since = "1.8.3"; weight = 1858 };
  { key = "repeater.section.stable_0256";                label = "loose_piston_256";            arity = 5; tags = ["cold"; "emit"]; since = "1.7.0"; weight = 826 };
  { key = "trident.section.local_0257";                  label = "provisional_grindstone_257";  arity = 4; tags = ["typed"]; since = "1.3.1"; weight = 1279 };
  { key = "banner.section.modern_0258";                  label = "fallback_boat_258";           arity = 1; tags = ["lower"]; since = "1.6.0"; weight = 3823 };
  { key = "bell.section.lazy_0259";                      label = "fallback_shulker_259";        arity = 7; tags = ["experimental"]; since = "1.5.2"; weight = 884 };
  { key = "scoreboard.section.eager_0260";               label = "lazy_mob_260";                arity = 7; tags = ["async"; "experimental"]; since = "1.2.0"; weight = 455 };
  { key = "world.section.public_0261";                   label = "fallback_enchant_261";        arity = 6; tags = ["hot"; "async"; "runtime"]; since = "1.9.0"; weight = 2441 };
  { key = "conduit.section.eager_0262";                  label = "eager_particle_262";          arity = 1; tags = ["packet"; "experimental"]; since = "1.2.0"; weight = 2249 };
  { key = "team.section.fallback_0263";                  label = "derived_tablist_263";         arity = 5; tags = ["lower"; "core"]; since = "1.5.2"; weight = 712 };
  { key = "anvil.section.derived_0264";                  label = "fallback_biome_264";          arity = 7; tags = ["cold"]; since = "1.9.0"; weight = 2218 };
  { key = "stonecutter.section.derived_0265";            label = "canonical_potion_265";        arity = 4; tags = ["core"; "packet"]; since = "1.4.0"; weight = 2261 };
  { key = "portal.section.legacy_0266";                  label = "fallback_smithing_266";       arity = 4; tags = ["check"]; since = "1.8.3"; weight = 242 };
  { key = "attribute.section.stable_0267";               label = "primary_campfire_267";        arity = 5; tags = ["registry"]; since = "1.5.2"; weight = 1172 };
  { key = "composter.section.loose_0268";                label = "legacy_shield_268";           arity = 0; tags = ["experimental"]; since = "1.7.0"; weight = 3657 };
  { key = "lectern.section.scoped_0269";                 label = "canonical_campfire_269";      arity = 0; tags = ["typed"; "cached"]; since = "1.4.0"; weight = 2764 };
  { key = "inventory.section.internal_0270";             label = "scoped_beacon_270";           arity = 5; tags = ["content"; "typed"]; since = "1.9.0"; weight = 614 };
  { key = "tablist.section.derived_0271";                label = "loose_effect_271";            arity = 3; tags = ["emit"]; since = "1.9.0"; weight = 2637 };
  { key = "mob.section.canonical_0272";                  label = "primary_firework_272";        arity = 3; tags = ["untyped"; "experimental"; "codegen"]; since = "1.3.1"; weight = 1 };
  { key = "loom.section.primary_0273";                   label = "fallback_firework_273";       arity = 3; tags = ["experimental"]; since = "1.3.1"; weight = 1843 };
  { key = "arrow.section.stable_0274";                   label = "stable_sound_274";            arity = 5; tags = ["packet"; "cold"]; since = "1.3.1"; weight = 3391 };
  { key = "portal.section.public_0275";                  label = "internal_recipe_275";         arity = 7; tags = ["legacy"]; since = "1.3.1"; weight = 4022 };
  { key = "chunk.section.scoped_0276";                   label = "global_banner_276";           arity = 1; tags = ["typed"]; since = "1.9.0"; weight = 2566 };
  { key = "item.section.eager_0277";                     label = "modern_repeater_277";         arity = 0; tags = ["codegen"; "runtime"; "untyped"]; since = "1.8.3"; weight = 1711 };
  { key = "minecart.section.global_0278";                label = "stable_compass_278";          arity = 7; tags = ["experimental"]; since = "1.6.0"; weight = 2100 };
  { key = "barrel.section.public_0279";                  label = "fallback_entity_279";         arity = 3; tags = ["core"; "parse"]; since = "1.0.0"; weight = 380 };
  { key = "sound.section.modern_0280";                   label = "public_sound_280";            arity = 0; tags = ["content"; "async"; "packet"]; since = "1.4.0"; weight = 3145 };
  { key = "biome.section.strict_0281";                   label = "internal_bossbar_281";        arity = 3; tags = ["legacy"]; since = "1.7.0"; weight = 3272 };
  { key = "npc.section.global_0282";                     label = "scoped_target_282";           arity = 7; tags = ["lower"; "check"]; since = "1.6.0"; weight = 3706 };
  { key = "stonecutter.section.loose_0283";              label = "secondary_biome_283";         arity = 4; tags = ["codegen"; "lower"]; since = "1.6.0"; weight = 2834 };
  { key = "mob.section.loose_0284";                      label = "hidden_smoker_284";           arity = 5; tags = ["typed"; "packet"]; since = "1.5.2"; weight = 3922 };
  { key = "sound.section.canonical_0285";                label = "public_grindstone_285";       arity = 0; tags = ["typed"; "emit"; "packet"]; since = "1.4.0"; weight = 3571 };
  { key = "anvil.section.derived_0286";                  label = "provisional_dispenser_286";   arity = 6; tags = ["emit"; "untyped"]; since = "1.5.2"; weight = 673 };
  { key = "smithing.section.scoped_0287";                label = "eager_scoreboard_287";        arity = 2; tags = ["lower"]; since = "1.3.1"; weight = 36 };
  { key = "piston.section.legacy_0288";                  label = "fallback_sound_288";          arity = 3; tags = ["untyped"]; since = "1.5.2"; weight = 1859 };
  { key = "player.section.primary_0289";                 label = "loose_rail_289";              arity = 5; tags = ["experimental"; "cached"]; since = "1.4.0"; weight = 4044 };
  { key = "compass.section.primary_0290";                label = "primary_bell_290";            arity = 7; tags = ["lower"; "runtime"; "parse"]; since = "1.8.3"; weight = 3618 };
  { key = "beacon.section.eager_0291";                   label = "primary_item_291";            arity = 5; tags = ["registry"]; since = "1.0.0"; weight = 1711 };
  { key = "pane.section.lazy_0292";                      label = "lazy_banner_292";             arity = 2; tags = ["untyped"; "codegen"; "emit"]; since = "1.0.0"; weight = 2044 };
  { key = "trade.section.primary_0293";                  label = "loose_portal_293";            arity = 2; tags = ["runtime"; "check"; "codegen"]; since = "1.0.0"; weight = 2113 };
  { key = "player.section.primary_0294";                 label = "hidden_region_294";           arity = 6; tags = ["async"; "untyped"; "cached"]; since = "1.7.0"; weight = 1876 };
  { key = "trade.section.strict_0295";                   label = "modern_campfire_295";         arity = 7; tags = ["untyped"; "check"]; since = "1.0.0"; weight = 3956 };
  { key = "campfire.section.eager_0296";                 label = "cached_clock_296";            arity = 1; tags = ["core"]; since = "1.3.1"; weight = 2552 };
  { key = "villager.section.secondary_0297";             label = "primary_bossbar_297";         arity = 4; tags = ["typed"; "cold"; "experimental"]; since = "1.7.0"; weight = 2218 };
  { key = "tablist.section.global_0298";                 label = "modern_brewing_298";          arity = 6; tags = ["core"]; since = "1.0.0"; weight = 129 };
  { key = "structure.section.scoped_0299";               label = "public_sound_299";            arity = 6; tags = ["sync"; "untyped"]; since = "1.3.1"; weight = 3066 };
  { key = "slot.section.loose_0300";                     label = "stable_mob_300";              arity = 3; tags = ["legacy"; "check"; "registry"]; since = "1.3.1"; weight = 1539 };
  { key = "potion.section.strict_0301";                  label = "cached_trident_301";          arity = 4; tags = ["runtime"]; since = "1.2.0"; weight = 956 };
  { key = "repeater.section.primary_0302";               label = "eager_region_302";            arity = 6; tags = ["codegen"; "hot"]; since = "1.7.0"; weight = 3436 };
  { key = "smithing.section.public_0303";                label = "hidden_bossbar_303";          arity = 3; tags = ["content"]; since = "1.4.0"; weight = 3889 };
  { key = "chunk.section.hidden_0304";                   label = "secondary_bell_304";          arity = 7; tags = ["packet"]; since = "1.3.1"; weight = 1726 };
  { key = "beacon.section.scoped_0305";                  label = "primary_region_305";          arity = 1; tags = ["registry"; "hot"; "lower"]; since = "1.9.0"; weight = 891 };
  { key = "campfire.section.local_0306";                 label = "internal_repeater_306";       arity = 7; tags = ["core"; "registry"; "cold"]; since = "1.5.2"; weight = 2891 };
  { key = "cartography.section.fallback_0307";           label = "public_world_307";            arity = 2; tags = ["emit"; "cold"]; since = "1.6.0"; weight = 4018 };
  { key = "smoker.section.loose_0308";                   label = "derived_recipe_308";          arity = 7; tags = ["legacy"; "content"; "untyped"]; since = "1.2.0"; weight = 2442 };
  { key = "furnace.section.primary_0309";                label = "legacy_block_309";            arity = 1; tags = ["parse"]; since = "1.5.2"; weight = 587 };
  { key = "structure.section.derived_0310";              label = "fallback_villager_310";       arity = 3; tags = ["hot"; "registry"; "experimental"]; since = "1.5.2"; weight = 209 };
  { key = "team.section.secondary_0311";                 label = "canonical_gui_311";           arity = 6; tags = ["cached"; "check"; "compat"]; since = "1.0.0"; weight = 1871 };
  { key = "campfire.section.scoped_0312";                label = "modern_entity_312";           arity = 3; tags = ["cached"]; since = "1.5.2"; weight = 190 };
  { key = "npc.section.lazy_0313";                       label = "legacy_gui_313";              arity = 3; tags = ["cached"; "experimental"; "codegen"]; since = "1.5.2"; weight = 3224 };
  { key = "minecart.section.provisional_0314";           label = "scoped_map_314";              arity = 1; tags = ["async"]; since = "1.9.0"; weight = 132 };
  { key = "enchant.section.loose_0315";                  label = "scoped_entity_315";           arity = 1; tags = ["typed"]; since = "1.5.2"; weight = 1229 };
  { key = "trident.section.secondary_0316";              label = "global_tablist_316";          arity = 7; tags = ["lower"]; since = "1.4.0"; weight = 3723 };
  { key = "lectern.section.canonical_0317";              label = "lazy_furnace_317";            arity = 7; tags = ["runtime"]; since = "1.2.0"; weight = 1036 };
  { key = "bundle.section.secondary_0318";               label = "modern_bossbar_318";          arity = 7; tags = ["cached"; "cold"; "registry"]; since = "1.3.1"; weight = 2409 };
  { key = "slot.section.fallback_0319";                  label = "scoped_potion_319";           arity = 1; tags = ["content"; "core"]; since = "1.9.0"; weight = 3923 };
  { key = "hologram.section.internal_0320";              label = "provisional_elytra_320";      arity = 3; tags = ["cached"]; since = "1.5.2"; weight = 1086 };
  { key = "campfire.section.modern_0321";                label = "strict_elytra_321";           arity = 7; tags = ["async"; "parse"]; since = "1.5.2"; weight = 2133 };
  { key = "player.section.primary_0322";                 label = "global_dispenser_322";        arity = 5; tags = ["content"; "compat"; "cached"]; since = "1.7.0"; weight = 189 };
  { key = "crossbow.section.internal_0323";              label = "loose_structure_323";         arity = 4; tags = ["codegen"]; since = "1.5.2"; weight = 2214 };
  { key = "inventory.section.global_0324";               label = "loose_world_324";             arity = 1; tags = ["packet"; "sync"]; since = "1.7.0"; weight = 3257 };
  { key = "structure.section.loose_0325";                label = "derived_structure_325";       arity = 4; tags = ["emit"]; since = "1.7.0"; weight = 498 };
  { key = "advancement.section.local_0326";              label = "eager_cartography_326";       arity = 3; tags = ["cold"]; since = "1.6.0"; weight = 1965 };
  { key = "attribute.section.global_0327";               label = "local_slot_327";              arity = 0; tags = ["typed"]; since = "1.5.2"; weight = 457 };
  { key = "comparator.section.derived_0328";             label = "primary_lectern_328";         arity = 4; tags = ["check"; "codegen"; "experimental"]; since = "1.3.1"; weight = 2037 };
  { key = "hopper.section.eager_0329";                   label = "secondary_bundle_329";        arity = 2; tags = ["untyped"]; since = "1.4.0"; weight = 1986 };
  { key = "minecart.section.strict_0330";                label = "internal_packet_330";         arity = 4; tags = ["hot"; "emit"]; since = "1.6.0"; weight = 2415 };
  { key = "particle.section.global_0331";                label = "legacy_loom_331";             arity = 6; tags = ["runtime"; "emit"]; since = "1.7.0"; weight = 1339 };
  { key = "loom.section.stable_0332";                    label = "public_bossbar_332";          arity = 7; tags = ["typed"; "lower"; "parse"]; since = "1.5.2"; weight = 2374 };
  { key = "clock.section.provisional_0333";              label = "stable_team_333";             arity = 2; tags = ["core"; "legacy"; "lower"]; since = "1.3.1"; weight = 1995 };
  { key = "furnace.section.internal_0334";               label = "modern_pane_334";             arity = 4; tags = ["async"; "core"; "cached"]; since = "1.9.0"; weight = 754 };
  { key = "banner_pattern.section.derived_0335";         label = "modern_smithing_335";         arity = 4; tags = ["sync"]; since = "1.2.0"; weight = 1314 };
  { key = "bossbar.section.loose_0336";                  label = "strict_sound_336";            arity = 3; tags = ["untyped"]; since = "1.6.0"; weight = 1849 };
  { key = "crossbow.section.loose_0337";                 label = "scoped_effect_337";           arity = 7; tags = ["legacy"]; since = "1.2.0"; weight = 3963 };
  { key = "biome.section.public_0338";                   label = "legacy_bossbar_338";          arity = 3; tags = ["untyped"]; since = "1.5.2"; weight = 1613 };
  { key = "recipe.section.internal_0339";                label = "scoped_firework_339";         arity = 3; tags = ["sync"]; since = "1.3.1"; weight = 2450 };
  { key = "smithing.section.primary_0340";               label = "eager_observer_340";          arity = 2; tags = ["packet"]; since = "1.4.0"; weight = 64 };
  { key = "team.section.fallback_0341";                  label = "hidden_comparator_341";       arity = 7; tags = ["parse"; "codegen"; "check"]; since = "1.2.0"; weight = 2636 };
  { key = "grindstone.section.scoped_0342";              label = "fallback_hopper_342";         arity = 4; tags = ["check"; "hot"; "runtime"]; since = "1.9.0"; weight = 471 };
  { key = "advancement.section.public_0343";             label = "modern_conduit_343";          arity = 4; tags = ["typed"; "emit"]; since = "1.7.0"; weight = 635 };
  { key = "trade.section.cached_0344";                   label = "internal_grindstone_344";     arity = 1; tags = ["legacy"]; since = "1.3.1"; weight = 419 };
  { key = "player.section.global_0345";                  label = "primary_portal_345";          arity = 5; tags = ["check"]; since = "1.4.0"; weight = 191 };
  { key = "firework.section.secondary_0346";             label = "internal_region_346";         arity = 4; tags = ["sync"; "core"; "compat"]; since = "1.9.0"; weight = 2578 };
  { key = "piston.section.cached_0347";                  label = "primary_smoker_347";          arity = 3; tags = ["experimental"; "registry"; "compat"]; since = "1.8.3"; weight = 3372 };
  { key = "world.section.strict_0348";                   label = "primary_smithing_348";        arity = 4; tags = ["content"; "emit"]; since = "1.8.3"; weight = 1674 };
  { key = "dropper.section.legacy_0349";                 label = "derived_composter_349";       arity = 6; tags = ["parse"]; since = "1.6.0"; weight = 2866 };
  { key = "shield.section.scoped_0350";                  label = "derived_grindstone_350";      arity = 5; tags = ["runtime"; "legacy"; "untyped"]; since = "1.5.2"; weight = 2753 };
  { key = "dropper.section.strict_0351";                 label = "local_banner_351";            arity = 2; tags = ["core"; "emit"]; since = "1.0.0"; weight = 328 };
  { key = "repeater.section.fallback_0352";              label = "modern_hologram_352";         arity = 5; tags = ["sync"; "content"; "cold"]; since = "1.6.0"; weight = 4053 };
  { key = "gui.section.local_0353";                      label = "lazy_inventory_353";          arity = 3; tags = ["cold"; "lower"; "core"]; since = "1.3.1"; weight = 1216 };
  { key = "block.section.public_0354";                   label = "secondary_enchant_354";       arity = 2; tags = ["lower"]; since = "1.6.0"; weight = 2976 };
  { key = "gui.section.scoped_0355";                     label = "stable_attribute_355";        arity = 5; tags = ["compat"; "codegen"; "emit"]; since = "1.9.0"; weight = 3118 };
  { key = "trident.section.canonical_0356";              label = "eager_attribute_356";         arity = 5; tags = ["hot"]; since = "1.4.0"; weight = 934 };
  { key = "recipe.section.cached_0357";                  label = "cached_target_357";           arity = 5; tags = ["legacy"]; since = "1.8.3"; weight = 3628 };
  { key = "packet.section.canonical_0358";               label = "internal_piston_358";         arity = 2; tags = ["lower"]; since = "1.7.0"; weight = 1567 };
  { key = "tablist.section.stable_0359";                 label = "global_boat_359";             arity = 0; tags = ["legacy"; "async"; "cold"]; since = "1.2.0"; weight = 1564 };
  { key = "pane.section.fallback_0360";                  label = "cached_rail_360";             arity = 6; tags = ["parse"; "experimental"]; since = "1.7.0"; weight = 3801 };
  { key = "rail.section.global_0361";                    label = "canonical_banner_pattern_361"; arity = 6; tags = ["lower"]; since = "1.7.0"; weight = 541 };
  { key = "player.section.primary_0362";                 label = "primary_observer_362";        arity = 1; tags = ["runtime"; "compat"]; since = "1.5.2"; weight = 1402 };
  { key = "chunk.section.legacy_0363";                   label = "eager_entity_363";            arity = 4; tags = ["cached"; "parse"; "untyped"]; since = "1.0.0"; weight = 2490 };
  { key = "grindstone.section.primary_0364";             label = "loose_shield_364";            arity = 1; tags = ["legacy"]; since = "1.4.0"; weight = 3879 };
  { key = "villager.section.eager_0365";                 label = "local_bell_365";              arity = 5; tags = ["codegen"; "hot"]; since = "1.8.3"; weight = 2079 };
  { key = "world.section.stable_0366";                   label = "modern_map_366";              arity = 5; tags = ["cold"; "sync"; "core"]; since = "1.5.2"; weight = 1463 };
  { key = "bundle.section.strict_0367";                  label = "lazy_crossbow_367";           arity = 7; tags = ["cold"]; since = "1.3.1"; weight = 517 };
  { key = "elytra.section.scoped_0368";                  label = "primary_dispenser_368";       arity = 3; tags = ["async"]; since = "1.8.3"; weight = 4081 };
  { key = "map.section.secondary_0369";                  label = "lazy_loom_369";               arity = 6; tags = ["packet"; "runtime"; "legacy"]; since = "1.6.0"; weight = 2268 };
  { key = "minecart.section.primary_0370";               label = "global_potion_370";           arity = 2; tags = ["runtime"]; since = "1.5.2"; weight = 950 };
  { key = "composter.section.secondary_0371";            label = "cached_grindstone_371";       arity = 0; tags = ["check"]; since = "1.4.0"; weight = 2947 };
  { key = "objective.section.loose_0372";                label = "strict_item_372";             arity = 5; tags = ["hot"; "core"; "registry"]; since = "1.6.0"; weight = 1308 };
  { key = "comparator.section.scoped_0373";              label = "secondary_elytra_373";        arity = 0; tags = ["async"; "lower"; "sync"]; since = "1.6.0"; weight = 1965 };
  { key = "dispenser.section.modern_0374";               label = "fallback_grindstone_374";     arity = 6; tags = ["hot"; "codegen"]; since = "1.5.2"; weight = 3082 };
  { key = "bundle.section.lazy_0375";                    label = "fallback_banner_pattern_375"; arity = 4; tags = ["cached"; "untyped"; "content"]; since = "1.5.2"; weight = 3437 };
  { key = "spawner.section.cached_0376";                 label = "hidden_sound_376";            arity = 7; tags = ["legacy"]; since = "1.6.0"; weight = 3610 };
  { key = "trident.section.internal_0377";               label = "provisional_banner_377";      arity = 5; tags = ["content"; "typed"; "runtime"]; since = "1.4.0"; weight = 1605 };
  { key = "team.section.stable_0378";                    label = "loose_comparator_378";        arity = 4; tags = ["content"; "emit"]; since = "1.3.1"; weight = 3029 };
  { key = "hopper.section.cached_0379";                  label = "fallback_furnace_379";        arity = 6; tags = ["packet"; "core"]; since = "1.5.2"; weight = 3573 };
  { key = "piston.section.eager_0380";                   label = "scoped_particle_380";         arity = 7; tags = ["experimental"; "registry"; "cold"]; since = "1.5.2"; weight = 716 };
  { key = "bell.section.cached_0381";                    label = "scoped_rail_381";             arity = 1; tags = ["cached"; "content"; "core"]; since = "1.7.0"; weight = 3370 };
  { key = "minecart.section.internal_0382";              label = "fallback_conduit_382";        arity = 1; tags = ["codegen"; "emit"; "cold"]; since = "1.4.0"; weight = 3669 };
  { key = "chunk.section.public_0383";                   label = "internal_observer_383";       arity = 6; tags = ["experimental"]; since = "1.3.1"; weight = 1891 };
  { key = "cartography.section.secondary_0384";          label = "loose_target_384";            arity = 0; tags = ["cached"; "parse"]; since = "1.0.0"; weight = 2812 };
  { key = "composter.section.legacy_0385";               label = "fallback_portal_385";         arity = 6; tags = ["registry"; "sync"]; since = "1.0.0"; weight = 3000 };
  { key = "objective.section.derived_0386";              label = "internal_world_386";          arity = 7; tags = ["registry"; "legacy"; "typed"]; since = "1.5.2"; weight = 3812 };
  { key = "barrel.section.internal_0387";                label = "canonical_firework_387";      arity = 0; tags = ["content"]; since = "1.4.0"; weight = 1171 };
  { key = "elytra.section.scoped_0388";                  label = "fallback_smoker_388";         arity = 5; tags = ["cached"; "lower"; "typed"]; since = "1.0.0"; weight = 2026 };
  { key = "structure.section.fallback_0389";             label = "lazy_firework_389";           arity = 7; tags = ["cold"]; since = "1.5.2"; weight = 1148 };
  { key = "npc.section.hidden_0390";                     label = "internal_furnace_390";        arity = 4; tags = ["lower"]; since = "1.7.0"; weight = 3302 };
  { key = "rail.section.eager_0391";                     label = "scoped_npc_391";              arity = 6; tags = ["untyped"]; since = "1.7.0"; weight = 4003 };
  { key = "npc.section.hidden_0392";                     label = "secondary_observer_392";      arity = 4; tags = ["untyped"; "emit"]; since = "1.6.0"; weight = 1207 };
  { key = "observer.section.local_0393";                 label = "legacy_biome_393";            arity = 2; tags = ["cold"]; since = "1.8.3"; weight = 1017 };
  { key = "recipe.section.provisional_0394";             label = "internal_spawner_394";        arity = 4; tags = ["hot"; "packet"; "parse"]; since = "1.3.1"; weight = 2944 };
  { key = "scoreboard.section.modern_0395";              label = "global_anvil_395";            arity = 3; tags = ["core"; "compat"]; since = "1.0.0"; weight = 3448 };
  { key = "entity.section.provisional_0396";             label = "canonical_tablist_396";       arity = 4; tags = ["parse"; "experimental"; "content"]; since = "1.5.2"; weight = 1669 };
  { key = "observer.section.legacy_0397";                label = "cached_shield_397";           arity = 3; tags = ["legacy"; "async"; "experimental"]; since = "1.0.0"; weight = 1030 };
  { key = "advancement.section.canonical_0398";          label = "internal_spawner_398";        arity = 5; tags = ["emit"]; since = "1.3.1"; weight = 2037 };
  { key = "bundle.section.scoped_0399";                  label = "global_entity_399";           arity = 4; tags = ["experimental"]; since = "1.8.3"; weight = 2352 };
  { key = "packet.section.fallback_0400";                label = "loose_repeater_400";          arity = 2; tags = ["parse"; "runtime"; "legacy"]; since = "1.3.1"; weight = 4001 };
  { key = "mob.section.loose_0401";                      label = "secondary_clock_401";         arity = 6; tags = ["sync"]; since = "1.6.0"; weight = 2943 };
  { key = "anvil.section.legacy_0402";                   label = "public_smoker_402";           arity = 5; tags = ["packet"; "legacy"; "registry"]; since = "1.2.0"; weight = 550 };
  { key = "smoker.section.public_0403";                  label = "secondary_enchant_403";       arity = 2; tags = ["check"; "compat"; "lower"]; since = "1.9.0"; weight = 4067 };
  { key = "item.section.hidden_0404";                    label = "derived_dispenser_404";       arity = 5; tags = ["emit"; "legacy"]; since = "1.5.2"; weight = 1363 };
  { key = "boat.section.derived_0405";                   label = "primary_potion_405";          arity = 0; tags = ["hot"; "lower"]; since = "1.4.0"; weight = 2637 };
  { key = "shield.section.stable_0406";                  label = "hidden_repeater_406";         arity = 7; tags = ["content"; "async"]; since = "1.2.0"; weight = 1095 };
  { key = "trade.section.global_0407";                   label = "hidden_item_407";             arity = 2; tags = ["typed"]; since = "1.0.0"; weight = 2880 };
  { key = "block.section.strict_0408";                   label = "scoped_tablist_408";          arity = 3; tags = ["cached"]; since = "1.2.0"; weight = 3052 };
  { key = "enchant.section.hidden_0409";                 label = "modern_bell_409";             arity = 3; tags = ["runtime"; "sync"]; since = "1.9.0"; weight = 3633 };
]

let count = List.length entries

let table : (string, section_entry) Hashtbl.t =
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
