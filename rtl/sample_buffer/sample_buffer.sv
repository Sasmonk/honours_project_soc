// =============================================================================
// Module      : sample_buffer.sv
// Description : Dual-Port Asynchronous Sample Buffer RAM with CDC & AXI4-Lite Read
// Specification: Architecture Document Section 2.3 & 8.1
//   - Memory  : 4096 x 16-bit Samples (8 KB)
//   - Port A  : Write Port (clk_sys) driven by DMA Controller
//   - Port B  : Read Port (clk_vga) read by VGA Oscilloscope Controller
//   - Port C  : AXI4-Lite Slave Read Port (clk_sys) for CPU measurement math (DP5)
// =============================================================================

`timescale 1ns / 1ps
`default_nettype none

module sample_buffer #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter BUFFER_DEPTH = 4096,
    parameter BUF_ADDR_WIDTH = 12 // $clog2(4096)
)(
    // System Clock Domain (clk_sys)
    input  wire                      clk_sys,
    input  wire                      rst_sys_n,

    // Port A: DMA Hardware Write Port (clk_sys)
    input  wire [BUF_ADDR_WIDTH-1:0] sbuf_waddr,
    input  wire [15:0]               sbuf_wdata,
    input  wire                      sbuf_we,

    // Port B: VGA Controller Read Port (clk_vga domain)
    input  wire                      clk_vga,
    input  wire                      rst_vga_n,
    input  wire [BUF_ADDR_WIDTH-1:0] sbuf_raddr,
    output reg  [15:0]               sbuf_rdata,

    // Port C: AXI4-Lite Slave Interface (clk_sys domain for DP5 measurement reads)
    input  wire [ADDR_WIDTH-1:0]     s_axi_awaddr,
    input  wire                      s_axi_awvalid,
    output reg                       s_axi_awready,

    input  wire [DATA_WIDTH-1:0]     s_axi_wdata,
    input  wire [3:0]                s_axi_wstrb,
    input  wire                      s_axi_wvalid,
    output reg                       s_axi_wready,

    output reg  [1:0]                s_axi_bresp,
    output reg                       s_axi_bvalid,
    input  wire                      s_axi_bready,

    input  wire [ADDR_WIDTH-1:0]     s_axi_araddr,
    input  wire                      s_axi_arvalid,
    output reg                       s_axi_arready,

    output reg  [DATA_WIDTH-1:0]     s_axi_rdata,
    output reg  [1:0]                s_axi_rresp,
    output reg                       s_axi_rvalid,
    input  wire                      s_axi_rready
);

    // 4096 x 16-bit RAM
    reg [15:0] mem [0:BUFFER_DEPTH-1];

    // -------------------------------------------------------------------------
    // Port A: Synchronous Write (clk_sys)
    // -------------------------------------------------------------------------
    always @(posedge clk_sys) begin
        if (sbuf_we) begin
            mem[sbuf_waddr] <= sbuf_wdata;
        end
    end

    // -------------------------------------------------------------------------
    // Port B: Synchronous Read (clk_vga)
    // -------------------------------------------------------------------------
    always @(posedge clk_vga or negedge rst_vga_n) begin
        if (!rst_vga_n) begin
            sbuf_rdata <= 16'd0;
        end else begin
            sbuf_rdata <= mem[sbuf_raddr];
        end
    end

    // -------------------------------------------------------------------------
    // Port C: AXI4-Lite Read-Only Interface (clk_sys) for CPU DP5 Math
    // -------------------------------------------------------------------------
    // Memory map word address: byte address >> 2 (each 32-bit word holds two 16-bit samples)
    wire [BUF_ADDR_WIDTH-1:0] axi_sample_idx = s_axi_araddr[BUF_ADDR_WIDTH:1];

    always @(posedge clk_sys or negedge rst_sys_n) begin
        if (!rst_sys_n) begin
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rdata   <= {DATA_WIDTH{1'b0}};
            s_axi_rresp   <= 2'b00;
        end else begin
            if (s_axi_arvalid && !s_axi_rvalid) begin
                s_axi_arready <= 1'b1;
                s_axi_rvalid  <= 1'b1;
                s_axi_rresp   <= 2'b00;
                // Return 16-bit sample sign-extended or pair
                s_axi_rdata   <= {16'd0, mem[axi_sample_idx]};
            end else begin
                s_axi_arready <= 1'b0;
            end

            if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

    // Write responses (Sample Buffer is read-only via AXI bus for CPU)
    always @(posedge clk_sys or negedge rst_sys_n) begin
        if (!rst_sys_n) begin
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            s_axi_bvalid  <= 1'b0;
            s_axi_bresp   <= 2'b00;
        end else begin
            if (s_axi_awvalid && s_axi_wvalid && !s_axi_bvalid) begin
                s_axi_awready <= 1'b1;
                s_axi_wready  <= 1'b1;
                s_axi_bvalid  <= 1'b1;
                s_axi_bresp   <= 2'b10; // SLVERR (Read-only via bus)
            end else begin
                s_axi_awready <= 1'b0;
                s_axi_wready  <= 1'b0;
            end

            if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end

endmodule
