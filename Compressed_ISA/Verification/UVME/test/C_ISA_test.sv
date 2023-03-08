 class C_ISA_test extends uvm_test;

  //factory registration
  `uvm_component_utils(C_ISA_test)

  //creating environment and sequence handle
  C_ISA_env env_inst;
 // C_ISA_sequence seq_inst;
  
  //constructor
  function new(string name = "C_ISA_test",uvm_component parent=null);
    super.new(name,parent);
  endfunction
 
  //build phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env_inst = C_ISA_env::type_id::create("env_inst",this); 
 //   seq_inst = C_ISA_sequence::type_id::create("seq_inst"); 
  endfunction


//end of elaboration phase
	function void end_of_elaboration_phase(uvm_phase phase);
		uvm_top.print_topology();
	endfunction

task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    #100;
   `uvm_info(get_name(),$sformatf("inside the base test"),UVM_MEDIUM)
    phase.drop_objection(this);
  endtask

endclass 

