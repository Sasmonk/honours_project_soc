// =============================================================================
// Scoreboard  : spi_scoreboard.sv
// Description : Golden Reference Memory & Data Integrity Checker
// =============================================================================
`ifndef SPI_SCOREBOARD_SV
`define SPI_SCOREBOARD_SV

class spi_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(spi_scoreboard)

  uvm_analysis_imp #(spi_item, spi_scoreboard) item_export;

  function new(string name = "spi_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    item_export = new("item_export", this);
  endfunction : new

  virtual function void write(spi_item item);
    `uvm_info("SB", $sformatf("Transaction seen: %s", item.convert2string()), UVM_HIGH)
  endfunction : write

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
  endfunction : report_phase

endclass : spi_scoreboard

`endif // SPI_SCOREBOARD_SV
