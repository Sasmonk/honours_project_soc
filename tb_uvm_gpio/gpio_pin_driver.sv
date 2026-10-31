// =============================================================================
// Driver      : gpio_pin_driver.sv
// Description : Asynchronous / Synchronous Push-Button Edge Driver for gpio_in
// =============================================================================
`ifndef GPIO_PIN_DRIVER_SV
`define GPIO_PIN_DRIVER_SV

class gpio_pin_driver extends uvm_driver #(gpio_pin_item);
  `uvm_component_utils(gpio_pin_driver)

  virtual gpio_pin_if vif;
  uvm_analysis_port #(gpio_pin_item) ap;

  function new(string name = "gpio_pin_driver", uvm_component parent = null);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual gpio_pin_if)::get(this, "", "pin_vif", vif)) begin
      `uvm_fatal("GPIO_PIN_DRV", "Virtual interface gpio_pin_if not found in config_db!")
    end
  endfunction : build_phase

  virtual task run_phase(uvm_phase phase);
    vif.gpio_in <= 8'd0;
    @(posedge vif.rst_n);
    @(posedge vif.clk);

    forever begin
      seq_item_port.get_next_item(req);
      repeat (req.delay_cycles) @(posedge vif.clk);
      vif.gpio_in <= req.pin_val;
      req.timestamp = $realtime;
      ap.write(req);
      `uvm_info("GPIO_DRV", $sformatf("Injected gpio_in transition to 0x%02h", req.pin_val), UVM_HIGH)
      seq_item_port.item_done();
    end
  endtask : run_phase
endclass : gpio_pin_driver

`endif // GPIO_PIN_DRIVER_SV
