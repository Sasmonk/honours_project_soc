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
  logic [7:0] mon_captured_byte = 8'h00;
  logic       mon_byte_valid    = 1'b0;

  // Modports
  modport driver_mp (
    input  clk, rst_n, uart_tx, uart_irq, baud_divisor,
    output uart_rx
  );

  modport monitor_mp (
    input  clk, rst_n, uart_tx, uart_rx, uart_irq, baud_divisor
  );
endinterface : uart_serial_if
