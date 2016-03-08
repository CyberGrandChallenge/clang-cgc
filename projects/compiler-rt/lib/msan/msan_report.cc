//===-- msan_report.cc ----------------------------------------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file is a part of MemorySanitizer.
//
// Error reporting.
//===----------------------------------------------------------------------===//

#include "msan.h"
#include "sanitizer_common/sanitizer_allocator_internal.h"
#include "sanitizer_common/sanitizer_common.h"
#include "sanitizer_common/sanitizer_flags.h"
#include "sanitizer_common/sanitizer_mutex.h"
#include "sanitizer_common/sanitizer_report_decorator.h"
#include "sanitizer_common/sanitizer_stackdepot.h"
#include "sanitizer_common/sanitizer_symbolizer.h"

using namespace __sanitizer;

namespace __msan {

class Decorator: private __sanitizer::AnsiColorDecorator {
 public:
  Decorator() : __sanitizer::AnsiColorDecorator(PrintsToTtyCached()) { }
  const char *Warning()    { return Red(); }
  const char *Origin()     { return Magenta(); }
  const char *Name()   { return Green(); }
  const char *End()    { return Default(); }
};

static void DescribeOrigin(u32 origin) {
  Decorator d;
  if (common_flags()->verbosity)
    Printf("  raw origin id: %d\n", origin);
  uptr pc;
  if (const char *so = GetOriginDescrIfStack(origin, &pc)) {
    char* s = internal_strdup(so);
    char* sep = internal_strchr(s, '@');
    CHECK(sep);
    *sep = '\0';
    Printf("%s", d.Origin());
    Printf("  %sUninitialized value was created by an allocation of '%s%s%s'"
           " in the stack frame of function '%s%s%s'%s\n",
           d.Origin(), d.Name(), s, d.Origin(), d.Name(),
           Symbolizer::Get()->Demangle(sep + 1), d.Origin(), d.End());
    InternalFree(s);

    if (pc) {
      // For some reason function address in LLVM IR is 1 less then the address
      // of the first instruction.
      pc += 1;
      StackTrace::PrintStack(&pc, 1);
    }
  } else {
    uptr size = 0;
    const uptr *trace = StackDepotGet(origin, &size);
    Printf("  %sUninitialized value was created by a heap allocation%s\n",
           d.Origin(), d.End());
    StackTrace::PrintStack(trace, size);
  }
}

void ReportUMR(StackTrace *stack, u32 origin) {
  if (!__msan::flags()->report_umrs) return;

  SpinMutexLock l(&CommonSanitizerReportMutex);

  Decorator d;
  Printf("%s", d.Warning());
  Report(" WARNING: MemorySanitizer: use-of-uninitialized-value\n");
  Printf("%s", d.End());
  StackTrace::PrintStack(stack->trace, stack->size);
  if (origin) {
    DescribeOrigin(origin);
  }
  ReportErrorSummary("use-of-uninitialized-value", stack);
}

void ReportExpectedUMRNotFound(StackTrace *stack) {
  SpinMutexLock l(&CommonSanitizerReportMutex);

  Printf(" WARNING: Expected use of uninitialized value not found\n");
  StackTrace::PrintStack(stack->trace, stack->size);
}

void ReportAtExitStatistics() {
  SpinMutexLock l(&CommonSanitizerReportMutex);

  Decorator d;
  Printf("%s", d.Warning());
  Printf("MemorySanitizer: %d warnings reported.\n", msan_report_count);
  Printf("%s", d.End());
}

}  // namespace __msan
