// =============================================================================
// Top Testbench : tb_vga_uvm_top.sv
// Description   : Top-Level UVM Harness instantiating VGA Controller DUT & VIPs
// =============================================================================
`timescale 1ns / 1ps

module tb_vga_uvm_top;

  import uvm_pkg::*;
  import axi_pkg::*;
  import vga_uvm_pkg::*;

  // Clocks
  logic clk_sys; // 50 MHz
  logic rst_sys_n;
  logic clk_vga; // 25 MHz pixel clock
  logic rst_vga_n;

  // 50 MHz System Clock
  initial begin
    clk_sys = 1'b0;
    forever #10 clk_sys = ~clk_sys;
  end

  // 25 MHz Pixel Clock
  initial begin
    clk_vga = 1'b0;
    forever #20 clk_vga = ~clk_vga;
  end

  // Reset Generation
  initial begin
    rst_sys_n = 1'b0;
    rst_vga_n = 1'b0;
    #100;
    @(negedge clk_sys);
    rst_sys_n = 1'b1;
    @(negedge clk_vga);
    rst_vga_n = 1'b1;
  end

  // Physical Interfaces
  axi_if       axi_bus (.clk(clk_sys), .rst_n(rst_sys_n));
  vga_pixel_if vga_bus (.clk_vga(clk_vga), .rst_vga_n(rst_vga_n));

  wire        u_vga_hsync;
  wire        u_vga_vsync;
  wire [3:0]  u_vga_red;
  wire [3:0]  u_vga_green;
  wire [3:0]  u_vga_blue;
  wire        u_vga_vsync_pulse;
  wire [11:0] u_sbuf_raddr;
  wire        u_irq_vga_frame;

  assign vga_bus.vga_hsync       = u_vga_hsync;
  assign vga_bus.vga_vsync       = u_vga_vsync;
  assign vga_bus.vga_red         = u_vga_red;
  assign vga_bus.vga_green       = u_vga_green;
  assign vga_bus.vga_blue        = u_vga_blue;
  assign vga_bus.vga_vsync_pulse = u_vga_vsync_pulse;
  assign vga_bus.irq_vga_frame   = u_irq_vga_frame;
  assign vga_bus.sbuf_raddr      = u_sbuf_raddr;

  // DUT Instance
  vga_controller #(
    .ADDR_WIDTH    (32),
    .DATA_WIDTH    (32),
    .BUF_ADDR_WIDTH(12)
  ) u_dut (
    .clk_sys        (clk_sys),
    .rst_sys_n      (rst_sys_n),
    .clk_vga        (clk_vga),
    .rst_vga_n      (rst_vga_n),
    .sbuf_raddr     (u_sbuf_raddr),
    .sbuf_rdata     (vga_bus.sbuf_rdata),
    .vga_vsync_pulse(u_vga_vsync_pulse),
    .vga_hsync      (u_vga_hsync),
    .vga_vsync      (u_vga_vsync),
    .vga_red        (u_vga_red),
    .vga_green      (u_vga_green),
    .vga_blue       (u_vga_blue),
    .s_axi_awaddr   (axi_bus.awaddr),
    .s_axi_awvalid  (axi_bus.awvalid),
    .s_axi_awready  (axi_bus.awready),
    .s_axi_wdata    (axi_bus.wdata),
    .s_axi_wstrb    (axi_bus.wstrb),
    .s_axi_wvalid   (axi_bus.wvalid),
    .s_axi_wready   (axi_bus.wready),
    .s_axi_bresp    (axi_bus.bresp),
    .s_axi_bvalid   (axi_bus.bvalid),
    .s_axi_bready   (axi_bus.bready),
    .s_axi_araddr   (axi_bus.araddr),
    .s_axi_arvalid  (axi_bus.arvalid),
    .s_axi_arready  (axi_bus.arready),
    .s_axi_rdata    (axi_bus.rdata),
    .s_axi_rresp    (axi_bus.rresp),
    .s_axi_rvalid   (axi_bus.rvalid),
    .s_axi_rready   (axi_bus.rready),
    .irq_vga_frame  (u_irq_vga_frame)
  );

  // ---------------------------------------------------------------------------
  // SystemVerilog Assertions (SVA)
  // ---------------------------------------------------------------------------

  // SVA_VGA_01: HSYNC width must equal 96 pixel clocks when active low
  property p_sva_vga_hsync;
    @(posedge clk_vga) disable iff (!rst_vga_n)
    $fell(u_vga_hsync) |-> (!u_vga_hsync)[*96] ##1 u_vga_hsync;
  endproperty
  SVA_VGA_01_Check: assert property (p_sva_vga_hsync)
    else `uvm_error("SVA_VGA_01", "HSYNC active pulse duration is not exactly 96 clocks!")

  // SVA_VGA_02: RGB signals must be strictly 0 outside the 640x480 active region
  property p_sva_vga_blanking;
    @(posedge clk_vga) disable iff (!rst_vga_n)
    $past(!u_dut.active_video) |-> (u_vga_red == 4'h0 && u_vga_green == 4'h0 && u_vga_blue == 4'h0);
  endproperty
  SVA_VGA_02_Check: assert property (p_sva_vga_blanking)
    else `uvm_error("SVA_VGA_02", "Zero blanking violation! Non-zero RGB during blanking region")

  // UVM Registration and Test Launch
  initial begin
    uvm_config_db#(virtual axi_if)::set(null, "*", "vif", axi_bus);
    uvm_config_db#(virtual vga_pixel_if)::set(null, "*", "vga_vif", vga_bus);

    if ($test$plusargs("FSDB")) begin
      $fsdbDumpfile("vga_uvm.fsdb");
      $fsdbDumpvars(0, tb_vga_uvm_top, "+all");
    end
    if ($test$plusargs("VCD")) begin
      $dumpfile("vga_uvm.vcd");
      $dumpvars(0, tb_vga_uvm_top);
    end

    run_test();
  end

endmodule : tb_vga_uvm_top
