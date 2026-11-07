// =============================================================================
// Responder    : dma_axi_master_responder.sv
// Description  : Reactive Slave Responder for DMA Controller's AXI4 Master port
// =============================================================================
`ifndef DMA_AXI_MASTER_RESPONDER_SV
`define DMA_AXI_MASTER_RESPONDER_SV

class dma_axi_master_responder extends uvm_component;
  `uvm_component_utils(dma_axi_master_responder)

  virtual dma_stream_if vif;
  uvm_analysis_port #(dma_axi_xfer_item) ap;

  // Internal Memory Model (Word Addr -> 32-bit Word)
  bit [31:0] memory [bit [31:0]];

  // Error Injection and Bus Control Flags
  bit inject_slverr  = 1'b0;
  bit inject_stall   = 1'b0;
  int response_delay = 0; // clock cycles delay

  function new(string name = "dma_axi_master_responder", uvm_component parent = null);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual dma_stream_if)::get(this, "", "dma_vif", vif)) begin
      `uvm_fatal("NOVIF", "virtual dma_stream_if not found in config_db")
    end
  endfunction

  // Memory access helper
  function void write_mem(bit [31:0] addr, bit [31:0] data);
    memory[addr] = data;
  endfunction

  function bit [31:0] read_mem(bit [31:0] addr);
    if (memory.exists(addr)) return memory[addr];
    return 32'hDEAD_BEEF;
  endfunction

  task run_phase(uvm_phase phase);
    // Initialize Master interface inputs (slave outputs)
    vif.m_axi_arready <= 1'b0;
    vif.m_axi_rvalid  <= 1'b0;
    vif.m_axi_rdata   <= 32'h0;
    vif.m_axi_rresp   <= 2'b00;
    vif.m_axi_rlast   <= 1'b0;
    vif.m_axi_rid     <= 8'h0;

    vif.m_axi_awready <= 1'b0;
    vif.m_axi_wready  <= 1'b0;
    vif.m_axi_bvalid  <= 1'b0;
    vif.m_axi_bresp   <= 2'b00;
    vif.m_axi_bid     <= 8'h0;

    @(posedge vif.rst_n);

    fork
      handle_read_channel();
      handle_write_channel();
    join
  endtask

  // Read Channel Handler
  task handle_read_channel();
    bit [31:0] latched_araddr;
    bit [7:0]  latched_arid;
    int        wait_cnt;

    forever begin
      @(posedge vif.clk);

      if (inject_stall) begin
        vif.m_axi_arready <= 1'b0;
        continue;
      end

      if (vif.m_axi_arvalid && !vif.m_axi_arready) begin
        if (response_delay > 0) repeat (response_delay) @(posedge vif.clk);
        vif.m_axi_arready <= 1'b1;
        latched_araddr     = vif.m_axi_araddr;
        latched_arid       = vif.m_axi_arid;
        @(posedge vif.clk);
        vif.m_axi_arready <= 1'b0;

        // Drive Read Data Beat
        vif.m_axi_rvalid <= 1'b1;
        vif.m_axi_rlast  <= 1'b1;
        vif.m_axi_rid    <= latched_arid;
        vif.m_axi_rdata  <= read_mem(latched_araddr);
        vif.m_axi_rresp  <= inject_slverr ? 2'b10 : 2'b00;

        // Broadcast to Analysis Port
        begin
          dma_axi_xfer_item item = dma_axi_xfer_item::type_id::create("rd_item");
          item.dir       = dma_axi_xfer_item::AXI_XFER_READ;
          item.addr      = latched_araddr;
          item.data      = read_mem(latched_araddr);
          item.resp      = inject_slverr ? 2'b10 : 2'b00;
          item.last      = 1'b1;
          item.timestamp = $realtime;
          ap.write(item);
        end

        // Wait for DUT to accept read data (with abort guard)
        wait_cnt = 0;
        while (!vif.m_axi_rready && vif.rst_n && (wait_cnt < 64)) begin
          @(posedge vif.clk);
          wait_cnt++;
        end
        @(posedge vif.clk);
        vif.m_axi_rvalid <= 1'b0;
        vif.m_axi_rlast  <= 1'b0;
      end
    end
  endtask

  // Write Channel Handler
  task handle_write_channel();
    bit [31:0] latched_awaddr;
    bit [31:0] latched_wdata;
    bit [7:0]  latched_awid;
    bit        aw_done_local;
    bit        w_done_local;
    int        wait_b_cnt;

    forever begin
      @(posedge vif.clk);

      if (vif.m_axi_awvalid || vif.m_axi_wvalid) begin
        `uvm_info("RESPONDER_WR", $sformatf("Observed AWVALID=%b WVALID=%b", vif.m_axi_awvalid, vif.m_axi_wvalid), UVM_LOW)
      end

      if (inject_stall) begin
        vif.m_axi_awready <= 1'b0;
        vif.m_axi_wready  <= 1'b0;
        continue;
      end

      if ((vif.m_axi_awvalid || aw_done_local) && (vif.m_axi_wvalid || w_done_local)) begin
        if (response_delay > 0) repeat (response_delay) @(posedge vif.clk);

        if (vif.m_axi_awvalid && !aw_done_local) begin
          vif.m_axi_awready <= 1'b1;
          latched_awaddr     = vif.m_axi_awaddr;
          latched_awid       = vif.m_axi_awid;
          aw_done_local      = 1'b1;
        end
        if (vif.m_axi_wvalid && !w_done_local) begin
          vif.m_axi_wready <= 1'b1;
          latched_wdata    = vif.m_axi_wdata;
          w_done_local     = 1'b1;
        end

        @(posedge vif.clk);
        vif.m_axi_awready <= 1'b0;
        vif.m_axi_wready  <= 1'b0;

        if (aw_done_local && w_done_local) begin
          // Write into local memory
          write_mem(latched_awaddr, latched_wdata);

          // Broadcast to Analysis Port
          begin
            dma_axi_xfer_item item = dma_axi_xfer_item::type_id::create("wr_item");
            item.dir       = dma_axi_xfer_item::AXI_XFER_WRITE;
            item.addr      = latched_awaddr;
            item.data      = latched_wdata;
            item.resp      = inject_slverr ? 2'b10 : 2'b00;
            item.last      = 1'b1;
            item.timestamp = $realtime;
            ap.write(item);
          end

          // Send Write Response Beat
          vif.m_axi_bvalid <= 1'b1;
          vif.m_axi_bid    <= latched_awid;
          vif.m_axi_bresp  <= inject_slverr ? 2'b10 : 2'b00;

          wait_b_cnt = 0;
          while (!vif.m_axi_bready && vif.rst_n && (wait_b_cnt < 64)) begin
            @(posedge vif.clk);
            wait_b_cnt++;
          end
          @(posedge vif.clk);
          vif.m_axi_bvalid <= 1'b0;

          aw_done_local = 1'b0;
          w_done_local  = 1'b0;
        end
      end
    end
  endtask

endclass : dma_axi_master_responder

`endif // DMA_AXI_MASTER_RESPONDER_SV
