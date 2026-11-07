// =============================================================================
// Monitor     : uart_serial_monitor.sv
// Description : Cycle-accurate Serial TX Bitstream & Interrupt Monitor
// =============================================================================
`ifndef UART_SERIAL_MONITOR_SV
`define UART_SERIAL_MONITOR_SV

class uart_serial_monitor extends uvm_monitor;
  `uvm_component_utils(uart_serial_monitor)

  virtual uart_serial_if vif;
  uvm_analysis_port #(uart_serial_item) ap;
  uvm_analysis_port #(bit)              irq_ap;

  function new(string name = "uart_serial_monitor", uvm_component parent = null);
    super.new(name, parent);
    ap     = new("ap", this);
    irq_ap = new("irq_ap", this);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual uart_serial_if)::get(this, "", "serial_vif", vif)) begin
      `uvm_fatal("UART_SERIAL_MON", "Virtual interface uart_serial_if not found in config_db!")
    end
  endfunction : build_phase

  virtual task run_phase(uvm_phase phase);
    fork
      monitor_tx_serial();
      monitor_irq_line();
    join
  endtask : run_phase

  virtual task monitor_tx_serial();
    int bit_cycles;
    bit [7:0] captured_byte;
    uart_serial_item item;

    vif.mon_in_frame          <= 1'b0;
    vif.mon_bit_sample_strobe <= 1'b0;
    vif.mon_bit_index         <= 4'd0;
    vif.mon_sampled_bit       <= 1'b1;
    vif.mon_shift_reg         <= 8'h00;

    @(posedge vif.rst_n);

    forever begin
      bit_cycles = vif.baud_divisor;
      if (bit_cycles < 2) bit_cycles = 16;

      // 1. Wait for Start Bit (falling edge on uart_tx)
      @(negedge vif.uart_tx);
      vif.mon_in_frame  <= 1'b1;
      vif.mon_bit_index <= 4'd0;
      vif.mon_shift_reg <= 8'h00;

      // Verify start bit remains low at mid-bit
      repeat (bit_cycles / 2) @(posedge vif.clk);
      vif.mon_sampled_bit       <= vif.uart_tx;
      vif.mon_bit_sample_strobe <= 1'b1;
      fork
        begin
          @(posedge vif.clk);
          vif.mon_bit_sample_strobe <= 1'b0;
        end
      join_none

      if (vif.uart_tx !== 1'b0) begin
        `uvm_warning("UART_TX_GLITCH", "Glitched start bit detected on uart_tx!")
        vif.mon_in_frame <= 1'b0;
        continue;
      end

      // 2. Sample 8 Data Bits at Mid-Bit intervals (LSB first)
      captured_byte = 8'd0;
      for (int i = 0; i < 8; i++) begin
        repeat (bit_cycles) @(posedge vif.clk);
        captured_byte[i]           = vif.uart_tx;
        vif.mon_bit_index         <= i + 1;
        vif.mon_sampled_bit       <= vif.uart_tx;
        vif.mon_shift_reg         <= captured_byte;
        vif.mon_bit_sample_strobe <= 1'b1;
        fork
          begin
            @(posedge vif.clk);
            vif.mon_bit_sample_strobe <= 1'b0;
          end
        join_none
      end

      // 3. Sample Stop Bit at Mid-Bit interval (must be 1)
      repeat (bit_cycles) @(posedge vif.clk);
      vif.mon_bit_index         <= 4'd9;
      vif.mon_sampled_bit       <= vif.uart_tx;
      vif.mon_bit_sample_strobe <= 1'b1;
      fork
        begin
          @(posedge vif.clk);
          vif.mon_bit_sample_strobe <= 1'b0;
        end
      join_none

      item = uart_serial_item::type_id::create("mon_tx_item");
      item.data      = captured_byte;
      item.timestamp = $realtime;

      if (vif.uart_tx !== 1'b1) begin
        item.framing_err = 1'b1;
        `uvm_error("UART_FRAMING_ERR", $sformatf("Framing Error on uart_tx! Stop bit was 0 for byte 0x%02h", captured_byte))
      end else begin
        item.framing_err = 1'b0;
        `uvm_info("UART_TX_MON", $sformatf("Captured Valid TX Byte: 0x%02h ('%c')", captured_byte, captured_byte), UVM_MEDIUM)
      end

      // Update interface telemetry for Verdi waveform observation
      vif.mon_captured_byte <= captured_byte;
      vif.mon_byte_valid    <= 1'b1;
      fork
        begin
          repeat (bit_cycles) @(posedge vif.clk);
          vif.mon_byte_valid <= 1'b0;
          vif.mon_in_frame   <= 1'b0;
        end
      join_none

      ap.write(item);
    end
  endtask : monitor_tx_serial

  virtual task monitor_irq_line();
    bit prev_irq = 1'b0;
    @(posedge vif.rst_n);

    forever begin
      @(vif.uart_irq);
      if (vif.uart_irq !== prev_irq) begin
        prev_irq = vif.uart_irq;
        `uvm_info("UART_IRQ_MON", $sformatf("uart_irq transitioned to %0b at %0t", vif.uart_irq, $time), UVM_HIGH)
        irq_ap.write(vif.uart_irq);
      end
    end
  endtask : monitor_irq_line
endclass : uart_serial_monitor

`endif // UART_SERIAL_MONITOR_SV
