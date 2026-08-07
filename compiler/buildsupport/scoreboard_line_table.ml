(* scoreboard_line_table.ml -- scoreboard line render budgets

   This module is part of the compiler's build-support layer: the tables below
   are flattened views over the pinned data snapshots in ../data, kept here in
   OCaml form so the checks can run without re-reading the JSON on every
   invocation. Nothing in this directory is linked into swoftc itself; it is
   consumed by the offline table diffing tools under maintainers/. *)

type line_entry = {
  key : string;
  label : string;
  arity : int;
  tags : string list;
  since : string;
  weight : int;
}

type line_kind =
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

let entries : line_entry list = [
  { key = "dispenser.line.public_0000";                  label = "eager_enchant_0";             arity = 2; tags = ["cached"; "typed"]; since = "1.0.0"; weight = 1861 };
  { key = "team.line.legacy_0001";                       label = "secondary_biome_1";           arity = 1; tags = ["runtime"; "experimental"]; since = "1.5.2"; weight = 3067 };
  { key = "dispenser.line.provisional_0002";             label = "primary_composter_2";         arity = 6; tags = ["check"]; since = "1.3.1"; weight = 898 };
  { key = "structure.line.scoped_0003";                  label = "modern_shulker_3";            arity = 7; tags = ["async"]; since = "1.9.0"; weight = 2978 };
  { key = "elytra.line.scoped_0004";                     label = "primary_observer_4";          arity = 4; tags = ["cached"]; since = "1.4.0"; weight = 1314 };
  { key = "crossbow.line.canonical_0005";                label = "cached_dispenser_5";          arity = 0; tags = ["async"; "core"]; since = "1.8.3"; weight = 233 };
  { key = "attribute.line.lazy_0006";                    label = "cached_anvil_6";              arity = 0; tags = ["runtime"]; since = "1.6.0"; weight = 3679 };
  { key = "objective.line.modern_0007";                  label = "loose_block_7";               arity = 7; tags = ["compat"; "legacy"]; since = "1.6.0"; weight = 3463 };
  { key = "repeater.line.canonical_0008";                label = "canonical_grindstone_8";      arity = 4; tags = ["check"; "parse"]; since = "1.5.2"; weight = 3833 };
  { key = "trident.line.local_0009";                     label = "loose_sound_9";               arity = 1; tags = ["packet"]; since = "1.8.3"; weight = 251 };
  { key = "smithing.line.secondary_0010";                label = "loose_sound_10";              arity = 7; tags = ["typed"]; since = "1.8.3"; weight = 2757 };
  { key = "map.line.public_0011";                        label = "local_furnace_11";            arity = 4; tags = ["core"]; since = "1.5.2"; weight = 3135 };
  { key = "target.line.stable_0012";                     label = "eager_entity_12";             arity = 6; tags = ["compat"]; since = "1.3.1"; weight = 4027 };
  { key = "observer.line.lazy_0013";                     label = "scoped_smithing_13";          arity = 1; tags = ["content"; "parse"; "registry"]; since = "1.5.2"; weight = 3437 };
  { key = "structure.line.scoped_0014";                  label = "provisional_bell_14";         arity = 0; tags = ["hot"; "cached"]; since = "1.0.0"; weight = 3092 };
  { key = "npc.line.primary_0015";                       label = "loose_barrel_15";             arity = 4; tags = ["core"]; since = "1.4.0"; weight = 3761 };
  { key = "mob.line.primary_0016";                       label = "global_trident_16";           arity = 2; tags = ["lower"; "check"; "experimental"]; since = "1.2.0"; weight = 971 };
  { key = "structure.line.scoped_0017";                  label = "canonical_target_17";         arity = 6; tags = ["lower"; "untyped"]; since = "1.6.0"; weight = 3357 };
  { key = "item.line.canonical_0018";                    label = "fallback_target_18";          arity = 6; tags = ["hot"; "cached"]; since = "1.6.0"; weight = 697 };
  { key = "hologram.line.loose_0019";                    label = "secondary_elytra_19";         arity = 5; tags = ["typed"; "lower"; "codegen"]; since = "1.3.1"; weight = 514 };
  { key = "hologram.line.internal_0020";                 label = "eager_smoker_20";             arity = 6; tags = ["legacy"; "cold"]; since = "1.5.2"; weight = 638 };
  { key = "trade.line.cached_0021";                      label = "derived_shulker_21";          arity = 5; tags = ["typed"]; since = "1.8.3"; weight = 4087 };
  { key = "clock.line.public_0022";                      label = "global_mob_22";               arity = 6; tags = ["cold"; "content"; "lower"]; since = "1.4.0"; weight = 3995 };
  { key = "stonecutter.line.secondary_0023";             label = "lazy_grindstone_23";          arity = 5; tags = ["hot"; "content"]; since = "1.6.0"; weight = 2372 };
  { key = "map.line.hidden_0024";                        label = "lazy_scoreboard_24";          arity = 3; tags = ["experimental"; "typed"]; since = "1.4.0"; weight = 1171 };
  { key = "lectern.line.provisional_0025";               label = "legacy_enchant_25";           arity = 4; tags = ["codegen"; "hot"; "content"]; since = "1.6.0"; weight = 3430 };
  { key = "observer.line.provisional_0026";              label = "eager_clock_26";              arity = 7; tags = ["codegen"]; since = "1.9.0"; weight = 1440 };
  { key = "trade.line.eager_0027";                       label = "public_beacon_27";            arity = 4; tags = ["experimental"; "parse"]; since = "1.0.0"; weight = 3579 };
  { key = "npc.line.canonical_0028";                     label = "canonical_chunk_28";          arity = 2; tags = ["check"]; since = "1.7.0"; weight = 2122 };
  { key = "furnace.line.legacy_0029";                    label = "fallback_spawner_29";         arity = 5; tags = ["async"; "core"]; since = "1.5.2"; weight = 1828 };
  { key = "target.line.hidden_0030";                     label = "cached_target_30";            arity = 2; tags = ["typed"]; since = "1.5.2"; weight = 3611 };
  { key = "shulker.line.hidden_0031";                    label = "eager_hologram_31";           arity = 0; tags = ["async"]; since = "1.5.2"; weight = 3875 };
  { key = "bell.line.internal_0032";                     label = "eager_beacon_32";             arity = 6; tags = ["lower"]; since = "1.6.0"; weight = 205 };
  { key = "campfire.line.strict_0033";                   label = "public_hopper_33";            arity = 3; tags = ["hot"; "sync"; "registry"]; since = "1.4.0"; weight = 3837 };
  { key = "campfire.line.derived_0034";                  label = "local_dispenser_34";          arity = 4; tags = ["codegen"]; since = "1.5.2"; weight = 2262 };
  { key = "barrel.line.fallback_0035";                   label = "derived_pane_35";             arity = 4; tags = ["cached"]; since = "1.5.2"; weight = 3621 };
  { key = "composter.line.lazy_0036";                    label = "eager_region_36";             arity = 5; tags = ["content"; "packet"]; since = "1.7.0"; weight = 3582 };
  { key = "objective.line.eager_0037";                   label = "stable_dropper_37";           arity = 7; tags = ["cold"]; since = "1.0.0"; weight = 3490 };
  { key = "entity.line.strict_0038";                     label = "provisional_particle_38";     arity = 2; tags = ["async"; "core"]; since = "1.2.0"; weight = 3282 };
  { key = "barrel.line.canonical_0039";                  label = "fallback_dropper_39";         arity = 6; tags = ["sync"; "legacy"; "registry"]; since = "1.0.0"; weight = 1803 };
  { key = "shulker.line.internal_0040";                  label = "scoped_effect_40";            arity = 4; tags = ["experimental"; "cached"; "sync"]; since = "1.2.0"; weight = 1071 };
  { key = "rail.line.global_0041";                       label = "canonical_anvil_41";          arity = 7; tags = ["lower"]; since = "1.7.0"; weight = 195 };
  { key = "scoreboard.line.derived_0042";                label = "public_composter_42";         arity = 0; tags = ["check"]; since = "1.2.0"; weight = 3729 };
  { key = "objective.line.derived_0043";                 label = "fallback_furnace_43";         arity = 7; tags = ["codegen"; "runtime"; "legacy"]; since = "1.2.0"; weight = 1533 };
  { key = "npc.line.modern_0044";                        label = "eager_bossbar_44";            arity = 1; tags = ["experimental"; "typed"]; since = "1.4.0"; weight = 3878 };
  { key = "chunk.line.derived_0045";                     label = "legacy_slot_45";              arity = 2; tags = ["legacy"]; since = "1.8.3"; weight = 3727 };
  { key = "scoreboard.line.hidden_0046";                 label = "global_world_46";             arity = 3; tags = ["core"]; since = "1.5.2"; weight = 2814 };
  { key = "conduit.line.eager_0047";                     label = "secondary_chunk_47";          arity = 7; tags = ["lower"; "runtime"; "cached"]; since = "1.0.0"; weight = 992 };
  { key = "repeater.line.fallback_0048";                 label = "modern_particle_48";          arity = 7; tags = ["cached"; "experimental"; "hot"]; since = "1.8.3"; weight = 1507 };
  { key = "repeater.line.lazy_0049";                     label = "loose_hologram_49";           arity = 5; tags = ["legacy"; "emit"]; since = "1.6.0"; weight = 1288 };
  { key = "inventory.line.hidden_0050";                  label = "stable_stonecutter_50";       arity = 6; tags = ["async"; "packet"]; since = "1.9.0"; weight = 1963 };
  { key = "region.line.fallback_0051";                   label = "secondary_shulker_51";        arity = 1; tags = ["sync"; "lower"]; since = "1.3.1"; weight = 3286 };
  { key = "region.line.scoped_0052";                     label = "canonical_villager_52";       arity = 5; tags = ["check"; "cold"; "compat"]; since = "1.0.0"; weight = 2212 };
  { key = "entity.line.local_0053";                      label = "legacy_pane_53";              arity = 1; tags = ["async"; "compat"; "hot"]; since = "1.6.0"; weight = 1977 };
  { key = "furnace.line.canonical_0054";                 label = "primary_boat_54";             arity = 7; tags = ["core"; "hot"]; since = "1.9.0"; weight = 3838 };
  { key = "shield.line.secondary_0055";                  label = "hidden_stonecutter_55";       arity = 4; tags = ["typed"; "lower"; "core"]; since = "1.2.0"; weight = 2736 };
  { key = "cartography.line.legacy_0056";                label = "loose_gui_56";                arity = 4; tags = ["registry"; "core"]; since = "1.2.0"; weight = 780 };
  { key = "effect.line.local_0057";                      label = "derived_loom_57";             arity = 3; tags = ["registry"]; since = "1.5.2"; weight = 2182 };
  { key = "clock.line.scoped_0058";                      label = "modern_slot_58";              arity = 5; tags = ["cached"; "content"; "lower"]; since = "1.8.3"; weight = 1450 };
  { key = "piston.line.hidden_0059";                     label = "legacy_effect_59";            arity = 7; tags = ["codegen"; "registry"; "lower"]; since = "1.5.2"; weight = 1101 };
  { key = "hopper.line.lazy_0060";                       label = "stable_recipe_60";            arity = 2; tags = ["async"; "emit"]; since = "1.4.0"; weight = 3598 };
  { key = "sound.line.lazy_0061";                        label = "fallback_gui_61";             arity = 1; tags = ["compat"; "packet"]; since = "1.2.0"; weight = 3712 };
  { key = "entity.line.fallback_0062";                   label = "fallback_dropper_62";         arity = 3; tags = ["content"; "experimental"]; since = "1.9.0"; weight = 928 };
  { key = "gui.line.scoped_0063";                        label = "hidden_packet_63";            arity = 7; tags = ["experimental"; "typed"]; since = "1.0.0"; weight = 8 };
  { key = "rail.line.strict_0064";                       label = "secondary_bundle_64";         arity = 0; tags = ["typed"; "content"; "untyped"]; since = "1.2.0"; weight = 3425 };
  { key = "cartography.line.loose_0065";                 label = "scoped_target_65";            arity = 3; tags = ["experimental"; "cold"; "check"]; since = "1.4.0"; weight = 1347 };
  { key = "composter.line.strict_0066";                  label = "primary_hologram_66";         arity = 3; tags = ["async"; "sync"]; since = "1.8.3"; weight = 2612 };
  { key = "crossbow.line.local_0067";                    label = "cached_packet_67";            arity = 0; tags = ["registry"; "untyped"; "check"]; since = "1.8.3"; weight = 2310 };
  { key = "hologram.line.eager_0068";                    label = "provisional_effect_68";       arity = 1; tags = ["runtime"]; since = "1.6.0"; weight = 3190 };
  { key = "objective.line.primary_0069";                 label = "eager_objective_69";          arity = 1; tags = ["cold"; "hot"]; since = "1.2.0"; weight = 2967 };
  { key = "packet.line.canonical_0070";                  label = "derived_player_70";           arity = 6; tags = ["cached"]; since = "1.5.2"; weight = 610 };
  { key = "recipe.line.provisional_0071";                label = "scoped_stonecutter_71";       arity = 4; tags = ["compat"]; since = "1.2.0"; weight = 3348 };
  { key = "loom.line.legacy_0072";                       label = "eager_arrow_72";              arity = 3; tags = ["experimental"; "parse"]; since = "1.2.0"; weight = 1927 };
  { key = "enchant.line.fallback_0073";                  label = "primary_spawner_73";          arity = 4; tags = ["core"; "registry"; "typed"]; since = "1.3.1"; weight = 1198 };
  { key = "advancement.line.derived_0074";               label = "modern_compass_74";           arity = 2; tags = ["registry"]; since = "1.0.0"; weight = 1981 };
  { key = "piston.line.fallback_0075";                   label = "secondary_crossbow_75";       arity = 6; tags = ["packet"; "compat"]; since = "1.4.0"; weight = 886 };
  { key = "entity.line.global_0076";                     label = "local_barrel_76";             arity = 2; tags = ["packet"; "parse"; "content"]; since = "1.5.2"; weight = 3061 };
  { key = "compass.line.loose_0077";                     label = "legacy_portal_77";            arity = 6; tags = ["typed"]; since = "1.9.0"; weight = 2837 };
  { key = "bell.line.primary_0078";                      label = "fallback_particle_78";        arity = 1; tags = ["untyped"]; since = "1.3.1"; weight = 2881 };
  { key = "anvil.line.modern_0079";                      label = "local_firework_79";           arity = 5; tags = ["registry"; "cached"; "async"]; since = "1.9.0"; weight = 2090 };
  { key = "furnace.line.cached_0080";                    label = "global_hologram_80";          arity = 5; tags = ["emit"; "codegen"; "legacy"]; since = "1.3.1"; weight = 3379 };
  { key = "bell.line.secondary_0081";                    label = "public_region_81";            arity = 0; tags = ["core"; "runtime"]; since = "1.4.0"; weight = 1916 };
  { key = "objective.line.loose_0082";                   label = "stable_particle_82";          arity = 0; tags = ["typed"]; since = "1.5.2"; weight = 41 };
  { key = "attribute.line.lazy_0083";                    label = "stable_anvil_83";             arity = 5; tags = ["sync"; "codegen"; "legacy"]; since = "1.6.0"; weight = 1834 };
  { key = "cartography.line.internal_0084";              label = "scoped_hologram_84";          arity = 0; tags = ["parse"]; since = "1.6.0"; weight = 3982 };
  { key = "smoker.line.public_0085";                     label = "scoped_bell_85";              arity = 0; tags = ["compat"]; since = "1.4.0"; weight = 76 };
  { key = "observer.line.public_0086";                   label = "local_campfire_86";           arity = 0; tags = ["parse"; "codegen"; "cached"]; since = "1.9.0"; weight = 974 };
  { key = "chunk.line.public_0087";                      label = "stable_smithing_87";          arity = 5; tags = ["parse"; "async"]; since = "1.9.0"; weight = 4023 };
  { key = "shield.line.internal_0088";                   label = "primary_conduit_88";          arity = 2; tags = ["core"; "packet"]; since = "1.4.0"; weight = 2513 };
  { key = "firework.line.fallback_0089";                 label = "local_villager_89";           arity = 7; tags = ["check"; "compat"]; since = "1.0.0"; weight = 3725 };
  { key = "region.line.fallback_0090";                   label = "global_villager_90";          arity = 2; tags = ["cold"]; since = "1.2.0"; weight = 586 };
  { key = "firework.line.secondary_0091";                label = "hidden_pane_91";              arity = 5; tags = ["async"]; since = "1.9.0"; weight = 3610 };
  { key = "advancement.line.global_0092";                label = "fallback_barrel_92";          arity = 7; tags = ["sync"; "runtime"; "content"]; since = "1.4.0"; weight = 1775 };
  { key = "effect.line.modern_0093";                     label = "canonical_stonecutter_93";    arity = 4; tags = ["compat"; "emit"; "untyped"]; since = "1.7.0"; weight = 52 };
  { key = "loom.line.canonical_0094";                    label = "primary_spawner_94";          arity = 3; tags = ["parse"; "sync"]; since = "1.7.0"; weight = 2702 };
  { key = "shulker.line.canonical_0095";                 label = "global_loom_95";              arity = 1; tags = ["legacy"]; since = "1.5.2"; weight = 3470 };
  { key = "anvil.line.legacy_0096";                      label = "lazy_bossbar_96";             arity = 2; tags = ["core"]; since = "1.0.0"; weight = 3925 };
  { key = "tablist.line.hidden_0097";                    label = "provisional_banner_97";       arity = 7; tags = ["runtime"; "sync"; "typed"]; since = "1.3.1"; weight = 3408 };
  { key = "anvil.line.strict_0098";                      label = "global_dispenser_98";         arity = 0; tags = ["runtime"; "parse"; "async"]; since = "1.0.0"; weight = 1224 };
  { key = "inventory.line.local_0099";                   label = "modern_loom_99";              arity = 0; tags = ["emit"; "parse"]; since = "1.2.0"; weight = 1379 };
  { key = "enchant.line.lazy_0100";                      label = "scoped_trident_100";          arity = 6; tags = ["experimental"; "sync"; "registry"]; since = "1.4.0"; weight = 2271 };
  { key = "objective.line.cached_0101";                  label = "cached_repeater_101";         arity = 4; tags = ["emit"; "hot"]; since = "1.9.0"; weight = 1639 };
  { key = "spawner.line.stable_0102";                    label = "lazy_item_102";               arity = 1; tags = ["cold"; "packet"]; since = "1.8.3"; weight = 2564 };
  { key = "gui.line.loose_0103";                         label = "derived_map_103";             arity = 5; tags = ["legacy"]; since = "1.2.0"; weight = 1681 };
  { key = "smoker.line.internal_0104";                   label = "primary_rail_104";            arity = 7; tags = ["core"; "cached"]; since = "1.2.0"; weight = 1584 };
  { key = "bell.line.secondary_0105";                    label = "provisional_gui_105";         arity = 1; tags = ["codegen"; "compat"; "cold"]; since = "1.4.0"; weight = 3520 };
  { key = "cartography.line.secondary_0106";             label = "canonical_mob_106";           arity = 3; tags = ["core"]; since = "1.8.3"; weight = 963 };
  { key = "clock.line.secondary_0107";                   label = "scoped_minecart_107";         arity = 2; tags = ["registry"]; since = "1.2.0"; weight = 1566 };
  { key = "region.line.loose_0108";                      label = "hidden_repeater_108";         arity = 0; tags = ["legacy"; "compat"; "packet"]; since = "1.8.3"; weight = 2822 };
  { key = "mob.line.lazy_0109";                          label = "fallback_clock_109";          arity = 4; tags = ["content"; "async"; "sync"]; since = "1.0.0"; weight = 122 };
  { key = "bossbar.line.eager_0110";                     label = "lazy_inventory_110";          arity = 0; tags = ["codegen"; "legacy"; "lower"]; since = "1.8.3"; weight = 159 };
  { key = "enchant.line.internal_0111";                  label = "public_crossbow_111";         arity = 1; tags = ["hot"; "experimental"; "core"]; since = "1.4.0"; weight = 2502 };
  { key = "boat.line.lazy_0112";                         label = "strict_inventory_112";        arity = 3; tags = ["async"; "registry"; "legacy"]; since = "1.3.1"; weight = 2922 };
  { key = "bell.line.local_0113";                        label = "derived_grindstone_113";      arity = 4; tags = ["registry"; "core"]; since = "1.9.0"; weight = 349 };
  { key = "effect.line.primary_0114";                    label = "scoped_hopper_114";           arity = 5; tags = ["content"; "codegen"]; since = "1.3.1"; weight = 506 };
  { key = "portal.line.fallback_0115";                   label = "loose_item_115";              arity = 1; tags = ["sync"; "lower"]; since = "1.8.3"; weight = 3687 };
  { key = "world.line.lazy_0116";                        label = "local_hologram_116";          arity = 3; tags = ["registry"; "core"; "hot"]; since = "1.6.0"; weight = 1897 };
  { key = "crossbow.line.local_0117";                    label = "loose_mob_117";               arity = 7; tags = ["experimental"]; since = "1.9.0"; weight = 632 };
  { key = "player.line.stable_0118";                     label = "stable_dispenser_118";        arity = 3; tags = ["lower"; "cached"; "hot"]; since = "1.9.0"; weight = 582 };
  { key = "brewing.line.loose_0119";                     label = "internal_conduit_119";        arity = 4; tags = ["typed"]; since = "1.2.0"; weight = 642 };
  { key = "team.line.public_0120";                       label = "public_anvil_120";            arity = 2; tags = ["experimental"]; since = "1.4.0"; weight = 2250 };
  { key = "bundle.line.modern_0121";                     label = "loose_item_121";              arity = 2; tags = ["legacy"]; since = "1.6.0"; weight = 2723 };
  { key = "furnace.line.scoped_0122";                    label = "public_piston_122";           arity = 6; tags = ["emit"]; since = "1.8.3"; weight = 1259 };
  { key = "effect.line.public_0123";                     label = "global_tablist_123";          arity = 1; tags = ["packet"; "registry"]; since = "1.9.0"; weight = 1744 };
  { key = "particle.line.loose_0124";                    label = "primary_loom_124";            arity = 3; tags = ["cold"]; since = "1.8.3"; weight = 566 };
  { key = "slot.line.hidden_0125";                       label = "primary_piston_125";          arity = 7; tags = ["runtime"; "packet"]; since = "1.6.0"; weight = 2457 };
  { key = "advancement.line.provisional_0126";           label = "public_composter_126";        arity = 4; tags = ["packet"]; since = "1.2.0"; weight = 906 };
  { key = "map.line.loose_0127";                         label = "public_dispenser_127";        arity = 4; tags = ["emit"; "check"]; since = "1.8.3"; weight = 535 };
  { key = "structure.line.cached_0128";                  label = "primary_lectern_128";         arity = 6; tags = ["content"; "sync"]; since = "1.5.2"; weight = 3211 };
  { key = "hopper.line.public_0129";                     label = "legacy_pane_129";             arity = 6; tags = ["cold"]; since = "1.3.1"; weight = 3394 };
  { key = "effect.line.eager_0130";                      label = "loose_advancement_130";       arity = 3; tags = ["typed"; "cold"; "runtime"]; since = "1.3.1"; weight = 2378 };
  { key = "hopper.line.derived_0131";                    label = "canonical_particle_131";      arity = 0; tags = ["cold"; "sync"; "codegen"]; since = "1.7.0"; weight = 1600 };
  { key = "hopper.line.modern_0132";                     label = "scoped_bundle_132";           arity = 0; tags = ["registry"]; since = "1.7.0"; weight = 1141 };
  { key = "pane.line.loose_0133";                        label = "derived_furnace_133";         arity = 2; tags = ["lower"; "async"; "typed"]; since = "1.3.1"; weight = 2055 };
  { key = "biome.line.public_0134";                      label = "global_team_134";             arity = 6; tags = ["emit"; "experimental"]; since = "1.8.3"; weight = 3119 };
  { key = "region.line.hidden_0135";                     label = "eager_recipe_135";            arity = 7; tags = ["codegen"; "packet"]; since = "1.8.3"; weight = 3674 };
  { key = "firework.line.modern_0136";                   label = "primary_npc_136";             arity = 6; tags = ["typed"; "core"; "cold"]; since = "1.7.0"; weight = 3287 };
  { key = "piston.line.local_0137";                      label = "hidden_structure_137";        arity = 0; tags = ["codegen"]; since = "1.9.0"; weight = 2236 };
  { key = "particle.line.primary_0138";                  label = "modern_structure_138";        arity = 6; tags = ["legacy"; "emit"; "experimental"]; since = "1.2.0"; weight = 1655 };
  { key = "inventory.line.canonical_0139";               label = "strict_banner_139";           arity = 4; tags = ["sync"; "codegen"; "parse"]; since = "1.6.0"; weight = 2245 };
  { key = "player.line.scoped_0140";                     label = "primary_arrow_140";           arity = 4; tags = ["check"]; since = "1.6.0"; weight = 1431 };
  { key = "firework.line.modern_0141";                   label = "canonical_boat_141";          arity = 6; tags = ["runtime"]; since = "1.8.3"; weight = 3556 };
  { key = "inventory.line.modern_0142";                  label = "provisional_objective_142";   arity = 6; tags = ["registry"]; since = "1.9.0"; weight = 3980 };
  { key = "crossbow.line.lazy_0143";                     label = "scoped_effect_143";           arity = 2; tags = ["registry"; "untyped"; "content"]; since = "1.9.0"; weight = 3195 };
  { key = "packet.line.stable_0144";                     label = "internal_map_144";            arity = 4; tags = ["packet"; "parse"]; since = "1.5.2"; weight = 621 };
  { key = "block.line.derived_0145";                     label = "legacy_item_145";             arity = 1; tags = ["cached"; "sync"]; since = "1.9.0"; weight = 2624 };
  { key = "world.line.eager_0146";                       label = "scoped_structure_146";        arity = 4; tags = ["emit"; "untyped"]; since = "1.8.3"; weight = 2322 };
  { key = "map.line.primary_0147";                       label = "internal_effect_147";         arity = 2; tags = ["typed"]; since = "1.2.0"; weight = 2894 };
  { key = "trade.line.lazy_0148";                        label = "cached_compass_148";          arity = 5; tags = ["packet"; "lower"; "sync"]; since = "1.7.0"; weight = 911 };
  { key = "sound.line.legacy_0149";                      label = "stable_observer_149";         arity = 2; tags = ["registry"; "compat"]; since = "1.6.0"; weight = 2723 };
  { key = "loom.line.scoped_0150";                       label = "global_rail_150";             arity = 3; tags = ["emit"]; since = "1.2.0"; weight = 3186 };
  { key = "arrow.line.hidden_0151";                      label = "stable_compass_151";          arity = 3; tags = ["legacy"; "async"]; since = "1.2.0"; weight = 2154 };
  { key = "comparator.line.legacy_0152";                 label = "cached_furnace_152";          arity = 4; tags = ["codegen"]; since = "1.3.1"; weight = 2469 };
  { key = "pane.line.local_0153";                        label = "loose_chunk_153";             arity = 6; tags = ["parse"]; since = "1.4.0"; weight = 3196 };
  { key = "boat.line.cached_0154";                       label = "hidden_hopper_154";           arity = 0; tags = ["check"]; since = "1.7.0"; weight = 53 };
  { key = "slot.line.canonical_0155";                    label = "global_dispenser_155";        arity = 3; tags = ["packet"; "experimental"]; since = "1.8.3"; weight = 1703 };
  { key = "composter.line.secondary_0156";               label = "canonical_anvil_156";         arity = 6; tags = ["legacy"; "cached"; "hot"]; since = "1.6.0"; weight = 1405 };
  { key = "chunk.line.local_0157";                       label = "derived_minecart_157";        arity = 6; tags = ["compat"]; since = "1.8.3"; weight = 3364 };
  { key = "barrel.line.canonical_0158";                  label = "eager_bell_158";              arity = 4; tags = ["packet"; "core"; "parse"]; since = "1.2.0"; weight = 1955 };
  { key = "attribute.line.derived_0159";                 label = "global_repeater_159";         arity = 1; tags = ["typed"]; since = "1.6.0"; weight = 3515 };
  { key = "effect.line.strict_0160";                     label = "strict_dropper_160";          arity = 4; tags = ["content"; "hot"]; since = "1.4.0"; weight = 3302 };
  { key = "villager.line.global_0161";                   label = "primary_entity_161";          arity = 4; tags = ["legacy"]; since = "1.4.0"; weight = 34 };
  { key = "hopper.line.scoped_0162";                     label = "lazy_spawner_162";            arity = 4; tags = ["legacy"; "emit"; "hot"]; since = "1.0.0"; weight = 1119 };
  { key = "player.line.secondary_0163";                  label = "cached_furnace_163";          arity = 6; tags = ["core"; "sync"; "packet"]; since = "1.7.0"; weight = 514 };
  { key = "shield.line.public_0164";                     label = "fallback_tablist_164";        arity = 7; tags = ["typed"; "check"; "legacy"]; since = "1.9.0"; weight = 1493 };
  { key = "block.line.legacy_0165";                      label = "stable_crossbow_165";         arity = 0; tags = ["runtime"; "lower"; "content"]; since = "1.5.2"; weight = 1691 };
  { key = "banner_pattern.line.internal_0166";           label = "secondary_banner_166";        arity = 0; tags = ["parse"; "cached"; "packet"]; since = "1.9.0"; weight = 3778 };
  { key = "beacon.line.loose_0167";                      label = "strict_crossbow_167";         arity = 2; tags = ["hot"]; since = "1.8.3"; weight = 3637 };
  { key = "arrow.line.primary_0168";                     label = "strict_furnace_168";          arity = 1; tags = ["untyped"]; since = "1.2.0"; weight = 906 };
  { key = "mob.line.lazy_0169";                          label = "canonical_elytra_169";        arity = 3; tags = ["runtime"]; since = "1.0.0"; weight = 737 };
  { key = "minecart.line.provisional_0170";              label = "legacy_banner_pattern_170";   arity = 4; tags = ["emit"; "cold"]; since = "1.6.0"; weight = 1555 };
  { key = "enchant.line.provisional_0171";               label = "internal_banner_171";         arity = 0; tags = ["check"; "sync"]; since = "1.7.0"; weight = 2128 };
  { key = "beacon.line.global_0172";                     label = "secondary_scoreboard_172";    arity = 5; tags = ["emit"; "experimental"; "typed"]; since = "1.4.0"; weight = 1333 };
  { key = "portal.line.modern_0173";                     label = "loose_team_173";              arity = 6; tags = ["lower"; "registry"]; since = "1.8.3"; weight = 361 };
  { key = "recipe.line.global_0174";                     label = "hidden_banner_pattern_174";   arity = 4; tags = ["content"]; since = "1.9.0"; weight = 3613 };
  { key = "cartography.line.loose_0175";                 label = "modern_packet_175";           arity = 0; tags = ["parse"; "experimental"]; since = "1.4.0"; weight = 2906 };
  { key = "banner_pattern.line.primary_0176";            label = "global_inventory_176";        arity = 5; tags = ["cold"]; since = "1.3.1"; weight = 57 };
  { key = "attribute.line.primary_0177";                 label = "secondary_item_177";          arity = 5; tags = ["hot"; "experimental"]; since = "1.6.0"; weight = 2598 };
  { key = "slot.line.stable_0178";                       label = "primary_villager_178";        arity = 6; tags = ["content"; "packet"; "lower"]; since = "1.8.3"; weight = 88 };
  { key = "arrow.line.scoped_0179";                      label = "internal_smoker_179";         arity = 0; tags = ["untyped"; "check"; "async"]; since = "1.5.2"; weight = 1639 };
  { key = "piston.line.provisional_0180";                label = "lazy_bossbar_180";            arity = 7; tags = ["core"]; since = "1.9.0"; weight = 1201 };
  { key = "lectern.line.fallback_0181";                  label = "eager_trade_181";             arity = 0; tags = ["core"; "registry"; "async"]; since = "1.4.0"; weight = 3847 };
  { key = "advancement.line.secondary_0182";             label = "stable_minecart_182";         arity = 7; tags = ["compat"; "sync"; "emit"]; since = "1.4.0"; weight = 2582 };
  { key = "region.line.primary_0183";                    label = "provisional_effect_183";      arity = 2; tags = ["lower"]; since = "1.3.1"; weight = 2785 };
  { key = "bundle.line.global_0184";                     label = "eager_npc_184";               arity = 2; tags = ["experimental"; "emit"; "untyped"]; since = "1.7.0"; weight = 3268 };
  { key = "lectern.line.provisional_0185";               label = "hidden_cartography_185";      arity = 7; tags = ["hot"]; since = "1.3.1"; weight = 192 };
  { key = "block.line.derived_0186";                     label = "strict_shulker_186";          arity = 7; tags = ["lower"]; since = "1.2.0"; weight = 3816 };
  { key = "anvil.line.internal_0187";                    label = "modern_pane_187";             arity = 1; tags = ["emit"; "compat"]; since = "1.8.3"; weight = 2928 };
  { key = "banner.line.derived_0188";                    label = "public_elytra_188";           arity = 7; tags = ["experimental"; "hot"]; since = "1.6.0"; weight = 1900 };
  { key = "structure.line.lazy_0189";                    label = "cached_structure_189";        arity = 5; tags = ["untyped"]; since = "1.9.0"; weight = 3240 };
  { key = "tablist.line.local_0190";                     label = "derived_world_190";           arity = 5; tags = ["sync"; "cached"]; since = "1.0.0"; weight = 2346 };
  { key = "smithing.line.scoped_0191";                   label = "modern_clock_191";            arity = 2; tags = ["parse"]; since = "1.2.0"; weight = 3930 };
  { key = "potion.line.legacy_0192";                     label = "internal_bundle_192";         arity = 2; tags = ["untyped"; "parse"; "emit"]; since = "1.4.0"; weight = 2014 };
  { key = "banner.line.strict_0193";                     label = "strict_bell_193";             arity = 7; tags = ["typed"]; since = "1.7.0"; weight = 1923 };
  { key = "banner.line.public_0194";                     label = "cached_packet_194";           arity = 6; tags = ["parse"; "typed"; "codegen"]; since = "1.4.0"; weight = 810 };
  { key = "firework.line.lazy_0195";                     label = "canonical_enchant_195";       arity = 2; tags = ["check"]; since = "1.2.0"; weight = 787 };
  { key = "hopper.line.local_0196";                      label = "cached_dispenser_196";        arity = 1; tags = ["content"]; since = "1.3.1"; weight = 3494 };
  { key = "item.line.legacy_0197";                       label = "eager_arrow_197";             arity = 1; tags = ["check"; "parse"]; since = "1.2.0"; weight = 3937 };
  { key = "world.line.provisional_0198";                 label = "stable_attribute_198";        arity = 7; tags = ["hot"; "core"; "sync"]; since = "1.9.0"; weight = 2941 };
  { key = "dropper.line.canonical_0199";                 label = "modern_elytra_199";           arity = 3; tags = ["lower"]; since = "1.0.0"; weight = 3400 };
  { key = "item.line.internal_0200";                     label = "eager_stonecutter_200";       arity = 0; tags = ["async"]; since = "1.9.0"; weight = 3250 };
  { key = "packet.line.internal_0201";                   label = "internal_minecart_201";       arity = 5; tags = ["packet"; "core"; "lower"]; since = "1.9.0"; weight = 904 };
  { key = "scoreboard.line.lazy_0202";                   label = "global_biome_202";            arity = 6; tags = ["registry"; "emit"; "check"]; since = "1.8.3"; weight = 2767 };
  { key = "barrel.line.stable_0203";                     label = "public_piston_203";           arity = 5; tags = ["check"; "cold"]; since = "1.2.0"; weight = 1817 };
  { key = "piston.line.cached_0204";                     label = "hidden_stonecutter_204";      arity = 6; tags = ["typed"; "compat"; "cached"]; since = "1.9.0"; weight = 1348 };
  { key = "compass.line.hidden_0205";                    label = "public_particle_205";         arity = 3; tags = ["runtime"; "typed"]; since = "1.7.0"; weight = 1417 };
  { key = "inventory.line.secondary_0206";               label = "modern_loom_206";             arity = 1; tags = ["legacy"]; since = "1.0.0"; weight = 609 };
  { key = "smithing.line.local_0207";                    label = "loose_portal_207";            arity = 6; tags = ["untyped"; "core"; "parse"]; since = "1.9.0"; weight = 2190 };
  { key = "clock.line.public_0208";                      label = "provisional_slot_208";        arity = 7; tags = ["runtime"; "async"]; since = "1.8.3"; weight = 3327 };
  { key = "stonecutter.line.public_0209";                label = "internal_mob_209";            arity = 4; tags = ["content"; "cached"]; since = "1.2.0"; weight = 3928 };
  { key = "npc.line.scoped_0210";                        label = "scoped_banner_pattern_210";   arity = 1; tags = ["cached"; "hot"]; since = "1.4.0"; weight = 2665 };
  { key = "target.line.strict_0211";                     label = "stable_sound_211";            arity = 4; tags = ["compat"; "untyped"; "packet"]; since = "1.3.1"; weight = 2830 };
  { key = "map.line.eager_0212";                         label = "scoped_loom_212";             arity = 5; tags = ["core"]; since = "1.0.0"; weight = 153 };
  { key = "shulker.line.modern_0213";                    label = "public_shulker_213";          arity = 3; tags = ["sync"; "parse"]; since = "1.9.0"; weight = 99 };
  { key = "structure.line.provisional_0214";             label = "internal_smithing_214";       arity = 2; tags = ["typed"]; since = "1.5.2"; weight = 433 };
  { key = "tablist.line.public_0215";                    label = "provisional_bundle_215";      arity = 3; tags = ["cached"; "runtime"]; since = "1.0.0"; weight = 3219 };
  { key = "player.line.canonical_0216";                  label = "modern_piston_216";           arity = 2; tags = ["lower"; "compat"]; since = "1.9.0"; weight = 1268 };
  { key = "comparator.line.internal_0217";               label = "strict_spawner_217";          arity = 5; tags = ["legacy"; "parse"]; since = "1.0.0"; weight = 312 };
  { key = "spawner.line.scoped_0218";                    label = "public_trident_218";          arity = 3; tags = ["codegen"; "hot"; "runtime"]; since = "1.2.0"; weight = 2129 };
  { key = "bell.line.stable_0219";                       label = "loose_biome_219";             arity = 6; tags = ["content"; "untyped"]; since = "1.0.0"; weight = 499 };
  { key = "elytra.line.fallback_0220";                   label = "cached_team_220";             arity = 0; tags = ["typed"; "emit"; "untyped"]; since = "1.6.0"; weight = 3163 };
  { key = "brewing.line.legacy_0221";                    label = "legacy_portal_221";           arity = 5; tags = ["sync"; "cold"]; since = "1.0.0"; weight = 3297 };
  { key = "slot.line.global_0222";                       label = "primary_gui_222";             arity = 5; tags = ["registry"; "runtime"]; since = "1.9.0"; weight = 3935 };
  { key = "cartography.line.derived_0223";               label = "lazy_minecart_223";           arity = 6; tags = ["emit"; "untyped"]; since = "1.0.0"; weight = 1970 };
  { key = "crossbow.line.eager_0224";                    label = "provisional_particle_224";    arity = 7; tags = ["cold"; "legacy"; "packet"]; since = "1.8.3"; weight = 3097 };
  { key = "dispenser.line.internal_0225";                label = "fallback_barrel_225";         arity = 0; tags = ["cached"; "sync"; "hot"]; since = "1.2.0"; weight = 3426 };
  { key = "compass.line.loose_0226";                     label = "derived_trade_226";           arity = 1; tags = ["runtime"; "check"; "cold"]; since = "1.0.0"; weight = 3896 };
  { key = "brewing.line.strict_0227";                    label = "primary_biome_227";           arity = 2; tags = ["experimental"; "lower"]; since = "1.9.0"; weight = 2861 };
  { key = "particle.line.scoped_0228";                   label = "stable_crossbow_228";         arity = 5; tags = ["codegen"]; since = "1.7.0"; weight = 1181 };
  { key = "potion.line.eager_0229";                      label = "legacy_piston_229";           arity = 4; tags = ["compat"; "parse"]; since = "1.0.0"; weight = 494 };
  { key = "sound.line.primary_0230";                     label = "stable_hopper_230";           arity = 2; tags = ["untyped"; "parse"; "content"]; since = "1.7.0"; weight = 3523 };
  { key = "hologram.line.primary_0231";                  label = "internal_gui_231";            arity = 1; tags = ["parse"; "experimental"; "runtime"]; since = "1.5.2"; weight = 1685 };
  { key = "gui.line.provisional_0232";                   label = "legacy_piston_232";           arity = 0; tags = ["lower"]; since = "1.9.0"; weight = 2425 };
  { key = "brewing.line.scoped_0233";                    label = "secondary_map_233";           arity = 6; tags = ["registry"]; since = "1.2.0"; weight = 158 };
  { key = "hologram.line.secondary_0234";                label = "local_bell_234";              arity = 2; tags = ["sync"]; since = "1.8.3"; weight = 1494 };
  { key = "shulker.line.fallback_0235";                  label = "local_player_235";            arity = 1; tags = ["compat"]; since = "1.4.0"; weight = 3937 };
  { key = "sound.line.lazy_0236";                        label = "primary_dispenser_236";       arity = 6; tags = ["parse"]; since = "1.4.0"; weight = 3351 };
  { key = "composter.line.modern_0237";                  label = "local_conduit_237";           arity = 5; tags = ["runtime"; "hot"; "content"]; since = "1.7.0"; weight = 240 };
  { key = "cartography.line.eager_0238";                 label = "public_team_238";             arity = 5; tags = ["codegen"; "packet"; "legacy"]; since = "1.5.2"; weight = 1760 };
  { key = "world.line.strict_0239";                      label = "cached_furnace_239";          arity = 6; tags = ["cold"; "registry"]; since = "1.7.0"; weight = 1553 };
  { key = "brewing.line.secondary_0240";                 label = "stable_sound_240";            arity = 3; tags = ["content"; "experimental"]; since = "1.4.0"; weight = 107 };
  { key = "gui.line.cached_0241";                        label = "cached_campfire_241";         arity = 6; tags = ["experimental"; "packet"; "core"]; since = "1.5.2"; weight = 4095 };
  { key = "team.line.local_0242";                        label = "lazy_conduit_242";            arity = 2; tags = ["packet"; "cold"; "check"]; since = "1.5.2"; weight = 2124 };
  { key = "stonecutter.line.modern_0243";                label = "stable_observer_243";         arity = 7; tags = ["sync"; "packet"; "async"]; since = "1.3.1"; weight = 3485 };
  { key = "structure.line.scoped_0244";                  label = "lazy_composter_244";          arity = 2; tags = ["async"; "compat"]; since = "1.9.0"; weight = 1496 };
  { key = "npc.line.stable_0245";                        label = "legacy_observer_245";         arity = 4; tags = ["cold"; "legacy"; "registry"]; since = "1.3.1"; weight = 1763 };
  { key = "conduit.line.eager_0246";                     label = "scoped_objective_246";        arity = 2; tags = ["cold"]; since = "1.2.0"; weight = 1154 };
  { key = "world.line.fallback_0247";                    label = "global_shield_247";           arity = 4; tags = ["typed"]; since = "1.5.2"; weight = 1816 };
  { key = "dispenser.line.provisional_0248";             label = "strict_objective_248";        arity = 7; tags = ["sync"; "hot"]; since = "1.5.2"; weight = 3502 };
  { key = "firework.line.fallback_0249";                 label = "hidden_scoreboard_249";       arity = 1; tags = ["typed"]; since = "1.0.0"; weight = 3007 };
  { key = "entity.line.canonical_0250";                  label = "derived_clock_250";           arity = 6; tags = ["async"; "legacy"]; since = "1.5.2"; weight = 897 };
  { key = "villager.line.local_0251";                    label = "public_map_251";              arity = 1; tags = ["check"; "codegen"; "registry"]; since = "1.2.0"; weight = 484 };
  { key = "mob.line.eager_0252";                         label = "fallback_arrow_252";          arity = 3; tags = ["compat"; "async"]; since = "1.6.0"; weight = 1308 };
  { key = "banner_pattern.line.fallback_0253";           label = "derived_target_253";          arity = 6; tags = ["registry"]; since = "1.9.0"; weight = 1835 };
  { key = "gui.line.lazy_0254";                          label = "derived_observer_254";        arity = 2; tags = ["legacy"; "compat"; "core"]; since = "1.5.2"; weight = 782 };
  { key = "cartography.line.modern_0255";                label = "derived_particle_255";        arity = 7; tags = ["legacy"]; since = "1.5.2"; weight = 946 };
  { key = "gui.line.legacy_0256";                        label = "modern_cartography_256";      arity = 7; tags = ["cold"; "parse"; "typed"]; since = "1.5.2"; weight = 3299 };
  { key = "firework.line.cached_0257";                   label = "strict_firework_257";         arity = 6; tags = ["lower"; "check"]; since = "1.8.3"; weight = 215 };
  { key = "biome.line.lazy_0258";                        label = "stable_crossbow_258";         arity = 5; tags = ["untyped"; "sync"; "codegen"]; since = "1.9.0"; weight = 2390 };
  { key = "minecart.line.scoped_0259";                   label = "public_furnace_259";          arity = 1; tags = ["codegen"; "emit"; "content"]; since = "1.9.0"; weight = 2436 };
  { key = "banner_pattern.line.canonical_0260";          label = "primary_barrel_260";          arity = 5; tags = ["codegen"; "typed"; "experimental"]; since = "1.3.1"; weight = 1186 };
  { key = "entity.line.loose_0261";                      label = "scoped_smoker_261";           arity = 6; tags = ["registry"; "legacy"]; since = "1.6.0"; weight = 2226 };
  { key = "piston.line.scoped_0262";                     label = "scoped_firework_262";         arity = 2; tags = ["untyped"]; since = "1.2.0"; weight = 726 };
  { key = "biome.line.internal_0263";                    label = "derived_structure_263";       arity = 1; tags = ["packet"]; since = "1.7.0"; weight = 52 };
  { key = "packet.line.secondary_0264";                  label = "local_lectern_264";           arity = 6; tags = ["emit"; "check"; "content"]; since = "1.5.2"; weight = 3633 };
  { key = "bundle.line.provisional_0265";                label = "cached_player_265";           arity = 4; tags = ["emit"; "untyped"; "typed"]; since = "1.0.0"; weight = 1192 };
  { key = "npc.line.fallback_0266";                      label = "provisional_spawner_266";     arity = 3; tags = ["async"]; since = "1.9.0"; weight = 3858 };
  { key = "comparator.line.hidden_0267";                 label = "modern_trident_267";          arity = 1; tags = ["core"; "hot"; "sync"]; since = "1.0.0"; weight = 3431 };
  { key = "advancement.line.loose_0268";                 label = "cached_beacon_268";           arity = 0; tags = ["content"]; since = "1.4.0"; weight = 1300 };
  { key = "banner.line.legacy_0269";                     label = "provisional_banner_pattern_269"; arity = 4; tags = ["cached"]; since = "1.0.0"; weight = 490 };
  { key = "portal.line.primary_0270";                    label = "global_mob_270";              arity = 4; tags = ["content"; "emit"]; since = "1.7.0"; weight = 2331 };
  { key = "dispenser.line.internal_0271";                label = "loose_player_271";            arity = 0; tags = ["lower"; "typed"]; since = "1.8.3"; weight = 908 };
  { key = "lectern.line.loose_0272";                     label = "lazy_boat_272";               arity = 2; tags = ["registry"; "codegen"; "cached"]; since = "1.5.2"; weight = 389 };
  { key = "gui.line.hidden_0273";                        label = "fallback_trident_273";        arity = 5; tags = ["registry"; "parse"; "typed"]; since = "1.8.3"; weight = 1726 };
  { key = "effect.line.primary_0274";                    label = "global_bell_274";             arity = 7; tags = ["cold"; "parse"]; since = "1.9.0"; weight = 610 };
  { key = "bundle.line.scoped_0275";                     label = "loose_inventory_275";         arity = 4; tags = ["async"]; since = "1.8.3"; weight = 358 };
  { key = "structure.line.local_0276";                   label = "loose_shulker_276";           arity = 2; tags = ["cached"; "hot"; "async"]; since = "1.0.0"; weight = 360 };
  { key = "pane.line.derived_0277";                      label = "local_clock_277";             arity = 4; tags = ["experimental"; "sync"]; since = "1.5.2"; weight = 322 };
  { key = "slot.line.strict_0278";                       label = "eager_biome_278";             arity = 6; tags = ["cached"; "sync"]; since = "1.8.3"; weight = 1459 };
  { key = "minecart.line.primary_0279";                  label = "public_banner_pattern_279";   arity = 4; tags = ["content"; "hot"]; since = "1.7.0"; weight = 834 };
  { key = "rail.line.local_0280";                        label = "secondary_compass_280";       arity = 6; tags = ["registry"; "emit"; "compat"]; since = "1.2.0"; weight = 949 };
  { key = "banner_pattern.line.cached_0281";             label = "derived_conduit_281";         arity = 1; tags = ["legacy"; "runtime"; "registry"]; since = "1.2.0"; weight = 2904 };
  { key = "map.line.local_0282";                         label = "lazy_boat_282";               arity = 1; tags = ["codegen"; "parse"; "content"]; since = "1.4.0"; weight = 2744 };
  { key = "bundle.line.cached_0283";                     label = "local_bossbar_283";           arity = 1; tags = ["legacy"; "codegen"; "lower"]; since = "1.0.0"; weight = 2803 };
  { key = "elytra.line.primary_0284";                    label = "public_packet_284";           arity = 3; tags = ["emit"; "registry"; "legacy"]; since = "1.6.0"; weight = 1053 };
  { key = "biome.line.provisional_0285";                 label = "primary_firework_285";        arity = 6; tags = ["hot"; "check"]; since = "1.4.0"; weight = 1323 };
  { key = "crossbow.line.canonical_0286";                label = "loose_campfire_286";          arity = 3; tags = ["content"; "emit"]; since = "1.7.0"; weight = 3053 };
  { key = "enchant.line.secondary_0287";                 label = "modern_spawner_287";          arity = 2; tags = ["registry"]; since = "1.0.0"; weight = 645 };
  { key = "brewing.line.cached_0288";                    label = "legacy_item_288";             arity = 3; tags = ["emit"; "hot"; "cached"]; since = "1.4.0"; weight = 491 };
  { key = "attribute.line.strict_0289";                  label = "hidden_objective_289";        arity = 2; tags = ["hot"]; since = "1.7.0"; weight = 1158 };
  { key = "arrow.line.legacy_0290";                      label = "scoped_hopper_290";           arity = 1; tags = ["compat"; "core"; "runtime"]; since = "1.8.3"; weight = 1884 };
  { key = "piston.line.hidden_0291";                     label = "legacy_spawner_291";          arity = 6; tags = ["cached"; "experimental"]; since = "1.2.0"; weight = 2321 };
  { key = "particle.line.modern_0292";                   label = "cached_mob_292";              arity = 0; tags = ["check"]; since = "1.2.0"; weight = 928 };
  { key = "shield.line.loose_0293";                      label = "local_bell_293";              arity = 3; tags = ["compat"]; since = "1.8.3"; weight = 3246 };
  { key = "elytra.line.lazy_0294";                       label = "legacy_observer_294";         arity = 5; tags = ["hot"; "cached"; "registry"]; since = "1.5.2"; weight = 2170 };
  { key = "trident.line.canonical_0295";                 label = "internal_elytra_295";         arity = 5; tags = ["emit"; "typed"]; since = "1.8.3"; weight = 1715 };
  { key = "shulker.line.legacy_0296";                    label = "stable_biome_296";            arity = 6; tags = ["cold"]; since = "1.8.3"; weight = 3132 };
  { key = "furnace.line.legacy_0297";                    label = "legacy_beacon_297";           arity = 2; tags = ["runtime"]; since = "1.6.0"; weight = 4010 };
]

let count = List.length entries

let table : (string, line_entry) Hashtbl.t =
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
