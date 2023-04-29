TOPLEVEL_LANG ?= verilog

SIM ?= verilator
WAVES ?= 0

DUT = mm2s
TOPLEVEL = mm2s_ingress_egress_fifos
module = test_$(DUT)
VERILOG_SOURCES += ../rtl/$(DUT).v
VERILOG_SOURCES += lib/verilog/glbl.v
VERILOG_SOURCES += lib/ip/xpm_cdc.sv
VERILOG_SOURCES += lib/ip/xpm_fifo.sv
VERILOG_SOURCES += lib/ip/xpm_memory.sv

# module parameters
export PARAM_MM_DATA_WIDTH := 256
export PARAM_EGRESS_DATA_WIDTH := 256
export PARAM_EGRESS_FIFO_DEPTH := 1024
export PARAM_INGRESS_DATA_WIDTH := 256
export PARAM_INGRESS_FIFO_DEPTH := 1024

ifeq ($(SIM), icarus)
	PLUSARGS += -fst

	COMPILE_ARGS += $(foreach v,$(filter PARAM_%,$(.VARIABLES)),-P $(TOPLEVEL).$(subst PARAM_,,$(v))=$($(v)))
	COMPILE_ARGS += -DOBSOLETE -DONESPIN

	ifeq ($(WAVES), 1)
		VERILOG_SOURCES += iverilog_dump.v
		COMPILE_ARGS += -s iverilog_dump
	endif
else ifeq ($(SIM), verilator)
	COMPILE_ARGS += -Wno-SELRANGE -Wno-WIDTH -Wno-CASEINCOMPLETE --timing
	COMPILE_ARGS += --bbox-unsup --assert -DOBSOLETE -DONESPIN
	COMPILE_ARGS += -Ilib/verilog

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
