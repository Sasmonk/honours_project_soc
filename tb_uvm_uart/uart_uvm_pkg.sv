// =============================================================================
// Package      : uart_uvm_pkg.sv
// Description  : Complete UVM Verification Package for UART 16550 IP Core
// =============================================================================
`ifndef UART_UVM_PKG_SV
`define UART_UVM_PKG_SV

package uart_uvm_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import axi_pkg::*;

  `include "uart_serial_item.sv"
  `include "uart_serial_sequencer.sv"
  `include "uart_serial_driver.sv"
  `include "uart_serial_monitor.sv"
  `include "uart_serial_agent.sv"
  `include "uart_scoreboard.sv"
  `include "uart_coverage.sv"
  `include "uart_seq_lib.sv"
  `include "uart_env.sv"
  `include "uart_tests.sv"

endpackage : uart_uvm_pkg

`endif // UART_UVM_PKG_SV
