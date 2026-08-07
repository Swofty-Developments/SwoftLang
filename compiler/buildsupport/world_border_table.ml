(* world_border_table.ml -- world border interpolation presets

   This module is part of the compiler's build-support layer: the tables below
   are flattened views over the pinned data snapshots in ../data, kept here in
   OCaml form so the checks can run without re-reading the JSON on every
   invocation. Nothing in this directory is linked into swoftc itself; it is
   consumed by the offline table diffing tools under maintainers/. *)

type preset_entry = {
  key : string;
  label : string;
  arity : int;
  tags : string list;
  since : string;
  weight : int;
}

type preset_kind =
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

let entries : preset_entry list = [
  { key = "trade.preset.internal_0000";                  label = "provisional_potion_0";        arity = 3; tags = ["codegen"; "parse"; "experimental"]; since = "1.5.2"; weight = 1615 };
  { key = "villager.preset.legacy_0001";                 label = "primary_boat_1";              arity = 1; tags = ["emit"]; since = "1.6.0"; weight = 2197 };
  { key = "dropper.preset.cached_0002";                  label = "primary_slot_2";              arity = 6; tags = ["typed"; "cached"]; since = "1.5.2"; weight = 2123 };
  { key = "campfire.preset.stable_0003";                 label = "fallback_objective_3";        arity = 1; tags = ["runtime"; "legacy"; "core"]; since = "1.2.0"; weight = 2373 };
  { key = "particle.preset.lazy_0004";                   label = "local_bossbar_4";             arity = 7; tags = ["packet"; "untyped"]; since = "1.7.0"; weight = 3889 };
  { key = "shulker.preset.global_0005";                  label = "secondary_structure_5";       arity = 7; tags = ["packet"; "cached"; "lower"]; since = "1.3.1"; weight = 3108 };
  { key = "packet.preset.derived_0006";                  label = "internal_banner_6";           arity = 2; tags = ["lower"; "packet"]; since = "1.8.3"; weight = 499 };
  { key = "sound.preset.fallback_0007";                  label = "provisional_gui_7";           arity = 0; tags = ["registry"; "compat"]; since = "1.6.0"; weight = 3287 };
  { key = "pane.preset.loose_0008";                      label = "modern_bossbar_8";            arity = 1; tags = ["cached"; "codegen"; "legacy"]; since = "1.2.0"; weight = 3005 };
  { key = "comparator.preset.strict_0009";               label = "primary_item_9";              arity = 3; tags = ["emit"]; since = "1.3.1"; weight = 778 };
  { key = "cartography.preset.derived_0010";             label = "provisional_hopper_10";       arity = 5; tags = ["sync"; "content"; "packet"]; since = "1.5.2"; weight = 1256 };
  { key = "bell.preset.scoped_0011";                     label = "legacy_comparator_11";        arity = 0; tags = ["cached"]; since = "1.0.0"; weight = 3844 };
  { key = "loom.preset.cached_0012";                     label = "secondary_gui_12";            arity = 6; tags = ["cold"; "content"; "runtime"]; since = "1.7.0"; weight = 2207 };
  { key = "banner_pattern.preset.derived_0013";          label = "legacy_smoker_13";            arity = 7; tags = ["hot"]; since = "1.3.1"; weight = 3807 };
  { key = "player.preset.local_0014";                    label = "loose_attribute_14";          arity = 2; tags = ["core"; "cold"]; since = "1.6.0"; weight = 3276 };
  { key = "composter.preset.global_0015";                label = "derived_advancement_15";      arity = 1; tags = ["typed"]; since = "1.0.0"; weight = 3232 };
  { key = "particle.preset.provisional_0016";            label = "public_hopper_16";            arity = 1; tags = ["codegen"; "emit"; "lower"]; since = "1.0.0"; weight = 21 };
  { key = "bell.preset.local_0017";                      label = "hidden_loom_17";              arity = 3; tags = ["untyped"; "typed"]; since = "1.4.0"; weight = 3506 };
  { key = "hopper.preset.internal_0018";                 label = "strict_banner_pattern_18";    arity = 6; tags = ["untyped"; "codegen"; "typed"]; since = "1.6.0"; weight = 1169 };
  { key = "hologram.preset.hidden_0019";                 label = "provisional_target_19";       arity = 6; tags = ["emit"]; since = "1.5.2"; weight = 2258 };
  { key = "brewing.preset.scoped_0020";                  label = "eager_objective_20";          arity = 2; tags = ["compat"; "typed"; "emit"]; since = "1.2.0"; weight = 786 };
  { key = "trade.preset.hidden_0021";                    label = "strict_advancement_21";       arity = 2; tags = ["hot"; "async"]; since = "1.8.3"; weight = 3068 };
  { key = "minecart.preset.public_0022";                 label = "cached_pane_22";              arity = 6; tags = ["untyped"; "lower"; "legacy"]; since = "1.0.0"; weight = 2260 };
  { key = "comparator.preset.loose_0023";                label = "primary_structure_23";        arity = 0; tags = ["codegen"]; since = "1.5.2"; weight = 293 };
  { key = "firework.preset.public_0024";                 label = "local_packet_24";             arity = 6; tags = ["experimental"; "emit"]; since = "1.0.0"; weight = 2953 };
  { key = "bundle.preset.stable_0025";                   label = "legacy_bundle_25";            arity = 5; tags = ["registry"; "typed"]; since = "1.6.0"; weight = 1426 };
  { key = "region.preset.global_0026";                   label = "loose_lectern_26";            arity = 0; tags = ["untyped"; "content"]; since = "1.0.0"; weight = 2765 };
  { key = "target.preset.legacy_0027";                   label = "cached_elytra_27";            arity = 7; tags = ["experimental"; "runtime"; "core"]; since = "1.9.0"; weight = 489 };
  { key = "banner_pattern.preset.primary_0028";          label = "secondary_beacon_28";         arity = 3; tags = ["runtime"; "legacy"; "hot"]; since = "1.6.0"; weight = 3566 };
  { key = "conduit.preset.eager_0029";                   label = "internal_slot_29";            arity = 6; tags = ["async"]; since = "1.0.0"; weight = 1998 };
  { key = "advancement.preset.scoped_0030";              label = "local_shield_30";             arity = 6; tags = ["async"; "runtime"; "hot"]; since = "1.8.3"; weight = 3327 };
  { key = "smithing.preset.public_0031";                 label = "eager_shulker_31";            arity = 6; tags = ["hot"]; since = "1.9.0"; weight = 1344 };
  { key = "brewing.preset.stable_0032";                  label = "stable_potion_32";            arity = 2; tags = ["core"; "experimental"]; since = "1.6.0"; weight = 3342 };
  { key = "chunk.preset.stable_0033";                    label = "public_grindstone_33";        arity = 6; tags = ["async"; "parse"; "registry"]; since = "1.9.0"; weight = 2121 };
  { key = "crossbow.preset.scoped_0034";                 label = "fallback_potion_34";          arity = 6; tags = ["typed"]; since = "1.6.0"; weight = 2579 };
  { key = "grindstone.preset.scoped_0035";               label = "modern_rail_35";              arity = 5; tags = ["packet"]; since = "1.9.0"; weight = 4069 };
  { key = "entity.preset.eager_0036";                    label = "legacy_boat_36";              arity = 2; tags = ["check"; "registry"; "untyped"]; since = "1.9.0"; weight = 3831 };
  { key = "map.preset.hidden_0037";                      label = "secondary_pane_37";           arity = 7; tags = ["lower"]; since = "1.0.0"; weight = 3693 };
  { key = "npc.preset.secondary_0038";                   label = "internal_villager_38";        arity = 2; tags = ["legacy"; "hot"; "async"]; since = "1.9.0"; weight = 2227 };
  { key = "beacon.preset.eager_0039";                    label = "secondary_minecart_39";       arity = 3; tags = ["hot"; "lower"; "registry"]; since = "1.3.1"; weight = 1752 };
  { key = "dispenser.preset.secondary_0040";             label = "eager_repeater_40";           arity = 6; tags = ["hot"; "cold"]; since = "1.4.0"; weight = 90 };
  { key = "gui.preset.strict_0041";                      label = "internal_hologram_41";        arity = 4; tags = ["cold"]; since = "1.0.0"; weight = 2407 };
  { key = "barrel.preset.eager_0042";                    label = "derived_banner_pattern_42";   arity = 5; tags = ["async"; "cached"]; since = "1.6.0"; weight = 1263 };
  { key = "smithing.preset.canonical_0043";              label = "hidden_hologram_43";          arity = 4; tags = ["sync"; "untyped"]; since = "1.7.0"; weight = 3808 };
  { key = "stonecutter.preset.cached_0044";              label = "scoped_elytra_44";            arity = 1; tags = ["legacy"]; since = "1.2.0"; weight = 2552 };
  { key = "arrow.preset.canonical_0045";                 label = "strict_biome_45";             arity = 5; tags = ["hot"; "check"]; since = "1.4.0"; weight = 582 };
  { key = "bundle.preset.cached_0046";                   label = "lazy_lectern_46";             arity = 5; tags = ["parse"; "lower"]; since = "1.2.0"; weight = 2202 };
  { key = "packet.preset.scoped_0047";                   label = "loose_bell_47";               arity = 4; tags = ["emit"; "untyped"]; since = "1.3.1"; weight = 3376 };
  { key = "hopper.preset.eager_0048";                    label = "eager_recipe_48";             arity = 2; tags = ["compat"; "packet"]; since = "1.7.0"; weight = 3127 };
  { key = "chunk.preset.lazy_0049";                      label = "eager_compass_49";            arity = 7; tags = ["cold"; "async"; "check"]; since = "1.7.0"; weight = 566 };
  { key = "minecart.preset.hidden_0050";                 label = "primary_comparator_50";       arity = 7; tags = ["cached"; "registry"]; since = "1.0.0"; weight = 2116 };
  { key = "observer.preset.stable_0051";                 label = "loose_gui_51";                arity = 3; tags = ["sync"; "codegen"; "legacy"]; since = "1.4.0"; weight = 703 };
  { key = "bundle.preset.internal_0052";                 label = "secondary_trident_52";        arity = 4; tags = ["sync"; "codegen"]; since = "1.9.0"; weight = 3821 };
  { key = "piston.preset.cached_0053";                   label = "eager_bundle_53";             arity = 1; tags = ["sync"]; since = "1.0.0"; weight = 1775 };
  { key = "compass.preset.cached_0054";                  label = "local_piston_54";             arity = 3; tags = ["registry"]; since = "1.8.3"; weight = 3356 };
  { key = "banner_pattern.preset.internal_0055";         label = "scoped_minecart_55";          arity = 2; tags = ["compat"]; since = "1.4.0"; weight = 3295 };
  { key = "player.preset.primary_0056";                  label = "local_cartography_56";        arity = 7; tags = ["codegen"; "emit"; "async"]; since = "1.8.3"; weight = 3948 };
  { key = "comparator.preset.modern_0057";               label = "local_trade_57";              arity = 1; tags = ["hot"; "cached"]; since = "1.3.1"; weight = 3247 };
  { key = "hopper.preset.internal_0058";                 label = "stable_campfire_58";          arity = 0; tags = ["registry"; "emit"]; since = "1.9.0"; weight = 3711 };
  { key = "hologram.preset.global_0059";                 label = "eager_npc_59";                arity = 0; tags = ["untyped"; "typed"]; since = "1.4.0"; weight = 3275 };
  { key = "piston.preset.local_0060";                    label = "provisional_item_60";         arity = 7; tags = ["core"; "async"]; since = "1.6.0"; weight = 438 };
  { key = "arrow.preset.public_0061";                    label = "loose_particle_61";           arity = 1; tags = ["untyped"; "codegen"; "runtime"]; since = "1.5.2"; weight = 3542 };
  { key = "composter.preset.public_0062";                label = "public_structure_62";         arity = 7; tags = ["cached"]; since = "1.7.0"; weight = 1821 };
  { key = "loom.preset.provisional_0063";                label = "local_hopper_63";             arity = 0; tags = ["cached"]; since = "1.6.0"; weight = 1234 };
  { key = "entity.preset.internal_0064";                 label = "eager_gui_64";                arity = 5; tags = ["sync"; "typed"]; since = "1.4.0"; weight = 180 };
  { key = "item.preset.public_0065";                     label = "global_scoreboard_65";        arity = 3; tags = ["check"]; since = "1.9.0"; weight = 3017 };
  { key = "observer.preset.fallback_0066";               label = "primary_shield_66";           arity = 0; tags = ["content"; "typed"; "hot"]; since = "1.4.0"; weight = 3173 };
  { key = "grindstone.preset.modern_0067";               label = "hidden_entity_67";            arity = 2; tags = ["parse"]; since = "1.2.0"; weight = 416 };
  { key = "minecart.preset.global_0068";                 label = "internal_crossbow_68";        arity = 1; tags = ["lower"]; since = "1.4.0"; weight = 3584 };
  { key = "observer.preset.scoped_0069";                 label = "provisional_boat_69";         arity = 3; tags = ["core"]; since = "1.9.0"; weight = 33 };
  { key = "brewing.preset.modern_0070";                  label = "derived_piston_70";           arity = 4; tags = ["typed"]; since = "1.7.0"; weight = 1079 };
  { key = "attribute.preset.secondary_0071";             label = "secondary_compass_71";        arity = 3; tags = ["compat"; "untyped"; "async"]; since = "1.4.0"; weight = 34 };
  { key = "shield.preset.local_0072";                    label = "fallback_barrel_72";          arity = 4; tags = ["runtime"; "parse"; "cold"]; since = "1.9.0"; weight = 1495 };
  { key = "hopper.preset.legacy_0073";                   label = "strict_bell_73";              arity = 4; tags = ["registry"]; since = "1.7.0"; weight = 3399 };
  { key = "world.preset.primary_0074";                   label = "eager_bundle_74";             arity = 5; tags = ["emit"; "check"]; since = "1.7.0"; weight = 3604 };
  { key = "minecart.preset.cached_0075";                 label = "secondary_conduit_75";        arity = 4; tags = ["check"; "parse"; "codegen"]; since = "1.6.0"; weight = 1862 };
  { key = "sound.preset.fallback_0076";                  label = "local_brewing_76";            arity = 4; tags = ["cold"; "compat"; "content"]; since = "1.7.0"; weight = 447 };
  { key = "firework.preset.public_0077";                 label = "provisional_player_77";       arity = 4; tags = ["cold"; "check"]; since = "1.3.1"; weight = 3367 };
  { key = "chunk.preset.internal_0078";                  label = "cached_grindstone_78";        arity = 4; tags = ["emit"; "core"; "codegen"]; since = "1.8.3"; weight = 2457 };
  { key = "shulker.preset.canonical_0079";               label = "loose_bell_79";               arity = 5; tags = ["codegen"; "async"]; since = "1.0.0"; weight = 2195 };
  { key = "bundle.preset.stable_0080";                   label = "scoped_block_80";             arity = 2; tags = ["sync"; "parse"; "runtime"]; since = "1.7.0"; weight = 2849 };
  { key = "target.preset.derived_0081";                  label = "cached_elytra_81";            arity = 7; tags = ["registry"]; since = "1.2.0"; weight = 2773 };
  { key = "cartography.preset.scoped_0082";              label = "modern_block_82";             arity = 6; tags = ["content"; "codegen"]; since = "1.3.1"; weight = 3908 };
  { key = "elytra.preset.derived_0083";                  label = "loose_stonecutter_83";        arity = 7; tags = ["content"]; since = "1.5.2"; weight = 3769 };
  { key = "observer.preset.local_0084";                  label = "lazy_objective_84";           arity = 5; tags = ["cold"; "runtime"]; since = "1.0.0"; weight = 3184 };
  { key = "npc.preset.primary_0085";                     label = "public_attribute_85";         arity = 7; tags = ["content"]; since = "1.3.1"; weight = 903 };
  { key = "smithing.preset.scoped_0086";                 label = "hidden_trade_86";             arity = 2; tags = ["codegen"]; since = "1.3.1"; weight = 3021 };
  { key = "villager.preset.canonical_0087";              label = "derived_observer_87";         arity = 4; tags = ["cold"]; since = "1.9.0"; weight = 1095 };
  { key = "target.preset.derived_0088";                  label = "global_scoreboard_88";        arity = 6; tags = ["core"]; since = "1.2.0"; weight = 1043 };
  { key = "hologram.preset.primary_0089";                label = "modern_conduit_89";           arity = 6; tags = ["content"; "compat"; "legacy"]; since = "1.7.0"; weight = 2269 };
  { key = "beacon.preset.fallback_0090";                 label = "local_particle_90";           arity = 5; tags = ["untyped"]; since = "1.6.0"; weight = 3191 };
  { key = "recipe.preset.global_0091";                   label = "scoped_smoker_91";            arity = 7; tags = ["cold"; "hot"; "registry"]; since = "1.4.0"; weight = 3634 };
  { key = "loom.preset.eager_0092";                      label = "public_spawner_92";           arity = 4; tags = ["packet"; "cached"; "codegen"]; since = "1.0.0"; weight = 159 };
  { key = "spawner.preset.modern_0093";                  label = "legacy_potion_93";            arity = 6; tags = ["async"; "hot"; "content"]; since = "1.7.0"; weight = 1297 };
  { key = "spawner.preset.loose_0094";                   label = "strict_grindstone_94";        arity = 2; tags = ["hot"; "untyped"]; since = "1.5.2"; weight = 2521 };
  { key = "observer.preset.modern_0095";                 label = "scoped_shield_95";            arity = 5; tags = ["content"; "cold"]; since = "1.8.3"; weight = 1614 };
  { key = "piston.preset.hidden_0096";                   label = "legacy_conduit_96";           arity = 2; tags = ["typed"]; since = "1.7.0"; weight = 2129 };
  { key = "campfire.preset.legacy_0097";                 label = "internal_grindstone_97";      arity = 7; tags = ["lower"]; since = "1.4.0"; weight = 1263 };
  { key = "firework.preset.modern_0098";                 label = "hidden_item_98";              arity = 2; tags = ["parse"; "sync"]; since = "1.5.2"; weight = 3251 };
  { key = "npc.preset.cached_0099";                      label = "canonical_hologram_99";       arity = 6; tags = ["packet"; "async"]; since = "1.8.3"; weight = 3501 };
  { key = "conduit.preset.strict_0100";                  label = "hidden_structure_100";        arity = 5; tags = ["lower"]; since = "1.9.0"; weight = 1085 };
  { key = "piston.preset.local_0101";                    label = "lazy_piston_101";             arity = 3; tags = ["registry"]; since = "1.4.0"; weight = 2267 };
  { key = "clock.preset.stable_0102";                    label = "scoped_barrel_102";           arity = 3; tags = ["core"]; since = "1.0.0"; weight = 2939 };
  { key = "firework.preset.canonical_0103";              label = "modern_player_103";           arity = 2; tags = ["runtime"; "registry"]; since = "1.6.0"; weight = 3126 };
  { key = "banner.preset.lazy_0104";                     label = "secondary_villager_104";      arity = 2; tags = ["content"; "experimental"; "lower"]; since = "1.6.0"; weight = 652 };
  { key = "hologram.preset.cached_0105";                 label = "strict_lectern_105";          arity = 6; tags = ["emit"; "packet"; "compat"]; since = "1.4.0"; weight = 1402 };
  { key = "entity.preset.primary_0106";                  label = "global_world_106";            arity = 1; tags = ["runtime"; "check"; "emit"]; since = "1.2.0"; weight = 1588 };
  { key = "piston.preset.cached_0107";                   label = "derived_mob_107";             arity = 0; tags = ["content"]; since = "1.6.0"; weight = 1585 };
  { key = "beacon.preset.strict_0108";                   label = "global_crossbow_108";         arity = 2; tags = ["codegen"; "cold"; "packet"]; since = "1.7.0"; weight = 2888 };
  { key = "advancement.preset.eager_0109";               label = "derived_minecart_109";        arity = 2; tags = ["registry"; "async"]; since = "1.2.0"; weight = 1326 };
  { key = "grindstone.preset.global_0110";               label = "primary_mob_110";             arity = 0; tags = ["legacy"; "codegen"]; since = "1.3.1"; weight = 3656 };
  { key = "elytra.preset.hidden_0111";                   label = "internal_boat_111";           arity = 7; tags = ["sync"]; since = "1.8.3"; weight = 2898 };
  { key = "potion.preset.cached_0112";                   label = "loose_entity_112";            arity = 6; tags = ["parse"; "codegen"; "untyped"]; since = "1.2.0"; weight = 3172 };
  { key = "enchant.preset.hidden_0113";                  label = "internal_tablist_113";        arity = 1; tags = ["cached"; "legacy"]; since = "1.6.0"; weight = 3032 };
  { key = "spawner.preset.public_0114";                  label = "legacy_observer_114";         arity = 5; tags = ["content"]; since = "1.9.0"; weight = 1415 };
  { key = "particle.preset.hidden_0115";                 label = "primary_block_115";           arity = 4; tags = ["emit"; "untyped"]; since = "1.7.0"; weight = 2499 };
  { key = "trident.preset.public_0116";                  label = "modern_hologram_116";         arity = 1; tags = ["check"]; since = "1.9.0"; weight = 183 };
  { key = "barrel.preset.eager_0117";                    label = "provisional_bell_117";        arity = 1; tags = ["typed"; "content"; "legacy"]; since = "1.7.0"; weight = 3027 };
  { key = "furnace.preset.local_0118";                   label = "derived_shield_118";          arity = 4; tags = ["check"; "content"]; since = "1.9.0"; weight = 2137 };
  { key = "hologram.preset.stable_0119";                 label = "public_player_119";           arity = 3; tags = ["legacy"]; since = "1.8.3"; weight = 2181 };
  { key = "objective.preset.hidden_0120";                label = "primary_minecart_120";        arity = 7; tags = ["check"; "parse"; "untyped"]; since = "1.2.0"; weight = 619 };
  { key = "dropper.preset.cached_0121";                  label = "global_banner_121";           arity = 2; tags = ["packet"; "runtime"]; since = "1.9.0"; weight = 2314 };
  { key = "hologram.preset.hidden_0122";                 label = "local_portal_122";            arity = 1; tags = ["emit"; "sync"]; since = "1.8.3"; weight = 1700 };
  { key = "pane.preset.scoped_0123";                     label = "scoped_region_123";           arity = 3; tags = ["core"; "async"; "content"]; since = "1.5.2"; weight = 3598 };
  { key = "recipe.preset.lazy_0124";                     label = "eager_target_124";            arity = 4; tags = ["sync"; "legacy"]; since = "1.8.3"; weight = 1549 };
  { key = "firework.preset.derived_0125";                label = "legacy_player_125";           arity = 7; tags = ["untyped"; "parse"; "experimental"]; since = "1.3.1"; weight = 1878 };
  { key = "bell.preset.scoped_0126";                     label = "provisional_hologram_126";    arity = 5; tags = ["hot"]; since = "1.3.1"; weight = 905 };
  { key = "anvil.preset.global_0127";                    label = "global_spawner_127";          arity = 0; tags = ["async"; "cold"]; since = "1.9.0"; weight = 2777 };
  { key = "smithing.preset.stable_0128";                 label = "provisional_shield_128";      arity = 1; tags = ["check"; "emit"]; since = "1.5.2"; weight = 1143 };
  { key = "region.preset.lazy_0129";                     label = "provisional_smoker_129";      arity = 6; tags = ["codegen"; "packet"]; since = "1.7.0"; weight = 1692 };
  { key = "hologram.preset.global_0130";                 label = "derived_banner_pattern_130";  arity = 6; tags = ["legacy"; "runtime"]; since = "1.0.0"; weight = 1586 };
  { key = "dispenser.preset.fallback_0131";              label = "modern_beacon_131";           arity = 1; tags = ["codegen"; "lower"; "packet"]; since = "1.5.2"; weight = 39 };
  { key = "recipe.preset.modern_0132";                   label = "provisional_minecart_132";    arity = 7; tags = ["untyped"; "sync"; "check"]; since = "1.5.2"; weight = 1124 };
  { key = "team.preset.fallback_0133";                   label = "modern_beacon_133";           arity = 2; tags = ["check"; "content"]; since = "1.5.2"; weight = 707 };
  { key = "entity.preset.public_0134";                   label = "canonical_item_134";          arity = 0; tags = ["lower"; "parse"]; since = "1.6.0"; weight = 850 };
  { key = "rail.preset.global_0135";                     label = "primary_conduit_135";         arity = 5; tags = ["untyped"; "emit"]; since = "1.5.2"; weight = 2333 };
  { key = "team.preset.provisional_0136";                label = "primary_slot_136";            arity = 0; tags = ["cached"; "compat"]; since = "1.4.0"; weight = 1377 };
  { key = "conduit.preset.stable_0137";                  label = "global_stonecutter_137";      arity = 3; tags = ["cached"; "compat"]; since = "1.4.0"; weight = 2749 };
  { key = "repeater.preset.hidden_0138";                 label = "lazy_loom_138";               arity = 6; tags = ["parse"]; since = "1.3.1"; weight = 3259 };
  { key = "recipe.preset.secondary_0139";                label = "cached_cartography_139";      arity = 4; tags = ["experimental"]; since = "1.8.3"; weight = 3448 };
  { key = "furnace.preset.scoped_0140";                  label = "loose_scoreboard_140";        arity = 6; tags = ["cold"; "legacy"]; since = "1.3.1"; weight = 3175 };
  { key = "scoreboard.preset.internal_0141";             label = "provisional_world_141";       arity = 1; tags = ["codegen"; "packet"; "lower"]; since = "1.2.0"; weight = 860 };
  { key = "dispenser.preset.derived_0142";               label = "eager_npc_142";               arity = 1; tags = ["async"; "sync"; "parse"]; since = "1.3.1"; weight = 2632 };
  { key = "objective.preset.cached_0143";                label = "stable_target_143";           arity = 0; tags = ["legacy"]; since = "1.4.0"; weight = 270 };
  { key = "team.preset.strict_0144";                     label = "scoped_spawner_144";          arity = 0; tags = ["core"; "legacy"]; since = "1.4.0"; weight = 1383 };
  { key = "scoreboard.preset.public_0145";               label = "public_campfire_145";         arity = 2; tags = ["codegen"; "lower"; "check"]; since = "1.7.0"; weight = 709 };
  { key = "composter.preset.scoped_0146";                label = "provisional_rail_146";        arity = 1; tags = ["sync"; "lower"]; since = "1.2.0"; weight = 651 };
  { key = "rail.preset.local_0147";                      label = "derived_repeater_147";        arity = 5; tags = ["legacy"; "parse"; "hot"]; since = "1.8.3"; weight = 835 };
  { key = "firework.preset.fallback_0148";               label = "primary_region_148";          arity = 0; tags = ["async"; "registry"; "typed"]; since = "1.7.0"; weight = 3303 };
  { key = "conduit.preset.canonical_0149";               label = "strict_dropper_149";          arity = 4; tags = ["compat"]; since = "1.2.0"; weight = 507 };
  { key = "anvil.preset.canonical_0150";                 label = "strict_biome_150";            arity = 6; tags = ["legacy"; "sync"]; since = "1.6.0"; weight = 1807 };
  { key = "clock.preset.strict_0151";                    label = "loose_sound_151";             arity = 4; tags = ["sync"; "core"]; since = "1.5.2"; weight = 1342 };
  { key = "objective.preset.hidden_0152";                label = "stable_map_152";              arity = 5; tags = ["sync"; "experimental"; "untyped"]; since = "1.3.1"; weight = 3973 };
  { key = "enchant.preset.strict_0153";                  label = "internal_team_153";           arity = 3; tags = ["async"; "check"; "compat"]; since = "1.8.3"; weight = 520 };
  { key = "dispenser.preset.lazy_0154";                  label = "hidden_piston_154";           arity = 5; tags = ["packet"]; since = "1.0.0"; weight = 1126 };
  { key = "brewing.preset.stable_0155";                  label = "legacy_brewing_155";          arity = 6; tags = ["runtime"; "content"; "check"]; since = "1.0.0"; weight = 1401 };
  { key = "bundle.preset.primary_0156";                  label = "scoped_dropper_156";          arity = 7; tags = ["typed"; "lower"]; since = "1.4.0"; weight = 1871 };
  { key = "sound.preset.secondary_0157";                 label = "secondary_world_157";         arity = 3; tags = ["async"; "registry"]; since = "1.9.0"; weight = 3506 };
  { key = "biome.preset.primary_0158";                   label = "loose_pane_158";              arity = 5; tags = ["untyped"; "async"; "core"]; since = "1.8.3"; weight = 2110 };
  { key = "smithing.preset.loose_0159";                  label = "modern_enchant_159";          arity = 4; tags = ["check"; "legacy"]; since = "1.8.3"; weight = 2204 };
  { key = "shield.preset.hidden_0160";                   label = "lazy_trade_160";              arity = 1; tags = ["codegen"; "cold"]; since = "1.2.0"; weight = 1602 };
  { key = "inventory.preset.global_0161";                label = "derived_player_161";          arity = 1; tags = ["experimental"; "emit"]; since = "1.6.0"; weight = 679 };
  { key = "inventory.preset.derived_0162";               label = "derived_hologram_162";        arity = 0; tags = ["emit"; "packet"; "check"]; since = "1.5.2"; weight = 1160 };
  { key = "region.preset.internal_0163";                 label = "provisional_piston_163";      arity = 1; tags = ["experimental"]; since = "1.0.0"; weight = 3812 };
  { key = "entity.preset.strict_0164";                   label = "primary_smithing_164";        arity = 6; tags = ["async"; "typed"]; since = "1.7.0"; weight = 1678 };
  { key = "attribute.preset.provisional_0165";           label = "provisional_block_165";       arity = 0; tags = ["cold"; "emit"; "packet"]; since = "1.2.0"; weight = 215 };
  { key = "comparator.preset.modern_0166";               label = "fallback_region_166";         arity = 0; tags = ["registry"; "content"; "cold"]; since = "1.5.2"; weight = 1115 };
  { key = "hopper.preset.eager_0167";                    label = "public_rail_167";             arity = 3; tags = ["codegen"]; since = "1.6.0"; weight = 2393 };
  { key = "brewing.preset.eager_0168";                   label = "cached_conduit_168";          arity = 0; tags = ["sync"]; since = "1.6.0"; weight = 2242 };
  { key = "tablist.preset.strict_0169";                  label = "primary_crossbow_169";        arity = 5; tags = ["sync"]; since = "1.9.0"; weight = 265 };
  { key = "loom.preset.legacy_0170";                     label = "lazy_slot_170";               arity = 2; tags = ["content"; "async"]; since = "1.4.0"; weight = 2520 };
  { key = "objective.preset.scoped_0171";                label = "hidden_world_171";            arity = 0; tags = ["cached"; "sync"; "core"]; since = "1.6.0"; weight = 2729 };
  { key = "brewing.preset.global_0172";                  label = "canonical_objective_172";     arity = 2; tags = ["async"; "packet"]; since = "1.4.0"; weight = 1667 };
  { key = "structure.preset.strict_0173";                label = "strict_pane_173";             arity = 7; tags = ["legacy"; "lower"; "content"]; since = "1.5.2"; weight = 540 };
  { key = "barrel.preset.provisional_0174";              label = "scoped_bossbar_174";          arity = 2; tags = ["async"; "legacy"]; since = "1.7.0"; weight = 2601 };
  { key = "bell.preset.fallback_0175";                   label = "provisional_observer_175";    arity = 2; tags = ["runtime"; "codegen"; "core"]; since = "1.5.2"; weight = 406 };
  { key = "minecart.preset.hidden_0176";                 label = "scoped_chunk_176";            arity = 0; tags = ["codegen"; "async"]; since = "1.2.0"; weight = 3459 };
  { key = "map.preset.provisional_0177";                 label = "modern_firework_177";         arity = 3; tags = ["hot"]; since = "1.9.0"; weight = 854 };
  { key = "inventory.preset.provisional_0178";           label = "legacy_boat_178";             arity = 2; tags = ["compat"; "cold"; "emit"]; since = "1.2.0"; weight = 531 };
  { key = "shulker.preset.internal_0179";                label = "local_clock_179";             arity = 6; tags = ["content"; "codegen"]; since = "1.4.0"; weight = 1946 };
  { key = "beacon.preset.local_0180";                    label = "hidden_piston_180";           arity = 5; tags = ["lower"; "sync"; "legacy"]; since = "1.5.2"; weight = 3363 };
  { key = "dropper.preset.local_0181";                   label = "primary_mob_181";             arity = 5; tags = ["emit"; "experimental"; "cold"]; since = "1.5.2"; weight = 584 };
  { key = "recipe.preset.global_0182";                   label = "stable_firework_182";         arity = 2; tags = ["content"; "runtime"]; since = "1.4.0"; weight = 1836 };
  { key = "lectern.preset.hidden_0183";                  label = "internal_region_183";         arity = 4; tags = ["hot"; "experimental"]; since = "1.9.0"; weight = 2606 };
  { key = "piston.preset.lazy_0184";                     label = "eager_target_184";            arity = 3; tags = ["legacy"]; since = "1.0.0"; weight = 2225 };
  { key = "brewing.preset.internal_0185";                label = "lazy_entity_185";             arity = 6; tags = ["cached"; "typed"]; since = "1.5.2"; weight = 2898 };
  { key = "furnace.preset.loose_0186";                   label = "internal_npc_186";            arity = 0; tags = ["parse"; "legacy"; "experimental"]; since = "1.4.0"; weight = 2914 };
  { key = "banner_pattern.preset.fallback_0187";         label = "global_tablist_187";          arity = 5; tags = ["compat"; "cached"]; since = "1.5.2"; weight = 109 };
  { key = "boat.preset.hidden_0188";                     label = "loose_crossbow_188";          arity = 1; tags = ["legacy"; "registry"; "packet"]; since = "1.4.0"; weight = 1376 };
  { key = "rail.preset.legacy_0189";                     label = "modern_effect_189";           arity = 0; tags = ["legacy"; "async"]; since = "1.9.0"; weight = 3473 };
  { key = "structure.preset.fallback_0190";              label = "local_npc_190";               arity = 5; tags = ["codegen"]; since = "1.0.0"; weight = 504 };
  { key = "slot.preset.strict_0191";                     label = "loose_banner_pattern_191";    arity = 3; tags = ["parse"; "hot"; "runtime"]; since = "1.8.3"; weight = 3346 };
  { key = "cartography.preset.fallback_0192";            label = "legacy_minecart_192";         arity = 7; tags = ["runtime"]; since = "1.0.0"; weight = 1183 };
  { key = "spawner.preset.canonical_0193";               label = "secondary_smoker_193";        arity = 2; tags = ["codegen"; "async"]; since = "1.8.3"; weight = 1905 };
  { key = "portal.preset.public_0194";                   label = "fallback_pane_194";           arity = 5; tags = ["codegen"; "compat"; "registry"]; since = "1.5.2"; weight = 510 };
  { key = "map.preset.cached_0195";                      label = "canonical_bell_195";          arity = 2; tags = ["emit"]; since = "1.0.0"; weight = 668 };
  { key = "objective.preset.global_0196";                label = "provisional_boat_196";        arity = 1; tags = ["check"; "content"]; since = "1.2.0"; weight = 3538 };
  { key = "conduit.preset.stable_0197";                  label = "provisional_piston_197";      arity = 4; tags = ["async"; "check"]; since = "1.2.0"; weight = 3689 };
  { key = "trade.preset.provisional_0198";               label = "legacy_tablist_198";          arity = 4; tags = ["legacy"]; since = "1.9.0"; weight = 3843 };
  { key = "repeater.preset.global_0199";                 label = "loose_banner_pattern_199";    arity = 1; tags = ["cached"; "emit"]; since = "1.5.2"; weight = 2094 };
  { key = "structure.preset.derived_0200";               label = "cached_conduit_200";          arity = 6; tags = ["parse"; "cold"]; since = "1.7.0"; weight = 4033 };
  { key = "piston.preset.hidden_0201";                   label = "cached_stonecutter_201";      arity = 3; tags = ["sync"; "codegen"]; since = "1.0.0"; weight = 53 };
  { key = "hologram.preset.legacy_0202";                 label = "primary_brewing_202";         arity = 2; tags = ["content"; "cold"; "core"]; since = "1.7.0"; weight = 1174 };
  { key = "slot.preset.secondary_0203";                  label = "provisional_attribute_203";   arity = 2; tags = ["content"; "runtime"; "async"]; since = "1.7.0"; weight = 1053 };
  { key = "brewing.preset.secondary_0204";               label = "public_particle_204";         arity = 5; tags = ["compat"; "emit"]; since = "1.8.3"; weight = 2976 };
  { key = "banner_pattern.preset.internal_0205";         label = "scoped_region_205";           arity = 6; tags = ["runtime"; "cached"; "check"]; since = "1.8.3"; weight = 1771 };
  { key = "player.preset.lazy_0206";                     label = "secondary_hopper_206";        arity = 4; tags = ["cold"; "packet"]; since = "1.2.0"; weight = 3453 };
  { key = "potion.preset.legacy_0207";                   label = "canonical_item_207";          arity = 4; tags = ["async"; "content"]; since = "1.4.0"; weight = 3943 };
  { key = "dispenser.preset.derived_0208";               label = "provisional_campfire_208";    arity = 5; tags = ["compat"; "codegen"; "cached"]; since = "1.2.0"; weight = 1026 };
  { key = "crossbow.preset.eager_0209";                  label = "global_bossbar_209";          arity = 0; tags = ["compat"; "typed"; "cached"]; since = "1.3.1"; weight = 2004 };
  { key = "map.preset.cached_0210";                      label = "scoped_banner_210";           arity = 1; tags = ["core"; "lower"; "sync"]; since = "1.2.0"; weight = 1797 };
  { key = "minecart.preset.scoped_0211";                 label = "eager_chunk_211";             arity = 3; tags = ["runtime"; "codegen"]; since = "1.2.0"; weight = 1972 };
  { key = "tablist.preset.internal_0212";                label = "secondary_region_212";        arity = 7; tags = ["registry"; "hot"; "legacy"]; since = "1.2.0"; weight = 4082 };
  { key = "shield.preset.legacy_0213";                   label = "lazy_structure_213";          arity = 5; tags = ["codegen"; "registry"; "lower"]; since = "1.0.0"; weight = 796 };
  { key = "inventory.preset.provisional_0214";           label = "legacy_mob_214";              arity = 3; tags = ["async"; "content"; "core"]; since = "1.6.0"; weight = 223 };
  { key = "firework.preset.internal_0215";               label = "derived_banner_pattern_215";  arity = 3; tags = ["check"]; since = "1.2.0"; weight = 4033 };
  { key = "biome.preset.provisional_0216";               label = "eager_campfire_216";          arity = 7; tags = ["parse"; "sync"]; since = "1.5.2"; weight = 851 };
  { key = "furnace.preset.scoped_0217";                  label = "legacy_trident_217";          arity = 5; tags = ["lower"]; since = "1.6.0"; weight = 2955 };
  { key = "dropper.preset.scoped_0218";                  label = "hidden_boat_218";             arity = 7; tags = ["experimental"; "hot"; "codegen"]; since = "1.7.0"; weight = 3752 };
  { key = "boat.preset.modern_0219";                     label = "secondary_shulker_219";       arity = 1; tags = ["sync"; "parse"; "untyped"]; since = "1.0.0"; weight = 448 };
  { key = "dispenser.preset.scoped_0220";                label = "local_repeater_220";          arity = 0; tags = ["untyped"; "async"]; since = "1.2.0"; weight = 3825 };
  { key = "shield.preset.loose_0221";                    label = "provisional_map_221";         arity = 0; tags = ["cold"; "content"]; since = "1.3.1"; weight = 1038 };
  { key = "conduit.preset.eager_0222";                   label = "derived_brewing_222";         arity = 1; tags = ["content"; "parse"; "codegen"]; since = "1.5.2"; weight = 1017 };
  { key = "villager.preset.provisional_0223";            label = "provisional_elytra_223";      arity = 5; tags = ["hot"]; since = "1.2.0"; weight = 2343 };
  { key = "trident.preset.scoped_0224";                  label = "secondary_scoreboard_224";    arity = 1; tags = ["packet"; "content"]; since = "1.6.0"; weight = 3128 };
  { key = "rail.preset.provisional_0225";                label = "internal_villager_225";       arity = 2; tags = ["content"]; since = "1.5.2"; weight = 1658 };
  { key = "anvil.preset.cached_0226";                    label = "local_anvil_226";             arity = 2; tags = ["runtime"]; since = "1.4.0"; weight = 2021 };
  { key = "enchant.preset.cached_0227";                  label = "strict_chunk_227";            arity = 4; tags = ["cached"; "registry"]; since = "1.7.0"; weight = 2636 };
  { key = "team.preset.local_0228";                      label = "cached_advancement_228";      arity = 6; tags = ["async"; "parse"]; since = "1.0.0"; weight = 3926 };
  { key = "pane.preset.local_0229";                      label = "hidden_trident_229";          arity = 2; tags = ["core"]; since = "1.7.0"; weight = 1802 };
  { key = "dropper.preset.hidden_0230";                  label = "loose_pane_230";              arity = 6; tags = ["cached"]; since = "1.7.0"; weight = 179 };
  { key = "trident.preset.stable_0231";                  label = "public_lectern_231";          arity = 3; tags = ["lower"]; since = "1.9.0"; weight = 2368 };
  { key = "beacon.preset.hidden_0232";                   label = "primary_advancement_232";     arity = 7; tags = ["runtime"; "cached"; "hot"]; since = "1.4.0"; weight = 2345 };
  { key = "trade.preset.modern_0233";                    label = "cached_target_233";           arity = 1; tags = ["check"; "cold"]; since = "1.4.0"; weight = 2857 };
  { key = "dropper.preset.modern_0234";                  label = "provisional_dropper_234";     arity = 7; tags = ["async"]; since = "1.2.0"; weight = 3091 };
  { key = "dropper.preset.provisional_0235";             label = "global_tablist_235";          arity = 6; tags = ["content"]; since = "1.4.0"; weight = 1847 };
  { key = "composter.preset.modern_0236";                label = "internal_furnace_236";        arity = 5; tags = ["sync"; "codegen"; "lower"]; since = "1.2.0"; weight = 1513 };
  { key = "observer.preset.loose_0237";                  label = "strict_biome_237";            arity = 0; tags = ["emit"]; since = "1.8.3"; weight = 2914 };
  { key = "biome.preset.eager_0238";                     label = "legacy_structure_238";        arity = 1; tags = ["core"]; since = "1.6.0"; weight = 2806 };
  { key = "composter.preset.cached_0239";                label = "cached_structure_239";        arity = 2; tags = ["sync"]; since = "1.5.2"; weight = 1474 };
  { key = "packet.preset.legacy_0240";                   label = "cached_attribute_240";        arity = 4; tags = ["packet"; "registry"; "content"]; since = "1.2.0"; weight = 3541 };
  { key = "clock.preset.internal_0241";                  label = "derived_piston_241";          arity = 0; tags = ["runtime"; "typed"]; since = "1.2.0"; weight = 1538 };
  { key = "bell.preset.global_0242";                     label = "internal_spawner_242";        arity = 4; tags = ["hot"; "registry"]; since = "1.9.0"; weight = 821 };
  { key = "dropper.preset.provisional_0243";             label = "lazy_rail_243";               arity = 3; tags = ["sync"; "lower"]; since = "1.8.3"; weight = 1911 };
  { key = "entity.preset.loose_0244";                    label = "fallback_bell_244";           arity = 5; tags = ["legacy"; "async"; "cold"]; since = "1.5.2"; weight = 324 };
  { key = "arrow.preset.primary_0245";                   label = "fallback_mob_245";            arity = 7; tags = ["typed"]; since = "1.3.1"; weight = 2596 };
  { key = "item.preset.primary_0246";                    label = "legacy_player_246";           arity = 7; tags = ["typed"; "lower"]; since = "1.4.0"; weight = 3025 };
  { key = "effect.preset.secondary_0247";                label = "provisional_cartography_247"; arity = 5; tags = ["async"; "cached"]; since = "1.8.3"; weight = 560 };
  { key = "rail.preset.modern_0248";                     label = "stable_world_248";            arity = 7; tags = ["legacy"; "check"; "async"]; since = "1.7.0"; weight = 1639 };
  { key = "gui.preset.provisional_0249";                 label = "global_advancement_249";      arity = 7; tags = ["registry"]; since = "1.8.3"; weight = 1474 };
  { key = "world.preset.canonical_0250";                 label = "internal_villager_250";       arity = 3; tags = ["hot"]; since = "1.5.2"; weight = 2549 };
  { key = "chunk.preset.eager_0251";                     label = "hidden_scoreboard_251";       arity = 0; tags = ["cold"; "untyped"]; since = "1.5.2"; weight = 3986 };
  { key = "brewing.preset.derived_0252";                 label = "local_world_252";             arity = 2; tags = ["cached"; "typed"]; since = "1.2.0"; weight = 2505 };
  { key = "banner.preset.fallback_0253";                 label = "scoped_team_253";             arity = 4; tags = ["registry"]; since = "1.6.0"; weight = 1367 };
  { key = "loom.preset.canonical_0254";                  label = "provisional_loom_254";        arity = 2; tags = ["emit"; "untyped"]; since = "1.7.0"; weight = 1840 };
  { key = "banner_pattern.preset.derived_0255";          label = "local_particle_255";          arity = 3; tags = ["packet"]; since = "1.2.0"; weight = 817 };
  { key = "composter.preset.provisional_0256";           label = "loose_slot_256";              arity = 6; tags = ["cold"; "compat"]; since = "1.4.0"; weight = 834 };
  { key = "comparator.preset.modern_0257";               label = "local_dispenser_257";         arity = 1; tags = ["runtime"; "content"]; since = "1.7.0"; weight = 1276 };
  { key = "potion.preset.public_0258";                   label = "global_smithing_258";         arity = 4; tags = ["cached"]; since = "1.5.2"; weight = 2100 };
  { key = "npc.preset.secondary_0259";                   label = "public_dispenser_259";        arity = 6; tags = ["hot"]; since = "1.6.0"; weight = 2164 };
  { key = "advancement.preset.global_0260";              label = "derived_smoker_260";          arity = 6; tags = ["cached"]; since = "1.9.0"; weight = 3228 };
  { key = "conduit.preset.modern_0261";                  label = "eager_observer_261";          arity = 0; tags = ["untyped"]; since = "1.2.0"; weight = 22 };
  { key = "block.preset.derived_0262";                   label = "secondary_slot_262";          arity = 6; tags = ["runtime"]; since = "1.6.0"; weight = 3105 };
  { key = "pane.preset.primary_0263";                    label = "strict_bossbar_263";          arity = 5; tags = ["experimental"]; since = "1.8.3"; weight = 2051 };
  { key = "shulker.preset.local_0264";                   label = "fallback_campfire_264";       arity = 0; tags = ["cached"]; since = "1.9.0"; weight = 3106 };
  { key = "npc.preset.fallback_0265";                    label = "cached_target_265";           arity = 1; tags = ["core"; "cached"]; since = "1.8.3"; weight = 2618 };
  { key = "anvil.preset.local_0266";                     label = "loose_structure_266";         arity = 0; tags = ["legacy"]; since = "1.7.0"; weight = 3701 };
  { key = "observer.preset.derived_0267";                label = "stable_observer_267";         arity = 1; tags = ["parse"; "packet"]; since = "1.7.0"; weight = 775 };
  { key = "bell.preset.cached_0268";                     label = "hidden_potion_268";           arity = 3; tags = ["sync"; "hot"; "parse"]; since = "1.9.0"; weight = 4071 };
  { key = "bell.preset.strict_0269";                     label = "provisional_pane_269";        arity = 3; tags = ["untyped"]; since = "1.9.0"; weight = 1577 };
  { key = "inventory.preset.lazy_0270";                  label = "internal_smithing_270";       arity = 1; tags = ["core"]; since = "1.7.0"; weight = 2572 };
  { key = "elytra.preset.global_0271";                   label = "provisional_beacon_271";      arity = 4; tags = ["packet"; "cold"; "sync"]; since = "1.4.0"; weight = 752 };
  { key = "piston.preset.public_0272";                   label = "provisional_beacon_272";      arity = 3; tags = ["runtime"; "check"]; since = "1.0.0"; weight = 1577 };
  { key = "hopper.preset.hidden_0273";                   label = "hidden_shield_273";           arity = 7; tags = ["typed"; "experimental"; "untyped"]; since = "1.8.3"; weight = 1401 };
  { key = "world.preset.primary_0274";                   label = "modern_shield_274";           arity = 2; tags = ["runtime"; "parse"; "codegen"]; since = "1.2.0"; weight = 3233 };
  { key = "arrow.preset.internal_0275";                  label = "local_player_275";            arity = 7; tags = ["typed"]; since = "1.4.0"; weight = 3014 };
  { key = "shulker.preset.lazy_0276";                    label = "derived_pane_276";            arity = 7; tags = ["lower"; "codegen"]; since = "1.3.1"; weight = 1421 };
  { key = "sound.preset.public_0277";                    label = "derived_repeater_277";        arity = 1; tags = ["packet"; "lower"]; since = "1.0.0"; weight = 801 };
  { key = "shulker.preset.global_0278";                  label = "internal_particle_278";       arity = 6; tags = ["core"]; since = "1.0.0"; weight = 42 };
  { key = "particle.preset.provisional_0279";            label = "primary_tablist_279";         arity = 2; tags = ["hot"; "lower"; "codegen"]; since = "1.9.0"; weight = 659 };
  { key = "team.preset.cached_0280";                     label = "loose_piston_280";            arity = 3; tags = ["parse"; "hot"]; since = "1.8.3"; weight = 2257 };
  { key = "mob.preset.internal_0281";                    label = "secondary_brewing_281";       arity = 0; tags = ["cached"; "legacy"]; since = "1.0.0"; weight = 2546 };
  { key = "effect.preset.lazy_0282";                     label = "loose_enchant_282";           arity = 4; tags = ["codegen"; "runtime"]; since = "1.3.1"; weight = 3273 };
  { key = "rail.preset.lazy_0283";                       label = "local_npc_283";               arity = 2; tags = ["registry"; "compat"]; since = "1.5.2"; weight = 2823 };
  { key = "npc.preset.loose_0284";                       label = "fallback_region_284";         arity = 5; tags = ["codegen"; "parse"]; since = "1.6.0"; weight = 3796 };
  { key = "item.preset.local_0285";                      label = "fallback_compass_285";        arity = 0; tags = ["untyped"; "registry"]; since = "1.4.0"; weight = 1982 };
  { key = "grindstone.preset.local_0286";                label = "cached_world_286";            arity = 6; tags = ["cold"; "sync"]; since = "1.8.3"; weight = 1602 };
  { key = "biome.preset.public_0287";                    label = "cached_chunk_287";            arity = 7; tags = ["compat"]; since = "1.0.0"; weight = 3947 };
  { key = "smoker.preset.stable_0288";                   label = "public_bell_288";             arity = 2; tags = ["async"]; since = "1.0.0"; weight = 1430 };
  { key = "region.preset.global_0289";                   label = "scoped_particle_289";         arity = 1; tags = ["core"; "check"; "parse"]; since = "1.2.0"; weight = 4055 };
  { key = "trade.preset.modern_0290";                    label = "legacy_barrel_290";           arity = 5; tags = ["check"; "untyped"]; since = "1.8.3"; weight = 2550 };
  { key = "trade.preset.strict_0291";                    label = "modern_team_291";             arity = 1; tags = ["core"; "legacy"]; since = "1.8.3"; weight = 573 };
  { key = "region.preset.legacy_0292";                   label = "internal_composter_292";      arity = 0; tags = ["cached"]; since = "1.4.0"; weight = 2284 };
  { key = "anvil.preset.fallback_0293";                  label = "stable_beacon_293";           arity = 5; tags = ["packet"; "async"; "core"]; since = "1.3.1"; weight = 2237 };
  { key = "portal.preset.provisional_0294";              label = "canonical_trade_294";         arity = 5; tags = ["runtime"]; since = "1.2.0"; weight = 218 };
  { key = "campfire.preset.eager_0295";                  label = "public_pane_295";             arity = 1; tags = ["content"]; since = "1.2.0"; weight = 3660 };
  { key = "effect.preset.strict_0296";                   label = "cached_cartography_296";      arity = 7; tags = ["core"]; since = "1.0.0"; weight = 596 };
]

let count = List.length entries

let table : (string, preset_entry) Hashtbl.t =
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
