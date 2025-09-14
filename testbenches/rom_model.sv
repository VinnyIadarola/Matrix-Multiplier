`default_nettype none

module rom_model #(
    parameter int DATA_WIDTH   = 16,
    parameter int LINE_LEN     = 16,     // number of words per "line" (output array length)
    parameter int MEM_DEPTH    = 256,    // ROM depth (words)
    parameter int MAX_STALL    = 5,      // max random stall cycles between line grabs
    parameter      MEMFILE     = ""      // optional $readmemh file
) (
    input  wire                          clk,
    input  wire                          rst_n,

    // Request to grab a line into the output array register; honored only when ready=1
    input  wire                          fetch,

    // If addr_use_ext==1 during an accepted fetch, addr_ext is the starting ROM address.
    input  wire                          addr_use_ext,
    input  wire [$clog2(MEM_DEPTH)-1:0]  addr_ext,

    // Status / visibility
    output wire                          ready,       // can accept fetch this cycle
    output wire                          line_valid,  // 1-cycle pulse when line_out is updated
    output wire [$clog2(MEM_DEPTH)-1:0]  used_addr,   // start addr used for the most recent line

    // Output array register: LINE_LEN words wide
    output logic [DATA_WIDTH-1:0]        line_out [0:LINE_LEN-1]
);

    /**********************************************************************
    ******                         ROM Storage                        ******
    **********************************************************************/
    logic [DATA_WIDTH-1:0] rom [0:MEM_DEPTH-1];
    initial begin
        if (MEMFILE != "") begin
            $readmemh(MEMFILE, rom);
        end else begin
            int k;
            for (k = 0; k < MEM_DEPTH; k++) rom[k] = DATA_WIDTH'(k);
        end
    end

    /**********************************************************************
    ******                Variable Stall Between Fetches              ******
    **********************************************************************/
    localparam int AW = (MEM_DEPTH <= 1) ? 1 : $clog2(MEM_DEPTH);

    logic [AW-1:0] addr_seq_q;       // sequential line-start address (when not using external)
    logic [AW-1:0] used_addr_q;      // latched start address used on the accepted fetch
    logic                         line_valid_q;
    logic [$clog2(MAX_STALL+1)-1:0] stall_cnt;

    assign used_addr  = used_addr_q;
    assign line_valid = line_valid_q;
    assign ready      = (stall_cnt == '0);

    // Accept a fetch only when ready
    wire accept_fetch = fetch && ready;

    // Random stall control
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stall_cnt <= '0;
        end else if (accept_fetch) begin
            stall_cnt <= (MAX_STALL == 0) ? '0 : $urandom_range(0, MAX_STALL);
        end else if (stall_cnt != '0) begin
            stall_cnt <= stall_cnt - 1'b1;
        end
    end

    // Address helpers (wrap-around)
    function automatic [AW-1:0] addr_add(input [AW-1:0] a, input int unsigned b);
        int unsigned tmp;
        begin
            tmp = a + b;
            addr_add = tmp % MEM_DEPTH;
        end
    endfunction

    // Latch the address used for the fetch
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            used_addr_q <= '0;
        end else if (accept_fetch) begin
            used_addr_q <= addr_use_ext ? addr_ext : addr_seq_q;
        end
    end

    // Advance sequential start address by a whole line when we auto-sequence
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_seq_q <= '0;
        end else if (accept_fetch && !addr_use_ext) begin
            addr_seq_q <= addr_add(addr_seq_q, LINE_LEN);
        end
    end

    // Output array register update + valid pulse
    integer i;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            line_valid_q <= 1'b0;
            for (i = 0; i < LINE_LEN; i++) line_out[i] <= '0;
        end else begin
            line_valid_q <= 1'b0;
            if (accept_fetch) begin
                for (i = 0; i < LINE_LEN; i++) begin
                    line_out[i] <= rom[addr_add(addr_use_ext ? addr_ext : addr_seq_q, i)];
                end
                line_valid_q <= 1'b1;
            end
        end
    end

endmodule

`default_nettype wire
