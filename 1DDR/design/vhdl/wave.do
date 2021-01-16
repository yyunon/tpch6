onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group Toplevel -color #FFFFFF /simtop_tc/clock_stop
add wave -noupdate -group Toplevel -color #FFFFFF /simtop_tc/kcd_clk
add wave -noupdate -group Toplevel -color #FFFFFF /simtop_tc/kcd_reset
add wave -noupdate -group Toplevel -color #FFFFFF /simtop_tc/bcd_clk
add wave -noupdate -group Toplevel -color #FFFFFF /simtop_tc/bcd_reset
add wave -noupdate -group Toplevel -color #FFFFFF /simtop_tc/mmio_awvalid
add wave -noupdate -group Toplevel -color #FFFFFF /simtop_tc/mmio_awready
add wave -noupdate -group Toplevel -color #FFFFFF /simtop_tc/mmio_awaddr
add wave -noupdate -group Toplevel -color #FFFFFF /simtop_tc/mmio_wvalid
add wave -noupdate -group Toplevel -color #FFFFFF /simtop_tc/mmio_wready
add wave -noupdate -group Toplevel -color #FFFFFF /simtop_tc/mmio_wdata
add wave -noupdate -group Toplevel -color #FFFFFF /simtop_tc/mmio_wstrb
add wave -noupdate -group Toplevel -color #FFFFFF /simtop_tc/mmio_bvalid
add wave -noupdate -group Toplevel -color #FFFFFF /simtop_tc/mmio_bready
add wave -noupdate -group Toplevel -color #FFFFFF /simtop_tc/mmio_bresp
add wave -noupdate -group Toplevel -color #FFFFFF /simtop_tc/mmio_arvalid
add wave -noupdate -group Toplevel -color #FFFFFF /simtop_tc/mmio_arready
add wave -noupdate -group Toplevel -color #FFFFFF /simtop_tc/mmio_araddr
add wave -noupdate -group Toplevel -color #FFFFFF /simtop_tc/mmio_rvalid
add wave -noupdate -group Toplevel -color #FFFFFF /simtop_tc/mmio_rready
add wave -noupdate -group Toplevel -color #FFFFFF /simtop_tc/mmio_rdata
add wave -noupdate -group Toplevel -color #FFFFFF /simtop_tc/mmio_rresp
add wave -noupdate -group Toplevel -color #FFFFFF /simtop_tc/mmio_source
add wave -noupdate -group Toplevel -color #FFFFFF /simtop_tc/mmio_sink
add wave -noupdate -group Toplevel -color #FFFFFF /simtop_tc/bus_rreq_addr
add wave -noupdate -group Toplevel -color #FFFFFF /simtop_tc/bus_rreq_len
add wave -noupdate -group Toplevel -color #FFFFFF /simtop_tc/bus_rreq_valid
add wave -noupdate -group Toplevel -color #FFFFFF /simtop_tc/bus_rreq_ready
add wave -noupdate -group Toplevel -color #FFFFFF /simtop_tc/bus_rdat_data
add wave -noupdate -group Toplevel -color #FFFFFF /simtop_tc/bus_rdat_last
add wave -noupdate -group Toplevel -color #FFFFFF /simtop_tc/bus_rdat_valid
add wave -noupdate -group Toplevel -color #FFFFFF /simtop_tc/bus_rdat_ready
add wave -noupdate -group Toplevel -color #FFFFFF /simtop_tc/bus_wreq_addr
add wave -noupdate -group Toplevel -color #FFFFFF /simtop_tc/bus_wreq_len
add wave -noupdate -group Toplevel -color #FFFFFF /simtop_tc/bus_wreq_valid
add wave -noupdate -group Toplevel -color #FFFFFF /simtop_tc/bus_wreq_ready
add wave -noupdate -group Toplevel -color #FFFFFF /simtop_tc/bus_wdat_data
add wave -noupdate -group Toplevel -color #FFFFFF /simtop_tc/bus_wdat_strobe
add wave -noupdate -group Toplevel -color #FFFFFF /simtop_tc/bus_wdat_last
add wave -noupdate -group Toplevel -color #FFFFFF /simtop_tc/bus_wdat_valid
add wave -noupdate -group Toplevel -color #FFFFFF /simtop_tc/bus_wdat_ready
add wave -noupdate -group Forecast_Mantle_inst -color #00FFFF /simtop_tc/Forecast_Mantle_inst/bcd_clk
add wave -noupdate -group Forecast_Mantle_inst -color #00FFFF /simtop_tc/Forecast_Mantle_inst/bcd_reset
add wave -noupdate -group Forecast_Mantle_inst -color #00FFFF /simtop_tc/Forecast_Mantle_inst/kcd_clk
add wave -noupdate -group Forecast_Mantle_inst -color #00FFFF /simtop_tc/Forecast_Mantle_inst/kcd_reset
add wave -noupdate -group Forecast_Mantle_inst -color #00FFFF /simtop_tc/Forecast_Mantle_inst/mmio_awvalid
add wave -noupdate -group Forecast_Mantle_inst -color #FFFF00 /simtop_tc/Forecast_Mantle_inst/mmio_awready
add wave -noupdate -group Forecast_Mantle_inst -color #00FFFF /simtop_tc/Forecast_Mantle_inst/mmio_awaddr
add wave -noupdate -group Forecast_Mantle_inst -color #00FFFF /simtop_tc/Forecast_Mantle_inst/mmio_wvalid
add wave -noupdate -group Forecast_Mantle_inst -color #FFFF00 /simtop_tc/Forecast_Mantle_inst/mmio_wready
add wave -noupdate -group Forecast_Mantle_inst -color #00FFFF /simtop_tc/Forecast_Mantle_inst/mmio_wdata
add wave -noupdate -group Forecast_Mantle_inst -color #00FFFF /simtop_tc/Forecast_Mantle_inst/mmio_wstrb
add wave -noupdate -group Forecast_Mantle_inst -color #FFFF00 /simtop_tc/Forecast_Mantle_inst/mmio_bvalid
add wave -noupdate -group Forecast_Mantle_inst -color #00FFFF /simtop_tc/Forecast_Mantle_inst/mmio_bready
add wave -noupdate -group Forecast_Mantle_inst -color #FFFF00 /simtop_tc/Forecast_Mantle_inst/mmio_bresp
add wave -noupdate -group Forecast_Mantle_inst -color #00FFFF /simtop_tc/Forecast_Mantle_inst/mmio_arvalid
add wave -noupdate -group Forecast_Mantle_inst -color #FFFF00 /simtop_tc/Forecast_Mantle_inst/mmio_arready
add wave -noupdate -group Forecast_Mantle_inst -color #00FFFF /simtop_tc/Forecast_Mantle_inst/mmio_araddr
add wave -noupdate -group Forecast_Mantle_inst -color #FFFF00 /simtop_tc/Forecast_Mantle_inst/mmio_rvalid
add wave -noupdate -group Forecast_Mantle_inst -color #00FFFF /simtop_tc/Forecast_Mantle_inst/mmio_rready
add wave -noupdate -group Forecast_Mantle_inst -color #FFFF00 /simtop_tc/Forecast_Mantle_inst/mmio_rdata
add wave -noupdate -group Forecast_Mantle_inst -color #FFFF00 /simtop_tc/Forecast_Mantle_inst/mmio_rresp
add wave -noupdate -group Forecast_Mantle_inst -color #FFFF00 /simtop_tc/Forecast_Mantle_inst/rd_mst_rreq_valid
add wave -noupdate -group Forecast_Mantle_inst -color #00FFFF /simtop_tc/Forecast_Mantle_inst/rd_mst_rreq_ready
add wave -noupdate -group Forecast_Mantle_inst -color #FFFF00 /simtop_tc/Forecast_Mantle_inst/rd_mst_rreq_addr
add wave -noupdate -group Forecast_Mantle_inst -color #FFFF00 /simtop_tc/Forecast_Mantle_inst/rd_mst_rreq_len
add wave -noupdate -group Forecast_Mantle_inst -color #00FFFF /simtop_tc/Forecast_Mantle_inst/rd_mst_rdat_valid
add wave -noupdate -group Forecast_Mantle_inst -color #FFFF00 /simtop_tc/Forecast_Mantle_inst/rd_mst_rdat_ready
add wave -noupdate -group Forecast_Mantle_inst -color #00FFFF /simtop_tc/Forecast_Mantle_inst/rd_mst_rdat_data
add wave -noupdate -group Forecast_Mantle_inst -color #00FFFF /simtop_tc/Forecast_Mantle_inst/rd_mst_rdat_last
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_mmio_awvalid
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_mmio_awready
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_mmio_awaddr
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_mmio_wvalid
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_mmio_wready
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_mmio_wdata
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_mmio_wstrb
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_mmio_bvalid
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_mmio_bready
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_mmio_bresp
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_mmio_arvalid
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_mmio_arready
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_mmio_araddr
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_mmio_rvalid
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_mmio_rready
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_mmio_rdata
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_mmio_rresp
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_quantity_valid
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_quantity_ready
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_quantity_dvalid
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_quantity_last
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_quantity
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_extendedprice_valid
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_extendedprice_ready
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_extendedprice_dvalid
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_extendedprice_last
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_extendedprice
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_discount_valid
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_discount_ready
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_discount_dvalid
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_discount_last
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_discount
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_shipdate_valid
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_shipdate_ready
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_shipdate_dvalid
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_shipdate_last
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_shipdate
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_quantity_unl_valid
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_quantity_unl_ready
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_quantity_unl_tag
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_extendedprice_unl_valid
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_extendedprice_unl_ready
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_extendedprice_unl_tag
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_discount_unl_valid
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_discount_unl_ready
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_discount_unl_tag
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_shipdate_unl_valid
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_shipdate_unl_ready
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_shipdate_unl_tag
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_quantity_cmd_valid
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_quantity_cmd_ready
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_quantity_cmd_firstIdx
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_quantity_cmd_lastIdx
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_quantity_cmd_ctrl
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_quantity_cmd_tag
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_extendedprice_cmd_valid
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_extendedprice_cmd_ready
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_extendedprice_cmd_firstIdx
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_extendedprice_cmd_lastIdx
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_extendedprice_cmd_ctrl
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_extendedprice_cmd_tag
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_discount_cmd_valid
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_discount_cmd_ready
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_discount_cmd_firstIdx
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_discount_cmd_lastIdx
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_discount_cmd_ctrl
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_discount_cmd_tag
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_shipdate_cmd_valid
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_shipdate_cmd_ready
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_shipdate_cmd_firstIdx
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_shipdate_cmd_lastIdx
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_shipdate_cmd_ctrl
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst_l_shipdate_cmd_tag
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_quantity_valid
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_quantity_ready
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_quantity_dvalid
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_quantity_last
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_quantity
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_quantity_bus_rreq_valid
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_quantity_bus_rreq_ready
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_quantity_bus_rreq_addr
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_quantity_bus_rreq_len
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_quantity_bus_rdat_valid
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_quantity_bus_rdat_ready
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_quantity_bus_rdat_data
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_quantity_bus_rdat_last
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_quantity_cmd_valid
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_quantity_cmd_ready
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_quantity_cmd_firstIdx
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_quantity_cmd_lastIdx
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_quantity_cmd_ctrl
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_quantity_cmd_tag
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_quantity_unl_valid
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_quantity_unl_ready
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_quantity_unl_tag
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_extendedprice_valid
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_extendedprice_ready
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_extendedprice_dvalid
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_extendedprice_last
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_extendedprice
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_extendedprice_bus_rreq_valid
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_extendedprice_bus_rreq_ready
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_extendedprice_bus_rreq_addr
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_extendedprice_bus_rreq_len
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_extendedprice_bus_rdat_valid
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_extendedprice_bus_rdat_ready
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_extendedprice_bus_rdat_data
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_extendedprice_bus_rdat_last
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_extendedprice_cmd_valid
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_extendedprice_cmd_ready
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_extendedprice_cmd_firstIdx
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_extendedprice_cmd_lastIdx
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_extendedprice_cmd_ctrl
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_extendedprice_cmd_tag
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_extendedprice_unl_valid
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_extendedprice_unl_ready
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_extendedprice_unl_tag
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_discount_valid
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_discount_ready
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_discount_dvalid
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_discount_last
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_discount
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_discount_bus_rreq_valid
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_discount_bus_rreq_ready
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_discount_bus_rreq_addr
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_discount_bus_rreq_len
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_discount_bus_rdat_valid
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_discount_bus_rdat_ready
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_discount_bus_rdat_data
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_discount_bus_rdat_last
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_discount_cmd_valid
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_discount_cmd_ready
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_discount_cmd_firstIdx
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_discount_cmd_lastIdx
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_discount_cmd_ctrl
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_discount_cmd_tag
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_discount_unl_valid
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_discount_unl_ready
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_discount_unl_tag
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_shipdate_valid
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_shipdate_ready
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_shipdate_dvalid
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_shipdate_last
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_shipdate
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_shipdate_bus_rreq_valid
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_shipdate_bus_rreq_ready
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_shipdate_bus_rreq_addr
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_shipdate_bus_rreq_len
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_shipdate_bus_rdat_valid
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_shipdate_bus_rdat_ready
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_shipdate_bus_rdat_data
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_shipdate_bus_rdat_last
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_shipdate_cmd_valid
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_shipdate_cmd_ready
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_shipdate_cmd_firstIdx
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_shipdate_cmd_lastIdx
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_shipdate_cmd_ctrl
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_shipdate_cmd_tag
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_shipdate_unl_valid
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_shipdate_unl_ready
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/Forecast_l_inst_l_shipdate_unl_tag
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/RDAW64DW512LW8BS1BM16_inst_mst_rreq_valid
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/RDAW64DW512LW8BS1BM16_inst_mst_rreq_ready
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/RDAW64DW512LW8BS1BM16_inst_mst_rreq_addr
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/RDAW64DW512LW8BS1BM16_inst_mst_rreq_len
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/RDAW64DW512LW8BS1BM16_inst_mst_rdat_valid
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/RDAW64DW512LW8BS1BM16_inst_mst_rdat_ready
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/RDAW64DW512LW8BS1BM16_inst_mst_rdat_data
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/RDAW64DW512LW8BS1BM16_inst_mst_rdat_last
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/RDAW64DW512LW8BS1BM16_inst_bsv_rreq_valid
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/RDAW64DW512LW8BS1BM16_inst_bsv_rreq_ready
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/RDAW64DW512LW8BS1BM16_inst_bsv_rreq_addr
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/RDAW64DW512LW8BS1BM16_inst_bsv_rreq_len
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/RDAW64DW512LW8BS1BM16_inst_bsv_rdat_valid
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/RDAW64DW512LW8BS1BM16_inst_bsv_rdat_ready
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/RDAW64DW512LW8BS1BM16_inst_bsv_rdat_data
add wave -noupdate -group Forecast_Mantle_inst -color #FFFFFF /simtop_tc/Forecast_Mantle_inst/RDAW64DW512LW8BS1BM16_inst_bsv_rdat_last
add wave -noupdate -group rmem_inst -color #00FFFF /simtop_tc/rmem_inst/clk
add wave -noupdate -group rmem_inst -color #00FFFF /simtop_tc/rmem_inst/reset
add wave -noupdate -group rmem_inst -color #00FFFF /simtop_tc/rmem_inst/rreq_valid
add wave -noupdate -group rmem_inst -color #FFFF00 /simtop_tc/rmem_inst/rreq_ready
add wave -noupdate -group rmem_inst -color #00FFFF /simtop_tc/rmem_inst/rreq_addr
add wave -noupdate -group rmem_inst -color #00FFFF /simtop_tc/rmem_inst/rreq_len
add wave -noupdate -group rmem_inst -color #FFFF00 /simtop_tc/rmem_inst/rdat_valid
add wave -noupdate -group rmem_inst -color #00FFFF /simtop_tc/rmem_inst/rdat_ready
add wave -noupdate -group rmem_inst -color #FFFF00 /simtop_tc/rmem_inst/rdat_data
add wave -noupdate -group rmem_inst -color #FFFF00 /simtop_tc/rmem_inst/rdat_last
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/kcd_clk
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/kcd_reset
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_quantity_valid
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_quantity_ready
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_quantity_dvalid
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_quantity_last
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_quantity
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_quantity_unl_valid
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_quantity_unl_ready
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_quantity_unl_tag
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_quantity_cmd_valid
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_quantity_cmd_ready
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_quantity_cmd_firstIdx
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_quantity_cmd_lastIdx
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_quantity_cmd_tag
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_extendedprice_valid
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_extendedprice_ready
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_extendedprice_dvalid
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_extendedprice_last
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_extendedprice
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_extendedprice_unl_valid
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_extendedprice_unl_ready
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_extendedprice_unl_tag
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_extendedprice_cmd_valid
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_extendedprice_cmd_ready
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_extendedprice_cmd_firstIdx
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_extendedprice_cmd_lastIdx
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_extendedprice_cmd_tag
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_discount_valid
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_discount_ready
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_discount_dvalid
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_discount_last
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_discount
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_discount_unl_valid
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_discount_unl_ready
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_discount_unl_tag
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_discount_cmd_valid
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_discount_cmd_ready
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_discount_cmd_firstIdx
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_discount_cmd_lastIdx
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_discount_cmd_tag
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_shipdate_valid
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_shipdate_ready
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_shipdate_dvalid
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_shipdate_last
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_shipdate
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_shipdate_unl_valid
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_shipdate_unl_ready
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_shipdate_unl_tag
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_shipdate_cmd_valid
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_shipdate_cmd_ready
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_shipdate_cmd_firstIdx
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_shipdate_cmd_lastIdx
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_shipdate_cmd_tag
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/start
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/stop
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/reset
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/idle
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/busy
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/done
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/result
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_firstidx
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/l_lastidx
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/hash_addr_pointer
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/state_slv
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/state
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/state_next
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/filter_in_ready
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/filter_out_valid
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/filter_out_ready
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/filter_out_last
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/filter_out_strb
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/sum_out_valid
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/sum_out_ready
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/sum_out_data
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/lessthan_out_ready
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/lessthan_out_valid
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/lessthan_out_data
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/between_out_ready
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/between_out_valid
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/between_out_data
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/date_engine_out_ready
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/date_engine_out_valid
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/date_engine_out_data
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/matcher_out_s_valid
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/matcher_out_s_ready
add wave -noupdate /simtop_tc/Forecast_Mantle_inst/Forecast_Nucleus_inst/Forecast_inst/out_predicate
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 256
configure wave -valuecolwidth 192
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {1050005250 ps}
