#include <stdlib.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>

struct stat statbuf;


#define PRINT_OFFSET(name) printf(#name " = %d\n", (int)(((char*)&(statbuf.name)) - (char*)&statbuf));

int main(int argc, char* argv[]) {

  printf("sizeof(statbuf) = %d\n", (int)sizeof(statbuf)); 
  
  PRINT_OFFSET(st_dev);
  PRINT_OFFSET(st_ino);
  PRINT_OFFSET(st_mode);
  PRINT_OFFSET(st_nlink);
  PRINT_OFFSET(st_uid);
  PRINT_OFFSET(st_gid);
  PRINT_OFFSET(st_rdev);
  PRINT_OFFSET(st_size);
  PRINT_OFFSET(st_blksize);
  PRINT_OFFSET(st_blocks);
  PRINT_OFFSET(st_atim);
  PRINT_OFFSET(st_mtim);
  PRINT_OFFSET(st_ctim);

  printf("\n");
  return 0;
}
