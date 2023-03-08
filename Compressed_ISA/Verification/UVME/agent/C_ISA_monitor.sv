class C_ISA_monitor extends uvm_monitor;

    // Factory registration
    `uvm_component_utils(C_ISA_monitor)

    // Creating interface and sequence item handle
    virtual C_ISA_inf intf; 

    // Analysis port to send transactions to the scoreboard
    uvm_analysis_port #(C_ISA_seq_item) analysis_port;

    // Constructor
    function new(string name = "C_ISA_monitor", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // Build phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
	if (!uvm_config_db#(virtual C_ISA_inf)::get(this, "*", "C_ISA_inf", intf)) begin
            `uvm_fatal(get_full_name(), "Error while getting read interface from top monitor")
        end
        analysis_port = new("analysis_port", this); // Initialize analysis port
    endfunction

    // Run phase (Captures transactions)
    task run_phase(uvm_phase phase);
        super.run_phase(phase);

    endtask

endclass
