CFLAGS = -g -Wall `pkg-config --cflags opencv`
LIBS = `pkg-config --libs opencv`

all: cvcu

cvcu: cvcu.o
	$(CC) $(CFLAGS) -o cvcu cvcu.o $(LIBS)

clean:
	rm -f *.o cvcu
