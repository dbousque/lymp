

(* downloads a webpage using phantomjs, saves a screenshot of it to screen.png,
   selects links out of page, and prints the links' titles *)

open Lymp

let py = init ~ocamlfind:false ~lymppy_dirpath:"srcs" "."
let phantom = get_module py "phantom"

let download_with_phantom url =
	get_string phantom "download" [Pystr url]

let select html css_selector =
	get_list phantom "select" [Pystr html ; Pystr css_selector]

let get_lxml_text (Pyref lxml_elt) =
	(* calling method text_content() of lxml element *)
	let text = get lxml_elt "text_content" [] in
	(* text is a custom lxml type, we convert it to str *)
	get_string (builtins py) "str" [text]

let () =
	let url = "https://github.com/dbousque/lymp" in
	let page_content = download_with_phantom url in
	let links = select page_content "a" in
	let titles = List.map get_lxml_text links in
	List.iter print_endline titles ;

	close py