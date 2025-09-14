import testing_pkg::*;

module matrix_mult_tb();

localparam int N           = 2;
localparam int P           = 2;
localparam int M           = 2;
localparam int unsigned N_BIT_WIDTH = (N > 1) ? $clog2(N) : 1;
localparam int unsigned P_BIT_WIDTH = (P > 1) ? $clog2(P) : 1;
localparam int unsigned M_BIT_WIDTH = (M > 1) ? $clog2(M) : 1;
localparam int DATA_WIDTH  = 4;
localparam int ACCUM_WIDTH = 2*DATA_WIDTH;
localparam int FIFO_SIZE   = 3;

/**************************************************************************
***                      Testbench → DUT Inputs                         ***
**************************************************************************/
logic clk;
logic rst_n;

logic fetch_stall;
logic data_stall;

logic pop_fifo;
logic start;
logic [DATA_WIDTH-1:0] mem_line [0:N-1];

/**************************************************************************
***                      DUT → Testbench Outputs                        ***
**************************************************************************/
logic [N_BIT_WIDTH-1:0] n;
logic [M_BIT_WIDTH-1:0] m;
logic fetch_row;
logic fetch_col;
logic [ACCUM_WIDTH-1:0] fifo_head;
logic fifo_empty;
logic fifo_full;
logic done;
logic err;

/**************************************************************************
***                      Derived taps from DUT internals                ***
**************************************************************************/
logic load_row;
logic start_PE;
logic [1:0] PE_ready;

assign load_row = iDUT.load_row;
assign start_PE = iDUT.start_PE;
assign PE_ready = iDUT.PE_ready;

logic [DATA_WIDTH-1:0] results [0:(N*M)-1];

