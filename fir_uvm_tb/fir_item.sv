// =============================================================================
// Sequence Item : fir_item.sv
// Description   : Standard UVM Transaction Item for FIR
// =============================================================================
`ifndef FIR_ITEM_SV
`define FIR_ITEM_SV

class fir_item extends uvm_sequence_item;

  // Transaction Fields
  rand bit [15:0] fir_sample_in;
  rand bit        fir_sample_valid_in;
       bit [15:0] fir_sample_out;
       bit        fir_sample_valid_out;
       bit        irq_fir;
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

  `uvm_object_utils_begin(fir_item)
    `uvm_field_int(fir_sample_in, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(fir_sample_valid_in, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(fir_sample_out, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(fir_sample_valid_out, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(irq_fir, UVM_ALL_ON | UVM_HEX)
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

  function new(string name = "fir_item");
    super.new(name);
  endfunction : new

  virtual function string convert2string();
    return $sformatf("fir_sample_in=0x%0h fir_sample_valid_in=0x%0h fir_sample_out=0x%0h fir_sample_valid_out=0x%0h irq_fir=0x%0h s_axi_awaddr=0x%0h s_axi_awvalid=0x%0h s_axi_awready=0x%0h s_axi_wdata=0x%0h s_axi_wstrb=0x%0h s_axi_wvalid=0x%0h s_axi_wready=0x%0h s_axi_bresp=0x%0h s_axi_bvalid=0x%0h s_axi_bready=0x%0h s_axi_araddr=0x%0h s_axi_arvalid=0x%0h s_axi_arready=0x%0h s_axi_rdata=0x%0h s_axi_rresp=0x%0h s_axi_rvalid=0x%0h s_axi_rready=0x%0h", fir_sample_in, fir_sample_valid_in, fir_sample_out, fir_sample_valid_out, irq_fir, s_axi_awaddr, s_axi_awvalid, s_axi_awready, s_axi_wdata, s_axi_wstrb, s_axi_wvalid, s_axi_wready, s_axi_bresp, s_axi_bvalid, s_axi_bready, s_axi_araddr, s_axi_arvalid, s_axi_arready, s_axi_rdata, s_axi_rresp, s_axi_rvalid, s_axi_rready);
  endfunction : convert2string

endclass : fir_item

`endif // FIR_ITEM_SV
