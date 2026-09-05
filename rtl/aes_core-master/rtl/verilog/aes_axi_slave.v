/////////////////////////////////////////////////////////////////////
////                                                             ////
////  AES AXI4-Lite Slave Protocol Interface                     ////
////                                                             ////
////  Converts standard AXI4-Lite read/write bus channels into   ////
////  internal register read/write strobes for the register block////
////                                                             ////
/////////////////////////////////////////////////////////////////////

`include "timescale.v"

module aes_axi_slave #(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 8
)(
    // Global Clock & Reset
    input  wire                                s_axi_aclk,
    input  wire                                s_axi_aresetn,

    // AXI4-Lite Write Address Channel
    input  wire [C_S_AXI_ADDR_WIDTH-1:0]       s_axi_awaddr,
    input  wire [2:0]                          s_axi_awprot,
    input  wire                                s_axi_awvalid,
    output wire                                s_axi_awready,

    // AXI4-Lite Write Data Channel
    input  wire [C_S_AXI_DATA_WIDTH-1:0]       s_axi_wdata,
    input  wire [(C_S_AXI_DATA_WIDTH/8)-1:0]   s_axi_wstrb,
    input  wire                                s_axi_wvalid,
    output wire                                s_axi_wready,

    // AXI4-Lite Write Response Channel
    output wire [1:0]                          s_axi_bresp,
    output wire                                s_axi_bvalid,
    input  wire                                s_axi_bready,

    // AXI4-Lite Read Address Channel
    input  wire [C_S_AXI_ADDR_WIDTH-1:0]       s_axi_araddr,
    input  wire [2:0]                          s_axi_arprot,
    input  wire                                s_axi_arvalid,
    output wire                                s_axi_arready,

    // AXI4-Lite Read Data Channel
    output wire [C_S_AXI_DATA_WIDTH-1:0]       s_axi_rdata,
    output wire [1:0]                          s_axi_rresp,
    output wire                                s_axi_rvalid,
    input  wire                                s_axi_rready,

    // Internal Register Bus Interface
    output wire [C_S_AXI_ADDR_WIDTH-1:0]       reg_addr,
    output wire [C_S_AXI_DATA_WIDTH-1:0]       reg_wdata,
    output wire [(C_S_AXI_DATA_WIDTH/8)-1:0]   reg_wstrb,
    output wire                                reg_write,
    output wire                                reg_read,
    input  wire [C_S_AXI_DATA_WIDTH-1:0]       reg_rdata
);

    // Internal AXI handshake registers
    reg                                 axi_awready;
    reg [C_S_AXI_ADDR_WIDTH-1:0]        axi_awaddr;
    reg                                 axi_wready;
    reg [1:0]                           axi_bresp;
    reg                                 axi_bvalid;
    reg                                 axi_arready;
    reg [C_S_AXI_ADDR_WIDTH-1:0]        axi_araddr;
    reg [C_S_AXI_DATA_WIDTH-1:0]        axi_rdata;
    reg [1:0]                           axi_rresp;
    reg                                 axi_rvalid;

    reg                                 aw_en;

    // Connect outputs
    assign s_axi_awready = axi_awready;
    assign s_axi_wready  = axi_wready;
    assign s_axi_bresp   = axi_bresp;
    assign s_axi_bvalid  = axi_bvalid;
    assign s_axi_arready = axi_arready;
    assign s_axi_rdata   = axi_rdata;
    assign s_axi_rresp   = axi_rresp;
    assign s_axi_rvalid  = axi_rvalid;

    //--------------------------------------------------------------------------
    // Write Address & Data Handshake
    //--------------------------------------------------------------------------
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            axi_awready <= 1'b0;
            aw_en       <= 1'b1;
            axi_awaddr  <= {C_S_AXI_ADDR_WIDTH{1'b0}};
        end else begin
            if (~axi_awready && s_axi_awvalid && s_axi_wvalid && aw_en) begin
                axi_awready <= 1'b1;
                aw_en       <= 1'b0;
                axi_awaddr  <= s_axi_awaddr;
            end else if (s_axi_bready && axi_bvalid) begin
                aw_en       <= 1'b1;
                axi_awready <= 1'b0;
            end else begin
                axi_awready <= 1'b0;
            end
        end
    end

    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            axi_wready <= 1'b0;
        end else begin
            if (~axi_wready && s_axi_wvalid && s_axi_awvalid && aw_en) begin
                axi_wready <= 1'b1;
            end else begin
                axi_wready <= 1'b0;
            end
        end
    end

    // Write strobes for register block
    wire slv_reg_wren = axi_wready && s_axi_wvalid && axi_awready && s_axi_awvalid;
    assign reg_write  = slv_reg_wren;
    assign reg_wdata  = s_axi_wdata;
    assign reg_wstrb  = s_axi_wstrb;

    // Write Response Generation
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            axi_bvalid <= 1'b0;
            axi_bresp  <= 2'b00; // 'OKAY' response
        end else begin
            if (axi_awready && s_axi_awvalid && ~axi_bvalid && axi_wready && s_axi_wvalid) begin
                axi_bvalid <= 1'b1;
                axi_bresp  <= 2'b00;
            end else if (s_axi_bready && axi_bvalid) begin
                axi_bvalid <= 1'b0;
            end
        end
    end

    //--------------------------------------------------------------------------
    // Read Address & Data Handshake
    //--------------------------------------------------------------------------
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            axi_arready <= 1'b0;
            axi_araddr  <= {C_S_AXI_ADDR_WIDTH{1'b0}};
        end else begin
            if (~axi_arready && s_axi_arvalid) begin
                axi_arready <= 1'b1;
                axi_araddr  <= s_axi_araddr;
            end else begin
                axi_arready <= 1'b0;
            end
        end
    end

    wire slv_reg_rden = axi_arready && s_axi_arvalid && ~axi_rvalid;
    assign reg_read   = slv_reg_rden;

    // Address multiplexer for register block access
    wire [C_S_AXI_ADDR_WIDTH-1:0] read_addr_mux = (s_axi_arvalid && ~axi_arready) ? s_axi_araddr : axi_araddr;
    assign reg_addr = (slv_reg_wren) ? axi_awaddr : read_addr_mux;

    // Read Response and Data latching
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            axi_rvalid <= 1'b0;
            axi_rresp  <= 2'b00;
            axi_rdata  <= {C_S_AXI_DATA_WIDTH{1'b0}};
        end else begin
            if (axi_arready && s_axi_arvalid && ~axi_rvalid) begin
                axi_rvalid <= 1'b1;
                axi_rresp  <= 2'b00; // 'OKAY' response
                axi_rdata  <= reg_rdata;
            end else if (axi_rvalid && s_axi_rready) begin
                axi_rvalid <= 1'b0;
            end
        end
    end

endmodule
