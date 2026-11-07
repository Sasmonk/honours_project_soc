// =============================================================================
// Agent        : dma_agent.sv
// Description  : UVM Agent encapsulating Driver, Responder & Monitor for DMA
// =============================================================================
`ifndef DMA_AGENT_SV
`define DMA_AGENT_SV

class dma_agent extends uvm_agent;
  `uvm_component_utils(dma_agent)

  dma_stream_driver        driver;
  dma_axi_master_responder responder;
  dma_monitor              monitor;

  uvm_analysis_port #(dma_axi_xfer_item) axi_xfer_ap;
  uvm_analysis_port #(dma_stream_item)   stream_ap;
  uvm_analysis_port #(dma_event_item)    event_ap;

  function new(string name = "dma_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    driver      = dma_stream_driver::type_id::create("driver", this);
    responder   = dma_axi_master_responder::type_id::create("responder", this);
    monitor     = dma_monitor::type_id::create("monitor", this);
    axi_xfer_ap = new("axi_xfer_ap", this);
    stream_ap   = new("stream_ap", this);
    event_ap    = new("event_ap", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    responder.ap.connect(axi_xfer_ap);
    monitor.stream_ap.connect(stream_ap);
    monitor.event_ap.connect(event_ap);
  endfunction

endclass : dma_agent

`endif // DMA_AGENT_SV
