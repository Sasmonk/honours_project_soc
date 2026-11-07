// =============================================================================
// Tests        : vga_tests.sv
// Description  : UVM Test library for VGA Controller Verification
// =============================================================================
`ifndef VGA_TESTS_SV
`define VGA_TESTS_SV

class vga_base_test extends uvm_test;
  `uvm_component_utils(vga_base_test)

  vga_env env;

  function new(string name = "vga_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = vga_env::type_id::create("env", this);
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction

endclass : vga_base_test

// -----------------------------------------------------------------------------
// TC_VGA_01: 640x480 @ 60Hz Timing Compliance
// -----------------------------------------------------------------------------
class tc_vga_01_test extends vga_base_test;
  `uvm_component_utils(tc_vga_01_test)

  function new(string name = "tc_vga_01_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    tc_vga_01_vesa_timing_seq seq = tc_vga_01_vesa_timing_seq::type_id::create("seq");
    phase.raise_objection(this);
    #200;
    seq.start(env.axi_agt.seqr);
    #500;
    phase.drop_objection(this);
  endtask
endclass : tc_vga_01_test

// -----------------------------------------------------------------------------
// TC_VGA_02: Rising / Falling Trigger Edge Comparator
// -----------------------------------------------------------------------------
class tc_vga_02_test extends vga_base_test;
  `uvm_component_utils(tc_vga_02_test)

  function new(string name = "tc_vga_02_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    tc_vga_02_trigger_seq seq = tc_vga_02_trigger_seq::type_id::create("seq");
    phase.raise_objection(this);
    #200;
    seq.start(env.axi_agt.seqr);
    #500;
    phase.drop_objection(this);
  endtask
endclass : tc_vga_02_test

// -----------------------------------------------------------------------------
// TC_VGA_03: Holdoff Timeout & Free-Run Fallback
// -----------------------------------------------------------------------------
class tc_vga_03_test extends vga_base_test;
  `uvm_component_utils(tc_vga_03_test)

  function new(string name = "tc_vga_03_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    tc_vga_03_holdoff_seq seq = tc_vga_03_holdoff_seq::type_id::create("seq");
    phase.raise_objection(this);
    #200;
    seq.start(env.axi_agt.seqr);
    #500;
    phase.drop_objection(this);
  endtask
endclass : tc_vga_03_test

// -----------------------------------------------------------------------------
// TC_VGA_04: Volts/Div (VDIV) & Time/Div (TDIV) Scaling Sweep
// -----------------------------------------------------------------------------
class tc_vga_04_test extends vga_base_test;
  `uvm_component_utils(tc_vga_04_test)

  function new(string name = "tc_vga_04_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    tc_vga_04_scaling_sweep_seq seq = tc_vga_04_scaling_sweep_seq::type_id::create("seq");
    phase.raise_objection(this);
    #200;
    seq.start(env.axi_agt.seqr);
    #500;
    phase.drop_objection(this);
  endtask
endclass : tc_vga_04_test

// -----------------------------------------------------------------------------
// TC_VGA_05: Software UI Color Customization
// -----------------------------------------------------------------------------
class tc_vga_05_test extends vga_base_test;
  `uvm_component_utils(tc_vga_05_test)

  function new(string name = "tc_vga_05_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    tc_vga_05_color_palette_seq seq = tc_vga_05_color_palette_seq::type_id::create("seq");
    phase.raise_objection(this);
    #200;
    seq.start(env.axi_agt.seqr);
    #500;
    phase.drop_objection(this);
  endtask
endclass : tc_vga_05_test

// -----------------------------------------------------------------------------
// TC_VGA_06: Voltage Cursors A & B Overlay
// -----------------------------------------------------------------------------
class tc_vga_06_test extends vga_base_test;
  `uvm_component_utils(tc_vga_06_test)

  function new(string name = "tc_vga_06_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    tc_vga_06_cursors_overlay_seq seq = tc_vga_06_cursors_overlay_seq::type_id::create("seq");
    phase.raise_objection(this);
    #200;
    seq.start(env.axi_agt.seqr);
    #500;
    phase.drop_objection(this);
  endtask
endclass : tc_vga_06_test

// -----------------------------------------------------------------------------
// All Features Composite Test
// -----------------------------------------------------------------------------
class vga_all_features_test extends vga_base_test;
  `uvm_component_utils(vga_all_features_test)

  function new(string name = "vga_all_features_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    vga_all_features_seq seq = vga_all_features_seq::type_id::create("seq");
    phase.raise_objection(this);
    #200;
    seq.start(env.axi_agt.seqr);
    #500;
    phase.drop_objection(this);
  endtask
endclass : vga_all_features_test

`endif // VGA_TESTS_SV
