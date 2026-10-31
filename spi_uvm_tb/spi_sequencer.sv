// =============================================================================
// Sequencer   : spi_sequencer.sv
// Description : Standard UVM Sequencer for SPI VIP
// =============================================================================
`ifndef SPI_SEQUENCER_SV
`define SPI_SEQUENCER_SV

class spi_sequencer extends uvm_sequencer #(spi_item);
  `uvm_component_utils(spi_sequencer)

  function new(string name = "spi_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new
endclass : spi_sequencer

`endif // SPI_SEQUENCER_SV
