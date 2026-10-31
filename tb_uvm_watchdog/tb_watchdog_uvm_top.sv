// =============================================================================
// Top Testbench : tb_watchdog_uvm_top.sv
// Description   : Top-Level UVM Harness instantiating Watchdog DUT and VIPs
// =============================================================================
`timescale 1ns / 1ps

module tb_watchdog_uvm_top;

  import uvm_pkg::*;
  import axi_pkg::*;
  import watchdog_uvm_pkg::*;

  // Clock & Reset
  logic clk;
  logic rst_n;

  // 50 MHz Clock Generation (20ns period)
  initial begin
    clk = 1'b0;
    forever #10 clk = ~clk;
  end

  // Reset Generation
  initial begin
    rst_n = 1'b0;
    #100;
    @(posedge clk);
    rst_n = 1'b1;
  end

  // Physical Interfaces
  axi_if        axi_bus    (.clk(clk), .rst_n(rst_n));
  wdt_safety_if safety_bus (.clk(clk), .rst_n(rst_n));

  wire u_nmi_prewarn;
  wire u_wdt_reset;
  wire u_wdt_reset_out;

  assign safety_bus.nmi_prewarn   = u_nmi_prewarn;
  assign safety_bus.wdt_reset     = u_wdt_reset;
  assign safety_bus.wdt_reset_out = u_wdt_reset_out;

  // Default pipeline heartbeats to alive
  assign safety_bus.pipeline_alive = 4'b1111;

  // Watchdog DUT Instance
  watchdog #(
    .ADDR_WIDTH(32),
    .DATA_WIDTH(32)
  ) u_dut (
    .clk            (clk),
    .rst_n          (rst_n),
    .pipeline_alive (safety_bus.pipeline_alive),
    .nmi_prewarn    (u_nmi_prewarn),
    .wdt_reset      (u_wdt_reset),
    .wdt_reset_out  (u_wdt_reset_out),
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

  // UVM Registration and Test Launch
  initial begin
    uvm_config_db#(virtual axi_if)::set(null, "*", "vif", axi_bus);
    uvm_config_db#(virtual wdt_safety_if)::set(null, "*", "safety_vif", safety_bus);

    if ($test$plusargs("FSDB")) begin
      $fsdbDumpfile("watchdog_uvm.fsdb");
      $fsdbDumpvars(0, tb_watchdog_uvm_top, "+all");
    end
    if ($test$plusargs("VCD")) begin
      $dumpfile("watchdog_uvm.vcd");
      $dumpvars(0, tb_watchdog_uvm_top);
    end

    run_test();
  end

endmodule : tb_watchdog_uvm_top
