// =============================================================================
// Environment  : spi_env.sv
// Description  : UVM Environment for SPI Master Controller Verification
// =============================================================================
`ifndef SPI_ENV_SV
`define SPI_ENV_SV

class spi_env extends uvm_env;
  `uvm_component_utils(spi_env)

  axi_agent       axi_agt;
  spi_adc_agent   spi_agt;
  spi_scoreboard  sb;
  spi_coverage    cov;

  function new(string name = "spi_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    axi_agt = axi_agent::type_id::create("axi_agt", this);
    spi_agt = spi_adc_agent::type_id::create("spi_agt", this);
    sb      = spi_scoreboard::type_id::create("sb", this);
    cov     = spi_coverage::type_id::create("cov", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    axi_agt.ap.connect(sb.axi_export);
    axi_agt.ap.connect(cov.axi_cov_export);

    spi_agt.drv.drv_ap.connect(sb.spi_drv_export);
    spi_agt.mon.item_collected_port.connect(sb.spi_item_export);
    spi_agt.mon.item_collected_port.connect(cov.analysis_export);
    spi_agt.mon.sample_ready_ap.connect(sb.ready_export);
  endfunction

endclass : spi_env

`endif // SPI_ENV_SV
