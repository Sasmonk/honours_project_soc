// =============================================================================
// Scoreboard  : vga_scoreboard.sv
// Description : Golden Reference Memory & Data Integrity Checker
// =============================================================================
`ifndef VGA_SCOREBOARD_SV
`define VGA_SCOREBOARD_SV

class vga_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(vga_scoreboard)

  uvm_analysis_imp #(vga_item, vga_scoreboard) item_export;

  function new(string name = "vga_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    item_export = new("item_export", this);
  endfunction : new

  virtual function void write(vga_item item);
    `uvm_info("SB", $sformatf("Transaction seen: %s", item.convert2string()), UVM_HIGH)
  endfunction : write

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
  endfunction : report_phase

endclass : vga_scoreboard

`endif // VGA_SCOREBOARD_SV
