// =============================================================================
// Sequence Lib : fir_seq_lib.sv
// =============================================================================
`ifndef FIR_SEQ_LIB_SV
`define FIR_SEQ_LIB_SV

class fir_base_seq extends uvm_sequence #(fir_item);
  `uvm_object_utils(fir_base_seq)
  function new(string name = "fir_base_seq"); super.new(name); endfunction

  virtual task body();
    repeat (10) begin
      req = fir_item::type_id::create("req");
      start_item(req);
      if (!req.randomize()) `uvm_fatal("FIR_SEQ", "Randomization failed!")
      finish_item(req);
    end
  endtask : body
endclass : fir_base_seq

`endif // FIR_SEQ_LIB_SV
