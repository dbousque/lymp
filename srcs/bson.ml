exception Invalid_objectId;;
exception Wrong_bson_type;;
exception Wrong_string;;
exception Malformed_bson;;

type document = (string * element) list
and t = document
and special =
  | NULL
  | MINKEY
  | MAXKEY
and element =
  | Double of float
  | String of string
  | Document of document
  | Array of element list
  | Binary of binary
  | ObjectId of string (* only 12 bytes *)
  | Boolean of bool
  | UTC of int64
  | Null of special
  | Regex of (string * string)
  | JSCode of string
  | JSCodeWS of (string * document)
  | Int32 of int32
  | Int64 of int64
  | Timestamp of int64
  | MinKey of special
  | MaxKey of special
and binary =
  | Generic of string
  | Function of string
  | UUID of string
  | MD5 of string
  | UserDefined of string;;


let empty = [];;

let is_empty = function
  | [] -> true
  | _ -> false;;

let has_element = List.mem_assoc

(*
  The remove  operations.
*)
let remove_element = List.remove_assoc

(*
  for constructing a document
  1. we make a empty document
  2. we create element as we want
  3. we add the element to the document, with a element name
*)
let add_element ename element doc =
  (* Emulating StringMap add operation *)
  let doc =
    if has_element ename doc then remove_element ename doc
    else doc
  in
  (ename,element)::doc;;

(*
  for using a document
  1. we get an element from document, if existing
  2. we get the value of the element
*)
let get_element = List.assoc



let create_double v = Double v;;
let create_string v = String v;;
let create_doc_element v = Document v;;
let create_list l = Array l;;
let create_doc_element_list l = create_list (List.map create_doc_element l);;
let create_generic_binary v = Binary (Generic v);;
let create_function_binary v = Binary (Function v);;
let create_uuid_binary v = Binary (UUID v);;
let create_md5_binary v = Binary (MD5 v);;
let create_user_binary v = Binary (UserDefined v);;
let is_valid_objectId objectId = if String.length objectId = 12 || String.length objectId = 24 then true else false;;
let hex_to_string s =
  let n = String.length s in
  let buf = Buffer.create 12 in
  let rec convert i =
    if i > n-1 then Buffer.contents buf
    else begin
      Buffer.add_char buf (char_of_int (int_of_string ("0x" ^ (String.sub s i 2))));
      convert (i+2)
    end
  in
  convert 0
let create_objectId v =
  if String.length v = 12 then ObjectId v
  else if String.length v = 24 then
    try (ObjectId (hex_to_string v)) with (Failure "int_of_string") -> raise Invalid_objectId
  else raise Invalid_objectId;;
let create_boolean v = Boolean v;;
let create_utc v = UTC v;;
let create_null () = Null NULL;;
let create_regex s1 s2 = Regex (s1, s2);;
let create_jscode v = JSCode v;;
let create_jscode_w_s s doc = JSCodeWS (s, doc);;
let create_int32 v = Int32 v;;
let create_int64 v = Int64 v;;
let create_timestamp v = Timestamp v;;
let create_minkey () = MinKey MINKEY;;
let create_maxkey () = MaxKey MAXKEY;;

let get_double = function | Double v -> v | _ -> raise Wrong_bson_type;;
let get_string = function | String v -> v | _ -> raise Wrong_bson_type;;
let get_doc_element = function | Document v -> v | _ -> raise Wrong_bson_type;;
let get_list = function | Array v -> v | _ -> raise Wrong_bson_type;;
let get_generic_binary = function | Binary (Generic v) -> v | _ -> raise Wrong_bson_type;;
let get_function_binary = function | Binary (Function v) -> v | _ -> raise Wrong_bson_type;;
let get_uuid_binary = function | Binary (UUID v) -> v | _ -> raise Wrong_bson_type;;
let get_md5_binary = function | Binary (MD5 v) -> v | _ -> raise Wrong_bson_type;;
let get_user_binary = function | Binary (UserDefined v) -> v | _ -> raise Wrong_bson_type;;
let get_objectId = function | ObjectId v -> v | _ -> raise Wrong_bson_type;;
let get_boolean = function | Boolean v -> v | _ -> raise Wrong_bson_type;;
let get_utc = function | UTC v -> v | _ -> raise Wrong_bson_type;;
let get_null = function | Null NULL -> NULL | _ -> raise Wrong_bson_type;;
let get_regex = function | Regex v -> v | _ -> raise Wrong_bson_type;;
let get_jscode = function | JSCode v -> v | _ -> raise Wrong_bson_type;;
let get_jscode_w_s = function | JSCodeWS v -> v | _ -> raise Wrong_bson_type;;
let get_int32 = function | Int32 v -> v | _ -> raise Wrong_bson_type;;
let get_int64 = function | Int64 v -> v | _ -> raise Wrong_bson_type;;
let get_timestamp = function | Timestamp v -> v | _ -> raise Wrong_bson_type;;
let get_minkey = function | MinKey MINKEY -> MINKEY | _ -> raise Wrong_bson_type;;
let get_maxkey = function | MaxKey MAXKEY -> MAXKEY | _ -> raise Wrong_bson_type;;

