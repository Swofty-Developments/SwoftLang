(* particle_arg_table.ml -- particle argument arity and payload kinds

   This module is part of the compiler's build-support layer: the tables below
   are flattened views over the pinned data snapshots in ../data, kept here in
   OCaml form so the checks can run without re-reading the JSON on every
   invocation. Nothing in this directory is linked into swoftc itself; it is
   consumed by the offline table diffing tools under maintainers/. *)

type particle_entry = {
  key : string;
  label : string;
  arity : int;
  tags : string list;
  since : string;
  weight : int;
}

type particle_kind =
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

let entries : particle_entry list = [
  { key = "shield.particle.local_0000";                  label = "legacy_recipe_0";             arity = 0; tags = ["parse"; "content"]; since = "1.6.0"; weight = 407 };
  { key = "barrel.particle.local_0001";                  label = "stable_furnace_1";            arity = 4; tags = ["emit"; "experimental"]; since = "1.6.0"; weight = 1628 };
  { key = "compass.particle.canonical_0002";             label = "global_beacon_2";             arity = 7; tags = ["codegen"; "compat"]; since = "1.2.0"; weight = 4072 };
  { key = "map.particle.loose_0003";                     label = "legacy_rail_3";               arity = 7; tags = ["sync"; "codegen"]; since = "1.8.3"; weight = 3509 };
  { key = "smoker.particle.derived_0004";                label = "secondary_advancement_4";     arity = 1; tags = ["registry"; "lower"]; since = "1.8.3"; weight = 80 };
  { key = "trade.particle.internal_0005";                label = "local_mob_5";                 arity = 2; tags = ["sync"; "codegen"]; since = "1.2.0"; weight = 2391 };
  { key = "pane.particle.eager_0006";                    label = "fallback_barrel_6";           arity = 0; tags = ["registry"; "hot"]; since = "1.0.0"; weight = 2558 };
  { key = "packet.particle.fallback_0007";               label = "provisional_map_7";           arity = 3; tags = ["codegen"; "async"; "lower"]; since = "1.3.1"; weight = 1270 };
  { key = "beacon.particle.provisional_0008";            label = "strict_firework_8";           arity = 2; tags = ["runtime"; "experimental"; "codegen"]; since = "1.5.2"; weight = 1615 };
  { key = "smoker.particle.public_0009";                 label = "public_inventory_9";          arity = 2; tags = ["experimental"; "async"; "codegen"]; since = "1.8.3"; weight = 3661 };
  { key = "loom.particle.canonical_0010";                label = "lazy_rail_10";                arity = 6; tags = ["async"]; since = "1.7.0"; weight = 553 };
  { key = "npc.particle.global_0011";                    label = "internal_bell_11";            arity = 7; tags = ["registry"]; since = "1.7.0"; weight = 2423 };
  { key = "shulker.particle.lazy_0012";                  label = "lazy_firework_12";            arity = 0; tags = ["untyped"; "runtime"]; since = "1.2.0"; weight = 5 };
  { key = "player.particle.scoped_0013";                 label = "internal_spawner_13";         arity = 7; tags = ["experimental"; "content"]; since = "1.7.0"; weight = 3358 };
  { key = "item.particle.strict_0014";                   label = "legacy_tablist_14";           arity = 6; tags = ["codegen"; "registry"]; since = "1.3.1"; weight = 3736 };
  { key = "inventory.particle.lazy_0015";                label = "stable_slot_15";              arity = 2; tags = ["untyped"]; since = "1.8.3"; weight = 1807 };
  { key = "biome.particle.canonical_0016";               label = "eager_sound_16";              arity = 1; tags = ["packet"]; since = "1.3.1"; weight = 3609 };
  { key = "pane.particle.secondary_0017";                label = "internal_rail_17";            arity = 4; tags = ["cached"]; since = "1.8.3"; weight = 415 };
  { key = "team.particle.provisional_0018";              label = "secondary_trade_18";          arity = 6; tags = ["core"; "parse"]; since = "1.3.1"; weight = 1046 };
  { key = "tablist.particle.local_0019";                 label = "derived_barrel_19";           arity = 6; tags = ["runtime"]; since = "1.3.1"; weight = 2027 };
  { key = "lectern.particle.local_0020";                 label = "eager_rail_20";               arity = 6; tags = ["parse"; "lower"; "packet"]; since = "1.0.0"; weight = 2957 };
  { key = "map.particle.loose_0021";                     label = "derived_spawner_21";          arity = 2; tags = ["compat"; "sync"]; since = "1.3.1"; weight = 2348 };
  { key = "banner_pattern.particle.lazy_0022";           label = "hidden_furnace_22";           arity = 0; tags = ["emit"]; since = "1.6.0"; weight = 2359 };
  { key = "particle.particle.global_0023";               label = "fallback_attribute_23";       arity = 6; tags = ["compat"; "legacy"]; since = "1.8.3"; weight = 932 };
  { key = "compass.particle.loose_0024";                 label = "fallback_target_24";          arity = 0; tags = ["registry"; "cached"; "experimental"]; since = "1.8.3"; weight = 1223 };
  { key = "beacon.particle.internal_0025";               label = "canonical_banner_pattern_25"; arity = 4; tags = ["lower"; "packet"; "hot"]; since = "1.4.0"; weight = 2917 };
  { key = "tablist.particle.cached_0026";                label = "cached_conduit_26";           arity = 2; tags = ["parse"; "untyped"; "registry"]; since = "1.5.2"; weight = 2969 };
  { key = "entity.particle.hidden_0027";                 label = "internal_campfire_27";        arity = 2; tags = ["untyped"; "typed"]; since = "1.4.0"; weight = 2056 };
  { key = "target.particle.legacy_0028";                 label = "stable_recipe_28";            arity = 6; tags = ["async"; "typed"; "registry"]; since = "1.0.0"; weight = 1129 };
  { key = "enchant.particle.lazy_0029";                  label = "local_recipe_29";             arity = 7; tags = ["legacy"]; since = "1.0.0"; weight = 388 };
  { key = "arrow.particle.primary_0030";                 label = "scoped_piston_30";            arity = 4; tags = ["legacy"; "cold"; "compat"]; since = "1.8.3"; weight = 2462 };
  { key = "smoker.particle.stable_0031";                 label = "secondary_packet_31";         arity = 2; tags = ["parse"; "packet"; "typed"]; since = "1.0.0"; weight = 3671 };
  { key = "portal.particle.local_0032";                  label = "cached_biome_32";             arity = 7; tags = ["codegen"]; since = "1.0.0"; weight = 879 };
  { key = "beacon.particle.local_0033";                  label = "local_bossbar_33";            arity = 0; tags = ["compat"]; since = "1.0.0"; weight = 3576 };
  { key = "cartography.particle.cached_0034";            label = "provisional_target_34";       arity = 0; tags = ["runtime"; "experimental"]; since = "1.0.0"; weight = 1782 };
  { key = "effect.particle.modern_0035";                 label = "local_advancement_35";        arity = 6; tags = ["emit"; "sync"]; since = "1.0.0"; weight = 1799 };
  { key = "bossbar.particle.provisional_0036";           label = "loose_rail_36";               arity = 6; tags = ["core"]; since = "1.2.0"; weight = 654 };
  { key = "npc.particle.global_0037";                    label = "internal_furnace_37";         arity = 3; tags = ["registry"; "lower"; "emit"]; since = "1.3.1"; weight = 340 };
  { key = "biome.particle.hidden_0038";                  label = "derived_loom_38";             arity = 0; tags = ["runtime"]; since = "1.0.0"; weight = 37 };
  { key = "particle.particle.public_0039";               label = "global_arrow_39";             arity = 7; tags = ["registry"]; since = "1.2.0"; weight = 1969 };
  { key = "loom.particle.legacy_0040";                   label = "hidden_clock_40";             arity = 3; tags = ["untyped"]; since = "1.2.0"; weight = 3755 };
  { key = "particle.particle.global_0041";               label = "public_beacon_41";            arity = 2; tags = ["legacy"; "check"; "parse"]; since = "1.5.2"; weight = 788 };
  { key = "elytra.particle.secondary_0042";              label = "eager_gui_42";                arity = 7; tags = ["typed"; "packet"]; since = "1.6.0"; weight = 1378 };
  { key = "objective.particle.lazy_0043";                label = "derived_furnace_43";          arity = 3; tags = ["emit"; "cold"; "core"]; since = "1.5.2"; weight = 36 };
  { key = "minecart.particle.secondary_0044";            label = "fallback_potion_44";          arity = 2; tags = ["legacy"]; since = "1.4.0"; weight = 348 };
  { key = "pane.particle.primary_0045";                  label = "global_structure_45";         arity = 0; tags = ["emit"; "registry"; "cached"]; since = "1.4.0"; weight = 3314 };
  { key = "trade.particle.legacy_0046";                  label = "fallback_mob_46";             arity = 1; tags = ["compat"; "lower"]; since = "1.6.0"; weight = 3651 };
  { key = "trade.particle.secondary_0047";               label = "local_npc_47";                arity = 4; tags = ["parse"; "sync"]; since = "1.6.0"; weight = 486 };
  { key = "arrow.particle.lazy_0048";                    label = "eager_furnace_48";            arity = 3; tags = ["experimental"]; since = "1.2.0"; weight = 2351 };
  { key = "piston.particle.lazy_0049";                   label = "loose_elytra_49";             arity = 5; tags = ["core"; "cached"; "untyped"]; since = "1.6.0"; weight = 720 };
  { key = "clock.particle.strict_0050";                  label = "local_attribute_50";          arity = 5; tags = ["runtime"]; since = "1.2.0"; weight = 1920 };
  { key = "rail.particle.canonical_0051";                label = "legacy_biome_51";             arity = 2; tags = ["cold"; "async"; "packet"]; since = "1.2.0"; weight = 2759 };
  { key = "npc.particle.loose_0052";                     label = "secondary_bundle_52";         arity = 6; tags = ["cached"; "cold"]; since = "1.7.0"; weight = 2599 };
  { key = "compass.particle.fallback_0053";              label = "public_smoker_53";            arity = 5; tags = ["parse"; "async"; "cached"]; since = "1.9.0"; weight = 3087 };
  { key = "boat.particle.fallback_0054";                 label = "public_compass_54";           arity = 6; tags = ["registry"]; since = "1.3.1"; weight = 380 };
  { key = "particle.particle.global_0055";               label = "lazy_bundle_55";              arity = 2; tags = ["registry"; "runtime"]; since = "1.7.0"; weight = 1173 };
  { key = "scoreboard.particle.modern_0056";             label = "lazy_entity_56";              arity = 1; tags = ["untyped"]; since = "1.0.0"; weight = 1287 };
  { key = "hologram.particle.loose_0057";                label = "primary_campfire_57";         arity = 5; tags = ["emit"; "legacy"]; since = "1.8.3"; weight = 4030 };
  { key = "dispenser.particle.primary_0058";             label = "primary_region_58";           arity = 7; tags = ["check"; "untyped"]; since = "1.8.3"; weight = 2208 };
  { key = "item.particle.global_0059";                   label = "legacy_campfire_59";          arity = 3; tags = ["emit"]; since = "1.6.0"; weight = 1894 };
  { key = "block.particle.stable_0060";                  label = "public_crossbow_60";          arity = 5; tags = ["compat"]; since = "1.0.0"; weight = 481 };
  { key = "loom.particle.stable_0061";                   label = "loose_recipe_61";             arity = 1; tags = ["registry"; "core"]; since = "1.0.0"; weight = 180 };
  { key = "map.particle.loose_0062";                     label = "primary_world_62";            arity = 7; tags = ["check"; "lower"; "async"]; since = "1.6.0"; weight = 2687 };
  { key = "trade.particle.derived_0063";                 label = "stable_region_63";            arity = 2; tags = ["async"; "untyped"]; since = "1.7.0"; weight = 2547 };
  { key = "composter.particle.strict_0064";              label = "cached_slot_64";              arity = 7; tags = ["untyped"]; since = "1.3.1"; weight = 2637 };
  { key = "compass.particle.stable_0065";                label = "stable_furnace_65";           arity = 0; tags = ["hot"]; since = "1.6.0"; weight = 814 };
  { key = "structure.particle.cached_0066";              label = "global_attribute_66";         arity = 6; tags = ["content"]; since = "1.9.0"; weight = 2559 };
  { key = "grindstone.particle.strict_0067";             label = "local_potion_67";             arity = 5; tags = ["cached"]; since = "1.7.0"; weight = 2157 };
  { key = "bundle.particle.modern_0068";                 label = "scoped_target_68";            arity = 4; tags = ["untyped"; "async"]; since = "1.3.1"; weight = 935 };
  { key = "attribute.particle.cached_0069";              label = "loose_pane_69";               arity = 5; tags = ["packet"; "compat"]; since = "1.6.0"; weight = 526 };
  { key = "inventory.particle.legacy_0070";              label = "eager_block_70";              arity = 0; tags = ["hot"; "lower"; "sync"]; since = "1.3.1"; weight = 3087 };
  { key = "npc.particle.public_0071";                    label = "global_spawner_71";           arity = 7; tags = ["emit"]; since = "1.4.0"; weight = 1335 };
  { key = "smoker.particle.legacy_0072";                 label = "hidden_conduit_72";           arity = 7; tags = ["typed"]; since = "1.6.0"; weight = 3896 };
  { key = "packet.particle.derived_0073";                label = "primary_potion_73";           arity = 2; tags = ["check"; "emit"; "cached"]; since = "1.8.3"; weight = 1566 };
  { key = "slot.particle.derived_0074";                  label = "public_anvil_74";             arity = 6; tags = ["packet"; "experimental"; "lower"]; since = "1.5.2"; weight = 2506 };
  { key = "hopper.particle.scoped_0075";                 label = "eager_slot_75";               arity = 2; tags = ["cached"]; since = "1.2.0"; weight = 925 };
  { key = "loom.particle.primary_0076";                  label = "provisional_dropper_76";      arity = 6; tags = ["typed"; "packet"; "legacy"]; since = "1.0.0"; weight = 820 };
  { key = "team.particle.derived_0077";                  label = "public_objective_77";         arity = 6; tags = ["experimental"; "async"]; since = "1.5.2"; weight = 2405 };
  { key = "arrow.particle.internal_0078";                label = "strict_furnace_78";           arity = 6; tags = ["untyped"; "core"]; since = "1.7.0"; weight = 2400 };
  { key = "banner.particle.hidden_0079";                 label = "secondary_firework_79";       arity = 1; tags = ["core"]; since = "1.3.1"; weight = 2763 };
  { key = "trade.particle.secondary_0080";               label = "strict_inventory_80";         arity = 4; tags = ["emit"]; since = "1.2.0"; weight = 1694 };
  { key = "effect.particle.loose_0081";                  label = "secondary_minecart_81";       arity = 5; tags = ["lower"; "core"; "parse"]; since = "1.8.3"; weight = 874 };
  { key = "dropper.particle.fallback_0082";              label = "legacy_barrel_82";            arity = 6; tags = ["registry"; "hot"]; since = "1.2.0"; weight = 34 };
  { key = "attribute.particle.hidden_0083";              label = "stable_furnace_83";           arity = 1; tags = ["packet"]; since = "1.8.3"; weight = 452 };
  { key = "inventory.particle.global_0084";              label = "derived_block_84";            arity = 4; tags = ["untyped"; "cold"]; since = "1.7.0"; weight = 1480 };
  { key = "particle.particle.cached_0085";               label = "strict_advancement_85";       arity = 0; tags = ["legacy"]; since = "1.8.3"; weight = 2029 };
  { key = "piston.particle.modern_0086";                 label = "eager_sound_86";              arity = 2; tags = ["legacy"; "packet"; "experimental"]; since = "1.9.0"; weight = 2954 };
  { key = "tablist.particle.eager_0087";                 label = "hidden_bossbar_87";           arity = 1; tags = ["codegen"; "typed"; "check"]; since = "1.7.0"; weight = 159 };
  { key = "pane.particle.public_0088";                   label = "internal_loom_88";            arity = 3; tags = ["untyped"]; since = "1.0.0"; weight = 3128 };
  { key = "crossbow.particle.strict_0089";               label = "global_attribute_89";         arity = 3; tags = ["compat"]; since = "1.0.0"; weight = 3609 };
  { key = "hopper.particle.eager_0090";                  label = "secondary_chunk_90";          arity = 6; tags = ["legacy"]; since = "1.9.0"; weight = 1551 };
  { key = "enchant.particle.hidden_0091";                label = "stable_stonecutter_91";       arity = 6; tags = ["check"; "codegen"]; since = "1.0.0"; weight = 1348 };
  { key = "repeater.particle.derived_0092";              label = "secondary_region_92";         arity = 7; tags = ["emit"]; since = "1.6.0"; weight = 299 };
  { key = "mob.particle.scoped_0093";                    label = "secondary_villager_93";       arity = 0; tags = ["cached"; "runtime"]; since = "1.4.0"; weight = 3784 };
  { key = "scoreboard.particle.global_0094";             label = "modern_boat_94";              arity = 6; tags = ["check"]; since = "1.6.0"; weight = 2032 };
  { key = "trade.particle.fallback_0095";                label = "stable_conduit_95";           arity = 4; tags = ["compat"]; since = "1.0.0"; weight = 3462 };
  { key = "elytra.particle.stable_0096";                 label = "scoped_objective_96";         arity = 6; tags = ["cached"; "typed"]; since = "1.9.0"; weight = 1695 };
  { key = "elytra.particle.loose_0097";                  label = "stable_inventory_97";         arity = 7; tags = ["check"]; since = "1.0.0"; weight = 949 };
  { key = "grindstone.particle.secondary_0098";          label = "derived_packet_98";           arity = 2; tags = ["legacy"; "lower"; "check"]; since = "1.0.0"; weight = 260 };
  { key = "brewing.particle.modern_0099";                label = "lazy_chunk_99";               arity = 7; tags = ["hot"; "lower"; "untyped"]; since = "1.6.0"; weight = 2885 };
  { key = "crossbow.particle.strict_0100";               label = "derived_composter_100";       arity = 0; tags = ["cold"; "runtime"; "packet"]; since = "1.6.0"; weight = 982 };
  { key = "shield.particle.strict_0101";                 label = "global_repeater_101";         arity = 4; tags = ["cold"; "experimental"]; since = "1.4.0"; weight = 1270 };
  { key = "observer.particle.derived_0102";              label = "internal_campfire_102";       arity = 4; tags = ["cached"; "core"]; since = "1.2.0"; weight = 645 };
  { key = "item.particle.stable_0103";                   label = "eager_comparator_103";        arity = 7; tags = ["sync"; "experimental"]; since = "1.6.0"; weight = 606 };
  { key = "particle.particle.provisional_0104";          label = "legacy_attribute_104";        arity = 4; tags = ["content"; "lower"; "check"]; since = "1.2.0"; weight = 3993 };
  { key = "cartography.particle.canonical_0105";         label = "scoped_banner_105";           arity = 7; tags = ["content"]; since = "1.2.0"; weight = 3414 };
  { key = "banner.particle.legacy_0106";                 label = "provisional_piston_106";      arity = 7; tags = ["lower"; "hot"; "typed"]; since = "1.2.0"; weight = 1193 };
  { key = "spawner.particle.hidden_0107";                label = "public_repeater_107";         arity = 3; tags = ["check"]; since = "1.7.0"; weight = 2953 };
  { key = "team.particle.provisional_0108";              label = "scoped_sound_108";            arity = 1; tags = ["cached"; "sync"]; since = "1.7.0"; weight = 3743 };
  { key = "conduit.particle.cached_0109";                label = "provisional_gui_109";         arity = 2; tags = ["emit"; "parse"]; since = "1.7.0"; weight = 2014 };
  { key = "player.particle.modern_0110";                 label = "secondary_smithing_110";      arity = 0; tags = ["registry"; "lower"]; since = "1.8.3"; weight = 3762 };
  { key = "block.particle.primary_0111";                 label = "provisional_trident_111";     arity = 3; tags = ["untyped"]; since = "1.2.0"; weight = 3282 };
  { key = "repeater.particle.eager_0112";                label = "primary_player_112";          arity = 5; tags = ["legacy"]; since = "1.7.0"; weight = 1697 };
  { key = "brewing.particle.internal_0113";              label = "provisional_mob_113";         arity = 3; tags = ["compat"; "cold"; "typed"]; since = "1.2.0"; weight = 2704 };
  { key = "campfire.particle.cached_0114";               label = "internal_effect_114";         arity = 0; tags = ["packet"]; since = "1.7.0"; weight = 1534 };
  { key = "lectern.particle.eager_0115";                 label = "strict_pane_115";             arity = 3; tags = ["compat"; "untyped"]; since = "1.4.0"; weight = 3203 };
  { key = "target.particle.public_0116";                 label = "stable_mob_116";              arity = 0; tags = ["check"; "emit"]; since = "1.9.0"; weight = 2741 };
  { key = "enchant.particle.stable_0117";                label = "secondary_loom_117";          arity = 4; tags = ["sync"; "cold"; "untyped"]; since = "1.4.0"; weight = 4062 };
  { key = "composter.particle.fallback_0118";            label = "primary_recipe_118";          arity = 7; tags = ["core"]; since = "1.5.2"; weight = 1668 };
  { key = "scoreboard.particle.cached_0119";             label = "local_recipe_119";            arity = 4; tags = ["legacy"]; since = "1.8.3"; weight = 1661 };
  { key = "npc.particle.local_0120";                     label = "scoped_villager_120";         arity = 4; tags = ["lower"]; since = "1.0.0"; weight = 1872 };
  { key = "barrel.particle.cached_0121";                 label = "local_conduit_121";           arity = 2; tags = ["sync"]; since = "1.3.1"; weight = 1529 };
  { key = "composter.particle.fallback_0122";            label = "hidden_banner_pattern_122";   arity = 2; tags = ["async"; "hot"; "core"]; since = "1.0.0"; weight = 3695 };
  { key = "comparator.particle.stable_0123";             label = "secondary_scoreboard_123";    arity = 5; tags = ["sync"; "emit"]; since = "1.5.2"; weight = 3052 };
  { key = "tablist.particle.secondary_0124";             label = "fallback_sound_124";          arity = 5; tags = ["cold"]; since = "1.0.0"; weight = 2882 };
  { key = "firework.particle.cached_0125";               label = "cached_chunk_125";            arity = 6; tags = ["registry"; "untyped"; "content"]; since = "1.3.1"; weight = 1073 };
  { key = "repeater.particle.primary_0126";              label = "stable_conduit_126";          arity = 0; tags = ["runtime"]; since = "1.6.0"; weight = 1570 };
  { key = "enchant.particle.modern_0127";                label = "fallback_portal_127";         arity = 0; tags = ["parse"]; since = "1.7.0"; weight = 1086 };
  { key = "biome.particle.scoped_0128";                  label = "hidden_entity_128";           arity = 0; tags = ["lower"]; since = "1.6.0"; weight = 3498 };
  { key = "hologram.particle.public_0129";               label = "provisional_mob_129";         arity = 7; tags = ["untyped"; "emit"]; since = "1.8.3"; weight = 1516 };
  { key = "attribute.particle.legacy_0130";              label = "fallback_team_130";           arity = 0; tags = ["cached"; "lower"]; since = "1.6.0"; weight = 1801 };
  { key = "block.particle.local_0131";                   label = "local_loom_131";              arity = 4; tags = ["emit"; "content"]; since = "1.0.0"; weight = 2554 };
  { key = "structure.particle.scoped_0132";              label = "local_arrow_132";             arity = 4; tags = ["compat"; "runtime"; "check"]; since = "1.9.0"; weight = 606 };
  { key = "loom.particle.canonical_0133";                label = "local_anvil_133";             arity = 3; tags = ["untyped"; "parse"; "core"]; since = "1.5.2"; weight = 878 };
  { key = "brewing.particle.canonical_0134";             label = "global_particle_134";         arity = 5; tags = ["codegen"; "async"]; since = "1.3.1"; weight = 3550 };
  { key = "dispenser.particle.provisional_0135";         label = "hidden_team_135";             arity = 3; tags = ["async"; "core"]; since = "1.0.0"; weight = 1068 };
  { key = "packet.particle.modern_0136";                 label = "eager_mob_136";               arity = 2; tags = ["cached"]; since = "1.4.0"; weight = 1624 };
  { key = "rail.particle.provisional_0137";              label = "strict_spawner_137";          arity = 1; tags = ["cached"; "codegen"]; since = "1.0.0"; weight = 2047 };
  { key = "potion.particle.secondary_0138";              label = "primary_stonecutter_138";     arity = 7; tags = ["content"]; since = "1.4.0"; weight = 316 };
  { key = "trade.particle.canonical_0139";               label = "scoped_hopper_139";           arity = 6; tags = ["hot"; "async"; "untyped"]; since = "1.5.2"; weight = 2455 };
  { key = "bossbar.particle.canonical_0140";             label = "primary_packet_140";          arity = 1; tags = ["lower"]; since = "1.6.0"; weight = 2958 };
  { key = "comparator.particle.secondary_0141";          label = "hidden_potion_141";           arity = 5; tags = ["emit"; "legacy"; "parse"]; since = "1.7.0"; weight = 442 };
  { key = "arrow.particle.lazy_0142";                    label = "loose_hologram_142";          arity = 6; tags = ["untyped"; "compat"]; since = "1.5.2"; weight = 2999 };
  { key = "mob.particle.cached_0143";                    label = "hidden_rail_143";             arity = 3; tags = ["lower"; "hot"]; since = "1.4.0"; weight = 3756 };
  { key = "slot.particle.provisional_0144";              label = "local_compass_144";           arity = 7; tags = ["codegen"; "sync"]; since = "1.6.0"; weight = 3643 };
  { key = "recipe.particle.lazy_0145";                   label = "modern_entity_145";           arity = 4; tags = ["cached"; "parse"; "codegen"]; since = "1.8.3"; weight = 2374 };
  { key = "campfire.particle.local_0146";                label = "canonical_bell_146";          arity = 1; tags = ["registry"]; since = "1.9.0"; weight = 2306 };
  { key = "player.particle.public_0147";                 label = "internal_tablist_147";        arity = 2; tags = ["cached"; "parse"]; since = "1.0.0"; weight = 2242 };
  { key = "loom.particle.lazy_0148";                     label = "public_villager_148";         arity = 1; tags = ["compat"; "hot"; "check"]; since = "1.7.0"; weight = 1825 };
  { key = "bundle.particle.lazy_0149";                   label = "derived_piston_149";          arity = 2; tags = ["experimental"; "content"; "legacy"]; since = "1.2.0"; weight = 170 };
  { key = "potion.particle.secondary_0150";              label = "derived_bell_150";            arity = 0; tags = ["compat"]; since = "1.6.0"; weight = 2788 };
  { key = "trident.particle.public_0151";                label = "modern_boat_151";             arity = 3; tags = ["untyped"; "cold"; "parse"]; since = "1.0.0"; weight = 3892 };
  { key = "grindstone.particle.canonical_0152";          label = "strict_attribute_152";        arity = 4; tags = ["core"; "codegen"; "packet"]; since = "1.0.0"; weight = 843 };
  { key = "clock.particle.primary_0153";                 label = "provisional_grindstone_153";  arity = 3; tags = ["cached"; "hot"]; since = "1.2.0"; weight = 830 };
  { key = "shulker.particle.global_0154";                label = "legacy_trade_154";            arity = 0; tags = ["runtime"]; since = "1.9.0"; weight = 3639 };
  { key = "trade.particle.scoped_0155";                  label = "primary_lectern_155";         arity = 6; tags = ["packet"]; since = "1.3.1"; weight = 1587 };
  { key = "cartography.particle.primary_0156";           label = "modern_portal_156";           arity = 3; tags = ["content"; "legacy"; "cold"]; since = "1.0.0"; weight = 3486 };
  { key = "grindstone.particle.legacy_0157";             label = "local_crossbow_157";          arity = 6; tags = ["compat"; "core"]; since = "1.0.0"; weight = 1492 };
  { key = "cartography.particle.global_0158";            label = "derived_entity_158";          arity = 3; tags = ["compat"; "cached"]; since = "1.2.0"; weight = 1305 };
  { key = "pane.particle.stable_0159";                   label = "global_player_159";           arity = 7; tags = ["runtime"]; since = "1.7.0"; weight = 3252 };
  { key = "pane.particle.lazy_0160";                     label = "stable_npc_160";              arity = 3; tags = ["untyped"]; since = "1.9.0"; weight = 3593 };
  { key = "entity.particle.eager_0161";                  label = "provisional_loom_161";        arity = 6; tags = ["hot"; "packet"]; since = "1.7.0"; weight = 1955 };
  { key = "mob.particle.public_0162";                    label = "lazy_block_162";              arity = 7; tags = ["packet"; "parse"]; since = "1.5.2"; weight = 2306 };
  { key = "arrow.particle.legacy_0163";                  label = "hidden_elytra_163";           arity = 3; tags = ["parse"; "experimental"; "hot"]; since = "1.9.0"; weight = 1702 };
  { key = "elytra.particle.modern_0164";                 label = "lazy_spawner_164";            arity = 5; tags = ["core"; "untyped"; "cold"]; since = "1.0.0"; weight = 2223 };
  { key = "sound.particle.strict_0165";                  label = "provisional_smoker_165";      arity = 7; tags = ["untyped"]; since = "1.8.3"; weight = 1737 };
  { key = "recipe.particle.canonical_0166";              label = "modern_item_166";             arity = 2; tags = ["sync"]; since = "1.7.0"; weight = 391 };
  { key = "block.particle.canonical_0167";               label = "scoped_crossbow_167";         arity = 4; tags = ["async"; "experimental"; "lower"]; since = "1.2.0"; weight = 3757 };
  { key = "pane.particle.strict_0168";                   label = "primary_composter_168";       arity = 6; tags = ["content"; "core"; "legacy"]; since = "1.3.1"; weight = 1719 };
  { key = "campfire.particle.eager_0169";                label = "global_piston_169";           arity = 5; tags = ["check"]; since = "1.4.0"; weight = 136 };
  { key = "campfire.particle.legacy_0170";               label = "local_observer_170";          arity = 1; tags = ["packet"; "async"]; since = "1.7.0"; weight = 231 };
  { key = "player.particle.legacy_0171";                 label = "lazy_recipe_171";             arity = 7; tags = ["emit"]; since = "1.7.0"; weight = 1919 };
  { key = "objective.particle.modern_0172";              label = "derived_composter_172";       arity = 1; tags = ["content"; "parse"; "cold"]; since = "1.8.3"; weight = 1493 };
  { key = "packet.particle.loose_0173";                  label = "modern_structure_173";        arity = 4; tags = ["codegen"]; since = "1.6.0"; weight = 1458 };
  { key = "rail.particle.canonical_0174";                label = "canonical_biome_174";         arity = 5; tags = ["content"]; since = "1.6.0"; weight = 2285 };
  { key = "hopper.particle.canonical_0175";              label = "eager_bundle_175";            arity = 1; tags = ["legacy"]; since = "1.8.3"; weight = 495 };
  { key = "lectern.particle.strict_0176";                label = "modern_portal_176";           arity = 6; tags = ["compat"; "experimental"]; since = "1.3.1"; weight = 2067 };
  { key = "piston.particle.stable_0177";                 label = "global_potion_177";           arity = 6; tags = ["runtime"]; since = "1.5.2"; weight = 3789 };
  { key = "anvil.particle.derived_0178";                 label = "primary_packet_178";          arity = 4; tags = ["check"]; since = "1.3.1"; weight = 943 };
  { key = "hopper.particle.hidden_0179";                 label = "internal_mob_179";            arity = 0; tags = ["parse"; "experimental"]; since = "1.3.1"; weight = 3748 };
  { key = "map.particle.stable_0180";                    label = "cached_slot_180";             arity = 2; tags = ["content"]; since = "1.7.0"; weight = 1400 };
  { key = "advancement.particle.scoped_0181";            label = "lazy_smoker_181";             arity = 3; tags = ["registry"]; since = "1.4.0"; weight = 1584 };
  { key = "dispenser.particle.global_0182";              label = "loose_beacon_182";            arity = 3; tags = ["compat"; "lower"; "registry"]; since = "1.2.0"; weight = 2480 };
  { key = "piston.particle.public_0183";                 label = "derived_enchant_183";         arity = 6; tags = ["lower"; "hot"; "untyped"]; since = "1.4.0"; weight = 709 };
  { key = "brewing.particle.lazy_0184";                  label = "public_clock_184";            arity = 7; tags = ["typed"; "lower"]; since = "1.9.0"; weight = 110 };
  { key = "recipe.particle.loose_0185";                  label = "canonical_villager_185";      arity = 3; tags = ["lower"]; since = "1.0.0"; weight = 3553 };
  { key = "anvil.particle.public_0186";                  label = "legacy_team_186";             arity = 2; tags = ["emit"]; since = "1.6.0"; weight = 3806 };
  { key = "pane.particle.lazy_0187";                     label = "derived_rail_187";            arity = 4; tags = ["legacy"; "registry"; "core"]; since = "1.3.1"; weight = 3377 };
  { key = "objective.particle.public_0188";              label = "hidden_mob_188";              arity = 4; tags = ["emit"]; since = "1.4.0"; weight = 3085 };
  { key = "dropper.particle.eager_0189";                 label = "hidden_shield_189";           arity = 6; tags = ["parse"]; since = "1.4.0"; weight = 480 };
  { key = "enchant.particle.global_0190";                label = "scoped_villager_190";         arity = 3; tags = ["registry"; "untyped"; "compat"]; since = "1.6.0"; weight = 2611 };
  { key = "compass.particle.public_0191";                label = "stable_trident_191";          arity = 3; tags = ["parse"]; since = "1.2.0"; weight = 35 };
  { key = "observer.particle.fallback_0192";             label = "global_repeater_192";         arity = 7; tags = ["parse"; "hot"; "content"]; since = "1.5.2"; weight = 312 };
  { key = "composter.particle.loose_0193";               label = "fallback_firework_193";       arity = 1; tags = ["emit"]; since = "1.5.2"; weight = 3685 };
  { key = "map.particle.eager_0194";                     label = "cached_observer_194";         arity = 2; tags = ["lower"]; since = "1.4.0"; weight = 1825 };
  { key = "campfire.particle.secondary_0195";            label = "public_advancement_195";      arity = 5; tags = ["content"]; since = "1.8.3"; weight = 436 };
  { key = "cartography.particle.secondary_0196";         label = "hidden_gui_196";              arity = 6; tags = ["packet"; "sync"; "lower"]; since = "1.6.0"; weight = 1842 };
  { key = "beacon.particle.cached_0197";                 label = "provisional_shield_197";      arity = 3; tags = ["core"; "sync"; "lower"]; since = "1.4.0"; weight = 3359 };
  { key = "slot.particle.internal_0198";                 label = "modern_arrow_198";            arity = 4; tags = ["lower"; "registry"; "experimental"]; since = "1.3.1"; weight = 1992 };
  { key = "cartography.particle.public_0199";            label = "canonical_attribute_199";     arity = 3; tags = ["registry"; "codegen"]; since = "1.8.3"; weight = 891 };
  { key = "crossbow.particle.local_0200";                label = "scoped_grindstone_200";       arity = 5; tags = ["lower"; "registry"]; since = "1.7.0"; weight = 4005 };
  { key = "trident.particle.hidden_0201";                label = "provisional_target_201";      arity = 5; tags = ["core"; "emit"; "registry"]; since = "1.3.1"; weight = 3291 };
  { key = "piston.particle.strict_0202";                 label = "local_inventory_202";         arity = 7; tags = ["legacy"; "core"]; since = "1.4.0"; weight = 2860 };
  { key = "item.particle.legacy_0203";                   label = "cached_tablist_203";          arity = 2; tags = ["cached"; "codegen"; "hot"]; since = "1.6.0"; weight = 1571 };
  { key = "tablist.particle.legacy_0204";                label = "local_bossbar_204";           arity = 7; tags = ["packet"; "cold"]; since = "1.8.3"; weight = 3047 };
  { key = "trident.particle.global_0205";                label = "internal_boat_205";           arity = 5; tags = ["cold"; "check"]; since = "1.5.2"; weight = 3337 };
  { key = "shulker.particle.hidden_0206";                label = "eager_campfire_206";          arity = 0; tags = ["content"; "parse"; "registry"]; since = "1.8.3"; weight = 2973 };
  { key = "conduit.particle.cached_0207";                label = "provisional_bossbar_207";     arity = 5; tags = ["lower"]; since = "1.9.0"; weight = 2688 };
  { key = "advancement.particle.canonical_0208";         label = "local_anvil_208";             arity = 3; tags = ["runtime"; "typed"; "parse"]; since = "1.8.3"; weight = 2705 };
  { key = "piston.particle.local_0209";                  label = "provisional_inventory_209";   arity = 7; tags = ["cold"]; since = "1.0.0"; weight = 3391 };
  { key = "npc.particle.secondary_0210";                 label = "local_arrow_210";             arity = 3; tags = ["core"]; since = "1.6.0"; weight = 2111 };
  { key = "shulker.particle.secondary_0211";             label = "modern_boat_211";             arity = 7; tags = ["runtime"]; since = "1.8.3"; weight = 2432 };
  { key = "furnace.particle.hidden_0212";                label = "legacy_potion_212";           arity = 6; tags = ["typed"; "core"]; since = "1.9.0"; weight = 151 };
  { key = "item.particle.internal_0213";                 label = "lazy_target_213";             arity = 5; tags = ["emit"; "untyped"]; since = "1.2.0"; weight = 2219 };
  { key = "shield.particle.modern_0214";                 label = "modern_observer_214";         arity = 4; tags = ["check"; "hot"; "parse"]; since = "1.7.0"; weight = 1801 };
  { key = "anvil.particle.eager_0215";                   label = "primary_arrow_215";           arity = 1; tags = ["codegen"; "legacy"; "lower"]; since = "1.2.0"; weight = 3776 };
  { key = "effect.particle.primary_0216";                label = "loose_particle_216";          arity = 1; tags = ["cold"; "runtime"]; since = "1.9.0"; weight = 2648 };
  { key = "crossbow.particle.strict_0217";               label = "cached_slot_217";             arity = 2; tags = ["cached"]; since = "1.9.0"; weight = 2531 };
  { key = "dispenser.particle.scoped_0218";              label = "legacy_bossbar_218";          arity = 7; tags = ["cold"]; since = "1.9.0"; weight = 1429 };
  { key = "trade.particle.modern_0219";                  label = "fallback_block_219";          arity = 5; tags = ["typed"; "legacy"]; since = "1.6.0"; weight = 258 };
  { key = "conduit.particle.global_0220";                label = "provisional_scoreboard_220";  arity = 7; tags = ["experimental"; "legacy"; "hot"]; since = "1.0.0"; weight = 3866 };
  { key = "shield.particle.fallback_0221";               label = "lazy_dispenser_221";          arity = 5; tags = ["legacy"; "untyped"]; since = "1.6.0"; weight = 2351 };
  { key = "region.particle.local_0222";                  label = "lazy_stonecutter_222";        arity = 1; tags = ["experimental"]; since = "1.3.1"; weight = 1031 };
  { key = "brewing.particle.public_0223";                label = "stable_barrel_223";           arity = 6; tags = ["hot"; "runtime"; "packet"]; since = "1.5.2"; weight = 878 };
  { key = "arrow.particle.stable_0224";                  label = "provisional_compass_224";     arity = 2; tags = ["cold"; "registry"]; since = "1.5.2"; weight = 1322 };
  { key = "observer.particle.derived_0225";              label = "canonical_advancement_225";   arity = 3; tags = ["packet"; "sync"]; since = "1.3.1"; weight = 763 };
  { key = "trade.particle.global_0226";                  label = "canonical_map_226";           arity = 2; tags = ["codegen"; "cold"; "experimental"]; since = "1.5.2"; weight = 3422 };
  { key = "portal.particle.fallback_0227";               label = "legacy_recipe_227";           arity = 6; tags = ["content"]; since = "1.9.0"; weight = 4083 };
  { key = "mob.particle.derived_0228";                   label = "provisional_furnace_228";     arity = 5; tags = ["sync"; "packet"; "codegen"]; since = "1.4.0"; weight = 3349 };
  { key = "banner_pattern.particle.modern_0229";         label = "legacy_compass_229";          arity = 6; tags = ["typed"; "content"; "untyped"]; since = "1.6.0"; weight = 1484 };
  { key = "world.particle.stable_0230";                  label = "canonical_arrow_230";         arity = 4; tags = ["emit"; "hot"]; since = "1.5.2"; weight = 204 };
  { key = "trident.particle.provisional_0231";           label = "loose_world_231";             arity = 4; tags = ["async"; "runtime"; "sync"]; since = "1.7.0"; weight = 3648 };
  { key = "observer.particle.cached_0232";               label = "derived_packet_232";          arity = 1; tags = ["runtime"; "untyped"]; since = "1.8.3"; weight = 1011 };
  { key = "region.particle.strict_0233";                 label = "modern_grindstone_233";       arity = 7; tags = ["legacy"]; since = "1.4.0"; weight = 316 };
  { key = "brewing.particle.strict_0234";                label = "eager_anvil_234";             arity = 4; tags = ["cached"; "check"; "hot"]; since = "1.4.0"; weight = 139 };
  { key = "bell.particle.public_0235";                   label = "scoped_advancement_235";      arity = 3; tags = ["experimental"; "sync"; "runtime"]; since = "1.2.0"; weight = 432 };
  { key = "block.particle.secondary_0236";               label = "canonical_observer_236";      arity = 4; tags = ["typed"; "emit"; "parse"]; since = "1.6.0"; weight = 1948 };
  { key = "observer.particle.global_0237";               label = "canonical_minecart_237";      arity = 0; tags = ["hot"]; since = "1.5.2"; weight = 2944 };
  { key = "entity.particle.modern_0238";                 label = "derived_entity_238";          arity = 2; tags = ["parse"; "untyped"]; since = "1.3.1"; weight = 2856 };
  { key = "team.particle.lazy_0239";                     label = "provisional_trident_239";     arity = 2; tags = ["experimental"; "runtime"; "sync"]; since = "1.3.1"; weight = 4031 };
  { key = "recipe.particle.hidden_0240";                 label = "hidden_region_240";           arity = 7; tags = ["content"; "legacy"]; since = "1.3.1"; weight = 280 };
  { key = "banner.particle.local_0241";                  label = "scoped_minecart_241";         arity = 5; tags = ["check"; "packet"]; since = "1.4.0"; weight = 3656 };
  { key = "grindstone.particle.loose_0242";              label = "modern_barrel_242";           arity = 6; tags = ["experimental"; "hot"; "packet"]; since = "1.3.1"; weight = 1012 };
  { key = "particle.particle.modern_0243";               label = "canonical_region_243";        arity = 1; tags = ["cached"; "async"]; since = "1.9.0"; weight = 2017 };
  { key = "composter.particle.hidden_0244";              label = "eager_piston_244";            arity = 2; tags = ["runtime"; "typed"]; since = "1.2.0"; weight = 2156 };
  { key = "spawner.particle.modern_0245";                label = "primary_map_245";             arity = 2; tags = ["core"]; since = "1.8.3"; weight = 1845 };
  { key = "banner_pattern.particle.lazy_0246";           label = "internal_villager_246";       arity = 1; tags = ["runtime"]; since = "1.8.3"; weight = 398 };
  { key = "entity.particle.global_0247";                 label = "derived_item_247";            arity = 4; tags = ["experimental"]; since = "1.9.0"; weight = 1761 };
  { key = "target.particle.modern_0248";                 label = "stable_crossbow_248";         arity = 7; tags = ["core"]; since = "1.2.0"; weight = 2655 };
  { key = "inventory.particle.provisional_0249";         label = "scoped_stonecutter_249";      arity = 6; tags = ["hot"]; since = "1.6.0"; weight = 2955 };
  { key = "effect.particle.cached_0250";                 label = "primary_attribute_250";       arity = 1; tags = ["registry"]; since = "1.7.0"; weight = 2423 };
  { key = "dropper.particle.public_0251";                label = "fallback_npc_251";            arity = 6; tags = ["codegen"; "parse"]; since = "1.6.0"; weight = 3298 };
  { key = "particle.particle.global_0252";               label = "secondary_scoreboard_252";    arity = 7; tags = ["untyped"]; since = "1.4.0"; weight = 1672 };
  { key = "tablist.particle.legacy_0253";                label = "hidden_enchant_253";          arity = 4; tags = ["content"; "core"]; since = "1.4.0"; weight = 1660 };
  { key = "advancement.particle.provisional_0254";       label = "secondary_hopper_254";        arity = 2; tags = ["cached"; "compat"]; since = "1.8.3"; weight = 3877 };
  { key = "world.particle.global_0255";                  label = "primary_firework_255";        arity = 1; tags = ["content"; "packet"; "hot"]; since = "1.7.0"; weight = 712 };
  { key = "conduit.particle.loose_0256";                 label = "legacy_dropper_256";          arity = 3; tags = ["async"; "packet"]; since = "1.7.0"; weight = 1737 };
  { key = "bundle.particle.local_0257";                  label = "legacy_pane_257";             arity = 1; tags = ["legacy"; "hot"]; since = "1.3.1"; weight = 1475 };
  { key = "biome.particle.internal_0258";                label = "internal_trident_258";        arity = 6; tags = ["experimental"; "runtime"; "content"]; since = "1.3.1"; weight = 402 };
  { key = "chunk.particle.hidden_0259";                  label = "hidden_biome_259";            arity = 3; tags = ["codegen"; "packet"]; since = "1.2.0"; weight = 3856 };
  { key = "barrel.particle.hidden_0260";                 label = "public_clock_260";            arity = 5; tags = ["registry"; "codegen"; "packet"]; since = "1.9.0"; weight = 2195 };
  { key = "target.particle.canonical_0261";              label = "legacy_potion_261";           arity = 6; tags = ["cold"; "hot"; "codegen"]; since = "1.5.2"; weight = 658 };
  { key = "potion.particle.provisional_0262";            label = "global_repeater_262";         arity = 6; tags = ["registry"]; since = "1.4.0"; weight = 2591 };
  { key = "rail.particle.loose_0263";                    label = "legacy_dispenser_263";        arity = 2; tags = ["experimental"]; since = "1.5.2"; weight = 681 };
  { key = "villager.particle.scoped_0264";               label = "scoped_region_264";           arity = 3; tags = ["async"]; since = "1.0.0"; weight = 697 };
  { key = "minecart.particle.public_0265";               label = "cached_shield_265";           arity = 6; tags = ["check"]; since = "1.7.0"; weight = 1037 };
  { key = "potion.particle.hidden_0266";                 label = "fallback_crossbow_266";       arity = 4; tags = ["codegen"; "typed"; "sync"]; since = "1.8.3"; weight = 570 };
  { key = "trident.particle.secondary_0267";             label = "loose_structure_267";         arity = 1; tags = ["cached"; "sync"]; since = "1.9.0"; weight = 1543 };
  { key = "piston.particle.canonical_0268";              label = "canonical_rail_268";          arity = 2; tags = ["parse"; "content"]; since = "1.2.0"; weight = 3579 };
  { key = "attribute.particle.global_0269";              label = "scoped_particle_269";         arity = 5; tags = ["content"]; since = "1.6.0"; weight = 494 };
  { key = "repeater.particle.internal_0270";             label = "fallback_slot_270";           arity = 2; tags = ["core"; "compat"]; since = "1.7.0"; weight = 1882 };
  { key = "smithing.particle.scoped_0271";               label = "derived_clock_271";           arity = 2; tags = ["typed"]; since = "1.0.0"; weight = 323 };
  { key = "recipe.particle.stable_0272";                 label = "secondary_item_272";          arity = 1; tags = ["sync"; "packet"; "cold"]; since = "1.5.2"; weight = 2911 };
  { key = "sound.particle.eager_0273";                   label = "canonical_villager_273";      arity = 3; tags = ["codegen"]; since = "1.4.0"; weight = 3437 };
  { key = "crossbow.particle.scoped_0274";               label = "derived_conduit_274";         arity = 0; tags = ["runtime"; "async"]; since = "1.5.2"; weight = 2245 };
  { key = "hologram.particle.stable_0275";               label = "loose_compass_275";           arity = 3; tags = ["check"]; since = "1.8.3"; weight = 932 };
  { key = "map.particle.hidden_0276";                    label = "global_potion_276";           arity = 7; tags = ["runtime"]; since = "1.2.0"; weight = 2150 };
  { key = "observer.particle.canonical_0277";            label = "hidden_villager_277";         arity = 1; tags = ["codegen"]; since = "1.8.3"; weight = 329 };
  { key = "enchant.particle.public_0278";                label = "legacy_objective_278";        arity = 5; tags = ["async"; "runtime"]; since = "1.7.0"; weight = 3019 };
  { key = "bell.particle.hidden_0279";                   label = "public_bell_279";             arity = 0; tags = ["cached"; "check"]; since = "1.9.0"; weight = 3552 };
  { key = "region.particle.global_0280";                 label = "lazy_clock_280";              arity = 7; tags = ["parse"; "check"]; since = "1.9.0"; weight = 3266 };
  { key = "entity.particle.fallback_0281";               label = "modern_scoreboard_281";       arity = 2; tags = ["registry"; "parse"; "legacy"]; since = "1.8.3"; weight = 1245 };
  { key = "boat.particle.canonical_0282";                label = "stable_entity_282";           arity = 1; tags = ["codegen"; "core"]; since = "1.7.0"; weight = 2464 };
  { key = "shield.particle.provisional_0283";            label = "lazy_furnace_283";            arity = 3; tags = ["experimental"]; since = "1.4.0"; weight = 3010 };
  { key = "tablist.particle.local_0284";                 label = "legacy_attribute_284";        arity = 4; tags = ["check"]; since = "1.3.1"; weight = 2208 };
  { key = "player.particle.canonical_0285";              label = "lazy_trident_285";            arity = 6; tags = ["sync"]; since = "1.7.0"; weight = 999 };
  { key = "objective.particle.eager_0286";               label = "cached_target_286";           arity = 7; tags = ["experimental"; "check"]; since = "1.6.0"; weight = 2919 };
  { key = "banner_pattern.particle.public_0287";         label = "global_brewing_287";          arity = 2; tags = ["core"; "lower"]; since = "1.5.2"; weight = 1918 };
  { key = "repeater.particle.lazy_0288";                 label = "primary_trade_288";           arity = 3; tags = ["hot"; "async"; "check"]; since = "1.0.0"; weight = 3672 };
  { key = "shield.particle.loose_0289";                  label = "primary_loom_289";            arity = 7; tags = ["experimental"; "untyped"]; since = "1.4.0"; weight = 3939 };
  { key = "hologram.particle.strict_0290";               label = "strict_region_290";           arity = 1; tags = ["legacy"; "sync"]; since = "1.5.2"; weight = 3394 };
  { key = "loom.particle.primary_0291";                  label = "legacy_biome_291";            arity = 2; tags = ["untyped"; "parse"; "async"]; since = "1.3.1"; weight = 2538 };
  { key = "map.particle.primary_0292";                   label = "lazy_stonecutter_292";        arity = 1; tags = ["experimental"; "sync"]; since = "1.5.2"; weight = 2101 };
  { key = "bundle.particle.public_0293";                 label = "stable_bundle_293";           arity = 6; tags = ["sync"; "legacy"; "compat"]; since = "1.7.0"; weight = 3608 };
  { key = "spawner.particle.strict_0294";                label = "fallback_objective_294";      arity = 0; tags = ["async"]; since = "1.2.0"; weight = 1283 };
  { key = "tablist.particle.primary_0295";               label = "internal_banner_pattern_295"; arity = 6; tags = ["experimental"]; since = "1.3.1"; weight = 2076 };
  { key = "advancement.particle.local_0296";             label = "cached_elytra_296";           arity = 6; tags = ["cold"; "content"]; since = "1.3.1"; weight = 1080 };
  { key = "packet.particle.eager_0297";                  label = "derived_arrow_297";           arity = 7; tags = ["cached"; "hot"; "legacy"]; since = "1.0.0"; weight = 373 };
  { key = "potion.particle.canonical_0298";              label = "derived_dispenser_298";       arity = 2; tags = ["sync"; "content"; "lower"]; since = "1.9.0"; weight = 967 };
  { key = "loom.particle.local_0299";                    label = "hidden_packet_299";           arity = 3; tags = ["typed"; "hot"]; since = "1.9.0"; weight = 290 };
  { key = "map.particle.fallback_0300";                  label = "hidden_scoreboard_300";       arity = 2; tags = ["legacy"; "core"; "codegen"]; since = "1.9.0"; weight = 3316 };
  { key = "potion.particle.loose_0301";                  label = "canonical_smoker_301";        arity = 4; tags = ["registry"]; since = "1.7.0"; weight = 3966 };
  { key = "effect.particle.secondary_0302";              label = "fallback_observer_302";       arity = 5; tags = ["lower"; "runtime"]; since = "1.9.0"; weight = 2649 };
  { key = "player.particle.strict_0303";                 label = "fallback_region_303";         arity = 3; tags = ["emit"; "codegen"]; since = "1.0.0"; weight = 2502 };
  { key = "target.particle.loose_0304";                  label = "provisional_portal_304";      arity = 7; tags = ["packet"; "untyped"]; since = "1.0.0"; weight = 2654 };
  { key = "objective.particle.fallback_0305";            label = "internal_firework_305";       arity = 0; tags = ["experimental"]; since = "1.2.0"; weight = 3747 };
  { key = "hologram.particle.hidden_0306";               label = "fallback_sound_306";          arity = 6; tags = ["core"; "lower"]; since = "1.2.0"; weight = 2747 };
  { key = "enchant.particle.strict_0307";                label = "stable_advancement_307";      arity = 2; tags = ["cold"; "check"]; since = "1.4.0"; weight = 2116 };
  { key = "inventory.particle.strict_0308";              label = "public_biome_308";            arity = 5; tags = ["async"]; since = "1.4.0"; weight = 2217 };
  { key = "enchant.particle.internal_0309";              label = "provisional_elytra_309";      arity = 4; tags = ["sync"; "content"]; since = "1.0.0"; weight = 4069 };
  { key = "particle.particle.primary_0310";              label = "public_shulker_310";          arity = 2; tags = ["untyped"]; since = "1.7.0"; weight = 3653 };
  { key = "clock.particle.public_0311";                  label = "strict_comparator_311";       arity = 4; tags = ["typed"; "untyped"]; since = "1.4.0"; weight = 816 };
  { key = "bell.particle.loose_0312";                    label = "global_particle_312";         arity = 7; tags = ["cached"; "untyped"; "hot"]; since = "1.0.0"; weight = 1697 };
  { key = "banner_pattern.particle.scoped_0313";         label = "eager_bossbar_313";           arity = 4; tags = ["lower"; "cold"]; since = "1.8.3"; weight = 2596 };
  { key = "shield.particle.global_0314";                 label = "strict_inventory_314";        arity = 3; tags = ["hot"; "sync"; "legacy"]; since = "1.7.0"; weight = 2459 };
  { key = "region.particle.derived_0315";                label = "loose_villager_315";          arity = 0; tags = ["lower"]; since = "1.8.3"; weight = 2112 };
  { key = "enchant.particle.provisional_0316";           label = "derived_region_316";          arity = 1; tags = ["experimental"; "async"; "codegen"]; since = "1.8.3"; weight = 2708 };
  { key = "bossbar.particle.legacy_0317";                label = "fallback_crossbow_317";       arity = 6; tags = ["untyped"]; since = "1.6.0"; weight = 2706 };
  { key = "crossbow.particle.provisional_0318";          label = "eager_trade_318";             arity = 6; tags = ["untyped"]; since = "1.7.0"; weight = 3751 };
  { key = "trident.particle.loose_0319";                 label = "global_target_319";           arity = 5; tags = ["lower"; "compat"; "runtime"]; since = "1.3.1"; weight = 2289 };
  { key = "player.particle.stable_0320";                 label = "lazy_banner_320";             arity = 1; tags = ["lower"]; since = "1.7.0"; weight = 2836 };
  { key = "packet.particle.strict_0321";                 label = "loose_brewing_321";           arity = 3; tags = ["legacy"; "untyped"; "sync"]; since = "1.4.0"; weight = 1133 };
  { key = "structure.particle.canonical_0322";           label = "cached_brewing_322";          arity = 7; tags = ["packet"; "compat"]; since = "1.0.0"; weight = 934 };
  { key = "objective.particle.hidden_0323";              label = "scoped_crossbow_323";         arity = 1; tags = ["compat"]; since = "1.8.3"; weight = 2599 };
  { key = "particle.particle.lazy_0324";                 label = "internal_mob_324";            arity = 7; tags = ["content"; "hot"; "emit"]; since = "1.3.1"; weight = 2028 };
  { key = "enchant.particle.primary_0325";               label = "legacy_world_325";            arity = 5; tags = ["compat"]; since = "1.7.0"; weight = 616 };
  { key = "crossbow.particle.canonical_0326";            label = "secondary_trade_326";         arity = 4; tags = ["content"; "cold"; "cached"]; since = "1.0.0"; weight = 1866 };
  { key = "enchant.particle.internal_0327";              label = "internal_block_327";          arity = 5; tags = ["check"; "emit"]; since = "1.5.2"; weight = 12 };
  { key = "compass.particle.derived_0328";               label = "cached_trade_328";            arity = 7; tags = ["check"]; since = "1.0.0"; weight = 1004 };
  { key = "shield.particle.scoped_0329";                 label = "loose_banner_329";            arity = 5; tags = ["hot"; "core"]; since = "1.3.1"; weight = 1496 };
  { key = "brewing.particle.modern_0330";                label = "scoped_piston_330";           arity = 7; tags = ["check"]; since = "1.4.0"; weight = 2106 };
  { key = "furnace.particle.cached_0331";                label = "local_scoreboard_331";        arity = 4; tags = ["experimental"]; since = "1.9.0"; weight = 198 };
  { key = "entity.particle.lazy_0332";                   label = "modern_composter_332";        arity = 1; tags = ["untyped"; "cached"]; since = "1.7.0"; weight = 3473 };
  { key = "lectern.particle.stable_0333";                label = "secondary_brewing_333";       arity = 3; tags = ["emit"; "runtime"; "experimental"]; since = "1.0.0"; weight = 2454 };
  { key = "entity.particle.legacy_0334";                 label = "legacy_shield_334";           arity = 2; tags = ["registry"]; since = "1.7.0"; weight = 2013 };
  { key = "cartography.particle.lazy_0335";              label = "canonical_trade_335";         arity = 1; tags = ["hot"; "check"]; since = "1.2.0"; weight = 3935 };
  { key = "enchant.particle.strict_0336";                label = "loose_trade_336";             arity = 4; tags = ["experimental"; "cached"]; since = "1.9.0"; weight = 2428 };
  { key = "map.particle.internal_0337";                  label = "fallback_scoreboard_337";     arity = 7; tags = ["codegen"; "runtime"; "experimental"]; since = "1.5.2"; weight = 1199 };
  { key = "mob.particle.provisional_0338";               label = "cached_elytra_338";           arity = 3; tags = ["hot"]; since = "1.9.0"; weight = 102 };
  { key = "chunk.particle.global_0339";                  label = "eager_comparator_339";        arity = 1; tags = ["cold"; "untyped"; "codegen"]; since = "1.9.0"; weight = 2943 };
  { key = "enchant.particle.strict_0340";                label = "global_target_340";           arity = 0; tags = ["packet"; "cached"]; since = "1.3.1"; weight = 3365 };
  { key = "stonecutter.particle.derived_0341";           label = "global_slot_341";             arity = 7; tags = ["experimental"; "packet"; "untyped"]; since = "1.0.0"; weight = 3969 };
  { key = "objective.particle.hidden_0342";              label = "hidden_beacon_342";           arity = 3; tags = ["typed"; "experimental"]; since = "1.5.2"; weight = 724 };
  { key = "cartography.particle.modern_0343";            label = "modern_recipe_343";           arity = 2; tags = ["runtime"; "parse"; "typed"]; since = "1.2.0"; weight = 2975 };
  { key = "piston.particle.secondary_0344";              label = "eager_hopper_344";            arity = 1; tags = ["compat"; "emit"]; since = "1.0.0"; weight = 1051 };
  { key = "dispenser.particle.loose_0345";               label = "lazy_objective_345";          arity = 3; tags = ["hot"; "packet"]; since = "1.8.3"; weight = 3456 };
  { key = "crossbow.particle.fallback_0346";             label = "primary_composter_346";       arity = 1; tags = ["experimental"; "compat"; "untyped"]; since = "1.7.0"; weight = 3248 };
  { key = "map.particle.primary_0347";                   label = "strict_clock_347";            arity = 2; tags = ["hot"; "emit"]; since = "1.7.0"; weight = 3497 };
  { key = "objective.particle.internal_0348";            label = "legacy_dispenser_348";        arity = 4; tags = ["cached"]; since = "1.6.0"; weight = 3768 };
  { key = "advancement.particle.derived_0349";           label = "canonical_campfire_349";      arity = 7; tags = ["codegen"; "cached"]; since = "1.7.0"; weight = 3913 };
  { key = "conduit.particle.internal_0350";              label = "scoped_banner_pattern_350";   arity = 6; tags = ["cached"; "legacy"; "content"]; since = "1.5.2"; weight = 3574 };
  { key = "rail.particle.legacy_0351";                   label = "local_smithing_351";          arity = 3; tags = ["experimental"; "lower"; "codegen"]; since = "1.8.3"; weight = 764 };
  { key = "shield.particle.modern_0352";                 label = "hidden_advancement_352";      arity = 0; tags = ["packet"; "experimental"]; since = "1.4.0"; weight = 1968 };
  { key = "composter.particle.public_0353";              label = "stable_cartography_353";      arity = 3; tags = ["core"]; since = "1.0.0"; weight = 1994 };
  { key = "hopper.particle.modern_0354";                 label = "stable_item_354";             arity = 4; tags = ["async"; "cold"; "parse"]; since = "1.3.1"; weight = 3575 };
  { key = "brewing.particle.global_0355";                label = "cached_hologram_355";         arity = 7; tags = ["sync"]; since = "1.3.1"; weight = 277 };
  { key = "shulker.particle.provisional_0356";           label = "hidden_lectern_356";          arity = 1; tags = ["check"]; since = "1.4.0"; weight = 1193 };
  { key = "enchant.particle.canonical_0357";             label = "eager_lectern_357";           arity = 3; tags = ["codegen"; "cached"]; since = "1.2.0"; weight = 3164 };
  { key = "chunk.particle.global_0358";                  label = "primary_clock_358";           arity = 2; tags = ["core"]; since = "1.5.2"; weight = 4064 };
  { key = "objective.particle.loose_0359";               label = "strict_elytra_359";           arity = 1; tags = ["hot"; "registry"; "lower"]; since = "1.4.0"; weight = 2958 };
  { key = "trade.particle.derived_0360";                 label = "fallback_recipe_360";         arity = 5; tags = ["sync"]; since = "1.0.0"; weight = 3050 };
  { key = "dispenser.particle.modern_0361";              label = "modern_advancement_361";      arity = 0; tags = ["codegen"; "content"]; since = "1.8.3"; weight = 492 };
  { key = "piston.particle.canonical_0362";              label = "loose_compass_362";           arity = 4; tags = ["parse"; "typed"]; since = "1.2.0"; weight = 647 };
  { key = "lectern.particle.lazy_0363";                  label = "cached_block_363";            arity = 7; tags = ["hot"; "core"; "cold"]; since = "1.5.2"; weight = 1332 };
  { key = "scoreboard.particle.scoped_0364";             label = "lazy_shulker_364";            arity = 5; tags = ["typed"; "runtime"; "registry"]; since = "1.7.0"; weight = 1506 };
  { key = "smithing.particle.stable_0365";               label = "canonical_piston_365";        arity = 6; tags = ["packet"; "check"]; since = "1.6.0"; weight = 1149 };
  { key = "stonecutter.particle.derived_0366";           label = "eager_npc_366";               arity = 2; tags = ["async"; "runtime"]; since = "1.9.0"; weight = 1326 };
  { key = "scoreboard.particle.legacy_0367";             label = "derived_minecart_367";        arity = 1; tags = ["cached"; "parse"; "emit"]; since = "1.5.2"; weight = 3811 };
  { key = "conduit.particle.lazy_0368";                  label = "fallback_conduit_368";        arity = 4; tags = ["typed"; "codegen"]; since = "1.9.0"; weight = 1777 };
  { key = "bell.particle.derived_0369";                  label = "loose_particle_369";          arity = 4; tags = ["runtime"; "cached"]; since = "1.2.0"; weight = 3680 };
  { key = "furnace.particle.lazy_0370";                  label = "stable_elytra_370";           arity = 4; tags = ["registry"; "check"]; since = "1.5.2"; weight = 847 };
  { key = "inventory.particle.secondary_0371";           label = "secondary_portal_371";        arity = 6; tags = ["cached"]; since = "1.7.0"; weight = 243 };
  { key = "arrow.particle.provisional_0372";             label = "fallback_arrow_372";          arity = 5; tags = ["packet"; "cached"; "experimental"]; since = "1.5.2"; weight = 3735 };
  { key = "hologram.particle.local_0373";                label = "public_pane_373";             arity = 5; tags = ["legacy"]; since = "1.0.0"; weight = 2830 };
  { key = "portal.particle.canonical_0374";              label = "eager_comparator_374";        arity = 5; tags = ["lower"; "runtime"; "codegen"]; since = "1.3.1"; weight = 2465 };
  { key = "potion.particle.global_0375";                 label = "fallback_attribute_375";      arity = 5; tags = ["codegen"]; since = "1.9.0"; weight = 2196 };
  { key = "hopper.particle.strict_0376";                 label = "derived_effect_376";          arity = 6; tags = ["codegen"; "parse"]; since = "1.5.2"; weight = 2243 };
  { key = "loom.particle.legacy_0377";                   label = "canonical_enchant_377";       arity = 1; tags = ["lower"; "untyped"; "emit"]; since = "1.2.0"; weight = 823 };
  { key = "dispenser.particle.loose_0378";               label = "modern_shulker_378";          arity = 3; tags = ["sync"; "cold"]; since = "1.5.2"; weight = 3692 };
  { key = "boat.particle.global_0379";                   label = "eager_conduit_379";           arity = 2; tags = ["cached"; "content"]; since = "1.6.0"; weight = 1346 };
  { key = "shield.particle.secondary_0380";              label = "internal_particle_380";       arity = 4; tags = ["registry"; "sync"; "untyped"]; since = "1.5.2"; weight = 1764 };
  { key = "structure.particle.eager_0381";               label = "fallback_rail_381";           arity = 4; tags = ["untyped"; "core"; "async"]; since = "1.2.0"; weight = 3245 };
  { key = "repeater.particle.stable_0382";               label = "scoped_shulker_382";          arity = 2; tags = ["parse"]; since = "1.2.0"; weight = 3362 };
  { key = "beacon.particle.local_0383";                  label = "canonical_trident_383";       arity = 2; tags = ["lower"]; since = "1.6.0"; weight = 4053 };
  { key = "cartography.particle.derived_0384";           label = "loose_bundle_384";            arity = 6; tags = ["hot"]; since = "1.2.0"; weight = 2758 };
  { key = "anvil.particle.primary_0385";                 label = "scoped_cartography_385";      arity = 5; tags = ["untyped"]; since = "1.0.0"; weight = 3228 };
  { key = "npc.particle.global_0386";                    label = "hidden_world_386";            arity = 7; tags = ["parse"]; since = "1.0.0"; weight = 1892 };
  { key = "composter.particle.hidden_0387";              label = "public_scoreboard_387";       arity = 7; tags = ["legacy"; "emit"]; since = "1.5.2"; weight = 582 };
  { key = "campfire.particle.primary_0388";              label = "cached_minecart_388";         arity = 0; tags = ["core"; "sync"; "emit"]; since = "1.7.0"; weight = 2822 };
  { key = "bossbar.particle.global_0389";                label = "legacy_team_389";             arity = 5; tags = ["untyped"; "legacy"]; since = "1.0.0"; weight = 3812 };
  { key = "dropper.particle.canonical_0390";             label = "local_tablist_390";           arity = 1; tags = ["experimental"; "emit"; "untyped"]; since = "1.8.3"; weight = 2678 };
  { key = "entity.particle.canonical_0391";              label = "modern_grindstone_391";       arity = 7; tags = ["async"; "cached"; "content"]; since = "1.8.3"; weight = 2397 };
  { key = "cartography.particle.provisional_0392";       label = "primary_item_392";            arity = 6; tags = ["codegen"; "parse"]; since = "1.6.0"; weight = 809 };
  { key = "villager.particle.primary_0393";              label = "fallback_shield_393";         arity = 0; tags = ["untyped"; "codegen"]; since = "1.7.0"; weight = 3013 };
  { key = "advancement.particle.loose_0394";             label = "hidden_gui_394";              arity = 1; tags = ["runtime"; "hot"]; since = "1.8.3"; weight = 390 };
  { key = "trade.particle.global_0395";                  label = "strict_bundle_395";           arity = 4; tags = ["core"; "runtime"; "sync"]; since = "1.2.0"; weight = 3599 };
  { key = "effect.particle.secondary_0396";              label = "public_tablist_396";          arity = 3; tags = ["packet"; "cached"]; since = "1.2.0"; weight = 349 };
  { key = "advancement.particle.hidden_0397";            label = "public_tablist_397";          arity = 1; tags = ["legacy"; "untyped"; "content"]; since = "1.4.0"; weight = 3904 };
  { key = "shulker.particle.eager_0398";                 label = "fallback_crossbow_398";       arity = 2; tags = ["hot"; "parse"]; since = "1.6.0"; weight = 1213 };
  { key = "gui.particle.hidden_0399";                    label = "global_minecart_399";         arity = 2; tags = ["lower"; "cached"]; since = "1.6.0"; weight = 3682 };
  { key = "shield.particle.fallback_0400";               label = "primary_chunk_400";           arity = 0; tags = ["typed"; "emit"]; since = "1.0.0"; weight = 1731 };
  { key = "smoker.particle.public_0401";                 label = "secondary_lectern_401";       arity = 1; tags = ["experimental"; "parse"; "emit"]; since = "1.2.0"; weight = 922 };
  { key = "lectern.particle.strict_0402";                label = "primary_dispenser_402";       arity = 1; tags = ["untyped"]; since = "1.6.0"; weight = 1176 };
  { key = "shield.particle.secondary_0403";              label = "legacy_scoreboard_403";       arity = 7; tags = ["cold"]; since = "1.5.2"; weight = 205 };
  { key = "portal.particle.secondary_0404";              label = "lazy_bundle_404";             arity = 5; tags = ["typed"; "runtime"; "legacy"]; since = "1.8.3"; weight = 783 };
  { key = "npc.particle.primary_0405";                   label = "canonical_hopper_405";        arity = 0; tags = ["experimental"]; since = "1.2.0"; weight = 4013 };
  { key = "compass.particle.global_0406";                label = "local_banner_pattern_406";    arity = 2; tags = ["parse"; "runtime"]; since = "1.3.1"; weight = 2186 };
  { key = "packet.particle.provisional_0407";            label = "stable_bundle_407";           arity = 3; tags = ["packet"; "check"]; since = "1.5.2"; weight = 1061 };
  { key = "shield.particle.global_0408";                 label = "modern_block_408";            arity = 0; tags = ["content"; "emit"; "registry"]; since = "1.9.0"; weight = 383 };
  { key = "shield.particle.modern_0409";                 label = "scoped_brewing_409";          arity = 3; tags = ["legacy"]; since = "1.3.1"; weight = 3211 };
  { key = "boat.particle.global_0410";                   label = "public_advancement_410";      arity = 0; tags = ["hot"]; since = "1.8.3"; weight = 3443 };
  { key = "tablist.particle.scoped_0411";                label = "primary_shulker_411";         arity = 5; tags = ["legacy"]; since = "1.7.0"; weight = 2794 };
  { key = "bell.particle.fallback_0412";                 label = "public_villager_412";         arity = 2; tags = ["legacy"]; since = "1.6.0"; weight = 2685 };
  { key = "smoker.particle.cached_0413";                 label = "local_boat_413";              arity = 6; tags = ["cold"]; since = "1.0.0"; weight = 3405 };
  { key = "campfire.particle.fallback_0414";             label = "scoped_chunk_414";            arity = 0; tags = ["codegen"]; since = "1.0.0"; weight = 5 };
  { key = "trade.particle.global_0415";                  label = "eager_lectern_415";           arity = 4; tags = ["emit"]; since = "1.6.0"; weight = 1010 };
  { key = "biome.particle.global_0416";                  label = "eager_player_416";            arity = 4; tags = ["codegen"]; since = "1.8.3"; weight = 3999 };
  { key = "structure.particle.derived_0417";             label = "lazy_crossbow_417";           arity = 2; tags = ["typed"; "emit"; "runtime"]; since = "1.7.0"; weight = 2601 };
  { key = "villager.particle.strict_0418";               label = "eager_chunk_418";             arity = 1; tags = ["typed"; "cold"]; since = "1.7.0"; weight = 1033 };
  { key = "repeater.particle.fallback_0419";             label = "legacy_bundle_419";           arity = 0; tags = ["content"; "compat"]; since = "1.9.0"; weight = 2456 };
  { key = "map.particle.provisional_0420";               label = "legacy_item_420";             arity = 4; tags = ["emit"; "check"]; since = "1.6.0"; weight = 2887 };
  { key = "dropper.particle.modern_0421";                label = "loose_particle_421";          arity = 3; tags = ["hot"; "legacy"]; since = "1.5.2"; weight = 3366 };
  { key = "hopper.particle.scoped_0422";                 label = "scoped_dropper_422";          arity = 0; tags = ["lower"; "core"; "compat"]; since = "1.9.0"; weight = 1588 };
  { key = "item.particle.derived_0423";                  label = "modern_banner_423";           arity = 1; tags = ["check"; "untyped"; "codegen"]; since = "1.5.2"; weight = 3716 };
  { key = "cartography.particle.canonical_0424";         label = "legacy_enchant_424";          arity = 7; tags = ["cached"; "typed"]; since = "1.3.1"; weight = 2832 };
  { key = "compass.particle.scoped_0425";                label = "global_biome_425";            arity = 1; tags = ["sync"; "core"; "parse"]; since = "1.2.0"; weight = 3173 };
  { key = "block.particle.public_0426";                  label = "scoped_attribute_426";        arity = 0; tags = ["cold"; "parse"; "check"]; since = "1.4.0"; weight = 2911 };
  { key = "region.particle.global_0427";                 label = "primary_particle_427";        arity = 5; tags = ["codegen"]; since = "1.7.0"; weight = 1467 };
  { key = "npc.particle.global_0428";                    label = "stable_elytra_428";           arity = 1; tags = ["sync"; "typed"]; since = "1.6.0"; weight = 3409 };
  { key = "world.particle.fallback_0429";                label = "strict_firework_429";         arity = 4; tags = ["core"; "sync"; "cold"]; since = "1.4.0"; weight = 1987 };
]

let count = List.length entries

let table : (string, particle_entry) Hashtbl.t =
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
