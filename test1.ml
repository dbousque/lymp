

let test_speed in_c out_c bytes =
	let out_file = open_out "caml_out" in
	while true do
		(
		output out_c "hello\n" 0 6 ;
		flush out_c ;
		ignore (input in_c bytes 0 6));
	done

let () =
	let (in_c, out_c) = Unix.open_process "python3 test1.py" in
	let bytes = Bytes.create 10 in
	print_string "lol\n" ;
	flush stdout ;
	Unix.sleep 1 ;
	test_speed in_c out_c bytes
	(*ignore (Unix.close_process (in_c, out_c)) *)
