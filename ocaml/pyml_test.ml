

let speed_test modul =
	let nb = ref 0 in
	let start = Unix.gettimeofday () in
	while Unix.gettimeofday () -. start < 1.0 do
		modul#get_int "random_int" [] ;
		incr nb
	done ;
	print_string "DONE : " ;
	print_int (!nb) ;
	print_endline " TIMES"

let () =
	let py = Pyml.init "." in
	let fetch = py#get_module "fetch" in
	let page_content = fetch#call "get_url" [Pyml.Pystr "http://github.com/MassD/bson"] in
	match page_content with
	| Pyml.Pystr str -> print_endline str ;
	let page_content2 = fetch#call "get_url" [Pyml.Pystr "http://github.com/MassD/bson"] in
	match page_content with
	| Pyml.Pystr str -> print_endline str ;

	let content = fetch#get_string "phantom_fetch" [Pyml.Pystr "https://google.fr"] in
	print_endline content ;

	let rand = fetch#get_int "random_int" [] in
	print_int rand ;
	print_endline "" ;

	speed_test fetch ;

	py#close