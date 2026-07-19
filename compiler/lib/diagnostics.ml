type error = {
  file : string;
  line : int;
  col : int;
  msg : string;
}

exception Error of error

let raise_error ~file ~line ~col msg = raise (Error { file; line; col; msg })

let source_line source n =
  let lines = String.split_on_char '\n' source in
  List.nth_opt lines (n - 1)

let print_error source err =
  Printf.eprintf "%s:%d:%d: error: %s\n" err.file err.line err.col err.msg;
  match source_line source err.line with
  | Some text ->
    Printf.eprintf "%s\n" text;
    Printf.eprintf "%s^\n" (String.make (max 0 (err.col - 1)) ' ')
  | None -> ()

let to_json err : Yojson.Safe.t =
  `Assoc
    [ ( "error",
        `Assoc
          [ ("message", `String err.msg);
            ("line", `Int err.line);
            ("col", `Int err.col);
          ] );
    ]
