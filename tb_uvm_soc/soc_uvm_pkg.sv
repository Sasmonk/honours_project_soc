// =============================================================================
// Package      : soc_uvm_pkg.sv
// Description  : Master UVM Package for RISC-V Real-Time Oscilloscope SoC
// =============================================================================
`ifndef SOC_UVM_PKG_SV
`define SOC_UVM_PKG_SV

package soc_uvm_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Peripheral Verification IP Packages
  import axi_pkg::*;
  import uart_uvm_pkg::*;
  import spi_uvm_pkg::*;
  import gpio_uvm_pkg::*;
  import vga_uvm_pkg::*;
  import timer_uvm_pkg::*;
  import watchdog_uvm_pkg::*;
  import fir_uvm_pkg::*;
  import dma_uvm_pkg::*;
  import sbuf_uvm_pkg::*;

  // Top-Level SoC UVM Environment & Test Components
  `include "soc_env_config.sv"
  `include "soc_virtual_sequencer.sv"
  `include "soc_vseq_lib.sv"
  `include "soc_scoreboard.sv"
  `include "soc_env.sv"
  `include "soc_tests.sv"

endpackage : soc_uvm_pkg

`endif // SOC_UVM_PKG_SV
