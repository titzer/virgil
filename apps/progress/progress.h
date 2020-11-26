#define RESET "\033[0m"
#define RED "\033[0;31m"
#define GREEN "\033[0;32m"
#define BUF_SIZE 4096
#define DEBUG 0

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

int match_str(char *, char *, int, int);
char *str_slice(char *, int, int);
void process_line();
void report_start();
int report_finish();
void report_test_begin(char *);
void report_test_passed();
void report_test_failed(char *, int);
