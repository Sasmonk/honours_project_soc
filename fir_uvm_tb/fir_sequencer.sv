// =============================================================================
// Sequencer   : fir_sequencer.sv
// Description : Standard UVM Sequencer for FIR VIP
// =============================================================================
`ifndef FIR_SEQUENCER_SV
`define FIR_SEQUENCER_SV

class fir_sequencer extends uvm_sequencer #(fir_item);
  `uvm_component_utils(fir_sequencer)

  function new(string name = "fir_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new
endclass : fir_sequencer

`endif // FIR_SEQUENCER_SV
