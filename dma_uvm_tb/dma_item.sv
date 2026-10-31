// =============================================================================
// Sequence Item : dma_item.sv
// Description   : Standard UVM Transaction Item for DMA
// =============================================================================
`ifndef DMA_ITEM_SV
`define DMA_ITEM_SV

class dma_item extends uvm_sequence_item;

  // Transaction Fields
  rand bit        sample_tick;
  rand bit        spi_sample_ready;
  rand bit [15:0] spi_sample_data;
       bit [15:0] fir_sample_in;
       bit        fir_sample_valid_in;
  rand bit [15:0] fir_sample_out;
  rand bit        fir_sample_valid_out;
       bit [11:0] sbuf_waddr;
       bit [15:0] sbuf_wdata;
       bit        sbuf_we;
       bit        buf_swap_req;
       bit [7:0] m_axi_awid;
       bit [31:0] m_axi_awaddr;
       bit [7:0] m_axi_awlen;
       bit [2:0] m_axi_awsize;
       bit [1:0] m_axi_awburst;
       bit        m_axi_awlock;
       bit [3:0] m_axi_awcache;
       bit [2:0] m_axi_awprot;
       bit [3:0] m_axi_awqos;
       bit        m_axi_awvalid;
  rand bit        m_axi_awready;
       bit [31:0] m_axi_wdata;
       bit [3:0] m_axi_wstrb;
       bit        m_axi_wlast;
       bit        m_axi_wvalid;
  rand bit        m_axi_wready;
  rand bit [7:0] m_axi_bid;
  rand bit [1:0] m_axi_bresp;
  rand bit        m_axi_bvalid;
       bit        m_axi_bready;
       bit [7:0] m_axi_arid;
       bit [31:0] m_axi_araddr;
       bit [7:0] m_axi_arlen;
       bit [2:0] m_axi_arsize;
       bit [1:0] m_axi_arburst;
       bit        m_axi_arlock;
       bit [3:0] m_axi_arcache;
       bit [2:0] m_axi_arprot;
       bit [3:0] m_axi_arqos;
       bit        m_axi_arvalid;
  rand bit        m_axi_arready;
  rand bit [7:0] m_axi_rid;
  rand bit [31:0] m_axi_rdata;
  rand bit [1:0] m_axi_rresp;
  rand bit        m_axi_rlast;
  rand bit        m_axi_rvalid;
       bit        m_axi_rready;
  rand bit [31:0] s_axi_awaddr;
  rand bit        s_axi_awvalid;
       bit        s_axi_awready;
  rand bit [31:0] s_axi_wdata;
  rand bit [3:0] s_axi_wstrb;
  rand bit        s_axi_wvalid;
       bit        s_axi_wready;
       bit [1:0] s_axi_bresp;
       bit        s_axi_bvalid;
  rand bit        s_axi_bready;
  rand bit [31:0] s_axi_araddr;
  rand bit        s_axi_arvalid;
       bit        s_axi_arready;
       bit [31:0] s_axi_rdata;
       bit [1:0] s_axi_rresp;
       bit        s_axi_rvalid;
  rand bit        s_axi_rready;
       bit        irq_dma_done;
       bit        irq_dma_err;
  rand int unsigned delay;

  `uvm_object_utils_begin(dma_item)
    `uvm_field_int(sample_tick, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(spi_sample_ready, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(spi_sample_data, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(fir_sample_in, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(fir_sample_valid_in, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(fir_sample_out, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(fir_sample_valid_out, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(sbuf_waddr, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(sbuf_wdata, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(sbuf_we, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(buf_swap_req, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(m_axi_awid, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(m_axi_awaddr, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(m_axi_awlen, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(m_axi_awsize, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(m_axi_awburst, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(m_axi_awlock, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(m_axi_awcache, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(m_axi_awprot, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(m_axi_awqos, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(m_axi_awvalid, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(m_axi_awready, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(m_axi_wdata, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(m_axi_wstrb, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(m_axi_wlast, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(m_axi_wvalid, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(m_axi_wready, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(m_axi_bid, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(m_axi_bresp, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(m_axi_bvalid, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(m_axi_bready, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(m_axi_arid, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(m_axi_araddr, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(m_axi_arlen, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(m_axi_arsize, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(m_axi_arburst, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(m_axi_arlock, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(m_axi_arcache, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(m_axi_arprot, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(m_axi_arqos, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(m_axi_arvalid, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(m_axi_arready, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(m_axi_rid, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(m_axi_rdata, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(m_axi_rresp, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(m_axi_rlast, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(m_axi_rvalid, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(m_axi_rready, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(s_axi_awaddr, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(s_axi_awvalid, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(s_axi_awready, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(s_axi_wdata, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(s_axi_wstrb, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(s_axi_wvalid, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(s_axi_wready, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(s_axi_bresp, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(s_axi_bvalid, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(s_axi_bready, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(s_axi_araddr, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(s_axi_arvalid, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(s_axi_arready, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(s_axi_rdata, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(s_axi_rresp, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(s_axi_rvalid, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(s_axi_rready, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(irq_dma_done, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(irq_dma_err, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(delay, UVM_ALL_ON | UVM_DEC)
  `uvm_object_utils_end

  constraint c_delay { delay inside {[0:5]}; }

  function new(string name = "dma_item");
    super.new(name);
  endfunction : new

  virtual function string convert2string();
    return $sformatf("sample_tick=0x%0h spi_sample_ready=0x%0h spi_sample_data=0x%0h fir_sample_in=0x%0h fir_sample_valid_in=0x%0h fir_sample_out=0x%0h fir_sample_valid_out=0x%0h sbuf_waddr=0x%0h sbuf_wdata=0x%0h sbuf_we=0x%0h buf_swap_req=0x%0h m_axi_awid=0x%0h m_axi_awaddr=0x%0h m_axi_awlen=0x%0h m_axi_awsize=0x%0h m_axi_awburst=0x%0h m_axi_awlock=0x%0h m_axi_awcache=0x%0h m_axi_awprot=0x%0h m_axi_awqos=0x%0h m_axi_awvalid=0x%0h m_axi_awready=0x%0h m_axi_wdata=0x%0h m_axi_wstrb=0x%0h m_axi_wlast=0x%0h m_axi_wvalid=0x%0h m_axi_wready=0x%0h m_axi_bid=0x%0h m_axi_bresp=0x%0h m_axi_bvalid=0x%0h m_axi_bready=0x%0h m_axi_arid=0x%0h m_axi_araddr=0x%0h m_axi_arlen=0x%0h m_axi_arsize=0x%0h m_axi_arburst=0x%0h m_axi_arlock=0x%0h m_axi_arcache=0x%0h m_axi_arprot=0x%0h m_axi_arqos=0x%0h m_axi_arvalid=0x%0h m_axi_arready=0x%0h m_axi_rid=0x%0h m_axi_rdata=0x%0h m_axi_rresp=0x%0h m_axi_rlast=0x%0h m_axi_rvalid=0x%0h m_axi_rready=0x%0h s_axi_awaddr=0x%0h s_axi_awvalid=0x%0h s_axi_awready=0x%0h s_axi_wdata=0x%0h s_axi_wstrb=0x%0h s_axi_wvalid=0x%0h s_axi_wready=0x%0h s_axi_bresp=0x%0h s_axi_bvalid=0x%0h s_axi_bready=0x%0h s_axi_araddr=0x%0h s_axi_arvalid=0x%0h s_axi_arready=0x%0h s_axi_rdata=0x%0h s_axi_rresp=0x%0h s_axi_rvalid=0x%0h s_axi_rready=0x%0h irq_dma_done=0x%0h irq_dma_err=0x%0h", sample_tick, spi_sample_ready, spi_sample_data, fir_sample_in, fir_sample_valid_in, fir_sample_out, fir_sample_valid_out, sbuf_waddr, sbuf_wdata, sbuf_we, buf_swap_req, m_axi_awid, m_axi_awaddr, m_axi_awlen, m_axi_awsize, m_axi_awburst, m_axi_awlock, m_axi_awcache, m_axi_awprot, m_axi_awqos, m_axi_awvalid, m_axi_awready, m_axi_wdata, m_axi_wstrb, m_axi_wlast, m_axi_wvalid, m_axi_wready, m_axi_bid, m_axi_bresp, m_axi_bvalid, m_axi_bready, m_axi_arid, m_axi_araddr, m_axi_arlen, m_axi_arsize, m_axi_arburst, m_axi_arlock, m_axi_arcache, m_axi_arprot, m_axi_arqos, m_axi_arvalid, m_axi_arready, m_axi_rid, m_axi_rdata, m_axi_rresp, m_axi_rlast, m_axi_rvalid, m_axi_rready, s_axi_awaddr, s_axi_awvalid, s_axi_awready, s_axi_wdata, s_axi_wstrb, s_axi_wvalid, s_axi_wready, s_axi_bresp, s_axi_bvalid, s_axi_bready, s_axi_araddr, s_axi_arvalid, s_axi_arready, s_axi_rdata, s_axi_rresp, s_axi_rvalid, s_axi_rready, irq_dma_done, irq_dma_err);
  endfunction : convert2string

endclass : dma_item

`endif // DMA_ITEM_SV
