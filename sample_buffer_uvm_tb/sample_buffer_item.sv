// =============================================================================
// Sequence Item : sample_buffer_item.sv
// Description   : Standard UVM Transaction Item for SAMPLE_BUFFER
// =============================================================================
`ifndef SAMPLE_BUFFER_ITEM_SV
`define SAMPLE_BUFFER_ITEM_SV

class sample_buffer_item extends uvm_sequence_item;

  // Transaction Fields
  rand bit [11:0] sbuf_waddr;
  rand bit [15:0] sbuf_wdata;
  rand bit        sbuf_we;
  rand bit        buf_swap_req;
  rand bit        vga_vsync_pulse;
       bit        active_wr_buf;
       bit        active_rd_buf;
  rand bit        clk_vga;
  rand bit        rst_vga_n;
  rand bit [11:0] sbuf_raddr;
       bit [15:0] sbuf_rdata;
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
  rand int unsigned delay;

  `uvm_object_utils_begin(sample_buffer_item)
    `uvm_field_int(sbuf_waddr, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(sbuf_wdata, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(sbuf_we, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(buf_swap_req, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(vga_vsync_pulse, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(active_wr_buf, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(active_rd_buf, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(clk_vga, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(rst_vga_n, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(sbuf_raddr, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(sbuf_rdata, UVM_ALL_ON | UVM_HEX)
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
    `uvm_field_int(delay, UVM_ALL_ON | UVM_DEC)
  `uvm_object_utils_end

  constraint c_delay { delay inside {[0:5]}; }

  function new(string name = "sample_buffer_item");
    super.new(name);
  endfunction : new

  virtual function string convert2string();
    return $sformatf("sbuf_waddr=0x%0h sbuf_wdata=0x%0h sbuf_we=0x%0h buf_swap_req=0x%0h vga_vsync_pulse=0x%0h active_wr_buf=0x%0h active_rd_buf=0x%0h clk_vga=0x%0h rst_vga_n=0x%0h sbuf_raddr=0x%0h sbuf_rdata=0x%0h s_axi_awaddr=0x%0h s_axi_awvalid=0x%0h s_axi_awready=0x%0h s_axi_wdata=0x%0h s_axi_wstrb=0x%0h s_axi_wvalid=0x%0h s_axi_wready=0x%0h s_axi_bresp=0x%0h s_axi_bvalid=0x%0h s_axi_bready=0x%0h s_axi_araddr=0x%0h s_axi_arvalid=0x%0h s_axi_arready=0x%0h s_axi_rdata=0x%0h s_axi_rresp=0x%0h s_axi_rvalid=0x%0h s_axi_rready=0x%0h", sbuf_waddr, sbuf_wdata, sbuf_we, buf_swap_req, vga_vsync_pulse, active_wr_buf, active_rd_buf, clk_vga, rst_vga_n, sbuf_raddr, sbuf_rdata, s_axi_awaddr, s_axi_awvalid, s_axi_awready, s_axi_wdata, s_axi_wstrb, s_axi_wvalid, s_axi_wready, s_axi_bresp, s_axi_bvalid, s_axi_bready, s_axi_araddr, s_axi_arvalid, s_axi_arready, s_axi_rdata, s_axi_rresp, s_axi_rvalid, s_axi_rready);
  endfunction : convert2string

endclass : sample_buffer_item

`endif // SAMPLE_BUFFER_ITEM_SV
