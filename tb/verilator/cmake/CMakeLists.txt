######################################################################
#
# DESCRIPTION: Verilator CMake Example: Small CMakeLists.txt with tracing
#
# This is an example cmake script to build a verilog to systemc project
# using cmake and verilator.
#
# This file ONLY is placed under the Creative Commons Public Domain, for
# any use, without warranty, 2020 by Wilson Snyder.
# SPDX-License-Identifier: CC0-1.0
#
######################################################################

# This example builds the make_tracing_c example using CMake
# To use it, run the following:

# rm -rf build && mkdir build && cd build
# cmake ..
# cmake --build .

cmake_minimum_required(VERSION 3.12)
cmake_policy(SET CMP0074 NEW)
project(tb_top)

#Set variables

list (APPEND INC_DIR "../../../include" "../../../src" "../../../tb")
list (APPEND ARG_LIST "--timing" "-Wno-WIDTHTRUNC" "--main")
file (GLOB SRC_LIST ../../tb_src/*.sv)


find_package(verilator HINTS $ENV{VERILATOR_ROOT} ${VERILATOR_ROOT})
if (NOT verilator_FOUND)
  message(FATAL_ERROR "Verilator was not found. Either install it, or set the VERILATOR_ROOT environment variable")
endif()

# Create a new executable target that will contain all your sources
add_executable(tb_top)
target_compile_features(tb_top PUBLIC cxx_std_14)

# Add the Verilated circuit to the target
verilate(tb_top COVERAGE TRACE
  TOP_MODULE tb_top
  SOURCES ${SRC_LIST}
  INCLUDE_DIRS ${INC_DIR}
  VERILATOR_ARGS -x-assign 0 ${ARG_LIST}
  )
