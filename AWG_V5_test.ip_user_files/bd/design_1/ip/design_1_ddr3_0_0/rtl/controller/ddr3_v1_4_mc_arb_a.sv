/******************************************************************************
// (c) Copyright 2013 - 2014 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
******************************************************************************/
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor             : Xilinx
// \   \   \/     Version            : 1.1
//  \   \         Application        : MIG
//  /   /         Filename           : ddr3_v1_4_16_mc_arb_a.sv
// /___/   /\     Date Last Modified : $Date: 2014/09/03 $
// \   \  /  \    Date Created       : Thu Apr 18 2013
//  \___\/\___\
//
// Device           : UltraScale
// Design Name      : DDR4 SDRAM & DDR3 SDRAM
// Purpose          :
//                   ddr3_v1_4_16_mc_arb_a module
// Reference        :
// Revision History :
//*****************************************************************************

`timescale 1ns/100ps

module ddr3_v1_4_16_mc_arb_a #(parameter
    TCQ        = 0.1   
   ,RKBITS     = 2
   ,RANK_SLAB  = 4
)(
    input        clk
   ,input        rst
   ,input  wire [7:0] strict_fifo_output

   ,output reg       winAct
   ,output reg [7:0] winPort
   ,output reg [RANK_SLAB-1:0] act_rank_update
   ,output     [7:0] act_winPort_nxt

   ,input  [RKBITS*8-1:0] cmdRank 
   ,input  [7:0] req
);

function [1:0] findWin;
   input       last;
   input [1:0] reqs;
casez (reqs)
   2'b01: findWin = 2'b01;
   2'b10: findWin = 2'b10;
   2'b11: findWin = last ? 2'b01 : 2'b10;
   default: findWin = 2'b00;
endcase
endfunction

// regs
reg       last10;
reg       last32;
reg       last54;
reg       last76;
reg       last3210;
reg       last7654;
reg       last;

// wire-regs
reg [1:0] w10;
reg [1:0] w32;
reg [1:0] w54;
reg [1:0] w76;
reg [1:0] win3210;
reg [1:0] win7654;
reg [1:0] winner;
reg [7:0] win76543210;

reg [7:0] lastWinPort; 
reg [7:0] winSequentialAccess;
reg [7:0] winPortSequentialExtTmp;

reg [7:0] counter1;

always @(*) begin
   winPortSequentialExtTmp = (lastWinPort << 1);
   winSequentialAccess = !lastWinPort ? 8'b0 : winPortSequentialExtTmp ? winPortSequentialExtTmp : 8'b1 ;
   
   if( (strict_fifo_output & req) != 8'b0) begin
      win76543210 = strict_fifo_output;
   end
   else if(winSequentialAccess & req) 
       win76543210 = winSequentialAccess;
   else begin
//       w10 = findWin(last10, req[1:0]);
//       w32 = findWin(last32, req[3:2]);
//       w54 = findWin(last54, req[5:4]);
//       w76 = findWin(last76, req[7:6]);
//       win3210 = findWin(last3210, {|req[3:2], |req[1:0]});
//       win7654 = findWin(last7654, {|req[7:6], |req[5:4]});
//       winner = findWin(last, {|req[7:4], |req[3:0]});
//       casez({winner, win7654, win3210})
//            6'b1010zz:  win76543210 = {w76, 6'b000000};
//            6'b1001zz:  win76543210 = {2'b00, w54, 4'b0000};
//            6'b01zz10:  win76543210 = {4'b0000, w32, 2'b00};
//            6'b01zz01:  win76543210 = {6'b000000 , w10};
//            default:    win76543210 = 8'b00000000; 
//       endcase
        casez(req)
            8'bzzzzzzz1: win76543210 = 8'b00000001;
            8'bzzzzzz1z: win76543210 = 8'b00000010;
            8'bzzzzz1zz: win76543210 = 8'b00000100;
            8'bzzzz1zzz: win76543210 = 8'b00001000;
            8'bzzz1zzzz: win76543210 = 8'b00010000;
            8'bzz1zzzzz: win76543210 = 8'b00100000;
            8'bz1zzzzzz: win76543210 = 8'b01000000;
            8'b1zzzzzzz: win76543210 = 8'b10000000;
            default: win76543210 = 8'b00000000;
        endcase
    end
end

wire winAct_nxt = | req[7:0];

wire [RKBITS-1:0] act_rank_encode =   ( { RKBITS { win76543210[7] } } & cmdRank[RKBITS*8-1:RKBITS*7] )
                                    | ( { RKBITS { win76543210[6] } } & cmdRank[RKBITS*7-1:RKBITS*6] )
                                    | ( { RKBITS { win76543210[5] } } & cmdRank[RKBITS*6-1:RKBITS*5] )
                                    | ( { RKBITS { win76543210[4] } } & cmdRank[RKBITS*5-1:RKBITS*4] )
                                    | ( { RKBITS { win76543210[3] } } & cmdRank[RKBITS*4-1:RKBITS*3] )
                                    | ( { RKBITS { win76543210[2] } } & cmdRank[RKBITS*3-1:RKBITS*2] )
                                    | ( { RKBITS { win76543210[1] } } & cmdRank[RKBITS*2-1:RKBITS*1] )
                                    | ( { RKBITS { win76543210[0] } } & cmdRank[RKBITS*1-1:RKBITS*0] );
                                    
                                   
always @(*) begin
  act_rank_update = '0;
  act_rank_update[act_rank_encode] = winAct_nxt;
end

assign act_winPort_nxt = win76543210;

always @(posedge clk) if (rst) begin
   last <= 1'b0;
   last10 <= 1'b0;
   last32 <= 1'b0;
   last54 <= 1'b0;
   last76 <= 1'b0;
   last3210 <= 1'b0;
   last7654 <= 1'b0;
   
   winPort <= 8'b0;
   winAct  <= 1'b0;
   counter1 <= 8'b0;
end else begin:arbing
   winAct  <= #TCQ winAct_nxt;
   counter1 <= counter1 + 1;
   casez (win76543210)
      8'bzzzzzzz1: begin
         last <= #TCQ 1'b0;
         last3210 <= #TCQ 1'b0;
         last10 <= #TCQ 1'b0;
         winPort <= #TCQ win76543210;
         lastWinPort <= #TCQ win76543210;
         counter1 <= 8'b0;
      end
      8'bzzzzzz1z: begin
         last <= #TCQ 1'b0;
         last3210 <= #TCQ 1'b0;
         last10 <= #TCQ 1'b1;
         winPort <= #TCQ win76543210;
         lastWinPort <= #TCQ win76543210;
         counter1 <= 8'b0;
      end
      8'bzzzzz1zz: begin
         last <= #TCQ 1'b0;
         last3210 <= #TCQ 1'b1;
         last32 <= #TCQ 1'b0;
         winPort <= #TCQ win76543210;
         lastWinPort <= #TCQ win76543210;
         counter1 <= 8'b0;
      end
      8'bzzzz1zzz: begin
         last <= #TCQ 1'b0;
         last3210 <= #TCQ 1'b1;
         last32 <= #TCQ 1'b1;
         winPort <= #TCQ win76543210;
         lastWinPort <= #TCQ win76543210;
         counter1 <= 8'b0;
      end
      8'bzzz1zzzz: begin
         last <= #TCQ 1'b1;
         last7654 <= #TCQ 1'b0;
         last54 <= #TCQ 1'b0;
         winPort <= #TCQ win76543210;
         lastWinPort <= #TCQ win76543210;
         counter1 <= 8'b0;
      end
      8'bzz1zzzzz: begin
         last <= #TCQ 1'b1;
         last7654 <= #TCQ 1'b0;
         last54 <= #TCQ 1'b1;
         winPort <= #TCQ win76543210;
         lastWinPort <= #TCQ win76543210;
         counter1 <= 8'b0;
      end
      8'bz1zzzzzz: begin
         last <= #TCQ 1'b1;
         last7654 <= #TCQ 1'b1;
         last76 <= #TCQ 1'b0;
         winPort <= #TCQ win76543210;
         lastWinPort <= #TCQ win76543210;
         counter1 <= 8'b0;
      end
      8'b1zzzzzzz: begin
         last <= #TCQ 1'b1;
         last7654 <= #TCQ 1'b1;
         last76 <= #TCQ 1'b1;
         winPort <= #TCQ win76543210;
         lastWinPort <= #TCQ win76543210;
         counter1 <= 8'b0;
      end
      default: begin
         winPort <= #TCQ 8'b00000000;
      end
   endcase
end

//synopsys translate_off

`ifdef MEM_INTERNAL
// Events - When asserted high in a test that passes all verification checks, these coverage
//          properties indicate that a functional coverage event has been hit.
// ---------------------------------------------------------------------------------------------

