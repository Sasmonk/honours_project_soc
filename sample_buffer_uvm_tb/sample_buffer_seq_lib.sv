// =============================================================================
// Sequence Lib : sample_buffer_seq_lib.sv
// =============================================================================
`ifndef SAMPLE_BUFFER_SEQ_LIB_SV
`define SAMPLE_BUFFER_SEQ_LIB_SV

class sample_buffer_base_seq extends uvm_sequence #(sample_buffer_item);
  `uvm_object_utils(sample_buffer_base_seq)
  function new(string name = "sample_buffer_base_seq"); super.new(name); endfunction

  virtual task body();
    repeat (10) begin
      req = sample_buffer_item::type_id::create("req");
      start_item(req);
      if (!req.randomize()) `uvm_fatal("SAMPLE_BUFFER_SEQ", "Randomization failed!")
      finish_item(req);
    end
  endtask : body
endclass : sample_buffer_base_seq

`endif // SAMPLE_BUFFER_SEQ_LIB_SV
