// =============================================================================
// Environment  : sample_buffer_env.sv
// Description  : Standard UVM Environment for SAMPLE_BUFFER VIP
// =============================================================================
`ifndef SAMPLE_BUFFER_ENV_SV
`define SAMPLE_BUFFER_ENV_SV

class sample_buffer_env extends uvm_env;
  `uvm_component_utils(sample_buffer_env)

  sample_buffer_agent      agent;
  sample_buffer_scoreboard sb;

  function new(string name = "sample_buffer_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = sample_buffer_agent::type_id::create("agent", this);
    sb    = sample_buffer_scoreboard::type_id::create("sb", this);
  endfunction : build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent.ap.connect(sb.item_export);
  endfunction : connect_phase
endclass : sample_buffer_env

`endif // SAMPLE_BUFFER_ENV_SV
