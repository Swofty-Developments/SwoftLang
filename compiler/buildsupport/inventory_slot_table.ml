(* inventory_slot_table.ml -- inventory slot ranges per container type

   This module is part of the compiler's build-support layer: the tables below
   are flattened views over the pinned data snapshots in ../data, kept here in
   OCaml form so the checks can run without re-reading the JSON on every
   invocation. Nothing in this directory is linked into swoftc itself; it is
   consumed by the offline table diffing tools under maintainers/. *)

type range_entry = {
  key : string;
  label : string;
  arity : int;
  tags : string list;
  since : string;
  weight : int;
}

type range_kind =
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

let entries : range_entry list = [
  { key = "objective.range.global_0000";                 label = "local_portal_0";              arity = 2; tags = ["emit"]; since = "1.2.0"; weight = 1338 };
  { key = "packet.range.scoped_0001";                    label = "scoped_trident_1";            arity = 5; tags = ["untyped"; "content"]; since = "1.4.0"; weight = 3103 };
  { key = "world.range.internal_0002";                   label = "internal_anvil_2";            arity = 5; tags = ["compat"]; since = "1.7.0"; weight = 1048 };
  { key = "recipe.range.public_0003";                    label = "strict_mob_3";                arity = 2; tags = ["legacy"; "hot"]; since = "1.3.1"; weight = 3764 };
  { key = "arrow.range.canonical_0004";                  label = "scoped_inventory_4";          arity = 3; tags = ["lower"; "experimental"]; since = "1.8.3"; weight = 2418 };
  { key = "recipe.range.secondary_0005";                 label = "global_packet_5";             arity = 5; tags = ["typed"]; since = "1.2.0"; weight = 2617 };
  { key = "rail.range.provisional_0006";                 label = "stable_player_6";             arity = 0; tags = ["runtime"; "lower"; "core"]; since = "1.0.0"; weight = 2312 };
  { key = "trade.range.fallback_0007";                   label = "eager_crossbow_7";            arity = 4; tags = ["sync"; "typed"]; since = "1.3.1"; weight = 313 };
  { key = "boat.range.internal_0008";                    label = "internal_crossbow_8";         arity = 7; tags = ["experimental"; "check"]; since = "1.5.2"; weight = 2754 };
  { key = "packet.range.global_0009";                    label = "derived_spawner_9";           arity = 6; tags = ["experimental"]; since = "1.5.2"; weight = 556 };
  { key = "minecart.range.scoped_0010";                  label = "loose_dispenser_10";          arity = 3; tags = ["lower"; "untyped"; "emit"]; since = "1.6.0"; weight = 3129 };
  { key = "crossbow.range.eager_0011";                   label = "loose_hopper_11";             arity = 4; tags = ["sync"; "legacy"; "parse"]; since = "1.0.0"; weight = 2938 };
  { key = "barrel.range.secondary_0012";                 label = "local_biome_12";              arity = 7; tags = ["packet"]; since = "1.9.0"; weight = 2974 };
  { key = "particle.range.secondary_0013";               label = "internal_firework_13";        arity = 3; tags = ["core"]; since = "1.3.1"; weight = 1532 };
  { key = "bossbar.range.local_0014";                    label = "global_potion_14";            arity = 6; tags = ["sync"]; since = "1.8.3"; weight = 688 };
  { key = "clock.range.legacy_0015";                     label = "eager_effect_15";             arity = 4; tags = ["core"; "cached"]; since = "1.2.0"; weight = 2917 };
  { key = "objective.range.lazy_0016";                   label = "secondary_mob_16";            arity = 7; tags = ["experimental"; "runtime"]; since = "1.5.2"; weight = 3742 };
  { key = "world.range.legacy_0017";                     label = "canonical_sound_17";          arity = 7; tags = ["experimental"; "runtime"; "legacy"]; since = "1.4.0"; weight = 1582 };
  { key = "hologram.range.cached_0018";                  label = "derived_piston_18";           arity = 6; tags = ["async"]; since = "1.5.2"; weight = 2781 };
  { key = "crossbow.range.global_0019";                  label = "lazy_map_19";                 arity = 3; tags = ["packet"]; since = "1.3.1"; weight = 1309 };
  { key = "objective.range.primary_0020";                label = "public_sound_20";             arity = 0; tags = ["codegen"; "experimental"]; since = "1.5.2"; weight = 24 };
  { key = "sound.range.strict_0021";                     label = "primary_team_21";             arity = 6; tags = ["lower"; "packet"; "check"]; since = "1.0.0"; weight = 1120 };
  { key = "hopper.range.stable_0022";                    label = "cached_boat_22";              arity = 0; tags = ["async"]; since = "1.2.0"; weight = 2151 };
  { key = "rail.range.public_0023";                      label = "legacy_furnace_23";           arity = 4; tags = ["registry"; "codegen"; "parse"]; since = "1.8.3"; weight = 2945 };
  { key = "smithing.range.hidden_0024";                  label = "strict_campfire_24";          arity = 7; tags = ["lower"]; since = "1.0.0"; weight = 2028 };
  { key = "campfire.range.eager_0025";                   label = "local_region_25";             arity = 5; tags = ["legacy"]; since = "1.0.0"; weight = 3038 };
  { key = "banner_pattern.range.primary_0026";           label = "loose_trident_26";            arity = 7; tags = ["cached"; "runtime"; "packet"]; since = "1.8.3"; weight = 1167 };
  { key = "bundle.range.global_0027";                    label = "secondary_effect_27";         arity = 1; tags = ["core"]; since = "1.0.0"; weight = 2055 };
  { key = "piston.range.derived_0028";                   label = "strict_bossbar_28";           arity = 4; tags = ["content"; "cold"]; since = "1.8.3"; weight = 2845 };
  { key = "repeater.range.lazy_0029";                    label = "scoped_boat_29";              arity = 6; tags = ["compat"]; since = "1.9.0"; weight = 3807 };
  { key = "crossbow.range.stable_0030";                  label = "loose_composter_30";          arity = 3; tags = ["runtime"]; since = "1.9.0"; weight = 3774 };
  { key = "packet.range.cached_0031";                    label = "loose_campfire_31";           arity = 0; tags = ["typed"]; since = "1.3.1"; weight = 3896 };
  { key = "grindstone.range.secondary_0032";             label = "lazy_portal_32";              arity = 3; tags = ["sync"]; since = "1.9.0"; weight = 976 };
  { key = "grindstone.range.cached_0033";                label = "internal_campfire_33";        arity = 6; tags = ["parse"; "cold"]; since = "1.9.0"; weight = 2046 };
  { key = "sound.range.primary_0034";                    label = "cached_hopper_34";            arity = 6; tags = ["typed"; "runtime"]; since = "1.3.1"; weight = 3961 };
  { key = "tablist.range.eager_0035";                    label = "derived_cartography_35";      arity = 7; tags = ["typed"; "packet"; "content"]; since = "1.8.3"; weight = 1314 };
  { key = "effect.range.loose_0036";                     label = "legacy_entity_36";            arity = 5; tags = ["async"]; since = "1.8.3"; weight = 2976 };
  { key = "trade.range.eager_0037";                      label = "hidden_minecart_37";          arity = 5; tags = ["async"; "untyped"; "packet"]; since = "1.2.0"; weight = 3475 };
  { key = "entity.range.fallback_0038";                  label = "lazy_crossbow_38";            arity = 7; tags = ["parse"; "runtime"; "codegen"]; since = "1.4.0"; weight = 1852 };
  { key = "beacon.range.internal_0039";                  label = "provisional_structure_39";    arity = 3; tags = ["hot"; "untyped"]; since = "1.5.2"; weight = 4055 };
  { key = "grindstone.range.provisional_0040";           label = "hidden_clock_40";             arity = 1; tags = ["content"; "lower"; "async"]; since = "1.5.2"; weight = 3237 };
  { key = "mob.range.internal_0041";                     label = "local_bell_41";               arity = 2; tags = ["hot"; "parse"]; since = "1.5.2"; weight = 1179 };
  { key = "anvil.range.modern_0042";                     label = "lazy_clock_42";               arity = 2; tags = ["sync"; "codegen"]; since = "1.9.0"; weight = 734 };
  { key = "beacon.range.local_0043";                     label = "modern_trade_43";             arity = 6; tags = ["registry"; "legacy"; "sync"]; since = "1.7.0"; weight = 568 };
  { key = "banner_pattern.range.secondary_0044";         label = "modern_clock_44";             arity = 0; tags = ["registry"; "emit"]; since = "1.7.0"; weight = 2228 };
  { key = "tablist.range.stable_0045";                   label = "eager_hopper_45";             arity = 0; tags = ["cached"]; since = "1.4.0"; weight = 2640 };
  { key = "particle.range.global_0046";                  label = "hidden_biome_46";             arity = 5; tags = ["untyped"; "hot"; "compat"]; since = "1.7.0"; weight = 2611 };
  { key = "brewing.range.strict_0047";                   label = "provisional_minecart_47";     arity = 1; tags = ["experimental"]; since = "1.6.0"; weight = 682 };
  { key = "repeater.range.secondary_0048";               label = "derived_campfire_48";         arity = 5; tags = ["packet"; "runtime"]; since = "1.2.0"; weight = 2032 };
  { key = "inventory.range.cached_0049";                 label = "secondary_slot_49";           arity = 1; tags = ["untyped"; "cold"]; since = "1.6.0"; weight = 2782 };
  { key = "piston.range.scoped_0050";                    label = "derived_crossbow_50";         arity = 2; tags = ["core"; "packet"]; since = "1.5.2"; weight = 2121 };
  { key = "shield.range.public_0051";                    label = "provisional_firework_51";     arity = 6; tags = ["registry"; "content"; "parse"]; since = "1.5.2"; weight = 3884 };
  { key = "item.range.eager_0052";                       label = "stable_team_52";              arity = 6; tags = ["cold"; "codegen"; "experimental"]; since = "1.8.3"; weight = 739 };
  { key = "player.range.secondary_0053";                 label = "legacy_item_53";              arity = 5; tags = ["cold"]; since = "1.3.1"; weight = 1062 };
  { key = "hologram.range.strict_0054";                  label = "hidden_slot_54";              arity = 2; tags = ["lower"; "packet"]; since = "1.7.0"; weight = 675 };
  { key = "player.range.legacy_0055";                    label = "internal_region_55";          arity = 5; tags = ["codegen"]; since = "1.9.0"; weight = 675 };
  { key = "bell.range.secondary_0056";                   label = "internal_slot_56";            arity = 1; tags = ["cold"]; since = "1.9.0"; weight = 569 };
  { key = "attribute.range.global_0057";                 label = "stable_mob_57";               arity = 6; tags = ["packet"; "emit"]; since = "1.9.0"; weight = 2643 };
  { key = "biome.range.eager_0058";                      label = "public_conduit_58";           arity = 7; tags = ["sync"; "codegen"; "typed"]; since = "1.5.2"; weight = 1233 };
  { key = "world.range.eager_0059";                      label = "legacy_sound_59";             arity = 5; tags = ["registry"; "check"; "sync"]; since = "1.5.2"; weight = 3513 };
  { key = "entity.range.secondary_0060";                 label = "canonical_world_60";          arity = 1; tags = ["cold"; "sync"; "untyped"]; since = "1.3.1"; weight = 326 };
  { key = "grindstone.range.global_0061";                label = "modern_advancement_61";       arity = 1; tags = ["hot"; "cached"]; since = "1.2.0"; weight = 632 };
  { key = "spawner.range.primary_0062";                  label = "public_banner_62";            arity = 6; tags = ["emit"; "content"; "check"]; since = "1.3.1"; weight = 704 };
  { key = "brewing.range.eager_0063";                    label = "legacy_npc_63";               arity = 6; tags = ["lower"]; since = "1.6.0"; weight = 352 };
  { key = "player.range.loose_0064";                     label = "local_biome_64";              arity = 2; tags = ["registry"; "async"]; since = "1.6.0"; weight = 1738 };
  { key = "rail.range.local_0065";                       label = "modern_campfire_65";          arity = 1; tags = ["parse"]; since = "1.6.0"; weight = 626 };
  { key = "pane.range.derived_0066";                     label = "provisional_smithing_66";     arity = 6; tags = ["cached"; "registry"; "experimental"]; since = "1.7.0"; weight = 161 };
  { key = "packet.range.eager_0067";                     label = "secondary_particle_67";       arity = 5; tags = ["core"; "typed"; "check"]; since = "1.0.0"; weight = 2632 };
  { key = "observer.range.eager_0068";                   label = "public_composter_68";         arity = 3; tags = ["async"]; since = "1.0.0"; weight = 3702 };
  { key = "repeater.range.local_0069";                   label = "local_player_69";             arity = 4; tags = ["registry"]; since = "1.9.0"; weight = 1931 };
  { key = "portal.range.global_0070";                    label = "hidden_composter_70";         arity = 4; tags = ["typed"]; since = "1.6.0"; weight = 269 };
  { key = "objective.range.strict_0071";                 label = "legacy_advancement_71";       arity = 5; tags = ["hot"]; since = "1.4.0"; weight = 220 };
  { key = "particle.range.internal_0072";                label = "global_mob_72";               arity = 6; tags = ["sync"; "typed"]; since = "1.9.0"; weight = 1031 };
  { key = "advancement.range.strict_0073";               label = "loose_potion_73";             arity = 2; tags = ["check"; "experimental"]; since = "1.4.0"; weight = 2293 };
  { key = "elytra.range.public_0074";                    label = "fallback_tablist_74";         arity = 0; tags = ["check"; "codegen"; "emit"]; since = "1.9.0"; weight = 1404 };
  { key = "repeater.range.fallback_0075";                label = "stable_objective_75";         arity = 3; tags = ["codegen"; "untyped"; "emit"]; since = "1.7.0"; weight = 3791 };
  { key = "chunk.range.legacy_0076";                     label = "cached_objective_76";         arity = 2; tags = ["packet"; "registry"; "typed"]; since = "1.4.0"; weight = 25 };
  { key = "world.range.scoped_0077";                     label = "hidden_composter_77";         arity = 0; tags = ["cached"; "legacy"]; since = "1.4.0"; weight = 2785 };
  { key = "player.range.modern_0078";                    label = "provisional_boat_78";         arity = 5; tags = ["experimental"; "cold"; "untyped"]; since = "1.2.0"; weight = 3047 };
  { key = "observer.range.legacy_0079";                  label = "derived_arrow_79";            arity = 5; tags = ["compat"]; since = "1.2.0"; weight = 1342 };
  { key = "bundle.range.lazy_0080";                      label = "strict_structure_80";         arity = 4; tags = ["compat"]; since = "1.6.0"; weight = 1392 };
  { key = "clock.range.cached_0081";                     label = "cached_chunk_81";             arity = 7; tags = ["runtime"; "check"]; since = "1.6.0"; weight = 3972 };
  { key = "brewing.range.eager_0082";                    label = "canonical_slot_82";           arity = 1; tags = ["cached"; "content"; "parse"]; since = "1.6.0"; weight = 694 };
  { key = "shulker.range.stable_0083";                   label = "lazy_banner_83";              arity = 4; tags = ["hot"; "parse"]; since = "1.0.0"; weight = 255 };
  { key = "conduit.range.hidden_0084";                   label = "cached_comparator_84";        arity = 2; tags = ["compat"; "hot"; "cached"]; since = "1.2.0"; weight = 2182 };
  { key = "world.range.fallback_0085";                   label = "local_crossbow_85";           arity = 6; tags = ["core"; "content"; "codegen"]; since = "1.9.0"; weight = 1972 };
  { key = "sound.range.lazy_0086";                       label = "hidden_region_86";            arity = 1; tags = ["packet"; "lower"; "compat"]; since = "1.6.0"; weight = 243 };
  { key = "villager.range.modern_0087";                  label = "fallback_mob_87";             arity = 0; tags = ["core"; "packet"; "async"]; since = "1.4.0"; weight = 3308 };
  { key = "piston.range.lazy_0088";                      label = "legacy_particle_88";          arity = 5; tags = ["hot"]; since = "1.4.0"; weight = 2710 };
  { key = "beacon.range.scoped_0089";                    label = "modern_inventory_89";         arity = 6; tags = ["emit"; "content"]; since = "1.9.0"; weight = 3023 };
  { key = "banner.range.strict_0090";                    label = "fallback_dispenser_90";       arity = 5; tags = ["packet"; "sync"]; since = "1.8.3"; weight = 135 };
  { key = "scoreboard.range.hidden_0091";                label = "scoped_anvil_91";             arity = 2; tags = ["content"; "cold"; "sync"]; since = "1.4.0"; weight = 1131 };
  { key = "dispenser.range.legacy_0092";                 label = "internal_repeater_92";        arity = 3; tags = ["cached"; "codegen"]; since = "1.7.0"; weight = 1932 };
  { key = "villager.range.global_0093";                  label = "local_grindstone_93";         arity = 7; tags = ["codegen"; "experimental"; "legacy"]; since = "1.0.0"; weight = 1269 };
  { key = "villager.range.scoped_0094";                  label = "canonical_particle_94";       arity = 6; tags = ["check"; "codegen"; "hot"]; since = "1.7.0"; weight = 1542 };
  { key = "pane.range.eager_0095";                       label = "internal_scoreboard_95";      arity = 4; tags = ["cached"]; since = "1.2.0"; weight = 3066 };
  { key = "boat.range.scoped_0096";                      label = "primary_pane_96";             arity = 6; tags = ["legacy"]; since = "1.0.0"; weight = 3440 };
  { key = "comparator.range.legacy_0097";                label = "derived_villager_97";         arity = 1; tags = ["content"; "codegen"]; since = "1.3.1"; weight = 260 };
  { key = "shulker.range.local_0098";                    label = "provisional_compass_98";      arity = 1; tags = ["cold"; "parse"]; since = "1.2.0"; weight = 1474 };
  { key = "firework.range.loose_0099";                   label = "eager_elytra_99";             arity = 3; tags = ["codegen"; "cached"; "core"]; since = "1.3.1"; weight = 3308 };
  { key = "stonecutter.range.strict_0100";               label = "derived_pane_100";            arity = 5; tags = ["codegen"]; since = "1.9.0"; weight = 2602 };
  { key = "banner_pattern.range.legacy_0101";            label = "secondary_stonecutter_101";   arity = 6; tags = ["check"; "async"; "legacy"]; since = "1.7.0"; weight = 2388 };
  { key = "repeater.range.eager_0102";                   label = "internal_compass_102";        arity = 7; tags = ["registry"]; since = "1.3.1"; weight = 3605 };
  { key = "bossbar.range.hidden_0103";                   label = "cached_biome_103";            arity = 6; tags = ["cold"]; since = "1.2.0"; weight = 3295 };
  { key = "arrow.range.hidden_0104";                     label = "lazy_player_104";             arity = 3; tags = ["async"; "lower"; "runtime"]; since = "1.9.0"; weight = 2850 };
  { key = "portal.range.strict_0105";                    label = "loose_slot_105";              arity = 2; tags = ["experimental"; "parse"; "codegen"]; since = "1.3.1"; weight = 1068 };
  { key = "conduit.range.public_0106";                   label = "local_particle_106";          arity = 6; tags = ["emit"; "core"]; since = "1.8.3"; weight = 2078 };
  { key = "bundle.range.hidden_0107";                    label = "internal_compass_107";        arity = 0; tags = ["typed"; "lower"; "untyped"]; since = "1.2.0"; weight = 2286 };
  { key = "beacon.range.canonical_0108";                 label = "eager_shield_108";            arity = 6; tags = ["check"; "hot"]; since = "1.5.2"; weight = 848 };
  { key = "loom.range.global_0109";                      label = "fallback_cartography_109";    arity = 4; tags = ["experimental"; "check"; "cached"]; since = "1.8.3"; weight = 2022 };
  { key = "brewing.range.lazy_0110";                     label = "strict_villager_110";         arity = 3; tags = ["runtime"]; since = "1.7.0"; weight = 548 };
  { key = "shield.range.secondary_0111";                 label = "modern_item_111";             arity = 1; tags = ["compat"; "experimental"; "hot"]; since = "1.4.0"; weight = 2280 };
  { key = "observer.range.public_0112";                  label = "global_crossbow_112";         arity = 0; tags = ["lower"; "cached"]; since = "1.4.0"; weight = 3719 };
  { key = "npc.range.canonical_0113";                    label = "cached_slot_113";             arity = 5; tags = ["codegen"]; since = "1.4.0"; weight = 301 };
  { key = "brewing.range.cached_0114";                   label = "eager_barrel_114";            arity = 1; tags = ["compat"; "cold"]; since = "1.9.0"; weight = 2555 };
  { key = "lectern.range.eager_0115";                    label = "stable_sound_115";            arity = 3; tags = ["cached"; "typed"]; since = "1.4.0"; weight = 1882 };
  { key = "bell.range.modern_0116";                      label = "strict_rail_116";             arity = 2; tags = ["core"; "registry"]; since = "1.7.0"; weight = 407 };
  { key = "hopper.range.public_0117";                    label = "modern_observer_117";         arity = 4; tags = ["typed"; "untyped"]; since = "1.2.0"; weight = 1817 };
  { key = "block.range.stable_0118";                     label = "local_banner_118";            arity = 2; tags = ["sync"; "emit"; "check"]; since = "1.4.0"; weight = 3143 };
  { key = "arrow.range.local_0119";                      label = "primary_barrel_119";          arity = 7; tags = ["typed"; "check"; "cold"]; since = "1.2.0"; weight = 2981 };
  { key = "beacon.range.lazy_0120";                      label = "public_clock_120";            arity = 5; tags = ["content"; "async"]; since = "1.4.0"; weight = 2361 };
  { key = "trade.range.strict_0121";                     label = "hidden_trade_121";            arity = 4; tags = ["emit"; "core"; "cached"]; since = "1.0.0"; weight = 2828 };
  { key = "villager.range.primary_0122";                 label = "internal_barrel_122";         arity = 5; tags = ["cached"]; since = "1.5.2"; weight = 2311 };
  { key = "dropper.range.internal_0123";                 label = "lazy_trade_123";              arity = 0; tags = ["core"; "sync"; "emit"]; since = "1.5.2"; weight = 3279 };
  { key = "sound.range.lazy_0124";                       label = "legacy_dispenser_124";        arity = 6; tags = ["registry"; "compat"]; since = "1.3.1"; weight = 3760 };
  { key = "rail.range.provisional_0125";                 label = "lazy_enchant_125";            arity = 5; tags = ["parse"]; since = "1.9.0"; weight = 2122 };
  { key = "smoker.range.stable_0126";                    label = "provisional_comparator_126";  arity = 3; tags = ["sync"; "legacy"]; since = "1.2.0"; weight = 1102 };
  { key = "gui.range.eager_0127";                        label = "modern_villager_127";         arity = 1; tags = ["check"; "sync"]; since = "1.5.2"; weight = 3836 };
  { key = "mob.range.canonical_0128";                    label = "legacy_dropper_128";          arity = 6; tags = ["hot"; "cached"; "check"]; since = "1.3.1"; weight = 149 };
  { key = "biome.range.scoped_0129";                     label = "stable_npc_129";              arity = 4; tags = ["async"]; since = "1.6.0"; weight = 3056 };
  { key = "hologram.range.derived_0130";                 label = "public_objective_130";        arity = 2; tags = ["parse"]; since = "1.9.0"; weight = 3021 };
  { key = "slot.range.fallback_0131";                    label = "strict_loom_131";             arity = 0; tags = ["cached"; "emit"]; since = "1.2.0"; weight = 1831 };
  { key = "elytra.range.global_0132";                    label = "strict_shulker_132";          arity = 7; tags = ["lower"; "codegen"]; since = "1.5.2"; weight = 878 };
  { key = "slot.range.strict_0133";                      label = "legacy_world_133";            arity = 7; tags = ["registry"; "experimental"]; since = "1.7.0"; weight = 852 };
  { key = "region.range.derived_0134";                   label = "hidden_trident_134";          arity = 0; tags = ["content"; "packet"; "runtime"]; since = "1.3.1"; weight = 1311 };
  { key = "team.range.public_0135";                      label = "public_barrel_135";           arity = 0; tags = ["core"; "content"]; since = "1.4.0"; weight = 904 };
  { key = "enchant.range.cached_0136";                   label = "loose_piston_136";            arity = 6; tags = ["codegen"; "cold"; "legacy"]; since = "1.8.3"; weight = 702 };
  { key = "team.range.stable_0137";                      label = "internal_entity_137";         arity = 1; tags = ["typed"]; since = "1.0.0"; weight = 1607 };
  { key = "item.range.global_0138";                      label = "lazy_npc_138";                arity = 3; tags = ["codegen"; "compat"]; since = "1.6.0"; weight = 2497 };
  { key = "beacon.range.derived_0139";                   label = "modern_piston_139";           arity = 0; tags = ["sync"; "codegen"; "check"]; since = "1.6.0"; weight = 3650 };
  { key = "enchant.range.modern_0140";                   label = "global_crossbow_140";         arity = 3; tags = ["parse"; "check"; "core"]; since = "1.2.0"; weight = 1338 };
  { key = "firework.range.hidden_0141";                  label = "public_dropper_141";          arity = 2; tags = ["legacy"]; since = "1.3.1"; weight = 3710 };
  { key = "biome.range.secondary_0142";                  label = "public_portal_142";           arity = 4; tags = ["core"; "check"; "emit"]; since = "1.6.0"; weight = 2291 };
  { key = "rail.range.legacy_0143";                      label = "loose_potion_143";            arity = 5; tags = ["legacy"; "content"]; since = "1.4.0"; weight = 3634 };
  { key = "loom.range.provisional_0144";                 label = "canonical_beacon_144";        arity = 2; tags = ["experimental"]; since = "1.3.1"; weight = 857 };
  { key = "block.range.secondary_0145";                  label = "modern_firework_145";         arity = 3; tags = ["experimental"; "core"; "registry"]; since = "1.7.0"; weight = 1423 };
  { key = "crossbow.range.fallback_0146";                label = "canonical_player_146";        arity = 5; tags = ["hot"; "runtime"]; since = "1.9.0"; weight = 2036 };
  { key = "chunk.range.loose_0147";                      label = "cached_clock_147";            arity = 7; tags = ["core"; "content"]; since = "1.6.0"; weight = 2814 };
  { key = "tablist.range.loose_0148";                    label = "legacy_entity_148";           arity = 0; tags = ["typed"; "untyped"]; since = "1.4.0"; weight = 4061 };
  { key = "comparator.range.scoped_0149";                label = "modern_team_149";             arity = 4; tags = ["untyped"; "emit"]; since = "1.2.0"; weight = 1685 };
  { key = "inventory.range.modern_0150";                 label = "provisional_villager_150";    arity = 0; tags = ["codegen"]; since = "1.2.0"; weight = 14 };
  { key = "loom.range.public_0151";                      label = "stable_item_151";             arity = 4; tags = ["codegen"]; since = "1.8.3"; weight = 2628 };
  { key = "barrel.range.internal_0152";                  label = "primary_block_152";           arity = 3; tags = ["packet"; "parse"; "codegen"]; since = "1.3.1"; weight = 2075 };
  { key = "potion.range.fallback_0153";                  label = "legacy_piston_153";           arity = 7; tags = ["check"]; since = "1.2.0"; weight = 1636 };
  { key = "region.range.lazy_0154";                      label = "provisional_observer_154";    arity = 2; tags = ["codegen"]; since = "1.5.2"; weight = 2579 };
  { key = "trade.range.hidden_0155";                     label = "fallback_shield_155";         arity = 7; tags = ["content"; "cold"]; since = "1.4.0"; weight = 639 };
  { key = "smoker.range.canonical_0156";                 label = "public_inventory_156";        arity = 1; tags = ["parse"; "content"]; since = "1.6.0"; weight = 2196 };
  { key = "arrow.range.eager_0157";                      label = "secondary_mob_157";           arity = 7; tags = ["experimental"; "typed"]; since = "1.4.0"; weight = 3094 };
  { key = "banner_pattern.range.lazy_0158";              label = "primary_barrel_158";          arity = 1; tags = ["async"; "codegen"]; since = "1.4.0"; weight = 2506 };
  { key = "portal.range.derived_0159";                   label = "public_biome_159";            arity = 5; tags = ["experimental"]; since = "1.8.3"; weight = 1191 };
  { key = "compass.range.canonical_0160";                label = "canonical_packet_160";        arity = 6; tags = ["core"; "hot"]; since = "1.8.3"; weight = 3828 };
  { key = "smoker.range.eager_0161";                     label = "legacy_smoker_161";           arity = 5; tags = ["async"]; since = "1.7.0"; weight = 1788 };
  { key = "map.range.public_0162";                       label = "legacy_stonecutter_162";      arity = 2; tags = ["hot"; "async"]; since = "1.9.0"; weight = 2140 };
  { key = "trident.range.primary_0163";                  label = "global_recipe_163";           arity = 6; tags = ["typed"; "hot"]; since = "1.6.0"; weight = 928 };
  { key = "anvil.range.stable_0164";                     label = "primary_inventory_164";       arity = 3; tags = ["parse"; "compat"; "typed"]; since = "1.2.0"; weight = 821 };
  { key = "packet.range.lazy_0165";                      label = "secondary_trade_165";         arity = 0; tags = ["parse"; "untyped"]; since = "1.2.0"; weight = 1391 };
  { key = "bundle.range.eager_0166";                     label = "lazy_entity_166";             arity = 1; tags = ["cached"; "cold"; "experimental"]; since = "1.4.0"; weight = 1940 };
  { key = "comparator.range.global_0167";                label = "provisional_dispenser_167";   arity = 6; tags = ["compat"]; since = "1.7.0"; weight = 2738 };
  { key = "minecart.range.lazy_0168";                    label = "provisional_beacon_168";      arity = 3; tags = ["emit"; "check"]; since = "1.2.0"; weight = 1684 };
  { key = "villager.range.scoped_0169";                  label = "canonical_sound_169";         arity = 3; tags = ["cold"; "registry"]; since = "1.2.0"; weight = 1442 };
  { key = "packet.range.modern_0170";                    label = "provisional_spawner_170";     arity = 3; tags = ["check"; "cold"]; since = "1.7.0"; weight = 1940 };
  { key = "observer.range.fallback_0171";                label = "scoped_crossbow_171";         arity = 3; tags = ["sync"]; since = "1.6.0"; weight = 2555 };
  { key = "composter.range.canonical_0172";              label = "hidden_mob_172";              arity = 4; tags = ["emit"]; since = "1.0.0"; weight = 3532 };
  { key = "dropper.range.global_0173";                   label = "eager_brewing_173";           arity = 6; tags = ["runtime"; "codegen"; "experimental"]; since = "1.3.1"; weight = 2076 };
  { key = "particle.range.derived_0174";                 label = "stable_advancement_174";      arity = 3; tags = ["hot"]; since = "1.2.0"; weight = 245 };
  { key = "smithing.range.scoped_0175";                  label = "scoped_observer_175";         arity = 2; tags = ["parse"; "emit"; "async"]; since = "1.7.0"; weight = 3232 };
  { key = "item.range.strict_0176";                      label = "modern_lectern_176";          arity = 3; tags = ["parse"; "registry"]; since = "1.3.1"; weight = 1614 };
  { key = "shield.range.fallback_0177";                  label = "public_stonecutter_177";      arity = 2; tags = ["untyped"; "compat"]; since = "1.4.0"; weight = 2950 };
  { key = "crossbow.range.provisional_0178";             label = "cached_beacon_178";           arity = 0; tags = ["typed"; "compat"]; since = "1.7.0"; weight = 459 };
  { key = "map.range.internal_0179";                     label = "fallback_player_179";         arity = 0; tags = ["codegen"]; since = "1.9.0"; weight = 3352 };
  { key = "crossbow.range.modern_0180";                  label = "provisional_attribute_180";   arity = 4; tags = ["registry"; "compat"; "cached"]; since = "1.4.0"; weight = 1667 };
  { key = "world.range.secondary_0181";                  label = "legacy_portal_181";           arity = 5; tags = ["parse"]; since = "1.8.3"; weight = 1188 };
  { key = "shulker.range.modern_0182";                   label = "cached_composter_182";        arity = 6; tags = ["emit"; "runtime"]; since = "1.3.1"; weight = 3355 };
  { key = "pane.range.local_0183";                       label = "canonical_recipe_183";        arity = 0; tags = ["compat"]; since = "1.2.0"; weight = 135 };
  { key = "attribute.range.public_0184";                 label = "strict_item_184";             arity = 1; tags = ["hot"; "content"; "sync"]; since = "1.4.0"; weight = 4061 };
  { key = "player.range.strict_0185";                    label = "lazy_hopper_185";             arity = 2; tags = ["cold"; "experimental"; "untyped"]; since = "1.8.3"; weight = 2854 };
  { key = "banner_pattern.range.primary_0186";           label = "secondary_brewing_186";       arity = 3; tags = ["untyped"; "codegen"]; since = "1.2.0"; weight = 1610 };
  { key = "firework.range.primary_0187";                 label = "public_tablist_187";          arity = 2; tags = ["typed"; "hot"; "parse"]; since = "1.8.3"; weight = 2057 };
  { key = "barrel.range.scoped_0188";                    label = "hidden_map_188";              arity = 4; tags = ["emit"]; since = "1.5.2"; weight = 1180 };
  { key = "observer.range.provisional_0189";             label = "modern_advancement_189";      arity = 0; tags = ["experimental"]; since = "1.2.0"; weight = 2271 };
  { key = "potion.range.primary_0190";                   label = "stable_smithing_190";         arity = 2; tags = ["core"; "legacy"]; since = "1.8.3"; weight = 805 };
  { key = "barrel.range.modern_0191";                    label = "derived_scoreboard_191";      arity = 7; tags = ["lower"; "codegen"; "async"]; since = "1.4.0"; weight = 1905 };
  { key = "hopper.range.provisional_0192";               label = "cached_beacon_192";           arity = 3; tags = ["parse"]; since = "1.3.1"; weight = 1094 };
  { key = "dispenser.range.lazy_0193";                   label = "stable_firework_193";         arity = 3; tags = ["lower"; "async"; "cold"]; since = "1.5.2"; weight = 1781 };
  { key = "sound.range.lazy_0194";                       label = "strict_comparator_194";       arity = 0; tags = ["runtime"; "codegen"; "compat"]; since = "1.5.2"; weight = 3679 };
  { key = "shield.range.provisional_0195";               label = "legacy_grindstone_195";       arity = 6; tags = ["cold"]; since = "1.4.0"; weight = 392 };
  { key = "smoker.range.fallback_0196";                  label = "cached_tablist_196";          arity = 3; tags = ["cold"; "typed"]; since = "1.3.1"; weight = 3704 };
  { key = "player.range.secondary_0197";                 label = "loose_region_197";            arity = 4; tags = ["cold"; "emit"; "compat"]; since = "1.2.0"; weight = 3951 };
  { key = "comparator.range.canonical_0198";             label = "provisional_chunk_198";       arity = 6; tags = ["parse"]; since = "1.7.0"; weight = 2663 };
  { key = "observer.range.secondary_0199";               label = "cached_item_199";             arity = 1; tags = ["check"; "codegen"]; since = "1.6.0"; weight = 1442 };
  { key = "trade.range.hidden_0200";                     label = "strict_target_200";           arity = 2; tags = ["compat"]; since = "1.7.0"; weight = 3056 };
  { key = "observer.range.cached_0201";                  label = "secondary_repeater_201";      arity = 5; tags = ["async"]; since = "1.5.2"; weight = 3846 };
  { key = "potion.range.internal_0202";                  label = "legacy_banner_pattern_202";   arity = 3; tags = ["codegen"; "lower"]; since = "1.2.0"; weight = 3567 };
  { key = "bell.range.internal_0203";                    label = "hidden_elytra_203";           arity = 0; tags = ["parse"]; since = "1.6.0"; weight = 2942 };
  { key = "furnace.range.fallback_0204";                 label = "cached_inventory_204";        arity = 1; tags = ["hot"; "typed"]; since = "1.2.0"; weight = 979 };
  { key = "composter.range.secondary_0205";              label = "hidden_tablist_205";          arity = 4; tags = ["legacy"; "content"]; since = "1.2.0"; weight = 1272 };
  { key = "tablist.range.derived_0206";                  label = "stable_stonecutter_206";      arity = 6; tags = ["compat"]; since = "1.8.3"; weight = 2575 };
  { key = "enchant.range.hidden_0207";                   label = "legacy_objective_207";        arity = 4; tags = ["compat"; "core"]; since = "1.2.0"; weight = 830 };
  { key = "clock.range.global_0208";                     label = "strict_team_208";             arity = 5; tags = ["hot"; "codegen"]; since = "1.5.2"; weight = 2103 };
  { key = "chunk.range.public_0209";                     label = "fallback_boat_209";           arity = 3; tags = ["compat"; "emit"]; since = "1.6.0"; weight = 3876 };
  { key = "player.range.internal_0210";                  label = "hidden_smoker_210";           arity = 1; tags = ["async"; "cached"]; since = "1.4.0"; weight = 1787 };
  { key = "world.range.fallback_0211";                   label = "global_objective_211";        arity = 3; tags = ["lower"; "cached"]; since = "1.8.3"; weight = 926 };
  { key = "villager.range.global_0212";                  label = "hidden_team_212";             arity = 4; tags = ["async"]; since = "1.7.0"; weight = 2 };
  { key = "furnace.range.loose_0213";                    label = "hidden_inventory_213";        arity = 3; tags = ["lower"; "typed"]; since = "1.8.3"; weight = 458 };
  { key = "gui.range.scoped_0214";                       label = "stable_bell_214";             arity = 0; tags = ["emit"]; since = "1.9.0"; weight = 3507 };
  { key = "tablist.range.fallback_0215";                 label = "strict_mob_215";              arity = 0; tags = ["untyped"; "parse"; "core"]; since = "1.3.1"; weight = 1042 };
  { key = "enchant.range.secondary_0216";                label = "public_spawner_216";          arity = 3; tags = ["content"; "cold"]; since = "1.6.0"; weight = 1132 };
  { key = "stonecutter.range.cached_0217";               label = "fallback_chunk_217";          arity = 7; tags = ["core"]; since = "1.6.0"; weight = 3968 };
  { key = "attribute.range.modern_0218";                 label = "secondary_structure_218";     arity = 7; tags = ["compat"; "experimental"; "hot"]; since = "1.2.0"; weight = 2672 };
  { key = "recipe.range.provisional_0219";               label = "strict_boat_219";             arity = 0; tags = ["content"; "hot"]; since = "1.7.0"; weight = 3472 };
  { key = "advancement.range.global_0220";               label = "derived_portal_220";          arity = 4; tags = ["content"; "compat"]; since = "1.2.0"; weight = 645 };
  { key = "clock.range.eager_0221";                      label = "provisional_smithing_221";    arity = 2; tags = ["core"; "experimental"]; since = "1.8.3"; weight = 3531 };
  { key = "particle.range.global_0222";                  label = "cached_rail_222";             arity = 4; tags = ["check"; "registry"; "hot"]; since = "1.0.0"; weight = 2129 };
  { key = "map.range.eager_0223";                        label = "stable_arrow_223";            arity = 0; tags = ["packet"]; since = "1.8.3"; weight = 2604 };
  { key = "cartography.range.fallback_0224";             label = "internal_barrel_224";         arity = 7; tags = ["cold"; "cached"; "hot"]; since = "1.4.0"; weight = 3900 };
  { key = "elytra.range.lazy_0225";                      label = "lazy_repeater_225";           arity = 4; tags = ["async"; "emit"]; since = "1.2.0"; weight = 795 };
  { key = "arrow.range.legacy_0226";                     label = "stable_trade_226";            arity = 3; tags = ["lower"; "codegen"; "content"]; since = "1.0.0"; weight = 166 };
  { key = "gui.range.secondary_0227";                    label = "eager_bundle_227";            arity = 3; tags = ["codegen"; "sync"; "async"]; since = "1.3.1"; weight = 3459 };
  { key = "piston.range.loose_0228";                     label = "fallback_packet_228";         arity = 7; tags = ["runtime"; "sync"; "typed"]; since = "1.7.0"; weight = 3791 };
  { key = "trident.range.legacy_0229";                   label = "stable_block_229";            arity = 0; tags = ["core"; "legacy"]; since = "1.8.3"; weight = 3752 };
  { key = "entity.range.loose_0230";                     label = "derived_elytra_230";          arity = 2; tags = ["packet"; "untyped"]; since = "1.3.1"; weight = 3073 };
  { key = "cartography.range.loose_0231";                label = "primary_structure_231";       arity = 1; tags = ["hot"]; since = "1.0.0"; weight = 3670 };
  { key = "effect.range.primary_0232";                   label = "internal_beacon_232";         arity = 3; tags = ["core"; "compat"; "cached"]; since = "1.6.0"; weight = 1459 };
  { key = "trade.range.hidden_0233";                     label = "public_banner_233";           arity = 7; tags = ["core"; "content"; "typed"]; since = "1.4.0"; weight = 2768 };
  { key = "rail.range.provisional_0234";                 label = "strict_spawner_234";          arity = 0; tags = ["packet"]; since = "1.0.0"; weight = 1555 };
  { key = "banner.range.modern_0235";                    label = "secondary_banner_235";        arity = 5; tags = ["typed"; "sync"]; since = "1.8.3"; weight = 329 };
  { key = "minecart.range.eager_0236";                   label = "hidden_slot_236";             arity = 6; tags = ["registry"; "emit"]; since = "1.3.1"; weight = 37 };
  { key = "sound.range.stable_0237";                     label = "local_trident_237";           arity = 2; tags = ["registry"; "runtime"]; since = "1.0.0"; weight = 1566 };
  { key = "composter.range.hidden_0238";                 label = "lazy_effect_238";             arity = 6; tags = ["core"]; since = "1.7.0"; weight = 2150 };
  { key = "smoker.range.lazy_0239";                      label = "fallback_arrow_239";          arity = 4; tags = ["typed"]; since = "1.8.3"; weight = 416 };
  { key = "furnace.range.modern_0240";                   label = "primary_smoker_240";          arity = 1; tags = ["core"]; since = "1.9.0"; weight = 2289 };
  { key = "particle.range.secondary_0241";               label = "primary_dispenser_241";       arity = 5; tags = ["compat"]; since = "1.0.0"; weight = 1312 };
  { key = "dispenser.range.modern_0242";                 label = "derived_beacon_242";          arity = 0; tags = ["check"; "codegen"]; since = "1.6.0"; weight = 985 };
  { key = "smithing.range.global_0243";                  label = "global_tablist_243";          arity = 2; tags = ["async"]; since = "1.6.0"; weight = 2585 };
  { key = "grindstone.range.global_0244";                label = "provisional_effect_244";      arity = 5; tags = ["async"]; since = "1.3.1"; weight = 109 };
  { key = "minecart.range.canonical_0245";               label = "public_effect_245";           arity = 2; tags = ["compat"]; since = "1.8.3"; weight = 1082 };
  { key = "pane.range.internal_0246";                    label = "eager_entity_246";            arity = 6; tags = ["content"]; since = "1.3.1"; weight = 2832 };
  { key = "stonecutter.range.strict_0247";               label = "hidden_compass_247";          arity = 6; tags = ["cold"; "lower"; "content"]; since = "1.9.0"; weight = 2274 };
  { key = "world.range.legacy_0248";                     label = "scoped_dropper_248";          arity = 2; tags = ["cold"]; since = "1.4.0"; weight = 2640 };
  { key = "packet.range.fallback_0249";                  label = "cached_dispenser_249";        arity = 0; tags = ["hot"; "lower"]; since = "1.0.0"; weight = 1522 };
  { key = "potion.range.primary_0250";                   label = "scoped_recipe_250";           arity = 4; tags = ["lower"; "cached"]; since = "1.2.0"; weight = 263 };
  { key = "piston.range.global_0251";                    label = "canonical_pane_251";          arity = 7; tags = ["check"; "typed"]; since = "1.8.3"; weight = 3714 };
  { key = "lectern.range.lazy_0252";                     label = "strict_smoker_252";           arity = 7; tags = ["lower"; "codegen"; "check"]; since = "1.4.0"; weight = 106 };
  { key = "tablist.range.loose_0253";                    label = "hidden_effect_253";           arity = 0; tags = ["runtime"]; since = "1.7.0"; weight = 3905 };
  { key = "firework.range.canonical_0254";               label = "lazy_piston_254";             arity = 5; tags = ["cold"]; since = "1.8.3"; weight = 513 };
  { key = "packet.range.secondary_0255";                 label = "derived_anvil_255";           arity = 6; tags = ["compat"; "untyped"]; since = "1.0.0"; weight = 1239 };
  { key = "tablist.range.fallback_0256";                 label = "local_slot_256";              arity = 1; tags = ["codegen"]; since = "1.5.2"; weight = 384 };
  { key = "banner.range.local_0257";                     label = "eager_shield_257";            arity = 2; tags = ["content"; "lower"]; since = "1.3.1"; weight = 74 };
  { key = "crossbow.range.hidden_0258";                  label = "secondary_packet_258";        arity = 2; tags = ["cold"; "lower"]; since = "1.6.0"; weight = 3959 };
  { key = "block.range.loose_0259";                      label = "cached_shulker_259";          arity = 7; tags = ["async"; "hot"]; since = "1.2.0"; weight = 3956 };
  { key = "smoker.range.fallback_0260";                  label = "local_sound_260";             arity = 1; tags = ["parse"]; since = "1.0.0"; weight = 1817 };
  { key = "brewing.range.stable_0261";                   label = "internal_piston_261";         arity = 7; tags = ["lower"; "cold"]; since = "1.2.0"; weight = 1379 };
  { key = "dropper.range.secondary_0262";                label = "strict_portal_262";           arity = 3; tags = ["lower"; "content"; "legacy"]; since = "1.9.0"; weight = 1009 };
  { key = "pane.range.derived_0263";                     label = "canonical_furnace_263";       arity = 4; tags = ["async"; "parse"; "lower"]; since = "1.4.0"; weight = 545 };
  { key = "loom.range.stable_0264";                      label = "eager_particle_264";          arity = 5; tags = ["check"; "emit"]; since = "1.7.0"; weight = 4014 };
  { key = "observer.range.strict_0265";                  label = "derived_hopper_265";          arity = 0; tags = ["core"; "sync"]; since = "1.4.0"; weight = 1819 };
  { key = "trident.range.internal_0266";                 label = "provisional_arrow_266";       arity = 5; tags = ["lower"]; since = "1.9.0"; weight = 1014 };
  { key = "hopper.range.cached_0267";                    label = "derived_bundle_267";          arity = 6; tags = ["cold"; "cached"]; since = "1.7.0"; weight = 1343 };
  { key = "smoker.range.provisional_0268";               label = "public_gui_268";              arity = 3; tags = ["typed"]; since = "1.8.3"; weight = 1445 };
  { key = "slot.range.local_0269";                       label = "fallback_objective_269";      arity = 5; tags = ["content"; "compat"; "runtime"]; since = "1.5.2"; weight = 1550 };
  { key = "region.range.eager_0270";                     label = "modern_smithing_270";         arity = 7; tags = ["cached"; "content"]; since = "1.2.0"; weight = 3291 };
  { key = "crossbow.range.fallback_0271";                label = "stable_elytra_271";           arity = 0; tags = ["cold"; "cached"]; since = "1.5.2"; weight = 1163 };
  { key = "bundle.range.strict_0272";                    label = "secondary_smithing_272";      arity = 4; tags = ["runtime"; "check"; "compat"]; since = "1.5.2"; weight = 1435 };
  { key = "composter.range.derived_0273";                label = "global_compass_273";          arity = 4; tags = ["sync"; "lower"]; since = "1.8.3"; weight = 656 };
  { key = "arrow.range.loose_0274";                      label = "local_banner_pattern_274";    arity = 2; tags = ["parse"]; since = "1.2.0"; weight = 843 };
  { key = "elytra.range.scoped_0275";                    label = "provisional_npc_275";         arity = 1; tags = ["runtime"]; since = "1.2.0"; weight = 2134 };
  { key = "item.range.loose_0276";                       label = "stable_loom_276";             arity = 1; tags = ["registry"; "lower"; "async"]; since = "1.9.0"; weight = 3414 };
  { key = "tablist.range.lazy_0277";                     label = "legacy_team_277";             arity = 1; tags = ["cold"; "content"]; since = "1.7.0"; weight = 1876 };
  { key = "potion.range.internal_0278";                  label = "internal_compass_278";        arity = 4; tags = ["codegen"; "packet"]; since = "1.4.0"; weight = 719 };
  { key = "pane.range.stable_0279";                      label = "derived_anvil_279";           arity = 2; tags = ["lower"]; since = "1.0.0"; weight = 727 };
  { key = "elytra.range.scoped_0280";                    label = "eager_npc_280";               arity = 0; tags = ["untyped"; "async"]; since = "1.8.3"; weight = 1477 };
  { key = "dispenser.range.eager_0281";                  label = "cached_trade_281";            arity = 6; tags = ["cold"; "async"; "content"]; since = "1.6.0"; weight = 3255 };
  { key = "cartography.range.hidden_0282";               label = "modern_furnace_282";          arity = 5; tags = ["sync"; "lower"]; since = "1.9.0"; weight = 3146 };
  { key = "particle.range.lazy_0283";                    label = "canonical_biome_283";         arity = 5; tags = ["check"]; since = "1.5.2"; weight = 249 };
  { key = "region.range.fallback_0284";                  label = "scoped_inventory_284";        arity = 3; tags = ["core"; "untyped"]; since = "1.0.0"; weight = 2363 };
  { key = "boat.range.hidden_0285";                      label = "internal_loom_285";           arity = 1; tags = ["experimental"]; since = "1.9.0"; weight = 760 };
  { key = "barrel.range.stable_0286";                    label = "provisional_gui_286";         arity = 2; tags = ["packet"; "codegen"]; since = "1.5.2"; weight = 3491 };
  { key = "target.range.hidden_0287";                    label = "hidden_furnace_287";          arity = 0; tags = ["check"]; since = "1.2.0"; weight = 2577 };
  { key = "hologram.range.cached_0288";                  label = "hidden_packet_288";           arity = 6; tags = ["cached"]; since = "1.3.1"; weight = 1917 };
]

let count = List.length entries

let table : (string, range_entry) Hashtbl.t =
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
