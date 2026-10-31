#!/usr/bin/env python3
# ==============================================================================
# Project      : Honours SoC UVM Verification IP & Testbench Generator
# File         : uvm_testbench_generator.py
# Description  : Production-grade UVM VIP & Testbench Generator from Signal CSV
# Usage        : python uvm_testbench_generator.py <protocol_name> <signals.csv>
#
# CSV Format   :
#   <signal_name>,<direction>,<width>
# Example:
#   clk,input,1
#   rst_n,input,1
#   awaddr,input,32
#   wdata,input,32
#   ready,output,1
# ==============================================================================

import os
import sys
import csv

if len(sys.argv) < 3:
    print("Usage: python uvm_testbench_generator.py <protocol_name> <signals.csv>")
    sys.exit(1)

VIP_NAME = sys.argv[1].lower()
CSV_FILE = sys.argv[2]

CLK_NAMES = ['clk', 'clock', 'aclk', 'clk_i', 's_axi_aclk', 'fixed_clk_i', 'clk_sys']
RST_NAMES = ['rst', 'rst_n', 'reset', 'reset_n', 'aresetn', 'arstn_i', 'rst_sys_n', 's_axi_aresetn']

def parse_csv(csv_path):
    signals = []
    with open(csv_path, 'r') as f:
        reader = csv.reader(f)
        for row in reader:
            if not row or len(row) < 3 or row[0].strip().startswith('#'):
                continue
            name = row[0].strip()
            direction = row[1].strip().lower()
            try:
                width = int(row[2].strip())
            except ValueError:
                width = 1
            signals.append({'name': name, 'dir': direction, 'width': width})
    return signals

def get_clk_rst(signals):
    clk_sig = next((s['name'] for s in signals if s['name'].lower() in CLK_NAMES), 'clk')
    rst_sig = next((s['name'] for s in signals if s['name'].lower() in RST_NAMES), 'rst_n')
    return clk_sig, rst_sig

# ------------------------------------------------------------------------------
# 1. Generate Interface (with Clocking Blocks & Modports)
# ------------------------------------------------------------------------------
def gen_interface(vip, signals, clk, rst):
    lines = []
    lines.append(f"// =============================================================================")
    lines.append(f"// Interface   : {vip}_if.sv")
    lines.append(f"// Description : Standard UVM SystemVerilog Interface for {vip.upper()}")
    lines.append(f"// =============================================================================")
    lines.append(f"`timescale 1ns / 1ps\n")
    lines.append(f"interface {vip}_if (input logic {clk}, input logic {rst});")
    lines.append("")
    
    # Signal Declarations
    lines.append("  // Physical Bus Signals")
    for s in signals:
        if s['name'] in [clk, rst]:
            continue
        if s['width'] == 1:
            lines.append(f"  logic        {s['name']};")
        else:
            lines.append(f"  logic [{s['width']-1}:0] {s['name']};")
    lines.append("")

    # Master Clocking Block
    lines.append("  // Master Clocking Block (Driver perspective)")
    lines.append(f"  clocking master_cb @(posedge {clk});")
    lines.append("    default input #1step output #1;")
    for s in signals:
        if s['name'] in [clk, rst]:
            continue
        if s['dir'] == 'input':
            lines.append(f"    output {s['name']};")
        else:
            lines.append(f"    input  {s['name']};")
    lines.append("  endclocking")
    lines.append("")

    # Monitor Clocking Block
    lines.append("  // Monitor Clocking Block (Passive sampling)")
    lines.append(f"  clocking monitor_cb @(posedge {clk});")
    lines.append("    default input #1step output #1;")
    for s in signals:
        if s['name'] in [clk, rst]:
            continue
        lines.append(f"    input  {s['name']};")
    lines.append("  endclocking")
    lines.append("")

    # Modports
    lines.append("  // Modports")
    lines.append(f"  modport master_mp (clocking master_cb, input {clk}, input {rst});")
    lines.append(f"  modport monitor_mp (clocking monitor_cb, input {clk}, input {rst});")
    lines.append("")
    lines.append(f"endinterface : {vip}_if")
    return "\n".join(lines) + "\n"

