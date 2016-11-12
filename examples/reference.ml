

(* example usage of an object through a reference (here a dict object) *)

open Lymp

let py = init "."
let builtin = builtins py

let () =
	(* create a dict *)
	let dict = get_ref builtin "dict" [] in
	(* dict["field1"] = "value1" *)
	call dict "__setitem__" [Pystr "field1" ; Pystr "value1"] ;
	call dict "__setitem__" [Pystr "field2" ; Pyint 2] ;
	call dict "__setitem__" [Pystr "field3" ; Pyfloat 3.3] ;
	(* getting fields, for example 'val1' is the string "value1" *)
	let val1 = get_string dict "get" [Pystr "field1"] in
	let val2 = get_int dict "get" [Pystr "field2"] in
	let val3 = get_float dict "get" [Pystr "field3"] in
	(* 'values' will be : [Pystr "value1" ; Pyint 2 ; Pyfloat 3.3] *)
	let values_ref = get dict "values" [] in
	(* my_dict.values() returns a 'dict_values' and not a 'list' in python 3,
	   so we make a conversion with list(values_ref) *)
	let values = get_list builtin "list" [values_ref] in

	print_endline val1 ;
	print_endline (string_of_int val2) ;
	print_endline (string_of_float val3) ;

	print_endline (string_of_int (List.length values)) ;

	(* ouput will be :
		value1
		2
		3.3
		3
	 *)

	close py