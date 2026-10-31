// =============================================================================
// Agent       : uart_serial_agent.sv
// Description : Physical Serial & Interrupt Agent for UART Verification IP
// =============================================================================
`ifndef UART_SERIAL_AGENT_SV
`define UART_SERIAL_AGENT_SV

class uart_serial_agent extends uvm_agent;
  `uvm_component_utils(uart_serial_agent)

  uvm_active_passive_enum is_active = UVM_ACTIVE;
  uart_serial_driver    drv;
  uart_serial_monitor   mon;
  uart_serial_sequencer seqr;

  uvm_analysis_port #(uart_serial_item) ap;
  uvm_analysis_port #(uart_serial_item) rx_drv_ap;
  uvm_analysis_port #(bit)              irq_ap;

  function new(string name = "uart_serial_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon = uart_serial_monitor::type_id::create("mon", this);
    if (is_active == UVM_ACTIVE) begin
      drv  = uart_serial_driver::type_id::create("drv", this);
      seqr = uart_serial_sequencer::type_id::create("seqr", this);
    end
  endfunction : build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    ap        = mon.ap;
    irq_ap    = mon.irq_ap;
    if (is_active == UVM_ACTIVE) begin
      drv.seq_item_port.connect(seqr.seq_item_export);
      rx_drv_ap = drv.ap;
    end
  endfunction : connect_phase

endclass : uart_serial_agent

`endif // UART_SERIAL_AGENT_SV
