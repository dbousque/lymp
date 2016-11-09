

(* TESTING PYREF AND WRONGTYPE EXCEPTION *)

let ocamlfind_ok = (try (Sys.getenv "OCAMLFIND_OK" ; true) with | _ -> false)
let py = if ocamlfind_ok then Pyml.init "." else Pyml.init ~exec:"python3" ~ocamlfind:false ~pymlpy_dirpath:"srcs" "."
let modul = Pyml.get_module py "modul"

let file_lines filename =
	let lines = ref [] in
	let chan = open_in filename in
	try
		while true; do
			lines := input_line chan :: !lines
		done ;
		!lines
	with End_of_file ->
		close_in chan ;
		List.rev !lines

let rec check_lines lines expected_lines =
	match expected_lines with
	| [] -> ()
	| e::rest_e -> match lines with
				 | [] -> raise (Failure "failed")
				 | l::rest_l -> if l <> e then raise (Failure "failed") else check_lines rest_l rest_e

let () =
	ignore (try (Pyml.get_string modul "get_tuple" [])
	with Pyml.Wrong_Pytype -> "") ;
	let tuple = Pyml.get modul "get_tuple" [] in
	( match tuple with
	| Pyml.Pyref p -> ()
	| _ -> raise (Failure "failed")) ;

	(* ASSERTING THAT PASSING PYREF AS ARGUMENT PASSES ACTUAL OBJECT *)
	Pyml.call modul "print_tuple" [tuple] ;

	(* ASSERTING THAT GENERIC FUNCTIONS ACCEPTS ALL KINDS OF ARGUMENTS *)
	Pyml.call modul "print_arg" [Pyml.Pystr "salut"] ;
	Pyml.call modul "print_arg" [Pyml.Pyint 42] ;
	Pyml.call modul "print_arg" [Pyml.Pyfloat 42.42] ;
	Pyml.call modul "print_arg" [Pyml.Pybool true] ;
	Pyml.call modul "print_arg" [Pyml.Pybytes "some bytes"] ;
	Pyml.call modul "print_arg" [Pyml.get modul "ret_unicode" []] ;
	Pyml.call modul "print_arg" [Pyml.get modul "rand_str" []] ;
	(* equivalent of modul.print_arg(modul.first_of_tuple(tuple)) : *)
	Pyml.call modul "print_arg" [Pyml.get modul "first_of_tuple" [tuple]] ;

	Pyml.close py ;

	(* python_log should now be :
		(1, 2)
		salut
		42
		42.42
		True
		b'some bytes'
		saluté
		alright, inside python
		salut les gars
		1
	*)

	let lines = file_lines "python_log" in
	let expected_lines = [
		"(1, 2)" ;
		"salut" ;
		"42" ;
		"42.42" ;
		"True" ;
		"b'some bytes'" ;
		"saluté" ;
		"alright, inside python" ;
		"salut les gars" ;
		"1"
	] in
	check_lines lines expected_lines