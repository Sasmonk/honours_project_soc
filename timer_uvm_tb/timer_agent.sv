// =============================================================================
// Agent        : timer_agent.sv
// Description  : Standard UVM Agent (Driver, Monitor, Sequencer) for TIMER
// =============================================================================
`ifndef TIMER_AGENT_SV
`define TIMER_AGENT_SV

class timer_agent extends uvm_agent;
  `uvm_component_utils(timer_agent)

  uvm_active_passive_enum is_active = UVM_ACTIVE;
  timer_driver    drv;
  timer_monitor   mon;
  timer_sequencer seqr;
  uvm_analysis_port #(timer_item) ap;

  function new(string name = "timer_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon = timer_monitor::type_id::create("mon", this);
    if (is_active == UVM_ACTIVE) begin
      drv  = timer_driver::type_id::create("drv", this);
      seqr = timer_sequencer::type_id::create("seqr", this);
    end
  endfunction : build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    ap = mon.ap;
    if (is_active == UVM_ACTIVE) begin
      drv.seq_item_port.connect(seqr.seq_item_export);
    end
  endfunction : connect_phase
endclass : timer_agent

`endif // TIMER_AGENT_SV
