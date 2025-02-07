# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Jonathan Drolet

create_bd_design versal_cips

# Versal CIPS
set versal_cips_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:versal_cips versal_cips_0 ]
set_property -dict [list \
    CONFIG.BOOT_MODE {Custom} \
    CONFIG.CLOCK_MODE {Custom} \
    CONFIG.CPM_CONFIG { \
        CPM_PCIE0_AXISTEN_IF_ENABLE_CLIENT_TAG {1} \
        CPM_PCIE0_AXISTEN_IF_EXT_512_CQ_STRADDLE {1} \
        CPM_PCIE0_CFG_CTL_IF {1} \
        CPM_PCIE0_CFG_FC_IF {1} \
        CPM_PCIE0_CFG_MGMT_IF {1} \
        CPM_PCIE0_CFG_STS_IF {1} \
        CPM_PCIE0_CFG_VEND_ID {1234} \
        CPM_PCIE0_EDR_LINK_SPEED {None} \
        CPM_PCIE0_MAX_LINK_SPEED {16.0_GT/s} \
        CPM_PCIE0_MODES {PCIE} \
        CPM_PCIE0_MODE_SELECTION {Advanced} \
        CPM_PCIE0_MSI_X_OPTIONS {MSI-X_External} \
        CPM_PCIE0_PF0_BAR0_64BIT {1} \
        CPM_PCIE0_PF0_BAR0_PREFETCHABLE {1} \
        CPM_PCIE0_PF0_BAR0_SCALE {Megabytes} \
        CPM_PCIE0_PF0_BAR0_SIZE {16} \
        CPM_PCIE0_PF0_BAR2_64BIT {1} \
        CPM_PCIE0_PF0_BAR2_ENABLED {1} \
        CPM_PCIE0_PF0_BAR2_PREFETCHABLE {1} \
        CPM_PCIE0_PF0_BAR2_SCALE {Megabytes} \
        CPM_PCIE0_PF0_BAR2_SIZE {16} \
        CPM_PCIE0_PF0_BAR4_64BIT {1} \
        CPM_PCIE0_PF0_BAR4_ENABLED {1} \
        CPM_PCIE0_PF0_BAR4_PREFETCHABLE {1} \
        CPM_PCIE0_PF0_BAR4_SIZE {64} \
        CPM_PCIE0_PF0_CFG_DEV_ID {0001} \
        CPM_PCIE0_PF0_CFG_SUBSYS_ID {a0b4} \
        CPM_PCIE0_PF0_CFG_SUBSYS_VEND_ID {10ee} \
        CPM_PCIE0_PF0_DEV_CAP_EXT_TAG_EN {1} \
        CPM_PCIE0_PF0_MSIX_CAP_PBA_BIR {BAR_5:4} \
        CPM_PCIE0_PF0_MSIX_CAP_PBA_OFFSET {8000} \
        CPM_PCIE0_PF0_MSIX_CAP_TABLE_BIR {BAR_5:4} \
        CPM_PCIE0_PF0_MSIX_CAP_TABLE_OFFSET {0} \
        CPM_PCIE0_PF0_MSIX_CAP_TABLE_SIZE {01f} \
        CPM_PCIE0_PF0_MSI_ENABLED {0} \
        CPM_PCIE0_PL_LINK_CAP_MAX_LINK_WIDTH {X8} \
    } \
    CONFIG.DDR_MEMORY_MODE {Custom} \
    CONFIG.DEBUG_MODE {JTAG} \
    CONFIG.DESIGN_MODE {1} \
    CONFIG.PS_PMC_CONFIG { \
        BOOT_MODE {Custom} \
        CLOCK_MODE {Custom} \
        DEBUG_MODE {JTAG} \
        DESIGN_MODE {1} \
        PCIE_APERTURES_DUAL_ENABLE {0} \
        PCIE_APERTURES_SINGLE_ENABLE {0} \
        PMC_ALT_REF_CLK_FREQMHZ {33.333} \
        PMC_BANK_0_IO_STANDARD {LVCMOS1.8} \
        PMC_BANK_1_IO_STANDARD {LVCMOS1.8} \
        PMC_CRP_EFUSE_REF_CTRL_SRCSEL {IRO_CLK/4} \
        PMC_CRP_HSM0_REF_CTRL_FREQMHZ {33.333} \
        PMC_CRP_HSM1_REF_CTRL_FREQMHZ {133.333} \
        PMC_CRP_LSBUS_REF_CTRL_FREQMHZ {100} \
        PMC_CRP_NOC_REF_CTRL_FREQMHZ {960} \
        PMC_CRP_PL0_REF_CTRL_FREQMHZ {334} \
        PMC_CRP_PL5_REF_CTRL_FREQMHZ {400} \
        PMC_PL_ALT_REF_CLK_FREQMHZ {33.333} \
        PMC_QSPI_FBCLK {{ENABLE 1} {IO {PMC_MIO 6}}} \
        PMC_QSPI_PERIPHERAL_ENABLE {0} \
        PMC_SD0 {{CD_ENABLE 0} {CD_IO {PMC_MIO 24}} {POW_ENABLE 0} {POW_IO {PMC_MIO 17}} {RESET_ENABLE 0} {RESET_IO {PMC_MIO 17}} {WP_ENABLE 0} {WP_IO {PMC_MIO 25}}} \
        PMC_SD0_PERIPHERAL {{CLK_100_SDR_OTAP_DLY 0x00} {CLK_200_SDR_OTAP_DLY 0x00} {CLK_50_DDR_ITAP_DLY 0x00} {CLK_50_DDR_OTAP_DLY 0x00} {CLK_50_SDR_ITAP_DLY 0x00} {CLK_50_SDR_OTAP_DLY 0x00} {ENABLE 0} {IO {PMC_MIO 13 .. 25}}} \
        PMC_SD0_SLOT_TYPE {SD 2.0} \
        PMC_SD1 {{CD_ENABLE 1} {CD_IO {PMC_MIO 28}} {POW_ENABLE 1} {POW_IO {PMC_MIO 51}} {RESET_ENABLE 0} {RESET_IO {PMC_MIO 12}} {WP_ENABLE 0} {WP_IO {PMC_MIO 1}}} \
        PMC_SD1_PERIPHERAL {{CLK_100_SDR_OTAP_DLY 0x3} {CLK_200_SDR_OTAP_DLY 0x2} {CLK_50_DDR_ITAP_DLY 0x36} {CLK_50_DDR_OTAP_DLY 0x3} {CLK_50_SDR_ITAP_DLY 0x2C} {CLK_50_SDR_OTAP_DLY 0x4} {ENABLE 1} {IO {PMC_MIO 26 .. 36}}} \
        PMC_SD1_SLOT_TYPE {SD 3.0} \
        PMC_SMAP_PERIPHERAL {{ENABLE 0} {IO {32 Bit}}} \
        PS_BANK_2_IO_STANDARD {LVCMOS1.8} \
        PS_BANK_3_IO_STANDARD {LVCMOS1.8} \
        PS_BOARD_INTERFACE {Custom} \
        PS_HSDP_EGRESS_TRAFFIC {JTAG} \
        PS_HSDP_INGRESS_TRAFFIC {JTAG} \
        PS_HSDP_MODE {NONE} \
        PS_NUM_FABRIC_RESETS {0} \
        PS_PCIE1_PERIPHERAL_ENABLE {1} \
        PS_PCIE2_PERIPHERAL_ENABLE {0} \
        PS_PCIE_EP_RESET1_IO {PMC_MIO 38} \
        PS_PCIE_RESET {ENABLE 1} \
        PS_USE_PMCPL_CLK0 {0} \
        PS_USE_PMCPL_CLK1 {0} \
        PS_USE_PMCPL_CLK2 {0} \
        PS_USE_PMCPL_CLK3 {0} \
        PS_USE_PMCPL_IRO_CLK {0} \
        SMON_ALARMS {Set_Alarms_On} \
        SMON_ENABLE_TEMP_AVERAGING {0} \
        SMON_TEMP_AVERAGING_SAMPLES {0} \
    } \
] $versal_cips_0

