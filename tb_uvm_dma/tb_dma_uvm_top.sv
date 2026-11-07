// =============================================================================
// Top TB       : tb_dma_uvm_top.sv
// Description  : Top-level UVM Testbench for Autonomous DMA Controller
// =============================================================================
`timescale 1ns / 1ps

import uvm_pkg::*;
import axi_pkg::*;
import dma_uvm_pkg::*;
`include "uvm_macros.svh"

module tb_dma_uvm_top;

  localparam CLK_PERIOD_NS = 10; // 100 MHz System Clock

  logic clk;
  logic rst_n;

  // Clock Generation
  initial clk = 1'b0;
  always #(CLK_PERIOD_NS / 2) clk = ~clk;

  // Reset Generation
  initial begin
    rst_n = 1'b0;
    #(CLK_PERIOD_NS * 5);
    @(negedge clk);
    rst_n = 1'b1;
  end

  // Physical Interfaces
  axi_if        axi_bus (.clk(clk), .rst_n(rst_n));
  dma_stream_if dma_bus (.clk(clk), .rst_n(rst_n));

  // DUT Instance
  dma_controller #(
    .ADDR_WIDTH    (32),
    .DATA_WIDTH    (32),
    .ID_WIDTH      (8),
    .BUF_ADDR_WIDTH(12)
  ) u_dut (
    .clk                  (clk),
    .rst_n                (rst_n),

    // Timer Acquisition Strobe
    .sample_tick          (dma_bus.sample_tick),

    // Hardware Interface to SPI Controller
    .spi_sample_ready     (dma_bus.spi_sample_ready),
    .spi_sample_data      (dma_bus.spi_sample_data),

    // Legacy / Direct SPI Pins
    .adc_spi_sck          (dma_bus.adc_spi_sck),
    .adc_spi_mosi         (dma_bus.adc_spi_mosi),
    .adc_spi_miso         (dma_bus.adc_spi_miso),
    .adc_spi_cs_n         (dma_bus.adc_spi_cs_n),

    // FIR Filter Streaming Interface
    .fir_sample_in        (dma_bus.fir_sample_in),
    .fir_sample_valid_in  (dma_bus.fir_sample_valid_in),
    .fir_sample_out       (dma_bus.fir_sample_out),
    .fir_sample_valid_out (dma_bus.fir_sample_valid_out),

    // Ping-Pong Sample Buffer Interface
    .sbuf_waddr           (dma_bus.sbuf_waddr),
    .sbuf_wdata           (dma_bus.sbuf_wdata),
    .sbuf_we              (dma_bus.sbuf_we),
    .buf_swap_req         (dma_bus.buf_swap_req),

    // AXI4 Master Interface
    .m_axi_awid           (dma_bus.m_axi_awid),
    .m_axi_awaddr         (dma_bus.m_axi_awaddr),
    .m_axi_awlen          (dma_bus.m_axi_awlen),
    .m_axi_awsize         (dma_bus.m_axi_awsize),
    .m_axi_awburst        (dma_bus.m_axi_awburst),
    .m_axi_awlock         (dma_bus.m_axi_awlock),
    .m_axi_awcache        (dma_bus.m_axi_awcache),
    .m_axi_awprot         (dma_bus.m_axi_awprot),
    .m_axi_awqos          (dma_bus.m_axi_awqos),
    .m_axi_awvalid        (dma_bus.m_axi_awvalid),
    .m_axi_awready        (dma_bus.m_axi_awready),

    .m_axi_wdata          (dma_bus.m_axi_wdata),
    .m_axi_wstrb          (dma_bus.m_axi_wstrb),
    .m_axi_wlast          (dma_bus.m_axi_wlast),
    .m_axi_wvalid         (dma_bus.m_axi_wvalid),
    .m_axi_wready         (dma_bus.m_axi_wready),

    .m_axi_bid            (dma_bus.m_axi_bid),
    .m_axi_bresp          (dma_bus.m_axi_bresp),
    .m_axi_bvalid         (dma_bus.m_axi_bvalid),
    .m_axi_bready         (dma_bus.m_axi_bready),

    .m_axi_arid           (dma_bus.m_axi_arid),
    .m_axi_araddr         (dma_bus.m_axi_araddr),
    .m_axi_arlen          (dma_bus.m_axi_arlen),
    .m_axi_arsize         (dma_bus.m_axi_arsize),
    .m_axi_arburst        (dma_bus.m_axi_arburst),
    .m_axi_arlock         (dma_bus.m_axi_arlock),
    .m_axi_arcache        (dma_bus.m_axi_arcache),
    .m_axi_arprot         (dma_bus.m_axi_arprot),
    .m_axi_arqos          (dma_bus.m_axi_arqos),
    .m_axi_arvalid        (dma_bus.m_axi_arvalid),
    .m_axi_arready        (dma_bus.m_axi_arready),

    .m_axi_rid            (dma_bus.m_axi_rid),
    .m_axi_rdata          (dma_bus.m_axi_rdata),
    .m_axi_rresp          (dma_bus.m_axi_rresp),
    .m_axi_rlast          (dma_bus.m_axi_rlast),
    .m_axi_rvalid         (dma_bus.m_axi_rvalid),
    .m_axi_rready         (dma_bus.m_axi_rready),

    // AXI4-Lite Slave CSR Interface
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

    // Interrupts
    .irq_dma_done         (dma_bus.irq_dma_done),
    .irq_dma_err          (dma_bus.irq_dma_err)
  );

  // ---------------------------------------------------------------------------
  // SystemVerilog Assertions (SVA)
  // ---------------------------------------------------------------------------

  // SVA_DMA_01: AXI4 Master write bursts must assert wlast on single-beat transfers (awlen == 0)
  property p_sva_dma_wlast;
    @(posedge clk) disable iff (!rst_n)
    (dma_bus.m_axi_wvalid && (dma_bus.m_axi_awlen == 8'd0)) |-> dma_bus.m_axi_wlast;
  endproperty
  SVA_DMA_01_Check: assert property (p_sva_dma_wlast)
    else `uvm_error("SVA_DMA_01", "m_axi_wlast was not asserted on single-beat AXI write transaction!")

  // SVA_DMA_02: Maximum Bus Stall Watchdog Protection
  // If DMA is BUSY and timeout_counter exceeds dma_timeout, irq_dma_err must assert
  property p_sva_dma_timeout_err;
    @(posedge clk) disable iff (!rst_n)
    (u_dut.dma_busy && (u_dut.timeout_counter >= u_dut.dma_timeout)) |=> dma_bus.irq_dma_err;
  endproperty
  SVA_DMA_02_Check: assert property (p_sva_dma_timeout_err)
    else `uvm_error("SVA_DMA_02", "DMA Controller failed to assert irq_dma_err on timeout expiration!")

  // UVM Registration and Test Launch
  initial begin
    uvm_config_db#(virtual axi_if)::set(null, "*", "vif", axi_bus);
    uvm_config_db#(virtual dma_stream_if)::set(null, "*", "dma_vif", dma_bus);

    if ($test$plusargs("FSDB")) begin
      $fsdbDumpfile("dma_uvm.fsdb");
      $fsdbDumpvars(0, tb_dma_uvm_top, "+all");
    end
    if ($test$plusargs("VCD")) begin
      $dumpfile("dma_uvm.vcd");
      $dumpvars(0, tb_dma_uvm_top);
    end

    run_test();
  end

endmodule : tb_dma_uvm_top
