// =============================================================================
// Monitor      : spi_adc_monitor.sv
// Description  : Cycle-accurate monitor measuring SPI timing, signals, and SVA
// =============================================================================
`ifndef SPI_ADC_MONITOR_SV
`define SPI_ADC_MONITOR_SV

class spi_adc_monitor extends uvm_monitor;
  `uvm_component_utils(spi_adc_monitor)

  virtual spi_adc_if vif;
  uvm_analysis_port #(spi_adc_item) item_collected_port;
  uvm_analysis_port #(bit)          sample_ready_ap;

  function new(string name = "spi_adc_monitor", uvm_component parent = null);
    super.new(name, parent);
    item_collected_port = new("item_collected_port", this);
    sample_ready_ap     = new("sample_ready_ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual spi_adc_if)::get(this, "", "spi_vif", vif)) begin
      `uvm_fatal("NOVIF", "virtual spi_adc_if not found in config_db")
    end
  endfunction

  task run_phase(uvm_phase phase);
    @(posedge vif.rst_n);

    fork
      monitor_spi_bus();
      monitor_pipeline_strobes();
    join
  endtask

  task monitor_spi_bus();
    realtime t_cs_fall;
    realtime t_sck_rise;
    realtime t_sck_fall;
    realtime measured_high_time;
    realtime measured_low_time;
    realtime measured_period;
    bit [15:0] mosi_shift;
    bit [15:0] miso_shift;
    int        sck_cnt;
    realtime   t_lead_meas;
    realtime   t_trail_meas;

    forever begin
      // 1. Wait for CS_N falling edge
      @(negedge vif.adc_spi_cs_n);
      t_cs_fall   = $realtime;
      mosi_shift  = 16'h0000;
      miso_shift  = 16'h0000;
      sck_cnt     = 0;
      t_lead_meas = 0;
      measured_period = 0;

      // 2. Track SCK edges while CS_N is low
      while (!vif.adc_spi_cs_n) begin
        @(posedge vif.adc_spi_sck or posedge vif.adc_spi_cs_n);
        if (!vif.adc_spi_cs_n) begin
          t_sck_rise = $realtime;
          sck_cnt++;

          if (sck_cnt == 1) begin
            t_lead_meas = t_sck_rise - t_cs_fall;
          end else begin
            measured_low_time = t_sck_rise - t_sck_fall;
            measured_period   = measured_high_time + measured_low_time;
          end

          // Sample MOSI and MISO on SCK rising edge
          mosi_shift = {mosi_shift[14:0], vif.adc_spi_mosi};
          miso_shift = {miso_shift[14:0], vif.adc_spi_miso};

          // Wait for falling edge
          @(negedge vif.adc_spi_sck or posedge vif.adc_spi_cs_n);
          if (!vif.adc_spi_cs_n) begin
            t_sck_fall = $realtime;
            measured_high_time = t_sck_fall - t_sck_rise;
          end
        end
      end

      // 3. CS_N rose: compute t_trail and publish frame item
      t_trail_meas = $realtime - t_sck_fall;

      begin
        spi_adc_item item = spi_adc_item::type_id::create("item");
        item.mosi_data      = mosi_shift;
        item.miso_data      = miso_shift;
        item.num_sck_cycles = sck_cnt;
        item.sck_period     = measured_period;
        item.sck_high_time  = measured_high_time;
        item.sck_low_time   = measured_low_time;
        item.t_lead         = t_lead_meas;
        item.t_trail        = t_trail_meas;
        item.timestamp      = $realtime;
        item_collected_port.write(item);

        `uvm_info("SPI_MON", item.convert2string(), UVM_HIGH)
      end
    end
  endtask

  task monitor_pipeline_strobes();
    forever begin
      @(posedge vif.clk);
      if (vif.sample_ready) begin
        sample_ready_ap.write(1'b1);
      end
    end
  endtask

endclass : spi_adc_monitor

`endif // SPI_ADC_MONITOR_SV
