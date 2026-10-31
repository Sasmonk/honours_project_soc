// =============================================================================
// Environment  : gpio_env.sv
// Description  : UVM Environment for GPIO Verification (comms_ui_env)
// =============================================================================
`ifndef GPIO_ENV_SV
`define GPIO_ENV_SV

class gpio_env extends uvm_env;
  `uvm_component_utils(gpio_env)

  axi_agent       axi_agnt;
  gpio_pin_agent  pin_agnt;
  gpio_scoreboard sb;
  gpio_coverage   cov;

  function new(string name = "gpio_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    axi_agnt = axi_agent::type_id::create("axi_agnt", this);
    pin_agnt = gpio_pin_agent::type_id::create("pin_agnt", this);
    sb       = gpio_scoreboard::type_id::create("sb", this);
    cov      = gpio_coverage::type_id::create("cov", this);
  endfunction : build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // Connect AXI Agent to Scoreboard and Coverage
    axi_agnt.ap.connect(sb.axi_export);
    axi_agnt.ap.connect(cov.axi_export);

    // Connect Pin Monitor to Scoreboard
    pin_agnt.ap.connect(sb.pin_mon_export);

    // Connect Pin Driver to Scoreboard and Coverage
    pin_agnt.drv_ap.connect(sb.pin_drv_export);
    pin_agnt.drv_ap.connect(cov.pin_export);

    // Connect IRQ line to Scoreboard
    pin_agnt.irq_ap.connect(sb.irq_export);
  endfunction : connect_phase

endclass : gpio_env

`endif // GPIO_ENV_SV
