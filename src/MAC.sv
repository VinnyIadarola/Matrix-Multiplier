`default_nettype none

module MAC #(
    parameter DATA_WIDTH  = 16,
    parameter ACCUM_WIDTH = 2*DATA_WIDTH
) (
    // Basic Inputs
    input  wire                         rst_n,
    input  wire                         clk,

    // Control Inputs
    input  wire                         clr,
    input  wire                         running,
    
    // Data Inputs
    input  wire signed [DATA_WIDTH-1:0] in1,
    input  wire signed [DATA_WIDTH-1:0] in2,
    
    // Data Outputs 
    output logic signed [ACCUM_WIDTH-1:0] total,
    output logic                          err
);



    /**************************************************************************
    ***                            Declarations                             ***
    **************************************************************************/
    wire signed [2*DATA_WIDTH-1:0] product;
    logic signed [ACCUM_WIDTH-1:0] SExt_product;
    wire signed [ACCUM_WIDTH-1:0] new_total;



    /**************************************************************************
    ***                            Multiply Stage                           ***
    **************************************************************************/
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) 
            SExt_product <= '0;
        else if(running)
            SExt_product <= {{(ACCUM_WIDTH-(2*DATA_WIDTH)){product[2*DATA_WIDTH-1]}}, product};
        
    end

    assign product = in1 * in2;



    /**************************************************************************
    ***                            Accumulate Stage                         ***
    **************************************************************************/
    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n)
            total <= '0;
        else if (clr)
            total <= '0;
        else if (running)
            total <= new_total;
    end

    assign new_total = total + SExt_product;



    /**************************************************************************
    ***                          Overflow  Detection                         ***
    **************************************************************************/
    wire msb_total     = total[ACCUM_WIDTH-1];
    wire msb_addend  = SExt_product[ACCUM_WIDTH-1];
    wire msb_new     = new_total[ACCUM_WIDTH-1];
    wire same_sign   = ~(msb_total ^ msb_addend);
    wire ovf_next    = same_sign & (msb_new ^ msb_total);

    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n)
            err <= 1'b0;
        else if (clr)
            err <= 1'b0;
        else if (running)
            err <= err | ovf_next;
    end
endmodule
