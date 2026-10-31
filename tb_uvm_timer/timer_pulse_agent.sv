// =============================================================================
// Agent        : timer_pulse_agent.sv
// Description  : UVM Agent for Timer pulse monitoring
// =============================================================================
`ifndef TIMER_PULSE_AGENT_SV
`define TIMER_PULSE_AGENT_SV

class timer_pulse_agent extends uvm_agent;
  `uvm_component_utils(timer_pulse_agent)

  timer_pulse_monitor mon;

  function new(string name = "timer_pulse_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon = timer_pulse_monitor::type_id::create("mon", this);
  endfunction

endclass : timer_pulse_agent

`endif // TIMER_PULSE_AGENT_SV
