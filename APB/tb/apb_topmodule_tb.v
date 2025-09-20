`timescale 1ns/1ps

module apb_topmodule_tb;

    reg pclk, presetn;
    reg [7:0] wr_addr, rd_addr;
    reg [7:0] wr_data;
    reg transfer, read_write;

    wire [7:0] final_pr_dataout;
    wire pdone, plsverr;
    wire [7:0] gpio_pins;

    // TB driver for inout
   

    reg [7:0] tb_gpio_drive;
    reg  tb_gpio_drive_en; // enable driving
    assign gpio_pins =(tb_gpio_drive_en) ?  tb_gpio_drive: 8'bz;

    // Instantiate DUT
    APB_topmodule1 dut (
        .pclk(pclk),
        .presetn(presetn),
        .wr_data(wr_data),
        .wr_addr(wr_addr),
        .rd_addr(rd_addr),
        .read_write(read_write),
        .transfer(transfer),
        .final_pr_data(final_pr_dataout),
        .plsverr(plsverr),
        .pdone(pdone),
        .gpio_pins(gpio_pins)
    );

    // Clock generation
    always #5 pclk = ~pclk;

    initial begin
	 // Dump file for GTKWave
        $dumpfile("apb_topmodule.vcd");
        $dumpvars(0, apb_topmodule_tb);
        pclk      = 0;
        presetn   = 0;
        wr_addr   = 0;
        rd_addr   = 0;
        wr_data   = 0;
        transfer  = 0;
        read_write= 0;
        tb_gpio_drive = 8'h00;
	tb_gpio_drive_en=0;

        #10;
        presetn = 1;

        // WRITE TO MEMORY
        @(posedge pclk);
        read_write = 0; // WRITE
        wr_data    = 8'hAF;
        wr_addr    = 8'b00001011; // example mem address
        transfer   = 1'b1;


        #30;
        transfer   = 1'b0;
       

        // WRITE TO GPIO direction
        @(posedge pclk);
        read_write = 0; 
        wr_data    = 8'h0F;  // lower nibble output
        wr_addr    = 8'b00010000; // dir register
        transfer   = 1'b1;


        #30;
        transfer   = 1'b0;
   

        // WRITE to GPIO output register
       @(posedge pclk);
        read_write = 0;
        wr_data    = 8'h2A; // The output is fA
        wr_addr    = 8'b00010010; // output reg
        transfer   = 1'b1;
        
	#30;
        transfer   = 1'b0;
        #70;
        @(posedge pclk);
	presetn=0;
	#5;
	presetn=1;
        // Simulate external device driving GPIO
        tb_gpio_drive = 8'hCD; // drive inputs
	tb_gpio_drive_en=1;
       

      //   READ from GPIO input register
        @(posedge pclk);
        read_write = 1; 
        rd_addr    = 8'b00010001; // input reg
        transfer   = 1'b1;
        #50;
	tb_gpio_drive_en=0;
	#20;
        transfer   = 1'b0;
      
        $display("Read GPIO Data: %h", final_pr_dataout);

     //   WRITE TO UART
        @(posedge pclk);
	read_write=0;
	wr_data=8'hAB;
	wr_addr=8'b00100000;
	transfer=1'b1;

	#40;
	transfer = 1'b0;

        #24000000;

    //  READ FROM UART
        @(posedge pclk);
	read_write=1;
	rd_addr=8'b00100001;
	transfer=1'b1;

	#100
	transfer=1'b0;

	#1000000;

        $finish;
    end

endmodule
