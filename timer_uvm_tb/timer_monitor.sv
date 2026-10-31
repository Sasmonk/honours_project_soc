// =============================================================================
// Monitor    : timer_monitor.sv
// Description: Passive Protocol Monitor & Analysis Broadcaster for TIMER
// =============================================================================
`ifndef TIMER_MONITOR_SV
`define TIMER_MONITOR_SV

class timer_monitor extends uvm_monitor;
  `uvm_component_utils(timer_monitor)

  virtual timer_if vif;
  uvm_analysis_port #(timer_item) ap;

  function new(string name = "timer_monitor", uvm_component parent = null);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual timer_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("TIMER_MON", "Virtual interface timer_if not set in config_db!")
    end
  endfunction : build_phase

  virtual task run_phase(uvm_phase phase);
    forever begin
      @(vif.monitor_cb);
      begin
        timer_item item = timer_item::type_id::create("mon_item");
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
        item.sample_tick = vif.monitor_cb.sample_tick;
        item.irq_timer = vif.monitor_cb.irq_timer;
        ap.write(item);
      end
    end
  endtask : run_phase
endclass : timer_monitor

`endif // TIMER_MONITOR_SV
