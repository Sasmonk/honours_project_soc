// =============================================================================
// Driver      : vga_driver.sv
// Description : Protocol-Accurate Master Driver for VGA
// =============================================================================
`ifndef VGA_DRIVER_SV
`define VGA_DRIVER_SV

class vga_driver extends uvm_driver #(vga_item);
  `uvm_component_utils(vga_driver)

  virtual vga_if vif;

  function new(string name = "vga_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual vga_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("VGA_DRV", "Virtual interface vga_if not set in config_db!")
    end
  endfunction : build_phase

  virtual task run_phase(uvm_phase phase);
    reset_signals();
    wait_for_reset();
    forever begin
      seq_item_port.get_next_item(req);
      drive_transfer(req);
      seq_item_port.item_done();
    end
  endtask : run_phase

  virtual task reset_signals();
    vif.master_cb.clk_vga <= '0;
    vif.master_cb.rst_vga_n <= '0;
    vif.master_cb.sbuf_rdata <= '0;
    vif.master_cb.s_axi_awaddr <= '0;
    vif.master_cb.s_axi_awvalid <= '0;
    vif.master_cb.s_axi_wdata <= '0;
    vif.master_cb.s_axi_wstrb <= '0;
    vif.master_cb.s_axi_wvalid <= '0;
    vif.master_cb.s_axi_bready <= '0;
    vif.master_cb.s_axi_araddr <= '0;
    vif.master_cb.s_axi_arvalid <= '0;
    vif.master_cb.s_axi_rready <= '0;
  endtask : reset_signals

  virtual task wait_for_reset();
    @(posedge vif.rst_sys_n);
    @(vif.master_cb);
  endtask : wait_for_reset

  virtual task drive_transfer(vga_item item);
    repeat (item.delay) @(vif.master_cb);
    vif.master_cb.clk_vga <= item.clk_vga;
    vif.master_cb.rst_vga_n <= item.rst_vga_n;
    vif.master_cb.sbuf_rdata <= item.sbuf_rdata;
    vif.master_cb.s_axi_awaddr <= item.s_axi_awaddr;
    vif.master_cb.s_axi_awvalid <= item.s_axi_awvalid;
    vif.master_cb.s_axi_wdata <= item.s_axi_wdata;
    vif.master_cb.s_axi_wstrb <= item.s_axi_wstrb;
    vif.master_cb.s_axi_wvalid <= item.s_axi_wvalid;
    vif.master_cb.s_axi_bready <= item.s_axi_bready;
    vif.master_cb.s_axi_araddr <= item.s_axi_araddr;
    vif.master_cb.s_axi_arvalid <= item.s_axi_arvalid;
    vif.master_cb.s_axi_rready <= item.s_axi_rready;
    @(vif.master_cb);
endclass : vga_driver

`endif // VGA_DRIVER_SV
