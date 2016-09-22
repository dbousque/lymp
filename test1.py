

from time import time
import sys

def do_some_calculation():
	total = 0
	#for x in range(100):
	#	total += x

def make_file(filename):
	fil = open(filename, "w")
	# start, tell ocaml we're ready
	inp = input()
	sys.stdout.write("backTo\n")
	sys.stdout.flush()
	start = time()
	tmp = start
	nb = None
	fil.write(str(start))
	fil.write("\n")
	fil.flush()
	sys.stderr.write("start\n")
	for i in range(10000000000):
		#last = tmp
		if i % 30 == 0:
			if time() - start > 1:
				nb = i * 6
				#fil.write("BREAKING!!!!\n")
				break
		#fil.write("i1\n")
		#fil.flush()
		inp = input()
		#fil.write("w1\n")
		#fil.flush()
		sys.stdout.write("backTo\n")
		sys.stdout.flush()

		do_some_calculation()

		#fil.write("i2\n")
		#fil.flush()
		inp = input()
		#fil.write("w2\n")
		#fil.flush()
		sys.stdout.write("backTo\n")
		sys.stdout.flush()

		do_some_calculation()

		#fil.write("i3\n")
		#fil.flush()
		inp = input()
		#fil.write("w3\n")
		#fil.flush()
		sys.stdout.write("backTo\n")
		sys.stdout.flush()

		do_some_calculation()

		#fil.write("i4\n")
		#fil.flush()
		inp = input()
		#fil.write("w4\n")
		#fil.flush()
		sys.stdout.write("backTo\n")
		sys.stdout.flush()

		do_some_calculation()

		#fil.write("i5\n")
		#fil.flush()
		inp = input()
		#fil.write("w5\n")
		#fil.flush()
		sys.stdout.write("backTo\n")
		sys.stdout.flush()

		do_some_calculation()

		#fil.write("i6\n")
		#fil.flush()
		inp = input()
		#fil.write("w6\n")
		#fil.flush()
		sys.stdout.write("backTo\n")
		sys.stdout.flush()

		do_some_calculation()


		#fil.write("time\n")
		#fil.flush()
		#tmp = time()
		sys.stderr.write("i\n")
		#sys.stderr.write("ok" + str(i) + "\n")
		#sys.stderr.write("elapsed : " + str(tmp - last) + "\n")
	sys.stderr.write("all done")
	fil.write(str(time()))
	fil.write("\n")
	fil.write("times : " + str(nb) + "\n")
	fil.close()
	sys.stderr.write("done\n")

try:
	make_file("lolz.ok")
except Exception as e:
	sys.stderr.write("EXCEPTION\n")
	sys.stderr.write(e)