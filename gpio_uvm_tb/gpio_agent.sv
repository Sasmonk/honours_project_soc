// =============================================================================
// Agent        : gpio_agent.sv
// Description  : Standard UVM Agent (Driver, Monitor, Sequencer) for GPIO
// =============================================================================
`ifndef GPIO_AGENT_SV
`define GPIO_AGENT_SV

class gpio_agent extends uvm_agent;
  `uvm_component_utils(gpio_agent)

  uvm_active_passive_enum is_active = UVM_ACTIVE;
  gpio_driver    drv;
  gpio_monitor   mon;
  gpio_sequencer seqr;
  uvm_analysis_port #(gpio_item) ap;

  function new(string name = "gpio_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon = gpio_monitor::type_id::create("mon", this);
    if (is_active == UVM_ACTIVE) begin
      drv  = gpio_driver::type_id::create("drv", this);
      seqr = gpio_sequencer::type_id::create("seqr", this);
    end
  endfunction : build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    ap = mon.ap;
    if (is_active == UVM_ACTIVE) begin
      drv.seq_item_port.connect(seqr.seq_item_export);
    end
  endfunction : connect_phase
endclass : gpio_agent

`endif // GPIO_AGENT_SV
