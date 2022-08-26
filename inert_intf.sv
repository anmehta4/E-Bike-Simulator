module inert_intf(clk, rst_n, MISO, INT, incline, SS_n, SCLK, MOSI, vld);

input logic clk, rst_n, MISO;
input logic INT;
output logic [12:0] incline;
output logic SS_n, SCLK, MOSI, vld;

logic snd, done;
logic [15:0] cmd, resp;
logic [2:0] channel[0:3];
logic [13:0] counter16;
logic INT_ff1, INT_ff2;
logic [7:0] control_sig;
logic [15:0] roll_rt, yaw_rt, AY, AZ;
logic C_R_L, C_R_H, C_Y_L, C_Y_H, C_AY_L, C_AY_H, C_AZ_L, C_AZ_H;

SPI_mnrch SPI(.clk(clk), .rst_n(rst_n), .SS_n(SS_n), .MISO(MISO), .SCLK(SCLK), 
	      .MOSI(MOSI), .snd(snd), .cmd(cmd), .done(done), .resp(resp));

registers REG(.clk(clk), .rst_n(rst_n), .control_sig(control_sig), 
 	      .resp(resp), .roll_rt(roll_rt), .yaw_rt(yaw_rt), .AY(AY), .AZ(AZ));

inertial_integrator INTER_INTEG(.clk(clk), .rst_n(rst_n), .vld(vld), 
		    .roll_rt(roll_rt), .yaw_rt(yaw_rt), .AY(AY), .AZ(AZ), .incline(incline), .LED());

always_ff @(posedge clk, negedge rst_n) begin
   if(!rst_n) 
      counter16 <= 16'h0000;
   else
      counter16 <= counter16 + 16'b1;
end

always_ff @(posedge clk, negedge rst_n) begin 
   if(!rst_n) begin
      INT_ff1 <= 1'b0;
      INT_ff2 <= 1'b0;
   end else begin
      INT_ff1 <= INT;
      INT_ff2 <= INT_ff1;
   end
end

/****************************************************
 * State Machine
 ****************************************************/
typedef enum reg[3:0] {INIT1=4'b0000, INIT2=4'b0001, INIT3=4'b0010, INIT4=4'b0011,
		       DONE_INIT=4'b0100, C_R_Ls=4'b0101, C_R_Hs=4'b0110,
		       C_Y_Ls=4'b0111, C_Y_Hs=4'b1000, C_AY_Ls=4'b1001, C_AY_Hs=4'b1010,
		       C_AZ_Ls=4'b1011, C_AZ_Hs=4'b1100, DONE=4'b1101, VALID=4'b1110} state_t;
state_t nxt_state;
logic [4:0] state;

	
always_comb begin
  /////////////////////////////////////////
  // Default all SM outputs & nxt_state //
  ///////////////////////////////////////
  vld = 1'b0;
  snd = 1'b0;
  cmd = 16'b0;
  C_R_H = 1'b0;
  C_R_L = 1'b0;
  C_Y_H = 1'b0;
  C_Y_L = 1'b0;
  C_AY_H = 1'b0;
  C_AY_L = 1'b0;
  C_AZ_L = 1'b0;
  C_AZ_H = 1'b0;
  nxt_state = state_t'(state);

  //state transition logic and output logic
  case (state)
    INIT1: begin
        if(&counter16 == 1'b0 & rst_n) begin
	   snd = 1'b1;
           cmd = 16'h0D02;
           nxt_state = INIT2;
        end else begin
	  nxt_state = INIT1;
	end 
     end
    INIT2: begin
	if(done) begin
	   snd = 1'b1;
           cmd = 16'h1053;
           nxt_state = INIT3;
        end else begin
	  nxt_state = INIT2;
	end 
     end
    INIT3: begin
	if(done) begin
	   snd = 1'b1;
           cmd = 16'h1150;
           nxt_state = INIT4;
        end else begin
	  nxt_state = INIT3;
	end 
     end
    INIT4: begin
	if(done) begin
	   snd = 1'b1;
           cmd = 16'h1460;
           nxt_state = DONE_INIT;
        end else begin
	  nxt_state = INIT4;
	end 
     end
    DONE_INIT:
	if(done) begin
           nxt_state = C_R_Ls;
        end else begin
	  nxt_state = DONE_INIT;
	end  
    C_R_Ls: begin
	if(INT_ff2) begin
	   snd = 1'b1;
           cmd = 16'hA4xx;
           nxt_state = C_R_Hs;
        end else begin
	  nxt_state = C_R_Ls;
	end 
     end
    C_R_Hs: begin
	if(done) begin
           C_R_L = 1'b1;
	   snd = 1'b1;
           cmd = 16'hA5xx;
           nxt_state = C_Y_Ls;
        end else begin
	  nxt_state = C_R_Hs;
	end 
     end
    C_Y_Ls: begin
	if(done) begin
           C_R_H = 1'b1;
	   snd = 1'b1;
           cmd = 16'hA6xx;
           nxt_state = C_Y_Hs;
        end else begin
	  nxt_state = C_Y_Ls;
	end 
     end
    C_Y_Hs: begin
	if(done) begin
           C_Y_L = 1'b1;
	   snd = 1'b1;
           cmd = 16'hA7xx;
           nxt_state = C_AY_Ls;
        end else begin
	  nxt_state = C_Y_Hs;
	end 
     end
    C_AY_Ls: begin
	if(done) begin
           C_Y_H = 1'b1;
	   snd = 1'b1;
           cmd = 16'hAAxx;
           nxt_state = C_AY_Hs;
        end else begin
	  nxt_state = C_AY_Ls;
	end 
     end
    C_AY_Hs: begin
	if(done) begin
           C_AY_L = 1'b1;
	   snd = 1'b1;
           cmd = 16'hABxx;
           nxt_state = C_AZ_Ls;
        end else begin
	  nxt_state = C_AY_Hs;
	end 
     end
    C_AZ_Ls: begin
	if(done) begin
           C_AY_H = 1'b1;
	   snd = 1'b1;
           cmd = 16'hACxx;
           nxt_state = C_AZ_Hs;
        end else begin
	  nxt_state = C_AZ_Ls;
	end 
     end
    C_AZ_Hs: begin
	if(done) begin
           C_AZ_L = 1'b1;
	   snd = 1'b1;
           cmd = 16'hADxx;
           nxt_state = DONE;
        end else begin
	  nxt_state = C_AZ_Hs;
	end 
     end
    DONE: begin
        if(done) begin
  	   C_AZ_H = 1'b1;
           nxt_state = VALID;
        end else begin
	   nxt_state = DONE;
	end
    end
   VALID: begin
	vld = 1'b1;
        nxt_state = C_R_Ls;
    end
  endcase
end

assign control_sig = {C_R_L, C_R_H, C_Y_L, C_Y_H, C_AY_L, C_AY_H, C_AZ_L, C_AZ_H};

always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n)
    state <= 4'b0000;
  else
    state <= nxt_state;
end

endmodule
