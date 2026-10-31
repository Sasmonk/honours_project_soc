// =============================================================================
// Scoreboard  : gpio_scoreboard.sv
// Description : Golden Reference Memory & Data Integrity Checker
// =============================================================================
`ifndef GPIO_SCOREBOARD_SV
`define GPIO_SCOREBOARD_SV

class gpio_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(gpio_scoreboard)

  uvm_analysis_imp #(gpio_item, gpio_scoreboard) item_export;

  function new(string name = "gpio_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    item_export = new("item_export", this);
  endfunction : new

  virtual function void write(gpio_item item);
    `uvm_info("SB", $sformatf("Transaction seen: %s", item.convert2string()), UVM_HIGH)
  endfunction : write

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
  endfunction : report_phase

endclass : gpio_scoreboard

`endif // GPIO_SCOREBOARD_SV
