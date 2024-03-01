
# SPDX-License-Identifier: BSD-2-Clause-Views
# Copyright (c) 2020-2023 The Regents of the University of California

TOPLEVEL_LANG = verilog

SIM ?= icarus
WAVES ?= 1

COCOTB_HDL_TIMEUNIT = 1ns
COCOTB_HDL_TIMEPRECISION = 1ps

DUT      = mqnic_app_block_scheduler
TOPLEVEL = $(DUT)
MODULE   = test_$(DUT)
VERILOG_SOURCES += ../../rtl/$(DUT).v
VERILOG_SOURCES += ../../rtl/top_scheduler_down.v
VERILOG_SOURCES += ../../rtl/top_packet_dispatcher.v
VERILOG_SOURCES += ../../rtl/axis_packet_dispatcher_demultiplexeur.v
VERILOG_SOURCES += ../../rtl/axis_packet_dispatcher_multiplexeur.v
VERILOG_SOURCES += ../../rtl/buffer_parser_packet_dispatcher.v
VERILOG_SOURCES += ../../rtl/mat_packet_dispatcher.v
VERILOG_SOURCES += ../../rtl/FSM_packet_dispatcher.v
VERILOG_SOURCES += ../../rtl/top_priority_FIFO.v
VERILOG_SOURCES += ../../rtl/axis_FIFO_mult.v
VERILOG_SOURCES += ../../rtl/crossbar.v
VERILOG_SOURCES += ../../rtl/top_scheduler_up.v
VERILOG_SOURCES += ../../rtl/axis_tdest_demux.v

VERILOG_SOURCES += ../../lib/axi/rtl//axil_reg_if.v
VERILOG_SOURCES += ../../lib/axi/rtl//axil_reg_if_rd.v
VERILOG_SOURCES += ../../lib/axi/rtl//axil_reg_if_wr.v 
VERILOG_SOURCES += ../../lib/axis/rtl/axis_fifo.v

# module parameters
# export PARAM_DATA_WIDTH := 64
# export PARAM_KEEP_WIDTH := $(shell expr $(PARAM_DATA_WIDTH) / 8 )

ifeq ($(SIM), icarus)
	PLUSARGS += -fst

	COMPILE_ARGS += $(foreach v,$(filter PARAM_%,$(.VARIABLES)),-P $(TOPLEVEL).$(subst PARAM_,,$(v))=$($(v)))

	ifeq ($(WAVES), 1)
		VERILOG_SOURCES += iverilog_dump.v
		COMPILE_ARGS += -s iverilog_dump
	endif
else ifeq ($(SIM), verilator)
	COMPILE_ARGS += -Wno-SELRANGE -Wno-WIDTH

	COMPILE_ARGS += $(foreach v,$(filter PARAM_%,$(.VARIABLES)),-G$(subst PARAM_,,$(v))=$($(v)))

	ifeq ($(WAVES), 1)
		COMPILE_ARGS += --trace-fst
	endif
endif

include $(shell cocotb-config --makefiles)/Makefile.sim

iverilog_dump.v:
	echo 'module iverilog_dump();' > $@
	echo 'initial begin' >> $@
	echo '    $$dumpfile("$(TOPLEVEL).fst");' >> $@
	echo '    $$dumpvars(0, $(TOPLEVEL));' >> $@
	echo 'end' >> $@
	echo 'endmodule' >> $@

clean::
	@rm -rf iverilog_dump.v
	@rm -rf dump.fst $(TOPLEVEL).fst
	
# # SPDX-License-Identifier: BSD-2-Clause-Views
# # Copyright (c) 2021-2023 The Regents of the University of California

# TOPLEVEL_LANG = verilog

# SIM ?= icarus
# WAVES ?= 1

# COCOTB_HDL_TIMEUNIT = 1ns
# COCOTB_HDL_TIMEPRECISION = 1ps

# DUT      = mqnic_app_block_scheduler
# TOPLEVEL = $(DUT)
# MODULE   = test_$(DUT)
# VERILOG_SOURCES += ../../rtl/$(DUT).v
# VERILOG_SOURCES += ../../rtl/top_scheduler_down.v
# VERILOG_SOURCES += ../../rtl/top_packet_dispatcher.v
# VERILOG_SOURCES += ../../rtl/axis_packet_dispatcher_demultiplexeur.v
# VERILOG_SOURCES += ../../rtl/axis_packet_dispatcher_multiplexeur.v
# VERILOG_SOURCES += ../../rtl/buffer_parser_packet_dispatcher.v
# VERILOG_SOURCES += ../../rtl/mat_packet_dispatcher.v
# VERILOG_SOURCES += ../../rtl/FSM_packet_dispatcher.v
# VERILOG_SOURCES += ../../rtl/top_priority_FIFO.v
# VERILOG_SOURCES += ../../rtl/axis_FIFO_mult.v
# VERILOG_SOURCES += ../../rtl/crossbar.v
# VERILOG_SOURCES += ../../rtl/top_scheduler_up.v
# VERILOG_SOURCES += ../../rtl/axis_tdest_demux.v