# ------------------------------------------------------------------------------
# 2. Generate Sequence Item (Transaction Object)
# ------------------------------------------------------------------------------
def gen_item(vip, signals, clk, rst):
    lines = []
    lines.append(f"// =============================================================================")
    lines.append(f"// Sequence Item : {vip}_item.sv")
    lines.append(f"// Description   : Standard UVM Transaction Item for {vip.upper()}")
    lines.append(f"// =============================================================================")
    lines.append(f"`ifndef {vip.upper()}_ITEM_SV")
    lines.append(f"`define {vip.upper()}_ITEM_SV\n")

    # If AXI, add protocol enums
    if vip == 'axi':
        lines.append("typedef enum bit { AXI_READ = 1'b0, AXI_WRITE = 1'b1 } axi_op_e;")
        lines.append("typedef enum bit [1:0] { AXI_RESP_OKAY = 2'b00, AXI_RESP_EXOKAY = 2'b01, AXI_RESP_SLVERR = 2'b10, AXI_RESP_DECERR = 2'b11 } axi_resp_e;\n")

    lines.append(f"class {vip}_item extends uvm_sequence_item;")
    lines.append("")
    
    payload_sigs = [s for s in signals if s['name'] not in [clk, rst]]

    if vip == 'axi':
        lines.append("  // Standard AXI Protocol Transaction Fields")
        lines.append("  rand axi_op_e                 op;")
        lines.append("  rand bit [31:0]               addr;")
        lines.append("  rand bit [31:0]               data;")
        lines.append("  rand bit [3:0]                strb;")
        lines.append("  rand bit [2:0]                prot;")
        lines.append("  bit [1:0]                     resp;")
        lines.append("  rand int unsigned             delay;\n")
        lines.append("  `uvm_object_utils_begin(axi_item)")
        lines.append("    `uvm_field_enum(axi_op_e, op,    UVM_ALL_ON)")
        lines.append("    `uvm_field_int (addr,            UVM_ALL_ON | UVM_HEX)")
        lines.append("    `uvm_field_int (data,            UVM_ALL_ON | UVM_HEX)")
        lines.append("    `uvm_field_int (strb,            UVM_ALL_ON | UVM_HEX)")
        lines.append("    `uvm_field_int (prot,            UVM_ALL_ON | UVM_HEX)")
        lines.append("    `uvm_field_int (resp,            UVM_ALL_ON | UVM_HEX)")
        lines.append("    `uvm_field_int (delay,           UVM_ALL_ON | UVM_DEC)")
        lines.append("  `uvm_object_utils_end\n")
        lines.append("  // Protocol Constraints")
        lines.append("  constraint c_addr_align { addr[1:0] == 2'b00; }")
        lines.append("  constraint c_strb       { strb inside {4'b0001, 4'b0011, 4'b1111}; }")
        lines.append("  constraint c_delay      { delay inside {[0:5]}; }\n")
    else:
        lines.append("  // Transaction Fields")
        for s in payload_sigs:
            rand_prefix = "rand " if s['dir'] == 'input' else "     "
            if s['width'] == 1:
                lines.append(f"  {rand_prefix}bit        {s['name']};")
            else:
                lines.append(f"  {rand_prefix}bit [{s['width']-1}:0] {s['name']};")
        lines.append("  rand int unsigned delay;\n")
        lines.append(f"  `uvm_object_utils_begin({vip}_item)")
        for s in payload_sigs:
            lines.append(f"    `uvm_field_int({s['name']}, UVM_ALL_ON | UVM_HEX)")
        lines.append(f"    `uvm_field_int(delay, UVM_ALL_ON | UVM_DEC)")
        lines.append("  `uvm_object_utils_end\n")
        lines.append("  constraint c_delay { delay inside {[0:5]}; }\n")

    lines.append(f"  function new(string name = \"{vip}_item\");")
    lines.append("    super.new(name);")
    lines.append("  endfunction : new\n")

    lines.append("  virtual function string convert2string();")
    if vip == 'axi':
        lines.append("    return $sformatf(\"op=%s addr=0x%08h data=0x%08h strb=0x%1h resp=0x%0h delay=%0d\",")
        lines.append("                    op.name(), addr, data, strb, resp, delay);")
    else:
        fmt = " ".join([f"{s['name']}=0x%0h" for s in payload_sigs])
        args = ", ".join([s['name'] for s in payload_sigs])
        lines.append(f"    return $sformatf(\"{fmt}\", {args});")
    lines.append("  endfunction : convert2string\n")

    lines.append(f"endclass : {vip}_item\n")
    lines.append(f"`endif // {vip.upper()}_ITEM_SV")
    return "\n".join(lines) + "\n"

# ------------------------------------------------------------------------------
# 3. Generate Sequencer
# ------------------------------------------------------------------------------
def gen_sequencer(vip):
    return f"""// =============================================================================
// Sequencer   : {vip}_sequencer.sv
// Description : Standard UVM Sequencer for {vip.upper()} VIP
// =============================================================================
`ifndef {vip.upper()}_SEQUENCER_SV
`define {vip.upper()}_SEQUENCER_SV

class {vip}_sequencer extends uvm_sequencer #({vip}_item);
  `uvm_component_utils({vip}_sequencer)

  function new(string name = "{vip}_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new
endclass : {vip}_sequencer

`endif // {vip.upper()}_SEQUENCER_SV
"""

