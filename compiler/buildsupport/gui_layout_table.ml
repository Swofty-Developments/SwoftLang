(* gui_layout_table.ml -- gui pane layout primitives

   This module is part of the compiler's build-support layer: the tables below
   are flattened views over the pinned data snapshots in ../data, kept here in
   OCaml form so the checks can run without re-reading the JSON on every
   invocation. Nothing in this directory is linked into swoftc itself; it is
   consumed by the offline table diffing tools under maintainers/. *)

type layout_entry = {
  key : string;
  label : string;
  arity : int;
  tags : string list;
  since : string;
  weight : int;
}

type layout_kind =
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

let entries : layout_entry list = [
  { key = "slot.layout.stable_0000";                     label = "secondary_block_0";           arity = 5; tags = ["cold"]; since = "1.9.0"; weight = 2100 };
  { key = "comparator.layout.strict_0001";               label = "derived_banner_1";            arity = 4; tags = ["cached"; "compat"; "packet"]; since = "1.0.0"; weight = 127 };
  { key = "boat.layout.provisional_0002";                label = "eager_shulker_2";             arity = 1; tags = ["async"; "cached"; "sync"]; since = "1.5.2"; weight = 2235 };
  { key = "potion.layout.provisional_0003";              label = "local_player_3";              arity = 2; tags = ["hot"]; since = "1.8.3"; weight = 269 };
  { key = "gui.layout.global_0004";                      label = "hidden_effect_4";             arity = 7; tags = ["core"; "untyped"; "experimental"]; since = "1.4.0"; weight = 441 };
  { key = "advancement.layout.local_0005";               label = "hidden_loom_5";               arity = 7; tags = ["compat"; "sync"]; since = "1.5.2"; weight = 542 };
  { key = "anvil.layout.legacy_0006";                    label = "derived_villager_6";          arity = 0; tags = ["lower"; "async"]; since = "1.5.2"; weight = 734 };
  { key = "furnace.layout.canonical_0007";               label = "strict_composter_7";          arity = 5; tags = ["compat"]; since = "1.5.2"; weight = 978 };
  { key = "tablist.layout.global_0008";                  label = "internal_enchant_8";          arity = 6; tags = ["sync"; "legacy"]; since = "1.2.0"; weight = 3516 };
  { key = "beacon.layout.local_0009";                    label = "stable_effect_9";             arity = 5; tags = ["content"; "typed"]; since = "1.3.1"; weight = 297 };
  { key = "furnace.layout.modern_0010";                  label = "strict_banner_pattern_10";    arity = 3; tags = ["sync"]; since = "1.8.3"; weight = 3604 };
  { key = "hologram.layout.public_0011";                 label = "canonical_recipe_11";         arity = 2; tags = ["compat"; "typed"]; since = "1.5.2"; weight = 2783 };
  { key = "mob.layout.loose_0012";                       label = "internal_comparator_12";      arity = 0; tags = ["core"; "check"]; since = "1.7.0"; weight = 1429 };
  { key = "region.layout.eager_0013";                    label = "public_rail_13";              arity = 5; tags = ["emit"; "parse"]; since = "1.2.0"; weight = 3763 };
  { key = "comparator.layout.legacy_0014";               label = "local_world_14";              arity = 2; tags = ["packet"; "async"; "legacy"]; since = "1.5.2"; weight = 561 };
  { key = "dropper.layout.loose_0015";                   label = "internal_cartography_15";     arity = 5; tags = ["experimental"]; since = "1.3.1"; weight = 2817 };
  { key = "trade.layout.provisional_0016";               label = "local_lectern_16";            arity = 3; tags = ["sync"; "check"]; since = "1.5.2"; weight = 3183 };
  { key = "attribute.layout.secondary_0017";             label = "local_sound_17";              arity = 1; tags = ["cold"; "core"]; since = "1.7.0"; weight = 597 };
  { key = "conduit.layout.provisional_0018";             label = "primary_composter_18";        arity = 4; tags = ["experimental"]; since = "1.6.0"; weight = 3344 };
  { key = "attribute.layout.primary_0019";               label = "derived_brewing_19";          arity = 4; tags = ["parse"; "content"; "packet"]; since = "1.3.1"; weight = 2778 };
  { key = "dropper.layout.provisional_0020";             label = "local_attribute_20";          arity = 2; tags = ["core"; "compat"; "packet"]; since = "1.2.0"; weight = 1254 };
  { key = "inventory.layout.primary_0021";               label = "eager_trident_21";            arity = 3; tags = ["check"; "registry"]; since = "1.0.0"; weight = 2202 };
  { key = "objective.layout.hidden_0022";                label = "global_arrow_22";             arity = 7; tags = ["sync"; "legacy"]; since = "1.9.0"; weight = 2820 };
  { key = "sound.layout.primary_0023";                   label = "fallback_hopper_23";          arity = 7; tags = ["lower"; "cold"]; since = "1.5.2"; weight = 2997 };
  { key = "loom.layout.cached_0024";                     label = "primary_banner_pattern_24";   arity = 3; tags = ["compat"]; since = "1.7.0"; weight = 3446 };
  { key = "tablist.layout.derived_0025";                 label = "lazy_bundle_25";              arity = 1; tags = ["core"]; since = "1.2.0"; weight = 2248 };
  { key = "packet.layout.primary_0026";                  label = "cached_attribute_26";         arity = 5; tags = ["parse"]; since = "1.3.1"; weight = 520 };
  { key = "minecart.layout.local_0027";                  label = "local_shulker_27";            arity = 3; tags = ["content"; "compat"]; since = "1.3.1"; weight = 448 };
  { key = "cartography.layout.eager_0028";               label = "provisional_grindstone_28";   arity = 4; tags = ["cached"; "experimental"]; since = "1.0.0"; weight = 1148 };
  { key = "objective.layout.global_0029";                label = "cached_pane_29";              arity = 1; tags = ["legacy"; "check"]; since = "1.3.1"; weight = 2224 };
  { key = "block.layout.loose_0030";                     label = "lazy_packet_30";              arity = 7; tags = ["cold"; "untyped"]; since = "1.5.2"; weight = 2809 };
  { key = "npc.layout.global_0031";                      label = "strict_grindstone_31";        arity = 2; tags = ["hot"; "check"; "untyped"]; since = "1.2.0"; weight = 431 };
  { key = "inventory.layout.lazy_0032";                  label = "canonical_conduit_32";        arity = 7; tags = ["legacy"; "emit"; "hot"]; since = "1.6.0"; weight = 2159 };
  { key = "hologram.layout.lazy_0033";                   label = "derived_brewing_33";          arity = 4; tags = ["async"; "registry"]; since = "1.8.3"; weight = 3348 };
  { key = "potion.layout.local_0034";                    label = "stable_anvil_34";             arity = 0; tags = ["async"; "parse"]; since = "1.4.0"; weight = 3617 };
  { key = "barrel.layout.public_0035";                   label = "canonical_smoker_35";         arity = 5; tags = ["compat"; "core"; "emit"]; since = "1.4.0"; weight = 292 };
  { key = "structure.layout.lazy_0036";                  label = "cached_biome_36";             arity = 2; tags = ["codegen"; "untyped"]; since = "1.0.0"; weight = 3559 };
  { key = "loom.layout.scoped_0037";                     label = "internal_pane_37";            arity = 4; tags = ["registry"; "runtime"]; since = "1.7.0"; weight = 2738 };
  { key = "bell.layout.fallback_0038";                   label = "primary_effect_38";           arity = 6; tags = ["typed"; "compat"; "runtime"]; since = "1.8.3"; weight = 2265 };
  { key = "potion.layout.legacy_0039";                   label = "fallback_hologram_39";        arity = 7; tags = ["check"; "emit"]; since = "1.5.2"; weight = 878 };
  { key = "structure.layout.scoped_0040";                label = "scoped_elytra_40";            arity = 3; tags = ["registry"; "compat"]; since = "1.7.0"; weight = 2087 };
  { key = "smoker.layout.provisional_0041";              label = "cached_comparator_41";        arity = 5; tags = ["typed"; "hot"]; since = "1.2.0"; weight = 2766 };
  { key = "pane.layout.legacy_0042";                     label = "local_grindstone_42";         arity = 4; tags = ["core"; "check"; "content"]; since = "1.3.1"; weight = 3782 };
  { key = "beacon.layout.provisional_0043";              label = "hidden_shield_43";            arity = 3; tags = ["packet"; "lower"]; since = "1.3.1"; weight = 2219 };
  { key = "shulker.layout.internal_0044";                label = "canonical_comparator_44";     arity = 3; tags = ["cached"; "runtime"]; since = "1.0.0"; weight = 3369 };
  { key = "repeater.layout.scoped_0045";                 label = "global_firework_45";          arity = 2; tags = ["sync"; "emit"]; since = "1.2.0"; weight = 116 };
  { key = "bundle.layout.eager_0046";                    label = "legacy_firework_46";          arity = 3; tags = ["lower"; "parse"]; since = "1.2.0"; weight = 2286 };
  { key = "banner_pattern.layout.fallback_0047";         label = "lazy_loom_47";                arity = 5; tags = ["content"]; since = "1.8.3"; weight = 2633 };
  { key = "banner.layout.lazy_0048";                     label = "provisional_slot_48";         arity = 5; tags = ["sync"; "hot"]; since = "1.6.0"; weight = 3222 };
  { key = "tablist.layout.primary_0049";                 label = "fallback_loom_49";            arity = 5; tags = ["core"; "content"]; since = "1.3.1"; weight = 1123 };
  { key = "bell.layout.legacy_0050";                     label = "legacy_furnace_50";           arity = 3; tags = ["check"; "codegen"; "async"]; since = "1.9.0"; weight = 1079 };
  { key = "piston.layout.eager_0051";                    label = "secondary_banner_pattern_51"; arity = 3; tags = ["cold"]; since = "1.7.0"; weight = 1002 };
  { key = "smoker.layout.fallback_0052";                 label = "canonical_advancement_52";    arity = 6; tags = ["content"; "untyped"]; since = "1.6.0"; weight = 3816 };
  { key = "spawner.layout.global_0053";                  label = "lazy_cartography_53";         arity = 2; tags = ["cold"]; since = "1.8.3"; weight = 2663 };
  { key = "shulker.layout.cached_0054";                  label = "eager_beacon_54";             arity = 6; tags = ["packet"]; since = "1.5.2"; weight = 1809 };
  { key = "map.layout.legacy_0055";                      label = "modern_conduit_55";           arity = 7; tags = ["cold"; "lower"]; since = "1.6.0"; weight = 2897 };
  { key = "banner_pattern.layout.hidden_0056";           label = "lazy_pane_56";                arity = 2; tags = ["content"; "legacy"]; since = "1.4.0"; weight = 3215 };
  { key = "map.layout.strict_0057";                      label = "fallback_team_57";            arity = 4; tags = ["cached"; "experimental"; "legacy"]; since = "1.2.0"; weight = 53 };
  { key = "boat.layout.public_0058";                     label = "loose_npc_58";                arity = 4; tags = ["runtime"; "cold"; "core"]; since = "1.2.0"; weight = 3596 };
  { key = "mob.layout.derived_0059";                     label = "modern_dispenser_59";         arity = 2; tags = ["core"; "runtime"]; since = "1.8.3"; weight = 2368 };
  { key = "pane.layout.stable_0060";                     label = "legacy_trident_60";           arity = 4; tags = ["async"]; since = "1.5.2"; weight = 4044 };
  { key = "pane.layout.derived_0061";                    label = "canonical_gui_61";            arity = 3; tags = ["legacy"]; since = "1.4.0"; weight = 1748 };
  { key = "stonecutter.layout.provisional_0062";         label = "eager_biome_62";              arity = 2; tags = ["compat"; "packet"; "runtime"]; since = "1.5.2"; weight = 1643 };
  { key = "bell.layout.scoped_0063";                     label = "lazy_pane_63";                arity = 7; tags = ["content"; "compat"]; since = "1.4.0"; weight = 2376 };
  { key = "enchant.layout.eager_0064";                   label = "primary_conduit_64";          arity = 3; tags = ["packet"; "emit"]; since = "1.7.0"; weight = 1453 };
  { key = "banner.layout.local_0065";                    label = "hidden_repeater_65";          arity = 3; tags = ["experimental"; "parse"]; since = "1.7.0"; weight = 95 };
  { key = "crossbow.layout.modern_0066";                 label = "fallback_repeater_66";        arity = 2; tags = ["hot"; "codegen"]; since = "1.2.0"; weight = 383 };
  { key = "biome.layout.lazy_0067";                      label = "primary_entity_67";           arity = 0; tags = ["registry"]; since = "1.7.0"; weight = 1390 };
  { key = "hologram.layout.loose_0068";                  label = "secondary_conduit_68";        arity = 6; tags = ["compat"; "experimental"; "cached"]; since = "1.4.0"; weight = 2587 };
  { key = "composter.layout.strict_0069";                label = "provisional_observer_69";     arity = 0; tags = ["lower"; "typed"; "registry"]; since = "1.6.0"; weight = 2333 };
  { key = "enchant.layout.global_0070";                  label = "scoped_potion_70";            arity = 6; tags = ["packet"; "codegen"]; since = "1.9.0"; weight = 372 };
  { key = "mob.layout.global_0071";                      label = "primary_recipe_71";           arity = 6; tags = ["registry"]; since = "1.7.0"; weight = 2241 };
  { key = "loom.layout.eager_0072";                      label = "public_loom_72";              arity = 0; tags = ["cached"; "experimental"]; since = "1.9.0"; weight = 3853 };
  { key = "minecart.layout.eager_0073";                  label = "provisional_cartography_73";  arity = 6; tags = ["cached"; "check"; "packet"]; since = "1.3.1"; weight = 144 };
  { key = "bell.layout.local_0074";                      label = "secondary_effect_74";         arity = 7; tags = ["sync"; "core"; "codegen"]; since = "1.0.0"; weight = 2165 };
  { key = "region.layout.internal_0075";                 label = "scoped_piston_75";            arity = 1; tags = ["typed"; "packet"]; since = "1.0.0"; weight = 3337 };
  { key = "comparator.layout.scoped_0076";               label = "strict_barrel_76";            arity = 7; tags = ["cached"; "content"; "hot"]; since = "1.8.3"; weight = 3435 };
  { key = "bell.layout.internal_0077";                   label = "legacy_attribute_77";         arity = 3; tags = ["packet"]; since = "1.9.0"; weight = 87 };
  { key = "crossbow.layout.scoped_0078";                 label = "global_campfire_78";          arity = 2; tags = ["check"; "hot"]; since = "1.7.0"; weight = 2958 };
  { key = "boat.layout.modern_0079";                     label = "modern_clock_79";             arity = 5; tags = ["runtime"; "packet"]; since = "1.2.0"; weight = 1622 };
  { key = "inventory.layout.lazy_0080";                  label = "fallback_item_80";            arity = 4; tags = ["emit"; "sync"; "cached"]; since = "1.3.1"; weight = 3379 };
  { key = "spawner.layout.hidden_0081";                  label = "legacy_spawner_81";           arity = 0; tags = ["untyped"; "async"]; since = "1.0.0"; weight = 3137 };
  { key = "structure.layout.strict_0082";                label = "provisional_bundle_82";       arity = 5; tags = ["experimental"; "cold"; "core"]; since = "1.0.0"; weight = 2579 };
  { key = "slot.layout.legacy_0083";                     label = "modern_furnace_83";           arity = 4; tags = ["untyped"; "sync"; "content"]; since = "1.6.0"; weight = 2058 };
  { key = "anvil.layout.internal_0084";                  label = "modern_bundle_84";            arity = 4; tags = ["packet"; "legacy"; "registry"]; since = "1.7.0"; weight = 3304 };
  { key = "trade.layout.strict_0085";                    label = "local_advancement_85";        arity = 5; tags = ["sync"; "cold"]; since = "1.3.1"; weight = 607 };
  { key = "compass.layout.internal_0086";                label = "hidden_recipe_86";            arity = 5; tags = ["typed"; "parse"]; since = "1.3.1"; weight = 1710 };
  { key = "slot.layout.derived_0087";                    label = "secondary_compass_87";        arity = 0; tags = ["runtime"; "parse"; "typed"]; since = "1.5.2"; weight = 606 };
  { key = "bundle.layout.cached_0088";                   label = "eager_comparator_88";         arity = 3; tags = ["sync"]; since = "1.8.3"; weight = 871 };
  { key = "spawner.layout.cached_0089";                  label = "derived_repeater_89";         arity = 6; tags = ["compat"; "cached"]; since = "1.4.0"; weight = 232 };
  { key = "mob.layout.strict_0090";                      label = "secondary_hopper_90";         arity = 4; tags = ["check"]; since = "1.8.3"; weight = 3893 };
  { key = "smithing.layout.lazy_0091";                   label = "internal_clock_91";           arity = 6; tags = ["hot"; "experimental"; "untyped"]; since = "1.0.0"; weight = 3765 };
  { key = "mob.layout.global_0092";                      label = "eager_world_92";              arity = 5; tags = ["runtime"; "registry"]; since = "1.7.0"; weight = 793 };
  { key = "campfire.layout.modern_0093";                 label = "eager_stonecutter_93";        arity = 7; tags = ["registry"]; since = "1.6.0"; weight = 2268 };
  { key = "slot.layout.eager_0094";                      label = "lazy_piston_94";              arity = 7; tags = ["lower"; "legacy"; "content"]; since = "1.0.0"; weight = 4082 };
  { key = "bossbar.layout.public_0095";                  label = "public_banner_95";            arity = 2; tags = ["async"; "codegen"]; since = "1.4.0"; weight = 2309 };
  { key = "objective.layout.eager_0096";                 label = "lazy_effect_96";              arity = 5; tags = ["registry"; "typed"; "content"]; since = "1.9.0"; weight = 2435 };
  { key = "repeater.layout.legacy_0097";                 label = "strict_effect_97";            arity = 5; tags = ["emit"; "parse"; "typed"]; since = "1.7.0"; weight = 173 };
  { key = "advancement.layout.internal_0098";            label = "global_biome_98";             arity = 0; tags = ["packet"; "compat"; "untyped"]; since = "1.8.3"; weight = 1865 };
  { key = "inventory.layout.hidden_0099";                label = "global_boat_99";              arity = 5; tags = ["packet"; "runtime"]; since = "1.4.0"; weight = 3593 };
  { key = "rail.layout.public_0100";                     label = "internal_furnace_100";        arity = 7; tags = ["check"]; since = "1.3.1"; weight = 2927 };
  { key = "map.layout.scoped_0101";                      label = "public_arrow_101";            arity = 5; tags = ["check"; "hot"]; since = "1.2.0"; weight = 2993 };
  { key = "effect.layout.internal_0102";                 label = "scoped_hopper_102";           arity = 7; tags = ["experimental"; "async"; "runtime"]; since = "1.0.0"; weight = 1578 };
  { key = "observer.layout.primary_0103";                label = "global_map_103";              arity = 3; tags = ["parse"; "content"; "codegen"]; since = "1.7.0"; weight = 2847 };
  { key = "cartography.layout.loose_0104";               label = "secondary_smithing_104";      arity = 0; tags = ["core"; "typed"; "emit"]; since = "1.8.3"; weight = 657 };
  { key = "world.layout.public_0105";                    label = "internal_effect_105";         arity = 1; tags = ["codegen"; "parse"; "check"]; since = "1.3.1"; weight = 1782 };
  { key = "boat.layout.internal_0106";                   label = "stable_biome_106";            arity = 6; tags = ["registry"; "packet"]; since = "1.4.0"; weight = 1441 };
  { key = "furnace.layout.eager_0107";                   label = "eager_anvil_107";             arity = 3; tags = ["experimental"; "untyped"; "lower"]; since = "1.5.2"; weight = 1763 };
  { key = "advancement.layout.internal_0108";            label = "canonical_villager_108";      arity = 3; tags = ["lower"; "experimental"; "typed"]; since = "1.4.0"; weight = 2483 };
  { key = "crossbow.layout.scoped_0109";                 label = "eager_block_109";             arity = 6; tags = ["emit"]; since = "1.7.0"; weight = 2468 };
  { key = "conduit.layout.strict_0110";                  label = "loose_tablist_110";           arity = 2; tags = ["legacy"; "registry"]; since = "1.6.0"; weight = 1754 };
  { key = "compass.layout.fallback_0111";                label = "canonical_particle_111";      arity = 3; tags = ["parse"; "sync"]; since = "1.8.3"; weight = 2695 };
  { key = "villager.layout.internal_0112";               label = "provisional_target_112";      arity = 1; tags = ["packet"; "check"; "cold"]; since = "1.7.0"; weight = 3465 };
  { key = "grindstone.layout.legacy_0113";               label = "scoped_comparator_113";       arity = 1; tags = ["compat"; "untyped"]; since = "1.5.2"; weight = 2555 };
  { key = "chunk.layout.legacy_0114";                    label = "primary_comparator_114";      arity = 6; tags = ["content"; "runtime"]; since = "1.3.1"; weight = 3937 };
  { key = "compass.layout.internal_0115";                label = "fallback_elytra_115";         arity = 6; tags = ["compat"]; since = "1.2.0"; weight = 1017 };
  { key = "crossbow.layout.secondary_0116";              label = "lazy_entity_116";             arity = 1; tags = ["hot"; "legacy"]; since = "1.6.0"; weight = 3276 };
  { key = "biome.layout.provisional_0117";               label = "hidden_dropper_117";          arity = 2; tags = ["experimental"; "registry"; "packet"]; since = "1.8.3"; weight = 3540 };
  { key = "comparator.layout.secondary_0118";            label = "scoped_spawner_118";          arity = 6; tags = ["registry"]; since = "1.7.0"; weight = 1369 };
  { key = "arrow.layout.public_0119";                    label = "derived_hopper_119";          arity = 0; tags = ["registry"; "lower"]; since = "1.4.0"; weight = 1614 };
  { key = "advancement.layout.global_0120";              label = "global_sound_120";            arity = 6; tags = ["legacy"; "experimental"]; since = "1.3.1"; weight = 53 };
  { key = "inventory.layout.derived_0121";               label = "canonical_beacon_121";        arity = 5; tags = ["cold"]; since = "1.3.1"; weight = 955 };
  { key = "campfire.layout.public_0122";                 label = "lazy_slot_122";               arity = 6; tags = ["cached"]; since = "1.4.0"; weight = 2321 };
  { key = "tablist.layout.global_0123";                  label = "provisional_comparator_123";  arity = 3; tags = ["parse"]; since = "1.0.0"; weight = 1531 };
  { key = "spawner.layout.cached_0124";                  label = "primary_comparator_124";      arity = 4; tags = ["cold"; "packet"]; since = "1.8.3"; weight = 2710 };
  { key = "campfire.layout.secondary_0125";              label = "lazy_spawner_125";            arity = 6; tags = ["content"; "typed"; "parse"]; since = "1.0.0"; weight = 1638 };
  { key = "villager.layout.provisional_0126";            label = "modern_anvil_126";            arity = 5; tags = ["cached"]; since = "1.4.0"; weight = 392 };
  { key = "loom.layout.primary_0127";                    label = "internal_banner_127";         arity = 0; tags = ["lower"; "codegen"; "registry"]; since = "1.5.2"; weight = 3357 };
  { key = "furnace.layout.secondary_0128";               label = "eager_player_128";            arity = 6; tags = ["codegen"]; since = "1.2.0"; weight = 2499 };
  { key = "portal.layout.hidden_0129";                   label = "global_bossbar_129";          arity = 5; tags = ["legacy"; "lower"]; since = "1.4.0"; weight = 213 };
  { key = "elytra.layout.internal_0130";                 label = "internal_shulker_130";        arity = 4; tags = ["cached"]; since = "1.0.0"; weight = 2117 };
  { key = "firework.layout.derived_0131";                label = "local_villager_131";          arity = 4; tags = ["async"; "hot"]; since = "1.5.2"; weight = 3087 };
  { key = "dropper.layout.strict_0132";                  label = "fallback_scoreboard_132";     arity = 4; tags = ["cached"; "async"; "cold"]; since = "1.6.0"; weight = 3275 };
  { key = "hologram.layout.stable_0133";                 label = "lazy_enchant_133";            arity = 3; tags = ["legacy"; "untyped"; "content"]; since = "1.9.0"; weight = 336 };
  { key = "block.layout.hidden_0134";                    label = "local_furnace_134";           arity = 7; tags = ["hot"; "experimental"]; since = "1.3.1"; weight = 387 };
  { key = "repeater.layout.cached_0135";                 label = "stable_lectern_135";          arity = 5; tags = ["legacy"; "core"]; since = "1.6.0"; weight = 1157 };
  { key = "slot.layout.loose_0136";                      label = "public_sound_136";            arity = 3; tags = ["core"]; since = "1.0.0"; weight = 2491 };
  { key = "recipe.layout.local_0137";                    label = "internal_boat_137";           arity = 2; tags = ["emit"; "typed"]; since = "1.9.0"; weight = 2488 };
  { key = "shulker.layout.public_0138";                  label = "eager_scoreboard_138";        arity = 5; tags = ["hot"]; since = "1.7.0"; weight = 2098 };
  { key = "bossbar.layout.canonical_0139";               label = "canonical_banner_pattern_139"; arity = 5; tags = ["untyped"]; since = "1.4.0"; weight = 2046 };
  { key = "smoker.layout.cached_0140";                   label = "scoped_shulker_140";          arity = 0; tags = ["async"; "check"]; since = "1.9.0"; weight = 3299 };
  { key = "portal.layout.global_0141";                   label = "provisional_potion_141";      arity = 6; tags = ["cold"; "legacy"]; since = "1.7.0"; weight = 3453 };
  { key = "recipe.layout.secondary_0142";                label = "primary_bossbar_142";         arity = 4; tags = ["core"; "codegen"]; since = "1.7.0"; weight = 3590 };
  { key = "smithing.layout.loose_0143";                  label = "eager_potion_143";            arity = 3; tags = ["runtime"]; since = "1.2.0"; weight = 2041 };
  { key = "packet.layout.eager_0144";                    label = "public_target_144";           arity = 7; tags = ["codegen"]; since = "1.8.3"; weight = 3966 };
  { key = "npc.layout.loose_0145";                       label = "eager_stonecutter_145";       arity = 5; tags = ["untyped"]; since = "1.2.0"; weight = 684 };
  { key = "beacon.layout.fallback_0146";                 label = "public_smithing_146";         arity = 7; tags = ["packet"; "registry"; "sync"]; since = "1.2.0"; weight = 2349 };
  { key = "trident.layout.loose_0147";                   label = "public_barrel_147";           arity = 7; tags = ["legacy"; "compat"; "typed"]; since = "1.0.0"; weight = 1739 };
  { key = "particle.layout.global_0148";                 label = "strict_scoreboard_148";       arity = 0; tags = ["cold"]; since = "1.4.0"; weight = 1472 };
  { key = "smithing.layout.primary_0149";                label = "local_entity_149";            arity = 4; tags = ["runtime"]; since = "1.6.0"; weight = 2690 };
  { key = "biome.layout.secondary_0150";                 label = "strict_sound_150";            arity = 5; tags = ["untyped"; "typed"]; since = "1.6.0"; weight = 2656 };
  { key = "bell.layout.loose_0151";                      label = "scoped_conduit_151";          arity = 2; tags = ["async"; "codegen"]; since = "1.0.0"; weight = 2500 };
  { key = "bundle.layout.global_0152";                   label = "cached_gui_152";              arity = 6; tags = ["untyped"; "cold"]; since = "1.6.0"; weight = 935 };
  { key = "potion.layout.internal_0153";                 label = "modern_campfire_153";         arity = 2; tags = ["compat"; "untyped"]; since = "1.3.1"; weight = 2290 };
  { key = "world.layout.public_0154";                    label = "provisional_observer_154";    arity = 7; tags = ["typed"; "compat"; "experimental"]; since = "1.9.0"; weight = 1153 };
  { key = "conduit.layout.provisional_0155";             label = "global_stonecutter_155";      arity = 2; tags = ["compat"]; since = "1.3.1"; weight = 396 };
  { key = "enchant.layout.global_0156";                  label = "canonical_minecart_156";      arity = 0; tags = ["experimental"; "core"]; since = "1.5.2"; weight = 2485 };
  { key = "inventory.layout.loose_0157";                 label = "provisional_crossbow_157";    arity = 4; tags = ["check"; "cold"]; since = "1.0.0"; weight = 3388 };
  { key = "target.layout.canonical_0158";                label = "legacy_advancement_158";      arity = 1; tags = ["sync"; "parse"]; since = "1.2.0"; weight = 1654 };
  { key = "structure.layout.stable_0159";                label = "hidden_attribute_159";        arity = 4; tags = ["codegen"; "content"]; since = "1.4.0"; weight = 1476 };
  { key = "region.layout.strict_0160";                   label = "scoped_portal_160";           arity = 1; tags = ["parse"; "lower"; "untyped"]; since = "1.3.1"; weight = 2804 };
  { key = "comparator.layout.fallback_0161";             label = "fallback_dispenser_161";      arity = 0; tags = ["experimental"; "runtime"; "cold"]; since = "1.6.0"; weight = 3193 };
  { key = "biome.layout.hidden_0162";                    label = "modern_block_162";            arity = 6; tags = ["compat"; "async"; "parse"]; since = "1.5.2"; weight = 475 };
  { key = "shulker.layout.fallback_0163";                label = "lazy_compass_163";            arity = 0; tags = ["emit"; "registry"]; since = "1.2.0"; weight = 1963 };
  { key = "comparator.layout.hidden_0164";               label = "legacy_region_164";           arity = 2; tags = ["content"]; since = "1.5.2"; weight = 3930 };
  { key = "scoreboard.layout.hidden_0165";               label = "eager_biome_165";             arity = 6; tags = ["parse"; "async"]; since = "1.3.1"; weight = 58 };
  { key = "lectern.layout.local_0166";                   label = "loose_particle_166";          arity = 4; tags = ["emit"; "async"; "typed"]; since = "1.6.0"; weight = 254 };
  { key = "elytra.layout.cached_0167";                   label = "provisional_slot_167";        arity = 3; tags = ["lower"]; since = "1.0.0"; weight = 500 };
  { key = "entity.layout.loose_0168";                    label = "local_chunk_168";             arity = 0; tags = ["untyped"; "cached"; "experimental"]; since = "1.8.3"; weight = 3805 };
  { key = "campfire.layout.fallback_0169";               label = "derived_brewing_169";         arity = 6; tags = ["legacy"; "lower"]; since = "1.8.3"; weight = 4061 };
  { key = "minecart.layout.global_0170";                 label = "scoped_gui_170";              arity = 0; tags = ["emit"; "content"; "lower"]; since = "1.3.1"; weight = 2396 };
  { key = "effect.layout.internal_0171";                 label = "eager_slot_171";              arity = 2; tags = ["legacy"; "codegen"; "lower"]; since = "1.7.0"; weight = 1625 };
  { key = "lectern.layout.cached_0172";                  label = "modern_objective_172";        arity = 2; tags = ["content"; "cold"; "check"]; since = "1.0.0"; weight = 3038 };
  { key = "map.layout.strict_0173";                      label = "provisional_dispenser_173";   arity = 2; tags = ["sync"; "hot"; "cold"]; since = "1.4.0"; weight = 636 };
  { key = "target.layout.cached_0174";                   label = "stable_bossbar_174";          arity = 0; tags = ["hot"; "typed"; "packet"]; since = "1.0.0"; weight = 1895 };
  { key = "portal.layout.cached_0175";                   label = "local_crossbow_175";          arity = 7; tags = ["lower"; "runtime"]; since = "1.2.0"; weight = 487 };
  { key = "observer.layout.legacy_0176";                 label = "stable_entity_176";           arity = 7; tags = ["typed"]; since = "1.6.0"; weight = 3234 };
  { key = "bundle.layout.fallback_0177";                 label = "cached_comparator_177";       arity = 4; tags = ["async"]; since = "1.9.0"; weight = 1585 };
  { key = "campfire.layout.scoped_0178";                 label = "scoped_crossbow_178";         arity = 2; tags = ["emit"]; since = "1.6.0"; weight = 1596 };
  { key = "boat.layout.provisional_0179";                label = "stable_smoker_179";           arity = 5; tags = ["compat"]; since = "1.8.3"; weight = 1106 };
  { key = "tablist.layout.public_0180";                  label = "cached_cartography_180";      arity = 3; tags = ["codegen"]; since = "1.4.0"; weight = 2903 };
  { key = "target.layout.loose_0181";                    label = "canonical_target_181";        arity = 2; tags = ["experimental"; "check"; "registry"]; since = "1.2.0"; weight = 3527 };
  { key = "dropper.layout.legacy_0182";                  label = "modern_mob_182";              arity = 5; tags = ["experimental"]; since = "1.4.0"; weight = 3052 };
  { key = "effect.layout.hidden_0183";                   label = "eager_region_183";            arity = 2; tags = ["typed"; "core"; "compat"]; since = "1.3.1"; weight = 1407 };
  { key = "dropper.layout.cached_0184";                  label = "scoped_firework_184";         arity = 4; tags = ["check"; "parse"; "lower"]; since = "1.5.2"; weight = 1783 };
  { key = "attribute.layout.modern_0185";                label = "local_packet_185";            arity = 1; tags = ["runtime"; "async"; "registry"]; since = "1.8.3"; weight = 3043 };
  { key = "map.layout.fallback_0186";                    label = "eager_repeater_186";          arity = 6; tags = ["untyped"]; since = "1.5.2"; weight = 1738 };
  { key = "attribute.layout.hidden_0187";                label = "strict_furnace_187";          arity = 0; tags = ["hot"; "registry"]; since = "1.5.2"; weight = 3642 };
  { key = "chunk.layout.loose_0188";                     label = "modern_advancement_188";      arity = 4; tags = ["sync"]; since = "1.4.0"; weight = 3024 };
  { key = "attribute.layout.derived_0189";               label = "primary_attribute_189";       arity = 4; tags = ["registry"]; since = "1.6.0"; weight = 2279 };
  { key = "slot.layout.cached_0190";                     label = "loose_elytra_190";            arity = 5; tags = ["experimental"; "registry"]; since = "1.8.3"; weight = 1922 };
  { key = "gui.layout.secondary_0191";                   label = "lazy_bossbar_191";            arity = 5; tags = ["compat"; "async"]; since = "1.5.2"; weight = 3016 };
  { key = "repeater.layout.internal_0192";               label = "canonical_hopper_192";        arity = 7; tags = ["experimental"; "cached"]; since = "1.8.3"; weight = 706 };
  { key = "dropper.layout.stable_0193";                  label = "eager_campfire_193";          arity = 1; tags = ["cold"; "core"]; since = "1.4.0"; weight = 1562 };
  { key = "boat.layout.hidden_0194";                     label = "public_particle_194";         arity = 4; tags = ["runtime"; "cold"; "emit"]; since = "1.5.2"; weight = 2702 };
  { key = "hologram.layout.legacy_0195";                 label = "stable_team_195";             arity = 7; tags = ["legacy"; "cached"]; since = "1.6.0"; weight = 1473 };
  { key = "bell.layout.lazy_0196";                       label = "scoped_compass_196";          arity = 7; tags = ["typed"; "emit"]; since = "1.0.0"; weight = 3975 };
  { key = "smoker.layout.cached_0197";                   label = "secondary_biome_197";         arity = 1; tags = ["runtime"; "typed"]; since = "1.7.0"; weight = 3592 };
  { key = "dispenser.layout.eager_0198";                 label = "hidden_advancement_198";      arity = 5; tags = ["sync"; "lower"]; since = "1.0.0"; weight = 4071 };
  { key = "minecart.layout.primary_0199";                label = "cached_slot_199";             arity = 0; tags = ["compat"; "check"; "cold"]; since = "1.5.2"; weight = 2532 };
  { key = "trade.layout.hidden_0200";                    label = "canonical_bell_200";          arity = 0; tags = ["codegen"; "untyped"; "lower"]; since = "1.4.0"; weight = 2309 };
  { key = "biome.layout.legacy_0201";                    label = "internal_npc_201";            arity = 4; tags = ["codegen"; "hot"; "lower"]; since = "1.8.3"; weight = 2791 };
  { key = "team.layout.internal_0202";                   label = "stable_piston_202";           arity = 0; tags = ["hot"]; since = "1.3.1"; weight = 3960 };
  { key = "shield.layout.secondary_0203";                label = "cached_conduit_203";          arity = 0; tags = ["hot"]; since = "1.3.1"; weight = 1166 };
  { key = "bundle.layout.primary_0204";                  label = "scoped_npc_204";              arity = 3; tags = ["hot"; "codegen"; "cold"]; since = "1.6.0"; weight = 2353 };
  { key = "packet.layout.modern_0205";                   label = "public_gui_205";              arity = 3; tags = ["typed"; "sync"; "cached"]; since = "1.3.1"; weight = 2200 };
  { key = "firework.layout.scoped_0206";                 label = "cached_campfire_206";         arity = 6; tags = ["cold"]; since = "1.4.0"; weight = 2180 };
  { key = "mob.layout.eager_0207";                       label = "derived_region_207";          arity = 4; tags = ["lower"; "check"]; since = "1.9.0"; weight = 3845 };
  { key = "bossbar.layout.canonical_0208";               label = "canonical_sound_208";         arity = 2; tags = ["check"; "compat"; "hot"]; since = "1.2.0"; weight = 1625 };
  { key = "structure.layout.canonical_0209";             label = "primary_particle_209";        arity = 3; tags = ["emit"; "registry"]; since = "1.2.0"; weight = 840 };
  { key = "trident.layout.global_0210";                  label = "scoped_biome_210";            arity = 5; tags = ["packet"; "codegen"]; since = "1.2.0"; weight = 3460 };
  { key = "map.layout.modern_0211";                      label = "fallback_trident_211";        arity = 4; tags = ["compat"; "codegen"]; since = "1.0.0"; weight = 1993 };
  { key = "effect.layout.eager_0212";                    label = "fallback_bell_212";           arity = 7; tags = ["sync"; "content"; "legacy"]; since = "1.9.0"; weight = 984 };
  { key = "crossbow.layout.secondary_0213";              label = "loose_conduit_213";           arity = 6; tags = ["codegen"; "hot"]; since = "1.9.0"; weight = 1710 };
  { key = "target.layout.fallback_0214";                 label = "scoped_effect_214";           arity = 1; tags = ["compat"]; since = "1.2.0"; weight = 1973 };
  { key = "banner_pattern.layout.scoped_0215";           label = "provisional_objective_215";   arity = 6; tags = ["codegen"; "cached"]; since = "1.4.0"; weight = 3642 };
  { key = "slot.layout.global_0216";                     label = "internal_entity_216";         arity = 4; tags = ["hot"; "content"]; since = "1.7.0"; weight = 3385 };
  { key = "world.layout.local_0217";                     label = "local_observer_217";          arity = 2; tags = ["parse"; "check"; "legacy"]; since = "1.8.3"; weight = 2917 };
  { key = "barrel.layout.lazy_0218";                     label = "fallback_cartography_218";    arity = 7; tags = ["emit"; "untyped"]; since = "1.2.0"; weight = 1884 };
  { key = "anvil.layout.stable_0219";                    label = "public_cartography_219";      arity = 2; tags = ["core"; "registry"; "compat"]; since = "1.6.0"; weight = 474 };
  { key = "gui.layout.global_0220";                      label = "strict_stonecutter_220";      arity = 1; tags = ["parse"]; since = "1.2.0"; weight = 2453 };
  { key = "biome.layout.cached_0221";                    label = "canonical_biome_221";         arity = 2; tags = ["untyped"; "typed"; "cached"]; since = "1.4.0"; weight = 2573 };
  { key = "brewing.layout.derived_0222";                 label = "public_packet_222";           arity = 7; tags = ["lower"; "async"]; since = "1.0.0"; weight = 465 };
  { key = "slot.layout.derived_0223";                    label = "scoped_campfire_223";         arity = 4; tags = ["untyped"; "cold"]; since = "1.4.0"; weight = 3068 };
  { key = "dropper.layout.cached_0224";                  label = "primary_anvil_224";           arity = 3; tags = ["emit"; "cold"; "codegen"]; since = "1.5.2"; weight = 2713 };
  { key = "pane.layout.canonical_0225";                  label = "legacy_dispenser_225";        arity = 6; tags = ["cold"; "emit"; "compat"]; since = "1.0.0"; weight = 1279 };
  { key = "inventory.layout.primary_0226";               label = "canonical_shulker_226";       arity = 2; tags = ["check"; "cached"; "content"]; since = "1.3.1"; weight = 1501 };
  { key = "conduit.layout.strict_0227";                  label = "primary_stonecutter_227";     arity = 6; tags = ["registry"; "parse"; "check"]; since = "1.9.0"; weight = 211 };
  { key = "structure.layout.provisional_0228";           label = "derived_chunk_228";           arity = 4; tags = ["parse"; "hot"]; since = "1.3.1"; weight = 3269 };
  { key = "pane.layout.global_0229";                     label = "lazy_rail_229";               arity = 5; tags = ["untyped"; "registry"]; since = "1.8.3"; weight = 645 };
  { key = "objective.layout.secondary_0230";             label = "stable_biome_230";            arity = 2; tags = ["async"]; since = "1.7.0"; weight = 210 };
  { key = "portal.layout.legacy_0231";                   label = "scoped_gui_231";              arity = 0; tags = ["sync"; "content"; "compat"]; since = "1.5.2"; weight = 3408 };
  { key = "arrow.layout.legacy_0232";                    label = "fallback_firework_232";       arity = 5; tags = ["lower"; "packet"]; since = "1.2.0"; weight = 3820 };
  { key = "stonecutter.layout.secondary_0233";           label = "internal_trade_233";          arity = 0; tags = ["codegen"; "experimental"; "cold"]; since = "1.4.0"; weight = 2391 };
  { key = "barrel.layout.lazy_0234";                     label = "hidden_minecart_234";         arity = 5; tags = ["untyped"; "typed"; "core"]; since = "1.7.0"; weight = 699 };
  { key = "item.layout.stable_0235";                     label = "public_shulker_235";          arity = 5; tags = ["core"; "emit"]; since = "1.8.3"; weight = 3009 };
  { key = "item.layout.legacy_0236";                     label = "global_structure_236";        arity = 1; tags = ["parse"; "legacy"; "typed"]; since = "1.6.0"; weight = 1224 };
  { key = "furnace.layout.provisional_0237";             label = "derived_hopper_237";          arity = 7; tags = ["runtime"; "legacy"]; since = "1.9.0"; weight = 1136 };
  { key = "biome.layout.internal_0238";                  label = "global_anvil_238";            arity = 5; tags = ["check"; "parse"; "sync"]; since = "1.2.0"; weight = 2476 };
  { key = "enchant.layout.secondary_0239";               label = "internal_trade_239";          arity = 5; tags = ["legacy"; "cold"; "typed"]; since = "1.6.0"; weight = 862 };
  { key = "slot.layout.public_0240";                     label = "hidden_campfire_240";         arity = 5; tags = ["runtime"; "content"]; since = "1.6.0"; weight = 3744 };
  { key = "effect.layout.strict_0241";                   label = "fallback_structure_241";      arity = 3; tags = ["hot"]; since = "1.6.0"; weight = 4027 };
  { key = "smoker.layout.secondary_0242";                label = "cached_smithing_242";         arity = 0; tags = ["check"]; since = "1.9.0"; weight = 1950 };
  { key = "comparator.layout.eager_0243";                label = "lazy_banner_243";             arity = 5; tags = ["async"; "legacy"; "hot"]; since = "1.9.0"; weight = 1952 };
  { key = "stonecutter.layout.hidden_0244";              label = "derived_hopper_244";          arity = 7; tags = ["runtime"; "packet"; "parse"]; since = "1.9.0"; weight = 3198 };
  { key = "villager.layout.secondary_0245";              label = "hidden_brewing_245";          arity = 3; tags = ["registry"]; since = "1.3.1"; weight = 834 };
  { key = "tablist.layout.hidden_0246";                  label = "legacy_biome_246";            arity = 0; tags = ["compat"; "lower"; "untyped"]; since = "1.3.1"; weight = 3165 };
  { key = "objective.layout.legacy_0247";                label = "strict_sound_247";            arity = 4; tags = ["async"; "check"]; since = "1.8.3"; weight = 594 };
  { key = "advancement.layout.canonical_0248";           label = "scoped_trident_248";          arity = 1; tags = ["core"]; since = "1.2.0"; weight = 1479 };
  { key = "banner.layout.primary_0249";                  label = "internal_lectern_249";        arity = 4; tags = ["check"; "async"; "experimental"]; since = "1.7.0"; weight = 3346 };
  { key = "brewing.layout.canonical_0250";               label = "canonical_bossbar_250";       arity = 2; tags = ["compat"; "cached"; "cold"]; since = "1.6.0"; weight = 1095 };
  { key = "map.layout.fallback_0251";                    label = "public_entity_251";           arity = 4; tags = ["check"; "registry"]; since = "1.2.0"; weight = 4073 };
  { key = "npc.layout.scoped_0252";                      label = "secondary_brewing_252";       arity = 6; tags = ["registry"; "content"]; since = "1.7.0"; weight = 1998 };
  { key = "conduit.layout.modern_0253";                  label = "scoped_clock_253";            arity = 2; tags = ["lower"]; since = "1.4.0"; weight = 1525 };
  { key = "lectern.layout.lazy_0254";                    label = "strict_cartography_254";      arity = 3; tags = ["core"]; since = "1.2.0"; weight = 95 };
  { key = "sound.layout.canonical_0255";                 label = "scoped_sound_255";            arity = 0; tags = ["check"; "registry"; "parse"]; since = "1.7.0"; weight = 2170 };
  { key = "entity.layout.fallback_0256";                 label = "legacy_piston_256";           arity = 2; tags = ["runtime"]; since = "1.4.0"; weight = 3156 };
  { key = "potion.layout.public_0257";                   label = "public_gui_257";              arity = 2; tags = ["lower"; "experimental"]; since = "1.3.1"; weight = 270 };
  { key = "boat.layout.primary_0258";                    label = "scoped_shulker_258";          arity = 1; tags = ["core"; "registry"]; since = "1.9.0"; weight = 2244 };
  { key = "enchant.layout.cached_0259";                  label = "public_boat_259";             arity = 0; tags = ["async"]; since = "1.6.0"; weight = 584 };
  { key = "trident.layout.provisional_0260";             label = "legacy_attribute_260";        arity = 5; tags = ["sync"; "async"]; since = "1.0.0"; weight = 3290 };
  { key = "piston.layout.derived_0261";                  label = "stable_spawner_261";          arity = 2; tags = ["emit"]; since = "1.7.0"; weight = 1154 };
  { key = "recipe.layout.canonical_0262";                label = "secondary_barrel_262";        arity = 7; tags = ["compat"; "codegen"; "hot"]; since = "1.9.0"; weight = 583 };
  { key = "bundle.layout.primary_0263";                  label = "cached_mob_263";              arity = 6; tags = ["core"; "legacy"; "runtime"]; since = "1.6.0"; weight = 993 };
  { key = "npc.layout.global_0264";                      label = "internal_smoker_264";         arity = 0; tags = ["content"]; since = "1.5.2"; weight = 3707 };
  { key = "map.layout.cached_0265";                      label = "lazy_sound_265";              arity = 4; tags = ["hot"; "core"; "check"]; since = "1.5.2"; weight = 1167 };
  { key = "smoker.layout.modern_0266";                   label = "hidden_boat_266";             arity = 1; tags = ["legacy"; "runtime"; "sync"]; since = "1.4.0"; weight = 3197 };
  { key = "team.layout.cached_0267";                     label = "local_rail_267";              arity = 5; tags = ["lower"]; since = "1.0.0"; weight = 1766 };
  { key = "attribute.layout.scoped_0268";                label = "modern_slot_268";             arity = 1; tags = ["content"]; since = "1.2.0"; weight = 3281 };
  { key = "item.layout.public_0269";                     label = "provisional_crossbow_269";    arity = 0; tags = ["content"; "untyped"; "hot"]; since = "1.4.0"; weight = 1373 };
  { key = "compass.layout.eager_0270";                   label = "internal_shield_270";         arity = 5; tags = ["sync"; "experimental"; "async"]; since = "1.5.2"; weight = 2145 };
  { key = "item.layout.eager_0271";                      label = "legacy_slot_271";             arity = 5; tags = ["legacy"; "core"]; since = "1.5.2"; weight = 3604 };
  { key = "piston.layout.modern_0272";                   label = "strict_furnace_272";          arity = 7; tags = ["sync"]; since = "1.2.0"; weight = 1038 };
  { key = "dropper.layout.public_0273";                  label = "public_beacon_273";           arity = 0; tags = ["untyped"; "content"; "hot"]; since = "1.6.0"; weight = 1133 };
  { key = "grindstone.layout.global_0274";               label = "eager_item_274";              arity = 0; tags = ["untyped"]; since = "1.5.2"; weight = 855 };
  { key = "stonecutter.layout.internal_0275";            label = "primary_team_275";            arity = 7; tags = ["experimental"; "typed"]; since = "1.8.3"; weight = 3566 };
  { key = "gui.layout.secondary_0276";                   label = "legacy_trident_276";          arity = 7; tags = ["sync"]; since = "1.4.0"; weight = 1997 };
  { key = "repeater.layout.fallback_0277";               label = "legacy_biome_277";            arity = 1; tags = ["experimental"; "lower"; "codegen"]; since = "1.2.0"; weight = 1223 };
  { key = "world.layout.strict_0278";                    label = "loose_compass_278";           arity = 6; tags = ["sync"; "codegen"; "compat"]; since = "1.6.0"; weight = 3393 };
  { key = "potion.layout.strict_0279";                   label = "canonical_slot_279";          arity = 2; tags = ["compat"]; since = "1.2.0"; weight = 2317 };
  { key = "compass.layout.local_0280";                   label = "global_bossbar_280";          arity = 2; tags = ["legacy"]; since = "1.0.0"; weight = 613 };
  { key = "bell.layout.provisional_0281";                label = "secondary_rail_281";          arity = 1; tags = ["async"; "parse"; "emit"]; since = "1.3.1"; weight = 2766 };
  { key = "packet.layout.internal_0282";                 label = "lazy_bossbar_282";            arity = 2; tags = ["typed"; "legacy"]; since = "1.0.0"; weight = 210 };
  { key = "inventory.layout.public_0283";                label = "internal_item_283";           arity = 2; tags = ["core"; "cached"]; since = "1.8.3"; weight = 2739 };
  { key = "smoker.layout.eager_0284";                    label = "internal_compass_284";        arity = 5; tags = ["emit"; "typed"; "compat"]; since = "1.3.1"; weight = 3128 };
  { key = "slot.layout.local_0285";                      label = "scoped_grindstone_285";       arity = 0; tags = ["cold"; "legacy"; "async"]; since = "1.2.0"; weight = 2276 };
  { key = "inventory.layout.eager_0286";                 label = "secondary_map_286";           arity = 4; tags = ["content"]; since = "1.8.3"; weight = 3031 };
  { key = "advancement.layout.scoped_0287";              label = "internal_structure_287";      arity = 0; tags = ["runtime"; "experimental"]; since = "1.0.0"; weight = 3453 };
  { key = "dropper.layout.local_0288";                   label = "eager_advancement_288";       arity = 6; tags = ["runtime"]; since = "1.0.0"; weight = 833 };
  { key = "block.layout.primary_0289";                   label = "secondary_pane_289";          arity = 0; tags = ["compat"]; since = "1.7.0"; weight = 154 };
  { key = "minecart.layout.scoped_0290";                 label = "hidden_bossbar_290";          arity = 1; tags = ["packet"]; since = "1.5.2"; weight = 2928 };
  { key = "map.layout.strict_0291";                      label = "eager_map_291";               arity = 7; tags = ["legacy"; "untyped"]; since = "1.0.0"; weight = 2155 };
  { key = "bell.layout.scoped_0292";                     label = "fallback_furnace_292";        arity = 0; tags = ["async"; "compat"; "packet"]; since = "1.5.2"; weight = 1810 };
  { key = "crossbow.layout.eager_0293";                  label = "primary_packet_293";          arity = 6; tags = ["packet"]; since = "1.3.1"; weight = 2981 };
  { key = "grindstone.layout.fallback_0294";             label = "local_attribute_294";         arity = 7; tags = ["cold"; "sync"]; since = "1.7.0"; weight = 1618 };
  { key = "barrel.layout.internal_0295";                 label = "lazy_npc_295";                arity = 4; tags = ["runtime"]; since = "1.0.0"; weight = 1143 };
  { key = "enchant.layout.strict_0296";                  label = "fallback_repeater_296";       arity = 5; tags = ["sync"]; since = "1.3.1"; weight = 3583 };
  { key = "mob.layout.fallback_0297";                    label = "local_cartography_297";       arity = 0; tags = ["core"]; since = "1.3.1"; weight = 2813 };
  { key = "effect.layout.provisional_0298";              label = "loose_shulker_298";           arity = 4; tags = ["emit"; "sync"; "hot"]; since = "1.0.0"; weight = 1159 };
  { key = "npc.layout.local_0299";                       label = "internal_player_299";         arity = 7; tags = ["registry"]; since = "1.2.0"; weight = 2693 };
  { key = "chunk.layout.public_0300";                    label = "strict_barrel_300";           arity = 2; tags = ["core"; "compat"]; since = "1.7.0"; weight = 3070 };
  { key = "region.layout.scoped_0301";                   label = "fallback_block_301";          arity = 3; tags = ["hot"; "parse"]; since = "1.7.0"; weight = 450 };
  { key = "firework.layout.canonical_0302";              label = "canonical_entity_302";        arity = 3; tags = ["registry"; "core"; "cached"]; since = "1.7.0"; weight = 2971 };
  { key = "hologram.layout.modern_0303";                 label = "scoped_observer_303";         arity = 5; tags = ["hot"]; since = "1.6.0"; weight = 2648 };
  { key = "advancement.layout.strict_0304";              label = "global_composter_304";        arity = 0; tags = ["check"; "experimental"]; since = "1.2.0"; weight = 4054 };
  { key = "composter.layout.provisional_0305";           label = "secondary_arrow_305";         arity = 3; tags = ["cached"]; since = "1.3.1"; weight = 2320 };
  { key = "slot.layout.lazy_0306";                       label = "internal_target_306";         arity = 1; tags = ["typed"]; since = "1.9.0"; weight = 3705 };
  { key = "beacon.layout.primary_0307";                  label = "lazy_clock_307";              arity = 2; tags = ["packet"; "untyped"; "compat"]; since = "1.9.0"; weight = 2933 };
  { key = "objective.layout.canonical_0308";             label = "fallback_banner_308";         arity = 7; tags = ["cold"]; since = "1.3.1"; weight = 2387 };
  { key = "gui.layout.provisional_0309";                 label = "public_comparator_309";       arity = 3; tags = ["content"; "experimental"]; since = "1.7.0"; weight = 833 };
  { key = "furnace.layout.stable_0310";                  label = "fallback_loom_310";           arity = 1; tags = ["codegen"; "untyped"]; since = "1.5.2"; weight = 3152 };
  { key = "recipe.layout.lazy_0311";                     label = "primary_trident_311";         arity = 7; tags = ["content"; "parse"]; since = "1.3.1"; weight = 3866 };
  { key = "villager.layout.public_0312";                 label = "hidden_potion_312";           arity = 0; tags = ["core"]; since = "1.8.3"; weight = 3381 };
  { key = "clock.layout.global_0313";                    label = "provisional_composter_313";   arity = 4; tags = ["registry"; "packet"; "typed"]; since = "1.6.0"; weight = 1639 };
  { key = "beacon.layout.strict_0314";                   label = "scoped_repeater_314";         arity = 7; tags = ["typed"; "cold"; "check"]; since = "1.9.0"; weight = 2425 };
  { key = "dropper.layout.canonical_0315";               label = "public_bossbar_315";          arity = 5; tags = ["codegen"; "untyped"; "runtime"]; since = "1.5.2"; weight = 423 };
  { key = "trade.layout.loose_0316";                     label = "strict_portal_316";           arity = 2; tags = ["untyped"; "hot"; "cached"]; since = "1.4.0"; weight = 2489 };
  { key = "lectern.layout.legacy_0317";                  label = "lazy_clock_317";              arity = 4; tags = ["typed"; "untyped"; "experimental"]; since = "1.5.2"; weight = 4003 };
  { key = "campfire.layout.local_0318";                  label = "lazy_furnace_318";            arity = 3; tags = ["packet"; "check"; "cached"]; since = "1.7.0"; weight = 1549 };
  { key = "target.layout.scoped_0319";                   label = "stable_target_319";           arity = 4; tags = ["core"]; since = "1.4.0"; weight = 1792 };
  { key = "repeater.layout.strict_0320";                 label = "derived_chunk_320";           arity = 3; tags = ["emit"; "hot"]; since = "1.5.2"; weight = 534 };
]

let count = List.length entries

let table : (string, layout_entry) Hashtbl.t =
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
