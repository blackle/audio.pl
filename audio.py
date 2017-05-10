import posix as px
import sys
import array
from math import *
import random

rate = 22050
time = 0

def p2m(pitch):
	global rate
	return (pi*2*pitch)/rate

def sec2samp(sec):
	return (1.0*sec)*rate

def samp2sec(time):
	return (1.0*time)/rate

samplelength = int(sec2samp(0.05))+1
samples = [0]*samplelength

class Rosenberg:
	def __init__(self, ts, cps, p1, p2, p3):
		self.time = int(0)
		self.sum = float(0)
		self.ts = float(ts)
		self.cps = float(cps)
		self.p1 = float(p1)
		self.p2 = float(p2)
		self.p3 = float(p3)

	def step(self):
		self.time += 1
		t = self.time
		t %= int(sec2samp(1.0/self.cps))
		s = samp2sec(t)/self.ts
		diff = 0
		if (s < 1):
			diff += self.p1*pow(s, self.p1-1)
			diff -= self.p2*pow(s, self.p2-1)
			diff += pow(s, self.p3)
			diff -= 1.0/(self.p3 + 1.0)
		self.sum += diff/sec2samp(self.ts)
		self.sum *= 0.995 #correct any bias toward 0
		return self.sum

rosen = Rosenberg(0.007, 100, 2.0, 3.0, 60.0)

def gensample():
	global samples
	global rosen
	newsample = rosen.step()
	# samples.pop()
	# samples.insert(0,newsample)

	# outsample = 0
	# for x in xrange(0, 100):
	# 	outsample += samples[x]
	# outsample /= 10.0
	return newsample

def main():
	read, write = px.pipe()
	pid = px.fork()
	if (pid != 0):
		px.close(read)

		bufsize = 1024
		buf = array.array('f', [0]*bufsize)

		while 1:
			try:
				for i in xrange(0,bufsize):
					buf[i] = gensample()
				px.write(write, buf.tostring())
			except KeyboardInterrupt:
				exit(0)
	else:
		px.close(2)
		px.close(write)
		px.dup2(read, 0)
		aplay_args = ("/usr/bin/aplay -q -c 1 -r %d -f FLOAT_LE" % rate).split(" ")
		px.execv(aplay_args[0], aplay_args)

main()