let all_elements d = d

  (*
    encode int64, int32 and float.
    note that encoding float is the same as int64, just need to transfer all the bits into an int64.

    The logic is that (e.g., for int32):
    1) we get an int32
    2) we shift right 1 byte one by one
    3) After each shift, we logic and 0000 0000 ... 0000 1111 1111 (255l) with the shifted int32 to get the lower 1 byte
    4) we convert the int32 to int, so Char.chr can pick it up and convert it to char (byte)
    5) we put the byte to the buffer (starting from index of 0, since it is little-endian format)
  *)

let encode_int64 buf v =
  for i = 0 to 7 do
    let b = Int64.logand 255L (Int64.shift_right v (i*8)) in
    Buffer.add_char buf (Char.chr (Int64.to_int b))
  done;;

let encode_float buf v = encode_int64 buf (Int64.bits_of_float v);;

let encode_int32 buf v =
  for i = 0 to 3 do
    let b = Int32.logand 255l (Int32.shift_right v (i*8)) in
    Buffer.add_char buf (Char.chr (Int32.to_int b))
  done;;

let encode_ename buf c ename =
  Buffer.add_char buf c;
  Buffer.add_string buf ename;
  Buffer.add_char buf '\x00';;

let encode_string buf s =
  let len = String.length s in
  if len > 0 && s.[len-1] = '\x00' then raise Wrong_string
  else begin
    encode_int32 buf (Int32.of_int (len+1));
    Buffer.add_string buf s;
    Buffer.add_char buf '\x00'
  end;;

let encode_objectId buf s =
  if String.length s <> 12 then raise Invalid_objectId
  else Buffer.add_string buf s;;

let encode_binary buf c b =
  encode_int32 buf (Int32.of_int (String.length b));
  Buffer.add_char buf c;
  Buffer.add_string buf b;;

let encode_cstring buf cs =
  Buffer.add_string buf cs;
  Buffer.add_char buf '\x00';;

let list_to_doc l = (* we need to transform the list to a doc with key as incrementing from '0' *)
  let rec to_doc i acc = function
    | [] -> acc
    | hd::tl -> to_doc (i+1) (add_element (string_of_int i) hd acc) tl
  in
  to_doc 0 empty l;;


let encode doc =
  let all_buf = Buffer.create 64 in
  let rec encode_element buf ename element =
    match element with
      | Double v ->
	encode_ename buf '\x01' ename;
	encode_float buf v
      | String v ->
	encode_ename buf '\x02' ename;
	encode_string buf v
      | Document v ->
	encode_ename buf '\x03' ename;
	encode_doc buf v
      | Array v ->
	encode_ename buf '\x04' ename;
	encode_doc buf (list_to_doc v)
      | Binary v ->
	encode_ename buf '\x05' ename;
	begin match v with
	  | Generic v -> encode_binary buf '\x00' v
	  | Function v -> encode_binary buf '\x01' v
	  | UUID v -> encode_binary buf '\x04' v
	  | MD5 v -> encode_binary buf '\x05' v
	  | UserDefined v -> encode_binary buf '\x80' v
	end
      | ObjectId v ->
	encode_ename buf '\x07' ename;
	encode_objectId buf v
      | Boolean v ->
	encode_ename buf '\x08' ename;
	Buffer.add_char buf (if v then '\x01' else '\x00')
      | UTC v ->
	encode_ename buf '\x09' ename;
	encode_int64 buf v
      | Null NULL->
	encode_ename buf '\x0A' ename;
      | Regex (v1,v2) ->
	encode_ename buf '\x0B' ename;
	encode_cstring buf v1;
	encode_cstring buf v2
      | JSCode v ->
	encode_ename buf '\x0D' ename;
	encode_string buf v
      | JSCodeWS (v, d) ->
	encode_ename buf '\x0F' ename;
	let tmp_str_buf = Buffer.create 16 and tmp_doc_buf = Buffer.create 16 in
	encode_string tmp_str_buf v;
	encode_doc tmp_doc_buf d;
	encode_int32 buf (Int32.of_int (4 + (Buffer.length tmp_str_buf) + (Buffer.length tmp_doc_buf)));
	Buffer.add_buffer buf tmp_str_buf;
	Buffer.add_buffer buf tmp_doc_buf
      | Int32 v ->
	encode_ename buf '\x10' ename;
	encode_int32 buf v
      | Timestamp v ->
	encode_ename buf '\x11' ename;
	encode_int64 buf v
      | Int64 v ->
	encode_ename buf '\x12' ename;
	encode_int64 buf v
      | MinKey MINKEY ->
	encode_ename buf '\xFF' ename
      | MaxKey MAXKEY ->
	encode_ename buf '\x7F' ename
      | _ -> raise Malformed_bson
  and
      encode_doc buf doc =
    let process_element buf (ename, element) = encode_element buf ename element; buf in
    let e_buf = List.fold_left process_element (Buffer.create 64) doc in
    encode_int32 buf (Int32.of_int (5+(Buffer.length e_buf)));
    Buffer.add_buffer buf e_buf;
    Buffer.add_char buf '\x00';
  in
  encode_doc all_buf doc;
  Buffer.contents all_buf;;


