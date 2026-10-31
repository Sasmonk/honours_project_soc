// =============================================================================
// Sequence Lib : watchdog_seq_lib.sv
// Description  : UVM Sequences for Watchdog Safety Monitor (TC_WDT_01)
// =============================================================================
`ifndef WATCHDOG_SEQ_LIB_SV
`define WATCHDOG_SEQ_LIB_SV

class watchdog_base_seq extends uvm_sequence #(axi_item);
  `uvm_object_utils(watchdog_base_seq)

  // Watchdog CSR Addresses (Architecture Section 8.8)
  localparam bit [31:0] REG_WDT_CTRL   = 32'h4000_E000;
  localparam bit [31:0] REG_WDT_RELOAD = 32'h4000_E004;
  localparam bit [31:0] REG_WDT_KICK   = 32'h4000_E008;
  localparam bit [31:0] REG_WDT_STATUS = 32'h4000_E00C;

  function new(string name = "watchdog_base_seq");
    super.new(name);
  endfunction

  task write_reg(bit [31:0] addr, bit [31:0] data);
    axi_item req = axi_item::type_id::create("req");
    start_item(req);
    req.op   = AXI_WRITE;
    req.addr = addr;
    req.data = data;
    req.strb = 4'hF;
    req.prot = 3'b000;
    finish_item(req);
  endtask

  task read_reg(bit [31:0] addr, output bit [31:0] data);
    axi_item req = axi_item::type_id::create("req");
    start_item(req);
    req.op   = AXI_READ;
    req.addr = addr;
    req.strb = 4'h0;
    req.prot = 3'b000;
    finish_item(req);
    data = req.data;
  endtask

endclass : watchdog_base_seq

// -----------------------------------------------------------------------------
// TC_WDT_01 Sequence: Watchdog Keep-Alive & Reset Trip
// -----------------------------------------------------------------------------
class wdt_safety_trip_seq extends watchdog_base_seq;
  `uvm_object_utils(wdt_safety_trip_seq)

  function new(string name = "wdt_safety_trip_seq");
    super.new(name);
  endfunction

  virtual task body();
    bit [31:0] rdata;

    `uvm_info("TC_WDT_01", "Starting TC_WDT_01: Watchdog Keep-Alive & Reset Trip Sequence", UVM_LOW)

    // Milestone 25%: Program WDT_RELOAD = 600 cycles and arm WDT
    `uvm_info("TC_WDT_01", "[TC_WDT_01 25%%] Programming WDT_RELOAD = 600 cycles", UVM_LOW)
    write_reg(REG_WDT_RELOAD, 32'd600);

    read_reg(REG_WDT_RELOAD, rdata);
    if (rdata !== 32'd600) begin
      `uvm_error("TC_WDT_01", $sformatf("WDT_RELOAD readback mismatch: expected 600, got %0d", rdata))
    end

    `uvm_info("TC_WDT_01", "[TC_WDT_01 25%%] Arming Watchdog: WDT_CTRL.EN = 1", UVM_LOW)
    write_reg(REG_WDT_CTRL, 32'd1);

    // Milestone 50%: Firmware kicks WDT periodically (every 300 cycles) to keep alive
    `uvm_info("TC_WDT_01", "[TC_WDT_01 50%%] Executing Periodic Firmware Kicks (Keep-Alive Phase)", UVM_LOW)
    repeat (3) begin
      #6000; // 300 cycles * 20ns = 6000ns
      `uvm_info("TC_WDT_01", "Kicking Watchdog (WDT_KICK = 1)", UVM_LOW)
      write_reg(REG_WDT_KICK, 32'd1);

      // Verify status remains untripped
      read_reg(REG_WDT_STATUS, rdata);
      if (rdata[1] !== 1'b0 || rdata[0] !== 1'b0) begin
        `uvm_error("TC_WDT_01", $sformatf("Unexpected WDT trip during keep-alive kicks! Status=0x%0x", rdata))
      end
    end

    // Milestone 75% & 100%: Stop kicking; allow counter to decrement to 1 and 0
    `uvm_info("TC_WDT_01", "[TC_WDT_01 75%%] Ceasing Software Kicks - Expecting NMI Pre-Warning", UVM_LOW)
    // 600 cycles * 20ns = 12,000ns
    #12500;

    // Milestone 100%: Read status to verify TRIPPED=1
    `uvm_info("TC_WDT_01", "[TC_WDT_01 100%%] Checking WDT_STATUS for TRIPPED bit", UVM_LOW)
    read_reg(REG_WDT_STATUS, rdata);
    if (!rdata[1]) begin
      `uvm_error("TC_WDT_01", $sformatf("Expected WDT_STATUS.TRIPPED=1 after countdown! Status=0x%08x", rdata))
    end else begin
      `uvm_info("TC_WDT_01", "WDT_STATUS TRIPPED bit verified HIGH!", UVM_LOW)
    end

    // Disarm Watchdog cleanly
    write_reg(REG_WDT_CTRL, 32'd0);
    `uvm_info("TC_WDT_01", "TC_WDT_01 completed successfully!", UVM_LOW)
  endtask

endclass : wdt_safety_trip_seq

`endif // WATCHDOG_SEQ_LIB_SV
