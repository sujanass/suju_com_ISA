class C_ISA_sequencer extends uvm_sequencer#(C_ISA_seq_item);

  //factory registration
  `uvm_component_utils(C_ISA_sequencer)

  //constructor
  function new(string name="C_ISA_sequencer",uvm_component parent=null);
   super.new(name,parent);
  endfunction
  
endclass
