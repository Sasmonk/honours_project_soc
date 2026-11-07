// =============================================================================
// Sequence Items : sbuf_items.sv
// Description    : Transaction items for DMA Port A and VGA Port B
// =============================================================================
`ifndef SBUF_ITEMS_SV
`define SBUF_ITEMS_SV

class sbuf_dma_item extends uvm_sequence_item;
  `uvm_object_utils(sbuf_dma_item)

  rand bit [11:0] addr;
  rand bit [15:0] data;
  rand bit        we;
  rand bit        swap_req;
  bit             active_wr_buf;
  realtime        timestamp;

  function new(string name = "sbuf_dma_item");
    super.new(name);
    we       = 1'b1;
    swap_req = 1'b0;
  endfunction

  function void do_copy(uvm_object rhs);
    sbuf_dma_item rhs_;
    if (!$cast(rhs_, rhs)) return;
    super.do_copy(rhs);
    this.addr          = rhs_.addr;
    this.data          = rhs_.data;
    this.we            = rhs_.we;
    this.swap_req      = rhs_.swap_req;
    this.active_wr_buf = rhs_.active_wr_buf;
    this.timestamp     = rhs_.timestamp;
  endfunction

  function string convert2string();
    return $sformatf("DMA Item: we=%b addr=0x%03x data=0x%04x swap=%b", we, addr, data, swap_req);
  endfunction
endclass : sbuf_dma_item

class sbuf_vga_item extends uvm_sequence_item;
  `uvm_object_utils(sbuf_vga_item)

  rand bit [11:0] addr;
  bit [15:0]      data;
  bit             rd_buf_sel;
  realtime        timestamp;

  function new(string name = "sbuf_vga_item");
    super.new(name);
  endfunction

  function void do_copy(uvm_object rhs);
    sbuf_vga_item rhs_;
    if (!$cast(rhs_, rhs)) return;
    super.do_copy(rhs);
    this.addr       = rhs_.addr;
    this.data       = rhs_.data;
    this.rd_buf_sel = rhs_.rd_buf_sel;
    this.timestamp  = rhs_.timestamp;
  endfunction

  function string convert2string();
    return $sformatf("VGA Item: addr=0x%03x data=0x%04x rd_buf=%b", addr, data, rd_buf_sel);
  endfunction
endclass : sbuf_vga_item

`endif // SBUF_ITEMS_SV
