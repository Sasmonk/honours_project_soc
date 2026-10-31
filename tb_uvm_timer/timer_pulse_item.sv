// =============================================================================
// Item         : timer_pulse_item.sv
// Description  : Sequence item for Timer pulse and interrupt monitoring
// =============================================================================
`ifndef TIMER_PULSE_ITEM_SV
`define TIMER_PULSE_ITEM_SV

class timer_pulse_item extends uvm_sequence_item;
  `uvm_object_utils(timer_pulse_item)

  bit          sample_tick;
  bit          irq_timer;
  int unsigned cycle_period;
  realtime     timestamp;

  function new(string name = "timer_pulse_item");
    super.new(name);
  endfunction

  virtual function string convert2string();
    return $sformatf("sample_tick=%b irq_timer=%b cycle_period=%0d @%0t",
                     sample_tick, irq_timer, cycle_period, timestamp);
  endfunction

endclass : timer_pulse_item

`endif // TIMER_PULSE_ITEM_SV
