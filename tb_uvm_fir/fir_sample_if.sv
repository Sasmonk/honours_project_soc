// =============================================================================
// Interface    : fir_sample_if.sv
// Description  : Interface for FIR streaming sample input, output, and IRQ
// =============================================================================
`ifndef FIR_SAMPLE_IF_SV
`define FIR_SAMPLE_IF_SV

interface fir_sample_if (
  input logic clk,
  input logic rst_n
);
  logic signed [15:0] fir_sample_in;
  logic               fir_sample_valid_in;
  logic signed [15:0] fir_sample_out;
  logic               fir_sample_valid_out;
  logic               irq_fir;

  modport driver (
    input  clk,
    input  rst_n,
    output fir_sample_in,
    output fir_sample_valid_in
  );

  modport monitor (
    input clk,
    input rst_n,
    input fir_sample_in,
    input fir_sample_valid_in,
    input fir_sample_out,
    input fir_sample_valid_out,
    input irq_fir
  );

endinterface : fir_sample_if

`endif // FIR_SAMPLE_IF_SV
