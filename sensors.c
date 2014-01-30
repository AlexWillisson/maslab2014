#include <stdio.h>
#include <unistd.h>
#include <limits.h>
#include <fcntl.h>

#define DEBUG_VALUES 1

int botfd;
float readings[4];

#include <errno.h>
#include <termios.h>
#include <unistd.h>
#include <string.h>

int
set_interface_attribs (int fd, int speed, int parity)
{
        struct termios tty;
        memset (&tty, 0, sizeof tty);
        if (tcgetattr (fd, &tty) != 0)
        {
                printf ("error %d from tcgetattr", errno);
                return -1;
        }

        cfsetospeed (&tty, speed);
        cfsetispeed (&tty, speed);

        tty.c_cflag = (tty.c_cflag & ~CSIZE) | CS8;     // 8-bit chars
        // disable IGNBRK for mismatched speed tests; otherwise receive break
        // as \000 chars
        tty.c_iflag &= ~IGNBRK;         // ignore break signal
        tty.c_lflag = 0;                // no signaling chars, no echo,
                                        // no canonical processing
        tty.c_oflag = 0;                // no remapping, no delays
        tty.c_cc[VMIN]  = 0;            // read doesn't block
        tty.c_cc[VTIME] = 5;            // 0.5 seconds read timeout

        tty.c_iflag &= ~(IXON | IXOFF | IXANY); // shut off xon/xoff ctrl

        tty.c_cflag |= (CLOCAL | CREAD);// ignore modem controls,
                                        // enable reading
        tty.c_cflag &= ~(PARENB | PARODD);      // shut off parity
        tty.c_cflag |= parity;
        tty.c_cflag &= ~CSTOPB;
        tty.c_cflag &= ~CRTSCTS;

        if (tcsetattr (fd, TCSANOW, &tty) != 0)
        {
                printf ("error %d from tcsetattr", errno);
                return -1;
        }
        return 0;
}

void
set_blocking (int fd, int should_block)
{
        struct termios tty;
        memset (&tty, 0, sizeof tty);
        if (tcgetattr (fd, &tty) != 0)
        {
                printf ("error %d from tggetattr", errno);
                return;
        }

        tty.c_cc[VMIN]  = should_block ? 1 : 0;
        tty.c_cc[VTIME] = 5;            // 0.5 seconds read timeout

        if (tcsetattr (fd, TCSANOW, &tty) != 0)
                printf ("error %d setting term attributes", errno);
}

int
main (int argc, char **argv)
{
	char buf[200], *p0, *p1;
	int x, done;
	float val;
	FILE *f;

	botfd = open ("/dev/ttyACM2", O_RDWR | O_NOCTTY | O_SYNC);

	if (botfd < 0) {
		printf ("bad\n");
		return (1);
	}

	set_interface_attribs (botfd, B9600, 0);
	set_blocking (botfd, 0);

	while (1) {
		read (botfd, buf, 100);

		p0 = buf;
		while (*p0 && *p0 != '\n') {
			p0++;
		}

		if (*p0 == 0) {
			continue;
		}

		p0++;
		p1 = p0;
		
		done = 0;
		while (*p1 && ! done) {
			while (*p1 && *p1 != '\n') {
				p1++;
			}

			if (*p1 == 0) {
				done = 1;
			}

			*p1 = 0;

			sscanf (p0, "us%d: %f", &x, &val);

			switch (x) {
			case 0:
				printf ("%f\n", val);
				readings[0] = val;
				break;
			case 1:
				printf ("%f\n", val);
				readings[1] = val;
				break;
			case 2:
				printf ("%f\n", val);
				readings[2] = val;
				break;
			case 3:
				printf ("%f\n", val);
				readings[3] = val;
				break;
			}

			p1++;
			p0 = p1;
		}

		f = fopen ("ultrasonics", "w");
		fprintf (f, "%f\n%f\n%f\n%f\n", readings[0], readings[1],
			                        readings[2], readings[3]);
		fclose (f);

		/* usleep (5000); */
	}

	return (0);
}
