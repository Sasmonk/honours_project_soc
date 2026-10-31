// =============================================================================
// Coverage     : spi_coverage.sv
// Description  : Functional Coverage for SPI Master Controller Subsystem
// =============================================================================
`ifndef SPI_COVERAGE_SV
`define SPI_COVERAGE_SV

class spi_coverage extends uvm_subscriber #(spi_adc_item);
  `uvm_component_utils(spi_coverage)

  bit [4:0] prescaler_val;
  bit       auto_trig_val;
  bit [5:0] fifo_level_val;
  bit       is_manual_cmd;

  uvm_analysis_imp_spi_axi #(axi_item, spi_coverage) axi_cov_export;

  covergroup cg_acquisition_timing;
    option.per_instance = 1;
    option.comment = "SPI Master Acquisition & Prescaler Functional Coverage";

    // Prescaler settings
    cp_prescaler: coverpoint prescaler_val {
      bins div_2  = {5'd2};
      bins div_4  = {5'd4};
      bins div_8  = {5'd8};
      bins div_16 = {5'd16};
    }

    // Trigger modes
    cp_trigger_mode: coverpoint auto_trig_val {
      bins manual_mode = {1'b0};
      bins auto_mode   = {1'b1};
    }

    // FIFO levels
    cp_fifo_level: coverpoint fifo_level_val {
      bins empty     = {6'd0};
      bins quarter   = {[6'd1:6'd8]};
      bins half      = {[6'd9:6'd16]};
      bins three_qtr = {[6'd17:6'd31]};
      bins full      = {6'd32};
    }

    // Cross between prescaler and trigger mode
    cross_prescaler_trigger: cross cp_prescaler, cp_trigger_mode;

  endgroup : cg_acquisition_timing

  function new(string name = "spi_coverage", uvm_component parent = null);
    super.new(name, parent);
    cg_acquisition_timing = new();
    axi_cov_export = new("axi_cov_export", this);
  endfunction : new

  virtual function void write(spi_adc_item t);
    cg_acquisition_timing.sample();
  endfunction : write

  virtual function void write_spi_axi(axi_item item);
    if (item.op == AXI_WRITE && item.addr[7:0] == 8'h00) begin
      prescaler_val = item.data[7:4];
      auto_trig_val = item.data[1];
    end else if (item.op == AXI_READ && item.addr[7:0] == 8'h14) begin
      fifo_level_val = item.data[4:0];
    end
  endfunction : write_spi_axi

endclass : spi_coverage

`endif // SPI_COVERAGE_SV
