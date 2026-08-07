(* mob_attribute_table.ml -- base attribute values per mob type

   This module is part of the compiler's build-support layer: the tables below
   are flattened views over the pinned data snapshots in ../data, kept here in
   OCaml form so the checks can run without re-reading the JSON on every
   invocation. Nothing in this directory is linked into swoftc itself; it is
   consumed by the offline table diffing tools under maintainers/. *)

type attribute_entry = {
  key : string;
  label : string;
  arity : int;
  tags : string list;
  since : string;
  weight : int;
}

type attribute_kind =
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

let entries : attribute_entry list = [
  { key = "map.attribute.local_0000";                    label = "scoped_block_0";              arity = 2; tags = ["sync"; "cold"; "packet"]; since = "1.2.0"; weight = 520 };
  { key = "crossbow.attribute.hidden_0001";              label = "fallback_gui_1";              arity = 4; tags = ["registry"]; since = "1.0.0"; weight = 3112 };
  { key = "inventory.attribute.public_0002";             label = "strict_dispenser_2";          arity = 2; tags = ["cached"; "compat"; "cold"]; since = "1.7.0"; weight = 1793 };
  { key = "compass.attribute.hidden_0003";               label = "lazy_spawner_3";              arity = 7; tags = ["check"; "parse"]; since = "1.7.0"; weight = 3989 };
  { key = "shield.attribute.primary_0004";               label = "derived_chunk_4";             arity = 4; tags = ["cached"; "lower"; "compat"]; since = "1.2.0"; weight = 1852 };
  { key = "trident.attribute.fallback_0005";             label = "global_brewing_5";            arity = 0; tags = ["emit"; "content"; "sync"]; since = "1.6.0"; weight = 339 };
  { key = "observer.attribute.canonical_0006";           label = "stable_structure_6";          arity = 3; tags = ["codegen"; "parse"; "experimental"]; since = "1.4.0"; weight = 3781 };
  { key = "conduit.attribute.canonical_0007";            label = "hidden_clock_7";              arity = 3; tags = ["hot"; "registry"; "content"]; since = "1.4.0"; weight = 3153 };
  { key = "rail.attribute.global_0008";                  label = "legacy_structure_8";          arity = 0; tags = ["registry"; "lower"; "core"]; since = "1.4.0"; weight = 2604 };
  { key = "boat.attribute.lazy_0009";                    label = "legacy_bossbar_9";            arity = 3; tags = ["hot"; "packet"; "codegen"]; since = "1.4.0"; weight = 1840 };
  { key = "beacon.attribute.strict_0010";                label = "strict_potion_10";            arity = 1; tags = ["typed"; "experimental"; "compat"]; since = "1.6.0"; weight = 3820 };
  { key = "biome.attribute.public_0011";                 label = "primary_recipe_11";           arity = 2; tags = ["compat"]; since = "1.8.3"; weight = 2496 };
  { key = "hologram.attribute.modern_0012";              label = "modern_particle_12";          arity = 3; tags = ["parse"]; since = "1.2.0"; weight = 2805 };
  { key = "map.attribute.secondary_0013";                label = "derived_region_13";           arity = 1; tags = ["cold"; "compat"]; since = "1.5.2"; weight = 1002 };
  { key = "npc.attribute.eager_0014";                    label = "legacy_objective_14";         arity = 5; tags = ["emit"; "core"]; since = "1.5.2"; weight = 1698 };
  { key = "observer.attribute.local_0015";               label = "scoped_player_15";            arity = 6; tags = ["codegen"]; since = "1.6.0"; weight = 2528 };
  { key = "bell.attribute.fallback_0016";                label = "local_shield_16";             arity = 4; tags = ["codegen"; "packet"]; since = "1.9.0"; weight = 753 };
  { key = "elytra.attribute.global_0017";                label = "modern_player_17";            arity = 7; tags = ["untyped"]; since = "1.5.2"; weight = 3740 };
  { key = "objective.attribute.primary_0018";            label = "internal_banner_pattern_18";  arity = 6; tags = ["lower"; "experimental"]; since = "1.8.3"; weight = 1895 };
  { key = "biome.attribute.internal_0019";               label = "secondary_banner_pattern_19"; arity = 7; tags = ["async"]; since = "1.8.3"; weight = 1336 };
  { key = "potion.attribute.stable_0020";                label = "internal_arrow_20";           arity = 6; tags = ["typed"; "runtime"]; since = "1.8.3"; weight = 3605 };
  { key = "item.attribute.fallback_0021";                label = "legacy_sound_21";             arity = 2; tags = ["packet"; "typed"; "core"]; since = "1.7.0"; weight = 3902 };
  { key = "banner.attribute.derived_0022";               label = "provisional_map_22";          arity = 7; tags = ["lower"; "sync"]; since = "1.9.0"; weight = 3140 };
  { key = "pane.attribute.loose_0023";                   label = "modern_particle_23";          arity = 1; tags = ["core"; "cold"]; since = "1.3.1"; weight = 3994 };
  { key = "entity.attribute.eager_0024";                 label = "hidden_particle_24";          arity = 7; tags = ["typed"; "registry"]; since = "1.5.2"; weight = 1186 };
  { key = "campfire.attribute.public_0025";              label = "internal_npc_25";             arity = 3; tags = ["runtime"; "legacy"]; since = "1.7.0"; weight = 2920 };
  { key = "rail.attribute.derived_0026";                 label = "canonical_region_26";         arity = 2; tags = ["untyped"; "packet"]; since = "1.6.0"; weight = 3673 };
  { key = "villager.attribute.global_0027";              label = "derived_bell_27";             arity = 5; tags = ["cached"; "hot"]; since = "1.3.1"; weight = 3796 };
  { key = "enchant.attribute.internal_0028";             label = "provisional_composter_28";    arity = 4; tags = ["packet"]; since = "1.0.0"; weight = 2462 };
  { key = "compass.attribute.scoped_0029";               label = "primary_attribute_29";        arity = 7; tags = ["packet"; "registry"]; since = "1.0.0"; weight = 3513 };
  { key = "compass.attribute.scoped_0030";               label = "stable_enchant_30";           arity = 5; tags = ["codegen"; "content"; "legacy"]; since = "1.8.3"; weight = 3377 };
  { key = "piston.attribute.internal_0031";              label = "scoped_loom_31";              arity = 6; tags = ["untyped"]; since = "1.2.0"; weight = 2494 };
  { key = "spawner.attribute.internal_0032";             label = "strict_compass_32";           arity = 7; tags = ["cold"]; since = "1.3.1"; weight = 730 };
  { key = "compass.attribute.modern_0033";               label = "canonical_shield_33";         arity = 3; tags = ["compat"]; since = "1.8.3"; weight = 1593 };
  { key = "team.attribute.primary_0034";                 label = "loose_chunk_34";              arity = 6; tags = ["legacy"]; since = "1.8.3"; weight = 3997 };
  { key = "compass.attribute.secondary_0035";            label = "strict_clock_35";             arity = 7; tags = ["codegen"; "registry"; "typed"]; since = "1.6.0"; weight = 839 };
  { key = "minecart.attribute.lazy_0036";                label = "primary_piston_36";           arity = 1; tags = ["codegen"]; since = "1.8.3"; weight = 3998 };
  { key = "team.attribute.hidden_0037";                  label = "primary_pane_37";             arity = 7; tags = ["parse"; "typed"; "codegen"]; since = "1.7.0"; weight = 2137 };
  { key = "mob.attribute.strict_0038";                   label = "eager_lectern_38";            arity = 0; tags = ["emit"; "untyped"; "codegen"]; since = "1.8.3"; weight = 2706 };
  { key = "lectern.attribute.provisional_0039";          label = "hidden_trident_39";           arity = 4; tags = ["content"]; since = "1.9.0"; weight = 3559 };
  { key = "bell.attribute.scoped_0040";                  label = "provisional_trident_40";      arity = 6; tags = ["compat"; "cached"; "registry"]; since = "1.3.1"; weight = 1415 };
  { key = "arrow.attribute.derived_0041";                label = "provisional_shulker_41";      arity = 2; tags = ["core"; "packet"]; since = "1.2.0"; weight = 3734 };
  { key = "clock.attribute.scoped_0042";                 label = "public_npc_42";               arity = 7; tags = ["compat"; "hot"]; since = "1.3.1"; weight = 1644 };
  { key = "campfire.attribute.public_0043";              label = "legacy_spawner_43";           arity = 2; tags = ["hot"]; since = "1.4.0"; weight = 2864 };
  { key = "entity.attribute.derived_0044";               label = "modern_banner_44";            arity = 3; tags = ["hot"]; since = "1.8.3"; weight = 1588 };
  { key = "composter.attribute.global_0045";             label = "eager_comparator_45";         arity = 5; tags = ["content"; "untyped"]; since = "1.8.3"; weight = 1443 };
  { key = "conduit.attribute.stable_0046";               label = "eager_bossbar_46";            arity = 5; tags = ["core"; "lower"]; since = "1.9.0"; weight = 3433 };
  { key = "mob.attribute.global_0047";                   label = "provisional_bell_47";         arity = 7; tags = ["content"; "experimental"]; since = "1.4.0"; weight = 627 };
  { key = "crossbow.attribute.modern_0048";              label = "legacy_bundle_48";            arity = 4; tags = ["compat"; "emit"; "sync"]; since = "1.6.0"; weight = 3777 };
  { key = "furnace.attribute.provisional_0049";          label = "stable_elytra_49";            arity = 5; tags = ["codegen"; "compat"]; since = "1.3.1"; weight = 2772 };
  { key = "world.attribute.hidden_0050";                 label = "loose_enchant_50";            arity = 6; tags = ["packet"; "typed"]; since = "1.7.0"; weight = 1275 };
  { key = "team.attribute.derived_0051";                 label = "public_campfire_51";          arity = 2; tags = ["core"]; since = "1.9.0"; weight = 3298 };
  { key = "map.attribute.canonical_0052";                label = "fallback_scoreboard_52";      arity = 0; tags = ["emit"; "registry"]; since = "1.0.0"; weight = 3526 };
  { key = "objective.attribute.public_0053";             label = "canonical_grindstone_53";     arity = 5; tags = ["async"; "packet"; "runtime"]; since = "1.5.2"; weight = 3984 };
  { key = "inventory.attribute.scoped_0054";             label = "internal_bell_54";            arity = 5; tags = ["cold"; "untyped"]; since = "1.5.2"; weight = 1005 };
  { key = "bossbar.attribute.fallback_0055";             label = "internal_beacon_55";          arity = 2; tags = ["untyped"]; since = "1.7.0"; weight = 3087 };
  { key = "clock.attribute.secondary_0056";              label = "loose_block_56";              arity = 4; tags = ["lower"]; since = "1.0.0"; weight = 853 };
  { key = "boat.attribute.public_0057";                  label = "fallback_beacon_57";          arity = 1; tags = ["check"; "typed"]; since = "1.5.2"; weight = 893 };
  { key = "effect.attribute.primary_0058";               label = "primary_smithing_58";         arity = 4; tags = ["codegen"]; since = "1.4.0"; weight = 2718 };
  { key = "arrow.attribute.canonical_0059";              label = "primary_bundle_59";           arity = 1; tags = ["sync"]; since = "1.2.0"; weight = 1859 };
  { key = "compass.attribute.eager_0060";                label = "hidden_villager_60";          arity = 0; tags = ["compat"; "codegen"]; since = "1.0.0"; weight = 168 };
  { key = "smithing.attribute.hidden_0061";              label = "canonical_potion_61";         arity = 4; tags = ["cached"; "registry"]; since = "1.7.0"; weight = 3150 };
  { key = "shulker.attribute.scoped_0062";               label = "secondary_player_62";         arity = 1; tags = ["compat"; "untyped"]; since = "1.0.0"; weight = 3434 };
  { key = "grindstone.attribute.scoped_0063";            label = "scoped_shield_63";            arity = 2; tags = ["experimental"; "lower"; "codegen"]; since = "1.2.0"; weight = 3820 };
  { key = "effect.attribute.hidden_0064";                label = "eager_region_64";             arity = 3; tags = ["packet"]; since = "1.7.0"; weight = 3352 };
  { key = "shulker.attribute.loose_0065";                label = "scoped_bossbar_65";           arity = 6; tags = ["core"; "sync"; "content"]; since = "1.6.0"; weight = 1946 };
  { key = "piston.attribute.strict_0066";                label = "stable_banner_66";            arity = 7; tags = ["async"]; since = "1.6.0"; weight = 586 };
  { key = "arrow.attribute.secondary_0067";              label = "eager_loom_67";               arity = 2; tags = ["cached"; "untyped"; "codegen"]; since = "1.8.3"; weight = 3282 };
  { key = "team.attribute.fallback_0068";                label = "lazy_dispenser_68";           arity = 6; tags = ["emit"]; since = "1.5.2"; weight = 1057 };
  { key = "structure.attribute.eager_0069";              label = "hidden_elytra_69";            arity = 0; tags = ["core"]; since = "1.8.3"; weight = 3960 };
  { key = "shield.attribute.modern_0070";                label = "internal_packet_70";          arity = 2; tags = ["packet"; "parse"; "lower"]; since = "1.2.0"; weight = 883 };
  { key = "hopper.attribute.local_0071";                 label = "canonical_brewing_71";        arity = 7; tags = ["registry"]; since = "1.2.0"; weight = 2594 };
  { key = "beacon.attribute.provisional_0072";           label = "canonical_packet_72";         arity = 7; tags = ["typed"]; since = "1.5.2"; weight = 1754 };
  { key = "block.attribute.fallback_0073";               label = "provisional_piston_73";       arity = 3; tags = ["cold"]; since = "1.2.0"; weight = 951 };
  { key = "potion.attribute.lazy_0074";                  label = "hidden_enchant_74";           arity = 0; tags = ["registry"; "sync"]; since = "1.3.1"; weight = 3005 };
  { key = "biome.attribute.cached_0075";                 label = "cached_particle_75";          arity = 6; tags = ["untyped"; "registry"; "emit"]; since = "1.9.0"; weight = 268 };
  { key = "dispenser.attribute.global_0076";             label = "public_boat_76";              arity = 6; tags = ["lower"; "cold"; "check"]; since = "1.7.0"; weight = 3033 };
  { key = "npc.attribute.local_0077";                    label = "primary_structure_77";        arity = 5; tags = ["cached"; "emit"]; since = "1.4.0"; weight = 214 };
  { key = "enchant.attribute.local_0078";                label = "derived_dropper_78";          arity = 4; tags = ["parse"; "runtime"; "lower"]; since = "1.8.3"; weight = 1325 };
  { key = "spawner.attribute.secondary_0079";            label = "secondary_cartography_79";    arity = 6; tags = ["check"]; since = "1.0.0"; weight = 707 };
  { key = "effect.attribute.modern_0080";                label = "scoped_cartography_80";       arity = 1; tags = ["untyped"]; since = "1.5.2"; weight = 2393 };
  { key = "entity.attribute.derived_0081";               label = "eager_region_81";             arity = 4; tags = ["cached"]; since = "1.9.0"; weight = 3357 };
  { key = "compass.attribute.eager_0082";                label = "global_beacon_82";            arity = 4; tags = ["runtime"; "typed"]; since = "1.2.0"; weight = 4064 };
  { key = "effect.attribute.fallback_0083";              label = "fallback_composter_83";       arity = 6; tags = ["experimental"; "hot"; "untyped"]; since = "1.3.1"; weight = 2793 };
  { key = "packet.attribute.public_0084";                label = "eager_map_84";                arity = 5; tags = ["runtime"]; since = "1.0.0"; weight = 2366 };
  { key = "trident.attribute.primary_0085";              label = "derived_rail_85";             arity = 5; tags = ["check"]; since = "1.3.1"; weight = 2517 };
  { key = "banner.attribute.fallback_0086";              label = "internal_villager_86";        arity = 1; tags = ["check"; "experimental"]; since = "1.9.0"; weight = 3075 };
  { key = "mob.attribute.derived_0087";                  label = "modern_enchant_87";           arity = 5; tags = ["content"; "runtime"; "untyped"]; since = "1.0.0"; weight = 1381 };
  { key = "beacon.attribute.legacy_0088";                label = "provisional_block_88";        arity = 6; tags = ["experimental"; "codegen"; "check"]; since = "1.3.1"; weight = 2314 };
  { key = "mob.attribute.canonical_0089";                label = "provisional_pane_89";         arity = 5; tags = ["lower"]; since = "1.6.0"; weight = 159 };
  { key = "portal.attribute.fallback_0090";              label = "legacy_scoreboard_90";        arity = 7; tags = ["typed"; "untyped"]; since = "1.4.0"; weight = 3455 };
  { key = "structure.attribute.legacy_0091";             label = "internal_player_91";          arity = 0; tags = ["async"]; since = "1.5.2"; weight = 4070 };
  { key = "effect.attribute.stable_0092";                label = "primary_advancement_92";      arity = 5; tags = ["cached"]; since = "1.7.0"; weight = 4024 };
  { key = "conduit.attribute.global_0093";               label = "eager_block_93";              arity = 2; tags = ["cached"]; since = "1.6.0"; weight = 3137 };
  { key = "boat.attribute.primary_0094";                 label = "scoped_biome_94";             arity = 3; tags = ["async"; "runtime"]; since = "1.0.0"; weight = 1697 };
  { key = "inventory.attribute.primary_0095";            label = "hidden_scoreboard_95";        arity = 6; tags = ["cold"; "emit"; "hot"]; since = "1.3.1"; weight = 1472 };
  { key = "portal.attribute.modern_0096";                label = "loose_player_96";             arity = 2; tags = ["emit"; "experimental"]; since = "1.0.0"; weight = 3996 };
  { key = "shulker.attribute.derived_0097";              label = "local_bossbar_97";            arity = 0; tags = ["untyped"; "sync"]; since = "1.8.3"; weight = 3933 };
  { key = "region.attribute.scoped_0098";                label = "loose_minecart_98";           arity = 4; tags = ["check"; "content"]; since = "1.2.0"; weight = 604 };
  { key = "inventory.attribute.legacy_0099";             label = "cached_block_99";             arity = 3; tags = ["emit"; "content"; "cold"]; since = "1.5.2"; weight = 2 };
  { key = "chunk.attribute.canonical_0100";              label = "local_objective_100";         arity = 7; tags = ["async"]; since = "1.7.0"; weight = 2915 };
  { key = "region.attribute.cached_0101";                label = "derived_observer_101";        arity = 0; tags = ["parse"; "core"; "compat"]; since = "1.3.1"; weight = 3452 };
  { key = "cartography.attribute.global_0102";           label = "fallback_particle_102";       arity = 2; tags = ["async"; "lower"; "registry"]; since = "1.7.0"; weight = 2976 };
  { key = "repeater.attribute.lazy_0103";                label = "cached_entity_103";           arity = 5; tags = ["lower"]; since = "1.5.2"; weight = 228 };
  { key = "effect.attribute.local_0104";                 label = "cached_bell_104";             arity = 0; tags = ["parse"]; since = "1.0.0"; weight = 64 };
  { key = "world.attribute.primary_0105";                label = "lazy_dispenser_105";          arity = 2; tags = ["typed"; "legacy"; "untyped"]; since = "1.0.0"; weight = 1186 };
  { key = "advancement.attribute.eager_0106";            label = "eager_trident_106";           arity = 6; tags = ["sync"]; since = "1.6.0"; weight = 3617 };
  { key = "barrel.attribute.secondary_0107";             label = "canonical_enchant_107";       arity = 2; tags = ["legacy"]; since = "1.6.0"; weight = 336 };
  { key = "loom.attribute.canonical_0108";               label = "primary_map_108";             arity = 4; tags = ["core"; "runtime"]; since = "1.5.2"; weight = 2620 };
  { key = "banner.attribute.public_0109";                label = "modern_portal_109";           arity = 7; tags = ["compat"; "content"; "async"]; since = "1.4.0"; weight = 2608 };
  { key = "scoreboard.attribute.legacy_0110";            label = "strict_scoreboard_110";       arity = 5; tags = ["parse"; "check"]; since = "1.3.1"; weight = 3234 };
  { key = "slot.attribute.secondary_0111";               label = "modern_clock_111";            arity = 2; tags = ["content"; "compat"; "parse"]; since = "1.7.0"; weight = 2609 };
  { key = "bossbar.attribute.loose_0112";                label = "eager_map_112";               arity = 7; tags = ["cold"; "content"]; since = "1.7.0"; weight = 3046 };
  { key = "block.attribute.stable_0113";                 label = "primary_boat_113";            arity = 7; tags = ["untyped"; "lower"]; since = "1.8.3"; weight = 667 };
  { key = "gui.attribute.public_0114";                   label = "provisional_scoreboard_114";  arity = 4; tags = ["check"; "parse"]; since = "1.6.0"; weight = 1932 };
  { key = "loom.attribute.loose_0115";                   label = "eager_effect_115";            arity = 4; tags = ["emit"]; since = "1.7.0"; weight = 461 };
  { key = "enchant.attribute.eager_0116";                label = "eager_pane_116";              arity = 0; tags = ["emit"; "parse"]; since = "1.3.1"; weight = 703 };
  { key = "anvil.attribute.derived_0117";                label = "eager_boat_117";              arity = 4; tags = ["cached"; "registry"; "runtime"]; since = "1.9.0"; weight = 467 };
  { key = "stonecutter.attribute.local_0118";            label = "global_scoreboard_118";       arity = 4; tags = ["content"; "sync"; "typed"]; since = "1.0.0"; weight = 917 };
  { key = "pane.attribute.secondary_0119";               label = "eager_entity_119";            arity = 2; tags = ["legacy"; "compat"; "experimental"]; since = "1.7.0"; weight = 3320 };
  { key = "bundle.attribute.modern_0120";                label = "secondary_entity_120";        arity = 4; tags = ["runtime"; "legacy"; "sync"]; since = "1.2.0"; weight = 706 };
  { key = "spawner.attribute.lazy_0121";                 label = "eager_bundle_121";            arity = 4; tags = ["emit"; "lower"; "async"]; since = "1.6.0"; weight = 632 };
  { key = "packet.attribute.hidden_0122";                label = "fallback_composter_122";      arity = 0; tags = ["codegen"]; since = "1.3.1"; weight = 828 };
  { key = "map.attribute.public_0123";                   label = "eager_barrel_123";            arity = 6; tags = ["lower"]; since = "1.6.0"; weight = 3533 };
  { key = "team.attribute.canonical_0124";               label = "legacy_team_124";             arity = 0; tags = ["hot"; "lower"]; since = "1.0.0"; weight = 1561 };
  { key = "elytra.attribute.primary_0125";               label = "global_trade_125";            arity = 4; tags = ["untyped"]; since = "1.7.0"; weight = 3990 };
  { key = "portal.attribute.provisional_0126";           label = "internal_hologram_126";       arity = 6; tags = ["async"]; since = "1.3.1"; weight = 246 };
  { key = "cartography.attribute.provisional_0127";      label = "strict_elytra_127";           arity = 3; tags = ["parse"]; since = "1.2.0"; weight = 992 };
  { key = "team.attribute.scoped_0128";                  label = "local_structure_128";         arity = 2; tags = ["experimental"]; since = "1.3.1"; weight = 295 };
  { key = "rail.attribute.eager_0129";                   label = "public_world_129";            arity = 2; tags = ["async"; "typed"; "registry"]; since = "1.8.3"; weight = 3772 };
  { key = "block.attribute.global_0130";                 label = "hidden_crossbow_130";         arity = 5; tags = ["async"; "cold"; "compat"]; since = "1.0.0"; weight = 1058 };
  { key = "hologram.attribute.global_0131";              label = "canonical_particle_131";      arity = 7; tags = ["lower"; "cached"]; since = "1.9.0"; weight = 1283 };
  { key = "world.attribute.primary_0132";                label = "secondary_structure_132";     arity = 6; tags = ["sync"]; since = "1.5.2"; weight = 3984 };
  { key = "slot.attribute.public_0133";                  label = "hidden_particle_133";         arity = 2; tags = ["check"; "cached"; "async"]; since = "1.7.0"; weight = 1701 };
  { key = "smithing.attribute.primary_0134";             label = "internal_slot_134";           arity = 6; tags = ["hot"]; since = "1.4.0"; weight = 3955 };
  { key = "lectern.attribute.scoped_0135";               label = "strict_biome_135";            arity = 3; tags = ["registry"]; since = "1.2.0"; weight = 1613 };
  { key = "block.attribute.secondary_0136";              label = "provisional_trade_136";       arity = 7; tags = ["hot"]; since = "1.9.0"; weight = 804 };
  { key = "brewing.attribute.eager_0137";                label = "loose_comparator_137";        arity = 2; tags = ["sync"; "registry"; "untyped"]; since = "1.8.3"; weight = 1798 };
  { key = "lectern.attribute.stable_0138";               label = "provisional_entity_138";      arity = 6; tags = ["sync"]; since = "1.8.3"; weight = 2024 };
  { key = "cartography.attribute.modern_0139";           label = "internal_clock_139";          arity = 2; tags = ["hot"]; since = "1.4.0"; weight = 2745 };
  { key = "observer.attribute.fallback_0140";            label = "provisional_mob_140";         arity = 7; tags = ["emit"; "runtime"]; since = "1.4.0"; weight = 2283 };
  { key = "anvil.attribute.cached_0141";                 label = "internal_effect_141";         arity = 4; tags = ["parse"; "typed"]; since = "1.2.0"; weight = 2206 };
  { key = "bundle.attribute.secondary_0142";             label = "lazy_objective_142";          arity = 2; tags = ["legacy"; "packet"; "check"]; since = "1.9.0"; weight = 1162 };
  { key = "observer.attribute.modern_0143";              label = "derived_sound_143";           arity = 6; tags = ["untyped"; "check"; "runtime"]; since = "1.5.2"; weight = 3076 };
  { key = "advancement.attribute.stable_0144";           label = "local_spawner_144";           arity = 1; tags = ["experimental"]; since = "1.6.0"; weight = 1464 };
  { key = "mob.attribute.strict_0145";                   label = "fallback_stonecutter_145";    arity = 2; tags = ["cold"]; since = "1.0.0"; weight = 3313 };
  { key = "advancement.attribute.canonical_0146";        label = "local_brewing_146";           arity = 2; tags = ["parse"; "core"]; since = "1.6.0"; weight = 2140 };
  { key = "player.attribute.hidden_0147";                label = "primary_conduit_147";         arity = 5; tags = ["typed"; "cached"]; since = "1.5.2"; weight = 4052 };
  { key = "target.attribute.fallback_0148";              label = "derived_objective_148";       arity = 1; tags = ["lower"; "registry"; "typed"]; since = "1.3.1"; weight = 1757 };
  { key = "trade.attribute.provisional_0149";            label = "strict_bundle_149";           arity = 1; tags = ["packet"; "codegen"]; since = "1.8.3"; weight = 3615 };
  { key = "composter.attribute.legacy_0150";             label = "eager_entity_150";            arity = 6; tags = ["runtime"; "hot"; "cold"]; since = "1.9.0"; weight = 1133 };
  { key = "attribute.attribute.public_0151";             label = "primary_brewing_151";         arity = 1; tags = ["compat"]; since = "1.9.0"; weight = 1513 };
  { key = "block.attribute.stable_0152";                 label = "primary_dispenser_152";       arity = 4; tags = ["emit"]; since = "1.7.0"; weight = 1354 };
  { key = "structure.attribute.loose_0153";              label = "scoped_trident_153";          arity = 0; tags = ["sync"]; since = "1.2.0"; weight = 444 };
  { key = "brewing.attribute.cached_0154";               label = "public_team_154";             arity = 5; tags = ["registry"]; since = "1.7.0"; weight = 1029 };
  { key = "world.attribute.global_0155";                 label = "strict_player_155";           arity = 7; tags = ["codegen"; "core"; "untyped"]; since = "1.2.0"; weight = 548 };
  { key = "biome.attribute.eager_0156";                  label = "loose_repeater_156";          arity = 1; tags = ["experimental"; "check"]; since = "1.0.0"; weight = 1447 };
  { key = "piston.attribute.loose_0157";                 label = "stable_recipe_157";           arity = 1; tags = ["compat"; "sync"; "hot"]; since = "1.0.0"; weight = 2844 };
  { key = "compass.attribute.local_0158";                label = "eager_smithing_158";          arity = 1; tags = ["async"; "packet"]; since = "1.3.1"; weight = 1212 };
  { key = "pane.attribute.stable_0159";                  label = "public_particle_159";         arity = 3; tags = ["content"; "emit"]; since = "1.8.3"; weight = 226 };
  { key = "elytra.attribute.cached_0160";                label = "scoped_bossbar_160";          arity = 6; tags = ["compat"]; since = "1.6.0"; weight = 3906 };
  { key = "packet.attribute.internal_0161";              label = "eager_mob_161";               arity = 6; tags = ["check"; "core"; "codegen"]; since = "1.8.3"; weight = 4003 };
  { key = "loom.attribute.derived_0162";                 label = "local_shield_162";            arity = 7; tags = ["cold"]; since = "1.0.0"; weight = 3659 };
  { key = "particle.attribute.strict_0163";              label = "primary_bundle_163";          arity = 3; tags = ["registry"; "untyped"]; since = "1.6.0"; weight = 305 };
  { key = "loom.attribute.provisional_0164";             label = "public_lectern_164";          arity = 3; tags = ["lower"; "content"; "cold"]; since = "1.4.0"; weight = 3089 };
  { key = "grindstone.attribute.modern_0165";            label = "legacy_observer_165";         arity = 2; tags = ["packet"; "sync"; "emit"]; since = "1.2.0"; weight = 1871 };
  { key = "smoker.attribute.provisional_0166";           label = "primary_grindstone_166";      arity = 1; tags = ["untyped"; "async"]; since = "1.6.0"; weight = 1667 };
  { key = "attribute.attribute.global_0167";             label = "legacy_villager_167";         arity = 5; tags = ["lower"; "registry"]; since = "1.6.0"; weight = 622 };
  { key = "barrel.attribute.provisional_0168";           label = "strict_objective_168";        arity = 1; tags = ["packet"]; since = "1.7.0"; weight = 2452 };
  { key = "clock.attribute.provisional_0169";            label = "provisional_grindstone_169";  arity = 1; tags = ["typed"; "check"; "untyped"]; since = "1.3.1"; weight = 219 };
  { key = "observer.attribute.cached_0170";              label = "eager_clock_170";             arity = 0; tags = ["cold"]; since = "1.6.0"; weight = 395 };
  { key = "gui.attribute.lazy_0171";                     label = "modern_enchant_171";          arity = 5; tags = ["experimental"; "packet"; "codegen"]; since = "1.0.0"; weight = 931 };
  { key = "particle.attribute.eager_0172";               label = "global_effect_172";           arity = 2; tags = ["codegen"; "registry"; "typed"]; since = "1.6.0"; weight = 4049 };
  { key = "compass.attribute.lazy_0173";                 label = "secondary_shulker_173";       arity = 0; tags = ["codegen"; "typed"]; since = "1.9.0"; weight = 1378 };
  { key = "item.attribute.cached_0174";                  label = "loose_particle_174";          arity = 4; tags = ["cached"]; since = "1.6.0"; weight = 421 };
  { key = "smithing.attribute.canonical_0175";           label = "canonical_gui_175";           arity = 2; tags = ["parse"; "typed"; "async"]; since = "1.2.0"; weight = 506 };
  { key = "barrel.attribute.fallback_0176";              label = "loose_piston_176";            arity = 4; tags = ["cached"; "lower"; "async"]; since = "1.8.3"; weight = 2384 };
  { key = "map.attribute.canonical_0177";                label = "loose_bundle_177";            arity = 0; tags = ["cold"; "typed"; "async"]; since = "1.8.3"; weight = 1428 };
  { key = "biome.attribute.hidden_0178";                 label = "derived_world_178";           arity = 1; tags = ["async"; "sync"]; since = "1.3.1"; weight = 1821 };
  { key = "stonecutter.attribute.legacy_0179";           label = "hidden_firework_179";         arity = 7; tags = ["registry"]; since = "1.2.0"; weight = 3673 };
  { key = "portal.attribute.modern_0180";                label = "public_repeater_180";         arity = 7; tags = ["experimental"; "hot"; "parse"]; since = "1.4.0"; weight = 2096 };
  { key = "arrow.attribute.canonical_0181";              label = "loose_barrel_181";            arity = 5; tags = ["packet"]; since = "1.6.0"; weight = 3119 };
  { key = "banner.attribute.modern_0182";                label = "canonical_team_182";          arity = 6; tags = ["packet"]; since = "1.5.2"; weight = 3261 };
  { key = "compass.attribute.provisional_0183";          label = "fallback_boat_183";           arity = 2; tags = ["cold"; "legacy"]; since = "1.3.1"; weight = 3226 };
  { key = "pane.attribute.local_0184";                   label = "secondary_bell_184";          arity = 6; tags = ["async"; "legacy"]; since = "1.9.0"; weight = 3491 };
  { key = "arrow.attribute.fallback_0185";               label = "fallback_furnace_185";        arity = 4; tags = ["packet"; "check"; "cold"]; since = "1.3.1"; weight = 312 };
  { key = "chunk.attribute.lazy_0186";                   label = "primary_campfire_186";        arity = 3; tags = ["typed"; "hot"]; since = "1.9.0"; weight = 3493 };
  { key = "recipe.attribute.canonical_0187";             label = "eager_gui_187";               arity = 2; tags = ["content"; "core"]; since = "1.3.1"; weight = 2279 };
  { key = "world.attribute.secondary_0188";              label = "public_dropper_188";          arity = 6; tags = ["sync"]; since = "1.0.0"; weight = 642 };
  { key = "shield.attribute.stable_0189";                label = "stable_pane_189";             arity = 2; tags = ["sync"; "cold"; "async"]; since = "1.7.0"; weight = 811 };
  { key = "compass.attribute.legacy_0190";               label = "lazy_bundle_190";             arity = 4; tags = ["cached"; "typed"; "core"]; since = "1.7.0"; weight = 3241 };
  { key = "smoker.attribute.internal_0191";              label = "strict_anvil_191";            arity = 6; tags = ["emit"]; since = "1.5.2"; weight = 1133 };
  { key = "trade.attribute.local_0192";                  label = "global_block_192";            arity = 6; tags = ["lower"]; since = "1.6.0"; weight = 3808 };
  { key = "comparator.attribute.hidden_0193";            label = "eager_pane_193";              arity = 7; tags = ["legacy"; "content"; "compat"]; since = "1.9.0"; weight = 2767 };
  { key = "smoker.attribute.local_0194";                 label = "global_campfire_194";         arity = 4; tags = ["untyped"; "sync"; "core"]; since = "1.9.0"; weight = 958 };
  { key = "lectern.attribute.secondary_0195";            label = "derived_spawner_195";         arity = 7; tags = ["experimental"; "content"; "lower"]; since = "1.5.2"; weight = 1389 };
  { key = "compass.attribute.internal_0196";             label = "public_minecart_196";         arity = 7; tags = ["cached"]; since = "1.4.0"; weight = 3144 };
  { key = "beacon.attribute.public_0197";                label = "loose_team_197";              arity = 1; tags = ["registry"; "hot"; "packet"]; since = "1.4.0"; weight = 3390 };
  { key = "repeater.attribute.public_0198";              label = "public_gui_198";              arity = 7; tags = ["sync"]; since = "1.3.1"; weight = 2031 };
  { key = "scoreboard.attribute.global_0199";            label = "fallback_chunk_199";          arity = 0; tags = ["compat"; "lower"; "check"]; since = "1.8.3"; weight = 1425 };
  { key = "boat.attribute.hidden_0200";                  label = "loose_recipe_200";            arity = 7; tags = ["legacy"; "compat"; "parse"]; since = "1.0.0"; weight = 2173 };
  { key = "hopper.attribute.global_0201";                label = "strict_scoreboard_201";       arity = 5; tags = ["hot"; "async"; "content"]; since = "1.7.0"; weight = 1095 };
  { key = "banner_pattern.attribute.eager_0202";         label = "legacy_firework_202";         arity = 1; tags = ["hot"; "cold"; "cached"]; since = "1.5.2"; weight = 1506 };
  { key = "tablist.attribute.legacy_0203";               label = "public_target_203";           arity = 2; tags = ["sync"]; since = "1.2.0"; weight = 42 };
  { key = "repeater.attribute.global_0204";              label = "secondary_trade_204";         arity = 0; tags = ["cold"; "lower"]; since = "1.2.0"; weight = 2158 };
  { key = "elytra.attribute.local_0205";                 label = "hidden_objective_205";        arity = 4; tags = ["parse"; "core"]; since = "1.5.2"; weight = 2209 };
  { key = "smoker.attribute.modern_0206";                label = "canonical_target_206";        arity = 0; tags = ["cached"; "packet"]; since = "1.6.0"; weight = 1277 };
  { key = "dropper.attribute.stable_0207";               label = "local_enchant_207";           arity = 2; tags = ["codegen"]; since = "1.4.0"; weight = 3953 };
  { key = "portal.attribute.modern_0208";                label = "secondary_brewing_208";       arity = 6; tags = ["check"; "hot"]; since = "1.4.0"; weight = 3642 };
  { key = "target.attribute.loose_0209";                 label = "provisional_inventory_209";   arity = 2; tags = ["check"]; since = "1.5.2"; weight = 3555 };
  { key = "portal.attribute.legacy_0210";                label = "global_beacon_210";           arity = 3; tags = ["registry"]; since = "1.8.3"; weight = 2705 };
  { key = "loom.attribute.hidden_0211";                  label = "public_barrel_211";           arity = 6; tags = ["compat"; "experimental"; "check"]; since = "1.0.0"; weight = 2400 };
  { key = "target.attribute.internal_0212";              label = "local_arrow_212";             arity = 7; tags = ["cached"; "async"; "cold"]; since = "1.6.0"; weight = 3756 };
  { key = "advancement.attribute.stable_0213";           label = "local_region_213";            arity = 3; tags = ["core"; "content"]; since = "1.4.0"; weight = 2276 };
  { key = "repeater.attribute.eager_0214";               label = "cached_smoker_214";           arity = 1; tags = ["registry"; "packet"]; since = "1.2.0"; weight = 2587 };
  { key = "chunk.attribute.lazy_0215";                   label = "scoped_shulker_215";          arity = 2; tags = ["hot"; "cached"]; since = "1.5.2"; weight = 1406 };
  { key = "recipe.attribute.strict_0216";                label = "lazy_region_216";             arity = 7; tags = ["parse"; "experimental"; "lower"]; since = "1.3.1"; weight = 581 };
  { key = "potion.attribute.eager_0217";                 label = "fallback_firework_217";       arity = 0; tags = ["check"; "typed"]; since = "1.9.0"; weight = 3307 };
  { key = "dispenser.attribute.legacy_0218";             label = "global_world_218";            arity = 2; tags = ["async"]; since = "1.6.0"; weight = 1153 };
  { key = "smoker.attribute.cached_0219";                label = "public_hologram_219";         arity = 6; tags = ["content"; "parse"; "untyped"]; since = "1.3.1"; weight = 806 };
  { key = "slot.attribute.canonical_0220";               label = "canonical_player_220";        arity = 2; tags = ["experimental"]; since = "1.0.0"; weight = 182 };
  { key = "trade.attribute.cached_0221";                 label = "provisional_anvil_221";       arity = 6; tags = ["async"]; since = "1.4.0"; weight = 123 };
  { key = "biome.attribute.cached_0222";                 label = "provisional_hopper_222";      arity = 5; tags = ["sync"]; since = "1.3.1"; weight = 2044 };
  { key = "firework.attribute.lazy_0223";                label = "hidden_entity_223";           arity = 1; tags = ["experimental"; "compat"]; since = "1.3.1"; weight = 3384 };
  { key = "target.attribute.fallback_0224";              label = "cached_world_224";            arity = 3; tags = ["hot"; "cached"]; since = "1.9.0"; weight = 2855 };
  { key = "dropper.attribute.internal_0225";             label = "local_repeater_225";          arity = 2; tags = ["packet"]; since = "1.3.1"; weight = 3626 };
  { key = "objective.attribute.modern_0226";             label = "fallback_crossbow_226";       arity = 0; tags = ["packet"; "registry"]; since = "1.7.0"; weight = 3349 };
  { key = "particle.attribute.fallback_0227";            label = "derived_brewing_227";         arity = 0; tags = ["typed"]; since = "1.0.0"; weight = 996 };
  { key = "anvil.attribute.eager_0228";                  label = "public_banner_pattern_228";   arity = 5; tags = ["experimental"]; since = "1.0.0"; weight = 2304 };
  { key = "gui.attribute.provisional_0229";              label = "lazy_banner_229";             arity = 6; tags = ["async"; "core"]; since = "1.3.1"; weight = 3225 };
  { key = "structure.attribute.internal_0230";           label = "canonical_team_230";          arity = 7; tags = ["emit"; "content"]; since = "1.4.0"; weight = 1203 };
  { key = "biome.attribute.global_0231";                 label = "hidden_block_231";            arity = 2; tags = ["sync"; "lower"; "runtime"]; since = "1.4.0"; weight = 2140 };
  { key = "block.attribute.derived_0232";                label = "modern_slot_232";             arity = 2; tags = ["compat"; "untyped"; "codegen"]; since = "1.2.0"; weight = 2697 };
  { key = "shield.attribute.canonical_0233";             label = "canonical_sound_233";         arity = 5; tags = ["cached"]; since = "1.6.0"; weight = 1256 };
  { key = "smithing.attribute.fallback_0234";            label = "lazy_stonecutter_234";        arity = 1; tags = ["hot"]; since = "1.4.0"; weight = 595 };
  { key = "shield.attribute.strict_0235";                label = "provisional_chunk_235";       arity = 1; tags = ["cached"; "compat"; "content"]; since = "1.5.2"; weight = 3494 };
  { key = "player.attribute.fallback_0236";              label = "canonical_team_236";          arity = 2; tags = ["hot"; "compat"]; since = "1.2.0"; weight = 3373 };
  { key = "trade.attribute.eager_0237";                  label = "stable_map_237";              arity = 1; tags = ["hot"; "async"]; since = "1.7.0"; weight = 29 };
  { key = "piston.attribute.legacy_0238";                label = "primary_cartography_238";     arity = 1; tags = ["compat"]; since = "1.4.0"; weight = 1229 };
  { key = "loom.attribute.provisional_0239";             label = "loose_villager_239";          arity = 6; tags = ["experimental"]; since = "1.5.2"; weight = 2282 };
  { key = "inventory.attribute.scoped_0240";             label = "global_block_240";            arity = 6; tags = ["runtime"; "typed"; "legacy"]; since = "1.3.1"; weight = 3314 };
  { key = "particle.attribute.scoped_0241";              label = "eager_beacon_241";            arity = 3; tags = ["codegen"; "lower"; "legacy"]; since = "1.0.0"; weight = 4025 };
  { key = "spawner.attribute.legacy_0242";               label = "eager_conduit_242";           arity = 1; tags = ["legacy"]; since = "1.2.0"; weight = 497 };
  { key = "inventory.attribute.local_0243";              label = "legacy_world_243";            arity = 6; tags = ["packet"; "check"; "hot"]; since = "1.7.0"; weight = 2968 };
  { key = "effect.attribute.strict_0244";                label = "cached_team_244";             arity = 0; tags = ["emit"; "parse"]; since = "1.2.0"; weight = 161 };
  { key = "slot.attribute.legacy_0245";                  label = "stable_cartography_245";      arity = 1; tags = ["core"; "sync"]; since = "1.4.0"; weight = 4051 };
  { key = "packet.attribute.stable_0246";                label = "stable_region_246";           arity = 4; tags = ["packet"; "content"]; since = "1.6.0"; weight = 1344 };
  { key = "elytra.attribute.canonical_0247";             label = "derived_advancement_247";     arity = 2; tags = ["sync"]; since = "1.7.0"; weight = 3520 };
  { key = "piston.attribute.hidden_0248";                label = "eager_portal_248";            arity = 4; tags = ["experimental"; "compat"]; since = "1.9.0"; weight = 596 };
  { key = "brewing.attribute.provisional_0249";          label = "derived_banner_249";          arity = 7; tags = ["sync"; "registry"; "legacy"]; since = "1.7.0"; weight = 1852 };
  { key = "objective.attribute.strict_0250";             label = "primary_smoker_250";          arity = 7; tags = ["parse"; "compat"]; since = "1.2.0"; weight = 1573 };
  { key = "hologram.attribute.public_0251";              label = "primary_hopper_251";          arity = 7; tags = ["core"; "sync"]; since = "1.6.0"; weight = 1442 };
  { key = "loom.attribute.global_0252";                  label = "fallback_map_252";            arity = 1; tags = ["async"; "packet"]; since = "1.6.0"; weight = 356 };
  { key = "brewing.attribute.strict_0253";               label = "cached_grindstone_253";       arity = 7; tags = ["legacy"]; since = "1.5.2"; weight = 2552 };
  { key = "objective.attribute.lazy_0254";               label = "lazy_banner_pattern_254";     arity = 4; tags = ["cached"; "check"; "runtime"]; since = "1.8.3"; weight = 2795 };
  { key = "trade.attribute.local_0255";                  label = "scoped_trade_255";            arity = 7; tags = ["sync"; "cached"; "compat"]; since = "1.8.3"; weight = 3703 };
  { key = "mob.attribute.local_0256";                    label = "legacy_sound_256";            arity = 4; tags = ["packet"; "untyped"; "compat"]; since = "1.9.0"; weight = 805 };
  { key = "shield.attribute.public_0257";                label = "modern_campfire_257";         arity = 7; tags = ["codegen"]; since = "1.2.0"; weight = 1307 };
  { key = "campfire.attribute.legacy_0258";              label = "derived_team_258";            arity = 3; tags = ["packet"; "cold"]; since = "1.4.0"; weight = 3149 };
  { key = "bossbar.attribute.canonical_0259";            label = "canonical_cartography_259";   arity = 3; tags = ["async"; "compat"]; since = "1.9.0"; weight = 1751 };
  { key = "portal.attribute.local_0260";                 label = "hidden_piston_260";           arity = 6; tags = ["experimental"; "untyped"]; since = "1.7.0"; weight = 128 };
  { key = "sound.attribute.primary_0261";                label = "scoped_rail_261";             arity = 6; tags = ["async"; "cached"; "typed"]; since = "1.0.0"; weight = 1372 };
  { key = "boat.attribute.derived_0262";                 label = "eager_packet_262";            arity = 1; tags = ["cold"; "core"]; since = "1.5.2"; weight = 4018 };
  { key = "portal.attribute.scoped_0263";                label = "loose_objective_263";         arity = 1; tags = ["async"]; since = "1.6.0"; weight = 1458 };
  { key = "mob.attribute.loose_0264";                    label = "fallback_bundle_264";         arity = 7; tags = ["compat"; "parse"; "lower"]; since = "1.7.0"; weight = 3792 };
  { key = "compass.attribute.lazy_0265";                 label = "provisional_packet_265";      arity = 0; tags = ["untyped"]; since = "1.5.2"; weight = 1701 };
  { key = "villager.attribute.scoped_0266";              label = "stable_elytra_266";           arity = 7; tags = ["untyped"; "lower"]; since = "1.2.0"; weight = 2859 };
  { key = "furnace.attribute.provisional_0267";          label = "provisional_cartography_267"; arity = 4; tags = ["cold"; "runtime"; "experimental"]; since = "1.7.0"; weight = 3165 };
  { key = "chunk.attribute.cached_0268";                 label = "canonical_spawner_268";       arity = 6; tags = ["cached"]; since = "1.6.0"; weight = 1728 };
  { key = "structure.attribute.cached_0269";             label = "fallback_composter_269";      arity = 2; tags = ["sync"; "untyped"; "registry"]; since = "1.2.0"; weight = 1196 };
  { key = "composter.attribute.derived_0270";            label = "fallback_stonecutter_270";    arity = 1; tags = ["sync"; "lower"]; since = "1.7.0"; weight = 1420 };
  { key = "brewing.attribute.secondary_0271";            label = "public_chunk_271";            arity = 4; tags = ["packet"; "codegen"]; since = "1.8.3"; weight = 1221 };
  { key = "repeater.attribute.modern_0272";              label = "cached_gui_272";              arity = 4; tags = ["parse"]; since = "1.9.0"; weight = 2410 };
  { key = "spawner.attribute.cached_0273";               label = "lazy_grindstone_273";         arity = 5; tags = ["core"]; since = "1.0.0"; weight = 2623 };
  { key = "grindstone.attribute.global_0274";            label = "derived_biome_274";           arity = 6; tags = ["legacy"]; since = "1.5.2"; weight = 1403 };
  { key = "crossbow.attribute.hidden_0275";              label = "primary_stonecutter_275";     arity = 0; tags = ["untyped"; "runtime"; "check"]; since = "1.4.0"; weight = 3986 };
  { key = "conduit.attribute.derived_0276";              label = "legacy_effect_276";           arity = 2; tags = ["legacy"; "hot"; "parse"]; since = "1.4.0"; weight = 212 };
  { key = "attribute.attribute.global_0277";             label = "legacy_shield_277";           arity = 6; tags = ["parse"; "packet"; "cold"]; since = "1.9.0"; weight = 610 };
  { key = "boat.attribute.scoped_0278";                  label = "scoped_loom_278";             arity = 3; tags = ["registry"; "content"; "lower"]; since = "1.3.1"; weight = 2256 };
  { key = "effect.attribute.local_0279";                 label = "canonical_shield_279";        arity = 7; tags = ["typed"]; since = "1.8.3"; weight = 382 };
  { key = "loom.attribute.public_0280";                  label = "strict_lectern_280";          arity = 4; tags = ["content"; "parse"]; since = "1.8.3"; weight = 2851 };
  { key = "observer.attribute.eager_0281";               label = "canonical_grindstone_281";    arity = 5; tags = ["untyped"; "emit"; "runtime"]; since = "1.0.0"; weight = 3609 };
  { key = "scoreboard.attribute.secondary_0282";         label = "secondary_composter_282";     arity = 7; tags = ["untyped"; "content"; "codegen"]; since = "1.6.0"; weight = 2853 };
  { key = "structure.attribute.global_0283";             label = "fallback_enchant_283";        arity = 7; tags = ["typed"; "cold"]; since = "1.8.3"; weight = 1407 };
]

let count = List.length entries

let table : (string, attribute_entry) Hashtbl.t =
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
