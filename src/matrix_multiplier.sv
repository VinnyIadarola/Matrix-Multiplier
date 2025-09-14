    `default_nettype none

module matrix_multiplier #(
    parameter N           = 8,
    parameter P           = 9,
    parameter M           = 10,
    parameter DATA_WIDTH  = 16,
    parameter ACCUM_WIDTH = 2*DATA_WIDTH,
    parameter FIFO_SIZE   = 20
) (
    // Basic Inputs
    input wire clk,
    input wire rst_n,

    // Control Inputs
    input wire mem_stall,
    input wire pop_fifo,

    input wire start,

    // Data Inputs
    input wire [DATA_WIDTH-1:0] mem_buffer [0:N-1],
    

    // Control Outputs
    output wire n,
    output wire m,
    output wire fetch_row,
    output wire fetch_col,
    output wire [DATA_WIDTH-1:0] fifo_head,
    output wire fifo_empty,
    output wire fifo_full,
    output wire done,
    output wire err
);
        

    
    /**********************************************************************
    ******                     General Declarations                  ******
    **********************************************************************/
    wire start_PE;
    wire load_row;
   


    wire PE_done[0:1];
    wire [ACCUM_WIDTH-1:0] PE_total;






    /**********************************************************************
    ******                      Processing Element                   ******
    **********************************************************************/
    control_unit #(
        .N              (N),
        .M              (M)
    ) controller (
        // Basic Inputs
        .clk            (clk),
        .rst_n          (rst_n),

        // Control Inputs
        .start          (start),
        .mem_stall      (mem_stall),
        .fifo_full      (fifo_full),
        .PE_ready       (PE_done),

        //Control Outputs
        .start_PE       (start_PE),
        .done           (done),
        .load_row       (load_row),
        .fetch_row      (fetch_row),
        .fetch_col      (fetch_col),
        .n              (n),
        .m              (m)
    );



    /**********************************************************************
    ******                      Processing Element                   ******
    **********************************************************************/
    PE #(
        .N              (8),
        .DATA_WIDTH     (16),
        .ACCUM_WIDTH    (2*DATA_WIDTH)
    ) PE (
        // Basic Inputs
        .clk            (clk),
        .rst_n          (rst_n),

        // Control Inputs
        .load_row       (load_row), // load row[] into local buffer
        .start          (start_PE), // start one dot product

        // Data Inputs
        .row            (mem_buffer),
        .col_entry      (col_entry),

        // Control Outputs
        .done           (PE_done[0]), // 1-cycle pulse when the dot is done
        .err            (err),
        .p              (p),

        // Data Outputs
        .total          (PE_total)
    );


    wire col_entry = mem_buffer[p];


    /**********************************************************************
    ******                         Output Queue                      ******
    **********************************************************************/
    ring_buffer #(
        .DATA_WIDTH    (N),
        .FIFO_SIZE     (FIFO_SIZE)
    ) ring_buffer (
        // Basic Inputs
        .clk           (clk),
        .rst_n         (rst_n),
        // Data Inputs
        .entry         (PE_toal),
        // Control Inputs
        .insert        (insert),
        .pop           (pop),
        // no edge detection wizll activate every cycle

        //Data Outputs
        .head          (fifo_head),
        // Control Outputs
        .full          (fifo_full),
        .empty         (empty)
    );

    wire insert = PE_done[0] & ~PE_done[1];
    always_ff @(posedge clk, negedge rst_n)
        if (~rst_n)
            PE_done[1] <= '0;
        else 
            PE_done[1] <= PE_done[2];










endmodule
`default_nettype wire
