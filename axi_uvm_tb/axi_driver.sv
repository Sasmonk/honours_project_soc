// =============================================================================
// Driver      : axi_driver.sv
// Description : Protocol-Accurate Master Driver for AXI
// =============================================================================
`ifndef AXI_DRIVER_SV
`define AXI_DRIVER_SV

class axi_driver extends uvm_driver #(axi_item);
  `uvm_component_utils(axi_driver)

  virtual axi_if vif;

  function new(string name = "axi_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axi_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("AXI_DRV", "Virtual interface axi_if not set in config_db!")
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
    vif.master_cb.awvalid <= 1'b0;
    vif.master_cb.wvalid  <= 1'b0;
    vif.master_cb.bready  <= 1'b0;
    vif.master_cb.arvalid <= 1'b0;
    vif.master_cb.rready  <= 1'b0;
    vif.master_cb.awaddr  <= 32'd0;
    vif.master_cb.wdata   <= 32'd0;
    vif.master_cb.wstrb   <= 4'd0;
    vif.master_cb.araddr  <= 32'd0;
  endtask : reset_signals

  virtual task wait_for_reset();
    @(posedge vif.rst_n);
    @(vif.master_cb);
  endtask : wait_for_reset

  virtual task drive_transfer(axi_item item);
    repeat (item.delay) @(vif.master_cb);
    if (item.op == AXI_WRITE) begin
      drive_write(item);
    end else begin
      drive_read(item);
    end
  endtask : drive_transfer

  virtual task drive_write(axi_item item);
    // Assert Address and Data concurrently
    vif.master_cb.awaddr  <= item.addr;
    vif.master_cb.awprot  <= item.prot;
    vif.master_cb.awvalid <= 1'b1;
    vif.master_cb.wdata   <= item.data;
    vif.master_cb.wstrb   <= item.strb;
    vif.master_cb.wvalid  <= 1'b1;
    vif.master_cb.bready  <= 1'b1;

    // Concurrent handshakes for AW, W, and B channels
    fork
      begin
        do @(vif.master_cb); while (!vif.master_cb.awready);
        vif.master_cb.awvalid <= 1'b0;
      end
      begin
        do @(vif.master_cb); while (!vif.master_cb.wready);
        vif.master_cb.wvalid <= 1'b0;
      end
      begin
        do @(vif.master_cb); while (!vif.master_cb.bvalid);
        item.resp = vif.master_cb.bresp;
        vif.master_cb.bready <= 1'b0;
      end
    join
  endtask : drive_write

  virtual task drive_read(axi_item item);
    // Assert Read Address and Ready
    vif.master_cb.araddr  <= item.addr;
    vif.master_cb.arprot  <= item.prot;
    vif.master_cb.arvalid <= 1'b1;
    vif.master_cb.rready  <= 1'b1;

    // Concurrent handshakes for AR and R channels
    fork
      begin
        do @(vif.master_cb); while (!vif.master_cb.arready);
        vif.master_cb.arvalid <= 1'b0;
      end
      begin
        do @(vif.master_cb); while (!vif.master_cb.rvalid);
        item.data = vif.master_cb.rdata;
        item.resp = vif.master_cb.rresp;
        vif.master_cb.rready <= 1'b0;
      end
    join
  endtask : drive_read
endclass : axi_driver

`endif // AXI_DRIVER_SV
