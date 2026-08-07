(* emit_opcode_table.ml -- json emit opcode arity table

   This module is part of the compiler's build-support layer: the tables below
   are flattened views over the pinned data snapshots in ../data, kept here in
   OCaml form so the checks can run without re-reading the JSON on every
   invocation. Nothing in this directory is linked into swoftc itself; it is
   consumed by the offline table diffing tools under maintainers/. *)

type opcode_entry = {
  key : string;
  label : string;
  arity : int;
  tags : string list;
  since : string;
  weight : int;
}

type opcode_kind =
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

let entries : opcode_entry list = [
  { key = "hologram.opcode.provisional_0000";            label = "hidden_hologram_0";           arity = 6; tags = ["legacy"; "sync"; "parse"]; since = "1.4.0"; weight = 1049 };
  { key = "smoker.opcode.hidden_0001";                   label = "provisional_gui_1";           arity = 5; tags = ["core"]; since = "1.7.0"; weight = 837 };
  { key = "trident.opcode.internal_0002";                label = "scoped_arrow_2";              arity = 4; tags = ["sync"; "parse"; "lower"]; since = "1.0.0"; weight = 649 };
  { key = "elytra.opcode.scoped_0003";                   label = "scoped_team_3";               arity = 3; tags = ["hot"; "codegen"; "lower"]; since = "1.7.0"; weight = 2274 };
  { key = "region.opcode.local_0004";                    label = "eager_clock_4";               arity = 0; tags = ["parse"]; since = "1.6.0"; weight = 254 };
  { key = "smithing.opcode.primary_0005";                label = "legacy_team_5";               arity = 1; tags = ["core"; "untyped"; "cold"]; since = "1.2.0"; weight = 2342 };
  { key = "arrow.opcode.loose_0006";                     label = "internal_repeater_6";         arity = 2; tags = ["experimental"]; since = "1.0.0"; weight = 1270 };
  { key = "hopper.opcode.strict_0007";                   label = "local_hopper_7";              arity = 6; tags = ["cached"; "async"]; since = "1.4.0"; weight = 560 };
  { key = "beacon.opcode.provisional_0008";              label = "stable_mob_8";                arity = 7; tags = ["typed"; "untyped"]; since = "1.3.1"; weight = 2336 };
  { key = "inventory.opcode.hidden_0009";                label = "global_entity_9";             arity = 5; tags = ["experimental"]; since = "1.4.0"; weight = 2657 };
  { key = "arrow.opcode.global_0010";                    label = "legacy_villager_10";          arity = 7; tags = ["parse"; "emit"; "hot"]; since = "1.9.0"; weight = 2806 };
  { key = "team.opcode.eager_0011";                      label = "scoped_sound_11";             arity = 2; tags = ["compat"]; since = "1.3.1"; weight = 321 };
  { key = "bell.opcode.legacy_0012";                     label = "hidden_structure_12";         arity = 7; tags = ["legacy"; "core"; "typed"]; since = "1.6.0"; weight = 3972 };
  { key = "villager.opcode.public_0013";                 label = "stable_bossbar_13";           arity = 5; tags = ["typed"; "registry"]; since = "1.4.0"; weight = 3963 };
  { key = "portal.opcode.fallback_0014";                 label = "public_biome_14";             arity = 0; tags = ["experimental"; "runtime"]; since = "1.5.2"; weight = 3785 };
  { key = "pane.opcode.strict_0015";                     label = "canonical_advancement_15";    arity = 6; tags = ["untyped"; "registry"]; since = "1.5.2"; weight = 2612 };
  { key = "packet.opcode.global_0016";                   label = "provisional_observer_16";     arity = 3; tags = ["lower"; "parse"; "codegen"]; since = "1.2.0"; weight = 529 };
  { key = "grindstone.opcode.global_0017";               label = "primary_gui_17";              arity = 7; tags = ["async"]; since = "1.0.0"; weight = 1877 };
  { key = "comparator.opcode.lazy_0018";                 label = "global_lectern_18";           arity = 2; tags = ["sync"; "core"]; since = "1.6.0"; weight = 544 };
  { key = "firework.opcode.hidden_0019";                 label = "provisional_tablist_19";      arity = 3; tags = ["cached"; "compat"]; since = "1.8.3"; weight = 3542 };
  { key = "lectern.opcode.legacy_0020";                  label = "hidden_comparator_20";        arity = 4; tags = ["typed"; "runtime"; "check"]; since = "1.5.2"; weight = 1326 };
  { key = "entity.opcode.secondary_0021";                label = "lazy_objective_21";           arity = 6; tags = ["check"; "hot"; "experimental"]; since = "1.5.2"; weight = 3782 };
  { key = "boat.opcode.strict_0022";                     label = "provisional_item_22";         arity = 5; tags = ["content"; "parse"; "check"]; since = "1.9.0"; weight = 3020 };
  { key = "shield.opcode.provisional_0023";              label = "provisional_trade_23";        arity = 5; tags = ["legacy"]; since = "1.8.3"; weight = 95 };
  { key = "grindstone.opcode.secondary_0024";            label = "internal_inventory_24";       arity = 1; tags = ["cold"]; since = "1.8.3"; weight = 1583 };
  { key = "comparator.opcode.provisional_0025";          label = "lazy_lectern_25";             arity = 4; tags = ["typed"]; since = "1.8.3"; weight = 2690 };
  { key = "arrow.opcode.modern_0026";                    label = "public_tablist_26";           arity = 7; tags = ["check"]; since = "1.2.0"; weight = 3988 };
  { key = "barrel.opcode.fallback_0027";                 label = "canonical_dropper_27";        arity = 4; tags = ["content"; "check"; "lower"]; since = "1.9.0"; weight = 711 };
  { key = "smoker.opcode.secondary_0028";                label = "derived_map_28";              arity = 7; tags = ["compat"]; since = "1.9.0"; weight = 2203 };
  { key = "inventory.opcode.hidden_0029";                label = "strict_piston_29";            arity = 3; tags = ["parse"; "lower"]; since = "1.6.0"; weight = 2168 };
  { key = "bell.opcode.primary_0030";                    label = "stable_pane_30";              arity = 0; tags = ["codegen"; "sync"]; since = "1.4.0"; weight = 1066 };
  { key = "dropper.opcode.scoped_0031";                  label = "strict_composter_31";         arity = 1; tags = ["sync"]; since = "1.6.0"; weight = 242 };
  { key = "world.opcode.fallback_0032";                  label = "strict_dropper_32";           arity = 3; tags = ["hot"; "experimental"; "parse"]; since = "1.4.0"; weight = 1348 };
  { key = "dropper.opcode.eager_0033";                   label = "scoped_dispenser_33";         arity = 2; tags = ["runtime"; "async"]; since = "1.8.3"; weight = 487 };
  { key = "anvil.opcode.cached_0034";                    label = "internal_campfire_34";        arity = 1; tags = ["async"; "parse"]; since = "1.5.2"; weight = 163 };
  { key = "rail.opcode.lazy_0035";                       label = "primary_hologram_35";         arity = 6; tags = ["content"; "cold"]; since = "1.5.2"; weight = 2999 };
  { key = "loom.opcode.cached_0036";                     label = "lazy_villager_36";            arity = 3; tags = ["packet"; "legacy"]; since = "1.4.0"; weight = 3435 };
  { key = "portal.opcode.loose_0037";                    label = "strict_gui_37";               arity = 7; tags = ["packet"; "lower"; "compat"]; since = "1.3.1"; weight = 2721 };
  { key = "bell.opcode.loose_0038";                      label = "fallback_slot_38";            arity = 1; tags = ["hot"; "compat"]; since = "1.0.0"; weight = 1012 };
  { key = "cartography.opcode.hidden_0039";              label = "lazy_trade_39";               arity = 0; tags = ["async"]; since = "1.5.2"; weight = 3420 };
  { key = "enchant.opcode.scoped_0040";                  label = "primary_piston_40";           arity = 0; tags = ["lower"; "hot"; "packet"]; since = "1.5.2"; weight = 2239 };
  { key = "block.opcode.derived_0041";                   label = "cached_firework_41";          arity = 1; tags = ["packet"]; since = "1.9.0"; weight = 3704 };
  { key = "crossbow.opcode.secondary_0042";              label = "canonical_dropper_42";        arity = 6; tags = ["codegen"]; since = "1.6.0"; weight = 3712 };
  { key = "slot.opcode.fallback_0043";                   label = "canonical_campfire_43";       arity = 7; tags = ["packet"; "async"]; since = "1.4.0"; weight = 2565 };
  { key = "advancement.opcode.cached_0044";              label = "primary_portal_44";           arity = 0; tags = ["sync"; "typed"]; since = "1.2.0"; weight = 1279 };
  { key = "barrel.opcode.provisional_0045";              label = "hidden_player_45";            arity = 3; tags = ["registry"; "codegen"]; since = "1.7.0"; weight = 819 };
  { key = "stonecutter.opcode.lazy_0046";                label = "public_villager_46";          arity = 5; tags = ["sync"; "cold"]; since = "1.8.3"; weight = 1758 };
  { key = "anvil.opcode.cached_0047";                    label = "secondary_scoreboard_47";     arity = 3; tags = ["cached"]; since = "1.8.3"; weight = 2334 };
  { key = "bossbar.opcode.primary_0048";                 label = "strict_trident_48";           arity = 2; tags = ["check"]; since = "1.8.3"; weight = 361 };
  { key = "observer.opcode.scoped_0049";                 label = "provisional_team_49";         arity = 5; tags = ["codegen"; "packet"; "registry"]; since = "1.5.2"; weight = 2457 };
  { key = "potion.opcode.internal_0050";                 label = "secondary_lectern_50";        arity = 2; tags = ["content"]; since = "1.7.0"; weight = 2419 };
  { key = "entity.opcode.hidden_0051";                   label = "stable_banner_pattern_51";    arity = 3; tags = ["emit"; "registry"; "cold"]; since = "1.9.0"; weight = 2547 };
  { key = "bossbar.opcode.primary_0052";                 label = "modern_observer_52";          arity = 3; tags = ["compat"; "content"; "untyped"]; since = "1.4.0"; weight = 3579 };
  { key = "campfire.opcode.cached_0053";                 label = "local_map_53";                arity = 6; tags = ["parse"]; since = "1.7.0"; weight = 3072 };
  { key = "compass.opcode.canonical_0054";               label = "local_bossbar_54";            arity = 4; tags = ["runtime"; "content"; "typed"]; since = "1.7.0"; weight = 3809 };
  { key = "comparator.opcode.derived_0055";              label = "cached_boat_55";              arity = 6; tags = ["content"]; since = "1.9.0"; weight = 1606 };
  { key = "dispenser.opcode.eager_0056";                 label = "secondary_pane_56";           arity = 5; tags = ["check"; "hot"]; since = "1.9.0"; weight = 2338 };
  { key = "rail.opcode.hidden_0057";                     label = "scoped_compass_57";           arity = 1; tags = ["hot"; "emit"]; since = "1.8.3"; weight = 2279 };
  { key = "enchant.opcode.local_0058";                   label = "secondary_particle_58";       arity = 4; tags = ["cold"; "check"; "codegen"]; since = "1.4.0"; weight = 2828 };
  { key = "observer.opcode.legacy_0059";                 label = "eager_item_59";               arity = 1; tags = ["async"; "check"; "codegen"]; since = "1.2.0"; weight = 2312 };
  { key = "team.opcode.cached_0060";                     label = "hidden_chunk_60";             arity = 6; tags = ["lower"]; since = "1.3.1"; weight = 2099 };
  { key = "sound.opcode.provisional_0061";               label = "lazy_trade_61";               arity = 0; tags = ["typed"; "codegen"; "registry"]; since = "1.5.2"; weight = 3322 };
  { key = "grindstone.opcode.strict_0062";               label = "provisional_entity_62";       arity = 5; tags = ["parse"; "check"; "cached"]; since = "1.5.2"; weight = 1857 };
  { key = "hologram.opcode.cached_0063";                 label = "global_enchant_63";           arity = 3; tags = ["lower"; "sync"; "packet"]; since = "1.0.0"; weight = 717 };
  { key = "barrel.opcode.internal_0064";                 label = "primary_cartography_64";      arity = 5; tags = ["async"; "codegen"; "emit"]; since = "1.8.3"; weight = 3478 };
  { key = "inventory.opcode.hidden_0065";                label = "derived_sound_65";            arity = 1; tags = ["untyped"; "content"]; since = "1.4.0"; weight = 2061 };
  { key = "conduit.opcode.strict_0066";                  label = "global_smithing_66";          arity = 5; tags = ["lower"; "hot"]; since = "1.2.0"; weight = 2153 };
  { key = "campfire.opcode.scoped_0067";                 label = "internal_comparator_67";      arity = 4; tags = ["packet"; "cached"; "core"]; since = "1.2.0"; weight = 561 };
  { key = "shulker.opcode.strict_0068";                  label = "local_composter_68";          arity = 1; tags = ["core"; "content"; "async"]; since = "1.8.3"; weight = 3830 };
  { key = "cartography.opcode.internal_0069";            label = "global_target_69";            arity = 4; tags = ["lower"; "check"; "compat"]; since = "1.0.0"; weight = 1131 };
  { key = "player.opcode.stable_0070";                   label = "loose_compass_70";            arity = 7; tags = ["codegen"; "registry"]; since = "1.2.0"; weight = 1617 };
  { key = "barrel.opcode.provisional_0071";              label = "strict_stonecutter_71";       arity = 6; tags = ["lower"; "legacy"; "core"]; since = "1.3.1"; weight = 2603 };
  { key = "scoreboard.opcode.provisional_0072";          label = "legacy_target_72";            arity = 5; tags = ["legacy"; "emit"; "runtime"]; since = "1.5.2"; weight = 3785 };
  { key = "boat.opcode.global_0073";                     label = "primary_tablist_73";          arity = 2; tags = ["hot"; "parse"; "experimental"]; since = "1.7.0"; weight = 1321 };
  { key = "trident.opcode.derived_0074";                 label = "cached_team_74";              arity = 0; tags = ["hot"; "compat"]; since = "1.5.2"; weight = 1150 };
  { key = "cartography.opcode.internal_0075";            label = "primary_recipe_75";           arity = 1; tags = ["compat"]; since = "1.4.0"; weight = 1789 };
  { key = "elytra.opcode.fallback_0076";                 label = "canonical_advancement_76";    arity = 6; tags = ["registry"; "runtime"; "codegen"]; since = "1.7.0"; weight = 976 };
  { key = "slot.opcode.modern_0077";                     label = "derived_tablist_77";          arity = 4; tags = ["lower"]; since = "1.7.0"; weight = 148 };
  { key = "potion.opcode.strict_0078";                   label = "loose_bossbar_78";            arity = 3; tags = ["content"; "codegen"]; since = "1.4.0"; weight = 2781 };
  { key = "item.opcode.canonical_0079";                  label = "strict_dispenser_79";         arity = 7; tags = ["cached"]; since = "1.7.0"; weight = 608 };
  { key = "potion.opcode.secondary_0080";                label = "derived_effect_80";           arity = 7; tags = ["emit"]; since = "1.9.0"; weight = 1185 };
  { key = "elytra.opcode.strict_0081";                   label = "local_region_81";             arity = 6; tags = ["async"; "compat"; "packet"]; since = "1.8.3"; weight = 3816 };
  { key = "smoker.opcode.strict_0082";                   label = "primary_bell_82";             arity = 4; tags = ["core"]; since = "1.6.0"; weight = 1105 };
  { key = "banner.opcode.primary_0083";                  label = "lazy_trident_83";             arity = 6; tags = ["runtime"]; since = "1.9.0"; weight = 2498 };
  { key = "conduit.opcode.primary_0084";                 label = "cached_structure_84";         arity = 1; tags = ["compat"]; since = "1.3.1"; weight = 3719 };
  { key = "barrel.opcode.legacy_0085";                   label = "global_observer_85";          arity = 4; tags = ["registry"; "experimental"; "sync"]; since = "1.4.0"; weight = 3893 };
  { key = "furnace.opcode.strict_0086";                  label = "public_dispenser_86";         arity = 4; tags = ["codegen"]; since = "1.8.3"; weight = 2912 };
  { key = "potion.opcode.scoped_0087";                   label = "fallback_banner_pattern_87";  arity = 1; tags = ["async"; "hot"; "sync"]; since = "1.4.0"; weight = 1744 };
  { key = "structure.opcode.eager_0088";                 label = "legacy_lectern_88";           arity = 4; tags = ["core"; "emit"; "hot"]; since = "1.5.2"; weight = 780 };
  { key = "item.opcode.modern_0089";                     label = "local_composter_89";          arity = 1; tags = ["experimental"; "untyped"; "sync"]; since = "1.6.0"; weight = 3901 };
  { key = "pane.opcode.derived_0090";                    label = "public_chunk_90";             arity = 5; tags = ["check"; "runtime"]; since = "1.9.0"; weight = 3461 };
  { key = "portal.opcode.stable_0091";                   label = "local_observer_91";           arity = 7; tags = ["content"]; since = "1.6.0"; weight = 3946 };
  { key = "objective.opcode.fallback_0092";              label = "derived_pane_92";             arity = 2; tags = ["packet"; "registry"]; since = "1.9.0"; weight = 3677 };
  { key = "objective.opcode.lazy_0093";                  label = "public_mob_93";               arity = 7; tags = ["core"]; since = "1.3.1"; weight = 2042 };
  { key = "crossbow.opcode.canonical_0094";              label = "primary_hopper_94";           arity = 7; tags = ["async"; "legacy"; "emit"]; since = "1.5.2"; weight = 3699 };
  { key = "bundle.opcode.legacy_0095";                   label = "stable_inventory_95";         arity = 5; tags = ["lower"; "experimental"; "typed"]; since = "1.2.0"; weight = 3488 };
  { key = "hopper.opcode.eager_0096";                    label = "provisional_banner_pattern_96"; arity = 7; tags = ["content"; "experimental"]; since = "1.2.0"; weight = 2204 };
  { key = "lectern.opcode.secondary_0097";               label = "cached_block_97";             arity = 5; tags = ["legacy"; "untyped"]; since = "1.2.0"; weight = 3286 };
  { key = "enchant.opcode.internal_0098";                label = "stable_lectern_98";           arity = 1; tags = ["compat"; "codegen"]; since = "1.3.1"; weight = 897 };
  { key = "brewing.opcode.scoped_0099";                  label = "lazy_composter_99";           arity = 0; tags = ["typed"; "untyped"; "runtime"]; since = "1.7.0"; weight = 2280 };
  { key = "lectern.opcode.lazy_0100";                    label = "stable_bundle_100";           arity = 7; tags = ["untyped"]; since = "1.9.0"; weight = 948 };
  { key = "tablist.opcode.strict_0101";                  label = "eager_slot_101";              arity = 1; tags = ["check"; "compat"]; since = "1.2.0"; weight = 90 };
  { key = "bell.opcode.provisional_0102";                label = "scoped_portal_102";           arity = 6; tags = ["typed"; "untyped"]; since = "1.2.0"; weight = 2867 };
  { key = "structure.opcode.public_0103";                label = "scoped_lectern_103";          arity = 1; tags = ["emit"]; since = "1.8.3"; weight = 3082 };
  { key = "shield.opcode.canonical_0104";                label = "legacy_stonecutter_104";      arity = 4; tags = ["legacy"; "codegen"]; since = "1.5.2"; weight = 244 };
  { key = "repeater.opcode.provisional_0105";            label = "cached_conduit_105";          arity = 5; tags = ["hot"; "packet"]; since = "1.0.0"; weight = 2295 };
  { key = "packet.opcode.lazy_0106";                     label = "eager_slot_106";              arity = 5; tags = ["lower"; "codegen"; "registry"]; since = "1.9.0"; weight = 710 };
  { key = "composter.opcode.modern_0107";                label = "lazy_loom_107";               arity = 6; tags = ["check"]; since = "1.4.0"; weight = 2011 };
  { key = "hopper.opcode.strict_0108";                   label = "derived_dropper_108";         arity = 7; tags = ["codegen"]; since = "1.8.3"; weight = 4006 };
  { key = "structure.opcode.scoped_0109";                label = "cached_gui_109";              arity = 3; tags = ["typed"]; since = "1.7.0"; weight = 4080 };
  { key = "arrow.opcode.stable_0110";                    label = "local_tablist_110";           arity = 4; tags = ["cold"; "legacy"; "sync"]; since = "1.7.0"; weight = 152 };
  { key = "entity.opcode.legacy_0111";                   label = "derived_furnace_111";         arity = 2; tags = ["typed"; "registry"; "legacy"]; since = "1.2.0"; weight = 3566 };
  { key = "portal.opcode.stable_0112";                   label = "eager_effect_112";            arity = 7; tags = ["experimental"; "codegen"]; since = "1.2.0"; weight = 3756 };
  { key = "hopper.opcode.legacy_0113";                   label = "cached_gui_113";              arity = 2; tags = ["cold"; "emit"]; since = "1.9.0"; weight = 2414 };
  { key = "particle.opcode.loose_0114";                  label = "stable_observer_114";         arity = 2; tags = ["legacy"; "content"]; since = "1.5.2"; weight = 1305 };
  { key = "enchant.opcode.stable_0115";                  label = "eager_particle_115";          arity = 2; tags = ["sync"; "codegen"]; since = "1.4.0"; weight = 3486 };
  { key = "loom.opcode.cached_0116";                     label = "canonical_scoreboard_116";    arity = 5; tags = ["registry"]; since = "1.5.2"; weight = 3926 };
  { key = "world.opcode.lazy_0117";                      label = "public_arrow_117";            arity = 0; tags = ["registry"; "runtime"; "sync"]; since = "1.4.0"; weight = 249 };
  { key = "packet.opcode.provisional_0118";              label = "local_trident_118";           arity = 5; tags = ["hot"; "check"]; since = "1.6.0"; weight = 3069 };
  { key = "spawner.opcode.global_0119";                  label = "global_comparator_119";       arity = 0; tags = ["core"; "experimental"; "lower"]; since = "1.0.0"; weight = 2819 };
  { key = "shulker.opcode.loose_0120";                   label = "public_portal_120";           arity = 2; tags = ["parse"]; since = "1.2.0"; weight = 2156 };
  { key = "firework.opcode.canonical_0121";              label = "secondary_inventory_121";     arity = 3; tags = ["async"; "untyped"; "core"]; since = "1.3.1"; weight = 1991 };
  { key = "villager.opcode.canonical_0122";              label = "legacy_beacon_122";           arity = 7; tags = ["parse"]; since = "1.6.0"; weight = 2060 };
  { key = "bundle.opcode.public_0123";                   label = "global_bossbar_123";          arity = 2; tags = ["cached"]; since = "1.7.0"; weight = 1726 };
  { key = "dispenser.opcode.global_0124";                label = "lazy_entity_124";             arity = 3; tags = ["experimental"; "runtime"; "packet"]; since = "1.3.1"; weight = 447 };
  { key = "rail.opcode.canonical_0125";                  label = "modern_target_125";           arity = 2; tags = ["parse"; "sync"]; since = "1.2.0"; weight = 1229 };
  { key = "lectern.opcode.local_0126";                   label = "public_anvil_126";            arity = 5; tags = ["core"; "content"; "registry"]; since = "1.4.0"; weight = 1050 };
  { key = "effect.opcode.hidden_0127";                   label = "scoped_biome_127";            arity = 5; tags = ["legacy"; "experimental"; "codegen"]; since = "1.7.0"; weight = 1411 };
  { key = "objective.opcode.provisional_0128";           label = "global_attribute_128";        arity = 7; tags = ["legacy"; "untyped"; "core"]; since = "1.3.1"; weight = 3520 };
  { key = "packet.opcode.scoped_0129";                   label = "eager_campfire_129";          arity = 2; tags = ["async"; "hot"; "cached"]; since = "1.3.1"; weight = 147 };
  { key = "repeater.opcode.canonical_0130";              label = "stable_compass_130";          arity = 7; tags = ["codegen"; "typed"]; since = "1.3.1"; weight = 3602 };
  { key = "crossbow.opcode.global_0131";                 label = "fallback_furnace_131";        arity = 7; tags = ["runtime"]; since = "1.0.0"; weight = 2265 };
  { key = "composter.opcode.hidden_0132";                label = "canonical_hopper_132";        arity = 3; tags = ["lower"; "compat"]; since = "1.8.3"; weight = 2372 };
  { key = "inventory.opcode.provisional_0133";           label = "eager_bossbar_133";           arity = 4; tags = ["legacy"]; since = "1.6.0"; weight = 3074 };
  { key = "minecart.opcode.fallback_0134";               label = "provisional_hologram_134";    arity = 3; tags = ["packet"; "check"; "cached"]; since = "1.0.0"; weight = 2925 };
  { key = "hopper.opcode.stable_0135";                   label = "scoped_smoker_135";           arity = 1; tags = ["hot"; "runtime"]; since = "1.7.0"; weight = 2369 };
  { key = "rail.opcode.provisional_0136";                label = "scoped_compass_136";          arity = 5; tags = ["check"]; since = "1.5.2"; weight = 3186 };
  { key = "smithing.opcode.derived_0137";                label = "canonical_grindstone_137";    arity = 2; tags = ["sync"; "typed"]; since = "1.2.0"; weight = 3632 };
  { key = "villager.opcode.cached_0138";                 label = "primary_comparator_138";      arity = 1; tags = ["registry"; "compat"]; since = "1.5.2"; weight = 220 };
  { key = "arrow.opcode.provisional_0139";               label = "derived_furnace_139";         arity = 3; tags = ["packet"]; since = "1.2.0"; weight = 3586 };
  { key = "minecart.opcode.stable_0140";                 label = "provisional_hopper_140";      arity = 0; tags = ["parse"; "emit"]; since = "1.5.2"; weight = 231 };
  { key = "pane.opcode.scoped_0141";                     label = "loose_hopper_141";            arity = 4; tags = ["runtime"; "core"; "emit"]; since = "1.9.0"; weight = 280 };
  { key = "chunk.opcode.public_0142";                    label = "lazy_mob_142";                arity = 0; tags = ["parse"; "core"; "content"]; since = "1.2.0"; weight = 2092 };
  { key = "clock.opcode.hidden_0143";                    label = "canonical_region_143";        arity = 1; tags = ["hot"]; since = "1.6.0"; weight = 37 };
  { key = "npc.opcode.fallback_0144";                    label = "provisional_observer_144";    arity = 3; tags = ["check"]; since = "1.3.1"; weight = 983 };
  { key = "smoker.opcode.modern_0145";                   label = "canonical_bell_145";          arity = 3; tags = ["untyped"; "compat"; "cached"]; since = "1.0.0"; weight = 628 };
  { key = "trade.opcode.canonical_0146";                 label = "cached_team_146";             arity = 7; tags = ["hot"; "experimental"]; since = "1.0.0"; weight = 1771 };
  { key = "objective.opcode.secondary_0147";             label = "fallback_particle_147";       arity = 3; tags = ["lower"; "parse"]; since = "1.5.2"; weight = 209 };
  { key = "biome.opcode.fallback_0148";                  label = "lazy_dropper_148";            arity = 5; tags = ["check"]; since = "1.2.0"; weight = 2003 };
  { key = "boat.opcode.legacy_0149";                     label = "lazy_observer_149";           arity = 3; tags = ["packet"; "registry"; "parse"]; since = "1.6.0"; weight = 2042 };
  { key = "lectern.opcode.loose_0150";                   label = "modern_smithing_150";         arity = 2; tags = ["emit"; "check"; "codegen"]; since = "1.3.1"; weight = 1603 };
  { key = "brewing.opcode.hidden_0151";                  label = "loose_potion_151";            arity = 6; tags = ["registry"; "async"; "untyped"]; since = "1.8.3"; weight = 3091 };
  { key = "comparator.opcode.stable_0152";               label = "public_bossbar_152";          arity = 2; tags = ["sync"; "content"; "codegen"]; since = "1.8.3"; weight = 2320 };
  { key = "piston.opcode.local_0153";                    label = "scoped_grindstone_153";       arity = 4; tags = ["codegen"; "core"]; since = "1.9.0"; weight = 368 };
  { key = "enchant.opcode.canonical_0154";               label = "modern_tablist_154";          arity = 5; tags = ["untyped"; "legacy"]; since = "1.4.0"; weight = 3821 };
  { key = "npc.opcode.legacy_0155";                      label = "provisional_shield_155";      arity = 0; tags = ["experimental"; "content"; "compat"]; since = "1.0.0"; weight = 1385 };
  { key = "dropper.opcode.hidden_0156";                  label = "legacy_enchant_156";          arity = 3; tags = ["emit"; "compat"]; since = "1.5.2"; weight = 833 };
  { key = "scoreboard.opcode.canonical_0157";            label = "derived_shulker_157";         arity = 7; tags = ["core"; "parse"; "registry"]; since = "1.4.0"; weight = 2515 };
  { key = "advancement.opcode.legacy_0158";              label = "internal_trade_158";          arity = 6; tags = ["lower"; "typed"; "async"]; since = "1.0.0"; weight = 3127 };
  { key = "campfire.opcode.stable_0159";                 label = "secondary_repeater_159";      arity = 7; tags = ["content"]; since = "1.2.0"; weight = 2130 };
  { key = "player.opcode.loose_0160";                    label = "local_bundle_160";            arity = 2; tags = ["experimental"]; since = "1.4.0"; weight = 1769 };
  { key = "portal.opcode.primary_0161";                  label = "cached_smithing_161";         arity = 0; tags = ["cached"]; since = "1.7.0"; weight = 2702 };
  { key = "attribute.opcode.canonical_0162";             label = "global_shulker_162";          arity = 5; tags = ["cold"; "legacy"; "emit"]; since = "1.5.2"; weight = 3088 };
  { key = "villager.opcode.scoped_0163";                 label = "strict_sound_163";            arity = 0; tags = ["emit"; "sync"; "legacy"]; since = "1.6.0"; weight = 1650 };
  { key = "entity.opcode.scoped_0164";                   label = "internal_tablist_164";        arity = 2; tags = ["runtime"; "hot"; "check"]; since = "1.4.0"; weight = 1159 };
  { key = "enchant.opcode.scoped_0165";                  label = "provisional_firework_165";    arity = 4; tags = ["legacy"; "async"; "experimental"]; since = "1.0.0"; weight = 1986 };
  { key = "player.opcode.fallback_0166";                 label = "loose_effect_166";            arity = 0; tags = ["cold"; "lower"; "emit"]; since = "1.4.0"; weight = 879 };
  { key = "trade.opcode.secondary_0167";                 label = "strict_gui_167";              arity = 6; tags = ["packet"; "compat"; "emit"]; since = "1.2.0"; weight = 386 };
  { key = "elytra.opcode.derived_0168";                  label = "lazy_dropper_168";            arity = 5; tags = ["sync"; "untyped"; "packet"]; since = "1.3.1"; weight = 3392 };
  { key = "map.opcode.strict_0169";                      label = "canonical_grindstone_169";    arity = 7; tags = ["compat"]; since = "1.5.2"; weight = 1503 };
  { key = "structure.opcode.scoped_0170";                label = "fallback_attribute_170";      arity = 0; tags = ["compat"; "emit"; "cold"]; since = "1.8.3"; weight = 2313 };
  { key = "gui.opcode.eager_0171";                       label = "internal_brewing_171";        arity = 3; tags = ["experimental"; "parse"; "content"]; since = "1.7.0"; weight = 2442 };
  { key = "chunk.opcode.hidden_0172";                    label = "modern_conduit_172";          arity = 4; tags = ["sync"; "untyped"; "typed"]; since = "1.3.1"; weight = 713 };
  { key = "advancement.opcode.fallback_0173";            label = "eager_boat_173";              arity = 2; tags = ["legacy"; "typed"; "async"]; since = "1.0.0"; weight = 3555 };
  { key = "block.opcode.canonical_0174";                 label = "fallback_grindstone_174";     arity = 0; tags = ["parse"; "cold"]; since = "1.7.0"; weight = 3084 };
  { key = "campfire.opcode.canonical_0175";              label = "internal_team_175";           arity = 3; tags = ["legacy"]; since = "1.3.1"; weight = 888 };
  { key = "smoker.opcode.fallback_0176";                 label = "canonical_stonecutter_176";   arity = 1; tags = ["typed"; "legacy"; "check"]; since = "1.0.0"; weight = 78 };
  { key = "trade.opcode.cached_0177";                    label = "fallback_comparator_177";     arity = 4; tags = ["untyped"; "cached"; "cold"]; since = "1.5.2"; weight = 3603 };
  { key = "smoker.opcode.loose_0178";                    label = "fallback_inventory_178";      arity = 1; tags = ["content"; "cold"]; since = "1.5.2"; weight = 1811 };
  { key = "crossbow.opcode.local_0179";                  label = "primary_trade_179";           arity = 6; tags = ["cached"; "core"]; since = "1.4.0"; weight = 389 };
  { key = "world.opcode.scoped_0180";                    label = "stable_lectern_180";          arity = 0; tags = ["core"; "emit"]; since = "1.4.0"; weight = 2671 };
  { key = "repeater.opcode.local_0181";                  label = "provisional_dispenser_181";   arity = 4; tags = ["async"; "codegen"; "sync"]; since = "1.9.0"; weight = 2549 };
  { key = "hopper.opcode.primary_0182";                  label = "scoped_advancement_182";      arity = 6; tags = ["core"]; since = "1.7.0"; weight = 4085 };
  { key = "mob.opcode.canonical_0183";                   label = "internal_bell_183";           arity = 0; tags = ["core"]; since = "1.9.0"; weight = 3187 };
  { key = "elytra.opcode.provisional_0184";              label = "secondary_sound_184";         arity = 2; tags = ["sync"; "parse"; "core"]; since = "1.9.0"; weight = 1844 };
  { key = "player.opcode.eager_0185";                    label = "hidden_inventory_185";        arity = 6; tags = ["cached"]; since = "1.9.0"; weight = 86 };
  { key = "npc.opcode.stable_0186";                      label = "derived_observer_186";        arity = 1; tags = ["cold"; "lower"]; since = "1.7.0"; weight = 954 };
  { key = "villager.opcode.global_0187";                 label = "cached_advancement_187";      arity = 1; tags = ["parse"; "packet"]; since = "1.0.0"; weight = 3363 };
  { key = "mob.opcode.secondary_0188";                   label = "lazy_pane_188";               arity = 2; tags = ["content"; "cold"; "runtime"]; since = "1.0.0"; weight = 1930 };
  { key = "region.opcode.eager_0189";                    label = "hidden_slot_189";             arity = 4; tags = ["typed"; "emit"; "packet"]; since = "1.6.0"; weight = 3381 };
  { key = "bell.opcode.lazy_0190";                       label = "stable_bell_190";             arity = 6; tags = ["content"]; since = "1.8.3"; weight = 3678 };
  { key = "tablist.opcode.fallback_0191";                label = "strict_team_191";             arity = 6; tags = ["check"; "experimental"]; since = "1.2.0"; weight = 3901 };
  { key = "biome.opcode.primary_0192";                   label = "internal_smithing_192";       arity = 4; tags = ["parse"; "content"]; since = "1.3.1"; weight = 1953 };
  { key = "observer.opcode.strict_0193";                 label = "fallback_minecart_193";       arity = 4; tags = ["runtime"; "legacy"; "parse"]; since = "1.3.1"; weight = 2268 };
  { key = "furnace.opcode.scoped_0194";                  label = "eager_entity_194";            arity = 5; tags = ["core"; "runtime"; "emit"]; since = "1.3.1"; weight = 3501 };
  { key = "bossbar.opcode.scoped_0195";                  label = "canonical_barrel_195";        arity = 4; tags = ["sync"; "registry"; "legacy"]; since = "1.2.0"; weight = 767 };
  { key = "chunk.opcode.primary_0196";                   label = "fallback_item_196";           arity = 4; tags = ["emit"; "async"]; since = "1.2.0"; weight = 814 };
  { key = "hologram.opcode.hidden_0197";                 label = "internal_banner_197";         arity = 1; tags = ["content"]; since = "1.6.0"; weight = 1920 };
  { key = "shield.opcode.modern_0198";                   label = "modern_furnace_198";          arity = 6; tags = ["async"]; since = "1.9.0"; weight = 2565 };
  { key = "inventory.opcode.secondary_0199";             label = "public_clock_199";            arity = 6; tags = ["typed"]; since = "1.4.0"; weight = 3341 };
  { key = "hologram.opcode.public_0200";                 label = "global_hopper_200";           arity = 2; tags = ["legacy"]; since = "1.7.0"; weight = 19 };
  { key = "gui.opcode.canonical_0201";                   label = "eager_objective_201";         arity = 2; tags = ["runtime"; "typed"]; since = "1.8.3"; weight = 491 };
  { key = "advancement.opcode.local_0202";               label = "canonical_banner_pattern_202"; arity = 2; tags = ["cached"; "runtime"; "async"]; since = "1.9.0"; weight = 3116 };
  { key = "mob.opcode.cached_0203";                      label = "eager_conduit_203";           arity = 0; tags = ["async"; "runtime"]; since = "1.3.1"; weight = 3979 };
  { key = "boat.opcode.hidden_0204";                     label = "stable_biome_204";            arity = 3; tags = ["sync"; "emit"]; since = "1.7.0"; weight = 3092 };
  { key = "loom.opcode.scoped_0205";                     label = "provisional_minecart_205";    arity = 7; tags = ["cold"; "lower"; "runtime"]; since = "1.9.0"; weight = 2910 };
  { key = "packet.opcode.lazy_0206";                     label = "canonical_block_206";         arity = 7; tags = ["async"]; since = "1.2.0"; weight = 2607 };
  { key = "attribute.opcode.canonical_0207";             label = "stable_enchant_207";          arity = 6; tags = ["check"; "core"]; since = "1.5.2"; weight = 3591 };
  { key = "piston.opcode.primary_0208";                  label = "hidden_portal_208";           arity = 3; tags = ["async"; "compat"]; since = "1.0.0"; weight = 712 };
  { key = "composter.opcode.modern_0209";                label = "legacy_spawner_209";          arity = 7; tags = ["untyped"; "experimental"; "legacy"]; since = "1.8.3"; weight = 1261 };
  { key = "repeater.opcode.legacy_0210";                 label = "scoped_rail_210";             arity = 2; tags = ["emit"; "typed"; "parse"]; since = "1.2.0"; weight = 2138 };
  { key = "item.opcode.lazy_0211";                       label = "local_smoker_211";            arity = 5; tags = ["async"; "codegen"; "experimental"]; since = "1.3.1"; weight = 1087 };
  { key = "sound.opcode.provisional_0212";               label = "lazy_portal_212";             arity = 4; tags = ["hot"; "packet"; "registry"]; since = "1.2.0"; weight = 2312 };
  { key = "scoreboard.opcode.provisional_0213";          label = "derived_recipe_213";          arity = 6; tags = ["compat"; "registry"; "experimental"]; since = "1.2.0"; weight = 1266 };
  { key = "repeater.opcode.derived_0214";                label = "scoped_loom_214";             arity = 0; tags = ["typed"; "legacy"]; since = "1.4.0"; weight = 1878 };
  { key = "bossbar.opcode.global_0215";                  label = "scoped_sound_215";            arity = 5; tags = ["async"]; since = "1.6.0"; weight = 752 };
  { key = "team.opcode.legacy_0216";                     label = "primary_packet_216";          arity = 3; tags = ["emit"; "untyped"]; since = "1.9.0"; weight = 1000 };
  { key = "inventory.opcode.stable_0217";                label = "strict_map_217";              arity = 5; tags = ["sync"; "lower"]; since = "1.7.0"; weight = 1050 };
  { key = "conduit.opcode.lazy_0218";                    label = "cached_sound_218";            arity = 4; tags = ["emit"; "packet"]; since = "1.2.0"; weight = 2639 };
  { key = "tablist.opcode.legacy_0219";                  label = "public_packet_219";           arity = 1; tags = ["lower"]; since = "1.4.0"; weight = 2826 };
  { key = "crossbow.opcode.internal_0220";               label = "global_particle_220";         arity = 2; tags = ["registry"; "parse"]; since = "1.0.0"; weight = 4069 };
  { key = "tablist.opcode.modern_0221";                  label = "derived_cartography_221";     arity = 3; tags = ["packet"; "compat"]; since = "1.9.0"; weight = 4018 };
  { key = "anvil.opcode.internal_0222";                  label = "modern_banner_222";           arity = 1; tags = ["runtime"; "async"; "cold"]; since = "1.6.0"; weight = 2233 };
  { key = "bell.opcode.loose_0223";                      label = "eager_hologram_223";          arity = 0; tags = ["legacy"; "untyped"; "packet"]; since = "1.0.0"; weight = 1118 };
  { key = "hopper.opcode.derived_0224";                  label = "lazy_scoreboard_224";         arity = 3; tags = ["typed"; "parse"; "lower"]; since = "1.4.0"; weight = 1324 };
  { key = "chunk.opcode.provisional_0225";               label = "public_trident_225";          arity = 1; tags = ["core"]; since = "1.7.0"; weight = 2271 };
  { key = "crossbow.opcode.cached_0226";                 label = "scoped_enchant_226";          arity = 6; tags = ["experimental"]; since = "1.9.0"; weight = 515 };
  { key = "sound.opcode.eager_0227";                     label = "fallback_sound_227";          arity = 0; tags = ["registry"]; since = "1.5.2"; weight = 3674 };
  { key = "effect.opcode.loose_0228";                    label = "stable_map_228";              arity = 2; tags = ["packet"]; since = "1.9.0"; weight = 2472 };
  { key = "structure.opcode.scoped_0229";                label = "derived_compass_229";         arity = 1; tags = ["registry"]; since = "1.6.0"; weight = 311 };
  { key = "trade.opcode.cached_0230";                    label = "internal_potion_230";         arity = 7; tags = ["emit"]; since = "1.0.0"; weight = 1166 };
  { key = "repeater.opcode.eager_0231";                  label = "legacy_stonecutter_231";      arity = 6; tags = ["legacy"; "emit"; "runtime"]; since = "1.5.2"; weight = 3834 };
  { key = "map.opcode.modern_0232";                      label = "local_banner_232";            arity = 1; tags = ["typed"; "registry"]; since = "1.7.0"; weight = 489 };
  { key = "mob.opcode.loose_0233";                       label = "hidden_bundle_233";           arity = 2; tags = ["cached"; "lower"]; since = "1.9.0"; weight = 2152 };
  { key = "tablist.opcode.derived_0234";                 label = "strict_arrow_234";            arity = 3; tags = ["experimental"; "cold"]; since = "1.2.0"; weight = 2318 };
  { key = "composter.opcode.public_0235";                label = "internal_minecart_235";       arity = 4; tags = ["legacy"; "emit"; "packet"]; since = "1.2.0"; weight = 2228 };
  { key = "campfire.opcode.eager_0236";                  label = "derived_conduit_236";         arity = 3; tags = ["core"]; since = "1.4.0"; weight = 212 };
  { key = "compass.opcode.derived_0237";                 label = "legacy_slot_237";             arity = 6; tags = ["experimental"; "content"]; since = "1.6.0"; weight = 1529 };
  { key = "scoreboard.opcode.loose_0238";                label = "internal_comparator_238";     arity = 1; tags = ["hot"; "cached"]; since = "1.8.3"; weight = 863 };
  { key = "piston.opcode.hidden_0239";                   label = "local_pane_239";              arity = 4; tags = ["content"; "cold"]; since = "1.3.1"; weight = 2829 };
  { key = "spawner.opcode.internal_0240";                label = "canonical_inventory_240";     arity = 3; tags = ["async"; "parse"; "runtime"]; since = "1.2.0"; weight = 2026 };
  { key = "objective.opcode.strict_0241";                label = "secondary_stonecutter_241";   arity = 5; tags = ["registry"; "untyped"]; since = "1.5.2"; weight = 3525 };
  { key = "potion.opcode.eager_0242";                    label = "lazy_boat_242";               arity = 5; tags = ["cold"; "untyped"; "parse"]; since = "1.0.0"; weight = 832 };
  { key = "bundle.opcode.lazy_0243";                     label = "stable_conduit_243";          arity = 7; tags = ["core"; "cached"; "lower"]; since = "1.6.0"; weight = 276 };
  { key = "hologram.opcode.internal_0244";               label = "lazy_slot_244";               arity = 0; tags = ["async"; "sync"]; since = "1.3.1"; weight = 2750 };
  { key = "shulker.opcode.public_0245";                  label = "public_bell_245";             arity = 7; tags = ["registry"; "typed"; "experimental"]; since = "1.4.0"; weight = 2560 };
  { key = "bundle.opcode.lazy_0246";                     label = "public_trade_246";            arity = 3; tags = ["typed"; "core"]; since = "1.5.2"; weight = 225 };
  { key = "cartography.opcode.secondary_0247";           label = "strict_observer_247";         arity = 0; tags = ["typed"]; since = "1.6.0"; weight = 3410 };
  { key = "player.opcode.fallback_0248";                 label = "secondary_minecart_248";      arity = 6; tags = ["sync"; "packet"]; since = "1.0.0"; weight = 3768 };
  { key = "rail.opcode.fallback_0249";                   label = "modern_comparator_249";       arity = 5; tags = ["experimental"; "compat"; "hot"]; since = "1.4.0"; weight = 4032 };
  { key = "crossbow.opcode.local_0250";                  label = "cached_arrow_250";            arity = 0; tags = ["async"; "emit"]; since = "1.5.2"; weight = 2734 };
  { key = "item.opcode.primary_0251";                    label = "fallback_advancement_251";    arity = 2; tags = ["compat"; "cold"; "packet"]; since = "1.4.0"; weight = 81 };
  { key = "gui.opcode.modern_0252";                      label = "loose_cartography_252";       arity = 6; tags = ["cached"; "check"; "parse"]; since = "1.4.0"; weight = 2792 };
  { key = "effect.opcode.modern_0253";                   label = "eager_advancement_253";       arity = 7; tags = ["cold"]; since = "1.2.0"; weight = 2770 };
  { key = "block.opcode.loose_0254";                     label = "stable_scoreboard_254";       arity = 4; tags = ["typed"; "cold"]; since = "1.3.1"; weight = 3159 };
  { key = "grindstone.opcode.provisional_0255";          label = "strict_banner_pattern_255";   arity = 2; tags = ["registry"]; since = "1.4.0"; weight = 3963 };
  { key = "composter.opcode.derived_0256";               label = "strict_map_256";              arity = 7; tags = ["runtime"; "cold"]; since = "1.2.0"; weight = 1034 };
  { key = "clock.opcode.primary_0257";                   label = "fallback_anvil_257";          arity = 4; tags = ["registry"; "check"]; since = "1.2.0"; weight = 1806 };
  { key = "hopper.opcode.legacy_0258";                   label = "lazy_crossbow_258";           arity = 4; tags = ["experimental"]; since = "1.9.0"; weight = 3194 };
  { key = "gui.opcode.stable_0259";                      label = "eager_loom_259";              arity = 2; tags = ["runtime"]; since = "1.6.0"; weight = 1297 };
  { key = "bell.opcode.loose_0260";                      label = "local_bundle_260";            arity = 4; tags = ["parse"]; since = "1.2.0"; weight = 339 };
  { key = "world.opcode.local_0261";                     label = "secondary_objective_261";     arity = 7; tags = ["core"; "codegen"; "cached"]; since = "1.4.0"; weight = 2889 };
  { key = "barrel.opcode.cached_0262";                   label = "scoped_clock_262";            arity = 2; tags = ["emit"; "cold"; "untyped"]; since = "1.3.1"; weight = 2102 };
  { key = "potion.opcode.cached_0263";                   label = "internal_minecart_263";       arity = 3; tags = ["check"; "runtime"]; since = "1.2.0"; weight = 2548 };
  { key = "banner.opcode.derived_0264";                  label = "modern_sound_264";            arity = 2; tags = ["compat"]; since = "1.5.2"; weight = 2849 };
  { key = "firework.opcode.loose_0265";                  label = "canonical_target_265";        arity = 4; tags = ["content"; "async"]; since = "1.4.0"; weight = 16 };
  { key = "npc.opcode.internal_0266";                    label = "derived_comparator_266";      arity = 3; tags = ["experimental"]; since = "1.4.0"; weight = 2060 };
  { key = "banner_pattern.opcode.fallback_0267";         label = "lazy_comparator_267";         arity = 3; tags = ["content"]; since = "1.9.0"; weight = 2876 };
  { key = "shulker.opcode.public_0268";                  label = "hidden_attribute_268";        arity = 3; tags = ["async"; "runtime"; "registry"]; since = "1.9.0"; weight = 1614 };
  { key = "composter.opcode.lazy_0269";                  label = "hidden_stonecutter_269";      arity = 5; tags = ["untyped"; "legacy"]; since = "1.7.0"; weight = 3336 };
  { key = "campfire.opcode.modern_0270";                 label = "internal_bundle_270";         arity = 5; tags = ["cached"; "cold"]; since = "1.9.0"; weight = 1303 };
  { key = "biome.opcode.modern_0271";                    label = "strict_grindstone_271";       arity = 5; tags = ["cached"; "sync"; "core"]; since = "1.4.0"; weight = 1027 };
  { key = "structure.opcode.fallback_0272";              label = "modern_inventory_272";        arity = 5; tags = ["check"; "cached"; "typed"]; since = "1.8.3"; weight = 3073 };
  { key = "furnace.opcode.lazy_0273";                    label = "canonical_gui_273";           arity = 6; tags = ["hot"; "lower"]; since = "1.2.0"; weight = 2745 };
  { key = "team.opcode.legacy_0274";                     label = "hidden_objective_274";        arity = 1; tags = ["legacy"; "async"; "compat"]; since = "1.8.3"; weight = 1258 };
  { key = "objective.opcode.local_0275";                 label = "modern_particle_275";         arity = 7; tags = ["core"; "compat"]; since = "1.4.0"; weight = 3492 };
  { key = "brewing.opcode.strict_0276";                  label = "hidden_scoreboard_276";       arity = 7; tags = ["experimental"; "hot"]; since = "1.7.0"; weight = 1444 };
  { key = "world.opcode.eager_0277";                     label = "eager_banner_277";            arity = 3; tags = ["content"; "codegen"]; since = "1.6.0"; weight = 287 };
  { key = "effect.opcode.canonical_0278";                label = "stable_attribute_278";        arity = 0; tags = ["legacy"; "packet"]; since = "1.4.0"; weight = 1839 };
  { key = "team.opcode.eager_0279";                      label = "legacy_comparator_279";       arity = 1; tags = ["core"; "sync"]; since = "1.3.1"; weight = 80 };
  { key = "shulker.opcode.canonical_0280";               label = "secondary_arrow_280";         arity = 7; tags = ["packet"; "async"]; since = "1.5.2"; weight = 3008 };
  { key = "cartography.opcode.hidden_0281";              label = "modern_npc_281";              arity = 1; tags = ["hot"; "compat"]; since = "1.9.0"; weight = 1830 };
  { key = "cartography.opcode.lazy_0282";                label = "provisional_conduit_282";     arity = 1; tags = ["hot"]; since = "1.4.0"; weight = 56 };
  { key = "map.opcode.local_0283";                       label = "eager_structure_283";         arity = 7; tags = ["check"; "content"]; since = "1.6.0"; weight = 3983 };
  { key = "tablist.opcode.internal_0284";                label = "loose_target_284";            arity = 5; tags = ["emit"; "content"]; since = "1.9.0"; weight = 4048 };
  { key = "chunk.opcode.canonical_0285";                 label = "loose_loom_285";              arity = 0; tags = ["sync"]; since = "1.8.3"; weight = 3572 };
  { key = "team.opcode.scoped_0286";                     label = "modern_entity_286";           arity = 4; tags = ["codegen"; "cold"; "emit"]; since = "1.7.0"; weight = 1130 };
  { key = "attribute.opcode.local_0287";                 label = "loose_chunk_287";             arity = 1; tags = ["typed"]; since = "1.0.0"; weight = 2476 };
  { key = "clock.opcode.provisional_0288";               label = "legacy_boat_288";             arity = 5; tags = ["lower"; "experimental"]; since = "1.5.2"; weight = 1310 };
  { key = "slot.opcode.global_0289";                     label = "stable_smithing_289";         arity = 1; tags = ["registry"; "async"; "experimental"]; since = "1.9.0"; weight = 2757 };
  { key = "beacon.opcode.local_0290";                    label = "scoped_inventory_290";        arity = 6; tags = ["core"]; since = "1.4.0"; weight = 3968 };
  { key = "potion.opcode.legacy_0291";                   label = "hidden_team_291";             arity = 4; tags = ["registry"; "hot"]; since = "1.6.0"; weight = 354 };
  { key = "region.opcode.secondary_0292";                label = "legacy_region_292";           arity = 3; tags = ["check"; "lower"]; since = "1.8.3"; weight = 476 };
  { key = "compass.opcode.secondary_0293";               label = "stable_grindstone_293";       arity = 3; tags = ["emit"]; since = "1.3.1"; weight = 462 };
  { key = "pane.opcode.internal_0294";                   label = "modern_firework_294";         arity = 5; tags = ["content"; "sync"; "cold"]; since = "1.8.3"; weight = 4072 };
  { key = "banner_pattern.opcode.strict_0295";           label = "public_banner_pattern_295";   arity = 2; tags = ["core"; "sync"; "typed"]; since = "1.2.0"; weight = 3688 };
  { key = "beacon.opcode.primary_0296";                  label = "cached_shield_296";           arity = 4; tags = ["core"]; since = "1.6.0"; weight = 2798 };
  { key = "crossbow.opcode.provisional_0297";            label = "hidden_observer_297";         arity = 3; tags = ["runtime"]; since = "1.7.0"; weight = 2792 };
  { key = "sound.opcode.public_0298";                    label = "loose_scoreboard_298";        arity = 1; tags = ["experimental"]; since = "1.4.0"; weight = 2238 };
  { key = "dropper.opcode.fallback_0299";                label = "derived_chunk_299";           arity = 3; tags = ["packet"; "content"; "async"]; since = "1.3.1"; weight = 1945 };
  { key = "minecart.opcode.global_0300";                 label = "canonical_recipe_300";        arity = 4; tags = ["check"]; since = "1.7.0"; weight = 1160 };
  { key = "loom.opcode.stable_0301";                     label = "secondary_mob_301";           arity = 5; tags = ["cold"; "content"; "check"]; since = "1.6.0"; weight = 3284 };
  { key = "mob.opcode.legacy_0302";                      label = "public_scoreboard_302";       arity = 1; tags = ["cold"; "core"; "content"]; since = "1.9.0"; weight = 2939 };
  { key = "chunk.opcode.derived_0303";                   label = "global_recipe_303";           arity = 6; tags = ["packet"]; since = "1.2.0"; weight = 802 };
  { key = "region.opcode.canonical_0304";                label = "provisional_team_304";        arity = 6; tags = ["emit"; "packet"; "compat"]; since = "1.4.0"; weight = 4094 };
  { key = "beacon.opcode.strict_0305";                   label = "loose_shield_305";            arity = 1; tags = ["typed"; "core"]; since = "1.5.2"; weight = 475 };
  { key = "pane.opcode.canonical_0306";                  label = "modern_advancement_306";      arity = 5; tags = ["content"; "parse"]; since = "1.4.0"; weight = 2566 };
  { key = "slot.opcode.hidden_0307";                     label = "global_packet_307";           arity = 6; tags = ["core"]; since = "1.5.2"; weight = 3801 };
  { key = "shield.opcode.eager_0308";                    label = "strict_brewing_308";          arity = 1; tags = ["typed"]; since = "1.8.3"; weight = 2603 };
  { key = "objective.opcode.public_0309";                label = "public_hologram_309";         arity = 2; tags = ["lower"]; since = "1.8.3"; weight = 1855 };
  { key = "player.opcode.scoped_0310";                   label = "canonical_particle_310";      arity = 3; tags = ["runtime"; "parse"]; since = "1.7.0"; weight = 3796 };
  { key = "furnace.opcode.fallback_0311";                label = "eager_clock_311";             arity = 2; tags = ["sync"; "async"]; since = "1.6.0"; weight = 1475 };
  { key = "hologram.opcode.scoped_0312";                 label = "public_spawner_312";          arity = 1; tags = ["parse"; "core"; "experimental"]; since = "1.3.1"; weight = 3015 };
  { key = "smoker.opcode.scoped_0313";                   label = "lazy_lectern_313";            arity = 1; tags = ["registry"; "runtime"; "typed"]; since = "1.4.0"; weight = 1115 };
  { key = "attribute.opcode.internal_0314";              label = "hidden_smithing_314";         arity = 5; tags = ["lower"; "sync"]; since = "1.5.2"; weight = 2878 };
  { key = "sound.opcode.primary_0315";                   label = "modern_observer_315";         arity = 5; tags = ["lower"]; since = "1.2.0"; weight = 2109 };
  { key = "shield.opcode.eager_0316";                    label = "lazy_slot_316";               arity = 7; tags = ["check"; "codegen"]; since = "1.4.0"; weight = 1387 };
  { key = "conduit.opcode.internal_0317";                label = "stable_block_317";            arity = 3; tags = ["experimental"; "cold"; "sync"]; since = "1.0.0"; weight = 1722 };
  { key = "banner.opcode.scoped_0318";                   label = "local_shield_318";            arity = 7; tags = ["parse"]; since = "1.6.0"; weight = 1857 };
  { key = "elytra.opcode.cached_0319";                   label = "strict_npc_319";              arity = 0; tags = ["cold"; "lower"]; since = "1.2.0"; weight = 1104 };
  { key = "cartography.opcode.public_0320";              label = "secondary_stonecutter_320";   arity = 0; tags = ["typed"; "hot"]; since = "1.8.3"; weight = 3293 };
  { key = "elytra.opcode.strict_0321";                   label = "strict_bossbar_321";          arity = 0; tags = ["runtime"; "packet"; "check"]; since = "1.4.0"; weight = 3545 };
  { key = "rail.opcode.primary_0322";                    label = "legacy_barrel_322";           arity = 0; tags = ["emit"; "compat"]; since = "1.4.0"; weight = 1290 };
  { key = "conduit.opcode.provisional_0323";             label = "eager_elytra_323";            arity = 7; tags = ["async"; "sync"]; since = "1.2.0"; weight = 1738 };
  { key = "clock.opcode.eager_0324";                     label = "primary_inventory_324";       arity = 2; tags = ["check"; "cold"; "legacy"]; since = "1.8.3"; weight = 391 };
  { key = "team.opcode.modern_0325";                     label = "fallback_structure_325";      arity = 4; tags = ["core"; "check"; "hot"]; since = "1.8.3"; weight = 3493 };
  { key = "map.opcode.fallback_0326";                    label = "local_player_326";            arity = 4; tags = ["async"]; since = "1.7.0"; weight = 80 };
  { key = "hopper.opcode.cached_0327";                   label = "modern_npc_327";              arity = 5; tags = ["compat"; "sync"]; since = "1.8.3"; weight = 2603 };
  { key = "hopper.opcode.legacy_0328";                   label = "internal_advancement_328";    arity = 0; tags = ["core"]; since = "1.0.0"; weight = 622 };
  { key = "world.opcode.derived_0329";                   label = "global_inventory_329";        arity = 5; tags = ["async"; "core"; "sync"]; since = "1.3.1"; weight = 3904 };
  { key = "bossbar.opcode.stable_0330";                  label = "global_compass_330";          arity = 4; tags = ["cold"; "async"]; since = "1.0.0"; weight = 3609 };
  { key = "campfire.opcode.secondary_0331";              label = "modern_smoker_331";           arity = 4; tags = ["emit"]; since = "1.7.0"; weight = 1217 };
  { key = "pane.opcode.public_0332";                     label = "lazy_enchant_332";            arity = 0; tags = ["check"; "sync"]; since = "1.2.0"; weight = 3312 };
  { key = "player.opcode.derived_0333";                  label = "internal_elytra_333";         arity = 7; tags = ["check"; "content"]; since = "1.3.1"; weight = 2966 };
  { key = "enchant.opcode.scoped_0334";                  label = "loose_banner_334";            arity = 7; tags = ["emit"; "packet"; "untyped"]; since = "1.7.0"; weight = 429 };
  { key = "tablist.opcode.strict_0335";                  label = "lazy_minecart_335";           arity = 4; tags = ["content"; "compat"]; since = "1.2.0"; weight = 1883 };
  { key = "structure.opcode.hidden_0336";                label = "eager_entity_336";            arity = 7; tags = ["packet"; "emit"; "compat"]; since = "1.8.3"; weight = 2820 };
  { key = "map.opcode.lazy_0337";                        label = "lazy_pane_337";               arity = 0; tags = ["cached"]; since = "1.5.2"; weight = 2874 };
  { key = "shield.opcode.scoped_0338";                   label = "fallback_item_338";           arity = 5; tags = ["registry"]; since = "1.7.0"; weight = 299 };
  { key = "recipe.opcode.local_0339";                    label = "strict_lectern_339";          arity = 3; tags = ["registry"]; since = "1.9.0"; weight = 156 };
  { key = "mob.opcode.global_0340";                      label = "modern_loom_340";             arity = 4; tags = ["content"; "async"; "emit"]; since = "1.8.3"; weight = 208 };
  { key = "effect.opcode.canonical_0341";                label = "stable_effect_341";           arity = 7; tags = ["untyped"; "sync"]; since = "1.4.0"; weight = 2717 };
  { key = "smoker.opcode.secondary_0342";                label = "cached_bundle_342";           arity = 4; tags = ["packet"; "runtime"; "untyped"]; since = "1.9.0"; weight = 1049 };
  { key = "pane.opcode.legacy_0343";                     label = "primary_arrow_343";           arity = 5; tags = ["untyped"; "hot"]; since = "1.6.0"; weight = 490 };
  { key = "comparator.opcode.global_0344";               label = "primary_structure_344";       arity = 1; tags = ["codegen"; "async"]; since = "1.3.1"; weight = 2811 };
  { key = "elytra.opcode.global_0345";                   label = "loose_hologram_345";          arity = 5; tags = ["check"]; since = "1.7.0"; weight = 2437 };
  { key = "mob.opcode.global_0346";                      label = "local_stonecutter_346";       arity = 7; tags = ["codegen"; "sync"; "content"]; since = "1.9.0"; weight = 3517 };
  { key = "pane.opcode.canonical_0347";                  label = "scoped_observer_347";         arity = 1; tags = ["runtime"; "emit"; "cold"]; since = "1.5.2"; weight = 33 };
  { key = "pane.opcode.derived_0348";                    label = "secondary_entity_348";        arity = 1; tags = ["codegen"; "runtime"; "cached"]; since = "1.0.0"; weight = 2535 };
]

let count = List.length entries

let table : (string, opcode_entry) Hashtbl.t =
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
