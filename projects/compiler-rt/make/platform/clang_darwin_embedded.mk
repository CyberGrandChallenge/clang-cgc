# These are the functions which clang needs when it is targetting a previous
# version of the OS. The issue is that the backend may use functions which were
# not present in the libgcc that shipped on the platform. In such cases, we link
# with a version of the library which contains private_extern definitions of all
# the extra functions which might be referenced.

Description := Static runtime libraries for embedded clang/Darwin

XCRun = \
  $(shell \
    result=`xcrun -find $(1) 2> /dev/null`; \
    if [ "$$?" != "0" ]; then result=$(1); fi; \
    echo $$result)

###

CC       := $(call XCRun,clang)
AR       := $(call XCRun,ar)
RANLIB   := $(call XCRun,ranlib)
STRIP    := $(call XCRun,strip)
LIPO     := $(call XCRun,lipo)
DSYMUTIL := $(call XCRun,dsymutil)

Configs :=
UniversalArchs :=

# Soft-float version of the runtime. No floating-point instructions will be used
# and the ABI (out of necessity) passes floating values in normal registers:
# non-VFP variant of the AAPCS.
Configs += soft_static
UniversalArchs.soft_static := armv6m armv7m armv7em armv7

# Hard-float version of the runtime. On ARM VFP instructions and registers are
# allowed, and floating point values get passed in them. VFP variant of the
# AAPCS.
Configs += hard_static
UniversalArchs.hard_static := armv7em armv7 i386 x86_64

Configs += soft_pic
UniversalArchs.soft_pic := armv6m armv7m armv7em armv7

Configs += hard_pic
UniversalArchs.hard_pic := armv7em armv7 i386 x86_64

CFLAGS := -Wall -Werror -Oz -fomit-frame-pointer -ffreestanding

PIC_CFLAGS := -fPIC
STATIC_CFLAGS := -static

CFLAGS_SOFT := -mfloat-abi=soft
CFLAGS_HARD := -mfloat-abi=hard

CFLAGS_ARMV7 := -target thumbv7-apple-darwin-eabi
CFLAGS_I386  := -march=pentium

CFLAGS.soft_static := $(CFLAGS) $(STATIC_CFLAGS) $(CFLAGS_SOFT)
CFLAGS.hard_static := $(CFLAGS) $(STATIC_CFLAGS) $(CFLAGS_HARD)
CFLAGS.soft_pic    := $(CFLAGS) $(PIC_CFLAGS) $(CFLAGS_SOFT)
CFLAGS.hard_pic    := $(CFLAGS) $(PIC_CFLAGS) $(CFLAGS_HARD)

CFLAGS.soft_static.armv7 := $(CFLAGS.soft_static) $(CFLAGS_ARMV7)
CFLAGS.hard_static.armv7 := $(CFLAGS.hard_static) $(CFLAGS_ARMV7)
CFLAGS.soft_pic.armv7    := $(CFLAGS.soft_pic) $(CFLAGS_ARMV7)
CFLAGS.hard_pic.armv7    := $(CFLAGS.hard_pic) $(CFLAGS_ARMV7)

# x86 platforms ignore -mfloat-abi options and complain about doing so. Despite
# this they're hard-float.
CFLAGS.hard_static.i386   := $(CFLAGS) $(STATIC_CFLAGS) $(CFLAGS_I386)
CFLAGS.hard_pic.i386      := $(CFLAGS) $(PIC_CFLAGS) $(CFLAGS_I386)
CFLAGS.hard_static.x86_64 := $(CFLAGS) $(STATIC_CFLAGS)
CFLAGS.hard_pic.x86_64    := $(CFLAGS) $(PIC_CFLAGS)

# Functions not wanted:
#   + eprintf is obsolete anyway
#   + *vfp: designed for Thumb1 CPUs with VFPv2

COMMON_FUNCTIONS := \
	absvdi2 \
	absvsi2 \
	addvdi3 \
	addvsi3 \
	ashldi3 \
	ashrdi3 \
	bswapdi2 \
	bswapsi2 \
	clzdi2 \
	clzsi2 \
	cmpdi2 \
	ctzdi2 \
	ctzsi2 \
	divdc3 \
	divdi3 \
	divsc3 \
	divmodsi4 \
	udivmodsi4 \
	do_global_dtors \
	ffsdi2 \
	fixdfdi \
	fixsfdi \
	fixunsdfdi \
	fixunsdfsi \
	fixunssfdi \
	fixunssfsi \
	floatdidf \
	floatdisf \
	floatundidf \
	floatundisf \
	gcc_bcmp \
	lshrdi3 \
	moddi3 \
	muldc3 \
	muldi3 \
	mulsc3 \
	mulvdi3 \
	mulvsi3 \
	negdi2 \
	negvdi2 \
	negvsi2 \
	paritydi2 \
	paritysi2 \
	popcountdi2 \
	popcountsi2 \
	powidf2 \
	powisf2 \
	subvdi3 \
	subvsi3 \
	ucmpdi2 \
	udiv_w_sdiv \
	udivdi3 \
	udivmoddi4 \
	umoddi3 \
	adddf3 \
	addsf3 \
	cmpdf2 \
	cmpsf2 \
	div0 \
	divdf3 \
	divsf3 \
	divsi3 \
	extendsfdf2 \
	ffssi2 \
	fixdfsi \
	fixsfsi \
	floatsidf \
	floatsisf \
	floatunsidf \
	floatunsisf \
	comparedf2 \
	comparesf2 \
	modsi3 \
	muldf3 \
	mulsf3 \
	negdf2 \
	negsf2 \
	subdf3 \
	subsf3 \
	truncdfsf2 \
	udivsi3 \
	umodsi3 \
	unorddf2 \
	unordsf2

