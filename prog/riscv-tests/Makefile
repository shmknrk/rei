#=======================================================================
# Makefile for riscv-tests/isa
#-----------------------------------------------------------------------

XLEN                ?= 64

src_dir             := riscv-tests/isa

ifeq ($(XLEN),64)
include $(src_dir)/rv64ui/Makefrag
include $(src_dir)/rv64uc/Makefrag
include $(src_dir)/rv64um/Makefrag
include $(src_dir)/rv64ua/Makefrag
include $(src_dir)/rv64uf/Makefrag
include $(src_dir)/rv64ud/Makefrag
include $(src_dir)/rv64uziccid/Makefrag
include $(src_dir)/rv64uzfh/Makefrag
include $(src_dir)/rv64uzba/Makefrag
include $(src_dir)/rv64uzbb/Makefrag
include $(src_dir)/rv64uzbc/Makefrag
include $(src_dir)/rv64uzbs/Makefrag
include $(src_dir)/rv64si/Makefrag
include $(src_dir)/rv64ssvnapot/Makefrag
include $(src_dir)/rv64mi/Makefrag
include $(src_dir)/rv64mzicbo/Makefrag
include $(src_dir)/hypervisor/Makefrag
endif
include $(src_dir)/rv32ui/Makefrag
include $(src_dir)/rv32uc/Makefrag
include $(src_dir)/rv32um/Makefrag
include $(src_dir)/rv32ua/Makefrag
include $(src_dir)/rv32uf/Makefrag
include $(src_dir)/rv32ud/Makefrag
include $(src_dir)/rv32uzfh/Makefrag
include $(src_dir)/rv32uzba/Makefrag
include $(src_dir)/rv32uzbb/Makefrag
include $(src_dir)/rv32uzbc/Makefrag
include $(src_dir)/rv32uzbs/Makefrag
include $(src_dir)/rv32si/Makefrag
include $(src_dir)/rv32mi/Makefrag

default: rv64ui

#--------------------------------------------------------------------
# Build rules
#--------------------------------------------------------------------

RISCV_PREFIX        ?= riscv$(XLEN)-unknown-elf-
RISCV_GCC           ?= $(RISCV_PREFIX)gcc
RISCV_GCC_OPTS      ?= -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles
RISCV_OBJDUMP       ?= $(RISCV_PREFIX)objdump --disassemble-all --disassemble-zeroes --section=.text --section=.text.startup --section=.text.init --section=.data
RISCV_OBJCOPY       ?= $(RISCV_PREFIX)objcopy
RISCV_SIM           ?= spike

#------------------------------------------------------------
# Build assembly tests

%.dump: %.elf
	$(RISCV_OBJDUMP) $< > $@

%.128.mem: %.64.mem
	awk '{if (NR % 2) { line = $$1 } else { print $$1 line }} END {if (NR % 2) { print "0000000000000000" line }}' $< > $@

%.64.mem: %.bin
	od -v -An -tx8 -w8 $< | sed 's/^ *//' > $@

%.32.mem: %.bin
	od -v -An -tx4 -w4 $< | sed 's/^ *//' > $@

%.bin: %.elf
	$(RISCV_OBJCOPY) -O binary $< $@

%.out: %.elf
	$(RISCV_SIM) --isa=rv64gch_zfh_zicboz_svnapot_zicntr_zba_zbb_zbc_zbs --misaligned $< 2> $@

%.out32: %.elf
	$(RISCV_SIM) --isa=rv32gc_zfh_zicboz_svnapot_zicntr_zba_zbb_zbc_zbs --misaligned $< 2> $@

define compile_template

$1_p_tests_elf := $$(addprefix $1/,$$(addsuffix .elf,$$($1_p_tests)))
$$($1_p_tests_elf): $1/$1-p-%.elf: $$(src_dir)/$1/%.S
	$$(RISCV_GCC) $2 $$(RISCV_GCC_OPTS) -Ienv/p -I$(src_dir)/macros/scalar -Tenv/p/link.ld $$< -o $$@
$1_tests += $$($1_p_tests)

