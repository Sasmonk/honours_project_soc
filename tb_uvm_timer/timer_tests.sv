// =============================================================================
// Tests        : timer_tests.sv
// Description  : Test classes for System Timer Verification (TC_ACQ_01)
// =============================================================================
`ifndef TIMER_TESTS_SV
`define TIMER_TESTS_SV

// -----------------------------------------------------------------------------
// Base Timer Test
// -----------------------------------------------------------------------------
class timer_base_test extends uvm_test;
  `uvm_component_utils(timer_base_test)

  timer_env env;

  function new(string name = "timer_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = timer_env::type_id::create("env", this);
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction

endclass : timer_base_test

// -----------------------------------------------------------------------------
// TC_ACQ_01 Dedicated Test
// -----------------------------------------------------------------------------
class tc_acq_01_test extends timer_base_test;
  `uvm_component_utils(tc_acq_01_test)

  function new(string name = "tc_acq_01_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    timer_pacing_precision_seq seq = timer_pacing_precision_seq::type_id::create("seq");
    phase.raise_objection(this);

    `uvm_info("TEST", "=========================================================", UVM_LOW)
    `uvm_info("TEST", "   RUNNING TC_ACQ_01: CYCLE-ACCURATE SAMPLE RATE PACING  ", UVM_LOW)
    `uvm_info("TEST", "=========================================================", UVM_LOW)

    #200; // Wait for reset release
    seq.start(env.axi_agt.seqr);

    #500;
    phase.drop_objection(this);
  endtask

endclass : tc_acq_01_test

// -----------------------------------------------------------------------------
// All Features Test
// -----------------------------------------------------------------------------
class timer_all_features_test extends timer_base_test;
  `uvm_component_utils(timer_all_features_test)

  function new(string name = "timer_all_features_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    timer_pacing_precision_seq seq = timer_pacing_precision_seq::type_id::create("seq");
    phase.raise_objection(this);

    `uvm_info("TEST", "=========================================================", UVM_LOW)
    `uvm_info("TEST", "   RUNNING ALL TIMER IP VERIFICATION FEATURES            ", UVM_LOW)
    `uvm_info("TEST", "=========================================================", UVM_LOW)

    #200; // Wait for reset release
    seq.start(env.axi_agt.seqr);

    #500;
    phase.drop_objection(this);
  endtask

endclass : timer_all_features_test

`endif // TIMER_TESTS_SV
