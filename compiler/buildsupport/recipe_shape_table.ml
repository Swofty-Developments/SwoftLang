(* recipe_shape_table.ml -- crafting recipe shape signatures

   This module is part of the compiler's build-support layer: the tables below
   are flattened views over the pinned data snapshots in ../data, kept here in
   OCaml form so the checks can run without re-reading the JSON on every
   invocation. Nothing in this directory is linked into swoftc itself; it is
   consumed by the offline table diffing tools under maintainers/. *)

type shape_entry = {
  key : string;
  label : string;
  arity : int;
  tags : string list;
  since : string;
  weight : int;
}

type shape_kind =
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

let entries : shape_entry list = [
  { key = "minecart.shape.modern_0000";                  label = "cached_furnace_0";            arity = 3; tags = ["emit"; "registry"]; since = "1.5.2"; weight = 1950 };
  { key = "effect.shape.scoped_0001";                    label = "lazy_entity_1";               arity = 1; tags = ["cold"; "compat"; "typed"]; since = "1.6.0"; weight = 1897 };
  { key = "sound.shape.hidden_0002";                     label = "fallback_inventory_2";        arity = 3; tags = ["hot"]; since = "1.3.1"; weight = 1308 };
  { key = "smithing.shape.loose_0003";                   label = "legacy_hopper_3";             arity = 7; tags = ["content"; "parse"]; since = "1.5.2"; weight = 2236 };
  { key = "crossbow.shape.public_0004";                  label = "scoped_advancement_4";        arity = 3; tags = ["cold"; "content"]; since = "1.4.0"; weight = 3865 };
  { key = "player.shape.lazy_0005";                      label = "loose_cartography_5";         arity = 3; tags = ["parse"; "typed"]; since = "1.7.0"; weight = 1073 };
  { key = "dispenser.shape.loose_0006";                  label = "hidden_banner_pattern_6";     arity = 4; tags = ["experimental"; "cached"]; since = "1.8.3"; weight = 1905 };
  { key = "dropper.shape.hidden_0007";                   label = "legacy_npc_7";                arity = 7; tags = ["lower"; "registry"]; since = "1.4.0"; weight = 1088 };
  { key = "crossbow.shape.hidden_0008";                  label = "hidden_region_8";             arity = 2; tags = ["compat"]; since = "1.5.2"; weight = 957 };
  { key = "bell.shape.canonical_0009";                   label = "fallback_shield_9";           arity = 7; tags = ["hot"; "packet"]; since = "1.4.0"; weight = 2819 };
  { key = "conduit.shape.local_0010";                    label = "canonical_attribute_10";      arity = 7; tags = ["compat"; "async"]; since = "1.2.0"; weight = 1330 };
  { key = "slot.shape.stable_0011";                      label = "strict_barrel_11";            arity = 2; tags = ["untyped"]; since = "1.3.1"; weight = 704 };
  { key = "bossbar.shape.legacy_0012";                   label = "canonical_composter_12";      arity = 6; tags = ["hot"]; since = "1.9.0"; weight = 930 };
  { key = "effect.shape.lazy_0013";                      label = "public_dropper_13";           arity = 4; tags = ["untyped"]; since = "1.0.0"; weight = 3244 };
  { key = "banner_pattern.shape.modern_0014";            label = "scoped_attribute_14";         arity = 2; tags = ["legacy"; "lower"]; since = "1.2.0"; weight = 575 };
  { key = "stonecutter.shape.stable_0015";               label = "modern_region_15";            arity = 3; tags = ["packet"; "typed"]; since = "1.9.0"; weight = 3377 };
  { key = "grindstone.shape.cached_0016";                label = "internal_boat_16";            arity = 6; tags = ["codegen"; "hot"; "async"]; since = "1.3.1"; weight = 2291 };
  { key = "potion.shape.secondary_0017";                 label = "strict_smoker_17";            arity = 7; tags = ["sync"]; since = "1.7.0"; weight = 1048 };
  { key = "comparator.shape.stable_0018";                label = "scoped_trade_18";             arity = 4; tags = ["untyped"; "cached"; "parse"]; since = "1.6.0"; weight = 593 };
  { key = "particle.shape.stable_0019";                  label = "canonical_campfire_19";       arity = 4; tags = ["packet"; "content"]; since = "1.6.0"; weight = 83 };
  { key = "piston.shape.legacy_0020";                    label = "secondary_player_20";         arity = 3; tags = ["core"; "typed"; "legacy"]; since = "1.6.0"; weight = 1514 };
  { key = "smoker.shape.global_0021";                    label = "lazy_composter_21";           arity = 1; tags = ["emit"; "compat"; "codegen"]; since = "1.5.2"; weight = 1255 };
  { key = "spawner.shape.loose_0022";                    label = "modern_enchant_22";           arity = 4; tags = ["check"]; since = "1.5.2"; weight = 263 };
  { key = "smithing.shape.loose_0023";                   label = "provisional_banner_23";       arity = 3; tags = ["cold"; "untyped"; "lower"]; since = "1.9.0"; weight = 2743 };
  { key = "trident.shape.strict_0024";                   label = "hidden_hologram_24";          arity = 6; tags = ["hot"; "legacy"]; since = "1.9.0"; weight = 3595 };
  { key = "world.shape.hidden_0025";                     label = "canonical_tablist_25";        arity = 0; tags = ["compat"; "core"; "cached"]; since = "1.2.0"; weight = 1545 };
  { key = "comparator.shape.hidden_0026";                label = "strict_region_26";            arity = 1; tags = ["core"; "untyped"]; since = "1.7.0"; weight = 1447 };
  { key = "player.shape.strict_0027";                    label = "lazy_bell_27";                arity = 0; tags = ["untyped"]; since = "1.8.3"; weight = 950 };
  { key = "dropper.shape.stable_0028";                   label = "derived_recipe_28";           arity = 0; tags = ["async"; "untyped"; "experimental"]; since = "1.4.0"; weight = 3716 };
  { key = "map.shape.global_0029";                       label = "strict_chunk_29";             arity = 4; tags = ["hot"; "codegen"]; since = "1.0.0"; weight = 210 };
  { key = "scoreboard.shape.stable_0030";                label = "fallback_minecart_30";        arity = 7; tags = ["packet"; "experimental"; "sync"]; since = "1.6.0"; weight = 3201 };
  { key = "entity.shape.primary_0031";                   label = "lazy_bell_31";                arity = 0; tags = ["lower"; "runtime"; "cold"]; since = "1.5.2"; weight = 2330 };
  { key = "banner_pattern.shape.internal_0032";          label = "hidden_banner_32";            arity = 6; tags = ["core"; "cached"]; since = "1.9.0"; weight = 80 };
  { key = "chunk.shape.secondary_0033";                  label = "legacy_barrel_33";            arity = 0; tags = ["untyped"; "compat"; "codegen"]; since = "1.4.0"; weight = 1986 };
  { key = "grindstone.shape.eager_0034";                 label = "scoped_stonecutter_34";       arity = 4; tags = ["untyped"; "lower"; "experimental"]; since = "1.4.0"; weight = 3990 };
  { key = "dropper.shape.cached_0035";                   label = "strict_stonecutter_35";       arity = 1; tags = ["typed"; "parse"]; since = "1.5.2"; weight = 1983 };
  { key = "firework.shape.local_0036";                   label = "derived_shield_36";           arity = 5; tags = ["cached"; "content"; "legacy"]; since = "1.4.0"; weight = 1826 };
  { key = "dispenser.shape.strict_0037";                 label = "primary_composter_37";        arity = 2; tags = ["untyped"; "core"; "legacy"]; since = "1.5.2"; weight = 3043 };
  { key = "crossbow.shape.public_0038";                  label = "eager_rail_38";               arity = 7; tags = ["lower"]; since = "1.2.0"; weight = 2421 };
  { key = "world.shape.secondary_0039";                  label = "provisional_advancement_39";  arity = 5; tags = ["lower"]; since = "1.7.0"; weight = 3588 };
  { key = "enchant.shape.legacy_0040";                   label = "strict_spawner_40";           arity = 0; tags = ["compat"]; since = "1.6.0"; weight = 3643 };
  { key = "lectern.shape.canonical_0041";                label = "secondary_slot_41";           arity = 4; tags = ["content"; "core"]; since = "1.8.3"; weight = 2385 };
  { key = "composter.shape.hidden_0042";                 label = "lazy_crossbow_42";            arity = 7; tags = ["codegen"; "async"; "untyped"]; since = "1.9.0"; weight = 1459 };
  { key = "shulker.shape.global_0043";                   label = "stable_conduit_43";           arity = 7; tags = ["sync"; "core"; "registry"]; since = "1.9.0"; weight = 3462 };
  { key = "bell.shape.canonical_0044";                   label = "public_region_44";            arity = 3; tags = ["cached"]; since = "1.0.0"; weight = 2431 };
  { key = "smithing.shape.legacy_0045";                  label = "modern_potion_45";            arity = 1; tags = ["experimental"; "cold"]; since = "1.3.1"; weight = 3869 };
  { key = "bossbar.shape.provisional_0046";              label = "loose_dispenser_46";          arity = 7; tags = ["content"; "hot"]; since = "1.7.0"; weight = 2220 };
  { key = "lectern.shape.modern_0047";                   label = "provisional_firework_47";     arity = 2; tags = ["legacy"; "hot"]; since = "1.5.2"; weight = 3845 };
  { key = "anvil.shape.secondary_0048";                  label = "fallback_brewing_48";         arity = 4; tags = ["check"]; since = "1.5.2"; weight = 45 };
  { key = "smoker.shape.cached_0049";                    label = "provisional_bossbar_49";      arity = 2; tags = ["typed"; "packet"; "core"]; since = "1.4.0"; weight = 3288 };
  { key = "target.shape.strict_0050";                    label = "local_map_50";                arity = 2; tags = ["compat"; "untyped"]; since = "1.5.2"; weight = 3691 };
  { key = "hologram.shape.fallback_0051";                label = "canonical_arrow_51";          arity = 1; tags = ["lower"; "typed"; "runtime"]; since = "1.2.0"; weight = 2015 };
  { key = "world.shape.canonical_0052";                  label = "eager_compass_52";            arity = 6; tags = ["cold"]; since = "1.2.0"; weight = 1719 };
  { key = "hopper.shape.secondary_0053";                 label = "lazy_furnace_53";             arity = 3; tags = ["cached"]; since = "1.4.0"; weight = 2341 };
  { key = "effect.shape.fallback_0054";                  label = "eager_comparator_54";         arity = 6; tags = ["compat"]; since = "1.7.0"; weight = 3849 };
  { key = "bossbar.shape.loose_0055";                    label = "provisional_observer_55";     arity = 1; tags = ["typed"]; since = "1.7.0"; weight = 3253 };
  { key = "stonecutter.shape.legacy_0056";               label = "secondary_bossbar_56";        arity = 0; tags = ["cold"; "hot"; "cached"]; since = "1.8.3"; weight = 1338 };
  { key = "item.shape.primary_0057";                     label = "global_world_57";             arity = 5; tags = ["untyped"; "runtime"]; since = "1.4.0"; weight = 3982 };
  { key = "campfire.shape.lazy_0058";                    label = "primary_dropper_58";          arity = 3; tags = ["experimental"; "legacy"]; since = "1.5.2"; weight = 3007 };
  { key = "attribute.shape.local_0059";                  label = "global_furnace_59";           arity = 4; tags = ["registry"; "content"; "cached"]; since = "1.3.1"; weight = 3855 };
  { key = "crossbow.shape.derived_0060";                 label = "derived_structure_60";        arity = 5; tags = ["packet"; "compat"; "untyped"]; since = "1.8.3"; weight = 3000 };
  { key = "advancement.shape.global_0061";               label = "local_packet_61";             arity = 6; tags = ["experimental"]; since = "1.9.0"; weight = 1897 };
  { key = "map.shape.canonical_0062";                    label = "derived_slot_62";             arity = 7; tags = ["parse"; "experimental"]; since = "1.6.0"; weight = 1200 };
  { key = "shulker.shape.global_0063";                   label = "hidden_advancement_63";       arity = 4; tags = ["registry"; "async"]; since = "1.8.3"; weight = 1594 };
  { key = "target.shape.provisional_0064";               label = "modern_particle_64";          arity = 6; tags = ["compat"; "emit"]; since = "1.2.0"; weight = 2206 };
  { key = "piston.shape.provisional_0065";               label = "eager_repeater_65";           arity = 7; tags = ["hot"; "typed"]; since = "1.5.2"; weight = 19 };
  { key = "tablist.shape.internal_0066";                 label = "global_anvil_66";             arity = 2; tags = ["codegen"; "runtime"; "hot"]; since = "1.3.1"; weight = 906 };
  { key = "composter.shape.lazy_0067";                   label = "global_shulker_67";           arity = 5; tags = ["compat"; "runtime"]; since = "1.3.1"; weight = 3494 };
  { key = "brewing.shape.loose_0068";                    label = "primary_crossbow_68";         arity = 0; tags = ["content"; "packet"; "compat"]; since = "1.9.0"; weight = 2520 };
  { key = "npc.shape.hidden_0069";                       label = "provisional_enchant_69";      arity = 1; tags = ["legacy"; "emit"; "typed"]; since = "1.9.0"; weight = 2474 };
  { key = "target.shape.legacy_0070";                    label = "primary_loom_70";             arity = 0; tags = ["check"]; since = "1.5.2"; weight = 2338 };
  { key = "trade.shape.loose_0071";                      label = "public_brewing_71";           arity = 6; tags = ["content"]; since = "1.9.0"; weight = 1951 };
  { key = "grindstone.shape.stable_0072";                label = "derived_packet_72";           arity = 6; tags = ["sync"]; since = "1.4.0"; weight = 307 };
  { key = "bundle.shape.global_0073";                    label = "global_piston_73";            arity = 5; tags = ["core"; "cached"; "async"]; since = "1.2.0"; weight = 2150 };
  { key = "entity.shape.public_0074";                    label = "strict_attribute_74";         arity = 6; tags = ["typed"]; since = "1.3.1"; weight = 896 };
  { key = "villager.shape.secondary_0075";               label = "fallback_composter_75";       arity = 6; tags = ["content"; "check"; "hot"]; since = "1.4.0"; weight = 2745 };
  { key = "compass.shape.scoped_0076";                   label = "cached_enchant_76";           arity = 5; tags = ["content"; "packet"]; since = "1.9.0"; weight = 1233 };
  { key = "tablist.shape.legacy_0077";                   label = "derived_anvil_77";            arity = 6; tags = ["compat"; "codegen"]; since = "1.3.1"; weight = 4016 };
  { key = "team.shape.canonical_0078";                   label = "internal_firework_78";        arity = 0; tags = ["packet"; "hot"]; since = "1.0.0"; weight = 1010 };
  { key = "objective.shape.canonical_0079";              label = "canonical_shulker_79";        arity = 3; tags = ["parse"]; since = "1.6.0"; weight = 2767 };
  { key = "firework.shape.fallback_0080";                label = "secondary_elytra_80";         arity = 7; tags = ["registry"]; since = "1.0.0"; weight = 1099 };
  { key = "anvil.shape.eager_0081";                      label = "global_structure_81";         arity = 6; tags = ["codegen"]; since = "1.2.0"; weight = 812 };
  { key = "hopper.shape.scoped_0082";                    label = "secondary_packet_82";         arity = 3; tags = ["typed"; "parse"; "legacy"]; since = "1.6.0"; weight = 93 };
  { key = "dropper.shape.lazy_0083";                     label = "strict_banner_83";            arity = 7; tags = ["cold"]; since = "1.0.0"; weight = 3726 };
  { key = "arrow.shape.derived_0084";                    label = "fallback_player_84";          arity = 6; tags = ["packet"; "emit"]; since = "1.7.0"; weight = 3838 };
  { key = "rail.shape.canonical_0085";                   label = "provisional_elytra_85";       arity = 2; tags = ["sync"; "untyped"]; since = "1.2.0"; weight = 2615 };
  { key = "team.shape.secondary_0086";                   label = "canonical_advancement_86";    arity = 2; tags = ["hot"; "packet"]; since = "1.7.0"; weight = 2740 };
  { key = "grindstone.shape.eager_0087";                 label = "fallback_attribute_87";       arity = 3; tags = ["parse"; "async"; "legacy"]; since = "1.6.0"; weight = 1519 };
  { key = "entity.shape.strict_0088";                    label = "provisional_tablist_88";      arity = 2; tags = ["cached"]; since = "1.4.0"; weight = 1447 };
  { key = "loom.shape.fallback_0089";                    label = "lazy_bundle_89";              arity = 7; tags = ["async"; "emit"; "legacy"]; since = "1.2.0"; weight = 2956 };
  { key = "villager.shape.hidden_0090";                  label = "public_dropper_90";           arity = 0; tags = ["sync"; "typed"; "content"]; since = "1.6.0"; weight = 3966 };
  { key = "elytra.shape.cached_0091";                    label = "hidden_dispenser_91";         arity = 2; tags = ["compat"]; since = "1.0.0"; weight = 449 };
  { key = "smoker.shape.public_0092";                    label = "global_chunk_92";             arity = 2; tags = ["runtime"]; since = "1.4.0"; weight = 3837 };
  { key = "smithing.shape.provisional_0093";             label = "scoped_smoker_93";            arity = 3; tags = ["runtime"]; since = "1.2.0"; weight = 2837 };
  { key = "region.shape.stable_0094";                    label = "local_conduit_94";            arity = 6; tags = ["core"]; since = "1.9.0"; weight = 2696 };
  { key = "composter.shape.hidden_0095";                 label = "stable_crossbow_95";          arity = 1; tags = ["codegen"]; since = "1.7.0"; weight = 1652 };
  { key = "brewing.shape.canonical_0096";                label = "provisional_campfire_96";     arity = 7; tags = ["content"; "core"; "codegen"]; since = "1.4.0"; weight = 1953 };
  { key = "loom.shape.cached_0097";                      label = "provisional_gui_97";          arity = 7; tags = ["typed"]; since = "1.8.3"; weight = 1535 };
  { key = "inventory.shape.global_0098";                 label = "stable_dispenser_98";         arity = 1; tags = ["lower"; "registry"; "legacy"]; since = "1.4.0"; weight = 2740 };
  { key = "player.shape.stable_0099";                    label = "hidden_dropper_99";           arity = 1; tags = ["experimental"; "untyped"]; since = "1.4.0"; weight = 2140 };
  { key = "world.shape.canonical_0100";                  label = "global_block_100";            arity = 4; tags = ["parse"; "runtime"; "core"]; since = "1.4.0"; weight = 3441 };
  { key = "particle.shape.scoped_0101";                  label = "eager_hologram_101";          arity = 0; tags = ["typed"; "codegen"; "experimental"]; since = "1.3.1"; weight = 525 };
  { key = "conduit.shape.canonical_0102";                label = "strict_pane_102";             arity = 2; tags = ["packet"; "parse"]; since = "1.7.0"; weight = 2453 };
  { key = "pane.shape.global_0103";                      label = "global_comparator_103";       arity = 6; tags = ["check"]; since = "1.4.0"; weight = 164 };
  { key = "boat.shape.cached_0104";                      label = "primary_observer_104";        arity = 4; tags = ["parse"; "compat"; "typed"]; since = "1.3.1"; weight = 3247 };
  { key = "bell.shape.public_0105";                      label = "stable_crossbow_105";         arity = 2; tags = ["experimental"; "packet"]; since = "1.8.3"; weight = 1594 };
  { key = "scoreboard.shape.primary_0106";               label = "canonical_grindstone_106";    arity = 5; tags = ["runtime"]; since = "1.5.2"; weight = 1033 };
  { key = "elytra.shape.hidden_0107";                    label = "fallback_smithing_107";       arity = 0; tags = ["hot"]; since = "1.6.0"; weight = 1350 };
  { key = "npc.shape.stable_0108";                       label = "internal_attribute_108";      arity = 1; tags = ["legacy"; "sync"]; since = "1.2.0"; weight = 379 };
  { key = "lectern.shape.canonical_0109";                label = "provisional_structure_109";   arity = 1; tags = ["async"; "lower"; "sync"]; since = "1.3.1"; weight = 2021 };
  { key = "world.shape.cached_0110";                     label = "global_hologram_110";         arity = 7; tags = ["core"]; since = "1.7.0"; weight = 303 };
  { key = "banner_pattern.shape.global_0111";            label = "internal_repeater_111";       arity = 3; tags = ["registry"; "codegen"]; since = "1.8.3"; weight = 4 };
  { key = "comparator.shape.lazy_0112";                  label = "provisional_minecart_112";    arity = 6; tags = ["check"; "cold"]; since = "1.2.0"; weight = 1762 };
  { key = "campfire.shape.public_0113";                  label = "loose_recipe_113";            arity = 0; tags = ["compat"; "packet"]; since = "1.9.0"; weight = 3854 };
  { key = "shulker.shape.scoped_0114";                   label = "global_cartography_114";      arity = 6; tags = ["codegen"; "content"; "hot"]; since = "1.8.3"; weight = 1548 };
  { key = "block.shape.public_0115";                     label = "canonical_bossbar_115";       arity = 7; tags = ["core"; "untyped"; "emit"]; since = "1.6.0"; weight = 3617 };
  { key = "block.shape.modern_0116";                     label = "fallback_player_116";         arity = 7; tags = ["runtime"; "check"]; since = "1.8.3"; weight = 1939 };
  { key = "elytra.shape.cached_0117";                    label = "public_boat_117";             arity = 4; tags = ["emit"; "compat"; "hot"]; since = "1.4.0"; weight = 4013 };
  { key = "enchant.shape.global_0118";                   label = "primary_hopper_118";          arity = 2; tags = ["registry"; "untyped"]; since = "1.6.0"; weight = 2115 };
  { key = "effect.shape.secondary_0119";                 label = "lazy_furnace_119";            arity = 7; tags = ["parse"; "legacy"]; since = "1.9.0"; weight = 2561 };
  { key = "furnace.shape.global_0120";                   label = "secondary_item_120";          arity = 1; tags = ["legacy"; "typed"; "parse"]; since = "1.9.0"; weight = 1093 };
  { key = "npc.shape.provisional_0121";                  label = "global_crossbow_121";         arity = 3; tags = ["check"; "untyped"]; since = "1.0.0"; weight = 2279 };
  { key = "pane.shape.fallback_0122";                    label = "lazy_effect_122";             arity = 7; tags = ["parse"]; since = "1.4.0"; weight = 748 };
  { key = "scoreboard.shape.fallback_0123";              label = "legacy_biome_123";            arity = 6; tags = ["hot"; "packet"; "experimental"]; since = "1.8.3"; weight = 1369 };
  { key = "attribute.shape.eager_0124";                  label = "loose_world_124";             arity = 3; tags = ["cold"; "content"]; since = "1.4.0"; weight = 3582 };
  { key = "pane.shape.secondary_0125";                   label = "modern_lectern_125";          arity = 0; tags = ["lower"]; since = "1.0.0"; weight = 2786 };
  { key = "dropper.shape.cached_0126";                   label = "provisional_region_126";      arity = 7; tags = ["cached"; "runtime"; "hot"]; since = "1.8.3"; weight = 525 };
  { key = "pane.shape.cached_0127";                      label = "eager_crossbow_127";          arity = 2; tags = ["legacy"; "typed"; "async"]; since = "1.7.0"; weight = 4033 };
  { key = "team.shape.secondary_0128";                   label = "primary_shield_128";          arity = 3; tags = ["sync"; "async"]; since = "1.7.0"; weight = 2884 };
  { key = "npc.shape.strict_0129";                       label = "public_smoker_129";           arity = 2; tags = ["parse"; "emit"]; since = "1.0.0"; weight = 236 };
  { key = "region.shape.fallback_0130";                  label = "internal_conduit_130";        arity = 6; tags = ["emit"; "sync"]; since = "1.8.3"; weight = 1179 };
  { key = "dropper.shape.local_0131";                    label = "public_region_131";           arity = 3; tags = ["untyped"; "runtime"]; since = "1.4.0"; weight = 2144 };
  { key = "potion.shape.primary_0132";                   label = "eager_slot_132";              arity = 3; tags = ["hot"; "content"; "lower"]; since = "1.3.1"; weight = 3145 };
  { key = "campfire.shape.internal_0133";                label = "strict_biome_133";            arity = 5; tags = ["registry"; "legacy"]; since = "1.6.0"; weight = 657 };
  { key = "trident.shape.strict_0134";                   label = "local_banner_134";            arity = 4; tags = ["core"]; since = "1.6.0"; weight = 3128 };
  { key = "team.shape.fallback_0135";                    label = "loose_elytra_135";            arity = 2; tags = ["experimental"; "async"; "runtime"]; since = "1.2.0"; weight = 1016 };
  { key = "biome.shape.loose_0136";                      label = "stable_dispenser_136";        arity = 6; tags = ["parse"]; since = "1.7.0"; weight = 1625 };
  { key = "trade.shape.hidden_0137";                     label = "secondary_lectern_137";       arity = 7; tags = ["registry"; "parse"]; since = "1.0.0"; weight = 220 };
  { key = "barrel.shape.local_0138";                     label = "lazy_bossbar_138";            arity = 6; tags = ["lower"; "untyped"]; since = "1.7.0"; weight = 2663 };
  { key = "spawner.shape.strict_0139";                   label = "stable_trade_139";            arity = 4; tags = ["legacy"; "cached"]; since = "1.3.1"; weight = 357 };
  { key = "smithing.shape.fallback_0140";                label = "cached_entity_140";           arity = 4; tags = ["async"]; since = "1.0.0"; weight = 2387 };
  { key = "tablist.shape.global_0141";                   label = "eager_cartography_141";       arity = 0; tags = ["compat"; "async"; "content"]; since = "1.4.0"; weight = 2304 };
  { key = "grindstone.shape.global_0142";                label = "scoped_chunk_142";            arity = 7; tags = ["hot"; "legacy"; "core"]; since = "1.3.1"; weight = 3856 };
  { key = "team.shape.loose_0143";                       label = "legacy_campfire_143";         arity = 7; tags = ["compat"; "legacy"]; since = "1.5.2"; weight = 2924 };
  { key = "portal.shape.provisional_0144";               label = "internal_anvil_144";          arity = 4; tags = ["cached"]; since = "1.3.1"; weight = 816 };
  { key = "comparator.shape.fallback_0145";              label = "loose_conduit_145";           arity = 3; tags = ["legacy"; "emit"]; since = "1.9.0"; weight = 35 };
  { key = "structure.shape.eager_0146";                  label = "cached_bell_146";             arity = 6; tags = ["content"; "hot"]; since = "1.9.0"; weight = 1662 };
  { key = "pane.shape.scoped_0147";                      label = "derived_brewing_147";         arity = 7; tags = ["cached"; "async"; "legacy"]; since = "1.8.3"; weight = 3267 };
  { key = "attribute.shape.lazy_0148";                   label = "primary_beacon_148";          arity = 4; tags = ["cached"]; since = "1.7.0"; weight = 1191 };
  { key = "map.shape.canonical_0149";                    label = "secondary_arrow_149";         arity = 3; tags = ["sync"; "experimental"]; since = "1.4.0"; weight = 949 };
  { key = "anvil.shape.strict_0150";                     label = "cached_lectern_150";          arity = 3; tags = ["legacy"; "codegen"]; since = "1.8.3"; weight = 1812 };
  { key = "trident.shape.internal_0151";                 label = "hidden_sound_151";            arity = 2; tags = ["async"; "sync"]; since = "1.8.3"; weight = 2721 };
  { key = "world.shape.legacy_0152";                     label = "local_cartography_152";       arity = 4; tags = ["codegen"; "async"]; since = "1.8.3"; weight = 1291 };
  { key = "spawner.shape.strict_0153";                   label = "internal_sound_153";          arity = 0; tags = ["codegen"; "runtime"]; since = "1.2.0"; weight = 4028 };
  { key = "sound.shape.scoped_0154";                     label = "public_smoker_154";           arity = 3; tags = ["packet"; "parse"]; since = "1.5.2"; weight = 827 };
  { key = "observer.shape.primary_0155";                 label = "primary_spawner_155";         arity = 2; tags = ["packet"; "cached"; "sync"]; since = "1.8.3"; weight = 397 };
  { key = "player.shape.cached_0156";                    label = "cached_crossbow_156";         arity = 0; tags = ["compat"; "check"; "runtime"]; since = "1.6.0"; weight = 1553 };
  { key = "campfire.shape.primary_0157";                 label = "primary_compass_157";         arity = 5; tags = ["cold"; "codegen"]; since = "1.8.3"; weight = 2002 };
  { key = "bell.shape.hidden_0158";                      label = "modern_shield_158";           arity = 4; tags = ["emit"]; since = "1.0.0"; weight = 852 };
  { key = "pane.shape.secondary_0159";                   label = "hidden_brewing_159";          arity = 7; tags = ["typed"; "runtime"; "async"]; since = "1.6.0"; weight = 2943 };
  { key = "inventory.shape.loose_0160";                  label = "primary_region_160";          arity = 0; tags = ["emit"; "compat"; "untyped"]; since = "1.4.0"; weight = 3865 };
  { key = "item.shape.fallback_0161";                    label = "secondary_comparator_161";    arity = 5; tags = ["cold"; "typed"; "parse"]; since = "1.2.0"; weight = 2600 };
  { key = "block.shape.canonical_0162";                  label = "fallback_target_162";         arity = 6; tags = ["parse"; "untyped"]; since = "1.9.0"; weight = 2016 };
  { key = "anvil.shape.stable_0163";                     label = "provisional_villager_163";    arity = 3; tags = ["cold"]; since = "1.0.0"; weight = 1529 };
  { key = "bell.shape.hidden_0164";                      label = "primary_team_164";            arity = 5; tags = ["packet"]; since = "1.2.0"; weight = 2361 };
  { key = "smithing.shape.legacy_0165";                  label = "canonical_banner_165";        arity = 7; tags = ["packet"; "cold"; "runtime"]; since = "1.8.3"; weight = 227 };
  { key = "advancement.shape.fallback_0166";             label = "secondary_bell_166";          arity = 5; tags = ["async"; "hot"]; since = "1.7.0"; weight = 3921 };
  { key = "arrow.shape.primary_0167";                    label = "derived_hopper_167";          arity = 2; tags = ["check"]; since = "1.2.0"; weight = 2777 };
  { key = "chunk.shape.eager_0168";                      label = "primary_shulker_168";         arity = 6; tags = ["parse"; "registry"]; since = "1.8.3"; weight = 3061 };
  { key = "map.shape.internal_0169";                     label = "strict_hologram_169";         arity = 1; tags = ["registry"; "emit"]; since = "1.9.0"; weight = 354 };
  { key = "compass.shape.fallback_0170";                 label = "strict_tablist_170";          arity = 0; tags = ["sync"; "packet"; "async"]; since = "1.8.3"; weight = 2924 };
  { key = "stonecutter.shape.public_0171";               label = "global_sound_171";            arity = 4; tags = ["codegen"; "emit"]; since = "1.3.1"; weight = 2888 };
  { key = "particle.shape.lazy_0172";                    label = "derived_furnace_172";         arity = 1; tags = ["cached"; "experimental"]; since = "1.3.1"; weight = 3754 };
  { key = "shield.shape.provisional_0173";               label = "internal_cartography_173";    arity = 5; tags = ["runtime"; "parse"; "codegen"]; since = "1.9.0"; weight = 1026 };
  { key = "packet.shape.canonical_0174";                 label = "loose_shulker_174";           arity = 4; tags = ["packet"]; since = "1.8.3"; weight = 1353 };
  { key = "team.shape.secondary_0175";                   label = "eager_dropper_175";           arity = 0; tags = ["emit"]; since = "1.7.0"; weight = 352 };
  { key = "item.shape.global_0176";                      label = "lazy_barrel_176";             arity = 0; tags = ["core"; "untyped"]; since = "1.4.0"; weight = 4002 };
  { key = "slot.shape.modern_0177";                      label = "lazy_conduit_177";            arity = 0; tags = ["hot"; "cached"; "legacy"]; since = "1.2.0"; weight = 3126 };
  { key = "attribute.shape.fallback_0178";               label = "cached_arrow_178";            arity = 2; tags = ["async"; "parse"]; since = "1.7.0"; weight = 1578 };
  { key = "hopper.shape.local_0179";                     label = "modern_advancement_179";      arity = 3; tags = ["compat"; "cold"]; since = "1.0.0"; weight = 411 };
  { key = "villager.shape.secondary_0180";               label = "internal_dropper_180";        arity = 7; tags = ["hot"; "experimental"]; since = "1.8.3"; weight = 2824 };
  { key = "hopper.shape.fallback_0181";                  label = "canonical_player_181";        arity = 4; tags = ["parse"]; since = "1.9.0"; weight = 1368 };
  { key = "clock.shape.cached_0182";                     label = "primary_arrow_182";           arity = 4; tags = ["hot"; "typed"]; since = "1.5.2"; weight = 2293 };
  { key = "potion.shape.scoped_0183";                    label = "strict_portal_183";           arity = 4; tags = ["core"; "async"]; since = "1.4.0"; weight = 1747 };
  { key = "biome.shape.canonical_0184";                  label = "public_cartography_184";      arity = 7; tags = ["async"]; since = "1.0.0"; weight = 1831 };
  { key = "gui.shape.strict_0185";                       label = "strict_packet_185";           arity = 3; tags = ["untyped"; "cached"; "experimental"]; since = "1.2.0"; weight = 22 };
  { key = "clock.shape.provisional_0186";                label = "secondary_trade_186";         arity = 7; tags = ["experimental"]; since = "1.4.0"; weight = 3889 };
  { key = "minecart.shape.local_0187";                   label = "fallback_minecart_187";       arity = 5; tags = ["registry"; "sync"; "runtime"]; since = "1.4.0"; weight = 2045 };
  { key = "region.shape.public_0188";                    label = "fallback_structure_188";      arity = 3; tags = ["async"]; since = "1.7.0"; weight = 3590 };
  { key = "chunk.shape.primary_0189";                    label = "strict_bundle_189";           arity = 3; tags = ["async"]; since = "1.7.0"; weight = 1299 };
  { key = "boat.shape.secondary_0190";                   label = "loose_particle_190";          arity = 2; tags = ["emit"]; since = "1.3.1"; weight = 769 };
  { key = "trade.shape.loose_0191";                      label = "local_effect_191";            arity = 3; tags = ["cold"; "emit"; "cached"]; since = "1.2.0"; weight = 1845 };
  { key = "composter.shape.legacy_0192";                 label = "cached_enchant_192";          arity = 7; tags = ["parse"]; since = "1.3.1"; weight = 3825 };
  { key = "smithing.shape.cached_0193";                  label = "lazy_boat_193";               arity = 2; tags = ["experimental"; "sync"]; since = "1.3.1"; weight = 3904 };
  { key = "conduit.shape.lazy_0194";                     label = "eager_sound_194";             arity = 5; tags = ["hot"; "legacy"]; since = "1.2.0"; weight = 1242 };
  { key = "hopper.shape.eager_0195";                     label = "derived_block_195";           arity = 3; tags = ["packet"; "cold"]; since = "1.3.1"; weight = 3869 };
  { key = "hopper.shape.internal_0196";                  label = "public_crossbow_196";         arity = 1; tags = ["cached"]; since = "1.0.0"; weight = 3580 };
  { key = "brewing.shape.loose_0197";                    label = "secondary_conduit_197";       arity = 3; tags = ["typed"]; since = "1.8.3"; weight = 1089 };
  { key = "world.shape.legacy_0198";                     label = "global_banner_pattern_198";   arity = 1; tags = ["typed"; "registry"]; since = "1.7.0"; weight = 323 };
  { key = "sound.shape.lazy_0199";                       label = "secondary_banner_pattern_199"; arity = 6; tags = ["codegen"]; since = "1.6.0"; weight = 4033 };
  { key = "slot.shape.local_0200";                       label = "lazy_beacon_200";             arity = 6; tags = ["legacy"]; since = "1.4.0"; weight = 3454 };
  { key = "sound.shape.strict_0201";                     label = "loose_trident_201";           arity = 5; tags = ["typed"; "parse"; "sync"]; since = "1.7.0"; weight = 2592 };
  { key = "item.shape.loose_0202";                       label = "modern_biome_202";            arity = 7; tags = ["content"; "registry"; "async"]; since = "1.9.0"; weight = 1065 };
  { key = "biome.shape.internal_0203";                   label = "global_target_203";           arity = 4; tags = ["typed"; "content"]; since = "1.6.0"; weight = 3889 };
  { key = "slot.shape.legacy_0204";                      label = "fallback_entity_204";         arity = 2; tags = ["packet"; "sync"]; since = "1.7.0"; weight = 658 };
  { key = "team.shape.legacy_0205";                      label = "local_slot_205";              arity = 4; tags = ["core"; "compat"]; since = "1.9.0"; weight = 1493 };
  { key = "rail.shape.loose_0206";                       label = "fallback_chunk_206";          arity = 7; tags = ["cold"; "compat"]; since = "1.9.0"; weight = 814 };
  { key = "scoreboard.shape.provisional_0207";           label = "modern_firework_207";         arity = 1; tags = ["cold"; "compat"]; since = "1.9.0"; weight = 1050 };
  { key = "stonecutter.shape.fallback_0208";             label = "scoped_beacon_208";           arity = 1; tags = ["check"]; since = "1.7.0"; weight = 3467 };
  { key = "objective.shape.primary_0209";                label = "loose_entity_209";            arity = 4; tags = ["hot"; "cached"]; since = "1.4.0"; weight = 892 };
  { key = "entity.shape.secondary_0210";                 label = "scoped_shield_210";           arity = 2; tags = ["async"; "core"]; since = "1.9.0"; weight = 1255 };
  { key = "crossbow.shape.canonical_0211";               label = "fallback_repeater_211";       arity = 1; tags = ["typed"]; since = "1.4.0"; weight = 103 };
  { key = "slot.shape.fallback_0212";                    label = "cached_world_212";            arity = 3; tags = ["runtime"]; since = "1.3.1"; weight = 520 };
  { key = "team.shape.scoped_0213";                      label = "secondary_spawner_213";       arity = 1; tags = ["content"]; since = "1.4.0"; weight = 3640 };
  { key = "shield.shape.cached_0214";                    label = "provisional_shield_214";      arity = 7; tags = ["codegen"; "content"; "compat"]; since = "1.3.1"; weight = 1299 };
  { key = "potion.shape.scoped_0215";                    label = "primary_trident_215";         arity = 0; tags = ["lower"; "content"]; since = "1.4.0"; weight = 3460 };
  { key = "hologram.shape.modern_0216";                  label = "strict_compass_216";          arity = 5; tags = ["cached"]; since = "1.9.0"; weight = 3297 };
  { key = "banner_pattern.shape.strict_0217";            label = "local_elytra_217";            arity = 3; tags = ["parse"; "hot"]; since = "1.7.0"; weight = 3385 };
  { key = "structure.shape.canonical_0218";              label = "stable_trade_218";            arity = 4; tags = ["parse"; "experimental"; "compat"]; since = "1.3.1"; weight = 1571 };
  { key = "villager.shape.scoped_0219";                  label = "provisional_effect_219";      arity = 7; tags = ["hot"]; since = "1.4.0"; weight = 2010 };
  { key = "trade.shape.internal_0220";                   label = "global_chunk_220";            arity = 5; tags = ["legacy"; "experimental"; "cold"]; since = "1.5.2"; weight = 3399 };
  { key = "brewing.shape.legacy_0221";                   label = "primary_entity_221";          arity = 4; tags = ["check"]; since = "1.4.0"; weight = 1240 };
  { key = "shield.shape.provisional_0222";               label = "scoped_scoreboard_222";       arity = 4; tags = ["async"]; since = "1.6.0"; weight = 3581 };
  { key = "packet.shape.modern_0223";                    label = "eager_biome_223";             arity = 5; tags = ["async"; "content"; "typed"]; since = "1.8.3"; weight = 120 };
  { key = "boat.shape.stable_0224";                      label = "provisional_structure_224";   arity = 7; tags = ["runtime"; "compat"; "codegen"]; since = "1.7.0"; weight = 1844 };
  { key = "rail.shape.legacy_0225";                      label = "lazy_anvil_225";              arity = 1; tags = ["runtime"; "experimental"]; since = "1.3.1"; weight = 3330 };
  { key = "npc.shape.hidden_0226";                       label = "modern_villager_226";         arity = 3; tags = ["experimental"; "compat"]; since = "1.6.0"; weight = 2182 };
  { key = "map.shape.public_0227";                       label = "hidden_trade_227";            arity = 6; tags = ["runtime"; "check"; "cold"]; since = "1.7.0"; weight = 2580 };
  { key = "loom.shape.local_0228";                       label = "cached_lectern_228";          arity = 2; tags = ["sync"]; since = "1.8.3"; weight = 3772 };
  { key = "bossbar.shape.derived_0229";                  label = "public_scoreboard_229";       arity = 3; tags = ["codegen"]; since = "1.7.0"; weight = 467 };
  { key = "rail.shape.modern_0230";                      label = "global_inventory_230";        arity = 4; tags = ["legacy"; "experimental"; "typed"]; since = "1.5.2"; weight = 393 };
  { key = "structure.shape.local_0231";                  label = "provisional_item_231";        arity = 1; tags = ["check"; "async"]; since = "1.9.0"; weight = 1122 };
  { key = "dropper.shape.strict_0232";                   label = "modern_comparator_232";       arity = 6; tags = ["registry"; "compat"]; since = "1.6.0"; weight = 3397 };
  { key = "trade.shape.eager_0233";                      label = "derived_smithing_233";        arity = 2; tags = ["lower"; "hot"]; since = "1.2.0"; weight = 1003 };
  { key = "boat.shape.global_0234";                      label = "internal_loom_234";           arity = 7; tags = ["cold"]; since = "1.6.0"; weight = 1277 };
  { key = "compass.shape.canonical_0235";                label = "hidden_cartography_235";      arity = 3; tags = ["untyped"; "typed"; "compat"]; since = "1.3.1"; weight = 2845 };
  { key = "item.shape.provisional_0236";                 label = "secondary_observer_236";      arity = 7; tags = ["lower"; "experimental"]; since = "1.5.2"; weight = 1725 };
  { key = "comparator.shape.loose_0237";                 label = "lazy_chunk_237";              arity = 2; tags = ["lower"; "untyped"; "runtime"]; since = "1.7.0"; weight = 191 };
  { key = "item.shape.stable_0238";                      label = "local_objective_238";         arity = 6; tags = ["core"; "compat"]; since = "1.2.0"; weight = 2355 };
  { key = "banner.shape.legacy_0239";                    label = "canonical_arrow_239";         arity = 1; tags = ["cached"; "registry"; "cold"]; since = "1.3.1"; weight = 3520 };
  { key = "bundle.shape.stable_0240";                    label = "fallback_particle_240";       arity = 1; tags = ["content"; "legacy"; "untyped"]; since = "1.3.1"; weight = 3266 };
  { key = "anvil.shape.public_0241";                     label = "fallback_shulker_241";        arity = 5; tags = ["parse"]; since = "1.5.2"; weight = 795 };
  { key = "banner_pattern.shape.primary_0242";           label = "internal_map_242";            arity = 4; tags = ["sync"]; since = "1.0.0"; weight = 2458 };
  { key = "bell.shape.scoped_0243";                      label = "global_packet_243";           arity = 1; tags = ["legacy"; "async"]; since = "1.0.0"; weight = 3181 };
  { key = "trident.shape.strict_0244";                   label = "legacy_smoker_244";           arity = 2; tags = ["untyped"; "core"; "packet"]; since = "1.7.0"; weight = 545 };
  { key = "entity.shape.secondary_0245";                 label = "stable_region_245";           arity = 5; tags = ["lower"; "runtime"]; since = "1.7.0"; weight = 698 };
  { key = "chunk.shape.internal_0246";                   label = "canonical_entity_246";        arity = 1; tags = ["runtime"; "core"; "untyped"]; since = "1.4.0"; weight = 837 };
  { key = "brewing.shape.public_0247";                   label = "provisional_campfire_247";    arity = 1; tags = ["sync"; "cached"; "core"]; since = "1.5.2"; weight = 3178 };
  { key = "boat.shape.hidden_0248";                      label = "modern_barrel_248";           arity = 4; tags = ["core"; "codegen"]; since = "1.9.0"; weight = 1610 };
  { key = "shulker.shape.stable_0249";                   label = "global_elytra_249";           arity = 4; tags = ["registry"; "legacy"]; since = "1.7.0"; weight = 2983 };
  { key = "gui.shape.fallback_0250";                     label = "legacy_stonecutter_250";      arity = 5; tags = ["codegen"; "check"; "parse"]; since = "1.7.0"; weight = 1648 };
  { key = "team.shape.loose_0251";                       label = "legacy_gui_251";              arity = 2; tags = ["emit"; "check"]; since = "1.5.2"; weight = 3019 };
  { key = "effect.shape.global_0252";                    label = "public_trident_252";          arity = 0; tags = ["untyped"; "sync"]; since = "1.6.0"; weight = 2333 };
  { key = "particle.shape.fallback_0253";                label = "cached_loom_253";             arity = 5; tags = ["legacy"; "typed"; "codegen"]; since = "1.6.0"; weight = 2191 };
  { key = "dispenser.shape.legacy_0254";                 label = "scoped_chunk_254";            arity = 5; tags = ["hot"; "registry"]; since = "1.4.0"; weight = 3814 };
  { key = "target.shape.stable_0255";                    label = "lazy_hopper_255";             arity = 1; tags = ["compat"]; since = "1.8.3"; weight = 1125 };
  { key = "barrel.shape.global_0256";                    label = "global_crossbow_256";         arity = 7; tags = ["packet"]; since = "1.7.0"; weight = 1185 };
  { key = "block.shape.derived_0257";                    label = "fallback_clock_257";          arity = 4; tags = ["codegen"; "check"; "packet"]; since = "1.7.0"; weight = 3714 };
  { key = "inventory.shape.global_0258";                 label = "local_gui_258";               arity = 7; tags = ["experimental"; "codegen"]; since = "1.3.1"; weight = 2998 };
  { key = "firework.shape.public_0259";                  label = "secondary_hopper_259";        arity = 5; tags = ["lower"]; since = "1.6.0"; weight = 124 };
  { key = "slot.shape.canonical_0260";                   label = "secondary_conduit_260";       arity = 2; tags = ["check"; "experimental"]; since = "1.7.0"; weight = 3185 };
  { key = "scoreboard.shape.primary_0261";               label = "provisional_banner_261";      arity = 0; tags = ["emit"]; since = "1.4.0"; weight = 1135 };
  { key = "portal.shape.eager_0262";                     label = "global_map_262";              arity = 0; tags = ["emit"]; since = "1.3.1"; weight = 3711 };
  { key = "minecart.shape.stable_0263";                  label = "derived_rail_263";            arity = 7; tags = ["parse"; "legacy"; "untyped"]; since = "1.9.0"; weight = 3629 };
  { key = "effect.shape.derived_0264";                   label = "legacy_spawner_264";          arity = 7; tags = ["hot"; "codegen"; "compat"]; since = "1.4.0"; weight = 264 };
  { key = "crossbow.shape.primary_0265";                 label = "derived_banner_pattern_265";  arity = 2; tags = ["legacy"]; since = "1.8.3"; weight = 1057 };
  { key = "crossbow.shape.secondary_0266";               label = "public_particle_266";         arity = 2; tags = ["content"; "emit"; "compat"]; since = "1.6.0"; weight = 3477 };
  { key = "region.shape.legacy_0267";                    label = "strict_dropper_267";          arity = 3; tags = ["packet"]; since = "1.3.1"; weight = 3801 };
  { key = "beacon.shape.lazy_0268";                      label = "loose_item_268";              arity = 2; tags = ["legacy"]; since = "1.9.0"; weight = 1807 };
  { key = "observer.shape.stable_0269";                  label = "local_effect_269";            arity = 1; tags = ["cached"; "cold"; "check"]; since = "1.8.3"; weight = 4020 };
  { key = "compass.shape.local_0270";                    label = "canonical_smoker_270";        arity = 7; tags = ["async"; "cold"]; since = "1.6.0"; weight = 104 };
  { key = "boat.shape.public_0271";                      label = "stable_inventory_271";        arity = 3; tags = ["cold"]; since = "1.0.0"; weight = 4022 };
  { key = "entity.shape.global_0272";                    label = "canonical_map_272";           arity = 7; tags = ["sync"]; since = "1.9.0"; weight = 4096 };
  { key = "objective.shape.secondary_0273";              label = "fallback_elytra_273";         arity = 6; tags = ["packet"; "registry"; "cached"]; since = "1.8.3"; weight = 2762 };
  { key = "cartography.shape.canonical_0274";            label = "strict_rail_274";             arity = 6; tags = ["codegen"; "content"]; since = "1.2.0"; weight = 219 };
  { key = "brewing.shape.derived_0275";                  label = "lazy_enchant_275";            arity = 7; tags = ["content"]; since = "1.3.1"; weight = 4015 };
  { key = "trident.shape.provisional_0276";              label = "public_chunk_276";            arity = 6; tags = ["parse"; "cached"; "sync"]; since = "1.3.1"; weight = 2095 };
  { key = "biome.shape.legacy_0277";                     label = "public_structure_277";        arity = 3; tags = ["experimental"; "hot"; "core"]; since = "1.2.0"; weight = 3037 };
  { key = "banner_pattern.shape.public_0278";            label = "local_trade_278";             arity = 3; tags = ["lower"; "core"; "sync"]; since = "1.4.0"; weight = 1331 };
  { key = "slot.shape.fallback_0279";                    label = "primary_rail_279";            arity = 2; tags = ["untyped"]; since = "1.0.0"; weight = 3620 };
  { key = "pane.shape.primary_0280";                     label = "canonical_attribute_280";     arity = 1; tags = ["core"; "typed"]; since = "1.7.0"; weight = 820 };
  { key = "map.shape.hidden_0281";                       label = "fallback_slot_281";           arity = 7; tags = ["codegen"; "lower"; "legacy"]; since = "1.6.0"; weight = 894 };
  { key = "tablist.shape.public_0282";                   label = "eager_bundle_282";            arity = 3; tags = ["content"; "sync"]; since = "1.7.0"; weight = 2390 };
  { key = "player.shape.scoped_0283";                    label = "hidden_repeater_283";         arity = 2; tags = ["content"; "parse"; "untyped"]; since = "1.4.0"; weight = 1217 };
  { key = "arrow.shape.derived_0284";                    label = "provisional_smithing_284";    arity = 0; tags = ["hot"; "packet"; "experimental"]; since = "1.9.0"; weight = 3462 };
  { key = "compass.shape.derived_0285";                  label = "local_lectern_285";           arity = 2; tags = ["untyped"]; since = "1.3.1"; weight = 3722 };
  { key = "boat.shape.cached_0286";                      label = "internal_sound_286";          arity = 6; tags = ["packet"]; since = "1.4.0"; weight = 173 };
  { key = "world.shape.global_0287";                     label = "hidden_hologram_287";         arity = 6; tags = ["check"; "lower"]; since = "1.0.0"; weight = 2535 };
  { key = "tablist.shape.primary_0288";                  label = "lazy_dropper_288";            arity = 1; tags = ["check"; "core"]; since = "1.3.1"; weight = 329 };
  { key = "lectern.shape.canonical_0289";                label = "canonical_npc_289";           arity = 3; tags = ["experimental"]; since = "1.6.0"; weight = 1823 };
  { key = "minecart.shape.public_0290";                  label = "primary_observer_290";        arity = 3; tags = ["content"; "emit"]; since = "1.3.1"; weight = 471 };
  { key = "particle.shape.legacy_0291";                  label = "hidden_trade_291";            arity = 4; tags = ["core"]; since = "1.5.2"; weight = 3594 };
  { key = "boat.shape.secondary_0292";                   label = "modern_gui_292";              arity = 2; tags = ["cold"; "core"]; since = "1.6.0"; weight = 761 };
  { key = "villager.shape.legacy_0293";                  label = "lazy_smithing_293";           arity = 6; tags = ["runtime"; "typed"]; since = "1.5.2"; weight = 271 };
  { key = "player.shape.eager_0294";                     label = "cached_structure_294";        arity = 1; tags = ["typed"]; since = "1.7.0"; weight = 3296 };
  { key = "chunk.shape.stable_0295";                     label = "scoped_trident_295";          arity = 6; tags = ["registry"; "async"; "core"]; since = "1.3.1"; weight = 3070 };
  { key = "rail.shape.loose_0296";                       label = "fallback_shulker_296";        arity = 7; tags = ["compat"; "cold"; "runtime"]; since = "1.4.0"; weight = 3103 };
  { key = "dropper.shape.secondary_0297";                label = "local_furnace_297";           arity = 6; tags = ["legacy"; "cold"]; since = "1.7.0"; weight = 290 };
  { key = "lectern.shape.fallback_0298";                 label = "internal_dropper_298";        arity = 2; tags = ["cold"; "lower"; "parse"]; since = "1.3.1"; weight = 3675 };
]

let count = List.length entries

let table : (string, shape_entry) Hashtbl.t =
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
