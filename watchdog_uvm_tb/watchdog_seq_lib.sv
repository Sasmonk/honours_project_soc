// =============================================================================
// Sequence Lib : watchdog_seq_lib.sv
// =============================================================================
`ifndef WATCHDOG_SEQ_LIB_SV
`define WATCHDOG_SEQ_LIB_SV

class watchdog_base_seq extends uvm_sequence #(watchdog_item);
  `uvm_object_utils(watchdog_base_seq)
  function new(string name = "watchdog_base_seq"); super.new(name); endfunction

  virtual task body();
    repeat (10) begin
      req = watchdog_item::type_id::create("req");
      start_item(req);
      if (!req.randomize()) `uvm_fatal("WATCHDOG_SEQ", "Randomization failed!")
      finish_item(req);
    end
  endtask : body
endclass : watchdog_base_seq

`endif // WATCHDOG_SEQ_LIB_SV
