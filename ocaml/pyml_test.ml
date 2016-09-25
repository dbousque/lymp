

let () =
	let py = Pyml.init "." in
	let fetch = py#get_module "fetch" in
	let page_content = fetch#call "get_url" [Pyml.Pystr "http://github.com/MassD/bson"] in
	match page_content with
	| Pyml.Pystr str -> print_endline str