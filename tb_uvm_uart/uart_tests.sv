// =============================================================================
// Tests        : uart_tests.sv
// Description  : UVM Tests for UART 16550 Verification (TC_COM_01/02/03)
// =============================================================================
`ifndef UART_TESTS_SV
`define UART_TESTS_SV

// -----------------------------------------------------------------------------
// Base Test
// -----------------------------------------------------------------------------
class uart_base_test extends uvm_test;
  `uvm_component_utils(uart_base_test)

  uart_env env;

  function new(string name = "uart_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = uart_env::type_id::create("env", this);
  endfunction : build_phase

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction : end_of_elaboration_phase
endclass : uart_base_test

// -----------------------------------------------------------------------------
// TC_COM_01: 16550 UART 115200 Framing Test
// -----------------------------------------------------------------------------
class tc_com_01_test extends uart_base_test;
  `uvm_component_utils(tc_com_01_test)

  function new(string name = "tc_com_01_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual task run_phase(uvm_phase phase);
    uart_tx_frame_seq seq = uart_tx_frame_seq::type_id::create("seq");
    phase.raise_objection(this, "Starting TC_COM_01 Test");
    phase.phase_done.set_drain_time(this, 1000ns);
    seq.start(env.axi_agnt.seqr);
    phase.drop_objection(this, "Completed TC_COM_01 Test");
  endtask : run_phase
endclass : tc_com_01_test

// -----------------------------------------------------------------------------
// TC_COM_02: UART RX FIFO Watermark & IRQ Test
// -----------------------------------------------------------------------------
class tc_com_02_test extends uart_base_test;
  `uvm_component_utils(tc_com_02_test)

  function new(string name = "tc_com_02_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual task run_phase(uvm_phase phase);
    uart_serial_rx_inject_seq rx_seq = uart_serial_rx_inject_seq::type_id::create("rx_seq");
    uart_rx_irq_axi_seq       axi_seq = uart_rx_irq_axi_seq::type_id::create("axi_seq");

    phase.raise_objection(this, "Starting TC_COM_02 Test");
    phase.phase_done.set_drain_time(this, 1000ns);

    // Run parallel: serial driver pushes bytes while AXI reads them from FIFO
    fork
      rx_seq.start(env.serial_agnt.seqr);
      axi_seq.start(env.axi_agnt.seqr);
    join

    phase.drop_objection(this, "Completed TC_COM_02 Test");
  endtask : run_phase
endclass : tc_com_02_test

// -----------------------------------------------------------------------------
// Comprehensive All Features Test: TC_COM_01 + TC_COM_02 + TC_COM_03
// -----------------------------------------------------------------------------
class uart_all_features_test extends uart_base_test;
  `uvm_component_utils(uart_all_features_test)

  function new(string name = "uart_all_features_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual task run_phase(uvm_phase phase);
    uart_tx_frame_seq         tx_seq   = uart_tx_frame_seq::type_id::create("tx_seq");
    uart_serial_rx_inject_seq rx_seq   = uart_serial_rx_inject_seq::type_id::create("rx_seq");
    uart_rx_irq_axi_seq       axi_seq  = uart_rx_irq_axi_seq::type_id::create("axi_seq");
    uart_tx_empty_irq_seq     thre_seq = uart_tx_empty_irq_seq::type_id::create("thre_seq");

    phase.raise_objection(this, "Starting All UART Features Test Suite");
    phase.phase_done.set_drain_time(this, 2000ns);

    `uvm_info("UART_SUITE", "==========================================================", UVM_NONE)
    `uvm_info("UART_SUITE", " RUNNING TC_COM_01: 16550 UART TX FRAMING VERIFICATION     ", UVM_NONE)
    `uvm_info("UART_SUITE", "==========================================================", UVM_NONE)
    tx_seq.start(env.axi_agnt.seqr);

    `uvm_info("UART_SUITE", "==========================================================", UVM_NONE)
    `uvm_info("UART_SUITE", " RUNNING TC_COM_02: UART RX FIFO & IRQ VERIFICATION        ", UVM_NONE)
    `uvm_info("UART_SUITE", "==========================================================", UVM_NONE)
    fork
      rx_seq.start(env.serial_agnt.seqr);
      axi_seq.start(env.axi_agnt.seqr);
    join

    `uvm_info("UART_SUITE", "==========================================================", UVM_NONE)
    `uvm_info("UART_SUITE", " RUNNING TC_COM_03: THRE EMPTY IRQ VERIFICATION            ", UVM_NONE)
    `uvm_info("UART_SUITE", "==========================================================", UVM_NONE)
    thre_seq.start(env.axi_agnt.seqr);

    phase.drop_objection(this, "Completed All UART Features Test Suite");
  endtask : run_phase
endclass : uart_all_features_test

`endif // UART_TESTS_SV
