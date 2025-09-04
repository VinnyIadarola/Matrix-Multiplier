`default_nettype none

module PE #(
    parameter int N           = 8,
    parameter int DATA_WIDTH  = 16,
    parameter int ACCUM_WIDTH = 2*DATA_WIDTH
) (
    // Basic Inputs
    input  wire                        clk,
    input  wire                        rst_n,

    // Control Inputs
    input  wire                        load_row,  // load row[] into local buffer
    input  wire                        start,     // start one dot product

    // Data Inputs
    input  wire signed [DATA_WIDTH-1:0] row [0:N-1],  // A[i,*]
    input  wire signed [DATA_WIDTH-1:0] col_entry,    // B[k,j] each cycle

    // Control Outputs
    output logic                       done,      // 1-cycle pulse when the dot is done
    output wire                        err,


    // Data Outputs
    output wire signed [ACCUM_WIDTH-1:0] total
);

    /**************************************************************************
    ***                               Declarations                          ***
    **************************************************************************/
    localparam int K_WIDTH = (N <= 1) ? 1 : $clog2(N); // 0-N-1
    logic [K_WIDTH-1:0] k;        // Row index for B and Col ndex for A

    logic signed [DATA_WIDTH-1:0] row_buffer [0:N-1];

    logic             init;     // pulse at true start to clear accumulator

    typedef enum logic [1:0] {
        IDLE,
        COMPUTE,
        SYNC,
        DONE
    } pe_state;
    
    pe_state curr_state, next_state;


    logic busy;   // high while consuming N beats


    /**************************************************************************
    ***                          General Assignments                        ***
    **************************************************************************/
    assign init = start & ~busy; 

    /**************************************************************************
    ***                               Row Buffer                            ***
    **************************************************************************/
    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            for (int t = 0; t < N; t++) row_buffer[t] <= '0;
        end else if (load_row) begin
            row_buffer <= row;
        end
    end

    /**************************************************************************
    ***                               Incrementor                           ***
    **************************************************************************/
    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n)
            k <= '0;
        else if (init) 
            k <= '0;
        else if (busy && k != N-1) 
            k <= k + 1'b1;           
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
        done  = 1'b0;

        case (curr_state)
            IDLE: begin
                if (init) begin
                    done       = 1'b0;
                    next_state = COMPUTE;
                end
            end
            COMPUTE: begin
                busy = 1'b1;                 // keep busy high through last valid pair
                if (k == N-1) begin
                    next_state = SYNC;       
                end
            end
            SYNC: begin
                next_state = DONE;
            end
            DONE: begin
                done       = 1'b1;           // total is now valid
                next_state = IDLE;
            end
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
        .in1   (row_buffer[k]),  // A[i,k] 
        .in2   (col_entry),      // B[k,j] 
        .total (total),
        .err   (err)
    );

endmodule

`default_nettype wire
