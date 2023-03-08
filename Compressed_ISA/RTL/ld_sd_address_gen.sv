`timescale 1ns / 1ps
module addr_gen
#(
    parameter DATA_WIDTH        = 32,
    parameter GPR_ADDR_WIDTH    = 5
)

(

    input logic 				                    addr_clk		,//external clock
    input logic 				                    addr_rst		,//external reset
    input logic 		[DATA_WIDTH-1:0] 		    rs1_data		,
    input logic 		[DATA_WIDTH-1:0] 		    imm_val			,
    input logic 		[GPR_ADDR_WIDTH-1:0] 		id_ex_rd		,
    input logic 		[GPR_ADDR_WIDTH-1:0] 		id_ex_rs1		,
    input logic 	    			                id_ex_reg_wr_en	,
    input logic	    			                    id_ex_mem_wr_en	,
    input logic	    			                    id_ex_mem_rd_en	,
    input logic 		[DATA_WIDTH-1:0] 		    alu_data		,
    input logic 		[DATA_WIDTH-1:0] 		    mem_wb_data		,
    input logic 		[DATA_WIDTH-1:0] 		    wb_data			,
    input logic 		[11:0] 	                	alu_ctrl		,
    output logic        [DATA_WIDTH-1:0] 		    addr			,
    output logic        [DATA_WIDTH-1:0] 		    addr_temp		,
    output logic        [(DATA_WIDTH>>3)-1 :0] 		byte_en			,
    output logic 		                            sign_bit		,
    output logic  			                        ld_valid		,
    output logic  			                        sd_valid		,
    output logic        [1:0] 		                byte_sel_o	    ,
    input logic                                     stall_pipeline

);


    //logic		[DATA_WIDTH-1:0] 		    addr_temp		    ;
    logic 		[DATA_WIDTH-1:0] 		    oper1			    ;
    logic 		[DATA_WIDTH-1:0] 		    oper2			    ;
    logic 		[GPR_ADDR_WIDTH-1:0] 		ex_mem_rd		    ;
    logic 		[GPR_ADDR_WIDTH-1:0] 		mem_wb_rd		    ;
    logic 		[GPR_ADDR_WIDTH-1:0] 		wb_rd			    ;
    logic 				                    ex_mem_reg_wr_en	;
    logic 				                    mem_wb_reg_wr_en	;
    logic 				                    wb_reg_wr_en		;
    logic 				                    ex_mem_mem_wr_en	;
    logic 				                    mem_mem_wr_en		;
    logic 				                    ex_mem_mem_rd_en	;
    logic 				                    mem_mem_rd_en		;
    logic 		[(DATA_WIDTH>>3)-1 :0]		byte_en_r		    ;
    logic 				                    sign_bit_r		    ;
    logic 		[1 :0] 		                fwd			        ;
    logic 				                    rs1_fwd_id_ex		;
    logic 				                    rs1_fwd_ex_mem		;
    logic 				                    rs1_fwd_mem_wb		;
    logic                                   ld_valid_o          ;
    logic                                   sd_valid_o          ;

    
    logic [GPR_ADDR_WIDTH-1:0] id_ex_rd_w;
    logic id_ex_reg_wr_en_w;
    logic id_ex_mem_rd_en_w;
    assign id_ex_rd_w = stall_pipeline ? {GPR_ADDR_WIDTH{1'b0}} : id_ex_rd;
    assign id_ex_reg_wr_en_w = stall_pipeline ? 1'b0 : id_ex_reg_wr_en;
    assign id_ex_mem_rd_en_w = (stall_pipeline & id_ex_mem_rd_en) ? 1'b0 : id_ex_mem_rd_en;
    

    always_ff@(posedge addr_clk or negedge addr_rst)
    begin
    	if(!addr_rst)
    	begin
    		addr 			    <=	{DATA_WIDTH{1'b0}}			    ;
    		ex_mem_rd		    <=	{GPR_ADDR_WIDTH{1'b0}}			;	
    		byte_en			    <=	{(DATA_WIDTH>>3){1'b0}}			;
    		sign_bit		    <=	1'b0			                ;
    		mem_wb_rd		    <=	{GPR_ADDR_WIDTH{1'b0}}			;
    		wb_rd			    <=	{GPR_ADDR_WIDTH{1'b0}}			;
    		ex_mem_reg_wr_en	<=	1'd0			                ;	
    		mem_wb_reg_wr_en	<=	1'd0			                ;
    		wb_reg_wr_en		<=	1'd0			                ;
    		ex_mem_mem_wr_en	<=	1'd0			                ;
    		ex_mem_mem_rd_en	<=	1'd0			                ;
    		mem_mem_wr_en		<=	1'd0			                ;
    		mem_mem_rd_en		<=	1'd0			                ;
            ld_valid            <=  1'b0                            ;
            sd_valid            <=  1'b0                            ;
    	end
    	else
    	begin
    		addr 			    <= 	addr_temp		    ;
    		ex_mem_rd		    <= 	id_ex_rd_w		    ;
    		byte_en 		    <= 	byte_en_r		    ;
    		sign_bit		    <= 	sign_bit_r		    ;
    		mem_wb_rd		    <= 	ex_mem_rd		    ;
    		wb_rd			    <= 	mem_wb_rd		    ;
    		ex_mem_reg_wr_en	<= 	id_ex_reg_wr_en_w	;
    		mem_wb_reg_wr_en	<= 	ex_mem_reg_wr_en	;
    		wb_reg_wr_en		<= 	mem_wb_reg_wr_en	;
    		ex_mem_mem_wr_en	<=	id_ex_mem_wr_en		;
    		ex_mem_mem_rd_en	<=	id_ex_mem_rd_en_w	;
    		mem_mem_wr_en		<=	ex_mem_mem_wr_en	;
    		mem_mem_rd_en		<=	ex_mem_mem_rd_en	;
            ld_valid            <=  ld_valid_o          ;
            sd_valid            <=  sd_valid_o          ;
    	end
    end

    assign rs1_fwd_id_ex 	= ((id_ex_rd !={GPR_ADDR_WIDTH{1'b0}}) && (id_ex_reg_wr_en  && (id_ex_mem_wr_en || id_ex_mem_rd_en)) && (id_ex_rd  == id_ex_rs1));
    assign rs1_fwd_ex_mem 	= ((ex_mem_rd!={GPR_ADDR_WIDTH{1'b0}}) && (ex_mem_reg_wr_en && (id_ex_mem_wr_en || id_ex_mem_rd_en)) && (ex_mem_rd == id_ex_rs1) && (id_ex_rd != id_ex_rs1));
    assign rs1_fwd_mem_wb 	= ((mem_wb_rd!={GPR_ADDR_WIDTH{1'b0}}) && (mem_wb_reg_wr_en && (id_ex_mem_wr_en || id_ex_mem_rd_en)) && (mem_wb_rd == id_ex_rs1) && (id_ex_rd != id_ex_rs1) && (ex_mem_rd != id_ex_rs1));
    
    always_comb
    begin
    	unique case({rs1_fwd_id_ex,rs1_fwd_ex_mem,rs1_fwd_mem_wb})
    	3'b100:
    	begin
    		fwd  	= 2'b01		;
    	end
    	3'b010:
    	begin
    		fwd 	= 2'b10		;
    	end
    	3'b001:
    	begin
    		fwd 	= 2'b11		;
    	end
    	default:
    	begin
    		fwd 	= 2'b00		;
    	end
    	endcase
    end
    
    always_comb
    begin
    	unique case(fwd)
    	2'b00:
    	begin
    		oper1 	= rs1_data	;
    		oper2 	= imm_val	;
    	end
    	2'b01:
    	begin
    		oper1 	= alu_data	;
    		oper2 	= imm_val	;
    	end
    	2'b10:
    	begin
    		oper1 	= mem_wb_data	;
    		oper2 	= imm_val	;
    	end
    	2'b11:
    	begin
    		oper1 	= wb_data	;
    		oper2 	= imm_val	;
    	end
    	default:
    	begin
    		oper1 	= rs1_data	;
    		oper2 	= imm_val	;
    	end
    	endcase
    end

    assign addr_temp = (ld_valid_o |sd_valid_o) ? (oper1 + oper2) : {DATA_WIDTH{1'b0}} ;

    always_comb
    begin
    	unique case(alu_ctrl)
    	12'b0000000_010_00://lw
    	begin
    		byte_en_r  = 4'b1111	; 
    		sign_bit_r = 1'b0		;
    		ld_valid_o 	= 1'b1		;
    		sd_valid_o 	= 1'b0		;
    		byte_sel_o 	= 2'b10		;
    	end
     	12'b0000000_110_00://sw
    	begin
    		byte_en_r   = 4'b1111   ;
    		sign_bit_r  = 1'b0		;
    		ld_valid_o 	= 1'b0		;
    		sd_valid_o 	= 1'b1		;
    		byte_sel_o 	= 2'b10		;
    	end
        12'b0000000_010_10://lwsp
        begin
    		byte_en_r   = 4'b1111   ;
    		sign_bit_r  = 1'b0		;
    		ld_valid_o 	= 1'b1		;
    		sd_valid_o 	= 1'b0		;
    		byte_sel_o 	= 2'b10		;
        end
        12'b0000000_110_10://swsp
        begin
    		byte_en_r   = 4'b1111   ;
    		sign_bit_r  = 1'b0		;
    		ld_valid_o 	= 1'b0		;
    		sd_valid_o 	= 1'b1		;
    		byte_sel_o 	= 2'b10		;
        end
    	default:
    	begin
    		byte_en_r  = 4'b0000	;
    		ld_valid_o 	= 1'b0		;
    		sd_valid_o 	= 1'b0		;
    		byte_sel_o 	= 2'b00		;
    		sign_bit_r 	= 1'b0		;
    	end
    	endcase    
    end
endmodule

