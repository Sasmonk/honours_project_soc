// =============================================================================
// Scoreboard   : uart_scoreboard.sv
// Description  : End-to-End Golden Scoreboard for UART 16550 IP (TC_COM_01/02)
// =============================================================================
`ifndef UART_SCOREBOARD_SV
`define UART_SCOREBOARD_SV

`uvm_analysis_imp_decl(_axi)
`uvm_analysis_imp_decl(_serial_tx)
`uvm_analysis_imp_decl(_serial_rx)
`uvm_analysis_imp_decl(_irq)

class uart_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(uart_scoreboard)

  // Analysis Imports
  uvm_analysis_imp_axi       #(axi_item, uart_scoreboard)         axi_export;
  uvm_analysis_imp_serial_tx #(uart_serial_item, uart_scoreboard) serial_tx_export;
  uvm_analysis_imp_serial_rx #(uart_serial_item, uart_scoreboard) serial_rx_export;
  uvm_analysis_imp_irq       #(bit, uart_scoreboard)              irq_export;

  // Expected queues
  bit [7:0] expected_tx_q[$];
  bit [7:0] expected_rx_q[$];

  // UART Register State
  bit       dlab = 1'b0;
  bit       ier_rx_ready_en = 1'b0;
  bit       ier_tx_empty_en = 1'b0;
  bit       current_irq = 1'b0;

  // Statistics
  int unsigned tx_match_count       = 0;
  int unsigned tx_mismatch_count    = 0;
  int unsigned tx_framing_err_count = 0;
  int unsigned rx_match_count       = 0;
  int unsigned rx_mismatch_count    = 0;
  int unsigned irq_transition_count = 0;

  function new(string name = "uart_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    axi_export       = new("axi_export", this);
    serial_tx_export = new("serial_tx_export", this);
    serial_rx_export = new("serial_rx_export", this);
    irq_export       = new("irq_export", this);
  endfunction : new

  // 1. AXI Protocol Monitor Callback
  virtual function void write_axi(axi_item item);
    bit [4:0] reg_offset = item.addr[4:0];

    if (item.op == AXI_WRITE) begin
      case (reg_offset)
        5'h00: begin // THR or DLL
          if (!dlab) begin
            expected_tx_q.push_back(item.data[7:0]);
            `uvm_info("UART_SB_AXI", $sformatf("AXI Write THR: 0x%02h ('%c') queued for TX verification", item.data[7:0], item.data[7:0]), UVM_HIGH)
          end
        end
        5'h04: begin // IER or DLM
          if (!dlab) begin
            ier_rx_ready_en = item.data[0];
            ier_tx_empty_en = item.data[1];
            `uvm_info("UART_SB_AXI", $sformatf("AXI Write IER: ERBFI(RX)=%0b, ETBEI(TX)=%0b", ier_rx_ready_en, ier_tx_empty_en), UVM_HIGH)
          end
        end
        5'h0C: begin // LCR
          dlab = item.data[7];
          `uvm_info("UART_SB_AXI", $sformatf("AXI Write LCR: DLAB=%0b", dlab), UVM_HIGH)
        end
        default: begin end
      endcase
    end else begin // AXI_READ
      case (reg_offset)
        5'h00: begin // RBR or DLL
          if (!dlab) begin
            bit [7:0] rdata = item.data[7:0];
            if (expected_rx_q.size() == 0) begin
              `uvm_error("UART_SB_RX", $sformatf("Unexpected AXI Read from RBR: 0x%02h (RX FIFO expected empty!)", rdata))
              rx_mismatch_count++;
            end else begin
              bit [7:0] exp = expected_rx_q.pop_front();
              if (exp === rdata) begin
                rx_match_count++;
                `uvm_info("UART_SB_RX", $sformatf("[TC_COM_02 MATCH] RBR Read 0x%02h ('%c') matches expected serial data!", rdata, rdata), UVM_LOW)
              end else begin
                rx_mismatch_count++;
                `uvm_error("UART_SB_RX", $sformatf("[TC_COM_02 MISMATCH] Expected 0x%02h, Read 0x%02h from RBR!", exp, rdata))
              end
            end
          end
        end
        5'h14: begin // LSR
          `uvm_info("UART_SB_AXI", $sformatf("AXI Read LSR: TEMT=%0b, THRE=%0b, DR=%0b", item.data[6], item.data[5], item.data[0]), UVM_HIGH)
        end
        default: begin end
      endcase
    end
  endfunction : write_axi

  // 2. Serial TX Monitor Callback (TC_COM_01)
  virtual function void write_serial_tx(uart_serial_item item);
    if (item.framing_err) begin
      tx_framing_err_count++;
      `uvm_error("UART_SB_TX", $sformatf("[TC_COM_01 FRAMING ERROR] Serial monitor captured framing error on byte 0x%02h", item.data))
    end

    if (expected_tx_q.size() == 0) begin
      `uvm_error("UART_SB_TX", $sformatf("Unexpected Serial TX Byte: 0x%02h ('%c')", item.data, item.data))
      tx_mismatch_count++;
    end else begin
      bit [7:0] exp = expected_tx_q.pop_front();
      if (exp === item.data) begin
        tx_match_count++;
        `uvm_info("UART_SB_TX", $sformatf("[TC_COM_01 MATCH] TX Serial 0x%02h ('%c') perfectly matches AXI THR input!", item.data, item.data), UVM_LOW)
      end else begin
        tx_mismatch_count++;
        `uvm_error("UART_SB_TX", $sformatf("[TC_COM_01 MISMATCH] Expected 0x%02h, Captured 0x%02h on TX line!", exp, item.data))
      end
    end
  endfunction : write_serial_tx

  // 3. Serial RX Driver Callback (TC_COM_02)
  virtual function void write_serial_rx(uart_serial_item item);
    expected_rx_q.push_back(item.data);
    `uvm_info("UART_SB_RX", $sformatf("Serial RX Byte 0x%02h ('%c') driven to uart_rx; queued for RBR read", item.data, item.data), UVM_HIGH)
  endfunction : write_serial_rx

  // 4. Interrupt Transition Callback
  virtual function void write_irq(bit irq_val);
    current_irq = irq_val;
    irq_transition_count++;
    `uvm_info("UART_SB_IRQ", $sformatf("UART Interrupt event: uart_irq = %0b", irq_val), UVM_HIGH)
  endfunction : write_irq

  // 5. Check Phase: Golden Verification Summary
  virtual function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    `uvm_info("UART_SB_REPORT", "------------------------------------------------------------", UVM_NONE)
    `uvm_info("UART_SB_REPORT", "       UART 16550 UVM SCOREBOARD VERIFICATION REPORT       ", UVM_NONE)
    `uvm_info("UART_SB_REPORT", "------------------------------------------------------------", UVM_NONE)
    `uvm_info("UART_SB_REPORT", $sformatf("  TC_COM_01 TX Verified Characters : %0d", tx_match_count), UVM_NONE)
    `uvm_info("UART_SB_REPORT", $sformatf("  TC_COM_01 TX Mismatches          : %0d", tx_mismatch_count), UVM_NONE)
    `uvm_info("UART_SB_REPORT", $sformatf("  TC_COM_01 TX Framing Errors      : %0d", tx_framing_err_count), UVM_NONE)
    `uvm_info("UART_SB_REPORT", $sformatf("  TC_COM_02 RX Verified Characters : %0d", rx_match_count), UVM_NONE)
    `uvm_info("UART_SB_REPORT", $sformatf("  TC_COM_02 RX Mismatches          : %0d", rx_mismatch_count), UVM_NONE)
    `uvm_info("UART_SB_REPORT", $sformatf("  Total IRQ Transitions Monitored  : %0d", irq_transition_count), UVM_NONE)
    `uvm_info("UART_SB_REPORT", "------------------------------------------------------------", UVM_NONE)

    if (tx_mismatch_count > 0 || rx_mismatch_count > 0 || tx_framing_err_count > 0) begin
      `uvm_error("UART_SB_FAIL", "Scoreboard detected functional mismatches in UART communication!")
    end

    if (expected_tx_q.size() > 0) begin
      `uvm_error("UART_SB_FAIL", $sformatf("%0d characters written to THR were never transmitted on uart_tx!", expected_tx_q.size()))
    end

    if (expected_rx_q.size() > 0) begin
      `uvm_error("UART_SB_FAIL", $sformatf("%0d characters injected into uart_rx were never read by CPU from RBR!", expected_rx_q.size()))
    end
  endfunction : check_phase

endclass : uart_scoreboard

`endif // UART_SCOREBOARD_SV
