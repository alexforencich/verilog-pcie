/*

Copyright (c) 2018 Alex Forencich
Copyright (c) 2025 Jonathan Drolet

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

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * FPGA top-level module
 */
module fpga (
    /*
     * GPIO
     */
    input  wire [3:0]  sw,
    output wire [3:0]  led,

    /*
     * PCI express
     */
    input  wire        pcie_clk0_p,
    input  wire        pcie_clk0_n,
    input  wire [7:0]  pcie_rx_p,
    input  wire [7:0]  pcie_rx_n,
    output wire [7:0]  pcie_tx_p,
    output wire [7:0]  pcie_tx_n
);

parameter AXIS_PCIE_DATA_WIDTH = 512;
parameter AXIS_PCIE_KEEP_WIDTH = (AXIS_PCIE_DATA_WIDTH/32);
parameter AXIS_PCIE_RC_USER_WIDTH = AXIS_PCIE_DATA_WIDTH < 512 ? 75 : 161;
parameter AXIS_PCIE_RQ_USER_WIDTH = AXIS_PCIE_DATA_WIDTH < 512 ? 62 : 179;
parameter AXIS_PCIE_CQ_USER_WIDTH = AXIS_PCIE_DATA_WIDTH < 512 ? 108 : 229;
parameter AXIS_PCIE_CC_USER_WIDTH = AXIS_PCIE_DATA_WIDTH < 512 ? 33 : 81;
parameter RC_STRADDLE = AXIS_PCIE_DATA_WIDTH >= 256;
parameter RQ_STRADDLE = AXIS_PCIE_DATA_WIDTH >= 512;
parameter CQ_STRADDLE = AXIS_PCIE_DATA_WIDTH >= 512;
parameter CC_STRADDLE = AXIS_PCIE_DATA_WIDTH >= 512;

parameter RQ_SEQ_NUM_WIDTH = 6;
parameter RQ_SEQ_NUM_ENABLE = 1;

parameter PCIE_TAG_COUNT = 256;
parameter BAR0_APERTURE = 24;
parameter BAR2_APERTURE = 24;
parameter BAR4_APERTURE = 16;

// Clock and reset
wire pcie_user_clk;
wire pcie_user_reset;

// GPIO
wire [3:0] sw_int;

debounce_switch #(
    .WIDTH(4),
    .N(4),
    .RATE(250000)
)
debounce_switch_inst (
    .clk(pcie_user_clk),
    .rst(pcie_user_reset),
    .in (sw),
    .out(sw_int)
);

wire [AXIS_PCIE_DATA_WIDTH-1:0]    axis_rq_tdata;
wire [AXIS_PCIE_KEEP_WIDTH-1:0]    axis_rq_tkeep;
wire                               axis_rq_tlast;
wire                               axis_rq_tready;
wire [AXIS_PCIE_RQ_USER_WIDTH-1:0] axis_rq_tuser;
wire                               axis_rq_tvalid;

wire [AXIS_PCIE_DATA_WIDTH-1:0]    axis_rc_tdata;
wire [AXIS_PCIE_KEEP_WIDTH-1:0]    axis_rc_tkeep;
wire                               axis_rc_tlast;
wire                               axis_rc_tready;
wire [AXIS_PCIE_RC_USER_WIDTH-1:0] axis_rc_tuser;
wire                               axis_rc_tvalid;

wire [AXIS_PCIE_DATA_WIDTH-1:0]    axis_cq_tdata;
wire [AXIS_PCIE_KEEP_WIDTH-1:0]    axis_cq_tkeep;
wire                               axis_cq_tlast;
wire                               axis_cq_tready;
wire [AXIS_PCIE_CQ_USER_WIDTH-1:0] axis_cq_tuser;
wire                               axis_cq_tvalid;

wire [AXIS_PCIE_DATA_WIDTH-1:0]    axis_cc_tdata;
wire [AXIS_PCIE_KEEP_WIDTH-1:0]    axis_cc_tkeep;
wire                               axis_cc_tlast;
wire                               axis_cc_tready;
wire [AXIS_PCIE_CC_USER_WIDTH-1:0] axis_cc_tuser;
wire                               axis_cc_tvalid;

wire [RQ_SEQ_NUM_WIDTH-1:0]        pcie_rq_seq_num0;
wire                               pcie_rq_seq_num_vld0;
wire [RQ_SEQ_NUM_WIDTH-1:0]        pcie_rq_seq_num1;
wire                               pcie_rq_seq_num_vld1;

wire [1:0] cfg_max_payload;
wire [2:0] cfg_max_read_req;
wire [3:0] cfg_rcb_status;

