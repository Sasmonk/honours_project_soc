/////////////////////////////////////////////////////////////////////
////                                                             ////
////  AES AXI4-Lite Top-Level Module                             ////
////                                                             ////
////  Wires together:                                            ////
////  1. AXI4-Lite Slave Protocol Interface                      ////
////  2. 32-bit Register Block (CSRs, Key, Data In, Data Out)    ////
////  3. AES Cipher Top Core (Encryption)                        ////
////  4. AES Inverse Cipher Top Core (Decryption)                ////
////                                                             ////
/////////////////////////////////////////////////////////////////////

`include "timescale.v"

module aes_axi_top #(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 8
)(
    // AXI4-Lite Slave Interface
    input  wire                                s_axi_aclk,
    input  wire                                s_axi_aresetn,

    // Write Address Channel
    input  wire [C_S_AXI_ADDR_WIDTH-1:0]       s_axi_awaddr,
    input  wire [2:0]                          s_axi_awprot,
    input  wire                                s_axi_awvalid,
    output wire                                s_axi_awready,

    // Write Data Channel
    input  wire [C_S_AXI_DATA_WIDTH-1:0]       s_axi_wdata,
    input  wire [(C_S_AXI_DATA_WIDTH/8)-1:0]   s_axi_wstrb,
    input  wire                                s_axi_wvalid,
    output wire                                s_axi_wready,

    // Write Response Channel
    output wire [1:0]                          s_axi_bresp,
    output wire                                s_axi_bvalid,
    input  wire                                s_axi_bready,

    // Read Address Channel
    input  wire [C_S_AXI_ADDR_WIDTH-1:0]       s_axi_araddr,
    input  wire [2:0]                          s_axi_arprot,
    input  wire                                s_axi_arvalid,
    output wire                                s_axi_arready,

    // Read Data Channel
    output wire [C_S_AXI_DATA_WIDTH-1:0]       s_axi_rdata,
    output wire [1:0]                          s_axi_rresp,
    output wire                                s_axi_rvalid,
    input  wire                                s_axi_rready,

    // Interrupt Output
    output wire                                irq
);

    //--------------------------------------------------------------------------
    // Internal Interconnect Wires
    //--------------------------------------------------------------------------
    // AXI Slave to Register Block
    wire [C_S_AXI_ADDR_WIDTH-1:0]       reg_addr;
    wire [C_S_AXI_DATA_WIDTH-1:0]       reg_wdata;
    wire [(C_S_AXI_DATA_WIDTH/8)-1:0]   reg_wstrb;
    wire                                reg_write;
    wire                                reg_read;
    wire [C_S_AXI_DATA_WIDTH-1:0]       reg_rdata;

    // Register Block to AES Cores
    wire                                enc_ld;
    wire                                enc_done;
    wire [127:0]                        enc_dout;

    wire                                dec_kld;
    wire                                dec_ld;
    wire                                dec_done;
    wire [127:0]                        dec_dout;

    wire [127:0]                        aes_key;
    wire [127:0]                        aes_din;
    wire                                aes_core_rst_n;

    //--------------------------------------------------------------------------
    // 1. AXI4-Lite Slave Protocol Interface Instance
    //--------------------------------------------------------------------------
    aes_axi_slave #(
        .C_S_AXI_DATA_WIDTH ( C_S_AXI_DATA_WIDTH ),
        .C_S_AXI_ADDR_WIDTH ( C_S_AXI_ADDR_WIDTH )
    ) u_axi_slave (
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

        .reg_addr      ( reg_addr      ),
        .reg_wdata     ( reg_wdata     ),
        .reg_wstrb     ( reg_wstrb     ),
        .reg_write     ( reg_write     ),
        .reg_read      ( reg_read      ),
        .reg_rdata     ( reg_rdata     )
    );

    //--------------------------------------------------------------------------
    // 2. 32-Bit Register Block Instance
    //--------------------------------------------------------------------------
    aes_reg_block #(
        .C_ADDR_WIDTH ( C_S_AXI_ADDR_WIDTH ),
        .C_DATA_WIDTH ( C_S_AXI_DATA_WIDTH )
    ) u_reg_block (
        .clk            ( s_axi_aclk     ),
        .rst_n          ( s_axi_aresetn  ),
        .reg_addr       ( reg_addr       ),
        .reg_wdata      ( reg_wdata      ),
        .reg_wstrb      ( reg_wstrb      ),
        .reg_write      ( reg_write      ),
        .reg_read       ( reg_read       ),
        .reg_rdata      ( reg_rdata      ),

        .enc_ld         ( enc_ld         ),
        .enc_done       ( enc_done       ),
        .enc_dout       ( enc_dout       ),

        .dec_kld        ( dec_kld        ),
        .dec_ld         ( dec_ld         ),
        .dec_done       ( dec_done       ),
        .dec_dout       ( dec_dout       ),

        .aes_key        ( aes_key        ),
        .aes_din        ( aes_din        ),
        .aes_core_rst_n ( aes_core_rst_n ),

        .irq            ( irq            )
    );

    //--------------------------------------------------------------------------
    // 3. AES Encryption Core Instance (aes_cipher_top)
    //--------------------------------------------------------------------------
    aes_cipher_top u_cipher (
        .clk      ( s_axi_aclk     ),
        .rst      ( aes_core_rst_n ),
        .ld       ( enc_ld         ),
        .done     ( enc_done       ),
        .key      ( aes_key        ),
        .text_in  ( aes_din        ),
        .text_out ( enc_dout       )
    );

    //--------------------------------------------------------------------------
    // 4. AES Decryption Core Instance (aes_inv_cipher_top)
    //--------------------------------------------------------------------------
    aes_inv_cipher_top u_inv_cipher (
        .clk      ( s_axi_aclk     ),
        .rst      ( aes_core_rst_n ),
        .kld      ( dec_kld        ),
        .ld       ( dec_ld         ),
        .done     ( dec_done       ),
        .key      ( aes_key        ),
        .text_in  ( aes_din        ),
        .text_out ( dec_dout       )
    );

endmodule
