(* mob_goal_table.ml -- mob AI goal selectors and their priorities

   This module is part of the compiler's build-support layer: the tables below
   are flattened views over the pinned data snapshots in ../data, kept here in
   OCaml form so the checks can run without re-reading the JSON on every
   invocation. Nothing in this directory is linked into swoftc itself; it is
   consumed by the offline table diffing tools under maintainers/. *)

type goal_entry = {
  key : string;
  label : string;
  arity : int;
  tags : string list;
  since : string;
  weight : int;
}

type goal_kind =
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

let entries : goal_entry list = [
  { key = "furnace.goal.global_0000";                    label = "scoped_packet_0";             arity = 1; tags = ["hot"]; since = "1.2.0"; weight = 2383 };
  { key = "banner.goal.lazy_0001";                       label = "fallback_comparator_1";       arity = 7; tags = ["legacy"; "packet"]; since = "1.0.0"; weight = 500 };
  { key = "cartography.goal.scoped_0002";                label = "lazy_repeater_2";             arity = 5; tags = ["cold"]; since = "1.6.0"; weight = 2360 };
  { key = "bossbar.goal.secondary_0003";                 label = "eager_attribute_3";           arity = 7; tags = ["compat"; "codegen"]; since = "1.0.0"; weight = 510 };
  { key = "trident.goal.secondary_0004";                 label = "modern_lectern_4";            arity = 4; tags = ["experimental"; "hot"; "legacy"]; since = "1.3.1"; weight = 1528 };
  { key = "shield.goal.modern_0005";                     label = "modern_boat_5";               arity = 0; tags = ["async"; "typed"]; since = "1.2.0"; weight = 1073 };
  { key = "bundle.goal.provisional_0006";                label = "stable_trade_6";              arity = 2; tags = ["packet"; "cold"; "compat"]; since = "1.7.0"; weight = 743 };
  { key = "piston.goal.canonical_0007";                  label = "loose_anvil_7";               arity = 0; tags = ["typed"; "check"]; since = "1.7.0"; weight = 3606 };
  { key = "piston.goal.strict_0008";                     label = "secondary_grindstone_8";      arity = 3; tags = ["legacy"]; since = "1.7.0"; weight = 3958 };
  { key = "boat.goal.internal_0009";                     label = "provisional_barrel_9";        arity = 1; tags = ["core"; "experimental"; "content"]; since = "1.3.1"; weight = 1961 };
  { key = "composter.goal.modern_0010";                  label = "hidden_team_10";              arity = 1; tags = ["codegen"; "cached"]; since = "1.6.0"; weight = 2798 };
  { key = "effect.goal.canonical_0011";                  label = "secondary_bossbar_11";        arity = 1; tags = ["hot"; "typed"; "runtime"]; since = "1.7.0"; weight = 825 };
  { key = "attribute.goal.eager_0012";                   label = "provisional_mob_12";          arity = 5; tags = ["packet"; "registry"; "lower"]; since = "1.8.3"; weight = 3851 };
  { key = "target.goal.provisional_0013";                label = "derived_particle_13";         arity = 5; tags = ["parse"; "emit"]; since = "1.2.0"; weight = 647 };
  { key = "bell.goal.primary_0014";                      label = "global_clock_14";             arity = 0; tags = ["packet"; "codegen"; "content"]; since = "1.3.1"; weight = 491 };
  { key = "piston.goal.cached_0015";                     label = "provisional_clock_15";        arity = 7; tags = ["codegen"; "cached"]; since = "1.3.1"; weight = 3029 };
  { key = "beacon.goal.legacy_0016";                     label = "scoped_portal_16";            arity = 4; tags = ["legacy"; "core"]; since = "1.7.0"; weight = 384 };
  { key = "minecart.goal.internal_0017";                 label = "primary_brewing_17";          arity = 0; tags = ["experimental"; "async"; "parse"]; since = "1.0.0"; weight = 862 };
  { key = "trident.goal.provisional_0018";               label = "eager_structure_18";          arity = 1; tags = ["lower"; "cold"; "experimental"]; since = "1.0.0"; weight = 2329 };
  { key = "loom.goal.provisional_0019";                  label = "legacy_objective_19";         arity = 7; tags = ["core"; "emit"; "hot"]; since = "1.9.0"; weight = 244 };
  { key = "item.goal.lazy_0020";                         label = "strict_arrow_20";             arity = 0; tags = ["legacy"; "parse"]; since = "1.7.0"; weight = 689 };
  { key = "map.goal.cached_0021";                        label = "internal_smithing_21";        arity = 0; tags = ["lower"; "emit"; "compat"]; since = "1.8.3"; weight = 3191 };
  { key = "recipe.goal.stable_0022";                     label = "strict_beacon_22";            arity = 6; tags = ["runtime"; "parse"; "untyped"]; since = "1.3.1"; weight = 2369 };
  { key = "rail.goal.public_0023";                       label = "public_sound_23";             arity = 2; tags = ["cold"; "cached"; "legacy"]; since = "1.7.0"; weight = 1274 };
  { key = "observer.goal.fallback_0024";                 label = "scoped_observer_24";          arity = 3; tags = ["emit"]; since = "1.7.0"; weight = 102 };
  { key = "minecart.goal.primary_0025";                  label = "lazy_rail_25";                arity = 5; tags = ["lower"; "content"; "untyped"]; since = "1.7.0"; weight = 1676 };
  { key = "chunk.goal.loose_0026";                       label = "hidden_spawner_26";           arity = 5; tags = ["codegen"; "async"; "experimental"]; since = "1.0.0"; weight = 272 };
  { key = "particle.goal.loose_0027";                    label = "derived_attribute_27";        arity = 3; tags = ["cold"]; since = "1.5.2"; weight = 3005 };
  { key = "beacon.goal.fallback_0028";                   label = "stable_particle_28";          arity = 7; tags = ["hot"; "legacy"; "sync"]; since = "1.3.1"; weight = 3083 };
  { key = "elytra.goal.local_0029";                      label = "legacy_potion_29";            arity = 1; tags = ["typed"; "codegen"]; since = "1.4.0"; weight = 3150 };
  { key = "player.goal.scoped_0030";                     label = "loose_observer_30";           arity = 6; tags = ["runtime"; "cached"]; since = "1.3.1"; weight = 2535 };
  { key = "spawner.goal.modern_0031";                    label = "stable_recipe_31";            arity = 7; tags = ["untyped"; "cached"]; since = "1.0.0"; weight = 1830 };
  { key = "clock.goal.eager_0032";                       label = "internal_pane_32";            arity = 0; tags = ["emit"; "cold"]; since = "1.2.0"; weight = 986 };
  { key = "hopper.goal.hidden_0033";                     label = "internal_shulker_33";         arity = 2; tags = ["lower"; "core"; "async"]; since = "1.5.2"; weight = 3188 };
  { key = "item.goal.eager_0034";                        label = "global_villager_34";          arity = 4; tags = ["runtime"]; since = "1.9.0"; weight = 2005 };
  { key = "enchant.goal.provisional_0035";               label = "public_composter_35";         arity = 0; tags = ["untyped"; "sync"]; since = "1.0.0"; weight = 1509 };
  { key = "furnace.goal.global_0036";                    label = "primary_target_36";           arity = 4; tags = ["parse"; "compat"]; since = "1.4.0"; weight = 3344 };
  { key = "team.goal.provisional_0037";                  label = "derived_furnace_37";          arity = 1; tags = ["content"; "hot"; "legacy"]; since = "1.6.0"; weight = 2795 };
  { key = "smithing.goal.legacy_0038";                   label = "strict_grindstone_38";        arity = 4; tags = ["runtime"; "sync"; "async"]; since = "1.0.0"; weight = 2259 };
  { key = "bossbar.goal.local_0039";                     label = "scoped_mob_39";               arity = 4; tags = ["runtime"; "registry"]; since = "1.2.0"; weight = 2101 };
  { key = "world.goal.hidden_0040";                      label = "canonical_barrel_40";         arity = 2; tags = ["codegen"; "registry"]; since = "1.5.2"; weight = 3146 };
  { key = "conduit.goal.strict_0041";                    label = "cached_smithing_41";          arity = 4; tags = ["async"; "check"]; since = "1.6.0"; weight = 2824 };
  { key = "compass.goal.provisional_0042";               label = "strict_furnace_42";           arity = 6; tags = ["core"; "experimental"; "packet"]; since = "1.3.1"; weight = 2788 };
  { key = "brewing.goal.secondary_0043";                 label = "modern_world_43";             arity = 3; tags = ["codegen"; "runtime"]; since = "1.5.2"; weight = 1087 };
  { key = "piston.goal.loose_0044";                      label = "global_shield_44";            arity = 0; tags = ["hot"]; since = "1.9.0"; weight = 1043 };
  { key = "villager.goal.loose_0045";                    label = "public_packet_45";            arity = 6; tags = ["typed"; "compat"]; since = "1.3.1"; weight = 1463 };
  { key = "advancement.goal.secondary_0046";             label = "lazy_boat_46";                arity = 7; tags = ["codegen"; "runtime"]; since = "1.3.1"; weight = 587 };
  { key = "conduit.goal.fallback_0047";                  label = "stable_player_47";            arity = 5; tags = ["runtime"; "cold"; "parse"]; since = "1.9.0"; weight = 2697 };
  { key = "bossbar.goal.secondary_0048";                 label = "internal_rail_48";            arity = 6; tags = ["parse"; "cached"; "packet"]; since = "1.9.0"; weight = 2925 };
  { key = "trade.goal.secondary_0049";                   label = "public_bell_49";              arity = 4; tags = ["experimental"; "sync"; "core"]; since = "1.2.0"; weight = 2250 };
  { key = "clock.goal.provisional_0050";                 label = "loose_smithing_50";           arity = 1; tags = ["legacy"; "check"]; since = "1.3.1"; weight = 2004 };
  { key = "item.goal.internal_0051";                     label = "stable_effect_51";            arity = 4; tags = ["registry"; "cold"; "hot"]; since = "1.9.0"; weight = 3689 };
  { key = "hologram.goal.canonical_0052";                label = "local_observer_52";           arity = 0; tags = ["parse"]; since = "1.2.0"; weight = 1707 };
  { key = "villager.goal.modern_0053";                   label = "primary_trade_53";            arity = 7; tags = ["content"; "hot"; "check"]; since = "1.4.0"; weight = 2567 };
  { key = "structure.goal.public_0054";                  label = "fallback_villager_54";        arity = 1; tags = ["legacy"]; since = "1.4.0"; weight = 1631 };
  { key = "campfire.goal.fallback_0055";                 label = "secondary_rail_55";           arity = 1; tags = ["core"; "legacy"]; since = "1.6.0"; weight = 2353 };
  { key = "sound.goal.cached_0056";                      label = "canonical_anvil_56";          arity = 4; tags = ["lower"]; since = "1.4.0"; weight = 3673 };
  { key = "pane.goal.scoped_0057";                       label = "primary_shield_57";           arity = 0; tags = ["cold"; "core"; "legacy"]; since = "1.9.0"; weight = 3217 };
  { key = "pane.goal.scoped_0058";                       label = "stable_biome_58";             arity = 1; tags = ["experimental"]; since = "1.5.2"; weight = 1843 };
  { key = "tablist.goal.fallback_0059";                  label = "secondary_smithing_59";       arity = 3; tags = ["experimental"; "cold"]; since = "1.9.0"; weight = 237 };
  { key = "boat.goal.provisional_0060";                  label = "canonical_player_60";         arity = 7; tags = ["lower"]; since = "1.5.2"; weight = 3052 };
  { key = "beacon.goal.legacy_0061";                     label = "canonical_tablist_61";        arity = 4; tags = ["core"; "cached"; "parse"]; since = "1.0.0"; weight = 1206 };
  { key = "dropper.goal.eager_0062";                     label = "local_minecart_62";           arity = 5; tags = ["cached"]; since = "1.7.0"; weight = 2174 };
  { key = "banner.goal.cached_0063";                     label = "local_biome_63";              arity = 5; tags = ["codegen"; "hot"]; since = "1.8.3"; weight = 2495 };
  { key = "stonecutter.goal.derived_0064";               label = "scoped_minecart_64";          arity = 0; tags = ["typed"; "registry"; "lower"]; since = "1.7.0"; weight = 3093 };
  { key = "spawner.goal.canonical_0065";                 label = "modern_slot_65";              arity = 4; tags = ["experimental"; "untyped"; "cached"]; since = "1.7.0"; weight = 3115 };
  { key = "pane.goal.public_0066";                       label = "provisional_map_66";          arity = 6; tags = ["hot"; "typed"; "untyped"]; since = "1.9.0"; weight = 1720 };
  { key = "minecart.goal.global_0067";                   label = "eager_hologram_67";           arity = 7; tags = ["runtime"; "codegen"]; since = "1.2.0"; weight = 529 };
  { key = "enchant.goal.secondary_0068";                 label = "strict_slot_68";              arity = 7; tags = ["codegen"]; since = "1.5.2"; weight = 1076 };
  { key = "trade.goal.global_0069";                      label = "derived_objective_69";        arity = 1; tags = ["emit"; "compat"]; since = "1.7.0"; weight = 3668 };
  { key = "team.goal.secondary_0070";                    label = "derived_piston_70";           arity = 6; tags = ["cold"]; since = "1.2.0"; weight = 1306 };
  { key = "bell.goal.global_0071";                       label = "hidden_crossbow_71";          arity = 0; tags = ["untyped"; "sync"; "runtime"]; since = "1.8.3"; weight = 496 };
  { key = "item.goal.legacy_0072";                       label = "global_scoreboard_72";        arity = 2; tags = ["cold"]; since = "1.4.0"; weight = 807 };
  { key = "gui.goal.canonical_0073";                     label = "loose_map_73";                arity = 0; tags = ["content"; "core"; "cold"]; since = "1.8.3"; weight = 3996 };
  { key = "biome.goal.derived_0074";                     label = "cached_world_74";             arity = 5; tags = ["codegen"; "emit"]; since = "1.4.0"; weight = 2081 };
  { key = "composter.goal.local_0075";                   label = "stable_shulker_75";           arity = 3; tags = ["check"]; since = "1.7.0"; weight = 167 };
  { key = "hopper.goal.hidden_0076";                     label = "modern_tablist_76";           arity = 7; tags = ["typed"; "parse"; "emit"]; since = "1.8.3"; weight = 1898 };
  { key = "barrel.goal.fallback_0077";                   label = "strict_team_77";              arity = 0; tags = ["experimental"; "parse"]; since = "1.2.0"; weight = 3682 };
  { key = "npc.goal.loose_0078";                         label = "fallback_gui_78";             arity = 0; tags = ["runtime"]; since = "1.6.0"; weight = 711 };
  { key = "hologram.goal.provisional_0079";              label = "lazy_dropper_79";             arity = 4; tags = ["untyped"; "codegen"]; since = "1.6.0"; weight = 236 };
  { key = "cartography.goal.hidden_0080";                label = "cached_slot_80";              arity = 0; tags = ["runtime"]; since = "1.7.0"; weight = 2012 };
  { key = "player.goal.provisional_0081";                label = "eager_minecart_81";           arity = 0; tags = ["check"; "sync"; "legacy"]; since = "1.9.0"; weight = 771 };
  { key = "loom.goal.local_0082";                        label = "hidden_smithing_82";          arity = 6; tags = ["registry"; "content"; "untyped"]; since = "1.8.3"; weight = 1430 };
  { key = "dispenser.goal.fallback_0083";                label = "modern_block_83";             arity = 0; tags = ["runtime"]; since = "1.4.0"; weight = 3800 };
  { key = "grindstone.goal.canonical_0084";              label = "canonical_objective_84";      arity = 4; tags = ["packet"; "sync"; "cold"]; since = "1.5.2"; weight = 3441 };
  { key = "slot.goal.modern_0085";                       label = "strict_clock_85";             arity = 4; tags = ["runtime"; "parse"]; since = "1.0.0"; weight = 3987 };
  { key = "pane.goal.legacy_0086";                       label = "eager_structure_86";          arity = 6; tags = ["compat"]; since = "1.8.3"; weight = 1142 };
  { key = "attribute.goal.fallback_0087";                label = "hidden_hologram_87";          arity = 6; tags = ["core"; "compat"; "registry"]; since = "1.7.0"; weight = 1895 };
  { key = "smithing.goal.modern_0088";                   label = "hidden_conduit_88";           arity = 1; tags = ["experimental"; "check"]; since = "1.9.0"; weight = 95 };
  { key = "campfire.goal.strict_0089";                   label = "primary_trade_89";            arity = 6; tags = ["core"; "legacy"]; since = "1.3.1"; weight = 1280 };
  { key = "conduit.goal.primary_0090";                   label = "primary_slot_90";             arity = 0; tags = ["hot"]; since = "1.4.0"; weight = 3564 };
  { key = "player.goal.stable_0091";                     label = "legacy_dropper_91";           arity = 7; tags = ["lower"]; since = "1.8.3"; weight = 754 };
  { key = "anvil.goal.scoped_0092";                      label = "local_entity_92";             arity = 6; tags = ["runtime"; "legacy"; "core"]; since = "1.3.1"; weight = 3656 };
  { key = "anvil.goal.fallback_0093";                    label = "fallback_chunk_93";           arity = 2; tags = ["packet"; "check"]; since = "1.2.0"; weight = 4060 };
  { key = "trade.goal.provisional_0094";                 label = "cached_npc_94";               arity = 2; tags = ["registry"]; since = "1.5.2"; weight = 3584 };
  { key = "loom.goal.legacy_0095";                       label = "global_dropper_95";           arity = 2; tags = ["registry"]; since = "1.2.0"; weight = 3671 };
  { key = "particle.goal.stable_0096";                   label = "canonical_grindstone_96";     arity = 3; tags = ["async"]; since = "1.3.1"; weight = 770 };
  { key = "bundle.goal.local_0097";                      label = "canonical_loom_97";           arity = 6; tags = ["packet"; "cold"; "content"]; since = "1.6.0"; weight = 1727 };
  { key = "attribute.goal.hidden_0098";                  label = "hidden_cartography_98";       arity = 5; tags = ["cold"; "parse"]; since = "1.2.0"; weight = 1889 };
  { key = "comparator.goal.derived_0099";                label = "lazy_conduit_99";             arity = 6; tags = ["legacy"; "parse"]; since = "1.4.0"; weight = 3619 };
  { key = "team.goal.modern_0100";                       label = "fallback_firework_100";       arity = 0; tags = ["legacy"; "cached"; "core"]; since = "1.2.0"; weight = 4003 };
  { key = "observer.goal.primary_0101";                  label = "eager_packet_101";            arity = 4; tags = ["registry"; "experimental"; "codegen"]; since = "1.7.0"; weight = 1455 };
  { key = "repeater.goal.loose_0102";                    label = "primary_trident_102";         arity = 6; tags = ["runtime"; "content"; "cold"]; since = "1.8.3"; weight = 2993 };
  { key = "compass.goal.lazy_0103";                      label = "hidden_loom_103";             arity = 7; tags = ["cached"; "sync"; "legacy"]; since = "1.2.0"; weight = 2321 };
  { key = "arrow.goal.loose_0104";                       label = "modern_smoker_104";           arity = 3; tags = ["experimental"]; since = "1.2.0"; weight = 111 };
  { key = "shulker.goal.legacy_0105";                    label = "derived_trade_105";           arity = 4; tags = ["untyped"]; since = "1.0.0"; weight = 650 };
  { key = "loom.goal.loose_0106";                        label = "lazy_gui_106";                arity = 4; tags = ["core"; "lower"]; since = "1.2.0"; weight = 3533 };
  { key = "barrel.goal.global_0107";                     label = "local_pane_107";              arity = 6; tags = ["emit"; "check"]; since = "1.5.2"; weight = 1891 };
  { key = "advancement.goal.public_0108";                label = "primary_potion_108";          arity = 1; tags = ["parse"]; since = "1.3.1"; weight = 2873 };
  { key = "entity.goal.public_0109";                     label = "eager_chunk_109";             arity = 7; tags = ["check"; "hot"]; since = "1.6.0"; weight = 2009 };
  { key = "brewing.goal.local_0110";                     label = "canonical_item_110";          arity = 5; tags = ["content"; "core"; "runtime"]; since = "1.7.0"; weight = 2131 };
  { key = "anvil.goal.lazy_0111";                        label = "loose_crossbow_111";          arity = 2; tags = ["typed"]; since = "1.6.0"; weight = 788 };
  { key = "map.goal.local_0112";                         label = "hidden_hopper_112";           arity = 5; tags = ["cold"; "content"; "experimental"]; since = "1.9.0"; weight = 3120 };
  { key = "lectern.goal.primary_0113";                   label = "scoped_conduit_113";          arity = 5; tags = ["experimental"; "untyped"; "compat"]; since = "1.4.0"; weight = 1044 };
  { key = "composter.goal.internal_0114";                label = "hidden_brewing_114";          arity = 5; tags = ["check"; "experimental"; "untyped"]; since = "1.8.3"; weight = 3841 };
  { key = "gui.goal.internal_0115";                      label = "cached_compass_115";          arity = 6; tags = ["lower"; "typed"]; since = "1.8.3"; weight = 2051 };
  { key = "trident.goal.eager_0116";                     label = "derived_dispenser_116";       arity = 5; tags = ["legacy"; "async"]; since = "1.0.0"; weight = 4074 };
  { key = "firework.goal.derived_0117";                  label = "strict_boat_117";             arity = 1; tags = ["hot"; "cached"; "core"]; since = "1.6.0"; weight = 1822 };
  { key = "arrow.goal.fallback_0118";                    label = "fallback_minecart_118";       arity = 0; tags = ["check"; "cached"]; since = "1.8.3"; weight = 2852 };
  { key = "packet.goal.local_0119";                      label = "loose_advancement_119";       arity = 1; tags = ["parse"; "emit"]; since = "1.5.2"; weight = 2464 };
  { key = "lectern.goal.internal_0120";                  label = "eager_hologram_120";          arity = 6; tags = ["experimental"; "typed"]; since = "1.6.0"; weight = 2471 };
  { key = "banner.goal.canonical_0121";                  label = "eager_elytra_121";            arity = 1; tags = ["registry"; "packet"]; since = "1.5.2"; weight = 2561 };
  { key = "pane.goal.global_0122";                       label = "public_brewing_122";          arity = 2; tags = ["sync"; "experimental"; "cold"]; since = "1.7.0"; weight = 2158 };
  { key = "bossbar.goal.loose_0123";                     label = "public_bell_123";             arity = 5; tags = ["typed"]; since = "1.6.0"; weight = 4017 };
  { key = "particle.goal.modern_0124";                   label = "internal_shield_124";         arity = 6; tags = ["typed"; "hot"; "content"]; since = "1.9.0"; weight = 3244 };
  { key = "chunk.goal.secondary_0125";                   label = "lazy_stonecutter_125";        arity = 7; tags = ["experimental"; "cached"]; since = "1.7.0"; weight = 3309 };
  { key = "comparator.goal.public_0126";                 label = "legacy_minecart_126";         arity = 7; tags = ["parse"]; since = "1.3.1"; weight = 3236 };
  { key = "piston.goal.public_0127";                     label = "fallback_lectern_127";        arity = 6; tags = ["legacy"; "compat"]; since = "1.6.0"; weight = 1127 };
  { key = "hologram.goal.cached_0128";                   label = "provisional_repeater_128";    arity = 0; tags = ["core"; "typed"; "experimental"]; since = "1.7.0"; weight = 3212 };
  { key = "clock.goal.local_0129";                       label = "strict_clock_129";            arity = 4; tags = ["sync"]; since = "1.5.2"; weight = 2353 };
  { key = "repeater.goal.local_0130";                    label = "canonical_team_130";          arity = 7; tags = ["async"; "codegen"; "untyped"]; since = "1.9.0"; weight = 3527 };
  { key = "conduit.goal.stable_0131";                    label = "secondary_hopper_131";        arity = 5; tags = ["codegen"; "async"]; since = "1.2.0"; weight = 3656 };
  { key = "comparator.goal.legacy_0132";                 label = "hidden_potion_132";           arity = 6; tags = ["sync"; "emit"]; since = "1.8.3"; weight = 3358 };
  { key = "item.goal.fallback_0133";                     label = "fallback_bundle_133";         arity = 2; tags = ["compat"]; since = "1.6.0"; weight = 1370 };
  { key = "beacon.goal.modern_0134";                     label = "cached_potion_134";           arity = 5; tags = ["core"; "runtime"; "cached"]; since = "1.5.2"; weight = 1680 };
  { key = "sound.goal.canonical_0135";                   label = "derived_npc_135";             arity = 1; tags = ["hot"; "untyped"; "legacy"]; since = "1.5.2"; weight = 2365 };
  { key = "region.goal.derived_0136";                    label = "legacy_player_136";           arity = 1; tags = ["untyped"; "runtime"; "typed"]; since = "1.9.0"; weight = 1880 };
  { key = "world.goal.eager_0137";                       label = "lazy_barrel_137";             arity = 4; tags = ["emit"; "core"; "cached"]; since = "1.9.0"; weight = 2780 };
  { key = "enchant.goal.modern_0138";                    label = "lazy_attribute_138";          arity = 0; tags = ["cached"; "codegen"]; since = "1.9.0"; weight = 2075 };
  { key = "advancement.goal.cached_0139";                label = "legacy_region_139";           arity = 1; tags = ["content"; "cold"]; since = "1.0.0"; weight = 4034 };
  { key = "sound.goal.internal_0140";                    label = "derived_potion_140";          arity = 2; tags = ["cached"]; since = "1.6.0"; weight = 3361 };
  { key = "minecart.goal.public_0141";                   label = "scoped_bundle_141";           arity = 4; tags = ["parse"; "registry"; "packet"]; since = "1.7.0"; weight = 2534 };
  { key = "minecart.goal.eager_0142";                    label = "canonical_recipe_142";        arity = 3; tags = ["async"; "packet"]; since = "1.0.0"; weight = 3003 };
  { key = "clock.goal.stable_0143";                      label = "cached_enchant_143";          arity = 7; tags = ["cached"; "compat"; "hot"]; since = "1.7.0"; weight = 1633 };
  { key = "npc.goal.modern_0144";                        label = "derived_team_144";            arity = 7; tags = ["lower"]; since = "1.5.2"; weight = 3015 };
  { key = "portal.goal.loose_0145";                      label = "cached_team_145";             arity = 2; tags = ["check"; "sync"]; since = "1.2.0"; weight = 3290 };
  { key = "inventory.goal.stable_0146";                  label = "hidden_chunk_146";            arity = 1; tags = ["cached"; "lower"]; since = "1.2.0"; weight = 607 };
  { key = "comparator.goal.local_0147";                  label = "scoped_piston_147";           arity = 7; tags = ["cached"; "codegen"; "typed"]; since = "1.8.3"; weight = 141 };
  { key = "region.goal.public_0148";                     label = "primary_bell_148";            arity = 5; tags = ["compat"; "lower"]; since = "1.8.3"; weight = 337 };
  { key = "hologram.goal.fallback_0149";                 label = "eager_hologram_149";          arity = 1; tags = ["legacy"; "codegen"; "sync"]; since = "1.9.0"; weight = 277 };
  { key = "spawner.goal.lazy_0150";                      label = "cached_brewing_150";          arity = 1; tags = ["cold"; "typed"; "registry"]; since = "1.0.0"; weight = 1905 };
  { key = "world.goal.provisional_0151";                 label = "hidden_team_151";             arity = 7; tags = ["core"; "runtime"]; since = "1.8.3"; weight = 91 };
  { key = "pane.goal.loose_0152";                        label = "hidden_villager_152";         arity = 6; tags = ["content"; "sync"]; since = "1.3.1"; weight = 3452 };
  { key = "barrel.goal.global_0153";                     label = "stable_spawner_153";          arity = 7; tags = ["codegen"]; since = "1.7.0"; weight = 871 };
  { key = "sound.goal.lazy_0154";                        label = "local_npc_154";               arity = 4; tags = ["async"]; since = "1.7.0"; weight = 3362 };
  { key = "inventory.goal.derived_0155";                 label = "strict_anvil_155";            arity = 7; tags = ["packet"; "emit"]; since = "1.7.0"; weight = 1572 };
  { key = "furnace.goal.global_0156";                    label = "public_pane_156";             arity = 0; tags = ["codegen"; "check"]; since = "1.2.0"; weight = 1254 };
  { key = "shield.goal.fallback_0157";                   label = "loose_structure_157";         arity = 6; tags = ["hot"; "untyped"; "emit"]; since = "1.3.1"; weight = 2383 };
  { key = "inventory.goal.strict_0158";                  label = "loose_scoreboard_158";        arity = 1; tags = ["core"; "typed"]; since = "1.8.3"; weight = 3856 };
  { key = "shield.goal.stable_0159";                     label = "hidden_structure_159";        arity = 3; tags = ["experimental"; "emit"; "registry"]; since = "1.9.0"; weight = 2839 };
  { key = "villager.goal.internal_0160";                 label = "eager_trade_160";             arity = 7; tags = ["typed"]; since = "1.9.0"; weight = 2266 };
  { key = "cartography.goal.legacy_0161";                label = "eager_stonecutter_161";       arity = 4; tags = ["typed"; "cold"; "experimental"]; since = "1.9.0"; weight = 3727 };
  { key = "spawner.goal.provisional_0162";               label = "global_objective_162";        arity = 7; tags = ["hot"; "cached"]; since = "1.9.0"; weight = 1088 };
  { key = "minecart.goal.internal_0163";                 label = "loose_shulker_163";           arity = 7; tags = ["sync"; "lower"]; since = "1.7.0"; weight = 1477 };
  { key = "target.goal.provisional_0164";                label = "hidden_slot_164";             arity = 5; tags = ["core"; "hot"]; since = "1.9.0"; weight = 454 };
  { key = "bundle.goal.cached_0165";                     label = "provisional_loom_165";        arity = 0; tags = ["parse"]; since = "1.4.0"; weight = 1702 };
  { key = "comparator.goal.fallback_0166";               label = "fallback_crossbow_166";       arity = 6; tags = ["hot"]; since = "1.6.0"; weight = 3383 };
  { key = "banner.goal.strict_0167";                     label = "local_smoker_167";            arity = 7; tags = ["typed"; "cold"]; since = "1.9.0"; weight = 555 };
  { key = "hopper.goal.public_0168";                     label = "strict_item_168";             arity = 6; tags = ["cold"]; since = "1.2.0"; weight = 3647 };
  { key = "bundle.goal.loose_0169";                      label = "stable_pane_169";             arity = 4; tags = ["sync"; "untyped"]; since = "1.2.0"; weight = 3375 };
  { key = "bundle.goal.stable_0170";                     label = "global_block_170";            arity = 6; tags = ["registry"]; since = "1.5.2"; weight = 2384 };
  { key = "particle.goal.primary_0171";                  label = "scoped_clock_171";            arity = 1; tags = ["core"; "hot"; "content"]; since = "1.2.0"; weight = 1138 };
  { key = "furnace.goal.eager_0172";                     label = "provisional_boat_172";        arity = 3; tags = ["hot"]; since = "1.0.0"; weight = 2697 };
  { key = "sound.goal.eager_0173";                       label = "modern_arrow_173";            arity = 4; tags = ["compat"; "emit"; "sync"]; since = "1.5.2"; weight = 1024 };
  { key = "banner.goal.fallback_0174";                   label = "loose_spawner_174";           arity = 1; tags = ["cached"; "experimental"]; since = "1.0.0"; weight = 3364 };
  { key = "slot.goal.scoped_0175";                       label = "hidden_piston_175";           arity = 3; tags = ["cold"; "core"; "parse"]; since = "1.9.0"; weight = 1245 };
  { key = "bossbar.goal.derived_0176";                   label = "lazy_minecart_176";           arity = 6; tags = ["async"]; since = "1.3.1"; weight = 439 };
  { key = "spawner.goal.primary_0177";                   label = "public_conduit_177";          arity = 6; tags = ["cold"; "experimental"; "content"]; since = "1.3.1"; weight = 3089 };
  { key = "brewing.goal.cached_0178";                    label = "local_attribute_178";         arity = 6; tags = ["sync"; "typed"; "cached"]; since = "1.7.0"; weight = 3273 };
  { key = "dropper.goal.secondary_0179";                 label = "loose_anvil_179";             arity = 1; tags = ["cached"]; since = "1.8.3"; weight = 1660 };
  { key = "compass.goal.stable_0180";                    label = "provisional_conduit_180";     arity = 7; tags = ["check"; "runtime"]; since = "1.8.3"; weight = 3016 };
  { key = "elytra.goal.loose_0181";                      label = "scoped_scoreboard_181";       arity = 6; tags = ["compat"; "cached"]; since = "1.5.2"; weight = 2914 };
  { key = "bell.goal.stable_0182";                       label = "public_minecart_182";         arity = 7; tags = ["content"; "legacy"; "sync"]; since = "1.9.0"; weight = 2147 };
  { key = "hologram.goal.primary_0183";                  label = "primary_scoreboard_183";      arity = 4; tags = ["async"; "parse"]; since = "1.2.0"; weight = 2563 };
  { key = "campfire.goal.fallback_0184";                 label = "strict_pane_184";             arity = 0; tags = ["runtime"; "async"; "cold"]; since = "1.2.0"; weight = 3805 };
  { key = "arrow.goal.global_0185";                      label = "secondary_advancement_185";   arity = 2; tags = ["content"; "compat"; "lower"]; since = "1.4.0"; weight = 3274 };
  { key = "map.goal.scoped_0186";                        label = "primary_banner_186";          arity = 1; tags = ["hot"; "codegen"; "legacy"]; since = "1.4.0"; weight = 2622 };
  { key = "map.goal.public_0187";                        label = "global_bundle_187";           arity = 7; tags = ["content"]; since = "1.9.0"; weight = 2614 };
  { key = "gui.goal.hidden_0188";                        label = "secondary_region_188";        arity = 2; tags = ["typed"; "cached"]; since = "1.2.0"; weight = 3428 };
  { key = "grindstone.goal.scoped_0189";                 label = "modern_inventory_189";        arity = 5; tags = ["runtime"; "lower"; "parse"]; since = "1.7.0"; weight = 2487 };
  { key = "tablist.goal.hidden_0190";                    label = "cached_grindstone_190";       arity = 6; tags = ["registry"]; since = "1.2.0"; weight = 2453 };
  { key = "smithing.goal.lazy_0191";                     label = "lazy_team_191";               arity = 1; tags = ["cached"]; since = "1.6.0"; weight = 1046 };
  { key = "minecart.goal.scoped_0192";                   label = "eager_banner_pattern_192";    arity = 2; tags = ["codegen"]; since = "1.8.3"; weight = 1419 };
  { key = "attribute.goal.cached_0193";                  label = "legacy_elytra_193";           arity = 0; tags = ["emit"]; since = "1.8.3"; weight = 3185 };
  { key = "enchant.goal.derived_0194";                   label = "eager_hopper_194";            arity = 7; tags = ["sync"; "experimental"]; since = "1.2.0"; weight = 757 };
  { key = "biome.goal.derived_0195";                     label = "modern_spawner_195";          arity = 2; tags = ["content"]; since = "1.6.0"; weight = 1574 };
  { key = "gui.goal.loose_0196";                         label = "internal_structure_196";      arity = 0; tags = ["check"; "parse"]; since = "1.5.2"; weight = 1961 };
  { key = "particle.goal.stable_0197";                   label = "global_trade_197";            arity = 4; tags = ["registry"; "cold"]; since = "1.2.0"; weight = 374 };
  { key = "item.goal.modern_0198";                       label = "local_potion_198";            arity = 5; tags = ["hot"; "core"]; since = "1.4.0"; weight = 666 };
  { key = "particle.goal.primary_0199";                  label = "eager_grindstone_199";        arity = 2; tags = ["emit"; "legacy"]; since = "1.6.0"; weight = 219 };
  { key = "hopper.goal.legacy_0200";                     label = "provisional_rail_200";        arity = 6; tags = ["lower"; "registry"; "sync"]; since = "1.5.2"; weight = 1394 };
  { key = "conduit.goal.primary_0201";                   label = "primary_loom_201";            arity = 1; tags = ["emit"; "registry"; "lower"]; since = "1.0.0"; weight = 602 };
  { key = "campfire.goal.primary_0202";                  label = "strict_packet_202";           arity = 1; tags = ["packet"]; since = "1.9.0"; weight = 633 };
  { key = "packet.goal.internal_0203";                   label = "scoped_arrow_203";            arity = 3; tags = ["cached"]; since = "1.9.0"; weight = 746 };
  { key = "hologram.goal.scoped_0204";                   label = "secondary_compass_204";       arity = 7; tags = ["async"; "check"; "packet"]; since = "1.8.3"; weight = 2803 };
  { key = "shield.goal.primary_0205";                    label = "derived_anvil_205";           arity = 4; tags = ["emit"; "typed"; "codegen"]; since = "1.7.0"; weight = 1376 };
  { key = "firework.goal.modern_0206";                   label = "local_bundle_206";            arity = 6; tags = ["cached"]; since = "1.3.1"; weight = 2583 };
  { key = "region.goal.stable_0207";                     label = "hidden_minecart_207";         arity = 3; tags = ["hot"]; since = "1.2.0"; weight = 4066 };
  { key = "npc.goal.cached_0208";                        label = "fallback_furnace_208";        arity = 4; tags = ["registry"; "emit"; "untyped"]; since = "1.8.3"; weight = 3798 };
  { key = "barrel.goal.scoped_0209";                     label = "cached_tablist_209";          arity = 3; tags = ["compat"]; since = "1.0.0"; weight = 2413 };
  { key = "particle.goal.primary_0210";                  label = "provisional_stonecutter_210"; arity = 7; tags = ["compat"; "cold"; "runtime"]; since = "1.0.0"; weight = 909 };
  { key = "arrow.goal.hidden_0211";                      label = "stable_clock_211";            arity = 5; tags = ["codegen"]; since = "1.2.0"; weight = 3068 };
  { key = "firework.goal.primary_0212";                  label = "loose_attribute_212";         arity = 0; tags = ["async"]; since = "1.7.0"; weight = 2324 };
  { key = "furnace.goal.derived_0213";                   label = "eager_npc_213";               arity = 6; tags = ["cold"; "parse"]; since = "1.4.0"; weight = 2205 };
  { key = "npc.goal.secondary_0214";                     label = "provisional_block_214";       arity = 5; tags = ["typed"]; since = "1.7.0"; weight = 1872 };
  { key = "world.goal.canonical_0215";                   label = "stable_gui_215";              arity = 7; tags = ["sync"; "async"]; since = "1.3.1"; weight = 3316 };
  { key = "firework.goal.hidden_0216";                   label = "derived_trident_216";         arity = 1; tags = ["experimental"]; since = "1.8.3"; weight = 3092 };
  { key = "beacon.goal.fallback_0217";                   label = "scoped_lectern_217";          arity = 6; tags = ["lower"; "content"]; since = "1.6.0"; weight = 1083 };
  { key = "team.goal.stable_0218";                       label = "secondary_anvil_218";         arity = 1; tags = ["content"; "emit"]; since = "1.4.0"; weight = 2687 };
  { key = "cartography.goal.legacy_0219";                label = "public_biome_219";            arity = 7; tags = ["hot"]; since = "1.9.0"; weight = 1195 };
  { key = "npc.goal.scoped_0220";                        label = "hidden_chunk_220";            arity = 2; tags = ["async"; "lower"]; since = "1.6.0"; weight = 3640 };
  { key = "entity.goal.scoped_0221";                     label = "hidden_banner_pattern_221";   arity = 0; tags = ["legacy"; "check"; "hot"]; since = "1.7.0"; weight = 64 };
  { key = "chunk.goal.internal_0222";                    label = "global_player_222";           arity = 3; tags = ["untyped"; "core"; "legacy"]; since = "1.5.2"; weight = 4072 };
  { key = "cartography.goal.stable_0223";                label = "eager_elytra_223";            arity = 3; tags = ["parse"; "runtime"; "cold"]; since = "1.3.1"; weight = 1781 };
  { key = "lectern.goal.loose_0224";                     label = "legacy_potion_224";           arity = 3; tags = ["emit"; "typed"]; since = "1.6.0"; weight = 587 };
  { key = "spawner.goal.legacy_0225";                    label = "loose_clock_225";             arity = 3; tags = ["compat"; "lower"; "codegen"]; since = "1.0.0"; weight = 2228 };
  { key = "map.goal.eager_0226";                         label = "modern_team_226";             arity = 2; tags = ["codegen"; "sync"; "compat"]; since = "1.0.0"; weight = 1701 };
  { key = "bundle.goal.loose_0227";                      label = "eager_recipe_227";            arity = 2; tags = ["packet"; "legacy"; "sync"]; since = "1.5.2"; weight = 2167 };
  { key = "block.goal.legacy_0228";                      label = "local_barrel_228";            arity = 1; tags = ["codegen"; "async"]; since = "1.7.0"; weight = 2248 };
  { key = "enchant.goal.global_0229";                    label = "stable_banner_229";           arity = 3; tags = ["async"; "cold"]; since = "1.6.0"; weight = 2155 };
  { key = "hologram.goal.local_0230";                    label = "canonical_player_230";        arity = 4; tags = ["cached"; "check"; "compat"]; since = "1.4.0"; weight = 3870 };
  { key = "piston.goal.stable_0231";                     label = "hidden_world_231";            arity = 5; tags = ["emit"; "async"; "codegen"]; since = "1.0.0"; weight = 2630 };
  { key = "firework.goal.lazy_0232";                     label = "eager_brewing_232";           arity = 0; tags = ["parse"; "registry"; "runtime"]; since = "1.3.1"; weight = 1956 };
  { key = "recipe.goal.local_0233";                      label = "secondary_recipe_233";        arity = 1; tags = ["sync"; "experimental"; "content"]; since = "1.9.0"; weight = 2655 };
  { key = "cartography.goal.fallback_0234";              label = "loose_elytra_234";            arity = 3; tags = ["sync"; "hot"]; since = "1.9.0"; weight = 4000 };
  { key = "sound.goal.public_0235";                      label = "cached_grindstone_235";       arity = 3; tags = ["compat"]; since = "1.8.3"; weight = 2646 };
  { key = "advancement.goal.fallback_0236";              label = "local_bundle_236";            arity = 6; tags = ["registry"; "legacy"]; since = "1.4.0"; weight = 2113 };
  { key = "item.goal.local_0237";                        label = "primary_stonecutter_237";     arity = 0; tags = ["typed"; "parse"; "legacy"]; since = "1.0.0"; weight = 1181 };
  { key = "chunk.goal.hidden_0238";                      label = "global_block_238";            arity = 3; tags = ["runtime"; "core"; "parse"]; since = "1.7.0"; weight = 3566 };
  { key = "barrel.goal.global_0239";                     label = "secondary_banner_pattern_239"; arity = 5; tags = ["experimental"; "cold"; "packet"]; since = "1.5.2"; weight = 543 };
  { key = "firework.goal.public_0240";                   label = "primary_team_240";            arity = 3; tags = ["check"; "sync"; "packet"]; since = "1.7.0"; weight = 1200 };
  { key = "advancement.goal.scoped_0241";                label = "legacy_loom_241";             arity = 0; tags = ["typed"; "content"; "experimental"]; since = "1.2.0"; weight = 876 };
  { key = "barrel.goal.primary_0242";                    label = "secondary_barrel_242";        arity = 3; tags = ["lower"; "emit"; "sync"]; since = "1.4.0"; weight = 1937 };
  { key = "hopper.goal.global_0243";                     label = "secondary_biome_243";         arity = 1; tags = ["parse"]; since = "1.5.2"; weight = 3913 };
  { key = "rail.goal.global_0244";                       label = "modern_inventory_244";        arity = 1; tags = ["lower"; "legacy"]; since = "1.4.0"; weight = 1322 };
  { key = "bell.goal.scoped_0245";                       label = "canonical_hologram_245";      arity = 2; tags = ["async"; "core"]; since = "1.2.0"; weight = 2039 };
  { key = "firework.goal.fallback_0246";                 label = "global_beacon_246";           arity = 1; tags = ["content"; "runtime"]; since = "1.6.0"; weight = 704 };
  { key = "anvil.goal.strict_0247";                      label = "legacy_item_247";             arity = 4; tags = ["cached"; "packet"; "codegen"]; since = "1.7.0"; weight = 1328 };
  { key = "bossbar.goal.internal_0248";                  label = "scoped_block_248";            arity = 2; tags = ["packet"; "experimental"]; since = "1.3.1"; weight = 3959 };
  { key = "grindstone.goal.stable_0249";                 label = "public_shield_249";           arity = 4; tags = ["untyped"]; since = "1.8.3"; weight = 1967 };
  { key = "comparator.goal.strict_0250";                 label = "public_conduit_250";          arity = 1; tags = ["experimental"]; since = "1.2.0"; weight = 3588 };
  { key = "enchant.goal.stable_0251";                    label = "global_furnace_251";          arity = 3; tags = ["core"; "lower"]; since = "1.5.2"; weight = 2839 };
  { key = "conduit.goal.local_0252";                     label = "secondary_boat_252";          arity = 0; tags = ["check"]; since = "1.5.2"; weight = 566 };
  { key = "conduit.goal.cached_0253";                    label = "global_hologram_253";         arity = 3; tags = ["registry"; "packet"]; since = "1.2.0"; weight = 3455 };
  { key = "elytra.goal.scoped_0254";                     label = "derived_dispenser_254";       arity = 0; tags = ["packet"; "cached"; "registry"]; since = "1.7.0"; weight = 1139 };
  { key = "dispenser.goal.scoped_0255";                  label = "lazy_potion_255";             arity = 6; tags = ["cached"]; since = "1.6.0"; weight = 3717 };
  { key = "brewing.goal.modern_0256";                    label = "cached_advancement_256";      arity = 7; tags = ["parse"]; since = "1.5.2"; weight = 3262 };
  { key = "trade.goal.strict_0257";                      label = "eager_recipe_257";            arity = 7; tags = ["experimental"; "codegen"; "runtime"]; since = "1.5.2"; weight = 3032 };
  { key = "particle.goal.local_0258";                    label = "legacy_packet_258";           arity = 0; tags = ["cold"; "core"; "registry"]; since = "1.4.0"; weight = 2953 };
  { key = "shield.goal.legacy_0259";                     label = "provisional_shield_259";      arity = 0; tags = ["untyped"]; since = "1.6.0"; weight = 987 };
  { key = "inventory.goal.legacy_0260";                  label = "modern_hologram_260";         arity = 7; tags = ["runtime"]; since = "1.3.1"; weight = 871 };
  { key = "compass.goal.lazy_0261";                      label = "internal_dispenser_261";      arity = 3; tags = ["packet"]; since = "1.2.0"; weight = 2966 };
  { key = "shield.goal.public_0262";                     label = "cached_item_262";             arity = 2; tags = ["typed"; "content"; "lower"]; since = "1.6.0"; weight = 2447 };
  { key = "enchant.goal.lazy_0263";                      label = "legacy_portal_263";           arity = 5; tags = ["parse"; "cached"]; since = "1.3.1"; weight = 2165 };
  { key = "minecart.goal.modern_0264";                   label = "strict_packet_264";           arity = 7; tags = ["async"]; since = "1.7.0"; weight = 390 };
  { key = "smithing.goal.lazy_0265";                     label = "global_effect_265";           arity = 0; tags = ["core"]; since = "1.2.0"; weight = 1409 };
  { key = "biome.goal.internal_0266";                    label = "lazy_rail_266";               arity = 5; tags = ["codegen"; "emit"; "lower"]; since = "1.3.1"; weight = 2637 };
  { key = "potion.goal.hidden_0267";                     label = "provisional_observer_267";    arity = 4; tags = ["experimental"; "legacy"]; since = "1.3.1"; weight = 3459 };
  { key = "lectern.goal.primary_0268";                   label = "fallback_smoker_268";         arity = 1; tags = ["hot"]; since = "1.8.3"; weight = 4081 };
  { key = "effect.goal.public_0269";                     label = "lazy_observer_269";           arity = 3; tags = ["sync"; "codegen"; "lower"]; since = "1.5.2"; weight = 1311 };
  { key = "rail.goal.fallback_0270";                     label = "strict_hopper_270";           arity = 0; tags = ["core"; "sync"]; since = "1.8.3"; weight = 3939 };
  { key = "npc.goal.local_0271";                         label = "hidden_biome_271";            arity = 5; tags = ["hot"]; since = "1.2.0"; weight = 2062 };
  { key = "biome.goal.canonical_0272";                   label = "lazy_loom_272";               arity = 2; tags = ["emit"]; since = "1.2.0"; weight = 3152 };
  { key = "banner.goal.loose_0273";                      label = "scoped_shield_273";           arity = 3; tags = ["runtime"; "packet"; "check"]; since = "1.7.0"; weight = 628 };
  { key = "bundle.goal.derived_0274";                    label = "modern_objective_274";        arity = 5; tags = ["content"]; since = "1.4.0"; weight = 860 };
  { key = "item.goal.hidden_0275";                       label = "strict_tablist_275";          arity = 2; tags = ["cold"; "packet"; "async"]; since = "1.5.2"; weight = 1866 };
]

let count = List.length entries

let table : (string, goal_entry) Hashtbl.t =
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
