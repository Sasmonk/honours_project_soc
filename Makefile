# ==============================================================================
# Makefile for Synopsys VCS and Verdi Simulation
# Project: Honours RISC-V Real-Time Signal Processing & VGA Oscilloscope SoC
# ==============================================================================

SHELL := /bin/bash

# ------------------------------------------------------------------------------
# Tool & Environment Configuration
# ------------------------------------------------------------------------------
export VCS_HOME             ?= /home/student/snps_tools_target/vcs/U-2023.03
export VERDI_HOME           ?= /home/student/snps_tools_target/verdi/U-2023.03-SP1
export SNPSLMD_LICENSE_FILE ?= 27021@14.139.1.126
export PATH                 := $(VCS_HOME)/bin:$(VERDI_HOME)/bin:$(PATH)

# Directory Paths
ROOT_DIR := $(shell pwd)
RUN_DIR  := $(ROOT_DIR)/run

# ------------------------------------------------------------------------------
# Testbench Selection
# Options:
#   uart          - AXI Interconnect + AXI UART (tb_axi_interconnect_uart_top.sv)
#   interconnect  - AXI Interconnect 3x14 (tb_axi_interconnect_wrap_3x14.sv)
#   timer         - System Timer IP (tb_timer.sv)
#   gpio          - GPIO Controller IP (tb_gpio.sv)
#   fir           - FIR Filter IP (tb_fir_filter.sv)
#   sample_buffer - Dual-Port Sample Buffer (tb_sample_buffer.sv)
#   dma           - Autonomous DMA Controller (tb_dma_controller.sv)
#   vga           - VGA Oscilloscope Controller (tb_vga_controller.sv)
#   watchdog      - Watchdog Safety Monitor (tb_watchdog.sv)
#   pipeline      - End-to-End SoC Pipeline (tb_soc_pipeline.sv)
# ------------------------------------------------------------------------------
TEST ?= soc

ifeq ($(TEST), uart)
    FILELIST    := filelist_uart_interconnect.f
    COMPILE_LOG := compile_uart.log
    SIM_LOG     := sim_uart.log
    WAVE_FILE   := dump.fsdb
    RC_FILE     := uart_signals.rc
else ifeq ($(TEST), interconnect)
    FILELIST    := filelist.f
    COMPILE_LOG := compile_interconnect.log
    SIM_LOG     := sim_interconnect.log
    WAVE_FILE   := dump.fsdb
    RC_FILE     := 
else ifeq ($(TEST), timer)
    FILELIST    := filelist_timer.f
    COMPILE_LOG := compile_timer.log
    SIM_LOG     := sim_timer.log
    WAVE_FILE   := dump.fsdb
    RC_FILE     := 
else ifeq ($(TEST), gpio)
    FILELIST    := filelist_gpio.f
    COMPILE_LOG := compile_gpio.log
    SIM_LOG     := sim_gpio.log
    WAVE_FILE   := dump.fsdb
    RC_FILE     := 
else ifeq ($(TEST), fir)
    FILELIST    := filelist_fir.f
    COMPILE_LOG := compile_fir.log
    SIM_LOG     := sim_fir.log
    WAVE_FILE   := dump.fsdb
    RC_FILE     := 
else ifeq ($(TEST), sample_buffer)
    FILELIST    := filelist_sample_buffer.f
    COMPILE_LOG := compile_sample_buffer.log
    SIM_LOG     := sim_sample_buffer.log
    WAVE_FILE   := dump.fsdb
    RC_FILE     := 
else ifeq ($(TEST), dma)
    FILELIST    := filelist_dma.f
    COMPILE_LOG := compile_dma.log
    SIM_LOG     := sim_dma.log
    WAVE_FILE   := dump.fsdb
    RC_FILE     := 
else ifeq ($(TEST), vga)
    FILELIST    := filelist_vga.f
    COMPILE_LOG := compile_vga.log
    SIM_LOG     := sim_vga.log
    WAVE_FILE   := dump.fsdb
    RC_FILE     := 
