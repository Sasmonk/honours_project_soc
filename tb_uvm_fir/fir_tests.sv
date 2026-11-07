// =============================================================================
// Tests        : fir_tests.sv
// Description  : UVM Test library for 16-Tap FIR Digital Filter Verification
// =============================================================================
`ifndef FIR_TESTS_SV
`define FIR_TESTS_SV

class fir_base_test extends uvm_test;
  `uvm_component_utils(fir_base_test)

  fir_env env;
  virtual fir_sample_if vif;

  function new(string name = "fir_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = fir_env::type_id::create("env", this);
    if (!uvm_config_db#(virtual fir_sample_if)::get(this, "", "fir_vif", vif)) begin
      `uvm_fatal("NOVIF", "virtual fir_sample_if not found in config_db")
    end
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction

endclass : fir_base_test

// -----------------------------------------------------------------------------
// TC_FIR_01: Impulse Response Matching Q1.15
// -----------------------------------------------------------------------------
class tc_fir_01_test extends fir_base_test;
  `uvm_component_utils(tc_fir_01_test)

  function new(string name = "tc_fir_01_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    tc_fir_01_impulse_response_seq seq = tc_fir_01_impulse_response_seq::type_id::create("seq");
    seq.sample_seqr = env.sample_agt.seqr;
    phase.raise_objection(this);
    #200;
    seq.start(env.axi_agt.seqr);
    #500;
    phase.drop_objection(this);
  endtask
endclass : tc_fir_01_test

// -----------------------------------------------------------------------------
// TC_FIR_02: Hardware Bypass vs Active Mode
// -----------------------------------------------------------------------------
class tc_fir_02_test extends fir_base_test;
  `uvm_component_utils(tc_fir_02_test)

  function new(string name = "tc_fir_02_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    tc_fir_02_bypass_mode_seq seq = tc_fir_02_bypass_mode_seq::type_id::create("seq");
    seq.sample_seqr = env.sample_agt.seqr;
    phase.raise_objection(this);
    #200;
    seq.start(env.axi_agt.seqr);
    #500;
    phase.drop_objection(this);
  endtask
endclass : tc_fir_02_test

// -----------------------------------------------------------------------------
// TC_FIR_03: Runtime Tap Scaling
// -----------------------------------------------------------------------------
class tc_fir_03_test extends fir_base_test;
  `uvm_component_utils(tc_fir_03_test)

  function new(string name = "tc_fir_03_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    tc_fir_03_tap_scaling_seq seq = tc_fir_03_tap_scaling_seq::type_id::create("seq");
    seq.sample_seqr = env.sample_agt.seqr;
    phase.raise_objection(this);
    #200;
    seq.start(env.axi_agt.seqr);
    #500;
    phase.drop_objection(this);
  endtask
endclass : tc_fir_03_test

// -----------------------------------------------------------------------------
// TC_FIR_04: Accumulator Overflow & Saturation Clamping
// -----------------------------------------------------------------------------
class tc_fir_04_test extends fir_base_test;
  `uvm_component_utils(tc_fir_04_test)

  function new(string name = "tc_fir_04_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    tc_fir_04_saturation_clamping_seq seq = tc_fir_04_saturation_clamping_seq::type_id::create("seq");
    seq.sample_seqr = env.sample_agt.seqr;
    phase.raise_objection(this);
    #200;
    seq.start(env.axi_agt.seqr);
    #500;
    phase.drop_objection(this);
  endtask
endclass : tc_fir_04_test

// -----------------------------------------------------------------------------
// TC_FIR_05: Low-Pass Noise Attenuation
// -----------------------------------------------------------------------------
class tc_fir_05_test extends fir_base_test;
  `uvm_component_utils(tc_fir_05_test)

  function new(string name = "tc_fir_05_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    tc_fir_05_noise_filtering_seq seq = tc_fir_05_noise_filtering_seq::type_id::create("seq");
    seq.sample_seqr = env.sample_agt.seqr;
    phase.raise_objection(this);
    #200;
    seq.start(env.axi_agt.seqr);
    #500;
    phase.drop_objection(this);
  endtask
endclass : tc_fir_05_test

// -----------------------------------------------------------------------------
// TC_FIR_06: Memory-Mapped Direct Sample Injection
// -----------------------------------------------------------------------------
class tc_fir_06_test extends fir_base_test;
  `uvm_component_utils(tc_fir_06_test)

  function new(string name = "tc_fir_06_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    tc_fir_06_mm_sample_seq seq = tc_fir_06_mm_sample_seq::type_id::create("seq");
    seq.sample_seqr = env.sample_agt.seqr;
    phase.raise_objection(this);
    #200;
    seq.start(env.axi_agt.seqr);
    #500;
    phase.drop_objection(this);
  endtask
endclass : tc_fir_06_test

// -----------------------------------------------------------------------------
// All Features Composite Test
// -----------------------------------------------------------------------------
class fir_all_features_test extends fir_base_test;
  `uvm_component_utils(fir_all_features_test)

  function new(string name = "fir_all_features_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    fir_all_features_seq seq = fir_all_features_seq::type_id::create("seq");
    seq.sample_seqr = env.sample_agt.seqr;
    phase.raise_objection(this);
    #200;
    seq.start(env.axi_agt.seqr);
    #500;
    phase.drop_objection(this);
  endtask
endclass : fir_all_features_test

`endif // FIR_TESTS_SV
