import testing_pkg::*;

module PE_tb();

    /**************************************************************************
    ***                               Instantiations                         ***
    **************************************************************************/
    // Common params
    localparam   N           = 2;
    localparam   DATA_WIDTH  = 4;
    localparam   ACCUM_WIDTH = 2 * DATA_WIDTH;

    // Signals (N=2 instance)
    logic        rst_n;
    logic        clk;
    logic        start;
    logic        load_row;

    logic signed [DATA_WIDTH-1:0]  row [0:N-1];
    logic signed [DATA_WIDTH-1:0]  col [0:N-1];
    logic signed [DATA_WIDTH-1:0]  col_entry;
    logic signed [ACCUM_WIDTH-1:0] total;
    logic        done;
    logic        err;

    // Second Instance (N=3)
    localparam   N3          = 3;

    logic        rst_n3;
    logic        start3;
    logic        load_row3;

    logic signed [DATA_WIDTH-1:0]  row3 [0:N3-1];
    logic signed [DATA_WIDTH-1:0]  col3 [0:N3-1];
    logic signed [DATA_WIDTH-1:0]  col_entry3;
    logic signed [ACCUM_WIDTH-1:0] total3;
    logic        done3;
    logic        err3;

    // Third Instance (N=10, DATA_WIDTH=3)
    localparam   N10             = 10;
    localparam   DATA_WIDTH10    = 3;
    localparam   ACCUM_WIDTH10   = 2 * DATA_WIDTH10;

    logic        rst_n10;
    logic        start10;
    logic        load_row10;

    logic signed [DATA_WIDTH10-1:0]  row10 [0:N10-1];
    logic signed [DATA_WIDTH10-1:0]  col10 [0:N10-1];
    logic signed [DATA_WIDTH10-1:0]  col_entry10;
    logic signed [ACCUM_WIDTH10-1:0] total10;
    logic        done10;
    logic        err10;

    /**************************************************************************
    ***                            Devices Under Testing                     ***
    **************************************************************************/
    PE #(
        .N              (N),
        .DATA_WIDTH     (DATA_WIDTH),
        .ACCUM_WIDTH    (ACCUM_WIDTH)
    ) iDUT (
        .rst_n      (rst_n),
        .clk        (clk),
        .load_row   (load_row),
        .start      (start),
        .row        (row),
        .col_entry  (col_entry),
        .total      (total),
        .done       (done),
        .err        (err)
    );

    PE #(
        .N              (N3),
        .DATA_WIDTH     (DATA_WIDTH),
        .ACCUM_WIDTH    (ACCUM_WIDTH)
    ) iDUT3 (
        .rst_n      (rst_n3),
        .clk        (clk),
        .load_row   (load_row3),
        .start      (start3),
        .row        (row3),
        .col_entry  (col_entry3),
        .total      (total3),
        .done       (done3),
        .err        (err3)
    );

    PE #(
        .N              (N10),
        .DATA_WIDTH     (DATA_WIDTH10),
        .ACCUM_WIDTH    (ACCUM_WIDTH10)
    ) iDUT10 (
        .rst_n      (rst_n10),
        .clk        (clk),
        .load_row   (load_row10),
        .start      (start10),
        .row        (row10),
        .col_entry  (col_entry10),
        .total      (total10),
        .done       (done10),
        .err        (err10)
    );

    // 100 MHz
    always #5 clk = ~clk;

    /**************************************************************************
    ***                                Test Suites                           ***
    **************************************************************************/
    initial begin
        // Defaults
        clk = 0;

        // N=2 defaults
        rst_n     = 1'b0;
        start     = 1'b0;
        load_row  = 1'b0;
        col_entry = '0;
        row       = '{default: '0};
        col       = '{default: '0};

        // N=3 defaults
        rst_n3     = 1'b0;
        start3     = 1'b0;
        load_row3  = 1'b0;
        col_entry3 = '0;
        row3       = '{default: '0};
        col3       = '{default: '0};

        // N=10 defaults
        rst_n10     = 1'b0;
        start10     = 1'b0;
        load_row10  = 1'b0;
        col_entry10 = '0;
        row10       = '{default: '0};
        col10       = '{default: '0};

        /****************************
        ***          N = 2        ***
        ****************************/

        // Test 2.1: Reset keeps total on 0
        checkValues8(
            .refclk(clk),
            .sig2watch(total),
            .clks2wait(6),
            .valHold(1'b1),
            .goal_value(0),
            .testnum(2.1)
        );

        // Test 2.2: Testing all positives (1*2 + 1*3 = 5)
        @(posedge clk);
        rst_n = 1'b1;

        @(negedge clk);
        load_row = 1'b1;
        row = '{1, 1};

        @(negedge clk);
        load_row = 1'b0;
        col = '{2, 3};
        start = 1'b1;

        fork
            begin
                @(negedge clk);
                foreach (col[i]) begin
                    col_entry = col[i];
                    @(negedge clk);
                end
            end
            begin
                checkValues8(
                    .refclk(clk),
                    .sig2watch(total),
                    .clks2wait(4),
                    .valHold(1'b1),
                    .goal_value(5),
                    .testnum(2.2)
                );
            end
            begin
                @(negedge clk);
                start = 1'b0;
            end
        join

        // Test 2.3: clears properly then negatives -> -5
        @(negedge clk);
        load_row = 1'b1;
        row = '{1, 1};

        @(negedge clk);
        load_row = 1'b0;
        col = '{-2, -3};
        start = 1'b1;

        fork
            begin
                @(negedge clk);
                foreach (col[i]) begin
                    col_entry = col[i];
                    @(negedge clk);
                end
            end
            begin
                checkValues8(
                    .refclk(clk),
                    .sig2watch(total),
                    .clks2wait(4),
                    .valHold(1'b1),
                    .goal_value(-5),
                    .testnum(2.3)
                );
            end
            begin
                @(negedge clk);
                start = 1'b0;
            end
        join

        // Test 2.4: both negatives → positive -> 5
        @(negedge clk);
        load_row = 1'b1;
        row = '{-1, -1};

        @(negedge clk);
        load_row = 1'b0;
        col = '{-2, -3};
        start = 1'b1;

        fork
            begin
                @(negedge clk);
                foreach (col[i]) begin
                    col_entry = col[i];
                    @(negedge clk);
                end
            end
            begin
                checkValues8(
                    .refclk(clk),
                    .sig2watch(total),
                    .clks2wait(3),
                    .valHold(1'b1),
                    .goal_value(5),
                    .testnum(2.4)
                );
            end
            begin
                @(negedge clk);
                start = 1'b0;
            end
        join

        // Test 2.5: zeros anywhere should yield 0
        @(negedge clk);
        load_row = 1'b1;
        row = '{0, 0};

        @(negedge clk);
        load_row = 1'b0;
        col = '{7, -8};
        start = 1'b1;

        fork
            begin
                @(negedge clk);
                foreach (col[i]) begin
                    col_entry = col[i];
                    @(negedge clk);
                end
            end
            begin
                checkValues8(
                    .refclk(clk),
                    .sig2watch(total),
                    .clks2wait(3),
                    .valHold(1'b1),
                    .goal_value(0),
                    .testnum(2.5)
                );
            end
            begin
                @(negedge clk);
                start = 1'b0;
            end
        join

        // Test 2.6: mixed signs cancel (7*1 + (-7)*1 = 0)
        @(negedge clk);
        load_row = 1'b1;
        row = '{7, -7};

        @(negedge clk);
        load_row = 1'b0;
        col = '{1, 1};
        start = 1'b1;

        fork
            begin
                @(negedge clk);
                foreach (col[i]) begin
                    col_entry = col[i];
                    @(negedge clk);
                end
            end
            begin
                checkValues8(
                    .refclk(clk),
                    .sig2watch(total),
                    .clks2wait(3),
                    .valHold(1'b1),
                    .goal_value(0),
                    .testnum(2.6)
                );
            end
            begin
                @(negedge clk);
                start = 1'b0;
            end
        join

        // Test 2.7: max-magnitude negative sum (no overflow): -112
        @(negedge clk);
        load_row = 1'b1;
        row = '{-8, -8};

        @(negedge clk);
        load_row = 1'b0;
        col = '{7, 7};
        start = 1'b1;

        fork
            begin
                @(negedge clk);
                foreach (col[i]) begin
                    col_entry = col[i];
                    @(negedge clk);
                end
            end
            begin
                checkValues8(
                    .refclk(clk),
                    .sig2watch(total),
                    .clks2wait(3),
                    .valHold(1'b1),
                    .goal_value(-112),
                    .testnum(2.7)
                );
                checkValues1(
                    .refclk(clk),
                    .sig2watch(err),
                    .clks2wait(3),
                    .valHold(1'b1),
                    .goal_value(1'b0),
                    .testnum(2.71)
                );
            end
            begin
                @(negedge clk);
                start = 1'b0;
            end
        join

        // Test 2.8: positive overflow -> err=1
        @(negedge clk);
        load_row = 1'b1;
        row = '{-8, -8};

        @(negedge clk);
        load_row = 1'b0;
        col = '{-8, -8};
        start = 1'b1;

        fork
            begin
                @(negedge clk);
                foreach (col[i]) begin
                    col_entry = col[i];
                    @(negedge clk);
                end
            end
            begin
                checkValues1(
                    .refclk(clk),
                    .sig2watch(err),
                    .clks2wait(3),
                    .valHold(1'b1),
                    .goal_value(1'b1),
                    .testnum(2.8)
                );
            end
            begin
                @(negedge clk);
                start = 1'b0;
            end
        join

        // Test 2.9: overflow flag HOLDS until start
        @(negedge clk);
        load_row = 1'b1;
        row = '{1, 1};

        @(negedge clk);
        load_row = 1'b0;
        col = '{1, 1};

        checkValues1(
            .refclk(clk),
            .sig2watch(err),
            .clks2wait(3),
            .valHold(1'b1),
            .goal_value(1'b1),
            .testnum(2.9)
        );

        // Test 2.10: start clears overflow; math resumes (sum=2)
        @(negedge clk);
        start = 1'b1;

        fork
            begin
                checkValues1(
                    .refclk(clk),
                    .sig2watch(err),
                    .clks2wait(2),
                    .valHold(1'b1),
                    .goal_value(1'b0),
                    .testnum(2.10)
                );
            end
            begin
                @(negedge clk);
                foreach (col[i]) begin
                    col_entry = col[i];
                    @(negedge clk);
                end
                checkValues8(
                    .refclk(clk),
                    .sig2watch(total),
                    .clks2wait(3),
                    .valHold(1'b1),
                    .goal_value(2),
                    .testnum(2.101)
                );
            end
            begin
                @(negedge clk);
                start = 1'b0;
            end
        join

        // Test 2.11: sign extremes without overflow = -15
        @(negedge clk);
        load_row = 1'b1;
        row = '{-8, 7};

        @(negedge clk);
        load_row = 1'b0;
        col = '{1, -1};
        start = 1'b1;

        fork
            begin
                @(negedge clk);
                foreach (col[i]) begin
                    col_entry = col[i];
                    @(negedge clk);
                end
            end
            begin
                checkValues8(
                    .refclk(clk),
                    .sig2watch(total),
                    .clks2wait(3),
                    .valHold(1'b1),
                    .goal_value(-15),
                    .testnum(2.11)
                );
                checkValues1(
                    .refclk(clk),
                    .sig2watch(err),
                    .clks2wait(3),
                    .valHold(1'b1),
                    .goal_value(1'b0),
                    .testnum(2.111)
                );
            end
            begin
                @(negedge clk);
                start = 1'b0;
            end
        join

        /****************************
        ***          N = 3        ***
        ****************************/
        // Test 3.1: Reset keeps total3 on 0
        @(negedge clk);
        rst_n3 = 1'b0;

        checkValues8(
            .refclk(clk),
            .sig2watch(total3),
            .clks2wait(6),
            .valHold(1'b1),
            .goal_value(0),
            .testnum(3.1)
        );

        // Test 3.2: all positives (1*2 + 1*3 + 1*4 = 9)
        @(posedge clk);
        rst_n3 = 1'b1;

        @(negedge clk);
        load_row3 = 1'b1;
        row3 = '{1, 1, 1};

        @(negedge clk);
        load_row3 = 1'b0;
        col3 = '{2, 3, 4};
        start3 = 1'b1;

        fork
            begin
                @(negedge clk);
                foreach (col3[i]) begin
                    col_entry3 = col3[i];
                    @(negedge clk);
                end
            end
            begin
                checkValues8(
                    .refclk(clk),
                    .sig2watch(total3),
                    .clks2wait(4),
                    .valHold(1'b1),
                    .goal_value(9),
                    .testnum(3.2)
                );
            end
            begin
                @(negedge clk);
                start3 = 1'b0;
            end
        join

        // Test 3.3: negatives = -9
        @(negedge clk);
        load_row3 = 1'b1;
        row3 = '{1, 1, 1};

        @(negedge clk);
        load_row3 = 1'b0;
        col3 = '{-2, -3, -4};
        start3 = 1'b1;

        fork
            begin
                @(negedge clk);
                foreach (col3[i]) begin
                    col_entry3 = col3[i];
                    @(negedge clk);
                end
            end
            begin
                checkValues8(
                    .refclk(clk),
                    .sig2watch(total3),
                    .clks2wait(4),
                    .valHold(1'b1),
                    .goal_value(-9),
                    .testnum(3.3)
                );
            end
            begin
                @(negedge clk);
                start3 = 1'b0;
            end
        join

        // Test 3.4: both negatives → positive = 9
        @(negedge clk);
        load_row3 = 1'b1;
        row3 = '{-1, -1, -1};

        @(negedge clk);
        load_row3 = 1'b0;
        col3 = '{-2, -3, -4};
        start3 = 1'b1;

        fork
            begin
                @(negedge clk);
                foreach (col3[i]) begin
                    col_entry3 = col3[i];
                    @(negedge clk);
                end
            end
            begin
                checkValues8(
                    .refclk(clk),
                    .sig2watch(total3),
                    .clks2wait(4),
                    .valHold(1'b1),
                    .goal_value(9),
                    .testnum(3.4)
                );
            end
            begin
                @(negedge clk);
                start3 = 1'b0;
            end
        join

        // Test 3.5: zeros yield 0
        @(negedge clk);
        load_row3 = 1'b1;
        row3 = '{0, 0, 0};

        @(negedge clk);
        load_row3 = 1'b0;
        col3 = '{7, -8, 5};
        start3 = 1'b1;

        fork
            begin
                @(negedge clk);
                foreach (col3[i]) begin
                    col_entry3 = col3[i];
                    @(negedge clk);
                end
            end
            begin
                checkValues8(
                    .refclk(clk),
                    .sig2watch(total3),
                    .clks2wait(4),
                    .valHold(1'b1),
                    .goal_value(0),
                    .testnum(3.5)
                );
            end
            begin
                @(negedge clk);
                start3 = 1'b0;
            end
        join

        // Test 3.6: mixed signs cancel
        @(negedge clk);
        load_row3 = 1'b1;
        row3 = '{7, -7, 0};

        @(negedge clk);
        load_row3 = 1'b0;
        col3 = '{1, 1, 5};
        start3 = 1'b1;

        fork
            begin
                @(negedge clk);
                foreach (col3[i]) begin
                    col_entry3 = col3[i];
                    @(negedge clk);
                end
            end
            begin
                checkValues8(
                    .refclk(clk),
                    .sig2watch(total3),
                    .clks2wait(4),
                    .valHold(1'b1),
                    .goal_value(0),
                    .testnum(3.6)
                );
            end
            begin
                @(negedge clk);
                start3 = 1'b0;
            end
        join

        // Test 3.7: max-neg sum w/o overflow = -112, err3=0
        @(negedge clk);
        load_row3 = 1'b1;
        row3 = '{-8, -8, 0};

        @(negedge clk);
        load_row3 = 1'b0;
        col3 = '{7, 7, 5};
        start3 = 1'b1;

        fork
            begin
                @(negedge clk);
                foreach (col3[i]) begin
                    col_entry3 = col3[i];
                    @(negedge clk);
                end
            end
            begin
                checkValues8(
                    .refclk(clk),
                    .sig2watch(total3),
                    .clks2wait(4),
                    .valHold(1'b1),
                    .goal_value(-112),
                    .testnum(3.7)
                );
                checkValues1(
                    .refclk(clk),
                    .sig2watch(err3),
                    .clks2wait(4),
                    .valHold(1'b1),
                    .goal_value(1'b0),
                    .testnum(3.71)
                );
            end
            begin
                @(negedge clk);
                start3 = 1'b0;
            end
        join

        // Test 3.8: positive overflow -> err3=1
        @(negedge clk);
        load_row3 = 1'b1;
        row3 = '{-8, -8, 0};

        @(negedge clk);
        load_row3 = 1'b0;
        col3 = '{-8, -8, 0};
        start3 = 1'b1;

        fork
            begin
                @(negedge clk);
                foreach (col3[i]) begin
                    col_entry3 = col3[i];
                    @(negedge clk);
                end
            end
            begin
                checkValues1(
                    .refclk(clk),
                    .sig2watch(err3),
                    .clks2wait(4),
                    .valHold(1'b1),
                    .goal_value(1'b1),
                    .testnum(3.8)
                );
            end
            begin
                @(negedge clk);
                start3 = 1'b0;
            end
        join

        // Test 3.95: overflow flag HOLDS until start
        @(negedge clk);
        load_row3 = 1'b1;
        row3 = '{1, 1, 1};

        @(negedge clk);
        load_row3 = 1'b0;
        col3 = '{1, 1, 1};

        checkValues1(
            .refclk(clk),
            .sig2watch(err3),
            .clks2wait(4),
            .valHold(1'b1),
            .goal_value(1'b1),
            .testnum(3.95)
        );

        // Test 3.10: start clears overflow; sum = 3
        @(negedge clk);
        start3 = 1'b1;

        fork
            begin
                checkValues1(
                    .refclk(clk),
                    .sig2watch(err3),
                    .clks2wait(2),
                    .valHold(1'b1),
                    .goal_value(1'b0),
                    .testnum(3.10)
                );
            end
            begin
                @(negedge clk);
                foreach (col3[i]) begin
                    col_entry3 = col3[i];
                    @(negedge clk);
                end
                checkValues8(
                    .refclk(clk),
                    .sig2watch(total3),
                    .clks2wait(4),
                    .valHold(1'b1),
                    .goal_value(3),
                    .testnum(3.101)
                );
            end
            begin
                @(negedge clk);
                start3 = 1'b0;
            end
        join

        // Test 3.11: sign extremes without overflow = -15, err3=0
        @(negedge clk);
        load_row3 = 1'b1;
        row3 = '{-8, 7, 0};

        @(negedge clk);
        load_row3 = 1'b0;
        col3 = '{1, -1, 5};
        start3 = 1'b1;

        fork
            begin
                @(negedge clk);
                foreach (col3[i]) begin
                    col_entry3 = col3[i];
                    @(negedge clk);
                end
            end
            begin
                checkValues8(
                    .refclk(clk),
                    .sig2watch(total3),
                    .clks2wait(4),
                    .valHold(1'b1),
                    .goal_value(-15),
                    .testnum(3.11)
                );
                checkValues1(
                    .refclk(clk),
                    .sig2watch(err3),
                    .clks2wait(4),
                    .valHold(1'b1),
                    .goal_value(1'b0),
                    .testnum(3.111)
                );
            end
            begin
                @(negedge clk);
                start3 = 1'b0;
            end
        join

        /****************************
        ***          N = 10       ***
        ****************************/
        // Test 10.1: Reset keeps total10 on 0
        @(negedge clk);
        rst_n10 = 1'b0;

        checkValues6(
            .refclk(clk),
            .sig2watch(total10),
            .clks2wait(6),
            .valHold(1'b1),
            .goal_value(0),
            .testnum(10.1)
        );

        // Test 10.2: all positives (ten 1*1 = 10)
        @(posedge clk);
        rst_n10 = 1'b1;

        @(negedge clk);
        load_row10 = 1'b1;
        row10 = '{1, 1, 1, 1, 1, 1, 1, 1, 1, 1};

        @(negedge clk);
        load_row10 = 1'b0;
        col10 = '{1, 1, 1, 1, 1, 1, 1, 1, 1, 1};
        start10 = 1'b1;

        fork
            begin
                @(negedge clk);
                foreach (col10[i]) begin
                    col_entry10 = col10[i];
                    @(negedge clk);
                end
            end
            begin
                checkValues6(
                    .refclk(clk),
                    .sig2watch(total10),
                    .clks2wait(11),
                    .valHold(1'b1),
                    .goal_value(10),
                    .testnum(10.2)
                );
            end
            begin
                @(negedge clk);
                start10 = 1'b0;
            end
        join

        // Test 10.3: all negatives (ten 1*-1 = -10)
        @(negedge clk);
        load_row10 = 1'b1;
        row10 = '{1, 1, 1, 1, 1, 1, 1, 1, 1, 1};

        @(negedge clk);
        load_row10 = 1'b0;
        col10 = '{-1, -1, -1, -1, -1, -1, -1, -1, -1, -1};
        start10 = 1'b1;

        fork
            begin
                @(negedge clk);
                foreach (col10[i]) begin
                    col_entry10 = col10[i];
                    @(negedge clk);
                end
            end
            begin
                checkValues6(
                    .refclk(clk),
                    .sig2watch(total10),
                    .clks2wait(11),
                    .valHold(1'b1),
                    .goal_value(-10),
                    .testnum(10.3)
                );
            end
            begin
                @(negedge clk);
                start10 = 1'b0;
            end
        join

        // Test 10.4: both negatives → positive (ten 1 = 10)
        @(negedge clk);
        load_row10 = 1'b1;
        row10 = '{-1, -1, -1, -1, -1, -1, -1, -1, -1, -1};

        @(negedge clk);
        load_row10 = 1'b0;
        col10 = '{-1, -1, -1, -1, -1, -1, -1, -1, -1, -1};
        start10 = 1'b1;

        fork
            begin
                @(negedge clk);
                foreach (col10[i]) begin
                    col_entry10 = col10[i];
                    @(negedge clk);
                end
            end
            begin
                checkValues6(
                    .refclk(clk),
                    .sig2watch(total10),
                    .clks2wait(11),
                    .valHold(1'b1),
                    .goal_value(10),
                    .testnum(10.4)
                );
            end
            begin
                @(negedge clk);
                start10 = 1'b0;
            end
        join

        // Test 10.5: zeros yield 0 regardless of other vector
        @(negedge clk);
        load_row10 = 1'b1;
        row10 = '{0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

        @(negedge clk);
        load_row10 = 1'b0;
        col10 = '{3, -2, 1, -1, 2, -3, 1, -1, 2, -3};
        start10 = 1'b1;

        fork
            begin
                @(negedge clk);
                foreach (col10[i]) begin
                    col_entry10 = col10[i];
                    @(negedge clk);
                end
            end
            begin
                checkValues6(
                    .refclk(clk),
                    .sig2watch(total10),
                    .clks2wait(11),
                    .valHold(1'b1),
                    .goal_value(0),
                    .testnum(10.5)
                );
            end
            begin
                @(negedge clk);
                start10 = 1'b0;
            end
        join

        // Test 10.6: mixed signs cancel to 0
        @(negedge clk);
        load_row10 = 1'b1;
        row10 = '{3, 3, 3, 3, -3, -3, -3, -3, 0, 0};

        @(negedge clk);
        load_row10 = 1'b0;
        col10 = '{1, 1, 1, 1, 1, 1, 1, 1, 0, 0};
        start10 = 1'b1;

        fork
            begin
                @(negedge clk);
                foreach (col10[i]) begin
                    col_entry10 = col10[i];
                    @(negedge clk);
                end
            end
            begin
                checkValues6(
                    .refclk(clk),
                    .sig2watch(total10),
                    .clks2wait(11),
                    .valHold(1'b1),
                    .goal_value(0),
                    .testnum(10.6)
                );
            end
            begin
                @(negedge clk);
                start10 = 1'b0;
            end
        join

        // Test 10.7: boundary no-overflow at -32; err10=0
        @(negedge clk);
        load_row10 = 1'b1;
        row10 = '{-4, -4, -4, -4, -4, -4, -4, -4, 0, 0};

        @(negedge clk);
        load_row10 = 1'b0;
        col10 = '{1, 1, 1, 1, 1, 1, 1, 1, 0, 0};
        start10 = 1'b1;

        fork
            begin
                @(negedge clk);
                foreach (col10[i]) begin
                    col_entry10 = col10[i];
                    @(negedge clk);
                end
            end
            begin
                checkValues6(
                    .refclk(clk),
                    .sig2watch(total10),
                    .clks2wait(11),
                    .valHold(1'b1),
                    .goal_value(-32),
                    .testnum(10.7)
                );
                checkValues1(
                    .refclk(clk),
                    .sig2watch(err10),
                    .clks2wait(11),
                    .valHold(1'b1),
                    .goal_value(1'b0),
                    .testnum(10.71)
                );
            end
            begin
                @(negedge clk);
                start10 = 1'b0;
            end
        join

        // Test 10.8: positive overflow -> err10=1
        @(negedge clk);
        load_row10 = 1'b1;
        row10 = '{-4, -4, -4, -4, -4, -4, -4, -4, -4, -4};

        @(negedge clk);
        load_row10 = 1'b0;
        col10 = '{-4, -4, -4, -4, -4, -4, -4, -4, -4, -4};
        start10 = 1'b1;

        fork
            begin
                @(negedge clk);
                foreach (col10[i]) begin
                    col_entry10 = col10[i];
                    @(negedge clk);
                end
            end
            begin
                checkValues1(
                    .refclk(clk),
                    .sig2watch(err10),
                    .clks2wait(11),
                    .valHold(1'b1),
                    .goal_value(1'b1),
                    .testnum(10.8)
                );
            end
            begin
                @(negedge clk);
                start10 = 1'b0;
            end
        join

        // Test 10.85: overflow flag HOLDS until start
        @(negedge clk);
        load_row10 = 1'b1;
        row10 = '{1, 1, 1, 1, 1, 1, 1, 1, 1, 1};

        @(negedge clk);
        load_row10 = 1'b0;
        col10 = '{1, 1, 1, 1, 1, 1, 1, 1, 1, 1};

        checkValues1(
            .refclk(clk),
            .sig2watch(err10),
            .clks2wait(3),
            .valHold(1'b1),
            .goal_value(1'b1),
            .testnum(10.85)
        );

        // Test 10.10: start clears overflow; sum = 10
        @(negedge clk);
        start10 = 1'b1;

        fork
            begin
                checkValues1(
                    .refclk(clk),
                    .sig2watch(err10),
                    .clks2wait(2),
                    .valHold(1'b1),
                    .goal_value(1'b0),
                    .testnum(10.10)
                );
            end
            begin
                @(negedge clk);
                foreach (col10[i]) begin
                    col_entry10 = col10[i];
                    @(negedge clk);
                end
                checkValues6(
                    .refclk(clk),
                    .sig2watch(total10),
                    .clks2wait(11),
                    .valHold(1'b1),
                    .goal_value(10),
                    .testnum(10.101)
                );
            end
            begin
                @(negedge clk);
                start10 = 1'b0;
            end
        join

        // Test 10.11: sign extremes without overflow → -15; err10=0
        @(negedge clk);
        load_row10 = 1'b1;
        row10 = '{-4, 3, 1, 0, 0, 0, 0, 0, 0, 0};

        @(negedge clk);
        load_row10 = 1'b0;
        col10 = '{1, -3, -2, 0, 0, 0, 0, 0, 0, 0};
        start10 = 1'b1;

        fork
            begin
                @(negedge clk);
                foreach (col10[i]) begin
                    col_entry10 = col10[i];
                    @(negedge clk);
                end
            end
            begin
                checkValues6(
                    .refclk(clk),
                    .sig2watch(total10),
                    .clks2wait(11),
                    .valHold(1'b1),
                    .goal_value(-15),
                    .testnum(10.11)
                );
                checkValues1(
                    .refclk(clk),
                    .sig2watch(err10),
                    .clks2wait(11),
                    .valHold(1'b1),
                    .goal_value(1'b0),
                    .testnum(10.111)
                );
            end
            begin
                @(negedge clk);
                start10 = 1'b0;
            end
        join

        print_all_passed_banner();
        $finish;
    end

endmodule
