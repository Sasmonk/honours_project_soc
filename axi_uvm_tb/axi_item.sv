// =============================================================================
// Sequence Item : axi_item.sv
// Description   : Standard UVM Transaction Item for AXI
// =============================================================================
`ifndef AXI_ITEM_SV
`define AXI_ITEM_SV

typedef enum bit { AXI_READ = 1'b0, AXI_WRITE = 1'b1 } axi_op_e;
typedef enum bit [1:0] { AXI_RESP_OKAY = 2'b00, AXI_RESP_EXOKAY = 2'b01, AXI_RESP_SLVERR = 2'b10, AXI_RESP_DECERR = 2'b11 } axi_resp_e;

class axi_item extends uvm_sequence_item;

  // Standard AXI Protocol Transaction Fields
  rand axi_op_e                 op;
  rand bit [31:0]               addr;
  rand bit [31:0]               data;
  rand bit [3:0]                strb;
  rand bit [2:0]                prot;
  bit [1:0]                     resp;
  rand int unsigned             delay;

  `uvm_object_utils_begin(axi_item)
    `uvm_field_enum(axi_op_e, op,    UVM_ALL_ON)
    `uvm_field_int (addr,            UVM_ALL_ON | UVM_HEX)
    `uvm_field_int (data,            UVM_ALL_ON | UVM_HEX)
    `uvm_field_int (strb,            UVM_ALL_ON | UVM_HEX)
    `uvm_field_int (prot,            UVM_ALL_ON | UVM_HEX)
    `uvm_field_int (resp,            UVM_ALL_ON | UVM_HEX)
    `uvm_field_int (delay,           UVM_ALL_ON | UVM_DEC)
  `uvm_object_utils_end

  // Protocol Constraints
  constraint c_addr_align { addr[1:0] == 2'b00; }
  constraint c_strb       { strb inside {4'b0001, 4'b0011, 4'b1111}; }
  constraint c_delay      { delay inside {[0:5]}; }

  function new(string name = "axi_item");
    super.new(name);
  endfunction : new

  virtual function string convert2string();
    return $sformatf("op=%s addr=0x%08h data=0x%08h strb=0x%1h resp=0x%0h delay=%0d",
                    op.name(), addr, data, strb, resp, delay);
  endfunction : convert2string

endclass : axi_item

`endif // AXI_ITEM_SV
