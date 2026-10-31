// =============================================================================
// Agent        : wdt_safety_agent.sv
// Description  : UVM Agent for Watchdog safety and heartbeat monitoring
// =============================================================================
`ifndef WDT_SAFETY_AGENT_SV
`define WDT_SAFETY_AGENT_SV

class wdt_safety_agent extends uvm_agent;
  `uvm_component_utils(wdt_safety_agent)

  wdt_safety_monitor mon;

  function new(string name = "wdt_safety_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon = wdt_safety_monitor::type_id::create("mon", this);
  endfunction

endclass : wdt_safety_agent

`endif // WDT_SAFETY_AGENT_SV
