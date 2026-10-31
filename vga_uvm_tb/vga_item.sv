// =============================================================================
// Sequence Item : vga_item.sv
// Description   : Standard UVM Transaction Item for VGA
// =============================================================================
`ifndef VGA_ITEM_SV
`define VGA_ITEM_SV

class vga_item extends uvm_sequence_item;

  // Transaction Fields
  rand bit        clk_vga;
  rand bit        rst_vga_n;
       bit [11:0] sbuf_raddr;
  rand bit [15:0] sbuf_rdata;
       bit        vga_vsync_pulse;
       bit        vga_hsync;
       bit        vga_vsync;
       bit [3:0] vga_red;
       bit [3:0] vga_green;
       bit [3:0] vga_blue;
       bit        irq_vga_frame;
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

  `uvm_object_utils_begin(vga_item)
    `uvm_field_int(clk_vga, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(rst_vga_n, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(sbuf_raddr, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(sbuf_rdata, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(vga_vsync_pulse, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(vga_hsync, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(vga_vsync, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(vga_red, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(vga_green, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(vga_blue, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(irq_vga_frame, UVM_ALL_ON | UVM_HEX)
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

  function new(string name = "vga_item");
    super.new(name);
  endfunction : new

  virtual function string convert2string();
    return $sformatf("clk_vga=0x%0h rst_vga_n=0x%0h sbuf_raddr=0x%0h sbuf_rdata=0x%0h vga_vsync_pulse=0x%0h vga_hsync=0x%0h vga_vsync=0x%0h vga_red=0x%0h vga_green=0x%0h vga_blue=0x%0h irq_vga_frame=0x%0h s_axi_awaddr=0x%0h s_axi_awvalid=0x%0h s_axi_awready=0x%0h s_axi_wdata=0x%0h s_axi_wstrb=0x%0h s_axi_wvalid=0x%0h s_axi_wready=0x%0h s_axi_bresp=0x%0h s_axi_bvalid=0x%0h s_axi_bready=0x%0h s_axi_araddr=0x%0h s_axi_arvalid=0x%0h s_axi_arready=0x%0h s_axi_rdata=0x%0h s_axi_rresp=0x%0h s_axi_rvalid=0x%0h s_axi_rready=0x%0h", clk_vga, rst_vga_n, sbuf_raddr, sbuf_rdata, vga_vsync_pulse, vga_hsync, vga_vsync, vga_red, vga_green, vga_blue, irq_vga_frame, s_axi_awaddr, s_axi_awvalid, s_axi_awready, s_axi_wdata, s_axi_wstrb, s_axi_wvalid, s_axi_wready, s_axi_bresp, s_axi_bvalid, s_axi_bready, s_axi_araddr, s_axi_arvalid, s_axi_arready, s_axi_rdata, s_axi_rresp, s_axi_rvalid, s_axi_rready);
  endfunction : convert2string

endclass : vga_item

`endif // VGA_ITEM_SV
