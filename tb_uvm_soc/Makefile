# ==============================================================================
# Makefile for Top-Level SoC UVM Verification Environment
# Tool: Synopsys VCS U-2023.03 & Verdi U-2023.03-SP1
# ==============================================================================

export VCS_HOME             ?= /home/student/snps_tools_target/vcs/U-2023.03
export VERDI_HOME           ?= /home/student/snps_tools_target/verdi/U-2023.03-SP1
export SNPSLMD_LICENSE_FILE ?= 27021@14.139.1.126
export PATH                 := $(VCS_HOME)/bin:$(VERDI_HOME)/bin:$(PATH)

VCS      = vcs -full64 -sverilog -timescale=1ns/1ps -ntb_opts uvm -debug_access+all -kdb -v2k_generate +define+DUMP_FSDB
TESTNAME ?= soc_all_features_test
VERDI    = verdi

FILELIST = filelist_uvm_soc.f

all: run

compile:
	$(VCS) -f $(FILELIST) -l compile.log

run: compile
	./simv +UVM_TESTNAME=$(TESTNAME) +FSDB -l sim.log

hello: compile
	./simv +UVM_TESTNAME=soc_hello_test +FSDB -l sim_hello.log

ui: compile
	./simv +UVM_TESTNAME=soc_interactive_ui_test +FSDB -l sim_ui.log

verdi:
	$(VERDI) -dbdir simv.daidir -ssf soc_uvm.fsdb &

clean:
	rm -rf simv* csrc *.log *.key *.fsdb ucli.key vc_hdrs.h DVEfiles *.vpd novas* verdiLog *.vdb verdi_config_file
