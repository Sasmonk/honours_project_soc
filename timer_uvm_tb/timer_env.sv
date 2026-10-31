// =============================================================================
// Environment  : timer_env.sv
// Description  : Standard UVM Environment for TIMER VIP
// =============================================================================
`ifndef TIMER_ENV_SV
`define TIMER_ENV_SV

class timer_env extends uvm_env;
  `uvm_component_utils(timer_env)

  timer_agent      agent;
  timer_scoreboard sb;

  function new(string name = "timer_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = timer_agent::type_id::create("agent", this);
    sb    = timer_scoreboard::type_id::create("sb", this);
  endfunction : build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent.ap.connect(sb.item_export);
  endfunction : connect_phase
endclass : timer_env

`endif // TIMER_ENV_SV
