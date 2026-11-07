// =============================================================================
// Environment  : sbuf_env.sv
// Description  : UVM Environment for True Dual-Port Sample Buffer Verification
// =============================================================================
`ifndef SBUF_ENV_SV
`define SBUF_ENV_SV

class sbuf_env extends uvm_env;
  `uvm_component_utils(sbuf_env)

  axi_agent        axi_agt;
  sbuf_dma_agent   dma_agt;
  sbuf_vga_agent   vga_agt;
  sbuf_scoreboard  sb;
  sbuf_coverage    cov;

  function new(string name = "sbuf_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    axi_agt = axi_agent::type_id::create("axi_agt", this);
    dma_agt = sbuf_dma_agent::type_id::create("dma_agt", this);
    vga_agt = sbuf_vga_agent::type_id::create("vga_agt", this);
    sb      = sbuf_scoreboard::type_id::create("sb", this);
    cov     = sbuf_coverage::type_id::create("cov", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    axi_agt.ap.connect(sb.axi_export);
    axi_agt.ap.connect(cov.axi_cov_export);

    dma_agt.mon.ap.connect(sb.dma_export);
    dma_agt.mon.ap.connect(cov.analysis_export);
    dma_agt.mon.bank_swap_ap.connect(sb.swap_export);

    vga_agt.mon.ap.connect(sb.vga_export);
  endfunction

endclass : sbuf_env

`endif // SBUF_ENV_SV
