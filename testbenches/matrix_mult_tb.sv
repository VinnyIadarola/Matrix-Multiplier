import testing_pkg::*;

module matrix_mult_tb();

localparam int N           = 2;
localparam int P           = 2;
localparam int M           = 2;
localparam int unsigned N_BIT_WIDTH = (N > 1) ? $clog2(N) : 1;
localparam int unsigned P_BIT_WIDTH = (P > 1) ? $clog2(P) : 1;
localparam int unsigned M_BIT_WIDTH = (M > 1) ? $clog2(M) : 1;
localparam int DATA_WIDTH  = 4;
localparam int ACCUM_WIDTH = 2 * DATA_WIDTH;
localparam int FIFO_SIZE   = 4;

logic clk;
logic rst_n;

logic fetch_stall;
logic data_stall;

logic pop_fifo;
logic start;
logic [DATA_WIDTH-1:0] mem_line [0:N-1];

logic [N_BIT_WIDTH-1:0] n;
logic [M_BIT_WIDTH-1:0] m;
logic fetch_row;
logic fetch_col;
logic [ACCUM_WIDTH-1:0] fifo_head;
logic fifo_empty;
logic fifo_full;
logic done;
logic err;

logic signed [DATA_WIDTH-1:0] A_mat [0:N-1][0:P-1];
logic signed [DATA_WIDTH-1:0] B_mat [0:P-1][0:M-1];

int i, k, q;

// Put near other decls
bit any_fail;
bit test_failed;

// Replace the old macro with this:
`define CHECK(expr) \
    if (!(expr)) begin \
        any_fail   = 1'b1; \
        test_failed = 1'b1; \
        $error("ASSERTION FAILED: %s", `"expr`"); \
    end

matrix_multiplier #(
    .N              (N),
    .P              (P),
    .M              (M),
    .DATA_WIDTH     (DATA_WIDTH),
    .ACCUM_WIDTH    (ACCUM_WIDTH),
    .FIFO_SIZE      (FIFO_SIZE)
) iDUT (
    .clk            (clk),
    .rst_n          (rst_n),
    .fetch_stall    (fetch_stall),
    .data_stall     (data_stall),
    .pop_fifo       (pop_fifo),
    .start          (start),
    .mem_line     (mem_line),
    .n              (n),
    .m              (m),
    .fetch_row      (fetch_row),
    .fetch_col      (fetch_col),
    .fifo_head      (fifo_head),
    .fifo_empty     (fifo_empty),
    .fifo_full      (fifo_full),
    .done           (done),
    .err            (err)
);

always #5 clk = ~clk;

