// =============================================================================
// Driver      : uart_serial_driver.sv
// Description : Cycle-accurate Serial Bitstream Driver for uart_rx
// =============================================================================
`ifndef UART_SERIAL_DRIVER_SV
`define UART_SERIAL_DRIVER_SV

class uart_serial_driver extends uvm_driver #(uart_serial_item);
  `uvm_component_utils(uart_serial_driver)

  virtual uart_serial_if vif;
  uvm_analysis_port #(uart_serial_item) ap;

  function new(string name = "uart_serial_driver", uvm_component parent = null);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual uart_serial_if)::get(this, "", "serial_vif", vif)) begin
      `uvm_fatal("UART_SERIAL_DRV", "Virtual interface uart_serial_if not found in config_db!")
    end
  endfunction : build_phase

  virtual task run_phase(uvm_phase phase);
    vif.uart_rx <= 1'b1; // Idle high
    @(posedge vif.rst_n);
    @(posedge vif.clk);

    forever begin
      seq_item_port.get_next_item(req);
      ap.write(req);
      drive_byte(req);
      seq_item_port.item_done();
    end
  endtask : run_phase

  virtual task drive_byte(uart_serial_item item);
    int bit_cycles = vif.baud_divisor;
    if (bit_cycles < 2) bit_cycles = 16;

    // Inter-character delay
    repeat (item.delay * bit_cycles) @(posedge vif.clk);

    `uvm_info("UART_RX_DRV", $sformatf("Driving Serial Byte to uart_rx: 0x%02h ('%c')", item.data, item.data), UVM_HIGH)

    // Start bit: 0
    vif.uart_rx <= 1'b0;
    repeat (bit_cycles) @(posedge vif.clk);

    // 8 Data bits: LSB first
    for (int i = 0; i < 8; i++) begin
      vif.uart_rx <= item.data[i];
      repeat (bit_cycles) @(posedge vif.clk);
    end

    // Stop bit: 1
    vif.uart_rx <= 1'b1;
    repeat (bit_cycles) @(posedge vif.clk);
  endtask : drive_byte
endclass : uart_serial_driver

`endif // UART_SERIAL_DRIVER_SV
