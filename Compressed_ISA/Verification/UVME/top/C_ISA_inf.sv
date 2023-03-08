interface c_ISA_inf(input bit risc_clk);
	//inputs
//	logic risc_clk,
	logic risc_rst,
	logic [15:0] instruction,
//	logic [31:0] data_mem_read_data,

	//outputs
	logic data_mem_write_en_o,
	logic [31:0] data_mem_write_data_o,
	logic [31:0] data_mem_write_addr_o,
	logic data_mem_read_en_o,
	logic [31:0] data_mem_read_addr_o,
	logic [31:0] id_ex_mem_rd_en,
	logic carry,
	logic zero,

clocking driver_cb @(negedge clk);
output risc_rst;
output instruction;

input data_mem_write_en_o;
input data_mem_write_data_o;
input data_mem_write_addr_o;
input data_mem_read_en_o,
input data_mem_read_addr_o,
input id_ex_mem_rd_en,
input carry,
input zero,


endclocking

endinterface
