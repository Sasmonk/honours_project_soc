// =============================================================================
// Environment  : vga_env.sv
// Description  : UVM Environment for VGA Controller Subsystem
// =============================================================================
`ifndef VGA_ENV_SV
`define VGA_ENV_SV

class vga_env extends uvm_env;
  `uvm_component_utils(vga_env)

  axi_agent      axi_agt;
  vga_agent      vga_agt;
  vga_scoreboard sb;
  vga_coverage   cov;

  function new(string name = "vga_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    axi_agt = axi_agent::type_id::create("axi_agt", this);
    vga_agt = vga_agent::type_id::create("vga_agt", this);
    sb      = vga_scoreboard::type_id::create("sb", this);
    cov     = vga_coverage::type_id::create("cov", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    axi_agt.ap.connect(sb.axi_export);
    axi_agt.ap.connect(cov.axi_cov_export);

    vga_agt.mon.ap.connect(sb.pixel_export);
    vga_agt.mon.ap.connect(cov.analysis_export);
    vga_agt.mon.frame_ap.connect(sb.frame_export);
  endfunction

endclass : vga_env

`endif // VGA_ENV_SV
