# ==============================================================================
# Makefile for 16-Tap FIR Digital Filter UVM Verification IP Testbench
# Tool: Synopsys VCS U-2023.03 & Verdi U-2023.03-SP1
# ==============================================================================

export VCS_HOME             ?= /home/student/snps_tools_target/vcs/U-2023.03
export VERDI_HOME           ?= /home/student/snps_tools_target/verdi/U-2023.03-SP1
export SNPSLMD_LICENSE_FILE ?= 27021@14.139.1.126
export PATH                 := $(VCS_HOME)/bin:$(VERDI_HOME)/bin:$(PATH)

VCS      = vcs -full64 -sverilog -timescale=1ns/1ps -ntb_opts uvm -debug_access+all -kdb +define+DUMP_FSDB
TESTNAME ?= fir_all_features_test
VERDI    = verdi

INCDIRS  = +incdir+../axi_uvm_tb \
           +incdir+.

RTL_SRCS = ../rtl/fir_filter/fir_filter.sv

TB_SRCS  = ../axi_uvm_tb/axi_if.sv \
           ../axi_uvm_tb/axi_pkg.sv \
           fir_sample_if.sv \
           fir_uvm_pkg.sv \
           tb_fir_uvm_top.sv

all: run

compile:
	$(VCS) $(INCDIRS) $(RTL_SRCS) $(TB_SRCS) -l compile.log

run: compile
	./simv +UVM_TESTNAME=$(TESTNAME) +FSDB -l sim.log

tc_fir_01: compile
	./simv +UVM_TESTNAME=tc_fir_01_test +FSDB -l sim_tc_fir_01.log

tc_fir_02: compile
	./simv +UVM_TESTNAME=tc_fir_02_test +FSDB -l sim_tc_fir_02.log

tc_fir_03: compile
	./simv +UVM_TESTNAME=tc_fir_03_test +FSDB -l sim_tc_fir_03.log

tc_fir_04: compile
	./simv +UVM_TESTNAME=tc_fir_04_test +FSDB -l sim_tc_fir_04.log

tc_fir_05: compile
	./simv +UVM_TESTNAME=tc_fir_05_test +FSDB -l sim_tc_fir_05.log

tc_fir_06: compile
	./simv +UVM_TESTNAME=tc_fir_06_test +FSDB -l sim_tc_fir_06.log

verdi:
	$(VERDI) -dbdir simv.daidir -ssf fir_uvm.fsdb &

clean:
	rm -rf simv* csrc *.log *.key *.fsdb ucli.key vc_hdrs.h DVEfiles *.vpd novas* verdiLog
