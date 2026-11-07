// =============================================================================
// Interface    : vga_pixel_if.sv
// Description  : Interface for VGA Physical Display Signals and Sample Buffer
// =============================================================================
`ifndef VGA_PIXEL_IF_SV
`define VGA_PIXEL_IF_SV

interface vga_pixel_if (
  input logic clk_vga,
  input logic rst_vga_n
);
  logic        vga_hsync;
  logic        vga_vsync;
  logic [3:0]  vga_red;
  logic [3:0]  vga_green;
  logic [3:0]  vga_blue;
  logic        vga_vsync_pulse;
  logic        irq_vga_frame;

  logic [11:0] sbuf_raddr;
  logic [15:0] sbuf_rdata;

  modport sbuf_driver (
    input  clk_vga,
    input  rst_vga_n,
    input  sbuf_raddr,
    output sbuf_rdata
  );

  modport monitor (
    input clk_vga,
    input rst_vga_n,
    input vga_hsync,
    input vga_vsync,
    input vga_red,
    input vga_green,
    input vga_blue,
    input vga_vsync_pulse,
    input irq_vga_frame,
    input sbuf_raddr,
    input sbuf_rdata
  );

endinterface : vga_pixel_if

`endif // VGA_PIXEL_IF_SV