let decode_int64 str cur =
  let rec decode i acc =
    if i < cur then acc
    else
      let high_byte = Char.code str.[i] in
      let high_int64 = Int64.of_int high_byte in
      let shift_acc = Int64.shift_left acc 8 in
      let new_acc = Int64.logor high_int64 shift_acc in
      decode (i-1) new_acc
  in (decode (cur+7) 0L, cur+8)

let decode_float str cur =
  let (i, new_cur) = decode_int64 str cur in
  (Int64.float_of_bits i, new_cur);;

let decode_int32 str cur =
  let rec decode i acc =
    if i < cur then acc
    else
      let high_byte = Char.code str.[i] in
	(*print_int high_byte;print_endline "";*)
      let high_int32 = Int32.of_int high_byte in
      let shift_acc = Int32.shift_left acc 8 in
      let new_acc = Int32.logor high_int32 shift_acc in
      decode (i-1) new_acc
  in (decode (cur+3) 0l, cur+4);;

let rec next_x00 str cur = String.index_from str cur '\x00';;

let decode_ename str cur =
  let x00 = next_x00 str cur in
  if x00 = -1 then raise Malformed_bson
  else (String.sub str cur (x00-cur), x00+1);;

let decode_cstring = decode_ename;;

let decode_len str cur =
  let (len32, next_cur) = decode_int32 str cur in
  (Int32.to_int len32, next_cur)

let decode_double str cur =
  let (f, new_cur) = decode_float str cur in
  (Double f, new_cur);;

let decode_string str cur =
  let (len, next_cur) = decode_len str cur in
    (*print_string "cur=";print_int cur;print_string ";";
      print_string "len=";print_int len;
      print_endline "";*)
  (*let x00 = next_x00 str next_cur in
  Printf.printf "len=%d, next_cur=%d, x00=%d, s[x00]=%c\n" len next_cur x00 str.[x00-1];
  print_endline (String.sub str next_cur (len-1));*)
  (*if len - 1 <> x00-next_cur then raise Wrong_string
  else (String.sub str next_cur (len-1), x00+1);;*)
  (String.sub str next_cur (len-1), next_cur+len);;

let doc_to_list doc = (* we need to transform a doc with key as incrementing from '0' to a list *)
  List.map (
    fun (k,v) -> v
  ) doc


let decode_binary str cur =
  let (len, next_cur) = decode_len str cur in
  let c = str.[next_cur] in
  let b = String.sub str (next_cur+1) len in
  let new_cur = next_cur+1+len in
  match c with
    | '\x00' -> (Binary (Generic b), new_cur)
    | '\x01' -> (Binary (Function b), new_cur)
    | '\x04' -> (Binary (UUID b), new_cur)
    | '\x05' -> (Binary (MD5 b), new_cur)
    | '\x80' -> (Binary (UserDefined b), new_cur)
    | _ -> raise Malformed_bson;;

let decode_objectId str cur = (ObjectId (String.sub str cur 12), cur+12);;

let decode_boolean str cur = (Boolean (if str.[cur] = '\x00' then false else true), cur+1);;

let decode_utc str cur =
  let (i, new_cur) = decode_int64 str cur in
  (UTC i, new_cur);;

let decode_regex str cur =
  let (s1, x00) = decode_cstring str cur in
  let (s2, new_cur) = decode_cstring str (x00+1) in
  (Regex (s1, s2), new_cur);;