// Put near other decls
bit any_fail;
bit test_failed;

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
    .mem_line       (mem_line),
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
    mem_line     = '{default:'x};

    $display("\n******************** TEST 1: RESET ********************");
    test_failed = 1'b0;
    @(posedge clk);
    rst_n       = 1'b0;

    @(negedge clk);
    `CHECK(fifo_head  ===   '0);  // reset to 0
    `CHECK(n          ===   '0);  // reset to 0
    `CHECK(m          ===   '0);  // reset to 0
    `CHECK(fetch_row  === 1'b0);  // set low
    `CHECK(fetch_col  === 1'b0);  // set low
    `CHECK(fifo_empty === 1'b1);  // set high
    `CHECK(fifo_full  === 1'b0);  // set low
    `CHECK(done       === 1'b0);  // set low
    `CHECK(err        === 1'b0);  // set low
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
    mem_line    = {1, 2};

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

    $display("****PART 1");
    //Emsure we dont move after starting due to stalls
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
    if (!test_failed) $display("**PASS");

    @(negedge clk);
    start = '0; 

    $display("****PART 2");
    //Wait for long time
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
    if (!test_failed) $display("**PASS");
    if (!test_failed) $display("PASS");

    $display("\n******************** TEST 4: FETCH_STALL DROP AT ROW  ********************");
    test_failed = 1'b0;
    @(negedge clk);
    fetch_stall = '0; 

    $display("****PART 1");
    //First fetch should happen
    @(posedge fetch_row);
    `CHECK(fifo_head  ===   '0);
    `CHECK(n          ===   '0);
    `CHECK(m          ===   '0);
    `CHECK(fetch_row  === 1'b1);  // set high
    `CHECK(fetch_col  === 1'b0);
    `CHECK(fifo_empty === 1'b1);
    `CHECK(fifo_full  === 1'b0);
    `CHECK(done       === 1'b0);
    `CHECK(err        === 1'b0);
    if (!test_failed) $display("**PASS");

    // raising so further chip stalls later
    @(negedge clk);
    fetch_stall = 1'b1; 

    $display("****PART 2");
    //Ensure we stay static after due to data stall
    repeat ((N*M)*(N*M)) begin
        `CHECK(fifo_head  ===   '0);
        `CHECK(n          ===   '0);
        `CHECK(m          ===   '0);
        `CHECK(fetch_row  === 1'b0);  // dropped
        `CHECK(fetch_col  === 1'b0);
        `CHECK(fifo_empty === 1'b1);
        `CHECK(fifo_full  === 1'b0);
        `CHECK(done       === 1'b0);
        `CHECK(err        === 1'b0);
        @(negedge clk);
    end
    if (!test_failed) $display("**PASS");
    if (!test_failed) $display("PASS");

    $display("\n******************** TEST 5: DATA_STALL DROP TRIGGERS LOAD_ROW ********************");
    test_failed = 1'b0;
    @(negedge clk);
    data_stall = 1'b0; 

    $display("****PART 1");
    // data stall droped we should move foward
    @(posedge load_row);
    `CHECK(load_row   === 1'b1);  // set high
    `CHECK(fifo_head  ===   '0);
    `CHECK(n          ===   '0);
    `CHECK(m          ===   '0);
    `CHECK(fetch_row  === 1'b0);
    `CHECK(fetch_col  === 1'b0);
    `CHECK(fifo_empty === 1'b1);
    `CHECK(fifo_full  === 1'b0);
    `CHECK(done       === 1'b0);
    `CHECK(err        === 1'b0);
    if (!test_failed) $display("**PASS");

    // raising so further chip stalls later
    @(negedge clk);
    data_stall = 1'b1; 

    $display("****PART 2");
    // We remain in the same state
    repeat ((N*M)*(N*M)) begin
        `CHECK(load_row   === 1'b0);  // dropped
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
    if (!test_failed) $display("**PASS");
    if (!test_failed) $display("PASS");

    $display("\n******************** TEST 6: FETCH_STALL DROP AT COL ********************");
    test_failed = 1'b0;
    @(negedge clk);
    fetch_stall = 1'b0; 

    $display("****PART 1");
    @(posedge fetch_col);
    `CHECK(fifo_head  ===   '0);
    `CHECK(n          ===   '0);
    `CHECK(m          ===   '0);
    `CHECK(fetch_row  === 1'b0);
    `CHECK(fetch_col  === 1'b1);  // set high
    `CHECK(fifo_empty === 1'b1);
    `CHECK(fifo_full  === 1'b0);
    `CHECK(done       === 1'b0);
    `CHECK(err        === 1'b0);
    if (!test_failed) $display("**PASS");

    // raising so further chip stalls later
    @(negedge clk);
    fetch_stall = 1'b1; 

    $display("****PART 2");
    repeat ((N*M)*(N*M)) begin
        @(negedge clk);
        `CHECK(fifo_head  ===   '0);
        `CHECK(n          ===   '0);
        `CHECK(m          ===   '0);
        `CHECK(fetch_row  === 1'b0);
        `CHECK(fetch_col  === 1'b0);  // dropped
        `CHECK(fifo_empty === 1'b1);
        `CHECK(fifo_full  === 1'b0);
        `CHECK(done       === 1'b0);
        `CHECK(err        === 1'b0);
    end
    if (!test_failed) $display("**PASS");
    if (!test_failed) $display("PASS");

    $display("\n******************** TEST 7: DATA STALL DROP AT COL ********************");
    test_failed = 1'b0;
    @(negedge clk);
    data_stall = 1'b0; 

    $display("****PART 1");
    @(posedge start_PE);
    `CHECK(start_PE === 1'b1);   // set high
    `CHECK(fifo_head  ===   '0);
    `CHECK(n          ===   '0);
    `CHECK(m          ===   '0);
    `CHECK(fetch_row  === 1'b0);
    `CHECK(fetch_col  === 1'b0);
    `CHECK(fifo_empty === 1'b1);
    `CHECK(fifo_full  === 1'b0);
    `CHECK(done       === 1'b0);
    `CHECK(err        === 1'b0);
    if (!test_failed) $display("**PASS");

    //raise back so we force stall
    @(negedge clk);
    data_stall = 1'b1; 

    $display("****PART 2");
    @(negedge clk);
    `CHECK(start_PE === 1'b0);   // dropped
    `CHECK(fifo_head  ===   '0);
    `CHECK(n          ===   '0);
    `CHECK(m          ===    1); // incremented
    `CHECK(fetch_row  === 1'b0);
    `CHECK(fetch_col  === 1'b0);
    `CHECK(fifo_empty === 1'b1);
    `CHECK(fifo_full  === 1'b0);
    `CHECK(done       === 1'b0);
    `CHECK(err        === 1'b0);
    if (!test_failed) $display("**PASS");

    $display("****PART 3");
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
    `CHECK(fifo_empty === 1'b0); // dropped (became non-empty)
    `CHECK(fifo_head  ===    5); // updated (advanced)

    if (!test_failed) $display("**PASS");
    if (!test_failed) $display("PASS");

    $display("\n******************** TEST 8: go through next column ********************");
    test_failed = 1'b0;
    mem_line = {-1, 3};          // input update
    @(negedge clk);
    fetch_stall = 1'b0;          
    data_stall  = 1'b0;          

    $display("****PART 1");
    @(posedge fetch_col);
    `CHECK(fifo_head  ===    5);
    `CHECK(n          ===    0);
    `CHECK(m          ===    1);
    `CHECK(fetch_row  === 1'b0);
    `CHECK(fetch_col  === 1'b1); // set high
    `CHECK(fifo_empty === 1'b0);
    `CHECK(fifo_full  === 1'b0);
    `CHECK(done       === 1'b0);
    `CHECK(err        === 1'b0);
    if (!test_failed) $display("**PASS");

    $display("****PART 2");
    @(posedge start_PE);
    `CHECK(start_PE === 1'b1);   // set high
    `CHECK(fifo_head     ===    5);
    `CHECK(n             ===    0);
    `CHECK(m             ===    1);
    `CHECK(fetch_row     === 1'b0);
    `CHECK(fetch_col     === 1'b0);  // dropped
    `CHECK(fifo_empty    === 1'b0);
    `CHECK(fifo_full     === 1'b0);
    `CHECK(done          === 1'b0);
    `CHECK(err           === 1'b0);
    if (!test_failed) $display("**PASS");

    @(negedge clk);
    fetch_stall = 1'b1; 

    repeat (2) @(negedge clk);
    $display("****PART 3");
    `CHECK(start_PE === 1'b0);   // dropped
    `CHECK(fifo_head     ===    5);
    `CHECK(n             ===    1); // incremented
    `CHECK(m             ===    0); // reset to 0
    `CHECK(fetch_row     === 1'b0);
    `CHECK(fetch_col     === 1'b0);
    `CHECK(fifo_empty    === 1'b0);
    `CHECK(fifo_full     === 1'b0);
    `CHECK(done          === 1'b0);
    `CHECK(err           === 1'b0);
    if (!test_failed) $display("**PASS");

    $display("****PART 4");
    //Ensure everything stays constant while we wait till finish
    fork
            begin 
                while (!iDUT.PE_ready) begin
                    `CHECK(n          ===    1);
                    `CHECK(m          ===    0);
                    `CHECK(fetch_col  === 1'b0);
                    `CHECK(fetch_row  === 1'b0);
                    `CHECK(fifo_full  === 1'b0);
                    `CHECK(fifo_empty === 1'b0);
                    `CHECK(fifo_head  ===    5);
                    `CHECK(done       === 1'b0);
                    `CHECK(err        === 1'b0);
                    @(negedge clk);
                end
            end

            begin
                repeat (M*N*P) @(posedge clk);
            end
        join_any

        if (!iDUT.PE_ready) begin
            test_failed = 1'b1;
            any_fail    = 1'b1;
        end

    if (!test_failed) $display("**PASS");
    if (!test_failed) $display("PASS");

    $display("\n******************** TEST 9: Get next row ********************");
    test_failed = 1'b0;
    mem_line = {-8, -8};         // input update
    fetch_stall = 1'b0;          
    data_stall  = 1'b0;          

    // We should be getting fetching the next row
    $display("****PART 1");
    @(posedge fetch_row);

    `CHECK(fifo_head  ===    5);
    `CHECK(n          ===    1);
    `CHECK(m          ===    0);
    `CHECK(fetch_row  === 1'b1); // set high
    `CHECK(fetch_col  === 1'b0);
    `CHECK(fifo_empty === 1'b0);
    `CHECK(fifo_full  === 1'b0);
    `CHECK(done       === 1'b0);
    `CHECK(err        === 1'b0);
    if (!test_failed) $display("**PASS");

    //Now we should be loading 
    $display("****PART 2");
    @(posedge load_row);

    `CHECK(load_row === 1'b1);      // set high
    `CHECK(fifo_head     ===    5);
    `CHECK(n             ===    1);
    `CHECK(m             ===    0);
    `CHECK(fetch_row     === 1'b0);  // dropped
    `CHECK(fetch_col     === 1'b0);
    `CHECK(fifo_empty    === 1'b0);
    `CHECK(fifo_full     === 1'b0);
    `CHECK(done          === 1'b0);
    `CHECK(err           === 1'b0);
    if (!test_failed) $display("**PASS");

    $display("\n******************** TEST 10: Get next col ********************");
    
    @(posedge fetch_col);
    $display("****PART 1");
    `CHECK(load_row === 1'b0);      // dropped
    `CHECK(fifo_head     ===    5);
    `CHECK(n             ===    1);
    `CHECK(m             ===    0);
    `CHECK(fetch_row     === 1'b0);
    `CHECK(fetch_col     === 1'b1);  // set high
    `CHECK(fifo_empty    === 1'b0);
    `CHECK(fifo_full     === 1'b0);
    `CHECK(done          === 1'b0);
    `CHECK(err           === 1'b0);
    if (!test_failed) $display("**PASS");

    @(negedge clk);
    mem_line = {1, 2};              // input update

    @(posedge start_PE);
    $display("****PART 2");
    `CHECK(start_PE === 1'b1);      // set high
    `CHECK(fifo_head     ===    5);
    `CHECK(n             ===    1);
    `CHECK(m             ===    0);
    `CHECK(fetch_row     === 1'b0);
    `CHECK(fetch_col     === 1'b0);  // dropped
    `CHECK(fifo_empty    === 1'b0);
    `CHECK(fifo_full     === 1'b0);
    `CHECK(done          === 1'b0);
    `CHECK(err           === 1'b0);
    if (!test_failed) $display("**PASS");

    @(negedge clk);
    fetch_stall = 1'b1; 

    repeat (2) @(negedge clk);
    $display("****PART 3");
    `CHECK(start_PE === 1'b0);      // dropped
    `CHECK(fifo_head     ===    5);
    `CHECK(n             ===    1);
    `CHECK(m             ===    1);  // incremented
    `CHECK(fetch_row     === 1'b0);
    `CHECK(fetch_col     === 1'b0);
    `CHECK(fifo_empty    === 1'b0);
    `CHECK(fifo_full     === 1'b0);
    `CHECK(done          === 1'b0);
    `CHECK(err           === 1'b0);
    if (!test_failed) $display("**PASS");
    
    $display("****PART 4");
    //Ensure everything stays constant while we wait till finish
    fork
        begin
            while (!iDUT.PE_ready) begin
            `CHECK(n          ===    1);
            `CHECK(m          ===    1);
            `CHECK(fetch_col  === 1'b0);
            `CHECK(fetch_row  === 1'b0);
            `CHECK(fifo_full  === 1'b0);
            `CHECK(fifo_empty === 1'b0);
            `CHECK(fifo_head  ===    5);
            `CHECK(done       === 1'b0);
            `CHECK(err        === 1'b0);
            @(negedge clk);
            end
        end

        begin
            repeat (M*N*P) @(posedge clk);
        end
    join_any

    if (!iDUT.PE_ready) begin
        test_failed = 1'b1;
        any_fail    = 1'b1;
    end

    $display("\n******************** TEST 11: FIFO stall behavior ********************");
    $display("****PART 1");
    @(posedge fifo_full);
    //Testing that fifo is full
    `CHECK(fifo_head     ===    5);
    `CHECK(n             ===    1);
    `CHECK(m             ===    1);
    `CHECK(fetch_row     === 1'b0);
    `CHECK(fetch_col     === 1'b0);
    `CHECK(fifo_empty    === 1'b0);
    `CHECK(fifo_full     === 1'b1);  // set high
    `CHECK(done          === 1'b0);
    `CHECK(err           === 1'b0);
    if (!test_failed) $display("**PASS");

    $display("****PART 2");
    repeat (M*N*P) begin
        @(negedge clk);
        `CHECK(fifo_head     ===    5);
        `CHECK(n             ===    1);
        `CHECK(m             ===    1);
        `CHECK(fetch_row     === 1'b0);
        `CHECK(fetch_col     === 1'b0);
        `CHECK(fifo_empty    === 1'b0);
        `CHECK(fifo_full     === 1'b1);
        `CHECK(done          === 1'b0);
        `CHECK(err           === 1'b0);
    end

    @(negedge clk);
    pop_fifo = 1'b1; 

    @(negedge clk);
    pop_fifo = 1'b0; 

    if (!test_failed) $display("**PASS");
    if (!test_failed) $display("PASS");

    $display("\n******************** TEST 12: Get last col ********************");
    test_failed = 1'b0;
    mem_line =  {-8, -8};        // input update
    fetch_stall = 1'b0;          
    data_stall  = 1'b0;          

    @(posedge fetch_col);
    $display("****PART 1");
    `CHECK(load_row === 1'b0);   // dropped (from earlier test when it was high)
    `CHECK(fifo_head  ===    5);
    `CHECK(n          ===    1);
    `CHECK(m          ===    1);
    `CHECK(fetch_row  === 1'b0);
    `CHECK(fetch_col  === 1'b1); // set high
    `CHECK(fifo_empty === 1'b0);
    `CHECK(fifo_full  === 1'b0);
    `CHECK(done       === 1'b0);
    `CHECK(err        === 1'b0);
    if (!test_failed) $display("**PASS");

    @(posedge start_PE);
    $display("****PART 2");
    `CHECK(start_PE === 1'b1);   // set high
    `CHECK(fifo_head     ===    5);
    `CHECK(n             ===    1);
    `CHECK(m             ===    1);
    `CHECK(fetch_row     === 1'b0);
    `CHECK(fetch_col     === 1'b0);  // dropped
    `CHECK(fifo_empty    === 1'b0);
    `CHECK(fifo_full     === 1'b0);
    `CHECK(done          === 1'b0);
    `CHECK(err           === 1'b0);
    if (!test_failed) $display("**PASS");

    repeat (3) @(negedge clk);
    $display("****PART 3");
    `CHECK(start_PE      === 1'b0); // dropped
    `CHECK(fifo_head     ===    5);
    `CHECK(n             ===    1);
    `CHECK(m             ===    1);
    `CHECK(fetch_row     === 1'b0);
    `CHECK(fetch_col     === 1'b0);
    `CHECK(fifo_empty    === 1'b0);
    `CHECK(fifo_full     === 1'b0);
    `CHECK(done          === 1'b0);
    `CHECK(err           === 1'b0);
    if (!test_failed) $display("**PASS");
    
    $display("****PART 4");
    @(posedge iDUT.PE_ready[1]);
    repeat(2) @(negedge clk);
    `CHECK(fifo_head     ===    5);
    `CHECK(n             ===    1);
    `CHECK(m             ===    1);
    `CHECK(fetch_row     === 1'b0);
    `CHECK(fetch_col     === 1'b0);
    `CHECK(fifo_empty    === 1'b0);
    `CHECK(fifo_full     === 1'b1); // set high
    `CHECK(done          === 1'b1); // set high
    `CHECK(err           === 1'b1); // set high
    if (!test_failed) $display("**PASS");
    if (!test_failed) $display("PASS");

    $display("\n******************** TEST 12: Check result matrix ********************");
    results = {5, 5, -24, 2}; //last entry should be 98 but since we overflow
    for(int i = 1; i < m*n; i++) begin
        `CHECK(fifo_head === results[i]); // compare (expected sequence)
        @(negedge clk);
        pop_fifo = 1'b1;       
        @(negedge clk);
        pop_fifo = 1'b0;                  
    end

    if (!any_fail) print_all_passed_banner();
    $stop();
end

endmodule
