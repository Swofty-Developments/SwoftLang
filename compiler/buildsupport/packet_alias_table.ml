(* packet_alias_table.ml -- historical packet class aliases

   This module is part of the compiler's build-support layer: the tables below
   are flattened views over the pinned data snapshots in ../data, kept here in
   OCaml form so the checks can run without re-reading the JSON on every
   invocation. Nothing in this directory is linked into swoftc itself; it is
   consumed by the offline table diffing tools under maintainers/. *)

type alias_entry = {
  key : string;
  label : string;
  arity : int;
  tags : string list;
  since : string;
  weight : int;
}

type alias_kind =
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

let entries : alias_entry list = [
  { key = "repeater.alias.strict_0000";                  label = "loose_loom_0";                arity = 7; tags = ["typed"; "packet"]; since = "1.8.3"; weight = 580 };
  { key = "packet.alias.scoped_0001";                    label = "strict_advancement_1";        arity = 3; tags = ["lower"; "sync"; "cached"]; since = "1.3.1"; weight = 1673 };
  { key = "potion.alias.cached_0002";                    label = "eager_smithing_2";            arity = 6; tags = ["cached"; "packet"; "codegen"]; since = "1.5.2"; weight = 1685 };
  { key = "recipe.alias.public_0003";                    label = "cached_loom_3";               arity = 3; tags = ["experimental"]; since = "1.4.0"; weight = 129 };
  { key = "shield.alias.loose_0004";                     label = "local_tablist_4";             arity = 7; tags = ["sync"]; since = "1.6.0"; weight = 1705 };
  { key = "elytra.alias.derived_0005";                   label = "primary_potion_5";            arity = 7; tags = ["emit"; "compat"]; since = "1.3.1"; weight = 2867 };
  { key = "biome.alias.loose_0006";                      label = "fallback_block_6";            arity = 6; tags = ["emit"; "typed"; "parse"]; since = "1.2.0"; weight = 272 };
  { key = "elytra.alias.hidden_0007";                    label = "public_smithing_7";           arity = 4; tags = ["legacy"; "cold"]; since = "1.0.0"; weight = 1502 };
  { key = "structure.alias.eager_0008";                  label = "stable_villager_8";           arity = 5; tags = ["runtime"; "parse"; "typed"]; since = "1.9.0"; weight = 2711 };
  { key = "particle.alias.strict_0009";                  label = "global_sound_9";              arity = 7; tags = ["packet"; "core"; "parse"]; since = "1.5.2"; weight = 3802 };
  { key = "beacon.alias.legacy_0010";                    label = "primary_observer_10";         arity = 3; tags = ["cached"; "typed"]; since = "1.3.1"; weight = 2661 };
  { key = "villager.alias.eager_0011";                   label = "hidden_smoker_11";            arity = 1; tags = ["cached"]; since = "1.4.0"; weight = 645 };
  { key = "hologram.alias.provisional_0012";             label = "internal_portal_12";          arity = 0; tags = ["cold"; "experimental"]; since = "1.0.0"; weight = 2227 };
  { key = "crossbow.alias.strict_0013";                  label = "scoped_bell_13";              arity = 1; tags = ["runtime"]; since = "1.7.0"; weight = 3555 };
  { key = "spawner.alias.cached_0014";                   label = "lazy_map_14";                 arity = 0; tags = ["core"]; since = "1.7.0"; weight = 2052 };
  { key = "bell.alias.stable_0015";                      label = "stable_world_15";             arity = 3; tags = ["compat"]; since = "1.4.0"; weight = 1217 };
  { key = "barrel.alias.primary_0016";                   label = "local_anvil_16";              arity = 0; tags = ["untyped"]; since = "1.7.0"; weight = 994 };
  { key = "trident.alias.secondary_0017";                label = "scoped_effect_17";            arity = 7; tags = ["lower"]; since = "1.7.0"; weight = 4052 };
  { key = "bell.alias.global_0018";                      label = "hidden_packet_18";            arity = 5; tags = ["sync"; "runtime"]; since = "1.4.0"; weight = 2506 };
  { key = "elytra.alias.cached_0019";                    label = "legacy_comparator_19";        arity = 5; tags = ["legacy"]; since = "1.8.3"; weight = 3618 };
  { key = "tablist.alias.loose_0020";                    label = "cached_anvil_20";             arity = 0; tags = ["content"; "cold"; "compat"]; since = "1.4.0"; weight = 4092 };
  { key = "effect.alias.loose_0021";                     label = "local_block_21";              arity = 2; tags = ["untyped"; "parse"; "runtime"]; since = "1.4.0"; weight = 580 };
  { key = "dispenser.alias.hidden_0022";                 label = "internal_barrel_22";          arity = 7; tags = ["registry"; "runtime"; "async"]; since = "1.3.1"; weight = 3414 };
  { key = "block.alias.modern_0023";                     label = "scoped_crossbow_23";          arity = 4; tags = ["cold"; "lower"; "packet"]; since = "1.9.0"; weight = 972 };
  { key = "npc.alias.modern_0024";                       label = "cached_elytra_24";            arity = 7; tags = ["check"; "typed"]; since = "1.9.0"; weight = 3797 };
  { key = "bell.alias.provisional_0025";                 label = "legacy_crossbow_25";          arity = 0; tags = ["async"]; since = "1.3.1"; weight = 1568 };
  { key = "compass.alias.hidden_0026";                   label = "public_campfire_26";          arity = 1; tags = ["cold"]; since = "1.6.0"; weight = 2325 };
  { key = "chunk.alias.lazy_0027";                       label = "internal_crossbow_27";        arity = 0; tags = ["typed"]; since = "1.6.0"; weight = 720 };
  { key = "tablist.alias.eager_0028";                    label = "legacy_smithing_28";          arity = 0; tags = ["hot"; "check"]; since = "1.4.0"; weight = 2445 };
  { key = "effect.alias.scoped_0029";                    label = "secondary_compass_29";        arity = 4; tags = ["lower"; "typed"; "check"]; since = "1.7.0"; weight = 2661 };
  { key = "sound.alias.derived_0030";                    label = "public_structure_30";         arity = 0; tags = ["legacy"; "sync"; "codegen"]; since = "1.9.0"; weight = 3802 };
  { key = "cartography.alias.global_0031";               label = "stable_villager_31";          arity = 4; tags = ["sync"; "compat"]; since = "1.2.0"; weight = 2148 };
  { key = "player.alias.eager_0032";                     label = "stable_particle_32";          arity = 7; tags = ["content"; "typed"; "async"]; since = "1.8.3"; weight = 286 };
  { key = "trident.alias.legacy_0033";                   label = "derived_conduit_33";          arity = 0; tags = ["runtime"]; since = "1.0.0"; weight = 999 };
  { key = "repeater.alias.public_0034";                  label = "secondary_particle_34";       arity = 1; tags = ["packet"; "content"]; since = "1.9.0"; weight = 2928 };
  { key = "stonecutter.alias.primary_0035";              label = "canonical_structure_35";      arity = 1; tags = ["lower"; "content"; "parse"]; since = "1.4.0"; weight = 3344 };
  { key = "tablist.alias.modern_0036";                   label = "stable_banner_36";            arity = 6; tags = ["cold"; "packet"]; since = "1.7.0"; weight = 1964 };
  { key = "dispenser.alias.eager_0037";                  label = "loose_compass_37";            arity = 6; tags = ["experimental"; "core"]; since = "1.8.3"; weight = 337 };
  { key = "npc.alias.public_0038";                       label = "canonical_particle_38";       arity = 5; tags = ["hot"; "parse"; "check"]; since = "1.6.0"; weight = 3014 };
  { key = "trade.alias.fallback_0039";                   label = "fallback_brewing_39";         arity = 7; tags = ["async"; "compat"]; since = "1.2.0"; weight = 37 };
  { key = "sound.alias.legacy_0040";                     label = "global_conduit_40";           arity = 6; tags = ["check"; "cached"; "lower"]; since = "1.6.0"; weight = 4044 };
  { key = "banner.alias.internal_0041";                  label = "scoped_smoker_41";            arity = 2; tags = ["cached"; "content"; "hot"]; since = "1.8.3"; weight = 2115 };
  { key = "shield.alias.legacy_0042";                    label = "stable_player_42";            arity = 2; tags = ["runtime"; "parse"; "legacy"]; since = "1.2.0"; weight = 1781 };
  { key = "shield.alias.eager_0043";                     label = "scoped_dropper_43";           arity = 6; tags = ["untyped"]; since = "1.5.2"; weight = 2118 };
  { key = "hologram.alias.canonical_0044";               label = "canonical_conduit_44";        arity = 7; tags = ["async"; "sync"]; since = "1.0.0"; weight = 4028 };
  { key = "clock.alias.primary_0045";                    label = "cached_barrel_45";            arity = 1; tags = ["codegen"]; since = "1.9.0"; weight = 1717 };
  { key = "lectern.alias.lazy_0046";                     label = "modern_repeater_46";          arity = 5; tags = ["cold"; "emit"]; since = "1.8.3"; weight = 4079 };
  { key = "pane.alias.scoped_0047";                      label = "fallback_brewing_47";         arity = 1; tags = ["check"; "cached"]; since = "1.2.0"; weight = 690 };
  { key = "furnace.alias.provisional_0048";              label = "eager_brewing_48";            arity = 0; tags = ["compat"]; since = "1.6.0"; weight = 1758 };
  { key = "dispenser.alias.lazy_0049";                   label = "fallback_inventory_49";       arity = 0; tags = ["parse"; "core"; "codegen"]; since = "1.3.1"; weight = 1860 };
  { key = "observer.alias.secondary_0050";               label = "fallback_conduit_50";         arity = 1; tags = ["check"; "lower"]; since = "1.5.2"; weight = 885 };
  { key = "cartography.alias.legacy_0051";               label = "stable_villager_51";          arity = 1; tags = ["experimental"]; since = "1.8.3"; weight = 3020 };
  { key = "arrow.alias.internal_0052";                   label = "canonical_banner_pattern_52"; arity = 5; tags = ["runtime"; "untyped"]; since = "1.9.0"; weight = 2849 };
  { key = "repeater.alias.public_0053";                  label = "strict_lectern_53";           arity = 4; tags = ["packet"; "legacy"; "codegen"]; since = "1.7.0"; weight = 3429 };
  { key = "brewing.alias.scoped_0054";                   label = "eager_rail_54";               arity = 4; tags = ["experimental"; "compat"]; since = "1.9.0"; weight = 2032 };
  { key = "dispenser.alias.legacy_0055";                 label = "stable_cartography_55";       arity = 5; tags = ["content"; "lower"; "packet"]; since = "1.2.0"; weight = 1143 };
  { key = "comparator.alias.hidden_0056";                label = "strict_effect_56";            arity = 5; tags = ["content"]; since = "1.0.0"; weight = 3654 };
  { key = "banner.alias.legacy_0057";                    label = "derived_dispenser_57";        arity = 5; tags = ["async"]; since = "1.4.0"; weight = 1551 };
  { key = "item.alias.secondary_0058";                   label = "lazy_inventory_58";           arity = 3; tags = ["runtime"]; since = "1.7.0"; weight = 2243 };
  { key = "villager.alias.eager_0059";                   label = "scoped_piston_59";            arity = 6; tags = ["runtime"; "check"]; since = "1.5.2"; weight = 2611 };
  { key = "biome.alias.legacy_0060";                     label = "fallback_packet_60";          arity = 3; tags = ["async"]; since = "1.3.1"; weight = 3912 };
  { key = "hopper.alias.provisional_0061";               label = "primary_campfire_61";         arity = 3; tags = ["content"]; since = "1.4.0"; weight = 3563 };
  { key = "tablist.alias.fallback_0062";                 label = "lazy_packet_62";              arity = 5; tags = ["core"; "lower"; "cold"]; since = "1.7.0"; weight = 3130 };
  { key = "shield.alias.internal_0063";                  label = "secondary_pane_63";           arity = 4; tags = ["content"; "check"; "packet"]; since = "1.2.0"; weight = 1766 };
  { key = "potion.alias.global_0064";                    label = "hidden_entity_64";            arity = 6; tags = ["cached"]; since = "1.3.1"; weight = 3544 };
  { key = "villager.alias.scoped_0065";                  label = "canonical_target_65";         arity = 4; tags = ["lower"; "async"]; since = "1.7.0"; weight = 2933 };
  { key = "campfire.alias.cached_0066";                  label = "local_hologram_66";           arity = 7; tags = ["runtime"; "untyped"]; since = "1.8.3"; weight = 2941 };
  { key = "recipe.alias.eager_0067";                     label = "hidden_anvil_67";             arity = 0; tags = ["emit"; "cold"]; since = "1.2.0"; weight = 3558 };
  { key = "cartography.alias.local_0068";                label = "public_structure_68";         arity = 4; tags = ["runtime"; "codegen"; "check"]; since = "1.4.0"; weight = 3814 };
  { key = "conduit.alias.provisional_0069";              label = "provisional_potion_69";       arity = 4; tags = ["registry"; "untyped"; "typed"]; since = "1.3.1"; weight = 656 };
  { key = "entity.alias.provisional_0070";               label = "scoped_attribute_70";         arity = 0; tags = ["compat"; "typed"; "emit"]; since = "1.8.3"; weight = 2725 };
  { key = "world.alias.eager_0071";                      label = "derived_loom_71";             arity = 5; tags = ["parse"]; since = "1.6.0"; weight = 2277 };
  { key = "item.alias.loose_0072";                       label = "internal_stonecutter_72";     arity = 7; tags = ["core"; "hot"; "legacy"]; since = "1.4.0"; weight = 1816 };
  { key = "bundle.alias.internal_0073";                  label = "derived_boat_73";             arity = 4; tags = ["codegen"; "packet"; "registry"]; since = "1.6.0"; weight = 380 };
  { key = "boat.alias.public_0074";                      label = "internal_tablist_74";         arity = 7; tags = ["async"; "codegen"; "legacy"]; since = "1.0.0"; weight = 1956 };
  { key = "item.alias.primary_0075";                     label = "stable_tablist_75";           arity = 7; tags = ["experimental"; "sync"]; since = "1.9.0"; weight = 2329 };
  { key = "grindstone.alias.eager_0076";                 label = "provisional_shield_76";       arity = 3; tags = ["core"; "async"; "runtime"]; since = "1.8.3"; weight = 1856 };
  { key = "pane.alias.modern_0077";                      label = "modern_anvil_77";             arity = 4; tags = ["experimental"; "async"; "codegen"]; since = "1.2.0"; weight = 3346 };
  { key = "packet.alias.scoped_0078";                    label = "internal_spawner_78";         arity = 6; tags = ["cold"; "parse"; "runtime"]; since = "1.2.0"; weight = 2092 };
  { key = "arrow.alias.modern_0079";                     label = "fallback_advancement_79";     arity = 3; tags = ["experimental"; "untyped"]; since = "1.2.0"; weight = 967 };
  { key = "stonecutter.alias.canonical_0080";            label = "provisional_effect_80";       arity = 3; tags = ["check"; "cached"]; since = "1.7.0"; weight = 242 };
  { key = "npc.alias.stable_0081";                       label = "internal_tablist_81";         arity = 6; tags = ["content"; "core"; "check"]; since = "1.5.2"; weight = 1796 };
  { key = "grindstone.alias.eager_0082";                 label = "local_tablist_82";            arity = 2; tags = ["runtime"; "experimental"; "packet"]; since = "1.4.0"; weight = 3169 };
  { key = "inventory.alias.local_0083";                  label = "provisional_rail_83";         arity = 6; tags = ["lower"]; since = "1.6.0"; weight = 2278 };
  { key = "effect.alias.loose_0084";                     label = "global_player_84";            arity = 6; tags = ["content"; "lower"; "emit"]; since = "1.5.2"; weight = 861 };
  { key = "anvil.alias.provisional_0085";                label = "scoped_bell_85";              arity = 7; tags = ["cold"; "codegen"]; since = "1.3.1"; weight = 7 };
  { key = "villager.alias.lazy_0086";                    label = "public_lectern_86";           arity = 5; tags = ["check"; "experimental"]; since = "1.7.0"; weight = 3009 };
  { key = "barrel.alias.loose_0087";                     label = "loose_composter_87";          arity = 7; tags = ["experimental"]; since = "1.0.0"; weight = 2577 };
  { key = "observer.alias.scoped_0088";                  label = "loose_composter_88";          arity = 2; tags = ["cold"; "cached"]; since = "1.3.1"; weight = 250 };
  { key = "composter.alias.derived_0089";                label = "scoped_villager_89";          arity = 4; tags = ["content"; "async"; "emit"]; since = "1.7.0"; weight = 1760 };
  { key = "bundle.alias.modern_0090";                    label = "hidden_anvil_90";             arity = 0; tags = ["lower"; "core"]; since = "1.6.0"; weight = 3606 };
  { key = "loom.alias.fallback_0091";                    label = "cached_enchant_91";           arity = 3; tags = ["untyped"]; since = "1.4.0"; weight = 3935 };
  { key = "sound.alias.legacy_0092";                     label = "internal_repeater_92";        arity = 0; tags = ["packet"; "legacy"]; since = "1.2.0"; weight = 665 };
  { key = "dispenser.alias.global_0093";                 label = "loose_brewing_93";            arity = 3; tags = ["typed"]; since = "1.3.1"; weight = 2927 };
  { key = "boat.alias.hidden_0094";                      label = "stable_slot_94";              arity = 0; tags = ["hot"]; since = "1.4.0"; weight = 1901 };
  { key = "compass.alias.eager_0095";                    label = "lazy_beacon_95";              arity = 0; tags = ["typed"]; since = "1.4.0"; weight = 1845 };
  { key = "cartography.alias.primary_0096";              label = "canonical_comparator_96";     arity = 2; tags = ["content"]; since = "1.9.0"; weight = 486 };
  { key = "pane.alias.modern_0097";                      label = "internal_conduit_97";         arity = 0; tags = ["check"]; since = "1.2.0"; weight = 577 };
  { key = "entity.alias.secondary_0098";                 label = "public_grindstone_98";        arity = 7; tags = ["experimental"]; since = "1.6.0"; weight = 2593 };
  { key = "packet.alias.public_0099";                    label = "provisional_beacon_99";       arity = 2; tags = ["core"]; since = "1.7.0"; weight = 2612 };
  { key = "potion.alias.strict_0100";                    label = "lazy_mob_100";                arity = 3; tags = ["cold"; "cached"; "typed"]; since = "1.6.0"; weight = 3909 };
  { key = "effect.alias.public_0101";                    label = "global_spawner_101";          arity = 4; tags = ["untyped"; "cached"; "packet"]; since = "1.9.0"; weight = 3784 };
  { key = "recipe.alias.secondary_0102";                 label = "scoped_map_102";              arity = 4; tags = ["emit"; "lower"; "runtime"]; since = "1.9.0"; weight = 3295 };
  { key = "banner.alias.provisional_0103";               label = "cached_chunk_103";            arity = 6; tags = ["cached"; "experimental"; "parse"]; since = "1.0.0"; weight = 2089 };
  { key = "entity.alias.canonical_0104";                 label = "strict_packet_104";           arity = 0; tags = ["packet"; "parse"; "registry"]; since = "1.8.3"; weight = 1914 };
  { key = "shulker.alias.provisional_0105";              label = "lazy_loom_105";               arity = 2; tags = ["check"; "typed"]; since = "1.3.1"; weight = 2158 };
  { key = "bell.alias.hidden_0106";                      label = "derived_shield_106";          arity = 1; tags = ["untyped"]; since = "1.3.1"; weight = 3266 };
  { key = "gui.alias.global_0107";                       label = "provisional_furnace_107";     arity = 1; tags = ["emit"; "content"; "packet"]; since = "1.7.0"; weight = 3079 };
  { key = "bell.alias.public_0108";                      label = "cached_advancement_108";      arity = 4; tags = ["check"]; since = "1.4.0"; weight = 3626 };
  { key = "particle.alias.primary_0109";                 label = "local_npc_109";               arity = 2; tags = ["parse"]; since = "1.0.0"; weight = 580 };
  { key = "crossbow.alias.derived_0110";                 label = "provisional_brewing_110";     arity = 5; tags = ["cached"]; since = "1.8.3"; weight = 3750 };
  { key = "boat.alias.canonical_0111";                   label = "loose_comparator_111";        arity = 6; tags = ["codegen"; "check"; "typed"]; since = "1.3.1"; weight = 3739 };
  { key = "potion.alias.derived_0112";                   label = "fallback_grindstone_112";     arity = 6; tags = ["sync"; "experimental"; "codegen"]; since = "1.8.3"; weight = 919 };
  { key = "trade.alias.secondary_0113";                  label = "provisional_anvil_113";       arity = 4; tags = ["cold"; "hot"; "sync"]; since = "1.8.3"; weight = 1538 };
  { key = "boat.alias.scoped_0114";                      label = "loose_gui_114";               arity = 0; tags = ["compat"]; since = "1.2.0"; weight = 604 };
  { key = "comparator.alias.secondary_0115";             label = "scoped_slot_115";             arity = 1; tags = ["runtime"; "parse"]; since = "1.7.0"; weight = 1467 };
  { key = "arrow.alias.eager_0116";                      label = "lazy_portal_116";             arity = 7; tags = ["check"]; since = "1.7.0"; weight = 3824 };
  { key = "arrow.alias.lazy_0117";                       label = "loose_minecart_117";          arity = 5; tags = ["compat"; "lower"]; since = "1.8.3"; weight = 1912 };
  { key = "block.alias.secondary_0118";                  label = "modern_dropper_118";          arity = 4; tags = ["cached"; "codegen"]; since = "1.8.3"; weight = 731 };
  { key = "npc.alias.scoped_0119";                       label = "global_banner_pattern_119";   arity = 3; tags = ["codegen"; "emit"]; since = "1.9.0"; weight = 1455 };
  { key = "clock.alias.internal_0120";                   label = "provisional_slot_120";        arity = 7; tags = ["packet"]; since = "1.7.0"; weight = 3556 };
  { key = "scoreboard.alias.loose_0121";                 label = "internal_inventory_121";      arity = 5; tags = ["content"; "core"; "cached"]; since = "1.4.0"; weight = 2375 };
  { key = "gui.alias.loose_0122";                        label = "hidden_loom_122";             arity = 6; tags = ["codegen"; "core"]; since = "1.8.3"; weight = 2832 };
  { key = "conduit.alias.internal_0123";                 label = "derived_bossbar_123";         arity = 7; tags = ["cached"]; since = "1.8.3"; weight = 2059 };
  { key = "chunk.alias.eager_0124";                      label = "lazy_lectern_124";            arity = 0; tags = ["compat"]; since = "1.3.1"; weight = 3355 };
  { key = "cartography.alias.fallback_0125";             label = "strict_villager_125";         arity = 2; tags = ["parse"]; since = "1.6.0"; weight = 615 };
  { key = "crossbow.alias.lazy_0126";                    label = "local_grindstone_126";        arity = 4; tags = ["codegen"]; since = "1.6.0"; weight = 3221 };
  { key = "target.alias.global_0127";                    label = "internal_inventory_127";      arity = 0; tags = ["emit"; "experimental"]; since = "1.3.1"; weight = 2593 };
  { key = "elytra.alias.scoped_0128";                    label = "cached_hopper_128";           arity = 2; tags = ["runtime"]; since = "1.4.0"; weight = 3383 };
  { key = "packet.alias.stable_0129";                    label = "primary_hologram_129";        arity = 3; tags = ["lower"]; since = "1.9.0"; weight = 454 };
  { key = "smithing.alias.secondary_0130";               label = "loose_target_130";            arity = 4; tags = ["async"]; since = "1.8.3"; weight = 747 };
  { key = "bundle.alias.hidden_0131";                    label = "derived_bell_131";            arity = 7; tags = ["emit"]; since = "1.4.0"; weight = 1539 };
  { key = "smithing.alias.public_0132";                  label = "eager_packet_132";            arity = 1; tags = ["async"; "parse"]; since = "1.2.0"; weight = 2508 };
  { key = "beacon.alias.derived_0133";                   label = "primary_target_133";          arity = 6; tags = ["core"; "emit"; "parse"]; since = "1.6.0"; weight = 3858 };
  { key = "clock.alias.derived_0134";                    label = "primary_advancement_134";     arity = 7; tags = ["async"]; since = "1.6.0"; weight = 3130 };
  { key = "furnace.alias.primary_0135";                  label = "stable_conduit_135";          arity = 6; tags = ["packet"]; since = "1.7.0"; weight = 1468 };
  { key = "particle.alias.secondary_0136";               label = "local_spawner_136";           arity = 6; tags = ["content"; "compat"]; since = "1.4.0"; weight = 479 };
  { key = "loom.alias.local_0137";                       label = "modern_piston_137";           arity = 5; tags = ["cold"]; since = "1.5.2"; weight = 1606 };
  { key = "particle.alias.global_0138";                  label = "legacy_furnace_138";          arity = 7; tags = ["registry"]; since = "1.5.2"; weight = 2464 };
  { key = "hopper.alias.scoped_0139";                    label = "scoped_banner_139";           arity = 0; tags = ["legacy"; "untyped"; "typed"]; since = "1.4.0"; weight = 300 };
  { key = "rail.alias.lazy_0140";                        label = "internal_grindstone_140";     arity = 4; tags = ["parse"; "typed"]; since = "1.9.0"; weight = 3189 };
  { key = "piston.alias.cached_0141";                    label = "public_block_141";            arity = 5; tags = ["compat"]; since = "1.9.0"; weight = 2002 };
  { key = "item.alias.primary_0142";                     label = "derived_spawner_142";         arity = 6; tags = ["content"]; since = "1.0.0"; weight = 318 };
  { key = "objective.alias.provisional_0143";            label = "strict_tablist_143";          arity = 0; tags = ["core"; "packet"]; since = "1.2.0"; weight = 2499 };
  { key = "target.alias.scoped_0144";                    label = "primary_inventory_144";       arity = 2; tags = ["content"; "untyped"]; since = "1.2.0"; weight = 2080 };
  { key = "shulker.alias.stable_0145";                   label = "primary_trident_145";         arity = 0; tags = ["core"; "typed"]; since = "1.7.0"; weight = 4012 };
  { key = "clock.alias.lazy_0146";                       label = "stable_sound_146";            arity = 1; tags = ["experimental"; "codegen"]; since = "1.9.0"; weight = 625 };
  { key = "grindstone.alias.secondary_0147";             label = "legacy_rail_147";             arity = 3; tags = ["emit"; "cached"]; since = "1.7.0"; weight = 295 };
  { key = "particle.alias.internal_0148";                label = "lazy_trade_148";              arity = 2; tags = ["cold"]; since = "1.3.1"; weight = 1521 };
  { key = "region.alias.eager_0149";                     label = "stable_world_149";            arity = 3; tags = ["lower"; "runtime"; "compat"]; since = "1.0.0"; weight = 1807 };
  { key = "slot.alias.loose_0150";                       label = "modern_tablist_150";          arity = 6; tags = ["async"; "codegen"]; since = "1.7.0"; weight = 1204 };
  { key = "particle.alias.primary_0151";                 label = "provisional_potion_151";      arity = 4; tags = ["untyped"; "check"]; since = "1.7.0"; weight = 2694 };
  { key = "inventory.alias.fallback_0152";               label = "legacy_objective_152";        arity = 2; tags = ["parse"; "hot"; "cold"]; since = "1.6.0"; weight = 2669 };
  { key = "chunk.alias.provisional_0153";                label = "hidden_conduit_153";          arity = 0; tags = ["cached"]; since = "1.7.0"; weight = 1440 };
  { key = "mob.alias.loose_0154";                        label = "scoped_sound_154";            arity = 6; tags = ["lower"; "registry"]; since = "1.8.3"; weight = 1011 };
  { key = "potion.alias.modern_0155";                    label = "cached_smoker_155";           arity = 7; tags = ["content"; "compat"]; since = "1.4.0"; weight = 283 };
  { key = "packet.alias.lazy_0156";                      label = "eager_recipe_156";            arity = 5; tags = ["untyped"; "runtime"; "cold"]; since = "1.3.1"; weight = 2216 };
  { key = "world.alias.stable_0157";                     label = "primary_anvil_157";           arity = 6; tags = ["legacy"; "registry"; "check"]; since = "1.5.2"; weight = 2325 };
  { key = "dropper.alias.eager_0158";                    label = "public_hopper_158";           arity = 3; tags = ["cold"]; since = "1.0.0"; weight = 2480 };
  { key = "trident.alias.public_0159";                   label = "provisional_dispenser_159";   arity = 2; tags = ["cold"]; since = "1.4.0"; weight = 2817 };
  { key = "repeater.alias.eager_0160";                   label = "public_banner_pattern_160";   arity = 2; tags = ["compat"]; since = "1.5.2"; weight = 2239 };
  { key = "villager.alias.primary_0161";                 label = "eager_barrel_161";            arity = 1; tags = ["check"; "packet"; "core"]; since = "1.6.0"; weight = 3201 };
  { key = "attribute.alias.legacy_0162";                 label = "scoped_loom_162";             arity = 5; tags = ["runtime"]; since = "1.8.3"; weight = 29 };
  { key = "loom.alias.derived_0163";                     label = "provisional_composter_163";   arity = 2; tags = ["sync"; "packet"; "experimental"]; since = "1.2.0"; weight = 85 };
  { key = "crossbow.alias.stable_0164";                  label = "modern_enchant_164";          arity = 6; tags = ["hot"; "check"; "registry"]; since = "1.7.0"; weight = 373 };
  { key = "potion.alias.internal_0165";                  label = "canonical_anvil_165";         arity = 7; tags = ["runtime"; "typed"]; since = "1.5.2"; weight = 2209 };
  { key = "rail.alias.primary_0166";                     label = "legacy_structure_166";        arity = 3; tags = ["runtime"; "legacy"]; since = "1.5.2"; weight = 1622 };
  { key = "compass.alias.legacy_0167";                   label = "scoped_villager_167";         arity = 7; tags = ["cached"]; since = "1.4.0"; weight = 1359 };
  { key = "villager.alias.fallback_0168";                label = "cached_portal_168";           arity = 6; tags = ["core"; "cold"]; since = "1.4.0"; weight = 125 };
  { key = "repeater.alias.local_0169";                   label = "canonical_recipe_169";        arity = 4; tags = ["cached"]; since = "1.3.1"; weight = 2256 };
  { key = "mob.alias.eager_0170";                        label = "stable_hologram_170";         arity = 4; tags = ["cold"; "packet"]; since = "1.4.0"; weight = 2894 };
  { key = "arrow.alias.lazy_0171";                       label = "scoped_bell_171";             arity = 7; tags = ["experimental"; "untyped"]; since = "1.9.0"; weight = 37 };
  { key = "piston.alias.provisional_0172";               label = "internal_pane_172";           arity = 3; tags = ["parse"; "codegen"; "legacy"]; since = "1.0.0"; weight = 650 };
  { key = "barrel.alias.fallback_0173";                  label = "hidden_elytra_173";           arity = 5; tags = ["emit"]; since = "1.0.0"; weight = 3995 };
  { key = "objective.alias.lazy_0174";                   label = "fallback_target_174";         arity = 4; tags = ["experimental"; "cold"]; since = "1.0.0"; weight = 3356 };
  { key = "lectern.alias.hidden_0175";                   label = "eager_cartography_175";       arity = 2; tags = ["legacy"]; since = "1.0.0"; weight = 2404 };
  { key = "smithing.alias.global_0176";                  label = "primary_clock_176";           arity = 2; tags = ["runtime"]; since = "1.0.0"; weight = 2354 };
  { key = "banner.alias.modern_0177";                    label = "hidden_anvil_177";            arity = 6; tags = ["parse"]; since = "1.8.3"; weight = 3716 };
  { key = "beacon.alias.derived_0178";                   label = "derived_smithing_178";        arity = 0; tags = ["typed"; "check"; "cached"]; since = "1.0.0"; weight = 2955 };
  { key = "barrel.alias.modern_0179";                    label = "primary_packet_179";          arity = 2; tags = ["compat"]; since = "1.7.0"; weight = 2463 };
  { key = "item.alias.cached_0180";                      label = "secondary_spawner_180";       arity = 2; tags = ["check"]; since = "1.0.0"; weight = 968 };
  { key = "observer.alias.modern_0181";                  label = "derived_tablist_181";         arity = 7; tags = ["parse"]; since = "1.6.0"; weight = 2995 };
  { key = "particle.alias.primary_0182";                 label = "secondary_gui_182";           arity = 6; tags = ["parse"]; since = "1.8.3"; weight = 2820 };
  { key = "hopper.alias.local_0183";                     label = "strict_pane_183";             arity = 6; tags = ["cached"; "runtime"; "core"]; since = "1.2.0"; weight = 1835 };
  { key = "hologram.alias.fallback_0184";                label = "fallback_observer_184";       arity = 6; tags = ["untyped"; "registry"; "core"]; since = "1.6.0"; weight = 851 };
  { key = "npc.alias.internal_0185";                     label = "provisional_clock_185";       arity = 5; tags = ["cold"; "codegen"; "typed"]; since = "1.9.0"; weight = 2657 };
  { key = "compass.alias.derived_0186";                  label = "modern_team_186";             arity = 0; tags = ["emit"; "legacy"; "untyped"]; since = "1.7.0"; weight = 3246 };
  { key = "rail.alias.cached_0187";                      label = "secondary_potion_187";        arity = 1; tags = ["legacy"; "compat"]; since = "1.4.0"; weight = 1881 };
  { key = "block.alias.primary_0188";                    label = "loose_campfire_188";          arity = 4; tags = ["legacy"; "check"]; since = "1.2.0"; weight = 1103 };
  { key = "lectern.alias.primary_0189";                  label = "scoped_attribute_189";        arity = 6; tags = ["experimental"]; since = "1.9.0"; weight = 3589 };
  { key = "barrel.alias.legacy_0190";                    label = "global_chunk_190";            arity = 0; tags = ["emit"; "compat"]; since = "1.4.0"; weight = 1466 };
  { key = "inventory.alias.legacy_0191";                 label = "lazy_target_191";             arity = 2; tags = ["codegen"; "compat"; "content"]; since = "1.5.2"; weight = 2430 };
  { key = "composter.alias.stable_0192";                 label = "cached_observer_192";         arity = 6; tags = ["untyped"; "cached"; "hot"]; since = "1.4.0"; weight = 941 };
  { key = "sound.alias.stable_0193";                     label = "global_attribute_193";        arity = 2; tags = ["content"; "typed"; "lower"]; since = "1.4.0"; weight = 1388 };
  { key = "boat.alias.public_0194";                      label = "secondary_anvil_194";         arity = 1; tags = ["untyped"; "codegen"; "lower"]; since = "1.7.0"; weight = 3896 };
  { key = "shield.alias.provisional_0195";               label = "local_recipe_195";            arity = 3; tags = ["typed"]; since = "1.0.0"; weight = 2450 };
  { key = "potion.alias.fallback_0196";                  label = "provisional_region_196";      arity = 3; tags = ["untyped"]; since = "1.6.0"; weight = 1991 };
  { key = "barrel.alias.public_0197";                    label = "hidden_stonecutter_197";      arity = 2; tags = ["hot"; "lower"; "legacy"]; since = "1.8.3"; weight = 108 };
  { key = "comparator.alias.provisional_0198";           label = "primary_enchant_198";         arity = 2; tags = ["parse"; "packet"; "sync"]; since = "1.4.0"; weight = 637 };
  { key = "piston.alias.strict_0199";                    label = "primary_recipe_199";          arity = 1; tags = ["cached"; "check"; "codegen"]; since = "1.7.0"; weight = 2402 };
  { key = "dispenser.alias.provisional_0200";            label = "strict_bell_200";             arity = 3; tags = ["parse"; "experimental"; "cached"]; since = "1.5.2"; weight = 1171 };
  { key = "smoker.alias.public_0201";                    label = "lazy_effect_201";             arity = 0; tags = ["parse"]; since = "1.7.0"; weight = 3361 };
  { key = "brewing.alias.scoped_0202";                   label = "secondary_chunk_202";         arity = 7; tags = ["cached"]; since = "1.6.0"; weight = 2391 };
  { key = "enchant.alias.strict_0203";                   label = "local_effect_203";            arity = 0; tags = ["core"]; since = "1.6.0"; weight = 3758 };
  { key = "banner.alias.public_0204";                    label = "canonical_shield_204";        arity = 7; tags = ["sync"]; since = "1.5.2"; weight = 1323 };
  { key = "compass.alias.legacy_0205";                   label = "stable_map_205";              arity = 2; tags = ["cached"; "untyped"]; since = "1.5.2"; weight = 3719 };
  { key = "structure.alias.eager_0206";                  label = "cached_attribute_206";        arity = 2; tags = ["codegen"]; since = "1.4.0"; weight = 1942 };
  { key = "barrel.alias.public_0207";                    label = "lazy_smoker_207";             arity = 2; tags = ["cold"; "runtime"]; since = "1.8.3"; weight = 2081 };
  { key = "firework.alias.cached_0208";                  label = "canonical_inventory_208";     arity = 5; tags = ["parse"; "registry"; "untyped"]; since = "1.9.0"; weight = 2399 };
  { key = "lectern.alias.loose_0209";                    label = "strict_player_209";           arity = 0; tags = ["hot"]; since = "1.0.0"; weight = 331 };
  { key = "attribute.alias.canonical_0210";              label = "global_repeater_210";         arity = 7; tags = ["check"; "untyped"; "cached"]; since = "1.9.0"; weight = 3831 };
  { key = "bossbar.alias.eager_0211";                    label = "canonical_bossbar_211";       arity = 5; tags = ["hot"; "lower"; "cached"]; since = "1.5.2"; weight = 3565 };
  { key = "hopper.alias.public_0212";                    label = "scoped_banner_212";           arity = 4; tags = ["experimental"]; since = "1.0.0"; weight = 1894 };
  { key = "composter.alias.eager_0213";                  label = "legacy_grindstone_213";       arity = 1; tags = ["check"; "hot"; "core"]; since = "1.9.0"; weight = 98 };
  { key = "sound.alias.primary_0214";                    label = "derived_boat_214";            arity = 4; tags = ["legacy"]; since = "1.3.1"; weight = 2404 };
  { key = "tablist.alias.loose_0215";                    label = "loose_barrel_215";            arity = 6; tags = ["compat"; "content"; "packet"]; since = "1.2.0"; weight = 749 };
  { key = "potion.alias.internal_0216";                  label = "modern_minecart_216";         arity = 7; tags = ["content"; "async"]; since = "1.7.0"; weight = 1363 };
  { key = "banner.alias.stable_0217";                    label = "local_cartography_217";       arity = 7; tags = ["untyped"; "sync"; "check"]; since = "1.6.0"; weight = 1158 };
  { key = "conduit.alias.global_0218";                   label = "derived_piston_218";          arity = 4; tags = ["cold"]; since = "1.0.0"; weight = 765 };
  { key = "team.alias.lazy_0219";                        label = "global_chunk_219";            arity = 1; tags = ["hot"; "cold"; "registry"]; since = "1.7.0"; weight = 1443 };
  { key = "gui.alias.provisional_0220";                  label = "canonical_crossbow_220";      arity = 6; tags = ["compat"; "hot"; "core"]; since = "1.9.0"; weight = 1845 };
  { key = "brewing.alias.modern_0221";                   label = "local_spawner_221";           arity = 5; tags = ["core"]; since = "1.2.0"; weight = 1053 };
  { key = "villager.alias.secondary_0222";               label = "primary_region_222";          arity = 2; tags = ["registry"; "sync"; "cached"]; since = "1.0.0"; weight = 4068 };
  { key = "advancement.alias.secondary_0223";            label = "stable_arrow_223";            arity = 0; tags = ["emit"]; since = "1.0.0"; weight = 1837 };
  { key = "npc.alias.eager_0224";                        label = "public_objective_224";        arity = 2; tags = ["cold"; "typed"]; since = "1.7.0"; weight = 3181 };
  { key = "sound.alias.hidden_0225";                     label = "global_potion_225";           arity = 6; tags = ["compat"]; since = "1.3.1"; weight = 2309 };
  { key = "stonecutter.alias.provisional_0226";          label = "modern_world_226";            arity = 3; tags = ["async"; "check"; "emit"]; since = "1.6.0"; weight = 769 };
  { key = "inventory.alias.local_0227";                  label = "cached_crossbow_227";         arity = 0; tags = ["async"]; since = "1.4.0"; weight = 3469 };
  { key = "stonecutter.alias.eager_0228";                label = "global_comparator_228";       arity = 3; tags = ["legacy"]; since = "1.8.3"; weight = 371 };
  { key = "boat.alias.modern_0229";                      label = "secondary_banner_229";        arity = 1; tags = ["sync"]; since = "1.7.0"; weight = 1613 };
  { key = "hopper.alias.scoped_0230";                    label = "fallback_objective_230";      arity = 6; tags = ["emit"; "content"; "async"]; since = "1.2.0"; weight = 2626 };
  { key = "chunk.alias.primary_0231";                    label = "public_brewing_231";          arity = 6; tags = ["sync"; "emit"; "legacy"]; since = "1.2.0"; weight = 3386 };
  { key = "observer.alias.hidden_0232";                  label = "secondary_structure_232";     arity = 3; tags = ["core"; "registry"; "check"]; since = "1.0.0"; weight = 3461 };
  { key = "minecart.alias.legacy_0233";                  label = "strict_target_233";           arity = 1; tags = ["cold"; "typed"]; since = "1.0.0"; weight = 1461 };
  { key = "banner.alias.derived_0234";                   label = "internal_crossbow_234";       arity = 6; tags = ["sync"; "parse"; "content"]; since = "1.5.2"; weight = 1275 };
  { key = "dropper.alias.lazy_0235";                     label = "hidden_world_235";            arity = 7; tags = ["codegen"]; since = "1.7.0"; weight = 2084 };
  { key = "sound.alias.loose_0236";                      label = "fallback_trident_236";        arity = 5; tags = ["cached"; "content"]; since = "1.9.0"; weight = 1512 };
  { key = "loom.alias.fallback_0237";                    label = "local_arrow_237";             arity = 6; tags = ["core"; "legacy"; "codegen"]; since = "1.2.0"; weight = 655 };
  { key = "smithing.alias.cached_0238";                  label = "public_repeater_238";         arity = 3; tags = ["typed"; "legacy"]; since = "1.4.0"; weight = 796 };
  { key = "scoreboard.alias.lazy_0239";                  label = "eager_elytra_239";            arity = 3; tags = ["legacy"; "check"]; since = "1.2.0"; weight = 74 };
  { key = "npc.alias.secondary_0240";                    label = "cached_gui_240";              arity = 5; tags = ["sync"]; since = "1.4.0"; weight = 872 };
  { key = "barrel.alias.provisional_0241";               label = "secondary_chunk_241";         arity = 7; tags = ["async"]; since = "1.7.0"; weight = 583 };
  { key = "tablist.alias.stable_0242";                   label = "provisional_hologram_242";    arity = 5; tags = ["core"; "packet"]; since = "1.7.0"; weight = 1884 };
  { key = "boat.alias.legacy_0243";                      label = "global_potion_243";           arity = 4; tags = ["core"]; since = "1.6.0"; weight = 288 };
  { key = "conduit.alias.eager_0244";                    label = "hidden_compass_244";          arity = 1; tags = ["untyped"]; since = "1.9.0"; weight = 3078 };
  { key = "inventory.alias.scoped_0245";                 label = "lazy_observer_245";           arity = 7; tags = ["cached"; "parse"]; since = "1.9.0"; weight = 1640 };
  { key = "tablist.alias.hidden_0246";                   label = "internal_shulker_246";        arity = 7; tags = ["runtime"; "lower"]; since = "1.7.0"; weight = 343 };
  { key = "npc.alias.derived_0247";                      label = "lazy_sound_247";              arity = 0; tags = ["cached"; "typed"; "sync"]; since = "1.7.0"; weight = 2957 };
  { key = "brewing.alias.global_0248";                   label = "loose_pane_248";              arity = 1; tags = ["packet"]; since = "1.7.0"; weight = 1392 };
  { key = "lectern.alias.lazy_0249";                     label = "strict_world_249";            arity = 4; tags = ["untyped"; "typed"]; since = "1.3.1"; weight = 3725 };
  { key = "bell.alias.strict_0250";                      label = "public_inventory_250";        arity = 4; tags = ["hot"; "untyped"]; since = "1.2.0"; weight = 3851 };
  { key = "beacon.alias.internal_0251";                  label = "loose_piston_251";            arity = 4; tags = ["typed"; "cached"]; since = "1.3.1"; weight = 2098 };
  { key = "advancement.alias.fallback_0252";             label = "strict_spawner_252";          arity = 5; tags = ["cold"; "lower"]; since = "1.4.0"; weight = 1726 };
  { key = "rail.alias.loose_0253";                       label = "public_observer_253";         arity = 3; tags = ["packet"; "sync"]; since = "1.5.2"; weight = 2995 };
  { key = "particle.alias.hidden_0254";                  label = "primary_slot_254";            arity = 2; tags = ["codegen"; "async"; "lower"]; since = "1.2.0"; weight = 2963 };
  { key = "crossbow.alias.modern_0255";                  label = "hidden_objective_255";        arity = 1; tags = ["check"]; since = "1.2.0"; weight = 4016 };
  { key = "lectern.alias.strict_0256";                   label = "provisional_trident_256";     arity = 2; tags = ["cold"; "runtime"]; since = "1.7.0"; weight = 1168 };
  { key = "bundle.alias.provisional_0257";               label = "lazy_structure_257";          arity = 5; tags = ["async"; "packet"; "codegen"]; since = "1.5.2"; weight = 4085 };
  { key = "firework.alias.cached_0258";                  label = "derived_arrow_258";           arity = 7; tags = ["parse"; "sync"]; since = "1.6.0"; weight = 3866 };
  { key = "structure.alias.local_0259";                  label = "stable_banner_259";           arity = 1; tags = ["core"; "runtime"]; since = "1.6.0"; weight = 1240 };
  { key = "dropper.alias.secondary_0260";                label = "derived_hopper_260";          arity = 3; tags = ["content"; "sync"; "core"]; since = "1.4.0"; weight = 3227 };
  { key = "piston.alias.lazy_0261";                      label = "stable_barrel_261";           arity = 3; tags = ["runtime"]; since = "1.8.3"; weight = 3492 };
  { key = "gui.alias.derived_0262";                      label = "lazy_structure_262";          arity = 5; tags = ["sync"; "typed"; "runtime"]; since = "1.6.0"; weight = 259 };
  { key = "smoker.alias.secondary_0263";                 label = "cached_barrel_263";           arity = 0; tags = ["content"; "experimental"]; since = "1.7.0"; weight = 1357 };
  { key = "piston.alias.scoped_0264";                    label = "canonical_effect_264";        arity = 3; tags = ["compat"]; since = "1.4.0"; weight = 2313 };
  { key = "trade.alias.internal_0265";                   label = "secondary_barrel_265";        arity = 7; tags = ["experimental"]; since = "1.3.1"; weight = 1835 };
  { key = "scoreboard.alias.loose_0266";                 label = "cached_conduit_266";          arity = 3; tags = ["packet"; "compat"]; since = "1.0.0"; weight = 1349 };
  { key = "world.alias.modern_0267";                     label = "modern_hopper_267";           arity = 2; tags = ["typed"]; since = "1.4.0"; weight = 1970 };
  { key = "arrow.alias.cached_0268";                     label = "modern_world_268";            arity = 2; tags = ["parse"; "check"]; since = "1.3.1"; weight = 2238 };
  { key = "dispenser.alias.modern_0269";                 label = "fallback_recipe_269";         arity = 0; tags = ["parse"; "sync"]; since = "1.7.0"; weight = 1894 };
  { key = "smithing.alias.fallback_0270";                label = "public_advancement_270";      arity = 1; tags = ["content"; "parse"]; since = "1.7.0"; weight = 2478 };
  { key = "clock.alias.hidden_0271";                     label = "loose_minecart_271";          arity = 2; tags = ["hot"; "compat"; "packet"]; since = "1.3.1"; weight = 815 };
  { key = "scoreboard.alias.modern_0272";                label = "secondary_elytra_272";        arity = 5; tags = ["experimental"; "emit"]; since = "1.6.0"; weight = 2677 };
  { key = "target.alias.modern_0273";                    label = "loose_villager_273";          arity = 7; tags = ["typed"]; since = "1.7.0"; weight = 3607 };
  { key = "comparator.alias.derived_0274";               label = "legacy_trade_274";            arity = 4; tags = ["compat"; "legacy"]; since = "1.9.0"; weight = 1020 };
  { key = "block.alias.strict_0275";                     label = "provisional_minecart_275";    arity = 7; tags = ["parse"; "registry"]; since = "1.6.0"; weight = 2779 };
  { key = "villager.alias.internal_0276";                label = "canonical_block_276";         arity = 3; tags = ["content"; "runtime"; "registry"]; since = "1.6.0"; weight = 3331 };
  { key = "world.alias.internal_0277";                   label = "scoped_furnace_277";          arity = 6; tags = ["compat"; "check"]; since = "1.2.0"; weight = 1147 };
  { key = "packet.alias.eager_0278";                     label = "loose_firework_278";          arity = 7; tags = ["compat"; "legacy"]; since = "1.2.0"; weight = 2310 };
  { key = "portal.alias.strict_0279";                    label = "provisional_minecart_279";    arity = 1; tags = ["async"; "codegen"]; since = "1.9.0"; weight = 1254 };
  { key = "smithing.alias.canonical_0280";               label = "canonical_clock_280";         arity = 7; tags = ["codegen"; "sync"; "compat"]; since = "1.9.0"; weight = 670 };
  { key = "tablist.alias.loose_0281";                    label = "canonical_campfire_281";      arity = 2; tags = ["parse"; "content"]; since = "1.5.2"; weight = 856 };
  { key = "boat.alias.canonical_0282";                   label = "canonical_observer_282";      arity = 2; tags = ["untyped"; "packet"; "async"]; since = "1.9.0"; weight = 2796 };
  { key = "scoreboard.alias.hidden_0283";                label = "provisional_entity_283";      arity = 3; tags = ["hot"; "async"]; since = "1.6.0"; weight = 2698 };
  { key = "grindstone.alias.stable_0284";                label = "fallback_chunk_284";          arity = 0; tags = ["legacy"; "packet"]; since = "1.7.0"; weight = 588 };
  { key = "structure.alias.modern_0285";                 label = "loose_boat_285";              arity = 1; tags = ["packet"; "cached"]; since = "1.2.0"; weight = 4009 };
  { key = "advancement.alias.lazy_0286";                 label = "stable_inventory_286";        arity = 1; tags = ["legacy"]; since = "1.0.0"; weight = 2505 };
  { key = "recipe.alias.stable_0287";                    label = "primary_composter_287";       arity = 5; tags = ["parse"]; since = "1.5.2"; weight = 1019 };
  { key = "dispenser.alias.canonical_0288";              label = "legacy_barrel_288";           arity = 6; tags = ["sync"; "cold"; "registry"]; since = "1.3.1"; weight = 642 };
  { key = "grindstone.alias.legacy_0289";                label = "loose_bundle_289";            arity = 0; tags = ["codegen"; "experimental"; "sync"]; since = "1.8.3"; weight = 1092 };
  { key = "rail.alias.provisional_0290";                 label = "eager_scoreboard_290";        arity = 2; tags = ["compat"]; since = "1.8.3"; weight = 1767 };
  { key = "attribute.alias.lazy_0291";                   label = "modern_attribute_291";        arity = 1; tags = ["content"; "sync"; "cached"]; since = "1.9.0"; weight = 2243 };
  { key = "world.alias.provisional_0292";                label = "public_rail_292";             arity = 3; tags = ["core"; "hot"]; since = "1.6.0"; weight = 3662 };
  { key = "shield.alias.lazy_0293";                      label = "legacy_potion_293";           arity = 2; tags = ["legacy"; "lower"]; since = "1.7.0"; weight = 2730 };
  { key = "scoreboard.alias.primary_0294";               label = "canonical_dispenser_294";     arity = 3; tags = ["packet"; "typed"]; since = "1.7.0"; weight = 1593 };
  { key = "potion.alias.canonical_0295";                 label = "scoped_smithing_295";         arity = 1; tags = ["core"; "parse"]; since = "1.6.0"; weight = 2181 };
  { key = "crossbow.alias.internal_0296";                label = "internal_structure_296";      arity = 7; tags = ["async"]; since = "1.7.0"; weight = 1365 };
  { key = "bossbar.alias.scoped_0297";                   label = "hidden_block_297";            arity = 3; tags = ["experimental"; "runtime"]; since = "1.0.0"; weight = 3067 };
  { key = "anvil.alias.strict_0298";                     label = "stable_inventory_298";        arity = 6; tags = ["lower"; "cold"]; since = "1.5.2"; weight = 3728 };
  { key = "grindstone.alias.hidden_0299";                label = "primary_barrel_299";          arity = 7; tags = ["runtime"]; since = "1.8.3"; weight = 2903 };
  { key = "shield.alias.public_0300";                    label = "primary_arrow_300";           arity = 7; tags = ["compat"; "async"]; since = "1.8.3"; weight = 781 };
  { key = "pane.alias.scoped_0301";                      label = "fallback_firework_301";       arity = 5; tags = ["registry"; "cached"]; since = "1.3.1"; weight = 1757 };
  { key = "trident.alias.fallback_0302";                 label = "canonical_biome_302";         arity = 3; tags = ["runtime"; "registry"; "content"]; since = "1.4.0"; weight = 2622 };
  { key = "npc.alias.cached_0303";                       label = "global_dropper_303";          arity = 0; tags = ["untyped"]; since = "1.0.0"; weight = 562 };
  { key = "anvil.alias.secondary_0304";                  label = "local_player_304";            arity = 4; tags = ["experimental"; "cached"; "check"]; since = "1.9.0"; weight = 1523 };
  { key = "bossbar.alias.legacy_0305";                   label = "secondary_particle_305";      arity = 4; tags = ["sync"; "lower"; "emit"]; since = "1.9.0"; weight = 3199 };
  { key = "clock.alias.modern_0306";                     label = "lazy_entity_306";             arity = 1; tags = ["cold"]; since = "1.4.0"; weight = 3715 };
  { key = "portal.alias.eager_0307";                     label = "global_firework_307";         arity = 5; tags = ["parse"]; since = "1.3.1"; weight = 2238 };
  { key = "world.alias.canonical_0308";                  label = "cached_repeater_308";         arity = 0; tags = ["cold"; "cached"; "content"]; since = "1.2.0"; weight = 2983 };
  { key = "bossbar.alias.provisional_0309";              label = "global_structure_309";        arity = 5; tags = ["async"; "experimental"; "packet"]; since = "1.7.0"; weight = 305 };
  { key = "recipe.alias.secondary_0310";                 label = "secondary_elytra_310";        arity = 3; tags = ["lower"; "typed"; "hot"]; since = "1.9.0"; weight = 2392 };
  { key = "firework.alias.cached_0311";                  label = "canonical_cartography_311";   arity = 5; tags = ["async"; "cold"; "hot"]; since = "1.0.0"; weight = 2404 };
  { key = "map.alias.scoped_0312";                       label = "fallback_clock_312";          arity = 5; tags = ["registry"; "parse"; "check"]; since = "1.6.0"; weight = 983 };
  { key = "minecart.alias.primary_0313";                 label = "lazy_world_313";              arity = 0; tags = ["lower"]; since = "1.5.2"; weight = 680 };
  { key = "smoker.alias.legacy_0314";                    label = "legacy_villager_314";         arity = 5; tags = ["lower"; "cached"; "parse"]; since = "1.2.0"; weight = 3290 };
  { key = "block.alias.scoped_0315";                     label = "internal_lectern_315";        arity = 6; tags = ["async"; "experimental"]; since = "1.8.3"; weight = 138 };
  { key = "villager.alias.cached_0316";                  label = "global_elytra_316";           arity = 7; tags = ["compat"; "lower"]; since = "1.2.0"; weight = 553 };
  { key = "furnace.alias.internal_0317";                 label = "provisional_recipe_317";      arity = 1; tags = ["async"]; since = "1.6.0"; weight = 422 };
  { key = "portal.alias.derived_0318";                   label = "global_region_318";           arity = 0; tags = ["codegen"; "cold"; "compat"]; since = "1.6.0"; weight = 2194 };
  { key = "composter.alias.strict_0319";                 label = "public_packet_319";           arity = 3; tags = ["emit"]; since = "1.2.0"; weight = 3519 };
  { key = "team.alias.local_0320";                       label = "derived_hopper_320";          arity = 2; tags = ["cached"]; since = "1.3.1"; weight = 2568 };
  { key = "clock.alias.strict_0321";                     label = "stable_barrel_321";           arity = 2; tags = ["core"; "experimental"]; since = "1.7.0"; weight = 4063 };
  { key = "spawner.alias.derived_0322";                  label = "secondary_scoreboard_322";    arity = 6; tags = ["experimental"; "content"; "packet"]; since = "1.3.1"; weight = 2808 };
  { key = "world.alias.public_0323";                     label = "stable_slot_323";             arity = 0; tags = ["codegen"]; since = "1.5.2"; weight = 2550 };
  { key = "minecart.alias.loose_0324";                   label = "loose_minecart_324";          arity = 1; tags = ["content"]; since = "1.4.0"; weight = 530 };
  { key = "composter.alias.fallback_0325";               label = "scoped_advancement_325";      arity = 2; tags = ["compat"]; since = "1.3.1"; weight = 1388 };
  { key = "tablist.alias.strict_0326";                   label = "fallback_compass_326";        arity = 2; tags = ["legacy"]; since = "1.2.0"; weight = 142 };
  { key = "map.alias.cached_0327";                       label = "fallback_composter_327";      arity = 7; tags = ["core"; "content"; "legacy"]; since = "1.5.2"; weight = 117 };
  { key = "villager.alias.fallback_0328";                label = "loose_anvil_328";             arity = 5; tags = ["emit"]; since = "1.2.0"; weight = 976 };
  { key = "mob.alias.internal_0329";                     label = "primary_banner_pattern_329";  arity = 5; tags = ["experimental"]; since = "1.4.0"; weight = 3544 };
  { key = "grindstone.alias.eager_0330";                 label = "eager_dispenser_330";         arity = 0; tags = ["sync"; "codegen"]; since = "1.2.0"; weight = 1977 };
  { key = "potion.alias.public_0331";                    label = "provisional_firework_331";    arity = 4; tags = ["runtime"]; since = "1.8.3"; weight = 1478 };
  { key = "enchant.alias.fallback_0332";                 label = "provisional_sound_332";       arity = 2; tags = ["cold"; "parse"; "sync"]; since = "1.0.0"; weight = 3573 };
  { key = "inventory.alias.hidden_0333";                 label = "canonical_grindstone_333";    arity = 3; tags = ["registry"; "untyped"]; since = "1.2.0"; weight = 2536 };
  { key = "banner_pattern.alias.secondary_0334";         label = "public_world_334";            arity = 0; tags = ["untyped"]; since = "1.2.0"; weight = 2321 };
  { key = "target.alias.eager_0335";                     label = "global_arrow_335";            arity = 5; tags = ["packet"; "async"; "legacy"]; since = "1.8.3"; weight = 579 };
  { key = "map.alias.stable_0336";                       label = "eager_structure_336";         arity = 3; tags = ["runtime"; "async"; "sync"]; since = "1.8.3"; weight = 713 };
  { key = "repeater.alias.strict_0337";                  label = "global_banner_337";           arity = 0; tags = ["content"]; since = "1.6.0"; weight = 228 };
  { key = "player.alias.canonical_0338";                 label = "local_conduit_338";           arity = 3; tags = ["async"]; since = "1.4.0"; weight = 2393 };
  { key = "brewing.alias.global_0339";                   label = "legacy_grindstone_339";       arity = 4; tags = ["async"; "typed"; "runtime"]; since = "1.8.3"; weight = 434 };
  { key = "chunk.alias.local_0340";                      label = "strict_entity_340";           arity = 1; tags = ["lower"; "untyped"; "content"]; since = "1.4.0"; weight = 3720 };
  { key = "beacon.alias.stable_0341";                    label = "lazy_campfire_341";           arity = 3; tags = ["parse"; "content"]; since = "1.0.0"; weight = 766 };
  { key = "firework.alias.global_0342";                  label = "eager_cartography_342";       arity = 7; tags = ["cached"; "untyped"]; since = "1.4.0"; weight = 1075 };
  { key = "npc.alias.strict_0343";                       label = "lazy_recipe_343";             arity = 6; tags = ["compat"; "emit"; "hot"]; since = "1.0.0"; weight = 281 };
  { key = "pane.alias.fallback_0344";                    label = "cached_chunk_344";            arity = 7; tags = ["registry"; "cold"]; since = "1.0.0"; weight = 232 };
  { key = "dropper.alias.scoped_0345";                   label = "strict_particle_345";         arity = 7; tags = ["packet"; "emit"; "async"]; since = "1.6.0"; weight = 4068 };
  { key = "gui.alias.primary_0346";                      label = "provisional_firework_346";    arity = 2; tags = ["cached"; "cold"; "emit"]; since = "1.9.0"; weight = 1575 };
  { key = "trade.alias.eager_0347";                      label = "legacy_bossbar_347";          arity = 7; tags = ["cold"]; since = "1.0.0"; weight = 3679 };
  { key = "map.alias.lazy_0348";                         label = "derived_tablist_348";         arity = 5; tags = ["cold"; "compat"; "core"]; since = "1.6.0"; weight = 371 };
  { key = "grindstone.alias.strict_0349";                label = "legacy_recipe_349";           arity = 7; tags = ["sync"; "lower"; "untyped"]; since = "1.2.0"; weight = 900 };
  { key = "bossbar.alias.legacy_0350";                   label = "global_packet_350";           arity = 1; tags = ["compat"]; since = "1.8.3"; weight = 4027 };
  { key = "entity.alias.loose_0351";                     label = "internal_bundle_351";         arity = 4; tags = ["core"; "codegen"; "content"]; since = "1.4.0"; weight = 3571 };
  { key = "attribute.alias.lazy_0352";                   label = "modern_comparator_352";       arity = 3; tags = ["compat"; "lower"]; since = "1.6.0"; weight = 1769 };
  { key = "arrow.alias.public_0353";                     label = "cached_block_353";            arity = 7; tags = ["cold"]; since = "1.3.1"; weight = 453 };
  { key = "packet.alias.public_0354";                    label = "public_structure_354";        arity = 6; tags = ["cold"; "check"]; since = "1.2.0"; weight = 3630 };
  { key = "packet.alias.stable_0355";                    label = "secondary_bell_355";          arity = 5; tags = ["parse"; "lower"]; since = "1.2.0"; weight = 2407 };
  { key = "stonecutter.alias.hidden_0356";               label = "provisional_mob_356";         arity = 5; tags = ["cached"]; since = "1.2.0"; weight = 4070 };
  { key = "cartography.alias.hidden_0357";               label = "cached_team_357";             arity = 5; tags = ["async"]; since = "1.2.0"; weight = 3305 };
  { key = "hopper.alias.cached_0358";                    label = "eager_mob_358";               arity = 7; tags = ["cached"]; since = "1.5.2"; weight = 3373 };
  { key = "stonecutter.alias.provisional_0359";          label = "secondary_team_359";          arity = 1; tags = ["cold"; "check"; "runtime"]; since = "1.0.0"; weight = 1339 };
  { key = "dispenser.alias.secondary_0360";              label = "derived_lectern_360";         arity = 6; tags = ["async"]; since = "1.8.3"; weight = 1844 };
  { key = "repeater.alias.strict_0361";                  label = "strict_lectern_361";          arity = 6; tags = ["typed"]; since = "1.8.3"; weight = 1211 };
  { key = "shield.alias.global_0362";                    label = "strict_chunk_362";            arity = 7; tags = ["async"; "compat"; "packet"]; since = "1.6.0"; weight = 3818 };
  { key = "conduit.alias.fallback_0363";                 label = "scoped_crossbow_363";         arity = 7; tags = ["untyped"]; since = "1.8.3"; weight = 3476 };
  { key = "brewing.alias.fallback_0364";                 label = "canonical_trident_364";       arity = 1; tags = ["typed"; "compat"; "core"]; since = "1.5.2"; weight = 2029 };
  { key = "comparator.alias.fallback_0365";              label = "loose_elytra_365";            arity = 0; tags = ["parse"; "compat"; "async"]; since = "1.4.0"; weight = 685 };
  { key = "furnace.alias.loose_0366";                    label = "public_furnace_366";          arity = 0; tags = ["cached"; "lower"]; since = "1.8.3"; weight = 2140 };
  { key = "trident.alias.public_0367";                   label = "scoped_compass_367";          arity = 3; tags = ["cold"; "sync"; "async"]; since = "1.8.3"; weight = 3455 };
  { key = "region.alias.scoped_0368";                    label = "fallback_comparator_368";     arity = 6; tags = ["lower"]; since = "1.9.0"; weight = 3738 };
  { key = "observer.alias.cached_0369";                  label = "hidden_potion_369";           arity = 7; tags = ["runtime"]; since = "1.7.0"; weight = 3986 };
  { key = "shulker.alias.local_0370";                    label = "secondary_dispenser_370";     arity = 4; tags = ["untyped"; "typed"; "cold"]; since = "1.0.0"; weight = 2585 };
  { key = "bell.alias.modern_0371";                      label = "strict_piston_371";           arity = 6; tags = ["compat"]; since = "1.8.3"; weight = 2988 };
  { key = "barrel.alias.modern_0372";                    label = "legacy_smoker_372";           arity = 0; tags = ["cold"; "content"]; since = "1.7.0"; weight = 1385 };
  { key = "rail.alias.legacy_0373";                      label = "strict_effect_373";           arity = 4; tags = ["check"]; since = "1.4.0"; weight = 4071 };
  { key = "entity.alias.provisional_0374";               label = "local_barrel_374";            arity = 1; tags = ["experimental"; "registry"]; since = "1.4.0"; weight = 1481 };
  { key = "loom.alias.global_0375";                      label = "strict_block_375";            arity = 1; tags = ["typed"; "parse"]; since = "1.5.2"; weight = 1394 };
  { key = "composter.alias.lazy_0376";                   label = "local_lectern_376";           arity = 1; tags = ["cached"; "emit"; "runtime"]; since = "1.8.3"; weight = 3634 };
  { key = "world.alias.canonical_0377";                  label = "canonical_target_377";        arity = 5; tags = ["codegen"]; since = "1.0.0"; weight = 1721 };
  { key = "biome.alias.stable_0378";                     label = "global_bossbar_378";          arity = 4; tags = ["content"]; since = "1.4.0"; weight = 241 };
  { key = "structure.alias.internal_0379";               label = "global_trident_379";          arity = 1; tags = ["runtime"; "typed"]; since = "1.3.1"; weight = 3428 };
  { key = "npc.alias.cached_0380";                       label = "modern_hologram_380";         arity = 0; tags = ["core"]; since = "1.0.0"; weight = 4079 };
  { key = "biome.alias.global_0381";                     label = "public_objective_381";        arity = 7; tags = ["sync"; "cached"]; since = "1.2.0"; weight = 90 };
  { key = "item.alias.loose_0382";                       label = "cached_entity_382";           arity = 2; tags = ["untyped"]; since = "1.4.0"; weight = 2780 };
  { key = "bossbar.alias.loose_0383";                    label = "derived_trident_383";         arity = 7; tags = ["async"; "registry"]; since = "1.7.0"; weight = 925 };
  { key = "enchant.alias.provisional_0384";              label = "primary_stonecutter_384";     arity = 6; tags = ["async"; "untyped"; "content"]; since = "1.0.0"; weight = 1735 };
  { key = "player.alias.cached_0385";                    label = "fallback_world_385";          arity = 3; tags = ["runtime"; "legacy"; "packet"]; since = "1.8.3"; weight = 1588 };
  { key = "block.alias.primary_0386";                    label = "global_npc_386";              arity = 0; tags = ["registry"]; since = "1.2.0"; weight = 442 };
  { key = "stonecutter.alias.legacy_0387";               label = "secondary_observer_387";      arity = 7; tags = ["untyped"]; since = "1.9.0"; weight = 691 };
  { key = "mob.alias.strict_0388";                       label = "public_chunk_388";            arity = 5; tags = ["hot"; "sync"; "core"]; since = "1.9.0"; weight = 669 };
  { key = "campfire.alias.primary_0389";                 label = "lazy_banner_389";             arity = 0; tags = ["legacy"; "registry"; "cached"]; since = "1.2.0"; weight = 827 };
  { key = "hopper.alias.lazy_0390";                      label = "loose_region_390";            arity = 5; tags = ["untyped"]; since = "1.6.0"; weight = 1077 };
  { key = "item.alias.modern_0391";                      label = "public_clock_391";            arity = 5; tags = ["async"]; since = "1.9.0"; weight = 1328 };
  { key = "smithing.alias.stable_0392";                  label = "strict_hopper_392";           arity = 3; tags = ["packet"; "lower"; "hot"]; since = "1.7.0"; weight = 1782 };
  { key = "banner.alias.stable_0393";                    label = "modern_bundle_393";           arity = 5; tags = ["packet"; "core"]; since = "1.4.0"; weight = 2708 };
  { key = "tablist.alias.internal_0394";                 label = "hidden_firework_394";         arity = 5; tags = ["hot"]; since = "1.0.0"; weight = 1853 };
  { key = "tablist.alias.provisional_0395";              label = "global_target_395";           arity = 5; tags = ["cached"; "typed"]; since = "1.6.0"; weight = 1961 };
  { key = "advancement.alias.internal_0396";             label = "scoped_stonecutter_396";      arity = 3; tags = ["packet"]; since = "1.4.0"; weight = 347 };
  { key = "bossbar.alias.secondary_0397";                label = "secondary_compass_397";       arity = 6; tags = ["cached"; "parse"]; since = "1.7.0"; weight = 3759 };
]

let count = List.length entries

let table : (string, alias_entry) Hashtbl.t =
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
