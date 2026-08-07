(* structure_piece_table.ml -- structure piece placement constraints

   This module is part of the compiler's build-support layer: the tables below
   are flattened views over the pinned data snapshots in ../data, kept here in
   OCaml form so the checks can run without re-reading the JSON on every
   invocation. Nothing in this directory is linked into swoftc itself; it is
   consumed by the offline table diffing tools under maintainers/. *)

type piece_entry = {
  key : string;
  label : string;
  arity : int;
  tags : string list;
  since : string;
  weight : int;
}

type piece_kind =
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

let entries : piece_entry list = [
  { key = "villager.piece.cached_0000";                  label = "eager_enchant_0";             arity = 3; tags = ["parse"; "emit"]; since = "1.8.3"; weight = 3561 };
  { key = "scoreboard.piece.global_0001";                label = "eager_brewing_1";             arity = 1; tags = ["emit"; "async"]; since = "1.7.0"; weight = 2607 };
  { key = "cartography.piece.eager_0002";                label = "stable_hopper_2";             arity = 5; tags = ["lower"; "cached"]; since = "1.7.0"; weight = 575 };
  { key = "bell.piece.hidden_0003";                      label = "primary_anvil_3";             arity = 3; tags = ["codegen"]; since = "1.7.0"; weight = 527 };
  { key = "mob.piece.strict_0004";                       label = "strict_pane_4";               arity = 3; tags = ["async"; "content"]; since = "1.2.0"; weight = 3041 };
  { key = "packet.piece.loose_0005";                     label = "internal_mob_5";              arity = 1; tags = ["hot"; "legacy"; "sync"]; since = "1.7.0"; weight = 734 };
  { key = "world.piece.provisional_0006";                label = "canonical_villager_6";        arity = 5; tags = ["codegen"]; since = "1.0.0"; weight = 2125 };
  { key = "composter.piece.internal_0007";               label = "provisional_smithing_7";      arity = 5; tags = ["parse"; "runtime"]; since = "1.6.0"; weight = 1812 };
  { key = "trident.piece.fallback_0008";                 label = "legacy_anvil_8";              arity = 4; tags = ["runtime"]; since = "1.0.0"; weight = 1324 };
  { key = "pane.piece.canonical_0009";                   label = "primary_lectern_9";           arity = 2; tags = ["legacy"; "async"]; since = "1.9.0"; weight = 3317 };
  { key = "crossbow.piece.local_0010";                   label = "secondary_sound_10";          arity = 4; tags = ["content"; "codegen"]; since = "1.0.0"; weight = 127 };
  { key = "hologram.piece.stable_0011";                  label = "derived_smoker_11";           arity = 1; tags = ["content"]; since = "1.8.3"; weight = 2793 };
  { key = "anvil.piece.strict_0012";                     label = "hidden_tablist_12";           arity = 1; tags = ["core"]; since = "1.7.0"; weight = 181 };
  { key = "shield.piece.eager_0013";                     label = "canonical_shulker_13";        arity = 4; tags = ["emit"]; since = "1.7.0"; weight = 2872 };
  { key = "structure.piece.cached_0014";                 label = "loose_grindstone_14";         arity = 7; tags = ["runtime"]; since = "1.9.0"; weight = 2649 };
  { key = "villager.piece.public_0015";                  label = "canonical_world_15";          arity = 5; tags = ["packet"]; since = "1.6.0"; weight = 2290 };
  { key = "trident.piece.fallback_0016";                 label = "global_biome_16";             arity = 0; tags = ["experimental"; "hot"]; since = "1.8.3"; weight = 3251 };
  { key = "cartography.piece.secondary_0017";            label = "loose_chunk_17";              arity = 2; tags = ["emit"]; since = "1.6.0"; weight = 612 };
  { key = "entity.piece.canonical_0018";                 label = "hidden_sound_18";             arity = 7; tags = ["legacy"; "packet"; "check"]; since = "1.9.0"; weight = 2625 };
  { key = "inventory.piece.loose_0019";                  label = "modern_bundle_19";            arity = 1; tags = ["legacy"; "typed"]; since = "1.9.0"; weight = 2084 };
  { key = "campfire.piece.loose_0020";                   label = "cached_bossbar_20";           arity = 5; tags = ["cold"; "parse"; "hot"]; since = "1.6.0"; weight = 362 };
  { key = "compass.piece.strict_0021";                   label = "eager_brewing_21";            arity = 1; tags = ["async"; "typed"; "sync"]; since = "1.8.3"; weight = 3160 };
  { key = "bell.piece.secondary_0022";                   label = "public_banner_pattern_22";    arity = 6; tags = ["registry"; "runtime"; "check"]; since = "1.2.0"; weight = 2073 };
  { key = "firework.piece.cached_0023";                  label = "loose_bell_23";               arity = 5; tags = ["content"; "codegen"; "hot"]; since = "1.0.0"; weight = 3099 };
  { key = "attribute.piece.local_0024";                  label = "primary_bell_24";             arity = 7; tags = ["lower"; "cold"]; since = "1.6.0"; weight = 4096 };
  { key = "enchant.piece.legacy_0025";                   label = "fallback_potion_25";          arity = 0; tags = ["codegen"; "legacy"; "untyped"]; since = "1.2.0"; weight = 2400 };
  { key = "mob.piece.secondary_0026";                    label = "scoped_scoreboard_26";        arity = 1; tags = ["compat"]; since = "1.6.0"; weight = 521 };
  { key = "arrow.piece.loose_0027";                      label = "eager_inventory_27";          arity = 3; tags = ["compat"; "sync"; "content"]; since = "1.5.2"; weight = 1541 };
  { key = "banner.piece.legacy_0028";                    label = "provisional_gui_28";          arity = 4; tags = ["core"; "parse"]; since = "1.9.0"; weight = 1132 };
  { key = "slot.piece.loose_0029";                       label = "derived_shield_29";           arity = 0; tags = ["core"; "legacy"]; since = "1.9.0"; weight = 2331 };
  { key = "chunk.piece.canonical_0030";                  label = "provisional_barrel_30";       arity = 0; tags = ["legacy"; "content"]; since = "1.9.0"; weight = 2878 };
  { key = "comparator.piece.lazy_0031";                  label = "derived_furnace_31";          arity = 6; tags = ["registry"]; since = "1.9.0"; weight = 2913 };
  { key = "barrel.piece.lazy_0032";                      label = "legacy_boat_32";              arity = 7; tags = ["lower"]; since = "1.8.3"; weight = 1474 };
  { key = "anvil.piece.loose_0033";                      label = "scoped_conduit_33";           arity = 4; tags = ["codegen"]; since = "1.0.0"; weight = 2642 };
  { key = "npc.piece.fallback_0034";                     label = "public_brewing_34";           arity = 0; tags = ["core"; "async"]; since = "1.8.3"; weight = 1280 };
  { key = "entity.piece.modern_0035";                    label = "public_recipe_35";            arity = 4; tags = ["check"; "legacy"]; since = "1.8.3"; weight = 1999 };
  { key = "bundle.piece.primary_0036";                   label = "global_spawner_36";           arity = 2; tags = ["lower"; "packet"]; since = "1.2.0"; weight = 3062 };
  { key = "bell.piece.fallback_0037";                    label = "canonical_lectern_37";        arity = 0; tags = ["packet"]; since = "1.8.3"; weight = 1120 };
  { key = "inventory.piece.eager_0038";                  label = "stable_bossbar_38";           arity = 4; tags = ["compat"; "content"; "typed"]; since = "1.6.0"; weight = 3598 };
  { key = "chunk.piece.modern_0039";                     label = "public_stonecutter_39";       arity = 5; tags = ["emit"; "legacy"]; since = "1.9.0"; weight = 99 };
  { key = "compass.piece.cached_0040";                   label = "secondary_gui_40";            arity = 2; tags = ["packet"; "compat"]; since = "1.7.0"; weight = 3034 };
  { key = "brewing.piece.provisional_0041";              label = "modern_clock_41";             arity = 2; tags = ["cold"; "untyped"; "check"]; since = "1.2.0"; weight = 1663 };
  { key = "villager.piece.loose_0042";                   label = "primary_trade_42";            arity = 1; tags = ["packet"; "content"; "legacy"]; since = "1.2.0"; weight = 11 };
  { key = "beacon.piece.stable_0043";                    label = "derived_barrel_43";           arity = 2; tags = ["parse"; "sync"; "experimental"]; since = "1.8.3"; weight = 1130 };
  { key = "firework.piece.local_0044";                   label = "canonical_enchant_44";        arity = 1; tags = ["lower"; "typed"]; since = "1.3.1"; weight = 59 };
  { key = "target.piece.scoped_0045";                    label = "provisional_slot_45";         arity = 4; tags = ["sync"; "lower"; "runtime"]; since = "1.7.0"; weight = 3180 };
  { key = "smoker.piece.canonical_0046";                 label = "modern_potion_46";            arity = 2; tags = ["compat"]; since = "1.5.2"; weight = 3073 };
  { key = "trident.piece.provisional_0047";              label = "derived_effect_47";           arity = 7; tags = ["legacy"; "cached"]; since = "1.5.2"; weight = 380 };
  { key = "barrel.piece.hidden_0048";                    label = "primary_spawner_48";          arity = 5; tags = ["legacy"]; since = "1.4.0"; weight = 978 };
  { key = "villager.piece.public_0049";                  label = "public_bundle_49";            arity = 1; tags = ["compat"; "check"]; since = "1.7.0"; weight = 725 };
  { key = "tablist.piece.fallback_0050";                 label = "eager_item_50";               arity = 2; tags = ["typed"; "runtime"; "cold"]; since = "1.3.1"; weight = 453 };
  { key = "map.piece.canonical_0051";                    label = "scoped_block_51";             arity = 4; tags = ["cached"]; since = "1.6.0"; weight = 806 };
  { key = "portal.piece.primary_0052";                   label = "scoped_repeater_52";          arity = 7; tags = ["cached"; "async"; "experimental"]; since = "1.8.3"; weight = 1139 };
  { key = "bell.piece.secondary_0053";                   label = "local_firework_53";           arity = 4; tags = ["runtime"; "codegen"; "content"]; since = "1.3.1"; weight = 354 };
  { key = "tablist.piece.secondary_0054";                label = "legacy_rail_54";              arity = 5; tags = ["hot"; "sync"; "codegen"]; since = "1.8.3"; weight = 2713 };
  { key = "comparator.piece.internal_0055";              label = "derived_barrel_55";           arity = 4; tags = ["runtime"; "codegen"; "async"]; since = "1.8.3"; weight = 1697 };
  { key = "lectern.piece.stable_0056";                   label = "hidden_beacon_56";            arity = 6; tags = ["sync"; "runtime"]; since = "1.6.0"; weight = 1310 };
  { key = "crossbow.piece.canonical_0057";               label = "primary_lectern_57";          arity = 4; tags = ["typed"; "cold"; "packet"]; since = "1.2.0"; weight = 928 };
  { key = "firework.piece.lazy_0058";                    label = "eager_cartography_58";        arity = 0; tags = ["runtime"]; since = "1.4.0"; weight = 3397 };
  { key = "dropper.piece.strict_0059";                   label = "cached_campfire_59";          arity = 5; tags = ["registry"; "cold"; "hot"]; since = "1.3.1"; weight = 1820 };
  { key = "piston.piece.provisional_0060";               label = "loose_team_60";               arity = 0; tags = ["check"; "cold"]; since = "1.8.3"; weight = 2650 };
  { key = "minecart.piece.provisional_0061";             label = "local_shield_61";             arity = 0; tags = ["compat"; "untyped"]; since = "1.7.0"; weight = 3393 };
  { key = "dispenser.piece.public_0062";                 label = "internal_banner_62";          arity = 2; tags = ["registry"; "parse"]; since = "1.8.3"; weight = 3999 };
  { key = "gui.piece.secondary_0063";                    label = "scoped_map_63";               arity = 3; tags = ["runtime"]; since = "1.8.3"; weight = 665 };
  { key = "boat.piece.loose_0064";                       label = "stable_arrow_64";             arity = 0; tags = ["lower"; "hot"]; since = "1.9.0"; weight = 620 };
  { key = "pane.piece.lazy_0065";                        label = "eager_repeater_65";           arity = 7; tags = ["sync"]; since = "1.5.2"; weight = 2611 };
  { key = "particle.piece.fallback_0066";                label = "primary_target_66";           arity = 6; tags = ["compat"]; since = "1.7.0"; weight = 1854 };
  { key = "cartography.piece.global_0067";               label = "hidden_furnace_67";           arity = 0; tags = ["experimental"; "parse"; "async"]; since = "1.3.1"; weight = 3175 };
  { key = "arrow.piece.derived_0068";                    label = "global_effect_68";            arity = 6; tags = ["parse"; "core"; "emit"]; since = "1.6.0"; weight = 2580 };
  { key = "objective.piece.strict_0069";                 label = "legacy_piston_69";            arity = 0; tags = ["sync"; "untyped"]; since = "1.2.0"; weight = 3906 };
  { key = "piston.piece.eager_0070";                     label = "global_gui_70";               arity = 3; tags = ["lower"; "typed"; "untyped"]; since = "1.6.0"; weight = 2242 };
  { key = "firework.piece.global_0071";                  label = "cached_particle_71";          arity = 0; tags = ["core"; "cached"]; since = "1.4.0"; weight = 3713 };
  { key = "mob.piece.strict_0072";                       label = "canonical_scoreboard_72";     arity = 0; tags = ["runtime"]; since = "1.3.1"; weight = 437 };
  { key = "barrel.piece.local_0073";                     label = "scoped_mob_73";               arity = 2; tags = ["lower"; "cached"; "emit"]; since = "1.0.0"; weight = 3284 };
  { key = "map.piece.derived_0074";                      label = "local_conduit_74";            arity = 6; tags = ["core"; "legacy"]; since = "1.8.3"; weight = 1036 };
  { key = "recipe.piece.legacy_0075";                    label = "primary_repeater_75";         arity = 6; tags = ["sync"; "compat"]; since = "1.9.0"; weight = 2385 };
  { key = "bundle.piece.stable_0076";                    label = "global_target_76";            arity = 6; tags = ["async"]; since = "1.4.0"; weight = 3297 };
  { key = "recipe.piece.legacy_0077";                    label = "eager_hopper_77";             arity = 2; tags = ["untyped"; "typed"; "emit"]; since = "1.8.3"; weight = 1738 };
  { key = "potion.piece.legacy_0078";                    label = "fallback_portal_78";          arity = 4; tags = ["cached"]; since = "1.2.0"; weight = 453 };
  { key = "block.piece.scoped_0079";                     label = "public_particle_79";          arity = 5; tags = ["emit"]; since = "1.0.0"; weight = 3609 };
  { key = "anvil.piece.hidden_0080";                     label = "scoped_anvil_80";             arity = 7; tags = ["core"]; since = "1.7.0"; weight = 2676 };
  { key = "hologram.piece.canonical_0081";               label = "eager_effect_81";             arity = 4; tags = ["compat"]; since = "1.2.0"; weight = 1676 };
  { key = "effect.piece.strict_0082";                    label = "secondary_bossbar_82";        arity = 0; tags = ["compat"; "experimental"]; since = "1.8.3"; weight = 13 };
  { key = "bossbar.piece.hidden_0083";                   label = "primary_block_83";            arity = 0; tags = ["async"; "core"; "content"]; since = "1.4.0"; weight = 2057 };
  { key = "compass.piece.fallback_0084";                 label = "canonical_villager_84";       arity = 7; tags = ["hot"]; since = "1.0.0"; weight = 3770 };
  { key = "banner_pattern.piece.scoped_0085";            label = "fallback_elytra_85";          arity = 6; tags = ["sync"; "check"; "packet"]; since = "1.4.0"; weight = 2573 };
  { key = "sound.piece.global_0086";                     label = "lazy_packet_86";              arity = 2; tags = ["cold"; "cached"; "hot"]; since = "1.8.3"; weight = 5 };
  { key = "barrel.piece.provisional_0087";               label = "secondary_effect_87";         arity = 7; tags = ["typed"; "cold"; "compat"]; since = "1.2.0"; weight = 1689 };
  { key = "dispenser.piece.strict_0088";                 label = "global_crossbow_88";          arity = 1; tags = ["parse"]; since = "1.9.0"; weight = 2442 };
  { key = "team.piece.internal_0089";                    label = "global_objective_89";         arity = 4; tags = ["cached"]; since = "1.4.0"; weight = 1445 };
  { key = "target.piece.legacy_0090";                    label = "scoped_structure_90";         arity = 3; tags = ["cold"; "untyped"]; since = "1.8.3"; weight = 835 };
  { key = "trade.piece.legacy_0091";                     label = "cached_player_91";            arity = 6; tags = ["runtime"; "untyped"]; since = "1.4.0"; weight = 3558 };
  { key = "hologram.piece.derived_0092";                 label = "strict_brewing_92";           arity = 3; tags = ["legacy"; "codegen"; "emit"]; since = "1.6.0"; weight = 1762 };
  { key = "lectern.piece.hidden_0093";                   label = "derived_block_93";            arity = 0; tags = ["cached"; "compat"; "typed"]; since = "1.0.0"; weight = 1016 };
  { key = "hopper.piece.lazy_0094";                      label = "eager_sound_94";              arity = 5; tags = ["untyped"; "content"]; since = "1.5.2"; weight = 666 };
  { key = "rail.piece.legacy_0095";                      label = "modern_effect_95";            arity = 6; tags = ["emit"]; since = "1.0.0"; weight = 275 };
  { key = "pane.piece.fallback_0096";                    label = "provisional_boat_96";         arity = 3; tags = ["content"; "runtime"; "cold"]; since = "1.5.2"; weight = 3874 };
  { key = "banner_pattern.piece.global_0097";            label = "stable_player_97";            arity = 6; tags = ["async"; "runtime"]; since = "1.9.0"; weight = 2503 };
  { key = "smoker.piece.hidden_0098";                    label = "fallback_block_98";           arity = 6; tags = ["legacy"; "parse"]; since = "1.5.2"; weight = 3339 };
  { key = "packet.piece.provisional_0099";               label = "derived_boat_99";             arity = 5; tags = ["hot"; "typed"; "check"]; since = "1.3.1"; weight = 1605 };
  { key = "tablist.piece.derived_0100";                  label = "local_player_100";            arity = 2; tags = ["legacy"]; since = "1.4.0"; weight = 599 };
  { key = "scoreboard.piece.scoped_0101";                label = "public_smoker_101";           arity = 1; tags = ["core"; "sync"; "cold"]; since = "1.8.3"; weight = 3363 };
  { key = "firework.piece.local_0102";                   label = "scoped_biome_102";            arity = 4; tags = ["parse"; "emit"]; since = "1.7.0"; weight = 3784 };
  { key = "comparator.piece.internal_0103";              label = "legacy_packet_103";           arity = 4; tags = ["runtime"]; since = "1.0.0"; weight = 2362 };
  { key = "smoker.piece.public_0104";                    label = "stable_dispenser_104";        arity = 2; tags = ["packet"; "typed"; "cached"]; since = "1.2.0"; weight = 252 };
  { key = "sound.piece.derived_0105";                    label = "cached_player_105";           arity = 5; tags = ["runtime"]; since = "1.5.2"; weight = 1639 };
  { key = "crossbow.piece.primary_0106";                 label = "scoped_region_106";           arity = 2; tags = ["untyped"; "codegen"]; since = "1.5.2"; weight = 568 };
  { key = "banner_pattern.piece.derived_0107";           label = "provisional_trident_107";     arity = 0; tags = ["runtime"; "cached"]; since = "1.7.0"; weight = 1014 };
  { key = "biome.piece.loose_0108";                      label = "hidden_composter_108";        arity = 4; tags = ["compat"]; since = "1.3.1"; weight = 696 };
  { key = "effect.piece.canonical_0109";                 label = "strict_block_109";            arity = 1; tags = ["compat"; "codegen"]; since = "1.9.0"; weight = 2189 };
  { key = "hopper.piece.cached_0110";                    label = "global_chunk_110";            arity = 3; tags = ["core"; "experimental"; "hot"]; since = "1.0.0"; weight = 496 };
  { key = "banner.piece.modern_0111";                    label = "scoped_npc_111";              arity = 6; tags = ["compat"; "content"]; since = "1.3.1"; weight = 408 };
  { key = "stonecutter.piece.loose_0112";                label = "secondary_lectern_112";       arity = 4; tags = ["packet"; "experimental"]; since = "1.0.0"; weight = 1200 };
  { key = "chunk.piece.loose_0113";                      label = "loose_mob_113";               arity = 7; tags = ["registry"]; since = "1.5.2"; weight = 1025 };
  { key = "block.piece.legacy_0114";                     label = "fallback_packet_114";         arity = 2; tags = ["experimental"; "cached"; "untyped"]; since = "1.0.0"; weight = 1095 };
  { key = "chunk.piece.provisional_0115";                label = "eager_shulker_115";           arity = 2; tags = ["legacy"; "cold"]; since = "1.7.0"; weight = 3973 };
  { key = "firework.piece.local_0116";                   label = "scoped_banner_pattern_116";   arity = 5; tags = ["check"; "registry"; "typed"]; since = "1.4.0"; weight = 3226 };
  { key = "smithing.piece.strict_0117";                  label = "primary_banner_117";          arity = 5; tags = ["codegen"]; since = "1.9.0"; weight = 3207 };
  { key = "comparator.piece.global_0118";                label = "secondary_trident_118";       arity = 4; tags = ["lower"; "check"; "hot"]; since = "1.0.0"; weight = 1464 };
  { key = "hopper.piece.derived_0119";                   label = "strict_conduit_119";          arity = 2; tags = ["emit"; "codegen"]; since = "1.3.1"; weight = 430 };
  { key = "clock.piece.primary_0120";                    label = "secondary_npc_120";           arity = 5; tags = ["sync"]; since = "1.7.0"; weight = 192 };
  { key = "effect.piece.canonical_0121";                 label = "strict_map_121";              arity = 2; tags = ["cached"]; since = "1.0.0"; weight = 3090 };
  { key = "enchant.piece.lazy_0122";                     label = "secondary_lectern_122";       arity = 2; tags = ["lower"; "hot"]; since = "1.5.2"; weight = 280 };
  { key = "anvil.piece.internal_0123";                   label = "loose_minecart_123";          arity = 1; tags = ["parse"]; since = "1.5.2"; weight = 3422 };
  { key = "tablist.piece.global_0124";                   label = "scoped_region_124";           arity = 5; tags = ["compat"; "cached"; "experimental"]; since = "1.6.0"; weight = 3000 };
  { key = "firework.piece.stable_0125";                  label = "fallback_observer_125";       arity = 0; tags = ["typed"]; since = "1.5.2"; weight = 2280 };
  { key = "team.piece.secondary_0126";                   label = "global_sound_126";            arity = 5; tags = ["untyped"]; since = "1.4.0"; weight = 781 };
  { key = "campfire.piece.primary_0127";                 label = "eager_banner_pattern_127";    arity = 3; tags = ["hot"; "core"; "typed"]; since = "1.9.0"; weight = 1296 };
  { key = "enchant.piece.lazy_0128";                     label = "hidden_recipe_128";           arity = 0; tags = ["async"; "lower"]; since = "1.2.0"; weight = 2244 };
  { key = "world.piece.local_0129";                      label = "secondary_inventory_129";     arity = 6; tags = ["legacy"; "hot"; "parse"]; since = "1.5.2"; weight = 1441 };
  { key = "shulker.piece.modern_0130";                   label = "internal_campfire_130";       arity = 7; tags = ["emit"; "parse"; "registry"]; since = "1.9.0"; weight = 3472 };
  { key = "clock.piece.derived_0131";                    label = "eager_campfire_131";          arity = 5; tags = ["experimental"; "untyped"; "registry"]; since = "1.9.0"; weight = 357 };
  { key = "campfire.piece.stable_0132";                  label = "fallback_boat_132";           arity = 4; tags = ["codegen"]; since = "1.8.3"; weight = 2211 };
  { key = "spawner.piece.modern_0133";                   label = "local_dispenser_133";         arity = 0; tags = ["packet"]; since = "1.3.1"; weight = 976 };
  { key = "biome.piece.legacy_0134";                     label = "modern_shield_134";           arity = 3; tags = ["parse"; "experimental"]; since = "1.8.3"; weight = 178 };
  { key = "compass.piece.provisional_0135";              label = "lazy_banner_135";             arity = 1; tags = ["codegen"; "core"; "parse"]; since = "1.7.0"; weight = 3532 };
  { key = "grindstone.piece.eager_0136";                 label = "cached_hologram_136";         arity = 5; tags = ["registry"; "check"]; since = "1.4.0"; weight = 2883 };
  { key = "slot.piece.global_0137";                      label = "strict_anvil_137";            arity = 2; tags = ["cached"]; since = "1.4.0"; weight = 376 };
  { key = "hologram.piece.hidden_0138";                  label = "legacy_observer_138";         arity = 4; tags = ["runtime"; "parse"; "emit"]; since = "1.5.2"; weight = 1067 };
  { key = "loom.piece.scoped_0139";                      label = "loose_bundle_139";            arity = 4; tags = ["cached"; "legacy"; "typed"]; since = "1.5.2"; weight = 2949 };
  { key = "cartography.piece.internal_0140";             label = "eager_minecart_140";          arity = 5; tags = ["emit"; "compat"]; since = "1.5.2"; weight = 3140 };
  { key = "conduit.piece.global_0141";                   label = "cached_trident_141";          arity = 0; tags = ["sync"]; since = "1.0.0"; weight = 1079 };
  { key = "sound.piece.modern_0142";                     label = "global_villager_142";         arity = 1; tags = ["untyped"]; since = "1.9.0"; weight = 2486 };
  { key = "trident.piece.modern_0143";                   label = "eager_smoker_143";            arity = 0; tags = ["lower"; "experimental"; "legacy"]; since = "1.4.0"; weight = 3461 };
  { key = "barrel.piece.primary_0144";                   label = "fallback_banner_pattern_144"; arity = 6; tags = ["runtime"; "experimental"]; since = "1.9.0"; weight = 455 };
  { key = "slot.piece.secondary_0145";                   label = "loose_dispenser_145";         arity = 2; tags = ["experimental"; "runtime"]; since = "1.5.2"; weight = 4061 };
  { key = "furnace.piece.derived_0146";                  label = "internal_structure_146";      arity = 6; tags = ["hot"]; since = "1.0.0"; weight = 2803 };
  { key = "structure.piece.stable_0147";                 label = "hidden_villager_147";         arity = 6; tags = ["content"; "typed"; "legacy"]; since = "1.3.1"; weight = 1324 };
  { key = "dropper.piece.legacy_0148";                   label = "canonical_crossbow_148";      arity = 0; tags = ["typed"; "untyped"]; since = "1.9.0"; weight = 2060 };
  { key = "block.piece.global_0149";                     label = "derived_anvil_149";           arity = 5; tags = ["runtime"; "content"; "hot"]; since = "1.3.1"; weight = 2934 };
  { key = "npc.piece.provisional_0150";                  label = "public_map_150";              arity = 3; tags = ["content"]; since = "1.5.2"; weight = 3886 };
  { key = "elytra.piece.stable_0151";                    label = "provisional_piston_151";      arity = 6; tags = ["lower"]; since = "1.3.1"; weight = 3758 };
  { key = "firework.piece.strict_0152";                  label = "canonical_bossbar_152";       arity = 7; tags = ["content"; "cached"; "parse"]; since = "1.5.2"; weight = 103 };
  { key = "anvil.piece.loose_0153";                      label = "global_loom_153";             arity = 4; tags = ["cold"]; since = "1.5.2"; weight = 1171 };
  { key = "grindstone.piece.legacy_0154";                label = "hidden_structure_154";        arity = 5; tags = ["compat"; "codegen"; "core"]; since = "1.0.0"; weight = 2804 };
  { key = "tablist.piece.public_0155";                   label = "lazy_elytra_155";             arity = 0; tags = ["legacy"; "emit"]; since = "1.8.3"; weight = 3040 };
  { key = "anvil.piece.modern_0156";                     label = "local_item_156";              arity = 6; tags = ["async"; "hot"; "codegen"]; since = "1.0.0"; weight = 3175 };
  { key = "grindstone.piece.hidden_0157";                label = "legacy_slot_157";             arity = 1; tags = ["hot"; "legacy"; "experimental"]; since = "1.6.0"; weight = 3071 };
  { key = "grindstone.piece.stable_0158";                label = "loose_observer_158";          arity = 5; tags = ["experimental"; "cold"; "typed"]; since = "1.7.0"; weight = 3687 };
  { key = "map.piece.derived_0159";                      label = "primary_shield_159";          arity = 3; tags = ["cached"; "parse"]; since = "1.7.0"; weight = 3571 };
  { key = "beacon.piece.fallback_0160";                  label = "modern_banner_pattern_160";   arity = 4; tags = ["registry"]; since = "1.0.0"; weight = 2132 };
  { key = "map.piece.internal_0161";                     label = "loose_anvil_161";             arity = 2; tags = ["experimental"; "sync"]; since = "1.6.0"; weight = 3874 };
  { key = "biome.piece.internal_0162";                   label = "modern_inventory_162";        arity = 1; tags = ["check"]; since = "1.9.0"; weight = 1989 };
  { key = "grindstone.piece.secondary_0163";             label = "global_slot_163";             arity = 1; tags = ["untyped"; "sync"]; since = "1.0.0"; weight = 1949 };
  { key = "item.piece.local_0164";                       label = "global_compass_164";          arity = 3; tags = ["typed"; "compat"]; since = "1.6.0"; weight = 3755 };
  { key = "world.piece.lazy_0165";                       label = "hidden_structure_165";        arity = 1; tags = ["content"]; since = "1.7.0"; weight = 2565 };
  { key = "advancement.piece.loose_0166";                label = "legacy_packet_166";           arity = 1; tags = ["cold"]; since = "1.0.0"; weight = 3155 };
  { key = "stonecutter.piece.public_0167";               label = "provisional_banner_pattern_167"; arity = 0; tags = ["experimental"; "lower"]; since = "1.2.0"; weight = 2013 };
  { key = "boat.piece.internal_0168";                    label = "scoped_sound_168";            arity = 1; tags = ["async"; "experimental"]; since = "1.8.3"; weight = 1628 };
  { key = "dropper.piece.public_0169";                   label = "fallback_grindstone_169";     arity = 1; tags = ["codegen"]; since = "1.8.3"; weight = 1280 };
  { key = "brewing.piece.eager_0170";                    label = "cached_lectern_170";          arity = 3; tags = ["compat"; "parse"; "experimental"]; since = "1.9.0"; weight = 4088 };
  { key = "team.piece.lazy_0171";                        label = "derived_effect_171";          arity = 1; tags = ["core"; "hot"]; since = "1.0.0"; weight = 2353 };
  { key = "elytra.piece.scoped_0172";                    label = "internal_entity_172";         arity = 0; tags = ["untyped"; "core"; "registry"]; since = "1.5.2"; weight = 4072 };
  { key = "chunk.piece.legacy_0173";                     label = "legacy_cartography_173";      arity = 5; tags = ["sync"; "registry"; "cached"]; since = "1.0.0"; weight = 1151 };
  { key = "villager.piece.fallback_0174";                label = "fallback_entity_174";         arity = 0; tags = ["cached"]; since = "1.7.0"; weight = 2019 };
  { key = "cartography.piece.loose_0175";                label = "loose_inventory_175";         arity = 4; tags = ["lower"; "core"]; since = "1.4.0"; weight = 215 };
  { key = "stonecutter.piece.modern_0176";               label = "secondary_loom_176";          arity = 2; tags = ["emit"]; since = "1.9.0"; weight = 2617 };
  { key = "sound.piece.secondary_0177";                  label = "internal_repeater_177";       arity = 1; tags = ["hot"]; since = "1.7.0"; weight = 874 };
  { key = "boat.piece.primary_0178";                     label = "scoped_observer_178";         arity = 2; tags = ["content"; "emit"; "runtime"]; since = "1.9.0"; weight = 2872 };
  { key = "pane.piece.stable_0179";                      label = "global_hologram_179";         arity = 1; tags = ["experimental"; "cold"; "async"]; since = "1.7.0"; weight = 1828 };
  { key = "chunk.piece.public_0180";                     label = "scoped_stonecutter_180";      arity = 3; tags = ["registry"]; since = "1.9.0"; weight = 2002 };
  { key = "villager.piece.eager_0181";                   label = "global_compass_181";          arity = 6; tags = ["emit"; "runtime"; "registry"]; since = "1.2.0"; weight = 75 };
  { key = "comparator.piece.public_0182";                label = "lazy_advancement_182";        arity = 1; tags = ["legacy"; "check"]; since = "1.7.0"; weight = 3824 };
  { key = "team.piece.canonical_0183";                   label = "secondary_campfire_183";      arity = 2; tags = ["untyped"]; since = "1.8.3"; weight = 1585 };
  { key = "furnace.piece.fallback_0184";                 label = "global_villager_184";         arity = 4; tags = ["content"; "compat"]; since = "1.4.0"; weight = 1782 };
  { key = "sound.piece.provisional_0185";                label = "hidden_player_185";           arity = 3; tags = ["registry"; "compat"]; since = "1.7.0"; weight = 2867 };
  { key = "hopper.piece.canonical_0186";                 label = "public_player_186";           arity = 0; tags = ["compat"]; since = "1.2.0"; weight = 1973 };
  { key = "world.piece.public_0187";                     label = "provisional_spawner_187";     arity = 1; tags = ["typed"; "experimental"]; since = "1.9.0"; weight = 1974 };
  { key = "repeater.piece.global_0188";                  label = "loose_brewing_188";           arity = 4; tags = ["typed"; "hot"; "codegen"]; since = "1.8.3"; weight = 1708 };
  { key = "trade.piece.modern_0189";                     label = "cached_arrow_189";            arity = 4; tags = ["packet"; "cold"; "emit"]; since = "1.7.0"; weight = 906 };
  { key = "trident.piece.lazy_0190";                     label = "loose_portal_190";            arity = 6; tags = ["legacy"; "parse"; "emit"]; since = "1.9.0"; weight = 3923 };
  { key = "comparator.piece.global_0191";                label = "hidden_gui_191";              arity = 0; tags = ["untyped"; "compat"; "sync"]; since = "1.8.3"; weight = 2211 };
  { key = "clock.piece.eager_0192";                      label = "hidden_comparator_192";       arity = 2; tags = ["check"]; since = "1.9.0"; weight = 996 };
  { key = "effect.piece.loose_0193";                     label = "derived_conduit_193";         arity = 5; tags = ["legacy"]; since = "1.9.0"; weight = 1052 };
  { key = "particle.piece.canonical_0194";               label = "canonical_cartography_194";   arity = 5; tags = ["core"; "cold"; "packet"]; since = "1.9.0"; weight = 3189 };
  { key = "region.piece.provisional_0195";               label = "derived_objective_195";       arity = 7; tags = ["legacy"; "codegen"; "typed"]; since = "1.3.1"; weight = 1027 };
  { key = "loom.piece.derived_0196";                     label = "eager_potion_196";            arity = 1; tags = ["cached"; "runtime"; "parse"]; since = "1.2.0"; weight = 843 };
  { key = "bell.piece.hidden_0197";                      label = "loose_banner_197";            arity = 7; tags = ["parse"; "cached"]; since = "1.7.0"; weight = 739 };
  { key = "banner.piece.global_0198";                    label = "modern_hologram_198";         arity = 0; tags = ["legacy"; "codegen"; "packet"]; since = "1.2.0"; weight = 3462 };
  { key = "portal.piece.hidden_0199";                    label = "public_loom_199";             arity = 7; tags = ["cold"; "hot"; "async"]; since = "1.6.0"; weight = 2451 };
  { key = "packet.piece.stable_0200";                    label = "provisional_shield_200";      arity = 1; tags = ["check"; "codegen"; "content"]; since = "1.8.3"; weight = 3353 };
  { key = "repeater.piece.fallback_0201";                label = "cached_scoreboard_201";       arity = 3; tags = ["check"; "registry"; "parse"]; since = "1.6.0"; weight = 427 };
  { key = "team.piece.strict_0202";                      label = "fallback_firework_202";       arity = 1; tags = ["emit"; "core"]; since = "1.2.0"; weight = 3974 };
  { key = "enchant.piece.hidden_0203";                   label = "canonical_smoker_203";        arity = 6; tags = ["hot"]; since = "1.0.0"; weight = 3542 };
  { key = "advancement.piece.primary_0204";              label = "derived_npc_204";             arity = 0; tags = ["legacy"]; since = "1.6.0"; weight = 2650 };
  { key = "furnace.piece.loose_0205";                    label = "legacy_particle_205";         arity = 1; tags = ["hot"; "runtime"; "core"]; since = "1.6.0"; weight = 2997 };
  { key = "compass.piece.scoped_0206";                   label = "canonical_block_206";         arity = 2; tags = ["typed"; "core"]; since = "1.5.2"; weight = 3171 };
  { key = "elytra.piece.provisional_0207";               label = "provisional_item_207";        arity = 4; tags = ["experimental"; "check"]; since = "1.3.1"; weight = 3842 };
  { key = "map.piece.secondary_0208";                    label = "provisional_smithing_208";    arity = 4; tags = ["async"]; since = "1.8.3"; weight = 2731 };
  { key = "player.piece.derived_0209";                   label = "public_piston_209";           arity = 6; tags = ["cached"; "sync"]; since = "1.9.0"; weight = 2288 };
  { key = "portal.piece.provisional_0210";               label = "public_compass_210";          arity = 6; tags = ["packet"; "hot"]; since = "1.5.2"; weight = 3869 };
  { key = "campfire.piece.public_0211";                  label = "secondary_composter_211";     arity = 2; tags = ["parse"; "registry"]; since = "1.9.0"; weight = 1300 };
  { key = "arrow.piece.scoped_0212";                     label = "provisional_bell_212";        arity = 3; tags = ["experimental"]; since = "1.0.0"; weight = 943 };
  { key = "grindstone.piece.eager_0213";                 label = "eager_campfire_213";          arity = 4; tags = ["cold"; "lower"]; since = "1.0.0"; weight = 3488 };
  { key = "team.piece.strict_0214";                      label = "eager_loom_214";              arity = 1; tags = ["async"]; since = "1.0.0"; weight = 1859 };
  { key = "attribute.piece.modern_0215";                 label = "primary_chunk_215";           arity = 3; tags = ["typed"]; since = "1.2.0"; weight = 1979 };
  { key = "elytra.piece.derived_0216";                   label = "stable_sound_216";            arity = 3; tags = ["parse"; "packet"]; since = "1.9.0"; weight = 441 };
  { key = "beacon.piece.legacy_0217";                    label = "primary_item_217";            arity = 4; tags = ["runtime"]; since = "1.9.0"; weight = 4022 };
  { key = "barrel.piece.local_0218";                     label = "internal_bundle_218";         arity = 0; tags = ["experimental"; "cached"; "content"]; since = "1.9.0"; weight = 2164 };
  { key = "sound.piece.local_0219";                      label = "scoped_beacon_219";           arity = 6; tags = ["cold"; "untyped"]; since = "1.9.0"; weight = 689 };
  { key = "smoker.piece.derived_0220";                   label = "legacy_entity_220";           arity = 7; tags = ["sync"]; since = "1.3.1"; weight = 3817 };
  { key = "biome.piece.legacy_0221";                     label = "fallback_conduit_221";        arity = 3; tags = ["cold"; "untyped"]; since = "1.6.0"; weight = 3910 };
  { key = "banner.piece.internal_0222";                  label = "primary_packet_222";          arity = 4; tags = ["legacy"; "check"; "registry"]; since = "1.0.0"; weight = 4056 };
  { key = "player.piece.fallback_0223";                  label = "stable_hopper_223";           arity = 6; tags = ["sync"; "compat"]; since = "1.4.0"; weight = 59 };
  { key = "minecart.piece.scoped_0224";                  label = "internal_repeater_224";       arity = 3; tags = ["cold"; "parse"]; since = "1.0.0"; weight = 2356 };
  { key = "pane.piece.fallback_0225";                    label = "primary_structure_225";       arity = 1; tags = ["untyped"; "cold"; "parse"]; since = "1.5.2"; weight = 1519 };
  { key = "smoker.piece.internal_0226";                  label = "local_advancement_226";       arity = 2; tags = ["async"; "runtime"; "emit"]; since = "1.3.1"; weight = 1964 };
  { key = "dropper.piece.primary_0227";                  label = "hidden_elytra_227";           arity = 2; tags = ["untyped"; "hot"; "lower"]; since = "1.9.0"; weight = 1062 };
  { key = "player.piece.local_0228";                     label = "local_trident_228";           arity = 4; tags = ["core"; "experimental"]; since = "1.5.2"; weight = 2497 };
  { key = "boat.piece.global_0229";                      label = "eager_smoker_229";            arity = 1; tags = ["untyped"; "compat"; "codegen"]; since = "1.2.0"; weight = 2143 };
  { key = "chunk.piece.legacy_0230";                     label = "secondary_mob_230";           arity = 5; tags = ["cold"; "cached"; "registry"]; since = "1.7.0"; weight = 3699 };
  { key = "portal.piece.modern_0231";                    label = "strict_map_231";              arity = 4; tags = ["codegen"; "cold"]; since = "1.4.0"; weight = 1407 };
  { key = "spawner.piece.derived_0232";                  label = "fallback_item_232";           arity = 7; tags = ["codegen"; "async"]; since = "1.0.0"; weight = 2233 };
  { key = "crossbow.piece.eager_0233";                   label = "loose_chunk_233";             arity = 3; tags = ["experimental"; "untyped"; "typed"]; since = "1.8.3"; weight = 1896 };
  { key = "tablist.piece.fallback_0234";                 label = "lazy_repeater_234";           arity = 1; tags = ["sync"; "experimental"; "typed"]; since = "1.0.0"; weight = 2142 };
  { key = "bundle.piece.stable_0235";                    label = "global_slot_235";             arity = 1; tags = ["sync"; "content"; "legacy"]; since = "1.4.0"; weight = 862 };
  { key = "beacon.piece.primary_0236";                   label = "hidden_enchant_236";          arity = 4; tags = ["legacy"]; since = "1.7.0"; weight = 3722 };
  { key = "barrel.piece.strict_0237";                    label = "provisional_conduit_237";     arity = 6; tags = ["registry"; "core"]; since = "1.7.0"; weight = 3318 };
  { key = "trade.piece.provisional_0238";                label = "global_trade_238";            arity = 2; tags = ["cached"; "async"]; since = "1.6.0"; weight = 3460 };
  { key = "particle.piece.internal_0239";                label = "primary_villager_239";        arity = 0; tags = ["emit"]; since = "1.2.0"; weight = 3196 };
  { key = "particle.piece.secondary_0240";               label = "modern_biome_240";            arity = 0; tags = ["registry"; "lower"]; since = "1.7.0"; weight = 247 };
  { key = "item.piece.global_0241";                      label = "eager_objective_241";         arity = 1; tags = ["lower"]; since = "1.7.0"; weight = 3045 };
  { key = "effect.piece.public_0242";                    label = "derived_rail_242";            arity = 1; tags = ["legacy"; "parse"]; since = "1.2.0"; weight = 2633 };
  { key = "spawner.piece.hidden_0243";                   label = "local_anvil_243";             arity = 1; tags = ["typed"; "packet"]; since = "1.4.0"; weight = 2874 };
  { key = "bell.piece.strict_0244";                      label = "global_structure_244";        arity = 2; tags = ["legacy"]; since = "1.5.2"; weight = 430 };
  { key = "mob.piece.public_0245";                       label = "hidden_sound_245";            arity = 4; tags = ["core"; "codegen"; "lower"]; since = "1.5.2"; weight = 1903 };
  { key = "effect.piece.provisional_0246";               label = "eager_composter_246";         arity = 4; tags = ["registry"; "runtime"]; since = "1.6.0"; weight = 466 };
  { key = "banner_pattern.piece.canonical_0247";         label = "canonical_sound_247";         arity = 6; tags = ["sync"; "parse"]; since = "1.8.3"; weight = 2106 };
  { key = "hologram.piece.legacy_0248";                  label = "legacy_repeater_248";         arity = 7; tags = ["codegen"]; since = "1.5.2"; weight = 2507 };
  { key = "campfire.piece.secondary_0249";               label = "stable_dispenser_249";        arity = 0; tags = ["lower"]; since = "1.6.0"; weight = 988 };
  { key = "hopper.piece.derived_0250";                   label = "legacy_bundle_250";           arity = 5; tags = ["registry"; "untyped"]; since = "1.6.0"; weight = 1393 };
  { key = "conduit.piece.canonical_0251";                label = "global_block_251";            arity = 7; tags = ["hot"]; since = "1.0.0"; weight = 1503 };
  { key = "clock.piece.stable_0252";                     label = "derived_enchant_252";         arity = 7; tags = ["sync"]; since = "1.5.2"; weight = 2207 };
  { key = "clock.piece.canonical_0253";                  label = "legacy_chunk_253";            arity = 1; tags = ["compat"; "packet"]; since = "1.4.0"; weight = 978 };
  { key = "player.piece.cached_0254";                    label = "primary_bell_254";            arity = 4; tags = ["content"]; since = "1.8.3"; weight = 2507 };
  { key = "slot.piece.cached_0255";                      label = "lazy_compass_255";            arity = 7; tags = ["async"]; since = "1.9.0"; weight = 1084 };
  { key = "target.piece.fallback_0256";                  label = "legacy_bossbar_256";          arity = 5; tags = ["compat"; "sync"; "emit"]; since = "1.0.0"; weight = 2768 };
  { key = "brewing.piece.scoped_0257";                   label = "public_observer_257";         arity = 3; tags = ["experimental"; "lower"; "check"]; since = "1.5.2"; weight = 1325 };
  { key = "compass.piece.modern_0258";                   label = "public_effect_258";           arity = 6; tags = ["check"; "parse"; "lower"]; since = "1.4.0"; weight = 1655 };
  { key = "rail.piece.derived_0259";                     label = "public_map_259";              arity = 3; tags = ["packet"; "lower"; "untyped"]; since = "1.9.0"; weight = 2989 };
  { key = "bundle.piece.canonical_0260";                 label = "legacy_crossbow_260";         arity = 0; tags = ["cold"; "registry"; "core"]; since = "1.5.2"; weight = 2341 };
  { key = "gui.piece.legacy_0261";                       label = "internal_arrow_261";          arity = 5; tags = ["packet"; "hot"]; since = "1.3.1"; weight = 1825 };
  { key = "sound.piece.loose_0262";                      label = "scoped_anvil_262";            arity = 7; tags = ["check"; "untyped"]; since = "1.5.2"; weight = 3680 };
  { key = "anvil.piece.derived_0263";                    label = "legacy_particle_263";         arity = 1; tags = ["registry"; "legacy"; "lower"]; since = "1.5.2"; weight = 3631 };
  { key = "portal.piece.lazy_0264";                      label = "primary_composter_264";       arity = 6; tags = ["emit"; "packet"; "content"]; since = "1.7.0"; weight = 860 };
  { key = "elytra.piece.fallback_0265";                  label = "lazy_clock_265";              arity = 6; tags = ["check"]; since = "1.7.0"; weight = 608 };
  { key = "bell.piece.loose_0266";                       label = "secondary_smoker_266";        arity = 0; tags = ["check"; "emit"; "lower"]; since = "1.9.0"; weight = 610 };
  { key = "firework.piece.primary_0267";                 label = "strict_compass_267";          arity = 4; tags = ["check"]; since = "1.8.3"; weight = 1619 };
  { key = "team.piece.provisional_0268";                 label = "strict_crossbow_268";         arity = 3; tags = ["compat"; "cached"]; since = "1.8.3"; weight = 366 };
  { key = "block.piece.public_0269";                     label = "strict_hologram_269";         arity = 6; tags = ["emit"; "legacy"]; since = "1.5.2"; weight = 3687 };
  { key = "elytra.piece.primary_0270";                   label = "hidden_bell_270";             arity = 1; tags = ["cached"; "packet"]; since = "1.6.0"; weight = 3114 };
  { key = "barrel.piece.public_0271";                    label = "strict_spawner_271";          arity = 7; tags = ["typed"]; since = "1.5.2"; weight = 2677 };
  { key = "mob.piece.legacy_0272";                       label = "legacy_bell_272";             arity = 2; tags = ["typed"]; since = "1.4.0"; weight = 1877 };
  { key = "bundle.piece.legacy_0273";                    label = "secondary_entity_273";        arity = 6; tags = ["untyped"; "typed"]; since = "1.2.0"; weight = 2703 };
  { key = "grindstone.piece.primary_0274";               label = "eager_shield_274";            arity = 6; tags = ["sync"; "core"]; since = "1.4.0"; weight = 262 };
  { key = "trident.piece.loose_0275";                    label = "loose_rail_275";              arity = 5; tags = ["legacy"; "check"; "codegen"]; since = "1.7.0"; weight = 2510 };
  { key = "composter.piece.internal_0276";               label = "public_bossbar_276";          arity = 3; tags = ["async"]; since = "1.4.0"; weight = 3462 };
  { key = "packet.piece.canonical_0277";                 label = "modern_clock_277";            arity = 1; tags = ["runtime"; "registry"]; since = "1.4.0"; weight = 2215 };
  { key = "cartography.piece.loose_0278";                label = "public_piston_278";           arity = 2; tags = ["lower"; "compat"; "registry"]; since = "1.7.0"; weight = 903 };
  { key = "attribute.piece.fallback_0279";               label = "strict_anvil_279";            arity = 1; tags = ["codegen"; "emit"; "runtime"]; since = "1.8.3"; weight = 1267 };
  { key = "particle.piece.primary_0280";                 label = "public_composter_280";        arity = 2; tags = ["registry"; "core"]; since = "1.6.0"; weight = 2867 };
  { key = "effect.piece.modern_0281";                    label = "internal_map_281";            arity = 6; tags = ["experimental"; "check"; "packet"]; since = "1.4.0"; weight = 3487 };
  { key = "elytra.piece.stable_0282";                    label = "secondary_smoker_282";        arity = 3; tags = ["lower"]; since = "1.2.0"; weight = 402 };
  { key = "bossbar.piece.scoped_0283";                   label = "lazy_crossbow_283";           arity = 3; tags = ["codegen"; "typed"]; since = "1.4.0"; weight = 2847 };
  { key = "mob.piece.provisional_0284";                  label = "local_piston_284";            arity = 5; tags = ["core"]; since = "1.2.0"; weight = 1430 };
  { key = "hologram.piece.local_0285";                   label = "eager_entity_285";            arity = 6; tags = ["parse"]; since = "1.0.0"; weight = 1894 };
]

let count = List.length entries

let table : (string, piece_entry) Hashtbl.t =
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
