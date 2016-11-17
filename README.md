<h1>Lymp</h1>

`lymp` is a library allowing you to use Python functions and objects from OCaml. It gives access to the rich ecosystem of libraries in Python. You might want to use `selenium`, `scipy`, `lxml`, `requests`, `pandas` or `matplotlib`.

You can also very easily write OCaml wrappers for Python libraries or your own modules.

Python 2 and 3 compatible.

<h3>Installation</h3>

`opam install lymp` or `opam install bson && make build && make install`

Python's `pymongo` package is required (for it's bson subpackage), `opam` and the Makefile try to install it using `pip` and `pip3`, so you should not have to install it manually. If `$ python3 -c "import pymongo"` fails, you need to install `pymongo`, maybe using sudo on `pip` or `pip3`.

To make sure everything is fine, you may want to compile the simple example, like so for example : `ocamlbuild -use-ocamlfind -pkgs lymp simple.native && ./simple.native`

If you have trouble building the package, please contact me.

<h3>Simple example</h3>

```
$ ls
simple.ml
simple.py
```
<h4>simple.py</h4>
```python
def get_message():
	return "hi there"

def get_integer():
	return 42

def sum(a, b):
	return a + b
```
<h4>simple.ml</h4>
```ocaml
open Lymp

let py = init "."
let simple = get_module py "simple"

let () =
	(* msg = simple.get_message() *)
	let msg = get_string simple "get_message" [] in
	let integer = get_int simple "get_integer" [] in
	let addition = get_int simple "sum" [Pyint 12 ; Pyint 10] in
	let strconcat = get_string simple "sum" [Pystr "first " ; Pystr "second"] in
	Printf.printf "%s\n%d\n%d\n%s\n" msg integer addition strconcat ;

	close py
```

```
$ ./simple.native
hi there
42
22
first second
```


<h3>Useful example</h3>

This example shows how you can use `selenium` and `lxml` to download a webpage (with content loaded via Javascript thanks to PhantomJS), and then parse it and manipulate the DOM. You would need `lxml`, `cssselect`, `selenium`, nodeJS and phantomJS (through `npm` for example) to run this example.

<h4>phantom.py</h4>
```python
import lxml.html as lx
from selenium import webdriver

driver = webdriver.PhantomJS()
driver.set_window_size(1024, 768)

def download(url):
	driver.get(url)
	driver.save_screenshot('screen.png')
	return driver.page_source

def select(html, css_selector):
	doc = lx.fromstring(html)
	return doc.cssselect(css_selector)
```

<h4>phantom.ml</h4>
```ocaml
(* downloads a webpage using phantomjs, saves a screenshot of it to screen.png,
   selects links out of the page, and prints the links' titles *)

open Lymp

let py = init "."
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
```
You don't really need the python script to do that, you could write it completely in OCaml using `lymp`, getting and manipulating the `driver` object directly using a reference.

<h3>pyobj</h3>

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
	| Namedarg of (string * pyobj)
