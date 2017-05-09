#!/usr/bin/env python2.7
import struct

f = open('audio', 'rw+')
f.seek(0x28)
position = struct.unpack('P', f.read(8))
f.seek(position[0])
f.truncate()