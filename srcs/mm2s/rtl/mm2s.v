`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 11/28/2022 05:39:16 PM
// Design Name:
// Module Name: mm2s
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module mm2s_ingress_fifo #(
    // Necessary condition: MM_DATA_WIDTH >= S_DATA_WIDTH
    parameter MM_DATA_WIDTH = 256,
    parameter S_DATA_WIDTH = 256,
    parameter FIFO_DEPTH = 1024
) (
    input aclk,
    input aresetn,
    // AXI4 Write Address Channel
    input s_axi_awid,
    input [63:0] s_axi_awaddr,
    input [7:0] s_axi_awlen,
    input [2:0] s_axi_awsize,
    input [1:0] s_axi_awburst,
    input s_axi_awvalid,
    output s_axi_awready,
    // AXI4 Write Data Channel
    input [MM_DATA_WIDTH-1:0] s_axi_wdata,
    input [(MM_DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input s_axi_wlast,
    input s_axi_wvalid,
    output s_axi_wready,
    output [1:0] s_axi_bresp,
    output s_axi_bvalid,
    input s_axi_bready,
    // AXIS Read
    output s_axis_tvalid,
    input s_axis_tready,
    output [S_DATA_WIDTH-1:0] s_axis_tdata,
    // MISC
    output [$clog2(S_DATA_WIDTH):0] fifo_count
);

initial begin
    if (MM_DATA_WIDTH < S_DATA_WIDTH) begin
        $error("Error: AXI data width is smaller than AXIS data width");
        $finish;
    end
end

wire fifo_full;
wire m_axis_tvalid;
wire m_axis_tready;
reg [S_DATA_WIDTH-1:0] m_axis_tdata;

integer i;
reg [(S_DATA_WIDTH/8)-1:0] packing;

assign m_axis_tready = !fifo_full;
assign s_axi_awready = 1;
assign s_axi_wready = m_axis_tready;
assign s_axi_bresp = 0;
assign m_axis_tvalid = &packing;
// WARNING ASSUMES MASTER BREADY ALWAYS ASSERTED
assign s_axi_bvalid = s_axi_wvalid && s_axi_wlast && s_axi_wready;

always @(posedge aclk) begin
    if (!aresetn) begin
        packing <= 0;
    end else begin
        if (s_axi_wvalid && s_axi_wready) begin
            for (i = 0; i < (S_DATA_WIDTH/8); i = i + 1) begin
                if (s_axi_wstrb[i]) begin
                    m_axis_tdata[8 * i +: 8] <= s_axi_wdata[8 * i +: 8];
                end
            end
            if (m_axis_tvalid) begin
                packing <= s_axi_wstrb;
            end else begin
                packing <= packing | s_axi_wstrb;
            end
        end else begin
            if (m_axis_tvalid && m_axis_tready) begin
                packing <= 0;
            end
        end
    end
end

xpm_fifo_sync #(
    .CASCADE_HEIGHT(0),
    .DOUT_RESET_VALUE("0"),
    .ECC_MODE("no_ecc"),
    .FIFO_MEMORY_TYPE("auto"),
    .FIFO_READ_LATENCY(0),
    .FIFO_WRITE_DEPTH(FIFO_DEPTH),
    .FULL_RESET_VALUE(0),
    .PROG_EMPTY_THRESH(10),
    .PROG_FULL_THRESH(10),
    .RD_DATA_COUNT_WIDTH($clog2(S_DATA_WIDTH) + 1),
    .READ_DATA_WIDTH(S_DATA_WIDTH),
    .READ_MODE("fwft"),
    .SIM_ASSERT_CHK(0),
    .USE_ADV_FEATURES("1400"),
    .WAKEUP_TIME(0),
    .WRITE_DATA_WIDTH(S_DATA_WIDTH),
    .WR_DATA_COUNT_WIDTH($clog2(S_DATA_WIDTH) + 1)
) fifo_inst (
    .wr_clk(aclk),
    .rst(!aresetn),
    .full(fifo_full),
    .wr_en(m_axis_tvalid),
    .din(m_axis_tdata),
    .empty(),
    .rd_en(s_axis_tready),
    .data_valid(s_axis_tvalid),
    .dout(s_axis_tdata),
    .rd_data_count(fifo_count)
);
endmodule

module mm2s_egress_fifo #(
    // Necessary condition: MM_DATA_WIDTH >= S_DATA_WIDTH
    parameter MM_DATA_WIDTH = 256,
    parameter S_DATA_WIDTH = 256,
    parameter FIFO_DEPTH = 1024
) (
    input aclk,
    input aresetn,
    // AXI4 Read Address Channel
    input s_axi_arid,
    input [63:0] s_axi_araddr,
    input [7:0] s_axi_arlen,
    input [2:0] s_axi_arsize,
    input [1:0] s_axi_arburst,
    input s_axi_arvalid,
    output s_axi_arready,
    // AXI4 Read Data Channel
    output s_axi_rid,
    output [MM_DATA_WIDTH-1:0] s_axi_rdata,
    output [1:0] s_axi_rresp,
    output s_axi_rlast,
    output s_axi_rvalid,
    input s_axi_rready,
    // AXIS Write
    input s_axis_tvalid,
    output s_axis_tready,
    input [S_DATA_WIDTH-1:0] s_axis_tdata,
    // MISC
    output [$clog2(S_DATA_WIDTH):0] fifo_count
);

initial begin
    if (MM_DATA_WIDTH < S_DATA_WIDTH) begin
        $error("Error: AXI data width is smaller than AXIS data width");
        $finish;
    end
end

localparam PAD_LEN = MM_DATA_WIDTH - S_DATA_WIDTH;

wire outstanding_full;
wire outstanding_valid;
wire outstanding_rd;
wire [7:0] outstanding_data;
wire [MM_DATA_WIDTH-1:0] s_axi_rdata_padded;
reg [7:0] outstanding_counter;
reg [S_DATA_WIDTH-1:0] s_axi_rdata_unpadded;

wire data_fifo_full;
wire data_fifo_valid;

assign s_axi_arready = !outstanding_full;

assign s_axis_tready = !data_fifo_full;
assign s_axi_rid = 1'b0;
assign s_axi_rresp = 2'b0;
assign s_axi_rlast = s_axi_rvalid && s_axi_rready && outstanding_counter == 1;
assign s_axi_rvalid = data_fifo_valid && outstanding_counter != 0;
assign outstanding_rd = s_axi_rvalid && s_axi_rready;
assign s_axi_rdata_padded = {{PAD_LEN{1'b0}}, s_axi_rdata_unpadded};
assign s_axi_rdata = s_axi_rdata_padded;

always @(posedge(aclk)) begin
    if (!aresetn) begin
        outstanding_counter <= 8'b0;
    end else begin
        if (outstanding_valid && outstanding_counter == 0) begin
            outstanding_counter <= outstanding_data;
        end else if (s_axi_rvalid && s_axi_rready) begin
            outstanding_counter <= outstanding_counter - 1;
        end
    end
end

xpm_fifo_sync #(
    .CASCADE_HEIGHT(0),
    .DOUT_RESET_VALUE("0"),
    .ECC_MODE("no_ecc"),
    .FIFO_MEMORY_TYPE("auto"),
    .FIFO_READ_LATENCY(0),
    .FIFO_WRITE_DEPTH(64),
    .FULL_RESET_VALUE(0),
    .PROG_EMPTY_THRESH(10),
    .PROG_FULL_THRESH(10),
    .RD_DATA_COUNT_WIDTH(0),
    .READ_DATA_WIDTH(8),
    .READ_MODE("fwft"),
    .SIM_ASSERT_CHK(0),
    .USE_ADV_FEATURES("1000"),
    .WAKEUP_TIME(0),
    .WRITE_DATA_WIDTH(8),
    .WR_DATA_COUNT_WIDTH(0)
) outstanding_fifo_inst (
    .wr_clk(aclk),
    .rst(!aresetn),
    .full(outstanding_full),
    .wr_en(s_axi_arvalid),
    .din(s_axi_arlen),
    .empty(),
    .rd_en(outstanding_rd),
    .data_valid(outstanding_valid),
    .dout(outstanding_data)
);

xpm_fifo_sync #(
    .CASCADE_HEIGHT(0),
    .DOUT_RESET_VALUE("0"),
    .ECC_MODE("no_ecc"),
    .FIFO_MEMORY_TYPE("auto"),
    .FIFO_READ_LATENCY(0),
    .FIFO_WRITE_DEPTH(FIFO_DEPTH),
    .FULL_RESET_VALUE(0),
    .PROG_EMPTY_THRESH(10),
    .PROG_FULL_THRESH(10),
    .RD_DATA_COUNT_WIDTH($clog2(S_DATA_WIDTH) + 1),
    .READ_DATA_WIDTH(S_DATA_WIDTH),
    .READ_MODE("fwft"),
    .SIM_ASSERT_CHK(0),
    .USE_ADV_FEATURES("1400"),
    .WAKEUP_TIME(0),
    .WRITE_DATA_WIDTH(S_DATA_WIDTH),
    .WR_DATA_COUNT_WIDTH($clog2(S_DATA_WIDTH) + 1)
) data_fifo_inst (
    .wr_clk(aclk),
    .rst(!aresetn),
    .full(data_fifo_full),
    .wr_en(s_axis_tvalid),
    .din(s_axis_tdata),
    .empty(),
    .rd_en(s_axi_valid && s_axi_rready),
    .data_valid(data_fifo_valid),
    .dout(s_axi_rdata_unpadded),
    .rd_data_count(fifo_count)
);
endmodule

// Main module containing both ingress and egress fifos and presenting a complete AXI4 slave
// interface.
module mm2s_ingress_egress_fifos #(
    parameter MM_DATA_WIDTH = 256,
    parameter INGRESS_DATA_WIDTH = 256,
    parameter INGRESS_FIFO_DEPTH = 1024,
    parameter EGRESS_DATA_WIDTH = 256,
    parameter EGRESS_FIFO_DEPTH = 1024
) (
    input aclk,
    input aresetn,

    // AXI4 Write Address Channel
    input s_axi_awid,
    input [63:0] s_axi_awaddr,
    input [7:0] s_axi_awlen,
    input [2:0] s_axi_awsize,
    input [1:0] s_axi_awburst,

    input s_axi_awlock,
    input [3:0] s_axi_awcache,
    input [2:0] s_axi_awprot,
    input [3:0] s_axi_awqos,
    input [3:0] s_axi_awregion,

    input s_axi_awvalid,
    output s_axi_awready,

    // AXI4 Write Data Channel
    input [MM_DATA_WIDTH-1:0] s_axi_wdata,
    input [(MM_DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input s_axi_wlast,
    input s_axi_wvalid,
    output s_axi_wready,
    output [1:0] s_axi_bresp,
    output s_axi_bvalid,
    input s_axi_bready,

    // AXI4 Read Address Channel
    input s_axi_arid,
    input [63:0] s_axi_araddr,
    input [7:0] s_axi_arlen,
    input [2:0] s_axi_arsize,
    input [1:0] s_axi_arburst,

    input s_axi_arlock,
    input [3:0] s_axi_arcache,
    input [2:0] s_axi_arprot,
    input [3:0] s_axi_arqos,
    input [3:0] s_axi_arregion,
    input s_axi_arvalid,
    output s_axi_arready,

    // AXI4 Read Data Channel
    output s_axi_rid,
    output [MM_DATA_WIDTH-1:0] s_axi_rdata,
    output [1:0] s_axi_rresp,
    output s_axi_rlast,
    output s_axi_rvalid,
    input s_axi_rready,

    // AXIS Read
    output s_axis_in_tvalid,
    input s_axis_in_tready,
    output [INGRESS_DATA_WIDTH-1:0] s_axis_in_tdata,

    // AXIS Write
    input s_axis_out_tvalid,
    output s_axis_out_tready,
    input [EGRESS_DATA_WIDTH-1:0] s_axis_out_tdata,

    // MISC
    output [$clog2(INGRESS_DATA_WIDTH):0] ingress_fifo_count,
    output [$clog2(EGRESS_DATA_WIDTH):0] egress_fifo_count
);

mm2s_ingress_fifo #(
    .MM_DATA_WIDTH(MM_DATA_WIDTH),
    .S_DATA_WIDTH(INGRESS_DATA_WIDTH),
    .FIFO_DEPTH(INGRESS_FIFO_DEPTH)
)
mm2s_ingress_fifo_inst
(
    .aclk(aclk),
    .aresetn(aresetn),
    .s_axi_awid(s_axi_awid),
    .s_axi_awaddr(s_axi_awaddr),
    .s_axi_awlen(s_axi_awlen),
    .s_axi_awsize(s_axi_awsize),
    .s_axi_awburst(s_axi_awburst),
    .s_axi_awvalid(s_axi_awvalid),
    .s_axi_awready(s_axi_awready),
    .s_axi_wdata(s_axi_wdata),
    .s_axi_wstrb(s_axi_wstrb),
    .s_axi_wlast(s_axi_wlast),
    .s_axi_wvalid(s_axi_wvalid),
    .s_axi_wready(s_axi_wready),
    .s_axi_bresp(s_axi_bresp),
    .s_axi_bvalid(s_axi_bvalid),
    .s_axi_bready(s_axi_bready),
    .s_axis_tready(s_axis_in_tready),
    .s_axis_tvalid(s_axis_in_tvalid),
    .s_axis_tdata(s_axis_in_tdata),
    .fifo_count(ingress_fifo_count)
);

mm2s_egress_fifo #(
    .MM_DATA_WIDTH(MM_DATA_WIDTH),
    .S_DATA_WIDTH(EGRESS_DATA_WIDTH),
    .FIFO_DEPTH(EGRESS_FIFO_DEPTH)
)
mm2s_egress_fifo_inst
(
    .aclk(aclk),
    .aresetn(aresetn),
    .s_axi_arid(s_axi_arid),
    .s_axi_araddr(s_axi_araddr),
    .s_axi_arlen(s_axi_arlen),
    .s_axi_arsize(s_axi_arsize),
    .s_axi_arburst(s_axi_arburst),
    .s_axi_arvalid(s_axi_arvalid),
    .s_axi_arready(s_axi_arready),
    .s_axi_rid(s_axi_rid),
    .s_axi_rdata(s_axi_rdata),
    .s_axi_rresp(s_axi_rresp),
    .s_axi_rlast(s_axi_rlast),
    .s_axi_rvalid(s_axi_rvalid),
    .s_axi_rready(s_axi_rready),
    .s_axis_tvalid(s_axis_out_tvalid),
    .s_axis_tready(s_axis_out_tready),
    .s_axis_tdata(s_axis_out_tdata),
    .fifo_count(egress_fifo_count)
);

endmodule // mm2s_ingress_egress_fifos
