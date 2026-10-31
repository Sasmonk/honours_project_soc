// =============================================================================
// Scoreboard   : timer_scoreboard.sv
// Description  : Golden Scoreboard for System Timer Verification (TC_ACQ_01)
// =============================================================================
`ifndef TIMER_SCOREBOARD_SV
`define TIMER_SCOREBOARD_SV

`uvm_analysis_imp_decl(_timer_axi)
`uvm_analysis_imp_decl(_timer_pulse)

class timer_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(timer_scoreboard)

  uvm_analysis_imp_timer_axi   #(axi_item, timer_scoreboard)         axi_export;
  uvm_analysis_imp_timer_pulse #(timer_pulse_item, timer_scoreboard) pulse_export;

  // Tracked Register State
  bit        reg_timer_en     = 1'b0;
  bit [31:0] reg_timer_reload = 32'd0;
  bit        reg_timer_tick   = 1'b0;
  bit        first_tick_after_reconfig = 1'b1;

  // Checkpoints for TC_ACQ_01
  bit cp_25_reload_programmed = 1'b0;
  bit cp_50_timer_enabled     = 1'b0;
  bit cp_75_tick_observed     = 1'b0;
  bit cp_100_period_verified  = 1'b0;
  bit cp_100_irq_verified     = 1'b0;
  bit cp_100_w1c_cleared      = 1'b0;

  // Match & Error Statistics
  int unsigned period_match_count    = 0;
  int unsigned period_mismatch_count = 0;
  int unsigned tick_count            = 0;
  int unsigned irq_assert_count      = 0;
  int unsigned irq_clear_count       = 0;
  int unsigned reg_read_match_count  = 0;
  int unsigned reg_read_error_count  = 0;

  function new(string name = "timer_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    axi_export   = new("axi_export", this);
    pulse_export = new("pulse_export", this);
  endfunction : new

  // 1. AXI Bus Callback
  virtual function void write_timer_axi(axi_item item);
    bit [3:0] reg_offset = item.addr[3:0];

    if (item.op == AXI_WRITE) begin
      case (reg_offset)
        4'h0: begin
          reg_timer_en = item.data[0];
          if (reg_timer_en) begin
            cp_50_timer_enabled = 1'b1;
            `uvm_info("SCOREBOARD", "[TC_ACQ_01 50%%] Checkpoint: TIMER_CTRL.EN=1 enabled", UVM_LOW)
          end else begin
            first_tick_after_reconfig = 1'b1;
          end
        end
        4'h4: begin
          reg_timer_reload = item.data;
          first_tick_after_reconfig = 1'b1;
          cp_25_reload_programmed = 1'b1;
          `uvm_info("SCOREBOARD", $sformatf("[TC_ACQ_01 25%%] Checkpoint: TIMER_RELOAD=%0d written", reg_timer_reload), UVM_LOW)
        end
        4'hC: begin
          if (item.data[0]) begin
            reg_timer_tick = 1'b0;
            `uvm_info("SCOREBOARD", "AXI W1C write to TIMER_STATUS.TICK received", UVM_HIGH)
          end
        end
        default: ;
      endcase
    end else if (item.op == AXI_READ) begin
      case (reg_offset)
        4'h0: begin
          if (item.data[0] === reg_timer_en) begin
            reg_read_match_count++;
          end else begin
            reg_read_error_count++;
            `uvm_error("SCOREBOARD", $sformatf("TIMER_CTRL mismatch: exp=%b act=%b", reg_timer_en, item.data[0]))
          end
        end
        4'h4: begin
          if (item.data === reg_timer_reload) begin
            reg_read_match_count++;
          end else begin
            reg_read_error_count++;
            `uvm_error("SCOREBOARD", $sformatf("TIMER_RELOAD mismatch: exp=0x%08x act=0x%08x", reg_timer_reload, item.data))
          end
        end
        4'hC: begin
          `uvm_info("SCOREBOARD", $sformatf("TIMER_STATUS read: 0x%08x", item.data), UVM_HIGH)
        end
        default: ;
      endcase
    end
  endfunction : write_timer_axi

  // 2. Pulse & Interrupt Callback
  virtual function void write_timer_pulse(timer_pulse_item item);
    if (item.sample_tick) begin
      tick_count++;
      cp_75_tick_observed = 1'b1;
      `uvm_info("SCOREBOARD", $sformatf("[TC_ACQ_01 75%%] Checkpoint: sample_tick pulse observed (#%0d)", tick_count), UVM_LOW)

      if (first_tick_after_reconfig) begin
        first_tick_after_reconfig = 1'b0;
        `uvm_info("SCOREBOARD", "First tick after enable/reconfig observed (syncing period measurement)", UVM_LOW)
      end else if (item.cycle_period > 0) begin
        int unsigned expected_period = reg_timer_reload + 1;
        if (item.cycle_period == expected_period) begin
          period_match_count++;
          cp_100_period_verified = 1'b1;
          `uvm_info("SCOREBOARD", $sformatf("[TC_ACQ_01 100%%] Checkpoint: Cycle-accurate period MATCH: %0d cycles (expected %0d)",
                    item.cycle_period, expected_period), UVM_LOW)
        end else begin
          period_mismatch_count++;
          `uvm_error("SCOREBOARD", $sformatf("Period MISMATCH: measured %0d cycles, expected %0d cycles",
                     item.cycle_period, expected_period))
        end
      end
    end

    if (item.irq_timer) begin
      irq_assert_count++;
      cp_100_irq_verified = 1'b1;
      `uvm_info("SCOREBOARD", "[TC_ACQ_01 100%%] Checkpoint: irq_timer asserted on tick", UVM_LOW)
    end else if (!item.irq_timer && cp_100_irq_verified) begin
      irq_clear_count++;
      cp_100_w1c_cleared = 1'b1;
      `uvm_info("SCOREBOARD", "[TC_ACQ_01 100%%] Checkpoint: irq_timer deasserted after W1C clear", UVM_LOW)
    end
  endfunction : write_timer_pulse

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("SCOREBOARD", "=================================================================", UVM_LOW)
    `uvm_info("SCOREBOARD", "               TIMER UVM SCOREBOARD FINAL REPORT                 ", UVM_LOW)
    `uvm_info("SCOREBOARD", "=================================================================", UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  Total Sample Ticks Observed : %0d", tick_count), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  Cycle Period Matches        : %0d", period_match_count), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  Cycle Period Mismatches     : %0d", period_mismatch_count), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  IRQ Assertions              : %0d", irq_assert_count), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  IRQ Clears (W1C)            : %0d", irq_clear_count), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  Register Read Matches       : %0d", reg_read_match_count), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  Register Read Errors        : %0d", reg_read_error_count), UVM_LOW)
    `uvm_info("SCOREBOARD", "-----------------------------------------------------------------", UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  [TC_ACQ_01 25%%] Reload Programmed : %s", cp_25_reload_programmed ? "PASS" : "FAIL"), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  [TC_ACQ_01 50%%] Timer Enabled     : %s", cp_50_timer_enabled ? "PASS" : "FAIL"), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  [TC_ACQ_01 75%%] Tick Observed     : %s", cp_75_tick_observed ? "PASS" : "FAIL"), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  [TC_ACQ_01 100%%] Period Verified  : %s", cp_100_period_verified ? "PASS" : "FAIL"), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  [TC_ACQ_01 100%%] IRQ Verified     : %s", cp_100_irq_verified ? "PASS" : "FAIL"), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  [TC_ACQ_01 100%%] W1C Cleared      : %s", cp_100_w1c_cleared ? "PASS" : "FAIL"), UVM_LOW)
    `uvm_info("SCOREBOARD", "=================================================================", UVM_LOW)

    if (period_mismatch_count > 0 || reg_read_error_count > 0) begin
      `uvm_error("SCOREBOARD", "TIMER SCOREBOARD VERIFICATION FAILED!")
    end else begin
      `uvm_info("SCOREBOARD", "TIMER SCOREBOARD VERIFICATION PASSED SUCCESSFULLY!", UVM_LOW)
    end
  endfunction : report_phase

endclass : timer_scoreboard

`endif // TIMER_SCOREBOARD_SV
