let swoftc = Sys.argv.(1)
let failures = ref 0
let total = ref 0

let fail fmt =
  Printf.ksprintf
    (fun s ->
      incr failures;
      Printf.printf "FAIL: %s\n" s)
    fmt

let read_file path =
  let ic = open_in_bin path in
  let n = in_channel_length ic in
  let s = really_input_string ic n in
  close_in ic;
  s

let contains haystack needle =
  let hl = String.length haystack in
  let nl = String.length needle in
  if nl = 0 then true
  else begin
    let found = ref false in
    for i = 0 to hl - nl do
      if (not !found) && String.sub haystack i nl = needle then found := true
    done;
    !found
  end

let run_capture args =
  let out = Filename.temp_file "swoftc_test" ".out" in
  let err = Filename.temp_file "swoftc_test" ".err" in
  let cmd =
    Printf.sprintf "%s %s > %s 2> %s" (Filename.quote swoftc) args
      (Filename.quote out) (Filename.quote err)
  in
  let code = Sys.command cmd in
  let stdout_text = read_file out in
  let stderr_text = read_file err in
  Sys.remove out;
  Sys.remove err;
  (code, stdout_text, stderr_text)

let norm json = Yojson.Safe.to_string (Yojson.Safe.sort json)

let golden_case sw =
  incr total;
  let expected_path = Filename.chop_suffix sw ".sw" ^ ".expected.json" in
  let code, out, err = run_capture (Printf.sprintf "compile %s" (Filename.quote sw)) in
  if code <> 0 then fail "%s: expected exit 0, got %d (stderr: %s)" sw code err
  else
    match Yojson.Safe.from_string out with
    | exception _ -> fail "%s: stdout is not valid JSON" sw
    | actual ->
      let expected = Yojson.Safe.from_file expected_path in
      if norm actual <> norm expected then
        fail "%s: JSON mismatch\n--- expected ---\n%s\n--- actual ---\n%s" sw
          (Yojson.Safe.pretty_to_string expected)
          (Yojson.Safe.pretty_to_string actual)

let error_case sw =
  incr total;
  let expected_sub =
    String.trim (read_file (Filename.chop_suffix sw ".sw" ^ ".expected"))
  in
  let code, out, err = run_capture (Printf.sprintf "compile %s" (Filename.quote sw)) in
  if code <> 1 then fail "%s: expected exit 1, got %d" sw code;
  if not (contains err expected_sub) then
    fail "%s: stderr missing %S\nstderr was:\n%s" sw expected_sub err;
  (match Yojson.Safe.from_string out with
  | exception _ -> fail "%s: stdout is not valid error JSON: %s" sw out
  | `Assoc kv when List.mem_assoc "error" kv -> ()
  | _ -> fail "%s: stdout JSON lacks \"error\" key: %s" sw out);
  (* 'check' runs the same parse+typecheck pipeline *)
  let check_code, _, check_err = run_capture (Printf.sprintf "check %s" (Filename.quote sw)) in
  if check_code <> 1 then fail "%s: 'check' expected exit 1, got %d" sw check_code;
  if not (contains check_err expected_sub) then
    fail "%s: 'check' stderr missing %S" sw expected_sub

let property_table_case () =
  incr total;
  let code, out, err = run_capture "--property-table" in
  if code <> 0 then fail "--property-table: expected exit 0, got %d (stderr: %s)" code err
  else
    match Yojson.Safe.from_string out with
    | exception _ -> fail "--property-table: stdout is not valid JSON"
    | actual ->
      let expected = Yojson.Safe.from_file "property-table.json" in
      if norm actual <> norm expected then
        fail
          "--property-table output does not match property-table.json; regenerate the fixture \
           and update the Java PropertyRegistry to match"

let list_cases dir suffix =
  Sys.readdir dir |> Array.to_list
  |> List.filter (fun f -> Filename.check_suffix f suffix)
  |> List.sort compare
  |> List.map (Filename.concat dir)

let () =
  List.iter golden_case (list_cases "cases" ".sw");
  List.iter error_case (list_cases "errors" ".sw");
  property_table_case ();
  if !failures > 0 then begin
    Printf.printf "%d of %d test(s) failed\n" !failures !total;
    exit 1
  end
  else Printf.printf "all %d tests passed\n" !total
