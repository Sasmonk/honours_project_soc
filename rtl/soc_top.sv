/*
 * RISC-V SoC Top-Level Integration Module (soc_top)
 *
 * Integrates:
 * 1. Western Digital / CHIPS Alliance VeeR EL2 RISC-V Core (veer_wrapper)
 *    - 32-bit RV32IMC RISC-V processor core
 *    - 64-bit AXI4 Master interfaces (LSU, IFU, SB)
 * 2. AXI4 64-to-32 Width Adapters:
 *    - Converts 64-bit LSU master traffic to 32-bit for Interconnect Slave Port 00 (s00)
 *    - Converts 64-bit IFU master traffic to 32-bit for Interconnect Slave Port 01 (s01)
 *    - Converts 64-bit SB debug master traffic to 32-bit for Interconnect Slave Port 02 (s02)
 * 3. 3-Master x 10-Slave AXI4 Interconnect (axi_interconnect_uart_top):
 *    - Master Port 00 (M00): Dedicated internal connection to AXI4-Lite UART IP core
 *    - Master Ports 01..09 (M01..M09): Exported to boundary for external peripherals
 *      (e.g., Boot ROM, RAM, AES Accelerator, Timer, GPIO, FIR, DMA, VGA, WDT)
 * 4. UART Peripheral Interface:
 *    - uart_rx, uart_tx, and uart_irq brought out to boundary
 *    - uart_irq internally connected to Core PIC external interrupt input extintsrc_req[0]
 */

