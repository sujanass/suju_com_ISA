class C_ISA_env extends uvm_env;

  //factory registration
  `uvm_component_utils(C_ISA_env)

  //creating agent handle
  C_ISA_agent agent;
  //axi4_slave_cov_model cov_model;

  //constructor
  function new(string name = "C_ISA_env",uvm_component parent=null);
    super.new(name,parent);
  endfunction

  //build phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = C_ISA_agent::type_id::create("C_ISA_agent",this); 
  endfunction

  //connect phase
  function void connect_phase(uvm_phase phase);
  //connection between scoreboard and monitor
  endfunction

 
  
endclass