initial begin
    any_fail     = 1'b0;
    clk          = '0;
    rst_n        = 'x;
    fetch_stall  = 'x;
    data_stall   = 'x;
    pop_fifo     = 'x;
    start        = 'x;
    mem_line   = '{default:'x};

    $display("\n******************** TEST 1: RESET ********************");
    test_failed = 1'b0;
    @(posedge clk);
    rst_n       = 1'b0;

    @(negedge clk);
    `CHECK(fifo_head  ===   '0);
    `CHECK(n          ===   '0);
    `CHECK(m          ===   '0);
    `CHECK(fetch_row  === 1'b0);
    `CHECK(fetch_col  === 1'b0);
    `CHECK(fifo_empty === 1'b1);
    `CHECK(fifo_full  === 1'b0);
    `CHECK(done       === 1'b0);
    `CHECK(err        === 1'b0);
    if (!test_failed) $display("PASS");

    @(posedge clk);
    rst_n       = 1'b1;

    $display("\n******************** TEST 2: IDLE WITHOUT START ********************");
    test_failed = 1'b0;
    @(negedge clk);
    fetch_stall = 1'b0;
    data_stall  = 1'b0;
    pop_fifo    = 1'b0;
    start       = 1'b0;
    mem_line  = {1, 2};

    repeat ((N*M)*(N*M)) begin
        `CHECK(fifo_head  ===   '0);
        `CHECK(n          ===   '0);
        `CHECK(m          ===   '0);
        `CHECK(fetch_row  === 1'b0);
        `CHECK(fetch_col  === 1'b0);
        `CHECK(fifo_empty === 1'b1);
        `CHECK(fifo_full  === 1'b0);
        `CHECK(done       === 1'b0);
        `CHECK(err        === 1'b0);
        @(negedge clk);
    end
    if (!test_failed) $display("PASS");


    $display("\n******************** TEST 3: IDLE UNDER STALLS  ********************");
    test_failed = 1'b0;
    @(negedge clk);
    fetch_stall  = '1;
    data_stall   = '1;
    start        = '1;

    $display("****PART 1...");
    @(negedge clk); 
    `CHECK(fifo_head  ===   '0);
    `CHECK(n          ===   '0);
    `CHECK(m          ===   '0);
    `CHECK(fetch_row  === 1'b0);
    `CHECK(fetch_col  === 1'b0);
    `CHECK(fifo_empty === 1'b1);
    `CHECK(fifo_full  === 1'b0);
    `CHECK(done       === 1'b0);
    `CHECK(err        === 1'b0);
    if (!test_failed) $display("****PASS");


    @(negedge clk);
    start = '0;

    $display("****PART 2");
    repeat ((N*M)*(N*M)) begin
        `CHECK(fifo_head  ===   '0);
        `CHECK(n          ===   '0);
        `CHECK(m          ===   '0);
        `CHECK(fetch_row  === 1'b0);
        `CHECK(fetch_col  === 1'b0);
        `CHECK(fifo_empty === 1'b1);
        `CHECK(fifo_full  === 1'b0);
        `CHECK(done       === 1'b0);
        `CHECK(err        === 1'b0);
        @(negedge clk);
    end
    if (!test_failed) $display("****PASS");
    if (!test_failed) $display("PASS");


    

    $display("\n******************** TEST 4: FETCH_STALL DROP AT ROW  ********************");
    test_failed = 1'b0;
    @(negedge clk);
    fetch_stall = '0;

    #2; // stall slightly so we can check the values 
    $display("****PART 1...");
    `CHECK(fifo_head  ===   '0);
    `CHECK(n          ===   '0);
    `CHECK(m          ===   '0);
    `CHECK(fetch_row  === 1'b1);
    `CHECK(fetch_col  === 1'b0);
    `CHECK(fifo_empty === 1'b1);
    `CHECK(fifo_full  === 1'b0);
    `CHECK(done       === 1'b0);
    `CHECK(err        === 1'b0);
    if (!test_failed) $display("****PASS");

    // raising so further chip stalls later
    @(negedge clk);
    fetch_stall = 1'b1;

    $display("****PART 2...");
    repeat ((N*M)*(N*M)) begin
        `CHECK(fifo_head  ===   '0);
        `CHECK(n          ===   '0);
        `CHECK(m          ===   '0);
        `CHECK(fetch_row  === 1'b0);
        `CHECK(fetch_col  === 1'b0);
        `CHECK(fifo_empty === 1'b1);
        `CHECK(fifo_full  === 1'b0);
        `CHECK(done       === 1'b0);
        `CHECK(err        === 1'b0);
        @(negedge clk);
    end
    if (!test_failed) $display("****PASS");
    if (!test_failed) $display("PASS");


    $display("\n******************** TEST 5: DATA_STALL DROP TRIGGERS LOAD_ROW ********************");
    test_failed = 1'b0;
    @(negedge clk);
    data_stall = 1'b0;

    #2; // stall slightly so we can check the values 
    $display("****PART 1...");
    `CHECK(iDUT.load_row  === 1'b1);
    `CHECK(fifo_head  ===   '0);
    `CHECK(n          ===   '0);
    `CHECK(m          ===   '0);
    `CHECK(fetch_row  === 1'b0);
    `CHECK(fetch_col  === 1'b0);
    `CHECK(fifo_empty === 1'b1);
    `CHECK(fifo_full  === 1'b0);
    `CHECK(done       === 1'b0);
    `CHECK(err        === 1'b0);
    if (!test_failed) $display("****PASS");

    // raising so further chip stalls later
    @(negedge clk);
    data_stall = 1'b1;

    $display("****PART 2...");
    repeat ((N*M)*(N*M)) begin
        `CHECK(iDUT.load_row  === 1'b0);
        `CHECK(fifo_head  ===   '0);
        `CHECK(n          ===   '0);
        `CHECK(m          ===   '0);
        `CHECK(fetch_row  === 1'b0);
        `CHECK(fetch_col  === 1'b0);
        `CHECK(fifo_empty === 1'b1);
        `CHECK(fifo_full  === 1'b0);
        `CHECK(done       === 1'b0);
        `CHECK(err        === 1'b0);
        @(negedge clk);
    end
    if (!test_failed) $display("****PASS");
    if (!test_failed) $display("PASS");

    $display("\n******************** TEST 6: FETCH_STALL DROP AT COL ********************");
    test_failed = 1'b0;
    @(negedge clk);
    fetch_stall = 1'b0;

    #2; // stall slightly so we can check the values 

    $display("****PART 1...");
    `CHECK(fifo_head  ===   '0);
    `CHECK(n          ===   '0);
    `CHECK(m          ===   '0);
    `CHECK(fetch_row  === 1'b0);
    `CHECK(fetch_col  === 1'b1);
    `CHECK(fifo_empty === 1'b1);
    `CHECK(fifo_full  === 1'b0);
    `CHECK(done       === 1'b0);
    `CHECK(err        === 1'b0);
    if (!test_failed) $display("****PASS");

    // raising so further chip stalls later
    @(negedge clk);
    fetch_stall = 1'b1;


    $display("****PART 2...");
    repeat ((N*M)*(N*M)) begin
        @(negedge clk);
        `CHECK(fifo_head  ===   '0);
        `CHECK(n          ===   '0);
        `CHECK(m          ===   '0);
        `CHECK(fetch_row  === 1'b0);
        `CHECK(fetch_col  === 1'b0);
        `CHECK(fifo_empty === 1'b1);
        `CHECK(fifo_full  === 1'b0);
        `CHECK(done       === 1'b0);
        `CHECK(err        === 1'b0);
    end
    if (!test_failed) $display("****PASS");
    if (!test_failed) $display("PASS");


    $display("\n******************** TEST 7: DATA STALL DROP AT COL ********************");
    test_failed = 1'b0;
    @(negedge clk);
    data_stall = 1'b0;

    #2; // stall slightly so we can check the values 

    $display("****PART 1...");
    `CHECK(iDUT.start_PE === 1'b1);
    `CHECK(fifo_head  ===   '0);
    `CHECK(n          ===   '0);
    `CHECK(m          ===   '0);
    `CHECK(fetch_row  === 1'b0);
    `CHECK(fetch_col  === 1'b0);
    `CHECK(fifo_empty === 1'b1);
    `CHECK(fifo_full  === 1'b0);
    `CHECK(done       === 1'b0);
    `CHECK(err        === 1'b0);
    if (!test_failed) $display("****PASS");


    //raise back so we force stall
    @(negedge clk);
    data_stall = 1'b1;


    $display("****PART 2...");
    @(negedge clk);
    `CHECK(iDUT.start_PE === 1'b0);
    `CHECK(fifo_head  ===   '0);
    `CHECK(n          ===   '0);
    `CHECK(m          ===    1);
    `CHECK(fetch_row  === 1'b0);
    `CHECK(fetch_col  === 1'b0);
    `CHECK(fifo_empty === 1'b1);
    `CHECK(fifo_full  === 1'b0);
    `CHECK(done       === 1'b0);
    `CHECK(err        === 1'b0);
    if (!test_failed) $display("****PASS");


    $display("****PART 3...");
    repeat ((N*M)*(N*M)) begin
        @(negedge clk);
        `CHECK(n          ===   '0);
        `CHECK(m          ===    1);
        `CHECK(fetch_row  === 1'b0);
        `CHECK(fetch_col  === 1'b0);
        `CHECK(fifo_full  === 1'b0);
        `CHECK(done       === 1'b0);
        `CHECK(err        === 1'b0);
    end
    `CHECK(fifo_empty === 1'b0);
    `CHECK(fifo_head  ===    5);


    if (!test_failed) $display("****PASS");
    if (!test_failed) $display("PASS");

    //TODO waiting back at FETCH COL prob change the mem_line 


    if (!any_fail) print_all_passed_banner();
    $stop();
end

endmodule
