# ==============================================================================
# Makefile for FIR UVM Verification IP Testbench
# Tool: Synopsys VCS U-2023.03
# ==============================================================================

VCS        = vcs -full64 -sverilog -timescale=1ns/1ps -ntb_opts uvm -debug_access+all -kdb +define+DUMP_FSDB
TESTNAME   ?= fir_sanity_test
VERDI      = verdi

FILES      = fir_if.sv fir_pkg.sv tb_fir_top.sv

all: run

compile:
	$(VCS) $(FILES) -l compile.log

run: compile
	./simv +UVM_TESTNAME=$(TESTNAME) -l sim.log

random: compile
	./simv +UVM_TESTNAME=fir_random_test -l sim_rand.log

verdi:
	$(VERDI) -dbdir simv.daidir -ssf uvm_fir_dump.fsdb &

clean:
	rm -rf simv* csrc *.log *.key *.fsdb ucli.key vc_hdrs.h DVEfiles *.vpd
