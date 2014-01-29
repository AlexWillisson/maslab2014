// -*- c -*-

#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <math.h>

#define PWM0 0
#define DIR0 1
#define PWM1 5
#define DIR1 7
#define SPEED 5000
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

int driving;

struct dev {
	int numpins, *pins, *modes;
};

struct dev lmotor, rmotor, lencoder, rencoder;

struct dev *
make_dev (struct dev *dp, int numpins, ...)
{
	int idx;
	va_list arg;

	if ((dp->pins = (int *) calloc (numpins, sizeof *dp->pins)) == NULL) {
		SerialUSB.println ("memory error");
		return (NULL);
	}

	if ((dp->modes = (int *) calloc (numpins, sizeof *dp->modes)) == NULL) {
		SerialUSB.println ("memory error");
		return (NULL);
	}

	va_start (arg, numpins);

	dp->numpins = numpins;

	for (idx = 0; idx < numpins; idx++) {
		dp->pins[idx] = va_arg (arg, int);
		dp->modes[idx] = va_arg (arg, int);
	}

	va_end (arg);

	map_pins (dp);

	return (dp);
}

void
map_pins (struct dev *dp) {
	int idx;

	for (idx = 0; idx < dp->numpins; idx++) {
		pinMode (dp->pins[idx], (WiringPinMode) dp->modes[idx]);
	}
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
set_motor (int side, int rate) {
	int pwm, dir;

	if (rate < 0) {
		dir = HIGH;
	} else {
		dir = LOW;
	}

	pwm = rate;

	if (pwm > MAX_SPEED) {
		pwm = MAX_SPEED;
	}

	switch (side) {
	case LEFT:
		pwmWrite (lmotor.pins[0], pwm);
		digitalWrite (lmotor.pins[1], dir);
		break;
	case RIGHT:
		pwmWrite (rmotor.pins[0], pwm);
		digitalWrite (rmotor.pins[1], dir);
		break;
	}
}

void
setup (void)
{
	make_dev (&lmotor, PWM0, PWM, DIR0, OUTPUT);
	make_dev (&rmotor, PWM1, PWM, DIR1, OUTPUT);

	/* /\* setup_encoder (&left_encoder, 8, 9, 10, 11, count_left); *\/ */
	/* /\* setup_encoder (&right_encoder, 23, 24, 25, 26, count_right); *\/ */

	set_motor (LEFT, 0);
	set_motor (RIGHT, 0);
}

void
loop (void)
{
        int idx, avail, c;
	/* char buf[500]; */

        avail = SerialUSB.available ();
        
        for (idx = 0; idx < avail; idx++) {
		c = SerialUSB.read ();
		switch (c) {
		case 'w':
			set_motor (LEFT, SPEED);
			set_motor (RIGHT, SPEED);
			/* digitalWrite (RIGHT_DIR, LOW); */
			/* digitalWrite (LEFT_DIR, LOW); */
			/* pwmWrite (RIGHT_MOTOR, SPEED); */
			/* pwmWrite (LEFT_MOTOR, SPEED); */
			/* driving = 1; */
			break;
		case 's':
			set_motor (LEFT, -SPEED);
			set_motor (RIGHT, -SPEED);
			/* digitalWrite (RIGHT_DIR, HIGH); */
			/* digitalWrite (LEFT_DIR, HIGH); */
			/* pwmWrite (RIGHT_MOTOR, SPEED); */
			/* pwmWrite (LEFT_MOTOR, SPEED); */
			/* driving = 1; */
			break;
		case 'a':
			set_motor (LEFT, -SPEED);
			set_motor (RIGHT, SPEED);
			/* digitalWrite (RIGHT_DIR, LOW); */
			/* digitalWrite (LEFT_DIR, HIGH); */
			/* pwmWrite (RIGHT_MOTOR, SPEED); */
			/* pwmWrite (LEFT_MOTOR, SPEED); */
			/* driving = 1; */
			break;
		case 'd':
			set_motor (LEFT, SPEED);
			set_motor (RIGHT, -SPEED);
			/* digitalWrite (RIGHT_DIR, HIGH); */
			/* digitalWrite (LEFT_DIR, LOW); */
			/* pwmWrite (RIGHT_MOTOR, SPEED); */
			/* pwmWrite (LEFT_MOTOR, SPEED); */
			/* driving = 1; */
			break;
		case ' ':
			set_motor (LEFT, 0);
			set_motor (RIGHT, 0);
			/* if (driving) { */
			/* 	driving = 0; */
			/* 	pwmWrite (RIGHT_MOTOR, 0); */
			/* 	pwmWrite (LEFT_MOTOR, 0); */
			/* } else { */
			/* 	driving = 1; */
			/* 	pwmWrite (RIGHT_MOTOR, SPEED); */
			/* 	pwmWrite (LEFT_MOTOR, SPEED); */
			/* } */
		default:
			break;
		}
        }

	/* if (digitalRead (38) == HIGH) { */
	/* 	sprintf (buf, "left: %d\t\tright: %d\n\r", */
	/* 		 left_encoder.ticks, right_encoder.ticks); */
	/* 	SerialUSB.print (buf); */
	/* } */
	delay (10);
}
