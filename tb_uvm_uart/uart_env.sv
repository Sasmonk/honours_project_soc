// =============================================================================
// Environment  : uart_env.sv
// Description  : UVM Environment for UART 16550 Verification (comms_ui_env)
// =============================================================================
`ifndef UART_ENV_SV
`define UART_ENV_SV

class uart_env extends uvm_env;
  `uvm_component_utils(uart_env)

  axi_agent         axi_agnt;
  uart_serial_agent serial_agnt;
  uart_scoreboard   sb;
  uart_coverage     cov;

  function new(string name = "uart_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    axi_agnt    = axi_agent::type_id::create("axi_agnt", this);
    serial_agnt = uart_serial_agent::type_id::create("serial_agnt", this);
    sb          = uart_scoreboard::type_id::create("sb", this);
    cov         = uart_coverage::type_id::create("cov", this);
  endfunction : build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // Connect AXI Agent to Scoreboard and Coverage
    axi_agnt.ap.connect(sb.axi_export);
    axi_agnt.ap.connect(cov.axi_export);

    // Connect Serial Monitor to Scoreboard and Coverage
    serial_agnt.ap.connect(sb.serial_tx_export);
    serial_agnt.ap.connect(cov.serial_export);

    // Connect Serial Driver to Scoreboard (for RX expected payload)
    serial_agnt.rx_drv_ap.connect(sb.serial_rx_export);

    // Connect IRQ line to Scoreboard
    serial_agnt.irq_ap.connect(sb.irq_export);
  endfunction : connect_phase

endclass : uart_env

`endif // UART_ENV_SV
