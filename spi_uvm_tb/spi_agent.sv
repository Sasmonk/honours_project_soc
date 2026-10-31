// =============================================================================
// Agent        : spi_agent.sv
// Description  : Standard UVM Agent (Driver, Monitor, Sequencer) for SPI
// =============================================================================
`ifndef SPI_AGENT_SV
`define SPI_AGENT_SV

class spi_agent extends uvm_agent;
  `uvm_component_utils(spi_agent)

  uvm_active_passive_enum is_active = UVM_ACTIVE;
  spi_driver    drv;
  spi_monitor   mon;
  spi_sequencer seqr;
  uvm_analysis_port #(spi_item) ap;

  function new(string name = "spi_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon = spi_monitor::type_id::create("mon", this);
    if (is_active == UVM_ACTIVE) begin
      drv  = spi_driver::type_id::create("drv", this);
      seqr = spi_sequencer::type_id::create("seqr", this);
    end
  endfunction : build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    ap = mon.ap;
    if (is_active == UVM_ACTIVE) begin
      drv.seq_item_port.connect(seqr.seq_item_export);
    end
  endfunction : connect_phase
endclass : spi_agent

`endif // SPI_AGENT_SV
