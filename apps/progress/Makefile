CC = gcc
CFLAGS = $(WARNFLAGS) $(PIEFLAGS) $(OPT)
OPT = -march=native -O2
WARNFLAGS = -Wall -Werror=format-security -Werror=implicit-function-declaration
PIEFLAGS = -fpie -Wl,-pie
DEBUGFLAGS = -g -fsanitize=address,undefined

.PHONY: all progress clean debug
all: progress

progress: progress.c
	$(CC) $(CFLAGS) -o $@ $<

debug: progress.c
	sed -i 's/DEBUG 0/DEBUG 1/' progress.h
	$(CC) $(CFLAGS) $(DEBUGFLAGS) -o progress $<
	sed -i 's/DEBUG 1/DEBUG 0/' progress.h

clean:
	rm -rf progress