else ifeq ($(TEST), vga_live)
    FILELIST    := filelist_vga_live.f
    COMPILE_LOG := compile_vga_live.log
    SIM_LOG     := sim_vga_live.log
    WAVE_FILE   := dump.fsdb
    RC_FILE     := 
else ifeq ($(TEST), watchdog)
    FILELIST    := filelist_watchdog.f
    COMPILE_LOG := compile_watchdog.log
    SIM_LOG     := sim_watchdog.log
    WAVE_FILE   := dump.fsdb
    RC_FILE     := 
else ifeq ($(TEST), pipeline)
    FILELIST    := filelist_pipeline.f
    COMPILE_LOG := compile_pipeline.log
    SIM_LOG     := sim_pipeline.log
    WAVE_FILE   := dump.fsdb
    RC_FILE     := 
else ifeq ($(TEST), soc)
    FILELIST    := filelist_soc.f
    COMPILE_LOG := compile_soc.log
    SIM_LOG     := sim_soc.log
    WAVE_FILE   := dump.fsdb
    RC_FILE     := 
else ifeq ($(TEST), hello)
    FILELIST    := filelist_soc_c_hello.f
    COMPILE_LOG := compile_c_hello.log
    SIM_LOG     := sim_c_hello.log
    WAVE_FILE   := dump.fsdb
    RC_FILE     := c_hello_signals.rc 
else
    $(error Unknown TEST '$(TEST)'. Valid options are: uart, interconnect, timer, gpio, fir, sample_buffer, dma, vga, vga_live, watchdog, pipeline, soc, hello)
endif

# Extra flags for tests with C++/DPI or external libraries
ifeq ($(TEST), vga_live)
    VCS_EXTRA_FLAGS := -CFLAGS "-std=c++11 -DENABLE_VGA_OPENGL -I$(ROOT_DIR)/tb/vga_simulator -I$(ROOT_DIR)/tb/vga_simulator/freeglut/include" \
                       -LDFLAGS "-Wl,--whole-archive $(ROOT_DIR)/tb/vga_simulator/freeglut/lib64/libglut.a -Wl,--no-whole-archive -lGLU -lGL -lX11 -lXrandr -lXxf86vm -lXi -lpthread"
endif

# VCS Compilation and Simulation Flags
VCS_FLAGS := -full64 -sverilog -timescale=1ns/1ps -debug_access+all -kdb -v2k_generate
SIM_FLAGS := -no_save
VERDI_BIN ?= $(VERDI_HOME)/bin/verdi

.PHONY: all help compile sim run verdi wave clean \
        uart interconnect timer gpio fir sample_buffer dma vga vga-live vga-live-gui vga-live-verdi watchdog pipeline test-all \
        soc soc-compile soc-sim soc-verdi hello hello-verdi \
        uart-verdi interconnect-verdi timer-verdi gpio-verdi fir-verdi \
        sample_buffer-verdi dma-verdi vga-verdi watchdog-verdi pipeline-verdi \
        uvm-soc uvm-soc-hello uvm-soc-ui uvm-soc-verdi

# Default target: display help menu
all: help

# ------------------------------------------------------------------------------
# Generic Targets (Controlled via TEST=<name>)
# ------------------------------------------------------------------------------
compile:
	@echo "=========================================================="
	@echo " Compiling [$(TEST)] with Synopsys VCS..."
	@echo "=========================================================="
	cd $(RUN_DIR) && vcs $(VCS_FLAGS) $(VCS_EXTRA_FLAGS) -f $(FILELIST) -l $(COMPILE_LOG)

sim:
	@echo "=========================================================="
	@echo " Running Simulation for [$(TEST)]..."
	@echo "=========================================================="
	cd $(RUN_DIR) && ./simv $(SIM_FLAGS) -l $(SIM_LOG)

run: compile sim

verdi wave:
	@echo "=========================================================="
	@echo " Launching Verdi GUI for [$(TEST)]..."
	@echo "=========================================================="
	cd $(RUN_DIR) && $(VERDI_BIN) -dbdir simv.daidir -ssf $(WAVE_FILE) $(if $(RC_FILE),-sswr $(RC_FILE),) &

