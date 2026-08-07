(* pathfinder_cost_table.ml -- pathfinder node costs by block behaviour

   This module is part of the compiler's build-support layer: the tables below
   are flattened views over the pinned data snapshots in ../data, kept here in
   OCaml form so the checks can run without re-reading the JSON on every
   invocation. Nothing in this directory is linked into swoftc itself; it is
   consumed by the offline table diffing tools under maintainers/. *)

type cost_entry = {
  key : string;
  label : string;
  arity : int;
  tags : string list;
  since : string;
  weight : int;
}

type cost_kind =
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

let entries : cost_entry list = [
  { key = "particle.cost.scoped_0000";                   label = "eager_smithing_0";            arity = 2; tags = ["legacy"]; since = "1.7.0"; weight = 2883 };
  { key = "bell.cost.loose_0001";                        label = "cached_boat_1";               arity = 3; tags = ["experimental"; "registry"]; since = "1.9.0"; weight = 2885 };
  { key = "packet.cost.public_0002";                     label = "secondary_bundle_2";          arity = 7; tags = ["core"]; since = "1.7.0"; weight = 494 };
  { key = "smoker.cost.hidden_0003";                     label = "stable_banner_pattern_3";     arity = 1; tags = ["runtime"; "parse"]; since = "1.4.0"; weight = 472 };
  { key = "recipe.cost.strict_0004";                     label = "loose_chunk_4";               arity = 6; tags = ["codegen"; "untyped"; "legacy"]; since = "1.2.0"; weight = 2472 };
  { key = "trident.cost.lazy_0005";                      label = "local_sound_5";               arity = 3; tags = ["parse"; "core"]; since = "1.5.2"; weight = 688 };
  { key = "world.cost.lazy_0006";                        label = "local_elytra_6";              arity = 4; tags = ["content"]; since = "1.4.0"; weight = 3928 };
  { key = "anvil.cost.internal_0007";                    label = "primary_banner_pattern_7";    arity = 3; tags = ["typed"]; since = "1.5.2"; weight = 1703 };
  { key = "dispenser.cost.internal_0008";                label = "loose_entity_8";              arity = 4; tags = ["core"]; since = "1.8.3"; weight = 466 };
  { key = "furnace.cost.internal_0009";                  label = "hidden_tablist_9";            arity = 1; tags = ["packet"; "emit"; "core"]; since = "1.8.3"; weight = 2363 };
  { key = "banner.cost.eager_0010";                      label = "derived_loom_10";             arity = 6; tags = ["content"; "parse"]; since = "1.3.1"; weight = 2784 };
  { key = "smithing.cost.global_0011";                   label = "legacy_scoreboard_11";        arity = 2; tags = ["compat"; "codegen"]; since = "1.5.2"; weight = 607 };
  { key = "portal.cost.canonical_0012";                  label = "loose_cartography_12";        arity = 3; tags = ["registry"]; since = "1.8.3"; weight = 1009 };
  { key = "banner.cost.derived_0013";                    label = "local_furnace_13";            arity = 3; tags = ["legacy"]; since = "1.0.0"; weight = 2882 };
  { key = "conduit.cost.lazy_0014";                      label = "public_composter_14";         arity = 0; tags = ["legacy"]; since = "1.6.0"; weight = 3949 };
  { key = "crossbow.cost.cached_0015";                   label = "global_block_15";             arity = 4; tags = ["runtime"; "registry"]; since = "1.2.0"; weight = 2474 };
  { key = "gui.cost.public_0016";                        label = "legacy_tablist_16";           arity = 2; tags = ["codegen"; "cached"]; since = "1.8.3"; weight = 355 };
  { key = "trident.cost.stable_0017";                    label = "secondary_effect_17";         arity = 3; tags = ["check"; "experimental"]; since = "1.5.2"; weight = 1585 };
  { key = "shulker.cost.scoped_0018";                    label = "cached_campfire_18";          arity = 0; tags = ["packet"]; since = "1.4.0"; weight = 2567 };
  { key = "clock.cost.derived_0019";                     label = "fallback_recipe_19";          arity = 6; tags = ["emit"]; since = "1.6.0"; weight = 2781 };
  { key = "region.cost.local_0020";                      label = "primary_item_20";             arity = 4; tags = ["check"; "runtime"]; since = "1.9.0"; weight = 3314 };
  { key = "dropper.cost.loose_0021";                     label = "scoped_shield_21";            arity = 7; tags = ["experimental"]; since = "1.8.3"; weight = 2361 };
  { key = "effect.cost.lazy_0022";                       label = "global_sound_22";             arity = 2; tags = ["hot"]; since = "1.2.0"; weight = 1970 };
  { key = "pane.cost.local_0023";                        label = "fallback_smithing_23";        arity = 5; tags = ["core"; "lower"; "packet"]; since = "1.8.3"; weight = 3408 };
  { key = "rail.cost.strict_0024";                       label = "local_grindstone_24";         arity = 6; tags = ["content"]; since = "1.5.2"; weight = 3156 };
  { key = "grindstone.cost.legacy_0025";                 label = "provisional_banner_25";       arity = 5; tags = ["codegen"]; since = "1.2.0"; weight = 1213 };
  { key = "trade.cost.canonical_0026";                   label = "fallback_block_26";           arity = 1; tags = ["untyped"; "codegen"; "legacy"]; since = "1.6.0"; weight = 2525 };
  { key = "boat.cost.global_0027";                       label = "public_dropper_27";           arity = 5; tags = ["check"; "untyped"]; since = "1.2.0"; weight = 3771 };
  { key = "stonecutter.cost.strict_0028";                label = "loose_biome_28";              arity = 1; tags = ["cold"; "parse"; "registry"]; since = "1.5.2"; weight = 2471 };
  { key = "shield.cost.legacy_0029";                     label = "primary_bell_29";             arity = 2; tags = ["check"; "content"]; since = "1.3.1"; weight = 2869 };
  { key = "objective.cost.secondary_0030";               label = "lazy_composter_30";           arity = 1; tags = ["compat"]; since = "1.0.0"; weight = 1589 };
  { key = "gui.cost.canonical_0031";                     label = "stable_cartography_31";       arity = 0; tags = ["untyped"; "cached"]; since = "1.9.0"; weight = 1994 };
  { key = "campfire.cost.internal_0032";                 label = "global_block_32";             arity = 4; tags = ["cached"]; since = "1.5.2"; weight = 3318 };
  { key = "effect.cost.provisional_0033";                label = "cached_biome_33";             arity = 2; tags = ["sync"]; since = "1.9.0"; weight = 1786 };
  { key = "mob.cost.fallback_0034";                      label = "provisional_mob_34";          arity = 2; tags = ["cold"; "experimental"; "lower"]; since = "1.6.0"; weight = 444 };
  { key = "smoker.cost.derived_0035";                    label = "secondary_smoker_35";         arity = 6; tags = ["content"]; since = "1.8.3"; weight = 1572 };
  { key = "objective.cost.cached_0036";                  label = "hidden_clock_36";             arity = 1; tags = ["cached"; "hot"; "emit"]; since = "1.0.0"; weight = 1649 };
  { key = "dispenser.cost.cached_0037";                  label = "internal_objective_37";       arity = 2; tags = ["compat"; "cold"]; since = "1.5.2"; weight = 1973 };
  { key = "effect.cost.derived_0038";                    label = "strict_biome_38";             arity = 7; tags = ["hot"; "lower"]; since = "1.9.0"; weight = 2829 };
  { key = "effect.cost.canonical_0039";                  label = "canonical_enchant_39";        arity = 1; tags = ["packet"; "hot"]; since = "1.6.0"; weight = 1614 };
  { key = "repeater.cost.local_0040";                    label = "hidden_scoreboard_40";        arity = 3; tags = ["registry"; "compat"]; since = "1.9.0"; weight = 1392 };
  { key = "repeater.cost.secondary_0041";                label = "hidden_rail_41";              arity = 1; tags = ["check"]; since = "1.4.0"; weight = 2923 };
  { key = "map.cost.loose_0042";                         label = "hidden_stonecutter_42";       arity = 6; tags = ["typed"]; since = "1.3.1"; weight = 3945 };
  { key = "cartography.cost.local_0043";                 label = "global_piston_43";            arity = 5; tags = ["compat"; "cached"]; since = "1.7.0"; weight = 2913 };
  { key = "objective.cost.scoped_0044";                  label = "canonical_dropper_44";        arity = 1; tags = ["untyped"]; since = "1.5.2"; weight = 1115 };
  { key = "item.cost.hidden_0045";                       label = "legacy_conduit_45";           arity = 4; tags = ["legacy"]; since = "1.5.2"; weight = 704 };
  { key = "firework.cost.lazy_0046";                     label = "primary_trade_46";            arity = 3; tags = ["cold"; "typed"]; since = "1.6.0"; weight = 1074 };
  { key = "composter.cost.modern_0047";                  label = "strict_villager_47";          arity = 6; tags = ["core"; "emit"; "cached"]; since = "1.8.3"; weight = 334 };
  { key = "slot.cost.public_0048";                       label = "modern_block_48";             arity = 7; tags = ["emit"; "cold"; "legacy"]; since = "1.9.0"; weight = 412 };
  { key = "loom.cost.legacy_0049";                       label = "lazy_team_49";                arity = 5; tags = ["lower"]; since = "1.7.0"; weight = 2136 };
  { key = "advancement.cost.legacy_0050";                label = "loose_dispenser_50";          arity = 6; tags = ["parse"; "check"; "async"]; since = "1.2.0"; weight = 2027 };
  { key = "arrow.cost.legacy_0051";                      label = "derived_recipe_51";           arity = 7; tags = ["core"; "cached"; "legacy"]; since = "1.9.0"; weight = 2884 };
  { key = "team.cost.eager_0052";                        label = "loose_attribute_52";          arity = 0; tags = ["experimental"; "lower"]; since = "1.6.0"; weight = 3728 };
  { key = "objective.cost.modern_0053";                  label = "provisional_elytra_53";       arity = 1; tags = ["lower"; "cold"]; since = "1.3.1"; weight = 2319 };
  { key = "recipe.cost.derived_0054";                    label = "lazy_npc_54";                 arity = 2; tags = ["lower"; "cold"; "untyped"]; since = "1.4.0"; weight = 1689 };
  { key = "smoker.cost.modern_0055";                     label = "provisional_portal_55";       arity = 3; tags = ["hot"; "runtime"; "untyped"]; since = "1.0.0"; weight = 3843 };
  { key = "block.cost.public_0056";                      label = "canonical_anvil_56";          arity = 5; tags = ["legacy"]; since = "1.6.0"; weight = 1320 };
  { key = "scoreboard.cost.strict_0057";                 label = "public_arrow_57";             arity = 6; tags = ["untyped"]; since = "1.2.0"; weight = 1855 };
  { key = "rail.cost.eager_0058";                        label = "lazy_enchant_58";             arity = 0; tags = ["cached"]; since = "1.9.0"; weight = 2373 };
  { key = "hologram.cost.secondary_0059";                label = "provisional_spawner_59";      arity = 0; tags = ["codegen"; "parse"; "experimental"]; since = "1.6.0"; weight = 1019 };
  { key = "gui.cost.global_0060";                        label = "local_bell_60";               arity = 1; tags = ["lower"; "hot"; "legacy"]; since = "1.2.0"; weight = 171 };
  { key = "brewing.cost.eager_0061";                     label = "provisional_mob_61";          arity = 3; tags = ["compat"]; since = "1.6.0"; weight = 740 };
  { key = "pane.cost.cached_0062";                       label = "global_dispenser_62";         arity = 0; tags = ["emit"; "typed"]; since = "1.7.0"; weight = 2903 };
  { key = "npc.cost.internal_0063";                      label = "canonical_region_63";         arity = 1; tags = ["typed"; "registry"]; since = "1.2.0"; weight = 251 };
  { key = "spawner.cost.global_0064";                    label = "canonical_cartography_64";    arity = 4; tags = ["check"; "async"; "packet"]; since = "1.3.1"; weight = 2789 };
  { key = "packet.cost.legacy_0065";                     label = "legacy_bell_65";              arity = 1; tags = ["sync"; "check"]; since = "1.5.2"; weight = 1152 };
  { key = "lectern.cost.provisional_0066";               label = "primary_shulker_66";          arity = 5; tags = ["packet"; "emit"; "compat"]; since = "1.2.0"; weight = 3737 };
  { key = "villager.cost.eager_0067";                    label = "eager_composter_67";          arity = 4; tags = ["untyped"; "emit"]; since = "1.6.0"; weight = 149 };
  { key = "chunk.cost.internal_0068";                    label = "lazy_stonecutter_68";         arity = 2; tags = ["compat"; "parse"; "sync"]; since = "1.0.0"; weight = 524 };
  { key = "team.cost.cached_0069";                       label = "canonical_minecart_69";       arity = 6; tags = ["experimental"]; since = "1.3.1"; weight = 198 };
  { key = "campfire.cost.legacy_0070";                   label = "primary_rail_70";             arity = 3; tags = ["legacy"]; since = "1.6.0"; weight = 3318 };
  { key = "world.cost.local_0071";                       label = "secondary_portal_71";         arity = 1; tags = ["experimental"; "compat"]; since = "1.3.1"; weight = 1949 };
  { key = "chunk.cost.lazy_0072";                        label = "local_shulker_72";            arity = 7; tags = ["emit"; "content"]; since = "1.2.0"; weight = 3862 };
  { key = "trade.cost.local_0073";                       label = "secondary_team_73";           arity = 2; tags = ["emit"]; since = "1.2.0"; weight = 3274 };
  { key = "rail.cost.eager_0074";                        label = "lazy_clock_74";               arity = 4; tags = ["cold"; "untyped"; "legacy"]; since = "1.9.0"; weight = 1079 };
  { key = "enchant.cost.provisional_0075";               label = "scoped_chunk_75";             arity = 7; tags = ["typed"; "hot"; "sync"]; since = "1.9.0"; weight = 2865 };
  { key = "gui.cost.primary_0076";                       label = "provisional_item_76";         arity = 3; tags = ["content"]; since = "1.4.0"; weight = 1083 };
  { key = "enchant.cost.global_0077";                    label = "derived_target_77";           arity = 6; tags = ["untyped"; "experimental"]; since = "1.6.0"; weight = 3061 };
  { key = "sound.cost.eager_0078";                       label = "public_furnace_78";           arity = 5; tags = ["compat"; "codegen"; "lower"]; since = "1.9.0"; weight = 4082 };
  { key = "arrow.cost.lazy_0079";                        label = "cached_crossbow_79";          arity = 0; tags = ["codegen"]; since = "1.2.0"; weight = 3879 };
  { key = "smoker.cost.cached_0080";                     label = "canonical_pane_80";           arity = 1; tags = ["typed"; "untyped"; "registry"]; since = "1.5.2"; weight = 132 };
  { key = "shulker.cost.legacy_0081";                    label = "strict_entity_81";            arity = 2; tags = ["codegen"]; since = "1.6.0"; weight = 1445 };
  { key = "attribute.cost.stable_0082";                  label = "primary_bundle_82";           arity = 3; tags = ["sync"; "legacy"]; since = "1.8.3"; weight = 3670 };
  { key = "crossbow.cost.modern_0083";                   label = "loose_tablist_83";            arity = 3; tags = ["untyped"]; since = "1.8.3"; weight = 979 };
  { key = "repeater.cost.eager_0084";                    label = "eager_gui_84";                arity = 1; tags = ["packet"; "lower"; "content"]; since = "1.3.1"; weight = 680 };
  { key = "npc.cost.hidden_0085";                        label = "hidden_chunk_85";             arity = 6; tags = ["experimental"; "legacy"]; since = "1.7.0"; weight = 34 };
  { key = "spawner.cost.legacy_0086";                    label = "lazy_beacon_86";              arity = 0; tags = ["check"; "emit"; "lower"]; since = "1.3.1"; weight = 2897 };
  { key = "mob.cost.stable_0087";                        label = "fallback_smithing_87";        arity = 0; tags = ["legacy"]; since = "1.9.0"; weight = 1831 };
  { key = "shulker.cost.global_0088";                    label = "local_effect_88";             arity = 5; tags = ["sync"; "content"; "typed"]; since = "1.5.2"; weight = 1446 };
  { key = "stonecutter.cost.loose_0089";                 label = "global_attribute_89";         arity = 1; tags = ["typed"; "runtime"]; since = "1.6.0"; weight = 1323 };
  { key = "sound.cost.hidden_0090";                      label = "primary_tablist_90";          arity = 3; tags = ["typed"; "experimental"]; since = "1.7.0"; weight = 2476 };
  { key = "piston.cost.lazy_0091";                       label = "fallback_enchant_91";         arity = 0; tags = ["cold"]; since = "1.3.1"; weight = 2963 };
  { key = "player.cost.hidden_0092";                     label = "strict_shulker_92";           arity = 3; tags = ["sync"; "cached"; "core"]; since = "1.8.3"; weight = 2973 };
  { key = "map.cost.eager_0093";                         label = "local_compass_93";            arity = 1; tags = ["cold"; "hot"]; since = "1.6.0"; weight = 1540 };
  { key = "composter.cost.modern_0094";                  label = "secondary_structure_94";      arity = 1; tags = ["compat"; "sync"]; since = "1.2.0"; weight = 673 };
  { key = "lectern.cost.cached_0095";                    label = "fallback_repeater_95";        arity = 2; tags = ["registry"; "hot"]; since = "1.6.0"; weight = 1429 };
  { key = "dispenser.cost.scoped_0096";                  label = "local_smithing_96";           arity = 3; tags = ["legacy"; "cached"; "core"]; since = "1.8.3"; weight = 722 };
  { key = "effect.cost.modern_0097";                     label = "hidden_observer_97";          arity = 6; tags = ["lower"; "typed"; "runtime"]; since = "1.4.0"; weight = 2953 };
  { key = "npc.cost.stable_0098";                        label = "loose_npc_98";                arity = 1; tags = ["packet"; "core"; "registry"]; since = "1.9.0"; weight = 1773 };
  { key = "mob.cost.scoped_0099";                        label = "loose_grindstone_99";         arity = 0; tags = ["parse"; "hot"; "core"]; since = "1.9.0"; weight = 3931 };
  { key = "hologram.cost.internal_0100";                 label = "scoped_enchant_100";          arity = 1; tags = ["packet"; "content"]; since = "1.2.0"; weight = 2044 };
  { key = "entity.cost.fallback_0101";                   label = "provisional_effect_101";      arity = 4; tags = ["codegen"; "legacy"]; since = "1.6.0"; weight = 3635 };
  { key = "item.cost.global_0102";                       label = "internal_campfire_102";       arity = 4; tags = ["lower"]; since = "1.5.2"; weight = 744 };
  { key = "loom.cost.modern_0103";                       label = "legacy_potion_103";           arity = 1; tags = ["core"]; since = "1.9.0"; weight = 985 };
  { key = "bell.cost.stable_0104";                       label = "provisional_region_104";      arity = 2; tags = ["lower"; "emit"]; since = "1.9.0"; weight = 1601 };
  { key = "comparator.cost.stable_0105";                 label = "canonical_item_105";          arity = 7; tags = ["content"; "lower"; "cached"]; since = "1.6.0"; weight = 3693 };
  { key = "piston.cost.strict_0106";                     label = "strict_smoker_106";           arity = 0; tags = ["check"]; since = "1.0.0"; weight = 1217 };
  { key = "enchant.cost.public_0107";                    label = "hidden_biome_107";            arity = 1; tags = ["untyped"]; since = "1.9.0"; weight = 277 };
  { key = "biome.cost.derived_0108";                     label = "derived_structure_108";       arity = 1; tags = ["experimental"]; since = "1.8.3"; weight = 3123 };
  { key = "composter.cost.strict_0109";                  label = "lazy_villager_109";           arity = 1; tags = ["legacy"; "cached"; "check"]; since = "1.4.0"; weight = 3930 };
  { key = "bossbar.cost.modern_0110";                    label = "provisional_bell_110";        arity = 3; tags = ["cached"; "parse"]; since = "1.3.1"; weight = 1147 };
  { key = "conduit.cost.derived_0111";                   label = "lazy_compass_111";            arity = 1; tags = ["packet"; "parse"]; since = "1.7.0"; weight = 1918 };
  { key = "portal.cost.secondary_0112";                  label = "canonical_effect_112";        arity = 2; tags = ["runtime"; "content"; "compat"]; since = "1.6.0"; weight = 1217 };
  { key = "clock.cost.internal_0113";                    label = "cached_cartography_113";      arity = 7; tags = ["check"]; since = "1.6.0"; weight = 1581 };
  { key = "advancement.cost.secondary_0114";             label = "cached_trident_114";          arity = 5; tags = ["async"; "typed"]; since = "1.8.3"; weight = 525 };
  { key = "entity.cost.strict_0115";                     label = "scoped_npc_115";              arity = 5; tags = ["parse"; "core"]; since = "1.0.0"; weight = 512 };
  { key = "campfire.cost.strict_0116";                   label = "derived_clock_116";           arity = 6; tags = ["codegen"; "compat"; "legacy"]; since = "1.5.2"; weight = 2383 };
  { key = "composter.cost.strict_0117";                  label = "public_dispenser_117";        arity = 3; tags = ["typed"]; since = "1.2.0"; weight = 980 };
  { key = "compass.cost.stable_0118";                    label = "global_compass_118";          arity = 4; tags = ["async"]; since = "1.5.2"; weight = 1965 };
  { key = "elytra.cost.scoped_0119";                     label = "local_scoreboard_119";        arity = 0; tags = ["sync"]; since = "1.8.3"; weight = 1754 };
  { key = "effect.cost.strict_0120";                     label = "global_villager_120";         arity = 6; tags = ["registry"]; since = "1.4.0"; weight = 1707 };
  { key = "conduit.cost.fallback_0121";                  label = "loose_spawner_121";           arity = 2; tags = ["experimental"; "async"; "lower"]; since = "1.9.0"; weight = 1801 };
  { key = "grindstone.cost.fallback_0122";               label = "canonical_team_122";          arity = 1; tags = ["lower"; "packet"]; since = "1.3.1"; weight = 1212 };
  { key = "anvil.cost.lazy_0123";                        label = "loose_bell_123";              arity = 1; tags = ["sync"; "compat"; "typed"]; since = "1.7.0"; weight = 1187 };
  { key = "barrel.cost.strict_0124";                     label = "lazy_campfire_124";           arity = 6; tags = ["parse"]; since = "1.7.0"; weight = 3069 };
  { key = "tablist.cost.eager_0125";                     label = "strict_world_125";            arity = 6; tags = ["legacy"; "parse"; "check"]; since = "1.8.3"; weight = 2954 };
  { key = "slot.cost.local_0126";                        label = "primary_bossbar_126";         arity = 1; tags = ["typed"; "cold"; "lower"]; since = "1.8.3"; weight = 3135 };
  { key = "grindstone.cost.loose_0127";                  label = "modern_clock_127";            arity = 4; tags = ["registry"; "parse"; "sync"]; since = "1.8.3"; weight = 2473 };
  { key = "firework.cost.eager_0128";                    label = "lazy_advancement_128";        arity = 3; tags = ["sync"; "hot"; "experimental"]; since = "1.6.0"; weight = 2094 };
  { key = "dispenser.cost.stable_0129";                  label = "public_sound_129";            arity = 5; tags = ["packet"; "experimental"; "compat"]; since = "1.7.0"; weight = 3740 };
  { key = "region.cost.fallback_0130";                   label = "scoped_smoker_130";           arity = 7; tags = ["cached"; "compat"; "cold"]; since = "1.3.1"; weight = 1451 };
  { key = "trade.cost.local_0131";                       label = "secondary_tablist_131";       arity = 2; tags = ["sync"; "parse"]; since = "1.2.0"; weight = 3615 };
  { key = "mob.cost.strict_0132";                        label = "stable_bossbar_132";          arity = 5; tags = ["typed"]; since = "1.6.0"; weight = 3407 };
  { key = "objective.cost.fallback_0133";                label = "modern_objective_133";        arity = 1; tags = ["lower"]; since = "1.6.0"; weight = 1365 };
  { key = "map.cost.fallback_0134";                      label = "canonical_villager_134";      arity = 2; tags = ["packet"; "async"; "typed"]; since = "1.0.0"; weight = 720 };
  { key = "smithing.cost.strict_0135";                   label = "cached_pane_135";             arity = 2; tags = ["legacy"]; since = "1.0.0"; weight = 482 };
  { key = "structure.cost.public_0136";                  label = "loose_conduit_136";           arity = 0; tags = ["untyped"]; since = "1.7.0"; weight = 3789 };
  { key = "stonecutter.cost.lazy_0137";                  label = "stable_attribute_137";        arity = 5; tags = ["compat"; "legacy"]; since = "1.6.0"; weight = 1172 };
  { key = "observer.cost.fallback_0138";                 label = "primary_gui_138";             arity = 6; tags = ["typed"; "hot"; "async"]; since = "1.3.1"; weight = 3521 };
  { key = "target.cost.primary_0139";                    label = "hidden_target_139";           arity = 0; tags = ["sync"; "cold"]; since = "1.7.0"; weight = 2174 };
  { key = "beacon.cost.stable_0140";                     label = "strict_biome_140";            arity = 6; tags = ["async"; "codegen"]; since = "1.3.1"; weight = 69 };
  { key = "bossbar.cost.modern_0141";                    label = "loose_campfire_141";          arity = 3; tags = ["experimental"; "sync"]; since = "1.0.0"; weight = 3206 };
  { key = "conduit.cost.strict_0142";                    label = "hidden_beacon_142";           arity = 2; tags = ["packet"]; since = "1.6.0"; weight = 422 };
  { key = "minecart.cost.provisional_0143";              label = "public_compass_143";          arity = 4; tags = ["codegen"; "experimental"; "core"]; since = "1.8.3"; weight = 555 };
  { key = "npc.cost.scoped_0144";                        label = "cached_trident_144";          arity = 2; tags = ["experimental"; "typed"]; since = "1.7.0"; weight = 3982 };
  { key = "particle.cost.canonical_0145";                label = "fallback_loom_145";           arity = 5; tags = ["runtime"; "registry"]; since = "1.0.0"; weight = 2867 };
  { key = "boat.cost.canonical_0146";                    label = "cached_furnace_146";          arity = 1; tags = ["content"; "packet"; "cached"]; since = "1.5.2"; weight = 910 };
  { key = "pane.cost.hidden_0147";                       label = "eager_team_147";              arity = 1; tags = ["packet"; "sync"]; since = "1.8.3"; weight = 986 };
  { key = "objective.cost.secondary_0148";               label = "internal_scoreboard_148";     arity = 7; tags = ["async"]; since = "1.3.1"; weight = 715 };
  { key = "advancement.cost.local_0149";                 label = "legacy_inventory_149";        arity = 6; tags = ["untyped"; "parse"; "core"]; since = "1.9.0"; weight = 2071 };
  { key = "shield.cost.primary_0150";                    label = "scoped_bossbar_150";          arity = 6; tags = ["async"]; since = "1.5.2"; weight = 1767 };
  { key = "lectern.cost.loose_0151";                     label = "strict_map_151";              arity = 5; tags = ["untyped"; "content"; "compat"]; since = "1.5.2"; weight = 1438 };
  { key = "inventory.cost.provisional_0152";             label = "internal_sound_152";          arity = 5; tags = ["sync"; "async"]; since = "1.5.2"; weight = 1663 };
  { key = "trade.cost.derived_0153";                     label = "local_trident_153";           arity = 0; tags = ["parse"]; since = "1.5.2"; weight = 1588 };
  { key = "shield.cost.public_0154";                     label = "modern_boat_154";             arity = 1; tags = ["async"]; since = "1.2.0"; weight = 3289 };
  { key = "attribute.cost.stable_0155";                  label = "canonical_world_155";         arity = 3; tags = ["cached"]; since = "1.8.3"; weight = 3033 };
  { key = "mob.cost.cached_0156";                        label = "global_beacon_156";           arity = 3; tags = ["runtime"]; since = "1.4.0"; weight = 2376 };
  { key = "banner_pattern.cost.strict_0157";             label = "lazy_clock_157";              arity = 5; tags = ["hot"]; since = "1.3.1"; weight = 1159 };
  { key = "observer.cost.public_0158";                   label = "secondary_conduit_158";       arity = 3; tags = ["legacy"; "codegen"]; since = "1.6.0"; weight = 798 };
  { key = "shield.cost.public_0159";                     label = "internal_rail_159";           arity = 0; tags = ["content"; "lower"; "sync"]; since = "1.7.0"; weight = 2625 };
  { key = "stonecutter.cost.legacy_0160";                label = "fallback_attribute_160";      arity = 7; tags = ["check"; "hot"; "async"]; since = "1.7.0"; weight = 1379 };
  { key = "composter.cost.hidden_0161";                  label = "cached_shield_161";           arity = 7; tags = ["check"]; since = "1.4.0"; weight = 3247 };
  { key = "npc.cost.legacy_0162";                        label = "lazy_anvil_162";              arity = 3; tags = ["typed"; "core"; "emit"]; since = "1.0.0"; weight = 2510 };
  { key = "minecart.cost.internal_0163";                 label = "primary_gui_163";             arity = 3; tags = ["sync"; "lower"; "core"]; since = "1.2.0"; weight = 1752 };
  { key = "conduit.cost.scoped_0164";                    label = "eager_chunk_164";             arity = 5; tags = ["registry"; "parse"; "check"]; since = "1.0.0"; weight = 3864 };
  { key = "slot.cost.lazy_0165";                         label = "local_entity_165";            arity = 5; tags = ["content"]; since = "1.2.0"; weight = 1256 };
  { key = "rail.cost.eager_0166";                        label = "secondary_repeater_166";      arity = 7; tags = ["packet"; "lower"; "emit"]; since = "1.9.0"; weight = 431 };
  { key = "player.cost.provisional_0167";                label = "stable_smithing_167";         arity = 1; tags = ["cold"; "content"]; since = "1.2.0"; weight = 463 };
  { key = "crossbow.cost.local_0168";                    label = "strict_slot_168";             arity = 5; tags = ["legacy"; "packet"; "untyped"]; since = "1.3.1"; weight = 3212 };
  { key = "particle.cost.scoped_0169";                   label = "hidden_firework_169";         arity = 5; tags = ["codegen"]; since = "1.2.0"; weight = 1460 };
  { key = "pane.cost.cached_0170";                       label = "eager_conduit_170";           arity = 4; tags = ["legacy"; "compat"; "cold"]; since = "1.7.0"; weight = 1537 };
  { key = "portal.cost.internal_0171";                   label = "strict_piston_171";           arity = 1; tags = ["cached"; "untyped"; "parse"]; since = "1.2.0"; weight = 2391 };
  { key = "firework.cost.primary_0172";                  label = "canonical_elytra_172";        arity = 1; tags = ["typed"]; since = "1.2.0"; weight = 925 };
  { key = "hopper.cost.scoped_0173";                     label = "canonical_shulker_173";       arity = 4; tags = ["emit"; "runtime"; "hot"]; since = "1.9.0"; weight = 198 };
  { key = "inventory.cost.loose_0174";                   label = "cached_hologram_174";         arity = 6; tags = ["content"]; since = "1.8.3"; weight = 2621 };
  { key = "npc.cost.public_0175";                        label = "eager_hopper_175";            arity = 5; tags = ["sync"; "legacy"; "packet"]; since = "1.5.2"; weight = 4001 };
  { key = "stonecutter.cost.legacy_0176";                label = "hidden_map_176";              arity = 2; tags = ["hot"; "codegen"]; since = "1.6.0"; weight = 2185 };
  { key = "advancement.cost.derived_0177";               label = "secondary_block_177";         arity = 1; tags = ["legacy"; "cold"; "experimental"]; since = "1.0.0"; weight = 1144 };
  { key = "composter.cost.stable_0178";                  label = "stable_piston_178";           arity = 7; tags = ["lower"; "registry"]; since = "1.6.0"; weight = 4074 };
  { key = "slot.cost.hidden_0179";                       label = "strict_banner_179";           arity = 6; tags = ["cold"; "content"]; since = "1.5.2"; weight = 3531 };
  { key = "tablist.cost.secondary_0180";                 label = "canonical_elytra_180";        arity = 6; tags = ["async"; "cold"]; since = "1.8.3"; weight = 814 };
  { key = "shulker.cost.loose_0181";                     label = "loose_structure_181";         arity = 7; tags = ["parse"]; since = "1.4.0"; weight = 2492 };
  { key = "slot.cost.local_0182";                        label = "primary_portal_182";          arity = 0; tags = ["legacy"; "experimental"; "untyped"]; since = "1.2.0"; weight = 3234 };
  { key = "bossbar.cost.cached_0183";                    label = "cached_enchant_183";          arity = 2; tags = ["experimental"; "check"; "typed"]; since = "1.2.0"; weight = 1182 };
  { key = "recipe.cost.eager_0184";                      label = "canonical_mob_184";           arity = 7; tags = ["experimental"; "async"]; since = "1.8.3"; weight = 2240 };
  { key = "banner.cost.strict_0185";                     label = "public_smoker_185";           arity = 2; tags = ["lower"]; since = "1.9.0"; weight = 4008 };
  { key = "packet.cost.derived_0186";                    label = "strict_grindstone_186";       arity = 1; tags = ["lower"]; since = "1.0.0"; weight = 3963 };
  { key = "pane.cost.modern_0187";                       label = "modern_shield_187";           arity = 3; tags = ["parse"]; since = "1.4.0"; weight = 3376 };
  { key = "shield.cost.eager_0188";                      label = "cached_particle_188";         arity = 3; tags = ["typed"; "experimental"]; since = "1.2.0"; weight = 4006 };
  { key = "mob.cost.hidden_0189";                        label = "cached_brewing_189";          arity = 0; tags = ["emit"; "sync"; "core"]; since = "1.8.3"; weight = 1076 };
  { key = "bossbar.cost.local_0190";                     label = "fallback_chunk_190";          arity = 0; tags = ["lower"; "cached"]; since = "1.4.0"; weight = 2441 };
  { key = "packet.cost.cached_0191";                     label = "legacy_banner_191";           arity = 0; tags = ["cached"]; since = "1.5.2"; weight = 174 };
  { key = "stonecutter.cost.legacy_0192";                label = "internal_compass_192";        arity = 1; tags = ["compat"; "untyped"]; since = "1.0.0"; weight = 2626 };
  { key = "item.cost.canonical_0193";                    label = "secondary_portal_193";        arity = 4; tags = ["registry"]; since = "1.3.1"; weight = 3695 };
  { key = "pane.cost.legacy_0194";                       label = "loose_stonecutter_194";       arity = 4; tags = ["check"; "parse"; "packet"]; since = "1.4.0"; weight = 239 };
  { key = "smoker.cost.primary_0195";                    label = "eager_bundle_195";            arity = 1; tags = ["compat"; "content"; "hot"]; since = "1.9.0"; weight = 3429 };
  { key = "arrow.cost.strict_0196";                      label = "strict_effect_196";           arity = 6; tags = ["experimental"; "legacy"; "cold"]; since = "1.9.0"; weight = 1984 };
  { key = "spawner.cost.lazy_0197";                      label = "lazy_map_197";                arity = 0; tags = ["registry"]; since = "1.3.1"; weight = 1200 };
  { key = "loom.cost.derived_0198";                      label = "fallback_hopper_198";         arity = 6; tags = ["compat"; "codegen"; "hot"]; since = "1.8.3"; weight = 2886 };
  { key = "minecart.cost.lazy_0199";                     label = "legacy_minecart_199";         arity = 0; tags = ["async"; "lower"; "codegen"]; since = "1.8.3"; weight = 688 };
  { key = "smithing.cost.strict_0200";                   label = "stable_comparator_200";       arity = 5; tags = ["cold"]; since = "1.7.0"; weight = 205 };
  { key = "effect.cost.internal_0201";                   label = "cached_conduit_201";          arity = 7; tags = ["emit"; "parse"]; since = "1.3.1"; weight = 710 };
  { key = "player.cost.scoped_0202";                     label = "hidden_shulker_202";          arity = 7; tags = ["compat"]; since = "1.5.2"; weight = 27 };
  { key = "trident.cost.lazy_0203";                      label = "derived_boat_203";            arity = 6; tags = ["cold"; "sync"; "hot"]; since = "1.9.0"; weight = 1876 };
  { key = "villager.cost.strict_0204";                   label = "stable_rail_204";             arity = 2; tags = ["emit"]; since = "1.0.0"; weight = 1513 };
  { key = "rail.cost.lazy_0205";                         label = "primary_stonecutter_205";     arity = 1; tags = ["async"; "codegen"; "packet"]; since = "1.6.0"; weight = 739 };
  { key = "team.cost.secondary_0206";                    label = "strict_portal_206";           arity = 5; tags = ["content"; "typed"]; since = "1.6.0"; weight = 2941 };
  { key = "smoker.cost.loose_0207";                      label = "modern_stonecutter_207";      arity = 5; tags = ["cold"; "check"; "lower"]; since = "1.2.0"; weight = 587 };
  { key = "cartography.cost.lazy_0208";                  label = "legacy_enchant_208";          arity = 7; tags = ["experimental"; "typed"; "codegen"]; since = "1.2.0"; weight = 983 };
  { key = "hopper.cost.canonical_0209";                  label = "canonical_bundle_209";        arity = 4; tags = ["registry"]; since = "1.3.1"; weight = 2366 };
  { key = "biome.cost.primary_0210";                     label = "public_conduit_210";          arity = 5; tags = ["check"; "registry"]; since = "1.7.0"; weight = 2553 };
  { key = "barrel.cost.strict_0211";                     label = "canonical_bossbar_211";       arity = 4; tags = ["registry"; "cold"; "parse"]; since = "1.0.0"; weight = 3275 };
  { key = "structure.cost.canonical_0212";               label = "secondary_sound_212";         arity = 3; tags = ["check"; "content"]; since = "1.4.0"; weight = 2646 };
  { key = "repeater.cost.internal_0213";                 label = "loose_biome_213";             arity = 2; tags = ["runtime"; "sync"; "hot"]; since = "1.2.0"; weight = 3797 };
  { key = "world.cost.strict_0214";                      label = "primary_beacon_214";          arity = 2; tags = ["codegen"; "core"; "parse"]; since = "1.2.0"; weight = 2390 };
  { key = "furnace.cost.strict_0215";                    label = "local_campfire_215";          arity = 7; tags = ["compat"; "lower"]; since = "1.7.0"; weight = 788 };
  { key = "elytra.cost.cached_0216";                     label = "scoped_furnace_216";          arity = 5; tags = ["legacy"]; since = "1.4.0"; weight = 2873 };
  { key = "clock.cost.scoped_0217";                      label = "derived_hologram_217";        arity = 1; tags = ["experimental"; "packet"]; since = "1.2.0"; weight = 3666 };
  { key = "chunk.cost.canonical_0218";                   label = "stable_banner_pattern_218";   arity = 4; tags = ["registry"; "hot"; "parse"]; since = "1.4.0"; weight = 75 };
  { key = "piston.cost.provisional_0219";                label = "stable_mob_219";              arity = 4; tags = ["sync"; "check"]; since = "1.3.1"; weight = 1034 };
  { key = "packet.cost.primary_0220";                    label = "hidden_banner_220";           arity = 0; tags = ["typed"; "cold"; "sync"]; since = "1.2.0"; weight = 4028 };
  { key = "boat.cost.local_0221";                        label = "legacy_bell_221";             arity = 5; tags = ["untyped"]; since = "1.3.1"; weight = 2666 };
  { key = "bundle.cost.global_0222";                     label = "loose_team_222";              arity = 5; tags = ["runtime"]; since = "1.8.3"; weight = 3804 };
  { key = "item.cost.scoped_0223";                       label = "provisional_piston_223";      arity = 3; tags = ["check"; "lower"]; since = "1.0.0"; weight = 3318 };
  { key = "player.cost.cached_0224";                     label = "canonical_dispenser_224";     arity = 4; tags = ["cached"; "parse"]; since = "1.3.1"; weight = 2354 };
  { key = "slot.cost.legacy_0225";                       label = "internal_biome_225";          arity = 6; tags = ["typed"]; since = "1.9.0"; weight = 3185 };
  { key = "entity.cost.local_0226";                      label = "derived_elytra_226";          arity = 2; tags = ["experimental"; "compat"; "codegen"]; since = "1.7.0"; weight = 855 };
  { key = "attribute.cost.stable_0227";                  label = "lazy_clock_227";              arity = 5; tags = ["lower"; "sync"; "packet"]; since = "1.6.0"; weight = 2406 };
  { key = "region.cost.provisional_0228";                label = "modern_hologram_228";         arity = 7; tags = ["emit"; "lower"]; since = "1.6.0"; weight = 2158 };
  { key = "particle.cost.public_0229";                   label = "canonical_minecart_229";      arity = 2; tags = ["typed"; "content"; "hot"]; since = "1.0.0"; weight = 3259 };
  { key = "grindstone.cost.public_0230";                 label = "global_crossbow_230";         arity = 3; tags = ["sync"]; since = "1.4.0"; weight = 1783 };
  { key = "slot.cost.eager_0231";                        label = "legacy_spawner_231";          arity = 1; tags = ["runtime"]; since = "1.3.1"; weight = 1251 };
  { key = "anvil.cost.hidden_0232";                      label = "stable_recipe_232";           arity = 2; tags = ["async"; "runtime"]; since = "1.0.0"; weight = 2611 };
  { key = "pane.cost.local_0233";                        label = "modern_bossbar_233";          arity = 0; tags = ["lower"; "codegen"]; since = "1.6.0"; weight = 2518 };
  { key = "recipe.cost.loose_0234";                      label = "local_trade_234";             arity = 5; tags = ["registry"]; since = "1.8.3"; weight = 3680 };
  { key = "villager.cost.canonical_0235";                label = "global_dispenser_235";        arity = 7; tags = ["packet"]; since = "1.8.3"; weight = 3211 };
  { key = "item.cost.primary_0236";                      label = "global_packet_236";           arity = 2; tags = ["emit"; "experimental"; "async"]; since = "1.2.0"; weight = 1952 };
  { key = "boat.cost.primary_0237";                      label = "public_chunk_237";            arity = 4; tags = ["untyped"; "codegen"; "hot"]; since = "1.7.0"; weight = 597 };
  { key = "effect.cost.internal_0238";                   label = "primary_anvil_238";           arity = 3; tags = ["compat"]; since = "1.5.2"; weight = 1823 };
  { key = "crossbow.cost.primary_0239";                  label = "global_trident_239";          arity = 0; tags = ["packet"; "lower"]; since = "1.4.0"; weight = 313 };
  { key = "clock.cost.strict_0240";                      label = "derived_arrow_240";           arity = 4; tags = ["core"; "legacy"; "cached"]; since = "1.8.3"; weight = 840 };
  { key = "advancement.cost.primary_0241";               label = "hidden_banner_pattern_241";   arity = 2; tags = ["sync"; "parse"]; since = "1.0.0"; weight = 2347 };
  { key = "smoker.cost.internal_0242";                   label = "local_observer_242";          arity = 1; tags = ["cold"; "async"; "check"]; since = "1.6.0"; weight = 1358 };
  { key = "item.cost.loose_0243";                        label = "canonical_team_243";          arity = 2; tags = ["runtime"]; since = "1.2.0"; weight = 2616 };
  { key = "banner.cost.canonical_0244";                  label = "fallback_region_244";         arity = 6; tags = ["async"]; since = "1.9.0"; weight = 1657 };
  { key = "map.cost.stable_0245";                        label = "legacy_packet_245";           arity = 2; tags = ["sync"; "codegen"]; since = "1.7.0"; weight = 2353 };
  { key = "region.cost.provisional_0246";                label = "derived_sound_246";           arity = 1; tags = ["sync"]; since = "1.4.0"; weight = 3221 };
  { key = "advancement.cost.scoped_0247";                label = "legacy_dispenser_247";        arity = 6; tags = ["sync"]; since = "1.4.0"; weight = 2441 };
  { key = "barrel.cost.loose_0248";                      label = "loose_biome_248";             arity = 0; tags = ["typed"; "lower"]; since = "1.8.3"; weight = 3117 };
  { key = "objective.cost.legacy_0249";                  label = "canonical_hopper_249";        arity = 1; tags = ["legacy"]; since = "1.5.2"; weight = 2629 };
  { key = "piston.cost.lazy_0250";                       label = "lazy_minecart_250";           arity = 1; tags = ["experimental"; "packet"]; since = "1.3.1"; weight = 2578 };
  { key = "chunk.cost.legacy_0251";                      label = "fallback_entity_251";         arity = 0; tags = ["cached"; "untyped"; "legacy"]; since = "1.7.0"; weight = 2191 };
  { key = "firework.cost.scoped_0252";                   label = "provisional_villager_252";    arity = 2; tags = ["cold"; "typed"; "async"]; since = "1.2.0"; weight = 1308 };
  { key = "scoreboard.cost.global_0253";                 label = "hidden_banner_253";           arity = 4; tags = ["legacy"]; since = "1.5.2"; weight = 2821 };
  { key = "biome.cost.secondary_0254";                   label = "local_hopper_254";            arity = 0; tags = ["codegen"; "legacy"]; since = "1.0.0"; weight = 2177 };
  { key = "conduit.cost.primary_0255";                   label = "public_composter_255";        arity = 4; tags = ["codegen"]; since = "1.5.2"; weight = 164 };
  { key = "anvil.cost.secondary_0256";                   label = "scoped_slot_256";             arity = 3; tags = ["lower"; "check"; "registry"]; since = "1.8.3"; weight = 3636 };
  { key = "entity.cost.scoped_0257";                     label = "cached_particle_257";         arity = 3; tags = ["runtime"; "experimental"]; since = "1.9.0"; weight = 3461 };
  { key = "elytra.cost.canonical_0258";                  label = "primary_minecart_258";        arity = 6; tags = ["check"]; since = "1.0.0"; weight = 429 };
  { key = "clock.cost.primary_0259";                     label = "modern_lectern_259";          arity = 2; tags = ["codegen"; "untyped"]; since = "1.3.1"; weight = 3938 };
  { key = "minecart.cost.loose_0260";                    label = "secondary_repeater_260";      arity = 6; tags = ["sync"]; since = "1.4.0"; weight = 3282 };
  { key = "smoker.cost.public_0261";                     label = "legacy_trade_261";            arity = 1; tags = ["async"]; since = "1.5.2"; weight = 2826 };
  { key = "shield.cost.lazy_0262";                       label = "hidden_hologram_262";         arity = 4; tags = ["typed"; "registry"]; since = "1.0.0"; weight = 3489 };
  { key = "scoreboard.cost.provisional_0263";            label = "legacy_villager_263";         arity = 4; tags = ["runtime"; "parse"; "compat"]; since = "1.4.0"; weight = 2511 };
  { key = "sound.cost.modern_0264";                      label = "stable_recipe_264";           arity = 4; tags = ["async"; "core"; "untyped"]; since = "1.0.0"; weight = 3909 };
  { key = "smoker.cost.legacy_0265";                     label = "primary_inventory_265";       arity = 4; tags = ["hot"; "compat"; "lower"]; since = "1.4.0"; weight = 1231 };
  { key = "smithing.cost.stable_0266";                   label = "hidden_inventory_266";        arity = 2; tags = ["registry"; "compat"]; since = "1.4.0"; weight = 2475 };
  { key = "objective.cost.hidden_0267";                  label = "hidden_barrel_267";           arity = 3; tags = ["packet"; "registry"; "compat"]; since = "1.7.0"; weight = 479 };
  { key = "rail.cost.loose_0268";                        label = "modern_gui_268";              arity = 3; tags = ["check"]; since = "1.0.0"; weight = 938 };
  { key = "entity.cost.loose_0269";                      label = "scoped_minecart_269";         arity = 2; tags = ["hot"]; since = "1.2.0"; weight = 2981 };
  { key = "minecart.cost.scoped_0270";                   label = "strict_smithing_270";         arity = 6; tags = ["runtime"; "lower"; "cold"]; since = "1.9.0"; weight = 504 };
  { key = "campfire.cost.strict_0271";                   label = "scoped_objective_271";        arity = 1; tags = ["packet"; "cached"; "parse"]; since = "1.6.0"; weight = 1448 };
  { key = "stonecutter.cost.strict_0272";                label = "modern_entity_272";           arity = 3; tags = ["parse"; "content"]; since = "1.6.0"; weight = 3898 };
  { key = "biome.cost.eager_0273";                       label = "canonical_chunk_273";         arity = 1; tags = ["hot"]; since = "1.2.0"; weight = 114 };
  { key = "shulker.cost.stable_0274";                    label = "hidden_trade_274";            arity = 0; tags = ["sync"; "packet"; "core"]; since = "1.2.0"; weight = 3127 };
  { key = "hologram.cost.strict_0275";                   label = "loose_slot_275";              arity = 0; tags = ["runtime"; "typed"]; since = "1.5.2"; weight = 1155 };
  { key = "villager.cost.public_0276";                   label = "derived_crossbow_276";        arity = 5; tags = ["hot"; "untyped"; "cached"]; since = "1.6.0"; weight = 1031 };
  { key = "team.cost.modern_0277";                       label = "canonical_dispenser_277";     arity = 0; tags = ["registry"; "codegen"; "legacy"]; since = "1.8.3"; weight = 1670 };
  { key = "team.cost.strict_0278";                       label = "fallback_attribute_278";      arity = 3; tags = ["typed"; "runtime"; "cold"]; since = "1.0.0"; weight = 2017 };
  { key = "cartography.cost.global_0279";                label = "canonical_scoreboard_279";    arity = 1; tags = ["compat"]; since = "1.9.0"; weight = 1187 };
  { key = "firework.cost.scoped_0280";                   label = "global_npc_280";              arity = 1; tags = ["runtime"; "compat"; "sync"]; since = "1.7.0"; weight = 2102 };
  { key = "advancement.cost.global_0281";                label = "provisional_stonecutter_281"; arity = 4; tags = ["cold"; "runtime"; "async"]; since = "1.9.0"; weight = 1274 };
  { key = "attribute.cost.loose_0282";                   label = "public_region_282";           arity = 7; tags = ["untyped"; "content"; "legacy"]; since = "1.9.0"; weight = 1502 };
  { key = "enchant.cost.eager_0283";                     label = "canonical_tablist_283";       arity = 4; tags = ["core"; "legacy"]; since = "1.6.0"; weight = 1676 };
  { key = "shield.cost.legacy_0284";                     label = "scoped_barrel_284";           arity = 7; tags = ["typed"; "packet"]; since = "1.7.0"; weight = 2371 };
  { key = "trade.cost.loose_0285";                       label = "legacy_compass_285";          arity = 7; tags = ["parse"; "content"; "async"]; since = "1.0.0"; weight = 1054 };
  { key = "piston.cost.hidden_0286";                     label = "derived_effect_286";          arity = 3; tags = ["codegen"; "legacy"]; since = "1.9.0"; weight = 2088 };
  { key = "tablist.cost.fallback_0287";                  label = "loose_attribute_287";         arity = 2; tags = ["parse"; "untyped"]; since = "1.5.2"; weight = 573 };
  { key = "crossbow.cost.secondary_0288";                label = "primary_observer_288";        arity = 1; tags = ["codegen"]; since = "1.4.0"; weight = 3800 };
  { key = "shulker.cost.internal_0289";                  label = "derived_particle_289";        arity = 4; tags = ["experimental"]; since = "1.8.3"; weight = 337 };
  { key = "trident.cost.canonical_0290";                 label = "provisional_barrel_290";      arity = 2; tags = ["sync"]; since = "1.6.0"; weight = 3092 };
  { key = "gui.cost.stable_0291";                        label = "local_trident_291";           arity = 1; tags = ["content"; "registry"]; since = "1.2.0"; weight = 1042 };
  { key = "attribute.cost.secondary_0292";               label = "secondary_inventory_292";     arity = 0; tags = ["hot"; "async"; "parse"]; since = "1.7.0"; weight = 149 };
  { key = "target.cost.strict_0293";                     label = "hidden_conduit_293";          arity = 2; tags = ["check"; "compat"; "cold"]; since = "1.9.0"; weight = 4022 };
  { key = "enchant.cost.stable_0294";                    label = "local_repeater_294";          arity = 1; tags = ["packet"]; since = "1.6.0"; weight = 48 };
  { key = "effect.cost.hidden_0295";                     label = "strict_clock_295";            arity = 5; tags = ["parse"]; since = "1.7.0"; weight = 3362 };
  { key = "sound.cost.stable_0296";                      label = "modern_sound_296";            arity = 3; tags = ["check"; "cold"]; since = "1.9.0"; weight = 2305 };
  { key = "target.cost.scoped_0297";                     label = "stable_hologram_297";         arity = 2; tags = ["untyped"]; since = "1.9.0"; weight = 383 };
  { key = "bell.cost.canonical_0298";                    label = "public_comparator_298";       arity = 1; tags = ["hot"]; since = "1.6.0"; weight = 159 };
  { key = "gui.cost.loose_0299";                         label = "internal_chunk_299";          arity = 4; tags = ["sync"; "lower"]; since = "1.2.0"; weight = 3107 };
  { key = "loom.cost.cached_0300";                       label = "derived_entity_300";          arity = 2; tags = ["core"; "packet"]; since = "1.2.0"; weight = 2563 };
  { key = "bell.cost.loose_0301";                        label = "fallback_clock_301";          arity = 2; tags = ["registry"; "check"]; since = "1.6.0"; weight = 1786 };
  { key = "shulker.cost.public_0302";                    label = "public_piston_302";           arity = 5; tags = ["cached"]; since = "1.0.0"; weight = 3368 };
  { key = "arrow.cost.derived_0303";                     label = "strict_campfire_303";         arity = 4; tags = ["codegen"; "cold"; "parse"]; since = "1.4.0"; weight = 1781 };
  { key = "shulker.cost.eager_0304";                     label = "lazy_composter_304";          arity = 1; tags = ["emit"; "packet"; "cold"]; since = "1.3.1"; weight = 1724 };
  { key = "anvil.cost.stable_0305";                      label = "fallback_npc_305";            arity = 4; tags = ["cached"]; since = "1.0.0"; weight = 2640 };
  { key = "potion.cost.modern_0306";                     label = "cached_hopper_306";           arity = 5; tags = ["experimental"; "codegen"; "compat"]; since = "1.4.0"; weight = 3837 };
  { key = "pane.cost.scoped_0307";                       label = "lazy_anvil_307";              arity = 6; tags = ["async"; "compat"; "cached"]; since = "1.0.0"; weight = 2365 };
  { key = "attribute.cost.canonical_0308";               label = "primary_biome_308";           arity = 6; tags = ["lower"; "codegen"; "cold"]; since = "1.8.3"; weight = 3575 };
  { key = "trade.cost.local_0309";                       label = "cached_minecart_309";         arity = 3; tags = ["core"; "untyped"; "typed"]; since = "1.9.0"; weight = 705 };
]

let count = List.length entries

let table : (string, cost_entry) Hashtbl.t =
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
