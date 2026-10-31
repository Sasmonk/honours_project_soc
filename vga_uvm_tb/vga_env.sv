// =============================================================================
// Environment  : vga_env.sv
// Description  : Standard UVM Environment for VGA VIP
// =============================================================================
`ifndef VGA_ENV_SV
`define VGA_ENV_SV

class vga_env extends uvm_env;
  `uvm_component_utils(vga_env)

  vga_agent      agent;
  vga_scoreboard sb;

  function new(string name = "vga_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = vga_agent::type_id::create("agent", this);
    sb    = vga_scoreboard::type_id::create("sb", this);
  endfunction : build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent.ap.connect(sb.item_export);
  endfunction : connect_phase
endclass : vga_env

`endif // VGA_ENV_SV
