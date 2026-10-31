// =============================================================================
// Scoreboard   : watchdog_scoreboard.sv
// Description  : Scoreboard for Watchdog Safety Monitor (TC_WDT_01, SVA_WDT_01/02)
// =============================================================================
`ifndef WATCHDOG_SCOREBOARD_SV
`define WATCHDOG_SCOREBOARD_SV

`uvm_analysis_imp_decl(_wdt_axi)
`uvm_analysis_imp_decl(_wdt_safety)

class watchdog_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(watchdog_scoreboard)

  uvm_analysis_imp_wdt_axi    #(axi_item, watchdog_scoreboard)        axi_export;
  uvm_analysis_imp_wdt_safety #(wdt_safety_item, watchdog_scoreboard) safety_export;

  // Tracked State
  bit        reg_wdt_en     = 1'b0;
  bit [31:0] reg_wdt_reload = 32'hFFFF_FFFF;
  int        kick_count     = 0;

  // Checkpoints for TC_WDT_01
  bit cp_25_wdt_armed      = 1'b0;
  bit cp_50_kicks_verified = 1'b0;
  bit cp_75_nmi_observed   = 1'b0;
  bit cp_100_reset_tripped = 1'b0;
  bit sva_wdt_02_pass      = 1'b0;

  // Statistics
  int unsigned nmi_count            = 0;
  int unsigned reset_count          = 0;
  int unsigned unexpected_nmi_count = 0;
  int unsigned unexpected_rst_count = 0;
  int unsigned timing_error_count   = 0;

  function new(string name = "watchdog_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    axi_export    = new("axi_export", this);
    safety_export = new("safety_export", this);
  endfunction : new

  // 1. AXI CSR Callback
  virtual function void write_wdt_axi(axi_item item);
    bit [3:0] reg_offset = item.addr[3:0];

    if (item.op == AXI_WRITE) begin
      case (reg_offset)
        4'h0: begin
          reg_wdt_en = item.data[0];
          if (reg_wdt_en && cp_25_wdt_armed) begin
            `uvm_info("SCOREBOARD", "[TC_WDT_01 25%%] Checkpoint: WDT Armed (EN=1)", UVM_LOW)
          end
        end
        4'h4: begin
          reg_wdt_reload = item.data;
          cp_25_wdt_armed = 1'b1;
          `uvm_info("SCOREBOARD", $sformatf("[TC_WDT_01 25%%] Checkpoint: WDT_RELOAD=0x%08x written", reg_wdt_reload), UVM_LOW)
        end
        4'h8: begin
          kick_count++;
          `uvm_info("SCOREBOARD", $sformatf("WDT Software Kick received (#%0d)", kick_count), UVM_HIGH)
          if (kick_count >= 3 && !cp_75_nmi_observed) begin
            cp_50_kicks_verified = 1'b1;
            `uvm_info("SCOREBOARD", "[TC_WDT_01 50%%] Checkpoint: Software Keep-Alive Kicks Verified Safe", UVM_LOW)
          end
        end
        default: ;
      endcase
    end else if (item.op == AXI_READ) begin
      case (reg_offset)
        4'hC: begin
          bit prewarn = item.data[0];
          bit tripped = item.data[1];
          `uvm_info("SCOREBOARD", $sformatf("WDT_STATUS read: prewarn=%b tripped=%b", prewarn, tripped), UVM_LOW)
        end
        default: ;
      endcase
    end
  endfunction : write_wdt_axi

  // 2. Safety Monitor Callback
  virtual function void write_wdt_safety(wdt_safety_item item);
    if (item.nmi_prewarn) begin
      nmi_count++;
      cp_75_nmi_observed = 1'b1;
      `uvm_info("SCOREBOARD", "[TC_WDT_01 75%%] Checkpoint: nmi_prewarn pulse observed on timeout countdown to 1", UVM_LOW)
    end

    if (item.wdt_reset_out) begin
      reset_count++;
      cp_100_reset_tripped = 1'b1;
      `uvm_info("SCOREBOARD", "[TC_WDT_01 100%%] Checkpoint: wdt_reset_out pulse observed on countdown reach 0!", UVM_LOW)

      // Verify SVA_WDT_02: nmi_prewarn precedes wdt_reset_out by exactly 1 clock cycle!
      if (item.cycles_since_nmi == 1) begin
        sva_wdt_02_pass = 1'b1;
        `uvm_info("SCOREBOARD", "[SVA_WDT_02 PASS] nmi_prewarn pulsed strictly 1 clock cycle before wdt_reset_out!", UVM_LOW)
      end else begin
        timing_error_count++;
        `uvm_error("SCOREBOARD", $sformatf("[SVA_WDT_02 FAIL] wdt_reset_out occurred %0d cycles after nmi_prewarn (expected 1)!",
                   item.cycles_since_nmi))
      end
    end
  endfunction : write_wdt_safety

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("SCOREBOARD", "=================================================================", UVM_LOW)
    `uvm_info("SCOREBOARD", "             WATCHDOG UVM SCOREBOARD FINAL REPORT                ", UVM_LOW)
    `uvm_info("SCOREBOARD", "=================================================================", UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  Software Kicks Received     : %0d", kick_count), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  NMI Pre-warnings Captured   : %0d", nmi_count), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  Fatal Resets Captured       : %0d", reset_count), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  Timing / SVA Errors         : %0d", timing_error_count), UVM_LOW)
    `uvm_info("SCOREBOARD", "-----------------------------------------------------------------", UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  [TC_WDT_01 25%%] Reload & Arm        : %s", cp_25_wdt_armed ? "PASS" : "FAIL"), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  [TC_WDT_01 50%%] Kicks Kept Safe     : %s", cp_50_kicks_verified ? "PASS" : "FAIL"), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  [TC_WDT_01 75%%] NMI Pre-warn        : %s", cp_75_nmi_observed ? "PASS" : "FAIL"), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  [TC_WDT_01 100%%] Reset Tripped      : %s", cp_100_reset_tripped ? "PASS" : "FAIL"), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  [SVA_WDT_02] 1-Cycle Lead Timing    : %s", sva_wdt_02_pass ? "PASS" : "FAIL"), UVM_LOW)
    `uvm_info("SCOREBOARD", "=================================================================", UVM_LOW)

    if (timing_error_count > 0 || !cp_100_reset_tripped || !sva_wdt_02_pass) begin
      `uvm_error("SCOREBOARD", "WATCHDOG SCOREBOARD VERIFICATION FAILED!")
    end else begin
      `uvm_info("SCOREBOARD", "WATCHDOG SCOREBOARD VERIFICATION PASSED SUCCESSFULLY!", UVM_LOW)
    end
  endfunction : report_phase

endclass : watchdog_scoreboard

`endif // WATCHDOG_SCOREBOARD_SV
