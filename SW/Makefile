CC=gcc
CFLAGS=-g -Wall
OBJS=inf.o
TARGET=inf.out

all: $(TARGET) $(TARGET)

clean: 
	rm -f *.o
	rm -f $(TARGET)

$(TARGET): $(OBJS)
	$(CC) -o $@ $(OBJS)
