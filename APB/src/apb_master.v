module apb_master(
	input [7:0] apb_write_paddr,
	input [7:0] apb_read_paddr,
	input [7:0] apb_pwdata,prdata,
	input pclk,presetn,read_write,transfer,pready,

	output reg[7:0] paddr,
	output reg [7:0] pwdata,apb_read_dataout,
	output  psel1,psel2,psel3,pslverr,
	output reg penable,pwrite,
        output pdone); //read_write= 0(write) and 1(read)

  reg invalid_setup_error,
      setup_error,
      invalid_read_paddr,
      invalid_write_paddr,
      invalid_write_data ;


parameter IDLE =2'b00,
	SETUP=2'b01,
	ENABLE=2'b10;

reg [1:0] state,nxt_state;

always@(posedge pclk)begin
	if(!presetn)
		state<=IDLE;
	else
		state<=nxt_state;
end

always@(transfer,state,pready) begin
	if(!presetn)begin
		nxt_state=IDLE;
	end
	pwrite= ~read_write;

	case(state) 
		IDLE: begin
			penable=0;
                        if(transfer) begin
				nxt_state=SETUP;
			end else begin
				nxt_state=IDLE;
			end
		end

		SETUP: begin
			penable=0;
			if(read_write) begin
				paddr=apb_read_paddr;
			end else begin
				paddr=apb_write_paddr;
				pwdata=apb_pwdata;
			end

			if(transfer) begin
				nxt_state=ENABLE;
			end else begin
				nxt_state=IDLE;
			end
		end
		
		ENABLE: begin
			if(psel1 || psel2 || psel3) begin
				penable=1;
			end
			if(transfer) begin
			     if(pready) begin //Have to check
					if(read_write) begin
						apb_read_dataout=prdata;
						if(apb_read_dataout==0) begin
							nxt_state=ENABLE;
						end else begin
							nxt_state=IDLE;
						end
					end
					else begin
						nxt_state=SETUP;
					end
				end else begin
					nxt_state=ENABLE;
				end
			end else begin
				nxt_state=IDLE;
			end
		end
	endcase
end
assign {psel1, psel2, psel3} = 
    (state != IDLE) ? 
        (paddr[7:4] == 4'b0000) ? 3'b100 :
        (paddr[7:4] == 4'b0001) ? 3'b010 :
        (paddr[7:4] == 4'b0010) ? 3'b001 :
                                  3'b000
    : 3'b000;

assign pdone=pready;
 // PSLVERR LOGIC
  
  always @(*) begin
        if(!presetn)
	    begin 
	     setup_error =0;
	     invalid_setup_error=0;
	     invalid_read_paddr = 0;
	     invalid_write_paddr = 0;
	     invalid_write_data =0 ;
	    end
        else
	 begin	
          begin
	  if(state == IDLE && nxt_state == ENABLE)
   		  setup_error = 1;
	  else setup_error = 0;
          end
          begin
          if((apb_pwdata===8'dx) && (!read_write) && (state==SETUP || state==ENABLE))
		  invalid_write_data =1;
	  else invalid_write_data= 0;
          end
          begin
	  if((apb_read_paddr===9'dx) && read_write && (state==SETUP || state==ENABLE))
		  invalid_read_paddr = 1;
	  else  invalid_read_paddr = 0;
          end
          begin
          if((apb_write_paddr===9'dx) && (!read_write) && (state==SETUP || state==ENABLE))
		  invalid_write_paddr =1;
          else invalid_write_paddr =0;
          end
          begin
	  if(state == SETUP)
            begin
                 if(pwrite)
                      begin
                         if(paddr==apb_write_paddr && pwdata==apb_pwdata)
                              setup_error=1'b0;
                         else
                               setup_error=1'b1;
                       end
                 else 
                       begin
                          if (paddr==apb_read_paddr)
                                 setup_error=1'b0;
                          else
                                 setup_error=1'b1;
                       end    
              end 
          
         else setup_error=1'b0;
         end 
       end
       invalid_setup_error = setup_error ||  invalid_read_paddr || invalid_write_data || invalid_write_paddr  ;
     end 

   assign pslverr =  invalid_setup_error ;

	 

 endmodule