# ------------------------------------------------------------------------------
# 4. Generate Driver (Protocol Accurate)
# ------------------------------------------------------------------------------
def gen_driver(vip, signals, clk, rst):
    lines = []
    lines.append(f"// =============================================================================")
    lines.append(f"// Driver      : {vip}_driver.sv")
    lines.append(f"// Description : Protocol-Accurate Master Driver for {vip.upper()}")
    lines.append(f"// =============================================================================")
    lines.append(f"`ifndef {vip.upper()}_DRIVER_SV")
    lines.append(f"`define {vip.upper()}_DRIVER_SV\n")
    lines.append(f"class {vip}_driver extends uvm_driver #({vip}_item);")
    lines.append(f"  `uvm_component_utils({vip}_driver)\n")
    lines.append(f"  virtual {vip}_if vif;\n")
    lines.append(f"  function new(string name = \"{vip}_driver\", uvm_component parent = null);")
    lines.append("    super.new(name, parent);")
    lines.append("  endfunction : new\n")
    lines.append("  virtual function void build_phase(uvm_phase phase);")
    lines.append("    super.build_phase(phase);")
    lines.append(f"    if (!uvm_config_db#(virtual {vip}_if)::get(this, \"\", \"vif\", vif)) begin")
    lines.append(f"      `uvm_fatal(\"{vip.upper()}_DRV\", \"Virtual interface {vip}_if not set in config_db!\")")
    lines.append("    end")
    lines.append("  endfunction : build_phase\n")

    lines.append("  virtual task run_phase(uvm_phase phase);")
    lines.append("    reset_signals();")
    lines.append(f"    wait_for_reset();")
    lines.append("    forever begin")
    lines.append("      seq_item_port.get_next_item(req);")
    lines.append("      drive_transfer(req);")
    lines.append("      seq_item_port.item_done();")
    lines.append("    end")
    lines.append("  endtask : run_phase\n")

    lines.append("  virtual task reset_signals();")
    if vip == 'axi':
        lines.append("    vif.master_cb.awvalid <= 1'b0;")
        lines.append("    vif.master_cb.wvalid  <= 1'b0;")
        lines.append("    vif.master_cb.bready  <= 1'b0;")
        lines.append("    vif.master_cb.arvalid <= 1'b0;")
        lines.append("    vif.master_cb.rready  <= 1'b0;")
        lines.append("    vif.master_cb.awaddr  <= 32'd0;")
        lines.append("    vif.master_cb.wdata   <= 32'd0;")
        lines.append("    vif.master_cb.wstrb   <= 4'd0;")
        lines.append("    vif.master_cb.araddr  <= 32'd0;")
    else:
        for s in signals:
            if s['dir'] == 'input' and s['name'] not in [clk, rst]:
                lines.append(f"    vif.master_cb.{s['name']} <= '0;")
    lines.append("  endtask : reset_signals\n")

    lines.append("  virtual task wait_for_reset();")
    lines.append(f"    @(posedge vif.{rst});")
    lines.append("    @(vif.master_cb);")
    lines.append("  endtask : wait_for_reset\n")

    lines.append(f"  virtual task drive_transfer({vip}_item item);")
    if vip == 'axi':
        lines.append("    repeat (item.delay) @(vif.master_cb);")
        lines.append("    if (item.op == AXI_WRITE) begin")
        lines.append("      drive_write(item);")
        lines.append("    end else begin")
        lines.append("      drive_read(item);")
        lines.append("    end")
        lines.append("  endtask : drive_transfer\n")

        lines.append("  virtual task drive_write(axi_item item);")
        lines.append("    // Assert Address and Data concurrently")
        lines.append("    vif.master_cb.awaddr  <= item.addr;")
        lines.append("    vif.master_cb.awprot  <= item.prot;")
        lines.append("    vif.master_cb.awvalid <= 1'b1;")
        lines.append("    vif.master_cb.wdata   <= item.data;")
        lines.append("    vif.master_cb.wstrb   <= item.strb;")
        lines.append("    vif.master_cb.wvalid  <= 1'b1;")
        lines.append("    vif.master_cb.bready  <= 1'b1;\n")
        lines.append("    // Concurrent handshakes for AW, W, and B channels")
        lines.append("    fork")
        lines.append("      begin")
        lines.append("        do @(vif.master_cb); while (!vif.master_cb.awready);")
        lines.append("        vif.master_cb.awvalid <= 1'b0;")
        lines.append("      end")
        lines.append("      begin")
        lines.append("        do @(vif.master_cb); while (!vif.master_cb.wready);")
        lines.append("        vif.master_cb.wvalid <= 1'b0;")
        lines.append("      end")
        lines.append("      begin")
        lines.append("        do @(vif.master_cb); while (!vif.master_cb.bvalid);")
        lines.append("        item.resp = vif.master_cb.bresp;")
        lines.append("        vif.master_cb.bready <= 1'b0;")
        lines.append("      end")
        lines.append("    join")
        lines.append("  endtask : drive_write\n")

        lines.append("  virtual task drive_read(axi_item item);")
        lines.append("    // Assert Read Address")
        lines.append("    vif.master_cb.araddr  <= item.addr;")
        lines.append("    vif.master_cb.arprot  <= item.prot;")
        lines.append("    vif.master_cb.arvalid <= 1'b1;")
        lines.append("    vif.master_cb.rready  <= 1'b1;\n")
        lines.append("    // Concurrent handshakes for AR and R channels")
        lines.append("    fork")
        lines.append("      begin")
        lines.append("        do @(vif.master_cb); while (!vif.master_cb.arready);")
        lines.append("        vif.master_cb.arvalid <= 1'b0;")
        lines.append("      end")
        lines.append("      begin")
        lines.append("        do @(vif.master_cb); while (!vif.master_cb.rvalid);")
        lines.append("        item.data = vif.master_cb.rdata;")
        lines.append("        item.resp = vif.master_cb.rresp;")
        lines.append("        vif.master_cb.rready <= 1'b0;")
        lines.append("      end")
        lines.append("    join")
        lines.append("  endtask : drive_read")
    else:
        lines.append("    repeat (item.delay) @(vif.master_cb);")
        for s in signals:
            if s['dir'] == 'input' and s['name'] not in [clk, rst]:
                lines.append(f"    vif.master_cb.{s['name']} <= item.{s['name']};")
        lines.append("    @(vif.master_cb);")
    lines.append(f"endclass : {vip}_driver\n")
    lines.append(f"`endif // {vip.upper()}_DRIVER_SV")
    return "\n".join(lines) + "\n"

