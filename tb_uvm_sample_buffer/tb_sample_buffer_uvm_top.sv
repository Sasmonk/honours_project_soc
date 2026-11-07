// =============================================================================
// Top Testbench : tb_sample_buffer_uvm_top.sv
// Description   : Multi-Clock UVM Harness instantiating Sample Buffer & VIPs
// =============================================================================
`timescale 1ns / 1ps

module tb_sample_buffer_uvm_top;

  import uvm_pkg::*;
  import axi_pkg::*;
  import sbuf_uvm_pkg::*;

  // Clocks
  logic clk_sys; // 50 MHz (20 ns)
  logic rst_sys_n;
  logic clk_vga; // 25 MHz (40 ns)
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
    @(posedge clk_sys);
    rst_sys_n = 1'b1;
    @(posedge clk_vga);
    rst_vga_n = 1'b1;
  end

  // Physical Interfaces
  axi_if      axi_bus (.clk(clk_sys), .rst_n(rst_sys_n));
  sbuf_dma_if dma_bus (.clk_sys(clk_sys), .rst_sys_n(rst_sys_n));
  sbuf_vga_if vga_bus (.clk_vga(clk_vga), .rst_vga_n(rst_vga_n));

  wire active_wr_buf;
  wire active_rd_buf;
  wire [15:0] sbuf_rdata_wire;

  assign dma_bus.active_wr_buf   = active_wr_buf;
  assign dma_bus.active_rd_buf   = active_rd_buf;
  assign vga_bus.sbuf_rdata      = sbuf_rdata_wire;
  assign vga_bus.rd_buf_sel_vga  = u_dut.rd_buf_sel_vga;

  // DUT Instance
  sample_buffer #(
    .ADDR_WIDTH    (32),
    .DATA_WIDTH    (32),
    .BUFFER_DEPTH  (4096),
    .BUF_ADDR_WIDTH(12)
  ) u_dut (
    .clk_sys        (clk_sys),
    .rst_sys_n      (rst_sys_n),
    .sbuf_waddr     (dma_bus.sbuf_waddr),
    .sbuf_wdata     (dma_bus.sbuf_wdata),
    .sbuf_we        (dma_bus.sbuf_we),
    .buf_swap_req   (dma_bus.buf_swap_req),
    .vga_vsync_pulse(dma_bus.vga_vsync_pulse),
    .active_wr_buf  (active_wr_buf),
    .active_rd_buf  (active_rd_buf),
    .clk_vga        (clk_vga),
    .rst_vga_n      (rst_vga_n),
    .sbuf_raddr     (vga_bus.sbuf_raddr),
    .sbuf_rdata     (sbuf_rdata_wire),
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
    .s_axi_rready   (axi_bus.rready)
  );

  // ---------------------------------------------------------------------------
  // SystemVerilog Assertions (SVA)
  // ---------------------------------------------------------------------------

  // SVA_BUF_01: Active write buffer and read buffer should never be identical
  // in Ping-Pong double buffering mode (except during reset).
  property p_sva_buf_01;
    @(posedge clk_sys) disable iff (!rst_sys_n)
    u_dut.ping_pong_en |-> (active_wr_buf != active_rd_buf);
  endproperty
  SVA_BUF_01_Check: assert property (p_sva_buf_01)
    else `uvm_error("SVA_BUF_01", "Bank Collision! active_wr_buf equals active_rd_buf in Ping-Pong mode")

  // SVA_BUF_02: Tear-free swap only triggered on swap_req, wrap, or manual swap
  property p_sva_buf_02;
    @(posedge clk_sys) disable iff (!rst_sys_n)
    $changed(active_wr_buf) |-> ($past(u_dut.pending_swap) || $past(axi_bus.wvalid && axi_bus.wdata[2]));
  endproperty
  SVA_BUF_02_Check: assert property (p_sva_buf_02)
    else `uvm_error("SVA_BUF_02", "Unexpected Bank Swap occurred without valid swap condition!")

  // SVA_CDC_01: Asynchronous CDC 2-stage synchronizer stability
  property p_sva_cdc_01;
    @(posedge clk_vga) disable iff (!rst_vga_n)
    !$isunknown(u_dut.rd_buf_sel_vga);
  endproperty
  SVA_CDC_01_Check: assert property (p_sva_cdc_01)
    else `uvm_error("SVA_CDC_01", "Metastability or unknown X on rd_buf_sel_vga in VGA domain!")

  // UVM Registration and Test Launch
  initial begin
    uvm_config_db#(virtual axi_if)::set(null, "*", "vif", axi_bus);
    uvm_config_db#(virtual sbuf_dma_if)::set(null, "*", "dma_vif", dma_bus);
    uvm_config_db#(virtual sbuf_vga_if)::set(null, "*", "vga_vif", vga_bus);

    if ($test$plusargs("FSDB")) begin
      $fsdbDumpfile("sbuf_uvm.fsdb");
      $fsdbDumpvars(0, tb_sample_buffer_uvm_top, "+all");
    end
    if ($test$plusargs("VCD")) begin
      $dumpfile("sbuf_uvm.vcd");
      $dumpvars(0, tb_sample_buffer_uvm_top);
    end

    run_test();
  end

endmodule : tb_sample_buffer_uvm_top
