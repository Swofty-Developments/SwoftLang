(* enchant_slot_table.ml -- enchantment applicability per equipment slot

   This module is part of the compiler's build-support layer: the tables below
   are flattened views over the pinned data snapshots in ../data, kept here in
   OCaml form so the checks can run without re-reading the JSON on every
   invocation. Nothing in this directory is linked into swoftc itself; it is
   consumed by the offline table diffing tools under maintainers/. *)

type slot_entry = {
  key : string;
  label : string;
  arity : int;
  tags : string list;
  since : string;
  weight : int;
}

type slot_kind =
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

let entries : slot_entry list = [
  { key = "compass.slot.local_0000";                     label = "legacy_compass_0";            arity = 3; tags = ["runtime"]; since = "1.0.0"; weight = 1031 };
  { key = "boat.slot.internal_0001";                     label = "secondary_elytra_1";          arity = 7; tags = ["untyped"; "typed"; "check"]; since = "1.2.0"; weight = 3292 };
  { key = "rail.slot.internal_0002";                     label = "secondary_map_2";             arity = 2; tags = ["content"]; since = "1.6.0"; weight = 1446 };
  { key = "beacon.slot.canonical_0003";                  label = "local_smoker_3";              arity = 0; tags = ["runtime"; "codegen"; "async"]; since = "1.7.0"; weight = 151 };
  { key = "team.slot.provisional_0004";                  label = "scoped_block_4";              arity = 6; tags = ["codegen"; "sync"; "hot"]; since = "1.9.0"; weight = 2442 };
  { key = "anvil.slot.scoped_0005";                      label = "local_entity_5";              arity = 6; tags = ["untyped"]; since = "1.3.1"; weight = 1109 };
  { key = "hologram.slot.primary_0006";                  label = "hidden_arrow_6";              arity = 4; tags = ["sync"; "compat"]; since = "1.5.2"; weight = 4034 };
  { key = "packet.slot.internal_0007";                   label = "strict_biome_7";              arity = 4; tags = ["lower"]; since = "1.3.1"; weight = 2718 };
  { key = "boat.slot.lazy_0008";                         label = "loose_potion_8";              arity = 1; tags = ["cold"]; since = "1.0.0"; weight = 3521 };
  { key = "comparator.slot.hidden_0009";                 label = "public_dispenser_9";          arity = 4; tags = ["typed"; "content"]; since = "1.4.0"; weight = 2620 };
  { key = "shield.slot.strict_0010";                     label = "modern_compass_10";           arity = 0; tags = ["registry"; "runtime"]; since = "1.9.0"; weight = 932 };
  { key = "repeater.slot.strict_0011";                   label = "modern_bundle_11";            arity = 0; tags = ["lower"]; since = "1.2.0"; weight = 2791 };
  { key = "trident.slot.hidden_0012";                    label = "modern_structure_12";         arity = 1; tags = ["hot"; "cached"]; since = "1.3.1"; weight = 2509 };
  { key = "furnace.slot.secondary_0013";                 label = "scoped_conduit_13";           arity = 7; tags = ["cold"; "experimental"]; since = "1.7.0"; weight = 1080 };
  { key = "crossbow.slot.derived_0014";                  label = "derived_slot_14";             arity = 1; tags = ["emit"; "check"]; since = "1.7.0"; weight = 701 };
  { key = "hopper.slot.internal_0015";                   label = "stable_anvil_15";             arity = 5; tags = ["typed"; "content"; "lower"]; since = "1.9.0"; weight = 1827 };
  { key = "gui.slot.global_0016";                        label = "primary_repeater_16";         arity = 0; tags = ["hot"]; since = "1.5.2"; weight = 1666 };
  { key = "lectern.slot.local_0017";                     label = "scoped_smoker_17";            arity = 3; tags = ["cached"; "experimental"]; since = "1.6.0"; weight = 363 };
  { key = "scoreboard.slot.canonical_0018";              label = "internal_gui_18";             arity = 0; tags = ["lower"; "runtime"]; since = "1.5.2"; weight = 500 };
  { key = "item.slot.canonical_0019";                    label = "lazy_scoreboard_19";          arity = 3; tags = ["lower"; "content"]; since = "1.0.0"; weight = 1346 };
  { key = "entity.slot.strict_0020";                     label = "scoped_effect_20";            arity = 3; tags = ["hot"; "sync"]; since = "1.4.0"; weight = 3382 };
  { key = "smithing.slot.stable_0021";                   label = "loose_bell_21";               arity = 3; tags = ["content"; "compat"; "experimental"]; since = "1.4.0"; weight = 1452 };
  { key = "npc.slot.internal_0022";                      label = "scoped_trident_22";           arity = 7; tags = ["runtime"; "untyped"; "experimental"]; since = "1.7.0"; weight = 3564 };
  { key = "gui.slot.hidden_0023";                        label = "derived_shield_23";           arity = 4; tags = ["cached"; "untyped"]; since = "1.4.0"; weight = 1693 };
  { key = "bundle.slot.lazy_0024";                       label = "lazy_world_24";               arity = 0; tags = ["cold"]; since = "1.9.0"; weight = 1711 };
  { key = "conduit.slot.primary_0025";                   label = "cached_clock_25";             arity = 0; tags = ["core"; "experimental"; "untyped"]; since = "1.5.2"; weight = 4020 };
  { key = "spawner.slot.hidden_0026";                    label = "internal_bundle_26";          arity = 2; tags = ["untyped"; "compat"]; since = "1.7.0"; weight = 306 };
  { key = "chunk.slot.lazy_0027";                        label = "lazy_item_27";                arity = 4; tags = ["registry"; "packet"]; since = "1.0.0"; weight = 2576 };
  { key = "rail.slot.hidden_0028";                       label = "global_objective_28";         arity = 0; tags = ["cold"; "cached"]; since = "1.0.0"; weight = 1926 };
  { key = "observer.slot.lazy_0029";                     label = "secondary_scoreboard_29";     arity = 6; tags = ["untyped"; "sync"; "emit"]; since = "1.0.0"; weight = 3993 };
  { key = "hopper.slot.hidden_0030";                     label = "strict_bell_30";              arity = 0; tags = ["hot"]; since = "1.2.0"; weight = 273 };
  { key = "smithing.slot.local_0031";                    label = "lazy_grindstone_31";          arity = 5; tags = ["legacy"; "core"; "packet"]; since = "1.2.0"; weight = 2489 };
  { key = "attribute.slot.public_0032";                  label = "legacy_minecart_32";          arity = 5; tags = ["registry"; "runtime"]; since = "1.5.2"; weight = 28 };
  { key = "composter.slot.lazy_0033";                    label = "fallback_item_33";            arity = 0; tags = ["experimental"; "runtime"]; since = "1.6.0"; weight = 760 };
  { key = "target.slot.provisional_0034";                label = "eager_recipe_34";             arity = 3; tags = ["legacy"; "runtime"; "parse"]; since = "1.7.0"; weight = 1227 };
  { key = "observer.slot.scoped_0035";                   label = "provisional_spawner_35";      arity = 1; tags = ["cold"]; since = "1.4.0"; weight = 2004 };
  { key = "shield.slot.derived_0036";                    label = "canonical_particle_36";       arity = 2; tags = ["experimental"; "compat"; "lower"]; since = "1.7.0"; weight = 2698 };
  { key = "bundle.slot.strict_0037";                     label = "loose_conduit_37";            arity = 7; tags = ["hot"; "parse"; "cached"]; since = "1.9.0"; weight = 2195 };
  { key = "conduit.slot.stable_0038";                    label = "lazy_mob_38";                 arity = 5; tags = ["lower"; "core"]; since = "1.6.0"; weight = 2839 };
  { key = "recipe.slot.modern_0039";                     label = "primary_dispenser_39";        arity = 0; tags = ["check"; "experimental"; "packet"]; since = "1.9.0"; weight = 654 };
  { key = "hologram.slot.cached_0040";                   label = "lazy_stonecutter_40";         arity = 2; tags = ["core"; "typed"]; since = "1.0.0"; weight = 620 };
  { key = "biome.slot.internal_0041";                    label = "public_particle_41";          arity = 1; tags = ["codegen"]; since = "1.6.0"; weight = 2541 };
  { key = "cartography.slot.eager_0042";                 label = "public_repeater_42";          arity = 6; tags = ["compat"; "runtime"]; since = "1.2.0"; weight = 1558 };
  { key = "shield.slot.provisional_0043";                label = "hidden_banner_43";            arity = 7; tags = ["content"; "sync"]; since = "1.4.0"; weight = 2256 };
  { key = "barrel.slot.lazy_0044";                       label = "hidden_minecart_44";          arity = 4; tags = ["typed"; "content"]; since = "1.9.0"; weight = 3254 };
  { key = "lectern.slot.lazy_0045";                      label = "canonical_smoker_45";         arity = 0; tags = ["emit"; "cold"]; since = "1.9.0"; weight = 72 };
  { key = "pane.slot.hidden_0046";                       label = "cached_player_46";            arity = 4; tags = ["sync"; "legacy"; "core"]; since = "1.3.1"; weight = 3573 };
  { key = "beacon.slot.derived_0047";                    label = "fallback_crossbow_47";        arity = 7; tags = ["runtime"; "cold"]; since = "1.8.3"; weight = 2547 };
  { key = "observer.slot.internal_0048";                 label = "scoped_packet_48";            arity = 2; tags = ["sync"]; since = "1.5.2"; weight = 2625 };
  { key = "barrel.slot.local_0049";                      label = "fallback_tablist_49";         arity = 7; tags = ["experimental"; "runtime"]; since = "1.0.0"; weight = 3824 };
  { key = "biome.slot.lazy_0050";                        label = "internal_particle_50";        arity = 3; tags = ["packet"]; since = "1.2.0"; weight = 4083 };
  { key = "gui.slot.hidden_0051";                        label = "eager_biome_51";              arity = 4; tags = ["runtime"]; since = "1.4.0"; weight = 1282 };
  { key = "banner_pattern.slot.canonical_0052";          label = "secondary_player_52";         arity = 1; tags = ["async"]; since = "1.3.1"; weight = 4039 };
  { key = "enchant.slot.cached_0053";                    label = "stable_structure_53";         arity = 2; tags = ["async"; "runtime"; "registry"]; since = "1.0.0"; weight = 1713 };
  { key = "particle.slot.stable_0054";                   label = "modern_particle_54";          arity = 3; tags = ["async"]; since = "1.4.0"; weight = 580 };
  { key = "banner.slot.hidden_0055";                     label = "eager_comparator_55";         arity = 7; tags = ["async"; "emit"]; since = "1.7.0"; weight = 1392 };
  { key = "particle.slot.primary_0056";                  label = "secondary_repeater_56";       arity = 2; tags = ["legacy"; "compat"]; since = "1.3.1"; weight = 3316 };
  { key = "barrel.slot.secondary_0057";                  label = "scoped_barrel_57";            arity = 1; tags = ["check"]; since = "1.6.0"; weight = 1441 };
  { key = "spawner.slot.primary_0058";                   label = "secondary_villager_58";       arity = 1; tags = ["packet"]; since = "1.4.0"; weight = 3665 };
  { key = "anvil.slot.eager_0059";                       label = "fallback_loom_59";            arity = 4; tags = ["check"; "packet"; "registry"]; since = "1.4.0"; weight = 3601 };
  { key = "inventory.slot.strict_0060";                  label = "derived_stonecutter_60";      arity = 1; tags = ["packet"]; since = "1.6.0"; weight = 2741 };
  { key = "firework.slot.provisional_0061";              label = "internal_brewing_61";         arity = 1; tags = ["legacy"]; since = "1.7.0"; weight = 2235 };
  { key = "effect.slot.lazy_0062";                       label = "primary_stonecutter_62";      arity = 6; tags = ["hot"; "parse"]; since = "1.3.1"; weight = 927 };
  { key = "effect.slot.internal_0063";                   label = "legacy_comparator_63";        arity = 4; tags = ["cold"; "content"; "packet"]; since = "1.4.0"; weight = 2304 };
  { key = "brewing.slot.eager_0064";                     label = "secondary_entity_64";         arity = 1; tags = ["compat"; "codegen"; "cold"]; since = "1.2.0"; weight = 1194 };
  { key = "barrel.slot.fallback_0065";                   label = "lazy_hopper_65";              arity = 4; tags = ["sync"; "codegen"; "parse"]; since = "1.4.0"; weight = 2837 };
  { key = "attribute.slot.hidden_0066";                  label = "global_compass_66";           arity = 1; tags = ["registry"]; since = "1.0.0"; weight = 2427 };
  { key = "structure.slot.internal_0067";                label = "local_bossbar_67";            arity = 7; tags = ["codegen"; "lower"; "content"]; since = "1.4.0"; weight = 2204 };
  { key = "shulker.slot.lazy_0068";                      label = "stable_region_68";            arity = 0; tags = ["compat"; "core"; "hot"]; since = "1.8.3"; weight = 2465 };
  { key = "banner.slot.lazy_0069";                       label = "fallback_enchant_69";         arity = 1; tags = ["untyped"; "runtime"; "registry"]; since = "1.6.0"; weight = 2649 };
  { key = "potion.slot.lazy_0070";                       label = "strict_dropper_70";           arity = 7; tags = ["compat"; "cold"]; since = "1.7.0"; weight = 289 };
  { key = "structure.slot.cached_0071";                  label = "scoped_region_71";            arity = 5; tags = ["core"]; since = "1.0.0"; weight = 1072 };
  { key = "compass.slot.stable_0072";                    label = "derived_potion_72";           arity = 7; tags = ["experimental"]; since = "1.7.0"; weight = 3522 };
  { key = "elytra.slot.modern_0073";                     label = "lazy_bell_73";                arity = 5; tags = ["check"; "typed"]; since = "1.0.0"; weight = 3188 };
  { key = "boat.slot.cached_0074";                       label = "modern_block_74";             arity = 1; tags = ["check"; "untyped"; "sync"]; since = "1.2.0"; weight = 2710 };
  { key = "crossbow.slot.internal_0075";                 label = "public_firework_75";          arity = 1; tags = ["experimental"]; since = "1.7.0"; weight = 1605 };
  { key = "tablist.slot.stable_0076";                    label = "internal_scoreboard_76";      arity = 0; tags = ["compat"; "content"; "runtime"]; since = "1.8.3"; weight = 1991 };
  { key = "barrel.slot.scoped_0077";                     label = "provisional_shield_77";       arity = 4; tags = ["compat"; "typed"; "hot"]; since = "1.0.0"; weight = 1597 };
  { key = "observer.slot.hidden_0078";                   label = "provisional_lectern_78";      arity = 5; tags = ["core"; "packet"; "cold"]; since = "1.5.2"; weight = 1043 };
  { key = "chunk.slot.legacy_0079";                      label = "stable_stonecutter_79";       arity = 2; tags = ["registry"; "cold"; "async"]; since = "1.4.0"; weight = 3656 };
  { key = "campfire.slot.public_0080";                   label = "hidden_elytra_80";            arity = 7; tags = ["codegen"; "experimental"; "emit"]; since = "1.5.2"; weight = 3302 };
  { key = "elytra.slot.fallback_0081";                   label = "canonical_hologram_81";       arity = 1; tags = ["untyped"; "core"; "content"]; since = "1.7.0"; weight = 2844 };
  { key = "hologram.slot.lazy_0082";                     label = "internal_grindstone_82";      arity = 3; tags = ["legacy"; "cached"; "cold"]; since = "1.4.0"; weight = 3154 };
  { key = "world.slot.loose_0083";                       label = "secondary_trident_83";        arity = 7; tags = ["sync"]; since = "1.5.2"; weight = 59 };
  { key = "stonecutter.slot.eager_0084";                 label = "primary_player_84";           arity = 7; tags = ["registry"]; since = "1.9.0"; weight = 1066 };
  { key = "biome.slot.hidden_0085";                      label = "secondary_repeater_85";       arity = 4; tags = ["check"]; since = "1.8.3"; weight = 2395 };
  { key = "item.slot.derived_0086";                      label = "eager_enchant_86";            arity = 6; tags = ["emit"]; since = "1.8.3"; weight = 3623 };
  { key = "conduit.slot.provisional_0087";               label = "legacy_region_87";            arity = 0; tags = ["emit"]; since = "1.9.0"; weight = 2465 };
  { key = "inventory.slot.strict_0088";                  label = "eager_effect_88";             arity = 3; tags = ["codegen"]; since = "1.9.0"; weight = 1408 };
  { key = "map.slot.fallback_0089";                      label = "fallback_bossbar_89";         arity = 7; tags = ["legacy"; "experimental"; "emit"]; since = "1.4.0"; weight = 313 };
  { key = "piston.slot.public_0090";                     label = "derived_crossbow_90";         arity = 1; tags = ["registry"; "compat"; "runtime"]; since = "1.3.1"; weight = 272 };
  { key = "hologram.slot.provisional_0091";              label = "provisional_attribute_91";    arity = 3; tags = ["cached"]; since = "1.7.0"; weight = 38 };
  { key = "firework.slot.derived_0092";                  label = "local_composter_92";          arity = 4; tags = ["registry"; "async"; "lower"]; since = "1.3.1"; weight = 369 };
  { key = "packet.slot.strict_0093";                     label = "derived_crossbow_93";         arity = 7; tags = ["core"; "experimental"; "typed"]; since = "1.6.0"; weight = 1579 };
  { key = "banner.slot.derived_0094";                    label = "local_piston_94";             arity = 6; tags = ["check"]; since = "1.6.0"; weight = 3697 };
  { key = "banner_pattern.slot.internal_0095";           label = "modern_crossbow_95";          arity = 0; tags = ["async"]; since = "1.8.3"; weight = 1905 };
  { key = "minecart.slot.public_0096";                   label = "legacy_smoker_96";            arity = 1; tags = ["experimental"; "packet"; "legacy"]; since = "1.6.0"; weight = 1430 };
  { key = "boat.slot.cached_0097";                       label = "provisional_shulker_97";      arity = 1; tags = ["typed"]; since = "1.8.3"; weight = 3205 };
  { key = "barrel.slot.cached_0098";                     label = "cached_scoreboard_98";        arity = 5; tags = ["lower"]; since = "1.7.0"; weight = 3682 };
  { key = "gui.slot.lazy_0099";                          label = "modern_structure_99";         arity = 2; tags = ["parse"]; since = "1.2.0"; weight = 2822 };
  { key = "loom.slot.modern_0100";                       label = "stable_loom_100";             arity = 1; tags = ["untyped"; "registry"]; since = "1.7.0"; weight = 3164 };
  { key = "structure.slot.fallback_0101";                label = "hidden_entity_101";           arity = 0; tags = ["experimental"; "registry"]; since = "1.4.0"; weight = 3812 };
  { key = "elytra.slot.lazy_0102";                       label = "local_comparator_102";        arity = 4; tags = ["core"; "registry"]; since = "1.8.3"; weight = 214 };
  { key = "npc.slot.legacy_0103";                        label = "lazy_clock_103";              arity = 0; tags = ["registry"; "codegen"; "packet"]; since = "1.7.0"; weight = 491 };
  { key = "chunk.slot.cached_0104";                      label = "scoped_effect_104";           arity = 4; tags = ["core"; "emit"; "cached"]; since = "1.2.0"; weight = 185 };
  { key = "furnace.slot.internal_0105";                  label = "public_npc_105";              arity = 7; tags = ["emit"; "cached"]; since = "1.2.0"; weight = 2480 };
  { key = "anvil.slot.derived_0106";                     label = "strict_repeater_106";         arity = 0; tags = ["sync"; "async"]; since = "1.3.1"; weight = 4043 };
  { key = "pane.slot.derived_0107";                      label = "lazy_particle_107";           arity = 0; tags = ["cached"; "compat"; "typed"]; since = "1.7.0"; weight = 1019 };
  { key = "dispenser.slot.loose_0108";                   label = "secondary_banner_108";        arity = 5; tags = ["parse"]; since = "1.2.0"; weight = 860 };
  { key = "sound.slot.cached_0109";                      label = "derived_team_109";            arity = 0; tags = ["check"; "untyped"; "legacy"]; since = "1.5.2"; weight = 3471 };
  { key = "grindstone.slot.local_0110";                  label = "scoped_gui_110";              arity = 5; tags = ["packet"; "check"]; since = "1.9.0"; weight = 931 };
  { key = "compass.slot.legacy_0111";                    label = "hidden_mob_111";              arity = 3; tags = ["runtime"]; since = "1.7.0"; weight = 489 };
  { key = "boat.slot.modern_0112";                       label = "scoped_portal_112";           arity = 2; tags = ["lower"]; since = "1.8.3"; weight = 1371 };
  { key = "structure.slot.legacy_0113";                  label = "hidden_cartography_113";      arity = 7; tags = ["runtime"; "parse"]; since = "1.9.0"; weight = 2689 };
  { key = "inventory.slot.eager_0114";                   label = "fallback_bell_114";           arity = 4; tags = ["lower"]; since = "1.0.0"; weight = 1250 };
  { key = "enchant.slot.lazy_0115";                      label = "strict_shulker_115";          arity = 2; tags = ["cached"]; since = "1.6.0"; weight = 543 };
  { key = "team.slot.canonical_0116";                    label = "primary_enchant_116";         arity = 5; tags = ["sync"; "async"]; since = "1.7.0"; weight = 2804 };
  { key = "compass.slot.secondary_0117";                 label = "hidden_shield_117";           arity = 7; tags = ["packet"; "experimental"; "codegen"]; since = "1.0.0"; weight = 1643 };
  { key = "grindstone.slot.eager_0118";                  label = "scoped_target_118";           arity = 3; tags = ["compat"]; since = "1.5.2"; weight = 630 };
  { key = "smoker.slot.global_0119";                     label = "fallback_barrel_119";         arity = 6; tags = ["compat"]; since = "1.0.0"; weight = 626 };
  { key = "bossbar.slot.provisional_0120";               label = "eager_repeater_120";          arity = 3; tags = ["async"; "hot"]; since = "1.3.1"; weight = 2436 };
  { key = "furnace.slot.cached_0121";                    label = "modern_dispenser_121";        arity = 2; tags = ["async"]; since = "1.7.0"; weight = 2631 };
  { key = "smoker.slot.lazy_0122";                       label = "provisional_crossbow_122";    arity = 3; tags = ["registry"]; since = "1.6.0"; weight = 3103 };
  { key = "smoker.slot.fallback_0123";                   label = "stable_team_123";             arity = 1; tags = ["check"; "content"; "cached"]; since = "1.7.0"; weight = 4053 };
  { key = "smoker.slot.provisional_0124";                label = "local_tablist_124";           arity = 4; tags = ["compat"]; since = "1.4.0"; weight = 1053 };
  { key = "spawner.slot.primary_0125";                   label = "provisional_stonecutter_125"; arity = 7; tags = ["lower"; "legacy"]; since = "1.5.2"; weight = 339 };
  { key = "world.slot.provisional_0126";                 label = "lazy_composter_126";          arity = 0; tags = ["hot"; "packet"]; since = "1.6.0"; weight = 424 };
  { key = "chunk.slot.eager_0127";                       label = "stable_sound_127";            arity = 4; tags = ["experimental"]; since = "1.5.2"; weight = 981 };
  { key = "inventory.slot.fallback_0128";                label = "legacy_cartography_128";      arity = 5; tags = ["compat"; "hot"]; since = "1.7.0"; weight = 257 };
  { key = "scoreboard.slot.public_0129";                 label = "scoped_elytra_129";           arity = 5; tags = ["core"; "hot"]; since = "1.9.0"; weight = 1980 };
  { key = "banner_pattern.slot.loose_0130";              label = "lazy_smoker_130";             arity = 7; tags = ["legacy"; "compat"; "async"]; since = "1.5.2"; weight = 296 };
  { key = "comparator.slot.eager_0131";                  label = "stable_hologram_131";         arity = 1; tags = ["packet"; "compat"; "hot"]; since = "1.7.0"; weight = 3936 };
  { key = "inventory.slot.canonical_0132";               label = "eager_stonecutter_132";       arity = 0; tags = ["runtime"; "codegen"; "lower"]; since = "1.6.0"; weight = 1471 };
  { key = "particle.slot.provisional_0133";              label = "global_hopper_133";           arity = 4; tags = ["content"; "registry"; "packet"]; since = "1.9.0"; weight = 2855 };
  { key = "trident.slot.secondary_0134";                 label = "eager_observer_134";          arity = 2; tags = ["lower"]; since = "1.2.0"; weight = 3493 };
  { key = "loom.slot.local_0135";                        label = "fallback_entity_135";         arity = 4; tags = ["experimental"; "cached"; "compat"]; since = "1.0.0"; weight = 1124 };
  { key = "enchant.slot.loose_0136";                     label = "stable_anvil_136";            arity = 7; tags = ["cached"]; since = "1.5.2"; weight = 3764 };
  { key = "minecart.slot.stable_0137";                   label = "local_beacon_137";            arity = 5; tags = ["content"; "registry"; "runtime"]; since = "1.5.2"; weight = 3833 };
  { key = "region.slot.hidden_0138";                     label = "scoped_smithing_138";         arity = 2; tags = ["packet"; "emit"]; since = "1.0.0"; weight = 1073 };
  { key = "player.slot.cached_0139";                     label = "provisional_dropper_139";     arity = 7; tags = ["runtime"; "typed"; "sync"]; since = "1.7.0"; weight = 2815 };
  { key = "villager.slot.secondary_0140";                label = "legacy_enchant_140";          arity = 0; tags = ["cold"; "packet"; "parse"]; since = "1.4.0"; weight = 1651 };
  { key = "minecart.slot.loose_0141";                    label = "loose_bell_141";              arity = 1; tags = ["typed"; "hot"; "core"]; since = "1.4.0"; weight = 1547 };
  { key = "trident.slot.derived_0142";                   label = "eager_spawner_142";           arity = 0; tags = ["cached"; "async"]; since = "1.4.0"; weight = 1835 };
  { key = "objective.slot.fallback_0143";                label = "legacy_objective_143";        arity = 7; tags = ["emit"]; since = "1.0.0"; weight = 2829 };
  { key = "observer.slot.stable_0144";                   label = "primary_gui_144";             arity = 3; tags = ["parse"; "cold"; "sync"]; since = "1.5.2"; weight = 2365 };
  { key = "cartography.slot.cached_0145";                label = "eager_campfire_145";          arity = 0; tags = ["async"; "experimental"; "runtime"]; since = "1.5.2"; weight = 2738 };
  { key = "spawner.slot.cached_0146";                    label = "provisional_piston_146";      arity = 6; tags = ["check"; "core"]; since = "1.3.1"; weight = 2540 };
  { key = "stonecutter.slot.hidden_0147";                label = "legacy_sound_147";            arity = 1; tags = ["hot"; "packet"]; since = "1.7.0"; weight = 3511 };
  { key = "potion.slot.legacy_0148";                     label = "cached_dropper_148";          arity = 6; tags = ["hot"; "emit"]; since = "1.7.0"; weight = 891 };
  { key = "conduit.slot.derived_0149";                   label = "hidden_biome_149";            arity = 7; tags = ["async"; "runtime"]; since = "1.2.0"; weight = 152 };
  { key = "piston.slot.scoped_0150";                     label = "modern_stonecutter_150";      arity = 0; tags = ["hot"; "parse"]; since = "1.2.0"; weight = 2082 };
  { key = "particle.slot.hidden_0151";                   label = "hidden_arrow_151";            arity = 0; tags = ["content"; "untyped"]; since = "1.7.0"; weight = 338 };
  { key = "potion.slot.strict_0152";                     label = "cached_rail_152";             arity = 0; tags = ["hot"]; since = "1.9.0"; weight = 2564 };
  { key = "conduit.slot.local_0153";                     label = "fallback_trade_153";          arity = 4; tags = ["legacy"]; since = "1.8.3"; weight = 256 };
  { key = "gui.slot.scoped_0154";                        label = "eager_anvil_154";             arity = 5; tags = ["codegen"]; since = "1.8.3"; weight = 2498 };
  { key = "map.slot.global_0155";                        label = "internal_tablist_155";        arity = 6; tags = ["experimental"; "parse"]; since = "1.9.0"; weight = 139 };
  { key = "banner.slot.strict_0156";                     label = "local_minecart_156";          arity = 4; tags = ["runtime"; "legacy"; "sync"]; since = "1.9.0"; weight = 4035 };
  { key = "structure.slot.secondary_0157";               label = "secondary_elytra_157";        arity = 7; tags = ["compat"; "check"]; since = "1.7.0"; weight = 3462 };
  { key = "block.slot.fallback_0158";                    label = "hidden_enchant_158";          arity = 5; tags = ["cold"]; since = "1.4.0"; weight = 3828 };
  { key = "firework.slot.provisional_0159";              label = "internal_anvil_159";          arity = 4; tags = ["registry"; "hot"; "typed"]; since = "1.7.0"; weight = 447 };
  { key = "arrow.slot.strict_0160";                      label = "eager_loom_160";              arity = 1; tags = ["packet"; "parse"; "legacy"]; since = "1.0.0"; weight = 2515 };
  { key = "mob.slot.secondary_0161";                     label = "loose_bossbar_161";           arity = 3; tags = ["untyped"; "runtime"]; since = "1.2.0"; weight = 1475 };
  { key = "sound.slot.derived_0162";                     label = "modern_npc_162";              arity = 7; tags = ["content"; "codegen"]; since = "1.8.3"; weight = 636 };
  { key = "villager.slot.eager_0163";                    label = "loose_team_163";              arity = 7; tags = ["runtime"; "compat"]; since = "1.2.0"; weight = 3909 };
  { key = "barrel.slot.derived_0164";                    label = "eager_entity_164";            arity = 7; tags = ["legacy"; "content"]; since = "1.8.3"; weight = 3267 };
  { key = "villager.slot.global_0165";                   label = "primary_hologram_165";        arity = 2; tags = ["registry"; "compat"; "packet"]; since = "1.3.1"; weight = 2214 };
  { key = "shield.slot.global_0166";                     label = "cached_barrel_166";           arity = 1; tags = ["registry"; "core"]; since = "1.4.0"; weight = 742 };
  { key = "advancement.slot.modern_0167";                label = "local_item_167";              arity = 6; tags = ["core"; "async"]; since = "1.5.2"; weight = 1760 };
  { key = "smithing.slot.primary_0168";                  label = "primary_attribute_168";       arity = 0; tags = ["check"]; since = "1.4.0"; weight = 2741 };
  { key = "trade.slot.hidden_0169";                      label = "lazy_particle_169";           arity = 1; tags = ["hot"; "experimental"]; since = "1.7.0"; weight = 1940 };
  { key = "scoreboard.slot.scoped_0170";                 label = "scoped_clock_170";            arity = 1; tags = ["registry"]; since = "1.2.0"; weight = 3992 };
  { key = "loom.slot.global_0171";                       label = "modern_banner_171";           arity = 6; tags = ["sync"; "async"]; since = "1.9.0"; weight = 1498 };
  { key = "recipe.slot.modern_0172";                     label = "public_anvil_172";            arity = 6; tags = ["runtime"; "legacy"; "sync"]; since = "1.3.1"; weight = 1117 };
  { key = "lectern.slot.secondary_0173";                 label = "internal_lectern_173";        arity = 3; tags = ["typed"; "registry"]; since = "1.3.1"; weight = 3598 };
  { key = "piston.slot.local_0174";                      label = "fallback_banner_pattern_174"; arity = 7; tags = ["content"; "untyped"]; since = "1.7.0"; weight = 2308 };
  { key = "stonecutter.slot.provisional_0175";           label = "primary_campfire_175";        arity = 2; tags = ["sync"; "registry"; "lower"]; since = "1.5.2"; weight = 1990 };
  { key = "observer.slot.primary_0176";                  label = "internal_effect_176";         arity = 5; tags = ["cold"; "cached"; "parse"]; since = "1.0.0"; weight = 3118 };
  { key = "barrel.slot.hidden_0177";                     label = "canonical_world_177";         arity = 3; tags = ["async"]; since = "1.3.1"; weight = 1940 };
  { key = "dropper.slot.modern_0178";                    label = "eager_dispenser_178";         arity = 3; tags = ["registry"; "typed"]; since = "1.3.1"; weight = 376 };
  { key = "chunk.slot.provisional_0179";                 label = "provisional_grindstone_179";  arity = 5; tags = ["content"; "lower"]; since = "1.8.3"; weight = 1888 };
  { key = "crossbow.slot.lazy_0180";                     label = "stable_stonecutter_180";      arity = 4; tags = ["packet"; "lower"]; since = "1.6.0"; weight = 64 };
  { key = "trade.slot.modern_0181";                      label = "eager_pane_181";              arity = 7; tags = ["legacy"; "cold"]; since = "1.7.0"; weight = 2547 };
  { key = "particle.slot.fallback_0182";                 label = "scoped_block_182";            arity = 6; tags = ["sync"]; since = "1.8.3"; weight = 299 };
  { key = "enchant.slot.hidden_0183";                    label = "cached_chunk_183";            arity = 2; tags = ["registry"; "runtime"; "untyped"]; since = "1.6.0"; weight = 3188 };
  { key = "dropper.slot.primary_0184";                   label = "stable_compass_184";          arity = 6; tags = ["content"]; since = "1.5.2"; weight = 3135 };
  { key = "cartography.slot.primary_0185";               label = "local_repeater_185";          arity = 5; tags = ["core"; "legacy"; "lower"]; since = "1.7.0"; weight = 2005 };
  { key = "piston.slot.lazy_0186";                       label = "eager_gui_186";               arity = 4; tags = ["parse"; "codegen"]; since = "1.9.0"; weight = 4018 };
  { key = "dispenser.slot.secondary_0187";               label = "eager_banner_187";            arity = 2; tags = ["legacy"]; since = "1.4.0"; weight = 3413 };
  { key = "anvil.slot.loose_0188";                       label = "loose_loom_188";              arity = 2; tags = ["lower"; "parse"; "cold"]; since = "1.9.0"; weight = 3925 };
  { key = "player.slot.local_0189";                      label = "modern_firework_189";         arity = 5; tags = ["packet"; "cold"]; since = "1.2.0"; weight = 3800 };
  { key = "minecart.slot.hidden_0190";                   label = "legacy_potion_190";           arity = 4; tags = ["compat"; "packet"]; since = "1.0.0"; weight = 1823 };
  { key = "composter.slot.secondary_0191";               label = "stable_hopper_191";           arity = 5; tags = ["untyped"; "typed"]; since = "1.5.2"; weight = 2611 };
  { key = "potion.slot.legacy_0192";                     label = "strict_dropper_192";          arity = 4; tags = ["core"]; since = "1.3.1"; weight = 1010 };
  { key = "tablist.slot.eager_0193";                     label = "secondary_lectern_193";       arity = 3; tags = ["runtime"]; since = "1.2.0"; weight = 1449 };
  { key = "grindstone.slot.lazy_0194";                   label = "eager_portal_194";            arity = 1; tags = ["codegen"; "parse"]; since = "1.5.2"; weight = 2326 };
  { key = "enchant.slot.cached_0195";                    label = "fallback_entity_195";         arity = 3; tags = ["async"; "parse"]; since = "1.8.3"; weight = 1616 };
  { key = "barrel.slot.canonical_0196";                  label = "lazy_brewing_196";            arity = 4; tags = ["legacy"; "experimental"]; since = "1.9.0"; weight = 3339 };
  { key = "cartography.slot.strict_0197";                label = "secondary_beacon_197";        arity = 2; tags = ["untyped"; "packet"]; since = "1.9.0"; weight = 2400 };
  { key = "inventory.slot.public_0198";                  label = "local_compass_198";           arity = 2; tags = ["emit"; "sync"; "runtime"]; since = "1.9.0"; weight = 2317 };
  { key = "banner_pattern.slot.global_0199";             label = "internal_banner_199";         arity = 5; tags = ["packet"]; since = "1.3.1"; weight = 2357 };
  { key = "beacon.slot.stable_0200";                     label = "hidden_trident_200";          arity = 3; tags = ["check"]; since = "1.6.0"; weight = 2557 };
  { key = "map.slot.eager_0201";                         label = "hidden_item_201";             arity = 3; tags = ["packet"; "emit"]; since = "1.5.2"; weight = 4059 };
  { key = "grindstone.slot.global_0202";                 label = "cached_shulker_202";          arity = 4; tags = ["emit"; "untyped"]; since = "1.8.3"; weight = 704 };
  { key = "team.slot.loose_0203";                        label = "fallback_hologram_203";       arity = 1; tags = ["cached"; "legacy"]; since = "1.8.3"; weight = 3225 };
  { key = "spawner.slot.provisional_0204";               label = "global_elytra_204";           arity = 7; tags = ["packet"; "cold"; "compat"]; since = "1.7.0"; weight = 2680 };
  { key = "biome.slot.legacy_0205";                      label = "provisional_player_205";      arity = 7; tags = ["legacy"]; since = "1.2.0"; weight = 2184 };
  { key = "npc.slot.local_0206";                         label = "local_lectern_206";           arity = 3; tags = ["cached"]; since = "1.2.0"; weight = 2419 };
  { key = "chunk.slot.secondary_0207";                   label = "internal_map_207";            arity = 1; tags = ["registry"; "sync"; "legacy"]; since = "1.9.0"; weight = 1939 };
  { key = "firework.slot.scoped_0208";                   label = "public_world_208";            arity = 5; tags = ["registry"; "emit"]; since = "1.8.3"; weight = 3303 };
  { key = "arrow.slot.secondary_0209";                   label = "lazy_attribute_209";          arity = 6; tags = ["packet"; "emit"; "hot"]; since = "1.7.0"; weight = 947 };
  { key = "spawner.slot.legacy_0210";                    label = "scoped_potion_210";           arity = 2; tags = ["hot"; "experimental"]; since = "1.5.2"; weight = 3574 };
  { key = "smoker.slot.global_0211";                     label = "lazy_mob_211";                arity = 2; tags = ["registry"; "emit"]; since = "1.4.0"; weight = 3189 };
  { key = "grindstone.slot.hidden_0212";                 label = "modern_hologram_212";         arity = 0; tags = ["packet"]; since = "1.7.0"; weight = 1237 };
  { key = "enchant.slot.canonical_0213";                 label = "global_brewing_213";          arity = 4; tags = ["experimental"]; since = "1.6.0"; weight = 3547 };
  { key = "smithing.slot.loose_0214";                    label = "hidden_comparator_214";       arity = 0; tags = ["compat"]; since = "1.0.0"; weight = 1480 };
  { key = "smoker.slot.derived_0215";                    label = "canonical_brewing_215";       arity = 5; tags = ["typed"]; since = "1.4.0"; weight = 3681 };
  { key = "objective.slot.provisional_0216";             label = "primary_comparator_216";      arity = 1; tags = ["async"; "check"; "cached"]; since = "1.6.0"; weight = 1620 };
  { key = "beacon.slot.strict_0217";                     label = "scoped_scoreboard_217";       arity = 6; tags = ["runtime"]; since = "1.2.0"; weight = 912 };
  { key = "inventory.slot.derived_0218";                 label = "provisional_particle_218";    arity = 2; tags = ["hot"]; since = "1.2.0"; weight = 1845 };
  { key = "banner.slot.strict_0219";                     label = "legacy_furnace_219";          arity = 4; tags = ["typed"]; since = "1.4.0"; weight = 2590 };
  { key = "mob.slot.modern_0220";                        label = "strict_crossbow_220";         arity = 5; tags = ["cached"; "typed"]; since = "1.6.0"; weight = 1716 };
  { key = "enchant.slot.legacy_0221";                    label = "secondary_advancement_221";   arity = 4; tags = ["experimental"]; since = "1.3.1"; weight = 2303 };
  { key = "slot.slot.local_0222";                        label = "scoped_shulker_222";          arity = 4; tags = ["lower"]; since = "1.7.0"; weight = 837 };
  { key = "brewing.slot.local_0223";                     label = "modern_scoreboard_223";       arity = 6; tags = ["runtime"]; since = "1.8.3"; weight = 3752 };
  { key = "campfire.slot.legacy_0224";                   label = "public_loom_224";             arity = 7; tags = ["packet"]; since = "1.7.0"; weight = 1933 };
  { key = "tablist.slot.cached_0225";                    label = "provisional_beacon_225";      arity = 1; tags = ["experimental"]; since = "1.0.0"; weight = 1244 };
  { key = "piston.slot.hidden_0226";                     label = "loose_world_226";             arity = 1; tags = ["content"]; since = "1.6.0"; weight = 2012 };
  { key = "hologram.slot.primary_0227";                  label = "fallback_advancement_227";    arity = 5; tags = ["legacy"; "cold"]; since = "1.8.3"; weight = 3097 };
  { key = "enchant.slot.fallback_0228";                  label = "eager_gui_228";               arity = 4; tags = ["compat"; "typed"; "hot"]; since = "1.7.0"; weight = 277 };
  { key = "shield.slot.derived_0229";                    label = "hidden_banner_pattern_229";   arity = 4; tags = ["legacy"; "compat"]; since = "1.5.2"; weight = 1362 };
  { key = "trident.slot.fallback_0230";                  label = "internal_inventory_230";      arity = 3; tags = ["emit"; "sync"]; since = "1.0.0"; weight = 1943 };
  { key = "shulker.slot.modern_0231";                    label = "provisional_particle_231";    arity = 7; tags = ["codegen"]; since = "1.8.3"; weight = 608 };
  { key = "comparator.slot.eager_0232";                  label = "derived_crossbow_232";        arity = 0; tags = ["hot"; "packet"]; since = "1.6.0"; weight = 1790 };
  { key = "trident.slot.local_0233";                     label = "fallback_furnace_233";        arity = 2; tags = ["hot"; "parse"; "cached"]; since = "1.6.0"; weight = 1216 };
  { key = "portal.slot.secondary_0234";                  label = "hidden_region_234";           arity = 0; tags = ["lower"]; since = "1.0.0"; weight = 353 };
  { key = "entity.slot.secondary_0235";                  label = "hidden_hologram_235";         arity = 7; tags = ["compat"; "untyped"]; since = "1.6.0"; weight = 1352 };
  { key = "rail.slot.public_0236";                       label = "modern_conduit_236";          arity = 0; tags = ["async"; "cached"]; since = "1.4.0"; weight = 2971 };
  { key = "spawner.slot.lazy_0237";                      label = "secondary_cartography_237";   arity = 4; tags = ["parse"; "compat"]; since = "1.4.0"; weight = 1229 };
  { key = "shield.slot.public_0238";                     label = "fallback_biome_238";          arity = 4; tags = ["untyped"; "content"]; since = "1.4.0"; weight = 2862 };
  { key = "tablist.slot.eager_0239";                     label = "internal_elytra_239";         arity = 5; tags = ["packet"]; since = "1.0.0"; weight = 2242 };
  { key = "boat.slot.legacy_0240";                       label = "hidden_crossbow_240";         arity = 2; tags = ["check"; "legacy"; "hot"]; since = "1.5.2"; weight = 3892 };
  { key = "shield.slot.global_0241";                     label = "eager_pane_241";              arity = 6; tags = ["compat"]; since = "1.2.0"; weight = 3844 };
  { key = "particle.slot.eager_0242";                    label = "public_repeater_242";         arity = 2; tags = ["cached"]; since = "1.9.0"; weight = 3048 };
  { key = "advancement.slot.canonical_0243";             label = "primary_slot_243";            arity = 5; tags = ["cached"; "experimental"]; since = "1.8.3"; weight = 3376 };
  { key = "tablist.slot.loose_0244";                     label = "secondary_map_244";           arity = 2; tags = ["hot"; "parse"]; since = "1.4.0"; weight = 3867 };
  { key = "target.slot.public_0245";                     label = "cached_slot_245";             arity = 5; tags = ["lower"]; since = "1.0.0"; weight = 3629 };
  { key = "spawner.slot.global_0246";                    label = "local_map_246";               arity = 0; tags = ["async"; "parse"]; since = "1.9.0"; weight = 4078 };
  { key = "world.slot.provisional_0247";                 label = "canonical_repeater_247";      arity = 4; tags = ["lower"]; since = "1.7.0"; weight = 1574 };
  { key = "potion.slot.fallback_0248";                   label = "global_scoreboard_248";       arity = 5; tags = ["cold"; "core"; "lower"]; since = "1.3.1"; weight = 2912 };
  { key = "bell.slot.public_0249";                       label = "local_banner_pattern_249";    arity = 2; tags = ["codegen"; "lower"; "check"]; since = "1.9.0"; weight = 1361 };
  { key = "trident.slot.stable_0250";                    label = "modern_region_250";           arity = 6; tags = ["packet"; "check"; "cold"]; since = "1.3.1"; weight = 763 };
  { key = "conduit.slot.strict_0251";                    label = "derived_composter_251";       arity = 6; tags = ["legacy"]; since = "1.3.1"; weight = 988 };
  { key = "piston.slot.modern_0252";                     label = "provisional_dispenser_252";   arity = 7; tags = ["runtime"; "emit"]; since = "1.7.0"; weight = 3141 };
  { key = "grindstone.slot.canonical_0253";              label = "stable_beacon_253";           arity = 4; tags = ["experimental"]; since = "1.9.0"; weight = 842 };
  { key = "scoreboard.slot.public_0254";                 label = "local_cartography_254";       arity = 0; tags = ["codegen"]; since = "1.8.3"; weight = 613 };
  { key = "firework.slot.modern_0255";                   label = "hidden_trident_255";          arity = 6; tags = ["emit"; "compat"]; since = "1.2.0"; weight = 2260 };
  { key = "target.slot.local_0256";                      label = "derived_tablist_256";         arity = 5; tags = ["runtime"; "cached"]; since = "1.8.3"; weight = 765 };
  { key = "effect.slot.scoped_0257";                     label = "derived_dropper_257";         arity = 7; tags = ["content"; "check"; "hot"]; since = "1.6.0"; weight = 1556 };
  { key = "biome.slot.provisional_0258";                 label = "strict_dispenser_258";        arity = 0; tags = ["lower"; "core"]; since = "1.4.0"; weight = 3689 };
  { key = "composter.slot.modern_0259";                  label = "local_anvil_259";             arity = 6; tags = ["content"; "hot"]; since = "1.4.0"; weight = 3928 };
  { key = "npc.slot.strict_0260";                        label = "canonical_bundle_260";        arity = 6; tags = ["sync"; "runtime"; "typed"]; since = "1.7.0"; weight = 2657 };
  { key = "furnace.slot.fallback_0261";                  label = "modern_boat_261";             arity = 1; tags = ["emit"; "content"]; since = "1.7.0"; weight = 600 };
  { key = "spawner.slot.stable_0262";                    label = "scoped_stonecutter_262";      arity = 7; tags = ["async"; "compat"]; since = "1.0.0"; weight = 2186 };
  { key = "brewing.slot.secondary_0263";                 label = "legacy_cartography_263";      arity = 3; tags = ["codegen"; "registry"]; since = "1.5.2"; weight = 4030 };
  { key = "elytra.slot.fallback_0264";                   label = "legacy_repeater_264";         arity = 5; tags = ["runtime"; "experimental"; "cached"]; since = "1.4.0"; weight = 2466 };
  { key = "trade.slot.internal_0265";                    label = "internal_anvil_265";          arity = 0; tags = ["lower"; "compat"; "packet"]; since = "1.8.3"; weight = 1042 };
  { key = "world.slot.primary_0266";                     label = "strict_crossbow_266";         arity = 0; tags = ["registry"; "runtime"; "check"]; since = "1.0.0"; weight = 2348 };
  { key = "loom.slot.modern_0267";                       label = "canonical_shulker_267";       arity = 4; tags = ["cached"; "packet"; "legacy"]; since = "1.7.0"; weight = 1339 };
  { key = "recipe.slot.modern_0268";                     label = "modern_cartography_268";      arity = 2; tags = ["hot"; "legacy"; "experimental"]; since = "1.4.0"; weight = 308 };
  { key = "attribute.slot.fallback_0269";                label = "canonical_elytra_269";        arity = 3; tags = ["emit"; "compat"; "cold"]; since = "1.3.1"; weight = 3627 };
  { key = "repeater.slot.fallback_0270";                 label = "cached_attribute_270";        arity = 4; tags = ["codegen"]; since = "1.9.0"; weight = 2482 };
  { key = "bossbar.slot.derived_0271";                   label = "public_particle_271";         arity = 6; tags = ["emit"; "untyped"]; since = "1.9.0"; weight = 3690 };
  { key = "bundle.slot.modern_0272";                     label = "eager_elytra_272";            arity = 3; tags = ["registry"; "untyped"]; since = "1.2.0"; weight = 2386 };
  { key = "portal.slot.global_0273";                     label = "global_villager_273";         arity = 5; tags = ["lower"; "core"; "typed"]; since = "1.4.0"; weight = 656 };
]

let count = List.length entries

let table : (string, slot_entry) Hashtbl.t =
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
