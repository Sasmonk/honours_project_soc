// =============================================================================
// Package      : fir_uvm_pkg.sv
// Description  : Complete UVM Verification Package for 16-Tap FIR Digital Filter
// =============================================================================
`ifndef FIR_UVM_PKG_SV
`define FIR_UVM_PKG_SV

package fir_uvm_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import axi_pkg::*;

  `include "fir_sample_item.sv"
  `include "fir_sample_driver.sv"
  `include "fir_sample_monitor.sv"
  `include "fir_sample_agent.sv"
  `include "fir_scoreboard.sv"
  `include "fir_coverage.sv"
  `include "fir_seq_lib.sv"
  `include "fir_env.sv"
  `include "fir_tests.sv"

endpackage : fir_uvm_pkg

`endif // FIR_UVM_PKG_SV
