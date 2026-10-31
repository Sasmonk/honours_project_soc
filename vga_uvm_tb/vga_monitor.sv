// =============================================================================
// Monitor    : vga_monitor.sv
// Description: Passive Protocol Monitor & Analysis Broadcaster for VGA
// =============================================================================
`ifndef VGA_MONITOR_SV
`define VGA_MONITOR_SV

class vga_monitor extends uvm_monitor;
  `uvm_component_utils(vga_monitor)

  virtual vga_if vif;
  uvm_analysis_port #(vga_item) ap;

  function new(string name = "vga_monitor", uvm_component parent = null);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual vga_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("VGA_MON", "Virtual interface vga_if not set in config_db!")
    end
  endfunction : build_phase

  virtual task run_phase(uvm_phase phase);
    forever begin
      @(vif.monitor_cb);
      begin
        vga_item item = vga_item::type_id::create("mon_item");
        item.clk_vga = vif.monitor_cb.clk_vga;
        item.rst_vga_n = vif.monitor_cb.rst_vga_n;
        item.sbuf_raddr = vif.monitor_cb.sbuf_raddr;
        item.sbuf_rdata = vif.monitor_cb.sbuf_rdata;
        item.vga_vsync_pulse = vif.monitor_cb.vga_vsync_pulse;
        item.vga_hsync = vif.monitor_cb.vga_hsync;
        item.vga_vsync = vif.monitor_cb.vga_vsync;
        item.vga_red = vif.monitor_cb.vga_red;
        item.vga_green = vif.monitor_cb.vga_green;
        item.vga_blue = vif.monitor_cb.vga_blue;
        item.irq_vga_frame = vif.monitor_cb.irq_vga_frame;
        item.s_axi_awaddr = vif.monitor_cb.s_axi_awaddr;
        item.s_axi_awvalid = vif.monitor_cb.s_axi_awvalid;
        item.s_axi_awready = vif.monitor_cb.s_axi_awready;
        item.s_axi_wdata = vif.monitor_cb.s_axi_wdata;
        item.s_axi_wstrb = vif.monitor_cb.s_axi_wstrb;
        item.s_axi_wvalid = vif.monitor_cb.s_axi_wvalid;
        item.s_axi_wready = vif.monitor_cb.s_axi_wready;
        item.s_axi_bresp = vif.monitor_cb.s_axi_bresp;
        item.s_axi_bvalid = vif.monitor_cb.s_axi_bvalid;
        item.s_axi_bready = vif.monitor_cb.s_axi_bready;
        item.s_axi_araddr = vif.monitor_cb.s_axi_araddr;
        item.s_axi_arvalid = vif.monitor_cb.s_axi_arvalid;
        item.s_axi_arready = vif.monitor_cb.s_axi_arready;
        item.s_axi_rdata = vif.monitor_cb.s_axi_rdata;
        item.s_axi_rresp = vif.monitor_cb.s_axi_rresp;
        item.s_axi_rvalid = vif.monitor_cb.s_axi_rvalid;
        item.s_axi_rready = vif.monitor_cb.s_axi_rready;
        ap.write(item);
      end
    end
  endtask : run_phase
endclass : vga_monitor

`endif // VGA_MONITOR_SV
