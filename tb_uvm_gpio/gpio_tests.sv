// =============================================================================
// Tests        : gpio_tests.sv
// Description  : UVM Tests for GPIO Verification (TC_COM_03/04)
// =============================================================================
`ifndef GPIO_TESTS_SV
`define GPIO_TESTS_SV

// -----------------------------------------------------------------------------
// Base Test
// -----------------------------------------------------------------------------
class gpio_base_test extends uvm_test;
  `uvm_component_utils(gpio_base_test)

  gpio_env env;

  function new(string name = "gpio_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = gpio_env::type_id::create("env", this);
  endfunction : build_phase

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction : end_of_elaboration_phase
endclass : gpio_base_test

// -----------------------------------------------------------------------------
// TC_COM_04 Test: Status LED Output Drive
// -----------------------------------------------------------------------------
class tc_com_04_test extends gpio_base_test;
  `uvm_component_utils(tc_com_04_test)

  function new(string name = "tc_com_04_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual task run_phase(uvm_phase phase);
    tc_com_04_led_drive_seq seq = tc_com_04_led_drive_seq::type_id::create("seq");
    phase.raise_objection(this, "Starting TC_COM_04 Test");
    phase.phase_done.set_drain_time(this, 500ns);
    seq.start(env.axi_agnt.seqr);
    phase.drop_objection(this, "Completed TC_COM_04 Test");
  endtask : run_phase
endclass : tc_com_04_test

// -----------------------------------------------------------------------------
// TC_COM_03 Test: Push-Button Sync & IRQ
// -----------------------------------------------------------------------------
class tc_com_03_test extends gpio_base_test;
  `uvm_component_utils(tc_com_03_test)

  function new(string name = "tc_com_03_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual task run_phase(uvm_phase phase);
    gpio_button_stimulus_seq pin_seq = gpio_button_stimulus_seq::type_id::create("pin_seq");
    tc_com_03_button_sync_seq axi_seq = tc_com_03_button_sync_seq::type_id::create("axi_seq");

    phase.raise_objection(this, "Starting TC_COM_03 Test");
    phase.phase_done.set_drain_time(this, 1000ns);

    fork
      pin_seq.start(env.pin_agnt.seqr);
      axi_seq.start(env.axi_agnt.seqr);
    join

    phase.drop_objection(this, "Completed TC_COM_03 Test");
  endtask : run_phase
endclass : tc_com_03_test

// -----------------------------------------------------------------------------
// Comprehensive All Features Test: TC_COM_04 + TC_COM_03
// -----------------------------------------------------------------------------
class gpio_all_features_test extends gpio_base_test;
  `uvm_component_utils(gpio_all_features_test)

  function new(string name = "gpio_all_features_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual task run_phase(uvm_phase phase);
    tc_com_04_led_drive_seq   led_seq = tc_com_04_led_drive_seq::type_id::create("led_seq");
    gpio_button_stimulus_seq pin_seq = gpio_button_stimulus_seq::type_id::create("pin_seq");
    tc_com_03_button_sync_seq axi_seq = tc_com_03_button_sync_seq::type_id::create("axi_seq");

    phase.raise_objection(this, "Starting All GPIO Features Test Suite");
    phase.phase_done.set_drain_time(this, 1000ns);

    `uvm_info("GPIO_SUITE", "==========================================================", UVM_NONE)
    `uvm_info("GPIO_SUITE", " RUNNING TC_COM_04: GPIO STATUS LED OUTPUT DRIVE          ", UVM_NONE)
    `uvm_info("GPIO_SUITE", "==========================================================", UVM_NONE)
    led_seq.start(env.axi_agnt.seqr);

    `uvm_info("GPIO_SUITE", "==========================================================", UVM_NONE)
    `uvm_info("GPIO_SUITE", " RUNNING TC_COM_03: GPIO PUSH-BUTTON SYNC & IRQ           ", UVM_NONE)
    `uvm_info("GPIO_SUITE", "==========================================================", UVM_NONE)
    fork
      pin_seq.start(env.pin_agnt.seqr);
      axi_seq.start(env.axi_agnt.seqr);
    join

    phase.drop_objection(this, "Completed All GPIO Features Test Suite");
  endtask : run_phase
endclass : gpio_all_features_test

`endif // GPIO_TESTS_SV