# ------------------------------------------------------------------------------
# 5. Generate Monitor (Continuous Protocol Sampling)
# ------------------------------------------------------------------------------
def gen_monitor(vip, signals, clk, rst):
    lines = []
    lines.append(f"// =============================================================================")
    lines.append(f"// Monitor    : {vip}_monitor.sv")
    lines.append(f"// Description: Passive Protocol Monitor & Analysis Broadcaster for {vip.upper()}")
    lines.append(f"// =============================================================================")
    lines.append(f"`ifndef {vip.upper()}_MONITOR_SV")
    lines.append(f"`define {vip.upper()}_MONITOR_SV\n")
    lines.append(f"class {vip}_monitor extends uvm_monitor;")
    lines.append(f"  `uvm_component_utils({vip}_monitor)\n")
    lines.append(f"  virtual {vip}_if vif;")
    lines.append(f"  uvm_analysis_port #({vip}_item) ap;\n")
    lines.append(f"  function new(string name = \"{vip}_monitor\", uvm_component parent = null);")
    lines.append("    super.new(name, parent);")
    lines.append("    ap = new(\"ap\", this);")
    lines.append("  endfunction : new\n")
    lines.append("  virtual function void build_phase(uvm_phase phase);")
    lines.append("    super.build_phase(phase);")
    lines.append(f"    if (!uvm_config_db#(virtual {vip}_if)::get(this, \"\", \"vif\", vif)) begin")
    lines.append(f"      `uvm_fatal(\"{vip.upper()}_MON\", \"Virtual interface {vip}_if not set in config_db!\")")
    lines.append("    end")
    lines.append("  endfunction : build_phase\n")

    lines.append("  virtual task run_phase(uvm_phase phase);")
    if vip == 'axi':
        lines.append("    fork")
        lines.append("      collect_write_transactions();")
        lines.append("      collect_read_transactions();")
        lines.append("    join")
        lines.append("  endtask : run_phase\n")

        lines.append("  virtual task collect_write_transactions();")
        lines.append("    bit [31:0] wr_addr;")
        lines.append("    bit [2:0]  wr_prot;")
        lines.append("    bit [31:0] wr_data;")
        lines.append("    bit [3:0]  wr_strb;")
        lines.append("    forever begin")
        lines.append("      fork")
        lines.append("        begin")
        lines.append("          do @(vif.monitor_cb); while (!(vif.monitor_cb.awvalid && vif.monitor_cb.awready));")
        lines.append("          wr_addr = vif.monitor_cb.awaddr;")
        lines.append("          wr_prot = vif.monitor_cb.awprot;")
        lines.append("        end")
        lines.append("        begin")
        lines.append("          do @(vif.monitor_cb); while (!(vif.monitor_cb.wvalid && vif.monitor_cb.wready));")
        lines.append("          wr_data = vif.monitor_cb.wdata;")
        lines.append("          wr_strb = vif.monitor_cb.wstrb;")
        lines.append("        end")
        lines.append("        begin")
        lines.append("          do @(vif.monitor_cb); while (!(vif.monitor_cb.bvalid && vif.monitor_cb.bready));")
        lines.append("          wr_resp = vif.monitor_cb.bresp;")
        lines.append("        end")
        lines.append("      join")
        lines.append("      begin")
        lines.append("        axi_item item = axi_item::type_id::create(\"mon_wr_item\");")
        lines.append("        item.op   = AXI_WRITE;")
        lines.append("        item.addr = wr_addr;")
        lines.append("        item.prot = wr_prot;")
        lines.append("        item.data = wr_data;")
        lines.append("        item.strb = wr_strb;")
        lines.append("        item.resp = wr_resp;")
        lines.append("        ap.write(item);")
        lines.append("      end")
        lines.append("    end")
        lines.append("  endtask : collect_write_transactions\n")

        lines.append("  virtual task collect_read_transactions();")
        lines.append("    bit [31:0] rd_addr;")
        lines.append("    bit [2:0]  rd_prot;")
        lines.append("    forever begin")
        lines.append("      fork")
        lines.append("        begin")
        lines.append("          do @(vif.monitor_cb); while (!(vif.monitor_cb.arvalid && vif.monitor_cb.arready));")
        lines.append("          rd_addr = vif.monitor_cb.araddr;")
        lines.append("          rd_prot = vif.monitor_cb.arprot;")
        lines.append("        end")
        lines.append("        begin")
        lines.append("          do @(vif.monitor_cb); while (!(vif.monitor_cb.rvalid && vif.monitor_cb.rready));")
        lines.append("          rd_data = vif.monitor_cb.rdata;")
        lines.append("          rd_resp = vif.monitor_cb.rresp;")
        lines.append("        end")
        lines.append("      join")
        lines.append("      begin")
        lines.append("        axi_item item = axi_item::type_id::create(\"mon_rd_item\");")
        lines.append("        item.op   = AXI_READ;")
        lines.append("        item.addr = rd_addr;")
        lines.append("        item.prot = rd_prot;")
        lines.append("        item.data = rd_data;")
        lines.append("        item.resp = rd_resp;")
        lines.append("        ap.write(item);")
        lines.append("      end")
        lines.append("    end")
        lines.append("  endtask : collect_read_transactions")
    else:
        lines.append("    forever begin")
        lines.append("      @(vif.monitor_cb);")
        lines.append(f"      begin")
        lines.append(f"        {vip}_item item = {vip}_item::type_id::create(\"mon_item\");")
        for s in signals:
            if s['name'] not in [clk, rst]:
                lines.append(f"        item.{s['name']} = vif.monitor_cb.{s['name']};")
        lines.append("        ap.write(item);")
        lines.append("      end")
        lines.append("    end")
        lines.append("  endtask : run_phase")

    lines.append(f"endclass : {vip}_monitor\n")
    lines.append(f"`endif // {vip.upper()}_MONITOR_SV")
    return "\n".join(lines) + "\n"

