import posix as px
import sys
import array
from math import *
import random

class Point:
	def __init__(this,x,y,z):
		this.x = x
		this.y = y
		this.z = z

def distance_field(point):
	radius = 10
	dx = radius - abs(point.x)
	dy = radius - abs(point.y)
	dz = radius - abs(point.z)
	return min(dx, min(dy, dz))

def main():
	for x in xrange (-20, 20, 1):
		for y in xrange (-20, 20, 1):
			point = Point(x,y,-10.1)
			if (distance_field(point) > 0):
				print ".",
			else:
				print "#",
		print ""

main()