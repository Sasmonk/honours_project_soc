// =============================================================================
// Tests        : spi_tests.sv
// Description  : UVM Test library for SPI Master Verification
// =============================================================================
`ifndef SPI_TESTS_SV
`define SPI_TESTS_SV

class spi_base_test extends uvm_test;
  `uvm_component_utils(spi_base_test)

  spi_env env;
  virtual spi_adc_if vif;

  function new(string name = "spi_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = spi_env::type_id::create("env", this);
    if (!uvm_config_db#(virtual spi_adc_if)::get(this, "", "spi_vif", vif)) begin
      `uvm_fatal("NOVIF", "virtual spi_adc_if not found in config_db")
    end
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction

endclass : spi_base_test

// -----------------------------------------------------------------------------
// TC_ACQ_02 Test: Autonomous SPI Hardware Auto-Trigger
// -----------------------------------------------------------------------------
class tc_acq_02_test extends spi_base_test;
  `uvm_component_utils(tc_acq_02_test)

  function new(string name = "tc_acq_02_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    tc_acq_02_auto_trigger_seq seq = tc_acq_02_auto_trigger_seq::type_id::create("seq");
    seq.vif = vif;
    phase.raise_objection(this);
    #200;
    seq.start(env.axi_agt.seqr);
    #500;
    phase.drop_objection(this);
  endtask
endclass : tc_acq_02_test

// -----------------------------------------------------------------------------
// TC_ACQ_03 Test: Prescaler Sweep
// -----------------------------------------------------------------------------
class tc_acq_03_test extends spi_base_test;
  `uvm_component_utils(tc_acq_03_test)

  function new(string name = "tc_acq_03_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    tc_acq_03_prescaler_sweep_seq seq = tc_acq_03_prescaler_sweep_seq::type_id::create("seq");
    seq.vif = vif;
    phase.raise_objection(this);
    #200;
    seq.start(env.axi_agt.seqr);
    #500;
    phase.drop_objection(this);
  endtask
endclass : tc_acq_03_test

// -----------------------------------------------------------------------------
// TC_ACQ_04 Test: FIFO Overflow
// -----------------------------------------------------------------------------
class tc_acq_04_test extends spi_base_test;
  `uvm_component_utils(tc_acq_04_test)

  function new(string name = "tc_acq_04_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    tc_acq_04_fifo_overflow_seq seq = tc_acq_04_fifo_overflow_seq::type_id::create("seq");
    seq.vif = vif;
    phase.raise_objection(this);
    #200;
    seq.start(env.axi_agt.seqr);
    #500;
    phase.drop_objection(this);
  endtask
endclass : tc_acq_04_test

// -----------------------------------------------------------------------------
// TC_ACQ_05 Test: Manual SPI Command Transmission
// -----------------------------------------------------------------------------
class tc_acq_05_test extends spi_base_test;
  `uvm_component_utils(tc_acq_05_test)

  function new(string name = "tc_acq_05_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    tc_acq_05_manual_command_seq seq = tc_acq_05_manual_command_seq::type_id::create("seq");
    seq.vif = vif;
    phase.raise_objection(this);
    #200;
    seq.start(env.axi_agt.seqr);
    #500;
    phase.drop_objection(this);
  endtask
endclass : tc_acq_05_test

// -----------------------------------------------------------------------------
// TC_ACQ_06 Test: Timing Margins
// -----------------------------------------------------------------------------
class tc_acq_06_test extends spi_base_test;
  `uvm_component_utils(tc_acq_06_test)

  function new(string name = "tc_acq_06_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    tc_acq_06_timing_margins_seq seq = tc_acq_06_timing_margins_seq::type_id::create("seq");
    seq.vif = vif;
    phase.raise_objection(this);
    #200;
    seq.start(env.axi_agt.seqr);
    #500;
    phase.drop_objection(this);
  endtask
endclass : tc_acq_06_test

// -----------------------------------------------------------------------------
// All Features Composite Test
// -----------------------------------------------------------------------------
class spi_all_features_test extends spi_base_test;
  `uvm_component_utils(spi_all_features_test)

  function new(string name = "spi_all_features_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    spi_all_features_seq seq = spi_all_features_seq::type_id::create("seq");
    seq.vif = vif;
    phase.raise_objection(this);
    #200;
    seq.start(env.axi_agt.seqr);
    #500;
    phase.drop_objection(this);
  endtask
endclass : spi_all_features_test

`endif // SPI_TESTS_SV
