// =============================================================================
// Agent        : fir_sample_agent.sv
// Description  : UVM Agent containing FIR sample driver, monitor, and sequencer
// =============================================================================
`ifndef FIR_SAMPLE_AGENT_SV
`define FIR_SAMPLE_AGENT_SV

typedef uvm_sequencer #(fir_sample_item) fir_sample_sequencer;

class fir_sample_agent extends uvm_agent;
  `uvm_component_utils(fir_sample_agent)

  fir_sample_driver    drv;
  fir_sample_monitor   mon;
  fir_sample_sequencer seqr;

  function new(string name = "fir_sample_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    drv  = fir_sample_driver::type_id::create("drv", this);
    mon  = fir_sample_monitor::type_id::create("mon", this);
    seqr = fir_sample_sequencer::type_id::create("seqr", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(seqr.seq_item_export);
  endfunction

endclass : fir_sample_agent

`endif // FIR_SAMPLE_AGENT_SV
