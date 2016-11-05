

let () =
	let py = Pyml.init "." in
	print_endline "init done" ;
	let fetch = Pyml.get_module py "fetch" in
	print_endline "got module" ;
	let str = Pyml.get_string fetch "rand_str" [] in
	print_endline str ;
	Pyml.close py
