let version = "2.0.0"

let usage () =
  prerr_endline
    "Usage: swoftc compile <file.sw...> [--addon-path <dir>] [-o <out.json>] | swoftc check \
     <file.sw...> [--addon-path <dir>] | swoftc --property-table | swoftc --check-props [--json] \
     | swoftc --dump-symbols | swoftc --version";
  exit 2

(* Resolve entries + transitive imports into one compilation unit. Module
   loading raises Diagnostics.Error for unresolvable imports, cycles (with
   the cycle path), duplicate module names, and parse errors in any module. *)
let load_unit ~addon_path files =
  try Swoftlang.Modload.load ~addon_path files
  with Swoftlang.Diagnostics.Error err ->
    let source =
      try
        let ic = open_in_bin err.file in
        let n = in_channel_length ic in
        let s = really_input_string ic n in
        close_in ic;
        s
      with Sys_error _ -> ""
    in
    Swoftlang.Diagnostics.print_error source err;
    print_endline (Yojson.Safe.to_string (Swoftlang.Diagnostics.to_json err));
    exit 1

(* parse + typecheck the whole unit; typecheck errors block emission
   (warnings don't) *)
let front_end ~addon_path files =
  let modules = load_unit ~addon_path files in
  let inputs =
    List.map
      (fun (m : Swoftlang.Modload.unit_module) ->
        {
          Swoftlang.Typecheck.tm_name = m.mu_name;
          tm_file = m.mu_path;
          tm_imports = m.mu_imports;
          tm_script = m.mu_script;
        })
      modules
  in
  (match Swoftlang.Typecheck.run_all inputs with
  | [] -> ()
  | first :: _ as errors ->
    List.iter
      (fun (e : Swoftlang.Diagnostics.error) ->
        let source =
          match
            List.find_opt
              (fun (m : Swoftlang.Modload.unit_module) -> m.mu_path = e.file)
              modules
          with
          | Some m -> m.mu_source
          | None -> ""
        in
        Swoftlang.Diagnostics.print_error source e)
      errors;
    print_endline (Yojson.Safe.to_string (Swoftlang.Diagnostics.to_json first));
    exit 1);
  modules

let emit_unit (modules : Swoftlang.Modload.unit_module list) =
  match modules with
  | [ single ] when single.mu_script.imports = [] && single.mu_script.module_vars = [] ->
    (* single file, no module machinery: the original flat shape, byte-
       identical for every pre-module script *)
    Swoftlang.Emit.script single.mu_script
  | _ ->
    Swoftlang.Emit.bundle
      (List.map
         (fun (m : Swoftlang.Modload.unit_module) ->
           (m.mu_name, m.mu_path, m.mu_entry, m.mu_script))
         modules)

let compile ~addon_path files out =
  let modules = front_end ~addon_path files in
  let text = Yojson.Safe.pretty_to_string (emit_unit modules) ^ "\n" in
  match out with
  | None -> print_string text
  | Some path ->
    let oc = open_out path in
    output_string oc text;
    close_out oc

let check ~addon_path files = ignore (front_end ~addon_path files)

(* <files...> [--addon-path <dir>] [-o <out.json>] *)
let parse_args args =
  let files = ref [] in
  let addon_path = ref None in
  let out = ref None in
  let rec go = function
    | [] -> ()
    | "--addon-path" :: dir :: rest ->
      addon_path := Some dir;
      go rest
    | [ "--addon-path" ] -> usage ()
    | "-o" :: path :: rest ->
      out := Some path;
      go rest
    | [ "-o" ] -> usage ()
    | file :: rest ->
      files := file :: !files;
      go rest
  in
  go args;
  if !files = [] then usage ();
  (List.rev !files, !addon_path, !out)

let () =
  match Array.to_list Sys.argv with
  | _ :: [ "--version" ] -> print_endline ("swoftc " ^ version)
  | _ :: [ "--property-table" ] ->
    print_endline (Yojson.Safe.pretty_to_string (Swoftlang.Registry.property_table_json ()))
  | _ :: [ "--check-props" ] ->
    let text, ok = Swoftlang.Check_props.report_text () in
    print_string text;
    if not ok then exit 1
  | _ :: [ "--check-props"; "--json" ] ->
    let json = Swoftlang.Check_props.report_json () in
    print_endline (Yojson.Safe.pretty_to_string json);
    (match json with
    | `Assoc kv when List.assoc_opt "clean" kv = Some (`Bool true) -> ()
    | _ -> exit 1)
  | _ :: [ "--dump-symbols" ] ->
    print_endline (Yojson.Safe.pretty_to_string (Swoftlang.Registry.dump_symbols_json ()))
  | _ :: "compile" :: rest ->
    let files, addon_path, out = parse_args rest in
    compile ~addon_path files out
  | _ :: "check" :: rest ->
    let files, addon_path, out = parse_args rest in
    if out <> None then usage ();
    check ~addon_path files
  | _ -> usage ()
