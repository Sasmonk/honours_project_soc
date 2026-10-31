// =============================================================================
// Interface   : vga_if.sv
// Description : Standard UVM SystemVerilog Interface for VGA
// =============================================================================
`timescale 1ns / 1ps

interface vga_if (input logic clk_sys, input logic rst_sys_n);

  // Physical Bus Signals
  logic        clk_vga;
  logic        rst_vga_n;
  logic [11:0] sbuf_raddr;
  logic [15:0] sbuf_rdata;
  logic        vga_vsync_pulse;
  logic        vga_hsync;
  logic        vga_vsync;
  logic [3:0] vga_red;
  logic [3:0] vga_green;
  logic [3:0] vga_blue;
  logic        irq_vga_frame;
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
  clocking master_cb @(posedge clk_sys);
    default input #1step output #1;
    output clk_vga;
    output rst_vga_n;
    input  sbuf_raddr;
    output sbuf_rdata;
    input  vga_vsync_pulse;
    input  vga_hsync;
    input  vga_vsync;
    input  vga_red;
    input  vga_green;
    input  vga_blue;
    input  irq_vga_frame;
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
  clocking monitor_cb @(posedge clk_sys);
    default input #1step output #1;
    input  clk_vga;
    input  rst_vga_n;
    input  sbuf_raddr;
    input  sbuf_rdata;
    input  vga_vsync_pulse;
    input  vga_hsync;
    input  vga_vsync;
    input  vga_red;
    input  vga_green;
    input  vga_blue;
    input  irq_vga_frame;
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
  modport master_mp (clocking master_cb, input clk_sys, input rst_sys_n);
  modport monitor_mp (clocking monitor_cb, input clk_sys, input rst_sys_n);

endinterface : vga_if
