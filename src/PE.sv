`default_nettype none

module PE #(
    parameter int P           = 8,
    parameter int DATA_WIDTH  = 16,
    parameter int ACCUM_WIDTH = 2*DATA_WIDTH + 1,
    localparam int unsigned P_BIT_WIDTH = (P > 1) ? $clog2(P) : 1

) (
    // Basic Inputs
    input  wire                        clk,
    input  wire                        rst_n,

    // Control Inputs
    input  wire                        load_row,  // load row[] into local buffer
    input  wire                        start,     // start one dot product

    // Data Inputs
    input  wire signed [DATA_WIDTH-1:0] row [0:P-1],  // A[i,*]
    input  wire signed [DATA_WIDTH-1:0] col_entry,    // B[p,j] each cycle

    // Control Outputs
    output logic                       ready,      // held when the dot is ready
    output logic         [P_BIT_WIDTH-1:0] p,        // Row index for B and Col ndex for A
    output wire                        err,


    // Data Outputs
    output wire signed [ACCUM_WIDTH-1:0] total
);

    /**************************************************************************
    ***                               Declarations                          ***
    **************************************************************************/
    

    logic signed [DATA_WIDTH-1:0] row_buffer [0:P-1];

    logic             init;     // pulse at true start to clear accumulator

    typedef enum logic [1:0] {
        IDLE,
        COMPUTE,
        SYNC
    } pe_state;
    
    pe_state curr_state, next_state;


    logic set_ready;
    logic busy;   // high while consuming N beats


    /**************************************************************************
    ***                          General Assignments                        ***
    **************************************************************************/
    assign init = start & ~busy; 





    /**************************************************************************
    ***                           ready Flip flop                           ***
    **************************************************************************/
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n)
            ready <= '1;
        else if (init) 
            ready <= '0;
        else if (set_ready)
            ready <= '1;
    end




    /**************************************************************************
    ***                               Row Buffer                            ***
    **************************************************************************/
    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            for (int t = 0; t < P; t++) row_buffer[t] <= '0;
        end else if (load_row & ~busy) begin
            row_buffer <= row;
        end
    end

    /**************************************************************************
    ***                               Incrementor                           ***
    **************************************************************************/
    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n)
            p <= '0;
        else if (init) 
            p <= '0;
        else if (busy && p != P-1) 
            p <= p + 1'b1;           
    end
 
    /**************************************************************************
    ***                            State Machine                            ***
    **************************************************************************/
    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n)
            curr_state <= IDLE;
        else
            curr_state <= next_state;
    end

    always_comb begin
        next_state = curr_state;
        busy  = 1'b0;
        set_ready  = 1'b0;

        case (curr_state)
            IDLE: begin
                if (init) begin
                    set_ready  = 1'b0;
                    next_state = COMPUTE;
                end
            end
            COMPUTE: begin
                busy = 1'b1;                 // keep busy high through last valid pair
                if (p == P-1) begin
                    next_state = SYNC;       
                end
            end
            SYNC: begin
                set_ready  = 1'b1;           // total is now valid
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end



    /**************************************************************************
    ***                               Row Buffer                            ***
    **************************************************************************/
    wire run = busy | (curr_state == SYNC); // ensure final add in SYNC
    MAC #(
        .DATA_WIDTH  (DATA_WIDTH),
        .ACCUM_WIDTH (ACCUM_WIDTH)
    ) MAC (
        .rst_n (rst_n),
        .clk   (clk),
        .clr   (init),           
        .run   (run),       
        .in1   (row_buffer[p]),  // A[i,p] 
        .in2   (col_entry),      // B[p,j] 
        .total (total),
        .err   (err)
    );

endmodule

`default_nettype wire
