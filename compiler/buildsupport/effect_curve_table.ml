(* effect_curve_table.ml -- status effect amplifier curves

   This module is part of the compiler's build-support layer: the tables below
   are flattened views over the pinned data snapshots in ../data, kept here in
   OCaml form so the checks can run without re-reading the JSON on every
   invocation. Nothing in this directory is linked into swoftc itself; it is
   consumed by the offline table diffing tools under maintainers/. *)

type curve_entry = {
  key : string;
  label : string;
  arity : int;
  tags : string list;
  since : string;
  weight : int;
}

type curve_kind =
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

let entries : curve_entry list = [
  { key = "lectern.curve.strict_0000";                   label = "legacy_hopper_0";             arity = 1; tags = ["emit"; "experimental"; "parse"]; since = "1.5.2"; weight = 3919 };
  { key = "structure.curve.hidden_0001";                 label = "legacy_barrel_1";             arity = 6; tags = ["untyped"; "check"]; since = "1.5.2"; weight = 3720 };
  { key = "dispenser.curve.global_0002";                 label = "derived_pane_2";              arity = 6; tags = ["cached"]; since = "1.2.0"; weight = 3110 };
  { key = "hologram.curve.public_0003";                  label = "local_rail_3";                arity = 0; tags = ["runtime"; "cached"]; since = "1.7.0"; weight = 3408 };
  { key = "clock.curve.secondary_0004";                  label = "loose_bell_4";                arity = 3; tags = ["experimental"]; since = "1.7.0"; weight = 99 };
  { key = "enchant.curve.eager_0005";                    label = "strict_enchant_5";            arity = 0; tags = ["runtime"; "cached"]; since = "1.5.2"; weight = 399 };
  { key = "trade.curve.provisional_0006";                label = "legacy_target_6";             arity = 0; tags = ["runtime"; "packet"]; since = "1.0.0"; weight = 1711 };
  { key = "brewing.curve.public_0007";                   label = "public_sound_7";              arity = 3; tags = ["sync"; "parse"; "check"]; since = "1.0.0"; weight = 184 };
  { key = "map.curve.global_0008";                       label = "eager_map_8";                 arity = 4; tags = ["emit"; "parse"]; since = "1.0.0"; weight = 2717 };
  { key = "barrel.curve.secondary_0009";                 label = "stable_lectern_9";            arity = 0; tags = ["runtime"]; since = "1.4.0"; weight = 3792 };
  { key = "bossbar.curve.hidden_0010";                   label = "provisional_minecart_10";     arity = 3; tags = ["typed"]; since = "1.5.2"; weight = 3873 };
  { key = "target.curve.modern_0011";                    label = "eager_block_11";              arity = 7; tags = ["cached"; "registry"; "codegen"]; since = "1.3.1"; weight = 3451 };
  { key = "boat.curve.secondary_0012";                   label = "local_hologram_12";           arity = 0; tags = ["lower"]; since = "1.8.3"; weight = 3921 };
  { key = "bell.curve.local_0013";                       label = "public_shulker_13";           arity = 7; tags = ["cached"]; since = "1.2.0"; weight = 3962 };
  { key = "bundle.curve.hidden_0014";                    label = "secondary_player_14";         arity = 2; tags = ["sync"]; since = "1.7.0"; weight = 2482 };
  { key = "particle.curve.eager_0015";                   label = "hidden_cartography_15";       arity = 3; tags = ["check"]; since = "1.7.0"; weight = 2868 };
  { key = "portal.curve.internal_0016";                  label = "modern_packet_16";            arity = 2; tags = ["parse"; "sync"; "experimental"]; since = "1.6.0"; weight = 939 };
  { key = "elytra.curve.primary_0017";                   label = "modern_particle_17";          arity = 5; tags = ["core"]; since = "1.2.0"; weight = 3704 };
  { key = "comparator.curve.stable_0018";                label = "secondary_bundle_18";         arity = 2; tags = ["parse"]; since = "1.5.2"; weight = 103 };
  { key = "campfire.curve.secondary_0019";               label = "provisional_hopper_19";       arity = 2; tags = ["registry"; "legacy"; "content"]; since = "1.3.1"; weight = 3691 };
  { key = "brewing.curve.stable_0020";                   label = "lazy_advancement_20";         arity = 1; tags = ["typed"; "packet"; "emit"]; since = "1.3.1"; weight = 2437 };
  { key = "conduit.curve.local_0021";                    label = "lazy_piston_21";              arity = 7; tags = ["emit"; "codegen"; "cached"]; since = "1.6.0"; weight = 3872 };
  { key = "piston.curve.provisional_0022";               label = "secondary_biome_22";          arity = 1; tags = ["parse"; "check"]; since = "1.6.0"; weight = 1379 };
  { key = "bundle.curve.derived_0023";                   label = "eager_sound_23";              arity = 7; tags = ["core"; "check"]; since = "1.6.0"; weight = 1060 };
  { key = "piston.curve.modern_0024";                    label = "eager_item_24";               arity = 4; tags = ["typed"]; since = "1.5.2"; weight = 21 };
  { key = "loom.curve.modern_0025";                      label = "local_trident_25";            arity = 0; tags = ["lower"; "async"]; since = "1.3.1"; weight = 4038 };
  { key = "compass.curve.fallback_0026";                 label = "public_smoker_26";            arity = 2; tags = ["content"]; since = "1.0.0"; weight = 2063 };
  { key = "shield.curve.stable_0027";                    label = "internal_player_27";          arity = 6; tags = ["lower"; "compat"]; since = "1.6.0"; weight = 1999 };
  { key = "gui.curve.canonical_0028";                    label = "hidden_repeater_28";          arity = 1; tags = ["content"; "emit"]; since = "1.3.1"; weight = 1035 };
  { key = "objective.curve.scoped_0029";                 label = "global_slot_29";              arity = 1; tags = ["content"]; since = "1.7.0"; weight = 2417 };
  { key = "minecart.curve.eager_0030";                   label = "secondary_region_30";         arity = 2; tags = ["emit"]; since = "1.6.0"; weight = 2137 };
  { key = "item.curve.local_0031";                       label = "eager_compass_31";            arity = 7; tags = ["compat"]; since = "1.0.0"; weight = 3563 };
  { key = "chunk.curve.strict_0032";                     label = "primary_structure_32";        arity = 0; tags = ["async"]; since = "1.2.0"; weight = 391 };
  { key = "cartography.curve.public_0033";               label = "provisional_bell_33";         arity = 1; tags = ["check"]; since = "1.9.0"; weight = 1357 };
  { key = "mob.curve.internal_0034";                     label = "loose_trade_34";              arity = 7; tags = ["parse"]; since = "1.8.3"; weight = 2593 };
  { key = "shield.curve.public_0035";                    label = "internal_clock_35";           arity = 0; tags = ["sync"; "packet"]; since = "1.0.0"; weight = 2362 };
  { key = "mob.curve.secondary_0036";                    label = "internal_elytra_36";          arity = 4; tags = ["check"; "cached"]; since = "1.8.3"; weight = 3446 };
  { key = "compass.curve.stable_0037";                   label = "canonical_npc_37";            arity = 7; tags = ["content"; "packet"]; since = "1.8.3"; weight = 2094 };
  { key = "hologram.curve.loose_0038";                   label = "scoped_brewing_38";           arity = 2; tags = ["emit"; "core"; "registry"]; since = "1.7.0"; weight = 2925 };
  { key = "arrow.curve.local_0039";                      label = "lazy_stonecutter_39";         arity = 3; tags = ["emit"]; since = "1.7.0"; weight = 3499 };
  { key = "furnace.curve.cached_0040";                   label = "local_banner_40";             arity = 1; tags = ["cached"; "lower"; "async"]; since = "1.6.0"; weight = 3773 };
  { key = "structure.curve.modern_0041";                 label = "legacy_bundle_41";            arity = 3; tags = ["experimental"; "content"]; since = "1.5.2"; weight = 3069 };
  { key = "enchant.curve.canonical_0042";                label = "hidden_compass_42";           arity = 2; tags = ["core"; "typed"; "packet"]; since = "1.3.1"; weight = 1271 };
  { key = "attribute.curve.cached_0043";                 label = "derived_conduit_43";          arity = 0; tags = ["cached"; "untyped"]; since = "1.0.0"; weight = 803 };
  { key = "shield.curve.stable_0044";                    label = "stable_dropper_44";           arity = 3; tags = ["packet"]; since = "1.7.0"; weight = 3247 };
  { key = "bundle.curve.canonical_0045";                 label = "provisional_dropper_45";      arity = 0; tags = ["hot"]; since = "1.3.1"; weight = 1054 };
  { key = "observer.curve.local_0046";                   label = "public_dropper_46";           arity = 5; tags = ["check"]; since = "1.7.0"; weight = 2584 };
  { key = "scoreboard.curve.provisional_0047";           label = "local_grindstone_47";         arity = 0; tags = ["typed"; "sync"]; since = "1.4.0"; weight = 3582 };
  { key = "loom.curve.local_0048";                       label = "modern_banner_48";            arity = 7; tags = ["compat"]; since = "1.4.0"; weight = 2138 };
  { key = "item.curve.local_0049";                       label = "primary_shulker_49";          arity = 3; tags = ["registry"; "untyped"]; since = "1.6.0"; weight = 3886 };
  { key = "comparator.curve.cached_0050";                label = "provisional_bossbar_50";      arity = 1; tags = ["untyped"]; since = "1.3.1"; weight = 2573 };
  { key = "block.curve.secondary_0051";                  label = "primary_smithing_51";         arity = 5; tags = ["cached"; "runtime"; "lower"]; since = "1.0.0"; weight = 3126 };
  { key = "dropper.curve.scoped_0052";                   label = "loose_comparator_52";         arity = 6; tags = ["untyped"; "lower"; "cold"]; since = "1.6.0"; weight = 3088 };
  { key = "conduit.curve.fallback_0053";                 label = "cached_player_53";            arity = 3; tags = ["untyped"; "async"]; since = "1.3.1"; weight = 3245 };
  { key = "effect.curve.strict_0054";                    label = "fallback_slot_54";            arity = 5; tags = ["cached"]; since = "1.4.0"; weight = 3887 };
  { key = "inventory.curve.internal_0055";               label = "eager_portal_55";             arity = 1; tags = ["parse"; "cached"]; since = "1.9.0"; weight = 2423 };
  { key = "banner.curve.lazy_0056";                      label = "primary_conduit_56";          arity = 7; tags = ["untyped"]; since = "1.4.0"; weight = 2694 };
  { key = "furnace.curve.secondary_0057";                label = "canonical_slot_57";           arity = 3; tags = ["sync"]; since = "1.8.3"; weight = 355 };
  { key = "grindstone.curve.secondary_0058";             label = "lazy_slot_58";                arity = 3; tags = ["codegen"]; since = "1.3.1"; weight = 1937 };
  { key = "elytra.curve.global_0059";                    label = "internal_smoker_59";          arity = 0; tags = ["packet"]; since = "1.7.0"; weight = 2616 };
  { key = "chunk.curve.stable_0060";                     label = "secondary_bell_60";           arity = 1; tags = ["experimental"; "compat"; "codegen"]; since = "1.6.0"; weight = 1816 };
  { key = "observer.curve.secondary_0061";               label = "local_campfire_61";           arity = 7; tags = ["cached"]; since = "1.6.0"; weight = 399 };
  { key = "brewing.curve.lazy_0062";                     label = "stable_campfire_62";          arity = 2; tags = ["emit"; "lower"]; since = "1.6.0"; weight = 1500 };
  { key = "campfire.curve.loose_0063";                   label = "secondary_barrel_63";         arity = 0; tags = ["runtime"; "content"; "experimental"]; since = "1.8.3"; weight = 2635 };
  { key = "observer.curve.scoped_0064";                  label = "modern_villager_64";          arity = 2; tags = ["sync"; "emit"]; since = "1.0.0"; weight = 313 };
  { key = "packet.curve.derived_0065";                   label = "derived_world_65";            arity = 2; tags = ["content"]; since = "1.4.0"; weight = 791 };
  { key = "minecart.curve.strict_0066";                  label = "derived_advancement_66";      arity = 3; tags = ["async"; "compat"; "cold"]; since = "1.9.0"; weight = 2985 };
  { key = "bell.curve.fallback_0067";                    label = "lazy_player_67";              arity = 1; tags = ["untyped"]; since = "1.7.0"; weight = 2042 };
  { key = "firework.curve.stable_0068";                  label = "primary_slot_68";             arity = 7; tags = ["packet"; "sync"]; since = "1.9.0"; weight = 3420 };
  { key = "banner_pattern.curve.legacy_0069";            label = "local_brewing_69";            arity = 7; tags = ["registry"; "check"]; since = "1.6.0"; weight = 1368 };
  { key = "smoker.curve.lazy_0070";                      label = "primary_effect_70";           arity = 0; tags = ["parse"; "async"; "cached"]; since = "1.9.0"; weight = 3547 };
  { key = "elytra.curve.derived_0071";                   label = "internal_dispenser_71";       arity = 6; tags = ["content"]; since = "1.6.0"; weight = 2229 };
  { key = "structure.curve.modern_0072";                 label = "public_loom_72";              arity = 3; tags = ["compat"]; since = "1.3.1"; weight = 2346 };
  { key = "scoreboard.curve.loose_0073";                 label = "hidden_packet_73";            arity = 0; tags = ["emit"; "core"; "experimental"]; since = "1.4.0"; weight = 2419 };
  { key = "bossbar.curve.cached_0074";                   label = "local_region_74";             arity = 7; tags = ["runtime"; "registry"]; since = "1.6.0"; weight = 1391 };
  { key = "trident.curve.cached_0075";                   label = "modern_map_75";               arity = 0; tags = ["untyped"; "runtime"; "packet"]; since = "1.4.0"; weight = 257 };
  { key = "grindstone.curve.strict_0076";                label = "scoped_trade_76";             arity = 4; tags = ["typed"; "content"; "parse"]; since = "1.9.0"; weight = 3333 };
  { key = "firework.curve.fallback_0077";                label = "global_spawner_77";           arity = 1; tags = ["core"]; since = "1.7.0"; weight = 1814 };
  { key = "campfire.curve.secondary_0078";               label = "stable_shield_78";            arity = 4; tags = ["codegen"; "packet"; "experimental"]; since = "1.8.3"; weight = 2992 };
  { key = "target.curve.public_0079";                    label = "fallback_dispenser_79";       arity = 3; tags = ["experimental"]; since = "1.5.2"; weight = 2674 };
  { key = "trident.curve.internal_0080";                 label = "hidden_pane_80";              arity = 2; tags = ["core"; "registry"; "content"]; since = "1.8.3"; weight = 1845 };
  { key = "beacon.curve.internal_0081";                  label = "primary_pane_81";             arity = 0; tags = ["experimental"; "untyped"]; since = "1.7.0"; weight = 1447 };
  { key = "region.curve.global_0082";                    label = "hidden_particle_82";          arity = 3; tags = ["parse"; "runtime"; "hot"]; since = "1.4.0"; weight = 3838 };
  { key = "packet.curve.secondary_0083";                 label = "secondary_bossbar_83";        arity = 2; tags = ["legacy"; "lower"]; since = "1.3.1"; weight = 463 };
  { key = "gui.curve.strict_0084";                       label = "cached_composter_84";         arity = 3; tags = ["experimental"]; since = "1.5.2"; weight = 1650 };
  { key = "world.curve.public_0085";                     label = "strict_mob_85";               arity = 2; tags = ["cached"]; since = "1.3.1"; weight = 434 };
  { key = "bundle.curve.legacy_0086";                    label = "fallback_npc_86";             arity = 0; tags = ["content"; "legacy"; "codegen"]; since = "1.3.1"; weight = 391 };
  { key = "beacon.curve.hidden_0087";                    label = "modern_conduit_87";           arity = 4; tags = ["legacy"; "cold"]; since = "1.0.0"; weight = 723 };
  { key = "block.curve.canonical_0088";                  label = "global_hologram_88";          arity = 7; tags = ["check"]; since = "1.8.3"; weight = 1330 };
  { key = "slot.curve.stable_0089";                      label = "eager_lectern_89";            arity = 7; tags = ["parse"]; since = "1.3.1"; weight = 1916 };
  { key = "block.curve.derived_0090";                    label = "provisional_tablist_90";      arity = 7; tags = ["async"]; since = "1.5.2"; weight = 1136 };
  { key = "slot.curve.internal_0091";                    label = "global_portal_91";            arity = 0; tags = ["async"; "content"]; since = "1.3.1"; weight = 3917 };
  { key = "world.curve.secondary_0092";                  label = "canonical_trade_92";          arity = 5; tags = ["runtime"; "untyped"; "experimental"]; since = "1.3.1"; weight = 3557 };
  { key = "npc.curve.secondary_0093";                    label = "provisional_tablist_93";      arity = 2; tags = ["codegen"; "untyped"; "legacy"]; since = "1.0.0"; weight = 1976 };
  { key = "loom.curve.scoped_0094";                      label = "cached_enchant_94";           arity = 7; tags = ["codegen"; "lower"; "sync"]; since = "1.9.0"; weight = 3809 };
  { key = "bell.curve.canonical_0095";                   label = "eager_composter_95";          arity = 5; tags = ["legacy"]; since = "1.9.0"; weight = 3590 };
  { key = "particle.curve.cached_0096";                  label = "primary_bossbar_96";          arity = 1; tags = ["hot"; "cold"; "codegen"]; since = "1.9.0"; weight = 16 };
  { key = "smoker.curve.public_0097";                    label = "public_observer_97";          arity = 0; tags = ["compat"]; since = "1.8.3"; weight = 1631 };
  { key = "grindstone.curve.stable_0098";                label = "internal_arrow_98";           arity = 4; tags = ["cold"; "hot"]; since = "1.5.2"; weight = 1993 };
  { key = "repeater.curve.public_0099";                  label = "global_team_99";              arity = 6; tags = ["check"; "core"; "legacy"]; since = "1.7.0"; weight = 1054 };
  { key = "scoreboard.curve.loose_0100";                 label = "lazy_gui_100";                arity = 1; tags = ["hot"; "legacy"]; since = "1.5.2"; weight = 65 };
  { key = "barrel.curve.local_0101";                     label = "fallback_cartography_101";    arity = 5; tags = ["cached"]; since = "1.2.0"; weight = 337 };
  { key = "slot.curve.fallback_0102";                    label = "global_smoker_102";           arity = 0; tags = ["untyped"; "content"; "emit"]; since = "1.0.0"; weight = 3635 };
  { key = "banner_pattern.curve.local_0103";             label = "canonical_banner_pattern_103"; arity = 4; tags = ["legacy"; "core"; "packet"]; since = "1.9.0"; weight = 2428 };
  { key = "pane.curve.loose_0104";                       label = "legacy_chunk_104";            arity = 1; tags = ["check"; "codegen"; "packet"]; since = "1.6.0"; weight = 1018 };
  { key = "attribute.curve.legacy_0105";                 label = "derived_piston_105";          arity = 0; tags = ["lower"; "cold"; "async"]; since = "1.4.0"; weight = 2640 };
  { key = "world.curve.loose_0106";                      label = "primary_bossbar_106";         arity = 5; tags = ["sync"; "hot"]; since = "1.4.0"; weight = 654 };
  { key = "dropper.curve.fallback_0107";                 label = "public_tablist_107";          arity = 3; tags = ["async"; "packet"; "lower"]; since = "1.8.3"; weight = 3071 };
  { key = "campfire.curve.stable_0108";                  label = "public_spawner_108";          arity = 7; tags = ["core"; "parse"]; since = "1.7.0"; weight = 3752 };
  { key = "sound.curve.internal_0109";                   label = "modern_hopper_109";           arity = 7; tags = ["emit"; "hot"]; since = "1.3.1"; weight = 2794 };
  { key = "grindstone.curve.eager_0110";                 label = "global_shulker_110";          arity = 2; tags = ["sync"; "cached"]; since = "1.6.0"; weight = 1257 };
  { key = "trident.curve.modern_0111";                   label = "primary_banner_pattern_111";  arity = 1; tags = ["async"; "packet"]; since = "1.3.1"; weight = 1357 };
  { key = "barrel.curve.local_0112";                     label = "secondary_scoreboard_112";    arity = 7; tags = ["cached"; "cold"]; since = "1.7.0"; weight = 2791 };
  { key = "observer.curve.loose_0113";                   label = "local_trade_113";             arity = 1; tags = ["legacy"; "packet"; "registry"]; since = "1.9.0"; weight = 978 };
  { key = "trade.curve.cached_0114";                     label = "strict_banner_114";           arity = 6; tags = ["packet"]; since = "1.7.0"; weight = 821 };
  { key = "smoker.curve.lazy_0115";                      label = "fallback_hopper_115";         arity = 2; tags = ["experimental"; "core"]; since = "1.5.2"; weight = 3932 };
  { key = "loom.curve.cached_0116";                      label = "strict_grindstone_116";       arity = 5; tags = ["cold"]; since = "1.3.1"; weight = 2286 };
  { key = "trident.curve.stable_0117";                   label = "eager_furnace_117";           arity = 3; tags = ["hot"]; since = "1.4.0"; weight = 57 };
  { key = "composter.curve.internal_0118";               label = "strict_anvil_118";            arity = 4; tags = ["content"]; since = "1.0.0"; weight = 1146 };
  { key = "compass.curve.primary_0119";                  label = "eager_comparator_119";        arity = 4; tags = ["core"; "cached"]; since = "1.4.0"; weight = 2113 };
  { key = "crossbow.curve.cached_0120";                  label = "loose_dropper_120";           arity = 1; tags = ["hot"; "codegen"]; since = "1.9.0"; weight = 3019 };
  { key = "structure.curve.cached_0121";                 label = "provisional_map_121";         arity = 7; tags = ["codegen"; "check"]; since = "1.3.1"; weight = 3294 };
  { key = "map.curve.internal_0122";                     label = "strict_mob_122";              arity = 4; tags = ["emit"; "codegen"; "packet"]; since = "1.5.2"; weight = 2735 };
  { key = "furnace.curve.secondary_0123";                label = "public_scoreboard_123";       arity = 5; tags = ["runtime"; "async"; "lower"]; since = "1.2.0"; weight = 93 };
  { key = "bell.curve.strict_0124";                      label = "hidden_enchant_124";          arity = 7; tags = ["registry"; "sync"; "cold"]; since = "1.9.0"; weight = 896 };
  { key = "stonecutter.curve.global_0125";               label = "local_scoreboard_125";        arity = 1; tags = ["sync"; "emit"; "codegen"]; since = "1.4.0"; weight = 3506 };
  { key = "loom.curve.hidden_0126";                      label = "lazy_map_126";                arity = 1; tags = ["cached"; "sync"]; since = "1.0.0"; weight = 1227 };
  { key = "tablist.curve.fallback_0127";                 label = "global_composter_127";        arity = 2; tags = ["check"; "registry"; "sync"]; since = "1.7.0"; weight = 3053 };
  { key = "structure.curve.global_0128";                 label = "strict_repeater_128";         arity = 4; tags = ["parse"]; since = "1.7.0"; weight = 837 };
  { key = "item.curve.global_0129";                      label = "local_beacon_129";            arity = 3; tags = ["async"]; since = "1.3.1"; weight = 1074 };
  { key = "packet.curve.fallback_0130";                  label = "internal_dropper_130";        arity = 4; tags = ["lower"; "legacy"; "experimental"]; since = "1.5.2"; weight = 3588 };
  { key = "piston.curve.legacy_0131";                    label = "provisional_elytra_131";      arity = 4; tags = ["cold"; "cached"]; since = "1.7.0"; weight = 2927 };
  { key = "arrow.curve.eager_0132";                      label = "strict_gui_132";              arity = 5; tags = ["registry"; "sync"; "legacy"]; since = "1.8.3"; weight = 3562 };
  { key = "attribute.curve.eager_0133";                  label = "derived_composter_133";       arity = 6; tags = ["codegen"; "hot"; "core"]; since = "1.9.0"; weight = 490 };
  { key = "block.curve.provisional_0134";                label = "secondary_banner_pattern_134"; arity = 0; tags = ["check"; "cold"; "untyped"]; since = "1.0.0"; weight = 2601 };
  { key = "clock.curve.primary_0135";                    label = "hidden_inventory_135";        arity = 3; tags = ["codegen"]; since = "1.5.2"; weight = 535 };
  { key = "compass.curve.modern_0136";                   label = "public_item_136";             arity = 7; tags = ["parse"]; since = "1.5.2"; weight = 2320 };
  { key = "cartography.curve.loose_0137";                label = "stable_team_137";             arity = 3; tags = ["content"]; since = "1.6.0"; weight = 1228 };
  { key = "stonecutter.curve.secondary_0138";            label = "local_tablist_138";           arity = 0; tags = ["lower"; "registry"]; since = "1.5.2"; weight = 2267 };
  { key = "brewing.curve.secondary_0139";                label = "eager_slot_139";              arity = 7; tags = ["experimental"; "runtime"; "core"]; since = "1.5.2"; weight = 1857 };
  { key = "beacon.curve.secondary_0140";                 label = "canonical_chunk_140";         arity = 0; tags = ["hot"; "sync"; "packet"]; since = "1.6.0"; weight = 386 };
  { key = "map.curve.hidden_0141";                       label = "local_stonecutter_141";       arity = 6; tags = ["emit"; "compat"]; since = "1.4.0"; weight = 3684 };
  { key = "furnace.curve.cached_0142";                   label = "derived_portal_142";          arity = 2; tags = ["cached"; "lower"]; since = "1.3.1"; weight = 1863 };
  { key = "block.curve.canonical_0143";                  label = "legacy_crossbow_143";         arity = 6; tags = ["core"; "emit"; "untyped"]; since = "1.0.0"; weight = 580 };
  { key = "enchant.curve.public_0144";                   label = "canonical_boat_144";          arity = 5; tags = ["typed"]; since = "1.8.3"; weight = 3604 };
  { key = "pane.curve.modern_0145";                      label = "local_villager_145";          arity = 0; tags = ["parse"]; since = "1.9.0"; weight = 3973 };
  { key = "lectern.curve.fallback_0146";                 label = "lazy_portal_146";             arity = 1; tags = ["cold"; "experimental"]; since = "1.4.0"; weight = 1396 };
  { key = "lectern.curve.cached_0147";                   label = "canonical_clock_147";         arity = 3; tags = ["cached"]; since = "1.2.0"; weight = 1408 };
  { key = "boat.curve.global_0148";                      label = "provisional_effect_148";      arity = 3; tags = ["experimental"]; since = "1.2.0"; weight = 1010 };
  { key = "minecart.curve.secondary_0149";               label = "stable_smoker_149";           arity = 7; tags = ["cached"]; since = "1.4.0"; weight = 3040 };
  { key = "elytra.curve.hidden_0150";                    label = "strict_attribute_150";        arity = 1; tags = ["check"; "legacy"; "emit"]; since = "1.2.0"; weight = 1859 };
  { key = "bossbar.curve.scoped_0151";                   label = "strict_potion_151";           arity = 6; tags = ["cold"]; since = "1.0.0"; weight = 3662 };
  { key = "anvil.curve.provisional_0152";                label = "primary_inventory_152";       arity = 2; tags = ["emit"; "check"; "cold"]; since = "1.0.0"; weight = 852 };
  { key = "enchant.curve.canonical_0153";                label = "provisional_trident_153";     arity = 2; tags = ["registry"]; since = "1.0.0"; weight = 1177 };
  { key = "villager.curve.canonical_0154";               label = "secondary_brewing_154";       arity = 4; tags = ["hot"; "cached"; "core"]; since = "1.7.0"; weight = 2765 };
  { key = "gui.curve.lazy_0155";                         label = "eager_conduit_155";           arity = 0; tags = ["core"; "runtime"; "async"]; since = "1.8.3"; weight = 3440 };
  { key = "crossbow.curve.fallback_0156";                label = "lazy_shield_156";             arity = 5; tags = ["parse"; "compat"; "content"]; since = "1.5.2"; weight = 1187 };
  { key = "player.curve.hidden_0157";                    label = "local_villager_157";          arity = 4; tags = ["check"]; since = "1.3.1"; weight = 1375 };
  { key = "hologram.curve.secondary_0158";               label = "primary_map_158";             arity = 7; tags = ["packet"; "async"]; since = "1.3.1"; weight = 4000 };
  { key = "attribute.curve.local_0159";                  label = "strict_stonecutter_159";      arity = 4; tags = ["packet"; "parse"]; since = "1.2.0"; weight = 1227 };
  { key = "tablist.curve.global_0160";                   label = "internal_attribute_160";      arity = 2; tags = ["async"]; since = "1.4.0"; weight = 1124 };
  { key = "cartography.curve.lazy_0161";                 label = "fallback_entity_161";         arity = 2; tags = ["lower"; "content"]; since = "1.9.0"; weight = 891 };
  { key = "effect.curve.loose_0162";                     label = "cached_bossbar_162";          arity = 1; tags = ["packet"; "sync"; "registry"]; since = "1.2.0"; weight = 215 };
  { key = "mob.curve.primary_0163";                      label = "canonical_sound_163";         arity = 4; tags = ["check"]; since = "1.7.0"; weight = 1616 };
  { key = "trade.curve.loose_0164";                      label = "public_inventory_164";        arity = 1; tags = ["packet"; "async"]; since = "1.2.0"; weight = 2764 };
  { key = "minecart.curve.cached_0165";                  label = "canonical_observer_165";      arity = 3; tags = ["runtime"]; since = "1.4.0"; weight = 3970 };
  { key = "smoker.curve.primary_0166";                   label = "legacy_boat_166";             arity = 1; tags = ["compat"]; since = "1.7.0"; weight = 563 };
  { key = "furnace.curve.lazy_0167";                     label = "provisional_dropper_167";     arity = 5; tags = ["core"]; since = "1.9.0"; weight = 3404 };
  { key = "arrow.curve.global_0168";                     label = "global_advancement_168";      arity = 2; tags = ["async"; "parse"]; since = "1.3.1"; weight = 2839 };
  { key = "pane.curve.cached_0169";                      label = "strict_map_169";              arity = 7; tags = ["async"]; since = "1.6.0"; weight = 1901 };
  { key = "tablist.curve.strict_0170";                   label = "secondary_loom_170";          arity = 1; tags = ["legacy"; "compat"; "content"]; since = "1.2.0"; weight = 599 };
  { key = "scoreboard.curve.provisional_0171";           label = "internal_cartography_171";    arity = 7; tags = ["legacy"; "emit"]; since = "1.4.0"; weight = 3381 };
  { key = "map.curve.fallback_0172";                     label = "legacy_elytra_172";           arity = 1; tags = ["content"; "cached"; "parse"]; since = "1.3.1"; weight = 681 };
  { key = "shield.curve.fallback_0173";                  label = "public_enchant_173";          arity = 0; tags = ["hot"]; since = "1.7.0"; weight = 448 };
  { key = "anvil.curve.derived_0174";                    label = "secondary_mob_174";           arity = 3; tags = ["untyped"]; since = "1.9.0"; weight = 2603 };
  { key = "piston.curve.public_0175";                    label = "canonical_grindstone_175";    arity = 2; tags = ["core"; "check"; "legacy"]; since = "1.5.2"; weight = 3323 };
  { key = "effect.curve.public_0176";                    label = "strict_boat_176";             arity = 2; tags = ["async"; "runtime"]; since = "1.2.0"; weight = 2259 };
  { key = "campfire.curve.fallback_0177";                label = "eager_smithing_177";          arity = 2; tags = ["experimental"; "parse"; "packet"]; since = "1.2.0"; weight = 2764 };
  { key = "elytra.curve.loose_0178";                     label = "derived_hologram_178";        arity = 7; tags = ["emit"; "cached"; "compat"]; since = "1.7.0"; weight = 3775 };
  { key = "crossbow.curve.lazy_0179";                    label = "eager_banner_pattern_179";    arity = 6; tags = ["packet"]; since = "1.5.2"; weight = 824 };
  { key = "biome.curve.modern_0180";                     label = "stable_scoreboard_180";       arity = 7; tags = ["typed"; "async"]; since = "1.5.2"; weight = 1207 };
  { key = "world.curve.provisional_0181";                label = "strict_dropper_181";          arity = 0; tags = ["packet"; "async"]; since = "1.2.0"; weight = 2907 };
  { key = "boat.curve.lazy_0182";                        label = "stable_npc_182";              arity = 2; tags = ["experimental"]; since = "1.0.0"; weight = 3381 };
  { key = "structure.curve.global_0183";                 label = "fallback_structure_183";      arity = 7; tags = ["lower"; "codegen"; "experimental"]; since = "1.3.1"; weight = 1190 };
  { key = "clock.curve.hidden_0184";                     label = "eager_potion_184";            arity = 6; tags = ["packet"; "core"; "sync"]; since = "1.3.1"; weight = 3440 };
  { key = "compass.curve.local_0185";                    label = "eager_potion_185";            arity = 4; tags = ["untyped"; "packet"]; since = "1.7.0"; weight = 1184 };
  { key = "enchant.curve.stable_0186";                   label = "strict_enchant_186";          arity = 0; tags = ["runtime"]; since = "1.2.0"; weight = 3283 };
  { key = "packet.curve.canonical_0187";                 label = "scoped_brewing_187";          arity = 3; tags = ["experimental"; "parse"]; since = "1.6.0"; weight = 3187 };
  { key = "spawner.curve.fallback_0188";                 label = "global_advancement_188";      arity = 5; tags = ["check"; "content"]; since = "1.7.0"; weight = 3609 };
  { key = "minecart.curve.scoped_0189";                  label = "legacy_mob_189";              arity = 5; tags = ["legacy"; "hot"]; since = "1.7.0"; weight = 3263 };
  { key = "barrel.curve.eager_0190";                     label = "loose_banner_190";            arity = 0; tags = ["parse"; "cold"]; since = "1.6.0"; weight = 2542 };
  { key = "grindstone.curve.stable_0191";                label = "modern_crossbow_191";         arity = 0; tags = ["lower"; "cold"]; since = "1.7.0"; weight = 1927 };
  { key = "scoreboard.curve.strict_0192";                label = "legacy_grindstone_192";       arity = 0; tags = ["cached"]; since = "1.9.0"; weight = 2783 };
  { key = "tablist.curve.lazy_0193";                     label = "loose_chunk_193";             arity = 7; tags = ["compat"; "sync"]; since = "1.5.2"; weight = 3359 };
  { key = "item.curve.public_0194";                      label = "modern_barrel_194";           arity = 3; tags = ["sync"; "untyped"; "compat"]; since = "1.5.2"; weight = 3153 };
  { key = "bundle.curve.global_0195";                    label = "stable_dropper_195";          arity = 1; tags = ["packet"; "cached"]; since = "1.9.0"; weight = 410 };
  { key = "minecart.curve.modern_0196";                  label = "modern_chunk_196";            arity = 2; tags = ["sync"]; since = "1.5.2"; weight = 645 };
  { key = "minecart.curve.internal_0197";                label = "cached_gui_197";              arity = 1; tags = ["lower"]; since = "1.5.2"; weight = 3387 };
  { key = "potion.curve.loose_0198";                     label = "derived_target_198";          arity = 3; tags = ["content"; "registry"]; since = "1.9.0"; weight = 1636 };
  { key = "minecart.curve.hidden_0199";                  label = "internal_anvil_199";          arity = 3; tags = ["parse"; "experimental"; "cached"]; since = "1.5.2"; weight = 1613 };
  { key = "smithing.curve.legacy_0200";                  label = "hidden_clock_200";            arity = 7; tags = ["compat"; "core"; "registry"]; since = "1.6.0"; weight = 504 };
  { key = "player.curve.strict_0201";                    label = "modern_observer_201";         arity = 3; tags = ["compat"; "parse"]; since = "1.3.1"; weight = 287 };
  { key = "clock.curve.legacy_0202";                     label = "secondary_bell_202";          arity = 1; tags = ["hot"]; since = "1.5.2"; weight = 2115 };
  { key = "npc.curve.lazy_0203";                         label = "global_trade_203";            arity = 1; tags = ["registry"; "runtime"]; since = "1.8.3"; weight = 2656 };
  { key = "anvil.curve.primary_0204";                    label = "provisional_conduit_204";     arity = 6; tags = ["content"]; since = "1.0.0"; weight = 3546 };
  { key = "target.curve.public_0205";                    label = "secondary_repeater_205";      arity = 4; tags = ["experimental"; "emit"; "core"]; since = "1.4.0"; weight = 684 };
  { key = "beacon.curve.provisional_0206";               label = "secondary_shield_206";        arity = 1; tags = ["registry"]; since = "1.5.2"; weight = 1536 };
  { key = "recipe.curve.fallback_0207";                  label = "scoped_biome_207";            arity = 2; tags = ["async"; "content"; "registry"]; since = "1.7.0"; weight = 3479 };
  { key = "target.curve.local_0208";                     label = "fallback_rail_208";           arity = 6; tags = ["async"; "parse"]; since = "1.2.0"; weight = 408 };
  { key = "player.curve.legacy_0209";                    label = "global_crossbow_209";         arity = 0; tags = ["legacy"; "typed"; "lower"]; since = "1.5.2"; weight = 727 };
  { key = "firework.curve.internal_0210";                label = "provisional_enchant_210";     arity = 4; tags = ["async"]; since = "1.6.0"; weight = 2285 };
  { key = "banner_pattern.curve.local_0211";             label = "modern_sound_211";            arity = 6; tags = ["check"]; since = "1.4.0"; weight = 2339 };
  { key = "world.curve.scoped_0212";                     label = "loose_compass_212";           arity = 4; tags = ["async"]; since = "1.7.0"; weight = 553 };
  { key = "observer.curve.derived_0213";                 label = "local_bell_213";              arity = 4; tags = ["sync"]; since = "1.3.1"; weight = 1165 };
  { key = "piston.curve.secondary_0214";                 label = "cached_player_214";           arity = 4; tags = ["parse"; "hot"]; since = "1.4.0"; weight = 3044 };
  { key = "block.curve.lazy_0215";                       label = "public_target_215";           arity = 5; tags = ["core"; "check"; "async"]; since = "1.5.2"; weight = 3537 };
  { key = "slot.curve.primary_0216";                     label = "cached_team_216";             arity = 6; tags = ["untyped"; "hot"; "emit"]; since = "1.6.0"; weight = 1068 };
  { key = "packet.curve.global_0217";                    label = "lazy_world_217";              arity = 2; tags = ["typed"]; since = "1.6.0"; weight = 204 };
  { key = "arrow.curve.scoped_0218";                     label = "legacy_beacon_218";           arity = 1; tags = ["cold"]; since = "1.4.0"; weight = 2669 };
  { key = "potion.curve.canonical_0219";                 label = "cached_barrel_219";           arity = 3; tags = ["content"; "legacy"]; since = "1.7.0"; weight = 3068 };
  { key = "crossbow.curve.hidden_0220";                  label = "hidden_campfire_220";         arity = 4; tags = ["hot"; "check"; "untyped"]; since = "1.3.1"; weight = 1208 };
  { key = "sound.curve.canonical_0221";                  label = "local_repeater_221";          arity = 0; tags = ["compat"; "content"; "experimental"]; since = "1.7.0"; weight = 1322 };
  { key = "inventory.curve.fallback_0222";               label = "hidden_packet_222";           arity = 0; tags = ["emit"; "typed"]; since = "1.8.3"; weight = 2105 };
  { key = "dropper.curve.primary_0223";                  label = "legacy_loom_223";             arity = 7; tags = ["runtime"]; since = "1.4.0"; weight = 617 };
  { key = "compass.curve.canonical_0224";                label = "scoped_trident_224";          arity = 1; tags = ["core"; "compat"; "emit"]; since = "1.3.1"; weight = 1444 };
  { key = "portal.curve.global_0225";                    label = "derived_composter_225";       arity = 2; tags = ["codegen"; "cached"; "content"]; since = "1.3.1"; weight = 3172 };
  { key = "entity.curve.secondary_0226";                 label = "hidden_attribute_226";        arity = 4; tags = ["core"; "legacy"]; since = "1.6.0"; weight = 627 };
  { key = "trade.curve.secondary_0227";                  label = "modern_comparator_227";       arity = 5; tags = ["hot"]; since = "1.5.2"; weight = 614 };
  { key = "attribute.curve.lazy_0228";                   label = "fallback_smoker_228";         arity = 3; tags = ["async"]; since = "1.6.0"; weight = 3335 };
  { key = "particle.curve.provisional_0229";             label = "loose_packet_229";            arity = 5; tags = ["hot"]; since = "1.8.3"; weight = 2571 };
  { key = "observer.curve.derived_0230";                 label = "legacy_particle_230";         arity = 1; tags = ["check"; "runtime"; "cached"]; since = "1.8.3"; weight = 1881 };
  { key = "campfire.curve.fallback_0231";                label = "primary_trident_231";         arity = 1; tags = ["codegen"; "emit"; "registry"]; since = "1.8.3"; weight = 905 };
  { key = "repeater.curve.modern_0232";                  label = "stable_slot_232";             arity = 3; tags = ["legacy"]; since = "1.9.0"; weight = 1540 };
  { key = "biome.curve.canonical_0233";                  label = "derived_hopper_233";          arity = 3; tags = ["untyped"; "packet"]; since = "1.0.0"; weight = 2668 };
  { key = "smithing.curve.lazy_0234";                    label = "lazy_potion_234";             arity = 3; tags = ["async"]; since = "1.3.1"; weight = 922 };
  { key = "team.curve.eager_0235";                       label = "global_bundle_235";           arity = 5; tags = ["registry"]; since = "1.3.1"; weight = 987 };
  { key = "block.curve.secondary_0236";                  label = "hidden_lectern_236";          arity = 4; tags = ["emit"]; since = "1.9.0"; weight = 3667 };
  { key = "inventory.curve.secondary_0237";              label = "secondary_entity_237";        arity = 2; tags = ["runtime"; "check"; "typed"]; since = "1.6.0"; weight = 874 };
  { key = "smoker.curve.scoped_0238";                    label = "lazy_shield_238";             arity = 5; tags = ["cold"; "experimental"; "sync"]; since = "1.5.2"; weight = 3848 };
  { key = "tablist.curve.cached_0239";                   label = "internal_structure_239";      arity = 2; tags = ["hot"; "parse"; "registry"]; since = "1.9.0"; weight = 1069 };
  { key = "enchant.curve.global_0240";                   label = "strict_region_240";           arity = 0; tags = ["cold"]; since = "1.4.0"; weight = 611 };
  { key = "pane.curve.public_0241";                      label = "local_lectern_241";           arity = 3; tags = ["hot"; "check"; "emit"]; since = "1.3.1"; weight = 3967 };
  { key = "repeater.curve.strict_0242";                  label = "scoped_trade_242";            arity = 0; tags = ["codegen"; "registry"; "emit"]; since = "1.0.0"; weight = 3651 };
  { key = "repeater.curve.hidden_0243";                  label = "global_banner_243";           arity = 3; tags = ["content"]; since = "1.2.0"; weight = 489 };
  { key = "scoreboard.curve.scoped_0244";                label = "secondary_packet_244";        arity = 4; tags = ["experimental"; "compat"]; since = "1.4.0"; weight = 649 };
  { key = "spawner.curve.internal_0245";                 label = "modern_gui_245";              arity = 5; tags = ["core"]; since = "1.9.0"; weight = 1580 };
  { key = "enchant.curve.stable_0246";                   label = "legacy_biome_246";            arity = 7; tags = ["compat"]; since = "1.3.1"; weight = 4032 };
  { key = "dropper.curve.public_0247";                   label = "secondary_crossbow_247";      arity = 4; tags = ["codegen"; "parse"]; since = "1.4.0"; weight = 109 };
  { key = "anvil.curve.canonical_0248";                  label = "canonical_lectern_248";       arity = 3; tags = ["compat"; "experimental"]; since = "1.9.0"; weight = 1224 };
  { key = "slot.curve.scoped_0249";                      label = "local_team_249";              arity = 3; tags = ["cold"; "async"]; since = "1.5.2"; weight = 2815 };
  { key = "banner.curve.fallback_0250";                  label = "derived_chunk_250";           arity = 3; tags = ["cold"]; since = "1.4.0"; weight = 3622 };
  { key = "hologram.curve.internal_0251";                label = "strict_elytra_251";           arity = 5; tags = ["content"; "legacy"; "experimental"]; since = "1.0.0"; weight = 1034 };
  { key = "team.curve.loose_0252";                       label = "modern_brewing_252";          arity = 3; tags = ["check"; "content"]; since = "1.8.3"; weight = 4019 };
  { key = "boat.curve.fallback_0253";                    label = "loose_crossbow_253";          arity = 7; tags = ["emit"; "lower"]; since = "1.0.0"; weight = 2341 };
  { key = "tablist.curve.eager_0254";                    label = "cached_composter_254";        arity = 3; tags = ["core"]; since = "1.5.2"; weight = 154 };
  { key = "composter.curve.secondary_0255";              label = "global_advancement_255";      arity = 7; tags = ["registry"]; since = "1.4.0"; weight = 206 };
  { key = "tablist.curve.hidden_0256";                   label = "cached_banner_pattern_256";   arity = 2; tags = ["packet"]; since = "1.8.3"; weight = 488 };
  { key = "banner.curve.global_0257";                    label = "cached_inventory_257";        arity = 1; tags = ["hot"; "emit"]; since = "1.5.2"; weight = 2020 };
  { key = "villager.curve.provisional_0258";             label = "canonical_composter_258";     arity = 3; tags = ["hot"; "registry"]; since = "1.9.0"; weight = 1396 };
  { key = "mob.curve.canonical_0259";                    label = "cached_tablist_259";          arity = 7; tags = ["typed"; "registry"; "cached"]; since = "1.4.0"; weight = 2969 };
  { key = "portal.curve.loose_0260";                     label = "scoped_enchant_260";          arity = 0; tags = ["core"]; since = "1.5.2"; weight = 2129 };
  { key = "bell.curve.loose_0261";                       label = "internal_compass_261";        arity = 4; tags = ["hot"]; since = "1.0.0"; weight = 2852 };
  { key = "item.curve.provisional_0262";                 label = "modern_villager_262";         arity = 0; tags = ["core"; "cached"]; since = "1.0.0"; weight = 2501 };
  { key = "objective.curve.local_0263";                  label = "primary_cartography_263";     arity = 0; tags = ["check"; "emit"; "registry"]; since = "1.4.0"; weight = 3938 };
  { key = "gui.curve.loose_0264";                        label = "strict_map_264";              arity = 2; tags = ["lower"]; since = "1.8.3"; weight = 675 };
  { key = "structure.curve.eager_0265";                  label = "modern_barrel_265";           arity = 1; tags = ["registry"]; since = "1.0.0"; weight = 1220 };
  { key = "attribute.curve.public_0266";                 label = "eager_smoker_266";            arity = 6; tags = ["codegen"; "cold"; "lower"]; since = "1.9.0"; weight = 4056 };
  { key = "crossbow.curve.secondary_0267";               label = "cached_target_267";           arity = 3; tags = ["cached"; "cold"; "emit"]; since = "1.5.2"; weight = 1001 };
  { key = "entity.curve.public_0268";                    label = "scoped_item_268";             arity = 6; tags = ["codegen"; "hot"]; since = "1.0.0"; weight = 4095 };
  { key = "firework.curve.derived_0269";                 label = "lazy_entity_269";             arity = 4; tags = ["async"; "packet"]; since = "1.8.3"; weight = 219 };
  { key = "mob.curve.public_0270";                       label = "derived_trident_270";         arity = 4; tags = ["cached"]; since = "1.0.0"; weight = 3360 };
  { key = "npc.curve.stable_0271";                       label = "legacy_bossbar_271";          arity = 6; tags = ["compat"]; since = "1.4.0"; weight = 3161 };
  { key = "smithing.curve.hidden_0272";                  label = "global_bundle_272";           arity = 3; tags = ["codegen"; "lower"]; since = "1.4.0"; weight = 1072 };
  { key = "clock.curve.stable_0273";                     label = "hidden_barrel_273";           arity = 7; tags = ["typed"; "sync"; "async"]; since = "1.7.0"; weight = 1512 };
  { key = "barrel.curve.eager_0274";                     label = "eager_villager_274";          arity = 3; tags = ["content"]; since = "1.6.0"; weight = 608 };
  { key = "map.curve.canonical_0275";                    label = "primary_tablist_275";         arity = 2; tags = ["async"; "compat"; "sync"]; since = "1.2.0"; weight = 2884 };
  { key = "smithing.curve.lazy_0276";                    label = "eager_recipe_276";            arity = 5; tags = ["runtime"; "cold"; "lower"]; since = "1.3.1"; weight = 2108 };
  { key = "banner_pattern.curve.modern_0277";            label = "derived_smithing_277";        arity = 7; tags = ["legacy"]; since = "1.8.3"; weight = 633 };
  { key = "biome.curve.public_0278";                     label = "secondary_bossbar_278";       arity = 5; tags = ["legacy"]; since = "1.8.3"; weight = 779 };
  { key = "recipe.curve.internal_0279";                  label = "lazy_player_279";             arity = 2; tags = ["legacy"]; since = "1.3.1"; weight = 3159 };
  { key = "chunk.curve.cached_0280";                     label = "primary_attribute_280";       arity = 3; tags = ["cold"; "content"]; since = "1.3.1"; weight = 4008 };
  { key = "trade.curve.public_0281";                     label = "fallback_rail_281";           arity = 2; tags = ["check"; "codegen"]; since = "1.4.0"; weight = 2770 };
  { key = "entity.curve.scoped_0282";                    label = "strict_advancement_282";      arity = 2; tags = ["legacy"; "packet"]; since = "1.8.3"; weight = 2424 };
  { key = "bundle.curve.primary_0283";                   label = "loose_portal_283";            arity = 0; tags = ["codegen"; "typed"; "async"]; since = "1.9.0"; weight = 4075 };
  { key = "recipe.curve.secondary_0284";                 label = "cached_villager_284";         arity = 3; tags = ["hot"]; since = "1.7.0"; weight = 442 };
  { key = "chunk.curve.lazy_0285";                       label = "stable_villager_285";         arity = 3; tags = ["async"; "core"; "parse"]; since = "1.7.0"; weight = 318 };
  { key = "recipe.curve.public_0286";                    label = "strict_shulker_286";          arity = 7; tags = ["emit"; "packet"]; since = "1.9.0"; weight = 3279 };
  { key = "elytra.curve.lazy_0287";                      label = "eager_smoker_287";            arity = 6; tags = ["check"; "cached"]; since = "1.5.2"; weight = 2638 };
  { key = "barrel.curve.derived_0288";                   label = "global_repeater_288";         arity = 2; tags = ["codegen"]; since = "1.4.0"; weight = 1536 };
  { key = "loom.curve.strict_0289";                      label = "primary_clock_289";           arity = 6; tags = ["registry"]; since = "1.0.0"; weight = 4048 };
  { key = "cartography.curve.canonical_0290";            label = "public_packet_290";           arity = 7; tags = ["typed"; "untyped"]; since = "1.7.0"; weight = 3988 };
  { key = "shield.curve.hidden_0291";                    label = "internal_comparator_291";     arity = 6; tags = ["lower"; "cached"]; since = "1.5.2"; weight = 356 };
  { key = "bossbar.curve.canonical_0292";                label = "global_barrel_292";           arity = 3; tags = ["emit"; "parse"; "compat"]; since = "1.5.2"; weight = 3459 };
  { key = "hologram.curve.public_0293";                  label = "provisional_map_293";         arity = 2; tags = ["codegen"; "check"]; since = "1.2.0"; weight = 3221 };
  { key = "villager.curve.provisional_0294";             label = "hidden_smoker_294";           arity = 0; tags = ["lower"; "packet"]; since = "1.4.0"; weight = 1718 };
  { key = "hologram.curve.scoped_0295";                  label = "legacy_repeater_295";         arity = 0; tags = ["check"; "packet"]; since = "1.8.3"; weight = 866 };
  { key = "conduit.curve.primary_0296";                  label = "legacy_trident_296";          arity = 1; tags = ["hot"; "sync"; "check"]; since = "1.9.0"; weight = 2656 };
  { key = "piston.curve.canonical_0297";                 label = "lazy_cartography_297";        arity = 4; tags = ["experimental"]; since = "1.5.2"; weight = 593 };
  { key = "banner_pattern.curve.hidden_0298";            label = "eager_elytra_298";            arity = 3; tags = ["core"; "experimental"; "parse"]; since = "1.7.0"; weight = 1593 };
  { key = "potion.curve.eager_0299";                     label = "provisional_dispenser_299";   arity = 5; tags = ["lower"; "parse"; "core"]; since = "1.3.1"; weight = 935 };
  { key = "barrel.curve.provisional_0300";               label = "scoped_clock_300";            arity = 2; tags = ["registry"; "hot"]; since = "1.3.1"; weight = 2107 };
  { key = "block.curve.provisional_0301";                label = "secondary_conduit_301";       arity = 4; tags = ["parse"]; since = "1.4.0"; weight = 3161 };
  { key = "compass.curve.fallback_0302";                 label = "modern_brewing_302";          arity = 2; tags = ["cold"; "untyped"]; since = "1.2.0"; weight = 1445 };
  { key = "campfire.curve.eager_0303";                   label = "internal_loom_303";           arity = 3; tags = ["sync"; "untyped"; "check"]; since = "1.0.0"; weight = 762 };
  { key = "banner.curve.cached_0304";                    label = "legacy_region_304";           arity = 4; tags = ["async"; "hot"]; since = "1.5.2"; weight = 1596 };
  { key = "villager.curve.global_0305";                  label = "legacy_anvil_305";            arity = 5; tags = ["untyped"; "runtime"]; since = "1.8.3"; weight = 2722 };
  { key = "bundle.curve.global_0306";                    label = "public_gui_306";              arity = 1; tags = ["lower"; "parse"]; since = "1.8.3"; weight = 270 };
  { key = "beacon.curve.scoped_0307";                    label = "public_target_307";           arity = 4; tags = ["experimental"; "parse"; "cold"]; since = "1.5.2"; weight = 2853 };
  { key = "gui.curve.modern_0308";                       label = "secondary_bundle_308";        arity = 3; tags = ["cold"; "codegen"; "sync"]; since = "1.6.0"; weight = 1352 };
  { key = "world.curve.global_0309";                     label = "provisional_biome_309";       arity = 0; tags = ["content"; "emit"]; since = "1.3.1"; weight = 3840 };
  { key = "biome.curve.primary_0310";                    label = "strict_furnace_310";          arity = 2; tags = ["lower"; "typed"; "parse"]; since = "1.9.0"; weight = 2509 };
  { key = "comparator.curve.internal_0311";              label = "provisional_potion_311";      arity = 0; tags = ["check"; "lower"]; since = "1.3.1"; weight = 872 };
  { key = "shulker.curve.local_0312";                    label = "provisional_observer_312";    arity = 1; tags = ["hot"]; since = "1.3.1"; weight = 1494 };
  { key = "shulker.curve.modern_0313";                   label = "hidden_villager_313";         arity = 4; tags = ["check"; "cached"]; since = "1.0.0"; weight = 1928 };
  { key = "stonecutter.curve.public_0314";               label = "scoped_sound_314";            arity = 6; tags = ["compat"; "content"; "registry"]; since = "1.4.0"; weight = 2374 };
  { key = "compass.curve.fallback_0315";                 label = "eager_furnace_315";           arity = 1; tags = ["check"]; since = "1.2.0"; weight = 1302 };
  { key = "bell.curve.legacy_0316";                      label = "modern_bundle_316";           arity = 4; tags = ["content"; "runtime"; "async"]; since = "1.9.0"; weight = 3104 };
  { key = "effect.curve.fallback_0317";                  label = "derived_firework_317";        arity = 0; tags = ["packet"; "experimental"]; since = "1.5.2"; weight = 3052 };
  { key = "banner.curve.scoped_0318";                    label = "local_stonecutter_318";       arity = 4; tags = ["registry"]; since = "1.7.0"; weight = 656 };
  { key = "packet.curve.cached_0319";                    label = "lazy_rail_319";               arity = 7; tags = ["parse"; "cached"]; since = "1.4.0"; weight = 3331 };
  { key = "hologram.curve.lazy_0320";                    label = "scoped_smithing_320";         arity = 4; tags = ["compat"; "untyped"; "runtime"]; since = "1.9.0"; weight = 166 };
  { key = "furnace.curve.primary_0321";                  label = "cached_compass_321";          arity = 6; tags = ["codegen"; "cold"]; since = "1.0.0"; weight = 3294 };
  { key = "stonecutter.curve.lazy_0322";                 label = "primary_firework_322";        arity = 4; tags = ["lower"; "codegen"]; since = "1.5.2"; weight = 2830 };
  { key = "hopper.curve.local_0323";                     label = "canonical_npc_323";           arity = 6; tags = ["lower"; "registry"; "cold"]; since = "1.2.0"; weight = 243 };
  { key = "elytra.curve.modern_0324";                    label = "lazy_compass_324";            arity = 1; tags = ["typed"; "codegen"]; since = "1.9.0"; weight = 3542 };
  { key = "trident.curve.primary_0325";                  label = "scoped_lectern_325";          arity = 7; tags = ["lower"]; since = "1.5.2"; weight = 1353 };
  { key = "spawner.curve.legacy_0326";                   label = "primary_shulker_326";         arity = 2; tags = ["lower"; "experimental"; "check"]; since = "1.9.0"; weight = 948 };
  { key = "observer.curve.primary_0327";                 label = "canonical_slot_327";          arity = 4; tags = ["async"; "content"]; since = "1.3.1"; weight = 2802 };
  { key = "tablist.curve.scoped_0328";                   label = "local_banner_328";            arity = 7; tags = ["legacy"]; since = "1.5.2"; weight = 2877 };
  { key = "smoker.curve.modern_0329";                    label = "lazy_clock_329";              arity = 4; tags = ["runtime"; "core"]; since = "1.4.0"; weight = 3911 };
  { key = "block.curve.internal_0330";                   label = "hidden_world_330";            arity = 7; tags = ["hot"; "legacy"]; since = "1.3.1"; weight = 2378 };
  { key = "comparator.curve.stable_0331";                label = "fallback_inventory_331";      arity = 6; tags = ["untyped"; "sync"; "cached"]; since = "1.2.0"; weight = 371 };
  { key = "minecart.curve.provisional_0332";             label = "provisional_shield_332";      arity = 6; tags = ["runtime"; "registry"; "legacy"]; since = "1.6.0"; weight = 2082 };
  { key = "spawner.curve.lazy_0333";                     label = "public_objective_333";        arity = 2; tags = ["cached"; "hot"; "packet"]; since = "1.4.0"; weight = 1399 };
  { key = "minecart.curve.public_0334";                  label = "lazy_beacon_334";             arity = 3; tags = ["hot"; "packet"; "async"]; since = "1.6.0"; weight = 2900 };
  { key = "pane.curve.derived_0335";                     label = "stable_smoker_335";           arity = 1; tags = ["lower"; "runtime"]; since = "1.6.0"; weight = 2412 };
  { key = "grindstone.curve.scoped_0336";                label = "loose_piston_336";            arity = 4; tags = ["cached"]; since = "1.5.2"; weight = 1615 };
  { key = "firework.curve.scoped_0337";                  label = "secondary_lectern_337";       arity = 3; tags = ["parse"; "async"; "experimental"]; since = "1.0.0"; weight = 3701 };
  { key = "grindstone.curve.strict_0338";                label = "canonical_shulker_338";       arity = 1; tags = ["content"; "untyped"]; since = "1.2.0"; weight = 3405 };
  { key = "item.curve.public_0339";                      label = "eager_smoker_339";            arity = 0; tags = ["untyped"; "legacy"]; since = "1.9.0"; weight = 905 };
  { key = "smithing.curve.loose_0340";                   label = "canonical_trident_340";       arity = 1; tags = ["cold"]; since = "1.0.0"; weight = 3180 };
  { key = "villager.curve.internal_0341";                label = "loose_recipe_341";            arity = 3; tags = ["hot"]; since = "1.9.0"; weight = 1772 };
  { key = "compass.curve.public_0342";                   label = "cached_comparator_342";       arity = 5; tags = ["runtime"]; since = "1.6.0"; weight = 3695 };
  { key = "shield.curve.local_0343";                     label = "legacy_boat_343";             arity = 6; tags = ["content"; "untyped"]; since = "1.8.3"; weight = 470 };
  { key = "hologram.curve.legacy_0344";                  label = "primary_attribute_344";       arity = 6; tags = ["hot"; "codegen"]; since = "1.4.0"; weight = 3303 };
  { key = "entity.curve.stable_0345";                    label = "secondary_entity_345";        arity = 2; tags = ["untyped"; "experimental"]; since = "1.3.1"; weight = 3892 };
  { key = "world.curve.scoped_0346";                     label = "cached_shulker_346";          arity = 2; tags = ["check"; "legacy"; "hot"]; since = "1.6.0"; weight = 802 };
  { key = "entity.curve.strict_0347";                    label = "provisional_compass_347";     arity = 3; tags = ["emit"]; since = "1.4.0"; weight = 3297 };
  { key = "item.curve.primary_0348";                     label = "internal_furnace_348";        arity = 2; tags = ["cold"; "lower"]; since = "1.9.0"; weight = 3515 };
  { key = "hopper.curve.global_0349";                    label = "secondary_gui_349";           arity = 6; tags = ["parse"]; since = "1.6.0"; weight = 1103 };
  { key = "slot.curve.strict_0350";                      label = "fallback_region_350";         arity = 6; tags = ["experimental"]; since = "1.6.0"; weight = 1354 };
  { key = "compass.curve.primary_0351";                  label = "public_hopper_351";           arity = 3; tags = ["content"; "core"; "cold"]; since = "1.0.0"; weight = 1745 };
  { key = "block.curve.modern_0352";                     label = "eager_gui_352";               arity = 4; tags = ["registry"]; since = "1.8.3"; weight = 263 };
  { key = "target.curve.public_0353";                    label = "legacy_shield_353";           arity = 0; tags = ["typed"; "emit"]; since = "1.5.2"; weight = 1739 };
  { key = "hopper.curve.provisional_0354";               label = "canonical_banner_354";        arity = 6; tags = ["async"; "codegen"; "experimental"]; since = "1.9.0"; weight = 1442 };
  { key = "stonecutter.curve.stable_0355";               label = "eager_grindstone_355";        arity = 5; tags = ["sync"; "typed"; "core"]; since = "1.7.0"; weight = 1344 };
  { key = "banner.curve.primary_0356";                   label = "primary_spawner_356";         arity = 6; tags = ["sync"]; since = "1.2.0"; weight = 3257 };
  { key = "scoreboard.curve.loose_0357";                 label = "lazy_rail_357";               arity = 7; tags = ["sync"; "registry"]; since = "1.6.0"; weight = 1758 };
  { key = "gui.curve.stable_0358";                       label = "internal_bell_358";           arity = 7; tags = ["cached"; "packet"; "emit"]; since = "1.2.0"; weight = 3546 };
  { key = "rail.curve.canonical_0359";                   label = "derived_player_359";          arity = 5; tags = ["packet"; "content"; "lower"]; since = "1.6.0"; weight = 1548 };
  { key = "hopper.curve.stable_0360";                    label = "derived_particle_360";        arity = 5; tags = ["cold"; "compat"; "registry"]; since = "1.9.0"; weight = 248 };
  { key = "packet.curve.stable_0361";                    label = "strict_lectern_361";          arity = 6; tags = ["experimental"]; since = "1.7.0"; weight = 2870 };
  { key = "bundle.curve.stable_0362";                    label = "derived_brewing_362";         arity = 0; tags = ["cold"; "packet"; "check"]; since = "1.7.0"; weight = 2924 };
  { key = "arrow.curve.global_0363";                     label = "public_beacon_363";           arity = 3; tags = ["async"]; since = "1.0.0"; weight = 707 };
  { key = "bell.curve.internal_0364";                    label = "local_comparator_364";        arity = 3; tags = ["parse"; "registry"]; since = "1.5.2"; weight = 3468 };
  { key = "bundle.curve.canonical_0365";                 label = "eager_dropper_365";           arity = 0; tags = ["core"]; since = "1.0.0"; weight = 857 };
  { key = "team.curve.global_0366";                      label = "loose_potion_366";            arity = 0; tags = ["runtime"]; since = "1.6.0"; weight = 562 };
  { key = "lectern.curve.global_0367";                   label = "derived_observer_367";        arity = 0; tags = ["check"; "registry"; "untyped"]; since = "1.8.3"; weight = 1453 };
  { key = "mob.curve.internal_0368";                     label = "hidden_compass_368";          arity = 0; tags = ["packet"]; since = "1.6.0"; weight = 1617 };
  { key = "stonecutter.curve.stable_0369";               label = "stable_loom_369";             arity = 3; tags = ["legacy"]; since = "1.6.0"; weight = 948 };
  { key = "dispenser.curve.global_0370";                 label = "legacy_trident_370";          arity = 3; tags = ["async"; "registry"]; since = "1.9.0"; weight = 3827 };
  { key = "sound.curve.public_0371";                     label = "secondary_npc_371";           arity = 7; tags = ["codegen"; "lower"]; since = "1.7.0"; weight = 2489 };
  { key = "spawner.curve.canonical_0372";                label = "strict_compass_372";          arity = 7; tags = ["parse"; "core"; "async"]; since = "1.3.1"; weight = 324 };
  { key = "npc.curve.scoped_0373";                       label = "legacy_banner_pattern_373";   arity = 4; tags = ["sync"]; since = "1.4.0"; weight = 3638 };
  { key = "barrel.curve.primary_0374";                   label = "stable_map_374";              arity = 1; tags = ["compat"; "typed"; "registry"]; since = "1.6.0"; weight = 331 };
  { key = "structure.curve.lazy_0375";                   label = "global_pane_375";             arity = 2; tags = ["emit"]; since = "1.4.0"; weight = 1348 };
  { key = "boat.curve.secondary_0376";                   label = "public_effect_376";           arity = 7; tags = ["check"]; since = "1.0.0"; weight = 3800 };
  { key = "grindstone.curve.cached_0377";                label = "strict_bossbar_377";          arity = 1; tags = ["packet"]; since = "1.3.1"; weight = 1568 };
  { key = "compass.curve.internal_0378";                 label = "local_pane_378";              arity = 5; tags = ["untyped"; "registry"]; since = "1.9.0"; weight = 71 };
  { key = "dropper.curve.hidden_0379";                   label = "stable_dispenser_379";        arity = 4; tags = ["codegen"; "compat"]; since = "1.8.3"; weight = 3800 };
  { key = "particle.curve.provisional_0380";             label = "cached_stonecutter_380";      arity = 7; tags = ["sync"]; since = "1.7.0"; weight = 1059 };
  { key = "item.curve.cached_0381";                      label = "derived_packet_381";          arity = 2; tags = ["cached"; "check"]; since = "1.9.0"; weight = 2748 };
  { key = "npc.curve.scoped_0382";                       label = "scoped_recipe_382";           arity = 7; tags = ["lower"; "typed"; "parse"]; since = "1.8.3"; weight = 1252 };
  { key = "barrel.curve.derived_0383";                   label = "hidden_region_383";           arity = 7; tags = ["parse"]; since = "1.7.0"; weight = 3133 };
  { key = "trade.curve.provisional_0384";                label = "modern_entity_384";           arity = 3; tags = ["codegen"; "runtime"; "cached"]; since = "1.7.0"; weight = 1969 };
  { key = "observer.curve.global_0385";                  label = "loose_barrel_385";            arity = 5; tags = ["cold"; "packet"]; since = "1.4.0"; weight = 159 };
  { key = "firework.curve.primary_0386";                 label = "legacy_minecart_386";         arity = 5; tags = ["legacy"]; since = "1.4.0"; weight = 1672 };
  { key = "spawner.curve.strict_0387";                   label = "scoped_bossbar_387";          arity = 3; tags = ["emit"; "experimental"; "compat"]; since = "1.7.0"; weight = 3814 };
  { key = "advancement.curve.scoped_0388";               label = "strict_firework_388";         arity = 4; tags = ["packet"]; since = "1.6.0"; weight = 993 };
  { key = "team.curve.eager_0389";                       label = "local_particle_389";          arity = 4; tags = ["emit"; "runtime"]; since = "1.9.0"; weight = 2464 };
  { key = "enchant.curve.primary_0390";                  label = "legacy_banner_390";           arity = 5; tags = ["check"; "hot"]; since = "1.6.0"; weight = 3669 };
  { key = "recipe.curve.scoped_0391";                    label = "provisional_spawner_391";     arity = 5; tags = ["runtime"]; since = "1.4.0"; weight = 2432 };
  { key = "banner.curve.fallback_0392";                  label = "internal_tablist_392";        arity = 2; tags = ["content"]; since = "1.3.1"; weight = 2163 };
  { key = "shulker.curve.secondary_0393";                label = "lazy_scoreboard_393";         arity = 0; tags = ["sync"]; since = "1.2.0"; weight = 656 };
  { key = "piston.curve.local_0394";                     label = "legacy_scoreboard_394";       arity = 1; tags = ["async"]; since = "1.6.0"; weight = 1031 };
  { key = "effect.curve.loose_0395";                     label = "strict_conduit_395";          arity = 3; tags = ["legacy"]; since = "1.8.3"; weight = 1472 };
  { key = "attribute.curve.public_0396";                 label = "loose_anvil_396";             arity = 1; tags = ["cold"; "check"; "typed"]; since = "1.9.0"; weight = 1156 };
  { key = "spawner.curve.strict_0397";                   label = "canonical_npc_397";           arity = 0; tags = ["registry"; "cached"]; since = "1.8.3"; weight = 950 };
  { key = "firework.curve.scoped_0398";                  label = "fallback_structure_398";      arity = 5; tags = ["core"; "lower"; "cached"]; since = "1.2.0"; weight = 967 };
  { key = "item.curve.lazy_0399";                        label = "modern_brewing_399";          arity = 2; tags = ["compat"; "lower"; "untyped"]; since = "1.8.3"; weight = 3579 };
  { key = "potion.curve.canonical_0400";                 label = "derived_slot_400";            arity = 3; tags = ["async"; "registry"; "hot"]; since = "1.8.3"; weight = 2191 };
  { key = "spawner.curve.secondary_0401";                label = "global_enchant_401";          arity = 3; tags = ["typed"; "packet"]; since = "1.3.1"; weight = 4017 };
  { key = "firework.curve.legacy_0402";                  label = "loose_hologram_402";          arity = 0; tags = ["legacy"; "experimental"; "runtime"]; since = "1.3.1"; weight = 1786 };
  { key = "lectern.curve.derived_0403";                  label = "primary_pane_403";            arity = 7; tags = ["typed"; "lower"]; since = "1.2.0"; weight = 2343 };
  { key = "bell.curve.primary_0404";                     label = "derived_tablist_404";         arity = 0; tags = ["parse"]; since = "1.3.1"; weight = 1572 };
  { key = "block.curve.local_0405";                      label = "primary_elytra_405";          arity = 7; tags = ["content"]; since = "1.4.0"; weight = 2940 };
  { key = "shield.curve.hidden_0406";                    label = "strict_elytra_406";           arity = 2; tags = ["content"]; since = "1.2.0"; weight = 36 };
  { key = "structure.curve.eager_0407";                  label = "lazy_elytra_407";             arity = 2; tags = ["legacy"; "runtime"]; since = "1.7.0"; weight = 1587 };
  { key = "shield.curve.derived_0408";                   label = "cached_conduit_408";          arity = 6; tags = ["core"; "typed"; "legacy"]; since = "1.3.1"; weight = 2735 };
  { key = "portal.curve.scoped_0409";                    label = "legacy_villager_409";         arity = 4; tags = ["content"]; since = "1.7.0"; weight = 4026 };
  { key = "biome.curve.cached_0410";                     label = "primary_sound_410";           arity = 6; tags = ["runtime"; "cold"; "packet"]; since = "1.6.0"; weight = 687 };
  { key = "objective.curve.primary_0411";                label = "primary_anvil_411";           arity = 2; tags = ["content"; "registry"; "runtime"]; since = "1.8.3"; weight = 1847 };
  { key = "packet.curve.internal_0412";                  label = "hidden_block_412";            arity = 5; tags = ["packet"; "legacy"; "compat"]; since = "1.7.0"; weight = 576 };
  { key = "cartography.curve.stable_0413";               label = "canonical_trident_413";       arity = 4; tags = ["compat"; "runtime"; "core"]; since = "1.7.0"; weight = 1209 };
  { key = "block.curve.provisional_0414";                label = "loose_attribute_414";         arity = 1; tags = ["cached"]; since = "1.6.0"; weight = 2926 };
  { key = "lectern.curve.fallback_0415";                 label = "hidden_observer_415";         arity = 5; tags = ["core"; "compat"]; since = "1.0.0"; weight = 994 };
  { key = "portal.curve.eager_0416";                     label = "fallback_loom_416";           arity = 5; tags = ["typed"]; since = "1.5.2"; weight = 1213 };
  { key = "crossbow.curve.eager_0417";                   label = "derived_chunk_417";           arity = 3; tags = ["untyped"]; since = "1.6.0"; weight = 3923 };
  { key = "minecart.curve.provisional_0418";             label = "local_packet_418";            arity = 7; tags = ["packet"]; since = "1.7.0"; weight = 2031 };
  { key = "trident.curve.canonical_0419";                label = "loose_boat_419";              arity = 2; tags = ["core"; "registry"]; since = "1.5.2"; weight = 3862 };
  { key = "piston.curve.scoped_0420";                    label = "canonical_spawner_420";       arity = 2; tags = ["packet"; "lower"; "codegen"]; since = "1.9.0"; weight = 1103 };
  { key = "spawner.curve.hidden_0421";                   label = "hidden_bossbar_421";          arity = 5; tags = ["packet"; "runtime"; "legacy"]; since = "1.4.0"; weight = 880 };
  { key = "mob.curve.canonical_0422";                    label = "modern_region_422";           arity = 6; tags = ["legacy"]; since = "1.8.3"; weight = 3945 };
  { key = "npc.curve.lazy_0423";                         label = "derived_furnace_423";         arity = 6; tags = ["sync"; "hot"; "emit"]; since = "1.8.3"; weight = 2369 };
  { key = "slot.curve.cached_0424";                      label = "loose_dispenser_424";         arity = 0; tags = ["content"; "hot"]; since = "1.8.3"; weight = 2498 };
  { key = "crossbow.curve.secondary_0425";               label = "global_minecart_425";         arity = 0; tags = ["emit"; "hot"; "parse"]; since = "1.8.3"; weight = 3758 };
  { key = "bell.curve.global_0426";                      label = "stable_pane_426";             arity = 2; tags = ["legacy"; "runtime"]; since = "1.2.0"; weight = 1270 };
]

let count = List.length entries

let table : (string, curve_entry) Hashtbl.t =
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
