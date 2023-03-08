module C_ISA_top;

  import uvm_pkg::*;
  import C_ISA_pkg::*;

  `include "uvm_macros.svh"

  //clock and reset signal declaration
    bit risc_clk;

//creatinng instance of interface, in order to connect DUT and testcase
  C_ISA_inf intf(risc_clk);
  
  //DUT instance, interface signals are connected to the DUT ports
  riscv_top dut (
    .risc_clk(intf.risc_clk),
    //.reset(intf.reset),
    .risc_rst(intf.risc_rst),
    .data_write_en_o(intf.data_write_en_o),
    .data_write_data_o(intf.data_write_data_o),
    .data_write_addr_o(intf.data_write_addr_o),
    .data_read_en_o(intf.data_read_en_o),
    .data_read_addr_o(intf.data_read_addr_o),
    .id_ex_mem_data(intf.id_ex_mem_data),
    .carry(intf.carry),
    .zero(intf.zero)
   );

  //clock generation
  initial begin 
  risc_clk=1'b1;
  forever begin
  #5 risc_clk = ~risc_clk;
  end
  end

  //set interface in config_db 
  initial begin 
    uvm_config_db#(virtual C_ISA_inf)::set(null,"*","C_ISA_inf",intf);
  end
  
// Waveform Dumping 
  initial begin
    $shm_open("wave.shm");  // Open SHM database
    $shm_probe("AS");        // Probe all signals (A=All, )
  end

  initial begin 
    run_test("C_ISA_test");
    uvm_top.set_report_verbosity_level(UVM_HIGH);
  end
endmodule  
