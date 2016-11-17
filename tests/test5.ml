

let ocamlfind_ok = (try (Sys.getenv "OCAMLFIND_OK" ; true) with | _ -> false)
let py = if ocamlfind_ok then Lymp.init "." else Lymp.init ~exec:"python3" ~ocamlfind:false ~lymppy_dirpath:"srcs" "."
let sys = Lymp.get_module py "sys"

let () =
	Lymp.set_attr sys "stdin" (Lymp.Pyint 42) ;
	let py_stdin = Lymp.attr_int sys "stdin" in
	if py_stdin = 42 then () else raise (Failure "failed") ;

	Lymp.close py