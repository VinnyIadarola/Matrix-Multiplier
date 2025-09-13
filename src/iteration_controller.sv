`default_nettype none

module iteration_controller #(
    parameter N,
    parameter M
) (
    // Basic Inputs
    input wire clk,
    input wire rst_n,

    // Control Inputs
    input wire start,
    input wire mem_stall,
    input wire fifo_full,
    input wire PE_ready,

    //Control Outputs
    output logic start_PE,
    output logic done,
    output logic load_row
);
    
    localparam N_BIT_WIDTH = (N > 0) ? $clog2(N) : 1;
    localparam M_BIT_WIDTH = (M > 0) ? $clog2(M) : 1;



    /**********************************************************************
    ******                         Declarations                      ******
    **********************************************************************/
    wire init;
    logic busy;
    logic set_done;

    logic [N_BIT_WIDTH-1:0] n; 
    logic [M_BIT_WIDTH-1:0] m;


    typedef enum logic[1:0] {IDLE, COLS, LOAD_ROW} state_t;
    state_t curr_state, next_state;

    /**********************************************************************
    ******                      General Assignments                  ******
    **********************************************************************/

    assign init = start & ~mem_stall & ~fifo_full & ~busy;


    assign start_PE = (PE_ready) & (curr_state == COLS) & ~(mem_stall | fifo_full);
 



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
        set_done  = 1'b0;
        load_row = 1'b0;

        case (curr_state)
            IDLE: begin
                if (init) begin
                    set_done  = 1'b0;

                    load_row = 1'b1;
                    next_state = COLS;
                end
            end
            COLS: begin
                busy = 1'b1; 
             
                if (m == M-1) begin //iterated through all columns next row
                    next_state = LOAD_ROW;  

                    if (n == N-1) begin
                        set_done  = 1'b1;           
                        next_state = IDLE;
                    end  
                end
            end
            LOAD_ROW: begin
                busy = 1'b1;                
                if (~mem_stall) begin
                    next_state = COLS;
                    load_row = 1'b1;
                end

            end     
            default: next_state = IDLE;
        endcase
    end





    /**************************************************************************
    ***                               Incrementors                          ***
    **************************************************************************/
    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n)
            n <= '0;
        else if (init) 
            n <= '0;
        else if (load_row & n != N-1) 
            n <= n + 1'b1;           
    end



    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n)
            m <= '0;
        else if (init | load_row) 
            m <= '0;
        else if (start_PE & m != M-1) 
            m <= m + 1'b1;           
    end
    


    
    /**************************************************************************
    ***                               DOne latch                          ***
    **************************************************************************/
    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n)
            done <= '0;
        else if (init) 
            done <= '0;
        else if (set_done) 
            done <= 1'b1;           
    end
    
    




endmodule      

`default_nettype wire