class C_ISA_agent extends uvm_agent;
    //factory registration
    `uvm_component_utils(C_ISA_agent)

    //creating driver, monitor & sequencer handle
    C_ISA_driver driver;
    C_ISA_monitor monitor;
    C_ISA_sequencer seqr;

    //constructor
    function new (string name = "C_ISA_agent", uvm_component parent=null);
      super.new(name, parent);
    endfunction
    
    //build phase
    function void build_phase (uvm_phase phase);
      super.build_phase(phase);
      driver = C_ISA_driver::type_id::create("driver",this);
      monitor = C_ISA_monitor::type_id::create("monitor",this);
      seqr = C_ISA_sequencer::type_id::create("seqr",this);
    endfunction
    
    //connect phase
    function void connect_phase (uvm_phase phase);
      super.connect_phase(phase);
      driver.seq_item_port.connect(seqr.seq_item_export);
    endfunction

endclass

