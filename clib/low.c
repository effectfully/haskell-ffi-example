#include <stdlib.h>
#include <stdio.h>

int* new_array (int size) {
  int* arr = calloc (size, sizeof (int));
  printf ("allocated an array\n");
  return arr;
}

void free_array (int* arr) {
  free(arr);
  printf ("freed an array\n");
  return;
}
