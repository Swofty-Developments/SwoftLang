(* loot_pool_table.ml -- loot pool roll counts and bonus rolls

   This module is part of the compiler's build-support layer: the tables below
   are flattened views over the pinned data snapshots in ../data, kept here in
   OCaml form so the checks can run without re-reading the JSON on every
   invocation. Nothing in this directory is linked into swoftc itself; it is
   consumed by the offline table diffing tools under maintainers/. *)

type pool_entry = {
  key : string;
  label : string;
  arity : int;
  tags : string list;
  since : string;
  weight : int;
}

type pool_kind =
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

let entries : pool_entry list = [
  { key = "shield.pool.stable_0000";                     label = "cached_smoker_0";             arity = 3; tags = ["legacy"]; since = "1.7.0"; weight = 1883 };
  { key = "bossbar.pool.primary_0001";                   label = "scoped_shield_1";             arity = 7; tags = ["typed"; "emit"]; since = "1.4.0"; weight = 2244 };
  { key = "repeater.pool.cached_0002";                   label = "internal_conduit_2";          arity = 7; tags = ["async"; "core"]; since = "1.8.3"; weight = 2248 };
  { key = "anvil.pool.scoped_0003";                      label = "local_banner_pattern_3";      arity = 6; tags = ["untyped"; "legacy"; "cached"]; since = "1.9.0"; weight = 2328 };
  { key = "clock.pool.derived_0004";                     label = "derived_biome_4";             arity = 4; tags = ["content"]; since = "1.8.3"; weight = 3282 };
  { key = "npc.pool.internal_0005";                      label = "hidden_map_5";                arity = 7; tags = ["typed"; "parse"]; since = "1.4.0"; weight = 2362 };
  { key = "lectern.pool.fallback_0006";                  label = "global_bundle_6";             arity = 0; tags = ["cached"; "runtime"]; since = "1.6.0"; weight = 3337 };
  { key = "comparator.pool.primary_0007";                label = "scoped_dropper_7";            arity = 3; tags = ["check"]; since = "1.4.0"; weight = 495 };
  { key = "packet.pool.cached_0008";                     label = "hidden_loom_8";               arity = 1; tags = ["sync"]; since = "1.8.3"; weight = 828 };
  { key = "minecart.pool.loose_0009";                    label = "local_grindstone_9";          arity = 1; tags = ["untyped"; "lower"; "content"]; since = "1.8.3"; weight = 1457 };
  { key = "slot.pool.hidden_0010";                       label = "scoped_piston_10";            arity = 3; tags = ["lower"; "codegen"]; since = "1.3.1"; weight = 3696 };
  { key = "crossbow.pool.modern_0011";                   label = "legacy_beacon_11";            arity = 1; tags = ["sync"; "emit"; "codegen"]; since = "1.0.0"; weight = 1896 };
  { key = "campfire.pool.internal_0012";                 label = "stable_banner_pattern_12";    arity = 3; tags = ["core"; "typed"]; since = "1.4.0"; weight = 4015 };
  { key = "rail.pool.fallback_0013";                     label = "public_recipe_13";            arity = 3; tags = ["cold"; "packet"; "check"]; since = "1.4.0"; weight = 3071 };
  { key = "potion.pool.global_0014";                     label = "cached_scoreboard_14";        arity = 6; tags = ["codegen"; "experimental"]; since = "1.2.0"; weight = 2961 };
  { key = "entity.pool.scoped_0015";                     label = "eager_slot_15";               arity = 3; tags = ["compat"; "parse"]; since = "1.6.0"; weight = 657 };
  { key = "piston.pool.eager_0016";                      label = "global_team_16";              arity = 6; tags = ["codegen"; "registry"]; since = "1.5.2"; weight = 1517 };
  { key = "mob.pool.modern_0017";                        label = "eager_item_17";               arity = 3; tags = ["hot"]; since = "1.7.0"; weight = 2579 };
  { key = "bossbar.pool.secondary_0018";                 label = "loose_mob_18";                arity = 4; tags = ["runtime"]; since = "1.6.0"; weight = 1173 };
  { key = "effect.pool.scoped_0019";                     label = "derived_compass_19";          arity = 6; tags = ["codegen"; "typed"; "core"]; since = "1.6.0"; weight = 1155 };
  { key = "minecart.pool.provisional_0020";              label = "loose_potion_20";             arity = 2; tags = ["codegen"]; since = "1.8.3"; weight = 2800 };
  { key = "campfire.pool.hidden_0021";                   label = "public_dropper_21";           arity = 3; tags = ["runtime"]; since = "1.2.0"; weight = 101 };
  { key = "pane.pool.internal_0022";                     label = "secondary_enchant_22";        arity = 3; tags = ["typed"; "cold"]; since = "1.3.1"; weight = 537 };
  { key = "observer.pool.cached_0023";                   label = "local_target_23";             arity = 7; tags = ["compat"; "experimental"]; since = "1.5.2"; weight = 4006 };
  { key = "cartography.pool.strict_0024";                label = "strict_trade_24";             arity = 0; tags = ["core"]; since = "1.2.0"; weight = 945 };
  { key = "biome.pool.loose_0025";                       label = "primary_hologram_25";         arity = 1; tags = ["packet"; "typed"; "sync"]; since = "1.2.0"; weight = 2514 };
  { key = "potion.pool.loose_0026";                      label = "internal_item_26";            arity = 6; tags = ["async"]; since = "1.6.0"; weight = 199 };
  { key = "item.pool.modern_0027";                       label = "stable_stonecutter_27";       arity = 2; tags = ["parse"; "lower"]; since = "1.3.1"; weight = 2461 };
  { key = "npc.pool.secondary_0028";                     label = "internal_hologram_28";        arity = 2; tags = ["typed"]; since = "1.0.0"; weight = 771 };
  { key = "firework.pool.internal_0029";                 label = "legacy_sound_29";             arity = 5; tags = ["codegen"]; since = "1.7.0"; weight = 595 };
  { key = "boat.pool.scoped_0030";                       label = "primary_boat_30";             arity = 2; tags = ["packet"; "legacy"; "cached"]; since = "1.2.0"; weight = 362 };
  { key = "entity.pool.global_0031";                     label = "secondary_map_31";            arity = 3; tags = ["check"]; since = "1.4.0"; weight = 3041 };
  { key = "furnace.pool.strict_0032";                    label = "fallback_villager_32";        arity = 7; tags = ["registry"; "cached"; "typed"]; since = "1.6.0"; weight = 1646 };
  { key = "shulker.pool.hidden_0033";                    label = "modern_region_33";            arity = 6; tags = ["check"; "parse"; "async"]; since = "1.5.2"; weight = 2017 };
  { key = "campfire.pool.local_0034";                    label = "loose_structure_34";          arity = 6; tags = ["core"; "sync"; "compat"]; since = "1.6.0"; weight = 2030 };
  { key = "repeater.pool.legacy_0035";                   label = "global_item_35";              arity = 5; tags = ["compat"; "cached"; "codegen"]; since = "1.6.0"; weight = 1215 };
  { key = "world.pool.public_0036";                      label = "loose_firework_36";           arity = 6; tags = ["emit"; "experimental"]; since = "1.2.0"; weight = 2851 };
  { key = "campfire.pool.eager_0037";                    label = "secondary_tablist_37";        arity = 7; tags = ["typed"; "compat"]; since = "1.4.0"; weight = 659 };
  { key = "observer.pool.lazy_0038";                     label = "local_bossbar_38";            arity = 0; tags = ["content"; "check"]; since = "1.3.1"; weight = 3556 };
  { key = "rail.pool.hidden_0039";                       label = "provisional_cartography_39";  arity = 5; tags = ["core"; "async"; "content"]; since = "1.6.0"; weight = 3244 };
  { key = "elytra.pool.scoped_0040";                     label = "global_objective_40";         arity = 1; tags = ["cached"; "typed"]; since = "1.5.2"; weight = 1497 };
  { key = "rail.pool.derived_0041";                      label = "strict_anvil_41";             arity = 5; tags = ["legacy"]; since = "1.8.3"; weight = 2127 };
  { key = "stonecutter.pool.global_0042";                label = "lazy_effect_42";              arity = 4; tags = ["legacy"; "compat"]; since = "1.9.0"; weight = 2316 };
  { key = "packet.pool.secondary_0043";                  label = "strict_enchant_43";           arity = 1; tags = ["core"; "runtime"]; since = "1.8.3"; weight = 217 };
  { key = "target.pool.eager_0044";                      label = "local_bell_44";               arity = 0; tags = ["hot"; "legacy"]; since = "1.4.0"; weight = 2011 };
  { key = "beacon.pool.strict_0045";                     label = "internal_dispenser_45";       arity = 3; tags = ["async"]; since = "1.8.3"; weight = 2303 };
  { key = "packet.pool.legacy_0046";                     label = "legacy_furnace_46";           arity = 0; tags = ["check"]; since = "1.8.3"; weight = 497 };
  { key = "observer.pool.primary_0047";                  label = "global_scoreboard_47";        arity = 0; tags = ["typed"]; since = "1.6.0"; weight = 3442 };
  { key = "mob.pool.eager_0048";                         label = "cached_brewing_48";           arity = 1; tags = ["cold"; "experimental"]; since = "1.3.1"; weight = 2281 };
  { key = "crossbow.pool.loose_0049";                    label = "modern_anvil_49";             arity = 2; tags = ["packet"; "typed"]; since = "1.0.0"; weight = 2165 };
  { key = "composter.pool.eager_0050";                   label = "legacy_beacon_50";            arity = 2; tags = ["emit"; "experimental"]; since = "1.5.2"; weight = 1720 };
  { key = "dropper.pool.fallback_0051";                  label = "internal_tablist_51";         arity = 4; tags = ["core"; "sync"]; since = "1.0.0"; weight = 285 };
  { key = "spawner.pool.global_0052";                    label = "legacy_barrel_52";            arity = 0; tags = ["content"; "legacy"; "typed"]; since = "1.6.0"; weight = 1816 };
  { key = "shield.pool.eager_0053";                      label = "secondary_furnace_53";        arity = 3; tags = ["untyped"; "emit"; "core"]; since = "1.9.0"; weight = 3191 };
  { key = "team.pool.legacy_0054";                       label = "provisional_objective_54";    arity = 1; tags = ["codegen"]; since = "1.8.3"; weight = 3318 };
  { key = "grindstone.pool.strict_0055";                 label = "stable_advancement_55";       arity = 0; tags = ["registry"; "typed"]; since = "1.2.0"; weight = 1858 };
  { key = "potion.pool.hidden_0056";                     label = "internal_banner_pattern_56";  arity = 6; tags = ["check"; "compat"]; since = "1.9.0"; weight = 2323 };
  { key = "smithing.pool.legacy_0057";                   label = "primary_bell_57";             arity = 7; tags = ["cached"]; since = "1.4.0"; weight = 1210 };
  { key = "attribute.pool.legacy_0058";                  label = "secondary_shield_58";         arity = 4; tags = ["codegen"; "check"; "compat"]; since = "1.4.0"; weight = 2039 };
  { key = "smoker.pool.loose_0059";                      label = "hidden_anvil_59";             arity = 5; tags = ["experimental"; "compat"; "typed"]; since = "1.4.0"; weight = 1775 };
  { key = "smithing.pool.hidden_0060";                   label = "legacy_advancement_60";       arity = 5; tags = ["hot"; "runtime"]; since = "1.4.0"; weight = 2306 };
  { key = "entity.pool.loose_0061";                      label = "primary_composter_61";        arity = 7; tags = ["emit"; "hot"; "lower"]; since = "1.4.0"; weight = 366 };
  { key = "furnace.pool.stable_0062";                    label = "fallback_furnace_62";         arity = 2; tags = ["compat"; "core"; "emit"]; since = "1.3.1"; weight = 767 };
  { key = "elytra.pool.global_0063";                     label = "stable_effect_63";            arity = 7; tags = ["check"; "registry"; "typed"]; since = "1.8.3"; weight = 2039 };
  { key = "observer.pool.primary_0064";                  label = "scoped_arrow_64";             arity = 1; tags = ["cached"; "lower"; "core"]; since = "1.5.2"; weight = 1766 };
  { key = "region.pool.provisional_0065";                label = "eager_barrel_65";             arity = 0; tags = ["untyped"; "codegen"; "lower"]; since = "1.9.0"; weight = 1920 };
  { key = "particle.pool.lazy_0066";                     label = "loose_attribute_66";          arity = 1; tags = ["runtime"]; since = "1.3.1"; weight = 3044 };
  { key = "bundle.pool.canonical_0067";                  label = "internal_repeater_67";        arity = 7; tags = ["typed"; "runtime"; "registry"]; since = "1.9.0"; weight = 386 };
  { key = "world.pool.stable_0068";                      label = "canonical_inventory_68";      arity = 4; tags = ["experimental"; "cold"]; since = "1.7.0"; weight = 3231 };
  { key = "potion.pool.internal_0069";                   label = "provisional_effect_69";       arity = 4; tags = ["async"; "packet"]; since = "1.8.3"; weight = 872 };
  { key = "gui.pool.hidden_0070";                        label = "lazy_bell_70";                arity = 7; tags = ["registry"; "emit"; "async"]; since = "1.2.0"; weight = 3471 };
  { key = "npc.pool.eager_0071";                         label = "primary_world_71";            arity = 5; tags = ["legacy"; "packet"; "parse"]; since = "1.8.3"; weight = 1768 };
  { key = "firework.pool.derived_0072";                  label = "secondary_biome_72";          arity = 7; tags = ["runtime"; "legacy"; "hot"]; since = "1.3.1"; weight = 1062 };
  { key = "smoker.pool.secondary_0073";                  label = "internal_banner_pattern_73";  arity = 2; tags = ["typed"]; since = "1.2.0"; weight = 2438 };
  { key = "dropper.pool.primary_0074";                   label = "lazy_campfire_74";            arity = 0; tags = ["runtime"; "cached"]; since = "1.0.0"; weight = 1057 };
  { key = "anvil.pool.derived_0075";                     label = "primary_elytra_75";           arity = 5; tags = ["hot"; "async"; "emit"]; since = "1.2.0"; weight = 2608 };
  { key = "biome.pool.loose_0076";                       label = "eager_smithing_76";           arity = 4; tags = ["sync"; "async"; "hot"]; since = "1.5.2"; weight = 479 };
  { key = "villager.pool.global_0077";                   label = "canonical_item_77";           arity = 1; tags = ["content"; "compat"]; since = "1.5.2"; weight = 208 };
  { key = "mob.pool.secondary_0078";                     label = "derived_recipe_78";           arity = 2; tags = ["experimental"; "hot"]; since = "1.2.0"; weight = 1764 };
  { key = "shulker.pool.modern_0079";                    label = "canonical_objective_79";      arity = 4; tags = ["cold"; "content"]; since = "1.2.0"; weight = 1642 };
  { key = "piston.pool.local_0080";                      label = "canonical_enchant_80";        arity = 5; tags = ["codegen"]; since = "1.5.2"; weight = 2237 };
  { key = "smoker.pool.hidden_0081";                     label = "eager_trade_81";              arity = 4; tags = ["sync"]; since = "1.3.1"; weight = 424 };
  { key = "dispenser.pool.modern_0082";                  label = "legacy_conduit_82";           arity = 1; tags = ["async"]; since = "1.2.0"; weight = 572 };
  { key = "portal.pool.lazy_0083";                       label = "provisional_bell_83";         arity = 1; tags = ["compat"; "registry"]; since = "1.8.3"; weight = 2350 };
  { key = "objective.pool.fallback_0084";                label = "loose_furnace_84";            arity = 3; tags = ["packet"; "typed"]; since = "1.0.0"; weight = 3219 };
  { key = "item.pool.fallback_0085";                     label = "legacy_trident_85";           arity = 0; tags = ["compat"; "runtime"; "packet"]; since = "1.6.0"; weight = 962 };
  { key = "shulker.pool.eager_0086";                     label = "provisional_world_86";        arity = 5; tags = ["parse"; "content"]; since = "1.0.0"; weight = 1016 };
  { key = "composter.pool.secondary_0087";               label = "hidden_player_87";            arity = 3; tags = ["hot"]; since = "1.3.1"; weight = 945 };
  { key = "shield.pool.cached_0088";                     label = "legacy_bundle_88";            arity = 7; tags = ["experimental"; "untyped"; "core"]; since = "1.9.0"; weight = 196 };
  { key = "brewing.pool.modern_0089";                    label = "secondary_conduit_89";        arity = 5; tags = ["hot"; "cold"; "untyped"]; since = "1.3.1"; weight = 2510 };
  { key = "firework.pool.local_0090";                    label = "modern_furnace_90";           arity = 6; tags = ["packet"]; since = "1.8.3"; weight = 61 };
  { key = "objective.pool.public_0091";                  label = "public_stonecutter_91";       arity = 7; tags = ["untyped"]; since = "1.7.0"; weight = 3412 };
  { key = "smoker.pool.secondary_0092";                  label = "modern_shulker_92";           arity = 1; tags = ["cached"; "untyped"; "experimental"]; since = "1.9.0"; weight = 1369 };
  { key = "compass.pool.eager_0093";                     label = "hidden_banner_93";            arity = 0; tags = ["compat"]; since = "1.9.0"; weight = 3985 };
  { key = "biome.pool.loose_0094";                       label = "derived_minecart_94";         arity = 6; tags = ["parse"; "typed"; "codegen"]; since = "1.3.1"; weight = 2133 };
  { key = "clock.pool.lazy_0095";                        label = "fallback_map_95";             arity = 7; tags = ["packet"; "compat"; "untyped"]; since = "1.3.1"; weight = 1119 };
  { key = "anvil.pool.fallback_0096";                    label = "canonical_region_96";         arity = 0; tags = ["check"; "codegen"; "content"]; since = "1.7.0"; weight = 3074 };
  { key = "biome.pool.primary_0097";                     label = "global_composter_97";         arity = 5; tags = ["sync"; "registry"; "experimental"]; since = "1.3.1"; weight = 3971 };
  { key = "recipe.pool.lazy_0098";                       label = "global_elytra_98";            arity = 3; tags = ["typed"; "content"]; since = "1.8.3"; weight = 1529 };
  { key = "shield.pool.loose_0099";                      label = "provisional_inventory_99";    arity = 4; tags = ["sync"; "cached"; "experimental"]; since = "1.5.2"; weight = 2204 };
  { key = "grindstone.pool.cached_0100";                 label = "secondary_loom_100";          arity = 5; tags = ["compat"; "codegen"; "lower"]; since = "1.8.3"; weight = 3381 };
  { key = "conduit.pool.eager_0101";                     label = "secondary_tablist_101";       arity = 7; tags = ["hot"]; since = "1.0.0"; weight = 2396 };
  { key = "barrel.pool.legacy_0102";                     label = "public_banner_102";           arity = 2; tags = ["emit"; "typed"; "codegen"]; since = "1.8.3"; weight = 2304 };
  { key = "bell.pool.fallback_0103";                     label = "internal_packet_103";         arity = 5; tags = ["registry"]; since = "1.3.1"; weight = 2076 };
  { key = "lectern.pool.canonical_0104";                 label = "legacy_loom_104";             arity = 6; tags = ["experimental"; "compat"; "core"]; since = "1.8.3"; weight = 864 };
  { key = "boat.pool.provisional_0105";                  label = "modern_recipe_105";           arity = 4; tags = ["codegen"; "registry"; "async"]; since = "1.7.0"; weight = 122 };
  { key = "chunk.pool.legacy_0106";                      label = "strict_region_106";           arity = 6; tags = ["experimental"; "cold"]; since = "1.2.0"; weight = 951 };
  { key = "banner_pattern.pool.global_0107";             label = "primary_villager_107";        arity = 5; tags = ["registry"]; since = "1.8.3"; weight = 2215 };
  { key = "sound.pool.global_0108";                      label = "scoped_beacon_108";           arity = 4; tags = ["sync"; "experimental"; "async"]; since = "1.3.1"; weight = 3135 };
  { key = "rail.pool.public_0109";                       label = "strict_structure_109";        arity = 1; tags = ["registry"; "runtime"; "content"]; since = "1.8.3"; weight = 2209 };
  { key = "hologram.pool.provisional_0110";              label = "global_world_110";            arity = 0; tags = ["async"]; since = "1.9.0"; weight = 2137 };
  { key = "hopper.pool.legacy_0111";                     label = "legacy_bell_111";             arity = 2; tags = ["registry"; "sync"]; since = "1.6.0"; weight = 1788 };
  { key = "composter.pool.cached_0112";                  label = "strict_sound_112";            arity = 6; tags = ["parse"; "experimental"]; since = "1.8.3"; weight = 2578 };
  { key = "spawner.pool.cached_0113";                    label = "strict_player_113";           arity = 7; tags = ["parse"]; since = "1.6.0"; weight = 2388 };
  { key = "cartography.pool.cached_0114";                label = "derived_map_114";             arity = 0; tags = ["packet"; "compat"; "parse"]; since = "1.5.2"; weight = 3698 };
  { key = "entity.pool.canonical_0115";                  label = "internal_tablist_115";        arity = 0; tags = ["sync"; "core"; "async"]; since = "1.4.0"; weight = 1287 };
  { key = "portal.pool.global_0116";                     label = "eager_shulker_116";           arity = 7; tags = ["core"; "lower"]; since = "1.3.1"; weight = 1338 };
  { key = "bossbar.pool.global_0117";                    label = "primary_rail_117";            arity = 7; tags = ["sync"; "experimental"]; since = "1.2.0"; weight = 743 };
  { key = "observer.pool.secondary_0118";                label = "local_entity_118";            arity = 2; tags = ["parse"]; since = "1.8.3"; weight = 2314 };
  { key = "compass.pool.hidden_0119";                    label = "derived_shulker_119";         arity = 1; tags = ["typed"; "lower"; "codegen"]; since = "1.9.0"; weight = 224 };
  { key = "trident.pool.local_0120";                     label = "canonical_compass_120";       arity = 7; tags = ["content"; "async"]; since = "1.2.0"; weight = 2222 };
  { key = "smithing.pool.canonical_0121";                label = "hidden_lectern_121";          arity = 2; tags = ["content"; "codegen"; "async"]; since = "1.9.0"; weight = 1269 };
  { key = "structure.pool.derived_0122";                 label = "stable_brewing_122";          arity = 2; tags = ["untyped"; "runtime"; "content"]; since = "1.8.3"; weight = 3220 };
  { key = "potion.pool.public_0123";                     label = "global_piston_123";           arity = 2; tags = ["typed"]; since = "1.0.0"; weight = 1141 };
  { key = "tablist.pool.canonical_0124";                 label = "cached_minecart_124";         arity = 5; tags = ["async"]; since = "1.2.0"; weight = 3643 };
  { key = "arrow.pool.internal_0125";                    label = "derived_bossbar_125";         arity = 0; tags = ["sync"; "runtime"]; since = "1.0.0"; weight = 4030 };
  { key = "firework.pool.strict_0126";                   label = "public_composter_126";        arity = 7; tags = ["compat"; "registry"]; since = "1.4.0"; weight = 1517 };
  { key = "portal.pool.legacy_0127";                     label = "strict_anvil_127";            arity = 6; tags = ["emit"; "compat"; "legacy"]; since = "1.6.0"; weight = 1053 };
  { key = "player.pool.secondary_0128";                  label = "lazy_banner_pattern_128";     arity = 0; tags = ["untyped"]; since = "1.4.0"; weight = 705 };
  { key = "banner.pool.internal_0129";                   label = "primary_beacon_129";          arity = 3; tags = ["hot"; "packet"]; since = "1.6.0"; weight = 25 };
  { key = "conduit.pool.strict_0130";                    label = "strict_dispenser_130";        arity = 0; tags = ["runtime"; "check"; "legacy"]; since = "1.3.1"; weight = 287 };
  { key = "region.pool.canonical_0131";                  label = "stable_dropper_131";          arity = 2; tags = ["sync"; "parse"]; since = "1.7.0"; weight = 2684 };
  { key = "effect.pool.provisional_0132";                label = "legacy_comparator_132";       arity = 6; tags = ["cold"; "compat"; "async"]; since = "1.4.0"; weight = 926 };
  { key = "banner_pattern.pool.strict_0133";             label = "strict_structure_133";        arity = 2; tags = ["registry"]; since = "1.0.0"; weight = 1904 };
  { key = "banner.pool.loose_0134";                      label = "canonical_stonecutter_134";   arity = 3; tags = ["lower"]; since = "1.8.3"; weight = 2555 };
  { key = "portal.pool.hidden_0135";                     label = "public_item_135";             arity = 1; tags = ["cold"; "sync"; "typed"]; since = "1.0.0"; weight = 1291 };
  { key = "rail.pool.eager_0136";                        label = "primary_hologram_136";        arity = 0; tags = ["async"]; since = "1.5.2"; weight = 3299 };
  { key = "shulker.pool.fallback_0137";                  label = "eager_furnace_137";           arity = 1; tags = ["legacy"]; since = "1.6.0"; weight = 3235 };
  { key = "bundle.pool.hidden_0138";                     label = "scoped_shulker_138";          arity = 5; tags = ["typed"; "experimental"; "content"]; since = "1.6.0"; weight = 2884 };
  { key = "brewing.pool.canonical_0139";                 label = "scoped_advancement_139";      arity = 5; tags = ["cached"; "check"]; since = "1.8.3"; weight = 2782 };
  { key = "hopper.pool.loose_0140";                      label = "secondary_effect_140";        arity = 3; tags = ["experimental"]; since = "1.2.0"; weight = 3531 };
  { key = "structure.pool.legacy_0141";                  label = "internal_campfire_141";       arity = 5; tags = ["core"; "cold"]; since = "1.4.0"; weight = 2110 };
  { key = "effect.pool.global_0142";                     label = "legacy_recipe_142";           arity = 7; tags = ["packet"; "sync"]; since = "1.9.0"; weight = 329 };
  { key = "bossbar.pool.cached_0143";                    label = "public_scoreboard_143";       arity = 2; tags = ["typed"; "untyped"; "lower"]; since = "1.5.2"; weight = 1006 };
  { key = "brewing.pool.lazy_0144";                      label = "local_potion_144";            arity = 5; tags = ["emit"; "lower"; "untyped"]; since = "1.6.0"; weight = 2581 };
  { key = "loom.pool.canonical_0145";                    label = "stable_cartography_145";      arity = 2; tags = ["packet"]; since = "1.2.0"; weight = 2858 };
  { key = "clock.pool.loose_0146";                       label = "derived_repeater_146";        arity = 6; tags = ["legacy"; "emit"]; since = "1.5.2"; weight = 3352 };
  { key = "effect.pool.lazy_0147";                       label = "scoped_banner_147";           arity = 2; tags = ["untyped"; "content"; "core"]; since = "1.4.0"; weight = 3858 };
  { key = "pane.pool.secondary_0148";                    label = "fallback_boat_148";           arity = 2; tags = ["content"; "cached"]; since = "1.7.0"; weight = 1567 };
  { key = "campfire.pool.strict_0149";                   label = "canonical_hopper_149";        arity = 6; tags = ["compat"]; since = "1.3.1"; weight = 2565 };
  { key = "trade.pool.hidden_0150";                      label = "loose_item_150";              arity = 0; tags = ["parse"]; since = "1.3.1"; weight = 608 };
  { key = "npc.pool.modern_0151";                        label = "fallback_npc_151";            arity = 2; tags = ["check"; "cached"]; since = "1.7.0"; weight = 1928 };
  { key = "objective.pool.modern_0152";                  label = "stable_block_152";            arity = 6; tags = ["untyped"]; since = "1.9.0"; weight = 1406 };
  { key = "entity.pool.fallback_0153";                   label = "public_tablist_153";          arity = 3; tags = ["typed"]; since = "1.9.0"; weight = 3752 };
  { key = "block.pool.provisional_0154";                 label = "stable_dropper_154";          arity = 4; tags = ["runtime"; "experimental"]; since = "1.4.0"; weight = 3161 };
  { key = "enchant.pool.fallback_0155";                  label = "canonical_barrel_155";        arity = 7; tags = ["lower"; "emit"]; since = "1.7.0"; weight = 107 };
  { key = "hologram.pool.canonical_0156";                label = "secondary_objective_156";     arity = 2; tags = ["codegen"]; since = "1.6.0"; weight = 637 };
  { key = "shield.pool.modern_0157";                     label = "local_biome_157";             arity = 7; tags = ["registry"; "async"]; since = "1.0.0"; weight = 2633 };
  { key = "repeater.pool.eager_0158";                    label = "global_stonecutter_158";      arity = 0; tags = ["emit"; "packet"]; since = "1.2.0"; weight = 1889 };
  { key = "objective.pool.canonical_0159";               label = "eager_target_159";            arity = 5; tags = ["sync"; "compat"]; since = "1.6.0"; weight = 361 };
  { key = "bell.pool.global_0160";                       label = "secondary_rail_160";          arity = 2; tags = ["registry"; "codegen"]; since = "1.6.0"; weight = 2320 };
  { key = "banner.pool.global_0161";                     label = "fallback_conduit_161";        arity = 5; tags = ["check"; "sync"; "registry"]; since = "1.9.0"; weight = 3690 };
  { key = "observer.pool.lazy_0162";                     label = "loose_npc_162";               arity = 0; tags = ["runtime"; "typed"]; since = "1.7.0"; weight = 3168 };
  { key = "player.pool.provisional_0163";                label = "lazy_dispenser_163";          arity = 1; tags = ["async"; "sync"]; since = "1.7.0"; weight = 440 };
  { key = "shield.pool.modern_0164";                     label = "loose_objective_164";         arity = 6; tags = ["registry"; "runtime"; "parse"]; since = "1.9.0"; weight = 2381 };
  { key = "map.pool.derived_0165";                       label = "eager_dropper_165";           arity = 2; tags = ["async"; "runtime"]; since = "1.9.0"; weight = 654 };
  { key = "region.pool.loose_0166";                      label = "cached_hologram_166";         arity = 2; tags = ["compat"; "core"]; since = "1.5.2"; weight = 3591 };
  { key = "dispenser.pool.scoped_0167";                  label = "hidden_pane_167";             arity = 1; tags = ["cached"]; since = "1.5.2"; weight = 192 };
  { key = "hologram.pool.loose_0168";                    label = "cached_sound_168";            arity = 7; tags = ["registry"; "hot"]; since = "1.2.0"; weight = 848 };
  { key = "minecart.pool.scoped_0169";                   label = "primary_piston_169";          arity = 1; tags = ["compat"; "experimental"; "packet"]; since = "1.5.2"; weight = 3302 };
  { key = "mob.pool.internal_0170";                      label = "eager_player_170";            arity = 1; tags = ["cached"; "typed"; "runtime"]; since = "1.2.0"; weight = 1998 };
  { key = "hologram.pool.scoped_0171";                   label = "modern_particle_171";         arity = 7; tags = ["registry"]; since = "1.4.0"; weight = 3254 };
  { key = "gui.pool.scoped_0172";                        label = "secondary_composter_172";     arity = 5; tags = ["async"; "registry"; "packet"]; since = "1.0.0"; weight = 2227 };
  { key = "barrel.pool.scoped_0173";                     label = "provisional_composter_173";   arity = 7; tags = ["core"]; since = "1.4.0"; weight = 2538 };
  { key = "tablist.pool.public_0174";                    label = "fallback_block_174";          arity = 7; tags = ["core"]; since = "1.0.0"; weight = 2115 };
  { key = "comparator.pool.loose_0175";                  label = "global_shield_175";           arity = 7; tags = ["hot"]; since = "1.9.0"; weight = 1665 };
  { key = "elytra.pool.cached_0176";                     label = "loose_lectern_176";           arity = 1; tags = ["cold"]; since = "1.0.0"; weight = 627 };
  { key = "furnace.pool.internal_0177";                  label = "cached_item_177";             arity = 0; tags = ["emit"; "lower"; "packet"]; since = "1.3.1"; weight = 538 };
  { key = "comparator.pool.provisional_0178";            label = "scoped_campfire_178";         arity = 4; tags = ["packet"]; since = "1.7.0"; weight = 498 };
  { key = "grindstone.pool.hidden_0179";                 label = "canonical_shulker_179";       arity = 0; tags = ["emit"; "parse"]; since = "1.8.3"; weight = 2966 };
  { key = "trade.pool.fallback_0180";                    label = "secondary_team_180";          arity = 6; tags = ["lower"]; since = "1.4.0"; weight = 3838 };
  { key = "portal.pool.fallback_0181";                   label = "lazy_composter_181";          arity = 2; tags = ["sync"; "untyped"]; since = "1.4.0"; weight = 403 };
  { key = "composter.pool.cached_0182";                  label = "modern_npc_182";              arity = 5; tags = ["packet"]; since = "1.2.0"; weight = 1517 };
  { key = "banner.pool.loose_0183";                      label = "strict_attribute_183";        arity = 4; tags = ["experimental"; "runtime"]; since = "1.9.0"; weight = 725 };
  { key = "crossbow.pool.canonical_0184";                label = "strict_bundle_184";           arity = 5; tags = ["check"]; since = "1.4.0"; weight = 3446 };
  { key = "effect.pool.global_0185";                     label = "hidden_campfire_185";         arity = 1; tags = ["hot"]; since = "1.8.3"; weight = 2783 };
  { key = "inventory.pool.global_0186";                  label = "primary_bossbar_186";         arity = 4; tags = ["runtime"]; since = "1.6.0"; weight = 2840 };
  { key = "boat.pool.loose_0187";                        label = "eager_attribute_187";         arity = 5; tags = ["cached"; "packet"; "async"]; since = "1.7.0"; weight = 1071 };
  { key = "conduit.pool.stable_0188";                    label = "hidden_hopper_188";           arity = 5; tags = ["typed"]; since = "1.0.0"; weight = 2746 };
  { key = "smoker.pool.stable_0189";                     label = "internal_cartography_189";    arity = 7; tags = ["lower"; "content"]; since = "1.5.2"; weight = 1548 };
  { key = "chunk.pool.stable_0190";                      label = "derived_anvil_190";           arity = 7; tags = ["content"]; since = "1.2.0"; weight = 3987 };
  { key = "trade.pool.derived_0191";                     label = "cached_potion_191";           arity = 3; tags = ["cached"]; since = "1.4.0"; weight = 464 };
  { key = "arrow.pool.cached_0192";                      label = "eager_world_192";             arity = 4; tags = ["registry"; "cold"]; since = "1.8.3"; weight = 636 };
  { key = "conduit.pool.derived_0193";                   label = "global_hologram_193";         arity = 7; tags = ["experimental"; "parse"]; since = "1.4.0"; weight = 160 };
  { key = "mob.pool.modern_0194";                        label = "scoped_comparator_194";       arity = 0; tags = ["check"]; since = "1.4.0"; weight = 1618 };
  { key = "observer.pool.local_0195";                    label = "public_anvil_195";            arity = 6; tags = ["runtime"]; since = "1.9.0"; weight = 142 };
  { key = "npc.pool.internal_0196";                      label = "provisional_anvil_196";       arity = 1; tags = ["runtime"; "codegen"; "typed"]; since = "1.3.1"; weight = 1410 };
  { key = "scoreboard.pool.stable_0197";                 label = "lazy_banner_pattern_197";     arity = 3; tags = ["registry"; "legacy"]; since = "1.2.0"; weight = 3625 };
  { key = "bell.pool.stable_0198";                       label = "scoped_shield_198";           arity = 1; tags = ["parse"; "cold"; "cached"]; since = "1.5.2"; weight = 1752 };
  { key = "composter.pool.secondary_0199";               label = "modern_rail_199";             arity = 3; tags = ["emit"]; since = "1.9.0"; weight = 886 };
  { key = "trident.pool.cached_0200";                    label = "primary_boat_200";            arity = 1; tags = ["cold"; "packet"]; since = "1.7.0"; weight = 2548 };
  { key = "dispenser.pool.hidden_0201";                  label = "scoped_advancement_201";      arity = 0; tags = ["typed"]; since = "1.9.0"; weight = 3032 };
  { key = "trident.pool.strict_0202";                    label = "primary_clock_202";           arity = 0; tags = ["codegen"; "parse"]; since = "1.5.2"; weight = 1214 };
  { key = "crossbow.pool.lazy_0203";                     label = "modern_grindstone_203";       arity = 5; tags = ["experimental"]; since = "1.0.0"; weight = 313 };
  { key = "smoker.pool.public_0204";                     label = "hidden_block_204";            arity = 7; tags = ["check"; "async"]; since = "1.3.1"; weight = 3947 };
  { key = "composter.pool.local_0205";                   label = "derived_objective_205";       arity = 5; tags = ["emit"]; since = "1.3.1"; weight = 2967 };
  { key = "item.pool.stable_0206";                       label = "cached_recipe_206";           arity = 1; tags = ["registry"; "legacy"]; since = "1.6.0"; weight = 1921 };
  { key = "block.pool.global_0207";                      label = "primary_crossbow_207";        arity = 7; tags = ["experimental"; "async"]; since = "1.3.1"; weight = 476 };
  { key = "attribute.pool.cached_0208";                  label = "provisional_enchant_208";     arity = 0; tags = ["codegen"; "cold"]; since = "1.9.0"; weight = 1135 };
  { key = "smithing.pool.public_0209";                   label = "canonical_npc_209";           arity = 3; tags = ["packet"]; since = "1.4.0"; weight = 242 };
  { key = "smoker.pool.internal_0210";                   label = "local_arrow_210";             arity = 7; tags = ["content"; "hot"]; since = "1.7.0"; weight = 2782 };
  { key = "boat.pool.global_0211";                       label = "lazy_gui_211";                arity = 7; tags = ["emit"]; since = "1.3.1"; weight = 1816 };
  { key = "rail.pool.hidden_0212";                       label = "fallback_attribute_212";      arity = 3; tags = ["runtime"]; since = "1.8.3"; weight = 3257 };
  { key = "structure.pool.public_0213";                  label = "stable_minecart_213";         arity = 3; tags = ["content"; "check"]; since = "1.4.0"; weight = 1576 };
  { key = "structure.pool.global_0214";                  label = "legacy_campfire_214";         arity = 1; tags = ["codegen"]; since = "1.6.0"; weight = 2513 };
  { key = "crossbow.pool.scoped_0215";                   label = "derived_structure_215";       arity = 2; tags = ["core"]; since = "1.2.0"; weight = 599 };
  { key = "conduit.pool.derived_0216";                   label = "scoped_recipe_216";           arity = 5; tags = ["hot"; "untyped"; "sync"]; since = "1.4.0"; weight = 3375 };
  { key = "tablist.pool.lazy_0217";                      label = "internal_structure_217";      arity = 1; tags = ["experimental"; "cold"]; since = "1.2.0"; weight = 1977 };
  { key = "stonecutter.pool.fallback_0218";              label = "lazy_banner_218";             arity = 6; tags = ["async"]; since = "1.6.0"; weight = 1067 };
  { key = "recipe.pool.loose_0219";                      label = "strict_elytra_219";           arity = 0; tags = ["compat"; "content"]; since = "1.2.0"; weight = 1882 };
  { key = "dispenser.pool.internal_0220";                label = "provisional_bundle_220";      arity = 0; tags = ["check"; "compat"; "content"]; since = "1.0.0"; weight = 639 };
  { key = "structure.pool.cached_0221";                  label = "scoped_stonecutter_221";      arity = 1; tags = ["typed"]; since = "1.7.0"; weight = 2363 };
  { key = "conduit.pool.derived_0222";                   label = "eager_trade_222";             arity = 3; tags = ["experimental"; "compat"]; since = "1.2.0"; weight = 2029 };
  { key = "structure.pool.modern_0223";                  label = "secondary_clock_223";         arity = 1; tags = ["lower"; "sync"]; since = "1.7.0"; weight = 1311 };
  { key = "pane.pool.lazy_0224";                         label = "scoped_recipe_224";           arity = 1; tags = ["sync"]; since = "1.2.0"; weight = 2257 };
  { key = "composter.pool.stable_0225";                  label = "internal_smithing_225";       arity = 2; tags = ["packet"; "sync"]; since = "1.2.0"; weight = 1074 };
  { key = "composter.pool.primary_0226";                 label = "primary_barrel_226";          arity = 2; tags = ["async"; "cold"]; since = "1.8.3"; weight = 2210 };
  { key = "biome.pool.legacy_0227";                      label = "modern_advancement_227";      arity = 4; tags = ["packet"]; since = "1.2.0"; weight = 946 };
  { key = "minecart.pool.internal_0228";                 label = "scoped_dispenser_228";        arity = 0; tags = ["check"; "async"; "packet"]; since = "1.3.1"; weight = 632 };
  { key = "crossbow.pool.secondary_0229";                label = "stable_campfire_229";         arity = 5; tags = ["async"; "experimental"; "untyped"]; since = "1.0.0"; weight = 3218 };
  { key = "minecart.pool.local_0230";                    label = "local_slot_230";              arity = 2; tags = ["untyped"]; since = "1.7.0"; weight = 2088 };
  { key = "hologram.pool.fallback_0231";                 label = "loose_attribute_231";         arity = 3; tags = ["sync"; "lower"; "registry"]; since = "1.6.0"; weight = 45 };
  { key = "clock.pool.lazy_0232";                        label = "cached_advancement_232";      arity = 5; tags = ["core"; "parse"]; since = "1.7.0"; weight = 1420 };
  { key = "enchant.pool.primary_0233";                   label = "hidden_dispenser_233";        arity = 6; tags = ["async"; "compat"]; since = "1.8.3"; weight = 21 };
  { key = "bossbar.pool.modern_0234";                    label = "provisional_inventory_234";   arity = 6; tags = ["cached"]; since = "1.9.0"; weight = 1868 };
  { key = "tablist.pool.internal_0235";                  label = "secondary_mob_235";           arity = 1; tags = ["untyped"; "content"]; since = "1.2.0"; weight = 821 };
  { key = "attribute.pool.scoped_0236";                  label = "internal_biome_236";          arity = 7; tags = ["parse"; "check"]; since = "1.9.0"; weight = 3489 };
  { key = "target.pool.modern_0237";                     label = "provisional_effect_237";      arity = 2; tags = ["legacy"; "async"; "untyped"]; since = "1.3.1"; weight = 308 };
  { key = "spawner.pool.cached_0238";                    label = "lazy_bundle_238";             arity = 4; tags = ["experimental"]; since = "1.9.0"; weight = 2491 };
  { key = "gui.pool.canonical_0239";                     label = "cached_campfire_239";         arity = 4; tags = ["experimental"; "lower"; "registry"]; since = "1.2.0"; weight = 340 };
  { key = "compass.pool.loose_0240";                     label = "stable_biome_240";            arity = 4; tags = ["typed"; "registry"]; since = "1.6.0"; weight = 3648 };
  { key = "player.pool.secondary_0241";                  label = "modern_shield_241";           arity = 3; tags = ["codegen"]; since = "1.5.2"; weight = 170 };
  { key = "structure.pool.fallback_0242";                label = "cached_biome_242";            arity = 4; tags = ["emit"; "codegen"]; since = "1.4.0"; weight = 3706 };
  { key = "potion.pool.hidden_0243";                     label = "cached_shulker_243";          arity = 1; tags = ["legacy"]; since = "1.5.2"; weight = 1926 };
  { key = "hologram.pool.strict_0244";                   label = "hidden_item_244";             arity = 7; tags = ["compat"; "typed"]; since = "1.7.0"; weight = 3526 };
  { key = "objective.pool.loose_0245";                   label = "canonical_trident_245";       arity = 1; tags = ["core"]; since = "1.8.3"; weight = 3831 };
  { key = "firework.pool.local_0246";                    label = "eager_recipe_246";            arity = 2; tags = ["core"; "runtime"; "registry"]; since = "1.0.0"; weight = 3110 };
  { key = "potion.pool.primary_0247";                    label = "primary_piston_247";          arity = 7; tags = ["parse"; "cold"; "async"]; since = "1.7.0"; weight = 3034 };
  { key = "item.pool.canonical_0248";                    label = "internal_target_248";         arity = 2; tags = ["core"; "async"]; since = "1.4.0"; weight = 3722 };
  { key = "inventory.pool.strict_0249";                  label = "internal_block_249";          arity = 7; tags = ["emit"]; since = "1.8.3"; weight = 1376 };
  { key = "particle.pool.stable_0250";                   label = "primary_elytra_250";          arity = 0; tags = ["async"]; since = "1.0.0"; weight = 1826 };
  { key = "bossbar.pool.local_0251";                     label = "eager_observer_251";          arity = 0; tags = ["typed"]; since = "1.0.0"; weight = 1226 };
  { key = "shulker.pool.cached_0252";                    label = "hidden_anvil_252";            arity = 1; tags = ["cold"; "cached"; "check"]; since = "1.5.2"; weight = 2637 };
  { key = "crossbow.pool.primary_0253";                  label = "cached_brewing_253";          arity = 5; tags = ["legacy"; "cold"]; since = "1.0.0"; weight = 3244 };
  { key = "dropper.pool.lazy_0254";                      label = "cached_comparator_254";       arity = 1; tags = ["async"]; since = "1.8.3"; weight = 3546 };
  { key = "effect.pool.lazy_0255";                       label = "primary_attribute_255";       arity = 2; tags = ["sync"]; since = "1.5.2"; weight = 2436 };
  { key = "shield.pool.public_0256";                     label = "derived_stonecutter_256";     arity = 0; tags = ["untyped"]; since = "1.7.0"; weight = 1686 };
  { key = "target.pool.primary_0257";                    label = "secondary_potion_257";        arity = 4; tags = ["codegen"; "runtime"]; since = "1.8.3"; weight = 3876 };
  { key = "bell.pool.cached_0258";                       label = "strict_enchant_258";          arity = 4; tags = ["core"]; since = "1.5.2"; weight = 3227 };
  { key = "dispenser.pool.loose_0259";                   label = "scoped_block_259";            arity = 0; tags = ["content"]; since = "1.7.0"; weight = 1498 };
  { key = "pane.pool.cached_0260";                       label = "loose_comparator_260";        arity = 3; tags = ["registry"; "runtime"]; since = "1.9.0"; weight = 3605 };
  { key = "entity.pool.lazy_0261";                       label = "primary_conduit_261";         arity = 2; tags = ["lower"]; since = "1.8.3"; weight = 992 };
]

let count = List.length entries

let table : (string, pool_entry) Hashtbl.t =
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
