(* command_node_table.ml -- brigadier command node argument kinds

   This module is part of the compiler's build-support layer: the tables below
   are flattened views over the pinned data snapshots in ../data, kept here in
   OCaml form so the checks can run without re-reading the JSON on every
   invocation. Nothing in this directory is linked into swoftc itself; it is
   consumed by the offline table diffing tools under maintainers/. *)

type node_entry = {
  key : string;
  label : string;
  arity : int;
  tags : string list;
  since : string;
  weight : int;
}

type node_kind =
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

let entries : node_entry list = [
  { key = "comparator.node.eager_0000";                  label = "scoped_lectern_0";            arity = 5; tags = ["runtime"; "lower"]; since = "1.6.0"; weight = 3192 };
  { key = "loom.node.scoped_0001";                       label = "local_dispenser_1";           arity = 6; tags = ["untyped"]; since = "1.2.0"; weight = 500 };
  { key = "portal.node.hidden_0002";                     label = "scoped_minecart_2";           arity = 5; tags = ["check"]; since = "1.7.0"; weight = 1894 };
  { key = "banner_pattern.node.stable_0003";             label = "legacy_effect_3";             arity = 5; tags = ["legacy"; "runtime"; "typed"]; since = "1.0.0"; weight = 3367 };
  { key = "repeater.node.cached_0004";                   label = "cached_effect_4";             arity = 1; tags = ["core"]; since = "1.6.0"; weight = 159 };
  { key = "packet.node.lazy_0005";                       label = "loose_rail_5";                arity = 4; tags = ["cold"; "sync"; "lower"]; since = "1.3.1"; weight = 2699 };
  { key = "piston.node.primary_0006";                    label = "global_enchant_6";            arity = 3; tags = ["legacy"; "parse"; "compat"]; since = "1.2.0"; weight = 2685 };
  { key = "anvil.node.cached_0007";                      label = "loose_scoreboard_7";          arity = 1; tags = ["experimental"; "registry"]; since = "1.9.0"; weight = 2541 };
  { key = "conduit.node.lazy_0008";                      label = "local_hopper_8";              arity = 4; tags = ["cold"; "packet"]; since = "1.0.0"; weight = 1728 };
  { key = "clock.node.scoped_0009";                      label = "legacy_conduit_9";            arity = 2; tags = ["packet"; "sync"; "codegen"]; since = "1.5.2"; weight = 3658 };
  { key = "furnace.node.cached_0010";                    label = "global_objective_10";         arity = 6; tags = ["check"; "experimental"; "legacy"]; since = "1.2.0"; weight = 2514 };
  { key = "target.node.strict_0011";                     label = "lazy_bossbar_11";             arity = 3; tags = ["typed"; "runtime"]; since = "1.2.0"; weight = 3162 };
  { key = "clock.node.local_0012";                       label = "hidden_brewing_12";           arity = 6; tags = ["core"; "parse"; "check"]; since = "1.4.0"; weight = 75 };
  { key = "dropper.node.canonical_0013";                 label = "fallback_villager_13";        arity = 7; tags = ["codegen"; "cold"]; since = "1.0.0"; weight = 495 };
  { key = "villager.node.local_0014";                    label = "hidden_shield_14";            arity = 0; tags = ["async"]; since = "1.0.0"; weight = 2719 };
  { key = "compass.node.loose_0015";                     label = "canonical_smoker_15";         arity = 2; tags = ["registry"; "parse"; "content"]; since = "1.5.2"; weight = 2237 };
  { key = "packet.node.scoped_0016";                     label = "stable_compass_16";           arity = 4; tags = ["cached"; "compat"; "sync"]; since = "1.8.3"; weight = 2887 };
  { key = "elytra.node.fallback_0017";                   label = "modern_sound_17";             arity = 2; tags = ["runtime"; "sync"]; since = "1.0.0"; weight = 685 };
  { key = "lectern.node.public_0018";                    label = "modern_trident_18";           arity = 7; tags = ["lower"; "untyped"]; since = "1.0.0"; weight = 341 };
  { key = "minecart.node.primary_0019";                  label = "legacy_team_19";              arity = 0; tags = ["untyped"]; since = "1.0.0"; weight = 3111 };
  { key = "clock.node.secondary_0020";                   label = "provisional_anvil_20";        arity = 3; tags = ["parse"; "check"]; since = "1.6.0"; weight = 3248 };
  { key = "gui.node.canonical_0021";                     label = "modern_chunk_21";             arity = 0; tags = ["experimental"; "registry"]; since = "1.3.1"; weight = 3000 };
  { key = "target.node.fallback_0022";                   label = "modern_player_22";            arity = 7; tags = ["packet"; "core"; "codegen"]; since = "1.6.0"; weight = 2952 };
  { key = "dispenser.node.loose_0023";                   label = "global_brewing_23";           arity = 2; tags = ["core"]; since = "1.0.0"; weight = 2542 };
  { key = "piston.node.internal_0024";                   label = "primary_trade_24";            arity = 6; tags = ["compat"]; since = "1.6.0"; weight = 338 };
  { key = "shulker.node.stable_0025";                    label = "hidden_portal_25";            arity = 5; tags = ["compat"; "lower"; "hot"]; since = "1.3.1"; weight = 3278 };
  { key = "shulker.node.secondary_0026";                 label = "stable_barrel_26";            arity = 3; tags = ["packet"]; since = "1.3.1"; weight = 3289 };
  { key = "shield.node.global_0027";                     label = "hidden_firework_27";          arity = 2; tags = ["typed"; "runtime"; "hot"]; since = "1.4.0"; weight = 3588 };
  { key = "packet.node.public_0028";                     label = "hidden_arrow_28";             arity = 4; tags = ["untyped"; "cold"; "emit"]; since = "1.3.1"; weight = 2336 };
  { key = "smithing.node.eager_0029";                    label = "hidden_map_29";               arity = 4; tags = ["cold"]; since = "1.7.0"; weight = 2076 };
  { key = "hopper.node.public_0030";                     label = "lazy_comparator_30";          arity = 4; tags = ["compat"; "async"]; since = "1.8.3"; weight = 1717 };
  { key = "objective.node.canonical_0031";               label = "lazy_region_31";              arity = 2; tags = ["experimental"]; since = "1.3.1"; weight = 3274 };
  { key = "comparator.node.loose_0032";                  label = "strict_bossbar_32";           arity = 3; tags = ["packet"; "compat"]; since = "1.5.2"; weight = 3189 };
  { key = "furnace.node.cached_0033";                    label = "lazy_repeater_33";            arity = 1; tags = ["typed"; "codegen"]; since = "1.6.0"; weight = 1703 };
  { key = "trade.node.legacy_0034";                      label = "global_inventory_34";         arity = 2; tags = ["codegen"]; since = "1.8.3"; weight = 3602 };
  { key = "smithing.node.modern_0035";                   label = "scoped_shield_35";            arity = 0; tags = ["codegen"]; since = "1.8.3"; weight = 1480 };
  { key = "lectern.node.hidden_0036";                    label = "secondary_campfire_36";       arity = 5; tags = ["core"; "sync"]; since = "1.5.2"; weight = 1893 };
  { key = "world.node.public_0037";                      label = "scoped_comparator_37";        arity = 2; tags = ["untyped"; "typed"; "compat"]; since = "1.9.0"; weight = 2019 };
  { key = "rail.node.cached_0038";                       label = "derived_clock_38";            arity = 6; tags = ["untyped"]; since = "1.9.0"; weight = 3535 };
  { key = "objective.node.lazy_0039";                    label = "scoped_pane_39";              arity = 4; tags = ["experimental"]; since = "1.9.0"; weight = 2397 };
  { key = "arrow.node.legacy_0040";                      label = "lazy_sound_40";               arity = 3; tags = ["typed"; "hot"; "cached"]; since = "1.2.0"; weight = 2576 };
  { key = "pane.node.stable_0041";                       label = "provisional_boat_41";         arity = 6; tags = ["experimental"]; since = "1.0.0"; weight = 587 };
  { key = "elytra.node.lazy_0042";                       label = "hidden_anvil_42";             arity = 3; tags = ["experimental"; "check"]; since = "1.6.0"; weight = 1306 };
  { key = "bell.node.secondary_0043";                    label = "provisional_gui_43";          arity = 3; tags = ["compat"; "lower"]; since = "1.3.1"; weight = 2716 };
  { key = "potion.node.global_0044";                     label = "global_shield_44";            arity = 4; tags = ["core"]; since = "1.4.0"; weight = 3348 };
  { key = "clock.node.cached_0045";                      label = "strict_particle_45";          arity = 2; tags = ["emit"; "async"; "registry"]; since = "1.3.1"; weight = 1815 };
  { key = "smoker.node.modern_0046";                     label = "fallback_shulker_46";         arity = 6; tags = ["parse"]; since = "1.4.0"; weight = 2055 };
  { key = "target.node.fallback_0047";                   label = "primary_arrow_47";            arity = 1; tags = ["packet"]; since = "1.6.0"; weight = 3175 };
  { key = "structure.node.local_0048";                   label = "legacy_smoker_48";            arity = 1; tags = ["async"]; since = "1.5.2"; weight = 544 };
  { key = "elytra.node.legacy_0049";                     label = "provisional_anvil_49";        arity = 7; tags = ["lower"; "codegen"]; since = "1.0.0"; weight = 1882 };
  { key = "mob.node.canonical_0050";                     label = "strict_shulker_50";           arity = 0; tags = ["legacy"]; since = "1.3.1"; weight = 895 };
  { key = "inventory.node.primary_0051";                 label = "primary_hopper_51";           arity = 7; tags = ["compat"]; since = "1.3.1"; weight = 1095 };
  { key = "barrel.node.lazy_0052";                       label = "local_elytra_52";             arity = 2; tags = ["emit"; "content"]; since = "1.4.0"; weight = 2379 };
  { key = "recipe.node.legacy_0053";                     label = "internal_particle_53";        arity = 7; tags = ["packet"]; since = "1.4.0"; weight = 3338 };
  { key = "barrel.node.scoped_0054";                     label = "scoped_npc_54";               arity = 2; tags = ["compat"]; since = "1.0.0"; weight = 2174 };
  { key = "objective.node.internal_0055";                label = "global_piston_55";            arity = 7; tags = ["check"; "parse"; "hot"]; since = "1.8.3"; weight = 2115 };
  { key = "firework.node.legacy_0056";                   label = "primary_bossbar_56";          arity = 6; tags = ["hot"]; since = "1.5.2"; weight = 993 };
  { key = "bell.node.primary_0057";                      label = "lazy_minecart_57";            arity = 7; tags = ["registry"; "experimental"; "runtime"]; since = "1.7.0"; weight = 3071 };
  { key = "gui.node.stable_0058";                        label = "strict_mob_58";               arity = 2; tags = ["emit"]; since = "1.4.0"; weight = 3121 };
  { key = "firework.node.provisional_0059";              label = "global_biome_59";             arity = 3; tags = ["cached"; "async"]; since = "1.5.2"; weight = 3823 };
  { key = "observer.node.legacy_0060";                   label = "global_hopper_60";            arity = 6; tags = ["experimental"; "cold"]; since = "1.2.0"; weight = 374 };
  { key = "rail.node.eager_0061";                        label = "lazy_repeater_61";            arity = 6; tags = ["typed"; "codegen"; "registry"]; since = "1.7.0"; weight = 703 };
  { key = "beacon.node.primary_0062";                    label = "provisional_inventory_62";    arity = 1; tags = ["registry"]; since = "1.7.0"; weight = 3090 };
  { key = "loom.node.lazy_0063";                         label = "loose_bell_63";               arity = 7; tags = ["hot"; "runtime"]; since = "1.7.0"; weight = 3360 };
  { key = "entity.node.strict_0064";                     label = "loose_rail_64";               arity = 2; tags = ["core"; "compat"]; since = "1.0.0"; weight = 1585 };
  { key = "hopper.node.scoped_0065";                     label = "hidden_trade_65";             arity = 5; tags = ["parse"]; since = "1.7.0"; weight = 1944 };
  { key = "pane.node.modern_0066";                       label = "cached_clock_66";             arity = 7; tags = ["runtime"; "legacy"]; since = "1.6.0"; weight = 975 };
  { key = "dropper.node.scoped_0067";                    label = "eager_smithing_67";           arity = 0; tags = ["parse"; "lower"]; since = "1.7.0"; weight = 3673 };
  { key = "inventory.node.global_0068";                  label = "eager_stonecutter_68";        arity = 6; tags = ["typed"]; since = "1.5.2"; weight = 4095 };
  { key = "effect.node.global_0069";                     label = "local_arrow_69";              arity = 4; tags = ["cached"; "compat"; "registry"]; since = "1.0.0"; weight = 346 };
  { key = "shield.node.local_0070";                      label = "derived_structure_70";        arity = 1; tags = ["async"; "experimental"]; since = "1.6.0"; weight = 3102 };
  { key = "chunk.node.fallback_0071";                    label = "derived_loom_71";             arity = 5; tags = ["content"]; since = "1.5.2"; weight = 1747 };
  { key = "advancement.node.fallback_0072";              label = "eager_beacon_72";             arity = 5; tags = ["compat"; "cached"; "codegen"]; since = "1.3.1"; weight = 1756 };
  { key = "trade.node.lazy_0073";                        label = "modern_comparator_73";        arity = 4; tags = ["cold"; "async"; "parse"]; since = "1.0.0"; weight = 1968 };
  { key = "clock.node.cached_0074";                      label = "primary_particle_74";         arity = 6; tags = ["runtime"; "packet"]; since = "1.2.0"; weight = 315 };
  { key = "conduit.node.derived_0075";                   label = "fallback_slot_75";            arity = 0; tags = ["packet"]; since = "1.2.0"; weight = 141 };
  { key = "sound.node.scoped_0076";                      label = "eager_recipe_76";             arity = 2; tags = ["sync"; "experimental"]; since = "1.5.2"; weight = 239 };
  { key = "npc.node.global_0077";                        label = "scoped_potion_77";            arity = 1; tags = ["cold"; "registry"; "typed"]; since = "1.3.1"; weight = 258 };
  { key = "barrel.node.lazy_0078";                       label = "canonical_cartography_78";    arity = 7; tags = ["typed"; "cold"]; since = "1.9.0"; weight = 518 };
  { key = "packet.node.scoped_0079";                     label = "primary_portal_79";           arity = 5; tags = ["check"; "sync"]; since = "1.7.0"; weight = 3923 };
  { key = "map.node.lazy_0080";                          label = "public_target_80";            arity = 4; tags = ["parse"; "packet"; "runtime"]; since = "1.6.0"; weight = 1879 };
  { key = "slot.node.scoped_0081";                       label = "cached_repeater_81";          arity = 5; tags = ["hot"]; since = "1.3.1"; weight = 1251 };
  { key = "tablist.node.local_0082";                     label = "eager_villager_82";           arity = 0; tags = ["async"; "registry"; "lower"]; since = "1.3.1"; weight = 938 };
  { key = "map.node.provisional_0083";                   label = "global_entity_83";            arity = 7; tags = ["untyped"; "emit"; "cold"]; since = "1.4.0"; weight = 1262 };
  { key = "piston.node.fallback_0084";                   label = "internal_chunk_84";           arity = 2; tags = ["legacy"; "codegen"]; since = "1.2.0"; weight = 495 };
  { key = "entity.node.provisional_0085";                label = "lazy_shulker_85";             arity = 2; tags = ["untyped"; "registry"]; since = "1.5.2"; weight = 1162 };
  { key = "inventory.node.cached_0086";                  label = "internal_particle_86";        arity = 7; tags = ["codegen"; "hot"]; since = "1.0.0"; weight = 1823 };
  { key = "world.node.primary_0087";                     label = "scoped_shulker_87";           arity = 7; tags = ["async"; "cold"; "sync"]; since = "1.9.0"; weight = 215 };
  { key = "banner.node.public_0088";                     label = "hidden_stonecutter_88";       arity = 6; tags = ["hot"; "cold"]; since = "1.2.0"; weight = 3975 };
  { key = "trade.node.loose_0089";                       label = "secondary_conduit_89";        arity = 1; tags = ["check"; "packet"; "lower"]; since = "1.4.0"; weight = 1621 };
  { key = "stonecutter.node.derived_0090";               label = "derived_mob_90";              arity = 4; tags = ["typed"]; since = "1.9.0"; weight = 89 };
  { key = "spawner.node.primary_0091";                   label = "modern_advancement_91";       arity = 4; tags = ["core"; "typed"; "packet"]; since = "1.0.0"; weight = 426 };
  { key = "beacon.node.strict_0092";                     label = "scoped_smithing_92";          arity = 2; tags = ["check"; "codegen"]; since = "1.8.3"; weight = 3799 };
  { key = "particle.node.fallback_0093";                 label = "fallback_biome_93";           arity = 6; tags = ["async"; "codegen"; "experimental"]; since = "1.6.0"; weight = 2491 };
  { key = "npc.node.internal_0094";                      label = "legacy_hopper_94";            arity = 4; tags = ["cold"; "untyped"; "experimental"]; since = "1.7.0"; weight = 3654 };
  { key = "effect.node.strict_0095";                     label = "internal_objective_95";       arity = 2; tags = ["codegen"]; since = "1.7.0"; weight = 3579 };
  { key = "repeater.node.primary_0096";                  label = "fallback_chunk_96";           arity = 2; tags = ["registry"; "legacy"; "compat"]; since = "1.8.3"; weight = 378 };
  { key = "team.node.secondary_0097";                    label = "global_rail_97";              arity = 1; tags = ["codegen"; "legacy"]; since = "1.3.1"; weight = 530 };
  { key = "portal.node.provisional_0098";                label = "lazy_boat_98";                arity = 1; tags = ["sync"; "experimental"]; since = "1.3.1"; weight = 569 };
  { key = "smithing.node.stable_0099";                   label = "derived_grindstone_99";       arity = 5; tags = ["hot"]; since = "1.2.0"; weight = 2484 };
  { key = "region.node.canonical_0100";                  label = "legacy_entity_100";           arity = 5; tags = ["compat"; "lower"]; since = "1.3.1"; weight = 3080 };
  { key = "banner_pattern.node.modern_0101";             label = "provisional_conduit_101";     arity = 5; tags = ["check"]; since = "1.3.1"; weight = 2763 };
  { key = "dropper.node.fallback_0102";                  label = "canonical_firework_102";      arity = 0; tags = ["codegen"]; since = "1.3.1"; weight = 2553 };
  { key = "lectern.node.global_0103";                    label = "global_loom_103";             arity = 7; tags = ["emit"; "check"; "compat"]; since = "1.0.0"; weight = 3823 };
  { key = "repeater.node.modern_0104";                   label = "internal_brewing_104";        arity = 3; tags = ["untyped"; "compat"; "emit"]; since = "1.6.0"; weight = 2782 };
  { key = "scoreboard.node.global_0105";                 label = "legacy_piston_105";           arity = 5; tags = ["codegen"]; since = "1.4.0"; weight = 2311 };
  { key = "attribute.node.legacy_0106";                  label = "provisional_anvil_106";       arity = 6; tags = ["async"; "check"; "compat"]; since = "1.5.2"; weight = 3220 };
  { key = "trident.node.strict_0107";                    label = "scoped_target_107";           arity = 6; tags = ["cached"]; since = "1.2.0"; weight = 2305 };
  { key = "elytra.node.scoped_0108";                     label = "hidden_map_108";              arity = 5; tags = ["hot"]; since = "1.5.2"; weight = 2087 };
  { key = "arrow.node.local_0109";                       label = "lazy_pane_109";               arity = 4; tags = ["content"; "cold"]; since = "1.8.3"; weight = 3650 };
  { key = "minecart.node.derived_0110";                  label = "internal_compass_110";        arity = 1; tags = ["emit"]; since = "1.6.0"; weight = 4080 };
  { key = "item.node.secondary_0111";                    label = "secondary_enchant_111";       arity = 4; tags = ["typed"]; since = "1.2.0"; weight = 3112 };
  { key = "repeater.node.canonical_0112";                label = "hidden_lectern_112";          arity = 4; tags = ["runtime"; "check"; "cold"]; since = "1.4.0"; weight = 714 };
  { key = "region.node.lazy_0113";                       label = "secondary_hologram_113";      arity = 1; tags = ["packet"; "cached"; "parse"]; since = "1.0.0"; weight = 3038 };
  { key = "pane.node.legacy_0114";                       label = "strict_elytra_114";           arity = 3; tags = ["cached"]; since = "1.4.0"; weight = 3593 };
  { key = "lectern.node.primary_0115";                   label = "lazy_mob_115";                arity = 2; tags = ["cold"; "packet"]; since = "1.8.3"; weight = 1989 };
  { key = "enchant.node.stable_0116";                    label = "cached_banner_116";           arity = 2; tags = ["packet"; "hot"; "typed"]; since = "1.6.0"; weight = 1465 };
  { key = "objective.node.hidden_0117";                  label = "global_bossbar_117";          arity = 7; tags = ["typed"; "parse"]; since = "1.5.2"; weight = 2939 };
  { key = "repeater.node.primary_0118";                  label = "eager_player_118";            arity = 0; tags = ["cold"]; since = "1.4.0"; weight = 1155 };
  { key = "advancement.node.hidden_0119";                label = "internal_shulker_119";        arity = 5; tags = ["async"; "sync"]; since = "1.3.1"; weight = 2434 };
  { key = "scoreboard.node.global_0120";                 label = "scoped_hologram_120";         arity = 3; tags = ["content"; "parse"; "compat"]; since = "1.9.0"; weight = 539 };
  { key = "objective.node.hidden_0121";                  label = "local_mob_121";               arity = 3; tags = ["async"]; since = "1.9.0"; weight = 2846 };
  { key = "arrow.node.primary_0122";                     label = "hidden_gui_122";              arity = 1; tags = ["cached"; "typed"]; since = "1.2.0"; weight = 1869 };
  { key = "brewing.node.secondary_0123";                 label = "cached_dispenser_123";        arity = 3; tags = ["legacy"]; since = "1.5.2"; weight = 774 };
  { key = "objective.node.provisional_0124";             label = "loose_arrow_124";             arity = 4; tags = ["cached"; "typed"; "experimental"]; since = "1.6.0"; weight = 1502 };
  { key = "item.node.hidden_0125";                       label = "lazy_furnace_125";            arity = 3; tags = ["emit"; "experimental"]; since = "1.4.0"; weight = 483 };
  { key = "firework.node.provisional_0126";              label = "canonical_hologram_126";      arity = 5; tags = ["runtime"; "hot"; "typed"]; since = "1.2.0"; weight = 1706 };
  { key = "mob.node.loose_0127";                         label = "primary_minecart_127";        arity = 4; tags = ["async"; "parse"; "packet"]; since = "1.3.1"; weight = 406 };
  { key = "minecart.node.legacy_0128";                   label = "fallback_rail_128";           arity = 1; tags = ["parse"; "codegen"; "cold"]; since = "1.4.0"; weight = 951 };
  { key = "slot.node.derived_0129";                      label = "strict_cartography_129";      arity = 6; tags = ["async"; "emit"; "check"]; since = "1.8.3"; weight = 2682 };
  { key = "potion.node.global_0130";                     label = "modern_shield_130";           arity = 1; tags = ["legacy"; "registry"; "cold"]; since = "1.8.3"; weight = 819 };
  { key = "mob.node.cached_0131";                        label = "public_chunk_131";            arity = 2; tags = ["experimental"; "runtime"; "compat"]; since = "1.6.0"; weight = 723 };
  { key = "region.node.local_0132";                      label = "eager_shulker_132";           arity = 6; tags = ["lower"; "experimental"]; since = "1.7.0"; weight = 248 };
  { key = "conduit.node.strict_0133";                    label = "fallback_region_133";         arity = 5; tags = ["hot"]; since = "1.2.0"; weight = 296 };
  { key = "effect.node.loose_0134";                      label = "legacy_target_134";           arity = 6; tags = ["compat"; "check"]; since = "1.9.0"; weight = 3760 };
  { key = "stonecutter.node.scoped_0135";                label = "stable_smoker_135";           arity = 4; tags = ["async"; "sync"]; since = "1.2.0"; weight = 3603 };
  { key = "player.node.primary_0136";                    label = "stable_anvil_136";            arity = 7; tags = ["check"; "typed"; "experimental"]; since = "1.2.0"; weight = 1569 };
  { key = "crossbow.node.loose_0137";                    label = "secondary_region_137";        arity = 4; tags = ["cached"; "typed"]; since = "1.9.0"; weight = 1378 };
  { key = "world.node.provisional_0138";                 label = "global_tablist_138";          arity = 7; tags = ["sync"; "codegen"]; since = "1.0.0"; weight = 3279 };
  { key = "rail.node.legacy_0139";                       label = "legacy_anvil_139";            arity = 7; tags = ["async"; "cold"]; since = "1.8.3"; weight = 2856 };
  { key = "smoker.node.modern_0140";                     label = "public_composter_140";        arity = 3; tags = ["hot"; "core"; "typed"]; since = "1.6.0"; weight = 1599 };
  { key = "repeater.node.eager_0141";                    label = "derived_beacon_141";          arity = 2; tags = ["compat"; "registry"; "packet"]; since = "1.0.0"; weight = 2689 };
  { key = "target.node.public_0142";                     label = "modern_attribute_142";        arity = 4; tags = ["hot"]; since = "1.3.1"; weight = 2224 };
  { key = "shulker.node.canonical_0143";                 label = "lazy_crossbow_143";           arity = 0; tags = ["experimental"; "cold"]; since = "1.2.0"; weight = 499 };
  { key = "rail.node.provisional_0144";                  label = "stable_enchant_144";          arity = 7; tags = ["compat"; "typed"; "codegen"]; since = "1.2.0"; weight = 3762 };
  { key = "enchant.node.cached_0145";                    label = "lazy_shulker_145";            arity = 5; tags = ["typed"]; since = "1.6.0"; weight = 590 };
  { key = "barrel.node.cached_0146";                     label = "loose_spawner_146";           arity = 3; tags = ["cached"]; since = "1.0.0"; weight = 558 };
  { key = "barrel.node.strict_0147";                     label = "hidden_mob_147";              arity = 1; tags = ["cached"; "runtime"; "compat"]; since = "1.0.0"; weight = 3306 };
  { key = "gui.node.internal_0148";                      label = "internal_sound_148";          arity = 2; tags = ["parse"; "hot"; "cached"]; since = "1.8.3"; weight = 145 };
  { key = "bell.node.public_0149";                       label = "scoped_map_149";              arity = 6; tags = ["sync"; "compat"; "content"]; since = "1.5.2"; weight = 2057 };
  { key = "smithing.node.hidden_0150";                   label = "public_bell_150";             arity = 4; tags = ["parse"; "lower"; "check"]; since = "1.9.0"; weight = 302 };
  { key = "hologram.node.legacy_0151";                   label = "lazy_hopper_151";             arity = 4; tags = ["parse"]; since = "1.6.0"; weight = 3488 };
  { key = "shulker.node.eager_0152";                     label = "modern_loom_152";             arity = 4; tags = ["cold"]; since = "1.2.0"; weight = 370 };
  { key = "structure.node.global_0153";                  label = "stable_chunk_153";            arity = 1; tags = ["emit"]; since = "1.3.1"; weight = 1982 };
  { key = "anvil.node.scoped_0154";                      label = "modern_map_154";              arity = 5; tags = ["experimental"]; since = "1.4.0"; weight = 2480 };
  { key = "scoreboard.node.strict_0155";                 label = "canonical_barrel_155";        arity = 1; tags = ["typed"]; since = "1.8.3"; weight = 2442 };
  { key = "shulker.node.lazy_0156";                      label = "scoped_piston_156";           arity = 2; tags = ["codegen"; "packet"]; since = "1.2.0"; weight = 1671 };
  { key = "gui.node.internal_0157";                      label = "stable_observer_157";         arity = 5; tags = ["parse"]; since = "1.4.0"; weight = 3339 };
  { key = "shulker.node.cached_0158";                    label = "loose_team_158";              arity = 7; tags = ["cold"; "content"]; since = "1.2.0"; weight = 1700 };
  { key = "slot.node.stable_0159";                       label = "stable_smoker_159";           arity = 6; tags = ["check"; "lower"; "emit"]; since = "1.9.0"; weight = 2130 };
  { key = "target.node.public_0160";                     label = "eager_team_160";              arity = 4; tags = ["cold"; "untyped"; "packet"]; since = "1.9.0"; weight = 425 };
  { key = "furnace.node.public_0161";                    label = "internal_elytra_161";         arity = 4; tags = ["emit"; "content"; "parse"]; since = "1.7.0"; weight = 3606 };
  { key = "beacon.node.fallback_0162";                   label = "scoped_slot_162";             arity = 4; tags = ["typed"; "parse"; "cold"]; since = "1.0.0"; weight = 3474 };
  { key = "pane.node.loose_0163";                        label = "secondary_conduit_163";       arity = 6; tags = ["content"]; since = "1.7.0"; weight = 2262 };
  { key = "beacon.node.local_0164";                      label = "strict_region_164";           arity = 6; tags = ["parse"; "compat"]; since = "1.3.1"; weight = 3686 };
  { key = "dropper.node.eager_0165";                     label = "provisional_grindstone_165";  arity = 3; tags = ["typed"]; since = "1.5.2"; weight = 2130 };
  { key = "npc.node.scoped_0166";                        label = "secondary_advancement_166";   arity = 2; tags = ["codegen"; "emit"]; since = "1.5.2"; weight = 95 };
  { key = "packet.node.fallback_0167";                   label = "provisional_tablist_167";     arity = 1; tags = ["experimental"; "cold"; "lower"]; since = "1.8.3"; weight = 2204 };
  { key = "attribute.node.primary_0168";                 label = "legacy_inventory_168";        arity = 6; tags = ["core"; "legacy"]; since = "1.9.0"; weight = 2742 };
  { key = "item.node.provisional_0169";                  label = "modern_team_169";             arity = 0; tags = ["lower"; "legacy"; "packet"]; since = "1.2.0"; weight = 422 };
  { key = "furnace.node.lazy_0170";                      label = "public_smithing_170";         arity = 5; tags = ["typed"; "legacy"; "compat"]; since = "1.5.2"; weight = 283 };
  { key = "block.node.derived_0171";                     label = "derived_item_171";            arity = 4; tags = ["legacy"; "content"; "lower"]; since = "1.8.3"; weight = 2495 };
  { key = "spawner.node.secondary_0172";                 label = "eager_bossbar_172";           arity = 4; tags = ["legacy"; "untyped"; "core"]; since = "1.7.0"; weight = 1762 };
  { key = "world.node.strict_0173";                      label = "primary_pane_173";            arity = 7; tags = ["async"; "sync"]; since = "1.9.0"; weight = 1185 };
  { key = "crossbow.node.derived_0174";                  label = "primary_mob_174";             arity = 5; tags = ["packet"]; since = "1.6.0"; weight = 622 };
  { key = "campfire.node.local_0175";                    label = "primary_bell_175";            arity = 7; tags = ["registry"; "hot"; "content"]; since = "1.3.1"; weight = 3860 };
  { key = "inventory.node.provisional_0176";             label = "lazy_piston_176";             arity = 0; tags = ["parse"; "runtime"]; since = "1.4.0"; weight = 3591 };
  { key = "slot.node.lazy_0177";                         label = "strict_brewing_177";          arity = 0; tags = ["runtime"]; since = "1.9.0"; weight = 3981 };
  { key = "shulker.node.scoped_0178";                    label = "legacy_banner_178";           arity = 5; tags = ["compat"]; since = "1.5.2"; weight = 6 };
  { key = "particle.node.eager_0179";                    label = "scoped_hologram_179";         arity = 3; tags = ["legacy"; "cached"]; since = "1.5.2"; weight = 969 };
  { key = "conduit.node.lazy_0180";                      label = "primary_brewing_180";         arity = 7; tags = ["parse"]; since = "1.0.0"; weight = 3397 };
  { key = "cartography.node.secondary_0181";             label = "secondary_team_181";          arity = 7; tags = ["cached"]; since = "1.0.0"; weight = 3022 };
  { key = "banner_pattern.node.provisional_0182";        label = "provisional_comparator_182";  arity = 0; tags = ["core"; "runtime"; "async"]; since = "1.6.0"; weight = 2717 };
  { key = "particle.node.derived_0183";                  label = "cached_cartography_183";      arity = 7; tags = ["hot"; "cold"; "sync"]; since = "1.0.0"; weight = 415 };
  { key = "recipe.node.derived_0184";                    label = "public_boat_184";             arity = 7; tags = ["codegen"; "untyped"]; since = "1.7.0"; weight = 3461 };
  { key = "elytra.node.primary_0185";                    label = "legacy_map_185";              arity = 4; tags = ["core"; "registry"]; since = "1.3.1"; weight = 643 };
  { key = "dropper.node.canonical_0186";                 label = "cached_arrow_186";            arity = 5; tags = ["registry"; "async"; "codegen"]; since = "1.6.0"; weight = 689 };
  { key = "cartography.node.lazy_0187";                  label = "internal_comparator_187";     arity = 6; tags = ["sync"; "content"; "legacy"]; since = "1.3.1"; weight = 3070 };
  { key = "bundle.node.internal_0188";                   label = "primary_target_188";          arity = 6; tags = ["core"; "packet"; "codegen"]; since = "1.5.2"; weight = 2083 };
  { key = "composter.node.primary_0189";                 label = "lazy_clock_189";              arity = 0; tags = ["packet"; "experimental"; "codegen"]; since = "1.9.0"; weight = 1951 };
  { key = "banner.node.strict_0190";                     label = "strict_npc_190";              arity = 4; tags = ["cold"; "untyped"; "core"]; since = "1.8.3"; weight = 554 };
  { key = "dropper.node.global_0191";                    label = "stable_anvil_191";            arity = 4; tags = ["registry"; "content"]; since = "1.0.0"; weight = 2006 };
  { key = "objective.node.strict_0192";                  label = "stable_banner_pattern_192";   arity = 7; tags = ["parse"; "runtime"; "typed"]; since = "1.4.0"; weight = 1680 };
  { key = "gui.node.global_0193";                        label = "primary_trade_193";           arity = 0; tags = ["emit"]; since = "1.6.0"; weight = 3680 };
  { key = "grindstone.node.secondary_0194";              label = "lazy_piston_194";             arity = 0; tags = ["hot"]; since = "1.4.0"; weight = 2821 };
  { key = "map.node.global_0195";                        label = "fallback_mob_195";            arity = 5; tags = ["codegen"; "typed"; "emit"]; since = "1.8.3"; weight = 2427 };
  { key = "firework.node.eager_0196";                    label = "internal_bundle_196";         arity = 0; tags = ["typed"; "untyped"; "content"]; since = "1.5.2"; weight = 668 };
  { key = "boat.node.scoped_0197";                       label = "secondary_firework_197";      arity = 0; tags = ["parse"; "packet"]; since = "1.3.1"; weight = 1065 };
  { key = "potion.node.provisional_0198";                label = "canonical_banner_198";        arity = 3; tags = ["lower"]; since = "1.3.1"; weight = 3497 };
  { key = "chunk.node.primary_0199";                     label = "hidden_banner_pattern_199";   arity = 2; tags = ["runtime"; "experimental"; "hot"]; since = "1.2.0"; weight = 458 };
  { key = "player.node.cached_0200";                     label = "cached_clock_200";            arity = 6; tags = ["experimental"; "runtime"]; since = "1.3.1"; weight = 2536 };
  { key = "clock.node.lazy_0201";                        label = "internal_sound_201";          arity = 2; tags = ["typed"]; since = "1.8.3"; weight = 1753 };
  { key = "bundle.node.loose_0202";                      label = "eager_item_202";              arity = 6; tags = ["packet"; "typed"; "async"]; since = "1.2.0"; weight = 3128 };
  { key = "banner_pattern.node.eager_0203";              label = "cached_grindstone_203";       arity = 7; tags = ["cached"]; since = "1.8.3"; weight = 120 };
  { key = "minecart.node.stable_0204";                   label = "scoped_boat_204";             arity = 5; tags = ["check"]; since = "1.9.0"; weight = 3702 };
  { key = "player.node.eager_0205";                      label = "strict_dropper_205";          arity = 1; tags = ["legacy"]; since = "1.8.3"; weight = 2244 };
  { key = "smoker.node.hidden_0206";                     label = "canonical_bell_206";          arity = 2; tags = ["untyped"; "emit"]; since = "1.7.0"; weight = 3005 };
  { key = "comparator.node.legacy_0207";                 label = "secondary_player_207";        arity = 6; tags = ["check"; "legacy"]; since = "1.2.0"; weight = 617 };
  { key = "recipe.node.public_0208";                     label = "derived_inventory_208";       arity = 1; tags = ["registry"; "runtime"; "async"]; since = "1.5.2"; weight = 3317 };
  { key = "mob.node.modern_0209";                        label = "modern_rail_209";             arity = 1; tags = ["core"; "check"]; since = "1.8.3"; weight = 645 };
  { key = "enchant.node.provisional_0210";               label = "legacy_barrel_210";           arity = 1; tags = ["registry"]; since = "1.7.0"; weight = 1084 };
  { key = "bossbar.node.modern_0211";                    label = "cached_spawner_211";          arity = 4; tags = ["packet"; "legacy"; "registry"]; since = "1.4.0"; weight = 2369 };
  { key = "piston.node.internal_0212";                   label = "local_compass_212";           arity = 7; tags = ["packet"]; since = "1.4.0"; weight = 3225 };
  { key = "comparator.node.eager_0213";                  label = "global_clock_213";            arity = 5; tags = ["untyped"; "registry"; "runtime"]; since = "1.4.0"; weight = 2501 };
  { key = "dropper.node.hidden_0214";                    label = "modern_stonecutter_214";      arity = 1; tags = ["hot"; "untyped"; "experimental"]; since = "1.7.0"; weight = 333 };
  { key = "compass.node.internal_0215";                  label = "global_dropper_215";          arity = 7; tags = ["cached"; "check"; "legacy"]; since = "1.2.0"; weight = 2888 };
  { key = "comparator.node.local_0216";                  label = "provisional_entity_216";      arity = 0; tags = ["lower"; "async"]; since = "1.4.0"; weight = 1766 };
  { key = "tablist.node.public_0217";                    label = "lazy_region_217";             arity = 3; tags = ["hot"; "cached"]; since = "1.6.0"; weight = 576 };
  { key = "comparator.node.provisional_0218";            label = "global_compass_218";          arity = 6; tags = ["parse"; "experimental"]; since = "1.3.1"; weight = 1109 };
  { key = "recipe.node.loose_0219";                      label = "legacy_shulker_219";          arity = 5; tags = ["cached"]; since = "1.4.0"; weight = 2801 };
  { key = "compass.node.scoped_0220";                    label = "derived_objective_220";       arity = 7; tags = ["hot"; "packet"]; since = "1.4.0"; weight = 3326 };
  { key = "team.node.provisional_0221";                  label = "lazy_effect_221";             arity = 6; tags = ["async"; "core"; "cached"]; since = "1.9.0"; weight = 3213 };
  { key = "scoreboard.node.modern_0222";                 label = "strict_inventory_222";        arity = 6; tags = ["untyped"]; since = "1.8.3"; weight = 470 };
  { key = "piston.node.cached_0223";                     label = "secondary_packet_223";        arity = 3; tags = ["parse"; "registry"; "runtime"]; since = "1.6.0"; weight = 1636 };
  { key = "attribute.node.derived_0224";                 label = "hidden_chunk_224";            arity = 4; tags = ["packet"]; since = "1.3.1"; weight = 2764 };
  { key = "grindstone.node.primary_0225";                label = "loose_banner_225";            arity = 5; tags = ["codegen"; "parse"; "packet"]; since = "1.5.2"; weight = 3188 };
  { key = "mob.node.scoped_0226";                        label = "legacy_dispenser_226";        arity = 1; tags = ["codegen"; "packet"]; since = "1.4.0"; weight = 1720 };
  { key = "dropper.node.scoped_0227";                    label = "strict_barrel_227";           arity = 0; tags = ["legacy"; "hot"]; since = "1.2.0"; weight = 3185 };
  { key = "chunk.node.modern_0228";                      label = "hidden_barrel_228";           arity = 5; tags = ["untyped"]; since = "1.3.1"; weight = 2110 };
  { key = "gui.node.stable_0229";                        label = "global_scoreboard_229";       arity = 7; tags = ["cold"; "experimental"; "check"]; since = "1.9.0"; weight = 3799 };
  { key = "barrel.node.modern_0230";                     label = "public_dropper_230";          arity = 5; tags = ["packet"; "codegen"; "untyped"]; since = "1.0.0"; weight = 1750 };
  { key = "shield.node.public_0231";                     label = "global_elytra_231";           arity = 3; tags = ["lower"]; since = "1.4.0"; weight = 1759 };
  { key = "furnace.node.canonical_0232";                 label = "strict_bundle_232";           arity = 0; tags = ["untyped"; "content"]; since = "1.7.0"; weight = 4038 };
  { key = "advancement.node.secondary_0233";             label = "legacy_smithing_233";         arity = 0; tags = ["emit"]; since = "1.5.2"; weight = 2750 };
  { key = "dropper.node.lazy_0234";                      label = "loose_block_234";             arity = 2; tags = ["core"]; since = "1.9.0"; weight = 2986 };
  { key = "banner_pattern.node.global_0235";             label = "eager_banner_pattern_235";    arity = 2; tags = ["async"; "cached"; "untyped"]; since = "1.9.0"; weight = 3755 };
  { key = "sound.node.eager_0236";                       label = "strict_trident_236";          arity = 0; tags = ["sync"; "cached"]; since = "1.4.0"; weight = 87 };
  { key = "arrow.node.global_0237";                      label = "modern_gui_237";              arity = 1; tags = ["experimental"; "runtime"; "emit"]; since = "1.4.0"; weight = 3618 };
  { key = "potion.node.secondary_0238";                  label = "cached_map_238";              arity = 6; tags = ["content"; "check"; "cached"]; since = "1.2.0"; weight = 894 };
  { key = "block.node.modern_0239";                      label = "lazy_tablist_239";            arity = 7; tags = ["untyped"; "packet"; "codegen"]; since = "1.0.0"; weight = 1439 };
  { key = "entity.node.cached_0240";                     label = "fallback_trade_240";          arity = 2; tags = ["lower"]; since = "1.5.2"; weight = 2564 };
  { key = "block.node.hidden_0241";                      label = "eager_firework_241";          arity = 0; tags = ["typed"]; since = "1.7.0"; weight = 250 };
  { key = "banner.node.canonical_0242";                  label = "fallback_arrow_242";          arity = 7; tags = ["typed"; "experimental"]; since = "1.2.0"; weight = 3491 };
  { key = "region.node.canonical_0243";                  label = "loose_tablist_243";           arity = 0; tags = ["check"; "core"]; since = "1.8.3"; weight = 3249 };
  { key = "tablist.node.cached_0244";                    label = "fallback_packet_244";         arity = 7; tags = ["core"]; since = "1.0.0"; weight = 2042 };
  { key = "scoreboard.node.global_0245";                 label = "legacy_potion_245";           arity = 3; tags = ["legacy"]; since = "1.6.0"; weight = 1470 };
  { key = "sound.node.stable_0246";                      label = "local_target_246";            arity = 2; tags = ["registry"; "content"; "legacy"]; since = "1.9.0"; weight = 29 };
  { key = "repeater.node.scoped_0247";                   label = "canonical_smithing_247";      arity = 7; tags = ["compat"]; since = "1.6.0"; weight = 1796 };
  { key = "potion.node.public_0248";                     label = "stable_potion_248";           arity = 2; tags = ["runtime"; "cached"]; since = "1.9.0"; weight = 3541 };
  { key = "team.node.secondary_0249";                    label = "fallback_inventory_249";      arity = 4; tags = ["runtime"; "content"; "experimental"]; since = "1.8.3"; weight = 3383 };
  { key = "advancement.node.fallback_0250";              label = "fallback_dispenser_250";      arity = 6; tags = ["async"]; since = "1.8.3"; weight = 704 };
  { key = "comparator.node.local_0251";                  label = "canonical_shulker_251";       arity = 5; tags = ["hot"; "registry"]; since = "1.0.0"; weight = 3808 };
  { key = "item.node.stable_0252";                       label = "public_arrow_252";            arity = 2; tags = ["codegen"; "parse"]; since = "1.6.0"; weight = 341 };
  { key = "recipe.node.public_0253";                     label = "cached_advancement_253";      arity = 0; tags = ["parse"; "typed"; "lower"]; since = "1.4.0"; weight = 2493 };
  { key = "hologram.node.provisional_0254";              label = "local_villager_254";          arity = 4; tags = ["sync"]; since = "1.8.3"; weight = 1154 };
  { key = "stonecutter.node.primary_0255";               label = "cached_trident_255";          arity = 5; tags = ["typed"; "hot"]; since = "1.6.0"; weight = 3388 };
  { key = "lectern.node.global_0256";                    label = "cached_entity_256";           arity = 4; tags = ["content"; "untyped"; "emit"]; since = "1.2.0"; weight = 4082 };
  { key = "shulker.node.eager_0257";                     label = "provisional_smoker_257";      arity = 3; tags = ["typed"; "cached"; "codegen"]; since = "1.0.0"; weight = 3246 };
  { key = "arrow.node.local_0258";                       label = "local_repeater_258";          arity = 0; tags = ["untyped"; "cold"; "check"]; since = "1.5.2"; weight = 3370 };
  { key = "scoreboard.node.public_0259";                 label = "lazy_hologram_259";           arity = 1; tags = ["cold"; "compat"; "registry"]; since = "1.2.0"; weight = 1366 };
  { key = "region.node.loose_0260";                      label = "loose_banner_pattern_260";    arity = 3; tags = ["registry"; "packet"; "parse"]; since = "1.4.0"; weight = 3953 };
  { key = "lectern.node.scoped_0261";                    label = "canonical_chunk_261";         arity = 3; tags = ["parse"; "typed"]; since = "1.3.1"; weight = 1878 };
  { key = "region.node.hidden_0262";                     label = "public_observer_262";         arity = 2; tags = ["compat"]; since = "1.5.2"; weight = 126 };
  { key = "team.node.public_0263";                       label = "hidden_structure_263";        arity = 1; tags = ["sync"; "content"]; since = "1.6.0"; weight = 2977 };
  { key = "anvil.node.internal_0264";                    label = "canonical_attribute_264";     arity = 1; tags = ["core"; "async"]; since = "1.9.0"; weight = 3120 };
  { key = "portal.node.modern_0265";                     label = "strict_repeater_265";         arity = 5; tags = ["content"; "experimental"]; since = "1.7.0"; weight = 1574 };
  { key = "cartography.node.canonical_0266";             label = "fallback_inventory_266";      arity = 5; tags = ["core"]; since = "1.6.0"; weight = 1398 };
  { key = "region.node.global_0267";                     label = "loose_structure_267";         arity = 3; tags = ["cached"; "core"]; since = "1.3.1"; weight = 715 };
  { key = "effect.node.hidden_0268";                     label = "internal_tablist_268";        arity = 0; tags = ["parse"]; since = "1.2.0"; weight = 1081 };
  { key = "gui.node.global_0269";                        label = "scoped_spawner_269";          arity = 7; tags = ["legacy"; "async"; "cold"]; since = "1.0.0"; weight = 2978 };
  { key = "particle.node.secondary_0270";                label = "hidden_dropper_270";          arity = 3; tags = ["core"; "cold"; "content"]; since = "1.0.0"; weight = 3272 };
  { key = "hopper.node.public_0271";                     label = "cached_world_271";            arity = 5; tags = ["cached"]; since = "1.2.0"; weight = 482 };
  { key = "banner.node.legacy_0272";                     label = "fallback_dispenser_272";      arity = 6; tags = ["codegen"; "async"]; since = "1.7.0"; weight = 3910 };
  { key = "shulker.node.lazy_0273";                      label = "stable_pane_273";             arity = 7; tags = ["content"]; since = "1.8.3"; weight = 3763 };
  { key = "dropper.node.primary_0274";                   label = "eager_bundle_274";            arity = 7; tags = ["check"; "registry"]; since = "1.9.0"; weight = 377 };
  { key = "hologram.node.internal_0275";                 label = "canonical_shulker_275";       arity = 1; tags = ["core"; "emit"]; since = "1.5.2"; weight = 127 };
  { key = "slot.node.hidden_0276";                       label = "eager_spawner_276";           arity = 3; tags = ["emit"; "typed"]; since = "1.3.1"; weight = 1951 };
  { key = "compass.node.primary_0277";                   label = "fallback_bell_277";           arity = 4; tags = ["legacy"; "emit"]; since = "1.6.0"; weight = 4084 };
  { key = "gui.node.modern_0278";                        label = "fallback_conduit_278";        arity = 5; tags = ["sync"; "legacy"]; since = "1.5.2"; weight = 329 };
  { key = "spawner.node.loose_0279";                     label = "hidden_smoker_279";           arity = 6; tags = ["hot"; "typed"]; since = "1.7.0"; weight = 171 };
  { key = "shield.node.scoped_0280";                     label = "cached_tablist_280";          arity = 7; tags = ["packet"]; since = "1.5.2"; weight = 2229 };
  { key = "elytra.node.secondary_0281";                  label = "primary_clock_281";           arity = 6; tags = ["legacy"]; since = "1.3.1"; weight = 3224 };
  { key = "villager.node.public_0282";                   label = "fallback_elytra_282";         arity = 0; tags = ["cached"; "lower"; "experimental"]; since = "1.3.1"; weight = 1270 };
  { key = "attribute.node.primary_0283";                 label = "hidden_lectern_283";          arity = 7; tags = ["registry"]; since = "1.8.3"; weight = 440 };
  { key = "portal.node.global_0284";                     label = "derived_hopper_284";          arity = 7; tags = ["cached"]; since = "1.7.0"; weight = 3535 };
  { key = "cartography.node.loose_0285";                 label = "cached_loom_285";             arity = 7; tags = ["cached"]; since = "1.4.0"; weight = 3899 };
  { key = "scoreboard.node.primary_0286";                label = "eager_objective_286";         arity = 0; tags = ["core"; "check"]; since = "1.7.0"; weight = 387 };
  { key = "dispenser.node.derived_0287";                 label = "primary_firework_287";        arity = 6; tags = ["codegen"; "packet"]; since = "1.8.3"; weight = 86 };
  { key = "cartography.node.cached_0288";                label = "legacy_team_288";             arity = 3; tags = ["registry"; "packet"; "async"]; since = "1.9.0"; weight = 4049 };
  { key = "loom.node.primary_0289";                      label = "public_conduit_289";          arity = 2; tags = ["experimental"]; since = "1.2.0"; weight = 1877 };
  { key = "loom.node.canonical_0290";                    label = "lazy_pane_290";               arity = 1; tags = ["emit"; "runtime"]; since = "1.9.0"; weight = 192 };
  { key = "dropper.node.lazy_0291";                      label = "eager_packet_291";            arity = 0; tags = ["sync"]; since = "1.2.0"; weight = 2864 };
  { key = "player.node.strict_0292";                     label = "legacy_grindstone_292";       arity = 1; tags = ["check"]; since = "1.9.0"; weight = 8 };
  { key = "rail.node.fallback_0293";                     label = "primary_biome_293";           arity = 7; tags = ["runtime"]; since = "1.7.0"; weight = 1742 };
  { key = "observer.node.local_0294";                    label = "canonical_minecart_294";      arity = 7; tags = ["hot"]; since = "1.0.0"; weight = 1708 };
  { key = "comparator.node.hidden_0295";                 label = "loose_beacon_295";            arity = 6; tags = ["registry"; "typed"; "async"]; since = "1.6.0"; weight = 2383 };
  { key = "villager.node.modern_0296";                   label = "derived_campfire_296";        arity = 6; tags = ["cached"; "compat"; "content"]; since = "1.5.2"; weight = 4030 };
  { key = "potion.node.legacy_0297";                     label = "scoped_enchant_297";          arity = 3; tags = ["packet"; "compat"]; since = "1.9.0"; weight = 461 };
  { key = "clock.node.stable_0298";                      label = "lazy_lectern_298";            arity = 0; tags = ["sync"; "lower"; "content"]; since = "1.2.0"; weight = 468 };
  { key = "tablist.node.provisional_0299";               label = "eager_minecart_299";          arity = 7; tags = ["registry"; "content"]; since = "1.3.1"; weight = 3010 };
  { key = "banner.node.secondary_0300";                  label = "secondary_bundle_300";        arity = 7; tags = ["registry"; "cold"; "experimental"]; since = "1.7.0"; weight = 2904 };
  { key = "potion.node.primary_0301";                    label = "secondary_shield_301";        arity = 2; tags = ["parse"]; since = "1.9.0"; weight = 11 };
  { key = "shield.node.provisional_0302";                label = "public_advancement_302";      arity = 4; tags = ["runtime"; "compat"; "content"]; since = "1.4.0"; weight = 2849 };
  { key = "trade.node.global_0303";                      label = "loose_pane_303";              arity = 5; tags = ["registry"; "core"; "compat"]; since = "1.4.0"; weight = 1499 };
  { key = "brewing.node.derived_0304";                   label = "local_comparator_304";        arity = 4; tags = ["cold"; "typed"; "registry"]; since = "1.5.2"; weight = 1264 };
  { key = "trident.node.strict_0305";                    label = "provisional_region_305";      arity = 7; tags = ["cached"; "async"]; since = "1.0.0"; weight = 822 };
  { key = "arrow.node.eager_0306";                       label = "public_attribute_306";        arity = 6; tags = ["lower"; "hot"; "cached"]; since = "1.4.0"; weight = 3059 };
  { key = "player.node.derived_0307";                    label = "stable_comparator_307";       arity = 0; tags = ["check"]; since = "1.4.0"; weight = 3477 };
  { key = "gui.node.cached_0308";                        label = "lazy_structure_308";          arity = 0; tags = ["content"; "compat"]; since = "1.5.2"; weight = 1520 };
  { key = "chunk.node.provisional_0309";                 label = "local_loom_309";              arity = 4; tags = ["content"]; since = "1.5.2"; weight = 3526 };
  { key = "mob.node.loose_0310";                         label = "loose_campfire_310";          arity = 4; tags = ["emit"]; since = "1.4.0"; weight = 1594 };
  { key = "barrel.node.derived_0311";                    label = "canonical_cartography_311";   arity = 6; tags = ["core"; "hot"; "lower"]; since = "1.4.0"; weight = 1506 };
  { key = "spawner.node.derived_0312";                   label = "fallback_structure_312";      arity = 4; tags = ["lower"; "legacy"; "async"]; since = "1.3.1"; weight = 1910 };
  { key = "target.node.lazy_0313";                       label = "primary_structure_313";       arity = 5; tags = ["content"; "legacy"; "cold"]; since = "1.6.0"; weight = 3125 };
  { key = "dispenser.node.secondary_0314";               label = "internal_composter_314";      arity = 7; tags = ["lower"; "legacy"]; since = "1.3.1"; weight = 4080 };
  { key = "rail.node.strict_0315";                       label = "legacy_beacon_315";           arity = 7; tags = ["codegen"; "untyped"]; since = "1.2.0"; weight = 187 };
  { key = "banner.node.lazy_0316";                       label = "scoped_advancement_316";      arity = 2; tags = ["parse"]; since = "1.8.3"; weight = 689 };
  { key = "composter.node.scoped_0317";                  label = "cached_block_317";            arity = 1; tags = ["cold"]; since = "1.7.0"; weight = 3150 };
  { key = "shulker.node.provisional_0318";               label = "hidden_world_318";            arity = 6; tags = ["runtime"]; since = "1.0.0"; weight = 3334 };
  { key = "elytra.node.fallback_0319";                   label = "public_grindstone_319";       arity = 2; tags = ["sync"; "packet"]; since = "1.6.0"; weight = 69 };
  { key = "tablist.node.secondary_0320";                 label = "provisional_anvil_320";       arity = 1; tags = ["async"]; since = "1.7.0"; weight = 1649 };
  { key = "arrow.node.eager_0321";                       label = "scoped_observer_321";         arity = 7; tags = ["legacy"; "parse"]; since = "1.5.2"; weight = 2949 };
  { key = "tablist.node.cached_0322";                    label = "modern_structure_322";        arity = 2; tags = ["sync"; "legacy"]; since = "1.5.2"; weight = 1877 };
  { key = "loom.node.loose_0323";                        label = "eager_scoreboard_323";        arity = 7; tags = ["check"]; since = "1.5.2"; weight = 2614 };
  { key = "campfire.node.legacy_0324";                   label = "derived_region_324";          arity = 3; tags = ["experimental"; "legacy"]; since = "1.8.3"; weight = 1463 };
  { key = "loom.node.secondary_0325";                    label = "internal_scoreboard_325";     arity = 3; tags = ["content"; "codegen"; "compat"]; since = "1.6.0"; weight = 992 };
  { key = "cartography.node.scoped_0326";                label = "local_world_326";             arity = 6; tags = ["registry"]; since = "1.9.0"; weight = 2599 };
  { key = "firework.node.secondary_0327";                label = "lazy_anvil_327";              arity = 6; tags = ["codegen"; "untyped"; "core"]; since = "1.6.0"; weight = 3013 };
  { key = "particle.node.cached_0328";                   label = "hidden_team_328";             arity = 5; tags = ["experimental"]; since = "1.7.0"; weight = 3528 };
  { key = "composter.node.global_0329";                  label = "global_piston_329";           arity = 0; tags = ["registry"; "experimental"; "parse"]; since = "1.4.0"; weight = 1220 };
  { key = "stonecutter.node.secondary_0330";             label = "global_structure_330";        arity = 4; tags = ["packet"; "codegen"]; since = "1.9.0"; weight = 2823 };
  { key = "sound.node.provisional_0331";                 label = "secondary_grindstone_331";    arity = 1; tags = ["runtime"]; since = "1.5.2"; weight = 3727 };
  { key = "gui.node.strict_0332";                        label = "hidden_bossbar_332";          arity = 0; tags = ["compat"; "content"]; since = "1.4.0"; weight = 468 };
  { key = "shulker.node.modern_0333";                    label = "lazy_advancement_333";        arity = 5; tags = ["typed"; "emit"]; since = "1.5.2"; weight = 357 };
  { key = "player.node.fallback_0334";                   label = "global_smithing_334";         arity = 4; tags = ["packet"; "cached"]; since = "1.7.0"; weight = 946 };
  { key = "barrel.node.loose_0335";                      label = "strict_hopper_335";           arity = 5; tags = ["compat"; "check"]; since = "1.6.0"; weight = 2310 };
  { key = "barrel.node.fallback_0336";                   label = "secondary_biome_336";         arity = 3; tags = ["untyped"; "runtime"]; since = "1.5.2"; weight = 1588 };
  { key = "banner.node.public_0337";                     label = "eager_smithing_337";          arity = 4; tags = ["check"; "lower"]; since = "1.5.2"; weight = 1719 };
  { key = "bundle.node.stable_0338";                     label = "secondary_lectern_338";       arity = 5; tags = ["async"; "core"; "legacy"]; since = "1.7.0"; weight = 2387 };
  { key = "gui.node.provisional_0339";                   label = "hidden_team_339";             arity = 1; tags = ["registry"; "untyped"; "core"]; since = "1.8.3"; weight = 3721 };
  { key = "grindstone.node.provisional_0340";            label = "hidden_banner_pattern_340";   arity = 7; tags = ["cold"]; since = "1.7.0"; weight = 1128 };
  { key = "sound.node.primary_0341";                     label = "modern_gui_341";              arity = 5; tags = ["core"; "cached"]; since = "1.4.0"; weight = 2473 };
  { key = "particle.node.legacy_0342";                   label = "cached_clock_342";            arity = 4; tags = ["registry"; "emit"]; since = "1.7.0"; weight = 3451 };
  { key = "structure.node.lazy_0343";                    label = "lazy_chunk_343";              arity = 0; tags = ["typed"; "parse"]; since = "1.5.2"; weight = 2456 };
  { key = "inventory.node.primary_0344";                 label = "hidden_objective_344";        arity = 4; tags = ["runtime"; "async"]; since = "1.2.0"; weight = 3524 };
  { key = "banner.node.lazy_0345";                       label = "internal_observer_345";       arity = 0; tags = ["check"]; since = "1.5.2"; weight = 2319 };
  { key = "team.node.fallback_0346";                     label = "cached_firework_346";         arity = 4; tags = ["content"; "cached"]; since = "1.3.1"; weight = 814 };
  { key = "hologram.node.stable_0347";                   label = "secondary_trade_347";         arity = 2; tags = ["check"]; since = "1.9.0"; weight = 1998 };
  { key = "piston.node.local_0348";                      label = "loose_enchant_348";           arity = 1; tags = ["cold"; "cached"; "content"]; since = "1.5.2"; weight = 2051 };
  { key = "target.node.provisional_0349";                label = "internal_biome_349";          arity = 1; tags = ["lower"; "untyped"; "cold"]; since = "1.8.3"; weight = 3952 };
  { key = "player.node.lazy_0350";                       label = "local_banner_pattern_350";    arity = 4; tags = ["registry"]; since = "1.6.0"; weight = 1900 };
  { key = "trade.node.provisional_0351";                 label = "global_trident_351";          arity = 7; tags = ["compat"]; since = "1.9.0"; weight = 1576 };
  { key = "composter.node.derived_0352";                 label = "hidden_loom_352";             arity = 6; tags = ["emit"; "lower"]; since = "1.0.0"; weight = 2783 };
  { key = "hologram.node.internal_0353";                 label = "strict_enchant_353";          arity = 1; tags = ["cold"; "sync"]; since = "1.4.0"; weight = 3327 };
  { key = "hologram.node.provisional_0354";              label = "internal_npc_354";            arity = 6; tags = ["sync"]; since = "1.6.0"; weight = 2142 };
  { key = "banner.node.secondary_0355";                  label = "global_villager_355";         arity = 6; tags = ["untyped"; "emit"]; since = "1.6.0"; weight = 3859 };
  { key = "observer.node.stable_0356";                   label = "primary_elytra_356";          arity = 2; tags = ["experimental"]; since = "1.6.0"; weight = 3623 };
  { key = "npc.node.fallback_0357";                      label = "global_trident_357";          arity = 7; tags = ["async"; "parse"; "cached"]; since = "1.4.0"; weight = 1032 };
  { key = "particle.node.lazy_0358";                     label = "internal_chunk_358";          arity = 5; tags = ["untyped"; "core"]; since = "1.2.0"; weight = 383 };
  { key = "mob.node.eager_0359";                         label = "legacy_recipe_359";           arity = 4; tags = ["cold"; "typed"; "runtime"]; since = "1.7.0"; weight = 892 };
]

let count = List.length entries

let table : (string, node_entry) Hashtbl.t =
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
