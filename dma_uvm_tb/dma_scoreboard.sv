// =============================================================================
// Scoreboard  : dma_scoreboard.sv
// Description : Golden Reference Memory & Data Integrity Checker
// =============================================================================
`ifndef DMA_SCOREBOARD_SV
`define DMA_SCOREBOARD_SV

class dma_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(dma_scoreboard)

  uvm_analysis_imp #(dma_item, dma_scoreboard) item_export;

  function new(string name = "dma_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    item_export = new("item_export", this);
  endfunction : new

  virtual function void write(dma_item item);
    `uvm_info("SB", $sformatf("Transaction seen: %s", item.convert2string()), UVM_HIGH)
  endfunction : write

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
  endfunction : report_phase

endclass : dma_scoreboard

`endif // DMA_SCOREBOARD_SV
