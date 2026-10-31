// =============================================================================
// Monitor     : gpio_pin_monitor.sv
// Description : Real-Time Monitor for gpio_out Status LEDs & irq_gpio Line
// =============================================================================
`ifndef GPIO_PIN_MONITOR_SV
`define GPIO_PIN_MONITOR_SV

class gpio_pin_monitor extends uvm_monitor;
  `uvm_component_utils(gpio_pin_monitor)

  virtual gpio_pin_if vif;
  uvm_analysis_port #(gpio_pin_item) ap;
  uvm_analysis_port #(bit)           irq_ap;

  function new(string name = "gpio_pin_monitor", uvm_component parent = null);
    super.new(name, parent);
    ap     = new("ap", this);
    irq_ap = new("irq_ap", this);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual gpio_pin_if)::get(this, "", "pin_vif", vif)) begin
      `uvm_fatal("GPIO_PIN_MON", "Virtual interface gpio_pin_if not found in config_db!")
    end
  endfunction : build_phase

  virtual task run_phase(uvm_phase phase);
    fork
      monitor_led_outputs();
      monitor_irq_transitions();
    join
  endtask : run_phase

  virtual task monitor_led_outputs();
    bit [7:0] prev_out = 8'h00;
    @(posedge vif.rst_n);

    forever begin
      @(posedge vif.clk);
      if (vif.gpio_out !== prev_out) begin
        gpio_pin_item item = gpio_pin_item::type_id::create("led_item");
        prev_out        = vif.gpio_out;
        item.out_val    = vif.gpio_out;
        item.irq_val    = vif.irq_gpio;
        item.timestamp  = $realtime;
        `uvm_info("GPIO_LED_MON", $sformatf("Observed gpio_out change: 0x%02h", vif.gpio_out), UVM_HIGH)
        ap.write(item);
      end
    end
  endtask : monitor_led_outputs

  virtual task monitor_irq_transitions();
    bit prev_irq = 1'b0;
    @(posedge vif.rst_n);

    forever begin
      @(vif.irq_gpio);
      if (vif.irq_gpio !== prev_irq) begin
        prev_irq = vif.irq_gpio;
        `uvm_info("GPIO_IRQ_MON", $sformatf("irq_gpio transitioned to %0b at %0t", vif.irq_gpio, $time), UVM_HIGH)
        irq_ap.write(vif.irq_gpio);
      end
    end
  endtask : monitor_irq_transitions
endclass : gpio_pin_monitor

`endif // GPIO_PIN_MONITOR_SV
