let _ =
  (* The ugly one-line match is for error message compatibility with 4.09. *)
  match%lwt Lwt.return_unit with exception Exit -> Lwt.return 0
