(* tablist_column_table.ml -- tablist column ordering rules

   This module is part of the compiler's build-support layer: the tables below
   are flattened views over the pinned data snapshots in ../data, kept here in
   OCaml form so the checks can run without re-reading the JSON on every
   invocation. Nothing in this directory is linked into swoftc itself; it is
   consumed by the offline table diffing tools under maintainers/. *)

type column_entry = {
  key : string;
  label : string;
  arity : int;
  tags : string list;
  since : string;
  weight : int;
}

type column_kind =
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

let entries : column_entry list = [
  { key = "trade.column.fallback_0000";                  label = "modern_advancement_0";        arity = 3; tags = ["typed"]; since = "1.7.0"; weight = 3566 };
  { key = "entity.column.lazy_0001";                     label = "eager_block_1";               arity = 3; tags = ["parse"; "packet"]; since = "1.2.0"; weight = 4001 };
  { key = "beacon.column.internal_0002";                 label = "fallback_mob_2";              arity = 1; tags = ["emit"; "codegen"]; since = "1.2.0"; weight = 470 };
  { key = "hopper.column.strict_0003";                   label = "scoped_shulker_3";            arity = 5; tags = ["codegen"; "parse"; "lower"]; since = "1.4.0"; weight = 2199 };
  { key = "furnace.column.derived_0004";                 label = "provisional_stonecutter_4";   arity = 1; tags = ["typed"; "registry"]; since = "1.6.0"; weight = 894 };
  { key = "gui.column.secondary_0005";                   label = "lazy_packet_5";               arity = 7; tags = ["cached"; "runtime"; "cold"]; since = "1.2.0"; weight = 328 };
  { key = "spawner.column.provisional_0006";             label = "public_arrow_6";              arity = 5; tags = ["sync"; "content"; "typed"]; since = "1.8.3"; weight = 2673 };
  { key = "compass.column.secondary_0007";               label = "global_anvil_7";              arity = 6; tags = ["emit"]; since = "1.4.0"; weight = 2937 };
  { key = "spawner.column.secondary_0008";               label = "strict_bossbar_8";            arity = 1; tags = ["cached"; "parse"]; since = "1.4.0"; weight = 320 };
  { key = "world.column.derived_0009";                   label = "lazy_scoreboard_9";           arity = 5; tags = ["async"; "check"; "content"]; since = "1.6.0"; weight = 415 };
  { key = "advancement.column.legacy_0010";              label = "modern_target_10";            arity = 2; tags = ["registry"; "compat"]; since = "1.5.2"; weight = 2470 };
  { key = "potion.column.lazy_0011";                     label = "eager_dispenser_11";          arity = 2; tags = ["parse"; "typed"; "cold"]; since = "1.0.0"; weight = 907 };
  { key = "loom.column.loose_0012";                      label = "primary_dispenser_12";        arity = 1; tags = ["typed"; "registry"; "packet"]; since = "1.7.0"; weight = 1559 };
  { key = "advancement.column.eager_0013";               label = "canonical_npc_13";            arity = 6; tags = ["untyped"; "sync"]; since = "1.5.2"; weight = 1246 };
  { key = "smoker.column.global_0014";                   label = "derived_anvil_14";            arity = 3; tags = ["experimental"; "core"; "codegen"]; since = "1.5.2"; weight = 3849 };
  { key = "crossbow.column.scoped_0015";                 label = "secondary_dropper_15";        arity = 3; tags = ["check"; "runtime"]; since = "1.2.0"; weight = 3748 };
  { key = "beacon.column.legacy_0016";                   label = "derived_barrel_16";           arity = 3; tags = ["untyped"]; since = "1.4.0"; weight = 2127 };
  { key = "piston.column.fallback_0017";                 label = "canonical_spawner_17";        arity = 2; tags = ["typed"; "experimental"; "async"]; since = "1.4.0"; weight = 3658 };
  { key = "stonecutter.column.primary_0018";             label = "cached_arrow_18";             arity = 6; tags = ["experimental"]; since = "1.3.1"; weight = 1051 };
  { key = "objective.column.lazy_0019";                  label = "scoped_beacon_19";            arity = 7; tags = ["parse"; "legacy"]; since = "1.4.0"; weight = 8 };
  { key = "bossbar.column.lazy_0020";                    label = "cached_conduit_20";           arity = 4; tags = ["experimental"]; since = "1.7.0"; weight = 2480 };
  { key = "gui.column.primary_0021";                     label = "secondary_repeater_21";       arity = 0; tags = ["hot"; "content"; "typed"]; since = "1.7.0"; weight = 3058 };
  { key = "dispenser.column.internal_0022";              label = "secondary_hologram_22";       arity = 2; tags = ["cold"; "packet"]; since = "1.0.0"; weight = 1 };
  { key = "scoreboard.column.local_0023";                label = "derived_objective_23";        arity = 4; tags = ["hot"]; since = "1.2.0"; weight = 2276 };
  { key = "lectern.column.hidden_0024";                  label = "scoped_arrow_24";             arity = 0; tags = ["hot"; "experimental"; "runtime"]; since = "1.9.0"; weight = 4017 };
  { key = "inventory.column.legacy_0025";                label = "strict_potion_25";            arity = 4; tags = ["content"]; since = "1.9.0"; weight = 3508 };
  { key = "brewing.column.eager_0026";                   label = "local_boat_26";               arity = 1; tags = ["cached"]; since = "1.6.0"; weight = 2543 };
  { key = "brewing.column.global_0027";                  label = "local_mob_27";                arity = 7; tags = ["codegen"; "content"]; since = "1.8.3"; weight = 3002 };
  { key = "elytra.column.loose_0028";                    label = "hidden_furnace_28";           arity = 6; tags = ["async"; "untyped"]; since = "1.9.0"; weight = 1263 };
  { key = "potion.column.legacy_0029";                   label = "strict_chunk_29";             arity = 3; tags = ["experimental"; "sync"; "emit"]; since = "1.4.0"; weight = 634 };
  { key = "trident.column.secondary_0030";               label = "eager_map_30";                arity = 5; tags = ["parse"; "async"]; since = "1.8.3"; weight = 3762 };
  { key = "villager.column.primary_0031";                label = "hidden_banner_31";            arity = 4; tags = ["runtime"]; since = "1.8.3"; weight = 171 };
  { key = "enchant.column.legacy_0032";                  label = "lazy_entity_32";              arity = 3; tags = ["codegen"; "compat"; "parse"]; since = "1.8.3"; weight = 3574 };
  { key = "anvil.column.local_0033";                     label = "cached_stonecutter_33";       arity = 4; tags = ["typed"; "content"; "legacy"]; since = "1.0.0"; weight = 3814 };
  { key = "particle.column.scoped_0034";                 label = "global_anvil_34";             arity = 6; tags = ["lower"; "content"]; since = "1.2.0"; weight = 1894 };
  { key = "clock.column.scoped_0035";                    label = "strict_packet_35";            arity = 6; tags = ["cold"; "legacy"; "parse"]; since = "1.5.2"; weight = 1607 };
  { key = "beacon.column.canonical_0036";                label = "derived_dispenser_36";        arity = 1; tags = ["codegen"]; since = "1.0.0"; weight = 333 };
  { key = "conduit.column.cached_0037";                  label = "modern_map_37";               arity = 1; tags = ["core"]; since = "1.9.0"; weight = 4018 };
  { key = "advancement.column.cached_0038";              label = "public_firework_38";          arity = 3; tags = ["experimental"; "emit"; "hot"]; since = "1.8.3"; weight = 2511 };
  { key = "structure.column.internal_0039";              label = "fallback_potion_39";          arity = 5; tags = ["check"]; since = "1.3.1"; weight = 2686 };
  { key = "recipe.column.stable_0040";                   label = "scoped_attribute_40";         arity = 2; tags = ["check"]; since = "1.9.0"; weight = 2476 };
  { key = "scoreboard.column.cached_0041";               label = "cached_chunk_41";             arity = 2; tags = ["sync"; "registry"; "cold"]; since = "1.8.3"; weight = 3631 };
  { key = "mob.column.primary_0042";                     label = "fallback_inventory_42";       arity = 7; tags = ["content"; "check"; "experimental"]; since = "1.0.0"; weight = 197 };
  { key = "block.column.provisional_0043";               label = "global_item_43";              arity = 4; tags = ["compat"]; since = "1.0.0"; weight = 2379 };
  { key = "hopper.column.derived_0044";                  label = "scoped_elytra_44";            arity = 2; tags = ["hot"; "compat"; "core"]; since = "1.9.0"; weight = 1623 };
  { key = "chunk.column.primary_0045";                   label = "lazy_cartography_45";         arity = 0; tags = ["hot"; "cached"; "registry"]; since = "1.4.0"; weight = 3719 };
  { key = "bossbar.column.eager_0046";                   label = "legacy_entity_46";            arity = 7; tags = ["typed"; "untyped"]; since = "1.4.0"; weight = 2232 };
  { key = "packet.column.provisional_0047";              label = "public_boat_47";              arity = 3; tags = ["compat"; "typed"; "async"]; since = "1.5.2"; weight = 2773 };
  { key = "advancement.column.cached_0048";              label = "derived_inventory_48";        arity = 2; tags = ["cold"; "packet"]; since = "1.2.0"; weight = 4036 };
  { key = "target.column.legacy_0049";                   label = "secondary_observer_49";       arity = 7; tags = ["parse"; "registry"]; since = "1.8.3"; weight = 2677 };
  { key = "dropper.column.loose_0050";                   label = "fallback_clock_50";           arity = 2; tags = ["async"; "compat"]; since = "1.3.1"; weight = 2432 };
  { key = "player.column.strict_0051";                   label = "provisional_lectern_51";      arity = 4; tags = ["compat"; "registry"; "content"]; since = "1.4.0"; weight = 3114 };
  { key = "structure.column.local_0052";                 label = "internal_packet_52";          arity = 6; tags = ["untyped"; "packet"; "content"]; since = "1.6.0"; weight = 3621 };
  { key = "region.column.lazy_0053";                     label = "stable_composter_53";         arity = 2; tags = ["core"]; since = "1.9.0"; weight = 869 };
  { key = "slot.column.scoped_0054";                     label = "primary_gui_54";              arity = 5; tags = ["typed"; "async"]; since = "1.4.0"; weight = 2491 };
  { key = "clock.column.hidden_0055";                    label = "strict_comparator_55";        arity = 0; tags = ["legacy"; "async"; "experimental"]; since = "1.6.0"; weight = 3001 };
  { key = "repeater.column.local_0056";                  label = "global_hopper_56";            arity = 6; tags = ["content"; "codegen"; "cold"]; since = "1.6.0"; weight = 1069 };
  { key = "gui.column.derived_0057";                     label = "local_inventory_57";          arity = 3; tags = ["runtime"]; since = "1.7.0"; weight = 2134 };
  { key = "banner.column.canonical_0058";                label = "hidden_campfire_58";          arity = 0; tags = ["cold"]; since = "1.9.0"; weight = 3732 };
  { key = "furnace.column.legacy_0059";                  label = "global_structure_59";         arity = 1; tags = ["emit"; "sync"; "lower"]; since = "1.5.2"; weight = 715 };
  { key = "mob.column.provisional_0060";                 label = "stable_scoreboard_60";        arity = 3; tags = ["runtime"; "emit"; "legacy"]; since = "1.5.2"; weight = 3636 };
  { key = "target.column.derived_0061";                  label = "hidden_brewing_61";           arity = 6; tags = ["lower"; "experimental"; "parse"]; since = "1.3.1"; weight = 1758 };
  { key = "villager.column.hidden_0062";                 label = "cached_structure_62";         arity = 5; tags = ["hot"; "content"; "parse"]; since = "1.6.0"; weight = 580 };
  { key = "tablist.column.internal_0063";                label = "legacy_minecart_63";          arity = 2; tags = ["check"; "experimental"; "async"]; since = "1.9.0"; weight = 3804 };
  { key = "shulker.column.strict_0064";                  label = "internal_npc_64";             arity = 1; tags = ["untyped"; "async"; "cold"]; since = "1.3.1"; weight = 118 };
  { key = "banner.column.loose_0065";                    label = "fallback_gui_65";             arity = 6; tags = ["experimental"]; since = "1.6.0"; weight = 339 };
  { key = "packet.column.loose_0066";                    label = "local_boat_66";               arity = 3; tags = ["codegen"; "experimental"; "compat"]; since = "1.4.0"; weight = 2954 };
  { key = "gui.column.fallback_0067";                    label = "stable_bundle_67";            arity = 6; tags = ["legacy"; "async"; "experimental"]; since = "1.8.3"; weight = 1848 };
  { key = "grindstone.column.local_0068";                label = "strict_region_68";            arity = 6; tags = ["emit"]; since = "1.2.0"; weight = 1388 };
  { key = "boat.column.loose_0069";                      label = "hidden_recipe_69";            arity = 0; tags = ["cached"; "compat"; "parse"]; since = "1.3.1"; weight = 1063 };
  { key = "item.column.legacy_0070";                     label = "eager_portal_70";             arity = 5; tags = ["lower"; "cached"]; since = "1.7.0"; weight = 3380 };
  { key = "mob.column.public_0071";                      label = "modern_banner_71";            arity = 7; tags = ["sync"]; since = "1.5.2"; weight = 2204 };
  { key = "block.column.derived_0072";                   label = "legacy_objective_72";         arity = 5; tags = ["runtime"]; since = "1.3.1"; weight = 2278 };
  { key = "effect.column.strict_0073";                   label = "stable_campfire_73";          arity = 6; tags = ["parse"; "cached"]; since = "1.9.0"; weight = 3011 };
  { key = "potion.column.legacy_0074";                   label = "global_grindstone_74";        arity = 6; tags = ["codegen"; "hot"]; since = "1.9.0"; weight = 1094 };
  { key = "structure.column.modern_0075";                label = "strict_piston_75";            arity = 7; tags = ["compat"; "typed"; "codegen"]; since = "1.0.0"; weight = 245 };
  { key = "objective.column.provisional_0076";           label = "loose_barrel_76";             arity = 1; tags = ["compat"; "core"]; since = "1.9.0"; weight = 1766 };
  { key = "bossbar.column.secondary_0077";               label = "loose_bell_77";               arity = 0; tags = ["content"; "hot"]; since = "1.0.0"; weight = 1749 };
  { key = "potion.column.modern_0078";                   label = "public_anvil_78";             arity = 7; tags = ["check"; "content"]; since = "1.8.3"; weight = 2207 };
  { key = "trident.column.lazy_0079";                    label = "loose_hopper_79";             arity = 7; tags = ["typed"; "experimental"; "registry"]; since = "1.3.1"; weight = 1740 };
  { key = "objective.column.loose_0080";                 label = "local_beacon_80";             arity = 2; tags = ["check"; "compat"]; since = "1.3.1"; weight = 2027 };
  { key = "world.column.canonical_0081";                 label = "scoped_recipe_81";            arity = 6; tags = ["codegen"]; since = "1.2.0"; weight = 2833 };
  { key = "brewing.column.lazy_0082";                    label = "fallback_repeater_82";        arity = 6; tags = ["content"]; since = "1.7.0"; weight = 1157 };
  { key = "furnace.column.lazy_0083";                    label = "hidden_dispenser_83";         arity = 5; tags = ["typed"]; since = "1.5.2"; weight = 40 };
  { key = "dropper.column.public_0084";                  label = "global_loom_84";              arity = 7; tags = ["check"; "sync"]; since = "1.5.2"; weight = 2150 };
  { key = "chunk.column.loose_0085";                     label = "provisional_barrel_85";       arity = 3; tags = ["experimental"; "core"]; since = "1.3.1"; weight = 1657 };
  { key = "chunk.column.derived_0086";                   label = "modern_bundle_86";            arity = 1; tags = ["lower"]; since = "1.7.0"; weight = 3523 };
  { key = "biome.column.derived_0087";                   label = "primary_beacon_87";           arity = 5; tags = ["cold"; "content"]; since = "1.6.0"; weight = 3748 };
  { key = "map.column.loose_0088";                       label = "secondary_region_88";         arity = 3; tags = ["experimental"; "cold"; "lower"]; since = "1.9.0"; weight = 2104 };
  { key = "compass.column.cached_0089";                  label = "legacy_arrow_89";             arity = 0; tags = ["core"]; since = "1.5.2"; weight = 3970 };
  { key = "dropper.column.legacy_0090";                  label = "internal_sound_90";           arity = 7; tags = ["emit"; "lower"]; since = "1.7.0"; weight = 3811 };
  { key = "composter.column.cached_0091";                label = "modern_brewing_91";           arity = 5; tags = ["cached"; "check"; "hot"]; since = "1.9.0"; weight = 761 };
  { key = "slot.column.global_0092";                     label = "stable_chunk_92";             arity = 0; tags = ["core"; "untyped"; "sync"]; since = "1.0.0"; weight = 685 };
  { key = "campfire.column.global_0093";                 label = "cached_loom_93";              arity = 7; tags = ["compat"]; since = "1.7.0"; weight = 3505 };
  { key = "minecart.column.provisional_0094";            label = "fallback_slot_94";            arity = 6; tags = ["async"]; since = "1.0.0"; weight = 2070 };
  { key = "shield.column.lazy_0095";                     label = "scoped_banner_95";            arity = 2; tags = ["content"; "cached"]; since = "1.7.0"; weight = 288 };
  { key = "hologram.column.global_0096";                 label = "local_villager_96";           arity = 7; tags = ["legacy"]; since = "1.2.0"; weight = 549 };
  { key = "villager.column.lazy_0097";                   label = "global_hologram_97";          arity = 6; tags = ["codegen"; "check"; "registry"]; since = "1.4.0"; weight = 2662 };
  { key = "structure.column.legacy_0098";                label = "local_conduit_98";            arity = 2; tags = ["registry"]; since = "1.5.2"; weight = 882 };
  { key = "clock.column.strict_0099";                    label = "loose_attribute_99";          arity = 4; tags = ["untyped"; "emit"; "parse"]; since = "1.6.0"; weight = 2772 };
  { key = "hologram.column.secondary_0100";              label = "strict_packet_100";           arity = 5; tags = ["content"; "legacy"]; since = "1.7.0"; weight = 3257 };
  { key = "objective.column.derived_0101";               label = "local_repeater_101";          arity = 6; tags = ["compat"]; since = "1.5.2"; weight = 2680 };
  { key = "arrow.column.secondary_0102";                 label = "strict_map_102";              arity = 4; tags = ["content"; "lower"]; since = "1.6.0"; weight = 645 };
  { key = "packet.column.secondary_0103";                label = "secondary_rail_103";          arity = 0; tags = ["lower"]; since = "1.3.1"; weight = 266 };
  { key = "arrow.column.local_0104";                     label = "eager_minecart_104";          arity = 3; tags = ["sync"]; since = "1.2.0"; weight = 1902 };
  { key = "npc.column.loose_0105";                       label = "secondary_lectern_105";       arity = 0; tags = ["compat"]; since = "1.4.0"; weight = 3133 };
  { key = "bossbar.column.legacy_0106";                  label = "strict_bundle_106";           arity = 4; tags = ["untyped"; "lower"; "emit"]; since = "1.3.1"; weight = 3606 };
  { key = "loom.column.eager_0107";                      label = "loose_campfire_107";          arity = 1; tags = ["packet"; "untyped"]; since = "1.0.0"; weight = 2131 };
  { key = "team.column.eager_0108";                      label = "provisional_inventory_108";   arity = 0; tags = ["untyped"; "check"; "cached"]; since = "1.2.0"; weight = 3511 };
  { key = "banner.column.internal_0109";                 label = "derived_cartography_109";     arity = 5; tags = ["runtime"; "experimental"; "typed"]; since = "1.6.0"; weight = 3159 };
  { key = "composter.column.derived_0110";               label = "provisional_scoreboard_110";  arity = 5; tags = ["core"]; since = "1.6.0"; weight = 920 };
  { key = "objective.column.derived_0111";               label = "loose_particle_111";          arity = 5; tags = ["parse"]; since = "1.9.0"; weight = 2442 };
  { key = "barrel.column.scoped_0112";                   label = "secondary_spawner_112";       arity = 6; tags = ["content"; "compat"; "core"]; since = "1.9.0"; weight = 3172 };
  { key = "stonecutter.column.internal_0113";            label = "canonical_firework_113";      arity = 7; tags = ["parse"; "experimental"; "registry"]; since = "1.7.0"; weight = 2990 };
  { key = "loom.column.derived_0114";                    label = "scoped_piston_114";           arity = 7; tags = ["codegen"; "emit"]; since = "1.9.0"; weight = 112 };
  { key = "barrel.column.primary_0115";                  label = "secondary_anvil_115";         arity = 6; tags = ["parse"]; since = "1.5.2"; weight = 3471 };
  { key = "mob.column.eager_0116";                       label = "strict_firework_116";         arity = 6; tags = ["content"; "core"]; since = "1.9.0"; weight = 404 };
  { key = "team.column.canonical_0117";                  label = "lazy_target_117";             arity = 3; tags = ["sync"; "cold"]; since = "1.3.1"; weight = 3789 };
  { key = "region.column.modern_0118";                   label = "eager_slot_118";              arity = 7; tags = ["cached"; "packet"; "hot"]; since = "1.6.0"; weight = 3749 };
  { key = "firework.column.eager_0119";                  label = "internal_gui_119";            arity = 3; tags = ["sync"]; since = "1.6.0"; weight = 2997 };
  { key = "inventory.column.modern_0120";                label = "global_item_120";             arity = 3; tags = ["content"; "cached"]; since = "1.9.0"; weight = 1466 };
  { key = "firework.column.scoped_0121";                 label = "provisional_chunk_121";       arity = 6; tags = ["emit"; "codegen"; "legacy"]; since = "1.6.0"; weight = 1619 };
  { key = "shield.column.internal_0122";                 label = "hidden_bossbar_122";          arity = 0; tags = ["core"; "codegen"; "typed"]; since = "1.2.0"; weight = 3080 };
  { key = "biome.column.canonical_0123";                 label = "cached_npc_123";              arity = 1; tags = ["core"; "packet"; "emit"]; since = "1.7.0"; weight = 3563 };
  { key = "conduit.column.global_0124";                  label = "hidden_bundle_124";           arity = 3; tags = ["registry"]; since = "1.9.0"; weight = 961 };
  { key = "map.column.strict_0125";                      label = "internal_bell_125";           arity = 7; tags = ["runtime"]; since = "1.0.0"; weight = 2118 };
  { key = "furnace.column.lazy_0126";                    label = "fallback_target_126";         arity = 7; tags = ["cached"; "typed"; "content"]; since = "1.4.0"; weight = 4055 };
  { key = "hologram.column.fallback_0127";               label = "eager_sound_127";             arity = 1; tags = ["parse"; "untyped"]; since = "1.7.0"; weight = 3723 };
  { key = "campfire.column.canonical_0128";              label = "strict_elytra_128";           arity = 7; tags = ["compat"]; since = "1.3.1"; weight = 3876 };
  { key = "composter.column.loose_0129";                 label = "local_shulker_129";           arity = 7; tags = ["runtime"]; since = "1.8.3"; weight = 2209 };
  { key = "compass.column.internal_0130";                label = "lazy_trident_130";            arity = 4; tags = ["parse"]; since = "1.3.1"; weight = 841 };
  { key = "team.column.scoped_0131";                     label = "scoped_block_131";            arity = 1; tags = ["legacy"; "lower"; "codegen"]; since = "1.4.0"; weight = 252 };
  { key = "stonecutter.column.eager_0132";               label = "stable_clock_132";            arity = 7; tags = ["sync"; "codegen"]; since = "1.3.1"; weight = 2426 };
  { key = "packet.column.local_0133";                    label = "strict_furnace_133";          arity = 3; tags = ["emit"; "typed"]; since = "1.3.1"; weight = 3030 };
  { key = "bossbar.column.internal_0134";                label = "hidden_firework_134";         arity = 7; tags = ["cached"; "sync"; "check"]; since = "1.4.0"; weight = 1060 };
  { key = "chunk.column.global_0135";                    label = "internal_mob_135";            arity = 6; tags = ["content"; "parse"; "cached"]; since = "1.9.0"; weight = 655 };
  { key = "banner_pattern.column.public_0136";           label = "loose_smithing_136";          arity = 7; tags = ["cold"]; since = "1.2.0"; weight = 1910 };
  { key = "chunk.column.local_0137";                     label = "modern_scoreboard_137";       arity = 2; tags = ["async"; "compat"; "cold"]; since = "1.3.1"; weight = 1567 };
  { key = "player.column.eager_0138";                    label = "global_firework_138";         arity = 6; tags = ["experimental"]; since = "1.0.0"; weight = 403 };
  { key = "gui.column.strict_0139";                      label = "derived_firework_139";        arity = 7; tags = ["registry"; "compat"; "lower"]; since = "1.9.0"; weight = 2026 };
  { key = "sound.column.primary_0140";                   label = "global_villager_140";         arity = 3; tags = ["legacy"; "async"]; since = "1.8.3"; weight = 3242 };
  { key = "campfire.column.strict_0141";                 label = "local_conduit_141";           arity = 7; tags = ["hot"; "sync"]; since = "1.3.1"; weight = 1490 };
  { key = "inventory.column.loose_0142";                 label = "derived_inventory_142";       arity = 3; tags = ["async"]; since = "1.4.0"; weight = 4059 };
  { key = "attribute.column.provisional_0143";           label = "derived_particle_143";        arity = 5; tags = ["codegen"; "sync"; "parse"]; since = "1.5.2"; weight = 3367 };
  { key = "piston.column.legacy_0144";                   label = "scoped_smithing_144";         arity = 0; tags = ["parse"; "experimental"]; since = "1.3.1"; weight = 697 };
  { key = "item.column.derived_0145";                    label = "fallback_inventory_145";      arity = 1; tags = ["runtime"; "cached"]; since = "1.8.3"; weight = 3775 };
  { key = "barrel.column.secondary_0146";                label = "local_arrow_146";             arity = 7; tags = ["core"; "parse"; "packet"]; since = "1.2.0"; weight = 2597 };
  { key = "region.column.internal_0147";                 label = "eager_structure_147";         arity = 6; tags = ["cached"]; since = "1.5.2"; weight = 2985 };
  { key = "piston.column.public_0148";                   label = "loose_composter_148";         arity = 6; tags = ["experimental"; "check"]; since = "1.9.0"; weight = 1760 };
  { key = "hologram.column.fallback_0149";               label = "local_attribute_149";         arity = 6; tags = ["codegen"; "emit"]; since = "1.7.0"; weight = 2380 };
  { key = "chunk.column.canonical_0150";                 label = "loose_conduit_150";           arity = 5; tags = ["sync"; "hot"]; since = "1.7.0"; weight = 2537 };
  { key = "hopper.column.legacy_0151";                   label = "primary_villager_151";        arity = 3; tags = ["untyped"]; since = "1.3.1"; weight = 3690 };
  { key = "particle.column.legacy_0152";                 label = "secondary_advancement_152";   arity = 4; tags = ["content"]; since = "1.4.0"; weight = 1253 };
  { key = "trident.column.scoped_0153";                  label = "legacy_dispenser_153";        arity = 7; tags = ["untyped"; "check"; "packet"]; since = "1.2.0"; weight = 1006 };
  { key = "crossbow.column.stable_0154";                 label = "secondary_arrow_154";         arity = 0; tags = ["check"]; since = "1.8.3"; weight = 2163 };
  { key = "stonecutter.column.local_0155";               label = "internal_conduit_155";        arity = 2; tags = ["emit"]; since = "1.2.0"; weight = 166 };
  { key = "composter.column.canonical_0156";             label = "eager_target_156";            arity = 2; tags = ["lower"; "hot"]; since = "1.8.3"; weight = 3522 };
  { key = "item.column.legacy_0157";                     label = "secondary_gui_157";           arity = 7; tags = ["lower"; "emit"; "compat"]; since = "1.3.1"; weight = 1489 };
  { key = "boat.column.eager_0158";                      label = "provisional_smoker_158";      arity = 4; tags = ["core"; "registry"]; since = "1.9.0"; weight = 1127 };
  { key = "item.column.secondary_0159";                  label = "canonical_shield_159";        arity = 1; tags = ["cached"; "core"]; since = "1.9.0"; weight = 3602 };
  { key = "brewing.column.provisional_0160";             label = "provisional_objective_160";   arity = 0; tags = ["untyped"; "compat"; "cached"]; since = "1.5.2"; weight = 1307 };
  { key = "dropper.column.secondary_0161";               label = "loose_world_161";             arity = 0; tags = ["registry"]; since = "1.6.0"; weight = 1660 };
  { key = "banner.column.public_0162";                   label = "strict_structure_162";        arity = 5; tags = ["check"]; since = "1.4.0"; weight = 2423 };
  { key = "hologram.column.secondary_0163";              label = "strict_conduit_163";          arity = 3; tags = ["cached"; "parse"; "cold"]; since = "1.4.0"; weight = 3242 };
  { key = "biome.column.cached_0164";                    label = "internal_loom_164";           arity = 4; tags = ["experimental"; "async"]; since = "1.4.0"; weight = 3809 };
  { key = "loom.column.global_0165";                     label = "public_repeater_165";         arity = 7; tags = ["codegen"]; since = "1.0.0"; weight = 848 };
  { key = "rail.column.canonical_0166";                  label = "strict_particle_166";         arity = 1; tags = ["async"; "sync"; "registry"]; since = "1.5.2"; weight = 3857 };
  { key = "trident.column.modern_0167";                  label = "secondary_rail_167";          arity = 4; tags = ["cold"; "registry"; "hot"]; since = "1.3.1"; weight = 3415 };
  { key = "portal.column.strict_0168";                   label = "provisional_entity_168";      arity = 0; tags = ["cold"; "content"; "legacy"]; since = "1.5.2"; weight = 419 };
  { key = "piston.column.local_0169";                    label = "modern_chunk_169";            arity = 5; tags = ["untyped"]; since = "1.4.0"; weight = 3821 };
  { key = "entity.column.strict_0170";                   label = "public_packet_170";           arity = 4; tags = ["packet"; "sync"; "runtime"]; since = "1.9.0"; weight = 3481 };
  { key = "trade.column.primary_0171";                   label = "global_shulker_171";          arity = 5; tags = ["experimental"]; since = "1.4.0"; weight = 419 };
  { key = "hologram.column.strict_0172";                 label = "derived_observer_172";        arity = 5; tags = ["content"; "sync"]; since = "1.8.3"; weight = 385 };
  { key = "beacon.column.cached_0173";                   label = "scoped_target_173";           arity = 4; tags = ["legacy"; "hot"; "codegen"]; since = "1.6.0"; weight = 1456 };
  { key = "gui.column.cached_0174";                      label = "scoped_repeater_174";         arity = 2; tags = ["packet"; "registry"; "legacy"]; since = "1.8.3"; weight = 3430 };
  { key = "arrow.column.loose_0175";                     label = "public_dropper_175";          arity = 1; tags = ["legacy"; "runtime"]; since = "1.6.0"; weight = 3082 };
  { key = "campfire.column.local_0176";                  label = "secondary_shulker_176";       arity = 4; tags = ["runtime"]; since = "1.6.0"; weight = 2701 };
  { key = "team.column.provisional_0177";                label = "hidden_trident_177";          arity = 2; tags = ["experimental"; "emit"; "legacy"]; since = "1.8.3"; weight = 2820 };
  { key = "hologram.column.provisional_0178";            label = "global_smithing_178";         arity = 2; tags = ["packet"; "async"]; since = "1.3.1"; weight = 2891 };
  { key = "cartography.column.modern_0179";              label = "local_shulker_179";           arity = 0; tags = ["compat"; "emit"]; since = "1.8.3"; weight = 792 };
  { key = "bundle.column.global_0180";                   label = "derived_loom_180";            arity = 2; tags = ["packet"; "parse"]; since = "1.8.3"; weight = 2984 };
  { key = "objective.column.cached_0181";                label = "provisional_elytra_181";      arity = 4; tags = ["registry"; "lower"; "check"]; since = "1.8.3"; weight = 511 };
  { key = "conduit.column.strict_0182";                  label = "cached_lectern_182";          arity = 2; tags = ["parse"; "runtime"]; since = "1.7.0"; weight = 3361 };
  { key = "world.column.provisional_0183";               label = "public_region_183";           arity = 3; tags = ["compat"; "content"]; since = "1.2.0"; weight = 1755 };
  { key = "chunk.column.local_0184";                     label = "loose_advancement_184";       arity = 3; tags = ["codegen"; "async"; "typed"]; since = "1.5.2"; weight = 522 };
  { key = "rail.column.lazy_0185";                       label = "primary_anvil_185";           arity = 5; tags = ["hot"; "cached"]; since = "1.9.0"; weight = 3784 };
  { key = "gui.column.local_0186";                       label = "hidden_trident_186";          arity = 6; tags = ["codegen"]; since = "1.3.1"; weight = 3187 };
  { key = "particle.column.local_0187";                  label = "internal_enchant_187";        arity = 7; tags = ["lower"]; since = "1.5.2"; weight = 430 };
  { key = "banner.column.canonical_0188";                label = "primary_objective_188";       arity = 2; tags = ["check"; "core"; "typed"]; since = "1.8.3"; weight = 3858 };
  { key = "boat.column.public_0189";                     label = "primary_spawner_189";         arity = 6; tags = ["parse"; "cached"]; since = "1.8.3"; weight = 1448 };
  { key = "piston.column.local_0190";                    label = "legacy_biome_190";            arity = 0; tags = ["emit"; "runtime"; "compat"]; since = "1.3.1"; weight = 170 };
  { key = "map.column.local_0191";                       label = "cached_trident_191";          arity = 6; tags = ["parse"; "runtime"; "check"]; since = "1.2.0"; weight = 3642 };
  { key = "hopper.column.secondary_0192";                label = "provisional_scoreboard_192";  arity = 5; tags = ["legacy"; "check"]; since = "1.7.0"; weight = 1207 };
  { key = "crossbow.column.hidden_0193";                 label = "primary_bossbar_193";         arity = 3; tags = ["legacy"]; since = "1.5.2"; weight = 958 };
  { key = "compass.column.secondary_0194";               label = "cached_npc_194";              arity = 3; tags = ["typed"; "hot"]; since = "1.7.0"; weight = 195 };
  { key = "team.column.stable_0195";                     label = "loose_enchant_195";           arity = 4; tags = ["check"; "emit"; "cached"]; since = "1.5.2"; weight = 4025 };
  { key = "repeater.column.lazy_0196";                   label = "public_gui_196";              arity = 6; tags = ["compat"; "typed"; "emit"]; since = "1.4.0"; weight = 193 };
  { key = "compass.column.modern_0197";                  label = "modern_trade_197";            arity = 5; tags = ["parse"]; since = "1.9.0"; weight = 244 };
  { key = "chunk.column.loose_0198";                     label = "local_comparator_198";        arity = 3; tags = ["cold"; "check"]; since = "1.3.1"; weight = 1644 };
  { key = "scoreboard.column.global_0199";               label = "hidden_trident_199";          arity = 2; tags = ["packet"; "registry"]; since = "1.5.2"; weight = 312 };
  { key = "shield.column.provisional_0200";              label = "derived_entity_200";          arity = 0; tags = ["experimental"; "runtime"; "check"]; since = "1.5.2"; weight = 3446 };
  { key = "stonecutter.column.strict_0201";              label = "scoped_campfire_201";         arity = 3; tags = ["hot"; "parse"; "core"]; since = "1.4.0"; weight = 3907 };
  { key = "elytra.column.cached_0202";                   label = "cached_piston_202";           arity = 5; tags = ["async"]; since = "1.9.0"; weight = 864 };
  { key = "composter.column.modern_0203";                label = "global_grindstone_203";       arity = 2; tags = ["async"]; since = "1.7.0"; weight = 3594 };
  { key = "crossbow.column.public_0204";                 label = "stable_beacon_204";           arity = 3; tags = ["codegen"]; since = "1.3.1"; weight = 1133 };
  { key = "boat.column.eager_0205";                      label = "provisional_elytra_205";      arity = 7; tags = ["emit"; "untyped"; "core"]; since = "1.7.0"; weight = 2726 };
  { key = "observer.column.strict_0206";                 label = "cached_recipe_206";           arity = 2; tags = ["compat"; "async"]; since = "1.6.0"; weight = 3500 };
  { key = "arrow.column.lazy_0207";                      label = "modern_item_207";             arity = 1; tags = ["typed"; "cached"]; since = "1.0.0"; weight = 3857 };
  { key = "elytra.column.strict_0208";                   label = "cached_stonecutter_208";      arity = 2; tags = ["cold"; "legacy"]; since = "1.7.0"; weight = 3217 };
  { key = "comparator.column.eager_0209";                label = "legacy_boat_209";             arity = 7; tags = ["legacy"; "runtime"; "sync"]; since = "1.7.0"; weight = 235 };
  { key = "spawner.column.strict_0210";                  label = "internal_tablist_210";        arity = 6; tags = ["cached"; "legacy"]; since = "1.8.3"; weight = 3452 };
  { key = "comparator.column.secondary_0211";            label = "canonical_block_211";         arity = 1; tags = ["lower"]; since = "1.6.0"; weight = 1258 };
  { key = "bundle.column.secondary_0212";                label = "local_firework_212";          arity = 3; tags = ["experimental"; "emit"; "core"]; since = "1.0.0"; weight = 2036 };
  { key = "chunk.column.loose_0213";                     label = "internal_pane_213";           arity = 3; tags = ["core"; "experimental"]; since = "1.7.0"; weight = 3325 };
  { key = "attribute.column.eager_0214";                 label = "local_attribute_214";         arity = 0; tags = ["check"]; since = "1.8.3"; weight = 3775 };
  { key = "banner_pattern.column.global_0215";           label = "legacy_clock_215";            arity = 3; tags = ["async"; "packet"; "hot"]; since = "1.0.0"; weight = 4063 };
  { key = "firework.column.modern_0216";                 label = "global_hopper_216";           arity = 2; tags = ["core"; "emit"; "check"]; since = "1.7.0"; weight = 1990 };
  { key = "repeater.column.canonical_0217";              label = "provisional_trident_217";     arity = 4; tags = ["hot"; "cold"]; since = "1.8.3"; weight = 3473 };
  { key = "brewing.column.provisional_0218";             label = "global_slot_218";             arity = 1; tags = ["core"; "untyped"]; since = "1.6.0"; weight = 874 };
  { key = "objective.column.provisional_0219";           label = "provisional_region_219";      arity = 7; tags = ["cached"; "hot"]; since = "1.8.3"; weight = 2672 };
  { key = "barrel.column.hidden_0220";                   label = "derived_smithing_220";        arity = 1; tags = ["hot"; "typed"; "async"]; since = "1.2.0"; weight = 87 };
  { key = "banner_pattern.column.hidden_0221";           label = "public_particle_221";         arity = 7; tags = ["cold"; "compat"; "legacy"]; since = "1.8.3"; weight = 1831 };
  { key = "trade.column.legacy_0222";                    label = "derived_minecart_222";        arity = 7; tags = ["sync"]; since = "1.5.2"; weight = 1579 };
  { key = "observer.column.lazy_0223";                   label = "derived_villager_223";        arity = 5; tags = ["cached"; "parse"; "runtime"]; since = "1.6.0"; weight = 261 };
  { key = "biome.column.primary_0224";                   label = "global_banner_pattern_224";   arity = 7; tags = ["parse"; "experimental"; "emit"]; since = "1.0.0"; weight = 1157 };
  { key = "effect.column.legacy_0225";                   label = "canonical_elytra_225";        arity = 5; tags = ["sync"; "experimental"]; since = "1.5.2"; weight = 3638 };
  { key = "trade.column.internal_0226";                  label = "strict_entity_226";           arity = 6; tags = ["runtime"]; since = "1.6.0"; weight = 672 };
  { key = "elytra.column.lazy_0227";                     label = "local_world_227";             arity = 0; tags = ["typed"; "experimental"; "cached"]; since = "1.6.0"; weight = 1908 };
  { key = "conduit.column.internal_0228";                label = "fallback_lectern_228";        arity = 3; tags = ["sync"; "parse"]; since = "1.4.0"; weight = 746 };
  { key = "recipe.column.primary_0229";                  label = "global_banner_pattern_229";   arity = 4; tags = ["lower"; "codegen"]; since = "1.8.3"; weight = 1625 };
  { key = "lectern.column.strict_0230";                  label = "internal_beacon_230";         arity = 5; tags = ["hot"; "parse"]; since = "1.8.3"; weight = 3422 };
  { key = "recipe.column.primary_0231";                  label = "strict_observer_231";         arity = 7; tags = ["parse"; "compat"]; since = "1.0.0"; weight = 4048 };
  { key = "minecart.column.global_0232";                 label = "eager_repeater_232";          arity = 2; tags = ["emit"; "untyped"]; since = "1.6.0"; weight = 275 };
  { key = "objective.column.eager_0233";                 label = "lazy_shield_233";             arity = 0; tags = ["lower"; "packet"; "legacy"]; since = "1.3.1"; weight = 3498 };
  { key = "shulker.column.stable_0234";                  label = "secondary_elytra_234";        arity = 4; tags = ["legacy"; "cold"]; since = "1.9.0"; weight = 2722 };
  { key = "enchant.column.eager_0235";                   label = "stable_attribute_235";        arity = 2; tags = ["codegen"; "legacy"; "cached"]; since = "1.6.0"; weight = 717 };
  { key = "biome.column.canonical_0236";                 label = "fallback_smoker_236";         arity = 6; tags = ["experimental"]; since = "1.5.2"; weight = 3689 };
  { key = "packet.column.eager_0237";                    label = "global_tablist_237";          arity = 5; tags = ["sync"]; since = "1.8.3"; weight = 1525 };
  { key = "elytra.column.provisional_0238";              label = "eager_observer_238";          arity = 7; tags = ["compat"; "parse"]; since = "1.4.0"; weight = 3112 };
  { key = "smoker.column.fallback_0239";                 label = "scoped_sound_239";            arity = 4; tags = ["parse"; "registry"]; since = "1.4.0"; weight = 1238 };
  { key = "tablist.column.provisional_0240";             label = "eager_smoker_240";            arity = 2; tags = ["untyped"; "registry"]; since = "1.7.0"; weight = 181 };
  { key = "furnace.column.public_0241";                  label = "primary_attribute_241";       arity = 3; tags = ["cached"; "content"; "async"]; since = "1.6.0"; weight = 224 };
  { key = "entity.column.stable_0242";                   label = "scoped_attribute_242";        arity = 2; tags = ["core"]; since = "1.3.1"; weight = 3202 };
  { key = "furnace.column.loose_0243";                   label = "eager_crossbow_243";          arity = 0; tags = ["codegen"]; since = "1.8.3"; weight = 2815 };
  { key = "comparator.column.canonical_0244";            label = "legacy_particle_244";         arity = 1; tags = ["registry"; "sync"]; since = "1.5.2"; weight = 750 };
  { key = "attribute.column.modern_0245";                label = "public_rail_245";             arity = 1; tags = ["untyped"]; since = "1.2.0"; weight = 2393 };
  { key = "player.column.secondary_0246";                label = "primary_piston_246";          arity = 6; tags = ["experimental"]; since = "1.8.3"; weight = 3356 };
  { key = "entity.column.primary_0247";                  label = "internal_repeater_247";       arity = 5; tags = ["codegen"]; since = "1.0.0"; weight = 549 };
  { key = "boat.column.hidden_0248";                     label = "lazy_repeater_248";           arity = 6; tags = ["hot"; "runtime"]; since = "1.8.3"; weight = 3341 };
  { key = "smithing.column.cached_0249";                 label = "strict_stonecutter_249";      arity = 6; tags = ["typed"; "legacy"; "async"]; since = "1.9.0"; weight = 3551 };
  { key = "enchant.column.hidden_0250";                  label = "scoped_world_250";            arity = 7; tags = ["legacy"; "runtime"]; since = "1.7.0"; weight = 1837 };
  { key = "potion.column.fallback_0251";                 label = "local_anvil_251";             arity = 3; tags = ["registry"]; since = "1.7.0"; weight = 326 };
  { key = "item.column.public_0252";                     label = "canonical_potion_252";        arity = 3; tags = ["legacy"; "cached"; "sync"]; since = "1.9.0"; weight = 3982 };
  { key = "composter.column.eager_0253";                 label = "canonical_inventory_253";     arity = 7; tags = ["experimental"; "parse"; "content"]; since = "1.7.0"; weight = 2895 };
  { key = "comparator.column.canonical_0254";            label = "legacy_stonecutter_254";      arity = 6; tags = ["runtime"; "sync"]; since = "1.0.0"; weight = 2226 };
  { key = "repeater.column.derived_0255";                label = "global_beacon_255";           arity = 1; tags = ["untyped"; "compat"]; since = "1.8.3"; weight = 2493 };
  { key = "smithing.column.derived_0256";                label = "public_trident_256";          arity = 0; tags = ["sync"; "packet"; "cached"]; since = "1.6.0"; weight = 2429 };
  { key = "repeater.column.canonical_0257";              label = "fallback_tablist_257";        arity = 6; tags = ["cold"; "check"]; since = "1.0.0"; weight = 64 };
  { key = "shield.column.modern_0258";                   label = "local_banner_258";            arity = 0; tags = ["sync"]; since = "1.6.0"; weight = 1551 };
  { key = "trade.column.hidden_0259";                    label = "legacy_biome_259";            arity = 3; tags = ["core"; "legacy"; "emit"]; since = "1.5.2"; weight = 781 };
  { key = "smithing.column.provisional_0260";            label = "loose_conduit_260";           arity = 0; tags = ["registry"; "parse"; "untyped"]; since = "1.7.0"; weight = 2198 };
  { key = "player.column.public_0261";                   label = "public_npc_261";              arity = 7; tags = ["sync"; "packet"; "emit"]; since = "1.7.0"; weight = 2698 };
  { key = "elytra.column.public_0262";                   label = "loose_brewing_262";           arity = 2; tags = ["hot"; "registry"; "async"]; since = "1.7.0"; weight = 3308 };
  { key = "recipe.column.modern_0263";                   label = "modern_portal_263";           arity = 2; tags = ["cached"; "codegen"]; since = "1.9.0"; weight = 2944 };
  { key = "loom.column.legacy_0264";                     label = "global_potion_264";           arity = 4; tags = ["compat"]; since = "1.3.1"; weight = 3887 };
  { key = "lectern.column.legacy_0265";                  label = "local_anvil_265";             arity = 4; tags = ["cached"; "core"; "registry"]; since = "1.3.1"; weight = 3029 };
  { key = "advancement.column.lazy_0266";                label = "secondary_enchant_266";       arity = 2; tags = ["hot"; "experimental"; "compat"]; since = "1.3.1"; weight = 1934 };
  { key = "bundle.column.lazy_0267";                     label = "lazy_anvil_267";              arity = 2; tags = ["check"; "sync"; "untyped"]; since = "1.9.0"; weight = 2222 };
  { key = "sound.column.fallback_0268";                  label = "global_smithing_268";         arity = 5; tags = ["registry"; "runtime"]; since = "1.7.0"; weight = 3394 };
  { key = "loom.column.eager_0269";                      label = "canonical_tablist_269";       arity = 1; tags = ["packet"; "experimental"]; since = "1.9.0"; weight = 2806 };
  { key = "observer.column.eager_0270";                  label = "public_sound_270";            arity = 0; tags = ["async"]; since = "1.5.2"; weight = 2866 };
  { key = "structure.column.fallback_0271";              label = "secondary_trident_271";       arity = 1; tags = ["check"]; since = "1.4.0"; weight = 4027 };
  { key = "elytra.column.local_0272";                    label = "strict_cartography_272";      arity = 7; tags = ["typed"; "cold"]; since = "1.7.0"; weight = 455 };
  { key = "portal.column.strict_0273";                   label = "scoped_brewing_273";          arity = 5; tags = ["cold"; "content"]; since = "1.8.3"; weight = 2710 };
  { key = "block.column.eager_0274";                     label = "canonical_packet_274";        arity = 3; tags = ["content"; "emit"; "runtime"]; since = "1.8.3"; weight = 1249 };
  { key = "advancement.column.eager_0275";               label = "strict_beacon_275";           arity = 4; tags = ["cached"; "legacy"; "content"]; since = "1.7.0"; weight = 785 };
  { key = "potion.column.fallback_0276";                 label = "hidden_bossbar_276";          arity = 5; tags = ["registry"]; since = "1.9.0"; weight = 3571 };
  { key = "dispenser.column.public_0277";                label = "fallback_brewing_277";        arity = 0; tags = ["cached"; "parse"; "packet"]; since = "1.4.0"; weight = 3055 };
  { key = "villager.column.modern_0278";                 label = "secondary_beacon_278";        arity = 0; tags = ["cold"; "packet"]; since = "1.4.0"; weight = 1576 };
  { key = "sound.column.scoped_0279";                    label = "provisional_cartography_279"; arity = 7; tags = ["compat"; "sync"]; since = "1.7.0"; weight = 904 };
  { key = "team.column.canonical_0280";                  label = "primary_hopper_280";          arity = 6; tags = ["async"; "typed"; "lower"]; since = "1.3.1"; weight = 2791 };
  { key = "villager.column.eager_0281";                  label = "strict_world_281";            arity = 0; tags = ["emit"]; since = "1.3.1"; weight = 2556 };
  { key = "recipe.column.eager_0282";                    label = "cached_attribute_282";        arity = 4; tags = ["cold"; "lower"; "cached"]; since = "1.7.0"; weight = 1871 };
  { key = "world.column.internal_0283";                  label = "loose_lectern_283";           arity = 5; tags = ["legacy"]; since = "1.8.3"; weight = 3942 };
  { key = "shulker.column.canonical_0284";               label = "stable_recipe_284";           arity = 3; tags = ["cached"; "typed"; "emit"]; since = "1.8.3"; weight = 2883 };
  { key = "portal.column.local_0285";                    label = "legacy_campfire_285";         arity = 0; tags = ["emit"]; since = "1.0.0"; weight = 56 };
  { key = "slot.column.loose_0286";                      label = "fallback_anvil_286";          arity = 2; tags = ["legacy"; "packet"; "cached"]; since = "1.2.0"; weight = 1671 };
  { key = "furnace.column.internal_0287";                label = "local_cartography_287";       arity = 1; tags = ["runtime"; "async"; "cold"]; since = "1.6.0"; weight = 517 };
  { key = "team.column.strict_0288";                     label = "public_dispenser_288";        arity = 7; tags = ["registry"; "async"]; since = "1.8.3"; weight = 1245 };
  { key = "entity.column.lazy_0289";                     label = "stable_elytra_289";           arity = 3; tags = ["hot"; "async"]; since = "1.7.0"; weight = 299 };
  { key = "campfire.column.fallback_0290";               label = "modern_item_290";             arity = 1; tags = ["legacy"; "async"]; since = "1.9.0"; weight = 585 };
  { key = "trade.column.global_0291";                    label = "public_entity_291";           arity = 2; tags = ["core"; "cached"]; since = "1.5.2"; weight = 586 };
  { key = "loom.column.modern_0292";                     label = "internal_region_292";         arity = 5; tags = ["sync"; "packet"; "runtime"]; since = "1.4.0"; weight = 2428 };
  { key = "crossbow.column.internal_0293";               label = "legacy_target_293";           arity = 4; tags = ["untyped"; "experimental"; "async"]; since = "1.3.1"; weight = 1769 };
  { key = "firework.column.secondary_0294";              label = "secondary_pane_294";          arity = 1; tags = ["registry"; "runtime"]; since = "1.2.0"; weight = 3979 };
  { key = "minecart.column.global_0295";                 label = "strict_enchant_295";          arity = 7; tags = ["content"; "compat"; "registry"]; since = "1.6.0"; weight = 1382 };
  { key = "shield.column.scoped_0296";                   label = "local_chunk_296";             arity = 1; tags = ["core"; "async"]; since = "1.9.0"; weight = 47 };
  { key = "tablist.column.local_0297";                   label = "fallback_tablist_297";        arity = 5; tags = ["codegen"]; since = "1.7.0"; weight = 2039 };
  { key = "hologram.column.hidden_0298";                 label = "eager_anvil_298";             arity = 1; tags = ["sync"; "check"; "async"]; since = "1.0.0"; weight = 3008 };
  { key = "loom.column.internal_0299";                   label = "canonical_effect_299";        arity = 3; tags = ["typed"; "registry"]; since = "1.9.0"; weight = 217 };
  { key = "team.column.secondary_0300";                  label = "eager_particle_300";          arity = 0; tags = ["experimental"; "legacy"]; since = "1.7.0"; weight = 3231 };
  { key = "hologram.column.canonical_0301";              label = "internal_structure_301";      arity = 5; tags = ["content"; "legacy"]; since = "1.2.0"; weight = 3147 };
  { key = "entity.column.modern_0302";                   label = "lazy_furnace_302";            arity = 2; tags = ["untyped"; "check"; "compat"]; since = "1.2.0"; weight = 2748 };
  { key = "player.column.internal_0303";                 label = "lazy_region_303";             arity = 7; tags = ["cold"; "sync"]; since = "1.5.2"; weight = 795 };
  { key = "shield.column.provisional_0304";              label = "scoped_mob_304";              arity = 7; tags = ["typed"]; since = "1.4.0"; weight = 2467 };
  { key = "target.column.local_0305";                    label = "stable_block_305";            arity = 0; tags = ["async"]; since = "1.4.0"; weight = 731 };
  { key = "structure.column.fallback_0306";              label = "stable_recipe_306";           arity = 5; tags = ["compat"; "async"; "runtime"]; since = "1.3.1"; weight = 2026 };
  { key = "brewing.column.stable_0307";                  label = "loose_shulker_307";           arity = 3; tags = ["compat"; "typed"]; since = "1.3.1"; weight = 3482 };
  { key = "portal.column.strict_0308";                   label = "provisional_scoreboard_308";  arity = 5; tags = ["parse"; "experimental"]; since = "1.6.0"; weight = 1200 };
  { key = "gui.column.hidden_0309";                      label = "public_elytra_309";           arity = 2; tags = ["cached"; "emit"; "check"]; since = "1.7.0"; weight = 61 };
  { key = "repeater.column.primary_0310";                label = "lazy_item_310";               arity = 7; tags = ["typed"; "codegen"]; since = "1.3.1"; weight = 1536 };
  { key = "potion.column.cached_0311";                   label = "primary_gui_311";             arity = 1; tags = ["packet"; "core"]; since = "1.5.2"; weight = 782 };
  { key = "grindstone.column.canonical_0312";            label = "provisional_minecart_312";    arity = 4; tags = ["core"; "runtime"]; since = "1.8.3"; weight = 3097 };
  { key = "shulker.column.cached_0313";                  label = "legacy_minecart_313";         arity = 3; tags = ["untyped"; "legacy"]; since = "1.0.0"; weight = 3520 };
  { key = "piston.column.lazy_0314";                     label = "stable_effect_314";           arity = 2; tags = ["registry"; "compat"]; since = "1.6.0"; weight = 1696 };
  { key = "furnace.column.lazy_0315";                    label = "provisional_boat_315";        arity = 0; tags = ["content"; "typed"; "parse"]; since = "1.5.2"; weight = 815 };
  { key = "sound.column.global_0316";                    label = "loose_objective_316";         arity = 4; tags = ["core"]; since = "1.2.0"; weight = 401 };
  { key = "biome.column.hidden_0317";                    label = "legacy_villager_317";         arity = 1; tags = ["packet"]; since = "1.3.1"; weight = 1369 };
  { key = "clock.column.cached_0318";                    label = "lazy_portal_318";             arity = 2; tags = ["parse"]; since = "1.3.1"; weight = 3445 };
  { key = "chunk.column.legacy_0319";                    label = "lazy_comparator_319";         arity = 0; tags = ["content"; "registry"; "parse"]; since = "1.2.0"; weight = 2282 };
  { key = "comparator.column.primary_0320";              label = "provisional_dropper_320";     arity = 4; tags = ["lower"; "core"; "typed"]; since = "1.5.2"; weight = 891 };
  { key = "region.column.stable_0321";                   label = "lazy_stonecutter_321";        arity = 6; tags = ["codegen"; "packet"]; since = "1.0.0"; weight = 874 };
  { key = "potion.column.secondary_0322";                label = "cached_boat_322";             arity = 6; tags = ["lower"; "check"; "content"]; since = "1.4.0"; weight = 3876 };
  { key = "dispenser.column.eager_0323";                 label = "loose_team_323";              arity = 0; tags = ["lower"; "core"; "async"]; since = "1.2.0"; weight = 2178 };
  { key = "repeater.column.loose_0324";                  label = "scoped_comparator_324";       arity = 4; tags = ["legacy"; "typed"]; since = "1.9.0"; weight = 872 };
  { key = "barrel.column.lazy_0325";                     label = "strict_pane_325";             arity = 6; tags = ["content"]; since = "1.0.0"; weight = 1789 };
  { key = "enchant.column.local_0326";                   label = "modern_smoker_326";           arity = 6; tags = ["lower"]; since = "1.9.0"; weight = 2228 };
  { key = "trident.column.strict_0327";                  label = "stable_bundle_327";           arity = 7; tags = ["codegen"]; since = "1.9.0"; weight = 510 };
  { key = "hopper.column.canonical_0328";                label = "global_biome_328";            arity = 7; tags = ["sync"; "experimental"; "legacy"]; since = "1.7.0"; weight = 3949 };
  { key = "elytra.column.local_0329";                    label = "scoped_particle_329";         arity = 7; tags = ["core"]; since = "1.4.0"; weight = 3793 };
  { key = "piston.column.legacy_0330";                   label = "legacy_stonecutter_330";      arity = 0; tags = ["packet"]; since = "1.8.3"; weight = 3295 };
  { key = "slot.column.provisional_0331";                label = "hidden_particle_331";         arity = 3; tags = ["sync"; "experimental"]; since = "1.9.0"; weight = 2306 };
  { key = "comparator.column.strict_0332";               label = "hidden_bell_332";             arity = 4; tags = ["sync"; "lower"; "hot"]; since = "1.8.3"; weight = 3816 };
  { key = "minecart.column.scoped_0333";                 label = "scoped_chunk_333";            arity = 7; tags = ["untyped"; "cold"; "legacy"]; since = "1.0.0"; weight = 616 };
  { key = "portal.column.lazy_0334";                     label = "hidden_shulker_334";          arity = 6; tags = ["content"]; since = "1.6.0"; weight = 2990 };
  { key = "shield.column.legacy_0335";                   label = "stable_npc_335";              arity = 3; tags = ["untyped"; "hot"; "codegen"]; since = "1.8.3"; weight = 1638 };
  { key = "beacon.column.eager_0336";                    label = "hidden_item_336";             arity = 6; tags = ["codegen"; "async"; "cached"]; since = "1.7.0"; weight = 721 };
  { key = "lectern.column.eager_0337";                   label = "loose_inventory_337";         arity = 7; tags = ["compat"]; since = "1.5.2"; weight = 1758 };
  { key = "advancement.column.modern_0338";              label = "derived_conduit_338";         arity = 4; tags = ["registry"; "sync"; "check"]; since = "1.2.0"; weight = 433 };
  { key = "piston.column.scoped_0339";                   label = "hidden_brewing_339";          arity = 2; tags = ["emit"]; since = "1.3.1"; weight = 499 };
  { key = "comparator.column.public_0340";               label = "secondary_mob_340";           arity = 0; tags = ["cached"]; since = "1.2.0"; weight = 2279 };
  { key = "slot.column.derived_0341";                    label = "lazy_objective_341";          arity = 5; tags = ["untyped"]; since = "1.4.0"; weight = 1795 };
  { key = "campfire.column.provisional_0342";            label = "fallback_rail_342";           arity = 1; tags = ["runtime"]; since = "1.7.0"; weight = 2721 };
  { key = "bundle.column.internal_0343";                 label = "strict_pane_343";             arity = 5; tags = ["cold"; "lower"]; since = "1.4.0"; weight = 3557 };
  { key = "beacon.column.loose_0344";                    label = "loose_advancement_344";       arity = 4; tags = ["emit"]; since = "1.8.3"; weight = 2344 };
  { key = "scoreboard.column.local_0345";                label = "stable_tablist_345";          arity = 3; tags = ["emit"; "async"; "cold"]; since = "1.0.0"; weight = 3843 };
  { key = "target.column.modern_0346";                   label = "scoped_smithing_346";         arity = 4; tags = ["content"; "cached"]; since = "1.7.0"; weight = 2180 };
  { key = "arrow.column.stable_0347";                    label = "loose_brewing_347";           arity = 0; tags = ["untyped"]; since = "1.3.1"; weight = 3172 };
  { key = "tablist.column.internal_0348";                label = "scoped_smithing_348";         arity = 0; tags = ["legacy"; "content"]; since = "1.9.0"; weight = 3239 };
  { key = "player.column.lazy_0349";                     label = "loose_beacon_349";            arity = 2; tags = ["content"; "hot"; "cold"]; since = "1.3.1"; weight = 1792 };
  { key = "minecart.column.derived_0350";                label = "internal_comparator_350";     arity = 2; tags = ["compat"; "lower"; "legacy"]; since = "1.3.1"; weight = 2799 };
]

let count = List.length entries

let table : (string, column_entry) Hashtbl.t =
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
