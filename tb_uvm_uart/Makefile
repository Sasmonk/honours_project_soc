# ==============================================================================
# Makefile for 16550 UART UVM Verification IP Testbench
# Tool: Synopsys VCS U-2023.03 & Verdi U-2023.03-SP1
# ==============================================================================

export VCS_HOME             ?= /home/student/snps_tools_target/vcs/U-2023.03
export VERDI_HOME           ?= /home/student/snps_tools_target/verdi/U-2023.03-SP1
export SNPSLMD_LICENSE_FILE ?= 27021@14.139.1.126
export PATH                 := $(VCS_HOME)/bin:$(VERDI_HOME)/bin:$(PATH)

VCS      = vcs -full64 -sverilog -timescale=1ns/1ps -ntb_opts uvm -debug_access+all -kdb +define+DUMP_FSDB
TESTNAME ?= uart_all_features_test
VERDI    = verdi

INCDIRS  = +incdir+../rtl/axi_uart/include \
           +incdir+../rtl/axi_uart/rtl \
           +incdir+../axi_uvm_tb \
           +incdir+.

RTL_SRCS = ../rtl/axi_uart/rtl/axi_internal_fifo.v \
           ../rtl/axi_uart/rtl/uart_parity_bit_compute.v \
           ../rtl/axi_uart/rtl/uart_receiver.v \
           ../rtl/axi_uart/rtl/uart_transmitter.v \
           ../rtl/axi_uart/rtl/uart_controller.v \
           ../rtl/axi_uart/rtl/axi_uart_top.v

TB_SRCS  = ../axi_uvm_tb/axi_if.sv \
           ../axi_uvm_tb/axi_pkg.sv \
           uart_serial_if.sv \
           uart_uvm_pkg.sv \
           tb_uart_uvm_top.sv

all: run

compile:
	$(VCS) $(INCDIRS) $(RTL_SRCS) $(TB_SRCS) -l compile.log

run: compile
	./simv +UVM_TESTNAME=$(TESTNAME) +FSDB -l sim.log

tc_com_01: compile
	./simv +UVM_TESTNAME=tc_com_01_test +FSDB -l sim_tc_com_01.log

tc_com_02: compile
	./simv +UVM_TESTNAME=tc_com_02_test +FSDB -l sim_tc_com_02.log

verdi:
	$(VERDI) -dbdir simv.daidir -ssf uart_uvm.fsdb &

clean:
	rm -rf simv* csrc *.log *.key *.fsdb ucli.key vc_hdrs.h DVEfiles *.vpd novas* verdiLog
