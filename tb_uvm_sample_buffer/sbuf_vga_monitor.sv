// =============================================================================
// Monitor      : sbuf_vga_monitor.sv
// Description  : Monitor for VGA Display Read Port on clk_vga domain
// =============================================================================
`ifndef SBUF_VGA_MONITOR_SV
`define SBUF_VGA_MONITOR_SV

class sbuf_vga_monitor extends uvm_monitor;
  `uvm_component_utils(sbuf_vga_monitor)

  virtual sbuf_vga_if vif;
  uvm_analysis_port #(sbuf_vga_item) ap;

  function new(string name = "sbuf_vga_monitor", uvm_component parent = null);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual sbuf_vga_if)::get(this, "", "vga_vif", vif)) begin
      `uvm_fatal("NOVIF", "virtual sbuf_vga_if not found in config_db")
    end
  endfunction

  task run_phase(uvm_phase phase);
    bit [11:0] pipe_raddr;
    bit        pipe_rd_buf;
    bit        pipe_valid = 1'b0;

    @(posedge vif.rst_vga_n);

    forever begin
      @(posedge vif.clk_vga);

      if (pipe_valid) begin
        sbuf_vga_item item = sbuf_vga_item::type_id::create("item");
        item.addr       = pipe_raddr;
        item.data       = vif.sbuf_rdata;
        item.rd_buf_sel = pipe_rd_buf;
        item.timestamp  = $realtime;
        ap.write(item);
        `uvm_info("VGA_MON", $sformatf("VGA Read: addr=0x%03x (Bank %b) data=0x%04x", item.addr, item.rd_buf_sel, item.data), UVM_HIGH)
      end

      pipe_raddr  = vif.sbuf_raddr;
      pipe_rd_buf = vif.rd_buf_sel_vga;
      pipe_valid  = vif.sbuf_ren;
    end
  endtask

endclass : sbuf_vga_monitor

`endif // SBUF_VGA_MONITOR_SV
