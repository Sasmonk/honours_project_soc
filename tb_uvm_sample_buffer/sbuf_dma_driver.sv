// =============================================================================
// Driver       : sbuf_dma_driver.sv
// Description  : UVM Driver injecting samples and swap requests via DMA Port A
// =============================================================================
`ifndef SBUF_DMA_DRIVER_SV
`define SBUF_DMA_DRIVER_SV

class sbuf_dma_driver extends uvm_driver #(sbuf_dma_item);
  `uvm_component_utils(sbuf_dma_driver)

  virtual sbuf_dma_if vif;
  uvm_analysis_port #(sbuf_dma_item) drv_ap;

  function new(string name = "sbuf_dma_driver", uvm_component parent = null);
    super.new(name, parent);
    drv_ap = new("drv_ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual sbuf_dma_if)::get(this, "", "dma_vif", vif)) begin
      `uvm_fatal("NOVIF", "virtual sbuf_dma_if not found in config_db")
    end
  endfunction

  task run_phase(uvm_phase phase);
    vif.sbuf_waddr       <= 12'd0;
    vif.sbuf_wdata       <= 16'd0;
    vif.sbuf_we          <= 1'b0;
    vif.buf_swap_req     <= 1'b0;
    vif.vga_vsync_pulse  <= 1'b0;

    @(posedge vif.rst_sys_n);

    forever begin
      seq_item_port.get_next_item(req);
      drive_item(req);
      seq_item_port.item_done();
    end
  endtask

  task drive_item(sbuf_dma_item item);
    @(posedge vif.clk_sys);
    if (item.swap_req) begin
      vif.buf_swap_req <= 1'b1;
    end
    if (item.we) begin
      vif.sbuf_waddr <= item.addr;
      vif.sbuf_wdata <= item.data;
      vif.sbuf_we    <= 1'b1;
    end

    begin
      sbuf_dma_item clone_item = sbuf_dma_item::type_id::create("clone_item");
      clone_item.addr      = item.addr;
      clone_item.data      = item.data;
      clone_item.we        = item.we;
      clone_item.swap_req  = item.swap_req;
      clone_item.timestamp = $realtime;
      drv_ap.write(clone_item);
    end

    @(posedge vif.clk_sys);
    vif.sbuf_we      <= 1'b0;
    vif.buf_swap_req <= 1'b0;
    vif.sbuf_waddr   <= 12'd0;
    vif.sbuf_wdata   <= 16'd0;
  endtask

endclass : sbuf_dma_driver

`endif // SBUF_DMA_DRIVER_SV