# ------------------------------------------------------------------------------
# 6. Generate Agent
# ------------------------------------------------------------------------------
def gen_agent(vip):
    return f"""// =============================================================================
// Agent        : {vip}_agent.sv
// Description  : Standard UVM Agent (Driver, Monitor, Sequencer) for {vip.upper()}
// =============================================================================
`ifndef {vip.upper()}_AGENT_SV
`define {vip.upper()}_AGENT_SV

class {vip}_agent extends uvm_agent;
  `uvm_component_utils({vip}_agent)

  uvm_active_passive_enum is_active = UVM_ACTIVE;
  {vip}_driver    drv;
  {vip}_monitor   mon;
  {vip}_sequencer seqr;
  uvm_analysis_port #({vip}_item) ap;

  function new(string name = "{vip}_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon = {vip}_monitor::type_id::create("mon", this);
    if (is_active == UVM_ACTIVE) begin
      drv  = {vip}_driver::type_id::create("drv", this);
      seqr = {vip}_sequencer::type_id::create("seqr", this);
    end
  endfunction : build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    ap = mon.ap;
    if (is_active == UVM_ACTIVE) begin
      drv.seq_item_port.connect(seqr.seq_item_export);
    end
  endfunction : connect_phase
endclass : {vip}_agent

`endif // {vip.upper()}_AGENT_SV
"""

# ------------------------------------------------------------------------------
# 7. Generate Sequences
# ------------------------------------------------------------------------------
def gen_sequences(vip):
    if vip == 'axi':
        return """// =============================================================================
// Sequence Lib : axi_seq_lib.sv
// Description  : Production Sequence Library for AXI UVM Verification
// =============================================================================
`ifndef AXI_SEQ_LIB_SV
`define AXI_SEQ_LIB_SV

class axi_base_seq extends uvm_sequence #(axi_item);
  `uvm_object_utils(axi_base_seq)
  function new(string name = "axi_base_seq"); super.new(name); endfunction
endclass : axi_base_seq

// Directed Write Sequence
class axi_write_seq extends axi_base_seq;
  `uvm_object_utils(axi_write_seq)
  rand bit [31:0] addr;
  rand bit [31:0] data;
  rand bit [3:0]  strb = 4'hF;

  function new(string name = "axi_write_seq"); super.new(name); endfunction

  virtual task body();
    req = axi_item::type_id::create("req");
    start_item(req);
    req.op   = AXI_WRITE;
    req.addr = addr;
    req.data = data;
    req.strb = strb;
    finish_item(req);
  endtask : body
endclass : axi_write_seq

// Directed Read Sequence
class axi_read_seq extends axi_base_seq;
  `uvm_object_utils(axi_read_seq)
  rand bit [31:0] addr;
  bit [31:0]      read_data;

  function new(string name = "axi_read_seq"); super.new(name); endfunction

  virtual task body();
    req = axi_item::type_id::create("req");
    start_item(req);
    req.op   = AXI_READ;
    req.addr = addr;
    finish_item(req);
    read_data = req.data;
  endtask : body
endclass : axi_read_seq

// Random Read/Write Burst Sequence
class axi_rand_burst_seq extends axi_base_seq;
  `uvm_object_utils(axi_rand_burst_seq)
  rand int unsigned count;
  constraint c_count { count inside {[10:30]}; }

  function new(string name = "axi_rand_burst_seq"); super.new(name); endfunction

  virtual task body();
    repeat (count) begin
      req = axi_item::type_id::create("req");
      start_item(req);
      if (!req.randomize()) `uvm_fatal("AXI_SEQ", "Randomization failed!")
      finish_item(req);
    end
  endtask : body
endclass : axi_rand_burst_seq

`endif // AXI_SEQ_LIB_SV
"""
    else:
        return f"""// =============================================================================
// Sequence Lib : {vip}_seq_lib.sv
// =============================================================================
`ifndef {vip.upper()}_SEQ_LIB_SV
`define {vip.upper()}_SEQ_LIB_SV

class {vip}_base_seq extends uvm_sequence #({vip}_item);
  `uvm_object_utils({vip}_base_seq)
  function new(string name = "{vip}_base_seq"); super.new(name); endfunction

  virtual task body();
    repeat (10) begin
      req = {vip}_item::type_id::create("req");
      start_item(req);
      if (!req.randomize()) `uvm_fatal("{vip.upper()}_SEQ", "Randomization failed!")
      finish_item(req);
    end
  endtask : body
endclass : {vip}_base_seq

`endif // {vip.upper()}_SEQ_LIB_SV
"""

