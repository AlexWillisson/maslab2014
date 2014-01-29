#! /usr/bin/env python

import socket, sys

s = socket.socket (socket.AF_INET, socket.SOCK_STREAM)
s.connect (("18.150.7.174", 6667))

data0 = ""
data1 = ""
data2 = ""
while True:
    data0 = s.recv (1024)
    data2 = data1 + data2
    if "start" in data2.lower ():
        sys.exit ()
    data1 = data0
