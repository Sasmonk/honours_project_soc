// =============================================================================
// Sequence Lib : gpio_seq_lib.sv
// =============================================================================
`ifndef GPIO_SEQ_LIB_SV
`define GPIO_SEQ_LIB_SV

class gpio_base_seq extends uvm_sequence #(gpio_item);
  `uvm_object_utils(gpio_base_seq)
  function new(string name = "gpio_base_seq"); super.new(name); endfunction

  virtual task body();
    repeat (10) begin
      req = gpio_item::type_id::create("req");
      start_item(req);
      if (!req.randomize()) `uvm_fatal("GPIO_SEQ", "Randomization failed!")
      finish_item(req);
    end
  endtask : body
endclass : gpio_base_seq

`endif // GPIO_SEQ_LIB_SV
