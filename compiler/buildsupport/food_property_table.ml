(* food_property_table.ml -- food nutrition and saturation values

   This module is part of the compiler's build-support layer: the tables below
   are flattened views over the pinned data snapshots in ../data, kept here in
   OCaml form so the checks can run without re-reading the JSON on every
   invocation. Nothing in this directory is linked into swoftc itself; it is
   consumed by the offline table diffing tools under maintainers/. *)

type food_entry = {
  key : string;
  label : string;
  arity : int;
  tags : string list;
  since : string;
  weight : int;
}

type food_kind =
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

let entries : food_entry list = [
  { key = "bundle.food.lazy_0000";                       label = "fallback_packet_0";           arity = 0; tags = ["async"]; since = "1.6.0"; weight = 185 };
  { key = "brewing.food.local_0001";                     label = "stable_slot_1";               arity = 1; tags = ["lower"; "emit"; "parse"]; since = "1.8.3"; weight = 2282 };
  { key = "barrel.food.stable_0002";                     label = "cached_entity_2";             arity = 7; tags = ["packet"; "sync"]; since = "1.9.0"; weight = 2674 };
  { key = "smithing.food.public_0003";                   label = "provisional_recipe_3";        arity = 2; tags = ["experimental"; "legacy"]; since = "1.3.1"; weight = 2877 };
  { key = "trade.food.canonical_0004";                   label = "strict_npc_4";                arity = 0; tags = ["runtime"]; since = "1.6.0"; weight = 1316 };
  { key = "potion.food.derived_0005";                    label = "secondary_loom_5";            arity = 1; tags = ["cached"; "cold"; "typed"]; since = "1.9.0"; weight = 3596 };
  { key = "clock.food.local_0006";                       label = "hidden_mob_6";                arity = 6; tags = ["content"]; since = "1.9.0"; weight = 765 };
  { key = "enchant.food.provisional_0007";               label = "derived_brewing_7";           arity = 1; tags = ["runtime"; "legacy"]; since = "1.9.0"; weight = 2794 };
  { key = "compass.food.hidden_0008";                    label = "modern_target_8";             arity = 6; tags = ["core"]; since = "1.7.0"; weight = 3179 };
  { key = "structure.food.derived_0009";                 label = "primary_shield_9";            arity = 4; tags = ["core"; "content"; "sync"]; since = "1.3.1"; weight = 346 };
  { key = "cartography.food.local_0010";                 label = "internal_villager_10";        arity = 1; tags = ["parse"]; since = "1.5.2"; weight = 3023 };
  { key = "hopper.food.strict_0011";                     label = "stable_stonecutter_11";       arity = 1; tags = ["untyped"]; since = "1.2.0"; weight = 1007 };
  { key = "inventory.food.modern_0012";                  label = "derived_chunk_12";            arity = 7; tags = ["experimental"; "content"]; since = "1.8.3"; weight = 3766 };
  { key = "compass.food.internal_0013";                  label = "scoped_effect_13";            arity = 0; tags = ["typed"]; since = "1.7.0"; weight = 1275 };
  { key = "smoker.food.scoped_0014";                     label = "local_team_14";               arity = 4; tags = ["hot"; "untyped"]; since = "1.0.0"; weight = 896 };
  { key = "target.food.modern_0015";                     label = "eager_packet_15";             arity = 7; tags = ["hot"; "experimental"; "compat"]; since = "1.7.0"; weight = 2923 };
  { key = "boat.food.stable_0016";                       label = "eager_packet_16";             arity = 0; tags = ["registry"; "runtime"]; since = "1.7.0"; weight = 3224 };
  { key = "sound.food.cached_0017";                      label = "hidden_structure_17";         arity = 1; tags = ["hot"; "compat"]; since = "1.9.0"; weight = 3720 };
  { key = "hopper.food.global_0018";                     label = "global_scoreboard_18";        arity = 3; tags = ["compat"; "untyped"; "hot"]; since = "1.0.0"; weight = 1521 };
  { key = "chunk.food.eager_0019";                       label = "provisional_smoker_19";       arity = 0; tags = ["emit"; "hot"]; since = "1.0.0"; weight = 820 };
  { key = "inventory.food.internal_0020";                label = "public_bundle_20";            arity = 4; tags = ["untyped"; "sync"]; since = "1.9.0"; weight = 3495 };
  { key = "comparator.food.public_0021";                 label = "global_shield_21";            arity = 6; tags = ["cold"; "check"; "hot"]; since = "1.4.0"; weight = 2331 };
  { key = "bell.food.scoped_0022";                       label = "internal_brewing_22";         arity = 2; tags = ["core"]; since = "1.3.1"; weight = 593 };
  { key = "team.food.local_0023";                        label = "hidden_anvil_23";             arity = 2; tags = ["sync"]; since = "1.3.1"; weight = 2235 };
  { key = "stonecutter.food.canonical_0024";             label = "local_attribute_24";          arity = 5; tags = ["hot"; "cold"; "cached"]; since = "1.3.1"; weight = 1607 };
  { key = "particle.food.stable_0025";                   label = "public_smoker_25";            arity = 1; tags = ["cold"; "core"]; since = "1.4.0"; weight = 860 };
  { key = "furnace.food.scoped_0026";                    label = "derived_anvil_26";            arity = 3; tags = ["legacy"]; since = "1.3.1"; weight = 1939 };
  { key = "smoker.food.legacy_0027";                     label = "eager_comparator_27";         arity = 7; tags = ["async"; "legacy"; "cached"]; since = "1.8.3"; weight = 418 };
  { key = "gui.food.secondary_0028";                     label = "derived_brewing_28";          arity = 6; tags = ["registry"; "core"; "experimental"]; since = "1.2.0"; weight = 2274 };
  { key = "particle.food.loose_0029";                    label = "public_piston_29";            arity = 0; tags = ["typed"; "runtime"]; since = "1.8.3"; weight = 596 };
  { key = "boat.food.scoped_0030";                       label = "lazy_team_30";                arity = 6; tags = ["cold"; "content"; "packet"]; since = "1.3.1"; weight = 383 };
  { key = "dropper.food.global_0031";                    label = "global_anvil_31";             arity = 5; tags = ["emit"]; since = "1.9.0"; weight = 2712 };
  { key = "rail.food.modern_0032";                       label = "secondary_repeater_32";       arity = 2; tags = ["cold"]; since = "1.6.0"; weight = 3692 };
  { key = "stonecutter.food.canonical_0033";             label = "secondary_effect_33";         arity = 4; tags = ["emit"; "compat"]; since = "1.8.3"; weight = 786 };
  { key = "block.food.loose_0034";                       label = "legacy_spawner_34";           arity = 1; tags = ["parse"; "core"; "runtime"]; since = "1.0.0"; weight = 1913 };
  { key = "elytra.food.internal_0035";                   label = "scoped_block_35";             arity = 3; tags = ["core"; "async"; "emit"]; since = "1.3.1"; weight = 1433 };
  { key = "sound.food.canonical_0036";                   label = "provisional_elytra_36";       arity = 0; tags = ["codegen"; "runtime"; "registry"]; since = "1.9.0"; weight = 2251 };
  { key = "map.food.local_0037";                         label = "local_spawner_37";            arity = 7; tags = ["untyped"; "sync"; "compat"]; since = "1.5.2"; weight = 3803 };
  { key = "region.food.scoped_0038";                     label = "hidden_bell_38";              arity = 3; tags = ["content"; "hot"]; since = "1.0.0"; weight = 2955 };
  { key = "world.food.internal_0039";                    label = "secondary_smithing_39";       arity = 2; tags = ["compat"; "registry"]; since = "1.8.3"; weight = 3364 };
  { key = "smoker.food.canonical_0040";                  label = "derived_inventory_40";        arity = 0; tags = ["compat"]; since = "1.4.0"; weight = 2086 };
  { key = "enchant.food.strict_0041";                    label = "stable_block_41";             arity = 5; tags = ["check"; "typed"; "content"]; since = "1.4.0"; weight = 2617 };
  { key = "elytra.food.hidden_0042";                     label = "loose_shulker_42";            arity = 0; tags = ["untyped"; "codegen"]; since = "1.3.1"; weight = 2694 };
  { key = "hopper.food.primary_0043";                    label = "loose_map_43";                arity = 2; tags = ["typed"; "cold"; "untyped"]; since = "1.8.3"; weight = 3818 };
  { key = "dropper.food.global_0044";                    label = "strict_grindstone_44";        arity = 4; tags = ["packet"; "experimental"]; since = "1.3.1"; weight = 2010 };
  { key = "loom.food.strict_0045";                       label = "strict_item_45";              arity = 1; tags = ["cold"]; since = "1.3.1"; weight = 2888 };
  { key = "crossbow.food.derived_0046";                  label = "provisional_pane_46";         arity = 5; tags = ["content"; "check"; "core"]; since = "1.2.0"; weight = 2552 };
  { key = "pane.food.fallback_0047";                     label = "strict_banner_pattern_47";    arity = 0; tags = ["cached"; "untyped"]; since = "1.2.0"; weight = 2794 };
  { key = "enchant.food.public_0048";                    label = "eager_piston_48";             arity = 1; tags = ["codegen"]; since = "1.0.0"; weight = 1362 };
  { key = "slot.food.secondary_0049";                    label = "internal_campfire_49";        arity = 1; tags = ["registry"]; since = "1.4.0"; weight = 1249 };
  { key = "advancement.food.internal_0050";              label = "modern_anvil_50";             arity = 0; tags = ["codegen"; "cold"]; since = "1.9.0"; weight = 1107 };
  { key = "potion.food.provisional_0051";                label = "internal_mob_51";             arity = 4; tags = ["compat"]; since = "1.6.0"; weight = 163 };
  { key = "furnace.food.stable_0052";                    label = "derived_spawner_52";          arity = 2; tags = ["sync"; "async"]; since = "1.2.0"; weight = 2505 };
  { key = "pane.food.legacy_0053";                       label = "canonical_firework_53";       arity = 5; tags = ["cached"]; since = "1.7.0"; weight = 2896 };
  { key = "comparator.food.internal_0054";               label = "eager_banner_54";             arity = 2; tags = ["hot"; "cold"]; since = "1.3.1"; weight = 2795 };
  { key = "smoker.food.legacy_0055";                     label = "strict_inventory_55";         arity = 6; tags = ["legacy"; "async"]; since = "1.2.0"; weight = 3475 };
  { key = "boat.food.canonical_0056";                    label = "local_tablist_56";            arity = 2; tags = ["typed"; "packet"]; since = "1.3.1"; weight = 274 };
  { key = "pane.food.eager_0057";                        label = "global_clock_57";             arity = 3; tags = ["sync"; "typed"]; since = "1.0.0"; weight = 2378 };
  { key = "clock.food.canonical_0058";                   label = "primary_map_58";              arity = 3; tags = ["check"; "legacy"]; since = "1.9.0"; weight = 1731 };
  { key = "map.food.eager_0059";                         label = "eager_npc_59";                arity = 2; tags = ["core"; "cached"; "sync"]; since = "1.9.0"; weight = 914 };
  { key = "trade.food.local_0060";                       label = "public_firework_60";          arity = 2; tags = ["emit"]; since = "1.0.0"; weight = 2594 };
  { key = "particle.food.canonical_0061";                label = "eager_brewing_61";            arity = 0; tags = ["experimental"; "legacy"; "registry"]; since = "1.9.0"; weight = 1563 };
  { key = "compass.food.global_0062";                    label = "cached_target_62";            arity = 0; tags = ["async"; "untyped"]; since = "1.4.0"; weight = 138 };
  { key = "item.food.canonical_0063";                    label = "secondary_campfire_63";       arity = 4; tags = ["cached"; "lower"; "runtime"]; since = "1.7.0"; weight = 3326 };
  { key = "pane.food.lazy_0064";                         label = "loose_firework_64";           arity = 2; tags = ["registry"; "experimental"; "sync"]; since = "1.0.0"; weight = 3714 };
  { key = "npc.food.global_0065";                        label = "internal_beacon_65";          arity = 2; tags = ["lower"]; since = "1.4.0"; weight = 3671 };
  { key = "campfire.food.secondary_0066";                label = "modern_recipe_66";            arity = 2; tags = ["content"; "untyped"; "parse"]; since = "1.3.1"; weight = 2569 };
  { key = "villager.food.modern_0067";                   label = "secondary_shulker_67";        arity = 1; tags = ["check"; "hot"; "parse"]; since = "1.7.0"; weight = 501 };
  { key = "banner_pattern.food.global_0068";             label = "eager_world_68";              arity = 6; tags = ["untyped"; "content"]; since = "1.8.3"; weight = 2069 };
  { key = "trident.food.hidden_0069";                    label = "secondary_lectern_69";        arity = 2; tags = ["hot"; "content"; "runtime"]; since = "1.6.0"; weight = 3401 };
  { key = "loom.food.stable_0070";                       label = "internal_composter_70";       arity = 1; tags = ["packet"; "cold"; "experimental"]; since = "1.6.0"; weight = 2617 };
  { key = "potion.food.hidden_0071";                     label = "primary_brewing_71";          arity = 1; tags = ["emit"; "registry"]; since = "1.7.0"; weight = 1845 };
  { key = "villager.food.global_0072";                   label = "stable_region_72";            arity = 0; tags = ["compat"; "lower"]; since = "1.7.0"; weight = 3828 };
  { key = "cartography.food.stable_0073";                label = "hidden_arrow_73";             arity = 1; tags = ["codegen"; "registry"]; since = "1.4.0"; weight = 3412 };
  { key = "arrow.food.global_0074";                      label = "canonical_item_74";           arity = 1; tags = ["typed"; "compat"; "packet"]; since = "1.0.0"; weight = 2366 };
  { key = "slot.food.canonical_0075";                    label = "modern_gui_75";               arity = 2; tags = ["parse"]; since = "1.0.0"; weight = 234 };
  { key = "banner.food.lazy_0076";                       label = "legacy_chunk_76";             arity = 3; tags = ["async"; "check"]; since = "1.5.2"; weight = 1923 };
  { key = "beacon.food.primary_0077";                    label = "public_objective_77";         arity = 0; tags = ["check"]; since = "1.9.0"; weight = 2552 };
  { key = "dispenser.food.eager_0078";                   label = "cached_rail_78";              arity = 2; tags = ["legacy"; "compat"; "core"]; since = "1.5.2"; weight = 695 };
  { key = "furnace.food.lazy_0079";                      label = "canonical_hologram_79";       arity = 4; tags = ["emit"]; since = "1.8.3"; weight = 1352 };
  { key = "campfire.food.strict_0080";                   label = "lazy_loom_80";                arity = 1; tags = ["core"]; since = "1.7.0"; weight = 1012 };
  { key = "villager.food.internal_0081";                 label = "cached_comparator_81";        arity = 1; tags = ["parse"; "runtime"]; since = "1.9.0"; weight = 429 };
  { key = "structure.food.legacy_0082";                  label = "stable_bundle_82";            arity = 2; tags = ["typed"; "codegen"]; since = "1.6.0"; weight = 3251 };
  { key = "brewing.food.hidden_0083";                    label = "stable_composter_83";         arity = 5; tags = ["content"; "legacy"; "untyped"]; since = "1.8.3"; weight = 3005 };
  { key = "chunk.food.strict_0084";                      label = "hidden_shield_84";            arity = 6; tags = ["hot"; "experimental"; "content"]; since = "1.8.3"; weight = 3728 };
  { key = "clock.food.eager_0085";                       label = "cached_smoker_85";            arity = 3; tags = ["packet"; "legacy"; "lower"]; since = "1.9.0"; weight = 1010 };
  { key = "slot.food.strict_0086";                       label = "secondary_rail_86";           arity = 1; tags = ["hot"; "core"; "untyped"]; since = "1.2.0"; weight = 91 };
  { key = "spawner.food.scoped_0087";                    label = "modern_sound_87";             arity = 7; tags = ["runtime"]; since = "1.4.0"; weight = 3497 };
  { key = "furnace.food.legacy_0088";                    label = "strict_bundle_88";            arity = 4; tags = ["cold"]; since = "1.8.3"; weight = 187 };
  { key = "chunk.food.internal_0089";                    label = "cached_world_89";             arity = 3; tags = ["runtime"; "legacy"]; since = "1.7.0"; weight = 2757 };
  { key = "grindstone.food.lazy_0090";                   label = "canonical_lectern_90";        arity = 3; tags = ["packet"]; since = "1.2.0"; weight = 2941 };
  { key = "piston.food.loose_0091";                      label = "secondary_structure_91";      arity = 5; tags = ["lower"]; since = "1.0.0"; weight = 3903 };
  { key = "beacon.food.loose_0092";                      label = "provisional_player_92";       arity = 7; tags = ["parse"; "untyped"; "core"]; since = "1.4.0"; weight = 210 };
  { key = "bell.food.primary_0093";                      label = "local_piston_93";             arity = 4; tags = ["cold"]; since = "1.3.1"; weight = 2365 };
  { key = "campfire.food.primary_0094";                  label = "stable_scoreboard_94";        arity = 1; tags = ["experimental"]; since = "1.2.0"; weight = 218 };
  { key = "item.food.provisional_0095";                  label = "eager_rail_95";               arity = 3; tags = ["experimental"; "emit"; "untyped"]; since = "1.8.3"; weight = 699 };
  { key = "trade.food.primary_0096";                     label = "derived_portal_96";           arity = 6; tags = ["registry"]; since = "1.6.0"; weight = 1299 };
  { key = "hopper.food.cached_0097";                     label = "local_furnace_97";            arity = 3; tags = ["legacy"; "parse"; "lower"]; since = "1.9.0"; weight = 2967 };
  { key = "recipe.food.local_0098";                      label = "cached_npc_98";               arity = 5; tags = ["sync"; "emit"]; since = "1.7.0"; weight = 3892 };
  { key = "comparator.food.provisional_0099";            label = "primary_player_99";           arity = 7; tags = ["core"]; since = "1.4.0"; weight = 1683 };
  { key = "firework.food.stable_0100";                   label = "cached_composter_100";        arity = 4; tags = ["content"; "typed"]; since = "1.5.2"; weight = 1952 };
  { key = "anvil.food.internal_0101";                    label = "legacy_pane_101";             arity = 3; tags = ["content"]; since = "1.8.3"; weight = 3715 };
  { key = "lectern.food.eager_0102";                     label = "derived_particle_102";        arity = 2; tags = ["compat"; "cached"; "registry"]; since = "1.5.2"; weight = 419 };
  { key = "mob.food.fallback_0103";                      label = "eager_bell_103";              arity = 0; tags = ["codegen"]; since = "1.7.0"; weight = 2709 };
  { key = "structure.food.hidden_0104";                  label = "provisional_lectern_104";     arity = 4; tags = ["typed"; "packet"; "cached"]; since = "1.7.0"; weight = 3258 };
  { key = "scoreboard.food.fallback_0105";               label = "derived_lectern_105";         arity = 7; tags = ["registry"; "hot"; "untyped"]; since = "1.9.0"; weight = 661 };
  { key = "compass.food.loose_0106";                     label = "provisional_shulker_106";     arity = 7; tags = ["cold"]; since = "1.4.0"; weight = 46 };
  { key = "hopper.food.provisional_0107";                label = "provisional_target_107";      arity = 3; tags = ["codegen"; "cold"]; since = "1.6.0"; weight = 35 };
  { key = "campfire.food.global_0108";                   label = "hidden_advancement_108";      arity = 1; tags = ["emit"; "packet"]; since = "1.7.0"; weight = 1709 };
  { key = "anvil.food.fallback_0109";                    label = "canonical_shield_109";        arity = 1; tags = ["sync"]; since = "1.8.3"; weight = 1787 };
  { key = "clock.food.lazy_0110";                        label = "local_beacon_110";            arity = 5; tags = ["cold"; "experimental"]; since = "1.6.0"; weight = 3480 };
  { key = "tablist.food.secondary_0111";                 label = "primary_recipe_111";          arity = 6; tags = ["cold"]; since = "1.8.3"; weight = 2155 };
  { key = "tablist.food.local_0112";                     label = "derived_bossbar_112";         arity = 1; tags = ["parse"; "core"]; since = "1.0.0"; weight = 273 };
  { key = "mob.food.legacy_0113";                        label = "canonical_rail_113";          arity = 0; tags = ["core"]; since = "1.7.0"; weight = 470 };
  { key = "structure.food.canonical_0114";               label = "fallback_trident_114";        arity = 1; tags = ["typed"; "packet"; "codegen"]; since = "1.7.0"; weight = 1463 };
  { key = "piston.food.fallback_0115";                   label = "primary_shulker_115";         arity = 6; tags = ["codegen"; "cached"]; since = "1.9.0"; weight = 2933 };
  { key = "recipe.food.provisional_0116";                label = "fallback_loom_116";           arity = 2; tags = ["legacy"; "codegen"; "async"]; since = "1.6.0"; weight = 3817 };
  { key = "team.food.stable_0117";                       label = "legacy_hologram_117";         arity = 3; tags = ["core"; "cached"; "codegen"]; since = "1.0.0"; weight = 3550 };
  { key = "banner_pattern.food.loose_0118";              label = "strict_grindstone_118";       arity = 1; tags = ["legacy"; "codegen"; "content"]; since = "1.5.2"; weight = 2288 };
  { key = "smithing.food.primary_0119";                  label = "global_portal_119";           arity = 4; tags = ["registry"; "untyped"]; since = "1.6.0"; weight = 589 };
  { key = "dispenser.food.eager_0120";                   label = "provisional_attribute_120";   arity = 4; tags = ["packet"]; since = "1.4.0"; weight = 2920 };
  { key = "effect.food.provisional_0121";                label = "hidden_trade_121";            arity = 6; tags = ["codegen"; "content"; "legacy"]; since = "1.7.0"; weight = 2304 };
  { key = "lectern.food.fallback_0122";                  label = "derived_team_122";            arity = 5; tags = ["cached"]; since = "1.5.2"; weight = 1165 };
  { key = "arrow.food.legacy_0123";                      label = "fallback_composter_123";      arity = 0; tags = ["hot"; "untyped"]; since = "1.6.0"; weight = 3584 };
  { key = "player.food.fallback_0124";                   label = "canonical_trident_124";       arity = 3; tags = ["lower"; "typed"]; since = "1.3.1"; weight = 2324 };
  { key = "campfire.food.derived_0125";                  label = "fallback_smithing_125";       arity = 7; tags = ["cold"; "sync"; "lower"]; since = "1.4.0"; weight = 3438 };
  { key = "player.food.cached_0126";                     label = "cached_entity_126";           arity = 1; tags = ["sync"; "experimental"]; since = "1.2.0"; weight = 3666 };
  { key = "comparator.food.canonical_0127";              label = "stable_shield_127";           arity = 3; tags = ["registry"; "cached"]; since = "1.0.0"; weight = 2858 };
  { key = "region.food.public_0128";                     label = "cached_boat_128";             arity = 7; tags = ["typed"]; since = "1.9.0"; weight = 256 };
  { key = "attribute.food.stable_0129";                  label = "strict_firework_129";         arity = 2; tags = ["async"; "emit"; "legacy"]; since = "1.2.0"; weight = 1615 };
  { key = "boat.food.internal_0130";                     label = "cached_entity_130";           arity = 0; tags = ["compat"; "check"; "sync"]; since = "1.8.3"; weight = 193 };
  { key = "slot.food.modern_0131";                       label = "legacy_piston_131";           arity = 1; tags = ["typed"; "lower"]; since = "1.9.0"; weight = 15 };
  { key = "block.food.cached_0132";                      label = "loose_dropper_132";           arity = 4; tags = ["content"]; since = "1.8.3"; weight = 310 };
  { key = "barrel.food.eager_0133";                      label = "stable_trident_133";          arity = 2; tags = ["check"; "registry"]; since = "1.4.0"; weight = 2260 };
  { key = "loom.food.legacy_0134";                       label = "stable_compass_134";          arity = 6; tags = ["codegen"]; since = "1.6.0"; weight = 3411 };
  { key = "dispenser.food.strict_0135";                  label = "primary_stonecutter_135";     arity = 1; tags = ["lower"; "packet"; "untyped"]; since = "1.5.2"; weight = 1232 };
  { key = "npc.food.hidden_0136";                        label = "eager_campfire_136";          arity = 4; tags = ["lower"; "typed"; "async"]; since = "1.5.2"; weight = 3261 };
  { key = "minecart.food.global_0137";                   label = "modern_mob_137";              arity = 2; tags = ["compat"; "legacy"]; since = "1.9.0"; weight = 1281 };
  { key = "potion.food.scoped_0138";                     label = "modern_stonecutter_138";      arity = 5; tags = ["registry"; "typed"; "cached"]; since = "1.0.0"; weight = 770 };
  { key = "villager.food.provisional_0139";              label = "secondary_portal_139";        arity = 2; tags = ["async"]; since = "1.4.0"; weight = 1818 };
  { key = "banner_pattern.food.eager_0140";              label = "local_team_140";              arity = 0; tags = ["codegen"]; since = "1.0.0"; weight = 2314 };
  { key = "recipe.food.fallback_0141";                   label = "scoped_biome_141";            arity = 1; tags = ["hot"]; since = "1.7.0"; weight = 3257 };
  { key = "entity.food.internal_0142";                   label = "local_clock_142";             arity = 7; tags = ["async"; "sync"]; since = "1.3.1"; weight = 1722 };
  { key = "sound.food.lazy_0143";                        label = "public_piston_143";           arity = 3; tags = ["registry"; "check"]; since = "1.5.2"; weight = 1275 };
  { key = "block.food.secondary_0144";                   label = "lazy_gui_144";                arity = 4; tags = ["check"; "parse"; "codegen"]; since = "1.0.0"; weight = 3195 };
  { key = "elytra.food.stable_0145";                     label = "local_elytra_145";            arity = 2; tags = ["experimental"; "check"]; since = "1.8.3"; weight = 742 };
  { key = "cartography.food.eager_0146";                 label = "internal_spawner_146";        arity = 7; tags = ["lower"; "hot"]; since = "1.4.0"; weight = 4023 };
  { key = "portal.food.loose_0147";                      label = "local_minecart_147";          arity = 1; tags = ["lower"; "cached"]; since = "1.2.0"; weight = 2608 };
  { key = "minecart.food.lazy_0148";                     label = "fallback_observer_148";       arity = 3; tags = ["cold"; "cached"; "legacy"]; since = "1.7.0"; weight = 1639 };
  { key = "composter.food.stable_0149";                  label = "local_clock_149";             arity = 4; tags = ["legacy"; "content"; "emit"]; since = "1.9.0"; weight = 2571 };
  { key = "rail.food.global_0150";                       label = "modern_comparator_150";       arity = 5; tags = ["cached"; "typed"]; since = "1.9.0"; weight = 868 };
  { key = "entity.food.public_0151";                     label = "legacy_barrel_151";           arity = 7; tags = ["sync"; "lower"; "async"]; since = "1.7.0"; weight = 934 };
  { key = "bundle.food.provisional_0152";                label = "scoped_inventory_152";        arity = 1; tags = ["check"; "compat"; "untyped"]; since = "1.5.2"; weight = 1633 };
  { key = "attribute.food.stable_0153";                  label = "canonical_brewing_153";       arity = 3; tags = ["lower"; "legacy"]; since = "1.8.3"; weight = 3060 };
  { key = "effect.food.scoped_0154";                     label = "eager_dispenser_154";         arity = 3; tags = ["content"]; since = "1.8.3"; weight = 1599 };
  { key = "hologram.food.eager_0155";                    label = "public_advancement_155";      arity = 1; tags = ["sync"]; since = "1.4.0"; weight = 4083 };
  { key = "block.food.stable_0156";                      label = "local_scoreboard_156";        arity = 2; tags = ["registry"; "hot"; "legacy"]; since = "1.8.3"; weight = 3475 };
  { key = "spawner.food.fallback_0157";                  label = "primary_piston_157";          arity = 5; tags = ["packet"; "parse"]; since = "1.2.0"; weight = 1705 };
  { key = "effect.food.strict_0158";                     label = "derived_dispenser_158";       arity = 4; tags = ["check"; "compat"; "hot"]; since = "1.2.0"; weight = 220 };
  { key = "trident.food.legacy_0159";                    label = "global_trident_159";          arity = 1; tags = ["codegen"; "lower"; "registry"]; since = "1.3.1"; weight = 2713 };
  { key = "grindstone.food.global_0160";                 label = "public_rail_160";             arity = 3; tags = ["async"]; since = "1.7.0"; weight = 2123 };
  { key = "minecart.food.eager_0161";                    label = "cached_composter_161";        arity = 3; tags = ["typed"; "codegen"]; since = "1.0.0"; weight = 276 };
  { key = "shulker.food.scoped_0162";                    label = "primary_bundle_162";          arity = 4; tags = ["async"]; since = "1.0.0"; weight = 925 };
  { key = "entity.food.hidden_0163";                     label = "secondary_portal_163";        arity = 7; tags = ["core"; "legacy"; "hot"]; since = "1.8.3"; weight = 976 };
  { key = "item.food.modern_0164";                       label = "lazy_loom_164";               arity = 6; tags = ["cold"]; since = "1.6.0"; weight = 905 };
  { key = "particle.food.fallback_0165";                 label = "modern_player_165";           arity = 0; tags = ["experimental"]; since = "1.5.2"; weight = 1532 };
  { key = "boat.food.legacy_0166";                       label = "stable_observer_166";         arity = 4; tags = ["legacy"; "check"]; since = "1.8.3"; weight = 1441 };
  { key = "attribute.food.local_0167";                   label = "eager_chunk_167";             arity = 1; tags = ["core"; "emit"]; since = "1.0.0"; weight = 3770 };
  { key = "compass.food.primary_0168";                   label = "fallback_bundle_168";         arity = 1; tags = ["packet"]; since = "1.3.1"; weight = 1740 };
  { key = "composter.food.cached_0169";                  label = "public_attribute_169";        arity = 6; tags = ["cached"; "core"; "runtime"]; since = "1.4.0"; weight = 90 };
  { key = "firework.food.fallback_0170";                 label = "secondary_rail_170";          arity = 3; tags = ["cold"; "lower"; "compat"]; since = "1.7.0"; weight = 1106 };
  { key = "smithing.food.derived_0171";                  label = "canonical_scoreboard_171";    arity = 3; tags = ["legacy"; "lower"]; since = "1.5.2"; weight = 241 };
  { key = "region.food.derived_0172";                    label = "stable_scoreboard_172";       arity = 0; tags = ["lower"]; since = "1.7.0"; weight = 3757 };
  { key = "boat.food.fallback_0173";                     label = "derived_npc_173";             arity = 1; tags = ["untyped"; "registry"]; since = "1.9.0"; weight = 1953 };
  { key = "world.food.modern_0174";                      label = "global_grindstone_174";       arity = 5; tags = ["runtime"; "async"]; since = "1.7.0"; weight = 677 };
  { key = "sound.food.secondary_0175";                   label = "canonical_tablist_175";       arity = 5; tags = ["async"]; since = "1.2.0"; weight = 2151 };
  { key = "banner.food.hidden_0176";                     label = "global_structure_176";        arity = 1; tags = ["untyped"; "hot"]; since = "1.0.0"; weight = 2168 };
  { key = "region.food.public_0177";                     label = "global_block_177";            arity = 7; tags = ["cold"; "lower"]; since = "1.5.2"; weight = 1183 };
  { key = "mob.food.hidden_0178";                        label = "lazy_smithing_178";           arity = 3; tags = ["content"; "hot"; "emit"]; since = "1.0.0"; weight = 543 };
  { key = "tablist.food.provisional_0179";               label = "derived_pane_179";            arity = 6; tags = ["codegen"; "cached"]; since = "1.2.0"; weight = 2703 };
  { key = "dispenser.food.loose_0180";                   label = "canonical_advancement_180";   arity = 3; tags = ["check"]; since = "1.4.0"; weight = 127 };
  { key = "hologram.food.public_0181";                   label = "provisional_repeater_181";    arity = 3; tags = ["compat"; "hot"]; since = "1.2.0"; weight = 1071 };
  { key = "scoreboard.food.public_0182";                 label = "hidden_bossbar_182";          arity = 6; tags = ["hot"]; since = "1.4.0"; weight = 3664 };
  { key = "campfire.food.cached_0183";                   label = "fallback_hologram_183";       arity = 3; tags = ["lower"]; since = "1.0.0"; weight = 3161 };
  { key = "attribute.food.primary_0184";                 label = "scoped_portal_184";           arity = 1; tags = ["core"; "packet"]; since = "1.2.0"; weight = 2055 };
  { key = "item.food.local_0185";                        label = "modern_structure_185";        arity = 5; tags = ["runtime"; "parse"]; since = "1.3.1"; weight = 968 };
  { key = "enchant.food.cached_0186";                    label = "modern_conduit_186";          arity = 5; tags = ["legacy"; "untyped"; "lower"]; since = "1.5.2"; weight = 743 };
  { key = "scoreboard.food.primary_0187";                label = "legacy_gui_187";              arity = 5; tags = ["packet"; "content"; "cold"]; since = "1.6.0"; weight = 203 };
  { key = "anvil.food.strict_0188";                      label = "global_advancement_188";      arity = 4; tags = ["parse"; "compat"]; since = "1.0.0"; weight = 838 };
  { key = "sound.food.legacy_0189";                      label = "lazy_banner_189";             arity = 1; tags = ["lower"]; since = "1.4.0"; weight = 2819 };
  { key = "shield.food.cached_0190";                     label = "public_entity_190";           arity = 6; tags = ["emit"]; since = "1.4.0"; weight = 725 };
  { key = "entity.food.strict_0191";                     label = "local_enchant_191";           arity = 6; tags = ["compat"]; since = "1.2.0"; weight = 3422 };
  { key = "hopper.food.global_0192";                     label = "lazy_clock_192";              arity = 5; tags = ["packet"]; since = "1.6.0"; weight = 1849 };
  { key = "firework.food.secondary_0193";                label = "provisional_objective_193";   arity = 0; tags = ["cached"]; since = "1.2.0"; weight = 1981 };
  { key = "banner_pattern.food.primary_0194";            label = "derived_biome_194";           arity = 1; tags = ["registry"; "lower"]; since = "1.5.2"; weight = 633 };
  { key = "effect.food.cached_0195";                     label = "hidden_item_195";             arity = 1; tags = ["registry"; "cold"; "content"]; since = "1.8.3"; weight = 1693 };
  { key = "portal.food.eager_0196";                      label = "loose_effect_196";            arity = 3; tags = ["experimental"; "cached"]; since = "1.0.0"; weight = 110 };
  { key = "region.food.modern_0197";                     label = "hidden_shield_197";           arity = 6; tags = ["check"; "codegen"]; since = "1.3.1"; weight = 2938 };
  { key = "item.food.stable_0198";                       label = "fallback_repeater_198";       arity = 6; tags = ["cached"]; since = "1.9.0"; weight = 1978 };
  { key = "sound.food.modern_0199";                      label = "eager_conduit_199";           arity = 0; tags = ["packet"; "parse"]; since = "1.7.0"; weight = 2111 };
  { key = "crossbow.food.fallback_0200";                 label = "global_bundle_200";           arity = 2; tags = ["content"]; since = "1.4.0"; weight = 723 };
  { key = "dropper.food.modern_0201";                    label = "global_biome_201";            arity = 1; tags = ["lower"]; since = "1.6.0"; weight = 3848 };
  { key = "attribute.food.derived_0202";                 label = "public_composter_202";        arity = 3; tags = ["content"]; since = "1.6.0"; weight = 2278 };
  { key = "comparator.food.cached_0203";                 label = "strict_bossbar_203";          arity = 4; tags = ["untyped"]; since = "1.5.2"; weight = 373 };
  { key = "arrow.food.modern_0204";                      label = "legacy_furnace_204";          arity = 0; tags = ["parse"; "compat"; "legacy"]; since = "1.8.3"; weight = 402 };
  { key = "grindstone.food.scoped_0205";                 label = "primary_elytra_205";          arity = 0; tags = ["check"; "experimental"; "lower"]; since = "1.0.0"; weight = 1616 };
  { key = "potion.food.public_0206";                     label = "internal_attribute_206";      arity = 1; tags = ["legacy"; "sync"]; since = "1.6.0"; weight = 3993 };
  { key = "loom.food.loose_0207";                        label = "internal_minecart_207";       arity = 3; tags = ["cold"; "lower"; "runtime"]; since = "1.0.0"; weight = 2931 };
  { key = "advancement.food.lazy_0208";                  label = "global_attribute_208";        arity = 2; tags = ["compat"; "lower"; "registry"]; since = "1.6.0"; weight = 1943 };
  { key = "dropper.food.lazy_0209";                      label = "primary_objective_209";       arity = 5; tags = ["compat"; "registry"]; since = "1.3.1"; weight = 2479 };
  { key = "composter.food.local_0210";                   label = "secondary_compass_210";       arity = 4; tags = ["compat"; "legacy"]; since = "1.4.0"; weight = 334 };
  { key = "lectern.food.legacy_0211";                    label = "lazy_compass_211";            arity = 7; tags = ["typed"]; since = "1.7.0"; weight = 90 };
  { key = "smoker.food.derived_0212";                    label = "derived_trade_212";           arity = 4; tags = ["async"]; since = "1.9.0"; weight = 1428 };
  { key = "brewing.food.primary_0213";                   label = "strict_banner_213";           arity = 4; tags = ["parse"; "packet"]; since = "1.8.3"; weight = 1914 };
  { key = "stonecutter.food.eager_0214";                 label = "lazy_pane_214";               arity = 4; tags = ["hot"; "packet"; "core"]; since = "1.6.0"; weight = 1946 };
  { key = "tablist.food.local_0215";                     label = "global_minecart_215";         arity = 1; tags = ["hot"]; since = "1.7.0"; weight = 3742 };
  { key = "attribute.food.derived_0216";                 label = "hidden_boat_216";             arity = 4; tags = ["cold"; "parse"; "lower"]; since = "1.6.0"; weight = 1127 };
  { key = "arrow.food.lazy_0217";                        label = "primary_elytra_217";          arity = 2; tags = ["codegen"; "packet"]; since = "1.5.2"; weight = 558 };
  { key = "mob.food.canonical_0218";                     label = "internal_repeater_218";       arity = 2; tags = ["packet"; "sync"]; since = "1.6.0"; weight = 1509 };
  { key = "region.food.eager_0219";                      label = "scoped_villager_219";         arity = 4; tags = ["check"]; since = "1.4.0"; weight = 2909 };
  { key = "boat.food.eager_0220";                        label = "strict_target_220";           arity = 6; tags = ["untyped"]; since = "1.9.0"; weight = 590 };
  { key = "item.food.scoped_0221";                       label = "fallback_grindstone_221";     arity = 3; tags = ["cold"]; since = "1.6.0"; weight = 1359 };
  { key = "furnace.food.cached_0222";                    label = "eager_enchant_222";           arity = 0; tags = ["check"; "registry"]; since = "1.9.0"; weight = 1784 };
  { key = "pane.food.secondary_0223";                    label = "modern_comparator_223";       arity = 6; tags = ["emit"; "runtime"]; since = "1.8.3"; weight = 2795 };
  { key = "bell.food.secondary_0224";                    label = "loose_arrow_224";             arity = 7; tags = ["cached"]; since = "1.4.0"; weight = 822 };
  { key = "cartography.food.legacy_0225";                label = "derived_mob_225";             arity = 1; tags = ["hot"; "core"]; since = "1.5.2"; weight = 3555 };
  { key = "smithing.food.lazy_0226";                     label = "strict_comparator_226";       arity = 2; tags = ["parse"; "compat"; "content"]; since = "1.9.0"; weight = 1456 };
  { key = "dispenser.food.stable_0227";                  label = "hidden_biome_227";            arity = 3; tags = ["untyped"; "packet"]; since = "1.4.0"; weight = 170 };
  { key = "mob.food.canonical_0228";                     label = "derived_spawner_228";         arity = 7; tags = ["async"]; since = "1.9.0"; weight = 571 };
  { key = "beacon.food.global_0229";                     label = "internal_furnace_229";        arity = 4; tags = ["runtime"; "legacy"]; since = "1.4.0"; weight = 560 };
  { key = "objective.food.derived_0230";                 label = "primary_spawner_230";         arity = 3; tags = ["experimental"; "async"]; since = "1.3.1"; weight = 2343 };
  { key = "stonecutter.food.stable_0231";                label = "lazy_objective_231";          arity = 1; tags = ["cold"]; since = "1.7.0"; weight = 676 };
  { key = "barrel.food.legacy_0232";                     label = "strict_shield_232";           arity = 0; tags = ["codegen"; "packet"; "core"]; since = "1.4.0"; weight = 1780 };
  { key = "minecart.food.stable_0233";                   label = "local_observer_233";          arity = 4; tags = ["registry"; "hot"; "codegen"]; since = "1.5.2"; weight = 4054 };
  { key = "advancement.food.primary_0234";               label = "internal_anvil_234";          arity = 5; tags = ["runtime"]; since = "1.8.3"; weight = 3390 };
  { key = "shield.food.global_0235";                     label = "cached_player_235";           arity = 4; tags = ["content"; "emit"; "async"]; since = "1.0.0"; weight = 823 };
  { key = "smoker.food.legacy_0236";                     label = "eager_block_236";             arity = 2; tags = ["cached"; "experimental"]; since = "1.5.2"; weight = 2840 };
  { key = "firework.food.global_0237";                   label = "local_inventory_237";         arity = 6; tags = ["untyped"; "typed"]; since = "1.5.2"; weight = 1530 };
  { key = "bossbar.food.hidden_0238";                    label = "fallback_smoker_238";         arity = 0; tags = ["legacy"; "untyped"; "content"]; since = "1.6.0"; weight = 1736 };
  { key = "map.food.strict_0239";                        label = "strict_portal_239";           arity = 1; tags = ["codegen"]; since = "1.6.0"; weight = 1712 };
  { key = "structure.food.lazy_0240";                    label = "scoped_biome_240";            arity = 3; tags = ["registry"]; since = "1.8.3"; weight = 818 };
  { key = "arrow.food.legacy_0241";                      label = "fallback_shield_241";         arity = 4; tags = ["packet"; "content"; "sync"]; since = "1.5.2"; weight = 1848 };
  { key = "barrel.food.canonical_0242";                  label = "public_world_242";            arity = 2; tags = ["check"; "cached"; "legacy"]; since = "1.5.2"; weight = 1063 };
  { key = "particle.food.fallback_0243";                 label = "fallback_anvil_243";          arity = 1; tags = ["parse"; "emit"]; since = "1.8.3"; weight = 52 };
  { key = "villager.food.modern_0244";                   label = "modern_advancement_244";      arity = 3; tags = ["registry"; "emit"]; since = "1.2.0"; weight = 3093 };
  { key = "target.food.legacy_0245";                     label = "derived_dispenser_245";       arity = 4; tags = ["core"; "compat"]; since = "1.9.0"; weight = 3900 };
  { key = "anvil.food.legacy_0246";                      label = "derived_structure_246";       arity = 2; tags = ["runtime"]; since = "1.9.0"; weight = 11 };
  { key = "comparator.food.primary_0247";                label = "stable_hologram_247";         arity = 5; tags = ["hot"]; since = "1.4.0"; weight = 3517 };
  { key = "beacon.food.lazy_0248";                       label = "internal_slot_248";           arity = 4; tags = ["registry"; "content"]; since = "1.0.0"; weight = 1227 };
  { key = "advancement.food.lazy_0249";                  label = "internal_attribute_249";      arity = 6; tags = ["runtime"; "async"; "content"]; since = "1.0.0"; weight = 1852 };
  { key = "rail.food.canonical_0250";                    label = "modern_stonecutter_250";      arity = 3; tags = ["async"; "cached"]; since = "1.4.0"; weight = 1974 };
  { key = "banner_pattern.food.secondary_0251";          label = "hidden_advancement_251";      arity = 4; tags = ["experimental"; "async"; "untyped"]; since = "1.4.0"; weight = 698 };
  { key = "recipe.food.lazy_0252";                       label = "loose_composter_252";         arity = 7; tags = ["experimental"; "core"]; since = "1.0.0"; weight = 3035 };
  { key = "sound.food.scoped_0253";                      label = "internal_boat_253";           arity = 1; tags = ["legacy"; "typed"]; since = "1.4.0"; weight = 3994 };
  { key = "lectern.food.stable_0254";                    label = "canonical_compass_254";       arity = 3; tags = ["typed"]; since = "1.4.0"; weight = 2431 };
  { key = "map.food.loose_0255";                         label = "eager_pane_255";              arity = 3; tags = ["packet"; "emit"]; since = "1.4.0"; weight = 2130 };
  { key = "dropper.food.stable_0256";                    label = "fallback_shield_256";         arity = 1; tags = ["compat"; "typed"; "packet"]; since = "1.4.0"; weight = 3161 };
  { key = "conduit.food.loose_0257";                     label = "modern_bundle_257";           arity = 7; tags = ["check"; "cold"]; since = "1.6.0"; weight = 3183 };
  { key = "gui.food.lazy_0258";                          label = "legacy_crossbow_258";         arity = 0; tags = ["experimental"]; since = "1.5.2"; weight = 1774 };
  { key = "spawner.food.internal_0259";                  label = "secondary_particle_259";      arity = 0; tags = ["codegen"; "registry"]; since = "1.2.0"; weight = 1740 };
  { key = "trade.food.legacy_0260";                      label = "hidden_stonecutter_260";      arity = 4; tags = ["check"]; since = "1.4.0"; weight = 2315 };
  { key = "campfire.food.cached_0261";                   label = "fallback_packet_261";         arity = 2; tags = ["cold"; "parse"; "experimental"]; since = "1.4.0"; weight = 1952 };
  { key = "biome.food.primary_0262";                     label = "loose_team_262";              arity = 0; tags = ["registry"]; since = "1.5.2"; weight = 1751 };
  { key = "conduit.food.hidden_0263";                    label = "cached_gui_263";              arity = 6; tags = ["registry"; "parse"]; since = "1.5.2"; weight = 3607 };
  { key = "dropper.food.legacy_0264";                    label = "derived_cartography_264";     arity = 4; tags = ["parse"; "compat"]; since = "1.2.0"; weight = 3169 };
  { key = "barrel.food.derived_0265";                    label = "local_potion_265";            arity = 4; tags = ["hot"; "codegen"]; since = "1.8.3"; weight = 3724 };
  { key = "minecart.food.provisional_0266";              label = "scoped_npc_266";              arity = 5; tags = ["registry"; "cached"]; since = "1.5.2"; weight = 2277 };
  { key = "banner_pattern.food.strict_0267";             label = "scoped_arrow_267";            arity = 7; tags = ["experimental"; "packet"]; since = "1.0.0"; weight = 2248 };
  { key = "entity.food.legacy_0268";                     label = "provisional_bossbar_268";     arity = 3; tags = ["sync"; "emit"; "core"]; since = "1.9.0"; weight = 346 };
  { key = "hopper.food.loose_0269";                      label = "provisional_packet_269";      arity = 7; tags = ["packet"]; since = "1.0.0"; weight = 1384 };
  { key = "villager.food.public_0270";                   label = "stable_conduit_270";          arity = 0; tags = ["sync"]; since = "1.7.0"; weight = 950 };
  { key = "crossbow.food.global_0271";                   label = "internal_stonecutter_271";    arity = 7; tags = ["emit"; "async"]; since = "1.6.0"; weight = 1465 };
  { key = "minecart.food.provisional_0272";              label = "provisional_comparator_272";  arity = 1; tags = ["untyped"]; since = "1.2.0"; weight = 2919 };
  { key = "hologram.food.fallback_0273";                 label = "fallback_boat_273";           arity = 6; tags = ["runtime"; "codegen"; "registry"]; since = "1.2.0"; weight = 591 };
  { key = "region.food.lazy_0274";                       label = "scoped_bundle_274";           arity = 5; tags = ["async"; "compat"]; since = "1.8.3"; weight = 2643 };
  { key = "entity.food.canonical_0275";                  label = "lazy_structure_275";          arity = 1; tags = ["parse"; "sync"]; since = "1.6.0"; weight = 1739 };
  { key = "smithing.food.hidden_0276";                   label = "legacy_barrel_276";           arity = 6; tags = ["emit"; "check"]; since = "1.7.0"; weight = 3364 };
  { key = "furnace.food.eager_0277";                     label = "eager_beacon_277";            arity = 7; tags = ["cached"]; since = "1.3.1"; weight = 1788 };
  { key = "advancement.food.primary_0278";               label = "lazy_smoker_278";             arity = 7; tags = ["lower"; "experimental"]; since = "1.0.0"; weight = 1363 };
]

let count = List.length entries

let table : (string, food_entry) Hashtbl.t =
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
