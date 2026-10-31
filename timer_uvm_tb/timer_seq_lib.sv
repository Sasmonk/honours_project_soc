// =============================================================================
// Sequence Lib : timer_seq_lib.sv
// =============================================================================
`ifndef TIMER_SEQ_LIB_SV
`define TIMER_SEQ_LIB_SV

class timer_base_seq extends uvm_sequence #(timer_item);
  `uvm_object_utils(timer_base_seq)
  function new(string name = "timer_base_seq"); super.new(name); endfunction

  virtual task body();
    repeat (10) begin
      req = timer_item::type_id::create("req");
      start_item(req);
      if (!req.randomize()) `uvm_fatal("TIMER_SEQ", "Randomization failed!")
      finish_item(req);
    end
  endtask : body
endclass : timer_base_seq

`endif // TIMER_SEQ_LIB_SV
