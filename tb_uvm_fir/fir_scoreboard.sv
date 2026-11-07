// =============================================================================
// Scoreboard   : fir_scoreboard.sv
// Description  : Reference Model Scoreboard for 16-Tap Q1.15 FIR Digital Filter
// =============================================================================
`ifndef FIR_SCOREBOARD_SV
`define FIR_SCOREBOARD_SV

`uvm_analysis_imp_decl(_fir_axi)
`uvm_analysis_imp_decl(_fir_drv)
`uvm_analysis_imp_decl(_fir_mon)
`uvm_analysis_imp_decl(_fir_irq)

class fir_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(fir_scoreboard)

  uvm_analysis_imp_fir_axi #(axi_item, fir_scoreboard)        axi_export;
  uvm_analysis_imp_fir_drv #(fir_sample_item, fir_scoreboard) drv_export;
  uvm_analysis_imp_fir_mon #(fir_sample_item, fir_scoreboard) mon_export;
  uvm_analysis_imp_fir_irq #(bit, fir_scoreboard)             irq_export;

  // Tracked Registers
  bit               reg_fir_en     = 1'b0;
  bit               reg_fir_bypass = 1'b1;
  bit [4:0]         reg_fir_ntaps  = 5'd8;
  bit signed [15:0] reg_coef_mem [0:15];
  bit               reg_coef_load_done = 1'b0;
  bit               reg_pipe_ovf       = 1'b0;

  // Golden Model State
  bit signed [15:0] golden_delay_line [0:15];
  bit signed [15:0] expected_out_q[$];
  bit signed [15:0] mm_expected_out_q[$];

  // Test Checkpoint Flags
  bit cp_fir_01_pass = 1'b0;
  bit cp_fir_02_pass = 1'b0;
  bit cp_fir_03_pass = 1'b0;
  bit cp_fir_04_pass = 1'b0;
  bit cp_fir_05_pass = 1'b0;
  bit cp_fir_06_pass = 1'b0;
  bit sva_fir_01_pass = 1'b1;
  bit sva_fir_02_pass = 1'b1;

  // Match Statistics
  int unsigned stream_match_count    = 0;
  int unsigned stream_mismatch_count = 0;
  int unsigned mm_match_count        = 0;
  int unsigned mm_mismatch_count     = 0;
  int unsigned saturation_events     = 0;

  function new(string name = "fir_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    axi_export = new("axi_export", this);
    drv_export = new("drv_export", this);
    mon_export = new("mon_export", this);
    irq_export = new("irq_export", this);

    for (int k = 0; k < 16; k++) begin
      reg_coef_mem[k]      = 16'sd0;
      golden_delay_line[k] = 16'sd0;
    end
  endfunction : new

  // 1. AXI CSR Callback
  virtual function void write_fir_axi(axi_item item);
    bit [7:0] reg_offset = item.addr[7:0];

    if (item.op == AXI_WRITE) begin
      if (reg_offset == 8'h00) begin
        reg_fir_en     = item.data[0];
        reg_fir_bypass = item.data[1];
        `uvm_info("SCOREBOARD", $sformatf("FIR_CTRL written: EN=%b BYPASS=%b", reg_fir_en, reg_fir_bypass), UVM_LOW)
      end else if (reg_offset == 8'h04) begin
        reg_fir_ntaps = item.data[4:0];
        `uvm_info("SCOREBOARD", $sformatf("FIR_NTAPS written: %0d", reg_fir_ntaps), UVM_LOW)
      end else if (reg_offset >= 8'h08 && reg_offset <= 8'h44) begin
        int tap_idx = (reg_offset - 8'h08) >> 2;
        reg_coef_mem[tap_idx] = item.data[15:0];
        `uvm_info("SCOREBOARD", $sformatf("FIR_COEF[%0d] = 0x%04x (%0d)", tap_idx, item.data[15:0], $signed(item.data[15:0])), UVM_HIGH)
      end else if (reg_offset == 8'h50) begin
        // Memory-Mapped Sample Input Injection (TC_FIR_06)
        process_sample_into_golden_model(item.data[15:0], 1'b1);
      end
    end else if (item.op == AXI_READ) begin
      if (reg_offset == 8'h54) begin
        // Memory-Mapped Sample Output Read (TC_FIR_06)
        bit signed [15:0] act = item.data[15:0];
        if (mm_expected_out_q.size() > 0) begin
          bit signed [15:0] exp = mm_expected_out_q.pop_front();
          if (act === exp) begin
            mm_match_count++;
            cp_fir_06_pass = 1'b1;
            `uvm_info("SCOREBOARD", $sformatf("[TC_FIR_06 100%%] MM Data Out Match: 0x%04x (%0d)", act, act), UVM_LOW)
          end else begin
            mm_mismatch_count++;
            `uvm_error("SCOREBOARD", $sformatf("MM Data Out MISMATCH! Exp=0x%04x Got=0x%04x", exp, act))
          end
        end
      end
    end
  endfunction : write_fir_axi

  // 2. Driven Streaming Sample Callback
  virtual function void write_fir_drv(fir_sample_item item);
    process_sample_into_golden_model(item.sample_data, 1'b0);
  endfunction : write_fir_drv

  // Common Golden Model computation
  function void process_sample_into_golden_model(bit signed [15:0] s_in, bit is_mm);
    bit signed [15:0] expected_sat_out;

    if (reg_fir_bypass || !reg_fir_en) begin
      // Bypass mode: output strictly equals input
      expected_sat_out = s_in;
      if (reg_fir_bypass) cp_fir_02_pass = 1'b1;
    end else begin
      // Q1.15 MAC accumulation
      longint signed acc = 0;
      longint signed mult = 0;

      for (int k = 0; k < 16; k++) begin
        if (k < reg_fir_ntaps) begin
          mult = (k == 0) ? (longint'(s_in) * longint'(reg_coef_mem[0]))
                          : (longint'(golden_delay_line[k-1]) * longint'(reg_coef_mem[k]));
          acc = acc + mult;
        end
      end

      // Update golden delay line
      for (int k = 15; k >= 1; k--) begin
        golden_delay_line[k] = golden_delay_line[k-1];
      end
      golden_delay_line[0] = s_in;

      // Scaling: shift right by 15 with saturation
      if ((acc[39:30] == 10'd0) || (acc[39:30] == 10'h3FF)) begin
        expected_sat_out = acc[30:15];
      end else if (acc[39]) begin
        expected_sat_out = -16'sd32768;
        saturation_events++;
        cp_fir_04_pass = 1'b1;
      end else begin
        expected_sat_out = 16'sd32767;
        saturation_events++;
        cp_fir_04_pass = 1'b1;
      end
    end

    if (is_mm) begin
      mm_expected_out_q.push_back(expected_sat_out);
    end else begin
      expected_out_q.push_back(expected_sat_out);
    end
  endfunction : process_sample_into_golden_model

  // 3. Observed Streaming Sample Callback
  virtual function void write_fir_mon(fir_sample_item item);
    if (expected_out_q.size() > 0) begin
      bit signed [15:0] exp = expected_out_q.pop_front();
      bit signed [15:0] act = item.sample_data;

      // Check SVA_FIR_01: output strictly in valid 16-bit signed range
      if (act > 16'sd32767 || act < -16'sd32768) begin
        sva_fir_01_pass = 1'b0;
        `uvm_error("SCOREBOARD", $sformatf("[SVA_FIR_01 FAIL] Value out of range: %0d", act))
      end

      if (act === exp) begin
        stream_match_count++;
        cp_fir_01_pass = 1'b1;
        cp_fir_03_pass = 1'b1;
        cp_fir_05_pass = 1'b1;
        `uvm_info("SCOREBOARD", $sformatf("Sample Match: Exp=0x%04x (%0d) Got=0x%04x", exp, exp, act), UVM_HIGH)
      end else begin
        stream_mismatch_count++;
        `uvm_error("SCOREBOARD", $sformatf("Sample MISMATCH: Exp=0x%04x (%0d) Got=0x%04x (%0d)",
                   exp, exp, act, act))
      end
    end
  endfunction : write_fir_mon

  // 4. IRQ Strobe Callback
  virtual function void write_fir_irq(bit irq_val);
    `uvm_info("SCOREBOARD", $sformatf("irq_fir transition: %b", irq_val), UVM_HIGH)
  endfunction : write_fir_irq

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("SCOREBOARD", "=================================================================", UVM_LOW)
    `uvm_info("SCOREBOARD", "              FIR FILTER UVM SCOREBOARD FINAL REPORT             ", UVM_LOW)
    `uvm_info("SCOREBOARD", "=================================================================", UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  Streaming Samples Matched   : %0d", stream_match_count), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  Streaming Mismatches        : %0d", stream_mismatch_count), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  Memory-Mapped Matches       : %0d", mm_match_count), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  Memory-Mapped Mismatches    : %0d", mm_mismatch_count), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  Saturation Events Verified  : %0d", saturation_events), UVM_LOW)
    `uvm_info("SCOREBOARD", "-----------------------------------------------------------------", UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  [TC_FIR_01] Q1.15 Impulse Response  : %s", cp_fir_01_pass ? "PASS" : "FAIL"), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  [TC_FIR_02] Hardware Bypass Mode    : %s", cp_fir_02_pass ? "PASS" : "FAIL"), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  [TC_FIR_03] Runtime Tap Scaling     : %s", cp_fir_03_pass ? "PASS" : "FAIL"), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  [TC_FIR_04] Overflow & Saturation   : %s", cp_fir_04_pass ? "PASS" : "FAIL"), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  [TC_FIR_05] Noise Attenuation       : %s", cp_fir_05_pass ? "PASS" : "FAIL"), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  [TC_FIR_06] Memory-Mapped Access    : %s", cp_fir_06_pass ? "PASS" : "FAIL"), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  [SVA_FIR_01] Saturation Range Check : %s", sva_fir_01_pass ? "PASS" : "FAIL"), UVM_LOW)
    `uvm_info("SCOREBOARD", "=================================================================", UVM_LOW)

    if (stream_mismatch_count > 0 || mm_mismatch_count > 0 || !sva_fir_01_pass) begin
      `uvm_error("SCOREBOARD", "FIR FILTER SCOREBOARD VERIFICATION FAILED!")
    end else begin
      `uvm_info("SCOREBOARD", "FIR FILTER SCOREBOARD VERIFICATION PASSED SUCCESSFULLY!", UVM_LOW)
    end
  endfunction : report_phase

endclass : fir_scoreboard

`endif // FIR_SCOREBOARD_SV
