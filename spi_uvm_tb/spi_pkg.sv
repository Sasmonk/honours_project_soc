// =============================================================================
// Package      : spi_pkg.sv
// Description  : Standard UVM Package wrapping SPI VIP Components
// =============================================================================
`ifndef SPI_PKG_SV
`define SPI_PKG_SV

package spi_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "spi_item.sv"
  `include "spi_sequencer.sv"
  `include "spi_seq_lib.sv"
  `include "spi_driver.sv"
  `include "spi_monitor.sv"
  `include "spi_agent.sv"
  `include "spi_scoreboard.sv"
  `include "spi_env.sv"
  `include "spi_test.sv"

endpackage : spi_pkg

`endif // SPI_PKG_SV
