// =============================================================================
// Package      : fir_pkg.sv
// Description  : Standard UVM Package wrapping FIR VIP Components
// =============================================================================
`ifndef FIR_PKG_SV
`define FIR_PKG_SV

package fir_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "fir_item.sv"
  `include "fir_sequencer.sv"
  `include "fir_seq_lib.sv"
  `include "fir_driver.sv"
  `include "fir_monitor.sv"
  `include "fir_agent.sv"
  `include "fir_scoreboard.sv"
  `include "fir_env.sv"
  `include "fir_test.sv"

endpackage : fir_pkg

`endif // FIR_PKG_SV
