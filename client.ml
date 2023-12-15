open Unix

let buffer_size = 1024

let () =
  let server_ip = "127.0.0.1" in
  let port = 8080 in
  let server_addr = ADDR_INET (inet_addr_of_string server_ip, port) in
  let sock = socket PF_INET SOCK_STREAM 0 in
  try
    connect sock server_addr;
    Printf.printf "Connected to the server. Type your messages:\n";
    try
      while true do
        let msg = read_line () in
        let sent_bytes = send sock (Bytes.of_string msg) 0 (String.length msg) [] in
        if sent_bytes = 0 then raise End_of_file;
        let buffer = Bytes.create buffer_size in
        let recv_len = recv sock buffer 0 buffer_size [] in
        if recv_len = 0 then raise End_of_file;
        let response = Bytes.sub_string buffer 0 recv_len in
        Printf.printf "Server response: %s\n" response;
      done
    with
    | End_of_file | Unix_error (EPIPE, _, _) ->
        Printf.printf "Connection to server lost.\n"
    | exn -> Printf.printf "An error occurred while sending/receiving: %s\n" (Printexc.to_string exn)
  with
  | Unix_error (err, _, _) when err = ECONNREFUSED ->
      Printf.printf "Could not connect to the server. Is it running?\n"
  | exn -> Printf.printf "An error occurred while connecting: %s\n" (Printexc.to_string exn);
  close sock
