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
* File Name : compressed_inst.sv

* Purpose :

* Creation Date : 25-02-2023

* Last Modified : Mon 27 Feb 2023 08:14:27 PM IST

* Created By :  

//////////////////////////////////////////////////////////////////////////////////////////////////////////////// */
`timescale 1ns / 1ps
module instruction_decoder #(                        
                        parameter DATA_WIDTH        = 32 ,
                        parameter INSTRUCTION_WIDTH = 16 ,
                        parameter OPCODE            = 2  ,
                        parameter FUNC3             = 3  ,
                        parameter FUNC4             = 4  ,
                        parameter FUNC2             = 2  ,
                        parameter FUNC6             = 6  ,
                        parameter GPR_ADDR_WIDTH    = 5  
                        )
(
    input   logic 				                    de_clk				        ,
    input   logic				                    de_rst				        ,
    input   logic	   	[INSTRUCTION_WIDTH-1:0]	    instruction_r			    ,
    input   logic	   		     	                stall_pipeline			    ,
    input   logic                                   stall_en                    ,
    output  logic	    [OPCODE-1:0]	            opcode				        ,
    output  logic  		[11:0]	                    alu_ctrl_r			        ,
    output  logic  		[DATA_WIDTH-1:0]	        imm_val				        ,
    output  logic  		[DATA_WIDTH-1:0]	        imm_r				        ,
    output  logic 	   	[GPR_ADDR_WIDTH-1:0]	    rs1				            ,
    output  logic 	   	[GPR_ADDR_WIDTH-1:0]	    rs2				            ,
    output  logic 	   	[GPR_ADDR_WIDTH-1:0]	    rd				            ,
    output  logic   		                        reg_wr_en_r			    ,
    output  logic  			                        mem_rd_en_r			        ,
    output  logic  			                        mem_wr_en_r			        ,
    output  logic 			                        mem_to_reg_en_r 		    ,
    output  logic 		[OPCODE-1:0]                opcode_r			        ,
    output  logic  			                        e_call_valid_o  		    ,//e-call exception
    output  logic  			                        e_break_valid_o 		    ,//e-break exception
    output  logic  			                        ret_func_valid		        ,
    output  logic   		                        invalid_instruction_valid_o	,//invalid instruction exception
    output  logic                                   ebreak_valid_o              
);

    logic [DATA_WIDTH-1:0]            imm_r1	              ;
    logic [INSTRUCTION_WIDTH-1:0]     instruction             ;
    logic [FUNC2-1:0]                 func2                   ;
    logic [FUNC3-1:0]                 func3                   ;
    logic [FUNC4-1:0]                 func4                   ;
    logic [FUNC6-1:0]                 func6                   ;
    logic [GPR_ADDR_WIDTH-1:0]        source_reg1	          ;
    logic [GPR_ADDR_WIDTH-1:0]        source_reg2             ;
    logic [GPR_ADDR_WIDTH-1:0]        dest_reg	              ;
    logic                             invalid_instruction_w   ;
    logic [11:0]                      alu_ctrl	              ;
    logic 	                          reg_wr_en	              ;
    logic	                          mem_rd_en	              ;
    logic	                          mem_wr_en	              ;
    logic 	                          mem_to_reg_en           ;

    assign instruction  =  instruction_r ;

    assign opcode 		= instruction[1:0]  ;
    assign func3  		= instruction[15:13];
    assign source_reg1 	= (((instruction[1:0] == 2'b00) || (instruction[1:0] == 2'b01)) && ((instruction[15:13] == 3'b010) || (instruction[15:13] == 3'b110) || (instruction[15:13] == 3'b101) || (instruction[15:13] == 3'b111) || (instruction[15:13] == 3'b100))) ? {2'd0,instruction[9:7]} : instruction[11:7];
    assign source_reg2 = (instruction[1:0] == 2'b10) ? (instruction[6:2]) : {2'd0,instruction[4:2]}  ;
    assign dest_reg	   	= ((instruction[1:0] == 2'b00) && (instruction[15:13] == 3'b010 || instruction[15:13] == 3'b000)) ? instruction[4:2] : ((instruction[1:0] == 2'b01) && ((instruction[15:13] == 3'b111) || (instruction[15:13] == 3'b110) || (instruction[15:13] == 3'b101) || (instruction[15:13] == 3'b100))) ?  {2'd0,instruction[9:7]}: instruction[11:7];
    assign func4        = instruction[15:12];
    assign func2        = ((instruction[1:0] == 2'b01) && (instruction[15:10] == 6'b100011)) ? instruction[6:5]:instruction[11:10];
    assign func6        = ((instruction[15:10] == 6'b100011) && (instruction[1:0] == 2'b01) ) ? instruction[15:10] : 6'd0  ;

    always_ff@(posedge de_clk or negedge de_rst )
    begin
    	if(!de_rst )
    	begin
    		imm_val  	        <= {DATA_WIDTH{1'b0}}	;
    		imm_r1		        <= {DATA_WIDTH{1'b0}}	;
    		alu_ctrl 	        <=  12'd0	;
    		reg_wr_en	        <=  1'd0	;
    		mem_wr_en	        <=  1'd0	;
    		mem_rd_en	        <=  1'd0	;
    		mem_to_reg_en 	    <=  1'b0	;
    		opcode_r 	        <= {OPCODE{1'b0}};
            invalid_instruction_valid_o <= 1'b0;
    	end
    	else
    	begin
    		imm_r1	 	        <= imm_r	;
    		imm_val  	        <= imm_r	;
    		alu_ctrl 	        <= alu_ctrl_r	;
    		reg_wr_en	        <= reg_wr_en_r  ;
    		mem_wr_en	        <= mem_wr_en_r  ;
    		mem_rd_en	        <= mem_rd_en_r  ;
    		mem_to_reg_en       <= mem_to_reg_en_r;
    		opcode_r            <= opcode;
            invalid_instruction_valid_o <= invalid_instruction_w;
    	end
    end
    
    always_comb
    begin
           	rs1	  	            = {GPR_ADDR_WIDTH{1'b0}}    ;
			rs2	   	            = {GPR_ADDR_WIDTH{1'b0}}	;
			rd	   	            = {GPR_ADDR_WIDTH{1'b0}}    ;
		    imm_r	   	        = {DATA_WIDTH{1'b0}}	    ;
			alu_ctrl_r 	        = 12'b0			            ;
			reg_wr_en_r  	    = 1'b0						;
			mem_rd_en_r  	    = 1'b0						;
			mem_wr_en_r  	    = 1'b0						;
			mem_to_reg_en_r     = 1'b0						;
			e_call_valid_o  	= 1'b0				;	
			e_break_valid_o 	= 1'b0				;	
			invalid_instruction_w = 1'b0			;
		    ret_func_valid      = 1'b0              ;
            ebreak_valid_o      = 1'b0              ;

            unique case (opcode)
            2'b00: //lw, sw, addi4spn  
            begin
                case(func3)
                3'b010://lw
                begin
                     rs1	  	            = source_reg1 + 5'b01000    ;
		             rs2	   	            = {GPR_ADDR_WIDTH{1'b0}}	;
		             rd	   	                = dest_reg + 5'b01000       ;
		             imm_r	   	            = {{(DATA_WIDTH-8){1'b0}},instruction[5],instruction[12:10],instruction[6],2'b00} ;
		             alu_ctrl_r 	        = {7'd0,func3,opcode}	    ;//0000000_010_00
		             reg_wr_en_r  	        = 1'b1						;
		             mem_rd_en_r  	        = 1'b1						;
		             mem_wr_en_r  	        = 1'b0						;
		             mem_to_reg_en_r        = 1'b1						;
		             e_call_valid_o  	    = 1'b0				        ;	
		             e_break_valid_o 	    = 1'b0				        ;	
		             invalid_instruction_w  = 1'b0			            ;
		             ret_func_valid         = 1'b0                      ;
                     ebreak_valid_o         = 1'b0                      ;                   
                end
                3'b110://sw
                begin
                     rs1	  	            = source_reg1 + 5'b01000    ;
		             rs2	   	            = source_reg2 + 5'b01000    ;
                     rd	   	                = {GPR_ADDR_WIDTH{1'b0}}    ;
		             imm_r	   	            = {{(DATA_WIDTH-8){1'b0}},instruction[5],instruction[12:10],instruction[6],2'b00} ;
		             alu_ctrl_r 	        = {7'd0,func3,opcode}	    ; //0000000_110_00
		             reg_wr_en_r  	        = 1'b0						;
		             mem_rd_en_r  	        = 1'b0						;
		             mem_wr_en_r  	        = 1'b1						;
		             mem_to_reg_en_r        = 1'b0						;
		             e_call_valid_o  	    = 1'b0				        ;	
		             e_break_valid_o 	    = 1'b0				        ;	
		             invalid_instruction_w  = 1'b0			            ;
		             ret_func_valid         = 1'b0                      ;
                     ebreak_valid_o         = 1'b0                      ;                   
                end
                3'b000://addi4spn
                begin
                    if(instruction[12:5] != 8'd0)
                    begin
                     rs1	  	            = {{(GPR_ADDR_WIDTH-2){1'b0}},2'd2}	 ;
		             rs2	   	            = {GPR_ADDR_WIDTH{1'b0}}	;
		             rd	   	                = dest_reg + 5'b01000       ;
                     imm_r	   	            = {{(DATA_WIDTH-10){1'b0}},instruction[10:7],instruction[12:11],instruction[5],instruction[6],2'b00} ;
		             alu_ctrl_r 	        = {7'd1,func3,opcode}	    ;//0000001_000_00
		             reg_wr_en_r  	        = 1'b1						;
		             mem_rd_en_r  	        = 1'b0						;
		             mem_wr_en_r  	        = 1'b0						;
		             mem_to_reg_en_r        = 1'b0						;
		             e_call_valid_o  	    = 1'b0				        ;	
		             e_break_valid_o 	    = 1'b0				        ;	
		             invalid_instruction_w  = 1'b0			            ;
		             ret_func_valid         = 1'b0                      ;
                     ebreak_valid_o         = 1'b0                      ;
                    end
                    else
                    begin
                     rs1	  	            = {GPR_ADDR_WIDTH{1'b0}}    ;
		             rs2	   	            = {GPR_ADDR_WIDTH{1'b0}}	;
		             rd	   	                = {GPR_ADDR_WIDTH{1'b0}}    ;
		             imm_r	   	            = {DATA_WIDTH{1'b0}}	    ;
		             alu_ctrl_r 	        = 12'b0			            ;
		             reg_wr_en_r  	        = 1'b0						;
		             mem_rd_en_r  	        = 1'b0						;
		             mem_wr_en_r  	        = 1'b0						;
		             mem_to_reg_en_r        = 1'b0						;
		             e_call_valid_o  	    = 1'b0				        ;	
		             e_break_valid_o 	    = 1'b0				        ;	
		             invalid_instruction_w  = 1'b1			            ;
		             ret_func_valid         = 1'b0                      ;
                     ebreak_valid_o         = 1'b0                      ;
                    end
                end
                default:
                begin
                     rs1	  	            = {GPR_ADDR_WIDTH{1'b0}}    ;
		             rs2	   	            = {GPR_ADDR_WIDTH{1'b0}}	;
		             rd	   	                = {GPR_ADDR_WIDTH{1'b0}}    ;
		             imm_r	   	            = {DATA_WIDTH{1'b0}}	    ;
		             alu_ctrl_r 	        = 12'b0			            ;
		             reg_wr_en_r  	        = 1'b0						;
		             mem_rd_en_r  	        = 1'b0						;
		             mem_wr_en_r  	        = 1'b0						;
		             mem_to_reg_en_r        = 1'b0						;
		             e_call_valid_o  	    = 1'b0				        ;	
		             e_break_valid_o 	    = 1'b0				        ;	
		             invalid_instruction_w  = 1'b1			            ;
		             ret_func_valid         = 1'b0                      ;
                     ebreak_valid_o         = 1'b0                      ;                                       
                end
                endcase
            end

            2'b01: // j, jal, beqz, bnez, li, lui, addi, addi16sp, srli, srai, andi, and, or, xor, sub, nop
            begin
                if(func6 == 6'b100011)
                begin
                   case(func2)
                   2'b00://sub
                   begin
                        rs1	  	            = source_reg1 + 5'd8              ;
		                rs2	   	            = source_reg2 + 5'd8              ;
		                rd	   	                = dest_reg + 5'd8                 ;
		                imm_r	   	            = {DATA_WIDTH{1'b0}}	          ;
		                alu_ctrl_r 	        = {3'd4,instruction[11:10],instruction[6:5],func3,opcode}	;//100_11_00_100_01		                         
                        reg_wr_en_r  	        = 1'b1						;
		                mem_rd_en_r  	        = 1'b0						;
		                mem_wr_en_r  	        = 1'b0						;
		                mem_to_reg_en_r        = 1'b0						;
		                e_call_valid_o  	    = 1'b0				        ;	
		                e_break_valid_o 	    = 1'b0				        ;	
		                invalid_instruction_w  = 1'b0			            ;
		                ret_func_valid         = 1'b0                      ;
                        ebreak_valid_o         = 1'b0                      ;                                      
                   end

                   2'b01://xor
                   begin
                        rs1	  	            = source_reg1 + 5'd8              ;
		                rs2	   	            = source_reg2 + 5'd8              ;
		                rd	   	                = dest_reg + 5'd8                 ;
		                imm_r	   	            = {DATA_WIDTH{1'b0}}	          ;
		                alu_ctrl_r 	        = {3'd0,instruction[11:10],instruction[6:5],func3,opcode}	;//000_11_01_100_01				                        
                        reg_wr_en_r  	        = 1'b1						;
		                mem_rd_en_r  	        = 1'b0						;
		                mem_wr_en_r  	        = 1'b0						;
		                mem_to_reg_en_r        = 1'b0						;
		                e_call_valid_o  	    = 1'b0				        ;	
		                e_break_valid_o 	    = 1'b0				        ;	
		                invalid_instruction_w  = 1'b0			            ;
		                ret_func_valid         = 1'b0                      ;
                        ebreak_valid_o         = 1'b0                      ;  
                   end

                   2'b10://or
                   begin
                        rs1	  	            = source_reg1 + 5'd8              ;
		                rs2	   	            = source_reg2 + 5'd8              ;
		                rd	   	                = dest_reg + 5'd8                 ;
		                imm_r	   	            = {DATA_WIDTH{1'b0}}	    ;
		                alu_ctrl_r 	        = {3'd0,instruction[11:10],instruction[6:5],func3,opcode}	;//000_11_10_100_01
		                reg_wr_en_r  	        = 1'b1						;
		                mem_rd_en_r  	        = 1'b0						;
		                mem_wr_en_r  	        = 1'b0						;
		                mem_to_reg_en_r        = 1'b0						;
		                e_call_valid_o  	    = 1'b0				        ;	
		                e_break_valid_o 	    = 1'b0				        ;	
		                invalid_instruction_w  = 1'b0			            ;
		                ret_func_valid         = 1'b0                      ;
                        ebreak_valid_o         = 1'b0                      ;  
                   end

                   2'b11://and
                   begin
                        rs1	  	            = source_reg1 + 5'd8              ;
		                rs2	   	            = source_reg2 + 5'd8              ;
		                rd	   	                = dest_reg + 5'd8                 ;
		                imm_r	   	            = {DATA_WIDTH{1'b0}}	    ;
		                alu_ctrl_r 	        = {3'd0,instruction[11:10],instruction[6:5],func3,opcode}	;//000_11_11_100_01
		                reg_wr_en_r  	        = 1'b1						;
		                mem_rd_en_r  	        = 1'b0						;
		                mem_wr_en_r  	        = 1'b0						;
		                mem_to_reg_en_r        = 1'b0						;
		                e_call_valid_o  	    = 1'b0				        ;	
		                e_break_valid_o 	    = 1'b0				        ;	
		                invalid_instruction_w  = 1'b0			            ;
		                ret_func_valid         = 1'b0                      ;
                        ebreak_valid_o         = 1'b0                      ;  
                   end

                   default:
                   begin
                        rs1	  	            = {GPR_ADDR_WIDTH{1'b0}}    ;
		                rs2	   	            = {GPR_ADDR_WIDTH{1'b0}}	;
		                rd	   	                = {GPR_ADDR_WIDTH{1'b0}}    ;
		                imm_r	   	            = {DATA_WIDTH{1'b0}}	    ;
		                alu_ctrl_r 	        = 12'b0			            ;
		                reg_wr_en_r  	        = 1'b0						;
		                mem_rd_en_r  	        = 1'b0						;
		                mem_wr_en_r  	        = 1'b0						;
		                mem_to_reg_en_r        = 1'b0						;
		                e_call_valid_o  	    = 1'b0				        ;	
		                e_break_valid_o 	    = 1'b0				        ;	
		                invalid_instruction_w  = 1'b1			            ;
		                ret_func_valid         = 1'b0                      ;
                        ebreak_valid_o         = 1'b0                      ;                                      
                   end
                   endcase
                end
                else
                begin
                     case(func3)
                         3'b000://nop,addi
                         begin
                             if({instruction[12],instruction[6:2]} == 6'd0)//nop
                             begin
                                  rs1	  	            = {GPR_ADDR_WIDTH{1'b0}}	;
		                          rs2	   	            = {GPR_ADDR_WIDTH{1'b0}}	;
		                          rd	   	            = {GPR_ADDR_WIDTH{1'b0}}	;
		                          imm_r	   	            = {{(DATA_WIDTH-2){1'b0}},2'd2}	 ;
		                          alu_ctrl_r 	        = {4'd0,instruction[12],instruction[6:2],opcode}	;//0000_0_00000_01
		                          reg_wr_en_r  	        = 1'b0						;
		                          mem_rd_en_r  	        = 1'b0						;
		                          mem_wr_en_r  	        = 1'b0						;
		                          mem_to_reg_en_r       = 1'b0						;
		                          e_call_valid_o  	    = 1'b0				        ;	
		                          e_break_valid_o 	    = 1'b0				        ;	
		                          invalid_instruction_w = 1'b0			            ;
		                          ret_func_valid        = 1'b0                      ;
                                  ebreak_valid_o        = 1'b0                      ;                
                             end
                             else //addi
                             begin
                                  rs1	  	            = source_reg1               ;
		                          rs2	   	            = {GPR_ADDR_WIDTH{1'b0}}	;
		                          rd	   	            = dest_reg                  ;
		                          imm_r	   	            = {{(DATA_WIDTH-6){instruction[12]}},instruction[12],instruction[6:2]}	    ;
		                          alu_ctrl_r 	        = {6'd0,1'b1,func3,opcode}		            ;//000000_1_000_01
		                          reg_wr_en_r  	        = 1'b1						;
		                          mem_rd_en_r  	        = 1'b0						;
		                          mem_wr_en_r  	        = 1'b0						;
		                          mem_to_reg_en_r        = 1'b0						;
		                          e_call_valid_o  	    = 1'b0				        ;	
		                          e_break_valid_o 	    = 1'b0				        ;	
		                          invalid_instruction_w  = 1'b0			            ;
		                          ret_func_valid         = 1'b0                      ;
                                  ebreak_valid_o         = 1'b0                      ; 
                             end
                         end

                         3'b001://jal
                         begin
                                 rs1	  	                = {GPR_ADDR_WIDTH{1'b0}}    ;
		                         rs2	   	                = {GPR_ADDR_WIDTH{1'b0}}	;
		                         rd	   	                = {GPR_ADDR_WIDTH{1'b0}}    ;
		                         imm_r	   	            = {{(DATA_WIDTH-12){instruction[12]}},instruction[12],instruction[8],instruction[10:9],instruction[6],instruction[7],instruction[2],instruction[11],instruction[5:3],1'b0}	    ;
		                         alu_ctrl_r 	            = {7'd0,func3,opcode}			            ;
		                         reg_wr_en_r  	        = 1'b1						;
		                         mem_rd_en_r  	        = 1'b0						;
		                         mem_wr_en_r  	        = 1'b0						;
		                         mem_to_reg_en_r         = 1'b0						;
		                         e_call_valid_o  	    = 1'b0				        ;	
		                         e_break_valid_o 	    = 1'b0				        ;	
		                         invalid_instruction_w   = 1'b0			            ;
		                         ret_func_valid          = 1'b1                      ;
                                 ebreak_valid_o          = 1'b0                      ;                                       
                         end
                         
                         3'b010://li
                         begin
                             if(instruction[11:7] != 5'd0) //li
                             begin
                                 rs1	  	                = {GPR_ADDR_WIDTH{1'b0}}    ;
		                         rs2	   	                = {GPR_ADDR_WIDTH{1'b0}}	;
		                         rd	   	                = dest_reg                  ;
		                         imm_r	   	            = {{(DATA_WIDTH-6){instruction[12]}},instruction[12],instruction[6:2]}	    ;
		                         alu_ctrl_r 	            = {7'd0,func3,opcode}			            ;
		                         reg_wr_en_r  	        = 1'b1						;
		                         mem_rd_en_r  	        = 1'b0						;
		                         mem_wr_en_r  	        = 1'b0						;
		                         mem_to_reg_en_r         = 1'b0						;
		                         e_call_valid_o  	    = 1'b0				        ;	
		                         e_break_valid_o 	    = 1'b0				        ;	
		                         invalid_instruction_w   = 1'b0			            ;
		                         ret_func_valid          = 1'b0                      ;
                                 ebreak_valid_o          = 1'b0                      ;                               
                             end
                             else
                             begin
                                 rs1	  	                = {GPR_ADDR_WIDTH{1'b0}}    ;
		                         rs2	   	                = {GPR_ADDR_WIDTH{1'b0}}	;
		                         rd	   	                = {GPR_ADDR_WIDTH{1'b0}}    ;
		                         imm_r	   	            = {(DATA_WIDTH){1'b0}}	    ;
		                         alu_ctrl_r 	            = 12'b0			            ;
		                         reg_wr_en_r  	        = 1'b0						;
		                         mem_rd_en_r  	        = 1'b0						;
		                         mem_wr_en_r  	        = 1'b0						;
		                         mem_to_reg_en_r         = 1'b0						;
		                         e_call_valid_o  	    = 1'b0				        ;	
		                         e_break_valid_o 	    = 1'b0				        ;	
		                         invalid_instruction_w   = 1'b1			            ;
		                         ret_func_valid          = 1'b0                      ;
                                 ebreak_valid_o          = 1'b0                      ;                               
                             end
                         end
                         
                         3'b011://lui, addi16sp
                         begin
                             if(instruction[11:7] != 5'd0 && instruction[11:7] != 5'd2) //lui
                             begin
                                 rs1	  	                = {GPR_ADDR_WIDTH{1'b0}}    ;
		                         rs2	   	                = {GPR_ADDR_WIDTH{1'b0}}	;
		                         rd	   	                = dest_reg                  ;
		                         imm_r	   	            = {{(DATA_WIDTH-18){instruction[12]}},instruction[12],instruction[6:2],12'd0};
		                         alu_ctrl_r 	            = {7'd0,func3,opcode}			            ;
		                         reg_wr_en_r  	        = 1'b1						;
		                         mem_rd_en_r  	        = 1'b0						;
		                         mem_wr_en_r  	        = 1'b0						;
		                         mem_to_reg_en_r         = 1'b0						;
		                         e_call_valid_o  	    = 1'b0				        ;	
		                         e_break_valid_o 	    = 1'b0				        ;	
		                         invalid_instruction_w   = 1'b0			            ;
		                         ret_func_valid          = 1'b0                      ;
                                 ebreak_valid_o          = 1'b0                      ;                               
                             end
                             else if({instruction[12],instruction[6:2]} != 6'd0 )//addi16sp
                             begin
                                 rs1	  	                = {{(GPR_ADDR_WIDTH-2){1'b0}},2'b10};
                                 rs2	   	                = {GPR_ADDR_WIDTH{1'b0}}	;
		                         rd	   	                = {{(GPR_ADDR_WIDTH-2){1'b0}},2'b10};
		                         imm_r	   	            = {{(DATA_WIDTH-10){1'b0}},instruction[12],instruction[4:3],instruction[5],instruction[2],instruction[6],4'd0}	    ;
		                         alu_ctrl_r 	            = {2'd0,instruction[11:7],func3,opcode}			            ;
		                         reg_wr_en_r  	        = 1'b1						;
		                         mem_rd_en_r  	        = 1'b0						;
		                         mem_wr_en_r  	        = 1'b0						;
		                         mem_to_reg_en_r         = 1'b0						;
		                         e_call_valid_o  	    = 1'b0				        ;	
		                         e_break_valid_o 	    = 1'b0				        ;	
		                         invalid_instruction_w   = 1'b0			            ;
		                         ret_func_valid          = 1'b0                      ;
                                 ebreak_valid_o          = 1'b0                      ;                               
                             end
                             else
                             begin
                                 rs1	  	                = {GPR_ADDR_WIDTH{1'b0}}    ;
		                         rs2	   	                = {GPR_ADDR_WIDTH{1'b0}}	;
		                         rd	   	                = {GPR_ADDR_WIDTH{1'b0}}    ;
		                         imm_r	   	            = {(DATA_WIDTH){1'b0}}	    ;
		                         alu_ctrl_r 	            = 12'b0			            ;
		                         reg_wr_en_r  	        = 1'b0						;
		                         mem_rd_en_r  	        = 1'b0						;
		                         mem_wr_en_r  	        = 1'b0						;
		                         mem_to_reg_en_r         = 1'b0						;
		                         e_call_valid_o  	    = 1'b0				        ;	
		                         e_break_valid_o 	    = 1'b0				        ;	
		                         invalid_instruction_w   = 1'b1			            ;
		                         ret_func_valid          = 1'b0                      ;
                                 ebreak_valid_o          = 1'b0                      ;                             
                             end
                         end
                         3'b100://srli, srai, andi
                         begin
                            case(func2)
                             2'b00://srli
                             begin
                                 rs1	  	                = source_reg1 + 5'd8              ;
		                         rs2	   	                = {GPR_ADDR_WIDTH{1'b0}}	      ;
		                         rd	   	                = dest_reg + 5'd8                 ;
		                         imm_r	   	            = {{(DATA_WIDTH-6){1'b0}},instruction[12],instruction[6:2]}	    ;
		                         alu_ctrl_r 	            = {5'd0,instruction[11:10],func3,opcode}	    ;//00000_00_100_01
		                         reg_wr_en_r  	        = 1'b1						;
		                         mem_rd_en_r  	        = 1'b0						;
		                         mem_wr_en_r  	        = 1'b0						;
		                         mem_to_reg_en_r         = 1'b0						;
		                         e_call_valid_o  	    = 1'b0				        ;	
		                         e_break_valid_o 	    = 1'b0				        ;	
		                         invalid_instruction_w   = 1'b0			            ;
		                         ret_func_valid          = 1'b0                      ;
                                 ebreak_valid_o          = 1'b0                      ;  
                             end
                             2'b01://srai
                             begin
                                 rs1	  	                = source_reg1 + 5'd8              ;
		                         rs2	   	                = {GPR_ADDR_WIDTH{1'b0}}	      ;
		                         rd	   	                = dest_reg + 5'd8                 ;
		                         imm_r	   	            = {{(DATA_WIDTH-6){1'b0}},instruction[12],instruction[6:2]}	    ;
		                         alu_ctrl_r 	            = {5'd0,instruction[11:10],func3,opcode}	    ;//00000_01_100_01
		                         reg_wr_en_r  	        = 1'b1						;
		                         mem_rd_en_r  	        = 1'b0						;
		                         mem_wr_en_r  	        = 1'b0						;
		                         mem_to_reg_en_r         = 1'b0						;
		                         e_call_valid_o  	    = 1'b0				        ;	
		                         e_break_valid_o 	    = 1'b0				        ;	
		                         invalid_instruction_w   = 1'b0			            ;
		                         ret_func_valid          = 1'b0                      ;
                                 ebreak_valid_o          = 1'b0                      ;  
                             end
                             2'b10://andi
                             begin
                                 rs1	  	                = source_reg1 + 5'd8              ;
		                         rs2	   	                = {GPR_ADDR_WIDTH{1'b0}}	      ;
		                         rd	   	                = dest_reg + 5'd8                 ;
		                         imm_r	   	            = {{(DATA_WIDTH-6){instruction[12]}},instruction[12],instruction[6:2]}	    ;
		                         alu_ctrl_r 	            = {5'd0,instruction[11:10],func3,opcode}	    ;//00000_10_100_01
		                         reg_wr_en_r  	        = 1'b1						;
		                         mem_rd_en_r  	        = 1'b0						;
		                         mem_wr_en_r  	        = 1'b0						;
		                         mem_to_reg_en_r         = 1'b0						;
		                         e_call_valid_o  	    = 1'b0				        ;	
		                         e_break_valid_o 	    = 1'b0				        ;	
		                         invalid_instruction_w   = 1'b0			            ;
		                         ret_func_valid          = 1'b0                      ;
                                 ebreak_valid_o          = 1'b0                      ;  
                             end
                             default:
                             begin
                                 rs1	  	                = {GPR_ADDR_WIDTH{1'b0}}    ;
		                         rs2	   	                = {GPR_ADDR_WIDTH{1'b0}}	;
		                         rd	   	                = {GPR_ADDR_WIDTH{1'b0}}    ;
		                         imm_r	   	            = {(DATA_WIDTH){1'b0}}	    ;
		                         alu_ctrl_r 	            = 12'b0			            ;
		                         reg_wr_en_r  	        = 1'b0						;
		                         mem_rd_en_r  	        = 1'b0						;
		                         mem_wr_en_r  	        = 1'b0						;
		                         mem_to_reg_en_r         = 1'b0						;
		                         e_call_valid_o  	    = 1'b0				        ;	
		                         e_break_valid_o 	    = 1'b0				        ;	
		                         invalid_instruction_w   = 1'b1			            ;
		                         ret_func_valid          = 1'b0                      ;
                                 ebreak_valid_o          = 1'b0                      ;                              
                             end
                            endcase
                         end
                         
                         3'b101://j
                         begin
                            rs1	  	                = {GPR_ADDR_WIDTH{1'b0}}    ;
		                    rs2	   	                = {GPR_ADDR_WIDTH{1'b0}}	;
		                    rd	   	                = {GPR_ADDR_WIDTH{1'b0}}    ;//pc
		                    imm_r	   	            = {{(DATA_WIDTH-12){instruction[12]}},instruction[12],instruction[8],instruction[10:9],instruction[6],instruction[7],instruction[2],instruction[11],instruction[5:3],1'b0}	    ;
		                    alu_ctrl_r 	            = {7'd0,func3,opcode}	    ;//0000000_101_01
		                    reg_wr_en_r  	        = 1'b1						;
		                    mem_rd_en_r  	        = 1'b0						;
		                    mem_wr_en_r  	        = 1'b0						;
		                    mem_to_reg_en_r          = 1'b0						;
		                    e_call_valid_o  	        = 1'b0				        ;	
		                    e_break_valid_o 	        = 1'b0				        ;	
		                    invalid_instruction_w    = 1'b0			            ;
		                    ret_func_valid           = 1'b0                      ;
                            ebreak_valid_o           = 1'b0                      ;      
                         end
                         
                         3'b110://beqz
                         begin
                             rs1	  	                = source_reg1 + 5'd8        ;
		                     rs2	   	                = {GPR_ADDR_WIDTH{1'b0}}	;
		                     rd	   	                = {GPR_ADDR_WIDTH{1'b0}}    ;
		                     imm_r	   	            = {{(DATA_WIDTH-9){instruction[12]}},instruction[12],instruction[6:5],instruction[2],instruction[11:10],instruction[4:3],1'b0}	    ;
		                     alu_ctrl_r 	            = {7'd0,func3,opcode}	    ;//0000000_110_01
		                     reg_wr_en_r  	        = 1'b0						;
		                     mem_rd_en_r  	        = 1'b0						;
		                     mem_wr_en_r  	        = 1'b0						;
		                     mem_to_reg_en_r         = 1'b0						;
		                     e_call_valid_o  	    = 1'b0			        	;	
		                     e_break_valid_o 	    = 1'b0			        	;	
		                     invalid_instruction_w   = 1'b0			            ;
		                     ret_func_valid          = 1'b0                      ;
                             ebreak_valid_o          = 1'b0                      ;    
                         end
                         
                         3'b111://bnez
                         begin
                             rs1	  	                = source_reg1 + 5'd8        ;
		                     rs2	   	                = {GPR_ADDR_WIDTH{1'b0}}	;
		                     rd	   	                = {GPR_ADDR_WIDTH{1'b0}}    ;
		                     imm_r	   	            = {{(DATA_WIDTH-9){instruction[12]}},instruction[12],instruction[6:5],instruction[2],instruction[11:10],instruction[4:3],1'b0}	    ;
		                     alu_ctrl_r 	            = {7'd0,func3,opcode}	    ;//0000000_111_01
		                     reg_wr_en_r  	        = 1'b0						;
		                     mem_rd_en_r  	        = 1'b0						;
		                     mem_wr_en_r  	        = 1'b0						;
		                     mem_to_reg_en_r         = 1'b0						;
		                     e_call_valid_o  	    = 1'b0			        	;	
		                     e_break_valid_o 	    = 1'b0			        	;	
		                     invalid_instruction_w   = 1'b0			            ;
		                     ret_func_valid          = 1'b0                      ;
                             ebreak_valid_o          = 1'b0                      ;                        
                         end
                         
                         default:
                         begin
                          rs1	  	            = {GPR_ADDR_WIDTH{1'b0}}    ;
		                  rs2	   	            = {GPR_ADDR_WIDTH{1'b0}}	;
		                  rd	   	                = {GPR_ADDR_WIDTH{1'b0}}    ;
		                  imm_r	   	            = {DATA_WIDTH{1'b0}}	    ;
		                  alu_ctrl_r 	        = 12'b0			            ;
		                  reg_wr_en_r  	        = 1'b0						;
		                  mem_rd_en_r  	        = 1'b0						;
		                  mem_wr_en_r  	        = 1'b0						;
		                  mem_to_reg_en_r        = 1'b0						;
		                  e_call_valid_o  	    = 1'b0				        ;	
		                  e_break_valid_o 	    = 1'b0				        ;	
		                  invalid_instruction_w  = 1'b1			            ;
		                  ret_func_valid         = 1'b0                      ;
                          ebreak_valid_o         = 1'b0                      ;                          
                         end
                     endcase
                end
            end

            2'b10: // lwsp, swsp, jr, jalr, slli, mv, add, ebreak
            begin
                if(func4 == 4'b1000)//jr, mv
                begin
                    if(source_reg2 != 5'd0 && dest_reg != 5'd0) //mv
                    begin
                         rs1	   	             = source_reg1          	;
		                 rs2	   	             = source_reg2          	;
		                 rd	   	                 = dest_reg         	    ;
		                 imm_r	   	             = {DATA_WIDTH{1'b0}}	    ;
		                 alu_ctrl_r 	         = {instruction[15:12],6'd4,opcode}	;//1000_000100_10
		                 reg_wr_en_r  	         = 1'b1						;
		                 mem_rd_en_r  	         = 1'b0						;
		                 mem_wr_en_r  	         = 1'b0						;
		                 mem_to_reg_en_r         = 1'b0						;
		                 e_call_valid_o  	     = 1'b0			        	;	
		                 e_break_valid_o 	     = 1'b0			        	;	
		                 invalid_instruction_w   = 1'b0			            ;
		                 ret_func_valid          = 1'b0                     ;
                         ebreak_valid_o          = 1'b0                     ;
                    end
                    else//jr
                    begin
 		                 rs1	   	             = source_reg1          	;
		                 rs2	   	             = {GPR_ADDR_WIDTH{1'b0}}          	;
		                 rd	   	                 = {GPR_ADDR_WIDTH{1'b0}}	    ;
		                 imm_r	   	             = {DATA_WIDTH{1'b0}}	    ;
		                 alu_ctrl_r 	         = {1'b0,instruction[6:2],instruction[12],func3,opcode}	;//0_00000_0_100_10
		                 reg_wr_en_r  	         = 1'b1						;
		                 mem_rd_en_r  	         = 1'b1						;
		                 mem_wr_en_r  	         = 1'b0						;
		                 mem_to_reg_en_r         = 1'b0						;
		                 e_call_valid_o  	     = 1'b0			        	;	
		                 e_break_valid_o 	     = 1'b0			        	;	
		                 invalid_instruction_w   = 1'b0			            ;
		                 ret_func_valid          = 1'b0                     ;
                         ebreak_valid_o          = 1'b0                     ;
                    end
                end
                else if(func4 == 4'b1001)//jalr, add, ebreak
                begin
                    if(dest_reg != 0 && source_reg2 != 0)//add
                    begin
 		                 rs1	   	             = source_reg1           	;
		                 rs2	   	             = source_reg2           	;
		                 rd	   	                 = dest_reg                 ;
		                 imm_r	   	             = {DATA_WIDTH{1'b0}}	    ;
		                 alu_ctrl_r 	         = {6'b010000,func4,opcode}	;//010000_1001_10
		                 reg_wr_en_r  	         = 1'b1						;
		                 mem_rd_en_r  	         = 1'b0						;
		                 mem_wr_en_r  	         = 1'b0						;
		                 mem_to_reg_en_r         = 1'b0						;
		                 e_call_valid_o  	     = 1'b0			        	;	
		                 e_break_valid_o 	     = 1'b0			        	;	
		                 invalid_instruction_w   = 1'b0			            ;
		                 ret_func_valid          = 1'b0                     ;
                         ebreak_valid_o          = 1'b0                     ;
                    end
                    else if(source_reg1 != 0)//jalr
                    begin
 		                 rs1	   	             = source_reg1          	;
		                 rs2	   	             = {GPR_ADDR_WIDTH{1'b0}}   ;
		                 rd	   	                 = {GPR_ADDR_WIDTH{1'b0}}	;
		                 imm_r	   	             = {DATA_WIDTH{1'b0}}	    ;
		                 alu_ctrl_r 	         = {6'b100000,func4,opcode}	;//000000_1001_10
		                 reg_wr_en_r  	         = 1'b1						;
		                 mem_rd_en_r  	         = 1'b1						;
		                 mem_wr_en_r  	         = 1'b0						;
		                 mem_to_reg_en_r         = 1'b0						;
		                 e_call_valid_o  	     = 1'b0			        	;	
		                 e_break_valid_o 	     = 1'b0			        	;	
		                 invalid_instruction_w   = 1'b0			            ;
		                 ret_func_valid          = 1'b1                     ;
                         ebreak_valid_o          = 1'b0                     ;
                    end
                    else //ebreak
                    begin
                         rs1	  	             = {GPR_ADDR_WIDTH{1'b0}}   ;
                         rs2	  	             = {GPR_ADDR_WIDTH{1'b0}}   ;
                         rd	  	                 = {GPR_ADDR_WIDTH{1'b0}}   ;
		                 imm_r	   	             = {DATA_WIDTH{1'b0}}	    ;
		                 alu_ctrl_r 	         = {6'b001000,func4,opcode}	;//001000_1001_10
		                 reg_wr_en_r  	         = 1'b0						;
		                 mem_rd_en_r  	         = 1'b0						;
		                 mem_wr_en_r  	         = 1'b0						;
		                 mem_to_reg_en_r         = 1'b0						;
		                 e_call_valid_o  	     = 1'b0			        	;	
		                 e_break_valid_o 	     = 1'b1			        	;	
		                 invalid_instruction_w   = 1'b0			            ;
		                 ret_func_valid          = 1'b0                     ;
                         ebreak_valid_o          = 1'b1                     ;
                    end                    
                end
                else
                begin
                    case(func3)
                    3'b000: //slli
                    begin
                        if(instruction[12] == 1'b0)
                        begin
                             rs1	  	            = source_reg1               ;
		                     rs2	   	            = {GPR_ADDR_WIDTH{1'b0}}	;
		                     rd	   	                = dest_reg                  ;
		                     imm_r	   	            = {{(DATA_WIDTH-6){1'b0}},instruction[12],instruction[6:2]} ;
		                     alu_ctrl_r 	        = {7'd0,func3,opcode}			            ;//0000000_000_10
		                     reg_wr_en_r  	        = 1'b1						;
		                     mem_rd_en_r  	        = 1'b0						;
		                     mem_wr_en_r  	        = 1'b0						;
		                     mem_to_reg_en_r        = 1'b0						;
		                     e_call_valid_o  	    = 1'b0				;	
		                     e_break_valid_o 	    = 1'b0				;	
		                     invalid_instruction_w  = 1'b0			    ;
		                     ret_func_valid         = 1'b0              ;
                             ebreak_valid_o         = 1'b0              ;
                        end
                        else
                        begin
                             rs1	  	            = {GPR_ADDR_WIDTH{1'b0}}    ;
		                     rs2	   	            = {GPR_ADDR_WIDTH{1'b0}}	;
		                     rd	   	                = {GPR_ADDR_WIDTH{1'b0}}    ;
		                     imm_r	   	            = {DATA_WIDTH{1'b0}}	    ;
		                     alu_ctrl_r 	        = 12'b0			            ;
		                     reg_wr_en_r  	        = 1'b0						;
		                     mem_rd_en_r  	        = 1'b0						;
		                     mem_wr_en_r  	        = 1'b0						;
		                     mem_to_reg_en_r        = 1'b0						;
		                     e_call_valid_o  	    = 1'b0				        ;	
		                     e_break_valid_o 	    = 1'b0				        ;	
		                     invalid_instruction_w  = 1'b1			            ;
		                     ret_func_valid         = 1'b0                      ;
                             ebreak_valid_o         = 1'b0                      ;                               
                        end
                    end
                    3'b110://swsp
                    begin
                        
                        rs1	  	            = {{(GPR_ADDR_WIDTH-2){1'b0}},2'b10};
		            	rs2	   	            = source_reg2	            ;
		            	rd	   	            = {GPR_ADDR_WIDTH{1'b0}}    ;
		                imm_r	   	        = {{(DATA_WIDTH-8){1'b0}},instruction[8:7],instruction[12:9],2'b00}	    ;
		            	alu_ctrl_r 	        = {7'd0,func3,opcode}			            ;//0000000_110_10
		            	reg_wr_en_r  	    = 1'b0						;
		            	mem_rd_en_r  	    = 1'b0						;
		            	mem_wr_en_r  	    = 1'b1						;
		            	mem_to_reg_en_r     = 1'b0						;
		            	e_call_valid_o  	= 1'b0				;	
		            	e_break_valid_o 	= 1'b0				;	
		            	invalid_instruction_w = 1'b0			;
		                ret_func_valid      = 1'b0              ;
                        ebreak_valid_o      = 1'b0              ;

                    end
                    3'b010://lwsp
                    begin  
                        rs1	  	            = {{(GPR_ADDR_WIDTH-2){1'b0}},2'b10}    ;//2'b10 --> sp
		            	rs2	   	            = {GPR_ADDR_WIDTH{1'b0}}	;
		            	rd	   	            = dest_reg                  ;
		                imm_r	   	        = {{(DATA_WIDTH-8){1'b0}},instruction[3:2],instruction[12],instruction[6:4],2'b00};
		            	alu_ctrl_r 	        = {7'd0,func3,opcode}			            ;//0000000_010_10
		            	reg_wr_en_r  	    = 1'b1						;
		            	mem_rd_en_r  	    = 1'b1						;
		            	mem_wr_en_r  	    = 1'b0						;
		            	mem_to_reg_en_r     = 1'b1						;
		            	e_call_valid_o  	= 1'b0				;	
		            	e_break_valid_o 	= 1'b0				;	
		            	invalid_instruction_w = 1'b0			;
		                ret_func_valid      = 1'b0              ;
                        ebreak_valid_o      = 1'b0              ;

                    end
                    default:
                    begin
                        
                        rs1	  	            = {GPR_ADDR_WIDTH{1'b0}}    ;
		            	rs2	   	            = {GPR_ADDR_WIDTH{1'b0}}	;
		            	rd	   	            = {GPR_ADDR_WIDTH{1'b0}}    ;
		                imm_r	   	        = {DATA_WIDTH{1'b0}}	    ;
		            	alu_ctrl_r 	        = 12'b0			            ;
		            	reg_wr_en_r  	    = 1'b0						;
		            	mem_rd_en_r  	    = 1'b0						;
		            	mem_wr_en_r  	    = 1'b0						;
		            	mem_to_reg_en_r     = 1'b0						;
		            	e_call_valid_o  	= 1'b0				;	
		            	e_break_valid_o 	= 1'b0				;	
		            	invalid_instruction_w = 1'b1			;
		                ret_func_valid      = 1'b0              ;
                        ebreak_valid_o      = 1'b0              ;

                    end
                    endcase

                end
            end

            default:
            begin
                 rs1	  	             = {GPR_ADDR_WIDTH{1'b0}}   ;
		         rs2	   	             = {GPR_ADDR_WIDTH{1'b0}}	;
		         rd	   	                 = {GPR_ADDR_WIDTH{1'b0}}   ;
		         imm_r	   	             = {DATA_WIDTH{1'b0}}	    ;
		         alu_ctrl_r 	         = 12'b0			        ;
		         reg_wr_en_r  	         = 1'b0						;
		         mem_rd_en_r  	         = 1'b0						;
		         mem_wr_en_r  	         = 1'b0						;
		         mem_to_reg_en_r         = 1'b0						;
		         e_call_valid_o  	     = 1'b0			        	;	
		         e_break_valid_o 	     = 1'b0			        	;	
		         invalid_instruction_w   = 1'b1			            ;
		         ret_func_valid          = 1'b0                     ;
                 ebreak_valid_o          = 1'b0                     ;
                
            end
            endcase
        end
endmodule




