#! /usr/bin/env python

import serial, time

us = [0, 0, 0, 0]

s = serial.Serial ("/dev/ttyACM1", 9600, timeout=1)
s.close ()
s.open ()
while True:
    r = s.read (size=64)

    print r
    
    a = r.split ("\n")

    for i in range (1, len (a) - 2):
        b = a[2:3]
        c = a[5:]

        if b == "0":
            us[0] = float (c)
        elif b == "1":
            us[1] = float (c)
        elif b == "2":
            us[2] = float (c)
        elif b == "3":
            us[3] = float (c)

    f = open ("ultrasonics", "w")
    f.write (",".join([str (x) for x in us]))
    f.close ()

    time.sleep (.04)

