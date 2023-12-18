open Unix
open Printf
open Thread

(* Configuration Parameters *)
let buffer_size = 1024
let default_port = 8080

(* Shared resources and synchronization primitives *)
let queue = Queue.create ()
let queue_mutex = Mutex.create ()
let condition = Condition.create ()
let active_client = ref None

(* Function to send status messages to the client *)
let inform_client_of_status sock msg =
  ignore (send sock (Bytes.of_string msg) 0 (String.length msg) [])

(* Function to handle client communication *)
let handle_client sock =
  let buffer = Bytes.create buffer_size in
  try
    while true do
      let recv_len = recv sock buffer 0 buffer_size [] in
      if recv_len = 0 then raise Exit;
      let msg = Bytes.sub_string buffer 0 recv_len in
      Printf.printf "Received: %s\n%!" msg;
      let response = "Message received" in
      ignore (send sock (Bytes.of_string response) 0 (String.length response) []);
    done
  with
  | Exit -> 
      Printf.printf "Client disconnected\n%!";
  | exn -> 
      Printf.printf "An error occurred: %s\n%!" (Printexc.to_string exn);
  close sock;
  active_client := None

(* Function to serve clients from the queue *)
let rec serve_clients () =
  Mutex.lock queue_mutex;
  while Queue.is_empty queue do
    Condition.wait condition queue_mutex;
  done;
  let client_sock = Queue.take queue in
  active_client := Some client_sock;
  Mutex.unlock queue_mutex;
  inform_client_of_status client_sock "You are now connected to the server.\n";
  handle_client client_sock;
  active_client := None;
  serve_clients ()

(* Main server function *)
let () =
  let port = if Array.length Sys.argv > 1 then int_of_string Sys.argv.(1) else default_port in
  let server_sock = socket PF_INET SOCK_STREAM 0 in
  setsockopt server_sock SO_REUSEADDR true;
  let host_addr = inet_addr_any in
  bind server_sock (ADDR_INET (host_addr, port));
  listen server_sock 10;
  Printf.printf "Server is listening on port %d\n" port;

  let _ = create serve_clients () in

  while true do
    let (client_sock, _) = accept server_sock in
    Mutex.lock queue_mutex;
    Queue.add client_sock queue;
    if !active_client = None then
      Condition.signal condition
    else
      inform_client_of_status client_sock "Please wait, another client is being served.\n";
    Mutex.unlock queue_mutex;
  done
