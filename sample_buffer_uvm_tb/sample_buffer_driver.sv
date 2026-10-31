// =============================================================================
// Driver      : sample_buffer_driver.sv
// Description : Protocol-Accurate Master Driver for SAMPLE_BUFFER
// =============================================================================
`ifndef SAMPLE_BUFFER_DRIVER_SV
`define SAMPLE_BUFFER_DRIVER_SV

class sample_buffer_driver extends uvm_driver #(sample_buffer_item);
  `uvm_component_utils(sample_buffer_driver)

  virtual sample_buffer_if vif;

  function new(string name = "sample_buffer_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual sample_buffer_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("SAMPLE_BUFFER_DRV", "Virtual interface sample_buffer_if not set in config_db!")
    end
  endfunction : build_phase

  virtual task run_phase(uvm_phase phase);
    reset_signals();
    wait_for_reset();
    forever begin
      seq_item_port.get_next_item(req);
      drive_transfer(req);
      seq_item_port.item_done();
    end
  endtask : run_phase

  virtual task reset_signals();
    vif.master_cb.sbuf_waddr <= '0;
    vif.master_cb.sbuf_wdata <= '0;
    vif.master_cb.sbuf_we <= '0;
    vif.master_cb.buf_swap_req <= '0;
    vif.master_cb.vga_vsync_pulse <= '0;
    vif.master_cb.clk_vga <= '0;
    vif.master_cb.rst_vga_n <= '0;
    vif.master_cb.sbuf_raddr <= '0;
    vif.master_cb.s_axi_awaddr <= '0;
    vif.master_cb.s_axi_awvalid <= '0;
    vif.master_cb.s_axi_wdata <= '0;
    vif.master_cb.s_axi_wstrb <= '0;
    vif.master_cb.s_axi_wvalid <= '0;
    vif.master_cb.s_axi_bready <= '0;
    vif.master_cb.s_axi_araddr <= '0;
    vif.master_cb.s_axi_arvalid <= '0;
    vif.master_cb.s_axi_rready <= '0;
  endtask : reset_signals

  virtual task wait_for_reset();
    @(posedge vif.rst_sys_n);
    @(vif.master_cb);
  endtask : wait_for_reset

  virtual task drive_transfer(sample_buffer_item item);
    repeat (item.delay) @(vif.master_cb);
    vif.master_cb.sbuf_waddr <= item.sbuf_waddr;
    vif.master_cb.sbuf_wdata <= item.sbuf_wdata;
    vif.master_cb.sbuf_we <= item.sbuf_we;
    vif.master_cb.buf_swap_req <= item.buf_swap_req;
    vif.master_cb.vga_vsync_pulse <= item.vga_vsync_pulse;
    vif.master_cb.clk_vga <= item.clk_vga;
    vif.master_cb.rst_vga_n <= item.rst_vga_n;
    vif.master_cb.sbuf_raddr <= item.sbuf_raddr;
    vif.master_cb.s_axi_awaddr <= item.s_axi_awaddr;
    vif.master_cb.s_axi_awvalid <= item.s_axi_awvalid;
    vif.master_cb.s_axi_wdata <= item.s_axi_wdata;
    vif.master_cb.s_axi_wstrb <= item.s_axi_wstrb;
    vif.master_cb.s_axi_wvalid <= item.s_axi_wvalid;
    vif.master_cb.s_axi_bready <= item.s_axi_bready;
    vif.master_cb.s_axi_araddr <= item.s_axi_araddr;
    vif.master_cb.s_axi_arvalid <= item.s_axi_arvalid;
    vif.master_cb.s_axi_rready <= item.s_axi_rready;
    @(vif.master_cb);
endclass : sample_buffer_driver

`endif // SAMPLE_BUFFER_DRIVER_SV
