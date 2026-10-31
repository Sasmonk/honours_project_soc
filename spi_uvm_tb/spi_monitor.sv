// =============================================================================
// Monitor    : spi_monitor.sv
// Description: Passive Protocol Monitor & Analysis Broadcaster for SPI
// =============================================================================
`ifndef SPI_MONITOR_SV
`define SPI_MONITOR_SV

class spi_monitor extends uvm_monitor;
  `uvm_component_utils(spi_monitor)

  virtual spi_if vif;
  uvm_analysis_port #(spi_item) ap;

  function new(string name = "spi_monitor", uvm_component parent = null);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual spi_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("SPI_MON", "Virtual interface spi_if not set in config_db!")
    end
  endfunction : build_phase

  virtual task run_phase(uvm_phase phase);
    forever begin
      @(vif.monitor_cb);
      begin
        spi_item item = spi_item::type_id::create("mon_item");
        item.sample_tick = vif.monitor_cb.sample_tick;
        item.adc_spi_sck = vif.monitor_cb.adc_spi_sck;
        item.adc_spi_mosi = vif.monitor_cb.adc_spi_mosi;
        item.adc_spi_miso = vif.monitor_cb.adc_spi_miso;
        item.adc_spi_cs_n = vif.monitor_cb.adc_spi_cs_n;
        item.sample_ready = vif.monitor_cb.sample_ready;
        item.sample_data = vif.monitor_cb.sample_data;
        item.irq_spi = vif.monitor_cb.irq_spi;
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
endclass : spi_monitor

`endif // SPI_MONITOR_SV