# ------------------------------------------------------------------------------
# Shortcut Targets for Individual IP Tests
# ------------------------------------------------------------------------------
timer:
	$(MAKE) run TEST=timer

gpio:
	$(MAKE) run TEST=gpio

fir:
	$(MAKE) run TEST=fir

sample_buffer:
	$(MAKE) run TEST=sample_buffer

dma:
	$(MAKE) run TEST=dma

vga:
	$(MAKE) run TEST=vga

vga-live:
	$(MAKE) run TEST=vga_live

vga-live-gui:
	VGA_GUI=1 $(MAKE) run TEST=vga_live

watchdog:
	$(MAKE) run TEST=watchdog

uart:
	$(MAKE) run TEST=uart

interconnect:
	$(MAKE) run TEST=interconnect

pipeline:
	$(MAKE) run TEST=pipeline

# ------------------------------------------------------------------------------
# Shortcut Targets for RISC-V SoC Top-Level
# ------------------------------------------------------------------------------
soc:
	$(MAKE) run TEST=soc

soc-compile:
	$(MAKE) compile TEST=soc

soc-sim:
	$(MAKE) sim TEST=soc

soc-verdi:
	$(MAKE) verdi TEST=soc

# Shortcut Targets for RISC-V C Firmware Hello World
hello:
	$(MAKE) run TEST=hello

hello-verdi:
	$(MAKE) verdi TEST=hello

# Shortcut Targets to launch Verdi GUI for individual IP tests
uart-verdi:
	$(MAKE) verdi TEST=uart

interconnect-verdi:
	$(MAKE) verdi TEST=interconnect

pipeline-verdi:
	$(MAKE) verdi TEST=pipeline

timer-verdi:
	$(MAKE) verdi TEST=timer

gpio-verdi:
	$(MAKE) verdi TEST=gpio

fir-verdi:
	$(MAKE) verdi TEST=fir

sample_buffer-verdi:
	$(MAKE) verdi TEST=sample_buffer

dma-verdi:
	$(MAKE) verdi TEST=dma

vga-verdi:
	$(MAKE) verdi TEST=vga

vga-live-verdi:
	$(MAKE) verdi TEST=vga_live

watchdog-verdi:
	$(MAKE) verdi TEST=watchdog

# ------------------------------------------------------------------------------
# Run All Unit & Pipeline Tests
# ------------------------------------------------------------------------------
test-all:
	@echo "=================================================================="
	@echo " RUNNING ALL UNIT & PIPELINE VERIFICATION SUITES WITH VCS         "
	@echo "=================================================================="
	$(MAKE) run TEST=timer
	$(MAKE) run TEST=gpio
	$(MAKE) run TEST=fir
	$(MAKE) run TEST=sample_buffer
	$(MAKE) run TEST=dma
	$(MAKE) run TEST=vga
	$(MAKE) run TEST=watchdog
	$(MAKE) run TEST=pipeline
	@echo "=================================================================="
	@echo " ALL IP & SYSTEM PIPELINE TESTS COMPLETED SUCCESSFULLY!           "
	@echo "=================================================================="

# ------------------------------------------------------------------------------
# UVM VIP Verification Targets
# ------------------------------------------------------------------------------
uvm-axi:
	@echo "=========================================================="
	@echo " Running AXI UVM VIP Verification Suite                   "
	@echo "=========================================================="
	cd $(ROOT_DIR)/axi_uvm_tb && $(MAKE) run

uvm-axi-rand:
	@echo "=========================================================="
	@echo " Running AXI UVM VIP Random Test                          "
	@echo "=========================================================="
	cd $(ROOT_DIR)/axi_uvm_tb && $(MAKE) random

uvm-axi-verdi:
	cd $(ROOT_DIR)/axi_uvm_tb && $(MAKE) verdi

# ------------------------------------------------------------------------------
# 16550 UART UVM VIP Verification Targets (TC_COM_01, TC_COM_02, All Features)
# ------------------------------------------------------------------------------
uvm-uart:
	@echo "=========================================================="
	@echo " Running 16550 UART UVM VIP All Features Test Suite       "
	@echo "=========================================================="
	cd $(ROOT_DIR)/tb_uvm_uart && $(MAKE) run

