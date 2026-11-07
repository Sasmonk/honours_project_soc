// =============================================================================
// Interface    : sbuf_vga_if.sv
// Description  : Interface for VGA Controller Display Read Port (clk_vga domain)
// =============================================================================
`ifndef SBUF_VGA_IF_SV
`define SBUF_VGA_IF_SV

interface sbuf_vga_if (
  input logic clk_vga,
  input logic rst_vga_n
);
  logic [11:0] sbuf_raddr;
  logic [15:0] sbuf_rdata;
  logic        sbuf_ren;
  logic        rd_buf_sel_vga;

  modport driver (
    input  clk_vga,
    input  rst_vga_n,
    output sbuf_raddr,
    output sbuf_ren
  );

  modport monitor (
    input clk_vga,
    input rst_vga_n,
    input sbuf_raddr,
    input sbuf_rdata,
    input sbuf_ren,
    input rd_buf_sel_vga
  );

endinterface : sbuf_vga_if

`endif // SBUF_VGA_IF_SV