# # module parameters
# # Structural configuration
# export PARAM_IF_COUNT := 4
# export PARAM_PORTS_PER_IF := 1
# export PARAM_SCHED_PER_IF := PORTS_PER_IF

# export PARAM_PORT_COUNT := IF_COUNT*PORTS_PER_IF

# # Clock configuration
# export PARAM_CLK_PERIOD_NS_NUM := 4
# export PARAM_CLK_PERIOD_NS_DENOM := 1

# # PTP configuration
# export PARAM_PTP_CLK_PERIOD_NS_NUM := 4
# export PARAM_PTP_CLK_PERIOD_NS_DENOM := 1
# export PARAM_PTP_TS_WIDTH := 96
# export PARAM_PTP_USE_SAMPLE_CLOCK := 0
# export PARAM_PTP_PORT_CDC_PIPELINE := 0
# export PARAM_PTP_PEROUT_ENABLE := 0
# export PARAM_PTP_PEROUT_COUNT := 1

# # Interface configuration
# export PARAM_PTP_TS_ENABLE := 1
# export PARAM_TX_TAG_WIDTH := 16
# export PARAM_MAX_TX_SIZE := 9214
# export PARAM_MAX_RX_SIZE := 9214

# # RAM configuration
# export PARAM_DDR_CH := 1
# export PARAM_DDR_ENABLE := 0
# export PARAM_DDR_GROUP_SIZE := 1
# export PARAM_AXI_DDR_DATA_WIDTH := 256
# export PARAM_AXI_DDR_ADDR_WIDTH := 32
# export PARAM_AXI_DDR_STRB_WIDTH := (AXI_DDR_DATA_WIDTH/8)
# export PARAM_AXI_DDR_ID_WIDTH := 8
# export PARAM_AXI_DDR_AWUSER_ENABLE := 0
# export PARAM_AXI_DDR_AWUSER_WIDTH := 1
# export PARAM_AXI_DDR_WUSER_ENABLE := 0
# export PARAM_AXI_DDR_WUSER_WIDTH := 1
# export PARAM_AXI_DDR_BUSER_ENABLE := 0
# export PARAM_AXI_DDR_BUSER_WIDTH := 1
# export PARAM_AXI_DDR_ARUSER_ENABLE := 0
# export PARAM_AXI_DDR_ARUSER_WIDTH := 1
# export PARAM_AXI_DDR_RUSER_ENABLE := 0
# export PARAM_AXI_DDR_RUSER_WIDTH := 1
# export PARAM_AXI_DDR_MAX_BURST_LEN := 256
# export PARAM_AXI_DDR_NARROW_BURST := 0
# export PARAM_AXI_DDR_FIXED_BURST := 0
# export PARAM_AXI_DDR_WRAP_BURST := 0
# export PARAM_HBM_CH := 1
# export PARAM_HBM_ENABLE := 0
# export PARAM_HBM_GROUP_SIZE := 1
# export PARAM_AXI_HBM_DATA_WIDTH := 256
# export PARAM_AXI_HBM_ADDR_WIDTH := 32
# export PARAM_AXI_HBM_STRB_WIDTH := (AXI_HBM_DATA_WIDTH/8)
# export PARAM_AXI_HBM_ID_WIDTH := 8
# export PARAM_AXI_HBM_AWUSER_ENABLE := 0
# export PARAM_AXI_HBM_AWUSER_WIDTH := 1
# export PARAM_AXI_HBM_WUSER_ENABLE := 0
# export PARAM_AXI_HBM_WUSER_WIDTH := 1
# export PARAM_AXI_HBM_BUSER_ENABLE := 0
# export PARAM_AXI_HBM_BUSER_WIDTH := 1
# export PARAM_AXI_HBM_ARUSER_ENABLE := 0
# export PARAM_AXI_HBM_ARUSER_WIDTH := 1
# export PARAM_AXI_HBM_RUSER_ENABLE := 0
# export PARAM_AXI_HBM_RUSER_WIDTH := 1
# export PARAM_AXI_HBM_MAX_BURST_LEN := 256
# export PARAM_AXI_HBM_NARROW_BURST := 0
# export PARAM_AXI_HBM_FIXED_BURST := 0
# export PARAM_AXI_HBM_WRAP_BURST := 0

# # Application configuration
# export PARAM_APP_ID := 32'h12342002
# export PARAM_APP_CTRL_ENABLE := 1
# export PARAM_APP_DMA_ENABLE := 1
# export PARAM_APP_AXIS_DIRECT_ENABLE := 1
# export PARAM_APP_AXIS_SYNC_ENABLE := 1
# export PARAM_APP_AXIS_IF_ENABLE := 1
# export PARAM_APP_STAT_ENABLE := 1
# export PARAM_APP_GPIO_IN_WIDTH := 32
# export PARAM_APP_GPIO_OUT_WIDTH := 32

