// =============================================================================
// Scoreboard  : watchdog_scoreboard.sv
// Description : Golden Reference Memory & Data Integrity Checker
// =============================================================================
`ifndef WATCHDOG_SCOREBOARD_SV
`define WATCHDOG_SCOREBOARD_SV

class watchdog_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(watchdog_scoreboard)

  uvm_analysis_imp #(watchdog_item, watchdog_scoreboard) item_export;

  function new(string name = "watchdog_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    item_export = new("item_export", this);
  endfunction : new

  virtual function void write(watchdog_item item);
    `uvm_info("SB", $sformatf("Transaction seen: %s", item.convert2string()), UVM_HIGH)
  endfunction : write

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
  endfunction : report_phase

endclass : watchdog_scoreboard

`endif // WATCHDOG_SCOREBOARD_SV
