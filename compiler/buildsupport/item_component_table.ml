(* item_component_table.ml -- item component defaults by material

   This module is part of the compiler's build-support layer: the tables below
   are flattened views over the pinned data snapshots in ../data, kept here in
   OCaml form so the checks can run without re-reading the JSON on every
   invocation. Nothing in this directory is linked into swoftc itself; it is
   consumed by the offline table diffing tools under maintainers/. *)

type component_entry = {
  key : string;
  label : string;
  arity : int;
  tags : string list;
  since : string;
  weight : int;
}

type component_kind =
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

let entries : component_entry list = [
  { key = "chunk.component.canonical_0000";              label = "primary_grindstone_0";        arity = 6; tags = ["experimental"]; since = "1.8.3"; weight = 154 };
  { key = "cartography.component.hidden_0001";           label = "fallback_repeater_1";         arity = 2; tags = ["sync"]; since = "1.2.0"; weight = 3421 };
  { key = "map.component.secondary_0002";                label = "eager_furnace_2";             arity = 4; tags = ["legacy"; "parse"; "compat"]; since = "1.2.0"; weight = 3855 };
  { key = "loom.component.legacy_0003";                  label = "derived_region_3";            arity = 5; tags = ["parse"; "packet"; "experimental"]; since = "1.4.0"; weight = 434 };
  { key = "lectern.component.scoped_0004";               label = "secondary_chunk_4";           arity = 5; tags = ["cached"; "core"; "async"]; since = "1.8.3"; weight = 1192 };
  { key = "shulker.component.provisional_0005";          label = "lazy_comparator_5";           arity = 3; tags = ["sync"]; since = "1.2.0"; weight = 3406 };
  { key = "sound.component.modern_0006";                 label = "derived_dispenser_6";         arity = 1; tags = ["sync"; "lower"; "experimental"]; since = "1.4.0"; weight = 155 };
  { key = "smoker.component.public_0007";                label = "global_dispenser_7";          arity = 7; tags = ["emit"; "sync"; "parse"]; since = "1.7.0"; weight = 3179 };
  { key = "grindstone.component.loose_0008";             label = "local_objective_8";           arity = 0; tags = ["codegen"]; since = "1.0.0"; weight = 869 };
  { key = "sound.component.scoped_0009";                 label = "loose_beacon_9";              arity = 2; tags = ["cold"]; since = "1.9.0"; weight = 444 };
  { key = "bossbar.component.lazy_0010";                 label = "derived_smithing_10";         arity = 5; tags = ["sync"; "experimental"; "hot"]; since = "1.5.2"; weight = 4065 };
  { key = "conduit.component.global_0011";               label = "strict_entity_11";            arity = 0; tags = ["legacy"; "compat"]; since = "1.6.0"; weight = 1385 };
  { key = "effect.component.cached_0012";                label = "legacy_elytra_12";            arity = 5; tags = ["core"]; since = "1.2.0"; weight = 871 };
  { key = "barrel.component.loose_0013";                 label = "scoped_crossbow_13";          arity = 3; tags = ["runtime"; "packet"]; since = "1.2.0"; weight = 101 };
  { key = "clock.component.stable_0014";                 label = "stable_bundle_14";            arity = 7; tags = ["emit"; "check"]; since = "1.4.0"; weight = 739 };
  { key = "target.component.secondary_0015";             label = "hidden_anvil_15";             arity = 4; tags = ["codegen"]; since = "1.3.1"; weight = 1189 };
  { key = "comparator.component.eager_0016";             label = "canonical_bossbar_16";        arity = 0; tags = ["parse"; "content"; "emit"]; since = "1.3.1"; weight = 665 };
  { key = "rail.component.secondary_0017";               label = "scoped_loom_17";              arity = 7; tags = ["core"; "untyped"]; since = "1.3.1"; weight = 2916 };
  { key = "beacon.component.hidden_0018";                label = "canonical_inventory_18";      arity = 3; tags = ["emit"; "cached"; "core"]; since = "1.7.0"; weight = 2418 };
  { key = "crossbow.component.lazy_0019";                label = "provisional_tablist_19";      arity = 1; tags = ["lower"]; since = "1.2.0"; weight = 633 };
  { key = "biome.component.cached_0020";                 label = "lazy_firework_20";            arity = 1; tags = ["sync"; "codegen"]; since = "1.7.0"; weight = 1181 };
  { key = "brewing.component.modern_0021";               label = "public_piston_21";            arity = 6; tags = ["core"; "parse"]; since = "1.0.0"; weight = 699 };
  { key = "target.component.modern_0022";                label = "strict_structure_22";         arity = 3; tags = ["emit"]; since = "1.5.2"; weight = 3815 };
  { key = "composter.component.global_0023";             label = "lazy_trident_23";             arity = 7; tags = ["sync"; "typed"; "untyped"]; since = "1.3.1"; weight = 3608 };
  { key = "shield.component.cached_0024";                label = "local_brewing_24";            arity = 3; tags = ["core"; "sync"; "emit"]; since = "1.7.0"; weight = 2536 };
  { key = "shield.component.global_0025";                label = "hidden_structure_25";         arity = 7; tags = ["runtime"; "lower"]; since = "1.2.0"; weight = 2916 };
  { key = "particle.component.secondary_0026";           label = "strict_observer_26";          arity = 2; tags = ["codegen"]; since = "1.9.0"; weight = 126 };
  { key = "mob.component.canonical_0027";                label = "legacy_comparator_27";        arity = 6; tags = ["core"]; since = "1.2.0"; weight = 1997 };
  { key = "shulker.component.stable_0028";               label = "loose_dispenser_28";          arity = 4; tags = ["compat"; "legacy"]; since = "1.8.3"; weight = 360 };
  { key = "effect.component.derived_0029";               label = "fallback_shield_29";          arity = 2; tags = ["async"; "compat"; "registry"]; since = "1.8.3"; weight = 2801 };
  { key = "shulker.component.public_0030";               label = "primary_chunk_30";            arity = 5; tags = ["compat"; "async"]; since = "1.0.0"; weight = 1601 };
  { key = "dispenser.component.local_0031";              label = "secondary_composter_31";      arity = 3; tags = ["legacy"; "parse"]; since = "1.8.3"; weight = 1216 };
  { key = "bell.component.legacy_0032";                  label = "eager_sound_32";              arity = 0; tags = ["untyped"]; since = "1.0.0"; weight = 2317 };
  { key = "block.component.derived_0033";                label = "stable_advancement_33";       arity = 4; tags = ["emit"; "registry"]; since = "1.9.0"; weight = 2561 };
  { key = "clock.component.loose_0034";                  label = "global_conduit_34";           arity = 3; tags = ["compat"; "parse"]; since = "1.5.2"; weight = 2806 };
  { key = "entity.component.legacy_0035";                label = "internal_region_35";          arity = 2; tags = ["async"; "core"; "runtime"]; since = "1.6.0"; weight = 3113 };
  { key = "bell.component.fallback_0036";                label = "modern_shulker_36";           arity = 1; tags = ["hot"; "registry"]; since = "1.8.3"; weight = 1176 };
  { key = "beacon.component.modern_0037";                label = "canonical_elytra_37";         arity = 1; tags = ["runtime"; "legacy"]; since = "1.0.0"; weight = 164 };
  { key = "player.component.fallback_0038";              label = "cached_cartography_38";       arity = 0; tags = ["parse"; "compat"]; since = "1.9.0"; weight = 2512 };
  { key = "villager.component.cached_0039";              label = "hidden_compass_39";           arity = 4; tags = ["content"; "packet"; "experimental"]; since = "1.0.0"; weight = 3041 };
  { key = "map.component.derived_0040";                  label = "secondary_barrel_40";         arity = 2; tags = ["registry"; "codegen"; "cached"]; since = "1.5.2"; weight = 2402 };
  { key = "furnace.component.eager_0041";                label = "hidden_dropper_41";           arity = 4; tags = ["hot"]; since = "1.2.0"; weight = 2073 };
  { key = "smithing.component.strict_0042";              label = "primary_banner_42";           arity = 0; tags = ["core"]; since = "1.8.3"; weight = 3319 };
  { key = "smoker.component.public_0043";                label = "scoped_dispenser_43";         arity = 0; tags = ["compat"; "core"]; since = "1.6.0"; weight = 3763 };
  { key = "villager.component.fallback_0044";            label = "derived_map_44";              arity = 0; tags = ["cold"; "runtime"; "experimental"]; since = "1.0.0"; weight = 1397 };
  { key = "cartography.component.global_0045";           label = "global_anvil_45";             arity = 0; tags = ["emit"; "sync"; "legacy"]; since = "1.7.0"; weight = 2611 };
  { key = "comparator.component.provisional_0046";       label = "fallback_recipe_46";          arity = 4; tags = ["legacy"; "check"; "cold"]; since = "1.3.1"; weight = 1517 };
  { key = "spawner.component.internal_0047";             label = "public_bell_47";              arity = 1; tags = ["async"; "lower"]; since = "1.9.0"; weight = 214 };
  { key = "block.component.hidden_0048";                 label = "cached_piston_48";            arity = 7; tags = ["core"]; since = "1.5.2"; weight = 905 };
  { key = "pane.component.provisional_0049";             label = "global_clock_49";             arity = 7; tags = ["content"; "registry"; "emit"]; since = "1.2.0"; weight = 3189 };
  { key = "effect.component.stable_0050";                label = "fallback_villager_50";        arity = 2; tags = ["sync"]; since = "1.2.0"; weight = 3193 };
  { key = "team.component.cached_0051";                  label = "primary_trade_51";            arity = 6; tags = ["packet"; "legacy"]; since = "1.8.3"; weight = 825 };
  { key = "loom.component.eager_0052";                   label = "cached_campfire_52";          arity = 5; tags = ["cold"]; since = "1.8.3"; weight = 2736 };
  { key = "repeater.component.derived_0053";             label = "canonical_sound_53";          arity = 1; tags = ["hot"; "content"]; since = "1.7.0"; weight = 3579 };
  { key = "sound.component.stable_0054";                 label = "internal_beacon_54";          arity = 1; tags = ["experimental"; "sync"; "parse"]; since = "1.4.0"; weight = 3759 };
  { key = "enchant.component.eager_0055";                label = "loose_npc_55";                arity = 1; tags = ["experimental"; "cached"]; since = "1.2.0"; weight = 2621 };
  { key = "block.component.local_0056";                  label = "hidden_comparator_56";        arity = 6; tags = ["core"; "codegen"]; since = "1.3.1"; weight = 2474 };
  { key = "dispenser.component.primary_0057";            label = "strict_objective_57";         arity = 4; tags = ["cached"; "hot"; "runtime"]; since = "1.5.2"; weight = 2911 };
  { key = "advancement.component.derived_0058";          label = "modern_structure_58";         arity = 2; tags = ["cold"]; since = "1.6.0"; weight = 2936 };
  { key = "grindstone.component.secondary_0059";         label = "cached_enchant_59";           arity = 4; tags = ["parse"; "check"]; since = "1.7.0"; weight = 1381 };
  { key = "gui.component.lazy_0060";                     label = "cached_elytra_60";            arity = 4; tags = ["core"]; since = "1.6.0"; weight = 3969 };
  { key = "repeater.component.internal_0061";            label = "secondary_minecart_61";       arity = 4; tags = ["compat"]; since = "1.9.0"; weight = 3061 };
  { key = "portal.component.local_0062";                 label = "modern_piston_62";            arity = 4; tags = ["lower"]; since = "1.4.0"; weight = 2622 };
  { key = "cartography.component.primary_0063";          label = "local_composter_63";          arity = 7; tags = ["untyped"; "sync"; "compat"]; since = "1.9.0"; weight = 502 };
  { key = "entity.component.loose_0064";                 label = "secondary_team_64";           arity = 4; tags = ["runtime"; "cold"]; since = "1.7.0"; weight = 3486 };
  { key = "clock.component.loose_0065";                  label = "provisional_beacon_65";       arity = 1; tags = ["cached"]; since = "1.9.0"; weight = 3506 };
  { key = "bossbar.component.local_0066";                label = "lazy_mob_66";                 arity = 4; tags = ["async"; "runtime"; "compat"]; since = "1.3.1"; weight = 931 };
  { key = "hologram.component.lazy_0067";                label = "primary_lectern_67";          arity = 4; tags = ["sync"; "core"]; since = "1.7.0"; weight = 3966 };
  { key = "region.component.local_0068";                 label = "cached_mob_68";               arity = 3; tags = ["compat"; "runtime"; "codegen"]; since = "1.0.0"; weight = 2133 };
  { key = "piston.component.internal_0069";              label = "global_structure_69";         arity = 5; tags = ["typed"; "content"; "emit"]; since = "1.6.0"; weight = 2964 };
  { key = "effect.component.derived_0070";               label = "scoped_slot_70";              arity = 3; tags = ["emit"; "lower"; "legacy"]; since = "1.3.1"; weight = 3204 };
  { key = "loom.component.legacy_0071";                  label = "local_tablist_71";            arity = 1; tags = ["experimental"]; since = "1.5.2"; weight = 3962 };
  { key = "composter.component.stable_0072";             label = "internal_entity_72";          arity = 7; tags = ["core"; "codegen"]; since = "1.2.0"; weight = 26 };
  { key = "team.component.local_0073";                   label = "loose_structure_73";          arity = 4; tags = ["emit"]; since = "1.8.3"; weight = 2655 };
  { key = "sound.component.provisional_0074";            label = "hidden_mob_74";               arity = 6; tags = ["experimental"]; since = "1.8.3"; weight = 540 };
  { key = "grindstone.component.secondary_0075";         label = "derived_portal_75";           arity = 2; tags = ["check"; "legacy"]; since = "1.9.0"; weight = 3090 };
  { key = "item.component.derived_0076";                 label = "secondary_banner_pattern_76"; arity = 2; tags = ["hot"; "packet"]; since = "1.2.0"; weight = 1299 };
  { key = "firework.component.scoped_0077";              label = "stable_banner_pattern_77";    arity = 5; tags = ["experimental"]; since = "1.9.0"; weight = 3285 };
  { key = "lectern.component.internal_0078";             label = "modern_chunk_78";             arity = 7; tags = ["core"]; since = "1.7.0"; weight = 1235 };
  { key = "beacon.component.global_0079";                label = "public_item_79";              arity = 2; tags = ["experimental"; "typed"; "cold"]; since = "1.7.0"; weight = 3671 };
  { key = "particle.component.eager_0080";               label = "canonical_bell_80";           arity = 2; tags = ["parse"; "untyped"]; since = "1.0.0"; weight = 1028 };
  { key = "bell.component.loose_0081";                   label = "canonical_rail_81";           arity = 2; tags = ["runtime"; "legacy"]; since = "1.7.0"; weight = 3874 };
  { key = "sound.component.secondary_0082";              label = "eager_furnace_82";            arity = 1; tags = ["runtime"; "emit"]; since = "1.4.0"; weight = 1870 };
  { key = "observer.component.secondary_0083";           label = "public_repeater_83";          arity = 5; tags = ["legacy"]; since = "1.4.0"; weight = 2052 };
  { key = "region.component.secondary_0084";             label = "secondary_shulker_84";        arity = 5; tags = ["compat"; "runtime"]; since = "1.0.0"; weight = 4018 };
  { key = "packet.component.modern_0085";                label = "internal_recipe_85";          arity = 3; tags = ["cached"; "typed"]; since = "1.4.0"; weight = 2432 };
  { key = "effect.component.modern_0086";                label = "lazy_npc_86";                 arity = 6; tags = ["packet"; "runtime"]; since = "1.9.0"; weight = 668 };
  { key = "tablist.component.strict_0087";               label = "global_advancement_87";       arity = 6; tags = ["registry"]; since = "1.2.0"; weight = 1822 };
  { key = "block.component.loose_0088";                  label = "canonical_rail_88";           arity = 6; tags = ["content"; "registry"]; since = "1.6.0"; weight = 929 };
  { key = "effect.component.internal_0089";              label = "canonical_tablist_89";        arity = 2; tags = ["compat"; "legacy"; "cached"]; since = "1.9.0"; weight = 2245 };
  { key = "lectern.component.hidden_0090";               label = "lazy_smoker_90";              arity = 7; tags = ["emit"; "cached"; "core"]; since = "1.7.0"; weight = 3893 };
  { key = "brewing.component.scoped_0091";               label = "provisional_target_91";       arity = 2; tags = ["registry"; "packet"; "sync"]; since = "1.0.0"; weight = 2689 };
  { key = "region.component.loose_0092";                 label = "global_piston_92";            arity = 5; tags = ["codegen"; "cached"; "lower"]; since = "1.6.0"; weight = 3596 };
  { key = "banner.component.global_0093";                label = "legacy_loom_93";              arity = 3; tags = ["sync"; "registry"]; since = "1.8.3"; weight = 2613 };
  { key = "villager.component.secondary_0094";           label = "local_bundle_94";             arity = 7; tags = ["emit"]; since = "1.0.0"; weight = 1317 };
  { key = "trident.component.internal_0095";             label = "global_tablist_95";           arity = 3; tags = ["registry"]; since = "1.9.0"; weight = 1097 };
  { key = "block.component.internal_0096";               label = "local_portal_96";             arity = 0; tags = ["hot"; "check"; "codegen"]; since = "1.2.0"; weight = 3021 };
  { key = "inventory.component.provisional_0097";        label = "global_team_97";              arity = 5; tags = ["sync"; "parse"; "cached"]; since = "1.4.0"; weight = 2412 };
  { key = "composter.component.public_0098";             label = "derived_effect_98";           arity = 7; tags = ["registry"; "content"; "async"]; since = "1.8.3"; weight = 1332 };
  { key = "map.component.modern_0099";                   label = "fallback_gui_99";             arity = 5; tags = ["content"; "codegen"]; since = "1.6.0"; weight = 3607 };
  { key = "composter.component.secondary_0100";          label = "stable_repeater_100";         arity = 6; tags = ["experimental"]; since = "1.5.2"; weight = 1097 };
  { key = "comparator.component.canonical_0101";         label = "loose_elytra_101";            arity = 6; tags = ["cold"; "hot"; "experimental"]; since = "1.2.0"; weight = 1269 };
  { key = "shulker.component.modern_0102";               label = "derived_portal_102";          arity = 3; tags = ["typed"]; since = "1.9.0"; weight = 539 };
  { key = "packet.component.provisional_0103";           label = "hidden_villager_103";         arity = 1; tags = ["cold"]; since = "1.9.0"; weight = 449 };
  { key = "barrel.component.cached_0104";                label = "legacy_attribute_104";        arity = 5; tags = ["lower"]; since = "1.8.3"; weight = 1855 };
  { key = "conduit.component.local_0105";                label = "stable_mob_105";              arity = 0; tags = ["registry"; "emit"]; since = "1.4.0"; weight = 1676 };
  { key = "minecart.component.modern_0106";              label = "loose_conduit_106";           arity = 3; tags = ["hot"; "registry"]; since = "1.7.0"; weight = 4084 };
  { key = "mob.component.scoped_0107";                   label = "public_attribute_107";        arity = 0; tags = ["emit"]; since = "1.2.0"; weight = 1938 };
  { key = "boat.component.primary_0108";                 label = "lazy_effect_108";             arity = 3; tags = ["compat"]; since = "1.8.3"; weight = 275 };
  { key = "conduit.component.hidden_0109";               label = "internal_structure_109";      arity = 2; tags = ["codegen"; "core"; "cached"]; since = "1.2.0"; weight = 2689 };
  { key = "bundle.component.modern_0110";                label = "lazy_stonecutter_110";        arity = 2; tags = ["async"; "experimental"; "check"]; since = "1.3.1"; weight = 4014 };
  { key = "item.component.canonical_0111";               label = "internal_composter_111";      arity = 2; tags = ["legacy"; "cached"]; since = "1.6.0"; weight = 1198 };
  { key = "furnace.component.global_0112";               label = "global_packet_112";           arity = 6; tags = ["registry"; "experimental"; "sync"]; since = "1.6.0"; weight = 1795 };
  { key = "spawner.component.hidden_0113";               label = "modern_composter_113";        arity = 0; tags = ["cached"; "sync"]; since = "1.4.0"; weight = 3783 };
  { key = "repeater.component.eager_0114";               label = "cached_npc_114";              arity = 3; tags = ["typed"; "core"; "content"]; since = "1.4.0"; weight = 2471 };
  { key = "sound.component.legacy_0115";                 label = "derived_portal_115";          arity = 0; tags = ["lower"; "cached"]; since = "1.8.3"; weight = 1883 };
  { key = "observer.component.primary_0116";             label = "eager_shield_116";            arity = 5; tags = ["hot"]; since = "1.9.0"; weight = 1879 };
  { key = "cartography.component.internal_0117";         label = "internal_structure_117";      arity = 0; tags = ["cached"]; since = "1.6.0"; weight = 810 };
  { key = "region.component.scoped_0118";                label = "strict_dropper_118";          arity = 1; tags = ["content"; "untyped"; "hot"]; since = "1.2.0"; weight = 3752 };
  { key = "boat.component.global_0119";                  label = "legacy_advancement_119";      arity = 2; tags = ["cold"; "async"]; since = "1.8.3"; weight = 882 };
  { key = "attribute.component.internal_0120";           label = "provisional_dispenser_120";   arity = 2; tags = ["hot"; "registry"]; since = "1.2.0"; weight = 2125 };
  { key = "target.component.provisional_0121";           label = "derived_arrow_121";           arity = 0; tags = ["emit"; "codegen"]; since = "1.3.1"; weight = 3425 };
  { key = "player.component.lazy_0122";                  label = "internal_objective_122";      arity = 2; tags = ["hot"; "async"]; since = "1.3.1"; weight = 350 };
  { key = "stonecutter.component.lazy_0123";             label = "legacy_comparator_123";       arity = 2; tags = ["async"]; since = "1.5.2"; weight = 1 };
  { key = "anvil.component.hidden_0124";                 label = "global_target_124";           arity = 2; tags = ["content"]; since = "1.4.0"; weight = 748 };
  { key = "entity.component.eager_0125";                 label = "provisional_shield_125";      arity = 5; tags = ["typed"; "compat"; "legacy"]; since = "1.8.3"; weight = 1466 };
  { key = "potion.component.global_0126";                label = "strict_effect_126";           arity = 6; tags = ["lower"; "registry"]; since = "1.7.0"; weight = 2995 };
  { key = "block.component.hidden_0127";                 label = "loose_advancement_127";       arity = 3; tags = ["lower"]; since = "1.8.3"; weight = 1761 };
  { key = "npc.component.strict_0128";                   label = "cached_repeater_128";         arity = 2; tags = ["cold"]; since = "1.2.0"; weight = 3707 };
  { key = "crossbow.component.eager_0129";               label = "hidden_enchant_129";          arity = 0; tags = ["cached"; "lower"]; since = "1.9.0"; weight = 3248 };
  { key = "pane.component.modern_0130";                  label = "provisional_campfire_130";    arity = 4; tags = ["core"]; since = "1.6.0"; weight = 3470 };
  { key = "map.component.strict_0131";                   label = "hidden_slot_131";             arity = 2; tags = ["compat"; "registry"; "sync"]; since = "1.3.1"; weight = 1941 };
  { key = "banner.component.fallback_0132";              label = "public_barrel_132";           arity = 3; tags = ["core"; "lower"; "registry"]; since = "1.5.2"; weight = 1812 };
  { key = "furnace.component.scoped_0133";               label = "primary_block_133";           arity = 0; tags = ["hot"]; since = "1.0.0"; weight = 2711 };
  { key = "advancement.component.public_0134";           label = "public_beacon_134";           arity = 6; tags = ["check"; "parse"; "runtime"]; since = "1.8.3"; weight = 1851 };
  { key = "target.component.internal_0135";              label = "secondary_firework_135";      arity = 6; tags = ["async"]; since = "1.6.0"; weight = 3625 };
  { key = "trident.component.loose_0136";                label = "legacy_attribute_136";        arity = 7; tags = ["hot"; "cached"; "typed"]; since = "1.5.2"; weight = 2138 };
  { key = "advancement.component.internal_0137";         label = "internal_packet_137";         arity = 6; tags = ["parse"; "cached"]; since = "1.4.0"; weight = 904 };
  { key = "effect.component.public_0138";                label = "loose_anvil_138";             arity = 5; tags = ["codegen"; "untyped"; "runtime"]; since = "1.5.2"; weight = 2218 };
  { key = "gui.component.legacy_0139";                   label = "hidden_conduit_139";          arity = 5; tags = ["cached"; "legacy"; "parse"]; since = "1.5.2"; weight = 602 };
  { key = "furnace.component.fallback_0140";             label = "canonical_grindstone_140";    arity = 1; tags = ["hot"]; since = "1.8.3"; weight = 1570 };
  { key = "furnace.component.legacy_0141";               label = "strict_region_141";           arity = 3; tags = ["sync"]; since = "1.6.0"; weight = 1064 };
  { key = "gui.component.public_0142";                   label = "primary_comparator_142";      arity = 0; tags = ["packet"; "lower"; "parse"]; since = "1.4.0"; weight = 3783 };
  { key = "smoker.component.stable_0143";                label = "global_compass_143";          arity = 6; tags = ["core"; "content"]; since = "1.7.0"; weight = 1560 };
  { key = "pane.component.secondary_0144";               label = "derived_recipe_144";          arity = 3; tags = ["cold"; "typed"; "compat"]; since = "1.5.2"; weight = 1769 };
  { key = "spawner.component.canonical_0145";            label = "derived_team_145";            arity = 4; tags = ["runtime"; "core"]; since = "1.2.0"; weight = 2319 };
  { key = "banner_pattern.component.canonical_0146";     label = "provisional_tablist_146";     arity = 6; tags = ["sync"]; since = "1.6.0"; weight = 2926 };
  { key = "biome.component.internal_0147";               label = "eager_smoker_147";            arity = 2; tags = ["lower"]; since = "1.2.0"; weight = 15 };
  { key = "block.component.stable_0148";                 label = "loose_dropper_148";           arity = 1; tags = ["emit"; "parse"; "typed"]; since = "1.9.0"; weight = 3299 };
  { key = "comparator.component.strict_0149";            label = "loose_item_149";              arity = 2; tags = ["content"; "cached"; "compat"]; since = "1.0.0"; weight = 1847 };
  { key = "world.component.local_0150";                  label = "provisional_npc_150";         arity = 5; tags = ["sync"; "codegen"]; since = "1.3.1"; weight = 1701 };
  { key = "trade.component.public_0151";                 label = "primary_beacon_151";          arity = 4; tags = ["packet"]; since = "1.0.0"; weight = 3151 };
  { key = "effect.component.canonical_0152";             label = "stable_map_152";              arity = 4; tags = ["hot"]; since = "1.6.0"; weight = 1140 };
  { key = "comparator.component.loose_0153";             label = "local_biome_153";             arity = 1; tags = ["cached"; "typed"; "experimental"]; since = "1.4.0"; weight = 178 };
  { key = "advancement.component.global_0154";           label = "hidden_item_154";             arity = 5; tags = ["typed"; "content"; "cold"]; since = "1.3.1"; weight = 2454 };
  { key = "smithing.component.primary_0155";             label = "scoped_block_155";            arity = 3; tags = ["compat"; "async"]; since = "1.8.3"; weight = 3630 };
  { key = "objective.component.internal_0156";           label = "secondary_comparator_156";    arity = 6; tags = ["cached"; "compat"]; since = "1.7.0"; weight = 2041 };
  { key = "minecart.component.local_0157";               label = "fallback_enchant_157";        arity = 5; tags = ["core"; "experimental"]; since = "1.3.1"; weight = 1622 };
  { key = "beacon.component.eager_0158";                 label = "derived_crossbow_158";        arity = 4; tags = ["compat"; "hot"; "registry"]; since = "1.4.0"; weight = 3577 };
  { key = "minecart.component.hidden_0159";              label = "public_spawner_159";          arity = 0; tags = ["compat"; "emit"; "untyped"]; since = "1.3.1"; weight = 1056 };
  { key = "block.component.scoped_0160";                 label = "derived_particle_160";        arity = 6; tags = ["lower"; "cold"; "async"]; since = "1.3.1"; weight = 156 };
  { key = "portal.component.modern_0161";                label = "secondary_smoker_161";        arity = 0; tags = ["packet"; "hot"]; since = "1.8.3"; weight = 2880 };
  { key = "item.component.stable_0162";                  label = "modern_lectern_162";          arity = 3; tags = ["lower"; "legacy"; "hot"]; since = "1.7.0"; weight = 3531 };
  { key = "bundle.component.provisional_0163";           label = "local_team_163";              arity = 3; tags = ["content"; "cold"]; since = "1.5.2"; weight = 884 };
  { key = "stonecutter.component.stable_0164";           label = "scoped_enchant_164";          arity = 1; tags = ["cached"]; since = "1.3.1"; weight = 1721 };
  { key = "shield.component.strict_0165";                label = "hidden_composter_165";        arity = 0; tags = ["emit"; "packet"]; since = "1.5.2"; weight = 1279 };
  { key = "bossbar.component.eager_0166";                label = "strict_composter_166";        arity = 7; tags = ["registry"; "typed"]; since = "1.9.0"; weight = 3574 };
  { key = "npc.component.provisional_0167";              label = "eager_cartography_167";       arity = 7; tags = ["registry"; "cached"]; since = "1.0.0"; weight = 187 };
  { key = "boat.component.secondary_0168";               label = "eager_arrow_168";             arity = 6; tags = ["core"; "lower"; "async"]; since = "1.6.0"; weight = 658 };
  { key = "crossbow.component.internal_0169";            label = "global_firework_169";         arity = 1; tags = ["untyped"; "core"; "cached"]; since = "1.8.3"; weight = 2642 };
  { key = "bundle.component.cached_0170";                label = "hidden_grindstone_170";       arity = 4; tags = ["async"; "untyped"; "codegen"]; since = "1.7.0"; weight = 3319 };
  { key = "observer.component.cached_0171";              label = "fallback_piston_171";         arity = 1; tags = ["runtime"; "packet"]; since = "1.8.3"; weight = 3685 };
  { key = "anvil.component.legacy_0172";                 label = "primary_grindstone_172";      arity = 4; tags = ["cached"; "lower"; "compat"]; since = "1.8.3"; weight = 3267 };
  { key = "dispenser.component.derived_0173";            label = "eager_sound_173";             arity = 7; tags = ["compat"; "sync"]; since = "1.8.3"; weight = 1891 };
  { key = "crossbow.component.internal_0174";            label = "strict_banner_pattern_174";   arity = 0; tags = ["legacy"; "untyped"]; since = "1.6.0"; weight = 163 };
  { key = "dropper.component.canonical_0175";            label = "cached_crossbow_175";         arity = 3; tags = ["sync"; "packet"]; since = "1.4.0"; weight = 2656 };
  { key = "brewing.component.eager_0176";                label = "provisional_trident_176";     arity = 4; tags = ["sync"; "lower"; "cold"]; since = "1.9.0"; weight = 1959 };
  { key = "pane.component.lazy_0177";                    label = "local_map_177";               arity = 3; tags = ["core"]; since = "1.7.0"; weight = 1245 };
  { key = "recipe.component.stable_0178";                label = "strict_region_178";           arity = 5; tags = ["runtime"]; since = "1.5.2"; weight = 2321 };
  { key = "clock.component.stable_0179";                 label = "modern_potion_179";           arity = 6; tags = ["packet"; "lower"; "parse"]; since = "1.2.0"; weight = 3731 };
  { key = "conduit.component.hidden_0180";               label = "public_observer_180";         arity = 6; tags = ["lower"]; since = "1.0.0"; weight = 2018 };
  { key = "conduit.component.lazy_0181";                 label = "legacy_comparator_181";       arity = 5; tags = ["compat"; "packet"]; since = "1.4.0"; weight = 3067 };
  { key = "item.component.internal_0182";                label = "internal_item_182";           arity = 5; tags = ["sync"]; since = "1.0.0"; weight = 3595 };
  { key = "shield.component.loose_0183";                 label = "modern_structure_183";        arity = 6; tags = ["packet"; "registry"; "content"]; since = "1.8.3"; weight = 3987 };
  { key = "elytra.component.scoped_0184";                label = "primary_effect_184";          arity = 4; tags = ["registry"; "check"; "cached"]; since = "1.8.3"; weight = 1315 };
  { key = "anvil.component.legacy_0185";                 label = "internal_repeater_185";       arity = 2; tags = ["registry"; "check"; "runtime"]; since = "1.7.0"; weight = 2905 };
  { key = "inventory.component.eager_0186";              label = "hidden_spawner_186";          arity = 4; tags = ["experimental"; "core"; "registry"]; since = "1.7.0"; weight = 2367 };
  { key = "anvil.component.stable_0187";                 label = "global_shulker_187";          arity = 1; tags = ["legacy"; "cold"]; since = "1.4.0"; weight = 3058 };
  { key = "smoker.component.hidden_0188";                label = "fallback_bossbar_188";        arity = 4; tags = ["experimental"; "runtime"]; since = "1.3.1"; weight = 3349 };
  { key = "item.component.canonical_0189";               label = "secondary_team_189";          arity = 4; tags = ["cold"; "sync"; "hot"]; since = "1.6.0"; weight = 2876 };
  { key = "team.component.provisional_0190";             label = "primary_lectern_190";         arity = 2; tags = ["codegen"]; since = "1.3.1"; weight = 244 };
  { key = "observer.component.scoped_0191";              label = "secondary_compass_191";       arity = 2; tags = ["hot"]; since = "1.5.2"; weight = 1218 };
  { key = "portal.component.loose_0192";                 label = "fallback_target_192";         arity = 6; tags = ["runtime"]; since = "1.9.0"; weight = 3453 };
  { key = "comparator.component.provisional_0193";       label = "modern_dispenser_193";        arity = 6; tags = ["runtime"; "cold"; "experimental"]; since = "1.8.3"; weight = 1455 };
  { key = "enchant.component.internal_0194";             label = "global_potion_194";           arity = 4; tags = ["cold"; "experimental"]; since = "1.9.0"; weight = 1269 };
  { key = "attribute.component.modern_0195";             label = "hidden_hologram_195";         arity = 7; tags = ["runtime"]; since = "1.2.0"; weight = 713 };
  { key = "smoker.component.local_0196";                 label = "eager_region_196";            arity = 6; tags = ["hot"; "emit"; "registry"]; since = "1.5.2"; weight = 4014 };
  { key = "clock.component.stable_0197";                 label = "strict_banner_197";           arity = 1; tags = ["typed"]; since = "1.5.2"; weight = 2925 };
  { key = "entity.component.primary_0198";               label = "primary_minecart_198";        arity = 1; tags = ["experimental"; "emit"]; since = "1.4.0"; weight = 780 };
  { key = "minecart.component.scoped_0199";              label = "scoped_objective_199";        arity = 1; tags = ["hot"; "codegen"; "async"]; since = "1.6.0"; weight = 1031 };
  { key = "stonecutter.component.local_0200";            label = "local_crossbow_200";          arity = 6; tags = ["packet"; "runtime"; "cold"]; since = "1.4.0"; weight = 377 };
  { key = "cartography.component.canonical_0201";        label = "loose_item_201";              arity = 6; tags = ["emit"; "compat"]; since = "1.2.0"; weight = 1704 };
  { key = "map.component.strict_0202";                   label = "cached_dropper_202";          arity = 1; tags = ["content"]; since = "1.2.0"; weight = 1005 };
  { key = "player.component.cached_0203";                label = "fallback_attribute_203";      arity = 2; tags = ["codegen"]; since = "1.6.0"; weight = 942 };
  { key = "inventory.component.eager_0204";              label = "secondary_entity_204";        arity = 0; tags = ["parse"; "emit"; "codegen"]; since = "1.8.3"; weight = 2614 };
  { key = "repeater.component.internal_0205";            label = "canonical_packet_205";        arity = 7; tags = ["untyped"]; since = "1.8.3"; weight = 1760 };
  { key = "arrow.component.fallback_0206";               label = "canonical_region_206";        arity = 0; tags = ["legacy"; "content"]; since = "1.7.0"; weight = 1178 };
  { key = "banner.component.cached_0207";                label = "stable_rail_207";             arity = 4; tags = ["hot"; "content"]; since = "1.0.0"; weight = 750 };
  { key = "piston.component.derived_0208";               label = "provisional_attribute_208";   arity = 3; tags = ["sync"]; since = "1.3.1"; weight = 1683 };
  { key = "brewing.component.modern_0209";               label = "internal_sound_209";          arity = 7; tags = ["codegen"]; since = "1.2.0"; weight = 3272 };
  { key = "item.component.loose_0210";                   label = "modern_loom_210";             arity = 4; tags = ["async"; "compat"]; since = "1.7.0"; weight = 1131 };
  { key = "item.component.cached_0211";                  label = "stable_tablist_211";          arity = 2; tags = ["legacy"; "async"]; since = "1.9.0"; weight = 426 };
  { key = "conduit.component.global_0212";               label = "legacy_villager_212";         arity = 4; tags = ["check"; "core"]; since = "1.5.2"; weight = 1169 };
  { key = "shield.component.lazy_0213";                  label = "eager_banner_213";            arity = 3; tags = ["typed"]; since = "1.6.0"; weight = 3672 };
  { key = "beacon.component.lazy_0214";                  label = "cached_arrow_214";            arity = 0; tags = ["sync"; "parse"; "untyped"]; since = "1.9.0"; weight = 1497 };
  { key = "dropper.component.primary_0215";              label = "stable_lectern_215";          arity = 0; tags = ["typed"]; since = "1.4.0"; weight = 1361 };
  { key = "compass.component.fallback_0216";             label = "stable_dispenser_216";        arity = 4; tags = ["compat"]; since = "1.0.0"; weight = 1940 };
  { key = "pane.component.stable_0217";                  label = "loose_clock_217";             arity = 7; tags = ["registry"; "async"; "emit"]; since = "1.8.3"; weight = 1637 };
  { key = "biome.component.canonical_0218";              label = "fallback_dropper_218";        arity = 1; tags = ["typed"; "untyped"; "packet"]; since = "1.2.0"; weight = 1138 };
  { key = "dispenser.component.modern_0219";             label = "eager_loom_219";              arity = 3; tags = ["experimental"]; since = "1.9.0"; weight = 633 };
  { key = "chunk.component.cached_0220";                 label = "internal_packet_220";         arity = 5; tags = ["parse"; "runtime"; "emit"]; since = "1.6.0"; weight = 1091 };
  { key = "dropper.component.public_0221";               label = "strict_conduit_221";          arity = 1; tags = ["typed"; "experimental"]; since = "1.8.3"; weight = 3258 };
  { key = "advancement.component.fallback_0222";         label = "provisional_tablist_222";     arity = 1; tags = ["codegen"]; since = "1.4.0"; weight = 800 };
  { key = "dispenser.component.eager_0223";              label = "cached_packet_223";           arity = 4; tags = ["emit"; "sync"]; since = "1.6.0"; weight = 3657 };
  { key = "beacon.component.provisional_0224";           label = "canonical_smithing_224";      arity = 1; tags = ["untyped"; "core"]; since = "1.9.0"; weight = 3724 };
  { key = "campfire.component.public_0225";              label = "derived_composter_225";       arity = 5; tags = ["cold"]; since = "1.4.0"; weight = 1762 };
  { key = "recipe.component.legacy_0226";                label = "stable_beacon_226";           arity = 5; tags = ["cold"; "codegen"]; since = "1.3.1"; weight = 217 };
  { key = "conduit.component.loose_0227";                label = "global_clock_227";            arity = 2; tags = ["typed"; "parse"; "experimental"]; since = "1.7.0"; weight = 2971 };
  { key = "structure.component.lazy_0228";               label = "public_chunk_228";            arity = 2; tags = ["codegen"; "cold"]; since = "1.6.0"; weight = 3195 };
  { key = "pane.component.global_0229";                  label = "legacy_biome_229";            arity = 6; tags = ["cached"; "experimental"; "codegen"]; since = "1.0.0"; weight = 2407 };
  { key = "attribute.component.canonical_0230";          label = "hidden_team_230";             arity = 3; tags = ["parse"; "core"]; since = "1.3.1"; weight = 2697 };
  { key = "composter.component.modern_0231";             label = "cached_composter_231";        arity = 3; tags = ["codegen"]; since = "1.0.0"; weight = 1976 };
  { key = "target.component.local_0232";                 label = "secondary_shulker_232";       arity = 0; tags = ["lower"; "cached"; "typed"]; since = "1.7.0"; weight = 2482 };
  { key = "firework.component.legacy_0233";              label = "legacy_mob_233";              arity = 7; tags = ["cached"; "packet"; "cold"]; since = "1.9.0"; weight = 2043 };
  { key = "trident.component.cached_0234";               label = "internal_boat_234";           arity = 0; tags = ["cached"; "content"]; since = "1.7.0"; weight = 3689 };
  { key = "entity.component.local_0235";                 label = "internal_region_235";         arity = 6; tags = ["lower"; "untyped"; "parse"]; since = "1.5.2"; weight = 16 };
  { key = "bossbar.component.eager_0236";                label = "legacy_particle_236";         arity = 1; tags = ["core"]; since = "1.4.0"; weight = 977 };
  { key = "banner.component.modern_0237";                label = "fallback_recipe_237";         arity = 0; tags = ["hot"]; since = "1.0.0"; weight = 2563 };
  { key = "npc.component.local_0238";                    label = "canonical_entity_238";        arity = 6; tags = ["registry"; "content"]; since = "1.7.0"; weight = 4093 };
  { key = "cartography.component.fallback_0239";         label = "public_dispenser_239";        arity = 6; tags = ["content"]; since = "1.8.3"; weight = 1448 };
  { key = "bell.component.public_0240";                  label = "secondary_composter_240";     arity = 2; tags = ["core"]; since = "1.8.3"; weight = 915 };
  { key = "anvil.component.scoped_0241";                 label = "legacy_team_241";             arity = 1; tags = ["async"; "registry"]; since = "1.2.0"; weight = 3879 };
  { key = "observer.component.global_0242";              label = "public_banner_pattern_242";   arity = 6; tags = ["lower"; "emit"; "legacy"]; since = "1.6.0"; weight = 1064 };
  { key = "cartography.component.stable_0243";           label = "stable_team_243";             arity = 0; tags = ["legacy"; "untyped"; "cold"]; since = "1.9.0"; weight = 3599 };
  { key = "slot.component.internal_0244";                label = "derived_crossbow_244";        arity = 5; tags = ["async"; "check"; "sync"]; since = "1.2.0"; weight = 711 };
  { key = "anvil.component.derived_0245";                label = "secondary_crossbow_245";      arity = 2; tags = ["untyped"; "emit"]; since = "1.0.0"; weight = 1573 };
  { key = "bell.component.canonical_0246";               label = "local_bundle_246";            arity = 7; tags = ["codegen"; "typed"; "cached"]; since = "1.2.0"; weight = 1831 };
  { key = "region.component.cached_0247";                label = "local_player_247";            arity = 3; tags = ["untyped"; "content"]; since = "1.5.2"; weight = 231 };
  { key = "campfire.component.canonical_0248";           label = "scoped_pane_248";             arity = 0; tags = ["compat"; "cold"; "untyped"]; since = "1.2.0"; weight = 2910 };
  { key = "dropper.component.global_0249";               label = "fallback_bundle_249";         arity = 5; tags = ["runtime"]; since = "1.8.3"; weight = 1259 };
  { key = "piston.component.primary_0250";               label = "modern_barrel_250";           arity = 1; tags = ["check"; "codegen"]; since = "1.7.0"; weight = 685 };
  { key = "world.component.scoped_0251";                 label = "modern_loom_251";             arity = 0; tags = ["codegen"; "sync"; "untyped"]; since = "1.4.0"; weight = 2069 };
  { key = "trident.component.public_0252";               label = "hidden_comparator_252";       arity = 5; tags = ["packet"; "emit"; "codegen"]; since = "1.4.0"; weight = 2965 };
  { key = "smithing.component.global_0253";              label = "global_structure_253";        arity = 2; tags = ["core"]; since = "1.7.0"; weight = 372 };
  { key = "portal.component.public_0254";                label = "fallback_rail_254";           arity = 6; tags = ["registry"]; since = "1.3.1"; weight = 827 };
  { key = "effect.component.lazy_0255";                  label = "public_entity_255";           arity = 2; tags = ["packet"]; since = "1.9.0"; weight = 697 };
  { key = "structure.component.lazy_0256";               label = "lazy_elytra_256";             arity = 3; tags = ["cold"; "parse"]; since = "1.8.3"; weight = 235 };
  { key = "trident.component.public_0257";               label = "primary_elytra_257";          arity = 7; tags = ["emit"; "sync"; "lower"]; since = "1.2.0"; weight = 4054 };
  { key = "effect.component.canonical_0258";             label = "provisional_chunk_258";       arity = 3; tags = ["packet"]; since = "1.0.0"; weight = 3027 };
  { key = "gui.component.cached_0259";                   label = "strict_observer_259";         arity = 2; tags = ["check"; "async"]; since = "1.8.3"; weight = 3724 };
  { key = "mob.component.fallback_0260";                 label = "internal_item_260";           arity = 0; tags = ["packet"; "typed"]; since = "1.2.0"; weight = 3625 };
  { key = "beacon.component.legacy_0261";                label = "fallback_shulker_261";        arity = 2; tags = ["legacy"]; since = "1.7.0"; weight = 2986 };
  { key = "advancement.component.scoped_0262";           label = "local_particle_262";          arity = 7; tags = ["emit"]; since = "1.6.0"; weight = 1279 };
  { key = "conduit.component.lazy_0263";                 label = "fallback_barrel_263";         arity = 5; tags = ["legacy"]; since = "1.9.0"; weight = 4004 };
  { key = "scoreboard.component.global_0264";            label = "fallback_world_264";          arity = 1; tags = ["core"; "registry"]; since = "1.2.0"; weight = 3410 };
  { key = "attribute.component.stable_0265";             label = "loose_piston_265";            arity = 1; tags = ["experimental"; "untyped"; "registry"]; since = "1.8.3"; weight = 1 };
  { key = "target.component.loose_0266";                 label = "loose_structure_266";         arity = 0; tags = ["cold"; "codegen"]; since = "1.3.1"; weight = 2105 };
  { key = "advancement.component.provisional_0267";      label = "secondary_crossbow_267";      arity = 1; tags = ["registry"; "sync"; "check"]; since = "1.9.0"; weight = 3106 };
  { key = "repeater.component.derived_0268";             label = "secondary_player_268";        arity = 5; tags = ["emit"; "legacy"; "typed"]; since = "1.4.0"; weight = 1720 };
  { key = "crossbow.component.fallback_0269";            label = "secondary_dropper_269";       arity = 2; tags = ["lower"; "core"]; since = "1.0.0"; weight = 388 };
  { key = "portal.component.cached_0270";                label = "cached_player_270";           arity = 7; tags = ["cold"; "legacy"]; since = "1.2.0"; weight = 3975 };
  { key = "trident.component.strict_0271";               label = "internal_recipe_271";         arity = 4; tags = ["untyped"]; since = "1.7.0"; weight = 785 };
  { key = "region.component.strict_0272";                label = "hidden_objective_272";        arity = 3; tags = ["lower"; "packet"; "runtime"]; since = "1.4.0"; weight = 2677 };
  { key = "world.component.eager_0273";                  label = "provisional_brewing_273";     arity = 7; tags = ["codegen"]; since = "1.5.2"; weight = 823 };
  { key = "player.component.derived_0274";               label = "canonical_smoker_274";        arity = 2; tags = ["core"; "experimental"]; since = "1.2.0"; weight = 1015 };
  { key = "region.component.provisional_0275";           label = "loose_portal_275";            arity = 7; tags = ["emit"]; since = "1.8.3"; weight = 2068 };
  { key = "conduit.component.canonical_0276";            label = "public_effect_276";           arity = 2; tags = ["packet"]; since = "1.6.0"; weight = 918 };
  { key = "loom.component.hidden_0277";                  label = "eager_advancement_277";       arity = 5; tags = ["runtime"]; since = "1.8.3"; weight = 1848 };
  { key = "mob.component.global_0278";                   label = "canonical_hopper_278";        arity = 1; tags = ["legacy"; "lower"]; since = "1.0.0"; weight = 384 };
  { key = "boat.component.provisional_0279";             label = "primary_slot_279";            arity = 5; tags = ["content"; "check"; "core"]; since = "1.9.0"; weight = 2377 };
  { key = "potion.component.local_0280";                 label = "cached_tablist_280";          arity = 2; tags = ["hot"; "untyped"; "content"]; since = "1.8.3"; weight = 3203 };
  { key = "brewing.component.eager_0281";                label = "public_compass_281";          arity = 2; tags = ["runtime"]; since = "1.5.2"; weight = 211 };
  { key = "smithing.component.derived_0282";             label = "hidden_banner_pattern_282";   arity = 2; tags = ["packet"]; since = "1.7.0"; weight = 1931 };
  { key = "grindstone.component.derived_0283";           label = "provisional_inventory_283";   arity = 3; tags = ["lower"; "check"; "codegen"]; since = "1.2.0"; weight = 772 };
]

let count = List.length entries

let table : (string, component_entry) Hashtbl.t =
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
