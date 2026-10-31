// =============================================================================
// Item         : wdt_safety_item.sv
// Description  : Sequence item for Watchdog Safety events (NMI, reset, heartbeats)
// =============================================================================
`ifndef WDT_SAFETY_ITEM_SV
`define WDT_SAFETY_ITEM_SV

class wdt_safety_item extends uvm_sequence_item;
  `uvm_object_utils(wdt_safety_item)

  bit       nmi_prewarn;
  bit       wdt_reset_out;
  bit [3:0] pipeline_alive;
  int       cycles_since_nmi;
  realtime  timestamp;

  function new(string name = "wdt_safety_item");
    super.new(name);
  endfunction

  virtual function string convert2string();
    return $sformatf("nmi=%b reset=%b alive=0x%0x @%0t",
                     nmi_prewarn, wdt_reset_out, pipeline_alive, timestamp);
  endfunction

endclass : wdt_safety_item

`endif // WDT_SAFETY_ITEM_SV
