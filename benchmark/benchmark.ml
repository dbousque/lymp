

let ocamlfind_ok = (try (Sys.getenv "OCAMLFIND_OK" ; true) with | _ -> false)
let py = if ocamlfind_ok then Lymp.init "." else Lymp.init ~exec:"python3" ~ocamlfind:false ~lymppy_dirpath:"srcs" "."
let modul = Lymp.get_module py "modul"

let speed_test () =
	let nb = ref 0 in
	let start = Unix.gettimeofday () in
	while Unix.gettimeofday () -. start < 1.0 do
		ignore (Lymp.get_int modul "get_int" []) ;
		ignore (Lymp.get_int modul "get_int" []) ;
		ignore (Lymp.get_int modul "get_int" []) ;
		ignore (Lymp.get_int modul "get_int" []) ;
		ignore (Lymp.get_int modul "get_int" []) ;
		ignore (Lymp.get_int modul "get_int" []) ;
		ignore (Lymp.get_int modul "get_int" []) ;
		ignore (Lymp.get_int modul "get_int" []) ;
		ignore (Lymp.get_int modul "get_int" []) ;
		ignore (Lymp.get_int modul "get_int" []) ;
		nb := !nb + 10
	done ;
	print_endline ("Function call overhead : " ^ (string_of_int (1000000 / !nb)) ^ " μs")

let () =
	speed_test () ;
	Lymp.close py