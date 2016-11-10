

What

`lymp` is a library allowing you to use Python functions and objects from OCaml. It gives access to the extremely rich ecosystem of libraries in Python. You might want to use `selenium`, `scipy`, `lxml`, `requests`, `pandas` or `matplotlib`.

You can also very easily write OCaml wrappers for Python libraries or your own modules.

Implementation

`lymp` currently uses named pipes to make OCaml and Python processes communicate. BSON is used to serialize data passed.
Performance is very good for almost all use cases. On my setup the overhead associated with a function call is roughly 60 μs. You can launch the benchmark to see what the overhead is on yours.
Performance could be improved by using other IPC methods, such as shared memory.

lymp ?

`pyml` was already taken, and so were `ocpy` and `pyoc`, so I figured I would just mix letters.

TODO

If it matters to you, better support for Python exceptions could be implemented (currently, a Pyexception is raised). Also, better performance would be pretty easy to get. We could also add the option to log Python's stdout to OCaml's stdout (there would be some drawbacks but it might be worth it). If you have any suggestions, you are welcome to contact me or to make a pull request.