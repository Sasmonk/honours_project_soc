// =============================================================================
// Module      : dma_controller.sv
// Description : Autonomous Signal Acquisition & Streaming DMA Controller
// Specification: Architecture Document Section 8.6
//   - Registers:
//       0x00: DMA_CTRL     [0] START, [1] ABORT
//       0x04: DMA_SRC_ADDR [31:0] ADDR (0 = ADC SPI, >0 = Memory)
//       0x08: DMA_DST_ADDR [31:0] ADDR (Target address pointer)
//       0x0C: DMA_LEN      [15:0] LEN  (Transfer sample length)
//       0x10: DMA_TIMEOUT  [31:0] CYCLES
//       0x14: DMA_STATUS   [0] BUSY, [1] DONE, [2] OVF, [3] UNDERRUN, [4] TIMEOUT, [5] ERR
//   - Cross-IP Connections:
//       Input : sample_tick (from Timer)
//       SPI   : adc_spi_sck, adc_spi_mosi, adc_spi_miso, adc_spi_cs_n
//       FIR   : fir_sample_in, fir_sample_valid_in, fir_sample_out, fir_sample_valid_out
//       SBUF  : sbuf_waddr, sbuf_wdata, sbuf_we
//       IRQs  : irq_dma_done, irq_dma_err
// =============================================================================

`timescale 1ns / 1ps
`default_nettype none

