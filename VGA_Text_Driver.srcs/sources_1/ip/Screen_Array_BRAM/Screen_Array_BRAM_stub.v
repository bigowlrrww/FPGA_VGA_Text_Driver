// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.1 (win64) Build 2552052 Fri May 24 14:49:42 MDT 2019
// Date        : Fri Oct 18 21:14:46 2019
// Host        : DESKTOP-5UD6CLR running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               d:/Vivado_Projects/ECEN340_Final/ECEN340_Final.srcs/sources_1/ip/Screen_Array_BRAM/Screen_Array_BRAM_stub.v
// Design      : Screen_Array_BRAM
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a35tcpg236-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_4_3,Vivado 2019.1" *)
module Screen_Array_BRAM(clka, wea, addra, dina, clkb, addrb, doutb)
/* synthesis syn_black_box black_box_pad_pin="clka,wea[0:0],addra[11:0],dina[7:0],clkb,addrb[11:0],doutb[7:0]" */;
  input clka;
  input [0:0]wea;
  input [11:0]addra;
  input [7:0]dina;
  input clkb;
  input [11:0]addrb;
  output [7:0]doutb;
endmodule
