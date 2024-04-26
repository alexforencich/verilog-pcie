# Verilog PCIe Alveo Example Design

## Introduction

This design targets multiple FPGA boards, including most of the Xilinx Alveo line.

The design implements the PCIe AXI lite master module, the PCIe AXI master module, and the PCIe DMA module.  A very simple Linux driver is included to test the FPGA design.

* FPGA
  * AU50: xcu50-fsvh2104-2-e
  * AU55C: xcu55c-fsvh2892-2L-e
  * AU55N/C1100: xcu55n-fsvh2892-2L-e
  * AU200: xcu200-fsgd2104-2-e
  * AU250: xcu250-fsgd2104-2-e
  * AU280: xcu280-fsvh2892-2L-e
  * VCU1525: xcvu9p-fsgd2104-2L-e

## How to build

Run `make` to build.  Ensure that the Xilinx Vivado components are in PATH.

Run `make` to build the driver.  Ensure the headers for the running kernel are installed, otherwise the driver cannot be compiled.

## How to test

Run `make program` to program the Alveo board with Vivado.  Then load the driver with `insmod example.ko`.  Check dmesg for the output.
