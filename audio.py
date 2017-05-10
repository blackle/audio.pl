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

def seconds2samples(time):
	return (1.0*time)*rate

def samples2seconds(time):
	return (1.0*time)/rate

samplelength = int(seconds2samples(0.05))+1
samples = [0]*samplelength

# rosenberg pulse
def rosenberg(time, ts, cps, p1, p2):
	s = samples2seconds(time)/ts
	s %= 1.0/(cps*ts)
	if (s < 1):
		return pow(s,p1) - pow(s,p2)
	else:
		return 0

def gensample():
	global time
	global samples
	time += 1
	newsample = rosenberg(time, 0.007, 100, 2.0, 3.0)
	samples.pop()
	samples.insert(0,newsample)

	outsample = 0
	for x in xrange(0, 100):
		outsample += samples[x]
	outsample /= 10.0
	return outsample

def main():
	read, write = px.pipe()
	pid = px.fork()
	if (pid == 0):
		px.close(read)

		bufsize = 1024
		buf = array.array('f', [0]*bufsize)

		while 1:
			for i in xrange(0,bufsize):
				buf[i] = gensample()
			px.write(write, buf.tostring())
		exit(0)
	else:
		px.close(write)
		px.dup2(read, 0)
		aplay_args = ("/usr/bin/aplay -q -c 1 -r %d -f FLOAT_LE" % rate).split(" ")
		px.execv(aplay_args[0], aplay_args)

main()