# ------------------------------------------------------------------------------
# 8. Generate Scoreboard (Reference Verification)
# ------------------------------------------------------------------------------
def gen_scoreboard(vip):
    lines = []
    lines.append(f"// =============================================================================")
    lines.append(f"// Scoreboard  : {vip}_scoreboard.sv")
    lines.append(f"// Description : Golden Reference Memory & Data Integrity Checker")
    lines.append(f"// =============================================================================")
    lines.append(f"`ifndef {vip.upper()}_SCOREBOARD_SV")
    lines.append(f"`define {vip.upper()}_SCOREBOARD_SV\n")
    lines.append(f"class {vip}_scoreboard extends uvm_scoreboard;")
    lines.append(f"  `uvm_component_utils({vip}_scoreboard)\n")
    lines.append(f"  uvm_analysis_imp #({vip}_item, {vip}_scoreboard) item_export;\n")

    if vip == 'axi':
        lines.append("  // Golden Associative Memory Model")
        lines.append("  bit [31:0] mem_model [bit [31:0]];")
        lines.append("  int match_count = 0;")
        lines.append("  int mismatch_count = 0;\n")

    lines.append(f"  function new(string name = \"{vip}_scoreboard\", uvm_component parent = null);")
    lines.append("    super.new(name, parent);")
    lines.append("    item_export = new(\"item_export\", this);")
    lines.append("  endfunction : new\n")

    lines.append(f"  virtual function void write({vip}_item item);")
    if vip == 'axi':
        lines.append("    if (item.op == AXI_WRITE) begin")
        lines.append("      mem_model[item.addr] = item.data;")
        lines.append("      `uvm_info(\"SB_WRITE\", $sformatf(\"Logged Write: Addr=0x%08h Data=0x%08h\", item.addr, item.data), UVM_HIGH)")
        lines.append("    end else begin")
        lines.append("      if (mem_model.exists(item.addr)) begin")
        lines.append("        if (mem_model[item.addr] === item.data) begin")
        lines.append("          match_count++;")
        lines.append("          `uvm_info(\"SB_MATCH\", $sformatf(\"Read Addr=0x%08h Data=0x%08h Matches Golden Model!\", item.addr, item.data), UVM_MEDIUM)")
        lines.append("        end else begin")
        lines.append("          mismatch_count++;")
        lines.append("          `uvm_error(\"SB_MISMATCH\", $sformatf(\"Read Addr=0x%08h Data=0x%08h Expected=0x%08h!\", item.addr, item.data, mem_model[item.addr]))")
        lines.append("        end")
        lines.append("      end else begin")
        lines.append("        `uvm_info(\"SB_UNINITIALIZED\", $sformatf(\"Read from unwritten Addr=0x%08h Data=0x%08h\", item.addr, item.data), UVM_HIGH)")
        lines.append("      end")
        lines.append("    end")
    else:
        lines.append("    `uvm_info(\"SB\", $sformatf(\"Transaction seen: %s\", item.convert2string()), UVM_HIGH)")
    lines.append("  endfunction : write\n")

    lines.append("  virtual function void report_phase(uvm_phase phase);")
    lines.append("    super.report_phase(phase);")
    if vip == 'axi':
        lines.append("    `uvm_info(\"SCOREBOARD_REPORT\", $sformatf(\"Total Matches: %0d | Total Mismatches: %0d\", match_count, mismatch_count), UVM_LOW)")
        lines.append("    if (mismatch_count == 0) begin")
        lines.append("      `uvm_info(\"SCOREBOARD_STATUS\", \"*** ALL SCOREBOARD COMPARISONS PASSED! ***\", UVM_LOW)")
        lines.append("    end else begin")
        lines.append("      `uvm_error(\"SCOREBOARD_STATUS\", \"*** SCOREBOARD DETECTED FAILURES! ***\")")
        lines.append("    end")
    lines.append("  endfunction : report_phase\n")

    lines.append(f"endclass : {vip}_scoreboard\n")
    lines.append(f"`endif // {vip.upper()}_SCOREBOARD_SV")
    return "\n".join(lines) + "\n"

# ------------------------------------------------------------------------------
# 9. Generate Environment
# ------------------------------------------------------------------------------
def gen_env(vip):
    return f"""// =============================================================================
// Environment  : {vip}_env.sv
// Description  : Standard UVM Environment for {vip.upper()} VIP
// =============================================================================
`ifndef {vip.upper()}_ENV_SV
`define {vip.upper()}_ENV_SV

class {vip}_env extends uvm_env;
  `uvm_component_utils({vip}_env)

  {vip}_agent      agent;
  {vip}_scoreboard sb;

  function new(string name = "{vip}_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = {vip}_agent::type_id::create("agent", this);
    sb    = {vip}_scoreboard::type_id::create("sb", this);
  endfunction : build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent.ap.connect(sb.item_export);
  endfunction : connect_phase
endclass : {vip}_env

`endif // {vip.upper()}_ENV_SV
"""

