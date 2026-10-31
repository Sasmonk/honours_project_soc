// =============================================================================
// Sequencer   : watchdog_sequencer.sv
// Description : Standard UVM Sequencer for WATCHDOG VIP
// =============================================================================
`ifndef WATCHDOG_SEQUENCER_SV
`define WATCHDOG_SEQUENCER_SV

class watchdog_sequencer extends uvm_sequencer #(watchdog_item);
  `uvm_component_utils(watchdog_sequencer)

  function new(string name = "watchdog_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new
endclass : watchdog_sequencer

`endif // WATCHDOG_SEQUENCER_SV
