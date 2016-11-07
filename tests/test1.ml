

(* TESTING BASIC FUNCTION CALL *)

let ocamlfind_ok = (try (Sys.getenv "OCAMLFIND_OK" ; true) with | _ -> false)
let py = if ocamlfind_ok then Pyml.init "." else Pyml.init ~ocamlfind:false ~pymlpy_dirpath:"srcs" "."
let modul = Pyml.get_module py "modul"

let rand_str () =
	Pyml.get_string modul "rand_str" []

let () =
	let str = Pyml.get_string modul "rand_str" [] in
	if str <> "salut les gars" then raise (Failure "failed") ;
	print_endline str ;

	let str = rand_str () in
	if str <> "salut les gars" then raise (Failure "failed") ;
	print_endline str ;

	Pyml.close py