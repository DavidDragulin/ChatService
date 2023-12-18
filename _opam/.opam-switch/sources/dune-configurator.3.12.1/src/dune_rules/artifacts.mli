open Import

type t

(** Force the computation of the internal list of binaries. This is exposed as
    some error checking is only performed during this computation and some
    errors will go unreported unless this computation takes place. *)
val force : t -> unit Memo.t

val bin_dir_basename : Filename.t

(** [local_bin dir] The directory which contains the local binaries viewed by
    rules defined in [dir] *)
val local_bin : Path.Build.t -> Path.Build.t

(** A named artifact that is looked up in the PATH if not found in the tree If
    the name is an absolute path, it is used as it. *)
val binary : t -> ?hint:string -> loc:Loc.t option -> string -> Action.Prog.t Memo.t

val binary_available : t -> string -> bool Memo.t
val add_binaries : t -> dir:Path.Build.t -> File_binding.Expanded.t list -> t
val create : Context.t -> local_bins:Path.Build.Set.t Memo.Lazy.t -> t
