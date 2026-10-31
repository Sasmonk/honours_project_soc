// =============================================================================
// Sequences   : gpio_seq_lib.sv
// Description : UVM Sequence Library for GPIO Verification (TC_COM_03/04)
// =============================================================================
`ifndef GPIO_SEQ_LIB_SV
`define GPIO_SEQ_LIB_SV

// -----------------------------------------------------------------------------
// Base AXI Register Sequence for GPIO
// -----------------------------------------------------------------------------
class gpio_base_axi_seq extends uvm_sequence #(axi_item);
  `uvm_object_utils(gpio_base_axi_seq)

  function new(string name = "gpio_base_axi_seq");
    super.new(name);
  endfunction : new

  task write_reg(bit [31:0] addr, bit [31:0] data);
    axi_item item = axi_item::type_id::create("reg_wr");
    start_item(item);
    item.op    = AXI_WRITE;
    item.addr  = addr;
    item.data  = data;
    item.strb  = 4'hF;
    item.prot  = 3'b000;
    item.delay = 1;
    finish_item(item);
  endtask : write_reg

  task read_reg(bit [31:0] addr, output bit [31:0] data);
    axi_item item = axi_item::type_id::create("reg_rd");
    start_item(item);
    item.op    = AXI_READ;
    item.addr  = addr;
    item.strb  = 4'h0;
    item.prot  = 3'b000;
    item.delay = 1;
    finish_item(item);
    data = item.data;
  endtask : read_reg
endclass : gpio_base_axi_seq

// -----------------------------------------------------------------------------
// TC_COM_04: GPIO Status LED Output Drive Sequence
// -----------------------------------------------------------------------------
class tc_com_04_led_drive_seq extends gpio_base_axi_seq;
  `uvm_object_utils(tc_com_04_led_drive_seq)

  function new(string name = "tc_com_04_led_drive_seq");
    super.new(name);
  endfunction : new

  virtual task body();
    bit [31:0] read_val;

    `uvm_info(get_type_name(), "=== [TC_COM_04] Starting GPIO Status LED Output Drive Verification ===", UVM_LOW)

    // Milestone 25%: Write 0xA5 to GPIO_OUT (offset 0x04)
    `uvm_info(get_type_name(), "[TC_COM_04 25%%] Writing 0xA5 to GPIO_OUT", UVM_LOW)
    write_reg(32'h04, 32'hA5);
    read_reg(32'h04, read_val);

    // Milestone 50%: Verify readback matches 0xA5
    if (read_val[7:0] !== 8'hA5) begin
      `uvm_error(get_type_name(), $sformatf("GPIO_OUT readback mismatch! Expected 0xA5, got 0x%02h", read_val[7:0]))
    end

    // Milestone 75%: Write 0x5A to GPIO_OUT (offset 0x04)
    `uvm_info(get_type_name(), "[TC_COM_04 75%%] Writing 0x5A to GPIO_OUT", UVM_LOW)
    write_reg(32'h04, 32'h5A);
    read_reg(32'h04, read_val);

    // Milestone 100%: Sweep walking-ones diagnostic patterns
    `uvm_info(get_type_name(), "[TC_COM_04 100%%] Sweeping walking-ones patterns on LEDs", UVM_LOW)
    for (int i = 0; i < 8; i++) begin
      write_reg(32'h04, 1 << i);
    end
    write_reg(32'h04, 32'h00);

    `uvm_info(get_type_name(), "=== [TC_COM_04] Status LED Output Drive Verification Completed Successfully! ===", UVM_LOW)
  endtask : body
endclass : tc_com_04_led_drive_seq

// -----------------------------------------------------------------------------
// Button Pin Driver Stimulus Sequence
// -----------------------------------------------------------------------------
class gpio_button_stimulus_seq extends uvm_sequence #(gpio_pin_item);
  `uvm_object_utils(gpio_button_stimulus_seq)

  function new(string name = "gpio_button_stimulus_seq");
    super.new(name);
  endfunction : new

  task drive_btn(bit [7:0] val, int unsigned cycles = 5);
    gpio_pin_item item = gpio_pin_item::type_id::create("btn_item");
    start_item(item);
    item.pin_val      = val;
    item.delay_cycles = cycles;
    finish_item(item);
  endtask : drive_btn

  virtual task body();
    // 1. Idle state: all buttons unpressed (0x00)
    drive_btn(8'h00, 5);

    // 2. Press button 0 (0x01) and hold for 25 cycles for AXI ISR to catch
    drive_btn(8'h01, 25);

    // 3. Release button 0 (0x00)
    drive_btn(8'h00, 15);

    // 4. Press button 1 and button 2 concurrently (0x06)
    drive_btn(8'h06, 20);

    // 5. Release all (0x00)
    drive_btn(8'h00, 10);
  endtask : body
endclass : gpio_button_stimulus_seq

// -----------------------------------------------------------------------------
// TC_COM_03: GPIO Push-Button Sync & IRQ AXI Reader / Clearer Sequence
// -----------------------------------------------------------------------------
class tc_com_03_button_sync_seq extends gpio_base_axi_seq;
  `uvm_object_utils(tc_com_03_button_sync_seq)

  function new(string name = "tc_com_03_button_sync_seq");
    super.new(name);
  endfunction : new

  virtual task body();
    bit [31:0] status_val;
    bit [31:0] pin_val;

    `uvm_info(get_type_name(), "=== [TC_COM_03] Starting GPIO Push-Button Sync & IRQ Verification ===", UVM_LOW)

    // Milestone 25%: Enable interrupts on all 8 pins (GPIO_IRQ_EN = 0xFF)
    `uvm_info(get_type_name(), "[TC_COM_03 25%%] Enabling GPIO_IRQ_EN = 0xFF", UVM_LOW)
    write_reg(32'h08, 32'hFF);

    // Milestone 50% & 75%: Poll for GPIO_STATUS.CHANGED assertion (bit 0 = 1)
    `uvm_info(get_type_name(), "[TC_COM_03 50%%-75%%] Polling GPIO_STATUS until edge detected by 3-stage synchronizer", UVM_LOW)
    do begin
      read_reg(32'h0C, status_val);
    end while ((status_val & 32'h01) == 0);

    `uvm_info(get_type_name(), "[TC_COM_03 75%%] Synchronizer successfully latched edge! Reading GPIO_IN", UVM_LOW)
    read_reg(32'h00, pin_val);
    `uvm_info(get_type_name(), $sformatf("GPIO_IN read value = 0x%02h", pin_val[7:0]), UVM_MEDIUM)

    // Milestone 100%: Write 1 to Clear (W1C) to GPIO_STATUS
    `uvm_info(get_type_name(), "[TC_COM_03 100%%] Writing W1C to GPIO_STATUS (0x0C) to clear IRQ", UVM_LOW)
    write_reg(32'h0C, 32'h01);

    // Verify status cleared
    read_reg(32'h0C, status_val);
    if ((status_val & 32'h01) !== 0) begin
      `uvm_error(get_type_name(), "GPIO_STATUS.CHANGED still asserted after W1C write!")
    end

    `uvm_info(get_type_name(), "=== [TC_COM_03] Button Sync & Edge IRQ Verification Completed Successfully! ===", UVM_LOW)
  endtask : body
endclass : tc_com_03_button_sync_seq

`endif // GPIO_SEQ_LIB_SV