```

Main type representing python values, which are passed as arguments of functions and returned from functions. `Pyref` allows us to use python objects, we explain that later on.

`Namedarg` represents a named argument, which you can use like so :
```ocaml
get builtin "open" [Pystr "input.txt" ; Namedarg ("encoding", Pystr "utf-8")]
```

<h3>API</h3>

`init` spawns a Python process and gets it ready. A `pycommunication` is returned, which you can then use to make modules. `get_module` can be thought of as an `import` statement in Python.
You can then call the functions or get the attributes of the module, using the get* and attr* functions.


```ocaml
val init : ?exec:string -> ?ocamlfind:bool -> ?lymppy_dirpath:string -> string -> pycommunication
```
- 1. `exec` : name of the python interpreter, or path to it. Default is `python3` (python 2 and 3 are both supported)
- 2. `ocamlfind` : `lymp` uses a python script, `lymp.py`, which is in `ocamlfind query lymp` if you installed through opam or the Makefile. If you didn't install that way, set `ocamlfind` to `false`. Default is `true`
- 3. `lymppy_dirpath` : if `ocamlfind` is set to `false`, `lymp.py` will be assumed to be in `lymppy_dirpath`. Default is `"."`
- 4. path from which python will be launched, which influences what modules are accessible. Example value : `"../py_utils"`


```ocaml
val get_module : pycommunication -> string -> pycallable
```
- 1. a value returned by `init`
- 2. name of the module you whish to use (can be something like `"app.crypto.utils"`)


```ocaml
val builtins : pycommunication -> pycallable
```
- 1. a value returned by `init`

Returns the module giving access to built-in functions and attributes, such as `print()`, `str()`, `dir()` etc.


```ocaml
val get : pycallable -> string -> pyobj list -> pyobj
```
- 1. a module or a reference, from which you wish to call a function
- 2. name of the function
- 3. arguments of the function

Example : `get time "sleep" [Pyint 2]` (equivalent in python : `time.sleep(2)`)

Sister functions : `get_string`, `get_int`, `get_float`, `get_bool`, `get_bytes` and `get_list`. They call `get` and try to do pattern matching over the result to return the desired type, they fail with a `Wrong_Pytype` if the result was not from the expected type. For example, `get_string` doesn't return a `pyobj`, but a `string`.


```ocaml
val attr : pycallable -> string -> pyobj
```
- 1. a module or a reference, from which you wish to get an attribute
- 2. name of the attribute

Example : `attr sys "argv"` (equivalent in python : `sys.argv`)

Sister functions : `attr_string`, `attr_int`, `attr_float`, `attr_bool`, `attr_bytes` and `attr_list`. They call `attr` and try to do pattern matching over the result to return the desired type, they fail with a `Wrong_Pytype` if the result was not from the expected type.


```ocaml
val call : pycallable -> string -> pyobj list -> unit
```

Calls `get` and dismisses the value returned


```ocaml
val set_attr : pycallable -> string -> pyobj -> unit
```
- 1. a module or a reference, to which you wish to set an attribute
- 2. name of the attribute
- 3. value to set the attribute to

Example : `set_attr sys "stdout" (Pyint 42)` (equivalent in python : `sys.stdout = 42`)


```ocaml
val close : pycommunication -> unit
```
- 1. a value returned by `init`

Exit properly, it's important to call it.


<h3>References</h3>
To be able to use python objects of non supported-types (anything outside of int, str etc.), we have references.

A `Pyreference` is of type `pycallable`, which allows us to call `get` and `attr` on it. When passed as arguments or returned from functions, they are passed as `Pyref`, of type `pyobj`.

References passed as arguments are resolved on the python side, which means that if you call a function with a reference as argument, on the python side the actual object will be passed.

Another use case for references (other than unsupported types) is for very big strings, bytes or lists, which you may not whish to send back and forth between OCaml and Python if you need to further process them in python. Passing is relatively cheap, but you may want to avoid it.


```ocaml
val get_ref : pycallable -> string -> pyobj list -> pycallable
```
Calls `get` and forces the result to be a reference, so the actual data is not sent back to OCaml, but remains on the Python side. To be used for unsupported types and big strings, bytes and lists if you need to further process them in python. What we call "big string" is a whole webpage for example (but as shown in the "Useful example", it's perfectly fine to pass the string directly back and forth).


```ocaml
val attr_ref : pycallable -> string -> pycallable
```
Calls `attr` and forces the result to be a reference.


```ocaml
val dereference : pycallable -> pyobj
```
If the value's type is supported, it will be returned, otherwise a reference to it is returned.

Example usage of a reference :
```ocaml
let file = get_ref builtin "open" [Pystr "input_file.txt"] in
call builtin "print" [Pyref file] ;
let content = get_string file "read" [] in
print_endline content
```
You can find a more in-depth example in `examples/reference.ml`

<h3>Notes</h3>
- In Python 2, Pystr are converted to `unicode`, assuming that the string is utf-8 encoded, and Pybytes to `str`
- Tuples returned from Python are converted to lists.
- If there is a fatal exception, the python process continues as normal, but a Pyexception is raised on the OCaml side.
- Python's stdout is a file named `python_log`, you will find the output and uncatched exceptions' traceback there.
- Python's `int`s are converted to OCaml `int`s, overflow and underflow are therefore possible. Same goes for `float`.

<h3>Implementation</h3>

`lymp` currently uses named pipes to make OCaml and Python processes communicate. BSON is used to serialize data passed.
Performance is very good for almost all use cases. On my setup (virtual machine and relatively low specs), the overhead associated with a function call is roughly 25 μs. You can launch the benchmark to see what the overhead is on yours.
Performance could be improved by using other IPC methods, such as shared memory.

<h3>"lymp" ?</h3>
"pyml" was already taken, and so were "ocpy" and "pyoc", so I figured I would just mix letters.

<h3>TODO</h3>

If it matters to you, better support for Python exceptions could be implemented (currently, a Pyexception is raised). Also, better performance would be pretty easy to get. Support for dicts could be added. We could also add the option to log Python's stdout to OCaml's stdout (there would be some drawbacks but it might be worth it). You are welcome to make pull requests and suggestions.
