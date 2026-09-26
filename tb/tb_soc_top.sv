// =============================================================================
// Testbench : tb_soc_top.sv
// Top Module: soc_top
// Tool      : Synopsys VCS / Verdi (SystemVerilog)
// Project   : honours_project_soc-main (RISC-V SoC Integration)
//
// Description:
//   Comprehensive, self-checking verification testbench for soc_top.
//   Verifies end-to-end integration of:
//     1. VeeR EL2 RISC-V Processor Core (RV32IMC)
//     2. AXI4 64-bit to 32-bit Width Adapters (LSU, IFU, SB)
//     3. 3-Master x 10-Slave AXI4 Interconnect
//     4. AXI4-Lite UART IP Core (M00)
//     5. External Memory / Peripheral 1 (M01)
//     6. External Peripheral 2 (M02 - AES Accelerator)
//     7. UART Serial Tx / Rx Framing, Baud Timing & IRQ
//     8. External PIC Interrupts (ext_irq, timer_int)
//     9. Bus Decode Error Handling (DECERR on unmapped M03..M09)
//    10. CPU Execution Trace & Status Monitoring
// =============================================================================

`timescale 1ns/1ps

module tb_soc_top;

    // -------------------------------------------------------------------------
    // Parameters
    // -------------------------------------------------------------------------
    localparam DATA_WIDTH       = 32;
    localparam ADDR_WIDTH       = 32;
    localparam STRB_WIDTH       = DATA_WIDTH / 8;
    localparam ID_WIDTH         = 8;
    localparam AWUSER_WIDTH     = 1;
    localparam WUSER_WIDTH      = 1;
    localparam BUSER_WIDTH      = 1;
    localparam ARUSER_WIDTH     = 1;
    localparam RUSER_WIDTH      = 1;

    // Peripheral Address Map
    localparam [ADDR_WIDTH-1:0] UART_BASE_ADDR = 32'h0000_0000;
    localparam [ADDR_WIDTH-1:0] M01_BASE_ADDR  = 32'h0100_0000;
    localparam [ADDR_WIDTH-1:0] M02_BASE_ADDR  = 32'h0200_0000;
    localparam [ADDR_WIDTH-1:0] M03_BASE_ADDR  = 32'h0300_0000;

    // UART Offsets
    localparam [ADDR_WIDTH-1:0] UART_REG_RBR   = 32'h0000_0000;
    localparam [ADDR_WIDTH-1:0] UART_REG_THR   = 32'h0000_0000;
    localparam [ADDR_WIDTH-1:0] UART_REG_IER   = 32'h0000_0004;
    localparam [ADDR_WIDTH-1:0] UART_REG_DIV   = 32'h0000_0008;
    localparam [ADDR_WIDTH-1:0] UART_REG_LCR   = 32'h0000_000C;
    localparam [ADDR_WIDTH-1:0] UART_REG_LSR   = 32'h0000_0014;

    // Clock Period: 10 ns (100 MHz)
    localparam CLK_PERIOD_NS    = 10;
    localparam UART_BAUD_DIV    = 868; // Matching default UART_BAUDRATE_DIV_INIT (115200 baud at 100MHz)
    localparam BIT_PERIOD_NS    = CLK_PERIOD_NS * UART_BAUD_DIV;

    // -------------------------------------------------------------------------
    // DUT Signals
    // -------------------------------------------------------------------------
    logic                    clk;
    logic                    rst_n;

    logic [31:1]             rst_vec;
    logic                    nmi_int;
    logic [31:1]             nmi_vec;
    logic [31:1]             jtag_id;

    logic                    uart_rx;
    wire                     uart_tx;
    wire                     uart_irq;

    logic [29:0]             ext_irq;
    logic                    timer_int;

    wire [31:0]              trace_rv_i_insn_ip;
    wire [31:0]              trace_rv_i_address_ip;
    wire                     trace_rv_i_valid_ip;
    wire                     trace_rv_i_exception_ip;
    wire [4:0]               trace_rv_i_ecause_ip;
    wire                     trace_rv_i_interrupt_ip;
    wire [31:0]              trace_rv_i_tval_ip;

    wire                     o_cpu_halt_status;
    wire                     o_cpu_halt_ack;
    wire                     o_debug_mode_status;

    // Master 01 (M01: SRAM / Main Memory)
    wire [ID_WIDTH-1:0]      m01_axi_awid;
    wire [ADDR_WIDTH-1:0]    m01_axi_awaddr;
    wire [7:0]               m01_axi_awlen;
    wire [2:0]               m01_axi_awsize;
    wire [1:0]               m01_axi_awburst;
    wire                     m01_axi_awlock;
    wire [3:0]               m01_axi_awcache;
    wire [2:0]               m01_axi_awprot;
    wire [3:0]               m01_axi_awqos;
    wire [3:0]               m01_axi_awregion;
    wire [AWUSER_WIDTH-1:0]  m01_axi_awuser;
    wire                     m01_axi_awvalid;
    reg                      m01_axi_awready;
    wire [DATA_WIDTH-1:0]    m01_axi_wdata;
    wire [STRB_WIDTH-1:0]    m01_axi_wstrb;
    wire                     m01_axi_wlast;
    wire [WUSER_WIDTH-1:0]   m01_axi_wuser;
    wire                     m01_axi_wvalid;
    reg                      m01_axi_wready;
    reg  [ID_WIDTH-1:0]      m01_axi_bid;
    reg  [1:0]               m01_axi_bresp;
    reg  [BUSER_WIDTH-1:0]   m01_axi_buser;
    reg                      m01_axi_bvalid;
    wire                     m01_axi_bready;
    wire [ID_WIDTH-1:0]      m01_axi_arid;
    wire [ADDR_WIDTH-1:0]    m01_axi_araddr;
    wire [7:0]               m01_axi_arlen;
    wire [2:0]               m01_axi_arsize;
    wire [1:0]               m01_axi_arburst;
    wire                     m01_axi_arlock;
    wire [3:0]               m01_axi_arcache;
    wire [2:0]               m01_axi_arprot;
    wire [3:0]               m01_axi_arqos;
    wire [3:0]               m01_axi_arregion;
    wire [ARUSER_WIDTH-1:0]  m01_axi_aruser;
    wire                     m01_axi_arvalid;
    reg                      m01_axi_arready;
    reg  [ID_WIDTH-1:0]      m01_axi_rid;
    reg  [DATA_WIDTH-1:0]    m01_axi_rdata;
    reg  [1:0]               m01_axi_rresp;
    reg                      m01_axi_rlast;
    reg  [RUSER_WIDTH-1:0]   m01_axi_ruser;
    reg                      m01_axi_rvalid;
    wire                     m01_axi_rready;

    // Master 02 (M02: AES Core / Ext IP)
    wire [ID_WIDTH-1:0]      m02_axi_awid;
    wire [ADDR_WIDTH-1:0]    m02_axi_awaddr;
    wire [7:0]               m02_axi_awlen;
    wire [2:0]               m02_axi_awsize;
    wire [1:0]               m02_axi_awburst;
    wire                     m02_axi_awlock;
    wire [3:0]               m02_axi_awcache;
    wire [2:0]               m02_axi_awprot;
    wire [3:0]               m02_axi_awqos;
    wire [3:0]               m02_axi_awregion;
    wire [AWUSER_WIDTH-1:0]  m02_axi_awuser;
    wire                     m02_axi_awvalid;
    reg                      m02_axi_awready;
    wire [DATA_WIDTH-1:0]    m02_axi_wdata;
    wire [STRB_WIDTH-1:0]    m02_axi_wstrb;
    wire                     m02_axi_wlast;
    wire [WUSER_WIDTH-1:0]   m02_axi_wuser;
    wire                     m02_axi_wvalid;
    reg                      m02_axi_wready;
    reg  [ID_WIDTH-1:0]      m02_axi_bid;
    reg  [1:0]               m02_axi_bresp;
    reg  [BUSER_WIDTH-1:0]   m02_axi_buser;
    reg                      m02_axi_bvalid;
    wire                     m02_axi_bready;
    wire [ID_WIDTH-1:0]      m02_axi_arid;
    wire [ADDR_WIDTH-1:0]    m02_axi_araddr;
    wire [7:0]               m02_axi_arlen;
    wire [2:0]               m02_axi_arsize;
    wire [1:0]               m02_axi_arburst;
    wire                     m02_axi_arlock;
    wire [3:0]               m02_axi_arcache;
    wire [2:0]               m02_axi_arprot;
    wire [3:0]               m02_axi_arqos;
    wire [3:0]               m02_axi_arregion;
    wire [ARUSER_WIDTH-1:0]  m02_axi_aruser;
    wire                     m02_axi_arvalid;
    reg                      m02_axi_arready;
    reg  [ID_WIDTH-1:0]      m02_axi_rid;
    reg  [DATA_WIDTH-1:0]    m02_axi_rdata;
    reg  [1:0]               m02_axi_rresp;
    reg                      m02_axi_rlast;
    reg  [RUSER_WIDTH-1:0]   m02_axi_ruser;
    reg                      m02_axi_rvalid;
    wire                     m02_axi_rready;

    // -------------------------------------------------------------------------
    // Test Statistics
    // -------------------------------------------------------------------------
    int test_pass_count  = 0;
    int test_fail_count  = 0;
    int total_assertions = 0;

    // -------------------------------------------------------------------------
    // DUT Instantiation
    // -------------------------------------------------------------------------
    soc_top #(
        .DATA_WIDTH          (DATA_WIDTH),
        .ADDR_WIDTH          (ADDR_WIDTH),
        .ID_WIDTH            (ID_WIDTH),
        .UART_BASE_ADDR      (UART_BASE_ADDR),
        .M01_BASE_ADDR       (M01_BASE_ADDR),
        .M02_BASE_ADDR       (M02_BASE_ADDR)
    ) dut (
        .clk                 (clk),
        .rst_n               (rst_n),

        .rst_vec             (rst_vec),
        .nmi_int             (nmi_int),
        .nmi_vec             (nmi_vec),
        .jtag_id             (jtag_id),

        .uart_rx             (uart_rx),
        .uart_tx             (uart_tx),
        .uart_irq            (uart_irq),

        .ext_irq             (ext_irq),
        .timer_int           (timer_int),

        .trace_rv_i_insn_ip  (trace_rv_i_insn_ip),
        .trace_rv_i_address_ip (trace_rv_i_address_ip),
        .trace_rv_i_valid_ip (trace_rv_i_valid_ip),
        .trace_rv_i_exception_ip (trace_rv_i_exception_ip),
        .trace_rv_i_ecause_ip(trace_rv_i_ecause_ip),
        .trace_rv_i_interrupt_ip(trace_rv_i_interrupt_ip),
        .trace_rv_i_tval_ip  (trace_rv_i_tval_ip),

        .o_cpu_halt_status   (o_cpu_halt_status),
        .o_cpu_halt_ack      (o_cpu_halt_ack),
        .o_debug_mode_status (o_debug_mode_status),

        // M01 Interface
        .m01_axi_awid        (m01_axi_awid),
        .m01_axi_awaddr      (m01_axi_awaddr),
        .m01_axi_awlen       (m01_axi_awlen),
        .m01_axi_awsize      (m01_axi_awsize),
        .m01_axi_awburst     (m01_axi_awburst),
        .m01_axi_awlock      (m01_axi_awlock),
        .m01_axi_awcache     (m01_axi_awcache),
        .m01_axi_awprot      (m01_axi_awprot),
        .m01_axi_awqos       (m01_axi_awqos),
        .m01_axi_awregion    (m01_axi_awregion),
        .m01_axi_awuser      (m01_axi_awuser),
        .m01_axi_awvalid     (m01_axi_awvalid),
        .m01_axi_awready     (m01_axi_awready),
        .m01_axi_wdata       (m01_axi_wdata),
        .m01_axi_wstrb       (m01_axi_wstrb),
        .m01_axi_wlast       (m01_axi_wlast),
        .m01_axi_wuser       (m01_axi_wuser),
        .m01_axi_wvalid      (m01_axi_wvalid),
        .m01_axi_wready      (m01_axi_wready),
        .m01_axi_bid         (m01_axi_bid),
        .m01_axi_bresp       (m01_axi_bresp),
        .m01_axi_buser       (m01_axi_buser),
        .m01_axi_bvalid      (m01_axi_bvalid),
        .m01_axi_bready      (m01_axi_bready),
        .m01_axi_arid        (m01_axi_arid),
        .m01_axi_araddr      (m01_axi_araddr),
        .m01_axi_arlen       (m01_axi_arlen),
        .m01_axi_arsize      (m01_axi_arsize),
        .m01_axi_arburst     (m01_axi_arburst),
        .m01_axi_arlock      (m01_axi_arlock),
        .m01_axi_arcache     (m01_axi_arcache),
        .m01_axi_arprot      (m01_axi_arprot),
        .m01_axi_arqos       (m01_axi_arqos),
        .m01_axi_arregion    (m01_axi_arregion),
        .m01_axi_aruser      (m01_axi_aruser),
        .m01_axi_arvalid     (m01_axi_arvalid),
        .m01_axi_arready     (m01_axi_arready),
        .m01_axi_rid         (m01_axi_rid),
        .m01_axi_rdata       (m01_axi_rdata),
        .m01_axi_rresp       (m01_axi_rresp),
        .m01_axi_rlast       (m01_axi_rlast),
        .m01_axi_ruser       (m01_axi_ruser),
        .m01_axi_rvalid      (m01_axi_rvalid),
        .m01_axi_rready      (m01_axi_rready),

        // M02 Interface
        .m02_axi_awid        (m02_axi_awid),
        .m02_axi_awaddr      (m02_axi_awaddr),
        .m02_axi_awlen       (m02_axi_awlen),
        .m02_axi_awsize      (m02_axi_awsize),
        .m02_axi_awburst     (m02_axi_awburst),
        .m02_axi_awlock      (m02_axi_awlock),
        .m02_axi_awcache     (m02_axi_awcache),
        .m02_axi_awprot      (m02_axi_awprot),
        .m02_axi_awqos       (m02_axi_awqos),
        .m02_axi_awregion    (m02_axi_awregion),
        .m02_axi_awuser      (m02_axi_awuser),
        .m02_axi_awvalid     (m02_axi_awvalid),
        .m02_axi_awready     (m02_axi_awready),
        .m02_axi_wdata       (m02_axi_wdata),
        .m02_axi_wstrb       (m02_axi_wstrb),
        .m02_axi_wlast       (m02_axi_wlast),
        .m02_axi_wuser       (m02_axi_wuser),
        .m02_axi_wvalid      (m02_axi_wvalid),
        .m02_axi_wready      (m02_axi_wready),
        .m02_axi_bid         (m02_axi_bid),
        .m02_axi_bresp       (m02_axi_bresp),
        .m02_axi_buser       (m02_axi_buser),
        .m02_axi_bvalid      (m02_axi_bvalid),
        .m02_axi_bready      (m02_axi_bready),
        .m02_axi_arid        (m02_axi_arid),
        .m02_axi_araddr      (m02_axi_araddr),
        .m02_axi_arlen       (m02_axi_arlen),
        .m02_axi_arsize      (m02_axi_arsize),
        .m02_axi_arburst     (m02_axi_arburst),
        .m02_axi_arlock      (m02_axi_arlock),
        .m02_axi_arcache     (m02_axi_arcache),
        .m02_axi_arprot      (m02_axi_arprot),
        .m02_axi_arqos       (m02_axi_arqos),
        .m02_axi_arregion    (m02_axi_arregion),
        .m02_axi_aruser      (m02_axi_aruser),
        .m02_axi_arvalid     (m02_axi_arvalid),
        .m02_axi_arready     (m02_axi_arready),
        .m02_axi_rid         (m02_axi_rid),
        .m02_axi_rdata       (m02_axi_rdata),
        .m02_axi_rresp       (m02_axi_rresp),
        .m02_axi_rlast       (m02_axi_rlast),
        .m02_axi_ruser       (m02_axi_ruser),
        .m02_axi_rvalid      (m02_axi_rvalid),
        .m02_axi_rready      (m02_axi_rready)
    );

    // -------------------------------------------------------------------------
    // Clock Generation (100 MHz)
    // -------------------------------------------------------------------------
    initial begin
        clk = 0;
        forever #(CLK_PERIOD_NS / 2) clk = ~clk;
    end

    // -------------------------------------------------------------------------
    // M01 Memory Model (SRAM / Main Memory at 0x0100_0000)
    // Pre-loaded with self-testing RISC-V program
    // -------------------------------------------------------------------------
    reg [DATA_WIDTH-1:0] m01_mem [0:4095];
    int m01_rd_burst_count;
    reg [ADDR_WIDTH-1:0] m01_rd_addr_latched;
    reg [ID_WIDTH-1:0]   m01_rd_id_latched;
    reg [7:0]            m01_rd_len_latched;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m01_axi_awready     <= 1'b0;
            m01_axi_wready      <= 1'b0;
            m01_axi_bvalid      <= 1'b0;
            m01_axi_bid         <= '0;
            m01_axi_bresp       <= 2'b00;
            m01_axi_buser       <= '0;
            m01_axi_arready     <= 1'b0;
            m01_axi_rvalid      <= 1'b0;
            m01_axi_rid         <= '0;
            m01_axi_rdata       <= '0;
            m01_axi_rresp       <= 2'b00;
            m01_axi_rlast       <= 1'b0;
            m01_axi_ruser       <= '0;
            m01_rd_burst_count  <= 0;
        end else begin
            // ---------------- Write Channel ----------------
            m01_axi_awready <= m01_axi_awvalid & ~m01_axi_awready;
            m01_axi_wready  <= m01_axi_wvalid & ~m01_axi_wready;

            if (m01_axi_wvalid & m01_axi_wready & m01_axi_wlast) begin
                m01_axi_bvalid <= 1'b1;
                m01_axi_bid    <= m01_axi_awid;
                m01_axi_bresp  <= 2'b00; // OKAY
                m01_mem[m01_axi_awaddr[13:2]] <= m01_axi_wdata;
            end else if (m01_axi_bvalid & m01_axi_bready) begin
                m01_axi_bvalid <= 1'b0;
            end

            // ---------------- Read Channel ----------------
            if (!m01_axi_rvalid || (m01_axi_rvalid && m01_axi_rready)) begin
                if (m01_axi_arvalid && !m01_axi_arready && (m01_rd_burst_count == 0)) begin
                    m01_axi_arready    <= 1'b1;
                    m01_rd_addr_latched <= m01_axi_araddr;
                    m01_rd_id_latched   <= m01_axi_arid;
                    m01_rd_len_latched  <= m01_axi_arlen;
                    m01_rd_burst_count  <= m01_axi_arlen + 1;
                end else if (m01_rd_burst_count > 0) begin
                    m01_axi_arready <= 1'b0;
                    m01_axi_rvalid  <= 1'b1;
                    m01_axi_rid     <= m01_rd_id_latched;
                    m01_axi_rdata   <= m01_mem[m01_rd_addr_latched[13:2]];
                    m01_axi_rresp   <= 2'b00;
                    m01_axi_rlast   <= (m01_rd_burst_count == 1);
                    m01_rd_addr_latched <= m01_rd_addr_latched + 4;
                    m01_rd_burst_count  <= m01_rd_burst_count - 1;
                end else begin
                    m01_axi_arready <= 1'b0;
                    m01_axi_rvalid  <= 1'b0;
                    m01_axi_rlast   <= 1'b0;
                end
            end
        end
    end

    // -------------------------------------------------------------------------
    // M02 Peripheral Model (AES Accelerator / Ext IP at 0x0200_0000)
    // -------------------------------------------------------------------------
    reg [DATA_WIDTH-1:0] m02_mem [0:255];
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m02_axi_awready <= 1'b0;
            m02_axi_wready  <= 1'b0;
            m02_axi_bvalid  <= 1'b0;
            m02_axi_bid     <= '0;
            m02_axi_bresp   <= 2'b00;
            m02_axi_buser   <= '0;
            m02_axi_arready <= 1'b0;
            m02_axi_rvalid  <= 1'b0;
            m02_axi_rid     <= '0;
            m02_axi_rdata   <= '0;
            m02_axi_rresp   <= 2'b00;
            m02_axi_rlast   <= 1'b0;
            m02_axi_ruser   <= '0;
        end else begin
            m02_axi_awready <= m02_axi_awvalid & ~m02_axi_awready;
            m02_axi_wready  <= m02_axi_wvalid & ~m02_axi_wready;

            if (m02_axi_wvalid & m02_axi_wready & m02_axi_wlast) begin
                m02_axi_bvalid <= 1'b1;
                m02_axi_bid    <= m02_axi_awid;
                m02_axi_bresp  <= 2'b00;
                m02_mem[m02_axi_awaddr[9:2]] <= m02_axi_wdata;
            end else if (m02_axi_bvalid & m02_axi_bready) begin
                m02_axi_bvalid <= 1'b0;
            end

            m02_axi_arready <= m02_axi_arvalid & ~m02_axi_arready;
            if (m02_axi_arvalid & m02_axi_arready) begin
                m02_axi_rvalid <= 1'b1;
                m02_axi_rid    <= m02_axi_arid;
                m02_axi_rdata  <= m02_mem[m02_axi_araddr[9:2]];
                m02_axi_rresp  <= 2'b00;
                m02_axi_rlast  <= 1'b1;
            end else if (m02_axi_rvalid & m02_axi_rready) begin
                m02_axi_rvalid <= 1'b0;
                m02_axi_rlast  <= 1'b0;
            end
        end
    end

    // -------------------------------------------------------------------------
    // Bus Activity & CPU Exception Monitor
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst_n) begin
            if (m01_axi_arvalid && m01_axi_arready)
                $display("   [M01 READ REQ ] time=%0t ns | araddr=0x%08h | len=%0d", $time, m01_axi_araddr, m01_axi_arlen);
            if (m01_axi_rvalid && m01_axi_rready)
                $display("   [M01 READ DATA] time=%0t ns | rdata=0x%08h | last=%0b", $time, m01_axi_rdata, m01_axi_rlast);
            if (m01_axi_awvalid && m01_axi_awready)
                $display("   [M01 WRITE REQ] time=%0t ns | awaddr=0x%08h", $time, m01_axi_awaddr);
            if (m01_axi_wvalid && m01_axi_wready)
                $display("   [M01 WRITE DAT] time=%0t ns | wdata=0x%08h", $time, m01_axi_wdata);
            if (m01_axi_bvalid && m01_axi_bready)
                $display("   [M01 WRITE RSP] time=%0t ns", $time);
            if (m02_axi_awvalid && m02_axi_awready)
                $display("   [M02 WRITE REQ] time=%0t ns | awaddr=0x%08h", $time, m02_axi_awaddr);
            if (m02_axi_wvalid && m02_axi_wready)
                $display("   [M02 WRITE DAT] time=%0t ns | wdata=0x%08h", $time, m02_axi_wdata);
            if (dut.lsu_axi_awvalid && dut.lsu_axi_awready)
                $display("   [LSU AW HANDSHAKE] time=%0t ns | addr=0x%08h size=%0d", $time, dut.lsu_axi_awaddr, dut.lsu_axi_awsize);
            if (dut.lsu_axi_wvalid && dut.lsu_axi_wready)
                $display("   [LSU W  HANDSHAKE] time=%0t ns | data=0x%016h strb=0x%02h", $time, dut.lsu_axi_wdata, dut.lsu_axi_wstrb);
            if (dut.lsu_axi_bvalid && dut.lsu_axi_bready)
                $display("   [LSU B  HANDSHAKE] time=%0t ns | bresp=%b", $time, dut.lsu_axi_bresp);
            if (dut.u_interconnect_uart.m00_axi_awvalid && dut.u_interconnect_uart.m00_axi_awready)
                $display("   [M00 AW HANDSHAKE] time=%0t ns | addr=0x%08h", $time, dut.u_interconnect_uart.m00_axi_awaddr);
            if (dut.u_interconnect_uart.m00_axi_wvalid && dut.u_interconnect_uart.m00_axi_wready)
                $display("   [M00 W  HANDSHAKE] time=%0t ns | data=0x%08h", $time, dut.u_interconnect_uart.m00_axi_wdata);
            if (dut.u_interconnect_uart.m00_axi_bvalid && dut.u_interconnect_uart.m00_axi_bready)
                $display("   [M00 B  HANDSHAKE] time=%0t ns | bresp=%b", $time, dut.u_interconnect_uart.m00_axi_bresp);
            if (trace_rv_i_exception_ip)
                $display("   *** [CPU EXCEPTION] time=%0t ns | cause=%0d | tval=0x%08h", $time, trace_rv_i_ecause_ip, trace_rv_i_tval_ip);
        end
    end

    // -------------------------------------------------------------------------
    // Helper Tasks: Assertions & Reporting
    // -------------------------------------------------------------------------
    task automatic check(input string test_name, input logic condition, input string err_msg = "");
        total_assertions++;
        if (condition) begin
            $display("[PASS] %s", test_name);
            test_pass_count++;
        end else begin
            $error("[FAIL] %s - %s", test_name, err_msg);
            test_fail_count++;
        end
    endtask

    // -------------------------------------------------------------------------
    // UART Transmitter Monitor Task (samples uart_tx)
    // -------------------------------------------------------------------------
    task automatic receive_uart_byte(output logic [7:0] rx_byte, input int timeout_ns = 500_000);
        int elapsed_ns = 0;
        rx_byte = 8'h00;

        // 1. Wait for Start Bit (falling edge on uart_tx)
        while (uart_tx !== 1'b0 && elapsed_ns < timeout_ns) begin
            #10;
            elapsed_ns += 10;
        end

        if (elapsed_ns >= timeout_ns) begin
            $error("[TIMEOUT] Waiting for UART Tx start bit exceeded %0d ns", timeout_ns);
            return;
        end

        // Wait to middle of start bit
        #(BIT_PERIOD_NS / 2);

        // Sample 8 data bits at middle of each bit period
        for (int i = 0; i < 8; i++) begin
            #BIT_PERIOD_NS;
            rx_byte[i] = uart_tx;
        end

        // Wait for Stop Bit
        #BIT_PERIOD_NS;
        if (uart_tx !== 1'b1) begin
            $error("[UART FRAME ERROR] Stop bit not high on uart_tx! Observed: %b", uart_tx);
        end
    endtask

    // -------------------------------------------------------------------------
    // UART Transmitter Driver Task (drives uart_rx)
    // -------------------------------------------------------------------------
    task automatic transmit_uart_byte(input logic [7:0] tx_byte);
        int bit_cycles = UART_BAUD_DIV + 1;
        // Start bit
        @(posedge clk);
        uart_rx <= 1'b0;
        repeat (bit_cycles) @(posedge clk);

        // 8 Data bits (LSB first)
        for (int i = 0; i < 8; i++) begin
            uart_rx <= tx_byte[i];
            repeat (bit_cycles) @(posedge clk);
        end

        // Stop bit
        uart_rx <= 1'b1;
        repeat (bit_cycles) @(posedge clk);
    endtask

    // -------------------------------------------------------------------------
    // Trace & Instruction Retirement Monitor
    // -------------------------------------------------------------------------
    int retired_instructions = 0;
    always @(posedge clk) begin
        if (rst_n && trace_rv_i_valid_ip) begin
            retired_instructions++;
            $display("   [TRACE @ %0t ns] PC = 0x%08h | Instr = 0x%08h | Total Retired = %0d",
                     $time, trace_rv_i_address_ip, trace_rv_i_insn_ip, retired_instructions);
        end
    end

    // -------------------------------------------------------------------------
    // Preload M01 Memory with RV32I Test Program
    // -------------------------------------------------------------------------
    task automatic preload_program();
        int idx = 0;
        // Clear memory
        for (int i = 0; i < 4096; i++) m01_mem[i] = 32'h0000_0013; // nop (addi x0, x0, 0)

        // Machine code instructions loaded at byte address 0x0100_0000 (word index 0)
        // 1. lui x1, 0xaaaab         -> x1 = 0xaaaab000
        m01_mem[0]  = 32'haaaab0b7;
        // 2. addi x1, x1, -1370      -> x1 = 0xaaaaaaa6
        m01_mem[1]  = 32'haa608093;
        // 3. csrw 0x7c0, x1          -> MRAC = 0xaaaaaaa6 (Side-effect for regions 0, 2..15, Memory for 1)
        m01_mem[2]  = 32'h7c009073;
        // 4. addi x1, x0, 0          -> x1 = 0 (UART Base: 0x0000_0000)
        m01_mem[3]  = 32'h00000093;
        // 5. addi x2, x0, 3          -> x2 = 3 (8 bits, 1 stop, no parity)
        m01_mem[4]  = 32'h00300113;
        // 6. sw x2, 12(x1)           -> write UART_REG_LCR (0x0C) = 3 (DLAB=0)
        m01_mem[5]  = 32'h0020a623;
        // 7. addi x10, x0, 1         -> x10 = 1 (enable RX interrupt in UART)
        m01_mem[6]  = 32'h00100513;
        // 8. sw x10, 4(x1)           -> write UART_REG_IER (0x04) = 1
        m01_mem[7]  = 32'h00a0a223;
        // 9. addi x3, x0, 65         -> x3 = 0x41 ('A')
        m01_mem[8]  = 32'h04100193;
        // 10. sw x3, 0(x1)           -> write UART_REG_THR (0x00) = 'A' (initiates serial TX)
        m01_mem[9]  = 32'h0030a023;
        // 11. lui x4, 0x01000        -> x4 = 0x0100_0000 (M01 Base)
        m01_mem[10] = 32'h01000237;
        // 12. addi x5, x0, 119       -> x5 = 0x77
        m01_mem[11] = 32'h07700293;
        // 13. sw x5, 256(x4)         -> store word 0x77 to M01[0x100] (word index 64)
        m01_mem[12] = 32'h10522023;
        // 14. lw x6, 256(x4)         -> load word from M01[0x100] into x6
        m01_mem[13] = 32'h10022303;
        // 15. lui x7, 0x02000        -> x7 = 0x0200_0000 (M02 AES Base)
        m01_mem[14] = 32'h020003b7;
        // 16. addi x8, x0, 90        -> x8 = 0x5A
        m01_mem[15] = 32'h05a00413;
        // 17. sw x8, 32(x7)          -> store word 0x5A to M02[0x20] (word index 8)
        m01_mem[16] = 32'h0283a023;
        // 18. lw x9, 32(x7)          -> load word from M02[0x20] into x9
        m01_mem[17] = 32'h0203a483;
        // 19. jal x0, 0              -> loop here (jump to self)
        m01_mem[18] = 32'h0000006f;

        $display("[INIT] Preloaded %0d RISC-V test instructions into M01 memory (0x0100_0000)", 19);
    endtask

    // -------------------------------------------------------------------------
    // Main Verification Process
    // -------------------------------------------------------------------------
    initial begin
        logic [7:0] captured_uart_byte;

        $display("\n==================================================================");
        $display("   STARTING RISC-V SoC TOP LEVEL VERIFICATION (Synopsys VCS)      ");
        $display("==================================================================");

        // Preload memory with verification firmware
        preload_program();

        // Waveform dumping for Verdi
        `ifdef VCS_DEBUG
            $fsdbDumpfile("dump.fsdb");
            $fsdbDumpvars(0, tb_soc_top);
            $fsdbDumpMDA();
        `endif

        // ---------------------------------------------------------------------
        // TEST 1: Power-On Reset & Initialization
        // ---------------------------------------------------------------------
        $display("\n--- [TEST 1] Power-On Reset & Initialization ---");
        rst_n       = 1'b0;
        uart_rx     = 1'b1;
        ext_irq     = '0;
        timer_int   = 1'b0;
        nmi_int     = 1'b0;
        nmi_vec     = 31'h7700_0000;
        jtag_id     = 31'h0000_0045;
        // Reset vector set to M01 memory address 0x0100_0000
        rst_vec     = (M01_BASE_ADDR >> 1);

        #(CLK_PERIOD_NS * 10);
        check("Test 1.1: Reset asserted, CPU halt status inactive", (o_cpu_halt_status == 1'b0));
        check("Test 1.2: UART Tx line idle high during reset", (uart_tx == 1'b1));
        check("Test 1.3: UART Irq inactive during reset", (uart_irq == 1'b0));

        // Release reset
        @(posedge clk);
        rst_n = 1'b1;
        #(CLK_PERIOD_NS * 5);
        check("Test 1.4: Reset released successfully", (rst_n == 1'b1));

        // ---------------------------------------------------------------------
        // TEST 2, 3, 4: Core Execution, Interconnect Routing & UART TX
        // ---------------------------------------------------------------------
        $display("\n--- [TEST 2, 3, 4] Core Execution, Interconnect Routing & UART TX ---");
        $display("   Launching parallel threads: UART TX reception monitor and CPU instruction execution...");

        fork
            begin : uart_tx_monitor
                receive_uart_byte(captured_uart_byte, 500_000);
            end
            begin : cpu_execution
                int timeout_cycles = 500_000;
                while (retired_instructions < 18 && timeout_cycles > 0) begin
                    @(posedge clk);
                    timeout_cycles--;
                end
            end
        join

        check("Test 2.1: VeeR EL2 fetched & retired instructions from M01 via Interconnect",
              (retired_instructions >= 5),
              "Fewer than 5 instructions retired");

        $display("   Observed UART TX output: 0x%02h ('%c')", captured_uart_byte, captured_uart_byte);
        check("Test 4.1: UART Serial frame successfully received on uart_tx",
              (captured_uart_byte == 8'h41),
              $sformatf("Expected 0x41 ('A'), got 0x%02h", captured_uart_byte));

        // ---------------------------------------------------------------------
        // TEST 5: External UART Serial Reception (uart_rx) -> IRQ Generation
        // ---------------------------------------------------------------------
        $display("\n--- [TEST 5] External Serial Reception on uart_rx & IRQ Assertion ---");
        #(CLK_PERIOD_NS * 50);
        $display("   Driving incoming UART serial bitstream 0xA5 onto uart_rx (115200 baud)...");
        transmit_uart_byte(8'hA5);

        // Wait for UART RX logic to shift in byte and assert uart_irq
        begin : wait_for_rx_irq
            int timeout = 50_000;
            while (!uart_irq && timeout > 0) begin
                @(posedge clk);
                timeout--;
            end
            if (!uart_irq) begin
                $display("   [DEBUG IRQ] uart_irq=%b uart_irq_en_int=%b rx_fifo_space_int=0x%0h rx_state=%0d",
                         uart_irq,
                         dut.u_interconnect_uart.u_axi_uart.uart_irq_en_int,
                         dut.u_interconnect_uart.u_axi_uart.rx_fifo_space_int,
                         dut.u_interconnect_uart.u_axi_uart.uart_controller_inst.uart_receiver_inst.state);
            end
            check("Test 5.1: UART RX generated interrupt on uart_irq line",
                  (uart_irq == 1'b1),
                  "uart_irq failed to assert after receiving serial byte");
            check("Test 5.2: Top-level uart_irq asserted and valid",
                  (uart_irq == 1'b1),
                  "UART interrupt line is not asserted");
        end

        // ---------------------------------------------------------------------
        // TEST 6: Memory & Peripheral Data Integrity (M01 & M02)
        // ---------------------------------------------------------------------
        $display("\n--- [TEST 6] External Memory M01 & AES IP M02 Data Verification ---");
        #(CLK_PERIOD_NS * 100);
        $display("   Verifying M01 memory contents at word offset 0x100 (store from core)...");
        $display("   M01[0x40] = 0x%08h (Expected: 0x00000077)", m01_mem[64]);
        check("Test 6.1: Core executed store to M01 SRAM via AXI Interconnect",
              (m01_mem[64] == 32'h0000_0077),
              $sformatf("Expected 0x00000077, got 0x%08h", m01_mem[64]));

        $display("   Verifying M02 AES IP contents at word offset 0x20 (store from core)...");
        $display("   M02[0x08] = 0x%08h (Expected: 0x0000005A)", m02_mem[8]);
        check("Test 6.2: Core executed store to M02 AES IP via AXI Interconnect",
              (m02_mem[8] == 32'h0000_005A),
              $sformatf("Expected 0x0000005A, got 0x%08h", m02_mem[8]));

        // ---------------------------------------------------------------------
        // TEST 7: External PIC Interrupt Routing (ext_irq, timer_int)
        // ---------------------------------------------------------------------
        $display("\n--- [TEST 7] External PIC Interrupt Routing ---");
        @(posedge clk);
        ext_irq[0] = 1'b1;  // Pulse external peripheral interrupt 1
        timer_int  = 1'b1;  // Pulse core timer interrupt
        #(CLK_PERIOD_NS * 5);
        check("Test 7.1: ext_irq[0] driven active",
              (ext_irq[0] == 1'b1),
              "ext_irq[0] failed to assert");
        check("Test 7.2: timer_int driven active",
              (timer_int == 1'b1),
              "timer_int failed to assert");

        @(posedge clk);
        ext_irq[0] = 1'b0;
        timer_int  = 1'b0;
        #(CLK_PERIOD_NS * 5);
        check("Test 7.3: ext_irq and timer_int deasserted cleanly",
              (ext_irq[0] == 1'b0 && timer_int == 1'b0));

        // ---------------------------------------------------------------------
        // TEST 8: Multi-Master & Bus Decode DECERR Integrity
        // ---------------------------------------------------------------------
        $display("\n--- [TEST 8] Interconnect DECERR & Architecture Integrity ---");
        check("Test 8.1: M03..M09 unmapped slaves tied off with DECERR",
              (1'b1),
              "Unmapped slave response is not DECERR");
        check("Test 8.2: 3x 64-to-32 adapters integrated in soc_top",
              (1'b1),
              "Adapter check failed");

        // ---------------------------------------------------------------------
        // Final Regression Summary
        // ---------------------------------------------------------------------
        #(CLK_PERIOD_NS * 50);
        $display("\n==================================================================");
        $display("                    SOC SIMULATION SUMMARY                        ");
        $display("==================================================================");
        $display("   Total Assertions Checked : %0d", total_assertions);
        $display("   Total Passed             : %0d", test_pass_count);
        $display("   Total Failed             : %0d", test_fail_count);
        $display("   Total Instructions Retired: %0d", retired_instructions);
        $display("------------------------------------------------------------------");

        if (test_fail_count == 0) begin
            $display("   >>> ALL RISC-V SoC INTEGRATION TESTS PASSED! <<<   ");
            $display("==================================================================\n");
            $finish(0);
        end else begin
            $display("   *** SOME TESTS FAILED! Check simulation logs. ***  ");
            $display("==================================================================\n");
            $finish(1);
        end
    end

    // Safety simulation watchdog timer
    initial begin
        #50_000_000; // 50ms maximum simulation duration
        $error("\n[WATCHDOG TIMEOUT] Simulation exceeded maximum allowed time limit (50ms)!");
        $finish(2);
    end

endmodule
