// =============================================================================
// Package      : axi_pkg.sv
// Description  : Standard UVM Package wrapping AXI VIP Components
// =============================================================================
`ifndef AXI_PKG_SV
`define AXI_PKG_SV

package axi_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "axi_item.sv"
  `include "axi_sequencer.sv"
  `include "axi_seq_lib.sv"
  `include "axi_driver.sv"
  `include "axi_monitor.sv"
  `include "axi_agent.sv"
  `include "axi_scoreboard.sv"
  `include "axi_env.sv"
  `include "axi_test.sv"

endpackage : axi_pkg

`endif // AXI_PKG_SV
