module apb_slave3 #(
    parameter CLK_RATE  = 10000000000,
    parameter BAUD_RATE = 9600
)(
    input  wire       pclk,
    input  wire       presetn,
    input  wire       psel,
    input  wire       penable,
    input  wire       pwrite,
    input  wire [7:0] paddr,
    input  wire [7:0] pw_data,

    output reg  [7:0] prdata,
    output reg        pready,

    input  wire       rx,
    output wire       tx
);

    // --------------------
    // Local parameters
    // --------------------
    parameter  IDLE   = 2'b00,
               SETUP  = 2'b01,
               ACCESS = 2'b10;

    parameter TX_DATA_REG = 8'h20,
               RX_DATA_REG = 8'h21,
               STATUS_REG  = 8'h22;

    // --------------------
    // State registers
    // --------------------
    reg [1:0] state, nxt_state;

    // --------------------
    // Internal regs
    // --------------------
    reg        t_start;
    wire        t_busy;
    reg [7:0]  tx_reg;
    wire [7:0] rx_reg;
    wire       r_stop;
    wire uart_ack;

    // --------------------
    // UART core instance
    // --------------------
    Uart_TopModule #(
        .clk_rate(CLK_RATE),
        .baud_rate(BAUD_RATE)
    ) uart_core (
        .clk       (pclk),
        .rst       (presetn),
        .data      (tx_reg),
        .t_start   (t_start),
        .tx_out    (tx),
        .t_busy    (t_busy),
        .rx_data_out(rx_reg),
        .r_stop    (r_stop),
        .uart_ack  (uart_ack)
    );

    // --------------------
    // FSM: state update
    // --------------------
    always @(posedge pclk or negedge presetn) begin
        if (!presetn)
            state <= IDLE;
        else
            state <= nxt_state;
    end

    // --------------------
    // FSM: next state
    // --------------------
    always @(*) begin
        case (state)
            IDLE:   nxt_state = (psel) ? SETUP : IDLE;
            SETUP:  nxt_state = (penable) ? ACCESS : SETUP;
            ACCESS: nxt_state = IDLE;
            default:nxt_state = IDLE;
        endcase
    end

    // --------------------
    // APB access logic
    // --------------------
    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            pready  <= 0;
            prdata  <= 8'h00;
            tx_reg  <= 8'h00;
            t_start <=1'b0;
        end else begin
            pready  <= 0;   // default

            if (state == ACCESS) begin
                pready <= 1;
                if (pwrite) begin
                    if (paddr == TX_DATA_REG) begin
                       if(t_start==0) begin
                        tx_reg  <= pw_data;
                        t_start <= 1'b1;
                        end
                        
                    end
                end else begin
                    case (paddr)
                        RX_DATA_REG: prdata <= rx_reg;
                        STATUS_REG:  prdata <= {6'b0, r_stop, uart_core.t1.t_busy};
                        default:     prdata <= 8'h00;
                    endcase
                end
            end
        end
    end
    
    always@(posedge pclk or negedge presetn) begin
    if(uart_ack && t_start ) begin
    t_start <=0;
    end
    end
    

endmodule
