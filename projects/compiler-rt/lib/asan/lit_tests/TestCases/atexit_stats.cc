// Make sure we report atexit stats.
// RUN: %clangxx_asan -O3 %s -o %t
// RUN: ASAN_OPTIONS=atexit=1:print_stats=1 %t 2>&1 | FileCheck %s
#include <stdlib.h>
#if !defined(__APPLE__)
#include <malloc.h>
#endif
int *p1 = (int*)malloc(900);
int *p2 = (int*)malloc(90000);
int *p3 = (int*)malloc(9000000);
int main() { }

// CHECK: AddressSanitizer exit stats:
