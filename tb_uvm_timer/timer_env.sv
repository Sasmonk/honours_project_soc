// =============================================================================
// Environment  : timer_env.sv
// Description  : UVM Environment for System Timer Verification
// =============================================================================
`ifndef TIMER_ENV_SV
`define TIMER_ENV_SV

class timer_env extends uvm_env;
  `uvm_component_utils(timer_env)

  axi_agent         axi_agt;
  timer_pulse_agent pulse_agt;
  timer_scoreboard  sb;
  timer_coverage    cov;

  function new(string name = "timer_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    axi_agt   = axi_agent::type_id::create("axi_agt", this);
    pulse_agt = timer_pulse_agent::type_id::create("pulse_agt", this);
    sb        = timer_scoreboard::type_id::create("sb", this);
    cov       = timer_coverage::type_id::create("cov", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // Connect AXI Agent to Scoreboard and Coverage
    axi_agt.ap.connect(sb.axi_export);
    axi_agt.ap.connect(cov.axi_cov_export);

    // Connect Pulse monitor to Scoreboard and Coverage
    pulse_agt.mon.item_collected_port.connect(sb.pulse_export);
    pulse_agt.mon.item_collected_port.connect(cov.analysis_export);
  endfunction

endclass : timer_env

`endif // TIMER_ENV_SV
