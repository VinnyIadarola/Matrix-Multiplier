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
    input wire fetch_stall,
    input wire data_stall,
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
    wire insert;
    wire p;


    logic [1:0] PE_done;
    wire [ACCUM_WIDTH-1:0] PE_total;

    wire col_entry;





    /**********************************************************************
    ******                      Processing Element                   ******
    **********************************************************************/
    control_unit #(
        .N              (2),
        .M              (2)
    ) controller (
        // Basic Inputs
        .clk            (clk),
        .rst_n          (rst_n),

        // Control Inputs
        .start          (start),    
        .fetch_stall    (fetch_stall),
        .fifo_full      (fifo_full),
        .PE_ready       (PE_done),
        .data_stall     (data_stall),


        // Control Outputs
        .start_PE       (start_PE), // 1-cycle pulse when issuing work
        .done           (done), // latched high after completion until `start`
        .load_row       (load_row), // 1-cycle pulse to load the row into register
        .fetch_row      (fetch_row), // 1-cycle pulse when stall conditions clear
        .fetch_col      (fetch_col), // 1-cycle pulse when stall conditions clear
        .n              (n), // row index [0..N-1]
        .m              (m) // col index [0..M-1]
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

    assign col_entry = mem_buffer[p];


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
        .entry         (PE_total),
        // Control Inputs
        .insert        (insert),
        .pop           (pop_fifo),
        // no edge detection wizll activate every cycle

        //Data Outputs
        .head          (fifo_head),
        // Control Outputs
        .full          (fifo_full),
        .empty         (fifo_empty)
    );

    assign insert = PE_done[0] & ~PE_done[1];
    always_ff @(posedge clk, negedge rst_n)
        if (~rst_n)
            PE_done[1] <= '0;
        else 
            PE_done[1] <= PE_done[0];










endmodule
`default_nettype wire