# ------------------------------------------------------------------------------
# 10. Generate Base Test & Tests
# ------------------------------------------------------------------------------
def gen_test(vip):
    return f"""// =============================================================================
// Test Lib     : {vip}_test.sv
// Description  : Base Test and Directed Verification Scenarios
// =============================================================================
`ifndef {vip.upper()}_TEST_SV
`define {vip.upper()}_TEST_SV

class {vip}_base_test extends uvm_test;
  `uvm_component_utils({vip}_base_test)

  {vip}_env env;

  function new(string name = "{vip}_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = {vip}_env::type_id::create("env", this);
  endfunction : build_phase

  virtual task run_phase(uvm_phase phase);
    uvm_top.set_report_verbosity_level_hier(UVM_LOW);
  endtask : run_phase
endclass : {vip}_base_test

// Directed Sanity Test
class {vip}_sanity_test extends {vip}_base_test;
  `uvm_component_utils({vip}_sanity_test)

  function new(string name = "{vip}_sanity_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual task run_phase(uvm_phase phase);
    axi_write_seq wr_seq;
    axi_read_seq  rd_seq;
    phase.raise_objection(this);

    `uvm_info("TEST", "Starting AXI Directed Read/Write Sanity Test...", UVM_LOW)

    // Write 0x12345678 to Address 0x1000
    wr_seq = axi_write_seq::type_id::create("wr_seq");
    wr_seq.addr = 32'h0000_1000;
    wr_seq.data = 32'h1234_5678;
    wr_seq.start(env.agent.seqr);

    // Read back from Address 0x1000
    rd_seq = axi_read_seq::type_id::create("rd_seq");
    rd_seq.addr = 32'h0000_1000;
    rd_seq.start(env.agent.seqr);

    // Write 0xCAFEBABE to Address 0x2000
    wr_seq = axi_write_seq::type_id::create("wr_seq");
    wr_seq.addr = 32'h0000_2000;
    wr_seq.data = 32'hCAFE_BABE;
    wr_seq.start(env.agent.seqr);

    // Read back from Address 0x2000
    rd_seq = axi_read_seq::type_id::create("rd_seq");
    rd_seq.addr = 32'h0000_2000;
    rd_seq.start(env.agent.seqr);

    #100ns;
    phase.drop_objection(this);
  endtask : run_phase
endclass : {vip}_sanity_test

// Random Burst Test
class {vip}_random_test extends {vip}_base_test;
  `uvm_component_utils({vip}_random_test)

  function new(string name = "{vip}_random_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual task run_phase(uvm_phase phase);
    axi_rand_burst_seq rseq;
    phase.raise_objection(this);
    `uvm_info("TEST", "Starting AXI Randomized Burst Verification...", UVM_LOW)

    rseq = axi_rand_burst_seq::type_id::create("rseq");
    rseq.count = 25;
    rseq.start(env.agent.seqr);

    #100ns;
    phase.drop_objection(this);
  endtask : run_phase
endclass : {vip}_random_test

`endif // {vip.upper()}_TEST_SV
"""

# ------------------------------------------------------------------------------
# 11. Generate Package
# ------------------------------------------------------------------------------
def gen_package(vip):
    return f"""// =============================================================================
// Package      : {vip}_pkg.sv
// Description  : Standard UVM Package wrapping {vip.upper()} VIP Components
// =============================================================================
`ifndef {vip.upper()}_PKG_SV
`define {vip.upper()}_PKG_SV

package {vip}_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "{vip}_item.sv"
  `include "{vip}_sequencer.sv"
  `include "{vip}_seq_lib.sv"
  `include "{vip}_driver.sv"
  `include "{vip}_monitor.sv"
  `include "{vip}_agent.sv"
  `include "{vip}_scoreboard.sv"
  `include "{vip}_env.sv"
  `include "{vip}_test.sv"

endpackage : {vip}_pkg

`endif // {vip.upper()}_PKG_SV
"""

