// =============================================================================
// Coverage     : dma_coverage.sv
// Description  : Functional coverage metrics for DMA Controller
// =============================================================================
`ifndef DMA_COVERAGE_SV
`define DMA_COVERAGE_SV

class dma_coverage extends uvm_subscriber #(dma_axi_xfer_item);
  `uvm_component_utils(dma_coverage)

  bit        cov_mode;
  bit        cov_src_inc;
  bit        cov_dst_inc;
  bit        cov_trigger_en;
  bit        cov_auto_reload;
  bit [15:0] cov_len;

  covergroup cg_dma_operations;
    cp_mode: coverpoint cov_mode {
      bins legacy_stream = {1'b0};
      bins axi_master    = {1'b1};
    }
    cp_src_inc: coverpoint cov_src_inc {
      bins fixed = {1'b0};
      bins incr  = {1'b1};
    }
    cp_dst_inc: coverpoint cov_dst_inc {
      bins fixed = {1'b0};
      bins incr  = {1'b1};
    }
    cp_trigger: coverpoint cov_trigger_en {
      bins free_run = {1'b0};
      bins paced    = {1'b1};
    }
    cp_reload: coverpoint cov_auto_reload {
      bins single_shot = {1'b0};
      bins ring_buffer = {1'b1};
    }
    cross_addr: cross cp_src_inc, cp_dst_inc;
    cross_mode_trig: cross cp_mode, cp_trigger;
  endgroup

  function new(string name = "dma_coverage", uvm_component parent = null);
    super.new(name, parent);
    cg_dma_operations = new();
  endfunction

  virtual function void write(dma_axi_xfer_item t);
    cg_dma_operations.sample();
  endfunction

  function void sample_cfg(bit mode, bit src_inc, bit dst_inc, bit trig_en, bit reload, bit [15:0] len);
    cov_mode        = mode;
    cov_src_inc     = src_inc;
    cov_dst_inc     = dst_inc;
    cov_trigger_en  = trig_en;
    cov_auto_reload = reload;
    cov_len         = len;
    cg_dma_operations.sample();
  endfunction

endclass : dma_coverage

`endif // DMA_COVERAGE_SV