uvm-uart-tc-com-01:
	@echo "=========================================================="
	@echo " Running TC_COM_01: 16550 UART TX Framing Verification    "
	@echo "=========================================================="
	cd $(ROOT_DIR)/tb_uvm_uart && $(MAKE) tc_com_01

uvm-uart-tc-com-02:
	@echo "=========================================================="
	@echo " Running TC_COM_02: UART RX FIFO & IRQ Verification       "
	@echo "=========================================================="
	cd $(ROOT_DIR)/tb_uvm_uart && $(MAKE) tc_com_02

uvm-uart-verdi:
	cd $(ROOT_DIR)/tb_uvm_uart && $(MAKE) verdi

# ------------------------------------------------------------------------------
# GPIO UVM VIP Verification Targets (TC_COM_03, TC_COM_04, All Features)
# ------------------------------------------------------------------------------
uvm-gpio:
	@echo "=========================================================="
	@echo " Running GPIO UVM VIP All Features Test Suite             "
	@echo "=========================================================="
	cd $(ROOT_DIR)/tb_uvm_gpio && $(MAKE) run

uvm-gpio-tc-com-03:
	@echo "=========================================================="
	@echo " Running TC_COM_03: GPIO Push-Button Sync & IRQ Test      "
	@echo "=========================================================="
	cd $(ROOT_DIR)/tb_uvm_gpio && $(MAKE) tc_com_03

uvm-gpio-tc-com-04:
	@echo "=========================================================="
	@echo " Running TC_COM_04: GPIO Status LED Output Drive Test     "
	@echo "=========================================================="
	cd $(ROOT_DIR)/tb_uvm_gpio && $(MAKE) tc_com_04

uvm-gpio-verdi:
	cd $(ROOT_DIR)/tb_uvm_gpio && $(MAKE) verdi

uvm-timer:
	@echo "=========================================================="
	@echo " Running System Timer UVM VIP All Features Test Suite     "
	@echo "=========================================================="
	cd $(ROOT_DIR)/tb_uvm_timer && $(MAKE) run

uvm-timer-tc-acq-01:
	@echo "=========================================================="
	@echo " Running TC_ACQ_01: Cycle-Accurate Sample Rate Pacing Test"
	@echo "=========================================================="
	cd $(ROOT_DIR)/tb_uvm_timer && $(MAKE) tc_acq_01

uvm-timer-verdi:
	cd $(ROOT_DIR)/tb_uvm_timer && $(MAKE) verdi

uvm-watchdog:
	@echo "=========================================================="
	@echo " Running Watchdog Safety Monitor UVM VIP Test Suite       "
	@echo "=========================================================="
	cd $(ROOT_DIR)/tb_uvm_watchdog && $(MAKE) run

uvm-watchdog-tc-wdt-01:
	@echo "=========================================================="
	@echo " Running TC_WDT_01: Watchdog Keep-Alive & Reset Trip Test "
	@echo "=========================================================="
	cd $(ROOT_DIR)/tb_uvm_watchdog && $(MAKE) tc_wdt_01

uvm-watchdog-verdi:
	cd $(ROOT_DIR)/tb_uvm_watchdog && $(MAKE) verdi

uvm-spi:
	@echo "=========================================================="
	@echo " Running SPI Master Controller UVM VIP All Features Suite "
	@echo "=========================================================="
	cd $(ROOT_DIR)/tb_uvm_spi && $(MAKE) run

uvm-spi-tc-acq-02:
	@echo "=========================================================="
	@echo " Running TC_ACQ_02: Autonomous SPI Hardware Auto-Trigger  "
	@echo "=========================================================="
	cd $(ROOT_DIR)/tb_uvm_spi && $(MAKE) tc_acq_02

uvm-spi-tc-acq-03:
	@echo "=========================================================="
	@echo " Running TC_ACQ_03: SPI Prescaler Frequency & Duty Sweep  "
	@echo "=========================================================="
	cd $(ROOT_DIR)/tb_uvm_spi && $(MAKE) tc_acq_03

