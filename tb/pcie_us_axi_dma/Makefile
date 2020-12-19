# Copyright (c) 2020 Alex Forencich
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

TOPLEVEL_LANG = verilog

SIM ?= icarus
WAVES ?= 0

COCOTB_HDL_TIMEUNIT = 1ns
COCOTB_HDL_TIMEPRECISION = 1ps

DUT      = pcie_us_axi_dma
TOPLEVEL = $(DUT)
MODULE   = test_$(DUT)
VERILOG_SOURCES += ../../rtl/$(DUT).v
VERILOG_SOURCES += ../../rtl/$(DUT)_rd.v
VERILOG_SOURCES += ../../rtl/$(DUT)_wr.v
VERILOG_SOURCES += ../../rtl/pcie_tag_manager.v
VERILOG_SOURCES += ../../rtl/priority_encoder.v

# module parameters
export PARAM_AXIS_PCIE_DATA_WIDTH ?= 64
export PARAM_AXIS_PCIE_KEEP_WIDTH ?= $(shell expr $(PARAM_AXIS_PCIE_DATA_WIDTH) / 32 )
export PARAM_AXIS_PCIE_RQ_USER_WIDTH ?= $(if $(filter-out 512,$(PARAM_AXIS_PCIE_DATA_WIDTH)),62,137)
export PARAM_AXIS_PCIE_RC_USER_WIDTH ?= $(if $(filter-out 512,$(PARAM_AXIS_PCIE_DATA_WIDTH)),75,161)
export PARAM_RQ_SEQ_NUM_WIDTH ?= $(if $(filter-out 60,$(PARAM_AXIS_PCIE_RQ_USER_WIDTH)),6,4)
export PARAM_RQ_SEQ_NUM_ENABLE ?= 1
export PARAM_AXI_DATA_WIDTH ?= $(PARAM_AXIS_PCIE_DATA_WIDTH)
export PARAM_AXI_ADDR_WIDTH ?= 24
export PARAM_AXI_STRB_WIDTH ?= $(shell expr $(PARAM_AXI_DATA_WIDTH) / 8 )
export PARAM_AXI_ID_WIDTH ?= 8
export PARAM_AXI_MAX_BURST_LEN ?= 256
export PARAM_PCIE_ADDR_WIDTH ?= 64
export PARAM_PCIE_TAG_COUNT ?= $(if $(filter-out 60,$(PARAM_AXIS_PCIE_RQ_USER_WIDTH)),256,64)
export PARAM_PCIE_TAG_WIDTH ?= 8
export PARAM_PCIE_EXT_TAG_ENABLE ?= 1
export PARAM_LEN_WIDTH ?= 20
export PARAM_TAG_WIDTH ?= 8
export PARAM_READ_OP_TABLE_SIZE ?= $(PARAM_PCIE_TAG_COUNT)
export PARAM_READ_TX_LIMIT ?= $(shell echo "$$(( 1 << ($(PARAM_RQ_SEQ_NUM_WIDTH)-1) ))" )
export PARAM_READ_TX_FC_ENABLE ?= 1
export PARAM_WRITE_OP_TABLE_SIZE ?= $(shell echo "$$(( 1 << ($(PARAM_RQ_SEQ_NUM_WIDTH)-1) ))" )
export PARAM_WRITE_TX_LIMIT ?= $(shell echo "$$(( 1 << ($(PARAM_RQ_SEQ_NUM_WIDTH)-1) ))" )
export PARAM_WRITE_TX_FC_ENABLE ?= 1

SIM_BUILD ?= sim_build_$(MODULE)-$(PARAM_AXIS_PCIE_DATA_WIDTH)

