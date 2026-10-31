// =============================================================================
// Coverage     : uart_coverage.sv
// Description  : Functional Coverage Model for UART 16550 Verification (cg_comms_ui)
// =============================================================================
`ifndef UART_COVERAGE_SV
`define UART_COVERAGE_SV

`uvm_analysis_imp_decl(_cov_axi)
`uvm_analysis_imp_decl(_cov_serial)

class uart_coverage extends uvm_component;
  `uvm_component_utils(uart_coverage)

  uvm_analysis_imp_cov_axi    #(axi_item, uart_coverage)         axi_export;
  uvm_analysis_imp_cov_serial #(uart_serial_item, uart_coverage) serial_export;

  // Variables sampled by covergroups
  axi_op_e      cov_op;
  bit [4:0]     cov_reg_addr;
  bit [7:0]     cov_data_byte;
  bit           cov_framing_err;
  bit           cov_dlab;

  // Covergroup matching SoC Test Plan: cg_comms_ui
  covergroup cg_comms_ui;
    // CP: Register Access (all standard 16550 registers)
    cp_reg_access: coverpoint cov_reg_addr {
      bins reg_rbr_thr_dll = {5'h00};
      bins reg_ier_dlm     = {5'h04};
      bins reg_iir_fcr     = {5'h08};
      bins reg_lcr         = {5'h0C};
      bins reg_mcr         = {5'h10};
      bins reg_lsr         = {5'h14};
      bins reg_msr         = {5'h18};
      bins reg_scr         = {5'h1C};
    }

    // CP: AXI Operation Type
    cp_axi_op: coverpoint cov_op {
      bins read_op  = {AXI_READ};
      bins write_op = {AXI_WRITE};
    }

    // Cross: Register Read/Write
    cross_reg_op: cross cp_reg_access, cp_axi_op;

    // CP: Baud Divisor / DLAB Switch
    cp_dlab_switch: coverpoint cov_dlab {
      bins dlab_0 = {1'b0};
      bins dlab_1 = {1'b1};
    }

    // CP: Character Data Distribution
    cp_char_data: coverpoint cov_data_byte {
      bins zero     = {8'h00};
      bins low_byte = {[8'h01:8'h40]};
      bins ascii_az = {[8'h41:8'h5A], [8'h61:8'h7A]};
      bins pattern1 = {8'h55};
      bins pattern2 = {8'hAA};
      bins high_byte= {[8'h7B:8'hFE]};
      bins full_ff  = {8'hFF};
    }
  endgroup : cg_comms_ui

  // Covergroup for Serial Framing
  covergroup cg_serial_framing;
    cp_framing_status: coverpoint cov_framing_err {
      bins valid_frame = {1'b0};
      bins frame_error = {1'b1};
    }
    cp_serial_data: coverpoint cov_data_byte {
      bins all_ranges[] = {[8'h00:8'hFF]};
    }
  endgroup : cg_serial_framing

  function new(string name = "uart_coverage", uvm_component parent = null);
    super.new(name, parent);
    axi_export    = new("axi_export", this);
    serial_export = new("serial_export", this);
    cg_comms_ui   = new();
    cg_serial_framing = new();
  endfunction : new

  virtual function void write_cov_axi(axi_item item);
    cov_op        = item.op;
    cov_reg_addr  = item.addr[4:0];
    cov_data_byte = item.data[7:0];
    if (item.op == AXI_WRITE && cov_reg_addr == 5'h0C) begin
      cov_dlab = item.data[7];
    end
    cg_comms_ui.sample();
  endfunction : write_cov_axi

  virtual function void write_cov_serial(uart_serial_item item);
    cov_data_byte   = item.data;
    cov_framing_err = item.framing_err;
    cg_serial_framing.sample();
  endfunction : write_cov_serial

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("UART_COV", $sformatf("cg_comms_ui Coverage: %0.2f%%", cg_comms_ui.get_coverage()), UVM_NONE)
    `uvm_info("UART_COV", $sformatf("cg_serial_framing Coverage: %0.2f%%", cg_serial_framing.get_coverage()), UVM_NONE)
  endfunction : report_phase

endclass : uart_coverage

`endif // UART_COVERAGE_SV
