class C_ISA_sequence extends uvm_sequence#(C_ISA_seq_item);

  //factory registration
  `uvm_object_utils(C_ISA_sequence)

  //creating sequence item handle
  C_ISA_seq_item C_ISA_seq_inst;

  int scenario;

  //constructor
  function new(string name="C_ISA_sequence");
   super.new(name);
  endfunction

  //build phase
  function void build_phase(uvm_phase phase);
    //super.build_phase(phase);
   C_ISA_seq_inst = C_ISA_seq_item::type_id::create("C_ISA_seq_inst");
  endfunction
  
  //task body
  task body();

    //reset scenario
    if(scenario == 1)
        begin
        repeat(20)
        begin
        `uvm_do_with(C_ISA_seq_inst,{C_ISA_seq_inst.RST == 0;}) 
     //   `uvm_do_with(C_ISA_seq_inst,{C_ISA_seq_inst.RST == 1;})
                    
        end
        end
     
    /* if(scenario==2)
        begin
        `uvm_do_with(C_ISA_seq_inst,{C_ISA_seq_inst.RST==0;C_ISA_seq_inst.soft_RST==0;C_ISA_seq_inst.stat_en==1;C_ISA_seq_inst.full_mem_clr==1;C_ISA_seq_inst.inc_vec==0;})//Clearing all the locations
        
        repeat(30)
        begin
        `uvm_do_with(C_ISA_seq_inst,{C_ISA_seq_inst.RST==1;C_ISA_seq_inst.soft_RST==1;C_ISA_seq_inst.stat_en==0;C_ISA_seq_inst.full_mem_clr==1;C_ISA_seq_inst.partial_mem_clr==0;C_ISA_seq_inst.individual_mem_clr==0;C_ISA_seq_inst.inc_vec==0;})//Clearing all the locations
        end
        end */

  endtask

endclass
