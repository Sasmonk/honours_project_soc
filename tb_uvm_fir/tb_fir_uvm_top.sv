// =============================================================================
// Top Testbench : tb_fir_uvm_top.sv
// Description   : Top-Level UVM Harness instantiating FIR Filter DUT and VIPs
// =============================================================================
`timescale 1ns / 1ps

module tb_fir_uvm_top;

  import uvm_pkg::*;
  import axi_pkg::*;
  import fir_uvm_pkg::*;

  // Clock & Reset
  logic clk;
  logic rst_n;

  // 50 MHz System Clock (20ns period)
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
  axi_if        axi_bus (.clk(clk), .rst_n(rst_n));
  fir_sample_if fir_bus (.clk(clk), .rst_n(rst_n));

  wire signed [15:0] u_sample_out;
  wire               u_sample_valid_out;
  wire               u_irq_fir;

  assign fir_bus.fir_sample_out       = u_sample_out;
  assign fir_bus.fir_sample_valid_out = u_sample_valid_out;
  assign fir_bus.irq_fir              = u_irq_fir;

  // FIR Filter DUT Instance
  fir_filter #(
    .ADDR_WIDTH(32),
    .DATA_WIDTH(32),
    .MAX_TAPS  (16)
  ) u_dut (
    .clk                  (clk),
    .rst_n                (rst_n),
    .fir_sample_in        (fir_bus.fir_sample_in),
    .fir_sample_valid_in  (fir_bus.fir_sample_valid_in),
    .fir_sample_out       (u_sample_out),
    .fir_sample_valid_out (u_sample_valid_out),
    .s_axi_awaddr         (axi_bus.awaddr),
    .s_axi_awvalid        (axi_bus.awvalid),
    .s_axi_awready        (axi_bus.awready),
    .s_axi_wdata          (axi_bus.wdata),
    .s_axi_wstrb          (axi_bus.wstrb),
    .s_axi_wvalid         (axi_bus.wvalid),
    .s_axi_wready         (axi_bus.wready),
    .s_axi_bresp          (axi_bus.bresp),
    .s_axi_bvalid         (axi_bus.bvalid),
    .s_axi_bready         (axi_bus.bready),
    .s_axi_araddr         (axi_bus.araddr),
    .s_axi_arvalid        (axi_bus.arvalid),
    .s_axi_arready        (axi_bus.arready),
    .s_axi_rdata          (axi_bus.rdata),
    .s_axi_rresp          (axi_bus.rresp),
    .s_axi_rvalid         (axi_bus.rvalid),
    .s_axi_rready         (axi_bus.rready),
    .irq_fir              (u_irq_fir)
  );

  // UVM Registration and Test Launch
  initial begin
    uvm_config_db#(virtual axi_if)::set(null, "*", "vif", axi_bus);
    uvm_config_db#(virtual fir_sample_if)::set(null, "*", "fir_vif", fir_bus);

    if ($test$plusargs("FSDB")) begin
      $fsdbDumpfile("fir_uvm.fsdb");
      $fsdbDumpvars(0, tb_fir_uvm_top, "+all");
    end
    if ($test$plusargs("VCD")) begin
      $dumpfile("fir_uvm.vcd");
      $dumpvars(0, tb_fir_uvm_top);
    end

    run_test();
  end

endmodule : tb_fir_uvm_top
