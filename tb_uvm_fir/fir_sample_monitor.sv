// =============================================================================
// Monitor      : fir_sample_monitor.sv
// Description  : Cycle-accurate monitor observing FIR output samples and IRQs
// =============================================================================
`ifndef FIR_SAMPLE_MONITOR_SV
`define FIR_SAMPLE_MONITOR_SV

class fir_sample_monitor extends uvm_monitor;
  `uvm_component_utils(fir_sample_monitor)

  virtual fir_sample_if vif;
  uvm_analysis_port #(fir_sample_item) item_collected_port;
  uvm_analysis_port #(bit)             irq_ap;

  function new(string name = "fir_sample_monitor", uvm_component parent = null);
    super.new(name, parent);
    item_collected_port = new("item_collected_port", this);
    irq_ap              = new("irq_ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual fir_sample_if)::get(this, "", "fir_vif", vif)) begin
      `uvm_fatal("NOVIF", "virtual fir_sample_if not found in config_db")
    end
  endfunction

  task run_phase(uvm_phase phase);
    bit prev_irq = 1'b0;

    @(posedge vif.rst_n);

    forever begin
      @(posedge vif.clk);

      if (vif.fir_sample_valid_out) begin
        fir_sample_item item = fir_sample_item::type_id::create("item");
        item.sample_data = vif.fir_sample_out;
        item.is_input    = 1'b0;
        item.timestamp   = $realtime;
        item_collected_port.write(item);

        `uvm_info("FIR_MON", $sformatf("Sample Out: 0x%04x (%0d)", item.sample_data, item.sample_data), UVM_HIGH)
      end

      if (vif.irq_fir != prev_irq) begin
        irq_ap.write(vif.irq_fir);
        `uvm_info("FIR_MON", $sformatf("irq_fir transition: %b", vif.irq_fir), UVM_HIGH)
      end

      prev_irq = vif.irq_fir;
    end
  endtask

endclass : fir_sample_monitor

`endif // FIR_SAMPLE_MONITOR_SV
