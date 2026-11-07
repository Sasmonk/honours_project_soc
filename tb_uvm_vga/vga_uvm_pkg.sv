// =============================================================================
// Package      : vga_uvm_pkg.sv
// Description  : Complete UVM Verification Package for VGA Oscilloscope Controller
// =============================================================================
`ifndef VGA_UVM_PKG_SV
`define VGA_UVM_PKG_SV

package vga_uvm_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import axi_pkg::*;

  `include "vga_items.sv"
  `include "vga_sbuf_driver.sv"
  `include "vga_pixel_monitor.sv"
  `include "vga_agent.sv"
  `include "vga_scoreboard.sv"
  `include "vga_coverage.sv"
  `include "vga_seq_lib.sv"
  `include "vga_env.sv"
  `include "vga_tests.sv"

endpackage : vga_uvm_pkg

`endif // VGA_UVM_PKG_SV
