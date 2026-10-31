// =============================================================================
// Agent        : dma_agent.sv
// Description  : Standard UVM Agent (Driver, Monitor, Sequencer) for DMA
// =============================================================================
`ifndef DMA_AGENT_SV
`define DMA_AGENT_SV

class dma_agent extends uvm_agent;
  `uvm_component_utils(dma_agent)

  uvm_active_passive_enum is_active = UVM_ACTIVE;
  dma_driver    drv;
  dma_monitor   mon;
  dma_sequencer seqr;
  uvm_analysis_port #(dma_item) ap;

  function new(string name = "dma_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon = dma_monitor::type_id::create("mon", this);
    if (is_active == UVM_ACTIVE) begin
      drv  = dma_driver::type_id::create("drv", this);
      seqr = dma_sequencer::type_id::create("seqr", this);
    end
  endfunction : build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    ap = mon.ap;
    if (is_active == UVM_ACTIVE) begin
      drv.seq_item_port.connect(seqr.seq_item_export);
    end
  endfunction : connect_phase
endclass : dma_agent

`endif // DMA_AGENT_SV
