CFLAGS = -g -Wall `pkg-config --cflags opencv`
LIBS = `pkg-config --libs opencv`

all: balltrack sensors

sensors: sensors.o
	$(CC) $(CFLAGS) -o sensors sensors.o $(LIBS)

balltrack: balltrack.o
	$(CC) $(CFLAGS) -o balltrack balltrack.o $(LIBS)

clean:
	rm -f *.o balltrack
