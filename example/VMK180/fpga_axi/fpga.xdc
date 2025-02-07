# XDC constraints for the Xilinx VMK180 board
# part: xcvm1802-vsva2197-2MP-e-S



# LEDs
set_property -dict {LOC H34 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {led[0]}]
set_property -dict {LOC J33 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {led[1]}]
set_property -dict {LOC K36 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {led[2]}]
set_property -dict {LOC L35 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {led[3]}]

set_false_path -to [get_ports {led[*]}]
set_output_delay 0 [get_ports {led[*]}]

# DIP switches
set_property -dict {LOC J35  IOSTANDARD LVCMOS18} [get_ports {sw[0]}]
set_property -dict {LOC J34  IOSTANDARD LVCMOS18} [get_ports {sw[1]}]
set_property -dict {LOC H37  IOSTANDARD LVCMOS18} [get_ports {sw[2]}]
set_property -dict {LOC H36  IOSTANDARD LVCMOS18} [get_ports {sw[3]}]

set_false_path -from [get_ports {sw[*]}]
set_input_delay 0 [get_ports {sw[*]}]

# PCIe clock
set_property -dict {LOC W39 } [get_ports pcie_clk0_p] ;# GTY_REFCLKP0_103
set_property -dict {LOC W40 } [get_ports pcie_clk0_n] ;# GTY_REFCLKN0_103
create_clock -period 10.000 -name pcie_clk [get_ports pcie_clk0_p]

# PCIe Interface
set_property -dict {LOC AB46 } [get_ports {pcie_rx_p[0]}]  ;# GTY_RXP0_103
set_property -dict {LOC AB47 } [get_ports {pcie_rx_n[0]}]  ;# GTY_RXN0_103
set_property -dict {LOC AB41 } [get_ports {pcie_tx_p[0]}]  ;# GTY_TXP0_103
set_property -dict {LOC AB42 } [get_ports {pcie_tx_n[0]}]  ;# GTY_TXN0_103
set_property -dict {LOC AA44 } [get_ports {pcie_rx_p[1]}]  ;# GTY_RXP2_103
set_property -dict {LOC AA45 } [get_ports {pcie_rx_n[1]}]  ;# GTY_RXN2_103
set_property -dict {LOC Y41  } [get_ports {pcie_tx_p[1]}]  ;# GTY_TXP2_103
set_property -dict {LOC Y42  } [get_ports {pcie_tx_n[1]}]  ;# GTY_TXN2_103
set_property -dict {LOC Y46  } [get_ports {pcie_rx_p[2]}]  ;# GTY_RXP2_103
set_property -dict {LOC Y47  } [get_ports {pcie_rx_n[2]}]  ;# GTY_RXN2_103
set_property -dict {LOC V41  } [get_ports {pcie_tx_p[2]}]  ;# GTY_TXN2_103
set_property -dict {LOC V42  } [get_ports {pcie_tx_n[2]}]  ;# GTY_TXN2_103
set_property -dict {LOC W44  } [get_ports {pcie_rx_p[3]}]  ;# GTY_RXN3_103
set_property -dict {LOC W45  } [get_ports {pcie_rx_n[3]}]  ;# GTY_RXN3_103
set_property -dict {LOC U43  } [get_ports {pcie_tx_p[3]}]  ;# GTY_TXN3_103
set_property -dict {LOC U44  } [get_ports {pcie_tx_n[3]}]  ;# GTY_TXN3_103
set_property -dict {LOC V46  } [get_ports {pcie_rx_p[4]}]  ;# GTY_RXN4_104
set_property -dict {LOC V47  } [get_ports {pcie_rx_n[4]}]  ;# GTY_RXN4_104
set_property -dict {LOC T41  } [get_ports {pcie_tx_p[4]}]  ;# GTY_TXN4_104
set_property -dict {LOC T42  } [get_ports {pcie_tx_n[4]}]  ;# GTY_TXN4_104
set_property -dict {LOC T46  } [get_ports {pcie_rx_p[5]}]  ;# GTY_RXN5_104
set_property -dict {LOC T47  } [get_ports {pcie_rx_n[5]}]  ;# GTY_RXN5_104
set_property -dict {LOC R43  } [get_ports {pcie_tx_p[5]}]  ;# GTY_TXN5_104
set_property -dict {LOC R44  } [get_ports {pcie_tx_n[5]}]  ;# GTY_TXN5_104
set_property -dict {LOC P46  } [get_ports {pcie_rx_p[6]}]  ;# GTY_RXN6_104
set_property -dict {LOC P47  } [get_ports {pcie_rx_n[6]}]  ;# GTY_RXN6_104
set_property -dict {LOC P41  } [get_ports {pcie_tx_p[6]}]  ;# GTY_TXN6_104
set_property -dict {LOC P42  } [get_ports {pcie_tx_n[6]}]  ;# GTY_TXN6_104
set_property -dict {LOC N44  } [get_ports {pcie_rx_p[7]}]  ;# GTY_RXN7_104
set_property -dict {LOC N45  } [get_ports {pcie_rx_n[7]}]  ;# GTY_RXN7_104
set_property -dict {LOC M41  } [get_ports {pcie_tx_p[7]}]  ;# GTY_TXN7_104
set_property -dict {LOC M42  } [get_ports {pcie_tx_n[7]}]  ;# GTY_TXN7_104