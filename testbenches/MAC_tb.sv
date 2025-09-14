import testing_pkg::*;

module MAC_tb();
    

parameter int DATA_WIDTH = 8;
typedef logic signed [DATA_WIDTH-1:0] data_t;

localparam int ACCUM_WIDTH = 2*DATA_WIDTH;
typedef logic signed [ACCUM_WIDTH-1:0] accum_t;


// Testbench Inputs
logic rst_n;
logic clk;
logic clr;
logic run;
logic signed [7:0] in1;
logic signed [7:0] in2;

// Testbench Outputs
logic signed [15:0] total;
logic err;

/**************************************************************************
***                            Test Suite 1                             ***
**************************************************************************/
MAC #(
    .DATA_WIDTH     (8),
    .ACCUM_WIDTH    (2*DATA_WIDTH)
) iDUT (
    // Basic Inputs
    .rst_n          (rst_n),
    .clk            (clk),
    // Control Inputs
    .clr            (clr),
    .run        (run),
    // Data Inputs
    .in1            (in1),
    .in2            (in2),
    
    // Data Outputs 
    .total          (total),
    .err            (err)
);

always #5 clk = ~clk;

initial begin
    //Settng to defaults
    clk = 1'b1;
    rst_n = 1'b0;

    clr = 1'b0;
    run = 1'b0;
    
    in1 = '1;
    in2 = '1;

    // Test 1: Ensure all values stay default
    checkValues16(
        .refclk(clk),                // clock signal
        .sig2watch(total),           // signal to watch
        .goal_value(16'h0000),       // expected value
        .clks2wait(100),             // cycles to wait
        .testnum(1),                 // test number
        .valHold(1'b1)               // hold value
    );

    // Test 2: Step through each value 
    @(posedge clk);
    rst_n = 1'b1;
    clr = 1'b0;
    run = 1'b0;
    in1 = 8'h01;
    in2 = 8'h01;

   fork
        begin
            repeat(2) @(negedge clk);
            run = 1'b0;
        end
        checkValues16(
            .refclk(clk),                // clock signal
            .sig2watch(total),           // signal to watch
            .goal_value(16'h0000),       // expected value
            .clks2wait(100),             // cycles to wait
            .testnum(2),                 // test number
            .valHold(1'b1)               // hold value
        );
   join 

    // Test 3: check if we hold our value after one accumulation
    @(negedge clk);
    clr = 1'b0;
    run = 1'b1;
    in1 = 8'h01;
    in2 = 8'h01;


    fork
        begin
            repeat(2) @(negedge clk);
            run = 1'b0;
        end

        checkValues16(
            .refclk(clk),                // clock signal
            .sig2watch(total),           // signal to watch
            .goal_value(16'h0001),       // expected value
            .clks2wait(20),              // cycles to wait
            .testnum(3),                 // test number
            .valHold(1'b1)               // hold value
        );
    join


    // Test 4: Ensure clr sets system back to 0
    @(negedge clk);
    clr = 1'b1;
    run = 1'b0;
    in1 = 8'h01;
    in2 = 8'h01;

    checkValues16(
        .refclk(clk),                // clock signal
        .sig2watch(total),           // signal to watch
        .goal_value(16'h0000),       // expected value
        .clks2wait(1),               // cycles to wait
        .testnum(4),                 // test number
        .valHold(1'b1)               // hold value
    );

    @(negedge clk);
    clr = 1'b0;

    checkValues16(
        .refclk(clk),                // clock signal
        .sig2watch(total),           // signal to watch
        .goal_value(16'h0000),       // expected value
        .clks2wait(20),              // cycles to wait
        .testnum(4),                 // test number
        .valHold(1'b1)               // hold value
    );

    // Test 5: Step through each value 
    @(negedge clk);
    clr = 1'b0;
    run = 1'b1;
    in1 = 8'h01;
    in2 = 8'h01;


    fork
        begin        
            repeat(90) @(negedge clk);
            run = 1'b0;
        end

    checkValues16(
        .refclk(clk),                // clock signal
        .sig2watch(total),           // signal to watch
        .goal_value(89),          // expected value 
        .clks2wait(100),              // cycles to wait
        .testnum(5),                 // test number
        .valHold(1'b1)               // hold value
    );

    join






    /**********************************************************************
    ******                  Overflow edge cases                      ******
    **********************************************************************/

    // Test 6: Positive overflow quickly: (-128 * -128) = 16384; 2 adds overflow
    @(negedge clk);
    clr = 1'b1; 
    @(negedge clk); 
    clr = 1'b0;
    run = 1'b1;
    in1 = -128;
    in2 = -128;
    
    checkValues1(
        .refclk(clk),
        .sig2watch(err),
        .clks2wait(4),
        .testnum(6),

        .valHold(1'b1),
        .goal_value(1'b1)
    );
    run = 1'b0;

    // Test 7: Positive overflow: (127 * 127) = 16129; 3 adds overflow
    @(negedge clk);
    clr = 1'b1; 
    @(negedge clk); 
    clr = 1'b0;

    checkValues1(
        .refclk(clk),
        .sig2watch(err),
        .clks2wait(5),
        .testnum(7.1),

        
        .valHold(1'b1),
        .goal_value(1'b0)
    );



    run = 1'b1;
    in1 = 8'sd127;
    in2 = 8'sd127;
    checkValues1(
        .refclk(clk),
        .sig2watch(err),
        .clks2wait(5),
        .testnum(7),

        
        .valHold(1'b1),
        .goal_value(1'b1)
    );
    run = 1'b0;

    // Test 8: Negative overflow: (-128 * 127) = -16256; 3 adds overflow (underflow)
    @(negedge clk);
    clr = 1'b1; @(negedge clk); clr = 1'b0;
    run = 1'b1;
    in1 = -128;
    in2 = 8'sd127;
    checkValues1(
        .refclk(clk),
        .sig2watch(err),
        .clks2wait(5),
        .testnum(8),

        
        .valHold(1'b1),
        .goal_value(1'b1)
    );
    run = 1'b0;


print_all_passed_banner();


    
end
endmodule
