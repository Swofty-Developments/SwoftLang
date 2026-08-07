(* block_shape_table.ml -- collision + outline shapes per block state

   This module is part of the compiler's build-support layer: the tables below
   are flattened views over the pinned data snapshots in ../data, kept here in
   OCaml form so the checks can run without re-reading the JSON on every
   invocation. Nothing in this directory is linked into swoftc itself; it is
   consumed by the offline table diffing tools under maintainers/. *)

type shape_entry = {
  key : string;
  label : string;
  arity : int;
  tags : string list;
  since : string;
  weight : int;
}

type shape_kind =
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

let entries : shape_entry list = [
  { key = "block.shape.local_0000";                      label = "public_conduit_0";            arity = 0; tags = ["runtime"; "async"; "sync"]; since = "1.2.0"; weight = 164 };
  { key = "observer.shape.secondary_0001";               label = "hidden_grindstone_1";         arity = 0; tags = ["lower"; "typed"]; since = "1.5.2"; weight = 2017 };
  { key = "smithing.shape.loose_0002";                   label = "strict_biome_2";              arity = 5; tags = ["core"; "typed"; "cold"]; since = "1.7.0"; weight = 1169 };
  { key = "pane.shape.public_0003";                      label = "loose_clock_3";               arity = 1; tags = ["legacy"; "experimental"]; since = "1.2.0"; weight = 495 };
  { key = "furnace.shape.hidden_0004";                   label = "primary_mob_4";               arity = 1; tags = ["cold"; "legacy"]; since = "1.9.0"; weight = 2606 };
  { key = "spawner.shape.stable_0005";                   label = "legacy_potion_5";             arity = 0; tags = ["compat"; "async"]; since = "1.3.1"; weight = 819 };
  { key = "grindstone.shape.local_0006";                 label = "canonical_clock_6";           arity = 2; tags = ["parse"]; since = "1.2.0"; weight = 887 };
  { key = "elytra.shape.lazy_0007";                      label = "legacy_dispenser_7";          arity = 7; tags = ["hot"; "runtime"; "compat"]; since = "1.3.1"; weight = 256 };
  { key = "enchant.shape.local_0008";                    label = "stable_rail_8";               arity = 6; tags = ["cached"; "untyped"]; since = "1.3.1"; weight = 1215 };
  { key = "shield.shape.public_0009";                    label = "local_rail_9";                arity = 1; tags = ["typed"; "core"; "emit"]; since = "1.6.0"; weight = 3373 };
  { key = "arrow.shape.stable_0010";                     label = "global_beacon_10";            arity = 2; tags = ["sync"; "parse"]; since = "1.3.1"; weight = 3694 };
  { key = "banner.shape.primary_0011";                   label = "hidden_boat_11";              arity = 7; tags = ["sync"; "experimental"]; since = "1.4.0"; weight = 2361 };
  { key = "gui.shape.primary_0012";                      label = "secondary_bell_12";           arity = 5; tags = ["untyped"; "codegen"; "emit"]; since = "1.5.2"; weight = 376 };
  { key = "elytra.shape.eager_0013";                     label = "hidden_smoker_13";            arity = 7; tags = ["content"]; since = "1.9.0"; weight = 1508 };
  { key = "cartography.shape.lazy_0014";                 label = "derived_pane_14";             arity = 5; tags = ["cached"; "cold"]; since = "1.6.0"; weight = 3829 };
  { key = "spawner.shape.eager_0015";                    label = "secondary_repeater_15";       arity = 7; tags = ["emit"; "sync"; "legacy"]; since = "1.8.3"; weight = 1426 };
  { key = "hologram.shape.strict_0016";                  label = "internal_stonecutter_16";     arity = 6; tags = ["check"; "sync"]; since = "1.6.0"; weight = 2882 };
  { key = "recipe.shape.hidden_0017";                    label = "cached_particle_17";          arity = 5; tags = ["hot"; "experimental"]; since = "1.6.0"; weight = 1552 };
  { key = "player.shape.provisional_0018";               label = "stable_shulker_18";           arity = 5; tags = ["experimental"]; since = "1.0.0"; weight = 1079 };
  { key = "recipe.shape.primary_0019";                   label = "secondary_barrel_19";         arity = 6; tags = ["codegen"; "lower"]; since = "1.3.1"; weight = 3758 };
  { key = "hologram.shape.loose_0020";                   label = "canonical_gui_20";            arity = 1; tags = ["check"; "emit"; "experimental"]; since = "1.9.0"; weight = 1217 };
  { key = "block.shape.strict_0021";                     label = "eager_particle_21";           arity = 0; tags = ["packet"]; since = "1.2.0"; weight = 3371 };
  { key = "comparator.shape.fallback_0022";              label = "scoped_target_22";            arity = 4; tags = ["sync"; "cached"]; since = "1.9.0"; weight = 1859 };
  { key = "inventory.shape.primary_0023";                label = "global_clock_23";             arity = 5; tags = ["codegen"]; since = "1.9.0"; weight = 1953 };
  { key = "bundle.shape.legacy_0024";                    label = "global_bossbar_24";           arity = 3; tags = ["registry"]; since = "1.5.2"; weight = 2071 };
  { key = "portal.shape.derived_0025";                   label = "scoped_brewing_25";           arity = 2; tags = ["codegen"]; since = "1.9.0"; weight = 1379 };
  { key = "attribute.shape.global_0026";                 label = "stable_conduit_26";           arity = 4; tags = ["untyped"; "emit"]; since = "1.5.2"; weight = 3942 };
  { key = "particle.shape.scoped_0027";                  label = "scoped_smoker_27";            arity = 7; tags = ["runtime"; "async"; "lower"]; since = "1.3.1"; weight = 3687 };
  { key = "compass.shape.stable_0028";                   label = "modern_enchant_28";           arity = 7; tags = ["check"; "packet"; "async"]; since = "1.3.1"; weight = 887 };
  { key = "clock.shape.provisional_0029";                label = "secondary_firework_29";       arity = 3; tags = ["untyped"; "typed"]; since = "1.3.1"; weight = 2477 };
  { key = "conduit.shape.fallback_0030";                 label = "stable_firework_30";          arity = 3; tags = ["async"; "sync"]; since = "1.7.0"; weight = 1848 };
  { key = "hopper.shape.hidden_0031";                    label = "strict_minecart_31";          arity = 0; tags = ["experimental"; "untyped"]; since = "1.5.2"; weight = 2149 };
  { key = "bossbar.shape.stable_0032";                   label = "primary_rail_32";             arity = 0; tags = ["packet"; "compat"; "async"]; since = "1.3.1"; weight = 3964 };
  { key = "campfire.shape.scoped_0033";                  label = "primary_campfire_33";         arity = 4; tags = ["packet"; "registry"; "content"]; since = "1.0.0"; weight = 3247 };
  { key = "mob.shape.lazy_0034";                         label = "internal_target_34";          arity = 2; tags = ["codegen"; "parse"; "content"]; since = "1.3.1"; weight = 595 };
  { key = "trade.shape.strict_0035";                     label = "global_bell_35";              arity = 0; tags = ["lower"]; since = "1.3.1"; weight = 2107 };
  { key = "biome.shape.public_0036";                     label = "secondary_structure_36";      arity = 6; tags = ["sync"; "content"]; since = "1.3.1"; weight = 145 };
  { key = "mob.shape.modern_0037";                       label = "canonical_rail_37";           arity = 1; tags = ["content"; "core"]; since = "1.7.0"; weight = 1622 };
  { key = "target.shape.cached_0038";                    label = "canonical_crossbow_38";       arity = 6; tags = ["compat"; "emit"]; since = "1.0.0"; weight = 794 };
  { key = "furnace.shape.global_0039";                   label = "internal_compass_39";         arity = 3; tags = ["typed"]; since = "1.2.0"; weight = 645 };
  { key = "anvil.shape.scoped_0040";                     label = "primary_hopper_40";           arity = 4; tags = ["lower"]; since = "1.9.0"; weight = 380 };
  { key = "brewing.shape.scoped_0041";                   label = "fallback_bell_41";            arity = 4; tags = ["typed"; "async"; "codegen"]; since = "1.5.2"; weight = 674 };
  { key = "compass.shape.provisional_0042";              label = "legacy_shield_42";            arity = 5; tags = ["lower"; "runtime"]; since = "1.9.0"; weight = 722 };
  { key = "crossbow.shape.stable_0043";                  label = "loose_sound_43";              arity = 2; tags = ["cached"; "parse"]; since = "1.0.0"; weight = 1182 };
  { key = "barrel.shape.secondary_0044";                 label = "provisional_player_44";       arity = 5; tags = ["untyped"; "registry"; "async"]; since = "1.0.0"; weight = 3734 };
  { key = "compass.shape.public_0045";                   label = "stable_smoker_45";            arity = 6; tags = ["packet"; "content"; "cold"]; since = "1.4.0"; weight = 929 };
  { key = "trident.shape.modern_0046";                   label = "hidden_tablist_46";           arity = 0; tags = ["cold"; "registry"; "hot"]; since = "1.3.1"; weight = 3638 };
  { key = "world.shape.primary_0047";                    label = "lazy_item_47";                arity = 2; tags = ["runtime"; "content"; "untyped"]; since = "1.0.0"; weight = 699 };
  { key = "crossbow.shape.fallback_0048";                label = "fallback_bossbar_48";         arity = 7; tags = ["async"; "lower"]; since = "1.7.0"; weight = 482 };
  { key = "structure.shape.global_0049";                 label = "primary_bundle_49";           arity = 5; tags = ["untyped"]; since = "1.9.0"; weight = 3894 };
  { key = "portal.shape.scoped_0050";                    label = "scoped_particle_50";          arity = 0; tags = ["experimental"]; since = "1.7.0"; weight = 209 };
  { key = "chunk.shape.scoped_0051";                     label = "modern_particle_51";          arity = 0; tags = ["codegen"]; since = "1.5.2"; weight = 1780 };
  { key = "structure.shape.cached_0052";                 label = "lazy_campfire_52";            arity = 6; tags = ["registry"]; since = "1.7.0"; weight = 1886 };
  { key = "objective.shape.derived_0053";                label = "secondary_dropper_53";        arity = 2; tags = ["typed"; "runtime"]; since = "1.9.0"; weight = 1817 };
  { key = "particle.shape.provisional_0054";             label = "primary_advancement_54";      arity = 1; tags = ["experimental"; "check"; "legacy"]; since = "1.5.2"; weight = 1965 };
  { key = "entity.shape.fallback_0055";                  label = "lazy_potion_55";              arity = 0; tags = ["untyped"; "check"]; since = "1.4.0"; weight = 3829 };
  { key = "composter.shape.global_0056";                 label = "eager_player_56";             arity = 3; tags = ["typed"]; since = "1.9.0"; weight = 1971 };
  { key = "stonecutter.shape.scoped_0057";               label = "canonical_observer_57";       arity = 6; tags = ["compat"; "codegen"]; since = "1.7.0"; weight = 2726 };
  { key = "dispenser.shape.strict_0058";                 label = "stable_repeater_58";          arity = 6; tags = ["hot"; "lower"]; since = "1.8.3"; weight = 3350 };
  { key = "cartography.shape.public_0059";               label = "canonical_shield_59";         arity = 7; tags = ["untyped"; "runtime"]; since = "1.7.0"; weight = 2819 };
  { key = "world.shape.local_0060";                      label = "scoped_gui_60";               arity = 4; tags = ["untyped"]; since = "1.5.2"; weight = 1596 };
  { key = "firework.shape.provisional_0061";             label = "legacy_hopper_61";            arity = 0; tags = ["registry"]; since = "1.9.0"; weight = 231 };
  { key = "smoker.shape.global_0062";                    label = "cached_clock_62";             arity = 1; tags = ["sync"]; since = "1.8.3"; weight = 921 };
  { key = "boat.shape.canonical_0063";                   label = "cached_bundle_63";            arity = 3; tags = ["async"; "check"; "content"]; since = "1.5.2"; weight = 1138 };
  { key = "arrow.shape.primary_0064";                    label = "secondary_arrow_64";          arity = 6; tags = ["packet"]; since = "1.2.0"; weight = 3730 };
  { key = "slot.shape.public_0065";                      label = "canonical_piston_65";         arity = 5; tags = ["codegen"; "content"; "hot"]; since = "1.2.0"; weight = 41 };
  { key = "elytra.shape.derived_0066";                   label = "derived_team_66";             arity = 5; tags = ["check"; "cached"]; since = "1.5.2"; weight = 3678 };
  { key = "shield.shape.primary_0067";                   label = "lazy_item_67";                arity = 3; tags = ["legacy"]; since = "1.4.0"; weight = 84 };
  { key = "hopper.shape.loose_0068";                     label = "primary_observer_68";         arity = 7; tags = ["cached"; "parse"; "emit"]; since = "1.4.0"; weight = 3188 };
  { key = "grindstone.shape.strict_0069";                label = "derived_effect_69";           arity = 7; tags = ["codegen"]; since = "1.7.0"; weight = 446 };
  { key = "compass.shape.derived_0070";                  label = "cached_tablist_70";           arity = 5; tags = ["emit"]; since = "1.5.2"; weight = 3793 };
  { key = "grindstone.shape.public_0071";                label = "stable_dropper_71";           arity = 0; tags = ["cached"]; since = "1.2.0"; weight = 2950 };
  { key = "objective.shape.strict_0072";                 label = "secondary_crossbow_72";       arity = 5; tags = ["hot"; "codegen"]; since = "1.5.2"; weight = 2837 };
  { key = "beacon.shape.secondary_0073";                 label = "public_scoreboard_73";        arity = 1; tags = ["registry"; "core"; "runtime"]; since = "1.5.2"; weight = 485 };
  { key = "villager.shape.primary_0074";                 label = "scoped_chunk_74";             arity = 1; tags = ["experimental"; "core"]; since = "1.3.1"; weight = 2247 };
  { key = "brewing.shape.strict_0075";                   label = "eager_sound_75";              arity = 1; tags = ["hot"; "runtime"]; since = "1.2.0"; weight = 3722 };
  { key = "trade.shape.scoped_0076";                     label = "stable_trade_76";             arity = 1; tags = ["packet"; "async"; "emit"]; since = "1.9.0"; weight = 1982 };
  { key = "campfire.shape.public_0077";                  label = "cached_chunk_77";             arity = 2; tags = ["untyped"; "emit"]; since = "1.7.0"; weight = 1600 };
  { key = "boat.shape.internal_0078";                    label = "eager_rail_78";               arity = 5; tags = ["content"; "typed"; "packet"]; since = "1.2.0"; weight = 1372 };
  { key = "banner_pattern.shape.local_0079";             label = "modern_entity_79";            arity = 0; tags = ["compat"; "async"]; since = "1.0.0"; weight = 486 };
  { key = "clock.shape.strict_0080";                     label = "eager_scoreboard_80";         arity = 4; tags = ["experimental"; "runtime"]; since = "1.2.0"; weight = 3042 };
  { key = "dropper.shape.strict_0081";                   label = "loose_trade_81";              arity = 7; tags = ["registry"; "content"; "async"]; since = "1.7.0"; weight = 1739 };
  { key = "potion.shape.global_0082";                    label = "strict_brewing_82";           arity = 2; tags = ["emit"; "parse"; "compat"]; since = "1.0.0"; weight = 2402 };
  { key = "crossbow.shape.local_0083";                   label = "secondary_brewing_83";        arity = 5; tags = ["cold"; "hot"; "compat"]; since = "1.3.1"; weight = 3649 };
  { key = "effect.shape.secondary_0084";                 label = "internal_comparator_84";      arity = 3; tags = ["hot"; "async"; "legacy"]; since = "1.4.0"; weight = 1617 };
  { key = "minecart.shape.cached_0085";                  label = "local_crossbow_85";           arity = 5; tags = ["registry"]; since = "1.7.0"; weight = 1458 };
  { key = "composter.shape.stable_0086";                 label = "provisional_gui_86";          arity = 5; tags = ["typed"; "async"; "sync"]; since = "1.2.0"; weight = 243 };
  { key = "firework.shape.strict_0087";                  label = "stable_brewing_87";           arity = 1; tags = ["experimental"; "core"; "runtime"]; since = "1.2.0"; weight = 481 };
  { key = "entity.shape.derived_0088";                   label = "scoped_tablist_88";           arity = 5; tags = ["hot"; "content"]; since = "1.4.0"; weight = 2188 };
  { key = "anvil.shape.loose_0089";                      label = "global_bundle_89";            arity = 4; tags = ["legacy"; "check"; "cached"]; since = "1.3.1"; weight = 3017 };
  { key = "chunk.shape.legacy_0090";                     label = "local_beacon_90";             arity = 6; tags = ["lower"; "runtime"; "content"]; since = "1.0.0"; weight = 639 };
  { key = "conduit.shape.public_0091";                   label = "eager_scoreboard_91";         arity = 2; tags = ["untyped"; "compat"]; since = "1.4.0"; weight = 2976 };
  { key = "banner_pattern.shape.loose_0092";             label = "secondary_elytra_92";         arity = 6; tags = ["content"]; since = "1.9.0"; weight = 168 };
  { key = "inventory.shape.legacy_0093";                 label = "provisional_anvil_93";        arity = 3; tags = ["async"]; since = "1.8.3"; weight = 1213 };
  { key = "villager.shape.local_0094";                   label = "provisional_packet_94";       arity = 2; tags = ["codegen"; "async"; "typed"]; since = "1.8.3"; weight = 1468 };
  { key = "slot.shape.hidden_0095";                      label = "legacy_slot_95";              arity = 4; tags = ["parse"]; since = "1.4.0"; weight = 3382 };
  { key = "scoreboard.shape.stable_0096";                label = "scoped_bell_96";              arity = 0; tags = ["compat"; "runtime"; "typed"]; since = "1.2.0"; weight = 918 };
  { key = "furnace.shape.legacy_0097";                   label = "legacy_barrel_97";            arity = 5; tags = ["cold"; "core"; "content"]; since = "1.5.2"; weight = 2749 };
  { key = "rail.shape.modern_0098";                      label = "eager_banner_pattern_98";     arity = 6; tags = ["untyped"; "packet"; "hot"]; since = "1.6.0"; weight = 2486 };
  { key = "entity.shape.eager_0099";                     label = "primary_item_99";             arity = 0; tags = ["sync"; "core"; "untyped"]; since = "1.2.0"; weight = 2248 };
  { key = "boat.shape.public_0100";                      label = "hidden_player_100";           arity = 2; tags = ["cold"]; since = "1.4.0"; weight = 3815 };
  { key = "smoker.shape.hidden_0101";                    label = "modern_bundle_101";           arity = 4; tags = ["runtime"; "registry"]; since = "1.0.0"; weight = 4080 };
  { key = "arrow.shape.cached_0102";                     label = "global_inventory_102";        arity = 7; tags = ["cold"]; since = "1.2.0"; weight = 1268 };
  { key = "composter.shape.modern_0103";                 label = "fallback_chunk_103";          arity = 2; tags = ["core"; "emit"]; since = "1.6.0"; weight = 398 };
  { key = "smoker.shape.public_0104";                    label = "stable_enchant_104";          arity = 1; tags = ["untyped"; "experimental"]; since = "1.7.0"; weight = 2025 };
  { key = "target.shape.secondary_0105";                 label = "loose_packet_105";            arity = 6; tags = ["content"; "typed"]; since = "1.6.0"; weight = 3252 };
  { key = "potion.shape.derived_0106";                   label = "legacy_clock_106";            arity = 0; tags = ["experimental"]; since = "1.6.0"; weight = 600 };
  { key = "attribute.shape.fallback_0107";               label = "local_region_107";            arity = 2; tags = ["registry"; "legacy"; "packet"]; since = "1.7.0"; weight = 1981 };
  { key = "stonecutter.shape.loose_0108";                label = "canonical_recipe_108";        arity = 6; tags = ["parse"; "typed"]; since = "1.3.1"; weight = 3133 };
  { key = "region.shape.strict_0109";                    label = "secondary_team_109";          arity = 2; tags = ["untyped"]; since = "1.7.0"; weight = 2819 };
  { key = "player.shape.stable_0110";                    label = "scoped_stonecutter_110";      arity = 1; tags = ["async"]; since = "1.3.1"; weight = 2017 };
  { key = "advancement.shape.canonical_0111";            label = "canonical_composter_111";     arity = 0; tags = ["async"; "runtime"]; since = "1.4.0"; weight = 4 };
  { key = "scoreboard.shape.derived_0112";               label = "internal_repeater_112";       arity = 7; tags = ["cold"; "content"]; since = "1.7.0"; weight = 1873 };
  { key = "minecart.shape.cached_0113";                  label = "legacy_recipe_113";           arity = 7; tags = ["check"; "registry"]; since = "1.7.0"; weight = 3729 };
  { key = "inventory.shape.global_0114";                 label = "hidden_minecart_114";         arity = 2; tags = ["parse"]; since = "1.9.0"; weight = 3067 };
  { key = "trade.shape.provisional_0115";                label = "loose_loom_115";              arity = 2; tags = ["runtime"]; since = "1.6.0"; weight = 1886 };
  { key = "compass.shape.stable_0116";                   label = "public_brewing_116";          arity = 2; tags = ["check"; "hot"]; since = "1.4.0"; weight = 1719 };
  { key = "beacon.shape.stable_0117";                    label = "cached_comparator_117";       arity = 2; tags = ["async"; "packet"]; since = "1.7.0"; weight = 671 };
  { key = "lectern.shape.lazy_0118";                     label = "modern_elytra_118";           arity = 6; tags = ["lower"]; since = "1.8.3"; weight = 2976 };
  { key = "barrel.shape.lazy_0119";                      label = "eager_packet_119";            arity = 1; tags = ["emit"; "core"; "hot"]; since = "1.3.1"; weight = 580 };
  { key = "lectern.shape.local_0120";                    label = "hidden_minecart_120";         arity = 1; tags = ["codegen"]; since = "1.6.0"; weight = 1385 };
  { key = "bossbar.shape.global_0121";                   label = "fallback_cartography_121";    arity = 0; tags = ["cached"; "runtime"]; since = "1.7.0"; weight = 2183 };
  { key = "lectern.shape.lazy_0122";                     label = "derived_elytra_122";          arity = 2; tags = ["typed"; "parse"; "registry"]; since = "1.8.3"; weight = 349 };
  { key = "comparator.shape.local_0123";                 label = "cached_repeater_123";         arity = 7; tags = ["cold"; "lower"]; since = "1.8.3"; weight = 3935 };
  { key = "comparator.shape.loose_0124";                 label = "strict_bell_124";             arity = 6; tags = ["parse"]; since = "1.9.0"; weight = 4005 };
  { key = "firework.shape.strict_0125";                  label = "strict_biome_125";            arity = 0; tags = ["cached"; "packet"]; since = "1.6.0"; weight = 478 };
  { key = "minecart.shape.hidden_0126";                  label = "canonical_conduit_126";       arity = 4; tags = ["cold"]; since = "1.2.0"; weight = 3464 };
  { key = "villager.shape.scoped_0127";                  label = "strict_dispenser_127";        arity = 5; tags = ["sync"; "legacy"]; since = "1.3.1"; weight = 3193 };
  { key = "barrel.shape.stable_0128";                    label = "local_npc_128";               arity = 0; tags = ["runtime"; "legacy"; "cold"]; since = "1.0.0"; weight = 908 };
  { key = "spawner.shape.global_0129";                   label = "scoped_pane_129";             arity = 4; tags = ["cold"]; since = "1.9.0"; weight = 1651 };
  { key = "beacon.shape.public_0130";                    label = "local_loom_130";              arity = 1; tags = ["legacy"]; since = "1.9.0"; weight = 1660 };
  { key = "packet.shape.eager_0131";                     label = "stable_shield_131";           arity = 7; tags = ["check"; "lower"]; since = "1.5.2"; weight = 3051 };
  { key = "map.shape.legacy_0132";                       label = "primary_shulker_132";         arity = 5; tags = ["runtime"]; since = "1.3.1"; weight = 1671 };
  { key = "world.shape.cached_0133";                     label = "scoped_objective_133";        arity = 2; tags = ["packet"; "parse"]; since = "1.0.0"; weight = 3661 };
  { key = "bundle.shape.global_0134";                    label = "eager_entity_134";            arity = 7; tags = ["cold"; "untyped"]; since = "1.8.3"; weight = 1475 };
  { key = "sound.shape.cached_0135";                     label = "public_firework_135";         arity = 3; tags = ["check"]; since = "1.2.0"; weight = 1732 };
  { key = "sound.shape.canonical_0136";                  label = "scoped_trident_136";          arity = 3; tags = ["lower"]; since = "1.2.0"; weight = 2325 };
  { key = "spawner.shape.internal_0137";                 label = "global_map_137";              arity = 3; tags = ["core"; "legacy"]; since = "1.3.1"; weight = 507 };
  { key = "shield.shape.stable_0138";                    label = "legacy_piston_138";           arity = 0; tags = ["hot"; "runtime"]; since = "1.8.3"; weight = 3461 };
  { key = "barrel.shape.primary_0139";                   label = "modern_campfire_139";         arity = 0; tags = ["legacy"]; since = "1.9.0"; weight = 1882 };
  { key = "smoker.shape.secondary_0140";                 label = "stable_cartography_140";      arity = 0; tags = ["cached"; "cold"; "core"]; since = "1.9.0"; weight = 2834 };
  { key = "pane.shape.fallback_0141";                    label = "derived_team_141";            arity = 1; tags = ["check"; "async"]; since = "1.5.2"; weight = 1341 };
  { key = "block.shape.eager_0142";                      label = "fallback_chunk_142";          arity = 7; tags = ["codegen"; "check"; "packet"]; since = "1.6.0"; weight = 58 };
  { key = "attribute.shape.strict_0143";                 label = "stable_stonecutter_143";      arity = 2; tags = ["lower"; "check"; "typed"]; since = "1.3.1"; weight = 2007 };
  { key = "trade.shape.modern_0144";                     label = "local_effect_144";            arity = 0; tags = ["codegen"; "untyped"]; since = "1.5.2"; weight = 2757 };
  { key = "stonecutter.shape.hidden_0145";               label = "modern_stonecutter_145";      arity = 3; tags = ["content"]; since = "1.3.1"; weight = 3572 };
  { key = "block.shape.internal_0146";                   label = "eager_furnace_146";           arity = 4; tags = ["experimental"; "core"]; since = "1.2.0"; weight = 2548 };
  { key = "region.shape.legacy_0147";                    label = "eager_structure_147";         arity = 2; tags = ["lower"; "legacy"]; since = "1.2.0"; weight = 359 };
  { key = "bell.shape.global_0148";                      label = "derived_banner_pattern_148";  arity = 3; tags = ["codegen"; "experimental"]; since = "1.3.1"; weight = 3684 };
  { key = "firework.shape.derived_0149";                 label = "loose_spawner_149";           arity = 4; tags = ["lower"; "compat"; "async"]; since = "1.0.0"; weight = 2957 };
  { key = "firework.shape.eager_0150";                   label = "secondary_gui_150";           arity = 2; tags = ["untyped"]; since = "1.6.0"; weight = 3489 };
  { key = "grindstone.shape.fallback_0151";              label = "loose_minecart_151";          arity = 4; tags = ["typed"; "runtime"]; since = "1.7.0"; weight = 896 };
  { key = "team.shape.stable_0152";                      label = "internal_team_152";           arity = 6; tags = ["cached"; "core"; "codegen"]; since = "1.5.2"; weight = 3199 };
  { key = "elytra.shape.secondary_0153";                 label = "cached_firework_153";         arity = 1; tags = ["check"; "sync"]; since = "1.7.0"; weight = 3434 };
  { key = "biome.shape.strict_0154";                     label = "strict_banner_154";           arity = 4; tags = ["check"; "lower"]; since = "1.2.0"; weight = 894 };
  { key = "pane.shape.stable_0155";                      label = "lazy_sound_155";              arity = 2; tags = ["registry"; "lower"; "runtime"]; since = "1.3.1"; weight = 661 };
  { key = "pane.shape.public_0156";                      label = "canonical_loom_156";          arity = 4; tags = ["typed"; "check"]; since = "1.6.0"; weight = 657 };
  { key = "shield.shape.canonical_0157";                 label = "scoped_smithing_157";         arity = 0; tags = ["registry"; "lower"]; since = "1.9.0"; weight = 4019 };
  { key = "smoker.shape.loose_0158";                     label = "fallback_campfire_158";       arity = 1; tags = ["registry"; "emit"]; since = "1.7.0"; weight = 2028 };
  { key = "smithing.shape.secondary_0159";               label = "lazy_banner_pattern_159";     arity = 7; tags = ["async"]; since = "1.0.0"; weight = 3507 };
  { key = "entity.shape.provisional_0160";               label = "cached_team_160";             arity = 6; tags = ["experimental"]; since = "1.4.0"; weight = 3048 };
  { key = "crossbow.shape.provisional_0161";             label = "derived_particle_161";        arity = 6; tags = ["registry"]; since = "1.9.0"; weight = 1897 };
  { key = "lectern.shape.eager_0162";                    label = "fallback_scoreboard_162";     arity = 5; tags = ["cached"]; since = "1.4.0"; weight = 348 };
  { key = "inventory.shape.primary_0163";                label = "lazy_portal_163";             arity = 1; tags = ["packet"]; since = "1.0.0"; weight = 2591 };
  { key = "bell.shape.stable_0164";                      label = "eager_comparator_164";        arity = 2; tags = ["runtime"; "sync"]; since = "1.2.0"; weight = 3058 };
  { key = "hologram.shape.lazy_0165";                    label = "canonical_minecart_165";      arity = 6; tags = ["codegen"; "registry"; "lower"]; since = "1.4.0"; weight = 1267 };
  { key = "firework.shape.modern_0166";                  label = "provisional_banner_pattern_166"; arity = 2; tags = ["packet"; "compat"]; since = "1.2.0"; weight = 1515 };
  { key = "boat.shape.strict_0167";                      label = "provisional_firework_167";    arity = 3; tags = ["typed"]; since = "1.3.1"; weight = 1342 };
  { key = "trade.shape.loose_0168";                      label = "legacy_composter_168";        arity = 4; tags = ["sync"]; since = "1.8.3"; weight = 1441 };
  { key = "anvil.shape.fallback_0169";                   label = "stable_smithing_169";         arity = 6; tags = ["parse"; "sync"; "codegen"]; since = "1.4.0"; weight = 2325 };
  { key = "structure.shape.internal_0170";               label = "hidden_villager_170";         arity = 2; tags = ["legacy"; "async"; "registry"]; since = "1.4.0"; weight = 2369 };
  { key = "target.shape.local_0171";                     label = "cached_bell_171";             arity = 7; tags = ["async"; "compat"; "codegen"]; since = "1.8.3"; weight = 1975 };
  { key = "map.shape.local_0172";                        label = "scoped_stonecutter_172";      arity = 6; tags = ["parse"; "typed"; "hot"]; since = "1.8.3"; weight = 3035 };
  { key = "map.shape.primary_0173";                      label = "stable_shield_173";           arity = 3; tags = ["runtime"]; since = "1.4.0"; weight = 932 };
  { key = "rail.shape.secondary_0174";                   label = "scoped_map_174";              arity = 1; tags = ["cold"; "core"; "hot"]; since = "1.9.0"; weight = 2788 };
  { key = "beacon.shape.secondary_0175";                 label = "internal_bossbar_175";        arity = 3; tags = ["codegen"]; since = "1.6.0"; weight = 4086 };
  { key = "portal.shape.provisional_0176";               label = "cached_tablist_176";          arity = 2; tags = ["packet"]; since = "1.2.0"; weight = 2972 };
  { key = "banner.shape.provisional_0177";               label = "derived_mob_177";             arity = 1; tags = ["runtime"; "check"]; since = "1.6.0"; weight = 859 };
  { key = "slot.shape.secondary_0178";                   label = "loose_arrow_178";             arity = 7; tags = ["registry"; "codegen"]; since = "1.6.0"; weight = 3533 };
  { key = "enchant.shape.public_0179";                   label = "public_cartography_179";      arity = 6; tags = ["emit"]; since = "1.9.0"; weight = 1278 };
  { key = "banner_pattern.shape.stable_0180";            label = "secondary_smithing_180";      arity = 4; tags = ["registry"]; since = "1.6.0"; weight = 2311 };
  { key = "grindstone.shape.eager_0181";                 label = "hidden_composter_181";        arity = 7; tags = ["sync"]; since = "1.5.2"; weight = 3252 };
  { key = "player.shape.stable_0182";                    label = "provisional_map_182";         arity = 3; tags = ["untyped"; "emit"; "parse"]; since = "1.9.0"; weight = 2837 };
  { key = "enchant.shape.internal_0183";                 label = "stable_shulker_183";          arity = 7; tags = ["content"]; since = "1.0.0"; weight = 2577 };
  { key = "comparator.shape.derived_0184";               label = "loose_villager_184";          arity = 5; tags = ["async"]; since = "1.6.0"; weight = 4040 };
  { key = "inventory.shape.fallback_0185";               label = "scoped_barrel_185";           arity = 2; tags = ["packet"; "core"; "sync"]; since = "1.0.0"; weight = 3805 };
  { key = "barrel.shape.global_0186";                    label = "global_cartography_186";      arity = 7; tags = ["compat"]; since = "1.4.0"; weight = 932 };
  { key = "stonecutter.shape.stable_0187";               label = "modern_composter_187";        arity = 6; tags = ["registry"; "codegen"]; since = "1.4.0"; weight = 1819 };
  { key = "advancement.shape.hidden_0188";               label = "loose_advancement_188";       arity = 2; tags = ["experimental"]; since = "1.0.0"; weight = 2167 };
  { key = "furnace.shape.cached_0189";                   label = "internal_bell_189";           arity = 1; tags = ["codegen"; "experimental"]; since = "1.2.0"; weight = 1829 };
  { key = "portal.shape.lazy_0190";                      label = "strict_trade_190";            arity = 1; tags = ["sync"]; since = "1.4.0"; weight = 3677 };
  { key = "sound.shape.scoped_0191";                     label = "strict_gui_191";              arity = 7; tags = ["lower"; "hot"]; since = "1.4.0"; weight = 513 };
  { key = "loom.shape.stable_0192";                      label = "derived_bundle_192";          arity = 0; tags = ["compat"; "hot"]; since = "1.5.2"; weight = 3122 };
  { key = "inventory.shape.secondary_0193";              label = "primary_slot_193";            arity = 4; tags = ["compat"]; since = "1.0.0"; weight = 1937 };
  { key = "grindstone.shape.hidden_0194";                label = "legacy_attribute_194";        arity = 6; tags = ["async"]; since = "1.2.0"; weight = 1556 };
  { key = "enchant.shape.modern_0195";                   label = "eager_banner_pattern_195";    arity = 1; tags = ["content"]; since = "1.4.0"; weight = 2656 };
  { key = "shulker.shape.canonical_0196";                label = "stable_structure_196";        arity = 7; tags = ["untyped"; "emit"]; since = "1.8.3"; weight = 2525 };
  { key = "conduit.shape.eager_0197";                    label = "fallback_effect_197";         arity = 6; tags = ["experimental"]; since = "1.9.0"; weight = 2016 };
  { key = "slot.shape.lazy_0198";                        label = "cached_item_198";             arity = 7; tags = ["parse"; "codegen"]; since = "1.0.0"; weight = 2243 };
  { key = "enchant.shape.eager_0199";                    label = "eager_sound_199";             arity = 0; tags = ["codegen"; "packet"; "async"]; since = "1.6.0"; weight = 2566 };
  { key = "particle.shape.internal_0200";                label = "cached_anvil_200";            arity = 7; tags = ["untyped"; "check"]; since = "1.3.1"; weight = 702 };
  { key = "scoreboard.shape.stable_0201";                label = "scoped_banner_pattern_201";   arity = 1; tags = ["content"; "legacy"; "emit"]; since = "1.9.0"; weight = 1170 };
  { key = "arrow.shape.eager_0202";                      label = "eager_slot_202";              arity = 2; tags = ["typed"; "experimental"]; since = "1.3.1"; weight = 3042 };
  { key = "entity.shape.public_0203";                    label = "lazy_potion_203";             arity = 4; tags = ["packet"; "runtime"]; since = "1.2.0"; weight = 773 };
  { key = "banner_pattern.shape.strict_0204";            label = "public_item_204";             arity = 0; tags = ["sync"; "runtime"]; since = "1.2.0"; weight = 3892 };
  { key = "target.shape.stable_0205";                    label = "hidden_piston_205";           arity = 7; tags = ["lower"; "legacy"; "core"]; since = "1.5.2"; weight = 2906 };
  { key = "observer.shape.eager_0206";                   label = "fallback_loom_206";           arity = 1; tags = ["compat"]; since = "1.4.0"; weight = 1933 };
  { key = "dropper.shape.internal_0207";                 label = "internal_objective_207";      arity = 3; tags = ["packet"; "cached"; "untyped"]; since = "1.8.3"; weight = 285 };
  { key = "arrow.shape.scoped_0208";                     label = "primary_shield_208";          arity = 4; tags = ["cached"; "hot"]; since = "1.6.0"; weight = 1101 };
  { key = "trade.shape.cached_0209";                     label = "lazy_particle_209";           arity = 0; tags = ["hot"; "experimental"; "registry"]; since = "1.8.3"; weight = 1205 };
  { key = "banner.shape.local_0210";                     label = "derived_target_210";          arity = 0; tags = ["compat"]; since = "1.8.3"; weight = 1496 };
  { key = "grindstone.shape.eager_0211";                 label = "hidden_smoker_211";           arity = 3; tags = ["packet"; "experimental"; "registry"]; since = "1.9.0"; weight = 3620 };
  { key = "campfire.shape.global_0212";                  label = "modern_block_212";            arity = 4; tags = ["async"; "compat"]; since = "1.5.2"; weight = 2556 };
  { key = "conduit.shape.scoped_0213";                   label = "internal_hologram_213";       arity = 2; tags = ["experimental"; "compat"; "packet"]; since = "1.3.1"; weight = 3566 };
  { key = "recipe.shape.secondary_0214";                 label = "global_scoreboard_214";       arity = 3; tags = ["check"; "sync"]; since = "1.9.0"; weight = 2556 };
  { key = "bossbar.shape.lazy_0215";                     label = "legacy_furnace_215";          arity = 2; tags = ["sync"; "experimental"]; since = "1.6.0"; weight = 3519 };
  { key = "map.shape.derived_0216";                      label = "stable_dispenser_216";        arity = 7; tags = ["untyped"]; since = "1.4.0"; weight = 3058 };
  { key = "firework.shape.derived_0217";                 label = "scoped_effect_217";           arity = 5; tags = ["legacy"; "registry"]; since = "1.7.0"; weight = 2330 };
  { key = "elytra.shape.modern_0218";                    label = "loose_furnace_218";           arity = 7; tags = ["hot"; "cached"]; since = "1.2.0"; weight = 2354 };
  { key = "dispenser.shape.provisional_0219";            label = "global_player_219";           arity = 4; tags = ["async"; "parse"; "experimental"]; since = "1.9.0"; weight = 3842 };
  { key = "pane.shape.lazy_0220";                        label = "public_packet_220";           arity = 1; tags = ["legacy"]; since = "1.6.0"; weight = 2595 };
  { key = "bossbar.shape.loose_0221";                    label = "strict_tablist_221";          arity = 5; tags = ["async"; "check"; "cached"]; since = "1.3.1"; weight = 3996 };
  { key = "trident.shape.secondary_0222";                label = "lazy_pane_222";               arity = 4; tags = ["core"]; since = "1.6.0"; weight = 3171 };
  { key = "attribute.shape.derived_0223";                label = "cached_pane_223";             arity = 1; tags = ["packet"]; since = "1.3.1"; weight = 3638 };
  { key = "boat.shape.stable_0224";                      label = "secondary_attribute_224";     arity = 6; tags = ["cold"; "typed"; "runtime"]; since = "1.7.0"; weight = 2813 };
  { key = "lectern.shape.local_0225";                    label = "lazy_banner_pattern_225";     arity = 3; tags = ["parse"]; since = "1.8.3"; weight = 2411 };
  { key = "barrel.shape.derived_0226";                   label = "modern_furnace_226";          arity = 0; tags = ["content"]; since = "1.9.0"; weight = 2760 };
  { key = "piston.shape.fallback_0227";                  label = "strict_beacon_227";           arity = 3; tags = ["parse"]; since = "1.6.0"; weight = 308 };
  { key = "arrow.shape.primary_0228";                    label = "provisional_elytra_228";      arity = 0; tags = ["async"; "runtime"]; since = "1.5.2"; weight = 993 };
  { key = "anvil.shape.strict_0229";                     label = "hidden_structure_229";        arity = 2; tags = ["lower"; "emit"]; since = "1.0.0"; weight = 1865 };
  { key = "bundle.shape.lazy_0230";                      label = "secondary_structure_230";     arity = 3; tags = ["experimental"; "untyped"; "compat"]; since = "1.0.0"; weight = 1921 };
  { key = "arrow.shape.internal_0231";                   label = "canonical_scoreboard_231";    arity = 4; tags = ["sync"; "parse"; "typed"]; since = "1.0.0"; weight = 194 };
  { key = "shield.shape.derived_0232";                   label = "hidden_boat_232";             arity = 1; tags = ["hot"; "lower"; "packet"]; since = "1.9.0"; weight = 1477 };
  { key = "dropper.shape.loose_0233";                    label = "stable_hopper_233";           arity = 7; tags = ["cold"; "hot"; "registry"]; since = "1.9.0"; weight = 392 };
  { key = "boat.shape.primary_0234";                     label = "loose_bell_234";              arity = 3; tags = ["compat"; "hot"; "sync"]; since = "1.2.0"; weight = 151 };
  { key = "boat.shape.fallback_0235";                    label = "local_trade_235";             arity = 5; tags = ["async"]; since = "1.2.0"; weight = 1528 };
  { key = "npc.shape.loose_0236";                        label = "loose_bell_236";              arity = 4; tags = ["legacy"]; since = "1.7.0"; weight = 2803 };
  { key = "observer.shape.provisional_0237";             label = "canonical_entity_237";        arity = 4; tags = ["check"; "content"]; since = "1.0.0"; weight = 1037 };
  { key = "hologram.shape.derived_0238";                 label = "lazy_packet_238";             arity = 3; tags = ["emit"]; since = "1.4.0"; weight = 369 };
  { key = "gui.shape.local_0239";                        label = "lazy_map_239";                arity = 2; tags = ["lower"; "packet"; "compat"]; since = "1.5.2"; weight = 439 };
  { key = "hologram.shape.hidden_0240";                  label = "provisional_dropper_240";     arity = 5; tags = ["packet"; "hot"]; since = "1.6.0"; weight = 693 };
  { key = "entity.shape.scoped_0241";                    label = "loose_comparator_241";        arity = 3; tags = ["legacy"; "core"; "parse"]; since = "1.7.0"; weight = 837 };
  { key = "barrel.shape.eager_0242";                     label = "strict_smithing_242";         arity = 2; tags = ["emit"]; since = "1.6.0"; weight = 3897 };
  { key = "rail.shape.scoped_0243";                      label = "modern_shield_243";           arity = 4; tags = ["parse"]; since = "1.5.2"; weight = 4040 };
  { key = "advancement.shape.primary_0244";              label = "loose_structure_244";         arity = 7; tags = ["parse"; "core"; "typed"]; since = "1.6.0"; weight = 2208 };
  { key = "spawner.shape.hidden_0245";                   label = "local_structure_245";         arity = 0; tags = ["untyped"; "registry"]; since = "1.5.2"; weight = 2162 };
  { key = "attribute.shape.legacy_0246";                 label = "local_player_246";            arity = 4; tags = ["hot"; "content"]; since = "1.0.0"; weight = 3347 };
  { key = "observer.shape.global_0247";                  label = "fallback_compass_247";        arity = 4; tags = ["cold"; "typed"; "core"]; since = "1.8.3"; weight = 2336 };
  { key = "world.shape.global_0248";                     label = "derived_portal_248";          arity = 2; tags = ["experimental"; "registry"]; since = "1.8.3"; weight = 1781 };
  { key = "structure.shape.provisional_0249";            label = "modern_hopper_249";           arity = 7; tags = ["parse"]; since = "1.5.2"; weight = 535 };
  { key = "hologram.shape.fallback_0250";                label = "loose_beacon_250";            arity = 7; tags = ["experimental"]; since = "1.2.0"; weight = 1360 };
  { key = "packet.shape.canonical_0251";                 label = "stable_tablist_251";          arity = 2; tags = ["check"; "typed"]; since = "1.2.0"; weight = 3691 };
  { key = "map.shape.stable_0252";                       label = "loose_scoreboard_252";        arity = 0; tags = ["emit"; "cached"; "sync"]; since = "1.0.0"; weight = 3521 };
  { key = "comparator.shape.local_0253";                 label = "local_dispenser_253";         arity = 4; tags = ["registry"]; since = "1.7.0"; weight = 3431 };
  { key = "loom.shape.global_0254";                      label = "strict_potion_254";           arity = 6; tags = ["content"; "runtime"; "registry"]; since = "1.2.0"; weight = 1746 };
  { key = "composter.shape.secondary_0255";              label = "public_shulker_255";          arity = 0; tags = ["registry"; "sync"; "cold"]; since = "1.4.0"; weight = 2711 };
  { key = "dispenser.shape.modern_0256";                 label = "internal_trade_256";          arity = 0; tags = ["hot"; "content"]; since = "1.5.2"; weight = 342 };
  { key = "shield.shape.cached_0257";                    label = "public_portal_257";           arity = 1; tags = ["runtime"; "legacy"]; since = "1.2.0"; weight = 128 };
  { key = "lectern.shape.secondary_0258";                label = "primary_trident_258";         arity = 1; tags = ["compat"; "cold"; "untyped"]; since = "1.3.1"; weight = 740 };
  { key = "campfire.shape.cached_0259";                  label = "eager_comparator_259";        arity = 0; tags = ["sync"]; since = "1.0.0"; weight = 1754 };
  { key = "mob.shape.legacy_0260";                       label = "internal_sound_260";          arity = 6; tags = ["typed"; "experimental"]; since = "1.6.0"; weight = 2902 };
  { key = "villager.shape.lazy_0261";                    label = "derived_smithing_261";        arity = 4; tags = ["typed"]; since = "1.9.0"; weight = 2109 };
  { key = "conduit.shape.derived_0262";                  label = "strict_objective_262";        arity = 0; tags = ["core"; "check"; "sync"]; since = "1.6.0"; weight = 874 };
  { key = "beacon.shape.public_0263";                    label = "cached_smithing_263";         arity = 6; tags = ["sync"; "content"]; since = "1.2.0"; weight = 3644 };
  { key = "shield.shape.stable_0264";                    label = "modern_brewing_264";          arity = 5; tags = ["core"; "async"]; since = "1.0.0"; weight = 1223 };
  { key = "boat.shape.fallback_0265";                    label = "cached_potion_265";           arity = 3; tags = ["packet"; "cached"]; since = "1.2.0"; weight = 3121 };
  { key = "npc.shape.internal_0266";                     label = "fallback_minecart_266";       arity = 0; tags = ["check"; "cached"; "experimental"]; since = "1.7.0"; weight = 1430 };
  { key = "furnace.shape.legacy_0267";                   label = "primary_spawner_267";         arity = 0; tags = ["typed"; "sync"; "lower"]; since = "1.5.2"; weight = 1783 };
  { key = "anvil.shape.loose_0268";                      label = "hidden_firework_268";         arity = 3; tags = ["legacy"; "experimental"]; since = "1.3.1"; weight = 924 };
  { key = "banner_pattern.shape.derived_0269";           label = "eager_smithing_269";          arity = 5; tags = ["parse"; "codegen"; "typed"]; since = "1.0.0"; weight = 2195 };
  { key = "anvil.shape.lazy_0270";                       label = "public_stonecutter_270";      arity = 2; tags = ["sync"; "lower"; "check"]; since = "1.8.3"; weight = 3882 };
  { key = "team.shape.lazy_0271";                        label = "provisional_scoreboard_271";  arity = 0; tags = ["hot"; "compat"; "cached"]; since = "1.9.0"; weight = 98 };
  { key = "piston.shape.provisional_0272";               label = "internal_trident_272";        arity = 6; tags = ["cached"; "content"; "parse"]; since = "1.2.0"; weight = 3845 };
  { key = "enchant.shape.global_0273";                   label = "global_furnace_273";          arity = 3; tags = ["cached"; "check"]; since = "1.0.0"; weight = 1630 };
  { key = "shield.shape.lazy_0274";                      label = "secondary_dropper_274";       arity = 7; tags = ["lower"; "typed"]; since = "1.0.0"; weight = 110 };
  { key = "slot.shape.eager_0275";                       label = "primary_barrel_275";          arity = 1; tags = ["check"; "core"; "emit"]; since = "1.8.3"; weight = 250 };
  { key = "portal.shape.secondary_0276";                 label = "provisional_inventory_276";   arity = 2; tags = ["check"; "registry"]; since = "1.5.2"; weight = 368 };
  { key = "tablist.shape.loose_0277";                    label = "strict_bundle_277";           arity = 5; tags = ["codegen"; "parse"; "compat"]; since = "1.4.0"; weight = 2911 };
  { key = "minecart.shape.internal_0278";                label = "scoped_advancement_278";      arity = 6; tags = ["lower"; "untyped"]; since = "1.7.0"; weight = 2202 };
  { key = "recipe.shape.secondary_0279";                 label = "modern_objective_279";        arity = 1; tags = ["typed"]; since = "1.3.1"; weight = 1569 };
  { key = "observer.shape.stable_0280";                  label = "fallback_piston_280";         arity = 0; tags = ["check"; "legacy"; "packet"]; since = "1.3.1"; weight = 3638 };
  { key = "npc.shape.stable_0281";                       label = "stable_repeater_281";         arity = 3; tags = ["core"]; since = "1.2.0"; weight = 2625 };
  { key = "region.shape.stable_0282";                    label = "local_target_282";            arity = 2; tags = ["sync"; "cold"]; since = "1.9.0"; weight = 1735 };
  { key = "entity.shape.local_0283";                     label = "modern_cartography_283";      arity = 5; tags = ["typed"]; since = "1.9.0"; weight = 2355 };
  { key = "hopper.shape.scoped_0284";                    label = "primary_trade_284";           arity = 5; tags = ["parse"; "runtime"; "check"]; since = "1.0.0"; weight = 1338 };
  { key = "structure.shape.local_0285";                  label = "internal_cartography_285";    arity = 3; tags = ["content"]; since = "1.3.1"; weight = 2193 };
  { key = "bundle.shape.loose_0286";                     label = "eager_minecart_286";          arity = 3; tags = ["typed"]; since = "1.3.1"; weight = 1270 };
  { key = "observer.shape.lazy_0287";                    label = "canonical_lectern_287";       arity = 2; tags = ["content"; "check"; "experimental"]; since = "1.8.3"; weight = 642 };
  { key = "lectern.shape.secondary_0288";                label = "stable_villager_288";         arity = 6; tags = ["parse"]; since = "1.7.0"; weight = 462 };
  { key = "scoreboard.shape.cached_0289";                label = "scoped_crossbow_289";         arity = 1; tags = ["hot"; "runtime"]; since = "1.5.2"; weight = 2635 };
  { key = "composter.shape.provisional_0290";            label = "fallback_item_290";           arity = 5; tags = ["async"; "cached"; "runtime"]; since = "1.6.0"; weight = 182 };
  { key = "crossbow.shape.scoped_0291";                  label = "internal_banner_291";         arity = 2; tags = ["sync"; "parse"; "codegen"]; since = "1.9.0"; weight = 2212 };
  { key = "grindstone.shape.cached_0292";                label = "primary_bossbar_292";         arity = 0; tags = ["registry"; "packet"]; since = "1.9.0"; weight = 2240 };
  { key = "smoker.shape.fallback_0293";                  label = "hidden_compass_293";          arity = 6; tags = ["emit"]; since = "1.6.0"; weight = 2056 };
  { key = "npc.shape.local_0294";                        label = "local_repeater_294";          arity = 7; tags = ["legacy"]; since = "1.8.3"; weight = 1789 };
  { key = "elytra.shape.legacy_0295";                    label = "canonical_shulker_295";       arity = 7; tags = ["legacy"]; since = "1.7.0"; weight = 2733 };
  { key = "sound.shape.canonical_0296";                  label = "local_minecart_296";          arity = 2; tags = ["legacy"; "parse"; "untyped"]; since = "1.7.0"; weight = 2886 };
  { key = "beacon.shape.modern_0297";                    label = "internal_campfire_297";       arity = 3; tags = ["content"; "compat"]; since = "1.9.0"; weight = 783 };
  { key = "lectern.shape.canonical_0298";                label = "loose_loom_298";              arity = 0; tags = ["hot"; "core"; "cold"]; since = "1.2.0"; weight = 1785 };
  { key = "cartography.shape.strict_0299";               label = "legacy_region_299";           arity = 4; tags = ["untyped"]; since = "1.6.0"; weight = 1271 };
  { key = "anvil.shape.provisional_0300";                label = "fallback_bossbar_300";        arity = 3; tags = ["registry"; "check"; "runtime"]; since = "1.2.0"; weight = 3164 };
  { key = "effect.shape.local_0301";                     label = "local_villager_301";          arity = 2; tags = ["untyped"; "runtime"; "lower"]; since = "1.8.3"; weight = 2806 };
  { key = "item.shape.eager_0302";                       label = "internal_banner_pattern_302"; arity = 7; tags = ["async"; "content"; "emit"]; since = "1.9.0"; weight = 3404 };
  { key = "scoreboard.shape.global_0303";                label = "hidden_advancement_303";      arity = 7; tags = ["lower"; "typed"]; since = "1.0.0"; weight = 973 };
  { key = "region.shape.scoped_0304";                    label = "internal_packet_304";         arity = 0; tags = ["cached"; "parse"; "hot"]; since = "1.8.3"; weight = 1388 };
  { key = "objective.shape.strict_0305";                 label = "secondary_attribute_305";     arity = 0; tags = ["experimental"; "registry"]; since = "1.9.0"; weight = 833 };
  { key = "rail.shape.strict_0306";                      label = "global_observer_306";         arity = 2; tags = ["lower"]; since = "1.9.0"; weight = 943 };
  { key = "shulker.shape.derived_0307";                  label = "canonical_minecart_307";      arity = 4; tags = ["codegen"]; since = "1.4.0"; weight = 1342 };
  { key = "smoker.shape.provisional_0308";               label = "global_world_308";            arity = 6; tags = ["legacy"; "parse"; "cold"]; since = "1.3.1"; weight = 1232 };
  { key = "loom.shape.strict_0309";                      label = "fallback_composter_309";      arity = 7; tags = ["packet"; "emit"; "async"]; since = "1.6.0"; weight = 2926 };
  { key = "observer.shape.derived_0310";                 label = "canonical_anvil_310";         arity = 7; tags = ["check"; "hot"]; since = "1.7.0"; weight = 2797 };
  { key = "arrow.shape.canonical_0311";                  label = "fallback_structure_311";      arity = 4; tags = ["check"]; since = "1.8.3"; weight = 2151 };
  { key = "attribute.shape.derived_0312";                label = "strict_smoker_312";           arity = 3; tags = ["cached"]; since = "1.0.0"; weight = 4024 };
  { key = "sound.shape.modern_0313";                     label = "global_biome_313";            arity = 1; tags = ["packet"; "untyped"]; since = "1.6.0"; weight = 2624 };
  { key = "world.shape.provisional_0314";                label = "cached_structure_314";        arity = 1; tags = ["check"; "parse"; "compat"]; since = "1.0.0"; weight = 2746 };
  { key = "chunk.shape.primary_0315";                    label = "hidden_trident_315";          arity = 7; tags = ["check"]; since = "1.4.0"; weight = 250 };
  { key = "gui.shape.cached_0316";                       label = "public_spawner_316";          arity = 2; tags = ["lower"; "content"; "cached"]; since = "1.6.0"; weight = 3917 };
  { key = "comparator.shape.public_0317";                label = "primary_banner_317";          arity = 3; tags = ["core"; "cached"]; since = "1.3.1"; weight = 2705 };
  { key = "observer.shape.local_0318";                   label = "lazy_spawner_318";            arity = 1; tags = ["experimental"]; since = "1.7.0"; weight = 1241 };
  { key = "dispenser.shape.stable_0319";                 label = "derived_smithing_319";        arity = 1; tags = ["compat"; "runtime"]; since = "1.5.2"; weight = 704 };
  { key = "player.shape.scoped_0320";                    label = "strict_spawner_320";          arity = 4; tags = ["hot"; "typed"; "registry"]; since = "1.0.0"; weight = 2926 };
  { key = "region.shape.local_0321";                     label = "public_anvil_321";            arity = 3; tags = ["check"]; since = "1.9.0"; weight = 2995 };
  { key = "bundle.shape.local_0322";                     label = "internal_stonecutter_322";    arity = 7; tags = ["runtime"; "cached"; "compat"]; since = "1.5.2"; weight = 1399 };
  { key = "map.shape.scoped_0323";                       label = "global_sound_323";            arity = 5; tags = ["parse"]; since = "1.8.3"; weight = 1059 };
  { key = "enchant.shape.local_0324";                    label = "internal_brewing_324";        arity = 7; tags = ["async"; "runtime"]; since = "1.6.0"; weight = 889 };
  { key = "smithing.shape.fallback_0325";                label = "cached_trade_325";            arity = 7; tags = ["packet"; "check"; "core"]; since = "1.4.0"; weight = 1284 };
  { key = "objective.shape.stable_0326";                 label = "modern_bundle_326";           arity = 3; tags = ["hot"; "cold"]; since = "1.8.3"; weight = 1403 };
  { key = "scoreboard.shape.derived_0327";               label = "local_team_327";              arity = 6; tags = ["emit"; "legacy"]; since = "1.6.0"; weight = 3436 };
  { key = "item.shape.modern_0328";                      label = "strict_comparator_328";       arity = 2; tags = ["async"; "sync"]; since = "1.3.1"; weight = 2977 };
  { key = "inventory.shape.primary_0329";                label = "global_attribute_329";        arity = 7; tags = ["core"; "lower"]; since = "1.5.2"; weight = 3431 };
  { key = "barrel.shape.eager_0330";                     label = "public_item_330";             arity = 4; tags = ["lower"]; since = "1.8.3"; weight = 2784 };
  { key = "structure.shape.legacy_0331";                 label = "eager_entity_331";            arity = 0; tags = ["parse"]; since = "1.3.1"; weight = 1975 };
  { key = "world.shape.lazy_0332";                       label = "scoped_banner_pattern_332";   arity = 6; tags = ["hot"; "parse"]; since = "1.9.0"; weight = 1857 };
  { key = "packet.shape.internal_0333";                  label = "cached_scoreboard_333";       arity = 2; tags = ["cold"; "sync"; "legacy"]; since = "1.6.0"; weight = 599 };
  { key = "scoreboard.shape.modern_0334";                label = "canonical_furnace_334";       arity = 2; tags = ["lower"]; since = "1.6.0"; weight = 1074 };
  { key = "furnace.shape.global_0335";                   label = "hidden_barrel_335";           arity = 1; tags = ["legacy"; "codegen"; "cold"]; since = "1.2.0"; weight = 2897 };
  { key = "team.shape.eager_0336";                       label = "stable_crossbow_336";         arity = 1; tags = ["lower"; "check"; "registry"]; since = "1.4.0"; weight = 3145 };
  { key = "world.shape.stable_0337";                     label = "cached_spawner_337";          arity = 1; tags = ["async"]; since = "1.0.0"; weight = 3723 };
  { key = "biome.shape.cached_0338";                     label = "public_shield_338";           arity = 0; tags = ["compat"]; since = "1.2.0"; weight = 740 };
  { key = "bell.shape.hidden_0339";                      label = "loose_packet_339";            arity = 4; tags = ["check"; "runtime"; "cached"]; since = "1.2.0"; weight = 2192 };
  { key = "packet.shape.eager_0340";                     label = "scoped_firework_340";         arity = 2; tags = ["parse"; "content"; "cold"]; since = "1.4.0"; weight = 1474 };
  { key = "arrow.shape.loose_0341";                      label = "stable_villager_341";         arity = 3; tags = ["cold"; "hot"; "content"]; since = "1.5.2"; weight = 1989 };
  { key = "attribute.shape.legacy_0342";                 label = "stable_effect_342";           arity = 1; tags = ["registry"]; since = "1.5.2"; weight = 1971 };
  { key = "portal.shape.loose_0343";                     label = "fallback_piston_343";         arity = 7; tags = ["emit"; "registry"; "cached"]; since = "1.3.1"; weight = 3832 };
  { key = "particle.shape.hidden_0344";                  label = "legacy_block_344";            arity = 3; tags = ["experimental"; "cold"]; since = "1.6.0"; weight = 3143 };
  { key = "elytra.shape.scoped_0345";                    label = "internal_hologram_345";       arity = 3; tags = ["compat"; "lower"; "cached"]; since = "1.3.1"; weight = 10 };
  { key = "smithing.shape.strict_0346";                  label = "local_campfire_346";          arity = 0; tags = ["typed"]; since = "1.5.2"; weight = 705 };
  { key = "bell.shape.provisional_0347";                 label = "loose_loom_347";              arity = 4; tags = ["emit"; "sync"]; since = "1.7.0"; weight = 821 };
  { key = "dropper.shape.secondary_0348";                label = "public_hologram_348";         arity = 4; tags = ["emit"; "cold"; "packet"]; since = "1.7.0"; weight = 3536 };
  { key = "biome.shape.loose_0349";                      label = "secondary_stonecutter_349";   arity = 6; tags = ["untyped"; "content"; "sync"]; since = "1.4.0"; weight = 194 };
  { key = "repeater.shape.modern_0350";                  label = "lazy_beacon_350";             arity = 7; tags = ["lower"]; since = "1.5.2"; weight = 2477 };
  { key = "conduit.shape.provisional_0351";              label = "public_barrel_351";           arity = 4; tags = ["content"; "emit"]; since = "1.6.0"; weight = 2216 };
  { key = "repeater.shape.global_0352";                  label = "internal_world_352";          arity = 7; tags = ["emit"; "packet"]; since = "1.9.0"; weight = 3712 };
  { key = "observer.shape.cached_0353";                  label = "public_objective_353";        arity = 2; tags = ["experimental"]; since = "1.0.0"; weight = 2155 };
  { key = "furnace.shape.eager_0354";                    label = "secondary_effect_354";        arity = 5; tags = ["hot"; "parse"]; since = "1.6.0"; weight = 680 };
  { key = "pane.shape.stable_0355";                      label = "stable_chunk_355";            arity = 5; tags = ["registry"]; since = "1.9.0"; weight = 2677 };
  { key = "recipe.shape.derived_0356";                   label = "derived_trident_356";         arity = 2; tags = ["hot"]; since = "1.6.0"; weight = 859 };
  { key = "beacon.shape.loose_0357";                     label = "stable_comparator_357";       arity = 3; tags = ["core"; "runtime"; "check"]; since = "1.6.0"; weight = 1227 };
  { key = "shulker.shape.hidden_0358";                   label = "loose_packet_358";            arity = 5; tags = ["experimental"; "registry"]; since = "1.7.0"; weight = 2742 };
  { key = "banner_pattern.shape.legacy_0359";            label = "eager_brewing_359";           arity = 7; tags = ["untyped"; "codegen"; "lower"]; since = "1.6.0"; weight = 3690 };
  { key = "particle.shape.modern_0360";                  label = "lazy_gui_360";                arity = 7; tags = ["parse"; "experimental"; "sync"]; since = "1.3.1"; weight = 1484 };
  { key = "effect.shape.legacy_0361";                    label = "strict_region_361";           arity = 7; tags = ["legacy"; "registry"; "typed"]; since = "1.0.0"; weight = 2822 };
  { key = "composter.shape.strict_0362";                 label = "strict_pane_362";             arity = 0; tags = ["experimental"]; since = "1.3.1"; weight = 3226 };
  { key = "structure.shape.modern_0363";                 label = "fallback_trident_363";        arity = 1; tags = ["sync"; "codegen"; "emit"]; since = "1.6.0"; weight = 153 };
  { key = "rail.shape.provisional_0364";                 label = "secondary_tablist_364";       arity = 7; tags = ["legacy"; "cold"; "experimental"]; since = "1.0.0"; weight = 2048 };
  { key = "minecart.shape.legacy_0365";                  label = "eager_arrow_365";             arity = 0; tags = ["check"; "cached"; "content"]; since = "1.4.0"; weight = 2367 };
  { key = "recipe.shape.legacy_0366";                    label = "internal_mob_366";            arity = 1; tags = ["core"]; since = "1.4.0"; weight = 3035 };
  { key = "stonecutter.shape.hidden_0367";               label = "primary_lectern_367";         arity = 4; tags = ["parse"; "lower"]; since = "1.0.0"; weight = 2387 };
  { key = "observer.shape.modern_0368";                  label = "internal_hopper_368";         arity = 2; tags = ["registry"; "runtime"]; since = "1.0.0"; weight = 2034 };
  { key = "enchant.shape.cached_0369";                   label = "public_particle_369";         arity = 1; tags = ["sync"; "codegen"]; since = "1.0.0"; weight = 3900 };
  { key = "scoreboard.shape.eager_0370";                 label = "fallback_biome_370";          arity = 0; tags = ["compat"; "untyped"]; since = "1.6.0"; weight = 3589 };
  { key = "slot.shape.eager_0371";                       label = "strict_region_371";           arity = 4; tags = ["compat"; "runtime"; "lower"]; since = "1.8.3"; weight = 439 };
  { key = "conduit.shape.modern_0372";                   label = "cached_firework_372";         arity = 2; tags = ["sync"; "hot"]; since = "1.0.0"; weight = 1498 };
  { key = "boat.shape.cached_0373";                      label = "public_bundle_373";           arity = 2; tags = ["core"; "check"]; since = "1.5.2"; weight = 38 };
  { key = "campfire.shape.loose_0374";                   label = "primary_brewing_374";         arity = 5; tags = ["typed"; "registry"; "hot"]; since = "1.3.1"; weight = 349 };
  { key = "particle.shape.strict_0375";                  label = "secondary_world_375";         arity = 4; tags = ["registry"]; since = "1.0.0"; weight = 71 };
  { key = "recipe.shape.hidden_0376";                    label = "loose_dropper_376";           arity = 6; tags = ["emit"; "codegen"; "lower"]; since = "1.8.3"; weight = 2915 };
  { key = "villager.shape.hidden_0377";                  label = "modern_pane_377";             arity = 3; tags = ["check"; "emit"]; since = "1.0.0"; weight = 1052 };
  { key = "entity.shape.scoped_0378";                    label = "fallback_clock_378";          arity = 7; tags = ["async"]; since = "1.7.0"; weight = 1761 };
  { key = "team.shape.cached_0379";                      label = "cached_comparator_379";       arity = 4; tags = ["cached"; "experimental"; "parse"]; since = "1.6.0"; weight = 2904 };
  { key = "bundle.shape.hidden_0380";                    label = "lazy_smoker_380";             arity = 3; tags = ["async"]; since = "1.8.3"; weight = 681 };
]

let count = List.length entries

let table : (string, shape_entry) Hashtbl.t =
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
