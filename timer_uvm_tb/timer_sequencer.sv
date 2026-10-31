// =============================================================================
// Sequencer   : timer_sequencer.sv
// Description : Standard UVM Sequencer for TIMER VIP
// =============================================================================
`ifndef TIMER_SEQUENCER_SV
`define TIMER_SEQUENCER_SV

class timer_sequencer extends uvm_sequencer #(timer_item);
  `uvm_component_utils(timer_sequencer)

  function new(string name = "timer_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new
endclass : timer_sequencer

`endif // TIMER_SEQUENCER_SV
