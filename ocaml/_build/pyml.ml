

let read_pipe_name = "my_named_pipe"
let write_pipe_name = "my_named_pipe2"

type pyobj =
	Pystr of string
	| Pyint of int
	| Pylist of pyobj list
	| Pynone

type pipe = {
	name: string ;
	fd: Unix.file_descr ;
}

exception Unknown_return_type of string

let compose f g x = f (g x)

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
		match ind - nb with
		| 0 -> ret * 256 + tmp
		| _ -> _to_int bytes (ind + 1) nb (ret * 256 + tmp)
	in
	_to_int bytes 0 nb 0

let send_bytes py bytes =
	let len = Int64.of_int (String.length bytes) in
	ignore (Unix.write py#get_write_pipe.fd (int64_to_bytes len) 0 8) ;
	ignore (Unix.write py#get_write_pipe.fd bytes 0 (String.length bytes))

let get_bytes py =
	let len = Bytes.make 8 (Char.chr 0) in
	ignore (Unix.read py#get_read_pipe.fd len 0 8) ;
	let to_read = bytes_to_int len 8 in
	let ret_bytes = Bytes.make to_read (Char.chr 0) in
	ignore (Unix.read py#get_read_pipe.fd ret_bytes 0 to_read) ;
	ret_bytes

let rec deserialize_list lst =
	List.map (compose deserialize Bson.get_doc_element) lst

and deserialize doc =
	let element = Bson.get_element "v" doc in
	match Bson.get_string (Bson.get_element "t" doc) with
	| "s" -> Pystr (Bson.get_string element)
	| "i" -> Pyint (Int64.to_int (Bson.get_int64 element))
	| "l" -> Pylist (deserialize_list (Bson.get_list element))
	| "n" -> Pynone
	| n -> raise (Unknown_return_type n)

let rec serialize_list lst =
	Bson.create_list (List.map serialize lst)

and serialize = function
	| Pystr str -> Bson.create_string str
	| Pyint i -> Bson.create_int64 (Int64.of_int i)
	| Pylist lst -> serialize_list lst
	| Pynone -> Bson.create_null ()

let pycall_raw py mod_name func_name args =
	let doc = Bson.empty in
	let lst = serialize_list args in
	let doc = Bson.add_element "a" lst doc in
	let doc = Bson.add_element "m" (Bson.create_string mod_name) doc in
	let doc = Bson.add_element "f" (Bson.create_string func_name) doc in
	let bytes = Bson.encode doc in
	send_bytes py bytes ;
	let ret_bytes = get_bytes py in
	let doc = Bson.decode bytes in
	deserialize doc

let pycall py mod_name func_name args =
	pycall_raw py mod_name func_name args 

class pymodule py mod_name =
	object
		val _py = py
		val _name = mod_name

		method call =
			pycall _py _name 
	end

class py read_pipe write_pipe =
	object (self)
		val _read_pipe = read_pipe
		val _write_pipe = write_pipe

		method get_module mod_name =
			new pymodule self mod_name

		method get_read_pipe = _read_pipe

		method get_write_pipe = _write_pipe
	end

let create_pipe name =
	try Unix.mkfifo name 0o777 with
		| Unix.Unix_error _ -> ignore ()

let get_pipes name_read name_write =
	(* set O_SYNC to have synchronous (unbuffered) communication,
	   so we don't have to flush, maybe O_DSYNC instead ? *)
	let fd_read = Unix.openfile name_read [Unix.O_RDONLY; Unix.O_SYNC] 0o777 in
	let fd_write = Unix.openfile name_write [Unix.O_WRONLY; Unix.O_SYNC] 0o777 in
	({name = name_read ; fd = fd_read}, {name = name_write ; fd = fd_write})

let create_process () =
	let (in_c, out_c) = Unix.open_process "python3 test2.py" in
	()

let init pyroot =
	create_pipe read_pipe_name ;
	create_pipe write_pipe_name ;
	create_process () ;
	let (read_pipe, write_pipe) = get_pipes read_pipe_name write_pipe_name in
	new py read_pipe write_pipe