uvm-spi-tc-acq-04:
	@echo "=========================================================="
	@echo " Running TC_ACQ_04: RX FIFO 32-Entry Watermark & Overflow "
	@echo "=========================================================="
	cd $(ROOT_DIR)/tb_uvm_spi && $(MAKE) tc_acq_04

uvm-spi-tc-acq-05:
	@echo "=========================================================="
	@echo " Running TC_ACQ_05: Manual SPI Command Transmission       "
	@echo "=========================================================="
	cd $(ROOT_DIR)/tb_uvm_spi && $(MAKE) tc_acq_05

uvm-spi-tc-acq-06:
	@echo "=========================================================="
	@echo " Running TC_ACQ_06: SPI Chip-Select Lead / Trail Timing   "
	@echo "=========================================================="
	cd $(ROOT_DIR)/tb_uvm_spi && $(MAKE) tc_acq_06

uvm-spi-verdi:
	cd $(ROOT_DIR)/tb_uvm_spi && $(MAKE) verdi

uvm-fir:
	@echo "=========================================================="
	@echo " Running 16-Tap FIR Digital Filter UVM All Features Suite "
	@echo "=========================================================="
	cd $(ROOT_DIR)/tb_uvm_fir && $(MAKE) run

uvm-fir-tc-fir-01:
	@echo "=========================================================="
	@echo " Running TC_FIR_01: Q1.15 Impulse Response Matching       "
	@echo "=========================================================="
	cd $(ROOT_DIR)/tb_uvm_fir && $(MAKE) tc_fir_01

uvm-fir-tc-fir-02:
	@echo "=========================================================="
	@echo " Running TC_FIR_02: Hardware Bypass vs Active Filter Mode "
	@echo "=========================================================="
	cd $(ROOT_DIR)/tb_uvm_fir && $(MAKE) tc_fir_02

uvm-fir-tc-fir-03:
	@echo "=========================================================="
	@echo " Running TC_FIR_03: Dynamic Runtime Tap Scaling (4->12)   "
	@echo "=========================================================="
	cd $(ROOT_DIR)/tb_uvm_fir && $(MAKE) tc_fir_03

uvm-fir-tc-fir-04:
	@echo "=========================================================="
	@echo " Running TC_FIR_04: Overflow & Saturation Clamping SVA    "
	@echo "=========================================================="
	cd $(ROOT_DIR)/tb_uvm_fir && $(MAKE) tc_fir_04

uvm-fir-tc-fir-05:
	@echo "=========================================================="
	@echo " Running TC_FIR_05: Low-Pass Noise Attenuation vs Golden  "
	@echo "=========================================================="
	cd $(ROOT_DIR)/tb_uvm_fir && $(MAKE) tc_fir_05

uvm-fir-tc-fir-06:
	@echo "=========================================================="
	@echo " Running TC_FIR_06: Direct Memory-Mapped Sample Injection "
	@echo "=========================================================="
	cd $(ROOT_DIR)/tb_uvm_fir && $(MAKE) tc_fir_06

uvm-fir-verdi:
	cd $(ROOT_DIR)/tb_uvm_fir && $(MAKE) verdi

uvm-sample-buffer:
	@echo "=========================================================="
	@echo " Running Dual-Port Sample Buffer UVM All Features Suite   "
	@echo "=========================================================="
	cd $(ROOT_DIR)/tb_uvm_sample_buffer && $(MAKE) run

uvm-sample-buffer-tc-buf-01:
	@echo "=========================================================="
	@echo " Running TC_BUF_01: Tear-Free Rotation Synchronized VSYNC "
	@echo "=========================================================="
	cd $(ROOT_DIR)/tb_uvm_sample_buffer && $(MAKE) tc_buf_01

uvm-sample-buffer-tc-buf-02:
	@echo "=========================================================="
	@echo " Running TC_BUF_02: Write-Hold Freeze Mode Check          "
	@echo "=========================================================="
	cd $(ROOT_DIR)/tb_uvm_sample_buffer && $(MAKE) tc_buf_02

