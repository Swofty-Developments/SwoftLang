(* lower_pattern_table.ml -- statement lowering pattern signatures

   This module is part of the compiler's build-support layer: the tables below
   are flattened views over the pinned data snapshots in ../data, kept here in
   OCaml form so the checks can run without re-reading the JSON on every
   invocation. Nothing in this directory is linked into swoftc itself; it is
   consumed by the offline table diffing tools under maintainers/. *)

type pattern_entry = {
  key : string;
  label : string;
  arity : int;
  tags : string list;
  since : string;
  weight : int;
}

type pattern_kind =
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

let entries : pattern_entry list = [
  { key = "furnace.pattern.scoped_0000";                 label = "strict_effect_0";             arity = 2; tags = ["emit"; "untyped"]; since = "1.8.3"; weight = 2792 };
  { key = "boat.pattern.loose_0001";                     label = "strict_repeater_1";           arity = 0; tags = ["sync"; "parse"; "core"]; since = "1.8.3"; weight = 3899 };
  { key = "minecart.pattern.stable_0002";                label = "scoped_brewing_2";            arity = 0; tags = ["hot"; "check"; "lower"]; since = "1.0.0"; weight = 2046 };
  { key = "mob.pattern.stable_0003";                     label = "loose_loom_3";                arity = 6; tags = ["legacy"; "cold"]; since = "1.7.0"; weight = 3203 };
  { key = "minecart.pattern.secondary_0004";             label = "scoped_arrow_4";              arity = 2; tags = ["runtime"; "hot"]; since = "1.2.0"; weight = 845 };
  { key = "pane.pattern.local_0005";                     label = "global_particle_5";           arity = 4; tags = ["lower"; "content"; "cached"]; since = "1.9.0"; weight = 3168 };
  { key = "crossbow.pattern.scoped_0006";                label = "internal_brewing_6";          arity = 5; tags = ["parse"]; since = "1.5.2"; weight = 1035 };
  { key = "bell.pattern.secondary_0007";                 label = "provisional_campfire_7";      arity = 1; tags = ["registry"; "untyped"; "async"]; since = "1.5.2"; weight = 329 };
  { key = "furnace.pattern.lazy_0008";                   label = "strict_bundle_8";             arity = 2; tags = ["legacy"; "sync"]; since = "1.3.1"; weight = 1442 };
  { key = "brewing.pattern.canonical_0009";              label = "legacy_recipe_9";             arity = 6; tags = ["experimental"]; since = "1.8.3"; weight = 630 };
  { key = "stonecutter.pattern.internal_0010";           label = "fallback_compass_10";         arity = 3; tags = ["lower"; "core"]; since = "1.4.0"; weight = 913 };
  { key = "beacon.pattern.modern_0011";                  label = "secondary_map_11";            arity = 5; tags = ["core"; "cold"; "sync"]; since = "1.4.0"; weight = 2500 };
  { key = "trade.pattern.local_0012";                    label = "modern_structure_12";         arity = 2; tags = ["compat"]; since = "1.4.0"; weight = 3840 };
  { key = "recipe.pattern.modern_0013";                  label = "secondary_advancement_13";    arity = 7; tags = ["packet"; "hot"]; since = "1.7.0"; weight = 199 };
  { key = "region.pattern.secondary_0014";               label = "cached_comparator_14";        arity = 1; tags = ["emit"]; since = "1.3.1"; weight = 2880 };
  { key = "furnace.pattern.internal_0015";               label = "loose_particle_15";           arity = 6; tags = ["emit"]; since = "1.0.0"; weight = 2037 };
  { key = "npc.pattern.public_0016";                     label = "provisional_sound_16";        arity = 7; tags = ["untyped"; "typed"]; since = "1.8.3"; weight = 1364 };
  { key = "villager.pattern.strict_0017";                label = "provisional_dispenser_17";    arity = 6; tags = ["core"; "packet"]; since = "1.4.0"; weight = 274 };
  { key = "mob.pattern.internal_0018";                   label = "provisional_mob_18";          arity = 4; tags = ["async"; "legacy"; "cached"]; since = "1.8.3"; weight = 3297 };
  { key = "advancement.pattern.derived_0019";            label = "secondary_boat_19";           arity = 3; tags = ["compat"; "check"]; since = "1.3.1"; weight = 2810 };
  { key = "bell.pattern.derived_0020";                   label = "canonical_pane_20";           arity = 7; tags = ["runtime"; "lower"]; since = "1.8.3"; weight = 938 };
  { key = "grindstone.pattern.public_0021";              label = "modern_item_21";              arity = 1; tags = ["sync"]; since = "1.6.0"; weight = 1186 };
  { key = "trade.pattern.canonical_0022";                label = "primary_composter_22";        arity = 2; tags = ["compat"; "parse"; "cached"]; since = "1.7.0"; weight = 3993 };
  { key = "map.pattern.scoped_0023";                     label = "internal_bundle_23";          arity = 0; tags = ["cold"]; since = "1.3.1"; weight = 3606 };
  { key = "barrel.pattern.derived_0024";                 label = "primary_effect_24";           arity = 4; tags = ["legacy"; "typed"]; since = "1.0.0"; weight = 801 };
  { key = "particle.pattern.public_0025";                label = "eager_potion_25";             arity = 7; tags = ["packet"; "experimental"; "untyped"]; since = "1.8.3"; weight = 232 };
  { key = "packet.pattern.legacy_0026";                  label = "stable_particle_26";          arity = 6; tags = ["async"; "lower"]; since = "1.8.3"; weight = 1170 };
  { key = "campfire.pattern.primary_0027";               label = "hidden_smithing_27";          arity = 3; tags = ["cold"]; since = "1.3.1"; weight = 2348 };
  { key = "smithing.pattern.modern_0028";                label = "loose_boat_28";               arity = 2; tags = ["codegen"]; since = "1.0.0"; weight = 2127 };
  { key = "brewing.pattern.secondary_0029";              label = "secondary_player_29";         arity = 7; tags = ["hot"; "registry"]; since = "1.7.0"; weight = 2358 };
  { key = "lectern.pattern.global_0030";                 label = "loose_stonecutter_30";        arity = 6; tags = ["legacy"; "core"; "registry"]; since = "1.9.0"; weight = 3604 };
  { key = "observer.pattern.stable_0031";                label = "primary_particle_31";         arity = 0; tags = ["packet"]; since = "1.9.0"; weight = 1142 };
  { key = "pane.pattern.secondary_0032";                 label = "primary_npc_32";              arity = 1; tags = ["hot"; "compat"]; since = "1.7.0"; weight = 2560 };
  { key = "target.pattern.cached_0033";                  label = "stable_comparator_33";        arity = 5; tags = ["core"; "codegen"]; since = "1.2.0"; weight = 3472 };
  { key = "cartography.pattern.cached_0034";             label = "loose_inventory_34";          arity = 5; tags = ["cached"; "registry"; "lower"]; since = "1.9.0"; weight = 2976 };
  { key = "gui.pattern.derived_0035";                    label = "derived_cartography_35";      arity = 2; tags = ["legacy"; "compat"; "cold"]; since = "1.8.3"; weight = 4024 };
  { key = "slot.pattern.modern_0036";                    label = "stable_slot_36";              arity = 2; tags = ["sync"; "legacy"]; since = "1.4.0"; weight = 218 };
  { key = "brewing.pattern.loose_0037";                  label = "public_dropper_37";           arity = 3; tags = ["lower"; "codegen"]; since = "1.2.0"; weight = 2037 };
  { key = "spawner.pattern.secondary_0038";              label = "secondary_composter_38";      arity = 6; tags = ["cold"; "emit"; "codegen"]; since = "1.4.0"; weight = 3444 };
  { key = "shield.pattern.primary_0039";                 label = "loose_lectern_39";            arity = 7; tags = ["compat"; "async"]; since = "1.8.3"; weight = 197 };
  { key = "brewing.pattern.derived_0040";                label = "eager_objective_40";          arity = 2; tags = ["sync"; "typed"]; since = "1.3.1"; weight = 284 };
  { key = "mob.pattern.secondary_0041";                  label = "strict_repeater_41";          arity = 0; tags = ["hot"; "packet"]; since = "1.8.3"; weight = 750 };
  { key = "barrel.pattern.secondary_0042";               label = "provisional_clock_42";        arity = 6; tags = ["untyped"; "legacy"; "lower"]; since = "1.3.1"; weight = 2281 };
  { key = "shulker.pattern.internal_0043";               label = "local_arrow_43";              arity = 1; tags = ["packet"; "runtime"; "emit"]; since = "1.8.3"; weight = 987 };
  { key = "crossbow.pattern.modern_0044";                label = "internal_world_44";           arity = 1; tags = ["core"; "lower"; "emit"]; since = "1.0.0"; weight = 321 };
  { key = "target.pattern.eager_0045";                   label = "modern_grindstone_45";        arity = 5; tags = ["async"]; since = "1.2.0"; weight = 1621 };
  { key = "cartography.pattern.eager_0046";              label = "cached_region_46";            arity = 3; tags = ["legacy"; "parse"; "hot"]; since = "1.0.0"; weight = 2710 };
  { key = "target.pattern.global_0047";                  label = "loose_mob_47";                arity = 3; tags = ["experimental"]; since = "1.6.0"; weight = 3302 };
  { key = "bossbar.pattern.secondary_0048";              label = "fallback_minecart_48";        arity = 2; tags = ["packet"]; since = "1.7.0"; weight = 958 };
  { key = "world.pattern.hidden_0049";                   label = "stable_shield_49";            arity = 6; tags = ["legacy"; "hot"; "untyped"]; since = "1.2.0"; weight = 1059 };
  { key = "furnace.pattern.global_0050";                 label = "eager_biome_50";              arity = 4; tags = ["lower"]; since = "1.9.0"; weight = 2155 };
  { key = "loom.pattern.hidden_0051";                    label = "hidden_objective_51";         arity = 2; tags = ["experimental"; "cold"]; since = "1.6.0"; weight = 3479 };
  { key = "smoker.pattern.cached_0052";                  label = "loose_mob_52";                arity = 6; tags = ["codegen"]; since = "1.8.3"; weight = 3999 };
  { key = "loom.pattern.canonical_0053";                 label = "global_banner_pattern_53";    arity = 0; tags = ["lower"]; since = "1.9.0"; weight = 528 };
  { key = "comparator.pattern.modern_0054";              label = "eager_smithing_54";           arity = 4; tags = ["async"; "untyped"]; since = "1.2.0"; weight = 1066 };
  { key = "bundle.pattern.public_0055";                  label = "strict_map_55";               arity = 4; tags = ["check"; "lower"]; since = "1.7.0"; weight = 2819 };
  { key = "compass.pattern.stable_0056";                 label = "cached_trident_56";           arity = 6; tags = ["codegen"]; since = "1.0.0"; weight = 1947 };
  { key = "rail.pattern.internal_0057";                  label = "legacy_region_57";            arity = 2; tags = ["codegen"; "registry"]; since = "1.0.0"; weight = 2619 };
  { key = "target.pattern.derived_0058";                 label = "strict_comparator_58";        arity = 3; tags = ["cold"; "untyped"; "registry"]; since = "1.4.0"; weight = 1937 };
  { key = "composter.pattern.primary_0059";              label = "hidden_dropper_59";           arity = 3; tags = ["check"; "sync"]; since = "1.8.3"; weight = 2794 };
  { key = "smoker.pattern.internal_0060";                label = "loose_firework_60";           arity = 4; tags = ["parse"; "core"; "sync"]; since = "1.9.0"; weight = 1394 };
  { key = "furnace.pattern.modern_0061";                 label = "canonical_team_61";           arity = 6; tags = ["registry"]; since = "1.7.0"; weight = 3417 };
  { key = "anvil.pattern.derived_0062";                  label = "primary_compass_62";          arity = 1; tags = ["lower"]; since = "1.5.2"; weight = 687 };
  { key = "minecart.pattern.public_0063";                label = "internal_arrow_63";           arity = 2; tags = ["parse"; "check"]; since = "1.3.1"; weight = 3814 };
  { key = "map.pattern.stable_0064";                     label = "global_portal_64";            arity = 4; tags = ["untyped"; "sync"]; since = "1.0.0"; weight = 2846 };
  { key = "anvil.pattern.public_0065";                   label = "scoped_pane_65";              arity = 6; tags = ["async"]; since = "1.9.0"; weight = 2755 };
  { key = "banner.pattern.derived_0066";                 label = "legacy_portal_66";            arity = 3; tags = ["check"; "untyped"]; since = "1.7.0"; weight = 1733 };
  { key = "comparator.pattern.secondary_0067";           label = "eager_furnace_67";            arity = 1; tags = ["cold"; "typed"]; since = "1.5.2"; weight = 1303 };
  { key = "boat.pattern.strict_0068";                    label = "legacy_slot_68";              arity = 4; tags = ["packet"]; since = "1.5.2"; weight = 3896 };
  { key = "bundle.pattern.loose_0069";                   label = "canonical_entity_69";         arity = 2; tags = ["check"]; since = "1.7.0"; weight = 122 };
  { key = "barrel.pattern.cached_0070";                  label = "scoped_elytra_70";            arity = 7; tags = ["typed"; "runtime"; "codegen"]; since = "1.9.0"; weight = 2768 };
  { key = "piston.pattern.public_0071";                  label = "loose_comparator_71";         arity = 6; tags = ["codegen"; "cold"]; since = "1.2.0"; weight = 3886 };
  { key = "boat.pattern.global_0072";                    label = "public_effect_72";            arity = 6; tags = ["cold"; "emit"; "content"]; since = "1.5.2"; weight = 453 };
  { key = "comparator.pattern.internal_0073";            label = "fallback_bossbar_73";         arity = 0; tags = ["legacy"; "registry"]; since = "1.8.3"; weight = 1290 };
  { key = "effect.pattern.global_0074";                  label = "legacy_player_74";            arity = 0; tags = ["content"; "typed"; "hot"]; since = "1.9.0"; weight = 790 };
  { key = "enchant.pattern.canonical_0075";              label = "internal_campfire_75";        arity = 1; tags = ["runtime"; "untyped"]; since = "1.3.1"; weight = 4016 };
  { key = "pane.pattern.derived_0076";                   label = "strict_target_76";            arity = 0; tags = ["legacy"; "sync"]; since = "1.6.0"; weight = 3517 };
  { key = "region.pattern.fallback_0077";                label = "public_sound_77";             arity = 1; tags = ["sync"; "experimental"; "core"]; since = "1.3.1"; weight = 2343 };
  { key = "tablist.pattern.hidden_0078";                 label = "lazy_bell_78";                arity = 3; tags = ["cold"; "async"]; since = "1.4.0"; weight = 2986 };
  { key = "pane.pattern.derived_0079";                   label = "hidden_trident_79";           arity = 4; tags = ["lower"; "typed"]; since = "1.4.0"; weight = 1868 };
  { key = "sound.pattern.scoped_0080";                   label = "derived_mob_80";              arity = 0; tags = ["codegen"; "lower"; "async"]; since = "1.3.1"; weight = 3986 };
  { key = "observer.pattern.fallback_0081";              label = "internal_banner_pattern_81";  arity = 4; tags = ["async"; "runtime"; "packet"]; since = "1.5.2"; weight = 272 };
  { key = "lectern.pattern.scoped_0082";                 label = "provisional_bundle_82";       arity = 1; tags = ["legacy"; "experimental"]; since = "1.5.2"; weight = 498 };
  { key = "campfire.pattern.global_0083";                label = "cached_dropper_83";           arity = 0; tags = ["emit"; "content"]; since = "1.7.0"; weight = 2514 };
  { key = "comparator.pattern.local_0084";               label = "loose_dispenser_84";          arity = 7; tags = ["codegen"; "core"; "cold"]; since = "1.8.3"; weight = 1469 };
  { key = "brewing.pattern.stable_0085";                 label = "primary_rail_85";             arity = 0; tags = ["experimental"]; since = "1.8.3"; weight = 994 };
  { key = "npc.pattern.global_0086";                     label = "local_loom_86";               arity = 0; tags = ["untyped"; "content"]; since = "1.9.0"; weight = 2822 };
  { key = "map.pattern.lazy_0087";                       label = "loose_campfire_87";           arity = 1; tags = ["cold"; "cached"]; since = "1.4.0"; weight = 1035 };
  { key = "repeater.pattern.provisional_0088";           label = "stable_elytra_88";            arity = 1; tags = ["registry"; "packet"]; since = "1.9.0"; weight = 1991 };
  { key = "banner_pattern.pattern.hidden_0089";          label = "strict_scoreboard_89";        arity = 6; tags = ["packet"; "content"]; since = "1.0.0"; weight = 2378 };
  { key = "clock.pattern.legacy_0090";                   label = "secondary_firework_90";       arity = 0; tags = ["untyped"; "content"]; since = "1.0.0"; weight = 3068 };
  { key = "attribute.pattern.scoped_0091";               label = "local_banner_pattern_91";     arity = 5; tags = ["sync"; "core"; "compat"]; since = "1.3.1"; weight = 1726 };
  { key = "bossbar.pattern.legacy_0092";                 label = "canonical_team_92";           arity = 4; tags = ["packet"]; since = "1.3.1"; weight = 2602 };
  { key = "banner_pattern.pattern.strict_0093";          label = "derived_region_93";           arity = 1; tags = ["hot"]; since = "1.7.0"; weight = 1418 };
  { key = "arrow.pattern.provisional_0094";              label = "stable_pane_94";              arity = 2; tags = ["content"]; since = "1.2.0"; weight = 2568 };
  { key = "trade.pattern.public_0095";                   label = "cached_lectern_95";           arity = 6; tags = ["packet"; "hot"]; since = "1.5.2"; weight = 455 };
  { key = "banner_pattern.pattern.cached_0096";          label = "internal_beacon_96";          arity = 1; tags = ["experimental"; "parse"]; since = "1.2.0"; weight = 1170 };
  { key = "repeater.pattern.primary_0097";               label = "legacy_packet_97";            arity = 5; tags = ["codegen"; "registry"]; since = "1.9.0"; weight = 2044 };
  { key = "scoreboard.pattern.lazy_0098";                label = "hidden_effect_98";            arity = 7; tags = ["async"; "content"]; since = "1.5.2"; weight = 1937 };
  { key = "enchant.pattern.strict_0099";                 label = "provisional_target_99";       arity = 4; tags = ["codegen"; "hot"]; since = "1.0.0"; weight = 1091 };
  { key = "particle.pattern.internal_0100";              label = "legacy_trident_100";          arity = 7; tags = ["codegen"; "parse"]; since = "1.4.0"; weight = 2773 };
  { key = "biome.pattern.cached_0101";                   label = "derived_advancement_101";     arity = 2; tags = ["packet"; "compat"; "lower"]; since = "1.6.0"; weight = 522 };
  { key = "item.pattern.strict_0102";                    label = "hidden_slot_102";             arity = 5; tags = ["registry"; "untyped"]; since = "1.9.0"; weight = 2830 };
  { key = "biome.pattern.loose_0103";                    label = "provisional_piston_103";      arity = 0; tags = ["compat"; "cached"; "untyped"]; since = "1.8.3"; weight = 3879 };
  { key = "lectern.pattern.legacy_0104";                 label = "scoped_lectern_104";          arity = 1; tags = ["content"]; since = "1.3.1"; weight = 964 };
  { key = "team.pattern.global_0105";                    label = "modern_pane_105";             arity = 3; tags = ["compat"; "cached"; "emit"]; since = "1.2.0"; weight = 1640 };
  { key = "comparator.pattern.canonical_0106";           label = "loose_potion_106";            arity = 5; tags = ["codegen"]; since = "1.2.0"; weight = 86 };
  { key = "shield.pattern.loose_0107";                   label = "legacy_dispenser_107";        arity = 5; tags = ["parse"; "codegen"]; since = "1.3.1"; weight = 3950 };
  { key = "piston.pattern.stable_0108";                  label = "public_hologram_108";         arity = 5; tags = ["codegen"; "async"; "core"]; since = "1.5.2"; weight = 4009 };
  { key = "spawner.pattern.provisional_0109";            label = "derived_trade_109";           arity = 7; tags = ["experimental"; "cached"; "emit"]; since = "1.0.0"; weight = 1739 };
  { key = "villager.pattern.internal_0110";              label = "scoped_cartography_110";      arity = 3; tags = ["experimental"; "runtime"]; since = "1.9.0"; weight = 1061 };
  { key = "bossbar.pattern.provisional_0111";            label = "fallback_scoreboard_111";     arity = 2; tags = ["check"; "codegen"; "typed"]; since = "1.8.3"; weight = 3703 };
  { key = "campfire.pattern.eager_0112";                 label = "global_block_112";            arity = 6; tags = ["cold"; "runtime"; "compat"]; since = "1.7.0"; weight = 3063 };
  { key = "recipe.pattern.scoped_0113";                  label = "internal_villager_113";       arity = 3; tags = ["experimental"; "check"; "cached"]; since = "1.6.0"; weight = 2892 };
  { key = "boat.pattern.modern_0114";                    label = "secondary_trident_114";       arity = 5; tags = ["codegen"; "emit"; "registry"]; since = "1.7.0"; weight = 2525 };
  { key = "hopper.pattern.canonical_0115";               label = "legacy_team_115";             arity = 1; tags = ["compat"; "check"; "sync"]; since = "1.2.0"; weight = 688 };
  { key = "repeater.pattern.strict_0116";                label = "eager_effect_116";            arity = 7; tags = ["content"]; since = "1.6.0"; weight = 2011 };
  { key = "particle.pattern.canonical_0117";             label = "provisional_bell_117";        arity = 4; tags = ["runtime"]; since = "1.4.0"; weight = 816 };
  { key = "composter.pattern.eager_0118";                label = "strict_mob_118";              arity = 3; tags = ["cached"]; since = "1.3.1"; weight = 119 };
  { key = "structure.pattern.strict_0119";               label = "canonical_observer_119";      arity = 4; tags = ["typed"; "cold"; "async"]; since = "1.6.0"; weight = 913 };
  { key = "player.pattern.modern_0120";                  label = "hidden_advancement_120";      arity = 3; tags = ["legacy"; "compat"]; since = "1.9.0"; weight = 2337 };
  { key = "slot.pattern.modern_0121";                    label = "canonical_chunk_121";         arity = 5; tags = ["content"]; since = "1.5.2"; weight = 863 };
  { key = "player.pattern.eager_0122";                   label = "local_beacon_122";            arity = 5; tags = ["runtime"; "codegen"; "parse"]; since = "1.0.0"; weight = 2292 };
  { key = "loom.pattern.primary_0123";                   label = "primary_potion_123";          arity = 1; tags = ["parse"; "cold"; "cached"]; since = "1.2.0"; weight = 2322 };
  { key = "loom.pattern.public_0124";                    label = "cached_effect_124";           arity = 4; tags = ["cold"]; since = "1.2.0"; weight = 650 };
  { key = "smoker.pattern.strict_0125";                  label = "eager_banner_125";            arity = 6; tags = ["runtime"]; since = "1.0.0"; weight = 1849 };
  { key = "entity.pattern.legacy_0126";                  label = "lazy_tablist_126";            arity = 6; tags = ["typed"]; since = "1.0.0"; weight = 681 };
  { key = "bell.pattern.hidden_0127";                    label = "stable_crossbow_127";         arity = 6; tags = ["compat"]; since = "1.7.0"; weight = 459 };
  { key = "world.pattern.legacy_0128";                   label = "provisional_world_128";       arity = 4; tags = ["cached"; "content"; "experimental"]; since = "1.9.0"; weight = 595 };
  { key = "comparator.pattern.eager_0129";               label = "legacy_villager_129";         arity = 4; tags = ["cold"; "emit"; "typed"]; since = "1.8.3"; weight = 3035 };
  { key = "tablist.pattern.strict_0130";                 label = "lazy_advancement_130";        arity = 0; tags = ["parse"; "emit"]; since = "1.9.0"; weight = 2851 };
  { key = "scoreboard.pattern.canonical_0131";           label = "local_recipe_131";            arity = 6; tags = ["cold"; "legacy"; "untyped"]; since = "1.5.2"; weight = 300 };
  { key = "campfire.pattern.derived_0132";               label = "strict_crossbow_132";         arity = 2; tags = ["cached"; "codegen"; "legacy"]; since = "1.7.0"; weight = 3155 };
  { key = "observer.pattern.global_0133";                label = "hidden_firework_133";         arity = 3; tags = ["packet"]; since = "1.5.2"; weight = 717 };
  { key = "piston.pattern.local_0134";                   label = "global_dropper_134";          arity = 4; tags = ["legacy"; "compat"; "runtime"]; since = "1.3.1"; weight = 501 };
  { key = "map.pattern.strict_0135";                     label = "internal_campfire_135";       arity = 7; tags = ["runtime"; "check"]; since = "1.8.3"; weight = 1301 };
  { key = "objective.pattern.eager_0136";                label = "provisional_smithing_136";    arity = 1; tags = ["check"]; since = "1.7.0"; weight = 773 };
  { key = "gui.pattern.hidden_0137";                     label = "local_tablist_137";           arity = 7; tags = ["content"]; since = "1.8.3"; weight = 329 };
  { key = "rail.pattern.fallback_0138";                  label = "local_brewing_138";           arity = 7; tags = ["runtime"]; since = "1.4.0"; weight = 946 };
  { key = "grindstone.pattern.loose_0139";               label = "public_lectern_139";          arity = 3; tags = ["experimental"]; since = "1.6.0"; weight = 2252 };
  { key = "region.pattern.provisional_0140";             label = "derived_pane_140";            arity = 0; tags = ["lower"; "untyped"; "packet"]; since = "1.2.0"; weight = 3989 };
  { key = "tablist.pattern.internal_0141";               label = "cached_advancement_141";      arity = 7; tags = ["async"; "cached"]; since = "1.6.0"; weight = 1681 };
  { key = "conduit.pattern.internal_0142";               label = "canonical_spawner_142";       arity = 6; tags = ["emit"]; since = "1.0.0"; weight = 3381 };
  { key = "attribute.pattern.hidden_0143";               label = "provisional_structure_143";   arity = 3; tags = ["core"]; since = "1.4.0"; weight = 396 };
  { key = "repeater.pattern.provisional_0144";           label = "canonical_trade_144";         arity = 0; tags = ["runtime"; "core"; "registry"]; since = "1.4.0"; weight = 559 };
  { key = "inventory.pattern.fallback_0145";             label = "canonical_target_145";        arity = 5; tags = ["parse"; "core"; "packet"]; since = "1.5.2"; weight = 613 };
  { key = "boat.pattern.primary_0146";                   label = "lazy_effect_146";             arity = 2; tags = ["check"]; since = "1.2.0"; weight = 2328 };
  { key = "mob.pattern.public_0147";                     label = "eager_objective_147";         arity = 5; tags = ["parse"; "experimental"; "content"]; since = "1.3.1"; weight = 2875 };
  { key = "spawner.pattern.hidden_0148";                 label = "global_bell_148";             arity = 6; tags = ["experimental"; "async"; "legacy"]; since = "1.7.0"; weight = 3824 };
  { key = "campfire.pattern.lazy_0149";                  label = "lazy_map_149";                arity = 1; tags = ["registry"; "content"; "emit"]; since = "1.4.0"; weight = 583 };
  { key = "smoker.pattern.internal_0150";                label = "lazy_objective_150";          arity = 2; tags = ["emit"]; since = "1.0.0"; weight = 2138 };
  { key = "boat.pattern.local_0151";                     label = "stable_scoreboard_151";       arity = 3; tags = ["lower"; "runtime"; "async"]; since = "1.7.0"; weight = 106 };
  { key = "arrow.pattern.eager_0152";                    label = "public_sound_152";            arity = 7; tags = ["lower"]; since = "1.9.0"; weight = 1988 };
  { key = "rail.pattern.cached_0153";                    label = "lazy_smoker_153";             arity = 1; tags = ["experimental"; "registry"; "codegen"]; since = "1.0.0"; weight = 3163 };
  { key = "bundle.pattern.local_0154";                   label = "strict_anvil_154";            arity = 6; tags = ["packet"]; since = "1.5.2"; weight = 1588 };
  { key = "attribute.pattern.primary_0155";              label = "legacy_attribute_155";        arity = 3; tags = ["async"; "core"; "codegen"]; since = "1.5.2"; weight = 891 };
  { key = "recipe.pattern.global_0156";                  label = "primary_team_156";            arity = 6; tags = ["async"; "sync"]; since = "1.5.2"; weight = 2152 };
  { key = "smoker.pattern.derived_0157";                 label = "public_tablist_157";          arity = 3; tags = ["runtime"; "async"]; since = "1.4.0"; weight = 2662 };
  { key = "inventory.pattern.provisional_0158";          label = "stable_bundle_158";           arity = 6; tags = ["untyped"]; since = "1.9.0"; weight = 4 };
  { key = "biome.pattern.derived_0159";                  label = "primary_villager_159";        arity = 0; tags = ["runtime"; "experimental"]; since = "1.7.0"; weight = 313 };
  { key = "barrel.pattern.primary_0160";                 label = "loose_arrow_160";             arity = 4; tags = ["untyped"; "sync"]; since = "1.0.0"; weight = 442 };
  { key = "packet.pattern.eager_0161";                   label = "scoped_biome_161";            arity = 1; tags = ["async"; "check"]; since = "1.8.3"; weight = 2372 };
  { key = "smithing.pattern.provisional_0162";           label = "legacy_dispenser_162";        arity = 7; tags = ["untyped"; "cached"]; since = "1.4.0"; weight = 3168 };
  { key = "compass.pattern.global_0163";                 label = "global_objective_163";        arity = 5; tags = ["typed"; "untyped"; "experimental"]; since = "1.3.1"; weight = 1215 };
  { key = "team.pattern.strict_0164";                    label = "derived_mob_164";             arity = 3; tags = ["check"; "hot"; "sync"]; since = "1.2.0"; weight = 3084 };
  { key = "clock.pattern.legacy_0165";                   label = "local_elytra_165";            arity = 7; tags = ["experimental"; "emit"; "cold"]; since = "1.0.0"; weight = 2994 };
  { key = "beacon.pattern.scoped_0166";                  label = "strict_particle_166";         arity = 4; tags = ["registry"]; since = "1.8.3"; weight = 1760 };
  { key = "compass.pattern.internal_0167";               label = "legacy_beacon_167";           arity = 3; tags = ["cold"]; since = "1.4.0"; weight = 2514 };
  { key = "piston.pattern.strict_0168";                  label = "local_item_168";              arity = 7; tags = ["codegen"]; since = "1.5.2"; weight = 1145 };
  { key = "bundle.pattern.secondary_0169";               label = "internal_item_169";           arity = 7; tags = ["content"]; since = "1.2.0"; weight = 3931 };
  { key = "scoreboard.pattern.secondary_0170";           label = "strict_furnace_170";          arity = 1; tags = ["check"]; since = "1.6.0"; weight = 1405 };
  { key = "structure.pattern.eager_0171";                label = "derived_rail_171";            arity = 2; tags = ["emit"]; since = "1.7.0"; weight = 3961 };
  { key = "arrow.pattern.legacy_0172";                   label = "global_player_172";           arity = 0; tags = ["codegen"]; since = "1.9.0"; weight = 1398 };
  { key = "particle.pattern.eager_0173";                 label = "stable_stonecutter_173";      arity = 4; tags = ["legacy"; "cold"]; since = "1.3.1"; weight = 3047 };
  { key = "hopper.pattern.hidden_0174";                  label = "legacy_mob_174";              arity = 1; tags = ["registry"; "cached"; "content"]; since = "1.7.0"; weight = 1892 };
  { key = "cartography.pattern.local_0175";              label = "modern_gui_175";              arity = 6; tags = ["check"; "packet"; "cold"]; since = "1.9.0"; weight = 2943 };
  { key = "portal.pattern.local_0176";                   label = "strict_particle_176";         arity = 0; tags = ["check"; "legacy"; "hot"]; since = "1.4.0"; weight = 3457 };
  { key = "region.pattern.internal_0177";                label = "provisional_arrow_177";       arity = 7; tags = ["runtime"; "codegen"; "content"]; since = "1.4.0"; weight = 3624 };
  { key = "trident.pattern.stable_0178";                 label = "hidden_sound_178";            arity = 3; tags = ["cached"; "typed"; "runtime"]; since = "1.9.0"; weight = 2576 };
  { key = "boat.pattern.modern_0179";                    label = "public_boat_179";             arity = 4; tags = ["core"; "async"; "untyped"]; since = "1.9.0"; weight = 263 };
  { key = "packet.pattern.fallback_0180";                label = "internal_target_180";         arity = 2; tags = ["runtime"]; since = "1.9.0"; weight = 2407 };
  { key = "scoreboard.pattern.secondary_0181";           label = "secondary_attribute_181";     arity = 5; tags = ["async"]; since = "1.2.0"; weight = 441 };
  { key = "target.pattern.loose_0182";                   label = "secondary_trident_182";       arity = 0; tags = ["registry"]; since = "1.6.0"; weight = 1340 };
  { key = "packet.pattern.scoped_0183";                  label = "public_shulker_183";          arity = 0; tags = ["hot"; "cached"]; since = "1.0.0"; weight = 1678 };
  { key = "entity.pattern.provisional_0184";             label = "local_player_184";            arity = 3; tags = ["runtime"]; since = "1.3.1"; weight = 224 };
  { key = "dropper.pattern.hidden_0185";                 label = "provisional_comparator_185";  arity = 2; tags = ["registry"]; since = "1.9.0"; weight = 2194 };
  { key = "piston.pattern.strict_0186";                  label = "loose_boat_186";              arity = 1; tags = ["sync"]; since = "1.2.0"; weight = 2837 };
  { key = "clock.pattern.eager_0187";                    label = "fallback_advancement_187";    arity = 3; tags = ["emit"; "codegen"; "check"]; since = "1.9.0"; weight = 130 };
  { key = "npc.pattern.canonical_0188";                  label = "canonical_bundle_188";        arity = 2; tags = ["sync"]; since = "1.0.0"; weight = 167 };
  { key = "team.pattern.eager_0189";                     label = "stable_inventory_189";        arity = 4; tags = ["legacy"; "content"]; since = "1.5.2"; weight = 2282 };
  { key = "inventory.pattern.provisional_0190";          label = "primary_block_190";           arity = 1; tags = ["core"; "content"]; since = "1.4.0"; weight = 3229 };
  { key = "chunk.pattern.loose_0191";                    label = "hidden_tablist_191";          arity = 3; tags = ["typed"; "packet"; "content"]; since = "1.9.0"; weight = 111 };
  { key = "barrel.pattern.cached_0192";                  label = "local_trident_192";           arity = 4; tags = ["codegen"]; since = "1.5.2"; weight = 1609 };
  { key = "recipe.pattern.cached_0193";                  label = "primary_inventory_193";       arity = 4; tags = ["codegen"; "sync"; "runtime"]; since = "1.0.0"; weight = 739 };
  { key = "clock.pattern.cached_0194";                   label = "strict_slot_194";             arity = 5; tags = ["async"]; since = "1.0.0"; weight = 2984 };
  { key = "shulker.pattern.secondary_0195";              label = "derived_region_195";          arity = 2; tags = ["content"; "sync"]; since = "1.6.0"; weight = 2704 };
  { key = "dropper.pattern.primary_0196";                label = "strict_target_196";           arity = 2; tags = ["codegen"; "compat"; "parse"]; since = "1.3.1"; weight = 3298 };
  { key = "stonecutter.pattern.stable_0197";             label = "scoped_structure_197";        arity = 5; tags = ["sync"; "async"]; since = "1.5.2"; weight = 1607 };
  { key = "composter.pattern.modern_0198";               label = "provisional_hopper_198";      arity = 2; tags = ["registry"; "content"; "packet"]; since = "1.0.0"; weight = 529 };
  { key = "chunk.pattern.internal_0199";                 label = "eager_particle_199";          arity = 5; tags = ["check"]; since = "1.4.0"; weight = 2016 };
  { key = "slot.pattern.canonical_0200";                 label = "modern_npc_200";              arity = 4; tags = ["core"; "untyped"]; since = "1.4.0"; weight = 193 };
  { key = "enchant.pattern.primary_0201";                label = "local_compass_201";           arity = 0; tags = ["cold"; "async"; "check"]; since = "1.9.0"; weight = 2206 };
  { key = "player.pattern.internal_0202";                label = "global_dropper_202";          arity = 5; tags = ["registry"]; since = "1.2.0"; weight = 3290 };
  { key = "smithing.pattern.derived_0203";               label = "fallback_repeater_203";       arity = 2; tags = ["sync"; "parse"]; since = "1.5.2"; weight = 3420 };
  { key = "spawner.pattern.local_0204";                  label = "hidden_arrow_204";            arity = 7; tags = ["hot"; "legacy"; "untyped"]; since = "1.6.0"; weight = 3191 };
  { key = "particle.pattern.fallback_0205";              label = "loose_dropper_205";           arity = 2; tags = ["codegen"; "runtime"; "legacy"]; since = "1.8.3"; weight = 1583 };
  { key = "gui.pattern.loose_0206";                      label = "stable_campfire_206";         arity = 5; tags = ["untyped"]; since = "1.2.0"; weight = 435 };
  { key = "particle.pattern.stable_0207";                label = "primary_beacon_207";          arity = 1; tags = ["packet"; "cold"; "typed"]; since = "1.3.1"; weight = 302 };
  { key = "team.pattern.scoped_0208";                    label = "hidden_gui_208";              arity = 2; tags = ["lower"]; since = "1.5.2"; weight = 3721 };
  { key = "npc.pattern.canonical_0209";                  label = "primary_arrow_209";           arity = 5; tags = ["sync"]; since = "1.0.0"; weight = 2136 };
  { key = "chunk.pattern.cached_0210";                   label = "fallback_comparator_210";     arity = 6; tags = ["typed"; "lower"; "core"]; since = "1.5.2"; weight = 3493 };
  { key = "slot.pattern.derived_0211";                   label = "public_lectern_211";          arity = 6; tags = ["content"; "check"]; since = "1.8.3"; weight = 3784 };
  { key = "anvil.pattern.derived_0212";                  label = "local_tablist_212";           arity = 4; tags = ["typed"; "untyped"; "parse"]; since = "1.8.3"; weight = 582 };
  { key = "block.pattern.local_0213";                    label = "legacy_trident_213";          arity = 2; tags = ["legacy"]; since = "1.5.2"; weight = 3103 };
  { key = "item.pattern.local_0214";                     label = "legacy_potion_214";           arity = 1; tags = ["packet"; "untyped"; "typed"]; since = "1.5.2"; weight = 951 };
  { key = "rail.pattern.lazy_0215";                      label = "eager_villager_215";          arity = 0; tags = ["check"; "runtime"; "cold"]; since = "1.2.0"; weight = 230 };
  { key = "packet.pattern.loose_0216";                   label = "legacy_piston_216";           arity = 4; tags = ["core"; "lower"]; since = "1.3.1"; weight = 1931 };
  { key = "villager.pattern.secondary_0217";             label = "local_rail_217";              arity = 7; tags = ["runtime"]; since = "1.9.0"; weight = 904 };
  { key = "gui.pattern.internal_0218";                   label = "modern_spawner_218";          arity = 7; tags = ["cached"; "packet"]; since = "1.4.0"; weight = 1156 };
  { key = "block.pattern.internal_0219";                 label = "provisional_anvil_219";       arity = 4; tags = ["experimental"; "parse"; "typed"]; since = "1.2.0"; weight = 913 };
  { key = "mob.pattern.internal_0220";                   label = "modern_hologram_220";         arity = 4; tags = ["async"; "compat"]; since = "1.8.3"; weight = 97 };
  { key = "region.pattern.lazy_0221";                    label = "public_dispenser_221";        arity = 6; tags = ["cached"]; since = "1.8.3"; weight = 2543 };
  { key = "rail.pattern.internal_0222";                  label = "loose_smoker_222";            arity = 7; tags = ["hot"; "cached"]; since = "1.4.0"; weight = 2052 };
  { key = "lectern.pattern.provisional_0223";            label = "modern_item_223";             arity = 6; tags = ["compat"]; since = "1.8.3"; weight = 1922 };
  { key = "furnace.pattern.lazy_0224";                   label = "fallback_cartography_224";    arity = 5; tags = ["cached"]; since = "1.0.0"; weight = 2556 };
  { key = "attribute.pattern.local_0225";                label = "loose_clock_225";             arity = 2; tags = ["legacy"; "codegen"; "experimental"]; since = "1.6.0"; weight = 1898 };
  { key = "trident.pattern.legacy_0226";                 label = "derived_item_226";            arity = 4; tags = ["async"; "core"]; since = "1.2.0"; weight = 3715 };
  { key = "advancement.pattern.derived_0227";            label = "secondary_loom_227";          arity = 3; tags = ["cached"; "content"]; since = "1.2.0"; weight = 2921 };
  { key = "brewing.pattern.modern_0228";                 label = "provisional_smithing_228";    arity = 4; tags = ["content"]; since = "1.2.0"; weight = 56 };
  { key = "objective.pattern.primary_0229";              label = "global_smoker_229";           arity = 7; tags = ["emit"; "content"]; since = "1.3.1"; weight = 3445 };
  { key = "world.pattern.fallback_0230";                 label = "internal_repeater_230";       arity = 0; tags = ["runtime"]; since = "1.2.0"; weight = 2148 };
  { key = "objective.pattern.fallback_0231";             label = "eager_map_231";               arity = 6; tags = ["check"]; since = "1.3.1"; weight = 555 };
  { key = "objective.pattern.local_0232";                label = "cached_compass_232";          arity = 4; tags = ["core"; "parse"; "content"]; since = "1.8.3"; weight = 617 };
  { key = "biome.pattern.derived_0233";                  label = "provisional_grindstone_233";  arity = 3; tags = ["content"]; since = "1.6.0"; weight = 1740 };
  { key = "dispenser.pattern.hidden_0234";               label = "public_particle_234";         arity = 4; tags = ["check"]; since = "1.4.0"; weight = 1537 };
  { key = "smoker.pattern.local_0235";                   label = "provisional_mob_235";         arity = 1; tags = ["typed"; "compat"; "parse"]; since = "1.7.0"; weight = 32 };
  { key = "advancement.pattern.global_0236";             label = "fallback_banner_236";         arity = 5; tags = ["untyped"]; since = "1.7.0"; weight = 2932 };
  { key = "rail.pattern.global_0237";                    label = "loose_hologram_237";          arity = 1; tags = ["experimental"]; since = "1.5.2"; weight = 2505 };
  { key = "crossbow.pattern.lazy_0238";                  label = "stable_slot_238";             arity = 5; tags = ["compat"; "untyped"]; since = "1.0.0"; weight = 1922 };
  { key = "potion.pattern.eager_0239";                   label = "hidden_gui_239";              arity = 4; tags = ["legacy"]; since = "1.9.0"; weight = 3253 };
  { key = "clock.pattern.provisional_0240";              label = "canonical_rail_240";          arity = 4; tags = ["cached"; "experimental"]; since = "1.7.0"; weight = 1719 };
  { key = "compass.pattern.loose_0241";                  label = "cached_rail_241";             arity = 2; tags = ["typed"; "async"]; since = "1.7.0"; weight = 454 };
  { key = "team.pattern.derived_0242";                   label = "modern_mob_242";              arity = 1; tags = ["emit"; "async"; "cold"]; since = "1.6.0"; weight = 1358 };
  { key = "grindstone.pattern.fallback_0243";            label = "loose_pane_243";              arity = 6; tags = ["cold"]; since = "1.4.0"; weight = 48 };
  { key = "piston.pattern.lazy_0244";                    label = "provisional_block_244";       arity = 1; tags = ["untyped"]; since = "1.4.0"; weight = 651 };
  { key = "attribute.pattern.provisional_0245";          label = "canonical_block_245";         arity = 6; tags = ["typed"]; since = "1.7.0"; weight = 3342 };
  { key = "tablist.pattern.public_0246";                 label = "provisional_boat_246";        arity = 0; tags = ["sync"; "emit"]; since = "1.7.0"; weight = 350 };
  { key = "conduit.pattern.scoped_0247";                 label = "strict_world_247";            arity = 4; tags = ["async"]; since = "1.0.0"; weight = 886 };
  { key = "grindstone.pattern.lazy_0248";                label = "modern_structure_248";        arity = 3; tags = ["untyped"]; since = "1.8.3"; weight = 3109 };
  { key = "slot.pattern.cached_0249";                    label = "loose_region_249";            arity = 2; tags = ["sync"; "lower"]; since = "1.3.1"; weight = 2515 };
  { key = "bundle.pattern.primary_0250";                 label = "strict_anvil_250";            arity = 7; tags = ["typed"; "hot"]; since = "1.3.1"; weight = 3326 };
  { key = "scoreboard.pattern.secondary_0251";           label = "modern_smithing_251";         arity = 2; tags = ["check"; "typed"; "codegen"]; since = "1.6.0"; weight = 3136 };
  { key = "chunk.pattern.canonical_0252";                label = "fallback_entity_252";         arity = 3; tags = ["cached"; "parse"]; since = "1.4.0"; weight = 107 };
  { key = "campfire.pattern.loose_0253";                 label = "strict_anvil_253";            arity = 6; tags = ["packet"; "legacy"]; since = "1.6.0"; weight = 2193 };
  { key = "boat.pattern.internal_0254";                  label = "lazy_brewing_254";            arity = 1; tags = ["hot"]; since = "1.3.1"; weight = 341 };
  { key = "banner_pattern.pattern.strict_0255";          label = "provisional_rail_255";        arity = 5; tags = ["check"; "experimental"; "packet"]; since = "1.4.0"; weight = 438 };
  { key = "bell.pattern.primary_0256";                   label = "scoped_shield_256";           arity = 5; tags = ["legacy"]; since = "1.5.2"; weight = 437 };
  { key = "brewing.pattern.strict_0257";                 label = "secondary_sound_257";         arity = 1; tags = ["parse"]; since = "1.5.2"; weight = 2054 };
  { key = "arrow.pattern.strict_0258";                   label = "hidden_item_258";             arity = 6; tags = ["cold"; "core"]; since = "1.9.0"; weight = 3217 };
  { key = "scoreboard.pattern.local_0259";               label = "lazy_bundle_259";             arity = 0; tags = ["hot"; "async"; "parse"]; since = "1.8.3"; weight = 828 };
  { key = "banner_pattern.pattern.hidden_0260";          label = "local_biome_260";             arity = 1; tags = ["untyped"; "hot"; "cached"]; since = "1.4.0"; weight = 3829 };
  { key = "elytra.pattern.primary_0261";                 label = "cached_scoreboard_261";       arity = 3; tags = ["sync"]; since = "1.8.3"; weight = 3323 };
  { key = "campfire.pattern.legacy_0262";                label = "global_cartography_262";      arity = 5; tags = ["emit"]; since = "1.9.0"; weight = 3963 };
  { key = "trade.pattern.stable_0263";                   label = "canonical_lectern_263";       arity = 2; tags = ["codegen"; "content"; "lower"]; since = "1.5.2"; weight = 2561 };
  { key = "enchant.pattern.provisional_0264";            label = "stable_pane_264";             arity = 7; tags = ["legacy"; "core"; "parse"]; since = "1.0.0"; weight = 725 };
  { key = "firework.pattern.provisional_0265";           label = "canonical_dropper_265";       arity = 5; tags = ["cold"]; since = "1.9.0"; weight = 2967 };
  { key = "arrow.pattern.derived_0266";                  label = "lazy_hopper_266";             arity = 2; tags = ["runtime"; "check"; "registry"]; since = "1.9.0"; weight = 2855 };
  { key = "anvil.pattern.local_0267";                    label = "lazy_composter_267";          arity = 3; tags = ["lower"; "content"]; since = "1.2.0"; weight = 3249 };
  { key = "potion.pattern.hidden_0268";                  label = "provisional_smoker_268";      arity = 4; tags = ["untyped"; "packet"; "legacy"]; since = "1.3.1"; weight = 1707 };
  { key = "smoker.pattern.lazy_0269";                    label = "secondary_dropper_269";       arity = 2; tags = ["cached"]; since = "1.9.0"; weight = 483 };
  { key = "conduit.pattern.fallback_0270";               label = "secondary_observer_270";      arity = 2; tags = ["lower"]; since = "1.2.0"; weight = 3340 };
  { key = "scoreboard.pattern.strict_0271";              label = "fallback_repeater_271";       arity = 6; tags = ["registry"]; since = "1.8.3"; weight = 3833 };
  { key = "biome.pattern.provisional_0272";              label = "strict_particle_272";         arity = 6; tags = ["compat"; "emit"]; since = "1.9.0"; weight = 2277 };
  { key = "compass.pattern.legacy_0273";                 label = "stable_smoker_273";           arity = 2; tags = ["registry"; "cold"]; since = "1.3.1"; weight = 3105 };
  { key = "clock.pattern.scoped_0274";                   label = "stable_loom_274";             arity = 3; tags = ["hot"]; since = "1.5.2"; weight = 2995 };
  { key = "pane.pattern.canonical_0275";                 label = "primary_anvil_275";           arity = 5; tags = ["core"; "legacy"]; since = "1.4.0"; weight = 2410 };
  { key = "gui.pattern.internal_0276";                   label = "strict_particle_276";         arity = 1; tags = ["runtime"; "content"]; since = "1.0.0"; weight = 2115 };
  { key = "minecart.pattern.loose_0277";                 label = "legacy_smithing_277";         arity = 3; tags = ["hot"; "packet"]; since = "1.9.0"; weight = 1236 };
  { key = "bossbar.pattern.modern_0278";                 label = "lazy_conduit_278";            arity = 0; tags = ["cold"; "check"]; since = "1.7.0"; weight = 2516 };
  { key = "shulker.pattern.loose_0279";                  label = "secondary_shield_279";        arity = 3; tags = ["codegen"]; since = "1.4.0"; weight = 782 };
  { key = "scoreboard.pattern.lazy_0280";                label = "scoped_smithing_280";         arity = 6; tags = ["untyped"]; since = "1.6.0"; weight = 1429 };
  { key = "stonecutter.pattern.fallback_0281";           label = "provisional_smithing_281";    arity = 1; tags = ["parse"; "core"]; since = "1.5.2"; weight = 2686 };
  { key = "slot.pattern.canonical_0282";                 label = "hidden_hologram_282";         arity = 5; tags = ["core"; "typed"]; since = "1.5.2"; weight = 602 };
  { key = "comparator.pattern.strict_0283";              label = "fallback_smithing_283";       arity = 6; tags = ["lower"; "codegen"; "cold"]; since = "1.6.0"; weight = 1666 };
  { key = "potion.pattern.strict_0284";                  label = "local_potion_284";            arity = 5; tags = ["core"; "runtime"]; since = "1.7.0"; weight = 952 };
  { key = "brewing.pattern.secondary_0285";              label = "modern_brewing_285";          arity = 1; tags = ["cold"; "sync"]; since = "1.6.0"; weight = 755 };
  { key = "packet.pattern.legacy_0286";                  label = "strict_anvil_286";            arity = 4; tags = ["content"; "legacy"]; since = "1.9.0"; weight = 1210 };
  { key = "region.pattern.internal_0287";                label = "provisional_bell_287";        arity = 0; tags = ["core"; "lower"; "experimental"]; since = "1.4.0"; weight = 1312 };
  { key = "enchant.pattern.loose_0288";                  label = "global_effect_288";           arity = 4; tags = ["compat"]; since = "1.9.0"; weight = 3842 };
  { key = "grindstone.pattern.cached_0289";              label = "global_tablist_289";          arity = 0; tags = ["parse"; "untyped"]; since = "1.6.0"; weight = 647 };
  { key = "trident.pattern.global_0290";                 label = "hidden_gui_290";              arity = 6; tags = ["emit"]; since = "1.6.0"; weight = 1303 };
  { key = "sound.pattern.strict_0291";                   label = "secondary_hologram_291";      arity = 6; tags = ["async"]; since = "1.9.0"; weight = 2836 };
  { key = "mob.pattern.modern_0292";                     label = "primary_npc_292";             arity = 5; tags = ["cold"]; since = "1.9.0"; weight = 1765 };
  { key = "world.pattern.legacy_0293";                   label = "stable_item_293";             arity = 1; tags = ["async"; "compat"]; since = "1.8.3"; weight = 181 };
  { key = "chunk.pattern.lazy_0294";                     label = "derived_slot_294";            arity = 0; tags = ["registry"; "untyped"]; since = "1.4.0"; weight = 2063 };
  { key = "bundle.pattern.eager_0295";                   label = "modern_objective_295";        arity = 3; tags = ["hot"]; since = "1.7.0"; weight = 3821 };
  { key = "target.pattern.legacy_0296";                  label = "strict_firework_296";         arity = 6; tags = ["parse"; "cached"]; since = "1.9.0"; weight = 865 };
  { key = "tablist.pattern.primary_0297";                label = "global_objective_297";        arity = 0; tags = ["content"; "typed"; "runtime"]; since = "1.9.0"; weight = 479 };
  { key = "minecart.pattern.hidden_0298";                label = "loose_elytra_298";            arity = 2; tags = ["async"; "content"; "cold"]; since = "1.8.3"; weight = 3960 };
  { key = "structure.pattern.internal_0299";             label = "secondary_packet_299";        arity = 6; tags = ["legacy"; "packet"]; since = "1.4.0"; weight = 3685 };
  { key = "banner_pattern.pattern.scoped_0300";          label = "internal_anvil_300";          arity = 7; tags = ["typed"; "untyped"]; since = "1.2.0"; weight = 766 };
  { key = "effect.pattern.public_0301";                  label = "derived_player_301";          arity = 3; tags = ["parse"; "typed"]; since = "1.7.0"; weight = 1092 };
  { key = "beacon.pattern.lazy_0302";                    label = "legacy_barrel_302";           arity = 7; tags = ["legacy"; "async"]; since = "1.2.0"; weight = 1605 };
  { key = "target.pattern.derived_0303";                 label = "modern_rail_303";             arity = 0; tags = ["cached"; "hot"; "compat"]; since = "1.9.0"; weight = 1740 };
  { key = "firework.pattern.eager_0304";                 label = "hidden_block_304";            arity = 5; tags = ["experimental"]; since = "1.7.0"; weight = 3872 };
  { key = "cartography.pattern.derived_0305";            label = "primary_piston_305";          arity = 3; tags = ["legacy"]; since = "1.0.0"; weight = 1494 };
  { key = "comparator.pattern.eager_0306";               label = "local_banner_pattern_306";    arity = 4; tags = ["core"; "sync"]; since = "1.0.0"; weight = 1432 };
  { key = "item.pattern.scoped_0307";                    label = "provisional_repeater_307";    arity = 7; tags = ["hot"; "codegen"]; since = "1.3.1"; weight = 1783 };
  { key = "conduit.pattern.stable_0308";                 label = "secondary_world_308";         arity = 3; tags = ["compat"; "check"; "sync"]; since = "1.4.0"; weight = 3883 };
  { key = "enchant.pattern.public_0309";                 label = "loose_dispenser_309";         arity = 6; tags = ["emit"; "check"]; since = "1.0.0"; weight = 958 };
  { key = "attribute.pattern.eager_0310";                label = "secondary_sound_310";         arity = 7; tags = ["lower"; "runtime"]; since = "1.4.0"; weight = 242 };
  { key = "compass.pattern.provisional_0311";            label = "global_banner_311";           arity = 5; tags = ["sync"]; since = "1.9.0"; weight = 3356 };
  { key = "repeater.pattern.modern_0312";                label = "local_firework_312";          arity = 2; tags = ["parse"; "compat"]; since = "1.6.0"; weight = 332 };
  { key = "player.pattern.global_0313";                  label = "local_objective_313";         arity = 6; tags = ["core"; "legacy"]; since = "1.4.0"; weight = 1953 };
  { key = "conduit.pattern.scoped_0314";                 label = "provisional_hopper_314";      arity = 3; tags = ["content"]; since = "1.2.0"; weight = 919 };
  { key = "anvil.pattern.eager_0315";                    label = "public_banner_315";           arity = 0; tags = ["cold"; "untyped"; "async"]; since = "1.5.2"; weight = 4027 };
  { key = "shield.pattern.derived_0316";                 label = "secondary_clock_316";         arity = 4; tags = ["parse"; "content"]; since = "1.8.3"; weight = 1988 };
  { key = "firework.pattern.loose_0317";                 label = "scoped_tablist_317";          arity = 1; tags = ["codegen"; "untyped"; "emit"]; since = "1.3.1"; weight = 2809 };
  { key = "comparator.pattern.hidden_0318";              label = "loose_entity_318";            arity = 5; tags = ["packet"]; since = "1.7.0"; weight = 2498 };
  { key = "crossbow.pattern.modern_0319";                label = "canonical_arrow_319";         arity = 2; tags = ["parse"; "core"; "check"]; since = "1.3.1"; weight = 3346 };
  { key = "mob.pattern.public_0320";                     label = "stable_bossbar_320";          arity = 2; tags = ["compat"; "untyped"]; since = "1.4.0"; weight = 3007 };
  { key = "clock.pattern.strict_0321";                   label = "derived_composter_321";       arity = 2; tags = ["packet"]; since = "1.9.0"; weight = 2736 };
  { key = "banner.pattern.stable_0322";                  label = "fallback_furnace_322";        arity = 1; tags = ["sync"; "async"]; since = "1.5.2"; weight = 2844 };
  { key = "lectern.pattern.secondary_0323";              label = "modern_conduit_323";          arity = 6; tags = ["sync"]; since = "1.7.0"; weight = 1524 };
  { key = "barrel.pattern.eager_0324";                   label = "internal_gui_324";            arity = 5; tags = ["cached"; "experimental"]; since = "1.8.3"; weight = 2755 };
  { key = "region.pattern.public_0325";                  label = "cached_bundle_325";           arity = 1; tags = ["registry"; "emit"]; since = "1.8.3"; weight = 2695 };
  { key = "repeater.pattern.primary_0326";               label = "fallback_structure_326";      arity = 7; tags = ["typed"; "sync"]; since = "1.8.3"; weight = 3250 };
  { key = "enchant.pattern.provisional_0327";            label = "eager_structure_327";         arity = 6; tags = ["hot"; "content"; "lower"]; since = "1.9.0"; weight = 2622 };
  { key = "scoreboard.pattern.loose_0328";               label = "secondary_inventory_328";     arity = 0; tags = ["registry"; "cached"]; since = "1.0.0"; weight = 921 };
  { key = "enchant.pattern.internal_0329";               label = "internal_furnace_329";        arity = 5; tags = ["content"; "typed"; "untyped"]; since = "1.2.0"; weight = 2098 };
  { key = "furnace.pattern.global_0330";                 label = "stable_repeater_330";         arity = 1; tags = ["codegen"]; since = "1.3.1"; weight = 1151 };
  { key = "dropper.pattern.strict_0331";                 label = "scoped_campfire_331";         arity = 6; tags = ["cached"]; since = "1.0.0"; weight = 217 };
  { key = "elytra.pattern.fallback_0332";                label = "derived_item_332";            arity = 6; tags = ["async"]; since = "1.3.1"; weight = 2416 };
  { key = "sound.pattern.primary_0333";                  label = "derived_attribute_333";       arity = 3; tags = ["hot"]; since = "1.2.0"; weight = 1849 };
  { key = "furnace.pattern.local_0334";                  label = "global_conduit_334";          arity = 1; tags = ["typed"; "cold"]; since = "1.3.1"; weight = 2475 };
  { key = "enchant.pattern.modern_0335";                 label = "lazy_team_335";               arity = 6; tags = ["async"; "check"]; since = "1.0.0"; weight = 863 };
  { key = "anvil.pattern.global_0336";                   label = "legacy_campfire_336";         arity = 6; tags = ["parse"; "compat"]; since = "1.8.3"; weight = 168 };
  { key = "smoker.pattern.derived_0337";                 label = "fallback_anvil_337";          arity = 5; tags = ["codegen"]; since = "1.8.3"; weight = 1717 };
  { key = "shulker.pattern.stable_0338";                 label = "strict_banner_338";           arity = 7; tags = ["cached"; "legacy"]; since = "1.9.0"; weight = 4073 };
  { key = "beacon.pattern.secondary_0339";               label = "loose_gui_339";               arity = 5; tags = ["emit"]; since = "1.3.1"; weight = 3816 };
  { key = "enchant.pattern.secondary_0340";              label = "legacy_trade_340";            arity = 0; tags = ["registry"]; since = "1.0.0"; weight = 3024 };
  { key = "shield.pattern.secondary_0341";               label = "derived_region_341";          arity = 2; tags = ["packet"; "async"]; since = "1.7.0"; weight = 2166 };
  { key = "dropper.pattern.cached_0342";                 label = "scoped_packet_342";           arity = 4; tags = ["lower"]; since = "1.5.2"; weight = 565 };
  { key = "effect.pattern.lazy_0343";                    label = "derived_team_343";            arity = 0; tags = ["cold"]; since = "1.5.2"; weight = 2656 };
  { key = "chunk.pattern.internal_0344";                 label = "provisional_composter_344";   arity = 4; tags = ["typed"; "sync"; "runtime"]; since = "1.8.3"; weight = 2523 };
  { key = "gui.pattern.lazy_0345";                       label = "local_shield_345";            arity = 0; tags = ["codegen"; "core"; "cached"]; since = "1.8.3"; weight = 963 };
  { key = "player.pattern.loose_0346";                   label = "primary_particle_346";        arity = 1; tags = ["emit"; "lower"; "cached"]; since = "1.9.0"; weight = 3479 };
  { key = "world.pattern.local_0347";                    label = "eager_chunk_347";             arity = 3; tags = ["cold"; "hot"; "typed"]; since = "1.2.0"; weight = 515 };
  { key = "effect.pattern.secondary_0348";               label = "hidden_bossbar_348";          arity = 2; tags = ["registry"; "emit"]; since = "1.3.1"; weight = 240 };
  { key = "anvil.pattern.legacy_0349";                   label = "derived_hopper_349";          arity = 4; tags = ["lower"; "sync"]; since = "1.5.2"; weight = 1687 };
  { key = "dropper.pattern.cached_0350";                 label = "loose_dropper_350";           arity = 3; tags = ["lower"; "codegen"]; since = "1.3.1"; weight = 1314 };
  { key = "biome.pattern.strict_0351";                   label = "modern_recipe_351";           arity = 2; tags = ["async"]; since = "1.2.0"; weight = 1824 };
  { key = "compass.pattern.legacy_0352";                 label = "scoped_scoreboard_352";       arity = 4; tags = ["parse"; "codegen"]; since = "1.4.0"; weight = 1850 };
  { key = "cartography.pattern.internal_0353";           label = "cached_item_353";             arity = 1; tags = ["experimental"; "untyped"]; since = "1.9.0"; weight = 2665 };
  { key = "grindstone.pattern.fallback_0354";            label = "derived_portal_354";          arity = 7; tags = ["lower"; "runtime"]; since = "1.2.0"; weight = 2423 };
  { key = "banner_pattern.pattern.loose_0355";           label = "cached_world_355";            arity = 3; tags = ["experimental"]; since = "1.4.0"; weight = 1287 };
  { key = "cartography.pattern.hidden_0356";             label = "legacy_repeater_356";         arity = 4; tags = ["legacy"; "registry"; "sync"]; since = "1.9.0"; weight = 2076 };
  { key = "pane.pattern.derived_0357";                   label = "provisional_campfire_357";    arity = 0; tags = ["runtime"; "sync"]; since = "1.2.0"; weight = 2172 };
  { key = "hologram.pattern.stable_0358";                label = "primary_scoreboard_358";      arity = 5; tags = ["registry"; "check"]; since = "1.6.0"; weight = 893 };
  { key = "loom.pattern.local_0359";                     label = "scoped_inventory_359";        arity = 1; tags = ["content"; "compat"; "typed"]; since = "1.5.2"; weight = 1004 };
  { key = "map.pattern.hidden_0360";                     label = "lazy_npc_360";                arity = 1; tags = ["compat"; "cached"]; since = "1.4.0"; weight = 4015 };
  { key = "dropper.pattern.strict_0361";                 label = "global_target_361";           arity = 1; tags = ["cached"; "sync"; "legacy"]; since = "1.4.0"; weight = 2482 };
  { key = "crossbow.pattern.hidden_0362";                label = "strict_villager_362";         arity = 6; tags = ["runtime"]; since = "1.9.0"; weight = 4092 };
  { key = "npc.pattern.modern_0363";                     label = "primary_attribute_363";       arity = 4; tags = ["core"]; since = "1.2.0"; weight = 2984 };
  { key = "barrel.pattern.internal_0364";                label = "local_comparator_364";        arity = 7; tags = ["runtime"]; since = "1.6.0"; weight = 2498 };
  { key = "structure.pattern.strict_0365";               label = "local_npc_365";               arity = 0; tags = ["registry"]; since = "1.4.0"; weight = 3485 };
  { key = "particle.pattern.provisional_0366";           label = "loose_crossbow_366";          arity = 0; tags = ["parse"; "untyped"; "registry"]; since = "1.3.1"; weight = 3061 };
  { key = "grindstone.pattern.provisional_0367";         label = "lazy_hologram_367";           arity = 6; tags = ["untyped"; "hot"; "runtime"]; since = "1.7.0"; weight = 2724 };
  { key = "pane.pattern.secondary_0368";                 label = "local_rail_368";              arity = 4; tags = ["hot"; "check"; "emit"]; since = "1.8.3"; weight = 1068 };
  { key = "hologram.pattern.legacy_0369";                label = "lazy_banner_369";             arity = 4; tags = ["emit"]; since = "1.5.2"; weight = 2994 };
  { key = "piston.pattern.canonical_0370";               label = "fallback_attribute_370";      arity = 4; tags = ["cold"]; since = "1.0.0"; weight = 802 };
  { key = "potion.pattern.eager_0371";                   label = "cached_team_371";             arity = 4; tags = ["experimental"; "cached"; "typed"]; since = "1.8.3"; weight = 1012 };
  { key = "firework.pattern.scoped_0372";                label = "provisional_inventory_372";   arity = 2; tags = ["parse"; "emit"; "cached"]; since = "1.0.0"; weight = 2400 };
  { key = "clock.pattern.cached_0373";                   label = "hidden_target_373";           arity = 0; tags = ["packet"; "registry"]; since = "1.3.1"; weight = 1203 };
  { key = "banner_pattern.pattern.local_0374";           label = "primary_enchant_374";         arity = 0; tags = ["codegen"]; since = "1.4.0"; weight = 3715 };
  { key = "item.pattern.canonical_0375";                 label = "secondary_attribute_375";     arity = 2; tags = ["sync"]; since = "1.3.1"; weight = 3633 };
  { key = "spawner.pattern.legacy_0376";                 label = "secondary_enchant_376";       arity = 2; tags = ["typed"; "experimental"]; since = "1.9.0"; weight = 3616 };
  { key = "campfire.pattern.cached_0377";                label = "secondary_scoreboard_377";    arity = 2; tags = ["registry"]; since = "1.8.3"; weight = 1773 };
  { key = "observer.pattern.modern_0378";                label = "loose_stonecutter_378";       arity = 0; tags = ["packet"; "core"; "compat"]; since = "1.6.0"; weight = 490 };
  { key = "portal.pattern.public_0379";                  label = "stable_banner_379";           arity = 6; tags = ["hot"; "untyped"]; since = "1.0.0"; weight = 1232 };
  { key = "banner_pattern.pattern.canonical_0380";       label = "strict_slot_380";             arity = 1; tags = ["hot"; "runtime"]; since = "1.0.0"; weight = 1151 };
  { key = "loom.pattern.stable_0381";                    label = "internal_clock_381";          arity = 5; tags = ["cached"; "experimental"; "codegen"]; since = "1.5.2"; weight = 837 };
  { key = "smithing.pattern.canonical_0382";             label = "modern_crossbow_382";         arity = 7; tags = ["emit"; "untyped"]; since = "1.5.2"; weight = 502 };
  { key = "world.pattern.fallback_0383";                 label = "derived_conduit_383";         arity = 4; tags = ["experimental"]; since = "1.0.0"; weight = 3057 };
  { key = "block.pattern.derived_0384";                  label = "fallback_minecart_384";       arity = 5; tags = ["typed"]; since = "1.4.0"; weight = 3607 };
  { key = "observer.pattern.cached_0385";                label = "provisional_structure_385";   arity = 2; tags = ["content"; "typed"; "compat"]; since = "1.0.0"; weight = 478 };
  { key = "minecart.pattern.local_0386";                 label = "loose_minecart_386";          arity = 3; tags = ["cold"]; since = "1.4.0"; weight = 2637 };
  { key = "anvil.pattern.fallback_0387";                 label = "modern_stonecutter_387";      arity = 3; tags = ["packet"]; since = "1.2.0"; weight = 3143 };
  { key = "trident.pattern.strict_0388";                 label = "global_chunk_388";            arity = 3; tags = ["cold"]; since = "1.2.0"; weight = 3926 };
  { key = "banner.pattern.public_0389";                  label = "secondary_particle_389";      arity = 6; tags = ["experimental"]; since = "1.3.1"; weight = 2360 };
]

let count = List.length entries

let table : (string, pattern_entry) Hashtbl.t =
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
