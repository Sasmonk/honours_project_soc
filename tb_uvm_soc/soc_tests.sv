// =============================================================================
// File        : soc_tests.sv
// Description : Top-Level SoC UVM Test Suite
// =============================================================================
`ifndef SOC_TESTS_SV
`define SOC_TESTS_SV

// -----------------------------------------------------------------------------
// Base SoC Test
// -----------------------------------------------------------------------------
class soc_base_test extends uvm_test;
  `uvm_component_utils(soc_base_test)

  soc_env        env;
  soc_env_config m_cfg;

  function new(string name = "soc_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m_cfg = soc_env_config::type_id::create("m_cfg");
    configure_env();
    uvm_config_db#(soc_env_config)::set(this, "env*", "cfg", m_cfg);
    env = soc_env::type_id::create("env", this);
  endfunction : build_phase

  virtual function void configure_env();
    // Default: all agents active and enabled
    m_cfg.has_uart_agent  = 1'b1;
    m_cfg.has_spi_agent   = 1'b1;
    m_cfg.has_gpio_agent  = 1'b1;
    m_cfg.has_vga_agent   = 1'b1;
    m_cfg.has_timer_agent = 1'b1;
    m_cfg.has_wdt_agent   = 1'b1;
    m_cfg.has_scoreboard  = 1'b1;
  endfunction : configure_env

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    `uvm_info("SOC_TOPOLOGY", "Displaying UVM Component Topology for SoC Verification:", UVM_LOW)
    uvm_top.print_topology();
  endfunction : end_of_elaboration_phase

  virtual task run_phase(uvm_phase phase);
    phase.phase_done.set_drain_time(this, 10us);
  endtask : run_phase

endclass : soc_base_test


// -----------------------------------------------------------------------------
// Test 1: C Firmware Hello World and UART Live Capture Test
// -----------------------------------------------------------------------------
class soc_hello_test extends soc_base_test;
  `uvm_component_utils(soc_hello_test)

  function new(string name = "soc_hello_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual task run_phase(uvm_phase phase);
    soc_firmware_boot_vseq vseq;
    super.run_phase(phase);
    phase.raise_objection(this, "Starting soc_hello_test");

    vseq = soc_firmware_boot_vseq::type_id::create("vseq");
    vseq.start(env.vseqr);

    phase.drop_objection(this, "Finished soc_hello_test");
  endtask : run_phase

endclass : soc_hello_test


// -----------------------------------------------------------------------------
// Test 2: Interactive UI Test (GPIO Pushbuttons & Scale Modulation)
// -----------------------------------------------------------------------------
class soc_interactive_ui_test extends soc_base_test;
  `uvm_component_utils(soc_interactive_ui_test)

  function new(string name = "soc_interactive_ui_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual task run_phase(uvm_phase phase);
    soc_interactive_ui_vseq vseq;
    super.run_phase(phase);
    phase.raise_objection(this, "Starting soc_interactive_ui_test");

    vseq = soc_interactive_ui_vseq::type_id::create("vseq");
    vseq.start(env.vseqr);

    phase.drop_objection(this, "Finished soc_interactive_ui_test");
  endtask : run_phase

endclass : soc_interactive_ui_test


// -----------------------------------------------------------------------------
// Test 3: Complete Closed-Loop All Features Multi-Peripheral Stress Test
// -----------------------------------------------------------------------------
class soc_all_features_test extends soc_base_test;
  `uvm_component_utils(soc_all_features_test)

  function new(string name = "soc_all_features_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual task run_phase(uvm_phase phase);
    soc_all_features_vseq vseq;
    super.run_phase(phase);
    phase.raise_objection(this, "Starting soc_all_features_test");

    vseq = soc_all_features_vseq::type_id::create("vseq");
    vseq.start(env.vseqr);

    phase.drop_objection(this, "Finished soc_all_features_test");
  endtask : run_phase

endclass : soc_all_features_test

`endif // SOC_TESTS_SV
