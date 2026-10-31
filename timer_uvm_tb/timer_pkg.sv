// =============================================================================
// Package      : timer_pkg.sv
// Description  : Standard UVM Package wrapping TIMER VIP Components
// =============================================================================
`ifndef TIMER_PKG_SV
`define TIMER_PKG_SV

package timer_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "timer_item.sv"
  `include "timer_sequencer.sv"
  `include "timer_seq_lib.sv"
  `include "timer_driver.sv"
  `include "timer_monitor.sv"
  `include "timer_agent.sv"
  `include "timer_scoreboard.sv"
  `include "timer_env.sv"
  `include "timer_test.sv"

endpackage : timer_pkg

`endif // TIMER_PKG_SV
