open Ast
open Registry

let rec join a b =
  if a = b then a
  else
    match (a, b) with
    | TAny, _ | _, TAny -> TAny
    | TInteger, TDouble | TDouble, TInteger -> TDouble
    (* Mob is a subtype of Entity (phase 7) *)
    | TMob, TEntity | TEntity, TMob -> TEntity
    (* Player is a subtype of OfflinePlayer (phase 8) *)
    | TPlayer, TOfflinePlayer | TOfflinePlayer, TPlayer -> TOfflinePlayer
    | TOptional x, TOptional y -> TOptional (join x y)
    | TOptional x, y | y, TOptional x -> TOptional (join x y)
    | TList x, TList y -> TList (join x y)
    | TMap (kx, vx), TMap (ky, vy) -> TMap (join kx ky, join vx vy)
    | _ -> TAny

let wrap_optional = function
  | TOptional _ as t -> t
  | TAny -> TOptional TAny
  | t -> TOptional t

let unwrap = function
  | TOptional t -> t
  | t -> t

let num_ok = function
  | TInteger | TDouble | TAny -> true
  | _ -> false

let num_join a b =
  match (a, b) with
  | TAny, _ | _, TAny -> TAny
  | TDouble, _ | _, TDouble -> TDouble
  | _ -> TInteger

let boolish = function
  | TBoolean | TAny -> true
  | _ -> false

let rec ty_of_dt = function
  | DSimple "STRING" -> TString
  | DSimple "INTEGER" -> TInteger
  | DSimple "DOUBLE" -> TDouble
  | DSimple "BOOLEAN" -> TBoolean
  | DSimple "PLAYER" -> TPlayer
  | DSimple "LOCATION" -> TLocation
  | DSimple "WORLD" -> TWorld
  | DSimple "ITEM" -> TItem
  | DSimple "MOB" -> TMob
  | DSimple "DISPLAY" -> TDisplay
  | DSimple "SONG" -> TSong
  | DSimple "SKIN" -> TSkin
  | DSimple "CANVAS" -> TCanvas
  | DSimple "SCHEDULE" -> TSchedule
  | DSimple "WORLD_LOADER" -> TWorldLoader
  | DSimple "ENTITY" -> TEntity
  | DSimple "VEC" -> TVec
  | DSimple "OFFLINE_PLAYER" -> TOfflinePlayer
  | DSimple _ -> TAny
  | DEither ts -> TEither (List.map ty_of_dt ts)
  | DOptional t -> TOptional (ty_of_dt t)
  | DList t -> TList (ty_of_dt t)
  | DMap (k, v) -> TMap (ty_of_dt k, ty_of_dt v)

let ty_of_type_name = function
  | "String" -> Some TString
  | "Integer" | "Int" | "int" -> Some TInteger
  | "Double" | "double" -> Some TDouble
  | "Boolean" | "Bool" | "bool" -> Some TBoolean
  | "Player" -> Some TPlayer
  | "Location" -> Some TLocation
  | "Item" -> Some TItem
  | "World" -> Some TWorld
  | "Mob" -> Some TMob
  | "Display" -> Some TDisplay
  | "Song" -> Some TSong
  | "Skin" -> Some TSkin
  | "Canvas" -> Some TCanvas
  | "Schedule" -> Some TSchedule
  | "WorldLoader" -> Some TWorldLoader
  | "Entity" -> Some TEntity
  | "Vec" -> Some TVec
  | "OfflinePlayer" -> Some TOfflinePlayer
  | _ -> None

let known_type_names =
  [ "String"; "Integer"; "Int"; "int"; "Double"; "double"; "Boolean"; "Bool"; "bool";
    "Player"; "Location"; "Item"; "World"; "Mob"; "Number"; "Display"; "Song"; "Skin";
    "Canvas"; "Schedule"; "WorldLoader"; "Entity"; "Vec"; "OfflinePlayer" ]
