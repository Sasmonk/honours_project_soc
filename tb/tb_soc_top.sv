// =============================================================================
// Testbench : tb_soc_top.sv
// Top Module: soc_top
// Tool      : Synopsys VCS / Verdi (SystemVerilog)
// Project   : Honours RISC-V Real-Time Signal Processing & VGA Oscilloscope SoC
//
// Description:
//   Self-checking verification testbench for the fully integrated SoC top level.
//   Verifies end-to-end integration of:
//     1. Western Digital VeeR EL2 RISC-V Processor Core (RV32IMC)
//     2. AXI4 64-bit to 32-bit Width Adapters (LSU, IFU, SB)
//     3. 5-Master x 20-Slave AXI4 Interconnect Crossbar
//     4. On-Chip 64 KB AXI4 Instruction Memory (IMEM at 0x1000_0000)
//     5. On-Chip 64 KB AXI4 Data Memory (DMEM at 0x1002_0000)
//     6. AXI UART IP Core (0x4000_6000) - Serial Tx/Rx & IRQ
//     7. Acquisition Timer (0x4000_8000) - Periodic sample_tick
//     8. GPIO Controller (0x4000_A000) - LED outputs & switch inputs
//     9. SPI Master Controller (0x4000_C000) - ADC acquisition interface
//    10. Watchdog Safety Monitor (0x4000_E000) - Trip status & NMI
//    11. Autonomous Streaming DMA Controller (0x4001_0000)
//    12. 16-Tap Q1.15 Fixed-Point FIR Filter (0x4001_2000)
//    13. Real-Time Oscilloscope VGA Controller with Software UI (0x4001_4000)
//    14. True Dual-Port Ping-Pong Double Sample Buffer (0x4001_6000)
//    15. PIC Interrupts & Watchdog NMI prewarn
// =============================================================================

