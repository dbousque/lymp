

exception Unknown_return_type of string
exception Wrong_Pytype
exception Expected_reference_not_module
exception Could_not_create_pipe
exception Pyexception

type pycommunication

(* pycallable can be a module or a reference *)
type pycallable

type pyobj =
	Pystr of string
	| Pyint of int
	| Pyfloat of float
	| Pybool of bool
	| Pybytes of bytes
	| Pyref of pycallable
	| Pylist of pyobj list
	| Pynone

val get_module : pycommunication -> string -> pycallable

val call : pycallable -> string -> pyobj list -> unit
val get : pycallable -> string -> pyobj list -> pyobj
val get_string : pycallable -> string -> pyobj list -> string
val get_int : pycallable -> string -> pyobj list -> int
val get_float : pycallable -> string -> pyobj list -> float
val get_bool : pycallable -> string -> pyobj list -> bool
val get_bytes : pycallable -> string -> pyobj list -> bytes
val get_ref : pycallable -> string -> pyobj list -> pycallable
val get_list : pycallable -> string -> pyobj list -> pyobj list

(* get what is being referenced,
   will return a Pyref if the python type is not supported *)
val dereference : pycallable -> pyobj

val close : pycommunication -> unit
val init : ?exec:string -> ?ocamlfind:bool -> ?pymlpy_dirpath:string -> string -> pycommunication