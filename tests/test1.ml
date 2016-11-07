

let py = Pyml.init ~ocamlfind:false ~pymlpy_dirpath:"srcs" "."
let fetch = Pyml.get_module py "fetch"

let rand_str () =
	Pyml.get_string fetch "rand_str" []

let () =
	let str = Pyml.get_string fetch "rand_str" [] in
	print_endline str ;
	let str = rand_str () in
	print_endline str ;

	Pyml.close py