/*

Copyright (c) 2018 Alex Forencich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

// Language: Verilog 2001

`timescale 1ns / 1ps

/*
 * Ultrascale PCIe AXI DMA Read
 */
module pcie_us_axi_dma_rd #
(
    parameter AXIS_PCIE_DATA_WIDTH = 256,
    parameter AXIS_PCIE_KEEP_WIDTH = (AXIS_PCIE_DATA_WIDTH/32),
    parameter AXI_DATA_WIDTH = AXIS_PCIE_DATA_WIDTH,
    parameter AXI_ADDR_WIDTH = 64,
    parameter AXI_STRB_WIDTH = (AXI_DATA_WIDTH/8),
    parameter AXI_ID_WIDTH = 8,
    parameter AXI_MAX_BURST_LEN = 256,
    parameter PCIE_ADDR_WIDTH = 64,
    parameter PCIE_CLIENT_TAG = 1,
    parameter PCIE_TAG_WIDTH = 8,
    parameter PCIE_TAG_COUNT = 32,
    parameter PCIE_EXT_TAG_ENABLE = 0,
    parameter LEN_WIDTH = 20,
    parameter TAG_WIDTH = 8
)
(
    input  wire                            clk,
    input  wire                            rst,

    /*
     * AXI input (RC)
     */
    input  wire [AXIS_PCIE_DATA_WIDTH-1:0] s_axis_rc_tdata,
    input  wire [AXIS_PCIE_KEEP_WIDTH-1:0] s_axis_rc_tkeep,
    input  wire                            s_axis_rc_tvalid,
    output wire                            s_axis_rc_tready,
    input  wire                            s_axis_rc_tlast,
    input  wire [74:0]                     s_axis_rc_tuser,

    /*
     * AXI output (RQ)
     */
    output wire [AXIS_PCIE_DATA_WIDTH-1:0] m_axis_rq_tdata,
    output wire [AXIS_PCIE_KEEP_WIDTH-1:0] m_axis_rq_tkeep,
    output wire                            m_axis_rq_tvalid,
    input  wire                            m_axis_rq_tready,
    output wire                            m_axis_rq_tlast,
    output wire [59:0]                     m_axis_rq_tuser,

    /*
     * Tag input
     */
    input  wire [PCIE_TAG_WIDTH-1:0]       s_axis_pcie_rq_tag,
    input  wire                            s_axis_pcie_rq_tag_valid,

    /*
     * AXI read descriptor input
     */
    input  wire [PCIE_ADDR_WIDTH-1:0]      s_axis_read_desc_pcie_addr,
    input  wire [AXI_ADDR_WIDTH-1:0]       s_axis_read_desc_axi_addr,
    input  wire [LEN_WIDTH-1:0]            s_axis_read_desc_len,
    input  wire [TAG_WIDTH-1:0]            s_axis_read_desc_tag,
    input  wire                            s_axis_read_desc_valid,
    output wire                            s_axis_read_desc_ready,

    /*
     * AXI read descriptor status output
     */
    output wire [TAG_WIDTH-1:0]            m_axis_read_desc_status_tag,
    output wire                            m_axis_read_desc_status_valid,

    /*
     * AXI master interface
     */
    output wire [AXI_ID_WIDTH-1:0]         m_axi_awid,
    output wire [AXI_ADDR_WIDTH-1:0]       m_axi_awaddr,
    output wire [7:0]                      m_axi_awlen,
    output wire [2:0]                      m_axi_awsize,
    output wire [1:0]                      m_axi_awburst,
    output wire                            m_axi_awlock,
    output wire [3:0]                      m_axi_awcache,
    output wire [2:0]                      m_axi_awprot,
    output wire                            m_axi_awvalid,
    input  wire                            m_axi_awready,
    output wire [AXI_DATA_WIDTH-1:0]       m_axi_wdata,
    output wire [AXI_STRB_WIDTH-1:0]       m_axi_wstrb,
    output wire                            m_axi_wlast,
    output wire                            m_axi_wvalid,
    input  wire                            m_axi_wready,
    input  wire [AXI_ID_WIDTH-1:0]         m_axi_bid,
    input  wire [1:0]                      m_axi_bresp,
    input  wire                            m_axi_bvalid,
    output wire                            m_axi_bready,

    /*
     * Configuration
     */
    input  wire                            enable,
    input  wire                            ext_tag_enable,
    input  wire [15:0]                     requester_id,
    input  wire                            requester_id_enable,
    input  wire [2:0]                      max_read_request_size,

    /*
     * Status
     */
    output wire                            status_error_cor,
    output wire                            status_error_uncor
);

parameter AXI_WORD_WIDTH = AXI_STRB_WIDTH;
parameter AXI_WORD_SIZE = AXI_DATA_WIDTH/AXI_WORD_WIDTH;
parameter AXI_BURST_SIZE = $clog2(AXI_STRB_WIDTH);
parameter AXI_MAX_BURST_SIZE = AXI_MAX_BURST_LEN*AXI_WORD_WIDTH;

parameter AXIS_PCIE_WORD_WIDTH = AXIS_PCIE_KEEP_WIDTH;
parameter AXIS_PCIE_WORD_SIZE = AXIS_PCIE_DATA_WIDTH/AXIS_PCIE_WORD_WIDTH;

parameter OFFSET_WIDTH = $clog2(AXIS_PCIE_DATA_WIDTH/8);

// bus width assertions
initial begin
    if (AXIS_PCIE_DATA_WIDTH != 64 && AXIS_PCIE_DATA_WIDTH != 128 && AXIS_PCIE_DATA_WIDTH != 256) begin
        $error("Error: PCIe interface width must be 64, 128, or 256");
        $finish;
    end

    if (AXIS_PCIE_KEEP_WIDTH * 32 != AXIS_PCIE_DATA_WIDTH) begin
        $error("Error: PCIe interface requires dword (32-bit) granularity");
        $finish;
    end

    if (AXI_DATA_WIDTH != AXIS_PCIE_DATA_WIDTH) begin
        $error("Error: AXI interface width must match PCIe interface width");
        $finish;
    end

    if (AXI_STRB_WIDTH * 8 != AXI_DATA_WIDTH) begin
        $error("Error: AXI interface requires byte (8-bit) granularity");
        $finish;
    end

    if (AXI_MAX_BURST_LEN < 1 || AXI_MAX_BURST_LEN > 256) begin
        $error("Error: AXI_MAX_BURST_LEN must be between 1 and 256");
        $finish;
    end
end

localparam [3:0]
    REQ_MEM_READ = 4'b0000,
    REQ_MEM_WRITE = 4'b0001,
    REQ_IO_READ = 4'b0010,
    REQ_IO_WRITE = 4'b0011,
    REQ_MEM_FETCH_ADD = 4'b0100,
    REQ_MEM_SWAP = 4'b0101,
    REQ_MEM_CAS = 4'b0110,
    REQ_MEM_READ_LOCKED = 4'b0111,
    REQ_CFG_READ_0 = 4'b1000,
    REQ_CFG_READ_1 = 4'b1001,
    REQ_CFG_WRITE_0 = 4'b1010,
    REQ_CFG_WRITE_1 = 4'b1011,
    REQ_MSG = 4'b1100,
    REQ_MSG_VENDOR = 4'b1101,
    REQ_MSG_ATS = 4'b1110;

localparam [2:0]
    CPL_STATUS_SC  = 3'b000, // successful completion
    CPL_STATUS_UR  = 3'b001, // unsupported request
    CPL_STATUS_CRS = 3'b010, // configuration request retry status
    CPL_STATUS_CA  = 3'b100; // completer abort

