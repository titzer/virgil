CC = gcc
CFLAGS = $(WARNFLAGS) $(PIEFLAGS) $(OPT)
OPT = -O2
WARNFLAGS = -Wall -Werror=format-security -Werror=implicit-function-declaration
PIEFLAGS = -fpie -Wl,-pie
DEBUGFLAGS = -DDEBUG -g -fsanitize=address,undefined

.PHONY: all progress clean debug
all: progress

progress: progress.c
	$(CC) $(CFLAGS) -o $@ $<

debug: progress.c
	$(CC) $(CFLAGS) $(DEBUGFLAGS) -o progress $<

clean:
	rm -rf progress
