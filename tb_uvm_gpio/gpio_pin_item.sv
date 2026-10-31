// =============================================================================
// Sequence Item : gpio_pin_item.sv
// Description   : Transaction item for physical GPIO pin transitions
// =============================================================================
`ifndef GPIO_PIN_ITEM_SV
`define GPIO_PIN_ITEM_SV

class gpio_pin_item extends uvm_sequence_item;
  rand bit [7:0]        pin_val;
  rand int unsigned     delay_cycles;
  bit [7:0]             out_val;
  bit                   irq_val;
  realtime              timestamp;

  `uvm_object_utils_begin(gpio_pin_item)
    `uvm_field_int (pin_val,      UVM_ALL_ON | UVM_HEX)
    `uvm_field_int (delay_cycles, UVM_ALL_ON | UVM_DEC)
    `uvm_field_int (out_val,      UVM_ALL_ON | UVM_HEX)
    `uvm_field_int (irq_val,      UVM_ALL_ON | UVM_BIN)
  `uvm_object_utils_end

  constraint c_delay { delay_cycles inside {[1:10]}; }

  function new(string name = "gpio_pin_item");
    super.new(name);
  endfunction : new

  virtual function string convert2string();
    return $sformatf("gpio_in=0x%02h gpio_out=0x%02h irq=%0b delay=%0d",
                     pin_val, out_val, irq_val, delay_cycles);
  endfunction : convert2string
endclass : gpio_pin_item

`endif // GPIO_PIN_ITEM_SV
