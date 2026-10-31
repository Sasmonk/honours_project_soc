// =============================================================================
// Sequence Lib : vga_seq_lib.sv
// =============================================================================
`ifndef VGA_SEQ_LIB_SV
`define VGA_SEQ_LIB_SV

class vga_base_seq extends uvm_sequence #(vga_item);
  `uvm_object_utils(vga_base_seq)
  function new(string name = "vga_base_seq"); super.new(name); endfunction

  virtual task body();
    repeat (10) begin
      req = vga_item::type_id::create("req");
      start_item(req);
      if (!req.randomize()) `uvm_fatal("VGA_SEQ", "Randomization failed!")
      finish_item(req);
    end
  endtask : body
endclass : vga_base_seq

`endif // VGA_SEQ_LIB_SV
