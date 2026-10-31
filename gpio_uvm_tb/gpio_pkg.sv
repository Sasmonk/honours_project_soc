// =============================================================================
// Package      : gpio_pkg.sv
// Description  : Standard UVM Package wrapping GPIO VIP Components
// =============================================================================
`ifndef GPIO_PKG_SV
`define GPIO_PKG_SV

package gpio_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "gpio_item.sv"
  `include "gpio_sequencer.sv"
  `include "gpio_seq_lib.sv"
  `include "gpio_driver.sv"
  `include "gpio_monitor.sv"
  `include "gpio_agent.sv"
  `include "gpio_scoreboard.sv"
  `include "gpio_env.sv"
  `include "gpio_test.sv"

endpackage : gpio_pkg

`endif // GPIO_PKG_SV
