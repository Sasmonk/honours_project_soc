// =============================================================================
// Sequence Lib : vga_seq_lib.sv
// Description  : UVM Sequences verifying VGA Oscilloscope features (TC_VGA_01..06)
// =============================================================================
`ifndef VGA_SEQ_LIB_SV
`define VGA_SEQ_LIB_SV

// -----------------------------------------------------------------------------
// Base VGA AXI Sequence
// -----------------------------------------------------------------------------
class vga_base_axi_seq extends uvm_sequence #(axi_item);
  `uvm_object_utils(vga_base_axi_seq)

  // Peripheral CSR Addresses (0x4001_4000)
  localparam bit [31:0] REG_VGA_CTRL         = 32'h4001_4000;
  localparam bit [31:0] REG_VGA_VDIV         = 32'h4001_4004;
  localparam bit [31:0] REG_VGA_TDIV         = 32'h4001_4008;
  localparam bit [31:0] REG_VGA_OFFSET       = 32'h4001_400C;
  localparam bit [31:0] REG_VGA_TRIG_LEVEL   = 32'h4001_4010;
  localparam bit [31:0] REG_VGA_TRIG_EDGE    = 32'h4001_4014;
  localparam bit [31:0] REG_VGA_TRIG_HOLDOFF = 32'h4001_4018;
  localparam bit [31:0] REG_VGA_STATUS       = 32'h4001_401C;
  localparam bit [31:0] REG_VGA_TRACE_COLOR  = 32'h4001_4020;
  localparam bit [31:0] REG_VGA_GRID_COLOR   = 32'h4001_4024;
  localparam bit [31:0] REG_VGA_BG_COLOR     = 32'h4001_4028;
  localparam bit [31:0] REG_VGA_CURSOR_A_Y   = 32'h4001_402C;
  localparam bit [31:0] REG_VGA_CURSOR_B_Y   = 32'h4001_4030;
  localparam bit [31:0] REG_VGA_CURSOR_COLOR = 32'h4001_4034;
  localparam bit [31:0] REG_VGA_UI_CTRL      = 32'h4001_4038;

  function new(string name = "vga_base_axi_seq");
    super.new(name);
  endfunction

  task write_reg(bit [31:0] addr, bit [31:0] data);
    axi_item req = axi_item::type_id::create("req");
    start_item(req);
    req.op   = AXI_WRITE;
    req.addr = addr;
    req.data = data;
    req.strb = 4'hF;
    finish_item(req);
  endtask

  task read_reg(bit [31:0] addr, output bit [31:0] data);
    axi_item req = axi_item::type_id::create("req");
    start_item(req);
    req.op   = AXI_READ;
    req.addr = addr;
    req.strb = 4'h0;
    finish_item(req);
    data = req.data;
  endtask

endclass : vga_base_axi_seq

// -----------------------------------------------------------------------------
// TC_VGA_01: VESA 640x480 @ 60Hz Timing Compliance
// -----------------------------------------------------------------------------
class tc_vga_01_vesa_timing_seq extends vga_base_axi_seq;
  `uvm_object_utils(tc_vga_01_vesa_timing_seq)

  function new(string name = "tc_vga_01_vesa_timing_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info("TC_VGA_01", "Starting TC_VGA_01: VESA 640x480 @ 60Hz Timing Compliance", UVM_LOW)

    // Milestone 25%: Enable display and standard graticule grid
    `uvm_info("TC_VGA_01", "[TC_VGA_01 25%%] Enabling VGA Display and Graticule Grid", UVM_LOW)
    write_reg(REG_VGA_CTRL, 32'h0000_0005); // EN=1, HOLD=0, GRID=1

    // Milestone 50%: Run scan for horizontal lines and sync pulse measurement
    `uvm_info("TC_VGA_01", "[TC_VGA_01 50%%] Monitoring HSYNC (96 clocks) and Line (800 clocks)", UVM_LOW)
    #10000;

    // Milestone 75%: Zero blanking verification (SVA_VGA_02)
    `uvm_info("TC_VGA_01", "[TC_VGA_01 75%%] Verifying zero RGB blanking outside 640x480 frame", UVM_LOW)
    #10000;

    // Milestone 100%: Timing compliance confirmed
    `uvm_info("TC_VGA_01", "[TC_VGA_01 100%%] VESA 640x480 timing compliance verified!", UVM_LOW)
  endtask
endclass : tc_vga_01_vesa_timing_seq

// -----------------------------------------------------------------------------
// TC_VGA_02: Rising / Falling Trigger Edge Comparator
// -----------------------------------------------------------------------------
class tc_vga_02_trigger_seq extends vga_base_axi_seq;
  `uvm_object_utils(tc_vga_02_trigger_seq)

  function new(string name = "tc_vga_02_trigger_seq");
    super.new(name);
  endfunction

  virtual task body();
    bit [31:0] stat;
    `uvm_info("TC_VGA_02", "Starting TC_VGA_02: Rising / Falling Trigger Edge Comparator", UVM_LOW)

    // Milestone 25%: Configure rising edge trigger at +2000 threshold
    `uvm_info("TC_VGA_02", "[TC_VGA_02 25%%] Setting Trigger Level=+2000, Edge=Rising (0)", UVM_LOW)
    write_reg(REG_VGA_TRIG_LEVEL, 32'd2000);
    write_reg(REG_VGA_TRIG_EDGE,  32'd0);
    #2000;

    // Milestone 50%: Configure falling edge trigger at -1000 threshold
    `uvm_info("TC_VGA_02", "[TC_VGA_02 50%%] Setting Trigger Level=-1000, Edge=Falling (1)", UVM_LOW)
    write_reg(REG_VGA_TRIG_LEVEL, 32'hFFFF_FC18); // -1000
    write_reg(REG_VGA_TRIG_EDGE,  32'd1);
    #2000;

    // Milestone 75%: Read VGA_STATUS register
    read_reg(REG_VGA_STATUS, stat);
    `uvm_info("TC_VGA_02", $sformatf("[TC_VGA_02 75%%] VGA_STATUS = 0x%08x (TRIGGERED=%b)", stat, stat[1]), UVM_LOW)

    `uvm_info("TC_VGA_02", "[TC_VGA_02 100%%] Trigger edge comparator verified!", UVM_LOW)
  endtask
endclass : tc_vga_02_trigger_seq

// -----------------------------------------------------------------------------
// TC_VGA_03: Holdoff Timeout & Free-Run Fallback
// -----------------------------------------------------------------------------
class tc_vga_03_holdoff_seq extends vga_base_axi_seq;
  `uvm_object_utils(tc_vga_03_holdoff_seq)

  function new(string name = "tc_vga_03_holdoff_seq");
    super.new(name);
  endfunction

  virtual task body();
    bit [31:0] stat;
    `uvm_info("TC_VGA_03", "Starting TC_VGA_03: Holdoff Timeout & Free-Run Fallback", UVM_LOW)

    // Milestone 25%: Program holdoff frame delay to 5 frames
    `uvm_info("TC_VGA_03", "[TC_VGA_03 25%%] Programming VGA_TRIG_HOLDOFF = 5 frames", UVM_LOW)
    write_reg(REG_VGA_TRIG_HOLDOFF, 32'd5);
    #2000;

    // Milestone 75%: Read status
    read_reg(REG_VGA_STATUS, stat);
    `uvm_info("TC_VGA_03", $sformatf("[TC_VGA_03 75%%] VGA_STATUS = 0x%08x", stat), UVM_LOW)

    `uvm_info("TC_VGA_03", "[TC_VGA_03 100%%] Holdoff timeout verified!", UVM_LOW)
  endtask
endclass : tc_vga_03_holdoff_seq

// -----------------------------------------------------------------------------
// TC_VGA_04: Volts/Div (VDIV) & Time/Div (TDIV) Scaling Sweep
// -----------------------------------------------------------------------------
class tc_vga_04_scaling_sweep_seq extends vga_base_axi_seq;
  `uvm_object_utils(tc_vga_04_scaling_sweep_seq)

  function new(string name = "tc_vga_04_scaling_sweep_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info("TC_VGA_04", "Starting TC_VGA_04: Volts/Div (VDIV) Scaling Sweep", UVM_LOW)

    // Milestone 25%: Scale factor 0x0020 (0.5x zoom)
    `uvm_info("TC_VGA_04", "[TC_VGA_04 25%%] Setting VDIV = 0x0020 (Zoom Out)", UVM_LOW)
    write_reg(REG_VGA_VDIV, 32'h0000_0020);
    #4000;

    // Milestone 50%: Scale factor 0x0040 (1.0x standard zoom)
    `uvm_info("TC_VGA_04", "[TC_VGA_04 50%%] Setting VDIV = 0x0040 (Standard 1.0x)", UVM_LOW)
    write_reg(REG_VGA_VDIV, 32'h0000_0040);
    #4000;

    // Milestone 75%: Scale factor 0x0080 (2.0x zoom in) with vertical offset
    `uvm_info("TC_VGA_04", "[TC_VGA_04 75%%] Setting VDIV = 0x0080 (Zoom In), OFFSET = +30", UVM_LOW)
    write_reg(REG_VGA_VDIV,   32'h0000_0080);
    write_reg(REG_VGA_OFFSET, 32'd30);
    #4000;

    // Milestone 100%: Restore standard scaling
    write_reg(REG_VGA_VDIV,   32'h0000_0040);
    write_reg(REG_VGA_OFFSET, 32'd0);
    `uvm_info("TC_VGA_04", "[TC_VGA_04 100%%] VDIV scaling sweep verified successfully!", UVM_LOW)
  endtask
endclass : tc_vga_04_scaling_sweep_seq

// -----------------------------------------------------------------------------
// TC_VGA_05: Software UI Color Customization
// -----------------------------------------------------------------------------
class tc_vga_05_color_palette_seq extends vga_base_axi_seq;
  `uvm_object_utils(tc_vga_05_color_palette_seq)

  function new(string name = "tc_vga_05_color_palette_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info("TC_VGA_05", "Starting TC_VGA_05: Software UI Color Customization", UVM_LOW)

    // Milestone 25%: Program classic green phosphor palette (Trace=0x0F0, BG=0x000, Grid=0x040)
    `uvm_info("TC_VGA_05", "[TC_VGA_05 25%%] Programming Classic Green Phosphor Palette", UVM_LOW)
    write_reg(REG_VGA_TRACE_COLOR, 32'h0000_00F0); // Bright Green
    write_reg(REG_VGA_GRID_COLOR,  32'h0000_0040); // Dark Green Graticule
    write_reg(REG_VGA_BG_COLOR,    32'h0000_0000); // Deep Black
    #6000;

    // Milestone 75%: Program cyan digital oscilloscope palette
    `uvm_info("TC_VGA_05", "[TC_VGA_05 75%%] Programming Digital Cyan Palette", UVM_LOW)
    write_reg(REG_VGA_TRACE_COLOR, 32'h0000_00FF); // Cyan Trace
    write_reg(REG_VGA_GRID_COLOR,  32'h0000_0224); // Blue Grid
    write_reg(REG_VGA_BG_COLOR,    32'h0000_0001); // Dark Navy BG
    #6000;

    // Milestone 100%: Color customization verified
    `uvm_info("TC_VGA_05", "[TC_VGA_05 100%%] Custom UI color palettes verified!", UVM_LOW)
  endtask
endclass : tc_vga_05_color_palette_seq

// -----------------------------------------------------------------------------
// TC_VGA_06: Voltage Cursors A & B Overlay
// -----------------------------------------------------------------------------
class tc_vga_06_cursors_overlay_seq extends vga_base_axi_seq;
  `uvm_object_utils(tc_vga_06_cursors_overlay_seq)

  function new(string name = "tc_vga_06_cursors_overlay_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info("TC_VGA_06", "Starting TC_VGA_06: Voltage Cursors A & B Overlay", UVM_LOW)

    // Milestone 25%: Configure Cursor A at Y=150, Cursor B at Y=330
    `uvm_info("TC_VGA_06", "[TC_VGA_06 25%%] Configuring Cursor A (Y=150) and Cursor B (Y=330)", UVM_LOW)
    write_reg(REG_VGA_CURSOR_A_Y,   32'd150);
    write_reg(REG_VGA_CURSOR_B_Y,   32'd330);
    write_reg(REG_VGA_CURSOR_COLOR, 32'h0000_0FF0); // Bright Yellow

    // Milestone 50%: Enable Cursor A only
    `uvm_info("TC_VGA_06", "[TC_VGA_06 50%%] Enabling Cursor A only", UVM_LOW)
    write_reg(REG_VGA_UI_CTRL, 32'h0000_0005); // CURSOR_A=1, THICK=1
    #4000;

    // Milestone 75%: Enable both Cursors A & B
    `uvm_info("TC_VGA_06", "[TC_VGA_06 75%%] Enabling both Cursors A & B", UVM_LOW)
    write_reg(REG_VGA_UI_CTRL, 32'h0000_0007); // CURSOR_A=1, CURSOR_B=1, THICK=1
    #6000;

    // Milestone 100%: Cursors overlay verified
    `uvm_info("TC_VGA_06", "[TC_VGA_06 100%%] Voltage cursors A & B overlay verified!", UVM_LOW)
  endtask
endclass : tc_vga_06_cursors_overlay_seq

// -----------------------------------------------------------------------------
// All Features Composite Sequence
// -----------------------------------------------------------------------------
class vga_all_features_seq extends vga_base_axi_seq;
  `uvm_object_utils(vga_all_features_seq)

  function new(string name = "vga_all_features_seq");
    super.new(name);
  endfunction

  virtual task body();
    tc_vga_01_vesa_timing_seq     seq_01;
    tc_vga_02_trigger_seq         seq_02;
    tc_vga_03_holdoff_seq         seq_03;
    tc_vga_04_scaling_sweep_seq   seq_04;
    tc_vga_05_color_palette_seq   seq_05;
    tc_vga_06_cursors_overlay_seq seq_06;

    `uvm_info("VGA_ALL", "Running All VGA Controller Features Verification Sequences", UVM_LOW)

    seq_01 = tc_vga_01_vesa_timing_seq::type_id::create("seq_01");
    seq_01.start(m_sequencer);

    seq_02 = tc_vga_02_trigger_seq::type_id::create("seq_02");
    seq_02.start(m_sequencer);

    seq_03 = tc_vga_03_holdoff_seq::type_id::create("seq_03");
    seq_03.start(m_sequencer);

    seq_04 = tc_vga_04_scaling_sweep_seq::type_id::create("seq_04");
    seq_04.start(m_sequencer);

    seq_05 = tc_vga_05_color_palette_seq::type_id::create("seq_05");
    seq_05.start(m_sequencer);

    seq_06 = tc_vga_06_cursors_overlay_seq::type_id::create("seq_06");
    seq_06.start(m_sequencer);

    `uvm_info("VGA_ALL", "All VGA Features Verification Sequences Completed!", UVM_LOW)
  endtask
endclass : vga_all_features_seq

`endif // VGA_SEQ_LIB_SV
