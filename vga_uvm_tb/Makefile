# ==============================================================================
# Makefile for VGA UVM Verification IP Testbench
# Tool: Synopsys VCS U-2023.03
# ==============================================================================

VCS        = vcs -full64 -sverilog -timescale=1ns/1ps -ntb_opts uvm -debug_access+all -kdb +define+DUMP_FSDB
TESTNAME   ?= vga_sanity_test
VERDI      = verdi

FILES      = vga_if.sv vga_pkg.sv tb_vga_top.sv

all: run

compile:
	$(VCS) $(FILES) -l compile.log

run: compile
	./simv +UVM_TESTNAME=$(TESTNAME) -l sim.log

random: compile
	./simv +UVM_TESTNAME=vga_random_test -l sim_rand.log

verdi:
	$(VERDI) -dbdir simv.daidir -ssf uvm_vga_dump.fsdb &

clean:
	rm -rf simv* csrc *.log *.key *.fsdb ucli.key vc_hdrs.h DVEfiles *.vpd
