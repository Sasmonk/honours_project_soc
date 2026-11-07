// =============================================================================
// Monitor      : vga_pixel_monitor.sv
// Description  : Hardware Timing Compliance and Pixel Color Monitor
// =============================================================================
`ifndef VGA_PIXEL_MONITOR_SV
`define VGA_PIXEL_MONITOR_SV

class vga_pixel_monitor extends uvm_monitor;
  `uvm_component_utils(vga_pixel_monitor)

  virtual vga_pixel_if vif;
  uvm_analysis_port #(vga_pixel_item) ap;
  uvm_analysis_port #(int)            frame_ap;

  // Timing Statistics
  int unsigned h_sync_width    = 0;
  int unsigned h_line_width    = 0;
  int unsigned v_sync_lines    = 0;
  int unsigned v_frame_lines   = 0;
  int unsigned total_frames    = 0;
  int unsigned blank_violations= 0;

  function new(string name = "vga_pixel_monitor", uvm_component parent = null);
    super.new(name, parent);
    ap       = new("ap", this);
    frame_ap = new("frame_ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual vga_pixel_if)::get(this, "", "vga_vif", vif)) begin
      `uvm_fatal("NOVIF", "virtual vga_pixel_if not found in config_db")
    end
  endfunction

  task run_phase(uvm_phase phase);
    int unsigned h_cnt = 0;
    int unsigned v_cnt = 0;
    bit prev_hsync = 1'b1;
    bit prev_vsync = 1'b1;
    int cur_h_sync = 0;
    bit synced = 1'b0;

    @(posedge vif.rst_vga_n);

    forever begin
      @(posedge vif.clk_vga);

      // Measure HSYNC pulse width
      if (!vif.vga_hsync) begin
        cur_h_sync++;
      end else if (prev_hsync == 1'b0 && vif.vga_hsync == 1'b1) begin
        h_sync_width = cur_h_sync;
        cur_h_sync = 0;
      end

      // Synchronize to physical HSYNC falling edge
      if (prev_hsync == 1'b1 && vif.vga_hsync == 1'b0) begin
        synced = 1'b1;
        h_cnt  = 656; // ACTIVE (640) + FRONT_PORCH (16)
        if (v_cnt == 524) begin
          v_cnt = 0;
          total_frames++;
          frame_ap.write(total_frames);
          `uvm_info("VGA_MON", $sformatf("Frame Complete: #%0d (HSYNC_WIDTH=%0d clocks)",
                    total_frames, h_sync_width), UVM_HIGH)
        end else begin
          v_cnt++;
        end
      end else if (synced) begin
        if (h_cnt == 799) begin
          h_cnt = 0;
        end else begin
          h_cnt++;
        end
      end

      // Synchronize to physical VSYNC falling edge
      if (prev_vsync == 1'b1 && vif.vga_vsync == 1'b0) begin
        v_cnt = 490; // ACTIVE (480) + FRONT_PORCH (10)
      end

      prev_hsync = vif.vga_hsync;
      prev_vsync = vif.vga_vsync;

      if (!synced) continue;

      // Check SVA_VGA_02: Zero blanking violation
      if (h_cnt >= 640 || v_cnt >= 480) begin
        if (vif.vga_red != 4'h0 || vif.vga_green != 4'h0 || vif.vga_blue != 4'h0) begin
          blank_violations++;
          `uvm_error("SVA_VGA_02", $sformatf("Blanking Violation at (%0d, %0d)! Non-zero RGB: #%1x%1x%1x",
                     h_cnt, v_cnt, vif.vga_red, vif.vga_green, vif.vga_blue))
        end
      end

      // Sample active video pixel transactions periodically
      if ((h_cnt < 640) && (v_cnt < 480) && (h_cnt % 32 == 0)) begin
        vga_pixel_item item = vga_pixel_item::type_id::create("item");
        item.h_count      = h_cnt;
        item.v_count      = v_cnt;
        item.hsync        = vif.vga_hsync;
        item.vsync        = vif.vga_vsync;
        item.red          = vif.vga_red;
        item.green        = vif.vga_green;
        item.blue         = vif.vga_blue;
        item.active_video = 1'b1;
        item.sample_in    = vif.sbuf_rdata;
        item.timestamp    = $realtime;
        ap.write(item);
      end
    end
  endtask

endclass : vga_pixel_monitor

`endif // VGA_PIXEL_MONITOR_SV
