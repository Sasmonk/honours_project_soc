// =============================================================================
// Interface    : dma_stream_if.sv
// Description  : Hardware interface connecting DMA Streaming and Master ports
// =============================================================================
`ifndef DMA_STREAM_IF_SV
`define DMA_STREAM_IF_SV

interface dma_stream_if (
  input wire clk,
  input wire rst_n
);

  // Timer Strobe & SPI Inputs
  logic        sample_tick;
  logic        spi_sample_ready;
  logic [15:0] spi_sample_data;

  // Legacy SPI Pins
  logic        adc_spi_sck;
  logic        adc_spi_mosi;
  logic        adc_spi_miso;
  logic        adc_spi_cs_n;

  // FIR Filter Interface
  logic signed [15:0] fir_sample_in;
  logic               fir_sample_valid_in;
  logic signed [15:0] fir_sample_out;
  logic               fir_sample_valid_out;

  // Sample Buffer Interface
  logic [11:0] sbuf_waddr;
  logic [15:0] sbuf_wdata;
  logic        sbuf_we;
  logic        buf_swap_req;

  // AXI4 Master Interface (DUT outputs, responder inputs/outputs)
  logic [7:0]  m_axi_awid;
  logic [31:0] m_axi_awaddr;
  logic [7:0]  m_axi_awlen;
  logic [2:0]  m_axi_awsize;
  logic [1:0]  m_axi_awburst;
  logic        m_axi_awlock;
  logic [3:0]  m_axi_awcache;
  logic [2:0]  m_axi_awprot;
  logic [3:0]  m_axi_awqos;
  logic        m_axi_awvalid;
  logic        m_axi_awready;

  logic [31:0] m_axi_wdata;
  logic [3:0]  m_axi_wstrb;
  logic        m_axi_wlast;
  logic        m_axi_wvalid;
  logic        m_axi_wready;

  logic [7:0]  m_axi_bid;
  logic [1:0]  m_axi_bresp;
  logic        m_axi_bvalid;
  logic        m_axi_bready;

  logic [7:0]  m_axi_arid;
  logic [31:0] m_axi_araddr;
  logic [7:0]  m_axi_arlen;
  logic [2:0]  m_axi_arsize;
  logic [1:0]  m_axi_arburst;
  logic        m_axi_arlock;
  logic [3:0]  m_axi_arcache;
  logic [2:0]  m_axi_arprot;
  logic [3:0]  m_axi_arqos;
  logic        m_axi_arvalid;
  logic        m_axi_arready;

  logic [7:0]  m_axi_rid;
  logic [31:0] m_axi_rdata;
  logic [1:0]  m_axi_rresp;
  logic        m_axi_rlast;
  logic        m_axi_rvalid;
  logic        m_axi_rready;

  // Interrupts
  logic        irq_dma_done;
  logic        irq_dma_err;

endinterface : dma_stream_if

`endif // DMA_STREAM_IF_SV
