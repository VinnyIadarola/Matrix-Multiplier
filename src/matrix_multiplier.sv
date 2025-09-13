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

        input wire start,

        // Data Inputs
        input wire [DATA_WIDTH-1:0] row [0:N-1],
        input wire [DATA_WIDTH-1:0] col_entry,
        

        output logic head
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
        .load_row       (load_row),
        // load row[] into local buffer
        .start          (start_PE),
        // start one dot product

        // Data Inputs
        .row            (row),
        .col_entry      (col_entry),

        // Control Outputs
        .done           (PE_done),
        // 1-cycle pulse when the dot is done
        .err            (err),
        // Data Outputs
        .total          (total)
    );




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
        .entry         (entry),
        // Control Inputs
        .insert        (insert),
        .pop           (pop),
        // no edge detection wizll activate every cycle

        //Data Outputs
        .head          (head),
        // Control Outputs
        .full          (fifo_full),
        .empty         (empty)
    );









    endmodule