// =============================================================================
// Interface   : spi_if.sv
// Description : Standard UVM SystemVerilog Interface for SPI
// =============================================================================
`timescale 1ns / 1ps

interface spi_if (input logic clk, input logic rst_n);

  // Physical Bus Signals
  logic        sample_tick;
  logic        adc_spi_sck;
  logic        adc_spi_mosi;
  logic        adc_spi_miso;
  logic        adc_spi_cs_n;
  logic        sample_ready;
  logic [15:0] sample_data;
  logic        irq_spi;
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
    output sample_tick;
    input  adc_spi_sck;
    input  adc_spi_mosi;
    output adc_spi_miso;
    input  adc_spi_cs_n;
    input  sample_ready;
    input  sample_data;
    input  irq_spi;
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
    input  sample_tick;
    input  adc_spi_sck;
    input  adc_spi_mosi;
    input  adc_spi_miso;
    input  adc_spi_cs_n;
    input  sample_ready;
    input  sample_data;
    input  irq_spi;
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

endinterface : spi_if
