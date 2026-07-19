(* Module graph resolution (design 6A): entry files plus their transitive
   imports are read, parsed, and returned as one compilation unit in
   dependency order (every module appears after all of its imports).

   Import forms:
     import "name"          — <importing script's dir>/name.sw, then
                              <addon path>/name.sw
     import "./util.sw"     — path relative to the importing file (may use
                              ../ and omit the .sw suffix)

   The addon path defaults to an 'addons' directory next to the first entry
   file. Cycles are compile errors carrying the full cycle path. Duplicate
   imports of the same module are a no-op. *)

type unit_module = {
  mu_name : string; (* file basename without .sw — the module's symbol namespace *)
  mu_path : string; (* normalized path as resolved (identity key) *)
  mu_entry : bool; (* true for files passed on the command line *)
  mu_imports : string list; (* module names of direct imports, deduped, in order *)
  mu_script : Ast.script;
  mu_source : string;
}

let read_file path =
  let ic = open_in_bin path in
  let n = in_channel_length ic in
  let s = really_input_string ic n in
  close_in ic;
  s

(* Lexical path normalization: collapse '.', '..', '//'. No symlink
   resolution — identity only has to be stable across the spellings the
   resolver itself produces. *)
let normalize path =
  let absolute = String.length path > 0 && path.[0] = '/' in
  let parts = String.split_on_char '/' path in
  let out =
    List.fold_left
      (fun acc part ->
        match part with
        | "" | "." -> acc
        | ".." -> (
          match acc with
          | top :: rest when top <> ".." -> rest
          | _ -> if absolute then acc else ".." :: acc)
        | p -> p :: acc)
      [] parts
  in
  let joined = String.concat "/" (List.rev out) in
  if absolute then "/" ^ joined
  else if joined = "" then "."
  else joined

let module_name_of_path path =
  let base = Filename.basename path in
  if Filename.check_suffix base ".sw" then Filename.chop_suffix base ".sw" else base

let with_sw spec = if Filename.check_suffix spec ".sw" then spec else spec ^ ".sw"

let import_error ~file ~(pos : Ast.pos) fmt =
  Printf.ksprintf
    (fun msg -> Diagnostics.raise_error ~file ~line:pos.line ~col:pos.col msg)
    fmt

(* Resolve one import spec from the file at [from_path]. *)
let resolve_import ~addon_path ~from_path ~pos spec =
  let dir = Filename.dirname from_path in
  if String.contains spec '/' then begin
    (* path import, relative to the importing file *)
    let candidate = normalize (Filename.concat dir (with_sw spec)) in
    if Sys.file_exists candidate then candidate
    else
      import_error ~file:from_path ~pos "cannot resolve import \"%s\" (looked for %s)" spec
        candidate
  end
  else begin
    (* bare module name: script dir first, then the addon path *)
    let local = normalize (Filename.concat dir (with_sw spec)) in
    let addon = normalize (Filename.concat addon_path (with_sw spec)) in
    if Sys.file_exists local then local
    else if Sys.file_exists addon then addon
    else
      import_error ~file:from_path ~pos "cannot resolve import \"%s\" (looked for %s and %s)"
        spec local addon
  end

(* "a -> b -> a" from the outermost-first stack and the revisited target *)
let cycle_chain rev_stack target =
  let rec from_target = function
    | [] -> []
    | (p, n) :: rest -> if p = target then n :: List.map snd rest else from_target rest
  in
  String.concat " -> " (from_target rev_stack @ [ module_name_of_path target ])

let load ~addon_path entries =
  (match entries with
  | [] -> failwith "no entry files"
  | _ -> ());
  let addon_path =
    match addon_path with
    | Some d -> d
    | None -> Filename.concat (Filename.dirname (List.hd entries)) "addons"
  in
  let visited : (string, unit_module) Hashtbl.t = Hashtbl.create 8 in
  let in_stack : (string, unit) Hashtbl.t = Hashtbl.create 8 in
  let names : (string, string) Hashtbl.t = Hashtbl.create 8 in
  (* completed modules in postorder: every module after all of its imports *)
  let order = ref [] in
  (* stack: innermost-last (outermost-first) list of (path, name) *)
  let rec visit ~entry ~stack path ~import_site =
    let path = normalize path in
    if Hashtbl.mem in_stack path then begin
      let cycle = cycle_chain stack path in
      match import_site with
      | Some (file, pos) -> import_error ~file ~pos "import cycle: %s" cycle
      | None -> failwith ("import cycle: " ^ cycle)
    end;
    match Hashtbl.find_opt visited path with
    | Some existing ->
      (* already loaded through another entry/importer: single registration,
         but command-line entries keep their entry status *)
      if entry && not existing.mu_entry then
        Hashtbl.replace visited path { existing with mu_entry = true };
      existing.mu_name
    | None ->
      if not (Sys.file_exists path) then begin
        match import_site with
        | Some (file, pos) -> import_error ~file ~pos "cannot resolve import: no such file '%s'" path
        | None ->
          Printf.eprintf "swoftc: error: no such file '%s'\n" path;
          exit 1
      end;
      let name = module_name_of_path path in
      (match Hashtbl.find_opt names name with
      | Some other when other <> path ->
        let file, pos =
          match import_site with
          | Some (f, p) -> (f, p)
          | None -> (path, { Ast.line = 1; col = 1 })
        in
        import_error ~file ~pos
          "two modules with the same name '%s': %s and %s (module names come from file \
           basenames and must be unique)"
          name other path
      | _ -> Hashtbl.replace names name path);
      let source = read_file path in
      let script = Parser.parse ~file:path source in
      Hashtbl.replace in_stack path ();
      let stack' = stack @ [ (path, name) ] in
      let imports =
        List.fold_left
          (fun acc (im : Ast.import_decl) ->
            let target =
              resolve_import ~addon_path ~from_path:path ~pos:im.im_pos im.im_spec
            in
            let child =
              visit ~entry:false ~stack:stack' target ~import_site:(Some (path, im.im_pos))
            in
            (* duplicate import of the same module is a no-op *)
            if List.mem child acc then acc else child :: acc)
          [] script.imports
      in
      Hashtbl.remove in_stack path;
      Hashtbl.replace visited path
        {
          mu_name = name;
          mu_path = path;
          mu_entry = entry;
          mu_imports = List.rev imports;
          mu_script = script;
          mu_source = source;
        };
      order := path :: !order;
      name
  in
  List.iter (fun e -> ignore (visit ~entry:true ~stack:[] e ~import_site:None)) entries;
  List.rev_map (fun path -> Hashtbl.find visited path) !order