# Create interface ports
set pcie_refclk [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 pcie_refclk ]
set pcie_gt [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 pcie_gt ]
set pcie_m_axis_rc [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 pcie_m_axis_rc ]
set pcie_m_axis_cq [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 pcie_m_axis_cq ]
set pcie_cfg_control [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:pcie4_cfg_control_rtl:1.0 pcie_cfg_control ]
set pcie_cfg_status [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie4_cfg_status_rtl:1.0 pcie_cfg_status ]
set pcie_cfg_mgmt [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:pcie4_cfg_mgmt_rtl:1.0 pcie_cfg_mgmt ]
set pcie_cfg_fc [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie_cfg_fc_rtl:1.1 pcie_cfg_fc ]
set pcie_cfg_interrupt [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:pcie3_cfg_interrupt_rtl:1.0 pcie_cfg_interrupt ]
set pcie_cfg_msix [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:pcie4_cfg_msix_rtl:1.0 pcie_cfg_msix ]

set pcie_s_axis_rq [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 pcie_s_axis_rq ]
set_property -dict [ list \
    CONFIG.HAS_TKEEP {1} \
    CONFIG.HAS_TLAST {1} \
    CONFIG.HAS_TREADY {1} \
    CONFIG.HAS_TSTRB {0} \
    CONFIG.LAYERED_METADATA {undef} \
    CONFIG.TDATA_NUM_BYTES {64} \
    CONFIG.TDEST_WIDTH {0} \
    CONFIG.TID_WIDTH {0} \
    CONFIG.TUSER_WIDTH {179} \
] $pcie_s_axis_rq

