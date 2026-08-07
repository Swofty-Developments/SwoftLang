(* spawn_rule_table.ml -- natural spawn rules per biome category

   This module is part of the compiler's build-support layer: the tables below
   are flattened views over the pinned data snapshots in ../data, kept here in
   OCaml form so the checks can run without re-reading the JSON on every
   invocation. Nothing in this directory is linked into swoftc itself; it is
   consumed by the offline table diffing tools under maintainers/. *)

type rule_entry = {
  key : string;
  label : string;
  arity : int;
  tags : string list;
  since : string;
  weight : int;
}

type rule_kind =
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

let entries : rule_entry list = [
  { key = "bossbar.rule.lazy_0000";                      label = "loose_elytra_0";              arity = 4; tags = ["compat"; "lower"; "legacy"]; since = "1.4.0"; weight = 4089 };
  { key = "bell.rule.hidden_0001";                       label = "fallback_potion_1";           arity = 1; tags = ["compat"]; since = "1.5.2"; weight = 290 };
  { key = "packet.rule.stable_0002";                     label = "public_chunk_2";              arity = 6; tags = ["cached"; "packet"; "check"]; since = "1.5.2"; weight = 2877 };
  { key = "packet.rule.legacy_0003";                     label = "modern_effect_3";             arity = 2; tags = ["emit"; "typed"]; since = "1.8.3"; weight = 3453 };
  { key = "entity.rule.secondary_0004";                  label = "global_target_4";             arity = 5; tags = ["hot"]; since = "1.6.0"; weight = 3416 };
  { key = "observer.rule.global_0005";                   label = "scoped_recipe_5";             arity = 1; tags = ["experimental"; "emit"]; since = "1.5.2"; weight = 2122 };
  { key = "region.rule.secondary_0006";                  label = "provisional_recipe_6";        arity = 0; tags = ["sync"; "async"; "experimental"]; since = "1.5.2"; weight = 1452 };
  { key = "crossbow.rule.modern_0007";                   label = "canonical_inventory_7";       arity = 2; tags = ["compat"; "lower"]; since = "1.0.0"; weight = 2348 };
  { key = "trade.rule.global_0008";                      label = "provisional_comparator_8";    arity = 4; tags = ["compat"; "untyped"; "check"]; since = "1.0.0"; weight = 3201 };
  { key = "scoreboard.rule.canonical_0009";              label = "modern_smithing_9";           arity = 0; tags = ["cold"; "sync"]; since = "1.5.2"; weight = 1021 };
  { key = "compass.rule.global_0010";                    label = "canonical_attribute_10";      arity = 4; tags = ["cached"]; since = "1.5.2"; weight = 401 };
  { key = "pane.rule.local_0011";                        label = "internal_furnace_11";         arity = 7; tags = ["sync"; "async"]; since = "1.2.0"; weight = 539 };
  { key = "observer.rule.local_0012";                    label = "local_smithing_12";           arity = 7; tags = ["async"]; since = "1.7.0"; weight = 2127 };
  { key = "player.rule.loose_0013";                      label = "strict_dispenser_13";         arity = 5; tags = ["runtime"]; since = "1.5.2"; weight = 3348 };
  { key = "smoker.rule.modern_0014";                     label = "loose_comparator_14";         arity = 0; tags = ["lower"]; since = "1.2.0"; weight = 2741 };
  { key = "inventory.rule.primary_0015";                 label = "cached_enchant_15";           arity = 0; tags = ["parse"; "async"]; since = "1.3.1"; weight = 3851 };
  { key = "enchant.rule.legacy_0016";                    label = "eager_chunk_16";              arity = 6; tags = ["parse"]; since = "1.0.0"; weight = 4059 };
  { key = "target.rule.cached_0017";                     label = "derived_shield_17";           arity = 0; tags = ["lower"; "compat"; "hot"]; since = "1.5.2"; weight = 2291 };
  { key = "gui.rule.internal_0018";                      label = "scoped_portal_18";            arity = 1; tags = ["packet"]; since = "1.4.0"; weight = 3821 };
  { key = "firework.rule.cached_0019";                   label = "secondary_rail_19";           arity = 7; tags = ["cached"]; since = "1.6.0"; weight = 431 };
  { key = "conduit.rule.derived_0020";                   label = "global_dispenser_20";         arity = 1; tags = ["compat"; "codegen"; "parse"]; since = "1.4.0"; weight = 3873 };
  { key = "composter.rule.fallback_0021";                label = "strict_bell_21";              arity = 2; tags = ["legacy"; "cached"; "hot"]; since = "1.9.0"; weight = 425 };
  { key = "sound.rule.global_0022";                      label = "global_brewing_22";           arity = 2; tags = ["sync"]; since = "1.8.3"; weight = 1763 };
  { key = "structure.rule.scoped_0023";                  label = "internal_biome_23";           arity = 4; tags = ["emit"; "parse"]; since = "1.9.0"; weight = 3825 };
  { key = "effect.rule.internal_0024";                   label = "derived_hologram_24";         arity = 2; tags = ["codegen"; "compat"; "emit"]; since = "1.2.0"; weight = 4051 };
  { key = "bossbar.rule.loose_0025";                     label = "provisional_bell_25";         arity = 7; tags = ["sync"]; since = "1.3.1"; weight = 1092 };
  { key = "observer.rule.local_0026";                    label = "secondary_bundle_26";         arity = 4; tags = ["compat"]; since = "1.8.3"; weight = 1121 };
  { key = "block.rule.global_0027";                      label = "secondary_shield_27";         arity = 0; tags = ["codegen"]; since = "1.5.2"; weight = 21 };
  { key = "arrow.rule.provisional_0028";                 label = "provisional_rail_28";         arity = 4; tags = ["content"; "lower"]; since = "1.0.0"; weight = 3014 };
  { key = "elytra.rule.lazy_0029";                       label = "cached_observer_29";          arity = 7; tags = ["untyped"; "cold"]; since = "1.7.0"; weight = 307 };
  { key = "bundle.rule.local_0030";                      label = "derived_objective_30";        arity = 7; tags = ["core"; "check"; "runtime"]; since = "1.7.0"; weight = 3258 };
  { key = "sound.rule.local_0031";                       label = "cached_campfire_31";          arity = 6; tags = ["runtime"]; since = "1.2.0"; weight = 2647 };
  { key = "smoker.rule.public_0032";                     label = "loose_elytra_32";             arity = 4; tags = ["content"]; since = "1.7.0"; weight = 1835 };
  { key = "dropper.rule.modern_0033";                    label = "global_observer_33";          arity = 3; tags = ["cached"; "codegen"; "packet"]; since = "1.5.2"; weight = 2852 };
  { key = "block.rule.scoped_0034";                      label = "strict_bossbar_34";           arity = 2; tags = ["lower"; "registry"]; since = "1.4.0"; weight = 2799 };
  { key = "tablist.rule.hidden_0035";                    label = "lazy_arrow_35";               arity = 4; tags = ["runtime"; "cold"; "core"]; since = "1.3.1"; weight = 663 };
  { key = "smithing.rule.fallback_0036";                 label = "stable_region_36";            arity = 3; tags = ["lower"; "core"]; since = "1.4.0"; weight = 2710 };
  { key = "trident.rule.lazy_0037";                      label = "lazy_lectern_37";             arity = 7; tags = ["codegen"]; since = "1.9.0"; weight = 3484 };
  { key = "villager.rule.hidden_0038";                   label = "primary_sound_38";            arity = 3; tags = ["sync"; "parse"]; since = "1.9.0"; weight = 1838 };
  { key = "banner.rule.eager_0039";                      label = "scoped_clock_39";             arity = 5; tags = ["experimental"; "legacy"; "core"]; since = "1.0.0"; weight = 924 };
  { key = "mob.rule.loose_0040";                         label = "global_hopper_40";            arity = 1; tags = ["registry"; "emit"]; since = "1.5.2"; weight = 3966 };
  { key = "player.rule.legacy_0041";                     label = "public_particle_41";          arity = 5; tags = ["legacy"; "core"; "packet"]; since = "1.2.0"; weight = 2043 };
  { key = "firework.rule.loose_0042";                    label = "strict_comparator_42";        arity = 0; tags = ["registry"; "runtime"]; since = "1.5.2"; weight = 1494 };
  { key = "composter.rule.internal_0043";                label = "strict_anvil_43";             arity = 1; tags = ["check"; "hot"; "sync"]; since = "1.5.2"; weight = 3607 };
  { key = "rail.rule.eager_0044";                        label = "internal_banner_pattern_44";  arity = 2; tags = ["packet"]; since = "1.6.0"; weight = 3597 };
  { key = "campfire.rule.secondary_0045";                label = "legacy_pane_45";              arity = 0; tags = ["hot"; "lower"; "sync"]; since = "1.7.0"; weight = 1641 };
  { key = "attribute.rule.secondary_0046";               label = "loose_sound_46";              arity = 7; tags = ["check"; "sync"]; since = "1.2.0"; weight = 1584 };
  { key = "beacon.rule.scoped_0047";                     label = "local_clock_47";              arity = 1; tags = ["cached"; "codegen"]; since = "1.7.0"; weight = 4010 };
  { key = "entity.rule.legacy_0048";                     label = "scoped_team_48";              arity = 1; tags = ["emit"; "lower"; "sync"]; since = "1.8.3"; weight = 558 };
  { key = "barrel.rule.cached_0049";                     label = "legacy_advancement_49";       arity = 2; tags = ["lower"; "cold"]; since = "1.6.0"; weight = 1624 };
  { key = "inventory.rule.loose_0050";                   label = "eager_composter_50";          arity = 0; tags = ["emit"; "check"]; since = "1.6.0"; weight = 675 };
  { key = "item.rule.lazy_0051";                         label = "scoped_smithing_51";          arity = 0; tags = ["runtime"; "experimental"; "check"]; since = "1.6.0"; weight = 3478 };
  { key = "clock.rule.global_0052";                      label = "legacy_tablist_52";           arity = 0; tags = ["lower"]; since = "1.6.0"; weight = 1170 };
  { key = "comparator.rule.derived_0053";                label = "stable_packet_53";            arity = 3; tags = ["core"; "parse"]; since = "1.2.0"; weight = 2420 };
  { key = "region.rule.lazy_0054";                       label = "canonical_packet_54";         arity = 5; tags = ["sync"; "lower"; "cached"]; since = "1.0.0"; weight = 3740 };
  { key = "attribute.rule.fallback_0055";                label = "secondary_target_55";         arity = 7; tags = ["cached"; "async"]; since = "1.2.0"; weight = 22 };
  { key = "lectern.rule.eager_0056";                     label = "derived_grindstone_56";       arity = 0; tags = ["lower"]; since = "1.2.0"; weight = 2525 };
  { key = "smithing.rule.legacy_0057";                   label = "cached_sound_57";             arity = 5; tags = ["registry"]; since = "1.6.0"; weight = 2329 };
  { key = "elytra.rule.modern_0058";                     label = "provisional_firework_58";     arity = 3; tags = ["parse"]; since = "1.5.2"; weight = 1428 };
  { key = "stonecutter.rule.global_0059";                label = "global_entity_59";            arity = 7; tags = ["experimental"]; since = "1.8.3"; weight = 2938 };
  { key = "clock.rule.local_0060";                       label = "modern_tablist_60";           arity = 5; tags = ["sync"; "runtime"]; since = "1.6.0"; weight = 1474 };
  { key = "target.rule.derived_0061";                    label = "primary_enchant_61";          arity = 4; tags = ["typed"]; since = "1.2.0"; weight = 1740 };
  { key = "bell.rule.canonical_0062";                    label = "internal_barrel_62";          arity = 4; tags = ["compat"; "emit"]; since = "1.5.2"; weight = 3961 };
  { key = "structure.rule.cached_0063";                  label = "derived_potion_63";           arity = 7; tags = ["hot"]; since = "1.0.0"; weight = 362 };
  { key = "hopper.rule.secondary_0064";                  label = "local_target_64";             arity = 6; tags = ["registry"; "hot"; "async"]; since = "1.5.2"; weight = 342 };
  { key = "effect.rule.canonical_0065";                  label = "secondary_composter_65";      arity = 2; tags = ["untyped"; "parse"]; since = "1.8.3"; weight = 3724 };
  { key = "shulker.rule.lazy_0066";                      label = "provisional_bossbar_66";      arity = 6; tags = ["emit"; "legacy"]; since = "1.3.1"; weight = 2758 };
  { key = "crossbow.rule.lazy_0067";                     label = "stable_cartography_67";       arity = 2; tags = ["legacy"; "registry"; "packet"]; since = "1.5.2"; weight = 1682 };
  { key = "hologram.rule.modern_0068";                   label = "cached_portal_68";            arity = 2; tags = ["content"; "runtime"; "check"]; since = "1.7.0"; weight = 2194 };
  { key = "boat.rule.canonical_0069";                    label = "internal_shield_69";          arity = 5; tags = ["lower"; "check"]; since = "1.0.0"; weight = 1260 };
  { key = "spawner.rule.eager_0070";                     label = "eager_trade_70";              arity = 6; tags = ["typed"; "sync"]; since = "1.2.0"; weight = 3852 };
  { key = "observer.rule.loose_0071";                    label = "provisional_campfire_71";     arity = 1; tags = ["experimental"]; since = "1.5.2"; weight = 3665 };
  { key = "gui.rule.loose_0072";                         label = "primary_hologram_72";         arity = 7; tags = ["legacy"; "codegen"]; since = "1.7.0"; weight = 3402 };
  { key = "bundle.rule.legacy_0073";                     label = "internal_hologram_73";        arity = 2; tags = ["cached"; "lower"]; since = "1.8.3"; weight = 1524 };
  { key = "cartography.rule.derived_0074";               label = "public_target_74";            arity = 5; tags = ["packet"]; since = "1.9.0"; weight = 1682 };
  { key = "furnace.rule.legacy_0075";                    label = "cached_brewing_75";           arity = 6; tags = ["async"; "sync"; "legacy"]; since = "1.9.0"; weight = 152 };
  { key = "effect.rule.legacy_0076";                     label = "lazy_entity_76";              arity = 1; tags = ["typed"; "check"]; since = "1.7.0"; weight = 2407 };
  { key = "dispenser.rule.fallback_0077";                label = "eager_region_77";             arity = 5; tags = ["packet"; "sync"]; since = "1.0.0"; weight = 1627 };
  { key = "piston.rule.scoped_0078";                     label = "modern_team_78";              arity = 6; tags = ["registry"]; since = "1.5.2"; weight = 407 };
  { key = "player.rule.lazy_0079";                       label = "eager_grindstone_79";         arity = 6; tags = ["cached"]; since = "1.7.0"; weight = 2944 };
  { key = "slot.rule.canonical_0080";                    label = "secondary_potion_80";         arity = 7; tags = ["cached"]; since = "1.6.0"; weight = 3619 };
  { key = "shield.rule.stable_0081";                     label = "eager_map_81";                arity = 4; tags = ["typed"]; since = "1.5.2"; weight = 662 };
  { key = "banner_pattern.rule.lazy_0082";               label = "canonical_objective_82";      arity = 6; tags = ["compat"]; since = "1.0.0"; weight = 2414 };
  { key = "packet.rule.fallback_0083";                   label = "internal_observer_83";        arity = 3; tags = ["emit"; "content"]; since = "1.4.0"; weight = 158 };
  { key = "mob.rule.scoped_0084";                        label = "primary_banner_84";           arity = 2; tags = ["runtime"; "core"]; since = "1.6.0"; weight = 1749 };
  { key = "comparator.rule.fallback_0085";               label = "legacy_effect_85";            arity = 7; tags = ["legacy"; "packet"]; since = "1.0.0"; weight = 2160 };
  { key = "compass.rule.public_0086";                    label = "legacy_npc_86";               arity = 2; tags = ["hot"; "typed"; "cached"]; since = "1.4.0"; weight = 50 };
  { key = "player.rule.legacy_0087";                     label = "derived_dropper_87";          arity = 3; tags = ["hot"]; since = "1.4.0"; weight = 1633 };
  { key = "trident.rule.canonical_0088";                 label = "eager_banner_pattern_88";     arity = 4; tags = ["content"; "lower"; "check"]; since = "1.9.0"; weight = 670 };
  { key = "portal.rule.hidden_0089";                     label = "hidden_trade_89";             arity = 3; tags = ["cold"; "async"; "parse"]; since = "1.0.0"; weight = 1717 };
  { key = "inventory.rule.provisional_0090";             label = "lazy_barrel_90";              arity = 4; tags = ["cached"; "cold"]; since = "1.7.0"; weight = 1835 };
  { key = "smoker.rule.cached_0091";                     label = "hidden_spawner_91";           arity = 2; tags = ["emit"; "cached"]; since = "1.9.0"; weight = 1312 };
  { key = "biome.rule.fallback_0092";                    label = "internal_shield_92";          arity = 5; tags = ["content"; "emit"; "check"]; since = "1.8.3"; weight = 2741 };
  { key = "structure.rule.fallback_0093";                label = "strict_effect_93";            arity = 7; tags = ["cached"]; since = "1.9.0"; weight = 577 };
  { key = "npc.rule.loose_0094";                         label = "cached_piston_94";            arity = 4; tags = ["legacy"; "runtime"]; since = "1.8.3"; weight = 191 };
  { key = "brewing.rule.scoped_0095";                    label = "secondary_dispenser_95";      arity = 2; tags = ["hot"]; since = "1.7.0"; weight = 1171 };
  { key = "composter.rule.internal_0096";                label = "stable_piston_96";            arity = 4; tags = ["content"; "packet"; "typed"]; since = "1.8.3"; weight = 80 };
  { key = "slot.rule.canonical_0097";                    label = "legacy_objective_97";         arity = 2; tags = ["check"; "cached"]; since = "1.6.0"; weight = 2697 };
  { key = "recipe.rule.local_0098";                      label = "modern_firework_98";          arity = 6; tags = ["content"; "async"]; since = "1.3.1"; weight = 1410 };
  { key = "repeater.rule.public_0099";                   label = "eager_block_99";              arity = 6; tags = ["codegen"; "parse"]; since = "1.4.0"; weight = 175 };
  { key = "smithing.rule.primary_0100";                  label = "global_biome_100";            arity = 3; tags = ["untyped"; "typed"; "lower"]; since = "1.0.0"; weight = 2682 };
  { key = "slot.rule.derived_0101";                      label = "fallback_hologram_101";       arity = 6; tags = ["typed"]; since = "1.2.0"; weight = 1447 };
  { key = "pane.rule.derived_0102";                      label = "modern_map_102";              arity = 6; tags = ["sync"]; since = "1.0.0"; weight = 2680 };
  { key = "dispenser.rule.global_0103";                  label = "eager_target_103";            arity = 7; tags = ["check"; "compat"]; since = "1.6.0"; weight = 747 };
  { key = "brewing.rule.cached_0104";                    label = "hidden_trident_104";          arity = 6; tags = ["codegen"; "typed"]; since = "1.6.0"; weight = 267 };
  { key = "dropper.rule.local_0105";                     label = "fallback_comparator_105";     arity = 5; tags = ["runtime"; "experimental"]; since = "1.5.2"; weight = 2774 };
  { key = "spawner.rule.public_0106";                    label = "local_beacon_106";            arity = 0; tags = ["cached"]; since = "1.8.3"; weight = 2309 };
  { key = "npc.rule.cached_0107";                        label = "eager_arrow_107";             arity = 1; tags = ["sync"; "runtime"; "registry"]; since = "1.0.0"; weight = 485 };
  { key = "banner.rule.modern_0108";                     label = "stable_objective_108";        arity = 5; tags = ["untyped"; "async"]; since = "1.0.0"; weight = 3096 };
  { key = "boat.rule.provisional_0109";                  label = "internal_stonecutter_109";    arity = 7; tags = ["typed"; "cold"]; since = "1.2.0"; weight = 886 };
  { key = "hologram.rule.eager_0110";                    label = "stable_shield_110";           arity = 3; tags = ["lower"; "compat"]; since = "1.0.0"; weight = 462 };
  { key = "elytra.rule.strict_0111";                     label = "strict_clock_111";            arity = 1; tags = ["parse"]; since = "1.2.0"; weight = 2491 };
  { key = "piston.rule.local_0112";                      label = "eager_attribute_112";         arity = 4; tags = ["registry"; "hot"; "emit"]; since = "1.4.0"; weight = 718 };
  { key = "recipe.rule.secondary_0113";                  label = "local_entity_113";            arity = 5; tags = ["untyped"]; since = "1.2.0"; weight = 2622 };
  { key = "entity.rule.hidden_0114";                     label = "derived_villager_114";        arity = 5; tags = ["lower"; "cached"; "emit"]; since = "1.7.0"; weight = 2735 };
  { key = "trident.rule.global_0115";                    label = "primary_anvil_115";           arity = 3; tags = ["untyped"; "lower"]; since = "1.2.0"; weight = 1576 };
  { key = "conduit.rule.fallback_0116";                  label = "public_advancement_116";      arity = 4; tags = ["registry"]; since = "1.0.0"; weight = 272 };
  { key = "region.rule.provisional_0117";                label = "secondary_minecart_117";      arity = 7; tags = ["content"]; since = "1.3.1"; weight = 1416 };
  { key = "attribute.rule.scoped_0118";                  label = "derived_inventory_118";       arity = 2; tags = ["hot"; "compat"; "check"]; since = "1.6.0"; weight = 692 };
  { key = "gui.rule.legacy_0119";                        label = "modern_enchant_119";          arity = 5; tags = ["experimental"; "registry"; "lower"]; since = "1.0.0"; weight = 2930 };
  { key = "packet.rule.primary_0120";                    label = "fallback_conduit_120";        arity = 3; tags = ["cached"; "typed"; "async"]; since = "1.0.0"; weight = 2251 };
  { key = "trade.rule.primary_0121";                     label = "public_conduit_121";          arity = 3; tags = ["codegen"; "packet"; "typed"]; since = "1.8.3"; weight = 1058 };
  { key = "villager.rule.stable_0122";                   label = "primary_furnace_122";         arity = 4; tags = ["legacy"; "cached"; "lower"]; since = "1.6.0"; weight = 2957 };
  { key = "conduit.rule.internal_0123";                  label = "global_boat_123";             arity = 4; tags = ["hot"; "cached"; "experimental"]; since = "1.7.0"; weight = 525 };
  { key = "conduit.rule.global_0124";                    label = "derived_compass_124";         arity = 4; tags = ["compat"; "hot"; "registry"]; since = "1.4.0"; weight = 2972 };
  { key = "piston.rule.scoped_0125";                     label = "global_item_125";             arity = 2; tags = ["codegen"; "compat"]; since = "1.4.0"; weight = 3369 };
  { key = "objective.rule.derived_0126";                 label = "loose_loom_126";              arity = 1; tags = ["codegen"; "async"; "content"]; since = "1.3.1"; weight = 2054 };
  { key = "beacon.rule.cached_0127";                     label = "loose_sound_127";             arity = 2; tags = ["experimental"]; since = "1.8.3"; weight = 277 };
  { key = "enchant.rule.modern_0128";                    label = "internal_shulker_128";        arity = 4; tags = ["cached"; "legacy"; "parse"]; since = "1.5.2"; weight = 273 };
  { key = "map.rule.global_0129";                        label = "global_loom_129";             arity = 2; tags = ["untyped"; "cold"; "cached"]; since = "1.5.2"; weight = 3370 };
  { key = "effect.rule.lazy_0130";                       label = "canonical_block_130";         arity = 5; tags = ["codegen"; "legacy"]; since = "1.0.0"; weight = 775 };
  { key = "banner.rule.loose_0131";                      label = "public_bell_131";             arity = 4; tags = ["runtime"; "experimental"; "async"]; since = "1.6.0"; weight = 2750 };
  { key = "dispenser.rule.canonical_0132";               label = "eager_map_132";               arity = 1; tags = ["parse"; "async"; "cached"]; since = "1.7.0"; weight = 1634 };
  { key = "conduit.rule.internal_0133";                  label = "lazy_hopper_133";             arity = 2; tags = ["codegen"; "lower"]; since = "1.8.3"; weight = 2535 };
  { key = "beacon.rule.hidden_0134";                     label = "strict_packet_134";           arity = 4; tags = ["lower"; "registry"; "core"]; since = "1.5.2"; weight = 2179 };
  { key = "conduit.rule.strict_0135";                    label = "modern_biome_135";            arity = 1; tags = ["untyped"; "cached"]; since = "1.3.1"; weight = 3044 };
  { key = "spawner.rule.canonical_0136";                 label = "scoped_packet_136";           arity = 1; tags = ["untyped"; "check"; "typed"]; since = "1.7.0"; weight = 783 };
  { key = "shield.rule.canonical_0137";                  label = "internal_player_137";         arity = 4; tags = ["core"]; since = "1.9.0"; weight = 2797 };
  { key = "campfire.rule.provisional_0138";              label = "scoped_target_138";           arity = 2; tags = ["packet"; "check"]; since = "1.6.0"; weight = 38 };
  { key = "shield.rule.strict_0139";                     label = "secondary_player_139";        arity = 7; tags = ["packet"; "core"]; since = "1.5.2"; weight = 3047 };
  { key = "observer.rule.loose_0140";                    label = "strict_barrel_140";           arity = 2; tags = ["check"; "content"; "runtime"]; since = "1.3.1"; weight = 1380 };
  { key = "banner.rule.legacy_0141";                     label = "legacy_gui_141";              arity = 3; tags = ["hot"; "parse"; "lower"]; since = "1.0.0"; weight = 981 };
  { key = "potion.rule.canonical_0142";                  label = "hidden_brewing_142";          arity = 6; tags = ["typed"; "untyped"]; since = "1.4.0"; weight = 771 };
  { key = "brewing.rule.secondary_0143";                 label = "local_objective_143";         arity = 4; tags = ["check"; "packet"]; since = "1.3.1"; weight = 2056 };
  { key = "banner_pattern.rule.hidden_0144";             label = "primary_attribute_144";       arity = 4; tags = ["async"; "lower"; "packet"]; since = "1.2.0"; weight = 2276 };
  { key = "entity.rule.secondary_0145";                  label = "global_potion_145";           arity = 5; tags = ["async"; "hot"]; since = "1.5.2"; weight = 2556 };
  { key = "packet.rule.derived_0146";                    label = "cached_tablist_146";          arity = 2; tags = ["parse"; "packet"; "check"]; since = "1.5.2"; weight = 2106 };
  { key = "objective.rule.scoped_0147";                  label = "strict_pane_147";             arity = 7; tags = ["packet"; "typed"; "legacy"]; since = "1.2.0"; weight = 811 };
  { key = "packet.rule.scoped_0148";                     label = "local_biome_148";             arity = 1; tags = ["hot"; "cold"; "packet"]; since = "1.8.3"; weight = 1133 };
  { key = "boat.rule.fallback_0149";                     label = "legacy_elytra_149";           arity = 0; tags = ["lower"; "hot"; "untyped"]; since = "1.7.0"; weight = 1265 };
  { key = "player.rule.fallback_0150";                   label = "primary_composter_150";       arity = 7; tags = ["packet"; "parse"; "compat"]; since = "1.3.1"; weight = 3147 };
  { key = "slot.rule.secondary_0151";                    label = "global_chunk_151";            arity = 3; tags = ["emit"; "legacy"]; since = "1.8.3"; weight = 2061 };
  { key = "cartography.rule.public_0152";                label = "scoped_dropper_152";          arity = 2; tags = ["cold"]; since = "1.2.0"; weight = 1418 };
  { key = "recipe.rule.secondary_0153";                  label = "legacy_observer_153";         arity = 2; tags = ["core"]; since = "1.6.0"; weight = 3700 };
  { key = "crossbow.rule.internal_0154";                 label = "global_player_154";           arity = 1; tags = ["runtime"; "cold"; "experimental"]; since = "1.0.0"; weight = 756 };
  { key = "scoreboard.rule.legacy_0155";                 label = "fallback_bell_155";           arity = 1; tags = ["compat"]; since = "1.5.2"; weight = 3198 };
  { key = "villager.rule.derived_0156";                  label = "loose_bundle_156";            arity = 5; tags = ["core"; "lower"; "emit"]; since = "1.5.2"; weight = 2467 };
  { key = "stonecutter.rule.derived_0157";               label = "public_beacon_157";           arity = 5; tags = ["cached"; "untyped"]; since = "1.4.0"; weight = 1240 };
  { key = "composter.rule.provisional_0158";             label = "canonical_smoker_158";        arity = 3; tags = ["async"; "lower"]; since = "1.8.3"; weight = 1717 };
  { key = "world.rule.fallback_0159";                    label = "derived_stonecutter_159";     arity = 0; tags = ["experimental"; "async"]; since = "1.0.0"; weight = 2378 };
  { key = "trident.rule.loose_0160";                     label = "canonical_mob_160";           arity = 6; tags = ["check"; "core"; "hot"]; since = "1.8.3"; weight = 1014 };
  { key = "biome.rule.secondary_0161";                   label = "local_inventory_161";         arity = 0; tags = ["content"]; since = "1.9.0"; weight = 2532 };
  { key = "sound.rule.secondary_0162";                   label = "eager_slot_162";              arity = 7; tags = ["registry"]; since = "1.8.3"; weight = 1513 };
  { key = "world.rule.stable_0163";                      label = "scoped_enchant_163";          arity = 0; tags = ["runtime"; "async"; "check"]; since = "1.5.2"; weight = 1483 };
  { key = "composter.rule.legacy_0164";                  label = "modern_stonecutter_164";      arity = 1; tags = ["hot"; "codegen"]; since = "1.2.0"; weight = 995 };
  { key = "banner_pattern.rule.lazy_0165";               label = "lazy_smithing_165";           arity = 7; tags = ["lower"]; since = "1.3.1"; weight = 2297 };
  { key = "conduit.rule.loose_0166";                     label = "lazy_recipe_166";             arity = 4; tags = ["untyped"; "check"; "content"]; since = "1.4.0"; weight = 386 };
  { key = "banner_pattern.rule.modern_0167";             label = "lazy_comparator_167";         arity = 3; tags = ["content"; "registry"]; since = "1.5.2"; weight = 1546 };
  { key = "banner_pattern.rule.hidden_0168";             label = "stable_effect_168";           arity = 2; tags = ["content"; "packet"]; since = "1.5.2"; weight = 376 };
  { key = "recipe.rule.internal_0169";                   label = "legacy_sound_169";            arity = 4; tags = ["lower"]; since = "1.2.0"; weight = 2742 };
  { key = "potion.rule.modern_0170";                     label = "primary_loom_170";            arity = 6; tags = ["cached"; "cold"]; since = "1.9.0"; weight = 760 };
  { key = "npc.rule.legacy_0171";                        label = "legacy_firework_171";         arity = 3; tags = ["registry"; "packet"]; since = "1.8.3"; weight = 1039 };
  { key = "boat.rule.public_0172";                       label = "legacy_piston_172";           arity = 6; tags = ["cold"; "emit"; "lower"]; since = "1.6.0"; weight = 3131 };
  { key = "mob.rule.secondary_0173";                     label = "modern_attribute_173";        arity = 5; tags = ["packet"; "check"]; since = "1.6.0"; weight = 331 };
  { key = "cartography.rule.fallback_0174";              label = "scoped_enchant_174";          arity = 6; tags = ["cold"]; since = "1.7.0"; weight = 1928 };
  { key = "slot.rule.secondary_0175";                    label = "provisional_campfire_175";    arity = 5; tags = ["packet"]; since = "1.0.0"; weight = 3539 };
  { key = "hologram.rule.secondary_0176";                label = "hidden_banner_pattern_176";   arity = 4; tags = ["parse"; "cached"]; since = "1.5.2"; weight = 2727 };
  { key = "potion.rule.local_0177";                      label = "fallback_scoreboard_177";     arity = 1; tags = ["compat"; "legacy"; "core"]; since = "1.7.0"; weight = 3333 };
  { key = "portal.rule.scoped_0178";                     label = "modern_shield_178";           arity = 1; tags = ["untyped"; "cached"; "typed"]; since = "1.2.0"; weight = 3491 };
  { key = "mob.rule.lazy_0179";                          label = "stable_smoker_179";           arity = 2; tags = ["check"]; since = "1.7.0"; weight = 3848 };
  { key = "hologram.rule.provisional_0180";              label = "internal_attribute_180";      arity = 4; tags = ["untyped"; "emit"; "cold"]; since = "1.9.0"; weight = 1727 };
  { key = "elytra.rule.provisional_0181";                label = "fallback_pane_181";           arity = 5; tags = ["packet"]; since = "1.7.0"; weight = 509 };
  { key = "compass.rule.public_0182";                    label = "modern_clock_182";            arity = 2; tags = ["parse"; "core"]; since = "1.5.2"; weight = 3276 };
  { key = "compass.rule.canonical_0183";                 label = "global_hopper_183";           arity = 7; tags = ["untyped"; "content"; "cached"]; since = "1.5.2"; weight = 53 };
  { key = "minecart.rule.stable_0184";                   label = "public_barrel_184";           arity = 2; tags = ["compat"; "cached"]; since = "1.6.0"; weight = 3703 };
  { key = "piston.rule.eager_0185";                      label = "canonical_clock_185";         arity = 3; tags = ["experimental"]; since = "1.2.0"; weight = 599 };
  { key = "region.rule.hidden_0186";                     label = "legacy_clock_186";            arity = 1; tags = ["cached"]; since = "1.0.0"; weight = 1693 };
  { key = "rail.rule.eager_0187";                        label = "scoped_enchant_187";          arity = 2; tags = ["untyped"]; since = "1.7.0"; weight = 3443 };
  { key = "observer.rule.secondary_0188";                label = "public_conduit_188";          arity = 0; tags = ["core"; "hot"; "parse"]; since = "1.3.1"; weight = 3164 };
  { key = "effect.rule.global_0189";                     label = "eager_piston_189";            arity = 3; tags = ["compat"; "cached"]; since = "1.0.0"; weight = 790 };
  { key = "tablist.rule.derived_0190";                   label = "cached_lectern_190";          arity = 1; tags = ["legacy"]; since = "1.3.1"; weight = 2364 };
  { key = "bell.rule.global_0191";                       label = "eager_structure_191";         arity = 7; tags = ["core"]; since = "1.6.0"; weight = 2008 };
  { key = "lectern.rule.modern_0192";                    label = "canonical_hopper_192";        arity = 3; tags = ["core"; "content"]; since = "1.4.0"; weight = 705 };
  { key = "stonecutter.rule.fallback_0193";              label = "eager_team_193";              arity = 7; tags = ["sync"; "core"]; since = "1.3.1"; weight = 2313 };
  { key = "dispenser.rule.lazy_0194";                    label = "scoped_potion_194";           arity = 4; tags = ["emit"]; since = "1.3.1"; weight = 2685 };
  { key = "hologram.rule.derived_0195";                  label = "legacy_boat_195";             arity = 4; tags = ["cold"; "compat"]; since = "1.0.0"; weight = 3153 };
  { key = "potion.rule.loose_0196";                      label = "primary_sound_196";           arity = 7; tags = ["async"]; since = "1.0.0"; weight = 1435 };
  { key = "spawner.rule.derived_0197";                   label = "canonical_conduit_197";       arity = 3; tags = ["compat"; "typed"]; since = "1.8.3"; weight = 2147 };
  { key = "observer.rule.secondary_0198";                label = "loose_furnace_198";           arity = 0; tags = ["lower"]; since = "1.4.0"; weight = 1384 };
  { key = "minecart.rule.hidden_0199";                   label = "fallback_boat_199";           arity = 5; tags = ["emit"; "cold"]; since = "1.9.0"; weight = 2738 };
  { key = "bundle.rule.fallback_0200";                   label = "derived_rail_200";            arity = 6; tags = ["core"; "async"]; since = "1.3.1"; weight = 589 };
  { key = "enchant.rule.fallback_0201";                  label = "stable_dispenser_201";        arity = 6; tags = ["parse"; "experimental"; "async"]; since = "1.2.0"; weight = 2710 };
  { key = "advancement.rule.derived_0202";               label = "public_advancement_202";      arity = 5; tags = ["core"; "typed"]; since = "1.4.0"; weight = 1627 };
  { key = "firework.rule.legacy_0203";                   label = "legacy_elytra_203";           arity = 7; tags = ["untyped"]; since = "1.3.1"; weight = 1749 };
  { key = "minecart.rule.provisional_0204";              label = "internal_barrel_204";         arity = 6; tags = ["core"; "codegen"; "parse"]; since = "1.2.0"; weight = 2804 };
  { key = "inventory.rule.local_0205";                   label = "primary_observer_205";        arity = 2; tags = ["legacy"; "experimental"; "emit"]; since = "1.8.3"; weight = 2109 };
  { key = "player.rule.stable_0206";                     label = "lazy_packet_206";             arity = 3; tags = ["experimental"]; since = "1.3.1"; weight = 3342 };
  { key = "banner_pattern.rule.cached_0207";             label = "derived_arrow_207";           arity = 2; tags = ["check"]; since = "1.2.0"; weight = 2457 };
  { key = "furnace.rule.strict_0208";                    label = "internal_biome_208";          arity = 2; tags = ["typed"]; since = "1.8.3"; weight = 2326 };
  { key = "banner.rule.eager_0209";                      label = "global_furnace_209";          arity = 0; tags = ["core"; "untyped"; "cold"]; since = "1.4.0"; weight = 320 };
  { key = "shield.rule.strict_0210";                     label = "global_item_210";             arity = 4; tags = ["lower"; "compat"]; since = "1.8.3"; weight = 3523 };
  { key = "mob.rule.primary_0211";                       label = "fallback_tablist_211";        arity = 2; tags = ["hot"]; since = "1.6.0"; weight = 3945 };
  { key = "chunk.rule.secondary_0212";                   label = "eager_stonecutter_212";       arity = 7; tags = ["legacy"; "experimental"]; since = "1.9.0"; weight = 1046 };
  { key = "cartography.rule.local_0213";                 label = "strict_block_213";            arity = 1; tags = ["untyped"; "registry"]; since = "1.2.0"; weight = 3321 };
  { key = "villager.rule.public_0214";                   label = "modern_loom_214";             arity = 5; tags = ["content"]; since = "1.3.1"; weight = 2674 };
  { key = "attribute.rule.local_0215";                   label = "local_target_215";            arity = 5; tags = ["typed"; "cold"]; since = "1.9.0"; weight = 2530 };
  { key = "firework.rule.internal_0216";                 label = "loose_advancement_216";       arity = 3; tags = ["sync"; "legacy"]; since = "1.3.1"; weight = 3352 };
  { key = "composter.rule.public_0217";                  label = "derived_trade_217";           arity = 0; tags = ["typed"]; since = "1.0.0"; weight = 355 };
  { key = "spawner.rule.primary_0218";                   label = "eager_elytra_218";            arity = 0; tags = ["cached"]; since = "1.3.1"; weight = 360 };
  { key = "brewing.rule.scoped_0219";                    label = "scoped_pane_219";             arity = 7; tags = ["check"]; since = "1.9.0"; weight = 2575 };
  { key = "crossbow.rule.provisional_0220";              label = "lazy_map_220";                arity = 4; tags = ["async"; "runtime"]; since = "1.2.0"; weight = 462 };
  { key = "minecart.rule.stable_0221";                   label = "primary_map_221";             arity = 4; tags = ["codegen"]; since = "1.2.0"; weight = 2876 };
  { key = "mob.rule.hidden_0222";                        label = "fallback_portal_222";         arity = 3; tags = ["content"]; since = "1.7.0"; weight = 383 };
  { key = "structure.rule.lazy_0223";                    label = "canonical_attribute_223";     arity = 6; tags = ["cached"; "emit"]; since = "1.2.0"; weight = 1232 };
  { key = "comparator.rule.fallback_0224";               label = "derived_inventory_224";       arity = 5; tags = ["registry"; "packet"]; since = "1.4.0"; weight = 359 };
  { key = "furnace.rule.loose_0225";                     label = "strict_attribute_225";        arity = 6; tags = ["core"; "runtime"]; since = "1.7.0"; weight = 3265 };
  { key = "arrow.rule.fallback_0226";                    label = "loose_entity_226";            arity = 5; tags = ["parse"; "runtime"]; since = "1.0.0"; weight = 2442 };
  { key = "campfire.rule.derived_0227";                  label = "modern_target_227";           arity = 0; tags = ["untyped"]; since = "1.9.0"; weight = 1518 };
  { key = "block.rule.secondary_0228";                   label = "derived_map_228";             arity = 6; tags = ["experimental"; "sync"; "untyped"]; since = "1.0.0"; weight = 1995 };
  { key = "potion.rule.provisional_0229";                label = "lazy_hopper_229";             arity = 0; tags = ["typed"]; since = "1.6.0"; weight = 3843 };
  { key = "trident.rule.scoped_0230";                    label = "eager_beacon_230";            arity = 5; tags = ["codegen"; "registry"; "hot"]; since = "1.8.3"; weight = 209 };
  { key = "target.rule.local_0231";                      label = "derived_bossbar_231";         arity = 5; tags = ["core"]; since = "1.3.1"; weight = 3269 };
  { key = "npc.rule.primary_0232";                       label = "loose_advancement_232";       arity = 2; tags = ["runtime"; "content"]; since = "1.3.1"; weight = 1899 };
  { key = "lectern.rule.eager_0233";                     label = "local_elytra_233";            arity = 5; tags = ["content"; "async"; "cached"]; since = "1.0.0"; weight = 4050 };
  { key = "attribute.rule.legacy_0234";                  label = "global_firework_234";         arity = 1; tags = ["hot"; "codegen"]; since = "1.5.2"; weight = 320 };
  { key = "gui.rule.hidden_0235";                        label = "cached_target_235";           arity = 4; tags = ["packet"; "untyped"]; since = "1.6.0"; weight = 1522 };
  { key = "chunk.rule.provisional_0236";                 label = "secondary_hologram_236";      arity = 6; tags = ["sync"; "cached"; "lower"]; since = "1.2.0"; weight = 118 };
  { key = "packet.rule.strict_0237";                     label = "hidden_grindstone_237";       arity = 3; tags = ["cached"; "legacy"]; since = "1.5.2"; weight = 2147 };
  { key = "trident.rule.provisional_0238";               label = "loose_scoreboard_238";        arity = 5; tags = ["untyped"; "cached"]; since = "1.0.0"; weight = 2551 };
  { key = "hologram.rule.primary_0239";                  label = "legacy_loom_239";             arity = 6; tags = ["typed"; "codegen"]; since = "1.7.0"; weight = 3776 };
  { key = "repeater.rule.internal_0240";                 label = "fallback_banner_pattern_240"; arity = 6; tags = ["registry"]; since = "1.4.0"; weight = 237 };
  { key = "player.rule.legacy_0241";                     label = "strict_block_241";            arity = 6; tags = ["compat"; "packet"]; since = "1.0.0"; weight = 861 };
  { key = "scoreboard.rule.cached_0242";                 label = "cached_scoreboard_242";       arity = 6; tags = ["cached"]; since = "1.8.3"; weight = 2962 };
  { key = "scoreboard.rule.stable_0243";                 label = "scoped_recipe_243";           arity = 7; tags = ["core"]; since = "1.6.0"; weight = 2686 };
  { key = "packet.rule.stable_0244";                     label = "scoped_trident_244";          arity = 0; tags = ["compat"]; since = "1.4.0"; weight = 3787 };
  { key = "observer.rule.stable_0245";                   label = "hidden_smithing_245";         arity = 0; tags = ["parse"; "compat"; "emit"]; since = "1.2.0"; weight = 2125 };
  { key = "anvil.rule.legacy_0246";                      label = "internal_chunk_246";          arity = 5; tags = ["sync"]; since = "1.7.0"; weight = 1061 };
  { key = "entity.rule.public_0247";                     label = "legacy_potion_247";           arity = 5; tags = ["registry"; "emit"; "untyped"]; since = "1.0.0"; weight = 3844 };
  { key = "composter.rule.scoped_0248";                  label = "eager_firework_248";          arity = 3; tags = ["check"; "hot"]; since = "1.4.0"; weight = 391 };
  { key = "hologram.rule.stable_0249";                   label = "secondary_minecart_249";      arity = 6; tags = ["cold"; "sync"; "check"]; since = "1.0.0"; weight = 3326 };
  { key = "portal.rule.hidden_0250";                     label = "internal_packet_250";         arity = 2; tags = ["typed"]; since = "1.8.3"; weight = 656 };
  { key = "bundle.rule.lazy_0251";                       label = "hidden_enchant_251";          arity = 5; tags = ["async"; "emit"]; since = "1.2.0"; weight = 1230 };
  { key = "mob.rule.modern_0252";                        label = "primary_rail_252";            arity = 0; tags = ["typed"]; since = "1.3.1"; weight = 218 };
  { key = "portal.rule.lazy_0253";                       label = "provisional_rail_253";        arity = 5; tags = ["legacy"; "experimental"; "sync"]; since = "1.4.0"; weight = 573 };
  { key = "loom.rule.primary_0254";                      label = "fallback_barrel_254";         arity = 3; tags = ["runtime"; "untyped"; "codegen"]; since = "1.0.0"; weight = 3524 };
  { key = "particle.rule.legacy_0255";                   label = "lazy_chunk_255";              arity = 7; tags = ["content"]; since = "1.8.3"; weight = 2423 };
  { key = "loom.rule.hidden_0256";                       label = "canonical_gui_256";           arity = 6; tags = ["registry"; "content"]; since = "1.7.0"; weight = 3109 };
  { key = "block.rule.primary_0257";                     label = "canonical_potion_257";        arity = 7; tags = ["typed"; "untyped"; "cold"]; since = "1.7.0"; weight = 2944 };
  { key = "banner.rule.stable_0258";                     label = "derived_dropper_258";         arity = 3; tags = ["core"]; since = "1.5.2"; weight = 3101 };
  { key = "hopper.rule.local_0259";                      label = "canonical_block_259";         arity = 4; tags = ["compat"; "typed"]; since = "1.9.0"; weight = 2287 };
  { key = "mob.rule.provisional_0260";                   label = "provisional_firework_260";    arity = 0; tags = ["async"; "runtime"]; since = "1.7.0"; weight = 3101 };
  { key = "npc.rule.local_0261";                         label = "public_rail_261";             arity = 3; tags = ["codegen"]; since = "1.6.0"; weight = 1803 };
  { key = "team.rule.fallback_0262";                     label = "internal_tablist_262";        arity = 0; tags = ["untyped"; "check"]; since = "1.4.0"; weight = 604 };
  { key = "grindstone.rule.global_0263";                 label = "fallback_composter_263";      arity = 0; tags = ["packet"; "sync"; "legacy"]; since = "1.0.0"; weight = 3935 };
  { key = "villager.rule.hidden_0264";                   label = "cached_gui_264";              arity = 0; tags = ["content"; "registry"; "compat"]; since = "1.9.0"; weight = 2304 };
  { key = "team.rule.strict_0265";                       label = "secondary_target_265";        arity = 0; tags = ["lower"; "async"]; since = "1.0.0"; weight = 362 };
  { key = "furnace.rule.scoped_0266";                    label = "loose_banner_266";            arity = 6; tags = ["core"; "async"; "untyped"]; since = "1.0.0"; weight = 1218 };
  { key = "brewing.rule.cached_0267";                    label = "eager_loom_267";              arity = 4; tags = ["lower"; "cached"; "experimental"]; since = "1.7.0"; weight = 837 };
  { key = "scoreboard.rule.internal_0268";               label = "canonical_trade_268";         arity = 1; tags = ["registry"; "cached"; "untyped"]; since = "1.7.0"; weight = 1692 };
  { key = "boat.rule.lazy_0269";                         label = "scoped_biome_269";            arity = 6; tags = ["packet"; "content"; "codegen"]; since = "1.7.0"; weight = 825 };
  { key = "chunk.rule.canonical_0270";                   label = "lazy_inventory_270";          arity = 2; tags = ["packet"; "compat"; "lower"]; since = "1.9.0"; weight = 2498 };
  { key = "shield.rule.scoped_0271";                     label = "canonical_rail_271";          arity = 0; tags = ["sync"]; since = "1.2.0"; weight = 2148 };
  { key = "conduit.rule.hidden_0272";                    label = "local_crossbow_272";          arity = 3; tags = ["registry"; "experimental"]; since = "1.7.0"; weight = 1553 };
  { key = "shulker.rule.cached_0273";                    label = "hidden_scoreboard_273";       arity = 5; tags = ["cold"; "content"]; since = "1.6.0"; weight = 3705 };
  { key = "player.rule.global_0274";                     label = "provisional_brewing_274";     arity = 1; tags = ["codegen"; "lower"]; since = "1.4.0"; weight = 527 };
  { key = "trade.rule.legacy_0275";                      label = "derived_arrow_275";           arity = 0; tags = ["legacy"; "cached"]; since = "1.5.2"; weight = 1074 };
  { key = "chunk.rule.legacy_0276";                      label = "secondary_slot_276";          arity = 4; tags = ["hot"]; since = "1.5.2"; weight = 1560 };
  { key = "trade.rule.secondary_0277";                   label = "lazy_villager_277";           arity = 1; tags = ["runtime"]; since = "1.4.0"; weight = 1811 };
  { key = "dropper.rule.eager_0278";                     label = "cached_banner_pattern_278";   arity = 2; tags = ["lower"; "compat"; "content"]; since = "1.9.0"; weight = 4011 };
  { key = "elytra.rule.global_0279";                     label = "hidden_bundle_279";           arity = 7; tags = ["packet"; "legacy"]; since = "1.7.0"; weight = 548 };
  { key = "gui.rule.canonical_0280";                     label = "canonical_slot_280";          arity = 0; tags = ["codegen"; "sync"; "untyped"]; since = "1.7.0"; weight = 1482 };
  { key = "minecart.rule.public_0281";                   label = "canonical_hopper_281";        arity = 3; tags = ["hot"; "sync"]; since = "1.9.0"; weight = 811 };
  { key = "particle.rule.public_0282";                   label = "cached_region_282";           arity = 7; tags = ["hot"]; since = "1.2.0"; weight = 3680 };
  { key = "hopper.rule.eager_0283";                      label = "legacy_effect_283";           arity = 7; tags = ["codegen"; "untyped"]; since = "1.5.2"; weight = 1913 };
  { key = "dropper.rule.global_0284";                    label = "cached_beacon_284";           arity = 0; tags = ["legacy"]; since = "1.2.0"; weight = 3086 };
  { key = "smithing.rule.canonical_0285";                label = "strict_conduit_285";          arity = 6; tags = ["cached"; "runtime"; "core"]; since = "1.9.0"; weight = 2284 };
  { key = "bell.rule.fallback_0286";                     label = "public_mob_286";              arity = 1; tags = ["async"; "packet"]; since = "1.0.0"; weight = 989 };
  { key = "crossbow.rule.eager_0287";                    label = "primary_shulker_287";         arity = 1; tags = ["cached"; "packet"]; since = "1.0.0"; weight = 3817 };
  { key = "banner.rule.fallback_0288";                   label = "primary_anvil_288";           arity = 7; tags = ["runtime"]; since = "1.5.2"; weight = 526 };
  { key = "repeater.rule.eager_0289";                    label = "eager_structure_289";         arity = 0; tags = ["typed"; "emit"; "packet"]; since = "1.3.1"; weight = 1962 };
  { key = "bell.rule.legacy_0290";                       label = "secondary_trade_290";         arity = 2; tags = ["legacy"; "untyped"]; since = "1.6.0"; weight = 581 };
  { key = "observer.rule.cached_0291";                   label = "cached_comparator_291";       arity = 6; tags = ["sync"; "core"]; since = "1.3.1"; weight = 2623 };
  { key = "bossbar.rule.derived_0292";                   label = "cached_world_292";            arity = 6; tags = ["emit"; "check"; "untyped"]; since = "1.8.3"; weight = 2696 };
  { key = "item.rule.fallback_0293";                     label = "canonical_firework_293";      arity = 0; tags = ["legacy"; "core"]; since = "1.9.0"; weight = 1265 };
  { key = "compass.rule.eager_0294";                     label = "scoped_objective_294";        arity = 1; tags = ["cold"]; since = "1.0.0"; weight = 1013 };
  { key = "conduit.rule.eager_0295";                     label = "canonical_particle_295";      arity = 6; tags = ["cached"; "untyped"; "cold"]; since = "1.5.2"; weight = 1409 };
  { key = "world.rule.global_0296";                      label = "stable_clock_296";            arity = 5; tags = ["typed"]; since = "1.6.0"; weight = 1962 };
  { key = "observer.rule.legacy_0297";                   label = "modern_minecart_297";         arity = 4; tags = ["packet"]; since = "1.5.2"; weight = 981 };
  { key = "firework.rule.legacy_0298";                   label = "scoped_enchant_298";          arity = 3; tags = ["legacy"; "packet"; "hot"]; since = "1.3.1"; weight = 3435 };
  { key = "smithing.rule.strict_0299";                   label = "cached_effect_299";           arity = 3; tags = ["untyped"; "async"]; since = "1.9.0"; weight = 2180 };
  { key = "compass.rule.local_0300";                     label = "provisional_arrow_300";       arity = 4; tags = ["compat"]; since = "1.0.0"; weight = 699 };
  { key = "trade.rule.public_0301";                      label = "scoped_boat_301";             arity = 0; tags = ["async"; "parse"]; since = "1.5.2"; weight = 3682 };
  { key = "firework.rule.cached_0302";                   label = "eager_arrow_302";             arity = 7; tags = ["core"]; since = "1.3.1"; weight = 1890 };
  { key = "composter.rule.global_0303";                  label = "primary_objective_303";       arity = 1; tags = ["sync"; "packet"; "parse"]; since = "1.9.0"; weight = 88 };
  { key = "dispenser.rule.hidden_0304";                  label = "fallback_beacon_304";         arity = 6; tags = ["content"]; since = "1.4.0"; weight = 461 };
  { key = "barrel.rule.legacy_0305";                     label = "canonical_shield_305";        arity = 3; tags = ["sync"; "packet"; "check"]; since = "1.4.0"; weight = 2049 };
  { key = "repeater.rule.secondary_0306";                label = "global_arrow_306";            arity = 2; tags = ["cold"; "registry"; "experimental"]; since = "1.3.1"; weight = 4015 };
  { key = "anvil.rule.loose_0307";                       label = "lazy_compass_307";            arity = 1; tags = ["lower"; "async"]; since = "1.9.0"; weight = 873 };
  { key = "villager.rule.internal_0308";                 label = "derived_rail_308";            arity = 4; tags = ["registry"]; since = "1.0.0"; weight = 326 };
  { key = "tablist.rule.lazy_0309";                      label = "loose_grindstone_309";        arity = 1; tags = ["compat"]; since = "1.4.0"; weight = 2904 };
  { key = "cartography.rule.internal_0310";              label = "eager_piston_310";            arity = 2; tags = ["parse"; "check"; "content"]; since = "1.4.0"; weight = 943 };
  { key = "arrow.rule.secondary_0311";                   label = "legacy_brewing_311";          arity = 7; tags = ["lower"]; since = "1.6.0"; weight = 3948 };
  { key = "sound.rule.scoped_0312";                      label = "secondary_smithing_312";      arity = 0; tags = ["content"; "check"; "hot"]; since = "1.8.3"; weight = 187 };
  { key = "tablist.rule.loose_0313";                     label = "public_pane_313";             arity = 1; tags = ["cached"]; since = "1.7.0"; weight = 721 };
  { key = "team.rule.lazy_0314";                         label = "lazy_target_314";             arity = 3; tags = ["registry"]; since = "1.6.0"; weight = 3275 };
  { key = "mob.rule.stable_0315";                        label = "cached_attribute_315";        arity = 2; tags = ["async"; "untyped"]; since = "1.3.1"; weight = 3331 };
  { key = "barrel.rule.canonical_0316";                  label = "eager_dispenser_316";         arity = 5; tags = ["parse"; "legacy"; "typed"]; since = "1.0.0"; weight = 1457 };
  { key = "cartography.rule.stable_0317";                label = "cached_bundle_317";           arity = 7; tags = ["runtime"; "compat"; "typed"]; since = "1.8.3"; weight = 3060 };
  { key = "portal.rule.secondary_0318";                  label = "internal_crossbow_318";       arity = 3; tags = ["runtime"; "compat"]; since = "1.7.0"; weight = 3023 };
  { key = "region.rule.fallback_0319";                   label = "strict_chunk_319";            arity = 3; tags = ["legacy"; "cold"; "packet"]; since = "1.0.0"; weight = 1679 };
  { key = "composter.rule.hidden_0320";                  label = "lazy_structure_320";          arity = 4; tags = ["core"]; since = "1.0.0"; weight = 4027 };
  { key = "npc.rule.scoped_0321";                        label = "secondary_potion_321";        arity = 2; tags = ["async"; "check"; "hot"]; since = "1.2.0"; weight = 2434 };
  { key = "smithing.rule.loose_0322";                    label = "fallback_player_322";         arity = 6; tags = ["cached"; "content"; "runtime"]; since = "1.2.0"; weight = 42 };
  { key = "mob.rule.derived_0323";                       label = "canonical_entity_323";        arity = 4; tags = ["runtime"; "legacy"; "registry"]; since = "1.6.0"; weight = 3329 };
  { key = "structure.rule.fallback_0324";                label = "local_crossbow_324";          arity = 1; tags = ["experimental"; "cold"; "typed"]; since = "1.0.0"; weight = 2564 };
  { key = "player.rule.secondary_0325";                  label = "secondary_structure_325";     arity = 1; tags = ["legacy"; "hot"]; since = "1.2.0"; weight = 3708 };
  { key = "stonecutter.rule.derived_0326";               label = "cached_observer_326";         arity = 5; tags = ["async"; "content"; "runtime"]; since = "1.0.0"; weight = 1254 };
  { key = "scoreboard.rule.legacy_0327";                 label = "scoped_trade_327";            arity = 2; tags = ["cold"]; since = "1.7.0"; weight = 1919 };
  { key = "minecart.rule.primary_0328";                  label = "public_mob_328";              arity = 2; tags = ["cached"]; since = "1.7.0"; weight = 2969 };
  { key = "conduit.rule.canonical_0329";                 label = "public_bossbar_329";          arity = 4; tags = ["core"; "runtime"]; since = "1.0.0"; weight = 1138 };
  { key = "boat.rule.strict_0330";                       label = "lazy_lectern_330";            arity = 1; tags = ["lower"; "codegen"]; since = "1.2.0"; weight = 1271 };
  { key = "portal.rule.internal_0331";                   label = "legacy_bundle_331";           arity = 5; tags = ["packet"]; since = "1.4.0"; weight = 57 };
  { key = "cartography.rule.eager_0332";                 label = "lazy_tablist_332";            arity = 6; tags = ["codegen"]; since = "1.3.1"; weight = 3859 };
  { key = "gui.rule.strict_0333";                        label = "loose_portal_333";            arity = 7; tags = ["experimental"; "codegen"]; since = "1.0.0"; weight = 1623 };
  { key = "packet.rule.local_0334";                      label = "modern_trade_334";            arity = 5; tags = ["lower"; "registry"; "content"]; since = "1.7.0"; weight = 1008 };
  { key = "inventory.rule.derived_0335";                 label = "strict_rail_335";             arity = 7; tags = ["untyped"]; since = "1.7.0"; weight = 999 };
  { key = "effect.rule.fallback_0336";                   label = "provisional_crossbow_336";    arity = 1; tags = ["content"; "runtime"]; since = "1.5.2"; weight = 3232 };
  { key = "shulker.rule.hidden_0337";                    label = "public_lectern_337";          arity = 0; tags = ["core"; "registry"]; since = "1.5.2"; weight = 1086 };
  { key = "trade.rule.legacy_0338";                      label = "scoped_cartography_338";      arity = 1; tags = ["hot"]; since = "1.9.0"; weight = 130 };
  { key = "gui.rule.primary_0339";                       label = "scoped_chunk_339";            arity = 4; tags = ["core"; "untyped"]; since = "1.8.3"; weight = 1497 };
  { key = "trident.rule.modern_0340";                    label = "global_arrow_340";            arity = 1; tags = ["untyped"; "cached"]; since = "1.9.0"; weight = 3107 };
  { key = "villager.rule.public_0341";                   label = "primary_brewing_341";         arity = 4; tags = ["content"]; since = "1.0.0"; weight = 1436 };
  { key = "composter.rule.scoped_0342";                  label = "eager_spawner_342";           arity = 2; tags = ["compat"; "runtime"; "cold"]; since = "1.0.0"; weight = 3843 };
  { key = "trident.rule.local_0343";                     label = "loose_spawner_343";           arity = 7; tags = ["core"]; since = "1.0.0"; weight = 2525 };
  { key = "tablist.rule.strict_0344";                    label = "loose_enchant_344";           arity = 0; tags = ["emit"; "sync"; "legacy"]; since = "1.9.0"; weight = 2102 };
  { key = "comparator.rule.public_0345";                 label = "hidden_villager_345";         arity = 2; tags = ["packet"]; since = "1.6.0"; weight = 1222 };
  { key = "boat.rule.lazy_0346";                         label = "cached_campfire_346";         arity = 1; tags = ["runtime"]; since = "1.2.0"; weight = 2079 };
  { key = "dropper.rule.stable_0347";                    label = "lazy_enchant_347";            arity = 3; tags = ["compat"; "sync"]; since = "1.9.0"; weight = 2432 };
  { key = "piston.rule.loose_0348";                      label = "hidden_smoker_348";           arity = 5; tags = ["parse"]; since = "1.8.3"; weight = 3350 };
  { key = "player.rule.stable_0349";                     label = "loose_map_349";               arity = 5; tags = ["cached"]; since = "1.7.0"; weight = 4088 };
  { key = "grindstone.rule.public_0350";                 label = "modern_block_350";            arity = 6; tags = ["packet"; "runtime"; "experimental"]; since = "1.9.0"; weight = 1119 };
  { key = "dispenser.rule.legacy_0351";                  label = "internal_particle_351";       arity = 7; tags = ["check"; "compat"; "codegen"]; since = "1.8.3"; weight = 675 };
  { key = "scoreboard.rule.secondary_0352";              label = "modern_mob_352";              arity = 6; tags = ["core"]; since = "1.7.0"; weight = 1852 };
  { key = "banner_pattern.rule.cached_0353";             label = "local_banner_pattern_353";    arity = 2; tags = ["typed"; "content"]; since = "1.3.1"; weight = 484 };
  { key = "banner_pattern.rule.lazy_0354";               label = "canonical_bossbar_354";       arity = 5; tags = ["check"]; since = "1.4.0"; weight = 2890 };
  { key = "beacon.rule.global_0355";                     label = "eager_beacon_355";            arity = 4; tags = ["check"]; since = "1.8.3"; weight = 48 };
  { key = "potion.rule.provisional_0356";                label = "lazy_campfire_356";           arity = 2; tags = ["sync"; "check"; "hot"]; since = "1.2.0"; weight = 25 };
  { key = "beacon.rule.internal_0357";                   label = "eager_spawner_357";           arity = 6; tags = ["experimental"; "untyped"; "emit"]; since = "1.7.0"; weight = 503 };
  { key = "trident.rule.loose_0358";                     label = "canonical_player_358";        arity = 0; tags = ["compat"; "check"; "legacy"]; since = "1.2.0"; weight = 57 };
  { key = "anvil.rule.local_0359";                       label = "canonical_world_359";         arity = 5; tags = ["typed"]; since = "1.9.0"; weight = 337 };
  { key = "piston.rule.stable_0360";                     label = "scoped_crossbow_360";         arity = 6; tags = ["experimental"]; since = "1.9.0"; weight = 2 };
  { key = "arrow.rule.internal_0361";                    label = "hidden_boat_361";             arity = 5; tags = ["cold"; "emit"]; since = "1.5.2"; weight = 3160 };
  { key = "piston.rule.eager_0362";                      label = "secondary_elytra_362";        arity = 7; tags = ["typed"; "parse"; "sync"]; since = "1.5.2"; weight = 1208 };
  { key = "target.rule.local_0363";                      label = "derived_boat_363";            arity = 6; tags = ["content"; "experimental"; "emit"]; since = "1.9.0"; weight = 429 };
  { key = "sound.rule.hidden_0364";                      label = "lazy_team_364";               arity = 6; tags = ["async"]; since = "1.8.3"; weight = 87 };
  { key = "player.rule.strict_0365";                     label = "local_bell_365";              arity = 3; tags = ["runtime"; "cached"; "typed"]; since = "1.9.0"; weight = 168 };
  { key = "crossbow.rule.secondary_0366";                label = "eager_loom_366";              arity = 6; tags = ["cached"; "untyped"; "content"]; since = "1.4.0"; weight = 3627 };
  { key = "particle.rule.provisional_0367";              label = "lazy_piston_367";             arity = 1; tags = ["typed"; "experimental"]; since = "1.3.1"; weight = 52 };
  { key = "attribute.rule.cached_0368";                  label = "modern_shield_368";           arity = 4; tags = ["core"]; since = "1.9.0"; weight = 3312 };
  { key = "entity.rule.internal_0369";                   label = "public_cartography_369";      arity = 0; tags = ["typed"; "untyped"]; since = "1.2.0"; weight = 3701 };
  { key = "scoreboard.rule.derived_0370";                label = "modern_gui_370";              arity = 1; tags = ["experimental"; "typed"]; since = "1.8.3"; weight = 3950 };
  { key = "compass.rule.canonical_0371";                 label = "cached_villager_371";         arity = 5; tags = ["untyped"]; since = "1.8.3"; weight = 3962 };
  { key = "block.rule.canonical_0372";                   label = "lazy_barrel_372";             arity = 4; tags = ["experimental"; "content"; "codegen"]; since = "1.3.1"; weight = 2812 };
  { key = "repeater.rule.hidden_0373";                   label = "derived_player_373";          arity = 6; tags = ["cold"]; since = "1.8.3"; weight = 2384 };
  { key = "barrel.rule.local_0374";                      label = "strict_campfire_374";         arity = 3; tags = ["hot"; "sync"]; since = "1.9.0"; weight = 463 };
  { key = "tablist.rule.canonical_0375";                 label = "fallback_crossbow_375";       arity = 7; tags = ["hot"]; since = "1.6.0"; weight = 16 };
  { key = "observer.rule.internal_0376";                 label = "global_structure_376";        arity = 5; tags = ["runtime"]; since = "1.8.3"; weight = 973 };
  { key = "team.rule.stable_0377";                       label = "hidden_cartography_377";      arity = 6; tags = ["registry"; "cold"; "sync"]; since = "1.7.0"; weight = 346 };
  { key = "conduit.rule.primary_0378";                   label = "secondary_barrel_378";        arity = 7; tags = ["legacy"; "packet"; "check"]; since = "1.4.0"; weight = 2794 };
  { key = "villager.rule.primary_0379";                  label = "hidden_attribute_379";        arity = 3; tags = ["cached"; "content"; "lower"]; since = "1.9.0"; weight = 389 };
  { key = "dispenser.rule.global_0380";                  label = "modern_chunk_380";            arity = 1; tags = ["core"]; since = "1.3.1"; weight = 146 };
  { key = "furnace.rule.modern_0381";                    label = "stable_observer_381";         arity = 6; tags = ["content"]; since = "1.9.0"; weight = 220 };
  { key = "banner_pattern.rule.global_0382";             label = "provisional_shulker_382";     arity = 6; tags = ["codegen"; "sync"; "parse"]; since = "1.0.0"; weight = 2217 };
  { key = "trident.rule.eager_0383";                     label = "secondary_pane_383";          arity = 4; tags = ["legacy"]; since = "1.3.1"; weight = 2942 };
  { key = "sound.rule.provisional_0384";                 label = "modern_conduit_384";          arity = 6; tags = ["cold"; "sync"]; since = "1.5.2"; weight = 3326 };
  { key = "trident.rule.stable_0385";                    label = "provisional_cartography_385"; arity = 3; tags = ["typed"; "registry"; "hot"]; since = "1.0.0"; weight = 633 };
  { key = "hologram.rule.secondary_0386";                label = "stable_biome_386";            arity = 2; tags = ["lower"; "content"; "cached"]; since = "1.9.0"; weight = 2878 };
  { key = "pane.rule.loose_0387";                        label = "local_villager_387";          arity = 7; tags = ["core"; "parse"; "sync"]; since = "1.6.0"; weight = 120 };
  { key = "map.rule.fallback_0388";                      label = "canonical_inventory_388";     arity = 2; tags = ["core"; "check"; "cold"]; since = "1.9.0"; weight = 3501 };
  { key = "map.rule.canonical_0389";                     label = "modern_scoreboard_389";       arity = 5; tags = ["codegen"]; since = "1.5.2"; weight = 2236 };
  { key = "compass.rule.canonical_0390";                 label = "modern_sound_390";            arity = 1; tags = ["emit"]; since = "1.6.0"; weight = 3305 };
  { key = "crossbow.rule.eager_0391";                    label = "cached_map_391";              arity = 7; tags = ["legacy"; "packet"; "hot"]; since = "1.7.0"; weight = 3264 };
  { key = "arrow.rule.cached_0392";                      label = "scoped_gui_392";              arity = 3; tags = ["packet"; "sync"; "typed"]; since = "1.3.1"; weight = 1533 };
  { key = "packet.rule.public_0393";                     label = "provisional_gui_393";         arity = 4; tags = ["typed"; "lower"]; since = "1.0.0"; weight = 504 };
  { key = "villager.rule.eager_0394";                    label = "eager_chunk_394";             arity = 7; tags = ["packet"]; since = "1.2.0"; weight = 2063 };
  { key = "enchant.rule.primary_0395";                   label = "public_npc_395";              arity = 7; tags = ["legacy"]; since = "1.0.0"; weight = 1105 };
  { key = "bell.rule.secondary_0396";                    label = "public_clock_396";            arity = 4; tags = ["parse"]; since = "1.4.0"; weight = 3604 };
  { key = "smoker.rule.public_0397";                     label = "global_item_397";             arity = 5; tags = ["sync"; "codegen"; "async"]; since = "1.2.0"; weight = 3922 };
  { key = "slot.rule.hidden_0398";                       label = "fallback_arrow_398";          arity = 2; tags = ["lower"]; since = "1.5.2"; weight = 2879 };
  { key = "shield.rule.cached_0399";                     label = "provisional_target_399";      arity = 7; tags = ["core"; "content"]; since = "1.8.3"; weight = 1433 };
  { key = "banner_pattern.rule.loose_0400";              label = "hidden_boat_400";             arity = 4; tags = ["hot"]; since = "1.0.0"; weight = 1015 };
  { key = "furnace.rule.legacy_0401";                    label = "primary_mob_401";             arity = 1; tags = ["hot"]; since = "1.3.1"; weight = 3573 };
  { key = "smoker.rule.derived_0402";                    label = "legacy_observer_402";         arity = 6; tags = ["check"]; since = "1.7.0"; weight = 672 };
  { key = "advancement.rule.global_0403";                label = "provisional_dropper_403";     arity = 0; tags = ["emit"]; since = "1.9.0"; weight = 645 };
  { key = "bundle.rule.loose_0404";                      label = "derived_repeater_404";        arity = 0; tags = ["cached"; "codegen"]; since = "1.0.0"; weight = 453 };
]

let count = List.length entries

let table : (string, rule_entry) Hashtbl.t =
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
