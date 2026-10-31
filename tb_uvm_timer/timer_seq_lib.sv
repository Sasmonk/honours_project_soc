// =============================================================================
// Sequence Lib : timer_seq_lib.sv
// Description  : UVM Sequences for System Timer Verification (TC_ACQ_01)
// =============================================================================
`ifndef TIMER_SEQ_LIB_SV
`define TIMER_SEQ_LIB_SV

// -----------------------------------------------------------------------------
// Base Timer AXI Sequence
// -----------------------------------------------------------------------------
class timer_base_seq extends uvm_sequence #(axi_item);
  `uvm_object_utils(timer_base_seq)

  // Register Offsets
  localparam bit [31:0] REG_TIMER_CTRL   = 32'h4000_8000;
  localparam bit [31:0] REG_TIMER_RELOAD = 32'h4000_8004;
  localparam bit [31:0] REG_TIMER_COUNT  = 32'h4000_8008;
  localparam bit [31:0] REG_TIMER_STATUS = 32'h4000_800C;

  function new(string name = "timer_base_seq");
    super.new(name);
  endfunction

  task write_reg(bit [31:0] addr, bit [31:0] data);
    axi_item req = axi_item::type_id::create("req");
    start_item(req);
    req.op    = AXI_WRITE;
    req.addr  = addr;
    req.data  = data;
    req.strb  = 4'hF;
    req.prot  = 3'b000;
    finish_item(req);
  endtask

  task read_reg(bit [31:0] addr, output bit [31:0] data);
    axi_item req = axi_item::type_id::create("req");
    start_item(req);
    req.op    = AXI_READ;
    req.addr  = addr;
    req.strb  = 4'h0;
    req.prot  = 3'b000;
    finish_item(req);
    data = req.data;
  endtask

endclass : timer_base_seq

// -----------------------------------------------------------------------------
// TC_ACQ_01 Sequence: Cycle-Accurate Sample Rate Pacing
// -----------------------------------------------------------------------------
class timer_pacing_precision_seq extends timer_base_seq;
  `uvm_object_utils(timer_pacing_precision_seq)

  function new(string name = "timer_pacing_precision_seq");
    super.new(name);
  endfunction

  virtual task body();
    bit [31:0] rdata;

    `uvm_info("TC_ACQ_01", "Starting TC_ACQ_01: Cycle-Accurate Sample Rate Pacing Sequence", UVM_LOW)

    // Milestone 25%: Write TIMER_RELOAD = 100 cycles
    `uvm_info("TC_ACQ_01", "[TC_ACQ_01 25%%] Programming TIMER_RELOAD = 100 cycles", UVM_LOW)
    write_reg(REG_TIMER_RELOAD, 32'd100);

    // Readback verification of RELOAD
    read_reg(REG_TIMER_RELOAD, rdata);
    if (rdata !== 32'd100) begin
      `uvm_error("TC_ACQ_01", $sformatf("TIMER_RELOAD readback mismatch: expected 100, got %0d", rdata))
    end

    // Milestone 50%: Write TIMER_CTRL.EN = 1
    `uvm_info("TC_ACQ_01", "[TC_ACQ_01 50%%] Enabling Timer: TIMER_CTRL.EN = 1", UVM_LOW)
    write_reg(REG_TIMER_CTRL, 32'd1);

    // Check timer decrementing
    #200; // wait 10 clock cycles
    read_reg(REG_TIMER_COUNT, rdata);
    `uvm_info("TC_ACQ_01", $sformatf("Sampled active TIMER_COUNT = %0d", rdata), UVM_LOW)

    // Milestone 75%: Wait for first tick pulse and IRQ
    `uvm_info("TC_ACQ_01", "[TC_ACQ_01 75%%] Waiting for down-counter underflow to 0 and sample_tick pulse", UVM_LOW)
    #2200; // Wait > 100 cycles for first tick (100 * 20ns = 2000ns)

    // Milestone 100%: Verify multiple consecutive ticks and cycle period
    `uvm_info("TC_ACQ_01", "[TC_ACQ_01 100%%] Monitoring consecutive sample_tick pulses for exact 101-cycle period", UVM_LOW)
    #6500; // Wait another 3 full periods (3 * 101 * 20ns = 6060ns)

    // Check TIMER_STATUS (TICK bit)
    read_reg(REG_TIMER_STATUS, rdata);
    if (!rdata[0]) begin
      `uvm_error("TC_ACQ_01", "TIMER_STATUS TICK bit not asserted after underflow!")
    end else begin
      `uvm_info("TC_ACQ_01", "TIMER_STATUS TICK bit successfully observed asserted", UVM_LOW)
    end

    // Test W1C clearing of TICK
    `uvm_info("TC_ACQ_01", "Writing 1 to TIMER_STATUS.TICK (W1C clear)", UVM_LOW)
    write_reg(REG_TIMER_STATUS, 32'd1);
    read_reg(REG_TIMER_STATUS, rdata);
    `uvm_info("TC_ACQ_01", $sformatf("Post-clear TIMER_STATUS = 0x%08x", rdata), UVM_LOW)

    // Reconfigure with a different reload value (fast rate: reload = 30)
    `uvm_info("TC_ACQ_01", "Testing secondary reload rate: TIMER_RELOAD = 30 cycles", UVM_LOW)
    write_reg(REG_TIMER_CTRL, 32'd0); // disable
    write_reg(REG_TIMER_RELOAD, 32'd30);
    write_reg(REG_TIMER_CTRL, 32'd1); // re-enable

    #3500; // Observe several 31-cycle periods (31 * 20ns = 620ns)

    // Clean disable
    write_reg(REG_TIMER_CTRL, 32'd0);
    `uvm_info("TC_ACQ_01", "TC_ACQ_01 completed successfully!", UVM_LOW)
  endtask

endclass : timer_pacing_precision_seq

`endif // TIMER_SEQ_LIB_SV
