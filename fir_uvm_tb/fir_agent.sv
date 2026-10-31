// =============================================================================
// Agent        : fir_agent.sv
// Description  : Standard UVM Agent (Driver, Monitor, Sequencer) for FIR
// =============================================================================
`ifndef FIR_AGENT_SV
`define FIR_AGENT_SV

class fir_agent extends uvm_agent;
  `uvm_component_utils(fir_agent)

  uvm_active_passive_enum is_active = UVM_ACTIVE;
  fir_driver    drv;
  fir_monitor   mon;
  fir_sequencer seqr;
  uvm_analysis_port #(fir_item) ap;

  function new(string name = "fir_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon = fir_monitor::type_id::create("mon", this);
    if (is_active == UVM_ACTIVE) begin
      drv  = fir_driver::type_id::create("drv", this);
      seqr = fir_sequencer::type_id::create("seqr", this);
    end
  endfunction : build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    ap = mon.ap;
    if (is_active == UVM_ACTIVE) begin
      drv.seq_item_port.connect(seqr.seq_item_export);
    end
  endfunction : connect_phase
endclass : fir_agent

`endif // FIR_AGENT_SV
