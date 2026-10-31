// =============================================================================
// Sequencer   : vga_sequencer.sv
// Description : Standard UVM Sequencer for VGA VIP
// =============================================================================
`ifndef VGA_SEQUENCER_SV
`define VGA_SEQUENCER_SV

class vga_sequencer extends uvm_sequencer #(vga_item);
  `uvm_component_utils(vga_sequencer)

  function new(string name = "vga_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new
endclass : vga_sequencer

`endif // VGA_SEQUENCER_SV
