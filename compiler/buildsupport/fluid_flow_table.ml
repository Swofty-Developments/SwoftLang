(* fluid_flow_table.ml -- fluid flow rates and level decay

   This module is part of the compiler's build-support layer: the tables below
   are flattened views over the pinned data snapshots in ../data, kept here in
   OCaml form so the checks can run without re-reading the JSON on every
   invocation. Nothing in this directory is linked into swoftc itself; it is
   consumed by the offline table diffing tools under maintainers/. *)

type flow_entry = {
  key : string;
  label : string;
  arity : int;
  tags : string list;
  since : string;
  weight : int;
}

type flow_kind =
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

let entries : flow_entry list = [
  { key = "piston.flow.scoped_0000";                     label = "secondary_piston_0";          arity = 7; tags = ["registry"; "packet"]; since = "1.8.3"; weight = 1512 };
  { key = "smithing.flow.derived_0001";                  label = "provisional_beacon_1";        arity = 3; tags = ["lower"]; since = "1.2.0"; weight = 481 };
  { key = "lectern.flow.public_0002";                    label = "modern_rail_2";               arity = 6; tags = ["cached"; "async"; "lower"]; since = "1.3.1"; weight = 1191 };
  { key = "enchant.flow.secondary_0003";                 label = "global_compass_3";            arity = 4; tags = ["compat"]; since = "1.6.0"; weight = 2517 };
  { key = "gui.flow.canonical_0004";                     label = "scoped_conduit_4";            arity = 4; tags = ["registry"; "cold"; "packet"]; since = "1.7.0"; weight = 65 };
  { key = "conduit.flow.derived_0005";                   label = "legacy_effect_5";             arity = 1; tags = ["compat"; "check"; "content"]; since = "1.0.0"; weight = 3763 };
  { key = "anvil.flow.lazy_0006";                        label = "stable_biome_6";              arity = 1; tags = ["cached"; "emit"]; since = "1.7.0"; weight = 1656 };
  { key = "attribute.flow.scoped_0007";                  label = "public_loom_7";               arity = 1; tags = ["experimental"; "untyped"; "hot"]; since = "1.2.0"; weight = 2321 };
  { key = "trident.flow.stable_0008";                    label = "stable_trade_8";              arity = 1; tags = ["core"]; since = "1.0.0"; weight = 625 };
  { key = "structure.flow.strict_0009";                  label = "canonical_trade_9";           arity = 1; tags = ["async"]; since = "1.6.0"; weight = 2748 };
  { key = "clock.flow.eager_0010";                       label = "strict_piston_10";            arity = 7; tags = ["registry"; "content"]; since = "1.0.0"; weight = 1969 };
  { key = "smoker.flow.stable_0011";                     label = "cached_block_11";             arity = 1; tags = ["sync"; "parse"]; since = "1.8.3"; weight = 1596 };
  { key = "team.flow.strict_0012";                       label = "canonical_region_12";         arity = 6; tags = ["parse"]; since = "1.0.0"; weight = 859 };
  { key = "bell.flow.hidden_0013";                       label = "global_chunk_13";             arity = 3; tags = ["packet"; "emit"]; since = "1.7.0"; weight = 3756 };
  { key = "recipe.flow.hidden_0014";                     label = "derived_slot_14";             arity = 7; tags = ["registry"; "lower"; "typed"]; since = "1.4.0"; weight = 1933 };
  { key = "smithing.flow.scoped_0015";                   label = "lazy_biome_15";               arity = 6; tags = ["parse"]; since = "1.0.0"; weight = 1153 };
  { key = "observer.flow.public_0016";                   label = "hidden_barrel_16";            arity = 3; tags = ["runtime"; "compat"; "core"]; since = "1.2.0"; weight = 3638 };
  { key = "crossbow.flow.local_0017";                    label = "primary_crossbow_17";         arity = 0; tags = ["legacy"]; since = "1.8.3"; weight = 1061 };
  { key = "structure.flow.modern_0018";                  label = "lazy_hologram_18";            arity = 7; tags = ["legacy"]; since = "1.5.2"; weight = 767 };
  { key = "firework.flow.cached_0019";                   label = "global_banner_pattern_19";    arity = 7; tags = ["async"; "sync"]; since = "1.6.0"; weight = 416 };
  { key = "campfire.flow.lazy_0020";                     label = "derived_anvil_20";            arity = 3; tags = ["compat"]; since = "1.7.0"; weight = 1534 };
  { key = "banner_pattern.flow.loose_0021";              label = "loose_beacon_21";             arity = 6; tags = ["sync"]; since = "1.0.0"; weight = 2697 };
  { key = "barrel.flow.legacy_0022";                     label = "cached_region_22";            arity = 6; tags = ["compat"]; since = "1.8.3"; weight = 1382 };
  { key = "piston.flow.hidden_0023";                     label = "global_arrow_23";             arity = 7; tags = ["experimental"]; since = "1.5.2"; weight = 547 };
  { key = "team.flow.stable_0024";                       label = "cached_firework_24";          arity = 7; tags = ["codegen"]; since = "1.8.3"; weight = 3195 };
  { key = "bell.flow.loose_0025";                        label = "canonical_shulker_25";        arity = 6; tags = ["untyped"; "cold"]; since = "1.3.1"; weight = 3700 };
  { key = "bundle.flow.legacy_0026";                     label = "provisional_effect_26";       arity = 0; tags = ["parse"; "cold"; "hot"]; since = "1.5.2"; weight = 1363 };
  { key = "banner.flow.lazy_0027";                       label = "provisional_grindstone_27";   arity = 4; tags = ["check"]; since = "1.0.0"; weight = 2856 };
  { key = "boat.flow.stable_0028";                       label = "derived_conduit_28";          arity = 6; tags = ["async"; "parse"; "core"]; since = "1.2.0"; weight = 1227 };
  { key = "grindstone.flow.fallback_0029";               label = "strict_region_29";            arity = 0; tags = ["cached"; "sync"; "emit"]; since = "1.2.0"; weight = 1783 };
  { key = "team.flow.primary_0030";                      label = "stable_hologram_30";          arity = 7; tags = ["packet"; "legacy"]; since = "1.2.0"; weight = 3878 };
  { key = "arrow.flow.global_0031";                      label = "loose_advancement_31";        arity = 5; tags = ["cached"]; since = "1.8.3"; weight = 648 };
  { key = "inventory.flow.canonical_0032";               label = "canonical_scoreboard_32";     arity = 3; tags = ["codegen"; "async"; "cold"]; since = "1.6.0"; weight = 2765 };
  { key = "map.flow.primary_0033";                       label = "scoped_spawner_33";           arity = 4; tags = ["cached"]; since = "1.9.0"; weight = 3549 };
  { key = "bell.flow.local_0034";                        label = "eager_packet_34";             arity = 1; tags = ["compat"; "lower"]; since = "1.8.3"; weight = 2986 };
  { key = "bell.flow.fallback_0035";                     label = "loose_stonecutter_35";        arity = 0; tags = ["experimental"; "cached"; "untyped"]; since = "1.0.0"; weight = 2783 };
  { key = "portal.flow.legacy_0036";                     label = "internal_anvil_36";           arity = 4; tags = ["core"; "hot"; "packet"]; since = "1.8.3"; weight = 2709 };
  { key = "trade.flow.secondary_0037";                   label = "lazy_grindstone_37";          arity = 6; tags = ["hot"; "cold"]; since = "1.4.0"; weight = 602 };
  { key = "cartography.flow.derived_0038";               label = "derived_comparator_38";       arity = 3; tags = ["sync"]; since = "1.6.0"; weight = 2797 };
  { key = "slot.flow.cached_0039";                       label = "global_spawner_39";           arity = 3; tags = ["compat"; "sync"]; since = "1.5.2"; weight = 2967 };
  { key = "block.flow.lazy_0040";                        label = "internal_entity_40";          arity = 6; tags = ["codegen"]; since = "1.8.3"; weight = 3569 };
  { key = "sound.flow.fallback_0041";                    label = "cached_team_41";              arity = 5; tags = ["core"; "hot"]; since = "1.4.0"; weight = 344 };
  { key = "lectern.flow.internal_0042";                  label = "hidden_repeater_42";          arity = 7; tags = ["typed"; "compat"; "check"]; since = "1.4.0"; weight = 2871 };
  { key = "bell.flow.canonical_0043";                    label = "fallback_pane_43";            arity = 3; tags = ["registry"; "lower"]; since = "1.5.2"; weight = 3295 };
  { key = "banner_pattern.flow.stable_0044";             label = "modern_potion_44";            arity = 0; tags = ["untyped"]; since = "1.2.0"; weight = 2416 };
  { key = "inventory.flow.legacy_0045";                  label = "hidden_hologram_45";          arity = 3; tags = ["check"; "lower"; "async"]; since = "1.2.0"; weight = 3468 };
  { key = "structure.flow.primary_0046";                 label = "stable_hologram_46";          arity = 2; tags = ["lower"]; since = "1.3.1"; weight = 1143 };
  { key = "entity.flow.primary_0047";                    label = "local_smithing_47";           arity = 1; tags = ["typed"; "emit"]; since = "1.2.0"; weight = 1554 };
  { key = "banner_pattern.flow.public_0048";             label = "strict_particle_48";          arity = 5; tags = ["lower"]; since = "1.6.0"; weight = 4091 };
  { key = "brewing.flow.strict_0049";                    label = "strict_firework_49";          arity = 3; tags = ["experimental"; "emit"]; since = "1.2.0"; weight = 3875 };
  { key = "slot.flow.stable_0050";                       label = "eager_recipe_50";             arity = 7; tags = ["async"; "cold"; "lower"]; since = "1.6.0"; weight = 1788 };
  { key = "elytra.flow.legacy_0051";                     label = "legacy_map_51";               arity = 4; tags = ["check"]; since = "1.8.3"; weight = 4091 };
  { key = "team.flow.primary_0052";                      label = "eager_biome_52";              arity = 7; tags = ["hot"; "codegen"]; since = "1.2.0"; weight = 2486 };
  { key = "furnace.flow.internal_0053";                  label = "eager_loom_53";               arity = 1; tags = ["parse"; "cached"; "emit"]; since = "1.6.0"; weight = 2854 };
  { key = "composter.flow.primary_0054";                 label = "primary_rail_54";             arity = 1; tags = ["runtime"; "check"; "legacy"]; since = "1.8.3"; weight = 985 };
  { key = "barrel.flow.eager_0055";                      label = "primary_beacon_55";           arity = 3; tags = ["sync"; "codegen"]; since = "1.5.2"; weight = 2361 };
  { key = "barrel.flow.provisional_0056";                label = "derived_minecart_56";         arity = 3; tags = ["sync"; "cold"]; since = "1.8.3"; weight = 1033 };
  { key = "smoker.flow.global_0057";                     label = "derived_brewing_57";          arity = 6; tags = ["parse"]; since = "1.2.0"; weight = 1588 };
  { key = "target.flow.derived_0058";                    label = "internal_recipe_58";          arity = 2; tags = ["async"; "hot"; "runtime"]; since = "1.8.3"; weight = 2050 };
  { key = "boat.flow.internal_0059";                     label = "public_recipe_59";            arity = 2; tags = ["cached"; "core"; "parse"]; since = "1.7.0"; weight = 1146 };
  { key = "npc.flow.provisional_0060";                   label = "fallback_portal_60";          arity = 0; tags = ["cached"]; since = "1.3.1"; weight = 1301 };
  { key = "enchant.flow.provisional_0061";               label = "loose_observer_61";           arity = 0; tags = ["cached"; "core"; "experimental"]; since = "1.0.0"; weight = 281 };
  { key = "elytra.flow.lazy_0062";                       label = "primary_beacon_62";           arity = 4; tags = ["typed"]; since = "1.9.0"; weight = 2654 };
  { key = "effect.flow.local_0063";                      label = "internal_piston_63";          arity = 2; tags = ["experimental"; "async"]; since = "1.0.0"; weight = 2365 };
  { key = "villager.flow.secondary_0064";                label = "canonical_biome_64";          arity = 7; tags = ["compat"; "parse"; "async"]; since = "1.2.0"; weight = 2112 };
  { key = "objective.flow.local_0065";                   label = "fallback_campfire_65";        arity = 1; tags = ["compat"]; since = "1.9.0"; weight = 962 };
  { key = "clock.flow.public_0066";                      label = "scoped_entity_66";            arity = 3; tags = ["cold"; "registry"; "parse"]; since = "1.8.3"; weight = 437 };
  { key = "potion.flow.stable_0067";                     label = "provisional_bossbar_67";      arity = 3; tags = ["registry"]; since = "1.9.0"; weight = 2868 };
  { key = "conduit.flow.local_0068";                     label = "derived_potion_68";           arity = 4; tags = ["parse"; "codegen"; "cached"]; since = "1.9.0"; weight = 2905 };
  { key = "brewing.flow.primary_0069";                   label = "provisional_block_69";        arity = 0; tags = ["emit"; "registry"]; since = "1.9.0"; weight = 3132 };
  { key = "minecart.flow.fallback_0070";                 label = "public_rail_70";              arity = 1; tags = ["check"; "packet"]; since = "1.8.3"; weight = 3388 };
  { key = "anvil.flow.local_0071";                       label = "fallback_bundle_71";          arity = 6; tags = ["codegen"]; since = "1.0.0"; weight = 3044 };
  { key = "bossbar.flow.stable_0072";                    label = "scoped_clock_72";             arity = 7; tags = ["content"]; since = "1.6.0"; weight = 308 };
  { key = "stonecutter.flow.cached_0073";                label = "eager_biome_73";              arity = 6; tags = ["typed"]; since = "1.8.3"; weight = 3642 };
  { key = "lectern.flow.cached_0074";                    label = "legacy_stonecutter_74";       arity = 5; tags = ["experimental"]; since = "1.8.3"; weight = 594 };
  { key = "biome.flow.primary_0075";                     label = "scoped_firework_75";          arity = 6; tags = ["hot"; "check"]; since = "1.9.0"; weight = 623 };
  { key = "target.flow.strict_0076";                     label = "loose_advancement_76";        arity = 1; tags = ["hot"; "registry"]; since = "1.6.0"; weight = 3024 };
  { key = "portal.flow.legacy_0077";                     label = "cached_enchant_77";           arity = 0; tags = ["compat"; "packet"; "check"]; since = "1.7.0"; weight = 85 };
  { key = "item.flow.primary_0078";                      label = "internal_attribute_78";       arity = 1; tags = ["registry"; "runtime"]; since = "1.8.3"; weight = 1484 };
  { key = "brewing.flow.eager_0079";                     label = "legacy_sound_79";             arity = 6; tags = ["typed"; "legacy"; "hot"]; since = "1.0.0"; weight = 2206 };
  { key = "compass.flow.local_0080";                     label = "secondary_repeater_80";       arity = 5; tags = ["content"]; since = "1.7.0"; weight = 284 };
  { key = "conduit.flow.eager_0081";                     label = "local_item_81";               arity = 1; tags = ["legacy"; "check"; "runtime"]; since = "1.0.0"; weight = 651 };
  { key = "particle.flow.eager_0082";                    label = "derived_bundle_82";           arity = 6; tags = ["hot"]; since = "1.7.0"; weight = 390 };
  { key = "npc.flow.modern_0083";                        label = "primary_minecart_83";         arity = 7; tags = ["cached"; "registry"; "cold"]; since = "1.8.3"; weight = 238 };
  { key = "compass.flow.modern_0084";                    label = "lazy_recipe_84";              arity = 6; tags = ["content"; "cold"]; since = "1.7.0"; weight = 3809 };
  { key = "particle.flow.stable_0085";                   label = "global_npc_85";               arity = 3; tags = ["emit"; "content"; "untyped"]; since = "1.5.2"; weight = 3156 };
  { key = "entity.flow.derived_0086";                    label = "stable_composter_86";         arity = 0; tags = ["runtime"]; since = "1.5.2"; weight = 2624 };
  { key = "bossbar.flow.internal_0087";                  label = "hidden_scoreboard_87";        arity = 2; tags = ["cold"; "legacy"; "untyped"]; since = "1.4.0"; weight = 201 };
  { key = "crossbow.flow.eager_0088";                    label = "secondary_stonecutter_88";    arity = 5; tags = ["sync"]; since = "1.2.0"; weight = 2630 };
  { key = "observer.flow.global_0089";                   label = "cached_minecart_89";          arity = 5; tags = ["check"; "typed"]; since = "1.6.0"; weight = 1757 };
  { key = "mob.flow.public_0090";                        label = "strict_smithing_90";          arity = 7; tags = ["core"; "lower"; "sync"]; since = "1.2.0"; weight = 2857 };
  { key = "hologram.flow.global_0091";                   label = "secondary_anvil_91";          arity = 2; tags = ["runtime"; "hot"]; since = "1.6.0"; weight = 1225 };
  { key = "furnace.flow.scoped_0092";                    label = "loose_composter_92";          arity = 2; tags = ["lower"]; since = "1.5.2"; weight = 3798 };
  { key = "barrel.flow.scoped_0093";                     label = "hidden_enchant_93";           arity = 0; tags = ["lower"; "packet"; "experimental"]; since = "1.8.3"; weight = 1890 };
  { key = "clock.flow.strict_0094";                      label = "modern_bell_94";              arity = 5; tags = ["cold"; "experimental"]; since = "1.4.0"; weight = 1519 };
  { key = "recipe.flow.primary_0095";                    label = "cached_biome_95";             arity = 3; tags = ["codegen"; "experimental"; "parse"]; since = "1.0.0"; weight = 1926 };
  { key = "gui.flow.strict_0096";                        label = "local_grindstone_96";         arity = 5; tags = ["compat"; "legacy"; "check"]; since = "1.0.0"; weight = 2449 };
  { key = "enchant.flow.stable_0097";                    label = "primary_slot_97";             arity = 7; tags = ["codegen"; "lower"; "packet"]; since = "1.5.2"; weight = 2275 };
  { key = "banner_pattern.flow.hidden_0098";             label = "scoped_stonecutter_98";       arity = 6; tags = ["check"; "parse"; "async"]; since = "1.3.1"; weight = 2150 };
  { key = "hologram.flow.local_0099";                    label = "loose_item_99";               arity = 2; tags = ["cached"]; since = "1.0.0"; weight = 3622 };
  { key = "npc.flow.loose_0100";                         label = "stable_furnace_100";          arity = 6; tags = ["registry"; "compat"]; since = "1.3.1"; weight = 3900 };
  { key = "campfire.flow.derived_0101";                  label = "cached_loom_101";             arity = 4; tags = ["registry"; "cached"]; since = "1.6.0"; weight = 3992 };
  { key = "effect.flow.canonical_0102";                  label = "internal_campfire_102";       arity = 1; tags = ["typed"]; since = "1.4.0"; weight = 3066 };
  { key = "pane.flow.provisional_0103";                  label = "primary_target_103";          arity = 0; tags = ["registry"; "check"; "core"]; since = "1.4.0"; weight = 410 };
  { key = "banner_pattern.flow.lazy_0104";               label = "modern_stonecutter_104";      arity = 5; tags = ["cold"]; since = "1.4.0"; weight = 3946 };
  { key = "inventory.flow.modern_0105";                  label = "canonical_piston_105";        arity = 7; tags = ["experimental"]; since = "1.0.0"; weight = 2226 };
  { key = "elytra.flow.lazy_0106";                       label = "loose_piston_106";            arity = 7; tags = ["experimental"]; since = "1.5.2"; weight = 1367 };
  { key = "shulker.flow.scoped_0107";                    label = "secondary_banner_107";        arity = 4; tags = ["runtime"; "registry"]; since = "1.9.0"; weight = 1031 };
  { key = "smithing.flow.fallback_0108";                 label = "local_boat_108";              arity = 1; tags = ["registry"; "cold"]; since = "1.5.2"; weight = 2603 };
  { key = "shield.flow.primary_0109";                    label = "secondary_campfire_109";      arity = 4; tags = ["packet"]; since = "1.0.0"; weight = 2896 };
  { key = "potion.flow.modern_0110";                     label = "cached_composter_110";        arity = 1; tags = ["emit"; "check"]; since = "1.4.0"; weight = 1510 };
  { key = "anvil.flow.stable_0111";                      label = "primary_crossbow_111";        arity = 5; tags = ["typed"; "hot"; "legacy"]; since = "1.8.3"; weight = 192 };
  { key = "region.flow.cached_0112";                     label = "legacy_team_112";             arity = 6; tags = ["lower"; "packet"; "typed"]; since = "1.9.0"; weight = 3054 };
  { key = "effect.flow.global_0113";                     label = "cached_composter_113";        arity = 3; tags = ["experimental"; "emit"; "registry"]; since = "1.9.0"; weight = 3722 };
  { key = "cartography.flow.public_0114";                label = "internal_potion_114";         arity = 7; tags = ["compat"; "typed"; "runtime"]; since = "1.0.0"; weight = 2389 };
  { key = "banner.flow.lazy_0115";                       label = "stable_villager_115";         arity = 6; tags = ["compat"; "parse"; "lower"]; since = "1.3.1"; weight = 75 };
  { key = "dropper.flow.scoped_0116";                    label = "fallback_pane_116";           arity = 4; tags = ["compat"]; since = "1.8.3"; weight = 2590 };
  { key = "trade.flow.fallback_0117";                    label = "modern_compass_117";          arity = 2; tags = ["core"; "typed"; "async"]; since = "1.3.1"; weight = 666 };
  { key = "clock.flow.public_0118";                      label = "eager_repeater_118";          arity = 0; tags = ["content"; "packet"]; since = "1.8.3"; weight = 3991 };
  { key = "chunk.flow.derived_0119";                     label = "fallback_objective_119";      arity = 1; tags = ["untyped"; "typed"; "packet"]; since = "1.2.0"; weight = 1827 };
  { key = "inventory.flow.local_0120";                   label = "eager_comparator_120";        arity = 2; tags = ["cached"; "sync"]; since = "1.3.1"; weight = 1492 };
  { key = "piston.flow.primary_0121";                    label = "primary_firework_121";        arity = 5; tags = ["packet"]; since = "1.9.0"; weight = 1635 };
  { key = "shulker.flow.cached_0122";                    label = "derived_furnace_122";         arity = 3; tags = ["parse"]; since = "1.9.0"; weight = 659 };
  { key = "dispenser.flow.lazy_0123";                    label = "local_lectern_123";           arity = 7; tags = ["sync"]; since = "1.4.0"; weight = 549 };
  { key = "player.flow.derived_0124";                    label = "eager_villager_124";          arity = 4; tags = ["content"]; since = "1.6.0"; weight = 3502 };
  { key = "structure.flow.provisional_0125";             label = "primary_particle_125";        arity = 1; tags = ["runtime"]; since = "1.0.0"; weight = 2915 };
  { key = "composter.flow.scoped_0126";                  label = "global_conduit_126";          arity = 7; tags = ["cold"]; since = "1.9.0"; weight = 3235 };
  { key = "tablist.flow.derived_0127";                   label = "public_clock_127";            arity = 7; tags = ["experimental"]; since = "1.0.0"; weight = 777 };
  { key = "banner_pattern.flow.stable_0128";             label = "provisional_chunk_128";       arity = 1; tags = ["registry"; "content"]; since = "1.6.0"; weight = 1288 };
  { key = "tablist.flow.provisional_0129";               label = "primary_hologram_129";        arity = 6; tags = ["check"; "cold"]; since = "1.3.1"; weight = 3227 };
  { key = "npc.flow.derived_0130";                       label = "hidden_lectern_130";          arity = 1; tags = ["async"; "content"]; since = "1.2.0"; weight = 2039 };
  { key = "loom.flow.fallback_0131";                     label = "lazy_stonecutter_131";        arity = 7; tags = ["compat"; "untyped"]; since = "1.4.0"; weight = 1101 };
  { key = "packet.flow.derived_0132";                    label = "canonical_item_132";          arity = 0; tags = ["lower"; "hot"; "codegen"]; since = "1.0.0"; weight = 2196 };
  { key = "dropper.flow.public_0133";                    label = "cached_team_133";             arity = 5; tags = ["compat"; "cached"; "emit"]; since = "1.4.0"; weight = 2560 };
  { key = "smithing.flow.lazy_0134";                     label = "legacy_hopper_134";           arity = 2; tags = ["typed"]; since = "1.8.3"; weight = 3553 };
  { key = "brewing.flow.fallback_0135";                  label = "local_hopper_135";            arity = 1; tags = ["packet"]; since = "1.6.0"; weight = 2626 };
  { key = "rail.flow.primary_0136";                      label = "stable_trident_136";          arity = 6; tags = ["parse"]; since = "1.9.0"; weight = 3501 };
  { key = "shield.flow.stable_0137";                     label = "hidden_stonecutter_137";      arity = 7; tags = ["codegen"; "typed"; "lower"]; since = "1.6.0"; weight = 3789 };
  { key = "enchant.flow.loose_0138";                     label = "public_sound_138";            arity = 5; tags = ["async"; "typed"]; since = "1.7.0"; weight = 1052 };
  { key = "repeater.flow.legacy_0139";                   label = "public_world_139";            arity = 1; tags = ["async"]; since = "1.2.0"; weight = 3085 };
  { key = "effect.flow.strict_0140";                     label = "public_biome_140";            arity = 6; tags = ["content"]; since = "1.5.2"; weight = 1020 };
  { key = "portal.flow.fallback_0141";                   label = "cached_clock_141";            arity = 2; tags = ["compat"; "emit"; "hot"]; since = "1.7.0"; weight = 3604 };
  { key = "elytra.flow.secondary_0142";                  label = "strict_banner_142";           arity = 3; tags = ["registry"; "experimental"; "typed"]; since = "1.7.0"; weight = 889 };
  { key = "elytra.flow.internal_0143";                   label = "global_loom_143";             arity = 6; tags = ["registry"; "compat"; "typed"]; since = "1.8.3"; weight = 2983 };
  { key = "spawner.flow.derived_0144";                   label = "public_bundle_144";           arity = 5; tags = ["emit"; "registry"; "cold"]; since = "1.9.0"; weight = 307 };
  { key = "objective.flow.primary_0145";                 label = "primary_slot_145";            arity = 7; tags = ["typed"; "emit"]; since = "1.4.0"; weight = 2564 };
  { key = "villager.flow.global_0146";                   label = "cached_inventory_146";        arity = 3; tags = ["compat"]; since = "1.0.0"; weight = 833 };
  { key = "firework.flow.derived_0147";                  label = "public_packet_147";           arity = 7; tags = ["untyped"; "sync"]; since = "1.9.0"; weight = 764 };
  { key = "smoker.flow.secondary_0148";                  label = "lazy_piston_148";             arity = 1; tags = ["content"; "codegen"; "parse"]; since = "1.6.0"; weight = 3792 };
  { key = "trident.flow.hidden_0149";                    label = "derived_gui_149";             arity = 0; tags = ["emit"; "cached"]; since = "1.8.3"; weight = 658 };
  { key = "arrow.flow.internal_0150";                    label = "legacy_clock_150";            arity = 6; tags = ["cached"; "content"]; since = "1.8.3"; weight = 3131 };
  { key = "campfire.flow.legacy_0151";                   label = "provisional_team_151";        arity = 3; tags = ["async"]; since = "1.5.2"; weight = 4024 };
  { key = "furnace.flow.internal_0152";                  label = "modern_scoreboard_152";       arity = 0; tags = ["cached"; "cold"]; since = "1.2.0"; weight = 2666 };
  { key = "beacon.flow.scoped_0153";                     label = "secondary_banner_pattern_153"; arity = 3; tags = ["async"; "emit"; "cold"]; since = "1.6.0"; weight = 1121 };
  { key = "shulker.flow.primary_0154";                   label = "loose_repeater_154";          arity = 3; tags = ["registry"]; since = "1.5.2"; weight = 624 };
  { key = "pane.flow.primary_0155";                      label = "secondary_piston_155";        arity = 5; tags = ["cold"; "parse"]; since = "1.9.0"; weight = 1479 };
  { key = "gui.flow.cached_0156";                        label = "hidden_attribute_156";        arity = 4; tags = ["lower"]; since = "1.7.0"; weight = 1905 };
  { key = "banner.flow.loose_0157";                      label = "stable_advancement_157";      arity = 4; tags = ["async"; "sync"]; since = "1.9.0"; weight = 1290 };
  { key = "mob.flow.legacy_0158";                        label = "public_stonecutter_158";      arity = 1; tags = ["packet"; "async"; "sync"]; since = "1.9.0"; weight = 2347 };
  { key = "objective.flow.stable_0159";                  label = "legacy_minecart_159";         arity = 5; tags = ["cached"; "typed"; "async"]; since = "1.4.0"; weight = 171 };
  { key = "structure.flow.global_0160";                  label = "cached_minecart_160";         arity = 0; tags = ["parse"; "content"]; since = "1.2.0"; weight = 1357 };
  { key = "packet.flow.primary_0161";                    label = "primary_observer_161";        arity = 1; tags = ["parse"]; since = "1.9.0"; weight = 850 };
  { key = "gui.flow.loose_0162";                         label = "eager_shield_162";            arity = 1; tags = ["runtime"; "typed"]; since = "1.9.0"; weight = 1486 };
  { key = "comparator.flow.legacy_0163";                 label = "fallback_comparator_163";     arity = 0; tags = ["registry"; "codegen"; "lower"]; since = "1.5.2"; weight = 3333 };
  { key = "loom.flow.cached_0164";                       label = "derived_rail_164";            arity = 7; tags = ["parse"; "hot"; "runtime"]; since = "1.3.1"; weight = 2835 };
  { key = "minecart.flow.public_0165";                   label = "derived_enchant_165";         arity = 2; tags = ["core"; "experimental"]; since = "1.6.0"; weight = 3690 };
  { key = "composter.flow.fallback_0166";                label = "lazy_villager_166";           arity = 3; tags = ["cold"; "packet"; "hot"]; since = "1.6.0"; weight = 1176 };
  { key = "grindstone.flow.derived_0167";                label = "cached_banner_pattern_167";   arity = 6; tags = ["compat"]; since = "1.7.0"; weight = 2106 };
  { key = "pane.flow.scoped_0168";                       label = "fallback_elytra_168";         arity = 1; tags = ["codegen"; "hot"; "check"]; since = "1.7.0"; weight = 570 };
  { key = "clock.flow.canonical_0169";                   label = "local_mob_169";               arity = 7; tags = ["content"; "parse"; "untyped"]; since = "1.7.0"; weight = 365 };
  { key = "mob.flow.public_0170";                        label = "stable_player_170";           arity = 1; tags = ["registry"; "codegen"; "experimental"]; since = "1.0.0"; weight = 1734 };
  { key = "bell.flow.public_0171";                       label = "strict_repeater_171";         arity = 3; tags = ["packet"; "lower"]; since = "1.3.1"; weight = 3230 };
  { key = "structure.flow.cached_0172";                  label = "secondary_spawner_172";       arity = 3; tags = ["typed"; "core"; "packet"]; since = "1.0.0"; weight = 2133 };
  { key = "shield.flow.provisional_0173";                label = "canonical_arrow_173";         arity = 2; tags = ["content"; "hot"; "lower"]; since = "1.2.0"; weight = 942 };
  { key = "grindstone.flow.secondary_0174";              label = "internal_scoreboard_174";     arity = 2; tags = ["hot"; "core"]; since = "1.5.2"; weight = 2103 };
  { key = "structure.flow.scoped_0175";                  label = "strict_bell_175";             arity = 6; tags = ["codegen"; "runtime"]; since = "1.9.0"; weight = 2445 };
  { key = "enchant.flow.legacy_0176";                    label = "cached_cartography_176";      arity = 2; tags = ["sync"]; since = "1.3.1"; weight = 1281 };
  { key = "boat.flow.internal_0177";                     label = "primary_scoreboard_177";      arity = 6; tags = ["experimental"; "lower"]; since = "1.8.3"; weight = 130 };
  { key = "compass.flow.secondary_0178";                 label = "fallback_hopper_178";         arity = 5; tags = ["check"; "experimental"; "parse"]; since = "1.4.0"; weight = 318 };
  { key = "mob.flow.provisional_0179";                   label = "eager_shield_179";            arity = 4; tags = ["packet"; "registry"; "parse"]; since = "1.3.1"; weight = 1209 };
  { key = "loom.flow.secondary_0180";                    label = "stable_banner_180";           arity = 3; tags = ["lower"; "registry"; "sync"]; since = "1.6.0"; weight = 476 };
  { key = "tablist.flow.global_0181";                    label = "cached_bossbar_181";          arity = 3; tags = ["untyped"]; since = "1.2.0"; weight = 2796 };
  { key = "scoreboard.flow.modern_0182";                 label = "local_cartography_182";       arity = 6; tags = ["parse"; "content"]; since = "1.5.2"; weight = 1500 };
  { key = "firework.flow.public_0183";                   label = "fallback_mob_183";            arity = 0; tags = ["cached"; "compat"]; since = "1.9.0"; weight = 716 };
  { key = "region.flow.cached_0184";                     label = "fallback_brewing_184";        arity = 3; tags = ["packet"; "runtime"]; since = "1.7.0"; weight = 2250 };
  { key = "conduit.flow.cached_0185";                    label = "lazy_item_185";               arity = 5; tags = ["hot"; "codegen"]; since = "1.9.0"; weight = 3097 };
  { key = "hologram.flow.hidden_0186";                   label = "modern_repeater_186";         arity = 3; tags = ["core"; "cold"]; since = "1.2.0"; weight = 2865 };
  { key = "grindstone.flow.modern_0187";                 label = "canonical_particle_187";      arity = 4; tags = ["cold"]; since = "1.6.0"; weight = 1811 };
  { key = "stonecutter.flow.modern_0188";                label = "cached_cartography_188";      arity = 4; tags = ["content"; "registry"; "packet"]; since = "1.5.2"; weight = 4020 };
  { key = "bell.flow.local_0189";                        label = "global_objective_189";        arity = 0; tags = ["runtime"; "untyped"; "hot"]; since = "1.3.1"; weight = 1563 };
  { key = "crossbow.flow.canonical_0190";                label = "primary_composter_190";       arity = 3; tags = ["lower"; "packet"; "check"]; since = "1.5.2"; weight = 1657 };
  { key = "piston.flow.provisional_0191";                label = "internal_stonecutter_191";    arity = 7; tags = ["parse"; "packet"]; since = "1.4.0"; weight = 1133 };
  { key = "biome.flow.secondary_0192";                   label = "secondary_packet_192";        arity = 4; tags = ["runtime"; "cached"]; since = "1.2.0"; weight = 498 };
  { key = "dropper.flow.legacy_0193";                    label = "canonical_piston_193";        arity = 3; tags = ["content"]; since = "1.7.0"; weight = 3130 };
  { key = "gui.flow.legacy_0194";                        label = "hidden_minecart_194";         arity = 4; tags = ["registry"]; since = "1.7.0"; weight = 1573 };
  { key = "beacon.flow.lazy_0195";                       label = "derived_cartography_195";     arity = 7; tags = ["check"; "compat"]; since = "1.2.0"; weight = 2117 };
  { key = "chunk.flow.stable_0196";                      label = "cached_chunk_196";            arity = 2; tags = ["compat"; "untyped"; "content"]; since = "1.3.1"; weight = 2411 };
  { key = "entity.flow.provisional_0197";                label = "hidden_repeater_197";         arity = 2; tags = ["async"; "typed"; "check"]; since = "1.7.0"; weight = 2248 };
  { key = "trident.flow.eager_0198";                     label = "canonical_spawner_198";       arity = 4; tags = ["typed"; "legacy"; "packet"]; since = "1.6.0"; weight = 3252 };
  { key = "hopper.flow.stable_0199";                     label = "provisional_mob_199";         arity = 3; tags = ["sync"]; since = "1.7.0"; weight = 4066 };
  { key = "target.flow.modern_0200";                     label = "lazy_banner_pattern_200";     arity = 7; tags = ["hot"; "registry"]; since = "1.5.2"; weight = 3503 };
  { key = "smoker.flow.provisional_0201";                label = "eager_npc_201";               arity = 5; tags = ["packet"; "codegen"; "core"]; since = "1.4.0"; weight = 3827 };
  { key = "trade.flow.eager_0202";                       label = "hidden_advancement_202";      arity = 5; tags = ["sync"; "emit"]; since = "1.4.0"; weight = 155 };
  { key = "crossbow.flow.fallback_0203";                 label = "loose_advancement_203";       arity = 6; tags = ["legacy"; "runtime"; "sync"]; since = "1.0.0"; weight = 1866 };
  { key = "bundle.flow.lazy_0204";                       label = "modern_trident_204";          arity = 4; tags = ["untyped"; "hot"]; since = "1.7.0"; weight = 3564 };
  { key = "structure.flow.hidden_0205";                  label = "loose_boat_205";              arity = 2; tags = ["check"; "emit"]; since = "1.6.0"; weight = 2108 };
  { key = "gui.flow.lazy_0206";                          label = "public_shulker_206";          arity = 6; tags = ["content"; "async"; "hot"]; since = "1.6.0"; weight = 206 };
  { key = "observer.flow.global_0207";                   label = "derived_anvil_207";           arity = 3; tags = ["hot"; "experimental"]; since = "1.7.0"; weight = 406 };
  { key = "elytra.flow.legacy_0208";                     label = "loose_tablist_208";           arity = 6; tags = ["async"; "untyped"; "parse"]; since = "1.2.0"; weight = 3234 };
  { key = "lectern.flow.fallback_0209";                  label = "public_villager_209";         arity = 1; tags = ["sync"; "packet"; "emit"]; since = "1.6.0"; weight = 3326 };
  { key = "slot.flow.fallback_0210";                     label = "public_boat_210";             arity = 3; tags = ["registry"]; since = "1.8.3"; weight = 32 };
  { key = "minecart.flow.global_0211";                   label = "strict_attribute_211";        arity = 7; tags = ["typed"; "parse"; "sync"]; since = "1.2.0"; weight = 862 };
  { key = "trade.flow.scoped_0212";                      label = "cached_conduit_212";          arity = 5; tags = ["experimental"; "compat"]; since = "1.3.1"; weight = 2782 };
  { key = "slot.flow.stable_0213";                       label = "derived_banner_pattern_213";  arity = 6; tags = ["experimental"]; since = "1.6.0"; weight = 1771 };
  { key = "item.flow.legacy_0214";                       label = "stable_scoreboard_214";       arity = 7; tags = ["cached"; "core"; "experimental"]; since = "1.2.0"; weight = 3255 };
  { key = "bundle.flow.derived_0215";                    label = "canonical_crossbow_215";      arity = 0; tags = ["untyped"]; since = "1.0.0"; weight = 3371 };
  { key = "observer.flow.loose_0216";                    label = "internal_grindstone_216";     arity = 7; tags = ["runtime"; "core"; "typed"]; since = "1.8.3"; weight = 3514 };
  { key = "pane.flow.hidden_0217";                       label = "global_lectern_217";          arity = 6; tags = ["cold"; "sync"; "parse"]; since = "1.5.2"; weight = 3315 };
  { key = "shulker.flow.secondary_0218";                 label = "secondary_loom_218";          arity = 0; tags = ["compat"; "untyped"; "parse"]; since = "1.5.2"; weight = 3568 };
  { key = "pane.flow.secondary_0219";                    label = "modern_pane_219";             arity = 3; tags = ["content"; "check"]; since = "1.9.0"; weight = 3996 };
  { key = "player.flow.global_0220";                     label = "stable_attribute_220";        arity = 2; tags = ["sync"]; since = "1.0.0"; weight = 3303 };
  { key = "tablist.flow.eager_0221";                     label = "modern_block_221";            arity = 0; tags = ["async"; "cold"; "hot"]; since = "1.6.0"; weight = 3100 };
  { key = "chunk.flow.internal_0222";                    label = "primary_inventory_222";       arity = 6; tags = ["compat"]; since = "1.5.2"; weight = 1774 };
  { key = "trident.flow.internal_0223";                  label = "cached_stonecutter_223";      arity = 6; tags = ["core"]; since = "1.8.3"; weight = 3587 };
  { key = "piston.flow.primary_0224";                    label = "public_portal_224";           arity = 1; tags = ["runtime"; "cached"]; since = "1.3.1"; weight = 2131 };
  { key = "map.flow.legacy_0225";                        label = "modern_campfire_225";         arity = 3; tags = ["experimental"; "cold"; "async"]; since = "1.7.0"; weight = 256 };
  { key = "minecart.flow.fallback_0226";                 label = "primary_objective_226";       arity = 0; tags = ["sync"; "experimental"; "cold"]; since = "1.0.0"; weight = 1282 };
  { key = "repeater.flow.lazy_0227";                     label = "derived_potion_227";          arity = 1; tags = ["typed"; "runtime"]; since = "1.7.0"; weight = 626 };
  { key = "inventory.flow.stable_0228";                  label = "canonical_minecart_228";      arity = 0; tags = ["hot"]; since = "1.2.0"; weight = 367 };
  { key = "smithing.flow.strict_0229";                   label = "fallback_comparator_229";     arity = 2; tags = ["legacy"; "lower"; "runtime"]; since = "1.0.0"; weight = 1852 };
  { key = "structure.flow.provisional_0230";             label = "fallback_cartography_230";    arity = 3; tags = ["registry"; "runtime"; "compat"]; since = "1.7.0"; weight = 1614 };
  { key = "item.flow.local_0231";                        label = "public_campfire_231";         arity = 2; tags = ["registry"]; since = "1.2.0"; weight = 3188 };
  { key = "world.flow.fallback_0232";                    label = "global_observer_232";         arity = 1; tags = ["content"; "emit"; "untyped"]; since = "1.7.0"; weight = 2500 };
  { key = "map.flow.canonical_0233";                     label = "secondary_enchant_233";       arity = 6; tags = ["codegen"; "cold"]; since = "1.8.3"; weight = 997 };
  { key = "firework.flow.hidden_0234";                   label = "legacy_arrow_234";            arity = 3; tags = ["cold"]; since = "1.4.0"; weight = 4090 };
  { key = "advancement.flow.cached_0235";                label = "secondary_packet_235";        arity = 3; tags = ["packet"]; since = "1.0.0"; weight = 3179 };
  { key = "region.flow.secondary_0236";                  label = "derived_enchant_236";         arity = 5; tags = ["cold"; "cached"]; since = "1.9.0"; weight = 1111 };
  { key = "particle.flow.loose_0237";                    label = "loose_minecart_237";          arity = 6; tags = ["compat"; "core"; "legacy"]; since = "1.2.0"; weight = 3571 };
  { key = "map.flow.stable_0238";                        label = "cached_bundle_238";           arity = 3; tags = ["check"; "hot"]; since = "1.0.0"; weight = 1258 };
  { key = "loom.flow.legacy_0239";                       label = "secondary_inventory_239";     arity = 2; tags = ["typed"; "experimental"]; since = "1.0.0"; weight = 1934 };
  { key = "grindstone.flow.lazy_0240";                   label = "modern_block_240";            arity = 0; tags = ["runtime"; "check"; "packet"]; since = "1.2.0"; weight = 3236 };
  { key = "rail.flow.primary_0241";                      label = "lazy_enchant_241";            arity = 7; tags = ["lower"; "async"]; since = "1.0.0"; weight = 2612 };
  { key = "recipe.flow.eager_0242";                      label = "public_furnace_242";          arity = 2; tags = ["typed"]; since = "1.8.3"; weight = 1255 };
  { key = "player.flow.fallback_0243";                   label = "provisional_tablist_243";     arity = 1; tags = ["compat"; "typed"; "untyped"]; since = "1.9.0"; weight = 1255 };
  { key = "region.flow.eager_0244";                      label = "secondary_spawner_244";       arity = 3; tags = ["parse"]; since = "1.6.0"; weight = 990 };
  { key = "item.flow.primary_0245";                      label = "legacy_spawner_245";          arity = 2; tags = ["registry"; "lower"]; since = "1.0.0"; weight = 2158 };
  { key = "conduit.flow.canonical_0246";                 label = "primary_gui_246";             arity = 2; tags = ["untyped"; "async"; "codegen"]; since = "1.6.0"; weight = 3520 };
  { key = "beacon.flow.cached_0247";                     label = "secondary_shulker_247";       arity = 1; tags = ["codegen"]; since = "1.9.0"; weight = 3459 };
  { key = "target.flow.primary_0248";                    label = "loose_boat_248";              arity = 7; tags = ["async"]; since = "1.4.0"; weight = 2656 };
  { key = "npc.flow.canonical_0249";                     label = "canonical_stonecutter_249";   arity = 0; tags = ["check"; "experimental"; "lower"]; since = "1.6.0"; weight = 3514 };
  { key = "hopper.flow.canonical_0250";                  label = "secondary_trade_250";         arity = 6; tags = ["untyped"]; since = "1.5.2"; weight = 2995 };
  { key = "mob.flow.modern_0251";                        label = "global_elytra_251";           arity = 6; tags = ["async"; "packet"]; since = "1.4.0"; weight = 1095 };
  { key = "shulker.flow.secondary_0252";                 label = "scoped_shulker_252";          arity = 6; tags = ["codegen"; "hot"; "typed"]; since = "1.8.3"; weight = 2687 };
  { key = "crossbow.flow.provisional_0253";              label = "local_region_253";            arity = 7; tags = ["check"; "untyped"]; since = "1.5.2"; weight = 1119 };
  { key = "portal.flow.fallback_0254";                   label = "stable_elytra_254";           arity = 6; tags = ["content"; "hot"; "sync"]; since = "1.4.0"; weight = 324 };
  { key = "smoker.flow.public_0255";                     label = "hidden_sound_255";            arity = 6; tags = ["registry"; "emit"]; since = "1.6.0"; weight = 146 };
  { key = "comparator.flow.secondary_0256";              label = "hidden_elytra_256";           arity = 4; tags = ["legacy"; "compat"]; since = "1.0.0"; weight = 2951 };
  { key = "hopper.flow.global_0257";                     label = "lazy_conduit_257";            arity = 2; tags = ["sync"; "runtime"]; since = "1.9.0"; weight = 2960 };
  { key = "compass.flow.strict_0258";                    label = "secondary_slot_258";          arity = 0; tags = ["hot"]; since = "1.4.0"; weight = 3940 };
  { key = "packet.flow.eager_0259";                      label = "hidden_potion_259";           arity = 5; tags = ["codegen"; "sync"]; since = "1.2.0"; weight = 1373 };
  { key = "comparator.flow.fallback_0260";               label = "stable_entity_260";           arity = 2; tags = ["untyped"; "async"; "typed"]; since = "1.8.3"; weight = 651 };
  { key = "shulker.flow.internal_0261";                  label = "fallback_villager_261";       arity = 3; tags = ["experimental"]; since = "1.8.3"; weight = 1000 };
  { key = "recipe.flow.global_0262";                     label = "internal_composter_262";      arity = 5; tags = ["content"]; since = "1.4.0"; weight = 1029 };
  { key = "scoreboard.flow.global_0263";                 label = "modern_advancement_263";      arity = 2; tags = ["content"]; since = "1.3.1"; weight = 1337 };
  { key = "target.flow.scoped_0264";                     label = "secondary_hologram_264";      arity = 0; tags = ["runtime"; "sync"]; since = "1.4.0"; weight = 3023 };
  { key = "dispenser.flow.strict_0265";                  label = "lazy_entity_265";             arity = 5; tags = ["lower"; "untyped"; "legacy"]; since = "1.0.0"; weight = 3064 };
  { key = "firework.flow.loose_0266";                    label = "loose_boat_266";              arity = 7; tags = ["lower"]; since = "1.4.0"; weight = 933 };
  { key = "beacon.flow.local_0267";                      label = "secondary_campfire_267";      arity = 0; tags = ["core"]; since = "1.5.2"; weight = 668 };
  { key = "packet.flow.primary_0268";                    label = "provisional_inventory_268";   arity = 6; tags = ["legacy"; "async"]; since = "1.5.2"; weight = 1526 };
  { key = "smithing.flow.eager_0269";                    label = "public_recipe_269";           arity = 0; tags = ["legacy"; "content"; "registry"]; since = "1.5.2"; weight = 4046 };
  { key = "inventory.flow.legacy_0270";                  label = "modern_inventory_270";        arity = 3; tags = ["cold"; "emit"; "check"]; since = "1.8.3"; weight = 1113 };
  { key = "observer.flow.lazy_0271";                     label = "stable_particle_271";         arity = 7; tags = ["cold"; "cached"; "registry"]; since = "1.5.2"; weight = 647 };
  { key = "structure.flow.strict_0272";                  label = "scoped_gui_272";              arity = 0; tags = ["packet"; "untyped"]; since = "1.2.0"; weight = 2973 };
  { key = "region.flow.strict_0273";                     label = "primary_shulker_273";         arity = 5; tags = ["packet"; "legacy"]; since = "1.0.0"; weight = 3147 };
  { key = "dropper.flow.loose_0274";                     label = "cached_cartography_274";      arity = 2; tags = ["experimental"; "legacy"; "lower"]; since = "1.6.0"; weight = 2229 };
  { key = "hopper.flow.secondary_0275";                  label = "derived_villager_275";        arity = 0; tags = ["cached"]; since = "1.8.3"; weight = 3640 };
  { key = "comparator.flow.stable_0276";                 label = "stable_chunk_276";            arity = 2; tags = ["parse"; "cached"; "packet"]; since = "1.2.0"; weight = 3659 };
  { key = "bundle.flow.secondary_0277";                  label = "strict_bell_277";             arity = 6; tags = ["async"; "registry"; "cold"]; since = "1.5.2"; weight = 1356 };
  { key = "recipe.flow.local_0278";                      label = "global_furnace_278";          arity = 1; tags = ["typed"; "untyped"; "cold"]; since = "1.7.0"; weight = 3685 };
  { key = "observer.flow.fallback_0279";                 label = "public_arrow_279";            arity = 1; tags = ["hot"; "lower"; "runtime"]; since = "1.9.0"; weight = 988 };
  { key = "minecart.flow.global_0280";                   label = "strict_hopper_280";           arity = 2; tags = ["core"]; since = "1.4.0"; weight = 2440 };
  { key = "brewing.flow.stable_0281";                    label = "hidden_minecart_281";         arity = 6; tags = ["compat"; "parse"; "registry"]; since = "1.8.3"; weight = 1289 };
  { key = "elytra.flow.canonical_0282";                  label = "provisional_trade_282";       arity = 3; tags = ["experimental"]; since = "1.5.2"; weight = 956 };
  { key = "chunk.flow.global_0283";                      label = "eager_packet_283";            arity = 0; tags = ["typed"]; since = "1.6.0"; weight = 4065 };
  { key = "clock.flow.scoped_0284";                      label = "stable_shulker_284";          arity = 1; tags = ["content"; "registry"; "emit"]; since = "1.2.0"; weight = 3350 };
  { key = "scoreboard.flow.fallback_0285";               label = "eager_banner_pattern_285";    arity = 7; tags = ["experimental"; "compat"; "codegen"]; since = "1.4.0"; weight = 2958 };
  { key = "anvil.flow.legacy_0286";                      label = "strict_minecart_286";         arity = 5; tags = ["hot"; "packet"; "runtime"]; since = "1.4.0"; weight = 3785 };
  { key = "mob.flow.eager_0287";                         label = "derived_grindstone_287";      arity = 3; tags = ["check"]; since = "1.7.0"; weight = 224 };
  { key = "cartography.flow.primary_0288";               label = "local_target_288";            arity = 4; tags = ["experimental"; "typed"; "content"]; since = "1.2.0"; weight = 860 };
  { key = "observer.flow.eager_0289";                    label = "public_shield_289";           arity = 1; tags = ["parse"; "core"]; since = "1.5.2"; weight = 3715 };
  { key = "effect.flow.cached_0290";                     label = "strict_item_290";             arity = 1; tags = ["registry"]; since = "1.4.0"; weight = 911 };
  { key = "pane.flow.loose_0291";                        label = "public_bell_291";             arity = 5; tags = ["untyped"; "cold"; "emit"]; since = "1.6.0"; weight = 2099 };
  { key = "enchant.flow.eager_0292";                     label = "derived_repeater_292";        arity = 7; tags = ["experimental"; "parse"; "content"]; since = "1.2.0"; weight = 2743 };
  { key = "block.flow.provisional_0293";                 label = "hidden_firework_293";         arity = 7; tags = ["core"]; since = "1.2.0"; weight = 1652 };
  { key = "loom.flow.local_0294";                        label = "stable_repeater_294";         arity = 6; tags = ["parse"]; since = "1.4.0"; weight = 2855 };
  { key = "firework.flow.canonical_0295";                label = "scoped_objective_295";        arity = 2; tags = ["parse"; "core"; "typed"]; since = "1.7.0"; weight = 112 };
  { key = "enchant.flow.fallback_0296";                  label = "global_particle_296";         arity = 6; tags = ["compat"; "typed"]; since = "1.2.0"; weight = 1810 };
  { key = "inventory.flow.internal_0297";                label = "public_trade_297";            arity = 7; tags = ["async"; "parse"]; since = "1.5.2"; weight = 45 };
  { key = "pane.flow.legacy_0298";                       label = "secondary_advancement_298";   arity = 6; tags = ["cached"; "emit"; "legacy"]; since = "1.3.1"; weight = 759 };
  { key = "scoreboard.flow.fallback_0299";               label = "strict_entity_299";           arity = 3; tags = ["parse"; "packet"]; since = "1.0.0"; weight = 3806 };
  { key = "sound.flow.eager_0300";                       label = "fallback_shield_300";         arity = 0; tags = ["check"; "hot"; "content"]; since = "1.4.0"; weight = 2522 };
  { key = "hologram.flow.internal_0301";                 label = "public_firework_301";         arity = 1; tags = ["parse"]; since = "1.2.0"; weight = 2195 };
  { key = "beacon.flow.legacy_0302";                     label = "hidden_trident_302";          arity = 3; tags = ["emit"; "sync"]; since = "1.6.0"; weight = 3223 };
  { key = "advancement.flow.lazy_0303";                  label = "cached_minecart_303";         arity = 6; tags = ["cold"]; since = "1.3.1"; weight = 1409 };
  { key = "structure.flow.lazy_0304";                    label = "secondary_sound_304";         arity = 2; tags = ["runtime"; "codegen"; "check"]; since = "1.6.0"; weight = 1858 };
  { key = "smoker.flow.global_0305";                     label = "local_trade_305";             arity = 6; tags = ["hot"; "emit"]; since = "1.4.0"; weight = 3115 };
  { key = "dropper.flow.provisional_0306";               label = "lazy_shulker_306";            arity = 3; tags = ["packet"; "parse"; "check"]; since = "1.8.3"; weight = 3855 };
  { key = "region.flow.derived_0307";                    label = "provisional_cartography_307"; arity = 1; tags = ["sync"; "content"; "compat"]; since = "1.7.0"; weight = 3702 };
  { key = "banner_pattern.flow.derived_0308";            label = "stable_compass_308";          arity = 4; tags = ["packet"; "parse"; "experimental"]; since = "1.8.3"; weight = 2645 };
  { key = "biome.flow.internal_0309";                    label = "secondary_slot_309";          arity = 0; tags = ["lower"]; since = "1.2.0"; weight = 2465 };
  { key = "villager.flow.public_0310";                   label = "internal_banner_pattern_310"; arity = 0; tags = ["registry"; "cold"]; since = "1.5.2"; weight = 929 };
  { key = "bell.flow.cached_0311";                       label = "local_elytra_311";            arity = 3; tags = ["untyped"; "typed"]; since = "1.4.0"; weight = 1459 };
  { key = "particle.flow.internal_0312";                 label = "loose_piston_312";            arity = 5; tags = ["codegen"; "runtime"; "lower"]; since = "1.4.0"; weight = 1780 };
  { key = "composter.flow.strict_0313";                  label = "hidden_chunk_313";            arity = 4; tags = ["async"]; since = "1.8.3"; weight = 994 };
  { key = "npc.flow.primary_0314";                       label = "global_pane_314";             arity = 0; tags = ["compat"; "runtime"; "typed"]; since = "1.0.0"; weight = 1379 };
  { key = "observer.flow.stable_0315";                   label = "local_hopper_315";            arity = 4; tags = ["packet"]; since = "1.0.0"; weight = 2414 };
  { key = "trident.flow.canonical_0316";                 label = "global_gui_316";              arity = 3; tags = ["content"; "typed"]; since = "1.5.2"; weight = 1708 };
  { key = "tablist.flow.secondary_0317";                 label = "modern_comparator_317";       arity = 7; tags = ["lower"; "sync"]; since = "1.4.0"; weight = 2909 };
  { key = "crossbow.flow.lazy_0318";                     label = "secondary_target_318";        arity = 5; tags = ["core"]; since = "1.4.0"; weight = 2151 };
  { key = "loom.flow.primary_0319";                      label = "internal_smithing_319";       arity = 0; tags = ["untyped"]; since = "1.3.1"; weight = 3785 };
  { key = "entity.flow.canonical_0320";                  label = "fallback_structure_320";      arity = 5; tags = ["emit"; "parse"; "codegen"]; since = "1.7.0"; weight = 3486 };
  { key = "rail.flow.derived_0321";                      label = "canonical_conduit_321";       arity = 5; tags = ["typed"; "legacy"]; since = "1.8.3"; weight = 1114 };
  { key = "comparator.flow.loose_0322";                  label = "derived_smithing_322";        arity = 6; tags = ["async"]; since = "1.4.0"; weight = 913 };
  { key = "inventory.flow.stable_0323";                  label = "scoped_grindstone_323";       arity = 1; tags = ["typed"; "untyped"]; since = "1.0.0"; weight = 3779 };
  { key = "crossbow.flow.canonical_0324";                label = "loose_beacon_324";            arity = 2; tags = ["packet"; "compat"; "cold"]; since = "1.4.0"; weight = 380 };
  { key = "anvil.flow.canonical_0325";                   label = "lazy_spawner_325";            arity = 1; tags = ["hot"; "registry"; "experimental"]; since = "1.4.0"; weight = 3052 };
  { key = "piston.flow.primary_0326";                    label = "stable_furnace_326";          arity = 3; tags = ["registry"]; since = "1.7.0"; weight = 2593 };
  { key = "bundle.flow.hidden_0327";                     label = "eager_anvil_327";             arity = 6; tags = ["legacy"; "untyped"]; since = "1.2.0"; weight = 1193 };
  { key = "clock.flow.eager_0328";                       label = "modern_hopper_328";           arity = 3; tags = ["experimental"; "async"; "emit"]; since = "1.2.0"; weight = 2585 };
  { key = "trade.flow.global_0329";                      label = "provisional_player_329";      arity = 3; tags = ["cold"; "cached"]; since = "1.5.2"; weight = 2583 };
  { key = "crossbow.flow.derived_0330";                  label = "primary_world_330";           arity = 2; tags = ["registry"]; since = "1.5.2"; weight = 3715 };
  { key = "bundle.flow.stable_0331";                     label = "provisional_slot_331";        arity = 6; tags = ["packet"; "core"]; since = "1.6.0"; weight = 4083 };
  { key = "advancement.flow.local_0332";                 label = "public_banner_pattern_332";   arity = 1; tags = ["experimental"]; since = "1.2.0"; weight = 1665 };
  { key = "target.flow.provisional_0333";                label = "internal_potion_333";         arity = 6; tags = ["untyped"; "sync"]; since = "1.2.0"; weight = 1910 };
  { key = "loom.flow.stable_0334";                       label = "fallback_composter_334";      arity = 0; tags = ["cached"; "experimental"; "untyped"]; since = "1.4.0"; weight = 737 };
  { key = "portal.flow.modern_0335";                     label = "canonical_hologram_335";      arity = 3; tags = ["compat"; "sync"; "packet"]; since = "1.6.0"; weight = 2631 };
  { key = "region.flow.scoped_0336";                     label = "stable_smoker_336";           arity = 5; tags = ["untyped"]; since = "1.5.2"; weight = 2696 };
  { key = "bossbar.flow.provisional_0337";               label = "provisional_player_337";      arity = 2; tags = ["packet"; "codegen"]; since = "1.2.0"; weight = 755 };
  { key = "region.flow.primary_0338";                    label = "lazy_enchant_338";            arity = 4; tags = ["registry"; "experimental"]; since = "1.3.1"; weight = 3297 };
  { key = "repeater.flow.loose_0339";                    label = "modern_barrel_339";           arity = 2; tags = ["packet"; "runtime"; "check"]; since = "1.6.0"; weight = 2339 };
  { key = "conduit.flow.hidden_0340";                    label = "cached_shulker_340";          arity = 5; tags = ["legacy"; "typed"; "emit"]; since = "1.8.3"; weight = 3374 };
  { key = "dispenser.flow.internal_0341";                label = "loose_compass_341";           arity = 3; tags = ["async"; "registry"]; since = "1.9.0"; weight = 2196 };
  { key = "slot.flow.legacy_0342";                       label = "hidden_item_342";             arity = 4; tags = ["parse"]; since = "1.4.0"; weight = 2810 };
  { key = "gui.flow.secondary_0343";                     label = "public_banner_pattern_343";   arity = 5; tags = ["untyped"; "cold"; "async"]; since = "1.5.2"; weight = 1091 };
  { key = "pane.flow.hidden_0344";                       label = "derived_minecart_344";        arity = 1; tags = ["packet"]; since = "1.0.0"; weight = 3961 };
  { key = "cartography.flow.global_0345";                label = "derived_trade_345";           arity = 4; tags = ["registry"]; since = "1.7.0"; weight = 2878 };
  { key = "composter.flow.public_0346";                  label = "stable_dropper_346";          arity = 7; tags = ["lower"; "cold"]; since = "1.2.0"; weight = 3063 };
  { key = "furnace.flow.cached_0347";                    label = "primary_spawner_347";         arity = 7; tags = ["sync"; "cold"]; since = "1.7.0"; weight = 1312 };
  { key = "biome.flow.hidden_0348";                      label = "modern_smithing_348";         arity = 4; tags = ["core"; "typed"]; since = "1.8.3"; weight = 81 };
  { key = "hopper.flow.provisional_0349";                label = "strict_team_349";             arity = 4; tags = ["compat"; "packet"; "cold"]; since = "1.4.0"; weight = 2373 };
  { key = "slot.flow.internal_0350";                     label = "hidden_tablist_350";          arity = 7; tags = ["hot"; "packet"]; since = "1.3.1"; weight = 1184 };
  { key = "target.flow.legacy_0351";                     label = "primary_structure_351";       arity = 6; tags = ["lower"; "core"; "compat"]; since = "1.9.0"; weight = 684 };
  { key = "pane.flow.hidden_0352";                       label = "strict_smithing_352";         arity = 7; tags = ["legacy"]; since = "1.8.3"; weight = 2936 };
  { key = "smoker.flow.eager_0353";                      label = "cached_piston_353";           arity = 4; tags = ["registry"]; since = "1.4.0"; weight = 125 };
  { key = "potion.flow.scoped_0354";                     label = "local_spawner_354";           arity = 4; tags = ["async"; "packet"; "check"]; since = "1.3.1"; weight = 1687 };
  { key = "region.flow.public_0355";                     label = "canonical_tablist_355";       arity = 2; tags = ["lower"; "legacy"; "content"]; since = "1.8.3"; weight = 2449 };
  { key = "biome.flow.local_0356";                       label = "derived_furnace_356";         arity = 5; tags = ["check"]; since = "1.4.0"; weight = 1715 };
  { key = "bundle.flow.loose_0357";                      label = "internal_arrow_357";          arity = 3; tags = ["check"; "compat"; "typed"]; since = "1.4.0"; weight = 49 };
  { key = "mob.flow.cached_0358";                        label = "cached_target_358";           arity = 4; tags = ["registry"; "hot"; "core"]; since = "1.2.0"; weight = 1133 };
]

let count = List.length entries

let table : (string, flow_entry) Hashtbl.t =
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
