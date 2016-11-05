

(* set ocamlfind_ready to false if your ocamlfind is unable to find the package,
   pyml.py will be assumed to be in the current directory *)
let ocamlfind_ready = true
let read_pipe_name = ".pyml_to_ocaml"
let write_pipe_name = ".pyml_to_python"

exception Unknown_return_type of string
exception Wrong_Pytype
exception Could_not_create_pipe


(* TYPES *)

type pipe = {
	path: string ;
	fd: Unix.file_descr ;
}

type pycommunication = {
	read_pipe: pipe ;
	write_pipe: pipe ;
	process_in: in_channel ;
	process_out: out_channel ;
}

type pymodule = pycommunication * string

type pyobj =
	Pystr of string
	| Pyint of int
	| Pylist of pyobj list
	| Pyfloat of float
	| Pynone


(* SERIALIZATION / DESERIALIZATION *)

let int64_mod i n =
	Int64.sub i (Int64.mul (Int64.div i (Int64.of_int n)) (Int64.of_int n))

let int64_to_bytes i =
	let bytes = Bytes.make 8 (Char.chr 0) in
	let rec _to_bytes bytes i ind =
		Bytes.set bytes ind (Char.chr (Int64.to_int (int64_mod i 256))) ;
		match ind with
		| 0 -> ()
		| n -> _to_bytes bytes (Int64.div i (Int64.of_int 256)) (n - 1)
	in
	_to_bytes bytes i 7 ;
	bytes

let bytes_to_int bytes nb =
	let rec _to_int bytes ind nb ret =
		let tmp = Char.code (Bytes.get bytes ind) in
		match nb - ind - 1 with
		| 0 -> ret * 256 + tmp
		| _ -> _to_int bytes (ind + 1) nb (ret * 256 + tmp)
	in
	_to_int bytes 0 nb 0

let send_bytes py bytes =
	let len = Int64.of_int (String.length bytes) in
	ignore (Unix.write py.write_pipe.fd (int64_to_bytes len) 0 8) ;
	ignore (Unix.write py.write_pipe.fd bytes 0 (String.length bytes))

let get_bytes py =
	let len = Bytes.make 8 (Char.chr 0) in
	ignore (Unix.read py.read_pipe.fd len 0 8) ;
	let to_read = bytes_to_int len 8 in
	let ret_bytes = Bytes.make to_read (Char.chr 0) in
	ignore (Unix.read py.read_pipe.fd ret_bytes 0 to_read) ;
	ret_bytes

let compose f g x = f (g x)

let rec deserialize_list lst =
	List.map (compose deserialize Bson.get_doc_element) lst

and deserialize doc =
	let element = Bson.get_element "v" doc in
	match Bson.get_string (Bson.get_element "t" doc) with
	| "s" -> Pystr (Bson.get_string element)
	| "i" -> Pyint (Int64.to_int (Bson.get_int64 element))
	| "l" -> Pylist (deserialize_list (Bson.get_list element))
	| "f" -> Pyfloat (Bson.get_double element)
	| "n" -> Pynone
	| n -> raise (Unknown_return_type n)

let rec serialize_list lst =
	Bson.create_list (List.map serialize lst)

and serialize = function
	| Pystr str -> Bson.create_string str
	| Pyint i -> Bson.create_int64 (Int64.of_int i)
	| Pylist lst -> serialize_list lst
	| Pyfloat f -> Bson.create_double f
	| Pynone -> Bson.create_null ()


(* COMMUNICATION UTILS *)

let get_random_characters () =
	String.init 10 (fun i -> Char.chr (Random.int 26 + Char.code 'a'))

let rec create_pipe path =
	let rand_path = path ^ (get_random_characters ()) in
	if Sys.file_exists rand_path then create_pipe path
	else (
		(try Unix.mkfifo rand_path 0o777 with
			| Unix.Unix_error _ -> raise Could_not_create_pipe) ;
		rand_path
	)

let get_pipes path_read path_write =
	(* set O_SYNC to have synchronous (unbuffered) communication,
	   so we don't have to flush, maybe O_DSYNC instead ? *)
	let fd_read = Unix.openfile path_read [Unix.O_RDONLY; Unix.O_SYNC] 0o777 in
	let fd_write = Unix.openfile path_write [Unix.O_WRONLY; Unix.O_SYNC] 0o777 in
	({path = path_read ; fd = fd_read}, {path = path_write ; fd = fd_write})

let create_process exec pyroot read_pipe_path write_pipe_path =
	let path = (
		if ocamlfind_ready then
			"`ocamlfind query pyml`" ^ Filename.dir_sep
		else
			""
	) in 
	Unix.open_process (exec ^ " " ^ path ^ "pyml.py " ^ pyroot ^ " " ^ read_pipe_path ^ " " ^ write_pipe_path)


(* INTERFACE *)

let get_module py mod_name =
	(py, mod_name)

let pycall_raw py mod_name func_name args =
	let doc = Bson.empty in
	let lst = serialize_list args in
	let doc = Bson.add_element "a" lst doc in
	let doc = Bson.add_element "m" (Bson.create_string mod_name) doc in
	let doc = Bson.add_element "f" (Bson.create_string func_name) doc in
	let bytes = Bson.encode doc in
	send_bytes py bytes ;
	let ret_bytes = get_bytes py in
	let ret_doc = Bson.decode ret_bytes in
	deserialize ret_doc

let get modul func args =
	pycall_raw (fst modul) (snd modul) func args

let call modul func args =
	ignore (get modul func args)

let get_string modul func args =
	match get modul func args with
	| Pystr s -> s
	| _ -> raise Wrong_Pytype

let get_int modul func args =
	match get modul func args with
	| Pyint i -> i
	| _ -> raise Wrong_Pytype

let get_float modul func args =
	match get modul func args with
	| Pyfloat f -> f
	| _ -> raise Wrong_Pytype

let get_list modul func args =
	match get modul func args with
	| Pylist l -> l
	| _ -> raise Wrong_Pytype

let close py =
	send_bytes py "done" ;
	ignore (Unix.close_process (py.process_in, py.process_out)) ;
	Sys.remove py.read_pipe.path ;
	Sys.remove py.write_pipe.path

let init ?(exec="python3") pyroot =
	Random.self_init () ;
	let read_pipe_path = pyroot ^ Filename.dir_sep ^ read_pipe_name in
	let write_pipe_path = pyroot ^ Filename.dir_sep ^ write_pipe_name in
	let read_pipe_path = create_pipe read_pipe_path in
	let write_pipe_path = create_pipe write_pipe_path in
	let process_in, process_out = create_process exec pyroot read_pipe_path write_pipe_path in
	let read_pipe, write_pipe = get_pipes read_pipe_path write_pipe_path in
	{
		read_pipe = read_pipe ;
		write_pipe = write_pipe ;
		process_in = process_in ;
		process_out = process_out
	}
