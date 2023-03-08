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
* File Name : alu.sv

* Purpose :

* Creation Date : 14-02-2023

* Last Modified : Fri 03 Mar 2023 10:33:59 PM IST

* Created By :  

//////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

`timescale 1ns / 1ps
module alu #(parameter DATA_WIDTH = 32,
             parameter PC_WIDTH   = 20,
             parameter OPCODE     = 7
             )
(
    input logic 			                    alu_clk	 	        , 
    input logic 			                    alu_rst		        ,
    input logic 		[11:0]	                alu_ctrl	        ,//control
    input logic		    [DATA_WIDTH-1:0]        ld_sd_addr	        ,
    input logic 		[(DATA_WIDTH>>3)-1:0]	id_ex_byte_en	    ,//byte selection for load / store:pipeline
    input logic 			                    id_ex_sign_bit	    ,
    input logic                                 stall_pipeline      ,
    output logic  		                        ex_mem_sign_bit	    ,
    input logic 		[DATA_WIDTH-1:0]        imm_val		        ,//immediate value
    input logic 		[DATA_WIDTH-1:0]	    data_in_1	        ,//data from source register 1
    input logic 		[DATA_WIDTH-1:0]	    data_in_2	        ,//data from source  register 2
    //input logic 		[PC_WIDTH-1:0]          pc		            ,//program counter value for auipc instruction
    input logic 		[OPCODE-1:0]            opcode_r	        ,
    output logic  	    [DATA_WIDTH-1:0]	    data_out	        ,//output logic data  from alu
    output logic        [DATA_WIDTH-1:0]        data_out_1          ,//to addr_gen
    //output logic 	    [DATA_WIDTH-1:0]	    data_out_1_o	    ,
    output logic 	    [DATA_WIDTH-1:0]        mem_addr	        ,//pipelined load store adress
    output logic 	    [(DATA_WIDTH>>3)-1:0]   ex_mem_byte_en      ,//byte selection signal:pipelined
    output logic 		                        carry		        ,
    input logic 			                    branch_en	        ,    
    output logic 		                        zero		        
    );

    logic 		[11:0]	            alu_ctrl_r	    ;
    logic       [11:0]              alu_ctrl_r1     ;
    logic  			                oper1_sign	    ;
    logic  			                oper2_sign	    ;
    logic 	    [DATA_WIDTH-1:0]	data_out_1_o	;    
    logic  			                carry_o		    ;
    logic  			                zero_o		    ;
    logic  		[DATA_WIDTH-1:0]    oper1		    ;
    logic  		[DATA_WIDTH-1:0]    oper2		    ;
    logic 		[PC_WIDTH-1:0]      pc_w		    ;
    //logic  		[PC_WIDTH-1:0]      pc_r		    ;
   // logic 		[PC_WIDTH-1:0]      jal_pc		    ;
    logic  		[PC_WIDTH-1:0]      jal_pc_r	    ;
    logic 			                lui_en		    ;
    logic                           add_en          ;
    logic                           sub_en          ;
    logic                           sll_en          ;
    logic                           xor_en          ;
    logic                           srl_en          ;
    logic                           sra_en          ;
    logic                           or_en           ;
    logic                           and_en          ;
    logic                           jal_en          ;
    logic                           jalr_en         ;
    logic       [DATA_WIDTH-1:0]    lui_op          ;
    logic       [DATA_WIDTH-1:0]    jalr_op         ;
    logic       [DATA_WIDTH-1:0]    jal_op          ;
    logic       [DATA_WIDTH-1:0]    sum		        ;
    logic                           carry_out	    ;
    logic                           add_zero	    ;
    logic       [DATA_WIDTH-1:0]    diff		    ;
    logic                           borrow_out      ;
    logic                           sub_zero	    ;
    logic       [DATA_WIDTH-1:0]    sll_op	        ;
    logic                           sll_zero        ;
    logic       [DATA_WIDTH-1:0]    xor_op	        ;
    logic                           xor_zero        ;
    logic       [DATA_WIDTH-1:0]    srl_op	        ;
    logic                           srl_zero        ;
    logic       [DATA_WIDTH-1:0]    sra_op	        ;
    logic                           sra_zero        ;
    logic       [DATA_WIDTH-1:0]    or_op	        ;
    logic                           or_zero         ;
    logic       [DATA_WIDTH-1:0]    and_op	        ;
    logic                           and_zero        ;
    logic       [DATA_WIDTH-1:0]    mvi_op          ;
    logic                           mv_zero         ;
    logic                           nop_en          ;
    logic                           nop_zero        ;    
    logic       [DATA_WIDTH-1:0]    nop_op          ;




    //assign     jal_pc       = pc - 20'd2					 ;
    //assign 	 pc_w 	    =  nop_en ?  (pc + 20'd2) : 20'd0	;
    //assign     alu_ctrl_r 	= alu_ctrl ;
    assign     data_out_1   = (stall_pipeline) ? 32'd0 : data_out_1_o ;

    always_ff@(posedge alu_clk or negedge alu_rst)
    begin
    		if(!alu_rst)
    		begin
    			alu_ctrl_r1 	<= 	12'd0	            ;
    			mem_addr    	<= 	{DATA_WIDTH{1'b0}}	;
    			ex_mem_byte_en 	<= 	{DATA_WIDTH>>3{1'b0}}	;
    			ex_mem_sign_bit <= 	1'b0	            ;
    			//pc_r 		    <= 	{PC_WIDTH{1'b0}}	;
            	//jal_pc_r 	    <= 	{PC_WIDTH{1'b0}}	;
    		end
    		else
    		begin
    			alu_ctrl_r1 	<= alu_ctrl	     ;
    			//mem_addr    	<= ld_sd_addr	 ; //pipelining the load and store address in execution phase
    			//ex_mem_byte_en 	<= id_ex_byte_en ;
    			//ex_mem_sign_bit <= id_ex_sign_bit;                
    			//pc_r 		    <= pc_w          ;
                //jal_pc_r 	    <= jal_pc	     ;
    		end
    end

    assign lui_en	= ((alu_ctrl_r1 == 12'b0000000_011_01) || (alu_ctrl_r1 == 12'b0000000_010_01))? 1'b1:1'b0;
    assign add_en   = ((alu_ctrl_r1 == 12'b010000_1001_10) || (alu_ctrl_r1 == 12'b000000_1_000_01)  || (alu_ctrl_r1 == 12'b00_00010_011_01)|| (alu_ctrl_r1 == 12'b0000001_000_00))? 1'b1 : 1'b0;
    assign sub_en   = ((alu_ctrl_r1 == 12'b100_11_00_100_01))? 1'b1:1'b0;
    assign sll_en   = ((alu_ctrl_r1 == 12'b0000000_000_10)) ? 1'b1:1'b0;
    assign xor_en   = ((alu_ctrl_r1 == 12'b000_11_01_100_01)) ? 1'b1:1'b0;
    assign srl_en   = ((alu_ctrl_r1 == 12'b00000_00_100_01)) ? 1'b1:1'b0;
    assign sra_en   = ((alu_ctrl_r1 == 12'b00000_01_100_01)) ? 1'b1:1'b0;
    assign or_en    = ((alu_ctrl_r1 == 12'b000_11_10_100_01)) ? 1'b1:1'b0;
    assign and_en   = ((alu_ctrl_r1 == 12'b000_11_11_100_01) || (alu_ctrl_r1 == 12'b00000_10_100_01)) ? 1'b1:1'b0;
    assign jal_en   = ((alu_ctrl_r1 == 12'b0000000_001_01)) ? 1'b1:1'b0;
    assign jalr_en  = ((alu_ctrl_r1 == 12'b100000_1001_10)) ? 1'b1:1'b0;
    assign jr_en    = ((alu_ctrl_r1 == 12'b0_00000_0_100_10)) ? 1'b1:1'b0;
    assign j_en     = ((alu_ctrl_r1 == 12'b0000000_101_01)) ? 1'b1:1'b0;
    assign mvi_en   = ((alu_ctrl_r1 == 12'b1_00000_0_100_10)) ? 1'b1:1'b0;
    assign nop_en   = ((alu_ctrl_r1 == 12'b0000_0_00000_01)) ? 1'b1 : 1'b0 ;


    always_comb 
    begin
        unique case (alu_ctrl_r1)
            12'b0000001_000_00://addi4spn
            begin
                oper2       = imm_val           ;
    			oper1       = data_in_1         ;
    			oper1_sign  = 1'b0              ; 
                oper2_sign  = 1'b0              ;
            end
            12'b000000_1_000_01://addi            
            begin
                oper2       = imm_val           ;
    			oper1       = data_in_1         ;
    			oper1_sign  = 1'b0              ;
                oper2_sign  = 1'b0              ;  
            end
            /*
            12'b0000000_101_01://j
            begin
                oper2       = imm_val           ;
    			oper1       = {12'd0,pc_r}	    ;
                oper1_sign  = 1'b0              ;
                oper2_sign  = 1'b0              ;                  
            end
            12'b0000000_001_01://jal
            begin
                oper2       = {DATA_WIDTH{1'b0}};
    			oper1       = {{DATA_WIDTH-20{1'b0}},jal_pc_r}	;
                oper1_sign  = 1'b0              ;
                oper2_sign  = 1'b0              ;    
            end
            */
            12'b0000000_010_01://li
            begin
                oper2       = imm_val           ;
    			oper1       = {DATA_WIDTH{1'b0}};
    			oper1_sign  = 1'b0              ;
                oper2_sign  = 1'b0              ;                    
            end
            12'b0000000_011_01://lui
            begin
                oper2       = imm_val           ;
    			oper1       = {DATA_WIDTH{1'b0}};
    			oper1_sign  = 1'b0              ;
                oper2_sign  = 1'b0              ;                  
            end
            12'b00_00010_011_01://addi16sp
            begin
                oper2       = imm_val           ;
    			oper1       = data_in_1         ;
    			oper1_sign  = 1'b0              ;
                oper2_sign  = 1'b0              ;                   
            end
            12'b00000_00_100_01://srli
            begin
                oper2       = imm_val           ;
    			oper1       = data_in_1         ;
    			oper1_sign  = 1'b0              ;
                oper2_sign  = 1'b0              ;                   
            end
            12'b00000_01_100_01://srai
            begin
                oper2       = imm_val           ;
    			oper1       = data_in_1         ;
    			oper1_sign  = 1'b0              ;
                oper2_sign  = 1'b0              ;                  
            end
            12'b00000_10_100_01://andi
            begin
                oper2       = imm_val           ;
    			oper1       = data_in_1         ;
    			oper1_sign  = 1'b0              ;
                oper2_sign  = 1'b0              ;  
            end
            12'b000_11_11_100_01://and
            begin
                oper2       = data_in_2         ;
    			oper1       = data_in_1         ;
    			oper1_sign  = 1'b0              ;
                oper2_sign  = 1'b0              ;  
            end
            12'b000_11_10_100_01://or
            begin
                oper2       = data_in_2         ;
    			oper1       = data_in_1        ;
    			oper1_sign  = 1'b0              ;
                oper2_sign  = 1'b0              ;  
            end
            12'b000_11_01_100_01://xor
            begin
                oper2       = data_in_2         ;
    			oper1       = data_in_1        ;
    			oper1_sign  = 1'b0              ;
                oper2_sign  = 1'b0              ;  
            end
            12'b100_11_00_100_01://sub
            begin
    			oper2       = data_in_2         ;
    			oper1       = data_in_1         ;
    			oper1_sign  = 1'b0              ;
                oper2_sign  = 1'b0              ;                   
                
            end
            /*
            12'b0_00000_0_100_10://jr
            begin
                oper2       = {DATA_WIDTH{1'b0}};
    			oper1       = {{DATA_WIDTH-20{1'b0}},jal_pc_r}	;
    			oper1_sign  = 1'b0              ;
                oper2_sign  = 1'b0              ;                   
            end
            12'b100000_1001_10://jalr
            begin
                oper2       = {DATA_WIDTH{1'b0}};
    			oper1       = {{DATA_WIDTH-20{1'b0}},jal_pc_r}	;
    			oper1_sign  = 1'b0              ;
                oper2_sign  = 1'b0              ;                
            end
            */
            12'b0000000_000_10://slli
            begin
    			oper2       = imm_val           ;
    			oper1       = data_in_1        ;
    			oper1_sign  = 1'b0              ;
                oper2_sign  = 1'b0              ;
            end
            12'b1_00000_0_100_10://mv
            begin
    			oper2       = data_in_2         ;
    			oper1       = {DATA_WIDTH{1'b0}};
    			oper1_sign  = 1'b0              ;
                oper2_sign  = 1'b0              ;                
            end
            12'b010000_1001_10://add
            begin
    			oper2       = data_in_2         ;
    			oper1       = data_in_1         ;
    			oper1_sign  = 1'b0              ;
                oper2_sign  = 1'b0              ;
            end
            12'b0000_0_00000_01://nop
            begin
    			oper2       = imm_val           ;
    			oper1       = {DATA_WIDTH{1'b0}};
    			oper1_sign  = 1'b0              ;
                oper2_sign  = 1'b0              ;
            end
            default:
            begin
    			oper2       = {DATA_WIDTH{1'b0}};
    			oper1       = {DATA_WIDTH{1'b0}};
    			oper1_sign  = 1'b0              ;
                oper2_sign  = 1'b0              ;
            end
        endcase 
    end

    lui #(.DATA_WIDTH(DATA_WIDTH))
    lui_inst
    
    (
    
    .*,
    .oper1		(oper1		),
    .oper2		(oper2		),
    .lui_out	(lui_op		),
    .en		    (lui_en     )
    );

    /*
    jalr #(.DATA_WIDTH(DATA_WIDTH)) 
    jalr_inst
    (
    .*,
    .oper1		(oper1		),
    .oper2		(oper2		),
    .jalr_out	(jalr_op	),
    .en		    (jalr_en    )
    
    );
    jal #(.DATA_WIDTH(DATA_WIDTH)) 
    jal_inst
    (
    .*,
    .oper1		(oper1		),
    .oper2		(oper2		),
    .jal_out	(jal_op		),
    .en		    (jal_en     )
    );
    */
    add #(.DATA_WIDTH(DATA_WIDTH))
    add_inst
    (
    
    .*,
    .oper1		(oper1		),
    .oper2		(oper2		),
    .rslt		(sum		),
    .carry		(carry_out	),
    .zero		(add_zero	),
    .en		    (add_en     )
    );
    
    sub #(.DATA_WIDTH(DATA_WIDTH)) 
    sub_inst
    (
    .*,
    .oper1		(oper1		),
    .oper2		(oper2		),
    .rslt		(diff		),
    .borrow		(borrow_out ),
    .zero		(sub_zero	),
    .en		    (sub_en     )
    
    );
    
    sll #(.DATA_WIDTH(DATA_WIDTH)) 
    sll_inst
    (
    .*,
    .oper1		(oper1		),
    .oper2		(oper2		),
    .rslt		(sll_op		),
    .zero		(sll_zero	),
    .en		    (sll_en     )
    
    );
    
    xorg #(.DATA_WIDTH(DATA_WIDTH)) 
    xor_inst
    (
    .*,
    .oper1		(oper1		),
    .oper2		(oper2		),
    .rslt		(xor_op		),
    .zero		(xor_zero	),
    .en		    (xor_en     )
    
    );
    
    srl #(.DATA_WIDTH(DATA_WIDTH)) 
    srl_inst
    (
    
    .*,
    .oper1		(oper1		),
    .oper2		(oper2		),
    .rslt		(srl_op		),
    .zero		(srl_zero	),
    .en		    (srl_en	    )
    
    );
    
    sra #(.DATA_WIDTH(DATA_WIDTH))
    sra_inst
    (
    .*,
    .oper1		(oper1		),
    .oper2		(oper2		),
    .rslt		(sra_op		),
    .zero		(sra_zero	),
    .en		    (sra_en     )
    
    );
    
    org #(.DATA_WIDTH(DATA_WIDTH)) 
    or_inst
    (
    .*,
    .oper1		(oper1		),
    .oper2		(oper2		),
    .rslt		(or_op		),
    .zero		(or_zero	),
    .en		    (or_en      )
    
    );
    
    andg #(.DATA_WIDTH(DATA_WIDTH)) 
    and_inst
    (
    .*,
    .oper1		(oper1		),
    .oper2		(oper2		),
    .rslt		(and_op		),
    .zero		(and_zero	),
    .en		    (and_en	    )
    
    );

    mvi #(.DATA_WIDTH(DATA_WIDTH))
    mvi_inst
    (
    .*,
    
    .oper1		(oper1		),
    .oper2		(oper2		),
    .en         (mvi_en     ),
    .zero       (mv_zero    ),
    .result     (mvi_op     )
    );

    nop #(.DATA_WIDTH(DATA_WIDTH))
    nop_inst
    (
    .*,
    .oper1		(oper1		),
    .oper2		(oper2		),
    .nop_out	(nop_op	    ),
    .zero       (nop_zero   ),
    .en		    (nop_en	    )
    );


    always_ff@(posedge alu_clk or negedge alu_rst)
    begin
    	if(!alu_rst)
    	begin
    		data_out    <= {DATA_WIDTH{1'b0}};
    		zero        <= 1'b0              ;
    		carry       <= 1'b0              ;
    	end
    	else
    	begin
        /*
            if(stall_pipeline)
            begin
                data_out <= {DATA_WIDTH{1'b0}};
                carry    <= 1'b0              ;
                zero     <= 1'b0              ;
            end
            else
            begin */
            data_out  <= data_out_1     ;
    	    carry     <= carry_o        ;
    		zero      <= zero_o         ;
            //end
        end
    end

    always_comb 
    begin
        unique case (alu_ctrl_r1)
            12'b0000001_000_00://addi4spn
            begin
    			data_out_1_o = sum		    ;
    			zero_o       = add_zero     ;
    			carry_o      = carry_out	;
            end
            12'b000000_1_000_01://addi            
            begin
    			data_out_1_o = sum		    ;
    			zero_o       = add_zero 	;
    			carry_o      = carry_out    ;
            end
            /*
            12'b0000000_001_01://jal
            begin
    			data_out_1_o = jal_op;
    			carry_o    = 1'b0  ;
    			if(jal_op == {DATA_WIDTH{1'b0}})
    			begin
    		        zero_o = 1'b1;
    			end
    			else
    			begin
    			    zero_o = 1'b0;
    			end
 
            end
            */
            12'b0000000_010_01://li
            begin
    			data_out_1_o = lui_op;
    			carry_o      = 1'b0  ;
                if(lui_op == {DATA_WIDTH{1'b0}})
                begin
    			    zero_o 	 = 1'b1	 ;
                end
                else
                begin
                    zero_o = 1'b0;
                end   
            end
            12'b0000000_011_01://lui
            begin
    			data_out_1_o = lui_op;
    			carry_o      = 1'b0  ;
                if(lui_op == {DATA_WIDTH{1'b0}})
                begin
    			    zero_o	 = 1'b1	 ;
                end
                else
                begin
                    zero_o = 1'b0;
                end       
            end
            12'b00_00010_011_01://addi16sp
            begin
    			data_out_1_o = sum		    ;
    			zero_o       = add_zero 	;
    			carry_o      = carry_out    ;
                  
            end
            12'b00000_00_100_01://srli
            begin
    			data_out_1_o    = srl_op    ;
    			zero_o          = srl_zero	;
    			carry_o         = 1'b0	    ;
                  
            end
            12'b00000_01_100_01://srai
            begin
    			data_out_1_o= sra_op		;
    			zero_o      = sra_zero	;
    			carry_o     = 1'b0     ;
                 
            end
            12'b00000_10_100_01://andi
            begin
    			data_out_1_o= and_op	;
    			zero_o      = and_zero	;
    			carry_o     = 1'b0	    ;
 
            end
            12'b000_11_11_100_01://and
            begin
    			data_out_1_o= and_op	;
    			zero_o      = and_zero	;
    			carry_o     = 1'b0	    ;
            end
            12'b000_11_10_100_01://or
            begin
    			data_out_1_o= or_op      ;
    			zero_o      = or_zero    ;
    			carry_o     = 1'b0       ;
 
            end
            12'b000_11_01_100_01://xor
            begin
    			data_out_1_o=  xor_op      ;
    			zero_o      =  xor_zero    ;
    			carry_o     =  1'b0       ;

            end
            12'b100_11_00_100_01://sub
            begin
    			data_out_1_o= diff       ;        		
    			zero_o      = sub_zero	 ;        
    			carry_o     = borrow_out ;                 
            end
            /*
            12'b0_00000_0_100_10://jr
            begin
    			data_out_1_o = jal_op;
    			carry_o    = 1'b0  ;
    			if(jal_op == {DATA_WIDTH{1'b0}})
    			begin
    		        zero_o = 1'b1;
    			end
    			else
    			begin
    			    zero_o = 1'b0;
    			end
                  
            end
            12'b100000_1001_10://jalr
            begin
    			data_out_1_o = jal_op;
    			carry_o    = 1'b0  ;
    			if(jal_op == {DATA_WIDTH{1'b0}})
    			begin
    		        zero_o = 1'b1;
    			end
    			else
    			begin
    			    zero_o = 1'b0;
    			end
              
            end
            */
            12'b0000000_000_10://slli
            begin
    			data_out_1_o = sll_op     ;
    			carry_o	   = 1'b0       ;
    			zero_o	   = sll_zero   ;           
            end
            12'b1_00000_0_100_10://mv
            begin
    			data_out_1_o 	= mvi_op;
    			carry_o	 	    = 1'b0;
    	        zero_o          = mv_zero;
            end
            12'b010000_1001_10://add
            begin
    			data_out_1_o    = sum		;
    			zero_o          = add_zero  ;
    			carry_o         = carry_out ;
            end
            12'b0000_0_00000_01://nop
            begin
    			data_out_1_o  = nop_op   ;
    			carry_o       = 1'b0     ;
                zero_o        = nop_zero ;
            end
            default:
            begin
    			data_out_1_o= {DATA_WIDTH{1'b0}};
    			zero_o      = 1'b0              ;
    			carry_o     = 1'b0              ;
            end
        endcase 
    end
endmodule



    /////////////////////////////
    //	addition 	           //
    /////////////////////////////
    module add #(parameter DATA_WIDTH = 32)
   
    (
    input logic		                    en	    ,
    input logic  [DATA_WIDTH-1:0] 	    oper1	,
    input logic  [DATA_WIDTH-1:0] 	    oper2	,
    output logic [DATA_WIDTH-1:0] 	    rslt	,
    output logic 	      	            carry	,
    output logic		                zero	
    );
    
    logic [DATA_WIDTH:0] sum;
    
    assign sum   = en ? (oper1 + oper2) : {DATA_WIDTH+1{1'b0}} ;
    assign rslt  = sum[DATA_WIDTH-1:0];
    assign carry = (sum[DATA_WIDTH] == 1'b1) ? 1'b1 : 1'b0;
    assign zero  = (rslt == {DATA_WIDTH{1'b0}}) ? 1'b1 : 1'b0;
    
    endmodule
    
    ////////////////////////////// 
    //	substraction	    //
    //////////////////////////////
    module sub #(parameter DATA_WIDTH = 32)
    (
    input logic 		                en	    ,
    input logic  [DATA_WIDTH-1:0] 	    oper1	,
    input logic  [DATA_WIDTH-1:0] 	    oper2	,
    output logic [DATA_WIDTH-1:0] 	    rslt	,
    output logic 		                borrow	,
    output logic 		                zero	
    
    
    );
    logic [DATA_WIDTH:0]diff;
    
    assign diff   = en ? (oper1 - oper2) : {DATA_WIDTH{1'b0}} ;
    assign rslt   = diff[DATA_WIDTH-1:0];
    assign borrow = diff[DATA_WIDTH];
    assign zero   = (diff == {DATA_WIDTH{1'b0}}) ? 1'b1 : 1'b0;
    
    endmodule
    
    ////////////////////////////// 
    //   logical left shift	    //
    //////////////////////////////
    module sll #(parameter DATA_WIDTH = 32)
    (
    input logic [DATA_WIDTH-1:0] 		oper1	,
    input logic [DATA_WIDTH-1:0] 		oper2	,
    output logic [DATA_WIDTH-1:0] 	    rslt	,
    output logic 			            zero    ,	
    input logic 		                en	    
    
    );
    
    assign rslt = en ? (oper1 << oper2) : {DATA_WIDTH{1'b0}} ;
    assign zero = (rslt == {DATA_WIDTH{1'b0}}) ? 1'b1 : 1'b0;
    
    endmodule
    
    ////////////////////////////// 
    //   logical XOR	    //
    //////////////////////////////
    module xorg #(parameter DATA_WIDTH = 32)
    (
    input logic [DATA_WIDTH-1:0] 		oper1	,
    input logic [DATA_WIDTH-1:0] 		oper2	,
    output logic [DATA_WIDTH-1:0] 	    rslt	,
    output logic 			            zero	,
    input logic			                en
    
    
    );
    assign rslt = en ? (oper1 ^ oper2) : {DATA_WIDTH{1'b0}} ;
    assign zero = (rslt == {DATA_WIDTH{1'b0}}) ? 1'b1 : 1'b0;
    
    
    endmodule
    
    
    ////////////////////////////// 
    //   logical right shift    //
    //////////////////////////////
    
    module srl #(parameter DATA_WIDTH = 32)
    (
    
    input logic [DATA_WIDTH-1:0] 		oper1	,
    input logic [DATA_WIDTH-1:0] 		oper2	,
    output logic [DATA_WIDTH-1:0] 	    rslt	,
    output logic 			            zero    ,
    input logic			                en
    
    
    );
    assign rslt = en ? (oper1 >> oper2) : {DATA_WIDTH{1'b0}}  ; 
    assign zero = (rslt == {DATA_WIDTH{1'b0}}) ? 1'b1 : 1'b0;
    
    
    endmodule
    
    
    ////////////////////////////////// 
    //  arithmetic right shift double word	//
    //////////////////////////////////
    module sra #(parameter DATA_WIDTH = 32)
    (
    input logic 		[DATA_WIDTH-1:0] 		oper1	,
    input logic 		[DATA_WIDTH-1:0] 		oper2	,
    output logic 		[DATA_WIDTH-1:0] 		rslt	,
    output logic 				                zero    ,
    input logic				                    en          
    );
    logic [DATA_WIDTH-1:0] result;

    always_comb
    begin
    if(en)
    begin
    unique case(oper2[4:0])
     5'b000000:result = oper1;
     5'b000001:result = {{ 2{oper1[DATA_WIDTH-1]}} ,oper1[DATA_WIDTH-2:1 ] };
     5'b000010:result = {{ 3{oper1[DATA_WIDTH-1]}} ,oper1[DATA_WIDTH-2:2 ] };
     5'b000011:result = {{ 4{oper1[DATA_WIDTH-1]}} ,oper1[DATA_WIDTH-2:3 ] };
     5'b000100:result = {{ 5{oper1[DATA_WIDTH-1]}} ,oper1[DATA_WIDTH-2:4 ] };
     5'b000101:result = {{ 6{oper1[DATA_WIDTH-1]}} ,oper1[DATA_WIDTH-2:5 ] };
     5'b000110:result = {{ 7{oper1[DATA_WIDTH-1]}} ,oper1[DATA_WIDTH-2:6 ] };
     5'b000111:result = {{ 8{oper1[DATA_WIDTH-1]}} ,oper1[DATA_WIDTH-2:7 ] };
     5'b001000:result = {{ 9{oper1[DATA_WIDTH-1]}} ,oper1[DATA_WIDTH-2:8 ] };
     5'b001001:result = {{10{oper1[DATA_WIDTH-1]}} ,oper1[DATA_WIDTH-2:9 ] };
     5'b001010:result = {{11{oper1[DATA_WIDTH-1]}} ,oper1[DATA_WIDTH-2:10] };
     5'b001011:result = {{12{oper1[DATA_WIDTH-1]}} ,oper1[DATA_WIDTH-2:11] };
     5'b001100:result = {{13{oper1[DATA_WIDTH-1]}} ,oper1[DATA_WIDTH-2:12] };
     5'b001101:result = {{14{oper1[DATA_WIDTH-1]}} ,oper1[DATA_WIDTH-2:13] };
     5'b001110:result = {{15{oper1[DATA_WIDTH-1]}} ,oper1[DATA_WIDTH-2:14] };
     5'b001111:result = {{16{oper1[DATA_WIDTH-1]}} ,oper1[DATA_WIDTH-2:15] };
     5'b010000:result = {{17{oper1[DATA_WIDTH-1]}} ,oper1[DATA_WIDTH-2:16] };
     5'b010001:result = {{18{oper1[DATA_WIDTH-1]}} ,oper1[DATA_WIDTH-2:17] };
     5'b010010:result = {{19{oper1[DATA_WIDTH-1]}} ,oper1[DATA_WIDTH-2:18] };
     5'b010011:result = {{20{oper1[DATA_WIDTH-1]}} ,oper1[DATA_WIDTH-2:19] };
     5'b010100:result = {{21{oper1[DATA_WIDTH-1]}} ,oper1[DATA_WIDTH-2:20] };
     5'b010101:result = {{22{oper1[DATA_WIDTH-1]}} ,oper1[DATA_WIDTH-2:21] };
     5'b010110:result = {{23{oper1[DATA_WIDTH-1]}} ,oper1[DATA_WIDTH-2:22] };
     5'b010111:result = {{24{oper1[DATA_WIDTH-1]}} ,oper1[DATA_WIDTH-2:23] };
     5'b011000:result = {{25{oper1[DATA_WIDTH-1]}} ,oper1[DATA_WIDTH-2:24] };
     5'b011001:result = {{26{oper1[DATA_WIDTH-1]}} ,oper1[DATA_WIDTH-2:25] };
     5'b011010:result = {{27{oper1[DATA_WIDTH-1]}} ,oper1[DATA_WIDTH-2:26] };
     5'b011011:result = {{28{oper1[DATA_WIDTH-1]}} ,oper1[DATA_WIDTH-2:27] };
     5'b011100:result = {{29{oper1[DATA_WIDTH-1]}} ,oper1[DATA_WIDTH-2:28] };
     5'b011101:result = {{30{oper1[DATA_WIDTH-1]}} ,oper1[DATA_WIDTH-2:29] };
     5'b011110:result = {{31{oper1[DATA_WIDTH-1]}} ,oper1[30] };
     5'b011111:result = {{32{oper1[DATA_WIDTH-1]}} };
    default:
    begin
        result = {DATA_WIDTH{1'b0}};
        zero   = 1'b0; 
    end
    endcase
    end
    else
    begin
        result = {DATA_WIDTH{1'b0}};
        zero   = 1'b0;
    end
    end
    	assign rslt = result ;
    endmodule
    /////////////////////////////////////////////////////////////////////
    
    //////////////////////////////
    //   logical OR	    	    //
    //////////////////////////////
    module org #(parameter DATA_WIDTH = 32)
    (
    input logic [DATA_WIDTH-1:0] 		oper1	,
    input logic [DATA_WIDTH-1:0] 		oper2	,
    output logic [DATA_WIDTH-1:0] 	rslt	,
    output logic 			            zero    ,
    input logic			            en      
    
    
    );
    assign rslt = en ? (oper1 | oper2) : {DATA_WIDTH{1'b0}} ;
    assign zero = (rslt == {DATA_WIDTH{1'b0}}) ? 1'b1 : 1'b0;
    
    
    endmodule
    
    ////////////////////////////// 
    //   logical 	AND	    //
    //////////////////////////////
    module andg #(parameter DATA_WIDTH = 32)
    (
    input logic [DATA_WIDTH-1:0] 		oper1	,
    input logic [DATA_WIDTH-1:0] 		oper2	,
    output logic [DATA_WIDTH-1:0] 	rslt	,
    output logic 			            zero    ,
    input logic			            en      
    
    );
    
    assign rslt = en ? (oper1 & oper2) : {DATA_WIDTH{1'b0}} ;
    assign zero = (rslt == {DATA_WIDTH{1'b0}}) ? 1'b1 : 1'b0;
    endmodule
    
    //////////////////////////////////////////////////////////////////////////////////
    module lui #(parameter DATA_WIDTH = 32)
    
    (
    input logic  [DATA_WIDTH-1:0]     oper1   ,
    input logic  [DATA_WIDTH-1:0]     oper2   ,
    output logic [DATA_WIDTH-1:0]     lui_out ,
    input logic			            en
    );
    
    assign lui_out = en ? oper2 : {DATA_WIDTH{1'b0}};
    endmodule
    
    /////////////////////////////////////////////////////////////////////////////////
    module jal #(parameter DATA_WIDTH = 32)
    (
    input logic [DATA_WIDTH-1:0]      oper1   ,
    input logic [DATA_WIDTH-1:0]      oper2   ,
    output logic [DATA_WIDTH-1:0]     jal_out ,
    input logic			            en      
    
    );
    
    assign jal_out = en ? oper1 : {DATA_WIDTH{1'b0}} ;//pc
    
    
    endmodule
    
    //////////////////////////////////////////////////////////////////////////////////////////
    module jalr #(parameter DATA_WIDTH = 32)
    
    (
    input logic  [DATA_WIDTH-1:0] oper1       ,
    input logic  [DATA_WIDTH-1:0] oper2       ,
    output logic [DATA_WIDTH-1:0] jalr_out    ,
    input logic			          en
    
    );
    
    assign jalr_out = en ? oper1 : {DATA_WIDTH{1'b0}} ;//pc
  
    
    endmodule
////////////////////////////////////////////////////////////////////
//////////////////                                   ///////////////
//////////////////           Move                    ///////////////
////////////////////////////////////////////////////////////////////
module mvi #(parameter DATA_WIDTH = 32)
    
    (
    	input logic [DATA_WIDTH-1:0] 	    oper1	,
    	input logic [DATA_WIDTH-1:0] 	    oper2	,
    	input logic 		                en	    ,
        output logic 			            zero    ,    
        
    	output logic [DATA_WIDTH-1:0] 	    result 
    );
    
    assign result = (en)? oper2 : {DATA_WIDTH{1'b0}};
    assign zero = 1'b0 ;
    

endmodule

////////////////////////////////////////////////////////////////////
//////////////////                                   ///////////////
//////////////////           NOP                    ///////////////
////////////////////////////////////////////////////////////////////
module nop #(parameter DATA_WIDTH = 0)
    (
    input  logic [DATA_WIDTH-1:0]  oper1        ,
    input  logic [DATA_WIDTH-1:0]  oper2        ,
    output logic [DATA_WIDTH-1:0] nop_out       ,
    output logic 			      zero          ,    
    input  logic			      en          
    );
    
    assign nop_out = (en)? (oper1 + oper2) : {DATA_WIDTH{1'b0}};
    assign zero = 1'b0 ;
    
    
endmodule
