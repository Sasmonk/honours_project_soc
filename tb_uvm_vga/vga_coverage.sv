// =============================================================================
// Coverage     : vga_coverage.sv
// Description  : Functional Coverage for VGA Oscilloscope Controller Subsystem
// =============================================================================
`ifndef VGA_COVERAGE_SV
`define VGA_COVERAGE_SV

class vga_coverage extends uvm_subscriber #(vga_pixel_item);
  `uvm_component_utils(vga_coverage)

  bit [9:0]  cov_h_count;
  bit [9:0]  cov_v_count;
  bit [3:0]  cov_r, cov_g, cov_b;
  bit [15:0] cov_vdiv;
  bit        cov_grid_en;
  bit        cov_cursor_a_en;
  bit        cov_cursor_b_en;

  uvm_analysis_imp_vga_axi #(axi_item, vga_coverage) axi_cov_export;

  covergroup cg_vga_render;
    option.per_instance = 1;
    option.comment = "VGA Oscilloscope Display Controller Coverage";

    // Screen X pixel bins
    cp_x_pos: coverpoint cov_h_count {
      bins left_margin   = {[0:99]};
      bins center_left   = {[100:319]};
      bins center_axis   = {320};
      bins center_right  = {[321:539]};
      bins right_margin  = {[540:639]};
    }

    // Screen Y pixel bins
    cp_y_pos: coverpoint cov_v_count {
      bins top_margin    = {[0:99]};
      bins upper_quad    = {[100:239]};
      bins center_axis   = {240};
      bins lower_quad    = {[241:379]};
      bins bottom_margin = {[380:479]};
    }

    // Grid enable
    cp_grid: coverpoint cov_grid_en {
      bins grid_off = {1'b0};
      bins grid_on  = {1'b1};
    }

    // Cursors
    cp_cursor_a: coverpoint cov_cursor_a_en {
      bins off = {1'b0};
      bins on  = {1'b1};
    }

    cp_cursor_b: coverpoint cov_cursor_b_en {
      bins off = {1'b0};
      bins on  = {1'b1};
    }

    // Scaling factor
    cp_vdiv: coverpoint cov_vdiv {
      bins scale_low     = {[16'h0001:16'h0020]};
      bins scale_default = {16'h0040};
      bins scale_high    = {[16'h0041:16'h0100]};
    }

  endgroup : cg_vga_render

  function new(string name = "vga_coverage", uvm_component parent = null);
    super.new(name, parent);
    cg_vga_render  = new();
    axi_cov_export = new("axi_cov_export", this);
    cov_vdiv       = 16'h0040;
    cov_grid_en    = 1'b1;
  endfunction

  virtual function void write(vga_pixel_item t);
    cov_h_count = t.h_count;
    cov_v_count = t.v_count;
    cov_r       = t.red;
    cov_g       = t.green;
    cov_b       = t.blue;
    cg_vga_render.sample();
  endfunction

  virtual function void write_vga_axi(axi_item item);
    if (item.op == AXI_WRITE) begin
      if (item.addr[7:0] == 8'h00) cov_grid_en     = item.data[2];
      if (item.addr[7:0] == 8'h04) cov_vdiv        = item.data[15:0];
      if (item.addr[7:0] == 8'h38) begin
        cov_cursor_a_en = item.data[0];
        cov_cursor_b_en = item.data[1];
      end
    end
  endfunction

endclass : vga_coverage

`endif // VGA_COVERAGE_SV
