// =============================================================================
// Environment  : fir_env.sv
// Description  : Standard UVM Environment for FIR VIP
// =============================================================================
`ifndef FIR_ENV_SV
`define FIR_ENV_SV

class fir_env extends uvm_env;
  `uvm_component_utils(fir_env)

  fir_agent      agent;
  fir_scoreboard sb;

  function new(string name = "fir_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = fir_agent::type_id::create("agent", this);
    sb    = fir_scoreboard::type_id::create("sb", this);
  endfunction : build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent.ap.connect(sb.item_export);
  endfunction : connect_phase
endclass : fir_env

`endif // FIR_ENV_SV
