

let () =
	let py = Pyml.init "." in
	let fetch = py#get_module "fetch" in
	let page_content = fetch#call "get_url" [Pystr "http://github.com/MassD/bson"] in
	match page_content with
	| Pystr str -> print_endline str