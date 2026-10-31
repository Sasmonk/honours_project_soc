// =============================================================================
// Coverage     : watchdog_coverage.sv
// Description  : Functional Coverage for Watchdog Safety Supervisory Subsystem
// =============================================================================
`ifndef WATCHDOG_COVERAGE_SV
`define WATCHDOG_COVERAGE_SV

class watchdog_coverage extends uvm_subscriber #(wdt_safety_item);
  `uvm_component_utils(watchdog_coverage)

  // Monitored transaction fields
  bit       nmi_prewarn;
  bit       wdt_reset_out;
  bit [3:0] pipeline_alive;
  bit [31:0] current_reload;
  int        current_kick_interval;

  uvm_analysis_imp_wdt_axi #(axi_item, watchdog_coverage) axi_cov_export;

  covergroup cg_safety_supervisory;
    option.per_instance = 1;
    option.comment = "Watchdog Safety and Supervisory Functional Coverage";

    // Reload duration ranges
    cp_reload_duration: coverpoint current_reload {
      bins short_timeout  = {[100:500]};
      bins medium_timeout = {[501:2000]};
      bins long_timeout   = {[2001:100000]};
    }

    // NMI invocation
    cp_nmi_prewarn: coverpoint nmi_prewarn {
      bins no_nmi  = {1'b0};
      bins nmi_hit = {1'b1};
    }

    // Fatal hard reset
    cp_wdt_reset: coverpoint wdt_reset_out {
      bins no_reset  = {1'b0};
      bins reset_hit = {1'b1};
    }

    // Pipeline liveness heartbeat taps
    cp_pipeline_alive: coverpoint pipeline_alive {
      bins idle_taps   = {4'b0000};
      bins single_taps = {4'b0001, 4'b0010, 4'b0100, 4'b1000};
      bins all_active  = {4'b1111};
    }

    // Cross between reset and nmi
    cross_nmi_reset: cross cp_nmi_prewarn, cp_wdt_reset;

  endgroup : cg_safety_supervisory

  function new(string name = "watchdog_coverage", uvm_component parent = null);
    super.new(name, parent);
    cg_safety_supervisory = new();
    axi_cov_export = new("axi_cov_export", this);
  endfunction : new

  virtual function void write(wdt_safety_item t);
    nmi_prewarn    = t.nmi_prewarn;
    wdt_reset_out  = t.wdt_reset_out;
    pipeline_alive = t.pipeline_alive;
    cg_safety_supervisory.sample();
  endfunction : write

  virtual function void write_wdt_axi(axi_item item);
    if (item.op == AXI_WRITE && item.addr[3:0] == 4'h4) begin
      current_reload = item.data;
    end
  endfunction : write_wdt_axi

endclass : watchdog_coverage

`endif // WATCHDOG_COVERAGE_SV
