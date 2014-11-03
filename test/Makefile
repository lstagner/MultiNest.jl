.PHONY : clean

CFLAGS = -fPIC
LDFLAGS = -shared

ifeq ($(shell uname), Darwin)
TARGET = libmultinest.dylib
else
TARGET = libmultinest.so
endif

all: $(TARGET)

clean:
	rm -f $(TARGET) libmultinest-mock.o

$(TARGET): libmultinest-mock.c
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ libmultinest-mock.c
