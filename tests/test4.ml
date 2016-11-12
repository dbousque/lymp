

open Lymp

let ocamlfind_ok = (try (Sys.getenv "OCAMLFIND_OK" ; true) with | _ -> false)
let py = if ocamlfind_ok then Lymp.init "." else Lymp.init ~exec:"python3" ~ocamlfind:false ~lymppy_dirpath:"srcs" "."
let test = Lymp.get_module py "mod.test"

let () =
	if (get_string test "get_msg" [] <> "hi there") then raise (Failure "failed") ;

	close py
