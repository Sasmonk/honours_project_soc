// =============================================================================
// Sequencer   : dma_sequencer.sv
// Description : Standard UVM Sequencer for DMA VIP
// =============================================================================
`ifndef DMA_SEQUENCER_SV
`define DMA_SEQUENCER_SV

class dma_sequencer extends uvm_sequencer #(dma_item);
  `uvm_component_utils(dma_sequencer)

  function new(string name = "dma_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new
endclass : dma_sequencer

`endif // DMA_SEQUENCER_SV
