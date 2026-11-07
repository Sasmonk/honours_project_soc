// =============================================================================
// File        : soc_env.sv
// Description : Top-Level SoC UVM Environment dynamically instantiating VIPs
// =============================================================================
`ifndef SOC_ENV_SV
`define SOC_ENV_SV

class soc_env extends uvm_env;
  `uvm_component_utils(soc_env)

  // Configuration Handle
  soc_env_config         m_cfg;

  // VIP Agents
  uart_serial_agent      uart_agent;
  spi_adc_agent          spi_agent;
  gpio_pin_agent         gpio_agent;
  vga_agent              vga_disp_agent;
  timer_pulse_agent      timer_agent;
  wdt_safety_agent       wdt_agent;

  // Coordination & Checking Components
  soc_scoreboard         scoreboard;
  soc_virtual_sequencer  vseqr;

  function new(string name = "soc_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Retrieve or create environment configuration
    if (!uvm_config_db#(soc_env_config)::get(this, "", "cfg", m_cfg)) begin
      `uvm_info("SOC_ENV", "soc_env_config not found in config_db; creating default config", UVM_MEDIUM)
      m_cfg = soc_env_config::type_id::create("m_cfg");
    end

    // Dynamically instantiate enabled VIP agents via UVM Factory
    if (m_cfg.has_uart_agent) begin
      uvm_config_db#(uvm_active_passive_enum)::set(this, "uart_agent", "is_active", m_cfg.uart_is_active);
      uart_agent = uart_serial_agent::type_id::create("uart_agent", this);
    end

    if (m_cfg.has_spi_agent) begin
      spi_agent = spi_adc_agent::type_id::create("spi_agent", this);
    end

    if (m_cfg.has_gpio_agent) begin
      uvm_config_db#(uvm_active_passive_enum)::set(this, "gpio_agent", "is_active", m_cfg.gpio_is_active);
      gpio_agent = gpio_pin_agent::type_id::create("gpio_agent", this);
    end

    if (m_cfg.has_vga_agent) begin
      vga_disp_agent = vga_agent::type_id::create("vga_disp_agent", this);
    end

    if (m_cfg.has_timer_agent) begin
      timer_agent = timer_pulse_agent::type_id::create("timer_agent", this);
    end

    if (m_cfg.has_wdt_agent) begin
      wdt_agent = wdt_safety_agent::type_id::create("wdt_agent", this);
    end

    // Create Scoreboard & Virtual Sequencer
    if (m_cfg.has_scoreboard) begin
      scoreboard = soc_scoreboard::type_id::create("scoreboard", this);
    end

    vseqr = soc_virtual_sequencer::type_id::create("vseqr", this);
  endfunction : build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // Bind sub-sequencers to virtual sequencer
    if (m_cfg.has_uart_agent && (m_cfg.uart_is_active == UVM_ACTIVE)) begin
      vseqr.uart_seqr = uart_agent.seqr;
    end
    if (m_cfg.has_gpio_agent && (m_cfg.gpio_is_active == UVM_ACTIVE)) begin
      vseqr.gpio_seqr = gpio_agent.seqr;
    end

    // Connect Analysis Ports to Top-Level Scoreboard
    if (m_cfg.has_scoreboard) begin
      if (m_cfg.has_uart_agent) begin
        uart_agent.ap.connect(scoreboard.uart_export);
      end
      if (m_cfg.has_spi_agent) begin
        spi_agent.mon.item_collected_port.connect(scoreboard.spi_export);
      end
      if (m_cfg.has_gpio_agent) begin
        if (m_cfg.gpio_is_active == UVM_ACTIVE) begin
          gpio_agent.drv_ap.connect(scoreboard.gpio_export);
        end else begin
          gpio_agent.ap.connect(scoreboard.gpio_export);
        end
      end
      if (m_cfg.has_vga_agent) begin
        vga_disp_agent.mon.ap.connect(scoreboard.vga_export);
      end
      if (m_cfg.has_timer_agent) begin
        timer_agent.mon.item_collected_port.connect(scoreboard.timer_export);
      end
      if (m_cfg.has_wdt_agent) begin
        wdt_agent.mon.item_collected_port.connect(scoreboard.wdt_export);
      end
    end
  endfunction : connect_phase

endclass : soc_env

`endif // SOC_ENV_SV
