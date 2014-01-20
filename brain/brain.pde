// -*- c -*-

#define RIGHT_MOTOR 14
#define LEFT_MOTOR 3
#define RIGHT_DIR 13
#define LEFT_DIR 4
#define SPEED 10000

#define ROT_THRESH 1

int us_vcc, us_trig, us_echo, us_gnd;
int driving;
int us_val, echo_low, recv_echo, us_start;

void
ultrasonic_sample (void)
{
	SerialUSB.println ("foo");

	if ( ! recv_echo) {
		if (micros () - us_start < 60000) {
			return;
		}
	}

	SerialUSB.println ("bar");

	if ( ! echo_low) {
		return;
	}

	SerialUSB.println ("baz");

	digitalWrite (us_trig, HIGH);
	delayMicroseconds (10);
	digitalWrite (us_trig, LOW);
	us_start = micros ();

	echo_low = 1;
	recv_echo = 0;
}

void
ultrasonic_isr (void)
{
	SerialUSB.println ("quux");

	if (echo_low) {
		us_start = micros ();
		echo_low = 0;
		recv_echo = 1;
	} else {
		us_val = micros () - us_start;
		echo_low = 1;
	}
}

void
ultrasonic_setup (int vcc, int trig, int echo, int gnd)
{
	us_vcc = vcc;
	us_trig = trig;
	us_echo = echo;
	us_gnd = gnd;

	pinMode (us_gnd, OUTPUT);
	pinMode (us_vcc, OUTPUT);

	pinMode (us_trig, OUTPUT);
	pinMode (us_echo, INPUT);

	digitalWrite (us_vcc, HIGH);
	digitalWrite (us_gnd, LOW);
	digitalWrite (us_trig, LOW);

	attachInterrupt (us_echo, ultrasonic_isr, CHANGE);

	echo_low = 0;
}

void
setup (void)
{
	pinMode (RIGHT_MOTOR, PWM);
	pinMode (LEFT_MOTOR, PWM);
	pinMode (RIGHT_DIR, OUTPUT);
	pinMode (LEFT_DIR, OUTPUT);
	
	ultrasonic_setup (2, 3, 4, 5);

	driving = 0;
	digitalWrite (RIGHT_DIR, LOW);
	digitalWrite (LEFT_DIR, LOW);
        pwmWrite (RIGHT_MOTOR, 0);
        pwmWrite (LEFT_MOTOR, 0);
}

double
us_to_cm (long usec)
{
	return ((usec / 29) / 2);
}

void
loop (void)
{
        int idx, avail, c;
	long duration;
	double cm;

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

	ultrasonic_sample ();

	cm = us_to_cm (us_val);

	SerialUSB.println (cm);

	delay (100);
}
