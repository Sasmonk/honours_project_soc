// =============================================================================
// Scoreboard  : axi_scoreboard.sv
// Description : Golden Reference Memory & Data Integrity Checker
// =============================================================================
`ifndef AXI_SCOREBOARD_SV
`define AXI_SCOREBOARD_SV

class axi_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(axi_scoreboard)

  uvm_analysis_imp #(axi_item, axi_scoreboard) item_export;

  // Golden Associative Memory Model
  bit [31:0] mem_model [bit [31:0]];
  int match_count = 0;
  int mismatch_count = 0;

  function new(string name = "axi_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    item_export = new("item_export", this);
  endfunction : new

  virtual function void write(axi_item item);
    if (item.op == AXI_WRITE) begin
      mem_model[item.addr] = item.data;
      `uvm_info("SB_WRITE", $sformatf("Logged Write: Addr=0x%08h Data=0x%08h", item.addr, item.data), UVM_HIGH)
    end else begin
      if (mem_model.exists(item.addr)) begin
        if (mem_model[item.addr] === item.data) begin
          match_count++;
          `uvm_info("SB_MATCH", $sformatf("Read Addr=0x%08h Data=0x%08h Matches Golden Model!", item.addr, item.data), UVM_MEDIUM)
        end else begin
          mismatch_count++;
          `uvm_error("SB_MISMATCH", $sformatf("Read Addr=0x%08h Data=0x%08h Expected=0x%08h!", item.addr, item.data, mem_model[item.addr]))
        end
      end else begin
        `uvm_info("SB_UNINITIALIZED", $sformatf("Read from unwritten Addr=0x%08h Data=0x%08h", item.addr, item.data), UVM_HIGH)
      end
    end
  endfunction : write

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("SCOREBOARD_REPORT", $sformatf("Total Matches: %0d | Total Mismatches: %0d", match_count, mismatch_count), UVM_LOW)
    if (mismatch_count == 0) begin
      `uvm_info("SCOREBOARD_STATUS", "*** ALL SCOREBOARD COMPARISONS PASSED! ***", UVM_LOW)
    end else begin
      `uvm_error("SCOREBOARD_STATUS", "*** SCOREBOARD DETECTED FAILURES! ***")
    end
  endfunction : report_phase

endclass : axi_scoreboard

`endif // AXI_SCOREBOARD_SV
