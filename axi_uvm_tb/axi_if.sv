// =============================================================================
// Interface   : axi_if.sv
// Description : Standard UVM SystemVerilog Interface for AXI
// =============================================================================
`timescale 1ns / 1ps

interface axi_if (input logic clk, input logic rst_n);

  // Physical Bus Signals
  logic [31:0] awaddr;
  logic [2:0] awprot;
  logic        awvalid;
  logic        awready;
  logic [31:0] wdata;
  logic [3:0] wstrb;
  logic        wvalid;
  logic        wready;
  logic [1:0] bresp;
  logic        bvalid;
  logic        bready;
  logic [31:0] araddr;
  logic [2:0] arprot;
  logic        arvalid;
  logic        arready;
  logic [31:0] rdata;
  logic [1:0] rresp;
  logic        rvalid;
  logic        rready;

  // Master Clocking Block (Driver perspective)
  clocking master_cb @(posedge clk);
    default input #1step output #1;
    output awaddr;
    output awprot;
    output awvalid;
    input  awready;
    output wdata;
    output wstrb;
    output wvalid;
    input  wready;
    input  bresp;
    input  bvalid;
    output bready;
    output araddr;
    output arprot;
    output arvalid;
    input  arready;
    input  rdata;
    input  rresp;
    input  rvalid;
    output rready;
  endclocking

  // Monitor Clocking Block (Passive sampling)
  clocking monitor_cb @(posedge clk);
    default input #1step output #1;
    input  awaddr;
    input  awprot;
    input  awvalid;
    input  awready;
    input  wdata;
    input  wstrb;
    input  wvalid;
    input  wready;
    input  bresp;
    input  bvalid;
    input  bready;
    input  araddr;
    input  arprot;
    input  arvalid;
    input  arready;
    input  rdata;
    input  rresp;
    input  rvalid;
    input  rready;
  endclocking

  // Modports
  modport master_mp (clocking master_cb, input clk, input rst_n);
  modport monitor_mp (clocking monitor_cb, input clk, input rst_n);

endinterface : axi_if