uvm-sample-buffer-tc-buf-03:
	@echo "=========================================================="
	@echo " Running TC_BUF_03: Concurrent 3-Port Access Stress       "
	@echo "=========================================================="
	cd $(ROOT_DIR)/tb_uvm_sample_buffer && $(MAKE) tc_buf_03

uvm-sample-buffer-tc-buf-04:
	@echo "=========================================================="
	@echo " Running TC_BUF_04: Manual Bank Swap Override Check       "
	@echo "=========================================================="
	cd $(ROOT_DIR)/tb_uvm_sample_buffer && $(MAKE) tc_buf_04

uvm-sample-buffer-tc-buf-05:
	@echo "=========================================================="
	@echo " Running TC_BUF_05: Asynchronous CDC SVA Verification     "
	@echo "=========================================================="
	cd $(ROOT_DIR)/tb_uvm_sample_buffer && $(MAKE) tc_buf_05

uvm-sample-buffer-verdi:
	cd $(ROOT_DIR)/tb_uvm_sample_buffer && $(MAKE) verdi

# ------------------------------------------------------------------------------
# UVM Verification Targets for VGA Controller IP (tb_uvm_vga)
# ------------------------------------------------------------------------------
uvm-vga:
	@echo "=========================================================="
	@echo " Compiling and Running VGA Oscilloscope UVM Verification  "
	@echo "=========================================================="
	cd $(ROOT_DIR)/tb_uvm_vga && $(MAKE) run

uvm-vga-tc-vga-01:
	@echo "=========================================================="
	@echo " Running TC_VGA_01: VESA 640x480 @ 60Hz Timing Compliance "
	@echo "=========================================================="
	cd $(ROOT_DIR)/tb_uvm_vga && $(MAKE) tc_vga_01

uvm-vga-tc-vga-02:
	@echo "=========================================================="
	@echo " Running TC_VGA_02: Rising / Falling Trigger Edge         "
	@echo "=========================================================="
	cd $(ROOT_DIR)/tb_uvm_vga && $(MAKE) tc_vga_02

uvm-vga-tc-vga-03:
	@echo "=========================================================="
	@echo " Running TC_VGA_03: Holdoff Timeout & Free-Run Fallback   "
	@echo "=========================================================="
	cd $(ROOT_DIR)/tb_uvm_vga && $(MAKE) tc_vga_03

uvm-vga-tc-vga-04:
	@echo "=========================================================="
	@echo " Running TC_VGA_04: VDIV & TDIV Scaling Sweep             "
	@echo "=========================================================="
	cd $(ROOT_DIR)/tb_uvm_vga && $(MAKE) tc_vga_04

uvm-vga-tc-vga-05:
	@echo "=========================================================="
	@echo " Running TC_VGA_05: Software UI Color Customization       "
	@echo "=========================================================="
	cd $(ROOT_DIR)/tb_uvm_vga && $(MAKE) tc_vga_05

uvm-vga-tc-vga-06:
	@echo "=========================================================="
	@echo " Running TC_VGA_06: Voltage Cursors A & B Overlay         "
	@echo "=========================================================="
	cd $(ROOT_DIR)/tb_uvm_vga && $(MAKE) tc_vga_06

uvm-vga-verdi:
	cd $(ROOT_DIR)/tb_uvm_vga && $(MAKE) verdi

# ------------------------------------------------------------------------------
# UVM Verification Targets for Autonomous DMA Controller IP (tb_uvm_dma)
# ------------------------------------------------------------------------------
uvm-dma:
	@echo "=========================================================="
	@echo " Compiling and Running DMA Controller UVM Verification    "
	@echo "=========================================================="
	cd $(ROOT_DIR)/tb_uvm_dma && $(MAKE) run

uvm-dma-tc-dma-01:
	@echo "=========================================================="
	@echo " Running TC_DMA_01: Streaming Pipeline (ADC/FIR->SBUF)    "
	@echo "=========================================================="
	cd $(ROOT_DIR)/tb_uvm_dma && $(MAKE) tc_dma_01

