// =============================================================================
// Package      : spi_uvm_pkg.sv
// Description  : Complete UVM Verification Package for SPI Master IP Core
// =============================================================================
`ifndef SPI_UVM_PKG_SV
`define SPI_UVM_PKG_SV

package spi_uvm_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import axi_pkg::*;

  `include "spi_adc_item.sv"
  `include "spi_adc_driver.sv"
  `include "spi_adc_monitor.sv"
  `include "spi_adc_agent.sv"
  `include "spi_scoreboard.sv"
  `include "spi_coverage.sv"
  `include "spi_seq_lib.sv"
  `include "spi_env.sv"
  `include "spi_tests.sv"

endpackage : spi_uvm_pkg

`endif // SPI_UVM_PKG_SV
