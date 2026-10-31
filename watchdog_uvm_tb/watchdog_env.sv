// =============================================================================
// Environment  : watchdog_env.sv
// Description  : Standard UVM Environment for WATCHDOG VIP
// =============================================================================
`ifndef WATCHDOG_ENV_SV
`define WATCHDOG_ENV_SV

class watchdog_env extends uvm_env;
  `uvm_component_utils(watchdog_env)

  watchdog_agent      agent;
  watchdog_scoreboard sb;

  function new(string name = "watchdog_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = watchdog_agent::type_id::create("agent", this);
    sb    = watchdog_scoreboard::type_id::create("sb", this);
  endfunction : build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent.ap.connect(sb.item_export);
  endfunction : connect_phase
endclass : watchdog_env

`endif // WATCHDOG_ENV_SV
