// =============================================================================
// Item         : fir_sample_item.sv
// Description  : Sequence item for streaming FIR samples
// =============================================================================
`ifndef FIR_SAMPLE_ITEM_SV
`define FIR_SAMPLE_ITEM_SV

class fir_sample_item extends uvm_sequence_item;
  `uvm_object_utils(fir_sample_item)

  rand bit signed [15:0] sample_data;
  bit                    is_input;
  realtime               timestamp;

  function new(string name = "fir_sample_item");
    super.new(name);
  endfunction

  virtual function string convert2string();
    return $sformatf("%s sample=0x%04x (%0d) @%0t",
                     is_input ? "IN" : "OUT", sample_data, sample_data, timestamp);
  endfunction

endclass : fir_sample_item

`endif // FIR_SAMPLE_ITEM_SV
