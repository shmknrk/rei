#===================================================================================================
# config
#---------------------------------------------------------------------------------------------------
DIFF_COMMIT_LOG     := 0
#TRACE_FST_FILE      := dump.fst

#---------------------------------------------------------------------------------------------------
log_dir             := log
diff_dir            := $(log_dir)/diff

# configuration for the program
xlen                := 64
riscv_arch          := rv$(xlen)im_zicntr_zicsr_zifencei
riscv_abi           := $(if $(filter 64,$(xlen)),lp64,ilp32)

#===================================================================================================
# sources
#---------------------------------------------------------------------------------------------------
pkg_dir             := src/pkg
pkgs                += $(pkg_dir)/rei_pkg.sv

src_dirs            += src/util src
srcs                += $(foreach src_dir,$(src_dirs),$(wildcard $(addprefix $(src_dir)/,*.sv *.v)))

sim_src_dirs        += sim
sim_srcs            += $(foreach src_dir,$(sim_src_dirs),$(wildcard $(addprefix $(src_dir)/,*.sv *.v)))

inc_dirs            += $(src_dirs)

prog_dir            := prog
test_dir            := $(prog_dir)/test
riscv-tests_dir     := $(prog_dir)/riscv-tests

-include config.mk

#===================================================================================================
# verilator
#---------------------------------------------------------------------------------------------------
topname             := rei
topmodule           := top

verilator           ?= verilator

# see Verilator Arguments (https://veripool.org/guide/latest/exe_verilator.html)
verilator_flags     += --binary
verilator_flags     += --prefix $(topname)
verilator_flags     += --top-module $(topmodule)
verilator_flags     += --Wno-WIDTHEXPAND

verilator_flags     += $(if $(TRACE_FST_FILE),--trace-fst --trace-structs)
verilator_flags     += $(addprefix -I,$(inc_dirs))

verilator_input     += $(pkgs) $(srcs) $(sim_srcs)

plusargs            += $(if $(imem_file),+imem_file="$(imem_file)")
plusargs            += $(if $(dmem_file),+dmem_file="$(dmem_file)")
plusargs            += $(if $(max_cycles),+max_cycles=$(max_cycles))
plusargs            += $(if $(TRACE_FST_FILE),+trace_fst_file="$(log_dir)/$(TRACE_FST_FILE)")
plusargs            += $(if $(commit_log_file),+commit_log_file="$(log_dir)/$(commit_log_file)")

#===================================================================================================
# build rules
#---------------------------------------------------------------------------------------------------
.PHONY: default build run
default: ;

build:
	$(verilator) $(verilator_flags) $(verilator_input)

run: $(log_dir)
	obj_dir/$(topname) $(plusargs)

$(log_dir) $(diff_dir):
	@mkdir -p $@

#---------------------------------------------------------------------------------------------------
.PHONY: clean progclean distclean
clean:
	rm -f *.log
	rm -rf obj_dir/ $(log_dir)/

progclean:
	@echo test
	@make -C $(test_dir) clean --no-print-directory
	@echo riscv-tests
	@make -C $(riscv-tests_dir) clean --no-print-directory

distclean: clean progclean

#===================================================================================================
# test-template
#---------------------------------------------------------------------------------------------------
# $(eval $(call test-template,program,program_list,program_dir,max_cycles))
define test-template

.PHONY: $1 $2
$1: $2

$2: %: $3/%.32.mem $3/%.64.mem
	make build --no-print-directory
	make run imem_file=$3/$$@.32.mem dmem_file=$3/$$@.64.mem max_cycles=$4 --no-print-directory

$3/%.32.mem $3/%.64.mem:
	make -C $3 --no-print-directory

endef

#===================================================================================================
# test
#---------------------------------------------------------------------------------------------------
__test              := test

$(eval $(call test-template,__test,$(__test),$(test_dir),50))

#===================================================================================================
# riscv-tests template
#---------------------------------------------------------------------------------------------------

define riscv-tests-template

.PHONY: $1_test $$($1_sc_tests)
$1_test: $$($1_sc_tests)
$$($1_sc_tests): %: $(riscv-tests_dir)/$1
ifeq ($(DIFF_COMMIT_LOG),1)
$$($1_sc_tests): %: $$(diff_dir)
	spike --isa=$$(riscv_arch) --log-commits --log=$$(log_dir)/$$@_spike_commit.log $$(riscv-tests_dir)/$1/$1-p-$$@.elf
	make build --no-print-directory > /dev/null
	make run \
		imem_file=$$(riscv-tests_dir)/$1/$1-p-$$@.32.mem \
		dmem_file=$$(riscv-tests_dir)/$1/$1-p-$$@.64.mem \
		max_cycles=$2 \
		commit_log_file=$$@_rei_commit.log \
		--no-print-directory
	-diff $$(log_dir)/$$@_spike_commit.log $$(log_dir)/$$@_rei_commit.log > $$(diff_dir)/$1-p-$$@.diff

else
	make build --no-print-directory > /dev/null
	make run \
		imem_file=$$(riscv-tests_dir)/$1/$1-p-$$@.32.mem \
		dmem_file=$$(riscv-tests_dir)/$1/$1-p-$$@.64.mem \
		max_cycles=$2 \
		--no-print-directory
endif

$$(riscv-tests_dir)/$1:
	make -C $$(riscv-tests_dir) $1 --no-print-directory

endef

#===================================================================================================
# riscv-tests
#---------------------------------------------------------------------------------------------------
# ma_data fence_i
rv64ui_sc_tests     := \
	add addi addiw addw \
	and andi \
	auipc \
	beq bge bgeu blt bltu bne \
	simple \
	jal jalr \
	lb lbu lh lhu lw lwu ld ld_st \
	lui \
	or ori \
	sb sh sw sd st_ld \
	sll slli slliw sllw \
	slt slti sltiu sltu \
	sra srai sraiw sraw \
	srl srli srliw srlw \
	sub subw \
	xor xori \

rv64um_sc_tests     := \
	div divu divuw divw \
	mul mulh mulhsu mulhu mulw \
	rem remu remuw remw \

.PHONY: isa
isa: rv64ui_test rv64um_test
$(eval $(call riscv-tests-template,rv64ui,2000))
$(eval $(call riscv-tests-template,rv64um,2000))

#===================================================================================================
# docker
#---------------------------------------------------------------------------------------------------
tagname             := rei
home_dir            := /root
work_dir            := $(home_dir)/work

.PHONY: docker-build mount
docker-build:
	docker build \
		--no-cache \
		-t $(tagname) \
		--build-arg XLEN=$(xlen) \
		--build-arg RISCV_ARCH=$(riscv_arch) \
		--build-arg RISCV_ABI=$(riscv_abi) \
		.

mount:
	docker run --rm -it \
		--mount type=bind,source=$(CURDIR),target=$(work_dir) \
		-w $(work_dir) \
		$(tagname)
