// =============================================================================
// Sequence Items : vga_items.sv
// Description    : Transaction items for VGA Pixel Stream
// =============================================================================
`ifndef VGA_ITEMS_SV
`define VGA_ITEMS_SV

class vga_pixel_item extends uvm_sequence_item;
  `uvm_object_utils(vga_pixel_item)

  bit [9:0]        h_count;
  bit [9:0]        v_count;
  bit              hsync;
  bit              vsync;
  bit [3:0]        red;
  bit [3:0]        green;
  bit [3:0]        blue;
  bit              active_video;
  bit signed [15:0]sample_in;
  realtime         timestamp;

  function new(string name = "vga_pixel_item");
    super.new(name);
  endfunction

  function void do_copy(uvm_object rhs);
    vga_pixel_item rhs_;
    if (!$cast(rhs_, rhs)) return;
    super.do_copy(rhs);
    this.h_count      = rhs_.h_count;
    this.v_count      = rhs_.v_count;
    this.hsync        = rhs_.hsync;
    this.vsync        = rhs_.vsync;
    this.red          = rhs_.red;
    this.green        = rhs_.green;
    this.blue         = rhs_.blue;
    this.active_video = rhs_.active_video;
    this.sample_in    = rhs_.sample_in;
    this.timestamp    = rhs_.timestamp;
  endfunction

  function string convert2string();
    return $sformatf("VGA Pixel: (%0d, %0d) RGB444=#%1x%1x%1x HSYNC=%b VSYNC=%b",
                     h_count, v_count, red, green, blue, hsync, vsync);
  endfunction
endclass : vga_pixel_item

`endif // VGA_ITEMS_SV
