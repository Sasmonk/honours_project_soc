// =============================================================================
// Driver       : dma_stream_driver.sv
// Description  : Hardware Driver driving Sample Ticks, SPI samples & FIR loopback
// =============================================================================
`ifndef DMA_STREAM_DRIVER_SV
`define DMA_STREAM_DRIVER_SV

class dma_stream_driver extends uvm_driver;
  `uvm_component_utils(dma_stream_driver)

  virtual dma_stream_if vif;

  bit enable_periodic_ticks = 1'b0;
  int tick_period_clocks    = 10;

  function new(string name = "dma_stream_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual dma_stream_if)::get(this, "", "dma_vif", vif)) begin
      `uvm_fatal("NOVIF", "virtual dma_stream_if not found in config_db")
    end
  endfunction

  task run_phase(uvm_phase phase);
    vif.sample_tick          <= 1'b0;
    vif.spi_sample_ready     <= 1'b0;
    vif.spi_sample_data      <= 16'h0;
    vif.fir_sample_out       <= 16'sd0;
    vif.fir_sample_valid_out <= 1'b0;

    @(posedge vif.rst_n);

    fork
      fir_loopback_loop();
      periodic_tick_loop();
    join
  endtask

  // FIR Filter Behavioral Loopback (1 cycle latency matching fir_filter.sv)
  task fir_loopback_loop();
    forever begin
      @(posedge vif.clk);
      vif.fir_sample_out       <= vif.fir_sample_in;
      vif.fir_sample_valid_out <= vif.fir_sample_valid_in;
    end
  endtask

  // Periodic Timer Tick Generator
  task periodic_tick_loop();
    forever begin
      @(posedge vif.clk);
      if (enable_periodic_ticks) begin
        repeat (tick_period_clocks - 1) @(posedge vif.clk);
        vif.sample_tick <= 1'b1;
        @(posedge vif.clk);
        vif.sample_tick <= 1'b0;
      end
    end
  endtask

  // API: Drive single sample tick
  task send_tick();
    @(posedge vif.clk);
    vif.sample_tick <= 1'b1;
    @(posedge vif.clk);
    vif.sample_tick <= 1'b0;
  endtask

  // API: Drive SPI sample
  task send_spi_sample(bit [15:0] data);
    @(posedge vif.clk);
    vif.spi_sample_data  <= data;
    vif.spi_sample_ready <= 1'b1;
    @(posedge vif.clk);
    vif.spi_sample_ready <= 1'b0;
  endtask

endclass : dma_stream_driver

`endif // DMA_STREAM_DRIVER_SV
