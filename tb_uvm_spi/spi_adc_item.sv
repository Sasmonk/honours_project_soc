// =============================================================================
// Item         : spi_adc_item.sv
// Description  : Sequence item for SPI transactions, frame timings, and metrics
// =============================================================================
`ifndef SPI_ADC_ITEM_SV
`define SPI_ADC_ITEM_SV

class spi_adc_item extends uvm_sequence_item;
  `uvm_object_utils(spi_adc_item)

  bit [15:0]  mosi_data;
  bit [15:0]  miso_data;
  realtime    sck_period;
  realtime    sck_high_time;
  realtime    sck_low_time;
  realtime    t_lead;
  realtime    t_trail;
  int         num_sck_cycles;
  realtime    timestamp;

  function new(string name = "spi_adc_item");
    super.new(name);
  endfunction

  virtual function string convert2string();
    return $sformatf("MOSI=0x%04x MISO=0x%04x SCK_cycles=%0d period=%0.2fns lead=%0.2fns trail=%0.2fns @%0t",
                     mosi_data, miso_data, num_sck_cycles, sck_period, t_lead, t_trail, timestamp);
  endfunction

endclass : spi_adc_item

`endif // SPI_ADC_ITEM_SV
