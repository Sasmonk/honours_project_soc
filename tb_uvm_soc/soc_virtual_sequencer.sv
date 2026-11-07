// =============================================================================
// File        : soc_virtual_sequencer.sv
// Description : Virtual Sequencer coordinating multi-peripheral sequences
// =============================================================================
`ifndef SOC_VIRTUAL_SEQUENCER_SV
`define SOC_VIRTUAL_SEQUENCER_SV

class soc_virtual_sequencer extends uvm_sequencer;
  `uvm_component_utils(soc_virtual_sequencer)

  uart_serial_sequencer uart_seqr;
  gpio_pin_sequencer    gpio_seqr;

  function new(string name = "soc_virtual_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

endclass : soc_virtual_sequencer

`endif // SOC_VIRTUAL_SEQUENCER_SV
