

let ocamlfind_ok = (try (Sys.getenv "OCAMLFIND_OK" ; true) with | _ -> false)
let py = if ocamlfind_ok then Pyml.init "." else Pyml.init ~exec:"python3" ~ocamlfind:false ~pymlpy_dirpath:"srcs" "."
let fetch = Pyml.get_module py "fetch"