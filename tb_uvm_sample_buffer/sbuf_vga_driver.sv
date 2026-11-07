// =============================================================================
// Driver       : sbuf_vga_driver.sv
// Description  : UVM Driver generating VGA read addresses on clk_vga domain
// =============================================================================
`ifndef SBUF_VGA_DRIVER_SV
`define SBUF_VGA_DRIVER_SV

class sbuf_vga_driver extends uvm_driver #(sbuf_vga_item);
  `uvm_component_utils(sbuf_vga_driver)

  virtual sbuf_vga_if vif;

  function new(string name = "sbuf_vga_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual sbuf_vga_if)::get(this, "", "vga_vif", vif)) begin
      `uvm_fatal("NOVIF", "virtual sbuf_vga_if not found in config_db")
    end
  endfunction

  task run_phase(uvm_phase phase);
    vif.sbuf_raddr <= 12'd0;
    vif.sbuf_ren   <= 1'b0;

    @(posedge vif.rst_vga_n);

    forever begin
      seq_item_port.get_next_item(req);
      @(posedge vif.clk_vga);
      vif.sbuf_raddr <= req.addr;
      vif.sbuf_ren   <= 1'b1;
      @(posedge vif.clk_vga);
      vif.sbuf_ren   <= 1'b0;
      seq_item_port.item_done();
    end
  endtask

endclass : sbuf_vga_driver

`endif // SBUF_VGA_DRIVER_SV
