// =============================================================================
// Sequence Lib : dma_seq_lib.sv
// Description  : UVM Sequences verifying DMA Controller features (TC_DMA_01..07)
// =============================================================================
`ifndef DMA_SEQ_LIB_SV
`define DMA_SEQ_LIB_SV

// -----------------------------------------------------------------------------
// Base DMA AXI Sequence
// -----------------------------------------------------------------------------
class dma_base_axi_seq extends uvm_sequence #(axi_item);
  `uvm_object_utils(dma_base_axi_seq)

  // CSR Register Addresses
  localparam bit [31:0] REG_DMA_CTRL     = 32'h4001_0000;
  localparam bit [31:0] REG_DMA_SRC_ADDR = 32'h4001_0004;
  localparam bit [31:0] REG_DMA_DST_ADDR = 32'h4001_0008;
  localparam bit [31:0] REG_DMA_LEN      = 32'h4001_000C;
  localparam bit [31:0] REG_DMA_TIMEOUT  = 32'h4001_0010;
  localparam bit [31:0] REG_DMA_STATUS   = 32'h4001_0014;
  localparam bit [31:0] REG_DMA_COUNT    = 32'h4001_0018;

  dma_agent dma_agt_h;

  function new(string name = "dma_base_axi_seq");
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

  task wait_for_done();
    bit [31:0] stat;
    do begin
      #50;
      read_reg(REG_DMA_STATUS, stat);
    end while (!stat[1] && !stat[4] && !stat[5]); // Wait for DONE, TIMEOUT, or ERR
  endtask

endclass : dma_base_axi_seq

// -----------------------------------------------------------------------------
// TC_DMA_01: Streaming Pipeline (ADC/FIR -> Sample Buffer at 100kSPS)
// -----------------------------------------------------------------------------
class tc_dma_01_streaming_pipeline_seq extends dma_base_axi_seq;
  `uvm_object_utils(tc_dma_01_streaming_pipeline_seq)

  function new(string name = "tc_dma_01_streaming_pipeline_seq");
    super.new(name);
  endfunction

  virtual task body();
    bit [31:0] stat;
    `uvm_info("TC_DMA_01", "Starting TC_DMA_01: Streaming Pipeline Mode (Mode 1)", UVM_LOW)

    // Milestone 25%: Configure transfer length = 8 samples, destination = 0x000
    `uvm_info("TC_DMA_01", "[TC_DMA_01 25%%] Programming DMA_LEN=8, DST_ADDR=0x4001_6000", UVM_LOW)
    write_reg(REG_DMA_LEN,      32'd8);
    write_reg(REG_DMA_DST_ADDR, 32'h4001_6000);

    // Milestone 50%: Arm DMA in Legacy Streaming Mode (MODE=0, START=1)
    `uvm_info("TC_DMA_01", "[TC_DMA_01 50%%] Arming DMA (START=1, MODE=0 Streaming)", UVM_LOW)
    write_reg(REG_DMA_CTRL, 32'h0000_0001);

    read_reg(REG_DMA_STATUS, stat);
    `uvm_info("TC_DMA_01", $sformatf("DMA_STATUS after START: 0x%08x (BUSY=%b)", stat, stat[0]), UVM_LOW)

    // Milestone 75%: Feed 8 sample ticks through stream driver
    `uvm_info("TC_DMA_01", "[TC_DMA_01 75%%] Injecting 8 SPI sample ticks into streaming pipeline", UVM_LOW)
    for (int i = 0; i < 8; i++) begin
      if (dma_agt_h != null) begin
        dma_agt_h.driver.send_spi_sample(16'h1000 + i);
      end
      #200;
    end

    // Milestone 100%: Wait for DONE and verify status
    wait_for_done();
    read_reg(REG_DMA_STATUS, stat);
    `uvm_info("TC_DMA_01", $sformatf("[TC_DMA_01 100%%] Streaming pipeline transfer complete! STATUS=0x%08x (DONE=%b)",
              stat, stat[1]), UVM_LOW)

    // Clear DONE (W1C)
    write_reg(REG_DMA_STATUS, 32'h0000_0002);
  endtask
endclass : tc_dma_01_streaming_pipeline_seq

// -----------------------------------------------------------------------------
// TC_DMA_02: AXI4 Master Block Move
// -----------------------------------------------------------------------------
class tc_dma_02_axi_master_block_move_seq extends dma_base_axi_seq;
  `uvm_object_utils(tc_dma_02_axi_master_block_move_seq)

  function new(string name = "tc_dma_02_axi_master_block_move_seq");
    super.new(name);
  endfunction

  virtual task body();
    bit [31:0] stat;
    bit [31:0] rdata;
    `uvm_info("TC_DMA_02", "Starting TC_DMA_02: AXI4 Master Block Move", UVM_LOW)

    // Milestone 25%: Populate source memory buffer in slave responder
    `uvm_info("TC_DMA_02", "[TC_DMA_02 25%%] Pre-loading source memory buffer at 0x8000_0000", UVM_LOW)
    if (dma_agt_h != null) begin
      for (int i = 0; i < 8; i++) begin
        dma_agt_h.responder.write_mem(32'h8000_0000 + (i*4), 32'hCAFE_0000 + i);
      end
    end

    // Milestone 50%: Configure DMA for AXI Master mode
    `uvm_info("TC_DMA_02", "[TC_DMA_02 50%%] Configuring AXI Master: SRC=0x8000_0000 DST=0x8000_1000 LEN=8", UVM_LOW)
    write_reg(REG_DMA_SRC_ADDR, 32'h8000_0000);
    write_reg(REG_DMA_DST_ADDR, 32'h8000_1000);
    write_reg(REG_DMA_LEN,      32'd8);
    write_reg(REG_DMA_TIMEOUT,  32'h0000_1000);

    // Milestone 75%: Arm DMA in Free-Running AXI Master Mode
    // Bit 7=1 (AXI Master), Bit 4=1 (DST_INC), Bit 3=1 (SRC_INC), Bit 0=1 (START) => 0x99
    `uvm_info("TC_DMA_02", "[TC_DMA_02 75%%] Arming DMA (START=1, MODE=1 AXI Master, SRC_INC=1, DST_INC=1)", UVM_LOW)
    write_reg(REG_DMA_CTRL, 32'h0000_0099);

    wait_for_done();

    // Milestone 100%: Verify all 8 words moved to destination memory
    for (int i = 0; i < 8; i++) begin
      if (dma_agt_h != null) begin
        rdata = dma_agt_h.responder.read_mem(32'h8000_1000 + (i*4));
        if (rdata !== (32'hCAFE_0000 + i)) begin
          `uvm_error("TC_DMA_02", $sformatf("Memory verification mismatch at idx %0d: Exp=0x%08x Got=0x%08x",
                     i, 32'hCAFE_0000 + i, rdata))
        end
      end
    end

    read_reg(REG_DMA_STATUS, stat);
    `uvm_info("TC_DMA_02", $sformatf("[TC_DMA_02 100%%] AXI Master Block Move verified! STATUS=0x%08x", stat), UVM_LOW)
    write_reg(REG_DMA_STATUS, 32'h0000_0002); // Clear DONE
  endtask
endclass : tc_dma_02_axi_master_block_move_seq

// -----------------------------------------------------------------------------
// TC_DMA_03: Rate-Paced vs Free-Running Modes
// -----------------------------------------------------------------------------
class tc_dma_03_rate_paced_vs_freerun_seq extends dma_base_axi_seq;
  `uvm_object_utils(tc_dma_03_rate_paced_vs_freerun_seq)

  function new(string name = "tc_dma_03_rate_paced_vs_freerun_seq");
    super.new(name);
  endfunction

  virtual task body();
    bit [31:0] stat;
    `uvm_info("TC_DMA_03", "Starting TC_DMA_03: Rate-Paced vs Free-Running Modes", UVM_LOW)

    // Milestone 25%: Setup source data for 4 words
    `uvm_info("TC_DMA_03", "[TC_DMA_03 25%%] Setting up Rate-Paced transfer (TRIGGER_EN=1)", UVM_LOW)
    if (dma_agt_h != null) begin
      for (int i = 0; i < 4; i++) begin
        dma_agt_h.responder.write_mem(32'h8000_0000 + (i*4), 32'hFACE_0000 + i);
      end
    end

    write_reg(REG_DMA_SRC_ADDR, 32'h8000_0000);
    write_reg(REG_DMA_DST_ADDR, 32'h8000_1000);
    write_reg(REG_DMA_LEN,      32'd4);

    // Milestone 50%: Arm with TRIGGER_EN=1 (Bit 5=1, Bit 7=1, Bit 4=1, Bit 3=1, Bit 0=1 => 0xB9)
    write_reg(REG_DMA_CTRL, 32'h0000_00B9);
    #100;
    read_reg(REG_DMA_STATUS, stat);
    `uvm_info("TC_DMA_03", $sformatf("[TC_DMA_03 50%%] DMA waiting for sample_tick pulses. STATUS=0x%08x", stat), UVM_LOW)

    // Milestone 75%: Send 4 sample_tick pulses to advance transfer
    for (int i = 0; i < 4; i++) begin
      #200;
      if (dma_agt_h != null) dma_agt_h.driver.send_tick();
    end

    wait_for_done();
    read_reg(REG_DMA_STATUS, stat);
    `uvm_info("TC_DMA_03", $sformatf("[TC_DMA_03 100%%] Rate-paced transfer completed! STATUS=0x%08x", stat), UVM_LOW)
    write_reg(REG_DMA_STATUS, 32'h0000_0002);
  endtask
endclass : tc_dma_03_rate_paced_vs_freerun_seq

// -----------------------------------------------------------------------------
// TC_DMA_04: Auto-Reload Ring Buffer Mode
// -----------------------------------------------------------------------------
class tc_dma_04_auto_reload_ring_buf_seq extends dma_base_axi_seq;
  `uvm_object_utils(tc_dma_04_auto_reload_ring_buf_seq)

  function new(string name = "tc_dma_04_auto_reload_ring_buf_seq");
    super.new(name);
  endfunction

  virtual task body();
    bit [31:0] stat;
    `uvm_info("TC_DMA_04", "Starting TC_DMA_04: Auto-Reload Ring Buffer Mode", UVM_LOW)

    // Milestone 25%: Setup source data
    `uvm_info("TC_DMA_04", "[TC_DMA_04 25%%] Programming AUTO_RELOAD=1, LEN=4 words", UVM_LOW)
    if (dma_agt_h != null) begin
      for (int i = 0; i < 4; i++) begin
        dma_agt_h.responder.write_mem(32'h8000_0000 + (i*4), 32'hBEEF_0000 + i);
      end
    end

    write_reg(REG_DMA_SRC_ADDR, 32'h8000_0000);
    write_reg(REG_DMA_DST_ADDR, 32'h8000_1000);
    write_reg(REG_DMA_LEN,      32'd4);

    // Milestone 50%: Arm with AUTO_RELOAD=1 (Bit 2=1, Bit 7=1, Bit 4=1, Bit 3=1, Bit 0=1 => 0x9D)
    `uvm_info("TC_DMA_04", "[TC_DMA_04 50%%] Arming DMA with AUTO_RELOAD=1", UVM_LOW)
    write_reg(REG_DMA_CTRL, 32'h0000_009D);

    // Wait for first block completion
    wait_for_done();
    read_reg(REG_DMA_STATUS, stat);
    `uvm_info("TC_DMA_04", $sformatf("[TC_DMA_04 75%%] First block completed, DMA automatically reloaded! STATUS=0x%08x", stat), UVM_LOW)

    // Clear DONE flag and let second block proceed
    write_reg(REG_DMA_STATUS, 32'h0000_0002);
    #500;

    // Milestone 100%: Abort auto-reload loop cleanly
    write_reg(REG_DMA_CTRL, 32'h0000_0002); // ABORT
    #100;
    write_reg(REG_DMA_STATUS, 32'h0000_0002); // Clear any lingering DONE flag
    read_reg(REG_DMA_STATUS, stat);
    `uvm_info("TC_DMA_04", $sformatf("[TC_DMA_04 100%%] DMA aborted cleanly. STATUS=0x%08x (BUSY=%b)", stat, stat[0]), UVM_LOW)
  endtask
endclass : tc_dma_04_auto_reload_ring_buf_seq

// -----------------------------------------------------------------------------
// TC_DMA_05: Timeout Abort & Watchdog Recovery
// -----------------------------------------------------------------------------
class tc_dma_05_timeout_abort_seq extends dma_base_axi_seq;
  `uvm_object_utils(tc_dma_05_timeout_abort_seq)

  function new(string name = "tc_dma_05_timeout_abort_seq");
    super.new(name);
  endfunction

  virtual task body();
    bit [31:0] stat;
    `uvm_info("TC_DMA_05", "Starting TC_DMA_05: Timeout Abort & Watchdog Recovery", UVM_LOW)

    // Milestone 25%: Configure tight timeout = 50 clock cycles
    `uvm_info("TC_DMA_05", "[TC_DMA_05 25%%] Programming DMA_TIMEOUT = 50 cycles", UVM_LOW)
    write_reg(REG_DMA_LEN,     32'd8);
    write_reg(REG_DMA_TIMEOUT, 32'd50);

    // Milestone 50%: Enable slave bus stall in responder
    `uvm_info("TC_DMA_05", "[TC_DMA_05 50%%] Injecting artificial bus stall (arready=0)", UVM_LOW)
    if (dma_agt_h != null) dma_agt_h.responder.inject_stall = 1'b1;

    // Milestone 75%: Arm DMA
    write_reg(REG_DMA_CTRL, 32'h0000_0099);

    // Wait for timeout flag assertion
    do begin
      #50;
      read_reg(REG_DMA_STATUS, stat);
    end while (!stat[4]); // Bit 4: TIMEOUT

    `uvm_info("TC_DMA_05", $sformatf("[TC_DMA_05 75%%] Timeout triggered successfully! STATUS=0x%08x (TIMEOUT=%b)", stat, stat[4]), UVM_LOW)

    // Milestone 100%: Recover responder and clear status (W1C)
    if (dma_agt_h != null) dma_agt_h.responder.inject_stall = 1'b0;
    write_reg(REG_DMA_STATUS, 32'h0000_0010); // Clear TIMEOUT bit
    read_reg(REG_DMA_STATUS, stat);
    `uvm_info("TC_DMA_05", $sformatf("[TC_DMA_05 100%%] Watchdog recovery complete! STATUS=0x%08x", stat), UVM_LOW)
  endtask
endclass : tc_dma_05_timeout_abort_seq

// -----------------------------------------------------------------------------
// TC_DMA_06: FIFO Underrun / Error Recovery
// -----------------------------------------------------------------------------
class tc_dma_06_error_recovery_seq extends dma_base_axi_seq;
  `uvm_object_utils(tc_dma_06_error_recovery_seq)

  function new(string name = "tc_dma_06_error_recovery_seq");
    super.new(name);
  endfunction

  virtual task body();
    bit [31:0] stat;
    `uvm_info("TC_DMA_06", "Starting TC_DMA_06: Bus Error & Slave Error Recovery", UVM_LOW)

    // Milestone 25%: Setup transfer for 1 word SLVERR test
    write_reg(REG_DMA_LEN,     32'd1);
    write_reg(REG_DMA_TIMEOUT, 32'h0000_1000);

    // Milestone 50%: Inject SLVERR (2'b10) response from responder
    `uvm_info("TC_DMA_06", "[TC_DMA_06 50%%] Injecting SLVERR on write response", UVM_LOW)
    if (dma_agt_h != null) dma_agt_h.responder.inject_slverr = 1'b1;

    // Arm DMA
    write_reg(REG_DMA_CTRL, 32'h0000_0099);

    do begin
      #50;
      read_reg(REG_DMA_STATUS, stat);
    end while (!stat[5]); // Wait for ERR bit

    `uvm_info("TC_DMA_06", $sformatf("[TC_DMA_06 75%%] Bus error captured! STATUS=0x%08x (ERR=%b)", stat, stat[5]), UVM_LOW)

    // Milestone 100%: Clear error flag and responder injection
    if (dma_agt_h != null) dma_agt_h.responder.inject_slverr = 1'b0;
    write_reg(REG_DMA_STATUS, 32'h0000_0022); // Clear ERR and DONE
    #100;
    read_reg(REG_DMA_STATUS, stat);
    `uvm_info("TC_DMA_06", $sformatf("[TC_DMA_06 100%%] Error recovery complete! STATUS=0x%08x", stat), UVM_LOW)
  endtask
endclass : tc_dma_06_error_recovery_seq

// -----------------------------------------------------------------------------
// TC_DMA_07: Fixed vs Incrementing Addressing Modes
// -----------------------------------------------------------------------------
class tc_dma_07_fixed_vs_inc_addr_seq extends dma_base_axi_seq;
  `uvm_object_utils(tc_dma_07_fixed_vs_inc_addr_seq)

  function new(string name = "tc_dma_07_fixed_vs_inc_addr_seq");
    super.new(name);
  endfunction

  virtual task body();
    bit [31:0] stat;
    bit [31:0] rdata;
    `uvm_info("TC_DMA_07", "Starting TC_DMA_07: Fixed vs Incrementing Addressing Modes", UVM_LOW)

    // Milestone 25%: Pre-load single FIFO source register at 0x4000_C00C
    `uvm_info("TC_DMA_07", "[TC_DMA_07 25%%] Setting fixed FIFO source at 0x4000_C00C", UVM_LOW)
    if (dma_agt_h != null) begin
      dma_agt_h.responder.write_mem(32'h4000_C00C, 32'h55AA_1234);
    end

    // Milestone 50%: Configure DMA with SRC_INC=0 (fixed) and DST_INC=1 (incrementing)
    write_reg(REG_DMA_SRC_ADDR, 32'h4000_C00C);
    write_reg(REG_DMA_DST_ADDR, 32'h8000_2000);
    write_reg(REG_DMA_LEN,      32'd4);

    // Bit 7=1 (AXI Master), Bit 4=1 (DST_INC), Bit 3=0 (SRC_INC FIXED), Bit 0=1 (START) => 0x91
    `uvm_info("TC_DMA_07", "[TC_DMA_07 75%%] Arming DMA with SRC_INC=0 (Fixed FIFO) and DST_INC=1 (RAM Buffer)", UVM_LOW)
    write_reg(REG_DMA_CTRL, 32'h0000_0091);

    wait_for_done();

    // Milestone 100%: Verify all 4 destination buffer words got the fixed FIFO value
    for (int i = 0; i < 4; i++) begin
      if (dma_agt_h != null) begin
        rdata = dma_agt_h.responder.read_mem(32'h8000_2000 + (i*4));
        if (rdata !== 32'h55AA_1234) begin
          `uvm_error("TC_DMA_07", $sformatf("Destination word %0d mismatch! Exp=0x55AA1234 Got=0x%08x", i, rdata))
        end
      end
    end

    read_reg(REG_DMA_STATUS, stat);
    `uvm_info("TC_DMA_07", $sformatf("[TC_DMA_07 100%%] Fixed vs incrementing addressing verified! STATUS=0x%08x", stat), UVM_LOW)
    write_reg(REG_DMA_STATUS, 32'h0000_0002);
  endtask
endclass : tc_dma_07_fixed_vs_inc_addr_seq

// -----------------------------------------------------------------------------
// All Features Composite Sequence
// -----------------------------------------------------------------------------
class dma_all_features_seq extends dma_base_axi_seq;
  `uvm_object_utils(dma_all_features_seq)

  function new(string name = "dma_all_features_seq");
    super.new(name);
  endfunction

  virtual task body();
    tc_dma_01_streaming_pipeline_seq    seq_01;
    tc_dma_02_axi_master_block_move_seq seq_02;
    tc_dma_03_rate_paced_vs_freerun_seq seq_03;
    tc_dma_04_auto_reload_ring_buf_seq  seq_04;
    tc_dma_05_timeout_abort_seq         seq_05;
    tc_dma_06_error_recovery_seq        seq_06;
    tc_dma_07_fixed_vs_inc_addr_seq     seq_07;

    `uvm_info("DMA_ALL", "Running All DMA Controller Features Verification Sequences", UVM_LOW)

    seq_01 = tc_dma_01_streaming_pipeline_seq::type_id::create("seq_01");
    seq_01.dma_agt_h = dma_agt_h;
    seq_01.start(m_sequencer);

    seq_02 = tc_dma_02_axi_master_block_move_seq::type_id::create("seq_02");
    seq_02.dma_agt_h = dma_agt_h;
    seq_02.start(m_sequencer);

    seq_03 = tc_dma_03_rate_paced_vs_freerun_seq::type_id::create("seq_03");
    seq_03.dma_agt_h = dma_agt_h;
    seq_03.start(m_sequencer);

    seq_04 = tc_dma_04_auto_reload_ring_buf_seq::type_id::create("seq_04");
    seq_04.dma_agt_h = dma_agt_h;
    seq_04.start(m_sequencer);

    seq_05 = tc_dma_05_timeout_abort_seq::type_id::create("seq_05");
    seq_05.dma_agt_h = dma_agt_h;
    seq_05.start(m_sequencer);

    seq_06 = tc_dma_06_error_recovery_seq::type_id::create("seq_06");
    seq_06.dma_agt_h = dma_agt_h;
    seq_06.start(m_sequencer);

    seq_07 = tc_dma_07_fixed_vs_inc_addr_seq::type_id::create("seq_07");
    seq_07.dma_agt_h = dma_agt_h;
    seq_07.start(m_sequencer);

    `uvm_info("DMA_ALL", "All DMA Features Verification Sequences Completed!", UVM_LOW)
  endtask
endclass : dma_all_features_seq

`endif // DMA_SEQ_LIB_SV
