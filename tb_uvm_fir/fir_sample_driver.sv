// =============================================================================
// Driver       : fir_sample_driver.sv
// Description  : UVM Driver injecting streaming samples into FIR filter
// =============================================================================
`ifndef FIR_SAMPLE_DRIVER_SV
`define FIR_SAMPLE_DRIVER_SV

class fir_sample_driver extends uvm_driver #(fir_sample_item);
  `uvm_component_utils(fir_sample_driver)

  virtual fir_sample_if vif;
  uvm_analysis_port #(fir_sample_item) drv_ap;

  function new(string name = "fir_sample_driver", uvm_component parent = null);
    super.new(name, parent);
    drv_ap = new("drv_ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual fir_sample_if)::get(this, "", "fir_vif", vif)) begin
      `uvm_fatal("NOVIF", "virtual fir_sample_if not found in config_db")
    end
  endfunction

  task run_phase(uvm_phase phase);
    vif.fir_sample_in       <= 16'sd0;
    vif.fir_sample_valid_in <= 1'b0;

    @(posedge vif.rst_n);

    forever begin
      seq_item_port.get_next_item(req);
      drive_sample(req.sample_data);
      seq_item_port.item_done();
    end
  endtask

  task drive_sample(bit signed [15:0] data);
    @(posedge vif.clk);
    vif.fir_sample_in       <= data;
    vif.fir_sample_valid_in <= 1'b1;

    begin
      fir_sample_item item = fir_sample_item::type_id::create("drv_item");
      item.sample_data = data;
      item.is_input    = 1'b1;
      item.timestamp   = $realtime;
      drv_ap.write(item);
    end

    @(posedge vif.clk);
    vif.fir_sample_valid_in <= 1'b0;
    vif.fir_sample_in       <= 16'sd0;
  endtask

endclass : fir_sample_driver

`endif // FIR_SAMPLE_DRIVER_SV
