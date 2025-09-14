import testing_pkg::*;

/**************************************************************************
***                            Testbench Top                             ***
**************************************************************************/
module matrix_mult_tb();

/**************************************************************************
***                                Params                                ***
**************************************************************************/
parameter int N = 2;
parameter int M = 2;

/**************************************************************************
***                             Declarations                             ***
**************************************************************************/
// Basic Inputs
logic clk;
logic rst_n;

// Control Inputs
logic start;
logic mem_stall;
logic fifo_full;
logic PE_ready;

// Control Outputs
logic start_PE;
logic done;
logic load_row;

int i, j;

/**************************************************************************
***                        Devices Under Testing                         ***
**************************************************************************/
matrix_multiplier #(
    .N              (2),
    .P              (2),
    .M              (2),
    .DATA_WIDTH     (8),
    .ACCUM_WIDTH    (2*DATA_WIDTH),
    .FIFO_SIZE      (4)
) u_matrix_multiplier (
    // Basic Inputs
    .clk            (clk),
    .rst_n          (rst_n),
    // Control Inputs
    .mem_stall      (mem_stall),
    .pop_fifo       (pop_fifo),
    .start          (start),
    // Data Inputs
    .mem_buffer     (mem_buffer),
    // Control Outputs
    .n              (n),
    .m              (m),
    .fetch_row      (fetch_row),
    .fetch_col      (fetch_col),
    .fifo_head      (fifo_head),
    .fifo_empty     (fifo_empty),
    .fifo_full      (fifo_full),
    .done           (done),
    .err            (err)
);




rom_model #(
    .DATA_WIDTH      (8),
    .LINE_LEN        (2),
    // number of words per "line" (output array length)
    .MEM_DEPTH       (256),
    // ROM depth (words)
    .MAX_STALL       (5),
    // max random stall cycles between line grabs
    // optional $readmemh file
    .MEMFILE         ("init_mem_8bit.hex")
) u_rom_model (
    .clk             (clk),
    .rst_n           (rst_n),
    
    // Request to grab a line into the output array register; honored only when ready=1
    .fetch           (fetch_col | fetch_row),
    
    // If addr_use_ext==1 during an accepted fetch, addr_ext is the starting ROM address.
    .addr_use_ext    (1'b1),
    .addr_ext        (addr_ext),


    
    // Status / visibility
    .ready           (ready),
    // can accept fetch this cycle
    .line_valid      (line_valid),
    // 1-cycle pulse when line_out is updated
    .used_addr       (used_addr),
    // start addr used for the most recent line

    // Output array register: LINE_LEN words wide
    .line_out        (line_out)
);






/**************************************************************************
***                                 Clock                               ***
**************************************************************************/
always #5 clk = ~clk;





/**************************************************************************
***                               Test Plan                              ***
**************************************************************************/
initial begin


    print_all_passed_banner();
end

endmodule
