// =============================================================================
// Sequence Lib : dma_seq_lib.sv
// =============================================================================
`ifndef DMA_SEQ_LIB_SV
`define DMA_SEQ_LIB_SV

class dma_base_seq extends uvm_sequence #(dma_item);
  `uvm_object_utils(dma_base_seq)
  function new(string name = "dma_base_seq"); super.new(name); endfunction

  virtual task body();
    repeat (10) begin
      req = dma_item::type_id::create("req");
      start_item(req);
      if (!req.randomize()) `uvm_fatal("DMA_SEQ", "Randomization failed!")
      finish_item(req);
    end
  endtask : body
endclass : dma_base_seq

`endif // DMA_SEQ_LIB_SV
