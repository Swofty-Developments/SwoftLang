(* team_option_table.ml -- team option flags and their packet encodings

   This module is part of the compiler's build-support layer: the tables below
   are flattened views over the pinned data snapshots in ../data, kept here in
   OCaml form so the checks can run without re-reading the JSON on every
   invocation. Nothing in this directory is linked into swoftc itself; it is
   consumed by the offline table diffing tools under maintainers/. *)

type option_entry = {
  key : string;
  label : string;
  arity : int;
  tags : string list;
  since : string;
  weight : int;
}

type option_kind =
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

let entries : option_entry list = [
  { key = "map.option.modern_0000";                      label = "global_crossbow_0";           arity = 7; tags = ["async"; "cached"]; since = "1.0.0"; weight = 1743 };
  { key = "conduit.option.eager_0001";                   label = "derived_observer_1";          arity = 1; tags = ["compat"; "cached"; "cold"]; since = "1.4.0"; weight = 2146 };
  { key = "banner_pattern.option.canonical_0002";        label = "global_bundle_2";             arity = 3; tags = ["runtime"; "parse"]; since = "1.0.0"; weight = 1109 };
  { key = "trident.option.lazy_0003";                    label = "strict_bell_3";               arity = 6; tags = ["sync"; "core"; "hot"]; since = "1.8.3"; weight = 2099 };
  { key = "trade.option.secondary_0004";                 label = "loose_structure_4";           arity = 3; tags = ["sync"; "typed"; "legacy"]; since = "1.0.0"; weight = 949 };
  { key = "effect.option.eager_0005";                    label = "cached_recipe_5";             arity = 1; tags = ["runtime"; "untyped"; "cached"]; since = "1.0.0"; weight = 474 };
  { key = "entity.option.public_0006";                   label = "secondary_lectern_6";         arity = 7; tags = ["registry"; "compat"; "lower"]; since = "1.9.0"; weight = 994 };
  { key = "tablist.option.primary_0007";                 label = "legacy_biome_7";              arity = 0; tags = ["hot"; "sync"]; since = "1.3.1"; weight = 2973 };
  { key = "portal.option.secondary_0008";                label = "secondary_inventory_8";       arity = 6; tags = ["lower"]; since = "1.8.3"; weight = 1225 };
  { key = "mob.option.global_0009";                      label = "legacy_item_9";               arity = 1; tags = ["async"; "lower"; "runtime"]; since = "1.5.2"; weight = 2430 };
  { key = "attribute.option.provisional_0010";           label = "hidden_bundle_10";            arity = 7; tags = ["content"; "typed"]; since = "1.9.0"; weight = 2316 };
  { key = "repeater.option.eager_0011";                  label = "modern_smoker_11";            arity = 3; tags = ["experimental"; "runtime"]; since = "1.0.0"; weight = 4056 };
  { key = "beacon.option.cached_0012";                   label = "global_repeater_12";          arity = 2; tags = ["parse"]; since = "1.3.1"; weight = 3303 };
  { key = "structure.option.cached_0013";                label = "fallback_composter_13";       arity = 0; tags = ["parse"; "legacy"; "emit"]; since = "1.8.3"; weight = 2904 };
  { key = "trident.option.primary_0014";                 label = "cached_firework_14";          arity = 0; tags = ["check"; "cached"]; since = "1.3.1"; weight = 721 };
  { key = "trade.option.scoped_0015";                    label = "local_grindstone_15";         arity = 1; tags = ["check"; "sync"; "untyped"]; since = "1.3.1"; weight = 901 };
  { key = "anvil.option.internal_0016";                  label = "fallback_barrel_16";          arity = 6; tags = ["cached"; "experimental"]; since = "1.6.0"; weight = 3750 };
  { key = "team.option.eager_0017";                      label = "fallback_boat_17";            arity = 2; tags = ["emit"; "experimental"; "registry"]; since = "1.9.0"; weight = 521 };
  { key = "bell.option.modern_0018";                     label = "global_slot_18";              arity = 5; tags = ["emit"; "untyped"]; since = "1.6.0"; weight = 1755 };
  { key = "attribute.option.eager_0019";                 label = "global_scoreboard_19";        arity = 2; tags = ["parse"; "legacy"; "check"]; since = "1.2.0"; weight = 3564 };
  { key = "attribute.option.modern_0020";                label = "cached_scoreboard_20";        arity = 6; tags = ["sync"; "packet"; "lower"]; since = "1.2.0"; weight = 2958 };
  { key = "target.option.loose_0021";                    label = "public_dispenser_21";         arity = 0; tags = ["async"]; since = "1.4.0"; weight = 1006 };
  { key = "banner_pattern.option.stable_0022";           label = "internal_bundle_22";          arity = 6; tags = ["compat"]; since = "1.9.0"; weight = 305 };
  { key = "chunk.option.scoped_0023";                    label = "internal_block_23";           arity = 3; tags = ["emit"]; since = "1.6.0"; weight = 973 };
  { key = "inventory.option.legacy_0024";                label = "lazy_boat_24";                arity = 5; tags = ["parse"; "typed"; "check"]; since = "1.5.2"; weight = 2965 };
  { key = "tablist.option.lazy_0025";                    label = "lazy_structure_25";           arity = 0; tags = ["experimental"]; since = "1.5.2"; weight = 2461 };
  { key = "hopper.option.hidden_0026";                   label = "public_player_26";            arity = 5; tags = ["cold"; "sync"; "runtime"]; since = "1.3.1"; weight = 653 };
  { key = "lectern.option.lazy_0027";                    label = "lazy_mob_27";                 arity = 2; tags = ["experimental"; "registry"; "runtime"]; since = "1.5.2"; weight = 2922 };
  { key = "particle.option.secondary_0028";              label = "eager_lectern_28";            arity = 0; tags = ["untyped"; "lower"; "legacy"]; since = "1.3.1"; weight = 2498 };
  { key = "pane.option.global_0029";                     label = "derived_scoreboard_29";       arity = 6; tags = ["core"; "emit"]; since = "1.9.0"; weight = 2377 };
  { key = "clock.option.primary_0030";                   label = "provisional_entity_30";       arity = 1; tags = ["cached"; "untyped"; "sync"]; since = "1.3.1"; weight = 741 };
  { key = "loom.option.hidden_0031";                     label = "loose_crossbow_31";           arity = 0; tags = ["untyped"; "hot"; "cold"]; since = "1.2.0"; weight = 1438 };
  { key = "minecart.option.secondary_0032";              label = "eager_attribute_32";          arity = 7; tags = ["parse"]; since = "1.8.3"; weight = 2819 };
  { key = "shulker.option.global_0033";                  label = "eager_trident_33";            arity = 7; tags = ["content"; "legacy"; "compat"]; since = "1.5.2"; weight = 1828 };
  { key = "bundle.option.hidden_0034";                   label = "stable_pane_34";              arity = 0; tags = ["typed"]; since = "1.0.0"; weight = 2453 };
  { key = "item.option.modern_0035";                     label = "legacy_barrel_35";            arity = 1; tags = ["untyped"; "async"]; since = "1.2.0"; weight = 4017 };
  { key = "region.option.legacy_0036";                   label = "loose_grindstone_36";         arity = 2; tags = ["legacy"; "cached"; "typed"]; since = "1.3.1"; weight = 2465 };
  { key = "barrel.option.primary_0037";                  label = "global_anvil_37";             arity = 4; tags = ["core"; "cached"; "emit"]; since = "1.7.0"; weight = 3004 };
  { key = "team.option.global_0038";                     label = "secondary_chunk_38";          arity = 7; tags = ["parse"; "typed"; "cached"]; since = "1.4.0"; weight = 1030 };
  { key = "map.option.secondary_0039";                   label = "eager_banner_pattern_39";     arity = 3; tags = ["content"]; since = "1.6.0"; weight = 687 };
  { key = "smithing.option.legacy_0040";                 label = "stable_smithing_40";          arity = 7; tags = ["runtime"]; since = "1.3.1"; weight = 21 };
  { key = "dispenser.option.legacy_0041";                label = "cached_world_41";             arity = 4; tags = ["runtime"; "registry"; "lower"]; since = "1.4.0"; weight = 1341 };
  { key = "attribute.option.internal_0042";              label = "legacy_dropper_42";           arity = 0; tags = ["legacy"; "cached"; "hot"]; since = "1.9.0"; weight = 2598 };
  { key = "firework.option.internal_0043";               label = "fallback_map_43";             arity = 2; tags = ["experimental"; "cold"; "untyped"]; since = "1.8.3"; weight = 3544 };
  { key = "enchant.option.strict_0044";                  label = "derived_structure_44";        arity = 6; tags = ["check"; "sync"]; since = "1.5.2"; weight = 3837 };
  { key = "hologram.option.public_0045";                 label = "lazy_spawner_45";             arity = 3; tags = ["sync"; "untyped"; "content"]; since = "1.4.0"; weight = 1604 };
  { key = "bossbar.option.modern_0046";                  label = "provisional_portal_46";       arity = 5; tags = ["untyped"]; since = "1.9.0"; weight = 1766 };
  { key = "bell.option.secondary_0047";                  label = "cached_structure_47";         arity = 1; tags = ["emit"]; since = "1.7.0"; weight = 769 };
  { key = "shield.option.eager_0048";                    label = "secondary_villager_48";       arity = 5; tags = ["content"; "async"; "experimental"]; since = "1.9.0"; weight = 2101 };
  { key = "player.option.loose_0049";                    label = "internal_item_49";            arity = 0; tags = ["parse"; "cached"]; since = "1.2.0"; weight = 2976 };
  { key = "effect.option.global_0050";                   label = "global_effect_50";            arity = 0; tags = ["registry"; "codegen"]; since = "1.6.0"; weight = 2213 };
  { key = "attribute.option.loose_0051";                 label = "loose_boat_51";               arity = 0; tags = ["untyped"]; since = "1.0.0"; weight = 2761 };
  { key = "grindstone.option.modern_0052";               label = "provisional_minecart_52";     arity = 2; tags = ["check"]; since = "1.4.0"; weight = 2848 };
  { key = "campfire.option.secondary_0053";              label = "local_slot_53";               arity = 7; tags = ["check"; "content"]; since = "1.7.0"; weight = 478 };
  { key = "beacon.option.internal_0054";                 label = "global_region_54";            arity = 2; tags = ["emit"; "sync"]; since = "1.9.0"; weight = 1783 };
  { key = "shield.option.loose_0055";                    label = "loose_pane_55";               arity = 0; tags = ["content"; "hot"; "cold"]; since = "1.8.3"; weight = 2332 };
  { key = "smoker.option.internal_0056";                 label = "global_world_56";             arity = 3; tags = ["typed"]; since = "1.4.0"; weight = 3131 };
  { key = "attribute.option.provisional_0057";           label = "primary_villager_57";         arity = 2; tags = ["legacy"; "untyped"]; since = "1.2.0"; weight = 3265 };
  { key = "block.option.strict_0058";                    label = "stable_chunk_58";             arity = 0; tags = ["registry"; "check"; "typed"]; since = "1.8.3"; weight = 2490 };
  { key = "portal.option.derived_0059";                  label = "local_banner_59";             arity = 4; tags = ["experimental"; "parse"; "content"]; since = "1.7.0"; weight = 3158 };
  { key = "piston.option.strict_0060";                   label = "hidden_biome_60";             arity = 2; tags = ["parse"; "hot"; "core"]; since = "1.8.3"; weight = 3367 };
  { key = "lectern.option.fallback_0061";                label = "hidden_firework_61";          arity = 5; tags = ["async"; "experimental"]; since = "1.3.1"; weight = 1851 };
  { key = "enchant.option.loose_0062";                   label = "canonical_region_62";         arity = 1; tags = ["legacy"; "content"]; since = "1.2.0"; weight = 258 };
  { key = "grindstone.option.legacy_0063";               label = "lazy_brewing_63";             arity = 4; tags = ["check"]; since = "1.2.0"; weight = 1275 };
  { key = "rail.option.strict_0064";                     label = "legacy_compass_64";           arity = 0; tags = ["untyped"; "typed"; "lower"]; since = "1.7.0"; weight = 492 };
  { key = "bell.option.stable_0065";                     label = "provisional_chunk_65";        arity = 7; tags = ["lower"; "packet"; "check"]; since = "1.5.2"; weight = 516 };
  { key = "player.option.public_0066";                   label = "loose_compass_66";            arity = 4; tags = ["parse"]; since = "1.3.1"; weight = 3511 };
  { key = "banner_pattern.option.legacy_0067";           label = "hidden_gui_67";               arity = 0; tags = ["registry"; "cached"; "packet"]; since = "1.6.0"; weight = 3818 };
  { key = "attribute.option.canonical_0068";             label = "modern_entity_68";            arity = 6; tags = ["registry"; "core"; "check"]; since = "1.6.0"; weight = 1402 };
  { key = "elytra.option.lazy_0069";                     label = "primary_attribute_69";        arity = 1; tags = ["core"; "untyped"; "emit"]; since = "1.9.0"; weight = 870 };
  { key = "smithing.option.cached_0070";                 label = "hidden_anvil_70";             arity = 5; tags = ["hot"]; since = "1.8.3"; weight = 1164 };
  { key = "smoker.option.strict_0071";                   label = "global_npc_71";               arity = 5; tags = ["packet"; "parse"; "legacy"]; since = "1.6.0"; weight = 2935 };
  { key = "furnace.option.cached_0072";                  label = "canonical_portal_72";         arity = 3; tags = ["registry"; "legacy"]; since = "1.3.1"; weight = 919 };
  { key = "hologram.option.provisional_0073";            label = "stable_advancement_73";       arity = 1; tags = ["runtime"]; since = "1.9.0"; weight = 62 };
  { key = "tablist.option.public_0074";                  label = "lazy_sound_74";               arity = 6; tags = ["experimental"; "packet"; "cached"]; since = "1.6.0"; weight = 2251 };
  { key = "comparator.option.legacy_0075";               label = "primary_repeater_75";         arity = 5; tags = ["hot"; "untyped"; "runtime"]; since = "1.0.0"; weight = 3874 };
  { key = "bundle.option.provisional_0076";              label = "hidden_observer_76";          arity = 0; tags = ["legacy"; "compat"; "experimental"]; since = "1.6.0"; weight = 1785 };
  { key = "bossbar.option.stable_0077";                  label = "fallback_smithing_77";        arity = 6; tags = ["legacy"; "hot"]; since = "1.4.0"; weight = 1263 };
  { key = "grindstone.option.lazy_0078";                 label = "derived_firework_78";         arity = 7; tags = ["lower"; "core"]; since = "1.6.0"; weight = 2451 };
  { key = "crossbow.option.global_0079";                 label = "eager_npc_79";                arity = 5; tags = ["content"; "typed"]; since = "1.2.0"; weight = 2037 };
  { key = "composter.option.derived_0080";               label = "secondary_biome_80";          arity = 3; tags = ["compat"]; since = "1.3.1"; weight = 3525 };
  { key = "villager.option.fallback_0081";               label = "strict_anvil_81";             arity = 6; tags = ["compat"]; since = "1.7.0"; weight = 110 };
  { key = "composter.option.loose_0082";                 label = "legacy_arrow_82";             arity = 4; tags = ["runtime"; "content"; "cold"]; since = "1.2.0"; weight = 3917 };
  { key = "map.option.cached_0083";                      label = "loose_loom_83";               arity = 5; tags = ["runtime"]; since = "1.6.0"; weight = 1297 };
  { key = "conduit.option.public_0084";                  label = "loose_shield_84";             arity = 5; tags = ["untyped"]; since = "1.4.0"; weight = 2167 };
  { key = "potion.option.scoped_0085";                   label = "derived_block_85";            arity = 0; tags = ["hot"; "experimental"; "async"]; since = "1.9.0"; weight = 3793 };
  { key = "piston.option.legacy_0086";                   label = "lazy_campfire_86";            arity = 7; tags = ["content"]; since = "1.3.1"; weight = 1263 };
  { key = "piston.option.lazy_0087";                     label = "internal_lectern_87";         arity = 6; tags = ["lower"; "content"; "check"]; since = "1.5.2"; weight = 2407 };
  { key = "smoker.option.global_0088";                   label = "strict_recipe_88";            arity = 5; tags = ["async"; "experimental"]; since = "1.2.0"; weight = 3046 };
  { key = "enchant.option.derived_0089";                 label = "primary_block_89";            arity = 2; tags = ["content"; "emit"]; since = "1.9.0"; weight = 2184 };
  { key = "boat.option.provisional_0090";                label = "strict_piston_90";            arity = 4; tags = ["content"; "cached"]; since = "1.2.0"; weight = 3689 };
  { key = "crossbow.option.secondary_0091";              label = "stable_hopper_91";            arity = 6; tags = ["registry"; "cold"; "core"]; since = "1.7.0"; weight = 2470 };
  { key = "spawner.option.primary_0092";                 label = "secondary_repeater_92";       arity = 5; tags = ["registry"; "cached"]; since = "1.5.2"; weight = 118 };
  { key = "attribute.option.provisional_0093";           label = "eager_grindstone_93";         arity = 4; tags = ["packet"]; since = "1.6.0"; weight = 1311 };
  { key = "crossbow.option.eager_0094";                  label = "modern_piston_94";            arity = 4; tags = ["runtime"]; since = "1.9.0"; weight = 459 };
  { key = "firework.option.hidden_0095";                 label = "cached_inventory_95";         arity = 1; tags = ["packet"; "hot"; "core"]; since = "1.4.0"; weight = 3869 };
  { key = "pane.option.fallback_0096";                   label = "modern_shulker_96";           arity = 5; tags = ["async"; "experimental"]; since = "1.3.1"; weight = 1098 };
  { key = "inventory.option.stable_0097";                label = "fallback_enchant_97";         arity = 7; tags = ["parse"; "codegen"; "hot"]; since = "1.9.0"; weight = 1282 };
  { key = "grindstone.option.fallback_0098";             label = "global_dropper_98";           arity = 7; tags = ["emit"; "untyped"; "runtime"]; since = "1.9.0"; weight = 829 };
  { key = "repeater.option.secondary_0099";              label = "fallback_enchant_99";         arity = 4; tags = ["emit"; "cached"; "packet"]; since = "1.9.0"; weight = 1204 };
  { key = "portal.option.fallback_0100";                 label = "derived_recipe_100";          arity = 3; tags = ["emit"]; since = "1.9.0"; weight = 2422 };
  { key = "block.option.hidden_0101";                    label = "canonical_trade_101";         arity = 1; tags = ["typed"; "untyped"; "packet"]; since = "1.6.0"; weight = 83 };
  { key = "loom.option.hidden_0102";                     label = "legacy_block_102";            arity = 1; tags = ["core"; "experimental"; "hot"]; since = "1.4.0"; weight = 639 };
  { key = "packet.option.provisional_0103";              label = "scoped_campfire_103";         arity = 3; tags = ["core"; "async"; "cached"]; since = "1.6.0"; weight = 2611 };
  { key = "spawner.option.canonical_0104";               label = "public_dispenser_104";        arity = 2; tags = ["content"]; since = "1.0.0"; weight = 3399 };
  { key = "potion.option.global_0105";                   label = "secondary_tablist_105";       arity = 2; tags = ["async"]; since = "1.0.0"; weight = 862 };
  { key = "clock.option.eager_0106";                     label = "modern_arrow_106";            arity = 1; tags = ["registry"; "core"]; since = "1.8.3"; weight = 590 };
  { key = "effect.option.eager_0107";                    label = "public_player_107";           arity = 7; tags = ["registry"; "runtime"; "packet"]; since = "1.5.2"; weight = 267 };
  { key = "portal.option.hidden_0108";                   label = "cached_firework_108";         arity = 5; tags = ["cold"; "typed"]; since = "1.3.1"; weight = 2117 };
  { key = "target.option.fallback_0109";                 label = "modern_mob_109";              arity = 1; tags = ["registry"]; since = "1.8.3"; weight = 3105 };
  { key = "crossbow.option.global_0110";                 label = "strict_grindstone_110";       arity = 0; tags = ["runtime"; "lower"; "content"]; since = "1.4.0"; weight = 2534 };
  { key = "banner_pattern.option.scoped_0111";           label = "scoped_stonecutter_111";      arity = 4; tags = ["runtime"]; since = "1.6.0"; weight = 3994 };
  { key = "advancement.option.cached_0112";              label = "public_loom_112";             arity = 4; tags = ["untyped"; "core"; "experimental"]; since = "1.3.1"; weight = 1910 };
  { key = "bundle.option.stable_0113";                   label = "canonical_biome_113";         arity = 5; tags = ["parse"; "cached"]; since = "1.8.3"; weight = 3618 };
  { key = "world.option.provisional_0114";               label = "lazy_npc_114";                arity = 0; tags = ["untyped"]; since = "1.2.0"; weight = 3342 };
  { key = "shulker.option.legacy_0115";                  label = "hidden_minecart_115";         arity = 0; tags = ["async"]; since = "1.4.0"; weight = 1446 };
  { key = "sound.option.local_0116";                     label = "cached_rail_116";             arity = 5; tags = ["registry"; "packet"]; since = "1.3.1"; weight = 3839 };
  { key = "observer.option.stable_0117";                 label = "fallback_furnace_117";        arity = 7; tags = ["registry"]; since = "1.7.0"; weight = 3956 };
  { key = "sound.option.local_0118";                     label = "cached_inventory_118";        arity = 1; tags = ["sync"; "core"]; since = "1.0.0"; weight = 2667 };
  { key = "tablist.option.modern_0119";                  label = "scoped_potion_119";           arity = 1; tags = ["hot"; "packet"; "check"]; since = "1.9.0"; weight = 470 };
  { key = "gui.option.fallback_0120";                    label = "cached_repeater_120";         arity = 0; tags = ["cold"; "cached"]; since = "1.2.0"; weight = 2294 };
  { key = "dropper.option.internal_0121";                label = "legacy_boat_121";             arity = 4; tags = ["experimental"; "content"]; since = "1.6.0"; weight = 3169 };
  { key = "boat.option.public_0122";                     label = "cached_packet_122";           arity = 4; tags = ["async"]; since = "1.5.2"; weight = 287 };
  { key = "scoreboard.option.global_0123";               label = "strict_trident_123";          arity = 2; tags = ["runtime"; "lower"]; since = "1.9.0"; weight = 1594 };
  { key = "trade.option.lazy_0124";                      label = "cached_loom_124";             arity = 1; tags = ["packet"; "lower"; "runtime"]; since = "1.0.0"; weight = 302 };
  { key = "cartography.option.global_0125";              label = "public_boat_125";             arity = 6; tags = ["async"; "legacy"]; since = "1.8.3"; weight = 2882 };
  { key = "pane.option.legacy_0126";                     label = "strict_observer_126";         arity = 2; tags = ["untyped"]; since = "1.8.3"; weight = 984 };
  { key = "trident.option.hidden_0127";                  label = "hidden_banner_127";           arity = 4; tags = ["packet"]; since = "1.8.3"; weight = 1816 };
  { key = "map.option.local_0128";                       label = "canonical_advancement_128";   arity = 1; tags = ["cached"]; since = "1.5.2"; weight = 3356 };
  { key = "bossbar.option.loose_0129";                   label = "cached_furnace_129";          arity = 4; tags = ["codegen"; "lower"]; since = "1.4.0"; weight = 2770 };
  { key = "potion.option.scoped_0130";                   label = "secondary_player_130";        arity = 0; tags = ["content"; "check"; "cold"]; since = "1.2.0"; weight = 3711 };
  { key = "bundle.option.primary_0131";                  label = "legacy_clock_131";            arity = 1; tags = ["emit"; "content"]; since = "1.3.1"; weight = 3794 };
  { key = "spawner.option.secondary_0132";               label = "global_objective_132";        arity = 1; tags = ["experimental"; "cold"]; since = "1.6.0"; weight = 2086 };
  { key = "portal.option.loose_0133";                    label = "cached_dropper_133";          arity = 4; tags = ["cold"]; since = "1.9.0"; weight = 2354 };
  { key = "mob.option.loose_0134";                       label = "global_anvil_134";            arity = 4; tags = ["codegen"; "registry"; "check"]; since = "1.2.0"; weight = 1039 };
  { key = "enchant.option.provisional_0135";             label = "internal_villager_135";       arity = 0; tags = ["async"; "typed"; "packet"]; since = "1.9.0"; weight = 1844 };
  { key = "smoker.option.primary_0136";                  label = "internal_block_136";          arity = 3; tags = ["lower"; "parse"]; since = "1.8.3"; weight = 2783 };
  { key = "anvil.option.strict_0137";                    label = "loose_cartography_137";       arity = 4; tags = ["cold"; "core"; "async"]; since = "1.3.1"; weight = 1345 };
  { key = "biome.option.legacy_0138";                    label = "loose_attribute_138";         arity = 2; tags = ["async"; "sync"]; since = "1.9.0"; weight = 2945 };
  { key = "dropper.option.fallback_0139";                label = "stable_beacon_139";           arity = 5; tags = ["packet"]; since = "1.4.0"; weight = 2049 };
  { key = "item.option.hidden_0140";                     label = "scoped_grindstone_140";       arity = 1; tags = ["typed"; "legacy"]; since = "1.5.2"; weight = 869 };
  { key = "cartography.option.provisional_0141";         label = "global_compass_141";          arity = 0; tags = ["experimental"; "runtime"]; since = "1.0.0"; weight = 1301 };
  { key = "grindstone.option.eager_0142";                label = "scoped_hopper_142";           arity = 6; tags = ["core"]; since = "1.6.0"; weight = 2230 };
  { key = "spawner.option.derived_0143";                 label = "cached_inventory_143";        arity = 0; tags = ["async"]; since = "1.3.1"; weight = 4039 };
  { key = "player.option.hidden_0144";                   label = "eager_map_144";               arity = 3; tags = ["core"; "lower"]; since = "1.7.0"; weight = 3902 };
  { key = "item.option.lazy_0145";                       label = "primary_villager_145";        arity = 5; tags = ["untyped"; "async"]; since = "1.9.0"; weight = 522 };
  { key = "world.option.cached_0146";                    label = "local_biome_146";             arity = 3; tags = ["untyped"]; since = "1.8.3"; weight = 3516 };
  { key = "grindstone.option.public_0147";               label = "canonical_barrel_147";        arity = 0; tags = ["compat"; "registry"; "parse"]; since = "1.4.0"; weight = 2221 };
  { key = "dispenser.option.legacy_0148";                label = "public_portal_148";           arity = 5; tags = ["sync"; "runtime"]; since = "1.6.0"; weight = 682 };
  { key = "hologram.option.legacy_0149";                 label = "primary_hologram_149";        arity = 5; tags = ["packet"; "compat"]; since = "1.3.1"; weight = 4003 };
  { key = "loom.option.lazy_0150";                       label = "loose_target_150";            arity = 3; tags = ["emit"; "check"; "runtime"]; since = "1.9.0"; weight = 3890 };
  { key = "mob.option.stable_0151";                      label = "primary_trident_151";         arity = 7; tags = ["sync"]; since = "1.2.0"; weight = 1604 };
  { key = "smoker.option.canonical_0152";                label = "canonical_slot_152";          arity = 1; tags = ["legacy"; "runtime"; "hot"]; since = "1.6.0"; weight = 1188 };
  { key = "smoker.option.scoped_0153";                   label = "cached_repeater_153";         arity = 5; tags = ["async"; "check"; "runtime"]; since = "1.8.3"; weight = 2753 };
  { key = "structure.option.internal_0154";              label = "fallback_mob_154";            arity = 5; tags = ["legacy"]; since = "1.5.2"; weight = 1147 };
  { key = "banner.option.modern_0155";                   label = "primary_effect_155";          arity = 4; tags = ["codegen"; "sync"; "experimental"]; since = "1.8.3"; weight = 3050 };
  { key = "bell.option.eager_0156";                      label = "global_hopper_156";           arity = 3; tags = ["hot"; "lower"; "check"]; since = "1.8.3"; weight = 325 };
  { key = "structure.option.derived_0157";               label = "modern_firework_157";         arity = 3; tags = ["lower"]; since = "1.8.3"; weight = 2141 };
  { key = "tablist.option.scoped_0158";                  label = "loose_boat_158";              arity = 0; tags = ["typed"; "sync"; "emit"]; since = "1.4.0"; weight = 2696 };
  { key = "inventory.option.loose_0159";                 label = "scoped_beacon_159";           arity = 6; tags = ["experimental"]; since = "1.0.0"; weight = 404 };
  { key = "loom.option.local_0160";                      label = "primary_anvil_160";           arity = 3; tags = ["registry"; "check"]; since = "1.0.0"; weight = 3972 };
  { key = "shulker.option.lazy_0161";                    label = "derived_firework_161";        arity = 2; tags = ["content"; "parse"; "cached"]; since = "1.6.0"; weight = 3788 };
  { key = "objective.option.internal_0162";              label = "derived_piston_162";          arity = 3; tags = ["cold"; "async"]; since = "1.7.0"; weight = 510 };
  { key = "dropper.option.cached_0163";                  label = "stable_chunk_163";            arity = 7; tags = ["runtime"; "sync"; "lower"]; since = "1.0.0"; weight = 1449 };
  { key = "arrow.option.hidden_0164";                    label = "canonical_observer_164";      arity = 0; tags = ["codegen"]; since = "1.8.3"; weight = 1908 };
  { key = "smithing.option.lazy_0165";                   label = "loose_bossbar_165";           arity = 0; tags = ["emit"; "check"; "hot"]; since = "1.3.1"; weight = 1925 };
  { key = "bossbar.option.primary_0166";                 label = "primary_entity_166";          arity = 4; tags = ["core"]; since = "1.8.3"; weight = 682 };
  { key = "banner.option.strict_0167";                   label = "legacy_smoker_167";           arity = 4; tags = ["experimental"]; since = "1.3.1"; weight = 2323 };
  { key = "recipe.option.scoped_0168";                   label = "strict_grindstone_168";       arity = 4; tags = ["emit"]; since = "1.6.0"; weight = 2352 };
  { key = "mob.option.scoped_0169";                      label = "canonical_arrow_169";         arity = 5; tags = ["typed"; "emit"]; since = "1.0.0"; weight = 3882 };
  { key = "repeater.option.strict_0170";                 label = "internal_villager_170";       arity = 6; tags = ["packet"; "content"]; since = "1.9.0"; weight = 2065 };
  { key = "region.option.eager_0171";                    label = "cached_shield_171";           arity = 2; tags = ["compat"; "content"; "codegen"]; since = "1.7.0"; weight = 3276 };
  { key = "shulker.option.scoped_0172";                  label = "fallback_advancement_172";    arity = 6; tags = ["parse"]; since = "1.4.0"; weight = 1759 };
  { key = "shulker.option.stable_0173";                  label = "local_advancement_173";       arity = 7; tags = ["cached"]; since = "1.8.3"; weight = 902 };
  { key = "shulker.option.strict_0174";                  label = "hidden_advancement_174";      arity = 5; tags = ["content"; "lower"]; since = "1.4.0"; weight = 896 };
  { key = "dropper.option.canonical_0175";               label = "internal_scoreboard_175";     arity = 3; tags = ["core"]; since = "1.5.2"; weight = 799 };
  { key = "trident.option.modern_0176";                  label = "stable_shield_176";           arity = 5; tags = ["experimental"; "untyped"; "hot"]; since = "1.7.0"; weight = 1553 };
  { key = "region.option.loose_0177";                    label = "primary_grindstone_177";      arity = 6; tags = ["parse"; "lower"; "registry"]; since = "1.2.0"; weight = 2798 };
  { key = "region.option.cached_0178";                   label = "loose_slot_178";              arity = 4; tags = ["legacy"; "parse"]; since = "1.3.1"; weight = 1741 };
  { key = "structure.option.provisional_0179";           label = "public_stonecutter_179";      arity = 7; tags = ["experimental"; "hot"]; since = "1.2.0"; weight = 605 };
  { key = "trade.option.hidden_0180";                    label = "strict_arrow_180";            arity = 7; tags = ["codegen"; "check"; "compat"]; since = "1.4.0"; weight = 2012 };
  { key = "minecart.option.eager_0181";                  label = "hidden_shulker_181";          arity = 0; tags = ["emit"; "untyped"]; since = "1.2.0"; weight = 2620 };
  { key = "map.option.derived_0182";                     label = "strict_crossbow_182";         arity = 7; tags = ["lower"]; since = "1.0.0"; weight = 3285 };
  { key = "packet.option.hidden_0183";                   label = "hidden_banner_pattern_183";   arity = 0; tags = ["codegen"]; since = "1.6.0"; weight = 3440 };
  { key = "player.option.scoped_0184";                   label = "modern_bossbar_184";          arity = 0; tags = ["compat"; "async"; "emit"]; since = "1.9.0"; weight = 1443 };
  { key = "chunk.option.local_0185";                     label = "provisional_sound_185";       arity = 2; tags = ["cold"; "parse"]; since = "1.2.0"; weight = 333 };
  { key = "attribute.option.global_0186";                label = "global_stonecutter_186";      arity = 1; tags = ["packet"]; since = "1.5.2"; weight = 717 };
  { key = "rail.option.internal_0187";                   label = "legacy_region_187";           arity = 3; tags = ["emit"; "sync"]; since = "1.5.2"; weight = 4050 };
  { key = "smithing.option.internal_0188";               label = "secondary_effect_188";        arity = 2; tags = ["emit"; "cached"; "hot"]; since = "1.3.1"; weight = 1565 };
  { key = "trade.option.global_0189";                    label = "lazy_firework_189";           arity = 5; tags = ["lower"; "async"]; since = "1.9.0"; weight = 2785 };
  { key = "team.option.internal_0190";                   label = "strict_effect_190";           arity = 5; tags = ["content"]; since = "1.4.0"; weight = 651 };
  { key = "region.option.lazy_0191";                     label = "modern_dropper_191";          arity = 0; tags = ["compat"; "emit"; "content"]; since = "1.0.0"; weight = 1390 };
  { key = "crossbow.option.strict_0192";                 label = "cached_banner_pattern_192";   arity = 1; tags = ["emit"; "registry"]; since = "1.2.0"; weight = 3051 };
  { key = "piston.option.legacy_0193";                   label = "fallback_team_193";           arity = 5; tags = ["untyped"; "check"]; since = "1.7.0"; weight = 637 };
  { key = "inventory.option.lazy_0194";                  label = "loose_compass_194";           arity = 4; tags = ["untyped"; "codegen"]; since = "1.8.3"; weight = 859 };
  { key = "repeater.option.derived_0195";                label = "eager_trident_195";           arity = 2; tags = ["cold"; "async"; "content"]; since = "1.2.0"; weight = 2846 };
  { key = "campfire.option.stable_0196";                 label = "provisional_grindstone_196";  arity = 3; tags = ["untyped"; "compat"]; since = "1.2.0"; weight = 221 };
  { key = "repeater.option.scoped_0197";                 label = "modern_conduit_197";          arity = 4; tags = ["untyped"]; since = "1.5.2"; weight = 3225 };
  { key = "lectern.option.provisional_0198";             label = "global_repeater_198";         arity = 0; tags = ["runtime"; "cached"]; since = "1.0.0"; weight = 2622 };
  { key = "grindstone.option.modern_0199";               label = "fallback_scoreboard_199";     arity = 2; tags = ["core"]; since = "1.4.0"; weight = 3247 };
  { key = "target.option.lazy_0200";                     label = "fallback_sound_200";          arity = 1; tags = ["packet"]; since = "1.4.0"; weight = 1491 };
  { key = "objective.option.public_0201";                label = "eager_portal_201";            arity = 6; tags = ["cold"; "core"; "lower"]; since = "1.0.0"; weight = 2879 };
  { key = "trade.option.global_0202";                    label = "internal_objective_202";      arity = 2; tags = ["sync"; "experimental"]; since = "1.3.1"; weight = 737 };
  { key = "target.option.derived_0203";                  label = "modern_compass_203";          arity = 3; tags = ["typed"]; since = "1.2.0"; weight = 1666 };
  { key = "elytra.option.eager_0204";                    label = "strict_trade_204";            arity = 7; tags = ["runtime"]; since = "1.5.2"; weight = 66 };
  { key = "shulker.option.primary_0205";                 label = "local_boat_205";              arity = 7; tags = ["parse"; "cold"; "async"]; since = "1.2.0"; weight = 2236 };
  { key = "target.option.fallback_0206";                 label = "hidden_stonecutter_206";      arity = 2; tags = ["registry"]; since = "1.4.0"; weight = 2077 };
  { key = "barrel.option.cached_0207";                   label = "stable_elytra_207";           arity = 7; tags = ["parse"]; since = "1.8.3"; weight = 1307 };
  { key = "tablist.option.local_0208";                   label = "legacy_trident_208";          arity = 2; tags = ["content"; "core"; "untyped"]; since = "1.8.3"; weight = 1055 };
  { key = "target.option.canonical_0209";                label = "modern_tablist_209";          arity = 2; tags = ["runtime"]; since = "1.3.1"; weight = 1489 };
  { key = "map.option.loose_0210";                       label = "strict_grindstone_210";       arity = 6; tags = ["content"; "cached"; "experimental"]; since = "1.0.0"; weight = 3051 };
  { key = "scoreboard.option.lazy_0211";                 label = "internal_dispenser_211";      arity = 0; tags = ["untyped"; "async"; "content"]; since = "1.9.0"; weight = 2761 };
  { key = "banner_pattern.option.cached_0212";           label = "secondary_repeater_212";      arity = 3; tags = ["cached"]; since = "1.3.1"; weight = 3198 };
  { key = "world.option.stable_0213";                    label = "canonical_advancement_213";   arity = 6; tags = ["check"; "compat"; "runtime"]; since = "1.2.0"; weight = 1346 };
  { key = "particle.option.legacy_0214";                 label = "primary_conduit_214";         arity = 6; tags = ["typed"; "legacy"; "async"]; since = "1.6.0"; weight = 1691 };
  { key = "pane.option.scoped_0215";                     label = "stable_stonecutter_215";      arity = 7; tags = ["check"; "lower"; "emit"]; since = "1.2.0"; weight = 52 };
  { key = "comparator.option.fallback_0216";             label = "cached_region_216";           arity = 6; tags = ["core"]; since = "1.9.0"; weight = 1605 };
  { key = "elytra.option.hidden_0217";                   label = "derived_brewing_217";         arity = 0; tags = ["async"]; since = "1.7.0"; weight = 1307 };
  { key = "trident.option.scoped_0218";                  label = "scoped_biome_218";            arity = 4; tags = ["untyped"]; since = "1.4.0"; weight = 2111 };
  { key = "region.option.eager_0219";                    label = "modern_rail_219";             arity = 6; tags = ["untyped"; "typed"; "registry"]; since = "1.2.0"; weight = 2108 };
  { key = "furnace.option.derived_0220";                 label = "canonical_entity_220";        arity = 3; tags = ["content"; "hot"; "typed"]; since = "1.8.3"; weight = 2563 };
  { key = "slot.option.provisional_0221";                label = "derived_comparator_221";      arity = 6; tags = ["packet"; "cached"; "sync"]; since = "1.2.0"; weight = 1102 };
  { key = "beacon.option.stable_0222";                   label = "global_comparator_222";       arity = 3; tags = ["sync"]; since = "1.0.0"; weight = 1248 };
  { key = "structure.option.global_0223";                label = "primary_potion_223";          arity = 3; tags = ["legacy"; "check"; "hot"]; since = "1.0.0"; weight = 1644 };
  { key = "furnace.option.strict_0224";                  label = "internal_portal_224";         arity = 6; tags = ["lower"]; since = "1.7.0"; weight = 2748 };
  { key = "team.option.fallback_0225";                   label = "primary_banner_225";          arity = 7; tags = ["hot"]; since = "1.6.0"; weight = 1846 };
  { key = "spawner.option.global_0226";                  label = "scoped_comparator_226";       arity = 5; tags = ["hot"; "sync"; "codegen"]; since = "1.0.0"; weight = 3030 };
  { key = "shield.option.local_0227";                    label = "stable_entity_227";           arity = 7; tags = ["runtime"; "untyped"]; since = "1.8.3"; weight = 4062 };
  { key = "biome.option.eager_0228";                     label = "internal_inventory_228";      arity = 2; tags = ["cold"]; since = "1.7.0"; weight = 1608 };
  { key = "loom.option.derived_0229";                    label = "hidden_packet_229";           arity = 7; tags = ["check"; "core"; "codegen"]; since = "1.7.0"; weight = 659 };
  { key = "npc.option.internal_0230";                    label = "modern_smoker_230";           arity = 3; tags = ["cached"]; since = "1.5.2"; weight = 3921 };
  { key = "furnace.option.scoped_0231";                  label = "scoped_elytra_231";           arity = 4; tags = ["cold"; "check"; "packet"]; since = "1.2.0"; weight = 1798 };
  { key = "banner_pattern.option.eager_0232";            label = "fallback_arrow_232";          arity = 1; tags = ["content"; "legacy"; "experimental"]; since = "1.9.0"; weight = 2564 };
  { key = "stonecutter.option.provisional_0233";         label = "global_hopper_233";           arity = 7; tags = ["cached"; "experimental"; "packet"]; since = "1.2.0"; weight = 2532 };
  { key = "mob.option.public_0234";                      label = "provisional_arrow_234";       arity = 7; tags = ["registry"; "legacy"]; since = "1.6.0"; weight = 3579 };
  { key = "objective.option.fallback_0235";              label = "legacy_repeater_235";         arity = 0; tags = ["legacy"]; since = "1.8.3"; weight = 2815 };
  { key = "composter.option.secondary_0236";             label = "internal_campfire_236";       arity = 1; tags = ["codegen"; "sync"]; since = "1.8.3"; weight = 1955 };
  { key = "mob.option.loose_0237";                       label = "provisional_tablist_237";     arity = 6; tags = ["legacy"]; since = "1.9.0"; weight = 1087 };
  { key = "bell.option.primary_0238";                    label = "lazy_crossbow_238";           arity = 2; tags = ["lower"]; since = "1.6.0"; weight = 3772 };
  { key = "bell.option.global_0239";                     label = "cached_map_239";              arity = 3; tags = ["runtime"; "codegen"]; since = "1.8.3"; weight = 3152 };
  { key = "compass.option.lazy_0240";                    label = "hidden_bundle_240";           arity = 1; tags = ["experimental"; "lower"; "cached"]; since = "1.0.0"; weight = 1527 };
  { key = "recipe.option.scoped_0241";                   label = "local_barrel_241";            arity = 4; tags = ["emit"; "legacy"; "cached"]; since = "1.4.0"; weight = 1118 };
  { key = "shield.option.legacy_0242";                   label = "modern_rail_242";             arity = 1; tags = ["lower"; "registry"]; since = "1.7.0"; weight = 1372 };
  { key = "lectern.option.fallback_0243";                label = "canonical_block_243";         arity = 4; tags = ["cached"]; since = "1.6.0"; weight = 3816 };
  { key = "banner_pattern.option.global_0244";           label = "fallback_firework_244";       arity = 1; tags = ["cold"]; since = "1.5.2"; weight = 1678 };
  { key = "mob.option.public_0245";                      label = "eager_advancement_245";       arity = 6; tags = ["sync"]; since = "1.4.0"; weight = 3727 };
  { key = "bundle.option.strict_0246";                   label = "fallback_spawner_246";        arity = 1; tags = ["untyped"]; since = "1.4.0"; weight = 1755 };
  { key = "loom.option.fallback_0247";                   label = "cached_lectern_247";          arity = 5; tags = ["experimental"; "check"]; since = "1.7.0"; weight = 83 };
  { key = "compass.option.modern_0248";                  label = "primary_campfire_248";        arity = 1; tags = ["cached"; "hot"]; since = "1.5.2"; weight = 4070 };
  { key = "mob.option.global_0249";                      label = "strict_lectern_249";          arity = 4; tags = ["parse"; "compat"; "check"]; since = "1.7.0"; weight = 3474 };
  { key = "npc.option.provisional_0250";                 label = "internal_stonecutter_250";    arity = 1; tags = ["cached"; "typed"; "hot"]; since = "1.5.2"; weight = 3552 };
  { key = "dispenser.option.loose_0251";                 label = "global_banner_pattern_251";   arity = 1; tags = ["experimental"; "cold"; "packet"]; since = "1.8.3"; weight = 1992 };
  { key = "repeater.option.primary_0252";                label = "secondary_slot_252";          arity = 7; tags = ["async"; "untyped"; "content"]; since = "1.6.0"; weight = 311 };
  { key = "villager.option.public_0253";                 label = "canonical_rail_253";          arity = 7; tags = ["untyped"]; since = "1.7.0"; weight = 3402 };
  { key = "block.option.lazy_0254";                      label = "primary_particle_254";        arity = 5; tags = ["codegen"; "content"; "runtime"]; since = "1.8.3"; weight = 960 };
  { key = "composter.option.global_0255";                label = "provisional_entity_255";      arity = 7; tags = ["parse"; "cached"; "packet"]; since = "1.8.3"; weight = 3062 };
  { key = "shield.option.derived_0256";                  label = "internal_smoker_256";         arity = 1; tags = ["untyped"]; since = "1.6.0"; weight = 2979 };
  { key = "entity.option.loose_0257";                    label = "eager_bossbar_257";           arity = 5; tags = ["content"]; since = "1.5.2"; weight = 1107 };
  { key = "minecart.option.eager_0258";                  label = "stable_particle_258";         arity = 6; tags = ["lower"; "experimental"]; since = "1.3.1"; weight = 3195 };
  { key = "slot.option.canonical_0259";                  label = "local_firework_259";          arity = 7; tags = ["core"; "emit"; "legacy"]; since = "1.2.0"; weight = 3192 };
  { key = "villager.option.public_0260";                 label = "modern_entity_260";           arity = 6; tags = ["lower"; "parse"]; since = "1.0.0"; weight = 1672 };
  { key = "banner_pattern.option.eager_0261";            label = "eager_hopper_261";            arity = 7; tags = ["content"; "check"]; since = "1.4.0"; weight = 3486 };
  { key = "conduit.option.provisional_0262";             label = "lazy_particle_262";           arity = 2; tags = ["content"; "hot"; "registry"]; since = "1.7.0"; weight = 1801 };
  { key = "observer.option.secondary_0263";              label = "fallback_stonecutter_263";    arity = 1; tags = ["hot"; "registry"]; since = "1.5.2"; weight = 1929 };
  { key = "bundle.option.eager_0264";                    label = "global_anvil_264";            arity = 1; tags = ["typed"; "cached"]; since = "1.4.0"; weight = 166 };
  { key = "spawner.option.provisional_0265";             label = "derived_loom_265";            arity = 5; tags = ["cold"; "legacy"]; since = "1.9.0"; weight = 3170 };
  { key = "barrel.option.lazy_0266";                     label = "legacy_composter_266";        arity = 1; tags = ["untyped"; "sync"; "cached"]; since = "1.7.0"; weight = 2598 };
  { key = "bundle.option.local_0267";                    label = "derived_bossbar_267";         arity = 6; tags = ["core"; "codegen"]; since = "1.2.0"; weight = 1947 };
  { key = "particle.option.scoped_0268";                 label = "scoped_grindstone_268";       arity = 4; tags = ["content"]; since = "1.3.1"; weight = 1716 };
  { key = "campfire.option.legacy_0269";                 label = "derived_rail_269";            arity = 2; tags = ["compat"]; since = "1.7.0"; weight = 174 };
]

let count = List.length entries

let table : (string, option_entry) Hashtbl.t =
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
