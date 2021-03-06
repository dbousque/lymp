

exception Unknown_return_type of string
exception Wrong_Pytype of string
exception Expected_reference_not_module
exception Could_not_create_pipe
exception Pyexception of string

(* information enabling communication with the python process *)
type pycommunication

(* pycallable can be a module or a reference *)
type pycallable

(* arguments passed to python functions must be of type pyobj *)
type pyobj =
	Pystr of string
	| Pyint of int
	| Pyfloat of float
	| Pybool of bool
	| Pybytes of bytes
	| Pyref of pycallable
	| Pytuple of pyobj list
	| Pylist of pyobj list
	| Pynone
	| Namedarg of (string * pyobj)

val get_module : pycommunication -> string -> pycallable

(* module givin access to builtins attributes and functions, such as 'print' *)
val builtins : pycommunication -> pycallable

(* call functions and methods of modules and objects *)
val call : pycallable -> string -> pyobj list -> unit
val get : pycallable -> string -> pyobj list -> pyobj
val get_string : pycallable -> string -> pyobj list -> string
val get_int : pycallable -> string -> pyobj list -> int
val get_float : pycallable -> string -> pyobj list -> float
val get_bool : pycallable -> string -> pyobj list -> bool
val get_bytes : pycallable -> string -> pyobj list -> bytes
val get_ref : pycallable -> string -> pyobj list -> pycallable
val get_tuple : pycallable -> string -> pyobj list -> pyobj list
val get_list : pycallable -> string -> pyobj list -> pyobj list

(* get attributes of modules and objects *)
val attr : pycallable -> string -> pyobj
val attr_string : pycallable -> string -> string
val attr_int : pycallable -> string -> int
val attr_float : pycallable -> string -> float
val attr_bool : pycallable -> string -> bool
val attr_bytes : pycallable -> string -> bytes
val attr_ref : pycallable -> string -> pycallable
val attr_tuple : pycallable -> string -> pyobj list
val attr_list : pycallable -> string -> pyobj list

val set_attr : pycallable -> string -> pyobj -> unit

(* get what is being referenced,
   will return a Pyref if the python type is not supported *)
val dereference : pycallable -> pyobj

val close : pycommunication -> unit
val init : ?exec:string -> ?ocamlfind:bool -> ?lymppy_dirpath:string -> string -> pycommunication
