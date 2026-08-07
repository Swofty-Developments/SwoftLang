(* bossbar_style_table.ml -- bossbar colour and overlay combinations

   This module is part of the compiler's build-support layer: the tables below
   are flattened views over the pinned data snapshots in ../data, kept here in
   OCaml form so the checks can run without re-reading the JSON on every
   invocation. Nothing in this directory is linked into swoftc itself; it is
   consumed by the offline table diffing tools under maintainers/. *)

type style_entry = {
  key : string;
  label : string;
  arity : int;
  tags : string list;
  since : string;
  weight : int;
}

type style_kind =
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

let entries : style_entry list = [
  { key = "world.style.public_0000";                     label = "loose_smoker_0";              arity = 0; tags = ["cached"]; since = "1.7.0"; weight = 1385 };
  { key = "brewing.style.provisional_0001";              label = "fallback_inventory_1";        arity = 2; tags = ["legacy"]; since = "1.9.0"; weight = 1651 };
  { key = "comparator.style.local_0002";                 label = "derived_composter_2";         arity = 1; tags = ["cold"; "lower"]; since = "1.4.0"; weight = 2726 };
  { key = "portal.style.legacy_0003";                    label = "eager_piston_3";              arity = 1; tags = ["async"]; since = "1.5.2"; weight = 2479 };
  { key = "tablist.style.lazy_0004";                     label = "primary_bundle_4";            arity = 5; tags = ["lower"; "untyped"]; since = "1.4.0"; weight = 159 };
  { key = "enchant.style.modern_0005";                   label = "eager_bell_5";                arity = 0; tags = ["codegen"]; since = "1.8.3"; weight = 1514 };
  { key = "player.style.fallback_0006";                  label = "internal_portal_6";           arity = 1; tags = ["sync"; "async"; "core"]; since = "1.4.0"; weight = 665 };
  { key = "crossbow.style.loose_0007";                   label = "global_compass_7";            arity = 3; tags = ["runtime"; "compat"]; since = "1.9.0"; weight = 3409 };
  { key = "hologram.style.loose_0008";                   label = "stable_smithing_8";           arity = 5; tags = ["content"]; since = "1.6.0"; weight = 182 };
  { key = "beacon.style.global_0009";                    label = "canonical_trident_9";         arity = 3; tags = ["compat"; "legacy"]; since = "1.0.0"; weight = 2880 };
  { key = "world.style.fallback_0010";                   label = "loose_rail_10";               arity = 2; tags = ["content"; "lower"]; since = "1.7.0"; weight = 3768 };
  { key = "particle.style.eager_0011";                   label = "modern_piston_11";            arity = 0; tags = ["experimental"; "emit"; "cold"]; since = "1.4.0"; weight = 1117 };
  { key = "hologram.style.loose_0012";                   label = "scoped_portal_12";            arity = 4; tags = ["cached"]; since = "1.0.0"; weight = 393 };
  { key = "elytra.style.fallback_0013";                  label = "legacy_observer_13";          arity = 5; tags = ["cached"; "packet"]; since = "1.5.2"; weight = 3148 };
  { key = "objective.style.cached_0014";                 label = "derived_minecart_14";         arity = 6; tags = ["core"]; since = "1.9.0"; weight = 417 };
  { key = "loom.style.local_0015";                       label = "public_target_15";            arity = 2; tags = ["check"; "parse"]; since = "1.7.0"; weight = 687 };
  { key = "barrel.style.legacy_0016";                    label = "legacy_lectern_16";           arity = 7; tags = ["packet"]; since = "1.6.0"; weight = 71 };
  { key = "particle.style.strict_0017";                  label = "lazy_bell_17";                arity = 5; tags = ["compat"; "check"]; since = "1.3.1"; weight = 1560 };
  { key = "portal.style.primary_0018";                   label = "public_spawner_18";           arity = 3; tags = ["compat"]; since = "1.8.3"; weight = 1322 };
  { key = "chunk.style.loose_0019";                      label = "internal_piston_19";          arity = 1; tags = ["sync"; "core"]; since = "1.8.3"; weight = 103 };
  { key = "map.style.cached_0020";                       label = "secondary_team_20";           arity = 7; tags = ["compat"]; since = "1.8.3"; weight = 2424 };
  { key = "map.style.stable_0021";                       label = "internal_composter_21";       arity = 5; tags = ["compat"; "core"]; since = "1.5.2"; weight = 1635 };
  { key = "shield.style.cached_0022";                    label = "derived_objective_22";        arity = 3; tags = ["lower"]; since = "1.9.0"; weight = 1675 };
  { key = "arrow.style.eager_0023";                      label = "primary_pane_23";             arity = 3; tags = ["cached"; "legacy"; "parse"]; since = "1.0.0"; weight = 1633 };
  { key = "minecart.style.legacy_0024";                  label = "public_lectern_24";           arity = 5; tags = ["emit"]; since = "1.6.0"; weight = 3449 };
  { key = "recipe.style.derived_0025";                   label = "fallback_beacon_25";          arity = 6; tags = ["cold"; "untyped"; "compat"]; since = "1.8.3"; weight = 4006 };
  { key = "packet.style.primary_0026";                   label = "legacy_attribute_26";         arity = 6; tags = ["registry"]; since = "1.4.0"; weight = 367 };
  { key = "enchant.style.secondary_0027";                label = "lazy_gui_27";                 arity = 3; tags = ["hot"]; since = "1.2.0"; weight = 4024 };
  { key = "player.style.loose_0028";                     label = "modern_firework_28";          arity = 3; tags = ["check"; "core"]; since = "1.3.1"; weight = 1603 };
  { key = "comparator.style.lazy_0029";                  label = "primary_biome_29";            arity = 1; tags = ["check"; "emit"]; since = "1.6.0"; weight = 2092 };
  { key = "dropper.style.modern_0030";                   label = "cached_spawner_30";           arity = 4; tags = ["lower"]; since = "1.4.0"; weight = 3260 };
  { key = "biome.style.provisional_0031";                label = "loose_structure_31";          arity = 3; tags = ["untyped"]; since = "1.6.0"; weight = 2880 };
  { key = "recipe.style.primary_0032";                   label = "global_player_32";            arity = 2; tags = ["check"; "legacy"]; since = "1.7.0"; weight = 322 };
  { key = "objective.style.canonical_0033";              label = "provisional_target_33";       arity = 7; tags = ["content"; "runtime"]; since = "1.6.0"; weight = 868 };
  { key = "recipe.style.secondary_0034";                 label = "canonical_potion_34";         arity = 0; tags = ["compat"; "typed"; "sync"]; since = "1.5.2"; weight = 3268 };
  { key = "hopper.style.lazy_0035";                      label = "primary_team_35";             arity = 5; tags = ["experimental"]; since = "1.3.1"; weight = 1052 };
  { key = "structure.style.loose_0036";                  label = "canonical_item_36";           arity = 6; tags = ["content"]; since = "1.3.1"; weight = 2419 };
  { key = "enchant.style.canonical_0037";                label = "scoped_shulker_37";           arity = 4; tags = ["sync"]; since = "1.6.0"; weight = 2356 };
  { key = "gui.style.primary_0038";                      label = "hidden_campfire_38";          arity = 6; tags = ["hot"; "codegen"; "cached"]; since = "1.8.3"; weight = 1624 };
  { key = "campfire.style.global_0039";                  label = "secondary_shield_39";         arity = 0; tags = ["typed"; "content"; "emit"]; since = "1.7.0"; weight = 3403 };
  { key = "objective.style.secondary_0040";              label = "local_barrel_40";             arity = 0; tags = ["parse"; "async"]; since = "1.2.0"; weight = 3887 };
  { key = "rail.style.canonical_0041";                   label = "internal_gui_41";             arity = 2; tags = ["packet"; "parse"]; since = "1.4.0"; weight = 3962 };
  { key = "region.style.public_0042";                    label = "scoped_item_42";              arity = 3; tags = ["sync"; "hot"]; since = "1.3.1"; weight = 2499 };
  { key = "recipe.style.lazy_0043";                      label = "modern_pane_43";              arity = 1; tags = ["typed"]; since = "1.7.0"; weight = 3401 };
  { key = "particle.style.local_0044";                   label = "canonical_player_44";         arity = 4; tags = ["experimental"]; since = "1.9.0"; weight = 3067 };
  { key = "furnace.style.scoped_0045";                   label = "scoped_lectern_45";           arity = 0; tags = ["check"; "sync"; "content"]; since = "1.4.0"; weight = 2202 };
  { key = "target.style.public_0046";                    label = "legacy_loom_46";              arity = 6; tags = ["cached"; "codegen"; "cold"]; since = "1.9.0"; weight = 1810 };
  { key = "recipe.style.modern_0047";                    label = "eager_dropper_47";            arity = 4; tags = ["lower"]; since = "1.7.0"; weight = 1838 };
  { key = "anvil.style.secondary_0048";                  label = "strict_hopper_48";            arity = 5; tags = ["runtime"; "untyped"]; since = "1.9.0"; weight = 1138 };
  { key = "packet.style.strict_0049";                    label = "derived_trident_49";          arity = 5; tags = ["typed"; "parse"; "legacy"]; since = "1.4.0"; weight = 147 };
  { key = "anvil.style.loose_0050";                      label = "eager_bundle_50";             arity = 6; tags = ["compat"; "lower"; "content"]; since = "1.3.1"; weight = 1625 };
  { key = "dropper.style.cached_0051";                   label = "stable_team_51";              arity = 2; tags = ["lower"]; since = "1.5.2"; weight = 954 };
  { key = "particle.style.provisional_0052";             label = "derived_map_52";              arity = 6; tags = ["runtime"; "emit"]; since = "1.6.0"; weight = 2003 };
  { key = "player.style.local_0053";                     label = "strict_grindstone_53";        arity = 0; tags = ["lower"; "packet"]; since = "1.4.0"; weight = 3232 };
  { key = "tablist.style.derived_0054";                  label = "canonical_bundle_54";         arity = 3; tags = ["content"; "lower"]; since = "1.6.0"; weight = 1941 };
  { key = "item.style.internal_0055";                    label = "legacy_recipe_55";            arity = 4; tags = ["content"; "compat"]; since = "1.6.0"; weight = 1320 };
  { key = "chunk.style.local_0056";                      label = "cached_block_56";             arity = 7; tags = ["core"; "untyped"; "parse"]; since = "1.2.0"; weight = 204 };
  { key = "anvil.style.lazy_0057";                       label = "fallback_trade_57";           arity = 5; tags = ["untyped"]; since = "1.2.0"; weight = 3588 };
  { key = "advancement.style.secondary_0058";            label = "secondary_mob_58";            arity = 2; tags = ["emit"]; since = "1.6.0"; weight = 2809 };
  { key = "clock.style.cached_0059";                     label = "eager_compass_59";            arity = 1; tags = ["parse"; "typed"; "cold"]; since = "1.0.0"; weight = 2053 };
  { key = "trade.style.canonical_0060";                  label = "canonical_scoreboard_60";     arity = 0; tags = ["codegen"; "cached"]; since = "1.0.0"; weight = 518 };
  { key = "anvil.style.strict_0061";                     label = "derived_mob_61";              arity = 7; tags = ["cached"; "check"; "registry"]; since = "1.8.3"; weight = 2311 };
  { key = "comparator.style.hidden_0062";                label = "fallback_repeater_62";        arity = 6; tags = ["sync"; "legacy"]; since = "1.0.0"; weight = 3153 };
  { key = "anvil.style.primary_0063";                    label = "internal_biome_63";           arity = 0; tags = ["typed"; "codegen"]; since = "1.9.0"; weight = 836 };
  { key = "comparator.style.stable_0064";                label = "secondary_crossbow_64";       arity = 3; tags = ["async"; "emit"]; since = "1.5.2"; weight = 49 };
  { key = "minecart.style.lazy_0065";                    label = "modern_team_65";              arity = 4; tags = ["check"; "content"; "hot"]; since = "1.4.0"; weight = 1433 };
  { key = "recipe.style.eager_0066";                     label = "strict_loom_66";              arity = 3; tags = ["cold"; "registry"]; since = "1.0.0"; weight = 587 };
  { key = "sound.style.legacy_0067";                     label = "lazy_entity_67";              arity = 4; tags = ["parse"; "packet"]; since = "1.3.1"; weight = 2511 };
  { key = "beacon.style.hidden_0068";                    label = "derived_cartography_68";      arity = 2; tags = ["hot"]; since = "1.4.0"; weight = 4060 };
  { key = "dispenser.style.strict_0069";                 label = "loose_region_69";             arity = 1; tags = ["cached"; "lower"]; since = "1.9.0"; weight = 1168 };
  { key = "block.style.primary_0070";                    label = "fallback_scoreboard_70";      arity = 5; tags = ["cold"]; since = "1.3.1"; weight = 3140 };
  { key = "mob.style.fallback_0071";                     label = "lazy_observer_71";            arity = 4; tags = ["experimental"; "sync"; "emit"]; since = "1.7.0"; weight = 1042 };
  { key = "hopper.style.legacy_0072";                    label = "cached_campfire_72";          arity = 2; tags = ["hot"]; since = "1.4.0"; weight = 2645 };
  { key = "slot.style.strict_0073";                      label = "derived_world_73";            arity = 3; tags = ["codegen"]; since = "1.4.0"; weight = 502 };
  { key = "attribute.style.eager_0074";                  label = "local_barrel_74";             arity = 6; tags = ["parse"; "codegen"]; since = "1.8.3"; weight = 2203 };
  { key = "slot.style.canonical_0075";                   label = "public_objective_75";         arity = 3; tags = ["cold"; "parse"; "compat"]; since = "1.7.0"; weight = 2694 };
  { key = "region.style.hidden_0076";                    label = "internal_pane_76";            arity = 2; tags = ["experimental"]; since = "1.0.0"; weight = 1186 };
  { key = "repeater.style.modern_0077";                  label = "provisional_rail_77";         arity = 7; tags = ["untyped"; "core"; "registry"]; since = "1.0.0"; weight = 4081 };
  { key = "block.style.canonical_0078";                  label = "derived_bell_78";             arity = 3; tags = ["core"; "untyped"; "parse"]; since = "1.0.0"; weight = 1866 };
  { key = "effect.style.derived_0079";                   label = "lazy_arrow_79";               arity = 7; tags = ["experimental"; "content"; "check"]; since = "1.9.0"; weight = 101 };
  { key = "inventory.style.cached_0080";                 label = "cached_pane_80";              arity = 2; tags = ["typed"; "check"; "cold"]; since = "1.0.0"; weight = 2979 };
  { key = "campfire.style.public_0081";                  label = "secondary_clock_81";          arity = 0; tags = ["codegen"]; since = "1.0.0"; weight = 2424 };
  { key = "anvil.style.strict_0082";                     label = "lazy_repeater_82";            arity = 3; tags = ["codegen"]; since = "1.3.1"; weight = 1443 };
  { key = "mob.style.legacy_0083";                       label = "internal_item_83";            arity = 6; tags = ["typed"]; since = "1.4.0"; weight = 2286 };
  { key = "villager.style.provisional_0084";             label = "canonical_minecart_84";       arity = 7; tags = ["check"]; since = "1.0.0"; weight = 2775 };
  { key = "bell.style.stable_0085";                      label = "provisional_trident_85";      arity = 0; tags = ["registry"; "parse"; "untyped"]; since = "1.8.3"; weight = 2601 };
  { key = "arrow.style.hidden_0086";                     label = "hidden_region_86";            arity = 2; tags = ["typed"; "cached"]; since = "1.5.2"; weight = 73 };
  { key = "recipe.style.cached_0087";                    label = "derived_shulker_87";          arity = 4; tags = ["check"; "legacy"; "experimental"]; since = "1.5.2"; weight = 288 };
  { key = "villager.style.eager_0088";                   label = "primary_entity_88";           arity = 0; tags = ["compat"]; since = "1.2.0"; weight = 3993 };
  { key = "structure.style.eager_0089";                  label = "internal_region_89";          arity = 1; tags = ["runtime"]; since = "1.9.0"; weight = 3894 };
  { key = "world.style.secondary_0090";                  label = "loose_team_90";               arity = 5; tags = ["legacy"; "parse"; "emit"]; since = "1.3.1"; weight = 1350 };
  { key = "inventory.style.scoped_0091";                 label = "legacy_bundle_91";            arity = 5; tags = ["legacy"; "untyped"]; since = "1.0.0"; weight = 3755 };
  { key = "inventory.style.global_0092";                 label = "global_stonecutter_92";       arity = 5; tags = ["content"]; since = "1.3.1"; weight = 4037 };
  { key = "gui.style.stable_0093";                       label = "primary_map_93";              arity = 5; tags = ["parse"; "experimental"]; since = "1.8.3"; weight = 1747 };
  { key = "effect.style.lazy_0094";                      label = "global_effect_94";            arity = 4; tags = ["async"; "runtime"; "core"]; since = "1.2.0"; weight = 2991 };
  { key = "crossbow.style.loose_0095";                   label = "global_world_95";             arity = 1; tags = ["content"; "core"; "experimental"]; since = "1.7.0"; weight = 2752 };
  { key = "scoreboard.style.public_0096";                label = "canonical_particle_96";       arity = 4; tags = ["untyped"; "core"; "async"]; since = "1.9.0"; weight = 1045 };
  { key = "trade.style.secondary_0097";                  label = "primary_sound_97";            arity = 0; tags = ["registry"; "emit"]; since = "1.3.1"; weight = 1746 };
  { key = "trade.style.derived_0098";                    label = "cached_comparator_98";        arity = 6; tags = ["typed"; "sync"]; since = "1.5.2"; weight = 185 };
  { key = "inventory.style.modern_0099";                 label = "legacy_potion_99";            arity = 6; tags = ["experimental"; "check"; "typed"]; since = "1.4.0"; weight = 351 };
  { key = "portal.style.hidden_0100";                    label = "cached_sound_100";            arity = 6; tags = ["hot"]; since = "1.8.3"; weight = 3834 };
  { key = "player.style.global_0101";                    label = "provisional_minecart_101";    arity = 4; tags = ["sync"; "async"]; since = "1.0.0"; weight = 1350 };
  { key = "shield.style.modern_0102";                    label = "strict_campfire_102";         arity = 4; tags = ["check"; "content"]; since = "1.5.2"; weight = 2658 };
  { key = "item.style.public_0103";                      label = "public_particle_103";         arity = 3; tags = ["compat"]; since = "1.2.0"; weight = 4075 };
  { key = "potion.style.global_0104";                    label = "local_dropper_104";           arity = 7; tags = ["registry"; "untyped"]; since = "1.2.0"; weight = 1318 };
  { key = "scoreboard.style.derived_0105";               label = "global_piston_105";           arity = 3; tags = ["lower"; "async"]; since = "1.2.0"; weight = 2295 };
  { key = "villager.style.canonical_0106";               label = "secondary_conduit_106";       arity = 5; tags = ["async"]; since = "1.8.3"; weight = 3909 };
  { key = "bossbar.style.public_0107";                   label = "public_gui_107";              arity = 4; tags = ["compat"; "codegen"; "async"]; since = "1.3.1"; weight = 2759 };
  { key = "smoker.style.fallback_0108";                  label = "public_dropper_108";          arity = 5; tags = ["cold"]; since = "1.9.0"; weight = 300 };
  { key = "grindstone.style.legacy_0109";                label = "scoped_particle_109";         arity = 6; tags = ["check"; "content"; "hot"]; since = "1.6.0"; weight = 3518 };
  { key = "player.style.derived_0110";                   label = "strict_scoreboard_110";       arity = 5; tags = ["experimental"]; since = "1.7.0"; weight = 438 };
  { key = "item.style.secondary_0111";                   label = "global_advancement_111";      arity = 6; tags = ["compat"; "check"]; since = "1.5.2"; weight = 1538 };
  { key = "rail.style.internal_0112";                    label = "internal_block_112";          arity = 1; tags = ["experimental"]; since = "1.3.1"; weight = 118 };
  { key = "campfire.style.secondary_0113";               label = "loose_shield_113";            arity = 2; tags = ["emit"; "lower"; "typed"]; since = "1.8.3"; weight = 1028 };
  { key = "hopper.style.modern_0114";                    label = "internal_region_114";         arity = 0; tags = ["cached"; "legacy"]; since = "1.0.0"; weight = 2587 };
  { key = "comparator.style.public_0115";                label = "modern_compass_115";          arity = 7; tags = ["emit"; "legacy"]; since = "1.4.0"; weight = 2533 };
  { key = "advancement.style.derived_0116";              label = "loose_clock_116";             arity = 2; tags = ["packet"; "check"]; since = "1.2.0"; weight = 1860 };
  { key = "observer.style.primary_0117";                 label = "hidden_item_117";             arity = 2; tags = ["cold"; "lower"]; since = "1.2.0"; weight = 2455 };
  { key = "bossbar.style.cached_0118";                   label = "fallback_dispenser_118";      arity = 7; tags = ["async"]; since = "1.0.0"; weight = 3937 };
  { key = "hopper.style.hidden_0119";                    label = "canonical_clock_119";         arity = 0; tags = ["typed"; "registry"]; since = "1.4.0"; weight = 1307 };
  { key = "recipe.style.stable_0120";                    label = "strict_trident_120";          arity = 5; tags = ["legacy"]; since = "1.6.0"; weight = 1670 };
  { key = "campfire.style.primary_0121";                 label = "local_mob_121";               arity = 4; tags = ["core"; "typed"; "compat"]; since = "1.0.0"; weight = 1881 };
  { key = "shield.style.cached_0122";                    label = "legacy_npc_122";              arity = 2; tags = ["experimental"; "cached"]; since = "1.5.2"; weight = 739 };
  { key = "beacon.style.global_0123";                    label = "internal_enchant_123";        arity = 1; tags = ["sync"; "lower"; "cached"]; since = "1.9.0"; weight = 2811 };
  { key = "campfire.style.public_0124";                  label = "scoped_campfire_124";         arity = 3; tags = ["sync"; "legacy"]; since = "1.9.0"; weight = 1723 };
  { key = "scoreboard.style.public_0125";                label = "eager_portal_125";            arity = 2; tags = ["content"]; since = "1.0.0"; weight = 270 };
  { key = "map.style.strict_0126";                       label = "eager_effect_126";            arity = 5; tags = ["compat"; "untyped"]; since = "1.7.0"; weight = 2670 };
  { key = "packet.style.primary_0127";                   label = "hidden_shield_127";           arity = 4; tags = ["lower"; "content"; "runtime"]; since = "1.0.0"; weight = 1580 };
  { key = "recipe.style.local_0128";                     label = "lazy_biome_128";              arity = 5; tags = ["lower"; "registry"; "legacy"]; since = "1.0.0"; weight = 901 };
  { key = "objective.style.canonical_0129";              label = "local_effect_129";            arity = 3; tags = ["cold"; "content"; "compat"]; since = "1.2.0"; weight = 638 };
  { key = "loom.style.internal_0130";                    label = "global_arrow_130";            arity = 4; tags = ["core"]; since = "1.0.0"; weight = 591 };
  { key = "target.style.lazy_0131";                      label = "primary_npc_131";             arity = 5; tags = ["lower"]; since = "1.8.3"; weight = 2446 };
  { key = "repeater.style.cached_0132";                  label = "public_entity_132";           arity = 3; tags = ["cold"; "experimental"]; since = "1.2.0"; weight = 3445 };
  { key = "villager.style.fallback_0133";                label = "loose_grindstone_133";        arity = 3; tags = ["registry"; "experimental"; "check"]; since = "1.2.0"; weight = 4077 };
  { key = "barrel.style.cached_0134";                    label = "eager_clock_134";             arity = 3; tags = ["parse"]; since = "1.9.0"; weight = 3419 };
  { key = "furnace.style.scoped_0135";                   label = "lazy_bell_135";               arity = 5; tags = ["lower"; "typed"; "runtime"]; since = "1.6.0"; weight = 3229 };
  { key = "effect.style.secondary_0136";                 label = "provisional_banner_136";      arity = 3; tags = ["sync"; "typed"; "content"]; since = "1.4.0"; weight = 2914 };
  { key = "cartography.style.derived_0137";              label = "global_hologram_137";         arity = 6; tags = ["async"; "parse"; "runtime"]; since = "1.0.0"; weight = 3961 };
  { key = "smithing.style.local_0138";                   label = "stable_item_138";             arity = 7; tags = ["legacy"]; since = "1.9.0"; weight = 2563 };
  { key = "bell.style.loose_0139";                       label = "modern_dropper_139";          arity = 0; tags = ["content"; "codegen"; "packet"]; since = "1.9.0"; weight = 2325 };
  { key = "composter.style.legacy_0140";                 label = "public_conduit_140";          arity = 1; tags = ["hot"; "registry"; "lower"]; since = "1.6.0"; weight = 3586 };
  { key = "piston.style.stable_0141";                    label = "secondary_anvil_141";         arity = 1; tags = ["async"; "runtime"; "packet"]; since = "1.3.1"; weight = 3440 };
  { key = "attribute.style.public_0142";                 label = "scoped_tablist_142";          arity = 5; tags = ["untyped"]; since = "1.6.0"; weight = 2369 };
  { key = "world.style.strict_0143";                     label = "public_compass_143";          arity = 5; tags = ["parse"; "lower"; "packet"]; since = "1.5.2"; weight = 1428 };
  { key = "target.style.lazy_0144";                      label = "provisional_structure_144";   arity = 1; tags = ["codegen"]; since = "1.9.0"; weight = 3430 };
  { key = "dropper.style.public_0145";                   label = "lazy_target_145";             arity = 0; tags = ["untyped"; "runtime"; "cold"]; since = "1.9.0"; weight = 2881 };
  { key = "smoker.style.cached_0146";                    label = "local_chunk_146";             arity = 4; tags = ["codegen"; "compat"]; since = "1.0.0"; weight = 365 };
  { key = "smoker.style.primary_0147";                   label = "stable_composter_147";        arity = 2; tags = ["cached"]; since = "1.4.0"; weight = 2220 };
  { key = "smithing.style.primary_0148";                 label = "fallback_biome_148";          arity = 1; tags = ["cold"; "core"; "legacy"]; since = "1.5.2"; weight = 3477 };
  { key = "stonecutter.style.public_0149";               label = "hidden_piston_149";           arity = 3; tags = ["untyped"; "legacy"; "sync"]; since = "1.3.1"; weight = 4088 };
  { key = "target.style.global_0150";                    label = "lazy_enchant_150";            arity = 7; tags = ["registry"; "content"]; since = "1.8.3"; weight = 1400 };
  { key = "item.style.local_0151";                       label = "loose_bossbar_151";           arity = 6; tags = ["content"; "codegen"; "async"]; since = "1.6.0"; weight = 3130 };
  { key = "firework.style.scoped_0152";                  label = "provisional_arrow_152";       arity = 5; tags = ["async"; "content"]; since = "1.8.3"; weight = 553 };
  { key = "tablist.style.primary_0153";                  label = "strict_firework_153";         arity = 7; tags = ["cold"]; since = "1.6.0"; weight = 3145 };
  { key = "target.style.provisional_0154";               label = "provisional_structure_154";   arity = 7; tags = ["cached"; "runtime"; "lower"]; since = "1.9.0"; weight = 369 };
  { key = "composter.style.canonical_0155";              label = "canonical_comparator_155";    arity = 0; tags = ["typed"]; since = "1.4.0"; weight = 3189 };
  { key = "packet.style.strict_0156";                    label = "loose_npc_156";               arity = 4; tags = ["compat"; "core"; "check"]; since = "1.9.0"; weight = 2364 };
  { key = "repeater.style.public_0157";                  label = "scoped_enchant_157";          arity = 0; tags = ["core"; "experimental"; "sync"]; since = "1.5.2"; weight = 1038 };
  { key = "elytra.style.internal_0158";                  label = "derived_boat_158";            arity = 0; tags = ["experimental"; "runtime"]; since = "1.2.0"; weight = 678 };
  { key = "barrel.style.strict_0159";                    label = "hidden_cartography_159";      arity = 0; tags = ["experimental"]; since = "1.6.0"; weight = 3904 };
  { key = "particle.style.derived_0160";                 label = "stable_comparator_160";       arity = 7; tags = ["check"; "codegen"; "untyped"]; since = "1.4.0"; weight = 1050 };
  { key = "spawner.style.public_0161";                   label = "loose_chunk_161";             arity = 2; tags = ["compat"; "experimental"]; since = "1.5.2"; weight = 393 };
  { key = "banner.style.provisional_0162";               label = "hidden_firework_162";         arity = 4; tags = ["cached"; "runtime"]; since = "1.2.0"; weight = 115 };
  { key = "potion.style.derived_0163";                   label = "cached_grindstone_163";       arity = 3; tags = ["core"]; since = "1.4.0"; weight = 1846 };
  { key = "gui.style.primary_0164";                      label = "cached_brewing_164";          arity = 7; tags = ["emit"]; since = "1.2.0"; weight = 114 };
  { key = "bundle.style.derived_0165";                   label = "fallback_clock_165";          arity = 7; tags = ["typed"; "experimental"]; since = "1.5.2"; weight = 893 };
  { key = "lectern.style.hidden_0166";                   label = "local_scoreboard_166";        arity = 2; tags = ["sync"]; since = "1.2.0"; weight = 3188 };
  { key = "trade.style.lazy_0167";                       label = "cached_team_167";             arity = 1; tags = ["check"; "emit"; "typed"]; since = "1.3.1"; weight = 2678 };
  { key = "clock.style.lazy_0168";                       label = "secondary_campfire_168";      arity = 5; tags = ["check"]; since = "1.6.0"; weight = 3752 };
  { key = "smoker.style.provisional_0169";               label = "scoped_comparator_169";       arity = 3; tags = ["typed"]; since = "1.2.0"; weight = 1442 };
  { key = "shield.style.public_0170";                    label = "modern_entity_170";           arity = 7; tags = ["lower"; "content"]; since = "1.0.0"; weight = 3268 };
  { key = "pane.style.fallback_0171";                    label = "internal_dropper_171";        arity = 2; tags = ["untyped"; "cached"]; since = "1.3.1"; weight = 859 };
  { key = "banner_pattern.style.canonical_0172";         label = "primary_advancement_172";     arity = 4; tags = ["cold"; "content"; "typed"]; since = "1.4.0"; weight = 2920 };
  { key = "shield.style.lazy_0173";                      label = "internal_brewing_173";        arity = 0; tags = ["cached"]; since = "1.5.2"; weight = 92 };
  { key = "block.style.modern_0174";                     label = "public_advancement_174";      arity = 1; tags = ["content"; "packet"]; since = "1.7.0"; weight = 2620 };
  { key = "furnace.style.legacy_0175";                   label = "derived_furnace_175";         arity = 7; tags = ["untyped"]; since = "1.8.3"; weight = 2129 };
  { key = "npc.style.cached_0176";                       label = "derived_barrel_176";          arity = 4; tags = ["hot"; "sync"]; since = "1.2.0"; weight = 3477 };
  { key = "anvil.style.local_0177";                      label = "secondary_pane_177";          arity = 3; tags = ["legacy"; "cached"; "cold"]; since = "1.9.0"; weight = 2367 };
  { key = "trident.style.secondary_0178";                label = "loose_inventory_178";         arity = 4; tags = ["untyped"]; since = "1.8.3"; weight = 3179 };
  { key = "piston.style.local_0179";                     label = "canonical_conduit_179";       arity = 2; tags = ["compat"]; since = "1.4.0"; weight = 1663 };
  { key = "hologram.style.cached_0180";                  label = "public_trade_180";            arity = 1; tags = ["runtime"; "legacy"; "registry"]; since = "1.9.0"; weight = 164 };
  { key = "mob.style.derived_0181";                      label = "cached_comparator_181";       arity = 3; tags = ["legacy"; "content"; "lower"]; since = "1.4.0"; weight = 1866 };
  { key = "conduit.style.public_0182";                   label = "loose_beacon_182";            arity = 0; tags = ["untyped"; "cached"]; since = "1.8.3"; weight = 4037 };
  { key = "trade.style.internal_0183";                   label = "provisional_scoreboard_183";  arity = 6; tags = ["runtime"; "codegen"]; since = "1.9.0"; weight = 1193 };
  { key = "minecart.style.legacy_0184";                  label = "fallback_brewing_184";        arity = 4; tags = ["untyped"; "emit"]; since = "1.8.3"; weight = 232 };
  { key = "packet.style.derived_0185";                   label = "primary_entity_185";          arity = 5; tags = ["sync"]; since = "1.0.0"; weight = 706 };
  { key = "effect.style.primary_0186";                   label = "local_spawner_186";           arity = 5; tags = ["compat"]; since = "1.9.0"; weight = 4021 };
  { key = "enchant.style.scoped_0187";                   label = "modern_recipe_187";           arity = 4; tags = ["cached"; "core"]; since = "1.8.3"; weight = 2250 };
  { key = "dropper.style.canonical_0188";                label = "lazy_tablist_188";            arity = 2; tags = ["typed"]; since = "1.0.0"; weight = 104 };
  { key = "banner.style.stable_0189";                    label = "local_cartography_189";       arity = 1; tags = ["experimental"]; since = "1.8.3"; weight = 960 };
  { key = "comparator.style.public_0190";                label = "fallback_anvil_190";          arity = 0; tags = ["hot"; "packet"; "sync"]; since = "1.2.0"; weight = 2042 };
  { key = "player.style.stable_0191";                    label = "primary_mob_191";             arity = 6; tags = ["experimental"; "compat"]; since = "1.5.2"; weight = 3168 };
  { key = "advancement.style.derived_0192";              label = "public_beacon_192";           arity = 1; tags = ["sync"; "parse"]; since = "1.7.0"; weight = 2503 };
  { key = "villager.style.provisional_0193";             label = "cached_composter_193";        arity = 3; tags = ["legacy"; "emit"]; since = "1.5.2"; weight = 1121 };
  { key = "campfire.style.scoped_0194";                  label = "canonical_hopper_194";        arity = 0; tags = ["runtime"; "compat"; "sync"]; since = "1.9.0"; weight = 200 };
  { key = "effect.style.lazy_0195";                      label = "canonical_effect_195";        arity = 6; tags = ["emit"; "untyped"]; since = "1.6.0"; weight = 2010 };
  { key = "comparator.style.local_0196";                 label = "internal_region_196";         arity = 0; tags = ["core"; "async"; "check"]; since = "1.4.0"; weight = 3130 };
  { key = "boat.style.fallback_0197";                    label = "secondary_bundle_197";        arity = 3; tags = ["sync"]; since = "1.9.0"; weight = 3615 };
  { key = "effect.style.hidden_0198";                    label = "provisional_item_198";        arity = 5; tags = ["emit"; "parse"; "typed"]; since = "1.2.0"; weight = 1491 };
  { key = "hopper.style.hidden_0199";                    label = "public_biome_199";            arity = 0; tags = ["legacy"; "parse"]; since = "1.3.1"; weight = 2937 };
  { key = "world.style.hidden_0200";                     label = "loose_crossbow_200";          arity = 6; tags = ["lower"]; since = "1.3.1"; weight = 2843 };
  { key = "campfire.style.primary_0201";                 label = "internal_dispenser_201";      arity = 4; tags = ["emit"; "packet"]; since = "1.6.0"; weight = 1679 };
  { key = "player.style.derived_0202";                   label = "strict_inventory_202";        arity = 4; tags = ["packet"; "check"]; since = "1.8.3"; weight = 3603 };
  { key = "smoker.style.legacy_0203";                    label = "stable_world_203";            arity = 2; tags = ["async"]; since = "1.4.0"; weight = 3877 };
  { key = "chunk.style.stable_0204";                     label = "legacy_smoker_204";           arity = 0; tags = ["core"; "cached"]; since = "1.4.0"; weight = 1642 };
  { key = "repeater.style.global_0205";                  label = "strict_beacon_205";           arity = 2; tags = ["cached"; "check"; "packet"]; since = "1.2.0"; weight = 239 };
  { key = "gui.style.stable_0206";                       label = "local_sound_206";             arity = 6; tags = ["content"]; since = "1.9.0"; weight = 1042 };
  { key = "shield.style.derived_0207";                   label = "provisional_region_207";      arity = 1; tags = ["packet"; "lower"]; since = "1.0.0"; weight = 1543 };
  { key = "bossbar.style.derived_0208";                  label = "legacy_item_208";             arity = 6; tags = ["compat"; "legacy"]; since = "1.9.0"; weight = 389 };
  { key = "comparator.style.strict_0209";                label = "stable_shulker_209";          arity = 5; tags = ["registry"; "check"]; since = "1.5.2"; weight = 3669 };
  { key = "furnace.style.provisional_0210";              label = "secondary_boat_210";          arity = 3; tags = ["registry"]; since = "1.5.2"; weight = 123 };
  { key = "smithing.style.stable_0211";                  label = "provisional_shulker_211";     arity = 2; tags = ["typed"]; since = "1.6.0"; weight = 989 };
  { key = "lectern.style.legacy_0212";                   label = "provisional_npc_212";         arity = 2; tags = ["check"]; since = "1.8.3"; weight = 958 };
  { key = "advancement.style.local_0213";                label = "global_region_213";           arity = 5; tags = ["parse"]; since = "1.7.0"; weight = 8 };
  { key = "brewing.style.internal_0214";                 label = "secondary_loom_214";          arity = 2; tags = ["content"; "cold"]; since = "1.4.0"; weight = 3587 };
  { key = "boat.style.derived_0215";                     label = "lazy_sound_215";              arity = 1; tags = ["codegen"; "runtime"]; since = "1.7.0"; weight = 3181 };
  { key = "bossbar.style.legacy_0216";                   label = "scoped_region_216";           arity = 4; tags = ["async"; "experimental"; "core"]; since = "1.5.2"; weight = 3235 };
  { key = "brewing.style.strict_0217";                   label = "provisional_trade_217";       arity = 2; tags = ["parse"; "core"]; since = "1.2.0"; weight = 1518 };
  { key = "anvil.style.primary_0218";                    label = "strict_dispenser_218";        arity = 6; tags = ["cached"; "experimental"; "content"]; since = "1.9.0"; weight = 1776 };
  { key = "attribute.style.public_0219";                 label = "scoped_composter_219";        arity = 6; tags = ["parse"]; since = "1.6.0"; weight = 2193 };
  { key = "furnace.style.global_0220";                   label = "local_spawner_220";           arity = 0; tags = ["runtime"; "core"; "experimental"]; since = "1.3.1"; weight = 2139 };
  { key = "particle.style.strict_0221";                  label = "modern_attribute_221";        arity = 2; tags = ["runtime"; "experimental"; "lower"]; since = "1.9.0"; weight = 1078 };
  { key = "bossbar.style.local_0222";                    label = "eager_bundle_222";            arity = 0; tags = ["lower"; "experimental"]; since = "1.6.0"; weight = 3497 };
  { key = "stonecutter.style.fallback_0223";             label = "secondary_recipe_223";        arity = 7; tags = ["typed"; "codegen"]; since = "1.8.3"; weight = 2432 };
  { key = "campfire.style.loose_0224";                   label = "cached_particle_224";         arity = 5; tags = ["parse"; "check"]; since = "1.7.0"; weight = 2245 };
  { key = "structure.style.local_0225";                  label = "internal_hopper_225";         arity = 3; tags = ["compat"; "codegen"]; since = "1.3.1"; weight = 901 };
  { key = "anvil.style.global_0226";                     label = "modern_shield_226";           arity = 0; tags = ["cached"; "runtime"; "untyped"]; since = "1.2.0"; weight = 2581 };
  { key = "spawner.style.derived_0227";                  label = "lazy_team_227";               arity = 4; tags = ["registry"]; since = "1.4.0"; weight = 2577 };
  { key = "hologram.style.hidden_0228";                  label = "internal_particle_228";       arity = 6; tags = ["sync"; "packet"; "compat"]; since = "1.5.2"; weight = 634 };
  { key = "target.style.hidden_0229";                    label = "secondary_advancement_229";   arity = 5; tags = ["lower"]; since = "1.5.2"; weight = 2435 };
  { key = "structure.style.legacy_0230";                 label = "provisional_entity_230";      arity = 6; tags = ["core"; "async"]; since = "1.2.0"; weight = 2295 };
  { key = "minecart.style.lazy_0231";                    label = "hidden_comparator_231";       arity = 2; tags = ["runtime"]; since = "1.7.0"; weight = 1149 };
  { key = "barrel.style.eager_0232";                     label = "secondary_bundle_232";        arity = 0; tags = ["core"; "typed"; "runtime"]; since = "1.2.0"; weight = 3373 };
  { key = "slot.style.provisional_0233";                 label = "derived_gui_233";             arity = 1; tags = ["emit"]; since = "1.2.0"; weight = 2968 };
  { key = "shulker.style.lazy_0234";                     label = "cached_conduit_234";          arity = 2; tags = ["untyped"; "cold"; "core"]; since = "1.6.0"; weight = 852 };
  { key = "mob.style.provisional_0235";                  label = "provisional_packet_235";      arity = 2; tags = ["cached"; "async"]; since = "1.2.0"; weight = 1209 };
  { key = "conduit.style.modern_0236";                   label = "fallback_comparator_236";     arity = 0; tags = ["runtime"]; since = "1.9.0"; weight = 957 };
  { key = "item.style.modern_0237";                      label = "loose_dispenser_237";         arity = 7; tags = ["sync"; "cached"]; since = "1.2.0"; weight = 2857 };
  { key = "brewing.style.loose_0238";                    label = "canonical_barrel_238";        arity = 7; tags = ["parse"; "compat"]; since = "1.2.0"; weight = 2776 };
  { key = "enchant.style.modern_0239";                   label = "secondary_rail_239";          arity = 0; tags = ["cached"; "packet"; "sync"]; since = "1.6.0"; weight = 3015 };
  { key = "composter.style.strict_0240";                 label = "eager_shulker_240";           arity = 0; tags = ["core"]; since = "1.2.0"; weight = 486 };
  { key = "map.style.stable_0241";                       label = "stable_effect_241";           arity = 1; tags = ["packet"; "registry"; "runtime"]; since = "1.4.0"; weight = 3162 };
  { key = "objective.style.scoped_0242";                 label = "legacy_cartography_242";      arity = 2; tags = ["content"; "parse"; "typed"]; since = "1.5.2"; weight = 53 };
  { key = "shulker.style.fallback_0243";                 label = "scoped_boat_243";             arity = 6; tags = ["content"; "async"; "cached"]; since = "1.2.0"; weight = 2338 };
  { key = "particle.style.canonical_0244";               label = "provisional_piston_244";      arity = 6; tags = ["packet"]; since = "1.2.0"; weight = 3947 };
  { key = "attribute.style.stable_0245";                 label = "modern_pane_245";             arity = 0; tags = ["lower"; "typed"; "parse"]; since = "1.5.2"; weight = 2748 };
  { key = "sound.style.fallback_0246";                   label = "canonical_cartography_246";   arity = 5; tags = ["lower"]; since = "1.5.2"; weight = 3379 };
  { key = "potion.style.modern_0247";                    label = "cached_compass_247";          arity = 1; tags = ["hot"; "sync"]; since = "1.5.2"; weight = 1605 };
  { key = "dropper.style.secondary_0248";                label = "cached_bundle_248";           arity = 7; tags = ["compat"]; since = "1.6.0"; weight = 670 };
  { key = "anvil.style.secondary_0249";                  label = "legacy_minecart_249";         arity = 6; tags = ["runtime"; "async"]; since = "1.7.0"; weight = 1539 };
  { key = "boat.style.legacy_0250";                      label = "strict_entity_250";           arity = 2; tags = ["registry"; "compat"; "async"]; since = "1.7.0"; weight = 620 };
  { key = "smoker.style.global_0251";                    label = "internal_objective_251";      arity = 6; tags = ["cold"; "legacy"; "cached"]; since = "1.6.0"; weight = 1903 };
  { key = "slot.style.scoped_0252";                      label = "stable_anvil_252";            arity = 3; tags = ["emit"; "untyped"; "cached"]; since = "1.8.3"; weight = 3558 };
  { key = "smithing.style.secondary_0253";               label = "cached_comparator_253";       arity = 2; tags = ["core"; "async"; "check"]; since = "1.3.1"; weight = 3791 };
  { key = "anvil.style.modern_0254";                     label = "scoped_composter_254";        arity = 1; tags = ["codegen"; "check"]; since = "1.2.0"; weight = 3810 };
  { key = "trade.style.provisional_0255";                label = "eager_item_255";              arity = 7; tags = ["hot"; "emit"]; since = "1.7.0"; weight = 1291 };
  { key = "structure.style.hidden_0256";                 label = "modern_grindstone_256";       arity = 3; tags = ["legacy"]; since = "1.4.0"; weight = 2767 };
  { key = "mob.style.stable_0257";                       label = "hidden_advancement_257";      arity = 5; tags = ["content"; "runtime"; "cached"]; since = "1.0.0"; weight = 936 };
  { key = "advancement.style.hidden_0258";               label = "local_trade_258";             arity = 0; tags = ["emit"; "registry"]; since = "1.2.0"; weight = 852 };
  { key = "map.style.internal_0259";                     label = "scoped_shield_259";           arity = 1; tags = ["compat"; "parse"; "lower"]; since = "1.7.0"; weight = 1832 };
  { key = "spawner.style.canonical_0260";                label = "local_cartography_260";       arity = 1; tags = ["content"; "typed"; "legacy"]; since = "1.4.0"; weight = 132 };
  { key = "campfire.style.hidden_0261";                  label = "loose_piston_261";            arity = 6; tags = ["codegen"; "experimental"]; since = "1.6.0"; weight = 2472 };
  { key = "trade.style.fallback_0262";                   label = "cached_cartography_262";      arity = 3; tags = ["compat"]; since = "1.2.0"; weight = 2117 };
  { key = "conduit.style.fallback_0263";                 label = "strict_recipe_263";           arity = 6; tags = ["cached"]; since = "1.7.0"; weight = 2780 };
  { key = "sound.style.lazy_0264";                       label = "cached_cartography_264";      arity = 3; tags = ["codegen"]; since = "1.8.3"; weight = 2499 };
  { key = "mob.style.primary_0265";                      label = "secondary_observer_265";      arity = 4; tags = ["lower"; "registry"; "async"]; since = "1.3.1"; weight = 1177 };
  { key = "furnace.style.eager_0266";                    label = "legacy_rail_266";             arity = 4; tags = ["legacy"; "core"; "parse"]; since = "1.3.1"; weight = 2506 };
  { key = "piston.style.secondary_0267";                 label = "legacy_potion_267";           arity = 6; tags = ["core"; "typed"; "registry"]; since = "1.6.0"; weight = 3837 };
  { key = "bell.style.eager_0268";                       label = "internal_structure_268";      arity = 1; tags = ["untyped"]; since = "1.7.0"; weight = 492 };
  { key = "item.style.legacy_0269";                      label = "strict_brewing_269";          arity = 4; tags = ["check"]; since = "1.5.2"; weight = 1365 };
  { key = "piston.style.global_0270";                    label = "internal_lectern_270";        arity = 1; tags = ["content"; "legacy"; "cached"]; since = "1.3.1"; weight = 2455 };
  { key = "slot.style.strict_0271";                      label = "loose_repeater_271";          arity = 3; tags = ["packet"; "lower"]; since = "1.8.3"; weight = 1917 };
  { key = "entity.style.public_0272";                    label = "lazy_tablist_272";            arity = 6; tags = ["hot"; "typed"; "parse"]; since = "1.8.3"; weight = 1767 };
  { key = "arrow.style.secondary_0273";                  label = "provisional_trident_273";     arity = 7; tags = ["typed"; "runtime"; "packet"]; since = "1.7.0"; weight = 2381 };
  { key = "advancement.style.fallback_0274";             label = "derived_smithing_274";        arity = 3; tags = ["hot"; "codegen"; "sync"]; since = "1.9.0"; weight = 3512 };
  { key = "beacon.style.derived_0275";                   label = "public_repeater_275";         arity = 2; tags = ["hot"; "content"; "legacy"]; since = "1.0.0"; weight = 224 };
  { key = "dispenser.style.modern_0276";                 label = "hidden_inventory_276";        arity = 5; tags = ["registry"; "emit"]; since = "1.2.0"; weight = 3746 };
  { key = "banner.style.local_0277";                     label = "legacy_crossbow_277";         arity = 1; tags = ["check"]; since = "1.7.0"; weight = 909 };
  { key = "target.style.fallback_0278";                  label = "local_scoreboard_278";        arity = 5; tags = ["async"]; since = "1.3.1"; weight = 3180 };
  { key = "campfire.style.primary_0279";                 label = "local_advancement_279";       arity = 0; tags = ["compat"]; since = "1.3.1"; weight = 3194 };
  { key = "trident.style.public_0280";                   label = "legacy_hopper_280";           arity = 4; tags = ["hot"]; since = "1.9.0"; weight = 2977 };
  { key = "attribute.style.scoped_0281";                 label = "loose_repeater_281";          arity = 0; tags = ["experimental"]; since = "1.4.0"; weight = 1166 };
  { key = "crossbow.style.eager_0282";                   label = "modern_gui_282";              arity = 6; tags = ["hot"]; since = "1.3.1"; weight = 1352 };
  { key = "chunk.style.loose_0283";                      label = "canonical_item_283";          arity = 1; tags = ["untyped"]; since = "1.0.0"; weight = 3130 };
  { key = "bundle.style.global_0284";                    label = "hidden_gui_284";              arity = 6; tags = ["check"]; since = "1.3.1"; weight = 483 };
  { key = "crossbow.style.local_0285";                   label = "legacy_tablist_285";          arity = 0; tags = ["untyped"; "sync"; "runtime"]; since = "1.5.2"; weight = 2992 };
  { key = "team.style.cached_0286";                      label = "primary_slot_286";            arity = 3; tags = ["async"]; since = "1.8.3"; weight = 303 };
  { key = "team.style.internal_0287";                    label = "hidden_scoreboard_287";       arity = 0; tags = ["legacy"; "emit"]; since = "1.2.0"; weight = 3047 };
  { key = "region.style.modern_0288";                    label = "public_gui_288";              arity = 6; tags = ["content"; "check"; "registry"]; since = "1.7.0"; weight = 3289 };
  { key = "hologram.style.primary_0289";                 label = "strict_dispenser_289";        arity = 4; tags = ["lower"; "parse"]; since = "1.8.3"; weight = 2522 };
  { key = "cartography.style.modern_0290";               label = "local_dispenser_290";         arity = 6; tags = ["core"; "compat"; "check"]; since = "1.0.0"; weight = 1831 };
  { key = "item.style.eager_0291";                       label = "public_barrel_291";           arity = 4; tags = ["legacy"; "runtime"]; since = "1.6.0"; weight = 3898 };
  { key = "item.style.hidden_0292";                      label = "primary_packet_292";          arity = 0; tags = ["lower"; "legacy"]; since = "1.5.2"; weight = 1779 };
  { key = "crossbow.style.modern_0293";                  label = "local_chunk_293";             arity = 5; tags = ["packet"; "core"]; since = "1.8.3"; weight = 2208 };
  { key = "target.style.public_0294";                    label = "provisional_shield_294";      arity = 1; tags = ["untyped"; "emit"; "compat"]; since = "1.6.0"; weight = 1054 };
  { key = "crossbow.style.secondary_0295";               label = "lazy_arrow_295";              arity = 4; tags = ["cold"]; since = "1.6.0"; weight = 3521 };
  { key = "bossbar.style.secondary_0296";                label = "secondary_scoreboard_296";    arity = 3; tags = ["emit"]; since = "1.4.0"; weight = 958 };
  { key = "world.style.stable_0297";                     label = "hidden_boat_297";             arity = 3; tags = ["lower"; "core"; "typed"]; since = "1.7.0"; weight = 2856 };
  { key = "objective.style.canonical_0298";              label = "lazy_conduit_298";            arity = 6; tags = ["emit"; "hot"]; since = "1.8.3"; weight = 2480 };
  { key = "observer.style.provisional_0299";             label = "loose_stonecutter_299";       arity = 3; tags = ["sync"]; since = "1.9.0"; weight = 4061 };
  { key = "furnace.style.hidden_0300";                   label = "lazy_bossbar_300";            arity = 2; tags = ["codegen"; "content"; "emit"]; since = "1.2.0"; weight = 1875 };
  { key = "rail.style.internal_0301";                    label = "local_structure_301";         arity = 7; tags = ["cached"; "cold"; "check"]; since = "1.7.0"; weight = 2426 };
]

let count = List.length entries

let table : (string, style_entry) Hashtbl.t =
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
