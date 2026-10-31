// =============================================================================
// Monitor    : axi_monitor.sv
// Description: Passive Protocol Monitor & Analysis Broadcaster for AXI
// =============================================================================
`ifndef AXI_MONITOR_SV
`define AXI_MONITOR_SV

class axi_monitor extends uvm_monitor;
  `uvm_component_utils(axi_monitor)

  virtual axi_if vif;
  uvm_analysis_port #(axi_item) ap;

  function new(string name = "axi_monitor", uvm_component parent = null);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axi_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("AXI_MON", "Virtual interface axi_if not set in config_db!")
    end
  endfunction : build_phase

  virtual task run_phase(uvm_phase phase);
    fork
      collect_write_transactions();
      collect_read_transactions();
    join
  endtask : run_phase

  virtual task collect_write_transactions();
    bit [31:0] wr_addr;
    bit [2:0]  wr_prot;
    bit [31:0] wr_data;
    bit [3:0]  wr_strb;
    bit [1:0]  wr_resp;
    forever begin
      fork
        begin
          do @(vif.monitor_cb); while (!(vif.monitor_cb.awvalid && vif.monitor_cb.awready));
          wr_addr = vif.monitor_cb.awaddr;
          wr_prot = vif.monitor_cb.awprot;
        end
        begin
          do @(vif.monitor_cb); while (!(vif.monitor_cb.wvalid && vif.monitor_cb.wready));
          wr_data = vif.monitor_cb.wdata;
          wr_strb = vif.monitor_cb.wstrb;
        end
        begin
          do @(vif.monitor_cb); while (!(vif.monitor_cb.bvalid && vif.monitor_cb.bready));
          wr_resp = vif.monitor_cb.bresp;
        end
      join
      begin
        axi_item item = axi_item::type_id::create("mon_wr_item");
        item.op   = AXI_WRITE;
        item.addr = wr_addr;
        item.prot = wr_prot;
        item.data = wr_data;
        item.strb = wr_strb;
        item.resp = wr_resp;
        ap.write(item);
      end
    end
  endtask : collect_write_transactions

  virtual task collect_read_transactions();
    bit [31:0] rd_addr;
    bit [2:0]  rd_prot;
    bit [31:0] rd_data;
    bit [1:0]  rd_resp;
    forever begin
      fork
        begin
          do @(vif.monitor_cb); while (!(vif.monitor_cb.arvalid && vif.monitor_cb.arready));
          rd_addr = vif.monitor_cb.araddr;
          rd_prot = vif.monitor_cb.arprot;
        end
        begin
          do @(vif.monitor_cb); while (!(vif.monitor_cb.rvalid && vif.monitor_cb.rready));
          rd_data = vif.monitor_cb.rdata;
          rd_resp = vif.monitor_cb.rresp;
        end
      join
      begin
        axi_item item = axi_item::type_id::create("mon_rd_item");
        item.op   = AXI_READ;
        item.addr = rd_addr;
        item.prot = rd_prot;
        item.data = rd_data;
        item.resp = rd_resp;
        ap.write(item);
      end
    end
  endtask : collect_read_transactions
endclass : axi_monitor

`endif // AXI_MONITOR_SV
