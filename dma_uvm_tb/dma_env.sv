// =============================================================================
// Environment  : dma_env.sv
// Description  : Standard UVM Environment for DMA VIP
// =============================================================================
`ifndef DMA_ENV_SV
`define DMA_ENV_SV

class dma_env extends uvm_env;
  `uvm_component_utils(dma_env)

  dma_agent      agent;
  dma_scoreboard sb;

  function new(string name = "dma_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = dma_agent::type_id::create("agent", this);
    sb    = dma_scoreboard::type_id::create("sb", this);
  endfunction : build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent.ap.connect(sb.item_export);
  endfunction : connect_phase
endclass : dma_env

`endif // DMA_ENV_SV
