// =============================================================================
// Interface    : timer_pulse_if.sv
// Description  : Interface for Timer output pulses (sample_tick, irq_timer)
// =============================================================================
`ifndef TIMER_PULSE_IF_SV
`define TIMER_PULSE_IF_SV

interface timer_pulse_if (
  input logic clk,
  input logic rst_n
);
  logic sample_tick;
  logic irq_timer;

  // Modport for testbench monitoring
  modport monitor (
    input clk,
    input rst_n,
    input sample_tick,
    input irq_timer
  );

endinterface : timer_pulse_if

`endif // TIMER_PULSE_IF_SV