set pcie_s_axis_cc [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 pcie_s_axis_cc ]
set_property -dict [ list \
    CONFIG.HAS_TKEEP {1} \
    CONFIG.HAS_TLAST {1} \
    CONFIG.HAS_TREADY {1} \
    CONFIG.HAS_TSTRB {0} \
    CONFIG.LAYERED_METADATA {undef} \
    CONFIG.TDATA_NUM_BYTES {64} \
    CONFIG.TDEST_WIDTH {0} \
    CONFIG.TID_WIDTH {0} \
    CONFIG.TUSER_WIDTH {81} \
] $pcie_s_axis_cc

# Create ports
set pcie_user_clk [ create_bd_port -dir O -type clk pcie_user_clk ]
set_property -dict [ list \
    CONFIG.ASSOCIATED_BUSIF {pcie_s_axis_rq:pcie_s_axis_cc:pcie_m_axis_rc:pcie_m_axis_cq} \
    CONFIG.ASSOCIATED_RESET {pcie_user_reset} \
] $pcie_user_clk
set pcie_user_reset [ create_bd_port -dir O -type rst pcie_user_reset ]
set pcie_user_lnk_up [ create_bd_port -dir O pcie_user_lnk_up ]


# Create interface connections
connect_bd_intf_net -intf_net gt_refclk0_0_1 [get_bd_intf_ports pcie_refclk] [get_bd_intf_pins versal_cips_0/gt_refclk0]
connect_bd_intf_net -intf_net pcie0_cfg_control_0_1 [get_bd_intf_ports pcie_cfg_control] [get_bd_intf_pins versal_cips_0/pcie0_cfg_control]
connect_bd_intf_net -intf_net pcie0_cfg_interrupt_0_1 [get_bd_intf_ports pcie_cfg_interrupt] [get_bd_intf_pins versal_cips_0/pcie0_cfg_interrupt]
connect_bd_intf_net -intf_net pcie0_cfg_mgmt_0_1 [get_bd_intf_ports pcie_cfg_mgmt] [get_bd_intf_pins versal_cips_0/pcie0_cfg_mgmt]
connect_bd_intf_net -intf_net pcie0_cfg_msix_0_1 [get_bd_intf_ports pcie_cfg_msix] [get_bd_intf_pins versal_cips_0/pcie0_cfg_msix]
connect_bd_intf_net -intf_net pcie0_s_axis_cc_0_1 [get_bd_intf_ports pcie_s_axis_cc] [get_bd_intf_pins versal_cips_0/pcie0_s_axis_cc]
connect_bd_intf_net -intf_net pcie0_s_axis_rq_0_1 [get_bd_intf_ports pcie_s_axis_rq] [get_bd_intf_pins versal_cips_0/pcie0_s_axis_rq]
connect_bd_intf_net -intf_net versal_cips_0_PCIE0_GT [get_bd_intf_ports pcie_gt] [get_bd_intf_pins versal_cips_0/PCIE0_GT]
connect_bd_intf_net -intf_net versal_cips_0_pcie0_cfg_fc [get_bd_intf_ports pcie_cfg_fc] [get_bd_intf_pins versal_cips_0/pcie0_cfg_fc]
connect_bd_intf_net -intf_net versal_cips_0_pcie0_cfg_status [get_bd_intf_ports pcie_cfg_status] [get_bd_intf_pins versal_cips_0/pcie0_cfg_status]
connect_bd_intf_net -intf_net versal_cips_0_pcie0_m_axis_cq [get_bd_intf_ports pcie_m_axis_cq] [get_bd_intf_pins versal_cips_0/pcie0_m_axis_cq]
connect_bd_intf_net -intf_net versal_cips_0_pcie0_m_axis_rc [get_bd_intf_ports pcie_m_axis_rc] [get_bd_intf_pins versal_cips_0/pcie0_m_axis_rc]

# Create port connections
connect_bd_net -net versal_cips_0_pcie0_user_clk  [get_bd_pins versal_cips_0/pcie0_user_clk] [get_bd_ports pcie_user_clk]
connect_bd_net -net versal_cips_0_pcie0_user_lnk_up  [get_bd_pins versal_cips_0/pcie0_user_lnk_up] [get_bd_ports pcie_user_lnk_up]
connect_bd_net -net versal_cips_0_pcie0_user_reset  [get_bd_pins versal_cips_0/pcie0_user_reset] [get_bd_ports pcie_user_reset]

validate_bd_design

save_bd_design [current_bd_design]
close_bd_design [current_bd_design]
