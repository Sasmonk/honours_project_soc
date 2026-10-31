// =============================================================================
// Interface   : watchdog_if.sv
// Description : Standard UVM SystemVerilog Interface for WATCHDOG
// =============================================================================
`timescale 1ns / 1ps

interface watchdog_if (input logic clk, input logic rst_n);

  // Physical Bus Signals
  logic [3:0] pipeline_alive;
  logic        nmi_prewarn;
  logic        wdt_reset;
  logic        wdt_reset_out;
  logic [31:0] s_axi_awaddr;
  logic        s_axi_awvalid;
  logic        s_axi_awready;
  logic [31:0] s_axi_wdata;
  logic [3:0] s_axi_wstrb;
  logic        s_axi_wvalid;
  logic        s_axi_wready;
  logic [1:0] s_axi_bresp;
  logic        s_axi_bvalid;
  logic        s_axi_bready;
  logic [31:0] s_axi_araddr;
  logic        s_axi_arvalid;
  logic        s_axi_arready;
  logic [31:0] s_axi_rdata;
  logic [1:0] s_axi_rresp;
  logic        s_axi_rvalid;
  logic        s_axi_rready;

  // Master Clocking Block (Driver perspective)
  clocking master_cb @(posedge clk);
    default input #1step output #1;
    output pipeline_alive;
    input  nmi_prewarn;
    input  wdt_reset;
    input  wdt_reset_out;
    output s_axi_awaddr;
    output s_axi_awvalid;
    input  s_axi_awready;
    output s_axi_wdata;
    output s_axi_wstrb;
    output s_axi_wvalid;
    input  s_axi_wready;
    input  s_axi_bresp;
    input  s_axi_bvalid;
    output s_axi_bready;
    output s_axi_araddr;
    output s_axi_arvalid;
    input  s_axi_arready;
    input  s_axi_rdata;
    input  s_axi_rresp;
    input  s_axi_rvalid;
    output s_axi_rready;
  endclocking

  // Monitor Clocking Block (Passive sampling)
  clocking monitor_cb @(posedge clk);
    default input #1step output #1;
    input  pipeline_alive;
    input  nmi_prewarn;
    input  wdt_reset;
    input  wdt_reset_out;
    input  s_axi_awaddr;
    input  s_axi_awvalid;
    input  s_axi_awready;
    input  s_axi_wdata;
    input  s_axi_wstrb;
    input  s_axi_wvalid;
    input  s_axi_wready;
    input  s_axi_bresp;
    input  s_axi_bvalid;
    input  s_axi_bready;
    input  s_axi_araddr;
    input  s_axi_arvalid;
    input  s_axi_arready;
    input  s_axi_rdata;
    input  s_axi_rresp;
    input  s_axi_rvalid;
    input  s_axi_rready;
  endclocking

  // Modports
  modport master_mp (clocking master_cb, input clk, input rst_n);
  modport monitor_mp (clocking monitor_cb, input clk, input rst_n);

endinterface : watchdog_if
