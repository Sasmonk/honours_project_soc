// =============================================================================
// Tests        : dma_tests.sv
// Description  : UVM Tests verifying DMA Controller (TC_DMA_01..07)
// =============================================================================
`ifndef DMA_TESTS_SV
`define DMA_TESTS_SV

// -----------------------------------------------------------------------------
// Base DMA Test
// -----------------------------------------------------------------------------
class dma_base_test extends uvm_test;
  `uvm_component_utils(dma_base_test)

  dma_env env;

  function new(string name = "dma_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = dma_env::type_id::create("env", this);
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction
endclass : dma_base_test

// -----------------------------------------------------------------------------
// Test: TC_DMA_01
// -----------------------------------------------------------------------------
class tc_dma_01_test extends dma_base_test;
  `uvm_component_utils(tc_dma_01_test)

  function new(string name = "tc_dma_01_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    tc_dma_01_streaming_pipeline_seq seq;
    phase.raise_objection(this);
    seq = tc_dma_01_streaming_pipeline_seq::type_id::create("seq");
    seq.dma_agt_h = env.dma_agt;
    seq.start(env.axi_agt.seqr);
    #1000;
    phase.drop_objection(this);
  endtask
endclass : tc_dma_01_test

// -----------------------------------------------------------------------------
// Test: TC_DMA_02
// -----------------------------------------------------------------------------
class tc_dma_02_test extends dma_base_test;
  `uvm_component_utils(tc_dma_02_test)

  function new(string name = "tc_dma_02_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    tc_dma_02_axi_master_block_move_seq seq;
    phase.raise_objection(this);
    seq = tc_dma_02_axi_master_block_move_seq::type_id::create("seq");
    seq.dma_agt_h = env.dma_agt;
    seq.start(env.axi_agt.seqr);
    #1000;
    phase.drop_objection(this);
  endtask
endclass : tc_dma_02_test

// -----------------------------------------------------------------------------
// Test: TC_DMA_03
// -----------------------------------------------------------------------------
class tc_dma_03_test extends dma_base_test;
  `uvm_component_utils(tc_dma_03_test)

  function new(string name = "tc_dma_03_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    tc_dma_03_rate_paced_vs_freerun_seq seq;
    phase.raise_objection(this);
    seq = tc_dma_03_rate_paced_vs_freerun_seq::type_id::create("seq");
    seq.dma_agt_h = env.dma_agt;
    seq.start(env.axi_agt.seqr);
    #1000;
    phase.drop_objection(this);
  endtask
endclass : tc_dma_03_test

// -----------------------------------------------------------------------------
// Test: TC_DMA_04
// -----------------------------------------------------------------------------
class tc_dma_04_test extends dma_base_test;
  `uvm_component_utils(tc_dma_04_test)

  function new(string name = "tc_dma_04_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    tc_dma_04_auto_reload_ring_buf_seq seq;
    phase.raise_objection(this);
    seq = tc_dma_04_auto_reload_ring_buf_seq::type_id::create("seq");
    seq.dma_agt_h = env.dma_agt;
    seq.start(env.axi_agt.seqr);
    #1000;
    phase.drop_objection(this);
  endtask
endclass : tc_dma_04_test

// -----------------------------------------------------------------------------
// Test: TC_DMA_05
// -----------------------------------------------------------------------------
class tc_dma_05_test extends dma_base_test;
  `uvm_component_utils(tc_dma_05_test)

  function new(string name = "tc_dma_05_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    tc_dma_05_timeout_abort_seq seq;
    phase.raise_objection(this);
    seq = tc_dma_05_timeout_abort_seq::type_id::create("seq");
    seq.dma_agt_h = env.dma_agt;
    seq.start(env.axi_agt.seqr);
    #1000;
    phase.drop_objection(this);
  endtask
endclass : tc_dma_05_test

// -----------------------------------------------------------------------------
// Test: TC_DMA_06
// -----------------------------------------------------------------------------
class tc_dma_06_test extends dma_base_test;
  `uvm_component_utils(tc_dma_06_test)

  function new(string name = "tc_dma_06_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    tc_dma_06_error_recovery_seq seq;
    phase.raise_objection(this);
    seq = tc_dma_06_error_recovery_seq::type_id::create("seq");
    seq.dma_agt_h = env.dma_agt;
    seq.start(env.axi_agt.seqr);
    #1000;
    phase.drop_objection(this);
  endtask
endclass : tc_dma_06_test

// -----------------------------------------------------------------------------
// Test: TC_DMA_07
// -----------------------------------------------------------------------------
class tc_dma_07_test extends dma_base_test;
  `uvm_component_utils(tc_dma_07_test)

  function new(string name = "tc_dma_07_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    tc_dma_07_fixed_vs_inc_addr_seq seq;
    phase.raise_objection(this);
    seq = tc_dma_07_fixed_vs_inc_addr_seq::type_id::create("seq");
    seq.dma_agt_h = env.dma_agt;
    seq.start(env.axi_agt.seqr);
    #1000;
    phase.drop_objection(this);
  endtask
endclass : tc_dma_07_test

// -----------------------------------------------------------------------------
// Composite Test: All DMA Features
// -----------------------------------------------------------------------------
class dma_all_features_test extends dma_base_test;
  `uvm_component_utils(dma_all_features_test)

  function new(string name = "dma_all_features_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    dma_all_features_seq seq;
    phase.raise_objection(this);
    seq = dma_all_features_seq::type_id::create("seq");
    seq.dma_agt_h = env.dma_agt;
    seq.start(env.axi_agt.seqr);
    #2000;
    phase.drop_objection(this);
  endtask
endclass : dma_all_features_test

`endif // DMA_TESTS_SV
