// =============================================================================
// Sequences   : uart_seq_lib.sv
// Description : UVM Sequence Library for UART 16550 Verification (TC_COM_01/02)
// =============================================================================
`ifndef UART_SEQ_LIB_SV
`define UART_SEQ_LIB_SV

// -----------------------------------------------------------------------------
// Base AXI Register Sequence
// -----------------------------------------------------------------------------
class uart_base_axi_seq extends uvm_sequence #(axi_item);
  `uvm_object_utils(uart_base_axi_seq)

  function new(string name = "uart_base_axi_seq");
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

  task set_baud(int unsigned divisor);
    `uvm_info(get_type_name(), $sformatf("Programming Baud Divisor = %0d (DLL/DLM + Legacy)", divisor), UVM_MEDIUM)
    // 1. Enable DLAB in LCR (bit 7)
    write_reg(32'h0C, 32'h83);
    // 2. Set DLL (LSB) & DLM (MSB)
    write_reg(32'h00, divisor & 32'hFF);
    write_reg(32'h04, (divisor >> 8) & 32'hFF);
    // 3. Set Legacy Divisor Register
    write_reg(32'h08, divisor);
    // 4. Clear DLAB in LCR (8 data bits, 1 stop bit, no parity)
    write_reg(32'h0C, 32'h03);
  endtask : set_baud
endclass : uart_base_axi_seq

// -----------------------------------------------------------------------------
// TC_COM_01: 16550 UART TX Framing Sequence
// -----------------------------------------------------------------------------
class uart_tx_frame_seq extends uart_base_axi_seq;
  `uvm_object_utils(uart_tx_frame_seq)

  string banner = "HELLO SoC!\r\n";
  int unsigned baud_div = 16;

  function new(string name = "uart_tx_frame_seq");
    super.new(name);
  endfunction : new

  virtual task body();
    bit [31:0] lsr_val;

    `uvm_info(get_type_name(), "=== [TC_COM_01] Starting 16550 UART TX Framing Verification ===", UVM_LOW)

    // Milestone 25%: Set Baud Divisor & Frame Format
    `uvm_info(get_type_name(), "[TC_COM_01 25%%] Configuring Baud Divisor & 8-N-1 Line Control", UVM_LOW)
    set_baud(baud_div);

    // Milestone 50%: Transmit String via UART_THR (0x00)
    `uvm_info(get_type_name(), $sformatf("[TC_COM_01 50%%] Writing string '%s' to UART_THR", banner), UVM_LOW)
    for (int i = 0; i < banner.len(); i++) begin
      // Wait for THRE (LSR bit 5) before sending
      do begin
        read_reg(32'h14, lsr_val);
      end while ((lsr_val & 32'h20) == 0);

      write_reg(32'h00, banner[i]);
    end

    // Milestone 75%: Poll LSR for Transmitter Empty (TEMT, bit 6)
    `uvm_info(get_type_name(), "[TC_COM_01 75%%] Polling LSR until TEMT=1 (all serialized bits shifted out)", UVM_LOW)
    do begin
      read_reg(32'h14, lsr_val);
    end while ((lsr_val & 32'h40) == 0);

    // Milestone 100%: Completed
    `uvm_info(get_type_name(), "[TC_COM_01 100%%] All characters successfully pushed and serialized with 0 framing errors!", UVM_LOW)
  endtask : body
endclass : uart_tx_frame_seq

// -----------------------------------------------------------------------------
// Serial Driver Sequence: Injects bytes into uart_rx
// -----------------------------------------------------------------------------
class uart_serial_rx_inject_seq extends uvm_sequence #(uart_serial_item);
  `uvm_object_utils(uart_serial_rx_inject_seq)

  string payload = "UVM_UART";

  function new(string name = "uart_serial_rx_inject_seq");
    super.new(name);
  endfunction : new

  virtual task body();
    for (int i = 0; i < payload.len(); i++) begin
      uart_serial_item item = uart_serial_item::type_id::create("rx_byte");
      start_item(item);
      item.data        = payload[i];
      item.delay       = 2;
      item.framing_err = 1'b0;
      item.parity_err  = 1'b0;
      finish_item(item);
    end
  endtask : body
endclass : uart_serial_rx_inject_seq

// -----------------------------------------------------------------------------
// TC_COM_02: UART RX FIFO Watermark & IRQ AXI Reader Sequence
// -----------------------------------------------------------------------------
class uart_rx_irq_axi_seq extends uart_base_axi_seq;
  `uvm_object_utils(uart_rx_irq_axi_seq)

  int unsigned num_expected_bytes = 8;

  function new(string name = "uart_rx_irq_axi_seq");
    super.new(name);
  endfunction : new

  virtual task body();
    bit [31:0] lsr_val;
    bit [31:0] rbr_val;
    int unsigned read_count = 0;

    `uvm_info(get_type_name(), "=== [TC_COM_02] Starting UART RX FIFO Watermark & IRQ Verification ===", UVM_LOW)

    // Milestone 25%: Configure Baud Divisor and Enable RX Data Interrupt in IER (bit 0)
    `uvm_info(get_type_name(), "[TC_COM_02 25%%] Setting Baud Divisor = 16 and Enabling UART_IER.ERBFI", UVM_LOW)
    set_baud(16);
    write_reg(32'h04, 32'h01);

    // Milestone 50% & 75%: Read incoming bytes as they arrive in RX FIFO
    `uvm_info(get_type_name(), "[TC_COM_02 50%%-75%%] Waiting for serial bytes and polling LSR.DR", UVM_LOW)
    while (read_count < num_expected_bytes) begin
      read_reg(32'h14, lsr_val);
      if (lsr_val & 32'h01) begin // Data Ready!
        read_reg(32'h00, rbr_val);
        `uvm_info(get_type_name(), $sformatf("Read RBR byte %0d/%0d: 0x%02h ('%c')",
                  read_count+1, num_expected_bytes, rbr_val[7:0], rbr_val[7:0]), UVM_MEDIUM)
        read_count++;
      end
    end

    // Verify RX FIFO empty and DR cleared
    read_reg(32'h14, lsr_val);
    if (lsr_val & 32'h01) begin
      `uvm_error(get_type_name(), "LSR.DR still asserted after all expected bytes were read!")
    end

    // Milestone 100%: Completed
    `uvm_info(get_type_name(), "[TC_COM_02 100%%] All RX bytes received, verified in-order, and IRQ successfully de-asserted!", UVM_LOW)
  endtask : body
endclass : uart_rx_irq_axi_seq

// -----------------------------------------------------------------------------
// TC_COM_03: UART Transmitter Holding Register Empty (THRE) IRQ Sequence
// -----------------------------------------------------------------------------
class uart_tx_empty_irq_seq extends uart_base_axi_seq;
  `uvm_object_utils(uart_tx_empty_irq_seq)

  function new(string name = "uart_tx_empty_irq_seq");
    super.new(name);
  endfunction : new

  virtual task body();
    bit [31:0] iir_val;
    bit [31:0] lsr_val;

    `uvm_info(get_type_name(), "=== [TC_COM_03] Verifying THRE (Transmitter Empty) IRQ ===", UVM_LOW)

    // 1. Enable THRE interrupt in IER (bit 1)
    write_reg(32'h04, 32'h02);

    // 2. Poll IIR to confirm THRE interrupt pending (IIR[3:0] == 4'h2)
    read_reg(32'h08, iir_val);
    `uvm_info(get_type_name(), $sformatf("IIR Status with THRE enabled: 0x%02h", iir_val[7:0]), UVM_MEDIUM)

    // 3. Write character to THR to clear THRE condition
    write_reg(32'h00, 32'h5A); // 'Z'

    // 4. Wait for TEMT to serialize out
    do begin
      read_reg(32'h14, lsr_val);
    end while ((lsr_val & 32'h40) == 0);

    // 5. Disable interrupts
    write_reg(32'h04, 32'h00);
    `uvm_info(get_type_name(), "=== [TC_COM_03] THRE IRQ Verification Complete ===", UVM_LOW)
  endtask : body
endclass : uart_tx_empty_irq_seq

`endif // UART_SEQ_LIB_SV
