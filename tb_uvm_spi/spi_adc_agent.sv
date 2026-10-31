// =============================================================================
// Agent        : spi_adc_agent.sv
// Description  : UVM Agent containing SPI ADC driver and monitor
// =============================================================================
`ifndef SPI_ADC_AGENT_SV
`define SPI_ADC_AGENT_SV

class spi_adc_agent extends uvm_agent;
  `uvm_component_utils(spi_adc_agent)

  spi_adc_driver  drv;
  spi_adc_monitor mon;

  function new(string name = "spi_adc_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    drv = spi_adc_driver::type_id::create("drv", this);
    mon = spi_adc_monitor::type_id::create("mon", this);
  endfunction

endclass : spi_adc_agent

`endif // SPI_ADC_AGENT_SV
