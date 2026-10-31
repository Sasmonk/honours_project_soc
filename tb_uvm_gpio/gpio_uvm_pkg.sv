// =============================================================================
// Package      : gpio_uvm_pkg.sv
// Description  : Complete UVM Verification Package for GPIO IP Core
// =============================================================================
`ifndef GPIO_UVM_PKG_SV
`define GPIO_UVM_PKG_SV

package gpio_uvm_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import axi_pkg::*;

  `include "gpio_pin_item.sv"
  `include "gpio_pin_driver.sv"
  `include "gpio_pin_monitor.sv"
  `include "gpio_pin_agent.sv"
  `include "gpio_scoreboard.sv"
  `include "gpio_coverage.sv"
  `include "gpio_seq_lib.sv"
  `include "gpio_env.sv"
  `include "gpio_tests.sv"

endpackage : gpio_uvm_pkg

`endif // GPIO_UVM_PKG_SV
