CGC_BINS=tester

CGC_LDFLAGS += -lcgc -nostdlib -L/usr/lib 
CGC_CFLAGS  += -fno-builtin -I/usr/include

LIBS       = -L/usr/lib -lcgc
LDFLAGS    = -nostdlib -static -lcgc -L/usr/lib

#CC         = /usr/i386-linux-cgc/bin/clang
LD         = /usr/i386-linux-cgc/bin/ld

CC         = ../Release+Asserts/bin/clang

all: $(CGC_BINS) 
	@echo CGC binaries: $(CGC_BINS)

$(CGC_BINS):
	$(CC) $(CGC_CFLAGS) -c $@.c -o $@.o
	$(LD) $(LDFLAGS) $@.o -o $@

test: $(CGC_TESTS)

$(CGC_TESTS):
	python $@.py

clean:
	rm -f $(CGC_BINS) *.o


