#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <termios.h>

static struct termios orig_termios;

void restore_terminal(void) {
    tcsetattr(STDIN_FILENO, TCSAFLUSH, &orig_termios);
}

void setup_raw_mode(void) {
    struct termios raw;

    // Get current terminal settings
    tcgetattr(STDIN_FILENO, &orig_termios);
    atexit(restore_terminal);

    // Modify for raw mode
    raw = orig_termios;
    raw.c_lflag &= ~(ICANON | ECHO);  // Disable canonical mode and echo
    raw.c_cc[VMIN] = 1;   // Return after 1 byte
    raw.c_cc[VTIME] = 0;  // No timeout

    // Apply new settings
    tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw);
}

int main(int argc, char *argv[]) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <program> [args...]\n", argv[0]);
        return 1;
    }

    setup_raw_mode();

    // Execute the target program
    execvp(argv[1], &argv[1]);

    // If exec fails
    perror("execvp");
    return 1;
}
