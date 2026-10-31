// =============================================================================
// Package      : sample_buffer_pkg.sv
// Description  : Standard UVM Package wrapping SAMPLE_BUFFER VIP Components
// =============================================================================
`ifndef SAMPLE_BUFFER_PKG_SV
`define SAMPLE_BUFFER_PKG_SV

package sample_buffer_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "sample_buffer_item.sv"
  `include "sample_buffer_sequencer.sv"
  `include "sample_buffer_seq_lib.sv"
  `include "sample_buffer_driver.sv"
  `include "sample_buffer_monitor.sv"
  `include "sample_buffer_agent.sv"
  `include "sample_buffer_scoreboard.sv"
  `include "sample_buffer_env.sv"
  `include "sample_buffer_test.sv"

endpackage : sample_buffer_pkg

`endif // SAMPLE_BUFFER_PKG_SV
