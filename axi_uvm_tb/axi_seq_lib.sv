// =============================================================================
// Sequence Lib : axi_seq_lib.sv
// Description  : Production Sequence Library for AXI UVM Verification
// =============================================================================
`ifndef AXI_SEQ_LIB_SV
`define AXI_SEQ_LIB_SV

class axi_base_seq extends uvm_sequence #(axi_item);
  `uvm_object_utils(axi_base_seq)
  function new(string name = "axi_base_seq"); super.new(name); endfunction
endclass : axi_base_seq

// Directed Write Sequence
class axi_write_seq extends axi_base_seq;
  `uvm_object_utils(axi_write_seq)
  rand bit [31:0] addr;
  rand bit [31:0] data;
  rand bit [3:0]  strb = 4'hF;

  function new(string name = "axi_write_seq"); super.new(name); endfunction

  virtual task body();
    req = axi_item::type_id::create("req");
    start_item(req);
    req.op   = AXI_WRITE;
    req.addr = addr;
    req.data = data;
    req.strb = strb;
    finish_item(req);
  endtask : body
endclass : axi_write_seq

// Directed Read Sequence
class axi_read_seq extends axi_base_seq;
  `uvm_object_utils(axi_read_seq)
  rand bit [31:0] addr;
  bit [31:0]      read_data;

  function new(string name = "axi_read_seq"); super.new(name); endfunction

  virtual task body();
    req = axi_item::type_id::create("req");
    start_item(req);
    req.op   = AXI_READ;
    req.addr = addr;
    finish_item(req);
    read_data = req.data;
  endtask : body
endclass : axi_read_seq

// Random Read/Write Burst Sequence
class axi_rand_burst_seq extends axi_base_seq;
  `uvm_object_utils(axi_rand_burst_seq)
  rand int unsigned count;
  constraint c_count { count inside {[10:30]}; }

  function new(string name = "axi_rand_burst_seq"); super.new(name); endfunction

  virtual task body();
    repeat (count) begin
      req = axi_item::type_id::create("req");
      start_item(req);
      if (!req.randomize()) `uvm_fatal("AXI_SEQ", "Randomization failed!")
      finish_item(req);
    end
  endtask : body
endclass : axi_rand_burst_seq

`endif // AXI_SEQ_LIB_SV
