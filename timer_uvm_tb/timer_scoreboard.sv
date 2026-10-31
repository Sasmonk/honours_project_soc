// =============================================================================
// Scoreboard  : timer_scoreboard.sv
// Description : Golden Reference Memory & Data Integrity Checker
// =============================================================================
`ifndef TIMER_SCOREBOARD_SV
`define TIMER_SCOREBOARD_SV

class timer_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(timer_scoreboard)

  uvm_analysis_imp #(timer_item, timer_scoreboard) item_export;

  function new(string name = "timer_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    item_export = new("item_export", this);
  endfunction : new

  virtual function void write(timer_item item);
    `uvm_info("SB", $sformatf("Transaction seen: %s", item.convert2string()), UVM_HIGH)
  endfunction : write

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
  endfunction : report_phase

endclass : timer_scoreboard

`endif // TIMER_SCOREBOARD_SV
