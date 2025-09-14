`default_nettype none

module control_unit #(
    parameter int unsigned N = 2,
    parameter int unsigned M = 2,

    localparam int unsigned N_BIT_WIDTH = (N > 1) ? $clog2(N) : 1,
    localparam int unsigned M_BIT_WIDTH = (M > 1) ? $clog2(M) : 1
) (
    // Basic Inputs
    input  wire                        clk,
    input  wire                        rst_n,

    // Run control
    input  wire                        start,        // assert to start a new run; clears latched `done`

    // Backpressure / readiness
    input  wire                        fetch_stall,
    input  wire                        fifo_full,
    input  wire                        PE_ready,
    input  wire                        data_stall,  

    // Control Outputs
    output logic                       start_PE,    // 1-cycle pulse when issuing work
    output logic                       done,        // latched high after completion until `start`
    output logic                       load_row,    // 1-cycle pulse to load the row into register
    output logic                       fetch_row,   // 1-cycle pulse when stall conditions clear
    output logic                       fetch_col,   // 1-cycle pulse when stall conditions clear
    output logic [N_BIT_WIDTH-1:0]     n,           // row index [0..N-1]
    output logic [M_BIT_WIDTH-1:0]     m            // col index [0..M-1]
);

    /**********************************************************************
    ******                         Declarations                      ******
    **********************************************************************/
    typedef enum logic [2:0] {
        IDLE,        // waiting for start
        FETCH_ROW,   // wait for stall conditions then pulse fetch
        PREP_ROW,    // pulse load when datas ready
        FETCH_COL,   // hold fetch_col for current column until allowed
        ISSUE_PE,    // 1-cycle pulse to PE
        ADVANCE,     // advance column counter, row counter, or end
        DONE         // wait for last PE to be done then stop
    } state_t;

    state_t curr_state, next_state;

    logic [N_BIT_WIDTH-1:0] n_nxt;
    logic [M_BIT_WIDTH-1:0] m_nxt;

    logic set_done;


    // convenience predicates
    logic last_row = (n == N-1);
    logic last_col = (m == M-1);

    // You can issue to PE if it’s ready and you aren’t stalled by output or inputs
    logic can_issue = (PE_ready & ~fifo_full & ~data_stall);





    /**********************************************************************
    ******                         Declarations                      ******
    **********************************************************************/
    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n)
            done <= 1'b0;
        else if (start)
            done <= 1'b0;
        else if (set_done)
            done <= 1'b1;
    end




    /**********************************************************************
    ******                       curr_state Machine                      ******
    **********************************************************************/
    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
           curr_state   <= IDLE;
            n       <= '0;
            m       <= '0;
        end else begin
           curr_state <= next_state;
            n     <= n_nxt;
            m     <= m_nxt;
        end
    end

    // Default outputs + next-state logic
    always_comb begin
        // hold values by default
        next_state = curr_state;
        n_nxt      = n;
        m_nxt      = m;

        start_PE   = 1'b0;
        load_row   = 1'b0;
        fetch_row  = 1'b0;
        fetch_col  = 1'b0;

        case (curr_state)
            IDLE: begin
                if (start) begin
                    n_nxt   = '0;
                    m_nxt   = '0;
                    next_state = FETCH_ROW;
                end
            end

            FETCH_ROW: begin
                // hold fetch_row until we’re allowed to pull the row
                if (~fetch_stall) begin
                    fetch_row = 1'b1;
                    next_state = PREP_ROW;
                end
            end

            PREP_ROW: begin
                //Wait until the data is ready to load
                if (~data_stall) begin
                    load_row  = 1'b1;
                    next_state   = FETCH_ROW;
                end
            end


            FETCH_COL: begin
                // Hold until we can grab the current cp;
                if (~fetch_stall) begin
                    fetch_col = 1'b1;
                    next_state = ISSUE_PE;
                end
            end

            ISSUE_PE: begin
                // wait until valid to start the PE again
                if (can_issue) begin
                    start_PE = 1'b1;
                    next_state  = ADVANCE;
                end
            end

            ADVANCE: begin
                if(last_row & last_col) begin
                    next_state = DONE;

                end else if (last_col) begin
                    m_nxt      = '0;
                    n_nxt      = n + 1'b1;
                    next_state = FETCH_ROW;

                end else begin 
                    m_nxt      = m + 1'b1;
                    next_state = FETCH_COL;
                end
            end

            DONE: begin
                if (PE_ready) begin
                    set_done = 1'b1;
                    next_state = IDLE;
                end
            end

            default: next_state = IDLE;
        endcase
    end
endmodule
