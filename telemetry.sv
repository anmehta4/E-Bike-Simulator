module telemetry(clk, rst_n, batt_v, avg_curr, avg_torque, TX);

input clk, rst_n;
input [11:0] batt_v, avg_curr, avg_torque;
output TX;

logic [7:0]tx_data;
logic init, trmt, done_t, tx_done;
logic [2:0] byte_num;
logic [19:0] count;


always_comb begin
   //Determine which byte to tranmit based on byte_num
   case(byte_num) 
      3'b000: tx_data = 8'hAA;
      3'b001: tx_data = 8'h55;
      3'b010: tx_data = {4'h0,batt_v[11:8]};
      3'b011: tx_data = batt_v[7:0];
      3'b100: tx_data = {4'h0,avg_curr[11:8]};
      3'b101: tx_data = avg_curr[7:0];
      3'b110: tx_data = {4'h0,avg_torque[11:8]};
      3'b111: tx_data = avg_torque[7:0];
   endcase
  
   //done_t is asstered once all 8 bytes are transmitted
   done_t = &count;
end

/*********************************************
 * Counter to keep track of 1/48s => 20 bit-counter
 * therefore we count till 1048576
 ********************************************/
always_ff @(posedge clk, negedge rst_n) begin
  if(!rst_n)
    count <= 20'b0;
  else if(init)
    count <= 20'b0;
  else
    count <= count + 20'b1;
end
      
/****************************************************
 * State Machine to keep track of which byte
 * is getting transmitted.
 ****************************************************/
typedef enum reg[3:0] {IDLE=4'b0000, TR1=4'b0001, TR2=4'b0010, TR3=4'b0011,
				     TR4=4'b0100, TR5=4'b0101, TR6=4'b0110,
				     TR7=4'b0111, STALL=4'b1000} state_t;
state_t nxt_state;
logic [3:0] state;

	
always_comb begin
  /////////////////////////////////////////
  // Default all SM outputs & nxt_state //
  ///////////////////////////////////////
  init = 1'b0;
  byte_num = 4'b000;
  trmt = 1'b0;
  nxt_state = state_t'(state);
	
  //state transition logic and output logic
  case (state)
    //Start transmitting byte 1
    IDLE: begin
	begin
	  nxt_state = TR1;
	  init = 1'b1;
          trmt = 1'b1;
	  byte_num = 4'b000;
	end 
    end
    //Start transmitting byte 2 else continue transmitting byte 1
    TR1: begin
	if(tx_done) begin
	  nxt_state = TR2;
          trmt = 1'b1;
	  byte_num = 4'b001;
	end else begin
	  nxt_state = TR1;
	  byte_num = 4'b000;
	end
    end
    //Start transmitting byte 3 else continue transmitting byte 2
    TR2: begin
	if(tx_done) begin
	  nxt_state = TR3;
          trmt = 1'b1;
	  byte_num = 4'b010;
	end else begin
	  nxt_state = TR2;
	  byte_num = 4'b001;
	end
    end
    //Start transmitting byte 4 else continue transmitting byte 3
    TR3: begin
	if(tx_done) begin
	  nxt_state = TR4;
          trmt = 1'b1;
	  byte_num = 4'b011;
	end else begin
	  nxt_state = TR3;
          byte_num = 4'b010;
	end
    end
    //Start transmitting byte 5 else continue transmitting byte 4
    TR4: begin
	if(tx_done) begin
	  nxt_state = TR5;
          trmt = 1'b1;
	  byte_num = 4'b100;
	end else begin
	  nxt_state = TR4;
          byte_num = 4'b011;
	end
    end
    //Start transmitting byte 6 else continue transmitting byte 5
    TR5: begin
	if(tx_done) begin
	  nxt_state = TR6;
          trmt = 1'b1;
	  byte_num = 4'b101;
	end else begin
	  nxt_state = TR5;
	  byte_num = 4'b100;
	end
    end
    //Start transmitting byte 7 else continue transmitting byte 6
    TR6: begin
	if(tx_done) begin
	  nxt_state = TR7;
          trmt = 1'b1;
	  byte_num = 4'b110;
	end else begin
	  nxt_state = TR6;
	  byte_num = 4'b101;
	end
    end
    //Start transmitting byte 8 else continue transmitting byte 7
    TR7: begin
	if(tx_done) begin
	  nxt_state = STALL;
          trmt = 1'b1;
	  byte_num = 4'b111;
	end else begin
	  nxt_state = TR7;
	  byte_num = 4'b110;
	end
    end
    //Finish transmitting byte 8 keeping stalling until done_t
    STALL: begin
	if(done_t) begin
	  nxt_state = IDLE;
	end else if(~tx_done) begin
	  byte_num = 4'b111;
        end else begin
	  nxt_state = STALL;
	end
    end

    default: nxt_state = IDLE;
  endcase
end

//Iterate through which state in the machine at posedge of clk
always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n)
    state <= 2'b00;
  else
    state <= nxt_state;
end

//Instantiate UART_tx
UART_tx uart(.clk(clk), .rst_n(rst_n), .TX(TX), .trmt(trmt) , .tx_data(tx_data) , .tx_done(tx_done));
     
endmodule
    