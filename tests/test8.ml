

let ocamlfind_ok = (try (Sys.getenv "OCAMLFIND_OK" ; true) with | _ -> false)
let py = if ocamlfind_ok then Lymp.init "." else Lymp.init ~exec:"python3" ~ocamlfind:false ~lymppy_dirpath:"srcs" "."
let builtin = Lymp.builtins py

let make_stuff () =
	let file = Lymp.get_ref builtin "open" [Lymp.Pystr "test8.ml"] in
	()

let () =
	print_endline "should show \"ok\" : " ;
	make_stuff () ;
	Lymp.close py ;
	Gc.full_major () ;
	print_endline "ok"