// -*- c -*-

#include <stdarg.h>

#define TRIG0 8
#define ECHO0 7

#define TRIG1 13
#define ECHO1 12

#define TRIG2 11
#define ECHO2 10

#define TRIG2 11
#define ECHO2 10

#define TRIG3 5
#define ECHO3 4

#define DISABLED 0
#define ENABLED 1

struct dev {
	int numpins, *pins, *modes;
};

struct dev ultrasonic0, ultrasonic1, ultrasonic2, ultrasonic3;

struct dev *
make_dev (struct dev *dp, int numpins, ...)
{
	int idx;
	va_list arg;

	if ((dp->pins = (int *) calloc (numpins, sizeof *dp->pins)) == NULL) {
		Serial.println ("memory error");
		return (NULL);
	}

	if ((dp->modes = (int *) calloc (numpins, sizeof *dp->modes)) == NULL) {
		Serial.println ("memory error");
		return (NULL);
	}

	va_start (arg, numpins);

	dp->numpins = numpins;

	for (idx = 0; idx < numpins; idx++) {
		dp->pins[idx] = va_arg (arg, int);
		dp->modes[idx] = va_arg (arg, int);
	}

	va_end (arg);

	return (dp);
}

void
map_pins (struct dev *dp) {
	int idx;

	for (idx = 0; idx < dp->numpins; idx++) {
		pinMode (dp->pins[idx], dp->modes[idx]);
	}
}

double
sample_ultrasonic (struct dev *dp)
{
	long duration, distance;

	digitalWrite (dp->pins[0], LOW);
	delayMicroseconds (2);
	digitalWrite (dp->pins[0], HIGH);
	delayMicroseconds (10);
	digitalWrite (dp->pins[0], LOW);

	duration = pulseIn (dp->pins[1], HIGH);
	distance = (duration / 2) / 29.1;

	return (duration / 2) / 29.1;
}

void
setup (void) {
	Serial.begin (9600);

	make_dev (&ultrasonic0, 2, TRIG0, OUTPUT, ECHO0, INPUT);
	map_pins (&ultrasonic0);

	make_dev (&ultrasonic1, 2, TRIG1, OUTPUT, ECHO1, INPUT);
	map_pins (&ultrasonic1);

	make_dev (&ultrasonic2, 2, TRIG2, OUTPUT, ECHO2, INPUT);
	map_pins (&ultrasonic2);

	make_dev (&ultrasonic3, 2, TRIG3, OUTPUT, ECHO3, INPUT);
	map_pins (&ultrasonic3);
}

void
loop (void) {
	Serial.print ("us0: ");
	Serial.println (sample_ultrasonic (&ultrasonic0));

	Serial.print ("us1: ");
	Serial.println (sample_ultrasonic (&ultrasonic1));

	Serial.print ("us2: ");
	Serial.println (sample_ultrasonic (&ultrasonic2));

	Serial.print ("us3: ");
	Serial.println (sample_ultrasonic (&ultrasonic3));

	delay(50);
}