integer group_index;
integer rank_index;

// All groups issue activate
reg  [3:0] e_act_group;        // Track activates by group
reg  [3:0] e_act_group_nxt;
reg  [3:0] e_act_group_rank[RANK_SLAB-1:0];     // Track activates by group and rank
reg  [3:0] e_act_group_rank_nxt[RANK_SLAB-1:0];
reg  [RKBITS-1:0] e_act_rank_encode;
reg  [RANK_SLAB:0] e_act_all_group_rank;     // Count activates by group and rank
reg  [RANK_SLAB:0] e_act_all_group_rank_nxt;
always @(*) begin
  e_act_all_group_rank_nxt = '0;
  for (group_index = 0; group_index < 4; group_index = group_index + 1) begin
    e_act_group_nxt[group_index] = ( e_act_group[group_index] | winPort[group_index] ) & ~( & e_act_group );
    for (rank_index = 0; rank_index < 4; rank_index = rank_index + 1) begin
      e_act_group_rank_nxt[rank_index][group_index] = ( e_act_group_rank[rank_index][group_index]
                                                        | ( winPort[group_index] & ( e_act_rank_encode == rank_index ) ) )
                                                      & ~( e_act_all_group_rank == 5'd16 );
      e_act_all_group_rank_nxt += e_act_group_rank[rank_index][group_index];
    end
  end
end
always @(posedge clk) if (rst) begin
  for (group_index = 0; group_index < 4; group_index = group_index + 1) begin
    for (rank_index = 0; rank_index < RANK_SLAB; rank_index = rank_index + 1) begin
      e_act_group_rank[rank_index][group_index]      <= #TCQ '0;
    end
  end
  e_act_group           <= #TCQ '0;
  e_act_rank_encode     <= #TCQ '0;
  e_act_all_group_rank  <= #TCQ '0;
end else begin
  for (group_index = 0; group_index < 4; group_index = group_index + 1) begin
    for (rank_index = 0; rank_index < RANK_SLAB; rank_index = rank_index + 1) begin
      e_act_group_rank[rank_index][group_index]      <= #TCQ e_act_group_rank_nxt[rank_index][group_index];
    end
  end
  e_act_group           <= #TCQ e_act_group_nxt;
  e_act_rank_encode     <= #TCQ act_rank_encode;
  e_act_all_group_rank  <= #TCQ e_act_all_group_rank_nxt;
end

// All Group FSMs have issued an activate
wire   e_mc_arb_a_000_act = & e_act_group;
always @(posedge clk) mc_arb_a_000: if (~rst) cover property (e_mc_arb_a_000_act);

// All ranks in all Group FSMs have been activated
wire   e_mc_arb_a_001_act = ( e_act_all_group_rank == 5'd16 );
always @(posedge clk) mc_arb_a_001: if (~rst) cover property (e_mc_arb_a_001_act);

reg  [31:0] e_act_shift;
wire [31:0] e_act_shift_nxt = { e_act_shift[30:0], | win3210 };
always @(posedge clk) begin
 e_act_shift <= #TCQ e_act_shift_nxt;
end

// 8 activates in a row
wire   e_mc_arb_a_002_act = & e_act_shift[7:0];
always @(posedge clk) mc_arb_a_002: if (~rst) cover property (e_mc_arb_a_002_act);

// 16 activates in a row
wire   e_mc_arb_a_003_act = & e_act_shift[15:0];
always @(posedge clk) mc_arb_a_003: if (~rst) cover property (e_mc_arb_a_003_act);

// 32 activates in a row
wire   e_mc_arb_a_004_act = & e_act_shift[31:0];
always @(posedge clk) mc_arb_a_004: if (~rst) cover property (e_mc_arb_a_004_act);

// All 4 Group FSMs requesting activate at the same time
wire   e_mc_arb_a_005_act = & req;
always @(posedge clk) mc_arb_a_005: if (~rst) cover property (e_mc_arb_a_005_act);



// Asserts - When asserted high, an illegal condition has been detected and the test has failed.
// ---------------------------------------------------------------------------------------------


// One-hot cold checks
reg [1:0]  a_win3210_hot;
always @(*) begin
  a_win3210_hot = 2'b0;
  for (group_index = 0; group_index < 4; group_index = group_index + 1) begin
    a_win3210_hot         += win3210[group_index];
  end
end
wire       a_mc_arb_a_000_hot = ( a_win3210_hot > 2'd1 );
always @(posedge clk) if (~rst) assert property (~a_mc_arb_a_000_hot);


`endif

//synopsys translate_on

endmodule


