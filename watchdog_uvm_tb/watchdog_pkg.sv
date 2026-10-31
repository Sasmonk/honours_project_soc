// =============================================================================
// Package      : watchdog_pkg.sv
// Description  : Standard UVM Package wrapping WATCHDOG VIP Components
// =============================================================================
`ifndef WATCHDOG_PKG_SV
`define WATCHDOG_PKG_SV

package watchdog_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "watchdog_item.sv"
  `include "watchdog_sequencer.sv"
  `include "watchdog_seq_lib.sv"
  `include "watchdog_driver.sv"
  `include "watchdog_monitor.sv"
  `include "watchdog_agent.sv"
  `include "watchdog_scoreboard.sv"
  `include "watchdog_env.sv"
  `include "watchdog_test.sv"

endpackage : watchdog_pkg

`endif // WATCHDOG_PKG_SV
