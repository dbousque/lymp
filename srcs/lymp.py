

from time import time
from struct import pack, unpack
import bson, sys, os, codecs
from random import randint
from traceback import print_exc

def int_to_int64_bytes(i):
	return pack('>q', i)

def py_to_bson(val):
	if type(val) is int:
		return bson.int64.Int64(val)
	if sys.version_info.major == 2 and type(val) is str:
		return bson.binary.Binary(val)
	return val

def exit_lymp():
	# closing 'python_log'
	sys.stdout.close()
	exit(0)

# A communication class, could be implemented using other ipc methods,
# it only needs the methods 'send_bytes' and 'get_bytes'
class PipeReaderWriter:

	def __init__(self, read_pipe_name, write_pipe_name):
		self.get_pipes(read_pipe_name, write_pipe_name)

	def get_pipes(self, read_pipe_name, write_pipe_name):
		# Order of open matters, since it is blocking, should match OCaml order
		# 0 to be unbuffered, so we don't have to flush (better performance ?)
		self.write_pipe = open(write_pipe_name, 'wb', 0)
		self.read_pipe = open(read_pipe_name, 'rb', 0)

	def send_bytes(self, byts):
		# '>q' to force signed 8 bytes integer
		self.write_pipe.write(pack('>q', len(byts)))
		#self.write_pipe.flush()
		self.write_pipe.write(byts)
		#self.write_pipe.flush()

	def get_bytes(self):
		# '>q' to force signed 8 bytes integer
		try:
			nb_bytes = unpack('>q', self.read_pipe.read(8))[0]
		except:
			# ocaml process has been terminated
			exit_lymp()
		byts = b'' if sys.version_info.major == 3 else ""
		while len(byts) < nb_bytes:
			byts += self.read_pipe.read(nb_bytes)
		return byts

class ExecutionHandler:

	to_ret_types = {
		int: "i",
		tuple: "t",
		list: "l",
		str: "s",
		float: "f",
		type(None): "n",
		bool: "b",
		bytes: "B"
	}
	# for python 2, unicode is str and str is bytes
	if sys.version_info.major == 2:
		to_ret_types[unicode] = "s"
		to_ret_types[str] = "B"

	def __init__(self, reader_writer):
		self.reader_writer = reader_writer
		self.modules = {}
		self.objs = {}
		self.ref_nb = 0

	def loop(self):
		# don't recursively call .loop, to avoid stack overflow
		while True:
			command_bytes = self.reader_writer.get_bytes()
			if command_bytes == b'done':
				exit_lymp()
			instruction = bson.BSON.decode(bson.BSON(command_bytes))
			try:
				ret = self.execute_instruction(instruction)
				# data may still be in the buffer
				sys.stdout.flush()
				self.send_ret(ret, ret_ref=("R" in instruction))
			except BaseException as e:
				# exception whilst executing, inform ocaml side
				print_exc()
				# data may still be in the buffer
				sys.stdout.flush()
				self.send_ret("", exception=True)

	def ret_to_msg(self, ret, ret_ref):
		msg = {}
		# reference (type not supported or explicitely asked to)
		if ret_ref or (type(ret) not in self.to_ret_types):
			self.ref_nb += 1
			self.objs[self.ref_nb] = ret
			msg["t"] = "r"
			msg["v"] = bson.code.Code(str(self.ref_nb))
		else:
			msg["t"] = self.to_ret_types[type(ret)]
			# tuples are just like lists, but their type "t" is "t" instead of "l"
			if type(ret) is tuple:
				ret = list(ret)
			# if type is list, further resolve
			if type(ret) is list:
				msg["v"] = []
				for elt in ret:
					# ret_ref is false here (would not be in the else otherwise)
					msg["v"].append(self.ret_to_msg(elt, False))
			else:
				msg["v"] = py_to_bson(ret)
		return msg

	def send_ret(self, ret, exception=False, ret_ref=False):
		if exception:
			msg = {}
			msg["t"] = "e"
			msg["v"] = ""
		else:
			msg = self.ret_to_msg(ret, ret_ref)
		msg = bytes(bson.BSON.encode(msg))
		self.reader_writer.send_bytes(msg)

	def resolve_args(self, args):
		named = {}
		i = 0
		for arg in args:
			# resolve named args (list of size 2, first one being a bson.code.Code starting with "!")
			if type(arg) is list and len(arg) == 2 and type(arg[0]) is bson.code.Code and str(arg[0])[0] == "!":
        named[str(arg[0])[1:]] = self.resolve_args([arg[1]])[0][0]
				del args[i]
				continue
			# if bytes
			if type(arg) is bson.binary.Binary:
				args[i] = bytes(arg)
			# resolve reference args (using bson jscode)
			if type(arg) is bson.code.Code:
				args[i] = self.objs[int(arg)]
			if type(arg) is bson.int64.Int64:
				args[i] = int(arg)
			# for python 2, if arg is str, convert to unicode
			if sys.version_info.major == 2 and type(arg) is str:
				args[i] = args[i].decode('utf-8')
			# for python 2, if arg is bytes, convert to str
			if sys.version_info.major == 2 and type(arg) is bson.binary.Binary:
				args[i] = str(arg)
			# if we have a list, we must recursively resolve
			if type(arg) is list:
				args[i] = self.resolve_args(arg)[0]
			# if we have a dict, it is a tuple inside "v"
			if type(arg) is dict:
				args[i] = tuple(self.resolve_args(arg["v"])[0])
			i += 1
		return args, named

	def execute_instruction(self, instruction):
		if "r" in instruction:
			# if we are asked to realease an inexisting of already released reference
			if "d" in instruction and instruction["r"] not in self.objs:
				return None
			# module is the object referenced, later we call getattr to get the method called
			module = self.objs[instruction["r"]]
			# if we were asked to 'detach' (release) the reference
			if "d" in instruction:
				del self.objs[instruction["r"]]
				return None
			# if we were asked to return the reference
			if "g" in instruction:
				return module
		else:
			# python 2 builtin module has a different name
			if sys.version_info.major == 2 and instruction["m"] == "builtins":
				instruction["m"] = "__builtin__"
			if instruction["m"] not in self.modules:
				__import__(instruction["m"])
				self.modules[instruction["m"]] = sys.modules[instruction["m"]]
			module = self.modules[instruction["m"]]
		# set attribute
		if "s" in instruction:
			args, named = self.resolve_args(instruction["a"])
			arg = args[0]
			setattr(module, instruction["f"], arg)
			return None
		func_or_attr = getattr(module, instruction["f"])
		# get attribute
		if "t" in instruction:
			return func_or_attr
		args = instruction["a"]
		args, named = self.resolve_args(args)
		ret = func_or_attr(*args, **named)
		return ret

working_directory = sys.argv[1]
write_pipe_path = sys.argv[2]
read_pipe_path = sys.argv[3]
# changing dir
os.chdir(working_directory)
sys.path.insert(0, working_directory)
# redirect stdout to 'python_log'
sys.stdout = codecs.open('python_log', 'w', encoding='utf-8')
sys.stderr = sys.stdout
communication = PipeReaderWriter(read_pipe_path, write_pipe_path)
handler = ExecutionHandler(communication)
handler.loop()
