#! /usr/bin/env python

import socket, base64, time

s = socket.socket (socket.AF_INET, socket.SOCK_STREAM)
s.connect (("18.150.7.174", 6667))

frame = []

f = open ("frame00.png")
frame.append (base64.b64encode (f.read ()))

f = open ("frame01.png")
frame.append (base64.b64encode (f.read ()))

f = open ("frame02.png")
frame.append (base64.b64encode (f.read ()))

f = open ("frame03.png")
frame.append (base64.b64encode (f.read ()))

f = open ("frame04.png")
frame.append (base64.b64encode (f.read ()))

f = open ("frame05.png")
frame.append (base64.b64encode (f.read ()))

f = open ("frame06.png")
frame.append (base64.b64encode (f.read ()))

f = open ("frame07.png")
frame.append (base64.b64encode (f.read ()))

f = open ("frame08.png")
frame.append (base64.b64encode (f.read ()))

f = open ("frame09.png")
frame.append (base64.b64encode (f.read ()))

f = open ("frame10.png")
frame.append (base64.b64encode (f.read ()))

f = open ("frame11.png")
frame.append (base64.b64encode (f.read ()))

idx = 0

s.send ("{\"token\": \"a12L7plGB8\", \"a\": [\"<marquee>nyanness</marquee>\", \"yay\"]}done\n")

while True:
    time.sleep (.1)
 
    idx += 1
    idx = idx % 11

#    print "{\"token\": \"a12L7plGB8\", \"IMAGE_DATA\": \"" + frame[idx] + "\"}done"
    s.send ("{\"token\": \"a12L7plGB8\", \"IMAGE_DATA\": \"" + frame[idx] + "\"}done\n")
#320x240
