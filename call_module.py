

import sys

name = "app.my_module"
func = "my_func"

__import__(name)
mod = sys.modules[name]
print("LAAA")
print(mod.a)
print(getattr(mod, func)("salut", 12))