localparam [4:0]
    RC_ERROR_NORMAL_TERMINATION = 4'b0000,
    RC_ERROR_POISONED = 4'b0001,
    RC_ERROR_BAD_STATUS = 4'b0010,
    RC_ERROR_INVALID_LENGTH = 4'b0011,
    RC_ERROR_MISMATCH = 4'b0100,
    RC_ERROR_INVALID_ADDRESS = 4'b0101,
    RC_ERROR_INVALID_TAG = 4'b0110,
    RC_ERROR_TIMEOUT = 4'b1001,
    RC_ERROR_FLR = 4'b1000;

localparam [1:0]
    REQ_STATE_IDLE = 2'd0,
    REQ_STATE_START = 2'd1,
    REQ_STATE_HEADER = 2'd2;

reg [1:0] req_state_reg = REQ_STATE_IDLE, req_state_next;

localparam [2:0]
    TLP_STATE_IDLE = 3'd0,
    TLP_STATE_HEADER = 3'd1,
    TLP_STATE_START = 3'd2,
    TLP_STATE_TRANSFER = 3'd3,
    TLP_STATE_WAIT_END = 3'd4;

reg [2:0] tlp_state_reg = TLP_STATE_IDLE, tlp_state_next;

// datapath control signals
reg transfer_in_save;

reg tag_table_we_req;
reg tag_table_we_tlp;

reg tlp_cmd_ready;

reg finish_tag;

