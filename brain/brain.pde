// -*- c -*-

#define RIGHT_MOTOR 14
#define LEFT_MOTOR 3
#define RIGHT_DIR 13
#define LEFT_DIR 4

#define GYRO_OUT 0
#define GYRO_GND 1
#define GYRO_VDD 2

#define GYRO_VOLT 3.2
#define GYRO_SENSITIVITY .007
#define GYRO_ZERO_VOLT 1.6

#define ROT_THRESH 1

int driving;
/* float theta; */

void
setup (void)
{
	pinMode (RIGHT_MOTOR, PWM);
	pinMode (LEFT_MOTOR, PWM);
	pinMode (RIGHT_DIR, OUTPUT);
	pinMode (LEFT_DIR, OUTPUT);

	driving = 0;
	digitalWrite (RIGHT_DIR, LOW);
	digitalWrite (LEFT_DIR, LOW);
        pwmWrite (RIGHT_MOTOR, 0);
        pwmWrite (LEFT_MOTOR, 0);

	/* pinMode (GYRO_OUT, INPUT_ANALOG); */
	/* pinMode (GYRO_GND, OUTPUT); */
	/* pinMode (GYRO_VDD, OUTPUT); */

	/* digitalWrite (GYRO_GND, LOW); */
	/* digitalWrite (GYRO_VDD, HIGH); */

	pinMode (24, INPUT);
	pinMode (26, OUTPUT);
	pinMode (28, OUTPUT);

	digitalWrite (26, HIGH);
	digitalWrite (28, LOW);
}

void
loop (void)
{
        int idx, avail, c;
	/* float gyro_rate; */
        
	/* gyro_rate = (analogRead (GYRO_OUT) * GYRO_VOLT) / 1023; */
	/* gyro_rate -= GYRO_ZERO_VOLT; */
	/* gyro_rate /= GYRO_SENSITIVITY; */
	/* if (gyro_rate >= ROT_THRESH || gyro_rate <= -ROT_THRESH) { */
	/* 	gyro_rate /= 100; */
	/* 	theta += gyro_rate; */
	/* } */

	/* if (theta < 0) */
	/* 	theta += 360; */
	/* else if (theta > 359) */
	/* 	theta -= 360; */

        avail = SerialUSB.available ();
        
        for (idx = 0; idx < avail; idx++) {
		c = SerialUSB.read ();
		switch (c) {
		case 'w':
			digitalWrite (RIGHT_DIR, LOW);
			digitalWrite (LEFT_DIR, LOW);
			pwmWrite (RIGHT_MOTOR, 10000);
			pwmWrite (LEFT_MOTOR, 10000);
			driving = 1;
			break;
		case 's':
			digitalWrite (RIGHT_DIR, HIGH);
			digitalWrite (LEFT_DIR, HIGH);
			pwmWrite (RIGHT_MOTOR, 10000);
			pwmWrite (LEFT_MOTOR, 10000);
			driving = 1;
			break;
		case 'a':
			digitalWrite (RIGHT_DIR, LOW);
			digitalWrite (LEFT_DIR, HIGH);
			pwmWrite (RIGHT_MOTOR, 10000);
			pwmWrite (LEFT_MOTOR, 10000);
			driving = 1;
			break;
		case 'd':
			digitalWrite (RIGHT_DIR, HIGH);
			digitalWrite (LEFT_DIR, LOW);
			pwmWrite (RIGHT_MOTOR, 10000);
			pwmWrite (LEFT_MOTOR, 10000);
			driving = 1;
			break;
		case ' ':
			if (driving) {
				driving = 0;
				pwmWrite (RIGHT_MOTOR, 0);
				pwmWrite (LEFT_MOTOR, 0);
			} else {
				driving = 1;
				pwmWrite (RIGHT_MOTOR, 10000);
				pwmWrite (LEFT_MOTOR, 10000);
			}
		default:
			break;
		}
        }

	/* SerialUSB.println (theta); */
	/* delay (10); */
}
