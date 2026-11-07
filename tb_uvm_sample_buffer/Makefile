# ==============================================================================
# Makefile for Dual-Port Ping-Pong Sample Buffer UVM Verification IP Testbench
# Tool: Synopsys VCS U-2023.03 & Verdi U-2023.03-SP1
# ==============================================================================

export VCS_HOME             ?= /home/student/snps_tools_target/vcs/U-2023.03
export VERDI_HOME           ?= /home/student/snps_tools_target/verdi/U-2023.03-SP1
export SNPSLMD_LICENSE_FILE ?= 27021@14.139.1.126
export PATH                 := $(VCS_HOME)/bin:$(VERDI_HOME)/bin:$(PATH)

VCS      = vcs -full64 -sverilog -timescale=1ns/1ps -ntb_opts uvm -debug_access+all -kdb +define+DUMP_FSDB
TESTNAME ?= sbuf_all_features_test
VERDI    = verdi

INCDIRS  = +incdir+../axi_uvm_tb \
           +incdir+.

RTL_SRCS = ../rtl/sample_buffer/sample_buffer.sv

TB_SRCS  = ../axi_uvm_tb/axi_if.sv \
           ../axi_uvm_tb/axi_pkg.sv \
           sbuf_dma_if.sv \
           sbuf_vga_if.sv \
           sbuf_uvm_pkg.sv \
           tb_sample_buffer_uvm_top.sv

all: run

compile:
	$(VCS) $(INCDIRS) $(RTL_SRCS) $(TB_SRCS) -l compile.log

run: compile
	./simv +UVM_TESTNAME=$(TESTNAME) +FSDB -l sim.log

tc_buf_01: compile
	./simv +UVM_TESTNAME=tc_buf_01_test +FSDB -l sim_tc_buf_01.log

tc_buf_02: compile
	./simv +UVM_TESTNAME=tc_buf_02_test +FSDB -l sim_tc_buf_02.log

tc_buf_03: compile
	./simv +UVM_TESTNAME=tc_buf_03_test +FSDB -l sim_tc_buf_03.log

tc_buf_04: compile
	./simv +UVM_TESTNAME=tc_buf_04_test +FSDB -l sim_tc_buf_04.log

tc_buf_05: compile
	./simv +UVM_TESTNAME=tc_buf_05_test +FSDB -l sim_tc_buf_05.log

verdi:
	$(VERDI) -dbdir simv.daidir -ssf sbuf_uvm.fsdb &

clean:
	rm -rf simv* csrc *.log *.key *.fsdb ucli.key vc_hdrs.h DVEfiles *.vpd novas* verdiLog
