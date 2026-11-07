# ==============================================================================
# Makefile for Autonomous DMA Controller UVM Verification IP Testbench
# Tool: Synopsys VCS U-2023.03 & Verdi U-2023.03-SP1
# ==============================================================================

export VCS_HOME             ?= /home/student/snps_tools_target/vcs/U-2023.03
export VERDI_HOME           ?= /home/student/snps_tools_target/verdi/U-2023.03-SP1
export SNPSLMD_LICENSE_FILE ?= 27021@14.139.1.126
export PATH                 := $(VCS_HOME)/bin:$(VERDI_HOME)/bin:$(PATH)

VCS      = vcs -full64 -sverilog -timescale=1ns/1ps -ntb_opts uvm -debug_access+all -kdb +define+DUMP_FSDB
TESTNAME ?= dma_all_features_test
VERDI    = verdi

INCDIRS  = +incdir+../axi_uvm_tb \
           +incdir+.

RTL_SRCS = ../rtl/dma_controller/dma_controller.sv

TB_SRCS  = ../axi_uvm_tb/axi_if.sv \
           ../axi_uvm_tb/axi_pkg.sv \
           dma_stream_if.sv \
           dma_uvm_pkg.sv \
           tb_dma_uvm_top.sv

all: run

compile:
	$(VCS) $(INCDIRS) $(RTL_SRCS) $(TB_SRCS) -l compile.log

run: compile
	./simv +UVM_TESTNAME=$(TESTNAME) +FSDB -l sim.log

tc_dma_01: compile
	./simv +UVM_TESTNAME=tc_dma_01_test +FSDB -l sim_tc_dma_01.log

tc_dma_02: compile
	./simv +UVM_TESTNAME=tc_dma_02_test +FSDB -l sim_tc_dma_02.log

tc_dma_03: compile
	./simv +UVM_TESTNAME=tc_dma_03_test +FSDB -l sim_tc_dma_03.log

tc_dma_04: compile
	./simv +UVM_TESTNAME=tc_dma_04_test +FSDB -l sim_tc_dma_04.log

tc_dma_05: compile
	./simv +UVM_TESTNAME=tc_dma_05_test +FSDB -l sim_tc_dma_05.log

tc_dma_06: compile
	./simv +UVM_TESTNAME=tc_dma_06_test +FSDB -l sim_tc_dma_06.log

tc_dma_07: compile
	./simv +UVM_TESTNAME=tc_dma_07_test +FSDB -l sim_tc_dma_07.log

verdi:
	$(VERDI) -dbdir simv.daidir -ssf dma_uvm.fsdb &

clean:
	rm -rf simv simv.daidir csrc *.log *.fsdb *.vcd ucli.key vc_hdrs.h verdiLog novas.*
