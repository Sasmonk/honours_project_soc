// =============================================================================
// Agent        : vga_agent.sv
// Description  : UVM Agent containing VGA monitor and sample buffer driver
// =============================================================================
`ifndef VGA_AGENT_SV
`define VGA_AGENT_SV

class vga_agent extends uvm_agent;
  `uvm_component_utils(vga_agent)

  vga_sbuf_driver   drv;
  vga_pixel_monitor mon;

  function new(string name = "vga_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    drv = vga_sbuf_driver::type_id::create("drv", this);
    mon = vga_pixel_monitor::type_id::create("mon", this);
  endfunction

endclass : vga_agent

`endif // VGA_AGENT_SV
