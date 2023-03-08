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
* File Name : data_mem.sv

* Purpose :

* Creation Date : 10-02-2023

* Last Modified : Sat 25 Feb 2023 08:00:10 AM IST

* Created By :  

//////////////////////////////////////////////////////////////////////////////////////////////////////////////// */
`timescale 1ns / 1ps

module data_mem #(parameter DATA_WIDTH = 32)
(
    input logic 			                    mem_clk				            ,
    input logic           	                    mem_rst         		        ,
    input logic 			                    wr_en				            ,
    input logic 			                    rd_en				            ,
    input logic 	[DATA_WIDTH-1       :0]   	wr_addr				            ,
    input logic     [DATA_WIDTH-1       :0]		rd_addr				            ,
    input logic	    [DATA_WIDTH-1       :0]		wr_data				            ,
    input logic     [(DATA_WIDTH>>3)-1  :0]	    byte_en				            ,
    input logic 			                    sign_bit			            ,
    input logic 			                    stall_en			            ,
    input logic	    [DATA_WIDTH-1       :0]     data_mem_read_data		        , //data memory read data
    output logic    [DATA_WIDTH-1       :0]  	rd_data				            , //to register file
    output logic	 		                    data_mem_write_en		        , //data memory write enable 
    output logic    [DATA_WIDTH-1       :0]     data_mem_write_addr		        , //data memory write address
    output logic    [DATA_WIDTH-1       :0]     data_mem_write_data		        , //data memory write address
    output logic      		                    data_mem_read_en		        , //data memory read enable
    output logic    [DATA_WIDTH-1       :0]     data_mem_read_addr		        , //data memory read address
    output logic    [(DATA_WIDTH>>3)-1  :0]     data_mem_strobe		            
    
);					
    logic [(DATA_WIDTH>>3)-1:0]       ld_byte_en              ;
    logic                             ld_sign_bit             ;
    logic                             read_data_sel           ;
    logic [DATA_WIDTH-1    :0]        rd_data_r	              ;
    logic [(DATA_WIDTH>>3)-1:0]       byte_en_r               ;
    logic                             sign_bit_r              ;
    logic [DATA_WIDTH-1    :0] 		  rd_addr_r               ;
    
        
    assign data_mem_write_en	= stall_en ? 1'b0 : wr_en     ;
    assign data_mem_read_en		= rd_en	  ;	
    //assign data_mem_write_data  = 
 

    always_ff@(posedge mem_clk or negedge mem_rst)
    begin
        if(!mem_rst)
        begin
            ld_byte_en              <= {(DATA_WIDTH>>3){1'b0}};//{(DATA_WIDTH>>3){1'b0}}
            ld_sign_bit             <= 1'b0                   ;
    	    read_data_sel           <= 1'b0                   ;
            rd_addr_r               <= {DATA_WIDTH{1'b0}}     ; 
        end
        else
        begin
            ld_byte_en              <= byte_en_r              ;
            ld_sign_bit             <= sign_bit               ;
    	    read_data_sel           <= rd_en                  ;
            rd_addr_r               <= rd_addr                ;
        end
    end
    
    always_comb
    begin
    	unique case({ld_byte_en,sign_bit})
    		5'b11111://lw
    		begin
    			rd_data = {rd_data_r[31:0]};
    		end
    	    default:
    		begin
    		    rd_data = {DATA_WIDTH{1'b0}};
    		end
    endcase
    end    
        
endmodule



















