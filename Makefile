######################################################################
# Usage
# make
# make TOP=fifo
######################################################################

######################################################################
# Check for sanity to avoid later confusion

ifneq ($(words $(CURDIR)),1)
 $(error Unsupported: GNU Make cannot build in directories containing spaces, build elsewhere: '$(CURDIR)')
endif

######################################################################
# Setup variables

# If $VERILATOR_ROOT isn't in the environment, we assume it is part of a
# package install, and verilator is in your path. Otherwise find the
# binary relative to $VERILATOR_ROOT (such as when inside the git sources).
ifeq ($(VERILATOR_ROOT),)
VERILATOR = verilator
VERILATOR_COVERAGE = verilator_coverage
else
export VERILATOR_ROOT
VERILATOR = $(VERILATOR_ROOT)/bin/verilator
VERILATOR_COVERAGE = $(VERILATOR_ROOT)/bin/verilator_coverage
endif

######################################################################
# Input Source Files
MAKEFILE_PATH = $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
SRC_DIR = $(MAKEFILE_PATH)/src
LIB_DIR = $(MAKEFILE_PATH)/src/lib
INC_DIR = $(MAKEFILE_PATH)/include
TB_DIR      = $(MAKEFILE_PATH)/src/tb
TB_DIRS    := $(shell find $(TB_DIR) -type d)
UVM_DIR       = $(MAKEFILE_PATH)/third_party/uvm-verilator/src
# UVM_DPI_DIR = $(UVM_DIR)/dpi

SRCS    := $(notdir $(wildcard $(SRC_DIR)/*.sv))
LIBS    := $(notdir $(wildcard $(LIB_DIR)/*.sv))

TOP    ?= sdpram
TB_TOP := tb_top
TIMESTAMP := $(shell date +%Y%m%d_%H%M%S)
OUT_DIR   := $(MAKEFILE_PATH)/sim/verilator/$(TB_TOP)_$(TIMESTAMP)

######################################################################
# Generate C++ in executable form
VERILATOR_FLAGS += -cc --exe
# Optimize
VERILATOR_FLAGS += --x-assign 0
# Make waveforms
VERILATOR_FLAGS += --trace
# Enable timing support
VERILATOR_FLAGS += --timing
# Check SystemVerilog assertions
VERILATOR_FLAGS += --assert
# Generate cpp files of tb_top
VERILATOR_FLAGS += --main
# Generate coverage analysis
VERILATOR_FLAGS += --coverage
# Run make to compile model, with as many CPUs as are free
VERILATOR_FLAGS += --build -j 2
# Output directory
VERILATOR_FLAGS += --Mdir $(OUT_DIR)/obj_dir
# Set include directory
VERILATOR_FLAGS += +incdir+$(INC_DIR)
# UVM include directory
VERILATOR_FLAGS += +incdir+$(UVM_DIR)
# Directory to search for modules
VERILATOR_FLAGS += -y $(SRC_DIR) -y $(LIB_DIR)
VERILATOR_FLAGS += $(foreach d,$(TB_DIRS),-y $(d))
# Include paths for `include inside packages
VERILATOR_FLAGS += $(foreach d,$(TB_DIRS),+incdir+$(d))
# You must define the top level for build/ or test
VERILATOR_FLAGS += --top-module $(TB_TOP)
# Disable Warning
VERILATOR_FLAGS += -Wno-WIDTHTRUNC
VERILATOR_FLAGS += -Wno-WIDTHEXPAND
VERILATOR_FLAGS += -Wno-TIMESCALEMOD
# Enable VPI support
VERILATOR_FLAGS += --vpi
# Command line Define
# Note: This flags are needed because the verilator has compile error "with dpi options"
VERILATOR_FLAGS += +define+UVM_NO_DPI
# Run Verilator in debug mode
#VERILATOR_FLAGS += --debug
# Add this trace to get a backtrace in gdb
#VERILATOR_FLAGS += --gdbbt

# Input files for Verilator
VERILATOR_INPUT = $(UVM_DIR)/uvm_pkg.sv $(LIBS) $(SRCS) $(TB_COMMON_DIR)/tb_top.sv

# Command Line Arguments
VERILATOR_ARGS = +trace

######################################################################

# Create annotated source
VERILATOR_COV_FLAGS += --annotate $(OUT_DIR)/logs/annotated
# A single coverage hit is considered good enough
VERILATOR_COV_FLAGS += --annotate-min 1
# Create LCOV info
VERILATOR_COV_FLAGS += --write-info $(OUT_DIR)/logs/coverage.info
# Input file from Verilator
VERILATOR_COV_FLAGS += $(OUT_DIR)/coverage.dat

##################################################################

default: all

all:verilate run cov wave

build:verilate run

verilate:
	@echo
	@echo "-- VERILATE ----------------"
	@mkdir -p $(OUT_DIR)/obj_dir
	$(VERILATOR) --version
	$(VERILATOR) $(VERILATOR_FLAGS) $(VERILATOR_INPUT)

run:verilate
	@echo
	@echo "-- RUN ---------------------"
	@rm -rf $(OUT_DIR)/logs
	@mkdir -p $(OUT_DIR)/logs
	cd $(OUT_DIR) && ./obj_dir/V$(TB_TOP) $(VERILATOR_ARGS) 2>&1 | tee $(OUT_DIR)/logs/sim.log

cov:run
	@echo
	@echo "-- COVERAGE ----------------"
	@rm -rf $(OUT_DIR)/logs/annotated
	$(VERILATOR_COVERAGE) $(VERILATOR_COV_FLAGS)

wave:run
	@echo
	@echo "-- WAVE --------------------"
	gtkwave $(OUT_DIR)/logs/vlt_dump.vcd
	@echo "-- DONE --------------------"

######################################################################
# Another Targets

.PHONY: init
init:
	git submodule update --init --recursive

show-config:
	$(VERILATOR) -V

.PHONY:lint
lint: $(SRC_DIR)/$(SRCS)
	cd $(SRC_DIR) && verilator --lint-only $(SRCS) -I$(INC_DIR)

.PHONY: clean
clean:
	rm -rf $(MAKEFILE_PATH)/sim/verilator/$(TB_TOP)_*

.PHONY: cleanall
cleanall:
	rm -rf $(MAKEFILE_PATH)/sim/verilator/
