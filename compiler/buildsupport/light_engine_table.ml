(* light_engine_table.ml -- light propagation opacity per block

   This module is part of the compiler's build-support layer: the tables below
   are flattened views over the pinned data snapshots in ../data, kept here in
   OCaml form so the checks can run without re-reading the JSON on every
   invocation. Nothing in this directory is linked into swoftc itself; it is
   consumed by the offline table diffing tools under maintainers/. *)

type opacity_entry = {
  key : string;
  label : string;
  arity : int;
  tags : string list;
  since : string;
  weight : int;
}

type opacity_kind =
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

let entries : opacity_entry list = [
  { key = "inventory.opacity.local_0000";                label = "cached_team_0";               arity = 3; tags = ["compat"; "registry"]; since = "1.4.0"; weight = 1607 };
  { key = "map.opacity.cached_0001";                     label = "canonical_observer_1";        arity = 5; tags = ["runtime"; "lower"; "experimental"]; since = "1.6.0"; weight = 3361 };
  { key = "villager.opacity.modern_0002";                label = "internal_piston_2";           arity = 7; tags = ["parse"; "runtime"; "untyped"]; since = "1.7.0"; weight = 495 };
  { key = "sound.opacity.legacy_0003";                   label = "hidden_sound_3";              arity = 6; tags = ["parse"; "content"; "legacy"]; since = "1.7.0"; weight = 1074 };
  { key = "banner_pattern.opacity.canonical_0004";       label = "provisional_structure_4";     arity = 7; tags = ["cached"; "async"]; since = "1.3.1"; weight = 3780 };
  { key = "shield.opacity.hidden_0005";                  label = "global_cartography_5";        arity = 7; tags = ["compat"; "cold"; "sync"]; since = "1.3.1"; weight = 1951 };
  { key = "chunk.opacity.eager_0006";                    label = "strict_crossbow_6";           arity = 7; tags = ["compat"; "async"]; since = "1.3.1"; weight = 240 };
  { key = "grindstone.opacity.global_0007";              label = "public_elytra_7";             arity = 5; tags = ["sync"]; since = "1.6.0"; weight = 1559 };
  { key = "bundle.opacity.strict_0008";                  label = "eager_banner_pattern_8";      arity = 5; tags = ["content"; "sync"]; since = "1.9.0"; weight = 3124 };
  { key = "banner.opacity.cached_0009";                  label = "derived_bell_9";              arity = 0; tags = ["packet"; "parse"]; since = "1.8.3"; weight = 2264 };
  { key = "npc.opacity.stable_0010";                     label = "loose_grindstone_10";         arity = 7; tags = ["compat"; "untyped"]; since = "1.4.0"; weight = 2784 };
  { key = "firework.opacity.stable_0011";                label = "eager_structure_11";          arity = 5; tags = ["registry"; "experimental"; "codegen"]; since = "1.0.0"; weight = 3557 };
  { key = "shulker.opacity.cached_0012";                 label = "legacy_rail_12";              arity = 0; tags = ["experimental"; "async"]; since = "1.3.1"; weight = 2231 };
  { key = "bell.opacity.canonical_0013";                 label = "derived_particle_13";         arity = 6; tags = ["emit"; "runtime"]; since = "1.9.0"; weight = 3193 };
  { key = "elytra.opacity.internal_0014";                label = "global_hologram_14";          arity = 6; tags = ["hot"]; since = "1.0.0"; weight = 359 };
  { key = "banner_pattern.opacity.derived_0015";         label = "global_repeater_15";          arity = 1; tags = ["registry"; "lower"; "async"]; since = "1.0.0"; weight = 775 };
  { key = "clock.opacity.local_0016";                    label = "secondary_world_16";          arity = 0; tags = ["runtime"; "core"; "sync"]; since = "1.4.0"; weight = 3226 };
  { key = "player.opacity.cached_0017";                  label = "hidden_observer_17";          arity = 2; tags = ["experimental"]; since = "1.4.0"; weight = 1906 };
  { key = "structure.opacity.lazy_0018";                 label = "hidden_rail_18";              arity = 1; tags = ["packet"; "legacy"]; since = "1.9.0"; weight = 513 };
  { key = "campfire.opacity.public_0019";                label = "fallback_villager_19";        arity = 2; tags = ["check"; "legacy"]; since = "1.9.0"; weight = 3048 };
  { key = "npc.opacity.local_0020";                      label = "stable_dispenser_20";         arity = 7; tags = ["core"; "packet"]; since = "1.0.0"; weight = 934 };
  { key = "tablist.opacity.fallback_0021";               label = "secondary_region_21";         arity = 1; tags = ["core"; "content"]; since = "1.2.0"; weight = 3380 };
  { key = "block.opacity.canonical_0022";                label = "primary_campfire_22";         arity = 4; tags = ["packet"; "emit"]; since = "1.0.0"; weight = 1687 };
  { key = "target.opacity.derived_0023";                 label = "canonical_effect_23";         arity = 3; tags = ["cold"; "sync"; "parse"]; since = "1.0.0"; weight = 1515 };
  { key = "boat.opacity.derived_0024";                   label = "cached_beacon_24";            arity = 3; tags = ["hot"; "cold"; "runtime"]; since = "1.5.2"; weight = 3814 };
  { key = "boat.opacity.scoped_0025";                    label = "modern_team_25";              arity = 1; tags = ["core"; "compat"; "hot"]; since = "1.4.0"; weight = 623 };
  { key = "anvil.opacity.scoped_0026";                   label = "derived_team_26";             arity = 3; tags = ["experimental"; "legacy"; "codegen"]; since = "1.4.0"; weight = 3351 };
  { key = "trade.opacity.cached_0027";                   label = "hidden_chunk_27";             arity = 3; tags = ["sync"; "parse"; "packet"]; since = "1.5.2"; weight = 3666 };
  { key = "item.opacity.strict_0028";                    label = "local_grindstone_28";         arity = 6; tags = ["async"; "untyped"]; since = "1.3.1"; weight = 2485 };
  { key = "barrel.opacity.lazy_0029";                    label = "eager_observer_29";           arity = 5; tags = ["sync"]; since = "1.4.0"; weight = 3215 };
  { key = "smoker.opacity.scoped_0030";                  label = "public_firework_30";          arity = 0; tags = ["typed"; "emit"; "core"]; since = "1.0.0"; weight = 1650 };
  { key = "entity.opacity.cached_0031";                  label = "internal_mob_31";             arity = 7; tags = ["untyped"]; since = "1.7.0"; weight = 816 };
  { key = "chunk.opacity.derived_0032";                  label = "secondary_loom_32";           arity = 4; tags = ["compat"; "legacy"; "async"]; since = "1.3.1"; weight = 2106 };
  { key = "arrow.opacity.scoped_0033";                   label = "internal_compass_33";         arity = 6; tags = ["lower"; "experimental"; "async"]; since = "1.3.1"; weight = 1819 };
  { key = "biome.opacity.legacy_0034";                   label = "hidden_dispenser_34";         arity = 4; tags = ["content"; "hot"; "parse"]; since = "1.8.3"; weight = 1785 };
  { key = "banner.opacity.secondary_0035";               label = "legacy_crossbow_35";          arity = 7; tags = ["runtime"; "sync"; "emit"]; since = "1.0.0"; weight = 577 };
  { key = "world.opacity.provisional_0036";              label = "public_potion_36";            arity = 2; tags = ["async"; "typed"; "legacy"]; since = "1.3.1"; weight = 1875 };
  { key = "scoreboard.opacity.public_0037";              label = "internal_boat_37";            arity = 2; tags = ["codegen"; "experimental"]; since = "1.7.0"; weight = 3691 };
  { key = "conduit.opacity.legacy_0038";                 label = "primary_npc_38";              arity = 5; tags = ["sync"; "async"; "compat"]; since = "1.2.0"; weight = 1999 };
  { key = "rail.opacity.stable_0039";                    label = "legacy_block_39";             arity = 0; tags = ["parse"; "content"]; since = "1.7.0"; weight = 365 };
  { key = "smithing.opacity.lazy_0040";                  label = "strict_region_40";            arity = 7; tags = ["sync"; "content"; "legacy"]; since = "1.3.1"; weight = 3011 };
  { key = "shield.opacity.derived_0041";                 label = "primary_campfire_41";         arity = 4; tags = ["experimental"; "content"]; since = "1.7.0"; weight = 1845 };
  { key = "furnace.opacity.hidden_0042";                 label = "modern_hologram_42";          arity = 7; tags = ["cached"]; since = "1.2.0"; weight = 4032 };
  { key = "brewing.opacity.derived_0043";                label = "fallback_grindstone_43";      arity = 5; tags = ["cached"; "typed"]; since = "1.3.1"; weight = 3300 };
  { key = "composter.opacity.strict_0044";               label = "global_banner_pattern_44";    arity = 7; tags = ["content"; "lower"]; since = "1.7.0"; weight = 1154 };
  { key = "world.opacity.strict_0045";                   label = "local_smoker_45";             arity = 4; tags = ["core"]; since = "1.8.3"; weight = 4037 };
  { key = "repeater.opacity.primary_0046";               label = "eager_smithing_46";           arity = 7; tags = ["content"]; since = "1.5.2"; weight = 3732 };
  { key = "objective.opacity.public_0047";               label = "loose_banner_pattern_47";     arity = 7; tags = ["untyped"]; since = "1.6.0"; weight = 3257 };
  { key = "advancement.opacity.legacy_0048";             label = "loose_entity_48";             arity = 1; tags = ["registry"; "hot"]; since = "1.4.0"; weight = 1094 };
  { key = "barrel.opacity.global_0049";                  label = "lazy_map_49";                 arity = 1; tags = ["runtime"]; since = "1.4.0"; weight = 263 };
  { key = "anvil.opacity.global_0050";                   label = "primary_bundle_50";           arity = 1; tags = ["content"]; since = "1.9.0"; weight = 2797 };
  { key = "enchant.opacity.primary_0051";                label = "fallback_team_51";            arity = 4; tags = ["check"]; since = "1.8.3"; weight = 3347 };
  { key = "target.opacity.provisional_0052";             label = "primary_smoker_52";           arity = 5; tags = ["parse"; "content"; "cached"]; since = "1.3.1"; weight = 2975 };
  { key = "firework.opacity.provisional_0053";           label = "stable_player_53";            arity = 7; tags = ["lower"; "registry"; "cached"]; since = "1.6.0"; weight = 96 };
  { key = "arrow.opacity.strict_0054";                   label = "stable_item_54";              arity = 1; tags = ["hot"; "untyped"]; since = "1.6.0"; weight = 567 };
  { key = "conduit.opacity.eager_0055";                  label = "legacy_inventory_55";         arity = 1; tags = ["compat"]; since = "1.9.0"; weight = 631 };
  { key = "spawner.opacity.lazy_0056";                   label = "fallback_arrow_56";           arity = 6; tags = ["lower"; "sync"; "hot"]; since = "1.7.0"; weight = 2944 };
  { key = "hopper.opacity.secondary_0057";               label = "derived_chunk_57";            arity = 1; tags = ["cold"; "core"; "experimental"]; since = "1.7.0"; weight = 460 };
  { key = "inventory.opacity.derived_0058";              label = "secondary_mob_58";            arity = 5; tags = ["compat"; "core"]; since = "1.2.0"; weight = 1582 };
  { key = "minecart.opacity.loose_0059";                 label = "legacy_brewing_59";           arity = 5; tags = ["core"; "cold"]; since = "1.7.0"; weight = 1566 };
  { key = "gui.opacity.stable_0060";                     label = "scoped_mob_60";               arity = 4; tags = ["runtime"]; since = "1.8.3"; weight = 452 };
  { key = "dispenser.opacity.lazy_0061";                 label = "global_bossbar_61";           arity = 1; tags = ["content"; "codegen"]; since = "1.8.3"; weight = 1839 };
  { key = "bossbar.opacity.hidden_0062";                 label = "canonical_cartography_62";    arity = 5; tags = ["experimental"; "sync"; "typed"]; since = "1.8.3"; weight = 3297 };
  { key = "npc.opacity.public_0063";                     label = "loose_banner_pattern_63";     arity = 7; tags = ["packet"; "hot"; "check"]; since = "1.2.0"; weight = 1475 };
  { key = "boat.opacity.lazy_0064";                      label = "provisional_entity_64";       arity = 4; tags = ["lower"]; since = "1.4.0"; weight = 202 };
  { key = "bell.opacity.fallback_0065";                  label = "eager_objective_65";          arity = 6; tags = ["untyped"]; since = "1.4.0"; weight = 1495 };
  { key = "sound.opacity.derived_0066";                  label = "lazy_smoker_66";              arity = 0; tags = ["untyped"]; since = "1.8.3"; weight = 1 };
  { key = "dispenser.opacity.canonical_0067";            label = "public_minecart_67";          arity = 7; tags = ["content"; "registry"; "runtime"]; since = "1.0.0"; weight = 433 };
  { key = "pane.opacity.stable_0068";                    label = "global_item_68";              arity = 3; tags = ["parse"; "codegen"; "lower"]; since = "1.3.1"; weight = 1332 };
  { key = "team.opacity.global_0069";                    label = "secondary_elytra_69";         arity = 4; tags = ["parse"]; since = "1.5.2"; weight = 2971 };
  { key = "arrow.opacity.derived_0070";                  label = "eager_minecart_70";           arity = 0; tags = ["check"; "cold"; "registry"]; since = "1.8.3"; weight = 2835 };
  { key = "potion.opacity.loose_0071";                   label = "internal_player_71";          arity = 0; tags = ["codegen"; "runtime"; "packet"]; since = "1.0.0"; weight = 2000 };
  { key = "spawner.opacity.eager_0072";                  label = "stable_pane_72";              arity = 2; tags = ["codegen"]; since = "1.7.0"; weight = 2455 };
  { key = "sound.opacity.secondary_0073";                label = "public_stonecutter_73";       arity = 1; tags = ["parse"; "core"]; since = "1.3.1"; weight = 136 };
  { key = "shulker.opacity.legacy_0074";                 label = "public_comparator_74";        arity = 3; tags = ["async"; "runtime"; "packet"]; since = "1.5.2"; weight = 2540 };
  { key = "recipe.opacity.internal_0075";                label = "eager_portal_75";             arity = 0; tags = ["registry"; "typed"]; since = "1.3.1"; weight = 294 };
  { key = "slot.opacity.strict_0076";                    label = "scoped_region_76";            arity = 5; tags = ["registry"; "content"]; since = "1.3.1"; weight = 1246 };
  { key = "npc.opacity.public_0077";                     label = "eager_world_77";              arity = 2; tags = ["parse"]; since = "1.7.0"; weight = 1949 };
  { key = "cartography.opacity.strict_0078";             label = "eager_effect_78";             arity = 7; tags = ["registry"]; since = "1.7.0"; weight = 3960 };
  { key = "npc.opacity.cached_0079";                     label = "hidden_anvil_79";             arity = 1; tags = ["untyped"; "parse"]; since = "1.2.0"; weight = 3032 };
  { key = "banner_pattern.opacity.primary_0080";         label = "strict_smithing_80";          arity = 5; tags = ["hot"]; since = "1.3.1"; weight = 378 };
  { key = "observer.opacity.loose_0081";                 label = "eager_effect_81";             arity = 5; tags = ["core"; "cached"; "sync"]; since = "1.3.1"; weight = 3602 };
  { key = "dispenser.opacity.hidden_0082";               label = "local_effect_82";             arity = 7; tags = ["check"; "runtime"; "content"]; since = "1.9.0"; weight = 3412 };
  { key = "scoreboard.opacity.modern_0083";              label = "cached_npc_83";               arity = 0; tags = ["emit"; "legacy"; "cached"]; since = "1.5.2"; weight = 3372 };
  { key = "packet.opacity.legacy_0084";                  label = "public_shield_84";            arity = 6; tags = ["check"; "experimental"; "cached"]; since = "1.4.0"; weight = 2307 };
  { key = "stonecutter.opacity.cached_0085";             label = "loose_observer_85";           arity = 6; tags = ["lower"; "cached"]; since = "1.0.0"; weight = 268 };
  { key = "clock.opacity.eager_0086";                    label = "internal_sound_86";           arity = 7; tags = ["runtime"; "sync"; "untyped"]; since = "1.9.0"; weight = 140 };
  { key = "particle.opacity.canonical_0087";             label = "lazy_conduit_87";             arity = 1; tags = ["legacy"; "content"]; since = "1.6.0"; weight = 2595 };
  { key = "conduit.opacity.lazy_0088";                   label = "stable_hologram_88";          arity = 3; tags = ["compat"; "packet"]; since = "1.6.0"; weight = 3821 };
  { key = "item.opacity.modern_0089";                    label = "lazy_trade_89";               arity = 7; tags = ["legacy"; "lower"]; since = "1.6.0"; weight = 241 };
  { key = "arrow.opacity.stable_0090";                   label = "scoped_block_90";             arity = 2; tags = ["content"; "codegen"; "emit"]; since = "1.6.0"; weight = 223 };
  { key = "minecart.opacity.hidden_0091";                label = "local_barrel_91";             arity = 5; tags = ["cold"; "runtime"]; since = "1.3.1"; weight = 632 };
  { key = "hologram.opacity.strict_0092";                label = "secondary_anvil_92";          arity = 6; tags = ["typed"]; since = "1.3.1"; weight = 837 };
  { key = "furnace.opacity.cached_0093";                 label = "lazy_brewing_93";             arity = 4; tags = ["cold"; "core"]; since = "1.8.3"; weight = 1508 };
  { key = "spawner.opacity.local_0094";                  label = "lazy_effect_94";              arity = 3; tags = ["core"]; since = "1.5.2"; weight = 2065 };
  { key = "rail.opacity.local_0095";                     label = "scoped_shield_95";            arity = 3; tags = ["parse"; "legacy"]; since = "1.8.3"; weight = 1712 };
  { key = "boat.opacity.strict_0096";                    label = "eager_pane_96";               arity = 0; tags = ["cold"; "packet"]; since = "1.3.1"; weight = 36 };
  { key = "item.opacity.canonical_0097";                 label = "public_map_97";               arity = 0; tags = ["typed"; "parse"]; since = "1.5.2"; weight = 1152 };
  { key = "shulker.opacity.provisional_0098";            label = "primary_region_98";           arity = 3; tags = ["lower"]; since = "1.4.0"; weight = 1092 };
  { key = "inventory.opacity.cached_0099";               label = "scoped_arrow_99";             arity = 5; tags = ["compat"]; since = "1.3.1"; weight = 1162 };
  { key = "potion.opacity.fallback_0100";                label = "loose_shulker_100";           arity = 2; tags = ["cached"; "core"]; since = "1.7.0"; weight = 1532 };
  { key = "loom.opacity.primary_0101";                   label = "global_banner_pattern_101";   arity = 3; tags = ["cold"; "core"]; since = "1.2.0"; weight = 2844 };
  { key = "bossbar.opacity.lazy_0102";                   label = "internal_region_102";         arity = 3; tags = ["registry"]; since = "1.5.2"; weight = 1932 };
  { key = "dropper.opacity.fallback_0103";               label = "public_slot_103";             arity = 2; tags = ["hot"]; since = "1.0.0"; weight = 536 };
  { key = "observer.opacity.strict_0104";                label = "provisional_lectern_104";     arity = 3; tags = ["cold"]; since = "1.9.0"; weight = 557 };
  { key = "target.opacity.canonical_0105";               label = "strict_campfire_105";         arity = 4; tags = ["content"]; since = "1.0.0"; weight = 735 };
  { key = "dropper.opacity.derived_0106";                label = "derived_inventory_106";       arity = 7; tags = ["typed"]; since = "1.7.0"; weight = 3788 };
  { key = "shield.opacity.loose_0107";                   label = "provisional_hologram_107";    arity = 2; tags = ["legacy"; "experimental"]; since = "1.9.0"; weight = 3723 };
  { key = "item.opacity.secondary_0108";                 label = "global_beacon_108";           arity = 1; tags = ["runtime"]; since = "1.4.0"; weight = 704 };
  { key = "team.opacity.primary_0109";                   label = "stable_grindstone_109";       arity = 6; tags = ["parse"; "compat"]; since = "1.6.0"; weight = 3053 };
  { key = "hologram.opacity.stable_0110";                label = "hidden_repeater_110";         arity = 5; tags = ["emit"; "sync"]; since = "1.7.0"; weight = 1221 };
  { key = "shield.opacity.stable_0111";                  label = "modern_block_111";            arity = 1; tags = ["registry"]; since = "1.2.0"; weight = 112 };
  { key = "elytra.opacity.legacy_0112";                  label = "stable_rail_112";             arity = 1; tags = ["hot"; "emit"; "async"]; since = "1.3.1"; weight = 2250 };
  { key = "dropper.opacity.modern_0113";                 label = "internal_hopper_113";         arity = 6; tags = ["experimental"]; since = "1.4.0"; weight = 2614 };
  { key = "comparator.opacity.scoped_0114";              label = "strict_arrow_114";            arity = 1; tags = ["experimental"; "typed"; "cold"]; since = "1.0.0"; weight = 3800 };
  { key = "map.opacity.public_0115";                     label = "global_compass_115";          arity = 6; tags = ["core"; "compat"]; since = "1.2.0"; weight = 3833 };
  { key = "observer.opacity.stable_0116";                label = "modern_anvil_116";            arity = 2; tags = ["runtime"]; since = "1.6.0"; weight = 1062 };
  { key = "shulker.opacity.eager_0117";                  label = "cached_comparator_117";       arity = 2; tags = ["typed"; "packet"]; since = "1.9.0"; weight = 2603 };
  { key = "inventory.opacity.hidden_0118";               label = "loose_composter_118";         arity = 4; tags = ["codegen"; "typed"; "async"]; since = "1.5.2"; weight = 155 };
  { key = "tablist.opacity.strict_0119";                 label = "hidden_player_119";           arity = 1; tags = ["legacy"; "compat"]; since = "1.2.0"; weight = 1728 };
  { key = "sound.opacity.cached_0120";                   label = "lazy_clock_120";              arity = 4; tags = ["codegen"]; since = "1.6.0"; weight = 370 };
  { key = "grindstone.opacity.canonical_0121";           label = "secondary_effect_121";        arity = 3; tags = ["async"; "untyped"; "typed"]; since = "1.3.1"; weight = 610 };
  { key = "campfire.opacity.lazy_0122";                  label = "loose_tablist_122";           arity = 2; tags = ["emit"; "async"; "core"]; since = "1.6.0"; weight = 1783 };
  { key = "team.opacity.public_0123";                    label = "public_clock_123";            arity = 7; tags = ["parse"; "registry"; "typed"]; since = "1.3.1"; weight = 1231 };
  { key = "particle.opacity.stable_0124";                label = "internal_crossbow_124";       arity = 1; tags = ["hot"; "compat"]; since = "1.7.0"; weight = 4056 };
  { key = "cartography.opacity.global_0125";             label = "modern_attribute_125";        arity = 5; tags = ["cached"; "emit"]; since = "1.3.1"; weight = 3604 };
  { key = "npc.opacity.scoped_0126";                     label = "primary_hopper_126";          arity = 6; tags = ["legacy"]; since = "1.9.0"; weight = 3232 };
  { key = "firework.opacity.global_0127";                label = "scoped_boat_127";             arity = 6; tags = ["core"]; since = "1.5.2"; weight = 2931 };
  { key = "bundle.opacity.lazy_0128";                    label = "cached_objective_128";        arity = 0; tags = ["parse"]; since = "1.7.0"; weight = 1861 };
  { key = "smithing.opacity.provisional_0129";           label = "scoped_chunk_129";            arity = 6; tags = ["emit"]; since = "1.7.0"; weight = 301 };
  { key = "region.opacity.primary_0130";                 label = "internal_world_130";          arity = 5; tags = ["typed"; "runtime"; "check"]; since = "1.2.0"; weight = 899 };
  { key = "conduit.opacity.modern_0131";                 label = "derived_particle_131";        arity = 3; tags = ["parse"]; since = "1.8.3"; weight = 1722 };
  { key = "dropper.opacity.hidden_0132";                 label = "stable_shulker_132";          arity = 4; tags = ["lower"; "parse"]; since = "1.2.0"; weight = 3813 };
  { key = "potion.opacity.cached_0133";                  label = "fallback_entity_133";         arity = 3; tags = ["core"; "lower"]; since = "1.8.3"; weight = 646 };
  { key = "smoker.opacity.local_0134";                   label = "local_target_134";            arity = 0; tags = ["core"; "compat"]; since = "1.8.3"; weight = 1377 };
  { key = "attribute.opacity.public_0135";               label = "local_pane_135";              arity = 6; tags = ["compat"; "check"]; since = "1.6.0"; weight = 3073 };
  { key = "bell.opacity.eager_0136";                     label = "stable_campfire_136";         arity = 1; tags = ["packet"; "runtime"]; since = "1.8.3"; weight = 1353 };
  { key = "observer.opacity.provisional_0137";           label = "eager_cartography_137";       arity = 5; tags = ["core"; "emit"]; since = "1.4.0"; weight = 3089 };
  { key = "hopper.opacity.hidden_0138";                  label = "modern_anvil_138";            arity = 3; tags = ["async"; "runtime"]; since = "1.4.0"; weight = 107 };
  { key = "villager.opacity.strict_0139";                label = "stable_banner_139";           arity = 4; tags = ["cold"; "runtime"; "experimental"]; since = "1.9.0"; weight = 1117 };
  { key = "dropper.opacity.primary_0140";                label = "stable_beacon_140";           arity = 1; tags = ["core"]; since = "1.4.0"; weight = 2727 };
  { key = "comparator.opacity.global_0141";              label = "derived_packet_141";          arity = 5; tags = ["parse"]; since = "1.5.2"; weight = 2012 };
  { key = "entity.opacity.primary_0142";                 label = "local_hologram_142";          arity = 5; tags = ["packet"; "core"; "content"]; since = "1.3.1"; weight = 3026 };
  { key = "hologram.opacity.canonical_0143";             label = "global_effect_143";           arity = 4; tags = ["untyped"; "compat"; "cached"]; since = "1.5.2"; weight = 2354 };
  { key = "compass.opacity.canonical_0144";              label = "scoped_hologram_144";         arity = 0; tags = ["content"; "async"]; since = "1.4.0"; weight = 2301 };
  { key = "trident.opacity.lazy_0145";                   label = "internal_hologram_145";       arity = 1; tags = ["lower"; "registry"; "experimental"]; since = "1.3.1"; weight = 103 };
  { key = "elytra.opacity.canonical_0146";               label = "secondary_barrel_146";        arity = 7; tags = ["content"; "compat"; "experimental"]; since = "1.4.0"; weight = 2372 };
  { key = "trade.opacity.fallback_0147";                 label = "provisional_firework_147";    arity = 5; tags = ["emit"; "packet"]; since = "1.6.0"; weight = 3034 };
  { key = "repeater.opacity.secondary_0148";             label = "legacy_particle_148";         arity = 1; tags = ["codegen"; "registry"; "compat"]; since = "1.7.0"; weight = 66 };
  { key = "bell.opacity.provisional_0149";               label = "provisional_hopper_149";      arity = 0; tags = ["core"]; since = "1.2.0"; weight = 2689 };
  { key = "barrel.opacity.secondary_0150";               label = "scoped_chunk_150";            arity = 6; tags = ["untyped"; "content"]; since = "1.9.0"; weight = 3165 };
  { key = "particle.opacity.lazy_0151";                  label = "legacy_hologram_151";         arity = 6; tags = ["async"; "content"]; since = "1.0.0"; weight = 3674 };
  { key = "recipe.opacity.internal_0152";                label = "primary_chunk_152";           arity = 6; tags = ["sync"]; since = "1.3.1"; weight = 1240 };
  { key = "portal.opacity.eager_0153";                   label = "public_portal_153";           arity = 5; tags = ["content"; "experimental"]; since = "1.5.2"; weight = 3022 };
  { key = "trade.opacity.internal_0154";                 label = "secondary_shulker_154";       arity = 1; tags = ["runtime"; "content"]; since = "1.9.0"; weight = 2915 };
  { key = "barrel.opacity.scoped_0155";                  label = "provisional_effect_155";      arity = 0; tags = ["legacy"; "hot"; "core"]; since = "1.0.0"; weight = 2882 };
  { key = "shield.opacity.fallback_0156";                label = "public_conduit_156";          arity = 1; tags = ["compat"]; since = "1.4.0"; weight = 893 };
  { key = "structure.opacity.strict_0157";               label = "canonical_villager_157";      arity = 0; tags = ["parse"; "async"; "content"]; since = "1.2.0"; weight = 1468 };
  { key = "recipe.opacity.canonical_0158";               label = "fallback_compass_158";        arity = 1; tags = ["lower"; "check"; "emit"]; since = "1.3.1"; weight = 45 };
  { key = "target.opacity.local_0159";                   label = "loose_map_159";               arity = 3; tags = ["async"; "codegen"; "lower"]; since = "1.5.2"; weight = 1974 };
  { key = "shield.opacity.loose_0160";                   label = "strict_compass_160";          arity = 7; tags = ["content"; "check"]; since = "1.5.2"; weight = 158 };
  { key = "enchant.opacity.hidden_0161";                 label = "canonical_particle_161";      arity = 5; tags = ["runtime"; "cached"; "hot"]; since = "1.4.0"; weight = 118 };
  { key = "beacon.opacity.hidden_0162";                  label = "global_banner_pattern_162";   arity = 4; tags = ["runtime"; "parse"; "check"]; since = "1.0.0"; weight = 2952 };
  { key = "boat.opacity.legacy_0163";                    label = "derived_composter_163";       arity = 5; tags = ["async"; "experimental"; "packet"]; since = "1.2.0"; weight = 2212 };
  { key = "portal.opacity.loose_0164";                   label = "primary_shulker_164";         arity = 4; tags = ["codegen"; "cold"; "runtime"]; since = "1.7.0"; weight = 1571 };
  { key = "tablist.opacity.lazy_0165";                   label = "fallback_banner_165";         arity = 0; tags = ["emit"; "async"]; since = "1.4.0"; weight = 3625 };
  { key = "minecart.opacity.canonical_0166";             label = "scoped_elytra_166";           arity = 7; tags = ["codegen"]; since = "1.9.0"; weight = 3084 };
  { key = "gui.opacity.public_0167";                     label = "scoped_conduit_167";          arity = 0; tags = ["lower"; "core"]; since = "1.7.0"; weight = 1183 };
  { key = "dropper.opacity.global_0168";                 label = "loose_dropper_168";           arity = 4; tags = ["emit"; "check"; "cached"]; since = "1.8.3"; weight = 3526 };
  { key = "chunk.opacity.modern_0169";                   label = "public_tablist_169";          arity = 5; tags = ["core"; "experimental"; "hot"]; since = "1.3.1"; weight = 2297 };
  { key = "elytra.opacity.legacy_0170";                  label = "provisional_recipe_170";      arity = 1; tags = ["registry"]; since = "1.4.0"; weight = 3414 };
  { key = "hopper.opacity.scoped_0171";                  label = "stable_gui_171";              arity = 5; tags = ["sync"]; since = "1.5.2"; weight = 2554 };
  { key = "brewing.opacity.loose_0172";                  label = "internal_arrow_172";          arity = 7; tags = ["experimental"]; since = "1.5.2"; weight = 1599 };
  { key = "hologram.opacity.stable_0173";                label = "cached_shulker_173";          arity = 5; tags = ["emit"]; since = "1.4.0"; weight = 3030 };
  { key = "gui.opacity.lazy_0174";                       label = "global_advancement_174";      arity = 2; tags = ["registry"; "lower"]; since = "1.2.0"; weight = 2740 };
  { key = "trident.opacity.provisional_0175";            label = "loose_effect_175";            arity = 3; tags = ["typed"; "lower"]; since = "1.2.0"; weight = 2998 };
  { key = "item.opacity.eager_0176";                     label = "public_hologram_176";         arity = 2; tags = ["compat"]; since = "1.6.0"; weight = 3342 };
  { key = "pane.opacity.cached_0177";                    label = "fallback_firework_177";       arity = 0; tags = ["experimental"]; since = "1.9.0"; weight = 1356 };
  { key = "chunk.opacity.global_0178";                   label = "secondary_bell_178";          arity = 7; tags = ["packet"; "experimental"; "cached"]; since = "1.9.0"; weight = 1849 };
  { key = "portal.opacity.legacy_0179";                  label = "local_portal_179";            arity = 0; tags = ["lower"]; since = "1.8.3"; weight = 251 };
  { key = "biome.opacity.loose_0180";                    label = "eager_region_180";            arity = 3; tags = ["codegen"; "check"]; since = "1.6.0"; weight = 3267 };
  { key = "conduit.opacity.legacy_0181";                 label = "modern_target_181";           arity = 7; tags = ["legacy"]; since = "1.5.2"; weight = 375 };
  { key = "advancement.opacity.legacy_0182";             label = "hidden_scoreboard_182";       arity = 5; tags = ["lower"; "packet"; "codegen"]; since = "1.9.0"; weight = 2082 };
  { key = "advancement.opacity.fallback_0183";           label = "canonical_dispenser_183";     arity = 3; tags = ["runtime"; "cached"; "registry"]; since = "1.0.0"; weight = 3567 };
  { key = "slot.opacity.modern_0184";                    label = "canonical_hopper_184";        arity = 1; tags = ["legacy"]; since = "1.4.0"; weight = 2899 };
  { key = "dispenser.opacity.eager_0185";                label = "cached_arrow_185";            arity = 0; tags = ["check"]; since = "1.3.1"; weight = 182 };
  { key = "hologram.opacity.canonical_0186";             label = "scoped_dropper_186";          arity = 2; tags = ["compat"; "lower"; "codegen"]; since = "1.8.3"; weight = 1470 };
  { key = "smithing.opacity.secondary_0187";             label = "internal_trade_187";          arity = 3; tags = ["codegen"]; since = "1.4.0"; weight = 3564 };
  { key = "region.opacity.global_0188";                  label = "legacy_stonecutter_188";      arity = 5; tags = ["lower"]; since = "1.0.0"; weight = 3918 };
  { key = "shield.opacity.scoped_0189";                  label = "loose_trade_189";             arity = 0; tags = ["hot"; "check"]; since = "1.5.2"; weight = 1964 };
  { key = "block.opacity.stable_0190";                   label = "public_banner_pattern_190";   arity = 3; tags = ["untyped"; "sync"; "runtime"]; since = "1.8.3"; weight = 2666 };
  { key = "npc.opacity.derived_0191";                    label = "secondary_shulker_191";       arity = 1; tags = ["packet"; "experimental"; "emit"]; since = "1.2.0"; weight = 916 };
  { key = "hopper.opacity.fallback_0192";                label = "primary_hologram_192";        arity = 5; tags = ["compat"; "experimental"]; since = "1.9.0"; weight = 54 };
  { key = "villager.opacity.strict_0193";                label = "public_biome_193";            arity = 7; tags = ["core"; "untyped"; "async"]; since = "1.9.0"; weight = 1006 };
  { key = "potion.opacity.strict_0194";                  label = "derived_trade_194";           arity = 2; tags = ["parse"; "legacy"]; since = "1.6.0"; weight = 440 };
  { key = "crossbow.opacity.primary_0195";               label = "stable_structure_195";        arity = 5; tags = ["cold"; "lower"; "parse"]; since = "1.4.0"; weight = 2880 };
  { key = "team.opacity.canonical_0196";                 label = "cached_potion_196";           arity = 0; tags = ["hot"; "codegen"; "cached"]; since = "1.7.0"; weight = 3664 };
  { key = "chunk.opacity.legacy_0197";                   label = "stable_lectern_197";          arity = 3; tags = ["hot"; "registry"; "legacy"]; since = "1.4.0"; weight = 1872 };
  { key = "advancement.opacity.modern_0198";             label = "loose_composter_198";         arity = 3; tags = ["check"]; since = "1.0.0"; weight = 1586 };
  { key = "pane.opacity.stable_0199";                    label = "strict_effect_199";           arity = 4; tags = ["lower"]; since = "1.9.0"; weight = 2426 };
  { key = "villager.opacity.fallback_0200";              label = "strict_grindstone_200";       arity = 1; tags = ["async"]; since = "1.0.0"; weight = 1276 };
  { key = "conduit.opacity.fallback_0201";               label = "eager_dropper_201";           arity = 5; tags = ["typed"; "lower"]; since = "1.0.0"; weight = 179 };
  { key = "scoreboard.opacity.secondary_0202";           label = "legacy_arrow_202";            arity = 4; tags = ["compat"; "runtime"; "codegen"]; since = "1.7.0"; weight = 1203 };
  { key = "inventory.opacity.stable_0203";               label = "hidden_trident_203";          arity = 1; tags = ["legacy"]; since = "1.5.2"; weight = 699 };
  { key = "repeater.opacity.legacy_0204";                label = "eager_map_204";               arity = 4; tags = ["lower"; "async"]; since = "1.4.0"; weight = 3145 };
  { key = "chunk.opacity.canonical_0205";                label = "internal_particle_205";       arity = 6; tags = ["content"; "codegen"]; since = "1.0.0"; weight = 2284 };
  { key = "slot.opacity.global_0206";                    label = "provisional_smithing_206";    arity = 4; tags = ["sync"; "codegen"; "runtime"]; since = "1.8.3"; weight = 3427 };
  { key = "potion.opacity.modern_0207";                  label = "stable_piston_207";           arity = 2; tags = ["parse"; "cached"]; since = "1.8.3"; weight = 651 };
  { key = "region.opacity.cached_0208";                  label = "legacy_conduit_208";          arity = 1; tags = ["compat"]; since = "1.4.0"; weight = 2801 };
  { key = "arrow.opacity.public_0209";                   label = "public_conduit_209";          arity = 4; tags = ["typed"; "lower"]; since = "1.9.0"; weight = 3252 };
  { key = "clock.opacity.lazy_0210";                     label = "loose_scoreboard_210";        arity = 6; tags = ["typed"; "check"]; since = "1.3.1"; weight = 1218 };
  { key = "shield.opacity.loose_0211";                   label = "stable_player_211";           arity = 7; tags = ["core"; "experimental"]; since = "1.0.0"; weight = 527 };
  { key = "tablist.opacity.legacy_0212";                 label = "public_dropper_212";          arity = 4; tags = ["typed"; "async"]; since = "1.3.1"; weight = 2296 };
  { key = "dispenser.opacity.loose_0213";                label = "loose_objective_213";         arity = 7; tags = ["check"]; since = "1.4.0"; weight = 1000 };
  { key = "bell.opacity.scoped_0214";                    label = "derived_elytra_214";          arity = 2; tags = ["parse"; "sync"; "experimental"]; since = "1.6.0"; weight = 1594 };
  { key = "smoker.opacity.fallback_0215";                label = "cached_gui_215";              arity = 1; tags = ["typed"; "untyped"]; since = "1.4.0"; weight = 2171 };
  { key = "inventory.opacity.stable_0216";               label = "internal_rail_216";           arity = 0; tags = ["typed"; "untyped"; "cold"]; since = "1.3.1"; weight = 2650 };
  { key = "structure.opacity.lazy_0217";                 label = "internal_objective_217";      arity = 6; tags = ["cached"]; since = "1.6.0"; weight = 701 };
  { key = "trade.opacity.eager_0218";                    label = "secondary_banner_218";        arity = 5; tags = ["experimental"; "untyped"; "emit"]; since = "1.8.3"; weight = 2439 };
  { key = "mob.opacity.internal_0219";                   label = "secondary_cartography_219";   arity = 2; tags = ["cold"; "hot"; "emit"]; since = "1.5.2"; weight = 928 };
  { key = "packet.opacity.modern_0220";                  label = "fallback_trade_220";          arity = 4; tags = ["lower"; "hot"]; since = "1.3.1"; weight = 3322 };
  { key = "minecart.opacity.global_0221";                label = "scoped_block_221";            arity = 7; tags = ["cached"]; since = "1.3.1"; weight = 3043 };
  { key = "stonecutter.opacity.legacy_0222";             label = "lazy_furnace_222";            arity = 2; tags = ["lower"; "parse"]; since = "1.8.3"; weight = 141 };
  { key = "world.opacity.modern_0223";                   label = "strict_smoker_223";           arity = 0; tags = ["registry"; "compat"]; since = "1.6.0"; weight = 3224 };
  { key = "sound.opacity.legacy_0224";                   label = "stable_shulker_224";          arity = 5; tags = ["cold"; "typed"]; since = "1.8.3"; weight = 3536 };
  { key = "clock.opacity.internal_0225";                 label = "secondary_smithing_225";      arity = 6; tags = ["experimental"; "codegen"; "typed"]; since = "1.7.0"; weight = 1834 };
  { key = "conduit.opacity.derived_0226";                label = "local_conduit_226";           arity = 3; tags = ["experimental"]; since = "1.5.2"; weight = 3890 };
  { key = "banner.opacity.fallback_0227";                label = "primary_bundle_227";          arity = 5; tags = ["core"]; since = "1.6.0"; weight = 3071 };
  { key = "sound.opacity.internal_0228";                 label = "strict_team_228";             arity = 4; tags = ["compat"; "emit"; "core"]; since = "1.6.0"; weight = 1685 };
  { key = "villager.opacity.cached_0229";                label = "primary_firework_229";        arity = 4; tags = ["check"; "experimental"]; since = "1.4.0"; weight = 1805 };
  { key = "smithing.opacity.hidden_0230";                label = "global_rail_230";             arity = 6; tags = ["content"]; since = "1.5.2"; weight = 2552 };
  { key = "brewing.opacity.canonical_0231";              label = "strict_world_231";            arity = 4; tags = ["content"]; since = "1.3.1"; weight = 1523 };
  { key = "stonecutter.opacity.modern_0232";             label = "internal_enchant_232";        arity = 7; tags = ["async"; "cached"; "typed"]; since = "1.3.1"; weight = 3512 };
  { key = "enchant.opacity.internal_0233";               label = "global_advancement_233";      arity = 7; tags = ["untyped"]; since = "1.7.0"; weight = 3554 };
  { key = "stonecutter.opacity.local_0234";              label = "loose_banner_pattern_234";    arity = 3; tags = ["compat"; "async"]; since = "1.6.0"; weight = 2449 };
  { key = "piston.opacity.primary_0235";                 label = "modern_composter_235";        arity = 7; tags = ["experimental"]; since = "1.6.0"; weight = 204 };
  { key = "potion.opacity.primary_0236";                 label = "local_anvil_236";             arity = 6; tags = ["legacy"]; since = "1.5.2"; weight = 1364 };
  { key = "hopper.opacity.global_0237";                  label = "local_smithing_237";          arity = 7; tags = ["core"; "check"; "parse"]; since = "1.2.0"; weight = 3223 };
  { key = "piston.opacity.eager_0238";                   label = "modern_objective_238";        arity = 6; tags = ["core"; "emit"]; since = "1.8.3"; weight = 1956 };
  { key = "biome.opacity.cached_0239";                   label = "secondary_region_239";        arity = 5; tags = ["check"; "parse"]; since = "1.3.1"; weight = 863 };
  { key = "objective.opacity.primary_0240";              label = "eager_clock_240";             arity = 7; tags = ["typed"]; since = "1.6.0"; weight = 624 };
  { key = "arrow.opacity.modern_0241";                   label = "strict_player_241";           arity = 0; tags = ["content"]; since = "1.0.0"; weight = 1639 };
  { key = "npc.opacity.eager_0242";                      label = "provisional_villager_242";    arity = 4; tags = ["lower"; "compat"; "experimental"]; since = "1.6.0"; weight = 72 };
  { key = "team.opacity.cached_0243";                    label = "eager_dropper_243";           arity = 2; tags = ["typed"]; since = "1.6.0"; weight = 2009 };
  { key = "cartography.opacity.stable_0244";             label = "primary_dispenser_244";       arity = 5; tags = ["content"; "check"]; since = "1.2.0"; weight = 229 };
  { key = "smoker.opacity.eager_0245";                   label = "internal_cartography_245";    arity = 0; tags = ["runtime"; "packet"]; since = "1.4.0"; weight = 3192 };
  { key = "shulker.opacity.internal_0246";               label = "cached_advancement_246";      arity = 3; tags = ["sync"]; since = "1.8.3"; weight = 3489 };
  { key = "packet.opacity.canonical_0247";               label = "derived_beacon_247";          arity = 0; tags = ["parse"]; since = "1.9.0"; weight = 1232 };
  { key = "map.opacity.secondary_0248";                  label = "local_shulker_248";           arity = 7; tags = ["runtime"]; since = "1.5.2"; weight = 212 };
  { key = "inventory.opacity.public_0249";               label = "hidden_arrow_249";            arity = 4; tags = ["packet"; "compat"; "experimental"]; since = "1.7.0"; weight = 2351 };
  { key = "villager.opacity.lazy_0250";                  label = "provisional_minecart_250";    arity = 6; tags = ["lower"; "core"; "parse"]; since = "1.5.2"; weight = 3271 };
  { key = "world.opacity.derived_0251";                  label = "cached_structure_251";        arity = 7; tags = ["packet"; "parse"]; since = "1.4.0"; weight = 930 };
  { key = "banner.opacity.internal_0252";                label = "local_effect_252";            arity = 0; tags = ["untyped"]; since = "1.8.3"; weight = 2047 };
  { key = "pane.opacity.fallback_0253";                  label = "lazy_compass_253";            arity = 5; tags = ["emit"]; since = "1.7.0"; weight = 73 };
  { key = "structure.opacity.fallback_0254";             label = "cached_team_254";             arity = 3; tags = ["cold"]; since = "1.2.0"; weight = 1484 };
  { key = "scoreboard.opacity.hidden_0255";              label = "canonical_entity_255";        arity = 0; tags = ["runtime"; "untyped"]; since = "1.3.1"; weight = 2066 };
  { key = "stonecutter.opacity.canonical_0256";          label = "legacy_chunk_256";            arity = 4; tags = ["registry"]; since = "1.9.0"; weight = 1414 };
  { key = "arrow.opacity.cached_0257";                   label = "local_loom_257";              arity = 5; tags = ["sync"]; since = "1.5.2"; weight = 3368 };
  { key = "chunk.opacity.stable_0258";                   label = "modern_stonecutter_258";      arity = 1; tags = ["compat"; "legacy"; "untyped"]; since = "1.8.3"; weight = 3810 };
  { key = "minecart.opacity.hidden_0259";                label = "cached_region_259";           arity = 1; tags = ["cached"; "check"; "untyped"]; since = "1.6.0"; weight = 3018 };
  { key = "portal.opacity.local_0260";                   label = "scoped_bell_260";             arity = 7; tags = ["registry"; "hot"; "check"]; since = "1.7.0"; weight = 323 };
  { key = "particle.opacity.internal_0261";              label = "lazy_team_261";               arity = 4; tags = ["hot"; "typed"; "codegen"]; since = "1.4.0"; weight = 486 };
  { key = "campfire.opacity.local_0262";                 label = "secondary_firework_262";      arity = 6; tags = ["codegen"; "runtime"; "content"]; since = "1.6.0"; weight = 3644 };
  { key = "recipe.opacity.scoped_0263";                  label = "legacy_bundle_263";           arity = 1; tags = ["lower"; "cold"]; since = "1.2.0"; weight = 616 };
  { key = "repeater.opacity.fallback_0264";              label = "provisional_block_264";       arity = 6; tags = ["emit"]; since = "1.0.0"; weight = 818 };
  { key = "entity.opacity.fallback_0265";                label = "hidden_campfire_265";         arity = 3; tags = ["core"]; since = "1.2.0"; weight = 3134 };
  { key = "trade.opacity.local_0266";                    label = "global_block_266";            arity = 6; tags = ["sync"; "async"; "lower"]; since = "1.5.2"; weight = 973 };
  { key = "gui.opacity.loose_0267";                      label = "strict_slot_267";             arity = 2; tags = ["async"]; since = "1.3.1"; weight = 1600 };
  { key = "anvil.opacity.fallback_0268";                 label = "derived_villager_268";        arity = 7; tags = ["compat"]; since = "1.3.1"; weight = 1846 };
  { key = "cartography.opacity.provisional_0269";        label = "canonical_campfire_269";      arity = 1; tags = ["experimental"; "check"; "untyped"]; since = "1.7.0"; weight = 2900 };
  { key = "firework.opacity.provisional_0270";           label = "fallback_team_270";           arity = 4; tags = ["packet"; "legacy"]; since = "1.9.0"; weight = 3726 };
  { key = "banner_pattern.opacity.cached_0271";          label = "modern_shield_271";           arity = 6; tags = ["packet"]; since = "1.2.0"; weight = 3184 };
  { key = "mob.opacity.canonical_0272";                  label = "fallback_potion_272";         arity = 6; tags = ["registry"; "sync"; "runtime"]; since = "1.6.0"; weight = 546 };
  { key = "shulker.opacity.stable_0273";                 label = "secondary_scoreboard_273";    arity = 2; tags = ["registry"; "codegen"]; since = "1.9.0"; weight = 2181 };
  { key = "repeater.opacity.hidden_0274";                label = "fallback_furnace_274";        arity = 1; tags = ["content"; "experimental"]; since = "1.7.0"; weight = 3900 };
  { key = "boat.opacity.global_0275";                    label = "derived_trade_275";           arity = 4; tags = ["cold"; "cached"]; since = "1.7.0"; weight = 78 };
  { key = "pane.opacity.legacy_0276";                    label = "secondary_mob_276";           arity = 2; tags = ["async"; "compat"]; since = "1.2.0"; weight = 3874 };
  { key = "banner_pattern.opacity.secondary_0277";       label = "lazy_villager_277";           arity = 7; tags = ["registry"]; since = "1.6.0"; weight = 3205 };
  { key = "shield.opacity.legacy_0278";                  label = "provisional_attribute_278";   arity = 7; tags = ["lower"; "compat"; "untyped"]; since = "1.8.3"; weight = 2 };
  { key = "mob.opacity.eager_0279";                      label = "strict_hologram_279";         arity = 0; tags = ["experimental"; "hot"; "emit"]; since = "1.0.0"; weight = 880 };
  { key = "bell.opacity.stable_0280";                    label = "local_boat_280";              arity = 5; tags = ["content"; "core"]; since = "1.2.0"; weight = 2716 };
  { key = "shield.opacity.internal_0281";                label = "derived_player_281";          arity = 0; tags = ["experimental"; "hot"]; since = "1.0.0"; weight = 2230 };
  { key = "advancement.opacity.legacy_0282";             label = "scoped_recipe_282";           arity = 2; tags = ["registry"; "lower"; "sync"]; since = "1.6.0"; weight = 1028 };
  { key = "composter.opacity.hidden_0283";               label = "cached_slot_283";             arity = 3; tags = ["cached"]; since = "1.0.0"; weight = 297 };
  { key = "brewing.opacity.cached_0284";                 label = "public_scoreboard_284";       arity = 2; tags = ["lower"]; since = "1.3.1"; weight = 1850 };
  { key = "campfire.opacity.cached_0285";                label = "fallback_entity_285";         arity = 0; tags = ["legacy"; "cached"; "packet"]; since = "1.8.3"; weight = 1354 };
  { key = "region.opacity.strict_0286";                  label = "derived_sound_286";           arity = 1; tags = ["check"; "compat"; "experimental"]; since = "1.7.0"; weight = 1862 };
  { key = "trident.opacity.canonical_0287";              label = "strict_attribute_287";        arity = 0; tags = ["sync"; "legacy"; "content"]; since = "1.6.0"; weight = 1300 };
  { key = "gui.opacity.strict_0288";                     label = "internal_firework_288";       arity = 7; tags = ["cached"; "hot"; "registry"]; since = "1.4.0"; weight = 1258 };
  { key = "compass.opacity.global_0289";                 label = "scoped_furnace_289";          arity = 3; tags = ["packet"; "emit"; "experimental"]; since = "1.4.0"; weight = 164 };
  { key = "hologram.opacity.fallback_0290";              label = "legacy_npc_290";              arity = 7; tags = ["lower"; "emit"; "sync"]; since = "1.7.0"; weight = 2407 };
  { key = "anvil.opacity.secondary_0291";                label = "cached_advancement_291";      arity = 2; tags = ["compat"]; since = "1.8.3"; weight = 1209 };
  { key = "sound.opacity.local_0292";                    label = "strict_comparator_292";       arity = 1; tags = ["emit"; "check"; "cached"]; since = "1.5.2"; weight = 3797 };
  { key = "elytra.opacity.provisional_0293";             label = "strict_banner_293";           arity = 6; tags = ["cached"; "untyped"]; since = "1.6.0"; weight = 2731 };
  { key = "world.opacity.secondary_0294";                label = "legacy_boat_294";             arity = 3; tags = ["untyped"; "typed"; "runtime"]; since = "1.9.0"; weight = 2893 };
  { key = "brewing.opacity.lazy_0295";                   label = "local_effect_295";            arity = 6; tags = ["cold"]; since = "1.0.0"; weight = 3388 };
  { key = "bossbar.opacity.stable_0296";                 label = "strict_effect_296";           arity = 0; tags = ["sync"]; since = "1.7.0"; weight = 3617 };
  { key = "gui.opacity.loose_0297";                      label = "public_map_297";              arity = 1; tags = ["content"; "sync"; "experimental"]; since = "1.2.0"; weight = 446 };
  { key = "dispenser.opacity.fallback_0298";             label = "primary_spawner_298";         arity = 0; tags = ["cold"; "experimental"]; since = "1.4.0"; weight = 1404 };
  { key = "smoker.opacity.secondary_0299";               label = "loose_world_299";             arity = 0; tags = ["packet"]; since = "1.5.2"; weight = 3440 };
  { key = "structure.opacity.internal_0300";             label = "global_clock_300";            arity = 7; tags = ["codegen"]; since = "1.0.0"; weight = 142 };
  { key = "trade.opacity.provisional_0301";              label = "lazy_chunk_301";              arity = 6; tags = ["typed"; "legacy"; "packet"]; since = "1.6.0"; weight = 2592 };
  { key = "pane.opacity.eager_0302";                     label = "secondary_rail_302";          arity = 1; tags = ["codegen"; "parse"]; since = "1.8.3"; weight = 454 };
  { key = "potion.opacity.strict_0303";                  label = "global_chunk_303";            arity = 3; tags = ["registry"]; since = "1.2.0"; weight = 720 };
  { key = "lectern.opacity.eager_0304";                  label = "hidden_portal_304";           arity = 7; tags = ["cold"]; since = "1.7.0"; weight = 1811 };
  { key = "smoker.opacity.public_0305";                  label = "public_campfire_305";         arity = 6; tags = ["parse"; "compat"]; since = "1.2.0"; weight = 1002 };
  { key = "team.opacity.legacy_0306";                    label = "legacy_sound_306";            arity = 1; tags = ["codegen"]; since = "1.4.0"; weight = 2496 };
  { key = "block.opacity.legacy_0307";                   label = "global_shield_307";           arity = 7; tags = ["registry"; "emit"; "parse"]; since = "1.7.0"; weight = 3689 };
  { key = "trident.opacity.provisional_0308";            label = "stable_objective_308";        arity = 4; tags = ["sync"; "emit"]; since = "1.2.0"; weight = 2525 };
  { key = "item.opacity.internal_0309";                  label = "lazy_conduit_309";            arity = 6; tags = ["core"]; since = "1.7.0"; weight = 2468 };
  { key = "bossbar.opacity.public_0310";                 label = "scoped_hopper_310";           arity = 7; tags = ["runtime"; "core"]; since = "1.2.0"; weight = 2923 };
  { key = "recipe.opacity.secondary_0311";               label = "primary_anvil_311";           arity = 5; tags = ["core"; "packet"; "parse"]; since = "1.2.0"; weight = 1302 };
  { key = "enchant.opacity.hidden_0312";                 label = "secondary_comparator_312";    arity = 0; tags = ["lower"; "check"]; since = "1.2.0"; weight = 3581 };
  { key = "packet.opacity.canonical_0313";               label = "legacy_pane_313";             arity = 1; tags = ["parse"; "registry"; "packet"]; since = "1.6.0"; weight = 2856 };
  { key = "bell.opacity.public_0314";                    label = "primary_lectern_314";         arity = 3; tags = ["codegen"; "experimental"]; since = "1.6.0"; weight = 3504 };
  { key = "spawner.opacity.hidden_0315";                 label = "strict_observer_315";         arity = 3; tags = ["runtime"; "cold"; "hot"]; since = "1.0.0"; weight = 724 };
  { key = "stonecutter.opacity.derived_0316";            label = "legacy_repeater_316";         arity = 1; tags = ["check"]; since = "1.4.0"; weight = 3046 };
  { key = "boat.opacity.strict_0317";                    label = "stable_packet_317";           arity = 7; tags = ["codegen"; "hot"]; since = "1.5.2"; weight = 638 };
  { key = "portal.opacity.local_0318";                   label = "local_composter_318";         arity = 2; tags = ["codegen"]; since = "1.0.0"; weight = 3804 };
  { key = "dropper.opacity.derived_0319";                label = "cached_effect_319";           arity = 3; tags = ["hot"; "registry"]; since = "1.0.0"; weight = 1408 };
  { key = "banner_pattern.opacity.fallback_0320";        label = "strict_block_320";            arity = 1; tags = ["async"]; since = "1.2.0"; weight = 3944 };
  { key = "bell.opacity.scoped_0321";                    label = "stable_world_321";            arity = 2; tags = ["sync"; "lower"]; since = "1.0.0"; weight = 541 };
  { key = "portal.opacity.eager_0322";                   label = "modern_team_322";             arity = 3; tags = ["runtime"; "hot"; "core"]; since = "1.6.0"; weight = 1670 };
  { key = "anvil.opacity.hidden_0323";                   label = "derived_particle_323";        arity = 0; tags = ["codegen"; "typed"]; since = "1.8.3"; weight = 3701 };
  { key = "dispenser.opacity.internal_0324";             label = "fallback_smoker_324";         arity = 2; tags = ["sync"]; since = "1.8.3"; weight = 3595 };
  { key = "entity.opacity.modern_0325";                  label = "strict_tablist_325";          arity = 1; tags = ["typed"; "registry"]; since = "1.5.2"; weight = 2803 };
  { key = "shield.opacity.scoped_0326";                  label = "hidden_barrel_326";           arity = 0; tags = ["sync"; "typed"]; since = "1.2.0"; weight = 477 };
  { key = "compass.opacity.global_0327";                 label = "provisional_npc_327";         arity = 1; tags = ["async"; "runtime"; "cold"]; since = "1.8.3"; weight = 1772 };
  { key = "biome.opacity.modern_0328";                   label = "internal_scoreboard_328";     arity = 4; tags = ["runtime"; "core"; "untyped"]; since = "1.4.0"; weight = 193 };
  { key = "portal.opacity.secondary_0329";               label = "loose_cartography_329";       arity = 2; tags = ["sync"; "typed"]; since = "1.6.0"; weight = 767 };
  { key = "packet.opacity.internal_0330";                label = "derived_grindstone_330";      arity = 0; tags = ["experimental"; "codegen"; "packet"]; since = "1.8.3"; weight = 924 };
  { key = "piston.opacity.legacy_0331";                  label = "stable_comparator_331";       arity = 5; tags = ["parse"; "untyped"]; since = "1.8.3"; weight = 4074 };
  { key = "sound.opacity.secondary_0332";                label = "derived_packet_332";          arity = 4; tags = ["codegen"; "async"]; since = "1.2.0"; weight = 1469 };
  { key = "smithing.opacity.cached_0333";                label = "provisional_brewing_333";     arity = 6; tags = ["cold"; "async"; "parse"]; since = "1.5.2"; weight = 3364 };
  { key = "tablist.opacity.internal_0334";               label = "local_packet_334";            arity = 3; tags = ["core"; "packet"; "cached"]; since = "1.5.2"; weight = 426 };
  { key = "observer.opacity.global_0335";                label = "lazy_entity_335";             arity = 3; tags = ["parse"]; since = "1.7.0"; weight = 1969 };
  { key = "bossbar.opacity.canonical_0336";              label = "primary_map_336";             arity = 1; tags = ["experimental"; "emit"; "codegen"]; since = "1.4.0"; weight = 2007 };
  { key = "item.opacity.lazy_0337";                      label = "canonical_bossbar_337";       arity = 4; tags = ["legacy"; "hot"; "codegen"]; since = "1.5.2"; weight = 452 };
  { key = "world.opacity.canonical_0338";                label = "public_particle_338";         arity = 6; tags = ["check"]; since = "1.0.0"; weight = 1395 };
  { key = "minecart.opacity.global_0339";                label = "scoped_elytra_339";           arity = 5; tags = ["emit"]; since = "1.6.0"; weight = 1969 };
  { key = "particle.opacity.eager_0340";                 label = "stable_hopper_340";           arity = 4; tags = ["typed"]; since = "1.9.0"; weight = 1171 };
  { key = "region.opacity.scoped_0341";                  label = "legacy_dropper_341";          arity = 2; tags = ["sync"; "legacy"]; since = "1.2.0"; weight = 2207 };
  { key = "biome.opacity.scoped_0342";                   label = "strict_stonecutter_342";      arity = 1; tags = ["parse"; "untyped"]; since = "1.2.0"; weight = 3869 };
  { key = "repeater.opacity.cached_0343";                label = "global_furnace_343";          arity = 0; tags = ["hot"]; since = "1.4.0"; weight = 1052 };
  { key = "barrel.opacity.hidden_0344";                  label = "derived_piston_344";          arity = 7; tags = ["legacy"; "parse"; "hot"]; since = "1.9.0"; weight = 1863 };
  { key = "mob.opacity.cached_0345";                     label = "fallback_player_345";         arity = 0; tags = ["untyped"]; since = "1.2.0"; weight = 2139 };
  { key = "hopper.opacity.cached_0346";                  label = "cached_banner_346";           arity = 1; tags = ["check"]; since = "1.9.0"; weight = 991 };
  { key = "banner.opacity.fallback_0347";                label = "eager_firework_347";          arity = 7; tags = ["experimental"; "lower"; "runtime"]; since = "1.4.0"; weight = 809 };
  { key = "comparator.opacity.internal_0348";            label = "primary_bossbar_348";         arity = 5; tags = ["typed"]; since = "1.3.1"; weight = 2129 };
  { key = "banner_pattern.opacity.global_0349";          label = "provisional_beacon_349";      arity = 4; tags = ["emit"; "registry"]; since = "1.7.0"; weight = 2375 };
  { key = "hologram.opacity.lazy_0350";                  label = "fallback_inventory_350";      arity = 4; tags = ["untyped"; "async"; "check"]; since = "1.2.0"; weight = 2342 };
]

let count = List.length entries

let table : (string, opacity_entry) Hashtbl.t =
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
