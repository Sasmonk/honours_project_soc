// =============================================================================
// Item Types   : dma_items.sv
// Description  : UVM Sequence Items representing DMA stream & AXI master events
// =============================================================================
`ifndef DMA_ITEMS_SV
`define DMA_ITEMS_SV

// -----------------------------------------------------------------------------
// DMA Streaming Sample Item (Mode 1)
// -----------------------------------------------------------------------------
class dma_stream_item extends uvm_sequence_item;
  `uvm_object_utils(dma_stream_item)

  rand bit [15:0] sample_in;
  bit [15:0]      fir_out;
  bit [11:0]      sbuf_addr;
  bit [15:0]      sbuf_data;
  bit             sbuf_we;
  bit             buf_swap;
  realtime        timestamp;

  function new(string name = "dma_stream_item");
    super.new(name);
  endfunction

  virtual function void do_copy(uvm_object rhs);
    dma_stream_item rhs_;
    if (!$cast(rhs_, rhs)) return;
    super.do_copy(rhs);
    this.sample_in = rhs_.sample_in;
    this.fir_out   = rhs_.fir_out;
    this.sbuf_addr = rhs_.sbuf_addr;
    this.sbuf_data = rhs_.sbuf_data;
    this.sbuf_we   = rhs_.sbuf_we;
    this.buf_swap  = rhs_.buf_swap;
    this.timestamp = rhs_.timestamp;
  endfunction

  virtual function string convert2string();
    return $sformatf("StreamItem: IN=0x%04x FIR=0x%04x SBUF_ADDR=%0d SBUF_DATA=0x%04x WE=%b SWAP=%b @%0t",
                     sample_in, fir_out, sbuf_addr, sbuf_data, sbuf_we, buf_swap, timestamp);
  endfunction
endclass : dma_stream_item

// -----------------------------------------------------------------------------
// DMA AXI Master Transfer Item (Mode 0)
// -----------------------------------------------------------------------------
class dma_axi_xfer_item extends uvm_sequence_item;
  `uvm_object_utils(dma_axi_xfer_item)

  typedef enum bit { AXI_XFER_READ = 1'b0, AXI_XFER_WRITE = 1'b1 } xfer_dir_e;

  xfer_dir_e   dir;
  bit [31:0]   addr;
  bit [31:0]   data;
  bit [1:0]    resp;
  bit          last;
  realtime     timestamp;

  function new(string name = "dma_axi_xfer_item");
    super.new(name);
  endfunction

  virtual function void do_copy(uvm_object rhs);
    dma_axi_xfer_item rhs_;
    if (!$cast(rhs_, rhs)) return;
    super.do_copy(rhs);
    this.dir       = rhs_.dir;
    this.addr      = rhs_.addr;
    this.data      = rhs_.data;
    this.resp      = rhs_.resp;
    this.last      = rhs_.last;
    this.timestamp = rhs_.timestamp;
  endfunction

  virtual function string convert2string();
    return $sformatf("AXI_XFER: %s ADDR=0x%08x DATA=0x%08x RESP=2'b%02b LAST=%b @%0t",
                     (dir == AXI_XFER_WRITE) ? "WRITE" : "READ",
                     addr, data, resp, last, timestamp);
  endfunction
endclass : dma_axi_xfer_item

// -----------------------------------------------------------------------------
// DMA Event / Interrupt Notification Item
// -----------------------------------------------------------------------------
class dma_event_item extends uvm_sequence_item;
  `uvm_object_utils(dma_event_item)

  bit        irq_done;
  bit        irq_err;
  bit        buf_swap;
  bit [15:0] samples_count;
  realtime   timestamp;

  function new(string name = "dma_event_item");
    super.new(name);
  endfunction

  virtual function void do_copy(uvm_object rhs);
    dma_event_item rhs_;
    if (!$cast(rhs_, rhs)) return;
    super.do_copy(rhs);
    this.irq_done      = rhs_.irq_done;
    this.irq_err       = rhs_.irq_err;
    this.buf_swap      = rhs_.buf_swap;
    this.samples_count = rhs_.samples_count;
    this.timestamp     = rhs_.timestamp;
  endfunction
endclass : dma_event_item

`endif // DMA_ITEMS_SV
