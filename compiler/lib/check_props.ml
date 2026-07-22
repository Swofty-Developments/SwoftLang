(* --- swoftc --check-props: property/accessor ownership validator ---

   Cross-checks the compile-time property-ownership tables in [Registry] against
   the generated Minestom catalogs (compiler/data/events_data.ml, the pinned
   event surface) and the curated event->class registry. It is the offline lint
   that keeps every event:* property row honest: each exposed property must
   resolve to a *concrete accessor* — a catalog getter, the CancellableEvent
   interface, a documented runtime alias, or a documented synthetic accessor —
   and its SwoftLang type + writability must match that accessor.

   Reported issue kinds (GitHub #57 "event:* owner mismatches"):
     - owner-mismatch : the property's SwoftLang type disagrees with the type
                        the backing accessor's Java type promotes to
                        (Registry.ty_of_java_type), i.e. it is attributed to the
                        wrong owner type.
     - wrong-writable : rw/ro disagrees with the accessor's settability.
     - orphaned       : no backing accessor exists for the property.
     - missing        : a cancellable event fails to expose `cancelled`.
     - duplicated     : the same property name appears twice under one owner.

   The alias/synthetic resolution tables below are NOT a way to silence the
   checker: every entry names a real runtime accessor documented in
   registry.ml (the generic-path event comment and ty_of_java_type). Anything
   not covered is a genuine finding. *)

open Registry
module ED = Events_data

type kind =
  | Owner_mismatch
  | Wrong_writable
  | Orphaned
  | Missing
  | Duplicated
  | Wrong_cancellable

let kind_slug = function
  | Owner_mismatch -> "owner-mismatch"
  | Wrong_writable -> "wrong-writable"
  | Orphaned -> "orphaned"
  | Missing -> "missing"
  | Duplicated -> "duplicated"
  | Wrong_cancellable -> "wrong-cancellable"

type issue = {
  owner : string;
  prop : string;
  kind : kind;
  detail : string;
}

let mk owner prop kind detail = { owner; prop; kind; detail }

(* --- generated event catalog lookups --- *)

let gen_of_class cls =
  List.find_opt (fun (g : ED.gen_event) -> g.ED.ev_class = cls) ED.generated_events

let catalog_prop (g : ED.gen_event) name =
  List.find_opt (fun (gp : ED.gen_event_prop) -> gp.ED.p_name = name) g.ED.ev_props

let has_getter g name = catalog_prop g name <> None

(* --- documented runtime aliases (generic-path events) ---

   A curated property name that is surfaced under a friendlier spelling than the
   raw catalog getter. Documented in registry.ml (generic-path comment):
   `world` reads the instance getter; `location` reads the block position (or
   plain position) getter. Returns the catalog getter name to check against. *)
let alias_getter (g : ED.gen_event) (name : string) : string option =
  match name with
  | "world" when (not (has_getter g "world")) && has_getter g "instance" -> Some "instance"
  | "location" when not (has_getter g "location") ->
    if has_getter g "block_position" then Some "block_position"
    else if has_getter g "position" then Some "position"
    else None
  | _ -> None

(* --- documented synthetic accessors (generic-path events) ---

   EntityDamage exposes the Minestom Damage object through unwrapping accessors
   (getAmount/setAmount for the amount; attacker/source_entity/damage_type read
   the Damage's fields). These are real runtime accessors with no 1:1 catalog
   getter, so they carry their own expected (type, writable). Documented in the
   registry.ml generic-path comment. *)
let synthetic : (string * string * (ty * bool)) list =
  [
    ("EntityDamage", "damage", (TDouble, true));
    ("EntityDamage", "attacker", (TOptional TEntity, false));
    ("EntityDamage", "source_entity", (TOptional TEntity, false));
    ("EntityDamage", "damage_type", (TString, false));
  ]

let synthetic_of ev name = List.assoc_opt name
    (List.filter_map (fun (e, n, v) -> if e = ev then Some (n, v) else None) synthetic)

(* generic-path events bind only `event`; the curated typed rows come straight
   from the catalog. Custom EventType wrappers (PlayerChat, MobDamage, the
   fishing/blocks events, ...) bind named aliases and are backed by bespoke Java
   wrapper classes, so they carry a non-empty e_aliases list. *)
let is_generic_path (e : event_def) = e.e_aliases = []

(* --- per-property check on a generic-path event against its catalog class --- *)

let check_generic_prop (e : event_def) (g : ED.gen_event) (p : prop) : issue option =
  let owner = "event:" ^ e.e_name in
  if p.p_name = "cancelled" then
    if not g.ED.ev_cancellable then
      Some (mk owner p.p_name Orphaned
              "'cancelled' exposed on an event the catalog reports non-cancellable")
    else if not p.p_writable then
      Some (mk owner p.p_name Wrong_writable "'cancelled' must be writable on a cancellable event")
    else if p.p_ty <> TBoolean then
      Some (mk owner p.p_name Owner_mismatch "'cancelled' must be Boolean")
    else None
  else
    match synthetic_of e.e_name p.p_name with
    | Some (exp_ty, exp_w) ->
      if p.p_ty <> exp_ty then
        Some (mk owner p.p_name Owner_mismatch
                (Printf.sprintf "synthetic accessor should be %s, table has %s"
                   (ty_to_string exp_ty) (ty_to_string p.p_ty)))
      else if p.p_writable <> exp_w then
        Some (mk owner p.p_name Wrong_writable
                (Printf.sprintf "synthetic accessor should be %s" (if exp_w then "rw" else "ro")))
      else None
    | None -> (
      let getter = match alias_getter g p.p_name with Some g' -> g' | None -> p.p_name in
      match catalog_prop g getter with
      | None ->
        Some (mk owner p.p_name Orphaned
                (Printf.sprintf "no catalog accessor on %s (getters: %s)" g.ED.ev_class
                   (String.concat ", "
                      (List.map (fun (gp : ED.gen_event_prop) -> gp.ED.p_name) g.ED.ev_props))))
      | Some gp -> (
        (* writability must match the catalog setter scan *)
        if gp.ED.p_settable <> p.p_writable then
          Some (mk owner p.p_name Wrong_writable
                  (Printf.sprintf "catalog accessor %s is %s, table has %s" gp.ED.p_accessor
                     (if gp.ED.p_settable then "rw" else "ro")
                     (if p.p_writable then "rw" else "ro")))
        else
          (* the promoted Java type identifies the owning type *)
          match ty_of_java_type gp.ED.p_java_type with
          | Some t when t <> p.p_ty ->
            Some (mk owner p.p_name Owner_mismatch
                    (Printf.sprintf "accessor %s : %s promotes to %s, table owns it as %s"
                       gp.ED.p_accessor gp.ED.p_java_type (ty_to_string t) (ty_to_string p.p_ty)))
          | Some _ | None -> None))

(* --- event-level checks --- *)

let check_event (e : event_def) : issue list =
  let owner = "event:" ^ e.e_name in
  match List.assoc_opt e.e_name curated_event_class with
  | None ->
    (* a curated event that names no backing class cannot be verified *)
    [ mk owner "" Orphaned "curated event has no backing class in curated_event_class" ]
  | Some cls -> (
    match gen_of_class cls with
    | None ->
      (* custom Swoft wrapper class under net.swofty: not in the engine catalog,
         so property rows are authored by hand. Only internal consistency is
         checkable here (cancelled presence handled by the caller). *)
      if is_generic_path e then
        [ mk owner "" Orphaned
            (Printf.sprintf "generic-path event maps to %s which is absent from the catalog" cls) ]
      else []
    | Some g ->
      if not (is_generic_path e) then
        (* custom EventType wrapper over an engine class: bespoke Java wrapper,
           hand-authored rows. Consistency only. *)
        []
      else begin
        (* cancellable flag must agree with the catalog *)
        let flag_issue =
          if e.e_cancellable <> g.ED.ev_cancellable then
            [ mk owner "cancelled" Wrong_cancellable
                (Printf.sprintf "event cancellable=%b but catalog=%b" e.e_cancellable
                   g.ED.ev_cancellable) ]
          else []
        in
        (* a cancellable generic-path event must expose `cancelled` *)
        let missing_cancel =
          if g.ED.ev_cancellable && not (List.exists (fun p -> p.p_name = "cancelled") e.e_props)
          then [ mk owner "cancelled" Missing "cancellable event does not expose 'cancelled'" ]
          else []
        in
        let prop_issues = List.filter_map (check_generic_prop e g) e.e_props in
        flag_issue @ missing_cancel @ prop_issues
      end)

(* every custom-wrapper event must still expose `cancelled` iff it is
   cancellable (internal consistency, catalog-independent) *)
let check_wrapper_cancel (e : event_def) : issue list =
  if is_generic_path e then []
  else
    let owner = "event:" ^ e.e_name in
    let has = List.exists (fun p -> p.p_name = "cancelled") e.e_props in
    if e.e_cancellable && not has then
      [ mk owner "cancelled" Missing "cancellable event does not expose 'cancelled'" ]
    else if (not e.e_cancellable) && has then
      [ mk owner "cancelled" Orphaned "'cancelled' exposed on a non-cancellable event" ]
    else []

(* --- duplicate detection across every owner in the property table --- *)

let owner_prop_lists () : (string * prop list) list =
  [
    ("Player", dedup_props player_props combat_entity_extra);
    ("Location", location_props);
    ("Item", item_props);
    ("Mob", dedup_props (mob_props @ mob_extra_props) combat_entity_extra);
    ("World", world_props);
    ("Display", display_props);
    ("Request", request_props);
    ("Song", song_props);
    ("Server", server_props);
    ("Skin", skin_props);
    ("Canvas", canvas_props);
    ("Entity", dedup_props entity_props combat_entity_extra);
    ("Vec", vec_props);
    ("OfflinePlayer", offline_player_props);
  ]
  @ List.map (fun (e : event_def) -> ("event:" ^ e.e_name, e.e_props)) events

let check_duplicates () : issue list =
  List.concat_map
    (fun (owner, props) ->
      let seen = Hashtbl.create 16 in
      List.filter_map
        (fun p ->
          if Hashtbl.mem seen p.p_name then
            Some (mk owner p.p_name Duplicated "property name appears more than once under this owner")
          else begin
            Hashtbl.add seen p.p_name ();
            None
          end)
        props)
    (owner_prop_lists ())

(* --- top level --- *)

let all_issues () : issue list =
  check_duplicates ()
  @ List.concat_map (fun e -> check_event e @ check_wrapper_cancel e) events

let issue_json (i : issue) : Yojson.Safe.t =
  `Assoc
    [
      ("owner", `String i.owner);
      ("prop", `String i.prop);
      ("kind", `String (kind_slug i.kind));
      ("detail", `String i.detail);
    ]

(* machine-readable report (stable ordering for the golden fixture) *)
let report_json () : Yojson.Safe.t =
  let issues = all_issues () in
  `Assoc
    [
      ("clean", `Bool (issues = []));
      ("issue_count", `Int (List.length issues));
      ("issues", `List (List.map issue_json issues));
    ]

(* human report; returns (text, ok) *)
let report_text () : string * bool =
  let issues = all_issues () in
  let buf = Buffer.create 256 in
  List.iter
    (fun i ->
      Buffer.add_string buf
        (Printf.sprintf "%-16s %s.%s  %s\n" (kind_slug i.kind) i.owner i.prop i.detail))
    issues;
  if issues = [] then
    Buffer.add_string buf "check-props: 0 issues — property ownership tables agree with the catalogs\n"
  else
    Buffer.add_string buf (Printf.sprintf "check-props: %d issue(s)\n" (List.length issues));
  (Buffer.contents buf, issues = [])
