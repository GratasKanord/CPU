Author: Gratas Kanord
GitHub: [GratasKanord](https://github.com/GratasKanord)

# RV64I Single-Cycle RISC-V CPU

A 64-bit RISC-V single-cycle processor implemented in Verilog.

## Quick Overview
- **Architecture**: Single-cycle RV64I
- **Status**: Passes all 52 RV64UI base integer compliance tests from the official RISC-V Architectural Test Suite
- **Language**: Verilog

## Features
- Complete RV64I instruction set implementation
- Single-cycle execution model
- Verified with official RISC-V tests
- Trap handling implemented

## Tests Passed
**52 tests:**
- All arithmetic operations (ADD, SUB, MUL, etc.)
- All logical operations (AND, OR, XOR, shifts)
- Memory operations (LB, LH, LW, LD, SB, SH, SW, SD)
- Control flow (branches, jumps)

## Project Structure
- ASMcode : manually written Assembly programs for quick testing
- compl_tests > pass_screenshot : screenshots of passed RISC-V compliance tests
- cpu_internal : all internal modules of the CPU: pc, decoder, dmem, etc.
- cpu_top : top layer of the CPU and testbench

## Prerequisites
- Icarus Verilog (`iverilog` and `vvp`)
- RISC-V toolchain (for compiling new tests)

## Getting Started
1) Clone the repository
git clone https://github.com/GratasKanord/RV64I.git

2) Indicate which test do you want to execute
in the ***imem.v***, write the name of the test in this line:
```$readmemh("./compl_tests/rv64ui-p-add.hex", imem);```
In this case, the rv64ui-p-add test will be executed.

3) Run the simulation with Icarus Verilog 
cd ~/cpu
iverilog -o cpu_top_test \
  cpu_top/cpu_top.v \
  cpu_top/cpu_top_tb.v \
  cpu_internal/trap_handler/trap_handler.v \
  cpu_internal/alu/alu.v \
  cpu_internal/alu/alu_lsb.v \
  cpu_internal/alu/alu_mid.v \
  cpu_internal/alu/alu_msb.v \
  cpu_internal/decoder/decoder.v \
  cpu_internal/imem/imem.v \
  cpu_internal/dmem/dmem.v \
  cpu_internal/pc/pc.v \
  cpu_internal/regfile/regfile.v \
  cpu_internal/CSR/csr_machine.v \
  cpu_internal/CSR/csr_supervisor.v \
  cpu_internal/CSR/csr_user.v \
  cpu_internal/CSR/csr_top.v \
  cpu_internal/priv_lvl/priv_lvl.v

vvp cpu_top_test

*Note:* for some tests initialization of DMEM is required. Check dmem initialization in the commit that corresponds to the test.

