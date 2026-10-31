// =============================================================================
// Interface   : sample_buffer_if.sv
// Description : Standard UVM SystemVerilog Interface for SAMPLE_BUFFER
// =============================================================================
`timescale 1ns / 1ps

interface sample_buffer_if (input logic clk_sys, input logic rst_sys_n);

  // Physical Bus Signals
  logic [11:0] sbuf_waddr;
  logic [15:0] sbuf_wdata;
  logic        sbuf_we;
  logic        buf_swap_req;
  logic        vga_vsync_pulse;
  logic        active_wr_buf;
  logic        active_rd_buf;
  logic        clk_vga;
  logic        rst_vga_n;
  logic [11:0] sbuf_raddr;
  logic [15:0] sbuf_rdata;
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
    output sbuf_waddr;
    output sbuf_wdata;
    output sbuf_we;
    output buf_swap_req;
    output vga_vsync_pulse;
    input  active_wr_buf;
    input  active_rd_buf;
    output clk_vga;
    output rst_vga_n;
    output sbuf_raddr;
    input  sbuf_rdata;
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
    input  sbuf_waddr;
    input  sbuf_wdata;
    input  sbuf_we;
    input  buf_swap_req;
    input  vga_vsync_pulse;
    input  active_wr_buf;
    input  active_rd_buf;
    input  clk_vga;
    input  rst_vga_n;
    input  sbuf_raddr;
    input  sbuf_rdata;
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

endinterface : sample_buffer_if
