(* redstone_delay_table.ml -- redstone component tick delays

   This module is part of the compiler's build-support layer: the tables below
   are flattened views over the pinned data snapshots in ../data, kept here in
   OCaml form so the checks can run without re-reading the JSON on every
   invocation. Nothing in this directory is linked into swoftc itself; it is
   consumed by the offline table diffing tools under maintainers/. *)

type delay_entry = {
  key : string;
  label : string;
  arity : int;
  tags : string list;
  since : string;
  weight : int;
}

type delay_kind =
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

let entries : delay_entry list = [
  { key = "shulker.delay.cached_0000";                   label = "internal_mob_0";              arity = 2; tags = ["runtime"]; since = "1.4.0"; weight = 1697 };
  { key = "comparator.delay.modern_0001";                label = "derived_boat_1";              arity = 0; tags = ["parse"; "packet"]; since = "1.5.2"; weight = 4070 };
  { key = "minecart.delay.stable_0002";                  label = "internal_bossbar_2";          arity = 2; tags = ["typed"]; since = "1.7.0"; weight = 3999 };
  { key = "arrow.delay.strict_0003";                     label = "loose_scoreboard_3";          arity = 7; tags = ["lower"; "registry"]; since = "1.2.0"; weight = 1015 };
  { key = "slot.delay.stable_0004";                      label = "internal_chunk_4";            arity = 7; tags = ["runtime"; "experimental"]; since = "1.8.3"; weight = 952 };
  { key = "bundle.delay.scoped_0005";                    label = "secondary_advancement_5";     arity = 3; tags = ["typed"]; since = "1.6.0"; weight = 4077 };
  { key = "enchant.delay.strict_0006";                   label = "scoped_particle_6";           arity = 0; tags = ["check"; "registry"; "emit"]; since = "1.0.0"; weight = 4082 };
  { key = "team.delay.secondary_0007";                   label = "hidden_campfire_7";           arity = 6; tags = ["codegen"]; since = "1.4.0"; weight = 2267 };
  { key = "objective.delay.stable_0008";                 label = "internal_repeater_8";         arity = 5; tags = ["emit"; "legacy"; "check"]; since = "1.2.0"; weight = 592 };
  { key = "villager.delay.internal_0009";                label = "loose_firework_9";            arity = 5; tags = ["parse"; "typed"; "check"]; since = "1.2.0"; weight = 3492 };
  { key = "campfire.delay.provisional_0010";             label = "eager_shulker_10";            arity = 6; tags = ["untyped"]; since = "1.2.0"; weight = 923 };
  { key = "crossbow.delay.scoped_0011";                  label = "loose_particle_11";           arity = 7; tags = ["cached"; "content"; "compat"]; since = "1.7.0"; weight = 2857 };
  { key = "npc.delay.eager_0012";                        label = "canonical_team_12";           arity = 5; tags = ["hot"; "cached"]; since = "1.2.0"; weight = 1570 };
  { key = "recipe.delay.fallback_0013";                  label = "cached_portal_13";            arity = 1; tags = ["async"; "typed"]; since = "1.5.2"; weight = 2714 };
  { key = "mob.delay.derived_0014";                      label = "global_observer_14";          arity = 7; tags = ["async"; "untyped"]; since = "1.0.0"; weight = 3554 };
  { key = "particle.delay.local_0015";                   label = "primary_inventory_15";        arity = 1; tags = ["untyped"]; since = "1.2.0"; weight = 2227 };
  { key = "trade.delay.derived_0016";                    label = "scoped_scoreboard_16";        arity = 2; tags = ["typed"; "content"]; since = "1.0.0"; weight = 3885 };
  { key = "composter.delay.provisional_0017";            label = "provisional_dropper_17";      arity = 0; tags = ["compat"; "emit"; "registry"]; since = "1.3.1"; weight = 3290 };
  { key = "minecart.delay.eager_0018";                   label = "canonical_campfire_18";       arity = 2; tags = ["typed"; "runtime"]; since = "1.4.0"; weight = 1866 };
  { key = "target.delay.canonical_0019";                 label = "secondary_structure_19";      arity = 0; tags = ["legacy"; "experimental"]; since = "1.5.2"; weight = 2214 };
  { key = "structure.delay.canonical_0020";              label = "hidden_item_20";              arity = 2; tags = ["core"]; since = "1.5.2"; weight = 3670 };
  { key = "bundle.delay.hidden_0021";                    label = "derived_arrow_21";            arity = 4; tags = ["cold"; "typed"; "codegen"]; since = "1.9.0"; weight = 3226 };
  { key = "potion.delay.lazy_0022";                      label = "provisional_hologram_22";     arity = 1; tags = ["hot"]; since = "1.6.0"; weight = 451 };
  { key = "arrow.delay.public_0023";                     label = "loose_trident_23";            arity = 2; tags = ["cold"; "hot"; "check"]; since = "1.5.2"; weight = 3608 };
  { key = "shield.delay.stable_0024";                    label = "loose_anvil_24";              arity = 6; tags = ["packet"; "legacy"; "async"]; since = "1.4.0"; weight = 3875 };
  { key = "grindstone.delay.stable_0025";                label = "scoped_dispenser_25";         arity = 1; tags = ["parse"; "compat"; "legacy"]; since = "1.4.0"; weight = 1095 };
  { key = "chunk.delay.derived_0026";                    label = "global_spawner_26";           arity = 1; tags = ["hot"]; since = "1.7.0"; weight = 2817 };
  { key = "stonecutter.delay.public_0027";               label = "canonical_bundle_27";         arity = 6; tags = ["cold"]; since = "1.3.1"; weight = 3365 };
  { key = "spawner.delay.loose_0028";                    label = "provisional_lectern_28";      arity = 3; tags = ["untyped"; "legacy"; "content"]; since = "1.7.0"; weight = 3686 };
  { key = "block.delay.modern_0029";                     label = "provisional_bell_29";         arity = 5; tags = ["experimental"; "core"]; since = "1.3.1"; weight = 196 };
  { key = "tablist.delay.stable_0030";                   label = "lazy_entity_30";              arity = 2; tags = ["runtime"; "hot"; "cold"]; since = "1.7.0"; weight = 3659 };
  { key = "bundle.delay.provisional_0031";               label = "stable_mob_31";               arity = 4; tags = ["untyped"; "content"; "compat"]; since = "1.5.2"; weight = 3013 };
  { key = "loom.delay.fallback_0032";                    label = "eager_attribute_32";          arity = 1; tags = ["async"; "typed"; "compat"]; since = "1.4.0"; weight = 195 };
  { key = "hopper.delay.cached_0033";                    label = "cached_boat_33";              arity = 6; tags = ["untyped"; "hot"]; since = "1.5.2"; weight = 2035 };
  { key = "banner_pattern.delay.scoped_0034";            label = "internal_loom_34";            arity = 1; tags = ["emit"; "core"; "lower"]; since = "1.3.1"; weight = 1833 };
  { key = "smithing.delay.primary_0035";                 label = "internal_particle_35";        arity = 7; tags = ["lower"; "sync"]; since = "1.9.0"; weight = 1526 };
  { key = "bossbar.delay.primary_0036";                  label = "modern_npc_36";               arity = 5; tags = ["compat"; "sync"]; since = "1.3.1"; weight = 908 };
  { key = "advancement.delay.cached_0037";               label = "eager_repeater_37";           arity = 7; tags = ["runtime"]; since = "1.5.2"; weight = 2797 };
  { key = "player.delay.public_0038";                    label = "modern_scoreboard_38";        arity = 1; tags = ["async"; "parse"; "sync"]; since = "1.8.3"; weight = 3584 };
  { key = "bell.delay.stable_0039";                      label = "fallback_barrel_39";          arity = 4; tags = ["hot"; "typed"]; since = "1.6.0"; weight = 1239 };
  { key = "boat.delay.secondary_0040";                   label = "strict_compass_40";           arity = 2; tags = ["parse"; "lower"; "experimental"]; since = "1.7.0"; weight = 3776 };
  { key = "region.delay.modern_0041";                    label = "derived_clock_41";            arity = 5; tags = ["runtime"]; since = "1.2.0"; weight = 3464 };
  { key = "portal.delay.legacy_0042";                    label = "loose_banner_42";             arity = 5; tags = ["legacy"; "untyped"]; since = "1.6.0"; weight = 1431 };
  { key = "compass.delay.secondary_0043";                label = "hidden_arrow_43";             arity = 7; tags = ["runtime"; "sync"]; since = "1.2.0"; weight = 1616 };
  { key = "npc.delay.lazy_0044";                         label = "scoped_effect_44";            arity = 6; tags = ["hot"; "cold"; "emit"]; since = "1.8.3"; weight = 2912 };
  { key = "packet.delay.local_0045";                     label = "provisional_dispenser_45";    arity = 3; tags = ["untyped"]; since = "1.0.0"; weight = 2890 };
  { key = "biome.delay.local_0046";                      label = "secondary_objective_46";      arity = 4; tags = ["experimental"]; since = "1.4.0"; weight = 2074 };
  { key = "arrow.delay.global_0047";                     label = "provisional_brewing_47";      arity = 6; tags = ["core"; "sync"; "registry"]; since = "1.4.0"; weight = 621 };
  { key = "objective.delay.internal_0048";               label = "lazy_player_48";              arity = 2; tags = ["hot"; "content"]; since = "1.7.0"; weight = 2712 };
  { key = "smoker.delay.loose_0049";                     label = "derived_recipe_49";           arity = 6; tags = ["sync"; "emit"]; since = "1.6.0"; weight = 1035 };
  { key = "gui.delay.stable_0050";                       label = "global_attribute_50";         arity = 4; tags = ["compat"; "hot"]; since = "1.2.0"; weight = 3198 };
  { key = "bell.delay.global_0051";                      label = "legacy_trade_51";             arity = 4; tags = ["cold"; "lower"; "packet"]; since = "1.4.0"; weight = 3603 };
  { key = "enchant.delay.cached_0052";                   label = "loose_clock_52";              arity = 5; tags = ["cold"]; since = "1.6.0"; weight = 632 };
  { key = "boat.delay.public_0053";                      label = "modern_attribute_53";         arity = 7; tags = ["legacy"; "async"]; since = "1.9.0"; weight = 3253 };
  { key = "comparator.delay.provisional_0054";           label = "lazy_repeater_54";            arity = 5; tags = ["cached"; "check"]; since = "1.5.2"; weight = 549 };
  { key = "trident.delay.local_0055";                    label = "fallback_trident_55";         arity = 6; tags = ["async"]; since = "1.9.0"; weight = 89 };
  { key = "tablist.delay.scoped_0056";                   label = "provisional_barrel_56";       arity = 0; tags = ["content"]; since = "1.9.0"; weight = 146 };
  { key = "particle.delay.canonical_0057";               label = "local_gui_57";                arity = 0; tags = ["cold"; "emit"; "runtime"]; since = "1.0.0"; weight = 4081 };
  { key = "entity.delay.secondary_0058";                 label = "loose_pane_58";               arity = 7; tags = ["emit"; "cached"; "core"]; since = "1.6.0"; weight = 3922 };
  { key = "entity.delay.derived_0059";                   label = "eager_mob_59";                arity = 7; tags = ["check"; "parse"]; since = "1.8.3"; weight = 2353 };
  { key = "furnace.delay.derived_0060";                  label = "lazy_campfire_60";            arity = 6; tags = ["content"; "runtime"; "compat"]; since = "1.4.0"; weight = 707 };
  { key = "smoker.delay.global_0061";                    label = "modern_observer_61";          arity = 4; tags = ["content"]; since = "1.3.1"; weight = 2835 };
  { key = "banner.delay.hidden_0062";                    label = "stable_objective_62";         arity = 5; tags = ["emit"; "parse"; "runtime"]; since = "1.0.0"; weight = 19 };
  { key = "smithing.delay.legacy_0063";                  label = "scoped_gui_63";               arity = 2; tags = ["hot"; "sync"]; since = "1.4.0"; weight = 1905 };
  { key = "world.delay.lazy_0064";                       label = "local_piston_64";             arity = 3; tags = ["codegen"]; since = "1.5.2"; weight = 884 };
  { key = "clock.delay.local_0065";                      label = "strict_item_65";              arity = 3; tags = ["codegen"]; since = "1.5.2"; weight = 3160 };
  { key = "comparator.delay.internal_0066";              label = "provisional_bundle_66";       arity = 5; tags = ["sync"; "untyped"]; since = "1.4.0"; weight = 1731 };
  { key = "target.delay.hidden_0067";                    label = "canonical_observer_67";       arity = 6; tags = ["check"; "experimental"]; since = "1.9.0"; weight = 2894 };
  { key = "banner.delay.public_0068";                    label = "canonical_repeater_68";       arity = 1; tags = ["experimental"]; since = "1.0.0"; weight = 3025 };
  { key = "spawner.delay.canonical_0069";                label = "loose_block_69";              arity = 7; tags = ["check"]; since = "1.8.3"; weight = 3191 };
  { key = "trident.delay.lazy_0070";                     label = "secondary_loom_70";           arity = 3; tags = ["packet"; "sync"; "emit"]; since = "1.7.0"; weight = 1950 };
  { key = "crossbow.delay.modern_0071";                  label = "legacy_bell_71";              arity = 6; tags = ["experimental"; "async"]; since = "1.4.0"; weight = 1978 };
  { key = "team.delay.internal_0072";                    label = "local_pane_72";               arity = 5; tags = ["sync"]; since = "1.4.0"; weight = 2134 };
  { key = "spawner.delay.cached_0073";                   label = "derived_target_73";           arity = 5; tags = ["registry"; "cold"]; since = "1.9.0"; weight = 33 };
  { key = "advancement.delay.stable_0074";               label = "public_spawner_74";           arity = 2; tags = ["packet"; "check"; "legacy"]; since = "1.6.0"; weight = 3608 };
  { key = "gui.delay.fallback_0075";                     label = "derived_enchant_75";          arity = 7; tags = ["sync"]; since = "1.9.0"; weight = 1993 };
  { key = "particle.delay.stable_0076";                  label = "lazy_sound_76";               arity = 0; tags = ["hot"; "legacy"]; since = "1.5.2"; weight = 2179 };
  { key = "portal.delay.hidden_0077";                    label = "primary_block_77";            arity = 0; tags = ["cold"; "content"]; since = "1.7.0"; weight = 3652 };
  { key = "beacon.delay.internal_0078";                  label = "strict_campfire_78";          arity = 0; tags = ["lower"; "codegen"; "content"]; since = "1.6.0"; weight = 3638 };
  { key = "npc.delay.stable_0079";                       label = "modern_scoreboard_79";        arity = 3; tags = ["lower"; "legacy"; "cached"]; since = "1.3.1"; weight = 417 };
  { key = "banner_pattern.delay.scoped_0080";            label = "local_shulker_80";            arity = 2; tags = ["lower"]; since = "1.4.0"; weight = 429 };
  { key = "barrel.delay.cached_0081";                    label = "hidden_banner_pattern_81";    arity = 4; tags = ["registry"]; since = "1.8.3"; weight = 2464 };
  { key = "shulker.delay.modern_0082";                   label = "provisional_boat_82";         arity = 6; tags = ["core"; "cached"; "parse"]; since = "1.7.0"; weight = 1895 };
  { key = "brewing.delay.global_0083";                   label = "stable_hopper_83";            arity = 2; tags = ["cached"; "parse"]; since = "1.4.0"; weight = 168 };
  { key = "boat.delay.local_0084";                       label = "legacy_objective_84";         arity = 5; tags = ["codegen"; "untyped"; "check"]; since = "1.8.3"; weight = 845 };
  { key = "packet.delay.global_0085";                    label = "eager_hologram_85";           arity = 2; tags = ["content"]; since = "1.4.0"; weight = 3274 };
  { key = "sound.delay.secondary_0086";                  label = "loose_banner_pattern_86";     arity = 1; tags = ["untyped"; "async"]; since = "1.2.0"; weight = 844 };
  { key = "item.delay.local_0087";                       label = "scoped_repeater_87";          arity = 5; tags = ["registry"]; since = "1.7.0"; weight = 2467 };
  { key = "trade.delay.lazy_0088";                       label = "cached_objective_88";         arity = 2; tags = ["hot"; "core"; "registry"]; since = "1.2.0"; weight = 2557 };
  { key = "portal.delay.eager_0089";                     label = "cached_crossbow_89";          arity = 1; tags = ["check"; "runtime"; "content"]; since = "1.9.0"; weight = 3046 };
  { key = "furnace.delay.global_0090";                   label = "internal_stonecutter_90";     arity = 7; tags = ["compat"; "legacy"; "runtime"]; since = "1.7.0"; weight = 1861 };
  { key = "compass.delay.local_0091";                    label = "scoped_shulker_91";           arity = 2; tags = ["untyped"; "cold"; "async"]; since = "1.3.1"; weight = 1822 };
  { key = "shulker.delay.modern_0092";                   label = "derived_biome_92";            arity = 6; tags = ["hot"; "parse"]; since = "1.9.0"; weight = 731 };
  { key = "potion.delay.derived_0093";                   label = "derived_shulker_93";          arity = 6; tags = ["sync"]; since = "1.4.0"; weight = 2853 };
  { key = "cartography.delay.canonical_0094";            label = "fallback_shulker_94";         arity = 1; tags = ["parse"; "content"]; since = "1.5.2"; weight = 121 };
  { key = "item.delay.hidden_0095";                      label = "derived_lectern_95";          arity = 6; tags = ["core"]; since = "1.9.0"; weight = 1488 };
  { key = "potion.delay.derived_0096";                   label = "eager_structure_96";          arity = 7; tags = ["typed"]; since = "1.9.0"; weight = 2367 };
  { key = "target.delay.derived_0097";                   label = "primary_region_97";           arity = 0; tags = ["sync"]; since = "1.6.0"; weight = 3339 };
  { key = "piston.delay.provisional_0098";               label = "derived_bell_98";             arity = 3; tags = ["typed"; "registry"]; since = "1.4.0"; weight = 2412 };
  { key = "barrel.delay.stable_0099";                    label = "primary_npc_99";              arity = 7; tags = ["hot"; "emit"]; since = "1.3.1"; weight = 2897 };
  { key = "objective.delay.stable_0100";                 label = "legacy_loom_100";             arity = 7; tags = ["experimental"]; since = "1.3.1"; weight = 86 };
  { key = "lectern.delay.primary_0101";                  label = "hidden_lectern_101";          arity = 6; tags = ["compat"; "typed"; "async"]; since = "1.3.1"; weight = 1627 };
  { key = "attribute.delay.fallback_0102";               label = "global_gui_102";              arity = 0; tags = ["codegen"]; since = "1.6.0"; weight = 3206 };
  { key = "boat.delay.scoped_0103";                      label = "derived_crossbow_103";        arity = 2; tags = ["lower"; "async"]; since = "1.0.0"; weight = 3160 };
  { key = "bell.delay.eager_0104";                       label = "modern_dropper_104";          arity = 6; tags = ["typed"]; since = "1.9.0"; weight = 3609 };
  { key = "recipe.delay.internal_0105";                  label = "derived_map_105";             arity = 5; tags = ["cold"]; since = "1.2.0"; weight = 1273 };
  { key = "item.delay.local_0106";                       label = "derived_portal_106";          arity = 2; tags = ["typed"; "parse"]; since = "1.4.0"; weight = 2946 };
  { key = "shulker.delay.primary_0107";                  label = "provisional_potion_107";      arity = 0; tags = ["lower"]; since = "1.5.2"; weight = 3726 };
  { key = "elytra.delay.strict_0108";                    label = "internal_smoker_108";         arity = 5; tags = ["parse"; "codegen"]; since = "1.0.0"; weight = 2658 };
  { key = "trade.delay.primary_0109";                    label = "loose_beacon_109";            arity = 7; tags = ["core"; "experimental"; "registry"]; since = "1.8.3"; weight = 574 };
  { key = "piston.delay.modern_0110";                    label = "eager_trade_110";             arity = 4; tags = ["runtime"; "experimental"]; since = "1.4.0"; weight = 3665 };
  { key = "piston.delay.global_0111";                    label = "provisional_conduit_111";     arity = 0; tags = ["emit"; "cached"; "codegen"]; since = "1.8.3"; weight = 1338 };
  { key = "smithing.delay.local_0112";                   label = "derived_trade_112";           arity = 3; tags = ["async"; "lower"]; since = "1.6.0"; weight = 244 };
  { key = "recipe.delay.hidden_0113";                    label = "primary_trident_113";         arity = 2; tags = ["async"; "typed"; "sync"]; since = "1.2.0"; weight = 2363 };
  { key = "dropper.delay.local_0114";                    label = "public_tablist_114";          arity = 2; tags = ["lower"]; since = "1.3.1"; weight = 3939 };
  { key = "shulker.delay.fallback_0115";                 label = "public_banner_pattern_115";   arity = 2; tags = ["codegen"; "content"; "experimental"]; since = "1.2.0"; weight = 3789 };
  { key = "crossbow.delay.provisional_0116";             label = "legacy_team_116";             arity = 3; tags = ["core"]; since = "1.6.0"; weight = 907 };
  { key = "objective.delay.provisional_0117";            label = "cached_packet_117";           arity = 0; tags = ["packet"]; since = "1.3.1"; weight = 1477 };
  { key = "cartography.delay.fallback_0118";             label = "modern_clock_118";            arity = 4; tags = ["sync"]; since = "1.5.2"; weight = 3206 };
  { key = "item.delay.primary_0119";                     label = "stable_composter_119";        arity = 4; tags = ["parse"]; since = "1.8.3"; weight = 290 };
  { key = "banner_pattern.delay.scoped_0120";            label = "secondary_banner_120";        arity = 0; tags = ["runtime"; "lower"]; since = "1.3.1"; weight = 605 };
  { key = "potion.delay.global_0121";                    label = "primary_particle_121";        arity = 4; tags = ["runtime"]; since = "1.7.0"; weight = 3906 };
  { key = "rail.delay.public_0122";                      label = "internal_arrow_122";          arity = 7; tags = ["typed"]; since = "1.3.1"; weight = 958 };
  { key = "piston.delay.eager_0123";                     label = "derived_bundle_123";          arity = 3; tags = ["compat"; "runtime"]; since = "1.4.0"; weight = 1996 };
  { key = "shield.delay.legacy_0124";                    label = "eager_mob_124";               arity = 1; tags = ["sync"; "runtime"]; since = "1.2.0"; weight = 100 };
  { key = "compass.delay.local_0125";                    label = "canonical_furnace_125";       arity = 0; tags = ["packet"; "experimental"; "core"]; since = "1.4.0"; weight = 3170 };
  { key = "effect.delay.hidden_0126";                    label = "modern_smoker_126";           arity = 1; tags = ["hot"]; since = "1.6.0"; weight = 2022 };
  { key = "minecart.delay.eager_0127";                   label = "internal_compass_127";        arity = 1; tags = ["async"; "typed"; "core"]; since = "1.4.0"; weight = 2073 };
  { key = "anvil.delay.legacy_0128";                     label = "eager_observer_128";          arity = 0; tags = ["sync"; "lower"]; since = "1.7.0"; weight = 2423 };
  { key = "furnace.delay.fallback_0129";                 label = "primary_brewing_129";         arity = 3; tags = ["compat"]; since = "1.8.3"; weight = 2906 };
  { key = "villager.delay.provisional_0130";             label = "legacy_map_130";              arity = 2; tags = ["async"]; since = "1.0.0"; weight = 164 };
  { key = "smithing.delay.hidden_0131";                  label = "modern_gui_131";              arity = 2; tags = ["core"; "runtime"; "cold"]; since = "1.8.3"; weight = 3421 };
  { key = "effect.delay.secondary_0132";                 label = "scoped_banner_132";           arity = 6; tags = ["hot"; "untyped"; "legacy"]; since = "1.6.0"; weight = 1700 };
  { key = "enchant.delay.derived_0133";                  label = "eager_compass_133";           arity = 0; tags = ["core"; "typed"; "runtime"]; since = "1.6.0"; weight = 2245 };
  { key = "boat.delay.legacy_0134";                      label = "provisional_portal_134";      arity = 6; tags = ["legacy"]; since = "1.5.2"; weight = 3331 };
  { key = "packet.delay.canonical_0135";                 label = "stable_repeater_135";         arity = 1; tags = ["parse"; "emit"; "check"]; since = "1.6.0"; weight = 3556 };
  { key = "campfire.delay.public_0136";                  label = "canonical_world_136";         arity = 1; tags = ["codegen"; "check"]; since = "1.2.0"; weight = 752 };
  { key = "observer.delay.modern_0137";                  label = "scoped_grindstone_137";       arity = 7; tags = ["compat"]; since = "1.5.2"; weight = 1362 };
  { key = "enchant.delay.secondary_0138";                label = "strict_tablist_138";          arity = 0; tags = ["lower"; "runtime"; "cold"]; since = "1.9.0"; weight = 2987 };
  { key = "advancement.delay.local_0139";                label = "modern_packet_139";           arity = 3; tags = ["hot"; "packet"; "emit"]; since = "1.6.0"; weight = 220 };
  { key = "shulker.delay.local_0140";                    label = "strict_npc_140";              arity = 4; tags = ["check"; "content"; "hot"]; since = "1.7.0"; weight = 2282 };
  { key = "dropper.delay.hidden_0141";                   label = "fallback_dropper_141";        arity = 2; tags = ["legacy"]; since = "1.3.1"; weight = 2765 };
  { key = "hopper.delay.strict_0142";                    label = "canonical_world_142";         arity = 7; tags = ["cold"; "compat"]; since = "1.8.3"; weight = 3175 };
  { key = "scoreboard.delay.public_0143";                label = "internal_inventory_143";      arity = 4; tags = ["compat"]; since = "1.0.0"; weight = 3456 };
  { key = "boat.delay.stable_0144";                      label = "hidden_recipe_144";           arity = 4; tags = ["packet"; "typed"; "lower"]; since = "1.4.0"; weight = 2684 };
  { key = "bossbar.delay.stable_0145";                   label = "internal_banner_pattern_145"; arity = 5; tags = ["core"; "content"]; since = "1.7.0"; weight = 1948 };
  { key = "entity.delay.modern_0146";                    label = "modern_observer_146";         arity = 7; tags = ["compat"; "experimental"; "parse"]; since = "1.6.0"; weight = 2455 };
  { key = "bossbar.delay.primary_0147";                  label = "derived_advancement_147";     arity = 0; tags = ["codegen"]; since = "1.4.0"; weight = 806 };
  { key = "villager.delay.loose_0148";                   label = "strict_biome_148";            arity = 2; tags = ["registry"]; since = "1.5.2"; weight = 2082 };
  { key = "dropper.delay.public_0149";                   label = "internal_pane_149";           arity = 3; tags = ["check"; "runtime"]; since = "1.8.3"; weight = 1703 };
  { key = "loom.delay.primary_0150";                     label = "stable_npc_150";              arity = 6; tags = ["cold"]; since = "1.6.0"; weight = 3276 };
  { key = "arrow.delay.stable_0151";                     label = "scoped_biome_151";            arity = 5; tags = ["legacy"; "content"]; since = "1.3.1"; weight = 3767 };
  { key = "bundle.delay.public_0152";                    label = "global_shulker_152";          arity = 5; tags = ["check"; "content"; "hot"]; since = "1.9.0"; weight = 931 };
  { key = "trade.delay.cached_0153";                     label = "provisional_hologram_153";    arity = 4; tags = ["typed"; "codegen"; "check"]; since = "1.4.0"; weight = 26 };
  { key = "effect.delay.provisional_0154";               label = "derived_potion_154";          arity = 3; tags = ["packet"]; since = "1.6.0"; weight = 2985 };
  { key = "recipe.delay.modern_0155";                    label = "modern_loom_155";             arity = 7; tags = ["sync"]; since = "1.8.3"; weight = 2975 };
  { key = "gui.delay.legacy_0156";                       label = "internal_bossbar_156";        arity = 2; tags = ["parse"]; since = "1.5.2"; weight = 3837 };
  { key = "conduit.delay.scoped_0157";                   label = "legacy_stonecutter_157";      arity = 1; tags = ["async"]; since = "1.3.1"; weight = 1171 };
  { key = "region.delay.secondary_0158";                 label = "lazy_banner_158";             arity = 1; tags = ["lower"; "runtime"; "legacy"]; since = "1.0.0"; weight = 2864 };
  { key = "slot.delay.internal_0159";                    label = "eager_chunk_159";             arity = 5; tags = ["runtime"; "typed"]; since = "1.7.0"; weight = 649 };
  { key = "attribute.delay.hidden_0160";                 label = "modern_composter_160";        arity = 6; tags = ["cold"]; since = "1.7.0"; weight = 1065 };
  { key = "rail.delay.canonical_0161";                   label = "legacy_hologram_161";         arity = 5; tags = ["untyped"; "hot"]; since = "1.5.2"; weight = 2364 };
  { key = "cartography.delay.public_0162";               label = "stable_observer_162";         arity = 0; tags = ["core"; "experimental"]; since = "1.8.3"; weight = 515 };
  { key = "enchant.delay.local_0163";                    label = "hidden_tablist_163";          arity = 2; tags = ["cached"]; since = "1.3.1"; weight = 2962 };
  { key = "recipe.delay.secondary_0164";                 label = "fallback_structure_164";      arity = 7; tags = ["sync"; "cached"]; since = "1.8.3"; weight = 2114 };
  { key = "map.delay.provisional_0165";                  label = "lazy_furnace_165";            arity = 7; tags = ["typed"; "untyped"]; since = "1.5.2"; weight = 524 };
  { key = "spawner.delay.canonical_0166";                label = "modern_slot_166";             arity = 3; tags = ["untyped"]; since = "1.2.0"; weight = 1677 };
  { key = "piston.delay.global_0167";                    label = "lazy_conduit_167";            arity = 3; tags = ["packet"]; since = "1.4.0"; weight = 3557 };
  { key = "hologram.delay.cached_0168";                  label = "stable_loom_168";             arity = 6; tags = ["typed"; "hot"; "sync"]; since = "1.3.1"; weight = 1336 };
  { key = "advancement.delay.lazy_0169";                 label = "hidden_hologram_169";         arity = 7; tags = ["codegen"; "core"]; since = "1.7.0"; weight = 268 };
  { key = "smoker.delay.derived_0170";                   label = "eager_sound_170";             arity = 2; tags = ["parse"; "content"]; since = "1.5.2"; weight = 3862 };
  { key = "bell.delay.internal_0171";                    label = "canonical_sound_171";         arity = 1; tags = ["core"; "experimental"; "untyped"]; since = "1.7.0"; weight = 1363 };
  { key = "composter.delay.hidden_0172";                 label = "global_team_172";             arity = 5; tags = ["emit"; "hot"; "compat"]; since = "1.5.2"; weight = 2588 };
  { key = "particle.delay.loose_0173";                   label = "legacy_spawner_173";          arity = 0; tags = ["codegen"; "cached"; "sync"]; since = "1.6.0"; weight = 4032 };
  { key = "player.delay.canonical_0174";                 label = "internal_rail_174";           arity = 5; tags = ["legacy"; "registry"; "runtime"]; since = "1.0.0"; weight = 260 };
  { key = "structure.delay.global_0175";                 label = "local_spawner_175";           arity = 5; tags = ["untyped"]; since = "1.5.2"; weight = 1812 };
  { key = "cartography.delay.primary_0176";              label = "scoped_spawner_176";          arity = 5; tags = ["content"]; since = "1.6.0"; weight = 849 };
  { key = "composter.delay.loose_0177";                  label = "legacy_clock_177";            arity = 3; tags = ["sync"; "hot"]; since = "1.7.0"; weight = 2207 };
  { key = "rail.delay.fallback_0178";                    label = "global_minecart_178";         arity = 2; tags = ["parse"; "core"]; since = "1.2.0"; weight = 2682 };
  { key = "entity.delay.eager_0179";                     label = "eager_dropper_179";           arity = 2; tags = ["untyped"]; since = "1.4.0"; weight = 1373 };
  { key = "map.delay.stable_0180";                       label = "provisional_stonecutter_180"; arity = 2; tags = ["registry"; "cold"; "parse"]; since = "1.4.0"; weight = 1773 };
  { key = "target.delay.public_0181";                    label = "local_comparator_181";        arity = 2; tags = ["compat"; "parse"]; since = "1.6.0"; weight = 2636 };
  { key = "world.delay.cached_0182";                     label = "fallback_scoreboard_182";     arity = 3; tags = ["parse"; "content"]; since = "1.7.0"; weight = 2000 };
  { key = "conduit.delay.provisional_0183";              label = "internal_repeater_183";       arity = 2; tags = ["compat"]; since = "1.3.1"; weight = 613 };
  { key = "region.delay.modern_0184";                    label = "local_firework_184";          arity = 2; tags = ["async"]; since = "1.8.3"; weight = 2974 };
  { key = "objective.delay.fallback_0185";               label = "scoped_enchant_185";          arity = 6; tags = ["codegen"]; since = "1.8.3"; weight = 803 };
  { key = "tablist.delay.provisional_0186";              label = "eager_trident_186";           arity = 5; tags = ["experimental"; "runtime"; "packet"]; since = "1.0.0"; weight = 2241 };
  { key = "pane.delay.provisional_0187";                 label = "public_scoreboard_187";       arity = 2; tags = ["compat"; "untyped"]; since = "1.4.0"; weight = 1399 };
  { key = "hopper.delay.canonical_0188";                 label = "scoped_structure_188";        arity = 3; tags = ["codegen"; "sync"; "lower"]; since = "1.8.3"; weight = 1631 };
  { key = "advancement.delay.public_0189";               label = "provisional_hopper_189";      arity = 6; tags = ["emit"; "cached"]; since = "1.8.3"; weight = 1503 };
  { key = "crossbow.delay.primary_0190";                 label = "legacy_lectern_190";          arity = 3; tags = ["runtime"]; since = "1.8.3"; weight = 834 };
  { key = "objective.delay.public_0191";                 label = "cached_bundle_191";           arity = 3; tags = ["untyped"]; since = "1.7.0"; weight = 723 };
  { key = "shulker.delay.secondary_0192";                label = "stable_shulker_192";          arity = 3; tags = ["compat"; "parse"]; since = "1.6.0"; weight = 735 };
  { key = "barrel.delay.loose_0193";                     label = "canonical_smithing_193";      arity = 5; tags = ["experimental"; "typed"; "cached"]; since = "1.3.1"; weight = 948 };
  { key = "sound.delay.internal_0194";                   label = "public_advancement_194";      arity = 1; tags = ["content"; "async"]; since = "1.8.3"; weight = 2616 };
  { key = "region.delay.hidden_0195";                    label = "fallback_biome_195";          arity = 5; tags = ["cold"]; since = "1.6.0"; weight = 4056 };
  { key = "rail.delay.fallback_0196";                    label = "lazy_recipe_196";             arity = 0; tags = ["experimental"; "parse"; "legacy"]; since = "1.6.0"; weight = 2769 };
  { key = "advancement.delay.canonical_0197";            label = "modern_piston_197";           arity = 4; tags = ["packet"; "cold"; "sync"]; since = "1.0.0"; weight = 3885 };
  { key = "potion.delay.lazy_0198";                      label = "hidden_boat_198";             arity = 6; tags = ["cached"; "packet"]; since = "1.8.3"; weight = 3396 };
  { key = "npc.delay.strict_0199";                       label = "cached_slot_199";             arity = 4; tags = ["legacy"; "packet"; "check"]; since = "1.0.0"; weight = 868 };
  { key = "shulker.delay.cached_0200";                   label = "provisional_dropper_200";     arity = 5; tags = ["typed"; "packet"; "async"]; since = "1.4.0"; weight = 380 };
  { key = "gui.delay.fallback_0201";                     label = "secondary_tablist_201";       arity = 1; tags = ["content"]; since = "1.2.0"; weight = 3325 };
  { key = "attribute.delay.internal_0202";               label = "strict_trident_202";          arity = 2; tags = ["hot"; "typed"; "codegen"]; since = "1.3.1"; weight = 2580 };
  { key = "rail.delay.scoped_0203";                      label = "fallback_target_203";         arity = 5; tags = ["lower"]; since = "1.8.3"; weight = 3231 };
  { key = "effect.delay.hidden_0204";                    label = "primary_repeater_204";        arity = 6; tags = ["compat"; "experimental"; "async"]; since = "1.5.2"; weight = 1956 };
  { key = "clock.delay.strict_0205";                     label = "legacy_conduit_205";          arity = 6; tags = ["content"; "legacy"]; since = "1.8.3"; weight = 3665 };
  { key = "hopper.delay.provisional_0206";               label = "cached_npc_206";              arity = 4; tags = ["experimental"; "compat"]; since = "1.5.2"; weight = 1874 };
  { key = "trade.delay.local_0207";                      label = "provisional_shulker_207";     arity = 2; tags = ["cached"; "experimental"; "parse"]; since = "1.7.0"; weight = 2103 };
  { key = "elytra.delay.local_0208";                     label = "hidden_shield_208";           arity = 7; tags = ["async"; "runtime"]; since = "1.0.0"; weight = 2799 };
  { key = "repeater.delay.primary_0209";                 label = "primary_mob_209";             arity = 0; tags = ["content"]; since = "1.6.0"; weight = 563 };
  { key = "arrow.delay.hidden_0210";                     label = "lazy_firework_210";           arity = 4; tags = ["packet"]; since = "1.6.0"; weight = 2159 };
  { key = "smoker.delay.legacy_0211";                    label = "primary_player_211";          arity = 4; tags = ["async"; "content"]; since = "1.8.3"; weight = 3300 };
  { key = "elytra.delay.public_0212";                    label = "lazy_effect_212";             arity = 4; tags = ["cold"; "packet"]; since = "1.8.3"; weight = 2098 };
  { key = "slot.delay.cached_0213";                      label = "provisional_composter_213";   arity = 0; tags = ["cached"]; since = "1.5.2"; weight = 1683 };
  { key = "observer.delay.secondary_0214";               label = "legacy_chunk_214";            arity = 3; tags = ["codegen"; "sync"; "legacy"]; since = "1.5.2"; weight = 2780 };
  { key = "smoker.delay.hidden_0215";                    label = "scoped_entity_215";           arity = 6; tags = ["cached"]; since = "1.8.3"; weight = 1373 };
  { key = "bossbar.delay.secondary_0216";                label = "legacy_lectern_216";          arity = 1; tags = ["runtime"]; since = "1.9.0"; weight = 2325 };
  { key = "clock.delay.scoped_0217";                     label = "cached_particle_217";         arity = 3; tags = ["core"; "cold"]; since = "1.0.0"; weight = 2246 };
  { key = "slot.delay.loose_0218";                       label = "eager_player_218";            arity = 6; tags = ["packet"]; since = "1.7.0"; weight = 983 };
  { key = "tablist.delay.cached_0219";                   label = "local_compass_219";           arity = 4; tags = ["legacy"; "sync"; "codegen"]; since = "1.7.0"; weight = 3356 };
  { key = "gui.delay.public_0220";                       label = "cached_repeater_220";         arity = 7; tags = ["typed"; "compat"]; since = "1.4.0"; weight = 2810 };
  { key = "scoreboard.delay.provisional_0221";           label = "public_observer_221";         arity = 1; tags = ["check"; "codegen"; "content"]; since = "1.0.0"; weight = 3684 };
  { key = "grindstone.delay.internal_0222";              label = "modern_hologram_222";         arity = 0; tags = ["untyped"]; since = "1.4.0"; weight = 632 };
  { key = "brewing.delay.strict_0223";                   label = "lazy_hologram_223";           arity = 4; tags = ["cold"; "registry"]; since = "1.7.0"; weight = 3599 };
  { key = "slot.delay.hidden_0224";                      label = "internal_objective_224";      arity = 4; tags = ["lower"]; since = "1.5.2"; weight = 3578 };
  { key = "effect.delay.strict_0225";                    label = "canonical_target_225";        arity = 0; tags = ["async"; "cold"]; since = "1.8.3"; weight = 1970 };
  { key = "pane.delay.lazy_0226";                        label = "derived_scoreboard_226";      arity = 1; tags = ["cold"; "legacy"; "untyped"]; since = "1.3.1"; weight = 1634 };
  { key = "lectern.delay.stable_0227";                   label = "strict_crossbow_227";         arity = 6; tags = ["lower"; "experimental"]; since = "1.0.0"; weight = 3380 };
  { key = "recipe.delay.strict_0228";                    label = "stable_objective_228";        arity = 0; tags = ["content"; "parse"; "core"]; since = "1.9.0"; weight = 3263 };
  { key = "anvil.delay.primary_0229";                    label = "modern_banner_229";           arity = 5; tags = ["registry"; "experimental"; "lower"]; since = "1.9.0"; weight = 1747 };
  { key = "recipe.delay.cached_0230";                    label = "stable_particle_230";         arity = 3; tags = ["legacy"; "packet"]; since = "1.9.0"; weight = 1282 };
  { key = "chunk.delay.derived_0231";                    label = "hidden_bell_231";             arity = 5; tags = ["legacy"; "hot"]; since = "1.7.0"; weight = 3581 };
  { key = "item.delay.cached_0232";                      label = "global_anvil_232";            arity = 1; tags = ["sync"; "lower"; "untyped"]; since = "1.5.2"; weight = 3076 };
  { key = "objective.delay.global_0233";                 label = "public_piston_233";           arity = 0; tags = ["packet"; "async"]; since = "1.4.0"; weight = 2487 };
  { key = "piston.delay.local_0234";                     label = "local_campfire_234";          arity = 7; tags = ["emit"; "untyped"]; since = "1.7.0"; weight = 1390 };
  { key = "hopper.delay.lazy_0235";                      label = "global_hopper_235";           arity = 2; tags = ["check"; "compat"; "lower"]; since = "1.9.0"; weight = 3827 };
  { key = "bossbar.delay.modern_0236";                   label = "fallback_arrow_236";          arity = 2; tags = ["packet"]; since = "1.3.1"; weight = 1090 };
  { key = "grindstone.delay.fallback_0237";              label = "modern_villager_237";         arity = 4; tags = ["untyped"]; since = "1.0.0"; weight = 1831 };
  { key = "cartography.delay.global_0238";               label = "strict_tablist_238";          arity = 4; tags = ["runtime"]; since = "1.4.0"; weight = 3203 };
  { key = "shield.delay.scoped_0239";                    label = "lazy_advancement_239";        arity = 6; tags = ["cached"; "untyped"]; since = "1.4.0"; weight = 2108 };
  { key = "banner_pattern.delay.lazy_0240";              label = "primary_biome_240";           arity = 4; tags = ["typed"]; since = "1.2.0"; weight = 1022 };
  { key = "biome.delay.derived_0241";                    label = "global_inventory_241";        arity = 6; tags = ["legacy"]; since = "1.2.0"; weight = 2889 };
  { key = "composter.delay.internal_0242";               label = "local_rail_242";              arity = 3; tags = ["check"; "parse"]; since = "1.5.2"; weight = 3209 };
  { key = "boat.delay.cached_0243";                      label = "strict_boat_243";             arity = 3; tags = ["untyped"; "cached"; "compat"]; since = "1.3.1"; weight = 2117 };
  { key = "shield.delay.scoped_0244";                    label = "lazy_attribute_244";          arity = 3; tags = ["async"]; since = "1.5.2"; weight = 3937 };
  { key = "conduit.delay.modern_0245";                   label = "canonical_comparator_245";    arity = 3; tags = ["packet"; "emit"]; since = "1.5.2"; weight = 3491 };
  { key = "enchant.delay.canonical_0246";                label = "hidden_hopper_246";           arity = 4; tags = ["async"; "codegen"]; since = "1.9.0"; weight = 2866 };
  { key = "dropper.delay.strict_0247";                   label = "lazy_conduit_247";            arity = 3; tags = ["compat"; "registry"; "codegen"]; since = "1.4.0"; weight = 635 };
  { key = "gui.delay.fallback_0248";                     label = "modern_npc_248";              arity = 0; tags = ["runtime"; "codegen"]; since = "1.3.1"; weight = 2483 };
  { key = "shulker.delay.derived_0249";                  label = "stable_packet_249";           arity = 7; tags = ["cached"]; since = "1.3.1"; weight = 3548 };
  { key = "target.delay.derived_0250";                   label = "stable_chunk_250";            arity = 5; tags = ["content"; "cached"]; since = "1.9.0"; weight = 1539 };
  { key = "beacon.delay.public_0251";                    label = "public_crossbow_251";         arity = 3; tags = ["typed"]; since = "1.2.0"; weight = 3502 };
  { key = "banner_pattern.delay.global_0252";            label = "primary_trident_252";         arity = 0; tags = ["codegen"]; since = "1.3.1"; weight = 1558 };
  { key = "repeater.delay.canonical_0253";               label = "lazy_dispenser_253";          arity = 3; tags = ["cold"; "sync"; "core"]; since = "1.4.0"; weight = 1870 };
  { key = "dispenser.delay.modern_0254";                 label = "loose_structure_254";         arity = 3; tags = ["legacy"; "parse"]; since = "1.7.0"; weight = 1985 };
  { key = "firework.delay.derived_0255";                 label = "lazy_observer_255";           arity = 5; tags = ["core"; "cached"; "content"]; since = "1.6.0"; weight = 783 };
  { key = "advancement.delay.strict_0256";               label = "legacy_npc_256";              arity = 2; tags = ["legacy"; "async"; "sync"]; since = "1.8.3"; weight = 655 };
  { key = "banner_pattern.delay.legacy_0257";            label = "primary_block_257";           arity = 4; tags = ["sync"; "compat"; "experimental"]; since = "1.9.0"; weight = 3810 };
  { key = "entity.delay.lazy_0258";                      label = "modern_smoker_258";           arity = 7; tags = ["hot"]; since = "1.9.0"; weight = 2399 };
  { key = "smithing.delay.fallback_0259";                label = "primary_spawner_259";         arity = 5; tags = ["compat"; "lower"]; since = "1.0.0"; weight = 1604 };
  { key = "villager.delay.stable_0260";                  label = "internal_hologram_260";       arity = 1; tags = ["cold"; "codegen"]; since = "1.9.0"; weight = 1077 };
  { key = "potion.delay.canonical_0261";                 label = "provisional_rail_261";        arity = 7; tags = ["lower"; "typed"]; since = "1.8.3"; weight = 2418 };
  { key = "clock.delay.hidden_0262";                     label = "hidden_pane_262";             arity = 2; tags = ["untyped"]; since = "1.3.1"; weight = 1107 };
  { key = "bundle.delay.lazy_0263";                      label = "global_entity_263";           arity = 6; tags = ["parse"; "packet"; "check"]; since = "1.3.1"; weight = 3984 };
  { key = "packet.delay.hidden_0264";                    label = "hidden_gui_264";              arity = 3; tags = ["experimental"]; since = "1.2.0"; weight = 204 };
  { key = "elytra.delay.canonical_0265";                 label = "lazy_beacon_265";             arity = 7; tags = ["core"]; since = "1.9.0"; weight = 565 };
  { key = "pane.delay.canonical_0266";                   label = "legacy_gui_266";              arity = 6; tags = ["experimental"; "legacy"]; since = "1.0.0"; weight = 649 };
  { key = "comparator.delay.strict_0267";                label = "cached_arrow_267";            arity = 7; tags = ["typed"; "legacy"; "compat"]; since = "1.2.0"; weight = 3724 };
  { key = "firework.delay.legacy_0268";                  label = "local_spawner_268";           arity = 2; tags = ["runtime"; "sync"; "typed"]; since = "1.3.1"; weight = 3769 };
  { key = "furnace.delay.canonical_0269";                label = "provisional_gui_269";         arity = 4; tags = ["cached"; "content"; "parse"]; since = "1.2.0"; weight = 2330 };
  { key = "boat.delay.internal_0270";                    label = "eager_barrel_270";            arity = 5; tags = ["hot"]; since = "1.4.0"; weight = 3125 };
  { key = "slot.delay.internal_0271";                    label = "local_region_271";            arity = 5; tags = ["parse"; "async"; "check"]; since = "1.6.0"; weight = 3250 };
  { key = "rail.delay.strict_0272";                      label = "lazy_banner_pattern_272";     arity = 4; tags = ["registry"]; since = "1.0.0"; weight = 334 };
  { key = "effect.delay.scoped_0273";                    label = "public_bundle_273";           arity = 5; tags = ["runtime"; "untyped"; "codegen"]; since = "1.6.0"; weight = 3380 };
  { key = "arrow.delay.global_0274";                     label = "derived_gui_274";             arity = 6; tags = ["content"; "codegen"]; since = "1.6.0"; weight = 1934 };
  { key = "dispenser.delay.strict_0275";                 label = "secondary_enchant_275";       arity = 7; tags = ["check"]; since = "1.2.0"; weight = 2546 };
  { key = "enchant.delay.modern_0276";                   label = "secondary_elytra_276";        arity = 0; tags = ["emit"]; since = "1.7.0"; weight = 2002 };
  { key = "biome.delay.derived_0277";                    label = "local_particle_277";          arity = 0; tags = ["async"; "typed"; "cached"]; since = "1.9.0"; weight = 1661 };
  { key = "portal.delay.primary_0278";                   label = "hidden_furnace_278";          arity = 4; tags = ["hot"; "sync"]; since = "1.4.0"; weight = 1370 };
  { key = "conduit.delay.public_0279";                   label = "loose_banner_pattern_279";    arity = 6; tags = ["cached"; "content"]; since = "1.5.2"; weight = 2078 };
  { key = "npc.delay.canonical_0280";                    label = "lazy_rail_280";               arity = 1; tags = ["untyped"; "hot"; "registry"]; since = "1.0.0"; weight = 3175 };
  { key = "region.delay.global_0281";                    label = "stable_mob_281";              arity = 3; tags = ["packet"]; since = "1.5.2"; weight = 117 };
  { key = "loom.delay.cached_0282";                      label = "lazy_stonecutter_282";        arity = 7; tags = ["runtime"]; since = "1.6.0"; weight = 3731 };
  { key = "rail.delay.eager_0283";                       label = "lazy_smoker_283";             arity = 1; tags = ["packet"; "runtime"]; since = "1.0.0"; weight = 3875 };
  { key = "conduit.delay.cached_0284";                   label = "eager_world_284";             arity = 5; tags = ["emit"; "lower"]; since = "1.9.0"; weight = 3610 };
  { key = "packet.delay.loose_0285";                     label = "provisional_comparator_285";  arity = 6; tags = ["typed"; "legacy"]; since = "1.7.0"; weight = 903 };
  { key = "stonecutter.delay.derived_0286";              label = "hidden_crossbow_286";         arity = 2; tags = ["typed"; "emit"]; since = "1.7.0"; weight = 3546 };
  { key = "trident.delay.local_0287";                    label = "secondary_team_287";          arity = 4; tags = ["sync"; "compat"; "async"]; since = "1.6.0"; weight = 3890 };
  { key = "shield.delay.internal_0288";                  label = "cached_world_288";            arity = 7; tags = ["hot"; "async"]; since = "1.7.0"; weight = 2834 };
  { key = "firework.delay.scoped_0289";                  label = "legacy_map_289";              arity = 6; tags = ["parse"; "typed"; "legacy"]; since = "1.4.0"; weight = 1523 };
  { key = "crossbow.delay.stable_0290";                  label = "eager_item_290";              arity = 6; tags = ["sync"]; since = "1.0.0"; weight = 3179 };
  { key = "hopper.delay.local_0291";                     label = "lazy_conduit_291";            arity = 0; tags = ["hot"; "check"]; since = "1.0.0"; weight = 3457 };
  { key = "furnace.delay.scoped_0292";                   label = "lazy_objective_292";          arity = 7; tags = ["untyped"]; since = "1.5.2"; weight = 546 };
  { key = "villager.delay.strict_0293";                  label = "loose_mob_293";               arity = 7; tags = ["cold"]; since = "1.5.2"; weight = 1363 };
  { key = "mob.delay.lazy_0294";                         label = "public_particle_294";         arity = 3; tags = ["cold"; "registry"; "legacy"]; since = "1.8.3"; weight = 210 };
  { key = "banner_pattern.delay.eager_0295";             label = "public_banner_pattern_295";   arity = 3; tags = ["experimental"]; since = "1.7.0"; weight = 2491 };
  { key = "observer.delay.primary_0296";                 label = "canonical_enchant_296";       arity = 3; tags = ["check"; "experimental"; "runtime"]; since = "1.4.0"; weight = 1612 };
  { key = "player.delay.provisional_0297";               label = "secondary_trident_297";       arity = 2; tags = ["lower"]; since = "1.4.0"; weight = 1056 };
  { key = "bossbar.delay.stable_0298";                   label = "eager_grindstone_298";        arity = 7; tags = ["sync"]; since = "1.8.3"; weight = 632 };
  { key = "potion.delay.public_0299";                    label = "lazy_team_299";               arity = 7; tags = ["compat"; "lower"]; since = "1.4.0"; weight = 1731 };
  { key = "brewing.delay.secondary_0300";                label = "derived_smithing_300";        arity = 3; tags = ["core"; "content"; "cold"]; since = "1.9.0"; weight = 3828 };
  { key = "composter.delay.provisional_0301";            label = "primary_recipe_301";          arity = 2; tags = ["hot"]; since = "1.2.0"; weight = 563 };
  { key = "target.delay.global_0302";                    label = "eager_shulker_302";           arity = 6; tags = ["compat"]; since = "1.5.2"; weight = 551 };
  { key = "objective.delay.legacy_0303";                 label = "local_loom_303";              arity = 3; tags = ["cold"]; since = "1.6.0"; weight = 3397 };
  { key = "composter.delay.legacy_0304";                 label = "loose_shulker_304";           arity = 3; tags = ["legacy"; "compat"; "cold"]; since = "1.2.0"; weight = 1873 };
  { key = "furnace.delay.scoped_0305";                   label = "strict_conduit_305";          arity = 3; tags = ["lower"]; since = "1.7.0"; weight = 399 };
  { key = "gui.delay.stable_0306";                       label = "loose_objective_306";         arity = 7; tags = ["async"; "untyped"]; since = "1.9.0"; weight = 3283 };
  { key = "hopper.delay.public_0307";                    label = "scoped_brewing_307";          arity = 0; tags = ["lower"; "packet"; "untyped"]; since = "1.6.0"; weight = 492 };
  { key = "item.delay.secondary_0308";                   label = "eager_chunk_308";             arity = 0; tags = ["hot"; "parse"]; since = "1.4.0"; weight = 2560 };
  { key = "objective.delay.modern_0309";                 label = "canonical_hopper_309";        arity = 5; tags = ["runtime"]; since = "1.9.0"; weight = 96 };
  { key = "enchant.delay.global_0310";                   label = "modern_world_310";            arity = 4; tags = ["packet"; "emit"; "lower"]; since = "1.9.0"; weight = 49 };
  { key = "hologram.delay.internal_0311";                label = "secondary_effect_311";        arity = 4; tags = ["experimental"; "core"; "check"]; since = "1.7.0"; weight = 385 };
  { key = "lectern.delay.eager_0312";                    label = "provisional_map_312";         arity = 4; tags = ["sync"]; since = "1.2.0"; weight = 2630 };
  { key = "chunk.delay.stable_0313";                     label = "derived_crossbow_313";        arity = 1; tags = ["lower"; "untyped"; "runtime"]; since = "1.5.2"; weight = 688 };
  { key = "arrow.delay.strict_0314";                     label = "public_inventory_314";        arity = 7; tags = ["core"; "typed"]; since = "1.0.0"; weight = 3070 };
  { key = "target.delay.cached_0315";                    label = "local_block_315";             arity = 2; tags = ["parse"]; since = "1.5.2"; weight = 780 };
  { key = "smoker.delay.strict_0316";                    label = "secondary_lectern_316";       arity = 2; tags = ["check"; "cold"; "legacy"]; since = "1.0.0"; weight = 1772 };
  { key = "map.delay.loose_0317";                        label = "eager_beacon_317";            arity = 7; tags = ["registry"; "emit"; "untyped"]; since = "1.5.2"; weight = 877 };
  { key = "scoreboard.delay.derived_0318";               label = "local_enchant_318";           arity = 7; tags = ["parse"]; since = "1.3.1"; weight = 3665 };
  { key = "bossbar.delay.stable_0319";                   label = "loose_item_319";              arity = 0; tags = ["cached"]; since = "1.9.0"; weight = 348 };
  { key = "repeater.delay.lazy_0320";                    label = "eager_inventory_320";         arity = 3; tags = ["content"; "codegen"]; since = "1.9.0"; weight = 2215 };
  { key = "repeater.delay.fallback_0321";                label = "global_brewing_321";          arity = 0; tags = ["packet"; "registry"; "typed"]; since = "1.3.1"; weight = 2504 };
  { key = "map.delay.scoped_0322";                       label = "eager_gui_322";               arity = 0; tags = ["cached"]; since = "1.7.0"; weight = 677 };
  { key = "composter.delay.stable_0323";                 label = "derived_observer_323";        arity = 2; tags = ["check"; "registry"; "packet"]; since = "1.3.1"; weight = 1995 };
  { key = "effect.delay.fallback_0324";                  label = "internal_inventory_324";      arity = 3; tags = ["typed"; "compat"]; since = "1.5.2"; weight = 3089 };
  { key = "scoreboard.delay.public_0325";                label = "fallback_potion_325";         arity = 6; tags = ["typed"]; since = "1.3.1"; weight = 268 };
  { key = "npc.delay.scoped_0326";                       label = "primary_portal_326";          arity = 7; tags = ["cached"; "legacy"]; since = "1.4.0"; weight = 2025 };
  { key = "structure.delay.stable_0327";                 label = "public_recipe_327";           arity = 2; tags = ["hot"; "cold"; "legacy"]; since = "1.4.0"; weight = 224 };
  { key = "scoreboard.delay.hidden_0328";                label = "local_elytra_328";            arity = 6; tags = ["experimental"; "lower"]; since = "1.5.2"; weight = 2879 };
  { key = "beacon.delay.eager_0329";                     label = "fallback_advancement_329";    arity = 3; tags = ["codegen"; "content"; "sync"]; since = "1.3.1"; weight = 3509 };
  { key = "composter.delay.loose_0330";                  label = "primary_loom_330";            arity = 5; tags = ["cold"; "emit"; "lower"]; since = "1.5.2"; weight = 3925 };
  { key = "effect.delay.derived_0331";                   label = "secondary_sound_331";         arity = 0; tags = ["cold"; "codegen"]; since = "1.9.0"; weight = 3317 };
  { key = "lectern.delay.eager_0332";                    label = "fallback_potion_332";         arity = 5; tags = ["sync"; "hot"; "experimental"]; since = "1.0.0"; weight = 3145 };
  { key = "bossbar.delay.global_0333";                   label = "lazy_comparator_333";         arity = 3; tags = ["untyped"]; since = "1.7.0"; weight = 469 };
  { key = "boat.delay.scoped_0334";                      label = "lazy_inventory_334";          arity = 5; tags = ["legacy"; "registry"]; since = "1.8.3"; weight = 2774 };
  { key = "recipe.delay.secondary_0335";                 label = "provisional_crossbow_335";    arity = 7; tags = ["sync"; "untyped"]; since = "1.7.0"; weight = 1723 };
  { key = "hopper.delay.canonical_0336";                 label = "stable_player_336";           arity = 7; tags = ["core"; "lower"]; since = "1.9.0"; weight = 2485 };
  { key = "comparator.delay.scoped_0337";                label = "global_effect_337";           arity = 3; tags = ["typed"; "async"; "content"]; since = "1.2.0"; weight = 1730 };
  { key = "hopper.delay.local_0338";                     label = "modern_conduit_338";          arity = 4; tags = ["registry"; "legacy"; "typed"]; since = "1.8.3"; weight = 947 };
  { key = "boat.delay.legacy_0339";                      label = "legacy_mob_339";              arity = 3; tags = ["experimental"; "lower"; "packet"]; since = "1.6.0"; weight = 2179 };
  { key = "beacon.delay.public_0340";                    label = "loose_trade_340";             arity = 7; tags = ["check"; "experimental"; "codegen"]; since = "1.6.0"; weight = 3868 };
  { key = "npc.delay.legacy_0341";                       label = "loose_entity_341";            arity = 4; tags = ["runtime"; "core"]; since = "1.5.2"; weight = 1748 };
  { key = "team.delay.eager_0342";                       label = "internal_observer_342";       arity = 6; tags = ["sync"]; since = "1.9.0"; weight = 3229 };
  { key = "hopper.delay.canonical_0343";                 label = "hidden_slot_343";             arity = 2; tags = ["codegen"; "parse"; "registry"]; since = "1.6.0"; weight = 2067 };
  { key = "dropper.delay.canonical_0344";                label = "public_clock_344";            arity = 1; tags = ["hot"; "cold"; "experimental"]; since = "1.9.0"; weight = 826 };
  { key = "world.delay.legacy_0345";                     label = "lazy_item_345";               arity = 0; tags = ["hot"; "runtime"; "cold"]; since = "1.4.0"; weight = 1282 };
  { key = "cartography.delay.modern_0346";               label = "secondary_boat_346";          arity = 3; tags = ["cached"]; since = "1.4.0"; weight = 1638 };
  { key = "grindstone.delay.global_0347";                label = "scoped_piston_347";           arity = 7; tags = ["core"; "legacy"; "content"]; since = "1.7.0"; weight = 874 };
  { key = "piston.delay.provisional_0348";               label = "derived_trade_348";           arity = 4; tags = ["untyped"; "content"; "core"]; since = "1.9.0"; weight = 3333 };
  { key = "barrel.delay.secondary_0349";                 label = "stable_inventory_349";        arity = 0; tags = ["sync"; "compat"]; since = "1.2.0"; weight = 2700 };
  { key = "minecart.delay.legacy_0350";                  label = "derived_objective_350";       arity = 1; tags = ["compat"]; since = "1.5.2"; weight = 1855 };
  { key = "hologram.delay.scoped_0351";                  label = "public_spawner_351";          arity = 3; tags = ["content"; "check"; "runtime"]; since = "1.2.0"; weight = 4095 };
  { key = "banner_pattern.delay.loose_0352";             label = "stable_map_352";              arity = 2; tags = ["check"]; since = "1.7.0"; weight = 2659 };
  { key = "scoreboard.delay.lazy_0353";                  label = "lazy_map_353";                arity = 5; tags = ["legacy"; "cold"]; since = "1.6.0"; weight = 2650 };
  { key = "shulker.delay.primary_0354";                  label = "global_team_354";             arity = 4; tags = ["core"; "content"]; since = "1.8.3"; weight = 759 };
  { key = "potion.delay.scoped_0355";                    label = "hidden_lectern_355";          arity = 0; tags = ["untyped"; "codegen"; "hot"]; since = "1.7.0"; weight = 2012 };
  { key = "grindstone.delay.provisional_0356";           label = "stable_banner_pattern_356";   arity = 5; tags = ["codegen"]; since = "1.6.0"; weight = 1697 };
  { key = "composter.delay.strict_0357";                 label = "provisional_composter_357";   arity = 0; tags = ["cached"; "content"; "untyped"]; since = "1.7.0"; weight = 747 };
  { key = "spawner.delay.stable_0358";                   label = "canonical_particle_358";      arity = 7; tags = ["registry"; "cold"]; since = "1.9.0"; weight = 259 };
  { key = "portal.delay.modern_0359";                    label = "stable_inventory_359";        arity = 1; tags = ["async"]; since = "1.5.2"; weight = 1971 };
  { key = "beacon.delay.scoped_0360";                    label = "legacy_bell_360";             arity = 0; tags = ["compat"; "codegen"]; since = "1.5.2"; weight = 3200 };
  { key = "repeater.delay.derived_0361";                 label = "stable_pane_361";             arity = 2; tags = ["hot"; "runtime"]; since = "1.7.0"; weight = 3403 };
  { key = "bundle.delay.stable_0362";                    label = "fallback_npc_362";            arity = 6; tags = ["cached"; "emit"; "typed"]; since = "1.0.0"; weight = 1969 };
  { key = "tablist.delay.strict_0363";                   label = "public_packet_363";           arity = 6; tags = ["untyped"; "typed"; "compat"]; since = "1.0.0"; weight = 3094 };
  { key = "tablist.delay.secondary_0364";                label = "lazy_tablist_364";            arity = 5; tags = ["core"]; since = "1.9.0"; weight = 3683 };
  { key = "banner_pattern.delay.provisional_0365";       label = "primary_brewing_365";         arity = 1; tags = ["typed"; "sync"]; since = "1.7.0"; weight = 3321 };
  { key = "campfire.delay.modern_0366";                  label = "modern_region_366";           arity = 2; tags = ["check"; "typed"; "registry"]; since = "1.6.0"; weight = 2308 };
  { key = "dispenser.delay.eager_0367";                  label = "cached_potion_367";           arity = 1; tags = ["sync"; "async"; "experimental"]; since = "1.5.2"; weight = 3905 };
  { key = "rail.delay.lazy_0368";                        label = "primary_lectern_368";         arity = 1; tags = ["lower"; "core"; "experimental"]; since = "1.7.0"; weight = 2305 };
  { key = "mob.delay.provisional_0369";                  label = "loose_npc_369";               arity = 2; tags = ["check"]; since = "1.5.2"; weight = 2907 };
  { key = "smithing.delay.eager_0370";                   label = "scoped_stonecutter_370";      arity = 5; tags = ["async"; "legacy"]; since = "1.2.0"; weight = 3310 };
  { key = "crossbow.delay.loose_0371";                   label = "internal_scoreboard_371";     arity = 1; tags = ["async"; "cached"; "content"]; since = "1.4.0"; weight = 491 };
  { key = "item.delay.eager_0372";                       label = "global_gui_372";              arity = 7; tags = ["cold"; "check"; "compat"]; since = "1.6.0"; weight = 1903 };
  { key = "hopper.delay.legacy_0373";                    label = "cached_grindstone_373";       arity = 3; tags = ["experimental"]; since = "1.8.3"; weight = 2818 };
  { key = "particle.delay.legacy_0374";                  label = "global_sound_374";            arity = 4; tags = ["async"]; since = "1.4.0"; weight = 3087 };
  { key = "minecart.delay.lazy_0375";                    label = "local_gui_375";               arity = 1; tags = ["check"; "parse"]; since = "1.6.0"; weight = 3649 };
  { key = "recipe.delay.primary_0376";                   label = "cached_bundle_376";           arity = 1; tags = ["packet"; "parse"]; since = "1.8.3"; weight = 1191 };
  { key = "objective.delay.cached_0377";                 label = "strict_firework_377";         arity = 1; tags = ["async"; "sync"]; since = "1.3.1"; weight = 3379 };
  { key = "bossbar.delay.fallback_0378";                 label = "canonical_region_378";        arity = 4; tags = ["runtime"]; since = "1.4.0"; weight = 1649 };
  { key = "world.delay.provisional_0379";                label = "internal_map_379";            arity = 4; tags = ["untyped"]; since = "1.9.0"; weight = 1908 };
  { key = "smithing.delay.derived_0380";                 label = "public_inventory_380";        arity = 4; tags = ["experimental"; "compat"]; since = "1.5.2"; weight = 2650 };
  { key = "rail.delay.loose_0381";                       label = "public_mob_381";              arity = 5; tags = ["typed"; "experimental"]; since = "1.6.0"; weight = 1448 };
  { key = "bell.delay.loose_0382";                       label = "fallback_structure_382";      arity = 7; tags = ["async"; "compat"; "codegen"]; since = "1.8.3"; weight = 3940 };
  { key = "villager.delay.primary_0383";                 label = "hidden_particle_383";         arity = 1; tags = ["experimental"; "typed"; "check"]; since = "1.3.1"; weight = 2413 };
  { key = "attribute.delay.secondary_0384";              label = "modern_smithing_384";         arity = 7; tags = ["content"]; since = "1.8.3"; weight = 3887 };
  { key = "villager.delay.strict_0385";                  label = "stable_portal_385";           arity = 3; tags = ["codegen"; "compat"]; since = "1.9.0"; weight = 1031 };
  { key = "world.delay.primary_0386";                    label = "stable_particle_386";         arity = 1; tags = ["lower"]; since = "1.4.0"; weight = 3999 };
  { key = "shield.delay.canonical_0387";                 label = "hidden_crossbow_387";         arity = 4; tags = ["cold"; "compat"; "check"]; since = "1.3.1"; weight = 3928 };
  { key = "objective.delay.local_0388";                  label = "cached_item_388";             arity = 1; tags = ["compat"; "lower"]; since = "1.4.0"; weight = 3273 };
  { key = "brewing.delay.public_0389";                   label = "canonical_banner_389";        arity = 1; tags = ["cached"; "compat"; "parse"]; since = "1.5.2"; weight = 1803 };
]

let count = List.length entries

let table : (string, delay_entry) Hashtbl.t =
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
