// =============================================================================
// Package      : watchdog_uvm_pkg.sv
// Description  : Complete UVM Verification Package for Watchdog IP Core
// =============================================================================
`ifndef WATCHDOG_UVM_PKG_SV
`define WATCHDOG_UVM_PKG_SV

package watchdog_uvm_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import axi_pkg::*;

  `include "wdt_safety_item.sv"
  `include "wdt_safety_monitor.sv"
  `include "wdt_safety_agent.sv"
  `include "watchdog_scoreboard.sv"
  `include "watchdog_coverage.sv"
  `include "watchdog_seq_lib.sv"
  `include "watchdog_env.sv"
  `include "watchdog_tests.sv"

endpackage : watchdog_uvm_pkg

`endif // WATCHDOG_UVM_PKG_SV
