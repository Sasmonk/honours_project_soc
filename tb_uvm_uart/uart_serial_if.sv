// =============================================================================
// Interface   : uart_serial_if.sv
// Description : Physical Serial & Interrupt Interface for UART Verification IP
// =============================================================================
`timescale 1ns / 1ps

interface uart_serial_if (input logic clk, input logic rst_n);
  logic uart_tx;
  logic uart_rx;
  logic uart_irq;

  // Active baud divisor configuration (set by testbench/sequences)
  int unsigned baud_divisor = 16;

  // UVM Monitor Captured Telemetry (visible in Verdi waveforms)
  logic       mon_in_frame          = 1'b0;  // High while actively receiving a serial character frame
  logic       mon_bit_sample_strobe = 1'b0;  // 1-cycle strobe at mid-bit sample instant
  logic [3:0] mon_bit_index         = 4'd0;  // 0=Start, 1..8=Data bits 0..7, 9=Stop bit
  logic       mon_sampled_bit       = 1'b1;  // The actual 1-bit logic level sampled at strobe
  logic [7:0] mon_shift_reg         = 8'h00; // Live shift register accumulating bits (view in Binary)
  logic [7:0] mon_captured_byte     = 8'h00; // Final assembled 8-bit character (view in ASCII / Hex)
  logic       mon_byte_valid        = 1'b0;  // Strobe indicating complete frame assembled

  // Modports
  modport driver_mp (
    input  clk, rst_n, uart_tx, uart_irq, baud_divisor,
    output uart_rx
  );

  modport monitor_mp (
    input  clk, rst_n, uart_tx, uart_rx, uart_irq, baud_divisor
  );
endinterface : uart_serial_if
