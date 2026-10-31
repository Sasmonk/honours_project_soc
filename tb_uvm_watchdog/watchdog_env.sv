// =============================================================================
// Environment  : watchdog_env.sv
// Description  : UVM Environment for Watchdog Safety Supervisory Subsystem
// =============================================================================
`ifndef WATCHDOG_ENV_SV
`define WATCHDOG_ENV_SV

class watchdog_env extends uvm_env;
  `uvm_component_utils(watchdog_env)

  axi_agent          axi_agt;
  wdt_safety_agent   safety_agt;
  watchdog_scoreboard sb;
  watchdog_coverage   cov;

  function new(string name = "watchdog_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    axi_agt    = axi_agent::type_id::create("axi_agt", this);
    safety_agt = wdt_safety_agent::type_id::create("safety_agt", this);
    sb         = watchdog_scoreboard::type_id::create("sb", this);
    cov        = watchdog_coverage::type_id::create("cov", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    axi_agt.ap.connect(sb.axi_export);
    axi_agt.ap.connect(cov.axi_cov_export);

    safety_agt.mon.item_collected_port.connect(sb.safety_export);
    safety_agt.mon.item_collected_port.connect(cov.analysis_export);
  endfunction

endclass : watchdog_env

`endif // WATCHDOG_ENV_SV
