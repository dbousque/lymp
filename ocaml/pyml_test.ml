

let speed_test modul =
	let nb = ref 0 in
	let start = Unix.gettimeofday () in
	while Unix.gettimeofday () -. start < 1.0 do
		ignore (Pyml.get_int modul "random_int" []) ;
		ignore (Pyml.get_int modul "random_int" []) ;
		ignore (Pyml.get_int modul "random_int" []) ;
		ignore (Pyml.get_int modul "random_int" []) ;
		ignore (Pyml.get_int modul "random_int" []) ;
		ignore (Pyml.get_int modul "random_int" []) ;
		ignore (Pyml.get_int modul "random_int" []) ;
		ignore (Pyml.get_int modul "random_int" []) ;
		ignore (Pyml.get_int modul "random_int" []) ;
		ignore (Pyml.get_int modul "random_int" []) ;
		incr nb ;
		incr nb ;
		incr nb ;
		incr nb ;
		incr nb ;
		incr nb ;
		incr nb ;
		incr nb ;
		incr nb ;
		incr nb
	done ;
	print_string "DONE : " ;
	print_int (!nb) ;
	print_endline " TIMES"

let () =
	let py = Pyml.init "." in
	let fetch = Pyml.get_module py "fetch" in
	let page_content = Pyml.get fetch "get_url" [Pyml.Pystr "http://github.com/MassD/bson"] in
	match page_content with
	| Pyml.Pystr str -> print_endline str ;
	let page_content2 = Pyml.get fetch "get_url" [Pyml.Pystr "http://github.com/MassD/bson"] in
	match page_content with
	| Pyml.Pystr str -> print_endline str ;

	let content = Pyml.get_string fetch "phantom_fetch" [Pyml.Pystr "https://google.fr"] in
	print_endline content ;

	let rand = Pyml.get_int fetch "random_int" [] in
	print_int rand ;
	print_endline "" ;

	speed_test fetch ;

	Pyml.close py