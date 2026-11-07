// =============================================================================
// Environment  : dma_env.sv
// Description  : UVM Environment instantiating AXI CSR, DMA Agent & Scoreboard
// =============================================================================
`ifndef DMA_ENV_SV
`define DMA_ENV_SV

class dma_env extends uvm_env;
  `uvm_component_utils(dma_env)

  axi_agent      axi_agt;
  dma_agent      dma_agt;
  dma_scoreboard sb;
  dma_coverage   cov;

  function new(string name = "dma_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    axi_agt = axi_agent::type_id::create("axi_agt", this);
    dma_agt = dma_agent::type_id::create("dma_agt", this);
    sb      = dma_scoreboard::type_id::create("sb", this);
    cov     = dma_coverage::type_id::create("cov", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    axi_agt.ap.connect(sb.axi_csr_export);
    dma_agt.axi_xfer_ap.connect(sb.axi_xfer_export);
    dma_agt.stream_ap.connect(sb.stream_export);
    dma_agt.event_ap.connect(sb.event_export);
    dma_agt.axi_xfer_ap.connect(cov.analysis_export);
  endfunction

endclass : dma_env

`endif // DMA_ENV_SV
