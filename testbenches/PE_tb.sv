import testing_pkg::*;
module PE_tb();

    /**************************************************************************
    ***                               Instantiations                         ***
    **************************************************************************/
    // Parameters
    localparam   N           = 2;
    localparam   DATA_WIDTH  = 4;
    localparam   ACCUM_WIDTH = 2 * DATA_WIDTH;

    // Signals
    logic        rst_n;
    logic        clk;
    logic        init;
    logic signed [DATA_WIDTH-1:0]  row [0:N-1];
    logic signed [DATA_WIDTH-1:0]  col [0:N-1];
    logic signed [ACCUM_WIDTH-1:0] total;
    logic        rdy;
    logic        err;

    // Second Instance (renamed to use "3")
    localparam   N3          = 3;

    logic        rst_n3;
    logic        init3;
    logic signed [DATA_WIDTH-1:0]  row3 [0:N3-1];
    logic signed [DATA_WIDTH-1:0]  col3 [0:N3-1];
    logic signed [ACCUM_WIDTH-1:0] total3;
    logic        rdy3;
    logic        err3;

    // Third Instance (N=10, DATA_WIDTH=3)
    localparam   N10             = 10;
    localparam   DATA_WIDTH10    = 3;
    localparam   ACCUM_WIDTH10   = 2 * DATA_WIDTH10;

    logic        rst_n10;
    logic        init10;
    logic signed [DATA_WIDTH10-1:0]  row10 [0:N10-1];
    logic signed [DATA_WIDTH10-1:0]  col10 [0:N10-1];
    logic signed [ACCUM_WIDTH10-1:0] total10;
    logic        rdy10;
    logic        err10;

    /**************************************************************************
    ***                            Devices Under Testing                     ***
    **************************************************************************/
    PE #(
        .N              (N),
        .DATA_WIDTH     (DATA_WIDTH),
        .ACCUM_WIDTH    (ACCUM_WIDTH)
    ) iDUT (
        // Basic Inputs
        .rst_n          (rst_n),
        .clk            (clk),
        // Control Inputs
        .init           (init),
        // Data Inputs
        .row            (row),
        .col            (col),

        // Data Outputs 
        .total          (total),
        .rdy            (rdy),
        .err            (err)
    );

    PE #(
        .N              (N3),
        .DATA_WIDTH     (DATA_WIDTH),
        .ACCUM_WIDTH    (ACCUM_WIDTH)
    ) iDUT3 (
        // Basic Inputs
        .rst_n          (rst_n3),
        .clk            (clk),
        // Control Inputs
        .init           (init3),
        // Data Inputs
        .row            (row3),
        .col            (col3),

        // Data Outputs 
        .total          (total3),
        .rdy            (rdy3),
        .err            (err3)
    );

    PE #(
        .N              (N10),
        .DATA_WIDTH     (DATA_WIDTH10),
        .ACCUM_WIDTH    (ACCUM_WIDTH10)
    ) iDUT10 (
        // Basic Inputs
        .rst_n          (rst_n10),
        .clk            (clk),
        // Control Inputs
        .init           (init10),
        // Data Inputs
        .row            (row10),
        .col            (col10),

        // Data Outputs 
        .total          (total10),
        .rdy            (rdy10),
        .err            (err10)
    );

    always #5 clk = ~clk;

    /**************************************************************************
    ***                                Test Suites                          ***
    **************************************************************************/
    initial begin
        clk = 0;


    /****************************
    ***          N = 2        ***
    ****************************/

        // Test 2.1: Reset keeps total on 0
        rst_n = 1'b0;

        checkValues8(
            .refclk(clk),
            .sig2watch(total),
            .clks2wait(5),
            .valHold(1'b1),
            .goal_value(0),
            .testnum(2.1)
        );

        // Test 2.2: Testing all positives 
        @(posedge clk);
        rst_n = 1'b1;

        @(negedge clk);
        row = {1, 1};
        col = {2, 3};
        init = 1'b1;

        fork
            begin
                checkValues8(
                    .refclk(clk),
                    .sig2watch(total),
                    .clks2wait(2),
                    .valHold(1'b1),
                    .goal_value(5),
                    .testnum(2.2)
                );
            end
            begin
                @(negedge clk);
                init = 1'b0;
            end
        join

        // Test 2.3: clears properly then negatives
        @(negedge clk);
        row = {1, 1};
        col = {-2, -3};
        init = 1'b1;

        fork
            begin
                checkValues8(
                    .refclk(clk),
                    .sig2watch(total),
                    .clks2wait(2),
                    .valHold(1'b1),
                    .goal_value(-5),
                    .testnum(2.3)
                );
            end
            begin
                @(negedge clk);
                init = 1'b0;
            end
        join

        // Test 2.4: both negatives → positive
        @(negedge clk);
        row = {-1, -1};
        col = {-2, -3};
        init = 1'b1;

        fork
            begin
                checkValues8(
                    .refclk(clk),
                    .sig2watch(total),
                    .clks2wait(2),
                    .valHold(1'b1),
                    .goal_value(5),
                    .testnum(2.4)
                );
            end
            begin
                @(negedge clk);
                init = 1'b0;
            end
        join


        // Test 2.5: zeros anywhere should yield 0
        @(negedge clk);
        row = {0, 0};
        col = {7, -8};
        init = 1'b1;

        fork
            begin
                checkValues8(
                    .refclk(clk),
                    .sig2watch(total),
                    .clks2wait(2),
                    .valHold(1'b1),
                    .goal_value(0),
                    .testnum(2.5)
                );
            end
            begin
                @(negedge clk);
                init = 1'b0;
            end
        join

        // Test 2.6: mixed signs cancel (7*1 + (-7)*1 = 0)
        @(negedge clk);
        row = {7, -7};
        col = {1, 1};
        init = 1'b1;

        fork
            begin
                checkValues8(
                    .refclk(clk),
                    .sig2watch(total),
                    .clks2wait(2),
                    .valHold(1'b1),
                    .goal_value(0),
                    .testnum(2.6)
                );
            end
            begin
                @(negedge clk);
                init = 1'b0;
            end
        join

        // Test 2.7: max-magnitude negative sum (no overflow): -112
        @(negedge clk);
        row = {-8, -8};
        col = {7, 7};
        init = 1'b1;

        fork
            begin
                checkValues8(
                    .refclk(clk),
                    .sig2watch(total),
                    .clks2wait(2),
                    .valHold(1'b1),
                    .goal_value(-112),
                    .testnum(2.7)
                );
                checkValues1(
                    .refclk(clk),
                    .sig2watch(err),
                    .clks2wait(2),
                    .valHold(1'b1),
                    .goal_value(1'b0),
                    .testnum(2.71) // subtest of 2.7
                );
            end
            begin
                @(negedge clk);
                init = 1'b0;
            end
        join

        // Test 2.8: positive overflow (128) -> overflow
        @(negedge clk);
        row = {-8, -8};
        col = {-8, -8};
        init = 1'b1;

        fork
            begin
                checkValues1(
                    .refclk(clk),
                    .sig2watch(err),
                    .clks2wait(2),
                    .valHold(1'b1),
                    .goal_value(1'b1),
                    .testnum(2.8)
                );
            end
            begin
                @(negedge clk);
                init = 1'b0;
            end
        join

        // Test 2.9: overflow flag HOLDS until init
        @(negedge clk);
        row = {1, 1};
        col = {1, 1};

        checkValues1(
            .refclk(clk),
            .sig2watch(err),
            .clks2wait(2),
            .valHold(1'b1),
            .goal_value(1'b1),
            .testnum(2.9)
        );

        // Test 2.10: init clears overflow; math resumes (sum=2)
        @(negedge clk);
        init = 1'b1;

        fork
            begin
                checkValues1(
                    .refclk(clk),
                    .sig2watch(err),
                    .clks2wait(1),
                    .valHold(1'b1),
                    .goal_value(1'b0),
                    .testnum(2.10)
                );

                checkValues8(
                    .refclk(clk),
                    .sig2watch(total),
                    .clks2wait(2),
                    .valHold(1'b1),
                    .goal_value(2),
                    .testnum(2.101) // subtest of 2.10
                );
            end
            begin
                @(negedge clk);
                init = 1'b0;
            end
        join

        // Test 2.11: sign extremes without overflow = -15
        @(negedge clk);
        row = {-8, 7};
        col = {1, -1};
        init = 1'b1;

        fork
            begin
                checkValues8(
                    .refclk(clk),
                    .sig2watch(total),
                    .clks2wait(2),
                    .valHold(1'b1),
                    .goal_value(-15),
                    .testnum(2.11)
                );
                checkValues1(
                    .refclk(clk),
                    .sig2watch(err),
                    .clks2wait(2),
                    .valHold(1'b1),
                    .goal_value(1'b0),
                    .testnum(2.111) // subtest of 2.11
                );
            end
            begin
                @(negedge clk);
                init = 1'b0;
            end
        join




        /****************************
        ***          N = 3        ***
        ****************************/

        // Test 3.1: Reset keeps total3 on 0
        rst_n3 = 1'b0;

        checkValues8(
            .refclk(clk),
            .sig2watch(total3),
            .clks2wait(5),
            .valHold(1'b1),
            .goal_value(0),
            .testnum(3.1)
        );

        // Test 3.2: all positives (1*2+1*3+1*4=9)
        @(posedge clk);
        rst_n3 = 1'b1;

        @(negedge clk);
        row3 = {1, 1, 1};
        col3 = {2, 3, 4};
        init3 = 1'b1;

        fork
            begin
                checkValues8(
                    .refclk(clk),
                    .sig2watch(total3),
                    .clks2wait(3),
                    .valHold(1'b1),
                    .goal_value(9),
                    .testnum(3.2)
                );
            end
            begin
                @(negedge clk);
                init3 = 1'b0;
            end
        join

        // Test 3.3: negatives = -9
        @(negedge clk);
        row3 = {1, 1, 1};
        col3 = {-2, -3, -4};
        init3 = 1'b1;

        fork
            begin
                checkValues8(
                    .refclk(clk),
                    .sig2watch(total3),
                    .clks2wait(3),
                    .valHold(1'b1),
                    .goal_value(-9),
                    .testnum(3.3)
                );
            end
            begin
                @(negedge clk);
                init3 = 1'b0;
            end
        join

        // Test 3.4: both negatives → positive = 9
        @(negedge clk);
        row3 = {-1, -1, -1};
        col3 = {-2, -3, -4};
        init3 = 1'b1;

        fork
            begin
                checkValues8(
                    .refclk(clk),
                    .sig2watch(total3),
                    .clks2wait(3),
                    .valHold(1'b1),
                    .goal_value(9),
                    .testnum(3.4)
                );
            end
            begin
                @(negedge clk);
                init3 = 1'b0;
            end
        join


        // Test 3.5: zeros yield 0
        @(negedge clk);
        row3 = {0, 0, 0};
        col3 = {7, -8, 5};
        init3 = 1'b1;

        fork
            begin
                checkValues8(
                    .refclk(clk),
                    .sig2watch(total3),
                    .clks2wait(3),
                    .valHold(1'b1),
                    .goal_value(0),
                    .testnum(3.5)
                );
            end
            begin
                @(negedge clk);
                init3 = 1'b0;
            end
        join

        // Test 3.6: mixed signs cancel
        @(negedge clk);
        row3 = {7, -7, 0};
        col3 = {1, 1, 5};
        init3 = 1'b1;

        fork
            begin
                checkValues8(
                    .refclk(clk),
                    .sig2watch(total3),
                    .clks2wait(3),
                    .valHold(1'b1),
                    .goal_value(0),
                    .testnum(3.6)
                );
            end
            begin
                @(negedge clk);
                init3 = 1'b0;
            end
        join

        // Test 3.7: max-neg sum w/o overflow = -112
        @(negedge clk);
        row3 = {-8, -8, 0};
        col3 = {7, 7, 5};
        init3 = 1'b1;

        fork
            begin
                checkValues8(
                    .refclk(clk),
                    .sig2watch(total3),
                    .clks2wait(3),
                    .valHold(1'b1),
                    .goal_value(-112),
                    .testnum(3.7)
                );
                checkValues1(
                    .refclk(clk),
                    .sig2watch(err3),
                    .clks2wait(3),
                    .valHold(1'b1),
                    .goal_value(1'b0),
                    .testnum(3.71) // subtest of 3.7
                );
            end
            begin
                @(negedge clk);
                init3 = 1'b0;
            end
        join

        // Test 3.8: positive overflow
        @(negedge clk);
        row3 = {-8, -8, 0};
        col3 = {-8, -8, 0};
        init3 = 1'b1;

        fork
            begin
                checkValues1(
                    .refclk(clk),
                    .sig2watch(err3),
                    .clks2wait(3),
                    .valHold(1'b1),
                    .goal_value(1'b1),
                    .testnum(3.8)
                );
            end
            begin
                @(negedge clk);
                init3 = 1'b0;
            end
        join

        // Test 3.95: overflow flag HOLDS until init
        @(negedge clk);
        row3 = {1, 1, 1};
        col3 = {1, 1, 1};
        checkValues1(
            .refclk(clk),
            .sig2watch(err3),
            .clks2wait(3),
            .valHold(1'b1),
            .goal_value(1'b1),
            .testnum(3.95) // encodes 3.9 subcase
        );

        // Test 3.10: init clears overflow; sum = 3
        @(negedge clk);
        init3 = 1'b1;

        fork
            begin
                checkValues1(
                    .refclk(clk),
                    .sig2watch(err3),
                    .clks2wait(1),
                    .valHold(1'b1),
                    .goal_value(1'b0),
                    .testnum(3.10)
                );

                checkValues8(
                    .refclk(clk),
                    .sig2watch(total3),
                    .clks2wait(3),
                    .valHold(1'b1),
                    .goal_value(3),
                    .testnum(3.101) // subtest of 3.10
                );
            end
            begin
                @(negedge clk);
                init3 = 1'b0;
            end
        join

        // Test 3.11: sign extremes w/o overflow = -15
        @(negedge clk);
        row3 = {-8, 7, 0};
        col3 = {1, -1, 5};
        init3 = 1'b1;

        fork
            begin
                checkValues8(
                    .refclk(clk),
                    .sig2watch(total3),
                    .clks2wait(3),
                    .valHold(1'b1),
                    .goal_value(-15),
                    .testnum(3.11)
                );
                checkValues1(
                    .refclk(clk),
                    .sig2watch(err3),
                    .clks2wait(3),
                    .valHold(1'b1),
                    .goal_value(1'b0),
                    .testnum(3.111) // subtest of 3.11
                );
            end
            begin
                @(negedge clk);
                init3 = 1'b0;
            end
        join




    /****************************
    ***          N = 10        ***
    ****************************/

        // Test 10.1: Reset keeps total10 on 0
        rst_n10 = 1'b0;

        checkValues6(
            .refclk(clk),
            .sig2watch(total10),
            .clks2wait(5),
            .valHold(1'b1),
            .goal_value(0),
            .testnum(10.1)
        );

        // Test 10.2: all positives (ten 1*1 terms = 10)
        @(posedge clk);
        rst_n10 = 1'b1;

        @(negedge clk);
        row10 = '{1,1,1,1,1,1,1,1,1,1};
        col10 = '{1,1,1,1,1,1,1,1,1,1};
        init10 = 1'b1;

        fork
            begin
                checkValues6(
                    .refclk(clk),
                    .sig2watch(total10),
                    .clks2wait(10),
                    .valHold(1'b1),
                    .goal_value(10),
                    .testnum(10.2)
                );
            end
            begin
                @(negedge clk);
                init10 = 1'b0;
            end
        join

        // Test 10.3: all negatives (ten 1*-1 terms = -10)
        @(negedge clk);
        row10 = '{1,1,1,1,1,1,1,1,1,1};
        col10 = '{-1,-1,-1,-1,-1,-1,-1,-1,-1,-1};
        init10 = 1'b1;

        fork
            begin
                checkValues6(
                    .refclk(clk),
                    .sig2watch(total10),
                    .clks2wait(10),
                    .valHold(1'b1),
                    .goal_value(-10),
                    .testnum(10.3)
                );
            end
            begin
                @(negedge clk);
                init10 = 1'b0;
            end
        join

        // Test 10.4: both negatives → positive (ten (-1*-1) = 10)
        @(negedge clk);
        row10 = '{-1,-1,-1,-1,-1,-1,-1,-1,-1,-1};
        col10 = '{-1,-1,-1,-1,-1,-1,-1,-1,-1,-1};
        init10 = 1'b1;

        fork
            begin
                checkValues6(
                    .refclk(clk),
                    .sig2watch(total10),
                    .clks2wait(10),
                    .valHold(1'b1),
                    .goal_value(10),
                    .testnum(10.4)
                );
            end
            begin
                @(negedge clk);
                init10 = 1'b0;
            end
        join

        /**************************************************************************
        ***                            Device Under Testing                     ***
        **************************************************************************/
        // Test 10.5: zeros yield 0 regardless of other vector
        @(negedge clk);
        row10 = '{0,0,0,0,0,0,0,0,0,0};
        col10 = '{3,-2,1,-1,2,-3,1,-1,2,-3};
        init10 = 1'b1;

        fork
            begin
                checkValues6(
                    .refclk(clk),
                    .sig2watch(total10),
                    .clks2wait(10),
                    .valHold(1'b1),
                    .goal_value(0),
                    .testnum(10.5)
                );
            end
            begin
                @(negedge clk);
                init10 = 1'b0;
            end
        join

        // Test 10.6: mixed signs cancel to 0
        @(negedge clk);
        row10 = '{3,3,3,3,-3,-3,-3,-3,0,0};
        col10 = '{1,1,1,1, 1, 1, 1, 1,0,0};
        init10 = 1'b1;

        fork
            begin
                checkValues6(
                    .refclk(clk),
                    .sig2watch(total10),
                    .clks2wait(10),
                    .valHold(1'b1),
                    .goal_value(0),
                    .testnum(10.6)
                );
            end
            begin
                @(negedge clk);
                init10 = 1'b0;
            end
        join

        // Test 10.7: boundary no-overflow at -32
        @(negedge clk);
        row10 = '{-4,-4,-4,-4,-4,-4,-4,-4,0,0};
        col10 = '{ 1, 1, 1, 1, 1, 1, 1, 1,0,0};
        init10 = 1'b1;

        fork
            begin
                checkValues6(
                    .refclk(clk),
                    .sig2watch(total10),
                    .clks2wait(10),
                    .valHold(1'b1),
                    .goal_value(-32),
                    .testnum(10.7)
                );
                checkValues1(
                    .refclk(clk),
                    .sig2watch(err10),
                    .clks2wait(10),
                    .valHold(1'b1),
                    .goal_value(1'b0),
                    .testnum(10.71) // subtest of 10.7
                );
            end
            begin
                @(negedge clk);
                init10 = 1'b0;
            end
        join

        // Test 10.8: positive overflow
        @(negedge clk);
        row10 = '{-4,-4,-4,-4,-4,-4,-4,-4,-4,-4};
        col10 = '{-4,-4,-4,-4,-4,-4,-4,-4,-4,-4};
        init10 = 1'b1;

        fork
            begin
                checkValues1(
                    .refclk(clk),
                    .sig2watch(err10),
                    .clks2wait(10),
                    .valHold(1'b1),
                    .goal_value(1'b1),
                    .testnum(10.8)
                );
            end
            begin
                @(negedge clk);
                init10 = 1'b0;
            end
        join

        // Test 10.85: overflow flag HOLDS until init
        @(negedge clk);
        row10 = '{1,1,1,1,1,1,1,1,1,1};
        col10 = '{1,1,1,1,1,1,1,1,1,1};

        checkValues1(
            .refclk(clk),
            .sig2watch(err10),
            .clks2wait(2),
            .valHold(1'b1),
            .goal_value(1'b1),
            .testnum(10.85) // encodes 10.8 subcase
        );

        // Test 10.10: init clears overflow; sum = 10
        @(negedge clk);
        init10 = 1'b1;

        fork
            begin
                checkValues1(
                    .refclk(clk),
                    .sig2watch(err10),
                    .clks2wait(1),
                    .valHold(1'b1),
                    .goal_value(1'b0),
                    .testnum(10.10)
                );

                checkValues6(
                    .refclk(clk),
                    .sig2watch(total10),
                    .clks2wait(10),
                    .valHold(1'b1),
                    .goal_value(10),
                    .testnum(10.101) // subtest of 10.10
                );
            end
            begin
                @(negedge clk);
                init10 = 1'b0;
            end
        join

        // Test 10.11: sign extremes without overflow → -15
        @(negedge clk);
        row10 = '{-4, 3, 1, 0,0,0,0,0,0,0};
        col10 = '{ 1,-3,-2, 0,0,0,0,0,0,0};
        init10 = 1'b1;

        fork
            begin
                checkValues6(
                    .refclk(clk),
                    .sig2watch(total10),
                    .clks2wait(10),
                    .valHold(1'b1),
                    .goal_value(-15),
                    .testnum(10.11)
                );
                checkValues1(
                    .refclk(clk),
                    .sig2watch(err10),
                    .clks2wait(10),
                    .valHold(1'b1),
                    .goal_value(1'b0),
                    .testnum(10.111) // subtest of 10.11
                );
            end
            begin
                @(negedge clk);
                init10 = 1'b0;
            end
        join

        print_all_passed_banner();
    end

endmodule
