// =============================================================================
// Tests        : watchdog_tests.sv
// Description  : Test classes for Watchdog Safety Monitor (TC_WDT_01)
// =============================================================================
`ifndef WATCHDOG_TESTS_SV
`define WATCHDOG_TESTS_SV

class watchdog_base_test extends uvm_test;
  `uvm_component_utils(watchdog_base_test)

  watchdog_env env;

  function new(string name = "watchdog_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = watchdog_env::type_id::create("env", this);
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction

endclass : watchdog_base_test

// -----------------------------------------------------------------------------
// TC_WDT_01 Dedicated Test
// -----------------------------------------------------------------------------
class tc_wdt_01_test extends watchdog_base_test;
  `uvm_component_utils(tc_wdt_01_test)

  function new(string name = "tc_wdt_01_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    wdt_safety_trip_seq seq = wdt_safety_trip_seq::type_id::create("seq");
    phase.raise_objection(this);

    `uvm_info("TEST", "=========================================================", UVM_LOW)
    `uvm_info("TEST", "    RUNNING TC_WDT_01: WATCHDOG KEEP-ALIVE & RESET TRIP  ", UVM_LOW)
    `uvm_info("TEST", "=========================================================", UVM_LOW)

    #200; // Wait for reset release
    seq.start(env.axi_agt.seqr);

    #500;
    phase.drop_objection(this);
  endtask

endclass : tc_wdt_01_test

// -----------------------------------------------------------------------------
// All Features Test
// -----------------------------------------------------------------------------
class watchdog_all_features_test extends watchdog_base_test;
  `uvm_component_utils(watchdog_all_features_test)

  function new(string name = "watchdog_all_features_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    wdt_safety_trip_seq seq = wdt_safety_trip_seq::type_id::create("seq");
    phase.raise_objection(this);

    `uvm_info("TEST", "=========================================================", UVM_LOW)
    `uvm_info("TEST", "    RUNNING ALL WATCHDOG IP VERIFICATION FEATURES        ", UVM_LOW)
    `uvm_info("TEST", "=========================================================", UVM_LOW)

    #200; // Wait for reset release
    seq.start(env.axi_agt.seqr);

    #500;
    phase.drop_objection(this);
  endtask

endclass : watchdog_all_features_test

`endif // WATCHDOG_TESTS_SV
