// =============================================================================
// File        : soc_vseq_lib.sv
// Description : Virtual Sequence Library for Top-Level SoC UVM Environment
// =============================================================================
`ifndef SOC_VSEQ_LIB_SV
`define SOC_VSEQ_LIB_SV

// -----------------------------------------------------------------------------
// Base Virtual Sequence
// -----------------------------------------------------------------------------
class soc_base_vseq extends uvm_sequence;
  `uvm_object_utils(soc_base_vseq)
  `uvm_declare_p_sequencer(soc_virtual_sequencer)

  function new(string name = "soc_base_vseq");
    super.new(name);
  endfunction : new

  task send_uart_byte(bit [7:0] byte_data);
    uart_serial_item item = uart_serial_item::type_id::create("uart_item");
    start_item(item, -1, p_sequencer.uart_seqr);
    item.data = byte_data;
    finish_item(item);
  endtask : send_uart_byte

  task send_uart_cmd(string cmd);
    for (int i = 0; i < cmd.len(); i++) begin
      send_uart_byte(cmd[i]);
    end
    send_uart_byte(8'h0D); // CR
    send_uart_byte(8'h0A); // LF
  endtask : send_uart_cmd

  task send_gpio_stimulus(bit [7:0] val, int hold_cycles = 100);
    gpio_pin_item item = gpio_pin_item::type_id::create("gpio_item");
    start_item(item, -1, p_sequencer.gpio_seqr);
    item.pin_val = val;
    finish_item(item);
    # (hold_cycles * 10ns);
  endtask : send_gpio_stimulus

endclass : soc_base_vseq


// -----------------------------------------------------------------------------
// Sequence 1: Firmware Boot and UART Live Telemetry
// -----------------------------------------------------------------------------
class soc_firmware_boot_vseq extends soc_base_vseq;
  `uvm_object_utils(soc_firmware_boot_vseq)

  function new(string name = "soc_firmware_boot_vseq");
    super.new(name);
  endfunction : new

  virtual task body();
    `uvm_info("VSEQ", "Executing SoC Firmware Boot & Live Telemetry Sequence", UVM_LOW)
    // Allow VeeR EL2 CPU to boot from IMEM (0x1000_0000) and initialize peripherals
    # 500us;
    `uvm_info("VSEQ", "Firmware boot observation window complete.", UVM_LOW)
  endtask : body

endclass : soc_firmware_boot_vseq


// -----------------------------------------------------------------------------
// Sequence 2: Interactive UI Controls via GPIO and UART
// -----------------------------------------------------------------------------
class soc_interactive_ui_vseq extends soc_base_vseq;
  `uvm_object_utils(soc_interactive_ui_vseq)

  function new(string name = "soc_interactive_ui_vseq");
    super.new(name);
  endfunction : new

  virtual task body();
    `uvm_info("VSEQ", "Starting Interactive UI Control Sequence (GPIO pushbuttons)", UVM_LOW)

    // Wait for initial system boot
    # 50us;

    // Simulate Button 0 (Volts/Div Scale Up)
    `uvm_info("VSEQ", "Simulating GPIO Button 0 Press: VDIV Scale Up", UVM_LOW)
    send_gpio_stimulus(8'h01, 200);
    send_gpio_stimulus(8'h00, 200);

    // Simulate Button 1 (Time/Div Scale Up)
    `uvm_info("VSEQ", "Simulating GPIO Button 1 Press: TDIV Scale Up", UVM_LOW)
    send_gpio_stimulus(8'h02, 200);
    send_gpio_stimulus(8'h00, 200);

    // Simulate Button 2 (Trigger Edge Toggle)
    `uvm_info("VSEQ", "Simulating GPIO Button 2 Press: Trigger Mode Toggle", UVM_LOW)
    send_gpio_stimulus(8'h04, 200);
    send_gpio_stimulus(8'h00, 200);

    # 100us;
    `uvm_info("VSEQ", "Interactive UI Control Sequence Completed Successfully", UVM_LOW)
  endtask : body

endclass : soc_interactive_ui_vseq


// -----------------------------------------------------------------------------
// Sequence 3: Comprehensive Multi-Peripheral All Features Sequence
// -----------------------------------------------------------------------------
class soc_all_features_vseq extends soc_base_vseq;
  `uvm_object_utils(soc_all_features_vseq)

  function new(string name = "soc_all_features_vseq");
    super.new(name);
  endfunction : new

  virtual task body();
    `uvm_info("VSEQ", "=======================================================", UVM_LOW)
    `uvm_info("VSEQ", "  STARTING COMPLETE MULTI-PERIPHERAL SOC STRESS SUITE  ", UVM_LOW)
    `uvm_info("VSEQ", "=======================================================", UVM_LOW)

    fork
      begin
        // Sub-thread 1: Monitor firmware execution
        # 500us;
      end
      begin
        // Sub-thread 2: Inject periodic GPIO user events
        # 20us;
        send_gpio_stimulus(8'h01, 150);
        send_gpio_stimulus(8'h00, 150);
        # 30us;
        send_gpio_stimulus(8'h02, 150);
        send_gpio_stimulus(8'h00, 150);
        # 30us;
        send_gpio_stimulus(8'h08, 150);
        send_gpio_stimulus(8'h00, 150);
      end
    join

    `uvm_info("VSEQ", "All Features SoC Verification Sequence Completed!", UVM_LOW)
  endtask : body

endclass : soc_all_features_vseq

`endif // SOC_VSEQ_LIB_SV
