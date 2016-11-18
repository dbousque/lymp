

let ocamlfind_ok = (try (Sys.getenv "OCAMLFIND_OK" ; true) with | _ -> false)
let py = if ocamlfind_ok then Lymp.init "." else Lymp.init ~exec:"python3" ~ocamlfind:false ~lymppy_dirpath:"srcs" "."
let builtin = Lymp.builtins py

let get_ints i =
	let string_repr1 = Lymp.get_string builtin "str" [Lymp.Pyint i] in
	let string_repr2 = Lymp.get_string builtin "str" [Lymp.Pyint (i + 100)] in
	let string_repr3 = Lymp.get_string builtin "str" [Lymp.Pyint (i + 200)] in
	Printf.printf "%s %s %s\n" string_repr1 string_repr2 string_repr3

let () =
	let threads = ref [] in
	for i = 0 to 50 do
		threads := (Thread.create get_ints i)::(!threads)
	done ;
	List.iter Thread.join !threads ;
	Lymp.close py