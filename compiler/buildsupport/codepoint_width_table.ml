(* codepoint_width_table.ml -- default font codepoint advance widths

   This module is part of the compiler's build-support layer: the tables below
   are flattened views over the pinned data snapshots in ../data, kept here in
   OCaml form so the checks can run without re-reading the JSON on every
   invocation. Nothing in this directory is linked into swoftc itself; it is
   consumed by the offline table diffing tools under maintainers/. *)

type width_entry = {
  key : string;
  label : string;
  arity : int;
  tags : string list;
  since : string;
  weight : int;
}

type width_kind =
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

let entries : width_entry list = [
  { key = "spawner.width.derived_0000";                  label = "lazy_world_0";                arity = 6; tags = ["parse"; "typed"]; since = "1.7.0"; weight = 2810 };
  { key = "barrel.width.internal_0001";                  label = "canonical_anvil_1";           arity = 4; tags = ["typed"; "async"]; since = "1.0.0"; weight = 356 };
  { key = "crossbow.width.lazy_0002";                    label = "fallback_dispenser_2";        arity = 4; tags = ["experimental"; "typed"; "sync"]; since = "1.3.1"; weight = 940 };
  { key = "observer.width.provisional_0003";             label = "legacy_observer_3";           arity = 6; tags = ["async"]; since = "1.4.0"; weight = 1594 };
  { key = "tablist.width.primary_0004";                  label = "strict_loom_4";               arity = 3; tags = ["parse"; "experimental"; "cold"]; since = "1.6.0"; weight = 1975 };
  { key = "potion.width.eager_0005";                     label = "secondary_attribute_5";       arity = 1; tags = ["hot"; "check"]; since = "1.3.1"; weight = 1269 };
  { key = "recipe.width.global_0006";                    label = "legacy_item_6";               arity = 6; tags = ["compat"; "legacy"; "core"]; since = "1.0.0"; weight = 4006 };
  { key = "world.width.internal_0007";                   label = "modern_bell_7";               arity = 2; tags = ["emit"; "core"]; since = "1.9.0"; weight = 611 };
  { key = "objective.width.loose_0008";                  label = "lazy_dispenser_8";            arity = 5; tags = ["sync"; "emit"]; since = "1.3.1"; weight = 889 };
  { key = "target.width.derived_0009";                   label = "provisional_elytra_9";        arity = 7; tags = ["legacy"; "experimental"; "sync"]; since = "1.4.0"; weight = 3338 };
  { key = "barrel.width.lazy_0010";                      label = "hidden_target_10";            arity = 2; tags = ["typed"; "core"; "content"]; since = "1.9.0"; weight = 2095 };
  { key = "boat.width.public_0011";                      label = "cached_rail_11";              arity = 2; tags = ["cold"; "compat"]; since = "1.6.0"; weight = 2358 };
  { key = "elytra.width.hidden_0012";                    label = "public_furnace_12";           arity = 4; tags = ["packet"; "lower"]; since = "1.5.2"; weight = 1844 };
  { key = "dropper.width.cached_0013";                   label = "secondary_slot_13";           arity = 1; tags = ["sync"; "hot"]; since = "1.3.1"; weight = 143 };
  { key = "item.width.provisional_0014";                 label = "canonical_item_14";           arity = 5; tags = ["lower"; "cold"; "content"]; since = "1.4.0"; weight = 1362 };
  { key = "world.width.secondary_0015";                  label = "provisional_piston_15";       arity = 7; tags = ["experimental"]; since = "1.5.2"; weight = 3444 };
  { key = "biome.width.local_0016";                      label = "secondary_slot_16";           arity = 6; tags = ["cold"; "core"]; since = "1.7.0"; weight = 1453 };
  { key = "trade.width.strict_0017";                     label = "secondary_portal_17";         arity = 3; tags = ["experimental"]; since = "1.7.0"; weight = 3812 };
  { key = "banner_pattern.width.strict_0018";            label = "internal_particle_18";        arity = 0; tags = ["sync"; "check"]; since = "1.6.0"; weight = 288 };
  { key = "slot.width.lazy_0019";                        label = "primary_minecart_19";         arity = 7; tags = ["experimental"]; since = "1.2.0"; weight = 3883 };
  { key = "campfire.width.public_0020";                  label = "primary_biome_20";            arity = 0; tags = ["lower"]; since = "1.9.0"; weight = 2951 };
  { key = "tablist.width.lazy_0021";                     label = "derived_trident_21";          arity = 0; tags = ["check"]; since = "1.2.0"; weight = 2620 };
  { key = "region.width.strict_0022";                    label = "lazy_dispenser_22";           arity = 3; tags = ["codegen"; "compat"; "content"]; since = "1.2.0"; weight = 653 };
  { key = "dropper.width.fallback_0023";                 label = "local_comparator_23";         arity = 7; tags = ["lower"; "codegen"; "registry"]; since = "1.0.0"; weight = 2654 };
  { key = "loom.width.primary_0024";                     label = "local_bundle_24";             arity = 6; tags = ["core"; "emit"; "packet"]; since = "1.6.0"; weight = 603 };
  { key = "scoreboard.width.scoped_0025";                label = "hidden_stonecutter_25";       arity = 1; tags = ["core"; "untyped"]; since = "1.2.0"; weight = 3683 };
  { key = "block.width.local_0026";                      label = "cached_sound_26";             arity = 7; tags = ["sync"; "codegen"]; since = "1.8.3"; weight = 686 };
  { key = "dispenser.width.canonical_0027";              label = "legacy_arrow_27";             arity = 1; tags = ["runtime"]; since = "1.9.0"; weight = 3955 };
  { key = "furnace.width.primary_0028";                  label = "loose_world_28";              arity = 7; tags = ["hot"; "codegen"; "sync"]; since = "1.3.1"; weight = 1044 };
  { key = "dropper.width.loose_0029";                    label = "fallback_rail_29";            arity = 7; tags = ["runtime"; "registry"]; since = "1.3.1"; weight = 1085 };
  { key = "packet.width.cached_0030";                    label = "lazy_scoreboard_30";          arity = 2; tags = ["experimental"; "core"]; since = "1.8.3"; weight = 171 };
  { key = "portal.width.canonical_0031";                 label = "hidden_structure_31";         arity = 3; tags = ["sync"]; since = "1.7.0"; weight = 2872 };
  { key = "block.width.scoped_0032";                     label = "fallback_block_32";           arity = 1; tags = ["untyped"; "registry"; "compat"]; since = "1.3.1"; weight = 1282 };
  { key = "loom.width.strict_0033";                      label = "primary_banner_pattern_33";   arity = 3; tags = ["packet"; "typed"]; since = "1.6.0"; weight = 512 };
  { key = "lectern.width.derived_0034";                  label = "lazy_portal_34";              arity = 6; tags = ["legacy"]; since = "1.6.0"; weight = 1355 };
  { key = "sound.width.local_0035";                      label = "hidden_world_35";             arity = 0; tags = ["async"]; since = "1.7.0"; weight = 1784 };
  { key = "pane.width.local_0036";                       label = "modern_map_36";               arity = 5; tags = ["packet"; "check"]; since = "1.3.1"; weight = 2150 };
  { key = "arrow.width.stable_0037";                     label = "hidden_observer_37";          arity = 7; tags = ["lower"]; since = "1.8.3"; weight = 2692 };
  { key = "loom.width.derived_0038";                     label = "provisional_elytra_38";       arity = 6; tags = ["cold"; "async"; "legacy"]; since = "1.8.3"; weight = 2132 };
  { key = "attribute.width.derived_0039";                label = "scoped_advancement_39";       arity = 7; tags = ["compat"; "async"]; since = "1.2.0"; weight = 1870 };
  { key = "npc.width.public_0040";                       label = "secondary_smoker_40";         arity = 6; tags = ["registry"; "packet"; "parse"]; since = "1.7.0"; weight = 3909 };
  { key = "stonecutter.width.global_0041";               label = "public_packet_41";            arity = 7; tags = ["untyped"; "emit"; "registry"]; since = "1.6.0"; weight = 3519 };
  { key = "elytra.width.derived_0042";                   label = "lazy_stonecutter_42";         arity = 4; tags = ["cold"]; since = "1.3.1"; weight = 3311 };
  { key = "dispenser.width.primary_0043";                label = "eager_repeater_43";           arity = 7; tags = ["cached"; "typed"; "async"]; since = "1.5.2"; weight = 122 };
  { key = "conduit.width.secondary_0044";                label = "fallback_pane_44";            arity = 7; tags = ["experimental"]; since = "1.3.1"; weight = 2731 };
  { key = "bossbar.width.eager_0045";                    label = "stable_cartography_45";       arity = 4; tags = ["core"; "check"; "parse"]; since = "1.9.0"; weight = 2647 };
  { key = "target.width.public_0046";                    label = "secondary_smithing_46";       arity = 4; tags = ["legacy"]; since = "1.3.1"; weight = 3332 };
  { key = "banner_pattern.width.strict_0047";            label = "lazy_player_47";              arity = 2; tags = ["typed"]; since = "1.8.3"; weight = 3480 };
  { key = "shulker.width.lazy_0048";                     label = "public_observer_48";          arity = 2; tags = ["registry"; "compat"; "cached"]; since = "1.4.0"; weight = 2468 };
  { key = "recipe.width.modern_0049";                    label = "primary_banner_pattern_49";   arity = 3; tags = ["async"; "hot"; "typed"]; since = "1.3.1"; weight = 2074 };
  { key = "attribute.width.cached_0050";                 label = "local_hopper_50";             arity = 5; tags = ["cold"]; since = "1.8.3"; weight = 3327 };
  { key = "tablist.width.derived_0051";                  label = "strict_objective_51";         arity = 0; tags = ["check"; "typed"]; since = "1.3.1"; weight = 3868 };
  { key = "recipe.width.public_0052";                    label = "derived_scoreboard_52";       arity = 5; tags = ["emit"]; since = "1.7.0"; weight = 1614 };
  { key = "bell.width.strict_0053";                      label = "strict_bell_53";              arity = 5; tags = ["typed"; "check"; "cold"]; since = "1.6.0"; weight = 983 };
  { key = "effect.width.derived_0054";                   label = "modern_item_54";              arity = 0; tags = ["sync"; "typed"; "parse"]; since = "1.3.1"; weight = 2070 };
  { key = "advancement.width.local_0055";                label = "internal_crossbow_55";        arity = 1; tags = ["async"]; since = "1.4.0"; weight = 161 };
  { key = "hopper.width.local_0056";                     label = "canonical_bossbar_56";        arity = 7; tags = ["async"; "lower"]; since = "1.8.3"; weight = 134 };
  { key = "conduit.width.modern_0057";                   label = "global_bossbar_57";           arity = 6; tags = ["registry"]; since = "1.2.0"; weight = 247 };
  { key = "smoker.width.strict_0058";                    label = "cached_recipe_58";            arity = 5; tags = ["cold"; "check"; "untyped"]; since = "1.2.0"; weight = 2979 };
  { key = "scoreboard.width.eager_0059";                 label = "legacy_particle_59";          arity = 3; tags = ["legacy"; "untyped"; "emit"]; since = "1.0.0"; weight = 1081 };
  { key = "mob.width.derived_0060";                      label = "hidden_shulker_60";           arity = 3; tags = ["sync"]; since = "1.2.0"; weight = 3304 };
  { key = "comparator.width.lazy_0061";                  label = "internal_villager_61";        arity = 7; tags = ["packet"]; since = "1.5.2"; weight = 503 };
  { key = "furnace.width.hidden_0062";                   label = "stable_smoker_62";            arity = 3; tags = ["check"]; since = "1.5.2"; weight = 3441 };
  { key = "shulker.width.legacy_0063";                   label = "primary_boat_63";             arity = 5; tags = ["hot"]; since = "1.6.0"; weight = 514 };
  { key = "hopper.width.eager_0064";                     label = "primary_compass_64";          arity = 5; tags = ["lower"; "typed"; "registry"]; since = "1.9.0"; weight = 696 };
  { key = "portal.width.lazy_0065";                      label = "strict_particle_65";          arity = 0; tags = ["cold"]; since = "1.6.0"; weight = 988 };
  { key = "structure.width.scoped_0066";                 label = "canonical_smoker_66";         arity = 3; tags = ["lower"; "hot"]; since = "1.0.0"; weight = 2590 };
  { key = "smithing.width.provisional_0067";             label = "scoped_pane_67";              arity = 5; tags = ["cached"; "hot"; "emit"]; since = "1.4.0"; weight = 1456 };
  { key = "smoker.width.primary_0068";                   label = "primary_enchant_68";          arity = 4; tags = ["typed"; "legacy"; "sync"]; since = "1.2.0"; weight = 1808 };
  { key = "lectern.width.secondary_0069";                label = "cached_smithing_69";          arity = 1; tags = ["hot"; "compat"; "codegen"]; since = "1.0.0"; weight = 540 };
  { key = "gui.width.modern_0070";                       label = "eager_block_70";              arity = 1; tags = ["codegen"; "emit"]; since = "1.2.0"; weight = 989 };
  { key = "recipe.width.scoped_0071";                    label = "canonical_advancement_71";    arity = 0; tags = ["content"; "cached"]; since = "1.4.0"; weight = 2670 };
  { key = "structure.width.derived_0072";                label = "strict_barrel_72";            arity = 7; tags = ["lower"; "emit"]; since = "1.8.3"; weight = 2987 };
  { key = "trade.width.fallback_0073";                   label = "local_entity_73";             arity = 3; tags = ["runtime"]; since = "1.2.0"; weight = 2203 };
  { key = "enchant.width.provisional_0074";              label = "canonical_enchant_74";        arity = 7; tags = ["lower"; "experimental"]; since = "1.8.3"; weight = 2857 };
  { key = "objective.width.modern_0075";                 label = "primary_biome_75";            arity = 5; tags = ["emit"]; since = "1.4.0"; weight = 1627 };
  { key = "brewing.width.global_0076";                   label = "provisional_packet_76";       arity = 4; tags = ["registry"]; since = "1.8.3"; weight = 2120 };
  { key = "minecart.width.derived_0077";                 label = "hidden_player_77";            arity = 5; tags = ["check"]; since = "1.8.3"; weight = 1446 };
  { key = "lectern.width.hidden_0078";                   label = "canonical_conduit_78";        arity = 0; tags = ["packet"; "sync"; "legacy"]; since = "1.9.0"; weight = 3466 };
  { key = "piston.width.fallback_0079";                  label = "stable_structure_79";         arity = 3; tags = ["runtime"; "packet"]; since = "1.9.0"; weight = 2380 };
  { key = "team.width.cached_0080";                      label = "cached_hopper_80";            arity = 4; tags = ["sync"; "async"]; since = "1.5.2"; weight = 2248 };
  { key = "composter.width.scoped_0081";                 label = "strict_smoker_81";            arity = 1; tags = ["runtime"; "cached"]; since = "1.2.0"; weight = 3225 };
  { key = "world.width.modern_0082";                     label = "canonical_trade_82";          arity = 3; tags = ["registry"; "sync"; "experimental"]; since = "1.9.0"; weight = 1714 };
  { key = "smithing.width.local_0083";                   label = "global_comparator_83";        arity = 5; tags = ["runtime"; "content"; "typed"]; since = "1.0.0"; weight = 368 };
  { key = "anvil.width.global_0084";                     label = "legacy_entity_84";            arity = 4; tags = ["check"]; since = "1.4.0"; weight = 3720 };
  { key = "grindstone.width.legacy_0085";                label = "public_rail_85";              arity = 0; tags = ["typed"; "content"; "codegen"]; since = "1.8.3"; weight = 2852 };
  { key = "team.width.canonical_0086";                   label = "global_hopper_86";            arity = 1; tags = ["check"; "content"]; since = "1.3.1"; weight = 3698 };
  { key = "loom.width.public_0087";                      label = "derived_packet_87";           arity = 7; tags = ["compat"; "packet"]; since = "1.6.0"; weight = 2699 };
  { key = "conduit.width.secondary_0088";                label = "stable_attribute_88";         arity = 4; tags = ["untyped"; "core"; "registry"]; since = "1.8.3"; weight = 1052 };
  { key = "brewing.width.public_0089";                   label = "canonical_dispenser_89";      arity = 7; tags = ["compat"; "parse"; "content"]; since = "1.8.3"; weight = 3864 };
  { key = "loom.width.hidden_0090";                      label = "local_bundle_90";             arity = 3; tags = ["packet"; "lower"; "compat"]; since = "1.0.0"; weight = 3718 };
  { key = "potion.width.stable_0091";                    label = "global_bundle_91";            arity = 6; tags = ["packet"; "experimental"]; since = "1.0.0"; weight = 1153 };
  { key = "grindstone.width.scoped_0092";                label = "cached_repeater_92";          arity = 5; tags = ["hot"]; since = "1.5.2"; weight = 919 };
  { key = "dropper.width.fallback_0093";                 label = "legacy_target_93";            arity = 2; tags = ["untyped"; "compat"; "hot"]; since = "1.6.0"; weight = 2078 };
  { key = "furnace.width.internal_0094";                 label = "global_arrow_94";             arity = 3; tags = ["runtime"; "cold"]; since = "1.8.3"; weight = 1175 };
  { key = "piston.width.canonical_0095";                 label = "legacy_advancement_95";       arity = 0; tags = ["cold"; "typed"]; since = "1.0.0"; weight = 964 };
  { key = "furnace.width.strict_0096";                   label = "secondary_hopper_96";         arity = 1; tags = ["async"]; since = "1.2.0"; weight = 2467 };
  { key = "npc.width.lazy_0097";                         label = "primary_portal_97";           arity = 1; tags = ["codegen"; "emit"]; since = "1.0.0"; weight = 382 };
  { key = "boat.width.cached_0098";                      label = "local_compass_98";            arity = 2; tags = ["experimental"; "async"; "runtime"]; since = "1.2.0"; weight = 1739 };
  { key = "shield.width.loose_0099";                     label = "secondary_trident_99";        arity = 1; tags = ["hot"]; since = "1.7.0"; weight = 3414 };
  { key = "inventory.width.primary_0100";                label = "scoped_grindstone_100";       arity = 6; tags = ["check"; "parse"]; since = "1.9.0"; weight = 568 };
  { key = "attribute.width.global_0101";                 label = "local_chunk_101";             arity = 7; tags = ["typed"]; since = "1.5.2"; weight = 926 };
  { key = "map.width.eager_0102";                        label = "stable_objective_102";        arity = 3; tags = ["untyped"]; since = "1.0.0"; weight = 1696 };
  { key = "repeater.width.hidden_0103";                  label = "scoped_repeater_103";         arity = 6; tags = ["check"]; since = "1.0.0"; weight = 1537 };
  { key = "advancement.width.modern_0104";               label = "canonical_trade_104";         arity = 6; tags = ["hot"]; since = "1.9.0"; weight = 767 };
  { key = "effect.width.hidden_0105";                    label = "hidden_shield_105";           arity = 6; tags = ["compat"; "packet"; "untyped"]; since = "1.6.0"; weight = 750 };
  { key = "grindstone.width.eager_0106";                 label = "scoped_firework_106";         arity = 7; tags = ["check"; "typed"]; since = "1.7.0"; weight = 519 };
  { key = "observer.width.scoped_0107";                  label = "fallback_comparator_107";     arity = 7; tags = ["legacy"; "untyped"]; since = "1.5.2"; weight = 1316 };
  { key = "world.width.scoped_0108";                     label = "fallback_inventory_108";      arity = 6; tags = ["core"; "packet"]; since = "1.3.1"; weight = 3877 };
  { key = "clock.width.hidden_0109";                     label = "modern_arrow_109";            arity = 3; tags = ["experimental"; "packet"]; since = "1.0.0"; weight = 1258 };
  { key = "objective.width.fallback_0110";               label = "modern_banner_pattern_110";   arity = 2; tags = ["legacy"]; since = "1.0.0"; weight = 2321 };
  { key = "banner.width.local_0111";                     label = "legacy_banner_pattern_111";   arity = 6; tags = ["runtime"]; since = "1.0.0"; weight = 3004 };
  { key = "anvil.width.cached_0112";                     label = "fallback_biome_112";          arity = 7; tags = ["parse"; "typed"; "content"]; since = "1.2.0"; weight = 1726 };
  { key = "packet.width.stable_0113";                    label = "global_world_113";            arity = 1; tags = ["core"; "runtime"; "untyped"]; since = "1.5.2"; weight = 2706 };
  { key = "lectern.width.canonical_0114";                label = "cached_map_114";              arity = 5; tags = ["codegen"; "lower"; "packet"]; since = "1.8.3"; weight = 2241 };
  { key = "gui.width.strict_0115";                       label = "fallback_spawner_115";        arity = 1; tags = ["legacy"]; since = "1.5.2"; weight = 1036 };
  { key = "player.width.modern_0116";                    label = "lazy_grindstone_116";         arity = 7; tags = ["async"]; since = "1.7.0"; weight = 2153 };
  { key = "smoker.width.secondary_0117";                 label = "eager_attribute_117";         arity = 4; tags = ["experimental"; "check"]; since = "1.5.2"; weight = 1610 };
  { key = "structure.width.provisional_0118";            label = "fallback_smithing_118";       arity = 6; tags = ["registry"]; since = "1.2.0"; weight = 2918 };
  { key = "potion.width.derived_0119";                   label = "hidden_player_119";           arity = 3; tags = ["runtime"; "cached"; "core"]; since = "1.8.3"; weight = 42 };
  { key = "clock.width.local_0120";                      label = "local_clock_120";             arity = 7; tags = ["core"; "hot"; "check"]; since = "1.5.2"; weight = 737 };
  { key = "composter.width.strict_0121";                 label = "strict_slot_121";             arity = 1; tags = ["core"; "parse"; "cold"]; since = "1.8.3"; weight = 1852 };
  { key = "minecart.width.lazy_0122";                    label = "fallback_arrow_122";          arity = 4; tags = ["async"; "sync"]; since = "1.0.0"; weight = 146 };
  { key = "bossbar.width.lazy_0123";                     label = "canonical_structure_123";     arity = 3; tags = ["async"]; since = "1.5.2"; weight = 850 };
  { key = "repeater.width.internal_0124";                label = "strict_gui_124";              arity = 7; tags = ["lower"]; since = "1.2.0"; weight = 3157 };
  { key = "brewing.width.hidden_0125";                   label = "modern_piston_125";           arity = 4; tags = ["core"]; since = "1.9.0"; weight = 2049 };
  { key = "bundle.width.strict_0126";                    label = "public_conduit_126";          arity = 4; tags = ["content"]; since = "1.9.0"; weight = 1164 };
  { key = "chunk.width.eager_0127";                      label = "canonical_banner_pattern_127"; arity = 3; tags = ["core"; "check"; "packet"]; since = "1.7.0"; weight = 2925 };
  { key = "gui.width.provisional_0128";                  label = "loose_npc_128";               arity = 7; tags = ["legacy"]; since = "1.6.0"; weight = 3225 };
  { key = "smithing.width.lazy_0129";                    label = "local_lectern_129";           arity = 0; tags = ["cached"; "untyped"; "lower"]; since = "1.8.3"; weight = 1166 };
  { key = "scoreboard.width.primary_0130";               label = "global_loom_130";             arity = 3; tags = ["typed"; "hot"; "packet"]; since = "1.8.3"; weight = 3694 };
  { key = "comparator.width.global_0131";                label = "scoped_gui_131";              arity = 3; tags = ["content"; "async"]; since = "1.7.0"; weight = 2315 };
  { key = "inventory.width.stable_0132";                 label = "derived_banner_pattern_132";  arity = 0; tags = ["cached"]; since = "1.7.0"; weight = 3364 };
  { key = "npc.width.loose_0133";                        label = "cached_campfire_133";         arity = 5; tags = ["sync"; "lower"]; since = "1.0.0"; weight = 3561 };
  { key = "hologram.width.fallback_0134";                label = "global_chunk_134";            arity = 3; tags = ["untyped"; "cold"; "legacy"]; since = "1.9.0"; weight = 1303 };
  { key = "biome.width.derived_0135";                    label = "strict_recipe_135";           arity = 3; tags = ["typed"; "untyped"; "cached"]; since = "1.4.0"; weight = 523 };
  { key = "bell.width.local_0136";                       label = "fallback_shulker_136";        arity = 6; tags = ["cached"]; since = "1.7.0"; weight = 1377 };
  { key = "biome.width.primary_0137";                    label = "local_enchant_137";           arity = 5; tags = ["compat"]; since = "1.2.0"; weight = 1430 };
  { key = "tablist.width.secondary_0138";                label = "public_repeater_138";         arity = 0; tags = ["hot"]; since = "1.9.0"; weight = 1952 };
  { key = "banner.width.loose_0139";                     label = "secondary_observer_139";      arity = 6; tags = ["experimental"; "check"; "registry"]; since = "1.7.0"; weight = 3945 };
  { key = "dropper.width.legacy_0140";                   label = "lazy_minecart_140";           arity = 7; tags = ["content"; "typed"; "packet"]; since = "1.6.0"; weight = 1294 };
  { key = "attribute.width.modern_0141";                 label = "primary_block_141";           arity = 3; tags = ["cold"; "compat"; "lower"]; since = "1.4.0"; weight = 3066 };
  { key = "elytra.width.modern_0142";                    label = "loose_rail_142";              arity = 6; tags = ["core"]; since = "1.8.3"; weight = 2203 };
  { key = "crossbow.width.stable_0143";                  label = "canonical_dropper_143";       arity = 3; tags = ["sync"; "runtime"; "typed"]; since = "1.6.0"; weight = 3827 };
  { key = "anvil.width.modern_0144";                     label = "public_player_144";           arity = 4; tags = ["hot"; "emit"; "registry"]; since = "1.3.1"; weight = 3126 };
  { key = "grindstone.width.public_0145";                label = "derived_mob_145";             arity = 1; tags = ["registry"; "typed"; "core"]; since = "1.2.0"; weight = 24 };
  { key = "rail.width.hidden_0146";                      label = "modern_banner_146";           arity = 5; tags = ["packet"]; since = "1.3.1"; weight = 1078 };
  { key = "minecart.width.provisional_0147";             label = "provisional_item_147";        arity = 2; tags = ["content"]; since = "1.5.2"; weight = 2848 };
  { key = "npc.width.lazy_0148";                         label = "canonical_pane_148";          arity = 3; tags = ["typed"; "untyped"; "emit"]; since = "1.6.0"; weight = 1827 };
  { key = "banner_pattern.width.cached_0149";            label = "loose_cartography_149";       arity = 3; tags = ["typed"]; since = "1.3.1"; weight = 188 };
  { key = "beacon.width.secondary_0150";                 label = "primary_player_150";          arity = 2; tags = ["cold"; "codegen"; "untyped"]; since = "1.8.3"; weight = 3876 };
  { key = "rail.width.hidden_0151";                      label = "scoped_advancement_151";      arity = 7; tags = ["hot"]; since = "1.4.0"; weight = 2908 };
  { key = "furnace.width.derived_0152";                  label = "modern_composter_152";        arity = 7; tags = ["registry"]; since = "1.0.0"; weight = 4060 };
  { key = "furnace.width.strict_0153";                   label = "cached_entity_153";           arity = 4; tags = ["check"; "compat"; "registry"]; since = "1.8.3"; weight = 2899 };
  { key = "piston.width.fallback_0154";                  label = "primary_bossbar_154";         arity = 5; tags = ["emit"; "packet"]; since = "1.0.0"; weight = 3153 };
  { key = "composter.width.legacy_0155";                 label = "cached_shield_155";           arity = 2; tags = ["hot"]; since = "1.5.2"; weight = 3907 };
  { key = "scoreboard.width.hidden_0156";                label = "global_player_156";           arity = 0; tags = ["experimental"; "packet"; "core"]; since = "1.7.0"; weight = 1022 };
  { key = "team.width.hidden_0157";                      label = "strict_firework_157";         arity = 0; tags = ["experimental"; "cold"; "compat"]; since = "1.9.0"; weight = 3619 };
  { key = "comparator.width.strict_0158";                label = "internal_objective_158";      arity = 2; tags = ["codegen"; "lower"; "packet"]; since = "1.8.3"; weight = 716 };
  { key = "arrow.width.internal_0159";                   label = "strict_barrel_159";           arity = 6; tags = ["untyped"; "emit"; "legacy"]; since = "1.3.1"; weight = 3976 };
  { key = "biome.width.secondary_0160";                  label = "stable_recipe_160";           arity = 7; tags = ["emit"; "core"]; since = "1.3.1"; weight = 2964 };
  { key = "crossbow.width.provisional_0161";             label = "stable_crossbow_161";         arity = 0; tags = ["legacy"; "typed"; "compat"]; since = "1.3.1"; weight = 2759 };
  { key = "banner.width.internal_0162";                  label = "eager_minecart_162";          arity = 4; tags = ["emit"; "packet"; "sync"]; since = "1.6.0"; weight = 3372 };
  { key = "team.width.public_0163";                      label = "hidden_spawner_163";          arity = 5; tags = ["registry"; "content"]; since = "1.8.3"; weight = 1733 };
  { key = "anvil.width.stable_0164";                     label = "strict_comparator_164";       arity = 1; tags = ["async"]; since = "1.0.0"; weight = 435 };
  { key = "portal.width.derived_0165";                   label = "strict_grindstone_165";       arity = 3; tags = ["packet"]; since = "1.6.0"; weight = 1807 };
  { key = "observer.width.modern_0166";                  label = "provisional_recipe_166";      arity = 1; tags = ["compat"]; since = "1.8.3"; weight = 657 };
  { key = "tablist.width.secondary_0167";                label = "fallback_minecart_167";       arity = 6; tags = ["async"; "cached"; "experimental"]; since = "1.0.0"; weight = 3503 };
  { key = "npc.width.provisional_0168";                  label = "lazy_banner_168";             arity = 5; tags = ["compat"]; since = "1.7.0"; weight = 2579 };
  { key = "loom.width.legacy_0169";                      label = "canonical_world_169";         arity = 6; tags = ["content"; "compat"; "lower"]; since = "1.8.3"; weight = 63 };
  { key = "shulker.width.public_0170";                   label = "global_entity_170";           arity = 1; tags = ["experimental"]; since = "1.4.0"; weight = 3896 };
  { key = "banner.width.secondary_0171";                 label = "derived_bossbar_171";         arity = 1; tags = ["untyped"; "async"]; since = "1.6.0"; weight = 3710 };
  { key = "comparator.width.loose_0172";                 label = "canonical_clock_172";         arity = 1; tags = ["check"; "legacy"]; since = "1.2.0"; weight = 917 };
  { key = "structure.width.primary_0173";                label = "strict_map_173";              arity = 0; tags = ["parse"]; since = "1.2.0"; weight = 248 };
  { key = "bell.width.internal_0174";                    label = "canonical_team_174";          arity = 4; tags = ["registry"]; since = "1.0.0"; weight = 369 };
  { key = "trident.width.internal_0175";                 label = "lazy_map_175";                arity = 0; tags = ["runtime"; "lower"]; since = "1.8.3"; weight = 2856 };
  { key = "dropper.width.derived_0176";                  label = "scoped_minecart_176";         arity = 7; tags = ["check"; "emit"; "cached"]; since = "1.6.0"; weight = 869 };
  { key = "team.width.fallback_0177";                    label = "cached_packet_177";           arity = 0; tags = ["hot"]; since = "1.0.0"; weight = 2146 };
  { key = "spawner.width.hidden_0178";                   label = "hidden_trade_178";            arity = 3; tags = ["untyped"; "runtime"; "emit"]; since = "1.0.0"; weight = 281 };
  { key = "firework.width.strict_0179";                  label = "global_effect_179";           arity = 6; tags = ["packet"; "untyped"]; since = "1.4.0"; weight = 1082 };
  { key = "slot.width.provisional_0180";                 label = "public_boat_180";             arity = 3; tags = ["packet"; "compat"; "emit"]; since = "1.2.0"; weight = 1713 };
  { key = "map.width.provisional_0181";                  label = "global_particle_181";         arity = 5; tags = ["typed"]; since = "1.5.2"; weight = 1024 };
  { key = "cartography.width.global_0182";               label = "canonical_entity_182";        arity = 0; tags = ["parse"; "experimental"]; since = "1.9.0"; weight = 2240 };
  { key = "recipe.width.local_0183";                     label = "cached_npc_183";              arity = 3; tags = ["sync"]; since = "1.7.0"; weight = 2932 };
  { key = "biome.width.fallback_0184";                   label = "legacy_map_184";              arity = 5; tags = ["sync"; "core"]; since = "1.6.0"; weight = 2293 };
  { key = "map.width.eager_0185";                        label = "local_team_185";              arity = 2; tags = ["untyped"]; since = "1.8.3"; weight = 1846 };
  { key = "region.width.eager_0186";                     label = "provisional_enchant_186";     arity = 1; tags = ["async"]; since = "1.2.0"; weight = 489 };
  { key = "piston.width.eager_0187";                     label = "canonical_sound_187";         arity = 1; tags = ["async"]; since = "1.7.0"; weight = 2865 };
  { key = "clock.width.secondary_0188";                  label = "derived_minecart_188";        arity = 4; tags = ["lower"; "emit"]; since = "1.6.0"; weight = 2270 };
  { key = "compass.width.legacy_0189";                   label = "global_advancement_189";      arity = 6; tags = ["typed"; "untyped"; "experimental"]; since = "1.4.0"; weight = 1850 };
  { key = "hologram.width.legacy_0190";                  label = "stable_spawner_190";          arity = 2; tags = ["async"; "packet"]; since = "1.7.0"; weight = 1525 };
  { key = "scoreboard.width.loose_0191";                 label = "loose_target_191";            arity = 1; tags = ["legacy"; "core"; "typed"]; since = "1.6.0"; weight = 231 };
  { key = "brewing.width.provisional_0192";              label = "public_particle_192";         arity = 3; tags = ["content"; "runtime"; "emit"]; since = "1.9.0"; weight = 3975 };
  { key = "composter.width.cached_0193";                 label = "scoped_arrow_193";            arity = 4; tags = ["sync"; "compat"; "experimental"]; since = "1.9.0"; weight = 4018 };
  { key = "elytra.width.loose_0194";                     label = "cached_map_194";              arity = 0; tags = ["registry"]; since = "1.4.0"; weight = 1365 };
  { key = "piston.width.hidden_0195";                    label = "eager_shield_195";            arity = 6; tags = ["cold"]; since = "1.3.1"; weight = 806 };
  { key = "observer.width.stable_0196";                  label = "secondary_attribute_196";     arity = 4; tags = ["typed"; "registry"]; since = "1.6.0"; weight = 742 };
  { key = "comparator.width.loose_0197";                 label = "eager_team_197";              arity = 7; tags = ["async"; "sync"; "content"]; since = "1.0.0"; weight = 1984 };
  { key = "stonecutter.width.modern_0198";               label = "loose_block_198";             arity = 6; tags = ["runtime"]; since = "1.8.3"; weight = 1298 };
  { key = "recipe.width.scoped_0199";                    label = "fallback_target_199";         arity = 2; tags = ["content"; "untyped"]; since = "1.9.0"; weight = 1252 };
  { key = "team.width.global_0200";                      label = "legacy_block_200";            arity = 0; tags = ["compat"]; since = "1.9.0"; weight = 761 };
  { key = "world.width.lazy_0201";                       label = "stable_region_201";           arity = 2; tags = ["typed"; "packet"]; since = "1.5.2"; weight = 1183 };
  { key = "target.width.provisional_0202";               label = "fallback_villager_202";       arity = 2; tags = ["registry"; "compat"; "emit"]; since = "1.0.0"; weight = 780 };
  { key = "advancement.width.canonical_0203";            label = "modern_barrel_203";           arity = 3; tags = ["untyped"]; since = "1.7.0"; weight = 1667 };
  { key = "anvil.width.local_0204";                      label = "strict_target_204";           arity = 3; tags = ["registry"; "check"; "emit"]; since = "1.8.3"; weight = 1727 };
  { key = "observer.width.derived_0205";                 label = "local_piston_205";            arity = 6; tags = ["content"; "check"]; since = "1.0.0"; weight = 2966 };
  { key = "grindstone.width.modern_0206";                label = "scoped_potion_206";           arity = 3; tags = ["cold"; "typed"; "codegen"]; since = "1.7.0"; weight = 1514 };
  { key = "world.width.modern_0207";                     label = "internal_grindstone_207";     arity = 6; tags = ["hot"]; since = "1.6.0"; weight = 2278 };
  { key = "barrel.width.provisional_0208";               label = "legacy_minecart_208";         arity = 2; tags = ["core"; "emit"; "packet"]; since = "1.9.0"; weight = 2249 };
  { key = "advancement.width.stable_0209";               label = "primary_particle_209";        arity = 5; tags = ["async"]; since = "1.7.0"; weight = 2687 };
  { key = "scoreboard.width.legacy_0210";                label = "legacy_tablist_210";          arity = 5; tags = ["experimental"]; since = "1.5.2"; weight = 2036 };
  { key = "shield.width.eager_0211";                     label = "primary_anvil_211";           arity = 7; tags = ["async"; "core"]; since = "1.7.0"; weight = 2903 };
  { key = "particle.width.lazy_0212";                    label = "provisional_loom_212";        arity = 1; tags = ["check"; "registry"; "parse"]; since = "1.0.0"; weight = 3877 };
  { key = "npc.width.derived_0213";                      label = "legacy_beacon_213";           arity = 1; tags = ["cached"]; since = "1.7.0"; weight = 2658 };
  { key = "boat.width.legacy_0214";                      label = "secondary_observer_214";      arity = 4; tags = ["codegen"]; since = "1.9.0"; weight = 2878 };
  { key = "campfire.width.primary_0215";                 label = "provisional_objective_215";   arity = 2; tags = ["legacy"]; since = "1.9.0"; weight = 1762 };
  { key = "composter.width.internal_0216";               label = "loose_observer_216";          arity = 6; tags = ["legacy"]; since = "1.0.0"; weight = 2925 };
  { key = "barrel.width.internal_0217";                  label = "loose_attribute_217";         arity = 2; tags = ["compat"]; since = "1.3.1"; weight = 2781 };
  { key = "map.width.strict_0218";                       label = "derived_item_218";            arity = 2; tags = ["runtime"; "codegen"]; since = "1.3.1"; weight = 452 };
  { key = "mob.width.fallback_0219";                     label = "canonical_chunk_219";         arity = 3; tags = ["cached"]; since = "1.2.0"; weight = 50 };
  { key = "hopper.width.public_0220";                    label = "public_observer_220";         arity = 4; tags = ["lower"; "parse"; "registry"]; since = "1.6.0"; weight = 1980 };
  { key = "hologram.width.eager_0221";                   label = "canonical_banner_221";        arity = 2; tags = ["experimental"]; since = "1.6.0"; weight = 908 };
  { key = "banner_pattern.width.eager_0222";             label = "lazy_comparator_222";         arity = 0; tags = ["hot"]; since = "1.6.0"; weight = 2335 };
  { key = "boat.width.canonical_0223";                   label = "cached_slot_223";             arity = 7; tags = ["experimental"]; since = "1.2.0"; weight = 1344 };
  { key = "slot.width.secondary_0224";                   label = "lazy_biome_224";              arity = 0; tags = ["legacy"; "packet"]; since = "1.9.0"; weight = 1107 };
  { key = "minecart.width.derived_0225";                 label = "internal_biome_225";          arity = 1; tags = ["core"; "runtime"; "registry"]; since = "1.0.0"; weight = 1973 };
  { key = "recipe.width.canonical_0226";                 label = "public_composter_226";        arity = 1; tags = ["packet"]; since = "1.3.1"; weight = 3417 };
  { key = "composter.width.local_0227";                  label = "scoped_pane_227";             arity = 1; tags = ["codegen"]; since = "1.3.1"; weight = 3827 };
  { key = "cartography.width.fallback_0228";             label = "legacy_repeater_228";         arity = 2; tags = ["untyped"]; since = "1.4.0"; weight = 1654 };
  { key = "region.width.scoped_0229";                    label = "eager_conduit_229";           arity = 2; tags = ["sync"; "content"; "check"]; since = "1.8.3"; weight = 3157 };
  { key = "villager.width.fallback_0230";                label = "stable_smithing_230";         arity = 7; tags = ["packet"; "untyped"]; since = "1.0.0"; weight = 2234 };
  { key = "trident.width.eager_0231";                    label = "legacy_banner_231";           arity = 1; tags = ["lower"]; since = "1.6.0"; weight = 2224 };
  { key = "attribute.width.secondary_0232";              label = "scoped_tablist_232";          arity = 4; tags = ["packet"; "check"; "hot"]; since = "1.9.0"; weight = 1607 };
  { key = "brewing.width.hidden_0233";                   label = "internal_conduit_233";        arity = 4; tags = ["codegen"]; since = "1.8.3"; weight = 1093 };
  { key = "loom.width.internal_0234";                    label = "loose_bell_234";              arity = 7; tags = ["parse"; "sync"]; since = "1.2.0"; weight = 2144 };
  { key = "rail.width.secondary_0235";                   label = "eager_composter_235";         arity = 4; tags = ["registry"]; since = "1.9.0"; weight = 696 };
  { key = "composter.width.canonical_0236";              label = "stable_villager_236";         arity = 0; tags = ["codegen"; "content"; "cold"]; since = "1.8.3"; weight = 3286 };
  { key = "campfire.width.scoped_0237";                  label = "modern_beacon_237";           arity = 5; tags = ["compat"; "legacy"; "lower"]; since = "1.8.3"; weight = 1779 };
  { key = "compass.width.cached_0238";                   label = "internal_furnace_238";        arity = 6; tags = ["codegen"; "emit"; "hot"]; since = "1.5.2"; weight = 3278 };
  { key = "smithing.width.internal_0239";                label = "public_lectern_239";          arity = 1; tags = ["emit"; "hot"]; since = "1.2.0"; weight = 3593 };
  { key = "loom.width.modern_0240";                      label = "primary_arrow_240";           arity = 5; tags = ["hot"]; since = "1.6.0"; weight = 2278 };
  { key = "crossbow.width.eager_0241";                   label = "scoped_anvil_241";            arity = 2; tags = ["runtime"; "typed"; "parse"]; since = "1.4.0"; weight = 2086 };
  { key = "repeater.width.primary_0242";                 label = "fallback_dispenser_242";      arity = 1; tags = ["typed"]; since = "1.3.1"; weight = 1575 };
  { key = "shulker.width.fallback_0243";                 label = "secondary_brewing_243";       arity = 6; tags = ["core"; "compat"; "sync"]; since = "1.0.0"; weight = 1333 };
  { key = "compass.width.global_0244";                   label = "eager_slot_244";              arity = 1; tags = ["typed"; "cold"]; since = "1.3.1"; weight = 1105 };
  { key = "bundle.width.secondary_0245";                 label = "cached_banner_pattern_245";   arity = 2; tags = ["legacy"]; since = "1.3.1"; weight = 474 };
  { key = "map.width.global_0246";                       label = "hidden_banner_pattern_246";   arity = 1; tags = ["registry"; "typed"; "emit"]; since = "1.6.0"; weight = 2445 };
  { key = "trident.width.strict_0247";                   label = "internal_gui_247";            arity = 7; tags = ["lower"; "legacy"]; since = "1.4.0"; weight = 531 };
  { key = "player.width.local_0248";                     label = "hidden_world_248";            arity = 1; tags = ["codegen"; "content"; "emit"]; since = "1.3.1"; weight = 2733 };
  { key = "anvil.width.global_0249";                     label = "loose_player_249";            arity = 7; tags = ["lower"; "parse"; "check"]; since = "1.8.3"; weight = 2279 };
  { key = "anvil.width.modern_0250";                     label = "strict_team_250";             arity = 5; tags = ["async"; "content"]; since = "1.8.3"; weight = 4061 };
  { key = "elytra.width.scoped_0251";                    label = "loose_sound_251";             arity = 2; tags = ["registry"; "parse"]; since = "1.9.0"; weight = 1837 };
  { key = "smithing.width.legacy_0252";                  label = "local_slot_252";              arity = 5; tags = ["check"]; since = "1.6.0"; weight = 1093 };
  { key = "chunk.width.cached_0253";                     label = "lazy_clock_253";              arity = 1; tags = ["typed"; "check"; "sync"]; since = "1.4.0"; weight = 1889 };
  { key = "mob.width.strict_0254";                       label = "stable_grindstone_254";       arity = 7; tags = ["sync"; "content"]; since = "1.2.0"; weight = 1506 };
  { key = "trident.width.primary_0255";                  label = "global_bossbar_255";          arity = 6; tags = ["registry"; "lower"; "untyped"]; since = "1.6.0"; weight = 3534 };
  { key = "map.width.primary_0256";                      label = "primary_enchant_256";         arity = 4; tags = ["legacy"; "hot"; "cold"]; since = "1.0.0"; weight = 1175 };
  { key = "portal.width.lazy_0257";                      label = "legacy_firework_257";         arity = 0; tags = ["experimental"; "check"; "compat"]; since = "1.2.0"; weight = 823 };
  { key = "structure.width.provisional_0258";            label = "scoped_gui_258";              arity = 6; tags = ["typed"; "async"; "emit"]; since = "1.7.0"; weight = 1323 };
  { key = "observer.width.eager_0259";                   label = "public_region_259";           arity = 3; tags = ["hot"; "cached"]; since = "1.0.0"; weight = 4021 };
  { key = "scoreboard.width.internal_0260";              label = "cached_smoker_260";           arity = 2; tags = ["async"]; since = "1.6.0"; weight = 3902 };
  { key = "trident.width.global_0261";                   label = "secondary_observer_261";      arity = 5; tags = ["core"; "typed"]; since = "1.4.0"; weight = 4013 };
  { key = "packet.width.loose_0262";                     label = "scoped_smithing_262";         arity = 1; tags = ["lower"]; since = "1.2.0"; weight = 294 };
  { key = "target.width.secondary_0263";                 label = "secondary_mob_263";           arity = 4; tags = ["parse"]; since = "1.0.0"; weight = 4073 };
  { key = "item.width.strict_0264";                      label = "loose_structure_264";         arity = 4; tags = ["sync"; "parse"]; since = "1.0.0"; weight = 1954 };
  { key = "chunk.width.local_0265";                      label = "global_banner_265";           arity = 4; tags = ["packet"; "hot"; "codegen"]; since = "1.0.0"; weight = 2994 };
  { key = "composter.width.public_0266";                 label = "scoped_advancement_266";      arity = 1; tags = ["sync"; "lower"; "async"]; since = "1.3.1"; weight = 2110 };
  { key = "block.width.secondary_0267";                  label = "primary_smoker_267";          arity = 3; tags = ["content"]; since = "1.8.3"; weight = 4010 };
  { key = "lectern.width.legacy_0268";                   label = "lazy_clock_268";              arity = 1; tags = ["hot"; "experimental"]; since = "1.8.3"; weight = 3575 };
  { key = "attribute.width.public_0269";                 label = "lazy_observer_269";           arity = 7; tags = ["cold"; "core"]; since = "1.7.0"; weight = 1512 };
  { key = "objective.width.internal_0270";               label = "eager_block_270";             arity = 0; tags = ["hot"; "content"]; since = "1.0.0"; weight = 2430 };
  { key = "beacon.width.loose_0271";                     label = "stable_spawner_271";          arity = 4; tags = ["untyped"]; since = "1.5.2"; weight = 420 };
  { key = "observer.width.strict_0272";                  label = "loose_npc_272";               arity = 7; tags = ["async"]; since = "1.5.2"; weight = 3320 };
  { key = "team.width.local_0273";                       label = "primary_banner_pattern_273";  arity = 6; tags = ["async"]; since = "1.4.0"; weight = 1273 };
  { key = "gui.width.derived_0274";                      label = "canonical_observer_274";      arity = 7; tags = ["compat"; "cached"; "cold"]; since = "1.0.0"; weight = 15 };
  { key = "arrow.width.stable_0275";                     label = "provisional_observer_275";    arity = 4; tags = ["untyped"; "runtime"; "sync"]; since = "1.6.0"; weight = 472 };
  { key = "potion.width.strict_0276";                    label = "primary_player_276";          arity = 5; tags = ["async"]; since = "1.9.0"; weight = 2563 };
  { key = "minecart.width.strict_0277";                  label = "strict_trade_277";            arity = 7; tags = ["emit"]; since = "1.2.0"; weight = 1493 };
  { key = "recipe.width.fallback_0278";                  label = "public_trident_278";          arity = 5; tags = ["packet"; "typed"]; since = "1.7.0"; weight = 2309 };
  { key = "player.width.fallback_0279";                  label = "stable_boat_279";             arity = 0; tags = ["experimental"]; since = "1.9.0"; weight = 1190 };
  { key = "packet.width.public_0280";                    label = "fallback_grindstone_280";     arity = 0; tags = ["lower"]; since = "1.4.0"; weight = 2388 };
  { key = "target.width.internal_0281";                  label = "hidden_recipe_281";           arity = 1; tags = ["sync"; "lower"]; since = "1.0.0"; weight = 2577 };
  { key = "team.width.cached_0282";                      label = "stable_npc_282";              arity = 1; tags = ["compat"]; since = "1.8.3"; weight = 2310 };
  { key = "tablist.width.hidden_0283";                   label = "provisional_piston_283";      arity = 7; tags = ["parse"; "content"; "hot"]; since = "1.2.0"; weight = 3385 };
  { key = "barrel.width.secondary_0284";                 label = "provisional_pane_284";        arity = 2; tags = ["untyped"; "experimental"; "cached"]; since = "1.3.1"; weight = 3806 };
  { key = "crossbow.width.provisional_0285";             label = "derived_attribute_285";       arity = 7; tags = ["typed"]; since = "1.9.0"; weight = 947 };
  { key = "loom.width.local_0286";                       label = "strict_smithing_286";         arity = 4; tags = ["async"; "runtime"; "lower"]; since = "1.8.3"; weight = 3880 };
  { key = "world.width.modern_0287";                     label = "strict_inventory_287";        arity = 1; tags = ["core"; "parse"; "registry"]; since = "1.2.0"; weight = 1975 };
  { key = "stonecutter.width.canonical_0288";            label = "fallback_elytra_288";         arity = 5; tags = ["compat"; "typed"]; since = "1.9.0"; weight = 110 };
]

let count = List.length entries

let table : (string, width_entry) Hashtbl.t =
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
