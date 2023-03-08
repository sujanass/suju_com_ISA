//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////Copyright © 2022 PravegaSemi PVT LTD., All rights reserved//////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                              //
//All works published under Zilla_Gen_0 by PravegaSemi PVT LTD is copyrighted by the Association and ownership  // 
//of all right, title and interest in and to the works remains with PravegaSemi PVT LTD. No works or documents  //
//published under Zilla_Gen_0 by PravegaSemi PVT LTD may be reproduced,transmitted or copied without the express//
//written permission of PravegaSemi PVT LTD will be considered as a violations of Copyright Act and it may lead //
//to legal action.                                                                                         //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*////////////////////////////////////////////////////////////////////////////////////////////////////////////////
* File Name : mux2x1.sv

* Purpose :

* Creation Date : 10-02-2023

* Last Modified : Tue 14 Feb 2023 01:00:08 PM IST

* Created By :  

//////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

`timescale 1ns / 1ps
module mux2x1 #(parameter DATA_WIDTH = 32)
(
    input logic  [DATA_WIDTH-1:0]  		in1			            ,//from memory
    input logic  [DATA_WIDTH-1:0]  		in2			            ,//from alu
    input logic 	       		        sel			            ,
    output logic  [DATA_WIDTH-1:0]  	out			
);

    always_comb
    begin
    	if(sel)
    	begin
    		out = in1 ;
    	end
    	else
    	begin
    		out = in2 ;
    	end
    end
    
endmodule








