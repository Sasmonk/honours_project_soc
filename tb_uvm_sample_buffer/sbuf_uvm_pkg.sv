// =============================================================================
// Package      : sbuf_uvm_pkg.sv
// Description  : UVM Verification Package for Dual-Port Ping-Pong Sample Buffer
// =============================================================================
`ifndef SBUF_UVM_PKG_SV
`define SBUF_UVM_PKG_SV

package sbuf_uvm_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import axi_pkg::*;

  `include "sbuf_items.sv"
  `include "sbuf_dma_driver.sv"
  `include "sbuf_dma_monitor.sv"
  `include "sbuf_vga_driver.sv"
  `include "sbuf_vga_monitor.sv"
  `include "sbuf_agents.sv"
  `include "sbuf_scoreboard.sv"
  `include "sbuf_coverage.sv"
  `include "sbuf_seq_lib.sv"
  `include "sbuf_env.sv"
  `include "sbuf_tests.sv"

endpackage : sbuf_uvm_pkg

`endif // SBUF_UVM_PKG_SV