ifeq ($(SIM), icarus)
	PLUSARGS += -fst

	COMPILE_ARGS += -P $(TOPLEVEL).AXIS_PCIE_DATA_WIDTH=$(PARAM_AXIS_PCIE_DATA_WIDTH)
	COMPILE_ARGS += -P $(TOPLEVEL).AXIS_PCIE_KEEP_WIDTH=$(PARAM_AXIS_PCIE_KEEP_WIDTH)
	COMPILE_ARGS += -P $(TOPLEVEL).AXIS_PCIE_RQ_USER_WIDTH=$(PARAM_AXIS_PCIE_RQ_USER_WIDTH)
	COMPILE_ARGS += -P $(TOPLEVEL).AXIS_PCIE_RC_USER_WIDTH=$(PARAM_AXIS_PCIE_RC_USER_WIDTH)
	COMPILE_ARGS += -P $(TOPLEVEL).RQ_SEQ_NUM_WIDTH=$(PARAM_RQ_SEQ_NUM_WIDTH)
	COMPILE_ARGS += -P $(TOPLEVEL).RQ_SEQ_NUM_ENABLE=$(PARAM_RQ_SEQ_NUM_ENABLE)
	COMPILE_ARGS += -P $(TOPLEVEL).AXI_DATA_WIDTH=$(PARAM_AXI_DATA_WIDTH)
	COMPILE_ARGS += -P $(TOPLEVEL).AXI_ADDR_WIDTH=$(PARAM_AXI_ADDR_WIDTH)
	COMPILE_ARGS += -P $(TOPLEVEL).AXI_STRB_WIDTH=$(PARAM_AXI_STRB_WIDTH)
	COMPILE_ARGS += -P $(TOPLEVEL).AXI_ID_WIDTH=$(PARAM_AXI_ID_WIDTH)
	COMPILE_ARGS += -P $(TOPLEVEL).AXI_MAX_BURST_LEN=$(PARAM_AXI_MAX_BURST_LEN)
	COMPILE_ARGS += -P $(TOPLEVEL).PCIE_ADDR_WIDTH=$(PARAM_PCIE_ADDR_WIDTH)
	COMPILE_ARGS += -P $(TOPLEVEL).PCIE_TAG_COUNT=$(PARAM_PCIE_TAG_COUNT)
	COMPILE_ARGS += -P $(TOPLEVEL).PCIE_TAG_WIDTH=$(PARAM_PCIE_TAG_WIDTH)
	COMPILE_ARGS += -P $(TOPLEVEL).PCIE_EXT_TAG_ENABLE=$(PARAM_PCIE_EXT_TAG_ENABLE)
	COMPILE_ARGS += -P $(TOPLEVEL).LEN_WIDTH=$(PARAM_LEN_WIDTH)
	COMPILE_ARGS += -P $(TOPLEVEL).TAG_WIDTH=$(PARAM_TAG_WIDTH)
	COMPILE_ARGS += -P $(TOPLEVEL).READ_OP_TABLE_SIZE=$(PARAM_READ_OP_TABLE_SIZE)
 	COMPILE_ARGS += -P $(TOPLEVEL).READ_TX_LIMIT=$(PARAM_READ_TX_LIMIT)
	COMPILE_ARGS += -P $(TOPLEVEL).READ_TX_FC_ENABLE=$(PARAM_READ_TX_FC_ENABLE)
	COMPILE_ARGS += -P $(TOPLEVEL).WRITE_OP_TABLE_SIZE=$(PARAM_WRITE_OP_TABLE_SIZE)
 	COMPILE_ARGS += -P $(TOPLEVEL).WRITE_TX_LIMIT=$(PARAM_WRITE_TX_LIMIT)
	COMPILE_ARGS += -P $(TOPLEVEL).WRITE_TX_FC_ENABLE=$(PARAM_WRITE_TX_FC_ENABLE)

	ifeq ($(WAVES), 1)
		VERILOG_SOURCES += iverilog_dump.v
		COMPILE_ARGS += -s iverilog_dump
	endif
