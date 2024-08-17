CC=gcc
CFLAGS=-g -Wall
OBJS=test.o
TARGET=test.out

all: $(TARGET) $(TARGET)

clean: 
	rm -f *.o
	rm -f $(TARGET)

$(TARGET): $(OBJS)
	$(CC) -o $@ $(OBJS)
