

let ocamlfind_ok = (try (Sys.getenv "OCAMLFIND_OK" ; true) with | _ -> false)
let py = if ocamlfind_ok then Lymp.init "." else Lymp.init ~exec:"python3" ~ocamlfind:false ~lymppy_dirpath:"srcs" "."
let fetch = Lymp.get_module py "fetch"
let builtin = Lymp.builtins py

let () =
	let fetch_obj = Lymp.get_ref fetch "Fetch" [Lymp.Pystr "https://google.com" ; Lymp.Pystr "std"] in
	Lymp.call builtin "print" [Lymp.Pyref fetch_obj] ;
	let content = Lymp.get_string fetch_obj "download" [] in
	if content <> "<html><p>Hi</p></html>" then raise (Failure "failed") ;
	let obj_ref_again = Lymp.get_ref fetch_obj "ret_self" [] in
	let url = Lymp.attr_string fetch_obj "url" in
	if url <> "https://google.com" then raise (Failure "failed") ;
	let mode = Lymp.attr_string obj_ref_again "mode" in
	if mode <> "std" then raise (Failure "failed") ;

	let int_ref = Lymp.get_ref builtin "int" [Lymp.Pystr "42"] in
	let int_val = Lymp.dereference int_ref in
	(match int_val with
	| Lymp.Pyint v -> if v <> 42 then raise (Failure "failed")
	| _ -> raise (Failure "failed") );

	let lst = Lymp.get_list fetch_obj "ret_list" [] in
	( match lst with
	| [Lymp.Pyint i1 ; Lymp.Pyint i2 ; Lymp.Pyref obj ; Lymp.Pylist [Lymp.Pystr str ; Lymp.Pyint i3] ; Lymp.Pyint i4] -> if i1 <> 1 || i2 <> 2 || i3 <> 3 || i4 <> 4 || str <> "salut" then raise (Failure "failed")
	| _ -> raise (Failure "failed") ) ;

	Lymp.close py