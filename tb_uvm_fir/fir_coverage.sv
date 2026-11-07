// =============================================================================
// Coverage     : fir_coverage.sv
// Description  : Functional Coverage for 16-Tap Q1.15 FIR Digital Filter Subsystem
// =============================================================================
`ifndef FIR_COVERAGE_SV
`define FIR_COVERAGE_SV

class fir_coverage extends uvm_subscriber #(fir_sample_item);
  `uvm_component_utils(fir_coverage)

  // Tracked Coverpoint variables
  bit [4:0]  cov_ntaps;
  bit        cov_bypass;
  bit        cov_en;
  bit signed [15:0] cov_sample;
  bit        cov_saturation;

  uvm_analysis_imp_fir_axi #(axi_item, fir_coverage) axi_cov_export;

  covergroup cg_fir_dsp;
    option.per_instance = 1;
    option.comment = "FIR DSP Conditioning Functional Coverage";

    // Active tap count bins (1 to 16)
    cp_tap_count: coverpoint cov_ntaps {
      bins single_tap   = {5'd1};
      bins few_taps     = {[5'd2:5'd4]};
      bins medium_taps  = {[5'd5:5'd8]};
      bins high_taps    = {[5'd9:5'd15]};
      bins max_taps     = {5'd16};
    }

    // Bypass mode
    cp_bypass_mode: coverpoint cov_bypass {
      bins active_filtering = {1'b0};
      bins hardware_bypass  = {1'b1};
    }

    // Sample range bins (positive, negative, zero)
    cp_sample_range: coverpoint cov_sample {
      bins neg_full_scale = {[-16'sd32768:-16'sd24000]};
      bins neg_medium     = {[-16'sd23999:-16'sd1000]};
      bins near_zero      = {[-16'sd999:16'sd999]};
      bins pos_medium     = {[16'sd1000:16'sd24000]};
      bins pos_full_scale = {[16'sd24001:16'sd32767]};
    }

    // Saturation indicator
    cp_saturation: coverpoint cov_saturation {
      bins normal_range = {1'b0};
      bins saturated    = {1'b1};
    }

    // Cross between tap count and bypass mode
    cross_tap_bypass: cross cp_tap_count, cp_bypass_mode;

  endgroup : cg_fir_dsp

  function new(string name = "fir_coverage", uvm_component parent = null);
    super.new(name, parent);
    cg_fir_dsp = new();
    axi_cov_export = new("axi_cov_export", this);
  endfunction : new

  virtual function void write(fir_sample_item t);
    cov_sample = t.sample_data;
    cov_saturation = (t.sample_data == 16'sd32767 || t.sample_data == -16'sd32768);
    cg_fir_dsp.sample();
  endfunction : write

  virtual function void write_fir_axi(axi_item item);
    if (item.op == AXI_WRITE && item.addr[7:0] == 8'h00) begin
      cov_en     = item.data[0];
      cov_bypass = item.data[1];
    end else if (item.op == AXI_WRITE && item.addr[7:0] == 8'h04) begin
      cov_ntaps = item.data[4:0];
    end
  endfunction : write_fir_axi

endclass : fir_coverage

`endif // FIR_COVERAGE_SV