module dma_controller #(
    parameter ADDR_WIDTH     = 32,
    parameter DATA_WIDTH     = 32,
    parameter BUF_ADDR_WIDTH = 12
)(
    input  wire                      clk,
    input  wire                      rst_n,

    // Timer Acquisition Strobe
    input  wire                      sample_tick,

    // SPI Master Interface to ADC Model
    output reg                       adc_spi_sck,
    output reg                       adc_spi_mosi,
    input  wire                      adc_spi_miso,
    output reg                       adc_spi_cs_n,

    // FIR Filter Streaming Interface
    output reg  signed [15:0]        fir_sample_in,
    output reg                       fir_sample_valid_in,
    input  wire signed [15:0]        fir_sample_out,
    input  wire                      fir_sample_valid_out,

    // Sample Buffer Write Port
    output reg  [BUF_ADDR_WIDTH-1:0] sbuf_waddr,
    output reg  [15:0]               sbuf_wdata,
    output reg                       sbuf_we,

    // AXI4-Lite Slave CSR Interface
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
    input  wire                      s_axi_rready,

    // Interrupt Outputs
    output wire                      irq_dma_done,
    output wire                      irq_dma_err
);

    // -------------------------------------------------------------------------
    // CSR Registers
    // -------------------------------------------------------------------------
    reg [31:0] dma_src_addr;
    reg [31:0] dma_dst_addr;
    reg [15:0] dma_len;
    reg [31:0] dma_timeout;

    reg        dma_busy;
    reg        dma_done;
    reg        dma_ovf;
    reg        dma_underrun;
    reg        dma_timeout_flag;
    reg        dma_err;

    assign irq_dma_done = dma_done;
    assign irq_dma_err  = dma_ovf || dma_underrun || dma_timeout_flag || dma_err;

    // -------------------------------------------------------------------------
    // DMA Control FSM
    // -------------------------------------------------------------------------
    localparam STATE_IDLE      = 3'd0;
    localparam STATE_WAIT_TICK = 3'd1;
    localparam STATE_SPI_XFER  = 3'd2;
    localparam STATE_TO_FIR    = 3'd3;
    localparam STATE_FROM_FIR  = 3'd4;
    localparam STATE_WRITE_BUF = 3'd5;
    localparam STATE_COMPLETE  = 3'd6;

    reg [2:0]  state;
    reg [15:0] samples_transferred;
    reg [31:0] timeout_counter;

    // SPI Engine Registers
    reg [4:0]  spi_bit_cnt;
    reg [15:0] spi_rx_shift;
    reg [3:0]  spi_clk_div;

    // -------------------------------------------------------------------------
    // AXI4-Lite Write Channel
    // -------------------------------------------------------------------------
    reg [ADDR_WIDTH-1:0] awaddr_latched;
    reg                  aw_done;
    reg                  w_done;

    wire write_req         = (aw_done && w_done && !s_axi_bvalid);
    wire start_req         = write_req && (awaddr_latched[7:0] == 8'h00) && s_axi_wdata[0];
    wire abort_req         = write_req && (awaddr_latched[7:0] == 8'h00) && s_axi_wdata[1];
    wire w1c_done_req      = write_req && (awaddr_latched[7:0] == 8'h14) && s_axi_wdata[1];
    wire w1c_ovf_req       = write_req && (awaddr_latched[7:0] == 8'h14) && s_axi_wdata[2];
    wire w1c_underrun_req  = write_req && (awaddr_latched[7:0] == 8'h14) && s_axi_wdata[3];
    wire w1c_timeout_req   = write_req && (awaddr_latched[7:0] == 8'h14) && s_axi_wdata[4];
    wire w1c_err_req       = write_req && (awaddr_latched[7:0] == 8'h14) && s_axi_wdata[5];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state               <= STATE_IDLE;
            dma_busy            <= 1'b0;
            dma_done            <= 1'b0;
            dma_ovf             <= 1'b0;
            dma_underrun        <= 1'b0;
            dma_timeout_flag    <= 1'b0;
            dma_err             <= 1'b0;
            samples_transferred <= 16'd0;
            timeout_counter     <= 32'd0;

            adc_spi_sck         <= 1'b0;
            adc_spi_mosi        <= 1'b0;
            adc_spi_cs_n        <= 1'b1;
            spi_bit_cnt         <= 5'd0;
            spi_rx_shift        <= 16'd0;
            spi_clk_div         <= 4'd0;

            fir_sample_in       <= 16'sd0;
            fir_sample_valid_in <= 1'b0;
            sbuf_waddr          <= {BUF_ADDR_WIDTH{1'b0}};
            sbuf_wdata          <= 16'd0;
            sbuf_we             <= 1'b0;
        end else begin
            sbuf_we             <= 1'b0;
            fir_sample_valid_in <= 1'b0;

            // Handle W1C status clears from AXI
            if (w1c_done_req)     dma_done         <= 1'b0;
            if (w1c_ovf_req)      dma_ovf          <= 1'b0;
            if (w1c_underrun_req) dma_underrun     <= 1'b0;
            if (w1c_timeout_req)  dma_timeout_flag <= 1'b0;
            if (w1c_err_req)      dma_err          <= 1'b0;

            // Handle Start/Abort commands
            if (abort_req) begin
                dma_busy     <= 1'b0;
                adc_spi_cs_n <= 1'b1;
                adc_spi_sck  <= 1'b0;
                state        <= STATE_IDLE;
            end else if (start_req) begin
                dma_busy            <= 1'b1;
                dma_done            <= 1'b0;
                samples_transferred <= 16'd0;
                sbuf_waddr          <= dma_dst_addr[BUF_ADDR_WIDTH-1:0];
                timeout_counter     <= 32'd0;
                state               <= STATE_WAIT_TICK;
            end else begin
                case (state)
                    STATE_IDLE: begin
                        timeout_counter <= 32'd0;
                        adc_spi_cs_n    <= 1'b1;
                        adc_spi_sck     <= 1'b0;
                    end

                    STATE_WAIT_TICK: begin
                        timeout_counter <= timeout_counter + 1'b1;
                        if (timeout_counter > dma_timeout && dma_timeout != 32'd0) begin
                            dma_timeout_flag <= 1'b1;
                            dma_busy         <= 1'b0;
                            state            <= STATE_IDLE;
                        end else if (sample_tick) begin
                            timeout_counter <= 32'd0;
                            adc_spi_cs_n    <= 1'b0;
                            spi_bit_cnt     <= 5'd16;
                            spi_clk_div     <= 4'd0;
                            state           <= STATE_SPI_XFER;
                        end
                    end

                    STATE_SPI_XFER: begin
                        // Fast SPI transfer: divide clk by 4
                        if (spi_clk_div == 4'd3) begin
                            spi_clk_div <= 4'd0;
                        end else begin
                            spi_clk_div <= spi_clk_div + 1'b1;
                        end

                        if (spi_clk_div == 4'd1) begin
                            adc_spi_sck <= 1'b1;
                            spi_rx_shift <= {spi_rx_shift[14:0], adc_spi_miso};
                        end else if (spi_clk_div == 4'd3) begin
                            adc_spi_sck <= 1'b0;
                            spi_bit_cnt <= spi_bit_cnt - 1'b1;
                            if (spi_bit_cnt == 5'd1) begin
                                adc_spi_cs_n <= 1'b1;
                                state        <= STATE_TO_FIR;
                            end
                        end
                    end

                    STATE_TO_FIR: begin
                        fir_sample_in       <= spi_rx_shift;
                        fir_sample_valid_in <= 1'b1;
                        state               <= STATE_FROM_FIR;
                    end

                    STATE_FROM_FIR: begin
                        if (fir_sample_valid_out) begin
                            sbuf_wdata <= fir_sample_out;
                            sbuf_we    <= 1'b1;
                            state      <= STATE_WRITE_BUF;
                        end
                    end

                    STATE_WRITE_BUF: begin
                        sbuf_waddr          <= sbuf_waddr + 1'b1;
                        samples_transferred <= samples_transferred + 1'b1;
                        if (samples_transferred + 1'b1 >= dma_len) begin
                            dma_done <= 1'b1;
                            dma_busy <= 1'b0;
                            state    <= STATE_COMPLETE;
                        end else begin
                            state    <= STATE_WAIT_TICK;
                        end
                    end

                    STATE_COMPLETE: begin
                        state <= STATE_IDLE;
                    end

                    default: state <= STATE_IDLE;
                endcase
            end
        end
    end

    // -------------------------------------------------------------------------
    // AXI4-Lite Write Handshake & Configuration Registers
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_awready  <= 1'b0;
            s_axi_wready   <= 1'b0;
            s_axi_bvalid   <= 1'b0;
            s_axi_bresp    <= 2'b00;
            aw_done        <= 1'b0;
            w_done         <= 1'b0;
            awaddr_latched <= {ADDR_WIDTH{1'b0}};

            dma_src_addr   <= 32'd0;
            dma_dst_addr   <= 32'd0;
            dma_len        <= 16'd0;
            dma_timeout    <= 32'h0000_FFFF;
        end else begin
            if (s_axi_awvalid && !aw_done) begin
                s_axi_awready  <= 1'b1;
                awaddr_latched <= s_axi_awaddr;
                aw_done        <= 1'b1;
            end else begin
                s_axi_awready  <= 1'b0;
            end

            if (s_axi_wvalid && !w_done) begin
                s_axi_wready <= 1'b1;
                w_done       <= 1'b1;
            end else begin
                s_axi_wready <= 1'b0;
            end

            if (aw_done && w_done && !s_axi_bvalid) begin
                case (awaddr_latched[7:0])
                    8'h04: dma_src_addr <= s_axi_wdata;
                    8'h08: dma_dst_addr <= s_axi_wdata;
                    8'h0C: dma_len      <= s_axi_wdata[15:0];
                    8'h10: dma_timeout  <= s_axi_wdata;
                    default: ;
                endcase
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00;
            end

            if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
                aw_done      <= 1'b0;
                w_done       <= 1'b0;
            end
        end
    end

    // -------------------------------------------------------------------------
    // AXI4-Lite Read Channel
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rdata   <= {DATA_WIDTH{1'b0}};
            s_axi_rresp   <= 2'b00;
        end else begin
            if (s_axi_arvalid && !s_axi_rvalid) begin
                s_axi_arready <= 1'b1;
                s_axi_rvalid  <= 1'b1;
                s_axi_rresp   <= 2'b00;
                case (s_axi_araddr[7:0])
                    8'h00: s_axi_rdata <= {31'd0, dma_busy};
                    8'h04: s_axi_rdata <= dma_src_addr;
                    8'h08: s_axi_rdata <= dma_dst_addr;
                    8'h0C: s_axi_rdata <= {16'd0, dma_len};
                    8'h10: s_axi_rdata <= dma_timeout;
                    8'h14: s_axi_rdata <= {26'd0, dma_err, dma_timeout_flag, dma_underrun, dma_ovf, dma_done, dma_busy};
                    default: s_axi_rdata <= 32'd0;
                endcase
            end else begin
                s_axi_arready <= 1'b0;
            end

            if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

endmodule
