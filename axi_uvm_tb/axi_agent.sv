// =============================================================================
// Agent        : axi_agent.sv
// Description  : Standard UVM Agent (Driver, Monitor, Sequencer) for AXI
// =============================================================================
`ifndef AXI_AGENT_SV
`define AXI_AGENT_SV

class axi_agent extends uvm_agent;
  `uvm_component_utils(axi_agent)

  uvm_active_passive_enum is_active = UVM_ACTIVE;
  axi_driver    drv;
  axi_monitor   mon;
  axi_sequencer seqr;
  uvm_analysis_port #(axi_item) ap;

  function new(string name = "axi_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon = axi_monitor::type_id::create("mon", this);
    if (is_active == UVM_ACTIVE) begin
      drv  = axi_driver::type_id::create("drv", this);
      seqr = axi_sequencer::type_id::create("seqr", this);
    end
  endfunction : build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    ap = mon.ap;
    if (is_active == UVM_ACTIVE) begin
      drv.seq_item_port.connect(seqr.seq_item_export);
    end
  endfunction : connect_phase
endclass : axi_agent

`endif // AXI_AGENT_SV
