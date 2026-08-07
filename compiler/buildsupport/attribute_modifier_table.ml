(* attribute_modifier_table.ml -- attribute modifier operations and stacking

   This module is part of the compiler's build-support layer: the tables below
   are flattened views over the pinned data snapshots in ../data, kept here in
   OCaml form so the checks can run without re-reading the JSON on every
   invocation. Nothing in this directory is linked into swoftc itself; it is
   consumed by the offline table diffing tools under maintainers/. *)

type modifier_entry = {
  key : string;
  label : string;
  arity : int;
  tags : string list;
  since : string;
  weight : int;
}

type modifier_kind =
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

let entries : modifier_entry list = [
  { key = "portal.modifier.scoped_0000";                 label = "loose_villager_0";            arity = 5; tags = ["legacy"]; since = "1.9.0"; weight = 2545 };
  { key = "dispenser.modifier.internal_0001";            label = "modern_bundle_1";             arity = 1; tags = ["sync"; "hot"]; since = "1.6.0"; weight = 423 };
  { key = "mob.modifier.fallback_0002";                  label = "eager_banner_pattern_2";      arity = 1; tags = ["runtime"]; since = "1.4.0"; weight = 3614 };
  { key = "team.modifier.modern_0003";                   label = "eager_rail_3";                arity = 6; tags = ["untyped"; "experimental"]; since = "1.0.0"; weight = 3980 };
  { key = "boat.modifier.canonical_0004";                label = "eager_bundle_4";              arity = 6; tags = ["check"; "untyped"; "experimental"]; since = "1.5.2"; weight = 2270 };
  { key = "stonecutter.modifier.loose_0005";             label = "internal_entity_5";           arity = 5; tags = ["check"; "codegen"; "cached"]; since = "1.0.0"; weight = 3598 };
  { key = "world.modifier.eager_0006";                   label = "canonical_spawner_6";         arity = 6; tags = ["cold"; "cached"]; since = "1.2.0"; weight = 3400 };
  { key = "item.modifier.fallback_0007";                 label = "scoped_enchant_7";            arity = 7; tags = ["codegen"]; since = "1.4.0"; weight = 3975 };
  { key = "block.modifier.primary_0008";                 label = "cached_biome_8";              arity = 0; tags = ["cached"; "async"; "cold"]; since = "1.5.2"; weight = 3048 };
  { key = "enchant.modifier.legacy_0009";                label = "public_advancement_9";        arity = 5; tags = ["cached"]; since = "1.7.0"; weight = 533 };
  { key = "villager.modifier.primary_0010";              label = "local_item_10";               arity = 7; tags = ["parse"; "lower"; "runtime"]; since = "1.2.0"; weight = 2829 };
  { key = "scoreboard.modifier.scoped_0011";             label = "lazy_compass_11";             arity = 6; tags = ["core"; "experimental"]; since = "1.2.0"; weight = 1635 };
  { key = "bell.modifier.public_0012";                   label = "modern_spawner_12";           arity = 0; tags = ["check"; "codegen"]; since = "1.7.0"; weight = 1295 };
  { key = "region.modifier.global_0013";                 label = "eager_map_13";                arity = 1; tags = ["lower"; "experimental"]; since = "1.7.0"; weight = 3399 };
  { key = "banner.modifier.lazy_0014";                   label = "internal_portal_14";          arity = 6; tags = ["compat"; "experimental"]; since = "1.9.0"; weight = 2913 };
  { key = "sound.modifier.eager_0015";                   label = "strict_banner_15";            arity = 3; tags = ["emit"; "lower"]; since = "1.3.1"; weight = 2198 };
  { key = "sound.modifier.derived_0016";                 label = "eager_observer_16";           arity = 7; tags = ["cold"]; since = "1.7.0"; weight = 2729 };
  { key = "mob.modifier.fallback_0017";                  label = "canonical_villager_17";       arity = 2; tags = ["typed"; "experimental"]; since = "1.6.0"; weight = 1230 };
  { key = "objective.modifier.hidden_0018";              label = "stable_clock_18";             arity = 4; tags = ["content"; "typed"; "sync"]; since = "1.6.0"; weight = 2963 };
  { key = "advancement.modifier.cached_0019";            label = "canonical_structure_19";      arity = 0; tags = ["async"; "typed"]; since = "1.8.3"; weight = 469 };
  { key = "furnace.modifier.primary_0020";               label = "public_brewing_20";           arity = 6; tags = ["cold"; "lower"]; since = "1.8.3"; weight = 3456 };
  { key = "barrel.modifier.derived_0021";                label = "legacy_firework_21";          arity = 5; tags = ["typed"; "core"]; since = "1.4.0"; weight = 1369 };
  { key = "spawner.modifier.hidden_0022";                label = "global_elytra_22";            arity = 2; tags = ["untyped"]; since = "1.5.2"; weight = 2708 };
  { key = "stonecutter.modifier.internal_0023";          label = "cached_bundle_23";            arity = 1; tags = ["parse"; "sync"]; since = "1.6.0"; weight = 86 };
  { key = "campfire.modifier.internal_0024";             label = "primary_campfire_24";         arity = 1; tags = ["sync"]; since = "1.3.1"; weight = 3897 };
  { key = "sound.modifier.global_0025";                  label = "scoped_arrow_25";             arity = 7; tags = ["content"; "codegen"; "core"]; since = "1.7.0"; weight = 3231 };
  { key = "advancement.modifier.provisional_0026";       label = "internal_scoreboard_26";      arity = 6; tags = ["registry"]; since = "1.2.0"; weight = 2772 };
  { key = "map.modifier.stable_0027";                    label = "modern_spawner_27";           arity = 0; tags = ["sync"]; since = "1.0.0"; weight = 1896 };
  { key = "player.modifier.secondary_0028";              label = "global_portal_28";            arity = 2; tags = ["typed"; "cached"; "content"]; since = "1.8.3"; weight = 2707 };
  { key = "inventory.modifier.strict_0029";              label = "canonical_crossbow_29";       arity = 3; tags = ["core"; "cached"; "async"]; since = "1.6.0"; weight = 2967 };
  { key = "grindstone.modifier.fallback_0030";           label = "provisional_anvil_30";        arity = 0; tags = ["typed"]; since = "1.3.1"; weight = 441 };
  { key = "villager.modifier.cached_0031";               label = "stable_minecart_31";          arity = 6; tags = ["compat"]; since = "1.9.0"; weight = 3083 };
  { key = "mob.modifier.local_0032";                     label = "stable_beacon_32";            arity = 7; tags = ["compat"]; since = "1.6.0"; weight = 1106 };
  { key = "advancement.modifier.stable_0033";            label = "hidden_world_33";             arity = 0; tags = ["content"; "sync"; "experimental"]; since = "1.6.0"; weight = 2335 };
  { key = "beacon.modifier.scoped_0034";                 label = "hidden_portal_34";            arity = 3; tags = ["compat"; "lower"]; since = "1.9.0"; weight = 3144 };
  { key = "composter.modifier.stable_0035";              label = "primary_mob_35";              arity = 3; tags = ["untyped"]; since = "1.0.0"; weight = 360 };
  { key = "biome.modifier.canonical_0036";               label = "strict_sound_36";             arity = 4; tags = ["untyped"; "codegen"; "core"]; since = "1.2.0"; weight = 623 };
  { key = "effect.modifier.fallback_0037";               label = "canonical_block_37";          arity = 7; tags = ["cold"; "lower"]; since = "1.3.1"; weight = 2181 };
  { key = "mob.modifier.scoped_0038";                    label = "global_entity_38";            arity = 7; tags = ["experimental"]; since = "1.2.0"; weight = 970 };
  { key = "cartography.modifier.fallback_0039";          label = "fallback_npc_39";             arity = 6; tags = ["async"]; since = "1.6.0"; weight = 2103 };
  { key = "dispenser.modifier.secondary_0040";           label = "stable_player_40";            arity = 7; tags = ["compat"; "codegen"]; since = "1.9.0"; weight = 2395 };
  { key = "banner_pattern.modifier.derived_0041";        label = "legacy_clock_41";             arity = 0; tags = ["typed"; "hot"; "untyped"]; since = "1.9.0"; weight = 212 };
  { key = "shulker.modifier.derived_0042";               label = "loose_mob_42";                arity = 0; tags = ["hot"; "cached"; "emit"]; since = "1.2.0"; weight = 1553 };
  { key = "entity.modifier.fallback_0043";               label = "internal_trade_43";           arity = 7; tags = ["parse"; "cached"; "experimental"]; since = "1.8.3"; weight = 2462 };
  { key = "block.modifier.legacy_0044";                  label = "public_campfire_44";          arity = 1; tags = ["untyped"]; since = "1.8.3"; weight = 1318 };
  { key = "portal.modifier.public_0045";                 label = "strict_map_45";               arity = 1; tags = ["compat"]; since = "1.9.0"; weight = 1969 };
  { key = "trade.modifier.provisional_0046";             label = "internal_crossbow_46";        arity = 2; tags = ["parse"; "packet"; "registry"]; since = "1.3.1"; weight = 606 };
  { key = "rail.modifier.loose_0047";                    label = "internal_target_47";          arity = 7; tags = ["runtime"; "legacy"; "packet"]; since = "1.2.0"; weight = 1950 };
  { key = "map.modifier.primary_0048";                   label = "secondary_smoker_48";         arity = 6; tags = ["runtime"; "check"; "core"]; since = "1.2.0"; weight = 1619 };
  { key = "packet.modifier.canonical_0049";              label = "hidden_stonecutter_49";       arity = 6; tags = ["cold"; "hot"]; since = "1.4.0"; weight = 848 };
  { key = "elytra.modifier.strict_0050";                 label = "derived_enchant_50";          arity = 7; tags = ["codegen"]; since = "1.5.2"; weight = 3057 };
  { key = "spawner.modifier.internal_0051";              label = "derived_world_51";            arity = 6; tags = ["hot"; "cold"]; since = "1.6.0"; weight = 264 };
  { key = "bundle.modifier.derived_0052";                label = "internal_anvil_52";           arity = 2; tags = ["parse"; "content"; "packet"]; since = "1.6.0"; weight = 1372 };
  { key = "grindstone.modifier.scoped_0053";             label = "legacy_recipe_53";            arity = 2; tags = ["runtime"; "content"]; since = "1.0.0"; weight = 1897 };
  { key = "banner.modifier.public_0054";                 label = "local_grindstone_54";         arity = 4; tags = ["experimental"; "emit"; "check"]; since = "1.8.3"; weight = 3698 };
  { key = "stonecutter.modifier.secondary_0055";         label = "fallback_boat_55";            arity = 0; tags = ["runtime"; "cold"]; since = "1.5.2"; weight = 2486 };
  { key = "crossbow.modifier.stable_0056";               label = "legacy_crossbow_56";          arity = 1; tags = ["core"; "async"]; since = "1.4.0"; weight = 540 };
  { key = "observer.modifier.legacy_0057";               label = "legacy_attribute_57";         arity = 1; tags = ["typed"; "content"; "cold"]; since = "1.9.0"; weight = 3769 };
  { key = "banner.modifier.fallback_0058";               label = "hidden_bossbar_58";           arity = 2; tags = ["sync"; "compat"]; since = "1.7.0"; weight = 3825 };
  { key = "scoreboard.modifier.stable_0059";             label = "hidden_trident_59";           arity = 7; tags = ["untyped"; "parse"]; since = "1.0.0"; weight = 348 };
  { key = "region.modifier.public_0060";                 label = "provisional_firework_60";     arity = 0; tags = ["parse"; "untyped"; "emit"]; since = "1.8.3"; weight = 2513 };
  { key = "objective.modifier.cached_0061";              label = "provisional_player_61";       arity = 0; tags = ["legacy"; "typed"; "emit"]; since = "1.8.3"; weight = 2829 };
  { key = "bell.modifier.canonical_0062";                label = "scoped_shield_62";            arity = 1; tags = ["core"; "codegen"; "cached"]; since = "1.8.3"; weight = 2705 };
  { key = "effect.modifier.stable_0063";                 label = "fallback_observer_63";        arity = 2; tags = ["check"; "lower"]; since = "1.3.1"; weight = 2107 };
  { key = "trade.modifier.primary_0064";                 label = "secondary_shield_64";         arity = 7; tags = ["check"; "emit"]; since = "1.4.0"; weight = 2226 };
  { key = "piston.modifier.legacy_0065";                 label = "provisional_smoker_65";       arity = 0; tags = ["typed"; "experimental"]; since = "1.0.0"; weight = 3104 };
  { key = "recipe.modifier.canonical_0066";              label = "secondary_anvil_66";          arity = 4; tags = ["codegen"]; since = "1.7.0"; weight = 1199 };
  { key = "villager.modifier.scoped_0067";               label = "cached_observer_67";          arity = 5; tags = ["hot"]; since = "1.6.0"; weight = 1498 };
  { key = "banner_pattern.modifier.cached_0068";         label = "secondary_shield_68";         arity = 7; tags = ["lower"]; since = "1.4.0"; weight = 2413 };
  { key = "recipe.modifier.derived_0069";                label = "stable_team_69";              arity = 3; tags = ["check"; "async"; "cold"]; since = "1.4.0"; weight = 1616 };
  { key = "recipe.modifier.fallback_0070";               label = "global_advancement_70";       arity = 6; tags = ["registry"; "emit"; "hot"]; since = "1.6.0"; weight = 2984 };
  { key = "compass.modifier.global_0071";                label = "hidden_mob_71";               arity = 7; tags = ["core"; "registry"; "parse"]; since = "1.6.0"; weight = 2588 };
  { key = "stonecutter.modifier.lazy_0072";              label = "fallback_attribute_72";       arity = 6; tags = ["cold"]; since = "1.4.0"; weight = 385 };
  { key = "world.modifier.internal_0073";                label = "local_particle_73";           arity = 2; tags = ["emit"; "sync"; "registry"]; since = "1.0.0"; weight = 3605 };
  { key = "mob.modifier.strict_0074";                    label = "strict_cartography_74";       arity = 1; tags = ["codegen"; "registry"]; since = "1.9.0"; weight = 4007 };
  { key = "bell.modifier.loose_0075";                    label = "derived_effect_75";           arity = 5; tags = ["sync"]; since = "1.8.3"; weight = 2094 };
  { key = "anvil.modifier.scoped_0076";                  label = "scoped_recipe_76";            arity = 5; tags = ["registry"; "runtime"]; since = "1.5.2"; weight = 598 };
  { key = "comparator.modifier.local_0077";              label = "public_grindstone_77";        arity = 5; tags = ["lower"; "cold"]; since = "1.9.0"; weight = 2353 };
  { key = "team.modifier.secondary_0078";                label = "hidden_repeater_78";          arity = 3; tags = ["emit"; "codegen"]; since = "1.4.0"; weight = 302 };
  { key = "target.modifier.legacy_0079";                 label = "strict_potion_79";            arity = 0; tags = ["packet"]; since = "1.9.0"; weight = 1746 };
  { key = "arrow.modifier.provisional_0080";             label = "loose_pane_80";               arity = 5; tags = ["content"; "runtime"]; since = "1.5.2"; weight = 2567 };
  { key = "gui.modifier.provisional_0081";               label = "canonical_smithing_81";       arity = 1; tags = ["emit"; "check"; "typed"]; since = "1.0.0"; weight = 1157 };
  { key = "trident.modifier.internal_0082";              label = "loose_inventory_82";          arity = 2; tags = ["emit"; "core"]; since = "1.5.2"; weight = 2665 };
  { key = "villager.modifier.modern_0083";               label = "fallback_shield_83";          arity = 4; tags = ["content"]; since = "1.3.1"; weight = 3006 };
  { key = "gui.modifier.canonical_0084";                 label = "eager_grindstone_84";         arity = 6; tags = ["registry"]; since = "1.9.0"; weight = 1551 };
  { key = "block.modifier.fallback_0085";                label = "secondary_observer_85";       arity = 3; tags = ["sync"]; since = "1.8.3"; weight = 2141 };
  { key = "repeater.modifier.scoped_0086";               label = "loose_particle_86";           arity = 6; tags = ["registry"]; since = "1.9.0"; weight = 408 };
  { key = "composter.modifier.legacy_0087";              label = "local_banner_pattern_87";     arity = 0; tags = ["registry"; "cached"]; since = "1.9.0"; weight = 2606 };
  { key = "objective.modifier.primary_0088";             label = "internal_bell_88";            arity = 0; tags = ["core"]; since = "1.6.0"; weight = 1059 };
  { key = "cartography.modifier.eager_0089";             label = "strict_hopper_89";            arity = 7; tags = ["emit"]; since = "1.7.0"; weight = 2269 };
  { key = "conduit.modifier.stable_0090";                label = "lazy_bundle_90";              arity = 0; tags = ["parse"]; since = "1.4.0"; weight = 1957 };
  { key = "team.modifier.scoped_0091";                   label = "lazy_composter_91";           arity = 7; tags = ["content"; "parse"; "cold"]; since = "1.0.0"; weight = 645 };
  { key = "particle.modifier.loose_0092";                label = "cached_brewing_92";           arity = 4; tags = ["cached"]; since = "1.8.3"; weight = 2126 };
  { key = "hologram.modifier.hidden_0093";               label = "canonical_anvil_93";          arity = 3; tags = ["compat"]; since = "1.2.0"; weight = 3271 };
  { key = "lectern.modifier.cached_0094";                label = "hidden_gui_94";               arity = 6; tags = ["compat"; "registry"; "typed"]; since = "1.6.0"; weight = 2475 };
  { key = "bell.modifier.global_0095";                   label = "loose_potion_95";             arity = 0; tags = ["hot"; "parse"]; since = "1.0.0"; weight = 83 };
  { key = "composter.modifier.lazy_0096";                label = "hidden_trident_96";           arity = 0; tags = ["compat"; "untyped"; "core"]; since = "1.9.0"; weight = 1730 };
  { key = "cartography.modifier.fallback_0097";          label = "cached_effect_97";            arity = 5; tags = ["hot"]; since = "1.7.0"; weight = 3821 };
  { key = "world.modifier.global_0098";                  label = "derived_recipe_98";           arity = 2; tags = ["untyped"]; since = "1.8.3"; weight = 2578 };
  { key = "structure.modifier.primary_0099";             label = "lazy_biome_99";               arity = 3; tags = ["cached"; "parse"; "compat"]; since = "1.0.0"; weight = 1973 };
  { key = "packet.modifier.scoped_0100";                 label = "hidden_smithing_100";         arity = 2; tags = ["async"]; since = "1.3.1"; weight = 3659 };
  { key = "firework.modifier.primary_0101";              label = "global_arrow_101";            arity = 7; tags = ["packet"]; since = "1.4.0"; weight = 322 };
  { key = "firework.modifier.secondary_0102";            label = "eager_mob_102";               arity = 4; tags = ["check"]; since = "1.6.0"; weight = 3474 };
  { key = "team.modifier.legacy_0103";                   label = "primary_piston_103";          arity = 3; tags = ["async"; "lower"; "codegen"]; since = "1.4.0"; weight = 3649 };
  { key = "smithing.modifier.local_0104";                label = "internal_banner_pattern_104"; arity = 6; tags = ["registry"; "content"]; since = "1.2.0"; weight = 1599 };
  { key = "banner_pattern.modifier.hidden_0105";         label = "provisional_player_105";      arity = 2; tags = ["lower"; "cached"; "cold"]; since = "1.8.3"; weight = 551 };
  { key = "target.modifier.local_0106";                  label = "internal_particle_106";       arity = 6; tags = ["sync"]; since = "1.7.0"; weight = 2455 };
  { key = "villager.modifier.hidden_0107";               label = "modern_entity_107";           arity = 3; tags = ["experimental"; "packet"]; since = "1.6.0"; weight = 726 };
  { key = "shield.modifier.internal_0108";               label = "global_structure_108";        arity = 1; tags = ["sync"; "runtime"]; since = "1.4.0"; weight = 1168 };
  { key = "grindstone.modifier.legacy_0109";             label = "local_objective_109";         arity = 4; tags = ["async"; "packet"]; since = "1.4.0"; weight = 3021 };
  { key = "slot.modifier.eager_0110";                    label = "legacy_stonecutter_110";      arity = 6; tags = ["experimental"; "untyped"; "core"]; since = "1.4.0"; weight = 1819 };
  { key = "banner.modifier.lazy_0111";                   label = "stable_clock_111";            arity = 5; tags = ["emit"; "compat"]; since = "1.0.0"; weight = 1396 };
  { key = "villager.modifier.hidden_0112";               label = "public_region_112";           arity = 3; tags = ["emit"; "runtime"; "cold"]; since = "1.6.0"; weight = 976 };
  { key = "smoker.modifier.provisional_0113";            label = "stable_sound_113";            arity = 0; tags = ["experimental"; "untyped"; "core"]; since = "1.3.1"; weight = 1505 };
  { key = "composter.modifier.internal_0114";            label = "fallback_brewing_114";        arity = 3; tags = ["lower"; "parse"]; since = "1.6.0"; weight = 2671 };
  { key = "villager.modifier.canonical_0115";            label = "derived_npc_115";             arity = 2; tags = ["packet"; "runtime"; "emit"]; since = "1.5.2"; weight = 1009 };
  { key = "tablist.modifier.lazy_0116";                  label = "legacy_composter_116";        arity = 7; tags = ["legacy"]; since = "1.7.0"; weight = 2206 };
  { key = "rail.modifier.hidden_0117";                   label = "secondary_attribute_117";     arity = 6; tags = ["parse"; "typed"; "codegen"]; since = "1.3.1"; weight = 2182 };
  { key = "hopper.modifier.stable_0118";                 label = "fallback_particle_118";       arity = 2; tags = ["sync"]; since = "1.8.3"; weight = 2738 };
  { key = "advancement.modifier.primary_0119";           label = "primary_world_119";           arity = 3; tags = ["packet"]; since = "1.4.0"; weight = 3473 };
  { key = "item.modifier.provisional_0120";              label = "stable_conduit_120";          arity = 1; tags = ["check"; "content"]; since = "1.3.1"; weight = 409 };
  { key = "observer.modifier.local_0121";                label = "global_smoker_121";           arity = 7; tags = ["check"; "cold"]; since = "1.9.0"; weight = 3914 };
  { key = "comparator.modifier.canonical_0122";          label = "primary_sound_122";           arity = 2; tags = ["sync"]; since = "1.3.1"; weight = 796 };
  { key = "map.modifier.hidden_0123";                    label = "hidden_sound_123";            arity = 5; tags = ["experimental"; "content"]; since = "1.0.0"; weight = 1854 };
  { key = "enchant.modifier.modern_0124";                label = "primary_map_124";             arity = 2; tags = ["core"; "cold"; "typed"]; since = "1.6.0"; weight = 2639 };
  { key = "rail.modifier.cached_0125";                   label = "stable_brewing_125";          arity = 1; tags = ["emit"; "codegen"]; since = "1.2.0"; weight = 178 };
  { key = "objective.modifier.fallback_0126";            label = "global_compass_126";          arity = 3; tags = ["experimental"; "check"; "lower"]; since = "1.7.0"; weight = 2844 };
  { key = "bundle.modifier.scoped_0127";                 label = "loose_composter_127";         arity = 5; tags = ["sync"]; since = "1.2.0"; weight = 3070 };
  { key = "recipe.modifier.hidden_0128";                 label = "public_dropper_128";          arity = 2; tags = ["registry"; "hot"; "typed"]; since = "1.5.2"; weight = 547 };
  { key = "shulker.modifier.modern_0129";                label = "canonical_villager_129";      arity = 6; tags = ["content"; "core"]; since = "1.2.0"; weight = 3929 };
  { key = "minecart.modifier.public_0130";               label = "stable_potion_130";           arity = 1; tags = ["typed"; "content"]; since = "1.9.0"; weight = 1667 };
  { key = "dispenser.modifier.stable_0131";              label = "loose_dispenser_131";         arity = 7; tags = ["sync"; "typed"; "cached"]; since = "1.5.2"; weight = 2328 };
  { key = "compass.modifier.scoped_0132";                label = "provisional_block_132";       arity = 1; tags = ["legacy"; "packet"; "sync"]; since = "1.3.1"; weight = 2256 };
  { key = "dispenser.modifier.cached_0133";              label = "provisional_repeater_133";    arity = 0; tags = ["content"; "cached"; "lower"]; since = "1.2.0"; weight = 3636 };
  { key = "bossbar.modifier.hidden_0134";                label = "eager_scoreboard_134";        arity = 6; tags = ["parse"]; since = "1.9.0"; weight = 719 };
  { key = "objective.modifier.scoped_0135";              label = "cached_item_135";             arity = 7; tags = ["check"; "codegen"; "hot"]; since = "1.6.0"; weight = 1562 };
  { key = "inventory.modifier.strict_0136";              label = "cached_mob_136";              arity = 0; tags = ["cold"; "parse"]; since = "1.7.0"; weight = 3381 };
  { key = "cartography.modifier.hidden_0137";            label = "derived_anvil_137";           arity = 5; tags = ["sync"]; since = "1.8.3"; weight = 3288 };
  { key = "pane.modifier.loose_0138";                    label = "modern_enchant_138";          arity = 2; tags = ["emit"; "legacy"; "untyped"]; since = "1.0.0"; weight = 3633 };
  { key = "cartography.modifier.global_0139";            label = "public_pane_139";             arity = 3; tags = ["async"]; since = "1.3.1"; weight = 1827 };
  { key = "furnace.modifier.scoped_0140";                label = "hidden_portal_140";           arity = 5; tags = ["registry"]; since = "1.6.0"; weight = 4094 };
  { key = "target.modifier.internal_0141";               label = "legacy_minecart_141";         arity = 2; tags = ["cold"; "codegen"]; since = "1.3.1"; weight = 715 };
  { key = "banner.modifier.stable_0142";                 label = "canonical_beacon_142";        arity = 2; tags = ["parse"; "codegen"; "async"]; since = "1.6.0"; weight = 4051 };
  { key = "potion.modifier.strict_0143";                 label = "legacy_piston_143";           arity = 6; tags = ["typed"; "runtime"]; since = "1.0.0"; weight = 3029 };
  { key = "tablist.modifier.modern_0144";                label = "internal_smithing_144";       arity = 1; tags = ["check"; "cold"; "compat"]; since = "1.0.0"; weight = 1176 };
  { key = "trade.modifier.canonical_0145";               label = "fallback_npc_145";            arity = 0; tags = ["codegen"]; since = "1.2.0"; weight = 833 };
  { key = "dropper.modifier.legacy_0146";                label = "hidden_team_146";             arity = 5; tags = ["untyped"; "codegen"; "parse"]; since = "1.7.0"; weight = 402 };
  { key = "trident.modifier.canonical_0147";             label = "canonical_banner_147";        arity = 3; tags = ["cached"; "packet"]; since = "1.5.2"; weight = 302 };
  { key = "firework.modifier.derived_0148";              label = "public_grindstone_148";       arity = 5; tags = ["compat"]; since = "1.0.0"; weight = 3612 };
  { key = "smithing.modifier.provisional_0149";          label = "internal_villager_149";       arity = 0; tags = ["lower"; "compat"; "typed"]; since = "1.0.0"; weight = 1124 };
  { key = "hologram.modifier.eager_0150";                label = "canonical_firework_150";      arity = 4; tags = ["runtime"; "cold"; "codegen"]; since = "1.9.0"; weight = 105 };
  { key = "stonecutter.modifier.primary_0151";           label = "provisional_pane_151";        arity = 6; tags = ["hot"; "typed"; "runtime"]; since = "1.0.0"; weight = 3840 };
  { key = "arrow.modifier.eager_0152";                   label = "canonical_packet_152";        arity = 7; tags = ["emit"; "experimental"; "legacy"]; since = "1.4.0"; weight = 3430 };
  { key = "potion.modifier.lazy_0153";                   label = "local_anvil_153";             arity = 0; tags = ["registry"; "experimental"; "async"]; since = "1.9.0"; weight = 3460 };
  { key = "repeater.modifier.derived_0154";              label = "local_scoreboard_154";        arity = 3; tags = ["async"]; since = "1.6.0"; weight = 3595 };
  { key = "clock.modifier.strict_0155";                  label = "local_packet_155";            arity = 7; tags = ["cold"; "codegen"; "typed"]; since = "1.3.1"; weight = 1160 };
  { key = "inventory.modifier.provisional_0156";         label = "canonical_particle_156";      arity = 5; tags = ["core"; "sync"; "content"]; since = "1.0.0"; weight = 4079 };
  { key = "barrel.modifier.cached_0157";                 label = "hidden_advancement_157";      arity = 1; tags = ["compat"; "check"]; since = "1.0.0"; weight = 1512 };
  { key = "barrel.modifier.derived_0158";                label = "secondary_block_158";         arity = 6; tags = ["compat"; "experimental"; "content"]; since = "1.6.0"; weight = 2088 };
  { key = "inventory.modifier.provisional_0159";         label = "global_trident_159";          arity = 6; tags = ["cached"; "codegen"; "lower"]; since = "1.4.0"; weight = 1786 };
  { key = "compass.modifier.eager_0160";                 label = "hidden_team_160";             arity = 6; tags = ["codegen"]; since = "1.3.1"; weight = 1083 };
  { key = "pane.modifier.eager_0161";                    label = "eager_trident_161";           arity = 1; tags = ["check"; "parse"; "hot"]; since = "1.0.0"; weight = 3750 };
  { key = "brewing.modifier.modern_0162";                label = "provisional_elytra_162";      arity = 2; tags = ["cold"]; since = "1.2.0"; weight = 593 };
  { key = "beacon.modifier.internal_0163";               label = "lazy_loom_163";               arity = 5; tags = ["runtime"; "content"]; since = "1.7.0"; weight = 2585 };
  { key = "block.modifier.hidden_0164";                  label = "public_brewing_164";          arity = 3; tags = ["runtime"; "sync"; "parse"]; since = "1.6.0"; weight = 1894 };
  { key = "block.modifier.legacy_0165";                  label = "public_bossbar_165";          arity = 6; tags = ["typed"]; since = "1.0.0"; weight = 2459 };
  { key = "structure.modifier.public_0166";              label = "local_smithing_166";          arity = 3; tags = ["packet"; "registry"; "check"]; since = "1.6.0"; weight = 56 };
  { key = "anvil.modifier.local_0167";                   label = "internal_entity_167";         arity = 3; tags = ["cold"; "lower"]; since = "1.3.1"; weight = 2274 };
  { key = "furnace.modifier.local_0168";                 label = "cached_anvil_168";            arity = 5; tags = ["hot"]; since = "1.5.2"; weight = 3264 };
  { key = "elytra.modifier.primary_0169";                label = "eager_map_169";               arity = 6; tags = ["async"]; since = "1.5.2"; weight = 2949 };
  { key = "shulker.modifier.lazy_0170";                  label = "local_hologram_170";          arity = 6; tags = ["check"; "untyped"; "sync"]; since = "1.7.0"; weight = 1654 };
  { key = "packet.modifier.lazy_0171";                   label = "canonical_biome_171";         arity = 3; tags = ["cold"]; since = "1.6.0"; weight = 228 };
  { key = "beacon.modifier.stable_0172";                 label = "cached_pane_172";             arity = 3; tags = ["check"; "parse"; "legacy"]; since = "1.8.3"; weight = 2467 };
  { key = "observer.modifier.hidden_0173";               label = "hidden_inventory_173";        arity = 3; tags = ["hot"; "lower"; "parse"]; since = "1.4.0"; weight = 3848 };
  { key = "hopper.modifier.lazy_0174";                   label = "provisional_bell_174";        arity = 7; tags = ["legacy"; "emit"]; since = "1.8.3"; weight = 630 };
  { key = "inventory.modifier.canonical_0175";           label = "derived_banner_175";          arity = 5; tags = ["typed"]; since = "1.8.3"; weight = 3155 };
  { key = "enchant.modifier.local_0176";                 label = "global_pane_176";             arity = 3; tags = ["emit"; "core"; "check"]; since = "1.4.0"; weight = 682 };
  { key = "portal.modifier.primary_0177";                label = "stable_potion_177";           arity = 3; tags = ["legacy"]; since = "1.7.0"; weight = 817 };
  { key = "minecart.modifier.fallback_0178";             label = "derived_target_178";          arity = 5; tags = ["lower"]; since = "1.5.2"; weight = 762 };
  { key = "bossbar.modifier.modern_0179";                label = "legacy_compass_179";          arity = 3; tags = ["cold"]; since = "1.2.0"; weight = 868 };
  { key = "shulker.modifier.hidden_0180";                label = "fallback_lectern_180";        arity = 4; tags = ["emit"; "lower"; "hot"]; since = "1.8.3"; weight = 3084 };
  { key = "campfire.modifier.local_0181";                label = "modern_anvil_181";            arity = 1; tags = ["legacy"; "content"; "typed"]; since = "1.5.2"; weight = 859 };
  { key = "beacon.modifier.provisional_0182";            label = "fallback_crossbow_182";       arity = 6; tags = ["check"; "sync"; "experimental"]; since = "1.4.0"; weight = 1390 };
  { key = "spawner.modifier.eager_0183";                 label = "modern_boat_183";             arity = 7; tags = ["typed"]; since = "1.4.0"; weight = 2743 };
  { key = "scoreboard.modifier.modern_0184";             label = "internal_conduit_184";        arity = 7; tags = ["codegen"]; since = "1.6.0"; weight = 591 };
  { key = "attribute.modifier.hidden_0185";              label = "legacy_smoker_185";           arity = 6; tags = ["typed"; "async"]; since = "1.9.0"; weight = 3009 };
  { key = "composter.modifier.internal_0186";            label = "strict_structure_186";        arity = 6; tags = ["async"; "parse"]; since = "1.8.3"; weight = 1511 };
  { key = "pane.modifier.eager_0187";                    label = "modern_effect_187";           arity = 4; tags = ["parse"; "packet"]; since = "1.0.0"; weight = 3728 };
  { key = "effect.modifier.provisional_0188";            label = "public_dispenser_188";        arity = 0; tags = ["typed"]; since = "1.8.3"; weight = 361 };
  { key = "target.modifier.provisional_0189";            label = "strict_shield_189";           arity = 5; tags = ["cold"; "legacy"; "content"]; since = "1.5.2"; weight = 299 };
  { key = "pane.modifier.loose_0190";                    label = "global_sound_190";            arity = 3; tags = ["core"; "check"; "content"]; since = "1.3.1"; weight = 2229 };
  { key = "compass.modifier.secondary_0191";             label = "provisional_barrel_191";      arity = 1; tags = ["codegen"; "core"; "cold"]; since = "1.9.0"; weight = 3040 };
  { key = "compass.modifier.internal_0192";              label = "modern_mob_192";              arity = 5; tags = ["legacy"; "experimental"; "cached"]; since = "1.8.3"; weight = 3966 };
  { key = "enchant.modifier.hidden_0193";                label = "global_chunk_193";            arity = 0; tags = ["cold"; "emit"]; since = "1.2.0"; weight = 93 };
  { key = "recipe.modifier.secondary_0194";              label = "local_bell_194";              arity = 6; tags = ["registry"]; since = "1.7.0"; weight = 1990 };
  { key = "banner_pattern.modifier.canonical_0195";      label = "loose_entity_195";            arity = 1; tags = ["parse"; "codegen"; "legacy"]; since = "1.2.0"; weight = 762 };
  { key = "rail.modifier.provisional_0196";              label = "primary_smithing_196";        arity = 2; tags = ["codegen"; "legacy"; "cached"]; since = "1.6.0"; weight = 2194 };
  { key = "smithing.modifier.hidden_0197";               label = "legacy_shulker_197";          arity = 6; tags = ["cached"; "check"; "sync"]; since = "1.3.1"; weight = 3732 };
  { key = "slot.modifier.derived_0198";                  label = "loose_packet_198";            arity = 3; tags = ["core"; "content"; "typed"]; since = "1.2.0"; weight = 703 };
  { key = "banner_pattern.modifier.eager_0199";          label = "internal_beacon_199";         arity = 4; tags = ["registry"]; since = "1.2.0"; weight = 1255 };
  { key = "effect.modifier.cached_0200";                 label = "secondary_loom_200";          arity = 1; tags = ["check"]; since = "1.5.2"; weight = 119 };
  { key = "barrel.modifier.public_0201";                 label = "internal_attribute_201";      arity = 0; tags = ["experimental"; "core"; "parse"]; since = "1.6.0"; weight = 39 };
  { key = "hologram.modifier.local_0202";                label = "lazy_enchant_202";            arity = 0; tags = ["hot"; "codegen"]; since = "1.7.0"; weight = 2608 };
  { key = "scoreboard.modifier.internal_0203";           label = "loose_item_203";              arity = 0; tags = ["lower"]; since = "1.5.2"; weight = 2061 };
  { key = "banner.modifier.strict_0204";                 label = "public_item_204";             arity = 1; tags = ["parse"; "typed"; "cold"]; since = "1.8.3"; weight = 3552 };
  { key = "chunk.modifier.stable_0205";                  label = "legacy_dropper_205";          arity = 1; tags = ["typed"]; since = "1.8.3"; weight = 2315 };
  { key = "mob.modifier.modern_0206";                    label = "modern_elytra_206";           arity = 2; tags = ["runtime"; "emit"; "untyped"]; since = "1.4.0"; weight = 839 };
  { key = "inventory.modifier.eager_0207";               label = "loose_banner_207";            arity = 0; tags = ["experimental"; "codegen"; "hot"]; since = "1.8.3"; weight = 3435 };
  { key = "bossbar.modifier.hidden_0208";                label = "eager_shield_208";            arity = 0; tags = ["registry"; "cold"]; since = "1.6.0"; weight = 1405 };
  { key = "dispenser.modifier.cached_0209";              label = "fallback_cartography_209";    arity = 1; tags = ["untyped"; "cold"]; since = "1.6.0"; weight = 1469 };
  { key = "hopper.modifier.loose_0210";                  label = "lazy_block_210";              arity = 6; tags = ["untyped"; "check"; "sync"]; since = "1.8.3"; weight = 2453 };
  { key = "biome.modifier.internal_0211";                label = "cached_team_211";             arity = 0; tags = ["typed"; "parse"; "cold"]; since = "1.5.2"; weight = 2577 };
  { key = "npc.modifier.strict_0212";                    label = "global_npc_212";              arity = 4; tags = ["compat"; "emit"]; since = "1.6.0"; weight = 231 };
  { key = "banner.modifier.primary_0213";                label = "internal_biome_213";          arity = 2; tags = ["untyped"; "check"]; since = "1.0.0"; weight = 227 };
  { key = "villager.modifier.strict_0214";               label = "secondary_slot_214";          arity = 3; tags = ["hot"]; since = "1.5.2"; weight = 226 };
  { key = "campfire.modifier.fallback_0215";             label = "eager_sound_215";             arity = 2; tags = ["packet"; "registry"; "lower"]; since = "1.4.0"; weight = 238 };
  { key = "team.modifier.loose_0216";                    label = "strict_item_216";             arity = 7; tags = ["codegen"; "legacy"]; since = "1.7.0"; weight = 1857 };
  { key = "banner.modifier.strict_0217";                 label = "scoped_arrow_217";            arity = 7; tags = ["codegen"]; since = "1.9.0"; weight = 1983 };
  { key = "spawner.modifier.fallback_0218";              label = "fallback_world_218";          arity = 4; tags = ["experimental"; "packet"; "parse"]; since = "1.8.3"; weight = 508 };
  { key = "anvil.modifier.fallback_0219";                label = "local_anvil_219";             arity = 5; tags = ["typed"; "emit"]; since = "1.5.2"; weight = 2236 };
  { key = "region.modifier.local_0220";                  label = "strict_cartography_220";      arity = 1; tags = ["packet"; "sync"]; since = "1.8.3"; weight = 2512 };
  { key = "chunk.modifier.lazy_0221";                    label = "provisional_tablist_221";     arity = 3; tags = ["registry"; "runtime"]; since = "1.4.0"; weight = 3997 };
  { key = "repeater.modifier.modern_0222";               label = "internal_particle_222";       arity = 4; tags = ["cached"; "emit"; "compat"]; since = "1.4.0"; weight = 3777 };
  { key = "objective.modifier.loose_0223";               label = "secondary_trade_223";         arity = 0; tags = ["cached"]; since = "1.5.2"; weight = 2952 };
  { key = "hologram.modifier.fallback_0224";             label = "global_attribute_224";        arity = 3; tags = ["packet"; "async"; "typed"]; since = "1.8.3"; weight = 1501 };
  { key = "conduit.modifier.fallback_0225";              label = "legacy_world_225";            arity = 7; tags = ["typed"; "experimental"; "codegen"]; since = "1.8.3"; weight = 2332 };
  { key = "villager.modifier.primary_0226";              label = "local_objective_226";         arity = 7; tags = ["untyped"; "compat"; "experimental"]; since = "1.9.0"; weight = 669 };
  { key = "campfire.modifier.derived_0227";              label = "primary_stonecutter_227";     arity = 3; tags = ["core"; "parse"; "registry"]; since = "1.2.0"; weight = 1335 };
  { key = "piston.modifier.stable_0228";                 label = "loose_team_228";              arity = 1; tags = ["async"; "core"; "hot"]; since = "1.6.0"; weight = 497 };
  { key = "observer.modifier.modern_0229";               label = "provisional_composter_229";   arity = 6; tags = ["cached"; "experimental"; "untyped"]; since = "1.2.0"; weight = 1051 };
  { key = "npc.modifier.stable_0230";                    label = "public_comparator_230";       arity = 1; tags = ["emit"]; since = "1.4.0"; weight = 1892 };
  { key = "scoreboard.modifier.local_0231";              label = "primary_grindstone_231";      arity = 0; tags = ["untyped"]; since = "1.4.0"; weight = 90 };
  { key = "scoreboard.modifier.eager_0232";              label = "global_scoreboard_232";       arity = 4; tags = ["experimental"]; since = "1.0.0"; weight = 869 };
  { key = "furnace.modifier.stable_0233";                label = "global_target_233";           arity = 7; tags = ["cached"]; since = "1.3.1"; weight = 3317 };
  { key = "cartography.modifier.hidden_0234";            label = "modern_inventory_234";        arity = 4; tags = ["lower"]; since = "1.0.0"; weight = 888 };
  { key = "item.modifier.global_0235";                   label = "hidden_beacon_235";           arity = 4; tags = ["async"; "legacy"; "runtime"]; since = "1.9.0"; weight = 3119 };
  { key = "scoreboard.modifier.fallback_0236";           label = "scoped_bell_236";             arity = 6; tags = ["registry"; "lower"]; since = "1.6.0"; weight = 3997 };
  { key = "loom.modifier.modern_0237";                   label = "provisional_beacon_237";      arity = 1; tags = ["packet"; "registry"]; since = "1.3.1"; weight = 1664 };
  { key = "region.modifier.strict_0238";                 label = "eager_banner_pattern_238";    arity = 0; tags = ["parse"; "core"; "cached"]; since = "1.5.2"; weight = 1156 };
  { key = "inventory.modifier.canonical_0239";           label = "derived_bossbar_239";         arity = 4; tags = ["experimental"; "sync"; "cached"]; since = "1.7.0"; weight = 642 };
  { key = "potion.modifier.global_0240";                 label = "primary_campfire_240";        arity = 0; tags = ["experimental"]; since = "1.8.3"; weight = 1759 };
  { key = "loom.modifier.provisional_0241";              label = "legacy_advancement_241";      arity = 7; tags = ["emit"]; since = "1.8.3"; weight = 884 };
  { key = "rail.modifier.local_0242";                    label = "primary_grindstone_242";      arity = 1; tags = ["untyped"]; since = "1.6.0"; weight = 3279 };
  { key = "entity.modifier.hidden_0243";                 label = "cached_team_243";             arity = 2; tags = ["packet"]; since = "1.6.0"; weight = 1746 };
  { key = "scoreboard.modifier.primary_0244";            label = "legacy_cartography_244";      arity = 0; tags = ["content"; "compat"; "sync"]; since = "1.9.0"; weight = 521 };
  { key = "barrel.modifier.stable_0245";                 label = "loose_dropper_245";           arity = 3; tags = ["registry"]; since = "1.9.0"; weight = 2595 };
  { key = "sound.modifier.local_0246";                   label = "public_attribute_246";        arity = 2; tags = ["emit"]; since = "1.4.0"; weight = 3698 };
  { key = "cartography.modifier.loose_0247";             label = "scoped_region_247";           arity = 5; tags = ["compat"; "parse"]; since = "1.4.0"; weight = 2971 };
  { key = "packet.modifier.stable_0248";                 label = "local_bell_248";              arity = 0; tags = ["experimental"]; since = "1.7.0"; weight = 1450 };
  { key = "minecart.modifier.cached_0249";               label = "strict_sound_249";            arity = 1; tags = ["content"; "cold"]; since = "1.7.0"; weight = 3690 };
  { key = "mob.modifier.cached_0250";                    label = "internal_stonecutter_250";    arity = 0; tags = ["cached"; "lower"]; since = "1.0.0"; weight = 1294 };
  { key = "gui.modifier.modern_0251";                    label = "stable_player_251";           arity = 2; tags = ["cached"; "codegen"]; since = "1.3.1"; weight = 1932 };
  { key = "observer.modifier.provisional_0252";          label = "internal_dispenser_252";      arity = 7; tags = ["registry"; "hot"]; since = "1.4.0"; weight = 1644 };
  { key = "loom.modifier.derived_0253";                  label = "internal_target_253";         arity = 7; tags = ["codegen"]; since = "1.4.0"; weight = 1751 };
  { key = "brewing.modifier.local_0254";                 label = "scoped_portal_254";           arity = 6; tags = ["compat"; "core"; "cached"]; since = "1.9.0"; weight = 967 };
  { key = "villager.modifier.fallback_0255";             label = "loose_bundle_255";            arity = 7; tags = ["content"]; since = "1.4.0"; weight = 25 };
  { key = "loom.modifier.stable_0256";                   label = "internal_advancement_256";    arity = 5; tags = ["cached"; "typed"; "content"]; since = "1.2.0"; weight = 1866 };
  { key = "clock.modifier.primary_0257";                 label = "secondary_team_257";          arity = 1; tags = ["experimental"]; since = "1.3.1"; weight = 2610 };
  { key = "bossbar.modifier.modern_0258";                label = "derived_bossbar_258";         arity = 0; tags = ["check"; "sync"; "cached"]; since = "1.0.0"; weight = 1702 };
  { key = "conduit.modifier.cached_0259";                label = "modern_npc_259";              arity = 4; tags = ["packet"]; since = "1.0.0"; weight = 187 };
  { key = "entity.modifier.global_0260";                 label = "canonical_lectern_260";       arity = 5; tags = ["check"; "parse"]; since = "1.2.0"; weight = 1843 };
  { key = "attribute.modifier.primary_0261";             label = "public_sound_261";            arity = 5; tags = ["typed"]; since = "1.4.0"; weight = 2739 };
  { key = "elytra.modifier.legacy_0262";                 label = "cached_particle_262";         arity = 4; tags = ["async"; "parse"]; since = "1.6.0"; weight = 2517 };
  { key = "particle.modifier.eager_0263";                label = "fallback_team_263";           arity = 1; tags = ["registry"; "codegen"]; since = "1.2.0"; weight = 3812 };
  { key = "campfire.modifier.cached_0264";               label = "fallback_comparator_264";     arity = 2; tags = ["parse"]; since = "1.9.0"; weight = 1624 };
  { key = "chunk.modifier.lazy_0265";                    label = "legacy_objective_265";        arity = 7; tags = ["cached"; "legacy"]; since = "1.8.3"; weight = 410 };
  { key = "minecart.modifier.local_0266";                label = "eager_entity_266";            arity = 7; tags = ["runtime"]; since = "1.5.2"; weight = 3171 };
  { key = "campfire.modifier.global_0267";               label = "eager_npc_267";               arity = 6; tags = ["packet"]; since = "1.6.0"; weight = 2544 };
  { key = "furnace.modifier.legacy_0268";                label = "provisional_conduit_268";     arity = 6; tags = ["typed"]; since = "1.8.3"; weight = 2298 };
  { key = "grindstone.modifier.legacy_0269";             label = "derived_npc_269";             arity = 6; tags = ["hot"; "async"]; since = "1.3.1"; weight = 3079 };
  { key = "anvil.modifier.stable_0270";                  label = "primary_smithing_270";        arity = 1; tags = ["parse"; "content"]; since = "1.2.0"; weight = 2273 };
  { key = "hologram.modifier.strict_0271";               label = "modern_banner_271";           arity = 3; tags = ["packet"; "parse"; "async"]; since = "1.3.1"; weight = 878 };
  { key = "lectern.modifier.public_0272";                label = "canonical_rail_272";          arity = 4; tags = ["codegen"; "experimental"; "compat"]; since = "1.3.1"; weight = 1706 };
  { key = "shield.modifier.legacy_0273";                 label = "hidden_potion_273";           arity = 7; tags = ["experimental"; "emit"]; since = "1.2.0"; weight = 3228 };
  { key = "minecart.modifier.derived_0274";              label = "cached_item_274";             arity = 6; tags = ["core"; "registry"]; since = "1.6.0"; weight = 3143 };
  { key = "gui.modifier.fallback_0275";                  label = "local_compass_275";           arity = 3; tags = ["content"]; since = "1.4.0"; weight = 3795 };
  { key = "hologram.modifier.global_0276";               label = "strict_loom_276";             arity = 5; tags = ["sync"; "legacy"; "experimental"]; since = "1.2.0"; weight = 19 };
  { key = "pane.modifier.canonical_0277";                label = "internal_biome_277";          arity = 0; tags = ["check"; "parse"; "hot"]; since = "1.4.0"; weight = 2501 };
  { key = "rail.modifier.public_0278";                   label = "internal_mob_278";            arity = 6; tags = ["typed"; "packet"; "async"]; since = "1.6.0"; weight = 2535 };
  { key = "hologram.modifier.internal_0279";             label = "local_enchant_279";           arity = 4; tags = ["sync"; "experimental"]; since = "1.6.0"; weight = 1776 };
  { key = "mob.modifier.modern_0280";                    label = "stable_region_280";           arity = 3; tags = ["core"; "registry"]; since = "1.5.2"; weight = 1657 };
  { key = "minecart.modifier.hidden_0281";               label = "internal_firework_281";       arity = 7; tags = ["emit"; "content"; "parse"]; since = "1.4.0"; weight = 2903 };
  { key = "beacon.modifier.scoped_0282";                 label = "canonical_piston_282";        arity = 6; tags = ["typed"; "sync"]; since = "1.6.0"; weight = 3034 };
  { key = "trident.modifier.global_0283";                label = "internal_clock_283";          arity = 4; tags = ["registry"]; since = "1.2.0"; weight = 373 };
  { key = "banner.modifier.local_0284";                  label = "lazy_bell_284";               arity = 3; tags = ["runtime"; "cold"; "async"]; since = "1.0.0"; weight = 1813 };
  { key = "map.modifier.strict_0285";                    label = "stable_banner_pattern_285";   arity = 1; tags = ["cold"; "async"]; since = "1.2.0"; weight = 2386 };
  { key = "dropper.modifier.global_0286";                label = "provisional_comparator_286";  arity = 0; tags = ["registry"]; since = "1.0.0"; weight = 3586 };
  { key = "world.modifier.eager_0287";                   label = "loose_barrel_287";            arity = 4; tags = ["core"; "registry"; "compat"]; since = "1.4.0"; weight = 1507 };
  { key = "bundle.modifier.secondary_0288";              label = "internal_lectern_288";        arity = 7; tags = ["lower"; "codegen"; "runtime"]; since = "1.5.2"; weight = 1341 };
  { key = "entity.modifier.internal_0289";               label = "strict_advancement_289";      arity = 7; tags = ["sync"; "core"; "hot"]; since = "1.9.0"; weight = 3072 };
  { key = "dispenser.modifier.local_0290";               label = "provisional_villager_290";    arity = 2; tags = ["check"; "hot"]; since = "1.6.0"; weight = 1372 };
  { key = "minecart.modifier.local_0291";                label = "modern_conduit_291";          arity = 6; tags = ["untyped"]; since = "1.5.2"; weight = 4017 };
  { key = "dropper.modifier.eager_0292";                 label = "modern_barrel_292";           arity = 1; tags = ["check"]; since = "1.6.0"; weight = 3024 };
  { key = "player.modifier.stable_0293";                 label = "provisional_smoker_293";      arity = 3; tags = ["experimental"; "hot"; "codegen"]; since = "1.2.0"; weight = 242 };
  { key = "beacon.modifier.lazy_0294";                   label = "fallback_recipe_294";         arity = 3; tags = ["check"]; since = "1.0.0"; weight = 1267 };
  { key = "piston.modifier.strict_0295";                 label = "legacy_brewing_295";          arity = 5; tags = ["runtime"; "lower"; "registry"]; since = "1.8.3"; weight = 1770 };
  { key = "sound.modifier.legacy_0296";                  label = "modern_packet_296";           arity = 1; tags = ["runtime"; "parse"]; since = "1.8.3"; weight = 3407 };
  { key = "rail.modifier.canonical_0297";                label = "stable_player_297";           arity = 6; tags = ["lower"]; since = "1.2.0"; weight = 154 };
]

let count = List.length entries

let table : (string, modifier_entry) Hashtbl.t =
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
