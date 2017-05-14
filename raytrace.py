import posix as px
import sys
import array
from math import *
import random

class Point:
	def __init__(this,x,y,z):
		this.x = float(x)
		this.y = float(y)
		this.z = float(z)

	def __add__(this, other):
		assert isinstance(other, Vector)
		return Point(this.x + other.x, this.y + other.y, this.z + other.z)

	def __sub__(this, other):
		assert isinstance(other, Point)
		return Vector(this.x - other.x, this.y - other.y, this.z - other.z)

	def __str__(this):
		return "p(%f %f %f)" % (this.x, this.y, this.z)

class Vector:
	def __init__(this,x,y,z):
		this.x = float(x)
		this.y = float(y)
		this.z = float(z)

	def length(this):
		return sqrt(this*this)

	def normalize(this):
		normalizer = 1.0/this.length()
		this.x *= normalizer
		this.y *= normalizer
		this.z *= normalizer

	def __mul__(this, other):
		if isinstance(other, float):
			return Vector(this.x*other, this.y*other, this.z*other)
		elif isinstance(other, Vector):
			return this.x*other.x + this.y*other.y + this.z*other.z
		else:
			assert False

	#use xor as cross product
	def __xor__(t, o):
		assert isinstance(o, Vector)
		return Vector(t.y*o.z - t.z*o.y, t.z*o.x - t.x*o.z, t.x*o.y - t.y*o.x)

	def __add__(this, other):
		assert isinstance(other, Vector)
		return Point(this.x + other.x, this.y + other.y, this.z + other.z)

	def __str__(this):
		return "v(%f %f %f)" % (this.x, this.y, this.z)

ORIGIN = Point(0,0,0)
VEC_X = Vector(1,0,0)
VEC_Y = Vector(0,1,0)
VEC_Z = Vector(0,0,1)
EPSI = 0.0001
EPSI_VEC_X = Vector(EPSI,0,0)
EPSI_VEC_Y = Vector(0,EPSI,0)
EPSI_VEC_Z = Vector(0,0,EPSI)

def distance_deriv(df, point):
	x = (df(point + EPSI_VEC_X) - df(point))/EPSI
	y = (df(point + EPSI_VEC_Y) - df(point))/EPSI
	z = (df(point + EPSI_VEC_Z) - df(point))/EPSI
	return Vector(x,y,z)

class Path:
	def __init__(this,orig,dire):
		assert isinstance(orig, Point)
		assert isinstance(dire, Vector)
		this.orig = orig
		this.dire = dire
		this.current = orig

	def cast(this, df):
		assert callable(df)
		distance = df(this.current)
		while distance > EPSI:
			this.current = this.current + this.dire * distance
			distance = df(this.current)

	def distance(this):
		return this.orig - this.current


def distance_field(point):
	radius = 10
	dx = radius - abs(point.x)
	dy = radius - abs(point.y)
	dz = radius - abs(point.z)
	return min(dx, min(dy, dz))

def main():

	deriv = Vector(0,0,0)
	end = Point(0,0,0)
	for i in xrange (0, 10000):
		direction = Vector(1, 0.8, 0)
		direction.normalize()
		# print direction
		path = Path(ORIGIN, direction)
		path.cast(distance_field)
		end = path.current
		deriv = distance_deriv(distance_field, path.current)
	# print path.orig
	# print path.current
	print end
	print deriv


main()