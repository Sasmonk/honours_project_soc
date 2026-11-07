// =============================================================================
// Interface    : sbuf_dma_if.sv
// Description  : Interface for DMA Hardware Write Port and Bank Control
// =============================================================================
`ifndef SBUF_DMA_IF_SV
`define SBUF_DMA_IF_SV

interface sbuf_dma_if (
  input logic clk_sys,
  input logic rst_sys_n
);
  logic [11:0] sbuf_waddr;
  logic [15:0] sbuf_wdata;
  logic        sbuf_we;
  logic        buf_swap_req;
  logic        vga_vsync_pulse;
  logic        active_wr_buf;
  logic        active_rd_buf;

  modport driver (
    input  clk_sys,
    input  rst_sys_n,
    output sbuf_waddr,
    output sbuf_wdata,
    output sbuf_we,
    output buf_swap_req,
    output vga_vsync_pulse
  );

  modport monitor (
    input clk_sys,
    input rst_sys_n,
    input sbuf_waddr,
    input sbuf_wdata,
    input sbuf_we,
    input buf_swap_req,
    input vga_vsync_pulse,
    input active_wr_buf,
    input active_rd_buf
  );

endinterface : sbuf_dma_if

`endif // SBUF_DMA_IF_SV
