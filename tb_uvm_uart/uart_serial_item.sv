// =============================================================================
// Sequence Item : uart_serial_item.sv
// Description   : Serial UART Character Frame Item
// =============================================================================
`ifndef UART_SERIAL_ITEM_SV
`define UART_SERIAL_ITEM_SV

class uart_serial_item extends uvm_sequence_item;
  rand bit [7:0]        data;
  rand int unsigned     delay;
  bit                   framing_err;
  bit                   parity_err;
  realtime              timestamp;

  `uvm_object_utils_begin(uart_serial_item)
    `uvm_field_int (data,        UVM_ALL_ON | UVM_HEX)
    `uvm_field_int (delay,       UVM_ALL_ON | UVM_DEC)
    `uvm_field_int (framing_err, UVM_ALL_ON | UVM_BIN)
    `uvm_field_int (parity_err,  UVM_ALL_ON | UVM_BIN)
  `uvm_object_utils_end

  constraint c_delay { delay inside {[0:5]}; }

  function new(string name = "uart_serial_item");
    super.new(name);
  endfunction : new

  virtual function string convert2string();
    return $sformatf("data=0x%02h ('%c') framing_err=%0b parity_err=%0b delay=%0d",
                    data, (data >= 32 && data <= 126) ? data : ".", framing_err, parity_err, delay);
  endfunction : convert2string
endclass : uart_serial_item

`endif // UART_SERIAL_ITEM_SV
