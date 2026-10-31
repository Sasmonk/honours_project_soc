// =============================================================================
// Environment  : gpio_env.sv
// Description  : Standard UVM Environment for GPIO VIP
// =============================================================================
`ifndef GPIO_ENV_SV
`define GPIO_ENV_SV

class gpio_env extends uvm_env;
  `uvm_component_utils(gpio_env)

  gpio_agent      agent;
  gpio_scoreboard sb;

  function new(string name = "gpio_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = gpio_agent::type_id::create("agent", this);
    sb    = gpio_scoreboard::type_id::create("sb", this);
  endfunction : build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent.ap.connect(sb.item_export);
  endfunction : connect_phase
endclass : gpio_env

`endif // GPIO_ENV_SV
