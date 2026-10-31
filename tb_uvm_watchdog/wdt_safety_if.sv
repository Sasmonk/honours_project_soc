// =============================================================================
// Interface    : wdt_safety_if.sv
// Description  : Interface for Watchdog Safety signals (NMI, reset, heartbeats)
// =============================================================================
`ifndef WDT_SAFETY_IF_SV
`define WDT_SAFETY_IF_SV

interface wdt_safety_if (
  input logic clk,
  input logic rst_n
);
  logic [3:0] pipeline_alive;
  logic       nmi_prewarn;
  logic       wdt_reset;
  logic       wdt_reset_out;

  modport monitor (
    input clk,
    input rst_n,
    input pipeline_alive,
    input nmi_prewarn,
    input wdt_reset,
    input wdt_reset_out
  );

  modport driver (
    input  clk,
    input  rst_n,
    output pipeline_alive
  );

endinterface : wdt_safety_if

`endif // WDT_SAFETY_IF_SV
