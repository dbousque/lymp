

(* TESTING BASIC FUNCTION CALL *)

let ocamlfind_ok = (try (Sys.getenv "OCAMLFIND_OK" ; true) with | _ -> false)
let py = if ocamlfind_ok then Lymp.init "." else Lymp.init ~ocamlfind:false ~lymppy_dirpath:"srcs" "."
let modul = Lymp.get_module py "modul"

let rand_str () =
	Lymp.get_string modul "rand_str" []

let () =
	let str = Lymp.get_string modul "rand_str" [] in
	if str <> "salut les gars" then raise (Failure "failed") ;
	print_endline str ;

	let str = rand_str () in
	if str <> "salut les gars" then raise (Failure "failed") ;
	print_endline str ;

	Lymp.close py