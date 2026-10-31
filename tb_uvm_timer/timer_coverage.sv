// =============================================================================
// Coverage     : timer_coverage.sv
// Description  : Functional Coverage for System Timer Subsystem (cg_acquisition_timing)
// =============================================================================
`ifndef TIMER_COVERAGE_SV
`define TIMER_COVERAGE_SV

class timer_coverage extends uvm_subscriber #(timer_pulse_item);
  `uvm_component_utils(timer_coverage)

  // Monitored transaction fields
  bit          sample_tick;
  bit          irq_timer;
  int unsigned cycle_period;
  bit [31:0]   current_reload;

  // Analysis export for AXI items to track programmed reload
  uvm_analysis_imp_timer_axi #(axi_item, timer_coverage) axi_cov_export;

  covergroup cg_acquisition_timing;
    option.per_instance = 1;
    option.comment = "System Timer Rate Pacing Functional Coverage";

    // Reload value ranges
    cp_reload_range: coverpoint current_reload {
      bins fast_rate   = {[10:50]};
      bins medium_rate = {[51:500]};
      bins slow_rate   = {[501:10000]};
    }

    // Tick pulse
    cp_sample_tick: coverpoint sample_tick {
      bins no_tick = {1'b0};
      bins tick    = {1'b1};
    }

    // IRQ flag
    cp_irq_timer: coverpoint irq_timer {
      bins irq_low  = {1'b0};
      bins irq_high = {1'b1};
    }

    // Period match bins
    cp_period: coverpoint cycle_period {
      bins period_zero   = {0};
      bins period_fast   = {[11:51]};
      bins period_medium = {[52:501]};
    }

    // Cross between reload range and tick pulse
    cross_reload_tick: cross cp_reload_range, cp_sample_tick;

  endgroup : cg_acquisition_timing

  function new(string name = "timer_coverage", uvm_component parent = null);
    super.new(name, parent);
    cg_acquisition_timing = new();
    axi_cov_export = new("axi_cov_export", this);
  endfunction : new

  virtual function void write(timer_pulse_item t);
    sample_tick  = t.sample_tick;
    irq_timer    = t.irq_timer;
    cycle_period = t.cycle_period;
    cg_acquisition_timing.sample();
  endfunction : write

  virtual function void write_timer_axi(axi_item item);
    if (item.op == AXI_WRITE && item.addr[3:0] == 4'h4) begin
      current_reload = item.data;
    end
  endfunction : write_timer_axi

endclass : timer_coverage

`endif // TIMER_COVERAGE_SV
