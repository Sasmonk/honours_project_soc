// =============================================================================
// Testbench Top: tb_watchdog_top.sv
// Description  : Self-contained UVM Testbench Top with Built-in AXI Memory Slave
// =============================================================================
`timescale 1ns / 1ps

module tb_watchdog_top;
  import uvm_pkg::*;
  import watchdog_pkg::*;

  logic clk;
  logic rst_n;

  // Clock generation (100 MHz)
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Reset generation
  initial begin
    rst_n = 0;
    #25 rst_n = 1;
  end

  // Virtual Interface Instance
  watchdog_if vif (.clk(clk), .rst_n(rst_n));

  // Built-in Standard AXI-Lite Slave Memory Responder
  reg [31:0] mem [bit [31:0]];

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      vif.awready <= 1'b0;
      vif.wready  <= 1'b0;
      vif.bvalid  <= 1'b0;
      vif.bresp   <= 2'b00;
      vif.arready <= 1'b0;
      vif.rvalid  <= 1'b0;
      vif.rdata   <= 32'd0;
      vif.rresp   <= 2'b00;
    end else begin
      // Write Address & Data Handshake
      vif.awready <= vif.awvalid;
      vif.wready  <= vif.wvalid;
      if (vif.awvalid && vif.wvalid && vif.awready && vif.wready) begin
        mem[vif.awaddr] <= vif.wdata;
        vif.bvalid      <= 1'b1;
        vif.bresp       <= 2'b00; // OKAY
      end
      if (vif.bvalid && vif.bready) begin
        vif.bvalid <= 1'b0;
      end

      // Read Address & Data Handshake
      vif.arready <= vif.arvalid;
      if (vif.arvalid && vif.arready) begin
        vif.rvalid <= 1'b1;
        vif.rresp  <= 2'b00; // OKAY
        if (mem.exists(vif.araddr)) begin
          vif.rdata <= mem[vif.araddr];
        end else begin
          vif.rdata <= 32'hDEAD_BEEF;
        end
      end
      if (vif.rvalid && vif.rready) begin
        vif.rvalid <= 1'b0;
      end
    end
  end

  // UVM Registration and Test Launch
  initial begin
    uvm_config_db#(virtual watchdog_if)::set(null, "*", "vif", vif);
    $timeformat(-9, 2, " ns", 20);

    // Verdi FSDB dump
    `ifdef DUMP_FSDB
      $fsdbDumpfile("uvm_watchdog_dump.fsdb");
      $fsdbDumpvars(0, tb_watchdog_top, "+all");
    `endif

    run_test();
  end
endmodule : tb_watchdog_top
