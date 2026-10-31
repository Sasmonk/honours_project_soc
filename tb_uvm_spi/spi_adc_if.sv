// =============================================================================
// Interface    : spi_adc_if.sv
// Description  : Interface for Physical SPI pins and Acquisition Signals
// =============================================================================
`ifndef SPI_ADC_IF_SV
`define SPI_ADC_IF_SV

interface spi_adc_if (
  input logic clk,
  input logic rst_n
);
  // Physical SPI bus
  logic        adc_spi_sck;
  logic        adc_spi_mosi;
  logic        adc_spi_miso;
  logic        adc_spi_cs_n;

  // Acquisition strobes & pipeline connections
  logic        sample_tick;
  logic        sample_ready;
  logic [15:0] sample_data;
  logic        irq_spi;

  // Modport for ADC driver
  modport adc_slave_driver (
    input  clk,
    input  rst_n,
    input  adc_spi_sck,
    input  adc_spi_mosi,
    output adc_spi_miso,
    input  adc_spi_cs_n,
    output sample_tick
  );

  // Modport for SPI monitor
  modport monitor (
    input clk,
    input rst_n,
    input adc_spi_sck,
    input adc_spi_mosi,
    input adc_spi_miso,
    input adc_spi_cs_n,
    input sample_tick,
    input sample_ready,
    input sample_data,
    input irq_spi
  );

endinterface : spi_adc_if

`endif // SPI_ADC_IF_SV