reg [PCIE_ADDR_WIDTH-1:0] req_pcie_addr_reg = {PCIE_ADDR_WIDTH{1'b0}}, req_pcie_addr_next;
reg [AXI_ADDR_WIDTH-1:0] req_axi_addr_reg = {AXI_ADDR_WIDTH{1'b0}}, req_axi_addr_next;
reg [LEN_WIDTH-1:0] req_op_count_reg = {LEN_WIDTH{1'b0}}, req_op_count_next;
reg [LEN_WIDTH-1:0] req_tlp_count_reg = {LEN_WIDTH{1'b0}}, req_tlp_count_next;

reg [11:0] lower_addr_reg = 12'd0, lower_addr_next;
reg [12:0] byte_count_reg = 13'd0, byte_count_next;
reg [3:0] error_code_reg = 4'd0, error_code_next;
reg [AXI_ADDR_WIDTH-1:0] axi_addr_reg = {AXI_ADDR_WIDTH{1'b0}}, axi_addr_next;
reg [9:0] op_dword_count_reg = 10'd0, op_dword_count_next;
reg [12:0] op_count_reg = 13'd0, op_count_next;
reg [12:0] tr_count_reg = 13'd0, tr_count_next;
reg [11:0] input_cycle_count_reg = 12'd0, input_cycle_count_next;
reg [11:0] output_cycle_count_reg = 12'd0, output_cycle_count_next;
reg input_active_reg = 1'b0, input_active_next;
reg bubble_cycle_reg = 1'b0, bubble_cycle_next;
reg first_cycle_reg = 1'b0, first_cycle_next;
reg last_cycle_reg = 1'b0, last_cycle_next;
reg [PCIE_TAG_WIDTH-1:0] pcie_tag_reg = {PCIE_TAG_WIDTH{1'b0}}, pcie_tag_next;
reg [TAG_WIDTH-1:0] tag_reg = {TAG_WIDTH{1'b0}}, tag_next;
reg final_cpl_reg = 1'b0, final_cpl_next;

reg [OFFSET_WIDTH-1:0] offset_reg = {OFFSET_WIDTH{1'b0}}, offset_next;
reg [OFFSET_WIDTH-1:0] first_cycle_offset_reg = {OFFSET_WIDTH{1'b0}}, first_cycle_offset_next;
reg [OFFSET_WIDTH-1:0] last_cycle_offset_reg = {OFFSET_WIDTH{1'b0}}, last_cycle_offset_next;

reg [AXI_ADDR_WIDTH-1:0] tlp_cmd_addr_reg = {AXI_ADDR_WIDTH{1'b0}}, tlp_cmd_addr_next;
reg [TAG_WIDTH-1:0] tlp_cmd_tag_reg = {TAG_WIDTH{1'b0}}, tlp_cmd_tag_next;
reg [PCIE_TAG_WIDTH-1:0] tlp_cmd_pcie_tag_reg = {PCIE_TAG_WIDTH{1'b0}}, tlp_cmd_pcie_tag_next;
reg tlp_cmd_last_reg = 1'b0, tlp_cmd_last_next;
reg tlp_cmd_valid_reg = 1'b0, tlp_cmd_valid_next;

reg [AXI_ADDR_WIDTH-1:0] tag_table_axi_addr[(2**PCIE_TAG_WIDTH)-1:0];
reg [TAG_WIDTH-1:0] tag_table_tag[(2**PCIE_TAG_WIDTH)-1:0];
reg tag_table_last[(2**PCIE_TAG_WIDTH)-1:0];

reg [10:0] max_read_request_size_dw_reg = 11'd0;

reg s_axis_rc_tready_reg = 1'b0, s_axis_rc_tready_next;
reg s_axis_read_desc_ready_reg = 1'b0, s_axis_read_desc_ready_next;

reg [TAG_WIDTH-1:0] m_axis_read_desc_status_tag_reg = {TAG_WIDTH{1'b0}}, m_axis_read_desc_status_tag_next;
reg m_axis_read_desc_status_valid_reg = 1'b0, m_axis_read_desc_status_valid_next;

reg [AXI_ADDR_WIDTH-1:0] m_axi_awaddr_reg = {AXI_ADDR_WIDTH{1'b0}}, m_axi_awaddr_next;
reg [7:0] m_axi_awlen_reg = 8'd0, m_axi_awlen_next;
reg m_axi_awvalid_reg = 1'b0, m_axi_awvalid_next;
reg m_axi_bready_reg = 1'b0, m_axi_bready_next;

reg status_error_cor_reg = 1'b0, status_error_cor_next;
reg status_error_uncor_reg = 1'b0, status_error_uncor_next;

reg [AXIS_PCIE_DATA_WIDTH-1:0] save_axis_tdata_reg = {AXIS_PCIE_DATA_WIDTH{1'b0}};

wire [AXI_DATA_WIDTH-1:0] shift_axis_tdata = {s_axis_rc_tdata, save_axis_tdata_reg} >> ((AXI_STRB_WIDTH-offset_reg)*AXI_WORD_SIZE);

// internal datapath
reg  [AXIS_PCIE_DATA_WIDTH-1:0] m_axis_rq_tdata_int;
reg  [AXIS_PCIE_KEEP_WIDTH-1:0] m_axis_rq_tkeep_int;
reg                             m_axis_rq_tvalid_int;
reg                             m_axis_rq_tready_int_reg = 1'b0;
reg                             m_axis_rq_tlast_int;
reg  [59:0]                     m_axis_rq_tuser_int;
wire                            m_axis_rq_tready_int_early;

reg  [AXI_DATA_WIDTH-1:0]  m_axi_wdata_int;
reg  [AXI_STRB_WIDTH-1:0]  m_axi_wstrb_int;
reg                        m_axi_wvalid_int;
reg                        m_axi_wready_int_reg = 1'b0;
reg                        m_axi_wlast_int;
wire                       m_axi_wready_int_early;

assign s_axis_rc_tready = s_axis_rc_tready_reg;
assign s_axis_read_desc_ready = s_axis_read_desc_ready_reg;

assign m_axis_read_desc_status_tag = m_axis_read_desc_status_tag_reg;
assign m_axis_read_desc_status_valid = m_axis_read_desc_status_valid_reg;

assign m_axi_awid = {AXI_ID_WIDTH{1'b0}};
assign m_axi_awaddr = m_axi_awaddr_reg;
assign m_axi_awlen = m_axi_awlen_reg;
assign m_axi_awsize = $clog2(AXI_STRB_WIDTH);
assign m_axi_awburst = 2'b01;
assign m_axi_awlock = 1'b0;
assign m_axi_awcache = 4'b0011;
assign m_axi_awprot = 3'b010;
assign m_axi_awvalid = m_axi_awvalid_reg;
assign m_axi_bready = 1'b1;//m_axi_bready_reg;

assign status_error_cor = status_error_cor_reg;
assign status_error_uncor = status_error_uncor_reg;

wire [PCIE_ADDR_WIDTH-1:0] req_pcie_addr_plus_max_read_request = req_pcie_addr_reg + {max_read_request_size_dw_reg, 2'b00};
wire [PCIE_ADDR_WIDTH-1:0] req_pcie_addr_plus_op_count = req_pcie_addr_reg + req_op_count_reg;
wire [PCIE_ADDR_WIDTH-1:0] req_pcie_addr_plus_tlp_count = req_pcie_addr_reg + req_tlp_count_reg;

wire [AXI_ADDR_WIDTH-1:0] axi_addr_plus_max_burst = axi_addr_reg + AXI_MAX_BURST_SIZE;
wire [AXI_ADDR_WIDTH-1:0] axi_addr_plus_op_count = axi_addr_reg + op_count_reg;

wire [3:0] first_be = 4'b1111 << req_pcie_addr_reg[1:0];
wire [3:0] last_be = 4'b1111 >> (3 - ((req_pcie_addr_reg[1:0] + req_tlp_count_next[1:0] - 1) & 3));
wire [10:0] dword_count = (req_tlp_count_next + req_pcie_addr_reg[1:0] + 3) >> 2;

wire [PCIE_TAG_WIDTH-1:0] new_tag;
wire new_tag_valid;
reg new_tag_ready;

wire [PCIE_TAG_COUNT-1:0] active_tags;

pcie_tag_manager #(
    .PCIE_TAG_WIDTH(PCIE_TAG_WIDTH),
    .PCIE_TAG_COUNT(PCIE_TAG_COUNT),
    .PCIE_EXT_TAG_ENABLE(PCIE_EXT_TAG_ENABLE)
)
pcie_tag_manager_inst (
    .clk(clk),
    .rst(rst),

    .m_axis_tag(new_tag),
    .m_axis_tag_valid(new_tag_valid),
    .m_axis_tag_ready(new_tag_ready),

    .s_axis_tag(pcie_tag_reg),
    .s_axis_tag_valid(finish_tag),

    .ext_tag_enable(ext_tag_enable),

    .active_tags(active_tags)
);

always @* begin
    req_state_next = REQ_STATE_IDLE;

    s_axis_read_desc_ready_next = 1'b0;

    req_pcie_addr_next = req_pcie_addr_reg;
    req_axi_addr_next = req_axi_addr_reg;
    req_op_count_next = req_op_count_reg;
    req_tlp_count_next = req_tlp_count_reg;

    tlp_cmd_addr_next = tlp_cmd_addr_reg;
    tlp_cmd_tag_next = tlp_cmd_tag_reg;
    tlp_cmd_pcie_tag_next = tlp_cmd_pcie_tag_reg;
    tlp_cmd_last_next = tlp_cmd_last_reg;
    tlp_cmd_valid_next = tlp_cmd_valid_reg && !tlp_cmd_ready;

    m_axis_rq_tdata_int = {AXIS_PCIE_DATA_WIDTH{1'b0}};
    m_axis_rq_tkeep_int = {AXIS_PCIE_KEEP_WIDTH{1'b0}};
    m_axis_rq_tvalid_int = 1'b0;
    if (AXIS_PCIE_DATA_WIDTH > 64) begin
        m_axis_rq_tlast_int = 1'b1;
    end else begin
        m_axis_rq_tlast_int = 1'b0;
    end
    m_axis_rq_tuser_int = 60'd0;

    m_axis_rq_tdata_int[1:0] = 2'b0; // address type
    m_axis_rq_tdata_int[63:2] = req_pcie_addr_reg[PCIE_ADDR_WIDTH-1:2]; // address
    if (AXIS_PCIE_DATA_WIDTH > 64) begin
        m_axis_rq_tdata_int[74:64] = dword_count; // DWORD count
        m_axis_rq_tdata_int[78:75] = REQ_MEM_READ; // request type - memory read
        m_axis_rq_tdata_int[79] = 1'b0; // poisoned request
        m_axis_rq_tdata_int[95:80] = requester_id;
        m_axis_rq_tdata_int[103:96] = new_tag;
        m_axis_rq_tdata_int[119:104] = 16'd0; // completer ID
        m_axis_rq_tdata_int[120] = requester_id_enable;
        m_axis_rq_tdata_int[123:121] = 3'b000; // traffic class
        m_axis_rq_tdata_int[126:124] = 3'b000; // attr
        m_axis_rq_tdata_int[127] = 1'b0; // force ECRC
    end

    if (AXIS_PCIE_DATA_WIDTH == 256) begin
        m_axis_rq_tkeep_int = 8'b00001111;
    end else if (AXIS_PCIE_DATA_WIDTH == 128) begin
        m_axis_rq_tkeep_int = 4'b1111;
    end else begin
        m_axis_rq_tkeep_int = 2'b11;
    end

    m_axis_rq_tuser_int[3:0] = dword_count == 1 ? first_be & last_be : first_be; // first BE
    m_axis_rq_tuser_int[7:4] = dword_count == 1 ? 4'b0000 : last_be; // last BE
    m_axis_rq_tuser_int[10:8] = 3'd0; // addr_offset
    m_axis_rq_tuser_int[11] = 1'b0; // discontinue
    m_axis_rq_tuser_int[12] = 1'b0; // tph_present
    m_axis_rq_tuser_int[14:13] = 2'b00; // tph_type
    m_axis_rq_tuser_int[15] = 1'b0; // tph_indirect_tag_en
    m_axis_rq_tuser_int[23:16] = 8'd0; // tph_st_tag
    m_axis_rq_tuser_int[27:24] = 4'd0; // seq_num
    m_axis_rq_tuser_int[59:28] = 32'd0; // parity

    new_tag_ready = 1'b0;

    // TLP segmentation and request generation
    case (req_state_reg)
        REQ_STATE_IDLE: begin
            s_axis_read_desc_ready_next = enable;

            if (s_axis_read_desc_ready & s_axis_read_desc_valid) begin
                s_axis_read_desc_ready_next = 1'b0;
                req_pcie_addr_next = s_axis_read_desc_pcie_addr;
                req_axi_addr_next = s_axis_read_desc_axi_addr;
                req_op_count_next = s_axis_read_desc_len;
                tlp_cmd_tag_next = s_axis_read_desc_tag;
                req_state_next = REQ_STATE_START;
            end else begin
                req_state_next = REQ_STATE_IDLE;
            end
        end
        REQ_STATE_START: begin
            if (m_axis_rq_tready_int_reg && !tlp_cmd_valid_reg) begin
                if (req_op_count_reg <= {max_read_request_size_dw_reg, 2'b00}-req_pcie_addr_reg[1:0]) begin
                    // packet smaller than max read request size
                    if (req_pcie_addr_reg[12] != req_pcie_addr_plus_op_count[12]) begin
                        // crosses 4k boundary
                        req_tlp_count_next = 13'h1000 - req_pcie_addr_reg[11:0];
                    end else begin
                        // does not cross 4k boundary, send one TLP
                        req_tlp_count_next = req_op_count_reg;
                    end
                end else begin
                    // packet larger than max read request size
                    if (req_pcie_addr_reg[12] != req_pcie_addr_plus_max_read_request[12]) begin
                        // crosses 4k boundary
                        req_tlp_count_next = 13'h1000 - req_pcie_addr_reg[11:0];
                    end else begin
                        // does not cross 4k boundary, send one TLP
                        req_tlp_count_next = {max_read_request_size_dw_reg, 2'b00}-req_pcie_addr_reg[1:0];
                    end
                end

                m_axis_rq_tvalid_int = 1'b1;

                if (AXIS_PCIE_DATA_WIDTH > 64) begin
                    req_pcie_addr_next = req_pcie_addr_reg + req_tlp_count_next;
                    req_axi_addr_next = req_axi_addr_reg + req_tlp_count_next;
                    req_op_count_next = req_op_count_reg - req_tlp_count_next;

                    new_tag_ready = 1'b1;

                    tlp_cmd_addr_next = req_axi_addr_reg;
                    tlp_cmd_pcie_tag_next = new_tag;
                    tlp_cmd_last_next = req_op_count_next == 0;
                    tlp_cmd_valid_next = 1'b1;

                    if (req_op_count_next > 0) begin
                        req_state_next = REQ_STATE_START;
                    end else begin
                        s_axis_read_desc_ready_next = enable;
                        req_state_next = REQ_STATE_IDLE;
                    end
                end else begin
                    req_state_next = REQ_STATE_HEADER;
                end
            end else begin
                req_state_next = REQ_STATE_START;
            end
        end
        REQ_STATE_HEADER: begin
            if (m_axis_rq_tready_int_reg) begin
                req_pcie_addr_next = req_pcie_addr_reg + req_tlp_count_next;
                req_axi_addr_next = req_axi_addr_reg + req_tlp_count_next;
                req_op_count_next = req_op_count_reg - req_tlp_count_next;

                new_tag_ready = 1'b1;

                m_axis_rq_tdata_int[10:0] = dword_count; // DWORD count
                m_axis_rq_tdata_int[14:11] = REQ_MEM_READ; // request type - memory read
                m_axis_rq_tdata_int[15] = 1'b0; // poisoned request
                m_axis_rq_tdata_int[31:16] = requester_id;
                m_axis_rq_tdata_int[40:32] = new_tag;
                m_axis_rq_tdata_int[55:41] = 16'd0; // completer ID
                m_axis_rq_tdata_int[56] = requester_id_enable;
                m_axis_rq_tdata_int[59:57] = 3'b000; // traffic class
                m_axis_rq_tdata_int[62:60] = 3'b000; // attr
                m_axis_rq_tdata_int[63] = 1'b0; // force ECRC
                m_axis_rq_tlast_int = 1'b1;
                m_axis_rq_tvalid_int = 1'b1;

                tlp_cmd_addr_next = req_axi_addr_reg;
                tlp_cmd_pcie_tag_next = new_tag;
                tlp_cmd_last_next = req_op_count_next == 0;
                tlp_cmd_valid_next = 1'b1;

                if (req_op_count_next > 0) begin
                    req_state_next = REQ_STATE_START;
                end else begin
                    s_axis_read_desc_ready_next = enable;
                    req_state_next = REQ_STATE_IDLE;
                end
            end else begin
                req_state_next = REQ_STATE_HEADER;
            end
        end
    endcase
end

reg transfer_is_idle = 1'b0;

always @* begin
    tlp_state_next = TLP_STATE_IDLE;

    transfer_in_save = 1'b0;

    finish_tag = 1'b0;

    tag_table_we_tlp = 1'b0;

    s_axis_rc_tready_next = 1'b0;

    m_axis_read_desc_status_tag_next = m_axis_read_desc_status_tag_reg;
    m_axis_read_desc_status_valid_next = 1'b0;

    lower_addr_next = lower_addr_reg;
    byte_count_next = byte_count_reg;
    error_code_next = error_code_reg;
    axi_addr_next = axi_addr_reg;
    op_count_next = op_count_reg;
    tr_count_next = tr_count_reg;
    op_dword_count_next = op_dword_count_reg;
    input_cycle_count_next = input_cycle_count_reg;
    output_cycle_count_next = output_cycle_count_reg;
    input_active_next = input_active_reg;
    bubble_cycle_next = bubble_cycle_reg;
    first_cycle_next = first_cycle_reg;
    last_cycle_next = last_cycle_reg;
    pcie_tag_next = pcie_tag_reg;
    tag_next = tag_reg;
    final_cpl_next = final_cpl_reg;
    offset_next = offset_reg;
    first_cycle_offset_next = first_cycle_offset_reg;
    last_cycle_offset_next = last_cycle_offset_reg;

    m_axi_awaddr_next = m_axi_awaddr_reg;
    m_axi_awlen_next = m_axi_awlen_reg;
    m_axi_awvalid_next = m_axi_awvalid_reg && !m_axi_awready;
    m_axi_bready_next = 1'b0;

    m_axi_wdata_int = shift_axis_tdata;
    m_axi_wstrb_int = {AXI_STRB_WIDTH{1'b1}};
    m_axi_wvalid_int = 1'b0;
    m_axi_wlast_int = 1'b0;

    status_error_cor_next = 1'b0;
    status_error_uncor_next = 1'b0;

    transfer_is_idle = 1'b0;

    // TLP response handling and AXI operation generation
    case (tlp_state_reg)
        TLP_STATE_IDLE: begin
            // idle state, wait for completion
            if (AXIS_PCIE_DATA_WIDTH > 64) begin
                s_axis_rc_tready_next = 1'b0;

                if (s_axis_rc_tvalid) begin
                    // header fields
                    lower_addr_next = s_axis_rc_tdata[11:0]; // lower address
                    error_code_next = s_axis_rc_tdata[15:12]; // error code
                    byte_count_next = s_axis_rc_tdata[28:16]; // byte count
                    //s_axis_rc_tdata[29]; // locked read
                    //s_axis_rc_tdata[30]; // request completed
                    op_dword_count_next = s_axis_rc_tdata[42:32]; // DWORD count
                    //s_axis_rc_tdata[45:43]; // completion status
                    //s_axis_rc_tdata[46]; // poisoned completion
                    //s_axis_rc_tdata[63:48]; // requester ID
                    pcie_tag_next = s_axis_rc_tdata[71:64]; // tag
                    //s_axis_rc_tdata[87:72]; // completer ID
                    //s_axis_rc_tdata[91:89]; // attr
                    //s_axis_rc_tdata[94:92]; // tc

                    // tuser fields
                    //s_axis_rc_tuser[31:0]; // byte enables
                    //s_axis_rc_tuser[32]; // is_sof_0
                    //s_axis_rc_tuser[33]; // is_sof_1
                    //s_axis_rc_tuser[37:34]; // is_eof_0
                    //s_axis_rc_tuser[41:38]; // is_eof_1
                    //s_axis_rc_tuser[42]; // discontinue
                    //s_axis_rc_tuser[74:43]; // parity

                    if (byte_count_next > (op_dword_count_next << 2)) begin
                        // more completions to follow
                        op_count_next = (op_dword_count_next << 2) - lower_addr_next[1:0];
                        final_cpl_next = 1'b0;
                    end else begin
                        // last completion
                        op_count_next = byte_count_next;
                        final_cpl_next = 1'b1;
                    end

                    axi_addr_next = tag_table_axi_addr[pcie_tag_next];

                    offset_next = axi_addr_next[OFFSET_WIDTH-1:0] - (12+lower_addr_next[1:0]);
                    bubble_cycle_next = axi_addr_next[OFFSET_WIDTH-1:0] < 12+lower_addr_next[1:0];
                    first_cycle_offset_next = axi_addr_next[OFFSET_WIDTH-1:0];
                    first_cycle_next = 1'b1;

                    if (active_tags[pcie_tag_next] && error_code_next == RC_ERROR_NORMAL_TERMINATION) begin
                        // no error
                        s_axis_rc_tready_next = !m_axi_awvalid || m_axi_awready;
                        tlp_state_next = TLP_STATE_START;
                    end else if (error_code_next == RC_ERROR_MISMATCH) begin
                        // mismatched fields
                        // Handle as malformed TLP (2.3.2)
                        // drop TLP and report uncorrectable error
                        status_error_uncor_next = 1'b1;
                        s_axis_rc_tready_next = 1'b1;
                        tlp_state_next = TLP_STATE_WAIT_END;
                    end else if (!active_tags[pcie_tag_next]|| error_code_next == RC_ERROR_INVALID_TAG) begin
                        // invalid tag
                        // Handle as unexpected completion (2.3.2), advisory non-fatal (6.2.3.2.4.5)
                        // drop TLP and report correctable error
                        status_error_cor_next = 1'b1;
                        s_axis_rc_tready_next = 1'b1;
                        tlp_state_next = TLP_STATE_WAIT_END;
                    end else begin
                        // request terminated by other error (tag valid)
                        // report error
                        case (error_code_next)
                            RC_ERROR_POISONED: status_error_cor_next = 1'b1; // advisory non-fatal (6.2.3.2.4.3)
                            RC_ERROR_BAD_STATUS: status_error_cor_next = 1'b1; // advisory non-fatal (6.2.3.2.4.1)
                            RC_ERROR_INVALID_LENGTH: status_error_cor_next = 1'b1; // unexpected completion (2.3.2), advisory non-fatal (6.2.3.2.4.5)
                            RC_ERROR_MISMATCH: status_error_uncor_next = 1'b1; // malformed TLP (2.3.2)
                            RC_ERROR_INVALID_ADDRESS: status_error_cor_next = 1'b1; // unexpected completion (2.3.2), advisory non-fatal (6.2.3.2.4.5)
                            RC_ERROR_INVALID_TAG: status_error_cor_next = 1'b1; // unexpected completion (2.3.2), advisory non-fatal (6.2.3.2.4.5)
                            RC_ERROR_TIMEOUT: status_error_uncor_next = 1'b1; // uncorrectable (6.2.3.2.4.4)
                            RC_ERROR_FLR: status_error_cor_next = 1'b1; // unexpected completion (2.3.2), advisory non-fatal (6.2.3.2.4.5)
                            default: status_error_uncor_next = 1'b1;
                        endcase
                        // release tag
                        finish_tag = 1'b1;
                        // last request in current transfer
                        m_axis_read_desc_status_tag_next = tag_table_tag[pcie_tag_next];
                        m_axis_read_desc_status_valid_next = 1'b1;
                        // drop TLP
                        s_axis_rc_tready_next = 1'b1;
                        tlp_state_next = TLP_STATE_WAIT_END;
                    end
                end else begin
                    tlp_state_next = TLP_STATE_IDLE;
                end
            end else begin
                s_axis_rc_tready_next = !m_axi_awvalid || m_axi_awready;

                if (s_axis_rc_tready && s_axis_rc_tvalid) begin
                    // header fields
                    lower_addr_next = s_axis_rc_tdata[11:0]; // lower address
                    error_code_next = s_axis_rc_tdata[15:12]; // error code
                    byte_count_next = s_axis_rc_tdata[28:16]; // byte count
                    //s_axis_rc_tdata[29]; // locked read
                    //s_axis_rc_tdata[30]; // request completed
                    op_dword_count_next = s_axis_rc_tdata[42:32]; // DWORD count
                    //s_axis_rc_tdata[45:43]; // completion status
                    //s_axis_rc_tdata[46]; // poisoned completion
                    //s_axis_rc_tdata[63:48]; // requester ID

                    // tuser fields
                    //s_axis_rc_tuser[31:0]; // byte enables
                    //s_axis_rc_tuser[32]; // is_sof_0
                    //s_axis_rc_tuser[33]; // is_sof_1
                    //s_axis_rc_tuser[37:34]; // is_eof_0
                    //s_axis_rc_tuser[41:38]; // is_eof_1
                    //s_axis_rc_tuser[42]; // discontinue
                    //s_axis_rc_tuser[74:43]; // parity

                    if (byte_count_next > (op_dword_count_next << 2)) begin
                        // more completions to follow
                        op_count_next = (op_dword_count_next << 2) - lower_addr_next[1:0];
                        final_cpl_next = 1'b0;
                    end else begin
                        // last completion
                        op_count_next = byte_count_next;
                        final_cpl_next = 1'b1;
                    end

                    s_axis_rc_tready_next = 1'b0;
                    if (s_axis_rc_tlast) begin
                        tlp_state_next = TLP_STATE_IDLE;
                    end else begin
                        tlp_state_next = TLP_STATE_HEADER;
                    end
                end else begin
                    tlp_state_next = TLP_STATE_IDLE;
                end
            end
        end
        TLP_STATE_HEADER: begin
            // header state; process header (64 bit interface only)
            s_axis_rc_tready_next = 1'b0;

            if (s_axis_rc_tvalid) begin
                pcie_tag_next = s_axis_rc_tdata[7:0]; // tag
                //s_axis_rc_tdata[23:8]; // completer ID
                //s_axis_rc_tdata[27:25]; // attr
                //s_axis_rc_tdata[30:28]; // tc

                axi_addr_next = tag_table_axi_addr[pcie_tag_next];

                offset_next = axi_addr_next[OFFSET_WIDTH-1:0] - (4+lower_addr_reg[1:0]);
                bubble_cycle_next = axi_addr_next[OFFSET_WIDTH-1:0] < 4+lower_addr_reg[1:0];
                first_cycle_offset_next = axi_addr_next[OFFSET_WIDTH-1:0];
                first_cycle_next = 1'b1;

                if (active_tags[pcie_tag_next] && error_code_reg == RC_ERROR_NORMAL_TERMINATION) begin
                    // no error
                    s_axis_rc_tready_next = !m_axi_awvalid || m_axi_awready;
                    tlp_state_next = TLP_STATE_START;
                end else if (error_code_next == RC_ERROR_MISMATCH) begin
                    // mismatched fields
                    // Handle as malformed TLP (2.3.2)
                    // drop TLP and report uncorrectable error
                    status_error_uncor_next = 1'b1;
                    s_axis_rc_tready_next = 1'b1;
                    tlp_state_next = TLP_STATE_WAIT_END;
                end else if (!active_tags[pcie_tag_reg] || error_code_next == RC_ERROR_INVALID_TAG) begin
                    // invalid tag or mismatched fields (tag invalid)
                    // Handle as unexpected completion (2.3.2), advisory non-fatal (6.2.3.2.4.5)
                    // drop TLP and report correctable error
                    status_error_cor_next = 1'b1;
                    s_axis_rc_tready_next = 1'b1;
                    tlp_state_next = TLP_STATE_WAIT_END;
                end else begin
                    // request terminated by other error (tag valid)
                    // report error
                    case (error_code_next)
                        RC_ERROR_POISONED: status_error_cor_next = 1'b1; // advisory non-fatal (6.2.3.2.4.3)
                        RC_ERROR_BAD_STATUS: status_error_cor_next = 1'b1; // advisory non-fatal (6.2.3.2.4.1)
                        RC_ERROR_INVALID_LENGTH: status_error_cor_next = 1'b1; // unexpected completion (2.3.2), advisory non-fatal (6.2.3.2.4.5)
                        RC_ERROR_MISMATCH: status_error_uncor_next = 1'b1; // malformed TLP (2.3.2)
                        RC_ERROR_INVALID_ADDRESS: status_error_cor_next = 1'b1; // unexpected completion (2.3.2), advisory non-fatal (6.2.3.2.4.5)
                        RC_ERROR_INVALID_TAG: status_error_cor_next = 1'b1; // unexpected completion (2.3.2), advisory non-fatal (6.2.3.2.4.5)
                        RC_ERROR_TIMEOUT: status_error_uncor_next = 1'b1; // uncorrectable (6.2.3.2.4.4)
                        RC_ERROR_FLR: status_error_cor_next = 1'b1; // unexpected completion (2.3.2), advisory non-fatal (6.2.3.2.4.5)
                        default: status_error_uncor_next = 1'b1;
                    endcase
                    // release tag
                    finish_tag = 1'b1;
                    // last request in current transfer
                    m_axis_read_desc_status_tag_next = tag_table_tag[pcie_tag_reg];
                    m_axis_read_desc_status_valid_next = 1'b1;
                    // drop TLP
                    s_axis_rc_tready_next = 1'b1;
                    tlp_state_next = TLP_STATE_WAIT_END;
                end
            end else begin
                tlp_state_next = TLP_STATE_HEADER;
            end
        end
        TLP_STATE_START: begin
            s_axis_rc_tready_next = !m_axi_awvalid || m_axi_awready;

            if (s_axis_rc_tready && s_axis_rc_tvalid) begin
                transfer_in_save = 1'b1;

                if (op_count_reg <= AXI_MAX_BURST_SIZE-axi_addr_reg[1:0]) begin
                    // packet smaller than max burst size
                    if (axi_addr_reg[12] != axi_addr_plus_op_count[12]) begin
                        // crosses 4k boundary
                        tr_count_next = 13'h1000 - axi_addr_reg[11:0];
                        m_axi_awlen_next = (tr_count_next - 1) >> AXI_BURST_SIZE;
                    end else begin
                        // does not cross 4k boundary, send one request
                        tr_count_next = op_count_reg;
                        m_axi_awlen_next = (tr_count_next + axi_addr_reg[OFFSET_WIDTH-1:0] - 1) >> AXI_BURST_SIZE;
                    end
                end else begin
                    // packet larger than max burst size
                    if (axi_addr_reg[12] != axi_addr_plus_max_burst[12]) begin
                        // crosses 4k boundary
                        tr_count_next = 13'h1000 - axi_addr_reg[11:0];
                        m_axi_awlen_next = (tr_count_next - 1) >> AXI_BURST_SIZE;
                    end else begin
                        // does not cross 4k boundary, send one request
                        tr_count_next = AXI_MAX_BURST_SIZE - axi_addr_reg[OFFSET_WIDTH-1:0];
                        m_axi_awlen_next = (tr_count_next - 1) >> AXI_BURST_SIZE;
                    end
                end

                m_axi_awaddr_next = axi_addr_reg;

                if (AXIS_PCIE_DATA_WIDTH == 64) begin
                    input_cycle_count_next = (tr_count_next + 4+lower_addr_reg[1:0] - 1) >> (AXI_BURST_SIZE);
                end else begin
                    input_cycle_count_next = (tr_count_next + 12+lower_addr_reg[1:0] - 1) >> (AXI_BURST_SIZE);
                end
                output_cycle_count_next = (tr_count_next + axi_addr_reg[OFFSET_WIDTH-1:0] - 1) >> (AXI_BURST_SIZE);
                last_cycle_offset_next = axi_addr_reg[OFFSET_WIDTH-1:0] + tr_count_next;
                last_cycle_next = output_cycle_count_next == 0;
                input_active_next = 1'b1;

                axi_addr_next = axi_addr_reg + tr_count_next;
                op_count_next = op_count_reg - tr_count_next;

                m_axi_awvalid_next = 1'b1;

                input_active_next = input_cycle_count_next > 0;
                input_cycle_count_next = input_cycle_count_next - 1;
                s_axis_rc_tready_next = m_axi_wready_int_early && input_active_next && bubble_cycle_reg;
                tlp_state_next = TLP_STATE_TRANSFER;
            end else begin
                tlp_state_next = TLP_STATE_START;
            end
        end
        TLP_STATE_TRANSFER: begin
            s_axis_rc_tready_next = m_axi_wready_int_early && input_active_reg && !(first_cycle_reg && !bubble_cycle_reg);

            if (m_axi_wready_int_reg && ((s_axis_rc_tready && s_axis_rc_tvalid) || !input_active_reg || (first_cycle_reg && !bubble_cycle_reg))) begin
                transfer_in_save = s_axis_rc_tready && s_axis_rc_tvalid;

                if (first_cycle_reg && !bubble_cycle_reg) begin
                    m_axi_wdata_int = {save_axis_tdata_reg, {AXIS_PCIE_DATA_WIDTH{1'b0}}} >> ((AXI_STRB_WIDTH-offset_reg)*8);
                    s_axis_rc_tready_next = m_axi_wready_int_early && input_active_reg;
                end else begin
                    m_axi_wdata_int = shift_axis_tdata;
                end
                if (first_cycle_reg) begin
                    m_axi_wstrb_int = {AXI_STRB_WIDTH{1'b1}} << first_cycle_offset_reg;
                end else begin
                    m_axi_wstrb_int = {AXI_STRB_WIDTH{1'b1}};
                end

                if (input_active_reg && !(first_cycle_reg && !bubble_cycle_reg)) begin
                    input_cycle_count_next = input_cycle_count_reg - 1;
                    input_active_next = input_cycle_count_reg > 0;
                end
                output_cycle_count_next = output_cycle_count_reg - 1;
                last_cycle_next = output_cycle_count_next == 0;

                if (last_cycle_reg) begin
                    if (last_cycle_offset_reg > 0 && op_count_reg == 0) begin
                        m_axi_wstrb_int = m_axi_wstrb_int & {AXI_STRB_WIDTH{1'b1}} >> (AXI_STRB_WIDTH-last_cycle_offset_reg);
                    end
                    m_axi_wlast_int = 1'b1;
                end
                m_axi_wvalid_int = 1'b1;
                first_cycle_next = 1'b0;
                if (!last_cycle_reg) begin
                    // current transfer not finished yet
                    s_axis_rc_tready_next = m_axi_wready_int_early && input_active_next;
                    tlp_state_next = TLP_STATE_TRANSFER;
                end else if (op_count_reg > 0) begin
                    // current transfer done, but operation not finished yet
                    if (op_count_reg <= AXI_MAX_BURST_SIZE-axi_addr_reg[1:0]) begin
                        // packet smaller than max burst size
                        if (axi_addr_reg[12] != axi_addr_plus_op_count[12]) begin
                            // crosses 4k boundary
                            tr_count_next = 13'h1000 - axi_addr_reg[11:0];
                            m_axi_awlen_next = (tr_count_next - 1) >> AXI_BURST_SIZE;
                        end else begin
                            // does not cross 4k boundary, send one request
                            tr_count_next = op_count_reg;
                            m_axi_awlen_next = (tr_count_next + axi_addr_reg[OFFSET_WIDTH-1:0] - 1) >> AXI_BURST_SIZE;
                        end
                    end else begin
                        // packet larger than max burst size
                        if (axi_addr_reg[12] != axi_addr_plus_max_burst[12]) begin
                            // crosses 4k boundary
                            tr_count_next = 13'h1000 - axi_addr_reg[11:0];
                            m_axi_awlen_next = (tr_count_next - 1) >> AXI_BURST_SIZE;
                        end else begin
                            // does not cross 4k boundary, send one request
                            tr_count_next = AXI_MAX_BURST_SIZE - axi_addr_reg[OFFSET_WIDTH-1:0];
                            m_axi_awlen_next = (tr_count_next - 1) >> AXI_BURST_SIZE;
                        end
                    end

                    m_axi_awaddr_next = axi_addr_reg;

                    // keep offset, no bubble cycles, not first cycle
                    bubble_cycle_next = 1'b0;
                    first_cycle_next = 1'b0;

                    input_cycle_count_next = (tr_count_next - offset_reg - 1) >> (AXI_BURST_SIZE);
                    output_cycle_count_next = (tr_count_next + axi_addr_reg[OFFSET_WIDTH-1:0] - 1) >> (AXI_BURST_SIZE);
                    last_cycle_offset_next = axi_addr_reg[OFFSET_WIDTH-1:0] + tr_count_next;
                    last_cycle_next = output_cycle_count_next == 0;
                    input_active_next = tr_count_next > offset_reg;

                    axi_addr_next = axi_addr_reg + tr_count_next;
                    op_count_next = op_count_reg - tr_count_next;

                    m_axi_awvalid_next = 1'b1;
                    s_axis_rc_tready_next = m_axi_wready_int_early && input_active_next;
                    tlp_state_next = TLP_STATE_TRANSFER;
                end else begin
                    if (final_cpl_reg) begin
                        // last completion in current read request (PCIe tag)
                        finish_tag = 1'b1; // release tag
                        if (tag_table_last[pcie_tag_reg]) begin
                            // last request in current transfer
                            m_axis_read_desc_status_tag_next = tag_table_tag[pcie_tag_reg];
                            m_axis_read_desc_status_valid_next = 1'b1;
                        end
                    end else begin
                        // more completions to come, store current address
                        tag_table_we_tlp = 1'b1;
                    end
                    if (AXIS_PCIE_DATA_WIDTH > 64) begin
                        s_axis_rc_tready_next = 1'b0;
                    end else begin
                        s_axis_rc_tready_next = 1'b1;
                    end
                    tlp_state_next = TLP_STATE_IDLE;
                end
            end else begin
                transfer_is_idle = 1'b1;
                tlp_state_next = TLP_STATE_TRANSFER;
            end
        end
        TLP_STATE_WAIT_END: begin
            // wait end state, wait for end of TLP
            s_axis_rc_tready_next = 1'b1;

            if (s_axis_rc_tready & s_axis_rc_tvalid) begin
                if (s_axis_rc_tlast) begin
                    if (AXIS_PCIE_DATA_WIDTH > 64) begin
                        s_axis_rc_tready_next = 1'b0;
                    end else begin
                        s_axis_rc_tready_next = 1'b1;
                    end
                    tlp_state_next = TLP_STATE_IDLE;
                end else begin
                    tlp_state_next = TLP_STATE_WAIT_END;
                end
            end else begin
                tlp_state_next = TLP_STATE_WAIT_END;
            end
        end
    endcase
end

always @* begin
    tag_table_we_req = 1'b0;
    tlp_cmd_ready = 1'b0;

    // tag table write management
    if (tag_table_we_tlp) begin
        
    end else if (tlp_cmd_valid_reg) begin
        tlp_cmd_ready = 1'b1;
        tag_table_we_req = 1'b1;
    end
end

always @(posedge clk) begin
    if (rst) begin
        req_state_reg <= REQ_STATE_IDLE;
        tlp_state_reg <= TLP_STATE_IDLE;
        tlp_cmd_valid_reg <= 1'b0;
        s_axis_rc_tready_reg <= 1'b0;
        s_axis_read_desc_ready_reg <= 1'b0;
        m_axis_read_desc_status_valid_reg <= 1'b0;
        m_axi_awvalid_reg <= 1'b0;
        m_axi_bready_reg <= 1'b0;

        status_error_cor_reg <= 1'b0;
        status_error_uncor_reg <= 1'b0;
    end else begin
        req_state_reg <= req_state_next;
        tlp_state_reg <= tlp_state_next;
        tlp_cmd_valid_reg <= tlp_cmd_valid_next;
        s_axis_rc_tready_reg <= s_axis_rc_tready_next;
        s_axis_read_desc_ready_reg <= s_axis_read_desc_ready_next;
        m_axis_read_desc_status_valid_reg <= m_axis_read_desc_status_valid_next;
        m_axi_awvalid_reg <= m_axi_awvalid_next;
        m_axi_bready_reg <= m_axi_bready_next;

        status_error_cor_reg <= status_error_cor_next;
        status_error_uncor_reg <= status_error_uncor_next;
    end

    req_pcie_addr_reg <= req_pcie_addr_next;
    req_axi_addr_reg <= req_axi_addr_next;
    req_op_count_reg <= req_op_count_next;
    req_tlp_count_reg <= req_tlp_count_next;

    lower_addr_reg <= lower_addr_next;
    byte_count_reg <= byte_count_next;
    error_code_reg <= error_code_next;
    axi_addr_reg <= axi_addr_next;
    op_count_reg <= op_count_next;
    tr_count_reg <= tr_count_next;
    op_dword_count_reg <= op_dword_count_next;
    input_cycle_count_reg <= input_cycle_count_next;
    output_cycle_count_reg <= output_cycle_count_next;
    input_active_reg <= input_active_next;
    bubble_cycle_reg <= bubble_cycle_next;
    first_cycle_reg <= first_cycle_next;
    last_cycle_reg <= last_cycle_next;
    pcie_tag_reg <= pcie_tag_next;
    final_cpl_reg <= final_cpl_next;

    offset_reg <= offset_next;
    first_cycle_offset_reg <= first_cycle_offset_next;
    last_cycle_offset_reg <= last_cycle_offset_next;

    tlp_cmd_addr_reg <= tlp_cmd_addr_next;
    tlp_cmd_tag_reg <= tlp_cmd_tag_next;
    tlp_cmd_pcie_tag_reg <= tlp_cmd_pcie_tag_next;
    tlp_cmd_last_reg <= tlp_cmd_last_next;

    m_axis_read_desc_status_tag_reg <= m_axis_read_desc_status_tag_next;

    m_axi_awaddr_reg <= m_axi_awaddr_next;
    m_axi_awlen_reg <= m_axi_awlen_next;

    max_read_request_size_dw_reg <= 11'd32 << (max_read_request_size > 5 ? 5 : max_read_request_size);

    if (transfer_in_save) begin
        save_axis_tdata_reg <= s_axis_rc_tdata;
    end

    if (tag_table_we_tlp) begin
        tag_table_axi_addr[pcie_tag_reg] <= axi_addr_next;
    end else if (tlp_cmd_valid_reg && tag_table_we_req) begin
        tag_table_axi_addr[tlp_cmd_pcie_tag_reg] <= tlp_cmd_addr_reg;
        tag_table_tag[tlp_cmd_pcie_tag_reg] <= tlp_cmd_tag_reg;
        tag_table_last[tlp_cmd_pcie_tag_reg] <= tlp_cmd_last_reg;
    end
end

// output datapath logic (PCIe TLP)
reg [AXIS_PCIE_DATA_WIDTH-1:0] m_axis_rq_tdata_reg = {AXIS_PCIE_DATA_WIDTH{1'b0}};
reg [AXIS_PCIE_KEEP_WIDTH-1:0] m_axis_rq_tkeep_reg = {AXIS_PCIE_KEEP_WIDTH{1'b0}};
reg                            m_axis_rq_tvalid_reg = 1'b0, m_axis_rq_tvalid_next;
reg                            m_axis_rq_tlast_reg = 1'b0;
reg [59:0]                     m_axis_rq_tuser_reg = 60'd0;

reg [AXIS_PCIE_DATA_WIDTH-1:0] temp_m_axis_rq_tdata_reg = {AXIS_PCIE_DATA_WIDTH{1'b0}};
reg [AXIS_PCIE_KEEP_WIDTH-1:0] temp_m_axis_rq_tkeep_reg = {AXIS_PCIE_KEEP_WIDTH{1'b0}};
reg                            temp_m_axis_rq_tvalid_reg = 1'b0, temp_m_axis_rq_tvalid_next;
reg                            temp_m_axis_rq_tlast_reg = 1'b0;
reg [59:0]                     temp_m_axis_rq_tuser_reg = 60'd0;

// datapath control
reg store_axis_rq_int_to_output;
reg store_axis_rq_int_to_temp;
reg store_axis_rq_temp_to_output;

assign m_axis_rq_tdata = m_axis_rq_tdata_reg;
assign m_axis_rq_tkeep = m_axis_rq_tkeep_reg;
assign m_axis_rq_tvalid = m_axis_rq_tvalid_reg;
assign m_axis_rq_tlast = m_axis_rq_tlast_reg;
assign m_axis_rq_tuser = m_axis_rq_tuser_reg;

// enable ready input next cycle if output is ready or the temp reg will not be filled on the next cycle (output reg empty or no input)
assign m_axis_rq_tready_int_early = m_axis_rq_tready || (!temp_m_axis_rq_tvalid_reg && (!m_axis_rq_tvalid_reg || !m_axis_rq_tvalid_int));

always @* begin
    // transfer sink ready state to source
    m_axis_rq_tvalid_next = m_axis_rq_tvalid_reg;
    temp_m_axis_rq_tvalid_next = temp_m_axis_rq_tvalid_reg;

    store_axis_rq_int_to_output = 1'b0;
    store_axis_rq_int_to_temp = 1'b0;
    store_axis_rq_temp_to_output = 1'b0;
    
    if (m_axis_rq_tready_int_reg) begin
        // input is ready
        if (m_axis_rq_tready || !m_axis_rq_tvalid_reg) begin
            // output is ready or currently not valid, transfer data to output
            m_axis_rq_tvalid_next = m_axis_rq_tvalid_int;
            store_axis_rq_int_to_output = 1'b1;
        end else begin
            // output is not ready, store input in temp
            temp_m_axis_rq_tvalid_next = m_axis_rq_tvalid_int;
            store_axis_rq_int_to_temp = 1'b1;
        end
    end else if (m_axis_rq_tready) begin
        // input is not ready, but output is ready
        m_axis_rq_tvalid_next = temp_m_axis_rq_tvalid_reg;
        temp_m_axis_rq_tvalid_next = 1'b0;
        store_axis_rq_temp_to_output = 1'b1;
    end
end

always @(posedge clk) begin
    if (rst) begin
        m_axis_rq_tvalid_reg <= 1'b0;
        m_axis_rq_tready_int_reg <= 1'b0;
        temp_m_axis_rq_tvalid_reg <= 1'b0;
    end else begin
        m_axis_rq_tvalid_reg <= m_axis_rq_tvalid_next;
        m_axis_rq_tready_int_reg <= m_axis_rq_tready_int_early;
        temp_m_axis_rq_tvalid_reg <= temp_m_axis_rq_tvalid_next;
    end

    // datapath
    if (store_axis_rq_int_to_output) begin
        m_axis_rq_tdata_reg <= m_axis_rq_tdata_int;
        m_axis_rq_tkeep_reg <= m_axis_rq_tkeep_int;
        m_axis_rq_tlast_reg <= m_axis_rq_tlast_int;
        m_axis_rq_tuser_reg <= m_axis_rq_tuser_int;
    end else if (store_axis_rq_temp_to_output) begin
        m_axis_rq_tdata_reg <= temp_m_axis_rq_tdata_reg;
        m_axis_rq_tkeep_reg <= temp_m_axis_rq_tkeep_reg;
        m_axis_rq_tlast_reg <= temp_m_axis_rq_tlast_reg;
        m_axis_rq_tuser_reg <= temp_m_axis_rq_tuser_reg;
    end

    if (store_axis_rq_int_to_temp) begin
        temp_m_axis_rq_tdata_reg <= m_axis_rq_tdata_int;
        temp_m_axis_rq_tkeep_reg <= m_axis_rq_tkeep_int;
        temp_m_axis_rq_tlast_reg <= m_axis_rq_tlast_int;
        temp_m_axis_rq_tuser_reg <= m_axis_rq_tuser_int;
    end
end

// output datapath logic (AXI write data)
reg [AXI_DATA_WIDTH-1:0] m_axi_wdata_reg = {AXI_DATA_WIDTH{1'b0}};
reg [AXI_STRB_WIDTH-1:0] m_axi_wstrb_reg = {AXI_STRB_WIDTH{1'b0}};
reg                      m_axi_wvalid_reg = 1'b0, m_axi_wvalid_next;
reg                      m_axi_wlast_reg = 1'b0;

reg [AXI_DATA_WIDTH-1:0] temp_m_axi_wdata_reg = {AXI_DATA_WIDTH{1'b0}};
reg [AXI_STRB_WIDTH-1:0] temp_m_axi_wstrb_reg = {AXI_STRB_WIDTH{1'b0}};
reg                      temp_m_axi_wvalid_reg = 1'b0, temp_m_axi_wvalid_next;
reg                      temp_m_axi_wlast_reg = 1'b0;

// datapath control
reg store_axi_w_int_to_output;
reg store_axi_w_int_to_temp;
reg store_axi_w_temp_to_output;

assign m_axi_wdata = m_axi_wdata_reg;
assign m_axi_wstrb = m_axi_wstrb_reg;
assign m_axi_wvalid = m_axi_wvalid_reg;
assign m_axi_wlast = m_axi_wlast_reg;

// enable ready input next cycle if output is ready or the temp reg will not be filled on the next cycle (output reg empty or no input)
assign m_axi_wready_int_early = m_axi_wready || (!temp_m_axi_wvalid_reg && (!m_axi_wvalid_reg || !m_axi_wvalid_int));

always @* begin
    // transfer sink ready state to source
    m_axi_wvalid_next = m_axi_wvalid_reg;
    temp_m_axi_wvalid_next = temp_m_axi_wvalid_reg;

    store_axi_w_int_to_output = 1'b0;
    store_axi_w_int_to_temp = 1'b0;
    store_axi_w_temp_to_output = 1'b0;
    
    if (m_axi_wready_int_reg) begin
        // input is ready
        if (m_axi_wready || !m_axi_wvalid_reg) begin
            // output is ready or currently not valid, transfer data to output
            m_axi_wvalid_next = m_axi_wvalid_int;
            store_axi_w_int_to_output = 1'b1;
        end else begin
            // output is not ready, store input in temp
            temp_m_axi_wvalid_next = m_axi_wvalid_int;
            store_axi_w_int_to_temp = 1'b1;
        end
    end else if (m_axi_wready) begin
        // input is not ready, but output is ready
        m_axi_wvalid_next = temp_m_axi_wvalid_reg;
        temp_m_axi_wvalid_next = 1'b0;
        store_axi_w_temp_to_output = 1'b1;
    end
end

always @(posedge clk) begin
    if (rst) begin
        m_axi_wvalid_reg <= 1'b0;
        m_axi_wready_int_reg <= 1'b0;
        temp_m_axi_wvalid_reg <= 1'b0;
    end else begin
        m_axi_wvalid_reg <= m_axi_wvalid_next;
        m_axi_wready_int_reg <= m_axi_wready_int_early;
        temp_m_axi_wvalid_reg <= temp_m_axi_wvalid_next;
    end

    // datapath
    if (store_axi_w_int_to_output) begin
        m_axi_wdata_reg <= m_axi_wdata_int;
        m_axi_wstrb_reg <= m_axi_wstrb_int;
        m_axi_wlast_reg <= m_axi_wlast_int;
    end else if (store_axi_w_temp_to_output) begin
        m_axi_wdata_reg <= temp_m_axi_wdata_reg;
        m_axi_wstrb_reg <= temp_m_axi_wstrb_reg;
        m_axi_wlast_reg <= temp_m_axi_wlast_reg;
    end

    if (store_axi_w_int_to_temp) begin
        temp_m_axi_wdata_reg <= m_axi_wdata_int;
        temp_m_axi_wstrb_reg <= m_axi_wstrb_int;
        temp_m_axi_wlast_reg <= m_axi_wlast_int;
    end
end

endmodule