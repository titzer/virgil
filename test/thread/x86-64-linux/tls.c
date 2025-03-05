#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>

pthread_key_t thread_data_key;

void cleanup_data(void *data) {
    free(data);
}

void *thread_function(void *arg) {
    int *thread_specific_data = (int *)malloc(sizeof(int));
    *thread_specific_data = (int)(long)arg * 10;
    pthread_setspecific(thread_data_key, thread_specific_data);

    printf("Thread %ld: Data = %d\n", (long)arg, *(int *)pthread_getspecific(thread_data_key));
    return NULL;
}

int main() {
    pthread_t threads[5];
    int i;

    pthread_key_create(&thread_data_key, cleanup_data);

    for (i = 0; i < 5; i++) {
        pthread_create(&threads[i], NULL, thread_function, (void *)(long)(i + 1));
    }

    for (i = 0; i < 5; i++) {
        pthread_join(threads[i], NULL);
    }

    pthread_key_delete(thread_data_key);
    return 0;
}
