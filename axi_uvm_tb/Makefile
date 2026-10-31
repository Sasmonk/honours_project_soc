# ==============================================================================
# Makefile for AXI UVM Verification IP Testbench
# Tool: Synopsys VCS U-2023.03
# ==============================================================================

VCS        = vcs -full64 -sverilog -timescale=1ns/1ps -ntb_opts uvm -debug_access+all -kdb +define+DUMP_FSDB
TESTNAME   ?= axi_sanity_test
VERDI      = verdi

FILES      = axi_if.sv axi_pkg.sv tb_axi_top.sv

all: run

compile:
	$(VCS) $(FILES) -l compile.log

run: compile
	./simv +UVM_TESTNAME=$(TESTNAME) -l sim.log

random: compile
	./simv +UVM_TESTNAME=axi_random_test -l sim_rand.log

verdi:
	$(VERDI) -dbdir simv.daidir -ssf uvm_axi_dump.fsdb &

clean:
	rm -rf simv* csrc *.log *.key *.fsdb ucli.key vc_hdrs.h DVEfiles *.vpd
