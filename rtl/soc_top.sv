/*
 * RISC-V SoC Top-Level Integration Module (soc_top)
 *
 * Fully Integrates:
 * 1. Western Digital / CHIPS Alliance VeeR EL2 RISC-V Core (veer_wrapper)
 *    - RV32IMC 32-bit RISC-V processor core
 *    - 64-bit AXI4 Master interfaces (LSU, IFU, SB)
 * 2. AXI4 64-to-32 Width Adapters (LSU, IFU, SB)
 * 3. 5-Master x 20-Slave AXI4 Crossbar Interconnect (axi_interconnect_uart_top)
 * 4. Memory Subsystem:
 *    - On-Chip AXI4 Instruction Memory (IMEM, 64 KB at 0x1000_0000)
 *    - On-Chip AXI4 Data Memory (DMEM, 64 KB at 0x1002_0000)
 * 5. Integrated Hardware Peripherals:
 *    - AXI UART (0x4000_6000)
 *    - Acquisition Timer (0x4000_8000)
 *    - GPIO Controller with LED/button sync (0x4000_A000)
 *    - SPI Master Controller for ADC acquisition (0x4000_C000)
 *    - Watchdog Safety Monitor with NMI & reset trip (0x4000_E000)
 * 6. DSP & Visualization Hardware Streaming Pipeline:
 *    - Autonomous Streaming DMA Controller (0x4001_0000)
 *    - 16-Tap Q1.15 Fixed-Point FIR Filter Engine (0x4001_2000)
 *    - Real-Time 640x480 Oscilloscope VGA Controller with custom UI (0x4001_4000)
 *    - 4096-entry Ping-Pong Double Sample Buffer RAM (0x4001_6000)
 * 7. Hardware Datapath Wiring:
 *    - Timer sample_tick -> SPI & DMA acquisition trigger
 *    - SPI Master physical interface to external ADC pins
 *    - DMA autonomous reading of SPI sample words
 *    - DMA -> FIR Filter streaming pipeline
 *    - FIR Filter -> Dual-Port Ping-Pong Buffer tear-free write
 *    - Ping-Pong Buffer -> VGA Controller pixel rendering
 *    - PIC interrupt vector wiring (Timer, DMA, UART, GPIO, FIR, VGA, SPI)
 *    - Watchdog NMI prewarn -> Core NMI interrupt
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

    // Base Addresses for SoC Memory Map
    parameter UART_BASE_ADDR   = 32'h4000_6000,
    parameter UART_ADDR_WIDTH  = {M_REGIONS{32'd12}},

    parameter IMEM_BASE_ADDR   = 32'h1000_0000, // M01: IMEM (64 KB)
    parameter IMEM_ADDR_WIDTH  = {M_REGIONS{32'd16}},

    parameter DMEM_BASE_ADDR   = 32'h1002_0000, // M02: DMEM (64 KB)
    parameter DMEM_ADDR_WIDTH  = {M_REGIONS{32'd16}},

    parameter I2C_BASE_ADDR    = 32'h4000_0000, // M03: I2C (4 KB)
    parameter I2C_ADDR_WIDTH   = {M_REGIONS{32'd12}},

    parameter PWM_BASE_ADDR    = 32'h4000_2000, // M04: PWM (4 KB)
    parameter PWM_ADDR_WIDTH   = {M_REGIONS{32'd12}},

    parameter SSD_BASE_ADDR    = 32'h4000_4000, // M05: SSD (4 KB)
    parameter SSD_ADDR_WIDTH   = {M_REGIONS{32'd12}},

    parameter TIMER_BASE_ADDR  = 32'h4000_8000, // M06: TIMER (4 KB)
    parameter TIMER_ADDR_WIDTH = {M_REGIONS{32'd12}},

    parameter GPIO_BASE_ADDR   = 32'h4000_A000, // M07: GPIO (4 KB)
    parameter GPIO_ADDR_WIDTH  = {M_REGIONS{32'd12}},

    parameter SPI_BASE_ADDR    = 32'h4000_C000, // M08: SPI (4 KB)
    parameter SPI_ADDR_WIDTH   = {M_REGIONS{32'd12}},

    parameter WDT_BASE_ADDR    = 32'h4000_E000, // M09: WATCHDOG (4 KB)
    parameter WDT_ADDR_WIDTH   = {M_REGIONS{32'd12}},

    parameter DMA_BASE_ADDR    = 32'h4001_0000, // M10: DMA (4 KB)
    parameter DMA_ADDR_WIDTH   = {M_REGIONS{32'd12}},

    parameter FIR_BASE_ADDR    = 32'h4001_2000, // M11: FIR (4 KB)
    parameter FIR_ADDR_WIDTH   = {M_REGIONS{32'd12}},

    parameter VGA_BASE_ADDR    = 32'h4001_4000, // M12: VGA (4 KB)
    parameter VGA_ADDR_WIDTH   = {M_REGIONS{32'd12}},

    parameter SBUF_BASE_ADDR   = 32'h4001_6000, // M13: BUFFER (8 KB)
    parameter SBUF_ADDR_WIDTH  = {M_REGIONS{32'd13}},

    // Optional on-chip memory preload file
    parameter IMEM_INIT_FILE   = ""
)
(
    // System Clock (100 MHz) and Active-Low Reset
    input  wire                              clk,
    input  wire                              rst_n,

    // Pixel Clock (25.175 MHz for 640x480 @ 60 Hz VGA)
    input  wire                              clk_vga,

    // Core Control & Vectors
    input  wire [31:1]                       rst_vec,
    input  wire                              nmi_int,
    input  wire [31:1]                       nmi_vec,
    input  wire [31:1]                       jtag_id,

    // UART Physical Interface & Interrupt
    input  wire                              uart_rx,
    output wire                              uart_tx,
    output wire                              uart_irq,

    // GPIO External Boundary Pins
    input  wire [7:0]                        gpio_in,
    output wire [7:0]                        gpio_out,

    // ADC SPI Interface (from SPI Controller)
    output wire                              adc_spi_sck,
    output wire                              adc_spi_mosi,
    input  wire                              adc_spi_miso,
    output wire                              adc_spi_cs_n,

    // VGA Oscilloscope Physical Outputs (640x480 @ 60 Hz)
    output wire                              vga_hsync,
    output wire                              vga_vsync,
    output wire [3:0]                        vga_red,
    output wire [3:0]                        vga_green,
    output wire [3:0]                        vga_blue,

    // Watchdog Reset Indicator
    output wire                              wdt_reset_out,

    // External Interrupt Inputs for Expansion
    input  wire [pt.PIC_TOTAL_INT-8:0]       ext_irq,
    input  wire                              timer_int,

    // Instruction Execution Trace Interface
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
    output wire                              o_debug_mode_status
);

    // Active-high reset for interconnect & adapters
    wire rst = ~rst_n;

    // Reset for VGA domain
    reg rst_vga_n_meta, rst_vga_n;
    always @(posedge clk_vga or negedge rst_n) begin
        if (!rst_n) begin
            rst_vga_n_meta <= 1'b0;
            rst_vga_n      <= 1'b0;
        end else begin
            rst_vga_n_meta <= 1'b1;
            rst_vga_n      <= rst_vga_n_meta;
        end
    end

    // =========================================================================
    // Internal Interrupt Lines
    // =========================================================================
    wire irq_timer;
    wire irq_gpio;
    wire irq_dma_done;
    wire irq_dma_err;
    wire irq_fir;
    wire irq_vga_frame;
    wire irq_spi;
    wire wdt_nmi_prewarn;
    wire wdt_reset;

    // Core PIC External Interrupt Vector (31 sources)
    wire [pt.PIC_TOTAL_INT-1:0] core_extintsrc_req;
    assign core_extintsrc_req[0] = uart_irq;
    assign core_extintsrc_req[1] = irq_timer;
    assign core_extintsrc_req[2] = irq_gpio;
    assign core_extintsrc_req[3] = irq_dma_done;
    assign core_extintsrc_req[4] = irq_dma_err;
    assign core_extintsrc_req[5] = irq_fir;
    assign core_extintsrc_req[6] = irq_vga_frame;
    assign core_extintsrc_req[pt.PIC_TOTAL_INT-1:7] = ext_irq;

    // Core NMI Interrupt (External NMI OR Watchdog pre-warning)
    wire core_nmi_int = nmi_int | wdt_nmi_prewarn;

    // =========================================================================
    // Core 64-bit AXI Signals
    // =========================================================================
    // LSU AXI (64-bit)
    wire                      lsu_axi_awvalid, lsu_axi_awready;
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
    wire                      lsu_axi_wvalid, lsu_axi_wready;
    wire [63:0]               lsu_axi_wdata;
    wire [7:0]                lsu_axi_wstrb;
    wire                      lsu_axi_wlast;
    wire                      lsu_axi_bvalid, lsu_axi_bready;
    wire [1:0]                lsu_axi_bresp;
    wire [pt.LSU_BUS_TAG-1:0] lsu_axi_bid;
    wire                      lsu_axi_arvalid, lsu_axi_arready;
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
    wire                      lsu_axi_rvalid, lsu_axi_rready;
    wire [pt.LSU_BUS_TAG-1:0] lsu_axi_rid;
    wire [63:0]               lsu_axi_rdata;
    wire [1:0]                lsu_axi_rresp;
    wire                      lsu_axi_rlast;

    // IFU AXI (64-bit)
    wire                      ifu_axi_awvalid, ifu_axi_awready;
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
    wire                      ifu_axi_wvalid, ifu_axi_wready;
    wire [63:0]               ifu_axi_wdata;
    wire [7:0]                ifu_axi_wstrb;
    wire                      ifu_axi_wlast;
    wire                      ifu_axi_bvalid, ifu_axi_bready;
    wire [1:0]                ifu_axi_bresp;
    wire [pt.IFU_BUS_TAG-1:0] ifu_axi_bid;
    wire                      ifu_axi_arvalid, ifu_axi_arready;
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
    wire                      ifu_axi_rvalid, ifu_axi_rready;
    wire [pt.IFU_BUS_TAG-1:0] ifu_axi_rid;
    wire [63:0]               ifu_axi_rdata;
    wire [1:0]                ifu_axi_rresp;
    wire                      ifu_axi_rlast;

    // SB System Bus (64-bit)
    wire                      sb_axi_awvalid, sb_axi_awready;
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
    wire                      sb_axi_wvalid, sb_axi_wready;
    wire [63:0]               sb_axi_wdata;
    wire [7:0]                sb_axi_wstrb;
    wire                      sb_axi_wlast;
    wire                      sb_axi_bvalid, sb_axi_bready;
    wire [1:0]                sb_axi_bresp;
    wire [pt.SB_BUS_TAG-1:0]  sb_axi_bid;
    wire                      sb_axi_arvalid, sb_axi_arready;
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
    wire                      sb_axi_rvalid, sb_axi_rready;
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
        .nmi_int                (core_nmi_int),
        .nmi_vec                (nmi_vec),
        .jtag_id                (jtag_id),

        .timer_int              (timer_int),
        .extintsrc_req          (core_extintsrc_req),

        .lsu_bus_clk_en         (1'b1),
        .ifu_bus_clk_en         (1'b1),
        .dbg_bus_clk_en         (1'b1),
        .dma_bus_clk_en         (1'b1),

        .trace_rv_i_insn_ip     (trace_rv_i_insn_ip),
        .trace_rv_i_address_ip  (trace_rv_i_address_ip),
        .trace_rv_i_valid_ip    (trace_rv_i_valid_ip),
        .trace_rv_i_exception_ip(trace_rv_i_exception_ip),
        .trace_rv_i_ecause_ip   (trace_rv_i_ecause_ip),
        .trace_rv_i_interrupt_ip(trace_rv_i_interrupt_ip),
        .trace_rv_i_tval_ip     (trace_rv_i_tval_ip),

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

        // Core DMA Slave Interface (Unused - tie off inactive)
        .dma_axi_awvalid        (1'b0),
        .dma_axi_awready        (),
        .dma_axi_awid           ('0),
        .dma_axi_awaddr         ('0),
        .dma_axi_awsize         ('0),
        .dma_axi_awprot         ('0),
        .dma_axi_awlen          ('0),
        .dma_axi_awburst        ('0),
        .dma_axi_wvalid         (1'b0),
        .dma_axi_wready         (),
        .dma_axi_wdata          ('0),
        .dma_axi_wstrb          ('0),
        .dma_axi_wlast          (1'b0),
        .dma_axi_bvalid         (),
        .dma_axi_bready         (1'b1),
        .dma_axi_bresp          (),
        .dma_axi_bid            (),
        .dma_axi_arvalid        (1'b0),
        .dma_axi_arready        (),
        .dma_axi_arid           ('0),
        .dma_axi_araddr         ('0),
        .dma_axi_arsize         ('0),
        .dma_axi_arprot         ('0),
        .dma_axi_arlen          ('0),
        .dma_axi_arburst        ('0),
        .dma_axi_rvalid         (),
        .dma_axi_rready         (1'b1),
        .dma_axi_rid            (),
        .dma_axi_rdata          (),
        .dma_axi_rresp          (),
        .dma_axi_rlast          (),

        // Additional Core inputs
        .soft_int               (1'b0),
        .core_id                ('0),
        .jtag_tck               (1'b0),
        .jtag_tms               (1'b0),
        .jtag_tdi               (1'b0),
        .jtag_trst_n            (1'b1),
        .jtag_tdo               (),
        .jtag_tdoEn             (),
        .dec_tlu_perfcnt0       (),
        .dec_tlu_perfcnt1       (),
        .dec_tlu_perfcnt2       (),
        .dec_tlu_perfcnt3       (),

        // Memory Export Interface (Tied off)
        .mem_clk                (),
        .iccm_clken             (),
        .iccm_wren_bank         (),
        .iccm_addr_bank         (),
        .iccm_bank_wr_data      (),
        .iccm_bank_wr_ecc       (),
        .iccm_bank_dout         ('0),
        .iccm_bank_ecc          ('0),
        .dccm_clken             (),
        .dccm_wren_bank         (),
        .dccm_addr_bank         (),
        .dccm_wr_data_bank      (),
        .dccm_wr_ecc_bank       (),
        .dccm_bank_dout         ('0),
        .dccm_bank_ecc          ('0),
        .ic_b_sb_wren           (),
        .ic_b_sb_bit_en_vec     (),
        .ic_sb_wr_data          (),
        .ic_rw_addr_bank_q      (),
        .ic_bank_way_clken_final(),
        .ic_bank_way_clken_final_up(),
        .wb_packeddout_pre      ('0),
        .wb_dout_pre_up         ('0),
        .ic_tag_clken_final     (),
        .ic_tag_wren_q          (),
        .ic_tag_wren_biten_vec  (),
        .ic_tag_wr_data         (),
        .ic_rw_addr_q           (),
        .ic_tag_data_raw_pre    ('0),
        .ic_tag_data_raw_packed_pre('0),
        .iccm_ecc_single_error  (),
        .iccm_ecc_double_error  (),
        .dccm_ecc_single_error  (),
        .dccm_ecc_double_error  (),
        .dccm_write_readback_error()
    );

    // =========================================================================
    // 2. AXI4 64-to-32 Width Adapters
    // =========================================================================
    // 32-bit slave port lines
    wire [ID_WIDTH-1:0]     s00_axi_awid,    s01_axi_awid,    s02_axi_awid;
    wire [ADDR_WIDTH-1:0]   s00_axi_awaddr,  s01_axi_awaddr,  s02_axi_awaddr;
    wire [7:0]              s00_axi_awlen,   s01_axi_awlen,   s02_axi_awlen;
    wire [2:0]              s00_axi_awsize,  s01_axi_awsize,  s02_axi_awsize;
    wire [1:0]              s00_axi_awburst, s01_axi_awburst, s02_axi_awburst;
    wire                    s00_axi_awlock,  s01_axi_awlock,  s02_axi_awlock;
    wire [3:0]              s00_axi_awcache, s01_axi_awcache, s02_axi_awcache;
    wire [2:0]              s00_axi_awprot,  s01_axi_awprot,  s02_axi_awprot;
    wire [3:0]              s00_axi_awqos,   s01_axi_awqos,   s02_axi_awqos;
    wire [AWUSER_WIDTH-1:0] s00_axi_awuser,  s01_axi_awuser,  s02_axi_awuser;
    wire                    s00_axi_awvalid, s01_axi_awvalid, s02_axi_awvalid;
    wire                    s00_axi_awready, s01_axi_awready, s02_axi_awready;
    wire [DATA_WIDTH-1:0]   s00_axi_wdata,   s01_axi_wdata,   s02_axi_wdata;
    wire [STRB_WIDTH-1:0]   s00_axi_wstrb,   s01_axi_wstrb,   s02_axi_wstrb;
    wire                    s00_axi_wlast,   s01_axi_wlast,   s02_axi_wlast;
    wire [WUSER_WIDTH-1:0]  s00_axi_wuser,   s01_axi_wuser,   s02_axi_wuser;
    wire                    s00_axi_wvalid,  s01_axi_wvalid,  s02_axi_wvalid;
    wire                    s00_axi_wready,  s01_axi_wready,  s02_axi_wready;
    wire [ID_WIDTH-1:0]     s00_axi_bid,     s01_axi_bid,     s02_axi_bid;
    wire [1:0]              s00_axi_bresp,   s01_axi_bresp,   s02_axi_bresp;
    wire [BUSER_WIDTH-1:0]  s00_axi_buser,   s01_axi_buser,   s02_axi_buser;
    wire                    s00_axi_bvalid,  s01_axi_bvalid,  s02_axi_bvalid;
    wire                    s00_axi_bready,  s01_axi_bready,  s02_axi_bready;
    wire [ID_WIDTH-1:0]     s00_axi_arid,    s01_axi_arid,    s02_axi_arid;
    wire [ADDR_WIDTH-1:0]   s00_axi_araddr,  s01_axi_araddr,  s02_axi_araddr;
    wire [7:0]              s00_axi_arlen,   s01_axi_arlen,   s02_axi_arlen;
    wire [2:0]              s00_axi_arsize,  s01_axi_arsize,  s02_axi_arsize;
    wire [1:0]              s00_axi_arburst, s01_axi_arburst, s02_axi_arburst;
    wire                    s00_axi_arlock,  s01_axi_arlock,  s02_axi_arlock;
    wire [3:0]              s00_axi_arcache, s01_axi_arcache, s02_axi_arcache;
    wire [2:0]              s00_axi_arprot,  s01_axi_arprot,  s02_axi_arprot;
    wire [3:0]              s00_axi_arqos,   s01_axi_arqos,   s02_axi_arqos;
    wire [ARUSER_WIDTH-1:0] s00_axi_aruser,  s01_axi_aruser,  s02_axi_aruser;
    wire                    s00_axi_arvalid, s01_axi_arvalid, s02_axi_arvalid;
    wire                    s00_axi_arready, s01_axi_arready, s02_axi_arready;
    wire [ID_WIDTH-1:0]     s00_axi_rid,     s01_axi_rid,     s02_axi_rid;
    wire [DATA_WIDTH-1:0]   s00_axi_rdata,   s01_axi_rdata,   s02_axi_rdata;
    wire [1:0]              s00_axi_rresp,   s01_axi_rresp,   s02_axi_rresp;
    wire                    s00_axi_rlast,   s01_axi_rlast,   s02_axi_rlast;
    wire [RUSER_WIDTH-1:0]  s00_axi_ruser,   s01_axi_ruser,   s02_axi_ruser;
    wire                    s00_axi_rvalid,  s01_axi_rvalid,  s02_axi_rvalid;
    wire                    s00_axi_rready,  s01_axi_rready,  s02_axi_rready;

    wire [ID_WIDTH-1:0]     lsu_adapter_s_bid;
    wire [ID_WIDTH-1:0]     lsu_adapter_s_rid;
    assign lsu_axi_bid    = lsu_adapter_s_bid[pt.LSU_BUS_TAG-1:0];
    assign lsu_axi_rid    = lsu_adapter_s_rid[pt.LSU_BUS_TAG-1:0];

    axi_adapter_64_to_32 #(
        .ADDR_WIDTH         (ADDR_WIDTH),
        .ID_WIDTH           (ID_WIDTH)
    ) u_adapter_lsu (
        .clk                (clk),
        .rst                (rst),
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
        .m_axi_awid         (s00_axi_awid),
        .m_axi_awaddr       (s00_axi_awaddr),
        .m_axi_awlen        (s00_axi_awlen),
        .m_axi_awsize       (s00_axi_awsize),
        .m_axi_awburst      (s00_axi_awburst),
        .m_axi_awlock       (s00_axi_awlock),
        .m_axi_awcache      (s00_axi_awcache),
        .m_axi_awprot       (s00_axi_awprot),
        .m_axi_awqos        (s00_axi_awqos),
        .m_axi_awregion     (),
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
        .m_axi_arregion     (),
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

    wire [ID_WIDTH-1:0]     ifu_adapter_s_bid;
    wire [ID_WIDTH-1:0]     ifu_adapter_s_rid;
    assign ifu_axi_bid    = ifu_adapter_s_bid[pt.IFU_BUS_TAG-1:0];
    assign ifu_axi_rid    = ifu_adapter_s_rid[pt.IFU_BUS_TAG-1:0];

    axi_adapter_64_to_32 #(
        .ADDR_WIDTH         (ADDR_WIDTH),
        .ID_WIDTH           (ID_WIDTH)
    ) u_adapter_ifu (
        .clk                (clk),
        .rst                (rst),
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
        .m_axi_awid         (s01_axi_awid),
        .m_axi_awaddr       (s01_axi_awaddr),
        .m_axi_awlen        (s01_axi_awlen),
        .m_axi_awsize       (s01_axi_awsize),
        .m_axi_awburst      (s01_axi_awburst),
        .m_axi_awlock       (s01_axi_awlock),
        .m_axi_awcache      (s01_axi_awcache),
        .m_axi_awprot       (s01_axi_awprot),
        .m_axi_awqos        (s01_axi_awqos),
        .m_axi_awregion     (),
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
        .m_axi_arregion     (),
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

    wire [ID_WIDTH-1:0]     sb_adapter_s_bid;
    wire [ID_WIDTH-1:0]     sb_adapter_s_rid;
    assign sb_axi_bid     = sb_adapter_s_bid[pt.SB_BUS_TAG-1:0];
    assign sb_axi_rid     = sb_adapter_s_rid[pt.SB_BUS_TAG-1:0];

    axi_adapter_64_to_32 #(
        .ADDR_WIDTH         (ADDR_WIDTH),
        .ID_WIDTH           (ID_WIDTH)
    ) u_adapter_sb (
        .clk                (clk),
        .rst                (rst),
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
        .m_axi_awid         (s02_axi_awid),
        .m_axi_awaddr       (s02_axi_awaddr),
        .m_axi_awlen        (s02_axi_awlen),
        .m_axi_awsize       (s02_axi_awsize),
        .m_axi_awburst      (s02_axi_awburst),
        .m_axi_awlock       (s02_axi_awlock),
        .m_axi_awcache      (s02_axi_awcache),
        .m_axi_awprot       (s02_axi_awprot),
        .m_axi_awqos        (s02_axi_awqos),
        .m_axi_awregion     (),
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
        .m_axi_arregion     (),
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
    // 3. AXI Interconnect (5 Masters x 20 Slaves)
    // =========================================================================
    // Master Port Wires (Interconnect Slaves m01..m13)
    // m01: IMEM, m02: DMEM, m06: TIMER, m07: GPIO, m08: SPI, m09: WDT, m10: DMA, m11: FIR, m12: VGA, m13: SBUF
    wire [ID_WIDTH-1:0]     m_awid[1:13];
    wire [ADDR_WIDTH-1:0]   m_awaddr[1:13];
    wire [7:0]              m_awlen[1:13];
    wire [2:0]              m_awsize[1:13];
    wire [1:0]              m_awburst[1:13];
    wire                    m_awlock[1:13];
    wire [3:0]              m_awcache[1:13];
    wire [2:0]              m_awprot[1:13];
    wire [3:0]              m_awqos[1:13];
    wire [AWUSER_WIDTH-1:0] m_awuser[1:13];
    wire                    m_awvalid[1:13];
    wire                    m_awready[1:13];
    wire [DATA_WIDTH-1:0]   m_wdata[1:13];
    wire [STRB_WIDTH-1:0]   m_wstrb[1:13];
    wire                    m_wlast[1:13];
    wire [WUSER_WIDTH-1:0]  m_wuser[1:13];
    wire                    m_wvalid[1:13];
    wire                    m_wready[1:13];
    wire [ID_WIDTH-1:0]     m_bid[1:13];
    wire [1:0]              m_bresp[1:13];
    wire [BUSER_WIDTH-1:0]  m_buser[1:13];
    wire                    m_bvalid[1:13];
    wire                    m_bready[1:13];
    wire [ID_WIDTH-1:0]     m_arid[1:13];
    wire [ADDR_WIDTH-1:0]   m_araddr[1:13];
    wire [7:0]              m_arlen[1:13];
    wire [2:0]              m_arsize[1:13];
    wire [1:0]              m_arburst[1:13];
    wire                    m_arlock[1:13];
    wire [3:0]              m_arcache[1:13];
    wire [2:0]              m_arprot[1:13];
    wire [3:0]              m_arqos[1:13];
    wire [ARUSER_WIDTH-1:0] m_aruser[1:13];
    wire                    m_arvalid[1:13];
    wire                    m_arready[1:13];
    wire [ID_WIDTH-1:0]     m_rid[1:13];
    wire [DATA_WIDTH-1:0]   m_rdata[1:13];
    wire [1:0]              m_rresp[1:13];
    wire                    m_rlast[1:13];
    wire [RUSER_WIDTH-1:0]  m_ruser[1:13];
    wire                    m_rvalid[1:13];
    wire                    m_rready[1:13];

    axi_interconnect_uart_top #(
        .DATA_WIDTH         (DATA_WIDTH),
        .ADDR_WIDTH         (ADDR_WIDTH),
        .STRB_WIDTH         (STRB_WIDTH),
        .ID_WIDTH           (ID_WIDTH),
        .UART_BASE_ADDR     (UART_BASE_ADDR),
        .UART_ADDR_WIDTH    (UART_ADDR_WIDTH),
        .M01_BASE_ADDR      (IMEM_BASE_ADDR),
        .M01_ADDR_WIDTH     (IMEM_ADDR_WIDTH),
        .M02_BASE_ADDR      (DMEM_BASE_ADDR),
        .M02_ADDR_WIDTH     (DMEM_ADDR_WIDTH),
        .M03_BASE_ADDR      (I2C_BASE_ADDR),
        .M03_ADDR_WIDTH     (I2C_ADDR_WIDTH),
        .M04_BASE_ADDR      (PWM_BASE_ADDR),
        .M04_ADDR_WIDTH     (PWM_ADDR_WIDTH),
        .M05_BASE_ADDR      (SSD_BASE_ADDR),
        .M05_ADDR_WIDTH     (SSD_ADDR_WIDTH),
        .M06_BASE_ADDR      (TIMER_BASE_ADDR),
        .M06_ADDR_WIDTH     (TIMER_ADDR_WIDTH),
        .M07_BASE_ADDR      (GPIO_BASE_ADDR),
        .M07_ADDR_WIDTH     (GPIO_ADDR_WIDTH),
        .M08_BASE_ADDR      (SPI_BASE_ADDR),
        .M08_ADDR_WIDTH     (SPI_ADDR_WIDTH),
        .M09_BASE_ADDR      (WDT_BASE_ADDR),
        .M09_ADDR_WIDTH     (WDT_ADDR_WIDTH),
        .M10_BASE_ADDR      (DMA_BASE_ADDR),
        .M10_ADDR_WIDTH     (DMA_ADDR_WIDTH),
        .M11_BASE_ADDR      (FIR_BASE_ADDR),
        .M11_ADDR_WIDTH     (FIR_ADDR_WIDTH),
        .M12_BASE_ADDR      (VGA_BASE_ADDR),
        .M12_ADDR_WIDTH     (VGA_ADDR_WIDTH),
        .M13_BASE_ADDR      (SBUF_BASE_ADDR),
        .M13_ADDR_WIDTH     (SBUF_ADDR_WIDTH),
        .M14_BASE_ADDR      (32'h5000_0000),
        .M14_ADDR_WIDTH     ({M_REGIONS{32'd12}}),
        .M15_BASE_ADDR      (32'h5000_1000),
        .M15_ADDR_WIDTH     ({M_REGIONS{32'd12}}),
        .M16_BASE_ADDR      (32'h5000_2000),
        .M16_ADDR_WIDTH     ({M_REGIONS{32'd12}}),
        .M17_BASE_ADDR      (32'h5000_3000),
        .M17_ADDR_WIDTH     ({M_REGIONS{32'd12}}),
        .M18_BASE_ADDR      (32'h5000_4000),
        .M18_ADDR_WIDTH     ({M_REGIONS{32'd12}}),
        .M19_BASE_ADDR      (32'h5000_5000),
        .M19_ADDR_WIDTH     ({M_REGIONS{32'd12}})
    )
    u_interconnect_uart (
        .clk                (clk),
        .uart_clk           (clk),
        .rst                (rst),
        .uart_rx            (uart_rx),
        .uart_tx            (uart_tx),
        .uart_irq           (uart_irq),

        // Slave 00: LSU
        .s00_axi_awid(s00_axi_awid), .s00_axi_awaddr(s00_axi_awaddr), .s00_axi_awlen(s00_axi_awlen), .s00_axi_awsize(s00_axi_awsize),
        .s00_axi_awburst(s00_axi_awburst), .s00_axi_awlock(s00_axi_awlock), .s00_axi_awcache(s00_axi_awcache), .s00_axi_awprot(s00_axi_awprot),
        .s00_axi_awqos(s00_axi_awqos), .s00_axi_awuser(s00_axi_awuser), .s00_axi_awvalid(s00_axi_awvalid), .s00_axi_awready(s00_axi_awready),
        .s00_axi_wdata(s00_axi_wdata), .s00_axi_wstrb(s00_axi_wstrb), .s00_axi_wlast(s00_axi_wlast), .s00_axi_wuser(s00_axi_wuser), .s00_axi_wvalid(s00_axi_wvalid), .s00_axi_wready(s00_axi_wready),
        .s00_axi_bid(s00_axi_bid), .s00_axi_bresp(s00_axi_bresp), .s00_axi_buser(s00_axi_buser), .s00_axi_bvalid(s00_axi_bvalid), .s00_axi_bready(s00_axi_bready),
        .s00_axi_arid(s00_axi_arid), .s00_axi_araddr(s00_axi_araddr), .s00_axi_arlen(s00_axi_arlen), .s00_axi_arsize(s00_axi_arsize),
        .s00_axi_arburst(s00_axi_arburst), .s00_axi_arlock(s00_axi_arlock), .s00_axi_arcache(s00_axi_arcache), .s00_axi_arprot(s00_axi_arprot),
        .s00_axi_arqos(s00_axi_arqos), .s00_axi_aruser(s00_axi_aruser), .s00_axi_arvalid(s00_axi_arvalid), .s00_axi_arready(s00_axi_arready),
        .s00_axi_rid(s00_axi_rid), .s00_axi_rdata(s00_axi_rdata), .s00_axi_rresp(s00_axi_rresp), .s00_axi_rlast(s00_axi_rlast), .s00_axi_ruser(s00_axi_ruser), .s00_axi_rvalid(s00_axi_rvalid), .s00_axi_rready(s00_axi_rready),

        // Slave 01: IFU
        .s01_axi_awid(s01_axi_awid), .s01_axi_awaddr(s01_axi_awaddr), .s01_axi_awlen(s01_axi_awlen), .s01_axi_awsize(s01_axi_awsize),
        .s01_axi_awburst(s01_axi_awburst), .s01_axi_awlock(s01_axi_awlock), .s01_axi_awcache(s01_axi_awcache), .s01_axi_awprot(s01_axi_awprot),
        .s01_axi_awqos(s01_axi_awqos), .s01_axi_awuser(s01_axi_awuser), .s01_axi_awvalid(s01_axi_awvalid), .s01_axi_awready(s01_axi_awready),
        .s01_axi_wdata(s01_axi_wdata), .s01_axi_wstrb(s01_axi_wstrb), .s01_axi_wlast(s01_axi_wlast), .s01_axi_wuser(s01_axi_wuser), .s01_axi_wvalid(s01_axi_wvalid), .s01_axi_wready(s01_axi_wready),
        .s01_axi_bid(s01_axi_bid), .s01_axi_bresp(s01_axi_bresp), .s01_axi_buser(s01_axi_buser), .s01_axi_bvalid(s01_axi_bvalid), .s01_axi_bready(s01_axi_bready),
        .s01_axi_arid(s01_axi_arid), .s01_axi_araddr(s01_axi_araddr), .s01_axi_arlen(s01_axi_arlen), .s01_axi_arsize(s01_axi_arsize),
        .s01_axi_arburst(s01_axi_arburst), .s01_axi_arlock(s01_axi_arlock), .s01_axi_arcache(s01_axi_arcache), .s01_axi_arprot(s01_axi_arprot),
        .s01_axi_arqos(s01_axi_arqos), .s01_axi_aruser(s01_axi_aruser), .s01_axi_arvalid(s01_axi_arvalid), .s01_axi_arready(s01_axi_arready),
        .s01_axi_rid(s01_axi_rid), .s01_axi_rdata(s01_axi_rdata), .s01_axi_rresp(s01_axi_rresp), .s01_axi_rlast(s01_axi_rlast), .s01_axi_ruser(s01_axi_ruser), .s01_axi_rvalid(s01_axi_rvalid), .s01_axi_rready(s01_axi_rready),

        // Slave 02: SB
        .s02_axi_awid(s02_axi_awid), .s02_axi_awaddr(s02_axi_awaddr), .s02_axi_awlen(s02_axi_awlen), .s02_axi_awsize(s02_axi_awsize),
        .s02_axi_awburst(s02_axi_awburst), .s02_axi_awlock(s02_axi_awlock), .s02_axi_awcache(s02_axi_awcache), .s02_axi_awprot(s02_axi_awprot),
        .s02_axi_awqos(s02_axi_awqos), .s02_axi_awuser(s02_axi_awuser), .s02_axi_awvalid(s02_axi_awvalid), .s02_axi_awready(s02_axi_awready),
        .s02_axi_wdata(s02_axi_wdata), .s02_axi_wstrb(s02_axi_wstrb), .s02_axi_wlast(s02_axi_wlast), .s02_axi_wuser(s02_axi_wuser), .s02_axi_wvalid(s02_axi_wvalid), .s02_axi_wready(s02_axi_wready),
        .s02_axi_bid(s02_axi_bid), .s02_axi_bresp(s02_axi_bresp), .s02_axi_buser(s02_axi_buser), .s02_axi_bvalid(s02_axi_bvalid), .s02_axi_bready(s02_axi_bready),
        .s02_axi_arid(s02_axi_arid), .s02_axi_araddr(s02_axi_araddr), .s02_axi_arlen(s02_axi_arlen), .s02_axi_arsize(s02_axi_arsize),
        .s02_axi_arburst(s02_axi_arburst), .s02_axi_arlock(s02_axi_arlock), .s02_axi_arcache(s02_axi_arcache), .s02_axi_arprot(s02_axi_arprot),
        .s02_axi_arqos(s02_axi_arqos), .s02_axi_aruser(s02_axi_aruser), .s02_axi_arvalid(s02_axi_arvalid), .s02_axi_arready(s02_axi_arready),
        .s02_axi_rid(s02_axi_rid), .s02_axi_rdata(s02_axi_rdata), .s02_axi_rresp(s02_axi_rresp), .s02_axi_rlast(s02_axi_rlast), .s02_axi_ruser(s02_axi_ruser), .s02_axi_rvalid(s02_axi_rvalid), .s02_axi_rready(s02_axi_rready),

        // Masters M01..M13
        .m01_axi_awid(m_awid[1]), .m01_axi_awaddr(m_awaddr[1]), .m01_axi_awlen(m_awlen[1]), .m01_axi_awsize(m_awsize[1]), .m01_axi_awburst(m_awburst[1]), .m01_axi_awlock(m_awlock[1]), .m01_axi_awcache(m_awcache[1]), .m01_axi_awprot(m_awprot[1]), .m01_axi_awqos(m_awqos[1]), .m01_axi_awregion(), .m01_axi_awuser(m_awuser[1]), .m01_axi_awvalid(m_awvalid[1]), .m01_axi_awready(m_awready[1]),
        .m01_axi_wdata(m_wdata[1]), .m01_axi_wstrb(m_wstrb[1]), .m01_axi_wlast(m_wlast[1]), .m01_axi_wuser(m_wuser[1]), .m01_axi_wvalid(m_wvalid[1]), .m01_axi_wready(m_wready[1]),
        .m01_axi_bid(m_bid[1]), .m01_axi_bresp(m_bresp[1]), .m01_axi_buser(m_buser[1]), .m01_axi_bvalid(m_bvalid[1]), .m01_axi_bready(m_bready[1]),
        .m01_axi_arid(m_arid[1]), .m01_axi_araddr(m_araddr[1]), .m01_axi_arlen(m_arlen[1]), .m01_axi_arsize(m_arsize[1]), .m01_axi_arburst(m_arburst[1]), .m01_axi_arlock(m_arlock[1]), .m01_axi_arcache(m_arcache[1]), .m01_axi_arprot(m_arprot[1]), .m01_axi_arqos(m_arqos[1]), .m01_axi_arregion(), .m01_axi_aruser(m_aruser[1]), .m01_axi_arvalid(m_arvalid[1]), .m01_axi_arready(m_arready[1]),
        .m01_axi_rid(m_rid[1]), .m01_axi_rdata(m_rdata[1]), .m01_axi_rresp(m_rresp[1]), .m01_axi_rlast(m_rlast[1]), .m01_axi_ruser(m_ruser[1]), .m01_axi_rvalid(m_rvalid[1]), .m01_axi_rready(m_rready[1]),

        .m02_axi_awid(m_awid[2]), .m02_axi_awaddr(m_awaddr[2]), .m02_axi_awlen(m_awlen[2]), .m02_axi_awsize(m_awsize[2]), .m02_axi_awburst(m_awburst[2]), .m02_axi_awlock(m_awlock[2]), .m02_axi_awcache(m_awcache[2]), .m02_axi_awprot(m_awprot[2]), .m02_axi_awqos(m_awqos[2]), .m02_axi_awregion(), .m02_axi_awuser(m_awuser[2]), .m02_axi_awvalid(m_awvalid[2]), .m02_axi_awready(m_awready[2]),
        .m02_axi_wdata(m_wdata[2]), .m02_axi_wstrb(m_wstrb[2]), .m02_axi_wlast(m_wlast[2]), .m02_axi_wuser(m_wuser[2]), .m02_axi_wvalid(m_wvalid[2]), .m02_axi_wready(m_wready[2]),
        .m02_axi_bid(m_bid[2]), .m02_axi_bresp(m_bresp[2]), .m02_axi_buser(m_buser[2]), .m02_axi_bvalid(m_bvalid[2]), .m02_axi_bready(m_bready[2]),
        .m02_axi_arid(m_arid[2]), .m02_axi_araddr(m_araddr[2]), .m02_axi_arlen(m_arlen[2]), .m02_axi_arsize(m_arsize[2]), .m02_axi_arburst(m_arburst[2]), .m02_axi_arlock(m_arlock[2]), .m02_axi_arcache(m_arcache[2]), .m02_axi_arprot(m_arprot[2]), .m02_axi_arqos(m_arqos[2]), .m02_axi_arregion(), .m02_axi_aruser(m_aruser[2]), .m02_axi_arvalid(m_arvalid[2]), .m02_axi_arready(m_arready[2]),
        .m02_axi_rid(m_rid[2]), .m02_axi_rdata(m_rdata[2]), .m02_axi_rresp(m_rresp[2]), .m02_axi_rlast(m_rlast[2]), .m02_axi_ruser(m_ruser[2]), .m02_axi_rvalid(m_rvalid[2]), .m02_axi_rready(m_rready[2]),

        // M03..M05: Stubbed / Tied-off with DECERR
        .m03_axi_awready(1'b0), .m03_axi_wready(1'b0), .m03_axi_bid('0), .m03_axi_bresp(2'b11), .m03_axi_buser('0), .m03_axi_bvalid(1'b0),
        .m03_axi_arready(1'b0), .m03_axi_rid('0), .m03_axi_rdata('0), .m03_axi_rresp(2'b11), .m03_axi_rlast(1'b0), .m03_axi_ruser('0), .m03_axi_rvalid(1'b0),
        .m04_axi_awready(1'b0), .m04_axi_wready(1'b0), .m04_axi_bid('0), .m04_axi_bresp(2'b11), .m04_axi_buser('0), .m04_axi_bvalid(1'b0),
        .m04_axi_arready(1'b0), .m04_axi_rid('0), .m04_axi_rdata('0), .m04_axi_rresp(2'b11), .m04_axi_rlast(1'b0), .m04_axi_ruser('0), .m04_axi_rvalid(1'b0),
        .m05_axi_awready(1'b0), .m05_axi_wready(1'b0), .m05_axi_bid('0), .m05_axi_bresp(2'b11), .m05_axi_buser('0), .m05_axi_bvalid(1'b0),
        .m05_axi_arready(1'b0), .m05_axi_rid('0), .m05_axi_rdata('0), .m05_axi_rresp(2'b11), .m05_axi_rlast(1'b0), .m05_axi_ruser('0), .m05_axi_rvalid(1'b0),

        // M06: Timer
        .m06_axi_awid(m_awid[6]), .m06_axi_awaddr(m_awaddr[6]), .m06_axi_awlen(m_awlen[6]), .m06_axi_awsize(m_awsize[6]), .m06_axi_awburst(m_awburst[6]), .m06_axi_awlock(m_awlock[6]), .m06_axi_awcache(m_awcache[6]), .m06_axi_awprot(m_awprot[6]), .m06_axi_awqos(m_awqos[6]), .m06_axi_awregion(), .m06_axi_awuser(m_awuser[6]), .m06_axi_awvalid(m_awvalid[6]), .m06_axi_awready(m_awready[6]),
        .m06_axi_wdata(m_wdata[6]), .m06_axi_wstrb(m_wstrb[6]), .m06_axi_wlast(m_wlast[6]), .m06_axi_wuser(m_wuser[6]), .m06_axi_wvalid(m_wvalid[6]), .m06_axi_wready(m_wready[6]),
        .m06_axi_bid(m_bid[6]), .m06_axi_bresp(m_bresp[6]), .m06_axi_buser(m_buser[6]), .m06_axi_bvalid(m_bvalid[6]), .m06_axi_bready(m_bready[6]),
        .m06_axi_arid(m_arid[6]), .m06_axi_araddr(m_araddr[6]), .m06_axi_arlen(m_arlen[6]), .m06_axi_arsize(m_arsize[6]), .m06_axi_arburst(m_arburst[6]), .m06_axi_arlock(m_arlock[6]), .m06_axi_arcache(m_arcache[6]), .m06_axi_arprot(m_arprot[6]), .m06_axi_arqos(m_arqos[6]), .m06_axi_arregion(), .m06_axi_aruser(m_aruser[6]), .m06_axi_arvalid(m_arvalid[6]), .m06_axi_arready(m_arready[6]),
        .m06_axi_rid(m_rid[6]), .m06_axi_rdata(m_rdata[6]), .m06_axi_rresp(m_rresp[6]), .m06_axi_rlast(m_rlast[6]), .m06_axi_ruser(m_ruser[6]), .m06_axi_rvalid(m_rvalid[6]), .m06_axi_rready(m_rready[6]),

        // M07: GPIO
        .m07_axi_awid(m_awid[7]), .m07_axi_awaddr(m_awaddr[7]), .m07_axi_awlen(m_awlen[7]), .m07_axi_awsize(m_awsize[7]), .m07_axi_awburst(m_awburst[7]), .m07_axi_awlock(m_awlock[7]), .m07_axi_awcache(m_awcache[7]), .m07_axi_awprot(m_awprot[7]), .m07_axi_awqos(m_awqos[7]), .m07_axi_awregion(), .m07_axi_awuser(m_awuser[7]), .m07_axi_awvalid(m_awvalid[7]), .m07_axi_awready(m_awready[7]),
        .m07_axi_wdata(m_wdata[7]), .m07_axi_wstrb(m_wstrb[7]), .m07_axi_wlast(m_wlast[7]), .m07_axi_wuser(m_wuser[7]), .m07_axi_wvalid(m_wvalid[7]), .m07_axi_wready(m_wready[7]),
        .m07_axi_bid(m_bid[7]), .m07_axi_bresp(m_bresp[7]), .m07_axi_buser(m_buser[7]), .m07_axi_bvalid(m_bvalid[7]), .m07_axi_bready(m_bready[7]),
        .m07_axi_arid(m_arid[7]), .m07_axi_araddr(m_araddr[7]), .m07_axi_arlen(m_arlen[7]), .m07_axi_arsize(m_arsize[7]), .m07_axi_arburst(m_arburst[7]), .m07_axi_arlock(m_arlock[7]), .m07_axi_arcache(m_arcache[7]), .m07_axi_arprot(m_arprot[7]), .m07_axi_arqos(m_arqos[7]), .m07_axi_arregion(), .m07_axi_aruser(m_aruser[7]), .m07_axi_arvalid(m_arvalid[7]), .m07_axi_arready(m_arready[7]),
        .m07_axi_rid(m_rid[7]), .m07_axi_rdata(m_rdata[7]), .m07_axi_rresp(m_rresp[7]), .m07_axi_rlast(m_rlast[7]), .m07_axi_ruser(m_ruser[7]), .m07_axi_rvalid(m_rvalid[7]), .m07_axi_rready(m_rready[7]),

        // M08: SPI Master
        .m08_axi_awid(m_awid[8]), .m08_axi_awaddr(m_awaddr[8]), .m08_axi_awlen(m_awlen[8]), .m08_axi_awsize(m_awsize[8]), .m08_axi_awburst(m_awburst[8]), .m08_axi_awlock(m_awlock[8]), .m08_axi_awcache(m_awcache[8]), .m08_axi_awprot(m_awprot[8]), .m08_axi_awqos(m_awqos[8]), .m08_axi_awregion(), .m08_axi_awuser(m_awuser[8]), .m08_axi_awvalid(m_awvalid[8]), .m08_axi_awready(m_awready[8]),
        .m08_axi_wdata(m_wdata[8]), .m08_axi_wstrb(m_wstrb[8]), .m08_axi_wlast(m_wlast[8]), .m08_axi_wuser(m_wuser[8]), .m08_axi_wvalid(m_wvalid[8]), .m08_axi_wready(m_wready[8]),
        .m08_axi_bid(m_bid[8]), .m08_axi_bresp(m_bresp[8]), .m08_axi_buser(m_buser[8]), .m08_axi_bvalid(m_bvalid[8]), .m08_axi_bready(m_bready[8]),
        .m08_axi_arid(m_arid[8]), .m08_axi_araddr(m_araddr[8]), .m08_axi_arlen(m_arlen[8]), .m08_axi_arsize(m_arsize[8]), .m08_axi_arburst(m_arburst[8]), .m08_axi_arlock(m_arlock[8]), .m08_axi_arcache(m_arcache[8]), .m08_axi_arprot(m_arprot[8]), .m08_axi_arqos(m_arqos[8]), .m08_axi_arregion(), .m08_axi_aruser(m_aruser[8]), .m08_axi_arvalid(m_arvalid[8]), .m08_axi_arready(m_arready[8]),
        .m08_axi_rid(m_rid[8]), .m08_axi_rdata(m_rdata[8]), .m08_axi_rresp(m_rresp[8]), .m08_axi_rlast(m_rlast[8]), .m08_axi_ruser(m_ruser[8]), .m08_axi_rvalid(m_rvalid[8]), .m08_axi_rready(m_rready[8]),

        // M09: Watchdog
        .m09_axi_awid(m_awid[9]), .m09_axi_awaddr(m_awaddr[9]), .m09_axi_awlen(m_awlen[9]), .m09_axi_awsize(m_awsize[9]), .m09_axi_awburst(m_awburst[9]), .m09_axi_awlock(m_awlock[9]), .m09_axi_awcache(m_awcache[9]), .m09_axi_awprot(m_awprot[9]), .m09_axi_awqos(m_awqos[9]), .m09_axi_awregion(), .m09_axi_awuser(m_awuser[9]), .m09_axi_awvalid(m_awvalid[9]), .m09_axi_awready(m_awready[9]),
        .m09_axi_wdata(m_wdata[9]), .m09_axi_wstrb(m_wstrb[9]), .m09_axi_wlast(m_wlast[9]), .m09_axi_wuser(m_wuser[9]), .m09_axi_wvalid(m_wvalid[9]), .m09_axi_wready(m_wready[9]),
        .m09_axi_bid(m_bid[9]), .m09_axi_bresp(m_bresp[9]), .m09_axi_buser(m_buser[9]), .m09_axi_bvalid(m_bvalid[9]), .m09_axi_bready(m_bready[9]),
        .m09_axi_arid(m_arid[9]), .m09_axi_araddr(m_araddr[9]), .m09_axi_arlen(m_arlen[9]), .m09_axi_arsize(m_arsize[9]), .m09_axi_arburst(m_arburst[9]), .m09_axi_arlock(m_arlock[9]), .m09_axi_arcache(m_arcache[9]), .m09_axi_arprot(m_arprot[9]), .m09_axi_arqos(m_arqos[9]), .m09_axi_arregion(), .m09_axi_aruser(m_aruser[9]), .m09_axi_arvalid(m_arvalid[9]), .m09_axi_arready(m_arready[9]),
        .m09_axi_rid(m_rid[9]), .m09_axi_rdata(m_rdata[9]), .m09_axi_rresp(m_rresp[9]), .m09_axi_rlast(m_rlast[9]), .m09_axi_ruser(m_ruser[9]), .m09_axi_rvalid(m_rvalid[9]), .m09_axi_rready(m_rready[9]),

        // M10: DMA Controller
        .m10_axi_awid(m_awid[10]), .m10_axi_awaddr(m_awaddr[10]), .m10_axi_awlen(m_awlen[10]), .m10_axi_awsize(m_awsize[10]), .m10_axi_awburst(m_awburst[10]), .m10_axi_awlock(m_awlock[10]), .m10_axi_awcache(m_awcache[10]), .m10_axi_awprot(m_awprot[10]), .m10_axi_awqos(m_awqos[10]), .m10_axi_awregion(), .m10_axi_awuser(m_awuser[10]), .m10_axi_awvalid(m_awvalid[10]), .m10_axi_awready(m_awready[10]),
        .m10_axi_wdata(m_wdata[10]), .m10_axi_wstrb(m_wstrb[10]), .m10_axi_wlast(m_wlast[10]), .m10_axi_wuser(m_wuser[10]), .m10_axi_wvalid(m_wvalid[10]), .m10_axi_wready(m_wready[10]),
        .m10_axi_bid(m_bid[10]), .m10_axi_bresp(m_bresp[10]), .m10_axi_buser(m_buser[10]), .m10_axi_bvalid(m_bvalid[10]), .m10_axi_bready(m_bready[10]),
        .m10_axi_arid(m_arid[10]), .m10_axi_araddr(m_araddr[10]), .m10_axi_arlen(m_arlen[10]), .m10_axi_arsize(m_arsize[10]), .m10_axi_arburst(m_arburst[10]), .m10_axi_arlock(m_arlock[10]), .m10_axi_arcache(m_arcache[10]), .m10_axi_arprot(m_arprot[10]), .m10_axi_arqos(m_arqos[10]), .m10_axi_arregion(), .m10_axi_aruser(m_aruser[10]), .m10_axi_arvalid(m_arvalid[10]), .m10_axi_arready(m_arready[10]),
        .m10_axi_rid(m_rid[10]), .m10_axi_rdata(m_rdata[10]), .m10_axi_rresp(m_rresp[10]), .m10_axi_rlast(m_rlast[10]), .m10_axi_ruser(m_ruser[10]), .m10_axi_rvalid(m_rvalid[10]), .m10_axi_rready(m_rready[10]),

        // M11: FIR Filter
        .m11_axi_awid(m_awid[11]), .m11_axi_awaddr(m_awaddr[11]), .m11_axi_awlen(m_awlen[11]), .m11_axi_awsize(m_awsize[11]), .m11_axi_awburst(m_awburst[11]), .m11_axi_awlock(m_awlock[11]), .m11_axi_awcache(m_awcache[11]), .m11_axi_awprot(m_awprot[11]), .m11_axi_awqos(m_awqos[11]), .m11_axi_awregion(), .m11_axi_awuser(m_awuser[11]), .m11_axi_awvalid(m_awvalid[11]), .m11_axi_awready(m_awready[11]),
        .m11_axi_wdata(m_wdata[11]), .m11_axi_wstrb(m_wstrb[11]), .m11_axi_wlast(m_wlast[11]), .m11_axi_wuser(m_wuser[11]), .m11_axi_wvalid(m_wvalid[11]), .m11_axi_wready(m_wready[11]),
        .m11_axi_bid(m_bid[11]), .m11_axi_bresp(m_bresp[11]), .m11_axi_buser(m_buser[11]), .m11_axi_bvalid(m_bvalid[11]), .m11_axi_bready(m_bready[11]),
        .m11_axi_arid(m_arid[11]), .m11_axi_araddr(m_araddr[11]), .m11_axi_arlen(m_arlen[11]), .m11_axi_arsize(m_arsize[11]), .m11_axi_arburst(m_arburst[11]), .m11_axi_arlock(m_arlock[11]), .m11_axi_arcache(m_arcache[11]), .m11_axi_arprot(m_arprot[11]), .m11_axi_arqos(m_arqos[11]), .m11_axi_arregion(), .m11_axi_aruser(m_aruser[11]), .m11_axi_arvalid(m_arvalid[11]), .m11_axi_arready(m_arready[11]),
        .m11_axi_rid(m_rid[11]), .m11_axi_rdata(m_rdata[11]), .m11_axi_rresp(m_rresp[11]), .m11_axi_rlast(m_rlast[11]), .m11_axi_ruser(m_ruser[11]), .m11_axi_rvalid(m_rvalid[11]), .m11_axi_rready(m_rready[11]),

        // M12: VGA Controller
        .m12_axi_awid(m_awid[12]), .m12_axi_awaddr(m_awaddr[12]), .m12_axi_awlen(m_awlen[12]), .m12_axi_awsize(m_awsize[12]), .m12_axi_awburst(m_awburst[12]), .m12_axi_awlock(m_awlock[12]), .m12_axi_awcache(m_awcache[12]), .m12_axi_awprot(m_awprot[12]), .m12_axi_awqos(m_awqos[12]), .m12_axi_awregion(), .m12_axi_awuser(m_awuser[12]), .m12_axi_awvalid(m_awvalid[12]), .m12_axi_awready(m_awready[12]),
        .m12_axi_wdata(m_wdata[12]), .m12_axi_wstrb(m_wstrb[12]), .m12_axi_wlast(m_wlast[12]), .m12_axi_wuser(m_wuser[12]), .m12_axi_wvalid(m_wvalid[12]), .m12_axi_wready(m_wready[12]),
        .m12_axi_bid(m_bid[12]), .m12_axi_bresp(m_bresp[12]), .m12_axi_buser(m_buser[12]), .m12_axi_bvalid(m_bvalid[12]), .m12_axi_bready(m_bready[12]),
        .m12_axi_arid(m_arid[12]), .m12_axi_araddr(m_araddr[12]), .m12_axi_arlen(m_arlen[12]), .m12_axi_arsize(m_arsize[12]), .m12_axi_arburst(m_arburst[12]), .m12_axi_arlock(m_arlock[12]), .m12_axi_arcache(m_arcache[12]), .m12_axi_arprot(m_arprot[12]), .m12_axi_arqos(m_arqos[12]), .m12_axi_arregion(), .m12_axi_aruser(m_aruser[12]), .m12_axi_arvalid(m_arvalid[12]), .m12_axi_arready(m_arready[12]),
        .m12_axi_rid(m_rid[12]), .m12_axi_rdata(m_rdata[12]), .m12_axi_rresp(m_rresp[12]), .m12_axi_rlast(m_rlast[12]), .m12_axi_ruser(m_ruser[12]), .m12_axi_rvalid(m_rvalid[12]), .m12_axi_rready(m_rready[12]),

        // M13: Sample Buffer
        .m13_axi_awid(m_awid[13]), .m13_axi_awaddr(m_awaddr[13]), .m13_axi_awlen(m_awlen[13]), .m13_axi_awsize(m_awsize[13]), .m13_axi_awburst(m_awburst[13]), .m13_axi_awlock(m_awlock[13]), .m13_axi_awcache(m_awcache[13]), .m13_axi_awprot(m_awprot[13]), .m13_axi_awqos(m_awqos[13]), .m13_axi_awregion(), .m13_axi_awuser(m_awuser[13]), .m13_axi_awvalid(m_awvalid[13]), .m13_axi_awready(m_awready[13]),
        .m13_axi_wdata(m_wdata[13]), .m13_axi_wstrb(m_wstrb[13]), .m13_axi_wlast(m_wlast[13]), .m13_axi_wuser(m_wuser[13]), .m13_axi_wvalid(m_wvalid[13]), .m13_axi_wready(m_wready[13]),
        .m13_axi_bid(m_bid[13]), .m13_axi_bresp(m_bresp[13]), .m13_axi_buser(m_buser[13]), .m13_axi_bvalid(m_bvalid[13]), .m13_axi_bready(m_bready[13]),
        .m13_axi_arid(m_arid[13]), .m13_axi_araddr(m_araddr[13]), .m13_axi_arlen(m_arlen[13]), .m13_axi_arsize(m_arsize[13]), .m13_axi_arburst(m_arburst[13]), .m13_axi_arlock(m_arlock[13]), .m13_axi_arcache(m_arcache[13]), .m13_axi_arprot(m_arprot[13]), .m13_axi_arqos(m_arqos[13]), .m13_axi_arregion(), .m13_axi_aruser(m_aruser[13]), .m13_axi_arvalid(m_arvalid[13]), .m13_axi_arready(m_arready[13]),
        .m13_axi_rid(m_rid[13]), .m13_axi_rdata(m_rdata[13]), .m13_axi_rresp(m_rresp[13]), .m13_axi_rlast(m_rlast[13]), .m13_axi_ruser(m_ruser[13]), .m13_axi_rvalid(m_rvalid[13]), .m13_axi_rready(m_rready[13])
    );

    // =========================================================================
    // 4. Memory Subsystem: On-Chip IMEM and DMEM
    // =========================================================================
    // M01: IMEM (64 KB at 0x1000_0000)
    axi_ram #(
        .DATA_WIDTH     (DATA_WIDTH),
        .ADDR_WIDTH     (ADDR_WIDTH),
        .ID_WIDTH       (ID_WIDTH),
        .DEPTH          (16384),
        .MEM_ADDR_WIDTH (14),
        .INIT_FILE      (IMEM_INIT_FILE)
    ) u_imem (
        .clk            (clk),
        .rst_n          (rst_n),
        .s_axi_awid     (m_awid[1]),
        .s_axi_awaddr   (m_awaddr[1]),
        .s_axi_awlen    (m_awlen[1]),
        .s_axi_awsize   (m_awsize[1]),
        .s_axi_awburst  (m_awburst[1]),
        .s_axi_awlock   (m_awlock[1]),
        .s_axi_awcache  (m_awcache[1]),
        .s_axi_awprot   (m_awprot[1]),
        .s_axi_awqos    (m_awqos[1]),
        .s_axi_awregion (),
        .s_axi_awvalid  (m_awvalid[1]),
        .s_axi_awready  (m_awready[1]),
        .s_axi_wdata    (m_wdata[1]),
        .s_axi_wstrb    (m_wstrb[1]),
        .s_axi_wlast    (m_wlast[1]),
        .s_axi_wvalid   (m_wvalid[1]),
        .s_axi_wready   (m_wready[1]),
        .s_axi_bid      (m_bid[1]),
        .s_axi_bresp    (m_bresp[1]),
        .s_axi_bvalid   (m_bvalid[1]),
        .s_axi_bready   (m_bready[1]),
        .s_axi_arid     (m_arid[1]),
        .s_axi_araddr   (m_araddr[1]),
        .s_axi_arlen    (m_arlen[1]),
        .s_axi_arsize   (m_arsize[1]),
        .s_axi_arburst  (m_arburst[1]),
        .s_axi_arlock   (m_arlock[1]),
        .s_axi_arcache  (m_arcache[1]),
        .s_axi_arprot   (m_arprot[1]),
        .s_axi_arqos    (m_arqos[1]),
        .s_axi_arregion (),
        .s_axi_arvalid  (m_arvalid[1]),
        .s_axi_arready  (m_arready[1]),
        .s_axi_rid      (m_rid[1]),
        .s_axi_rdata    (m_rdata[1]),
        .s_axi_rresp    (m_rresp[1]),
        .s_axi_rlast    (m_rlast[1]),
        .s_axi_rvalid   (m_rvalid[1]),
        .s_axi_rready   (m_rready[1])
    );

    // M02: DMEM (64 KB at 0x1002_0000)
    axi_ram #(
        .DATA_WIDTH     (DATA_WIDTH),
        .ADDR_WIDTH     (ADDR_WIDTH),
        .ID_WIDTH       (ID_WIDTH),
        .DEPTH          (16384),
        .MEM_ADDR_WIDTH (14),
        .INIT_FILE      ("")
    ) u_dmem (
        .clk            (clk),
        .rst_n          (rst_n),
        .s_axi_awid     (m_awid[2]),
        .s_axi_awaddr   (m_awaddr[2]),
        .s_axi_awlen    (m_awlen[2]),
        .s_axi_awsize   (m_awsize[2]),
        .s_axi_awburst  (m_awburst[2]),
        .s_axi_awlock   (m_awlock[2]),
        .s_axi_awcache  (m_awcache[2]),
        .s_axi_awprot   (m_awprot[2]),
        .s_axi_awqos    (m_awqos[2]),
        .s_axi_awregion (),
        .s_axi_awvalid  (m_awvalid[2]),
        .s_axi_awready  (m_awready[2]),
        .s_axi_wdata    (m_wdata[2]),
        .s_axi_wstrb    (m_wstrb[2]),
        .s_axi_wlast    (m_wlast[2]),
        .s_axi_wvalid   (m_wvalid[2]),
        .s_axi_wready   (m_wready[2]),
        .s_axi_bid      (m_bid[2]),
        .s_axi_bresp    (m_bresp[2]),
        .s_axi_bvalid   (m_bvalid[2]),
        .s_axi_bready   (m_bready[2]),
        .s_axi_arid     (m_arid[2]),
        .s_axi_araddr   (m_araddr[2]),
        .s_axi_arlen    (m_arlen[2]),
        .s_axi_arsize   (m_arsize[2]),
        .s_axi_arburst  (m_arburst[2]),
        .s_axi_arlock   (m_arlock[2]),
        .s_axi_arcache  (m_arcache[2]),
        .s_axi_arprot   (m_arprot[2]),
        .s_axi_arqos    (m_arqos[2]),
        .s_axi_arregion (),
        .s_axi_arvalid  (m_arvalid[2]),
        .s_axi_arready  (m_arready[2]),
        .s_axi_rid      (m_rid[2]),
        .s_axi_rdata    (m_rdata[2]),
        .s_axi_rresp    (m_rresp[2]),
        .s_axi_rlast    (m_rlast[2]),
        .s_axi_rvalid   (m_rvalid[2]),
        .s_axi_rready   (m_rready[2])
    );

    // =========================================================================
    // 5. Hardware Datapath Wiring: Signals between Peripherals
    // =========================================================================
    wire sample_tick;
    wire spi_sample_ready;
    wire [15:0] spi_sample_data;

    wire signed [15:0] fir_sample_in;
    wire               fir_sample_valid_in;
    wire signed [15:0] fir_sample_out;
    wire               fir_sample_valid_out;

    wire [11:0]        sbuf_waddr;
    wire [15:0]        sbuf_wdata;
    wire               sbuf_we;
    wire               buf_swap_req;
    wire               vga_vsync_pulse;
    wire               active_wr_buf;
    wire               active_rd_buf;

    wire [11:0]        sbuf_raddr;
    wire [15:0]        sbuf_rdata;

    // =========================================================================
    // 6. Integrated Peripheral Subsystem
    // =========================================================================
    // --- M06: Acquisition Timer (0x4000_8000) ---
    wire [ADDR_WIDTH-1:0] timer_axil_awaddr, timer_axil_araddr;
    wire [DATA_WIDTH-1:0] timer_axil_wdata,  timer_axil_rdata;
    wire [STRB_WIDTH-1:0] timer_axil_wstrb;
    wire [1:0]            timer_axil_bresp,  timer_axil_rresp;
    wire                  timer_axil_awvalid, timer_axil_awready, timer_axil_wvalid, timer_axil_wready;
    wire                  timer_axil_bvalid,  timer_axil_bready,  timer_axil_arvalid, timer_axil_arready;
    wire                  timer_axil_rvalid,  timer_axil_rready;

    axi4_to_axil_lite #(.DATA_WIDTH(32), .ADDR_WIDTH(32), .ID_WIDTH(ID_WIDTH))
    u_bridge_timer (
        .clk(clk), .rst_n(rst_n),
        .s_axi_awid(m_awid[6]), .s_axi_awaddr(m_awaddr[6]), .s_axi_awlen(m_awlen[6]), .s_axi_awsize(m_awsize[6]),
        .s_axi_awburst(m_awburst[6]), .s_axi_awlock(m_awlock[6]), .s_axi_awcache(m_awcache[6]), .s_axi_awprot(m_awprot[6]),
        .s_axi_awqos(m_awqos[6]), .s_axi_awregion(4'd0), .s_axi_awuser(m_awuser[6]), .s_axi_awvalid(m_awvalid[6]), .s_axi_awready(m_awready[6]),
        .s_axi_wdata(m_wdata[6]), .s_axi_wstrb(m_wstrb[6]), .s_axi_wlast(m_wlast[6]), .s_axi_wuser(m_wuser[6]), .s_axi_wvalid(m_wvalid[6]), .s_axi_wready(m_wready[6]),
        .s_axi_bid(m_bid[6]), .s_axi_bresp(m_bresp[6]), .s_axi_buser(m_buser[6]), .s_axi_bvalid(m_bvalid[6]), .s_axi_bready(m_bready[6]),
        .s_axi_arid(m_arid[6]), .s_axi_araddr(m_araddr[6]), .s_axi_arlen(m_arlen[6]), .s_axi_arsize(m_arsize[6]),
        .s_axi_arburst(m_arburst[6]), .s_axi_arlock(m_arlock[6]), .s_axi_arcache(m_arcache[6]), .s_axi_arprot(m_arprot[6]),
        .s_axi_arqos(m_arqos[6]), .s_axi_arregion(4'd0), .s_axi_aruser(m_aruser[6]), .s_axi_arvalid(m_arvalid[6]), .s_axi_arready(m_arready[6]),
        .s_axi_rid(m_rid[6]), .s_axi_rdata(m_rdata[6]), .s_axi_rresp(m_rresp[6]), .s_axi_rlast(m_rlast[6]), .s_axi_ruser(m_ruser[6]), .s_axi_rvalid(m_rvalid[6]), .s_axi_rready(m_rready[6]),
        .m_axil_awaddr(timer_axil_awaddr), .m_axil_awvalid(timer_axil_awvalid), .m_axil_awready(timer_axil_awready),
        .m_axil_wdata(timer_axil_wdata), .m_axil_wstrb(timer_axil_wstrb), .m_axil_wvalid(timer_axil_wvalid), .m_axil_wready(timer_axil_wready),
        .m_axil_bresp(timer_axil_bresp), .m_axil_bvalid(timer_axil_bvalid), .m_axil_bready(timer_axil_bready),
        .m_axil_araddr(timer_axil_araddr), .m_axil_arvalid(timer_axil_arvalid), .m_axil_arready(timer_axil_arready),
        .m_axil_rdata(timer_axil_rdata), .m_axil_rresp(timer_axil_rresp), .m_axil_rvalid(timer_axil_rvalid), .m_axil_rready(timer_axil_rready)
    );

    timer u_timer (
        .clk(clk), .rst_n(rst_n),
        .s_axi_awaddr(timer_axil_awaddr), .s_axi_awvalid(timer_axil_awvalid), .s_axi_awready(timer_axil_awready),
        .s_axi_wdata(timer_axil_wdata), .s_axi_wstrb(timer_axil_wstrb), .s_axi_wvalid(timer_axil_wvalid), .s_axi_wready(timer_axil_wready),
        .s_axi_bresp(timer_axil_bresp), .s_axi_bvalid(timer_axil_bvalid), .s_axi_bready(timer_axil_bready),
        .s_axi_araddr(timer_axil_araddr), .s_axi_arvalid(timer_axil_arvalid), .s_axi_arready(timer_axil_arready),
        .s_axi_rdata(timer_axil_rdata), .s_axi_rresp(timer_axil_rresp), .s_axi_rvalid(timer_axil_rvalid), .s_axi_rready(timer_axil_rready),
        .sample_tick(sample_tick), .irq_timer(irq_timer)
    );

    // --- M07: GPIO Controller (0x4000_A000) ---
    wire [ADDR_WIDTH-1:0] gpio_axil_awaddr, gpio_axil_araddr;
    wire [DATA_WIDTH-1:0] gpio_axil_wdata,  gpio_axil_rdata;
    wire [STRB_WIDTH-1:0] gpio_axil_wstrb;
    wire [1:0]            gpio_axil_bresp,  gpio_axil_rresp;
    wire                  gpio_axil_awvalid, gpio_axil_awready, gpio_axil_wvalid, gpio_axil_wready;
    wire                  gpio_axil_bvalid,  gpio_axil_bready,  gpio_axil_arvalid, gpio_axil_arready;
    wire                  gpio_axil_rvalid,  gpio_axil_rready;

    axi4_to_axil_lite #(.DATA_WIDTH(32), .ADDR_WIDTH(32), .ID_WIDTH(ID_WIDTH))
    u_bridge_gpio (
        .clk(clk), .rst_n(rst_n),
        .s_axi_awid(m_awid[7]), .s_axi_awaddr(m_awaddr[7]), .s_axi_awlen(m_awlen[7]), .s_axi_awsize(m_awsize[7]),
        .s_axi_awburst(m_awburst[7]), .s_axi_awlock(m_awlock[7]), .s_axi_awcache(m_awcache[7]), .s_axi_awprot(m_awprot[7]),
        .s_axi_awqos(m_awqos[7]), .s_axi_awregion(4'd0), .s_axi_awuser(m_awuser[7]), .s_axi_awvalid(m_awvalid[7]), .s_axi_awready(m_awready[7]),
        .s_axi_wdata(m_wdata[7]), .s_axi_wstrb(m_wstrb[7]), .s_axi_wlast(m_wlast[7]), .s_axi_wuser(m_wuser[7]), .s_axi_wvalid(m_wvalid[7]), .s_axi_wready(m_wready[7]),
        .s_axi_bid(m_bid[7]), .s_axi_bresp(m_bresp[7]), .s_axi_buser(m_buser[7]), .s_axi_bvalid(m_bvalid[7]), .s_axi_bready(m_bready[7]),
        .s_axi_arid(m_arid[7]), .s_axi_araddr(m_araddr[7]), .s_axi_arlen(m_arlen[7]), .s_axi_arsize(m_arsize[7]),
        .s_axi_arburst(m_arburst[7]), .s_axi_arlock(m_arlock[7]), .s_axi_arcache(m_arcache[7]), .s_axi_arprot(m_arprot[7]),
        .s_axi_arqos(m_arqos[7]), .s_axi_arregion(4'd0), .s_axi_aruser(m_aruser[7]), .s_axi_arvalid(m_arvalid[7]), .s_axi_arready(m_arready[7]),
        .s_axi_rid(m_rid[7]), .s_axi_rdata(m_rdata[7]), .s_axi_rresp(m_rresp[7]), .s_axi_rlast(m_rlast[7]), .s_axi_ruser(m_ruser[7]), .s_axi_rvalid(m_rvalid[7]), .s_axi_rready(m_rready[7]),
        .m_axil_awaddr(gpio_axil_awaddr), .m_axil_awvalid(gpio_axil_awvalid), .m_axil_awready(gpio_axil_awready),
        .m_axil_wdata(gpio_axil_wdata), .m_axil_wstrb(gpio_axil_wstrb), .m_axil_wvalid(gpio_axil_wvalid), .m_axil_wready(gpio_axil_wready),
        .m_axil_bresp(gpio_axil_bresp), .m_axil_bvalid(gpio_axil_bvalid), .m_axil_bready(gpio_axil_bready),
        .m_axil_araddr(gpio_axil_araddr), .m_axil_arvalid(gpio_axil_arvalid), .m_axil_arready(gpio_axil_arready),
        .m_axil_rdata(gpio_axil_rdata), .m_axil_rresp(gpio_axil_rresp), .m_axil_rvalid(gpio_axil_rvalid), .m_axil_rready(gpio_axil_rready)
    );

    gpio u_gpio (
        .clk(clk), .rst_n(rst_n),
        .gpio_in(gpio_in), .gpio_out(gpio_out),
        .s_axi_awaddr(gpio_axil_awaddr), .s_axi_awvalid(gpio_axil_awvalid), .s_axi_awready(gpio_axil_awready),
        .s_axi_wdata(gpio_axil_wdata), .s_axi_wstrb(gpio_axil_wstrb), .s_axi_wvalid(gpio_axil_wvalid), .s_axi_wready(gpio_axil_wready),
        .s_axi_bresp(gpio_axil_bresp), .s_axi_bvalid(gpio_axil_bvalid), .s_axi_bready(gpio_axil_bready),
        .s_axi_araddr(gpio_axil_araddr), .s_axi_arvalid(gpio_axil_arvalid), .s_axi_arready(gpio_axil_arready),
        .s_axi_rdata(gpio_axil_rdata), .s_axi_rresp(gpio_axil_rresp), .s_axi_rvalid(gpio_axil_rvalid), .s_axi_rready(gpio_axil_rready),
        .irq_gpio(irq_gpio)
    );

    // --- M08: SPI Master Controller (0x4000_C000) ---
    wire [ADDR_WIDTH-1:0] spi_axil_awaddr, spi_axil_araddr;
    wire [DATA_WIDTH-1:0] spi_axil_wdata,  spi_axil_rdata;
    wire [STRB_WIDTH-1:0] spi_axil_wstrb;
    wire [1:0]            spi_axil_bresp,  spi_axil_rresp;
    wire                  spi_axil_awvalid, spi_axil_awready, spi_axil_wvalid, spi_axil_wready;
    wire                  spi_axil_bvalid,  spi_axil_bready,  spi_axil_arvalid, spi_axil_arready;
    wire                  spi_axil_rvalid,  spi_axil_rready;

    axi4_to_axil_lite #(.DATA_WIDTH(32), .ADDR_WIDTH(32), .ID_WIDTH(ID_WIDTH))
    u_bridge_spi (
        .clk(clk), .rst_n(rst_n),
        .s_axi_awid(m_awid[8]), .s_axi_awaddr(m_awaddr[8]), .s_axi_awlen(m_awlen[8]), .s_axi_awsize(m_awsize[8]),
        .s_axi_awburst(m_awburst[8]), .s_axi_awlock(m_awlock[8]), .s_axi_awcache(m_awcache[8]), .s_axi_awprot(m_awprot[8]),
        .s_axi_awqos(m_awqos[8]), .s_axi_awregion(4'd0), .s_axi_awuser(m_awuser[8]), .s_axi_awvalid(m_awvalid[8]), .s_axi_awready(m_awready[8]),
        .s_axi_wdata(m_wdata[8]), .s_axi_wstrb(m_wstrb[8]), .s_axi_wlast(m_wlast[8]), .s_axi_wuser(m_wuser[8]), .s_axi_wvalid(m_wvalid[8]), .s_axi_wready(m_wready[8]),
        .s_axi_bid(m_bid[8]), .s_axi_bresp(m_bresp[8]), .s_axi_buser(m_buser[8]), .s_axi_bvalid(m_bvalid[8]), .s_axi_bready(m_bready[8]),
        .s_axi_arid(m_arid[8]), .s_axi_araddr(m_araddr[8]), .s_axi_arlen(m_arlen[8]), .s_axi_arsize(m_arsize[8]),
        .s_axi_arburst(m_arburst[8]), .s_axi_arlock(m_arlock[8]), .s_axi_arcache(m_arcache[8]), .s_axi_arprot(m_arprot[8]),
        .s_axi_arqos(m_arqos[8]), .s_axi_arregion(4'd0), .s_axi_aruser(m_aruser[8]), .s_axi_arvalid(m_arvalid[8]), .s_axi_arready(m_arready[8]),
        .s_axi_rid(m_rid[8]), .s_axi_rdata(m_rdata[8]), .s_axi_rresp(m_rresp[8]), .s_axi_rlast(m_rlast[8]), .s_axi_ruser(m_ruser[8]), .s_axi_rvalid(m_rvalid[8]), .s_axi_rready(m_rready[8]),
        .m_axil_awaddr(spi_axil_awaddr), .m_axil_awvalid(spi_axil_awvalid), .m_axil_awready(spi_axil_awready),
        .m_axil_wdata(spi_axil_wdata), .m_axil_wstrb(spi_axil_wstrb), .m_axil_wvalid(spi_axil_wvalid), .m_axil_wready(spi_axil_wready),
        .m_axil_bresp(spi_axil_bresp), .m_axil_bvalid(spi_axil_bvalid), .m_axil_bready(spi_axil_bready),
        .m_axil_araddr(spi_axil_araddr), .m_axil_arvalid(spi_axil_arvalid), .m_axil_arready(spi_axil_arready),
        .m_axil_rdata(spi_axil_rdata), .m_axil_rresp(spi_axil_rresp), .m_axil_rvalid(spi_axil_rvalid), .m_axil_rready(spi_axil_rready)
    );

    spi_controller u_spi (
        .clk(clk), .rst_n(rst_n),
        .sample_tick(sample_tick),
        .adc_spi_sck(adc_spi_sck), .adc_spi_mosi(adc_spi_mosi), .adc_spi_miso(adc_spi_miso), .adc_spi_cs_n(adc_spi_cs_n),
        .sample_ready(spi_sample_ready), .sample_data(spi_sample_data),
        .s_axi_awaddr(spi_axil_awaddr), .s_axi_awvalid(spi_axil_awvalid), .s_axi_awready(spi_axil_awready),
        .s_axi_wdata(spi_axil_wdata), .s_axi_wstrb(spi_axil_wstrb), .s_axi_wvalid(spi_axil_wvalid), .s_axi_wready(spi_axil_wready),
        .s_axi_bresp(spi_axil_bresp), .s_axi_bvalid(spi_axil_bvalid), .s_axi_bready(spi_axil_bready),
        .s_axi_araddr(spi_axil_araddr), .s_axi_arvalid(spi_axil_arvalid), .s_axi_arready(spi_axil_arready),
        .s_axi_rdata(spi_axil_rdata), .s_axi_rresp(spi_axil_rresp), .s_axi_rvalid(spi_axil_rvalid), .s_axi_rready(spi_axil_rready),
        .irq_spi(irq_spi)
    );

    // --- M09: Watchdog Monitor (0x4000_E000) ---
    wire [ADDR_WIDTH-1:0] wdt_axil_awaddr, wdt_axil_araddr;
    wire [DATA_WIDTH-1:0] wdt_axil_wdata,  wdt_axil_rdata;
    wire [STRB_WIDTH-1:0] wdt_axil_wstrb;
    wire [1:0]            wdt_axil_bresp,  wdt_axil_rresp;
    wire                  wdt_axil_awvalid, wdt_axil_awready, wdt_axil_wvalid, wdt_axil_wready;
    wire                  wdt_axil_bvalid,  wdt_axil_bready,  wdt_axil_arvalid, wdt_axil_arready;
    wire                  wdt_axil_rvalid,  wdt_axil_rready;

    axi4_to_axil_lite #(.DATA_WIDTH(32), .ADDR_WIDTH(32), .ID_WIDTH(ID_WIDTH))
    u_bridge_wdt (
        .clk(clk), .rst_n(rst_n),
        .s_axi_awid(m_awid[9]), .s_axi_awaddr(m_awaddr[9]), .s_axi_awlen(m_awlen[9]), .s_axi_awsize(m_awsize[9]),
        .s_axi_awburst(m_awburst[9]), .s_axi_awlock(m_awlock[9]), .s_axi_awcache(m_awcache[9]), .s_axi_awprot(m_awprot[9]),
        .s_axi_awqos(m_awqos[9]), .s_axi_awregion(4'd0), .s_axi_awuser(m_awuser[9]), .s_axi_awvalid(m_awvalid[9]), .s_axi_awready(m_awready[9]),
        .s_axi_wdata(m_wdata[9]), .s_axi_wstrb(m_wstrb[9]), .s_axi_wlast(m_wlast[9]), .s_axi_wuser(m_wuser[9]), .s_axi_wvalid(m_wvalid[9]), .s_axi_wready(m_wready[9]),
        .s_axi_bid(m_bid[9]), .s_axi_bresp(m_bresp[9]), .s_axi_buser(m_buser[9]), .s_axi_bvalid(m_bvalid[9]), .s_axi_bready(m_bready[9]),
        .s_axi_arid(m_arid[9]), .s_axi_araddr(m_araddr[9]), .s_axi_arlen(m_arlen[9]), .s_axi_arsize(m_arsize[9]),
        .s_axi_arburst(m_arburst[9]), .s_axi_arlock(m_arlock[9]), .s_axi_arcache(m_arcache[9]), .s_axi_arprot(m_arprot[9]),
        .s_axi_arqos(m_arqos[9]), .s_axi_arregion(4'd0), .s_axi_aruser(m_aruser[9]), .s_axi_arvalid(m_arvalid[9]), .s_axi_arready(m_arready[9]),
        .s_axi_rid(m_rid[9]), .s_axi_rdata(m_rdata[9]), .s_axi_rresp(m_rresp[9]), .s_axi_rlast(m_rlast[9]), .s_axi_ruser(m_ruser[9]), .s_axi_rvalid(m_rvalid[9]), .s_axi_rready(m_rready[9]),
        .m_axil_awaddr(wdt_axil_awaddr), .m_axil_awvalid(wdt_axil_awvalid), .m_axil_awready(wdt_axil_awready),
        .m_axil_wdata(wdt_axil_wdata), .m_axil_wstrb(wdt_axil_wstrb), .m_axil_wvalid(wdt_axil_wvalid), .m_axil_wready(wdt_axil_wready),
        .m_axil_bresp(wdt_axil_bresp), .m_axil_bvalid(wdt_axil_bvalid), .m_axil_bready(wdt_axil_bready),
        .m_axil_araddr(wdt_axil_araddr), .m_axil_arvalid(wdt_axil_arvalid), .m_axil_arready(wdt_axil_arready),
        .m_axil_rdata(wdt_axil_rdata), .m_axil_rresp(wdt_axil_rresp), .m_axil_rvalid(wdt_axil_rvalid), .m_axil_rready(wdt_axil_rready)
    );

    watchdog u_wdt (
        .clk(clk), .rst_n(rst_n),
        .pipeline_alive({irq_vga_frame, fir_sample_valid_out, sample_tick, uart_irq}),
        .nmi_prewarn(wdt_nmi_prewarn), .wdt_reset(wdt_reset), .wdt_reset_out(wdt_reset_out),
        .s_axi_awaddr(wdt_axil_awaddr), .s_axi_awvalid(wdt_axil_awvalid), .s_axi_awready(wdt_axil_awready),
        .s_axi_wdata(wdt_axil_wdata), .s_axi_wstrb(wdt_axil_wstrb), .s_axi_wvalid(wdt_axil_wvalid), .s_axi_wready(wdt_axil_wready),
        .s_axi_bresp(wdt_axil_bresp), .s_axi_bvalid(wdt_axil_bvalid), .s_axi_bready(wdt_axil_bready),
        .s_axi_araddr(wdt_axil_araddr), .s_axi_arvalid(wdt_axil_arvalid), .s_axi_arready(wdt_axil_arready),
        .s_axi_rdata(wdt_axil_rdata), .s_axi_rresp(wdt_axil_rresp), .s_axi_rvalid(wdt_axil_rvalid), .s_axi_rready(wdt_axil_rready)
    );

    // --- M10: DMA Controller (0x4001_0000) ---
    wire [ADDR_WIDTH-1:0] dma_axil_awaddr, dma_axil_araddr;
    wire [DATA_WIDTH-1:0] dma_axil_wdata,  dma_axil_rdata;
    wire [STRB_WIDTH-1:0] dma_axil_wstrb;
    wire [1:0]            dma_axil_bresp,  dma_axil_rresp;
    wire                  dma_axil_awvalid, dma_axil_awready, dma_axil_wvalid, dma_axil_wready;
    wire                  dma_axil_bvalid,  dma_axil_bready,  dma_axil_arvalid, dma_axil_arready;
    wire                  dma_axil_rvalid,  dma_axil_rready;

    axi4_to_axil_lite #(.DATA_WIDTH(32), .ADDR_WIDTH(32), .ID_WIDTH(ID_WIDTH))
    u_bridge_dma (
        .clk(clk), .rst_n(rst_n),
        .s_axi_awid(m_awid[10]), .s_axi_awaddr(m_awaddr[10]), .s_axi_awlen(m_awlen[10]), .s_axi_awsize(m_awsize[10]),
        .s_axi_awburst(m_awburst[10]), .s_axi_awlock(m_awlock[10]), .s_axi_awcache(m_awcache[10]), .s_axi_awprot(m_awprot[10]),
        .s_axi_awqos(m_awqos[10]), .s_axi_awregion(4'd0), .s_axi_awuser(m_awuser[10]), .s_axi_awvalid(m_awvalid[10]), .s_axi_awready(m_awready[10]),
        .s_axi_wdata(m_wdata[10]), .s_axi_wstrb(m_wstrb[10]), .s_axi_wlast(m_wlast[10]), .s_axi_wuser(m_wuser[10]), .s_axi_wvalid(m_wvalid[10]), .s_axi_wready(m_wready[10]),
        .s_axi_bid(m_bid[10]), .s_axi_bresp(m_bresp[10]), .s_axi_buser(m_buser[10]), .s_axi_bvalid(m_bvalid[10]), .s_axi_bready(m_bready[10]),
        .s_axi_arid(m_arid[10]), .s_axi_araddr(m_araddr[10]), .s_axi_arlen(m_arlen[10]), .s_axi_arsize(m_arsize[10]),
        .s_axi_arburst(m_arburst[10]), .s_axi_arlock(m_arlock[10]), .s_axi_arcache(m_arcache[10]), .s_axi_arprot(m_arprot[10]),
        .s_axi_arqos(m_arqos[10]), .s_axi_arregion(4'd0), .s_axi_aruser(m_aruser[10]), .s_axi_arvalid(m_arvalid[10]), .s_axi_arready(m_arready[10]),
        .s_axi_rid(m_rid[10]), .s_axi_rdata(m_rdata[10]), .s_axi_rresp(m_rresp[10]), .s_axi_rlast(m_rlast[10]), .s_axi_ruser(m_ruser[10]), .s_axi_rvalid(m_rvalid[10]), .s_axi_rready(m_rready[10]),
        .m_axil_awaddr(dma_axil_awaddr), .m_axil_awvalid(dma_axil_awvalid), .m_axil_awready(dma_axil_awready),
        .m_axil_wdata(dma_axil_wdata), .m_axil_wstrb(dma_axil_wstrb), .m_axil_wvalid(dma_axil_wvalid), .m_axil_wready(dma_axil_wready),
        .m_axil_bresp(dma_axil_bresp), .m_axil_bvalid(dma_axil_bvalid), .m_axil_bready(dma_axil_bready),
        .m_axil_araddr(dma_axil_araddr), .m_axil_arvalid(dma_axil_arvalid), .m_axil_arready(dma_axil_arready),
        .m_axil_rdata(dma_axil_rdata), .m_axil_rresp(dma_axil_rresp), .m_axil_rvalid(dma_axil_rvalid), .m_axil_rready(dma_axil_rready)
    );

    dma_controller u_dma (
        .clk(clk), .rst_n(rst_n),
        .sample_tick(sample_tick),
        .spi_sample_ready(spi_sample_ready),
        .spi_sample_data(spi_sample_data),
        .adc_spi_sck(), .adc_spi_mosi(), .adc_spi_miso(1'b0), .adc_spi_cs_n(),
        .fir_sample_in(fir_sample_in), .fir_sample_valid_in(fir_sample_valid_in),
        .fir_sample_out(fir_sample_out), .fir_sample_valid_out(fir_sample_valid_out),
        .sbuf_waddr(sbuf_waddr), .sbuf_wdata(sbuf_wdata), .sbuf_we(sbuf_we),
        .buf_swap_req(buf_swap_req),
        .s_axi_awaddr(dma_axil_awaddr), .s_axi_awvalid(dma_axil_awvalid), .s_axi_awready(dma_axil_awready),
        .s_axi_wdata(dma_axil_wdata), .s_axi_wstrb(dma_axil_wstrb), .s_axi_wvalid(dma_axil_wvalid), .s_axi_wready(dma_axil_wready),
        .s_axi_bresp(dma_axil_bresp), .s_axi_bvalid(dma_axil_bvalid), .s_axi_bready(dma_axil_bready),
        .s_axi_araddr(dma_axil_araddr), .s_axi_arvalid(dma_axil_arvalid), .s_axi_arready(dma_axil_arready),
        .s_axi_rdata(dma_axil_rdata), .s_axi_rresp(dma_axil_rresp), .s_axi_rvalid(dma_axil_rvalid), .s_axi_rready(dma_axil_rready),
        .irq_dma_done(irq_dma_done), .irq_dma_err(irq_dma_err)
    );

    // --- M11: FIR Filter Engine (0x4001_2000) ---
    wire [ADDR_WIDTH-1:0] fir_axil_awaddr, fir_axil_araddr;
    wire [DATA_WIDTH-1:0] fir_axil_wdata,  fir_axil_rdata;
    wire [STRB_WIDTH-1:0] fir_axil_wstrb;
    wire [1:0]            fir_axil_bresp,  fir_axil_rresp;
    wire                  fir_axil_awvalid, fir_axil_awready, fir_axil_wvalid, fir_axil_wready;
    wire                  fir_axil_bvalid,  fir_axil_bready,  fir_axil_arvalid, fir_axil_arready;
    wire                  fir_axil_rvalid,  fir_axil_rready;

    axi4_to_axil_lite #(.DATA_WIDTH(32), .ADDR_WIDTH(32), .ID_WIDTH(ID_WIDTH))
    u_bridge_fir (
        .clk(clk), .rst_n(rst_n),
        .s_axi_awid(m_awid[11]), .s_axi_awaddr(m_awaddr[11]), .s_axi_awlen(m_awlen[11]), .s_axi_awsize(m_awsize[11]),
        .s_axi_awburst(m_awburst[11]), .s_axi_awlock(m_awlock[11]), .s_axi_awcache(m_awcache[11]), .s_axi_awprot(m_awprot[11]),
        .s_axi_awqos(m_awqos[11]), .s_axi_awregion(4'd0), .s_axi_awuser(m_awuser[11]), .s_axi_awvalid(m_awvalid[11]), .s_axi_awready(m_awready[11]),
        .s_axi_wdata(m_wdata[11]), .s_axi_wstrb(m_wstrb[11]), .s_axi_wlast(m_wlast[11]), .s_axi_wuser(m_wuser[11]), .s_axi_wvalid(m_wvalid[11]), .s_axi_wready(m_wready[11]),
        .s_axi_bid(m_bid[11]), .s_axi_bresp(m_bresp[11]), .s_axi_buser(m_buser[11]), .s_axi_bvalid(m_bvalid[11]), .s_axi_bready(m_bready[11]),
        .s_axi_arid(m_arid[11]), .s_axi_araddr(m_araddr[11]), .s_axi_arlen(m_arlen[11]), .s_axi_arsize(m_arsize[11]),
        .s_axi_arburst(m_arburst[11]), .s_axi_arlock(m_arlock[11]), .s_axi_arcache(m_arcache[11]), .s_axi_arprot(m_arprot[11]),
        .s_axi_arqos(m_arqos[11]), .s_axi_arregion(4'd0), .s_axi_aruser(m_aruser[11]), .s_axi_arvalid(m_arvalid[11]), .s_axi_arready(m_arready[11]),
        .s_axi_rid(m_rid[11]), .s_axi_rdata(m_rdata[11]), .s_axi_rresp(m_rresp[11]), .s_axi_rlast(m_rlast[11]), .s_axi_ruser(m_ruser[11]), .s_axi_rvalid(m_rvalid[11]), .s_axi_rready(m_rready[11]),
        .m_axil_awaddr(fir_axil_awaddr), .m_axil_awvalid(fir_axil_awvalid), .m_axil_awready(fir_axil_awready),
        .m_axil_wdata(fir_axil_wdata), .m_axil_wstrb(fir_axil_wstrb), .m_axil_wvalid(fir_axil_wvalid), .m_axil_wready(fir_axil_wready),
        .m_axil_bresp(fir_axil_bresp), .m_axil_bvalid(fir_axil_bvalid), .m_axil_bready(fir_axil_bready),
        .m_axil_araddr(fir_axil_araddr), .m_axil_arvalid(fir_axil_arvalid), .m_axil_arready(fir_axil_arready),
        .m_axil_rdata(fir_axil_rdata), .m_axil_rresp(fir_axil_rresp), .m_axil_rvalid(fir_axil_rvalid), .m_axil_rready(fir_axil_rready)
    );

    fir_filter u_fir (
        .clk(clk), .rst_n(rst_n),
        .fir_sample_in(fir_sample_in), .fir_sample_valid_in(fir_sample_valid_in),
        .fir_sample_out(fir_sample_out), .fir_sample_valid_out(fir_sample_valid_out),
        .s_axi_awaddr(fir_axil_awaddr), .s_axi_awvalid(fir_axil_awvalid), .s_axi_awready(fir_axil_awready),
        .s_axi_wdata(fir_axil_wdata), .s_axi_wstrb(fir_axil_wstrb), .s_axi_wvalid(fir_axil_wvalid), .s_axi_wready(fir_axil_wready),
        .s_axi_bresp(fir_axil_bresp), .s_axi_bvalid(fir_axil_bvalid), .s_axi_bready(fir_axil_bready),
        .s_axi_araddr(fir_axil_araddr), .s_axi_arvalid(fir_axil_arvalid), .s_axi_arready(fir_axil_arready),
        .s_axi_rdata(fir_axil_rdata), .s_axi_rresp(fir_axil_rresp), .s_axi_rvalid(fir_axil_rvalid), .s_axi_rready(fir_axil_rready),
        .irq_fir(irq_fir)
    );

    // --- M12: VGA Oscilloscope Controller (0x4001_4000) ---
    wire [ADDR_WIDTH-1:0] vga_axil_awaddr, vga_axil_araddr;
    wire [DATA_WIDTH-1:0] vga_axil_wdata,  vga_axil_rdata;
    wire [STRB_WIDTH-1:0] vga_axil_wstrb;
    wire [1:0]            vga_axil_bresp,  vga_axil_rresp;
    wire                  vga_axil_awvalid, vga_axil_awready, vga_axil_wvalid, vga_axil_wready;
    wire                  vga_axil_bvalid,  vga_axil_bready,  vga_axil_arvalid, vga_axil_arready;
    wire                  vga_axil_rvalid,  vga_axil_rready;

    axi4_to_axil_lite #(.DATA_WIDTH(32), .ADDR_WIDTH(32), .ID_WIDTH(ID_WIDTH))
    u_bridge_vga (
        .clk(clk), .rst_n(rst_n),
        .s_axi_awid(m_awid[12]), .s_axi_awaddr(m_awaddr[12]), .s_axi_awlen(m_awlen[12]), .s_axi_awsize(m_awsize[12]),
        .s_axi_awburst(m_awburst[12]), .s_axi_awlock(m_awlock[12]), .s_axi_awcache(m_awcache[12]), .s_axi_awprot(m_awprot[12]),
        .s_axi_awqos(m_awqos[12]), .s_axi_awregion(4'd0), .s_axi_awuser(m_awuser[12]), .s_axi_awvalid(m_awvalid[12]), .s_axi_awready(m_awready[12]),
        .s_axi_wdata(m_wdata[12]), .s_axi_wstrb(m_wstrb[12]), .s_axi_wlast(m_wlast[12]), .s_axi_wuser(m_wuser[12]), .s_axi_wvalid(m_wvalid[12]), .s_axi_wready(m_wready[12]),
        .s_axi_bid(m_bid[12]), .s_axi_bresp(m_bresp[12]), .s_axi_buser(m_buser[12]), .s_axi_bvalid(m_bvalid[12]), .s_axi_bready(m_bready[12]),
        .s_axi_arid(m_arid[12]), .s_axi_araddr(m_araddr[12]), .s_axi_arlen(m_arlen[12]), .s_axi_arsize(m_arsize[12]),
        .s_axi_arburst(m_arburst[12]), .s_axi_arlock(m_arlock[12]), .s_axi_arcache(m_arcache[12]), .s_axi_arprot(m_arprot[12]),
        .s_axi_arqos(m_arqos[12]), .s_axi_arregion(4'd0), .s_axi_aruser(m_aruser[12]), .s_axi_arvalid(m_arvalid[12]), .s_axi_arready(m_arready[12]),
        .s_axi_rid(m_rid[12]), .s_axi_rdata(m_rdata[12]), .s_axi_rresp(m_rresp[12]), .s_axi_rlast(m_rlast[12]), .s_axi_ruser(m_ruser[12]), .s_axi_rvalid(m_rvalid[12]), .s_axi_rready(m_rready[12]),
        .m_axil_awaddr(vga_axil_awaddr), .m_axil_awvalid(vga_axil_awvalid), .m_axil_awready(vga_axil_awready),
        .m_axil_wdata(vga_axil_wdata), .m_axil_wstrb(vga_axil_wstrb), .m_axil_wvalid(vga_axil_wvalid), .m_axil_wready(vga_axil_wready),
        .m_axil_bresp(vga_axil_bresp), .m_axil_bvalid(vga_axil_bvalid), .m_axil_bready(vga_axil_bready),
        .m_axil_araddr(vga_axil_araddr), .m_axil_arvalid(vga_axil_arvalid), .m_axil_arready(vga_axil_arready),
        .m_axil_rdata(vga_axil_rdata), .m_axil_rresp(vga_axil_rresp), .m_axil_rvalid(vga_axil_rvalid), .m_axil_rready(vga_axil_rready)
    );

    vga_controller u_vga (
        .clk_sys(clk), .rst_sys_n(rst_n),
        .clk_vga(clk_vga), .rst_vga_n(rst_vga_n),
        .sbuf_raddr(sbuf_raddr), .sbuf_rdata(sbuf_rdata),
        .vga_vsync_pulse(vga_vsync_pulse),
        .vga_hsync(vga_hsync), .vga_vsync(vga_vsync),
        .vga_red(vga_red), .vga_green(vga_green), .vga_blue(vga_blue),
        .s_axi_awaddr(vga_axil_awaddr), .s_axi_awvalid(vga_axil_awvalid), .s_axi_awready(vga_axil_awready),
        .s_axi_wdata(vga_axil_wdata), .s_axi_wstrb(vga_axil_wstrb), .s_axi_wvalid(vga_axil_wvalid), .s_axi_wready(vga_axil_wready),
        .s_axi_bresp(vga_axil_bresp), .s_axi_bvalid(vga_axil_bvalid), .s_axi_bready(vga_axil_bready),
        .s_axi_araddr(vga_axil_araddr), .s_axi_arvalid(vga_axil_arvalid), .s_axi_arready(vga_axil_arready),
        .s_axi_rdata(vga_axil_rdata), .s_axi_rresp(vga_axil_rresp), .s_axi_rvalid(vga_axil_rvalid), .s_axi_rready(vga_axil_rready),
        .irq_vga_frame(irq_vga_frame)
    );

    // --- M13: Dual-Port Ping-Pong Sample Buffer (0x4001_6000) ---
    wire [ADDR_WIDTH-1:0] sbuf_axil_awaddr, sbuf_axil_araddr;
    wire [DATA_WIDTH-1:0] sbuf_axil_wdata,  sbuf_axil_rdata;
    wire [STRB_WIDTH-1:0] sbuf_axil_wstrb;
    wire [1:0]            sbuf_axil_bresp,  sbuf_axil_rresp;
    wire                  sbuf_axil_awvalid, sbuf_axil_awready, sbuf_axil_wvalid, sbuf_axil_wready;
    wire                  sbuf_axil_bvalid,  sbuf_axil_bready,  sbuf_axil_arvalid, sbuf_axil_arready;
    wire                  sbuf_axil_rvalid,  sbuf_axil_rready;

    axi4_to_axil_lite #(.DATA_WIDTH(32), .ADDR_WIDTH(32), .ID_WIDTH(ID_WIDTH))
    u_bridge_sbuf (
        .clk(clk), .rst_n(rst_n),
        .s_axi_awid(m_awid[13]), .s_axi_awaddr(m_awaddr[13]), .s_axi_awlen(m_awlen[13]), .s_axi_awsize(m_awsize[13]),
        .s_axi_awburst(m_awburst[13]), .s_axi_awlock(m_awlock[13]), .s_axi_awcache(m_awcache[13]), .s_axi_awprot(m_awprot[13]),
        .s_axi_awqos(m_awqos[13]), .s_axi_awregion(4'd0), .s_axi_awuser(m_awuser[13]), .s_axi_awvalid(m_awvalid[13]), .s_axi_awready(m_awready[13]),
        .s_axi_wdata(m_wdata[13]), .s_axi_wstrb(m_wstrb[13]), .s_axi_wlast(m_wlast[13]), .s_axi_wuser(m_wuser[13]), .s_axi_wvalid(m_wvalid[13]), .s_axi_wready(m_wready[13]),
        .s_axi_bid(m_bid[13]), .s_axi_bresp(m_bresp[13]), .s_axi_buser(m_buser[13]), .s_axi_bvalid(m_bvalid[13]), .s_axi_bready(m_bready[13]),
        .s_axi_arid(m_arid[13]), .s_axi_araddr(m_araddr[13]), .s_axi_arlen(m_arlen[13]), .s_axi_arsize(m_arsize[13]),
        .s_axi_arburst(m_arburst[13]), .s_axi_arlock(m_arlock[13]), .s_axi_arcache(m_arcache[13]), .s_axi_arprot(m_arprot[13]),
        .s_axi_arqos(m_arqos[13]), .s_axi_arregion(4'd0), .s_axi_aruser(m_aruser[13]), .s_axi_arvalid(m_arvalid[13]), .s_axi_arready(m_arready[13]),
        .s_axi_rid(m_rid[13]), .s_axi_rdata(m_rdata[13]), .s_axi_rresp(m_rresp[13]), .s_axi_rlast(m_rlast[13]), .s_axi_ruser(m_ruser[13]), .s_axi_rvalid(m_rvalid[13]), .s_axi_rready(m_rready[13]),
        .m_axil_awaddr(sbuf_axil_awaddr), .m_axil_awvalid(sbuf_axil_awvalid), .m_axil_awready(sbuf_axil_awready),
        .m_axil_wdata(sbuf_axil_wdata), .m_axil_wstrb(sbuf_axil_wstrb), .m_axil_wvalid(sbuf_axil_wvalid), .m_axil_wready(sbuf_axil_wready),
        .m_axil_bresp(sbuf_axil_bresp), .m_axil_bvalid(sbuf_axil_bvalid), .m_axil_bready(sbuf_axil_bready),
        .m_axil_araddr(sbuf_axil_araddr), .m_axil_arvalid(sbuf_axil_arvalid), .m_axil_arready(sbuf_axil_arready),
        .m_axil_rdata(sbuf_axil_rdata), .m_axil_rresp(sbuf_axil_rresp), .m_axil_rvalid(sbuf_axil_rvalid), .m_axil_rready(sbuf_axil_rready)
    );

    sample_buffer u_sbuf (
        .clk_sys(clk), .rst_sys_n(rst_n),
        .sbuf_waddr(sbuf_waddr), .sbuf_wdata(sbuf_wdata), .sbuf_we(sbuf_we),
        .buf_swap_req(buf_swap_req), .vga_vsync_pulse(vga_vsync_pulse),
        .active_wr_buf(active_wr_buf), .active_rd_buf(active_rd_buf),
        .clk_vga(clk_vga), .rst_vga_n(rst_vga_n),
        .sbuf_raddr(sbuf_raddr), .sbuf_rdata(sbuf_rdata),
        .s_axi_awaddr(sbuf_axil_awaddr), .s_axi_awvalid(sbuf_axil_awvalid), .s_axi_awready(sbuf_axil_awready),
        .s_axi_wdata(sbuf_axil_wdata), .s_axi_wstrb(sbuf_axil_wstrb), .s_axi_wvalid(sbuf_axil_wvalid), .s_axi_wready(sbuf_axil_wready),
        .s_axi_bresp(sbuf_axil_bresp), .s_axi_bvalid(sbuf_axil_bvalid), .s_axi_bready(sbuf_axil_bready),
        .s_axi_araddr(sbuf_axil_araddr), .s_axi_arvalid(sbuf_axil_arvalid), .s_axi_arready(sbuf_axil_arready),
        .s_axi_rdata(sbuf_axil_rdata), .s_axi_rresp(sbuf_axil_rresp), .s_axi_rvalid(sbuf_axil_rvalid), .s_axi_rready(sbuf_axil_rready)
    );

endmodule

`resetall
