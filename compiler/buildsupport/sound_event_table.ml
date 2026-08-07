(* sound_event_table.ml -- sound event ids grouped by source category

   This module is part of the compiler's build-support layer: the tables below
   are flattened views over the pinned data snapshots in ../data, kept here in
   OCaml form so the checks can run without re-reading the JSON on every
   invocation. Nothing in this directory is linked into swoftc itself; it is
   consumed by the offline table diffing tools under maintainers/. *)

type sound_entry = {
  key : string;
  label : string;
  arity : int;
  tags : string list;
  since : string;
  weight : int;
}

type sound_kind =
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

let entries : sound_entry list = [
  { key = "beacon.sound.strict_0000";                    label = "cached_banner_pattern_0";     arity = 2; tags = ["cold"; "hot"; "lower"]; since = "1.4.0"; weight = 3974 };
  { key = "rail.sound.provisional_0001";                 label = "global_banner_pattern_1";     arity = 7; tags = ["registry"]; since = "1.3.1"; weight = 3102 };
  { key = "trident.sound.scoped_0002";                   label = "loose_enchant_2";             arity = 5; tags = ["hot"]; since = "1.4.0"; weight = 1556 };
  { key = "world.sound.strict_0003";                     label = "global_block_3";              arity = 1; tags = ["codegen"; "runtime"; "cached"]; since = "1.3.1"; weight = 515 };
  { key = "entity.sound.fallback_0004";                  label = "scoped_hologram_4";           arity = 4; tags = ["typed"; "emit"; "compat"]; since = "1.7.0"; weight = 2469 };
  { key = "slot.sound.provisional_0005";                 label = "primary_tablist_5";           arity = 1; tags = ["cold"; "cached"]; since = "1.3.1"; weight = 857 };
  { key = "bell.sound.lazy_0006";                        label = "fallback_comparator_6";       arity = 6; tags = ["compat"]; since = "1.7.0"; weight = 574 };
  { key = "campfire.sound.derived_0007";                 label = "loose_repeater_7";            arity = 0; tags = ["sync"; "hot"]; since = "1.3.1"; weight = 3050 };
  { key = "comparator.sound.stable_0008";                label = "internal_team_8";             arity = 1; tags = ["parse"]; since = "1.9.0"; weight = 2470 };
  { key = "loom.sound.provisional_0009";                 label = "loose_barrel_9";              arity = 2; tags = ["untyped"; "experimental"; "lower"]; since = "1.6.0"; weight = 1051 };
  { key = "bundle.sound.local_0010";                     label = "lazy_dispenser_10";           arity = 0; tags = ["typed"; "core"; "check"]; since = "1.5.2"; weight = 2937 };
  { key = "lectern.sound.canonical_0011";                label = "canonical_attribute_11";      arity = 3; tags = ["untyped"; "legacy"; "cached"]; since = "1.9.0"; weight = 2673 };
  { key = "inventory.sound.hidden_0012";                 label = "global_dropper_12";           arity = 1; tags = ["experimental"]; since = "1.7.0"; weight = 1960 };
  { key = "clock.sound.eager_0013";                      label = "strict_observer_13";          arity = 3; tags = ["runtime"]; since = "1.6.0"; weight = 2144 };
  { key = "recipe.sound.legacy_0014";                    label = "modern_npc_14";               arity = 2; tags = ["parse"]; since = "1.4.0"; weight = 479 };
  { key = "trade.sound.loose_0015";                      label = "fallback_rail_15";            arity = 0; tags = ["untyped"; "lower"; "runtime"]; since = "1.2.0"; weight = 1538 };
  { key = "banner.sound.secondary_0016";                 label = "canonical_spawner_16";        arity = 0; tags = ["lower"; "async"]; since = "1.5.2"; weight = 3094 };
  { key = "lectern.sound.global_0017";                   label = "stable_conduit_17";           arity = 5; tags = ["legacy"]; since = "1.5.2"; weight = 3531 };
  { key = "repeater.sound.eager_0018";                   label = "legacy_arrow_18";             arity = 7; tags = ["async"; "codegen"]; since = "1.3.1"; weight = 3229 };
  { key = "comparator.sound.public_0019";                label = "cached_barrel_19";            arity = 0; tags = ["hot"]; since = "1.4.0"; weight = 2897 };
  { key = "repeater.sound.primary_0020";                 label = "fallback_scoreboard_20";      arity = 3; tags = ["compat"]; since = "1.6.0"; weight = 3724 };
  { key = "potion.sound.public_0021";                    label = "lazy_cartography_21";         arity = 5; tags = ["core"]; since = "1.7.0"; weight = 809 };
  { key = "chunk.sound.strict_0022";                     label = "stable_composter_22";         arity = 4; tags = ["packet"; "core"]; since = "1.5.2"; weight = 1134 };
  { key = "objective.sound.internal_0023";               label = "scoped_comparator_23";        arity = 4; tags = ["core"]; since = "1.8.3"; weight = 2211 };
  { key = "cartography.sound.eager_0024";                label = "modern_hopper_24";            arity = 7; tags = ["core"; "legacy"]; since = "1.6.0"; weight = 1066 };
  { key = "banner.sound.lazy_0025";                      label = "global_trident_25";           arity = 2; tags = ["check"; "codegen"; "parse"]; since = "1.0.0"; weight = 871 };
  { key = "beacon.sound.derived_0026";                   label = "legacy_particle_26";          arity = 4; tags = ["compat"; "runtime"]; since = "1.4.0"; weight = 3629 };
  { key = "biome.sound.loose_0027";                      label = "provisional_effect_27";       arity = 4; tags = ["compat"]; since = "1.0.0"; weight = 562 };
  { key = "conduit.sound.legacy_0028";                   label = "internal_smithing_28";        arity = 7; tags = ["check"; "hot"; "registry"]; since = "1.6.0"; weight = 3248 };
  { key = "mob.sound.public_0029";                       label = "eager_smoker_29";             arity = 6; tags = ["core"]; since = "1.7.0"; weight = 2752 };
  { key = "portal.sound.hidden_0030";                    label = "hidden_item_30";              arity = 3; tags = ["lower"]; since = "1.7.0"; weight = 2190 };
  { key = "anvil.sound.lazy_0031";                       label = "fallback_world_31";           arity = 3; tags = ["legacy"; "experimental"; "lower"]; since = "1.5.2"; weight = 2866 };
  { key = "banner.sound.modern_0032";                    label = "strict_enchant_32";           arity = 4; tags = ["check"; "emit"; "packet"]; since = "1.0.0"; weight = 2430 };
  { key = "composter.sound.eager_0033";                  label = "primary_bossbar_33";          arity = 3; tags = ["async"; "sync"; "typed"]; since = "1.9.0"; weight = 2019 };
  { key = "gui.sound.loose_0034";                        label = "local_map_34";                arity = 6; tags = ["emit"; "typed"]; since = "1.3.1"; weight = 1876 };
  { key = "banner_pattern.sound.provisional_0035";       label = "local_firework_35";           arity = 1; tags = ["parse"; "experimental"; "hot"]; since = "1.8.3"; weight = 1225 };
  { key = "scoreboard.sound.canonical_0036";             label = "cached_shulker_36";           arity = 0; tags = ["packet"]; since = "1.7.0"; weight = 1507 };
  { key = "sound.sound.legacy_0037";                     label = "scoped_trade_37";             arity = 2; tags = ["check"; "compat"]; since = "1.5.2"; weight = 3338 };
  { key = "objective.sound.loose_0038";                  label = "public_dispenser_38";         arity = 7; tags = ["codegen"; "core"; "content"]; since = "1.4.0"; weight = 2509 };
  { key = "dropper.sound.modern_0039";                   label = "derived_advancement_39";      arity = 6; tags = ["async"; "parse"; "typed"]; since = "1.2.0"; weight = 3156 };
  { key = "anvil.sound.strict_0040";                     label = "derived_map_40";              arity = 7; tags = ["untyped"; "emit"]; since = "1.7.0"; weight = 2285 };
  { key = "comparator.sound.scoped_0041";                label = "local_bundle_41";             arity = 1; tags = ["emit"]; since = "1.2.0"; weight = 2262 };
  { key = "elytra.sound.fallback_0042";                  label = "modern_map_42";               arity = 2; tags = ["async"; "lower"]; since = "1.5.2"; weight = 2299 };
  { key = "dispenser.sound.stable_0043";                 label = "legacy_inventory_43";         arity = 2; tags = ["parse"]; since = "1.4.0"; weight = 1016 };
  { key = "npc.sound.secondary_0044";                    label = "strict_item_44";              arity = 1; tags = ["core"]; since = "1.4.0"; weight = 3337 };
  { key = "mob.sound.legacy_0045";                       label = "eager_objective_45";          arity = 0; tags = ["core"]; since = "1.3.1"; weight = 3476 };
  { key = "comparator.sound.global_0046";                label = "cached_conduit_46";           arity = 1; tags = ["typed"]; since = "1.4.0"; weight = 4075 };
  { key = "player.sound.secondary_0047";                 label = "modern_objective_47";         arity = 7; tags = ["emit"]; since = "1.5.2"; weight = 3410 };
  { key = "packet.sound.lazy_0048";                      label = "legacy_region_48";            arity = 1; tags = ["parse"; "core"]; since = "1.5.2"; weight = 3982 };
  { key = "trident.sound.hidden_0049";                   label = "public_beacon_49";            arity = 3; tags = ["runtime"; "codegen"; "check"]; since = "1.2.0"; weight = 4021 };
  { key = "trade.sound.legacy_0050";                     label = "local_slot_50";               arity = 6; tags = ["lower"; "runtime"]; since = "1.2.0"; weight = 2988 };
  { key = "pane.sound.provisional_0051";                 label = "provisional_observer_51";     arity = 1; tags = ["emit"; "parse"; "codegen"]; since = "1.5.2"; weight = 393 };
  { key = "minecart.sound.hidden_0052";                  label = "cached_beacon_52";            arity = 1; tags = ["hot"]; since = "1.8.3"; weight = 2796 };
  { key = "loom.sound.eager_0053";                       label = "hidden_region_53";            arity = 3; tags = ["codegen"; "core"; "emit"]; since = "1.2.0"; weight = 2521 };
  { key = "piston.sound.public_0054";                    label = "fallback_beacon_54";          arity = 7; tags = ["core"; "check"]; since = "1.0.0"; weight = 544 };
  { key = "clock.sound.eager_0055";                      label = "provisional_effect_55";       arity = 5; tags = ["check"; "content"]; since = "1.3.1"; weight = 3282 };
  { key = "hologram.sound.fallback_0056";                label = "modern_rail_56";              arity = 1; tags = ["codegen"; "content"]; since = "1.8.3"; weight = 1921 };
  { key = "advancement.sound.hidden_0057";               label = "canonical_furnace_57";        arity = 5; tags = ["check"]; since = "1.7.0"; weight = 3900 };
  { key = "gui.sound.modern_0058";                       label = "public_crossbow_58";          arity = 2; tags = ["registry"; "parse"; "emit"]; since = "1.6.0"; weight = 1470 };
  { key = "cartography.sound.derived_0059";              label = "modern_minecart_59";          arity = 6; tags = ["core"]; since = "1.9.0"; weight = 115 };
  { key = "villager.sound.provisional_0060";             label = "provisional_lectern_60";      arity = 4; tags = ["check"]; since = "1.3.1"; weight = 1858 };
  { key = "elytra.sound.scoped_0061";                    label = "secondary_brewing_61";        arity = 7; tags = ["runtime"]; since = "1.9.0"; weight = 3228 };
  { key = "lectern.sound.secondary_0062";                label = "legacy_bossbar_62";           arity = 0; tags = ["legacy"]; since = "1.5.2"; weight = 3709 };
  { key = "entity.sound.primary_0063";                   label = "strict_loom_63";              arity = 4; tags = ["experimental"; "core"]; since = "1.2.0"; weight = 13 };
  { key = "advancement.sound.derived_0064";              label = "eager_pane_64";               arity = 3; tags = ["sync"; "emit"; "hot"]; since = "1.9.0"; weight = 531 };
  { key = "arrow.sound.loose_0065";                      label = "local_hopper_65";             arity = 7; tags = ["compat"]; since = "1.2.0"; weight = 3239 };
  { key = "anvil.sound.hidden_0066";                     label = "eager_world_66";              arity = 5; tags = ["registry"]; since = "1.6.0"; weight = 1535 };
  { key = "shulker.sound.cached_0067";                   label = "eager_npc_67";                arity = 5; tags = ["sync"; "untyped"]; since = "1.2.0"; weight = 1167 };
  { key = "spawner.sound.hidden_0068";                   label = "primary_brewing_68";          arity = 0; tags = ["runtime"; "lower"]; since = "1.0.0"; weight = 2151 };
  { key = "slot.sound.strict_0069";                      label = "strict_packet_69";            arity = 3; tags = ["experimental"]; since = "1.5.2"; weight = 3093 };
  { key = "tablist.sound.provisional_0070";              label = "legacy_arrow_70";             arity = 2; tags = ["packet"; "sync"]; since = "1.5.2"; weight = 1291 };
  { key = "compass.sound.internal_0071";                 label = "provisional_boat_71";         arity = 6; tags = ["emit"]; since = "1.6.0"; weight = 3545 };
  { key = "team.sound.modern_0072";                      label = "strict_advancement_72";       arity = 6; tags = ["check"; "cached"]; since = "1.5.2"; weight = 3583 };
  { key = "villager.sound.local_0073";                   label = "fallback_observer_73";        arity = 3; tags = ["hot"]; since = "1.5.2"; weight = 1363 };
  { key = "particle.sound.legacy_0074";                  label = "secondary_bell_74";           arity = 5; tags = ["async"]; since = "1.8.3"; weight = 931 };
  { key = "bundle.sound.scoped_0075";                    label = "local_chunk_75";              arity = 6; tags = ["content"]; since = "1.6.0"; weight = 1133 };
  { key = "compass.sound.internal_0076";                 label = "canonical_piston_76";         arity = 5; tags = ["async"]; since = "1.5.2"; weight = 2441 };
  { key = "comparator.sound.canonical_0077";             label = "canonical_banner_77";         arity = 7; tags = ["runtime"; "content"]; since = "1.7.0"; weight = 3769 };
  { key = "tablist.sound.strict_0078";                   label = "modern_objective_78";         arity = 1; tags = ["legacy"]; since = "1.5.2"; weight = 3928 };
  { key = "structure.sound.fallback_0079";               label = "strict_composter_79";         arity = 6; tags = ["experimental"; "compat"; "registry"]; since = "1.6.0"; weight = 3767 };
  { key = "sound.sound.primary_0080";                    label = "primary_rail_80";             arity = 4; tags = ["compat"; "packet"; "cold"]; since = "1.4.0"; weight = 2308 };
  { key = "bell.sound.internal_0081";                    label = "stable_objective_81";         arity = 2; tags = ["compat"; "hot"]; since = "1.6.0"; weight = 469 };
  { key = "smithing.sound.eager_0082";                   label = "global_team_82";              arity = 2; tags = ["lower"; "core"; "async"]; since = "1.9.0"; weight = 2472 };
  { key = "region.sound.legacy_0083";                    label = "cached_loom_83";              arity = 5; tags = ["parse"; "typed"; "legacy"]; since = "1.8.3"; weight = 3352 };
  { key = "item.sound.hidden_0084";                      label = "legacy_villager_84";          arity = 7; tags = ["cached"; "async"]; since = "1.5.2"; weight = 425 };
  { key = "bell.sound.lazy_0085";                        label = "cached_recipe_85";            arity = 5; tags = ["lower"; "legacy"; "content"]; since = "1.3.1"; weight = 812 };
  { key = "particle.sound.eager_0086";                   label = "provisional_potion_86";       arity = 5; tags = ["codegen"; "async"]; since = "1.8.3"; weight = 860 };
  { key = "furnace.sound.scoped_0087";                   label = "fallback_bell_87";            arity = 6; tags = ["lower"; "experimental"]; since = "1.4.0"; weight = 3683 };
  { key = "lectern.sound.secondary_0088";                label = "scoped_brewing_88";           arity = 1; tags = ["sync"]; since = "1.7.0"; weight = 1566 };
  { key = "beacon.sound.fallback_0089";                  label = "lazy_boat_89";                arity = 2; tags = ["packet"]; since = "1.2.0"; weight = 936 };
  { key = "smoker.sound.modern_0090";                    label = "local_comparator_90";         arity = 3; tags = ["packet"]; since = "1.3.1"; weight = 354 };
  { key = "effect.sound.local_0091";                     label = "local_firework_91";           arity = 2; tags = ["experimental"; "untyped"]; since = "1.5.2"; weight = 607 };
  { key = "shield.sound.canonical_0092";                 label = "secondary_target_92";         arity = 5; tags = ["core"]; since = "1.7.0"; weight = 1009 };
  { key = "beacon.sound.provisional_0093";               label = "loose_arrow_93";              arity = 4; tags = ["runtime"; "cached"; "emit"]; since = "1.7.0"; weight = 3119 };
  { key = "banner.sound.modern_0094";                    label = "derived_gui_94";              arity = 6; tags = ["lower"; "core"; "parse"]; since = "1.4.0"; weight = 978 };
  { key = "repeater.sound.cached_0095";                  label = "eager_composter_95";          arity = 2; tags = ["sync"]; since = "1.7.0"; weight = 2811 };
  { key = "player.sound.legacy_0096";                    label = "provisional_cartography_96";  arity = 6; tags = ["sync"; "packet"]; since = "1.6.0"; weight = 3721 };
  { key = "bossbar.sound.derived_0097";                  label = "secondary_stonecutter_97";    arity = 4; tags = ["experimental"]; since = "1.3.1"; weight = 40 };
  { key = "block.sound.lazy_0098";                       label = "strict_shield_98";            arity = 1; tags = ["typed"]; since = "1.6.0"; weight = 1398 };
  { key = "pane.sound.local_0099";                       label = "derived_attribute_99";        arity = 3; tags = ["registry"]; since = "1.0.0"; weight = 795 };
  { key = "entity.sound.canonical_0100";                 label = "canonical_enchant_100";       arity = 0; tags = ["codegen"; "runtime"]; since = "1.2.0"; weight = 511 };
  { key = "target.sound.loose_0101";                     label = "canonical_packet_101";        arity = 5; tags = ["compat"]; since = "1.9.0"; weight = 594 };
  { key = "portal.sound.primary_0102";                   label = "cached_comparator_102";       arity = 7; tags = ["lower"; "emit"; "registry"]; since = "1.3.1"; weight = 3376 };
  { key = "portal.sound.provisional_0103";               label = "public_boat_103";             arity = 4; tags = ["emit"]; since = "1.4.0"; weight = 59 };
  { key = "hologram.sound.scoped_0104";                  label = "strict_bossbar_104";          arity = 0; tags = ["lower"]; since = "1.8.3"; weight = 2055 };
  { key = "player.sound.loose_0105";                     label = "hidden_hologram_105";         arity = 0; tags = ["sync"; "content"]; since = "1.6.0"; weight = 3430 };
  { key = "map.sound.public_0106";                       label = "modern_composter_106";        arity = 3; tags = ["core"]; since = "1.2.0"; weight = 2082 };
  { key = "barrel.sound.strict_0107";                    label = "legacy_structure_107";        arity = 2; tags = ["packet"; "content"]; since = "1.2.0"; weight = 1531 };
  { key = "lectern.sound.stable_0108";                   label = "internal_trident_108";        arity = 6; tags = ["packet"; "registry"]; since = "1.2.0"; weight = 3742 };
  { key = "effect.sound.primary_0109";                   label = "eager_potion_109";            arity = 2; tags = ["parse"; "emit"; "cold"]; since = "1.0.0"; weight = 626 };
  { key = "attribute.sound.global_0110";                 label = "modern_arrow_110";            arity = 7; tags = ["async"]; since = "1.6.0"; weight = 1243 };
  { key = "structure.sound.loose_0111";                  label = "scoped_composter_111";        arity = 5; tags = ["content"; "async"]; since = "1.5.2"; weight = 289 };
  { key = "dispenser.sound.fallback_0112";               label = "eager_particle_112";          arity = 3; tags = ["cached"; "hot"; "cold"]; since = "1.0.0"; weight = 2568 };
  { key = "grindstone.sound.fallback_0113";              label = "loose_particle_113";          arity = 6; tags = ["sync"]; since = "1.9.0"; weight = 120 };
  { key = "banner.sound.stable_0114";                    label = "scoped_npc_114";              arity = 4; tags = ["async"; "cached"]; since = "1.0.0"; weight = 2907 };
  { key = "player.sound.derived_0115";                   label = "local_bossbar_115";           arity = 1; tags = ["cached"; "core"]; since = "1.8.3"; weight = 3869 };
  { key = "potion.sound.modern_0116";                    label = "stable_bell_116";             arity = 2; tags = ["parse"; "sync"]; since = "1.7.0"; weight = 2978 };
  { key = "effect.sound.loose_0117";                     label = "primary_minecart_117";        arity = 6; tags = ["compat"; "async"; "cold"]; since = "1.8.3"; weight = 2084 };
  { key = "attribute.sound.fallback_0118";               label = "legacy_world_118";            arity = 2; tags = ["registry"; "compat"]; since = "1.9.0"; weight = 1716 };
  { key = "boat.sound.cached_0119";                      label = "secondary_bell_119";          arity = 3; tags = ["hot"; "registry"; "cached"]; since = "1.3.1"; weight = 4024 };
  { key = "player.sound.local_0120";                     label = "public_piston_120";           arity = 1; tags = ["typed"; "untyped"; "codegen"]; since = "1.5.2"; weight = 2913 };
  { key = "trade.sound.lazy_0121";                       label = "hidden_player_121";           arity = 6; tags = ["check"; "async"; "typed"]; since = "1.4.0"; weight = 3093 };
  { key = "arrow.sound.canonical_0122";                  label = "global_mob_122";              arity = 3; tags = ["lower"; "codegen"]; since = "1.2.0"; weight = 3525 };
  { key = "brewing.sound.global_0123";                   label = "derived_firework_123";        arity = 5; tags = ["check"]; since = "1.7.0"; weight = 2075 };
  { key = "entity.sound.modern_0124";                    label = "cached_boat_124";             arity = 0; tags = ["content"]; since = "1.3.1"; weight = 2498 };
  { key = "trident.sound.loose_0125";                    label = "primary_packet_125";          arity = 4; tags = ["emit"; "hot"]; since = "1.9.0"; weight = 1902 };
  { key = "beacon.sound.eager_0126";                     label = "hidden_dispenser_126";        arity = 7; tags = ["check"; "async"; "core"]; since = "1.4.0"; weight = 3837 };
  { key = "particle.sound.derived_0127";                 label = "scoped_tablist_127";          arity = 6; tags = ["codegen"]; since = "1.4.0"; weight = 3789 };
  { key = "piston.sound.stable_0128";                    label = "stable_furnace_128";          arity = 3; tags = ["typed"; "parse"; "sync"]; since = "1.7.0"; weight = 951 };
  { key = "inventory.sound.public_0129";                 label = "eager_team_129";              arity = 4; tags = ["legacy"; "emit"]; since = "1.0.0"; weight = 323 };
  { key = "scoreboard.sound.stable_0130";                label = "hidden_barrel_130";           arity = 1; tags = ["async"; "legacy"; "registry"]; since = "1.5.2"; weight = 2667 };
  { key = "hologram.sound.global_0131";                  label = "stable_slot_131";             arity = 7; tags = ["hot"; "core"; "packet"]; since = "1.8.3"; weight = 735 };
  { key = "arrow.sound.provisional_0132";                label = "internal_hopper_132";         arity = 3; tags = ["untyped"]; since = "1.6.0"; weight = 1706 };
  { key = "stonecutter.sound.derived_0133";              label = "secondary_comparator_133";    arity = 5; tags = ["compat"; "sync"]; since = "1.4.0"; weight = 3610 };
  { key = "anvil.sound.derived_0134";                    label = "lazy_entity_134";             arity = 4; tags = ["registry"; "experimental"]; since = "1.4.0"; weight = 394 };
  { key = "bundle.sound.primary_0135";                   label = "provisional_pane_135";        arity = 1; tags = ["typed"; "runtime"]; since = "1.9.0"; weight = 1710 };
  { key = "repeater.sound.derived_0136";                 label = "strict_banner_136";           arity = 3; tags = ["lower"; "packet"; "legacy"]; since = "1.9.0"; weight = 1774 };
  { key = "attribute.sound.public_0137";                 label = "hidden_barrel_137";           arity = 5; tags = ["cached"; "untyped"; "check"]; since = "1.6.0"; weight = 2495 };
  { key = "world.sound.fallback_0138";                   label = "global_villager_138";         arity = 6; tags = ["emit"]; since = "1.3.1"; weight = 2820 };
  { key = "beacon.sound.legacy_0139";                    label = "internal_target_139";         arity = 3; tags = ["sync"; "check"]; since = "1.8.3"; weight = 2351 };
  { key = "region.sound.canonical_0140";                 label = "provisional_compass_140";     arity = 1; tags = ["sync"; "legacy"]; since = "1.9.0"; weight = 610 };
  { key = "stonecutter.sound.canonical_0141";            label = "scoped_dropper_141";          arity = 1; tags = ["sync"; "parse"; "compat"]; since = "1.9.0"; weight = 2400 };
  { key = "inventory.sound.local_0142";                  label = "eager_item_142";              arity = 0; tags = ["check"; "core"]; since = "1.9.0"; weight = 1073 };
  { key = "biome.sound.provisional_0143";                label = "eager_gui_143";               arity = 0; tags = ["hot"; "typed"]; since = "1.9.0"; weight = 86 };
  { key = "shulker.sound.provisional_0144";              label = "derived_inventory_144";       arity = 5; tags = ["legacy"]; since = "1.5.2"; weight = 2374 };
  { key = "crossbow.sound.eager_0145";                   label = "canonical_stonecutter_145";   arity = 7; tags = ["lower"; "codegen"; "compat"]; since = "1.6.0"; weight = 225 };
  { key = "comparator.sound.cached_0146";                label = "legacy_compass_146";          arity = 0; tags = ["untyped"; "registry"]; since = "1.2.0"; weight = 392 };
  { key = "gui.sound.modern_0147";                       label = "cached_recipe_147";           arity = 5; tags = ["core"]; since = "1.0.0"; weight = 2789 };
  { key = "trade.sound.provisional_0148";                label = "internal_inventory_148";      arity = 7; tags = ["experimental"; "lower"]; since = "1.2.0"; weight = 3782 };
  { key = "objective.sound.fallback_0149";               label = "stable_firework_149";         arity = 1; tags = ["emit"; "content"; "check"]; since = "1.6.0"; weight = 2188 };
  { key = "portal.sound.derived_0150";                   label = "scoped_tablist_150";          arity = 7; tags = ["parse"; "hot"; "content"]; since = "1.3.1"; weight = 31 };
  { key = "particle.sound.strict_0151";                  label = "loose_shulker_151";           arity = 3; tags = ["parse"; "legacy"; "check"]; since = "1.3.1"; weight = 3158 };
  { key = "shield.sound.derived_0152";                   label = "modern_loom_152";             arity = 4; tags = ["lower"; "parse"]; since = "1.8.3"; weight = 1665 };
  { key = "effect.sound.lazy_0153";                      label = "scoped_observer_153";         arity = 5; tags = ["untyped"; "typed"]; since = "1.9.0"; weight = 305 };
  { key = "attribute.sound.secondary_0154";              label = "global_dropper_154";          arity = 6; tags = ["compat"; "core"; "runtime"]; since = "1.5.2"; weight = 1732 };
  { key = "enchant.sound.loose_0155";                    label = "loose_objective_155";         arity = 3; tags = ["compat"; "runtime"]; since = "1.2.0"; weight = 879 };
  { key = "crossbow.sound.provisional_0156";             label = "loose_compass_156";           arity = 0; tags = ["untyped"]; since = "1.7.0"; weight = 128 };
  { key = "bundle.sound.stable_0157";                    label = "stable_world_157";            arity = 4; tags = ["async"; "cold"]; since = "1.9.0"; weight = 2553 };
  { key = "spawner.sound.eager_0158";                    label = "cached_bell_158";             arity = 2; tags = ["compat"; "codegen"; "cold"]; since = "1.6.0"; weight = 3345 };
  { key = "world.sound.global_0159";                     label = "public_loom_159";             arity = 3; tags = ["compat"]; since = "1.4.0"; weight = 3263 };
  { key = "spawner.sound.eager_0160";                    label = "hidden_bundle_160";           arity = 0; tags = ["codegen"]; since = "1.6.0"; weight = 797 };
  { key = "piston.sound.local_0161";                     label = "strict_world_161";            arity = 3; tags = ["lower"; "hot"; "check"]; since = "1.5.2"; weight = 625 };
  { key = "entity.sound.provisional_0162";               label = "derived_item_162";            arity = 3; tags = ["legacy"; "sync"; "emit"]; since = "1.5.2"; weight = 3967 };
  { key = "composter.sound.local_0163";                  label = "eager_chunk_163";             arity = 4; tags = ["lower"; "core"]; since = "1.7.0"; weight = 1848 };
  { key = "banner_pattern.sound.legacy_0164";            label = "global_villager_164";         arity = 2; tags = ["check"]; since = "1.8.3"; weight = 1757 };
  { key = "observer.sound.hidden_0165";                  label = "fallback_trident_165";        arity = 1; tags = ["lower"]; since = "1.3.1"; weight = 3535 };
  { key = "furnace.sound.primary_0166";                  label = "fallback_item_166";           arity = 3; tags = ["typed"; "experimental"]; since = "1.7.0"; weight = 2375 };
  { key = "sound.sound.lazy_0167";                       label = "lazy_smoker_167";             arity = 7; tags = ["experimental"; "registry"; "check"]; since = "1.9.0"; weight = 3237 };
  { key = "npc.sound.provisional_0168";                  label = "canonical_loom_168";          arity = 0; tags = ["compat"; "experimental"; "emit"]; since = "1.0.0"; weight = 2602 };
  { key = "bossbar.sound.legacy_0169";                   label = "hidden_sound_169";            arity = 7; tags = ["async"; "core"; "check"]; since = "1.5.2"; weight = 1743 };
  { key = "barrel.sound.canonical_0170";                 label = "lazy_inventory_170";          arity = 6; tags = ["cold"; "sync"; "emit"]; since = "1.8.3"; weight = 693 };
  { key = "structure.sound.hidden_0171";                 label = "modern_inventory_171";        arity = 5; tags = ["cold"]; since = "1.0.0"; weight = 4009 };
  { key = "villager.sound.fallback_0172";                label = "stable_elytra_172";           arity = 0; tags = ["check"]; since = "1.4.0"; weight = 640 };
  { key = "repeater.sound.derived_0173";                 label = "provisional_particle_173";    arity = 4; tags = ["hot"]; since = "1.8.3"; weight = 2170 };
  { key = "hologram.sound.scoped_0174";                  label = "derived_map_174";             arity = 4; tags = ["experimental"]; since = "1.7.0"; weight = 1260 };
  { key = "anvil.sound.cached_0175";                     label = "primary_npc_175";             arity = 0; tags = ["sync"; "parse"; "cold"]; since = "1.8.3"; weight = 1597 };
  { key = "region.sound.loose_0176";                     label = "lazy_player_176";             arity = 1; tags = ["packet"]; since = "1.3.1"; weight = 564 };
  { key = "spawner.sound.canonical_0177";                label = "loose_spawner_177";           arity = 7; tags = ["sync"; "untyped"]; since = "1.7.0"; weight = 918 };
  { key = "dispenser.sound.canonical_0178";              label = "secondary_hopper_178";        arity = 0; tags = ["typed"; "hot"; "runtime"]; since = "1.4.0"; weight = 3631 };
  { key = "arrow.sound.legacy_0179";                     label = "scoped_boat_179";             arity = 1; tags = ["parse"; "check"; "registry"]; since = "1.5.2"; weight = 1940 };
  { key = "arrow.sound.provisional_0180";                label = "derived_firework_180";        arity = 4; tags = ["codegen"]; since = "1.3.1"; weight = 2890 };
  { key = "bell.sound.global_0181";                      label = "fallback_campfire_181";       arity = 2; tags = ["typed"]; since = "1.3.1"; weight = 2550 };
  { key = "boat.sound.internal_0182";                    label = "secondary_composter_182";     arity = 6; tags = ["registry"; "runtime"; "legacy"]; since = "1.8.3"; weight = 2418 };
  { key = "arrow.sound.provisional_0183";                label = "lazy_stonecutter_183";        arity = 6; tags = ["legacy"; "compat"; "cold"]; since = "1.9.0"; weight = 2735 };
  { key = "observer.sound.cached_0184";                  label = "global_portal_184";           arity = 2; tags = ["untyped"; "cold"; "hot"]; since = "1.9.0"; weight = 3449 };
  { key = "hopper.sound.scoped_0185";                    label = "lazy_target_185";             arity = 0; tags = ["content"; "lower"; "untyped"]; since = "1.4.0"; weight = 2538 };
  { key = "observer.sound.stable_0186";                  label = "canonical_particle_186";      arity = 4; tags = ["packet"]; since = "1.0.0"; weight = 2429 };
  { key = "region.sound.local_0187";                     label = "local_composter_187";         arity = 1; tags = ["parse"; "emit"; "cached"]; since = "1.0.0"; weight = 1732 };
  { key = "loom.sound.derived_0188";                     label = "derived_barrel_188";          arity = 2; tags = ["runtime"; "lower"]; since = "1.3.1"; weight = 2928 };
  { key = "banner_pattern.sound.internal_0189";          label = "eager_spawner_189";           arity = 0; tags = ["packet"; "untyped"]; since = "1.5.2"; weight = 2487 };
  { key = "anvil.sound.local_0190";                      label = "modern_compass_190";          arity = 2; tags = ["compat"]; since = "1.6.0"; weight = 3256 };
  { key = "cartography.sound.scoped_0191";               label = "lazy_dropper_191";            arity = 4; tags = ["sync"]; since = "1.9.0"; weight = 626 };
  { key = "bundle.sound.hidden_0192";                    label = "eager_composter_192";         arity = 4; tags = ["cached"; "codegen"; "cold"]; since = "1.3.1"; weight = 2413 };
  { key = "objective.sound.hidden_0193";                 label = "modern_hopper_193";           arity = 4; tags = ["runtime"; "core"; "emit"]; since = "1.0.0"; weight = 456 };
  { key = "bundle.sound.secondary_0194";                 label = "secondary_bell_194";          arity = 6; tags = ["experimental"; "cached"]; since = "1.4.0"; weight = 1701 };
  { key = "elytra.sound.local_0195";                     label = "strict_grindstone_195";       arity = 5; tags = ["emit"]; since = "1.9.0"; weight = 744 };
  { key = "shulker.sound.hidden_0196";                   label = "stable_clock_196";            arity = 3; tags = ["lower"]; since = "1.5.2"; weight = 4003 };
  { key = "anvil.sound.stable_0197";                     label = "strict_scoreboard_197";       arity = 7; tags = ["legacy"; "core"; "compat"]; since = "1.0.0"; weight = 1030 };
  { key = "trident.sound.secondary_0198";                label = "local_advancement_198";       arity = 5; tags = ["sync"; "cold"]; since = "1.0.0"; weight = 299 };
  { key = "team.sound.public_0199";                      label = "loose_repeater_199";          arity = 0; tags = ["lower"; "sync"]; since = "1.6.0"; weight = 419 };
  { key = "advancement.sound.global_0200";               label = "cached_shield_200";           arity = 2; tags = ["core"; "cached"]; since = "1.7.0"; weight = 1627 };
  { key = "slot.sound.local_0201";                       label = "canonical_elytra_201";        arity = 7; tags = ["codegen"; "cold"; "runtime"]; since = "1.9.0"; weight = 2534 };
  { key = "structure.sound.modern_0202";                 label = "stable_firework_202";         arity = 5; tags = ["runtime"; "lower"; "parse"]; since = "1.9.0"; weight = 122 };
  { key = "smoker.sound.hidden_0203";                    label = "primary_repeater_203";        arity = 6; tags = ["content"; "parse"]; since = "1.9.0"; weight = 473 };
  { key = "item.sound.hidden_0204";                      label = "public_trade_204";            arity = 3; tags = ["core"; "runtime"]; since = "1.3.1"; weight = 2025 };
  { key = "campfire.sound.scoped_0205";                  label = "stable_dispenser_205";        arity = 2; tags = ["experimental"; "parse"; "codegen"]; since = "1.9.0"; weight = 1289 };
  { key = "arrow.sound.canonical_0206";                  label = "public_attribute_206";        arity = 3; tags = ["typed"]; since = "1.6.0"; weight = 3867 };
  { key = "clock.sound.eager_0207";                      label = "provisional_shield_207";      arity = 3; tags = ["legacy"; "check"]; since = "1.5.2"; weight = 1661 };
  { key = "chunk.sound.provisional_0208";                label = "lazy_packet_208";             arity = 5; tags = ["codegen"; "cached"]; since = "1.4.0"; weight = 19 };
  { key = "target.sound.derived_0209";                   label = "loose_anvil_209";             arity = 5; tags = ["legacy"; "runtime"]; since = "1.4.0"; weight = 1217 };
  { key = "trade.sound.cached_0210";                     label = "secondary_smoker_210";        arity = 1; tags = ["hot"]; since = "1.7.0"; weight = 462 };
  { key = "entity.sound.canonical_0211";                 label = "provisional_cartography_211"; arity = 7; tags = ["registry"]; since = "1.3.1"; weight = 1897 };
  { key = "particle.sound.cached_0212";                  label = "provisional_clock_212";       arity = 3; tags = ["content"; "hot"; "cached"]; since = "1.7.0"; weight = 2956 };
  { key = "smoker.sound.fallback_0213";                  label = "stable_boat_213";             arity = 0; tags = ["experimental"; "runtime"]; since = "1.5.2"; weight = 321 };
  { key = "smithing.sound.derived_0214";                 label = "provisional_advancement_214"; arity = 7; tags = ["registry"; "packet"]; since = "1.0.0"; weight = 3783 };
  { key = "lectern.sound.lazy_0215";                     label = "legacy_bell_215";             arity = 5; tags = ["sync"; "lower"]; since = "1.0.0"; weight = 3888 };
  { key = "minecart.sound.primary_0216";                 label = "secondary_dropper_216";       arity = 2; tags = ["codegen"]; since = "1.2.0"; weight = 2841 };
  { key = "scoreboard.sound.stable_0217";                label = "public_team_217";             arity = 3; tags = ["core"; "runtime"; "typed"]; since = "1.9.0"; weight = 2348 };
  { key = "smithing.sound.primary_0218";                 label = "eager_firework_218";          arity = 0; tags = ["untyped"]; since = "1.9.0"; weight = 3263 };
  { key = "lectern.sound.cached_0219";                   label = "modern_inventory_219";        arity = 1; tags = ["content"; "cold"]; since = "1.5.2"; weight = 2148 };
  { key = "conduit.sound.fallback_0220";                 label = "secondary_bossbar_220";       arity = 6; tags = ["cold"; "runtime"]; since = "1.8.3"; weight = 1120 };
  { key = "hologram.sound.local_0221";                   label = "secondary_slot_221";          arity = 0; tags = ["packet"; "typed"; "content"]; since = "1.2.0"; weight = 722 };
  { key = "repeater.sound.scoped_0222";                  label = "modern_potion_222";           arity = 3; tags = ["untyped"; "registry"]; since = "1.3.1"; weight = 2480 };
  { key = "boat.sound.legacy_0223";                      label = "derived_block_223";           arity = 1; tags = ["lower"; "async"]; since = "1.6.0"; weight = 3628 };
  { key = "compass.sound.derived_0224";                  label = "hidden_banner_224";           arity = 1; tags = ["cold"; "legacy"]; since = "1.9.0"; weight = 218 };
  { key = "conduit.sound.provisional_0225";              label = "scoped_villager_225";         arity = 4; tags = ["parse"; "sync"]; since = "1.5.2"; weight = 2181 };
  { key = "trade.sound.hidden_0226";                     label = "primary_crossbow_226";        arity = 5; tags = ["check"]; since = "1.5.2"; weight = 3962 };
  { key = "block.sound.local_0227";                      label = "provisional_trade_227";       arity = 6; tags = ["legacy"; "untyped"; "packet"]; since = "1.7.0"; weight = 1528 };
  { key = "bell.sound.fallback_0228";                    label = "fallback_structure_228";      arity = 6; tags = ["async"; "emit"; "packet"]; since = "1.3.1"; weight = 39 };
  { key = "gui.sound.public_0229";                       label = "lazy_scoreboard_229";         arity = 5; tags = ["compat"]; since = "1.0.0"; weight = 2030 };
  { key = "bell.sound.lazy_0230";                        label = "internal_mob_230";            arity = 6; tags = ["experimental"]; since = "1.3.1"; weight = 117 };
  { key = "advancement.sound.legacy_0231";               label = "global_mob_231";              arity = 0; tags = ["hot"; "content"; "runtime"]; since = "1.0.0"; weight = 2246 };
  { key = "shulker.sound.canonical_0232";                label = "lazy_portal_232";             arity = 2; tags = ["runtime"; "cold"; "compat"]; since = "1.4.0"; weight = 1808 };
  { key = "trade.sound.local_0233";                      label = "strict_hologram_233";         arity = 6; tags = ["check"; "experimental"; "lower"]; since = "1.2.0"; weight = 3957 };
  { key = "hopper.sound.secondary_0234";                 label = "provisional_shulker_234";     arity = 2; tags = ["compat"; "sync"]; since = "1.2.0"; weight = 2553 };
  { key = "lectern.sound.public_0235";                   label = "hidden_rail_235";             arity = 4; tags = ["typed"; "legacy"]; since = "1.3.1"; weight = 948 };
  { key = "entity.sound.internal_0236";                  label = "derived_sound_236";           arity = 7; tags = ["sync"]; since = "1.6.0"; weight = 2691 };
  { key = "campfire.sound.provisional_0237";             label = "legacy_packet_237";           arity = 5; tags = ["emit"; "untyped"; "sync"]; since = "1.0.0"; weight = 3398 };
  { key = "slot.sound.provisional_0238";                 label = "scoped_sound_238";            arity = 1; tags = ["check"; "cached"; "untyped"]; since = "1.4.0"; weight = 1725 };
  { key = "team.sound.public_0239";                      label = "fallback_beacon_239";         arity = 6; tags = ["cached"; "core"; "runtime"]; since = "1.5.2"; weight = 1785 };
  { key = "tablist.sound.scoped_0240";                   label = "primary_structure_240";       arity = 1; tags = ["async"; "experimental"]; since = "1.0.0"; weight = 769 };
  { key = "furnace.sound.canonical_0241";                label = "hidden_item_241";             arity = 4; tags = ["parse"]; since = "1.7.0"; weight = 3968 };
  { key = "effect.sound.eager_0242";                     label = "provisional_beacon_242";      arity = 1; tags = ["compat"; "core"; "legacy"]; since = "1.8.3"; weight = 2074 };
  { key = "potion.sound.loose_0243";                     label = "lazy_gui_243";                arity = 3; tags = ["core"]; since = "1.8.3"; weight = 617 };
  { key = "arrow.sound.hidden_0244";                     label = "local_furnace_244";           arity = 7; tags = ["cold"]; since = "1.3.1"; weight = 2801 };
  { key = "hologram.sound.lazy_0245";                    label = "eager_smithing_245";          arity = 7; tags = ["untyped"; "lower"; "packet"]; since = "1.2.0"; weight = 3037 };
  { key = "banner.sound.secondary_0246";                 label = "legacy_villager_246";         arity = 5; tags = ["cached"; "experimental"]; since = "1.6.0"; weight = 1683 };
  { key = "tablist.sound.secondary_0247";                label = "loose_spawner_247";           arity = 0; tags = ["experimental"]; since = "1.8.3"; weight = 1244 };
  { key = "spawner.sound.local_0248";                    label = "strict_conduit_248";          arity = 1; tags = ["legacy"; "cold"]; since = "1.5.2"; weight = 434 };
  { key = "mob.sound.strict_0249";                       label = "provisional_map_249";         arity = 2; tags = ["emit"; "parse"]; since = "1.9.0"; weight = 1448 };
  { key = "observer.sound.derived_0250";                 label = "cached_comparator_250";       arity = 2; tags = ["runtime"; "hot"; "packet"]; since = "1.8.3"; weight = 3162 };
  { key = "villager.sound.eager_0251";                   label = "secondary_composter_251";     arity = 5; tags = ["core"; "untyped"]; since = "1.8.3"; weight = 3077 };
  { key = "lectern.sound.canonical_0252";                label = "canonical_bundle_252";        arity = 2; tags = ["cached"]; since = "1.4.0"; weight = 2216 };
  { key = "observer.sound.canonical_0253";               label = "cached_bundle_253";           arity = 6; tags = ["content"; "core"; "emit"]; since = "1.6.0"; weight = 1698 };
  { key = "hopper.sound.stable_0254";                    label = "hidden_bundle_254";           arity = 0; tags = ["async"; "content"]; since = "1.8.3"; weight = 3565 };
  { key = "observer.sound.canonical_0255";               label = "scoped_minecart_255";         arity = 5; tags = ["runtime"]; since = "1.3.1"; weight = 1718 };
  { key = "boat.sound.modern_0256";                      label = "public_minecart_256";         arity = 1; tags = ["registry"]; since = "1.5.2"; weight = 2716 };
  { key = "tablist.sound.provisional_0257";              label = "secondary_hopper_257";        arity = 4; tags = ["packet"; "check"]; since = "1.3.1"; weight = 2129 };
  { key = "repeater.sound.hidden_0258";                  label = "derived_hologram_258";        arity = 4; tags = ["parse"; "untyped"]; since = "1.3.1"; weight = 906 };
  { key = "team.sound.lazy_0259";                        label = "public_dropper_259";          arity = 0; tags = ["untyped"]; since = "1.2.0"; weight = 1881 };
  { key = "team.sound.primary_0260";                     label = "primary_anvil_260";           arity = 2; tags = ["compat"; "cached"]; since = "1.6.0"; weight = 1949 };
  { key = "anvil.sound.local_0261";                      label = "local_spawner_261";           arity = 1; tags = ["hot"]; since = "1.9.0"; weight = 3834 };
  { key = "entity.sound.stable_0262";                    label = "global_clock_262";            arity = 5; tags = ["lower"; "registry"; "runtime"]; since = "1.0.0"; weight = 3995 };
  { key = "block.sound.modern_0263";                     label = "stable_objective_263";        arity = 3; tags = ["compat"; "lower"]; since = "1.8.3"; weight = 53 };
  { key = "packet.sound.primary_0264";                   label = "primary_team_264";            arity = 1; tags = ["cached"; "core"; "parse"]; since = "1.8.3"; weight = 2995 };
  { key = "team.sound.eager_0265";                       label = "public_shulker_265";          arity = 2; tags = ["lower"; "parse"; "cached"]; since = "1.7.0"; weight = 1952 };
  { key = "loom.sound.eager_0266";                       label = "fallback_banner_266";         arity = 7; tags = ["packet"; "lower"; "cold"]; since = "1.3.1"; weight = 1949 };
  { key = "enchant.sound.local_0267";                    label = "lazy_inventory_267";          arity = 5; tags = ["cached"; "untyped"; "emit"]; since = "1.0.0"; weight = 1730 };
  { key = "npc.sound.derived_0268";                      label = "local_stonecutter_268";       arity = 1; tags = ["legacy"; "async"; "cold"]; since = "1.9.0"; weight = 492 };
  { key = "biome.sound.global_0269";                     label = "global_trade_269";            arity = 4; tags = ["experimental"; "lower"; "runtime"]; since = "1.5.2"; weight = 2286 };
  { key = "team.sound.scoped_0270";                      label = "fallback_block_270";          arity = 4; tags = ["registry"]; since = "1.4.0"; weight = 2192 };
  { key = "lectern.sound.stable_0271";                   label = "secondary_smoker_271";        arity = 4; tags = ["legacy"]; since = "1.9.0"; weight = 316 };
  { key = "chunk.sound.eager_0272";                      label = "local_effect_272";            arity = 1; tags = ["check"; "lower"; "experimental"]; since = "1.0.0"; weight = 262 };
  { key = "lectern.sound.strict_0273";                   label = "stable_stonecutter_273";      arity = 5; tags = ["codegen"]; since = "1.5.2"; weight = 3224 };
  { key = "mob.sound.local_0274";                        label = "hidden_furnace_274";          arity = 1; tags = ["hot"; "core"; "packet"]; since = "1.6.0"; weight = 3430 };
  { key = "observer.sound.derived_0275";                 label = "hidden_potion_275";           arity = 7; tags = ["parse"]; since = "1.4.0"; weight = 236 };
  { key = "inventory.sound.modern_0276";                 label = "legacy_minecart_276";         arity = 1; tags = ["sync"]; since = "1.6.0"; weight = 3056 };
  { key = "mob.sound.provisional_0277";                  label = "modern_slot_277";             arity = 3; tags = ["parse"]; since = "1.5.2"; weight = 907 };
  { key = "recipe.sound.fallback_0278";                  label = "provisional_rail_278";        arity = 5; tags = ["core"]; since = "1.0.0"; weight = 3793 };
  { key = "packet.sound.local_0279";                     label = "modern_boat_279";             arity = 1; tags = ["cold"; "untyped"; "runtime"]; since = "1.3.1"; weight = 3886 };
  { key = "item.sound.canonical_0280";                   label = "loose_potion_280";            arity = 3; tags = ["cached"]; since = "1.8.3"; weight = 547 };
  { key = "chunk.sound.secondary_0281";                  label = "legacy_block_281";            arity = 7; tags = ["untyped"]; since = "1.9.0"; weight = 723 };
  { key = "grindstone.sound.internal_0282";              label = "eager_npc_282";               arity = 3; tags = ["lower"; "runtime"]; since = "1.0.0"; weight = 1348 };
  { key = "hologram.sound.fallback_0283";                label = "fallback_pane_283";           arity = 5; tags = ["legacy"; "hot"; "codegen"]; since = "1.9.0"; weight = 3336 };
  { key = "anvil.sound.hidden_0284";                     label = "secondary_attribute_284";     arity = 4; tags = ["compat"]; since = "1.5.2"; weight = 1944 };
  { key = "attribute.sound.eager_0285";                  label = "provisional_bell_285";        arity = 2; tags = ["experimental"; "typed"; "emit"]; since = "1.4.0"; weight = 2371 };
  { key = "stonecutter.sound.hidden_0286";               label = "primary_packet_286";          arity = 4; tags = ["check"]; since = "1.3.1"; weight = 2809 };
  { key = "shulker.sound.eager_0287";                    label = "canonical_portal_287";        arity = 3; tags = ["hot"; "check"; "emit"]; since = "1.8.3"; weight = 728 };
  { key = "mob.sound.provisional_0288";                  label = "internal_trident_288";        arity = 6; tags = ["content"]; since = "1.5.2"; weight = 425 };
  { key = "cartography.sound.loose_0289";                label = "lazy_advancement_289";        arity = 6; tags = ["parse"; "runtime"; "typed"]; since = "1.2.0"; weight = 1960 };
  { key = "bundle.sound.derived_0290";                   label = "primary_dropper_290";         arity = 5; tags = ["cold"; "lower"]; since = "1.9.0"; weight = 3735 };
  { key = "player.sound.local_0291";                     label = "legacy_gui_291";              arity = 6; tags = ["core"; "legacy"; "async"]; since = "1.7.0"; weight = 2630 };
  { key = "firework.sound.cached_0292";                  label = "lazy_player_292";             arity = 6; tags = ["cold"]; since = "1.6.0"; weight = 4003 };
  { key = "banner_pattern.sound.cached_0293";            label = "public_team_293";             arity = 1; tags = ["parse"; "experimental"]; since = "1.6.0"; weight = 630 };
  { key = "barrel.sound.global_0294";                    label = "canonical_advancement_294";   arity = 3; tags = ["emit"; "async"]; since = "1.5.2"; weight = 3285 };
  { key = "composter.sound.strict_0295";                 label = "modern_campfire_295";         arity = 7; tags = ["emit"; "typed"; "content"]; since = "1.8.3"; weight = 3177 };
  { key = "team.sound.internal_0296";                    label = "internal_mob_296";            arity = 3; tags = ["hot"; "typed"]; since = "1.6.0"; weight = 1701 };
  { key = "scoreboard.sound.fallback_0297";              label = "eager_cartography_297";       arity = 2; tags = ["packet"; "check"]; since = "1.7.0"; weight = 3765 };
  { key = "npc.sound.eager_0298";                        label = "legacy_gui_298";              arity = 6; tags = ["legacy"]; since = "1.8.3"; weight = 3292 };
  { key = "biome.sound.cached_0299";                     label = "modern_campfire_299";         arity = 7; tags = ["cached"; "packet"]; since = "1.9.0"; weight = 2600 };
  { key = "hopper.sound.global_0300";                    label = "canonical_entity_300";        arity = 6; tags = ["runtime"; "async"]; since = "1.4.0"; weight = 251 };
  { key = "rail.sound.derived_0301";                     label = "loose_beacon_301";            arity = 4; tags = ["experimental"; "codegen"]; since = "1.3.1"; weight = 1388 };
  { key = "minecart.sound.internal_0302";                label = "modern_particle_302";         arity = 7; tags = ["parse"; "async"; "compat"]; since = "1.4.0"; weight = 3858 };
  { key = "team.sound.hidden_0303";                      label = "stable_firework_303";         arity = 0; tags = ["compat"]; since = "1.7.0"; weight = 506 };
  { key = "team.sound.secondary_0304";                   label = "internal_slot_304";           arity = 5; tags = ["typed"; "untyped"; "legacy"]; since = "1.2.0"; weight = 3466 };
  { key = "potion.sound.fallback_0305";                  label = "lazy_smoker_305";             arity = 4; tags = ["core"; "compat"]; since = "1.6.0"; weight = 463 };
  { key = "advancement.sound.modern_0306";               label = "stable_observer_306";         arity = 3; tags = ["parse"; "check"]; since = "1.6.0"; weight = 1177 };
  { key = "potion.sound.provisional_0307";               label = "stable_effect_307";           arity = 7; tags = ["experimental"; "runtime"; "legacy"]; since = "1.4.0"; weight = 2018 };
  { key = "campfire.sound.eager_0308";                   label = "scoped_dispenser_308";        arity = 6; tags = ["core"; "compat"]; since = "1.4.0"; weight = 4008 };
  { key = "observer.sound.legacy_0309";                  label = "cached_comparator_309";       arity = 6; tags = ["parse"; "check"; "async"]; since = "1.6.0"; weight = 182 };
  { key = "attribute.sound.lazy_0310";                   label = "global_smithing_310";         arity = 6; tags = ["hot"; "lower"]; since = "1.5.2"; weight = 1457 };
  { key = "dispenser.sound.scoped_0311";                 label = "secondary_repeater_311";      arity = 5; tags = ["experimental"; "runtime"; "typed"]; since = "1.4.0"; weight = 359 };
  { key = "world.sound.secondary_0312";                  label = "provisional_piston_312";      arity = 6; tags = ["emit"]; since = "1.5.2"; weight = 266 };
  { key = "repeater.sound.modern_0313";                  label = "loose_observer_313";          arity = 3; tags = ["codegen"; "registry"]; since = "1.0.0"; weight = 3077 };
  { key = "crossbow.sound.internal_0314";                label = "strict_region_314";           arity = 4; tags = ["registry"; "untyped"; "typed"]; since = "1.0.0"; weight = 1501 };
  { key = "stonecutter.sound.global_0315";               label = "eager_bossbar_315";           arity = 2; tags = ["typed"; "sync"; "runtime"]; since = "1.8.3"; weight = 1730 };
  { key = "recipe.sound.scoped_0316";                    label = "cached_shield_316";           arity = 3; tags = ["async"; "cold"]; since = "1.7.0"; weight = 1276 };
  { key = "loom.sound.scoped_0317";                      label = "internal_scoreboard_317";     arity = 7; tags = ["cached"; "legacy"; "registry"]; since = "1.2.0"; weight = 2219 };
  { key = "block.sound.provisional_0318";                label = "canonical_mob_318";           arity = 1; tags = ["check"; "core"]; since = "1.6.0"; weight = 3661 };
  { key = "arrow.sound.strict_0319";                     label = "legacy_effect_319";           arity = 5; tags = ["core"]; since = "1.5.2"; weight = 1144 };
  { key = "brewing.sound.stable_0320";                   label = "scoped_campfire_320";         arity = 7; tags = ["check"; "emit"; "parse"]; since = "1.0.0"; weight = 698 };
  { key = "biome.sound.legacy_0321";                     label = "canonical_repeater_321";      arity = 3; tags = ["core"; "async"]; since = "1.2.0"; weight = 3294 };
  { key = "bundle.sound.provisional_0322";               label = "cached_anvil_322";            arity = 4; tags = ["core"; "legacy"; "cold"]; since = "1.9.0"; weight = 2761 };
  { key = "attribute.sound.fallback_0323";               label = "cached_bundle_323";           arity = 3; tags = ["packet"; "typed"]; since = "1.8.3"; weight = 2806 };
  { key = "world.sound.local_0324";                      label = "derived_repeater_324";        arity = 0; tags = ["codegen"]; since = "1.2.0"; weight = 3993 };
  { key = "smithing.sound.canonical_0325";               label = "internal_conduit_325";        arity = 4; tags = ["content"]; since = "1.9.0"; weight = 3898 };
  { key = "attribute.sound.strict_0326";                 label = "modern_smithing_326";         arity = 3; tags = ["cached"; "core"; "untyped"]; since = "1.3.1"; weight = 431 };
  { key = "brewing.sound.provisional_0327";              label = "public_packet_327";           arity = 5; tags = ["untyped"]; since = "1.2.0"; weight = 1617 };
  { key = "world.sound.public_0328";                     label = "public_inventory_328";        arity = 4; tags = ["packet"; "legacy"; "hot"]; since = "1.2.0"; weight = 3690 };
  { key = "campfire.sound.primary_0329";                 label = "modern_piston_329";           arity = 6; tags = ["emit"]; since = "1.6.0"; weight = 198 };
  { key = "enchant.sound.stable_0330";                   label = "fallback_elytra_330";         arity = 1; tags = ["hot"; "async"; "untyped"]; since = "1.5.2"; weight = 4025 };
  { key = "lectern.sound.public_0331";                   label = "secondary_firework_331";      arity = 6; tags = ["experimental"]; since = "1.7.0"; weight = 2283 };
  { key = "banner_pattern.sound.loose_0332";             label = "cached_block_332";            arity = 5; tags = ["cached"; "untyped"; "packet"]; since = "1.6.0"; weight = 1649 };
  { key = "advancement.sound.strict_0333";               label = "hidden_loom_333";             arity = 3; tags = ["compat"; "check"]; since = "1.3.1"; weight = 1719 };
  { key = "map.sound.modern_0334";                       label = "hidden_conduit_334";          arity = 1; tags = ["emit"; "cold"]; since = "1.6.0"; weight = 3779 };
  { key = "lectern.sound.loose_0335";                    label = "local_conduit_335";           arity = 7; tags = ["codegen"; "experimental"; "typed"]; since = "1.7.0"; weight = 2212 };
  { key = "furnace.sound.derived_0336";                  label = "provisional_enchant_336";     arity = 7; tags = ["codegen"]; since = "1.0.0"; weight = 246 };
  { key = "chunk.sound.fallback_0337";                   label = "loose_barrel_337";            arity = 4; tags = ["untyped"; "cached"; "sync"]; since = "1.4.0"; weight = 2200 };
  { key = "furnace.sound.provisional_0338";              label = "global_loom_338";             arity = 2; tags = ["cold"; "codegen"; "async"]; since = "1.6.0"; weight = 2388 };
  { key = "bundle.sound.legacy_0339";                    label = "cached_mob_339";              arity = 6; tags = ["hot"; "legacy"]; since = "1.3.1"; weight = 1636 };
  { key = "enchant.sound.legacy_0340";                   label = "secondary_grindstone_340";    arity = 7; tags = ["compat"; "packet"]; since = "1.2.0"; weight = 1840 };
  { key = "mob.sound.legacy_0341";                       label = "primary_brewing_341";         arity = 2; tags = ["codegen"; "parse"]; since = "1.7.0"; weight = 920 };
  { key = "trade.sound.lazy_0342";                       label = "legacy_repeater_342";         arity = 3; tags = ["experimental"]; since = "1.4.0"; weight = 2944 };
  { key = "world.sound.provisional_0343";                label = "lazy_composter_343";          arity = 3; tags = ["cached"; "cold"]; since = "1.3.1"; weight = 3656 };
  { key = "packet.sound.loose_0344";                     label = "lazy_potion_344";             arity = 2; tags = ["packet"]; since = "1.4.0"; weight = 10 };
  { key = "observer.sound.hidden_0345";                  label = "primary_composter_345";       arity = 6; tags = ["lower"; "cold"]; since = "1.4.0"; weight = 2841 };
  { key = "structure.sound.fallback_0346";               label = "cached_firework_346";         arity = 1; tags = ["async"; "sync"]; since = "1.5.2"; weight = 2121 };
  { key = "potion.sound.canonical_0347";                 label = "cached_objective_347";        arity = 0; tags = ["compat"]; since = "1.5.2"; weight = 1315 };
  { key = "stonecutter.sound.primary_0348";              label = "canonical_piston_348";        arity = 1; tags = ["untyped"; "registry"]; since = "1.9.0"; weight = 138 };
  { key = "portal.sound.lazy_0349";                      label = "canonical_minecart_349";      arity = 2; tags = ["registry"]; since = "1.7.0"; weight = 2792 };
  { key = "hopper.sound.canonical_0350";                 label = "provisional_advancement_350"; arity = 4; tags = ["packet"; "cold"; "lower"]; since = "1.0.0"; weight = 2218 };
  { key = "banner_pattern.sound.primary_0351";           label = "global_advancement_351";      arity = 5; tags = ["check"]; since = "1.6.0"; weight = 661 };
  { key = "bundle.sound.global_0352";                    label = "scoped_beacon_352";           arity = 4; tags = ["sync"; "check"; "registry"]; since = "1.8.3"; weight = 1797 };
  { key = "player.sound.cached_0353";                    label = "secondary_loom_353";          arity = 6; tags = ["cached"; "emit"; "experimental"]; since = "1.2.0"; weight = 3994 };
  { key = "particle.sound.public_0354";                  label = "global_firework_354";         arity = 7; tags = ["cached"; "check"; "experimental"]; since = "1.6.0"; weight = 528 };
  { key = "world.sound.provisional_0355";                label = "scoped_crossbow_355";         arity = 2; tags = ["cold"; "parse"; "untyped"]; since = "1.9.0"; weight = 3671 };
  { key = "brewing.sound.cached_0356";                   label = "canonical_firework_356";      arity = 6; tags = ["sync"; "content"]; since = "1.5.2"; weight = 916 };
  { key = "portal.sound.stable_0357";                    label = "cached_banner_357";           arity = 4; tags = ["emit"]; since = "1.4.0"; weight = 3406 };
  { key = "chunk.sound.internal_0358";                   label = "lazy_cartography_358";        arity = 0; tags = ["typed"; "sync"; "packet"]; since = "1.2.0"; weight = 1928 };
  { key = "villager.sound.canonical_0359";               label = "loose_campfire_359";          arity = 4; tags = ["untyped"; "legacy"; "core"]; since = "1.4.0"; weight = 3326 };
  { key = "world.sound.strict_0360";                     label = "canonical_campfire_360";      arity = 0; tags = ["content"; "hot"]; since = "1.2.0"; weight = 3645 };
  { key = "item.sound.primary_0361";                     label = "legacy_effect_361";           arity = 7; tags = ["core"; "sync"; "emit"]; since = "1.3.1"; weight = 1132 };
  { key = "trade.sound.legacy_0362";                     label = "hidden_grindstone_362";       arity = 6; tags = ["hot"; "async"]; since = "1.7.0"; weight = 1597 };
  { key = "bossbar.sound.provisional_0363";              label = "legacy_attribute_363";        arity = 5; tags = ["check"; "registry"; "parse"]; since = "1.3.1"; weight = 1774 };
  { key = "anvil.sound.local_0364";                      label = "hidden_potion_364";           arity = 3; tags = ["registry"; "async"; "cold"]; since = "1.9.0"; weight = 349 };
  { key = "hologram.sound.strict_0365";                  label = "provisional_region_365";      arity = 2; tags = ["emit"; "parse"; "check"]; since = "1.0.0"; weight = 1521 };
  { key = "trident.sound.lazy_0366";                     label = "stable_advancement_366";      arity = 1; tags = ["check"]; since = "1.0.0"; weight = 3673 };
  { key = "pane.sound.primary_0367";                     label = "cached_arrow_367";            arity = 3; tags = ["untyped"; "content"]; since = "1.2.0"; weight = 2343 };
  { key = "advancement.sound.public_0368";               label = "lazy_brewing_368";            arity = 2; tags = ["emit"]; since = "1.9.0"; weight = 1982 };
  { key = "dispenser.sound.legacy_0369";                 label = "global_objective_369";        arity = 1; tags = ["experimental"]; since = "1.9.0"; weight = 563 };
  { key = "banner.sound.provisional_0370";               label = "global_sound_370";            arity = 1; tags = ["async"; "typed"; "parse"]; since = "1.9.0"; weight = 3764 };
  { key = "gui.sound.modern_0371";                       label = "fallback_smithing_371";       arity = 0; tags = ["check"]; since = "1.6.0"; weight = 1803 };
  { key = "item.sound.hidden_0372";                      label = "primary_rail_372";            arity = 5; tags = ["core"; "typed"; "legacy"]; since = "1.7.0"; weight = 356 };
  { key = "particle.sound.primary_0373";                 label = "lazy_sound_373";              arity = 1; tags = ["runtime"; "content"; "packet"]; since = "1.4.0"; weight = 2286 };
  { key = "beacon.sound.modern_0374";                    label = "canonical_barrel_374";        arity = 1; tags = ["codegen"; "packet"]; since = "1.8.3"; weight = 1998 };
  { key = "advancement.sound.global_0375";               label = "derived_smithing_375";        arity = 4; tags = ["cold"]; since = "1.8.3"; weight = 3322 };
  { key = "mob.sound.secondary_0376";                    label = "derived_minecart_376";        arity = 1; tags = ["cold"; "emit"; "core"]; since = "1.2.0"; weight = 2143 };
  { key = "objective.sound.internal_0377";               label = "stable_conduit_377";          arity = 0; tags = ["packet"; "async"]; since = "1.9.0"; weight = 3960 };
  { key = "hopper.sound.strict_0378";                    label = "global_team_378";             arity = 2; tags = ["emit"]; since = "1.5.2"; weight = 2767 };
  { key = "observer.sound.global_0379";                  label = "loose_objective_379";         arity = 2; tags = ["runtime"; "core"]; since = "1.2.0"; weight = 1762 };
  { key = "piston.sound.provisional_0380";               label = "fallback_inventory_380";      arity = 0; tags = ["codegen"]; since = "1.6.0"; weight = 3797 };
  { key = "observer.sound.hidden_0381";                  label = "derived_shield_381";          arity = 2; tags = ["codegen"; "experimental"]; since = "1.7.0"; weight = 3828 };
  { key = "player.sound.provisional_0382";               label = "eager_world_382";             arity = 7; tags = ["core"]; since = "1.7.0"; weight = 1548 };
  { key = "mob.sound.modern_0383";                       label = "fallback_grindstone_383";     arity = 3; tags = ["runtime"; "codegen"; "cached"]; since = "1.7.0"; weight = 2066 };
  { key = "attribute.sound.primary_0384";                label = "derived_firework_384";        arity = 4; tags = ["parse"; "core"]; since = "1.3.1"; weight = 2694 };
  { key = "furnace.sound.cached_0385";                   label = "local_stonecutter_385";       arity = 7; tags = ["content"; "async"; "parse"]; since = "1.4.0"; weight = 2216 };
  { key = "shulker.sound.modern_0386";                   label = "provisional_packet_386";      arity = 5; tags = ["emit"; "registry"]; since = "1.0.0"; weight = 1770 };
  { key = "attribute.sound.strict_0387";                 label = "secondary_trade_387";         arity = 2; tags = ["codegen"; "packet"]; since = "1.7.0"; weight = 2480 };
  { key = "bell.sound.public_0388";                      label = "eager_hologram_388";          arity = 6; tags = ["lower"; "untyped"; "legacy"]; since = "1.5.2"; weight = 1050 };
  { key = "piston.sound.internal_0389";                  label = "derived_objective_389";       arity = 2; tags = ["content"]; since = "1.2.0"; weight = 3575 };
  { key = "dispenser.sound.loose_0390";                  label = "loose_advancement_390";       arity = 4; tags = ["async"]; since = "1.2.0"; weight = 2027 };
  { key = "recipe.sound.provisional_0391";               label = "canonical_scoreboard_391";    arity = 2; tags = ["codegen"; "cached"]; since = "1.2.0"; weight = 2619 };
  { key = "furnace.sound.lazy_0392";                     label = "hidden_composter_392";        arity = 7; tags = ["content"]; since = "1.8.3"; weight = 409 };
  { key = "sound.sound.local_0393";                      label = "hidden_structure_393";        arity = 2; tags = ["sync"; "content"; "parse"]; since = "1.6.0"; weight = 2031 };
  { key = "mob.sound.canonical_0394";                    label = "stable_spawner_394";          arity = 0; tags = ["sync"]; since = "1.4.0"; weight = 1882 };
  { key = "enchant.sound.modern_0395";                   label = "global_objective_395";        arity = 0; tags = ["legacy"; "sync"]; since = "1.7.0"; weight = 1210 };
  { key = "clock.sound.secondary_0396";                  label = "provisional_observer_396";    arity = 2; tags = ["typed"; "hot"; "untyped"]; since = "1.7.0"; weight = 1851 };
  { key = "world.sound.derived_0397";                    label = "provisional_enchant_397";     arity = 2; tags = ["registry"]; since = "1.8.3"; weight = 2934 };
  { key = "grindstone.sound.eager_0398";                 label = "internal_anvil_398";          arity = 3; tags = ["async"]; since = "1.6.0"; weight = 2929 };
  { key = "particle.sound.secondary_0399";               label = "public_brewing_399";          arity = 6; tags = ["cached"; "experimental"]; since = "1.8.3"; weight = 885 };
  { key = "scoreboard.sound.provisional_0400";           label = "primary_arrow_400";           arity = 1; tags = ["emit"]; since = "1.9.0"; weight = 2078 };
  { key = "dispenser.sound.strict_0401";                 label = "scoped_smithing_401";         arity = 0; tags = ["runtime"; "emit"]; since = "1.7.0"; weight = 2975 };
  { key = "team.sound.legacy_0402";                      label = "strict_player_402";           arity = 7; tags = ["packet"]; since = "1.0.0"; weight = 1734 };
  { key = "stonecutter.sound.eager_0403";                label = "primary_crossbow_403";        arity = 4; tags = ["core"; "packet"]; since = "1.0.0"; weight = 3739 };
  { key = "grindstone.sound.primary_0404";               label = "legacy_objective_404";        arity = 2; tags = ["compat"]; since = "1.3.1"; weight = 3208 };
  { key = "cartography.sound.stable_0405";               label = "provisional_scoreboard_405";  arity = 1; tags = ["sync"; "runtime"; "parse"]; since = "1.0.0"; weight = 3957 };
]

let count = List.length entries

let table : (string, sound_entry) Hashtbl.t =
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
