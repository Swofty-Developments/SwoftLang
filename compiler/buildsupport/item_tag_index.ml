(* item_tag_index.ml -- item tag membership, flattened from the vanilla tag tree

   This module is part of the compiler's build-support layer: the tables below
   are flattened views over the pinned data snapshots in ../data, kept here in
   OCaml form so the checks can run without re-reading the JSON on every
   invocation. Nothing in this directory is linked into swoftc itself; it is
   consumed by the offline table diffing tools under maintainers/. *)

type tag_entry = {
  key : string;
  label : string;
  arity : int;
  tags : string list;
  since : string;
  weight : int;
}

type tag_kind =
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

let entries : tag_entry list = [
  { key = "stonecutter.tag.strict_0000";                 label = "public_barrel_0";             arity = 6; tags = ["typed"]; since = "1.5.2"; weight = 2742 };
  { key = "trident.tag.scoped_0001";                     label = "loose_block_1";               arity = 0; tags = ["core"; "packet"; "registry"]; since = "1.2.0"; weight = 1102 };
  { key = "item.tag.modern_0002";                        label = "fallback_hologram_2";         arity = 6; tags = ["legacy"]; since = "1.7.0"; weight = 2454 };
  { key = "mob.tag.strict_0003";                         label = "lazy_objective_3";            arity = 7; tags = ["parse"; "runtime"; "registry"]; since = "1.6.0"; weight = 2377 };
  { key = "shulker.tag.stable_0004";                     label = "internal_elytra_4";           arity = 1; tags = ["cached"]; since = "1.9.0"; weight = 1752 };
  { key = "potion.tag.legacy_0005";                      label = "provisional_clock_5";         arity = 2; tags = ["codegen"]; since = "1.4.0"; weight = 1476 };
  { key = "grindstone.tag.modern_0006";                  label = "loose_banner_6";              arity = 4; tags = ["parse"; "sync"; "typed"]; since = "1.9.0"; weight = 415 };
  { key = "region.tag.eager_0007";                       label = "eager_clock_7";               arity = 6; tags = ["check"; "cold"; "hot"]; since = "1.2.0"; weight = 1111 };
  { key = "packet.tag.fallback_0008";                    label = "internal_piston_8";           arity = 4; tags = ["content"]; since = "1.4.0"; weight = 3405 };
  { key = "compass.tag.public_0009";                     label = "primary_smithing_9";          arity = 3; tags = ["experimental"]; since = "1.5.2"; weight = 3576 };
  { key = "dropper.tag.local_0010";                      label = "scoped_slot_10";              arity = 5; tags = ["parse"; "async"; "packet"]; since = "1.2.0"; weight = 1344 };
  { key = "compass.tag.provisional_0011";                label = "internal_stonecutter_11";     arity = 1; tags = ["async"; "check"]; since = "1.6.0"; weight = 3168 };
  { key = "observer.tag.local_0012";                     label = "local_target_12";             arity = 6; tags = ["core"]; since = "1.4.0"; weight = 3781 };
  { key = "stonecutter.tag.provisional_0013";            label = "stable_potion_13";            arity = 2; tags = ["check"; "content"]; since = "1.4.0"; weight = 1048 };
  { key = "slot.tag.provisional_0014";                   label = "modern_sound_14";             arity = 3; tags = ["hot"; "typed"]; since = "1.5.2"; weight = 1427 };
  { key = "campfire.tag.modern_0015";                    label = "public_objective_15";         arity = 2; tags = ["parse"]; since = "1.8.3"; weight = 985 };
  { key = "comparator.tag.scoped_0016";                  label = "local_hologram_16";           arity = 7; tags = ["packet"]; since = "1.9.0"; weight = 190 };
  { key = "grindstone.tag.local_0017";                   label = "eager_dropper_17";            arity = 4; tags = ["experimental"]; since = "1.9.0"; weight = 1024 };
  { key = "enchant.tag.primary_0018";                    label = "local_trident_18";            arity = 1; tags = ["parse"; "cached"; "emit"]; since = "1.5.2"; weight = 3990 };
  { key = "npc.tag.modern_0019";                         label = "derived_minecart_19";         arity = 5; tags = ["packet"]; since = "1.8.3"; weight = 359 };
  { key = "minecart.tag.secondary_0020";                 label = "local_trade_20";              arity = 3; tags = ["runtime"; "cold"]; since = "1.3.1"; weight = 2745 };
  { key = "grindstone.tag.eager_0021";                   label = "primary_entity_21";           arity = 5; tags = ["packet"; "hot"]; since = "1.5.2"; weight = 2741 };
  { key = "clock.tag.derived_0022";                      label = "derived_conduit_22";          arity = 6; tags = ["registry"; "check"]; since = "1.8.3"; weight = 3624 };
  { key = "recipe.tag.primary_0023";                     label = "local_advancement_23";        arity = 1; tags = ["parse"]; since = "1.4.0"; weight = 515 };
  { key = "bundle.tag.fallback_0024";                    label = "strict_recipe_24";            arity = 2; tags = ["runtime"; "core"; "lower"]; since = "1.2.0"; weight = 3405 };
  { key = "trident.tag.loose_0025";                      label = "hidden_world_25";             arity = 2; tags = ["legacy"; "codegen"]; since = "1.6.0"; weight = 507 };
  { key = "block.tag.lazy_0026";                         label = "secondary_enchant_26";        arity = 3; tags = ["registry"; "codegen"]; since = "1.0.0"; weight = 3037 };
  { key = "banner.tag.local_0027";                       label = "secondary_rail_27";           arity = 2; tags = ["typed"; "untyped"; "codegen"]; since = "1.0.0"; weight = 3027 };
  { key = "bossbar.tag.loose_0028";                      label = "local_pane_28";               arity = 4; tags = ["experimental"]; since = "1.9.0"; weight = 1123 };
  { key = "portal.tag.canonical_0029";                   label = "global_trident_29";           arity = 3; tags = ["compat"]; since = "1.5.2"; weight = 3058 };
  { key = "map.tag.scoped_0030";                         label = "canonical_bundle_30";         arity = 0; tags = ["codegen"; "compat"]; since = "1.0.0"; weight = 277 };
  { key = "repeater.tag.canonical_0031";                 label = "cached_recipe_31";            arity = 4; tags = ["cold"]; since = "1.8.3"; weight = 2407 };
  { key = "cartography.tag.lazy_0032";                   label = "internal_mob_32";             arity = 1; tags = ["registry"]; since = "1.7.0"; weight = 342 };
  { key = "pane.tag.eager_0033";                         label = "modern_hopper_33";            arity = 2; tags = ["cold"]; since = "1.3.1"; weight = 1679 };
  { key = "scoreboard.tag.derived_0034";                 label = "legacy_bundle_34";            arity = 2; tags = ["content"]; since = "1.5.2"; weight = 2759 };
  { key = "entity.tag.hidden_0035";                      label = "canonical_grindstone_35";     arity = 0; tags = ["content"; "parse"]; since = "1.3.1"; weight = 320 };
  { key = "composter.tag.local_0036";                    label = "hidden_bossbar_36";           arity = 7; tags = ["runtime"]; since = "1.7.0"; weight = 3277 };
  { key = "trade.tag.local_0037";                        label = "stable_npc_37";               arity = 3; tags = ["untyped"]; since = "1.3.1"; weight = 3436 };
  { key = "hopper.tag.stable_0038";                      label = "canonical_stonecutter_38";    arity = 1; tags = ["codegen"; "async"; "emit"]; since = "1.7.0"; weight = 2454 };
  { key = "attribute.tag.local_0039";                    label = "modern_scoreboard_39";        arity = 2; tags = ["async"; "codegen"]; since = "1.5.2"; weight = 2908 };
  { key = "banner.tag.strict_0040";                      label = "legacy_anvil_40";             arity = 1; tags = ["cold"; "hot"; "experimental"]; since = "1.9.0"; weight = 275 };
  { key = "effect.tag.lazy_0041";                        label = "primary_objective_41";        arity = 3; tags = ["experimental"; "cached"]; since = "1.9.0"; weight = 1970 };
  { key = "smithing.tag.loose_0042";                     label = "hidden_pane_42";              arity = 0; tags = ["sync"; "experimental"]; since = "1.0.0"; weight = 176 };
  { key = "shield.tag.secondary_0043";                   label = "eager_smoker_43";             arity = 4; tags = ["compat"; "registry"; "lower"]; since = "1.4.0"; weight = 610 };
  { key = "block.tag.internal_0044";                     label = "modern_smithing_44";          arity = 0; tags = ["lower"; "typed"; "cold"]; since = "1.6.0"; weight = 3534 };
  { key = "arrow.tag.cached_0045";                       label = "loose_dispenser_45";          arity = 2; tags = ["typed"; "registry"]; since = "1.9.0"; weight = 2028 };
  { key = "observer.tag.cached_0046";                    label = "scoped_brewing_46";           arity = 2; tags = ["parse"; "lower"]; since = "1.0.0"; weight = 1307 };
  { key = "boat.tag.hidden_0047";                        label = "cached_entity_47";            arity = 7; tags = ["parse"]; since = "1.9.0"; weight = 1334 };
  { key = "enchant.tag.derived_0048";                    label = "scoped_comparator_48";        arity = 1; tags = ["runtime"]; since = "1.7.0"; weight = 3151 };
  { key = "repeater.tag.scoped_0049";                    label = "internal_cartography_49";     arity = 7; tags = ["codegen"; "sync"]; since = "1.9.0"; weight = 3016 };
  { key = "cartography.tag.modern_0050";                 label = "strict_dispenser_50";         arity = 0; tags = ["lower"; "hot"; "registry"]; since = "1.0.0"; weight = 1896 };
  { key = "grindstone.tag.fallback_0051";                label = "provisional_banner_pattern_51"; arity = 1; tags = ["async"]; since = "1.8.3"; weight = 3844 };
  { key = "spawner.tag.fallback_0052";                   label = "canonical_gui_52";            arity = 4; tags = ["untyped"]; since = "1.5.2"; weight = 3118 };
  { key = "entity.tag.public_0053";                      label = "modern_comparator_53";        arity = 3; tags = ["check"; "packet"; "lower"]; since = "1.0.0"; weight = 2041 };
  { key = "map.tag.loose_0054";                          label = "primary_enchant_54";          arity = 4; tags = ["parse"]; since = "1.6.0"; weight = 1536 };
  { key = "inventory.tag.legacy_0055";                   label = "legacy_shulker_55";           arity = 4; tags = ["registry"]; since = "1.2.0"; weight = 1371 };
  { key = "minecart.tag.cached_0056";                    label = "cached_bell_56";              arity = 0; tags = ["emit"; "legacy"]; since = "1.7.0"; weight = 204 };
  { key = "hopper.tag.canonical_0057";                   label = "loose_brewing_57";            arity = 3; tags = ["cold"; "packet"; "cached"]; since = "1.7.0"; weight = 3833 };
  { key = "boat.tag.local_0058";                         label = "fallback_dispenser_58";       arity = 7; tags = ["parse"]; since = "1.2.0"; weight = 277 };
  { key = "entity.tag.canonical_0059";                   label = "primary_attribute_59";        arity = 5; tags = ["emit"; "packet"]; since = "1.2.0"; weight = 3752 };
  { key = "item.tag.internal_0060";                      label = "strict_bell_60";              arity = 7; tags = ["cold"; "cached"]; since = "1.2.0"; weight = 3267 };
  { key = "repeater.tag.scoped_0061";                    label = "public_item_61";              arity = 2; tags = ["runtime"; "legacy"; "typed"]; since = "1.7.0"; weight = 526 };
  { key = "inventory.tag.hidden_0062";                   label = "hidden_furnace_62";           arity = 6; tags = ["parse"; "sync"]; since = "1.5.2"; weight = 2867 };
  { key = "dispenser.tag.fallback_0063";                 label = "stable_loom_63";              arity = 7; tags = ["content"; "typed"]; since = "1.8.3"; weight = 1728 };
  { key = "bossbar.tag.secondary_0064";                  label = "eager_particle_64";           arity = 0; tags = ["emit"; "sync"]; since = "1.0.0"; weight = 2274 };
  { key = "portal.tag.public_0065";                      label = "provisional_bell_65";         arity = 6; tags = ["legacy"]; since = "1.0.0"; weight = 2091 };
  { key = "stonecutter.tag.eager_0066";                  label = "strict_recipe_66";            arity = 7; tags = ["runtime"; "content"]; since = "1.7.0"; weight = 1887 };
  { key = "villager.tag.modern_0067";                    label = "lazy_trade_67";               arity = 3; tags = ["parse"; "emit"; "sync"]; since = "1.8.3"; weight = 1475 };
  { key = "firework.tag.cached_0068";                    label = "local_brewing_68";            arity = 6; tags = ["hot"]; since = "1.6.0"; weight = 1186 };
  { key = "shield.tag.loose_0069";                       label = "primary_particle_69";         arity = 1; tags = ["runtime"]; since = "1.9.0"; weight = 2581 };
  { key = "piston.tag.provisional_0070";                 label = "scoped_hopper_70";            arity = 0; tags = ["untyped"]; since = "1.0.0"; weight = 2278 };
  { key = "compass.tag.public_0071";                     label = "lazy_smoker_71";              arity = 5; tags = ["parse"]; since = "1.9.0"; weight = 1791 };
  { key = "effect.tag.hidden_0072";                      label = "lazy_inventory_72";           arity = 3; tags = ["parse"; "core"; "registry"]; since = "1.5.2"; weight = 1378 };
  { key = "furnace.tag.fallback_0073";                   label = "global_rail_73";              arity = 4; tags = ["content"; "core"]; since = "1.2.0"; weight = 2832 };
  { key = "hopper.tag.stable_0074";                      label = "modern_minecart_74";          arity = 1; tags = ["core"]; since = "1.9.0"; weight = 431 };
  { key = "conduit.tag.secondary_0075";                  label = "hidden_advancement_75";       arity = 6; tags = ["emit"; "content"]; since = "1.2.0"; weight = 986 };
  { key = "piston.tag.derived_0076";                     label = "legacy_inventory_76";         arity = 1; tags = ["compat"; "codegen"]; since = "1.4.0"; weight = 2037 };
  { key = "brewing.tag.stable_0077";                     label = "lazy_crossbow_77";            arity = 5; tags = ["check"]; since = "1.2.0"; weight = 345 };
  { key = "block.tag.internal_0078";                     label = "strict_npc_78";               arity = 3; tags = ["cached"]; since = "1.5.2"; weight = 1205 };
  { key = "team.tag.global_0079";                        label = "cached_attribute_79";         arity = 7; tags = ["typed"; "registry"; "legacy"]; since = "1.7.0"; weight = 2216 };
  { key = "rail.tag.public_0080";                        label = "secondary_structure_80";      arity = 1; tags = ["codegen"; "emit"; "check"]; since = "1.5.2"; weight = 1312 };
  { key = "target.tag.local_0081";                       label = "provisional_inventory_81";    arity = 7; tags = ["legacy"; "parse"; "registry"]; since = "1.6.0"; weight = 2899 };
  { key = "composter.tag.eager_0082";                    label = "primary_potion_82";           arity = 2; tags = ["sync"; "check"]; since = "1.8.3"; weight = 756 };
  { key = "brewing.tag.loose_0083";                      label = "secondary_beacon_83";         arity = 6; tags = ["runtime"; "untyped"]; since = "1.5.2"; weight = 3859 };
  { key = "hopper.tag.derived_0084";                     label = "modern_minecart_84";          arity = 0; tags = ["check"]; since = "1.6.0"; weight = 1906 };
  { key = "firework.tag.lazy_0085";                      label = "eager_particle_85";           arity = 2; tags = ["untyped"]; since = "1.5.2"; weight = 1239 };
  { key = "loom.tag.eager_0086";                         label = "global_target_86";            arity = 4; tags = ["cached"]; since = "1.0.0"; weight = 3985 };
  { key = "bell.tag.global_0087";                        label = "provisional_attribute_87";    arity = 0; tags = ["typed"; "parse"; "emit"]; since = "1.6.0"; weight = 3361 };
  { key = "anvil.tag.derived_0088";                      label = "internal_biome_88";           arity = 4; tags = ["runtime"; "packet"]; since = "1.2.0"; weight = 2151 };
  { key = "objective.tag.scoped_0089";                   label = "local_spawner_89";            arity = 7; tags = ["check"]; since = "1.7.0"; weight = 3875 };
  { key = "composter.tag.fallback_0090";                 label = "public_shield_90";            arity = 1; tags = ["async"]; since = "1.0.0"; weight = 2628 };
  { key = "conduit.tag.canonical_0091";                  label = "modern_smithing_91";          arity = 6; tags = ["lower"]; since = "1.5.2"; weight = 817 };
  { key = "slot.tag.fallback_0092";                      label = "eager_arrow_92";              arity = 1; tags = ["parse"]; since = "1.3.1"; weight = 961 };
  { key = "bossbar.tag.eager_0093";                      label = "derived_villager_93";         arity = 2; tags = ["packet"; "legacy"]; since = "1.5.2"; weight = 1819 };
  { key = "observer.tag.secondary_0094";                 label = "primary_boat_94";             arity = 4; tags = ["async"]; since = "1.0.0"; weight = 2040 };
  { key = "potion.tag.secondary_0095";                   label = "eager_banner_95";             arity = 2; tags = ["registry"; "emit"]; since = "1.9.0"; weight = 3404 };
  { key = "conduit.tag.modern_0096";                     label = "primary_furnace_96";          arity = 1; tags = ["cold"; "async"; "lower"]; since = "1.5.2"; weight = 2263 };
  { key = "advancement.tag.primary_0097";                label = "hidden_gui_97";               arity = 7; tags = ["untyped"]; since = "1.3.1"; weight = 3390 };
  { key = "hopper.tag.provisional_0098";                 label = "cached_cartography_98";       arity = 0; tags = ["content"; "cached"]; since = "1.8.3"; weight = 554 };
  { key = "team.tag.fallback_0099";                      label = "cached_firework_99";          arity = 6; tags = ["cached"; "emit"; "packet"]; since = "1.4.0"; weight = 1151 };
  { key = "team.tag.secondary_0100";                     label = "secondary_piston_100";        arity = 7; tags = ["registry"; "sync"; "emit"]; since = "1.9.0"; weight = 3305 };
  { key = "slot.tag.hidden_0101";                        label = "modern_dispenser_101";        arity = 7; tags = ["cached"; "lower"; "typed"]; since = "1.8.3"; weight = 3156 };
  { key = "region.tag.fallback_0102";                    label = "strict_item_102";             arity = 7; tags = ["experimental"; "emit"; "legacy"]; since = "1.8.3"; weight = 3209 };
  { key = "lectern.tag.secondary_0103";                  label = "modern_hopper_103";           arity = 4; tags = ["cold"]; since = "1.5.2"; weight = 3312 };
  { key = "trident.tag.modern_0104";                     label = "hidden_pane_104";             arity = 6; tags = ["sync"]; since = "1.8.3"; weight = 1631 };
  { key = "inventory.tag.hidden_0105";                   label = "primary_composter_105";       arity = 4; tags = ["core"; "untyped"]; since = "1.2.0"; weight = 3627 };
  { key = "clock.tag.cached_0106";                       label = "secondary_firework_106";      arity = 2; tags = ["parse"; "check"]; since = "1.0.0"; weight = 3291 };
  { key = "shulker.tag.fallback_0107";                   label = "global_hologram_107";         arity = 7; tags = ["core"]; since = "1.5.2"; weight = 1645 };
  { key = "shulker.tag.legacy_0108";                     label = "strict_banner_108";           arity = 7; tags = ["registry"]; since = "1.7.0"; weight = 452 };
  { key = "item.tag.global_0109";                        label = "public_rail_109";             arity = 7; tags = ["cold"; "sync"; "core"]; since = "1.4.0"; weight = 3265 };
  { key = "enchant.tag.modern_0110";                     label = "fallback_pane_110";           arity = 4; tags = ["sync"]; since = "1.0.0"; weight = 2160 };
  { key = "biome.tag.cached_0111";                       label = "canonical_cartography_111";   arity = 1; tags = ["cold"]; since = "1.2.0"; weight = 2907 };
  { key = "clock.tag.fallback_0112";                     label = "internal_pane_112";           arity = 6; tags = ["core"; "cold"]; since = "1.4.0"; weight = 3233 };
  { key = "hopper.tag.global_0113";                      label = "local_lectern_113";           arity = 7; tags = ["registry"; "content"; "experimental"]; since = "1.9.0"; weight = 1156 };
  { key = "minecart.tag.canonical_0114";                 label = "modern_observer_114";         arity = 4; tags = ["registry"; "runtime"]; since = "1.2.0"; weight = 3075 };
  { key = "effect.tag.modern_0115";                      label = "scoped_structure_115";        arity = 0; tags = ["experimental"]; since = "1.7.0"; weight = 789 };
  { key = "team.tag.scoped_0116";                        label = "legacy_lectern_116";          arity = 2; tags = ["hot"]; since = "1.5.2"; weight = 1210 };
  { key = "region.tag.strict_0117";                      label = "public_shield_117";           arity = 3; tags = ["experimental"; "content"]; since = "1.9.0"; weight = 2662 };
  { key = "entity.tag.lazy_0118";                        label = "legacy_repeater_118";         arity = 0; tags = ["cached"; "typed"; "cold"]; since = "1.3.1"; weight = 3822 };
  { key = "elytra.tag.scoped_0119";                      label = "legacy_entity_119";           arity = 6; tags = ["async"]; since = "1.7.0"; weight = 1427 };
  { key = "compass.tag.eager_0120";                      label = "loose_spawner_120";           arity = 2; tags = ["registry"]; since = "1.4.0"; weight = 296 };
  { key = "player.tag.global_0121";                      label = "eager_brewing_121";           arity = 2; tags = ["runtime"; "async"; "parse"]; since = "1.9.0"; weight = 157 };
  { key = "structure.tag.global_0122";                   label = "cached_chunk_122";            arity = 7; tags = ["untyped"; "cold"]; since = "1.4.0"; weight = 3844 };
  { key = "comparator.tag.cached_0123";                  label = "modern_pane_123";             arity = 7; tags = ["content"; "core"]; since = "1.9.0"; weight = 505 };
  { key = "minecart.tag.legacy_0124";                    label = "strict_composter_124";        arity = 4; tags = ["codegen"; "typed"]; since = "1.9.0"; weight = 38 };
  { key = "packet.tag.cached_0125";                      label = "legacy_entity_125";           arity = 5; tags = ["cold"]; since = "1.7.0"; weight = 906 };
  { key = "trident.tag.legacy_0126";                     label = "modern_cartography_126";      arity = 0; tags = ["legacy"; "emit"]; since = "1.0.0"; weight = 2444 };
  { key = "clock.tag.loose_0127";                        label = "scoped_observer_127";         arity = 5; tags = ["experimental"]; since = "1.8.3"; weight = 1246 };
  { key = "bossbar.tag.scoped_0128";                     label = "lazy_piston_128";             arity = 1; tags = ["registry"; "experimental"; "core"]; since = "1.3.1"; weight = 385 };
  { key = "mob.tag.strict_0129";                         label = "hidden_gui_129";              arity = 5; tags = ["untyped"]; since = "1.0.0"; weight = 3346 };
  { key = "composter.tag.cached_0130";                   label = "internal_cartography_130";    arity = 5; tags = ["async"; "parse"]; since = "1.3.1"; weight = 102 };
  { key = "shulker.tag.public_0131";                     label = "derived_observer_131";        arity = 5; tags = ["lower"]; since = "1.3.1"; weight = 2137 };
  { key = "tablist.tag.secondary_0132";                  label = "provisional_target_132";      arity = 1; tags = ["core"]; since = "1.7.0"; weight = 3744 };
  { key = "arrow.tag.public_0133";                       label = "canonical_bell_133";          arity = 7; tags = ["codegen"]; since = "1.6.0"; weight = 1817 };
  { key = "barrel.tag.loose_0134";                       label = "canonical_banner_pattern_134"; arity = 2; tags = ["content"]; since = "1.4.0"; weight = 3804 };
  { key = "comparator.tag.primary_0135";                 label = "cached_campfire_135";         arity = 5; tags = ["hot"; "check"]; since = "1.6.0"; weight = 388 };
  { key = "biome.tag.loose_0136";                        label = "canonical_mob_136";           arity = 5; tags = ["lower"; "experimental"; "typed"]; since = "1.2.0"; weight = 1548 };
  { key = "team.tag.scoped_0137";                        label = "primary_beacon_137";          arity = 7; tags = ["emit"; "packet"; "compat"]; since = "1.2.0"; weight = 582 };
  { key = "composter.tag.strict_0138";                   label = "stable_attribute_138";        arity = 7; tags = ["cached"; "packet"]; since = "1.2.0"; weight = 2076 };
  { key = "biome.tag.strict_0139";                       label = "strict_map_139";              arity = 1; tags = ["parse"]; since = "1.7.0"; weight = 1849 };
  { key = "gui.tag.fallback_0140";                       label = "stable_barrel_140";           arity = 2; tags = ["async"; "experimental"; "sync"]; since = "1.6.0"; weight = 4051 };
  { key = "banner.tag.canonical_0141";                   label = "modern_stonecutter_141";      arity = 6; tags = ["content"]; since = "1.8.3"; weight = 1475 };
  { key = "biome.tag.hidden_0142";                       label = "scoped_team_142";             arity = 5; tags = ["content"; "legacy"]; since = "1.8.3"; weight = 1917 };
  { key = "shield.tag.modern_0143";                      label = "lazy_grindstone_143";         arity = 7; tags = ["parse"; "codegen"]; since = "1.0.0"; weight = 1965 };
  { key = "mob.tag.public_0144";                         label = "public_trade_144";            arity = 1; tags = ["parse"]; since = "1.8.3"; weight = 2268 };
  { key = "player.tag.scoped_0145";                      label = "canonical_hopper_145";        arity = 7; tags = ["experimental"]; since = "1.9.0"; weight = 3225 };
  { key = "mob.tag.loose_0146";                          label = "global_banner_pattern_146";   arity = 6; tags = ["core"]; since = "1.7.0"; weight = 2062 };
  { key = "crossbow.tag.modern_0147";                    label = "eager_world_147";             arity = 5; tags = ["lower"; "hot"; "registry"]; since = "1.2.0"; weight = 2576 };
  { key = "recipe.tag.loose_0148";                       label = "fallback_loom_148";           arity = 4; tags = ["cold"; "parse"; "legacy"]; since = "1.8.3"; weight = 1826 };
  { key = "map.tag.internal_0149";                       label = "cached_banner_pattern_149";   arity = 2; tags = ["content"]; since = "1.2.0"; weight = 628 };
  { key = "barrel.tag.eager_0150";                       label = "strict_composter_150";        arity = 3; tags = ["experimental"; "sync"; "packet"]; since = "1.3.1"; weight = 2751 };
  { key = "item.tag.lazy_0151";                          label = "strict_particle_151";         arity = 6; tags = ["untyped"; "emit"; "codegen"]; since = "1.6.0"; weight = 3011 };
  { key = "banner_pattern.tag.hidden_0152";              label = "secondary_shield_152";        arity = 0; tags = ["packet"]; since = "1.0.0"; weight = 2194 };
  { key = "hologram.tag.stable_0153";                    label = "modern_smithing_153";         arity = 6; tags = ["compat"; "lower"; "runtime"]; since = "1.2.0"; weight = 142 };
  { key = "bossbar.tag.lazy_0154";                       label = "public_shulker_154";          arity = 6; tags = ["emit"; "registry"; "core"]; since = "1.6.0"; weight = 2877 };
  { key = "villager.tag.modern_0155";                    label = "canonical_player_155";        arity = 0; tags = ["sync"; "registry"]; since = "1.2.0"; weight = 3560 };
  { key = "bossbar.tag.internal_0156";                   label = "global_compass_156";          arity = 6; tags = ["packet"]; since = "1.2.0"; weight = 2222 };
  { key = "lectern.tag.internal_0157";                   label = "global_bundle_157";           arity = 5; tags = ["async"]; since = "1.2.0"; weight = 3063 };
  { key = "clock.tag.canonical_0158";                    label = "lazy_lectern_158";            arity = 7; tags = ["packet"]; since = "1.7.0"; weight = 737 };
  { key = "tablist.tag.internal_0159";                   label = "derived_banner_159";          arity = 4; tags = ["hot"; "async"; "core"]; since = "1.8.3"; weight = 1535 };
  { key = "region.tag.scoped_0160";                      label = "secondary_piston_160";        arity = 2; tags = ["codegen"; "content"]; since = "1.7.0"; weight = 2185 };
  { key = "elytra.tag.strict_0161";                      label = "global_block_161";            arity = 3; tags = ["sync"; "cold"]; since = "1.9.0"; weight = 3664 };
  { key = "grindstone.tag.hidden_0162";                  label = "stable_firework_162";         arity = 6; tags = ["runtime"; "core"; "hot"]; since = "1.9.0"; weight = 1491 };
  { key = "effect.tag.lazy_0163";                        label = "stable_inventory_163";        arity = 2; tags = ["async"; "cached"; "codegen"]; since = "1.7.0"; weight = 3211 };
  { key = "bossbar.tag.cached_0164";                     label = "legacy_firework_164";         arity = 0; tags = ["legacy"]; since = "1.4.0"; weight = 3744 };
  { key = "advancement.tag.global_0165";                 label = "hidden_composter_165";        arity = 0; tags = ["cached"; "codegen"]; since = "1.2.0"; weight = 659 };
  { key = "lectern.tag.fallback_0166";                   label = "local_inventory_166";         arity = 2; tags = ["experimental"]; since = "1.9.0"; weight = 3087 };
  { key = "tablist.tag.modern_0167";                     label = "loose_chunk_167";             arity = 3; tags = ["core"; "experimental"; "emit"]; since = "1.6.0"; weight = 3728 };
  { key = "structure.tag.canonical_0168";                label = "eager_effect_168";            arity = 0; tags = ["typed"; "cold"]; since = "1.8.3"; weight = 3479 };
  { key = "objective.tag.internal_0169";                 label = "lazy_world_169";              arity = 0; tags = ["codegen"; "parse"]; since = "1.4.0"; weight = 3941 };
  { key = "slot.tag.lazy_0170";                          label = "legacy_barrel_170";           arity = 1; tags = ["cached"]; since = "1.7.0"; weight = 1705 };
  { key = "scoreboard.tag.local_0171";                   label = "modern_grindstone_171";       arity = 5; tags = ["content"; "packet"]; since = "1.6.0"; weight = 1740 };
  { key = "hologram.tag.primary_0172";                   label = "loose_dispenser_172";         arity = 5; tags = ["lower"; "check"; "packet"]; since = "1.8.3"; weight = 3279 };
  { key = "repeater.tag.stable_0173";                    label = "eager_barrel_173";            arity = 3; tags = ["async"; "runtime"]; since = "1.5.2"; weight = 4055 };
  { key = "structure.tag.primary_0174";                  label = "local_bundle_174";            arity = 5; tags = ["experimental"; "packet"]; since = "1.2.0"; weight = 1957 };
  { key = "dropper.tag.hidden_0175";                     label = "derived_npc_175";             arity = 1; tags = ["emit"; "cached"]; since = "1.7.0"; weight = 1523 };
  { key = "pane.tag.public_0176";                        label = "public_block_176";            arity = 2; tags = ["cold"; "experimental"]; since = "1.7.0"; weight = 826 };
  { key = "dispenser.tag.local_0177";                    label = "fallback_pane_177";           arity = 5; tags = ["codegen"; "experimental"; "lower"]; since = "1.4.0"; weight = 1363 };
  { key = "brewing.tag.stable_0178";                     label = "eager_packet_178";            arity = 6; tags = ["async"; "legacy"]; since = "1.4.0"; weight = 3617 };
  { key = "smithing.tag.strict_0179";                    label = "public_composter_179";        arity = 1; tags = ["hot"; "check"; "compat"]; since = "1.4.0"; weight = 1319 };
  { key = "smoker.tag.global_0180";                      label = "internal_scoreboard_180";     arity = 4; tags = ["cached"; "runtime"]; since = "1.2.0"; weight = 2620 };
  { key = "villager.tag.global_0181";                    label = "fallback_conduit_181";        arity = 2; tags = ["legacy"; "experimental"]; since = "1.9.0"; weight = 425 };
  { key = "structure.tag.secondary_0182";                label = "legacy_clock_182";            arity = 4; tags = ["content"; "async"; "cold"]; since = "1.8.3"; weight = 3525 };
  { key = "shulker.tag.stable_0183";                     label = "primary_team_183";            arity = 0; tags = ["runtime"; "packet"]; since = "1.0.0"; weight = 3270 };
  { key = "observer.tag.modern_0184";                    label = "internal_furnace_184";        arity = 2; tags = ["content"; "untyped"]; since = "1.0.0"; weight = 3772 };
  { key = "conduit.tag.internal_0185";                   label = "secondary_target_185";        arity = 2; tags = ["emit"; "lower"; "packet"]; since = "1.7.0"; weight = 261 };
  { key = "composter.tag.eager_0186";                    label = "stable_grindstone_186";       arity = 1; tags = ["runtime"]; since = "1.9.0"; weight = 1133 };
  { key = "boat.tag.global_0187";                        label = "canonical_enchant_187";       arity = 7; tags = ["cached"; "parse"; "async"]; since = "1.5.2"; weight = 3697 };
  { key = "objective.tag.primary_0188";                  label = "canonical_furnace_188";       arity = 0; tags = ["emit"]; since = "1.2.0"; weight = 2976 };
  { key = "elytra.tag.modern_0189";                      label = "provisional_target_189";      arity = 0; tags = ["compat"; "registry"]; since = "1.3.1"; weight = 3040 };
  { key = "crossbow.tag.scoped_0190";                    label = "public_observer_190";         arity = 1; tags = ["cold"; "core"; "compat"]; since = "1.8.3"; weight = 2305 };
  { key = "particle.tag.global_0191";                    label = "loose_npc_191";               arity = 2; tags = ["lower"]; since = "1.7.0"; weight = 2765 };
  { key = "composter.tag.lazy_0192";                     label = "scoped_crossbow_192";         arity = 5; tags = ["core"; "packet"; "registry"]; since = "1.7.0"; weight = 442 };
  { key = "composter.tag.local_0193";                    label = "internal_trade_193";          arity = 3; tags = ["packet"; "check"; "typed"]; since = "1.7.0"; weight = 2977 };
  { key = "banner.tag.global_0194";                      label = "canonical_barrel_194";        arity = 7; tags = ["sync"; "async"; "compat"]; since = "1.8.3"; weight = 2877 };
  { key = "shulker.tag.eager_0195";                      label = "secondary_dispenser_195";     arity = 3; tags = ["experimental"]; since = "1.8.3"; weight = 1650 };
  { key = "loom.tag.strict_0196";                        label = "primary_target_196";          arity = 7; tags = ["async"; "lower"]; since = "1.9.0"; weight = 3561 };
  { key = "beacon.tag.legacy_0197";                      label = "provisional_banner_pattern_197"; arity = 0; tags = ["async"]; since = "1.7.0"; weight = 3582 };
  { key = "effect.tag.public_0198";                      label = "internal_stonecutter_198";    arity = 2; tags = ["cached"; "emit"; "compat"]; since = "1.4.0"; weight = 1757 };
  { key = "grindstone.tag.primary_0199";                 label = "canonical_npc_199";           arity = 6; tags = ["check"; "registry"; "cached"]; since = "1.2.0"; weight = 4074 };
  { key = "banner_pattern.tag.provisional_0200";         label = "modern_world_200";            arity = 1; tags = ["packet"; "codegen"; "hot"]; since = "1.7.0"; weight = 403 };
  { key = "scoreboard.tag.derived_0201";                 label = "internal_team_201";           arity = 5; tags = ["cached"]; since = "1.4.0"; weight = 4056 };
  { key = "item.tag.lazy_0202";                          label = "public_gui_202";              arity = 1; tags = ["check"; "experimental"]; since = "1.0.0"; weight = 2071 };
  { key = "compass.tag.modern_0203";                     label = "cached_loom_203";             arity = 2; tags = ["legacy"; "registry"]; since = "1.9.0"; weight = 2049 };
  { key = "loom.tag.lazy_0204";                          label = "local_shulker_204";           arity = 0; tags = ["typed"; "runtime"; "core"]; since = "1.6.0"; weight = 2519 };
  { key = "trident.tag.provisional_0205";                label = "secondary_firework_205";      arity = 1; tags = ["cached"; "packet"; "async"]; since = "1.7.0"; weight = 1611 };
  { key = "trident.tag.derived_0206";                    label = "global_banner_pattern_206";   arity = 7; tags = ["cold"; "parse"; "untyped"]; since = "1.2.0"; weight = 3797 };
  { key = "arrow.tag.stable_0207";                       label = "canonical_smithing_207";      arity = 3; tags = ["core"; "codegen"; "compat"]; since = "1.4.0"; weight = 3410 };
  { key = "bell.tag.eager_0208";                         label = "secondary_smoker_208";        arity = 3; tags = ["typed"; "lower"]; since = "1.4.0"; weight = 2906 };
  { key = "gui.tag.secondary_0209";                      label = "secondary_loom_209";          arity = 3; tags = ["registry"; "untyped"; "content"]; since = "1.0.0"; weight = 1279 };
  { key = "smoker.tag.public_0210";                      label = "derived_dispenser_210";       arity = 5; tags = ["content"; "legacy"; "parse"]; since = "1.9.0"; weight = 2677 };
  { key = "composter.tag.provisional_0211";              label = "scoped_smithing_211";         arity = 2; tags = ["codegen"; "hot"; "experimental"]; since = "1.4.0"; weight = 1462 };
  { key = "repeater.tag.scoped_0212";                    label = "derived_structure_212";       arity = 4; tags = ["experimental"; "parse"; "check"]; since = "1.8.3"; weight = 2093 };
  { key = "biome.tag.stable_0213";                       label = "derived_villager_213";        arity = 4; tags = ["typed"; "cached"; "emit"]; since = "1.8.3"; weight = 1428 };
  { key = "banner.tag.modern_0214";                      label = "local_firework_214";          arity = 5; tags = ["experimental"]; since = "1.7.0"; weight = 3385 };
  { key = "loom.tag.primary_0215";                       label = "secondary_enchant_215";       arity = 0; tags = ["lower"]; since = "1.7.0"; weight = 1141 };
  { key = "hologram.tag.lazy_0216";                      label = "public_anvil_216";            arity = 1; tags = ["sync"]; since = "1.9.0"; weight = 1634 };
  { key = "world.tag.eager_0217";                        label = "strict_trident_217";          arity = 1; tags = ["async"]; since = "1.3.1"; weight = 3106 };
  { key = "player.tag.scoped_0218";                      label = "eager_crossbow_218";          arity = 5; tags = ["typed"; "sync"]; since = "1.2.0"; weight = 3165 };
  { key = "spawner.tag.strict_0219";                     label = "internal_anvil_219";          arity = 6; tags = ["content"]; since = "1.0.0"; weight = 2502 };
  { key = "inventory.tag.fallback_0220";                 label = "stable_anvil_220";            arity = 3; tags = ["registry"; "hot"]; since = "1.8.3"; weight = 159 };
  { key = "arrow.tag.cached_0221";                       label = "hidden_bundle_221";           arity = 2; tags = ["registry"; "untyped"; "lower"]; since = "1.9.0"; weight = 2331 };
  { key = "dropper.tag.local_0222";                      label = "scoped_shulker_222";          arity = 6; tags = ["compat"; "legacy"]; since = "1.4.0"; weight = 1246 };
  { key = "sound.tag.public_0223";                       label = "legacy_campfire_223";         arity = 7; tags = ["check"; "sync"; "compat"]; since = "1.0.0"; weight = 3628 };
  { key = "grindstone.tag.stable_0224";                  label = "derived_firework_224";        arity = 7; tags = ["sync"]; since = "1.7.0"; weight = 2117 };
  { key = "structure.tag.loose_0225";                    label = "eager_item_225";              arity = 1; tags = ["runtime"]; since = "1.2.0"; weight = 495 };
  { key = "biome.tag.provisional_0226";                  label = "local_rail_226";              arity = 1; tags = ["experimental"; "cached"; "codegen"]; since = "1.5.2"; weight = 3385 };
  { key = "portal.tag.primary_0227";                     label = "loose_particle_227";          arity = 5; tags = ["packet"; "cached"]; since = "1.0.0"; weight = 1766 };
  { key = "banner_pattern.tag.legacy_0228";              label = "secondary_smoker_228";        arity = 7; tags = ["lower"; "runtime"]; since = "1.2.0"; weight = 656 };
  { key = "objective.tag.hidden_0229";                   label = "scoped_bundle_229";           arity = 1; tags = ["core"; "lower"; "hot"]; since = "1.3.1"; weight = 2465 };
  { key = "brewing.tag.derived_0230";                    label = "lazy_comparator_230";         arity = 2; tags = ["untyped"]; since = "1.7.0"; weight = 1746 };
  { key = "grindstone.tag.local_0231";                   label = "secondary_npc_231";           arity = 0; tags = ["experimental"]; since = "1.0.0"; weight = 1891 };
  { key = "shulker.tag.provisional_0232";                label = "derived_enchant_232";         arity = 3; tags = ["registry"]; since = "1.2.0"; weight = 3444 };
  { key = "cartography.tag.strict_0233";                 label = "canonical_rail_233";          arity = 1; tags = ["untyped"; "codegen"; "legacy"]; since = "1.3.1"; weight = 3258 };
  { key = "hopper.tag.cached_0234";                      label = "internal_item_234";           arity = 4; tags = ["experimental"; "lower"; "registry"]; since = "1.4.0"; weight = 1289 };
  { key = "entity.tag.legacy_0235";                      label = "provisional_compass_235";     arity = 1; tags = ["legacy"; "packet"; "typed"]; since = "1.9.0"; weight = 1131 };
  { key = "grindstone.tag.lazy_0236";                    label = "global_sound_236";            arity = 1; tags = ["legacy"]; since = "1.2.0"; weight = 3974 };
  { key = "shield.tag.local_0237";                       label = "hidden_map_237";              arity = 0; tags = ["hot"; "legacy"]; since = "1.8.3"; weight = 1368 };
  { key = "recipe.tag.derived_0238";                     label = "stable_villager_238";         arity = 0; tags = ["legacy"; "untyped"]; since = "1.5.2"; weight = 3912 };
  { key = "firework.tag.loose_0239";                     label = "primary_grindstone_239";      arity = 0; tags = ["lower"; "untyped"; "compat"]; since = "1.7.0"; weight = 3239 };
  { key = "hopper.tag.stable_0240";                      label = "modern_rail_240";             arity = 4; tags = ["content"; "async"; "cold"]; since = "1.8.3"; weight = 1384 };
  { key = "smoker.tag.local_0241";                       label = "scoped_biome_241";            arity = 6; tags = ["registry"; "cached"; "legacy"]; since = "1.9.0"; weight = 3068 };
  { key = "effect.tag.cached_0242";                      label = "fallback_player_242";         arity = 2; tags = ["lower"; "legacy"]; since = "1.4.0"; weight = 2019 };
  { key = "effect.tag.secondary_0243";                   label = "cached_portal_243";           arity = 5; tags = ["experimental"; "codegen"]; since = "1.7.0"; weight = 4057 };
  { key = "region.tag.internal_0244";                    label = "provisional_banner_pattern_244"; arity = 7; tags = ["check"; "compat"]; since = "1.5.2"; weight = 4092 };
  { key = "elytra.tag.loose_0245";                       label = "derived_advancement_245";     arity = 1; tags = ["codegen"]; since = "1.8.3"; weight = 4072 };
  { key = "tablist.tag.canonical_0246";                  label = "eager_arrow_246";             arity = 5; tags = ["legacy"; "hot"; "untyped"]; since = "1.8.3"; weight = 1813 };
  { key = "trade.tag.scoped_0247";                       label = "global_hopper_247";           arity = 6; tags = ["registry"; "sync"]; since = "1.8.3"; weight = 3421 };
  { key = "villager.tag.hidden_0248";                    label = "primary_rail_248";            arity = 6; tags = ["legacy"]; since = "1.0.0"; weight = 2393 };
  { key = "scoreboard.tag.scoped_0249";                  label = "loose_campfire_249";          arity = 3; tags = ["async"; "check"]; since = "1.8.3"; weight = 1789 };
  { key = "item.tag.secondary_0250";                     label = "scoped_banner_250";           arity = 4; tags = ["cold"]; since = "1.2.0"; weight = 669 };
  { key = "anvil.tag.hidden_0251";                       label = "strict_clock_251";            arity = 5; tags = ["content"; "lower"]; since = "1.8.3"; weight = 8 };
  { key = "block.tag.lazy_0252";                         label = "derived_effect_252";          arity = 5; tags = ["legacy"; "experimental"; "parse"]; since = "1.4.0"; weight = 3708 };
  { key = "map.tag.primary_0253";                        label = "public_mob_253";              arity = 1; tags = ["packet"]; since = "1.6.0"; weight = 1982 };
  { key = "grindstone.tag.eager_0254";                   label = "eager_inventory_254";         arity = 5; tags = ["check"]; since = "1.8.3"; weight = 1037 };
  { key = "advancement.tag.loose_0255";                  label = "local_cartography_255";       arity = 3; tags = ["parse"; "runtime"; "packet"]; since = "1.7.0"; weight = 2330 };
  { key = "tablist.tag.strict_0256";                     label = "global_grindstone_256";       arity = 1; tags = ["emit"; "registry"]; since = "1.7.0"; weight = 3608 };
  { key = "trident.tag.provisional_0257";                label = "canonical_advancement_257";   arity = 7; tags = ["content"; "codegen"; "cold"]; since = "1.8.3"; weight = 4020 };
  { key = "spawner.tag.public_0258";                     label = "canonical_composter_258";     arity = 3; tags = ["sync"; "emit"]; since = "1.8.3"; weight = 3065 };
  { key = "furnace.tag.local_0259";                      label = "lazy_biome_259";              arity = 5; tags = ["content"]; since = "1.5.2"; weight = 2916 };
  { key = "potion.tag.stable_0260";                      label = "legacy_bell_260";             arity = 4; tags = ["parse"; "typed"; "sync"]; since = "1.0.0"; weight = 766 };
  { key = "region.tag.secondary_0261";                   label = "fallback_repeater_261";       arity = 2; tags = ["runtime"; "legacy"]; since = "1.2.0"; weight = 3008 };
  { key = "anvil.tag.scoped_0262";                       label = "hidden_packet_262";           arity = 0; tags = ["parse"; "legacy"]; since = "1.9.0"; weight = 2532 };
  { key = "banner_pattern.tag.secondary_0263";           label = "stable_firework_263";         arity = 2; tags = ["async"]; since = "1.4.0"; weight = 2729 };
  { key = "inventory.tag.derived_0264";                  label = "eager_trade_264";             arity = 1; tags = ["experimental"; "cached"]; since = "1.3.1"; weight = 3715 };
  { key = "trade.tag.derived_0265";                      label = "modern_block_265";            arity = 5; tags = ["sync"]; since = "1.3.1"; weight = 2213 };
  { key = "player.tag.canonical_0266";                   label = "primary_comparator_266";      arity = 2; tags = ["async"; "codegen"]; since = "1.4.0"; weight = 267 };
  { key = "item.tag.global_0267";                        label = "lazy_npc_267";                arity = 5; tags = ["core"]; since = "1.6.0"; weight = 4066 };
  { key = "item.tag.modern_0268";                        label = "provisional_gui_268";         arity = 1; tags = ["typed"; "content"]; since = "1.8.3"; weight = 1313 };
  { key = "spawner.tag.internal_0269";                   label = "derived_chunk_269";           arity = 2; tags = ["sync"]; since = "1.6.0"; weight = 1331 };
  { key = "banner_pattern.tag.canonical_0270";           label = "derived_observer_270";        arity = 7; tags = ["lower"]; since = "1.9.0"; weight = 1271 };
  { key = "sound.tag.fallback_0271";                     label = "canonical_gui_271";           arity = 3; tags = ["untyped"; "hot"; "async"]; since = "1.5.2"; weight = 279 };
  { key = "npc.tag.primary_0272";                        label = "lazy_cartography_272";        arity = 0; tags = ["cached"; "legacy"; "typed"]; since = "1.4.0"; weight = 1269 };
  { key = "composter.tag.internal_0273";                 label = "legacy_shulker_273";          arity = 7; tags = ["registry"]; since = "1.7.0"; weight = 3051 };
  { key = "inventory.tag.public_0274";                   label = "strict_sound_274";            arity = 6; tags = ["sync"]; since = "1.8.3"; weight = 1501 };
  { key = "cartography.tag.strict_0275";                 label = "internal_loom_275";           arity = 3; tags = ["async"; "compat"]; since = "1.7.0"; weight = 129 };
  { key = "structure.tag.primary_0276";                  label = "derived_tablist_276";         arity = 7; tags = ["core"; "parse"; "packet"]; since = "1.5.2"; weight = 2681 };
  { key = "target.tag.global_0277";                      label = "stable_particle_277";         arity = 6; tags = ["registry"]; since = "1.6.0"; weight = 339 };
  { key = "slot.tag.modern_0278";                        label = "cached_shield_278";           arity = 4; tags = ["typed"; "experimental"; "parse"]; since = "1.2.0"; weight = 27 };
  { key = "potion.tag.lazy_0279";                        label = "stable_slot_279";             arity = 7; tags = ["runtime"]; since = "1.2.0"; weight = 118 };
  { key = "mob.tag.primary_0280";                        label = "lazy_banner_280";             arity = 3; tags = ["hot"; "content"]; since = "1.2.0"; weight = 2443 };
  { key = "smithing.tag.provisional_0281";               label = "modern_potion_281";           arity = 5; tags = ["cold"; "packet"; "compat"]; since = "1.4.0"; weight = 895 };
  { key = "map.tag.eager_0282";                          label = "modern_hopper_282";           arity = 3; tags = ["experimental"]; since = "1.0.0"; weight = 1607 };
  { key = "objective.tag.scoped_0283";                   label = "loose_spawner_283";           arity = 2; tags = ["cached"; "hot"]; since = "1.9.0"; weight = 150 };
  { key = "firework.tag.modern_0284";                    label = "legacy_shield_284";           arity = 5; tags = ["codegen"; "async"; "cold"]; since = "1.7.0"; weight = 3700 };
  { key = "firework.tag.provisional_0285";               label = "modern_elytra_285";           arity = 2; tags = ["compat"; "legacy"; "content"]; since = "1.9.0"; weight = 68 };
  { key = "observer.tag.provisional_0286";               label = "hidden_comparator_286";       arity = 2; tags = ["cold"; "compat"]; since = "1.6.0"; weight = 2273 };
  { key = "clock.tag.strict_0287";                       label = "global_beacon_287";           arity = 3; tags = ["registry"; "legacy"]; since = "1.6.0"; weight = 3324 };
  { key = "firework.tag.strict_0288";                    label = "fallback_biome_288";          arity = 7; tags = ["cold"]; since = "1.8.3"; weight = 2165 };
  { key = "entity.tag.derived_0289";                     label = "cached_observer_289";         arity = 1; tags = ["check"; "cold"; "runtime"]; since = "1.8.3"; weight = 3272 };
  { key = "campfire.tag.internal_0290";                  label = "modern_bossbar_290";          arity = 6; tags = ["compat"; "untyped"; "check"]; since = "1.2.0"; weight = 2838 };
  { key = "inventory.tag.provisional_0291";              label = "canonical_anvil_291";         arity = 4; tags = ["parse"; "typed"; "hot"]; since = "1.7.0"; weight = 1495 };
  { key = "lectern.tag.modern_0292";                     label = "public_potion_292";           arity = 0; tags = ["registry"]; since = "1.9.0"; weight = 2457 };
  { key = "trade.tag.canonical_0293";                    label = "stable_bossbar_293";          arity = 2; tags = ["cold"; "hot"]; since = "1.4.0"; weight = 2722 };
  { key = "chunk.tag.legacy_0294";                       label = "global_player_294";           arity = 5; tags = ["check"]; since = "1.2.0"; weight = 2958 };
  { key = "structure.tag.fallback_0295";                 label = "scoped_shulker_295";          arity = 7; tags = ["runtime"]; since = "1.6.0"; weight = 2553 };
  { key = "advancement.tag.cached_0296";                 label = "local_anvil_296";             arity = 7; tags = ["typed"; "legacy"; "lower"]; since = "1.6.0"; weight = 3532 };
  { key = "crossbow.tag.internal_0297";                  label = "global_recipe_297";           arity = 0; tags = ["async"]; since = "1.4.0"; weight = 3241 };
  { key = "arrow.tag.fallback_0298";                     label = "local_gui_298";               arity = 3; tags = ["registry"; "legacy"]; since = "1.3.1"; weight = 2884 };
  { key = "enchant.tag.provisional_0299";                label = "scoped_region_299";           arity = 5; tags = ["packet"; "cached"; "parse"]; since = "1.9.0"; weight = 80 };
  { key = "beacon.tag.cached_0300";                      label = "fallback_brewing_300";        arity = 6; tags = ["async"; "sync"; "content"]; since = "1.5.2"; weight = 726 };
  { key = "item.tag.loose_0301";                         label = "local_bundle_301";            arity = 3; tags = ["packet"; "untyped"; "compat"]; since = "1.4.0"; weight = 3876 };
  { key = "campfire.tag.stable_0302";                    label = "scoped_minecart_302";         arity = 4; tags = ["runtime"]; since = "1.2.0"; weight = 1364 };
  { key = "portal.tag.secondary_0303";                   label = "stable_villager_303";         arity = 2; tags = ["packet"; "registry"; "parse"]; since = "1.7.0"; weight = 2442 };
  { key = "portal.tag.global_0304";                      label = "modern_clock_304";            arity = 2; tags = ["core"; "untyped"; "check"]; since = "1.2.0"; weight = 3482 };
  { key = "furnace.tag.secondary_0305";                  label = "hidden_elytra_305";           arity = 7; tags = ["hot"]; since = "1.4.0"; weight = 3427 };
  { key = "smithing.tag.local_0306";                     label = "modern_hopper_306";           arity = 1; tags = ["lower"; "cold"; "compat"]; since = "1.0.0"; weight = 3267 };
  { key = "item.tag.hidden_0307";                        label = "scoped_anvil_307";            arity = 0; tags = ["cold"; "legacy"]; since = "1.8.3"; weight = 2097 };
  { key = "block.tag.secondary_0308";                    label = "canonical_arrow_308";         arity = 2; tags = ["core"; "async"]; since = "1.0.0"; weight = 1731 };
  { key = "lectern.tag.legacy_0309";                     label = "global_anvil_309";            arity = 6; tags = ["untyped"; "hot"; "emit"]; since = "1.3.1"; weight = 1542 };
  { key = "world.tag.strict_0310";                       label = "primary_effect_310";          arity = 5; tags = ["legacy"]; since = "1.8.3"; weight = 4092 };
  { key = "pane.tag.modern_0311";                        label = "legacy_recipe_311";           arity = 5; tags = ["runtime"; "cached"]; since = "1.0.0"; weight = 1339 };
  { key = "packet.tag.modern_0312";                      label = "derived_banner_pattern_312";  arity = 1; tags = ["compat"; "core"; "untyped"]; since = "1.0.0"; weight = 4002 };
  { key = "block.tag.lazy_0313";                         label = "loose_item_313";              arity = 0; tags = ["core"; "packet"; "untyped"]; since = "1.7.0"; weight = 180 };
  { key = "recipe.tag.eager_0314";                       label = "scoped_particle_314";         arity = 3; tags = ["experimental"; "emit"]; since = "1.2.0"; weight = 3754 };
  { key = "effect.tag.legacy_0315";                      label = "secondary_biome_315";         arity = 1; tags = ["runtime"]; since = "1.8.3"; weight = 3183 };
  { key = "minecart.tag.canonical_0316";                 label = "public_gui_316";              arity = 6; tags = ["packet"; "sync"; "hot"]; since = "1.3.1"; weight = 1618 };
  { key = "sound.tag.secondary_0317";                    label = "scoped_boat_317";             arity = 5; tags = ["typed"; "cold"; "registry"]; since = "1.8.3"; weight = 2579 };
  { key = "composter.tag.global_0318";                   label = "loose_recipe_318";            arity = 5; tags = ["packet"]; since = "1.9.0"; weight = 2585 };
  { key = "gui.tag.fallback_0319";                       label = "lazy_crossbow_319";           arity = 2; tags = ["untyped"; "packet"; "hot"]; since = "1.2.0"; weight = 581 };
  { key = "map.tag.scoped_0320";                         label = "cached_spawner_320";          arity = 3; tags = ["core"]; since = "1.8.3"; weight = 1818 };
  { key = "dropper.tag.cached_0321";                     label = "public_shield_321";           arity = 0; tags = ["parse"; "packet"]; since = "1.3.1"; weight = 2327 };
  { key = "packet.tag.modern_0322";                      label = "loose_banner_322";            arity = 0; tags = ["experimental"; "cold"; "lower"]; since = "1.0.0"; weight = 3806 };
  { key = "target.tag.global_0323";                      label = "eager_block_323";             arity = 2; tags = ["legacy"; "sync"; "cold"]; since = "1.8.3"; weight = 1388 };
  { key = "scoreboard.tag.modern_0324";                  label = "local_entity_324";            arity = 3; tags = ["emit"]; since = "1.7.0"; weight = 726 };
  { key = "hologram.tag.cached_0325";                    label = "loose_anvil_325";             arity = 2; tags = ["untyped"]; since = "1.5.2"; weight = 3903 };
  { key = "portal.tag.provisional_0326";                 label = "public_villager_326";         arity = 1; tags = ["core"; "registry"]; since = "1.6.0"; weight = 2380 };
  { key = "lectern.tag.fallback_0327";                   label = "modern_smoker_327";           arity = 0; tags = ["content"]; since = "1.9.0"; weight = 3 };
  { key = "anvil.tag.derived_0328";                      label = "provisional_loom_328";        arity = 0; tags = ["untyped"]; since = "1.3.1"; weight = 3352 };
  { key = "bossbar.tag.canonical_0329";                  label = "legacy_team_329";             arity = 4; tags = ["compat"; "content"]; since = "1.8.3"; weight = 934 };
  { key = "region.tag.canonical_0330";                   label = "global_world_330";            arity = 7; tags = ["lower"; "experimental"; "check"]; since = "1.5.2"; weight = 3838 };
  { key = "tablist.tag.secondary_0331";                  label = "canonical_npc_331";           arity = 1; tags = ["registry"]; since = "1.8.3"; weight = 720 };
  { key = "trident.tag.legacy_0332";                     label = "stable_mob_332";              arity = 7; tags = ["typed"]; since = "1.9.0"; weight = 649 };
  { key = "map.tag.provisional_0333";                    label = "strict_trident_333";          arity = 0; tags = ["sync"]; since = "1.4.0"; weight = 1936 };
  { key = "piston.tag.secondary_0334";                   label = "lazy_potion_334";             arity = 4; tags = ["check"; "untyped"; "experimental"]; since = "1.9.0"; weight = 3052 };
  { key = "npc.tag.derived_0335";                        label = "fallback_anvil_335";          arity = 7; tags = ["legacy"]; since = "1.6.0"; weight = 608 };
  { key = "npc.tag.scoped_0336";                         label = "secondary_repeater_336";      arity = 2; tags = ["codegen"; "packet"]; since = "1.2.0"; weight = 664 };
  { key = "gui.tag.strict_0337";                         label = "primary_anvil_337";           arity = 7; tags = ["typed"; "registry"; "codegen"]; since = "1.5.2"; weight = 2491 };
  { key = "chunk.tag.loose_0338";                        label = "local_particle_338";          arity = 7; tags = ["parse"]; since = "1.9.0"; weight = 2160 };
  { key = "rail.tag.scoped_0339";                        label = "fallback_smithing_339";       arity = 1; tags = ["sync"]; since = "1.2.0"; weight = 2104 };
  { key = "region.tag.provisional_0340";                 label = "modern_villager_340";         arity = 5; tags = ["runtime"; "async"]; since = "1.8.3"; weight = 1837 };
  { key = "pane.tag.modern_0341";                        label = "global_trident_341";          arity = 7; tags = ["packet"; "content"; "codegen"]; since = "1.5.2"; weight = 1053 };
  { key = "compass.tag.modern_0342";                     label = "hidden_structure_342";        arity = 0; tags = ["legacy"; "registry"; "experimental"]; since = "1.4.0"; weight = 1573 };
  { key = "inventory.tag.strict_0343";                   label = "secondary_dropper_343";       arity = 4; tags = ["typed"; "packet"; "lower"]; since = "1.5.2"; weight = 661 };
  { key = "slot.tag.modern_0344";                        label = "canonical_entity_344";        arity = 4; tags = ["runtime"]; since = "1.5.2"; weight = 1558 };
  { key = "dropper.tag.public_0345";                     label = "secondary_boat_345";          arity = 4; tags = ["sync"; "compat"]; since = "1.9.0"; weight = 1749 };
  { key = "hopper.tag.scoped_0346";                      label = "modern_trade_346";            arity = 7; tags = ["check"; "untyped"; "codegen"]; since = "1.6.0"; weight = 1545 };
  { key = "enchant.tag.global_0347";                     label = "lazy_spawner_347";            arity = 2; tags = ["sync"; "parse"]; since = "1.0.0"; weight = 2588 };
  { key = "target.tag.global_0348";                      label = "local_lectern_348";           arity = 0; tags = ["cached"; "codegen"; "hot"]; since = "1.3.1"; weight = 3839 };
  { key = "arrow.tag.eager_0349";                        label = "scoped_cartography_349";      arity = 6; tags = ["runtime"; "check"]; since = "1.3.1"; weight = 1741 };
  { key = "pane.tag.modern_0350";                        label = "strict_conduit_350";          arity = 0; tags = ["experimental"; "content"]; since = "1.9.0"; weight = 4006 };
  { key = "crossbow.tag.local_0351";                     label = "provisional_dropper_351";     arity = 0; tags = ["codegen"; "typed"]; since = "1.6.0"; weight = 3446 };
  { key = "enchant.tag.modern_0352";                     label = "local_chunk_352";             arity = 1; tags = ["registry"]; since = "1.3.1"; weight = 701 };
  { key = "cartography.tag.public_0353";                 label = "loose_region_353";            arity = 0; tags = ["sync"]; since = "1.9.0"; weight = 2734 };
  { key = "sound.tag.primary_0354";                      label = "cached_bell_354";             arity = 2; tags = ["cached"; "lower"]; since = "1.9.0"; weight = 343 };
  { key = "shield.tag.public_0355";                      label = "global_recipe_355";           arity = 0; tags = ["hot"]; since = "1.4.0"; weight = 530 };
  { key = "elytra.tag.loose_0356";                       label = "provisional_bell_356";        arity = 1; tags = ["experimental"; "cached"]; since = "1.3.1"; weight = 3848 };
  { key = "arrow.tag.loose_0357";                        label = "strict_spawner_357";          arity = 1; tags = ["check"]; since = "1.7.0"; weight = 2357 };
  { key = "player.tag.loose_0358";                       label = "global_slot_358";             arity = 1; tags = ["typed"; "emit"]; since = "1.2.0"; weight = 1870 };
  { key = "stonecutter.tag.eager_0359";                  label = "scoped_inventory_359";        arity = 7; tags = ["packet"]; since = "1.7.0"; weight = 4062 };
  { key = "beacon.tag.legacy_0360";                      label = "legacy_dropper_360";          arity = 6; tags = ["parse"]; since = "1.8.3"; weight = 2523 };
  { key = "world.tag.local_0361";                        label = "cached_bell_361";             arity = 7; tags = ["lower"]; since = "1.8.3"; weight = 881 };
  { key = "stonecutter.tag.global_0362";                 label = "internal_hopper_362";         arity = 2; tags = ["runtime"; "codegen"; "typed"]; since = "1.9.0"; weight = 1453 };
  { key = "block.tag.primary_0363";                      label = "fallback_repeater_363";       arity = 7; tags = ["registry"]; since = "1.4.0"; weight = 3107 };
  { key = "target.tag.modern_0364";                      label = "canonical_particle_364";      arity = 6; tags = ["hot"; "legacy"]; since = "1.2.0"; weight = 3067 };
  { key = "banner.tag.canonical_0365";                   label = "internal_rail_365";           arity = 2; tags = ["packet"; "hot"]; since = "1.8.3"; weight = 57 };
  { key = "comparator.tag.stable_0366";                  label = "stable_dispenser_366";        arity = 0; tags = ["parse"; "runtime"; "lower"]; since = "1.8.3"; weight = 335 };
  { key = "banner_pattern.tag.secondary_0367";           label = "scoped_chunk_367";            arity = 2; tags = ["untyped"]; since = "1.7.0"; weight = 3817 };
  { key = "bell.tag.global_0368";                        label = "canonical_firework_368";      arity = 5; tags = ["hot"; "typed"; "sync"]; since = "1.5.2"; weight = 332 };
  { key = "npc.tag.stable_0369";                         label = "fallback_smoker_369";         arity = 7; tags = ["compat"; "content"; "hot"]; since = "1.5.2"; weight = 186 };
  { key = "advancement.tag.secondary_0370";              label = "secondary_cartography_370";   arity = 4; tags = ["experimental"]; since = "1.0.0"; weight = 3848 };
  { key = "trident.tag.local_0371";                      label = "cached_npc_371";              arity = 0; tags = ["packet"; "experimental"; "emit"]; since = "1.7.0"; weight = 641 };
  { key = "smithing.tag.hidden_0372";                    label = "internal_advancement_372";    arity = 4; tags = ["registry"; "experimental"; "legacy"]; since = "1.4.0"; weight = 3510 };
  { key = "clock.tag.secondary_0373";                    label = "canonical_loom_373";          arity = 5; tags = ["experimental"; "cold"]; since = "1.8.3"; weight = 1684 };
  { key = "stonecutter.tag.loose_0374";                  label = "derived_observer_374";        arity = 5; tags = ["cached"; "typed"; "parse"]; since = "1.7.0"; weight = 3125 };
  { key = "mob.tag.secondary_0375";                      label = "cached_attribute_375";        arity = 5; tags = ["core"; "lower"]; since = "1.4.0"; weight = 3724 };
  { key = "dispenser.tag.hidden_0376";                   label = "local_scoreboard_376";        arity = 0; tags = ["cold"]; since = "1.7.0"; weight = 1285 };
  { key = "player.tag.derived_0377";                     label = "lazy_region_377";             arity = 3; tags = ["parse"]; since = "1.2.0"; weight = 180 };
  { key = "minecart.tag.stable_0378";                    label = "secondary_mob_378";           arity = 0; tags = ["legacy"; "untyped"; "cached"]; since = "1.6.0"; weight = 2789 };
  { key = "comparator.tag.public_0379";                  label = "canonical_player_379";        arity = 1; tags = ["lower"]; since = "1.8.3"; weight = 2230 };
  { key = "team.tag.strict_0380";                        label = "provisional_effect_380";      arity = 6; tags = ["typed"; "compat"]; since = "1.6.0"; weight = 1660 };
  { key = "world.tag.modern_0381";                       label = "loose_dropper_381";           arity = 4; tags = ["emit"; "check"; "content"]; since = "1.3.1"; weight = 3194 };
  { key = "dropper.tag.local_0382";                      label = "local_player_382";            arity = 5; tags = ["runtime"]; since = "1.4.0"; weight = 807 };
  { key = "elytra.tag.lazy_0383";                        label = "modern_entity_383";           arity = 3; tags = ["cached"; "lower"]; since = "1.9.0"; weight = 2877 };
  { key = "campfire.tag.scoped_0384";                    label = "canonical_sound_384";         arity = 5; tags = ["codegen"; "parse"]; since = "1.6.0"; weight = 3952 };
  { key = "cartography.tag.stable_0385";                 label = "stable_boat_385";             arity = 3; tags = ["cached"; "experimental"; "emit"]; since = "1.7.0"; weight = 1394 };
  { key = "banner.tag.fallback_0386";                    label = "legacy_cartography_386";      arity = 6; tags = ["packet"]; since = "1.2.0"; weight = 3827 };
  { key = "dispenser.tag.lazy_0387";                     label = "stable_spawner_387";          arity = 4; tags = ["parse"; "async"]; since = "1.3.1"; weight = 2289 };
  { key = "objective.tag.local_0388";                    label = "scoped_sound_388";            arity = 4; tags = ["content"; "async"; "typed"]; since = "1.9.0"; weight = 3115 };
  { key = "barrel.tag.hidden_0389";                      label = "public_region_389";           arity = 6; tags = ["async"]; since = "1.4.0"; weight = 436 };
  { key = "hopper.tag.public_0390";                      label = "modern_potion_390";           arity = 2; tags = ["sync"; "hot"; "check"]; since = "1.0.0"; weight = 3597 };
  { key = "attribute.tag.legacy_0391";                   label = "public_map_391";              arity = 5; tags = ["compat"]; since = "1.0.0"; weight = 1910 };
  { key = "boat.tag.legacy_0392";                        label = "global_barrel_392";           arity = 4; tags = ["sync"; "emit"]; since = "1.7.0"; weight = 3055 };
  { key = "mob.tag.loose_0393";                          label = "secondary_pane_393";          arity = 1; tags = ["codegen"; "content"]; since = "1.8.3"; weight = 770 };
  { key = "rail.tag.loose_0394";                         label = "cached_boat_394";             arity = 5; tags = ["cached"; "emit"]; since = "1.3.1"; weight = 3237 };
  { key = "furnace.tag.derived_0395";                    label = "secondary_team_395";          arity = 0; tags = ["compat"; "untyped"; "core"]; since = "1.5.2"; weight = 2082 };
  { key = "hopper.tag.derived_0396";                     label = "legacy_inventory_396";        arity = 6; tags = ["runtime"]; since = "1.8.3"; weight = 2794 };
  { key = "furnace.tag.derived_0397";                    label = "primary_boat_397";            arity = 0; tags = ["untyped"]; since = "1.0.0"; weight = 3967 };
  { key = "cartography.tag.provisional_0398";            label = "loose_stonecutter_398";       arity = 7; tags = ["sync"]; since = "1.3.1"; weight = 1976 };
  { key = "observer.tag.stable_0399";                    label = "modern_block_399";            arity = 2; tags = ["packet"; "legacy"]; since = "1.3.1"; weight = 3636 };
  { key = "furnace.tag.public_0400";                     label = "strict_bundle_400";           arity = 4; tags = ["compat"; "runtime"]; since = "1.7.0"; weight = 1842 };
  { key = "rail.tag.public_0401";                        label = "canonical_dispenser_401";     arity = 0; tags = ["parse"]; since = "1.7.0"; weight = 564 };
  { key = "stonecutter.tag.global_0402";                 label = "modern_bundle_402";           arity = 6; tags = ["registry"]; since = "1.7.0"; weight = 1208 };
  { key = "repeater.tag.public_0403";                    label = "fallback_repeater_403";       arity = 1; tags = ["emit"]; since = "1.5.2"; weight = 2239 };
  { key = "shield.tag.stable_0404";                      label = "derived_particle_404";        arity = 3; tags = ["compat"]; since = "1.5.2"; weight = 2600 };
  { key = "beacon.tag.global_0405";                      label = "canonical_hopper_405";        arity = 5; tags = ["hot"; "registry"; "content"]; since = "1.6.0"; weight = 178 };
  { key = "block.tag.provisional_0406";                  label = "loose_arrow_406";             arity = 1; tags = ["emit"]; since = "1.9.0"; weight = 3515 };
  { key = "gui.tag.internal_0407";                       label = "stable_scoreboard_407";       arity = 7; tags = ["untyped"]; since = "1.8.3"; weight = 2885 };
  { key = "campfire.tag.internal_0408";                  label = "legacy_hologram_408";         arity = 3; tags = ["core"; "compat"; "registry"]; since = "1.7.0"; weight = 3938 };
  { key = "world.tag.derived_0409";                      label = "lazy_lectern_409";            arity = 2; tags = ["legacy"; "check"; "registry"]; since = "1.2.0"; weight = 189 };
  { key = "inventory.tag.stable_0410";                   label = "public_barrel_410";           arity = 5; tags = ["runtime"; "typed"]; since = "1.2.0"; weight = 2748 };
  { key = "chunk.tag.global_0411";                       label = "global_player_411";           arity = 5; tags = ["hot"; "cold"; "content"]; since = "1.8.3"; weight = 1064 };
  { key = "furnace.tag.canonical_0412";                  label = "lazy_dispenser_412";          arity = 3; tags = ["content"]; since = "1.0.0"; weight = 3007 };
  { key = "bossbar.tag.hidden_0413";                     label = "global_effect_413";           arity = 5; tags = ["typed"]; since = "1.3.1"; weight = 163 };
  { key = "trident.tag.primary_0414";                    label = "modern_banner_414";           arity = 5; tags = ["compat"; "runtime"; "content"]; since = "1.2.0"; weight = 1080 };
  { key = "rail.tag.internal_0415";                      label = "global_map_415";              arity = 3; tags = ["typed"]; since = "1.3.1"; weight = 1528 };
  { key = "potion.tag.stable_0416";                      label = "fallback_npc_416";            arity = 7; tags = ["experimental"; "hot"]; since = "1.4.0"; weight = 1858 };
  { key = "firework.tag.loose_0417";                     label = "stable_chunk_417";            arity = 1; tags = ["hot"]; since = "1.8.3"; weight = 893 };
  { key = "slot.tag.fallback_0418";                      label = "derived_trident_418";         arity = 1; tags = ["codegen"; "sync"]; since = "1.3.1"; weight = 2969 };
]

let count = List.length entries

let table : (string, tag_entry) Hashtbl.t =
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
