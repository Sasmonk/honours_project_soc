// =============================================================================
// Monitor      : dma_monitor.sv
// Description  : Hardware Monitor capturing SBUF writes, interrupts and events
// =============================================================================
`ifndef DMA_MONITOR_SV
`define DMA_MONITOR_SV

class dma_monitor extends uvm_monitor;
  `uvm_component_utils(dma_monitor)

  virtual dma_stream_if vif;
  uvm_analysis_port #(dma_stream_item) stream_ap;
  uvm_analysis_port #(dma_event_item)  event_ap;

  function new(string name = "dma_monitor", uvm_component parent = null);
    super.new(name, parent);
    stream_ap = new("stream_ap", this);
    event_ap  = new("event_ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual dma_stream_if)::get(this, "", "dma_vif", vif)) begin
      `uvm_fatal("NOVIF", "virtual dma_stream_if not found in config_db")
    end
  endfunction

  task run_phase(uvm_phase phase);
    bit prev_irq_done = 1'b0;
    bit prev_irq_err  = 1'b0;
    bit prev_buf_swap = 1'b0;

    @(posedge vif.rst_n);

    forever begin
      @(posedge vif.clk);

      // Monitor SBUF Writes in Mode 1 (Streaming)
      if (vif.sbuf_we) begin
        dma_stream_item item = dma_stream_item::type_id::create("stream_item");
        item.sample_in = vif.spi_sample_data;
        item.fir_out   = vif.fir_sample_out;
        item.sbuf_addr = vif.sbuf_waddr;
        item.sbuf_data = vif.sbuf_wdata;
        item.sbuf_we   = vif.sbuf_we;
        item.buf_swap  = vif.buf_swap_req;
        item.timestamp = $realtime;
        stream_ap.write(item);
      end

      // Monitor Interrupts and Buffer Swaps
      if ((vif.irq_dma_done && !prev_irq_done) ||
          (vif.irq_dma_err  && !prev_irq_err)  ||
          (vif.buf_swap_req && !prev_buf_swap)) begin
        dma_event_item ev = dma_event_item::type_id::create("ev_item");
        ev.irq_done  = vif.irq_dma_done;
        ev.irq_err   = vif.irq_dma_err;
        ev.buf_swap  = vif.buf_swap_req;
        ev.timestamp = $realtime;
        event_ap.write(ev);
      end

      prev_irq_done = vif.irq_dma_done;
      prev_irq_err  = vif.irq_dma_err;
      prev_buf_swap = vif.buf_swap_req;
    end
  endtask

endclass : dma_monitor

`endif // DMA_MONITOR_SV
