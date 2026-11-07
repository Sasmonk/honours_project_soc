// =============================================================================
// Monitor      : sbuf_dma_monitor.sv
// Description  : Monitor for DMA Write Port A and active bank signals
// =============================================================================
`ifndef SBUF_DMA_MONITOR_SV
`define SBUF_DMA_MONITOR_SV

class sbuf_dma_monitor extends uvm_monitor;
  `uvm_component_utils(sbuf_dma_monitor)

  virtual sbuf_dma_if vif;
  uvm_analysis_port #(sbuf_dma_item) ap;
  uvm_analysis_port #(bit)           bank_swap_ap;

  function new(string name = "sbuf_dma_monitor", uvm_component parent = null);
    super.new(name, parent);
    ap           = new("ap", this);
    bank_swap_ap = new("bank_swap_ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual sbuf_dma_if)::get(this, "", "dma_vif", vif)) begin
      `uvm_fatal("NOVIF", "virtual sbuf_dma_if not found in config_db")
    end
  endfunction

  task run_phase(uvm_phase phase);
    bit prev_wr_buf = 1'b0;

    @(posedge vif.rst_sys_n);
    prev_wr_buf = vif.active_wr_buf;

    forever begin
      @(posedge vif.clk_sys);

      if (vif.sbuf_we || vif.buf_swap_req) begin
        sbuf_dma_item item = sbuf_dma_item::type_id::create("item");
        item.addr          = vif.sbuf_waddr;
        item.data          = vif.sbuf_wdata;
        item.we            = vif.sbuf_we;
        item.swap_req      = vif.buf_swap_req;
        item.active_wr_buf = vif.active_wr_buf;
        item.timestamp     = $realtime;
        ap.write(item);
      end

      if (vif.active_wr_buf != prev_wr_buf) begin
        bank_swap_ap.write(vif.active_wr_buf);
        `uvm_info("DMA_MON", $sformatf("Bank Swap Detected: wr_buf=%b rd_buf=%b",
                  vif.active_wr_buf, vif.active_rd_buf), UVM_HIGH)
      end
      prev_wr_buf = vif.active_wr_buf;
    end
  endtask

endclass : sbuf_dma_monitor

`endif // SBUF_DMA_MONITOR_SV
