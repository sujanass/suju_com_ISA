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
* File Name : forwarding_unit.sv

* Purpose :

* Creation Date : 10-02-2023

* Last Modified : Tue 14 Feb 2023 03:28:25 PM IST

* Created By :  

//////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

`timescale 1ns / 1ps
module forwarding #(parameter GPR_ADDR_WIDTH = 5)
(
    input logic 			                fwd_clk		    ,
    input logic 			                fwd_rst		    ,
    input logic 			                reg_wr_en	    ,
    input logic [GPR_ADDR_WIDTH-1:0]		rd		        ,
    input logic [GPR_ADDR_WIDTH-1:0] 		rs1		        ,
    input logic [GPR_ADDR_WIDTH-1:0]		rs2		        ,
    input logic                             stall_pipeline  ,
    output logic  [1:0]    	                forward_a	    ,
    output logic  [1:0]    	                forward_b       
);
    
    
    
    logic [GPR_ADDR_WIDTH-1:0] id_ex_rd		      ;
    logic [GPR_ADDR_WIDTH-1:0] ex_mem_rd		  ;
    logic [GPR_ADDR_WIDTH-1:0] mem_wb_rd		  ;
    logic [GPR_ADDR_WIDTH-1:0] wb_rd              ;
    logic [GPR_ADDR_WIDTH-1:0] id_ex_rs1		  ;
    logic [GPR_ADDR_WIDTH-1:0] id_ex_rs2		  ;
    logic	                   id_ex_reg_wr_en	  ;
    logic	                   ex_mem_reg_wr_en	  ;
    logic	                   mem_wb_reg_wr_en	  ;
    logic                      wb_reg_wr_en       ;
    logic 	                   rs1_fwd_ex_mem	  ; 
    logic 	                   rs1_fwd_mem_wb	  ;             
    logic 	                   rs2_fwd_ex_mem	  ;
    logic 	                   rs2_fwd_mem_wb	  ;
    logic                      rs1_fwd_wb         ;
    logic                      rs2_fwd_wb         ;
        
    
    always_ff@(posedge fwd_clk or negedge fwd_rst)
    begin
    	if(!fwd_rst)
    	begin
    		id_ex_rd	        <= 	{GPR_ADDR_WIDTH{1'b0}}		;		
    		ex_mem_rd	        <= 	{GPR_ADDR_WIDTH{1'b0}}		;
    		mem_wb_rd	        <= 	{GPR_ADDR_WIDTH{1'b0}}		;
    		wb_rd 		        <=  {GPR_ADDR_WIDTH{1'b0}}      ;
    		id_ex_rs1	        <= 	{GPR_ADDR_WIDTH{1'b0}}		;
    		id_ex_rs2	        <= 	{GPR_ADDR_WIDTH{1'b0}}		;
    		id_ex_reg_wr_en     <= 	1'd0		                ;
    		ex_mem_reg_wr_en    <= 	1'b0 		                ;
    		mem_wb_reg_wr_en    <= 	1'b0 		                ;
            wb_reg_wr_en        <=  1'b0                        ;
    	end
    	else
    	begin
            ex_mem_rd	        <=	id_ex_rd	                ;
            mem_wb_rd	        <=	ex_mem_rd	                ;
    		wb_rd 		        <=  mem_wb_rd                   ;
    		ex_mem_reg_wr_en    <=  id_ex_reg_wr_en             ;
    		mem_wb_reg_wr_en    <=	ex_mem_reg_wr_en            ;
            wb_reg_wr_en        <=  mem_wb_reg_wr_en            ;
    
            if(!stall_pipeline)
            begin
    		    id_ex_rd	        <=	rd		                    ;
                id_ex_rs1	        <=	rs1		                    ;
                id_ex_rs2	        <=	rs2		                    ;
                id_ex_reg_wr_en     <=	reg_wr_en	                ;
            end
            else
            begin
                 id_ex_rd            <= {GPR_ADDR_WIDTH{1'b0}}       ;
                 id_ex_rs1           <= {GPR_ADDR_WIDTH{1'b0}}       ;
                 id_ex_rs2           <= {GPR_ADDR_WIDTH{1'b0}}       ;
                 id_ex_reg_wr_en     <= 1'b0                         ;
            end    
    	end
    end
    
    assign rs1_fwd_ex_mem =	((ex_mem_rd != {GPR_ADDR_WIDTH{1'b0}}) && (ex_mem_reg_wr_en == 1'b1)        && (ex_mem_rd == id_ex_rs1)); 
    assign rs1_fwd_mem_wb = ((mem_wb_rd != {GPR_ADDR_WIDTH{1'b0}}) && (mem_wb_reg_wr_en == 1'b1)        && (mem_wb_rd == id_ex_rs1) && (ex_mem_rd != id_ex_rs1)); 
    assign rs1_fwd_wb     = ((wb_rd     != {GPR_ADDR_WIDTH{1'b0}}) && (wb_reg_wr_en	    ==	1'b1)       && (wb_rd     == id_ex_rs1));
    
    assign rs2_fwd_ex_mem = ((ex_mem_reg_wr_en == 1'b1       ) && (ex_mem_rd    != {GPR_ADDR_WIDTH{1'b0}}) && (ex_mem_rd == id_ex_rs2));
    assign rs2_fwd_mem_wb = ((mem_wb_reg_wr_en == 1'b1       ) && (ex_mem_rd    != id_ex_rs2)              && (mem_wb_rd == id_ex_rs2)  && (mem_wb_rd != {GPR_ADDR_WIDTH{1'b0}}));
    assign rs2_fwd_wb     = ((wb_rd != {GPR_ADDR_WIDTH{1'b0}}) && (wb_reg_wr_en	==	1'b1)                  && (wb_rd     == id_ex_rs2));

    always_comb
    	begin
    		if(rs1_fwd_ex_mem)
    		begin
    			forward_a = 2'b01   ;
    		end
    		else if(rs1_fwd_mem_wb)
    		begin
    			forward_a = 2'b10   ;
    		end
    		else if(rs1_fwd_wb)
    		begin
    			forward_a = 2'b11   ;
    		end
    		else
    		begin
    			forward_a = 2'b00   ;
    		end
    
    	end
    
    always_comb
    	begin
    		if(rs2_fwd_ex_mem)
    		begin
    			forward_b = 2'b01   ;
    		end
    		else if(rs2_fwd_mem_wb)
    		begin
    			forward_b = 2'b10   ;
    		end
    		else if(rs2_fwd_wb)
    		begin
    			forward_b = 2'b11   ;
    		end
    		else
    		begin
    			forward_b = 2'b00   ;
    		end
    
    	end

endmodule




