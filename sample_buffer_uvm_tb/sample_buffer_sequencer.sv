// =============================================================================
// Sequencer   : sample_buffer_sequencer.sv
// Description : Standard UVM Sequencer for SAMPLE_BUFFER VIP
// =============================================================================
`ifndef SAMPLE_BUFFER_SEQUENCER_SV
`define SAMPLE_BUFFER_SEQUENCER_SV

class sample_buffer_sequencer extends uvm_sequencer #(sample_buffer_item);
  `uvm_component_utils(sample_buffer_sequencer)

  function new(string name = "sample_buffer_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new
endclass : sample_buffer_sequencer

`endif // SAMPLE_BUFFER_SEQUENCER_SV
