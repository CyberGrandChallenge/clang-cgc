// RUN: %clangxx_msan -m64 -O0 %s -o %t && %t 2>&1
// RUN: %clangxx_msan -m64 -O3 %s -o %t && %t 2>&1

#include <assert.h>
#include <errno.h>
#include <glob.h>
#include <stdio.h>
#include <string.h>

#include <linux/aio_abi.h>
#include <sys/ptrace.h>
#include <sys/stat.h>

#include <sanitizer/linux_syscall_hooks.h>
#include <sanitizer/msan_interface.h>

/* Test the presence of __sanitizer_syscall_ in the tool runtime, and general
   sanity of their behaviour. */

int main(int argc, char *argv[]) {
  char buf[1000];
  const int kTen = 10;
  const int kFortyTwo = 42;
  memset(buf, 0, sizeof(buf));
  __msan_unpoison(buf, sizeof(buf));
  __sanitizer_syscall_pre_recvmsg(0, buf, 0);
  __sanitizer_syscall_pre_rt_sigpending(buf, kTen);
  __sanitizer_syscall_pre_getdents(0, buf, kTen);
  __sanitizer_syscall_pre_getdents64(0, buf, kTen);

  __msan_unpoison(buf, sizeof(buf));
  __sanitizer_syscall_post_recvmsg(0, 0, buf, 0);
  __sanitizer_syscall_post_rt_sigpending(-1, buf, kTen);
  __sanitizer_syscall_post_getdents(0, 0, buf, kTen);
  __sanitizer_syscall_post_getdents64(0, 0, buf, kTen);
  assert(__msan_test_shadow(buf, sizeof(buf)) == -1);

  __msan_unpoison(buf, sizeof(buf));
  __sanitizer_syscall_post_recvmsg(kTen, 0, buf, 0);

  // Tell the kernel that the output struct size is 10 bytes, verify that those
  // bytes are unpoisoned, and the next byte is not.
  __msan_poison(buf, kTen + 1);
  __sanitizer_syscall_post_rt_sigpending(0, buf, kTen);
  assert(__msan_test_shadow(buf, sizeof(buf)) == kTen);

  __msan_poison(buf, kTen + 1);
  __sanitizer_syscall_post_getdents(kTen, 0, buf, kTen);
  assert(__msan_test_shadow(buf, sizeof(buf)) == kTen);

  __msan_poison(buf, kTen + 1);
  __sanitizer_syscall_post_getdents64(kTen, 0, buf, kTen);
  assert(__msan_test_shadow(buf, sizeof(buf)) == kTen);

  __msan_poison(buf, sizeof(buf));
  __sanitizer_syscall_post_clock_getres(0, 0, buf);
  assert(__msan_test_shadow(buf, sizeof(buf)) == sizeof(long) * 2);

  __msan_poison(buf, sizeof(buf));
  __sanitizer_syscall_post_clock_gettime(0, 0, buf);
  assert(__msan_test_shadow(buf, sizeof(buf)) == sizeof(long) * 2);

  // Failed syscall does not write to the buffer.
  __msan_poison(buf, sizeof(buf));
  __sanitizer_syscall_post_clock_gettime(-1, 0, buf);
  assert(__msan_test_shadow(buf, sizeof(buf)) == 0);

  __msan_poison(buf, sizeof(buf));
  __sanitizer_syscall_post_read(5, 42, buf, 10);
  assert(__msan_test_shadow(buf, sizeof(buf)) == 5);

  __msan_poison(buf, sizeof(buf));
  __sanitizer_syscall_post_newfstatat(0, 5, "/path/to/file", buf, 0);
  assert(__msan_test_shadow(buf, sizeof(buf)) == sizeof(struct stat));

  __msan_poison(buf, sizeof(buf));
  int prio = 0;
  __sanitizer_syscall_post_mq_timedreceive(kFortyTwo, 5, buf, sizeof(buf), &prio, 0);
  assert(__msan_test_shadow(buf, sizeof(buf)) == kFortyTwo);
  assert(__msan_test_shadow(&prio, sizeof(prio)) == -1);

  __msan_poison(buf, sizeof(buf));
  __sanitizer_syscall_post_ptrace(0, PTRACE_PEEKUSER, kFortyTwo, 0xABCD, buf);
  assert(__msan_test_shadow(buf, sizeof(buf)) == sizeof(void *));

  __msan_poison(buf, sizeof(buf));
  struct iocb iocb[2];
  struct iocb *iocbp[2] = { &iocb[0], &iocb[1] };
  memset(iocb, 0, sizeof(iocb));
  iocb[0].aio_lio_opcode = IOCB_CMD_PREAD;
  iocb[0].aio_buf = (__u64)buf;
  iocb[0].aio_nbytes = kFortyTwo;
  iocb[1].aio_lio_opcode = IOCB_CMD_PREAD;
  iocb[1].aio_buf = (__u64)(&buf[kFortyTwo]);
  iocb[1].aio_nbytes = kFortyTwo;
  __sanitizer_syscall_post_io_submit(1, 0, 2, &iocbp);
  assert(__msan_test_shadow(buf, sizeof(buf)) == kFortyTwo);
  
  return 0;
}
