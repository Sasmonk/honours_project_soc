// =============================================================================
// Monitor    : dma_monitor.sv
// Description: Passive Protocol Monitor & Analysis Broadcaster for DMA
// =============================================================================
`ifndef DMA_MONITOR_SV
`define DMA_MONITOR_SV

class dma_monitor extends uvm_monitor;
  `uvm_component_utils(dma_monitor)

  virtual dma_if vif;
  uvm_analysis_port #(dma_item) ap;

  function new(string name = "dma_monitor", uvm_component parent = null);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual dma_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("DMA_MON", "Virtual interface dma_if not set in config_db!")
    end
  endfunction : build_phase

  virtual task run_phase(uvm_phase phase);
    forever begin
      @(vif.monitor_cb);
      begin
        dma_item item = dma_item::type_id::create("mon_item");
        item.sample_tick = vif.monitor_cb.sample_tick;
        item.spi_sample_ready = vif.monitor_cb.spi_sample_ready;
        item.spi_sample_data = vif.monitor_cb.spi_sample_data;
        item.fir_sample_in = vif.monitor_cb.fir_sample_in;
        item.fir_sample_valid_in = vif.monitor_cb.fir_sample_valid_in;
        item.fir_sample_out = vif.monitor_cb.fir_sample_out;
        item.fir_sample_valid_out = vif.monitor_cb.fir_sample_valid_out;
        item.sbuf_waddr = vif.monitor_cb.sbuf_waddr;
        item.sbuf_wdata = vif.monitor_cb.sbuf_wdata;
        item.sbuf_we = vif.monitor_cb.sbuf_we;
        item.buf_swap_req = vif.monitor_cb.buf_swap_req;
        item.m_axi_awid = vif.monitor_cb.m_axi_awid;
        item.m_axi_awaddr = vif.monitor_cb.m_axi_awaddr;
        item.m_axi_awlen = vif.monitor_cb.m_axi_awlen;
        item.m_axi_awsize = vif.monitor_cb.m_axi_awsize;
        item.m_axi_awburst = vif.monitor_cb.m_axi_awburst;
        item.m_axi_awlock = vif.monitor_cb.m_axi_awlock;
        item.m_axi_awcache = vif.monitor_cb.m_axi_awcache;
        item.m_axi_awprot = vif.monitor_cb.m_axi_awprot;
        item.m_axi_awqos = vif.monitor_cb.m_axi_awqos;
        item.m_axi_awvalid = vif.monitor_cb.m_axi_awvalid;
        item.m_axi_awready = vif.monitor_cb.m_axi_awready;
        item.m_axi_wdata = vif.monitor_cb.m_axi_wdata;
        item.m_axi_wstrb = vif.monitor_cb.m_axi_wstrb;
        item.m_axi_wlast = vif.monitor_cb.m_axi_wlast;
        item.m_axi_wvalid = vif.monitor_cb.m_axi_wvalid;
        item.m_axi_wready = vif.monitor_cb.m_axi_wready;
        item.m_axi_bid = vif.monitor_cb.m_axi_bid;
        item.m_axi_bresp = vif.monitor_cb.m_axi_bresp;
        item.m_axi_bvalid = vif.monitor_cb.m_axi_bvalid;
        item.m_axi_bready = vif.monitor_cb.m_axi_bready;
        item.m_axi_arid = vif.monitor_cb.m_axi_arid;
        item.m_axi_araddr = vif.monitor_cb.m_axi_araddr;
        item.m_axi_arlen = vif.monitor_cb.m_axi_arlen;
        item.m_axi_arsize = vif.monitor_cb.m_axi_arsize;
        item.m_axi_arburst = vif.monitor_cb.m_axi_arburst;
        item.m_axi_arlock = vif.monitor_cb.m_axi_arlock;
        item.m_axi_arcache = vif.monitor_cb.m_axi_arcache;
        item.m_axi_arprot = vif.monitor_cb.m_axi_arprot;
        item.m_axi_arqos = vif.monitor_cb.m_axi_arqos;
        item.m_axi_arvalid = vif.monitor_cb.m_axi_arvalid;
        item.m_axi_arready = vif.monitor_cb.m_axi_arready;
        item.m_axi_rid = vif.monitor_cb.m_axi_rid;
        item.m_axi_rdata = vif.monitor_cb.m_axi_rdata;
        item.m_axi_rresp = vif.monitor_cb.m_axi_rresp;
        item.m_axi_rlast = vif.monitor_cb.m_axi_rlast;
        item.m_axi_rvalid = vif.monitor_cb.m_axi_rvalid;
        item.m_axi_rready = vif.monitor_cb.m_axi_rready;
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
        item.irq_dma_done = vif.monitor_cb.irq_dma_done;
        item.irq_dma_err = vif.monitor_cb.irq_dma_err;
        ap.write(item);
      end
    end
  endtask : run_phase
endclass : dma_monitor

`endif // DMA_MONITOR_SV
