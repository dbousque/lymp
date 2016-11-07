

from time import time
from struct import pack, unpack
import bson, sys, os
from random import randint

def int_to_int64_bytes(i):
	return pack('>q', i)

def py_to_bson(val):
	if type(val) is int:
		return bson.int64.Int64(val)
	return val

# a communication class, could be implemented using other ipc methods,
# it only needs the methods 'send_bytes' and 'get_bytes'
class PipeReaderWriter:

	def __init__(self, read_pipe_name, write_pipe_name):
		self.get_pipes(read_pipe_name, write_pipe_name)
		self.say_hello()

	def get_pipes(self, read_pipe_name, write_pipe_name):
		# order of open matters, since it is blocking, should match OCaml order
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
		nb_bytes = unpack('>q', self.read_pipe.read(8))[0]
		return self.read_pipe.read(nb_bytes)

	def say_hello(self):
		# being polite can't make things worse
	#	self.send_bytes(b'hello')
		pass

class ExecutionHandler:

	to_ret_types = {
		int: "i",
		list: "l",
		str: "s",
		float: "f",
		type(None): "n",
		bool: "b",
		bytes: "B"
	}

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
				# closing 'python_log'
				sys.stdout.close()
				exit(0)
			instruction = bson.BSON.decode(command_bytes)
			ret = self.execute_instruction(instruction)
			# data may still be in the buffer
			sys.stdout.flush()
			self.send_ret(ret)

	def send_ret(self, ret):
		msg = {}
		# reference
		if type(ret) not in self.to_ret_types:
			self.ref_nb += 1
			self.objs[self.ref_nb] = ret
			msg["t"] = "r"
			msg["v"] = bson.code.Code(str(self.ref_nb))
		else:
			msg["t"] = self.to_ret_types[type(ret)]
			msg["v"] = py_to_bson(ret)
		msg = bytes(bson.BSON.encode(msg))
		self.reader_writer.send_bytes(msg)

	def execute_instruction(self, instruction):
		if "r" in instruction:
			# module is the object referenced, later we call getattr to get the method called
			module = self.objs[instruction["r"]]
			# if we were asked to return the reference
			# (might fail in case the object is not supported)
			if "g" in instruction:
				return module
		else:
			if instruction["m"] not in self.modules:
				__import__(instruction["m"])
				self.modules[instruction["m"]] = sys.modules[instruction["m"]]
			module = self.modules[instruction["m"]]
		func = getattr(module, instruction["f"])
		args = instruction["a"]
		# resolve reference args
		for i,arg in enumerate(args):
			if type(arg) is bson.code.Code:
				args[i] = self.objs[int(arg)]
		ret = func(*args)
		return ret

working_directory = sys.argv[1]
write_pipe_path = sys.argv[2]
read_pipe_path = sys.argv[3]
# changing dir
os.chdir(working_directory)
sys.path.insert(0, working_directory)
# redirect stdout to 'python_log'
sys.stdout = open('python_log', 'w')
communication = PipeReaderWriter(read_pipe_path, write_pipe_path)
handler = ExecutionHandler(communication)
handler.loop()
