# ==============================================================================
# Makefile for VGA Oscilloscope Controller UVM Verification IP Testbench
# Tool: Synopsys VCS U-2023.03 & Verdi U-2023.03-SP1
# ==============================================================================

export VCS_HOME             ?= /home/student/snps_tools_target/vcs/U-2023.03
export VERDI_HOME           ?= /home/student/snps_tools_target/verdi/U-2023.03-SP1
export SNPSLMD_LICENSE_FILE ?= 27021@14.139.1.126
export PATH                 := $(VCS_HOME)/bin:$(VERDI_HOME)/bin:$(PATH)

VCS      = vcs -full64 -sverilog -timescale=1ns/1ps -ntb_opts uvm -debug_access+all -kdb +define+DUMP_FSDB
TESTNAME ?= vga_all_features_test
VERDI    = verdi

INCDIRS  = +incdir+../axi_uvm_tb \
           +incdir+.

RTL_SRCS = ../rtl/vga_controller/vga_controller.sv

TB_SRCS  = ../axi_uvm_tb/axi_if.sv \
           ../axi_uvm_tb/axi_pkg.sv \
           vga_pixel_if.sv \
           vga_uvm_pkg.sv \
           tb_vga_uvm_top.sv

all: run

compile:
	$(VCS) $(INCDIRS) $(RTL_SRCS) $(TB_SRCS) -l compile.log

run: compile
	./simv +UVM_TESTNAME=$(TESTNAME) +FSDB -l sim.log

tc_vga_01: compile
	./simv +UVM_TESTNAME=tc_vga_01_test +FSDB -l sim_tc_vga_01.log

tc_vga_02: compile
	./simv +UVM_TESTNAME=tc_vga_02_test +FSDB -l sim_tc_vga_02.log

tc_vga_03: compile
	./simv +UVM_TESTNAME=tc_vga_03_test +FSDB -l sim_tc_vga_03.log

tc_vga_04: compile
	./simv +UVM_TESTNAME=tc_vga_04_test +FSDB -l sim_tc_vga_04.log

tc_vga_05: compile
	./simv +UVM_TESTNAME=tc_vga_05_test +FSDB -l sim_tc_vga_05.log

tc_vga_06: compile
	./simv +UVM_TESTNAME=tc_vga_06_test +FSDB -l sim_tc_vga_06.log

verdi:
	$(VERDI) -dbdir simv.daidir -ssf vga_uvm.fsdb &

clean:
	rm -rf simv* csrc *.log *.key *.fsdb ucli.key vc_hdrs.h DVEfiles *.vpd novas* verdiLog
