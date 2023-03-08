class C_ISA_seq_item extends uvm_sequence_item;

rand logic risc_clk;
 
 //factory registration
 `uvm_object_utils_begin(C_ISA_seq_item)
 `uvm_field_int(risc_clk        ,UVM_ALL_ON)

 `uvm_object_utils_end


 //constructor
  function new(string name="C_ISA_seq_item");
   super.new(name);
  endfunction

endclass