$1_v_tests_elf := $$(addprefix $1/,$$(addsuffix .elf,$$($1_v_tests)))
$$($1_v_tests_elf): $1/$1-v-%.elf: $$(src_dir)/$1/%.S
	$$(RISCV_GCC) $2 $$(RISCV_GCC_OPTS) -DENTROPY=0x$$(shell echo \$$@ | md5sum | cut -c 1-7) -std=gnu99 -O2 -Ienv/v -I$(src_dir)/macros/scalar -Tenv/v/link.ld env/v/entry.S env/v/*.c $$< -o $$@
#$1_tests += $$($1_v_tests)

$1_tests_elf        := $$(addprefix $1/,$$(addsuffix .elf, $$($1_tests)))
$1_tests_bin        := $$(addprefix $1/,$$(addsuffix .bin, $$($1_tests)))
$1_tests_32_mem     := $$(addprefix $1/,$$(addsuffix .32.mem, $$($1_tests)))
$1_tests_64_mem     := $$(addprefix $1/,$$(addsuffix .64.mem, $$($1_tests)))
$1_tests_128_mem    := $$(addprefix $1/,$$(addsuffix .128.mem, $$($1_tests)))
$1_tests_dump       := $$(addprefix $1/,$$(addsuffix .dump, $$($1_tests)))

.PHONY: $1
$1: build_dir_$1 $$($1_tests_elf) $$($1_tests_bin) $$($1_tests_32_mem) $$($1_tests_64_mem) $$($1_tests_128_mem) $$($1_tests_dump)

.PHONY: build_dir_$1
build_dir_$1:
	mkdir -p $1

COMPILER_SUPPORTS_$1 := $$(shell $$(RISCV_GCC) $2 -c -x c /dev/null -o /dev/null 2> /dev/null; echo $$$$?)

ifeq ($$(COMPILER_SUPPORTS_$1),0)
build_dirs += $1
tests += $$(addprefix $1/,$$($1_tests))
endif

endef

$(eval $(call compile_template,rv32ui,-march=rv32g -mabi=ilp32))
$(eval $(call compile_template,rv32uc,-march=rv32g -mabi=ilp32))
$(eval $(call compile_template,rv32um,-march=rv32g -mabi=ilp32))
$(eval $(call compile_template,rv32ua,-march=rv32g -mabi=ilp32))
$(eval $(call compile_template,rv32uf,-march=rv32g -mabi=ilp32))
$(eval $(call compile_template,rv32ud,-march=rv32g -mabi=ilp32))
$(eval $(call compile_template,rv32uzfh,-march=rv32g_zfh -mabi=ilp32))
$(eval $(call compile_template,rv32uzba,-march=rv32g_zba -mabi=ilp32))
$(eval $(call compile_template,rv32uzbb,-march=rv32g_zbb -mabi=ilp32))
$(eval $(call compile_template,rv32uzbc,-march=rv32g_zbc -mabi=ilp32))
$(eval $(call compile_template,rv32uzbs,-march=rv32g_zbs -mabi=ilp32))
$(eval $(call compile_template,rv32si,-march=rv32g -mabi=ilp32))
$(eval $(call compile_template,rv32mi,-march=rv32g -mabi=ilp32))
ifeq ($(XLEN),64)
$(eval $(call compile_template,rv64ui,-march=rv64g -mabi=lp64))
$(eval $(call compile_template,rv64uc,-march=rv64g -mabi=lp64))
$(eval $(call compile_template,rv64um,-march=rv64g -mabi=lp64))
$(eval $(call compile_template,rv64ua,-march=rv64g -mabi=lp64))
$(eval $(call compile_template,rv64uf,-march=rv64g -mabi=lp64))
$(eval $(call compile_template,rv64ud,-march=rv64g -mabi=lp64))
$(eval $(call compile_template,rv64uziccid,-march=rv64g -mabi=lp64))
$(eval $(call compile_template,rv64uzfh,-march=rv64g_zfh -mabi=lp64))
$(eval $(call compile_template,rv64uzba,-march=rv64g_zba -mabi=lp64))
$(eval $(call compile_template,rv64uzbb,-march=rv64g_zbb -mabi=lp64))
$(eval $(call compile_template,rv64uzbc,-march=rv64g_zbc -mabi=lp64))
$(eval $(call compile_template,rv64uzbs,-march=rv64g_zbs -mabi=lp64))
$(eval $(call compile_template,rv64mzicbo,-march=rv64g_zicboz -mabi=lp64))
$(eval $(call compile_template,rv64si,-march=rv64g -mabi=lp64))
$(eval $(call compile_template,rv64ssvnapot,-march=rv64g -mabi=lp64))
$(eval $(call compile_template,rv64mi,-march=rv64g -mabi=lp64))
$(eval $(call compile_template,hypervisor,-march=rv64gh -mabi=lp64))
endif

tests_bin           := $(addsuffix .bin, $(tests))
tests_32_mem        := $(addsuffix .32.mem, $(tests))
tests_64_mem        := $(addsuffix .64.mem, $(tests))
tests_128_mem       := $(addsuffix .128.mem, $(tests))
tests_dump          := $(addsuffix .dump, $(tests))
tests_out           := $(addsuffix .out, $(filter rv64%,$(tests)))
tests32_out         := $(addsuffix .out32, $(filter rv32%,$(tests)))

#------------------------------------------------------------
# Default

all: $(build_dirs) $(tests_bin) $(tests_32_mem) $(tests_64_mem) $(tests_128_mem) $(tests_dump)

$(build_dirs):
	mkdir -p $@

#------------------------------------------------------------
# Clean up

clean:
	rm -rf rv32*/ rv64*/
	rm -f *.elf *.bin *.mem *.dump *.out *.out32
