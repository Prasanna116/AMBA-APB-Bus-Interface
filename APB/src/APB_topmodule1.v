module APB_topmodule1 #(parameter clk_rate=1000000000, parameter baud_rate=9600) (
	input pclk,
	input presetn,
	input [7:0] wr_data,
	input [7:0] wr_addr,
	input [7:0] rd_addr,
	input read_write,
	input transfer,
	
	output [7:0] final_pr_data,
	output plsverr,
        output pdone,
        inout [7:0] gpio_pins);
// For Uart RX, the input signal rx is taken from the tx output for simulation purposes

	wire [7:0] prdata_mem, prdata_gpio,prdata_uart;
	wire psel_mem,psel_gpio,psel_uart;

	wire pready_mem,pready_gpio,pready_uart;

	// Simple address decoding
       // assign psel_mem  = (m_paddr[7:4] == 4'h0);
       // assign psel_gpio = (m_paddr[7:4] == 4'h1);
       wire [7:0] prdata_slave;
       wire prready_slave;
       wire [7:0] paddr;
       wire [7:0] pwdata;
       wire penable,pwrite;

        apb_master utt(
        .apb_write_paddr(wr_addr),
        .apb_read_paddr(rd_addr),
        .apb_pwdata(wr_data),
       	.prdata(prdata_slave),
        .pclk(pclk),
	.presetn(presetn),
	.read_write(read_write),
	.transfer(transfer),
	.pready(pready_slave),
        .paddr(paddr),
        .pwdata(pwdata),
	.apb_read_dataout(final_pr_data),
        .psel1(psel_mem),
	.psel2(psel_gpio),
	.psel3(psel_uart),
	.pslverr(pslverr),
        .penable(penable),
	.pwrite(pwrite),
        .pdone(pdone)); //read_write= 0(write) and 1(read)

       apb_slave1 stt(
        .pclk(pclk),
        .presetn(presetn),
        .paddr(paddr),
        .pw_data(pwdata),
        .psel(psel_mem),
	.penable(penable),
	.pwrite(pwrite),
        .prdata(prdata_mem),
        .pready(pready_mem));

wire [7:0] gpio_i,gpio_o,gpio_dir;

       apb_slave2 stt1(
        .pclk(pclk),
        .presetn(presetn),
        .paddr(paddr),
        .pw_data(pwdata),
        .psel(psel_gpio),
        .penable(penable),
        .pwrite(pwrite),
        .prdata(prdata_gpio),
        .pready(pready_gpio),
        .gpio_i(gpio_i),
        .gpio_o(gpio_o),
        .gpio_dir(gpio_dir));

wire rx,tx;
      apb_slave3 #(.CLK_RATE(clk_rate),.BAUD_RATE(baud_rate)) stt2(
        .pclk(pclk),
        .presetn(presetn),
        .psel(psel_uart),
        .penable(penable),
        .pwrite(pwrite),
        .paddr(paddr),
        .pw_data(pwdata),
        .prdata(prdata_uart),
        .pready(pready_uart),
        .rx(rx),
        .tx(tx));
        
genvar i;
generate
	for(i=0;i<8;i=i+1)begin
		assign gpio_i[i]=gpio_pins[i];
		assign gpio_pins[i]= (gpio_dir[i]) ? gpio_o[i] : 1'bz;
	end
endgenerate


 // Multiplex slave responses back to master
       assign prdata_slave = ((psel_mem) ? prdata_mem : ((psel_gpio) ? prdata_gpio : ((psel_uart) ? prdata_uart : 8'b0)));
       assign pready_slave = ((psel_mem) ? pready_mem : ((psel_gpio) ? pready_gpio : ((psel_uart) ? pready_uart : 1'b0)));

endmodule
