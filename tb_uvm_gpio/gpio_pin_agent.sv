// =============================================================================
// Agent       : gpio_pin_agent.sv
// Description : Physical Boundary Agent for GPIO Push-Buttons & LEDs
// =============================================================================
`ifndef GPIO_PIN_AGENT_SV
`define GPIO_PIN_AGENT_SV

typedef uvm_sequencer #(gpio_pin_item) gpio_pin_sequencer;

class gpio_pin_agent extends uvm_agent;
  `uvm_component_utils(gpio_pin_agent)

  uvm_active_passive_enum is_active = UVM_ACTIVE;
  gpio_pin_driver    drv;
  gpio_pin_monitor   mon;
  gpio_pin_sequencer seqr;

  uvm_analysis_port #(gpio_pin_item) ap;
  uvm_analysis_port #(gpio_pin_item) drv_ap;
  uvm_analysis_port #(bit)           irq_ap;

  function new(string name = "gpio_pin_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon = gpio_pin_monitor::type_id::create("mon", this);
    if (is_active == UVM_ACTIVE) begin
      drv  = gpio_pin_driver::type_id::create("drv", this);
      seqr = gpio_pin_sequencer::type_id::create("seqr", this);
    end
  endfunction : build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    ap     = mon.ap;
    irq_ap = mon.irq_ap;
    if (is_active == UVM_ACTIVE) begin
      drv.seq_item_port.connect(seqr.seq_item_export);
      drv_ap = drv.ap;
    end
  endfunction : connect_phase

endclass : gpio_pin_agent

`endif // GPIO_PIN_AGENT_SV
