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
* File Name : top.sv

* Purpose :

* Creation Date : 13-02-2023

* Last Modified : Fri 03 Mar 2023 10:35:26 PM IST

* Created By :  

//////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

`timescale 1ns / 1ps
module riscv_top #(
        parameter DATA_WIDTH          = 32    ,
        parameter PC_WIDTH            = 20    ,
        parameter INSTRUCTION_WIDTH   = 16    ,
        parameter OPCODE              = 2     ,
        parameter FUNC3               = 3     ,
        parameter FUNC4               = 4     ,
        parameter FUNC2               = 2     ,
        parameter FUNC6               = 6     ,
        parameter GPR_ADDR_WIDTH      = 5     
                   )
(
    input logic 		                    risc_clk			    , //global clock
    input logic		                        risc_rst			    , //global reset
    input logic   [INSTRUCTION_WIDTH-1:0]   instruction             ,
    //input logic   [PC_WIDTH-1:0]            pc                      ,
    output logic                            data_mem_write_en_o     ,
    output logic  [DATA_WIDTH-1:0]          data_mem_write_data_o   ,
    output logic  [DATA_WIDTH-1:0]          data_mem_write_addr_o   ,
    output logic                            data_mem_read_en_o      ,
    output logic  [DATA_WIDTH-1:0]          data_mem_read_addr_o    ,
    output logic                            id_ex_mem_rd_en         ,
    input logic   [DATA_WIDTH-1:0]          data_mem_read_data_i    ,
    output logic		                    carry				    , //carry flag 
    output logic		                    zero		 		      //zero  flag                         
    
);
    /////////////////////////Instruction decoder//////////////////////////////
    logic   [INSTRUCTION_WIDTH-1:0] 	de_instruction_w	            ;
    logic   [OPCODE-1:0]	            opcode				            ;
    logic   [FUNC3-1 : 0]               func3                           ;
    logic   [11:0]                      alu_ctrl                        ;
    logic   [DATA_WIDTH-1:0]            imm_val                         ;
    logic   [DATA_WIDTH-1:0]            addr_gen_imm_val                ;
    logic   [GPR_ADDR_WIDTH-1:0]        rs1                             ;
    logic   [GPR_ADDR_WIDTH-1:0]        rs2                             ;
    logic   [GPR_ADDR_WIDTH-1:0]        rd                              ;
    logic                               reg_wr_en                       ;
    logic                               mem_rd_en                       ;
    logic                               mem_wr_en                       ;
    logic                               mem_to_reg_en                   ;
    logic   [OPCODE-1:0]	            opcode_r                        ;
    logic                               e_call_valid_w                  ;
    logic                               e_break_valid_w                 ;
    logic                               invalid_instruction_valid_w     ;
    logic                               decode_instruction_valid_w      ;
    logic                               ret_func_valid                  ;
    logic                               ebreak_valid_w                  ;
    logic   [DATA_WIDTH-1:0]            reg_write_data                  ;
    logic   [DATA_WIDTH-1:0]            rs1_data                        ;
    logic   [DATA_WIDTH-1:0]            rd_data                         ;
    logic   [DATA_WIDTH-1:0]            addr_gen_rs1_data               ;
    logic   [DATA_WIDTH-1:0]            rs2_data                        ;
    logic   [DATA_WIDTH-1:0]            target_addr_rs2_data            ;
    /////////////////////////  ALU    ///////////////////////////////////
    logic   [DATA_WIDTH-1:0]            alu_data_in_1                   ;
    logic   [DATA_WIDTH-1:0]            alu_data_in_2                   ;
    logic   [DATA_WIDTH-1:0]	        mem_addr		                ; // memory address
    logic   [DATA_WIDTH-1:0]            alu_out                         ;
    logic   [DATA_WIDTH-1:0]            addr_alu_out                    ;
    logic                               branch_en                       ;

    /////////////////////////////////////////////////////////////////////
    logic   [PC_WIDTH-1 :0] 	        if_id_pc			            ;
    logic   [PC_WIDTH-1 :0] 	        id_ex_pc			            ;
    logic   [PC_WIDTH-1 :0] 	        pc_r    			            ;
    
    
    //////////////////////  byte enable and sign bit ////////////////////
    logic   [(DATA_WIDTH>>3)-1 :0]    	id_ex_byte_en		            ;
    logic		                        id_ex_sign_bit  	            ;
    logic   [(DATA_WIDTH>>3)-1 :0]    	ex_mem_byte_en		            ;
    logic 		                        ex_mem_sign_bit 	            ;

    //////////////////// stall pipeline //////////////////////////////////
    logic 	    	                    stall_pipeline	            	;
    logic 	    	                    stall_en	            	    ;

    ////////////////////// destination reg ///////////////////////////////
    logic   [GPR_ADDR_WIDTH-1   :0] 	id_ex_rd		                ;
    logic   [GPR_ADDR_WIDTH-1   :0] 	ex_mem_rd		                ;
    logic   [GPR_ADDR_WIDTH-1   :0] 	mem_wb_rd		                ;

    //////////////////////// register write enable ///////////////////////
    logic  		                         id_ex_reg_wr_en            	;
    logic  		                         ex_mem_reg_wr_en            	;
    logic  		                         mem_wb_reg_wr_en            	;

    /////////////////////// memory read enable ///////////////////////////
    //logic  		                         id_ex_mem_rd_en            	;
    logic  		                         ex_mem_mem_rd_en	            ;
    logic  		                         mem_wb_mem_rd_en	            ;

    ////////////// memory write enable //////////////////////////////////
    logic  		                         id_ex_mem_wr_en            	;
    logic  		                         ex_mem_mem_wr_en	            ;
    logic  		                         mem_wb_mem_wr_en	            ;

    ////////// load data enable signal ///////////////////////////////////
    logic 		                         id_ex_mem_to_reg_en	        ;
    logic 		                         ex_mem_mem_to_reg_en           ;
    logic 		                         mem_wb_mem_to_reg_en           ;
    logic                                mem_to_reg_en_w                ;

    ///////////////////////////////////////////////////////////////////
    logic                                data_mem_write_en_to_stall     ;

    ////////////////////////////////////////////////////////////////////
    logic   [1:0 ]	                    forward_a		                ; // forwarding control signal in execution stage
    logic   [1:0 ]	                    forward_b		                ; // forwarding control signal in memory access stage
    logic   [DATA_WIDTH-1:0]            reg_write_data_1                ;
    logic   [DATA_WIDTH-1:0]	        store_data_r                    ;
    logic   [DATA_WIDTH-1:0]	        mem_out                         ;

    /////////////////////////////////////////////////////////////////////
    logic                               ld_valid_w                      ;
    logic                               sd_valid_w                      ;
    logic  	[1 :0]               	    byte_sel_w                      ;
    logic   [DATA_WIDTH-1:0]            ld_sd_addr	                    ;
    logic   [DATA_WIDTH-1:0]            ld_sd_addr_w	                ;
    logic   [DATA_WIDTH-1:0] 	        store_data	                    ;
    logic   [DATA_WIDTH-1:0]            ld_sd_addr_temp	                ;
    logic   [DATA_WIDTH-1:0] 	        addr_gen_data	                ;
    /////////////////////////////////////////////////////////////////////
    logic                             data_mem_write_en                 ;
    logic  [DATA_WIDTH-1:0]           data_mem_write_data               ;
    logic  [DATA_WIDTH-1:0]           data_mem_write_addr               ;
    logic  [(DATA_WIDTH>>3)-1:0]      data_mem_strobe                   ; 
    logic  [DATA_WIDTH-1:0]           data_mem_read_addr                ;
    logic                             data_mem_read_en                  ;
    

    //////////////////////////////////////////////////////////////////////
    logic  [DATA_WIDTH-1:0]           mem_to_mux                        ;
    logic  [DATA_WIDTH-1:0]           alu_to_mux                        ;
    logic   [11:0]                    alu_ctrl_mem                      ;
    //logic  [DATA_WIDTH-1:0]           mem_out_o                         ;
    //logic  [DATA_WIDTH-1:0]           mem_out_o_1                       ;
    //logic  [DATA_WIDTH-1:0]           mem_out_o_2                       ;
    logic                            mem_rd_en_mem_out                  ;
    logic                            mem_rd_en_mem_out_1                ;
    logic                            mem_rd_en_r                        ;


    /////////////////////////////////////////////////////////////////////
    always_ff@(posedge risc_clk or negedge risc_rst)
    begin
        if(!risc_rst)
        begin
            de_instruction_w        <= 16'd0                    ;
            data_mem_write_en_o     <= 1'b0                     ;
            data_mem_write_addr_o   <= {DATA_WIDTH{1'b0}}       ;
            data_mem_write_data_o   <= {DATA_WIDTH{1'b0}}       ;
            data_mem_read_addr_o    <= {DATA_WIDTH{1'b0}}       ;
            data_mem_read_en_o      <= {DATA_WIDTH{1'b0}}       ;
            mem_rd_en_mem_out       <= 1'b0                     ;
            mem_to_reg_en_w         <= 1'b0                     ;
            id_ex_rd  		        <= 5'd0                     ;
    	    ex_mem_rd 		        <= 5'd0                     ; 
    	    mem_wb_rd 		        <= 5'd0                     ;
    	    id_ex_reg_wr_en 	    <= 1'd0                     ;			
            ex_mem_reg_wr_en	    <= 1'd0                     ;		
            mem_wb_reg_wr_en	    <= 1'd0                     ;
    	    id_ex_mem_rd_en 	    <= 1'd0                     ;	
            ex_mem_mem_rd_en	    <= 1'd0                     ;	
    	    id_ex_mem_wr_en 	    <= 1'd0                     ; 	
            ex_mem_mem_wr_en	    <= 1'd0                     ;	
    	    id_ex_mem_to_reg_en 	<= 1'd0                     ;	
            ex_mem_mem_to_reg_en	<= 1'd0                     ;	
            mem_wb_mem_to_reg_en	<= 1'd0                     ;
            mem_wb_mem_rd_en        <= 1'b0                     ;
            //pc_r                    <= 20'd0                    ;

        end
        else
        begin
            de_instruction_w        <= instruction              ;        
            data_mem_write_en_o     <= data_mem_write_en        ;
            data_mem_write_addr_o   <= data_mem_write_addr      ;
            data_mem_write_data_o   <= data_mem_write_data      ;
            data_mem_read_addr_o    <= data_mem_read_addr       ;
            data_mem_read_en_o      <= data_mem_read_en         ;
            mem_rd_en_mem_out       <= mem_rd_en_mem_out_1      ;
            mem_to_reg_en_w         <= mem_to_reg_en            ;
    	    id_ex_rd  			    <= rd			            ;		
            ex_mem_rd 			    <= id_ex_rd		            ;				 
            id_ex_reg_wr_en 		<= reg_wr_en		        ;
            ex_mem_reg_wr_en		<= id_ex_reg_wr_en	        ;				  
            id_ex_mem_rd_en 		<= mem_rd_en		        ;
            ex_mem_mem_rd_en		<= id_ex_mem_rd_en	        ;
            id_ex_mem_wr_en 		<= mem_wr_en		        ;
            ex_mem_mem_wr_en		<= id_ex_mem_wr_en	        ;
            id_ex_mem_to_reg_en 	<= mem_to_reg_en	        ;            
            ex_mem_mem_to_reg_en	<= id_ex_mem_to_reg_en      ;            
            mem_wb_mem_to_reg_en	<= ex_mem_mem_to_reg_en	    ;            
    	    mem_wb_rd 		        <= ex_mem_rd		        ;
    	    mem_wb_reg_wr_en	    <= ex_mem_reg_wr_en	        ;
            mem_wb_mem_rd_en        <= ex_mem_mem_rd_en         ; 
            ld_sd_addr_w            <= ld_sd_addr               ;
            //pc_r                    <= pc                       ;
        end
    end

    assign      risc_rst_r              = risc_rst                                              ;

    assign      data_mem_write_en       = (ex_mem_mem_wr_en ) ? 1'b1         :  1'b0                  ;
    assign      data_mem_write_addr     = (data_mem_write_en) ? ld_sd_addr_w : {DATA_WIDTH{1'b0}}     ;    
    assign      data_mem_write_data     = (data_mem_write_en) ? store_data   : {DATA_WIDTH{1'b0}}     ;

    assign      data_mem_read_en        = (ex_mem_mem_rd_en)  ? 1'b1                 : 1'b0                  ;
    assign      data_mem_read_addr      = (data_mem_read_en)  ? ld_sd_addr_w         : {DATA_WIDTH{1'b0}}    ;
    assign      mem_out                 = (data_mem_read_en)  ? data_mem_read_data_i : 32'd0                 ;

    assign 		addr_gen_data           = (ex_mem_mem_to_reg_en) ?   mem_out            : alu_out               ; 

/*    ///////////////////////////////////////////////////////////////////
    //																//
    //				SIGNAL PIPELINING INSTANCE					    //
    //																//
    //////////////////////////////////////////////////////////////////
    pipe 
    #(
    .DATA_WIDTH     (DATA_WIDTH     ),
    .GPR_ADDR_WIDTH (GPR_ADDR_WIDTH )
     )
    pipe_inst
    (
    .*,
    .risc_clk	   			        (risc_clk	     		    ),			 
    .risc_rst    			        (risc_rst_r	     		    ),
    .rd		    			        (rd		     		        ),
    .reg_wr_en	    			    (reg_wr_en	     		    ),
    .mem_rd_en	    			    (mem_rd_en	     		    ),
    .mem_wr_en	    			    (mem_wr_en	     		    ),
    .mem_to_reg_en	    		    (mem_to_reg_en	     		),
    .stall_pipeline				    (stall_pipeline    	  		),
    .id_ex_rd  	    			    (id_ex_rd  	     		    ),
    .ex_mem_rd 	    			    (ex_mem_rd 	     		    ),
    .mem_wb_rd 	    			    (mem_wb_rd 	     		    ),
    .id_ex_reg_wr_en     			(id_ex_reg_wr_en     		),
    .ex_mem_reg_wr_en    			(ex_mem_reg_wr_en    		),    
    .mem_wb_reg_wr_en_o   			(mem_wb_reg_wr_en    		), 
    .id_ex_mem_rd_en     			(id_ex_mem_rd_en     		),
    .ex_mem_mem_rd_en    			(ex_mem_mem_rd_en    		),
    .id_ex_mem_wr_en     			(id_ex_mem_wr_en     		),
    .ex_mem_mem_wr_en    			(ex_mem_mem_wr_en    		),
    .mem_wb_mem_rd_en               (mem_wb_mem_rd_en           ),
    .id_ex_mem_to_reg_en 			(id_ex_mem_to_reg_en 		),
    .ex_mem_mem_to_reg_en			(ex_mem_mem_to_reg_en		),
    .mem_wb_mem_to_reg_en			(mem_wb_mem_to_reg_en		)    
    );
*/

    ////////////////////////////////////////////////////////////////// 
    //				INSTRUCTION DECODER INSTANCE				    //
    //																//
    //////////////////////////////////////////////////////////////////

    instruction_decoder #(.DATA_WIDTH         (DATA_WIDTH       ),
                          .INSTRUCTION_WIDTH  (INSTRUCTION_WIDTH),
                          .OPCODE             (OPCODE           ),
                          .FUNC3              (FUNC3            ),
                          .FUNC4              (FUNC4            ),
                          .FUNC2              (FUNC2            ),
                          .FUNC6              (FUNC6            ),
                          .GPR_ADDR_WIDTH     (GPR_ADDR_WIDTH   )
                          )
    instr_decoder
    (
    .*,
    .de_clk					    (risc_clk			            ),
    .de_rst					    (risc_rst_r			            ),
    .instruction_r				(de_instruction_w		        ),
    .stall_pipeline             (stall_pipeline                 ),
    .stall_en                   (stall_en                       ),
    .opcode					    (opcode				            ),
    //.func3					    (func3				            ),
    .alu_ctrl_r				    (alu_ctrl			            ),
    .imm_val				    (imm_val			            ),
    .imm_r					    (addr_gen_imm_val		        ),
    .rs1					    (rs1				            ),
    .rs2					    (rs2				            ),
    .rd					        (rd				                ),
    .reg_wr_en_r				(reg_wr_en			            ),
    .mem_rd_en_r				(mem_rd_en			            ),
    .mem_wr_en_r				(mem_wr_en			            ),
    .mem_to_reg_en_r 			(mem_to_reg_en		            ),
    .opcode_r				    (opcode_r			            ),
    .e_call_valid_o  			(e_call_valid_w 		        ),//e-call  exception
    .e_break_valid_o 			(e_break_valid_w 		        ),//e-break exception
    .invalid_instruction_valid_o(invalid_instruction_valid_w	),//invalid instruction exception
    //.decode_instruction_valid_i	(decode_instruction_valid_w	    ),
    .ret_func_valid				(ret_func_valid                 ),
    .ebreak_valid_o             (ebreak_valid_w                 )   
    );


    //////////////////////////////////////////////////////////////////
    //																//
    //			REGISTER FILE INSTANCE								//
    //																//
    //////////////////////////////////////////////////////////////////
    reg_file #(.DATA_WIDTH(DATA_WIDTH),
               .GPR_ADDR_WIDTH(GPR_ADDR_WIDTH)
               )
    reg_file_inst
    (
    .*,
    .reg_clk				            (risc_clk			            ),
    .wr_data_en				            (mem_wb_reg_wr_en		        ),	//from write back stage
    .rs1					            (rs1				            ),	//from decoder
    .rs2					            (rs2				            ),	//from decoder
    .rd					                (mem_wb_rd			            ),	//from write back stage
    //.stall_pipeline                     (stall_pipeline                 ),
    .wr_data				            (reg_write_data			        ),	//from write back 
    .rs1_data				            (rs1_data			            ),	//to alu
    .rs1_data_r				            (addr_gen_rs1_data		        ),	//to ld/sd addr
    .rs2_data				            (rs2_data			            ),	//to alu
    .rs2_data_r				            (target_addr_rs2_data	        )   //conditional branch     
    );


    //////////////////////////////////////////////////////////////////
    //																//
    //			ALU UNIT											//
    //																//
    //////////////////////////////////////////////////////////////////
    alu #(.DATA_WIDTH   (DATA_WIDTH ),
          .PC_WIDTH     (PC_WIDTH   ),
          .OPCODE       (OPCODE     )
         )
    alu_inst
    (
    .*,
    .alu_clk				    (risc_clk	                 ),
    .alu_rst				    (risc_rst_r	                 ),
    .alu_ctrl				    (alu_ctrl	                 ),
    .ld_sd_addr				    (ld_sd_addr	                 ),
    .imm_val				    (imm_val	                 ),
    .stall_pipeline             (stall_pipeline              ),
    .data_in_1				    (alu_data_in_1        	     ),
    .data_in_2				    (alu_data_in_2    	         ),
    .mem_addr				    (mem_addr	                 ),
    .data_out				    (alu_out	                 ),
    .data_out_1 				(addr_alu_out	             ),
    //.pc					        (pc_r		                 ),
    .carry  				    (carry		                 ),
    .zero 					    (zero		                 ),
    .id_ex_byte_en				(id_ex_byte_en	             ),
    .id_ex_sign_bit 			(id_ex_sign_bit	             ),
    .ex_mem_byte_en				(ex_mem_byte_en	             ),
    .ex_mem_sign_bit			(ex_mem_sign_bit             ),
    .opcode_r				    (opcode		                 ),
    .branch_en				    (branch_en	                 )
    );
/*
    //////////////////////////////////////////////////////////////////
    //																//
    //			DATA MEMORY INTERFACE								//
    //																//
    //////////////////////////////////////////////////////////////////
    
    data_mem #(.DATA_WIDTH(DATA_WIDTH))
    data_mem_inst
    (
    .*,
    .mem_clk				        (risc_clk	 		            ),
    .mem_rst        			    (risc_rst_r       		        ),
    .wr_en					        (data_mem_data_wr_en		    ),//id_ex_mem_wr_en //ex_mem_mem_wr_en
    .rd_en					        (data_mem_data_rd_en		    ),
    .wr_addr				        (ld_sd_addr	 		            ),//ld_sd_addr //mem_addr
    .rd_addr				        (ld_sd_addr	 		            ),
    .wr_data				        (store_data_r	 		        ),//store_data_r //store_data
    .rd_data				        (mem_out 	 		            ),
    .byte_en				        (id_ex_byte_en	 		        ),//id_ex_byte_en //ex_mem_byte_en
    .sign_bit 				        (ex_mem_sign_bit 		        ),
    .data_mem_write_en			    (data_mem_write_en		        ),
    .stall_en       			    (stall_pipeline			        ),	
    .data_mem_write_addr		    (data_mem_write_addr		    ),
    .data_mem_write_data		    (data_mem_write_data		    ),
    .data_mem_read_en			    (data_mem_read_en		        ),
    .data_mem_read_addr			    (data_mem_read_addr		        ),
    .data_mem_strobe			    (data_mem_strobe		        ),	
    .data_mem_read_data			    (data_mem_read_data	    	    )
    );
*/
    //////////////////////////////////////////////////////////////////
    //																//
    //			LOAD - STORE ADDRESS GENERATION     				//
    //																//
    //////////////////////////////////////////////////////////////////
    
    addr_gen #(.DATA_WIDTH(DATA_WIDTH),
               .GPR_ADDR_WIDTH(GPR_ADDR_WIDTH))
    addr_gen_inst
    (
    .*,
    .addr_clk				(risc_clk			    ),
    .addr_rst				(risc_rst_r			    ),
    .rs1_data				(addr_gen_rs1_data		),	//from logic file
    .imm_val				(addr_gen_imm_val		),	//from decoder
    .alu_ctrl				(alu_ctrl_mem   			),
    .id_ex_rd				(id_ex_rd			    ),
    .id_ex_reg_wr_en		(id_ex_reg_wr_en		),
    .id_ex_rs1				(rs1				    ),
    .id_ex_mem_wr_en		(mem_wr_en			    ),
    .id_ex_mem_rd_en		(mem_rd_en			    ),
    .alu_data				(addr_alu_out			),
    .mem_wb_data			(addr_gen_data			),
    .wb_data				(reg_write_data			),
    .addr					(ld_sd_addr			    ),//to execution phase
    .addr_temp              (ld_sd_addr_temp        ),
    .byte_en				(id_ex_byte_en			),
    .sign_bit				(id_ex_sign_bit			),
    .ld_valid				(ld_valid_w			    ),
    .sd_valid				(sd_valid_w			    ),
    .byte_sel_o				(byte_sel_w			    ),
    .stall_pipeline         (stall_pipeline         )
    );

    //////////////////////////////////////////////////////////////////
    //																//
    //		LOAD HAZARD DETECTION UNIT								//
    //																//
    //////////////////////////////////////////////////////////////////
    load_hazard_ctrl #(.GPR_ADDR_WIDTH(GPR_ADDR_WIDTH))
    load_hazard_ctrl_inst
    (
    .ld_hz_ctrl_clk				(risc_clk			),
    .ld_hz_ctrl_rst				(risc_rst_r			),
    .id_ex_mem_rd_en			(id_ex_mem_rd_en	),
    .id_ex_rd				    (id_ex_rd			),
    .if_id_rs1				    (rs1				),
    .if_id_rs2				    (rs2				),
    .stall_pipeline  			(stall_pipeline		),
    .stall_en           	    (stall_en			)
    );


    
    //////////////////////////////////////////////////////////////////
    //																//
    //				WRITE BACK MUX									//
    //																//
    //////////////////////////////////////////////////////////////////
    mux2x1 #(.DATA_WIDTH(DATA_WIDTH))
    mem_reg_mux
    (
    .in1					    (mem_to_mux			    ),//from memory
    .in2					    (alu_to_mux			    ),//from alu
    .sel					    (mem_wb_mem_to_reg_en	),
    .out					    (reg_write_data			)
    );


    /////////////////////////////////////////////////////////////////// 																//
    //			FORWARDING MUX										//
    //																//
    //////////////////////////////////////////////////////////////////

    fwd #(.DATA_WIDTH(DATA_WIDTH))
    fwd_inst
    (
    .*,
    .rs1_data				    (rs1_data			    ),		
    .rs2_data				    (rs2_data			    ),
    .alu_out				    (alu_out      			),
    .forward_a				    (forward_a			    ),
    .forward_b  				(forward_b			    ),
    .reg_write_data				(reg_write_data			),
    .reg_write_data_1			(reg_write_data_1		),
    .alu_data_in_1				(alu_data_in_1			),
    .alu_data_in_2				(alu_data_in_2			),
    .store_data_r				(store_data_r			)    
    );


    //////////////////////////////////////////////////////////////////																//
    //			FORWARD CONDITION DETECTION							//
    //																//
    //////////////////////////////////////////////////////////////////    
    forwarding #(.GPR_ADDR_WIDTH(GPR_ADDR_WIDTH))
    forwarding_inst
    (
    .*,
    .fwd_clk				(risc_clk			),
    .fwd_rst				(risc_rst_r			),
    .reg_wr_en				(reg_wr_en			),
    .rd					    (rd				    ),
    .rs1					(rs1				),
    .rs2					(rs2				),
    .forward_a				(forward_a			),
    .forward_b   			(forward_b			),
    .stall_pipeline         (stall_en           )
    );


    
    //////////////////////////////////////////////////////////////////
    //																//
    //				STORE DATA SELECTION							//
    //																//
    //////////////////////////////////////////////////////////////////
    
    store_data #(.DATA_WIDTH(DATA_WIDTH ),
                 .PC_WIDTH  (PC_WIDTH   ))
    store_data_inst
    (
    .*,
    .risc_clk				(risc_clk			    ),	
    .risc_rst				(risc_rst_r			    ),
    .alu_out 				(alu_out 			    ),
    .mem_out 				(mem_out 			    ),
    .alu_ctrl				(alu_ctrl			    ),
    .if_id_pc				(if_id_pc			    ),
    .reg_write_data			(reg_write_data			),
    .store_data_r			(store_data_r			),
    .store_data				(store_data			    ),
    .alu_to_mux				(alu_to_mux			    ),
    .mem_to_mux				(mem_to_mux			    ),
    .reg_write_data_1		(reg_write_data_1		),
    .alu_ctrl_mem			(alu_ctrl_mem			),
    .id_ex_pc				(id_ex_pc			    )
    );




endmodule

    module pipe #(  parameter DATA_WIDTH = 32,
                    parameter GPR_ADDR_WIDTH = 5
                 ) 
    (
    input logic 		                            risc_clk			        ,
    input logic 		                            risc_rst			        ,
    input logic    [GPR_ADDR_WIDTH-1:0]	            rd			   	            ,
    input logic 		                            reg_wr_en			        ,
    input logic 		                            mem_rd_en			        ,
    input logic 		                            mem_wr_en			        ,
    input logic 		                            mem_to_reg_en			    ,
    input logic 		                            stall_pipeline			    ,
    output logic   [GPR_ADDR_WIDTH-1:0]             id_ex_rd  			        ,	    
    output logic   [GPR_ADDR_WIDTH-1:0]             ex_mem_rd 			        ,	    
    output logic   [GPR_ADDR_WIDTH-1:0]             mem_wb_rd 			        ,    	
    output logic  	                                id_ex_reg_wr_en     		,
    output logic  	                                ex_mem_reg_wr_en    		,
    output logic   	                                mem_wb_reg_wr_en_o    		,
    output logic 	                                id_ex_mem_rd_en     		,
    output logic 	                                ex_mem_mem_rd_en    		,
    output logic 	                                id_ex_mem_wr_en     		,
    output logic 	                                ex_mem_mem_wr_en    		,
    output logic                                    mem_wb_mem_rd_en            ,
    output logic 	                                id_ex_mem_to_reg_en 		,
    output logic 	                                ex_mem_mem_to_reg_en		,
    output logic 	                                mem_wb_mem_to_reg_en		,
    output logic                                    mem_wb_reg_wr_en           
    );
        
    
    always_ff@(posedge risc_clk or negedge risc_rst )
    begin
    	if(!risc_rst )
    	begin
    	   id_ex_rd  		    <= 5'd0;
    	   ex_mem_rd 		    <= 5'd0; 
    	   mem_wb_rd 		    <= 5'd0;
    	   id_ex_reg_wr_en 	    <= 1'd0;			
           ex_mem_reg_wr_en	    <= 1'd0;		
           mem_wb_reg_wr_en	    <= 1'd0;
    	   id_ex_mem_rd_en 	    <= 1'd0;	
           ex_mem_mem_rd_en	    <= 1'd0;	
    	   id_ex_mem_wr_en 	    <= 1'd0; 	
           ex_mem_mem_wr_en	    <= 1'd0;	
    	   id_ex_mem_to_reg_en 	<= 1'd0;	
           ex_mem_mem_to_reg_en	<= 1'd0;	
           mem_wb_mem_to_reg_en	<= 1'd0;
           mem_wb_mem_rd_en     <= 1'b0;
    	end
    	else
    	begin
    		//if(!stall_pipeline)
    		//begin			
    		    id_ex_rd  			    <= rd			        ;		
                ex_mem_rd 			    <= id_ex_rd		        ;				 
                id_ex_reg_wr_en 		<= reg_wr_en		    ;
                ex_mem_reg_wr_en		<= id_ex_reg_wr_en	    ;				  
                id_ex_mem_rd_en 		<= mem_rd_en		    ;
                ex_mem_mem_rd_en		<= id_ex_mem_rd_en	    ;
                id_ex_mem_wr_en 		<= mem_wr_en		    ;
                ex_mem_mem_wr_en		<= id_ex_mem_wr_en	    ;
            
    /*            
    		end
           	else
    		begin
    	        id_ex_rd  		        <=5'd0;  
    	        ex_mem_rd 		        <=5'd0;
    	    	id_ex_reg_wr_en 	    <=1'b0;
    	    	ex_mem_reg_wr_en	    <=1'b0;
    	    	id_ex_mem_rd_en 	    <=1'b0;
    	    	ex_mem_mem_rd_en	    <=1'b0;
    	    	id_ex_mem_wr_en 	    <=1'b0;
    	    	ex_mem_mem_wr_en	    <=1'b0;
    	    	id_ex_mem_to_reg_en	    <=1'b0; 
    	    	ex_mem_mem_to_reg_en	<=1'b0;
                mem_wb_mem_rd_en      <= 1'b0;
                
    		end */

            id_ex_mem_to_reg_en 	<= mem_to_reg_en	    ;            
            ex_mem_mem_to_reg_en	<= id_ex_mem_to_reg_en  ;            
            mem_wb_mem_to_reg_en	<= ex_mem_mem_to_reg_en	;            
    	    mem_wb_rd 		        <= ex_mem_rd		    ;
    	    mem_wb_reg_wr_en	    <= ex_mem_reg_wr_en	    ;
            mem_wb_mem_rd_en        <= ex_mem_mem_rd_en     ; 

    	end
    end
    endmodule


    module fwd #(parameter DATA_WIDTH = 0)
    (
    input logic       [DATA_WIDTH-1:0] 		rs1_data	        ,
    input logic       [DATA_WIDTH-1:0]		rs2_data	        ,
    input logic       [DATA_WIDTH-1:0] 		alu_out		        ,
    input logic       [1:0]		            forward_a           ,
    input logic       [1:0] 	            forward_b           ,
    input logic       [DATA_WIDTH-1:0] 		reg_write_data	    ,
    input logic       [DATA_WIDTH-1:0] 		reg_write_data_1    ,
    output logic  [DATA_WIDTH-1:0] 	        alu_data_in_1	    ,
    output logic  [DATA_WIDTH-1:0] 	        alu_data_in_2       ,
    output logic  [DATA_WIDTH-1:0]	        store_data_r            
    );
    always_comb
    begin
    	unique case(forward_a)
    		2'b00:	
            begin
    			alu_data_in_1 = rs1_data	    ;
    		end
    		2'b01:  
            begin
    			alu_data_in_1 =  alu_out	    ;
    		end
    		2'b10:  
            begin
    			alu_data_in_1 =	reg_write_data	;
    		end
    		2'b11:
            begin
    			alu_data_in_1 = reg_write_data_1;
    		end
    		default:
            begin
    			alu_data_in_1 = rs1_data	    ;
    		end
    	endcase
    end
    
    always_comb
    begin

     unique case(forward_b)
     
         2'b00:	
         begin
         	alu_data_in_2 		= 	rs2_data	    ;
         	store_data_r		=	rs2_data	    ;
         end
         2'b01:  
         begin
         	alu_data_in_2 		= 	alu_out		    ;
         	store_data_r		= 	alu_out		    ;
         end
         2'b10:  
         begin
         	alu_data_in_2 		= 	reg_write_data	;
         	store_data_r		=	reg_write_data	;	
         end
         2'b11:
         begin
         	alu_data_in_2 		= 	reg_write_data_1;
         	store_data_r		=	reg_write_data_1;
         end
         default:
         begin
         	alu_data_in_2 		=	rs2_data	    ;
         	store_data_r		=	rs2_data	    ;
         end

     endcase

    end

    endmodule

    module store_data
    #(parameter DATA_WIDTH = 32,
      parameter PC_WIDTH = 20 
     )
    (
    input logic 			                risc_clk	        ,
    input logic 			                risc_rst	        ,
    input logic       [DATA_WIDTH-1:0] 	    alu_out 	        ,
    input logic       [DATA_WIDTH-1:0] 	    mem_out 	        ,
    input logic       [DATA_WIDTH-1:0] 	    reg_write_data	    ,
    input logic       [DATA_WIDTH-1:0]	    store_data_r	    ,
    input logic       [PC_WIDTH-1  :0]	    if_id_pc	        ,
    input logic       [11:0]	            alu_ctrl	        ,
    output logic      [DATA_WIDTH-1:0] 	    store_data	        ,
    output logic      [DATA_WIDTH-1:0] 	    alu_to_mux	        ,
    output logic      [DATA_WIDTH-1:0] 	    mem_to_mux	        ,
    output logic      [DATA_WIDTH-1:0] 	    reg_write_data_1    ,
    output logic      [11:0]	            alu_ctrl_mem	    ,
    output logic      [PC_WIDTH-1  :0]	    id_ex_pc                 
    );    

    always_ff@(posedge risc_clk or negedge risc_rst)
    begin
    if(!risc_rst )
    begin
    	store_data 		    <=		{DATA_WIDTH{1'b0}};
    	alu_to_mux		    <=		{DATA_WIDTH{1'b0}};
    	mem_to_mux 		    <= 		{DATA_WIDTH{1'b0}};
    	reg_write_data_1 	<=		{DATA_WIDTH{1'b0}};
    	alu_ctrl_mem		<= 		12'd0;
    	id_ex_pc		    <=	    {PC_WIDTH{1'b0}};
    end
    else
    begin
    	store_data		    <= 	store_data_r	;
    	alu_to_mux		    <=	alu_out			;
    	mem_to_mux 		    <= 	mem_out 		;
    	reg_write_data_1 	<= 	reg_write_data	;
    	alu_ctrl_mem		<= 	alu_ctrl		;
    	id_ex_pc		    <= 	if_id_pc		;
     end
    end
    endmodule


interface riscv_top_if  #(
                             parameter DATA_WIDTH          = 32    ,
                             parameter PC_WIDTH            = 20    ,
                             parameter INSTRUCTION_WIDTH   = 16    ,
                             parameter OPCODE              = 7     ,
                             parameter FUNC3               = 3     ,
                             parameter FUNC4               = 4     ,
                             parameter FUNC2               = 2     ,
                             parameter GPR_ADDR_WIDTH      = 5     
                         );
    logic 		                     risc_clk			     ; //global clock
    logic		                     risc_rst			     ; //global reset
    logic  [INSTRUCTION_WIDTH-1:0]   instruction             ; 
    //logic  [PC_WIDTH-1:0]            pc                      ;    
    logic                            data_mem_write_en_o     ;
    logic  [DATA_WIDTH-1:0]          data_mem_write_data_o   ;
    logic  [DATA_WIDTH-1:0]          data_mem_write_addr_o   ;
    logic                            data_mem_read_en_o      ;
    logic  [DATA_WIDTH-1:0]          data_mem_read_addr_o    ;
    logic                            id_ex_mem_rd_en         ;    
    logic  [DATA_WIDTH-1:0]          data_mem_read_data_i    ;
    logic		                     carry				     ; //carry flag 
    logic		                     zero		 		     ; //zero  flag  

endinterface 
