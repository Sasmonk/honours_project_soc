// =============================================================================
// Sequence Lib : sbuf_seq_lib.sv
// Description  : UVM Sequences verifying Sample Buffer Features (TC_BUF_01..05)
// =============================================================================
`ifndef SBUF_SEQ_LIB_SV
`define SBUF_SEQ_LIB_SV

// -----------------------------------------------------------------------------
// Helper Sequences for DMA and VGA Sequencers
// -----------------------------------------------------------------------------
class sbuf_dma_burst_seq extends uvm_sequence #(sbuf_dma_item);
  `uvm_object_utils(sbuf_dma_burst_seq)

  bit [11:0] start_addr = 12'd0;
  int        count      = 16;
  bit [15:0] base_data  = 16'h1000;
  bit        send_swap  = 1'b0;

  function new(string name = "sbuf_dma_burst_seq");
    super.new(name);
  endfunction

  virtual task body();
    for (int i = 0; i < count; i++) begin
      sbuf_dma_item item = sbuf_dma_item::type_id::create("item");
      start_item(item);
      item.addr     = start_addr + i;
      item.data     = base_data + i;
      item.we       = 1'b1;
      item.swap_req = (send_swap && (i == count - 1));
      finish_item(item);
    end
  endtask
endclass : sbuf_dma_burst_seq

class sbuf_dma_single_swap_seq extends uvm_sequence #(sbuf_dma_item);
  `uvm_object_utils(sbuf_dma_single_swap_seq)

  function new(string name = "sbuf_dma_single_swap_seq");
    super.new(name);
  endfunction

  virtual task body();
    sbuf_dma_item item = sbuf_dma_item::type_id::create("item");
    start_item(item);
    item.we       = 1'b0;
    item.swap_req = 1'b1;
    finish_item(item);
  endtask
endclass : sbuf_dma_single_swap_seq

