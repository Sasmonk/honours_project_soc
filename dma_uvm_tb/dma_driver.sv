// =============================================================================
// Driver      : dma_driver.sv
// Description : Protocol-Accurate Master Driver for DMA
// =============================================================================
`ifndef DMA_DRIVER_SV
`define DMA_DRIVER_SV

class dma_driver extends uvm_driver #(dma_item);
  `uvm_component_utils(dma_driver)

  virtual dma_if vif;

  function new(string name = "dma_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual dma_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("DMA_DRV", "Virtual interface dma_if not set in config_db!")
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
    vif.master_cb.sample_tick <= '0;
    vif.master_cb.spi_sample_ready <= '0;
    vif.master_cb.spi_sample_data <= '0;
    vif.master_cb.fir_sample_out <= '0;
    vif.master_cb.fir_sample_valid_out <= '0;
    vif.master_cb.m_axi_awready <= '0;
    vif.master_cb.m_axi_wready <= '0;
    vif.master_cb.m_axi_bid <= '0;
    vif.master_cb.m_axi_bresp <= '0;
    vif.master_cb.m_axi_bvalid <= '0;
    vif.master_cb.m_axi_arready <= '0;
    vif.master_cb.m_axi_rid <= '0;
    vif.master_cb.m_axi_rdata <= '0;
    vif.master_cb.m_axi_rresp <= '0;
    vif.master_cb.m_axi_rlast <= '0;
    vif.master_cb.m_axi_rvalid <= '0;
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
    @(posedge vif.rst_n);
    @(vif.master_cb);
  endtask : wait_for_reset

  virtual task drive_transfer(dma_item item);
    repeat (item.delay) @(vif.master_cb);
    vif.master_cb.sample_tick <= item.sample_tick;
    vif.master_cb.spi_sample_ready <= item.spi_sample_ready;
    vif.master_cb.spi_sample_data <= item.spi_sample_data;
    vif.master_cb.fir_sample_out <= item.fir_sample_out;
    vif.master_cb.fir_sample_valid_out <= item.fir_sample_valid_out;
    vif.master_cb.m_axi_awready <= item.m_axi_awready;
    vif.master_cb.m_axi_wready <= item.m_axi_wready;
    vif.master_cb.m_axi_bid <= item.m_axi_bid;
    vif.master_cb.m_axi_bresp <= item.m_axi_bresp;
    vif.master_cb.m_axi_bvalid <= item.m_axi_bvalid;
    vif.master_cb.m_axi_arready <= item.m_axi_arready;
    vif.master_cb.m_axi_rid <= item.m_axi_rid;
    vif.master_cb.m_axi_rdata <= item.m_axi_rdata;
    vif.master_cb.m_axi_rresp <= item.m_axi_rresp;
    vif.master_cb.m_axi_rlast <= item.m_axi_rlast;
    vif.master_cb.m_axi_rvalid <= item.m_axi_rvalid;
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
endclass : dma_driver

`endif // DMA_DRIVER_SV
