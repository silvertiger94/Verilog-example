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
SRC_DIR = $(MAKEFILE_PATH)../../../src
INC_DIR = $(MAKEFILE_PATH)../../../include
TB_DIR = $(MAKEFILE_PATH)../../tb_src

SRCS = $(notdir $(wildcard $(SRC_DIR)/*.sv))
TB_SRCS = $(notdir $(wildcard $(TB_DIR)/*.sv))

TOP = $(basename $(notdir $(wildcard $(TB_DIR)/*.sv)))

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
VERILATOR_FLAGS += --build -j 4
# Set include directory
VERILATOR_FLAGS += +incdir+$(INC_DIR)
# Directory to search for modules
VERILATOR_FLAGS += -y $(SRC_DIR) -y $(TB_DIR)
# You must define the top level for build/ or test
VERILATOR_FLAGS += --top-module $(TOP)
# Disable Warning
VERILATOR_FLAGS += -Wno-WIDTHTRUNC
# Disable Warning
VERILATOR_FLAGS += -Wno-WIDTHEXPAND
# Run Verilator in debug mode
#VERILATOR_FLAGS += --debug
# Add this trace to get a backtrace in gdb
#VERILATOR_FLAGS += --gdbbt

# Input files for Verilator
VERILATOR_INPUT = $(SRCS) $(TB_SRCS)

# Command Line Arguments
VERILATOR_ARGS = +trace

######################################################################

# Create annotated source
VERILATOR_COV_FLAGS += --annotate logs/annotated
# A single coverage hit is considered good enough
VERILATOR_COV_FLAGS += --annotate-min 1
# Create LCOV info
VERILATOR_COV_FLAGS += --write-info logs/coverage.info
# Input file from Verilator
VERILATOR_COV_FLAGS += coverage.dat

##################################################################

default: all

all:verilate run cov wave

build:verilate run

verilate:
	@echo
	@echo "-- VERILATE ----------------"
	$(VERILATOR) --version
	$(VERILATOR) $(VERILATOR_FLAGS) $(VERILATOR_INPUT)

run:verilate
	@echo
	@echo "-- RUN ---------------------"
	@rm -rf logs
	@mkdir -p logs
	obj_dir/V$(TOP) $(VERILATOR_ARGS)

cov:run
	@echo
	@echo "-- COVERAGE ----------------"
	@rm -rf logs/annotated
	$(VERILATOR_COVERAGE) $(VERILATOR_COV_FLAGS)

wave:run
	@echo
	@echo "-- WAVE --------------------"
	gtkwave logs/vlt_dump.vcd
	@echo "-- DONE --------------------"

######################################################################
# Another Targets	

show-config:
	$(VERILATOR) -V

.PHONY:lint
lint: $(SRC_DIR)/$(SRCS)
	cd $(SRC_DIR) && verilator --lint-only $(SRCS) -I$(INC_DIR)

.PHONY: clean
clean:
	rm -rf ./obj_dir
	rm -rf logs coverage.dat
