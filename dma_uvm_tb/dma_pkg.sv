// =============================================================================
// Package      : dma_pkg.sv
// Description  : Standard UVM Package wrapping DMA VIP Components
// =============================================================================
`ifndef DMA_PKG_SV
`define DMA_PKG_SV

package dma_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "dma_item.sv"
  `include "dma_sequencer.sv"
  `include "dma_seq_lib.sv"
  `include "dma_driver.sv"
  `include "dma_monitor.sv"
  `include "dma_agent.sv"
  `include "dma_scoreboard.sv"
  `include "dma_env.sv"
  `include "dma_test.sv"

endpackage : dma_pkg

`endif // DMA_PKG_SV
