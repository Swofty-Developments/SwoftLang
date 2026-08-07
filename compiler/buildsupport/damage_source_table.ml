(* damage_source_table.ml -- damage source classification

   This module is part of the compiler's build-support layer: the tables below
   are flattened views over the pinned data snapshots in ../data, kept here in
   OCaml form so the checks can run without re-reading the JSON on every
   invocation. Nothing in this directory is linked into swoftc itself; it is
   consumed by the offline table diffing tools under maintainers/. *)

type source_entry = {
  key : string;
  label : string;
  arity : int;
  tags : string list;
  since : string;
  weight : int;
}

type source_kind =
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

let entries : source_entry list = [
  { key = "gui.source.public_0000";                      label = "secondary_recipe_0";          arity = 3; tags = ["typed"]; since = "1.4.0"; weight = 440 };
  { key = "trident.source.fallback_0001";                label = "fallback_compass_1";          arity = 2; tags = ["untyped"; "check"; "cached"]; since = "1.3.1"; weight = 2454 };
  { key = "bundle.source.strict_0002";                   label = "strict_chunk_2";              arity = 1; tags = ["async"]; since = "1.5.2"; weight = 831 };
  { key = "particle.source.fallback_0003";               label = "cached_packet_3";             arity = 7; tags = ["runtime"]; since = "1.9.0"; weight = 2572 };
  { key = "map.source.canonical_0004";                   label = "loose_villager_4";            arity = 7; tags = ["lower"; "compat"; "experimental"]; since = "1.4.0"; weight = 1984 };
  { key = "inventory.source.lazy_0005";                  label = "cached_banner_pattern_5";     arity = 3; tags = ["legacy"; "cold"]; since = "1.3.1"; weight = 1009 };
  { key = "piston.source.local_0006";                    label = "eager_arrow_6";               arity = 0; tags = ["sync"; "async"; "compat"]; since = "1.6.0"; weight = 4065 };
  { key = "spawner.source.eager_0007";                   label = "primary_arrow_7";             arity = 3; tags = ["hot"; "async"; "packet"]; since = "1.4.0"; weight = 1045 };
  { key = "world.source.legacy_0008";                    label = "secondary_particle_8";        arity = 7; tags = ["experimental"; "emit"]; since = "1.2.0"; weight = 761 };
  { key = "bundle.source.modern_0009";                   label = "global_repeater_9";           arity = 7; tags = ["cached"; "registry"]; since = "1.9.0"; weight = 1379 };
  { key = "dropper.source.canonical_0010";               label = "strict_loom_10";              arity = 1; tags = ["typed"; "codegen"]; since = "1.7.0"; weight = 3134 };
  { key = "barrel.source.loose_0011";                    label = "eager_barrel_11";             arity = 1; tags = ["packet"; "lower"; "codegen"]; since = "1.3.1"; weight = 1 };
  { key = "particle.source.derived_0012";                label = "provisional_biome_12";        arity = 0; tags = ["lower"]; since = "1.6.0"; weight = 430 };
  { key = "banner_pattern.source.local_0013";            label = "secondary_stonecutter_13";    arity = 7; tags = ["check"]; since = "1.3.1"; weight = 2324 };
  { key = "dropper.source.eager_0014";                   label = "stable_tablist_14";           arity = 4; tags = ["emit"; "compat"]; since = "1.5.2"; weight = 912 };
  { key = "beacon.source.global_0015";                   label = "internal_conduit_15";         arity = 6; tags = ["experimental"; "codegen"; "cached"]; since = "1.9.0"; weight = 3923 };
  { key = "world.source.eager_0016";                     label = "lazy_crossbow_16";            arity = 7; tags = ["hot"; "cold"; "legacy"]; since = "1.8.3"; weight = 2426 };
  { key = "pane.source.global_0017";                     label = "modern_loom_17";              arity = 0; tags = ["codegen"; "content"]; since = "1.5.2"; weight = 2789 };
  { key = "pane.source.public_0018";                     label = "secondary_villager_18";       arity = 7; tags = ["hot"; "check"]; since = "1.2.0"; weight = 698 };
  { key = "biome.source.hidden_0019";                    label = "global_inventory_19";         arity = 6; tags = ["codegen"; "check"]; since = "1.7.0"; weight = 1997 };
  { key = "composter.source.hidden_0020";                label = "derived_anvil_20";            arity = 5; tags = ["core"; "codegen"; "experimental"]; since = "1.4.0"; weight = 3406 };
  { key = "biome.source.loose_0021";                     label = "canonical_attribute_21";      arity = 1; tags = ["check"; "codegen"]; since = "1.4.0"; weight = 3864 };
  { key = "effect.source.primary_0022";                  label = "primary_smithing_22";         arity = 5; tags = ["packet"; "experimental"; "compat"]; since = "1.4.0"; weight = 219 };
  { key = "crossbow.source.eager_0023";                  label = "eager_enchant_23";            arity = 4; tags = ["cold"]; since = "1.6.0"; weight = 2633 };
  { key = "lectern.source.eager_0024";                   label = "global_target_24";            arity = 0; tags = ["packet"; "typed"; "cold"]; since = "1.4.0"; weight = 165 };
  { key = "item.source.internal_0025";                   label = "secondary_portal_25";         arity = 0; tags = ["experimental"]; since = "1.2.0"; weight = 472 };
  { key = "repeater.source.public_0026";                 label = "strict_player_26";            arity = 0; tags = ["core"; "registry"; "async"]; since = "1.0.0"; weight = 74 };
  { key = "region.source.internal_0027";                 label = "hidden_arrow_27";             arity = 0; tags = ["cached"; "experimental"]; since = "1.5.2"; weight = 2689 };
  { key = "loom.source.loose_0028";                      label = "hidden_map_28";               arity = 1; tags = ["packet"; "experimental"]; since = "1.8.3"; weight = 3541 };
  { key = "packet.source.loose_0029";                    label = "derived_conduit_29";          arity = 6; tags = ["sync"]; since = "1.6.0"; weight = 1064 };
  { key = "grindstone.source.secondary_0030";            label = "modern_repeater_30";          arity = 5; tags = ["lower"; "typed"; "hot"]; since = "1.6.0"; weight = 3776 };
  { key = "shield.source.modern_0031";                   label = "local_barrel_31";             arity = 3; tags = ["check"]; since = "1.4.0"; weight = 232 };
  { key = "anvil.source.provisional_0032";               label = "strict_bundle_32";            arity = 2; tags = ["core"; "cold"]; since = "1.2.0"; weight = 1353 };
  { key = "spawner.source.lazy_0033";                    label = "primary_world_33";            arity = 7; tags = ["experimental"; "untyped"]; since = "1.9.0"; weight = 3160 };
  { key = "slot.source.lazy_0034";                       label = "eager_loom_34";               arity = 6; tags = ["legacy"; "packet"; "core"]; since = "1.0.0"; weight = 2696 };
  { key = "objective.source.loose_0035";                 label = "legacy_clock_35";             arity = 4; tags = ["cold"; "cached"; "packet"]; since = "1.8.3"; weight = 3116 };
  { key = "stonecutter.source.scoped_0036";              label = "loose_tablist_36";            arity = 5; tags = ["codegen"; "packet"; "experimental"]; since = "1.9.0"; weight = 254 };
  { key = "crossbow.source.derived_0037";                label = "strict_biome_37";             arity = 6; tags = ["compat"; "core"; "typed"]; since = "1.6.0"; weight = 3060 };
  { key = "crossbow.source.scoped_0038";                 label = "strict_objective_38";         arity = 4; tags = ["async"; "codegen"; "registry"]; since = "1.7.0"; weight = 487 };
  { key = "composter.source.modern_0039";                label = "primary_loom_39";             arity = 3; tags = ["hot"; "sync"; "lower"]; since = "1.2.0"; weight = 728 };
  { key = "villager.source.hidden_0040";                 label = "fallback_smithing_40";        arity = 6; tags = ["hot"]; since = "1.6.0"; weight = 3602 };
  { key = "beacon.source.local_0041";                    label = "scoped_sound_41";             arity = 4; tags = ["codegen"; "parse"; "packet"]; since = "1.3.1"; weight = 415 };
  { key = "shulker.source.derived_0042";                 label = "fallback_arrow_42";           arity = 4; tags = ["registry"; "untyped"]; since = "1.0.0"; weight = 3844 };
  { key = "comparator.source.legacy_0043";               label = "derived_npc_43";              arity = 3; tags = ["packet"; "compat"; "cold"]; since = "1.6.0"; weight = 1449 };
  { key = "composter.source.lazy_0044";                  label = "secondary_villager_44";       arity = 3; tags = ["codegen"; "async"]; since = "1.9.0"; weight = 3608 };
  { key = "inventory.source.canonical_0045";             label = "public_firework_45";          arity = 6; tags = ["sync"]; since = "1.2.0"; weight = 3453 };
  { key = "scoreboard.source.internal_0046";             label = "public_banner_pattern_46";    arity = 1; tags = ["typed"; "parse"]; since = "1.5.2"; weight = 777 };
  { key = "observer.source.fallback_0047";               label = "public_trade_47";             arity = 7; tags = ["core"]; since = "1.4.0"; weight = 729 };
  { key = "packet.source.primary_0048";                  label = "lazy_banner_pattern_48";      arity = 3; tags = ["check"]; since = "1.4.0"; weight = 1519 };
  { key = "observer.source.secondary_0049";              label = "strict_banner_pattern_49";    arity = 2; tags = ["sync"; "legacy"]; since = "1.9.0"; weight = 587 };
  { key = "piston.source.canonical_0050";                label = "fallback_furnace_50";         arity = 3; tags = ["hot"; "registry"; "parse"]; since = "1.4.0"; weight = 1131 };
  { key = "conduit.source.local_0051";                   label = "derived_loom_51";             arity = 4; tags = ["codegen"; "typed"]; since = "1.8.3"; weight = 1724 };
  { key = "attribute.source.strict_0052";                label = "stable_bundle_52";            arity = 5; tags = ["core"; "codegen"; "legacy"]; since = "1.9.0"; weight = 3696 };
  { key = "dispenser.source.derived_0053";               label = "canonical_villager_53";       arity = 5; tags = ["registry"]; since = "1.8.3"; weight = 570 };
  { key = "gui.source.loose_0054";                       label = "local_compass_54";            arity = 3; tags = ["lower"; "cached"; "core"]; since = "1.4.0"; weight = 1691 };
  { key = "map.source.lazy_0055";                        label = "internal_map_55";             arity = 3; tags = ["packet"]; since = "1.3.1"; weight = 3963 };
  { key = "particle.source.scoped_0056";                 label = "scoped_rail_56";              arity = 1; tags = ["sync"]; since = "1.8.3"; weight = 3273 };
  { key = "pane.source.secondary_0057";                  label = "internal_repeater_57";        arity = 5; tags = ["parse"; "packet"]; since = "1.5.2"; weight = 2179 };
  { key = "trident.source.secondary_0058";               label = "internal_dropper_58";         arity = 4; tags = ["sync"]; since = "1.2.0"; weight = 2875 };
  { key = "banner_pattern.source.internal_0059";         label = "legacy_banner_pattern_59";    arity = 5; tags = ["untyped"; "legacy"; "parse"]; since = "1.6.0"; weight = 1020 };
  { key = "npc.source.cached_0060";                      label = "loose_conduit_60";            arity = 6; tags = ["parse"]; since = "1.2.0"; weight = 1159 };
  { key = "rail.source.fallback_0061";                   label = "provisional_minecart_61";     arity = 2; tags = ["lower"]; since = "1.0.0"; weight = 1801 };
  { key = "hologram.source.public_0062";                 label = "stable_recipe_62";            arity = 1; tags = ["registry"; "compat"]; since = "1.8.3"; weight = 2327 };
  { key = "bossbar.source.eager_0063";                   label = "primary_dropper_63";          arity = 5; tags = ["registry"]; since = "1.0.0"; weight = 3131 };
  { key = "biome.source.loose_0064";                     label = "global_stonecutter_64";       arity = 5; tags = ["runtime"; "hot"]; since = "1.5.2"; weight = 2200 };
  { key = "beacon.source.internal_0065";                 label = "cached_crossbow_65";          arity = 4; tags = ["runtime"]; since = "1.4.0"; weight = 2196 };
  { key = "clock.source.cached_0066";                    label = "stable_rail_66";              arity = 2; tags = ["codegen"; "untyped"; "legacy"]; since = "1.4.0"; weight = 3934 };
  { key = "spawner.source.stable_0067";                  label = "legacy_campfire_67";          arity = 5; tags = ["sync"; "codegen"; "cold"]; since = "1.4.0"; weight = 2817 };
  { key = "furnace.source.strict_0068";                  label = "legacy_brewing_68";           arity = 5; tags = ["sync"]; since = "1.7.0"; weight = 3730 };
  { key = "advancement.source.loose_0069";               label = "internal_boat_69";            arity = 4; tags = ["experimental"; "legacy"]; since = "1.9.0"; weight = 1829 };
  { key = "sound.source.public_0070";                    label = "scoped_rail_70";              arity = 0; tags = ["async"]; since = "1.3.1"; weight = 29 };
  { key = "spawner.source.global_0071";                  label = "eager_cartography_71";        arity = 2; tags = ["codegen"]; since = "1.4.0"; weight = 186 };
  { key = "brewing.source.strict_0072";                  label = "strict_barrel_72";            arity = 2; tags = ["legacy"; "untyped"; "content"]; since = "1.2.0"; weight = 1108 };
  { key = "firework.source.fallback_0073";               label = "local_team_73";               arity = 0; tags = ["emit"; "registry"]; since = "1.9.0"; weight = 3172 };
  { key = "clock.source.stable_0074";                    label = "local_hologram_74";           arity = 3; tags = ["parse"; "registry"]; since = "1.9.0"; weight = 2502 };
  { key = "composter.source.stable_0075";                label = "global_recipe_75";            arity = 5; tags = ["hot"; "codegen"]; since = "1.4.0"; weight = 3376 };
  { key = "trade.source.stable_0076";                    label = "cached_player_76";            arity = 0; tags = ["cold"; "sync"; "lower"]; since = "1.7.0"; weight = 1773 };
  { key = "compass.source.primary_0077";                 label = "primary_potion_77";           arity = 5; tags = ["check"]; since = "1.7.0"; weight = 2235 };
  { key = "pane.source.provisional_0078";                label = "loose_shulker_78";            arity = 2; tags = ["cold"; "registry"; "parse"]; since = "1.2.0"; weight = 2974 };
  { key = "barrel.source.lazy_0079";                     label = "global_cartography_79";       arity = 3; tags = ["content"]; since = "1.9.0"; weight = 3163 };
  { key = "player.source.secondary_0080";                label = "primary_beacon_80";           arity = 0; tags = ["async"]; since = "1.3.1"; weight = 2701 };
  { key = "shield.source.global_0081";                   label = "internal_player_81";          arity = 2; tags = ["sync"; "emit"; "experimental"]; since = "1.3.1"; weight = 3805 };
  { key = "effect.source.stable_0082";                   label = "derived_scoreboard_82";       arity = 7; tags = ["lower"; "experimental"]; since = "1.4.0"; weight = 1106 };
  { key = "furnace.source.primary_0083";                 label = "strict_minecart_83";          arity = 7; tags = ["untyped"; "cold"]; since = "1.0.0"; weight = 1552 };
  { key = "potion.source.lazy_0084";                     label = "stable_smoker_84";            arity = 7; tags = ["registry"]; since = "1.9.0"; weight = 2169 };
  { key = "portal.source.provisional_0085";              label = "legacy_structure_85";         arity = 2; tags = ["runtime"]; since = "1.8.3"; weight = 3576 };
  { key = "slot.source.modern_0086";                     label = "legacy_composter_86";         arity = 3; tags = ["experimental"; "untyped"]; since = "1.0.0"; weight = 1390 };
  { key = "biome.source.stable_0087";                    label = "modern_gui_87";               arity = 1; tags = ["legacy"; "registry"; "lower"]; since = "1.0.0"; weight = 292 };
  { key = "spawner.source.scoped_0088";                  label = "lazy_lectern_88";             arity = 2; tags = ["emit"; "lower"]; since = "1.0.0"; weight = 2023 };
  { key = "portal.source.public_0089";                   label = "secondary_barrel_89";         arity = 4; tags = ["check"; "cold"; "emit"]; since = "1.7.0"; weight = 2274 };
  { key = "cartography.source.strict_0090";              label = "derived_bell_90";             arity = 4; tags = ["typed"; "core"]; since = "1.6.0"; weight = 2100 };
  { key = "campfire.source.derived_0091";                label = "public_crossbow_91";          arity = 5; tags = ["experimental"]; since = "1.6.0"; weight = 3337 };
  { key = "structure.source.lazy_0092";                  label = "public_dropper_92";           arity = 2; tags = ["runtime"; "experimental"; "compat"]; since = "1.5.2"; weight = 3262 };
  { key = "slot.source.secondary_0093";                  label = "public_firework_93";          arity = 4; tags = ["compat"; "async"; "cold"]; since = "1.6.0"; weight = 2887 };
  { key = "particle.source.stable_0094";                 label = "secondary_hologram_94";       arity = 2; tags = ["lower"]; since = "1.7.0"; weight = 2013 };
  { key = "rail.source.derived_0095";                    label = "hidden_potion_95";            arity = 5; tags = ["lower"; "content"]; since = "1.6.0"; weight = 3076 };
  { key = "biome.source.legacy_0096";                    label = "internal_world_96";           arity = 7; tags = ["content"]; since = "1.8.3"; weight = 3188 };
  { key = "block.source.primary_0097";                   label = "secondary_beacon_97";         arity = 7; tags = ["runtime"]; since = "1.2.0"; weight = 2482 };
  { key = "pane.source.primary_0098";                    label = "legacy_portal_98";            arity = 6; tags = ["codegen"; "legacy"]; since = "1.8.3"; weight = 2367 };
  { key = "observer.source.loose_0099";                  label = "stable_bell_99";              arity = 0; tags = ["parse"]; since = "1.0.0"; weight = 3152 };
  { key = "crossbow.source.modern_0100";                 label = "cached_comparator_100";       arity = 2; tags = ["experimental"]; since = "1.4.0"; weight = 3469 };
  { key = "map.source.primary_0101";                     label = "provisional_shield_101";      arity = 2; tags = ["codegen"; "check"]; since = "1.4.0"; weight = 994 };
  { key = "banner.source.fallback_0102";                 label = "local_trade_102";             arity = 1; tags = ["typed"]; since = "1.6.0"; weight = 1864 };
  { key = "clock.source.legacy_0103";                    label = "public_advancement_103";      arity = 1; tags = ["registry"; "parse"; "async"]; since = "1.0.0"; weight = 1846 };
  { key = "dropper.source.provisional_0104";             label = "legacy_grindstone_104";       arity = 4; tags = ["cached"; "packet"]; since = "1.6.0"; weight = 2025 };
  { key = "hologram.source.stable_0105";                 label = "fallback_scoreboard_105";     arity = 0; tags = ["parse"]; since = "1.9.0"; weight = 2188 };
  { key = "dispenser.source.legacy_0106";                label = "modern_scoreboard_106";       arity = 1; tags = ["hot"]; since = "1.6.0"; weight = 76 };
  { key = "structure.source.modern_0107";                label = "derived_composter_107";       arity = 4; tags = ["typed"]; since = "1.7.0"; weight = 3660 };
  { key = "furnace.source.loose_0108";                   label = "canonical_elytra_108";        arity = 3; tags = ["cold"; "core"]; since = "1.7.0"; weight = 1533 };
  { key = "furnace.source.canonical_0109";               label = "loose_dropper_109";           arity = 1; tags = ["packet"; "parse"; "cached"]; since = "1.6.0"; weight = 2221 };
  { key = "objective.source.public_0110";                label = "cached_piston_110";           arity = 2; tags = ["cached"; "lower"; "hot"]; since = "1.6.0"; weight = 2429 };
  { key = "smoker.source.canonical_0111";                label = "derived_minecart_111";        arity = 3; tags = ["legacy"]; since = "1.6.0"; weight = 3904 };
  { key = "item.source.secondary_0112";                  label = "stable_biome_112";            arity = 2; tags = ["experimental"; "legacy"]; since = "1.6.0"; weight = 3086 };
  { key = "comparator.source.local_0113";                label = "public_furnace_113";          arity = 2; tags = ["typed"; "emit"]; since = "1.5.2"; weight = 1869 };
  { key = "campfire.source.scoped_0114";                 label = "hidden_target_114";           arity = 0; tags = ["legacy"; "registry"; "experimental"]; since = "1.5.2"; weight = 3791 };
  { key = "compass.source.fallback_0115";                label = "internal_item_115";           arity = 5; tags = ["legacy"]; since = "1.0.0"; weight = 1527 };
  { key = "structure.source.loose_0116";                 label = "stable_trade_116";            arity = 0; tags = ["check"; "sync"]; since = "1.9.0"; weight = 3273 };
  { key = "clock.source.loose_0117";                     label = "loose_trident_117";           arity = 2; tags = ["legacy"; "parse"]; since = "1.2.0"; weight = 698 };
  { key = "spawner.source.cached_0118";                  label = "lazy_trade_118";              arity = 7; tags = ["hot"; "cached"]; since = "1.4.0"; weight = 1756 };
  { key = "smithing.source.public_0119";                 label = "internal_arrow_119";          arity = 2; tags = ["cold"; "runtime"]; since = "1.0.0"; weight = 3494 };
  { key = "world.source.secondary_0120";                 label = "global_brewing_120";          arity = 2; tags = ["core"; "lower"; "legacy"]; since = "1.9.0"; weight = 53 };
  { key = "smoker.source.stable_0121";                   label = "global_observer_121";         arity = 6; tags = ["untyped"]; since = "1.4.0"; weight = 3978 };
  { key = "observer.source.canonical_0122";              label = "local_npc_122";               arity = 0; tags = ["packet"; "content"]; since = "1.7.0"; weight = 503 };
  { key = "piston.source.hidden_0123";                   label = "strict_tablist_123";          arity = 5; tags = ["emit"]; since = "1.3.1"; weight = 3330 };
  { key = "banner_pattern.source.cached_0124";           label = "cached_barrel_124";           arity = 5; tags = ["lower"; "core"; "check"]; since = "1.0.0"; weight = 3842 };
  { key = "rail.source.canonical_0125";                  label = "derived_biome_125";           arity = 0; tags = ["async"; "content"]; since = "1.6.0"; weight = 1093 };
  { key = "barrel.source.fallback_0126";                 label = "canonical_grindstone_126";    arity = 4; tags = ["hot"]; since = "1.0.0"; weight = 3793 };
  { key = "target.source.stable_0127";                   label = "canonical_trident_127";       arity = 4; tags = ["lower"; "parse"; "check"]; since = "1.6.0"; weight = 1817 };
  { key = "world.source.strict_0128";                    label = "derived_gui_128";             arity = 7; tags = ["async"; "untyped"]; since = "1.2.0"; weight = 1532 };
  { key = "packet.source.public_0129";                   label = "public_elytra_129";           arity = 2; tags = ["experimental"; "cold"; "emit"]; since = "1.3.1"; weight = 1934 };
  { key = "pane.source.canonical_0130";                  label = "scoped_slot_130";             arity = 2; tags = ["check"]; since = "1.0.0"; weight = 2369 };
  { key = "stonecutter.source.strict_0131";              label = "canonical_gui_131";           arity = 3; tags = ["hot"; "cached"]; since = "1.9.0"; weight = 3434 };
  { key = "loom.source.internal_0132";                   label = "hidden_minecart_132";         arity = 6; tags = ["emit"]; since = "1.0.0"; weight = 3073 };
  { key = "slot.source.canonical_0133";                  label = "cached_portal_133";           arity = 7; tags = ["sync"; "cold"]; since = "1.3.1"; weight = 1142 };
  { key = "bell.source.local_0134";                      label = "internal_banner_pattern_134"; arity = 6; tags = ["compat"]; since = "1.3.1"; weight = 3591 };
  { key = "beacon.source.legacy_0135";                   label = "cached_campfire_135";         arity = 1; tags = ["lower"]; since = "1.6.0"; weight = 1478 };
  { key = "banner_pattern.source.public_0136";           label = "loose_elytra_136";            arity = 3; tags = ["lower"]; since = "1.2.0"; weight = 2148 };
  { key = "shulker.source.public_0137";                  label = "global_anvil_137";            arity = 3; tags = ["runtime"; "hot"; "lower"]; since = "1.7.0"; weight = 2756 };
  { key = "mob.source.hidden_0138";                      label = "strict_slot_138";             arity = 5; tags = ["runtime"]; since = "1.0.0"; weight = 1308 };
  { key = "smithing.source.local_0139";                  label = "hidden_advancement_139";      arity = 1; tags = ["experimental"; "async"]; since = "1.3.1"; weight = 1186 };
  { key = "smoker.source.global_0140";                   label = "eager_gui_140";               arity = 2; tags = ["legacy"]; since = "1.5.2"; weight = 3612 };
  { key = "minecart.source.eager_0141";                  label = "local_sound_141";             arity = 6; tags = ["typed"]; since = "1.9.0"; weight = 2573 };
  { key = "anvil.source.hidden_0142";                    label = "canonical_recipe_142";        arity = 6; tags = ["content"; "lower"]; since = "1.4.0"; weight = 2538 };
  { key = "bell.source.legacy_0143";                     label = "local_sound_143";             arity = 5; tags = ["core"]; since = "1.3.1"; weight = 3129 };
  { key = "shulker.source.eager_0144";                   label = "scoped_bell_144";             arity = 1; tags = ["cold"; "content"]; since = "1.6.0"; weight = 3184 };
  { key = "shulker.source.local_0145";                   label = "stable_block_145";            arity = 1; tags = ["lower"; "core"]; since = "1.2.0"; weight = 1741 };
  { key = "recipe.source.public_0146";                   label = "global_potion_146";           arity = 0; tags = ["check"; "core"]; since = "1.2.0"; weight = 2056 };
  { key = "structure.source.eager_0147";                 label = "provisional_furnace_147";     arity = 5; tags = ["sync"; "experimental"; "hot"]; since = "1.7.0"; weight = 522 };
  { key = "conduit.source.legacy_0148";                  label = "scoped_conduit_148";          arity = 6; tags = ["parse"]; since = "1.3.1"; weight = 3512 };
  { key = "chunk.source.fallback_0149";                  label = "legacy_firework_149";         arity = 2; tags = ["content"; "sync"; "runtime"]; since = "1.8.3"; weight = 2118 };
  { key = "stonecutter.source.derived_0150";             label = "stable_beacon_150";           arity = 3; tags = ["lower"]; since = "1.4.0"; weight = 3267 };
  { key = "hopper.source.lazy_0151";                     label = "public_piston_151";           arity = 0; tags = ["packet"]; since = "1.8.3"; weight = 52 };
  { key = "pane.source.global_0152";                     label = "eager_portal_152";            arity = 0; tags = ["cold"]; since = "1.2.0"; weight = 302 };
  { key = "smoker.source.fallback_0153";                 label = "lazy_packet_153";             arity = 4; tags = ["hot"; "legacy"]; since = "1.2.0"; weight = 908 };
  { key = "attribute.source.stable_0154";                label = "lazy_arrow_154";              arity = 1; tags = ["check"]; since = "1.3.1"; weight = 3916 };
  { key = "advancement.source.derived_0155";             label = "global_observer_155";         arity = 2; tags = ["registry"]; since = "1.2.0"; weight = 378 };
  { key = "anvil.source.legacy_0156";                    label = "fallback_banner_pattern_156"; arity = 7; tags = ["registry"; "lower"]; since = "1.9.0"; weight = 272 };
  { key = "conduit.source.legacy_0157";                  label = "provisional_hopper_157";      arity = 7; tags = ["parse"; "untyped"]; since = "1.3.1"; weight = 617 };
  { key = "shield.source.cached_0158";                   label = "modern_compass_158";          arity = 2; tags = ["cold"; "core"; "runtime"]; since = "1.3.1"; weight = 2031 };
  { key = "structure.source.eager_0159";                 label = "public_world_159";            arity = 3; tags = ["legacy"; "runtime"]; since = "1.8.3"; weight = 1608 };
  { key = "npc.source.internal_0160";                    label = "provisional_tablist_160";     arity = 5; tags = ["untyped"; "compat"]; since = "1.0.0"; weight = 2191 };
  { key = "conduit.source.local_0161";                   label = "derived_inventory_161";       arity = 7; tags = ["hot"; "cached"; "runtime"]; since = "1.7.0"; weight = 3056 };
  { key = "chunk.source.internal_0162";                  label = "stable_block_162";            arity = 0; tags = ["legacy"; "registry"]; since = "1.6.0"; weight = 2823 };
  { key = "entity.source.hidden_0163";                   label = "legacy_arrow_163";            arity = 4; tags = ["typed"]; since = "1.7.0"; weight = 3269 };
  { key = "barrel.source.global_0164";                   label = "scoped_beacon_164";           arity = 5; tags = ["cold"; "check"]; since = "1.0.0"; weight = 694 };
  { key = "boat.source.internal_0165";                   label = "global_villager_165";         arity = 7; tags = ["content"; "cold"; "check"]; since = "1.0.0"; weight = 873 };
  { key = "map.source.internal_0166";                    label = "public_furnace_166";          arity = 2; tags = ["packet"]; since = "1.5.2"; weight = 2205 };
  { key = "chunk.source.scoped_0167";                    label = "hidden_boat_167";             arity = 4; tags = ["lower"]; since = "1.5.2"; weight = 1335 };
  { key = "lectern.source.canonical_0168";               label = "legacy_smoker_168";           arity = 5; tags = ["untyped"; "codegen"]; since = "1.5.2"; weight = 3935 };
  { key = "sound.source.canonical_0169";                 label = "derived_banner_169";          arity = 3; tags = ["async"]; since = "1.2.0"; weight = 1362 };
  { key = "target.source.global_0170";                   label = "stable_clock_170";            arity = 7; tags = ["content"; "codegen"]; since = "1.2.0"; weight = 3388 };
  { key = "firework.source.internal_0171";               label = "derived_sound_171";           arity = 5; tags = ["cold"; "content"; "experimental"]; since = "1.0.0"; weight = 1975 };
  { key = "hopper.source.hidden_0172";                   label = "primary_grindstone_172";      arity = 6; tags = ["codegen"; "cached"; "content"]; since = "1.0.0"; weight = 83 };
  { key = "boat.source.scoped_0173";                     label = "canonical_elytra_173";        arity = 1; tags = ["parse"; "packet"]; since = "1.3.1"; weight = 3465 };
  { key = "furnace.source.local_0174";                   label = "canonical_shulker_174";       arity = 2; tags = ["compat"]; since = "1.3.1"; weight = 740 };
  { key = "block.source.lazy_0175";                      label = "lazy_hopper_175";             arity = 2; tags = ["core"; "legacy"]; since = "1.4.0"; weight = 1183 };
  { key = "npc.source.loose_0176";                       label = "lazy_shulker_176";            arity = 7; tags = ["registry"]; since = "1.4.0"; weight = 712 };
  { key = "shulker.source.hidden_0177";                  label = "public_trident_177";          arity = 1; tags = ["emit"; "runtime"; "codegen"]; since = "1.6.0"; weight = 725 };
  { key = "slot.source.derived_0178";                    label = "eager_minecart_178";          arity = 0; tags = ["compat"; "untyped"]; since = "1.4.0"; weight = 3678 };
  { key = "sound.source.cached_0179";                    label = "hidden_smoker_179";           arity = 3; tags = ["async"; "check"; "core"]; since = "1.4.0"; weight = 1919 };
  { key = "dispenser.source.modern_0180";                label = "hidden_shield_180";           arity = 1; tags = ["codegen"]; since = "1.3.1"; weight = 3773 };
  { key = "mob.source.fallback_0181";                    label = "legacy_pane_181";             arity = 5; tags = ["sync"]; since = "1.5.2"; weight = 2118 };
  { key = "sound.source.scoped_0182";                    label = "provisional_campfire_182";    arity = 6; tags = ["parse"; "codegen"; "sync"]; since = "1.3.1"; weight = 2607 };
  { key = "particle.source.local_0183";                  label = "lazy_bell_183";               arity = 6; tags = ["legacy"; "emit"]; since = "1.3.1"; weight = 1896 };
  { key = "comparator.source.canonical_0184";            label = "primary_comparator_184";      arity = 3; tags = ["hot"]; since = "1.4.0"; weight = 1546 };
  { key = "trade.source.primary_0185";                   label = "global_boat_185";             arity = 3; tags = ["core"]; since = "1.3.1"; weight = 1812 };
  { key = "conduit.source.global_0186";                  label = "fallback_attribute_186";      arity = 7; tags = ["hot"; "cached"; "cold"]; since = "1.3.1"; weight = 3896 };
  { key = "trade.source.stable_0187";                    label = "provisional_entity_187";      arity = 1; tags = ["experimental"; "hot"]; since = "1.9.0"; weight = 2217 };
  { key = "smoker.source.stable_0188";                   label = "local_dropper_188";           arity = 7; tags = ["runtime"]; since = "1.9.0"; weight = 2599 };
  { key = "campfire.source.local_0189";                  label = "stable_comparator_189";       arity = 2; tags = ["parse"]; since = "1.6.0"; weight = 2638 };
  { key = "effect.source.lazy_0190";                     label = "cached_portal_190";           arity = 2; tags = ["emit"]; since = "1.4.0"; weight = 2428 };
  { key = "target.source.secondary_0191";                label = "secondary_dispenser_191";     arity = 5; tags = ["registry"]; since = "1.7.0"; weight = 1109 };
  { key = "brewing.source.legacy_0192";                  label = "cached_dispenser_192";        arity = 6; tags = ["packet"; "check"; "hot"]; since = "1.3.1"; weight = 1141 };
  { key = "player.source.primary_0193";                  label = "hidden_loom_193";             arity = 2; tags = ["registry"]; since = "1.8.3"; weight = 3312 };
  { key = "stonecutter.source.eager_0194";               label = "lazy_cartography_194";        arity = 1; tags = ["compat"; "untyped"; "async"]; since = "1.0.0"; weight = 160 };
  { key = "elytra.source.cached_0195";                   label = "secondary_dropper_195";       arity = 4; tags = ["cold"; "emit"]; since = "1.4.0"; weight = 3993 };
  { key = "dispenser.source.eager_0196";                 label = "secondary_stonecutter_196";   arity = 5; tags = ["cold"; "cached"; "hot"]; since = "1.4.0"; weight = 2130 };
  { key = "potion.source.fallback_0197";                 label = "canonical_particle_197";      arity = 2; tags = ["parse"; "check"]; since = "1.8.3"; weight = 2252 };
  { key = "smithing.source.modern_0198";                 label = "legacy_player_198";           arity = 0; tags = ["experimental"; "lower"]; since = "1.5.2"; weight = 3043 };
  { key = "attribute.source.local_0199";                 label = "strict_shield_199";           arity = 0; tags = ["cold"]; since = "1.9.0"; weight = 3694 };
  { key = "hopper.source.global_0200";                   label = "scoped_pane_200";             arity = 4; tags = ["registry"; "packet"; "codegen"]; since = "1.4.0"; weight = 534 };
  { key = "region.source.internal_0201";                 label = "scoped_stonecutter_201";      arity = 4; tags = ["emit"]; since = "1.4.0"; weight = 2176 };
  { key = "stonecutter.source.primary_0202";             label = "derived_shulker_202";         arity = 2; tags = ["typed"; "runtime"]; since = "1.8.3"; weight = 1344 };
  { key = "tablist.source.scoped_0203";                  label = "canonical_compass_203";       arity = 6; tags = ["cold"; "sync"; "untyped"]; since = "1.7.0"; weight = 2117 };
  { key = "enchant.source.secondary_0204";               label = "secondary_rail_204";          arity = 6; tags = ["sync"; "cold"; "emit"]; since = "1.0.0"; weight = 3395 };
  { key = "cartography.source.derived_0205";             label = "eager_portal_205";            arity = 3; tags = ["codegen"; "registry"]; since = "1.2.0"; weight = 3533 };
  { key = "barrel.source.public_0206";                   label = "internal_particle_206";       arity = 2; tags = ["lower"]; since = "1.5.2"; weight = 3583 };
  { key = "portal.source.secondary_0207";                label = "global_piston_207";           arity = 6; tags = ["codegen"; "check"]; since = "1.5.2"; weight = 3577 };
  { key = "firework.source.stable_0208";                 label = "loose_furnace_208";           arity = 3; tags = ["typed"]; since = "1.3.1"; weight = 326 };
  { key = "rail.source.canonical_0209";                  label = "modern_portal_209";           arity = 0; tags = ["runtime"]; since = "1.3.1"; weight = 2534 };
  { key = "grindstone.source.derived_0210";              label = "secondary_banner_210";        arity = 0; tags = ["legacy"; "core"]; since = "1.2.0"; weight = 1648 };
  { key = "structure.source.cached_0211";                label = "cached_observer_211";         arity = 1; tags = ["async"; "experimental"]; since = "1.3.1"; weight = 3430 };
  { key = "crossbow.source.global_0212";                 label = "cached_recipe_212";           arity = 7; tags = ["untyped"; "typed"; "parse"]; since = "1.2.0"; weight = 4022 };
  { key = "biome.source.derived_0213";                   label = "canonical_shulker_213";       arity = 6; tags = ["hot"; "async"; "typed"]; since = "1.4.0"; weight = 721 };
  { key = "item.source.legacy_0214";                     label = "fallback_anvil_214";          arity = 4; tags = ["sync"]; since = "1.9.0"; weight = 3456 };
  { key = "campfire.source.lazy_0215";                   label = "canonical_dropper_215";       arity = 6; tags = ["registry"; "check"; "codegen"]; since = "1.9.0"; weight = 2297 };
  { key = "banner_pattern.source.provisional_0216";      label = "stable_block_216";            arity = 5; tags = ["emit"; "typed"; "experimental"]; since = "1.2.0"; weight = 2433 };
  { key = "target.source.internal_0217";                 label = "modern_hologram_217";         arity = 5; tags = ["cached"; "hot"]; since = "1.7.0"; weight = 1279 };
  { key = "spawner.source.public_0218";                  label = "primary_composter_218";       arity = 6; tags = ["codegen"]; since = "1.5.2"; weight = 1640 };
  { key = "region.source.provisional_0219";              label = "lazy_banner_pattern_219";     arity = 6; tags = ["check"; "packet"; "legacy"]; since = "1.0.0"; weight = 4060 };
  { key = "cartography.source.secondary_0220";           label = "lazy_attribute_220";          arity = 4; tags = ["untyped"; "core"; "hot"]; since = "1.3.1"; weight = 2329 };
  { key = "map.source.loose_0221";                       label = "fallback_world_221";          arity = 3; tags = ["sync"]; since = "1.8.3"; weight = 1095 };
  { key = "potion.source.internal_0222";                 label = "canonical_player_222";        arity = 0; tags = ["untyped"]; since = "1.6.0"; weight = 2096 };
  { key = "elytra.source.lazy_0223";                     label = "fallback_loom_223";           arity = 7; tags = ["untyped"; "hot"]; since = "1.3.1"; weight = 891 };
  { key = "smoker.source.local_0224";                    label = "cached_conduit_224";          arity = 0; tags = ["experimental"; "sync"]; since = "1.9.0"; weight = 3469 };
  { key = "cartography.source.hidden_0225";              label = "fallback_recipe_225";         arity = 3; tags = ["lower"]; since = "1.0.0"; weight = 3110 };
  { key = "team.source.hidden_0226";                     label = "strict_composter_226";        arity = 0; tags = ["check"; "content"]; since = "1.7.0"; weight = 3003 };
  { key = "slot.source.legacy_0227";                     label = "provisional_grindstone_227";  arity = 1; tags = ["legacy"; "experimental"]; since = "1.4.0"; weight = 339 };
  { key = "inventory.source.local_0228";                 label = "fallback_arrow_228";          arity = 6; tags = ["hot"; "runtime"; "legacy"]; since = "1.2.0"; weight = 1270 };
  { key = "advancement.source.hidden_0229";              label = "global_cartography_229";      arity = 7; tags = ["packet"]; since = "1.5.2"; weight = 3998 };
  { key = "sound.source.derived_0230";                   label = "derived_minecart_230";        arity = 6; tags = ["runtime"; "experimental"]; since = "1.9.0"; weight = 930 };
  { key = "tablist.source.secondary_0231";               label = "modern_biome_231";            arity = 6; tags = ["untyped"; "legacy"; "lower"]; since = "1.2.0"; weight = 405 };
  { key = "effect.source.scoped_0232";                   label = "global_banner_232";           arity = 3; tags = ["untyped"]; since = "1.2.0"; weight = 1741 };
  { key = "dropper.source.canonical_0233";               label = "loose_repeater_233";          arity = 1; tags = ["cold"]; since = "1.0.0"; weight = 1691 };
  { key = "map.source.fallback_0234";                    label = "modern_dispenser_234";        arity = 6; tags = ["legacy"; "compat"; "experimental"]; since = "1.6.0"; weight = 1933 };
  { key = "attribute.source.loose_0235";                 label = "lazy_clock_235";              arity = 1; tags = ["core"; "untyped"; "emit"]; since = "1.8.3"; weight = 2772 };
  { key = "map.source.secondary_0236";                   label = "global_firework_236";         arity = 1; tags = ["cold"]; since = "1.3.1"; weight = 3032 };
  { key = "clock.source.stable_0237";                    label = "scoped_enchant_237";          arity = 5; tags = ["legacy"; "experimental"]; since = "1.3.1"; weight = 1944 };
  { key = "scoreboard.source.stable_0238";               label = "public_inventory_238";        arity = 7; tags = ["packet"; "cached"]; since = "1.2.0"; weight = 2172 };
  { key = "gui.source.secondary_0239";                   label = "local_clock_239";             arity = 7; tags = ["lower"; "content"; "sync"]; since = "1.4.0"; weight = 3051 };
  { key = "brewing.source.internal_0240";                label = "strict_sound_240";            arity = 2; tags = ["compat"; "hot"]; since = "1.3.1"; weight = 3849 };
  { key = "cartography.source.stable_0241";              label = "canonical_objective_241";     arity = 3; tags = ["async"; "experimental"; "untyped"]; since = "1.2.0"; weight = 3929 };
  { key = "effect.source.internal_0242";                 label = "modern_observer_242";         arity = 7; tags = ["lower"; "cached"; "registry"]; since = "1.7.0"; weight = 1554 };
  { key = "cartography.source.modern_0243";              label = "derived_dropper_243";         arity = 3; tags = ["async"; "sync"]; since = "1.4.0"; weight = 2890 };
  { key = "bossbar.source.legacy_0244";                  label = "lazy_dispenser_244";          arity = 1; tags = ["async"; "cold"]; since = "1.5.2"; weight = 1681 };
  { key = "hologram.source.hidden_0245";                 label = "cached_portal_245";           arity = 4; tags = ["cold"; "sync"; "legacy"]; since = "1.2.0"; weight = 515 };
  { key = "dropper.source.fallback_0246";                label = "fallback_trident_246";        arity = 2; tags = ["compat"; "cold"; "codegen"]; since = "1.9.0"; weight = 2905 };
  { key = "biome.source.modern_0247";                    label = "global_grindstone_247";       arity = 2; tags = ["codegen"]; since = "1.2.0"; weight = 1307 };
  { key = "clock.source.derived_0248";                   label = "scoped_map_248";              arity = 7; tags = ["packet"; "parse"]; since = "1.8.3"; weight = 496 };
  { key = "dispenser.source.global_0249";                label = "public_dispenser_249";        arity = 3; tags = ["cold"; "async"; "emit"]; since = "1.4.0"; weight = 3621 };
  { key = "composter.source.local_0250";                 label = "fallback_mob_250";            arity = 1; tags = ["check"]; since = "1.9.0"; weight = 2060 };
  { key = "dispenser.source.provisional_0251";           label = "hidden_boat_251";             arity = 5; tags = ["content"]; since = "1.0.0"; weight = 232 };
  { key = "furnace.source.derived_0252";                 label = "strict_region_252";           arity = 1; tags = ["cached"; "hot"; "legacy"]; since = "1.3.1"; weight = 376 };
  { key = "tablist.source.provisional_0253";             label = "canonical_world_253";         arity = 2; tags = ["registry"; "lower"]; since = "1.2.0"; weight = 1203 };
  { key = "region.source.fallback_0254";                 label = "public_effect_254";           arity = 1; tags = ["cached"; "parse"; "codegen"]; since = "1.0.0"; weight = 1298 };
  { key = "advancement.source.loose_0255";               label = "secondary_chunk_255";         arity = 6; tags = ["async"; "cached"; "codegen"]; since = "1.0.0"; weight = 2584 };
  { key = "crossbow.source.legacy_0256";                 label = "loose_villager_256";          arity = 7; tags = ["hot"]; since = "1.2.0"; weight = 2344 };
  { key = "effect.source.provisional_0257";              label = "strict_slot_257";             arity = 0; tags = ["cold"; "hot"]; since = "1.9.0"; weight = 2078 };
  { key = "brewing.source.cached_0258";                  label = "provisional_lectern_258";     arity = 7; tags = ["emit"; "async"; "check"]; since = "1.4.0"; weight = 3427 };
  { key = "mob.source.lazy_0259";                        label = "stable_objective_259";        arity = 3; tags = ["emit"]; since = "1.9.0"; weight = 915 };
  { key = "firework.source.secondary_0260";              label = "public_advancement_260";      arity = 5; tags = ["compat"]; since = "1.8.3"; weight = 2652 };
  { key = "rail.source.legacy_0261";                     label = "eager_hopper_261";            arity = 5; tags = ["legacy"; "core"; "packet"]; since = "1.7.0"; weight = 2473 };
  { key = "tablist.source.loose_0262";                   label = "cached_bossbar_262";          arity = 4; tags = ["codegen"]; since = "1.4.0"; weight = 615 };
  { key = "piston.source.fallback_0263";                 label = "strict_map_263";              arity = 3; tags = ["untyped"]; since = "1.0.0"; weight = 3964 };
  { key = "furnace.source.cached_0264";                  label = "derived_structure_264";       arity = 5; tags = ["sync"; "registry"]; since = "1.4.0"; weight = 2426 };
  { key = "potion.source.lazy_0265";                     label = "primary_rail_265";            arity = 7; tags = ["compat"]; since = "1.4.0"; weight = 3060 };
  { key = "banner_pattern.source.scoped_0266";           label = "scoped_stonecutter_266";      arity = 5; tags = ["cached"; "emit"; "cold"]; since = "1.3.1"; weight = 2286 };
  { key = "potion.source.primary_0267";                  label = "strict_world_267";            arity = 3; tags = ["legacy"; "emit"]; since = "1.4.0"; weight = 2881 };
  { key = "trident.source.scoped_0268";                  label = "provisional_bundle_268";      arity = 0; tags = ["cold"; "content"]; since = "1.4.0"; weight = 2097 };
  { key = "particle.source.provisional_0269";            label = "hidden_campfire_269";         arity = 5; tags = ["untyped"; "check"; "core"]; since = "1.2.0"; weight = 3783 };
  { key = "bossbar.source.local_0270";                   label = "public_repeater_270";         arity = 5; tags = ["experimental"; "runtime"; "content"]; since = "1.6.0"; weight = 3008 };
  { key = "entity.source.derived_0271";                  label = "stable_banner_pattern_271";   arity = 0; tags = ["cold"; "compat"]; since = "1.8.3"; weight = 2977 };
  { key = "beacon.source.loose_0272";                    label = "eager_sound_272";             arity = 6; tags = ["typed"; "check"]; since = "1.5.2"; weight = 444 };
  { key = "anvil.source.scoped_0273";                    label = "eager_hopper_273";            arity = 2; tags = ["core"]; since = "1.7.0"; weight = 3797 };
  { key = "sound.source.public_0274";                    label = "provisional_player_274";      arity = 1; tags = ["legacy"]; since = "1.9.0"; weight = 3877 };
  { key = "compass.source.stable_0275";                  label = "canonical_attribute_275";     arity = 4; tags = ["codegen"; "cached"]; since = "1.3.1"; weight = 568 };
  { key = "advancement.source.eager_0276";               label = "global_inventory_276";        arity = 3; tags = ["hot"]; since = "1.5.2"; weight = 1542 };
  { key = "clock.source.provisional_0277";               label = "primary_furnace_277";         arity = 0; tags = ["experimental"; "async"; "registry"]; since = "1.6.0"; weight = 2337 };
  { key = "piston.source.global_0278";                   label = "legacy_advancement_278";      arity = 0; tags = ["compat"; "packet"]; since = "1.6.0"; weight = 3015 };
  { key = "sound.source.strict_0279";                    label = "legacy_smithing_279";         arity = 2; tags = ["emit"]; since = "1.9.0"; weight = 1765 };
  { key = "compass.source.global_0280";                  label = "secondary_region_280";        arity = 7; tags = ["hot"]; since = "1.5.2"; weight = 1172 };
  { key = "smoker.source.cached_0281";                   label = "internal_composter_281";      arity = 2; tags = ["cached"; "emit"]; since = "1.9.0"; weight = 25 };
  { key = "comparator.source.provisional_0282";          label = "strict_advancement_282";      arity = 0; tags = ["untyped"; "core"; "cold"]; since = "1.5.2"; weight = 2326 };
  { key = "firework.source.local_0283";                  label = "eager_tablist_283";           arity = 0; tags = ["codegen"; "packet"; "emit"]; since = "1.3.1"; weight = 437 };
  { key = "repeater.source.loose_0284";                  label = "scoped_bell_284";             arity = 1; tags = ["hot"; "compat"]; since = "1.5.2"; weight = 2965 };
  { key = "conduit.source.loose_0285";                   label = "legacy_inventory_285";        arity = 1; tags = ["core"; "hot"]; since = "1.0.0"; weight = 3773 };
  { key = "chunk.source.modern_0286";                    label = "derived_banner_pattern_286";  arity = 2; tags = ["runtime"; "codegen"; "core"]; since = "1.5.2"; weight = 1989 };
  { key = "beacon.source.legacy_0287";                   label = "public_bell_287";             arity = 5; tags = ["legacy"; "experimental"; "runtime"]; since = "1.7.0"; weight = 1975 };
  { key = "villager.source.derived_0288";                label = "secondary_enchant_288";       arity = 1; tags = ["lower"; "untyped"; "cached"]; since = "1.0.0"; weight = 3585 };
  { key = "banner.source.cached_0289";                   label = "cached_compass_289";          arity = 1; tags = ["hot"; "parse"; "cold"]; since = "1.0.0"; weight = 3781 };
  { key = "clock.source.strict_0290";                    label = "fallback_slot_290";           arity = 2; tags = ["cold"; "compat"]; since = "1.4.0"; weight = 424 };
  { key = "arrow.source.canonical_0291";                 label = "scoped_anvil_291";            arity = 3; tags = ["hot"; "legacy"]; since = "1.2.0"; weight = 525 };
  { key = "grindstone.source.fallback_0292";             label = "legacy_crossbow_292";         arity = 5; tags = ["async"]; since = "1.4.0"; weight = 605 };
  { key = "tablist.source.derived_0293";                 label = "stable_smoker_293";           arity = 0; tags = ["compat"]; since = "1.5.2"; weight = 229 };
  { key = "spawner.source.internal_0294";                label = "primary_anvil_294";           arity = 6; tags = ["typed"]; since = "1.5.2"; weight = 1326 };
  { key = "shulker.source.scoped_0295";                  label = "legacy_map_295";              arity = 3; tags = ["codegen"; "packet"]; since = "1.4.0"; weight = 1723 };
  { key = "npc.source.fallback_0296";                    label = "hidden_shield_296";           arity = 7; tags = ["runtime"]; since = "1.4.0"; weight = 2788 };
  { key = "bundle.source.cached_0297";                   label = "fallback_item_297";           arity = 5; tags = ["registry"; "cold"; "compat"]; since = "1.2.0"; weight = 3145 };
  { key = "furnace.source.hidden_0298";                  label = "hidden_comparator_298";       arity = 3; tags = ["cold"; "runtime"; "hot"]; since = "1.4.0"; weight = 3678 };
  { key = "trade.source.derived_0299";                   label = "local_clock_299";             arity = 4; tags = ["emit"; "experimental"]; since = "1.2.0"; weight = 2732 };
  { key = "bell.source.lazy_0300";                       label = "lazy_elytra_300";             arity = 1; tags = ["emit"; "check"]; since = "1.4.0"; weight = 3049 };
  { key = "entity.source.strict_0301";                   label = "global_boat_301";             arity = 4; tags = ["content"]; since = "1.6.0"; weight = 2304 };
  { key = "dispenser.source.local_0302";                 label = "local_clock_302";             arity = 4; tags = ["parse"]; since = "1.7.0"; weight = 1750 };
  { key = "tablist.source.internal_0303";                label = "local_objective_303";         arity = 2; tags = ["compat"; "core"]; since = "1.2.0"; weight = 64 };
  { key = "world.source.global_0304";                    label = "secondary_player_304";        arity = 4; tags = ["hot"]; since = "1.2.0"; weight = 2050 };
  { key = "trident.source.strict_0305";                  label = "strict_minecart_305";         arity = 5; tags = ["hot"; "check"]; since = "1.2.0"; weight = 2182 };
  { key = "bundle.source.global_0306";                   label = "eager_repeater_306";          arity = 2; tags = ["runtime"]; since = "1.4.0"; weight = 2568 };
  { key = "hologram.source.canonical_0307";              label = "strict_observer_307";         arity = 5; tags = ["hot"]; since = "1.4.0"; weight = 1923 };
  { key = "cartography.source.secondary_0308";           label = "fallback_crossbow_308";       arity = 7; tags = ["lower"; "content"]; since = "1.9.0"; weight = 1389 };
  { key = "cartography.source.hidden_0309";              label = "canonical_barrel_309";        arity = 7; tags = ["registry"]; since = "1.6.0"; weight = 1083 };
  { key = "chunk.source.strict_0310";                    label = "legacy_smoker_310";           arity = 5; tags = ["check"; "content"; "codegen"]; since = "1.9.0"; weight = 2106 };
  { key = "bundle.source.secondary_0311";                label = "modern_shulker_311";          arity = 2; tags = ["cached"]; since = "1.3.1"; weight = 2375 };
  { key = "villager.source.public_0312";                 label = "fallback_target_312";         arity = 5; tags = ["cold"; "hot"]; since = "1.2.0"; weight = 2497 };
  { key = "hopper.source.legacy_0313";                   label = "hidden_crossbow_313";         arity = 0; tags = ["cold"; "content"]; since = "1.5.2"; weight = 2021 };
  { key = "structure.source.stable_0314";                label = "loose_bundle_314";            arity = 1; tags = ["cached"]; since = "1.4.0"; weight = 2963 };
  { key = "recipe.source.provisional_0315";              label = "global_tablist_315";          arity = 0; tags = ["cached"]; since = "1.2.0"; weight = 1311 };
  { key = "bundle.source.global_0316";                   label = "public_hologram_316";         arity = 1; tags = ["typed"; "codegen"; "legacy"]; since = "1.9.0"; weight = 3136 };
  { key = "objective.source.legacy_0317";                label = "primary_hopper_317";          arity = 0; tags = ["core"; "hot"]; since = "1.3.1"; weight = 542 };
  { key = "rail.source.lazy_0318";                       label = "legacy_arrow_318";            arity = 5; tags = ["typed"; "codegen"]; since = "1.4.0"; weight = 2208 };
  { key = "team.source.derived_0319";                    label = "global_attribute_319";        arity = 4; tags = ["codegen"]; since = "1.3.1"; weight = 3505 };
  { key = "world.source.primary_0320";                   label = "cached_compass_320";          arity = 3; tags = ["cold"; "core"]; since = "1.3.1"; weight = 1608 };
  { key = "entity.source.loose_0321";                    label = "canonical_composter_321";     arity = 2; tags = ["experimental"; "runtime"]; since = "1.8.3"; weight = 2435 };
  { key = "trident.source.derived_0322";                 label = "derived_minecart_322";        arity = 1; tags = ["lower"; "content"; "emit"]; since = "1.8.3"; weight = 1015 };
]

let count = List.length entries

let table : (string, source_entry) Hashtbl.t =
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
