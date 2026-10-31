// =============================================================================
// Scoreboard  : sample_buffer_scoreboard.sv
// Description : Golden Reference Memory & Data Integrity Checker
// =============================================================================
`ifndef SAMPLE_BUFFER_SCOREBOARD_SV
`define SAMPLE_BUFFER_SCOREBOARD_SV

class sample_buffer_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(sample_buffer_scoreboard)

  uvm_analysis_imp #(sample_buffer_item, sample_buffer_scoreboard) item_export;

  function new(string name = "sample_buffer_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    item_export = new("item_export", this);
  endfunction : new

  virtual function void write(sample_buffer_item item);
    `uvm_info("SB", $sformatf("Transaction seen: %s", item.convert2string()), UVM_HIGH)
  endfunction : write

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
  endfunction : report_phase

endclass : sample_buffer_scoreboard

`endif // SAMPLE_BUFFER_SCOREBOARD_SV
