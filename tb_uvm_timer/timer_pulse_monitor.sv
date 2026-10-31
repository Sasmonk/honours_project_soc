// =============================================================================
// Monitor      : timer_pulse_monitor.sv
// Description  : Cycle-accurate monitor for Timer sample_tick and irq_timer
// =============================================================================
`ifndef TIMER_PULSE_MONITOR_SV
`define TIMER_PULSE_MONITOR_SV

class timer_pulse_monitor extends uvm_monitor;
  `uvm_component_utils(timer_pulse_monitor)

  virtual timer_pulse_if vif;
  uvm_analysis_port #(timer_pulse_item) item_collected_port;

  function new(string name = "timer_pulse_monitor", uvm_component parent = null);
    super.new(name, parent);
    item_collected_port = new("item_collected_port", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual timer_pulse_if)::get(this, "", "timer_vif", vif)) begin
      `uvm_fatal("NOVIF", "virtual timer_pulse_if not found in config_db")
    end
  endfunction

  task run_phase(uvm_phase phase);
    int unsigned cycle_cnt = 0;
    bit prev_irq = 1'b0;
    bit prev_tick = 1'b0;
    int unsigned cycles_between_ticks = 0;
    bit first_tick_seen = 1'b0;

    @(posedge vif.rst_n);

    forever begin
      @(posedge vif.clk);
      cycle_cnt++;

      if (first_tick_seen) begin
        cycles_between_ticks++;
      end

      if (vif.sample_tick) begin
        timer_pulse_item item = timer_pulse_item::type_id::create("item");
        item.sample_tick   = 1'b1;
        item.irq_timer     = vif.irq_timer;
        item.cycle_period  = first_tick_seen ? cycles_between_ticks : 0;
        item.timestamp     = $realtime;
        item_collected_port.write(item);

        `uvm_info("TIMER_MON", $sformatf("Sample tick observed: period=%0d cycles, irq=%b",
                  item.cycle_period, item.irq_timer), UVM_HIGH)

        cycles_between_ticks = 0;
        first_tick_seen      = 1'b1;
      end else if (vif.irq_timer != prev_irq) begin
        // IRQ level transition (e.g. W1C clear)
        timer_pulse_item item = timer_pulse_item::type_id::create("item");
        item.sample_tick   = 1'b0;
        item.irq_timer     = vif.irq_timer;
        item.cycle_period  = 0;
        item.timestamp     = $realtime;
        item_collected_port.write(item);

        `uvm_info("TIMER_MON", $sformatf("IRQ transition observed: irq=%b", vif.irq_timer), UVM_HIGH)
      end

      prev_irq  = vif.irq_timer;
      prev_tick = vif.sample_tick;
    end
  endtask

endclass : timer_pulse_monitor

`endif // TIMER_PULSE_MONITOR_SV
