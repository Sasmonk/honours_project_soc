// =============================================================================
// Environment  : axi_env.sv
// Description  : Standard UVM Environment for AXI VIP
// =============================================================================
`ifndef AXI_ENV_SV
`define AXI_ENV_SV

class axi_env extends uvm_env;
  `uvm_component_utils(axi_env)

  axi_agent      agent;
  axi_scoreboard sb;

  function new(string name = "axi_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = axi_agent::type_id::create("agent", this);
    sb    = axi_scoreboard::type_id::create("sb", this);
  endfunction : build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent.ap.connect(sb.item_export);
  endfunction : connect_phase
endclass : axi_env

`endif // AXI_ENV_SV
