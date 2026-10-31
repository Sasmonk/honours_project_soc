// =============================================================================
// Agent        : vga_agent.sv
// Description  : Standard UVM Agent (Driver, Monitor, Sequencer) for VGA
// =============================================================================
`ifndef VGA_AGENT_SV
`define VGA_AGENT_SV

class vga_agent extends uvm_agent;
  `uvm_component_utils(vga_agent)

  uvm_active_passive_enum is_active = UVM_ACTIVE;
  vga_driver    drv;
  vga_monitor   mon;
  vga_sequencer seqr;
  uvm_analysis_port #(vga_item) ap;

  function new(string name = "vga_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon = vga_monitor::type_id::create("mon", this);
    if (is_active == UVM_ACTIVE) begin
      drv  = vga_driver::type_id::create("drv", this);
      seqr = vga_sequencer::type_id::create("seqr", this);
    end
  endfunction : build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    ap = mon.ap;
    if (is_active == UVM_ACTIVE) begin
      drv.seq_item_port.connect(seqr.seq_item_export);
    end
  endfunction : connect_phase
endclass : vga_agent

`endif // VGA_AGENT_SV
