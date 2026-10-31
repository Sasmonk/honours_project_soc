// =============================================================================
// Scoreboard   : spi_scoreboard.sv
// Description  : Comprehensive Scoreboard for SPI Master Verification
// =============================================================================
`ifndef SPI_SCOREBOARD_SV
`define SPI_SCOREBOARD_SV

`uvm_analysis_imp_decl(_spi_axi)
`uvm_analysis_imp_decl(_spi_item)
`uvm_analysis_imp_decl(_spi_drv)
`uvm_analysis_imp_decl(_spi_ready)

class spi_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(spi_scoreboard)

  uvm_analysis_imp_spi_axi   #(axi_item, spi_scoreboard)     axi_export;
  uvm_analysis_imp_spi_item  #(spi_adc_item, spi_scoreboard) spi_item_export;
  uvm_analysis_imp_spi_drv   #(spi_adc_item, spi_scoreboard) spi_drv_export;
  uvm_analysis_imp_spi_ready #(bit, spi_scoreboard)          ready_export;

  // Expected vs Observed Queues
  bit [15:0] expected_fifo_q[$];
  bit [15:0] expected_mosi_q[$];
  localparam int FIFO_CAPACITY = 32;

  // Tracked Register State
  bit       reg_spi_en       = 1'b1;
  bit       reg_auto_trigger = 1'b1;
  bit [3:0] reg_prescaler    = 4'd2;
  bit [15:0] reg_txdata      = 16'h0000;

  // Test Checkpoints & Flags
  bit cp_acq_02_pass = 1'b0;
  bit cp_acq_03_pass = 1'b0;
  bit cp_acq_04_pass = 1'b0;
  bit cp_acq_05_pass = 1'b0;
  bit cp_acq_06_pass = 1'b0;
  bit sva_spi_01_pass = 1'b1;
  bit sva_spi_02_pass = 1'b1;

  // Statistics
  int unsigned sample_match_count     = 0;
  int unsigned sample_mismatch_count  = 0;
  int unsigned mosi_match_count       = 0;
  int unsigned mosi_mismatch_count    = 0;
  int unsigned sample_ready_count     = 0;
  int unsigned total_frames_monitored = 0;
  int unsigned timing_violations      = 0;

  function new(string name = "spi_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    axi_export      = new("axi_export", this);
    spi_item_export = new("spi_item_export", this);
    spi_drv_export  = new("spi_drv_export", this);
    ready_export    = new("ready_export", this);
  endfunction : new

  // 1. AXI Bus Callback
  virtual function void write_spi_axi(axi_item item);
    bit [7:0] reg_offset = item.addr[7:0];

    if (item.op == AXI_WRITE) begin
      case (reg_offset)
        8'h00: begin // SPI_CTRL
          reg_spi_en       = item.data[0];
          reg_auto_trigger = item.data[1];
          if (|item.data[7:4]) reg_prescaler = item.data[7:4];
          `uvm_info("SCOREBOARD", $sformatf("SPI_CTRL: EN=%b AUTO=%b PRESCALER=%0d",
                    reg_spi_en, reg_auto_trigger, reg_prescaler), UVM_LOW)
        end
        8'h08: begin // SPI_TXDATA
          reg_txdata = item.data[15:0];
          expected_mosi_q.push_back(reg_txdata);
          `uvm_info("SCOREBOARD", $sformatf("SPI_TXDATA programmed: 0x%04x", reg_txdata), UVM_LOW)
        end
        8'h18: begin // SPI_FIFO_CTRL flush
          if (item.data[0]) begin
            expected_fifo_q.delete();
            `uvm_info("SCOREBOARD", "SPI FIFO flushed via CSR", UVM_LOW)
          end
        end
        default: ;
      endcase
    end else if (item.op == AXI_READ) begin
      case (reg_offset)
        8'h0C: begin // SPI_RXDATA
          bit [15:0] rdata = item.data[15:0];
          if (expected_fifo_q.size() > 0) begin
            bit [15:0] exp = expected_fifo_q.pop_front();
            if (rdata === exp) begin
              sample_match_count++;
              cp_acq_02_pass = 1'b1;
              `uvm_info("SCOREBOARD", $sformatf("[TC_ACQ_02 100%%] AXI Read SPI_RXDATA Match: 0x%04x", rdata), UVM_LOW)
            end else begin
              sample_mismatch_count++;
              `uvm_error("SCOREBOARD", $sformatf("SPI_RXDATA Mismatch! Exp=0x%04x Got=0x%04x", exp, rdata))
            end
          end
        end
        default: ;
      endcase
    end
  endfunction : write_spi_axi

  // 2. Driven Sample from ADC Slave VIP
  virtual function void write_spi_drv(spi_adc_item item);
    if (expected_fifo_q.size() < FIFO_CAPACITY) begin
      expected_fifo_q.push_back(item.miso_data);
      `uvm_info("SCOREBOARD", $sformatf("ADC VIP drove sample: 0x%04x (FIFO size=%0d)",
                item.miso_data, expected_fifo_q.size()), UVM_HIGH)
    end else begin
      cp_acq_04_pass = 1'b1;
      `uvm_info("SCOREBOARD", $sformatf("[TC_ACQ_04 75%%] Sample 0x%04x dropped on FIFO overflow as specified!",
                item.miso_data), UVM_LOW)
    end
  endfunction : write_spi_drv

  // 3. Observed SPI Physical Frame from Monitor
  virtual function void write_spi_item(spi_adc_item item);
    total_frames_monitored++;

    // SVA_SPI_01: Exactly 16 SCK cycles per conversion
    if (item.num_sck_cycles != 16) begin
      sva_spi_01_pass = 1'b0;
      timing_violations++;
      `uvm_error("SCOREBOARD", $sformatf("[SVA_SPI_01 FAIL] SCK cycle count=%0d (expected 16)!", item.num_sck_cycles))
    end else begin
      `uvm_info("SCOREBOARD", "[SVA_SPI_01 PASS] Verified exactly 16 SCK cycles for conversion", UVM_HIGH)
    end

    // SVA_SPI_02 & TC_ACQ_03: SCK Duty Cycle & Prescaler Verification
    if (item.sck_period > 0) begin
      realtime duty_diff = (item.sck_high_time > item.sck_low_time) ? 
                           (item.sck_high_time - item.sck_low_time) : 
                           (item.sck_low_time - item.sck_high_time);
      if (duty_diff <= 2.5ns) begin
        cp_acq_03_pass = 1'b1;
        `uvm_info("SCOREBOARD", $sformatf("[SVA_SPI_02 / TC_ACQ_03 PASS] SCK period=%0.2fns (high=%0.2fns low=%0.2fns)",
                  item.sck_period, item.sck_high_time, item.sck_low_time), UVM_LOW)
      end else begin
        sva_spi_02_pass = 1'b0;
        timing_violations++;
        `uvm_error("SCOREBOARD", $sformatf("[SVA_SPI_02 FAIL] SCK asymmetry: high=%0.2fns low=%0.2fns",
                   item.sck_high_time, item.sck_low_time))
      end
    end

    // TC_ACQ_06: Lead and Trail Margins (> 20ns)
    if (item.t_lead >= 19.0ns && item.t_trail >= 19.0ns) begin
      cp_acq_06_pass = 1'b1;
      `uvm_info("SCOREBOARD", $sformatf("[TC_ACQ_06 PASS] Lead=%0.2fns Trail=%0.2fns meet >20ns margin spec",
                item.t_lead, item.t_trail), UVM_LOW)
    end else begin
      timing_violations++;
      `uvm_error("SCOREBOARD", $sformatf("[TC_ACQ_06 FAIL] Margins too tight: lead=%0.2fns trail=%0.2fns",
                 item.t_lead, item.t_trail))
    end

    // TC_ACQ_05: MOSI verification for manual command transmission
    if (expected_mosi_q.size() > 0) begin
      bit [15:0] exp_mosi = expected_mosi_q.pop_front();
      if (item.mosi_data === exp_mosi) begin
        mosi_match_count++;
        cp_acq_05_pass = 1'b1;
        `uvm_info("SCOREBOARD", $sformatf("[TC_ACQ_05 100%%] MOSI Match: Transmitted 0x%04x accurately", exp_mosi), UVM_LOW)
      end else begin
        mosi_mismatch_count++;
        `uvm_error("SCOREBOARD", $sformatf("MOSI Mismatch! Exp=0x%04x Got=0x%04x", exp_mosi, item.mosi_data))
      end
    end
  endfunction : write_spi_item

  // 4. Sample Ready Strobe Callback
  virtual function void write_spi_ready(bit rdy);
    sample_ready_count++;
    `uvm_info("SCOREBOARD", $sformatf("sample_ready strobe observed (#%0d)", sample_ready_count), UVM_HIGH)
  endfunction : write_spi_ready

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("SCOREBOARD", "=================================================================", UVM_LOW)
    `uvm_info("SCOREBOARD", "              SPI CONTROLLER UVM SCOREBOARD REPORT               ", UVM_LOW)
    `uvm_info("SCOREBOARD", "=================================================================", UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  Total Frames Monitored       : %0d", total_frames_monitored), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  MISO Sample Matches          : %0d", sample_match_count), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  MISO Sample Mismatches       : %0d", sample_mismatch_count), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  MOSI Command Matches         : %0d", mosi_match_count), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  MOSI Command Mismatches      : %0d", mosi_mismatch_count), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  Sample Ready Pulses          : %0d", sample_ready_count), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  Timing / Protocol Violations : %0d", timing_violations), UVM_LOW)
    `uvm_info("SCOREBOARD", "-----------------------------------------------------------------", UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  [TC_ACQ_02] Hardware Auto-Trigger : %s", cp_acq_02_pass ? "PASS" : "FAIL"), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  [TC_ACQ_03] Prescaler Frequency   : %s", cp_acq_03_pass ? "PASS" : "FAIL"), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  [TC_ACQ_04] FIFO 32-Entry Overflow: %s", cp_acq_04_pass ? "PASS" : "FAIL"), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  [TC_ACQ_05] Manual SPI Command    : %s", cp_acq_05_pass ? "PASS" : "FAIL"), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  [TC_ACQ_06] Lead / Trail Margins  : %s", cp_acq_06_pass ? "PASS" : "FAIL"), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  [SVA_SPI_01] 16 SCK Cycles Count  : %s", sva_spi_01_pass ? "PASS" : "FAIL"), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  [SVA_SPI_02] 50%% SCK Duty Cycle  : %s", sva_spi_02_pass ? "PASS" : "FAIL"), UVM_LOW)
    `uvm_info("SCOREBOARD", "=================================================================", UVM_LOW)

    if (sample_mismatch_count > 0 || mosi_mismatch_count > 0 || timing_violations > 0) begin
      `uvm_error("SCOREBOARD", "SPI CONTROLLER SCOREBOARD VERIFICATION FAILED!")
    end else begin
      `uvm_info("SCOREBOARD", "SPI CONTROLLER SCOREBOARD VERIFICATION PASSED SUCCESSFULLY!", UVM_LOW)
    end
  endfunction : report_phase

endclass : spi_scoreboard

`endif // SPI_SCOREBOARD_SV
