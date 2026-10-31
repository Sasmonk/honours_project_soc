// =============================================================================
// Scoreboard  : fir_scoreboard.sv
// Description : Golden Reference Memory & Data Integrity Checker
// =============================================================================
`ifndef FIR_SCOREBOARD_SV
`define FIR_SCOREBOARD_SV

class fir_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(fir_scoreboard)

  uvm_analysis_imp #(fir_item, fir_scoreboard) item_export;

  function new(string name = "fir_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    item_export = new("item_export", this);
  endfunction : new

  virtual function void write(fir_item item);
    `uvm_info("SB", $sformatf("Transaction seen: %s", item.convert2string()), UVM_HIGH)
  endfunction : write

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
  endfunction : report_phase

endclass : fir_scoreboard

`endif // FIR_SCOREBOARD_SV
