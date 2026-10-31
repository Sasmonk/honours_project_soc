// =============================================================================
// Agent        : sample_buffer_agent.sv
// Description  : Standard UVM Agent (Driver, Monitor, Sequencer) for SAMPLE_BUFFER
// =============================================================================
`ifndef SAMPLE_BUFFER_AGENT_SV
`define SAMPLE_BUFFER_AGENT_SV

class sample_buffer_agent extends uvm_agent;
  `uvm_component_utils(sample_buffer_agent)

  uvm_active_passive_enum is_active = UVM_ACTIVE;
  sample_buffer_driver    drv;
  sample_buffer_monitor   mon;
  sample_buffer_sequencer seqr;
  uvm_analysis_port #(sample_buffer_item) ap;

  function new(string name = "sample_buffer_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon = sample_buffer_monitor::type_id::create("mon", this);
    if (is_active == UVM_ACTIVE) begin
      drv  = sample_buffer_driver::type_id::create("drv", this);
      seqr = sample_buffer_sequencer::type_id::create("seqr", this);
    end
  endfunction : build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    ap = mon.ap;
    if (is_active == UVM_ACTIVE) begin
      drv.seq_item_port.connect(seqr.seq_item_export);
    end
  endfunction : connect_phase
endclass : sample_buffer_agent

`endif // SAMPLE_BUFFER_AGENT_SV
