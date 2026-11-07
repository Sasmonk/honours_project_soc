// =============================================================================
// Agents       : sbuf_agents.sv
// Description  : UVM Agents for DMA Write Port A and VGA Read Port B
// =============================================================================
`ifndef SBUF_AGENTS_SV
`define SBUF_AGENTS_SV

typedef uvm_sequencer #(sbuf_dma_item) sbuf_dma_sequencer;
typedef uvm_sequencer #(sbuf_vga_item) sbuf_vga_sequencer;

class sbuf_dma_agent extends uvm_agent;
  `uvm_component_utils(sbuf_dma_agent)

  sbuf_dma_driver    drv;
  sbuf_dma_monitor   mon;
  sbuf_dma_sequencer seqr;

  function new(string name = "sbuf_dma_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    drv  = sbuf_dma_driver::type_id::create("drv", this);
    mon  = sbuf_dma_monitor::type_id::create("mon", this);
    seqr = sbuf_dma_sequencer::type_id::create("seqr", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(seqr.seq_item_export);
  endfunction

endclass : sbuf_dma_agent

class sbuf_vga_agent extends uvm_agent;
  `uvm_component_utils(sbuf_vga_agent)

  sbuf_vga_driver    drv;
  sbuf_vga_monitor   mon;
  sbuf_vga_sequencer seqr;

  function new(string name = "sbuf_vga_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    drv  = sbuf_vga_driver::type_id::create("drv", this);
    mon  = sbuf_vga_monitor::type_id::create("mon", this);
    seqr = sbuf_vga_sequencer::type_id::create("seqr", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(seqr.seq_item_export);
  endfunction

endclass : sbuf_vga_agent

`endif // SBUF_AGENTS_SV