let decode_jscode str cur =
  let (s, next_cur) = decode_string str cur in
  (JSCode s, next_cur);;

let decode str =
  let rec decode_element str cur =
    let c = str.[cur] in
    let next_cur = cur+1 in
    let (ename, next_cur) = decode_ename str next_cur in
      (*print_endline ename;*)
    let (element, next_cur) =
      match c with
	| '\x01' -> decode_double str next_cur
	| '\x02' ->
	    (*print_endline "decoding string...";*)
	  let (s, next_cur) = decode_string str next_cur in
	  (String s, next_cur)
	| '\x03' ->
	  let (doc, next_cur) = decode_doc str next_cur in
	  (Document doc, next_cur)
	| '\x04' ->
	  let (doc, next_cur) =  decode_doc str next_cur in
	  (Array (doc_to_list doc), next_cur)
	| '\x05' -> decode_binary str next_cur
	| '\x07' -> decode_objectId str next_cur
	| '\x08' -> decode_boolean str next_cur
	| '\x09' -> decode_utc str next_cur
	| '\x0A' -> (Null NULL, next_cur)
	| '\x0B' -> decode_regex str next_cur
	| '\x0D' -> decode_jscode str next_cur
	| '\x0F' -> (* decode jscode_w_s *)
	  let (len, next_cur) = decode_len str next_cur in
	  let (s, next_cur) = decode_string str next_cur in
	  let (doc, next_cur) = decode_doc str next_cur in
	  (JSCodeWS (s, doc), next_cur)
	| '\x10' ->
	  let (i, next_cur) = decode_int32 str next_cur in
	  (Int32 i, next_cur)
	| '\x11' ->
	  let (i, next_cur) = decode_int64 str next_cur in
	  (Timestamp i, next_cur)
	| '\x12' ->
	  let (i, next_cur) = decode_int64 str next_cur in
	  (Int64 i, next_cur)
	| '\xFF' -> (MinKey MINKEY, next_cur)
	| '\x7F' -> (MaxKey MAXKEY, next_cur)
	| _ -> raise Malformed_bson
    in
    (ename, element, next_cur)
  and decode_doc str cur =
    let acc = empty in
    let (len, next_cur) = decode_len str cur in
    let rec decode_elements cur acc =
      if str.[cur] = '\x00' then (acc, cur+1)
      else
	let (ename, element, next_cur) = decode_element str cur in
	decode_elements next_cur (add_element ename element acc)
    in
    let (doc, des) = decode_elements next_cur acc in
    if des - cur <> len then raise Malformed_bson
    else (doc, des)
  in let (doc, _) = decode_doc str 0 in doc;;

  (*
    Not that this bson to json conversion is far from completion.
    It is used to help the test verification and can handle only simple objects.
  *)
let to_simple_json doc =
  let rec el_to_sl el =
    List.rev (List.fold_left (fun acc e -> (e_to_s e)::acc) [] el)
  and e_to_s = function
    | Double v -> string_of_float v
    | String v -> "\"" ^ v ^ "\""
    | Document v -> d_to_s v
    | Array v -> let sl = el_to_sl v in "[" ^ (String.concat ", " sl) ^ "]"
    | Binary v ->
      begin match v with
	| Generic v | Function v | UUID v | MD5 v | UserDefined v -> "\"" ^ v ^ "\""
      end
    | ObjectId v -> "\"" ^ v ^ "\""
    | Boolean v -> if v then "\"true\"" else "\"false\""
    | UTC v -> Int64.to_string v
    | Null NULL-> "\"null\""
    | Regex (v1,v2) -> "(\"" ^ v1 ^ ", \"" ^ v2 ^ "\")"
    | JSCode v -> "\"" ^ v ^ "\""
    | JSCodeWS (v, d) -> "(\"" ^ v ^ ", \"" ^ (d_to_s d) ^ "\")"
    | Int32 v -> Int32.to_string v
    | Timestamp v -> Int64.to_string v
    | Int64 v -> Int64.to_string v
    | MinKey MINKEY -> "\"minkey\""
    | MaxKey MAXKEY -> "\"maxkey\""
    | _ -> raise Malformed_bson
  and d_to_s d =
    let buf = Buffer.create 16 in
    Buffer.add_string buf "{";
    (* let bindings = all_elements d in *)
    let process acc (ename, element) =
      ("\"" ^ ename ^ "\" : " ^ (e_to_s element)) :: acc;
    in
    Buffer.add_string buf (String.concat ", " (List.rev (List.fold_left process [] d)));
    Buffer.add_string buf "}";
    Buffer.contents buf
  in
  d_to_s doc;;
