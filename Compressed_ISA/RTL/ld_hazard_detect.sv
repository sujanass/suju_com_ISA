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
* File Name : ld_hazard_detect.sv

* Purpose :

* Creation Date : 10-02-2023

* Last Modified : Sat 04 Mar 2023 09:05:54 PM IST

* Created By :  

//////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

`timescale 1ns / 1ps
module load_hazard_ctrl
#(
parameter GPR_ADDR_WIDTH = 5
)
(
    input logic 		                ld_hz_ctrl_clk	,
    input logic 		                ld_hz_ctrl_rst	,
    input logic 		                id_ex_mem_rd_en	,
    input logic [GPR_ADDR_WIDTH-1:0]	id_ex_rd	    ,
    input logic [GPR_ADDR_WIDTH-1:0]	if_id_rs1	    ,
    input logic [GPR_ADDR_WIDTH-1:0]	if_id_rs2	    ,
    output logic 		                stall_pipeline  ,
    output logic                        stall_en        
);

    assign stall_en = (((id_ex_rd!={GPR_ADDR_WIDTH{1'b0}}) && (id_ex_mem_rd_en) && ((id_ex_rd == if_id_rs1) || (id_ex_rd == if_id_rs2)))) ? 1'b1 : 1'b0;
        
    always_ff@(posedge ld_hz_ctrl_clk or negedge ld_hz_ctrl_rst)
    begin

    	if(!ld_hz_ctrl_rst)
    	begin
    		stall_pipeline  <= 1'd0;
    	end
    	else
    	begin            
    		if((id_ex_rd!={GPR_ADDR_WIDTH{1'b0}}) && (id_ex_mem_rd_en) && ((id_ex_rd == if_id_rs1) || (id_ex_rd == if_id_rs2)))
    		    begin
    			    stall_pipeline <= 1'b1;
    		    end
    		else
    		    begin
    			    stall_pipeline <= 1'b0;
    		    end
    	end
    end
endmodule


