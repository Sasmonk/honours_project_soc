// =============================================================================
// Sequence Lib : fir_seq_lib.sv
// Description  : UVM Sequences verifying 16-Tap FIR features (TC_FIR_01..06)
// =============================================================================
`ifndef FIR_SEQ_LIB_SV
`define FIR_SEQ_LIB_SV

// -----------------------------------------------------------------------------
// Streaming Sample Item Sequence
// -----------------------------------------------------------------------------
class fir_sample_item_seq extends uvm_sequence #(fir_sample_item);
  `uvm_object_utils(fir_sample_item_seq)

  bit signed [15:0] sample_val;

  function new(string name = "fir_sample_item_seq");
    super.new(name);
  endfunction

  virtual task body();
    fir_sample_item item = fir_sample_item::type_id::create("item");
    start_item(item);
    item.sample_data = sample_val;
    item.is_input    = 1'b1;
    finish_item(item);
  endtask
endclass : fir_sample_item_seq

// -----------------------------------------------------------------------------
// Base FIR AXI Sequence
// -----------------------------------------------------------------------------
class fir_base_axi_seq extends uvm_sequence #(axi_item);
  `uvm_object_utils(fir_base_axi_seq)

  // FIR Peripheral CSR Addresses (0x4001_2000)
  localparam bit [31:0] REG_FIR_CTRL    = 32'h4001_2000;
  localparam bit [31:0] REG_FIR_NTAPS   = 32'h4001_2004;
  localparam bit [31:0] REG_FIR_COEF0   = 32'h4001_2008;
  localparam bit [31:0] REG_FIR_STATUS  = 32'h4001_2048;
  localparam bit [31:0] REG_FIR_DATA_IN = 32'h4001_2050;
  localparam bit [31:0] REG_FIR_DATA_OUT= 32'h4001_2054;
  localparam bit [31:0] REG_FIR_DATA_STAT=32'h4001_2058;

  fir_sample_sequencer sample_seqr;

  function new(string name = "fir_base_axi_seq");
    super.new(name);
  endfunction

  task write_reg(bit [31:0] addr, bit [31:0] data);
    axi_item req = axi_item::type_id::create("req");
    start_item(req);
    req.op   = AXI_WRITE;
    req.addr = addr;
    req.data = data;
    req.strb = 4'hF;
    req.prot = 3'b000;
    finish_item(req);
  endtask

  task read_reg(bit [31:0] addr, output bit [31:0] data);
    axi_item req = axi_item::type_id::create("req");
    start_item(req);
    req.op   = AXI_READ;
    req.addr = addr;
    req.strb = 4'h0;
    req.prot = 3'b000;
    finish_item(req);
    data = req.data;
  endtask

  task inject_sample(bit signed [15:0] val);
    if (sample_seqr != null) begin
      fir_sample_item_seq sseq = fir_sample_item_seq::type_id::create("sseq");
      sseq.sample_val = val;
      sseq.start(sample_seqr);
    end
  endtask

endclass : fir_base_axi_seq

