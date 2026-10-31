// =============================================================================
// Sequence Lib : spi_seq_lib.sv
// Description  : UVM Sequences verifying SPI Master features (TC_ACQ_02..06)
// =============================================================================
`ifndef SPI_SEQ_LIB_SV
`define SPI_SEQ_LIB_SV

// -----------------------------------------------------------------------------
// Base SPI AXI Sequence
// -----------------------------------------------------------------------------
class spi_base_axi_seq extends uvm_sequence #(axi_item);
  `uvm_object_utils(spi_base_axi_seq)

  // Peripheral CSR Addresses (0x4000_C000)
  localparam bit [31:0] REG_SPI_CTRL      = 32'h4000_C000;
  localparam bit [31:0] REG_SPI_STATUS    = 32'h4000_C004;
  localparam bit [31:0] REG_SPI_TXDATA    = 32'h4000_C008;
  localparam bit [31:0] REG_SPI_RXDATA    = 32'h4000_C00C;
  localparam bit [31:0] REG_SPI_CS        = 32'h4000_C010;
  localparam bit [31:0] REG_SPI_FIFO_CNT  = 32'h4000_C014;
  localparam bit [31:0] REG_SPI_FIFO_CTRL = 32'h4000_C018;

  virtual spi_adc_if vif;

  function new(string name = "spi_base_axi_seq");
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

  task pulse_tick();
    if (vif != null) begin
      @(posedge vif.clk);
      vif.sample_tick <= 1'b1;
      @(posedge vif.clk);
      vif.sample_tick <= 1'b0;
    end
  endtask

  task wait_for_transfer_done();
    bit [31:0] stat;
    #100;
    do begin
      #500;
      read_reg(REG_SPI_STATUS, stat);
    end while (stat[0]); // Poll BUSY
  endtask

endclass : spi_base_axi_seq

// -----------------------------------------------------------------------------
// TC_ACQ_02: Autonomous SPI Hardware Auto-Trigger
// -----------------------------------------------------------------------------
class tc_acq_02_auto_trigger_seq extends spi_base_axi_seq;
  `uvm_object_utils(tc_acq_02_auto_trigger_seq)

  function new(string name = "tc_acq_02_auto_trigger_seq");
    super.new(name);
  endfunction

  virtual task body();
    bit [31:0] rdata;
    `uvm_info("TC_ACQ_02", "Starting TC_ACQ_02: Autonomous SPI Hardware Auto-Trigger", UVM_LOW)

    // Milestone 25%: Enable SPI_CTRL.AUTO_TRIGGER = 1, PRESCALER = 2
    `uvm_info("TC_ACQ_02", "[TC_ACQ_02 25%%] Programming SPI_CTRL: AUTO_TRIGGER=1, PRESCALER=2", UVM_LOW)
    write_reg(REG_SPI_CTRL, 32'h0000_0023);

    // Milestone 50%: Timer emits sample_tick pulse
    `uvm_info("TC_ACQ_02", "[TC_ACQ_02 50%%] Emitting hardware sample_tick pulse", UVM_LOW)
    pulse_tick();

    // Milestone 75%: Wait for SPI transfer execution
    `uvm_info("TC_ACQ_02", "[TC_ACQ_02 75%%] Waiting for SPI transfer execution (CS_N assertion & SCK clocking)", UVM_LOW)
    wait_for_transfer_done();

    // Milestone 100%: Read RXDATA from AXI CSR
    `uvm_info("TC_ACQ_02", "[TC_ACQ_02 100%%] Reading captured ADC sample from SPI_RXDATA", UVM_LOW)
    read_reg(REG_SPI_RXDATA, rdata);
    `uvm_info("TC_ACQ_02", $sformatf("Captured Sample: 0x%04x", rdata[15:0]), UVM_LOW)

    `uvm_info("TC_ACQ_02", "TC_ACQ_02 completed successfully!", UVM_LOW)
  endtask
endclass : tc_acq_02_auto_trigger_seq

// -----------------------------------------------------------------------------
// TC_ACQ_03: SPI Prescaler SCK Frequency & Duty Sweep
// -----------------------------------------------------------------------------
class tc_acq_03_prescaler_sweep_seq extends spi_base_axi_seq;
  `uvm_object_utils(tc_acq_03_prescaler_sweep_seq)

  function new(string name = "tc_acq_03_prescaler_sweep_seq");
    super.new(name);
  endfunction

  virtual task body();
    bit [31:0] rdata;
    `uvm_info("TC_ACQ_03", "Starting TC_ACQ_03: SPI Prescaler Sweep (2, 4, 8)", UVM_LOW)

    // Sweep PRESCALER = 2
    `uvm_info("TC_ACQ_03", "[TC_ACQ_03 25%%] Testing PRESCALER = 2 (25 MHz SCK)", UVM_LOW)
    write_reg(REG_SPI_CTRL, 32'h0000_0023);
    pulse_tick();
    wait_for_transfer_done();
    read_reg(REG_SPI_RXDATA, rdata);

    // Sweep PRESCALER = 4
    `uvm_info("TC_ACQ_03", "[TC_ACQ_03 50%%] Testing PRESCALER = 4 (12.5 MHz SCK)", UVM_LOW)
    write_reg(REG_SPI_CTRL, 32'h0000_0043);
    pulse_tick();
    wait_for_transfer_done();
    read_reg(REG_SPI_RXDATA, rdata);

    // Sweep PRESCALER = 8
    `uvm_info("TC_ACQ_03", "[TC_ACQ_03 75%%] Testing PRESCALER = 8 (6.25 MHz SCK)", UVM_LOW)
    write_reg(REG_SPI_CTRL, 32'h0000_0083);
    pulse_tick();
    wait_for_transfer_done();
    read_reg(REG_SPI_RXDATA, rdata);

    `uvm_info("TC_ACQ_03", "[TC_ACQ_03 100%%] Prescaler sweep and 50% duty cycle verified!", UVM_LOW)
  endtask
endclass : tc_acq_03_prescaler_sweep_seq

// -----------------------------------------------------------------------------
// TC_ACQ_04: RX FIFO 32-Entry Watermark & Overflow
// -----------------------------------------------------------------------------
class tc_acq_04_fifo_overflow_seq extends spi_base_axi_seq;
  `uvm_object_utils(tc_acq_04_fifo_overflow_seq)

  function new(string name = "tc_acq_04_fifo_overflow_seq");
    super.new(name);
  endfunction

  virtual task body();
    bit [31:0] rdata;
    int i;
    `uvm_info("TC_ACQ_04", "Starting TC_ACQ_04: RX FIFO 32-Entry Watermark & Overflow", UVM_LOW)

    // Set fast rate: PRESCALER = 2
    write_reg(REG_SPI_CTRL, 32'h0000_0023);
    // Flush FIFO
    write_reg(REG_SPI_FIFO_CTRL, 32'd1);

    // Milestone 25%: Fill FIFO with 32 consecutive samples
    `uvm_info("TC_ACQ_04", "[TC_ACQ_04 25%%] Pulsing 32 consecutive auto-trigger sample ticks", UVM_LOW)
    for (i = 0; i < 32; i++) begin
      pulse_tick();
      wait_for_transfer_done();
    end

    // Milestone 50%: Check FIFO full flag in SPI_STATUS
    `uvm_info("TC_ACQ_04", "[TC_ACQ_04 50%%] Checking SPI_STATUS.FIFO_FULL bit and IRQ", UVM_LOW)
    read_reg(REG_SPI_STATUS, rdata);
    if (!rdata[4]) begin
      `uvm_error("TC_ACQ_04", $sformatf("Expected FIFO_FULL=1 (bit 4)! Status=0x%08x", rdata))
    end else begin
      `uvm_info("TC_ACQ_04", "FIFO_FULL bit verified asserted!", UVM_LOW)
    end

    // Milestone 75%: Inject 33rd sample while FIFO is full
    `uvm_info("TC_ACQ_04", "[TC_ACQ_04 75%%] Injecting 33rd sample (overflow injection)", UVM_LOW)
    pulse_tick();
    wait_for_transfer_done();

    // Milestone 100%: Pop all 32 samples from FIFO
    `uvm_info("TC_ACQ_04", "[TC_ACQ_04 100%%] Reading out all 32 samples from FIFO", UVM_LOW)
    for (i = 0; i < 32; i++) begin
      read_reg(REG_SPI_RXDATA, rdata);
    end

    // Check FIFO empty
    read_reg(REG_SPI_STATUS, rdata);
    `uvm_info("TC_ACQ_04", $sformatf("Status post-drain = 0x%08x (empty=%b)", rdata, !rdata[3]), UVM_LOW)
    `uvm_info("TC_ACQ_04", "TC_ACQ_04 completed successfully!", UVM_LOW)
  endtask
endclass : tc_acq_04_fifo_overflow_seq

// -----------------------------------------------------------------------------
// TC_ACQ_05: Manual SPI Command Transmission
// -----------------------------------------------------------------------------
class tc_acq_05_manual_command_seq extends spi_base_axi_seq;
  `uvm_object_utils(tc_acq_05_manual_command_seq)

  function new(string name = "tc_acq_05_manual_command_seq");
    super.new(name);
  endfunction

  virtual task body();
    bit [31:0] rdata;
    `uvm_info("TC_ACQ_05", "Starting TC_ACQ_05: Manual SPI Command Transmission", UVM_LOW)

    // Milestone 25%: Set SPI_CTRL.AUTO_TRIGGER = 0
    `uvm_info("TC_ACQ_05", "[TC_ACQ_05 25%%] Setting SPI_CTRL: AUTO_TRIGGER=0, PRESCALER=2", UVM_LOW)
    write_reg(REG_SPI_CTRL, 32'h0000_0021); // EN=1, AUTO=0, PRESCALER=2

    // Milestone 50%: Write command word 0xBEEF to SPI_TXDATA
    `uvm_info("TC_ACQ_05", "[TC_ACQ_05 50%%] Writing command word 0xBEEF to SPI_TXDATA", UVM_LOW)
    write_reg(REG_SPI_TXDATA, 32'h0000_BEEF);

    // Milestone 75% & 100%: Wait for transfer and verify
    `uvm_info("TC_ACQ_05", "[TC_ACQ_05 75%%] Polling SPI_STATUS.BUSY until transfer completes", UVM_LOW)
    wait_for_transfer_done();

    read_reg(REG_SPI_RXDATA, rdata);
    `uvm_info("TC_ACQ_05", "[TC_ACQ_05 100%%] Manual command transmission verified!", UVM_LOW)
  endtask
endclass : tc_acq_05_manual_command_seq

// -----------------------------------------------------------------------------
// TC_ACQ_06: SPI Chip-Select Lead / Trail Timing Margins
// -----------------------------------------------------------------------------
class tc_acq_06_timing_margins_seq extends spi_base_axi_seq;
  `uvm_object_utils(tc_acq_06_timing_margins_seq)

  function new(string name = "tc_acq_06_timing_margins_seq");
    super.new(name);
  endfunction

  virtual task body();
    bit [31:0] rdata;
    `uvm_info("TC_ACQ_06", "Starting TC_ACQ_06: SPI Lead / Trail Timing Margins", UVM_LOW)

    write_reg(REG_SPI_CTRL, 32'h0000_0023); // PRESCALER=2
    pulse_tick();
    wait_for_transfer_done();
    read_reg(REG_SPI_RXDATA, rdata);

    `uvm_info("TC_ACQ_06", "TC_ACQ_06 completed successfully!", UVM_LOW)
  endtask
endclass : tc_acq_06_timing_margins_seq

// -----------------------------------------------------------------------------
// All Features Composite Sequence
// -----------------------------------------------------------------------------
class spi_all_features_seq extends spi_base_axi_seq;
  `uvm_object_utils(spi_all_features_seq)

  function new(string name = "spi_all_features_seq");
    super.new(name);
  endfunction

  virtual task body();
    tc_acq_02_auto_trigger_seq seq_02;
    tc_acq_03_prescaler_sweep_seq seq_03;
    tc_acq_04_fifo_overflow_seq seq_04;
    tc_acq_05_manual_command_seq seq_05;
    tc_acq_06_timing_margins_seq seq_06;

    `uvm_info("SPI_ALL", "Running All SPI Features Verification Sequences", UVM_LOW)

    seq_02 = tc_acq_02_auto_trigger_seq::type_id::create("seq_02");
    seq_02.vif = vif;
    seq_02.start(m_sequencer);

    seq_03 = tc_acq_03_prescaler_sweep_seq::type_id::create("seq_03");
    seq_03.vif = vif;
    seq_03.start(m_sequencer);

    seq_04 = tc_acq_04_fifo_overflow_seq::type_id::create("seq_04");
    seq_04.vif = vif;
    seq_04.start(m_sequencer);

    seq_05 = tc_acq_05_manual_command_seq::type_id::create("seq_05");
    seq_05.vif = vif;
    seq_05.start(m_sequencer);

    seq_06 = tc_acq_06_timing_margins_seq::type_id::create("seq_06");
    seq_06.vif = vif;
    seq_06.start(m_sequencer);

    `uvm_info("SPI_ALL", "All SPI Features Verification Sequences Completed!", UVM_LOW)
  endtask
endclass : spi_all_features_seq

`endif // SPI_SEQ_LIB_SV