uvm-dma-tc-dma-02:
	@echo "=========================================================="
	@echo " Running TC_DMA_02: AXI4 Master Block Move                "
	@echo "=========================================================="
	cd $(ROOT_DIR)/tb_uvm_dma && $(MAKE) tc_dma_02

uvm-dma-tc-dma-03:
	@echo "=========================================================="
	@echo " Running TC_DMA_03: Rate-Paced vs Free-Running Transfer   "
	@echo "=========================================================="
	cd $(ROOT_DIR)/tb_uvm_dma && $(MAKE) tc_dma_03

uvm-dma-tc-dma-04:
	@echo "=========================================================="
	@echo " Running TC_DMA_04: Auto-Reload Ring Buffer Mode          "
	@echo "=========================================================="
	cd $(ROOT_DIR)/tb_uvm_dma && $(MAKE) tc_dma_04

uvm-dma-tc-dma-05:
	@echo "=========================================================="
	@echo " Running TC_DMA_05: Bus Stall Timeout & Watchdog Recovery "
	@echo "=========================================================="
	cd $(ROOT_DIR)/tb_uvm_dma && $(MAKE) tc_dma_05

uvm-dma-tc-dma-06:
	@echo "=========================================================="
	@echo " Running TC_DMA_06: FIFO Underrun / Error Recovery        "
	@echo "=========================================================="
	cd $(ROOT_DIR)/tb_uvm_dma && $(MAKE) tc_dma_06

uvm-dma-tc-dma-07:
	@echo "=========================================================="
	@echo " Running TC_DMA_07: Fixed vs Incrementing Addressing      "
	@echo "=========================================================="
	cd $(ROOT_DIR)/tb_uvm_dma && $(MAKE) tc_dma_07

uvm-dma-verdi:
	cd $(ROOT_DIR)/tb_uvm_dma && $(MAKE) verdi

# ------------------------------------------------------------------------------
# Top-Level SoC UVM Verification Targets (tb_uvm_soc)
# ------------------------------------------------------------------------------
uvm-soc:
	@echo "=========================================================="
	@echo " Running Top-Level SoC UVM All Features Test Suite        "
	@echo "=========================================================="
	cd $(ROOT_DIR)/tb_uvm_soc && $(MAKE) run

uvm-soc-hello:
	@echo "=========================================================="
	@echo " Running Top-Level SoC UVM Firmware Hello Boot Test       "
	@echo "=========================================================="
	cd $(ROOT_DIR)/tb_uvm_soc && $(MAKE) hello

uvm-soc-ui:
	@echo "=========================================================="
	@echo " Running Top-Level SoC UVM Interactive UI Test            "
	@echo "=========================================================="
	cd $(ROOT_DIR)/tb_uvm_soc && $(MAKE) ui

uvm-soc-verdi:
	cd $(ROOT_DIR)/tb_uvm_soc && $(MAKE) verdi

