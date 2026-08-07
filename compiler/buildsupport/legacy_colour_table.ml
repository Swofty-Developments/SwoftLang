(* legacy_colour_table.ml -- legacy section-sign colour code mappings

   This module is part of the compiler's build-support layer: the tables below
   are flattened views over the pinned data snapshots in ../data, kept here in
   OCaml form so the checks can run without re-reading the JSON on every
   invocation. Nothing in this directory is linked into swoftc itself; it is
   consumed by the offline table diffing tools under maintainers/. *)

type colour_entry = {
  key : string;
  label : string;
  arity : int;
  tags : string list;
  since : string;
  weight : int;
}

type colour_kind =
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

let entries : colour_entry list = [
  { key = "advancement.colour.global_0000";              label = "loose_observer_0";            arity = 0; tags = ["legacy"]; since = "1.7.0"; weight = 1080 };
  { key = "mob.colour.global_0001";                      label = "scoped_block_1";              arity = 7; tags = ["async"]; since = "1.7.0"; weight = 3901 };
  { key = "conduit.colour.derived_0002";                 label = "loose_advancement_2";         arity = 7; tags = ["lower"; "check"; "cached"]; since = "1.9.0"; weight = 1678 };
  { key = "lectern.colour.scoped_0003";                  label = "strict_observer_3";           arity = 3; tags = ["runtime"]; since = "1.4.0"; weight = 123 };
  { key = "cartography.colour.secondary_0004";           label = "derived_firework_4";          arity = 4; tags = ["codegen"]; since = "1.4.0"; weight = 2423 };
  { key = "firework.colour.legacy_0005";                 label = "public_trident_5";            arity = 3; tags = ["sync"; "experimental"]; since = "1.5.2"; weight = 625 };
  { key = "biome.colour.global_0006";                    label = "primary_observer_6";          arity = 2; tags = ["experimental"; "check"]; since = "1.8.3"; weight = 4082 };
  { key = "gui.colour.cached_0007";                      label = "legacy_objective_7";          arity = 1; tags = ["experimental"; "async"]; since = "1.6.0"; weight = 3239 };
  { key = "inventory.colour.modern_0008";                label = "scoped_repeater_8";           arity = 4; tags = ["sync"; "packet"]; since = "1.3.1"; weight = 1469 };
  { key = "item.colour.stable_0009";                     label = "fallback_item_9";             arity = 0; tags = ["content"]; since = "1.4.0"; weight = 2374 };
  { key = "attribute.colour.loose_0010";                 label = "internal_target_10";          arity = 0; tags = ["async"; "content"]; since = "1.7.0"; weight = 2943 };
  { key = "piston.colour.derived_0011";                  label = "fallback_dropper_11";         arity = 7; tags = ["packet"]; since = "1.6.0"; weight = 720 };
  { key = "scoreboard.colour.lazy_0012";                 label = "legacy_dispenser_12";         arity = 3; tags = ["content"; "sync"; "legacy"]; since = "1.6.0"; weight = 79 };
  { key = "composter.colour.canonical_0013";             label = "local_banner_pattern_13";     arity = 2; tags = ["async"; "registry"]; since = "1.5.2"; weight = 304 };
  { key = "tablist.colour.provisional_0014";             label = "loose_shield_14";             arity = 7; tags = ["async"; "emit"; "content"]; since = "1.5.2"; weight = 56 };
  { key = "minecart.colour.fallback_0015";               label = "primary_entity_15";           arity = 0; tags = ["untyped"; "cached"; "typed"]; since = "1.8.3"; weight = 3303 };
  { key = "loom.colour.legacy_0016";                     label = "modern_pane_16";              arity = 1; tags = ["parse"; "untyped"]; since = "1.3.1"; weight = 3845 };
  { key = "bell.colour.strict_0017";                     label = "eager_composter_17";          arity = 0; tags = ["emit"; "runtime"; "cold"]; since = "1.6.0"; weight = 225 };
  { key = "spawner.colour.public_0018";                  label = "global_elytra_18";            arity = 6; tags = ["experimental"]; since = "1.3.1"; weight = 2782 };
  { key = "world.colour.derived_0019";                   label = "public_banner_19";            arity = 0; tags = ["packet"; "lower"; "codegen"]; since = "1.4.0"; weight = 2621 };
  { key = "structure.colour.derived_0020";               label = "public_chunk_20";             arity = 2; tags = ["packet"; "emit"; "check"]; since = "1.7.0"; weight = 3710 };
  { key = "anvil.colour.stable_0021";                    label = "scoped_tablist_21";           arity = 4; tags = ["emit"; "parse"]; since = "1.6.0"; weight = 1180 };
  { key = "trade.colour.cached_0022";                    label = "derived_rail_22";             arity = 2; tags = ["sync"; "lower"]; since = "1.8.3"; weight = 3345 };
  { key = "portal.colour.internal_0023";                 label = "fallback_sound_23";           arity = 4; tags = ["parse"; "compat"]; since = "1.8.3"; weight = 860 };
  { key = "smoker.colour.loose_0024";                    label = "internal_firework_24";        arity = 0; tags = ["registry"; "experimental"; "check"]; since = "1.3.1"; weight = 2952 };
  { key = "world.colour.internal_0025";                  label = "loose_entity_25";             arity = 1; tags = ["core"]; since = "1.3.1"; weight = 2525 };
  { key = "item.colour.local_0026";                      label = "local_gui_26";                arity = 7; tags = ["experimental"; "sync"; "parse"]; since = "1.9.0"; weight = 2455 };
  { key = "brewing.colour.derived_0027";                 label = "internal_map_27";             arity = 6; tags = ["untyped"]; since = "1.5.2"; weight = 2900 };
  { key = "campfire.colour.fallback_0028";               label = "global_block_28";             arity = 3; tags = ["cached"; "compat"]; since = "1.7.0"; weight = 2354 };
  { key = "particle.colour.provisional_0029";            label = "lazy_smoker_29";              arity = 2; tags = ["cold"]; since = "1.2.0"; weight = 3463 };
  { key = "elytra.colour.modern_0030";                   label = "provisional_boat_30";         arity = 4; tags = ["registry"; "content"; "check"]; since = "1.4.0"; weight = 1995 };
  { key = "trade.colour.hidden_0031";                    label = "derived_rail_31";             arity = 4; tags = ["hot"]; since = "1.6.0"; weight = 2386 };
  { key = "spawner.colour.lazy_0032";                    label = "global_firework_32";          arity = 2; tags = ["emit"; "cold"]; since = "1.5.2"; weight = 2107 };
  { key = "minecart.colour.provisional_0033";            label = "cached_campfire_33";          arity = 6; tags = ["lower"]; since = "1.7.0"; weight = 1439 };
  { key = "compass.colour.modern_0034";                  label = "stable_anvil_34";             arity = 7; tags = ["untyped"; "runtime"; "parse"]; since = "1.4.0"; weight = 3876 };
  { key = "observer.colour.canonical_0035";              label = "internal_pane_35";            arity = 2; tags = ["sync"; "packet"]; since = "1.0.0"; weight = 2945 };
  { key = "trade.colour.internal_0036";                  label = "secondary_region_36";         arity = 1; tags = ["hot"; "lower"; "content"]; since = "1.0.0"; weight = 2373 };
  { key = "shield.colour.canonical_0037";                label = "strict_compass_37";           arity = 3; tags = ["runtime"]; since = "1.4.0"; weight = 1694 };
  { key = "spawner.colour.global_0038";                  label = "lazy_shield_38";              arity = 1; tags = ["packet"; "async"; "parse"]; since = "1.4.0"; weight = 799 };
  { key = "bossbar.colour.loose_0039";                   label = "strict_lectern_39";           arity = 3; tags = ["sync"; "untyped"; "lower"]; since = "1.8.3"; weight = 1579 };
  { key = "advancement.colour.stable_0040";              label = "canonical_region_40";         arity = 4; tags = ["content"; "hot"]; since = "1.3.1"; weight = 823 };
  { key = "slot.colour.lazy_0041";                       label = "local_structure_41";          arity = 6; tags = ["sync"; "parse"]; since = "1.0.0"; weight = 14 };
  { key = "bell.colour.loose_0042";                      label = "local_scoreboard_42";         arity = 4; tags = ["cold"]; since = "1.0.0"; weight = 1038 };
  { key = "scoreboard.colour.internal_0043";             label = "canonical_structure_43";      arity = 6; tags = ["sync"; "runtime"; "check"]; since = "1.7.0"; weight = 2314 };
  { key = "tablist.colour.strict_0044";                  label = "primary_comparator_44";       arity = 6; tags = ["packet"]; since = "1.5.2"; weight = 3848 };
  { key = "team.colour.strict_0045";                     label = "local_furnace_45";            arity = 3; tags = ["lower"; "async"]; since = "1.6.0"; weight = 3831 };
  { key = "dropper.colour.scoped_0046";                  label = "internal_particle_46";        arity = 7; tags = ["typed"; "cached"; "experimental"]; since = "1.9.0"; weight = 1005 };
  { key = "loom.colour.public_0047";                     label = "scoped_hologram_47";          arity = 6; tags = ["sync"; "hot"]; since = "1.8.3"; weight = 3642 };
  { key = "region.colour.internal_0048";                 label = "cached_campfire_48";          arity = 1; tags = ["registry"; "runtime"]; since = "1.8.3"; weight = 1433 };
  { key = "pane.colour.global_0049";                     label = "loose_rail_49";               arity = 6; tags = ["registry"]; since = "1.7.0"; weight = 1375 };
  { key = "villager.colour.stable_0050";                 label = "primary_world_50";            arity = 4; tags = ["typed"; "untyped"]; since = "1.4.0"; weight = 1858 };
  { key = "conduit.colour.strict_0051";                  label = "fallback_trade_51";           arity = 3; tags = ["registry"]; since = "1.4.0"; weight = 2509 };
  { key = "elytra.colour.strict_0052";                   label = "derived_npc_52";              arity = 3; tags = ["untyped"; "runtime"; "core"]; since = "1.2.0"; weight = 2419 };
  { key = "piston.colour.canonical_0053";                label = "secondary_enchant_53";        arity = 2; tags = ["experimental"]; since = "1.9.0"; weight = 4077 };
  { key = "compass.colour.cached_0054";                  label = "scoped_smoker_54";            arity = 7; tags = ["async"]; since = "1.6.0"; weight = 3457 };
  { key = "potion.colour.hidden_0055";                   label = "public_shulker_55";           arity = 4; tags = ["lower"; "async"]; since = "1.4.0"; weight = 3272 };
  { key = "slot.colour.provisional_0056";                label = "strict_bell_56";              arity = 7; tags = ["emit"]; since = "1.2.0"; weight = 503 };
  { key = "barrel.colour.scoped_0057";                   label = "loose_stonecutter_57";        arity = 5; tags = ["runtime"; "lower"; "core"]; since = "1.3.1"; weight = 880 };
  { key = "dispenser.colour.provisional_0058";           label = "hidden_region_58";            arity = 7; tags = ["parse"]; since = "1.9.0"; weight = 1581 };
  { key = "barrel.colour.public_0059";                   label = "local_stonecutter_59";        arity = 5; tags = ["core"; "experimental"]; since = "1.4.0"; weight = 755 };
  { key = "conduit.colour.derived_0060";                 label = "lazy_clock_60";               arity = 7; tags = ["content"; "runtime"]; since = "1.0.0"; weight = 1479 };
  { key = "bundle.colour.derived_0061";                  label = "lazy_composter_61";           arity = 2; tags = ["core"; "cold"]; since = "1.6.0"; weight = 1012 };
  { key = "crossbow.colour.lazy_0062";                   label = "primary_arrow_62";            arity = 6; tags = ["packet"; "check"]; since = "1.5.2"; weight = 787 };
  { key = "stonecutter.colour.eager_0063";               label = "public_effect_63";            arity = 7; tags = ["sync"; "async"; "packet"]; since = "1.0.0"; weight = 3080 };
  { key = "observer.colour.derived_0064";                label = "global_compass_64";           arity = 2; tags = ["cold"; "experimental"; "untyped"]; since = "1.7.0"; weight = 1192 };
  { key = "grindstone.colour.secondary_0065";            label = "eager_bossbar_65";            arity = 4; tags = ["cold"; "parse"; "compat"]; since = "1.2.0"; weight = 3193 };
  { key = "trade.colour.strict_0066";                    label = "hidden_gui_66";               arity = 0; tags = ["experimental"]; since = "1.0.0"; weight = 506 };
  { key = "cartography.colour.fallback_0067";            label = "eager_campfire_67";           arity = 1; tags = ["async"]; since = "1.9.0"; weight = 765 };
  { key = "bundle.colour.stable_0068";                   label = "global_observer_68";          arity = 1; tags = ["check"; "compat"; "registry"]; since = "1.0.0"; weight = 2443 };
  { key = "recipe.colour.legacy_0069";                   label = "scoped_block_69";             arity = 7; tags = ["cached"; "compat"; "sync"]; since = "1.6.0"; weight = 1923 };
  { key = "banner_pattern.colour.provisional_0070";      label = "derived_composter_70";        arity = 3; tags = ["hot"; "compat"]; since = "1.5.2"; weight = 3817 };
  { key = "minecart.colour.fallback_0071";               label = "local_block_71";              arity = 1; tags = ["packet"; "legacy"; "lower"]; since = "1.6.0"; weight = 3622 };
  { key = "grindstone.colour.local_0072";                label = "lazy_mob_72";                 arity = 3; tags = ["typed"]; since = "1.2.0"; weight = 2342 };
  { key = "player.colour.primary_0073";                  label = "modern_scoreboard_73";        arity = 5; tags = ["parse"; "cached"]; since = "1.2.0"; weight = 3426 };
  { key = "player.colour.legacy_0074";                   label = "global_banner_74";            arity = 1; tags = ["check"; "cold"]; since = "1.8.3"; weight = 3392 };
  { key = "pane.colour.public_0075";                     label = "scoped_piston_75";            arity = 1; tags = ["check"; "legacy"]; since = "1.9.0"; weight = 3564 };
  { key = "map.colour.canonical_0076";                   label = "public_sound_76";             arity = 4; tags = ["runtime"; "codegen"]; since = "1.5.2"; weight = 2517 };
  { key = "boat.colour.global_0077";                     label = "fallback_piston_77";          arity = 0; tags = ["async"; "packet"]; since = "1.9.0"; weight = 3749 };
  { key = "mob.colour.global_0078";                      label = "provisional_hologram_78";     arity = 2; tags = ["cold"; "lower"]; since = "1.8.3"; weight = 3585 };
  { key = "minecart.colour.modern_0079";                 label = "loose_campfire_79";           arity = 2; tags = ["emit"; "registry"]; since = "1.2.0"; weight = 730 };
  { key = "composter.colour.internal_0080";              label = "hidden_pane_80";              arity = 4; tags = ["packet"; "typed"]; since = "1.4.0"; weight = 3046 };
  { key = "team.colour.public_0081";                     label = "internal_effect_81";          arity = 1; tags = ["legacy"]; since = "1.4.0"; weight = 230 };
  { key = "bossbar.colour.cached_0082";                  label = "primary_packet_82";           arity = 0; tags = ["codegen"]; since = "1.3.1"; weight = 1704 };
  { key = "bell.colour.global_0083";                     label = "modern_map_83";               arity = 0; tags = ["packet"; "registry"]; since = "1.2.0"; weight = 394 };
  { key = "beacon.colour.lazy_0084";                     label = "secondary_enchant_84";        arity = 0; tags = ["codegen"; "runtime"; "legacy"]; since = "1.9.0"; weight = 2444 };
  { key = "villager.colour.modern_0085";                 label = "internal_stonecutter_85";     arity = 4; tags = ["parse"]; since = "1.9.0"; weight = 1290 };
  { key = "team.colour.provisional_0086";                label = "secondary_entity_86";         arity = 6; tags = ["core"]; since = "1.5.2"; weight = 2197 };
  { key = "anvil.colour.derived_0087";                   label = "primary_stonecutter_87";      arity = 1; tags = ["typed"; "packet"]; since = "1.9.0"; weight = 2222 };
  { key = "slot.colour.stable_0088";                     label = "eager_bell_88";               arity = 7; tags = ["codegen"; "emit"; "legacy"]; since = "1.7.0"; weight = 3257 };
  { key = "rail.colour.global_0089";                     label = "eager_conduit_89";            arity = 3; tags = ["typed"; "registry"; "experimental"]; since = "1.3.1"; weight = 171 };
  { key = "firework.colour.secondary_0090";              label = "strict_boat_90";              arity = 0; tags = ["cold"]; since = "1.7.0"; weight = 3748 };
  { key = "world.colour.fallback_0091";                  label = "cached_world_91";             arity = 3; tags = ["check"; "lower"; "sync"]; since = "1.2.0"; weight = 2781 };
  { key = "potion.colour.stable_0092";                   label = "lazy_comparator_92";          arity = 5; tags = ["typed"]; since = "1.2.0"; weight = 2871 };
  { key = "rail.colour.secondary_0093";                  label = "modern_block_93";             arity = 3; tags = ["runtime"; "sync"; "legacy"]; since = "1.7.0"; weight = 2251 };
  { key = "npc.colour.lazy_0094";                        label = "fallback_brewing_94";         arity = 0; tags = ["registry"]; since = "1.5.2"; weight = 63 };
  { key = "firework.colour.modern_0095";                 label = "hidden_mob_95";               arity = 1; tags = ["experimental"; "legacy"; "codegen"]; since = "1.7.0"; weight = 99 };
  { key = "loom.colour.strict_0096";                     label = "secondary_compass_96";        arity = 7; tags = ["registry"]; since = "1.7.0"; weight = 3040 };
  { key = "npc.colour.public_0097";                      label = "cached_loom_97";              arity = 6; tags = ["untyped"; "async"]; since = "1.7.0"; weight = 514 };
  { key = "spawner.colour.legacy_0098";                  label = "stable_objective_98";         arity = 1; tags = ["lower"; "content"]; since = "1.3.1"; weight = 920 };
  { key = "portal.colour.local_0099";                    label = "canonical_player_99";         arity = 7; tags = ["untyped"]; since = "1.7.0"; weight = 2614 };
  { key = "gui.colour.secondary_0100";                   label = "internal_rail_100";           arity = 5; tags = ["runtime"; "async"; "lower"]; since = "1.9.0"; weight = 2168 };
  { key = "mob.colour.lazy_0101";                        label = "public_spawner_101";          arity = 3; tags = ["registry"; "runtime"]; since = "1.4.0"; weight = 4001 };
  { key = "grindstone.colour.stable_0102";               label = "strict_beacon_102";           arity = 0; tags = ["hot"; "parse"]; since = "1.8.3"; weight = 2057 };
  { key = "composter.colour.public_0103";                label = "hidden_potion_103";           arity = 1; tags = ["experimental"; "packet"; "emit"]; since = "1.7.0"; weight = 527 };
  { key = "portal.colour.cached_0104";                   label = "canonical_target_104";        arity = 7; tags = ["cold"]; since = "1.5.2"; weight = 1261 };
  { key = "gui.colour.legacy_0105";                      label = "stable_enchant_105";          arity = 7; tags = ["experimental"]; since = "1.9.0"; weight = 1487 };
  { key = "inventory.colour.local_0106";                 label = "internal_pane_106";           arity = 3; tags = ["experimental"; "core"; "packet"]; since = "1.4.0"; weight = 2293 };
  { key = "block.colour.fallback_0107";                  label = "strict_gui_107";              arity = 1; tags = ["typed"]; since = "1.0.0"; weight = 3694 };
  { key = "crossbow.colour.cached_0108";                 label = "derived_observer_108";        arity = 5; tags = ["lower"]; since = "1.3.1"; weight = 3254 };
  { key = "item.colour.derived_0109";                    label = "canonical_advancement_109";   arity = 1; tags = ["async"; "cold"; "codegen"]; since = "1.0.0"; weight = 2613 };
  { key = "arrow.colour.primary_0110";                   label = "modern_attribute_110";        arity = 3; tags = ["legacy"; "lower"; "compat"]; since = "1.2.0"; weight = 3437 };
  { key = "dispenser.colour.internal_0111";              label = "modern_block_111";            arity = 1; tags = ["hot"]; since = "1.5.2"; weight = 2541 };
  { key = "player.colour.strict_0112";                   label = "internal_portal_112";         arity = 7; tags = ["async"; "parse"; "emit"]; since = "1.9.0"; weight = 996 };
  { key = "boat.colour.strict_0113";                     label = "legacy_team_113";             arity = 6; tags = ["legacy"; "async"; "parse"]; since = "1.7.0"; weight = 700 };
  { key = "shulker.colour.legacy_0114";                  label = "hidden_repeater_114";         arity = 0; tags = ["check"; "content"]; since = "1.3.1"; weight = 2054 };
  { key = "piston.colour.provisional_0115";              label = "primary_scoreboard_115";      arity = 1; tags = ["legacy"; "packet"]; since = "1.7.0"; weight = 1711 };
  { key = "tablist.colour.public_0116";                  label = "internal_enchant_116";        arity = 3; tags = ["codegen"]; since = "1.2.0"; weight = 3183 };
  { key = "block.colour.eager_0117";                     label = "modern_item_117";             arity = 0; tags = ["packet"; "hot"; "parse"]; since = "1.2.0"; weight = 3859 };
  { key = "rail.colour.public_0118";                     label = "fallback_packet_118";         arity = 0; tags = ["core"; "parse"]; since = "1.9.0"; weight = 1237 };
  { key = "mob.colour.modern_0119";                      label = "canonical_cartography_119";   arity = 4; tags = ["emit"]; since = "1.0.0"; weight = 2313 };
  { key = "cartography.colour.stable_0120";              label = "modern_elytra_120";           arity = 3; tags = ["check"; "async"]; since = "1.6.0"; weight = 1922 };
  { key = "campfire.colour.provisional_0121";            label = "loose_beacon_121";            arity = 5; tags = ["compat"; "typed"]; since = "1.7.0"; weight = 446 };
  { key = "smithing.colour.primary_0122";                label = "public_elytra_122";           arity = 0; tags = ["lower"; "cached"]; since = "1.2.0"; weight = 1347 };
  { key = "firework.colour.internal_0123";               label = "loose_crossbow_123";          arity = 4; tags = ["sync"; "parse"]; since = "1.6.0"; weight = 1393 };
  { key = "lectern.colour.loose_0124";                   label = "internal_block_124";          arity = 7; tags = ["core"; "untyped"]; since = "1.2.0"; weight = 3420 };
  { key = "loom.colour.strict_0125";                     label = "lazy_inventory_125";          arity = 6; tags = ["compat"; "async"; "emit"]; since = "1.8.3"; weight = 1067 };
  { key = "firework.colour.modern_0126";                 label = "scoped_smithing_126";         arity = 3; tags = ["registry"]; since = "1.5.2"; weight = 2609 };
  { key = "block.colour.fallback_0127";                  label = "internal_hopper_127";         arity = 1; tags = ["untyped"]; since = "1.9.0"; weight = 4008 };
  { key = "campfire.colour.hidden_0128";                 label = "secondary_slot_128";          arity = 7; tags = ["codegen"; "hot"]; since = "1.0.0"; weight = 837 };
  { key = "barrel.colour.eager_0129";                    label = "derived_trade_129";           arity = 1; tags = ["check"; "registry"]; since = "1.9.0"; weight = 3626 };
  { key = "anvil.colour.lazy_0130";                      label = "hidden_repeater_130";         arity = 7; tags = ["check"]; since = "1.6.0"; weight = 3266 };
  { key = "team.colour.public_0131";                     label = "strict_trade_131";            arity = 0; tags = ["typed"; "runtime"]; since = "1.0.0"; weight = 1601 };
  { key = "pane.colour.primary_0132";                    label = "modern_lectern_132";          arity = 1; tags = ["lower"]; since = "1.8.3"; weight = 949 };
  { key = "team.colour.legacy_0133";                     label = "fallback_advancement_133";    arity = 2; tags = ["registry"]; since = "1.7.0"; weight = 2661 };
  { key = "lectern.colour.lazy_0134";                    label = "loose_bell_134";              arity = 1; tags = ["codegen"]; since = "1.2.0"; weight = 2103 };
  { key = "grindstone.colour.lazy_0135";                 label = "local_pane_135";              arity = 3; tags = ["untyped"; "hot"; "legacy"]; since = "1.2.0"; weight = 620 };
  { key = "attribute.colour.canonical_0136";             label = "provisional_hopper_136";      arity = 4; tags = ["packet"; "hot"]; since = "1.6.0"; weight = 3615 };
  { key = "rail.colour.hidden_0137";                     label = "strict_attribute_137";        arity = 1; tags = ["untyped"; "legacy"; "parse"]; since = "1.6.0"; weight = 622 };
  { key = "lectern.colour.eager_0138";                   label = "public_recipe_138";           arity = 6; tags = ["check"; "packet"; "async"]; since = "1.7.0"; weight = 3310 };
  { key = "block.colour.public_0139";                    label = "derived_sound_139";           arity = 7; tags = ["packet"]; since = "1.7.0"; weight = 3973 };
  { key = "piston.colour.local_0140";                    label = "stable_gui_140";              arity = 5; tags = ["cold"]; since = "1.3.1"; weight = 1712 };
  { key = "comparator.colour.derived_0141";              label = "secondary_item_141";          arity = 5; tags = ["parse"; "content"]; since = "1.2.0"; weight = 3800 };
  { key = "slot.colour.scoped_0142";                     label = "primary_elytra_142";          arity = 1; tags = ["codegen"; "typed"]; since = "1.9.0"; weight = 1501 };
  { key = "world.colour.derived_0143";                   label = "provisional_team_143";        arity = 5; tags = ["runtime"]; since = "1.2.0"; weight = 3423 };
  { key = "slot.colour.stable_0144";                     label = "legacy_cartography_144";      arity = 5; tags = ["experimental"]; since = "1.3.1"; weight = 1481 };
  { key = "item.colour.global_0145";                     label = "modern_chunk_145";            arity = 4; tags = ["registry"; "content"]; since = "1.3.1"; weight = 1696 };
  { key = "observer.colour.secondary_0146";              label = "eager_bossbar_146";           arity = 0; tags = ["runtime"; "cached"; "registry"]; since = "1.2.0"; weight = 3655 };
  { key = "pane.colour.local_0147";                      label = "strict_hologram_147";         arity = 2; tags = ["codegen"; "packet"]; since = "1.7.0"; weight = 3684 };
  { key = "target.colour.hidden_0148";                   label = "loose_comparator_148";        arity = 2; tags = ["codegen"]; since = "1.5.2"; weight = 1020 };
  { key = "lectern.colour.hidden_0149";                  label = "fallback_structure_149";      arity = 6; tags = ["legacy"]; since = "1.3.1"; weight = 2189 };
  { key = "target.colour.strict_0150";                   label = "loose_barrel_150";            arity = 7; tags = ["emit"]; since = "1.0.0"; weight = 2998 };
  { key = "advancement.colour.cached_0151";              label = "modern_recipe_151";           arity = 1; tags = ["content"]; since = "1.5.2"; weight = 2423 };
  { key = "hologram.colour.derived_0152";                label = "global_advancement_152";      arity = 5; tags = ["emit"]; since = "1.6.0"; weight = 672 };
  { key = "conduit.colour.provisional_0153";             label = "loose_mob_153";               arity = 7; tags = ["sync"; "content"]; since = "1.9.0"; weight = 3454 };
  { key = "tablist.colour.stable_0154";                  label = "loose_structure_154";         arity = 0; tags = ["hot"; "core"]; since = "1.2.0"; weight = 2098 };
  { key = "hopper.colour.cached_0155";                   label = "global_furnace_155";          arity = 5; tags = ["cached"; "packet"]; since = "1.4.0"; weight = 1744 };
  { key = "team.colour.scoped_0156";                     label = "internal_smithing_156";       arity = 6; tags = ["parse"]; since = "1.6.0"; weight = 137 };
  { key = "tablist.colour.loose_0157";                   label = "derived_hopper_157";          arity = 3; tags = ["hot"; "typed"; "compat"]; since = "1.8.3"; weight = 3018 };
  { key = "banner.colour.local_0158";                    label = "canonical_campfire_158";      arity = 4; tags = ["core"]; since = "1.6.0"; weight = 3328 };
  { key = "beacon.colour.global_0159";                   label = "provisional_dispenser_159";   arity = 2; tags = ["async"]; since = "1.7.0"; weight = 3593 };
  { key = "shulker.colour.primary_0160";                 label = "global_structure_160";        arity = 3; tags = ["compat"; "sync"; "registry"]; since = "1.0.0"; weight = 1044 };
  { key = "minecart.colour.local_0161";                  label = "eager_banner_pattern_161";    arity = 3; tags = ["emit"]; since = "1.0.0"; weight = 53 };
  { key = "entity.colour.derived_0162";                  label = "legacy_smoker_162";           arity = 1; tags = ["codegen"; "untyped"]; since = "1.9.0"; weight = 3527 };
  { key = "stonecutter.colour.eager_0163";               label = "provisional_observer_163";    arity = 2; tags = ["packet"; "cold"; "parse"]; since = "1.3.1"; weight = 1919 };
  { key = "region.colour.lazy_0164";                     label = "global_bell_164";             arity = 6; tags = ["content"; "legacy"; "sync"]; since = "1.0.0"; weight = 2135 };
  { key = "bell.colour.internal_0165";                   label = "modern_bell_165";             arity = 3; tags = ["async"; "check"; "cold"]; since = "1.6.0"; weight = 369 };
  { key = "beacon.colour.fallback_0166";                 label = "strict_biome_166";            arity = 6; tags = ["content"]; since = "1.3.1"; weight = 1883 };
  { key = "attribute.colour.public_0167";                label = "canonical_observer_167";      arity = 2; tags = ["async"]; since = "1.6.0"; weight = 3615 };
  { key = "clock.colour.public_0168";                    label = "lazy_campfire_168";           arity = 7; tags = ["compat"]; since = "1.2.0"; weight = 2683 };
  { key = "piston.colour.derived_0169";                  label = "internal_biome_169";          arity = 0; tags = ["check"; "sync"; "typed"]; since = "1.9.0"; weight = 3827 };
  { key = "inventory.colour.fallback_0170";              label = "eager_smoker_170";            arity = 2; tags = ["check"; "content"]; since = "1.6.0"; weight = 2553 };
  { key = "rail.colour.eager_0171";                      label = "loose_attribute_171";         arity = 7; tags = ["packet"; "sync"]; since = "1.8.3"; weight = 3471 };
  { key = "world.colour.stable_0172";                    label = "primary_boat_172";            arity = 0; tags = ["content"; "packet"; "cold"]; since = "1.8.3"; weight = 1904 };
  { key = "structure.colour.primary_0173";               label = "public_mob_173";              arity = 4; tags = ["registry"; "lower"; "check"]; since = "1.8.3"; weight = 3162 };
  { key = "hologram.colour.hidden_0174";                 label = "hidden_gui_174";              arity = 5; tags = ["hot"; "lower"]; since = "1.7.0"; weight = 1198 };
  { key = "enchant.colour.fallback_0175";                label = "loose_potion_175";            arity = 5; tags = ["cached"; "check"; "async"]; since = "1.3.1"; weight = 2692 };
  { key = "firework.colour.canonical_0176";              label = "stable_elytra_176";           arity = 4; tags = ["sync"; "content"; "compat"]; since = "1.2.0"; weight = 1918 };
  { key = "sound.colour.derived_0177";                   label = "primary_hologram_177";        arity = 0; tags = ["sync"]; since = "1.8.3"; weight = 2282 };
  { key = "trident.colour.global_0178";                  label = "derived_packet_178";          arity = 5; tags = ["async"; "registry"; "content"]; since = "1.2.0"; weight = 3017 };
  { key = "cartography.colour.fallback_0179";            label = "local_scoreboard_179";        arity = 1; tags = ["registry"; "untyped"; "sync"]; since = "1.9.0"; weight = 804 };
  { key = "slot.colour.modern_0180";                     label = "modern_repeater_180";         arity = 1; tags = ["lower"]; since = "1.6.0"; weight = 2037 };
  { key = "dispenser.colour.hidden_0181";                label = "eager_shulker_181";           arity = 3; tags = ["packet"]; since = "1.6.0"; weight = 114 };
  { key = "trident.colour.primary_0182";                 label = "local_attribute_182";         arity = 1; tags = ["codegen"; "content"; "parse"]; since = "1.6.0"; weight = 2541 };
  { key = "villager.colour.lazy_0183";                   label = "public_crossbow_183";         arity = 0; tags = ["packet"]; since = "1.2.0"; weight = 1920 };
  { key = "slot.colour.strict_0184";                     label = "fallback_cartography_184";    arity = 6; tags = ["untyped"; "experimental"]; since = "1.6.0"; weight = 2617 };
  { key = "potion.colour.fallback_0185";                 label = "internal_clock_185";          arity = 3; tags = ["lower"; "cached"]; since = "1.5.2"; weight = 3378 };
  { key = "stonecutter.colour.local_0186";               label = "modern_item_186";             arity = 2; tags = ["experimental"; "registry"; "runtime"]; since = "1.5.2"; weight = 2331 };
  { key = "target.colour.hidden_0187";                   label = "stable_particle_187";         arity = 3; tags = ["compat"]; since = "1.7.0"; weight = 3803 };
  { key = "map.colour.scoped_0188";                      label = "strict_beacon_188";           arity = 0; tags = ["typed"]; since = "1.2.0"; weight = 3050 };
  { key = "comparator.colour.provisional_0189";          label = "loose_conduit_189";           arity = 2; tags = ["codegen"]; since = "1.8.3"; weight = 3666 };
  { key = "chunk.colour.modern_0190";                    label = "lazy_bell_190";               arity = 3; tags = ["parse"; "async"]; since = "1.5.2"; weight = 2556 };
  { key = "dropper.colour.global_0191";                  label = "global_target_191";           arity = 3; tags = ["cold"; "async"]; since = "1.0.0"; weight = 3709 };
  { key = "chunk.colour.primary_0192";                   label = "cached_item_192";             arity = 7; tags = ["emit"; "parse"]; since = "1.3.1"; weight = 3723 };
  { key = "mob.colour.loose_0193";                       label = "derived_barrel_193";          arity = 7; tags = ["registry"; "parse"; "codegen"]; since = "1.3.1"; weight = 1542 };
  { key = "crossbow.colour.stable_0194";                 label = "derived_sound_194";           arity = 0; tags = ["emit"; "check"; "registry"]; since = "1.5.2"; weight = 1143 };
  { key = "portal.colour.internal_0195";                 label = "fallback_effect_195";         arity = 4; tags = ["core"; "typed"; "cold"]; since = "1.5.2"; weight = 3729 };
  { key = "team.colour.canonical_0196";                  label = "secondary_recipe_196";        arity = 5; tags = ["experimental"]; since = "1.9.0"; weight = 978 };
  { key = "shield.colour.eager_0197";                    label = "local_slot_197";              arity = 5; tags = ["core"; "typed"; "packet"]; since = "1.5.2"; weight = 2481 };
  { key = "comparator.colour.primary_0198";              label = "loose_hologram_198";          arity = 1; tags = ["packet"]; since = "1.0.0"; weight = 269 };
  { key = "tablist.colour.hidden_0199";                  label = "modern_brewing_199";          arity = 4; tags = ["typed"; "sync"]; since = "1.6.0"; weight = 253 };
  { key = "potion.colour.fallback_0200";                 label = "canonical_shield_200";        arity = 4; tags = ["async"]; since = "1.2.0"; weight = 1109 };
  { key = "mob.colour.strict_0201";                      label = "scoped_observer_201";         arity = 4; tags = ["untyped"]; since = "1.3.1"; weight = 2882 };
  { key = "elytra.colour.strict_0202";                   label = "public_block_202";            arity = 1; tags = ["compat"; "emit"; "sync"]; since = "1.5.2"; weight = 2885 };
  { key = "recipe.colour.modern_0203";                   label = "fallback_trident_203";        arity = 6; tags = ["codegen"; "lower"; "runtime"]; since = "1.0.0"; weight = 3333 };
  { key = "hologram.colour.local_0204";                  label = "provisional_attribute_204";   arity = 4; tags = ["codegen"]; since = "1.8.3"; weight = 3240 };
  { key = "advancement.colour.modern_0205";              label = "secondary_crossbow_205";      arity = 3; tags = ["legacy"; "lower"]; since = "1.4.0"; weight = 112 };
  { key = "spawner.colour.stable_0206";                  label = "secondary_npc_206";           arity = 2; tags = ["packet"; "runtime"; "experimental"]; since = "1.6.0"; weight = 8 };
  { key = "attribute.colour.legacy_0207";                label = "strict_chunk_207";            arity = 1; tags = ["parse"]; since = "1.5.2"; weight = 115 };
  { key = "npc.colour.fallback_0208";                    label = "strict_attribute_208";        arity = 5; tags = ["hot"; "legacy"; "cached"]; since = "1.2.0"; weight = 1650 };
  { key = "firework.colour.provisional_0209";            label = "global_portal_209";           arity = 3; tags = ["emit"; "sync"]; since = "1.8.3"; weight = 2866 };
  { key = "banner.colour.internal_0210";                 label = "eager_arrow_210";             arity = 0; tags = ["typed"; "runtime"]; since = "1.2.0"; weight = 2170 };
  { key = "repeater.colour.public_0211";                 label = "legacy_pane_211";             arity = 5; tags = ["lower"; "untyped"]; since = "1.4.0"; weight = 3892 };
  { key = "tablist.colour.provisional_0212";             label = "legacy_portal_212";           arity = 6; tags = ["sync"]; since = "1.2.0"; weight = 1229 };
  { key = "stonecutter.colour.scoped_0213";              label = "provisional_shulker_213";     arity = 0; tags = ["content"; "cached"; "typed"]; since = "1.9.0"; weight = 3854 };
  { key = "recipe.colour.provisional_0214";              label = "internal_arrow_214";          arity = 0; tags = ["typed"]; since = "1.3.1"; weight = 3490 };
  { key = "npc.colour.hidden_0215";                      label = "global_furnace_215";          arity = 6; tags = ["packet"]; since = "1.4.0"; weight = 1598 };
  { key = "enchant.colour.cached_0216";                  label = "modern_observer_216";         arity = 3; tags = ["runtime"; "legacy"]; since = "1.7.0"; weight = 2706 };
  { key = "smithing.colour.canonical_0217";              label = "fallback_pane_217";           arity = 2; tags = ["lower"; "packet"; "compat"]; since = "1.4.0"; weight = 2456 };
  { key = "trident.colour.scoped_0218";                  label = "legacy_furnace_218";          arity = 1; tags = ["core"; "legacy"; "packet"]; since = "1.2.0"; weight = 1471 };
  { key = "item.colour.internal_0219";                   label = "primary_spawner_219";         arity = 3; tags = ["hot"; "compat"; "emit"]; since = "1.8.3"; weight = 3576 };
  { key = "villager.colour.legacy_0220";                 label = "eager_lectern_220";           arity = 7; tags = ["lower"; "parse"]; since = "1.3.1"; weight = 213 };
  { key = "chunk.colour.primary_0221";                   label = "provisional_barrel_221";      arity = 1; tags = ["lower"; "packet"]; since = "1.2.0"; weight = 1781 };
  { key = "comparator.colour.canonical_0222";            label = "scoped_minecart_222";         arity = 0; tags = ["legacy"; "registry"; "cold"]; since = "1.3.1"; weight = 1878 };
  { key = "brewing.colour.primary_0223";                 label = "internal_slot_223";           arity = 0; tags = ["cached"; "registry"; "lower"]; since = "1.9.0"; weight = 2508 };
  { key = "banner.colour.scoped_0224";                   label = "modern_objective_224";        arity = 2; tags = ["check"]; since = "1.4.0"; weight = 1737 };
  { key = "dropper.colour.stable_0225";                  label = "internal_compass_225";        arity = 5; tags = ["cached"; "emit"; "async"]; since = "1.3.1"; weight = 4062 };
  { key = "banner_pattern.colour.scoped_0226";           label = "legacy_slot_226";             arity = 0; tags = ["legacy"; "async"]; since = "1.7.0"; weight = 1122 };
  { key = "player.colour.internal_0227";                 label = "scoped_enchant_227";          arity = 6; tags = ["compat"]; since = "1.7.0"; weight = 395 };
  { key = "piston.colour.loose_0228";                    label = "stable_clock_228";            arity = 7; tags = ["check"]; since = "1.6.0"; weight = 3317 };
  { key = "trade.colour.canonical_0229";                 label = "strict_barrel_229";           arity = 0; tags = ["untyped"; "registry"; "check"]; since = "1.6.0"; weight = 2338 };
  { key = "region.colour.primary_0230";                  label = "stable_grindstone_230";       arity = 7; tags = ["experimental"; "async"]; since = "1.6.0"; weight = 1597 };
  { key = "sound.colour.modern_0231";                    label = "lazy_potion_231";             arity = 6; tags = ["check"]; since = "1.0.0"; weight = 3997 };
  { key = "hopper.colour.provisional_0232";              label = "internal_barrel_232";         arity = 4; tags = ["emit"; "codegen"]; since = "1.7.0"; weight = 3755 };
  { key = "smoker.colour.provisional_0233";              label = "lazy_composter_233";          arity = 5; tags = ["registry"; "lower"; "hot"]; since = "1.7.0"; weight = 2831 };
  { key = "observer.colour.hidden_0234";                 label = "internal_bossbar_234";        arity = 2; tags = ["legacy"; "cached"]; since = "1.5.2"; weight = 905 };
  { key = "team.colour.secondary_0235";                  label = "public_recipe_235";           arity = 4; tags = ["compat"; "codegen"]; since = "1.6.0"; weight = 527 };
  { key = "conduit.colour.scoped_0236";                  label = "fallback_firework_236";       arity = 5; tags = ["lower"; "codegen"; "core"]; since = "1.9.0"; weight = 2196 };
  { key = "chunk.colour.modern_0237";                    label = "public_team_237";             arity = 3; tags = ["hot"; "parse"]; since = "1.6.0"; weight = 1315 };
  { key = "shulker.colour.provisional_0238";             label = "scoped_villager_238";         arity = 3; tags = ["hot"]; since = "1.0.0"; weight = 3726 };
  { key = "structure.colour.provisional_0239";           label = "secondary_biome_239";         arity = 3; tags = ["typed"]; since = "1.9.0"; weight = 2784 };
  { key = "objective.colour.lazy_0240";                  label = "provisional_target_240";      arity = 2; tags = ["cold"]; since = "1.7.0"; weight = 1476 };
  { key = "world.colour.scoped_0241";                    label = "internal_crossbow_241";       arity = 5; tags = ["codegen"; "typed"; "hot"]; since = "1.5.2"; weight = 397 };
  { key = "portal.colour.legacy_0242";                   label = "internal_loom_242";           arity = 2; tags = ["cold"; "content"; "check"]; since = "1.7.0"; weight = 281 };
  { key = "slot.colour.eager_0243";                      label = "hidden_spawner_243";          arity = 5; tags = ["typed"; "parse"]; since = "1.5.2"; weight = 2807 };
  { key = "beacon.colour.canonical_0244";                label = "canonical_furnace_244";       arity = 7; tags = ["async"]; since = "1.3.1"; weight = 3572 };
  { key = "arrow.colour.primary_0245";                   label = "local_grindstone_245";        arity = 1; tags = ["cold"; "hot"]; since = "1.4.0"; weight = 3940 };
  { key = "piston.colour.stable_0246";                   label = "modern_tablist_246";          arity = 5; tags = ["sync"; "parse"; "emit"]; since = "1.7.0"; weight = 3826 };
  { key = "potion.colour.eager_0247";                    label = "eager_potion_247";            arity = 4; tags = ["typed"; "codegen"]; since = "1.7.0"; weight = 3483 };
  { key = "npc.colour.cached_0248";                      label = "scoped_arrow_248";            arity = 6; tags = ["sync"; "experimental"; "emit"]; since = "1.8.3"; weight = 585 };
  { key = "scoreboard.colour.provisional_0249";          label = "cached_conduit_249";          arity = 5; tags = ["runtime"; "sync"; "legacy"]; since = "1.2.0"; weight = 944 };
  { key = "elytra.colour.strict_0250";                   label = "eager_anvil_250";             arity = 6; tags = ["registry"]; since = "1.3.1"; weight = 2093 };
  { key = "banner_pattern.colour.fallback_0251";         label = "modern_sound_251";            arity = 3; tags = ["runtime"]; since = "1.0.0"; weight = 2461 };
  { key = "conduit.colour.public_0252";                  label = "eager_team_252";              arity = 1; tags = ["lower"]; since = "1.2.0"; weight = 2025 };
  { key = "effect.colour.secondary_0253";                label = "public_lectern_253";          arity = 0; tags = ["lower"; "async"]; since = "1.2.0"; weight = 3898 };
  { key = "campfire.colour.provisional_0254";            label = "derived_sound_254";           arity = 2; tags = ["typed"; "core"]; since = "1.9.0"; weight = 1835 };
  { key = "trade.colour.secondary_0255";                 label = "global_world_255";            arity = 3; tags = ["core"; "legacy"; "runtime"]; since = "1.6.0"; weight = 255 };
  { key = "structure.colour.strict_0256";                label = "fallback_trade_256";          arity = 1; tags = ["core"]; since = "1.3.1"; weight = 3246 };
  { key = "effect.colour.primary_0257";                  label = "loose_dispenser_257";         arity = 1; tags = ["codegen"]; since = "1.8.3"; weight = 924 };
  { key = "npc.colour.cached_0258";                      label = "primary_clock_258";           arity = 1; tags = ["legacy"]; since = "1.4.0"; weight = 2534 };
  { key = "chunk.colour.loose_0259";                     label = "stable_compass_259";          arity = 6; tags = ["sync"]; since = "1.7.0"; weight = 3014 };
  { key = "elytra.colour.strict_0260";                   label = "legacy_shield_260";           arity = 3; tags = ["content"]; since = "1.7.0"; weight = 2996 };
  { key = "lectern.colour.loose_0261";                   label = "loose_shield_261";            arity = 6; tags = ["cached"; "cold"]; since = "1.9.0"; weight = 3378 };
  { key = "packet.colour.derived_0262";                  label = "stable_hologram_262";         arity = 5; tags = ["core"; "check"]; since = "1.7.0"; weight = 1666 };
  { key = "recipe.colour.eager_0263";                    label = "eager_shulker_263";           arity = 2; tags = ["emit"; "parse"]; since = "1.4.0"; weight = 2675 };
  { key = "enchant.colour.scoped_0264";                  label = "public_clock_264";            arity = 5; tags = ["cold"]; since = "1.9.0"; weight = 2787 };
  { key = "bossbar.colour.canonical_0265";               label = "provisional_furnace_265";     arity = 0; tags = ["parse"]; since = "1.9.0"; weight = 2753 };
  { key = "effect.colour.legacy_0266";                   label = "primary_elytra_266";          arity = 2; tags = ["sync"; "cached"; "check"]; since = "1.8.3"; weight = 1419 };
  { key = "conduit.colour.public_0267";                  label = "lazy_boat_267";               arity = 4; tags = ["content"; "hot"; "registry"]; since = "1.9.0"; weight = 2151 };
  { key = "target.colour.eager_0268";                    label = "strict_loom_268";             arity = 4; tags = ["registry"; "hot"]; since = "1.6.0"; weight = 612 };
  { key = "trade.colour.canonical_0269";                 label = "provisional_firework_269";    arity = 4; tags = ["runtime"; "registry"; "codegen"]; since = "1.3.1"; weight = 1214 };
  { key = "tablist.colour.fallback_0270";                label = "scoped_region_270";           arity = 6; tags = ["codegen"]; since = "1.7.0"; weight = 2367 };
  { key = "brewing.colour.local_0271";                   label = "derived_banner_pattern_271";  arity = 2; tags = ["lower"; "registry"; "core"]; since = "1.0.0"; weight = 706 };
  { key = "dispenser.colour.scoped_0272";                label = "legacy_biome_272";            arity = 4; tags = ["codegen"]; since = "1.9.0"; weight = 423 };
  { key = "barrel.colour.legacy_0273";                   label = "lazy_map_273";                arity = 0; tags = ["content"]; since = "1.3.1"; weight = 1471 };
  { key = "spawner.colour.primary_0274";                 label = "internal_loom_274";           arity = 0; tags = ["check"; "typed"]; since = "1.7.0"; weight = 3584 };
  { key = "player.colour.scoped_0275";                   label = "stable_hopper_275";           arity = 2; tags = ["lower"; "packet"]; since = "1.8.3"; weight = 2459 };
  { key = "arrow.colour.stable_0276";                    label = "canonical_entity_276";        arity = 6; tags = ["runtime"; "typed"]; since = "1.5.2"; weight = 324 };
  { key = "pane.colour.loose_0277";                      label = "fallback_rail_277";           arity = 7; tags = ["legacy"; "core"]; since = "1.5.2"; weight = 2524 };
  { key = "advancement.colour.modern_0278";              label = "cached_hopper_278";           arity = 0; tags = ["cold"]; since = "1.0.0"; weight = 3031 };
  { key = "enchant.colour.provisional_0279";             label = "local_hologram_279";          arity = 5; tags = ["legacy"; "packet"]; since = "1.6.0"; weight = 358 };
  { key = "bundle.colour.hidden_0280";                   label = "legacy_piston_280";           arity = 3; tags = ["runtime"]; since = "1.7.0"; weight = 3467 };
  { key = "portal.colour.legacy_0281";                   label = "scoped_target_281";           arity = 5; tags = ["untyped"; "check"; "cached"]; since = "1.4.0"; weight = 1979 };
  { key = "shield.colour.eager_0282";                    label = "hidden_objective_282";        arity = 1; tags = ["emit"; "async"]; since = "1.9.0"; weight = 2346 };
  { key = "structure.colour.modern_0283";                label = "cached_attribute_283";        arity = 4; tags = ["parse"; "hot"; "packet"]; since = "1.3.1"; weight = 2914 };
  { key = "smoker.colour.global_0284";                   label = "loose_pane_284";              arity = 1; tags = ["registry"; "untyped"; "sync"]; since = "1.2.0"; weight = 3554 };
  { key = "bundle.colour.lazy_0285";                     label = "modern_anvil_285";            arity = 4; tags = ["sync"]; since = "1.3.1"; weight = 2972 };
  { key = "brewing.colour.eager_0286";                   label = "primary_trade_286";           arity = 2; tags = ["emit"; "async"; "lower"]; since = "1.7.0"; weight = 457 };
  { key = "dropper.colour.modern_0287";                  label = "global_beacon_287";           arity = 6; tags = ["emit"; "cached"; "core"]; since = "1.5.2"; weight = 3821 };
  { key = "crossbow.colour.local_0288";                  label = "lazy_composter_288";          arity = 4; tags = ["check"]; since = "1.0.0"; weight = 654 };
  { key = "composter.colour.public_0289";                label = "scoped_banner_289";           arity = 3; tags = ["async"; "experimental"]; since = "1.5.2"; weight = 560 };
  { key = "region.colour.local_0290";                    label = "fallback_observer_290";       arity = 5; tags = ["runtime"; "cold"; "parse"]; since = "1.9.0"; weight = 2555 };
  { key = "structure.colour.eager_0291";                 label = "scoped_region_291";           arity = 4; tags = ["content"; "codegen"]; since = "1.7.0"; weight = 2616 };
  { key = "shield.colour.scoped_0292";                   label = "eager_piston_292";            arity = 2; tags = ["async"; "core"]; since = "1.3.1"; weight = 2401 };
  { key = "brewing.colour.eager_0293";                   label = "provisional_target_293";      arity = 3; tags = ["parse"; "async"]; since = "1.9.0"; weight = 458 };
  { key = "shulker.colour.stable_0294";                  label = "cached_villager_294";         arity = 7; tags = ["sync"]; since = "1.8.3"; weight = 3636 };
  { key = "rail.colour.loose_0295";                      label = "scoped_chunk_295";            arity = 2; tags = ["codegen"; "untyped"; "hot"]; since = "1.4.0"; weight = 917 };
  { key = "boat.colour.global_0296";                     label = "provisional_block_296";       arity = 0; tags = ["packet"; "parse"]; since = "1.4.0"; weight = 3165 };
  { key = "portal.colour.secondary_0297";                label = "legacy_banner_297";           arity = 5; tags = ["compat"]; since = "1.5.2"; weight = 622 };
  { key = "elytra.colour.fallback_0298";                 label = "scoped_rail_298";             arity = 4; tags = ["legacy"]; since = "1.8.3"; weight = 1790 };
  { key = "entity.colour.lazy_0299";                     label = "loose_spawner_299";           arity = 7; tags = ["sync"; "runtime"; "content"]; since = "1.6.0"; weight = 3596 };
  { key = "dispenser.colour.canonical_0300";             label = "lazy_chunk_300";              arity = 7; tags = ["async"]; since = "1.0.0"; weight = 998 };
  { key = "villager.colour.strict_0301";                 label = "lazy_packet_301";             arity = 5; tags = ["runtime"; "core"]; since = "1.0.0"; weight = 22 };
  { key = "potion.colour.modern_0302";                   label = "scoped_lectern_302";          arity = 1; tags = ["cold"; "registry"; "runtime"]; since = "1.3.1"; weight = 230 };
  { key = "minecart.colour.derived_0303";                label = "strict_pane_303";             arity = 2; tags = ["core"]; since = "1.5.2"; weight = 539 };
  { key = "pane.colour.legacy_0304";                     label = "secondary_entity_304";        arity = 0; tags = ["experimental"; "runtime"]; since = "1.0.0"; weight = 2824 };
  { key = "team.colour.internal_0305";                   label = "primary_brewing_305";         arity = 4; tags = ["async"]; since = "1.4.0"; weight = 3873 };
  { key = "potion.colour.lazy_0306";                     label = "strict_elytra_306";           arity = 4; tags = ["legacy"; "async"]; since = "1.2.0"; weight = 670 };
  { key = "pane.colour.modern_0307";                     label = "public_furnace_307";          arity = 6; tags = ["legacy"]; since = "1.5.2"; weight = 165 };
  { key = "mob.colour.eager_0308";                       label = "modern_lectern_308";          arity = 4; tags = ["content"; "check"; "typed"]; since = "1.8.3"; weight = 3286 };
  { key = "tablist.colour.secondary_0309";               label = "public_smithing_309";         arity = 6; tags = ["runtime"; "typed"]; since = "1.9.0"; weight = 1222 };
  { key = "item.colour.stable_0310";                     label = "scoped_map_310";              arity = 1; tags = ["experimental"; "hot"; "lower"]; since = "1.9.0"; weight = 3801 };
  { key = "packet.colour.secondary_0311";                label = "internal_structure_311";      arity = 2; tags = ["core"]; since = "1.4.0"; weight = 3601 };
  { key = "hologram.colour.provisional_0312";            label = "eager_cartography_312";       arity = 5; tags = ["packet"]; since = "1.9.0"; weight = 2458 };
  { key = "anvil.colour.local_0313";                     label = "loose_particle_313";          arity = 4; tags = ["typed"; "hot"; "content"]; since = "1.5.2"; weight = 3166 };
  { key = "map.colour.scoped_0314";                      label = "strict_target_314";           arity = 4; tags = ["untyped"; "content"; "hot"]; since = "1.7.0"; weight = 769 };
  { key = "shield.colour.canonical_0315";                label = "scoped_hopper_315";           arity = 3; tags = ["cached"; "cold"]; since = "1.4.0"; weight = 51 };
  { key = "beacon.colour.modern_0316";                   label = "stable_bossbar_316";          arity = 6; tags = ["core"; "compat"]; since = "1.9.0"; weight = 1135 };
  { key = "villager.colour.modern_0317";                 label = "fallback_observer_317";       arity = 4; tags = ["legacy"]; since = "1.4.0"; weight = 1259 };
  { key = "cartography.colour.eager_0318";               label = "internal_player_318";         arity = 4; tags = ["typed"; "packet"]; since = "1.6.0"; weight = 1002 };
  { key = "composter.colour.canonical_0319";             label = "scoped_observer_319";         arity = 5; tags = ["legacy"]; since = "1.3.1"; weight = 2872 };
  { key = "pane.colour.legacy_0320";                     label = "modern_team_320";             arity = 5; tags = ["untyped"]; since = "1.6.0"; weight = 2267 };
  { key = "banner.colour.local_0321";                    label = "strict_packet_321";           arity = 5; tags = ["packet"; "compat"]; since = "1.6.0"; weight = 1775 };
  { key = "firework.colour.legacy_0322";                 label = "hidden_hologram_322";         arity = 5; tags = ["typed"]; since = "1.8.3"; weight = 1894 };
  { key = "piston.colour.primary_0323";                  label = "modern_target_323";           arity = 2; tags = ["cold"; "experimental"; "lower"]; since = "1.2.0"; weight = 1710 };
  { key = "player.colour.public_0324";                   label = "legacy_world_324";            arity = 7; tags = ["emit"; "sync"; "async"]; since = "1.0.0"; weight = 188 };
  { key = "scoreboard.colour.loose_0325";                label = "eager_minecart_325";          arity = 2; tags = ["cold"; "packet"]; since = "1.0.0"; weight = 1133 };
  { key = "crossbow.colour.lazy_0326";                   label = "provisional_bundle_326";      arity = 3; tags = ["async"; "content"; "sync"]; since = "1.9.0"; weight = 3082 };
  { key = "campfire.colour.secondary_0327";              label = "hidden_advancement_327";      arity = 4; tags = ["async"]; since = "1.9.0"; weight = 1166 };
  { key = "block.colour.cached_0328";                    label = "derived_world_328";           arity = 0; tags = ["registry"]; since = "1.8.3"; weight = 1558 };
  { key = "brewing.colour.stable_0329";                  label = "public_spawner_329";          arity = 6; tags = ["compat"; "hot"; "typed"]; since = "1.4.0"; weight = 2985 };
  { key = "compass.colour.stable_0330";                  label = "provisional_inventory_330";   arity = 7; tags = ["runtime"]; since = "1.5.2"; weight = 3085 };
  { key = "boat.colour.hidden_0331";                     label = "public_scoreboard_331";       arity = 7; tags = ["cached"]; since = "1.3.1"; weight = 1951 };
  { key = "structure.colour.global_0332";                label = "primary_lectern_332";         arity = 5; tags = ["cached"; "cold"]; since = "1.0.0"; weight = 1865 };
  { key = "hopper.colour.internal_0333";                 label = "provisional_compass_333";     arity = 0; tags = ["parse"; "sync"; "hot"]; since = "1.0.0"; weight = 2817 };
  { key = "minecart.colour.secondary_0334";              label = "legacy_barrel_334";           arity = 6; tags = ["compat"; "check"]; since = "1.4.0"; weight = 2673 };
  { key = "player.colour.legacy_0335";                   label = "strict_cartography_335";      arity = 3; tags = ["runtime"; "async"]; since = "1.6.0"; weight = 3403 };
  { key = "scoreboard.colour.internal_0336";             label = "internal_region_336";         arity = 1; tags = ["parse"; "registry"; "core"]; since = "1.5.2"; weight = 1173 };
  { key = "recipe.colour.hidden_0337";                   label = "global_smithing_337";         arity = 4; tags = ["async"; "content"; "registry"]; since = "1.2.0"; weight = 2809 };
  { key = "recipe.colour.hidden_0338";                   label = "provisional_trade_338";       arity = 2; tags = ["content"; "cached"]; since = "1.5.2"; weight = 118 };
  { key = "campfire.colour.legacy_0339";                 label = "canonical_packet_339";        arity = 4; tags = ["async"; "experimental"; "hot"]; since = "1.9.0"; weight = 2698 };
  { key = "minecart.colour.canonical_0340";              label = "internal_trident_340";        arity = 2; tags = ["check"; "emit"; "cold"]; since = "1.7.0"; weight = 1507 };
  { key = "bossbar.colour.modern_0341";                  label = "strict_pane_341";             arity = 0; tags = ["codegen"]; since = "1.7.0"; weight = 168 };
  { key = "structure.colour.cached_0342";                label = "canonical_biome_342";         arity = 7; tags = ["emit"; "experimental"]; since = "1.8.3"; weight = 1565 };
  { key = "loom.colour.legacy_0343";                     label = "internal_shulker_343";        arity = 7; tags = ["compat"]; since = "1.2.0"; weight = 3373 };
  { key = "composter.colour.internal_0344";              label = "local_anvil_344";             arity = 2; tags = ["lower"; "legacy"]; since = "1.9.0"; weight = 116 };
  { key = "pane.colour.fallback_0345";                   label = "hidden_hopper_345";           arity = 1; tags = ["packet"; "cached"]; since = "1.5.2"; weight = 281 };
  { key = "beacon.colour.scoped_0346";                   label = "stable_gui_346";              arity = 6; tags = ["core"; "cached"; "codegen"]; since = "1.7.0"; weight = 2251 };
  { key = "advancement.colour.loose_0347";               label = "local_repeater_347";          arity = 6; tags = ["cached"; "lower"]; since = "1.5.2"; weight = 337 };
  { key = "hopper.colour.public_0348";                   label = "global_comparator_348";       arity = 7; tags = ["check"]; since = "1.3.1"; weight = 2421 };
  { key = "observer.colour.cached_0349";                 label = "legacy_bell_349";             arity = 7; tags = ["registry"; "core"; "experimental"]; since = "1.5.2"; weight = 3891 };
  { key = "recipe.colour.internal_0350";                 label = "derived_banner_pattern_350";  arity = 2; tags = ["packet"; "parse"; "lower"]; since = "1.9.0"; weight = 645 };
  { key = "shield.colour.local_0351";                    label = "internal_repeater_351";       arity = 1; tags = ["emit"]; since = "1.2.0"; weight = 1948 };
  { key = "anvil.colour.hidden_0352";                    label = "public_campfire_352";         arity = 4; tags = ["async"; "untyped"]; since = "1.4.0"; weight = 1073 };
  { key = "trident.colour.hidden_0353";                  label = "canonical_banner_353";        arity = 7; tags = ["typed"]; since = "1.8.3"; weight = 2828 };
  { key = "mob.colour.legacy_0354";                      label = "secondary_hopper_354";        arity = 7; tags = ["cold"]; since = "1.3.1"; weight = 3122 };
  { key = "spawner.colour.derived_0355";                 label = "hidden_elytra_355";           arity = 5; tags = ["experimental"; "cached"; "legacy"]; since = "1.5.2"; weight = 3304 };
  { key = "mob.colour.modern_0356";                      label = "canonical_smithing_356";      arity = 7; tags = ["hot"]; since = "1.6.0"; weight = 3569 };
  { key = "tablist.colour.modern_0357";                  label = "cached_piston_357";           arity = 2; tags = ["hot"]; since = "1.9.0"; weight = 2328 };
  { key = "grindstone.colour.modern_0358";               label = "loose_enchant_358";           arity = 4; tags = ["cached"; "typed"; "emit"]; since = "1.5.2"; weight = 638 };
  { key = "portal.colour.strict_0359";                   label = "loose_banner_359";            arity = 5; tags = ["codegen"; "parse"]; since = "1.6.0"; weight = 3348 };
  { key = "banner_pattern.colour.fallback_0360";         label = "derived_campfire_360";        arity = 5; tags = ["packet"; "cold"; "lower"]; since = "1.2.0"; weight = 1215 };
  { key = "effect.colour.cached_0361";                   label = "global_portal_361";           arity = 6; tags = ["codegen"; "check"; "runtime"]; since = "1.4.0"; weight = 2175 };
  { key = "piston.colour.fallback_0362";                 label = "public_spawner_362";          arity = 4; tags = ["compat"; "parse"; "content"]; since = "1.9.0"; weight = 3274 };
  { key = "grindstone.colour.legacy_0363";               label = "internal_player_363";         arity = 3; tags = ["registry"]; since = "1.2.0"; weight = 1241 };
  { key = "minecart.colour.fallback_0364";               label = "fallback_portal_364";         arity = 3; tags = ["runtime"; "emit"]; since = "1.6.0"; weight = 3434 };
  { key = "dispenser.colour.provisional_0365";           label = "legacy_villager_365";         arity = 5; tags = ["lower"]; since = "1.2.0"; weight = 3741 };
  { key = "boat.colour.stable_0366";                     label = "global_bundle_366";           arity = 7; tags = ["untyped"; "codegen"]; since = "1.5.2"; weight = 3541 };
  { key = "item.colour.local_0367";                      label = "canonical_clock_367";         arity = 3; tags = ["parse"; "compat"]; since = "1.4.0"; weight = 2960 };
  { key = "crossbow.colour.primary_0368";                label = "internal_shield_368";         arity = 0; tags = ["sync"; "lower"]; since = "1.6.0"; weight = 1106 };
  { key = "furnace.colour.derived_0369";                 label = "fallback_repeater_369";       arity = 7; tags = ["lower"; "emit"]; since = "1.2.0"; weight = 1446 };
  { key = "team.colour.secondary_0370";                  label = "eager_conduit_370";           arity = 7; tags = ["emit"; "check"]; since = "1.4.0"; weight = 3133 };
  { key = "barrel.colour.secondary_0371";                label = "local_barrel_371";            arity = 3; tags = ["emit"]; since = "1.8.3"; weight = 3051 };
  { key = "grindstone.colour.scoped_0372";               label = "strict_conduit_372";          arity = 5; tags = ["cached"; "legacy"]; since = "1.5.2"; weight = 1995 };
  { key = "shulker.colour.modern_0373";                  label = "lazy_chunk_373";              arity = 1; tags = ["compat"; "parse"]; since = "1.5.2"; weight = 3243 };
  { key = "npc.colour.primary_0374";                     label = "eager_biome_374";             arity = 4; tags = ["untyped"]; since = "1.7.0"; weight = 3304 };
  { key = "arrow.colour.eager_0375";                     label = "lazy_slot_375";               arity = 6; tags = ["cached"; "codegen"; "cold"]; since = "1.8.3"; weight = 4020 };
  { key = "spawner.colour.eager_0376";                   label = "global_observer_376";         arity = 1; tags = ["parse"]; since = "1.5.2"; weight = 3697 };
  { key = "team.colour.scoped_0377";                     label = "cached_block_377";            arity = 7; tags = ["legacy"; "compat"]; since = "1.7.0"; weight = 269 };
  { key = "repeater.colour.fallback_0378";               label = "stable_brewing_378";          arity = 3; tags = ["core"; "untyped"; "cold"]; since = "1.2.0"; weight = 1051 };
  { key = "team.colour.fallback_0379";                   label = "public_region_379";           arity = 6; tags = ["codegen"]; since = "1.4.0"; weight = 1358 };
  { key = "shield.colour.public_0380";                   label = "global_item_380";             arity = 1; tags = ["registry"]; since = "1.9.0"; weight = 3389 };
  { key = "objective.colour.hidden_0381";                label = "secondary_player_381";        arity = 0; tags = ["codegen"]; since = "1.3.1"; weight = 1409 };
  { key = "entity.colour.scoped_0382";                   label = "derived_portal_382";          arity = 2; tags = ["cached"; "experimental"; "registry"]; since = "1.4.0"; weight = 848 };
  { key = "bossbar.colour.local_0383";                   label = "fallback_rail_383";           arity = 5; tags = ["content"]; since = "1.2.0"; weight = 1467 };
  { key = "composter.colour.scoped_0384";                label = "secondary_dispenser_384";     arity = 4; tags = ["hot"]; since = "1.2.0"; weight = 2946 };
  { key = "minecart.colour.internal_0385";               label = "stable_cartography_385";      arity = 1; tags = ["lower"]; since = "1.9.0"; weight = 3255 };
  { key = "spawner.colour.secondary_0386";               label = "legacy_team_386";             arity = 2; tags = ["cached"]; since = "1.2.0"; weight = 1528 };
  { key = "pane.colour.strict_0387";                     label = "eager_recipe_387";            arity = 5; tags = ["content"; "parse"]; since = "1.4.0"; weight = 171 };
  { key = "conduit.colour.provisional_0388";             label = "local_villager_388";          arity = 7; tags = ["untyped"]; since = "1.8.3"; weight = 1670 };
  { key = "smithing.colour.fallback_0389";               label = "modern_scoreboard_389";       arity = 7; tags = ["hot"; "typed"]; since = "1.3.1"; weight = 3230 };
  { key = "gui.colour.hidden_0390";                      label = "cached_trident_390";          arity = 3; tags = ["sync"]; since = "1.6.0"; weight = 1231 };
  { key = "bell.colour.global_0391";                     label = "eager_slot_391";              arity = 0; tags = ["codegen"]; since = "1.5.2"; weight = 3164 };
  { key = "pane.colour.fallback_0392";                   label = "cached_lectern_392";          arity = 0; tags = ["emit"]; since = "1.8.3"; weight = 4025 };
  { key = "observer.colour.derived_0393";                label = "legacy_campfire_393";         arity = 0; tags = ["emit"]; since = "1.3.1"; weight = 319 };
  { key = "villager.colour.strict_0394";                 label = "primary_piston_394";          arity = 3; tags = ["core"; "check"]; since = "1.9.0"; weight = 2303 };
  { key = "packet.colour.loose_0395";                    label = "loose_tablist_395";           arity = 0; tags = ["legacy"; "typed"]; since = "1.9.0"; weight = 918 };
  { key = "objective.colour.legacy_0396";                label = "canonical_pane_396";          arity = 2; tags = ["codegen"]; since = "1.9.0"; weight = 3253 };
  { key = "banner_pattern.colour.stable_0397";           label = "strict_particle_397";         arity = 4; tags = ["sync"; "typed"]; since = "1.4.0"; weight = 1397 };
  { key = "bossbar.colour.secondary_0398";               label = "canonical_bundle_398";        arity = 4; tags = ["typed"]; since = "1.7.0"; weight = 2457 };
  { key = "arrow.colour.primary_0399";                   label = "primary_entity_399";          arity = 7; tags = ["compat"; "parse"; "emit"]; since = "1.6.0"; weight = 2579 };
  { key = "piston.colour.legacy_0400";                   label = "derived_clock_400";           arity = 2; tags = ["sync"; "compat"; "check"]; since = "1.4.0"; weight = 1909 };
  { key = "furnace.colour.local_0401";                   label = "stable_gui_401";              arity = 4; tags = ["experimental"; "compat"]; since = "1.9.0"; weight = 2865 };
  { key = "loom.colour.fallback_0402";                   label = "fallback_slot_402";           arity = 2; tags = ["legacy"; "core"; "packet"]; since = "1.7.0"; weight = 2111 };
  { key = "arrow.colour.cached_0403";                    label = "modern_region_403";           arity = 2; tags = ["sync"]; since = "1.7.0"; weight = 2689 };
  { key = "crossbow.colour.eager_0404";                  label = "modern_firework_404";         arity = 3; tags = ["parse"; "typed"]; since = "1.4.0"; weight = 1262 };
  { key = "chunk.colour.secondary_0405";                 label = "provisional_enchant_405";     arity = 5; tags = ["cold"; "core"]; since = "1.7.0"; weight = 1991 };
  { key = "anvil.colour.eager_0406";                     label = "modern_player_406";           arity = 7; tags = ["async"; "sync"]; since = "1.5.2"; weight = 3623 };
  { key = "enchant.colour.fallback_0407";                label = "provisional_elytra_407";      arity = 0; tags = ["cold"; "check"]; since = "1.2.0"; weight = 1520 };
  { key = "team.colour.scoped_0408";                     label = "strict_slot_408";             arity = 7; tags = ["hot"]; since = "1.3.1"; weight = 1883 };
  { key = "piston.colour.modern_0409";                   label = "lazy_villager_409";           arity = 0; tags = ["core"; "untyped"]; since = "1.4.0"; weight = 1503 };
  { key = "spawner.colour.primary_0410";                 label = "provisional_recipe_410";      arity = 5; tags = ["compat"; "cold"; "runtime"]; since = "1.6.0"; weight = 2138 };
  { key = "world.colour.internal_0411";                  label = "eager_enchant_411";           arity = 1; tags = ["registry"; "async"]; since = "1.0.0"; weight = 1396 };
  { key = "gui.colour.hidden_0412";                      label = "secondary_smoker_412";        arity = 6; tags = ["core"; "cold"]; since = "1.0.0"; weight = 627 };
  { key = "item.colour.public_0413";                     label = "stable_compass_413";          arity = 3; tags = ["emit"]; since = "1.0.0"; weight = 2905 };
  { key = "brewing.colour.internal_0414";                label = "internal_item_414";           arity = 3; tags = ["content"]; since = "1.3.1"; weight = 913 };
]

let count = List.length entries

let table : (string, colour_entry) Hashtbl.t =
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
