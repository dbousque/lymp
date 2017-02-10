

(* TESTING PYREF AND WRONGTYPE EXCEPTION *)

let ocamlfind_ok = (try (Sys.getenv "OCAMLFIND_OK" ; true) with | _ -> false)
let py = if ocamlfind_ok then Lymp.init "." else Lymp.init ~exec:"python3" ~ocamlfind:false ~lymppy_dirpath:"srcs" "."
let modul = Lymp.get_module py "modul"

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
	ignore (try (Lymp.get_string modul "get_tuple" [])
	with Lymp.Wrong_Pytype _ -> "") ;
	(* tuples are converted to lists *)
	let tuple = Lymp.get modul "get_tuple" [] in
	( match tuple with
	| Lymp.Pytuple l -> ()
	| _ -> raise (Failure "failed")) ;

	(* ASSERTING THAT PASSING PYREF AS ARGUMENT PASSES ACTUAL OBJECT *)
	Lymp.call modul "print_tuple" [tuple] ;

	(* ASSERTING THAT GENERIC FUNCTIONS ACCEPTS ALL KINDS OF ARGUMENTS *)
	Lymp.call modul "print_arg" [Lymp.Pystr "salut"] ;
	Lymp.call modul "print_arg" [Lymp.Pyint 42] ;
	Lymp.call modul "print_arg" [Lymp.Pyfloat 42.42] ;
	Lymp.call modul "print_arg" [Lymp.Pybool true] ;
	Lymp.call modul "print_arg" [Lymp.Pybytes "some bytes"] ;
	Lymp.call modul "print_arg" [Lymp.get modul "ret_unicode" []] ;
	Lymp.call modul "print_arg" [Lymp.get modul "rand_str" []] ;
	(* equivalent of modul.print_arg(modul.first_of_tuple(tuple)) : *)
	Lymp.call modul "print_arg" [Lymp.get modul "first_of_tuple" [tuple]] ;

	Lymp.close py ;

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