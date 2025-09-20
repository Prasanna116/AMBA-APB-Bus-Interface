module apb_slave1 (
    input        pclk,
    input        presetn,
    input  [7:0] paddr,
    input  [7:0] pw_data,
    input        psel,
    input        penable,
    input        pwrite,

    output [7:0] prdata,
    output reg   pready
);

parameter IDLE   = 2'b00,
          SETUP  = 2'b01,
          ACCESS = 2'b10;

reg [1:0] state, nxt_state;
reg [7:0] regi_addr;
reg [7:0] mem [63:0];

// Sequential state update
always @(posedge pclk) begin
    if (!presetn)
        state <= IDLE;
    else
        state <= nxt_state;
end

// Sequential memory write
always @(posedge pclk) begin
    if (pwrite && state == ACCESS && psel && penable)
        mem[paddr] <= pw_data;
    else if (!pwrite && state == ACCESS && psel && penable)
        regi_addr <= paddr;
end

// Combinational next state & pready
always @(*) begin
    nxt_state = state;  // default stay
    pready    = 0;

    case (state)
        IDLE: begin
            if (psel)
                nxt_state = SETUP;
        end

        SETUP: begin
            if (penable) begin
                pready    = 1;
                nxt_state = ACCESS;
            end
        end

        ACCESS: begin
            pready    = 1;
            nxt_state = IDLE; // Return to idle after access
        end
    endcase
end

assign prdata = mem[regi_addr];

endmodule