# ------------------------------------------------------------------------------
# 12. Generate Standalone Self-Testing Testbench Top with Built-in Responder
# ------------------------------------------------------------------------------
def gen_tb_top(vip, clk, rst):
    return f"""// =============================================================================
// Testbench Top: tb_{vip}_top.sv
// Description  : Self-contained UVM Testbench Top with Built-in AXI Memory Slave
// =============================================================================
`timescale 1ns / 1ps

module tb_{vip}_top;
  import uvm_pkg::*;
  import {vip}_pkg::*;

  logic {clk};
  logic {rst};

  // Clock generation (100 MHz)
  initial begin
    {clk} = 0;
    forever #5 {clk} = ~{clk};
  end

  // Reset generation
  initial begin
    {rst} = 0;
    #25 {rst} = 1;
  end

  // Virtual Interface Instance
  {vip}_if vif (.{clk}({clk}), .{rst}({rst}));

  // Built-in Standard AXI-Lite Slave Memory Responder
  reg [31:0] mem [bit [31:0]];

  always @(posedge {clk} or negedge {rst}) begin
    if (!{rst}) begin
      vif.awready <= 1'b0;
      vif.wready  <= 1'b0;
      vif.bvalid  <= 1'b0;
      vif.bresp   <= 2'b00;
      vif.arready <= 1'b0;
      vif.rvalid  <= 1'b0;
      vif.rdata   <= 32'd0;
      vif.rresp   <= 2'b00;
    end else begin
      // Write Address & Data Handshake
      vif.awready <= vif.awvalid;
      vif.wready  <= vif.wvalid;
      if (vif.awvalid && vif.wvalid && vif.awready && vif.wready) begin
        mem[vif.awaddr] <= vif.wdata;
        vif.bvalid      <= 1'b1;
        vif.bresp       <= 2'b00; // OKAY
      end
      if (vif.bvalid && vif.bready) begin
        vif.bvalid <= 1'b0;
      end

      // Read Address & Data Handshake
      vif.arready <= vif.arvalid;
      if (vif.arvalid && vif.arready) begin
        vif.rvalid <= 1'b1;
        vif.rresp  <= 2'b00; // OKAY
        if (mem.exists(vif.araddr)) begin
          vif.rdata <= mem[vif.araddr];
        end else begin
          vif.rdata <= 32'hDEAD_BEEF;
        end
      end
      if (vif.rvalid && vif.rready) begin
        vif.rvalid <= 1'b0;
      end
    end
  end

  // UVM Registration and Test Launch
  initial begin
    uvm_config_db#(virtual {vip}_if)::set(null, "*", "vif", vif);
    $timeformat(-9, 2, " ns", 20);

    // Verdi FSDB dump
    `ifdef DUMP_FSDB
      $fsdbDumpfile("uvm_{vip}_dump.fsdb");
      $fsdbDumpvars(0, tb_{vip}_top, "+all");
    `endif

    run_test();
  end
endmodule : tb_{vip}_top
"""

# ------------------------------------------------------------------------------
# 13. Generate Makefile
# ------------------------------------------------------------------------------
def gen_makefile(vip):
    return f"""# ==============================================================================
# Makefile for {vip.upper()} UVM Verification IP Testbench
# Tool: Synopsys VCS U-2023.03
# ==============================================================================

VCS        = vcs -full64 -sverilog -timescale=1ns/1ps -ntb_opts uvm -debug_access+all -kdb +define+DUMP_FSDB
TESTNAME   ?= {vip}_sanity_test
VERDI      = verdi

FILES      = {vip}_if.sv {vip}_pkg.sv tb_{vip}_top.sv

all: run

compile:
\t$(VCS) $(FILES) -l compile.log

run: compile
\t./simv +UVM_TESTNAME=$(TESTNAME) -l sim.log

random: compile
\t./simv +UVM_TESTNAME={vip}_random_test -l sim_rand.log

verdi:
\t$(VERDI) -dbdir simv.daidir -ssf uvm_{vip}_dump.fsdb &

clean:
\trm -rf simv* csrc *.log *.key *.fsdb ucli.key vc_hdrs.h DVEfiles *.vpd
"""

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------
def main():
    signals = parse_csv(CSV_FILE)
    if not signals:
        print(f"Error: No signals found in {CSV_FILE}")
        sys.exit(1)

    clk, rst = get_clk_rst(signals)
    outdir = f"{VIP_NAME}_uvm_tb"
    os.makedirs(outdir, exist_ok=True)

    files = {
        f"{VIP_NAME}_if.sv": gen_interface(VIP_NAME, signals, clk, rst),
        f"{VIP_NAME}_item.sv": gen_item(VIP_NAME, signals, clk, rst),
        f"{VIP_NAME}_sequencer.sv": gen_sequencer(VIP_NAME),
        f"{VIP_NAME}_seq_lib.sv": gen_sequences(VIP_NAME),
        f"{VIP_NAME}_driver.sv": gen_driver(VIP_NAME, signals, clk, rst),
        f"{VIP_NAME}_monitor.sv": gen_monitor(VIP_NAME, signals, clk, rst),
        f"{VIP_NAME}_agent.sv": gen_agent(VIP_NAME),
        f"{VIP_NAME}_scoreboard.sv": gen_scoreboard(VIP_NAME),
        f"{VIP_NAME}_env.sv": gen_env(VIP_NAME),
        f"{VIP_NAME}_test.sv": gen_test(VIP_NAME),
        f"{VIP_NAME}_pkg.sv": gen_package(VIP_NAME),
        f"tb_{VIP_NAME}_top.sv": gen_tb_top(VIP_NAME, clk, rst),
        "Makefile": gen_makefile(VIP_NAME)
    }

    print(f"==================================================================")
    print(f"  Generating UVM Verification IP for: {VIP_NAME.upper()}")
    print(f"  Source Signal Specification       : {CSV_FILE}")
    print(f"  Output Directory                  : {outdir}/")
    print(f"==================================================================")

    for fname, content in files.items():
        fpath = os.path.join(outdir, fname)
        with open(fpath, "w") as f:
            f.write(content)
        print(f"  [+] Created: {fpath}")

    print(f"==================================================================")
    print(f"  UVM VIP Generation Complete! (Total {len(files)} files)")
    print(f"  Run test with: cd {outdir} && make run")
    print(f"==================================================================")

if __name__ == '__main__':
    main()