ARM_FUNCTIONS := \
	aeabi_cdcmpeq \
	aeabi_cdrcmple \
	aeabi_cfcmpeq \
	aeabi_cfrcmple \
	aeabi_dcmpeq \
	aeabi_dcmpge \
	aeabi_dcmpgt \
	aeabi_dcmple \
	aeabi_dcmplt \
	aeabi_drsub \
	aeabi_fcmpeq \
	aeabi_fcmpge \
	aeabi_fcmpgt \
	aeabi_fcmple \
	aeabi_fcmplt \
	aeabi_frsub \
	aeabi_idivmod \
	aeabi_uidivmod \

# ARM Assembly implementation which requires Thumb2 (i.e. won't work on v6M).
THUMB2_FUNCTIONS := \
	switch16 \
	switch32 \
	switch8 \
	switchu8 \

I386_FUNCTIONS :=  \
	i686.get_pc_thunk.eax \
	i686.get_pc_thunk.ebp \
	i686.get_pc_thunk.ebx \
	i686.get_pc_thunk.ecx \
	i686.get_pc_thunk.edi \
	i686.get_pc_thunk.edx \
	i686.get_pc_thunk.esi

# FIXME: Currently, compiler-rt is missing implementations for a number of the
# functions. Filter them out for now.
MISSING_FUNCTIONS := \
	cmpdf2 cmpsf2 div0 \
	ffssi2 \
	udiv_w_sdiv unorddf2 unordsf2 bswapdi2 \
	bswapsi2 \
	gcc_bcmp \
	do_global_dtors \
	i686.get_pc_thunk.eax i686.get_pc_thunk.ebp i686.get_pc_thunk.ebx \
	i686.get_pc_thunk.ecx i686.get_pc_thunk.edi i686.get_pc_thunk.edx \
	i686.get_pc_thunk.esi \
	aeabi_cdcmpeq aeabi_cdrcmple aeabi_cfcmpeq aeabi_cfrcmple aeabi_dcmpeq \
	aeabi_dcmpge aeabi_dcmpgt aeabi_dcmple aeabi_dcmplt aeabi_drsub \
	aeabi_fcmpeq \ aeabi_fcmpge aeabi_fcmpgt aeabi_fcmple aeabi_fcmplt \
	aeabi_frsub aeabi_idivmod aeabi_uidivmod

FUNCTIONS_ARMV6M  := $(COMMON_FUNCTIONS) $(ARM_FUNCTIONS)
FUNCTIONS_ARM_ALL := $(COMMON_FUNCTIONS) $(ARM_FUNCTIONS) $(THUMB2_FUNCTIONS)
FUNCTIONS_I386    := $(COMMON_FUNCTIONS) $(I386_FUNCTIONS)
FUNCTIONS_X86_64  := $(COMMON_FUNCTIONS)

FUNCTIONS_ARMV6M := \
	$(filter-out $(MISSING_FUNCTIONS),$(FUNCTIONS_ARMV6M))
FUNCTIONS_ARM_ALL := \
	$(filter-out $(MISSING_FUNCTIONS),$(FUNCTIONS_ARM_ALL))
FUNCTIONS_I386 := \
	$(filter-out $(MISSING_FUNCTIONS),$(FUNCTIONS_I386))
FUNCTIONS_X86_64 := \
	$(filter-out $(MISSING_FUNCTIONS),$(FUNCTIONS_X86_64))

FUNCTIONS.soft_static.armv6m := $(FUNCTIONS_ARMV6M)
FUNCTIONS.soft_pic.armv6m    := $(FUNCTIONS_ARMV6M)

FUNCTIONS.soft_static.armv7m := $(FUNCTIONS_ARM_ALL)
FUNCTIONS.soft_pic.armv7m    := $(FUNCTIONS_ARM_ALL)

FUNCTIONS.soft_static.armv7em := $(FUNCTIONS_ARM_ALL)
FUNCTIONS.hard_static.armv7em := $(FUNCTIONS_ARM_ALL)
FUNCTIONS.soft_pic.armv7em    := $(FUNCTIONS_ARM_ALL)
FUNCTIONS.hard_pic.armv7em    := $(FUNCTIONS_ARM_ALL)

FUNCTIONS.soft_static.armv7 := $(FUNCTIONS_ARM_ALL)
FUNCTIONS.hard_static.armv7 := $(FUNCTIONS_ARM_ALL)
FUNCTIONS.soft_pic.armv7    := $(FUNCTIONS_ARM_ALL)
FUNCTIONS.hard_pic.armv7    := $(FUNCTIONS_ARM_ALL)

FUNCTIONS.hard_static.i386 := $(FUNCTIONS_I386)
FUNCTIONS.hard_pic.i386    := $(FUNCTIONS_I386)

FUNCTIONS.hard_static.x86_64 := $(FUNCTIONS_X86_64)
FUNCTIONS.hard_pic.x86_64    := $(FUNCTIONS_X86_64)
