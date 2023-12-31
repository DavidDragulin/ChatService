(** This library is a convenience layer on top of raw inotify interface that
    maintains the required client-side bookkeeping to make sense of the events
    generated by the kernel and translate them in a form convenient for the
    client application.

    See [man 7 inotify] for the raw inotify documentation.

    The state maintained by [t] is not thread-safe and can only be interacted
    with in the context of a "scheduler" (async scheduler or fiber scheduler in
    dune). We assume that [add] is called in the context of the scheduler and
    that [send_emit_events_job_to_scheduler f] runs [f] in the context of the
    scheduler.

    Be aware that the interface of inotify makes it easy to write code with race
    conditions or other subtle pitfalls. For instance, stat'ing a file then
    watching it means you have lost any events between the stat and the watch.
    Or the behavior when watching a path whose inode has multiple hardlinks is
    non-obvious. *)

type t
type file_info = string * UnixLabels.stats

module Event : sig
  type move =
    | Away of string
    | Into of string
    | Move of string * string

  type t =
    | Created of string
    | Unlinked of string
    | Modified of string
    | Moved of move
    (** Queue overflow means that you are not consuming events fast enough
        and just lost some of them. This means that some changes to files
        you want might go unnoticed *)
    | Queue_overflow

  val to_string : t -> string
end

type modify_event_selector =
  [ `Any_change
    (** Send a Modified event whenever the contents of the file changes (which
        can be very often when writing a large file) *)
  | `Closed_writable_fd
    (** Only send a Modify event when someone with a file descriptor with write
        permission to that file is closed. There are usually many fewer of these
        events (for large files), but they come later. *)
  ]

(** [create path] creates an inotify watching path. Returns the inotify type t
    itself and the list of files currently being watched. By default,
    recursively watches all subdirectories of the given path. See [add_all] for
    caveats.

    [send_emit_events_job_to_scheduler f] is expected to run the job [f] in the
    scheduler, and then process the events returned by that job. *)
val create
  :  spawn_thread:((unit -> unit) -> unit)
  -> modify_event_selector:modify_event_selector
  -> log_error:(string -> unit)
  -> send_emit_events_job_to_scheduler:((unit -> Event.t list) -> unit)
  -> t

(** [add t path] add the path to t to be watched. The operation is synchronous,
    so when it returns the kernel has already acknowledged that the watch was
    set up. This may, in fact, block, but it's not safe to run this function in
    a separate thread. *)
val add : t -> string -> unit
