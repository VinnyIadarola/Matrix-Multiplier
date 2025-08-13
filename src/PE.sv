`default_nettype none

module PE #(
    parameter N            = 8,
    parameter DATA_WIDTH   = 16,
    parameter ACCUM_WIDTH  = 2*DATA_WIDTH
) (
    // Basic Inputs
    input  wire                                rst_n,
    input  wire                              clk,

    // Control Inputs
    input  wire logic                               init,

    // Data Inputs
    input  wire signed [DATA_WIDTH-1:0] row [0:N-1],
    input  wire signed [DATA_WIDTH-1:0] col [0:N-1],

    // Data Outputs 
    output wire signed  [ACCUM_WIDTH-1:0] total,
    output wire                          rdy,
    output wire                          err
);

    localparam INC_WIDTH = $clog2(N);
    logic running;
    logic clr;


    /**************************************************************************
    ***                            MOEW                             ***
    **************************************************************************/
    logic signed [DATA_WIDTH-1:0]row_shift_reg[0:N-1];
    logic signed [DATA_WIDTH-1:0]col_shift_reg[0:N-1];
    

   always_ff @(posedge clk) 
        if (init) begin
            row_shift_reg <= row;       
            col_shift_reg <= col;
        end 
        else if (running) begin
            for (int i = 0; i < N - 1; i++) begin
                row_shift_reg[i] <= row_shift_reg[i+1];
                col_shift_reg[i] <= col_shift_reg[i+1];
            end
            row_shift_reg[N-1] <= '0;
            col_shift_reg[N-1] <= '0;
         end

    


    
    /**************************************************************************
    ***                           MAC Instantiation                         ***
    **************************************************************************/
    MAC #(
        .DATA_WIDTH  (DATA_WIDTH),
        .ACCUM_WIDTH (ACCUM_WIDTH)
    ) MAC (
        // Basic Inputs
        .rst_n       (rst_n),
        .clk         (clk),

        // Control Inputs
        .clr         (clr),
        .running     (running),

        // Data Inputs
        .in1         (row_shift_reg[0]), //taking the 0th element of the array
        .in2         (col_shift_reg[0]),
        
        // Data Outputs 
        .total       (total),
        .err         (err)
    );



    /**************************************************************************
    ***                               Incrementorr                          ***
    **************************************************************************/
    reg [INC_WIDTH:0] cycles;
    
    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n) 
            cycles <= '0; //TODO see if u can remove this later as im worried about unknows
        else if (clr)
            cycles <= '0;
        else if (running)
            cycles <= cycles + 1'b1;
    end
        
    /**************************************************************************
    ***                              State Machine                          ***
    **************************************************************************/
    typedef enum reg {IDLE, RUN} STATE_t;
    STATE_t curr_state, next_state;

    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n) 
            curr_state <= IDLE;
        else 
            curr_state <= next_state; 
    end

    always_comb begin
        next_state = curr_state;
        running = 1'b0;
        clr = 1'b0;
        

        case (curr_state) 
            IDLE : 
                if (init) begin
                    clr = 1'b1;
                    next_state = RUN;
                end
            RUN : begin
                running = 1'b1;

                if (cycles == N) begin
                    next_state = IDLE;
                end 
            end

        endcase
    end



endmodule
`default_nettype wire
