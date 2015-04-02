CC=g++
CFLAGS=-ggdb -c -Wall
LDFLAGS=
SOURCES=hello-world.cpp
OBJECTS=$(SOURCES:.cpp=.o)
EXECUTABLE=a.out

all: $(SOURCES) $(EXECUTABLE)

$(EXECUTABLE): $(OBJECTS)
	$(CC) $(LDFLAGS) $(OBJECTS) -o $@

.cpp.o:
	$(CC) $(CFLAGS) $< -o $@

run: all
	./a.out

clean:
	rm -f a.out *.o