`resetall
`timescale 1ns / 1ps
`default_nettype none

module soc_top
import el2_pkg::*;
#(
    `include "el2_param.vh"
    ,
    // Bus & Memory Parameters
    parameter DATA_WIDTH       = 32,
    parameter ADDR_WIDTH       = 32,
    parameter STRB_WIDTH       = (DATA_WIDTH/8),
    parameter ID_WIDTH         = 8,
    parameter AWUSER_ENABLE    = 0,
    parameter AWUSER_WIDTH     = 1,
    parameter WUSER_ENABLE     = 0,
    parameter WUSER_WIDTH      = 1,
    parameter BUSER_ENABLE     = 0,
    parameter BUSER_WIDTH      = 1,
    parameter ARUSER_ENABLE    = 0,
    parameter ARUSER_WIDTH     = 1,
    parameter RUSER_ENABLE     = 0,
    parameter RUSER_WIDTH      = 1,
    parameter FORWARD_ID       = 0,
    parameter M_REGIONS        = 1,

    // Base Addresses for Peripherals on Interconnect
    parameter UART_BASE_ADDR   = 32'h0000_0000,
    parameter UART_ADDR_WIDTH  = {M_REGIONS{32'd24}},

    parameter M01_BASE_ADDR    = 32'h0100_0000, // Ext Peripheral / Memory 1
    parameter M01_ADDR_WIDTH   = {M_REGIONS{32'd24}},

    parameter M02_BASE_ADDR    = 32'h0200_0000, // AES Core / Ext Peripheral 2
    parameter M02_ADDR_WIDTH   = {M_REGIONS{32'd24}},

    parameter M03_BASE_ADDR    = 32'h0300_0000, // GPIO / Ext Peripheral 3
    parameter M03_ADDR_WIDTH   = {M_REGIONS{32'd24}},

    parameter M04_BASE_ADDR    = 32'h0400_0000, // Timer / Ext Peripheral 4
    parameter M04_ADDR_WIDTH   = {M_REGIONS{32'd24}},

    parameter M05_BASE_ADDR    = 32'h0500_0000, // FIR Filter / Ext Peripheral 5
    parameter M05_ADDR_WIDTH   = {M_REGIONS{32'd24}},

    parameter M06_BASE_ADDR    = 32'h0600_0000, // DMA / Ext Peripheral 6
    parameter M06_ADDR_WIDTH   = {M_REGIONS{32'd24}},

    parameter M07_BASE_ADDR    = 32'h0700_0000, // VGA / Ext Peripheral 7
    parameter M07_ADDR_WIDTH   = {M_REGIONS{32'd24}},

    parameter M08_BASE_ADDR    = 32'h0800_0000, // Watchdog / Ext Peripheral 8
    parameter M08_ADDR_WIDTH   = {M_REGIONS{32'd24}},

    parameter M09_BASE_ADDR    = 32'h0900_0000, // Sample Buffer / Ext Peripheral 9
    parameter M09_ADDR_WIDTH   = {M_REGIONS{32'd24}}
)
(
    // Global Clock and Active-Low Reset
    input  wire                              clk,
    input  wire                              rst_n,

    // Core Control
    input  wire [31:1]                       rst_vec,
    input  wire                              nmi_int,
    input  wire [31:1]                       nmi_vec,
    input  wire [31:1]                       jtag_id,

    // UART Physical Interface & Interrupt
    input  wire                              uart_rx,
    output wire                              uart_tx,
    output wire                              uart_irq,

    // External Interrupt Inputs for Additional Peripherals (Timer, GPIO, FIR, etc.)
    input  wire [pt.PIC_TOTAL_INT-2:0]       ext_irq,
    input  wire                              timer_int,

    // Instruction Execution Trace Interface (for verification & debug)
    output wire [31:0]                       trace_rv_i_insn_ip,
    output wire [31:0]                       trace_rv_i_address_ip,
    output wire                              trace_rv_i_valid_ip,
    output wire                              trace_rv_i_exception_ip,
    output wire [4:0]                        trace_rv_i_ecause_ip,
    output wire                              trace_rv_i_interrupt_ip,
    output wire [31:0]                       trace_rv_i_tval_ip,

    // CPU Status
    output wire                              o_cpu_halt_status,
    output wire                              o_cpu_halt_ack,
    output wire                              o_debug_mode_status,

    // =========================================================================
    // Master Port 01 Interface (M01: Memory / Peripherals)
    // =========================================================================
    output wire [ID_WIDTH-1:0]               m01_axi_awid,
    output wire [ADDR_WIDTH-1:0]             m01_axi_awaddr,
    output wire [7:0]                        m01_axi_awlen,
    output wire [2:0]                        m01_axi_awsize,
    output wire [1:0]                        m01_axi_awburst,
    output wire                              m01_axi_awlock,
    output wire [3:0]                        m01_axi_awcache,
    output wire [2:0]                        m01_axi_awprot,
    output wire [3:0]                        m01_axi_awqos,
    output wire [3:0]                        m01_axi_awregion,
    output wire [AWUSER_WIDTH-1:0]           m01_axi_awuser,
    output wire                              m01_axi_awvalid,
    input  wire                              m01_axi_awready,
    output wire [DATA_WIDTH-1:0]             m01_axi_wdata,
    output wire [STRB_WIDTH-1:0]             m01_axi_wstrb,
    output wire                              m01_axi_wlast,
    output wire [WUSER_WIDTH-1:0]            m01_axi_wuser,
    output wire                              m01_axi_wvalid,
    input  wire                              m01_axi_wready,
    input  wire [ID_WIDTH-1:0]               m01_axi_bid,
    input  wire [1:0]                        m01_axi_bresp,
    input  wire [BUSER_WIDTH-1:0]            m01_axi_buser,
    input  wire                              m01_axi_bvalid,
    output wire                              m01_axi_bready,
    output wire [ID_WIDTH-1:0]               m01_axi_arid,
    output wire [ADDR_WIDTH-1:0]             m01_axi_araddr,
    output wire [7:0]                        m01_axi_arlen,
    output wire [2:0]                        m01_axi_arsize,
    output wire [1:0]                        m01_axi_arburst,
    output wire                              m01_axi_arlock,
    output wire [3:0]                        m01_axi_arcache,
    output wire [2:0]                        m01_axi_arprot,
    output wire [3:0]                        m01_axi_arqos,
    output wire [3:0]                        m01_axi_arregion,
    output wire [ARUSER_WIDTH-1:0]           m01_axi_aruser,
    output wire                              m01_axi_arvalid,
    input  wire                              m01_axi_arready,
    input  wire [ID_WIDTH-1:0]               m01_axi_rid,
    input  wire [DATA_WIDTH-1:0]             m01_axi_rdata,
    input  wire [1:0]                        m01_axi_rresp,
    input  wire                              m01_axi_rlast,
    input  wire [RUSER_WIDTH-1:0]            m01_axi_ruser,
    input  wire                              m01_axi_rvalid,
    output wire                              m01_axi_rready,

    // =========================================================================
    // Master Port 02 Interface (M02: AES Core / Peripherals)
    // =========================================================================
    output wire [ID_WIDTH-1:0]               m02_axi_awid,
    output wire [ADDR_WIDTH-1:0]             m02_axi_awaddr,
    output wire [7:0]                        m02_axi_awlen,
    output wire [2:0]                        m02_axi_awsize,
    output wire [1:0]                        m02_axi_awburst,
    output wire                              m02_axi_awlock,
    output wire [3:0]                        m02_axi_awcache,
    output wire [2:0]                        m02_axi_awprot,
    output wire [3:0]                        m02_axi_awqos,
    output wire [3:0]                        m02_axi_awregion,
    output wire [AWUSER_WIDTH-1:0]           m02_axi_awuser,
    output wire                              m02_axi_awvalid,
    input  wire                              m02_axi_awready,
    output wire [DATA_WIDTH-1:0]             m02_axi_wdata,
    output wire [STRB_WIDTH-1:0]             m02_axi_wstrb,
    output wire                              m02_axi_wlast,
    output wire [WUSER_WIDTH-1:0]            m02_axi_wuser,
    output wire                              m02_axi_wvalid,
    input  wire                              m02_axi_wready,
    input  wire [ID_WIDTH-1:0]               m02_axi_bid,
    input  wire [1:0]                        m02_axi_bresp,
    input  wire [BUSER_WIDTH-1:0]            m02_axi_buser,
    input  wire                              m02_axi_bvalid,
    output wire                              m02_axi_bready,
    output wire [ID_WIDTH-1:0]               m02_axi_arid,
    output wire [ADDR_WIDTH-1:0]             m02_axi_araddr,
    output wire [7:0]                        m02_axi_arlen,
    output wire [2:0]                        m02_axi_arsize,
    output wire [1:0]                        m02_axi_arburst,
    output wire                              m02_axi_arlock,
    output wire [3:0]                        m02_axi_arcache,
    output wire [2:0]                        m02_axi_arprot,
    output wire [3:0]                        m02_axi_arqos,
    output wire [3:0]                        m02_axi_arregion,
    output wire [ARUSER_WIDTH-1:0]           m02_axi_aruser,
    output wire                              m02_axi_arvalid,
    input  wire                              m02_axi_arready,
    input  wire [ID_WIDTH-1:0]               m02_axi_rid,
    input  wire [DATA_WIDTH-1:0]             m02_axi_rdata,
    input  wire [1:0]                        m02_axi_rresp,
    input  wire                              m02_axi_rlast,
    input  wire [RUSER_WIDTH-1:0]            m02_axi_ruser,
    input  wire                              m02_axi_rvalid,
    output wire                              m02_axi_rready
);

    // Active-high reset for interconnect & adapters
    wire rst = ~rst_n;

    // Interrupt vector to core PIC
    wire [pt.PIC_TOTAL_INT-1:0] core_extintsrc_req;
    assign core_extintsrc_req[0] = uart_irq;
    assign core_extintsrc_req[pt.PIC_TOTAL_INT-1:1] = ext_irq;

    // =========================================================================
    // Core 64-bit AXI Signals
    // =========================================================================
    // LSU AXI (64-bit)
    wire                      lsu_axi_awvalid;
    wire                      lsu_axi_awready;
    wire [pt.LSU_BUS_TAG-1:0] lsu_axi_awid;
    wire [31:0]               lsu_axi_awaddr;
    wire [3:0]                lsu_axi_awregion;
    wire [7:0]                lsu_axi_awlen;
    wire [2:0]                lsu_axi_awsize;
    wire [1:0]                lsu_axi_awburst;
    wire                      lsu_axi_awlock;
    wire [3:0]                lsu_axi_awcache;
    wire [2:0]                lsu_axi_awprot;
    wire [3:0]                lsu_axi_awqos;
    wire                      lsu_axi_wvalid;
    wire                      lsu_axi_wready;
    wire [63:0]               lsu_axi_wdata;
    wire [7:0]                lsu_axi_wstrb;
    wire                      lsu_axi_wlast;
    wire                      lsu_axi_bvalid;
    wire                      lsu_axi_bready;
    wire [1:0]                lsu_axi_bresp;
    wire [pt.LSU_BUS_TAG-1:0] lsu_axi_bid;
    wire                      lsu_axi_arvalid;
    wire                      lsu_axi_arready;
    wire [pt.LSU_BUS_TAG-1:0] lsu_axi_arid;
    wire [31:0]               lsu_axi_araddr;
    wire [3:0]                lsu_axi_arregion;
    wire [7:0]                lsu_axi_arlen;
    wire [2:0]                lsu_axi_arsize;
    wire [1:0]                lsu_axi_arburst;
    wire                      lsu_axi_arlock;
    wire [3:0]                lsu_axi_arcache;
    wire [2:0]                lsu_axi_arprot;
    wire [3:0]                lsu_axi_arqos;
    wire                      lsu_axi_rvalid;
    wire                      lsu_axi_rready;
    wire [pt.LSU_BUS_TAG-1:0] lsu_axi_rid;
    wire [63:0]               lsu_axi_rdata;
    wire [1:0]                lsu_axi_rresp;
    wire                      lsu_axi_rlast;

    // IFU AXI (64-bit)
    wire                      ifu_axi_awvalid;
    wire                      ifu_axi_awready;
    wire [pt.IFU_BUS_TAG-1:0] ifu_axi_awid;
    wire [31:0]               ifu_axi_awaddr;
    wire [3:0]                ifu_axi_awregion;
    wire [7:0]                ifu_axi_awlen;
    wire [2:0]                ifu_axi_awsize;
    wire [1:0]                ifu_axi_awburst;
    wire                      ifu_axi_awlock;
    wire [3:0]                ifu_axi_awcache;
    wire [2:0]                ifu_axi_awprot;
    wire [3:0]                ifu_axi_awqos;
    wire                      ifu_axi_wvalid;
    wire                      ifu_axi_wready;
    wire [63:0]               ifu_axi_wdata;
    wire [7:0]                ifu_axi_wstrb;
    wire                      ifu_axi_wlast;
    wire                      ifu_axi_bvalid;
    wire                      ifu_axi_bready;
    wire [1:0]                ifu_axi_bresp;
    wire [pt.IFU_BUS_TAG-1:0] ifu_axi_bid;
    wire                      ifu_axi_arvalid;
    wire                      ifu_axi_arready;
    wire [pt.IFU_BUS_TAG-1:0] ifu_axi_arid;
    wire [31:0]               ifu_axi_araddr;
    wire [3:0]                ifu_axi_arregion;
    wire [7:0]                ifu_axi_arlen;
    wire [2:0]                ifu_axi_arsize;
    wire [1:0]                ifu_axi_arburst;
    wire                      ifu_axi_arlock;
    wire [3:0]                ifu_axi_arcache;
    wire [2:0]                ifu_axi_arprot;
    wire [3:0]                ifu_axi_arqos;
    wire                      ifu_axi_rvalid;
    wire                      ifu_axi_rready;
    wire [pt.IFU_BUS_TAG-1:0] ifu_axi_rid;
    wire [63:0]               ifu_axi_rdata;
    wire [1:0]                ifu_axi_rresp;
    wire                      ifu_axi_rlast;

    // SB AXI (64-bit)
    wire                      sb_axi_awvalid;
    wire                      sb_axi_awready;
    wire [pt.SB_BUS_TAG-1:0]  sb_axi_awid;
    wire [31:0]               sb_axi_awaddr;
    wire [3:0]                sb_axi_awregion;
    wire [7:0]                sb_axi_awlen;
    wire [2:0]                sb_axi_awsize;
    wire [1:0]                sb_axi_awburst;
    wire                      sb_axi_awlock;
    wire [3:0]                sb_axi_awcache;
    wire [2:0]                sb_axi_awprot;
    wire [3:0]                sb_axi_awqos;
    wire                      sb_axi_wvalid;
    wire                      sb_axi_wready;
    wire [63:0]               sb_axi_wdata;
    wire [7:0]                sb_axi_wstrb;
    wire                      sb_axi_wlast;
    wire                      sb_axi_bvalid;
    wire                      sb_axi_bready;
    wire [1:0]                sb_axi_bresp;
    wire [pt.SB_BUS_TAG-1:0]  sb_axi_bid;
    wire                      sb_axi_arvalid;
    wire                      sb_axi_arready;
    wire [pt.SB_BUS_TAG-1:0]  sb_axi_arid;
    wire [31:0]               sb_axi_araddr;
    wire [3:0]                sb_axi_arregion;
    wire [7:0]                sb_axi_arlen;
    wire [2:0]                sb_axi_arsize;
    wire [1:0]                sb_axi_arburst;
    wire                      sb_axi_arlock;
    wire [3:0]                sb_axi_arcache;
    wire [2:0]                sb_axi_arprot;
    wire [3:0]                sb_axi_arqos;
    wire                      sb_axi_rvalid;
    wire                      sb_axi_rready;
    wire [pt.SB_BUS_TAG-1:0]  sb_axi_rid;
    wire [63:0]               sb_axi_rdata;
    wire [1:0]                sb_axi_rresp;
    wire                      sb_axi_rlast;

    // =========================================================================
    // 1. VeeR EL2 RISC-V Core Instance
    // =========================================================================
    veer_wrapper u_veer_core (
        .clk                    (clk),
        .rst_l                  (rst_n),
        .dbg_rst_l              (rst_n),
        .rst_vec                (rst_vec),
        .nmi_int                (nmi_int),
        .nmi_vec                (nmi_vec),
        .jtag_id                (jtag_id),

        // Interrupts
        .timer_int              (timer_int),
        .extintsrc_req          (core_extintsrc_req),

        // Clock ratios
        .lsu_bus_clk_en         (1'b1),
        .ifu_bus_clk_en         (1'b1),
        .dbg_bus_clk_en         (1'b1),
        .dma_bus_clk_en         (1'b1),

        // Trace
        .trace_rv_i_insn_ip     (trace_rv_i_insn_ip),
        .trace_rv_i_address_ip  (trace_rv_i_address_ip),
        .trace_rv_i_valid_ip    (trace_rv_i_valid_ip),
        .trace_rv_i_exception_ip(trace_rv_i_exception_ip),
        .trace_rv_i_ecause_ip   (trace_rv_i_ecause_ip),
        .trace_rv_i_interrupt_ip(trace_rv_i_interrupt_ip),
        .trace_rv_i_tval_ip     (trace_rv_i_tval_ip),

        // Core Control & Status
        .mpc_debug_halt_req     (1'b0),
        .mpc_debug_run_req      (1'b0),
        .mpc_reset_run_req      (1'b1),
        .mpc_debug_halt_ack     (),
        .mpc_debug_run_ack      (),
        .debug_brkpt_status     (),
        .i_cpu_halt_req         (1'b0),
        .o_cpu_halt_ack         (o_cpu_halt_ack),
        .o_cpu_halt_status      (o_cpu_halt_status),
        .o_debug_mode_status    (o_debug_mode_status),
        .i_cpu_run_req          (1'b0),
        .o_cpu_run_ack          (),
        .scan_mode              (1'b0),
        .mbist_mode             (1'b0),
        .dmi_core_enable        (1'b0),
        .dmi_uncore_enable      (1'b0),
        .dmi_uncore_en          (),
        .dmi_uncore_wr_en       (),
        .dmi_uncore_addr        (),
        .dmi_uncore_wdata       (),
        .dmi_uncore_rdata       (32'd0),
        .dmi_active             (),

        // LSU AXI
        .lsu_axi_awvalid        (lsu_axi_awvalid),
        .lsu_axi_awready        (lsu_axi_awready),
        .lsu_axi_awid           (lsu_axi_awid),
        .lsu_axi_awaddr         (lsu_axi_awaddr),
        .lsu_axi_awregion       (lsu_axi_awregion),
        .lsu_axi_awlen          (lsu_axi_awlen),
        .lsu_axi_awsize         (lsu_axi_awsize),
        .lsu_axi_awburst        (lsu_axi_awburst),
        .lsu_axi_awlock         (lsu_axi_awlock),
        .lsu_axi_awcache        (lsu_axi_awcache),
        .lsu_axi_awprot         (lsu_axi_awprot),
        .lsu_axi_awqos          (lsu_axi_awqos),
        .lsu_axi_wvalid         (lsu_axi_wvalid),
        .lsu_axi_wready         (lsu_axi_wready),
        .lsu_axi_wdata          (lsu_axi_wdata),
        .lsu_axi_wstrb          (lsu_axi_wstrb),
        .lsu_axi_wlast          (lsu_axi_wlast),
        .lsu_axi_bvalid         (lsu_axi_bvalid),
        .lsu_axi_bready         (lsu_axi_bready),
        .lsu_axi_bresp          (lsu_axi_bresp),
        .lsu_axi_bid            (lsu_axi_bid),
        .lsu_axi_arvalid        (lsu_axi_arvalid),
        .lsu_axi_arready        (lsu_axi_arready),
        .lsu_axi_arid           (lsu_axi_arid),
        .lsu_axi_araddr         (lsu_axi_araddr),
        .lsu_axi_arregion       (lsu_axi_arregion),
        .lsu_axi_arlen          (lsu_axi_arlen),
        .lsu_axi_arsize         (lsu_axi_arsize),
        .lsu_axi_arburst        (lsu_axi_arburst),
        .lsu_axi_arlock         (lsu_axi_arlock),
        .lsu_axi_arcache        (lsu_axi_arcache),
        .lsu_axi_arprot         (lsu_axi_arprot),
        .lsu_axi_arqos          (lsu_axi_arqos),
        .lsu_axi_rvalid         (lsu_axi_rvalid),
        .lsu_axi_rready         (lsu_axi_rready),
        .lsu_axi_rid            (lsu_axi_rid),
        .lsu_axi_rdata          (lsu_axi_rdata),
        .lsu_axi_rresp          (lsu_axi_rresp),
        .lsu_axi_rlast          (lsu_axi_rlast),

        // IFU AXI
        .ifu_axi_awvalid        (ifu_axi_awvalid),
        .ifu_axi_awready        (ifu_axi_awready),
        .ifu_axi_awid           (ifu_axi_awid),
        .ifu_axi_awaddr         (ifu_axi_awaddr),
        .ifu_axi_awregion       (ifu_axi_awregion),
        .ifu_axi_awlen          (ifu_axi_awlen),
        .ifu_axi_awsize         (ifu_axi_awsize),
        .ifu_axi_awburst        (ifu_axi_awburst),
        .ifu_axi_awlock         (ifu_axi_awlock),
        .ifu_axi_awcache        (ifu_axi_awcache),
        .ifu_axi_awprot         (ifu_axi_awprot),
        .ifu_axi_awqos          (ifu_axi_awqos),
        .ifu_axi_wvalid         (ifu_axi_wvalid),
        .ifu_axi_wready         (ifu_axi_wready),
        .ifu_axi_wdata          (ifu_axi_wdata),
        .ifu_axi_wstrb          (ifu_axi_wstrb),
        .ifu_axi_wlast          (ifu_axi_wlast),
        .ifu_axi_bvalid         (ifu_axi_bvalid),
        .ifu_axi_bready         (ifu_axi_bready),
        .ifu_axi_bresp          (ifu_axi_bresp),
        .ifu_axi_bid            (ifu_axi_bid),
        .ifu_axi_arvalid        (ifu_axi_arvalid),
        .ifu_axi_arready        (ifu_axi_arready),
        .ifu_axi_arid           (ifu_axi_arid),
        .ifu_axi_araddr         (ifu_axi_araddr),
        .ifu_axi_arregion       (ifu_axi_arregion),
        .ifu_axi_arlen          (ifu_axi_arlen),
        .ifu_axi_arsize         (ifu_axi_arsize),
        .ifu_axi_arburst        (ifu_axi_arburst),
        .ifu_axi_arlock         (ifu_axi_arlock),
        .ifu_axi_arcache        (ifu_axi_arcache),
        .ifu_axi_arprot         (ifu_axi_arprot),
        .ifu_axi_arqos          (ifu_axi_arqos),
        .ifu_axi_rvalid         (ifu_axi_rvalid),
        .ifu_axi_rready         (ifu_axi_rready),
        .ifu_axi_rid            (ifu_axi_rid),
        .ifu_axi_rdata          (ifu_axi_rdata),
        .ifu_axi_rresp          (ifu_axi_rresp),
        .ifu_axi_rlast          (ifu_axi_rlast),

        // SB AXI
        .sb_axi_awvalid         (sb_axi_awvalid),
        .sb_axi_awready         (sb_axi_awready),
        .sb_axi_awid            (sb_axi_awid),
        .sb_axi_awaddr          (sb_axi_awaddr),
        .sb_axi_awregion        (sb_axi_awregion),
        .sb_axi_awlen           (sb_axi_awlen),
        .sb_axi_awsize          (sb_axi_awsize),
        .sb_axi_awburst         (sb_axi_awburst),
        .sb_axi_awlock          (sb_axi_awlock),
        .sb_axi_awcache         (sb_axi_awcache),
        .sb_axi_awprot          (sb_axi_awprot),
        .sb_axi_awqos           (sb_axi_awqos),
        .sb_axi_wvalid          (sb_axi_wvalid),
        .sb_axi_wready          (sb_axi_wready),
        .sb_axi_wdata           (sb_axi_wdata),
        .sb_axi_wstrb           (sb_axi_wstrb),
        .sb_axi_wlast           (sb_axi_wlast),
        .sb_axi_bvalid          (sb_axi_bvalid),
        .sb_axi_bready          (sb_axi_bready),
        .sb_axi_bresp           (sb_axi_bresp),
        .sb_axi_bid             (sb_axi_bid),
        .sb_axi_arvalid         (sb_axi_arvalid),
        .sb_axi_arready         (sb_axi_arready),
        .sb_axi_arid            (sb_axi_arid),
        .sb_axi_araddr          (sb_axi_araddr),
        .sb_axi_arregion        (sb_axi_arregion),
        .sb_axi_arlen           (sb_axi_arlen),
        .sb_axi_arsize          (sb_axi_arsize),
        .sb_axi_arburst         (sb_axi_arburst),
        .sb_axi_arlock          (sb_axi_arlock),
        .sb_axi_arcache         (sb_axi_arcache),
        .sb_axi_arprot          (sb_axi_arprot),
        .sb_axi_arqos           (sb_axi_arqos),
        .sb_axi_rvalid          (sb_axi_rvalid),
        .sb_axi_rready          (sb_axi_rready),
        .sb_axi_rid             (sb_axi_rid),
        .sb_axi_rdata           (sb_axi_rdata),
        .sb_axi_rresp           (sb_axi_rresp),
        .sb_axi_rlast           (sb_axi_rlast),

        // DMA AXI slave into DCCM/ICCM (tied off by default)
        .dma_axi_awvalid        (1'b0),
        .dma_axi_awready        (),
        .dma_axi_awid           ('0),
        .dma_axi_awaddr         (32'd0),
        .dma_axi_awsize         (3'd0),
        .dma_axi_awprot         (3'd0),
        .dma_axi_awlen          (8'd0),
        .dma_axi_awburst        (2'd0),
        .dma_axi_wvalid         (1'b0),
        .dma_axi_wready         (),
        .dma_axi_wdata          (64'd0),
        .dma_axi_wstrb          (8'd0),
        .dma_axi_wlast          (1'b0),
        .dma_axi_bvalid         (),
        .dma_axi_bready         (1'b0),
        .dma_axi_bresp          (),
        .dma_axi_bid            (),
        .dma_axi_arvalid        (1'b0),
        .dma_axi_arready        (),
        .dma_axi_arid           ('0),
        .dma_axi_araddr         (32'd0),
        .dma_axi_arsize         (3'd0),
        .dma_axi_arprot         (3'd0),
        .dma_axi_arlen          (8'd0),
        .dma_axi_arburst        (2'd0),
        .dma_axi_rvalid         (),
        .dma_axi_rready         (1'b0),
        .dma_axi_rid            (),
        .dma_axi_rdata          (),
        .dma_axi_rresp          (),
        .dma_axi_rlast          ()
    );

    // =========================================================================
    // 2. AXI Adapters: 64-bit Core Masters -> 32-bit Interconnect Slaves
    // =========================================================================
    // Slave 00: LSU (Core 0 Load/Store Unit)
    wire [ID_WIDTH-1:0]     s00_axi_awid;
    wire [ADDR_WIDTH-1:0]   s00_axi_awaddr;
    wire [7:0]              s00_axi_awlen;
    wire [2:0]              s00_axi_awsize;
    wire [1:0]              s00_axi_awburst;
    wire                    s00_axi_awlock;
    wire [3:0]              s00_axi_awcache;
    wire [2:0]              s00_axi_awprot;
    wire [3:0]              s00_axi_awqos;
    wire [3:0]              s00_axi_awregion;
    wire [AWUSER_WIDTH-1:0] s00_axi_awuser;
    wire                    s00_axi_awvalid;
    wire                    s00_axi_awready;
    wire [DATA_WIDTH-1:0]   s00_axi_wdata;
    wire [STRB_WIDTH-1:0]   s00_axi_wstrb;
    wire                    s00_axi_wlast;
    wire [WUSER_WIDTH-1:0]  s00_axi_wuser;
    wire                    s00_axi_wvalid;
    wire                    s00_axi_wready;
    wire [ID_WIDTH-1:0]     s00_axi_bid;
    wire [1:0]              s00_axi_bresp;
    wire [BUSER_WIDTH-1:0]  s00_axi_buser;
    wire                    s00_axi_bvalid;
    wire                    s00_axi_bready;
    wire [ID_WIDTH-1:0]     s00_axi_arid;
    wire [ADDR_WIDTH-1:0]   s00_axi_araddr;
    wire [7:0]              s00_axi_arlen;
    wire [2:0]              s00_axi_arsize;
    wire [1:0]              s00_axi_arburst;
    wire                    s00_axi_arlock;
    wire [3:0]              s00_axi_arcache;
    wire [2:0]              s00_axi_arprot;
    wire [3:0]              s00_axi_arqos;
    wire [3:0]              s00_axi_arregion;
    wire [ARUSER_WIDTH-1:0] s00_axi_aruser;
    wire                    s00_axi_arvalid;
    wire                    s00_axi_arready;
    wire [ID_WIDTH-1:0]     s00_axi_rid;
    wire [DATA_WIDTH-1:0]   s00_axi_rdata;
    wire [1:0]              s00_axi_rresp;
    wire                    s00_axi_rlast;
    wire [RUSER_WIDTH-1:0]  s00_axi_ruser;
    wire                    s00_axi_rvalid;
    wire                    s00_axi_rready;

    wire [ID_WIDTH-1:0]     lsu_adapter_s_bid;
    wire [ID_WIDTH-1:0]     lsu_adapter_s_rid;
    assign lsu_axi_bid    = lsu_adapter_s_bid[pt.LSU_BUS_TAG-1:0];
    assign lsu_axi_rid    = lsu_adapter_s_rid[pt.LSU_BUS_TAG-1:0];

    axi_adapter_64_to_32 #(
        .ADDR_WIDTH         (ADDR_WIDTH),
        .ID_WIDTH           (ID_WIDTH)
    ) u_lsu_adapter (
        .clk                (clk),
        .rst                (rst),
        // 64-bit Slave Interface (from LSU)
        .s_axi_awid         ({{ID_WIDTH-pt.LSU_BUS_TAG{1'b0}}, lsu_axi_awid}),
        .s_axi_awaddr       (lsu_axi_awaddr),
        .s_axi_awlen        (lsu_axi_awlen),
        .s_axi_awsize       (lsu_axi_awsize),
        .s_axi_awburst      (lsu_axi_awburst),
        .s_axi_awlock       (lsu_axi_awlock),
        .s_axi_awcache      (lsu_axi_awcache),
        .s_axi_awprot       (lsu_axi_awprot),
        .s_axi_awqos        (lsu_axi_awqos),
        .s_axi_awregion     (lsu_axi_awregion),
        .s_axi_awuser       ('0),
        .s_axi_awvalid      (lsu_axi_awvalid),
        .s_axi_awready      (lsu_axi_awready),
        .s_axi_wdata        (lsu_axi_wdata),
        .s_axi_wstrb        (lsu_axi_wstrb),
        .s_axi_wlast        (lsu_axi_wlast),
        .s_axi_wuser        ('0),
        .s_axi_wvalid       (lsu_axi_wvalid),
        .s_axi_wready       (lsu_axi_wready),
        .s_axi_bid          (lsu_adapter_s_bid),
        .s_axi_bresp        (lsu_axi_bresp),
        .s_axi_buser        (),
        .s_axi_bvalid       (lsu_axi_bvalid),
        .s_axi_bready       (lsu_axi_bready),
        .s_axi_arid         ({{ID_WIDTH-pt.LSU_BUS_TAG{1'b0}}, lsu_axi_arid}),
        .s_axi_araddr       (lsu_axi_araddr),
        .s_axi_arlen        (lsu_axi_arlen),
        .s_axi_arsize       (lsu_axi_arsize),
        .s_axi_arburst      (lsu_axi_arburst),
        .s_axi_arlock       (lsu_axi_arlock),
        .s_axi_arcache      (lsu_axi_arcache),
        .s_axi_arprot       (lsu_axi_arprot),
        .s_axi_arqos        (lsu_axi_arqos),
        .s_axi_arregion     (lsu_axi_arregion),
        .s_axi_aruser       ('0),
        .s_axi_arvalid      (lsu_axi_arvalid),
        .s_axi_arready      (lsu_axi_arready),
        .s_axi_rid          (lsu_adapter_s_rid),
        .s_axi_rdata        (lsu_axi_rdata),
        .s_axi_rresp        (lsu_axi_rresp),
        .s_axi_rlast        (lsu_axi_rlast),
        .s_axi_ruser        (),
        .s_axi_rvalid       (lsu_axi_rvalid),
        .s_axi_rready       (lsu_axi_rready),
        // 32-bit Master Interface (to s00 of interconnect)
        .m_axi_awid         (s00_axi_awid),
        .m_axi_awaddr       (s00_axi_awaddr),
        .m_axi_awlen        (s00_axi_awlen),
        .m_axi_awsize       (s00_axi_awsize),
        .m_axi_awburst      (s00_axi_awburst),
        .m_axi_awlock       (s00_axi_awlock),
        .m_axi_awcache      (s00_axi_awcache),
        .m_axi_awprot       (s00_axi_awprot),
        .m_axi_awqos        (s00_axi_awqos),
        .m_axi_awregion     (s00_axi_awregion),
        .m_axi_awuser       (s00_axi_awuser),
        .m_axi_awvalid      (s00_axi_awvalid),
        .m_axi_awready      (s00_axi_awready),
        .m_axi_wdata        (s00_axi_wdata),
        .m_axi_wstrb        (s00_axi_wstrb),
        .m_axi_wlast        (s00_axi_wlast),
        .m_axi_wuser        (s00_axi_wuser),
        .m_axi_wvalid       (s00_axi_wvalid),
        .m_axi_wready       (s00_axi_wready),
        .m_axi_bid          (s00_axi_bid),
        .m_axi_bresp        (s00_axi_bresp),
        .m_axi_buser        (s00_axi_buser),
        .m_axi_bvalid       (s00_axi_bvalid),
        .m_axi_bready       (s00_axi_bready),
        .m_axi_arid         (s00_axi_arid),
        .m_axi_araddr       (s00_axi_araddr),
        .m_axi_arlen        (s00_axi_arlen),
        .m_axi_arsize       (s00_axi_arsize),
        .m_axi_arburst      (s00_axi_arburst),
        .m_axi_arlock       (s00_axi_arlock),
        .m_axi_arcache      (s00_axi_arcache),
        .m_axi_arprot       (s00_axi_arprot),
        .m_axi_arqos        (s00_axi_arqos),
        .m_axi_arregion     (s00_axi_arregion),
        .m_axi_aruser       (s00_axi_aruser),
        .m_axi_arvalid      (s00_axi_arvalid),
        .m_axi_arready      (s00_axi_arready),
        .m_axi_rid          (s00_axi_rid),
        .m_axi_rdata        (s00_axi_rdata),
        .m_axi_rresp        (s00_axi_rresp),
        .m_axi_rlast        (s00_axi_rlast),
        .m_axi_ruser        (s00_axi_ruser),
        .m_axi_rvalid       (s00_axi_rvalid),
        .m_axi_rready       (s00_axi_rready)
    );

    // Slave 01: IFU (Instruction Fetch Unit)
    wire [ID_WIDTH-1:0]     s01_axi_awid;
    wire [ADDR_WIDTH-1:0]   s01_axi_awaddr;
    wire [7:0]              s01_axi_awlen;
    wire [2:0]              s01_axi_awsize;
    wire [1:0]              s01_axi_awburst;
    wire                    s01_axi_awlock;
    wire [3:0]              s01_axi_awcache;
    wire [2:0]              s01_axi_awprot;
    wire [3:0]              s01_axi_awqos;
    wire [3:0]              s01_axi_awregion;
    wire [AWUSER_WIDTH-1:0] s01_axi_awuser;
    wire                    s01_axi_awvalid;
    wire                    s01_axi_awready;
    wire [DATA_WIDTH-1:0]   s01_axi_wdata;
    wire [STRB_WIDTH-1:0]   s01_axi_wstrb;
    wire                    s01_axi_wlast;
    wire [WUSER_WIDTH-1:0]  s01_axi_wuser;
    wire                    s01_axi_wvalid;
    wire                    s01_axi_wready;
    wire [ID_WIDTH-1:0]     s01_axi_bid;
    wire [1:0]              s01_axi_bresp;
    wire [BUSER_WIDTH-1:0]  s01_axi_buser;
    wire                    s01_axi_bvalid;
    wire                    s01_axi_bready;
    wire [ID_WIDTH-1:0]     s01_axi_arid;
    wire [ADDR_WIDTH-1:0]   s01_axi_araddr;
    wire [7:0]              s01_axi_arlen;
    wire [2:0]              s01_axi_arsize;
    wire [1:0]              s01_axi_arburst;
    wire                    s01_axi_arlock;
    wire [3:0]              s01_axi_arcache;
    wire [2:0]              s01_axi_arprot;
    wire [3:0]              s01_axi_arqos;
    wire [3:0]              s01_axi_arregion;
    wire [ARUSER_WIDTH-1:0] s01_axi_aruser;
    wire                    s01_axi_arvalid;
    wire                    s01_axi_arready;
    wire [ID_WIDTH-1:0]     s01_axi_rid;
    wire [DATA_WIDTH-1:0]   s01_axi_rdata;
    wire [1:0]              s01_axi_rresp;
    wire                    s01_axi_rlast;
    wire [RUSER_WIDTH-1:0]  s01_axi_ruser;
    wire                    s01_axi_rvalid;
    wire                    s01_axi_rready;

    wire [ID_WIDTH-1:0]     ifu_adapter_s_bid;
    wire [ID_WIDTH-1:0]     ifu_adapter_s_rid;
    assign ifu_axi_bid    = ifu_adapter_s_bid[pt.IFU_BUS_TAG-1:0];
    assign ifu_axi_rid    = ifu_adapter_s_rid[pt.IFU_BUS_TAG-1:0];

    axi_adapter_64_to_32 #(
        .ADDR_WIDTH         (ADDR_WIDTH),
        .ID_WIDTH           (ID_WIDTH)
    ) u_ifu_adapter (
        .clk                (clk),
        .rst                (rst),
        // 64-bit Slave Interface (from IFU)
        .s_axi_awid         ({{ID_WIDTH-pt.IFU_BUS_TAG{1'b0}}, ifu_axi_awid}),
        .s_axi_awaddr       (ifu_axi_awaddr),
        .s_axi_awlen        (ifu_axi_awlen),
        .s_axi_awsize       (ifu_axi_awsize),
        .s_axi_awburst      (ifu_axi_awburst),
        .s_axi_awlock       (ifu_axi_awlock),
        .s_axi_awcache      (ifu_axi_awcache),
        .s_axi_awprot       (ifu_axi_awprot),
        .s_axi_awqos        (ifu_axi_awqos),
        .s_axi_awregion     (ifu_axi_awregion),
        .s_axi_awuser       ('0),
        .s_axi_awvalid      (ifu_axi_awvalid),
        .s_axi_awready      (ifu_axi_awready),
        .s_axi_wdata        (ifu_axi_wdata),
        .s_axi_wstrb        (ifu_axi_wstrb),
        .s_axi_wlast        (ifu_axi_wlast),
        .s_axi_wuser        ('0),
        .s_axi_wvalid       (ifu_axi_wvalid),
        .s_axi_wready       (ifu_axi_wready),
        .s_axi_bid          (ifu_adapter_s_bid),
        .s_axi_bresp        (ifu_axi_bresp),
        .s_axi_buser        (),
        .s_axi_bvalid       (ifu_axi_bvalid),
        .s_axi_bready       (ifu_axi_bready),
        .s_axi_arid         ({{ID_WIDTH-pt.IFU_BUS_TAG{1'b0}}, ifu_axi_arid}),
        .s_axi_araddr       (ifu_axi_araddr),
        .s_axi_arlen        (ifu_axi_arlen),
        .s_axi_arsize       (ifu_axi_arsize),
        .s_axi_arburst      (ifu_axi_arburst),
        .s_axi_arlock       (ifu_axi_arlock),
        .s_axi_arcache      (ifu_axi_arcache),
        .s_axi_arprot       (ifu_axi_arprot),
        .s_axi_arqos        (ifu_axi_arqos),
        .s_axi_arregion     (ifu_axi_arregion),
        .s_axi_aruser       ('0),
        .s_axi_arvalid      (ifu_axi_arvalid),
        .s_axi_arready      (ifu_axi_arready),
        .s_axi_rid          (ifu_adapter_s_rid),
        .s_axi_rdata        (ifu_axi_rdata),
        .s_axi_rresp        (ifu_axi_rresp),
        .s_axi_rlast        (ifu_axi_rlast),
        .s_axi_ruser        (),
        .s_axi_rvalid       (ifu_axi_rvalid),
        .s_axi_rready       (ifu_axi_rready),
        // 32-bit Master Interface (to s01 of interconnect)
        .m_axi_awid         (s01_axi_awid),
        .m_axi_awaddr       (s01_axi_awaddr),
        .m_axi_awlen        (s01_axi_awlen),
        .m_axi_awsize       (s01_axi_awsize),
        .m_axi_awburst      (s01_axi_awburst),
        .m_axi_awlock       (s01_axi_awlock),
        .m_axi_awcache      (s01_axi_awcache),
        .m_axi_awprot       (s01_axi_awprot),
        .m_axi_awqos        (s01_axi_awqos),
        .m_axi_awregion     (s01_axi_awregion),
        .m_axi_awuser       (s01_axi_awuser),
        .m_axi_awvalid      (s01_axi_awvalid),
        .m_axi_awready      (s01_axi_awready),
        .m_axi_wdata        (s01_axi_wdata),
        .m_axi_wstrb        (s01_axi_wstrb),
        .m_axi_wlast        (s01_axi_wlast),
        .m_axi_wuser        (s01_axi_wuser),
        .m_axi_wvalid       (s01_axi_wvalid),
        .m_axi_wready       (s01_axi_wready),
        .m_axi_bid          (s01_axi_bid),
        .m_axi_bresp        (s01_axi_bresp),
        .m_axi_buser        (s01_axi_buser),
        .m_axi_bvalid       (s01_axi_bvalid),
        .m_axi_bready       (s01_axi_bready),
        .m_axi_arid         (s01_axi_arid),
        .m_axi_araddr       (s01_axi_araddr),
        .m_axi_arlen        (s01_axi_arlen),
        .m_axi_arsize       (s01_axi_arsize),
        .m_axi_arburst      (s01_axi_arburst),
        .m_axi_arlock       (s01_axi_arlock),
        .m_axi_arcache      (s01_axi_arcache),
        .m_axi_arprot       (s01_axi_arprot),
        .m_axi_arqos        (s01_axi_arqos),
        .m_axi_arregion     (s01_axi_arregion),
        .m_axi_aruser       (s01_axi_aruser),
        .m_axi_arvalid      (s01_axi_arvalid),
        .m_axi_arready      (s01_axi_arready),
        .m_axi_rid          (s01_axi_rid),
        .m_axi_rdata        (s01_axi_rdata),
        .m_axi_rresp        (s01_axi_rresp),
        .m_axi_rlast        (s01_axi_rlast),
        .m_axi_ruser        (s01_axi_ruser),
        .m_axi_rvalid       (s01_axi_rvalid),
        .m_axi_rready       (s01_axi_rready)
    );

    // Slave 02: SB (System Bus / Debug Unit)
    wire [ID_WIDTH-1:0]     s02_axi_awid;
    wire [ADDR_WIDTH-1:0]   s02_axi_awaddr;
    wire [7:0]              s02_axi_awlen;
    wire [2:0]              s02_axi_awsize;
    wire [1:0]              s02_axi_awburst;
    wire                    s02_axi_awlock;
    wire [3:0]              s02_axi_awcache;
    wire [2:0]              s02_axi_awprot;
    wire [3:0]              s02_axi_awqos;
    wire [3:0]              s02_axi_awregion;
    wire [AWUSER_WIDTH-1:0] s02_axi_awuser;
    wire                    s02_axi_awvalid;
    wire                    s02_axi_awready;
    wire [DATA_WIDTH-1:0]   s02_axi_wdata;
    wire [STRB_WIDTH-1:0]   s02_axi_wstrb;
    wire                    s02_axi_wlast;
    wire [WUSER_WIDTH-1:0]  s02_axi_wuser;
    wire                    s02_axi_wvalid;
    wire                    s02_axi_wready;
    wire [ID_WIDTH-1:0]     s02_axi_bid;
    wire [1:0]              s02_axi_bresp;
    wire [BUSER_WIDTH-1:0]  s02_axi_buser;
    wire                    s02_axi_bvalid;
    wire                    s02_axi_bready;
    wire [ID_WIDTH-1:0]     s02_axi_arid;
    wire [ADDR_WIDTH-1:0]   s02_axi_araddr;
    wire [7:0]              s02_axi_arlen;
    wire [2:0]              s02_axi_arsize;
    wire [1:0]              s02_axi_arburst;
    wire                    s02_axi_arlock;
    wire [3:0]              s02_axi_arcache;
    wire [2:0]              s02_axi_arprot;
    wire [3:0]              s02_axi_arqos;
    wire [3:0]              s02_axi_arregion;
    wire [ARUSER_WIDTH-1:0] s02_axi_aruser;
    wire                    s02_axi_arvalid;
    wire                    s02_axi_arready;
    wire [ID_WIDTH-1:0]     s02_axi_rid;
    wire [DATA_WIDTH-1:0]   s02_axi_rdata;
    wire [1:0]              s02_axi_rresp;
    wire                    s02_axi_rlast;
    wire [RUSER_WIDTH-1:0]  s02_axi_ruser;
    wire                    s02_axi_rvalid;
    wire                    s02_axi_rready;

    wire [ID_WIDTH-1:0]     sb_adapter_s_bid;
    wire [ID_WIDTH-1:0]     sb_adapter_s_rid;
    assign sb_axi_bid     = sb_adapter_s_bid[pt.SB_BUS_TAG-1:0];
    assign sb_axi_rid     = sb_adapter_s_rid[pt.SB_BUS_TAG-1:0];

    axi_adapter_64_to_32 #(
        .ADDR_WIDTH         (ADDR_WIDTH),
        .ID_WIDTH           (ID_WIDTH)
    ) u_sb_adapter (
        .clk                (clk),
        .rst                (rst),
        // 64-bit Slave Interface (from SB)
        .s_axi_awid         ({{ID_WIDTH-pt.SB_BUS_TAG{1'b0}}, sb_axi_awid}),
        .s_axi_awaddr       (sb_axi_awaddr),
        .s_axi_awlen        (sb_axi_awlen),
        .s_axi_awsize       (sb_axi_awsize),
        .s_axi_awburst      (sb_axi_awburst),
        .s_axi_awlock       (sb_axi_awlock),
        .s_axi_awcache      (sb_axi_awcache),
        .s_axi_awprot       (sb_axi_awprot),
        .s_axi_awqos        (sb_axi_awqos),
        .s_axi_awregion     (sb_axi_awregion),
        .s_axi_awuser       ('0),
        .s_axi_awvalid      (sb_axi_awvalid),
        .s_axi_awready      (sb_axi_awready),
        .s_axi_wdata        (sb_axi_wdata),
        .s_axi_wstrb        (sb_axi_wstrb),
        .s_axi_wlast        (sb_axi_wlast),
        .s_axi_wuser        ('0),
        .s_axi_wvalid       (sb_axi_wvalid),
        .s_axi_wready       (sb_axi_wready),
        .s_axi_bid          (sb_adapter_s_bid),
        .s_axi_bresp        (sb_axi_bresp),
        .s_axi_buser        (),
        .s_axi_bvalid       (sb_axi_bvalid),
        .s_axi_bready       (sb_axi_bready),
        .s_axi_arid         ({{ID_WIDTH-pt.SB_BUS_TAG{1'b0}}, sb_axi_arid}),
        .s_axi_araddr       (sb_axi_araddr),
        .s_axi_arlen        (sb_axi_arlen),
        .s_axi_arsize       (sb_axi_arsize),
        .s_axi_arburst      (sb_axi_arburst),
        .s_axi_arlock       (sb_axi_arlock),
        .s_axi_arcache      (sb_axi_arcache),
        .s_axi_arprot       (sb_axi_arprot),
        .s_axi_arqos        (sb_axi_arqos),
        .s_axi_arregion     (sb_axi_arregion),
        .s_axi_aruser       ('0),
        .s_axi_arvalid      (sb_axi_arvalid),
        .s_axi_arready      (sb_axi_arready),
        .s_axi_rid          (sb_adapter_s_rid),
        .s_axi_rdata        (sb_axi_rdata),
        .s_axi_rresp        (sb_axi_rresp),
        .s_axi_rlast        (sb_axi_rlast),
        .s_axi_ruser        (),
        .s_axi_rvalid       (sb_axi_rvalid),
        .s_axi_rready       (sb_axi_rready),
        // 32-bit Master Interface (to s02 of interconnect)
        .m_axi_awid         (s02_axi_awid),
        .m_axi_awaddr       (s02_axi_awaddr),
        .m_axi_awlen        (s02_axi_awlen),
        .m_axi_awsize       (s02_axi_awsize),
        .m_axi_awburst      (s02_axi_awburst),
        .m_axi_awlock       (s02_axi_awlock),
        .m_axi_awcache      (s02_axi_awcache),
        .m_axi_awprot       (s02_axi_awprot),
        .m_axi_awqos        (s02_axi_awqos),
        .m_axi_awregion     (s02_axi_awregion),
        .m_axi_awuser       (s02_axi_awuser),
        .m_axi_awvalid      (s02_axi_awvalid),
        .m_axi_awready      (s02_axi_awready),
        .m_axi_wdata        (s02_axi_wdata),
        .m_axi_wstrb        (s02_axi_wstrb),
        .m_axi_wlast        (s02_axi_wlast),
        .m_axi_wuser        (s02_axi_wuser),
        .m_axi_wvalid       (s02_axi_wvalid),
        .m_axi_wready       (s02_axi_wready),
        .m_axi_bid          (s02_axi_bid),
        .m_axi_bresp        (s02_axi_bresp),
        .m_axi_buser        (s02_axi_buser),
        .m_axi_bvalid       (s02_axi_bvalid),
        .m_axi_bready       (s02_axi_bready),
        .m_axi_arid         (s02_axi_arid),
        .m_axi_araddr       (s02_axi_araddr),
        .m_axi_arlen        (s02_axi_arlen),
        .m_axi_arsize       (s02_axi_arsize),
        .m_axi_arburst      (s02_axi_arburst),
        .m_axi_arlock       (s02_axi_arlock),
        .m_axi_arcache      (s02_axi_arcache),
        .m_axi_arprot       (s02_axi_arprot),
        .m_axi_arqos        (s02_axi_arqos),
        .m_axi_arregion     (s02_axi_arregion),
        .m_axi_aruser       (s02_axi_aruser),
        .m_axi_arvalid      (s02_axi_arvalid),
        .m_axi_arready      (s02_axi_arready),
        .m_axi_rid          (s02_axi_rid),
        .m_axi_rdata        (s02_axi_rdata),
        .m_axi_rresp        (s02_axi_rresp),
        .m_axi_rlast        (s02_axi_rlast),
        .m_axi_ruser        (s02_axi_ruser),
        .m_axi_rvalid       (s02_axi_rvalid),
        .m_axi_rready       (s02_axi_rready)
    );

    // =========================================================================
    // 3. AXI Interconnect + AXI UART Integration Core
    // =========================================================================
    axi_interconnect_uart_top #(
        .DATA_WIDTH         (DATA_WIDTH),
        .ADDR_WIDTH         (ADDR_WIDTH),
        .STRB_WIDTH         (STRB_WIDTH),
        .ID_WIDTH           (ID_WIDTH),
        .AWUSER_ENABLE      (AWUSER_ENABLE),
        .AWUSER_WIDTH       (AWUSER_WIDTH),
        .WUSER_ENABLE       (WUSER_ENABLE),
        .WUSER_WIDTH        (WUSER_WIDTH),
        .BUSER_ENABLE       (BUSER_ENABLE),
        .BUSER_WIDTH        (BUSER_WIDTH),
        .ARUSER_ENABLE      (ARUSER_ENABLE),
        .ARUSER_WIDTH       (ARUSER_WIDTH),
        .RUSER_ENABLE       (RUSER_ENABLE),
        .RUSER_WIDTH        (RUSER_WIDTH),
        .FORWARD_ID         (FORWARD_ID),
        .M_REGIONS          (M_REGIONS),

        .UART_BASE_ADDR     (UART_BASE_ADDR),
        .UART_ADDR_WIDTH    (UART_ADDR_WIDTH),

        .M01_BASE_ADDR      (M01_BASE_ADDR),
        .M01_ADDR_WIDTH     (M01_ADDR_WIDTH),

        .M02_BASE_ADDR      (M02_BASE_ADDR),
        .M02_ADDR_WIDTH     (M02_ADDR_WIDTH),

        .M03_BASE_ADDR      (M03_BASE_ADDR),
        .M03_ADDR_WIDTH     (M03_ADDR_WIDTH),

        .M04_BASE_ADDR      (M04_BASE_ADDR),
        .M04_ADDR_WIDTH     (M04_ADDR_WIDTH),

        .M05_BASE_ADDR      (M05_BASE_ADDR),
        .M05_ADDR_WIDTH     (M05_ADDR_WIDTH),

        .M06_BASE_ADDR      (M06_BASE_ADDR),
        .M06_ADDR_WIDTH     (M06_ADDR_WIDTH),

        .M07_BASE_ADDR      (M07_BASE_ADDR),
        .M07_ADDR_WIDTH     (M07_ADDR_WIDTH),

        .M08_BASE_ADDR      (M08_BASE_ADDR),
        .M08_ADDR_WIDTH     (M08_ADDR_WIDTH),

        .M09_BASE_ADDR      (M09_BASE_ADDR),
        .M09_ADDR_WIDTH     (M09_ADDR_WIDTH)
    )
    u_interconnect_uart (
        .clk                (clk),
        .uart_clk           (clk),
        .rst                (rst),

        // UART physical lines & interrupt
        .uart_rx            (uart_rx),
        .uart_tx            (uart_tx),
        .uart_irq           (uart_irq),

        // Slave 00: Connected to LSU Adapter (CPU Data)
        .s00_axi_awid       (s00_axi_awid),
        .s00_axi_awaddr     (s00_axi_awaddr),
        .s00_axi_awlen      (s00_axi_awlen),
        .s00_axi_awsize     (s00_axi_awsize),
        .s00_axi_awburst    (s00_axi_awburst),
        .s00_axi_awlock     (s00_axi_awlock),
        .s00_axi_awcache    (s00_axi_awcache),
        .s00_axi_awprot     (s00_axi_awprot),
        .s00_axi_awqos      (s00_axi_awqos),
        .s00_axi_awuser     (s00_axi_awuser),
        .s00_axi_awvalid    (s00_axi_awvalid),
        .s00_axi_awready    (s00_axi_awready),
        .s00_axi_wdata      (s00_axi_wdata),
        .s00_axi_wstrb      (s00_axi_wstrb),
        .s00_axi_wlast      (s00_axi_wlast),
        .s00_axi_wuser      (s00_axi_wuser),
        .s00_axi_wvalid     (s00_axi_wvalid),
        .s00_axi_wready     (s00_axi_wready),
        .s00_axi_bid        (s00_axi_bid),
        .s00_axi_bresp      (s00_axi_bresp),
        .s00_axi_buser      (s00_axi_buser),
        .s00_axi_bvalid     (s00_axi_bvalid),
        .s00_axi_bready     (s00_axi_bready),
        .s00_axi_arid       (s00_axi_arid),
        .s00_axi_araddr     (s00_axi_araddr),
        .s00_axi_arlen      (s00_axi_arlen),
        .s00_axi_arsize     (s00_axi_arsize),
        .s00_axi_arburst    (s00_axi_arburst),
        .s00_axi_arlock     (s00_axi_arlock),
        .s00_axi_arcache    (s00_axi_arcache),
        .s00_axi_arprot     (s00_axi_arprot),
        .s00_axi_arqos      (s00_axi_arqos),
        .s00_axi_aruser     (s00_axi_aruser),
        .s00_axi_arvalid    (s00_axi_arvalid),
        .s00_axi_arready    (s00_axi_arready),
        .s00_axi_rid        (s00_axi_rid),
        .s00_axi_rdata      (s00_axi_rdata),
        .s00_axi_rresp      (s00_axi_rresp),
        .s00_axi_rlast      (s00_axi_rlast),
        .s00_axi_ruser      (s00_axi_ruser),
        .s00_axi_rvalid     (s00_axi_rvalid),
        .s00_axi_rready     (s00_axi_rready),

        // Slave 01: Connected to IFU Adapter (CPU Instruction Fetch)
        .s01_axi_awid       (s01_axi_awid),
        .s01_axi_awaddr     (s01_axi_awaddr),
        .s01_axi_awlen      (s01_axi_awlen),
        .s01_axi_awsize     (s01_axi_awsize),
        .s01_axi_awburst    (s01_axi_awburst),
        .s01_axi_awlock     (s01_axi_awlock),
        .s01_axi_awcache    (s01_axi_awcache),
        .s01_axi_awprot     (s01_axi_awprot),
        .s01_axi_awqos      (s01_axi_awqos),
        .s01_axi_awuser     (s01_axi_awuser),
        .s01_axi_awvalid    (s01_axi_awvalid),
        .s01_axi_awready    (s01_axi_awready),
        .s01_axi_wdata      (s01_axi_wdata),
        .s01_axi_wstrb      (s01_axi_wstrb),
        .s01_axi_wlast      (s01_axi_wlast),
        .s01_axi_wuser      (s01_axi_wuser),
        .s01_axi_wvalid     (s01_axi_wvalid),
        .s01_axi_wready     (s01_axi_wready),
        .s01_axi_bid        (s01_axi_bid),
        .s01_axi_bresp      (s01_axi_bresp),
        .s01_axi_buser      (s01_axi_buser),
        .s01_axi_bvalid     (s01_axi_bvalid),
        .s01_axi_bready     (s01_axi_bready),
        .s01_axi_arid       (s01_axi_arid),
        .s01_axi_araddr     (s01_axi_araddr),
        .s01_axi_arlen      (s01_axi_arlen),
        .s01_axi_arsize     (s01_axi_arsize),
        .s01_axi_arburst    (s01_axi_arburst),
        .s01_axi_arlock     (s01_axi_arlock),
        .s01_axi_arcache    (s01_axi_arcache),
        .s01_axi_arprot     (s01_axi_arprot),
        .s01_axi_arqos      (s01_axi_arqos),
        .s01_axi_aruser     (s01_axi_aruser),
        .s01_axi_arvalid    (s01_axi_arvalid),
        .s01_axi_arready    (s01_axi_arready),
        .s01_axi_rid        (s01_axi_rid),
        .s01_axi_rdata      (s01_axi_rdata),
        .s01_axi_rresp      (s01_axi_rresp),
        .s01_axi_rlast      (s01_axi_rlast),
        .s01_axi_ruser      (s01_axi_ruser),
        .s01_axi_rvalid     (s01_axi_rvalid),
        .s01_axi_rready     (s01_axi_rready),

        // Slave 02: Connected to SB Adapter (Core Debug/System Bus)
        .s02_axi_awid       (s02_axi_awid),
        .s02_axi_awaddr     (s02_axi_awaddr),
        .s02_axi_awlen      (s02_axi_awlen),
        .s02_axi_awsize     (s02_axi_awsize),
        .s02_axi_awburst    (s02_axi_awburst),
        .s02_axi_awlock     (s02_axi_awlock),
        .s02_axi_awcache    (s02_axi_awcache),
        .s02_axi_awprot     (s02_axi_awprot),
        .s02_axi_awqos      (s02_axi_awqos),
        .s02_axi_awuser     (s02_axi_awuser),
        .s02_axi_awvalid    (s02_axi_awvalid),
        .s02_axi_awready    (s02_axi_awready),
        .s02_axi_wdata      (s02_axi_wdata),
        .s02_axi_wstrb      (s02_axi_wstrb),
        .s02_axi_wlast      (s02_axi_wlast),
        .s02_axi_wuser      (s02_axi_wuser),
        .s02_axi_wvalid     (s02_axi_wvalid),
        .s02_axi_wready     (s02_axi_wready),
        .s02_axi_bid        (s02_axi_bid),
        .s02_axi_bresp      (s02_axi_bresp),
        .s02_axi_buser      (s02_axi_buser),
        .s02_axi_bvalid     (s02_axi_bvalid),
        .s02_axi_bready     (s02_axi_bready),
        .s02_axi_arid       (s02_axi_arid),
        .s02_axi_araddr     (s02_axi_araddr),
        .s02_axi_arlen      (s02_axi_arlen),
        .s02_axi_arsize     (s02_axi_arsize),
        .s02_axi_arburst    (s02_axi_arburst),
        .s02_axi_arlock     (s02_axi_arlock),
        .s02_axi_arcache    (s02_axi_arcache),
        .s02_axi_arprot     (s02_axi_arprot),
        .s02_axi_arqos      (s02_axi_arqos),
        .s02_axi_aruser     (s02_axi_aruser),
        .s02_axi_arvalid    (s02_axi_arvalid),
        .s02_axi_arready    (s02_axi_arready),
        .s02_axi_rid        (s02_axi_rid),
        .s02_axi_rdata      (s02_axi_rdata),
        .s02_axi_rresp      (s02_axi_rresp),
        .s02_axi_rlast      (s02_axi_rlast),
        .s02_axi_ruser      (s02_axi_ruser),
        .s02_axi_rvalid     (s02_axi_rvalid),
        .s02_axi_rready     (s02_axi_rready),

        // Master 01: Exported to top-level boundary
        .m01_axi_awid       (m01_axi_awid),
        .m01_axi_awaddr     (m01_axi_awaddr),
        .m01_axi_awlen      (m01_axi_awlen),
        .m01_axi_awsize     (m01_axi_awsize),
        .m01_axi_awburst    (m01_axi_awburst),
        .m01_axi_awlock     (m01_axi_awlock),
        .m01_axi_awcache    (m01_axi_awcache),
        .m01_axi_awprot     (m01_axi_awprot),
        .m01_axi_awqos      (m01_axi_awqos),
        .m01_axi_awregion   (),
        .m01_axi_awuser     (m01_axi_awuser),
        .m01_axi_awvalid    (m01_axi_awvalid),
        .m01_axi_awready    (m01_axi_awready),
        .m01_axi_wdata      (m01_axi_wdata),
        .m01_axi_wstrb      (m01_axi_wstrb),
        .m01_axi_wlast      (m01_axi_wlast),
        .m01_axi_wuser      (m01_axi_wuser),
        .m01_axi_wvalid     (m01_axi_wvalid),
        .m01_axi_wready     (m01_axi_wready),
        .m01_axi_bid        (m01_axi_bid),
        .m01_axi_bresp      (m01_axi_bresp),
        .m01_axi_buser      (m01_axi_buser),
        .m01_axi_bvalid     (m01_axi_bvalid),
        .m01_axi_bready     (m01_axi_bready),
        .m01_axi_arid       (m01_axi_arid),
        .m01_axi_araddr     (m01_axi_araddr),
        .m01_axi_arlen      (m01_axi_arlen),
        .m01_axi_arsize     (m01_axi_arsize),
        .m01_axi_arburst    (m01_axi_arburst),
        .m01_axi_arlock     (m01_axi_arlock),
        .m01_axi_arcache    (m01_axi_arcache),
        .m01_axi_arprot     (m01_axi_arprot),
        .m01_axi_arqos      (m01_axi_arqos),
        .m01_axi_arregion   (),
        .m01_axi_aruser     (m01_axi_aruser),
        .m01_axi_arvalid    (m01_axi_arvalid),
        .m01_axi_arready    (m01_axi_arready),
        .m01_axi_rid        (m01_axi_rid),
        .m01_axi_rdata      (m01_axi_rdata),
        .m01_axi_rresp      (m01_axi_rresp),
        .m01_axi_rlast      (m01_axi_rlast),
        .m01_axi_ruser      (m01_axi_ruser),
        .m01_axi_rvalid     (m01_axi_rvalid),
        .m01_axi_rready     (m01_axi_rready),

        // Master 02: Exported to top-level boundary
        .m02_axi_awid       (m02_axi_awid),
        .m02_axi_awaddr     (m02_axi_awaddr),
        .m02_axi_awlen      (m02_axi_awlen),
        .m02_axi_awsize     (m02_axi_awsize),
        .m02_axi_awburst    (m02_axi_awburst),
        .m02_axi_awlock     (m02_axi_awlock),
        .m02_axi_awcache    (m02_axi_awcache),
        .m02_axi_awprot     (m02_axi_awprot),
        .m02_axi_awqos      (m02_axi_awqos),
        .m02_axi_awregion   (),
        .m02_axi_awuser     (m02_axi_awuser),
        .m02_axi_awvalid    (m02_axi_awvalid),
        .m02_axi_awready    (m02_axi_awready),
        .m02_axi_wdata      (m02_axi_wdata),
        .m02_axi_wstrb      (m02_axi_wstrb),
        .m02_axi_wlast      (m02_axi_wlast),
        .m02_axi_wuser      (m02_axi_wuser),
        .m02_axi_wvalid     (m02_axi_wvalid),
        .m02_axi_wready     (m02_axi_wready),
        .m02_axi_bid        (m02_axi_bid),
        .m02_axi_bresp      (m02_axi_bresp),
        .m02_axi_buser      (m02_axi_buser),
        .m02_axi_bvalid     (m02_axi_bvalid),
        .m02_axi_bready     (m02_axi_bready),
        .m02_axi_arid       (m02_axi_arid),
        .m02_axi_araddr     (m02_axi_araddr),
        .m02_axi_arlen      (m02_axi_arlen),
        .m02_axi_arsize     (m02_axi_arsize),
        .m02_axi_arburst    (m02_axi_arburst),
        .m02_axi_arlock     (m02_axi_arlock),
        .m02_axi_arcache    (m02_axi_arcache),
        .m02_axi_arprot     (m02_axi_arprot),
        .m02_axi_arqos      (m02_axi_arqos),
        .m02_axi_arregion   (),
        .m02_axi_aruser     (m02_axi_aruser),
        .m02_axi_arvalid    (m02_axi_arvalid),
        .m02_axi_arready    (m02_axi_arready),
        .m02_axi_rid        (m02_axi_rid),
        .m02_axi_rdata      (m02_axi_rdata),
        .m02_axi_rresp      (m02_axi_rresp),
        .m02_axi_rlast      (m02_axi_rlast),
        .m02_axi_ruser      (m02_axi_ruser),
        .m02_axi_rvalid     (m02_axi_rvalid),
        .m02_axi_rready     (m02_axi_rready),

        // Masters 03..09 (Tied off internally if not externally connected)
        .m03_axi_awready    (1'b0),
        .m03_axi_wready     (1'b0),
        .m03_axi_bid        ('0),
        .m03_axi_bresp      (2'b11), // DECERR
        .m03_axi_buser      ('0),
        .m03_axi_bvalid     (1'b0),
        .m03_axi_arready    (1'b0),
        .m03_axi_rid        ('0),
        .m03_axi_rdata      ('0),
        .m03_axi_rresp      (2'b11), // DECERR
        .m03_axi_rlast      (1'b0),
        .m03_axi_ruser      ('0),
        .m03_axi_rvalid     (1'b0),

        .m04_axi_awready    (1'b0),
        .m04_axi_wready     (1'b0),
        .m04_axi_bid        ('0),
        .m04_axi_bresp      (2'b11),
        .m04_axi_buser      ('0),
        .m04_axi_bvalid     (1'b0),
        .m04_axi_arready    (1'b0),
        .m04_axi_rid        ('0),
        .m04_axi_rdata      ('0),
        .m04_axi_rresp      (2'b11),
        .m04_axi_rlast      (1'b0),
        .m04_axi_ruser      ('0),
        .m04_axi_rvalid     (1'b0),

        .m05_axi_awready    (1'b0),
        .m05_axi_wready     (1'b0),
        .m05_axi_bid        ('0),
        .m05_axi_bresp      (2'b11),
        .m05_axi_buser      ('0),
        .m05_axi_bvalid     (1'b0),
        .m05_axi_arready    (1'b0),
        .m05_axi_rid        ('0),
        .m05_axi_rdata      ('0),
        .m05_axi_rresp      (2'b11),
        .m05_axi_rlast      (1'b0),
        .m05_axi_ruser      ('0),
        .m05_axi_rvalid     (1'b0),

        .m06_axi_awready    (1'b0),
        .m06_axi_wready     (1'b0),
        .m06_axi_bid        ('0),
        .m06_axi_bresp      (2'b11),
        .m06_axi_buser      ('0),
        .m06_axi_bvalid     (1'b0),
        .m06_axi_arready    (1'b0),
        .m06_axi_rid        ('0),
        .m06_axi_rdata      ('0),
        .m06_axi_rresp      (2'b11),
        .m06_axi_rlast      (1'b0),
        .m06_axi_ruser      ('0),
        .m06_axi_rvalid     (1'b0),

        .m07_axi_awready    (1'b0),
        .m07_axi_wready     (1'b0),
        .m07_axi_bid        ('0),
        .m07_axi_bresp      (2'b11),
        .m07_axi_buser      ('0),
        .m07_axi_bvalid     (1'b0),
        .m07_axi_arready    (1'b0),
        .m07_axi_rid        ('0),
        .m07_axi_rdata      ('0),
        .m07_axi_rresp      (2'b11),
        .m07_axi_rlast      (1'b0),
        .m07_axi_ruser      ('0),
        .m07_axi_rvalid     (1'b0),

        .m08_axi_awready    (1'b0),
        .m08_axi_wready     (1'b0),
        .m08_axi_bid        ('0),
        .m08_axi_bresp      (2'b11),
        .m08_axi_buser      ('0),
        .m08_axi_bvalid     (1'b0),
        .m08_axi_arready    (1'b0),
        .m08_axi_rid        ('0),
        .m08_axi_rdata      ('0),
        .m08_axi_rresp      (2'b11),
        .m08_axi_rlast      (1'b0),
        .m08_axi_ruser      ('0),
        .m08_axi_rvalid     (1'b0),

        .m09_axi_awready    (1'b0),
        .m09_axi_wready     (1'b0),
        .m09_axi_bid        ('0),
        .m09_axi_bresp      (2'b11),
        .m09_axi_buser      ('0),
        .m09_axi_bvalid     (1'b0),
        .m09_axi_arready    (1'b0),
        .m09_axi_rid        ('0),
        .m09_axi_rdata      ('0),
        .m09_axi_rresp      (2'b11),
        .m09_axi_rlast      (1'b0),
        .m09_axi_ruser      ('0),
        .m09_axi_rvalid     (1'b0)
    );

endmodule

`resetall
