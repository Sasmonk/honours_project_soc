// =============================================================================
// Package      : vga_pkg.sv
// Description  : Standard UVM Package wrapping VGA VIP Components
// =============================================================================
`ifndef VGA_PKG_SV
`define VGA_PKG_SV

package vga_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "vga_item.sv"
  `include "vga_sequencer.sv"
  `include "vga_seq_lib.sv"
  `include "vga_driver.sv"
  `include "vga_monitor.sv"
  `include "vga_agent.sv"
  `include "vga_scoreboard.sv"
  `include "vga_env.sv"
  `include "vga_test.sv"

endpackage : vga_pkg

`endif // VGA_PKG_SV
