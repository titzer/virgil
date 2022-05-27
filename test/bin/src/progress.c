#include "progress.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

// Global state
static enum output_mode mode = CHARACTER;
static int indent = 0;
static int test_count = 0;
static int passed = 0;
static int failed = 0;
static char *current_test;
static char *line_buffer = NULL;
static int line_end = 0;
static size_t buf_size = 0;

int char_backup = 0;

void insert(struct failure *f) {
    struct node *node = malloc(sizeof(struct node));
    node->val = f;
    node->next = NULL;

    if (head == NULL) {
        head = node;
        tail = node;
    } else {
        tail->next = node;
        tail = node;
    }
}

void free_list(struct node **head_ref) {
    struct node *tmp;
    struct node *head = *head_ref;
    struct failure *f;
    while (head != NULL) {
        tmp = head;
        head = head->next;
        f = tmp->val;
        free(f->name);
        if (f->is_dynamic)
            free(f->error);
        free(f);
        free(tmp);
    }
}

int main(int argc, char *argv[]) {
    for (int i = 1; i < argc; i++) {
        char *arg = argv[i];
        int len = strlen(arg);
        for (int j = 0; j < len; j++) {
            switch (arg[j]) {
                case 'i':
                    mode = INLINE;
                    break;
                case 'c':
                    mode = CHARACTER;
                    break;
                case 'l':
                    mode = LINES;
                    break;
                case 's':
                    mode = SUMMARY;
                    break;
                case 't':
                    indent++;
                    break;
                default:
                    fprintf(stderr, "Usage: progress [iclst]\n");
                    exit(EXIT_FAILURE);
            }
        }
    }

    if (mode == SUMMARY)
        indent = 0;

    report_start();
    while (getline(&line_buffer, &buf_size, stdin) > 0) {
        line_end = strlen(line_buffer) - 1; // getline reads '\n' as well
        process_line();
    }
    free(line_buffer);
    return report_finish();
}

void process_line() {
    int pos = 3, end = line_end;
    if (line_end < pos)
        return;
    if (line_buffer[0] == '#' && line_buffer[1] == '#') {
        switch (line_buffer[2]) {
            case '+': ;
                // begin the next test
                char *test_name = str_slice(line_buffer, pos, end);
                report_test_begin(test_name);
                break;
            case '-': ;
                // end the current test
                int passed = match_str("ok", line_buffer, pos, end);
                if (passed)
                    report_test_passed();
                else
                    report_test_failed(str_slice(line_buffer, pos, end), 1);
                break;
            case '>': ;
                // increase the total test count
                char *count_str = str_slice(line_buffer, pos, end);
                int count = strtol(count_str, NULL, 10);
                if (count > 0)
                    test_count += count;
                free(count_str);
                break;
        }
    }
    line_end = 0;
}

void outc(char c) {
    printf("%c", c);
    char_backup++;
}

void outi(int i) {
    char_backup += printf("%d", i);
}

void outs(char *str) {
    char_backup += printf("%s", str);
}

void outindent() {
    for (int i = 0; i < indent; i++)
        printf(" ");
}

void outln() {
    printf("\n");
    outindent();
    char_backup = 0;
}

void outsp() {
    outc(' ');
}

void green(char *str) {
    printf(GREEN);
    outs(str);
    printf(RESET);
}

void red(char *str) {
    printf(RED);
    outs(str);
    printf(RESET);
}

void backup(int count) {
    while (count-- > 0)
        printf("\b \b");
}

void clearln() {
    backup(char_backup);
    char_backup = 0;
}

void output_failure(struct failure* f) {
    if (f->name != NULL)
        red(f->name);
    else
        red("<unknown>");
    outs(": ");
    if (f->error != NULL)
        outs(f->error);
    outln();
}

void output_count(int count) {
    outi(count);
    outs(" of ");
    int total = passed + failed;
    if (total < test_count)
        total = test_count;
    outi(total);
}

void output_passed_count() {
    output_count(passed);
    outsp();
    if (passed > 0)
        green("passed");
    else
        outs("passed");
    if (failed > 0) {
        outsp();
        printf(RED);
        outi(failed);
        outs(" failed");
        printf(RESET);
    }
}

void space() {
    int done = passed + failed;
    if (done % 10 == 0) {
        outc(' ');
    }
    if (done % 50 == 0) {
        output_count(done);
        outln();
    }
}

void report_start() {
    if (mode != INLINE)
        outindent();
    if (mode == SUMMARY)
        outs("##+\n");
}

void report_test_begin(char *name) {
    if (current_test != NULL)
        report_test_failed("unterminated test case", 0);
    current_test = name;
    switch (mode) {
        case LINES:
            outs(name);
            outs("...");
            fflush(stdout);
            break;
        case INLINE:
            clearln();
            output_passed_count();
            outs(" | ");
            outs(name);
            fflush(stdout);
            break;
        default: ;
    }
}

void report_test_passed() {
    passed++;
    free(current_test);
    current_test = NULL;
    switch (mode) {
        case INLINE:
            clearln();
            output_passed_count();
            outs(" | ");
            fflush(stdout);
            break;
        case CHARACTER:
            green("o");
            space();
            fflush(stdout);
            break;
        case LINES:
            green("ok");
            outln();
            fflush(stdout);
            break;
        case SUMMARY: ;
    }
}

void report_test_failed(char *error, int is_dynamic) {
    failed++;

    struct failure *f = malloc(sizeof(struct failure));
    f->name = current_test;
    f->error = error;
    f->is_dynamic = is_dynamic;
    insert(f);

    current_test = NULL;
    switch (mode) {
        case INLINE:
            clearln();
            if (failed == 1)
                outln();
            output_failure(f);
            fflush(stdout);
            break;
        case CHARACTER:
            red("X");
            space();
            fflush(stdout);
            break;
        case LINES:
            red("failed");
            outln();
            fflush(stdout);
            break;
        case SUMMARY: ;
    }
}

int report_finish() {
    if (current_test != NULL)
        report_test_failed("abrupt output end", 0);

    int ok = (head == NULL) && (failed == 0);
    switch (mode) {
        case INLINE:
            clearln();
            output_passed_count();
            printf("\n");
            break;
        case SUMMARY:
            if (ok)
                outs("##-ok\n");
            else {
                outs("##-fail ");
                outi(failed);
                outs(" failed\n");
            }
            break;
        default:
            if (mode == CHARACTER) {
                int done = passed + failed;
                if (done % 50 != 0) {
                    if (done % 10 != 0)
                        outsp();
                    output_count(done);
                    outln();
                }
            }
            struct node *current = head;
            while (current != NULL) {
                output_failure(current->val);
                current = current->next;
            }
            output_passed_count();
            printf("\n");
    }
    fflush(stdout);
    if (head != NULL)
        free_list(&head);
    return ok ? EXIT_SUCCESS : EXIT_FAILURE;
}

char *str_slice(char *arr, int start, int end) {
    char *n = malloc(sizeof(char) * (end - start) + 1);
    if (n == NULL)
        exit(EXIT_FAILURE);
    for (int i = start; i < end; i++)
        n[i - start] = arr[i];
    n[end - start] = '\00';
    return n;
}

int match_str(char *exp, char *arr, int pos, int end) {
    int len = strlen(exp);
    if ((pos + len) > end)
        return 0;
    for (int i = 0; i < len; i++) {
        if (exp[i] != arr[pos + i])
            return 0;
    }
    return 1;
}
