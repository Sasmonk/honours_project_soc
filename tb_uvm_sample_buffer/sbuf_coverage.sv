// =============================================================================
// Coverage     : sbuf_coverage.sv
// Description  : Functional Coverage for True Dual-Port Ping-Pong Sample Buffer
// =============================================================================
`ifndef SBUF_COVERAGE_SV
`define SBUF_COVERAGE_SV

class sbuf_coverage extends uvm_subscriber #(sbuf_dma_item);
  `uvm_component_utils(sbuf_coverage)

  bit [11:0] cov_waddr;
  bit        cov_swap_req;
  bit        cov_we;
  bit        cov_pp_en;
  bit        cov_auto_swap;
  bit        cov_hold;

  uvm_analysis_imp_sbuf_axi #(axi_item, sbuf_coverage) axi_cov_export;

  covergroup cg_sample_buffer;
    option.per_instance = 1;
    option.comment = "Dual-Port Sample Buffer Functional Coverage";

    // Write address range across Bank A and Bank B
    cp_waddr: coverpoint cov_waddr {
      bins bank_a_start = {12'h000};
      bins bank_a_mid   = {[12'h001:12'h7FE]};
      bins bank_a_wrap  = {12'h7FF};
      bins bank_b_start = {12'h800};
      bins bank_b_mid   = {[12'h801:12'hFFE]};
      bins bank_b_wrap  = {12'hFFF};
    }

    // Ping-pong buffer control flags
    cp_pp_en: coverpoint cov_pp_en {
      bins disabled = {1'b0};
      bins enabled  = {1'b1};
    }

    cp_auto_swap: coverpoint cov_auto_swap {
      bins disabled = {1'b0};
      bins enabled  = {1'b1};
    }

    cp_hold: coverpoint cov_hold {
      bins active = {1'b0};
      bins frozen = {1'b1};
    }

    // Swap request trigger
    cp_swap_req: coverpoint cov_swap_req {
      bins no_swap  = {1'b0};
      bins swap_req = {1'b1};
    }

    // Cross between bank address and hold mode
    cross_addr_hold: cross cp_waddr, cp_hold;

  endgroup : cg_sample_buffer

  function new(string name = "sbuf_coverage", uvm_component parent = null);
    super.new(name, parent);
    cg_sample_buffer = new();
    axi_cov_export   = new("axi_cov_export", this);
    cov_pp_en        = 1'b1;
    cov_auto_swap    = 1'b1;
    cov_hold         = 1'b0;
  endfunction

  virtual function void write(sbuf_dma_item t);
    cov_waddr    = t.addr;
    cov_swap_req = t.swap_req;
    cov_we       = t.we;
    cg_sample_buffer.sample();
  endfunction

  virtual function void write_sbuf_axi(axi_item item);
    if (item.op == AXI_WRITE && item.addr[13:0] == 14'h2000) begin
      cov_pp_en     = item.data[0];
      cov_auto_swap = item.data[1];
      cov_hold      = item.data[3];
    end
  endfunction

endclass : sbuf_coverage

`endif // SBUF_COVERAGE_SV
