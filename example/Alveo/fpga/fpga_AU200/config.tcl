set params [dict create]

# Board info
set board_vendor_id [expr 0x10ee]
set board_device_id [expr 0x90c8]

# PCIe IDs
set pcie_vendor_id [expr 0x1234]
set pcie_device_id [expr 0x0001]
set pcie_class_code [expr 0x058000]
set pcie_revision_id [expr 0x00]
set pcie_subsystem_vendor_id $board_vendor_id
set pcie_subsystem_device_id $board_device_id

# BAR sizes
dict set params BAR0_APERTURE "24"
dict set params BAR2_APERTURE "24"
dict set params BAR4_APERTURE "16"

# PCIe IP core settings
set pcie [get_ips pcie4_uscale_plus_0]

# Internal interface settings
dict set params AXIS_PCIE_DATA_WIDTH [regexp -all -inline -- {[0-9]+} [get_property CONFIG.axisten_if_width $pcie]]

# configure BAR settings
proc configure_bar {pcie pf bar aperture} {
    set size_list {Bytes Kilobytes Megabytes Gigabytes Terabytes Petabytes Exabytes}
    for { set i 0 } { $i < [llength $size_list] } { incr i } {
        set scale [lindex $size_list $i]

        if {$aperture > 0 && $aperture < ($i+1)*10} {
            set size [expr 1 << $aperture - ($i*10)]

            puts "${pcie} PF${pf} BAR${bar}: aperture ${aperture} bits ($size $scale)"

            set pcie_config [dict create]

            dict set pcie_config "CONFIG.pf${pf}_bar${bar}_enabled" {true}
            dict set pcie_config "CONFIG.pf${pf}_bar${bar}_type" {Memory}
            dict set pcie_config "CONFIG.pf${pf}_bar${bar}_64bit" {true}
            dict set pcie_config "CONFIG.pf${pf}_bar${bar}_prefetchable" {true}
            dict set pcie_config "CONFIG.pf${pf}_bar${bar}_scale" $scale
            dict set pcie_config "CONFIG.pf${pf}_bar${bar}_size" $size

            set_property -dict $pcie_config $pcie

            return
        }
    }
    puts "${pcie} PF${pf} BAR${bar}: disabled"
    set_property "CONFIG.pf${pf}_bar${bar}_enabled" {false} $pcie
}

# Configure BARs
configure_bar $pcie 0 0 [dict get $params BAR0_APERTURE]
configure_bar $pcie 0 2 [dict get $params BAR2_APERTURE]
configure_bar $pcie 0 4 [dict get $params BAR4_APERTURE]

# PCIe IP core configuration
set pcie_config [dict create]

# PCIe IDs
dict set pcie_config "CONFIG.vendor_id" [format "%04x" $pcie_vendor_id]
dict set pcie_config "CONFIG.PF0_DEVICE_ID" [format "%04x" $pcie_device_id]
dict set pcie_config "CONFIG.PF0_CLASS_CODE" [format "%06x" $pcie_class_code]
dict set pcie_config "CONFIG.PF0_REVISION_ID" [format "%02x" $pcie_revision_id]
dict set pcie_config "CONFIG.PF0_SUBSYSTEM_VENDOR_ID" [format "%04x" $pcie_subsystem_vendor_id]
dict set pcie_config "CONFIG.PF0_SUBSYSTEM_ID" [format "%04x" $pcie_subsystem_device_id]

# MSI-X
dict set pcie_config "CONFIG.pf0_msi_enabled" {false}
dict set pcie_config "CONFIG.pf0_msix_enabled" {true}
dict set pcie_config "CONFIG.PF0_MSIX_CAP_TABLE_SIZE" {01F}
dict set pcie_config "CONFIG.PF0_MSIX_CAP_TABLE_BIR" {BAR_5:4}
dict set pcie_config "CONFIG.PF0_MSIX_CAP_TABLE_OFFSET" {00000000}
dict set pcie_config "CONFIG.PF0_MSIX_CAP_PBA_BIR" {BAR_5:4}
dict set pcie_config "CONFIG.PF0_MSIX_CAP_PBA_OFFSET" {00008000}
dict set pcie_config "CONFIG.MSI_X_OPTIONS" {MSI-X_External}

set_property -dict $pcie_config $pcie

# apply parameters to top-level
set param_list {}
dict for {name value} $params {
    lappend param_list $name=$value
}

# set_property generic $param_list [current_fileset]
set_property generic $param_list [get_filesets sources_1]
