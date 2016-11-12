

open Lymp

let py = init ~ocamlfind:false ~lymppy_dirpath:"srcs" "."
let simple = get_module py "simple"

let () =
	(* msg = simple.get_message() *)
	let msg = get_string simple "get_message" [] in
	let integer = get_int simple "get_integer" [] in
	let addition = get_int simple "sum" [Pyint 12 ; Pyint 10] in
	let strconcat = get_string simple "sum" [Pystr "first " ; Pystr "second"] in
	Printf.printf "%s\n%d\n%d\n%s\n" msg integer addition strconcat ;

	close py