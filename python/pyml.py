

READ_PIPE_NAME = "my_named_pipe2"
WRITE_PIPE_NAME = "my_named_pipe"

from time import time
from struct import pack, unpack

class Log:

	def __init__(self, filename="python_log"):
		self.file = open(filename, "w")

	def log(self, msg):
		self.file.write(msg)

	def close(self):
		self.file.close()

class PipeReaderWriter:

	def __init__(self, read_pipe_name, write_pipe_name):
		self.set_pipes(read_pipe_name, write_pipe_name)
		self.say_hello()

	def get_pipes(self, read_pipe_name, write_pipe_name):
		# order of open matters, since it is blocking, should match OCaml order
		# 0 to be unbuffered, so we don't have to flush (better performance ?)
		self.write_pipe = open(write_pipe_name, 'wb', 0)
		self.read_pipe = open(read_pipe_name, 'rb', 0)
		return (read_pipe, write_pipe)

	def send_bytes(self, byts):
		# '=q' to force signed 8 bytes integer
		self.write_pipe.write(pack('=q', len(byts)))
		#self.write_pipe.flush()
		self.write_pipe.write(byts)
		#self.write_pipe.flush()

	def get_bytes(self):
		# '=q' to force signed 8 bytes integer
		nb_bytes = unpack('=q', self.read_pipe.read(8))[0]
		return self.read_pipe.read(nb_bytes)

	def say_hello(self):
		# being polite can't make things worse
	#	self.send_bytes(b'hello')
		pass

class 

log = Log()
pipes = PipeReaderWriter(READ_PIPE_NAME, WRITE_PIPE_NAME)