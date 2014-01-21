// -*- c -*-

#include <stdio.h>

#define RIGHT_MOTOR 14
#define LEFT_MOTOR 3
#define RIGHT_DIR 13
#define LEFT_DIR 4
#define SPEED 20000

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
	setup_motor (&left_motor, LEFT_MOTOR, LEFT_DIR);
	setup_motor (&right_motor, RIGHT_MOTOR, RIGHT_DIR);

	setup_encoder (&left_encoder, 8, 9, 10, 11, count_left);
	setup_encoder (&right_encoder, 23, 24, 25, 26, count_right);

	driving = 0;
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
			digitalWrite (RIGHT_DIR, LOW);
			digitalWrite (LEFT_DIR, LOW);
			pwmWrite (RIGHT_MOTOR, SPEED);
			pwmWrite (LEFT_MOTOR, SPEED);
			driving = 1;
			break;
		case 's':
			digitalWrite (RIGHT_DIR, HIGH);
			digitalWrite (LEFT_DIR, HIGH);
			pwmWrite (RIGHT_MOTOR, SPEED);
			pwmWrite (LEFT_MOTOR, SPEED);
			driving = 1;
			break;
		case 'a':
			digitalWrite (RIGHT_DIR, LOW);
			digitalWrite (LEFT_DIR, HIGH);
			pwmWrite (RIGHT_MOTOR, SPEED);
			pwmWrite (LEFT_MOTOR, SPEED);
			driving = 1;
			break;
		case 'd':
			digitalWrite (RIGHT_DIR, HIGH);
			digitalWrite (LEFT_DIR, LOW);
			pwmWrite (RIGHT_MOTOR, SPEED);
			pwmWrite (LEFT_MOTOR, SPEED);
			driving = 1;
			break;
		case ' ':
			if (driving) {
				driving = 0;
				pwmWrite (RIGHT_MOTOR, 0);
				pwmWrite (LEFT_MOTOR, 0);
			} else {
				driving = 1;
				pwmWrite (RIGHT_MOTOR, SPEED);
				pwmWrite (LEFT_MOTOR, SPEED);
			}
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
