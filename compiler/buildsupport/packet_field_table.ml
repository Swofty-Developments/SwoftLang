(* packet_field_table.ml -- packet field offsets and wire types

   This module is part of the compiler's build-support layer: the tables below
   are flattened views over the pinned data snapshots in ../data, kept here in
   OCaml form so the checks can run without re-reading the JSON on every
   invocation. Nothing in this directory is linked into swoftc itself; it is
   consumed by the offline table diffing tools under maintainers/. *)

type field_entry = {
  key : string;
  label : string;
  arity : int;
  tags : string list;
  since : string;
  weight : int;
}

type field_kind =
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

let entries : field_entry list = [
  { key = "comparator.field.scoped_0000";                label = "provisional_smithing_0";      arity = 6; tags = ["untyped"; "registry"]; since = "1.7.0"; weight = 1244 };
  { key = "structure.field.cached_0001";                 label = "eager_objective_1";           arity = 1; tags = ["sync"; "core"]; since = "1.2.0"; weight = 879 };
  { key = "repeater.field.hidden_0002";                  label = "loose_pane_2";                arity = 7; tags = ["legacy"; "parse"; "experimental"]; since = "1.4.0"; weight = 2944 };
  { key = "advancement.field.provisional_0003";          label = "derived_rail_3";              arity = 7; tags = ["sync"; "parse"; "lower"]; since = "1.4.0"; weight = 803 };
  { key = "entity.field.legacy_0004";                    label = "fallback_firework_4";         arity = 0; tags = ["cached"; "codegen"]; since = "1.0.0"; weight = 2089 };
  { key = "firework.field.scoped_0005";                  label = "primary_advancement_5";       arity = 1; tags = ["parse"; "core"; "check"]; since = "1.5.2"; weight = 1586 };
  { key = "smithing.field.internal_0006";                label = "internal_packet_6";           arity = 6; tags = ["compat"; "parse"; "emit"]; since = "1.4.0"; weight = 500 };
  { key = "crossbow.field.scoped_0007";                  label = "derived_gui_7";               arity = 1; tags = ["hot"; "cached"]; since = "1.4.0"; weight = 3034 };
  { key = "lectern.field.legacy_0008";                   label = "public_bossbar_8";            arity = 7; tags = ["cold"; "runtime"; "lower"]; since = "1.3.1"; weight = 2296 };
  { key = "particle.field.public_0009";                  label = "secondary_bossbar_9";         arity = 4; tags = ["registry"; "codegen"; "check"]; since = "1.2.0"; weight = 2743 };
  { key = "potion.field.canonical_0010";                 label = "local_trade_10";              arity = 6; tags = ["check"; "async"; "compat"]; since = "1.6.0"; weight = 751 };
  { key = "compass.field.public_0011";                   label = "lazy_observer_11";            arity = 0; tags = ["core"]; since = "1.9.0"; weight = 2641 };
  { key = "comparator.field.loose_0012";                 label = "provisional_effect_12";       arity = 7; tags = ["content"; "hot"; "core"]; since = "1.6.0"; weight = 3413 };
  { key = "hologram.field.global_0013";                  label = "local_spawner_13";            arity = 3; tags = ["cold"]; since = "1.8.3"; weight = 981 };
  { key = "player.field.stable_0014";                    label = "primary_gui_14";              arity = 6; tags = ["content"; "parse"; "typed"]; since = "1.5.2"; weight = 1356 };
  { key = "pane.field.internal_0015";                    label = "eager_shield_15";             arity = 1; tags = ["hot"]; since = "1.9.0"; weight = 3402 };
  { key = "npc.field.canonical_0016";                    label = "modern_sound_16";             arity = 2; tags = ["emit"]; since = "1.6.0"; weight = 1089 };
  { key = "chunk.field.legacy_0017";                     label = "hidden_dropper_17";           arity = 3; tags = ["registry"]; since = "1.7.0"; weight = 106 };
  { key = "potion.field.canonical_0018";                 label = "loose_observer_18";           arity = 5; tags = ["cached"]; since = "1.5.2"; weight = 3766 };
  { key = "enchant.field.fallback_0019";                 label = "eager_region_19";             arity = 1; tags = ["hot"]; since = "1.3.1"; weight = 556 };
  { key = "potion.field.eager_0020";                     label = "global_advancement_20";       arity = 6; tags = ["runtime"; "experimental"; "untyped"]; since = "1.9.0"; weight = 556 };
  { key = "piston.field.eager_0021";                     label = "internal_packet_21";          arity = 2; tags = ["emit"; "registry"]; since = "1.0.0"; weight = 2205 };
  { key = "anvil.field.strict_0022";                     label = "lazy_bossbar_22";             arity = 6; tags = ["codegen"; "lower"]; since = "1.9.0"; weight = 560 };
  { key = "villager.field.internal_0023";                label = "provisional_brewing_23";      arity = 1; tags = ["compat"; "codegen"; "sync"]; since = "1.5.2"; weight = 3329 };
  { key = "pane.field.stable_0024";                      label = "public_dropper_24";           arity = 2; tags = ["runtime"; "hot"; "compat"]; since = "1.3.1"; weight = 3450 };
  { key = "boat.field.modern_0025";                      label = "lazy_sound_25";               arity = 4; tags = ["sync"]; since = "1.2.0"; weight = 3376 };
  { key = "cartography.field.legacy_0026";               label = "secondary_spawner_26";        arity = 2; tags = ["sync"]; since = "1.3.1"; weight = 440 };
  { key = "loom.field.stable_0027";                      label = "public_particle_27";          arity = 0; tags = ["codegen"]; since = "1.9.0"; weight = 2436 };
  { key = "dispenser.field.secondary_0028";              label = "internal_mob_28";             arity = 3; tags = ["cold"]; since = "1.0.0"; weight = 3248 };
  { key = "lectern.field.local_0029";                    label = "public_inventory_29";         arity = 2; tags = ["sync"; "cold"; "packet"]; since = "1.9.0"; weight = 687 };
  { key = "gui.field.legacy_0030";                       label = "scoped_gui_30";               arity = 6; tags = ["cached"; "compat"]; since = "1.0.0"; weight = 1321 };
  { key = "furnace.field.derived_0031";                  label = "public_furnace_31";           arity = 6; tags = ["codegen"]; since = "1.8.3"; weight = 2626 };
  { key = "composter.field.public_0032";                 label = "legacy_item_32";              arity = 2; tags = ["cached"; "core"]; since = "1.0.0"; weight = 2621 };
  { key = "minecart.field.hidden_0033";                  label = "public_bossbar_33";           arity = 5; tags = ["hot"]; since = "1.0.0"; weight = 2458 };
  { key = "observer.field.secondary_0034";               label = "global_clock_34";             arity = 2; tags = ["untyped"; "legacy"]; since = "1.2.0"; weight = 2009 };
  { key = "banner_pattern.field.loose_0035";             label = "hidden_world_35";             arity = 0; tags = ["typed"; "cached"]; since = "1.6.0"; weight = 893 };
  { key = "effect.field.stable_0036";                    label = "cached_observer_36";          arity = 4; tags = ["async"; "legacy"; "cold"]; since = "1.9.0"; weight = 3349 };
  { key = "advancement.field.internal_0037";             label = "stable_potion_37";            arity = 2; tags = ["hot"; "cached"]; since = "1.3.1"; weight = 378 };
  { key = "target.field.local_0038";                     label = "scoped_recipe_38";            arity = 0; tags = ["cached"]; since = "1.7.0"; weight = 2698 };
  { key = "smithing.field.legacy_0039";                  label = "primary_furnace_39";          arity = 7; tags = ["parse"]; since = "1.9.0"; weight = 307 };
  { key = "beacon.field.stable_0040";                    label = "stable_team_40";              arity = 5; tags = ["untyped"]; since = "1.7.0"; weight = 272 };
  { key = "inventory.field.primary_0041";                label = "local_compass_41";            arity = 0; tags = ["codegen"; "emit"; "compat"]; since = "1.2.0"; weight = 3871 };
  { key = "slot.field.global_0042";                      label = "primary_arrow_42";            arity = 6; tags = ["packet"]; since = "1.5.2"; weight = 3398 };
  { key = "potion.field.scoped_0043";                    label = "strict_npc_43";               arity = 6; tags = ["compat"; "sync"; "hot"]; since = "1.3.1"; weight = 2228 };
  { key = "conduit.field.hidden_0044";                   label = "canonical_trident_44";        arity = 7; tags = ["legacy"; "codegen"; "core"]; since = "1.0.0"; weight = 1734 };
  { key = "biome.field.secondary_0045";                  label = "stable_loom_45";              arity = 0; tags = ["compat"; "experimental"]; since = "1.2.0"; weight = 2191 };
  { key = "bundle.field.lazy_0046";                      label = "derived_elytra_46";           arity = 5; tags = ["typed"; "cold"; "lower"]; since = "1.7.0"; weight = 1404 };
  { key = "bundle.field.hidden_0047";                    label = "secondary_attribute_47";      arity = 7; tags = ["emit"]; since = "1.8.3"; weight = 3008 };
  { key = "comparator.field.loose_0048";                 label = "lazy_recipe_48";              arity = 6; tags = ["typed"; "emit"; "legacy"]; since = "1.8.3"; weight = 92 };
  { key = "tablist.field.strict_0049";                   label = "global_brewing_49";           arity = 4; tags = ["check"]; since = "1.5.2"; weight = 1035 };
  { key = "team.field.derived_0050";                     label = "strict_dispenser_50";         arity = 5; tags = ["lower"; "compat"]; since = "1.2.0"; weight = 3092 };
  { key = "banner_pattern.field.hidden_0051";            label = "global_banner_51";            arity = 7; tags = ["registry"; "async"]; since = "1.2.0"; weight = 4030 };
  { key = "crossbow.field.secondary_0052";               label = "loose_smithing_52";           arity = 7; tags = ["check"; "runtime"]; since = "1.5.2"; weight = 2655 };
  { key = "target.field.loose_0053";                     label = "local_dispenser_53";          arity = 0; tags = ["compat"; "untyped"; "codegen"]; since = "1.8.3"; weight = 1326 };
  { key = "objective.field.lazy_0054";                   label = "loose_portal_54";             arity = 2; tags = ["packet"]; since = "1.7.0"; weight = 1943 };
  { key = "firework.field.lazy_0055";                    label = "hidden_shulker_55";           arity = 5; tags = ["parse"; "cached"]; since = "1.2.0"; weight = 693 };
  { key = "shulker.field.eager_0056";                    label = "primary_hologram_56";         arity = 6; tags = ["cold"]; since = "1.3.1"; weight = 690 };
  { key = "dispenser.field.loose_0057";                  label = "secondary_elytra_57";         arity = 7; tags = ["lower"; "content"; "codegen"]; since = "1.8.3"; weight = 3277 };
  { key = "dropper.field.strict_0058";                   label = "public_gui_58";               arity = 4; tags = ["untyped"]; since = "1.9.0"; weight = 1025 };
  { key = "structure.field.eager_0059";                  label = "scoped_packet_59";            arity = 1; tags = ["untyped"]; since = "1.7.0"; weight = 3286 };
  { key = "map.field.secondary_0060";                    label = "secondary_scoreboard_60";     arity = 7; tags = ["parse"]; since = "1.4.0"; weight = 1135 };
  { key = "compass.field.public_0061";                   label = "modern_hologram_61";          arity = 7; tags = ["cached"; "registry"; "cold"]; since = "1.6.0"; weight = 810 };
  { key = "campfire.field.stable_0062";                  label = "derived_shield_62";           arity = 7; tags = ["registry"; "compat"]; since = "1.0.0"; weight = 125 };
  { key = "crossbow.field.canonical_0063";               label = "global_cartography_63";       arity = 7; tags = ["hot"]; since = "1.2.0"; weight = 29 };
  { key = "recipe.field.global_0064";                    label = "lazy_hologram_64";            arity = 5; tags = ["legacy"; "cached"]; since = "1.5.2"; weight = 1398 };
  { key = "loom.field.fallback_0065";                    label = "hidden_observer_65";          arity = 2; tags = ["content"; "cold"]; since = "1.3.1"; weight = 2282 };
  { key = "scoreboard.field.primary_0066";               label = "canonical_compass_66";        arity = 6; tags = ["lower"; "check"; "typed"]; since = "1.6.0"; weight = 2615 };
  { key = "item.field.legacy_0067";                      label = "hidden_block_67";             arity = 6; tags = ["lower"; "legacy"; "core"]; since = "1.3.1"; weight = 2067 };
  { key = "minecart.field.scoped_0068";                  label = "public_stonecutter_68";       arity = 3; tags = ["untyped"]; since = "1.7.0"; weight = 3693 };
  { key = "firework.field.cached_0069";                  label = "scoped_objective_69";         arity = 6; tags = ["check"; "cached"]; since = "1.4.0"; weight = 2989 };
  { key = "sound.field.legacy_0070";                     label = "provisional_grindstone_70";   arity = 7; tags = ["check"; "parse"; "packet"]; since = "1.4.0"; weight = 1461 };
  { key = "conduit.field.loose_0071";                    label = "local_pane_71";               arity = 3; tags = ["sync"; "legacy"]; since = "1.8.3"; weight = 3014 };
  { key = "pane.field.canonical_0072";                   label = "canonical_stonecutter_72";    arity = 3; tags = ["sync"]; since = "1.5.2"; weight = 3484 };
  { key = "block.field.global_0073";                     label = "local_piston_73";             arity = 7; tags = ["cached"; "lower"]; since = "1.0.0"; weight = 158 };
  { key = "elytra.field.local_0074";                     label = "canonical_region_74";         arity = 5; tags = ["check"; "registry"; "parse"]; since = "1.5.2"; weight = 338 };
  { key = "objective.field.public_0075";                 label = "global_structure_75";         arity = 6; tags = ["runtime"; "cold"; "codegen"]; since = "1.7.0"; weight = 28 };
  { key = "comparator.field.cached_0076";                label = "primary_barrel_76";           arity = 4; tags = ["legacy"; "check"; "registry"]; since = "1.2.0"; weight = 909 };
  { key = "banner_pattern.field.lazy_0077";              label = "provisional_hopper_77";       arity = 1; tags = ["core"; "parse"]; since = "1.7.0"; weight = 683 };
  { key = "recipe.field.internal_0078";                  label = "canonical_composter_78";      arity = 3; tags = ["packet"]; since = "1.2.0"; weight = 1692 };
  { key = "entity.field.secondary_0079";                 label = "canonical_conduit_79";        arity = 4; tags = ["sync"]; since = "1.2.0"; weight = 1264 };
  { key = "minecart.field.public_0080";                  label = "modern_inventory_80";         arity = 1; tags = ["compat"; "check"; "lower"]; since = "1.0.0"; weight = 1716 };
  { key = "dropper.field.global_0081";                   label = "primary_slot_81";             arity = 7; tags = ["untyped"]; since = "1.9.0"; weight = 31 };
  { key = "piston.field.scoped_0082";                    label = "global_inventory_82";         arity = 0; tags = ["cached"; "legacy"]; since = "1.6.0"; weight = 2022 };
  { key = "rail.field.hidden_0083";                      label = "primary_trade_83";            arity = 0; tags = ["async"]; since = "1.3.1"; weight = 1117 };
  { key = "loom.field.legacy_0084";                      label = "hidden_scoreboard_84";        arity = 7; tags = ["registry"; "cached"]; since = "1.4.0"; weight = 1417 };
  { key = "tablist.field.hidden_0085";                   label = "loose_furnace_85";            arity = 3; tags = ["cold"; "runtime"]; since = "1.9.0"; weight = 2539 };
  { key = "map.field.modern_0086";                       label = "eager_structure_86";          arity = 0; tags = ["cold"; "async"; "sync"]; since = "1.3.1"; weight = 2934 };
  { key = "anvil.field.derived_0087";                    label = "cached_firework_87";          arity = 4; tags = ["legacy"; "sync"; "lower"]; since = "1.5.2"; weight = 4056 };
  { key = "tablist.field.canonical_0088";                label = "cached_item_88";              arity = 2; tags = ["core"; "sync"]; since = "1.5.2"; weight = 2124 };
  { key = "dropper.field.cached_0089";                   label = "internal_smoker_89";          arity = 3; tags = ["async"; "parse"]; since = "1.0.0"; weight = 876 };
  { key = "lectern.field.provisional_0090";              label = "lazy_firework_90";            arity = 6; tags = ["hot"; "registry"]; since = "1.0.0"; weight = 3228 };
  { key = "repeater.field.legacy_0091";                  label = "lazy_dispenser_91";           arity = 2; tags = ["async"; "cold"; "parse"]; since = "1.8.3"; weight = 3899 };
  { key = "anvil.field.global_0092";                     label = "eager_packet_92";             arity = 6; tags = ["parse"; "registry"]; since = "1.9.0"; weight = 2138 };
  { key = "shulker.field.stable_0093";                   label = "hidden_stonecutter_93";       arity = 2; tags = ["parse"; "untyped"]; since = "1.4.0"; weight = 2672 };
  { key = "scoreboard.field.legacy_0094";                label = "fallback_block_94";           arity = 1; tags = ["async"]; since = "1.4.0"; weight = 1231 };
  { key = "target.field.loose_0095";                     label = "global_player_95";            arity = 6; tags = ["untyped"; "hot"; "codegen"]; since = "1.2.0"; weight = 3530 };
  { key = "particle.field.internal_0096";                label = "derived_bossbar_96";          arity = 4; tags = ["content"; "experimental"]; since = "1.7.0"; weight = 3839 };
  { key = "arrow.field.secondary_0097";                  label = "public_composter_97";         arity = 4; tags = ["parse"]; since = "1.5.2"; weight = 2697 };
  { key = "map.field.modern_0098";                       label = "derived_repeater_98";         arity = 4; tags = ["registry"]; since = "1.4.0"; weight = 3564 };
  { key = "slot.field.scoped_0099";                      label = "scoped_smoker_99";            arity = 2; tags = ["cached"; "typed"; "content"]; since = "1.8.3"; weight = 724 };
  { key = "trident.field.modern_0100";                   label = "secondary_structure_100";     arity = 4; tags = ["content"]; since = "1.9.0"; weight = 81 };
  { key = "attribute.field.hidden_0101";                 label = "local_target_101";            arity = 3; tags = ["emit"; "packet"]; since = "1.2.0"; weight = 1204 };
  { key = "trident.field.canonical_0102";                label = "cached_trident_102";          arity = 0; tags = ["cached"]; since = "1.7.0"; weight = 1588 };
  { key = "anvil.field.scoped_0103";                     label = "local_slot_103";              arity = 0; tags = ["typed"]; since = "1.6.0"; weight = 3732 };
  { key = "campfire.field.hidden_0104";                  label = "cached_world_104";            arity = 1; tags = ["emit"]; since = "1.3.1"; weight = 2294 };
  { key = "dropper.field.derived_0105";                  label = "hidden_gui_105";              arity = 4; tags = ["codegen"; "untyped"]; since = "1.7.0"; weight = 3930 };
  { key = "chunk.field.local_0106";                      label = "secondary_cartography_106";   arity = 2; tags = ["typed"; "untyped"; "parse"]; since = "1.9.0"; weight = 1450 };
  { key = "trident.field.eager_0107";                    label = "eager_attribute_107";         arity = 2; tags = ["packet"; "typed"; "parse"]; since = "1.8.3"; weight = 280 };
  { key = "hopper.field.legacy_0108";                    label = "internal_player_108";         arity = 0; tags = ["hot"; "experimental"]; since = "1.2.0"; weight = 1336 };
  { key = "team.field.provisional_0109";                 label = "loose_beacon_109";            arity = 6; tags = ["check"]; since = "1.9.0"; weight = 3898 };
  { key = "portal.field.internal_0110";                  label = "modern_player_110";           arity = 1; tags = ["parse"]; since = "1.7.0"; weight = 3191 };
  { key = "attribute.field.modern_0111";                 label = "global_potion_111";           arity = 1; tags = ["typed"; "emit"; "lower"]; since = "1.7.0"; weight = 3374 };
  { key = "entity.field.legacy_0112";                    label = "public_stonecutter_112";      arity = 7; tags = ["packet"]; since = "1.5.2"; weight = 1210 };
  { key = "pane.field.global_0113";                      label = "stable_stonecutter_113";      arity = 6; tags = ["cold"; "content"; "untyped"]; since = "1.9.0"; weight = 2024 };
  { key = "firework.field.public_0114";                  label = "legacy_team_114";             arity = 3; tags = ["runtime"]; since = "1.4.0"; weight = 1712 };
  { key = "comparator.field.loose_0115";                 label = "scoped_shulker_115";          arity = 1; tags = ["packet"; "runtime"]; since = "1.8.3"; weight = 1300 };
  { key = "block.field.scoped_0116";                     label = "secondary_anvil_116";         arity = 0; tags = ["packet"]; since = "1.6.0"; weight = 2902 };
  { key = "elytra.field.hidden_0117";                    label = "public_furnace_117";          arity = 2; tags = ["hot"; "cold"; "registry"]; since = "1.4.0"; weight = 3620 };
  { key = "hologram.field.legacy_0118";                  label = "fallback_loom_118";           arity = 6; tags = ["cached"; "experimental"]; since = "1.0.0"; weight = 3284 };
  { key = "observer.field.derived_0119";                 label = "hidden_loom_119";             arity = 4; tags = ["cached"; "async"; "content"]; since = "1.0.0"; weight = 2819 };
  { key = "repeater.field.canonical_0120";               label = "loose_potion_120";            arity = 1; tags = ["emit"; "experimental"; "untyped"]; since = "1.6.0"; weight = 846 };
  { key = "lectern.field.internal_0121";                 label = "legacy_team_121";             arity = 1; tags = ["registry"]; since = "1.8.3"; weight = 3777 };
  { key = "arrow.field.strict_0122";                     label = "canonical_portal_122";        arity = 7; tags = ["compat"]; since = "1.5.2"; weight = 2173 };
  { key = "smithing.field.strict_0123";                  label = "hidden_mob_123";              arity = 7; tags = ["lower"; "typed"]; since = "1.3.1"; weight = 3507 };
  { key = "chunk.field.public_0124";                     label = "secondary_clock_124";         arity = 0; tags = ["emit"; "sync"]; since = "1.6.0"; weight = 3311 };
  { key = "crossbow.field.cached_0125";                  label = "cached_loom_125";             arity = 3; tags = ["parse"]; since = "1.8.3"; weight = 2455 };
  { key = "target.field.public_0126";                    label = "strict_lectern_126";          arity = 6; tags = ["content"; "lower"]; since = "1.9.0"; weight = 2289 };
  { key = "villager.field.provisional_0127";             label = "scoped_brewing_127";          arity = 0; tags = ["check"; "registry"; "experimental"]; since = "1.2.0"; weight = 1262 };
  { key = "arrow.field.eager_0128";                      label = "scoped_brewing_128";          arity = 4; tags = ["packet"]; since = "1.6.0"; weight = 3480 };
  { key = "block.field.derived_0129";                    label = "global_sound_129";            arity = 7; tags = ["runtime"]; since = "1.2.0"; weight = 2596 };
  { key = "block.field.cached_0130";                     label = "local_team_130";              arity = 3; tags = ["sync"; "lower"]; since = "1.3.1"; weight = 1384 };
  { key = "dropper.field.fallback_0131";                 label = "secondary_piston_131";        arity = 6; tags = ["check"; "parse"; "untyped"]; since = "1.6.0"; weight = 1447 };
  { key = "crossbow.field.loose_0132";                   label = "fallback_lectern_132";        arity = 4; tags = ["compat"; "cached"]; since = "1.8.3"; weight = 110 };
  { key = "barrel.field.strict_0133";                    label = "global_slot_133";             arity = 2; tags = ["emit"]; since = "1.8.3"; weight = 2311 };
  { key = "gui.field.local_0134";                        label = "scoped_beacon_134";           arity = 5; tags = ["sync"; "compat"]; since = "1.8.3"; weight = 2864 };
  { key = "bossbar.field.primary_0135";                  label = "modern_scoreboard_135";       arity = 5; tags = ["experimental"; "untyped"; "codegen"]; since = "1.9.0"; weight = 430 };
  { key = "bossbar.field.canonical_0136";                label = "modern_chunk_136";            arity = 5; tags = ["hot"; "untyped"; "typed"]; since = "1.4.0"; weight = 1865 };
  { key = "slot.field.loose_0137";                       label = "legacy_biome_137";            arity = 0; tags = ["lower"]; since = "1.0.0"; weight = 1313 };
  { key = "sound.field.derived_0138";                    label = "secondary_entity_138";        arity = 3; tags = ["typed"]; since = "1.2.0"; weight = 4007 };
  { key = "dispenser.field.cached_0139";                 label = "local_portal_139";            arity = 4; tags = ["hot"; "untyped"; "sync"]; since = "1.7.0"; weight = 2382 };
  { key = "comparator.field.stable_0140";                label = "lazy_arrow_140";              arity = 1; tags = ["emit"]; since = "1.9.0"; weight = 3704 };
  { key = "barrel.field.canonical_0141";                 label = "internal_chunk_141";          arity = 5; tags = ["content"; "untyped"; "codegen"]; since = "1.4.0"; weight = 963 };
  { key = "trident.field.loose_0142";                    label = "legacy_npc_142";              arity = 3; tags = ["codegen"]; since = "1.8.3"; weight = 1265 };
  { key = "tablist.field.fallback_0143";                 label = "modern_block_143";            arity = 7; tags = ["sync"; "runtime"; "cached"]; since = "1.2.0"; weight = 942 };
  { key = "barrel.field.provisional_0144";               label = "secondary_banner_144";        arity = 5; tags = ["content"; "hot"; "async"]; since = "1.7.0"; weight = 3835 };
  { key = "hologram.field.lazy_0145";                    label = "derived_enchant_145";         arity = 5; tags = ["core"; "cached"; "sync"]; since = "1.3.1"; weight = 808 };
  { key = "recipe.field.legacy_0146";                    label = "local_structure_146";         arity = 2; tags = ["emit"; "experimental"; "lower"]; since = "1.0.0"; weight = 18 };
  { key = "beacon.field.canonical_0147";                 label = "loose_stonecutter_147";       arity = 7; tags = ["codegen"]; since = "1.6.0"; weight = 3459 };
  { key = "shulker.field.provisional_0148";              label = "legacy_villager_148";         arity = 7; tags = ["codegen"; "emit"]; since = "1.2.0"; weight = 2848 };
  { key = "region.field.cached_0149";                    label = "fallback_enchant_149";        arity = 6; tags = ["sync"; "check"; "lower"]; since = "1.0.0"; weight = 549 };
  { key = "chunk.field.lazy_0150";                       label = "public_bossbar_150";          arity = 6; tags = ["experimental"]; since = "1.0.0"; weight = 3245 };
  { key = "loom.field.legacy_0151";                      label = "provisional_world_151";       arity = 4; tags = ["core"; "parse"; "lower"]; since = "1.3.1"; weight = 526 };
  { key = "compass.field.lazy_0152";                     label = "lazy_recipe_152";             arity = 5; tags = ["cached"; "typed"]; since = "1.2.0"; weight = 2679 };
  { key = "particle.field.internal_0153";                label = "global_region_153";           arity = 1; tags = ["cached"; "emit"]; since = "1.0.0"; weight = 700 };
  { key = "villager.field.public_0154";                  label = "derived_cartography_154";     arity = 1; tags = ["async"; "content"; "packet"]; since = "1.8.3"; weight = 2858 };
  { key = "npc.field.secondary_0155";                    label = "canonical_player_155";        arity = 7; tags = ["cached"; "experimental"; "core"]; since = "1.2.0"; weight = 326 };
  { key = "anvil.field.modern_0156";                     label = "secondary_shield_156";        arity = 5; tags = ["core"; "experimental"]; since = "1.6.0"; weight = 1158 };
  { key = "objective.field.modern_0157";                 label = "strict_boat_157";             arity = 6; tags = ["emit"]; since = "1.4.0"; weight = 1073 };
  { key = "firework.field.modern_0158";                  label = "strict_rail_158";             arity = 7; tags = ["registry"]; since = "1.8.3"; weight = 258 };
  { key = "particle.field.public_0159";                  label = "global_portal_159";           arity = 7; tags = ["async"; "content"]; since = "1.7.0"; weight = 4096 };
  { key = "elytra.field.loose_0160";                     label = "hidden_elytra_160";           arity = 7; tags = ["compat"; "legacy"; "typed"]; since = "1.2.0"; weight = 810 };
  { key = "elytra.field.cached_0161";                    label = "eager_clock_161";             arity = 7; tags = ["experimental"; "content"]; since = "1.5.2"; weight = 424 };
  { key = "firework.field.strict_0162";                  label = "loose_team_162";              arity = 3; tags = ["lower"; "untyped"]; since = "1.8.3"; weight = 835 };
  { key = "portal.field.stable_0163";                    label = "provisional_lectern_163";     arity = 6; tags = ["async"]; since = "1.3.1"; weight = 3543 };
  { key = "target.field.legacy_0164";                    label = "derived_brewing_164";         arity = 7; tags = ["hot"; "typed"]; since = "1.8.3"; weight = 3451 };
  { key = "packet.field.stable_0165";                    label = "global_elytra_165";           arity = 3; tags = ["registry"]; since = "1.2.0"; weight = 3050 };
  { key = "sound.field.modern_0166";                     label = "scoped_stonecutter_166";      arity = 7; tags = ["lower"]; since = "1.5.2"; weight = 1788 };
  { key = "smoker.field.stable_0167";                    label = "strict_boat_167";             arity = 6; tags = ["hot"; "runtime"; "sync"]; since = "1.7.0"; weight = 1746 };
  { key = "portal.field.public_0168";                    label = "global_attribute_168";        arity = 2; tags = ["core"; "parse"; "typed"]; since = "1.3.1"; weight = 3622 };
  { key = "conduit.field.global_0169";                   label = "public_attribute_169";        arity = 1; tags = ["registry"; "typed"]; since = "1.5.2"; weight = 1026 };
  { key = "pane.field.derived_0170";                     label = "cached_banner_170";           arity = 5; tags = ["packet"; "registry"; "core"]; since = "1.8.3"; weight = 2651 };
  { key = "campfire.field.public_0171";                  label = "derived_objective_171";       arity = 3; tags = ["legacy"]; since = "1.7.0"; weight = 3513 };
  { key = "map.field.public_0172";                       label = "provisional_bell_172";        arity = 7; tags = ["untyped"; "packet"; "check"]; since = "1.7.0"; weight = 3105 };
  { key = "bossbar.field.primary_0173";                  label = "hidden_shield_173";           arity = 7; tags = ["registry"]; since = "1.2.0"; weight = 3319 };
  { key = "block.field.local_0174";                      label = "fallback_piston_174";         arity = 2; tags = ["compat"; "content"; "runtime"]; since = "1.7.0"; weight = 1538 };
  { key = "block.field.secondary_0175";                  label = "cached_shulker_175";          arity = 4; tags = ["content"; "compat"; "experimental"]; since = "1.6.0"; weight = 3659 };
  { key = "advancement.field.hidden_0176";               label = "internal_furnace_176";        arity = 5; tags = ["cold"]; since = "1.8.3"; weight = 2990 };
  { key = "potion.field.legacy_0177";                    label = "eager_bossbar_177";           arity = 0; tags = ["async"; "content"; "untyped"]; since = "1.3.1"; weight = 2845 };
  { key = "rail.field.derived_0178";                     label = "stable_lectern_178";          arity = 3; tags = ["runtime"]; since = "1.5.2"; weight = 3722 };
  { key = "brewing.field.internal_0179";                 label = "secondary_block_179";         arity = 1; tags = ["core"; "packet"; "hot"]; since = "1.5.2"; weight = 2595 };
  { key = "smithing.field.stable_0180";                  label = "lazy_furnace_180";            arity = 3; tags = ["legacy"; "registry"; "sync"]; since = "1.5.2"; weight = 1846 };
  { key = "target.field.primary_0181";                   label = "fallback_crossbow_181";       arity = 3; tags = ["packet"]; since = "1.6.0"; weight = 1109 };
  { key = "effect.field.scoped_0182";                    label = "scoped_piston_182";           arity = 4; tags = ["experimental"; "codegen"]; since = "1.4.0"; weight = 2790 };
  { key = "tablist.field.eager_0183";                    label = "scoped_chunk_183";            arity = 3; tags = ["emit"; "check"; "experimental"]; since = "1.2.0"; weight = 3147 };
  { key = "gui.field.internal_0184";                     label = "scoped_player_184";           arity = 2; tags = ["compat"; "typed"]; since = "1.6.0"; weight = 2230 };
  { key = "map.field.legacy_0185";                       label = "loose_piston_185";            arity = 5; tags = ["registry"]; since = "1.0.0"; weight = 3767 };
  { key = "portal.field.eager_0186";                     label = "fallback_barrel_186";         arity = 2; tags = ["typed"]; since = "1.4.0"; weight = 3333 };
  { key = "stonecutter.field.loose_0187";                label = "internal_player_187";         arity = 0; tags = ["hot"; "emit"]; since = "1.6.0"; weight = 1907 };
  { key = "trident.field.strict_0188";                   label = "loose_composter_188";         arity = 1; tags = ["cached"]; since = "1.7.0"; weight = 1260 };
  { key = "block.field.primary_0189";                    label = "eager_firework_189";          arity = 3; tags = ["content"; "experimental"; "cold"]; since = "1.7.0"; weight = 1254 };
  { key = "sound.field.public_0190";                     label = "scoped_structure_190";        arity = 0; tags = ["lower"; "core"; "cached"]; since = "1.0.0"; weight = 3223 };
  { key = "bundle.field.modern_0191";                    label = "legacy_beacon_191";           arity = 4; tags = ["experimental"; "untyped"]; since = "1.9.0"; weight = 3819 };
  { key = "composter.field.provisional_0192";            label = "fallback_shield_192";         arity = 4; tags = ["typed"]; since = "1.8.3"; weight = 1736 };
  { key = "composter.field.public_0193";                 label = "modern_particle_193";         arity = 6; tags = ["codegen"]; since = "1.3.1"; weight = 3590 };
  { key = "trident.field.fallback_0194";                 label = "loose_smoker_194";            arity = 3; tags = ["lower"; "runtime"]; since = "1.2.0"; weight = 2138 };
  { key = "piston.field.secondary_0195";                 label = "lazy_attribute_195";          arity = 6; tags = ["cold"; "check"; "registry"]; since = "1.4.0"; weight = 2435 };
  { key = "composter.field.modern_0196";                 label = "canonical_lectern_196";       arity = 6; tags = ["typed"]; since = "1.3.1"; weight = 366 };
  { key = "grindstone.field.hidden_0197";                label = "primary_attribute_197";       arity = 3; tags = ["check"; "legacy"]; since = "1.4.0"; weight = 1673 };
  { key = "map.field.lazy_0198";                         label = "fallback_player_198";         arity = 7; tags = ["cached"]; since = "1.0.0"; weight = 37 };
  { key = "compass.field.derived_0199";                  label = "secondary_composter_199";     arity = 3; tags = ["parse"; "lower"; "untyped"]; since = "1.8.3"; weight = 639 };
  { key = "world.field.internal_0200";                   label = "secondary_bundle_200";        arity = 2; tags = ["lower"]; since = "1.5.2"; weight = 1330 };
  { key = "packet.field.hidden_0201";                    label = "fallback_team_201";           arity = 1; tags = ["runtime"; "sync"]; since = "1.0.0"; weight = 2897 };
  { key = "region.field.primary_0202";                   label = "fallback_player_202";         arity = 1; tags = ["sync"; "hot"]; since = "1.4.0"; weight = 2721 };
  { key = "potion.field.strict_0203";                    label = "public_brewing_203";          arity = 3; tags = ["core"; "runtime"; "async"]; since = "1.3.1"; weight = 1113 };
  { key = "hopper.field.stable_0204";                    label = "internal_packet_204";         arity = 0; tags = ["compat"; "codegen"; "sync"]; since = "1.7.0"; weight = 2000 };
  { key = "smithing.field.global_0205";                  label = "derived_conduit_205";         arity = 2; tags = ["compat"]; since = "1.5.2"; weight = 325 };
  { key = "structure.field.derived_0206";                label = "primary_tablist_206";         arity = 5; tags = ["sync"; "runtime"; "hot"]; since = "1.5.2"; weight = 1949 };
  { key = "team.field.public_0207";                      label = "legacy_bundle_207";           arity = 6; tags = ["untyped"]; since = "1.5.2"; weight = 1947 };
  { key = "villager.field.legacy_0208";                  label = "fallback_arrow_208";          arity = 2; tags = ["content"; "core"]; since = "1.9.0"; weight = 3963 };
  { key = "barrel.field.local_0209";                     label = "secondary_firework_209";      arity = 3; tags = ["registry"]; since = "1.9.0"; weight = 3028 };
  { key = "rail.field.canonical_0210";                   label = "scoped_arrow_210";            arity = 3; tags = ["packet"; "untyped"; "runtime"]; since = "1.5.2"; weight = 1390 };
  { key = "world.field.provisional_0211";                label = "public_beacon_211";           arity = 1; tags = ["core"]; since = "1.4.0"; weight = 3423 };
  { key = "boat.field.stable_0212";                      label = "global_entity_212";           arity = 3; tags = ["registry"]; since = "1.9.0"; weight = 3276 };
  { key = "minecart.field.provisional_0213";             label = "eager_region_213";            arity = 7; tags = ["parse"]; since = "1.9.0"; weight = 3855 };
  { key = "anvil.field.provisional_0214";                label = "provisional_npc_214";         arity = 3; tags = ["content"]; since = "1.6.0"; weight = 1725 };
  { key = "item.field.modern_0215";                      label = "lazy_comparator_215";         arity = 1; tags = ["untyped"; "experimental"]; since = "1.0.0"; weight = 1687 };
  { key = "structure.field.global_0216";                 label = "internal_map_216";            arity = 3; tags = ["cached"; "compat"; "parse"]; since = "1.9.0"; weight = 1649 };
  { key = "beacon.field.hidden_0217";                    label = "legacy_scoreboard_217";       arity = 4; tags = ["lower"; "hot"; "experimental"]; since = "1.4.0"; weight = 1742 };
  { key = "anvil.field.primary_0218";                    label = "derived_target_218";          arity = 3; tags = ["core"]; since = "1.2.0"; weight = 1689 };
  { key = "compass.field.derived_0219";                  label = "scoped_effect_219";           arity = 0; tags = ["check"]; since = "1.2.0"; weight = 839 };
  { key = "clock.field.strict_0220";                     label = "scoped_map_220";              arity = 7; tags = ["untyped"]; since = "1.9.0"; weight = 2008 };
  { key = "gui.field.scoped_0221";                       label = "scoped_rail_221";             arity = 1; tags = ["async"; "sync"; "typed"]; since = "1.9.0"; weight = 3909 };
  { key = "player.field.lazy_0222";                      label = "primary_bell_222";            arity = 3; tags = ["content"; "sync"; "codegen"]; since = "1.7.0"; weight = 3404 };
  { key = "cartography.field.scoped_0223";               label = "scoped_npc_223";              arity = 4; tags = ["typed"]; since = "1.8.3"; weight = 3112 };
  { key = "anvil.field.internal_0224";                   label = "canonical_minecart_224";      arity = 6; tags = ["packet"; "sync"]; since = "1.3.1"; weight = 2633 };
  { key = "compass.field.global_0225";                   label = "modern_portal_225";           arity = 7; tags = ["content"; "legacy"]; since = "1.9.0"; weight = 752 };
  { key = "beacon.field.hidden_0226";                    label = "hidden_banner_226";           arity = 4; tags = ["typed"]; since = "1.9.0"; weight = 2390 };
  { key = "comparator.field.secondary_0227";             label = "canonical_attribute_227";     arity = 5; tags = ["async"]; since = "1.2.0"; weight = 1076 };
  { key = "dispenser.field.primary_0228";                label = "stable_villager_228";         arity = 4; tags = ["experimental"; "core"; "codegen"]; since = "1.0.0"; weight = 3782 };
  { key = "brewing.field.loose_0229";                    label = "canonical_entity_229";        arity = 4; tags = ["legacy"; "core"; "experimental"]; since = "1.8.3"; weight = 1365 };
  { key = "observer.field.cached_0230";                  label = "provisional_packet_230";      arity = 3; tags = ["registry"; "compat"; "content"]; since = "1.2.0"; weight = 3931 };
  { key = "team.field.eager_0231";                       label = "eager_barrel_231";            arity = 5; tags = ["sync"; "parse"; "typed"]; since = "1.5.2"; weight = 4026 };
  { key = "minecart.field.derived_0232";                 label = "lazy_trade_232";              arity = 4; tags = ["lower"; "compat"]; since = "1.3.1"; weight = 2936 };
  { key = "biome.field.modern_0233";                     label = "local_anvil_233";             arity = 2; tags = ["codegen"; "compat"; "check"]; since = "1.3.1"; weight = 4034 };
  { key = "observer.field.strict_0234";                  label = "eager_block_234";             arity = 6; tags = ["runtime"; "async"]; since = "1.5.2"; weight = 388 };
  { key = "rail.field.global_0235";                      label = "global_arrow_235";            arity = 4; tags = ["hot"; "codegen"]; since = "1.4.0"; weight = 3361 };
  { key = "bell.field.eager_0236";                       label = "lazy_stonecutter_236";        arity = 6; tags = ["lower"; "packet"]; since = "1.8.3"; weight = 2176 };
  { key = "npc.field.internal_0237";                     label = "local_composter_237";         arity = 3; tags = ["packet"; "compat"; "registry"]; since = "1.8.3"; weight = 395 };
  { key = "firework.field.loose_0238";                   label = "scoped_smoker_238";           arity = 0; tags = ["legacy"; "registry"; "compat"]; since = "1.8.3"; weight = 765 };
  { key = "slot.field.hidden_0239";                      label = "lazy_enchant_239";            arity = 5; tags = ["async"]; since = "1.7.0"; weight = 3251 };
  { key = "attribute.field.secondary_0240";              label = "canonical_team_240";          arity = 3; tags = ["content"; "codegen"]; since = "1.6.0"; weight = 3076 };
  { key = "attribute.field.eager_0241";                  label = "lazy_rail_241";               arity = 3; tags = ["content"]; since = "1.5.2"; weight = 2176 };
  { key = "map.field.internal_0242";                     label = "derived_smoker_242";          arity = 3; tags = ["parse"]; since = "1.6.0"; weight = 4072 };
  { key = "clock.field.derived_0243";                    label = "strict_loom_243";             arity = 6; tags = ["registry"; "legacy"]; since = "1.9.0"; weight = 94 };
  { key = "shield.field.lazy_0244";                      label = "secondary_beacon_244";        arity = 0; tags = ["sync"]; since = "1.7.0"; weight = 1189 };
  { key = "entity.field.stable_0245";                    label = "lazy_lectern_245";            arity = 1; tags = ["content"; "cold"; "experimental"]; since = "1.8.3"; weight = 1558 };
  { key = "particle.field.derived_0246";                 label = "fallback_beacon_246";         arity = 2; tags = ["legacy"; "hot"; "compat"]; since = "1.7.0"; weight = 3063 };
  { key = "biome.field.canonical_0247";                  label = "secondary_npc_247";           arity = 5; tags = ["sync"; "experimental"]; since = "1.5.2"; weight = 274 };
  { key = "inventory.field.local_0248";                  label = "provisional_beacon_248";      arity = 7; tags = ["core"]; since = "1.7.0"; weight = 2968 };
  { key = "chunk.field.internal_0249";                   label = "internal_map_249";            arity = 4; tags = ["check"]; since = "1.9.0"; weight = 1067 };
  { key = "conduit.field.local_0250";                    label = "primary_player_250";          arity = 1; tags = ["sync"]; since = "1.5.2"; weight = 1353 };
  { key = "block.field.derived_0251";                    label = "loose_advancement_251";       arity = 7; tags = ["legacy"; "runtime"]; since = "1.4.0"; weight = 1372 };
  { key = "bossbar.field.strict_0252";                   label = "eager_furnace_252";           arity = 7; tags = ["check"; "emit"]; since = "1.5.2"; weight = 2723 };
  { key = "smoker.field.secondary_0253";                 label = "loose_sound_253";             arity = 0; tags = ["typed"; "codegen"; "async"]; since = "1.4.0"; weight = 3345 };
  { key = "biome.field.modern_0254";                     label = "derived_target_254";          arity = 4; tags = ["parse"; "registry"]; since = "1.6.0"; weight = 2914 };
  { key = "boat.field.public_0255";                      label = "hidden_trident_255";          arity = 7; tags = ["codegen"; "compat"; "hot"]; since = "1.6.0"; weight = 3742 };
  { key = "mob.field.derived_0256";                      label = "internal_hologram_256";       arity = 0; tags = ["core"]; since = "1.3.1"; weight = 82 };
  { key = "spawner.field.lazy_0257";                     label = "cached_recipe_257";           arity = 3; tags = ["hot"; "experimental"]; since = "1.4.0"; weight = 166 };
  { key = "gui.field.derived_0258";                      label = "strict_boat_258";             arity = 0; tags = ["parse"; "content"; "packet"]; since = "1.4.0"; weight = 1457 };
  { key = "enchant.field.legacy_0259";                   label = "hidden_minecart_259";         arity = 1; tags = ["compat"; "core"; "lower"]; since = "1.7.0"; weight = 3702 };
  { key = "potion.field.loose_0260";                     label = "legacy_repeater_260";         arity = 3; tags = ["parse"; "runtime"; "compat"]; since = "1.5.2"; weight = 129 };
  { key = "smoker.field.strict_0261";                    label = "internal_shulker_261";        arity = 0; tags = ["experimental"; "registry"; "runtime"]; since = "1.4.0"; weight = 475 };
  { key = "advancement.field.provisional_0262";          label = "canonical_biome_262";         arity = 7; tags = ["emit"]; since = "1.9.0"; weight = 2490 };
  { key = "composter.field.lazy_0263";                   label = "public_pane_263";             arity = 6; tags = ["content"]; since = "1.2.0"; weight = 2999 };
  { key = "mob.field.derived_0264";                      label = "canonical_arrow_264";         arity = 4; tags = ["untyped"; "async"; "parse"]; since = "1.0.0"; weight = 2524 };
  { key = "repeater.field.loose_0265";                   label = "derived_banner_pattern_265";  arity = 0; tags = ["registry"; "core"]; since = "1.2.0"; weight = 3559 };
  { key = "clock.field.local_0266";                      label = "hidden_particle_266";         arity = 3; tags = ["untyped"; "emit"]; since = "1.3.1"; weight = 854 };
  { key = "loom.field.secondary_0267";                   label = "internal_villager_267";       arity = 5; tags = ["hot"; "legacy"; "cold"]; since = "1.6.0"; weight = 3737 };
  { key = "shulker.field.derived_0268";                  label = "cached_trident_268";          arity = 2; tags = ["async"]; since = "1.4.0"; weight = 2560 };
  { key = "furnace.field.local_0269";                    label = "derived_map_269";             arity = 1; tags = ["cached"; "cold"; "runtime"]; since = "1.4.0"; weight = 3348 };
  { key = "grindstone.field.loose_0270";                 label = "provisional_firework_270";    arity = 3; tags = ["core"]; since = "1.5.2"; weight = 168 };
  { key = "world.field.provisional_0271";                label = "canonical_shield_271";        arity = 0; tags = ["packet"; "cold"; "content"]; since = "1.5.2"; weight = 3044 };
  { key = "crossbow.field.scoped_0272";                  label = "derived_inventory_272";       arity = 5; tags = ["parse"; "compat"; "typed"]; since = "1.5.2"; weight = 464 };
  { key = "stonecutter.field.hidden_0273";               label = "canonical_bossbar_273";       arity = 7; tags = ["emit"]; since = "1.8.3"; weight = 3324 };
  { key = "scoreboard.field.local_0274";                 label = "primary_region_274";          arity = 5; tags = ["legacy"; "check"]; since = "1.2.0"; weight = 2977 };
  { key = "boat.field.strict_0275";                      label = "hidden_region_275";           arity = 7; tags = ["cold"]; since = "1.2.0"; weight = 1054 };
  { key = "cartography.field.modern_0276";               label = "canonical_bossbar_276";       arity = 2; tags = ["packet"; "cold"; "untyped"]; since = "1.6.0"; weight = 4008 };
  { key = "npc.field.global_0277";                       label = "public_brewing_277";          arity = 4; tags = ["codegen"; "untyped"; "packet"]; since = "1.7.0"; weight = 760 };
  { key = "grindstone.field.hidden_0278";                label = "lazy_crossbow_278";           arity = 0; tags = ["runtime"]; since = "1.0.0"; weight = 1307 };
  { key = "player.field.internal_0279";                  label = "loose_piston_279";            arity = 2; tags = ["cold"]; since = "1.0.0"; weight = 988 };
  { key = "compass.field.scoped_0280";                   label = "global_item_280";             arity = 6; tags = ["packet"; "hot"]; since = "1.2.0"; weight = 1593 };
  { key = "scoreboard.field.stable_0281";                label = "eager_gui_281";               arity = 3; tags = ["runtime"; "async"]; since = "1.2.0"; weight = 2400 };
  { key = "dropper.field.internal_0282";                 label = "local_smithing_282";          arity = 0; tags = ["core"; "sync"; "experimental"]; since = "1.9.0"; weight = 2357 };
  { key = "rail.field.primary_0283";                     label = "cached_chunk_283";            arity = 1; tags = ["compat"; "packet"]; since = "1.2.0"; weight = 962 };
  { key = "compass.field.fallback_0284";                 label = "hidden_crossbow_284";         arity = 6; tags = ["codegen"; "emit"]; since = "1.4.0"; weight = 2785 };
  { key = "grindstone.field.fallback_0285";              label = "derived_attribute_285";       arity = 3; tags = ["typed"]; since = "1.8.3"; weight = 3206 };
  { key = "boat.field.canonical_0286";                   label = "scoped_hopper_286";           arity = 7; tags = ["emit"; "typed"]; since = "1.5.2"; weight = 4050 };
  { key = "block.field.global_0287";                     label = "provisional_entity_287";      arity = 3; tags = ["emit"; "sync"; "hot"]; since = "1.0.0"; weight = 185 };
  { key = "target.field.legacy_0288";                    label = "public_sound_288";            arity = 6; tags = ["parse"]; since = "1.7.0"; weight = 1446 };
  { key = "cartography.field.loose_0289";                label = "lazy_boat_289";               arity = 6; tags = ["lower"; "check"]; since = "1.8.3"; weight = 1904 };
  { key = "rail.field.canonical_0290";                   label = "hidden_beacon_290";           arity = 5; tags = ["hot"; "typed"; "cold"]; since = "1.6.0"; weight = 226 };
  { key = "slot.field.derived_0291";                     label = "hidden_stonecutter_291";      arity = 6; tags = ["packet"; "content"; "core"]; since = "1.4.0"; weight = 1075 };
  { key = "block.field.global_0292";                     label = "loose_attribute_292";         arity = 4; tags = ["hot"; "core"; "parse"]; since = "1.9.0"; weight = 311 };
  { key = "composter.field.local_0293";                  label = "stable_cartography_293";      arity = 3; tags = ["async"]; since = "1.2.0"; weight = 2088 };
  { key = "bossbar.field.loose_0294";                    label = "provisional_grindstone_294";  arity = 7; tags = ["content"]; since = "1.7.0"; weight = 1924 };
  { key = "arrow.field.canonical_0295";                  label = "legacy_furnace_295";          arity = 0; tags = ["sync"; "experimental"; "compat"]; since = "1.2.0"; weight = 2810 };
  { key = "banner_pattern.field.provisional_0296";       label = "cached_map_296";              arity = 2; tags = ["registry"]; since = "1.4.0"; weight = 2358 };
  { key = "barrel.field.hidden_0297";                    label = "cached_block_297";            arity = 0; tags = ["async"; "sync"; "untyped"]; since = "1.5.2"; weight = 272 };
  { key = "comparator.field.internal_0298";              label = "global_npc_298";              arity = 3; tags = ["runtime"]; since = "1.0.0"; weight = 2825 };
  { key = "recipe.field.canonical_0299";                 label = "cached_chunk_299";            arity = 1; tags = ["parse"; "packet"; "async"]; since = "1.7.0"; weight = 2191 };
  { key = "dropper.field.public_0300";                   label = "lazy_bossbar_300";            arity = 4; tags = ["untyped"; "hot"]; since = "1.6.0"; weight = 2049 };
  { key = "slot.field.scoped_0301";                      label = "internal_packet_301";         arity = 3; tags = ["packet"; "codegen"]; since = "1.2.0"; weight = 2892 };
  { key = "enchant.field.global_0302";                   label = "canonical_sound_302";         arity = 6; tags = ["emit"; "core"]; since = "1.8.3"; weight = 976 };
  { key = "block.field.eager_0303";                      label = "global_pane_303";             arity = 3; tags = ["content"]; since = "1.6.0"; weight = 2579 };
  { key = "biome.field.internal_0304";                   label = "canonical_compass_304";       arity = 2; tags = ["registry"; "async"]; since = "1.6.0"; weight = 3676 };
  { key = "furnace.field.scoped_0305";                   label = "legacy_entity_305";           arity = 7; tags = ["runtime"]; since = "1.3.1"; weight = 984 };
  { key = "chunk.field.lazy_0306";                       label = "strict_dropper_306";          arity = 4; tags = ["content"; "packet"]; since = "1.4.0"; weight = 128 };
  { key = "block.field.strict_0307";                     label = "fallback_biome_307";          arity = 1; tags = ["runtime"; "parse"]; since = "1.3.1"; weight = 2230 };
  { key = "particle.field.secondary_0308";               label = "scoped_shulker_308";          arity = 1; tags = ["cold"; "legacy"; "registry"]; since = "1.5.2"; weight = 332 };
  { key = "team.field.fallback_0309";                    label = "stable_clock_309";            arity = 0; tags = ["experimental"; "compat"; "async"]; since = "1.9.0"; weight = 640 };
  { key = "arrow.field.stable_0310";                     label = "loose_map_310";               arity = 2; tags = ["compat"]; since = "1.9.0"; weight = 257 };
  { key = "item.field.provisional_0311";                 label = "lazy_world_311";              arity = 2; tags = ["lower"; "async"; "cached"]; since = "1.0.0"; weight = 940 };
  { key = "comparator.field.strict_0312";                label = "primary_chunk_312";           arity = 5; tags = ["cached"]; since = "1.8.3"; weight = 3512 };
  { key = "player.field.internal_0313";                  label = "primary_world_313";           arity = 0; tags = ["packet"; "lower"]; since = "1.8.3"; weight = 69 };
  { key = "hopper.field.local_0314";                     label = "scoped_lectern_314";          arity = 1; tags = ["runtime"; "compat"]; since = "1.2.0"; weight = 1038 };
  { key = "scoreboard.field.secondary_0315";             label = "eager_bell_315";              arity = 7; tags = ["lower"]; since = "1.0.0"; weight = 1302 };
  { key = "minecart.field.global_0316";                  label = "secondary_advancement_316";   arity = 6; tags = ["runtime"]; since = "1.6.0"; weight = 820 };
  { key = "gui.field.global_0317";                       label = "loose_advancement_317";       arity = 0; tags = ["check"]; since = "1.3.1"; weight = 3282 };
  { key = "firework.field.stable_0318";                  label = "primary_lectern_318";         arity = 0; tags = ["hot"; "emit"]; since = "1.3.1"; weight = 2944 };
  { key = "hologram.field.lazy_0319";                    label = "eager_crossbow_319";          arity = 5; tags = ["async"; "core"; "legacy"]; since = "1.8.3"; weight = 3975 };
  { key = "scoreboard.field.provisional_0320";           label = "eager_particle_320";          arity = 4; tags = ["legacy"; "async"]; since = "1.3.1"; weight = 853 };
  { key = "lectern.field.internal_0321";                 label = "derived_slot_321";            arity = 7; tags = ["codegen"]; since = "1.5.2"; weight = 715 };
  { key = "hopper.field.loose_0322";                     label = "fallback_hopper_322";         arity = 2; tags = ["packet"; "untyped"]; since = "1.5.2"; weight = 556 };
  { key = "potion.field.strict_0323";                    label = "internal_piston_323";         arity = 4; tags = ["lower"; "async"; "untyped"]; since = "1.7.0"; weight = 2483 };
  { key = "smithing.field.provisional_0324";             label = "cached_player_324";           arity = 6; tags = ["runtime"]; since = "1.0.0"; weight = 142 };
  { key = "piston.field.scoped_0325";                    label = "hidden_potion_325";           arity = 2; tags = ["untyped"]; since = "1.7.0"; weight = 1098 };
  { key = "firework.field.global_0326";                  label = "fallback_bossbar_326";        arity = 4; tags = ["untyped"]; since = "1.6.0"; weight = 2957 };
  { key = "hologram.field.scoped_0327";                  label = "cached_anvil_327";            arity = 5; tags = ["core"]; since = "1.2.0"; weight = 1376 };
  { key = "advancement.field.secondary_0328";            label = "primary_anvil_328";           arity = 0; tags = ["runtime"; "emit"; "content"]; since = "1.2.0"; weight = 166 };
  { key = "rail.field.hidden_0329";                      label = "provisional_chunk_329";       arity = 0; tags = ["async"]; since = "1.7.0"; weight = 2369 };
  { key = "potion.field.derived_0330";                   label = "hidden_composter_330";        arity = 7; tags = ["check"]; since = "1.4.0"; weight = 3841 };
  { key = "trade.field.scoped_0331";                     label = "internal_grindstone_331";     arity = 4; tags = ["sync"; "async"]; since = "1.6.0"; weight = 2567 };
  { key = "firework.field.provisional_0332";             label = "internal_bell_332";           arity = 7; tags = ["check"; "cached"; "experimental"]; since = "1.3.1"; weight = 4035 };
  { key = "item.field.local_0333";                       label = "global_effect_333";           arity = 2; tags = ["cold"]; since = "1.2.0"; weight = 3279 };
  { key = "cartography.field.strict_0334";               label = "primary_inventory_334";       arity = 5; tags = ["parse"; "runtime"; "cached"]; since = "1.4.0"; weight = 3478 };
  { key = "portal.field.fallback_0335";                  label = "eager_trade_335";             arity = 1; tags = ["compat"]; since = "1.3.1"; weight = 3157 };
  { key = "pane.field.loose_0336";                       label = "local_mob_336";               arity = 3; tags = ["core"; "hot"]; since = "1.6.0"; weight = 2672 };
  { key = "crossbow.field.provisional_0337";             label = "modern_firework_337";         arity = 5; tags = ["codegen"]; since = "1.3.1"; weight = 431 };
  { key = "dropper.field.secondary_0338";                label = "lazy_block_338";              arity = 6; tags = ["runtime"; "codegen"]; since = "1.6.0"; weight = 2704 };
  { key = "packet.field.provisional_0339";               label = "scoped_block_339";            arity = 1; tags = ["check"]; since = "1.3.1"; weight = 1691 };
  { key = "portal.field.hidden_0340";                    label = "fallback_furnace_340";        arity = 3; tags = ["content"; "async"]; since = "1.4.0"; weight = 48 };
  { key = "slot.field.stable_0341";                      label = "internal_bundle_341";         arity = 6; tags = ["cold"; "packet"]; since = "1.5.2"; weight = 339 };
  { key = "brewing.field.global_0342";                   label = "canonical_scoreboard_342";    arity = 1; tags = ["runtime"]; since = "1.5.2"; weight = 3118 };
  { key = "banner.field.strict_0343";                    label = "strict_trident_343";          arity = 7; tags = ["content"; "cold"]; since = "1.9.0"; weight = 929 };
  { key = "stonecutter.field.public_0344";               label = "legacy_hologram_344";         arity = 2; tags = ["sync"]; since = "1.6.0"; weight = 2459 };
  { key = "elytra.field.eager_0345";                     label = "scoped_campfire_345";         arity = 1; tags = ["content"; "registry"]; since = "1.9.0"; weight = 2267 };
  { key = "mob.field.provisional_0346";                  label = "stable_biome_346";            arity = 3; tags = ["check"; "legacy"]; since = "1.9.0"; weight = 2503 };
  { key = "bundle.field.cached_0347";                    label = "internal_bundle_347";         arity = 2; tags = ["compat"; "runtime"; "sync"]; since = "1.2.0"; weight = 3756 };
  { key = "attribute.field.cached_0348";                 label = "fallback_hologram_348";       arity = 6; tags = ["typed"; "core"; "registry"]; since = "1.7.0"; weight = 3375 };
  { key = "player.field.scoped_0349";                    label = "canonical_objective_349";     arity = 7; tags = ["check"]; since = "1.2.0"; weight = 1056 };
  { key = "boat.field.stable_0350";                      label = "legacy_chunk_350";            arity = 6; tags = ["typed"; "emit"; "parse"]; since = "1.6.0"; weight = 1403 };
  { key = "trade.field.cached_0351";                     label = "stable_tablist_351";          arity = 6; tags = ["untyped"; "runtime"; "lower"]; since = "1.7.0"; weight = 1219 };
  { key = "team.field.legacy_0352";                      label = "secondary_cartography_352";   arity = 0; tags = ["check"]; since = "1.7.0"; weight = 2866 };
  { key = "comparator.field.public_0353";                label = "provisional_shield_353";      arity = 3; tags = ["typed"; "codegen"; "registry"]; since = "1.2.0"; weight = 408 };
  { key = "comparator.field.cached_0354";                label = "legacy_recipe_354";           arity = 2; tags = ["cached"; "parse"]; since = "1.8.3"; weight = 2661 };
  { key = "sound.field.scoped_0355";                     label = "lazy_cartography_355";        arity = 4; tags = ["compat"]; since = "1.4.0"; weight = 760 };
  { key = "spawner.field.hidden_0356";                   label = "loose_conduit_356";           arity = 1; tags = ["codegen"]; since = "1.7.0"; weight = 1529 };
  { key = "smithing.field.eager_0357";                   label = "stable_player_357";           arity = 3; tags = ["lower"]; since = "1.0.0"; weight = 4077 };
  { key = "bundle.field.lazy_0358";                      label = "internal_loom_358";           arity = 4; tags = ["compat"]; since = "1.7.0"; weight = 1692 };
  { key = "player.field.lazy_0359";                      label = "primary_arrow_359";           arity = 5; tags = ["untyped"]; since = "1.4.0"; weight = 3378 };
  { key = "trident.field.local_0360";                    label = "internal_minecart_360";       arity = 5; tags = ["emit"; "compat"; "runtime"]; since = "1.5.2"; weight = 942 };
  { key = "trident.field.hidden_0361";                   label = "cached_piston_361";           arity = 4; tags = ["lower"]; since = "1.5.2"; weight = 1773 };
  { key = "player.field.strict_0362";                    label = "stable_rail_362";             arity = 0; tags = ["packet"; "sync"]; since = "1.2.0"; weight = 45 };
  { key = "comparator.field.loose_0363";                 label = "primary_slot_363";            arity = 3; tags = ["codegen"]; since = "1.4.0"; weight = 385 };
  { key = "villager.field.local_0364";                   label = "strict_dropper_364";          arity = 2; tags = ["sync"; "async"; "parse"]; since = "1.2.0"; weight = 2221 };
  { key = "grindstone.field.derived_0365";               label = "internal_smoker_365";         arity = 4; tags = ["legacy"]; since = "1.8.3"; weight = 3354 };
  { key = "smithing.field.primary_0366";                 label = "internal_advancement_366";    arity = 3; tags = ["legacy"]; since = "1.8.3"; weight = 2603 };
  { key = "boat.field.secondary_0367";                   label = "local_shield_367";            arity = 6; tags = ["emit"; "legacy"; "typed"]; since = "1.0.0"; weight = 2531 };
  { key = "gui.field.fallback_0368";                     label = "local_observer_368";          arity = 0; tags = ["hot"; "sync"]; since = "1.3.1"; weight = 1889 };
  { key = "mob.field.primary_0369";                      label = "hidden_particle_369";         arity = 2; tags = ["cached"; "untyped"; "packet"]; since = "1.5.2"; weight = 3899 };
  { key = "hopper.field.legacy_0370";                    label = "public_trade_370";            arity = 3; tags = ["packet"]; since = "1.0.0"; weight = 3534 };
  { key = "smithing.field.scoped_0371";                  label = "legacy_inventory_371";        arity = 5; tags = ["runtime"; "legacy"; "core"]; since = "1.6.0"; weight = 3066 };
  { key = "player.field.legacy_0372";                    label = "scoped_anvil_372";            arity = 6; tags = ["untyped"; "registry"]; since = "1.8.3"; weight = 316 };
  { key = "smithing.field.primary_0373";                 label = "eager_lectern_373";           arity = 2; tags = ["cached"; "content"; "parse"]; since = "1.2.0"; weight = 971 };
  { key = "recipe.field.local_0374";                     label = "scoped_attribute_374";        arity = 3; tags = ["legacy"; "experimental"]; since = "1.5.2"; weight = 1146 };
  { key = "lectern.field.public_0375";                   label = "public_spawner_375";          arity = 7; tags = ["codegen"]; since = "1.8.3"; weight = 1568 };
  { key = "block.field.lazy_0376";                       label = "canonical_furnace_376";       arity = 1; tags = ["parse"; "cached"]; since = "1.2.0"; weight = 3788 };
  { key = "trade.field.local_0377";                      label = "strict_portal_377";           arity = 6; tags = ["registry"; "cached"; "packet"]; since = "1.8.3"; weight = 10 };
  { key = "smithing.field.primary_0378";                 label = "derived_biome_378";           arity = 5; tags = ["sync"; "compat"; "legacy"]; since = "1.2.0"; weight = 1087 };
  { key = "map.field.provisional_0379";                  label = "loose_attribute_379";         arity = 7; tags = ["runtime"; "untyped"; "parse"]; since = "1.7.0"; weight = 2111 };
  { key = "rail.field.local_0380";                       label = "derived_structure_380";       arity = 2; tags = ["legacy"; "runtime"]; since = "1.9.0"; weight = 2587 };
  { key = "structure.field.legacy_0381";                 label = "cached_item_381";             arity = 6; tags = ["cached"; "check"; "parse"]; since = "1.6.0"; weight = 1621 };
  { key = "gui.field.modern_0382";                       label = "local_arrow_382";             arity = 4; tags = ["experimental"; "async"]; since = "1.0.0"; weight = 886 };
  { key = "banner.field.scoped_0383";                    label = "internal_team_383";           arity = 1; tags = ["typed"; "content"]; since = "1.0.0"; weight = 1812 };
  { key = "villager.field.local_0384";                   label = "modern_stonecutter_384";      arity = 0; tags = ["content"]; since = "1.4.0"; weight = 1669 };
  { key = "bell.field.provisional_0385";                 label = "global_region_385";           arity = 5; tags = ["emit"]; since = "1.2.0"; weight = 548 };
  { key = "chunk.field.strict_0386";                     label = "loose_villager_386";          arity = 1; tags = ["hot"; "content"; "async"]; since = "1.2.0"; weight = 2325 };
  { key = "mob.field.eager_0387";                        label = "loose_potion_387";            arity = 2; tags = ["emit"; "async"; "check"]; since = "1.3.1"; weight = 867 };
  { key = "packet.field.stable_0388";                    label = "provisional_effect_388";      arity = 1; tags = ["packet"; "lower"]; since = "1.8.3"; weight = 2649 };
  { key = "cartography.field.provisional_0389";          label = "global_furnace_389";          arity = 1; tags = ["async"; "emit"]; since = "1.7.0"; weight = 2696 };
  { key = "packet.field.cached_0390";                    label = "legacy_objective_390";        arity = 6; tags = ["lower"]; since = "1.2.0"; weight = 2887 };
  { key = "villager.field.lazy_0391";                    label = "derived_pane_391";            arity = 4; tags = ["legacy"; "async"; "compat"]; since = "1.2.0"; weight = 2843 };
  { key = "dispenser.field.strict_0392";                 label = "hidden_compass_392";          arity = 6; tags = ["registry"; "typed"]; since = "1.0.0"; weight = 201 };
  { key = "player.field.lazy_0393";                      label = "public_minecart_393";         arity = 4; tags = ["typed"]; since = "1.2.0"; weight = 3782 };
  { key = "region.field.strict_0394";                    label = "primary_hologram_394";        arity = 5; tags = ["runtime"; "registry"]; since = "1.9.0"; weight = 4049 };
  { key = "dropper.field.scoped_0395";                   label = "secondary_block_395";         arity = 0; tags = ["lower"; "registry"]; since = "1.5.2"; weight = 1919 };
  { key = "anvil.field.primary_0396";                    label = "legacy_particle_396";         arity = 0; tags = ["registry"; "runtime"; "emit"]; since = "1.4.0"; weight = 117 };
  { key = "tablist.field.loose_0397";                    label = "fallback_structure_397";      arity = 3; tags = ["legacy"; "cached"; "parse"]; since = "1.7.0"; weight = 2623 };
  { key = "beacon.field.modern_0398";                    label = "derived_anvil_398";           arity = 5; tags = ["codegen"]; since = "1.8.3"; weight = 2058 };
  { key = "boat.field.hidden_0399";                      label = "internal_stonecutter_399";    arity = 2; tags = ["content"; "parse"]; since = "1.8.3"; weight = 1203 };
  { key = "beacon.field.public_0400";                    label = "global_beacon_400";           arity = 3; tags = ["core"]; since = "1.4.0"; weight = 1471 };
  { key = "banner_pattern.field.internal_0401";          label = "fallback_scoreboard_401";     arity = 2; tags = ["check"; "runtime"]; since = "1.9.0"; weight = 1411 };
  { key = "compass.field.local_0402";                    label = "eager_spawner_402";           arity = 2; tags = ["check"]; since = "1.2.0"; weight = 2292 };
  { key = "map.field.public_0403";                       label = "stable_arrow_403";            arity = 7; tags = ["packet"; "lower"; "check"]; since = "1.9.0"; weight = 3880 };
  { key = "block.field.lazy_0404";                       label = "loose_smithing_404";          arity = 7; tags = ["content"]; since = "1.7.0"; weight = 3942 };
  { key = "map.field.cached_0405";                       label = "local_anvil_405";             arity = 3; tags = ["async"; "legacy"; "codegen"]; since = "1.8.3"; weight = 3541 };
  { key = "dropper.field.hidden_0406";                   label = "global_composter_406";        arity = 6; tags = ["registry"]; since = "1.8.3"; weight = 1085 };
  { key = "loom.field.public_0407";                      label = "global_hopper_407";           arity = 1; tags = ["packet"; "runtime"]; since = "1.0.0"; weight = 3722 };
  { key = "cartography.field.strict_0408";               label = "hidden_banner_408";           arity = 6; tags = ["compat"; "check"]; since = "1.7.0"; weight = 1838 };
  { key = "rail.field.lazy_0409";                        label = "global_player_409";           arity = 0; tags = ["cold"; "compat"]; since = "1.0.0"; weight = 3508 };
  { key = "firework.field.strict_0410";                  label = "primary_region_410";          arity = 4; tags = ["registry"; "lower"; "emit"]; since = "1.2.0"; weight = 3459 };
  { key = "comparator.field.derived_0411";               label = "primary_recipe_411";          arity = 0; tags = ["runtime"; "cached"; "experimental"]; since = "1.9.0"; weight = 1174 };
  { key = "cartography.field.local_0412";                label = "secondary_composter_412";     arity = 0; tags = ["check"; "experimental"]; since = "1.3.1"; weight = 1878 };
]

let count = List.length entries

let table : (string, field_entry) Hashtbl.t =
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
