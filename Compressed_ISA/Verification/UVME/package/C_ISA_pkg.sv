package C_ISA_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "./../UVME/sequence/C_ISA_seq_item.sv"
    `include "./../UVME/agent/C_ISA_driver.sv"
    `include "./../UVME/agent/C_ISA_monitor.sv"
    `include "./../UVME/agent/C_ISA_sequencer.sv"
    `include "./../UVME/agent/C_ISA_agent.sv"
    //`include "./../UVME/env/C_ISA_scoreboard.sv"
    `include "./../UVME/env/C_ISA_env.sv"
    //`include "./../UVME/sequence/C_ISA_sequence.sv"
    `include "./../UVME/test/C_ISA_test.sv"
    
endpackage
