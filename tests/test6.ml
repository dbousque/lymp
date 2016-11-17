

let ocamlfind_ok = (try (Sys.getenv "OCAMLFIND_OK" ; true) with | _ -> false)
let py = if ocamlfind_ok then Lymp.init "." else Lymp.init ~exec:"python3" ~ocamlfind:false ~lymppy_dirpath:"srcs" "."
let builtin = Lymp.builtins py

let () =
	let file1 = Lymp.get_ref builtin "open" [Lymp.Pystr "test5.ml" ; Lymp.Namedarg ("encoding", Lymp.Pystr "utf-8")] in
	let encoding = Lymp.attr_string file1 "encoding" in
	if encoding = "utf-8" then () else raise (Failure "failed") ;
	let file2 = Lymp.get_ref builtin "open" [Lymp.Pystr "test5.ml" ; Lymp.Namedarg ("encoding", Lymp.Pystr "ascii")] in
	let encoding = Lymp.attr_string file2 "encoding" in
	if encoding = "ascii" then () else raise (Failure "failed") ;

	Lymp.close py