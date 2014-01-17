// -*- c -*-

#define RIGHT_MOTOR 14
#define LEFT_MOTOR 3
#define RIGHT_DIR 13
#define LEFT_DIR 4
#define SPEED 20000

#define ROT_THRESH 1

int driving;

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
}

void
loop (void)
{
        int idx, avail, c;

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
}
