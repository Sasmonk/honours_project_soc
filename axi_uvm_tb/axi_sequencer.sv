// =============================================================================
// Sequencer   : axi_sequencer.sv
// Description : Standard UVM Sequencer for AXI VIP
// =============================================================================
`ifndef AXI_SEQUENCER_SV
`define AXI_SEQUENCER_SV

class axi_sequencer extends uvm_sequencer #(axi_item);
  `uvm_component_utils(axi_sequencer)

  function new(string name = "axi_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new
endclass : axi_sequencer

`endif // AXI_SEQUENCER_SV
