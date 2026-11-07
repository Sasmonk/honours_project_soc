// =============================================================================
// Package      : dma_uvm_pkg.sv
// Description  : UVM Verification Package for Autonomous DMA Controller
// =============================================================================
`ifndef DMA_UVM_PKG_SV
`define DMA_UVM_PKG_SV

package dma_uvm_pkg;
  import uvm_pkg::*;
  import axi_pkg::*;
  `include "uvm_macros.svh"

  `include "dma_items.sv"
  `include "dma_stream_driver.sv"
  `include "dma_axi_master_responder.sv"
  `include "dma_monitor.sv"
  `include "dma_agent.sv"
  `include "dma_scoreboard.sv"
  `include "dma_coverage.sv"
  `include "dma_seq_lib.sv"
  `include "dma_env.sv"
  `include "dma_tests.sv"

endpackage : dma_uvm_pkg

`endif // DMA_UVM_PKG_SV
