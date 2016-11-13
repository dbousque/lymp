

 -- What

`lymp` is a library allowing you to use Python functions and objects from OCaml. It gives access to the rich ecosystem of libraries in Python. You might want to use `selenium`, `scipy`, `lxml`, `requests`, `pandas` or `matplotlib`.

You can also very easily write OCaml wrappers for Python libraries or your own modules.

Python 2 and 3 compatible.


 -- Simple example

```
$ ls
simple.ml
simple.py
```

(display simple.ml and simple.py side by side)

```
$ ./simple.native
hi there
42
22
first second
```


 -- More advanced example

This example shows how you can use `selenium` and `lxml` to download a webpage (with Javascript content thanks to PhantomJS), and then parse it and manipulate the DOM.
(display phantom.ml and phantom.py side by side)

`pyobj`

```ocaml
type pyobj =
    Pystr of string
    | Pyint of int
    | Pyfloat of float
    | Pybool of bool
    | Pybytes of bytes
    | Pyref of pycallable
    | Pylist of pyobj list
    | Pynone
```
Main type representing python values, which are passed as arguments of functions and returned from functions. `Pyref` allows us to use python objects, we explain them later on.


 -- API

`init` spawns a Python process and gets it ready. A `pycommunication` is returned, which you can then use to make modules. `get_module` can be thought of as an `import` statement in Python.
You can then call the functions or get the attributes of the module, using the get* and attr* functions.

```ocaml
val init : ?exec:string -> ?ocamlfind:bool -> ?lymppy_dirpath:string -> string -> pycommunication
```
- 1. `exec` : name of the python interpreter, or path to it. Default is `python3` (python 2 and 3 are both supported)
- 2. `ocamlfind` : `lymp` uses a python script, `lymp.py`, which is in `ocamlfind query lymp` if you installed through opam or the Makefile. If you didn't install that way, set `ocamlfind` to `false`. Default is `true`
- 3. `lymppy_dirpath` : if `ocamlfind` is set to `false`, `lymp.py` will be assumed to be in `lymppy_dirpath`. Default is `"."`
- 4. : path from which python will be launched, which influences what modules are accessible. Example value : `"../py_utils"`

```ocaml
val get_module : pycommunication -> string -> pycallable
```
- 1. a value returned by `init`
- 2. name of the module you whish to use (can be something like `"app.crypto.utils"`)

```ocaml
val get : pycallable -> string -> pyobj list -> pyobj
```
- 1. a module or a reference, from which you wish to call a function
- 2. name of the function
- 3. arguments of the function
Example : `get time "sleep" [Pyint 2]` (`time.sleep(2)`)
Sister functions : `get_string`, `get_int`, `get_float`, `get_bool`, `get_bytes` and `get_list`. They call `get` and try to do pattern matching over the result to return the desired type, they fail with a `Wrong_Pytype` if the result was not from the expected type.

```ocaml
val attr : pycallable -> string -> pyobj
```
- 1. a module or a reference, from which you wish to get an attribute
- 2. name of the attribute
Example : `attr sys "argv"` (`sys.argv`)
Sister functions : `attr_string`, `attr_int`, `attr_float`, `attr_bool`, `attr_bytes` and `attr_list`. They call `attr` and try to do pattern matching over the result to return the desired type, they fail with a `Wrong_Pytype` if the result was not from the expected type.

```ocaml
val close : pycommunication -> unit
```
- 1. a value returned by `init`
Exit properly, it's important to call it.


 -- Reference
To be able to use python objects of non supported-types (anything outside of int, str etc.), we have references. A `Pyreference` is of type `pycallable`, which allows us to call `get` and `attr` on it. When passed as arguments or returned from functions, they are passed as `Pyref`, of type `pyobj`. References passed as arguments are resolved on the python side, which means that if you call a function with a reference as argument, on the python side the actual object will be passed.
Another use case for references (other than unsupported types) is for very big strings, bytes or lists, which you may not whish to send back and forth between OCaml and Python if you need to further process them in python. Passing is relatively cheap, but you may want to avoid it.
```ocaml
val get_ref : pycallable -> string -> pyobj list -> pycallable
```
Calls `get` and forces the result to be a reference, so the actual data is not sent back to OCaml, but remains on the Python side. To be used for unsupported types and big strings, bytes and lists if you need to further process them in python. What we call "big string" is a string of more than 10000 characters.

```ocaml
val attr_ref : pycallable -> string -> pycallable
```

 -- Implementation

`lymp` currently uses named pipes to make OCaml and Python processes communicate. BSON is used to serialize data passed.
Performance is very good for almost all use cases. On my setup the overhead associated with a function call is roughly 60 μs. You can launch the benchmark to see what the overhead is on yours.
Performance could be improved by using other IPC methods, such as shared memory.

`lymp` ?

"pyml" was already taken, and so were "ocpy" and "pyoc", so I figured I would just mix letters.


 -- TODO

If it matters to you, better support for Python exceptions could be implemented (currently, a Pyexception is raised). Also, better performance would be pretty easy to get. Support for dicts and named arguments could be added. We could also add the option to log Python's stdout to OCaml's stdout (there would be some drawbacks but it might be worth it). You are welcome to make pull requests and suggestions.
