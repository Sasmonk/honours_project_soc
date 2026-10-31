// =============================================================================
// Package      : timer_uvm_pkg.sv
// Description  : Complete UVM Verification Package for System Timer IP Core
// =============================================================================
`ifndef TIMER_UVM_PKG_SV
`define TIMER_UVM_PKG_SV

package timer_uvm_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import axi_pkg::*;

  `include "timer_pulse_item.sv"
  `include "timer_pulse_monitor.sv"
  `include "timer_pulse_agent.sv"
  `include "timer_scoreboard.sv"
  `include "timer_coverage.sv"
  `include "timer_seq_lib.sv"
  `include "timer_env.sv"
  `include "timer_tests.sv"

endpackage : timer_uvm_pkg

`endif // TIMER_UVM_PKG_SV
