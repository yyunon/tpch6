// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2020.1 (lin64) Build 2902540 Wed May 27 19:54:35 MDT 2020
// Date        : Wed Mar 31 16:21:47 2021
// Host        : yuksel-machine running 64-bit unknown
// Command     : write_verilog -force -mode synth_stub
//               /home/yyunon/thesis_journals/resources/fletcher-aws/examples/tpch6/1DDR/ip/floating_point_0_2/floating_point_0_2_stub.v
// Design      : floating_point_0_2
// Purpose     : Stub declaration of top-level module interface
// Device      : xcvu9p-flgb2104-2-i
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "floating_point_v7_1_10,Vivado 2020.1" *)
module floating_point_0_2(aclk, s_axis_a_tvalid, s_axis_a_tready, 
  s_axis_a_tdata, s_axis_a_tuser, s_axis_a_tlast, m_axis_result_tvalid, 
  m_axis_result_tready, m_axis_result_tdata, m_axis_result_tuser, m_axis_result_tlast)
/* synthesis syn_black_box black_box_pad_pin="aclk,s_axis_a_tvalid,s_axis_a_tready,s_axis_a_tdata[63:0],s_axis_a_tuser[0:0],s_axis_a_tlast,m_axis_result_tvalid,m_axis_result_tready,m_axis_result_tdata[63:0],m_axis_result_tuser[0:0],m_axis_result_tlast" */;
  input aclk;
  input s_axis_a_tvalid;
  output s_axis_a_tready;
  input [63:0]s_axis_a_tdata;
  input [0:0]s_axis_a_tuser;
  input s_axis_a_tlast;
  output m_axis_result_tvalid;
  input m_axis_result_tready;
  output [63:0]m_axis_result_tdata;
  output [0:0]m_axis_result_tuser;
  output m_axis_result_tlast;
endmodule
