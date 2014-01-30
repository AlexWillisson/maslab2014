#! /usr/bin/env python

import serial, time, shutil

us = [0, 0, 0, 0]

s = serial.Serial ("/dev/ttyACM0", 9600, timeout=1)
buf = ""
while True:
    try:
        l = s.read ()

        if "\n" not in l:
            buf += l
            continue
        else:
            foo = l.split ("\n")
            line = buf + foo[0]
            buf = foo[1]

        if len (line) < 6:
            continue

        b = line[2:3]
        c = line[5:]

        if b == "0":
            us[0] = float (c)
        elif b == "1":
            us[1] = float (c)
        elif b == "2":
            us[2] = float (c)
        elif b == "3":
            us[3] = float (c)

        f = open ("ultrasonics.tmp", "w")
        f.write (",".join([str (x) for x in us]))
        f.close ()

        shutil.move ("ultrasonics.tmp", "ultrasonics")
    except:
        pass