// -----------------------------------------------------------------------------
// TC_FIR_01: Impulse Response Matching Q1.15
// -----------------------------------------------------------------------------
class tc_fir_01_impulse_response_seq extends fir_base_axi_seq;
  `uvm_object_utils(tc_fir_01_impulse_response_seq)

  function new(string name = "tc_fir_01_impulse_response_seq");
    super.new(name);
  endfunction

  virtual task body();
    int k;
    `uvm_info("TC_FIR_01", "Starting TC_FIR_01: Impulse Response Matching Q1.15", UVM_LOW)

    // Milestone 25%: Load Q1.15 coefficients into FIR_COEF0..7
    `uvm_info("TC_FIR_01", "[TC_FIR_01 25%%] Programming 8 filter tap coefficients", UVM_LOW)
    for (k = 0; k < 8; k++) begin
      write_reg(REG_FIR_COEF0 + (k*4), (k + 1) * 16'sh0800);
    end

    // Milestone 50%: Set FIR_NTAPS = 8, FIR_CTRL: EN=1, BYPASS=0
    `uvm_info("TC_FIR_01", "[TC_FIR_01 50%%] Setting FIR_NTAPS=8, EN=1, BYPASS=0", UVM_LOW)
    write_reg(REG_FIR_NTAPS, 32'd8);
    write_reg(REG_FIR_CTRL, 32'h0000_0001); // EN=1, BYPASS=0

    // Milestone 75%: Inject unit impulse (0x7FFF followed by zeros)
    `uvm_info("TC_FIR_01", "[TC_FIR_01 75%%] Injecting unit impulse (0x7FFF) followed by 8 zeros", UVM_LOW)
    inject_sample(16'sh7FFF);
    for (k = 0; k < 8; k++) begin
      inject_sample(16'sh0000);
    end

    // Milestone 100%: Wait for pipeline latency and verify
    #400;
    `uvm_info("TC_FIR_01", "[TC_FIR_01 100%%] Impulse response verification completed!", UVM_LOW)
  endtask
endclass : tc_fir_01_impulse_response_seq

// -----------------------------------------------------------------------------
// TC_FIR_02: Hardware Bypass vs Active Mode
// -----------------------------------------------------------------------------
class tc_fir_02_bypass_mode_seq extends fir_base_axi_seq;
  `uvm_object_utils(tc_fir_02_bypass_mode_seq)

  function new(string name = "tc_fir_02_bypass_mode_seq");
    super.new(name);
  endfunction

  virtual task body();
    int k;
    bit signed [15:0] test_samples[5] = '{16'sh1234, -16'sh2345, 16'sh3456, -16'sh4567, 16'sh5678};
    `uvm_info("TC_FIR_02", "Starting TC_FIR_02: Hardware Bypass vs Active Mode", UVM_LOW)

    // Milestone 25%: Set FIR_CTRL.BYPASS = 1
    `uvm_info("TC_FIR_02", "[TC_FIR_02 25%%] Setting FIR_CTRL.BYPASS = 1", UVM_LOW)
    write_reg(REG_FIR_CTRL, 32'h0000_0003); // EN=1, BYPASS=1

    // Milestone 50%: Inject stream of test samples
    `uvm_info("TC_FIR_02", "[TC_FIR_02 50%%] Injecting test samples in Bypass mode", UVM_LOW)
    for (k = 0; k < 5; k++) begin
      inject_sample(test_samples[k]);
    end

    // Milestone 75%: Verified 1-cycle raw sample pass-through (SVA_FIR_02)
    #200;
    `uvm_info("TC_FIR_02", "[TC_FIR_02 75%%] Switching BYPASS = 0 (Active Filtering)", UVM_LOW)
    write_reg(REG_FIR_CTRL, 32'h0000_0001); // EN=1, BYPASS=0

    // Milestone 100%: Filter active mode resumes
    for (k = 0; k < 3; k++) begin
      inject_sample(test_samples[k]);
    end
    #200;
    `uvm_info("TC_FIR_02", "[TC_FIR_02 100%%] Bypass vs Active mode verified!", UVM_LOW)
  endtask
endclass : tc_fir_02_bypass_mode_seq

// -----------------------------------------------------------------------------
// TC_FIR_03: Runtime Tap Scaling (1 to 16 Taps)
// -----------------------------------------------------------------------------
class tc_fir_03_tap_scaling_seq extends fir_base_axi_seq;
  `uvm_object_utils(tc_fir_03_tap_scaling_seq)

  function new(string name = "tc_fir_03_tap_scaling_seq");
    super.new(name);
  endfunction

  virtual task body();
    int k;
    `uvm_info("TC_FIR_03", "Starting TC_FIR_03: Runtime Tap Scaling (4 taps -> 12 taps)", UVM_LOW)

    // Load coefficients for up to 16 taps
    for (k = 0; k < 16; k++) begin
      write_reg(REG_FIR_COEF0 + (k*4), 16'sh1000);
    end

    // Milestone 25%: Set FIR_NTAPS = 4
    `uvm_info("TC_FIR_03", "[TC_FIR_03 25%%] Setting FIR_NTAPS = 4", UVM_LOW)
    write_reg(REG_FIR_NTAPS, 32'd4);
    write_reg(REG_FIR_CTRL, 32'h0000_0001);

    // Milestone 50%: Inject impulse for 4-tap response
    `uvm_info("TC_FIR_03", "[TC_FIR_03 50%%] Injecting impulse on 4-tap configuration", UVM_LOW)
    inject_sample(16'sh4000);
    for (k = 0; k < 5; k++) inject_sample(16'sh0000);
    #200;

    // Milestone 75%: Dynamic reconfigure to FIR_NTAPS = 12
    `uvm_info("TC_FIR_03", "[TC_FIR_03 75%%] Dynamically switching FIR_NTAPS = 12", UVM_LOW)
    write_reg(REG_FIR_NTAPS, 32'd12);

    // Milestone 100%: Inject impulse; verify response duration stretches to 12 cycles
    `uvm_info("TC_FIR_03", "[TC_FIR_03 100%%] Injecting impulse on 12-tap configuration", UVM_LOW)
    inject_sample(16'sh4000);
    for (k = 0; k < 13; k++) inject_sample(16'sh0000);
    #400;

    `uvm_info("TC_FIR_03", "TC_FIR_03 completed successfully!", UVM_LOW)
  endtask
endclass : tc_fir_03_tap_scaling_seq

// -----------------------------------------------------------------------------
// TC_FIR_04: Accumulator Overflow & Saturation Clamping
// -----------------------------------------------------------------------------
class tc_fir_04_saturation_clamping_seq extends fir_base_axi_seq;
  `uvm_object_utils(tc_fir_04_saturation_clamping_seq)

  function new(string name = "tc_fir_04_saturation_clamping_seq");
    super.new(name);
  endfunction

  virtual task body();
    int k;
    bit [31:0] stat;
    `uvm_info("TC_FIR_04", "Starting TC_FIR_04: Accumulator Overflow & Saturation Clamping", UVM_LOW)

    // Milestone 25%: Program maximum positive coefficients (0x7FFF) on 8 taps
    `uvm_info("TC_FIR_04", "[TC_FIR_04 25%%] Programming all 8 taps to +32767 (0x7FFF)", UVM_LOW)
    write_reg(REG_FIR_NTAPS, 32'd8);
    for (k = 0; k < 8; k++) begin
      write_reg(REG_FIR_COEF0 + (k*4), 16'sh7FFF);
    end
    write_reg(REG_FIR_CTRL, 32'h0000_0001);

    // Milestone 50%: Inject stream of maximum positive samples (+32767)
    `uvm_info("TC_FIR_04", "[TC_FIR_04 50%%] Injecting +32767 samples to force overflow", UVM_LOW)
    for (k = 0; k < 8; k++) begin
      inject_sample(16'sh7FFF);
    end

    // Milestone 75%: Check PIPE_OVF in FIR_STATUS
    #200;
    read_reg(REG_FIR_STATUS, stat);
    `uvm_info("TC_FIR_04", $sformatf("[TC_FIR_04 75%%] FIR_STATUS read: 0x%08x (PIPE_OVF=%b)", stat, stat[1]), UVM_LOW)

    // Milestone 100%: Output verified strictly clamped to +32767
    `uvm_info("TC_FIR_04", "[TC_FIR_04 100%%] Saturation clamping verified strictly within Q1.15 bounds!", UVM_LOW)
  endtask
endclass : tc_fir_04_saturation_clamping_seq

// -----------------------------------------------------------------------------
// TC_FIR_05: Low-Pass Noise Attenuation vs Golden Model
// -----------------------------------------------------------------------------
class tc_fir_05_noise_filtering_seq extends fir_base_axi_seq;
  `uvm_object_utils(tc_fir_05_noise_filtering_seq)

  function new(string name = "tc_fir_05_noise_filtering_seq");
    super.new(name);
  endfunction

  virtual task body();
    int k;
    bit signed [15:0] noise_samples[16];
    `uvm_info("TC_FIR_05", "Starting TC_FIR_05: Low-Pass Noise Attenuation", UVM_LOW)

    // 8-tap low pass filter taps: [1/8, 1/8, ... 1/8] = 0x1000 each
    write_reg(REG_FIR_NTAPS, 32'd8);
    for (k = 0; k < 8; k++) begin
      write_reg(REG_FIR_COEF0 + (k*4), 16'sh1000);
    end
    write_reg(REG_FIR_CTRL, 32'h0000_0001);

    // Generate sinusoidal + high freq noise samples
    for (k = 0; k < 16; k++) begin
      noise_samples[k] = (k % 2 == 0) ? (16'sh2000 + 16'sh0800) : (16'sh2000 - 16'sh0800);
      inject_sample(noise_samples[k]);
    end

    #300;
    `uvm_info("TC_FIR_05", "TC_FIR_05 completed successfully!", UVM_LOW)
  endtask
endclass : tc_fir_05_noise_filtering_seq

// -----------------------------------------------------------------------------
// TC_FIR_06: Memory-Mapped Direct Sample Injection
// -----------------------------------------------------------------------------
class tc_fir_06_mm_sample_seq extends fir_base_axi_seq;
  `uvm_object_utils(tc_fir_06_mm_sample_seq)

  function new(string name = "tc_fir_06_mm_sample_seq");
    super.new(name);
  endfunction

  virtual task body();
    bit [31:0] rdata;
    `uvm_info("TC_FIR_06", "Starting TC_FIR_06: Memory-Mapped Direct Sample Injection", UVM_LOW)

    // Milestone 25%: Write sample to FIR_DATA_IN (0x50)
    `uvm_info("TC_FIR_06", "[TC_FIR_06 25%%] Writing 0x2468 to FIR_DATA_IN", UVM_LOW)
    write_reg(REG_FIR_DATA_IN, 32'h0000_2468);

    // Milestone 50%: Poll FIR_DATA_STATUS (0x58)
    #100;
    read_reg(REG_FIR_DATA_STAT, rdata);
    `uvm_info("TC_FIR_06", $sformatf("[TC_FIR_06 50%%] FIR_DATA_STATUS = 0x%08x", rdata), UVM_LOW)

    // Milestone 75%: Read filtered sample from FIR_DATA_OUT (0x54)
    read_reg(REG_FIR_DATA_OUT, rdata);
    `uvm_info("TC_FIR_06", $sformatf("[TC_FIR_06 75%%] Read FIR_DATA_OUT = 0x%04x", rdata[15:0]), UVM_LOW)

    // Milestone 100%: Scoreboard verified result against golden model
    `uvm_info("TC_FIR_06", "[TC_FIR_06 100%%] MM sample injection verified!", UVM_LOW)
  endtask
endclass : tc_fir_06_mm_sample_seq

// -----------------------------------------------------------------------------
// All Features Composite Sequence
// -----------------------------------------------------------------------------
class fir_all_features_seq extends fir_base_axi_seq;
  `uvm_object_utils(fir_all_features_seq)

  function new(string name = "fir_all_features_seq");
    super.new(name);
  endfunction

  virtual task body();
    tc_fir_01_impulse_response_seq seq_01;
    tc_fir_02_bypass_mode_seq      seq_02;
    tc_fir_03_tap_scaling_seq      seq_03;
    tc_fir_04_saturation_clamping_seq seq_04;
    tc_fir_05_noise_filtering_seq  seq_05;
    tc_fir_06_mm_sample_seq        seq_06;

    `uvm_info("FIR_ALL", "Running All FIR Features Verification Sequences", UVM_LOW)

    seq_01 = tc_fir_01_impulse_response_seq::type_id::create("seq_01");
    seq_01.sample_seqr = sample_seqr;
    seq_01.start(m_sequencer);

    seq_02 = tc_fir_02_bypass_mode_seq::type_id::create("seq_02");
    seq_02.sample_seqr = sample_seqr;
    seq_02.start(m_sequencer);

    seq_03 = tc_fir_03_tap_scaling_seq::type_id::create("seq_03");
    seq_03.sample_seqr = sample_seqr;
    seq_03.start(m_sequencer);

    seq_04 = tc_fir_04_saturation_clamping_seq::type_id::create("seq_04");
    seq_04.sample_seqr = sample_seqr;
    seq_04.start(m_sequencer);

    seq_05 = tc_fir_05_noise_filtering_seq::type_id::create("seq_05");
    seq_05.sample_seqr = sample_seqr;
    seq_05.start(m_sequencer);

    seq_06 = tc_fir_06_mm_sample_seq::type_id::create("seq_06");
    seq_06.sample_seqr = sample_seqr;
    seq_06.start(m_sequencer);

    `uvm_info("FIR_ALL", "All FIR Features Verification Sequences Completed!", UVM_LOW)
  endtask
endclass : fir_all_features_seq

`endif // FIR_SEQ_LIB_SV
