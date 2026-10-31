// =============================================================================
// Top Testbench : tb_spi_uvm_top.sv
// Description   : Top-Level UVM Harness instantiating SPI Controller DUT and VIPs
// =============================================================================
`timescale 1ns / 1ps

module tb_spi_uvm_top;

  import uvm_pkg::*;
  import axi_pkg::*;
  import spi_uvm_pkg::*;

  // Clock & Reset
  logic clk;
  logic rst_n;

  // 50 MHz System Clock Generation (20ns period)
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
  axi_if     axi_bus (.clk(clk), .rst_n(rst_n));
  spi_adc_if spi_bus (.clk(clk), .rst_n(rst_n));

  // Wires for DUT outputs
  wire        u_sck;
  wire        u_mosi;
  wire        u_cs_n;
  wire        u_sample_ready;
  wire [15:0] u_sample_data;
  wire        u_irq_spi;

  // Connect DUT outputs to interface
  assign spi_bus.adc_spi_sck  = u_sck;
  assign spi_bus.adc_spi_mosi = u_mosi;
  assign spi_bus.adc_spi_cs_n = u_cs_n;
  assign spi_bus.sample_ready = u_sample_ready;
  assign spi_bus.sample_data  = u_sample_data;
  assign spi_bus.irq_spi      = u_irq_spi;

  // SPI Controller DUT Instance
  spi_controller #(
    .ADDR_WIDTH(32),
    .DATA_WIDTH(32)
  ) u_dut (
    .clk           (clk),
    .rst_n         (rst_n),
    .sample_tick   (spi_bus.sample_tick),
    .adc_spi_sck   (u_sck),
    .adc_spi_mosi  (u_mosi),
    .adc_spi_miso  (spi_bus.adc_spi_miso),
    .adc_spi_cs_n  (u_cs_n),
    .sample_ready  (u_sample_ready),
    .sample_data   (u_sample_data),
    .s_axi_awaddr  (axi_bus.awaddr),
    .s_axi_awvalid (axi_bus.awvalid),
    .s_axi_awready (axi_bus.awready),
    .s_axi_wdata   (axi_bus.wdata),
    .s_axi_wstrb   (axi_bus.wstrb),
    .s_axi_wvalid  (axi_bus.wvalid),
    .s_axi_wready  (axi_bus.wready),
    .s_axi_bresp   (axi_bus.bresp),
    .s_axi_bvalid  (axi_bus.bvalid),
    .s_axi_bready  (axi_bus.bready),
    .s_axi_araddr  (axi_bus.araddr),
    .s_axi_arvalid (axi_bus.arvalid),
    .s_axi_arready (axi_bus.arready),
    .s_axi_rdata   (axi_bus.rdata),
    .s_axi_rresp   (axi_bus.rresp),
    .s_axi_rvalid  (axi_bus.rvalid),
    .s_axi_rready  (axi_bus.rready),
    .irq_spi       (u_irq_spi)
  );

  // UVM Registration and Test Launch
  initial begin
    uvm_config_db#(virtual axi_if)::set(null, "*", "vif", axi_bus);
    uvm_config_db#(virtual spi_adc_if)::set(null, "*", "spi_vif", spi_bus);

    if ($test$plusargs("FSDB")) begin
      $fsdbDumpfile("spi_uvm.fsdb");
      $fsdbDumpvars(0, tb_spi_uvm_top, "+all");
    end
    if ($test$plusargs("VCD")) begin
      $dumpfile("spi_uvm.vcd");
      $dumpvars(0, tb_spi_uvm_top);
    end

    run_test();
  end

endmodule : tb_spi_uvm_top