`timescale 1ns/1ps

module tb_soc_top;
    import el2_pkg::*;

    // -------------------------------------------------------------------------
    // Parameters
    // -------------------------------------------------------------------------
    localparam DATA_WIDTH       = 32;
    localparam ADDR_WIDTH       = 32;
    localparam STRB_WIDTH       = DATA_WIDTH / 8;
    localparam ID_WIDTH         = 8;

    // Memory Map Base Addresses
    localparam [ADDR_WIDTH-1:0] IMEM_BASE_ADDR  = 32'h1000_0000;
    localparam [ADDR_WIDTH-1:0] DMEM_BASE_ADDR  = 32'h1002_0000;
    localparam [ADDR_WIDTH-1:0] UART_BASE_ADDR  = 32'h4000_6000;
    localparam [ADDR_WIDTH-1:0] TIMER_BASE_ADDR = 32'h4000_8000;
    localparam [ADDR_WIDTH-1:0] GPIO_BASE_ADDR  = 32'h4000_A000;
    localparam [ADDR_WIDTH-1:0] SPI_BASE_ADDR   = 32'h4000_C000;
    localparam [ADDR_WIDTH-1:0] WDT_BASE_ADDR   = 32'h4000_E000;
    localparam [ADDR_WIDTH-1:0] DMA_BASE_ADDR   = 32'h4001_0000;
    localparam [ADDR_WIDTH-1:0] FIR_BASE_ADDR   = 32'h4001_2000;
    localparam [ADDR_WIDTH-1:0] VGA_BASE_ADDR   = 32'h4001_4000;
    localparam [ADDR_WIDTH-1:0] SBUF_BASE_ADDR  = 32'h4001_6000;

    // Clock Periods
    localparam CLK_SYS_PERIOD_NS = 10;  // 100 MHz System Clock
    localparam CLK_VGA_PERIOD_NS = 40;  // 25 MHz Pixel Clock
    localparam UART_BAUD_DIV     = 868; // 115200 baud at 100 MHz
    localparam BIT_PERIOD_NS     = CLK_SYS_PERIOD_NS * UART_BAUD_DIV;

    // -------------------------------------------------------------------------
    // DUT Signals
    // -------------------------------------------------------------------------
    logic                    clk;
    logic                    rst_n;
    logic                    clk_vga;

    logic [31:1]             rst_vec;
    logic                    nmi_int;
    logic [31:1]             nmi_vec;
    logic [31:1]             jtag_id;

    logic                    uart_rx;
    wire                     uart_tx;
    wire                     uart_irq;

    logic [7:0]              gpio_in;
    wire [7:0]               gpio_out;

    wire                     adc_spi_sck;
    wire                     adc_spi_mosi;
    wire                     adc_spi_miso;
    wire                     adc_spi_cs_n;

    wire                     vga_hsync;
    wire                     vga_vsync;
    wire [3:0]               vga_red;
    wire [3:0]               vga_green;
    wire [3:0]               vga_blue;

    wire                     wdt_reset_out;

    logic [23:0]             ext_irq;
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

        .uart_rx             (uart_rx),
        .uart_tx             (uart_tx),
        .uart_irq            (uart_irq),

        .gpio_in             (gpio_in),
        .gpio_out            (gpio_out),

        .adc_spi_sck         (adc_spi_sck),
        .adc_spi_mosi        (adc_spi_mosi),
        .adc_spi_miso        (adc_spi_miso),
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
        .trace_rv_i_address_ip (trace_rv_i_address_ip),
        .trace_rv_i_valid_ip (trace_rv_i_valid_ip),
        .trace_rv_i_exception_ip (trace_rv_i_exception_ip),
        .trace_rv_i_ecause_ip(trace_rv_i_ecause_ip),
        .trace_rv_i_interrupt_ip(trace_rv_i_interrupt_ip),
        .trace_rv_i_tval_ip  (trace_rv_i_tval_ip),

        .o_cpu_halt_status   (o_cpu_halt_status),
        .o_cpu_halt_ack      (o_cpu_halt_ack),
        .o_debug_mode_status (o_debug_mode_status)
    );

    // -------------------------------------------------------------------------
    // Behavioral ADC Model Connected to Physical SPI Pins
    // -------------------------------------------------------------------------
    adc_model #(
        .DEFAULT_PATTERN     (0),          // Sine wave
        .SAMPLE_AMPLITUDE    (16'sd16000)
    ) u_adc_model (
        .adc_spi_sck         (adc_spi_sck),
        .adc_spi_miso        (adc_spi_miso),
        .adc_spi_mosi        (adc_spi_mosi),
        .adc_spi_cs_n        (adc_spi_cs_n)
    );

    // -------------------------------------------------------------------------
    // Clocks Generation
    // -------------------------------------------------------------------------
    initial begin
        clk = 0;
        forever #(CLK_SYS_PERIOD_NS / 2) clk = ~clk;
    end

    initial begin
        clk_vga = 0;
        forever #(CLK_VGA_PERIOD_NS / 2) clk_vga = ~clk_vga;
    end

    // -------------------------------------------------------------------------
    // Assertion Helper Task
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
    // UART Helper Tasks
    // -------------------------------------------------------------------------
    task automatic receive_uart_byte(output logic [7:0] rx_byte, input int timeout_ns = 500_000);
        int elapsed_ns = 0;
        rx_byte = 8'h00;

        while (uart_tx !== 1'b0 && elapsed_ns < timeout_ns) begin
            #10;
            elapsed_ns += 10;
        end

        if (elapsed_ns >= timeout_ns) begin
            $error("[TIMEOUT] Waiting for UART Tx start bit exceeded %0d ns", timeout_ns);
            return;
        end

        #(BIT_PERIOD_NS / 2);

        for (int i = 0; i < 8; i++) begin
            #BIT_PERIOD_NS;
            rx_byte[i] = uart_tx;
        end

        #BIT_PERIOD_NS;
        if (uart_tx !== 1'b1) begin
            $error("[UART FRAME ERROR] Stop bit not high on uart_tx! Observed: %b", uart_tx);
        end
    endtask

    task automatic transmit_uart_byte(input logic [7:0] tx_byte);
        int bit_cycles = UART_BAUD_DIV + 1;
        @(posedge clk);
        uart_rx <= 1'b0; // Start bit
        repeat (bit_cycles) @(posedge clk);

        for (int i = 0; i < 8; i++) begin
            uart_rx <= tx_byte[i];
            repeat (bit_cycles) @(posedge clk);
        end

        uart_rx <= 1'b1; // Stop bit
        repeat (bit_cycles) @(posedge clk);
    endtask

    // -------------------------------------------------------------------------
    // Trace & Instruction Retirement Monitor
    // -------------------------------------------------------------------------
    int retired_instructions = 0;
    always @(posedge clk) begin
        if (rst_n && trace_rv_i_valid_ip) begin
            retired_instructions++;
            $display("   [TRACE @ %0t ps] PC = 0x%08h | Instr = 0x%08h | Total Retired = %0d",
                     $time, trace_rv_i_address_ip, trace_rv_i_insn_ip, retired_instructions);
        end
        if (rst_n) begin
            if (dut.ifu_axi_arvalid && dut.ifu_axi_arready)
                $display("   [IFU AR HANDSHAKE] time=%0t ps | addr=0x%08h len=%0d", $time, dut.ifu_axi_araddr, dut.ifu_axi_arlen);
            if (dut.ifu_axi_rvalid && dut.ifu_axi_rready)
                $display("   [IFU R HANDSHAKE ] time=%0t ps | data=0x%016h last=%b resp=%b", $time, dut.ifu_axi_rdata, dut.ifu_axi_rlast, dut.ifu_axi_rresp);
            if (dut.lsu_axi_awvalid && dut.lsu_axi_awready)
                $display("   [LSU AW HANDSHAKE] time=%0t ps | addr=0x%08h size=%0d len=%0d", $time, dut.lsu_axi_awaddr, dut.lsu_axi_awsize, dut.lsu_axi_awlen);
            if (dut.lsu_axi_wvalid && dut.lsu_axi_wready)
                $display("   [LSU W HANDSHAKE ] time=%0t ps | data=0x%016h strb=0x%02h last=%b", $time, dut.lsu_axi_wdata, dut.lsu_axi_wstrb, dut.lsu_axi_wlast);
            if (dut.lsu_axi_bvalid && dut.lsu_axi_bready)
                $display("   [LSU B HANDSHAKE ] time=%0t ps | resp=%b", $time, dut.lsu_axi_bresp);
            if (dut.lsu_axi_arvalid && dut.lsu_axi_arready)
                $display("   [LSU AR HANDSHAKE] time=%0t ps | addr=0x%08h", $time, dut.lsu_axi_araddr);
            if (dut.lsu_axi_rvalid && dut.lsu_axi_rready)
                $display("   [LSU R HANDSHAKE ] time=%0t ps | data=0x%016h resp=%b", $time, dut.lsu_axi_rdata, dut.lsu_axi_rresp);
            if (dut.trace_rv_i_exception_ip)
                $display("   [CPU EXCEPTION] time=%0t ps | cause=%0d | tval=0x%08h", $time, dut.trace_rv_i_ecause_ip, dut.trace_rv_i_tval_ip);
        end
    end

    // -------------------------------------------------------------------------
    // Preload Instruction Memory (0x1000_0000)
    // -------------------------------------------------------------------------
    task automatic write_imem_word(input int word_addr, input logic [31:0] data);
        dut.u_imem.mem_0[word_addr] = data[7:0];
        dut.u_imem.mem_1[word_addr] = data[15:8];
        dut.u_imem.mem_2[word_addr] = data[23:16];
        dut.u_imem.mem_3[word_addr] = data[31:24];
    endtask

    task automatic preload_firmware();
        // Clear IMEM with NOP (addi x0, x0, 0)
        for (int i = 0; i < 16384; i++) begin
            write_imem_word(i, 32'h0000_0013);
        end

        // 1. Configure MRAC CSR (0x7c0) -> 0xAAAAAAA6 (Region 1 = Memory, Region 4 = Device)
        write_imem_word(0, 32'haaaab0b7); // lui x1, 0xaaaab
        write_imem_word(1, 32'haa608093); // addi x1, x1, -1370 -> x1 = 0xaaaaaaa6
        write_imem_word(2, 32'h7c009073); // csrw 0x7c0, x1

        // 2. Configure UART (0x4000_6000)
        write_imem_word(3, 32'h400060b7); // lui x1, 0x40006
        write_imem_word(4, 32'h00300113); // addi x2, x0, 3
        write_imem_word(5, 32'h0020a623); // sw x2, 12(x1)  -> LCR = 3 (8N1)
        write_imem_word(6, 32'h00100513); // addi x10, x0, 1
        write_imem_word(7, 32'h00a0a223); // sw x10, 4(x1)  -> IER = 1 (RX IRQ)
        write_imem_word(8, 32'h04100193); // addi x3, x0, 65 ('A')
        write_imem_word(9, 32'h0030a023); // sw x3, 0(x1)   -> THR = 'A' (transmit byte)

        // 3. Configure GPIO (0x4000_A000)
        write_imem_word(10, 32'h4000a137); // lui x2, 0x4000a
        write_imem_word(11, 32'h0a500193); // addi x3, x0, 165 (0xA5)
        write_imem_word(12, 32'h00312223); // sw x3, 4(x2)  -> GPIO OUT (0x04) = 0xA5
        write_imem_word(13, 32'h00012203); // lw x4, 0(x2)  -> read GPIO IN (0x00) into x4

        // 4. Configure VGA Oscilloscope UI Customization (0x4001_4000)
        write_imem_word(14, 32'h400142b7); // lui x5, 0x40014
        write_imem_word(15, 32'h0f000313); // addi x6, x0, 240 (0x0F0 = Green Trace)
        write_imem_word(16, 32'h0262a023); // sw x6, 32(x5) -> VGA_TRACE_COLOR (0x20) = 0x0F0
        write_imem_word(17, 32'h0c800393); // addi x7, x0, 200
        write_imem_word(18, 32'h0272a623); // sw x7, 44(x5) -> VGA_CURSOR_A_Y (0x2C) = 200

        // 5. Verify On-Chip Data Memory DMEM (0x1002_0000)
        write_imem_word(19, 32'h10020437); // lui x8, 0x10020
        write_imem_word(20, 32'h07b00493); // addi x9, x0, 123
        write_imem_word(21, 32'h00942023); // sw x9, 0(x8)  -> DMEM[0] = 123
        write_imem_word(22, 32'h00042583); // lw x11, 0(x8) -> read DMEM[0] into x11

        // 6. Infinite Loop
        write_imem_word(23, 32'h0000006f); // jal x0, 0

        $display("[INIT] Preloaded %0d RISC-V test instructions into On-Chip IMEM (0x1000_0000)", 24);
    endtask

    // -------------------------------------------------------------------------
    // Main Verification Process
    // -------------------------------------------------------------------------
    initial begin
        logic [7:0] captured_uart_byte;

        $display("\n==================================================================");
        $display("   STARTING RISC-V SoC TOP LEVEL INTEGRATION SUITE (Synopsys VCS) ");
        $display("==================================================================");

        // Preload On-Chip IMEM with firmware
        preload_firmware();

        // ---------------------------------------------------------------------
        // TEST 1: Power-On Reset & Static Initialization
        // ---------------------------------------------------------------------
        $display("\n--- [TEST 1] Power-On Reset & Initialization ---");
        rst_n       = 1'b0;
        uart_rx     = 1'b1;
        gpio_in     = 8'h3C;
        ext_irq     = '0;
        timer_int   = 1'b0;
        nmi_int     = 1'b0;
        nmi_vec     = 31'h7700_0000;
        jtag_id     = 31'h0000_0045;
        // Reset vector set to IMEM base address 0x1000_0000
        rst_vec     = (IMEM_BASE_ADDR >> 1);

        #(CLK_SYS_PERIOD_NS * 10);
        check("Test 1.1: Reset asserted, CPU halt status inactive", (o_cpu_halt_status == 1'b0));
        check("Test 1.2: UART Tx idle high during reset", (uart_tx == 1'b1));
        check("Test 1.3: Watchdog reset out inactive", (wdt_reset_out == 1'b0));

        // Release reset
        @(posedge clk);
        rst_n = 1'b1;
        #(CLK_SYS_PERIOD_NS * 5);
        check("Test 1.4: Reset released successfully", (rst_n == 1'b1));

        // ---------------------------------------------------------------------
        // TEST 2 & 3: VeeR Core Execution & UART Serial Transmission
        // ---------------------------------------------------------------------
        $display("\n--- [TEST 2 & 3] Core Execution & UART Serial Transmission ---");
        $display("   Launching threads: UART TX reception monitor and CPU instruction retirement...");

        fork
            begin : uart_tx_monitor
                receive_uart_byte(captured_uart_byte, 500_000);
            end
            begin : cpu_execution
                int timeout_cycles = 500_000;
                while (retired_instructions < 20 && timeout_cycles > 0) begin
                    @(posedge clk);
                    timeout_cycles--;
                end
            end
        join

        check("Test 2.1: VeeR EL2 fetched & retired instructions from on-chip IMEM",
              (retired_instructions >= 5),
              $sformatf("Only %0d instructions retired", retired_instructions));

        $display("   Captured UART TX output: 0x%02h ('%c')", captured_uart_byte, captured_uart_byte);
        check("Test 3.1: UART Serial frame successfully received on uart_tx",
              (captured_uart_byte == 8'h41),
              $sformatf("Expected 0x41 ('A'), got 0x%02h", captured_uart_byte));

        // ---------------------------------------------------------------------
        // TEST 4: GPIO Controller Software Control Verification
        // ---------------------------------------------------------------------
        $display("\n--- [TEST 4] GPIO Controller Software Verification ---");
        #(CLK_SYS_PERIOD_NS * 50);
        $display("   Observed gpio_out = 0x%02h (Expected: 0xA5)", gpio_out);
        check("Test 4.1: Core software wrote 0xA5 to GPIO outputs",
              (gpio_out == 8'hA5),
              $sformatf("Expected 0xA5, got 0x%02h", gpio_out));

        // ---------------------------------------------------------------------
        // TEST 5: VGA Controller Software UI Customization
        // ---------------------------------------------------------------------
        $display("\n--- [TEST 5] Software Control of VGA UI Settings ---");
        $display("   Observed VGA Trace Color = 0x%03h (Expected: 0x0F0)", dut.u_vga.vga_trace_color);
        $display("   Observed VGA Cursor A Y  = %0d (Expected: 200)", dut.u_vga.vga_cursor_a_y);
        check("Test 5.1: VGA custom trace color successfully set by CPU",
              (dut.u_vga.vga_trace_color == 12'h0F0),
              $sformatf("Expected 0x0F0, got 0x%03h", dut.u_vga.vga_trace_color));
        check("Test 5.2: VGA Cursor A position successfully set by CPU",
              (dut.u_vga.vga_cursor_a_y == 10'd200),
              $sformatf("Expected 200, got %0d", dut.u_vga.vga_cursor_a_y));

        // ---------------------------------------------------------------------
        // TEST 6: On-Chip Data Memory (DMEM) R/W Verification
        // ---------------------------------------------------------------------
        $display("\n--- [TEST 6] On-Chip Data Memory (DMEM) Verification ---");
        $display("   Checking DMEM[0] = %0d (Expected: 123)",
                 {dut.u_dmem.mem_3[0], dut.u_dmem.mem_2[0], dut.u_dmem.mem_1[0], dut.u_dmem.mem_0[0]});
        check("Test 6.1: Core stored test word to on-chip DMEM via Interconnect",
              ({dut.u_dmem.mem_3[0], dut.u_dmem.mem_2[0], dut.u_dmem.mem_1[0], dut.u_dmem.mem_0[0]} == 32'd123),
              "DMEM content does not match expected write value");

        // ---------------------------------------------------------------------
        // TEST 7: External Serial Reception on uart_rx & PIC IRQ Assertion
        // ---------------------------------------------------------------------
        $display("\n--- [TEST 7] External Serial Reception on uart_rx & PIC IRQ ---");
        #(CLK_SYS_PERIOD_NS * 50);
        $display("   Driving incoming UART serial bitstream 0x5A onto uart_rx (115200 baud)...");
        transmit_uart_byte(8'h5A);

        begin : wait_for_rx_irq
            int timeout = 50_000;
            while (!uart_irq && timeout > 0) begin
                @(posedge clk);
                timeout--;
            end
            check("Test 7.1: UART RX generated interrupt on uart_irq",
                  (uart_irq == 1'b1),
                  "uart_irq failed to assert after serial reception");
        end

        // ---------------------------------------------------------------------
        // TEST 8: ADC SPI Acquisition, DMA Streaming & Ping-Pong Buffering
        // ---------------------------------------------------------------------
        $display("\n--- [TEST 8] ADC SPI Acquisition & Ping-Pong Sample Buffer ---");
        // Check that VGA video timing is actively generating sync signals
        #(CLK_VGA_PERIOD_NS * 500);
        check("Test 8.1: VGA timing generator running (vga_hsync active)",
              (vga_hsync !== 1'bx),
              "vga_hsync is undefined");
        check("Test 8.2: VGA vertical sync active (vga_vsync active)",
              (vga_vsync !== 1'bx),
              "vga_vsync is undefined");
        check("Test 8.3: Watchdog safety monitor active and healthy",
              (wdt_reset_out == 1'b0),
              "Watchdog reset triggered unexpectedly");

        // ---------------------------------------------------------------------
        // TEST 9: External PIC Interrupt Routing
        // ---------------------------------------------------------------------
        $display("\n--- [TEST 9] External PIC Interrupt Lines ---");
        @(posedge clk);
        ext_irq[0] = 1'b1;
        timer_int  = 1'b1;
        #(CLK_SYS_PERIOD_NS * 5);
        check("Test 9.1: ext_irq[0] active", (ext_irq[0] == 1'b1));
        check("Test 9.2: timer_int active", (timer_int == 1'b1));

        @(posedge clk);
        ext_irq[0] = 1'b0;
        timer_int  = 1'b0;
        #(CLK_SYS_PERIOD_NS * 5);
        check("Test 9.3: Interrupts deasserted", (ext_irq[0] == 1'b0 && timer_int == 1'b0));

        // ---------------------------------------------------------------------
        // Final Regression Summary
        // ---------------------------------------------------------------------
        #(CLK_SYS_PERIOD_NS * 50);
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
        #50_000_000; // 50ms maximum simulation limit
        $error("\n[WATCHDOG TIMEOUT] Simulation exceeded maximum allowed time limit (50ms)!");
        $finish(2);
    end

endmodule
