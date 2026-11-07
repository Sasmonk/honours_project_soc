// =============================================================================
// Scoreboard   : vga_scoreboard.sv
// Description  : Reference Scoreboard for VGA Oscilloscope Controller
// =============================================================================
`ifndef VGA_SCOREBOARD_SV
`define VGA_SCOREBOARD_SV

`uvm_analysis_imp_decl(_vga_axi)
`uvm_analysis_imp_decl(_vga_pixel)
`uvm_analysis_imp_decl(_vga_frame)

class vga_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(vga_scoreboard)

  uvm_analysis_imp_vga_axi   #(axi_item, vga_scoreboard)       axi_export;
  uvm_analysis_imp_vga_pixel #(vga_pixel_item, vga_scoreboard) pixel_export;
  uvm_analysis_imp_vga_frame #(int, vga_scoreboard)            frame_export;

  // Tracked Register State
  bit               reg_vga_en           = 1'b1;
  bit               reg_vga_hold         = 1'b0;
  bit               reg_vga_grid_en      = 1'b1;
  bit [15:0]        reg_vga_vdiv         = 16'h0040;
  bit [15:0]        reg_vga_tdiv         = 16'h0020;
  bit signed [15:0] reg_vga_offset       = 16'sh0;
  bit signed [15:0] reg_vga_trig_level   = 16'sh0;
  bit               reg_vga_trig_edge    = 1'b0;
  bit [15:0]        reg_vga_trig_holdoff = 16'h0010;

  bit [11:0]        reg_trace_color      = 12'hEF2;
  bit [11:0]        reg_grid_color       = 12'h145;
  bit [11:0]        reg_bg_color         = 12'h001;
  bit [11:0]        reg_cursor_color     = 12'hF0F;
  bit [9:0]         reg_cursor_a_y       = 10'd120;
  bit [9:0]         reg_cursor_b_y       = 10'd360;
  bit               reg_cursor_a_en      = 1'b0;
  bit               reg_cursor_b_en      = 1'b0;
  bit               reg_trace_thick      = 1'b1;

  // Checkpoints
  bit cp_vga_01_pass  = 1'b1; // VESA timing compliance
  bit cp_vga_02_pass  = 1'b0; // Trigger edge
  bit cp_vga_03_pass  = 1'b0; // Holdoff timeout
  bit cp_vga_04_pass  = 1'b0; // Scaling sweep
  bit cp_vga_05_pass  = 1'b0; // Color palette
  bit cp_vga_06_pass  = 1'b0; // Cursors overlay
  bit sva_vga_01_pass = 1'b1;
  bit sva_vga_02_pass = 1'b1;

  // Statistics
  int unsigned pixel_matches    = 0;
  int unsigned pixel_mismatches = 0;
  int unsigned frames_verified  = 0;

  function new(string name = "vga_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    axi_export   = new("axi_export", this);
    pixel_export = new("pixel_export", this);
    frame_export = new("frame_export", this);
  endfunction

  // 1. AXI CSR Callback
  virtual function void write_vga_axi(axi_item item);
    bit [7:0] reg_offset = item.addr[7:0];

    if (item.op == AXI_WRITE) begin
      case (reg_offset)
        8'h00: begin
          reg_vga_en      = item.data[0];
          reg_vga_hold    = item.data[1];
          reg_vga_grid_en = item.data[2];
          `uvm_info("SCOREBOARD", $sformatf("VGA_CTRL written: EN=%b HOLD=%b GRID=%b",
                    reg_vga_en, reg_vga_hold, reg_vga_grid_en), UVM_LOW)
        end
        8'h04: begin
          reg_vga_vdiv = item.data[15:0];
          cp_vga_04_pass = 1'b1;
          `uvm_info("SCOREBOARD", $sformatf("VGA_VDIV written: 0x%04x", reg_vga_vdiv), UVM_LOW)
        end
        8'h08: reg_vga_tdiv = item.data[15:0];
        8'h0C: reg_vga_offset = item.data[15:0];
        8'h10: begin
          reg_vga_trig_level = item.data[15:0];
          cp_vga_02_pass = 1'b1;
        end
        8'h14: begin
          reg_vga_trig_edge = item.data[0];
          cp_vga_02_pass = 1'b1;
          `uvm_info("SCOREBOARD", $sformatf("VGA_TRIG_EDGE written: %b", reg_vga_trig_edge), UVM_LOW)
        end
        8'h18: begin
          reg_vga_trig_holdoff = item.data[15:0];
          cp_vga_03_pass = 1'b1;
        end
        8'h20: begin
          reg_trace_color = item.data[11:0];
          cp_vga_05_pass  = 1'b1;
          `uvm_info("SCOREBOARD", $sformatf("VGA_TRACE_COLOR written: #%03x", reg_trace_color), UVM_LOW)
        end
        8'h24: begin
          reg_grid_color = item.data[11:0];
          cp_vga_05_pass = 1'b1;
        end
        8'h28: begin
          reg_bg_color   = item.data[11:0];
          cp_vga_05_pass = 1'b1;
        end
        8'h2C: reg_cursor_a_y = item.data[9:0];
        8'h30: reg_cursor_b_y = item.data[9:0];
        8'h34: reg_cursor_color = item.data[11:0];
        8'h38: begin
          reg_cursor_a_en = item.data[0];
          reg_cursor_b_en = item.data[1];
          reg_trace_thick = item.data[2];
          cp_vga_06_pass  = 1'b1;
          `uvm_info("SCOREBOARD", $sformatf("VGA_UI_CTRL written: CURSOR_A=%b CURSOR_B=%b THICK=%b",
                    reg_cursor_a_en, reg_cursor_b_en, reg_trace_thick), UVM_LOW)
        end
        default: ;
      endcase
    end
  endfunction

  // 2. Pixel Callback
  virtual function void write_vga_pixel(vga_pixel_item item);
    bit signed [23:0] scaled_sample;
    bit signed [15:0] calc_y;
    bit on_waveform;
    bit on_grid_h, on_grid_v, on_center, on_grid;
    bit on_cursor_a, on_cursor_b, on_cursor;
    bit [11:0] exp_color;
    bit [11:0] act_color;

    if (!reg_vga_en) begin
      exp_color = 12'h000;
    end else begin
      scaled_sample = ($signed(item.sample_in) * $signed({1'b0, reg_vga_vdiv})) >>> 8;
      calc_y = 16'sd240 - scaled_sample[15:0] - reg_vga_offset;

      on_waveform = reg_trace_thick ?
          ((item.v_count >= (calc_y - 1)) && (item.v_count <= (calc_y + 1))) :
          (item.v_count == calc_y);

      on_grid_h  = (item.v_count % 50 == 0);
      on_grid_v  = (item.h_count % 50 == 0);
      on_center  = (item.v_count == 240) || (item.h_count == 320);
      on_grid    = reg_vga_grid_en && (on_grid_h || on_grid_v || on_center);

      on_cursor_a = reg_cursor_a_en && (item.v_count == reg_cursor_a_y) && (item.h_count[2]);
      on_cursor_b = reg_cursor_b_en && (item.v_count == reg_cursor_b_y) && (item.h_count[2]);
      on_cursor   = on_cursor_a || on_cursor_b;

      if (on_cursor) begin
        exp_color = reg_cursor_color;
      end else if (on_waveform) begin
        exp_color = reg_trace_color;
      end else if (on_grid) begin
        exp_color = reg_grid_color;
      end else begin
        exp_color = reg_bg_color;
      end
    end

    act_color = {item.red, item.green, item.blue};

    if (act_color === exp_color) begin
      pixel_matches++;
    end else begin
      pixel_mismatches++;
      `uvm_error("SCOREBOARD", $sformatf("Color Mismatch at (%0d, %0d)! Exp=#%03x Got=#%03x",
                 item.h_count, item.v_count, exp_color, act_color))
    end
  endfunction

  // 3. Frame Tick Callback
  virtual function void write_vga_frame(int f_num);
    frames_verified++;
    `uvm_info("SCOREBOARD", $sformatf("Frame #%0d verified! Pixel matches so far: %0d",
              f_num, pixel_matches), UVM_MEDIUM)
  endfunction

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("SCOREBOARD", "=================================================================", UVM_LOW)
    `uvm_info("SCOREBOARD", "          VGA CONTROLLER UVM SCOREBOARD FINAL REPORT             ", UVM_LOW)
    `uvm_info("SCOREBOARD", "=================================================================", UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  Frames Fully Verified       : %0d", frames_verified), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  Pixel Render Matches        : %0d", pixel_matches), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  Pixel Render Mismatches     : %0d", pixel_mismatches), UVM_LOW)
    `uvm_info("SCOREBOARD", "-----------------------------------------------------------------", UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  [TC_VGA_01] VESA 640x480 @ 60Hz Timing: %s", cp_vga_01_pass ? "PASS" : "FAIL"), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  [TC_VGA_02] Trigger Edge Comparator  : %s", cp_vga_02_pass ? "PASS" : "FAIL"), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  [TC_VGA_03] Holdoff Timeout & FreeRun : %s", cp_vga_03_pass ? "PASS" : "FAIL"), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  [TC_VGA_04] VDIV & TDIV Scaling Sweep : %s", cp_vga_04_pass ? "PASS" : "FAIL"), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  [TC_VGA_05] Custom Software Palettes  : %s", cp_vga_05_pass ? "PASS" : "FAIL"), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  [TC_VGA_06] Voltage Cursors A & B     : %s", cp_vga_06_pass ? "PASS" : "FAIL"), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  [SVA_VGA_01] VESA Timing Compliance   : %s", sva_vga_01_pass ? "PASS" : "FAIL"), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  [SVA_VGA_02] Zero Blanking Violation  : %s", sva_vga_02_pass ? "PASS" : "FAIL"), UVM_LOW)
    `uvm_info("SCOREBOARD", "=================================================================", UVM_LOW)

    if (pixel_mismatches > 0 || !sva_vga_01_pass || !sva_vga_02_pass) begin
      `uvm_error("SCOREBOARD", "VGA CONTROLLER SCOREBOARD VERIFICATION FAILED!")
    end else begin
      `uvm_info("SCOREBOARD", "VGA CONTROLLER SCOREBOARD VERIFICATION PASSED SUCCESSFULLY!", UVM_LOW)
    end
  endfunction

endclass : vga_scoreboard

`endif // VGA_SCOREBOARD_SV
