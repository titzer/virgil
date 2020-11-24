#define RESET   "\033[0m"
#define RED     "\033[0;31m"
#define GREEN   "\033[0;32m"
#define DEBUG   0

enum output_mode {
    INLINE,
    CHARACTER,
    LINES,
    SUMMARY
};

struct failure {
    char *name;
    char *error;
    int is_dynamic;
};

struct node {
    struct failure *val;
    struct node *next;
} *head, *tail;

static const char CTRL_C = 0x03;
static const char CTRL_D = 0x04;
static const int STDIN = 0;
static const int STDOUT = 1;

// Global state
static enum output_mode mode = CHARACTER;
static int indent = 0;
static int test_count = 0;
static int passed = 0;
static int failed = 0;
static char *current_test;
static char line_buffer[4096];
static int line_end = 0;

int char_backup = 0;

int match_str(char *, char *, int, int);
char *str_slice(char *, int, int);
void process_line();
void report_start();
int report_finish();
void report_test_begin(char *);
void report_test_passed();
void report_test_failed(char *, int);