# # DMA interface configuration
# export PARAM_DMA_ADDR_WIDTH := 64
# export PARAM_DMA_IMM_ENABLE := 0
# export PARAM_DMA_IMM_WIDTH := 32
# export PARAM_DMA_LEN_WIDTH := 16
# export PARAM_DMA_TAG_WIDTH := 16
# export PARAM_RAM_SEL_WIDTH := 4
# export PARAM_RAM_ADDR_WIDTH := 16
# export PARAM_RAM_SEG_COUNT := 2
# export PARAM_RAM_SEG_DATA_WIDTH := 256*2/RAM_SEG_COUNT
# export PARAM_RAM_SEG_BE_WIDTH := RAM_SEG_DATA_WIDTH/8
# export PARAM_RAM_SEG_ADDR_WIDTH := RAM_ADDR_WIDTH-$clog2(RAM_SEG_COUNT*RAM_SEG_BE_WIDTH)
# export PARAM_RAM_PIPELINE := 2

# # AXI lite interface (application control from host)
# export PARAM_AXIL_APP_CTRL_DATA_WIDTH := 32
# export PARAM_AXIL_APP_CTRL_ADDR_WIDTH := 16
# export PARAM_AXIL_APP_CTRL_STRB_WIDTH := (AXIL_APP_CTRL_DATA_WIDTH/8)

# # AXI lite interface (control to NIC)
# export PARAM_AXIL_CTRL_DATA_WIDTH := 32
# export PARAM_AXIL_CTRL_ADDR_WIDTH := 16
# export PARAM_AXIL_CTRL_STRB_WIDTH := (AXIL_CTRL_DATA_WIDTH/8)

# # Ethernet interface configuration (direct async)
# export PARAM_AXIS_DATA_WIDTH := 64
# export PARAM_AXIS_KEEP_WIDTH := AXIS_DATA_WIDTH/8
# export PARAM_AXIS_TX_USER_WIDTH := TX_TAG_WIDTH + 1
# export PARAM_AXIS_RX_USER_WIDTH := (PTP_TS_ENABLE ? PTP_TS_WIDTH : 0) + 1
# export PARAM_AXIS_RX_USE_READY := 0

# # Ethernet interface configuration (direct sync)
# export PARAM_AXIS_SYNC_DATA_WIDTH := AXIS_DATA_WIDTH
# export PARAM_AXIS_SYNC_KEEP_WIDTH := AXIS_SYNC_DATA_WIDTH/8
# export PARAM_AXIS_SYNC_TX_USER_WIDTH := AXIS_TX_USER_WIDTH
# export PARAM_AXIS_SYNC_RX_USER_WIDTH := AXIS_RX_USER_WIDTH

# # Ethernet interface configuration (interface)
# export PARAM_AXIS_IF_DATA_WIDTH := AXIS_SYNC_DATA_WIDTH*2**$clog2(PORTS_PER_IF)
# export PARAM_AXIS_IF_KEEP_WIDTH := AXIS_IF_DATA_WIDTH/8
# export PARAM_AXIS_IF_TX_ID_WIDTH := 12
# export PARAM_AXIS_IF_RX_ID_WIDTH := PORTS_PER_IF > 1 ? $clog2(PORTS_PER_IF) : 1
# export PARAM_AXIS_IF_TX_DEST_WIDTH := $clog2(PORTS_PER_IF)+4
# export PARAM_AXIS_IF_RX_DEST_WIDTH := 8
# export PARAM_AXIS_IF_TX_USER_WIDTH := AXIS_SYNC_TX_USER_WIDTH
# export PARAM_AXIS_IF_RX_USER_WIDTH := AXIS_SYNC_RX_USER_WIDTH

# # Statistics counter subsystem
# export PARAM_STAT_ENABLE := 1
# export PARAM_STAT_INC_WIDTH := 24
# export PARAM_STAT_ID_WIDTH := 12

# ifeq ($(SIM), icarus)
# 	PLUSARGS += -fst

# 	COMPILE_ARGS += $(foreach v,$(filter PARAM_%,$(.VARIABLES)),-P $(TOPLEVEL).$(subst PARAM_,,$(v))=$($(v)))

# 	ifeq ($(WAVES), 1)
# 		VERILOG_SOURCES += iverilog_dump.v
# 		COMPILE_ARGS += -s iverilog_dump
# 	endif
# else ifeq ($(SIM), verilator)
# 	COMPILE_ARGS += -Wno-SELRANGE -Wno-WIDTH

# 	COMPILE_ARGS += $(foreach v,$(filter PARAM_%,$(.VARIABLES)),-G$(subst PARAM_,,$(v))=$($(v)))

# 	ifeq ($(WAVES), 1)
# 		COMPILE_ARGS += --trace-fst
# 	endif
# endif

# include $(shell cocotb-config --makefiles)/Makefile.sim

# iverilog_dump.v:
# 	echo 'module iverilog_dump();' > $@
# 	echo 'initial begin' >> $@
# 	echo '    $$dumpfile("$(TOPLEVEL).fst");' >> $@
# 	echo '    $$dumpvars(0, $(TOPLEVEL));' >> $@
# 	echo 'end' >> $@
# 	echo 'endmodule' >> $@

# clean::
# 	@rm -rf iverilog_dump.v
# 	@rm -rf dump.fst $(TOPLEVEL).fst