else ifeq ($(SIM), verilator)
	COMPILE_ARGS += -Wno-SELRANGE -Wno-WIDTH

	COMPILE_ARGS += -GAXIS_PCIE_DATA_WIDTH=$(PARAM_AXIS_PCIE_DATA_WIDTH)
	COMPILE_ARGS += -GAXIS_PCIE_KEEP_WIDTH=$(PARAM_AXIS_PCIE_KEEP_WIDTH)
	COMPILE_ARGS += -GAXIS_PCIE_RQ_USER_WIDTH=$(PARAM_AXIS_PCIE_RQ_USER_WIDTH)
	COMPILE_ARGS += -GAXIS_PCIE_RC_USER_WIDTH=$(PARAM_AXIS_PCIE_RC_USER_WIDTH)
	COMPILE_ARGS += -GAXIS_RQ_SEQ_NUM_WIDTH=$(PARAM_RQ_SEQ_NUM_WIDTH)
	COMPILE_ARGS += -GAXIS_RQ_SEQ_NUM_ENABLE=$(PARAM_RQ_SEQ_NUM_ENABLE)
	COMPILE_ARGS += -GAXI_DATA_WIDTH=$(PARAM_AXI_DATA_WIDTH)
	COMPILE_ARGS += -GAXI_ADDR_WIDTH=$(PARAM_AXI_ADDR_WIDTH)
	COMPILE_ARGS += -GAXI_STRB_WIDTH=$(PARAM_AXI_STRB_WIDTH)
	COMPILE_ARGS += -GAXI_ID_WIDTH=$(PARAM_AXI_ID_WIDTH)
	COMPILE_ARGS += -GAXI_MAX_BURST_LEN=$(PARAM_AXI_MAX_BURST_LEN)
	COMPILE_ARGS += -GPCIE_ADDR_WIDTH=$(PARAM_PCIE_ADDR_WIDTH)
	COMPILE_ARGS += -GPCIE_TAG_COUNT=$(PARAM_PCIE_TAG_COUNT)
	COMPILE_ARGS += -GPCIE_TAG_WIDTH=$(PARAM_PCIE_TAG_WIDTH)
	COMPILE_ARGS += -GPCIE_EXT_TAG_ENABLE=$(PARAM_PCIE_EXT_TAG_ENABLE)
	COMPILE_ARGS += -GLEN_WIDTH=$(PARAM_LEN_WIDTH)
	COMPILE_ARGS += -GTAG_WIDTH=$(PARAM_TAG_WIDTH)
	COMPILE_ARGS += -GREAD_OP_TABLE_SIZE=$(PARAM_READ_OP_TABLE_SIZE)
 	COMPILE_ARGS += -GREAD_TX_LIMIT=$(PARAM_READ_TX_LIMIT)
	COMPILE_ARGS += -GREAD_TX_FC_ENABLE=$(PARAM_READ_TX_FC_ENABLE)
	COMPILE_ARGS += -GWRITE_OP_TABLE_SIZE=$(PARAM_WRITE_OP_TABLE_SIZE)
 	COMPILE_ARGS += -GWRITE_TX_LIMIT=$(PARAM_WRITE_TX_LIMIT)
	COMPILE_ARGS += -GWRITE_TX_FC_ENABLE=$(PARAM_WRITE_TX_FC_ENABLE)

	ifeq ($(WAVES), 1)
		COMPILE_ARGS += --trace-fst
	endif
endif

iverilog_dump.v:
	echo 'module iverilog_dump();' > $@
	echo 'initial begin' >> $@
	echo '    $$dumpfile("$(TOPLEVEL).fst");' >> $@
	echo '    $$dumpvars(0, $(TOPLEVEL));' >> $@
	echo 'end' >> $@
	echo 'endmodule' >> $@

clean::
	@rm -rf sim_build_*
	@rm -rf iverilog_dump.v
	@rm -rf dump.fst $(TOPLEVEL).fst

include $(shell cocotb-config --makefiles)/Makefile.sim
