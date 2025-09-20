module apb_slave2(
    input  wire        pclk,
    input  wire        presetn,
    input  wire [7:0]  paddr,
    input  wire [7:0]  pw_data,
    input  wire        psel,
    input  wire        penable,
    input  wire        pwrite,
    output reg  [7:0]  prdata,
    output reg         pready,

    // GPIO
    input  wire [7:0]  gpio_i,
    output reg  [7:0]  gpio_o,
    output reg  [7:0]  gpio_dir
);

    // Internal registers
    reg [7:0] dir_reg, in_reg, out_reg;

    // Address map
    localparam DIRECTION = 8'h10,
               INPUT     = 8'h11,
               OUTPUT    = 8'h12;

    // State machine
    parameter IDLE=2'b00,
	    SETUP=2'b01,
	    ACCESS=2'b10;

    reg[1:0] state, nxt_state;

    // FSM State update
    always @(posedge pclk or negedge presetn) begin
        if (!presetn)
            state <= IDLE;
        else
            state <= nxt_state;
    end

    // FSM Next state logic and pready
    always @(*) begin
        nxt_state = state;
        pready    = 1'b0;

        case (state)
            IDLE: begin
                if (psel)
                    nxt_state = SETUP;
            end

            SETUP: begin
                if (penable) begin
                    pready    = 1'b1;
                    nxt_state = ACCESS;
                end
            end

            ACCESS: begin
                nxt_state = IDLE;
            end
        endcase
    end

    // Read GPIO input on every clock
    always @(posedge pclk or negedge presetn) begin
        if (!presetn)
            in_reg <= 8'h00;
        else
            in_reg <= gpio_i;
    end

    // Main APB Access logic
    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            dir_reg  <= 8'h00;
            out_reg  <= 8'h00;
            prdata   <= 8'h00;
        end else if (state == ACCESS) begin
            if (pwrite) begin
                case (paddr)
                    DIRECTION: dir_reg <= pw_data;
                    OUTPUT:    out_reg <= pw_data;
                endcase
            end else begin
                case (paddr)
                    DIRECTION: prdata <= dir_reg;
                    INPUT:     prdata <= in_reg;
                    OUTPUT:    prdata <= out_reg;
                    default:   prdata <= 8'h00;
                endcase
            end
        end
    end

    // Output assignments
    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            gpio_dir <= 8'h00;
            gpio_o   <= 8'h00;
        end else begin
            gpio_dir <= dir_reg;
            gpio_o   <= out_reg;
        end
    end

endmodule






	
