// =============================================================================
// Coverage     : gpio_coverage.sv
// Description  : Functional Coverage for GPIO Verification (cg_comms_ui)
// =============================================================================
`ifndef GPIO_COVERAGE_SV
`define GPIO_COVERAGE_SV

`uvm_analysis_imp_decl(_gpio_cov_axi)
`uvm_analysis_imp_decl(_gpio_cov_pin)

class gpio_coverage extends uvm_component;
  `uvm_component_utils(gpio_coverage)

  uvm_analysis_imp_gpio_cov_axi #(axi_item, gpio_coverage)      axi_export;
  uvm_analysis_imp_gpio_cov_pin #(gpio_pin_item, gpio_coverage) pin_export;

  // Variables sampled by covergroups
  bit [3:0] cov_reg_addr;
  axi_op_e  cov_op;
  bit [7:0] cov_led_val;
  bit [7:0] cov_pin_val;

  // Covergroup for Communications & UI Subsystem (GPIO portion)
  covergroup cg_comms_ui;
    // CP: Register Access
    cp_reg_access: coverpoint cov_reg_addr {
      bins reg_in     = {4'h0};
      bins reg_out    = {4'h4};
      bins reg_irq_en = {4'h8};
      bins reg_status = {4'hC};
    }

    // CP: LED Output Patterns (TC_COM_04)
    cp_led_outputs: coverpoint cov_led_val {
      bins all_off    = {8'h00};
      bins pattern_a5 = {8'hA5};
      bins pattern_5a = {8'h5A};
      bins all_on     = {8'hFF};
      bins walking_ones[] = {8'h01, 8'h02, 8'h04, 8'h08, 8'h10, 8'h20, 8'h40, 8'h80};
    }

    // CP: Button Edge Inputs (TC_COM_03)
    cp_gpio_edge_irq: coverpoint cov_pin_val {
      bins btn0_press = {8'h01};
      bins btn1_press = {8'h02};
      bins btn2_press = {8'h04};
      bins btn3_press = {8'h08};
      bins all_press  = {8'hFF};
      bins all_idle   = {8'h00};
    }
  endgroup : cg_comms_ui

  function new(string name = "gpio_coverage", uvm_component parent = null);
    super.new(name, parent);
    axi_export  = new("axi_export", this);
    pin_export  = new("pin_export", this);
    cg_comms_ui = new();
  endfunction : new

  virtual function void write_gpio_cov_axi(axi_item item);
    cov_reg_addr = item.addr[3:0];
    cov_op       = item.op;
    if (item.op == AXI_WRITE && cov_reg_addr == 4'h4) begin
      cov_led_val = item.data[7:0];
    end
    cg_comms_ui.sample();
  endfunction : write_gpio_cov_axi

  virtual function void write_gpio_cov_pin(gpio_pin_item item);
    cov_pin_val = item.pin_val;
    cg_comms_ui.sample();
  endfunction : write_gpio_cov_pin

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("GPIO_COV", $sformatf("cg_comms_ui Coverage: %0.2f%%", cg_comms_ui.get_coverage()), UVM_NONE)
  endfunction : report_phase

endclass : gpio_coverage

`endif // GPIO_COVERAGE_SV
