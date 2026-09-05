/////////////////////////////////////////////////////////////////////
////                                                             ////
////  Testbench for AES AXI4-Lite Top Peripheral                 ////
////                                                             ////
////  Tests:                                                     ////
////  - AXI4-Lite read/write transactions                        ////
////  - CORE_ID register verification                            ////
////  - NIST FIPS-197 128-bit AES Encryption via AXI bus        ////
////  - Write-1-to-Clear (W1C) on STATUS register                ////
////  - NIST FIPS-197 128-bit AES Decryption via AXI bus        ////
////  - Interrupt (irq) generation & deassertion                 ////
////                                                             ////
/////////////////////////////////////////////////////////////////////

`include "timescale.v"

module tb_aes_axi_top;

    parameter C_S_AXI_DATA_WIDTH = 32;
    parameter C_S_AXI_ADDR_WIDTH = 8;

    // Clock & Reset
    reg                                 s_axi_aclk;
    reg                                 s_axi_aresetn;

    // AXI4-Lite Write Address Channel
    reg  [C_S_AXI_ADDR_WIDTH-1:0]       s_axi_awaddr;
    reg  [2:0]                          s_axi_awprot;
    reg                                 s_axi_awvalid;
    wire                                s_axi_awready;

    // AXI4-Lite Write Data Channel
    reg  [C_S_AXI_DATA_WIDTH-1:0]       s_axi_wdata;
    reg  [(C_S_AXI_DATA_WIDTH/8)-1:0]   s_axi_wstrb;
    reg                                 s_axi_wvalid;
    wire                                s_axi_wready;

    // AXI4-Lite Write Response Channel
    wire [1:0]                          s_axi_bresp;
    wire                                s_axi_bvalid;
    reg                                 s_axi_bready;

    // AXI4-Lite Read Address Channel
    reg  [C_S_AXI_ADDR_WIDTH-1:0]       s_axi_araddr;
    reg  [2:0]                          s_axi_arprot;
    reg                                 s_axi_arvalid;
    wire                                s_axi_arready;

    // AXI4-Lite Read Data Channel
    wire [C_S_AXI_DATA_WIDTH-1:0]       s_axi_rdata;
    wire [1:0]                          s_axi_rresp;
    wire                                s_axi_rvalid;
    reg                                 s_axi_rready;

    // Interrupt output
    wire                                irq;

    // Test Tracking
    integer error_count;
    reg [31:0] read_data;

    // Clock Generation: 100MHz (10ns period)
    always #5 s_axi_aclk = ~s_axi_aclk;

    //--------------------------------------------------------------------------
    // DUT Instantiation
    //--------------------------------------------------------------------------
    aes_axi_top #(
        .C_S_AXI_DATA_WIDTH ( C_S_AXI_DATA_WIDTH ),
        .C_S_AXI_ADDR_WIDTH ( C_S_AXI_ADDR_WIDTH )
    ) dut (
        .s_axi_aclk    ( s_axi_aclk    ),
        .s_axi_aresetn ( s_axi_aresetn ),
        .s_axi_awaddr  ( s_axi_awaddr  ),
        .s_axi_awprot  ( s_axi_awprot  ),
        .s_axi_awvalid ( s_axi_awvalid ),
        .s_axi_awready ( s_axi_awready ),
        .s_axi_wdata   ( s_axi_wdata   ),
        .s_axi_wstrb   ( s_axi_wstrb   ),
        .s_axi_wvalid  ( s_axi_wvalid  ),
        .s_axi_wready  ( s_axi_wready  ),
        .s_axi_bresp   ( s_axi_bresp   ),
        .s_axi_bvalid  ( s_axi_bvalid  ),
        .s_axi_bready  ( s_axi_bready  ),
        .s_axi_araddr  ( s_axi_araddr  ),
        .s_axi_arprot  ( s_axi_arprot  ),
        .s_axi_arvalid ( s_axi_arvalid ),
        .s_axi_arready ( s_axi_arready ),
        .s_axi_rdata   ( s_axi_rdata   ),
        .s_axi_rresp   ( s_axi_rresp   ),
        .s_axi_rvalid  ( s_axi_rvalid  ),
        .s_axi_rready  ( s_axi_rready  ),
        .irq           ( irq           )
    );

    //--------------------------------------------------------------------------
    // AXI4-Lite Master Bus Tasks
    //--------------------------------------------------------------------------
    task axi_write(input [C_S_AXI_ADDR_WIDTH-1:0] addr, input [C_S_AXI_DATA_WIDTH-1:0] data);
        begin
            @(posedge s_axi_aclk);
            #1;
            s_axi_awaddr  = addr;
            s_axi_awvalid = 1'b1;
            s_axi_wdata   = data;
            s_axi_wstrb   = 4'hF;
            s_axi_wvalid  = 1'b1;
            s_axi_bready  = 1'b1;

            fork
                begin
                    while (!(s_axi_awvalid && s_axi_awready)) @(posedge s_axi_aclk);
                    #1;
                    s_axi_awvalid = 1'b0;
                end
                begin
                    while (!(s_axi_wvalid && s_axi_wready)) @(posedge s_axi_aclk);
                    #1;
                    s_axi_wvalid = 1'b0;
                end
                begin
                    while (!(s_axi_bvalid && s_axi_bready)) @(posedge s_axi_aclk);
                    #1;
                    s_axi_bready = 1'b0;
                end
            join
        end
    endtask

    task axi_read(input [C_S_AXI_ADDR_WIDTH-1:0] addr, output [C_S_AXI_DATA_WIDTH-1:0] data);
        begin
            @(posedge s_axi_aclk);
            #1;
            s_axi_araddr  = addr;
            s_axi_arvalid = 1'b1;
            s_axi_rready  = 1'b1;

            fork
                begin
                    while (!(s_axi_arvalid && s_axi_arready)) @(posedge s_axi_aclk);
                    #1;
                    s_axi_arvalid = 1'b0;
                end
                begin
                    while (!(s_axi_rvalid && s_axi_rready)) @(posedge s_axi_aclk);
                    data = s_axi_rdata;
                    #1;
                    s_axi_rready = 1'b0;
                end
            join
        end
    endtask

    //--------------------------------------------------------------------------
    // Test Sequence
    //--------------------------------------------------------------------------
    reg [31:0] ciph0, ciph1, ciph2, ciph3;
    reg [31:0] plain0, plain1, plain2, plain3;

    initial begin
        // Dump waves for Verdi
        $fsdbDumpfile("dump_axi.fsdb");
        $fsdbDumpvars(0, tb_aes_axi_top);
        $fsdbDumpSVA();
        $fsdbDumpMDA();

        s_axi_aclk    = 1'b0;
        s_axi_aresetn = 1'b0;
        s_axi_awaddr  = 0;
        s_axi_awprot  = 0;
        s_axi_awvalid = 0;
        s_axi_wdata   = 0;
        s_axi_wstrb   = 0;
        s_axi_wvalid  = 0;
        s_axi_bready  = 0;
        s_axi_araddr  = 0;
        s_axi_arprot  = 0;
        s_axi_arvalid = 0;
        s_axi_rready  = 0;
        error_count   = 0;

        $display("\n=========================================================");
        $display("   STARTING AES AXI4-LITE IP COMPREHENSIVE VERIFICATION  ");
        $display("=========================================================\n");

        // Reset Pulse
        repeat (5) @(posedge s_axi_aclk);
        s_axi_aresetn = 1'b1;
        repeat (5) @(posedge s_axi_aclk);

        //----------------------------------------------------------------------
        // Test 1: Verify CORE_ID (0x0C)
        //----------------------------------------------------------------------
        $display("[TEST 1] Checking CORE_ID register (Offset 0x0C)...");
        axi_read(8'h0C, read_data);
        if (read_data == 32'h41455331) begin
            $display("         [PASS] CORE_ID matched: 0x%08X (\"AES1\")", read_data);
        end else begin
            $display("         [FAIL] CORE_ID expected 0x41455331, got 0x%08X", read_data);
            error_count = error_count + 1;
        end

        //----------------------------------------------------------------------
        // Test 2: Standard NIST AES-128 Encryption via AXI Registers
        // Key   = 0x2b7e1516_28aed2a6_abf71588_09cf4f3c
        // Plain = 0x3243f6a8_885a308d_313198a2_e0370734
        // Exp   = 0x3925841d_02dc09fb_dc118597_196a0b32
        //----------------------------------------------------------------------
        $display("\n[TEST 2] Running NIST AES-128 Encryption Test...");

        // 1. Write 128-bit Key
        axi_write(8'h1C, 32'h2b7e1516); // KEY3
        axi_write(8'h18, 32'h28aed2a6); // KEY2
        axi_write(8'h14, 32'habf71588); // KEY1
        axi_write(8'h10, 32'h09cf4f3c); // KEY0

        // 2. Write 128-bit Plaintext
        axi_write(8'h2C, 32'h3243f6a8); // DATA_IN3
        axi_write(8'h28, 32'h885a308d); // DATA_IN2
        axi_write(8'h24, 32'h313198a2); // DATA_IN1
        axi_write(8'h20, 32'he0370734); // DATA_IN0

        // 3. Enable Interrupt and Start Encryption (MODE=0, START=1)
        axi_write(8'h08, 32'h00000001); // INTR_EN = 1
        axi_write(8'h00, 32'h00000001); // CTRL = START (bit 0 = 1, mode = 0)

        // 4. Poll STATUS register until DONE == 1
        read_data = 32'h0;
        while ((read_data & 32'h00000002) == 0) begin
            axi_read(8'h04, read_data);
        end
        $display("         [INFO] Encryption completed! STATUS = 0x%08X", read_data);

        // Check interrupt pin
        if (irq === 1'b1) begin
            $display("         [PASS] Interrupt signal 'irq' correctly asserted!");
        end else begin
            $display("         [FAIL] Expected irq == 1, got %b", irq);
            error_count = error_count + 1;
        end

        // 5. Read 128-bit Output Data
        axi_read(8'h3C, ciph3);
        axi_read(8'h38, ciph2);
        axi_read(8'h34, ciph1);
        axi_read(8'h30, ciph0);

        $display("         Expected: 3925841d_02dc09fb_dc118597_196a0b32");
        $display("         Got     : %08x_%08x_%08x_%08x", ciph3, ciph2, ciph1, ciph0);

        if ({ciph3, ciph2, ciph1, ciph0} == 128'h3925841d_02dc09fb_dc118597_196a0b32) begin
            $display("         [PASS] Encryption result perfectly matched NIST specification!");
        end else begin
            $display("         [FAIL] Encryption ciphertext mismatch!");
            error_count = error_count + 1;
        end

        //----------------------------------------------------------------------
        // Test 3: Test Write-1-to-Clear on STATUS register
        //----------------------------------------------------------------------
        $display("\n[TEST 3] Testing W1C on STATUS[DONE]...");
        axi_write(8'h04, 32'h00000002); // Write 1 to bit 1
        axi_read(8'h04, read_data);
        if ((read_data & 32'h00000002) == 0 && irq === 1'b0) begin
            $display("         [PASS] STATUS[DONE] and 'irq' cleared successfully!");
        end else begin
            $display("         [FAIL] STATUS[DONE] not cleared. STATUS = 0x%08X, irq = %b", read_data, irq);
            error_count = error_count + 1;
        end

        //----------------------------------------------------------------------
        // Test 4: Standard NIST AES-128 Decryption via AXI Registers
        // Cipher = 0x3925841d_02dc09fb_dc118597_196a0b32
        // Plain  = 0x3243f6a8_885a308d_313198a2_e0370734
        //----------------------------------------------------------------------
        $display("\n[TEST 4] Running NIST AES-128 Decryption Test...");

        // 1. Write Ciphertext into DATA_IN
        axi_write(8'h2C, ciph3);
        axi_write(8'h28, ciph2);
        axi_write(8'h24, ciph1);
        axi_write(8'h20, ciph0);

        // 2. Start Decryption (MODE=1, START=1, KEY_UPDATE=1)
        axi_write(8'h00, 32'h0000000B); // START=1, MODE=1, KEY_UPDATE=1

        // 3. Poll STATUS until DONE == 1
        read_data = 32'h0;
        while ((read_data & 32'h00000002) == 0) begin
            axi_read(8'h04, read_data);
        end
        $display("         [INFO] Decryption completed! STATUS = 0x%08X", read_data);

        // 4. Read 128-bit Decrypted Plaintext
        axi_read(8'h3C, plain3);
        axi_read(8'h38, plain2);
        axi_read(8'h34, plain1);
        axi_read(8'h30, plain0);

        $display("         Expected: 3243f6a8_885a308d_313198a2_e0370734");
        $display("         Got     : %08x_%08x_%08x_%08x", plain3, plain2, plain1, plain0);

        if ({plain3, plain2, plain1, plain0} == 128'h3243f6a8_885a308d_313198a2_e0370734) begin
            $display("         [PASS] Decryption result perfectly matched original plaintext!");
        end else begin
            $display("         [FAIL] Decryption plaintext mismatch!");
            error_count = error_count + 1;
        end

        // Clear DONE flag
        axi_write(8'h04, 32'h00000002);

        //----------------------------------------------------------------------
        // Final Summary
        //----------------------------------------------------------------------
        $display("\n=========================================================");
        if (error_count == 0) begin
            $display("   ALL AES AXI4-LITE TESTS PASSED WITH 0 ERRORS!        ");
        end else begin
            $display("   TEST FAILED! Total Errors: %0d                       ", error_count);
        end
        $display("=========================================================\n");

        repeat (20) @(posedge s_axi_aclk);
        $finish;
    end

endmodule
