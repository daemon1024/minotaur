ifeq (,$(KRNDIR))
KRNVER = $(shell uname -r)
KRNDIR = /usr/src/linux-headers-$(KRNVER)
endif
LIBBPF = $(CURDIR)/libbpf

BIN = $(CURDIR)
CL  = clang
CC  = gcc
Q   = @

ifeq ($(V),1)
  Q =
endif



# shamelessly copied from kernel's samples/bpf/Makefile
KF = -nostdinc -isystem /usr/lib/gcc/x86_64-linux-gnu/7/include \
	 -I$(KRNDIR)/arch/x86/include -I$(KRNDIR)/arch/x86/include/generated  \
	 -I$(KRNDIR)/include -I$(KRNDIR)/arch/x86/include/uapi \
	 -I$(KRNDIR)/arch/x86/include/generated/uapi -I$(KRNDIR)/include/uapi \
	 -I$(KRNDIR)/include/generated/uapi \
	 -I$(LIBBPF)/src \
	 -include $(KRNDIR)/include/linux/kconfig.h \
	 -I/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/include \
	 -Isrc \
	 -D__KERNEL__ -D__BPF_TRACING__ -Wno-unused-value -Wno-pointer-sign \
	 -D__TARGET_ARCH_x86 -Wno-compare-distinct-pointer-types \
	 -Wno-gnu-variable-sized-type-not-at-end \
	 -Wno-address-of-packed-member -Wno-tautological-compare \
	 -Wno-unknown-warning-option  \
	 -fno-stack-protector \
	 -O2 -emit-llvm

# Fix alpine hardcoding

SRCDIR=$(CURDIR)

SRCS_KERN:=$(wildcard $(SRCDIR)/*.c)
SRCN:=$(notdir $(SRCS_KERN))
BOBJS:=$(patsubst %.c,$(BIN)/%.bpf.o,$(SRCN))

vpath %.c $(SRCDIR)

RED=\033[0;31m
GREEN=\033[0;32m
CYAN=\033[0;36m
NC=\033[0m

.PHONY: all
all: chkdir $(BOBJS)

.PHONY: chkdir
chkdir:
ifeq (,$(wildcard $(KRNDIR)/Kconfig))
	@echo "Your kernel path[$(RED)$(KRNDIR)$(NC)] is incorrect. Use 'make KRNDIR=[KERNEL-SRC-PATH]'."
	Quitting abnormally
endif
ifeq (,$(wildcard $(LIBBPF)/src/libbpf.a))
	make -C $(LIBBPF)/src
endif

$(BIN)/%.bpf.o: %.c
	@echo "Compiling eBPF bytecode: $(GREEN)$@$(NC) ..."
	$(CL) $(KF) -c $< -o -| llc -march=bpf -mcpu=probe -filetype=obj -o $@
#   $(CL) -target bpf $(KF) -c $< -o $@


.PHONY: clean
clean:
	@rm -rf $(BIN)
