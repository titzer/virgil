#include<pthread.h>
#include<stdio.h>
// a simple pthread example 
// compile with -lpthreads

// create the function to be executed as a thread
void *thread(void *ptr)
{
    int type = (int) ptr;
    fprintf(stderr,"Thread - %d\n",type);
    return  ptr;
}

int main(int argc, char **argv)
{
    // create the thread objs
    pthread_t thread1, thread2;
    int thr = 1;
    int thr2 = 2;
    // start the threads
    pthread_create(&thread1, NULL, *thread, (void *) thr);
    pthread_create(&thread2, NULL, *thread, (void *) thr2);
    // wait for threads to finish
    pthread_join(thread1,NULL);
    pthread_join(thread2,NULL);
    return 0;
}
