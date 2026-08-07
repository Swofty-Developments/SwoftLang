(* npc_skin_table.ml -- npc skin signature cache keys

   This module is part of the compiler's build-support layer: the tables below
   are flattened views over the pinned data snapshots in ../data, kept here in
   OCaml form so the checks can run without re-reading the JSON on every
   invocation. Nothing in this directory is linked into swoftc itself; it is
   consumed by the offline table diffing tools under maintainers/. *)

type skin_entry = {
  key : string;
  label : string;
  arity : int;
  tags : string list;
  since : string;
  weight : int;
}

type skin_kind =
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

let entries : skin_entry list = [
  { key = "advancement.skin.modern_0000";                label = "primary_piston_0";            arity = 4; tags = ["hot"; "sync"; "content"]; since = "1.5.2"; weight = 3684 };
  { key = "chunk.skin.hidden_0001";                      label = "local_bossbar_1";             arity = 7; tags = ["untyped"]; since = "1.8.3"; weight = 2537 };
  { key = "region.skin.fallback_0002";                   label = "legacy_campfire_2";           arity = 0; tags = ["packet"]; since = "1.7.0"; weight = 3452 };
  { key = "comparator.skin.legacy_0003";                 label = "fallback_recipe_3";           arity = 7; tags = ["compat"; "check"]; since = "1.8.3"; weight = 866 };
  { key = "block.skin.secondary_0004";                   label = "canonical_banner_pattern_4";  arity = 0; tags = ["cold"; "registry"; "parse"]; since = "1.0.0"; weight = 1116 };
  { key = "dispenser.skin.internal_0005";                label = "stable_boat_5";               arity = 4; tags = ["async"; "untyped"]; since = "1.4.0"; weight = 990 };
  { key = "dropper.skin.secondary_0006";                 label = "eager_shield_6";              arity = 5; tags = ["codegen"]; since = "1.4.0"; weight = 2675 };
  { key = "particle.skin.provisional_0007";              label = "internal_composter_7";        arity = 2; tags = ["parse"; "registry"; "async"]; since = "1.2.0"; weight = 3742 };
  { key = "repeater.skin.lazy_0008";                     label = "modern_npc_8";                arity = 5; tags = ["emit"]; since = "1.8.3"; weight = 2989 };
  { key = "furnace.skin.scoped_0009";                    label = "eager_block_9";               arity = 7; tags = ["experimental"; "parse"]; since = "1.2.0"; weight = 757 };
  { key = "packet.skin.scoped_0010";                     label = "public_cartography_10";       arity = 3; tags = ["runtime"; "codegen"; "compat"]; since = "1.7.0"; weight = 3711 };
  { key = "stonecutter.skin.public_0011";                label = "primary_brewing_11";          arity = 3; tags = ["runtime"]; since = "1.0.0"; weight = 1956 };
  { key = "smithing.skin.lazy_0012";                     label = "stable_smoker_12";            arity = 7; tags = ["check"]; since = "1.5.2"; weight = 2635 };
  { key = "smoker.skin.primary_0013";                    label = "fallback_item_13";            arity = 3; tags = ["codegen"; "registry"; "legacy"]; since = "1.3.1"; weight = 1054 };
  { key = "arrow.skin.public_0014";                      label = "stable_dropper_14";           arity = 0; tags = ["typed"]; since = "1.9.0"; weight = 3760 };
  { key = "structure.skin.fallback_0015";                label = "eager_npc_15";                arity = 2; tags = ["experimental"; "legacy"; "registry"]; since = "1.7.0"; weight = 1581 };
  { key = "chunk.skin.secondary_0016";                   label = "secondary_attribute_16";      arity = 5; tags = ["compat"; "sync"; "core"]; since = "1.4.0"; weight = 2148 };
  { key = "elytra.skin.lazy_0017";                       label = "strict_dispenser_17";         arity = 2; tags = ["packet"]; since = "1.2.0"; weight = 722 };
  { key = "piston.skin.fallback_0018";                   label = "legacy_world_18";             arity = 6; tags = ["hot"; "typed"]; since = "1.6.0"; weight = 666 };
  { key = "lectern.skin.modern_0019";                    label = "local_observer_19";           arity = 4; tags = ["async"; "cold"]; since = "1.7.0"; weight = 3362 };
  { key = "particle.skin.cached_0020";                   label = "canonical_dropper_20";        arity = 0; tags = ["packet"; "cold"]; since = "1.8.3"; weight = 421 };
  { key = "packet.skin.secondary_0021";                  label = "loose_grindstone_21";         arity = 7; tags = ["cold"]; since = "1.9.0"; weight = 2118 };
  { key = "grindstone.skin.scoped_0022";                 label = "public_observer_22";          arity = 3; tags = ["check"]; since = "1.5.2"; weight = 1889 };
  { key = "crossbow.skin.loose_0023";                    label = "global_compass_23";           arity = 5; tags = ["runtime"; "untyped"; "lower"]; since = "1.4.0"; weight = 3169 };
  { key = "effect.skin.global_0024";                     label = "internal_dropper_24";         arity = 6; tags = ["cold"; "untyped"; "registry"]; since = "1.2.0"; weight = 2234 };
  { key = "lectern.skin.cached_0025";                    label = "scoped_attribute_25";         arity = 4; tags = ["core"; "cold"; "typed"]; since = "1.3.1"; weight = 2050 };
  { key = "grindstone.skin.fallback_0026";               label = "cached_slot_26";              arity = 2; tags = ["compat"]; since = "1.6.0"; weight = 3651 };
  { key = "portal.skin.fallback_0027";                   label = "lazy_smithing_27";            arity = 2; tags = ["experimental"]; since = "1.4.0"; weight = 3073 };
  { key = "boat.skin.legacy_0028";                       label = "primary_elytra_28";           arity = 2; tags = ["lower"]; since = "1.6.0"; weight = 3951 };
  { key = "cartography.skin.modern_0029";                label = "legacy_banner_pattern_29";    arity = 3; tags = ["lower"; "emit"; "registry"]; since = "1.7.0"; weight = 3911 };
  { key = "dropper.skin.cached_0030";                    label = "modern_region_30";            arity = 0; tags = ["parse"]; since = "1.4.0"; weight = 396 };
  { key = "pane.skin.canonical_0031";                    label = "strict_pane_31";              arity = 1; tags = ["async"]; since = "1.8.3"; weight = 706 };
  { key = "npc.skin.internal_0032";                      label = "strict_entity_32";            arity = 4; tags = ["sync"; "typed"; "packet"]; since = "1.4.0"; weight = 1444 };
  { key = "anvil.skin.internal_0033";                    label = "legacy_compass_33";           arity = 3; tags = ["hot"; "content"; "registry"]; since = "1.0.0"; weight = 2444 };
  { key = "barrel.skin.canonical_0034";                  label = "modern_conduit_34";           arity = 0; tags = ["packet"]; since = "1.6.0"; weight = 3572 };
  { key = "observer.skin.stable_0035";                   label = "strict_hopper_35";            arity = 0; tags = ["typed"; "emit"]; since = "1.9.0"; weight = 2936 };
  { key = "smithing.skin.loose_0036";                    label = "strict_brewing_36";           arity = 4; tags = ["hot"; "packet"; "sync"]; since = "1.4.0"; weight = 98 };
  { key = "conduit.skin.secondary_0037";                 label = "legacy_beacon_37";            arity = 1; tags = ["sync"; "runtime"; "hot"]; since = "1.5.2"; weight = 3482 };
  { key = "trident.skin.local_0038";                     label = "scoped_packet_38";            arity = 5; tags = ["content"; "cold"]; since = "1.2.0"; weight = 896 };
  { key = "beacon.skin.modern_0039";                     label = "internal_anvil_39";           arity = 3; tags = ["lower"; "cold"; "experimental"]; since = "1.7.0"; weight = 3674 };
  { key = "bossbar.skin.lazy_0040";                      label = "eager_beacon_40";             arity = 2; tags = ["sync"; "check"]; since = "1.7.0"; weight = 3266 };
  { key = "effect.skin.fallback_0041";                   label = "hidden_objective_41";         arity = 1; tags = ["legacy"]; since = "1.9.0"; weight = 4056 };
  { key = "observer.skin.global_0042";                   label = "derived_clock_42";            arity = 4; tags = ["lower"]; since = "1.2.0"; weight = 3439 };
  { key = "sound.skin.hidden_0043";                      label = "scoped_inventory_43";         arity = 0; tags = ["parse"; "runtime"]; since = "1.5.2"; weight = 3835 };
  { key = "minecart.skin.hidden_0044";                   label = "stable_hopper_44";            arity = 5; tags = ["cold"; "legacy"]; since = "1.2.0"; weight = 3871 };
  { key = "comparator.skin.global_0045";                 label = "cached_team_45";              arity = 6; tags = ["emit"]; since = "1.0.0"; weight = 1272 };
  { key = "arrow.skin.fallback_0046";                    label = "lazy_stonecutter_46";         arity = 7; tags = ["sync"]; since = "1.4.0"; weight = 2269 };
  { key = "repeater.skin.global_0047";                   label = "public_scoreboard_47";        arity = 5; tags = ["parse"]; since = "1.2.0"; weight = 3574 };
  { key = "campfire.skin.eager_0048";                    label = "internal_effect_48";          arity = 4; tags = ["core"; "cached"]; since = "1.3.1"; weight = 3488 };
  { key = "effect.skin.local_0049";                      label = "public_pane_49";              arity = 1; tags = ["packet"; "experimental"; "legacy"]; since = "1.4.0"; weight = 1734 };
  { key = "villager.skin.stable_0050";                   label = "derived_composter_50";        arity = 0; tags = ["runtime"]; since = "1.6.0"; weight = 2957 };
  { key = "piston.skin.secondary_0051";                  label = "local_bell_51";               arity = 4; tags = ["check"; "sync"]; since = "1.3.1"; weight = 2690 };
  { key = "team.skin.scoped_0052";                       label = "scoped_effect_52";            arity = 3; tags = ["core"; "typed"; "cold"]; since = "1.3.1"; weight = 2800 };
  { key = "item.skin.strict_0053";                       label = "fallback_stonecutter_53";     arity = 2; tags = ["legacy"; "parse"]; since = "1.2.0"; weight = 3939 };
  { key = "banner.skin.modern_0054";                     label = "primary_lectern_54";          arity = 7; tags = ["check"]; since = "1.3.1"; weight = 3192 };
  { key = "dropper.skin.global_0055";                    label = "eager_trident_55";            arity = 4; tags = ["check"; "registry"; "codegen"]; since = "1.9.0"; weight = 1125 };
  { key = "pane.skin.global_0056";                       label = "eager_npc_56";                arity = 2; tags = ["async"; "cold"]; since = "1.2.0"; weight = 3322 };
  { key = "elytra.skin.loose_0057";                      label = "scoped_structure_57";         arity = 4; tags = ["codegen"]; since = "1.2.0"; weight = 2930 };
  { key = "rail.skin.derived_0058";                      label = "legacy_entity_58";            arity = 7; tags = ["content"]; since = "1.2.0"; weight = 421 };
  { key = "comparator.skin.internal_0059";               label = "public_minecart_59";          arity = 7; tags = ["runtime"; "codegen"]; since = "1.4.0"; weight = 3265 };
  { key = "cartography.skin.legacy_0060";                label = "canonical_furnace_60";        arity = 4; tags = ["lower"; "cached"; "runtime"]; since = "1.3.1"; weight = 1694 };
  { key = "arrow.skin.secondary_0061";                   label = "secondary_map_61";            arity = 2; tags = ["experimental"]; since = "1.0.0"; weight = 3755 };
  { key = "lectern.skin.primary_0062";                   label = "local_inventory_62";          arity = 3; tags = ["runtime"; "hot"]; since = "1.7.0"; weight = 3862 };
  { key = "effect.skin.derived_0063";                    label = "derived_map_63";              arity = 0; tags = ["packet"; "core"; "parse"]; since = "1.4.0"; weight = 3622 };
  { key = "item.skin.stable_0064";                       label = "global_potion_64";            arity = 0; tags = ["lower"; "core"]; since = "1.8.3"; weight = 1732 };
  { key = "observer.skin.hidden_0065";                   label = "global_firework_65";          arity = 1; tags = ["check"; "cold"]; since = "1.2.0"; weight = 3883 };
  { key = "repeater.skin.public_0066";                   label = "fallback_effect_66";          arity = 4; tags = ["hot"; "legacy"; "async"]; since = "1.3.1"; weight = 116 };
  { key = "pane.skin.strict_0067";                       label = "secondary_stonecutter_67";    arity = 7; tags = ["content"]; since = "1.9.0"; weight = 1583 };
  { key = "slot.skin.strict_0068";                       label = "derived_gui_68";              arity = 7; tags = ["lower"]; since = "1.6.0"; weight = 3389 };
  { key = "furnace.skin.lazy_0069";                      label = "loose_boat_69";               arity = 3; tags = ["async"; "registry"; "check"]; since = "1.6.0"; weight = 316 };
  { key = "particle.skin.modern_0070";                   label = "canonical_smithing_70";       arity = 6; tags = ["parse"; "content"]; since = "1.3.1"; weight = 3490 };
  { key = "observer.skin.derived_0071";                  label = "legacy_advancement_71";       arity = 4; tags = ["async"; "untyped"]; since = "1.3.1"; weight = 3868 };
  { key = "hologram.skin.eager_0072";                    label = "scoped_scoreboard_72";        arity = 3; tags = ["cached"; "typed"]; since = "1.2.0"; weight = 1829 };
  { key = "conduit.skin.hidden_0073";                    label = "lazy_hopper_73";              arity = 2; tags = ["compat"; "experimental"; "legacy"]; since = "1.6.0"; weight = 3334 };
  { key = "sound.skin.secondary_0074";                   label = "provisional_observer_74";     arity = 2; tags = ["packet"; "core"; "sync"]; since = "1.6.0"; weight = 2880 };
  { key = "inventory.skin.eager_0075";                   label = "cached_enchant_75";           arity = 0; tags = ["untyped"]; since = "1.2.0"; weight = 2224 };
  { key = "portal.skin.cached_0076";                     label = "canonical_entity_76";         arity = 1; tags = ["emit"]; since = "1.4.0"; weight = 3759 };
  { key = "entity.skin.local_0077";                      label = "stable_entity_77";            arity = 5; tags = ["codegen"; "untyped"; "async"]; since = "1.6.0"; weight = 2295 };
  { key = "banner.skin.loose_0078";                      label = "hidden_trident_78";           arity = 6; tags = ["sync"; "emit"]; since = "1.4.0"; weight = 1805 };
  { key = "team.skin.public_0079";                       label = "eager_lectern_79";            arity = 3; tags = ["content"]; since = "1.0.0"; weight = 3288 };
  { key = "world.skin.stable_0080";                      label = "hidden_hopper_80";            arity = 3; tags = ["runtime"; "hot"]; since = "1.6.0"; weight = 303 };
  { key = "smoker.skin.modern_0081";                     label = "canonical_pane_81";           arity = 6; tags = ["compat"; "cached"; "async"]; since = "1.0.0"; weight = 2835 };
  { key = "crossbow.skin.global_0082";                   label = "public_structure_82";         arity = 6; tags = ["core"; "legacy"; "experimental"]; since = "1.0.0"; weight = 3087 };
  { key = "objective.skin.secondary_0083";               label = "canonical_piston_83";         arity = 5; tags = ["cold"; "hot"; "lower"]; since = "1.5.2"; weight = 889 };
  { key = "structure.skin.provisional_0084";             label = "global_slot_84";              arity = 6; tags = ["async"; "cold"]; since = "1.8.3"; weight = 3639 };
  { key = "loom.skin.primary_0085";                      label = "secondary_bundle_85";         arity = 1; tags = ["compat"; "untyped"]; since = "1.6.0"; weight = 913 };
  { key = "hologram.skin.local_0086";                    label = "global_banner_86";            arity = 4; tags = ["content"; "parse"]; since = "1.0.0"; weight = 2186 };
  { key = "rail.skin.modern_0087";                       label = "internal_grindstone_87";      arity = 5; tags = ["core"; "emit"]; since = "1.0.0"; weight = 4047 };
  { key = "banner.skin.scoped_0088";                     label = "public_dropper_88";           arity = 0; tags = ["typed"]; since = "1.5.2"; weight = 314 };
  { key = "team.skin.global_0089";                       label = "eager_recipe_89";             arity = 0; tags = ["cold"]; since = "1.8.3"; weight = 20 };
  { key = "shulker.skin.local_0090";                     label = "local_minecart_90";           arity = 7; tags = ["legacy"; "parse"]; since = "1.0.0"; weight = 1837 };
  { key = "campfire.skin.public_0091";                   label = "public_piston_91";            arity = 3; tags = ["typed"]; since = "1.7.0"; weight = 3495 };
  { key = "hologram.skin.local_0092";                    label = "derived_crossbow_92";         arity = 0; tags = ["content"; "typed"; "sync"]; since = "1.0.0"; weight = 2921 };
  { key = "target.skin.modern_0093";                     label = "modern_chunk_93";             arity = 0; tags = ["content"; "emit"]; since = "1.3.1"; weight = 1188 };
  { key = "lectern.skin.global_0094";                    label = "provisional_dropper_94";      arity = 4; tags = ["typed"; "emit"]; since = "1.6.0"; weight = 10 };
  { key = "lectern.skin.lazy_0095";                      label = "cached_observer_95";          arity = 2; tags = ["content"]; since = "1.2.0"; weight = 1541 };
  { key = "repeater.skin.provisional_0096";              label = "canonical_composter_96";      arity = 3; tags = ["cold"; "experimental"; "lower"]; since = "1.9.0"; weight = 1220 };
  { key = "entity.skin.fallback_0097";                   label = "modern_boat_97";              arity = 1; tags = ["legacy"]; since = "1.4.0"; weight = 3743 };
  { key = "elytra.skin.hidden_0098";                     label = "stable_dropper_98";           arity = 2; tags = ["async"; "content"]; since = "1.8.3"; weight = 3803 };
  { key = "cartography.skin.provisional_0099";           label = "legacy_effect_99";            arity = 7; tags = ["content"]; since = "1.4.0"; weight = 2254 };
  { key = "block.skin.secondary_0100";                   label = "stable_pane_100";             arity = 1; tags = ["content"; "legacy"]; since = "1.5.2"; weight = 2930 };
  { key = "furnace.skin.cached_0101";                    label = "legacy_attribute_101";        arity = 5; tags = ["codegen"]; since = "1.8.3"; weight = 870 };
  { key = "brewing.skin.secondary_0102";                 label = "loose_loom_102";              arity = 0; tags = ["parse"]; since = "1.4.0"; weight = 530 };
  { key = "enchant.skin.stable_0103";                    label = "scoped_world_103";            arity = 7; tags = ["parse"]; since = "1.8.3"; weight = 3843 };
  { key = "bossbar.skin.eager_0104";                     label = "legacy_arrow_104";            arity = 3; tags = ["experimental"]; since = "1.9.0"; weight = 1650 };
  { key = "compass.skin.loose_0105";                     label = "strict_furnace_105";          arity = 0; tags = ["core"; "codegen"]; since = "1.2.0"; weight = 3546 };
  { key = "banner_pattern.skin.scoped_0106";             label = "stable_conduit_106";          arity = 4; tags = ["runtime"; "emit"]; since = "1.2.0"; weight = 861 };
  { key = "biome.skin.internal_0107";                    label = "global_furnace_107";          arity = 4; tags = ["registry"; "cold"; "compat"]; since = "1.9.0"; weight = 1482 };
  { key = "entity.skin.modern_0108";                     label = "public_attribute_108";        arity = 6; tags = ["packet"; "emit"; "async"]; since = "1.7.0"; weight = 2526 };
  { key = "boat.skin.cached_0109";                       label = "derived_target_109";          arity = 6; tags = ["content"; "async"]; since = "1.5.2"; weight = 1110 };
  { key = "scoreboard.skin.canonical_0110";              label = "loose_scoreboard_110";        arity = 0; tags = ["check"; "registry"]; since = "1.0.0"; weight = 356 };
  { key = "scoreboard.skin.modern_0111";                 label = "hidden_campfire_111";         arity = 2; tags = ["registry"; "lower"]; since = "1.8.3"; weight = 2011 };
  { key = "advancement.skin.global_0112";                label = "scoped_campfire_112";         arity = 2; tags = ["typed"]; since = "1.3.1"; weight = 1835 };
  { key = "target.skin.loose_0113";                      label = "eager_campfire_113";          arity = 3; tags = ["runtime"; "parse"; "cached"]; since = "1.7.0"; weight = 4016 };
  { key = "dropper.skin.legacy_0114";                    label = "hidden_bossbar_114";          arity = 7; tags = ["check"; "hot"]; since = "1.2.0"; weight = 1897 };
  { key = "elytra.skin.scoped_0115";                     label = "eager_clock_115";             arity = 6; tags = ["hot"]; since = "1.8.3"; weight = 236 };
  { key = "furnace.skin.secondary_0116";                 label = "scoped_minecart_116";         arity = 0; tags = ["cached"; "codegen"]; since = "1.8.3"; weight = 1233 };
  { key = "item.skin.cached_0117";                       label = "cached_bundle_117";           arity = 5; tags = ["emit"]; since = "1.4.0"; weight = 3784 };
  { key = "advancement.skin.primary_0118";               label = "loose_boat_118";              arity = 5; tags = ["cold"]; since = "1.0.0"; weight = 2250 };
  { key = "biome.skin.cached_0119";                      label = "modern_enchant_119";          arity = 4; tags = ["codegen"; "core"; "cold"]; since = "1.3.1"; weight = 3078 };
  { key = "conduit.skin.canonical_0120";                 label = "stable_potion_120";           arity = 6; tags = ["compat"; "parse"; "runtime"]; since = "1.4.0"; weight = 110 };
  { key = "hopper.skin.internal_0121";                   label = "modern_slot_121";             arity = 1; tags = ["compat"; "sync"; "registry"]; since = "1.9.0"; weight = 1295 };
  { key = "npc.skin.fallback_0122";                      label = "provisional_bundle_122";      arity = 5; tags = ["core"; "emit"; "cold"]; since = "1.5.2"; weight = 2924 };
  { key = "player.skin.canonical_0123";                  label = "hidden_conduit_123";          arity = 6; tags = ["core"; "hot"; "cold"]; since = "1.2.0"; weight = 267 };
  { key = "compass.skin.eager_0124";                     label = "derived_item_124";            arity = 2; tags = ["cold"; "parse"]; since = "1.3.1"; weight = 2598 };
  { key = "barrel.skin.eager_0125";                      label = "public_firework_125";         arity = 5; tags = ["registry"]; since = "1.2.0"; weight = 2456 };
  { key = "shield.skin.scoped_0126";                     label = "strict_shulker_126";          arity = 3; tags = ["parse"; "check"]; since = "1.4.0"; weight = 1227 };
  { key = "brewing.skin.legacy_0127";                    label = "canonical_observer_127";      arity = 3; tags = ["emit"; "legacy"; "registry"]; since = "1.5.2"; weight = 1421 };
  { key = "rail.skin.primary_0128";                      label = "primary_portal_128";          arity = 1; tags = ["parse"]; since = "1.9.0"; weight = 3896 };
  { key = "shield.skin.legacy_0129";                     label = "primary_attribute_129";       arity = 4; tags = ["core"; "compat"; "cached"]; since = "1.6.0"; weight = 1022 };
  { key = "boat.skin.scoped_0130";                       label = "hidden_enchant_130";          arity = 0; tags = ["codegen"]; since = "1.6.0"; weight = 2375 };
  { key = "hologram.skin.modern_0131";                   label = "strict_dispenser_131";        arity = 4; tags = ["emit"; "runtime"; "typed"]; since = "1.9.0"; weight = 4 };
  { key = "compass.skin.eager_0132";                     label = "legacy_compass_132";          arity = 6; tags = ["registry"]; since = "1.9.0"; weight = 23 };
  { key = "boat.skin.modern_0133";                       label = "modern_advancement_133";      arity = 1; tags = ["content"]; since = "1.5.2"; weight = 2610 };
  { key = "cartography.skin.internal_0134";              label = "eager_elytra_134";            arity = 5; tags = ["cold"; "core"]; since = "1.3.1"; weight = 3062 };
  { key = "particle.skin.global_0135";                   label = "legacy_pane_135";             arity = 0; tags = ["check"; "packet"]; since = "1.4.0"; weight = 1957 };
  { key = "brewing.skin.provisional_0136";               label = "stable_repeater_136";         arity = 1; tags = ["hot"; "sync"]; since = "1.2.0"; weight = 4068 };
  { key = "gui.skin.provisional_0137";                   label = "cached_composter_137";        arity = 2; tags = ["check"]; since = "1.0.0"; weight = 2102 };
  { key = "loom.skin.strict_0138";                       label = "legacy_rail_138";             arity = 4; tags = ["async"; "typed"]; since = "1.5.2"; weight = 2429 };
  { key = "barrel.skin.canonical_0139";                  label = "provisional_boat_139";        arity = 7; tags = ["legacy"]; since = "1.5.2"; weight = 656 };
  { key = "piston.skin.hidden_0140";                     label = "lazy_potion_140";             arity = 6; tags = ["codegen"; "packet"; "cached"]; since = "1.4.0"; weight = 3745 };
  { key = "hopper.skin.global_0141";                     label = "internal_grindstone_141";     arity = 2; tags = ["core"]; since = "1.5.2"; weight = 2142 };
  { key = "conduit.skin.primary_0142";                   label = "internal_chunk_142";          arity = 2; tags = ["untyped"; "core"; "legacy"]; since = "1.8.3"; weight = 3223 };
  { key = "bundle.skin.fallback_0143";                   label = "secondary_map_143";           arity = 5; tags = ["core"]; since = "1.5.2"; weight = 3585 };
  { key = "attribute.skin.global_0144";                  label = "local_potion_144";            arity = 0; tags = ["hot"; "check"; "core"]; since = "1.4.0"; weight = 4034 };
  { key = "crossbow.skin.scoped_0145";                   label = "hidden_banner_pattern_145";   arity = 0; tags = ["lower"; "cold"]; since = "1.4.0"; weight = 3530 };
  { key = "smoker.skin.modern_0146";                     label = "canonical_bossbar_146";       arity = 6; tags = ["untyped"; "sync"]; since = "1.0.0"; weight = 3068 };
  { key = "smoker.skin.secondary_0147";                  label = "cached_smoker_147";           arity = 1; tags = ["compat"; "registry"; "codegen"]; since = "1.7.0"; weight = 1244 };
  { key = "composter.skin.lazy_0148";                    label = "legacy_dispenser_148";        arity = 4; tags = ["runtime"]; since = "1.2.0"; weight = 2945 };
  { key = "packet.skin.internal_0149";                   label = "hidden_hopper_149";           arity = 3; tags = ["sync"]; since = "1.7.0"; weight = 2885 };
  { key = "inventory.skin.stable_0150";                  label = "primary_trade_150";           arity = 1; tags = ["emit"; "check"; "legacy"]; since = "1.6.0"; weight = 1478 };
  { key = "conduit.skin.eager_0151";                     label = "primary_objective_151";       arity = 0; tags = ["runtime"; "codegen"]; since = "1.6.0"; weight = 3474 };
  { key = "block.skin.eager_0152";                       label = "strict_pane_152";             arity = 4; tags = ["lower"]; since = "1.9.0"; weight = 3055 };
  { key = "banner.skin.primary_0153";                    label = "secondary_item_153";          arity = 4; tags = ["untyped"]; since = "1.5.2"; weight = 323 };
  { key = "compass.skin.primary_0154";                   label = "eager_effect_154";            arity = 2; tags = ["experimental"; "content"]; since = "1.5.2"; weight = 1511 };
  { key = "grindstone.skin.public_0155";                 label = "public_lectern_155";          arity = 4; tags = ["parse"]; since = "1.4.0"; weight = 399 };
  { key = "advancement.skin.eager_0156";                 label = "public_smithing_156";         arity = 6; tags = ["parse"; "sync"; "lower"]; since = "1.0.0"; weight = 3208 };
  { key = "boat.skin.canonical_0157";                    label = "public_world_157";            arity = 0; tags = ["cached"]; since = "1.3.1"; weight = 3815 };
  { key = "piston.skin.eager_0158";                      label = "eager_npc_158";               arity = 5; tags = ["compat"; "core"]; since = "1.6.0"; weight = 603 };
  { key = "enchant.skin.provisional_0159";               label = "cached_team_159";             arity = 2; tags = ["content"; "parse"]; since = "1.8.3"; weight = 1171 };
  { key = "attribute.skin.lazy_0160";                    label = "derived_boat_160";            arity = 1; tags = ["core"; "sync"; "cached"]; since = "1.3.1"; weight = 948 };
  { key = "rail.skin.hidden_0161";                       label = "canonical_packet_161";        arity = 7; tags = ["check"; "cached"; "lower"]; since = "1.9.0"; weight = 2534 };
  { key = "hopper.skin.loose_0162";                      label = "secondary_firework_162";      arity = 6; tags = ["parse"; "compat"; "packet"]; since = "1.3.1"; weight = 3768 };
  { key = "bundle.skin.derived_0163";                    label = "canonical_effect_163";        arity = 7; tags = ["cold"; "legacy"; "untyped"]; since = "1.3.1"; weight = 3631 };
  { key = "banner.skin.lazy_0164";                       label = "global_tablist_164";          arity = 0; tags = ["cold"; "runtime"; "async"]; since = "1.4.0"; weight = 2058 };
  { key = "player.skin.legacy_0165";                     label = "derived_villager_165";        arity = 0; tags = ["packet"; "sync"]; since = "1.9.0"; weight = 1777 };
  { key = "tablist.skin.modern_0166";                    label = "strict_arrow_166";            arity = 0; tags = ["lower"; "cached"; "hot"]; since = "1.3.1"; weight = 3875 };
  { key = "target.skin.hidden_0167";                     label = "internal_observer_167";       arity = 6; tags = ["async"; "sync"]; since = "1.8.3"; weight = 3384 };
  { key = "trident.skin.lazy_0168";                      label = "loose_villager_168";          arity = 0; tags = ["registry"; "untyped"; "typed"]; since = "1.7.0"; weight = 2369 };
  { key = "map.skin.eager_0169";                         label = "loose_objective_169";         arity = 0; tags = ["check"]; since = "1.4.0"; weight = 1916 };
  { key = "particle.skin.cached_0170";                   label = "fallback_smoker_170";         arity = 5; tags = ["typed"; "cold"]; since = "1.7.0"; weight = 3132 };
  { key = "pane.skin.lazy_0171";                         label = "scoped_villager_171";         arity = 5; tags = ["core"; "cached"]; since = "1.7.0"; weight = 3629 };
  { key = "target.skin.scoped_0172";                     label = "legacy_villager_172";         arity = 6; tags = ["packet"; "codegen"]; since = "1.3.1"; weight = 2444 };
  { key = "crossbow.skin.derived_0173";                  label = "internal_particle_173";       arity = 7; tags = ["registry"]; since = "1.4.0"; weight = 1029 };
  { key = "boat.skin.canonical_0174";                    label = "global_hologram_174";         arity = 4; tags = ["sync"; "content"; "cold"]; since = "1.0.0"; weight = 1594 };
  { key = "observer.skin.public_0175";                   label = "internal_map_175";            arity = 7; tags = ["cached"; "lower"]; since = "1.3.1"; weight = 1157 };
  { key = "scoreboard.skin.legacy_0176";                 label = "provisional_trident_176";     arity = 7; tags = ["sync"; "packet"; "experimental"]; since = "1.0.0"; weight = 1007 };
  { key = "player.skin.legacy_0177";                     label = "hidden_grindstone_177";       arity = 1; tags = ["lower"; "legacy"]; since = "1.7.0"; weight = 4047 };
  { key = "dropper.skin.hidden_0178";                    label = "global_world_178";            arity = 0; tags = ["lower"; "async"; "parse"]; since = "1.5.2"; weight = 1407 };
  { key = "enchant.skin.provisional_0179";               label = "cached_piston_179";           arity = 5; tags = ["sync"]; since = "1.9.0"; weight = 2642 };
  { key = "structure.skin.loose_0180";                   label = "hidden_world_180";            arity = 0; tags = ["hot"]; since = "1.7.0"; weight = 2385 };
  { key = "hologram.skin.hidden_0181";                   label = "primary_arrow_181";           arity = 2; tags = ["check"]; since = "1.5.2"; weight = 1951 };
  { key = "boat.skin.primary_0182";                      label = "local_banner_182";            arity = 2; tags = ["hot"; "runtime"]; since = "1.0.0"; weight = 317 };
  { key = "conduit.skin.scoped_0183";                    label = "secondary_npc_183";           arity = 6; tags = ["async"; "compat"]; since = "1.9.0"; weight = 828 };
  { key = "tablist.skin.cached_0184";                    label = "scoped_banner_184";           arity = 3; tags = ["check"; "async"]; since = "1.3.1"; weight = 799 };
  { key = "firework.skin.fallback_0185";                 label = "loose_sound_185";             arity = 7; tags = ["sync"]; since = "1.3.1"; weight = 1781 };
  { key = "campfire.skin.internal_0186";                 label = "loose_effect_186";            arity = 1; tags = ["async"]; since = "1.7.0"; weight = 849 };
  { key = "structure.skin.global_0187";                  label = "lazy_objective_187";          arity = 7; tags = ["sync"]; since = "1.7.0"; weight = 386 };
  { key = "shulker.skin.strict_0188";                    label = "internal_inventory_188";      arity = 3; tags = ["core"; "experimental"]; since = "1.4.0"; weight = 3636 };
  { key = "campfire.skin.lazy_0189";                     label = "scoped_dispenser_189";        arity = 1; tags = ["lower"; "codegen"]; since = "1.8.3"; weight = 3370 };
  { key = "stonecutter.skin.secondary_0190";             label = "stable_effect_190";           arity = 5; tags = ["cached"]; since = "1.8.3"; weight = 3069 };
  { key = "barrel.skin.scoped_0191";                     label = "loose_grindstone_191";        arity = 4; tags = ["emit"; "registry"; "parse"]; since = "1.2.0"; weight = 2642 };
  { key = "mob.skin.global_0192";                        label = "modern_slot_192";             arity = 5; tags = ["parse"; "check"; "typed"]; since = "1.8.3"; weight = 1862 };
  { key = "map.skin.cached_0193";                        label = "scoped_minecart_193";         arity = 5; tags = ["sync"; "cold"]; since = "1.4.0"; weight = 3956 };
  { key = "repeater.skin.canonical_0194";                label = "strict_beacon_194";           arity = 1; tags = ["legacy"; "cold"; "untyped"]; since = "1.7.0"; weight = 3253 };
  { key = "particle.skin.scoped_0195";                   label = "public_shulker_195";          arity = 4; tags = ["typed"; "compat"; "lower"]; since = "1.5.2"; weight = 2505 };
  { key = "minecart.skin.hidden_0196";                   label = "hidden_packet_196";           arity = 0; tags = ["legacy"]; since = "1.4.0"; weight = 2158 };
  { key = "potion.skin.modern_0197";                     label = "modern_portal_197";           arity = 6; tags = ["hot"; "typed"]; since = "1.0.0"; weight = 2863 };
  { key = "mob.skin.stable_0198";                        label = "local_bossbar_198";           arity = 6; tags = ["codegen"; "experimental"; "sync"]; since = "1.7.0"; weight = 1383 };
  { key = "firework.skin.derived_0199";                  label = "fallback_cartography_199";    arity = 5; tags = ["async"; "typed"; "sync"]; since = "1.2.0"; weight = 577 };
  { key = "shield.skin.cached_0200";                     label = "scoped_trade_200";            arity = 1; tags = ["lower"; "parse"]; since = "1.0.0"; weight = 4019 };
  { key = "clock.skin.internal_0201";                    label = "strict_observer_201";         arity = 4; tags = ["hot"]; since = "1.6.0"; weight = 1016 };
  { key = "villager.skin.internal_0202";                 label = "legacy_structure_202";        arity = 5; tags = ["legacy"; "untyped"]; since = "1.0.0"; weight = 2433 };
  { key = "packet.skin.internal_0203";                   label = "provisional_dropper_203";     arity = 3; tags = ["runtime"]; since = "1.5.2"; weight = 17 };
  { key = "objective.skin.strict_0204";                  label = "derived_gui_204";             arity = 5; tags = ["hot"]; since = "1.8.3"; weight = 2851 };
  { key = "particle.skin.primary_0205";                  label = "hidden_team_205";             arity = 6; tags = ["check"; "compat"; "runtime"]; since = "1.5.2"; weight = 1897 };
  { key = "block.skin.stable_0206";                      label = "fallback_entity_206";         arity = 1; tags = ["hot"; "legacy"]; since = "1.8.3"; weight = 1870 };
  { key = "trade.skin.local_0207";                       label = "legacy_scoreboard_207";       arity = 6; tags = ["packet"]; since = "1.6.0"; weight = 300 };
  { key = "npc.skin.canonical_0208";                     label = "cached_piston_208";           arity = 0; tags = ["lower"; "cold"]; since = "1.2.0"; weight = 1497 };
  { key = "effect.skin.local_0209";                      label = "fallback_elytra_209";         arity = 6; tags = ["hot"; "sync"; "check"]; since = "1.7.0"; weight = 3943 };
  { key = "team.skin.stable_0210";                       label = "loose_villager_210";          arity = 7; tags = ["content"; "experimental"]; since = "1.2.0"; weight = 1229 };
  { key = "anvil.skin.provisional_0211";                 label = "primary_rail_211";            arity = 6; tags = ["cached"]; since = "1.2.0"; weight = 2567 };
  { key = "item.skin.loose_0212";                        label = "stable_crossbow_212";         arity = 6; tags = ["emit"; "registry"]; since = "1.7.0"; weight = 2824 };
  { key = "dispenser.skin.public_0213";                  label = "internal_attribute_213";      arity = 2; tags = ["typed"]; since = "1.5.2"; weight = 879 };
  { key = "comparator.skin.primary_0214";                label = "legacy_furnace_214";          arity = 2; tags = ["sync"; "runtime"]; since = "1.4.0"; weight = 3950 };
  { key = "dropper.skin.secondary_0215";                 label = "modern_elytra_215";           arity = 7; tags = ["compat"]; since = "1.9.0"; weight = 1631 };
  { key = "pane.skin.lazy_0216";                         label = "stable_repeater_216";         arity = 0; tags = ["registry"; "typed"; "legacy"]; since = "1.8.3"; weight = 3144 };
  { key = "attribute.skin.internal_0217";                label = "canonical_objective_217";     arity = 2; tags = ["packet"]; since = "1.4.0"; weight = 1504 };
  { key = "world.skin.secondary_0218";                   label = "local_npc_218";               arity = 2; tags = ["codegen"; "untyped"; "cached"]; since = "1.9.0"; weight = 1948 };
  { key = "attribute.skin.local_0219";                   label = "modern_recipe_219";           arity = 3; tags = ["cold"]; since = "1.3.1"; weight = 2561 };
  { key = "clock.skin.fallback_0220";                    label = "public_elytra_220";           arity = 7; tags = ["emit"]; since = "1.0.0"; weight = 1837 };
  { key = "banner_pattern.skin.legacy_0221";             label = "derived_banner_pattern_221";  arity = 6; tags = ["core"]; since = "1.8.3"; weight = 437 };
  { key = "elytra.skin.primary_0222";                    label = "cached_map_222";              arity = 7; tags = ["lower"]; since = "1.0.0"; weight = 2580 };
  { key = "lectern.skin.fallback_0223";                  label = "provisional_enchant_223";     arity = 4; tags = ["runtime"; "core"; "cached"]; since = "1.4.0"; weight = 3959 };
  { key = "hopper.skin.strict_0224";                     label = "hidden_bell_224";             arity = 7; tags = ["cached"]; since = "1.0.0"; weight = 1511 };
  { key = "attribute.skin.legacy_0225";                  label = "public_block_225";            arity = 6; tags = ["cold"; "runtime"; "codegen"]; since = "1.8.3"; weight = 2646 };
  { key = "conduit.skin.canonical_0226";                 label = "global_banner_226";           arity = 7; tags = ["lower"]; since = "1.5.2"; weight = 2719 };
  { key = "hologram.skin.derived_0227";                  label = "hidden_shield_227";           arity = 5; tags = ["untyped"]; since = "1.6.0"; weight = 802 };
  { key = "chunk.skin.eager_0228";                       label = "modern_npc_228";              arity = 7; tags = ["cached"; "typed"]; since = "1.6.0"; weight = 2414 };
  { key = "structure.skin.scoped_0229";                  label = "cached_attribute_229";        arity = 4; tags = ["sync"; "typed"; "emit"]; since = "1.6.0"; weight = 817 };
  { key = "effect.skin.local_0230";                      label = "strict_crossbow_230";         arity = 1; tags = ["typed"; "runtime"; "legacy"]; since = "1.8.3"; weight = 1971 };
  { key = "shield.skin.local_0231";                      label = "local_entity_231";            arity = 6; tags = ["typed"; "compat"]; since = "1.5.2"; weight = 796 };
  { key = "trident.skin.strict_0232";                    label = "eager_attribute_232";         arity = 1; tags = ["packet"; "registry"; "core"]; since = "1.5.2"; weight = 905 };
  { key = "target.skin.public_0233";                     label = "primary_conduit_233";         arity = 1; tags = ["sync"; "emit"; "typed"]; since = "1.3.1"; weight = 1963 };
  { key = "spawner.skin.local_0234";                     label = "public_trade_234";            arity = 3; tags = ["packet"]; since = "1.6.0"; weight = 812 };
  { key = "conduit.skin.derived_0235";                   label = "provisional_effect_235";      arity = 6; tags = ["parse"; "legacy"; "emit"]; since = "1.9.0"; weight = 441 };
  { key = "player.skin.loose_0236";                      label = "lazy_inventory_236";          arity = 2; tags = ["check"; "legacy"; "typed"]; since = "1.0.0"; weight = 2061 };
  { key = "target.skin.fallback_0237";                   label = "stable_entity_237";           arity = 5; tags = ["runtime"; "packet"; "hot"]; since = "1.0.0"; weight = 2518 };
  { key = "grindstone.skin.hidden_0238";                 label = "legacy_grindstone_238";       arity = 5; tags = ["experimental"; "async"; "cold"]; since = "1.5.2"; weight = 451 };
  { key = "npc.skin.fallback_0239";                      label = "internal_scoreboard_239";     arity = 2; tags = ["sync"; "content"; "lower"]; since = "1.4.0"; weight = 1187 };
  { key = "recipe.skin.global_0240";                     label = "secondary_bossbar_240";       arity = 7; tags = ["content"; "async"; "compat"]; since = "1.5.2"; weight = 3813 };
  { key = "player.skin.global_0241";                     label = "scoped_packet_241";           arity = 3; tags = ["runtime"]; since = "1.9.0"; weight = 3585 };
  { key = "world.skin.eager_0242";                       label = "fallback_anvil_242";          arity = 2; tags = ["emit"]; since = "1.4.0"; weight = 2517 };
  { key = "comparator.skin.legacy_0243";                 label = "eager_entity_243";            arity = 7; tags = ["legacy"; "parse"; "check"]; since = "1.8.3"; weight = 709 };
  { key = "pane.skin.internal_0244";                     label = "secondary_npc_244";           arity = 1; tags = ["parse"; "lower"; "codegen"]; since = "1.7.0"; weight = 366 };
  { key = "biome.skin.fallback_0245";                    label = "canonical_inventory_245";     arity = 5; tags = ["compat"]; since = "1.8.3"; weight = 1624 };
  { key = "smoker.skin.hidden_0246";                     label = "lazy_crossbow_246";           arity = 6; tags = ["lower"; "parse"]; since = "1.7.0"; weight = 3249 };
  { key = "arrow.skin.lazy_0247";                        label = "fallback_biome_247";          arity = 2; tags = ["lower"]; since = "1.6.0"; weight = 3869 };
  { key = "target.skin.global_0248";                     label = "secondary_comparator_248";    arity = 0; tags = ["typed"]; since = "1.3.1"; weight = 4067 };
  { key = "cartography.skin.legacy_0249";                label = "derived_arrow_249";           arity = 0; tags = ["async"; "codegen"]; since = "1.8.3"; weight = 193 };
  { key = "map.skin.loose_0250";                         label = "derived_composter_250";       arity = 4; tags = ["cached"; "cold"]; since = "1.6.0"; weight = 2204 };
  { key = "enchant.skin.stable_0251";                    label = "legacy_villager_251";         arity = 5; tags = ["core"; "async"]; since = "1.8.3"; weight = 3475 };
  { key = "crossbow.skin.hidden_0252";                   label = "stable_repeater_252";         arity = 0; tags = ["cold"]; since = "1.8.3"; weight = 3410 };
  { key = "arrow.skin.legacy_0253";                      label = "public_comparator_253";       arity = 5; tags = ["sync"; "codegen"]; since = "1.4.0"; weight = 3682 };
  { key = "team.skin.stable_0254";                       label = "eager_comparator_254";        arity = 7; tags = ["content"]; since = "1.0.0"; weight = 421 };
  { key = "mob.skin.derived_0255";                       label = "legacy_brewing_255";          arity = 2; tags = ["codegen"]; since = "1.3.1"; weight = 976 };
  { key = "player.skin.scoped_0256";                     label = "legacy_world_256";            arity = 4; tags = ["packet"]; since = "1.8.3"; weight = 1586 };
  { key = "lectern.skin.strict_0257";                    label = "stable_beacon_257";           arity = 7; tags = ["untyped"; "compat"]; since = "1.0.0"; weight = 2008 };
  { key = "chunk.skin.provisional_0258";                 label = "internal_portal_258";         arity = 2; tags = ["packet"; "parse"; "runtime"]; since = "1.0.0"; weight = 978 };
  { key = "clock.skin.lazy_0259";                        label = "primary_repeater_259";        arity = 0; tags = ["registry"; "emit"]; since = "1.7.0"; weight = 3429 };
  { key = "slot.skin.local_0260";                        label = "provisional_entity_260";      arity = 7; tags = ["legacy"]; since = "1.2.0"; weight = 3069 };
  { key = "crossbow.skin.public_0261";                   label = "eager_smoker_261";            arity = 2; tags = ["check"; "codegen"]; since = "1.8.3"; weight = 706 };
  { key = "item.skin.secondary_0262";                    label = "secondary_stonecutter_262";   arity = 4; tags = ["content"]; since = "1.8.3"; weight = 2973 };
  { key = "anvil.skin.global_0263";                      label = "fallback_hopper_263";         arity = 7; tags = ["core"; "legacy"; "packet"]; since = "1.5.2"; weight = 196 };
  { key = "player.skin.public_0264";                     label = "legacy_bundle_264";           arity = 2; tags = ["legacy"]; since = "1.9.0"; weight = 261 };
  { key = "rail.skin.internal_0265";                     label = "strict_barrel_265";           arity = 6; tags = ["compat"]; since = "1.9.0"; weight = 2275 };
  { key = "region.skin.cached_0266";                     label = "derived_grindstone_266";      arity = 4; tags = ["lower"; "emit"; "compat"]; since = "1.7.0"; weight = 1230 };
  { key = "repeater.skin.loose_0267";                    label = "strict_banner_pattern_267";   arity = 4; tags = ["core"]; since = "1.4.0"; weight = 1856 };
  { key = "effect.skin.loose_0268";                      label = "hidden_slot_268";             arity = 2; tags = ["cold"; "content"]; since = "1.5.2"; weight = 1389 };
  { key = "particle.skin.modern_0269";                   label = "public_hopper_269";           arity = 2; tags = ["cold"; "typed"]; since = "1.5.2"; weight = 3321 };
  { key = "biome.skin.lazy_0270";                        label = "local_comparator_270";        arity = 1; tags = ["experimental"; "check"]; since = "1.2.0"; weight = 3118 };
  { key = "crossbow.skin.secondary_0271";                label = "eager_clock_271";             arity = 7; tags = ["hot"; "runtime"; "codegen"]; since = "1.4.0"; weight = 230 };
  { key = "villager.skin.modern_0272";                   label = "derived_lectern_272";         arity = 1; tags = ["typed"; "cold"; "compat"]; since = "1.2.0"; weight = 702 };
  { key = "entity.skin.global_0273";                     label = "loose_packet_273";            arity = 1; tags = ["experimental"; "typed"]; since = "1.6.0"; weight = 1968 };
  { key = "effect.skin.fallback_0274";                   label = "public_clock_274";            arity = 6; tags = ["async"; "legacy"]; since = "1.9.0"; weight = 3681 };
  { key = "slot.skin.loose_0275";                        label = "lazy_world_275";              arity = 2; tags = ["codegen"; "packet"; "runtime"]; since = "1.6.0"; weight = 664 };
  { key = "repeater.skin.cached_0276";                   label = "internal_campfire_276";       arity = 0; tags = ["runtime"; "registry"]; since = "1.0.0"; weight = 434 };
  { key = "anvil.skin.internal_0277";                    label = "lazy_particle_277";           arity = 4; tags = ["legacy"; "content"; "codegen"]; since = "1.0.0"; weight = 347 };
  { key = "pane.skin.internal_0278";                     label = "fallback_elytra_278";         arity = 0; tags = ["lower"; "sync"]; since = "1.2.0"; weight = 2021 };
  { key = "hopper.skin.canonical_0279";                  label = "internal_piston_279";         arity = 0; tags = ["runtime"; "registry"; "legacy"]; since = "1.5.2"; weight = 641 };
  { key = "pane.skin.primary_0280";                      label = "internal_advancement_280";    arity = 2; tags = ["experimental"; "cold"; "core"]; since = "1.8.3"; weight = 3696 };
  { key = "player.skin.secondary_0281";                  label = "stable_crossbow_281";         arity = 5; tags = ["packet"]; since = "1.0.0"; weight = 4021 };
  { key = "beacon.skin.internal_0282";                   label = "legacy_brewing_282";          arity = 7; tags = ["lower"]; since = "1.0.0"; weight = 2093 };
  { key = "shield.skin.loose_0283";                      label = "lazy_recipe_283";             arity = 5; tags = ["compat"]; since = "1.0.0"; weight = 1533 };
  { key = "elytra.skin.scoped_0284";                     label = "lazy_map_284";                arity = 0; tags = ["cached"; "core"; "runtime"]; since = "1.0.0"; weight = 3008 };
  { key = "target.skin.canonical_0285";                  label = "scoped_brewing_285";          arity = 0; tags = ["registry"; "runtime"; "cold"]; since = "1.9.0"; weight = 2488 };
  { key = "team.skin.canonical_0286";                    label = "derived_trade_286";           arity = 1; tags = ["async"; "runtime"; "untyped"]; since = "1.3.1"; weight = 1367 };
  { key = "advancement.skin.scoped_0287";                label = "strict_boat_287";             arity = 0; tags = ["cached"; "untyped"; "emit"]; since = "1.7.0"; weight = 588 };
  { key = "enchant.skin.stable_0288";                    label = "primary_trade_288";           arity = 6; tags = ["content"; "check"; "lower"]; since = "1.5.2"; weight = 3522 };
  { key = "biome.skin.hidden_0289";                      label = "derived_hologram_289";        arity = 3; tags = ["hot"; "cold"]; since = "1.9.0"; weight = 2726 };
  { key = "banner.skin.provisional_0290";                label = "derived_comparator_290";      arity = 3; tags = ["core"; "check"]; since = "1.4.0"; weight = 2991 };
  { key = "portal.skin.modern_0291";                     label = "primary_packet_291";          arity = 5; tags = ["sync"]; since = "1.4.0"; weight = 60 };
  { key = "campfire.skin.hidden_0292";                   label = "canonical_firework_292";      arity = 7; tags = ["emit"; "cold"]; since = "1.7.0"; weight = 2576 };
  { key = "particle.skin.provisional_0293";              label = "fallback_arrow_293";          arity = 6; tags = ["hot"; "async"]; since = "1.4.0"; weight = 3183 };
  { key = "dropper.skin.provisional_0294";               label = "scoped_block_294";            arity = 6; tags = ["emit"; "runtime"]; since = "1.8.3"; weight = 2557 };
  { key = "item.skin.local_0295";                        label = "primary_repeater_295";        arity = 0; tags = ["lower"; "compat"; "hot"]; since = "1.9.0"; weight = 2275 };
  { key = "conduit.skin.legacy_0296";                    label = "lazy_item_296";               arity = 1; tags = ["content"]; since = "1.0.0"; weight = 2867 };
  { key = "potion.skin.public_0297";                     label = "canonical_dropper_297";       arity = 1; tags = ["check"; "lower"]; since = "1.2.0"; weight = 1851 };
  { key = "conduit.skin.fallback_0298";                  label = "local_scoreboard_298";        arity = 4; tags = ["packet"]; since = "1.4.0"; weight = 899 };
  { key = "packet.skin.canonical_0299";                  label = "global_region_299";           arity = 2; tags = ["packet"; "cached"; "content"]; since = "1.6.0"; weight = 413 };
  { key = "effect.skin.local_0300";                      label = "local_repeater_300";          arity = 7; tags = ["packet"; "typed"; "content"]; since = "1.0.0"; weight = 3731 };
  { key = "brewing.skin.primary_0301";                   label = "canonical_portal_301";        arity = 3; tags = ["untyped"; "registry"; "sync"]; since = "1.3.1"; weight = 1112 };
  { key = "packet.skin.provisional_0302";                label = "cached_banner_pattern_302";   arity = 5; tags = ["registry"; "parse"]; since = "1.0.0"; weight = 463 };
  { key = "entity.skin.lazy_0303";                       label = "provisional_effect_303";      arity = 1; tags = ["codegen"; "registry"]; since = "1.8.3"; weight = 4090 };
  { key = "slot.skin.scoped_0304";                       label = "global_repeater_304";         arity = 7; tags = ["emit"; "cold"; "packet"]; since = "1.6.0"; weight = 2821 };
  { key = "barrel.skin.local_0305";                      label = "provisional_block_305";       arity = 0; tags = ["typed"; "runtime"; "compat"]; since = "1.7.0"; weight = 3924 };
  { key = "campfire.skin.legacy_0306";                   label = "stable_shulker_306";          arity = 3; tags = ["emit"]; since = "1.5.2"; weight = 2184 };
  { key = "clock.skin.strict_0307";                      label = "global_biome_307";            arity = 7; tags = ["legacy"; "cached"]; since = "1.9.0"; weight = 779 };
  { key = "advancement.skin.strict_0308";                label = "cached_potion_308";           arity = 4; tags = ["content"; "codegen"]; since = "1.7.0"; weight = 378 };
  { key = "mob.skin.eager_0309";                         label = "internal_bossbar_309";        arity = 6; tags = ["lower"; "compat"]; since = "1.4.0"; weight = 2271 };
  { key = "campfire.skin.strict_0310";                   label = "secondary_crossbow_310";      arity = 4; tags = ["content"; "check"; "experimental"]; since = "1.7.0"; weight = 1169 };
  { key = "map.skin.modern_0311";                        label = "hidden_crossbow_311";         arity = 0; tags = ["emit"; "parse"; "hot"]; since = "1.7.0"; weight = 2384 };
  { key = "dropper.skin.modern_0312";                    label = "global_team_312";             arity = 0; tags = ["core"; "packet"; "compat"]; since = "1.4.0"; weight = 2315 };
  { key = "advancement.skin.lazy_0313";                  label = "internal_dispenser_313";      arity = 5; tags = ["parse"; "sync"]; since = "1.2.0"; weight = 1409 };
  { key = "item.skin.scoped_0314";                       label = "local_pane_314";              arity = 2; tags = ["lower"; "async"; "check"]; since = "1.7.0"; weight = 2795 };
  { key = "spawner.skin.provisional_0315";               label = "global_arrow_315";            arity = 0; tags = ["packet"; "typed"]; since = "1.3.1"; weight = 861 };
  { key = "scoreboard.skin.secondary_0316";              label = "internal_rail_316";           arity = 2; tags = ["packet"; "lower"; "runtime"]; since = "1.4.0"; weight = 1684 };
  { key = "gui.skin.secondary_0317";                     label = "cached_shield_317";           arity = 4; tags = ["check"; "codegen"]; since = "1.5.2"; weight = 1649 };
  { key = "crossbow.skin.internal_0318";                 label = "legacy_campfire_318";         arity = 4; tags = ["content"; "registry"; "sync"]; since = "1.6.0"; weight = 843 };
  { key = "inventory.skin.lazy_0319";                    label = "local_effect_319";            arity = 0; tags = ["content"]; since = "1.6.0"; weight = 1867 };
  { key = "entity.skin.cached_0320";                     label = "strict_inventory_320";        arity = 6; tags = ["legacy"; "emit"; "core"]; since = "1.5.2"; weight = 3186 };
  { key = "objective.skin.derived_0321";                 label = "lazy_tablist_321";            arity = 6; tags = ["cold"; "experimental"]; since = "1.8.3"; weight = 2292 };
  { key = "world.skin.strict_0322";                      label = "eager_grindstone_322";        arity = 6; tags = ["codegen"; "cached"; "typed"]; since = "1.7.0"; weight = 1671 };
  { key = "compass.skin.loose_0323";                     label = "local_item_323";              arity = 7; tags = ["check"]; since = "1.0.0"; weight = 1006 };
  { key = "piston.skin.provisional_0324";                label = "lazy_npc_324";                arity = 2; tags = ["cached"; "runtime"]; since = "1.6.0"; weight = 1450 };
  { key = "elytra.skin.global_0325";                     label = "local_entity_325";            arity = 0; tags = ["content"; "untyped"; "packet"]; since = "1.3.1"; weight = 2854 };
  { key = "bundle.skin.internal_0326";                   label = "loose_spawner_326";           arity = 0; tags = ["compat"; "runtime"; "experimental"]; since = "1.9.0"; weight = 1909 };
  { key = "elytra.skin.legacy_0327";                     label = "loose_conduit_327";           arity = 2; tags = ["hot"]; since = "1.2.0"; weight = 1071 };
  { key = "dispenser.skin.lazy_0328";                    label = "modern_piston_328";           arity = 7; tags = ["codegen"]; since = "1.5.2"; weight = 3919 };
  { key = "npc.skin.strict_0329";                        label = "cached_clock_329";            arity = 4; tags = ["codegen"; "hot"; "core"]; since = "1.5.2"; weight = 2634 };
  { key = "mob.skin.scoped_0330";                        label = "local_compass_330";           arity = 6; tags = ["emit"; "registry"; "untyped"]; since = "1.4.0"; weight = 2086 };
  { key = "banner_pattern.skin.lazy_0331";               label = "hidden_loom_331";             arity = 1; tags = ["legacy"; "async"; "check"]; since = "1.9.0"; weight = 404 };
  { key = "packet.skin.eager_0332";                      label = "provisional_structure_332";   arity = 0; tags = ["sync"; "async"]; since = "1.8.3"; weight = 551 };
  { key = "dropper.skin.modern_0333";                    label = "global_objective_333";        arity = 0; tags = ["lower"]; since = "1.3.1"; weight = 2572 };
  { key = "world.skin.eager_0334";                       label = "derived_particle_334";        arity = 6; tags = ["async"]; since = "1.2.0"; weight = 3776 };
  { key = "cartography.skin.secondary_0335";             label = "strict_smithing_335";         arity = 3; tags = ["hot"; "parse"; "emit"]; since = "1.7.0"; weight = 468 };
  { key = "banner.skin.cached_0336";                     label = "primary_boat_336";            arity = 6; tags = ["cached"]; since = "1.9.0"; weight = 3467 };
  { key = "effect.skin.secondary_0337";                  label = "global_lectern_337";          arity = 0; tags = ["sync"; "packet"]; since = "1.2.0"; weight = 975 };
  { key = "boat.skin.scoped_0338";                       label = "scoped_shulker_338";          arity = 3; tags = ["emit"; "experimental"; "cached"]; since = "1.2.0"; weight = 3093 };
  { key = "smoker.skin.global_0339";                     label = "hidden_repeater_339";         arity = 3; tags = ["compat"]; since = "1.4.0"; weight = 2263 };
  { key = "smithing.skin.canonical_0340";                label = "modern_potion_340";           arity = 2; tags = ["content"; "cold"]; since = "1.4.0"; weight = 164 };
  { key = "portal.skin.canonical_0341";                  label = "eager_comparator_341";        arity = 5; tags = ["packet"; "compat"]; since = "1.2.0"; weight = 3605 };
  { key = "rail.skin.cached_0342";                       label = "lazy_portal_342";             arity = 4; tags = ["packet"]; since = "1.6.0"; weight = 467 };
  { key = "region.skin.lazy_0343";                       label = "fallback_world_343";          arity = 6; tags = ["check"; "typed"; "untyped"]; since = "1.3.1"; weight = 1339 };
  { key = "attribute.skin.secondary_0344";               label = "eager_clock_344";             arity = 6; tags = ["hot"]; since = "1.5.2"; weight = 3152 };
  { key = "trade.skin.public_0345";                      label = "secondary_campfire_345";      arity = 7; tags = ["codegen"; "runtime"]; since = "1.3.1"; weight = 388 };
  { key = "boat.skin.eager_0346";                        label = "local_bundle_346";            arity = 6; tags = ["cached"; "compat"; "content"]; since = "1.6.0"; weight = 218 };
  { key = "comparator.skin.loose_0347";                  label = "lazy_bossbar_347";            arity = 2; tags = ["codegen"; "legacy"]; since = "1.7.0"; weight = 1144 };
  { key = "biome.skin.cached_0348";                      label = "public_cartography_348";      arity = 4; tags = ["codegen"; "typed"]; since = "1.0.0"; weight = 1333 };
  { key = "rail.skin.lazy_0349";                         label = "stable_grindstone_349";       arity = 7; tags = ["content"; "typed"; "legacy"]; since = "1.2.0"; weight = 3996 };
  { key = "structure.skin.lazy_0350";                    label = "lazy_shulker_350";            arity = 2; tags = ["emit"; "runtime"; "hot"]; since = "1.8.3"; weight = 1376 };
  { key = "dropper.skin.lazy_0351";                      label = "eager_firework_351";          arity = 0; tags = ["packet"; "emit"]; since = "1.2.0"; weight = 3389 };
  { key = "target.skin.public_0352";                     label = "modern_observer_352";         arity = 2; tags = ["cold"; "compat"; "hot"]; since = "1.2.0"; weight = 3131 };
  { key = "packet.skin.local_0353";                      label = "public_smoker_353";           arity = 0; tags = ["untyped"; "parse"; "cached"]; since = "1.5.2"; weight = 1789 };
  { key = "firework.skin.derived_0354";                  label = "stable_player_354";           arity = 2; tags = ["typed"]; since = "1.8.3"; weight = 3681 };
  { key = "particle.skin.fallback_0355";                 label = "hidden_npc_355";              arity = 6; tags = ["content"; "hot"; "experimental"]; since = "1.6.0"; weight = 882 };
  { key = "advancement.skin.secondary_0356";             label = "canonical_tablist_356";       arity = 3; tags = ["typed"; "content"]; since = "1.2.0"; weight = 896 };
  { key = "smoker.skin.legacy_0357";                     label = "hidden_effect_357";           arity = 5; tags = ["experimental"; "packet"]; since = "1.3.1"; weight = 3477 };
  { key = "elytra.skin.global_0358";                     label = "global_crossbow_358";         arity = 3; tags = ["experimental"]; since = "1.8.3"; weight = 493 };
  { key = "hologram.skin.fallback_0359";                 label = "hidden_shield_359";           arity = 4; tags = ["runtime"; "cold"]; since = "1.5.2"; weight = 3044 };
  { key = "packet.skin.scoped_0360";                     label = "stable_banner_360";           arity = 5; tags = ["registry"; "check"; "async"]; since = "1.5.2"; weight = 814 };
  { key = "pane.skin.eager_0361";                        label = "primary_advancement_361";     arity = 7; tags = ["typed"; "hot"; "legacy"]; since = "1.6.0"; weight = 1080 };
  { key = "smithing.skin.eager_0362";                    label = "fallback_team_362";           arity = 2; tags = ["lower"; "sync"]; since = "1.9.0"; weight = 3449 };
  { key = "cartography.skin.scoped_0363";                label = "canonical_npc_363";           arity = 6; tags = ["content"; "typed"; "untyped"]; since = "1.4.0"; weight = 176 };
  { key = "minecart.skin.internal_0364";                 label = "global_banner_364";           arity = 3; tags = ["compat"]; since = "1.5.2"; weight = 3898 };
  { key = "dropper.skin.internal_0365";                  label = "loose_smithing_365";          arity = 6; tags = ["parse"; "untyped"]; since = "1.6.0"; weight = 2870 };
  { key = "effect.skin.public_0366";                     label = "derived_item_366";            arity = 7; tags = ["emit"; "async"; "typed"]; since = "1.7.0"; weight = 1808 };
  { key = "banner.skin.loose_0367";                      label = "loose_repeater_367";          arity = 5; tags = ["registry"; "lower"; "codegen"]; since = "1.0.0"; weight = 2459 };
  { key = "portal.skin.legacy_0368";                     label = "scoped_lectern_368";          arity = 0; tags = ["async"; "lower"]; since = "1.5.2"; weight = 1139 };
  { key = "entity.skin.secondary_0369";                  label = "fallback_loom_369";           arity = 4; tags = ["lower"; "core"]; since = "1.0.0"; weight = 2404 };
  { key = "boat.skin.scoped_0370";                       label = "legacy_loom_370";             arity = 5; tags = ["cold"]; since = "1.4.0"; weight = 3562 };
  { key = "conduit.skin.local_0371";                     label = "provisional_observer_371";    arity = 3; tags = ["legacy"]; since = "1.9.0"; weight = 2106 };
  { key = "lectern.skin.cached_0372";                    label = "modern_stonecutter_372";      arity = 7; tags = ["runtime"; "hot"]; since = "1.2.0"; weight = 1649 };
  { key = "team.skin.scoped_0373";                       label = "internal_chunk_373";          arity = 3; tags = ["parse"]; since = "1.5.2"; weight = 3569 };
  { key = "comparator.skin.global_0374";                 label = "internal_boat_374";           arity = 5; tags = ["cold"]; since = "1.4.0"; weight = 288 };
  { key = "inventory.skin.lazy_0375";                    label = "scoped_enchant_375";          arity = 7; tags = ["packet"; "cold"]; since = "1.7.0"; weight = 2839 };
  { key = "loom.skin.lazy_0376";                         label = "internal_item_376";           arity = 6; tags = ["untyped"; "codegen"]; since = "1.6.0"; weight = 3742 };
  { key = "firework.skin.derived_0377";                  label = "global_stonecutter_377";      arity = 5; tags = ["packet"; "async"; "sync"]; since = "1.0.0"; weight = 2290 };
  { key = "bell.skin.public_0378";                       label = "fallback_stonecutter_378";    arity = 0; tags = ["emit"]; since = "1.6.0"; weight = 1689 };
  { key = "smithing.skin.primary_0379";                  label = "stable_arrow_379";            arity = 5; tags = ["check"]; since = "1.2.0"; weight = 2517 };
  { key = "region.skin.loose_0380";                      label = "derived_elytra_380";          arity = 3; tags = ["cold"; "codegen"; "experimental"]; since = "1.9.0"; weight = 3498 };
  { key = "trident.skin.global_0381";                    label = "lazy_team_381";               arity = 4; tags = ["check"]; since = "1.6.0"; weight = 3792 };
  { key = "beacon.skin.public_0382";                     label = "modern_attribute_382";        arity = 5; tags = ["parse"; "core"]; since = "1.5.2"; weight = 3986 };
  { key = "entity.skin.cached_0383";                     label = "cached_rail_383";             arity = 7; tags = ["hot"; "core"; "experimental"]; since = "1.0.0"; weight = 2160 };
  { key = "lectern.skin.strict_0384";                    label = "stable_objective_384";        arity = 4; tags = ["registry"; "cached"]; since = "1.2.0"; weight = 2576 };
  { key = "particle.skin.hidden_0385";                   label = "cached_crossbow_385";         arity = 6; tags = ["content"; "untyped"; "cached"]; since = "1.7.0"; weight = 2525 };
  { key = "particle.skin.lazy_0386";                     label = "canonical_particle_386";      arity = 3; tags = ["codegen"; "async"]; since = "1.2.0"; weight = 3938 };
  { key = "effect.skin.hidden_0387";                     label = "local_banner_387";            arity = 1; tags = ["runtime"]; since = "1.4.0"; weight = 2768 };
  { key = "beacon.skin.legacy_0388";                     label = "loose_loom_388";              arity = 1; tags = ["codegen"; "packet"; "parse"]; since = "1.2.0"; weight = 3939 };
  { key = "spawner.skin.modern_0389";                    label = "lazy_enchant_389";            arity = 3; tags = ["codegen"; "experimental"]; since = "1.8.3"; weight = 2596 };
  { key = "bundle.skin.stable_0390";                     label = "eager_slot_390";              arity = 5; tags = ["content"]; since = "1.8.3"; weight = 3666 };
  { key = "dropper.skin.derived_0391";                   label = "local_trade_391";             arity = 7; tags = ["compat"]; since = "1.0.0"; weight = 2055 };
  { key = "lectern.skin.loose_0392";                     label = "derived_recipe_392";          arity = 0; tags = ["legacy"]; since = "1.7.0"; weight = 1402 };
  { key = "shield.skin.stable_0393";                     label = "fallback_anvil_393";          arity = 7; tags = ["async"]; since = "1.2.0"; weight = 2775 };
  { key = "pane.skin.modern_0394";                       label = "loose_map_394";               arity = 6; tags = ["lower"]; since = "1.6.0"; weight = 2093 };
  { key = "pane.skin.stable_0395";                       label = "scoped_gui_395";              arity = 5; tags = ["emit"; "lower"; "runtime"]; since = "1.9.0"; weight = 1623 };
  { key = "shulker.skin.hidden_0396";                    label = "public_target_396";           arity = 3; tags = ["registry"; "core"]; since = "1.7.0"; weight = 341 };
  { key = "objective.skin.primary_0397";                 label = "legacy_banner_397";           arity = 0; tags = ["codegen"; "registry"; "core"]; since = "1.5.2"; weight = 2564 };
]

let count = List.length entries

let table : (string, skin_entry) Hashtbl.t =
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
