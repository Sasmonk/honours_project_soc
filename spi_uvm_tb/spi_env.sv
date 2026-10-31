// =============================================================================
// Environment  : spi_env.sv
// Description  : Standard UVM Environment for SPI VIP
// =============================================================================
`ifndef SPI_ENV_SV
`define SPI_ENV_SV

class spi_env extends uvm_env;
  `uvm_component_utils(spi_env)

  spi_agent      agent;
  spi_scoreboard sb;

  function new(string name = "spi_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = spi_agent::type_id::create("agent", this);
    sb    = spi_scoreboard::type_id::create("sb", this);
  endfunction : build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent.ap.connect(sb.item_export);
  endfunction : connect_phase
endclass : spi_env

`endif // SPI_ENV_SV
