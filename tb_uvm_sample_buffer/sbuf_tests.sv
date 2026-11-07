// =============================================================================
// Tests        : sbuf_tests.sv
// Description  : UVM Test library for Sample Buffer Verification
// =============================================================================
`ifndef SBUF_TESTS_SV
`define SBUF_TESTS_SV

class sbuf_base_test extends uvm_test;
  `uvm_component_utils(sbuf_base_test)

  sbuf_env env;

  function new(string name = "sbuf_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = sbuf_env::type_id::create("env", this);
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction

endclass : sbuf_base_test

// -----------------------------------------------------------------------------
// TC_BUF_01: Tear-Free Rotation Synchronized to VSYNC
// -----------------------------------------------------------------------------
class tc_buf_01_test extends sbuf_base_test;
  `uvm_component_utils(tc_buf_01_test)

  function new(string name = "tc_buf_01_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    tc_buf_01_tear_free_seq seq = tc_buf_01_tear_free_seq::type_id::create("seq");
    seq.dma_seqr = env.dma_agt.seqr;
    seq.vga_seqr = env.vga_agt.seqr;
    phase.raise_objection(this);
    #200;
    seq.start(env.axi_agt.seqr);
    #500;
    phase.drop_objection(this);
  endtask
endclass : tc_buf_01_test

// -----------------------------------------------------------------------------
// TC_BUF_02: Write-Hold Freeze Mode
// -----------------------------------------------------------------------------
class tc_buf_02_test extends sbuf_base_test;
  `uvm_component_utils(tc_buf_02_test)

  function new(string name = "tc_buf_02_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    tc_buf_02_write_hold_seq seq = tc_buf_02_write_hold_seq::type_id::create("seq");
    seq.dma_seqr = env.dma_agt.seqr;
    seq.vga_seqr = env.vga_agt.seqr;
    phase.raise_objection(this);
    #200;
    seq.start(env.axi_agt.seqr);
    #500;
    phase.drop_objection(this);
  endtask
endclass : tc_buf_02_test

// -----------------------------------------------------------------------------
// TC_BUF_03: Concurrent 3-Port Access Stress
// -----------------------------------------------------------------------------
class tc_buf_03_test extends sbuf_base_test;
  `uvm_component_utils(tc_buf_03_test)

  function new(string name = "tc_buf_03_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    tc_buf_03_concurrent_access_seq seq = tc_buf_03_concurrent_access_seq::type_id::create("seq");
    seq.dma_seqr = env.dma_agt.seqr;
    seq.vga_seqr = env.vga_agt.seqr;
    phase.raise_objection(this);
    #200;
    seq.start(env.axi_agt.seqr);
    #500;
    phase.drop_objection(this);
  endtask
endclass : tc_buf_03_test

// -----------------------------------------------------------------------------
// TC_BUF_04: Manual Bank Swap Override
// -----------------------------------------------------------------------------
class tc_buf_04_test extends sbuf_base_test;
  `uvm_component_utils(tc_buf_04_test)

  function new(string name = "tc_buf_04_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    tc_buf_04_manual_swap_seq seq = tc_buf_04_manual_swap_seq::type_id::create("seq");
    seq.dma_seqr = env.dma_agt.seqr;
    seq.vga_seqr = env.vga_agt.seqr;
    phase.raise_objection(this);
    #200;
    seq.start(env.axi_agt.seqr);
    #500;
    phase.drop_objection(this);
  endtask
endclass : tc_buf_04_test

// -----------------------------------------------------------------------------
// TC_BUF_05: Asynchronous CDC SVA Verification
// -----------------------------------------------------------------------------
class tc_buf_05_test extends sbuf_base_test;
  `uvm_component_utils(tc_buf_05_test)

  function new(string name = "tc_buf_05_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    tc_buf_05_cdc_sync_seq seq = tc_buf_05_cdc_sync_seq::type_id::create("seq");
    seq.dma_seqr = env.dma_agt.seqr;
    seq.vga_seqr = env.vga_agt.seqr;
    phase.raise_objection(this);
    #200;
    seq.start(env.axi_agt.seqr);
    #500;
    phase.drop_objection(this);
  endtask
endclass : tc_buf_05_test

// -----------------------------------------------------------------------------
// All Features Composite Test
// -----------------------------------------------------------------------------
class sbuf_all_features_test extends sbuf_base_test;
  `uvm_component_utils(sbuf_all_features_test)

  function new(string name = "sbuf_all_features_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    sbuf_all_features_seq seq = sbuf_all_features_seq::type_id::create("seq");
    seq.dma_seqr = env.dma_agt.seqr;
    seq.vga_seqr = env.vga_agt.seqr;
    phase.raise_objection(this);
    #200;
    seq.start(env.axi_agt.seqr);
    #500;
    phase.drop_objection(this);
  endtask
endclass : sbuf_all_features_test

`endif // SBUF_TESTS_SV
