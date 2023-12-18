open Unix

(* Configuration Parameters *)
let buffer_size = 1024
let default_server_ip = "127.0.0.1"
let default_port = 8080

(* Function to connect to the server and handle communication *)
let () =
  let server_ip = if Array.length Sys.argv > 1 then Sys.argv.(1) else default_server_ip in
  let port = if Array.length Sys.argv > 2 then int_of_string Sys.argv.(2) else default_port in
  let server_addr = ADDR_INET (inet_addr_of_string server_ip, port) in
  let sock = socket PF_INET SOCK_STREAM 0 in

  try
    (* Establish connection *)
    connect sock server_addr;
    let buffer = Bytes.create buffer_size in
    let recv_len = recv sock buffer 0 buffer_size [] in
    if recv_len = 0 then raise End_of_file;
    let response = Bytes.sub_string buffer 0 recv_len in
    Printf.printf "Server response: %s\n" response;

    (* Message exchange loop *)
    if response = "You are now connected to the server.\n" then
      try
        while true do
          let msg = read_line () in
          let t1 = Unix.gettimeofday () in
          let sent_bytes = send sock (Bytes.of_string msg) 0 (String.length msg) [] in
          if sent_bytes = 0 then raise End_of_file;
          let recv_len = recv sock buffer 0 buffer_size [] in
          if recv_len = 0 then raise End_of_file;
          let t2 = Unix.gettimeofday () in
          let response = Bytes.sub_string buffer 0 recv_len in
          Printf.printf "Server response: %s\n" response;
          Printf.printf "Round trip time: %f seconds\n" (t2 -. t1);
        done
      with
      | End_of_file | Unix_error (EPIPE, _, _) ->
          Printf.printf "Connection to server lost.\n"
      | exn -> Printf.printf "An error occurred while sending/receiving: %s\n" (Printexc.to_string exn)
    else
      Printf.printf "Waiting for the server to be free...\n"
  with
  | Unix_error (err, _, _) when err = ECONNREFUSED ->
      Printf.printf "Could not connect to the server. Is it running?\n"
  | exn -> Printf.printf "An error occurred while connecting: %s\n" (Printexc.to_string exn);
  close sock
