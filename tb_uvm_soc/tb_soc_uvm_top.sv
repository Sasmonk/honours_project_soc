// =============================================================================
// Module       : tb_soc_uvm_top.sv
// Description  : Static Top-Level Module for Complete RISC-V SoC UVM Testbench
// =============================================================================
`timescale 1ns/1ps

module tb_soc_uvm_top;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import el2_pkg::*;
  import soc_uvm_pkg::*;

  // ---------------------------------------------------------------------------
  // Parameters & Timing Constants
  // ---------------------------------------------------------------------------
  localparam DATA_WIDTH         = 32;
  localparam ADDR_WIDTH         = 32;
  localparam ID_WIDTH           = 8;

  localparam IMEM_BASE_ADDR     = 32'h1000_0000;
  localparam DMEM_BASE_ADDR     = 32'h1002_0000;
  localparam UART_BASE_ADDR     = 32'h4000_6000;
  localparam TIMER_BASE_ADDR    = 32'h4000_8000;
  localparam GPIO_BASE_ADDR     = 32'h4000_A000;
  localparam SPI_BASE_ADDR      = 32'h4000_C000;
  localparam WDT_BASE_ADDR      = 32'h4000_E000;
  localparam DMA_BASE_ADDR      = 32'h4001_0000;
  localparam FIR_BASE_ADDR      = 32'h4001_2000;
  localparam VGA_BASE_ADDR      = 32'h4001_4000;
  localparam SBUF_BASE_ADDR     = 32'h4001_6000;

  localparam CLK_SYS_PERIOD_NS  = 10; // 100 MHz System Clock
  localparam CLK_VGA_PERIOD_NS  = 40; // 25.175 MHz Pixel Clock

  // ---------------------------------------------------------------------------
  // Clocks & Resets
  // ---------------------------------------------------------------------------
  logic clk;
  logic clk_vga;
  logic rst_n;

  initial begin
    clk = 1'b0;
    forever #(CLK_SYS_PERIOD_NS / 2) clk = ~clk;
  end

  initial begin
    clk_vga = 1'b0;
    forever #(CLK_VGA_PERIOD_NS / 2) clk_vga = ~clk_vga;
  end

  // ---------------------------------------------------------------------------
  // Physical SystemVerilog Interfaces (The Bridge to UVM VIPs)
  // ---------------------------------------------------------------------------
  uart_serial_if  uart_if  (clk, rst_n);
  spi_adc_if      spi_if   (clk, rst_n);
  gpio_pin_if     gpio_if  (clk, rst_n);
  vga_pixel_if    vga_if   (clk_vga, rst_n);
  timer_pulse_if  timer_if (clk, rst_n);
  wdt_safety_if   wdt_if   (clk, rst_n);

  // ---------------------------------------------------------------------------
  // DUT Boundary Signals
  // ---------------------------------------------------------------------------
  logic [31:1] rst_vec;
  logic        nmi_int;
  logic [31:1] nmi_vec;
  logic [31:1] jtag_id;

  wire         uart_tx;
  wire         uart_irq;

  wire [7:0]   gpio_out;

  wire         adc_spi_sck;
  wire         adc_spi_mosi;
  wire         adc_spi_cs_n;

  wire         vga_hsync;
  wire         vga_vsync;
  wire [3:0]   vga_red;
  wire [3:0]   vga_green;
  wire [3:0]   vga_blue;

  wire         wdt_reset_out;

  logic [23:0] ext_irq;
  logic        timer_int;

  wire [31:0]  trace_rv_i_insn_ip;
  wire [31:0]  trace_rv_i_address_ip;
  wire         trace_rv_i_valid_ip;
  wire         trace_rv_i_exception_ip;
  wire [4:0]   trace_rv_i_ecause_ip;
  wire         trace_rv_i_interrupt_ip;
  wire [31:0]  trace_rv_i_tval_ip;

  wire         o_cpu_halt_status;
  wire         o_cpu_halt_ack;
  wire         o_debug_mode_status;

  // ---------------------------------------------------------------------------
  // Connect Physical Interfaces to DUT
  // ---------------------------------------------------------------------------
  // UART
  assign uart_if.uart_tx  = uart_tx;
  assign uart_if.uart_irq = uart_irq;

  // SPI ADC
  assign spi_if.adc_spi_sck  = adc_spi_sck;
  assign spi_if.adc_spi_mosi = adc_spi_mosi;
  assign spi_if.adc_spi_cs_n = adc_spi_cs_n;

  // GPIO
  assign gpio_if.gpio_out    = gpio_out;

  // VGA Display
  assign vga_if.vga_hsync    = vga_hsync;
  assign vga_if.vga_vsync    = vga_vsync;
  assign vga_if.vga_red      = vga_red;
  assign vga_if.vga_green    = vga_green;
  assign vga_if.vga_blue     = vga_blue;

  // Safety & Watchdog
  assign wdt_if.wdt_reset_out = wdt_reset_out;

  // ---------------------------------------------------------------------------
  // Static DUT Instantiation: Complete RISC-V SoC Top Level
  // ---------------------------------------------------------------------------
  soc_top #(
    .DATA_WIDTH          (DATA_WIDTH),
    .ADDR_WIDTH          (ADDR_WIDTH),
    .ID_WIDTH            (ID_WIDTH),
    .UART_BASE_ADDR      (UART_BASE_ADDR),
    .IMEM_BASE_ADDR      (IMEM_BASE_ADDR),
    .DMEM_BASE_ADDR      (DMEM_BASE_ADDR),
    .TIMER_BASE_ADDR     (TIMER_BASE_ADDR),
    .GPIO_BASE_ADDR      (GPIO_BASE_ADDR),
    .SPI_BASE_ADDR       (SPI_BASE_ADDR),
    .WDT_BASE_ADDR       (WDT_BASE_ADDR),
    .DMA_BASE_ADDR       (DMA_BASE_ADDR),
    .FIR_BASE_ADDR       (FIR_BASE_ADDR),
    .VGA_BASE_ADDR       (VGA_BASE_ADDR),
    .SBUF_BASE_ADDR      (SBUF_BASE_ADDR)
  ) dut (
    .clk                 (clk),
    .rst_n               (rst_n),
    .clk_vga             (clk_vga),

    .rst_vec             (rst_vec),
    .nmi_int             (nmi_int),
    .nmi_vec             (nmi_vec),
    .jtag_id             (jtag_id),

    .uart_rx             (uart_if.uart_rx),
    .uart_tx             (uart_tx),
    .uart_irq            (uart_irq),

    .gpio_in             (gpio_if.gpio_in),
    .gpio_out            (gpio_out),

    .adc_spi_sck         (adc_spi_sck),
    .adc_spi_mosi        (adc_spi_mosi),
    .adc_spi_miso        (spi_if.adc_spi_miso),
    .adc_spi_cs_n        (adc_spi_cs_n),

    .vga_hsync           (vga_hsync),
    .vga_vsync           (vga_vsync),
    .vga_red             (vga_red),
    .vga_green           (vga_green),
    .vga_blue            (vga_blue),

    .wdt_reset_out       (wdt_reset_out),

    .ext_irq             (ext_irq),
    .timer_int           (timer_int),

    .trace_rv_i_insn_ip  (trace_rv_i_insn_ip),
    .trace_rv_i_address_ip(trace_rv_i_address_ip),
    .trace_rv_i_valid_ip (trace_rv_i_valid_ip),
    .trace_rv_i_exception_ip(trace_rv_i_exception_ip),
    .trace_rv_i_ecause_ip(trace_rv_i_ecause_ip),
    .trace_rv_i_interrupt_ip(trace_rv_i_interrupt_ip),
    .trace_rv_i_tval_ip  (trace_rv_i_tval_ip),

    .o_cpu_halt_status   (o_cpu_halt_status),
    .o_cpu_halt_ack      (o_cpu_halt_ack),
    .o_debug_mode_status (o_debug_mode_status)
  );

  // Tap internal timer pulses for passive timer VIP monitor
  assign timer_if.sample_tick = dut.u_timer.sample_tick;
  assign timer_if.irq_timer   = dut.u_timer.irq_timer;

  // ---------------------------------------------------------------------------
  // Firmware Preload Functionality
  // ---------------------------------------------------------------------------
  task automatic write_imem_word(input int index, input logic [31:0] data);
    dut.u_imem.mem_0[index] = data[7:0];
    dut.u_imem.mem_1[index] = data[15:8];
    dut.u_imem.mem_2[index] = data[23:16];
    dut.u_imem.mem_3[index] = data[31:24];
  endtask : write_imem_word

  `include "../sw/firmware_words.vh"

  // ---------------------------------------------------------------------------
  // Reset Generation & Firmware Loading Block
  // ---------------------------------------------------------------------------
  initial begin
    rst_n = 1'b0;
    // 1. Initialize IMEM with RISC-V NOP instructions (0x0000_0013)
    for (int i = 0; i < 16384; i++) begin
      write_imem_word(i, 32'h0000_0013);
    end
    // 2. Load compiled C firmware into VeeR EL2 Instruction Memory
    load_c_firmware();
    # 200ns;
    @(posedge clk);
    rst_n = 1'b1;
  end

  // ---------------------------------------------------------------------------
  // Main UVM Configuration & Test Registration Block
  // ---------------------------------------------------------------------------
  initial begin
    // Default initial vector states: rst_vec points to 0x1000_0000 (shifted by 1)
    rst_vec   = (IMEM_BASE_ADDR >> 1);
    nmi_vec   = 31'h7700_0000;
    nmi_int   = 1'b0;
    jtag_id   = 31'h0000_0045;
    ext_irq   = 24'd0;
    timer_int = 1'b0;

    // Set UART baud divisor (16 divider -> 17 clock periods per bit)
    uart_if.baud_divisor = 17;

    // Set virtual interfaces into UVM Configuration Database
    uvm_config_db#(virtual uart_serial_if)::set(null, "*", "serial_vif", uart_if);
    uvm_config_db#(virtual spi_adc_if)::set(null, "*", "spi_vif", spi_if);
    uvm_config_db#(virtual gpio_pin_if)::set(null, "*", "pin_vif", gpio_if);
    uvm_config_db#(virtual vga_pixel_if)::set(null, "*", "vga_vif", vga_if);
    uvm_config_db#(virtual timer_pulse_if)::set(null, "*", "timer_vif", timer_if);
    uvm_config_db#(virtual wdt_safety_if)::set(null, "*", "safety_vif", wdt_if);

    // FSDB Waveform Dumping for Verdi
    `ifdef DUMP_FSDB
      $fsdbDumpfile("soc_uvm.fsdb");
      $fsdbDumpvars(0, tb_soc_uvm_top, "+all");
      $fsdbDumpSVA;
      $fsdbDumpMDA;
    `endif

    // Execute UVM Test at time 0
    run_test();
  end

endmodule : tb_soc_uvm_top