wire [9:0]  cfg_mgmt_addr;
wire [7:0]  cfg_mgmt_function_number;
wire        cfg_mgmt_write;
wire [31:0] cfg_mgmt_write_data;
wire [3:0]  cfg_mgmt_byte_enable;
wire        cfg_mgmt_read;
wire [31:0] cfg_mgmt_read_data;
wire        cfg_mgmt_read_write_done;

wire [7:0]  cfg_fc_ph;
wire [11:0] cfg_fc_pd;
wire [7:0]  cfg_fc_nph;
wire [11:0] cfg_fc_npd;
wire [7:0]  cfg_fc_cplh;
wire [11:0] cfg_fc_cpld;
wire [2:0]  cfg_fc_sel;

wire [3:0]   cfg_interrupt_msix_enable;
wire [3:0]   cfg_interrupt_msix_mask;
wire [63:0]  cfg_interrupt_msix_address;
wire [31:0]  cfg_interrupt_msix_data;
wire         cfg_interrupt_msix_int;
wire [1:0]   cfg_interrupt_msix_vec_pending;
wire         cfg_interrupt_msix_vec_pending_status;

wire status_error_cor;
wire status_error_uncor;

versal_cips 
versal_cips_inst (
    .pcie_gt_gtx_n(pcie_tx_n),
    .pcie_gt_gtx_p(pcie_tx_p),
    .pcie_gt_grx_n(pcie_rx_n),
    .pcie_gt_grx_p(pcie_rx_p),
    .pcie_user_clk(pcie_user_clk),
    .pcie_user_reset(pcie_user_reset),
    .pcie_user_lnk_up(),

    .pcie_refclk_clk_n(pcie_clk0_n),
    .pcie_refclk_clk_p(pcie_clk0_p),

    .pcie_s_axis_rq_tdata(axis_rq_tdata),
    .pcie_s_axis_rq_tkeep(axis_rq_tkeep),
    .pcie_s_axis_rq_tlast(axis_rq_tlast),
    .pcie_s_axis_rq_tready(axis_rq_tready),
    .pcie_s_axis_rq_tuser(axis_rq_tuser),
    .pcie_s_axis_rq_tvalid(axis_rq_tvalid),

    .pcie_m_axis_rc_tdata(axis_rc_tdata),
    .pcie_m_axis_rc_tkeep(axis_rc_tkeep),
    .pcie_m_axis_rc_tlast(axis_rc_tlast),
    .pcie_m_axis_rc_tready(axis_rc_tready),
    .pcie_m_axis_rc_tuser(axis_rc_tuser),
    .pcie_m_axis_rc_tvalid(axis_rc_tvalid),

    .pcie_m_axis_cq_tdata(axis_cq_tdata),
    .pcie_m_axis_cq_tkeep(axis_cq_tkeep),
    .pcie_m_axis_cq_tlast(axis_cq_tlast),
    .pcie_m_axis_cq_tready(axis_cq_tready),
    .pcie_m_axis_cq_tuser(axis_cq_tuser),
    .pcie_m_axis_cq_tvalid(axis_cq_tvalid),

    .pcie_s_axis_cc_tdata(axis_cc_tdata),
    .pcie_s_axis_cc_tkeep(axis_cc_tkeep),
    .pcie_s_axis_cc_tlast(axis_cc_tlast),
    .pcie_s_axis_cc_tready(axis_cc_tready),
    .pcie_s_axis_cc_tuser(axis_cc_tuser),
    .pcie_s_axis_cc_tvalid(axis_cc_tvalid),

    .pcie_cfg_status_rq_seq_num0(pcie_rq_seq_num0),
    .pcie_cfg_status_rq_seq_num_vld0(pcie_rq_seq_num_vld0),
    .pcie_cfg_status_rq_seq_num1(pcie_rq_seq_num1),
    .pcie_cfg_status_rq_seq_num_vld1(pcie_rq_seq_num_vld1),
    .pcie_cfg_status_rq_tag0(),
    .pcie_cfg_status_rq_tag1(),
    .pcie_cfg_status_rq_tag_av(),
    .pcie_cfg_status_rq_tag_vld0(),
    .pcie_cfg_status_rq_tag_vld1(),

    .pcie_cfg_status_cq_np_req(2'b01),
    .pcie_cfg_status_cq_np_req_count(),

    .pcie_cfg_status_phy_link_down(),
    .pcie_cfg_status_phy_link_status(),
    .pcie_cfg_status_negotiated_width(),
    .pcie_cfg_status_current_speed(),
    .pcie_cfg_status_max_payload(cfg_max_payload),
    .pcie_cfg_status_max_read_req(cfg_max_read_req),
    .pcie_cfg_status_function_status(),
    .pcie_cfg_status_function_power_state(),
    .pcie_cfg_status_link_power_state(),

    .pcie_cfg_mgmt_addr(cfg_mgmt_addr),
    .pcie_cfg_mgmt_function_number(cfg_mgmt_function_number),
    .pcie_cfg_mgmt_write_en(cfg_mgmt_write),
    .pcie_cfg_mgmt_write_data(cfg_mgmt_write_data),
    .pcie_cfg_mgmt_byte_en(cfg_mgmt_byte_enable),
    .pcie_cfg_mgmt_read_en(cfg_mgmt_read),
    .pcie_cfg_mgmt_read_data(cfg_mgmt_read_data),
    .pcie_cfg_mgmt_read_write_done(cfg_mgmt_read_write_done),
    .pcie_cfg_mgmt_debug_access(1'b0),

    .pcie_cfg_status_err_cor_out(),
    .pcie_cfg_status_err_nonfatal_out(),
    .pcie_cfg_status_err_fatal_out(),
    .pcie_cfg_status_local_error_valid(),
    .pcie_cfg_status_local_error_out(),
    .pcie_cfg_status_ltssm_state(),
    .pcie_cfg_status_rx_pm_state(),
    .pcie_cfg_status_tx_pm_state(),
    .pcie_cfg_status_rcb_status(cfg_rcb_status),
    .pcie_cfg_status_pl_status_change(),
    .pcie_cfg_status_tph_requester_enable(),
    .pcie_cfg_status_tph_st_mode(),
    
    .pcie_cfg_fc_ph(cfg_fc_ph),
    .pcie_cfg_fc_ph_scale(2'b00),
    .pcie_cfg_fc_pd(cfg_fc_pd),
    .pcie_cfg_fc_pd_scale(2'b00),
    .pcie_cfg_fc_nph(cfg_fc_nph),
    .pcie_cfg_fc_nph_scale(2'b00),
    .pcie_cfg_fc_npd(cfg_fc_npd),
    .pcie_cfg_fc_npd_scale(2'b00),
    .pcie_cfg_fc_cplh(cfg_fc_cplh),
    .pcie_cfg_fc_cplh_scale(2'b00),
    .pcie_cfg_fc_cpld(cfg_fc_cpld),
    .pcie_cfg_fc_cpld_scale(2'b00),
    .pcie_cfg_fc_vc_sel(1'b0),
    .pcie_cfg_fc_sel(cfg_fc_sel),

    .pcie_cfg_control_power_state_change_ack(1'b1),
    .pcie_cfg_control_power_state_change_interrupt(),

    .pcie_cfg_control_err_cor_in(status_error_cor),
    .pcie_cfg_control_err_uncor_in(status_error_uncor),
    .pcie_cfg_control_flr_in_process(),
    .pcie_cfg_control_flr_done(4'd0),

    .pcie_cfg_interrupt_intx_vector(4'd0),
    .pcie_cfg_interrupt_pending(4'd0),
    .pcie_cfg_interrupt_sent(),
    .pcie_cfg_msix_enable(cfg_interrupt_msix_enable),
    .pcie_cfg_msix_mask(cfg_interrupt_msix_mask),
    .pcie_cfg_msix_address(cfg_interrupt_msix_address),
    .pcie_cfg_msix_data(cfg_interrupt_msix_data),
    .pcie_cfg_msix_int_vector(cfg_interrupt_msix_int),
    .pcie_cfg_msix_vec_pending(cfg_interrupt_msix_vec_pending),
    .pcie_cfg_msix_vec_pending_status(cfg_interrupt_msix_vec_pending_status),

    .pcie_cfg_control_hot_reset_out(),
    .pcie_cfg_control_hot_reset_in(1'b0),

    .pcie_cfg_status_10b_tag_requester_enable(),
    .pcie_cfg_status_atomic_requester_enable(),
    .pcie_cfg_status_ext_tag_enable()
);

fpga_core #(
    .AXIS_PCIE_DATA_WIDTH(AXIS_PCIE_DATA_WIDTH),
    .AXIS_PCIE_KEEP_WIDTH(AXIS_PCIE_KEEP_WIDTH),
    .AXIS_PCIE_RC_USER_WIDTH(AXIS_PCIE_RC_USER_WIDTH),
    .AXIS_PCIE_RQ_USER_WIDTH(AXIS_PCIE_RQ_USER_WIDTH),
    .AXIS_PCIE_CQ_USER_WIDTH(AXIS_PCIE_CQ_USER_WIDTH),
    .AXIS_PCIE_CC_USER_WIDTH(AXIS_PCIE_CC_USER_WIDTH),
    .RC_STRADDLE(RC_STRADDLE),
    .RQ_STRADDLE(RQ_STRADDLE),
    .CQ_STRADDLE(CQ_STRADDLE),
    .CC_STRADDLE(CC_STRADDLE),
    .RQ_SEQ_NUM_WIDTH(RQ_SEQ_NUM_WIDTH),
    .RQ_SEQ_NUM_ENABLE(RQ_SEQ_NUM_ENABLE),
    .PCIE_TAG_COUNT(PCIE_TAG_COUNT),
    .BAR0_APERTURE(BAR0_APERTURE),
    .BAR2_APERTURE(BAR2_APERTURE),
    .BAR4_APERTURE(BAR4_APERTURE)
)
core_inst (
    /*
     * Clock: 250 MHz
     * Synchronous reset
     */
    .clk(pcie_user_clk),
    .rst(pcie_user_reset),
    /*
     * GPIO
     */
    .sw(sw_int),
    .led(led),
    /*
     * PCIe
     */
    .m_axis_rq_tdata(axis_rq_tdata),
    .m_axis_rq_tkeep(axis_rq_tkeep),
    .m_axis_rq_tlast(axis_rq_tlast),
    .m_axis_rq_tready(axis_rq_tready),
    .m_axis_rq_tuser(axis_rq_tuser),
    .m_axis_rq_tvalid(axis_rq_tvalid),

    .s_axis_rc_tdata(axis_rc_tdata),
    .s_axis_rc_tkeep(axis_rc_tkeep),
    .s_axis_rc_tlast(axis_rc_tlast),
    .s_axis_rc_tready(axis_rc_tready),
    .s_axis_rc_tuser(axis_rc_tuser),
    .s_axis_rc_tvalid(axis_rc_tvalid),

    .s_axis_cq_tdata(axis_cq_tdata),
    .s_axis_cq_tkeep(axis_cq_tkeep),
    .s_axis_cq_tlast(axis_cq_tlast),
    .s_axis_cq_tready(axis_cq_tready),
    .s_axis_cq_tuser(axis_cq_tuser),
    .s_axis_cq_tvalid(axis_cq_tvalid),

    .m_axis_cc_tdata(axis_cc_tdata),
    .m_axis_cc_tkeep(axis_cc_tkeep),
    .m_axis_cc_tlast(axis_cc_tlast),
    .m_axis_cc_tready(axis_cc_tready),
    .m_axis_cc_tuser(axis_cc_tuser),
    .m_axis_cc_tvalid(axis_cc_tvalid),

    .s_axis_rq_seq_num_0(pcie_rq_seq_num0),
    .s_axis_rq_seq_num_valid_0(pcie_rq_seq_num_vld0),
    .s_axis_rq_seq_num_1(pcie_rq_seq_num1),
    .s_axis_rq_seq_num_valid_1(pcie_rq_seq_num_vld1),

    .cfg_max_payload(cfg_max_payload),
    .cfg_max_read_req(cfg_max_read_req),
    .cfg_rcb_status(cfg_rcb_status),

    .cfg_mgmt_addr(cfg_mgmt_addr),
    .cfg_mgmt_function_number(cfg_mgmt_function_number),
    .cfg_mgmt_write(cfg_mgmt_write),
    .cfg_mgmt_write_data(cfg_mgmt_write_data),
    .cfg_mgmt_byte_enable(cfg_mgmt_byte_enable),
    .cfg_mgmt_read(cfg_mgmt_read),
    .cfg_mgmt_read_data(cfg_mgmt_read_data),
    .cfg_mgmt_read_write_done(cfg_mgmt_read_write_done),

    .cfg_fc_ph(cfg_fc_ph),
    .cfg_fc_pd(cfg_fc_pd),
    .cfg_fc_nph(cfg_fc_nph),
    .cfg_fc_npd(cfg_fc_npd),
    .cfg_fc_cplh(cfg_fc_cplh),
    .cfg_fc_cpld(cfg_fc_cpld),
    .cfg_fc_sel(cfg_fc_sel),

    .cfg_interrupt_msix_enable(cfg_interrupt_msix_enable),
    .cfg_interrupt_msix_mask(cfg_interrupt_msix_mask),
    .cfg_interrupt_msix_address(cfg_interrupt_msix_address),
    .cfg_interrupt_msix_data(cfg_interrupt_msix_data),
    .cfg_interrupt_msix_int(cfg_interrupt_msix_int),
    .cfg_interrupt_msix_vec_pending(cfg_interrupt_msix_vec_pending),
    .cfg_interrupt_msix_vec_pending_status(cfg_interrupt_msix_vec_pending_status),

    .status_error_cor(status_error_cor),
    .status_error_uncor(status_error_uncor)
);

endmodule

`resetall
