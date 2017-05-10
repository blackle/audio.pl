import posix as px
import sys
import array
from math import *
import cmath
import random

rate = 22050
time = 0
pastsample = 0
octaves = [1, 2, 4, 8]

def p2m(pitch):
	global rate
	return (pi*2*pitch)/rate

# modulator, carrier, delta
def fm_mod(time, fm, fc, fd):
	mfm = p2m(fm)
	mfc = p2m(fc)
	return sin(mfc * time + fd * cos(time * mfm)/fm);

# carrier, phase shift
def pm_mod(time, fc, ps):
	mfc = p2m(fc)
	return sin(mfc * time + ps);

#x, y, lambda, theta, phi, sigma, gamma
def gabor(x, y, l, t, p, s, g)

def gensample():
	global time
	global pastsample
	time += 1
	pitch = 200
	if (time % 10000 == 0):
		random.shuffle(octaves)
	newsample = pm_mod(time, pitch*octaves[0], fm_mod(time, pitch*octaves[1], pitch*octaves[2], 100)*octaves[3])
	pastsample = pastsample*0.9 + newsample*0.1
	return pastsample

def main():
	read, write = px.pipe()
	pid = px.fork()
	if (pid == 0):
		px.close(read)
		px.dup2(write, 1)

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