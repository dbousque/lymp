

let read_pipe_name = "my_named_pipe"
let write_pipe_name = "my_named_pipe2"

let pycall_raw serialize deserialize py mod_name func_name args =


let pycall py mod_name func_name args =
	let ret_bson = pycall_raw py mod_name func_name args in


class pymodule py mod_name =
	object
		val _py = py
		val _name = mod_name

	method call =
		pycall _py _name 

class py read_pipe write_pipe =
	object (self)
		val _read_pipe = read_pipe
		val _write_pipe = write_pipe

	method get_module mod_name =
		pymodule self mod_name

type pipe = {
	name: str ;
	fd: Unix.file_descr
}

let create_pipe name =
	try Unix.mkfifo name 0o777 with
		| Unix.Unix_error _ -> ignore ()

let get_pipes name_read name_write =
	(* set O_SYNC to have synchronous (unbuffered) communication,
	   so we don't have to flush, maybe O_DSYNC instead ? *)
	let fd_read = Unix.openfile name_read [Unix.O_RDONLY, O_SYNC] 0o777 in
	let fd_write = Unix.openfile name_write [Unix.O_WRONLY, O_SYNC] 0o777 in
	(pipe {name: name_read ; fd: fd_read}, pipe {name: name_write ; fd: fd_write})

let communicate fd_read fd_write process_stdout =
	let bytes = Bytes.create 10 in
	let inp_bytes = Bytes.create 10 in
	let oldstdout = Unix.dup Unix.stdout in
	Bytes.set bytes 0 (Char.chr 6) ;
	Bytes.set bytes 1 's' ;
	Bytes.set bytes 2 'a' ;
	Bytes.set bytes 3 'l' ;
	Bytes.set bytes 4 'u' ;
	Bytes.set bytes 5 't' ;
	Bytes.set bytes 6 '\n' ;
	while true do
		ignore (Unix.write fd_write bytes 0 1) ;
		ignore (Unix.write fd_write bytes 0 6) ;
		print_endline "waiting for nb_to_read" ;
		ignore (Unix.read fd_read inp_bytes 0 1) ;
		print_endline "got it" ;
		ignore (Unix.read fd_read inp_bytes 0 (Char.code (Bytes.get inp_bytes 0))) ;
		print_string "got : " ;
		print_endline inp_bytes
	done

let create_process () =
	let (in_c, out_c) = Unix.open_process "python3 test2.py" in
	()

let init pyroot =
	create_pipe read_pipe_name ;
	create_pipe write_pipe_name ;
	create_process () ;
	let (read_pipe, write_pipe) = get_pipes read_pipe_name write_pipe_name in
	py read_pipe write_pipe