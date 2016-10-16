

all:
	ocamlbuild -use-ocamlfind -pkgs bson -libs unix pyml.native

install: all