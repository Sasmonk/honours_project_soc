// =============================================================================
// Driver       : spi_adc_driver.sv
// Description  : Reactive UVM Slave VIP modeling external high-speed SPI ADC
// =============================================================================
`ifndef SPI_ADC_DRIVER_SV
`define SPI_ADC_DRIVER_SV

class spi_adc_driver extends uvm_driver #(spi_adc_item);
  `uvm_component_utils(spi_adc_driver)

  virtual spi_adc_if vif;
  uvm_analysis_port #(spi_adc_item) drv_ap;

  bit [15:0] sample_queue[$];
  int        sample_counter = 0;

  function new(string name = "spi_adc_driver", uvm_component parent = null);
    super.new(name, parent);
    drv_ap = new("drv_ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual spi_adc_if)::get(this, "", "spi_vif", vif)) begin
      `uvm_fatal("NOVIF", "virtual spi_adc_if not found in config_db")
    end
  endfunction

  task run_phase(uvm_phase phase);
    vif.adc_spi_miso <= 1'b0;
    vif.sample_tick  <= 1'b0;

    @(posedge vif.rst_n);

    // Fork concurrent reactive ADC slave behavior
    fork
      adc_miso_responder();
    join
  endtask

  task adc_miso_responder();
    bit [15:0] current_sample;
    int        bit_idx;

    forever begin
      // Wait for CS_N assertion (active LOW)
      @(negedge vif.adc_spi_cs_n);

      if (sample_queue.size() > 0) begin
        current_sample = sample_queue.pop_front();
      end else begin
        sample_counter++;
        current_sample = 16'h1000 + sample_counter;
      end

      // Notify scoreboard of the driven sample
      begin
        spi_adc_item item = spi_adc_item::type_id::create("drv_item");
        item.miso_data  = current_sample;
        item.timestamp  = $realtime;
        drv_ap.write(item);
      end

      // Drive MSB immediately on CS_N assertion (SPI Mode 0)
      vif.adc_spi_miso <= current_sample[15];
      bit_idx = 14;

      // Shift out subsequent bits on falling edges of SCK
      while (!vif.adc_spi_cs_n) begin
        @(negedge vif.adc_spi_sck or posedge vif.adc_spi_cs_n);
        if (!vif.adc_spi_cs_n && bit_idx >= 0) begin
          vif.adc_spi_miso <= current_sample[bit_idx];
          bit_idx--;
        end
      end

      // CS_N deasserted: release MISO
      vif.adc_spi_miso <= 1'b0;
    end
  endtask

  task pulse_tick();
    @(posedge vif.clk);
    vif.sample_tick <= 1'b1;
    @(posedge vif.clk);
    vif.sample_tick <= 1'b0;
  endtask

endclass : spi_adc_driver

`endif // SPI_ADC_DRIVER_SV
