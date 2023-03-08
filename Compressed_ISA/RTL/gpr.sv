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
* File Name : gpr.sv

* Purpose :

* Creation Date : 16-02-2023

* Last Modified : Sat 18 Feb 2023 04:00:23 PM IST

* Created By :  

//////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

`timescale 1ns / 1ps
module reg_file #(parameter DATA_WIDTH     = 32,
                  parameter GPR_ADDR_WIDTH = 5
                  )
(
    input logic 			                    reg_clk		                ,
    input logic 			                    wr_data_en	                ,
    input logic  	      [GPR_ADDR_WIDTH-1:0]	rs1		                    ,
    input logic  	      [GPR_ADDR_WIDTH-1:0]	rs2		                    ,
    input logic  	      [GPR_ADDR_WIDTH-1:0]	rd		                    ,
    input logic  	      [DATA_WIDTH-1    :0]	wr_data		                ,
    //input logic                                 stall_pipeline              ,
    output logic          [DATA_WIDTH-1    :0]	rs1_data	                ,//delayed for alu
    output logic	      [DATA_WIDTH-1    :0] 	rs1_data_r	                ,
    output logic	      [DATA_WIDTH-1    :0]	rs2_data_r	                ,
    output logic          [DATA_WIDTH-1    :0]	rs2_data                     //delayed for alu
   
);


    logic [GPR_ADDR_WIDTH-1:0]   rd_addr1 	;
    logic [GPR_ADDR_WIDTH-1:0]   rd_addr2	;
    logic [GPR_ADDR_WIDTH-1:0]   wr_addr    ;

    assign rd_addr1 = rs1			; // source register-1 address
    assign rd_addr2 = rs2			; // source register-2 address 
    assign wr_addr	= rd			; // destination register address
    
    
    always_ff@(posedge reg_clk)
    begin
    /*
        if(stall_pipeline)
        begin
    	    rs1_data <= {(DATA_WIDTH){1'b0}};
    	    rs2_data <= {(DATA_WIDTH){1'b0}};
        end
        else
        begin
     */
    	    rs1_data <= rs1_data_r;
    	    rs2_data <= rs2_data_r;
       // end
    end
    
    dp_ram #(.DATA_WIDTH(DATA_WIDTH),
               .GPR_ADDR_WIDTH(GPR_ADDR_WIDTH))
    dp_ram_inst
    (
    .*,
    .ram_clk	                (reg_clk	            ),  
    .wr_en		                (wr_data_en		        ),
    .rd_addr1	                (rd_addr1	            ),
    .rd_addr2	                (rd_addr2	            ),
    .wr_addr	                (wr_addr	            ),
    .datain		                (wr_data	            ),
    .dataout1	                (rs1_data_r	            ),
    .dataout2	                (rs2_data_r	            )
    );

endmodule
    
    
module dp_ram #(
                 parameter DATA_WIDTH     = 32,
                 parameter GPR_ADDR_WIDTH = 5
                   )
    (
        input logic 			                    ram_clk		                ,
        input logic 			                    wr_en		                ,
        input logic 	    [GPR_ADDR_WIDTH-1:0] 	rd_addr1	                ,
        input logic 	    [GPR_ADDR_WIDTH-1:0] 	rd_addr2	                ,
        input logic 	    [GPR_ADDR_WIDTH-1:0]	wr_addr		                ,
        input logic 	    [DATA_WIDTH-1    :0] 	datain		                ,
        output logic        [DATA_WIDTH-1    :0] 	dataout1	                ,
        output logic        [DATA_WIDTH-1    :0] 	dataout2	                
    );

    
    logic [DATA_WIDTH-1:0] regfile [31:0] = '{default : 0};
    
    always_ff@(posedge ram_clk)
    begin
        if(wr_en)
    	begin
    		regfile[wr_addr] <= datain;
    	end
    end
    
    assign dataout1   = (rd_addr1) ? regfile[rd_addr1]:{DATA_WIDTH{1'b0}}; 
    assign dataout2   = (rd_addr2) ? regfile[rd_addr2]:{DATA_WIDTH{1'b0}}; 

endmodule
