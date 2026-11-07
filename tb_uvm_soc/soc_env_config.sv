// =============================================================================
// File        : soc_env_config.sv
// Description : Top-Level Environment Configuration Object for RISC-V SoC UVM
// =============================================================================
`ifndef SOC_ENV_CONFIG_SV
`define SOC_ENV_CONFIG_SV

class soc_env_config extends uvm_object;
  `uvm_object_utils(soc_env_config)

  // Subsystem VIP Agent Activation Controls
  bit has_uart_agent  = 1'b1;
  bit has_spi_agent   = 1'b1;
  bit has_gpio_agent  = 1'b1;
  bit has_vga_agent   = 1'b1;
  bit has_timer_agent = 1'b1;
  bit has_wdt_agent   = 1'b1;

  // Active / Passive modes for each agent
  uvm_active_passive_enum uart_is_active  = UVM_ACTIVE;  // Drives serial Rx & monitors Tx
  uvm_active_passive_enum spi_is_active   = UVM_ACTIVE;  // Behavioral ADC streaming slave
  uvm_active_passive_enum gpio_is_active  = UVM_ACTIVE;  // Stimulates pushbuttons, checks LEDs
  uvm_active_passive_enum vga_is_active   = UVM_PASSIVE; // Monitors raster frames & timing
  uvm_active_passive_enum timer_is_active = UVM_PASSIVE; // Monitors sample_tick and IRQs
  uvm_active_passive_enum wdt_is_active   = UVM_PASSIVE; // Monitors NMI and reset out

  // Verification & Scoreboard Options
  bit has_scoreboard = 1'b1;
  bit enable_coverage = 1'b1;

  function new(string name = "soc_env_config");
    super.new(name);
  endfunction : new

endclass : soc_env_config

`endif // SOC_ENV_CONFIG_SV
