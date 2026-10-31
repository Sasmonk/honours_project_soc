// =============================================================================
// Top Testbench : tb_uart_uvm_top.sv
// Description   : Top-Level UVM Harness instantiating 16550 UART DUT and VIPs
// =============================================================================
`timescale 1ns / 1ps

module tb_uart_uvm_top;

  import uvm_pkg::*;
  import axi_pkg::*;
  import uart_uvm_pkg::*;

  // Clock & Reset Signals
  logic clk;
  logic rst_n;

  // Clock Generation: 50 MHz (20ns period)
  initial begin
    clk = 1'b0;
    forever #10 clk = ~clk;
  end

  // Reset Generation: Assert active-low reset for 100ns
  initial begin
    rst_n = 1'b0;
    #100;
    @(posedge clk);
    rst_n = 1'b1;
  end

  // Instantiate Physical Interfaces
  axi_if         axi_bus    (.clk(clk), .rst_n(rst_n));
  uart_serial_if serial_bus (.clk(clk), .rst_n(rst_n));

  // Instantiate 16550 Standard AXI UART DUT
  axi_uart_top u_dut (
    .fixed_clk_i        (clk),
    .axi_aclk_i         (clk),
    .axi_aresetn_i      (rst_n),

    // Read Address Channel
    .axi_arid_i         (12'd0),
    .axi_araddr_i       (axi_bus.araddr[4:0]),
    .axi_arvalid_i      (axi_bus.arvalid),
    .axi_arready_o      (axi_bus.arready),

    // Read Data & Response Channel
    .axi_rid_o          (),
    .axi_rdata_o        (axi_bus.rdata),
    .axi_rresp_o        (axi_bus.rresp),
    .axi_rvalid_o       (axi_bus.rvalid),
    .axi_rready_i       (axi_bus.rready),

    // Write Address Channel
    .axi_awid_i         (12'd0),
    .axi_awaddr_i       (axi_bus.awaddr[4:0]),
    .axi_awvalid_i      (axi_bus.awvalid),
    .axi_awready_o      (axi_bus.awready),

    // Write Data Channel
    .axi_wdata_i        (axi_bus.wdata),
    .axi_wstrb_i        (axi_bus.wstrb),
    .axi_wvalid_i       (axi_bus.wvalid),
    .axi_wready_o       (axi_bus.wready),

    // Write Response Channel
    .axi_bid_o          (),
    .axi_bresp_o        (axi_bus.bresp),
    .axi_bvalid_o       (axi_bus.bvalid),
    .axi_bready_i       (axi_bus.bready),

    // Physical Serial Interface & Interrupt
    .uart_rx_i          (serial_bus.uart_rx),
    .uart_tx_o          (serial_bus.uart_tx),
    .read_interrupt_o   (serial_bus.uart_irq)
  );

  // Interface Configuration & Test Execution
  initial begin
    // Register interfaces in UVM config_db
    uvm_config_db#(virtual axi_if)::set(null, "*", "vif", axi_bus);
    uvm_config_db#(virtual uart_serial_if)::set(null, "*", "serial_vif", serial_bus);

    // Waveform Dumping Configuration
    if ($test$plusargs("FSDB")) begin
      $fsdbDumpfile("uart_uvm.fsdb");
      $fsdbDumpvars(0, tb_uart_uvm_top, "+all");
    end
    if ($test$plusargs("VCD")) begin
      $dumpfile("uart_uvm.vcd");
      $dumpvars(0, tb_uart_uvm_top);
    end

    // Run active test specified by +UVM_TESTNAME
    run_test();
  end

endmodule : tb_uart_uvm_top
