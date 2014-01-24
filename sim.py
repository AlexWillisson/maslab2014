#! /usr/bin/env python

import pygame, time, sys, math, random

WIDTH = 800
HEIGHT = 600

def draw ():
    global ball_x

    screen.fill ((0, 0, 0))

    pygame.draw.circle (screen, 0x00ff00, (int (ball_x), 300), 80)

    pygame.draw.line (screen, 0x0000ff, (400, 0), (400, 600))

    pygame.display.flip ()

def process_input ():
    global ball_x, paused

    for event in pygame.event.get ():
        if event.type == pygame.QUIT:
            pygame.quit ()
            sys.exit ()
        elif event.type == pygame.KEYDOWN:
            if event.key == pygame.K_ESCAPE:
                pygame.quit ()
                sys.exit ()
        elif event.type == pygame.KEYUP:
            if event.key == pygame.K_r:
                ball_x = (random.random () * 800) + 1
            elif event.key == pygame.K_p:
                paused ^= True

pygame.init ()
screen = pygame.display.set_mode ((WIDTH, HEIGHT))
pygame.display.set_caption ("maslab sim")

fps = 60
framestep = 1.0 / fps

last_time = time.time ()

ball_x = (random.random () * 800) + 1

prev_err = 0
integ = 0

p = 2
i = 0
d = -0.5

paused = True

while True:
    t = framestep - (time.time () - last_time)
    if t > 0:
        time.sleep (t)

    process_input ()

    draw ()

    if not paused:
        dt = time.time () - last_time
        err = 400 - ball_x
        integ = integ + err * (time.time () - last_time)
        deriv = (err - prev_err) / dt
        acc = (p * err + i * integ + d * deriv) * dt
        ball_x += acc
        prev_err = err

    last_time = time.time ()
