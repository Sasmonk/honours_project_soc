// =============================================================================
// Monitor      : wdt_safety_monitor.sv
// Description  : Cycle-accurate safety monitor for Watchdog NMI & Reset signals
// =============================================================================
`ifndef WDT_SAFETY_MONITOR_SV
`define WDT_SAFETY_MONITOR_SV

class wdt_safety_monitor extends uvm_monitor;
  `uvm_component_utils(wdt_safety_monitor)

  virtual wdt_safety_if vif;
  uvm_analysis_port #(wdt_safety_item) item_collected_port;

  function new(string name = "wdt_safety_monitor", uvm_component parent = null);
    super.new(name, parent);
    item_collected_port = new("item_collected_port", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual wdt_safety_if)::get(this, "", "safety_vif", vif)) begin
      `uvm_fatal("NOVIF", "virtual wdt_safety_if not found in config_db")
    end
  endfunction

  task run_phase(uvm_phase phase);
    bit prev_nmi = 1'b0;
    bit prev_rst = 1'b0;
    int nmi_assert_cycle = -100;
    int cycle_cnt = 0;

    @(posedge vif.rst_n);

    forever begin
      @(posedge vif.clk);
      cycle_cnt++;

      if (vif.nmi_prewarn) begin
        nmi_assert_cycle = cycle_cnt;
        `uvm_info("WDT_MON", "nmi_prewarn pulsed HIGH", UVM_HIGH)
      end

      if (vif.nmi_prewarn || vif.wdt_reset_out || (vif.pipeline_alive != 4'h0)) begin
        wdt_safety_item item = wdt_safety_item::type_id::create("item");
        item.nmi_prewarn      = vif.nmi_prewarn;
        item.wdt_reset_out    = vif.wdt_reset_out;
        item.pipeline_alive   = vif.pipeline_alive;
        item.cycles_since_nmi = cycle_cnt - nmi_assert_cycle;
        item.timestamp        = $realtime;
        item_collected_port.write(item);

        if (vif.wdt_reset_out) begin
          `uvm_info("WDT_MON", $sformatf("wdt_reset_out pulsed HIGH (%0d cycles after nmi_prewarn)",
                    item.cycles_since_nmi), UVM_HIGH)
        end
      end

      prev_nmi = vif.nmi_prewarn;
      prev_rst = vif.wdt_reset_out;
    end
  endtask

endclass : wdt_safety_monitor

`endif // WDT_SAFETY_MONITOR_SV
