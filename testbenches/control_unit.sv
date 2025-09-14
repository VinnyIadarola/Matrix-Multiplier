import testing_pkg::*;

/**************************************************************************
***                            Testbench Top                             ***
**************************************************************************/
module control_unit_tb();

  /**************************************************************************
  ***                                Params                                ***
  **************************************************************************/
  parameter int N = 2;
  parameter int M = 2;

  /**************************************************************************
  ***                             Declarations                             ***
  **************************************************************************/
  // Basic Inputs
  logic clk;
  logic rst_n;

  // Control Inputs
  logic start;
  logic mem_stall;
  logic fifo_full;
  logic PE_ready;

  // Control Outputs
  logic start_PE;
  logic done;
  logic load_row;

  int i, j;

  /**************************************************************************
  ***                        Devices Under Testing                         ***
  **************************************************************************/
  control_unit #(
      .N (N),
      .M (M)
  ) iDUT (
      // Basic Inputs
      .clk      (clk),
      .rst_n    (rst_n),

      // Control Inputs
      .start    (start),
      .mem_stall(mem_stall),
      .fifo_full(fifo_full),
      .PE_ready (PE_ready),

      // Control Outputs
      .start_PE (start_PE),
      .done     (done),
      .load_row (load_row)
  );

  /**************************************************************************
  ***                           Clock / Reset Gen                          ***
  **************************************************************************/
  always #5 clk = ~clk;

  /**************************************************************************
  ***                          Safety Assertions (SVA)                     ***
  **************************************************************************/
  // Functional guards you requested
  property p_no_load_row_when_memstall;
    @(posedge clk) disable iff (!rst_n)
      mem_stall |-> !load_row;
  endproperty
  ap_no_load_row_when_memstall: assert property (p_no_load_row_when_memstall)
    else begin $error("load_row asserted while mem_stall=1 @%0t", $time); $stop; end

  property p_no_startpe_when_blocked;
    @(posedge clk) disable iff (!rst_n)
      (mem_stall || fifo_full) |-> !start_PE;
  endproperty
  ap_no_startpe_when_blocked: assert property (p_no_startpe_when_blocked)
    else begin $error("start_PE asserted while mem_stall=1 or fifo_full=1 @%0t", $time); $stop; end

  /**************************************************************************
  ***               Timing Discipline Checkers (edges you asked)           ***
  **************************************************************************/
  // rst_n only changes on posedges of clk
  property p_rst_no_change_on_negedge;
    @(negedge clk) !$changed(rst_n);
  endproperty
  ap_rst_no_change_on_negedge: assert property (p_rst_no_change_on_negedge)
    else begin $error("rst_n changed on negedge @%0t", $time); $stop; end

  // All other TB-driven controls only change on negedges of clk
  property p_ctrl_no_change_on_posedge;
    @(posedge clk) !$changed({start, mem_stall, fifo_full, PE_ready});
  endproperty
  ap_ctrl_no_change_on_posedge: assert property (p_ctrl_no_change_on_posedge)
    else begin $error("TB control changed on posedge @%0t", $time); $stop; end

  /**************************************************************************
  ***                               Test Plan                              ***
  **************************************************************************/
  initial begin
    // ---------------- Power-on defaults ----------------
    clk       = 1'b1;

    rst_n     = 1'b1;
    start     = 'x;
    mem_stall = 'x;
    fifo_full = 'x;
    PE_ready  = 'x;

    @(posedge clk);  rst_n = 1'b0;

    repeat (2) @(posedge clk);
    repeat (2) @(negedge clk);
    assert (start_PE == 0) else begin $error("start_PE is not 0 at reset"); $stop; end
    assert (done     == 0) else begin $error("done is not 0 at reset");     $stop; end
    assert (load_row == 0) else begin $error("load_row is not 0 at reset"); $stop; end

    @(posedge clk);  rst_n = 1'b1;

    @(negedge clk);
    start     = 1'b1;
    mem_stall = 1'b0;
    fifo_full = 1'b0;
    PE_ready  = 1'b1;

    /**************************************************************************
    ***                      Test Suite 1: Smoke / Run-through              ***
    **************************************************************************/
    $display("test 1: general run-through");
    fork
      begin
        for (i = 0; i < N; i++) begin
          wait (i == iDUT.n);
          for (j = 0; j < M; j++) begin
            wait (j == iDUT.m);
          end
        end
        @(posedge done);
        disable meow;
      end

      begin : meow
        @(negedge clk) start = 1'b0; 
        repeat (N*M + 20) @(posedge clk);
        $display("stalled out");
        $stop();
      end
    join
    $display("pass test 1");

    /**************************************************************************
    ***                Interlude: Soft Reset Between Testcases              ***
    **************************************************************************/
    $display("soft reset between tests");

    @(negedge clk);
    start      = 1'b0;
    mem_stall  = 1'b0;
    fifo_full  = 1'b0;
    PE_ready   = 1'b0;

    @(posedge clk); rst_n = 1'b0;
    repeat (2) @(posedge clk);
    @(posedge clk); rst_n = 1'b1;

    /**************************************************************************
    ***   Test Suite 2: mem_stall prevents load_row and starting the PE     ***
    **************************************************************************/
    $display("test 2: mem_stall should block load_row and start_PE");

    // Drive stimulus on NEGEDGE
    @(negedge clk);
    start      = 1'b1;
    PE_ready   = 1'b1;   // ready, but mem_stall should still block
    fifo_full  = 1'b0;
    mem_stall  = 1'b1;

    repeat (8) begin
      @(posedge clk);
      assert (load_row == 1'b0) else begin
        $error("load_row asserted during mem_stall @%0t", $time); $stop;
      end
      assert (start_PE == 1'b0) else begin
        $error("start_PE asserted during mem_stall @%0t", $time); $stop;
      end
    end

    // Release stall on NEGEDGE and confirm forward progress resumes
    @(negedge clk) mem_stall  = 1'b0;

    fork
      begin : wait_progress
        wait (start_PE || load_row);
        disable timeout2;
      end
      begin : timeout2
        repeat (20) @(posedge clk);
        $error("No progress after clearing mem_stall"); $stop;
      end
    join_any
    disable fork;
    $display("pass test 2");

    /**************************************************************************
    ***      Test Suite 3: fifo_full prevents starting the PE (gating)      ***
    **************************************************************************/
    $display("test 3: fifo_full should block start_PE");

    @(negedge clk);
    start      = 1'b0;
    PE_ready   = 1'b0;
    mem_stall  = 1'b0;
    fifo_full  = 1'b0;

    @(posedge clk) rst_n = 1'b0;
    repeat (2) @(posedge clk);
    @(posedge clk) rst_n = 1'b1;

    @(negedge clk);
    start      = 1'b1;
    PE_ready   = 1'b1;
    mem_stall  = 1'b0;
    fifo_full  = 1'b1;

    repeat (8) begin
      @(posedge clk);
      assert (start_PE == 1'b0) else begin
        $error("start_PE asserted while fifo_full=1 @%0t", $time); $stop;
      end
    end

    @(negedge clk) fifo_full  = 1'b0;

    fork
      begin : wait_start
        wait (start_PE);
        disable timeout3;
      end
      begin : timeout3
        repeat (20) @(posedge clk);
        $error("start_PE never asserted after clearing fifo_full"); $stop;
      end
    join_any
    disable fork;
    $display("pass test 3");

    print_all_passed_banner();
  end

endmodule
