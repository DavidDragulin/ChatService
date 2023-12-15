open Unix
open Printf

let buffer_size = 1024
let queue = Queue.create ()

let inform_client_of_status sock is_active =
  let msg = if is_active then "You are now connected to the server.\n" else "Waiting for your turn to connect...\n" in
  ignore (send sock (Bytes.of_string msg) 0 (String.length msg) [])

let rec handle_client sock =
  let buffer = Bytes.create buffer_size in
  try
    while true do
      let recv_len = recv sock buffer 0 buffer_size [] in
      if recv_len = 0 then raise Exit;
      let msg = Bytes.sub_string buffer 0 recv_len in
      printf "Received: %s\n" msg;
      let response = "Message received" in
      ignore (send sock (Bytes.of_string response) 0 (String.length response) []);
    done
  with
  | Exit -> printf "Client disconnected\n"
  | exn -> printf "An error occurred: %s\n" (Printexc.to_string exn)

let rec serve_clients () =
  match Queue.take_opt queue with
  | Some client_sock ->
      if Queue.length queue = 1 then
        inform_client_of_status client_sock true;  (* Inform the client they are now being served *)
      handle_client client_sock;
      close client_sock;
      serve_clients ()
  | None -> ()

let () =
  let server_sock = socket PF_INET SOCK_STREAM 0 in
  setsockopt server_sock SO_REUSEADDR true;
  let host_addr = inet_addr_any in
  let port = 8080 in
  bind server_sock (ADDR_INET (host_addr, port));
  listen server_sock 10;
  printf "Server is listening on port %d\n" port;

  while true do
    let (client_sock, _) = accept server_sock in
    Queue.add client_sock queue;
    if Queue.length queue = 1 then
      serve_clients ()
    else
      inform_client_of_status client_sock false;  (* Inform waiting clients *)
  done
