// =============================================================================
// Agent        : watchdog_agent.sv
// Description  : Standard UVM Agent (Driver, Monitor, Sequencer) for WATCHDOG
// =============================================================================
`ifndef WATCHDOG_AGENT_SV
`define WATCHDOG_AGENT_SV

class watchdog_agent extends uvm_agent;
  `uvm_component_utils(watchdog_agent)

  uvm_active_passive_enum is_active = UVM_ACTIVE;
  watchdog_driver    drv;
  watchdog_monitor   mon;
  watchdog_sequencer seqr;
  uvm_analysis_port #(watchdog_item) ap;

  function new(string name = "watchdog_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon = watchdog_monitor::type_id::create("mon", this);
    if (is_active == UVM_ACTIVE) begin
      drv  = watchdog_driver::type_id::create("drv", this);
      seqr = watchdog_sequencer::type_id::create("seqr", this);
    end
  endfunction : build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    ap = mon.ap;
    if (is_active == UVM_ACTIVE) begin
      drv.seq_item_port.connect(seqr.seq_item_export);
    end
  endfunction : connect_phase
endclass : watchdog_agent

`endif // WATCHDOG_AGENT_SV
