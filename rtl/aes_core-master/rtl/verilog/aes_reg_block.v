/////////////////////////////////////////////////////////////////////
////                                                             ////
////  AES 32-Bit Register Block (CSR & Data Buffers)             ////
////                                                             ////
////  Implements:                                                ////
////  - CTRL (0x00) & STATUS (0x04) registers                    ////
////  - INTR_EN (0x08) & CORE_ID (0x0C)                          ////
////  - KEY[0..3] (0x10 - 0x1C): 128-bit Key                     ////
////  - DATA_IN[0..3] (0x20 - 0x2C): 128-bit Text In             ////
////  - DATA_OUT[0..3] (0x30 - 0x3C): 128-bit Text Out           ////
////  - Hardware FSM bridging to AES Encryption & Decryption Core////
////                                                             ////
/////////////////////////////////////////////////////////////////////

`include "timescale.v"

module aes_reg_block #(
    parameter integer C_ADDR_WIDTH = 8,
    parameter integer C_DATA_WIDTH = 32
)(
    input  wire                     clk,
    input  wire                     rst_n,

    // Register Bus Interface from AXI Slave
    input  wire [C_ADDR_WIDTH-1:0]  reg_addr,
    input  wire [C_DATA_WIDTH-1:0]  reg_wdata,
    input  wire [3:0]               reg_wstrb,
    input  wire                     reg_write,
    input  wire                     reg_read,
    output reg  [C_DATA_WIDTH-1:0]  reg_rdata,

    // Interface to aes_cipher_top (Encryption)
    output reg                      enc_ld,
    input  wire                     enc_done,
    input  wire [127:0]             enc_dout,

    // Interface to aes_inv_cipher_top (Decryption)
    output reg                      dec_kld,
    output reg                      dec_ld,
    input  wire                     dec_done,
    input  wire [127:0]             dec_dout,

    // Shared AES Core Buses
    output wire [127:0]             aes_key,
    output wire [127:0]             aes_din,
    output wire                     aes_core_rst_n,

    // Interrupt output
    output wire                     irq
);

    //--------------------------------------------------------------------------
    // Register Storage Declarations
    //--------------------------------------------------------------------------
    // CTRL Register (0x00)
    reg         ctrl_mode;       // bit 1: 0 = Encrypt, 1 = Decrypt
    reg         ctrl_auto_start; // bit 2: 1 = auto start on DATA_IN3 write
    reg         ctrl_key_update; // bit 3: 1 = force key schedule reload
    reg         ctrl_soft_rst;   // bit 4: soft reset core

    // STATUS Register (0x04)
    reg         status_busy;      // bit 0: core is busy computing
    reg         status_done;      // bit 1: operation complete (W1C)
    reg         status_key_ready; // bit 2: inverse key schedule ready

    // INTR_EN Register (0x08)
    reg         intr_en_done;    // bit 0: enable irq when done is 1

    // KEY Registers (0x10 - 0x1C) - 128 bits
    reg [31:0]  key_reg0; // bits [31:0]
    reg [31:0]  key_reg1; // bits [63:32]
    reg [31:0]  key_reg2; // bits [95:64]
    reg [31:0]  key_reg3; // bits [127:96]

    // DATA_IN Registers (0x20 - 0x2C) - 128 bits
    reg [31:0]  din_reg0; // bits [31:0]
    reg [31:0]  din_reg1; // bits [63:32]
    reg [31:0]  din_reg2; // bits [95:64]
    reg [31:0]  din_reg3; // bits [127:96]

    // DATA_OUT Registers (0x30 - 0x3C) - 128 bits
    reg [31:0]  dout_reg0; // bits [31:0]
    reg [31:0]  dout_reg1; // bits [63:32]
    reg [31:0]  dout_reg2; // bits [95:64]
    reg [31:0]  dout_reg3; // bits [127:96]

    // Assign shared 128-bit buses to the AES core
    assign aes_key        = { key_reg3, key_reg2, key_reg1, key_reg0 };
    assign aes_din        = { din_reg3, din_reg2, din_reg1, din_reg0 };
    assign aes_core_rst_n = rst_n & ~ctrl_soft_rst;

    // Interrupt line: active-high when done and enabled
    assign irq = status_done & intr_en_done;

    // Start strobe and immediate control decoding
    wire start_write = reg_write && (reg_addr[7:2] == 6'h00) && reg_wstrb[0] && reg_wdata[0];
    wire auto_start_write = reg_write && ctrl_auto_start && (reg_addr[7:2] == 6'h0B); // Write to DATA_IN3
    wire start_pulse = (start_write | auto_start_write) & ~status_busy;

    wire current_mode       = (reg_write && (reg_addr[7:2] == 6'h00) && reg_wstrb[0]) ? reg_wdata[1] : ctrl_mode;
    wire current_key_update = (reg_write && (reg_addr[7:2] == 6'h00) && reg_wstrb[0]) ? reg_wdata[3] : ctrl_key_update;

    //--------------------------------------------------------------------------
    // FSM State Definitions
    //--------------------------------------------------------------------------
    localparam [2:0]
        ST_IDLE      = 3'd0,
        ST_ENC_WAIT  = 3'd1,
        ST_DEC_WAITK = 3'd2,
        ST_DEC_WAIT  = 3'd3;

    reg [2:0] state;
    reg [4:0] key_wait_cnt;

    //--------------------------------------------------------------------------
    // Register Write Logic
    //--------------------------------------------------------------------------
    always @(posedge clk) begin
        if (!rst_n) begin
            ctrl_mode        <= 1'b0;
            ctrl_auto_start  <= 1'b0;
            ctrl_key_update  <= 1'b0;
            ctrl_soft_rst    <= 1'b0;
            intr_en_done     <= 1'b0;
            key_reg0         <= 32'h0;
            key_reg1         <= 32'h0;
            key_reg2         <= 32'h0;
            key_reg3         <= 32'h0;
            din_reg0         <= 32'h0;
            din_reg1         <= 32'h0;
            din_reg2         <= 32'h0;
            din_reg3         <= 32'h0;
        end else begin
            // Soft reset self-clearing
            if (ctrl_soft_rst) begin
                ctrl_soft_rst <= 1'b0;
            end

            if (reg_write) begin
                case (reg_addr[7:2])
                    6'h00: begin // CTRL (0x00)
                        if (reg_wstrb[0]) begin
                            ctrl_mode       <= reg_wdata[1];
                            ctrl_auto_start <= reg_wdata[2];
                            ctrl_key_update <= reg_wdata[3];
                            ctrl_soft_rst   <= reg_wdata[4];
                        end
                    end

                    6'h02: begin // INTR_EN (0x08)
                        if (reg_wstrb[0]) intr_en_done <= reg_wdata[0];
                    end

                    6'h04: begin // KEY0 (0x10)
                        if (reg_wstrb[0]) key_reg0[7:0]   <= reg_wdata[7:0];
                        if (reg_wstrb[1]) key_reg0[15:8]  <= reg_wdata[15:8];
                        if (reg_wstrb[2]) key_reg0[23:16] <= reg_wdata[23:16];
                        if (reg_wstrb[3]) key_reg0[31:24] <= reg_wdata[31:24];
                    end

                    6'h05: begin // KEY1 (0x14)
                        if (reg_wstrb[0]) key_reg1[7:0]   <= reg_wdata[7:0];
                        if (reg_wstrb[1]) key_reg1[15:8]  <= reg_wdata[15:8];
                        if (reg_wstrb[2]) key_reg1[23:16] <= reg_wdata[23:16];
                        if (reg_wstrb[3]) key_reg1[31:24] <= reg_wdata[31:24];
                    end

                    6'h06: begin // KEY2 (0x18)
                        if (reg_wstrb[0]) key_reg2[7:0]   <= reg_wdata[7:0];
                        if (reg_wstrb[1]) key_reg2[15:8]  <= reg_wdata[15:8];
                        if (reg_wstrb[2]) key_reg2[23:16] <= reg_wdata[23:16];
                        if (reg_wstrb[3]) key_reg2[31:24] <= reg_wdata[31:24];
                    end

                    6'h07: begin // KEY3 (0x1C)
                        if (reg_wstrb[0]) key_reg3[7:0]   <= reg_wdata[7:0];
                        if (reg_wstrb[1]) key_reg3[15:8]  <= reg_wdata[15:8];
                        if (reg_wstrb[2]) key_reg3[23:16] <= reg_wdata[23:16];
                        if (reg_wstrb[3]) key_reg3[31:24] <= reg_wdata[31:24];
                    end

                    6'h08: begin // DATA_IN0 (0x20)
                        if (reg_wstrb[0]) din_reg0[7:0]   <= reg_wdata[7:0];
                        if (reg_wstrb[1]) din_reg0[15:8]  <= reg_wdata[15:8];
                        if (reg_wstrb[2]) din_reg0[23:16] <= reg_wdata[23:16];
                        if (reg_wstrb[3]) din_reg0[31:24] <= reg_wdata[31:24];
                    end

                    6'h09: begin // DATA_IN1 (0x24)
                        if (reg_wstrb[0]) din_reg1[7:0]   <= reg_wdata[7:0];
                        if (reg_wstrb[1]) din_reg1[15:8]  <= reg_wdata[15:8];
                        if (reg_wstrb[2]) din_reg1[23:16] <= reg_wdata[23:16];
                        if (reg_wstrb[3]) din_reg1[31:24] <= reg_wdata[31:24];
                    end

                    6'h0A: begin // DATA_IN2 (0x28)
                        if (reg_wstrb[0]) din_reg2[7:0]   <= reg_wdata[7:0];
                        if (reg_wstrb[1]) din_reg2[15:8]  <= reg_wdata[15:8];
                        if (reg_wstrb[2]) din_reg2[23:16] <= reg_wdata[23:16];
                        if (reg_wstrb[3]) din_reg2[31:24] <= reg_wdata[31:24];
                    end

                    6'h0B: begin // DATA_IN3 (0x2C)
                        if (reg_wstrb[0]) din_reg3[7:0]   <= reg_wdata[7:0];
                        if (reg_wstrb[1]) din_reg3[15:8]  <= reg_wdata[15:8];
                        if (reg_wstrb[2]) din_reg3[23:16] <= reg_wdata[23:16];
                        if (reg_wstrb[3]) din_reg3[31:24] <= reg_wdata[31:24];
                    end

                    default: ;
                endcase
            end
        end
    end

    //--------------------------------------------------------------------------
    // Register Read Multiplexer (Word-aligned: addr[7:2])
    //--------------------------------------------------------------------------
    always @(*) begin
        case (reg_addr[7:2])
            6'h00: reg_rdata = {27'b0, ctrl_soft_rst, ctrl_key_update, ctrl_auto_start, ctrl_mode, 1'b0};
            6'h01: reg_rdata = {29'b0, status_key_ready, status_done, status_busy};
            6'h02: reg_rdata = {31'b0, intr_en_done};
            6'h03: reg_rdata = 32'h41455331; // "AES1"
            6'h04: reg_rdata = key_reg0;
            6'h05: reg_rdata = key_reg1;
            6'h06: reg_rdata = key_reg2;
            6'h07: reg_rdata = key_reg3;
            6'h08: reg_rdata = din_reg0;
            6'h09: reg_rdata = din_reg1;
            6'h0A: reg_rdata = din_reg2;
            6'h0B: reg_rdata = din_reg3;
            6'h0C: reg_rdata = dout_reg0;
            6'h0D: reg_rdata = dout_reg1;
            6'h0E: reg_rdata = dout_reg2;
            6'h0F: reg_rdata = dout_reg3;
            default: reg_rdata = 32'h00000000;
        endcase
    end

    //--------------------------------------------------------------------------
    // AES Core Bridging FSM & Status Management
    //--------------------------------------------------------------------------
    // Detect write to any KEY register to invalidate key schedule
    wire key_write = reg_write && (reg_addr[7:2] >= 6'h04 && reg_addr[7:2] <= 6'h07);

    always @(posedge clk) begin
        if (!rst_n || ctrl_soft_rst) begin
            state            <= ST_IDLE;
            enc_ld           <= 1'b0;
            dec_kld          <= 1'b0;
            dec_ld           <= 1'b0;
            status_busy      <= 1'b0;
            status_done      <= 1'b0;
            status_key_ready <= 1'b0;
            key_wait_cnt     <= 4'd0;
            dout_reg0        <= 32'h0;
            dout_reg1        <= 32'h0;
            dout_reg2        <= 32'h0;
            dout_reg3        <= 32'h0;
        end else begin
            // Invalidate key ready flag if key register is written
            if (key_write) begin
                status_key_ready <= 1'b0;
            end

            // Write-1-to-Clear (W1C) for STATUS[DONE]
            if (reg_write && (reg_addr[7:2] == 6'h01) && reg_wstrb[0] && reg_wdata[1]) begin
                status_done <= 1'b0;
            end

            case (state)
                ST_IDLE: begin
                    enc_ld  <= 1'b0;
                    dec_kld <= 1'b0;
                    dec_ld  <= 1'b0;
                    status_busy <= 1'b0;

                    if (start_pulse) begin
                        status_busy <= 1'b1;
                        status_done <= 1'b0; // Auto-clear DONE on new operation start

                        if (current_mode == 1'b0) begin
                            // Encryption: Pulse enc_ld for 1 cycle
                            enc_ld <= 1'b1;
                            state  <= ST_ENC_WAIT;
                        end else begin
                            // Decryption: check if key schedule needs expansion
                            if (~status_key_ready || current_key_update) begin
                                dec_kld      <= 1'b1;
                                key_wait_cnt <= 5'd15; // Wait 15 cycles for inv key expansion & buffer load
                                state        <= ST_DEC_WAITK;
                            end else begin
                                dec_ld <= 1'b1;
                                state  <= ST_DEC_WAIT;
                            end
                        end
                    end
                end

                ST_ENC_WAIT: begin
                    enc_ld <= 1'b0;
                    if (enc_done) begin
                        dout_reg0   <= enc_dout[31:0];
                        dout_reg1   <= enc_dout[63:32];
                        dout_reg2   <= enc_dout[95:64];
                        dout_reg3   <= enc_dout[127:96];
                        status_done <= 1'b1;
                        status_busy <= 1'b0;
                        state       <= ST_IDLE;
                    end
                end

                ST_DEC_WAITK: begin
                    dec_kld <= 1'b0;
                    if (key_wait_cnt > 4'd1) begin
                        key_wait_cnt <= key_wait_cnt - 1'b1;
                    end else begin
                        status_key_ready <= 1'b1;
                        dec_ld           <= 1'b1; // Start inverse cipher computation
                        state            <= ST_DEC_WAIT;
                    end
                end

                ST_DEC_WAIT: begin
                    dec_ld <= 1'b0;
                    if (dec_done) begin
                        dout_reg0   <= dec_dout[31:0];
                        dout_reg1   <= dec_dout[63:32];
                        dout_reg2   <= dec_dout[95:64];
                        dout_reg3   <= dec_dout[127:96];
                        status_done <= 1'b1;
                        status_busy <= 1'b0;
                        state       <= ST_IDLE;
                    end
                end

                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule
