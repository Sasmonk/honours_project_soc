// =============================================================================
// Monitor    : sample_buffer_monitor.sv
// Description: Passive Protocol Monitor & Analysis Broadcaster for SAMPLE_BUFFER
// =============================================================================
`ifndef SAMPLE_BUFFER_MONITOR_SV
`define SAMPLE_BUFFER_MONITOR_SV

class sample_buffer_monitor extends uvm_monitor;
  `uvm_component_utils(sample_buffer_monitor)

  virtual sample_buffer_if vif;
  uvm_analysis_port #(sample_buffer_item) ap;

  function new(string name = "sample_buffer_monitor", uvm_component parent = null);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual sample_buffer_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("SAMPLE_BUFFER_MON", "Virtual interface sample_buffer_if not set in config_db!")
    end
  endfunction : build_phase

  virtual task run_phase(uvm_phase phase);
    forever begin
      @(vif.monitor_cb);
      begin
        sample_buffer_item item = sample_buffer_item::type_id::create("mon_item");
        item.sbuf_waddr = vif.monitor_cb.sbuf_waddr;
        item.sbuf_wdata = vif.monitor_cb.sbuf_wdata;
        item.sbuf_we = vif.monitor_cb.sbuf_we;
        item.buf_swap_req = vif.monitor_cb.buf_swap_req;
        item.vga_vsync_pulse = vif.monitor_cb.vga_vsync_pulse;
        item.active_wr_buf = vif.monitor_cb.active_wr_buf;
        item.active_rd_buf = vif.monitor_cb.active_rd_buf;
        item.clk_vga = vif.monitor_cb.clk_vga;
        item.rst_vga_n = vif.monitor_cb.rst_vga_n;
        item.sbuf_raddr = vif.monitor_cb.sbuf_raddr;
        item.sbuf_rdata = vif.monitor_cb.sbuf_rdata;
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
endclass : sample_buffer_monitor

`endif // SAMPLE_BUFFER_MONITOR_SV