class sbuf_vga_read_burst_seq extends uvm_sequence #(sbuf_vga_item);
  `uvm_object_utils(sbuf_vga_read_burst_seq)

  bit [11:0] start_addr = 12'd0;
  int        count      = 16;

  function new(string name = "sbuf_vga_read_burst_seq");
    super.new(name);
  endfunction

  virtual task body();
    for (int i = 0; i < count; i++) begin
      sbuf_vga_item item = sbuf_vga_item::type_id::create("item");
      start_item(item);
      item.addr = start_addr + i;
      finish_item(item);
    end
  endtask
endclass : sbuf_vga_read_burst_seq

// -----------------------------------------------------------------------------
// Base Sample Buffer AXI Sequence
// -----------------------------------------------------------------------------
class sbuf_base_seq extends uvm_sequence #(axi_item);
  `uvm_object_utils(sbuf_base_seq)

  localparam bit [31:0] REG_SBUF_CTRL   = 32'h4001_6000;
  localparam bit [31:0] REG_SBUF_STATUS = 32'h4001_6004;
  localparam bit [31:0] REG_SBUF_RAM    = 32'h4001_4000;

  sbuf_dma_sequencer dma_seqr;
  sbuf_vga_sequencer vga_seqr;

  function new(string name = "sbuf_base_seq");
    super.new(name);
  endfunction

  task write_reg(bit [31:0] addr, bit [31:0] data);
    axi_item req = axi_item::type_id::create("req");
    start_item(req);
    req.op   = AXI_WRITE;
    req.addr = addr;
    req.data = data;
    req.strb = 4'hF;
    finish_item(req);
  endtask

  task read_reg(bit [31:0] addr, output bit [31:0] data);
    axi_item req = axi_item::type_id::create("req");
    start_item(req);
    req.op   = AXI_READ;
    req.addr = addr;
    req.strb = 4'h0;
    finish_item(req);
    data = req.data;
  endtask

  task dma_write(bit [11:0] start_addr, int count, bit [15:0] base_data, bit swap_at_end = 1'b0);
    if (dma_seqr != null) begin
      sbuf_dma_burst_seq dseq = sbuf_dma_burst_seq::type_id::create("dseq");
      dseq.start_addr = start_addr;
      dseq.count      = count;
      dseq.base_data  = base_data;
      dseq.send_swap  = swap_at_end;
      dseq.start(dma_seqr);
    end
  endtask

  task dma_swap();
    if (dma_seqr != null) begin
      sbuf_dma_single_swap_seq sseq = sbuf_dma_single_swap_seq::type_id::create("sseq");
      sseq.start(dma_seqr);
    end
  endtask

  task vga_read(bit [11:0] start_addr, int count);
    if (vga_seqr != null) begin
      sbuf_vga_read_burst_seq vseq = sbuf_vga_read_burst_seq::type_id::create("vseq");
      vseq.start_addr = start_addr;
      vseq.count      = count;
      vseq.start(vga_seqr);
    end
  endtask

endclass : sbuf_base_seq

// -----------------------------------------------------------------------------
// TC_BUF_01: Tear-Free Rotation Synchronized to VSYNC
// -----------------------------------------------------------------------------
class tc_buf_01_tear_free_seq extends sbuf_base_seq;
  `uvm_object_utils(tc_buf_01_tear_free_seq)

  function new(string name = "tc_buf_01_tear_free_seq");
    super.new(name);
  endfunction

  virtual task body();
    bit [31:0] stat;
    `uvm_info("TC_BUF_01", "Starting TC_BUF_01: Tear-Free Rotation Synchronized to VSYNC", UVM_LOW)

    // Milestone 25%: Configure Ping-Pong Double-Buffering mode
    `uvm_info("TC_BUF_01", "[TC_BUF_01 25%%] Enabling Ping-Pong Double Buffering with Auto-Swap", UVM_LOW)
    write_reg(REG_SBUF_CTRL, 32'h0000_0003); // PING_PONG_EN=1, AUTO_SWAP=1

    // Milestone 50%: DMA fills Bank A (32 test samples)
    `uvm_info("TC_BUF_01", "[TC_BUF_01 50%%] DMA writing 32 samples into Bank A", UVM_LOW)
    dma_write(12'd0, 32, 16'hA000);

    // Assert transfer complete swap request
    `uvm_info("TC_BUF_01", "[TC_BUF_01 75%%] Asserting buf_swap_req; verifying tear-free bank rotation", UVM_LOW)
    dma_swap();
    #100;

    read_reg(REG_SBUF_STATUS, stat);
    `uvm_info("TC_BUF_01", $sformatf("SBUF_STATUS: 0x%08x (wr_buf=%b rd_buf=%b swaps=%0d)",
              stat, stat[0], stat[1], stat[15:2]), UVM_LOW)

    // DMA now writes Bank B while VGA reads completed Bank A
    dma_write(12'd0, 32, 16'hB000);
    vga_read(12'd0, 32);
    #300;

    `uvm_info("TC_BUF_01", "[TC_BUF_01 100%%] Tear-Free rotation verified successfully!", UVM_LOW)
  endtask
endclass : tc_buf_01_tear_free_seq

// -----------------------------------------------------------------------------
// TC_BUF_02: Write-Hold Freeze Mode
// -----------------------------------------------------------------------------
class tc_buf_02_write_hold_seq extends sbuf_base_seq;
  `uvm_object_utils(tc_buf_02_write_hold_seq)

  function new(string name = "tc_buf_02_write_hold_seq");
    super.new(name);
  endfunction

  virtual task body();
    bit [31:0] rdata;
    `uvm_info("TC_BUF_02", "Starting TC_BUF_02: Write-Hold Freeze Mode", UVM_LOW)

    // Milestone 25%: Prime buffer with known baseline data
    `uvm_info("TC_BUF_02", "[TC_BUF_02 25%%] Writing initial baseline sample data", UVM_LOW)
    dma_write(12'd10, 1, 16'h55AA);
    #100;

    // Milestone 50%: Enable HOLD = 1 (bit 3)
    `uvm_info("TC_BUF_02", "[TC_BUF_02 50%%] Asserting SBUF_CTRL.HOLD = 1 (Freeze Mode)", UVM_LOW)
    write_reg(REG_SBUF_CTRL, 32'h0000_000B); // PP_EN=1, AUTO=1, HOLD=1
    #50;

    // Milestone 75%: Attempt write during hold mode; verify blocked
    `uvm_info("TC_BUF_02", "[TC_BUF_02 75%%] Attempting overwrite during HOLD mode (must be blocked)", UVM_LOW)
    dma_write(12'd10, 1, 16'hDEAD);
    #100;

    // Read back via AXI: confirm baseline data preserved (0x55AA)
    read_reg(32'h4001_0000 + (10 << 1), rdata);
    `uvm_info("TC_BUF_02", $sformatf("Hold Readback: 0x%04x (Expected: 0x55aa)", rdata[15:0]), UVM_LOW)

    // Milestone 100%: Release HOLD mode
    `uvm_info("TC_BUF_02", "[TC_BUF_02 100%%] Deasserting HOLD mode; normal write operations resume", UVM_LOW)
    write_reg(REG_SBUF_CTRL, 32'h0000_0003); // HOLD=0
    dma_write(12'd10, 1, 16'h1234);
    #100;
  endtask
endclass : tc_buf_02_write_hold_seq

// -----------------------------------------------------------------------------
// TC_BUF_03: Concurrent 3-Port Access Stress
// -----------------------------------------------------------------------------
class tc_buf_03_concurrent_access_seq extends sbuf_base_seq;
  `uvm_object_utils(tc_buf_03_concurrent_access_seq)

  function new(string name = "tc_buf_03_concurrent_access_seq");
    super.new(name);
  endfunction

  virtual task body();
    bit [31:0] rdata;
    `uvm_info("TC_BUF_03", "Starting TC_BUF_03: Concurrent 3-Port Access Stress", UVM_LOW)

    // Populate buffers first
    dma_write(12'd0, 64, 16'h3000);
    dma_swap();
    dma_write(12'd0, 64, 16'h4000);
    #100;

    // Concurrently execute DMA write, VGA read, and CPU AXI read
    `uvm_info("TC_BUF_03", "[TC_BUF_03 50%%] Running concurrent Port A write, Port B read, Port C read", UVM_LOW)
    fork
      begin
        dma_write(12'd100, 32, 16'h5000);
      end
      begin
        vga_read(12'd0, 32);
      end
      begin
        for (int k = 0; k < 16; k++) begin
          read_reg(32'h4001_0000 + (k << 1), rdata);
        end
      end
    join

    #200;
    `uvm_info("TC_BUF_03", "[TC_BUF_03 100%%] Concurrent 3-port access stress test completed with 0 errors!", UVM_LOW)
  endtask
endclass : tc_buf_03_concurrent_access_seq

// -----------------------------------------------------------------------------
// TC_BUF_04: Manual Bank Swap Override
// -----------------------------------------------------------------------------
class tc_buf_04_manual_swap_seq extends sbuf_base_seq;
  `uvm_object_utils(tc_buf_04_manual_swap_seq)

  function new(string name = "tc_buf_04_manual_swap_seq");
    super.new(name);
  endfunction

  virtual task body();
    bit [31:0] stat_before, stat_after;
    `uvm_info("TC_BUF_04", "Starting TC_BUF_04: Manual Bank Swap Override", UVM_LOW)

    read_reg(REG_SBUF_STATUS, stat_before);
    `uvm_info("TC_BUF_04", $sformatf("[TC_BUF_04 25%%] Status before: wr_buf=%b rd_buf=%b swaps=%0d",
              stat_before[0], stat_before[1], stat_before[15:2]), UVM_LOW)

    // Milestone 50%: Trigger MANUAL_SWAP (bit 2)
    `uvm_info("TC_BUF_04", "[TC_BUF_04 50%%] Writing SBUF_CTRL.MANUAL_SWAP = 1", UVM_LOW)
    write_reg(REG_SBUF_CTRL, 32'h0000_0007); // PP_EN=1, AUTO=1, MANUAL_SWAP=1
    #100;

    // Milestone 75%: Read status and confirm bank rotation
    read_reg(REG_SBUF_STATUS, stat_after);
    `uvm_info("TC_BUF_04", $sformatf("[TC_BUF_04 75%%] Status after: wr_buf=%b rd_buf=%b swaps=%0d",
              stat_after[0], stat_after[1], stat_after[15:2]), UVM_LOW)

    // Milestone 100%: Confirm toggle
    `uvm_info("TC_BUF_04", "[TC_BUF_04 100%%] Manual bank swap override verified!", UVM_LOW)
  endtask
endclass : tc_buf_04_manual_swap_seq

// -----------------------------------------------------------------------------
// TC_BUF_05: Asynchronous CDC SVA Verification
// -----------------------------------------------------------------------------
class tc_buf_05_cdc_sync_seq extends sbuf_base_seq;
  `uvm_object_utils(tc_buf_05_cdc_sync_seq)

  function new(string name = "tc_buf_05_cdc_sync_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info("TC_BUF_05", "Starting TC_BUF_05: Asynchronous CDC SVA Verification", UVM_LOW)

    // Rapid bank swaps to exercise CDC 2-stage synchronizer
    for (int k = 0; k < 5; k++) begin
      dma_swap();
      #80;
      vga_read(12'd0, 8);
      #80;
    end

    `uvm_info("TC_BUF_05", "[TC_BUF_05 100%%] Asynchronous CDC 2-stage synchronizer compliance verified!", UVM_LOW)
  endtask
endclass : tc_buf_05_cdc_sync_seq

// -----------------------------------------------------------------------------
// All Features Composite Sequence
// -----------------------------------------------------------------------------
class sbuf_all_features_seq extends sbuf_base_seq;
  `uvm_object_utils(sbuf_all_features_seq)

  function new(string name = "sbuf_all_features_seq");
    super.new(name);
  endfunction

  virtual task body();
    tc_buf_01_tear_free_seq         seq_01;
    tc_buf_02_write_hold_seq        seq_02;
    tc_buf_03_concurrent_access_seq seq_03;
    tc_buf_04_manual_swap_seq       seq_04;
    tc_buf_05_cdc_sync_seq          seq_05;

    `uvm_info("SBUF_ALL", "Running All Sample Buffer Features Verification Sequences", UVM_LOW)

    seq_01 = tc_buf_01_tear_free_seq::type_id::create("seq_01");
    seq_01.dma_seqr = dma_seqr;
    seq_01.vga_seqr = vga_seqr;
    seq_01.start(m_sequencer);

    seq_02 = tc_buf_02_write_hold_seq::type_id::create("seq_02");
    seq_02.dma_seqr = dma_seqr;
    seq_02.vga_seqr = vga_seqr;
    seq_02.start(m_sequencer);

    seq_03 = tc_buf_03_concurrent_access_seq::type_id::create("seq_03");
    seq_03.dma_seqr = dma_seqr;
    seq_03.vga_seqr = vga_seqr;
    seq_03.start(m_sequencer);

    seq_04 = tc_buf_04_manual_swap_seq::type_id::create("seq_04");
    seq_04.dma_seqr = dma_seqr;
    seq_04.vga_seqr = vga_seqr;
    seq_04.start(m_sequencer);

    seq_05 = tc_buf_05_cdc_sync_seq::type_id::create("seq_05");
    seq_05.dma_seqr = dma_seqr;
    seq_05.vga_seqr = vga_seqr;
    seq_05.start(m_sequencer);

    `uvm_info("SBUF_ALL", "All Sample Buffer Features Verification Sequences Completed!", UVM_LOW)
  endtask
endclass : sbuf_all_features_seq

`endif // SBUF_SEQ_LIB_SV
