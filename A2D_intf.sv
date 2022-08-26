module A2D_intf(clk, rst_n, batt, curr, brake, torque, SS_n, SCLK, MOSI, MISO);

input logic clk, rst_n, MISO;
output logic [11:0] batt, curr, brake, torque;
output logic SS_n, SCLK, MOSI;

logic snd, done, cnv_cmplt;
logic [15:0] cmd, resp;
logic [2:0] channel[0:3];
logic [13:0] counter14;

assign channel[0] = 3'b000;
assign channel[1] = 3'b001;
assign channel[2] = 3'b011;
assign channel[3] = 3'b100;

SPI_mnrch SPI(.clk(clk), .rst_n(rst_n), .SS_n(SS_n), .MISO(MISO), .SCLK(SCLK), 
	      .MOSI(MOSI), .snd(snd), .cmd(cmd), .done(done), .resp(resp));

logic en_torque, en_curr, en_batt, en_brake;

logic [1:0] channel_dff, channel_mux;
always_ff @(posedge clk, negedge rst_n) begin
   if(!rst_n)
       channel_dff <= 2'b00;
   else
       channel_dff <= channel_mux;
end

assign channel_mux = cnv_cmplt ? (channel_dff + 2'b01) : channel_dff;

assign cmd = {2'b00, channel[channel_dff], 11'h000};

always_comb begin
   en_batt = 1'b0;
   en_curr = 1'b0;
   en_brake = 1'b0;
   en_torque = 1'b0;

   case({channel_dff, cnv_cmplt})
      3'b001: en_batt = 1'b1;
      3'b011: en_curr = 1'b1;
      3'b101: en_brake = 1'b1;
      3'b111: en_torque = 1'b1;
   endcase
end 
/****************************************************
 * State Machine
 ****************************************************/
typedef enum reg[1:0] {WRITE=2'b00, WAIT1=2'b01, READ=2'b10, WAIT2=2'b11} state_t;
state_t nxt_state;
logic [2:0] state;

	
always_comb begin
  /////////////////////////////////////////
  // Default all SM outputs & nxt_state //
  ///////////////////////////////////////
  cnv_cmplt = 1'b0;
  nxt_state = state_t'(state);
  snd = 1'b0;	
  //state transition logic and output logic
  case (state)
    WRITE: begin
        if(|counter14 == 1'b0 & rst_n) begin
	   snd = 1'b1;
        end
        if(done) begin //if 16 bis transmitted then go to next state
	  nxt_state = WAIT1;
	end else begin
          snd = 1'b1;  
	  nxt_state = WRITE;
	end 
     end
    WAIT1: begin
	nxt_state = READ;
     end
    READ: begin
        if(done) begin //if 16 bis transmitted then go to next state
	  nxt_state = WAIT2;
	end else begin
          snd = 1'b1;
	  nxt_state = READ;
	end 
     end
    WAIT2: begin
	nxt_state = WRITE;
        cnv_cmplt = 1'b1; 
     end
  endcase
end


always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n)
    state <= 2'b00;
  else
    state <= nxt_state;
end

always_ff @(posedge clk, negedge rst_n) begin
   if(!rst_n) 
      torque <= 12'h000;
   else if(en_torque)
      torque <= resp;
end

always_ff @(posedge clk, negedge rst_n) begin
   if(!rst_n) 
      curr <= 12'h000;
   else if(en_curr)
      curr <= resp;
end

always_ff @(posedge clk, negedge rst_n) begin
   if(!rst_n) 
      batt <= 12'h000;
   else if(en_batt)
      batt <= resp;
end

always_ff @(posedge clk, negedge rst_n) begin
   if(!rst_n) 
      brake <= 12'h000;
   else if(en_brake)
      brake <= resp;
end

always_ff @(posedge clk, negedge rst_n) begin
   if(!rst_n) 
      counter14 <= 14'h0000;
   else
      counter14 <= counter14 + 14'b1;
end

endmodule
