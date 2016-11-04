

let () =
    let py = Pyml.init "." in
    let fetch = Pyml.get_module py "fetch" in
    print_endline (Pyml.get_string fetch "rand_str" [])