# ------------------------------------------------------------------------------
# Cleanup
# ------------------------------------------------------------------------------
clean:
	@echo "Cleaning simulation files in $(RUN_DIR) and $(ROOT_DIR)..."
	rm -rf $(RUN_DIR)/simv $(RUN_DIR)/simv.daidir $(RUN_DIR)/csrc
	rm -rf $(RUN_DIR)/*.log $(RUN_DIR)/*.fsdb $(RUN_DIR)/novas* $(RUN_DIR)/verdiLog $(RUN_DIR)/ucli.key
	rm -rf $(RUN_DIR)/*.bmp $(RUN_DIR)/*.ppm $(ROOT_DIR)/*.bmp $(ROOT_DIR)/*.ppm
	rm -rf $(ROOT_DIR)/*.log $(ROOT_DIR)/simv $(ROOT_DIR)/simv.daidir $(ROOT_DIR)/csrc $(ROOT_DIR)/verdiLog $(ROOT_DIR)/fsdbreportLog $(ROOT_DIR)/ucli.key
	@echo "Cleaning UVM simulation build directories..."
	rm -rf $(ROOT_DIR)/tb_uvm_*/simv $(ROOT_DIR)/tb_uvm_*/simv.daidir $(ROOT_DIR)/tb_uvm_*/csrc
	rm -rf $(ROOT_DIR)/tb_uvm_*/*.log $(ROOT_DIR)/tb_uvm_*/*.fsdb $(ROOT_DIR)/tb_uvm_*/novas* $(ROOT_DIR)/tb_uvm_*/verdiLog $(ROOT_DIR)/tb_uvm_*/ucli.key $(ROOT_DIR)/tb_uvm_*/vc_hdrs.h $(ROOT_DIR)/tb_uvm_*/*.vcd $(ROOT_DIR)/tb_uvm_*/*.vdb
	rm -rf $(ROOT_DIR)/axi_uvm_tb/simv $(ROOT_DIR)/axi_uvm_tb/simv.daidir $(ROOT_DIR)/axi_uvm_tb/csrc
	rm -rf $(ROOT_DIR)/axi_uvm_tb/*.log $(ROOT_DIR)/axi_uvm_tb/*.fsdb $(ROOT_DIR)/axi_uvm_tb/novas* $(ROOT_DIR)/axi_uvm_tb/verdiLog $(ROOT_DIR)/axi_uvm_tb/ucli.key $(ROOT_DIR)/axi_uvm_tb/vc_hdrs.h
	@echo "Clean completed."

# ------------------------------------------------------------------------------
# Help Menu
# ------------------------------------------------------------------------------
help:
	@echo "========================================================================"
	@echo "      RISC-V Real-Time Oscilloscope SoC Simulation Makefile             "
	@echo "========================================================================"
	@echo " Usage:"
	@echo "   make <target> [TEST=<test_name>]"
	@echo ""
	@echo " Available IP Verification Shortcuts:"
	@echo "   make timer         - Compile & Run System Timer test"
	@echo "   make gpio          - Compile & Run GPIO test"
	@echo "   make fir           - Compile & Run FIR Filter test"
	@echo "   make sample_buffer - Compile & Run Dual-Port Sample Buffer test"
	@echo "   make dma           - Compile & Run Autonomous DMA Controller test"
	@echo "   make vga           - Compile & Run VGA Controller timing test"
	@echo "   make vga-live      - Compile & Run Live VGA Simulator (saves frame BMP/PPM)"
	@echo "   make vga-live-gui  - Run Live VGA Simulator with interactive OpenGL window"
	@echo "   make watchdog      - Compile & Run Watchdog Monitor test"
	@echo "   make uart          - Compile & Run AXI UART test"
	@echo "   make interconnect  - Compile & Run AXI Interconnect test"
	@echo "   make pipeline      - Compile & Run End-to-End SoC Pipeline test"
	@echo "   make soc           - Compile & Run Complete Top-Level SoC test"
	@echo "   make hello         - Compile C firmware & Run UART Hello World test"
	@echo "   make test-all      - Run all testbenches sequentially"
	@echo "   make uvm-soc       - Compile & Run Top-Level SoC UVM Verification (All Features)"
	@echo "   make uvm-soc-hello - Compile & Run Top-Level SoC UVM Firmware Hello Boot Test"
	@echo "   make uvm-soc-ui    - Compile & Run Top-Level SoC UVM Interactive UI Test"
	@echo ""
	@echo " Verdi Waveform Viewing:"
	@echo "   make verdi         - Open Verdi GUI for current TEST (default: soc)"
	@echo "   make wave          - Alias for 'make verdi'"
	@echo "   make soc-verdi     - Open Verdi GUI for Top-Level SoC waveform"
	@echo "   make hello-verdi   - Open Verdi GUI for C Hello World test waveform"
	@echo "   make vga-live-verdi- Open Verdi GUI for Live VGA simulation waveform"
	@echo "   make <ip>-verdi    - Open Verdi GUI for specific IP (e.g. uart-verdi, dma-verdi)"
	@echo "   make verdi TEST=<name> - Open Verdi GUI for specified test"
	@echo ""
	@echo " Other Commands:"
	@echo "   make clean         - Remove simulation outputs, logs, waveforms"
	@echo "   make help          - Display this help message"
	@echo "========================================================================"
