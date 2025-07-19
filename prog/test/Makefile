#===================================================================================================
# config
#---------------------------------------------------------------------------------------------------
target              := test

#===================================================================================================
# sources
#---------------------------------------------------------------------------------------------------
srcs-to-objs         = $(patsubst %.s,%.o,$(filter %.s,$1)) \
                       $(patsubst %.S,%.o,$(filter %.S,$1)) \
                       $(patsubst %.c,%.o,$(filter %.c,$1))

srcs-to-deps         = $(patsubst %.s,%.d,$(filter %.s,$1)) \
                       $(patsubst %.S,%.d,$(filter %.S,$1)) \
                       $(patsubst %.c,%.d,$(filter %.c,$1))

src_dir             := .
srcs                := $(wildcard $(addprefix $(src_dir)/,*.s *.S *.c))
objs                := $(call srcs-to-objs,$(srcs))
deps                := $(call srcs-to-deps,$(srcs))

#===================================================================================================
# RISC-V
#---------------------------------------------------------------------------------------------------
XLEN                ?= 64
RISCV_ARCH          ?= rv$(XLEN)i_zicntr_zicsr_zifencei
RISCV_ABI           ?= $(if $(filter 64,$(XLEN)),lp64,ilp32)

-include config.mk

ifeq ($(RISCV),)
$(error Set the RISC-V environment variables.)
endif

RISCV_PREFIX        := $(RISCV)/bin/riscv$(XLEN)-unknown-elf-
RISCV_GCC           := $(RISCV_PREFIX)gcc
RISCV_OBJCOPY       := $(RISCV_PREFIX)objcopy
RISCV_OBJDUMP       := $(RISCV_PREFIX)objdump

RISCV_CPPFLAGS      += -MMD
RISCV_CFLAGS        += -O2 -march=$(RISCV_ARCH) -mabi=$(RISCV_ABI) -nostartfiles
RISCV_LDFLAGS       += -Tlink.ld

#===================================================================================================
# build rules
#---------------------------------------------------------------------------------------------------
.PHONY: default clean
default: $(objs) $(addprefix $(target),.elf .bin .32.mem .64.mem .128.mem .dump)

%.dump: %.elf
	$(RISCV_OBJDUMP) -d $< > $@

%.128.mem: %.64.mem
	awk '{if (NR % 2) { line = $$1 } else { print $$1 line }}' $< > $@

%.64.mem: %.bin
	od -v -An -t x8 -w8 $< | sed 's/^ \+//' > $@

%.32.mem: %.bin
	od -v -An -t x4 -w4 $< | sed 's/^ \+//' > $@

%.bin: %.elf
	$(RISCV_OBJCOPY) -O binary $< $@

%.elf: $(objs)
	$(RISCV_GCC) $(RISCV_CFLAGS) $(RISCV_LDFLAGS) -o $@ $^

%.o: %.s
	$(RISCV_GCC) $(RISCV_CPPFLAGS) $(RISCV_CFLAGS) -c -o $@ $<

%.o: %.c
	$(RISCV_GCC) $(RISCV_CPPFLAGS) $(RISCV_CFLAGS) -c -o $@ $<

clean:
	rm -f *.o *.d *.elf *.bin *.mem *.dump

-include $(deps)
