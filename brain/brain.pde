// -*- c -*-

#include <stdio.h>
#include <math.h>

#define RIGHT_PWM 5
#define RIGHT_DIR 7
#define LEFT_PWM 0
#define LEFT_DIR 1
#define SPEED 10000
#define MAX_SPEED 10000

enum {
	LEFT,
	RIGHT
};

struct motor {
	int pwm, dir;
};

struct motor left_motor, right_motor;

struct encoder {
	int vcc, gnd, a, b;
	long ticks;
};

struct encoder left_encoder, right_encoder;

void
setup_motor (struct motor *mp, int pwm, int dir)
{
	mp->pwm = pwm;
	mp->dir = dir;

	pinMode (mp->pwm, PWM);
	pinMode (mp->dir, OUTPUT);

	digitalWrite (mp->dir, LOW);
	pwmWrite (mp->pwm, 0);
}

void
setup_encoder (struct encoder *ep, int gnd, int vcc, int a, int b,
	       void (*handler) (void))
{
	ep->vcc = vcc;
	ep->gnd = gnd;
	ep->a = a;
	ep->b = b;

	pinMode (ep->vcc, OUTPUT);
	pinMode (ep->gnd, OUTPUT);
	pinMode (ep->a, INPUT);
	pinMode (ep->b, INPUT);

	digitalWrite (ep->vcc, HIGH);
	digitalWrite (ep->gnd, LOW);
	attachInterrupt (ep->a, handler, CHANGE);
	attachInterrupt (ep->b, handler, CHANGE);
}

void
set_motor (int side, int rate) {
	int pwm, dir;

	if (rate < 0) {
		dir = HIGH;
	} else {
		dir = LOW;
	}

	pwm = fabs (rate);

	if (pwm > MAX_SPEED) {
		pwm = MAX_SPEED;
	}

	switch (side) {
	case LEFT:
		pwmWrite (LEFT_PWM, pwm);
		digitalWrite (LEFT_DIR, dir);
		break;
	case RIGHT:
		pwmWrite (RIGHT_PWM, pwm);
		digitalWrite (RIGHT_DIR, dir);
		break;
	}
}

void
count_left (void)
{
	left_encoder.ticks++;
}

void
count_right (void)
{
	right_encoder.ticks++;
}

void
setup (void)
{
	setup_motor (&left_motor, LEFT_PWM, LEFT_DIR);
	setup_motor (&right_motor, RIGHT_PWM, RIGHT_DIR);
	pinMode (1, OUTPUT);
	digitalWrite (1, LOW);

	/* setup_encoder (&left_encoder, 8, 9, 10, 11, count_left); */
	/* setup_encoder (&right_encoder, 23, 24, 25, 26, count_right); */
}

void
loop (void)
{
        int idx, avail, c;
	char buf[500];

        avail = SerialUSB.available ();
        
        for (idx = 0; idx < avail; idx++) {
		c = SerialUSB.read ();
		switch (c) {
		case 'w':
			set_motor (LEFT, SPEED);
			set_motor (RIGHT, SPEED);
			break;
		case 's':
			set_motor (LEFT, -SPEED);
			set_motor (RIGHT, -SPEED);
			break;
		case 'a':
			set_motor (LEFT, -SPEED);
			set_motor (RIGHT, SPEED);
			break;
		case 'd':
			set_motor (LEFT, SPEED);
			set_motor (RIGHT, -SPEED);
			break;
		case ' ':
			set_motor (LEFT, 0);
			set_motor (RIGHT, 0);
			break;
		default:
			break;
		}
        }

	if (digitalRead (38) == HIGH) {
		sprintf (buf, "left: %d\t\tright: %d\n\r",
			 left_encoder.ticks, right_encoder.ticks);
		SerialUSB.print (buf);
	}
	delay (10);
}
